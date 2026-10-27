extends SceneTree
## Exact ordinary current input in three native worlds; only free-arm helper differs.
const Skater=preload("res://game/player/skater.gd")
const CandidateSkater=preload("res://.local/manual_arm_candidate_skater.gd")
const Arm=preload("res://tests/skater_obstacle_arm_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Manual=preload("res://tests/skater_wall_manual_tests.gd")
const Grade=preload("res://tests/pt24_manual_grade_tests.gd")
const Gate=preload("res://game/features/service_gate.gd")
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
const Authentic=preload("res://tests/authentic_pose_tests.gd")
const Score=preload("res://game/scoring/score_session.gd")
var passed:=0
var failed:=0
var records: Array[Dictionary]=[]
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	Wall.Setup.register_actions();Wall._release()
	var f:=_fixture("candidate");var old:=_fixture("baseline");var unfit:=_fixture("unfitted")
	var r: CharacterBody3D=f.rider;var c: CharacterBody3D=old.rider;var u: CharacterBody3D=unfit.rider
	var data:=Arm._skin_data(r,f.gate);var old_data:=Arm._skin_data(c,old.gate)
	var attachment:=Body._prepare(r._visual_rig)
	var ray:=PhysicsRayQueryParameters3D.new();ray.collision_mask=1|8;ray.exclude=[r.get_rid()]
	var score:=Score.new();var entries: Array[Dictionary]=[];var old_entries: Array[Dictionary]=[];var banks: Array[int]=[]
	r.trick_performed.connect(func(label: String,points: int):entries.append({"id":r.last_trick_id,"label":label,"points":points});score.add_trick(label,points,r.last_trick_id))
	c.trick_performed.connect(func(label: String,points: int):old_entries.append({"id":c.last_trick_id,"label":label,"points":points}))
	r.combo_link_started.connect(score.continue_combo);r.combo_link_ended.connect(score.begin_landing)
	await Wall._frames(self,4)
	var requested:=false;var impact:=-1;var active:=0;var residual:=0;var entry_speed:=0.0
	var physical:=true;var nonarm:=true;var root_same:=true;var far_same:=true;var fixed:=true
	var finite:=true;var attached:=true;var contained:=true;var loaded:=true;var cleared:=true
	var minimum_loaded:=INF;var maximum_loaded:=-INF;var old_hits:=0;var after_hits:=0
	var initial_fit:=-1;var ordinary_frames:=0;var fitted_frames:=0;var states: Array[String]=[]
	var previous: Array[Vector3]=[];var maximum_marker:=0.0;var maximum_changed_wrist:=0.0
	var previous_baseline: Array[Vector3]=[];var maximum_baseline_marker:=0.0
	var previous_world: Array[Vector3]=[];var previous_baseline_world: Array[Vector3]=[]
	var maximum_world:=0.0;var maximum_baseline_world:=0.0;var unchanged_markers:=true
	var previous_elbows: Array[Vector3]=[];var maximum_changed_elbow:=0.0
	var previous_changed: Array[bool]=[false,false];var frames: Array[String]=[]
	var bound_ids: Array[int]=[r._grind_board_query.get_instance_id(),r._grind_board_box.get_instance_id(),r._recovery_floor_query.get_instance_id()]
	Input.action_press("push",0.55)
	for tick: int in 150:
		if not requested and absf(r.speed)>=2.5 and r.global_position.z< -1.0:requested=true;Input.action_press("manual")
		await Wall._frames(self,1)
		if impact<0 and Wall._wall_contact(r,f.gate._panel):impact=tick;Input.action_release("push");Input.action_press("brake")
		if r.manual_active:
			if active==0:entry_speed=absf(r.speed)
			active+=1
		if not r.manual_active and r._visual_rig._manual_blend>0.0001 and r._obstacle_manual_continuation:residual+=1
		var bank:=score.tick(1.0/60.0)
		if bank>0:banks.append(bank)
		var physical_now: bool=Grade._physics(r)==Grade._physics(c) and Grade._physics(r)==Grade._physics(u)
		var nonarm_now: bool=Arm._nonarm(r)==Arm._nonarm(c) and Arm._nonarm(r)==Arm._nonarm(u)
		physical=physical and physical_now;nonarm=nonarm and nonarm_now
		root_same=root_same and r._visual.transform==c._visual.transform and r._obstacle_visual_offset==c._obstacle_visual_offset \
			and r._board_visual.transform==c._board_visual.transform and r._rider_visual.transform==c._rider_visual.transform
		var rig: RefCounted=r._visual_rig;var skel: Skeleton3D=rig._garments.skeleton;var base_skel: Skeleton3D=c._visual_rig._garments.skeleton
		var changed: Array[bool]=[]
		var elbows: Array[Vector3]=[]
		for index: int in 2:
			var arm: Dictionary=r._obstacle_arm_fit.arms[index]
			var shoulder:=skel.global_transform*skel.get_bone_global_pose(arm.upper).origin
			var elbow:=skel.global_transform*skel.get_bone_global_pose(arm.lower).origin
			var wrist: Vector3=rig._arms[index].hand.global_position
			elbows.append(r.to_local(elbow))
			fixed=fixed and absf(shoulder.distance_to(elbow)-0.30)<0.00001 and absf(elbow.distance_to(wrist)-0.29)<0.00001
			var arm_changed: bool=skel.get_bone_pose(arm.upper)!=base_skel.get_bone_pose(arm.upper) or skel.get_bone_pose(arm.lower)!=base_skel.get_bone_pose(arm.lower) \
				or rig._arms[index].hand.transform!=c._visual_rig._arms[index].hand.transform
			changed.append(arm_changed)
			if index==1:far_same=far_same and not arm_changed
		var actual:=Arm._vertices(r,data);var before:=Arm._vertices(c,old_data)
		contained=contained and actual.contained;old_hits+=int(before.panel_hits)
		if r._obstacle_arm_fit.accepted>0 and initial_fit<0:initial_fit=tick
		if initial_fit>=0:
			cleared=cleared and int(actual.panel_hits)==0;after_hits+=int(actual.panel_hits)
		if r._obstacle_manual_continuation:
			ordinary_frames+=1;fitted_frames+=int(changed[0] or changed[1])
			var support:=Manual._loaded(r,ray)
			loaded=loaded and support.valid;minimum_loaded=minf(minimum_loaded,support.minimum);maximum_loaded=maxf(maximum_loaded,support.maximum)
		var sample:=Body._sample(r,attachment)
		finite=finite and sample.finite;attached=attached and sample.seam<0.08 and sample.joint_gap<0.06 and sample.neck_gap<0.05
		var markers: Array[Vector3]=[];var baseline_markers: Array[Vector3]=[]
		var world_markers:=Authentic._markers(rig);var baseline_world_markers:=Authentic._markers(c._visual_rig)
		for marker: Vector3 in world_markers:markers.append(r.to_local(marker))
		for marker: Vector3 in baseline_world_markers:baseline_markers.append(c.to_local(marker))
		for index: int in markers.size():
			if index<3 or not changed[index-3]:unchanged_markers=unchanged_markers and markers[index]==baseline_markers[index] and world_markers[index]==baseline_world_markers[index]
		if previous.size()==markers.size():
			maximum_marker=maxf(maximum_marker,Authentic._marker_delta(previous,markers))
			maximum_baseline_marker=maxf(maximum_baseline_marker,Authentic._marker_delta(previous_baseline,baseline_markers))
			maximum_world=maxf(maximum_world,Authentic._marker_delta(previous_world,world_markers))
			maximum_baseline_world=maxf(maximum_baseline_world,Authentic._marker_delta(previous_baseline_world,baseline_world_markers))
			for index: int in 2:
				if changed[index] or previous_changed[index]:
					maximum_changed_wrist=maxf(maximum_changed_wrist,previous[index+3].distance_to(markers[index+3]))
					maximum_changed_elbow=maxf(maximum_changed_elbow,previous_elbows[index].distance_to(elbows[index]))
		previous=markers;previous_changed=changed;previous_baseline=baseline_markers;previous_world=world_markers;previous_baseline_world=baseline_world_markers;previous_elbows=elbows
		var stage: String="active" if tick==78 else ("residual" if tick==99 else "")
		if stage!="":states.append(stage)
		records.append({"tick":tick,"stage":stage,"manual":r.manual_active,"id":r.manual_trick_id,"blend":rig._manual_blend,"earned":r._obstacle_manual_continuation,
			"physical_equal":physical_now,"nonarm_equal":nonarm_now,"body":r.global_transform,"root":r._visual.transform,"board":r._board_visual.transform,
			"actual":actual,"baseline":before,"changed":changed,"body_markers":markers,"baseline_body_markers":baseline_markers,"world_markers":world_markers,"baseline_world_markers":baseline_world_markers,"body_elbows":elbows,"cloth":sample,"calls":r._obstacle_arm_fit.calls,"accepted":r._obstacle_arm_fit.accepted})
	Wall._release()
	_check(requested and entry_speed>=2.0 and active>=30 and residual>=15 and impact==79 and states==["active","residual"],"actual ordinary input earns expected Nose Manual and the exact active78/residual99 poses")
	_check(entries==old_entries and entries.size()==1 and entries[0].id=="nose_manual" and entries[0].points==100 and banks==[100] and score.total_score==100,"actual catalog entry and grounded link-exit bank100 exactly once with identical events")
	_check(initial_fit>=0 and ordinary_frames>=20 and fitted_frames>0 and old_hits>0 and cleared and after_hits==0,"every original Skin/curl vertex clears current finite8mm panel skin from first correction through active/residual/fade")
	_check(physical and root_same and nonarm and far_same,"native/unfitted physical twins, fitted root/local deck/rider, every non-arm bone and unblocked far arm remain exact")
	_check(loaded and minimum_loaded>=0.0079 and maximum_loaded<=0.00901,"both actual catalog-loaded tyres retain native8to9mm floor support through every earned Manual frame")
	_check(fixed and finite and attached and contained,"fixed .30/.29 arms, conservative original Skin/curl enclosure and existing cloth/neck attachment limits remain intact")
	_check(unchanged_markers and maximum_changed_wrist<0.22 and maximum_changed_elbow<0.22,"every unchanged world/body marker matches baseline exactly and all changed wrist/elbow steps retain original220mm bound including first correction")
	_check(r._obstacle_arm_fit.maximum_calls<=12 and r._obstacle_arm_fit.maximum_shift<=0.20 and bound_ids==[r._grind_board_query.get_instance_id(),r._grind_board_box.get_instance_id(),r._recovery_floor_query.get_instance_id()],"same three native query resources retain12-call and20cm wrist ceilings")
	var report: Dictionary={"passed":passed,"failed":failed,"entry_speed":entry_speed,"impact":impact,"active":active,"residual":residual,"entries":entries,"baseline_entries":old_entries,"banks":banks,"initial_fit":initial_fit,
		"ordinary_frames":ordinary_frames,"fitted_frames":fitted_frames,"baseline_skin_vertex_samples":old_hits,"after_skin_vertex_samples":after_hits,"maximum_body_marker":maximum_marker,"maximum_changed_wrist":maximum_changed_wrist,"maximum_changed_elbow":maximum_changed_elbow,"maximum_baseline_body_marker":maximum_baseline_marker,"maximum_world_marker":maximum_world,"maximum_baseline_world_marker":maximum_baseline_world,"unchanged_markers_equal":unchanged_markers,
		"minimum_loaded":minimum_loaded,"maximum_loaded":maximum_loaded,"maximum_calls":r._obstacle_arm_fit.maximum_calls,"maximum_shift":r._obstacle_arm_fit.maximum_shift,"records":records,
		"scope":"Current ordinary Push/fresh Manual resolves Nose Manual, exact active78 and residual99 plus complete150nativeupdates. Candidate changes only current earned exact ordinaryManual guard. Actual original Skin/curl finiteprimitive checks from first fit, native/root/nonarm/far-arm twins, fixedlength/original220mm changed wrist and elbow transitions including first correction; every unchanged world/body marker exact baseline. Full gait253mm rightfoot event retained quantitatively, not accepted as a new fixed-body pose or modified to pass. Loadedtyre/100once invariants. Other variants and negative controls separate."}
	var file:=FileAccess.open("res://.local/manual_arm_candidate_proof_v2.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	for item: Dictionary in [f,old,unfit]:item.viewport.queue_free()
	await process_frame;print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _fixture(kind: String) -> Dictionary:
	var viewport:=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;root.add_child(viewport)
	var scene:=Node3D.new();viewport.add_child(scene)
	var floor:=StaticBody3D.new();scene.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-0.1;floor.add_child(collision)
	var gate:=Gate.new();scene.add_child(gate);gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	var rider: CharacterBody3D=CandidateSkater.new() if kind=="candidate" else (Wall.UnfittedSkater.new() if kind=="unfitted" else Skater.new())
	rider.spawn_position=Vector3(0,0.04,-3.02);scene.add_child(rider);rider.rotation.y=PI
	return {"viewport":viewport,"scene":scene,"rider":rider,"gate":gate,"floor":floor}
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
