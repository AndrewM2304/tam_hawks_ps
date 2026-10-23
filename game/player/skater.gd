extends CharacterBody3D
## Forgiving arcade controller. Origin is at the ground beneath the skateboard.
## Travel heading and cosmetic aerial spins are deliberately independent in M01.

signal trick_performed(trick_name: String, points: int)
signal grind_captured(rail_id: String)
signal landed(clean: bool)
signal bailed()
signal combo_link_started()
signal combo_link_ended()
signal hold_points_awarded(points: int)

const GrindRideSource = preload("res://game/tricks/grind_ride.gd")
const TrickCatalog = preload("res://game/tricks/trick_catalog.gd")
const TrickInput = preload("res://game/tricks/trick_input.gd")
const SkaterVisualSource = preload("res://game/player/skater_visual.gd")
const SkateResponse = preload("res://game/player/skate_response.gd")
const ChaseCamera = preload("res://game/player/chase_camera.gd")
const GRIND_RECAPTURE_DELAY := 0.35

const MAX_SPEED := 15.0
const PUSH_ACCELERATION := 10.0
const BRAKE_DECELERATION := 22.0
const ROLLING_DRAG := 0.75
const GRAVITY := 22.0
const OLLIE_SPEED := 8.8
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.12
const SPIN_SPEED := 7.2
const FLIP_DURATION := 0.48
const MANUAL_MIN_SPEED := 2.0
const MANUAL_REENTRY_DELAY := 0.35
const MANUAL_BALANCE_CONTROL := 1.5
const REVERT_DURATION := 0.18
const REVERT_SPEED_RETAINED := 0.85
const SPECIAL_DURATION := 0.65
const WORLD_LIMIT := 400.0
const FLIP_CATCH_COOLDOWN := 0.06
const FLIP_LANDING_TOLERANCE := 0.80
const MANUAL_BUFFER_SECONDS := 0.18
const GRAB_MINIMUM_SECONDS := 0.20
const HOLD_INTERVAL := 0.25
const HOLD_AWARD := 25
const HOLD_LIMIT := 300

var speed: float = 0.0
var airborne: bool = false
var spawn_position: Vector3 = Vector3(0.0, 0.8, 12.0)
var manual_active := false
var manual_balance := 0.0
var revert_remaining := 0.0
var special_name := ""
## Set synchronously before the legacy two-argument trick signal.
var last_trick_id := ""
var flip_trick_id := ""
var grab_trick_id := ""
var grind_trick_id := ""
var manual_trick_id := "manual"
var stance: String:
	get:
		return "SWITCH" if absf(wrapf(_stance_angle, -PI, PI)) > PI * 0.5 else "REGULAR"
var active_trick: String:
	get:
		if not special_name.is_empty(): return special_name
		if grinding: return str(TrickCatalog.definition(grind_trick_id).get("display_name", "Rail Grind"))
		if manual_active: return str(TrickCatalog.definition(manual_trick_id).get("display_name", "Manual"))
		if _flip_remaining > 0.0: return str(_flip_definition.get("display_name", ""))
		if _grab_remaining > 0.0: return str(_grab_definition.get("display_name", ""))
		return ""
var hold_points: int:
	get:
		if grinding: return _grind_hold_points
		return _air_hold_points if airborne and _grab_remaining > 0.0 else 0

var _trick_input = TrickInput.new()
var _flip_definition: Dictionary = {}
var _grab_definition: Dictionary = {}
var _grind_definition: Dictionary = {}
var _pending_grab: Dictionary = {}
var _flip_duration := FLIP_DURATION
var _deck_yaw := 0.0
var _flip_yaw_committed := true
var _flip_catch_remaining := 0.0
var _grab_cooldown := 0.0
var _grab_elapsed := 0.0
var _grab_hold_tick := 0
var _air_hold_points := 0
var _grind_hold_tick := 0
var _grind_hold_points := 0
var _manual_buffer_remaining := 0.0
var _buffered_manual_id := "manual"

var _manual_cooldown := 0.0
var _manual_elapsed := 0.0
var _revert_used := false
var _revert_pose_remaining := 0.0
var _stance_angle := 0.0
var _special_id := ""
var _special_remaining := 0.0
var _special_used_this_air := false
var _surface_pitch := 0.0
var _camera_sensitivity := 1.0
var _reduced_motion := false
var _shirt_material: StandardMaterial3D
var _shirt_color := Color("4d6270")

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
var _flip_remaining := 0.0
var _grab_remaining := 0.0
var _spin_angle := 0.0
var _air_spin := 0.0
var _steering := 0.0
var _visual: Node3D
var _board_visual: Node3D
var _rider_visual: Node3D
var _camera: Camera3D
var _visual_rig: RefCounted
var _response = SkateResponse.new()
var _camera_follow = ChaseCamera.new()


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
	_trick_input.reset()
	last_trick_id = ""
	flip_trick_id = ""
	grab_trick_id = ""
	grind_trick_id = ""
	manual_trick_id = "manual"
	_flip_definition.clear()
	_grab_definition.clear()
	_grind_definition.clear()
	_pending_grab.clear()
	_flip_duration = FLIP_DURATION
	_deck_yaw = 0.0
	_flip_yaw_committed = true
	_flip_catch_remaining = 0.0
	_grab_cooldown = 0.0
	_grab_elapsed = 0.0
	_grab_hold_tick = 0
	_air_hold_points = 0
	_grind_hold_tick = 0
	_grind_hold_points = 0
	_manual_buffer_remaining = 0.0
	_buffered_manual_id = "manual"
	_response.reset()
	_camera_follow.reset()
	_grind.stop()
	_grind_cooldown = 0.0
	manual_active = false
	manual_balance = 0.0
	_manual_cooldown = 0.0
	_manual_elapsed = 0.0
	revert_remaining = 0.0
	_revert_used = false
	_revert_pose_remaining = 0.0
	_stance_angle = 0.0
	_special_used_this_air = false
	_clear_special_visual()
	_surface_pitch = 0.0
	global_position = spawn_position
	rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	speed = 0.0
	airborne = false
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_spin_angle = 0.0
	_air_spin = 0.0
	_steering = 0.0
	if is_instance_valid(_visual):
		_visual_rig.reset()
		_visual.position = Vector3.ZERO
		_visual.rotation = Vector3.ZERO
		_board_visual.rotation = Vector3.ZERO
		_rider_visual.position = Vector3.ZERO
		_rider_visual.rotation = Vector3(0.0, -PI / 2.0 + 0.28, 0.0)
	if is_instance_valid(_camera):
		_camera.global_position = global_position + Vector3(0.0, 3.4, 6.0)
		_camera.look_at(global_position + Vector3(0.0, 1.0, -1.5))


func recover_to(safe_position: Vector3) -> void:
	# A local hazard return preserves the career's original restart location.
	if not safe_position.is_finite():
		return
	bailed.emit()
	var run_spawn := spawn_position
	spawn_position = safe_position
	reset_skater()
	spawn_position = run_spawn


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if not enabled:
		_response.reset()
		_trick_input.reset()
		_pending_grab.clear()
		_manual_buffer_remaining = 0.0
		_end_manual(true)
		speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		_jump_buffer_remaining = 0.0
		revert_remaining = 0.0


func set_trick_entries_enabled(enabled: bool) -> void:
	# Run overtime permits an existing combo to land, without starting links.
	_trick_entries_enabled = enabled
	if not enabled:
		_jump_buffer_remaining = 0.0
		revert_remaining = 0.0
		_manual_buffer_remaining = 0.0
		_pending_grab.clear()


func set_grind_lines(lines: Array) -> void:
	# Snapshot the collection; geometry itself is immutable during a run.
	_grind_lines = lines.duplicate()


func set_presentation_settings(camera_sensitivity: float, reduced_motion: bool) -> void:
	_camera_sensitivity = clampf(camera_sensitivity, 0.5, 2.0) if is_finite(camera_sensitivity) else 1.0
	_reduced_motion = reduced_motion


func set_skater_color(color: Color) -> void:
	if not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b):
		return
	_shirt_color = Color(clampf(color.r, 0.0, 1.0), clampf(color.g, 0.0, 1.0), clampf(color.b, 0.0, 1.0))
	if is_instance_valid(_shirt_material):
		_shirt_material.albedo_color = _shirt_color


func try_special(trick_id: String) -> bool:
	# Main owns unlocks and meter spending; only a true result consumes a charge.
	if not is_inside_tree() or get_tree().paused or not airborne or grinding or manual_active or not _controls_enabled \
			or not _trick_entries_enabled or _special_used_this_air:
		return false
	if trick_id not in ["special_clyde_carousel", "special_tenement_tumble"]:
		return false
	if _flip_remaining > 0.0 or _grab_remaining > 0.0 or not _pending_grab.is_empty():
		return false
	_special_used_this_air = true
	_special_id = trick_id
	_special_remaining = SPECIAL_DURATION
	special_name = TrickCatalog.definition(trick_id)["display_name"]
	_emit_trick(trick_id)
	return true


func _clear_special_visual() -> void:
	_special_remaining = 0.0
	_special_id = ""
	special_name = ""
	if is_instance_valid(_board_visual):
		_board_visual.rotation.y = 0.0


func _physics_process(delta: float) -> void:
	if _controls_enabled:
		_trick_input.sample(delta)
	_flip_catch_remaining = maxf(0.0, _flip_catch_remaining - delta)
	_grab_cooldown = maxf(0.0, _grab_cooldown - delta)
	_manual_buffer_remaining = maxf(0.0, _manual_buffer_remaining - delta)
	if not Input.is_action_pressed("manual"):
		_manual_buffer_remaining = 0.0
	_grind_cooldown = maxf(0.0, _grind_cooldown - delta)
	_manual_cooldown = maxf(0.0, _manual_cooldown - delta)
	revert_remaining = maxf(0.0, revert_remaining - delta)
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
		if _trick_entries_enabled and airborne and Input.is_action_just_pressed("manual"):
			_manual_buffer_remaining = MANUAL_BUFFER_SECONDS
			_buffered_manual_id = _manual_choice()
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	_coyote_remaining = COYOTE_TIME if grounded_before else maxf(0.0, _coyote_remaining - delta)

	if manual_active:
		if not grounded_before:
			_end_manual(false)
		elif not _controls_enabled or not Input.is_action_pressed("manual") or speed < MANUAL_MIN_SPEED:
			_end_manual(true)
		elif not _tick_manual_balance(delta, push_input, brake_input):
			return

	if grounded_before:
		if manual_active:
			# Fore/aft input corrects balance while the manual coasts.
			speed = move_toward(speed, 0.0, ROLLING_DRAG * delta)
		elif brake_input > 0.05:
			speed = move_toward(speed, 0.0, BRAKE_DECELERATION * brake_input * delta)
		elif push_input > 0.05:
			speed = minf(MAX_SPEED, speed + PUSH_ACCELERATION * push_input * delta)
		else:
			speed = _response.coast_speed(speed, delta)
	# Ground carving and modest air correction are separate. Camera preferences
	# cannot change the rider's physical turning rate.
	var steering_angle: float = _response.steering_step(_steering, speed, grounded_before, delta)
	rotation.y += steering_angle
	var forward := -global_basis.z
	if grounded_before:
		var floor_normal := get_floor_normal()
		var ground_direction := forward.slide(floor_normal).normalized()
		var downhill_tangent := Vector3.DOWN.slide(floor_normal)
		var downhill_alignment := downhill_tangent.dot(ground_direction)
		speed = _response.apply_slope_gravity(speed, downhill_alignment, delta, GRAVITY)
		velocity = ground_direction * speed
	else:
		# Carry the ramp/contact-adjusted momentum into air. Rebuilding X/Z
		# from surface speed adds energy at lips and restores blocked motion.
		velocity = velocity.rotated(Vector3.UP, steering_angle)
		velocity.y -= GRAVITY * delta

	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0:
		_end_manual(false)
		_begin_air()
		velocity.y = maxf(0.0, velocity.y) + OLLIE_SPEED
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		combo_link_started.emit()
		_emit_trick("ollie")

	if airborne and _controls_enabled:
		_apply_air_tricks(delta)
		if _trick_entries_enabled and _try_grind():
			_update_pose(delta)
			return

	move_and_slide()
	if is_on_floor():
		# Derive signed board-forward speed from actual contact-adjusted travel.
		# This preserves collision response while allowing a steep uphill to
		# become a controlled roll back down its bank.
		var contact_direction := (-global_basis.z).slide(get_floor_normal()).normalized()
		speed = clampf(get_real_velocity().dot(contact_direction), -MAX_SPEED, MAX_SPEED)
		if airborne and not _finish_landing():
			_update_pose(delta)
			return
		if manual_active and speed < MANUAL_MIN_SPEED:
			_end_manual(true)
		_try_ground_links()
	else:
		_end_manual(false)
		speed = Vector2(velocity.x, velocity.z).length()
		if not airborne:
			_begin_air()

	if global_position.y < -8.0 or absf(global_position.x) > WORLD_LIMIT or absf(global_position.z) > WORLD_LIMIT:
		bailed.emit()
		reset_skater()

	_update_pose(delta)


func _begin_air() -> void:
	if airborne:
		return
	airborne = true
	_trick_input.clear_recent()
	_flip_definition.clear()
	_grab_definition.clear()
	_pending_grab.clear()
	flip_trick_id = ""
	grab_trick_id = ""
	grind_trick_id = ""
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_flip_catch_remaining = 0.0
	_grab_cooldown = 0.0
	_grab_elapsed = 0.0
	_grab_hold_tick = 0
	_air_hold_points = 0
	_manual_buffer_remaining = 0.0
	revert_remaining = 0.0
	_special_used_this_air = false
	_clear_special_visual()
	_air_spin = 0.0
	_spin_angle = 0.0


func _apply_air_tricks(delta: float) -> void:
	if _trick_entries_enabled and _special_remaining <= 0.0:
		if Input.is_action_just_pressed("flip") and _flip_remaining <= 0.0 and _flip_catch_remaining <= 0.0:
			_flip_definition = TrickCatalog.resolve("flip", _trick_input.direction())
			flip_trick_id = str(_flip_definition.id)
			_flip_duration = float(_flip_definition.get("duration", FLIP_DURATION))
			_flip_remaining = _flip_duration
			_flip_yaw_committed = false
			_grab_remaining = 0.0
			_grab_cooldown = 0.10
			_pending_grab.clear()
			_emit_trick(flip_trick_id)
		if Input.is_action_just_pressed("grab") and _grab_remaining <= 0.0 and _pending_grab.is_empty():
			var grab_choice := TrickCatalog.resolve("grab", _trick_input.direction())
			if _flip_remaining > 0.0 or _flip_catch_remaining > 0.0:
				_pending_grab = grab_choice
			elif _grab_cooldown <= 0.0:
				_start_grab(grab_choice)
		if not _pending_grab.is_empty() and _flip_remaining <= 0.0 and _flip_catch_remaining <= 0.0:
			_start_grab(_pending_grab.duplicate(true))
			_pending_grab.clear()
	if _grab_remaining > 0.0 and Input.is_action_pressed("grab"):
		_grab_remaining = maxf(_grab_remaining, delta + 0.05)
		_grab_elapsed += delta
		var tick := maxi(0, int(floor((_grab_elapsed + 0.000001) / HOLD_INTERVAL)) - 1)
		var points := mini(HOLD_LIMIT - _air_hold_points, maxi(0, tick - _grab_hold_tick) * HOLD_AWARD)
		_grab_hold_tick = tick
		if points > 0:
			_air_hold_points += points
			hold_points_awarded.emit(points)
	var spin_input := Input.get_axis("spin_left", "spin_right") if _trick_entries_enabled else 0.0
	_air_spin -= spin_input * SPIN_SPEED * delta
	_spin_angle = _air_spin


func _start_grab(choice: Dictionary) -> void:
	_grab_definition = choice.duplicate(true)
	grab_trick_id = str(choice.id)
	_grab_remaining = GRAB_MINIMUM_SECONDS
	_grab_elapsed = 0.0
	_grab_hold_tick = 0
	_emit_trick(grab_trick_id)


func _complete_flip() -> void:
	if not _flip_yaw_committed:
		_deck_yaw = wrapf(_deck_yaw + float(_flip_definition.get("board_yaw", 0.0)), -PI, PI)
		_flip_yaw_committed = true
	_flip_remaining = 0.0


func _emit_trick(trick_id: String, label: String = "", points: int = -1) -> void:
	var definition := TrickCatalog.definition(trick_id)
	if definition.is_empty():
		return
	last_trick_id = trick_id
	trick_performed.emit(str(definition.display_name) if label.is_empty() else label,
		int(definition.base_points) if points < 0 else points)


func _award_air_spin() -> void:
	# M01 uses forgiving, clean landings at any heading. Small spin tolerance
	# keeps the 180 accessible without precise last-frame timing.
	var half_turns := int(floor((absf(_air_spin) + deg_to_rad(20.0)) / PI))
	if half_turns > 0:
		var direction := "Frontside" if _air_spin > 0.0 else "Backside"
		_emit_trick("spin_180", "%s %d" % [direction, half_turns * 180], half_turns * 200)
		_stance_angle = wrapf(_stance_angle + half_turns * PI, -PI, PI)
		_spin_angle = wrapf(_air_spin - signf(_air_spin) * half_turns * PI, -PI, PI)
	_air_spin = 0.0


func _finish_landing() -> bool:
	if _flip_remaining > 0.0 and 1.0 - _flip_remaining / _flip_duration < FLIP_LANDING_TOLERANCE:
		bailed.emit()
		reset_skater()
		return false
	_complete_flip()
	_award_air_spin()
	_clear_special_visual()
	airborne = false
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_pending_grab.clear()
	revert_remaining = TrickCatalog.LANDING_LINK_SECONDS if _trick_entries_enabled else 0.0
	_revert_used = false
	landed.emit(true)
	return true


func _manual_choice() -> String:
	# Sustained pushing is travel input, not a deliberate nose-manual modifier.
	var direction: String = _trick_input.direction() if _trick_input.direction_age() <= MANUAL_BUFFER_SECONDS else "neutral"
	return str(TrickCatalog.resolve("manual", direction).id)


func _try_ground_links() -> void:
	if not _controls_enabled or not _trick_entries_enabled or grinding or not is_on_floor():
		return
	var fresh_manual := Input.is_action_just_pressed("manual")
	var buffered_manual := _manual_buffer_remaining > 0.0 and Input.is_action_pressed("manual")
	if not manual_active and _manual_cooldown <= 0.0 and speed >= MANUAL_MIN_SPEED \
			and (fresh_manual or buffered_manual):
		manual_active = true
		manual_trick_id = _buffered_manual_id if buffered_manual else _manual_choice()
		_manual_buffer_remaining = 0.0
		manual_balance = 0.05
		_manual_elapsed = 0.0
		combo_link_started.emit()
		_emit_trick(manual_trick_id)
	if not manual_active and not _revert_used and revert_remaining > 0.0 \
			and Input.is_action_just_pressed("revert"):
		_revert_used = true
		_revert_pose_remaining = REVERT_DURATION
		_stance_angle = wrapf(_stance_angle + PI, -PI, PI)
		speed *= REVERT_SPEED_RETAINED
		velocity.x *= REVERT_SPEED_RETAINED
		velocity.z *= REVERT_SPEED_RETAINED
		# A revert spends the existing landing window; it never opens a new one.
		_emit_trick("revert")


func _tick_manual_balance(delta: float, push_input: float, brake_input: float) -> bool:
	_manual_elapsed += delta
	var outward := 1.0 if manual_balance >= 0.0 else -1.0
	var drift := outward * (0.18 + 0.08 * _manual_elapsed)
	manual_balance += (drift + (brake_input - push_input) * MANUAL_BALANCE_CONTROL) * delta
	if absf(manual_balance) >= 1.0:
		bailed.emit()
		reset_skater()
		_manual_cooldown = MANUAL_REENTRY_DELAY
		return false
	return true


func _end_manual(grounded_exit: bool) -> void:
	if not manual_active:
		return
	manual_active = false
	manual_balance = 0.0
	_manual_elapsed = 0.0
	_manual_cooldown = MANUAL_REENTRY_DELAY
	if grounded_exit:
		combo_link_ended.emit()


func _try_grind() -> bool:
	if _grind_cooldown > 0.0 or not Input.is_action_pressed("grind"):
		return false
	if _flip_remaining > 0.0 and 1.0 - _flip_remaining / _flip_duration < FLIP_LANDING_TOLERANCE:
		return false
	if not _grind.start(_grind_lines, global_position, velocity, _rail_path_clear):
		return false
	_complete_flip()
	_award_air_spin()
	_clear_special_visual()
	airborne = false
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_pending_grab.clear()
	_grind_definition = TrickCatalog.resolve("grind", _trick_input.direction())
	grind_trick_id = str(_grind_definition.id)
	_grind_hold_points = 0
	_grind_hold_tick = 0
	_manual_buffer_remaining = 0.0
	_spin_angle = 0.0
	_jump_buffer_remaining = 0.0
	_coyote_remaining = 0.0
	revert_remaining = 0.0
	global_position = _grind.position()
	velocity = _grind.travel_velocity()
	speed = _grind.speed
	_align_to_travel()
	combo_link_started.emit()
	grind_captured.emit(_grind.line.id)
	_emit_trick(grind_trick_id)
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
	var tick := maxi(0, int(floor((_grind.elapsed + 0.000001) / HOLD_INTERVAL)) - 1)
	var points := mini(HOLD_LIMIT - _grind_hold_points, maxi(0, tick - _grind_hold_tick) * HOLD_AWARD)
	_grind_hold_tick = tick
	if points > 0:
		_grind_hold_points += points
		hold_points_awarded.emit(points)


func _release_grind(jump: bool) -> void:
	velocity = _grind.travel_velocity()
	_grind.stop()
	_grind_cooldown = GRIND_RECAPTURE_DELAY
	_begin_air()
	speed = Vector2(velocity.x, velocity.z).length()
	if jump:
		velocity.y = maxf(0.0, velocity.y) + OLLIE_SPEED
		combo_link_started.emit()
		_emit_trick("ollie")


func _update_pose(delta: float) -> void:
	var was_flipping := _flip_remaining > 0.0
	var was_grabbing := _grab_remaining > 0.0
	_flip_remaining = maxf(0.0, _flip_remaining - delta)
	_grab_remaining = maxf(0.0, _grab_remaining - delta)
	if was_flipping and _flip_remaining <= 0.0:
		_complete_flip()
		_flip_catch_remaining = FLIP_CATCH_COOLDOWN
	if was_grabbing and _grab_remaining <= 0.0:
		_grab_cooldown = 0.10
	_revert_pose_remaining = maxf(0.0, _revert_pose_remaining - delta)
	_special_remaining = maxf(0.0, _special_remaining - delta)
	if _special_remaining <= 0.0:
		_clear_special_visual()
	if not airborne:
		_spin_angle = lerp_angle(_spin_angle, 0.0, 1.0 - exp(-18.0 * delta))
	_visual.rotation.y = _spin_angle + _stance_angle - PI * (_revert_pose_remaining / REVERT_DURATION)
	_visual.rotation.z = lerpf(_visual.rotation.z, -_steering * 0.11 * (speed / MAX_SPEED), 1.0 - exp(-10.0 * delta))
	var flip_progress := clampf(1.0 - _flip_remaining / _flip_duration, 0.0, 1.0)
	var flip_curve := smoothstep(0.04, 0.88, flip_progress)
	var manual_sign := float(TrickCatalog.definition(manual_trick_id).get("manual_sign", 1.0))
	var deck_direction := cos(_deck_yaw)
	var board_pitch := deck_direction * manual_sign * (deg_to_rad(16.0) + manual_balance * 0.12) if manual_active else 0.0
	var board_roll := 0.0
	var board_yaw := _deck_yaw
	if grinding:
		board_yaw = float(_grind_definition.get("grind_yaw", 0.0))
		board_pitch = float(_grind_definition.get("grind_pitch", 0.0))
	elif _flip_remaining > 0.0:
		board_roll = deck_direction * float(_flip_definition.get("board_roll", TAU)) * flip_curve
		board_yaw += float(_flip_definition.get("board_yaw", 0.0)) * flip_curve
		board_pitch = deck_direction * float(_flip_definition.get("board_pitch", 0.0)) * sin(PI * flip_curve)
	elif _grab_remaining > 0.0:
		board_roll = deck_direction * float(_grab_definition.get("board_roll", 0.0))
		board_pitch = deck_direction * float(_grab_definition.get("board_pitch", 0.0))
	_board_visual.rotation.z = board_roll
	_board_visual.rotation.x = board_pitch if _flip_remaining > 0.0 else lerpf(_board_visual.rotation.x, board_pitch, 1.0 - exp(-16.0 * delta))
	var special_progress := 1.0 - _special_remaining / SPECIAL_DURATION
	_board_visual.rotation.y = _deck_yaw + TAU * special_progress if _special_id == "special_clyde_carousel" else board_yaw
	var grab_pose := 1.0 if _grab_remaining > 0.0 else 0.0
	var special_tuck := 0.25 * sin(PI * special_progress) if _special_id == "special_tenement_tumble" else 0.0
	_rider_visual.position.y = lerpf(_rider_visual.position.y, -0.17 * grab_pose - special_tuck, 1.0 - exp(-16.0 * delta))
	_rider_visual.rotation.x = lerpf(_rider_visual.rotation.x, -0.1 - grab_pose * 0.2, 1.0 - exp(-10.0 * delta))
	if grinding:
		_visual.rotation.z = -grind_balance * 0.35
		_rider_visual.position.y = -0.12
	elif manual_active:
		_rider_visual.position.y = -0.10
		_rider_visual.rotation.x = manual_sign * (-0.18 - manual_balance * 0.12)
	# Lean the visible board into slopes without pitching the upright collision.
	var desired_pitch := 0.0
	if grinding:
		desired_pitch = atan2(velocity.y, Vector2(velocity.x, velocity.z).length())
	elif is_on_floor():
		var local_normal := global_basis.inverse() * get_floor_normal()
		desired_pitch = atan2(local_normal.z, local_normal.y)
	_surface_pitch = lerpf(_surface_pitch, desired_pitch, 1.0 - exp(-14.0 * delta))
	_visual.rotation.x = _surface_pitch
	_visual.position = Vector3.ZERO
	if _special_id == "special_tenement_tumble":
		_visual.rotation.x += TAU * special_progress
		# Rotate the visible rider/board around the body, preserving the collision origin.
		var tumble_pivot := Vector3.UP * 0.8
		_visual.position = tumble_pivot - _visual.basis * tumble_pivot
	_visual_rig.animate(delta, {"airborne": airborne, "grab": _grab_remaining > 0.0,
		"flip": _flip_remaining > 0.0, "speed": absf(speed), "manual": manual_active,
		"grind": grinding, "push": _controls_enabled and Input.is_action_pressed("push"),
		"brake": _controls_enabled and Input.is_action_pressed("brake"),
		"steering": _steering, "manual_balance": manual_balance, "grind_balance": grind_balance,
		"revert_remaining": _revert_pose_remaining, "special_id": _special_id,
		"special_progress": special_progress, "flip_id": flip_trick_id, "flip_progress": flip_progress,
		"grab_id": grab_trick_id, "grab_side": _grab_definition.get("grab_side", -1.0),
		"grab_target": _grab_definition.get("grab_target", Vector3(-0.128, 0.022, -0.035)),
		"grind_id": grind_trick_id, "grind_yaw": _grind_definition.get("grind_yaw", 0.0),
		"grind_pitch": _grind_definition.get("grind_pitch", 0.0), "manual_sign": manual_sign,
		"deck_yaw": _board_visual.rotation.y if not grinding else 0.0,
		"rest_deck_yaw": _deck_yaw})


func _process(delta: float) -> void:
	_camera_follow.update(self, _camera, delta, _camera_sensitivity, _reduced_motion)


func _material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


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
	_board_visual.position.y = 0.12
	_visual.add_child(_board_visual)
	_rider_visual = Node3D.new()
	_rider_visual.name = "Rider"
	_visual.add_child(_rider_visual)

	_shirt_material = _material(_shirt_color, 0.94)
	_visual_rig = SkaterVisualSource.new()
	_visual_rig.build(_board_visual, _rider_visual, _shirt_material)
