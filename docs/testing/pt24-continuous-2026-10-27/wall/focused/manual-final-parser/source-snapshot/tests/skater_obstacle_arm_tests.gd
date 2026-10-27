extends RefCounted
## Current input earns the same native wall/Flip history in isolated twins.
## Only the test control replaces the presentation helper with a no-op.
const Skater = preload("res://game/player/skater.gd")
const Fit = preload("res://game/player/skater_obstacle_arm_fit.gd")
const Gate = preload("res://game/features/service_gate.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Body = preload("res://tests/skater_body_attachment_tests.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Wall = preload("res://tests/skater_wall_presentation_tests.gd")
const Score = preload("res://game/scoring/score_session.gd")

class NoArmFit extends RefCounted:
	func prepare(_body: CharacterBody3D) -> void:pass
	func reset() -> void:pass
	func apply(_delta: float) -> void:pass

static func run(tree: SceneTree,check: Callable) -> void:
	Setup.register_actions();Wall._release()
	var f:=_fixture(tree,false)
	var twin:=_fixture(tree,true)
	var rider: CharacterBody3D=f.rider
	var control: CharacterBody3D=twin.rider
	var data:=_skin_data(rider,f.gate)
	var old_data:=_skin_data(control,twin.gate)
	var attachment:=Body._prepare(rider._visual_rig)
	var score:=Score.new()
	var entries: Array[Dictionary]=[]
	var banks: Array[int]=[]
	var on_trick:=func(label: String,points: int):
		entries.append({"id":rider.last_trick_id,"points":points})
		score.add_trick(label,points,rider.last_trick_id)
	rider.trick_performed.connect(on_trick)
	rider.landed.connect(func(ok: bool):
		if ok:score.begin_landing()
		else:score.drop_combo())
	rider.combo_link_started.connect(score.continue_combo)
	rider.combo_link_ended.connect(score.begin_landing)
	var reached: bool=await _approach(tree,f)
	check.call(reached and rider.airborne and rider._obstacle_ollie_continuation and rider._obstacle_visual_offset.length()>0.10,
		"free arm: ordinary Push/Brake/Ollie earns real finite shutter flight before Flip")
	var ids: Array[int]=[rider._grind_board_query.get_instance_id(),rider._grind_board_box.get_instance_id(),rider._recovery_floor_query.get_instance_id()]
	var physical:=true
	var nonarm:=true
	var far:=true
	var fixed:=true
	var contained:=true
	var skin:=true
	var cloth:=true
	var old_intrusion:=0
	var active:=0
	var previous: Array[Vector3]=[]
	var marker_step:=0.0
	Input.action_press("flip")
	for tick: int in 90:
		if tick==6:Input.action_release("flip")
		await Wall._frames(tree,1)
		var bank:=score.tick(1.0/60.0)
		if bank>0:banks.append(bank)
		active+=int(rider._flip_remaining>0)
		physical=physical and Wall._physics(rider)==Wall._physics(control) and rider._visual.transform==control._visual.transform \
			and rider._board_visual.transform==control._board_visual.transform and rider._rider_visual.transform==control._rider_visual.transform
		nonarm=nonarm and _nonarm(rider)==_nonarm(control)
		var rig: RefCounted=rider._visual_rig
		var skeleton: Skeleton3D=rig._garments.skeleton
		var other: Skeleton3D=control._visual_rig._garments.skeleton
		for index: int in 2:
			var arm: Dictionary=rider._obstacle_arm_fit.arms[index]
			var shoulder:=skeleton.global_transform*skeleton.get_bone_global_pose(arm.upper).origin
			var elbow:=skeleton.global_transform*skeleton.get_bone_global_pose(arm.lower).origin
			var wrist: Vector3=rig._arms[index].hand.global_position
			fixed=fixed and absf(shoulder.distance_to(elbow)-0.30)<0.00001 and absf(elbow.distance_to(wrist)-0.29)<0.00001
			if index==1:
				far=far and skeleton.get_bone_pose(arm.upper)==other.get_bone_pose(arm.upper) and skeleton.get_bone_pose(arm.lower)==other.get_bone_pose(arm.lower) \
					and rig._arms[index].hand.transform==control._visual_rig._arms[index].hand.transform
		var actual:=_vertices(rider,data)
		contained=contained and actual.contained
		if rider._obstacle_arm_fit.accepted>0:skin=skin and actual.panel_hits==0
		old_intrusion+=int(_vertices(control,old_data).panel_hits)
		var sample:=Body._sample(rider,attachment)
		cloth=cloth and sample.finite and sample.seam<0.12 and sample.joint_gap<0.10 and sample.neck_gap<0.05
		var markers: Array[Vector3]=[]
		for marker: Vector3 in Authentic._markers(rig):markers.append(rider.to_local(marker))
		if previous.size()==markers.size():marker_step=maxf(marker_step,Authentic._marker_delta(previous,markers))
		previous=markers
	Wall._release()
	check.call(active>=15 and entries==[{"id":"ollie","points":100},{"id":"kickflip","points":300}] and banks==[800] and score.total_score==800,
		"free arm: actual native Flip and supported landing preserve exact catalog events and one800-point bank")
	check.call(old_intrusion>0 and rider._obstacle_arm_fit.accepted>=40 and skin,
		"free arm: former native sleeve/hand intrusion is removed with existing8mm finite-panel skin through catch/landing")
	check.call(physical and nonarm and far and rider.is_on_floor() and not rider.bailing,
		"free arm: exact physical/root/board/nonarm-bone and unblocked-arm twins remain unchanged")
	check.call(fixed and contained and cloth and marker_step<0.22,
		"free arm: original Skin/curl vertices stay inside conservative bounds with fixed .30/.29 lengths, attached clothes and220mm body-relative continuity")
	check.call(ids==[rider._grind_board_query.get_instance_id(),rider._grind_board_box.get_instance_id(),rider._recovery_floor_query.get_instance_id()] \
		and rider._obstacle_arm_fit.maximum_calls<=12 and rider._obstacle_arm_fit.maximum_shift<=0.20,
		"free arm: same three query resources retain twelve-call and20cm free-wrist caps")
	print("FREE_ARM_NATIVE ",{"accepted":rider._obstacle_arm_fit.accepted,"refused":rider._obstacle_arm_fit.refused,
		"maximum_calls":rider._obstacle_arm_fit.maximum_calls,"maximum_shift":rider._obstacle_arm_fit.maximum_shift,
		"old_panel_vertices":old_intrusion,"body_marker_step":marker_step,"banks":banks})
	rider.begin_bail("free_arm_contract")
	check.call(not rider._obstacle_arm_fit.continuing and rider._obstacle_arm_fit.calls==0,"free arm: actual begin_bail immediately clears continuation")
	rider._obstacle_arm_fit.continuing=true;rider.reset_skater()
	check.call(not rider._obstacle_arm_fit.continuing and rider._obstacle_arm_fit.accepted==0,"free arm: actual restart clears all retained fit state")
	f.viewport.queue_free();twin.viewport.queue_free();await tree.process_frame
	await _controls(tree,check)
	Wall._release()

static func _fixture(tree: SceneTree,unfitted: bool) -> Dictionary:
	var viewport:=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
	var root:=Node3D.new();viewport.add_child(root)
	var floor:=StaticBody3D.new();root.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-0.1;floor.add_child(collision)
	var gate:=Gate.new();root.add_child(gate);gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	var rider:=Skater.new()
	if unfitted:rider._obstacle_arm_fit=NoArmFit.new()
	rider.spawn_position=Vector3(0,0.04,-3);root.add_child(rider);rider.rotation.y=PI
	return {"viewport":viewport,"root":root,"rider":rider,"gate":gate}

static func _approach(tree: SceneTree,f: Dictionary) -> bool:
	await Wall._frames(tree,10)
	var reached:=false
	Input.action_press("push",0.55)
	for tick: int in 180:
		await Wall._frames(tree,1)
		if Wall._wall_contact(f.rider,f.gate._panel):reached=true;break
	Wall._release();Input.action_press("brake");await Wall._frames(tree,20)
	Wall._release();await Wall._frames(tree,2)
	Input.action_press("ollie");await Wall._frames(tree,20)
	Wall._release();await Wall._frames(tree,2)
	return reached

static func _nonarm(actor: CharacterBody3D) -> Array[Transform3D]:
	var skeleton: Skeleton3D=actor._visual_rig._garments.skeleton
	var poses: Array[Transform3D]=[]
	for bone: int in skeleton.get_bone_count():
		var label:=skeleton.get_bone_name(bone)
		if not label.ends_with("_sleeve") and not label.ends_with("_forearm"):poses.append(skeleton.get_bone_pose(bone))
	return poses

static func _skin_data(actor: CharacterBody3D,gate: Node3D = null) -> Dictionary:
	var rig: RefCounted=actor._visual_rig
	var skeleton: Skeleton3D=rig._garments.skeleton
	var jacket: MeshInstance3D=rig._rider.get_node("SkinnedJacket")
	var arrays:=jacket.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var binds: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	var stride:=binds.size()/vertices.size()
	var sleeves: Array[Array]=[]
	var hands: Array[Array]=[]
	for side: String in ["left","right"]:
		var points: Array[Dictionary]=[]
		for index: int in vertices.size():
			var weight:=0.0
			for influence: int in stride:
				var bone:=Body._bone_for(jacket.skin,skeleton,binds[index*stride+influence])
				if skeleton.get_bone_name(bone) in [side+"_sleeve",side+"_forearm"]:weight+=weights[index*stride+influence]
			if weight>0.001:points.append({"point":vertices[index],"binds":binds.slice(index*stride,(index+1)*stride),"weights":weights.slice(index*stride,(index+1)*stride)})
		sleeves.append(points)
		var mesh: MeshInstance3D=rig._arms[hands.size()].hand.get_node("HandAndFingers")
		var hand_points: Array[Dictionary]=[]
		for surface: int in mesh.mesh.get_surface_count():
			var base: PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var curl: PackedVector3Array=mesh.mesh.surface_get_blend_shape_arrays(surface)[0][Mesh.ARRAY_VERTEX]
			for index: int in base.size():hand_points.append({"base":base[index],"curl":curl[index]})
		hands.append(hand_points)
	return {"jacket":jacket,"sleeves":sleeves,"hands":hands,"gate":gate}

static func _vertices(actor: CharacterBody3D,data: Dictionary) -> Dictionary:
	var rig: RefCounted=actor._visual_rig
	var skeleton: Skeleton3D=rig._garments.skeleton
	var jacket: MeshInstance3D=data.jacket
	var palette: Array[Transform3D]=[]
	for bind: int in jacket.skin.get_bind_count():palette.append(skeleton.global_transform*skeleton.get_bone_global_pose(Body._bone_for(jacket.skin,skeleton,bind))*jacket.skin.get_bind_pose(bind))
	# This is the actual declared finite shutter Box including the unchanged
	# native7.99mm skin, not an infinite plane or an arm-joint proxy.
	var gate: Node3D=data.gate
	var panel:=AABB(-gate._shape.size*0.5,gate._shape.size).grow(0.00799)
	var contained:=true
	var panel_hits:=0
	for index: int in 2:
		var bound:=AABB()
		if actor._obstacle_arm_fit is Fit:bound=actor._obstacle_arm_fit._bounds(actor._obstacle_arm_fit.arms[index],{},rig._arms[index].hand.global_transform).grow(0.00001)
		for record: Dictionary in data.sleeves[index]:
			var point:=Vector3.ZERO
			for influence: int in record.binds.size():point+=(palette[record.binds[influence]]*Vector3(record.point))*float(record.weights[influence])
			if actor._obstacle_arm_fit is Fit:contained=contained and bound.has_point(point)
			panel_hits+=int(panel.has_point(gate._panel.to_local(point)))
		var mesh: MeshInstance3D=rig._arms[index].hand.get_node("HandAndFingers")
		for record: Dictionary in data.hands[index]:
			var point: Vector3=mesh.to_global(Vector3(record.base).lerp(Vector3(record.curl),mesh.get_blend_shape_value(0)))
			if actor._obstacle_arm_fit is Fit:contained=contained and bound.has_point(point)
			panel_hits+=int(panel.has_point(gate._panel.to_local(point)))
	return {"contained":contained,"panel_hits":panel_hits}

static func _controls(tree: SceneTree,check: Callable) -> void:
	var f:=_fixture(tree,true)
	var actor: CharacterBody3D=f.rider
	var gate: Node3D=f.gate
	var reached: bool=await _approach(tree,f)
	Input.action_press("flip");await Wall._frames(tree,6);Wall._release();actor.set_physics_process(false)
	check.call(reached and actor.airborne and actor._flip_remaining>0 and actor._obstacle_ollie_continuation,"free arm controls: earned native Flip6 is the negative-contract baseline")
	var helper:=Fit.new();helper.prepare(actor)
	var baseline:=_arm_pose(actor)
	var restored: Dictionary={}
	var query_before:=_query_state(actor)
	helper.apply(1.0/60.0)
	check.call(helper.accepted>0 and _arm_pose(actor)!=baseline and helper.maximum_calls<=12,"live finite arm envelope earns a bounded correction")
	check.call(_query_state(actor)==query_before,"positive correction restores every reused query field")
	for spec: Array in [[actor,"manual_active"],[actor,"bailing"],[actor,"lip_active"],[actor,"powersliding"],[actor._grind,"active"],[actor._wall,"active"],[actor._transition,"active"],[actor._feature_transition,"active"],[actor._setup,"active"],[actor._skitch,"active"]]:
		var object: Object=spec[0];var key: String=spec[1];var prior: Variant=object.get(key)
		restored=_restore_pose(actor,baseline);object.set(key,true);helper.continuing=true;var accepted: int=helper.accepted;helper.apply(1.0/60.0)
		check.call(helper.calls==0 and helper.accepted==accepted and _arm_pose(actor)==restored and not helper.continuing,"active contact guard "+str(spec)+" has no arm or query effects")
		object.set(key,prior)
	for key: String in ["_grab_remaining","_special_remaining"]:
		var prior: float=actor.get(key);restored=_restore_pose(actor,baseline);actor.set(key,0.1);helper.continuing=true
		var accepted: int=helper.accepted;helper.apply(1.0/60.0)
		check.call(helper.calls==0 and helper.accepted==accepted and _arm_pose(actor)==restored and not helper.continuing,"active trick guard "+key+" has no arm or query effects")
		actor.set(key,prior)
	for key: String in ["_grab_blend","_skitch_blend","_pogo_blend","_handplant_blend","_manual_blend","_walk_blend","_cross_blend","_casper_blend","_manual_weight_z","_front_foot_lift","_rear_foot_lift","_grind_blend","_lip_blend","_wall_blend","_transition_blend","_slide_blend","_bail_blend"]:
		var rig: RefCounted=actor._visual_rig;var prior: float=rig.get(key);restored=_restore_pose(actor,baseline);rig.set(key,0.1);helper.continuing=true
		var accepted: int=helper.accepted;helper.apply(1.0/60.0)
		check.call(helper.calls==0 and helper.accepted==accepted and _arm_pose(actor)==restored and not helper.continuing,"residual contact guard "+key+" has no arm or query effects")
		rig.set(key,prior)
	var axis: Vector3=actor._obstacle_visual_offset
	for value: Vector3 in [Vector3.ZERO,-axis,Vector3(NAN,0,0),axis.normalized()*0.181]:
		restored=_restore_pose(actor,baseline);actor._obstacle_visual_offset=value;helper.continuing=false;var accepted: int=helper.accepted
		helper.apply(1.0/60.0)
		check.call(helper.accepted==accepted and _arm_pose(actor)==restored and _query_state(actor)==query_before,"absent, opposite, nonfinite or over-cap axis refuses stale plane authority: "+str(value))
	actor._obstacle_visual_offset=axis
	restored=_restore_pose(actor,baseline);var armed: bool=actor._obstacle_ollie_continuation;actor._obstacle_ollie_continuation=false;helper.continuing=false;helper.apply(1.0/60.0)
	check.call(helper.calls==0 and _arm_pose(actor)==restored,"unarmed ordinary pose adds zero native queries")
	actor._obstacle_ollie_continuation=armed
	var panel_frame: Transform3D=gate._panel.transform
	gate._panel.position+=Vector3(5,0,0);await Wall._frames(tree,1);restored=_restore_pose(actor,baseline);helper.continuing=true;var accepted: int=helper.accepted;helper.apply(1.0/60.0)
	check.call(helper.accepted==accepted and _arm_pose(actor)==restored and not helper.continuing and _query_state(actor)==query_before,"moved-away actual finite panel clears continuation without remembered plane")
	gate._panel.transform=panel_frame;await Wall._frames(tree,1)
	var panel_size: Vector3=gate._shape.size
	gate._shape.size=Vector3(panel_size.x,0.05,panel_size.z);await Wall._frames(tree,1);restored=_restore_pose(actor,baseline);helper.continuing=true;accepted=helper.accepted;helper.apply(1.0/60.0)
	check.call(helper.accepted==accepted and _arm_pose(actor)==restored and not helper.continuing and _query_state(actor)==query_before,"short finite panel does not extend an infinite arm correction above its edge")
	gate._shape.size=panel_size;await Wall._frames(tree,1)
	var blocker:=StaticBody3D.new();var solid:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(3,3,3);solid.shape=box;blocker.add_child(solid);f.root.add_child(blocker);blocker.global_position=actor._rider_visual.global_position;await Wall._frames(tree,1)
	restored=_restore_pose(actor,baseline);helper.continuing=false;accepted=helper.accepted;helper.apply(1.0/60.0)
	check.call(helper.accepted==accepted and _arm_pose(actor)==restored and _query_state(actor)==query_before and helper.calls<=12,"corner/enclosing solid refuses unsafe shoulder or full-envelope fit within unchanged budget")
	blocker.queue_free();await tree.process_frame
	f.viewport.queue_free();await tree.process_frame

static func _arm_pose(actor: CharacterBody3D) -> Dictionary:
	var rig: RefCounted=actor._visual_rig;var skeleton: Skeleton3D=rig._garments.skeleton
	var bones: Array[Transform3D]=[]
	for bone: int in skeleton.get_bone_count():bones.append(skeleton.get_bone_pose(bone))
	return {"bones":bones,"left_hand":rig._arms[0].hand.transform,"right_hand":rig._arms[1].hand.transform}

static func _restore_pose(actor: CharacterBody3D,baseline: Dictionary) -> Dictionary:
	var rig: RefCounted=actor._visual_rig;var skeleton: Skeleton3D=rig._garments.skeleton
	for bone: int in skeleton.get_bone_count():skeleton.set_bone_pose(bone,baseline.bones[bone])
	rig._arms[0].hand.transform=baseline.left_hand;rig._arms[1].hand.transform=baseline.right_hand
	# Exact comparison begins after the fixture's native decomposition/recompose.
	return _arm_pose(actor)

static func _query_state(actor: CharacterBody3D) -> Dictionary:
	var q: PhysicsShapeQueryParameters3D=actor._grind_board_query;var ray: PhysicsRayQueryParameters3D=actor._recovery_floor_query
	return {"shape":q.shape,"margin":q.margin,"transform":q.transform,"motion":q.motion,"size":actor._grind_board_box.size,"mask":q.collision_mask,"exclude":q.exclude.duplicate(),"bodies":q.collide_with_bodies,"areas":q.collide_with_areas,"from":ray.from,"to":ray.to,"raymask":ray.collision_mask,"rayexclude":ray.exclude.duplicate(),"raybodies":ray.collide_with_bodies,"rayareas":ray.collide_with_areas,"rayback":ray.hit_back_faces,"rayinside":ray.hit_from_inside}
