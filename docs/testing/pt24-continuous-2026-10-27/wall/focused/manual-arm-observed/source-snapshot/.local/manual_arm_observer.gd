extends SceneTree
## Two existing actual input poses only; observational evidence, not acceptance.
const Skater=preload("res://game/player/skater.gd")
const Arm=preload("res://tests/skater_obstacle_arm_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Gate=preload("res://game/features/service_gate.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
var passed:=0
var failed:=0

func _initialize() -> void:_run.call_deferred()

func _run() -> void:
	Setup.register_actions();Wall._release()
	var viewport:=SubViewport.new()
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var scene:=Node3D.new();viewport.add_child(scene)
	var floor:=StaticBody3D.new();scene.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-0.1;floor.add_child(collision)
	var gate:=Gate.new();scene.add_child(gate)
	gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	var actor:=Skater.new()
	actor.spawn_position=Vector3(0,0.04,-3.02);scene.add_child(actor);actor.rotation.y=PI
	var data:=Arm._skin_data(actor,gate)
	var events: Array[Dictionary]=[]
	actor.trick_performed.connect(func(label: String,points: int):events.append({"id":actor.last_trick_id,"label":label,"points":points}))
	await Wall._frames(self,4)
	var requested:=false
	var entry_speed:=0.0
	var impact:=-1
	var records: Array[Dictionary]=[]
	Input.action_press("push",0.55)
	for tick: int in 150:
		if not requested and absf(actor.speed)>=2.5 and actor.global_position.z< -1.0:
			requested=true;Input.action_press("manual")
		await Wall._frames(self,1)
		if actor.manual_active and entry_speed==0.0:entry_speed=absf(actor.speed)
		if impact<0 and Wall._wall_contact(actor,gate._panel):
			impact=tick;Input.action_release("push");Input.action_press("brake")
		var stage: String="active" if tick==78 else ("residual" if impact>=0 and tick-impact==20 else "")
		if stage=="":continue
		var pose_before:=Arm._arm_pose(actor)
		var query_before:=Arm._query_state(actor)
		var native: Dictionary=Arm._vertices(actor,data)
		var detail:=_sample(actor,gate,data)
		var fits_phase: bool=actor.manual_active and impact<0 if stage=="active" else not actor.manual_active and actor._visual_rig._manual_blend>0.0001 and impact>=0
		_check(fits_phase and actor._obstacle_manual_continuation and actor.is_on_floor() and not actor.bailing,
			"Manual arm observation: actual "+stage+" matches the already captured native grounded pose")
		_check(native.contained and detail.finite and int(native.panel_hits)==int(detail.skin_hits),
			"Manual arm observation: exact Skin/curl samples agree with the existing finite native-panel observer")
		_check(actor._obstacle_arm_fit.calls==0 and actor._obstacle_arm_fit.accepted==0 and Arm._arm_pose(actor)==pose_before and Arm._query_state(actor)==query_before,
			"Manual arm observation: presentation exclusion and read-only measurement preserve every arm pose/query field")
		records.append({"stage":stage,"tick":tick,"impact":impact,"position":actor.global_position,"velocity":actor.velocity,
			"manual_active":actor.manual_active,"manual_id":actor.manual_trick_id,"blend":actor._visual_rig._manual_blend,
			"board_pitch":actor._board_visual.rotation.x,"root_offset":actor._obstacle_visual_offset,
			"native_vertex_observer":native,"detail":detail})
		if stage=="residual":break
	Wall._release()
	_check(requested and entry_speed>=2.0 and impact==79 and events.size()==1 and events[0].id=="nose_manual" and events[0].points==100,
		"Manual arm observation: same ordinary Push/fresh Manual earns catalog Nose Manual and the expected actual panel contact")
	_check(records.size()==2,"Manual arm observation: exactly the two existing active/residual poses were sampled")
	print("MANUAL_ARM_OBSERVATION ",{"entry_speed":entry_speed,"events":events,"records":records,
		"scope":"Original exact Skin and current curl vertices inside the actual finite native shutter Box and its unchanged7.99mm skin. Intrusion counts are observations, not acceptance assertions; zero sampled vertex hits alone does not certify all triangles or every Manual variant."})
	viewport.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)

func _sample(actor: CharacterBody3D,gate: Node3D,data: Dictionary) -> Dictionary:
	var rig: RefCounted=actor._visual_rig
	var skeleton: Skeleton3D=rig._garments.skeleton
	var jacket: MeshInstance3D=data.jacket
	var palette: Array[Transform3D]=[]
	for bind: int in jacket.skin.get_bind_count():
		palette.append(skeleton.global_transform*skeleton.get_bone_global_pose(Body._bone_for(jacket.skin,skeleton,bind))*jacket.skin.get_bind_pose(bind))
	var box:=AABB(-gate._shape.size*0.5,gate._shape.size)
	var skin:=box.grow(0.00799)
	var sides: Array[Dictionary]=[]
	var skin_hits:=0
	var solid_hits:=0
	var finite:=true
	for index: int in 2:
		var sleeve:=_group()
		var hand:=_group()
		for record: Dictionary in data.sleeves[index]:
			var point:=Vector3.ZERO
			for influence: int in record.binds.size():
				point+=(palette[record.binds[influence]]*Vector3(record.point))*float(record.weights[influence])
			_accumulate(sleeve,gate._panel.to_local(point),box,skin)
		var mesh: MeshInstance3D=rig._arms[index].hand.get_node("HandAndFingers")
		for record: Dictionary in data.hands[index]:
			var point: Vector3=mesh.to_global(Vector3(record.base).lerp(Vector3(record.curl),mesh.get_blend_shape_value(0)))
			_accumulate(hand,gate._panel.to_local(point),box,skin)
		for group: Dictionary in [sleeve,hand]:
			skin_hits+=int(group.skin_hits);solid_hits+=int(group.solid_hits);finite=finite and group.finite
		sides.append({"side":"left" if index==0 else "right","sleeve":sleeve,"hand":hand})
	return {"finite":finite,"skin_hits":skin_hits,"solid_hits":solid_hits,"sides":sides}

func _group() -> Dictionary:
	return {"vertices":0,"finite":true,"skin_hits":0,"solid_hits":0,"minimum_north_gap":INF,"cross_section_vertices":0,"deepest_panel_point":Vector3.ZERO}

func _accumulate(group: Dictionary,point: Vector3,box: AABB,skin: AABB) -> void:
	group.vertices+=1
	group.finite=group.finite and point.is_finite()
	group.skin_hits+=int(skin.has_point(point))
	group.solid_hits+=int(box.has_point(point))
	# This signed gap is limited to the finite panel's enlarged XY footprint.
	# Solid and skin hit counts above additionally require finite Z containment.
	if point.x>=skin.position.x and point.x<=skin.end.x and point.y>=skin.position.y and point.y<=skin.end.y:
		group.cross_section_vertices+=1
		var gap:=box.position.z-point.z
		if gap<float(group.minimum_north_gap):
			group.minimum_north_gap=gap;group.deepest_panel_point=point

func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
