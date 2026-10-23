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


class RampBodySample extends Node:
	# Per-tick motion must be sampled after native physics, never across
	# coroutine polls which may span multiple physics ticks in a slow frame.
	var rider: CharacterBody3D
	var samples := 0
	var contiguous := true
	var previous_tick := -1
	var previous_air := false
	var previous_body := Basis.IDENTITY
	var minimum_up_dot := 1.0
	var maximum_step := 0.0
	func _ready() -> void: process_physics_priority = 100
	func _physics_process(_delta: float) -> void:
		var tick := Engine.get_physics_frames()
		if previous_tick >= 0: contiguous = contiguous and tick == previous_tick + 1
		previous_tick = tick
		var in_air: bool = rider.airborne and rider._ramp_air
		if in_air:
			var body: Basis = rider.get_node("SkaterVisual").global_basis
			minimum_up_dot = minf(minimum_up_dot, body.y.dot(rider._ramp_air_normal))
			if previous_air:
				maximum_step = maxf(maximum_step, rad_to_deg(previous_body.get_rotation_quaternion().angle_to(body.get_rotation_quaternion())))
			previous_body = body
			samples += 1
		previous_air = in_air


class TurnSample extends Node:
	signal finished
	var rider: CharacterBody3D
	var framed: Callable
	var ticks := 0
	var seconds := 0.0
	var distance := 0.0
	var heading := 0.0
	var unsafe := 0
	var previous: Vector3
	var previous_yaw: float
	var final_speed := 0.0
	var supported := true
	var stall := false
	var stalled := false
	func _ready() -> void:
		process_physics_priority = 100
		process_priority = 100
		previous = rider.global_position
		previous_yaw = rider.rotation.y
	func _physics_process(delta: float) -> void:
		if ticks >= 60: return
		ticks += 1
		seconds += delta
		distance += previous.distance_to(rider.global_position)
		heading += angle_difference(previous_yaw, rider.rotation.y)
		previous = rider.global_position
		previous_yaw = rider.rotation.y
		final_speed = rider.speed
		supported = supported and rider.is_on_floor()
		if ticks == 60:
			Input.action_release("steer_left")
			finished.emit()
	func _process(_delta: float) -> void:
		unsafe += int(not framed.call(rider))
		if stall and not stalled and ticks >= 20:
			stalled = true
			OS.delay_msec(120)


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	await _support_interpolation(tree,check)
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
	await _ground_chase(tree,check)
	for quiet_reduced:bool in [false,true]:
		for held:int in [2,24]:await _quiet_ollie(tree,check,quiet_reduced,held)
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
	# Rendering may deliver multiple physics ticks per displayed frame. Stop the
	# input after exactly 60 physics updates, including under a deliberate stall.
	var sample := TurnSample.new()
	sample.rider = rider
	sample.framed = _framed
	sample.stall = requested_speed == 12.0 and strength == 1.0
	tree.root.add_child(sample)
	await sample.finished
	await tree.process_frame
	await tree.create_timer(0.0).timeout
	var distance: float = sample.distance
	var heading: float = sample.heading
	var unsafe: int = sample.unsafe
	var radius := distance / absf(heading)
	check.call(initial_speed >= requested_speed - 0.05 and initial_speed <= requested_speed + 0.2
		and sample.supported and sample.ticks == 60 and absf(sample.seconds - 1.0) < 0.00001 and heading > 0.3 and distance > 4.0 and unsafe == 0,
		"classic turns: %.0fm/s input %.2f stays supported, turns left and keeps the whole skater framed" % [requested_speed, strength])
	check.call((strength == 0.25 and heading < 0.50)
		or (strength == 0.5 and heading > 0.8 and heading < 1.1)
		or (strength == 1.0 and heading > 1.9 and heading < 2.5),
		"classic turns: %.0fm/s input %.2f gives a bounded useful one-second angle" % [requested_speed, strength])
	print("CLASSIC TURN initial=%.3f final=%.3f input=%.2f angle_deg=%.3f distance=%.3f effective_radius=%.3f unsafe=%d" % [
		initial_speed, sample.final_speed, strength, rad_to_deg(heading), distance, radius, unsafe])
	print("TURN_TIMING ticks=",sample.ticks," seconds=",sample.seconds," injected_stall=",sample.stalled)
	sample.queue_free()
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


static func _ground_chase(tree:SceneTree,check:Callable)->void:
	var fixture:=await _fixture(tree)
	var rider:CharacterBody3D=fixture.rider
	Input.action_press("push")
	await _frames(tree,50)
	Input.action_release("push")
	Input.action_press("steer_left")
	await _frames(tree,45)
	Input.action_release("steer_left")
	await _frames(tree,20)
	var facing:Vector3=-rider.global_basis.z
	var view:Vector3=-rider._camera.global_basis.z
	view.y=0.0
	var alignment:=view.normalized().dot(facing)
	check.call(rider.is_on_floor() and alignment>.98 and _camera_rear(rider).dot(-facing)>.95 and _framed(rider),
		"classic camera: after an actual flat-ground turn, short follow lag settles to a forward chase behind the skater")
	print("GROUND CHASE view_dot_forward=",alignment," rear_dot_back=",_camera_rear(rider).dot(-facing))
	await _dispose(tree,fixture)


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
	var fixture: Dictionary = await Classic._pipe_fixture(tree,false,Vector3(-42,2.8,60.5),-PI*.5,true)
	var rider:CharacterBody3D=fixture.rider
	rider.set_presentation_settings(1.0,reduced)
	var probe:=CameraProbe.new()
	probe.inner=rider._camera_follow
	rider._camera_follow=probe
	var bails:Array[int]=[]
	rider.bailed.connect(func():bails.append(1))
	Input.action_press("push")
	var camera:Camera3D=rider._camera
	var side_frames:=0
	var min_forward_dot:=1.0
	var rear_samples:=0
	var bottom_age:=0
	var bottom_samples:=0
	var bottom_forward_dot:=1.0
	var contact_age:=0
	var previous_contact:=false
	var entered:=false
	var departures:=0
	var returns:=0
	var unsafe:=0
	var min_axis:=INF
	var flight_alignment:=1.0
	var flight_samples:=0
	var body_probe := RampBodySample.new()
	body_probe.rider = rider
	fixture.root.add_child(body_probe)
	var was_air:=false
	var last_angle:=0.0
	var turn:=0.0
	var backwards:=0.0
	var peak_turn:=0.0
	var upward:=-1.0
	var downward:=1.0
	var view_up:=1.0
	var good_orbits:=0
	var orbit_started:=false
	for tick in 720:
		await _frames(tree,1)
		var contact:bool=rider.transition_active
		if contact:entered=true
		if previous_contact and not contact and rider.airborne:departures+=1
		if not previous_contact and contact and entered and rider.velocity.y<0:returns+=1
		previous_contact=contact
		var in_air:bool=rider.airborne and rider._ramp_air
		if in_air:
			var forward:Vector3=-camera.global_basis.z
			var normal:Vector3=rider._ramp_air_normal
			var angle:=atan2(normal.dot(Vector3.UP.cross(forward)),Vector3.UP.dot(forward))
			if not was_air:
				turn=0.0;backwards=0.0;peak_turn=0.0;upward=-1.0;downward=1.0;view_up=1.0;orbit_started=false
			elif orbit_started:
				var change:=angle_difference(last_angle,angle)
				turn+=change
				peak_turn=maxf(peak_turn,turn)
				backwards=maxf(backwards,peak_turn-turn)
			# Ramp approach first reaches the sky view; measure its subsequent
			#180 turn once, without resetting if it later winds backwards.
			if not orbit_started and forward.y>.97 and rider.velocity.y>0.0:
				orbit_started=true
			last_angle=angle
			upward=maxf(upward,forward.y)
			downward=minf(downward,forward.y)
			view_up=minf(view_up,camera.global_basis.y.dot(normal))
			if absf(rider.velocity.y)>5.0:
				flight_samples+=1
				flight_alignment=minf(flight_alignment,(-rider.get_node("SkaterVisual").global_basis.z).dot(rider.velocity.normalized()))
		elif was_air:
			var good:=orbit_started and turn>deg_to_rad(150.0) and turn<deg_to_rad(210.0) and backwards<deg_to_rad(15.0) and upward>.97 and downward<-.97 and view_up>.90
			good_orbits+=int(good)
			print("LOCAL RAMP ORBIT turn_deg=",rad_to_deg(turn)," max_reverse_excursion_deg=",rad_to_deg(backwards)," up_y=",upward," down_y=",downward," camera_up_dot_ramp_normal=",view_up," good=",good)
		was_air=in_air
		if rider.transition_active:
			contact_age+=1
			side_frames+=int(not is_zero_approx(probe.inner._selected_angle))
			# Actual moving travel is the heading reference. A near-zero rollback
			# has no stable direction and its displayed180 interpolation passes
			# sideways; allow the same short follow settling as a flat turn.
			if contact_age>12 and rider.velocity.length()>4.0:
				rear_samples+=1
				var normal:Vector3=rider.get_camera_support_up()
				var view_heading:=(-camera.global_basis.z).slide(normal).normalized()
				var travel_heading:=rider.velocity.slide(normal).normalized()
				min_forward_dot=minf(min_forward_dot,view_heading.dot(travel_heading))
		else:contact_age=0
		if not rider.transition_active and rider.is_on_floor() and not rider.airborne:
			bottom_age+=1
			if bottom_age>20 and rider.velocity.length()>4.0:
				var bottom_view:=Vector3(-camera.global_basis.z.x,0,-camera.global_basis.z.z).normalized()
				var bottom_travel:=Vector3(rider.velocity.x,0,rider.velocity.z).normalized()
				bottom_samples+=1
				bottom_forward_dot=minf(bottom_forward_dot,bottom_view.dot(bottom_travel))
		else:bottom_age=0
		var displayed:=rider.get_global_transform_interpolated()
		var up:=_display_up(rider)
		var board:=camera.unproject_position(displayed.origin+up*.12)
		var head:=camera.unproject_position(displayed.origin+up*1.8)
		min_axis=minf(min_axis,board.distance_to(head)/camera.get_viewport().get_visible_rect().size.y)
		unsafe+=int(not _framed(rider))
	check.call(departures>=3 and returns>=3 and bails.is_empty(),
		"classic camera: held push makes repeated natural finite-wall returns (reduced=%s)"%reduced)
	check.call(unsafe==0 and min_axis>.06,
		"classic camera: ramp cycles keep displayed rider/board clear and readable (reduced=%s)"%reduced)
	check.call(probe.max_angle<30.0 and probe.max_move<1.0,
		"classic camera: actual ramp updates avoid large view or zoom jumps (reduced=%s)"%reduced)
	check.call(flight_samples>30 and flight_alignment>.95,
		"classic ramp pose: airborne rider/board follows fast ascent/descent momentum (reduced=%s)"%reduced)
	check.call(body_probe.contiguous and body_probe.samples>60 and body_probe.minimum_up_dot>.99 and body_probe.maximum_step<12.0,
		"classic ramp pose: assisted return keeps the body outside the ramp with bounded per-tick rotation (reduced=%s)"%reduced)
	check.call(good_orbits>=3 and good_orbits==returns,
		"classic camera: one local180 turn reaches sky/down views and retains skater perspective (reduced=%s)"%reduced)
	check.call(side_frames==0 and rear_samples>100 and min_forward_dot>.80,
		"classic camera: supported ramp chase stays rear-facing without a side orbit (reduced=%s)"%reduced)
	check.call(bottom_samples>10 and bottom_forward_dot>.85,
		"classic camera: flat half-pipe bottom also returns behind actual travel after short settling (reduced=%s)"%reduced)
	print("CAMERA BOTTOM REAR samples=",bottom_samples," minimum_forward_dot=",bottom_forward_dot)
	print("CAMERA RAMP REAR side_frames=",side_frames," samples=",rear_samples," minimum_forward_dot=",min_forward_dot)
	print("CAMERA LOCAL RETURNS reduced=",reduced," departures=",departures," returns=",returns," good_orbits=",good_orbits," unsafe=",unsafe," minimum_axis_fraction=",min_axis," max_update_move=",probe.max_move," max_update_angle=",probe.max_angle," pose_forward_dot_velocity=",flight_alignment," body_step_deg=",body_probe.maximum_step," native_body_samples=",body_probe.samples," native_contiguous=",body_probe.contiguous)
	await _dispose(tree,fixture)


static func _camera_rear(rider: CharacterBody3D) -> Vector3:
	var offset: Vector3 = rider._camera.global_position - rider.global_position
	return Vector3(offset.x,0,offset.z).normalized()


static func _display_up(rider:CharacterBody3D) -> Vector3:
	var body:Node3D = rider.get_node("SkaterVisual") if rider.transition_active or (rider.airborne and rider._ramp_air) else rider.get_node("BodyCollision")
	return body.get_global_transform_interpolated().basis.y.normalized()


static func _framed(rider: CharacterBody3D) -> bool:
	var camera: Camera3D = rider._camera
	# Match the body the renderer displays, including the contact handoff;
	# current physics support can be one interpolated pose ahead.
	var displayed := rider.get_global_transform_interpolated()
	var normal := _display_up(rider)
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


static func _support_interpolation(tree:SceneTree,check:Callable)->void:
	var fixture := await _fixture(tree)
	var rider:CharacterBody3D=fixture.rider
	rider.set_physics_process(false)
	rider.set_process(false)
	# Godot's interpolated root basis can carry tiny uniform scale drift.
	# Ramp camera interpolation must remain a valid rotation at that seam.
	rider._previous_ramp_air_frame=Basis(Vector3.UP,PI/2.0).scaled(Vector3(.99982,1.0,.99982))
	rider._ramp_air_frame=Basis(Vector3.UP,PI/2.0+.02).scaled(Vector3(.99977,1.0,.99977))
	await tree.process_frame
	var frame:Basis=rider.get_camera_support_frame()
	check.call(is_equal_approx(frame.determinant(),1.0) and frame.y.is_equal_approx(Vector3.UP)
		and (-frame.z).dot(Vector3.LEFT)>.99,
		"classic camera: interpolated ramp support removes root scale drift and preserves direction")
	await _dispose(tree,fixture)


static func _quiet_ollie(tree:SceneTree,check:Callable,reduced:bool,held:int)->void:
	var fixture:=await _fixture(tree)
	var rider:CharacterBody3D=fixture.rider
	rider.set_presentation_settings(1.0,reduced)
	await _frames(tree,45)
	Input.action_press("ollie")
	await _frames(tree,held)
	var camera:Camera3D=rider._camera
	var initial_y:=camera.global_position.y
	var initial_rotation:=camera.global_basis.get_rotation_quaternion()
	var origin_y:=rider.global_position.y
	var rise:=0.0
	var camera_rise:=0.0
	var camera_angle:=0.0
	var unsafe:=0
	Input.action_release("ollie")
	await _frames(tree,2)
	Input.action_press("flip")
	await _frames(tree,2)
	Input.action_release("flip")
	for tick in 100:
		await _frames(tree,1)
		rise=maxf(rise,rider.global_position.y-origin_y)
		camera_rise=maxf(camera_rise,absf(camera.global_position.y-initial_y))
		camera_angle=maxf(camera_angle,initial_rotation.angle_to(camera.global_basis.get_rotation_quaternion()))
		unsafe+=int(not _framed(rider))
	check.call(rise>(1.15 if held>10 else .75) and rise<(1.45 if held>10 else .95) and rider.is_on_floor(),
		"classic quiet ollie: mapped release and flip make a real jump and supported landing (%df reduced=%s)"%[held,reduced])
	check.call(camera_rise<.10 and camera_angle<deg_to_rad(2.0) and unsafe==0,
		"classic quiet ollie: camera height/aim stay steady while the full rider jumps (%df reduced=%s)"%[held,reduced])
	print("CAMERA QUIET OLLIE held=",held," reduced=",reduced," body_rise=",rise," camera_y_span=",camera_rise," camera_angle_deg=",rad_to_deg(camera_angle)," unsafe=",unsafe)
	await _dispose(tree,fixture)
