extends RefCounted
## Mirrored, collision-earned wall entry and exit. Only initial fixture air and
## velocity are declared; held Grind and real Ollie edges own every transition.
const Skater = preload("res://game/player/skater.gd")
const Wall = preload("res://game/player/wall_ride.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Pose = preload("res://tests/trick_pose_tests.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	_presentation_clock(check)
	for side: float in [-1.0, 1.0]:
		for distance: float in [0.65, 0.90]:
			for wallie: bool in [false, true]:
				await _native_transition(tree, check, side, wallie, distance)
		for wallie: bool in [false, true]:
			await _native_transition(tree, check, side, wallie, 0.90, 1 if wallie else 5)
	await _native_transition(tree, check, 1.0, true, 0.65, 20, true)
	_release()


static func _presentation_clock(check: Callable) -> void:
	for side: float in [-1.0, 1.0]:
		var wall := Wall.new()
		wall.active = true
		wall.normal = Vector3.RIGHT * side
		wall.travel_velocity = Vector3(0, -1, -8)
		var incoming := Basis(Vector3.RIGHT, 0.12)
		var pose: Basis = wall.presentation_basis(incoming, Basis.IDENTITY, 1.0 / 60.0)
		var step := _frame_angle(incoming, pose)
		check.call(step <= 4.5 / 60.0 + 0.000001 and signf(pose.get_euler().z) == -side,
			"wall presentation: mirrored entry eases the actual incoming frame inside the existing air-pose angular rate " + str(side))
		check.call(wall.presentation_basis(pose, Basis.IDENTITY, 0.0) == pose
			and wall.presentation_basis(pose, Basis.IDENTITY, NAN) == pose
			and wall.travel_velocity == Vector3(0, -1, -8) and wall.active,
			"wall presentation: frozen/invalid pose clocks cannot change support or native travel " + str(side))
		var offset: Vector3 = wall.presentation_offset(Vector3.ZERO, Vector3.RIGHT * side * 0.5, 1.0 / 60.0)
		check.call(offset.length() <= 4.5 / 60.0 + 0.000001
			and wall.presentation_offset(offset, Vector3.ZERO, 0.0) == offset
			and wall.presentation_offset(offset, Vector3.ZERO, NAN) == offset,
			"wall presentation: positive-gap approach is bounded and cannot consume a frozen/invalid clock " + str(side))
		wall.stop()
		wall.retain_air_presentation(Vector3.RIGHT * side * 0.3)
		var retained: Vector3 = wall.air_presentation_offset
		check.call(wall.air_presentation_active and wall.decay_air_presentation(0.0) == retained
			and wall.decay_air_presentation(NAN) == retained
			and retained.distance_to(wall.decay_air_presentation(1.0 / 60.0)) <= 4.5 / 60.0 + 0.000001,
			"wall presentation: a genuine release offset has its own bounded clock without borrowing cooldown " + str(side))
		wall.stop()
		check.call(not wall.air_presentation_active and wall.air_presentation_offset == Vector3.ZERO,
			"wall presentation: a subsequent stop/takeover clears prior air-pose provenance " + str(side))


static func _native_transition(tree: SceneTree, check: Callable, side: float, wallie: bool, distance: float, hold_ticks: int = 20, ramp_flight: bool = false) -> void:
	_release()
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var fixture := Node3D.new()
	viewport.add_child(fixture)
	var wall := StaticBody3D.new()
	wall.name = "FinitePresentationWall"
	fixture.add_child(wall)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.4, 24, 40)
	collision.shape = shape
	collision.position.y = 8.0
	wall.add_child(collision)
	var rider := Skater.new()
	rider.spawn_position = Vector3(side * distance, 8.0, 8.0)
	fixture.add_child(rider)
	rider.set_physics_process(false)
	rider.set_process(false)
	await _frames(tree, 2)
	# Declared initial airborne approach, not a synthetic active wall flag.
	rider.airborne = true
	rider.velocity = Vector3(-side * 1.2, 0.0, -8.0)
	rider.speed = Vector2(rider.velocity.x, rider.velocity.z).length()
	if ramp_flight:
		# Declared ramp-departure state, not a played ramp launch. The real
		# wall probes must earn takeover and discard this prior return owner.
		rider.velocity.y = 6.0
		rider._ramp_air = true
		rider._ramp_air_normal = Vector3.UP
		rider._ramp_launch_forward = Vector3.FORWARD
		rider._vert_return = {"body":wall,"transform":Transform3D(Basis.IDENTITY,Vector3(0,0,9)),
			"width":40.0,"radius":1.0,"angle":PI * 0.5}
	var data := Attachment._prepare(rider._visual_rig)
	var events: Array[String] = []
	var on_trick := func(label: String, _points: int) -> void: events.append(label)
	rider.trick_performed.connect(on_trick)
	var previous := rider._visual.basis.orthonormalized()
	var markers := _markers(rider)
	var maximum_angle := 0.0
	var maximum_raw_quaternion_angle := 0.0
	var worst_raw_frames: Dictionary = {}
	var maximum_marker_step := 0.0
	var maximum_seam := 0.0
	var maximum_joint := 0.0
	var maximum_neck := 0.0
	var maximum_stretch := 0.0
	var maximum_foot_error := 0.0
	var minimum_wall_gap := INF
	var maximum_wall_gap := -INF
	var settled_minimum_gap := INF
	var settled_maximum_gap := -INF
	var first_bearing_tick := -1
	var wall_ticks := 0
	var air_after := 0
	var finite := true
	var bailed := false
	var ramp_context_cleared := true
	var trace: Array[Dictionary] = []
	Input.action_press("grind")
	rider.set_physics_process(true)
	for tick: int in 46:
		if tick == hold_ticks:
			if wallie: Input.action_press("ollie")
			else: Input.action_release("grind")
		if tick == hold_ticks + 4 and wallie: Input.action_release("ollie")
		await _frames(tree, 1)
		var current: Basis = rider._visual.basis.orthonormalized()
		var before_basis := previous
		var raw_quaternion_angle := previous.get_rotation_quaternion().angle_to(current.get_rotation_quaternion())
		var angle := _frame_angle(previous, current)
		if raw_quaternion_angle > maximum_raw_quaternion_angle:
			maximum_raw_quaternion_angle = raw_quaternion_angle
			worst_raw_frames = {"tick":tick,"before":before_basis,"after":current,
				"raw_quaternion_angle":raw_quaternion_angle,"matrix_angle":angle}
		var current_markers := _markers(rider)
		var step := Authentic._marker_delta(markers, current_markers)
		maximum_angle = maxf(maximum_angle, angle)
		maximum_marker_step = maxf(maximum_marker_step, step)
		previous = current
		markers = current_markers
		var cloth := Attachment._sample(rider, data)
		maximum_seam = maxf(maximum_seam, cloth.seam)
		maximum_joint = maxf(maximum_joint, cloth.joint_gap)
		maximum_neck = maxf(maximum_neck, cloth.neck_gap)
		maximum_stretch = maxf(maximum_stretch, Authentic._max_stretch(rider._visual_rig))
		maximum_foot_error = maxf(maximum_foot_error, Pose._feet_error(rider._visual_rig, rider._board_visual))
		finite = finite and cloth.finite and Authentic._finite(rider._visual_rig)
		bailed = bailed or rider.bail_active
		if rider.wallriding:
			wall_ticks += 1
			ramp_context_cleared = ramp_context_cleared and not rider._ramp_air and rider._vert_return.is_empty()
			var gap := _tyre_gap(rider, side)
			minimum_wall_gap = minf(minimum_wall_gap, gap)
			maximum_wall_gap = maxf(maximum_wall_gap, gap)
			if first_bearing_tick < 0 and gap <= 0.0151: first_bearing_tick = tick
			if first_bearing_tick >= 0:
				settled_minimum_gap = minf(settled_minimum_gap, gap)
				settled_maximum_gap = maxf(settled_maximum_gap, gap)
		elif tick > 24 and rider.airborne: air_after += 1
		if tick < 3 or tick in [4, 5, 6, 8, 19, 20, 24, 25, 45]:
			trace.append({"tick":tick,"angle":angle,"marker_step":step,"wall":rider.wallriding,
				"raw_quaternion_angle":raw_quaternion_angle,"before_basis":before_basis,"after_basis":current,
				"at":rider.global_position,"velocity":rider.velocity,"visual":rider._visual.transform})
	_release()
	var label := " side=" + str(side) + " wallie=" + str(wallie) + " distance=" + str(distance) + " hold_ticks=" + str(hold_ticks) + " ramp_fixture=" + str(ramp_flight)
	var expected_wall_ticks := hold_ticks + 4 if wallie else hold_ticks
	check.call(wall_ticks >= expected_wall_ticks and air_after >= 12 and not bailed and events.count("Wallride") == 1,
		"wall presentation: real held input earns one finite ride and ordinary air exit" + label)
	check.call(maximum_angle <= 4.5 / 60.0 + 0.000001,
		"wall presentation: actual connected frame has no first-contact roll snap or exit rotation jump" + label)
	check.call(maximum_marker_step < 0.22 and finite and maximum_stretch <= 1.12,
		"wall presentation: native head/feet/hands retain the existing pose-travel and fixed-limb bounds" + label)
	check.call(maximum_seam < 0.12 and maximum_joint < 0.06 and maximum_neck < 0.05 and maximum_foot_error < 0.005,
		"wall presentation: actual Skin-bound torso/waist/neck and both planted shoes remain attached" + label)
	check.call(minimum_wall_gap >= 0.0149 and first_bearing_tick >= 0 and first_bearing_tick <= 8
		and settled_minimum_gap >= 0.0149 and settled_maximum_gap <= 0.0151,
		"wall presentation: real tyres approach without penetration and settle on the native fifteen-millimetre bearing within eight ticks" + label)
	check.call(events.count("Wallie") == int(wallie) and rider._wall.cooldown >= 0.0,
		"wall presentation: only a real release of the charged jump earns one wallie" + label)
	if ramp_flight:
		check.call(ramp_context_cleared,
			"wall presentation: real wall capture takes ownership from declared ramp-flight metadata before any pose can be overwritten")
	print("WALL_PRESENTATION_TRANSITION ", {"side":side,"wallie":wallie,"distance":distance,"hold_ticks":hold_ticks,"maximum_angle":maximum_angle,
		"ramp_flight_fixture":ramp_flight,"ramp_context_cleared":ramp_context_cleared,
		"maximum_raw_quaternion_angle":maximum_raw_quaternion_angle,"worst_raw_frames":worst_raw_frames,
		"maximum_marker_step":maximum_marker_step,"maximum_seam":maximum_seam,"maximum_joint":maximum_joint,
		"maximum_neck":maximum_neck,"maximum_stretch":maximum_stretch,"maximum_foot_error":maximum_foot_error,
		"minimum_wall_gap":minimum_wall_gap,"maximum_wall_gap":maximum_wall_gap,"wall_ticks":wall_ticks,
		"first_bearing_tick":first_bearing_tick,"settled_minimum_gap":settled_minimum_gap,"settled_maximum_gap":settled_maximum_gap,
		"air_after":air_after,"events":events,"finite":finite,"bailed":bailed,"trace":trace})
	viewport.queue_free()
	await tree.process_frame


static func _markers(rider: CharacterBody3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for point: Vector3 in Authentic._markers(rider._visual_rig): result.append(rider.to_local(point))
	return result


static func _frame_angle(before: Basis, after: Basis) -> float:
	# Independent matrix atan2 avoids acos(dot(q,q)) cancellation for these
	# small native float32 steps. Raw quaternion angles and basis pairs remain
	# recorded; the physical angular rate and existing allowance are unchanged.
	var relative := before.transposed() * after
	var x: float = relative.y.z - relative.z.y
	var y: float = relative.z.x - relative.x.z
	var z: float = relative.x.y - relative.y.x
	return atan2(sqrt(x * x + y * y + z * z), relative.x.x + relative.y.y + relative.z.z - 1.0)


static func _tyre_gap(rider: CharacterBody3D, side: float) -> float:
	var result := INF
	var plane := Vector3(side * 0.2, 0, 0)
	var normal := Vector3(side, 0, 0)
	for wheel: Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		for point: Vector3 in wheel.points:
			result = minf(result, (rider._board_visual.to_global(point) - plane).dot(normal))
	return result


static func _release() -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for tick: int in count:
		await tree.physics_frame
		await tree.process_frame
