extends RefCounted
## Native interpolation at deliberately low physics/high render cadence, followed
## by identical real-input physical trajectories with presentation on and off.
## No render result here certifies Mac frame time or display comfort.

const Skater = preload("res://game/player/skater.gd")
const Setup = preload("res://game/core/input_setup.gd")


class FrameSensor extends Node:
	var rider: CharacterBody3D
	var enabled := false
	var samples: Array[Dictionary] = []
	func _process(_delta: float) -> void:
		if not enabled or not is_instance_valid(rider): return
		var frame := rider.get_global_transform_interpolated()
		var collision := rider.get_node("BodyCollision") as Node3D
		var up := collision.get_global_transform_interpolated().basis.y.normalized()
		samples.append({"physics": Engine.get_physics_frames(), "raw": rider.global_position,
			"rendered": frame.origin, "anchor": rider._camera_follow._last_anchor,
			"expected_anchor": frame.origin + up * 1.05,
			"camera": rider._camera.global_position, "fraction": Engine.get_physics_interpolation_fraction()})


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	_release()
	var previous_enabled := tree.physics_interpolation
	var previous_rate := Engine.physics_ticks_per_second
	var previous_cap := Engine.max_fps
	tree.physics_interpolation = true
	Engine.physics_ticks_per_second = 10
	Engine.max_fps = 120
	var fixture := await _fixture(tree)
	var rider: CharacterBody3D = fixture.rider
	check.call(rider.is_physics_interpolated_and_enabled()
		and rider.get_node("SkaterVisual").is_physics_interpolated_and_enabled()
		and not rider._camera.is_physics_interpolated_and_enabled() and rider._camera.top_level,
		"interpolation: physics rider/poses opt in under an opted-out parent and per-render world camera opts out")
	var sensor := FrameSensor.new()
	sensor.rider = rider
	sensor.process_priority = 100
	fixture.root.add_child(sensor)
	Input.action_press("push")
	await _frames(tree, 16)
	sensor.enabled = true
	await _frames(tree, 10)
	sensor.enabled = false
	_release()
	_inspect_samples(check, sensor.samples)
	var spawn: Vector3 = rider.spawn_position
	rider.set_physics_process(false)
	rider.reset_skater()
	var camera_reset: Vector3 = rider._camera.global_position
	await tree.process_frame
	await tree.process_frame
	var shown: Transform3D = rider.get_global_transform_interpolated()
	check.call(shown.origin.distance_to(spawn) < 0.0001
		and camera_reset.distance_to(spawn + Vector3(0, 3.4, 6)) < 0.0001
		and rider._camera_follow._last_anchor.distance_to(spawn + Vector3.UP * 1.05) < 0.0001,
		"interpolation: restart clears old rider/camera history before the next displayed frame")
	var destination := Vector3(25, 0.8, -20)
	rider.recover_to(destination)
	await tree.process_frame
	await tree.process_frame
	check.call(rider.get_global_transform_interpolated().origin.distance_to(destination) < 0.0001
		and rider.get_node("SkaterVisual").get_global_transform_interpolated().origin.distance_to(destination) < 0.0001
		and rider._body_collision.get_global_transform_interpolated().basis.y.distance_to(Vector3.UP) < 0.0001
		and rider.spawn_position == spawn,
		"interpolation: hazard recovery resets descendant/support history and preserves the normal restart location")
	await _dispose(tree, fixture)
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = previous_cap
	var without := await _trajectory(tree, false)
	var with_interpolation := await _trajectory(tree, true)
	var exact_motion := without.size() == with_interpolation.size()
	for index in mini(without.size(), with_interpolation.size()):
		var a: Dictionary = without[index]
		var b: Dictionary = with_interpolation[index]
		exact_motion = exact_motion and a.point.distance_to(b.point) < 0.00001 \
			and a.velocity.distance_to(b.velocity) < 0.00001 and absf(a.spin - b.spin) < 0.00001 \
			and a.airborne == b.airborne
	check.call(exact_motion and without.size() == 42,
		"interpolation: identical real push/crouch/pop/spin inputs preserve every physics position, velocity and spin")
	tree.physics_interpolation = previous_enabled
	Engine.physics_ticks_per_second = previous_rate
	Engine.max_fps = previous_cap
	_release()


static func _inspect_samples(check: Callable, samples: Array[Dictionary]) -> void:
	var anchor_error := 0.0
	var raw_anchor_difference := 0.0
	var raw_step := 0.0
	var rendered_step := 0.0
	var inter_tick_changes := 0
	var finite_camera := true
	for index in samples.size():
		var entry: Dictionary = samples[index]
		anchor_error = maxf(anchor_error, entry.anchor.distance_to(entry.expected_anchor))
		raw_anchor_difference = maxf(raw_anchor_difference, entry.rendered.distance_to(entry.raw))
		finite_camera = finite_camera and entry.camera.is_finite()
		if index == 0: continue
		var previous: Dictionary = samples[index - 1]
		raw_step = maxf(raw_step, entry.raw.distance_to(previous.raw))
		rendered_step = maxf(rendered_step, entry.rendered.distance_to(previous.rendered))
		if entry.physics == previous.physics and entry.rendered.distance_to(previous.rendered) > 0.001:
			inter_tick_changes += 1
	check.call(samples.size() >= 20 and inter_tick_changes >= 10 and rendered_step < raw_step * 0.75,
		"interpolation: high-render/10-Hz physics produces intermediate displayed movement with smaller frame steps")
	check.call(anchor_error < 0.0001 and raw_anchor_difference > 0.2 and finite_camera,
		"interpolation: chase anchor follows the displayed frame rather than the newest stepped physics origin")
	print("INTERPOLATION samples=%d within_tick_changes=%d raw_max_step=%.5f displayed_max_step=%.5f anchor_error=%.7f displayed_lag=%.5f" % [
		samples.size(), inter_tick_changes, raw_step, rendered_step, anchor_error, raw_anchor_difference])


static func _trajectory(tree: SceneTree, enabled: bool) -> Array[Dictionary]:
	tree.physics_interpolation = enabled
	var fixture := await _fixture(tree)
	var rider: CharacterBody3D = fixture.rider
	var states: Array[Dictionary] = []
	for tick in 42:
		if tick == 0: Input.action_press("push")
		if tick == 15:
			Input.action_release("push")
			Input.action_press("ollie")
		if tick == 18: Input.action_release("ollie")
		if tick == 20: Input.action_press("steer_right", 0.4)
		if tick == 28: Input.action_release("steer_right")
		await _frames(tree, 1)
		states.append({"point": rider.global_position, "velocity": rider.velocity,
			"spin": rider._air_spin, "airborne": rider.airborne})
	await _dispose(tree, fixture)
	return states


static func _fixture(tree: SceneTree) -> Dictionary:
	_release()
	var root := Node3D.new()
	root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	tree.root.add_child(root)
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 0.4, 200)
	collision.shape = box
	floor.add_child(collision)
	floor.position.y = -0.2
	root.add_child(floor)
	var rider = Skater.new()
	rider.spawn_position = Vector3(0, 0.8, 12)
	root.add_child(rider)
	await _frames(tree, 12)
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
