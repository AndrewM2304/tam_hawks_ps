extends RefCounted
## M01-008 regressions use actual CharacterBody3D motion and independent fixtures.
## Run while the main gameplay scene is absent so fixture collision is isolated.

const SkaterScript = preload("res://game/player/skater.gd")
const InputSetup = preload("res://game/core/input_setup.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	InputSetup.register_actions()
	_release_actions()
	await _roll_off(tree, check, 30.0, "uphill")
	await _roll_off(tree, check, -30.0, "downhill")
	await _roll_off(tree, check, 0.0, "flat")
	await _uphill_rollback(tree, check)
	await _airborne_wall_contact(tree, check)
	_release_actions()


static func _roll_off(tree: SceneTree, check: Callable, angle_degrees: float, label: String) -> void:
	var fixture := Node3D.new()
	fixture.name = "TakeoffFixture"
	tree.root.add_child(fixture)
	var platform := _box(Vector3(10, 0.4, 16), Vector3(0, 6, 0))
	platform.rotation.x = deg_to_rad(angle_degrees)
	fixture.add_child(platform)
	var skater = SkaterScript.new()
	var spawn_z: float = 4.5
	var floor_height: float = 6.0 + 0.2 / cos(deg_to_rad(angle_degrees)) - tan(deg_to_rad(angle_degrees)) * spawn_z
	skater.spawn_position = Vector3(0, floor_height + 0.7, spawn_z)
	fixture.add_child(skater)
	await _frames(tree, 45)
	check.call(skater.is_on_floor(), "takeoff %s: fixture settles onto the intended surface" % label)
	Input.action_press("push")
	var departed: bool = false
	for i in range(180):
		var was_grounded: bool = skater.is_on_floor()
		await _frames(tree, 1)
		if was_grounded and not skater.is_on_floor():
			departed = true
			break
	Input.action_release("push")
	check.call(departed and skater.airborne,
		"takeoff %s: actual skating leaves the elevated platform lip" % label)
	if departed:
		var outgoing: Vector3 = _planar(skater.velocity)
		var departure_position: Vector3 = skater.global_position
		var outgoing_real: Vector3 = _planar(skater.get_real_velocity())
		await _frames(tree, 1)
		var next_velocity: Vector3 = _planar(skater.velocity)
		var actual_next_velocity: Vector3 = _planar(skater.get_real_velocity())
		print("TAKEOFF %s: outgoing=%s real_departure=%s next=%s real_next=%s" % [
			label, outgoing, outgoing_real, next_velocity, actual_next_velocity])
		check.call(outgoing.length() > 3.0 and not skater.is_on_floor(),
			"takeoff %s: comparison samples a moving airborne skater" % label)
		check.call(next_velocity.distance_to(outgoing) < 0.05,
			"takeoff %s: first airborne tick preserves outgoing horizontal momentum" % label)
		check.call(actual_next_velocity.distance_to(outgoing) < 0.05
			and _planar(skater.global_position - departure_position).length() > 0.01,
			"takeoff %s: actual airborne displacement matches outgoing horizontal motion" % label)
		if label == "flat":
			var before_turn: Vector3 = next_velocity
			Input.action_press("steer_left")
			await _frames(tree, 6)
			Input.action_release("steer_left")
			var after_turn: Vector3 = _planar(skater.velocity)
			check.call(absf(after_turn.length() - before_turn.length()) < 0.05,
				"takeoff steering: arcade air steering rotates without adding horizontal speed")
			check.call(before_turn.angle_to(after_turn) > 0.03
				and before_turn.angle_to(after_turn) < 0.3,
				"takeoff steering: six frames turn the carried motion by a bounded angle")
	fixture.queue_free()
	await tree.process_frame
	await _frames(tree, 1)


static func _airborne_wall_contact(tree: SceneTree, check: Callable) -> void:
	var fixture := Node3D.new()
	fixture.name = "TakeoffWallFixture"
	tree.root.add_child(fixture)
	var wall := _box(Vector3(10, 10, 0.4), Vector3(0, 5, -0.5))
	fixture.add_child(wall)
	var skater = SkaterScript.new()
	skater.spawn_position = Vector3(0, 5, 1)
	fixture.add_child(skater)
	skater.speed = 10.0
	skater.velocity = Vector3.FORWARD * 10.0
	var collided: bool = false
	for i in range(20):
		await _frames(tree, 1)
		if skater.is_on_wall():
			collided = true
			break
	check.call(collided and not skater.is_on_floor(),
		"takeoff collision: moving airborne skater actually contacts the test wall")
	var stopped: Vector3 = _planar(skater.velocity)
	check.call(stopped.length() < 0.05,
		"takeoff collision: wall removes the blocked horizontal velocity")
	# Removing a contacted wall distinguishes carried velocity from a stale speed
	# that would be reapplied and hidden by repeated collision with the same wall.
	wall.queue_free()
	await tree.process_frame
	await _frames(tree, 2)
	print("TAKEOFF collided: stopped=%s after_removal=%s real=%s speed=%.5f" % [
		stopped, _planar(skater.velocity), _planar(skater.get_real_velocity()), skater.speed])
	check.call(_planar(skater.velocity).length() < 0.05
		and _planar(skater.get_real_velocity()).length() < 0.05,
		"takeoff collision: removing the wall cannot resurrect lost airborne momentum")
	check.call(skater.speed < 0.05,
		"takeoff collision: public speed reflects the remaining horizontal motion")
	fixture.queue_free()
	await tree.process_frame
	await _frames(tree, 1)


static func _uphill_rollback(tree: SceneTree, check: Callable) -> void:
	var fixture := Node3D.new()
	fixture.name = "SlopeRollbackFixture"
	tree.root.add_child(fixture)
	var angle := deg_to_rad(20.0)
	var platform := _box(Vector3(12, 0.4, 20), Vector3(0, 6, 0))
	platform.rotation.x = angle
	fixture.add_child(platform)
	var skater = SkaterScript.new()
	var start_z := -3.0
	var floor_height := 6.0 + 0.2 / cos(angle) - tan(angle) * start_z
	skater.spawn_position = Vector3(0, floor_height + 0.7, start_z)
	fixture.add_child(skater)
	await _frames(tree, 45)
	check.call(skater.is_on_floor(), "slope rollback: skater settles on the upper part of a supported bank")
	skater.speed = 0.0
	skater.velocity = Vector3.ZERO
	var start_position: Vector3 = skater.global_position
	await _frames(tree, 60)
	var rollback_distance: float = skater.global_position.z - start_position.z
	check.call(skater.is_on_floor() and skater.speed < -0.5 and rollback_distance > 0.3,
		"slope rollback: unpowered uphill skater rolls downhill under actual contact gravity")
	print("TAKEOFF rollback: start=%s end=%s signed_speed=%.3f distance=%.3f" % [
		start_position, skater.global_position, skater.speed, rollback_distance])
	fixture.queue_free()
	await tree.process_frame
	await _frames(tree, 1)


static func _box(size: Vector3, center: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body


static func _frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame
		await tree.process_frame


static func _planar(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


static func _release_actions() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
