extends RefCounted
## Native presentation/contact regressions. Initial active-manual fixtures are
## declared below; no transform, velocity or score is corrected during travel.

const Skater = preload("res://game/player/skater.gd")
const Terrain = preload("res://game/levels/core_terrain.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Geometry = preload("res://tests/board_geometry_tests_support.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")

class UnfittedSkater extends "res://game/player/skater.gd":
	# Negative control retains the former capsule-normal presentation. There
	# is no product option to disable contact or relax any clearance threshold.
	func _place_manual_wheels() -> void:
		pass


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	var legacy_failed := {"manual": false, "nose_manual": false}
	for id: String in ["manual", "nose_manual"]:
		for grade: String in ["downhill_to_flat", "flat_to_bank", "split_rear_planes", "flat_control"]:
			var evidence := await _crossing(tree, check, id, grade)
			if float(evidence.legacy_gap)<-0.004: legacy_failed[id]=true
	check.call(legacy_failed.manual and legacy_failed.nose_manual,
		"PT24 manual grade: unchanged capsule-normal controls reproduce real tyre penetration for both Manual and Nose Manual")
	_release()


static func _crossing(tree: SceneTree, check: Callable, id: String, grade: String) -> Dictionary:
	_release()
	var fixture := await _fixture(tree,grade)
	var rider: CharacterBody3D = fixture.rider
	var control: CharacterBody3D = fixture.control
	var sign_value := -1.0 if id=="nose_manual" else 1.0
	# Both riders receive exactly the same initial active-contact state. This
	# is a contact regression, not a claimed earned manual or scored route.
	for body: CharacterBody3D in [rider,control]:
		body.manual_active=true
		body.manual_trick_id=id
		body.manual_id=id
		body._manual_base_sign=sign_value
		body.manual_balance=0.05
		body.speed=4.0
		body.velocity=-body.global_basis.z*4.0
	Input.action_press("manual")
	var minimum := INF
	var legacy_minimum := INF
	var legacy_maximum := -INF
	var maximum_loaded_gap := -INF
	var maximum_sole_error := 0.0
	var physical_parity := true
	var local_pivot_parity := true
	var planar_pose_parity := true
	var minimum_pitch := INF
	var samples := 0
	var crossed := false
	for tick: int in 90:
		# This is the ordinary mapped balance correction; both actors receive
		# the same input, and their physical histories must remain identical.
		var correction: float=-(0.18+0.08*rider._manual_elapsed)/rider.MANUAL_BALANCE_CONTROL \
			-(rider.manual_balance-0.05)*1.2
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if correction<0: Input.action_press("steer_left",-correction)
		else: Input.action_press("steer_right",correction)
		await _frames(tree,1)
		physical_parity=physical_parity and _physics(rider)==_physics(control)
		local_pivot_parity=local_pivot_parity \
			and rider._board_visual.transform==control._board_visual.transform
		var coordinate: float=rider.global_position.x if grade=="flat_to_bank" else rider.global_position.z
		crossed=crossed or coordinate>0.8
		if coordinate>0.85 and samples>=8: break
		if tick<18 or absf(coordinate)>0.75: continue
		var actual := _loaded_clearance(rider)
		var old := _loaded_clearance(control)
		minimum=minf(minimum,float(actual.minimum))
		legacy_minimum=minf(legacy_minimum,float(old.minimum))
		legacy_maximum=maxf(legacy_maximum,float(old.maximum))
		maximum_loaded_gap=maxf(maximum_loaded_gap,float(actual.maximum))
		minimum_pitch=minf(minimum_pitch,absf(rider._board_visual.rotation.x))
		for leg: Dictionary in rider._visual_rig._legs:
			maximum_sole_error=maxf(maximum_sole_error,
				Geometry.grip_distance(rider._visual_rig,leg.foot.to_global(Footwear.SOLE_CONTACT)))
		if grade=="flat_control":
			planar_pose_parity=planar_pose_parity and rider._visual.transform==control._visual.transform
		samples+=1
	var tag := id+" "+grade
	check.call(crossed and samples>=8 and rider.manual_active and control.manual_active
		and not rider.bail_active and not control.bail_active,
		"PT24 manual grade: native active-axle fixture traverses the actual finite support "+tag)
	check.call(minimum>=-0.001 and maximum_loaded_gap<0.030,
		"PT24 manual grade: both loaded real tyre rims remain supported without penetration or floating "+tag)
	check.call(physical_parity and local_pivot_parity and minimum_pitch>deg_to_rad(12.0)
		and maximum_sole_error<0.004,
		"PT24 manual grade: physics, local 16-degree pitch/axle pivot and planted shoe contacts are preserved "+tag)
	if grade=="flat_control":
		check.call(planar_pose_parity,
			"PT24 manual grade: already correct planar presentation is exactly unchanged "+id)
	elif grade=="split_rear_planes":
		check.call(legacy_maximum>0.040 and maximum_loaded_gap<0.030,
			"PT24 manual grade: actual two-height axle supports both wheels instead of floating the lower-side tyre "+id)
	print("PT24_MANUAL_GRADE ",{"id":id,"grade":grade,"samples":samples,
		"minimum_native_gap":minimum,"maximum_loaded_gap":maximum_loaded_gap,
		"legacy_gap":legacy_minimum,"legacy_maximum":legacy_maximum,"minimum_pitch":minimum_pitch,"sole_error":maximum_sole_error,
		"physics_equal":physical_parity,"pivot_equal":local_pivot_parity,"crossed":crossed})
	_release()
	fixture.viewport.queue_free()
	await tree.process_frame
	return {"legacy_gap":legacy_minimum}


static func _loaded_clearance(rider: CharacterBody3D) -> Dictionary:
	var minimum := INF
	var maximum := -INF
	var space := rider.get_world_3d().direct_space_state
	var excluded: Array[RID] = [rider.get_rid()]
	for wheel: Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		if Vector3(wheel.center).z*rider._board_visual.rotation.x<=0: continue
		var lowest := INF
		for vertex: Vector3 in wheel.points:
			var point: Vector3=rider._board_visual.to_global(vertex)
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(
				point+Vector3.UP*0.12,point-Vector3.UP*0.20,1|8,excluded))
			if not hit.is_empty() and Vector3(hit.normal).y>0.5:
				lowest=minf(lowest,(point-Vector3(hit.position)).dot(hit.normal))
		minimum=minf(minimum,lowest)
		maximum=maxf(maximum,lowest)
	return {"minimum":minimum,"maximum":maximum}


static func _physics(body: CharacterBody3D) -> Dictionary:
	return {"transform":body.global_transform,"velocity":body.velocity,"speed":body.speed,
		"floor":body.is_on_floor(),"normal":body.get_floor_normal(),"air":body.airborne,
		"manual":body.manual_active,"balance":body.manual_balance,"age":body._manual_elapsed,
		"bail":body.bail_active,"capsule":body.get_node("BodyCollision").transform}


static func _fixture(tree: SceneTree, grade: String) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.own_world_3d=true
	viewport.size=Vector2i(640,480)
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	var terrain := Terrain.new()
	var material := StandardMaterial3D.new()
	var spawn := Vector3(0,0.08,-2.0)
	var yaw := PI
	if grade=="flat_to_bank":
		terrain.add_patch(root,"ManualFlat",Rect2(-12,-8,12,16),Vector4.ZERO,material)
		terrain.add_patch(root,"ManualBank",Rect2(0,-8,12,16),Vector4(0,2.4,2.4,0),material)
		spawn=Vector3(-2,0.08,0)
		yaw=-PI*0.5
	elif grade=="split_rear_planes":
		terrain.add_patch(root,"ManualLowerPlane",Rect2(-12,-12,12,24),Vector4.ZERO,material)
		terrain.add_patch(root,"ManualUpperPlane",Rect2(0,-12,12,24),Vector4.ONE*0.05,material)
		spawn.y=0.05+0.08
	elif grade=="downhill_to_flat":
		terrain.add_patch(root,"ManualDescending",Rect2(-8,-12,16,12),Vector4(12.0/7.0,12.0/7.0,0,0),material)
		terrain.add_patch(root,"ManualLanding",Rect2(-8,0,16,14),Vector4.ZERO,material)
		spawn.y=2.0/7.0+0.08
	else:
		terrain.add_patch(root,"ManualPlanarControl",Rect2(-12,-12,24,24),Vector4.ZERO,material)
	var rider=Skater.new()
	var control=UnfittedSkater.new()
	for body: CharacterBody3D in [rider,control]:
		body.spawn_position=spawn
		root.add_child(body)
		body.rotation.y=yaw
	await _frames(tree,40)
	return {"viewport":viewport,"rider":rider,"control":control}


static func _frames(tree: SceneTree,count: int) -> void:
	for tick: int in count:
		await tree.physics_frame
		await tree.create_timer(0.0,false,false).timeout


static func _release() -> void:
	for id: StringName in InputMap.get_actions(): Input.action_release(id)
