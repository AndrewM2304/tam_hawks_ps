extends SceneTree
## Read-only native pose observer for the already visible Flip/shutter sleeve.
## No per-tick actor placement, flags, mesh changes or candidate corrections.
const Current = preload("res://.local/active_wall_arm_skater_v2.gd")
const Gate = preload("res://game/features/service_gate.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Body = preload("res://tests/skater_body_attachment_tests.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Score = preload("res://game/scoring/score_session.gd")
const FACE_POINT := Vector3(0,0,-0.09)
const FACE_NORMAL := Vector3.FORWARD
var actor: CharacterBody3D
var gate: Node3D
var sample_data: Dictionary
var arms: Array[Dictionary]=[]
var query:=PhysicsRayQueryParameters3D.new()
var records: Array[Dictionary]=[]
var entries: Array[Dictionary]=[]
var active_ticks:=0
var contacts:=0
var sequence_tick:=0
var previous_markers: Array[Vector3]=[]
var maximum_marker_step:=0.0
var score:=Score.new()
var banks: Array[int]=[]

func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	Setup.register_actions();_release()
	var floor:=StaticBody3D.new();root.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-0.1;floor.add_child(collision)
	gate=Gate.new();root.add_child(gate)
	gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	actor=Current.new();actor.spawn_position=Vector3(0,0.04,-3);root.add_child(actor);actor.rotation.y=PI
	actor.trick_performed.connect(func(label: String,points: int):
		entries.append({"id":actor.last_trick_id,"label":label,"points":points})
		score.add_trick(label,points,actor.last_trick_id))
	actor.landed.connect(func(ok: bool):
		if ok:score.begin_landing()
		else:score.drop_combo())
	actor.combo_link_started.connect(score.continue_combo)
	actor.combo_link_ended.connect(score.begin_landing)
	query.collision_mask=1;query.exclude=[actor.get_rid()]
	sample_data=Body._prepare(actor._visual_rig);arms=_prepare_arms()
	for tick in 10:await _frame()
	var contact_tick:=-1
	Input.action_press("push",0.55)
	for tick in 180:
		await _frame()
		for slide in actor.get_slide_collision_count():
			if actor.get_slide_collision(slide).get_collider()==gate._panel:contacts+=1
		if contacts>0:contact_tick=tick;break
	Input.action_release("push");Input.action_press("brake")
	for tick in 20:await _frame()
	Input.action_release("brake")
	for tick in 2:await _frame()
	Input.action_press("ollie")
	for tick in 20:await _frame()
	Input.action_release("ollie")
	for tick in 2:await _frame()
	_observe("before_flip",0)
	Input.action_press("flip")
	for tick in 90:
		if tick==6:Input.action_release("flip")
		await _frame()
		active_ticks+=int(actor._flip_remaining>0)
		_observe("flip_catch_land",tick+1)
	_release()
	var valid: bool=contact_tick>=0 and contacts>0 and active_ticks>=15 and entries.size()==2 \
		and entries[0].id=="ollie" and entries[1].id=="kickflip" and not actor.bailing and actor.is_on_floor()
	var report: Dictionary={"native_workload_valid":valid,"contact_tick":contact_tick,"actual_panel_contacts":contacts,
		"active_flip_ticks":active_ticks,"entries":entries,"samples":records,
		"banks":banks,"score_total":score.total_score,"maximum_marker_step":maximum_marker_step,
		"candidate":actor.arm_candidate_report() if actor.has_method("arm_candidate_report") else {},
		"method":"Same current-controller ServiceGate workload as accepted native after-flip frame: single initial spawn(0,.04,-3),headingPI,10settle,Push(.55) to first actual panel collision,Brake20,neutral2,heldOllie20,release2,then90nativeupdates with freshFlip held6. No actor pose/velocity/trick/bone assignments after construction. Arms use original jacket vertex/bone/weight/Skin bind data and current Skeleton global poses. Known declared face is used only to measure this diagnostic; a fresh actual same-panel finite ray authenticates each worst sleeve and actual curl-blended anatomical-hand point. Negative gaps are retained as defects, not passing arm clearance.",
		"visual_source_sha256":FileAccess.get_sha256("res://game/player/skater_visual.gd"),
		"controller_source_sha256":FileAccess.get_sha256("res://game/player/skater.gd")}
	var file:=FileAccess.open("res://.local/active_wall_arm_candidate_proof_v2.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("ARM_WALL_DIAGNOSTIC valid_native_workload=",valid," samples=",records.size()," active_flip_ticks=",active_ticks)
	actor.queue_free();gate.queue_free();floor.queue_free();await process_frame
	quit(0 if valid else 1)

func _prepare_arms() -> Array[Dictionary]:
	var rig: RefCounted=actor._visual_rig
	var skeleton: Skeleton3D=rig._garments.skeleton
	var jacket: MeshInstance3D=sample_data.jacket
	var arrays:=jacket.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var binds: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	var stride:=binds.size()/vertices.size()
	var result: Array[Dictionary]=[]
	for side: float in [-1.0,1.0]:
		var prefix: String="left" if side<0.0 else "right"
		var points: Array[Dictionary]=[]
		for index in vertices.size():
			var arm_weight:=0.0
			for influence in stride:
				var bind:=binds[index*stride+influence]
				var bone:=Body._bone_for(jacket.skin,skeleton,bind)
				if skeleton.get_bone_name(bone) in [prefix+"_sleeve",prefix+"_forearm"]:arm_weight+=weights[index*stride+influence]
			if arm_weight<=0.001:continue
			points.append({"vertex_index":index,"point":vertices[index],"bones":binds.slice(index*stride,(index+1)*stride),"weights":weights.slice(index*stride,(index+1)*stride)})
		var hand_mesh: MeshInstance3D=rig._arms[result.size()].hand.get_node("HandAndFingers")
		var hand_points: Array[Dictionary]=[]
		for surface in hand_mesh.mesh.get_surface_count():
			var base: PackedVector3Array=hand_mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var blends: Array=hand_mesh.mesh.surface_get_blend_shape_arrays(surface)
			var curl: PackedVector3Array=blends[0][Mesh.ARRAY_VERTEX]
			for vertex in base.size():hand_points.append({"base":base[vertex],"curl":curl[vertex]})
		result.append({"side":side,"prefix":prefix,"points":points,"hand_mesh":hand_mesh,"hand_points":hand_points})
	return result

func _observe(phase: String,tick: int) -> void:
	var rig: RefCounted=actor._visual_rig
	var skeleton: Skeleton3D=rig._garments.skeleton
	var jacket: MeshInstance3D=sample_data.jacket
	var palette: Array[Transform3D]=[]
	for bind in jacket.skin.get_bind_count():palette.append(skeleton.global_transform*skeleton.get_bone_global_pose(Body._bone_for(jacket.skin,skeleton,bind))*jacket.skin.get_bind_pose(bind))
	var observations: Array[Dictionary]=[]
	var panel_box:=AABB(-gate._shape.size*0.5,gate._shape.size).grow(0.00799)
	for index in arms.size():
		var arm: Dictionary=arms[index]
		var worst:=Vector3.ZERO
		var gap:=INF
		var vertex:=-1
		var panel_hits:=0
		var envelope_misses:=0
		var envelope:=AABB()
		if actor.has_method("arm_candidate_report"):envelope=actor._arm_candidate._bounds(actor._arm_candidate.arms[index],{},rig._arms[index].hand.global_transform).grow(0.00001)
		for record: Dictionary in arm.points:
			var point:=Vector3.ZERO
			for influence in record.bones.size():point+=(palette[record.bones[influence]]*Vector3(record.point))*float(record.weights[influence])
			if actor.has_method("arm_candidate_report") and not envelope.has_point(point):envelope_misses+=1
			if panel_box.has_point(gate._panel.to_local(point)):panel_hits+=1
			var distance: float=(point-FACE_POINT).dot(FACE_NORMAL)
			if distance<gap:gap=distance;worst=point;vertex=record.vertex_index
		query.from=worst+FACE_NORMAL*0.90
		query.to=worst-FACE_NORMAL*0.05
		var hit:=actor.get_world_3d().direct_space_state.intersect_ray(query)
		var panel_face: bool=not hit.is_empty() and hit.get("rid")==gate._panel.get_rid() \
			and Vector3(hit.get("normal",Vector3.ZERO)).dot(FACE_NORMAL)>0.999
		var hand_gap:=INF
		var worst_hand:=Vector3.ZERO
		var hand_hits:=0
		var hand_mesh: MeshInstance3D=arm.hand_mesh
		var curl: float=hand_mesh.get_blend_shape_value(0)
		for point: Dictionary in arm.hand_points:
			var actual: Vector3=hand_mesh.to_global(Vector3(point.base).lerp(Vector3(point.curl),curl))
			if actor.has_method("arm_candidate_report") and not envelope.has_point(actual):envelope_misses+=1
			if panel_box.has_point(gate._panel.to_local(actual)):hand_hits+=1
			var distance: float=(actual-FACE_POINT).dot(FACE_NORMAL)
			if distance<hand_gap:hand_gap=distance;worst_hand=actual
		query.from=worst_hand+FACE_NORMAL*0.90;query.to=worst_hand-FACE_NORMAL*0.05
		var hand_hit:=actor.get_world_3d().direct_space_state.intersect_ray(query)
		var hand_face: bool=not hand_hit.is_empty() and hand_hit.get("rid")==gate._panel.get_rid() \
			and Vector3(hand_hit.get("normal",Vector3.ZERO)).dot(FACE_NORMAL)>0.999
		var shoulder: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone(arm.prefix+"_sleeve")).origin
		var elbow: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone(arm.prefix+"_forearm")).origin
		var wrist: Vector3=rig._arms[index].hand.global_position
		observations.append({"side":arm.side,"vertex_count":arm.points.size(),"minimum_declared_plane_gap":gap,
			"envelope_misses":envelope_misses,"native_panel_sleeve_vertices_within_skin":panel_hits,"native_panel_hand_vertices_within_skin":hand_hits,
			"worst_vertex":worst,"worst_vertex_index":vertex,"worst_has_current_finite_panel_face":panel_face,
			"finite_hit_point":hit.get("position",Vector3.ZERO),"finite_hit_normal":hit.get("normal",Vector3.ZERO),
			"hand_minimum_declared_plane_gap":hand_gap,"worst_hand":worst_hand,
			"hand_vertex_count":arm.hand_points.size(),"hand_curl":curl,"worst_hand_has_current_finite_panel_face":hand_face,
			"shoulder":shoulder,"elbow":elbow,"wrist":wrist,
			"shoulder_gap":(shoulder-FACE_POINT).dot(FACE_NORMAL),"elbow_gap":(elbow-FACE_POINT).dot(FACE_NORMAL),"wrist_gap":(wrist-FACE_POINT).dot(FACE_NORMAL),
			"upper_length":shoulder.distance_to(elbow),"lower_length":elbow.distance_to(wrist)})
	var nonarm: Dictionary={}
	for bone in skeleton.get_bone_count():
		var label:=skeleton.get_bone_name(bone)
		if label.ends_with("_sleeve") or label.ends_with("_forearm"):continue
		nonarm[label]=skeleton.get_bone_pose(bone)
	var markers:=Authentic._markers(rig)
	var step:=Authentic._marker_delta(previous_markers,markers) if previous_markers.size()==markers.size() else 0.0
	maximum_marker_step=maxf(maximum_marker_step,step);previous_markers=markers
	var row: Dictionary={"candidate":actor.arm_candidate_report() if actor.has_method("arm_candidate_report") else {},
		"marker_step":step,"phase":phase,"tick":tick,"airborne":actor.airborne,"active_flip":actor._flip_remaining>0.0,
		"body":actor.global_transform,"velocity":actor.velocity,"visual":actor._visual.transform,
		"offset":actor._obstacle_visual_offset,"deck":actor._board_visual.transform,
		"rider":actor._rider_visual.transform,"grab_remaining":actor._grab_remaining,"grab_blend":rig._grab_blend,
		"on_floor":actor.is_on_floor(),"bailing":actor.bailing,"speed":actor.speed,"wallride_normal":actor._wall.normal,"arms":observations,"nonarm_bones":nonarm,"cloth":Body._sample(actor,sample_data)}
	records.append(row)
	if tick==6:print("ARM_WALL_IMAGE_POSE ",row)

func _frame() -> void:
	await physics_frame;await process_frame
	sequence_tick+=1
	var bank:=score.tick(1.0/60.0)
	if bank>0:banks.append(bank)
	if not arms.is_empty():_observe("native_history",sequence_tick)
func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
