extends SceneTree
## Genuine coasting neutral Manual, shared inputs and same-native-state twins.
## Initial spawn is the only positive-route pose/velocity/state assignment.
const Current=preload("res://game/player/skater.gd")
const Candidate=preload("res://.local/manual_arm_candidate_anchored_skater.gd")
const USE_CANDIDATE:=true
const Arm=preload("res://tests/skater_obstacle_arm_tests.gd")
const Authentic=preload("res://tests/authentic_pose_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Grade=preload("res://tests/pt24_manual_grade_tests.gd")
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Gate=preload("res://game/features/service_gate.gd")
const Catalog=preload("res://game/tricks/trick_catalog.gd")
const Score=preload("res://game/scoring/score_session.gd")
var passed:=0
var failed:=0

func _initialize() -> void:_run.call_deferred()

func _run() -> void:
	Setup.register_actions();Wall._release()
	var viewport:=SubViewport.new();viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;root.add_child(viewport)
	var scene:=Node3D.new();viewport.add_child(scene)
	var floor:=StaticBody3D.new();scene.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
	var solid:=CollisionShape3D.new();solid.shape=shape;solid.position.y=-0.1;floor.add_child(solid)
	var gate:=Gate.new();scene.add_child(gate)
	gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	var rider: CharacterBody3D=Candidate.new() if USE_CANDIDATE else Current.new()
	var control:=Current.new()
	for actor: CharacterBody3D in [rider,control]:
		actor.spawn_position=Vector3(0,0.04,-6.0);scene.add_child(actor);actor.rotation.y=PI
	var data:=Arm._skin_data(rider,gate)
	var old_data:=Arm._skin_data(control,gate)
	var attachment:=Body._prepare(rider._visual_rig)
	var score:=Score.new();var old_score:=Score.new()
	var events: Array[Dictionary]=[];var old_events: Array[Dictionary]=[]
	var banks: Array[int]=[];var old_banks: Array[int]=[]
	rider.trick_performed.connect(func(label: String,points: int):
		events.append({"id":rider.last_trick_id,"points":points});score.add_trick(label,points,rider.last_trick_id))
	control.trick_performed.connect(func(label: String,points: int):
		old_events.append({"id":control.last_trick_id,"points":points});old_score.add_trick(label,points,control.last_trick_id))
	rider.combo_link_started.connect(score.continue_combo);rider.combo_link_ended.connect(score.begin_landing)
	control.combo_link_started.connect(old_score.continue_combo);control.combo_link_ended.connect(old_score.begin_landing)
	var ray:=PhysicsRayQueryParameters3D.new();ray.collision_mask=1|8;ray.exclude=[rider.get_rid(),control.get_rid()]
	await Wall._frames(self,4)
	var release_tick:=-1;var request_tick:=-1;var impact:=-1
	var entry_speed:=0.0;var active_ticks:=0;var active_fits:=0;var precontact_active_fits:=0;var residual_fits:=0
	var physical:=true;var local_pose:=true;var nonarm:=true;var loaded:=true
	var loaded_min:=INF;var loaded_max:=-INF
	var max_skin_hits:=0;var old_max_skin_hits:=0;var contained:=true
	var cloth:=true;var minimum_gap:=INF
	var samples: Array[Dictionary]=[]
	var resources: Array[int]=[rider._grind_board_query.get_instance_id(),rider._grind_board_box.get_instance_id(),rider._recovery_floor_query.get_instance_id()]
	var motion: Dictionary={"candidate_world_peak":0.0,"baseline_world_peak":0.0,"candidate_body_peak":0.0,"baseline_body_peak":0.0,"candidate_root_peak":0.0,"baseline_root_peak":0.0,
		"candidate_arm_body_peak":0.0,"baseline_arm_body_peak":0.0,"changed_arm_body_peak":0.0,
		"candidate_arm_world_peak":0.0,"baseline_arm_world_peak":0.0,"changed_arm_world_peak":0.0,
		"candidate_arm_root_peak":0.0,"baseline_arm_root_peak":0.0,"changed_arm_root_peak":0.0,
		"exact_unaffected_world":true,"exact_unaffected_body":true,"exact_unaffected_root":true,"exact_shoulders_world":true,"exact_shoulders_body":true,"exact_shoulders_root":true,
		"exact_shoulders_local":true,"maximum_shoulder_world_delta":0.0,"maximum_shoulder_body_delta":0.0,"maximum_shoulder_local_delta":0.0,"maximum_shoulder_root_delta":0.0,
		"exact_far_elbow_world":true,"exact_far_elbow_body":true,"exact_far_elbow_root":true,"exact_common_root":true}
	var previous: Dictionary=_motion_markers(rider)
	var old_previous: Dictionary=_motion_markers(control)
	Input.action_press("push",0.55)
	for tick: int in 220:
		if release_tick<0 and absf(rider.speed)>=4.5 and rider.global_position.z< -2.0:
			release_tick=tick;Input.action_release("push")
		elif release_tick>=0 and request_tick<0 and tick-release_tick>=12:
			# Twelve actual neutral physics ticks also expire the18/100s
			# directional memory; the fresh Manual uses real neutral input.
			request_tick=tick;Input.action_press("manual")
		await Wall._frames(self,1)
		var bank:=score.tick(1.0/60.0);var old_bank:=old_score.tick(1.0/60.0)
		if bank>0:banks.append(bank)
		if old_bank>0:old_banks.append(old_bank)
		if rider.manual_active:
			if active_ticks==0:entry_speed=absf(rider.speed)
			active_ticks+=1
		if impact<0 and Wall._wall_contact(rider,gate._panel):
			impact=tick;Input.action_press("brake")
		physical=physical and Grade._physics(rider)==Grade._physics(control) and rider._visual.transform==control._visual.transform
		local_pose=local_pose and rider._board_visual.transform==control._board_visual.transform and rider._rider_visual.transform==control._rider_visual.transform
		nonarm=nonarm and Arm._nonarm(rider)==Arm._nonarm(control)
		var current: Dictionary=_motion_markers(rider)
		var old_current: Dictionary=_motion_markers(control)
		_track_motion(motion,previous,current,old_previous,old_current,tick)
		previous=current;old_previous=old_current
		minimum_gap=minf(minimum_gap,Wall._plane_gap(rider))
		if rider.manual_active or rider._visual_rig._manual_blend>0.0001:
			var support:=_loaded(rider,ray)
			loaded=loaded and support.valid;loaded_min=minf(loaded_min,support.minimum);loaded_max=maxf(loaded_max,support.maximum)
		if rider._obstacle_manual_continuation:
			active_fits+=int(rider.manual_active);precontact_active_fits+=int(rider.manual_active and impact<0);residual_fits+=int(not rider.manual_active)
			var skin:=Arm._vertices(rider,data);var old_skin:=Arm._vertices(control,old_data)
			max_skin_hits=maxi(max_skin_hits,int(skin.panel_hits));old_max_skin_hits=maxi(old_max_skin_hits,int(old_skin.panel_hits));contained=contained and skin.contained
			var body:=Body._sample(rider,attachment)
			cloth=cloth and body.finite and body.seam<0.12 and body.joint_gap<0.10 and body.neck_gap<0.05
			if samples.is_empty() or (impact>=0 and tick-impact==20):
				samples.append({"tick":tick,"impact":impact,"position":rider.global_position,"velocity":rider.velocity,
					"manual_id":rider.manual_trick_id,"active":rider.manual_active,"blend":rider._visual_rig._manual_blend,
					"root_offset":rider._obstacle_visual_offset,"native_skin":skin,"old_native_skin":old_skin})
		if impact>=0 and tick-impact>=60:break
	Wall._release()
	var expected:=int(Catalog.definition("manual").base_points)
	_check(release_tick>=0 and request_tick-release_tick>=12 and entry_speed>=2.0 and events==[{"id":"manual","points":expected}],
		"ordinary Manual: actual Push release, twelve neutral rolling ticks and fresh Manual earn the genuine neutral catalog ID")
	_check(impact>=0 and active_fits==2 and precontact_active_fits==1 and residual_fits>=15 and rider.is_on_floor() and not rider.bailing,
		"ordinary Manual: the observed fast coast has one precontact and one impact active fitted tick plus the earned residual axle fit")
	_check(loaded and loaded_min>=0.0079 and loaded_max<=0.00901 and minimum_gap>=0.0079,
		"ordinary Manual: actual catalog-loaded rear tyres and board/shoes retain native8mm support and wall clearance")
	_check(physical and local_pose and nonarm,
		"ordinary Manual: exact native body/balance/root/local board/rider and every non-arm bone match the current physical twin")
	_check(events==old_events and banks==[expected] and old_banks==banks and score.total_score==expected and old_score.total_score==expected,
		"ordinary Manual: both genuine event streams bank catalog100 exactly once")
	_check(max_skin_hits==0 and contained and cloth,
		"ordinary Manual: original actual Skin/curl vertices clear the finite native panel during earned fits with contained envelopes and attached clothes")
	_check(resources==[rider._grind_board_query.get_instance_id(),rider._grind_board_box.get_instance_id(),rider._recovery_floor_query.get_instance_id()] \
		and rider._obstacle_arm_fit.maximum_calls<=12 and rider._obstacle_arm_fit.maximum_shift<=0.20,
		"ordinary Manual: original shared resources and twelve-call/20cm free-wrist caps remain bounded")
	# The first proposal wrongly called actor-relative root backoff an arm
	# teleport. Retain that raw256.631mm peak; constrain BOTH actual world
	# travel and pose inside the exact common visual root to the original220mm.
	_check(motion.exact_common_root and motion.exact_unaffected_world and motion.exact_unaffected_body and motion.exact_unaffected_root
		and motion.exact_far_elbow_world and motion.exact_far_elbow_body and motion.exact_far_elbow_root
		and motion.exact_shoulders_world and motion.exact_shoulders_body and motion.exact_shoulders_root and motion.exact_shoulders_local
		and float(motion.changed_arm_world_peak)<0.22 and float(motion.changed_arm_root_peak)<0.22,
		"ordinary Manual: exact common-root/head/feet/far-arm/shoulder parity with first changed wrist/elbow transitions within220mm in world AND common visual-root pose")
	print("ORDINARY_MANUAL_INPUT ",{"candidate":USE_CANDIDATE,"release_tick":release_tick,"request_tick":request_tick,"entry_speed":entry_speed,
		"impact":impact,"active_ticks":active_ticks,"active_fits":active_fits,"precontact_active_fits":precontact_active_fits,"residual_fits":residual_fits,
		"loaded_min":loaded_min,"loaded_max":loaded_max,"minimum_board_shoe_gap":minimum_gap,
		"physical":physical,"local_pose":local_pose,"nonarm":nonarm,"skin_hits":max_skin_hits,"old_skin_hits":old_max_skin_hits,
		"accepted":rider._obstacle_arm_fit.accepted,"refused":rider._obstacle_arm_fit.refused,"maximum_calls":rider._obstacle_arm_fit.maximum_calls,
		"maximum_shift":rider._obstacle_arm_fit.maximum_shift,"motion":motion,"events":events,"old_events":old_events,"banks":banks,"old_banks":old_banks,"samples":samples})
	viewport.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)

func _motion_markers(actor: CharacterBody3D) -> Dictionary:
	var rig: RefCounted=actor._visual_rig
	var skeleton: Skeleton3D=rig._garments.skeleton
	var world: Array[Vector3]=Authentic._markers(rig)
	var body: Array[Vector3]=[];var root_pose: Array[Vector3]=[]
	for point: Vector3 in world:body.append(actor.to_local(point));root_pose.append(actor._visual.to_local(point))
	var arm_world: Array[Vector3]=[];var arm_body: Array[Vector3]=[];var arm_root: Array[Vector3]=[]
	var shoulder_world: Array[Vector3]=[];var shoulder_body: Array[Vector3]=[];var shoulder_local: Array[Vector3]=[];var shoulder_root: Array[Vector3]=[]
	for index: int in 2:
		var side: String="left" if index==0 else "right"
		var upper: int=skeleton.find_bone(side+"_sleeve")
		var lower: int=skeleton.find_bone(side+"_forearm")
		var shoulder: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(upper).origin
		var elbow: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(lower).origin
		var wrist: Vector3=rig._arms[index].hand.global_position
		shoulder_world.append(shoulder);shoulder_body.append(actor.to_local(shoulder));shoulder_local.append(skeleton.get_bone_global_pose(upper).origin);shoulder_root.append(actor._visual.to_local(shoulder))
		for point: Vector3 in [elbow,wrist]:arm_world.append(point);arm_body.append(actor.to_local(point));arm_root.append(actor._visual.to_local(point))
	var frame: Transform3D=actor._visual.global_transform
	var rows: Array[Vector3]=[frame.basis.x,frame.basis.y,frame.basis.z,frame.origin]
	return {"world":world,"body":body,"root":root_pose,"arm_world":arm_world,"arm_body":arm_body,"arm_root":arm_root,
		"shoulder_world":shoulder_world,"shoulder_body":shoulder_body,"shoulder_local":shoulder_local,"shoulder_root":shoulder_root,
		"root_frame":rows,"actor_origin":actor.global_position}

func _track_motion(metrics: Dictionary,previous: Dictionary,current: Dictionary,old_previous: Dictionary,old_current: Dictionary,tick: int) -> void:
	metrics.exact_common_root=metrics.exact_common_root and current.root_frame==old_current.root_frame
	for space: String in ["world","body","root"]:
		var now: Array[Vector3]=current[space];var before: Array[Vector3]=previous[space]
		var old_now: Array[Vector3]=old_current[space];var old_before: Array[Vector3]=old_previous[space]
		for index: int in now.size():
			_peak(metrics,"candidate_"+space+"_peak",before[index].distance_to(now[index]),tick,index)
			_peak(metrics,"baseline_"+space+"_peak",old_before[index].distance_to(old_now[index]),tick,index)
		# Actual marker order: head, left/right foot, left/right hand.
		for index: int in [0,1,2,4]:metrics["exact_unaffected_"+space]=metrics["exact_unaffected_"+space] and now[index]==old_now[index]
		var arms: Array[Vector3]=current["arm_"+space];var old_arms: Array[Vector3]=old_current["arm_"+space]
		metrics["exact_far_elbow_"+space]=metrics["exact_far_elbow_"+space] and arms[2]==old_arms[2]
	for space: String in ["world","body","local","root"]:
		var shoulders: Array[Vector3]=current["shoulder_"+space];var old_shoulders: Array[Vector3]=old_current["shoulder_"+space]
		for index: int in shoulders.size():
			if shoulders[index]!=old_shoulders[index] and not metrics.has("first_shoulder_difference_"+space):
				metrics["first_shoulder_difference_"+space]={"tick":tick,"side":index,"candidate":shoulders[index],"baseline":old_shoulders[index]}
			metrics["exact_shoulders_"+space]=metrics["exact_shoulders_"+space] and shoulders[index]==old_shoulders[index]
			metrics["maximum_shoulder_"+space+"_delta"]=maxf(float(metrics["maximum_shoulder_"+space+"_delta"]),shoulders[index].distance_to(old_shoulders[index]))
	for space: String in ["world","body","root"]:
		var arms: Array[Vector3]=current["arm_"+space];var before: Array[Vector3]=previous["arm_"+space]
		var old_arms: Array[Vector3]=old_current["arm_"+space];var old_before: Array[Vector3]=old_previous["arm_"+space]
		for index: int in arms.size():
			_peak(metrics,"candidate_arm_"+space+"_peak",before[index].distance_to(arms[index]),tick,index)
			_peak(metrics,"baseline_arm_"+space+"_peak",old_before[index].distance_to(old_arms[index]),tick,index)
			# Both first correction and return to baseline remain in the bound.
			if arms[index]!=old_arms[index] or before[index]!=old_before[index]:
				_peak(metrics,"changed_arm_"+space+"_peak",before[index].distance_to(arms[index]),tick,index)
				if not metrics.has("first_changed_arm"):
					metrics.first_changed_arm={"tick":tick,"marker":index,"previous_world":previous.arm_world,"current_world":current.arm_world,"baseline_previous_world":old_previous.arm_world,"baseline_world":old_current.arm_world,
						"previous_actor_relative":previous.arm_body,"current_actor_relative":current.arm_body,"baseline_actor_relative":old_current.arm_body,
						"previous_root_pose":previous.arm_root,"current_root_pose":current.arm_root,"baseline_root_pose":old_current.arm_root,
						"previous_common_root":previous.root_frame,"current_common_root":current.root_frame,
						"previous_actor_origin":previous.actor_origin,"current_actor_origin":current.actor_origin}

func _peak(metrics: Dictionary,key: String,value: float,tick: int,index: int) -> void:
	if value>float(metrics[key]):
		metrics[key]=value;metrics[key+"_at"]={"tick":tick,"marker":index}

func _loaded(actor: CharacterBody3D,ray: PhysicsRayQueryParameters3D) -> Dictionary:
	var sign: float=Catalog.definition(actor.manual_trick_id).get("manual_sign",0.0)
	var valid: bool=sign==1.0 and actor._board_visual.rotation.x>0.0
	var count:=0;var minimum:=INF;var maximum:=-INF
	for wheel: Dictionary in actor._visual_rig.board_contact_geometry().wheels:
		if Vector3(wheel.center).z*sign<=0.0:continue
		count+=1
		var bearing: Vector3=actor._board_visual.to_global(wheel.center)
		ray.from=bearing+Vector3.UP*0.35;ray.to=bearing-Vector3.UP*0.50
		var hit:=actor.get_world_3d().direct_space_state.intersect_ray(ray)
		var clear: bool=not hit.is_empty() and Vector3(hit.get("normal",Vector3.ZERO)).y>0.999 and absf(Vector3(hit.get("position",Vector3.INF)).y)<0.001
		valid=valid and clear
		var gap:=INF
		if clear:
			for point: Vector3 in wheel.points:gap=minf(gap,(actor._board_visual.to_global(point)-Vector3(hit.position)).dot(hit.normal))
		minimum=minf(minimum,gap);maximum=maxf(maximum,gap)
	return {"valid":valid and count==2,"minimum":minimum,"maximum":maximum}

func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
