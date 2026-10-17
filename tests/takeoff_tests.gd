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
		var departure_frame := Engine.get_physics_frames()
		var departure_gap := _capsule_box_gap(skater, platform)
		var departure_native_clear := _native_margin_clear(skater)
		await _frames(tree, 1)
		var next_velocity: Vector3 = _planar(skater.velocity)
		var actual_next_velocity: Vector3 = _planar(skater.get_real_velocity())
		var immediate_frame := Engine.get_physics_frames()
		print("TAKEOFF %s: outgoing=%s real_departure=%s next=%s real_next=%s ticks=%d->%d initial_gap_m=%.8f safe_margin_m=%.5f native_margin_clear=%s" % [
			label, outgoing, outgoing_real, next_velocity, actual_next_velocity, departure_frame,
			immediate_frame, departure_gap, skater.safe_margin, departure_native_clear])
		check.call(outgoing.length() > 3.0 and not skater.is_on_floor(),
			"takeoff %s: comparison samples a moving airborne skater" % label)
		check.call(next_velocity.distance_to(outgoing) < 0.05,
			"takeoff %s: first airborne tick preserves outgoing horizontal momentum" % label)
		# An unsupported capsule may still be within native safe-margin recovery
		# distance of the lip. That positional separation is not carried velocity.
		# Bound it spatially, then keep the original strict speed gate in actual
		# free flight, after the complete capsule plus margin clears the platform.
		var clearance_wait := 1
		var gap := _capsule_box_gap(skater, platform)
		var native_clear := _native_margin_clear(skater)
		var elapsed := float(Engine.get_physics_frames() - departure_frame) / Engine.physics_ticks_per_second
		var recovery_error := _planar(skater.global_position - departure_position - outgoing * elapsed).length()
		while (not native_clear or gap <= skater.safe_margin) and clearance_wait < 8:
			await _frames(tree, 1)
			clearance_wait += 1
			gap = _capsule_box_gap(skater, platform)
			native_clear = _native_margin_clear(skater)
			elapsed = float(Engine.get_physics_frames() - departure_frame) / Engine.physics_ticks_per_second
			recovery_error = maxf(recovery_error,
				_planar(skater.global_position - departure_position - outgoing * elapsed).length())
		check.call(recovery_error <= skater.safe_margin + 0.0002,
			"takeoff %s: native lip separation remains within the declared spatial safe margin" % label)
		var fully_clear: bool = native_clear and gap > skater.safe_margin
		check.call(fully_clear and not skater.is_on_floor(),
			"takeoff %s: actual capsule and recovery margin clear the finite lip within eight samples" % label)
		var free_position: Vector3 = skater.global_position
		var free_frame := Engine.get_physics_frames()
		await _frames(tree, 1)
		var final_frame := Engine.get_physics_frames()
		var free_seconds := float(final_frame - free_frame) / Engine.physics_ticks_per_second
		var free_displacement: Vector3 = _planar(skater.global_position - free_position)
		var real_free: Vector3 = _planar(skater.get_real_velocity())
		var measured_free: Vector3 = free_displacement / maxf(free_seconds, 0.000001)
		print("TAKEOFF CLEAR %s: ticks=%d->%d gap_m=%.8f native_clear=%s edge_error_m=%.8f clearance_samples=%d carried=%s real=%s displacement_velocity=%s" % [
			label, free_frame, final_frame, gap, native_clear, recovery_error, clearance_wait,
			_planar(skater.velocity), real_free, measured_free])
		check.call(fully_clear and final_frame > free_frame and not skater.is_on_floor()
			and real_free.distance_to(outgoing) < 0.05 and measured_free.distance_to(outgoing) < 0.05
			and free_displacement.length() > 0.01,
			"takeoff %s: actual airborne displacement matches outgoing horizontal motion after native clearance" % label)
		if label == "flat":
			var before_turn: Vector3 = _planar(skater.velocity)
			Input.action_press("steer_left")
			await _frames(tree, 6)
			Input.action_release("steer_left")
			var after_turn: Vector3 = _planar(skater.velocity)
			check.call(absf(after_turn.length() - before_turn.length()) < 0.05,
				"takeoff steering: arcade air steering rotates without adding horizontal speed")
			check.call(before_turn.angle_to(after_turn) < 0.001 and absf(skater._spin_angle) > 0.3,
				"takeoff steering: stick input visibly spins the rider without bending carried flight")
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


static func _native_margin_clear(skater: CharacterBody3D) -> bool:
	var collision: CollisionShape3D = skater.get_node("BodyCollision")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.margin = skater.safe_margin
	query.collision_mask = skater.collision_mask
	query.exclude = [skater.get_rid()]
	return skater.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


static func _capsule_box_gap(skater: CharacterBody3D, platform: StaticBody3D) -> float:
	# Independent geometric clearance uses the actual fixture shapes/transforms.
	# Distance from the capsule axis segment to the oriented box is convex;
	# ternary search finds its closest point without using floor/contact flags.
	var capsule_node: CollisionShape3D = skater.get_node("BodyCollision")
	var box_node: CollisionShape3D = platform.get_child(0)
	var capsule: CapsuleShape3D = capsule_node.shape
	var box: BoxShape3D = box_node.shape
	var frame := box_node.global_transform.affine_inverse() * capsule_node.global_transform
	var axis_half := maxf(0.0, capsule.height * 0.5 - capsule.radius)
	var start: Vector3 = frame * Vector3(0, -axis_half, 0)
	var end: Vector3 = frame * Vector3(0, axis_half, 0)
	var half_size: Vector3 = box.size * 0.5
	var low := 0.0
	var high := 1.0
	for step in 40:
		var first := lerpf(low, high, 1.0 / 3.0)
		var second := lerpf(low, high, 2.0 / 3.0)
		if _point_box_squared(start.lerp(end, first), half_size) < _point_box_squared(start.lerp(end, second), half_size):
			high = second
		else:
			low = first
	var squared := minf(_point_box_squared(start, half_size), _point_box_squared(end, half_size))
	squared = minf(squared, _point_box_squared(start.lerp(end, (low + high) * 0.5), half_size))
	return sqrt(squared) - capsule.radius


static func _point_box_squared(point: Vector3, half_size: Vector3) -> float:
	return (point.abs() - half_size).max(Vector3.ZERO).length_squared()


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
