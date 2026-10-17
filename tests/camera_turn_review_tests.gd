extends RefCounted
## Actual mapped inputs on a clear isolated floor. Placement is initial only;
## no per-tick motion, heading or camera assignment is used by these routes.

const Skater = preload("res://game/player/skater.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Chase = preload("res://game/player/chase_camera.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	for start_speed: float in [8.0, 12.0, 15.0]:
		var measures: Array[Dictionary] = []
		for strength: float in [0.25, 0.5, 1.0]:
			measures.append(await _turn(tree, check, start_speed, strength))
		check.call(measures[2].heading > measures[0].heading * 4.0
			and measures[2].radius < measures[0].radius * 0.3
			and measures[1].heading > measures[0].heading * 1.9
			and measures[1].heading < measures[2].heading * 0.5,
			"classic turns: %.0fm/s full input carves while half/quarter input remain progressively finer corrections" % start_speed)
	await _rollback_camera(tree, check)
	var chase = Chase.new()
	for tick in 10: chase._direction_sign(Vector3(0, 0, 3), Vector3.BACK, 1.0 / 60.0)
	check.call(chase._travel_sign == 1.0,
		"classic camera: a brief backwards impulse cannot reverse the chase")
	for tick in 30: chase._direction_sign(Vector3(0, 0, 0.1), Vector3.BACK, 1.0 / 60.0)
	check.call(chase._travel_sign == 1.0 and chase._direction_confirm == 0.0,
		"classic camera: low-speed direction noise clears pending reversal")
	_release()


static func _turn(tree: SceneTree, check: Callable, requested_speed: float, strength: float) -> Dictionary:
	var fixture := await _fixture(tree)
	var rider: CharacterBody3D = fixture.rider
	Input.action_press("push")
	for tick in 100:
		await _frames(tree, 1)
		if rider.speed >= requested_speed - 0.01: break
	var initial_speed: float = rider.speed
	Input.action_release("push")
	Input.action_press("steer_left", strength)
	var previous: Vector3 = rider.global_position
	var previous_yaw := rider.rotation.y
	var distance := 0.0
	var heading := 0.0
	var unsafe := 0
	for tick in 60:
		await _frames(tree, 1)
		distance += previous.distance_to(rider.global_position)
		heading += angle_difference(previous_yaw, rider.rotation.y)
		previous = rider.global_position
		previous_yaw = rider.rotation.y
		unsafe += int(not _framed(rider))
	var radius := distance / absf(heading)
	check.call(initial_speed >= requested_speed - 0.05 and initial_speed <= requested_speed + 0.2
		and rider.is_on_floor() and heading > 0.3 and distance > 4.0 and unsafe == 0,
		"classic turns: %.0fm/s input %.2f stays supported, turns left and keeps the whole skater framed" % [requested_speed, strength])
	check.call((strength == 0.25 and heading < 0.50)
		or (strength == 0.5 and heading > 0.8 and heading < 1.1)
		or (strength == 1.0 and heading > 1.9 and heading < 2.5),
		"classic turns: %.0fm/s input %.2f gives a bounded useful one-second angle" % [requested_speed, strength])
	print("CLASSIC TURN initial=%.3f final=%.3f input=%.2f angle_deg=%.3f distance=%.3f effective_radius=%.3f unsafe=%d" % [
		initial_speed, rider.speed, strength, rad_to_deg(heading), distance, radius, unsafe])
	await _dispose(tree, fixture)
	return {"heading": heading, "radius": radius}


static func _rollback_camera(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, true)
	var rider: CharacterBody3D = fixture.rider
	var unsafe := 0
	var near_floor := true
	for tick in 180:
		await _frames(tree, 1)
		unsafe += int(not _framed(rider))
		near_floor = near_floor and rider.is_on_floor()
	var camera: Camera3D = rider._camera
	var travel := Vector3(rider.velocity.x, 0, rider.velocity.z).normalized()
	var rear := Vector3(camera.global_position.x - rider.global_position.x, 0,
		camera.global_position.z - rider.global_position.z).normalized()
	check.call(rider.speed < -2.0 and near_floor and rear.dot(travel) < -0.7 and unsafe == 0,
		"classic camera: sustained actual bank rollback moves chase behind travel without hiding rider or board")
	print("CLASSIC REVERSE speed=%.3f camera_dot_travel=%.3f unsafe=%d" % [rider.speed, rear.dot(travel), unsafe])
	await _dispose(tree, fixture)


static func _framed(rider: CharacterBody3D) -> bool:
	var camera: Camera3D = rider._camera
	var normal := Vector3.UP
	if "transition_active" in rider and rider.transition_active: normal = rider.transition_normal
	if not camera.global_position.is_finite(): return false
	var space := rider.get_world_3d().direct_space_state
	for height: float in [0.12, 1.05, 1.8]:
		var point := rider.global_position + normal * height
		if not camera.is_position_in_frustum(point): return false
		var ray := PhysicsRayQueryParameters3D.create(camera.global_position, point, 1)
		if not space.intersect_ray(ray).is_empty(): return false
	return true


static func _fixture(tree: SceneTree, bank: bool = false) -> Dictionary:
	_release()
	var root := Node3D.new()
	tree.root.add_child(root)
	var floor := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(180, 0.4, 180)
	shape.shape = box
	floor.add_child(shape)
	floor.position.y = 10.0 if bank else -0.2
	var angle := deg_to_rad(20.0) if bank else 0.0
	floor.rotation.x = angle
	root.add_child(floor)
	var rider = Skater.new()
	rider.spawn_position = Vector3(0, 10.0 + 0.2 / cos(angle) + 0.8 if bank else 0.8, 0)
	root.add_child(rider)
	if bank: Input.action_press("brake")
	await _frames(tree, 45)
	_release()
	return {"root": root, "rider": rider}


static func _dispose(tree: SceneTree, fixture: Dictionary) -> void:
	_release()
	fixture.root.queue_free()
	await tree.process_frame
	await _frames(tree, 1)


static func _frames(tree: SceneTree, count: int) -> void:
	for tick in count:
		await tree.physics_frame
		await tree.process_frame


static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
