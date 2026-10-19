extends RefCounted
## Actual mapped inputs on a clear isolated floor. Placement is initial only;
## no per-tick motion, heading or camera assignment is used by these routes.

const Skater = preload("res://game/player/skater.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Chase = preload("res://game/player/chase_camera.gd")
const Classic = preload("res://tests/classic_tricks_integration_tests.gd")


class CameraProbe extends RefCounted:
	var inner: RefCounted
	var calls := 0
	var max_move := 0.0
	var max_angle := 0.0
	func reset() -> void:
		inner.reset()
		calls = 0
		max_move = 0.0
		max_angle = 0.0
	func update(rider:CharacterBody3D,camera:Camera3D,delta:float,sensitivity:float,reduced:bool) -> void:
		var previous := camera.global_position
		var rotation := camera.global_basis.get_rotation_quaternion()
		inner.update(rider,camera,delta,sensitivity,reduced)
		if calls > 5:
			max_move = maxf(max_move,previous.distance_to(camera.global_position))
			max_angle = maxf(max_angle,rad_to_deg(rotation.angle_to(camera.global_basis.get_rotation_quaternion())))
		calls += 1


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
	for reduced: bool in [false, true]:
		for sensitivity: float in [0.5, 2.0]:
			await _air_spin(tree, check, reduced, sensitivity)
	for reduced: bool in [false, true]:
		await _natural_returns(tree, check, reduced)
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


static func _air_spin(tree: SceneTree, check: Callable, reduced: bool, sensitivity: float) -> void:
	var fixture := await _fixture(tree)
	var rider: CharacterBody3D = fixture.rider
	rider.set_presentation_settings(sensitivity, reduced)
	Input.action_press("push")
	await _frames(tree, 45)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(tree, 24)
	Input.action_release("ollie")
	await _frames(tree, 2)
	var initial := _camera_rear(rider)
	Input.action_press("spin_left")
	var spun := 0.0
	var visual: Node3D = rider.get_node("SkaterVisual")
	var previous := visual.global_basis.get_euler().y
	var drift := 0.0
	var unsafe := 0
	var horizontal_drift := 0.0
	var travel := Vector2(rider.velocity.x, rider.velocity.z)
	for tick in 20:
		await _frames(tree, 1)
		spun += absf(angle_difference(previous, visual.global_basis.get_euler().y))
		previous = visual.global_basis.get_euler().y
		drift = maxf(drift, initial.angle_to(_camera_rear(rider)))
		horizontal_drift = maxf(horizontal_drift, travel.distance_to(Vector2(rider.velocity.x, rider.velocity.z)))
		unsafe += int(not _framed(rider))
	check.call(rider.airborne and spun > deg_to_rad(75.0) and drift < deg_to_rad(8.0)
		and unsafe == 0 and horizontal_drift < 0.01,
		"classic camera: actual air spin rotates body independently of travel/chase (reduced=%s sensitivity=%.1f)" % [reduced,sensitivity])
	print("CAMERA AIR SPIN body_deg=%.3f camera_drift_deg=%.3f travel_drift=%.6f unsafe=%d" % [
		rad_to_deg(spun),rad_to_deg(drift),horizontal_drift,unsafe])
	await _dispose(tree, fixture)


static func _natural_returns(tree: SceneTree, check: Callable, reduced: bool) -> void:
	var fixture: Dictionary = await Classic._pipe_fixture(tree, false, Vector3(-42,2.8,60.5), -PI*0.5, true)
	var rider: CharacterBody3D = fixture.rider
	rider.set_presentation_settings(1.0, reduced)
	var probe := CameraProbe.new()
	probe.inner = rider._camera_follow
	rider._camera_follow = probe
	var bails: Array[int] = []
	rider.bailed.connect(func():bails.append(1))
	Input.action_press("push")
	var camera: Camera3D = rider._camera
	var previous := camera.global_basis.get_rotation_quaternion()
	var previous_contact := false
	var entered := false
	var departures := 0
	var returns := 0
	var unsafe := 0
	var min_axis := INF
	var max_step := 0.0
	var previous_camera := camera.global_position
	var max_position_step := 0.0
	var ascent_rear := Vector3.ZERO
	var was_rising := false
	var apex_turns := 0
	var min_return_alignment := 1.0
	var highest_descent_view_pitch := -PI * .5
	for tick in 720:
		await _frames(tree, 1)
		var contact: bool = rider.transition_active
		if contact: entered = true
		if previous_contact and not contact and rider.airborne: departures += 1
		if not previous_contact and contact and entered and rider.velocity.y < 0: returns += 1
		previous_contact = contact
		if rider.airborne and rider.velocity.y > 1.0 and probe.inner._apex_rear.length_squared() > .1:
			ascent_rear = probe.inner._apex_rear
			was_rising = true
		if was_rising and rider.airborne and rider.velocity.y < 0.0:
			apex_turns += 1
			min_return_alignment = minf(min_return_alignment, _camera_rear(rider).dot(-ascent_rear))
			highest_descent_view_pitch = maxf(highest_descent_view_pitch, asin(clampf(-camera.global_basis.z.y,-1.0,1.0)))
			was_rising = false
		var q := camera.global_basis.get_rotation_quaternion()
		if tick > 5:
			max_step = maxf(max_step, rad_to_deg(previous.angle_to(q)))
			max_position_step = maxf(max_position_step,previous_camera.distance_to(camera.global_position))
		previous_camera = camera.global_position
		previous = q
		var displayed := rider.get_global_transform_interpolated()
		var up: Vector3 = rider.get_node("BodyCollision").get_global_transform_interpolated().basis.y.normalized()
		var board := camera.unproject_position(displayed.origin+up*.12)
		var head := camera.unproject_position(displayed.origin+up*1.8)
		min_axis = minf(min_axis, board.distance_to(head)/camera.get_viewport().get_visible_rect().size.y)
		if not _framed(rider):
			unsafe += 1
			print("CAMERA UNSAFE tick=",tick," position=",rider.global_position," velocity=",rider.velocity," camera=",camera.global_position," contact=",contact)
			for height:float in [.12,1.05,1.8]:
				var point:Vector3=displayed.origin+up*height
				var hit:=rider.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,point,1))
				print("CAMERA LANDMARK height=",height," frustum=",camera.is_position_in_frustum(point)," hit=",hit)
	check.call(departures >= 3 and returns >= 3 and bails.is_empty(),
		"classic camera: held push makes repeated natural finite-wall aerial returns (reduced=%s)" % reduced)
	check.call(unsafe == 0 and min_axis > .06,
		"classic camera: natural ramp cycles keep body/board clear and steep body axis readable (reduced=%s)" % reduced)
	check.call(probe.max_angle < 30.0 and probe.max_move < 1.0,
		"classic camera: actual camera updates during natural returns avoid a large view or zoom jump (reduced=%s)" % reduced)
	check.call(apex_turns >= 3 and min_return_alignment > .5 and highest_descent_view_pitch < deg_to_rad(-35.0),
		"classic camera: anticipated swing faces the return and looks down by first descending air tick (reduced=%s)" % reduced)
	print("CAMERA APEX turns=",apex_turns," minimum_camera_return_dot=",min_return_alignment," highest_first_descent_pitch_deg=",rad_to_deg(highest_descent_view_pitch)," max_update_move_m=",probe.max_move," max_update_angle_deg=",probe.max_angle)
	print("CAMERA RETURNS reduced=%s departures=%d returns=%d unsafe=%d min_axis_fraction=%.4f max_physics_sample_deg=%.3f max_camera_step_m=%.3f" % [
		reduced,departures,returns,unsafe,min_axis,max_step,max_position_step])
	await _dispose(tree, fixture)


static func _camera_rear(rider: CharacterBody3D) -> Vector3:
	var offset: Vector3 = rider._camera.global_position - rider.global_position
	return Vector3(offset.x,0,offset.z).normalized()


static func _framed(rider: CharacterBody3D) -> bool:
	var camera: Camera3D = rider._camera
	# Match the body the renderer displays, including the contact handoff;
	# current physics support can be one interpolated pose ahead.
	var displayed := rider.get_global_transform_interpolated()
	var normal: Vector3 = rider.get_node("BodyCollision").get_global_transform_interpolated().basis.y.normalized()
	if not camera.global_position.is_finite(): return false
	var space := rider.get_world_3d().direct_space_state
	for height: float in [0.12, 1.05, 1.8]:
		var point := displayed.origin + normal * height
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
		# process_frame is emitted before node _process; inspect after chase update.
		await tree.create_timer(0.0).timeout


static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
