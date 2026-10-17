extends CharacterBody3D
## Forgiving arcade controller. Origin is at the ground beneath the skateboard.
## Travel heading and cosmetic aerial spins are deliberately independent in M01.

signal trick_performed(trick_name: String, points: int)
signal landed(clean: bool)
signal bailed()

const GrindRideSource = preload("res://game/tricks/grind_ride.gd")
const TrickCatalog = preload("res://game/tricks/trick_catalog.gd")
const GRIND_RECAPTURE_DELAY := 0.35

const MAX_SPEED := 15.0
const PUSH_ACCELERATION := 10.0
const BRAKE_DECELERATION := 22.0
const ROLLING_DRAG := 0.75
const TURN_SPEED := 2.3
const GRAVITY := 22.0
const OLLIE_SPEED := 8.8
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.12
const SPIN_SPEED := 7.2
const FLIP_DURATION := 0.48

var speed: float = 0.0
var airborne: bool = false
var spawn_position: Vector3 = Vector3(0.0, 0.8, 12.0)

var _grind = GrindRideSource.new()
var _grind_lines: Array = []
var _grind_cooldown := 0.0
var grinding: bool:
	get:
		return _grind.active
var grind_balance: float:
	get:
		return _grind.balance if grinding else 0.0

var _trick_entries_enabled := true
var _controls_enabled := true
var _coyote_remaining := 0.0
var _jump_buffer_remaining := 0.0
var _flip_used := false
var _grab_used := false
var _flip_remaining := 0.0
var _grab_remaining := 0.0
var _spin_angle := 0.0
var _air_spin := 0.0
var _steering := 0.0
var _visual: Node3D
var _board_visual: Node3D
var _rider_visual: Node3D
var _camera: Camera3D


func _ready() -> void:
	floor_max_angle = deg_to_rad(56.0)
	floor_snap_length = 0.45
	floor_constant_speed = true
	floor_stop_on_slope = true
	safe_margin = 0.015
	collision_layer = 2
	collision_mask = 1
	_build_skater()
	_camera = Camera3D.new()
	_camera.name = "ChaseCamera"
	add_child(_camera)
	_camera.top_level = true
	_camera.current = true
	_camera.fov = 68.0
	_camera.near = 0.08
	_camera.far = 220.0
	reset_skater()


func reset_skater() -> void:
	_grind.stop()
	_grind_cooldown = 0.0
	global_position = spawn_position
	rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	speed = 0.0
	airborne = false
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0
	_flip_used = false
	_grab_used = false
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_spin_angle = 0.0
	_air_spin = 0.0
	_steering = 0.0
	if is_instance_valid(_visual):
		_visual.rotation = Vector3.ZERO
		_board_visual.rotation = Vector3.ZERO
		_rider_visual.position = Vector3.ZERO
		_rider_visual.rotation = Vector3(0.0, -0.45, 0.0)
	if is_instance_valid(_camera):
		_camera.global_position = global_position + Vector3(0.0, 3.4, 6.0)
		_camera.look_at(global_position + Vector3(0.0, 1.0, -1.5))


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if not enabled:
		speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		_jump_buffer_remaining = 0.0


func set_trick_entries_enabled(enabled: bool) -> void:
	# Run overtime permits an existing combo to land, without starting links.
	_trick_entries_enabled = enabled
	if not enabled:
		_jump_buffer_remaining = 0.0


func set_grind_lines(lines: Array) -> void:
	# Snapshot the collection; geometry itself is immutable during a run.
	_grind_lines = lines.duplicate()


func _physics_process(delta: float) -> void:
	_grind_cooldown = maxf(0.0, _grind_cooldown - delta)
	if grinding:
		_tick_grind(delta)
		_update_pose(delta)
		return
	var grounded_before := is_on_floor()
	var push_input := 0.0
	var brake_input := 0.0
	_steering = 0.0
	if _controls_enabled:
		push_input = Input.get_action_strength("push")
		brake_input = Input.get_action_strength("brake")
		_steering = Input.get_axis("steer_left", "steer_right")
		if _trick_entries_enabled and Input.is_action_just_pressed("ollie"):
			_jump_buffer_remaining = JUMP_BUFFER_TIME
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	_coyote_remaining = COYOTE_TIME if grounded_before else maxf(0.0, _coyote_remaining - delta)

	if grounded_before:
		if brake_input > 0.05:
			speed = move_toward(speed, 0.0, BRAKE_DECELERATION * brake_input * delta)
		elif push_input > 0.05:
			speed = minf(MAX_SPEED, speed + PUSH_ACCELERATION * push_input * delta)
		else:
			speed = move_toward(speed, 0.0, ROLLING_DRAG * delta)
	# Low-speed steering remains useful, and high-speed turns stay controllable.
	var turn_scale := lerpf(1.0, 0.62, speed / MAX_SPEED)
	var steering_angle := -_steering * TURN_SPEED * turn_scale * delta
	rotation.y += steering_angle
	var forward := -global_basis.z
	if grounded_before:
		var ground_direction := forward.slide(get_floor_normal()).normalized()
		velocity = ground_direction * speed
	else:
		# Carry the ramp/contact-adjusted momentum into air. Rebuilding X/Z
		# from surface speed adds energy at lips and restores blocked motion.
		velocity = velocity.rotated(Vector3.UP, steering_angle)
		velocity.y -= GRAVITY * delta

	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0:
		_begin_air()
		velocity.y = maxf(0.0, velocity.y) + OLLIE_SPEED
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		trick_performed.emit("Ollie", 100)

	if airborne and _controls_enabled and _trick_entries_enabled:
		_apply_air_tricks(delta)
		if _try_grind():
			_update_pose(delta)
			return

	move_and_slide()
	if is_on_floor():
		# Godot can clear requested Y while snapping down a slope. Real travel
		# retains that component, avoiding repeated artificial downhill braking.
		# The cap prevents collision recovery/snap displacement adding speed.
		speed = minf(speed, get_real_velocity().length())
		if airborne:
			_finish_landing()
	else:
		speed = Vector2(velocity.x, velocity.z).length()
		if not airborne:
			_begin_air()

	if global_position.y < -8.0 or absf(global_position.x) > 100.0 or absf(global_position.z) > 110.0:
		bailed.emit()
		reset_skater()

	_update_pose(delta)


func _begin_air() -> void:
	if airborne:
		return
	airborne = true
	_flip_used = false
	_grab_used = false
	_air_spin = 0.0
	_spin_angle = 0.0


func _apply_air_tricks(delta: float) -> void:
	if Input.is_action_just_pressed("flip") and not _flip_used:
		_flip_used = true
		_flip_remaining = FLIP_DURATION
		trick_performed.emit("Kickflip", 300)
	if Input.is_action_just_pressed("grab") and not _grab_used:
		_grab_used = true
		_grab_remaining = 0.5
		trick_performed.emit("Melon Grab", 250)
	var spin_input := Input.get_axis("spin_left", "spin_right")
	_air_spin -= spin_input * SPIN_SPEED * delta
	_spin_angle = _air_spin


func _award_air_spin() -> void:
	# M01 uses forgiving, clean landings at any heading. Small spin tolerance
	# keeps the 180 accessible without precise last-frame timing.
	var half_turns := int(floor((absf(_air_spin) + deg_to_rad(20.0)) / PI))
	if half_turns > 0:
		var direction := "Frontside" if _air_spin > 0.0 else "Backside"
		trick_performed.emit("%s %d" % [direction, half_turns * 180], half_turns * 200)
	_air_spin = 0.0


func _finish_landing() -> void:
	_award_air_spin()
	airborne = false
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	landed.emit(true)


func _try_grind() -> bool:
	if _grind_cooldown > 0.0 or not Input.is_action_pressed("grind"):
		return false
	if not _grind.start(_grind_lines, global_position, velocity, _rail_path_clear):
		return false
	_award_air_spin()
	airborne = false
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_spin_angle = 0.0
	_jump_buffer_remaining = 0.0
	_coyote_remaining = 0.0
	global_position = _grind.position()
	velocity = _grind.travel_velocity()
	speed = _grind.speed
	_align_to_travel()
	trick_performed.emit(TrickCatalog.definition("rail_grind")["display_name"],
		TrickCatalog.base_points("rail_grind"))
	return true


func _rail_path_clear(from: Vector3, to: Vector3) -> bool:
	var start := global_transform
	start.origin = from
	# Sweep the real rider capsule against ordinary scenery, including overlap
	# recovery. Rail-only props are layer 2; world obstacles remain layer 1.
	return not test_move(start, to - from, null, safe_margin, true)


func _align_to_travel() -> void:
	if Vector2(velocity.x, velocity.z).length_squared() > 0.001:
		rotation.y = atan2(-velocity.x, -velocity.z)


func _tick_grind(delta: float) -> void:
	if not _controls_enabled:
		return
	_steering = Input.get_axis("steer_left", "steer_right")
	if _trick_entries_enabled and Input.is_action_just_pressed("ollie"):
		_release_grind(true)
		return
	if not Input.is_action_pressed("grind"):
		_release_grind(false)
		return
	# Short collision sweeps follow bends instead of cutting through scenery.
	var steps := maxi(1, ceili(delta * maxf(_grind.speed, 1.0) / 0.20))
	for i in steps:
		var result: String = _grind.step(delta / steps, _steering)
		var target: Vector3 = _grind.position()
		if result == "bail" or not _rail_path_clear(global_position, target):
			bailed.emit()
			reset_skater()
			_grind_cooldown = GRIND_RECAPTURE_DELAY
			return
		global_position = target
		velocity = _grind.travel_velocity()
		speed = _grind.speed
		_align_to_travel()
		if result != "riding":
			_release_grind(false)
			return


func _release_grind(jump: bool) -> void:
	velocity = _grind.travel_velocity()
	_grind.stop()
	_grind_cooldown = GRIND_RECAPTURE_DELAY
	_begin_air()
	speed = Vector2(velocity.x, velocity.z).length()
	if jump:
		velocity.y = maxf(0.0, velocity.y) + OLLIE_SPEED
		trick_performed.emit("Ollie", TrickCatalog.base_points("ollie"))


func _update_pose(delta: float) -> void:
	_flip_remaining = maxf(0.0, _flip_remaining - delta)
	_grab_remaining = maxf(0.0, _grab_remaining - delta)
	if not airborne:
		_spin_angle = lerp_angle(_spin_angle, 0.0, 1.0 - exp(-18.0 * delta))
	_visual.rotation.y = _spin_angle
	_visual.rotation.z = lerpf(_visual.rotation.z, -_steering * 0.11 * (speed / MAX_SPEED), 1.0 - exp(-10.0 * delta))
	_board_visual.rotation.z = TAU * (1.0 - _flip_remaining / FLIP_DURATION) if _flip_remaining > 0.0 else 0.0
	var grab_pose := 1.0 if _grab_remaining > 0.0 else 0.0
	_rider_visual.position.y = lerpf(_rider_visual.position.y, -0.17 * grab_pose, 1.0 - exp(-16.0 * delta))
	_rider_visual.rotation.x = lerpf(_rider_visual.rotation.x, -0.1 - grab_pose * 0.2, 1.0 - exp(-10.0 * delta))
	if grinding:
		_visual.rotation.z = -grind_balance * 0.35
		_rider_visual.position.y = -0.12
	# Lean the visible board into slopes without pitching the upright collision.
	var desired_pitch := 0.0
	if grinding:
		desired_pitch = atan2(velocity.y, Vector2(velocity.x, velocity.z).length())
	elif is_on_floor():
		var local_normal := global_basis.inverse() * get_floor_normal()
		desired_pitch = atan2(local_normal.z, local_normal.y)
	_visual.rotation.x = lerpf(_visual.rotation.x, desired_pitch, 1.0 - exp(-14.0 * delta))


func _process(delta: float) -> void:
	if not is_instance_valid(_camera):
		return
	var forward := -global_basis.z
	var target := global_position + Vector3.UP * 1.05 + forward * 1.2
	var desired := global_position - forward * (6.0 + speed * 0.04) + Vector3.UP * 3.4
	var query := PhysicsRayQueryParameters3D.create(target, desired, 1, [get_rid()])
	var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
	if not obstruction.is_empty():
		desired = obstruction["position"] + obstruction["normal"] * 0.3
	_camera.global_position = _camera.global_position.lerp(desired, 1.0 - exp(-7.0 * delta))
	if _camera.global_position.distance_squared_to(target) > 0.01:
		_camera.look_at(target, Vector3.UP)
	_camera.fov = lerpf(_camera.fov, 68.0 + speed * 0.35, 1.0 - exp(-3.0 * delta))


func _material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _box(parent: Node3D, size: Vector3, center: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	parent.add_child(instance)
	return instance


func _limb(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.85
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = (start + end) * 0.5
	instance.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	parent.add_child(instance)


func _build_skater() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.7
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)
	_visual = Node3D.new()
	_visual.name = "SkaterVisual"
	add_child(_visual)
	_board_visual = Node3D.new()
	_board_visual.name = "Board"
	_board_visual.position.y = 0.17
	_visual.add_child(_board_visual)
	_rider_visual = Node3D.new()
	_rider_visual.name = "Rider"
	_visual.add_child(_rider_visual)

	var grip := _material(Color("252c3b"))
	var deck := _material(Color("f7b94b"))
	var wheels := _material(Color("eee4c9"))
	var metal := _material(Color("8f99a5"), 0.45)
	var teal := _material(Color("20a59f"))
	var orange := _material(Color("ef7849"))
	var trousers := _material(Color("2e3b55"))
	var skin := _material(Color("d6a17d"))
	var shoes := _material(Color("f1eee1"))
	_box(_board_visual, Vector3(0.4, 0.075, 1.06), Vector3.ZERO, deck)
	_box(_board_visual, Vector3(0.36, 0.015, 1.01), Vector3(0, 0.045, 0), grip)
	for end: float in [-1.0, 1.0]:
		var tip := _box(_board_visual, Vector3(0.38, 0.06, 0.18), Vector3(0, 0.045, end * 0.57), deck)
		tip.rotation.x = -end * 0.22
		_box(_board_visual, Vector3(0.48, 0.04, 0.07), Vector3(0, -0.055, end * 0.36), metal)
		for side: float in [-1.0, 1.0]:
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.075
			wheel_mesh.bottom_radius = 0.075
			wheel_mesh.height = 0.065
			wheel_mesh.radial_segments = 12
			var wheel := MeshInstance3D.new()
			wheel.mesh = wheel_mesh
			wheel.material_override = wheels
			wheel.position = Vector3(side * 0.23, -0.075, end * 0.36)
			wheel.rotation.z = PI / 2.0
			_board_visual.add_child(wheel)

	# Bent stance, outward feet, and relaxed arms give a clear original silhouette.
	_box(_rider_visual, Vector3(0.43, 0.23, 0.3), Vector3(0, 0.82, 0), trousers)
	_box(_rider_visual, Vector3(0.55, 0.46, 0.36), Vector3(0, 1.12, 0), teal)
	_box(_rider_visual, Vector3(0.3, 0.065, 0.018), Vector3(0, 1.14, 0.19), deck)
	_box(_rider_visual, Vector3(0.25, 0.065, 0.018), Vector3(0, 1.14, -0.19), deck)
	_limb(_rider_visual, Vector3(-0.11, 0.84, -0.07), Vector3(-0.18, 0.56, -0.29), 0.12, trousers)
	_limb(_rider_visual, Vector3(-0.18, 0.56, -0.29), Vector3(-0.06, 0.29, -0.32), 0.09, trousers)
	_limb(_rider_visual, Vector3(0.11, 0.84, 0.08), Vector3(0.2, 0.55, 0.23), 0.12, trousers)
	_limb(_rider_visual, Vector3(0.2, 0.55, 0.23), Vector3(0.02, 0.29, 0.33), 0.09, trousers)
	var front_shoe := _box(_rider_visual, Vector3(0.31, 0.13, 0.17), Vector3(-0.01, 0.27, -0.32), shoes)
	front_shoe.rotation.y = -0.12
	var rear_shoe := _box(_rider_visual, Vector3(0.31, 0.13, 0.17), Vector3(0.02, 0.27, 0.32), shoes)
	rear_shoe.rotation.y = 0.15
	_limb(_rider_visual, Vector3(-0.28, 1.26, 0), Vector3(-0.46, 1.04, -0.1), 0.11, teal)
	_limb(_rider_visual, Vector3(-0.46, 1.04, -0.1), Vector3(-0.54, 0.91, -0.22), 0.075, skin)
	_limb(_rider_visual, Vector3(0.28, 1.26, 0), Vector3(0.48, 1.03, 0.11), 0.11, teal)
	_limb(_rider_visual, Vector3(0.48, 1.03, 0.11), Vector3(0.55, 0.96, 0.27), 0.075, skin)
	_limb(_rider_visual, Vector3(0, 1.3, 0), Vector3(0, 1.43, 0), 0.075, skin)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.17
	head_mesh.height = 0.34
	head_mesh.radial_segments = 16
	head_mesh.rings = 8
	var head := MeshInstance3D.new()
	head.mesh = head_mesh
	head.material_override = skin
	head.position = Vector3(0, 1.49, -0.025)
	_rider_visual.add_child(head)
	_box(_rider_visual, Vector3(0.35, 0.12, 0.33), Vector3(0, 1.63, -0.025), orange)
	_box(_rider_visual, Vector3(0.3, 0.035, 0.17), Vector3(0, 1.585, -0.22), orange)
	for eye_x: float in [-0.06, 0.06]:
		_box(_rider_visual, Vector3(0.035, 0.035, 0.018), Vector3(eye_x, 1.51, -0.18), grip)
