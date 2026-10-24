extends CharacterBody3D
## Forgiving arcade controller. Origin is at the ground beneath the skateboard.
## Native contact movement with explicit ground, rail, wall and transition support.

signal trick_performed(trick_name: String, points: int)
signal grind_captured(rail_id: String)
signal landed(clean: bool)
signal bailed()
signal combo_link_started()
signal combo_link_ended()
signal hold_points_awarded(points: int)
signal special_requested(trick_id: String)
signal trick_upgraded(trick_name: String, points: int, trick_id: String)

const GrindRideSource = preload("res://game/tricks/grind_ride.gd")
const TrickCatalog = preload("res://game/tricks/trick_catalog.gd")
const TrickInput = preload("res://game/tricks/trick_input.gd")
const SkaterVisualSource = preload("res://game/player/skater_visual.gd")
const SkateResponse = preload("res://game/player/skate_response.gd")
const ChaseCamera = preload("res://game/player/chase_camera.gd")
const WallRideSource = preload("res://game/player/wall_ride.gd")
const TransitionRideSource = preload("res://game/player/transition_ride.gd")
const LaunchSetupSource = preload("res://game/player/launch_setup.gd")
const BailRecoverySource = preload("res://game/player/bail_recovery.gd")
const SkitchRideSource = preload("res://game/player/skitch_ride.gd")
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
var ollie_charge := 0.0
var crouching := false
var powersliding := false
var takeoff_mode := "Regular"
var _ollie_held := 0.0
var _ollie_was_held := false
var _ollie_blocked_until_release := false
var _ollie_released := false
var _launch_impulse := OLLIE_SPEED
var _launch_base_impulse := OLLIE_SPEED
var _launch_id := "ollie"
var _launch_age := 0.0
var _switch_stance := false
var _rail_backwards := false
var _style_cooldown := 0.0
var _manual_latched := false
var _manual_base_sign := 1.0
var _manual_gesture_pending := ""
var _force_air_tick := false
var _wall = WallRideSource.new()
var _transition = TransitionRideSource.new()
var wallriding: bool:
	get: return _wall.active
var transition_active: bool:
	get: return _transition.active
var lip_balance: float:
	get: return _transition.lip_balance if lip_active else 0.0
var lip_active: bool:
	get: return _transition.active and _transition.lip
var _setup = LaunchSetupSource.new()
var _bail = BailRecoverySource.new()
var _skitch = SkitchRideSource.new()
var _setup_impulse := OLLIE_SPEED
var _recovery_fade_remaining := 0.0
var _flip_motion_origin := Vector3.ZERO
var _grab_tweaked := false
var lip_trick_id := "lip_stall"
var _lip_definition: Dictionary = {}
var _special_definition: Dictionary = {}
var _special_duration := SPECIAL_DURATION
var _transition_backwards := false
var _native_platform_flush := false
var _native_floor_valid := false
var _native_platform_floor := RID()
var _native_platform_layer := 0
var _native_platform_ready := false
var _platform_layers_after_flush := 0xFFFFFFFF
var _platform_leave_after_flush := CharacterBody3D.PLATFORM_ON_LEAVE_ADD_VELOCITY
var _skitch_scored := false
var setup_active: bool:
	get: return _setup.active
var setup_id: String:
	get: return _setup.id
var setup_phase: float:
	get: return _setup.phase
var bail_active: bool:
	get: return _bail.active
var bail_phase: float:
	get: return _bail.phase
var recovery_fade: float:
	get: return _bail.fade() if bail_active else clampf(_recovery_fade_remaining / 0.18, 0.0, 1.0)
var lip_name: String:
	get: return str(_lip_definition.get("display_name", "Lip Stall"))
var skitching: bool:
	get: return _skitch.active
var skitch_caught: bool:
	get: return skitching and bool(_skitch.get("caught"))
var skitch_balance: float:
	get: return _skitch.balance if skitching else 0.0
var stance: String:
	get:
		if _switch_stance: return "SWITCH"
		return "FAKIE" if speed < -0.5 else "REGULAR"
var active_trick: String:
	get:
		if bail_active: return "Getting back up" if bail_phase > 0.55 else "Bail"
		if setup_active: return str(TrickCatalog.definition(setup_id).get("display_name", "Setup"))
		if lip_active: return lip_name
		if skitching: return "Skitch"
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
var _special_id := ""
var _special_remaining := 0.0
var _surface_pitch := 0.0
var _air_support_basis := Basis.IDENTITY
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
	collision_mask = 1 | 8
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


func reset_skater(preserve_camera: bool = false, preserve_support: bool = false) -> void:
	_native_floor_valid = preserve_support and is_on_floor()
	if not preserve_support:
		_discard_cached_support()
	_setup.reset()
	_bail.reset()
	_skitch.reset()
	_recovery_fade_remaining = 0.0
	_flip_motion_origin = Vector3.ZERO
	_grab_tweaked = false
	_lip_definition.clear()
	lip_trick_id = "lip_stall"
	_special_definition.clear()
	_special_duration = SPECIAL_DURATION
	_transition_backwards = false
	_transition.reset(self)
	_wall.reset()
	ollie_charge = 0.0
	crouching = false
	powersliding = false
	takeoff_mode = "Regular"
	_ollie_held = 0.0
	_ollie_was_held = false
	_ollie_released = false
	_launch_impulse = OLLIE_SPEED
	_launch_base_impulse = OLLIE_SPEED
	_launch_id = "ollie"
	_launch_age = 0.0
	_switch_stance = false
	_rail_backwards = false
	_style_cooldown = 0.0
	_manual_latched = false
	_manual_gesture_pending = ""
	_force_air_tick = not preserve_support
	_skitch_scored = false
	_manual_base_sign = 1.0
	_trick_input.reset()
	_trick_input.synchronize_held()
	_ollie_blocked_until_release = Input.is_action_pressed("ollie")
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
	if not preserve_camera: _camera_follow.reset()
	_grind.stop()
	_grind_cooldown = 0.0
	manual_active = false
	manual_balance = 0.0
	_manual_cooldown = 0.0
	_manual_elapsed = 0.0
	revert_remaining = 0.0
	_revert_used = false
	_revert_pose_remaining = 0.0
	_clear_special_visual()
	_surface_pitch = 0.0
	_air_support_basis = Basis.IDENTITY
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
	if is_instance_valid(_camera) and not preserve_camera:
		_camera.global_position = global_position + Vector3(0.0, 3.4, 6.0)
		_camera.look_at(global_position + Vector3(0.0, 1.0, -1.5))


func recover_to(safe_position: Vector3) -> void:
	if safe_position.is_finite(): _start_bail(safe_position)


func _start_bail(target: Vector3 = Vector3.INF) -> void:
	if bail_active: return
	if is_instance_valid(_visual_rig) and _visual_rig.has_method("begin_bail"): _visual_rig.begin_bail()
	var outward: Vector3 = _transition.normal if transition_active else (_wall.normal if wallriding else Vector3.ZERO)
	_setup.reset()
	_transition.reset(self)
	_wall.stop()
	_skitch.stop()
	_grind.stop()
	_end_manual(false)
	_clear_charge()
	_trick_input.clear_actions()
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_pending_grab.clear()
	_clear_special_visual()
	_jump_buffer_remaining = 0.0
	_coyote_remaining = 0.0
	airborne = false
	powersliding = false
	_bail.start(self, spawn_position, target, outward)
	bailed.emit()


func _tick_bail(delta: float) -> void:
	var result: Dictionary = _bail.step(self, delta)
	_restore_platform_after_move()
	speed = Vector3(velocity.x, 0, velocity.z).dot(-global_basis.z)
	if result.event == "recovered":
		var run_spawn := spawn_position
		var heading := rotation.y
		var near: bool = global_position.distance_to(result.target) < 3.0
		var in_place: bool = global_position.distance_to(result.target) < 0.001 and is_on_floor()
		spawn_position = result.target
		reset_skater(true, in_place)
		spawn_position = run_spawn
		rotation.y = heading if near else 0.0
		_recovery_fade_remaining = 0.18
		if not _controls_enabled: set_physics_process(false)


func _restore_platform_after_move() -> void:
	_native_floor_valid = true
	if is_on_floor():
		var hit := _native_floor_hit(_native_floor_normal())
		if not hit.is_empty():
			_native_platform_floor = hit.rid
			var collider := hit.collider as CollisionObject3D
			_native_platform_layer = collider.collision_layer if collider != null else 0
	else:
		_native_platform_floor = RID()
		_native_platform_layer = 0
		_native_platform_ready = false
	if _native_platform_flush:
		platform_floor_layers = _platform_layers_after_flush
		platform_on_leave = _platform_leave_after_flush
		_native_platform_flush = false
	# This contact supplies inheritance for the next native move, after any
	# teleport/helper cache flush has restored the player's normal layer mask.
	_native_platform_ready = is_on_floor() and _native_platform_floor.is_valid() and (_native_platform_layer & platform_floor_layers) != 0


func _discard_cached_support() -> void:
	_native_floor_valid = false
	_native_platform_floor = RID()
	_native_platform_layer = 0
	_native_platform_ready = false
	if not _native_platform_flush:
		_platform_layers_after_flush = platform_floor_layers
		_platform_leave_after_flush = platform_on_leave
	platform_floor_layers = 0
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	_native_platform_flush = true


func _tick_setup(delta: float) -> void:
	var result: Dictionary = _setup.step(self, delta)
	if bool(result.get("moved", false)): _restore_platform_after_move()
	speed = Vector3(velocity.x, 0, velocity.z).dot(-global_basis.z)
	if result.event == "launch":
		_launch_id = str(result.id)
		_launch_impulse = _setup_impulse
		_begin_air()
		_set_launch_mode()
		velocity.y = maxf(0.0, velocity.y) + _launch_impulse
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		combo_link_started.emit()
		_emit_trick(_launch_id)
		move_and_slide()
		_restore_platform_after_move()
	elif result.event == "unsupported":
		_launch_id = "ollie"
		if is_on_floor():
			combo_link_ended.emit()
		else:
			_begin_air()
			_force_air_tick = true


func _tick_skitch(delta: float) -> void:
	var result: Dictionary = _skitch.step(self, delta, _steering,
		_ollie_released and _trick_entries_enabled, Input.is_action_pressed("grind") and _controls_enabled, _launch_impulse)
	_restore_platform_after_move()
	if skitch_caught and not _skitch_scored:
		_skitch_scored = true
		combo_link_started.emit()
		_emit_trick("skitch")
	speed = Vector3(velocity.x, 0, velocity.z).dot(-global_basis.z)
	if result.bailed:
		_start_bail()
	elif result.launched:
		_launch_id = "ollie"
		_begin_air()
		_set_launch_mode()
		_jump_buffer_remaining = 0.0
		combo_link_started.emit()
		_emit_trick("ollie")
	elif not skitching:
		if is_on_floor(): combo_link_ended.emit()
		else: _begin_air()


func set_controls_enabled(enabled: bool) -> void:
	if enabled != _controls_enabled:
		_trick_input.synchronize_held()
		_ollie_blocked_until_release = Input.is_action_pressed("ollie")
	_controls_enabled = enabled
	if not enabled:
		_setup.reset()
		_skitch.stop()
		_response.reset()
		_trick_input.reset()
		_pending_grab.clear()
		_manual_buffer_remaining = 0.0
		_end_manual(true)
		speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		_jump_buffer_remaining = 0.0
		_clear_charge()
		_trick_input.clear_actions()
		revert_remaining = 0.0


func set_trick_entries_enabled(enabled: bool) -> void:
	if enabled != _trick_entries_enabled:
		_trick_input.synchronize_held()
		_ollie_blocked_until_release = Input.is_action_pressed("ollie")
	# Run overtime permits an existing combo to land, without starting links.
	_trick_entries_enabled = enabled
	if not enabled:
		_setup.reset()
		_jump_buffer_remaining = 0.0
		_clear_charge()
		_trick_input.clear_actions()
		revert_remaining = 0.0
		_manual_buffer_remaining = 0.0
		_pending_grab.clear()


func set_grind_lines(lines: Array) -> void:
	# Snapshot the collection; geometry itself is immutable during a run.
	_grind_lines = lines.duplicate()


func get_support_normal() -> Vector3:
	if transition_active: return _transition.normal
	if _native_floor_valid and is_on_floor() and not airborne and not _force_air_tick and not grinding and not wallriding and not bail_active:
		return _native_floor_normal()
	return Vector3.UP


func _native_floor_normal() -> Vector3:
	var normal := get_floor_normal()
	if _native_floor_valid and normal.length_squared() > 0.5: return normal.normalized()
	# A first floor-snap onto a stationary platform can report a floor flag
	# before supplying a normal. Use the actual native floor rather than slide
	# or normalize a zero vector.
	var hit := _native_floor_hit(Vector3.UP)
	if not hit.is_empty() and Vector3(hit.normal).y > 0.5: return hit.normal
	return Vector3.UP


func _native_floor_hit(normal: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(global_position + normal * 0.35,
		global_position - normal * 0.6, collision_mask)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)


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
	# Main owns unlocks and maintained special mode; only an accepted request executes.
	if not is_inside_tree() or get_tree().paused or not airborne or grinding or manual_active or not _controls_enabled \
			or not _trick_entries_enabled or _special_remaining > 0.0 or wallriding or lip_active or bail_active or setup_active or skitching:
		return false
	var definition := TrickCatalog.definition(trick_id)
	if definition.get("family", "") != "special": return false
	if _flip_remaining > 0.0 or _grab_remaining > 0.0 or not _pending_grab.is_empty():
		return false
	_special_id = trick_id
	_special_definition = definition
	_special_duration = clampf(float(definition.get("duration", SPECIAL_DURATION)), 0.4, 1.3)
	_special_remaining = _special_duration
	special_name = TrickCatalog.definition(trick_id)["display_name"]
	_emit_trick(trick_id)
	return true


func _clear_special_visual() -> void:
	_special_remaining = 0.0
	_special_id = ""
	_special_definition.clear()
	special_name = ""
	if is_instance_valid(_board_visual):
		_board_visual.rotation.y = 0.0


func _clear_charge() -> void:
	ollie_charge = 0.0
	crouching = false
	_ollie_held = 0.0
	_ollie_was_held = false
	_ollie_released = false


func _sample_ollie(delta: float) -> void:
	_ollie_released = false
	if setup_active:
		if Input.is_action_pressed("ollie"): _ollie_blocked_until_release = true
		_clear_charge()
		return
	if not _controls_enabled or not _trick_entries_enabled:
		_clear_charge()
		return
	var held := Input.is_action_pressed("ollie")
	if _ollie_blocked_until_release:
		if not held: _ollie_blocked_until_release = false
		_clear_charge()
		return
	var supported: bool = (_transition.state != "air") if transition_active else (grinding or wallriding or skitching or (is_on_floor() and not airborne and not _force_air_tick))
	if held:
		_ollie_held += delta
		ollie_charge = clampf((_ollie_held - 0.12) / 0.45, 0.0, 1.0)
		crouching = supported
	elif _ollie_was_held:
		_ollie_released = true
		_launch_base_impulse = OLLIE_SPEED + 2.2 * ollie_charge
		_launch_impulse = _launch_base_impulse
		_launch_id = "ollie"
		var direction: String = _trick_input.direction() if _trick_input.direction_age() <= 0.18 else "neutral"
		if direction == "north": _launch_id = "nollie"
		elif direction == "south" and is_on_floor() and not grinding and not transition_active and not wallriding and not skitching:
			_launch_id = "no_comply" if Input.is_action_pressed("manual") else "boneless"
		_launch_impulse *= float(TrickCatalog.definition(_launch_id).get("launch_speed_scale", 1.0))
		_launch_impulse = minf(12.0, _launch_impulse)
		_jump_buffer_remaining = JUMP_BUFFER_TIME
		_ollie_held = 0.0
		crouching = false
		ollie_charge = 0.0
	_ollie_was_held = held


func _physics_process(delta: float) -> void:
	if bail_active:
		_tick_bail(delta)
		_update_pose(delta)
		return
	if _controls_enabled:
		_trick_input.sample(delta)
		if not _trick_entries_enabled: _trick_input.clear_actions()
		var gesture: String = _trick_input.consume_manual_gesture()
		if not gesture.is_empty() and _trick_entries_enabled:
			_manual_gesture_pending = gesture
			_buffered_manual_id = gesture
			_manual_buffer_remaining = MANUAL_BUFFER_SECONDS
	_launch_age += delta
	_sample_ollie(delta)
	_wall.tick(delta)
	_skitch.tick(delta)
	_style_cooldown = maxf(0.0, _style_cooldown - delta)
	_flip_catch_remaining = maxf(0.0, _flip_catch_remaining - delta)
	_grab_cooldown = maxf(0.0, _grab_cooldown - delta)
	_manual_buffer_remaining = maxf(0.0, _manual_buffer_remaining - delta)
	if _manual_buffer_remaining <= 0.0:
		_manual_gesture_pending = ""
	if not Input.is_action_pressed("manual") and _manual_gesture_pending.is_empty():
		_manual_buffer_remaining = 0.0
	_grind_cooldown = maxf(0.0, _grind_cooldown - delta)
	_manual_cooldown = maxf(0.0, _manual_cooldown - delta)
	revert_remaining = maxf(0.0, revert_remaining - delta)
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	var push_input := Input.get_action_strength("push") if _controls_enabled else 0.0
	var brake_input := Input.get_action_strength("brake") if _controls_enabled else 0.0
	_steering = Input.get_axis("steer_left", "steer_right") if _controls_enabled else 0.0
	if crouching and not manual_active: push_input = maxf(push_input, 1.0)
	if setup_active:
		_tick_setup(delta)
		_update_pose(delta)
		return
	if skitching:
		_tick_skitch(delta)
		_update_pose(delta)
		return
	if _controls_enabled and _trick_entries_enabled and not (grinding or wallriding or transition_active or manual_active) 		and Input.is_action_pressed("grind") and Input.is_action_just_pressed("interact"):
		for vehicle: Node in get_tree().get_nodes_in_group("skate_vehicles"):
			if _skitch.try_start(self, vehicle):
				_jump_buffer_remaining = 0.0
				_coyote_remaining = 0.0
				airborne = false
				_skitch_scored = false
				var tow: Vector3 = _skitch.travel_velocity
				rotation.y = atan2(-tow.x, -tow.z)
				_tick_skitch(delta)
				_update_pose(delta)
				return
	if grinding:
		powersliding = false
		_tick_grind(delta)
		_update_pose(delta)
		return
	if _controls_enabled and not wallriding and not transition_active and not manual_active:
		if _transition.try_enter(self, velocity):
			_transition_backwards = velocity.dot(-global_basis.z) < 0.0
	if transition_active:
		powersliding = false
		_tick_transition(delta, push_input, brake_input)
		_update_pose(delta)
		return
	if wallriding:
		powersliding = false
		_tick_wall(delta)
		_update_pose(delta)
		return
	# Transition movement uses move_and_collide, whose old floor flags are not
	# an airborne exit contact. Refresh them through one ordinary native move.
	var grounded_before := is_on_floor() and not _force_air_tick
	_force_air_tick = false
	_coyote_remaining = COYOTE_TIME if grounded_before else maxf(0.0, _coyote_remaining - delta)
	if _controls_enabled and _trick_entries_enabled and airborne and Input.is_action_just_pressed("manual"):
		_manual_buffer_remaining = MANUAL_BUFFER_SECONDS
		_buffered_manual_id = _manual_choice()
	if manual_active:
		if not grounded_before:
			_end_manual(false)
		elif not _controls_enabled or (not Input.is_action_pressed("manual") and not _manual_latched) or absf(speed) < MANUAL_MIN_SPEED:
			_end_manual(true)
		elif not _tick_manual_balance(delta, push_input, brake_input):
			return
	powersliding = grounded_before and not manual_active and brake_input > 0.5 and absf(_steering) > 0.6 and absf(speed) > 4.0
	if grounded_before:
		if manual_active:
			speed = move_toward(speed, 0.0, ROLLING_DRAG * delta)
		elif brake_input > 0.05:
			speed = move_toward(speed, 0.0, (8.0 if powersliding else BRAKE_DECELERATION) * brake_input * delta)
		elif push_input > 0.05:
			var travel_sign := -1.0 if speed < -0.5 else 1.0
			speed = travel_sign * minf(MAX_SPEED, absf(speed) + PUSH_ACCELERATION * push_input * delta)
		else:
			speed = _response.coast_speed(speed, delta)
	var steering_angle: float = _response.steering_step(_steering, speed, grounded_before, delta)
	if powersliding: steering_angle += -_steering * 2.0 * delta
	rotation.y += steering_angle
	var forward := -global_basis.z
	if grounded_before:
		var floor_normal := _native_floor_normal()
		var ground_direction := forward.slide(floor_normal).normalized()
		var downhill_alignment := Vector3.DOWN.slide(floor_normal).dot(ground_direction)
		speed = _response.apply_slope_gravity(speed, downhill_alignment, delta, GRAVITY)
		velocity = ground_direction * speed
	else:
		velocity = velocity.rotated(Vector3.UP, steering_angle)
		velocity.y -= GRAVITY * delta
	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0:
		if _launch_id in ["boneless", "no_comply"] and _setup.try_start(self, _launch_id, SkaterVisualSource.setup_foot_offset()):
			_setup_impulse = _launch_impulse
			_jump_buffer_remaining = 0.0
			_coyote_remaining = 0.0
			_end_manual(false)
			_tick_setup(delta)
			_update_pose(delta)
			return
		if _launch_id in ["boneless", "no_comply"]:
			# A missing real sole plant cannot award a planted-foot trick or boost.
			_launch_id = "ollie"
			_launch_impulse = _launch_base_impulse
		_end_manual(false)
		_begin_air()
		_launch_age = 0.0
		_set_launch_mode()
		velocity.y = maxf(0.0, velocity.y) + _launch_impulse
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		combo_link_started.emit()
		_emit_trick(_launch_id)
	if airborne and _controls_enabled:
		_apply_air_tricks(delta)
		if bail_active:
			_update_pose(delta)
			return
		if _trick_entries_enabled and _try_grind():
			_update_pose(delta)
			return
		if _trick_entries_enabled and Input.is_action_pressed("grind") and _flip_remaining <= 0.0 and _special_remaining <= 0.0 and _spin_landing_clean() and _wall.try_start(self, velocity):
			_complete_flip()
			_award_air_spin()
			var wall_travel: Vector3 = Vector3(_wall.travel_velocity.x, 0.0, _wall.travel_velocity.z)
			var backwards := wall_travel.dot(-global_basis.z) < 0.0
			if wall_travel.length_squared() > 0.001:
				rotation.y = atan2(-wall_travel.x, -wall_travel.z) + (PI if backwards else 0.0)
			_spin_angle = 0.0
			_grab_remaining = 0.0
			_pending_grab.clear()
			_emit_trick("wallride")
			combo_link_started.emit()
			_tick_wall(delta)
			_update_pose(delta)
			return
	var previous_platform := _native_platform_floor
	var previous_carry_ready := _native_platform_ready
	var arriving_from_air := airborne
	move_and_slide()
	_restore_platform_after_move()
	if is_on_floor():
		var contact_direction := (-global_basis.z).slide(_native_floor_normal()).normalized()
		# Both values belong to this completed native move. A cached pre-move
		# platform velocity falsely injected reverse speed when the cart stopped.
		var continuing_platform := previous_carry_ready and previous_platform == _native_platform_floor
		var carry := get_platform_velocity() if arriving_from_air or continuing_platform else Vector3.ZERO
		speed = clampf((get_real_velocity() - carry).dot(contact_direction), -MAX_SPEED, MAX_SPEED)
		if airborne and not _finish_landing():
			_update_pose(delta)
			return
		if manual_active and absf(speed) < MANUAL_MIN_SPEED: _end_manual(true)
		_try_ground_links()
	else:
		_end_manual(false)
		speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)
		if not airborne:
			_launch_id = "ollie"
			_begin_air()
	if global_position.y < -8.0 or absf(global_position.x) > WORLD_LIMIT or absf(global_position.z) > WORLD_LIMIT:
		_start_bail()
	_update_pose(delta)


func _tick_transition(delta: float, push: float, brake: float) -> void:
	if not _controls_enabled: return
	_discard_cached_support()
	_coyote_remaining = 0.0
	# A released pop cannot skip the landing catch/alignment check on first contact.
	if airborne and _transition.state in ["surface", "lip"]:
		if not _finish_landing(): return
	var was_lip: bool = _transition.state == "lip"
	var was_air: bool = _transition.state == "air"
	if was_lip and _trick_entries_enabled: _try_lip_extension()
	if was_air:
		_apply_air_tricks(delta)
		if _trick_entries_enabled and _try_grind(true): return
	var result: Dictionary = _transition.step(self, delta, push, brake, _steering,
		_ollie_released and _trick_entries_enabled, Input.is_action_pressed("grind") and _trick_entries_enabled, _launch_impulse)
	speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)
	if was_lip and _transition.active and _transition.state == "surface":
		combo_link_ended.emit()
	match str(result.get("event", "")):
		"launch":
			if not _ollie_released: _launch_id = "ollie"
			_begin_air()
			if _ollie_released: _set_launch_mode()
			_jump_buffer_remaining = 0.0
			combo_link_started.emit()
			if _ollie_released: _emit_trick(_launch_id)
		"landed":
			if airborne: _finish_landing()
		"lip":
			if airborne and not _finish_landing(): return
			var direction: String = _trick_input.direction() if _trick_input.direction_age() <= 0.18 else "neutral"
			_lip_definition = TrickCatalog.resolve("lip", direction)
			lip_trick_id = str(_lip_definition.id)
			_emit_trick(lip_trick_id)
			combo_link_started.emit()
		"bail":
			_start_bail()
		"exit":
			if airborne: _finish_landing()
			combo_link_ended.emit()
		"exit_air":
			_force_air_tick = true
			_coyote_remaining = 0.0
			if not airborne: _begin_air()
	if _transition.active and _transition.state == "surface" and airborne:
		_finish_landing()
	if _transition.active and _transition.state == "surface" and _transition.feature.get("wrap_lateral") == true:
		var travel: Vector3 = Vector3(_transition.forward.x, 0, _transition.forward.z)
		if travel.length_squared() > 0.001:
			rotation.y = atan2(-travel.x, -travel.z) + (PI if _transition_backwards else 0.0)
			speed = Vector3(velocity.x, 0, velocity.z).dot(-global_basis.z)
	if transition_active: _transition.refresh_frame(self)


func _try_lip_extension() -> void:
	if _style_cooldown > 0.0: return
	var action: Dictionary = _trick_input.pop_action("flip")
	if action.is_empty(): action = _trick_input.pop_action("grab")
	if action.is_empty(): action = _trick_input.pop_action("revert")
	if action.is_empty(): return
	var choice := TrickCatalog.resolve_extension("lip", str(action.action), str(action.direction), lip_trick_id)
	if choice.is_empty() or str(choice.id) == lip_trick_id: return
	_lip_definition = choice
	lip_trick_id = str(choice.id)
	_style_cooldown = 0.35
	if str(choice.id) == "rock_and_roll":
		rotation.y += PI
		_switch_stance = not _switch_stance
		_transition_backwards = not _transition_backwards
	_emit_trick(lip_trick_id)


func _tick_wall(delta: float) -> void:
	if not _controls_enabled: return
	var result: Dictionary = _wall.step(self, delta, _steering,
		_ollie_released and _trick_entries_enabled, Input.is_action_pressed("grind") and _trick_entries_enabled)
	speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)
	if result.bailed:
		_start_bail()
		return
	if result.launched:
		_launch_id = "wallie"
		_set_launch_mode()
		_jump_buffer_remaining = 0.0
		_emit_trick("wallie")
	if not _wall.active and is_on_floor():
		_finish_landing()


func _set_launch_mode() -> void:
	_launch_age = 0.0
	takeoff_mode = _launch_id.capitalize() if _launch_id not in ["ollie", "wallie"] else stance.capitalize()


func _begin_air() -> void:
	if airborne:
		return
	airborne = true
	takeoff_mode = stance.capitalize()
	_launch_age = 0.0
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
	_clear_special_visual()
	_air_spin = 0.0
	_spin_angle = 0.0


func _apply_air_tricks(delta: float) -> void:
	# Consume recognized commands after actual takeoff, before generic actions.
	# A short pre-pop command can queue without scoring an ineligible ground move.
	if _trick_entries_enabled and _special_remaining <= 0.0 and _flip_remaining <= 0.0 and _grab_remaining <= 0.0 and _pending_grab.is_empty():
		var special: String = _trick_input.consume_special()
		if special.is_empty() and not _trick_input.pop_action("special_one").is_empty():
			special = "special_clyde_carousel"
		if special.is_empty() and not _trick_input.pop_action("special_two").is_empty():
			special = "special_tenement_tumble"
		if not special.is_empty(): special_requested.emit(special)
	if _trick_entries_enabled and _special_remaining <= 0.0:
		if _flip_remaining > 0.0 and _trick_input.consume_double_tap("flip"):
			var upgraded := TrickCatalog.resolve_upgrade(flip_trick_id)
			if not upgraded.is_empty():
				_flip_motion_origin = _flip_pose_angles()
				_flip_definition = upgraded
				flip_trick_id = str(upgraded.id)
				_flip_duration = float(upgraded.duration)
				_flip_remaining = _flip_duration
				last_trick_id = flip_trick_id
				trick_upgraded.emit(_styled_trick_name(upgraded), int(upgraded.base_points), flip_trick_id)
		var flip_action: Dictionary = _trick_input.pop_action("flip") if _flip_remaining <= 0.0 and _flip_catch_remaining <= 0.0 else {}
		if not flip_action.is_empty():
			_flip_definition = TrickCatalog.resolve("flip", str(flip_action.direction))
			flip_trick_id = str(_flip_definition.id)
			_flip_duration = float(_flip_definition.get("duration", FLIP_DURATION))
			_flip_remaining = _flip_duration
			_flip_yaw_committed = false
			_flip_motion_origin = Vector3.ZERO
			_grab_remaining = 0.0
			_grab_cooldown = 0.10
			_pending_grab.clear()
			_emit_trick(flip_trick_id)
		var grab_action: Dictionary = _trick_input.pop_action("grab") if _grab_remaining <= 0.0 and _pending_grab.is_empty() else {}
		if not grab_action.is_empty():
			var grab_choice := TrickCatalog.resolve("grab", str(grab_action.direction))
			if _flip_remaining > 0.0 or _flip_catch_remaining > 0.0:
				_pending_grab = grab_choice
			elif _grab_cooldown <= 0.0:
				_start_grab(grab_choice)
		if not _pending_grab.is_empty() and _flip_remaining <= 0.0 and _flip_catch_remaining <= 0.0:
			_start_grab(_pending_grab.duplicate(true))
			_pending_grab.clear()
	if _trick_entries_enabled and _grab_remaining > 0.0:
		var tweak_action: Dictionary = _trick_input.consume_tap_upgrade("grab")
		if not _grab_tweaked and not tweak_action.is_empty():
			_grab_definition = TrickCatalog.grab_tweak(grab_trick_id, str(tweak_action.direction))
			_grab_tweaked = true
			last_trick_id = grab_trick_id
			trick_upgraded.emit(_styled_trick_name(_grab_definition), int(_grab_definition.base_points), grab_trick_id)
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
	_grab_tweaked = false
	_emit_trick(grab_trick_id)


func _flip_pose_angles() -> Vector3:
	var progress := clampf(1.0 - _flip_remaining / maxf(_flip_duration, 0.001), 0.0, 1.0)
	var curve := smoothstep(0.04, 0.88, progress)
	return Vector3(lerpf(_flip_motion_origin.x, float(_flip_definition.get("board_roll", TAU)), curve),
		lerpf(_flip_motion_origin.y, float(_flip_definition.get("board_yaw", 0.0)), curve),
		lerpf(_flip_motion_origin.z, 0.0, curve) + float(_flip_definition.get("board_pitch", 0.0)) * sin(PI * curve))


func _complete_special() -> void:
	if not _special_definition.is_empty():
		_air_spin += float(_special_definition.get("special_body_yaw", 0.0))
		_spin_angle = _air_spin
		_deck_yaw = wrapf(_deck_yaw + float(_special_definition.get("special_board_yaw", 0.0)), -PI, PI)
	_clear_special_visual()


func _special_axis(angle: float, progress: float) -> float:
	return angle * progress if absf(angle) >= PI - 0.001 else angle * sin(PI * progress)


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
	var display := _styled_trick_name(definition) if label.is_empty() else label
	trick_performed.emit(display,
		int(definition.base_points) if points < 0 else points)


func _styled_trick_name(definition: Dictionary) -> String:
	var display := str(definition.get("display_name", ""))
	if str(definition.get("family", "")) in ["flip", "grab"] and takeoff_mode in ["Switch", "Fakie", "Nollie"]:
		display = "%s %s" % [takeoff_mode, display]
	return display


func _award_air_spin() -> void:
	var half_turns := int(round(absf(_air_spin) / PI))
	if half_turns > 0:
		var direction := "Frontside" if _air_spin > 0.0 else "Backside"
		_emit_trick("spin_180", "%s %d" % [direction, half_turns * 180], half_turns * 200)
		var turn := signf(_air_spin) * half_turns * PI
		rotation.y += turn
		if half_turns % 2 == 1: _switch_stance = not _switch_stance
		_spin_angle = wrapf(_air_spin - turn, -PI, PI)
		speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)
	_air_spin = 0.0


func _spin_landing_clean() -> bool:
	return absf(_air_spin - roundf(_air_spin / PI) * PI) <= deg_to_rad(45.0)


func _finish_landing() -> bool:
	if _special_remaining > 0.0 and _special_remaining <= 0.15: _complete_special()
	if _special_remaining > 0.15 or not _spin_landing_clean() or (_flip_remaining > 0.0 and 1.0 - _flip_remaining / _flip_duration < FLIP_LANDING_TOLERANCE):
		_start_bail()
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
	if manual_active and _manual_latched and fresh_manual:
		_end_manual(true)
		return
	var buffered_manual := _manual_buffer_remaining > 0.0 and (Input.is_action_pressed("manual") or not _manual_gesture_pending.is_empty())
	# Manual also modifies a prepared No Comply. While crouching it must not
	# manufacture a separate manual entry before that planted-foot takeoff.
	if not manual_active and not crouching and _manual_cooldown <= 0.0 and absf(speed) >= MANUAL_MIN_SPEED \
			and (fresh_manual or buffered_manual):
		manual_active = true
		manual_trick_id = _buffered_manual_id if buffered_manual else _manual_choice()
		_manual_latched = not _manual_gesture_pending.is_empty()
		_manual_gesture_pending = ""
		_manual_base_sign = float(TrickCatalog.definition(manual_trick_id).get("manual_sign", 1.0))
		_manual_buffer_remaining = 0.0
		manual_balance = 0.05
		_manual_elapsed = 0.0
		combo_link_started.emit()
		_emit_trick(manual_trick_id)
	if manual_active and _style_cooldown <= 0.0:
		var action: Dictionary = _trick_input.pop_action("flip")
		if action.is_empty(): action = _trick_input.pop_action("grab")
		if action.is_empty(): action = _trick_input.pop_action("revert")
		if not action.is_empty():
			var choice := TrickCatalog.resolve_extension("manual", str(action.action), str(action.direction), manual_trick_id)
			if not choice.is_empty() and str(choice.id) != manual_trick_id:
				manual_trick_id = str(choice.id)
				_manual_base_sign = float(choice.get("manual_sign", _manual_base_sign))
				_style_cooldown = 0.35
				if float(choice.get("manual_yaw", 0.0)) != 0.0: _physical_revert()
				_emit_trick(manual_trick_id)
	if not manual_active and not _revert_used and revert_remaining > 0.0 \
			and Input.is_action_just_pressed("revert"):
		_revert_used = true
		_trick_input.pop_action("revert")
		_physical_revert()
		# A revert spends the existing landing window; it never opens a new one.
		_emit_trick("revert")


func _physical_revert() -> void:
	rotation.y += PI
	_switch_stance = not _switch_stance
	_revert_pose_remaining = REVERT_DURATION
	speed = -speed * REVERT_SPEED_RETAINED
	velocity.x *= REVERT_SPEED_RETAINED
	velocity.z *= REVERT_SPEED_RETAINED


func _tick_manual_balance(delta: float, push_input: float, brake_input: float) -> bool:
	_manual_elapsed += delta
	var outward := 1.0 if manual_balance >= 0.0 else -1.0
	var drift := outward * (0.18 + 0.08 * _manual_elapsed)
	manual_balance += (drift + (brake_input - push_input) * MANUAL_BALANCE_CONTROL) * delta
	if absf(manual_balance) >= 1.0:
		_start_bail()
		_manual_cooldown = MANUAL_REENTRY_DELAY
		return false
	return true


func _end_manual(grounded_exit: bool) -> void:
	if not manual_active:
		return
	manual_active = false
	_manual_latched = false
	_manual_gesture_pending = ""
	manual_balance = 0.0
	_manual_elapsed = 0.0
	_manual_cooldown = MANUAL_REENTRY_DELAY
	if grounded_exit:
		combo_link_ended.emit()


func _try_grind(from_transition: bool = false) -> bool:
	if _grind_cooldown > 0.0 or not Input.is_action_pressed("grind"):
		return false
	if _flip_remaining > 0.0 and 1.0 - _flip_remaining / _flip_duration < FLIP_LANDING_TOLERANCE:
		return false
	if _special_remaining > 0.0 and _special_remaining <= 0.15: _complete_special()
	if not _spin_landing_clean() or _special_remaining > 0.15:
		return false
	var clearance: Callable = _transition.grind_path_clear.bind(self) if from_transition else _rail_path_clear
	if not _grind.start(_grind_lines, global_position, velocity, clearance):
		return false
	if from_transition: _transition.reset(self)
	_complete_flip()
	_award_air_spin()
	_rail_backwards = velocity.dot(-global_basis.z) < 0.0
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
	speed = -_grind.speed if _rail_backwards else _grind.speed
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
		rotation.y = atan2(-velocity.x, -velocity.z) + (PI if _rail_backwards else 0.0)


func _tick_grind(delta: float) -> void:
	if not _controls_enabled:
		return
	_discard_cached_support()
	_steering = Input.get_axis("steer_left", "steer_right")
	if _trick_entries_enabled and _ollie_released:
		_release_grind(true)
		return
	if not Input.is_action_pressed("grind"):
		_release_grind(false)
		return
	if _trick_entries_enabled and _style_cooldown <= 0.0:
		var pivot_action: Dictionary = _trick_input.pop_action("revert")
		if not pivot_action.is_empty():
			_physical_revert()
			_rail_backwards = not _rail_backwards
			_grind.speed *= REVERT_SPEED_RETAINED
			_style_cooldown = 0.35
			_emit_trick("grind_pivot")
		var action: Dictionary = _trick_input.pop_action("flip")
		if action.is_empty(): action = _trick_input.pop_action("grab")
		if not action.is_empty():
			var choice := TrickCatalog.resolve("grind", str(action.direction))
			if str(choice.id) != grind_trick_id:
				_grind_definition = choice
				grind_trick_id = str(choice.id)
				_style_cooldown = 0.25
				_emit_trick(grind_trick_id)
	# Short collision sweeps follow bends instead of cutting through scenery.
	var steps := maxi(1, ceili(delta * maxf(_grind.speed, 1.0) / 0.20))
	for i in steps:
		var result: String = _grind.step(delta / steps, _steering)
		var target: Vector3 = _grind.position()
		if result == "bail" or not _rail_path_clear(global_position, target):
			_start_bail()
			_grind_cooldown = GRIND_RECAPTURE_DELAY
			return
		global_position = target
		velocity = _grind.travel_velocity()
		speed = -_grind.speed if _rail_backwards else _grind.speed
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
	if not jump: _launch_id = "ollie"
	_begin_air()
	speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)
	if jump:
		_set_launch_mode()
		velocity += global_basis.x * _steering * 4.0
		velocity.y = maxf(0.0, velocity.y) + _launch_impulse
		_jump_buffer_remaining = 0.0
		combo_link_started.emit()
		_emit_trick(_launch_id)


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
	var was_special := _special_remaining > 0.0
	_special_remaining = maxf(0.0, _special_remaining - delta)
	if was_special and _special_remaining <= 0.0:
		_complete_special()
	if not airborne:
		_spin_angle = lerp_angle(_spin_angle, 0.0, 1.0 - exp(-18.0 * delta))
	_visual.rotation.y = _spin_angle - PI * (_revert_pose_remaining / REVERT_DURATION)
	_visual.rotation.z = lerpf(_visual.rotation.z, -_steering * 0.11 * (speed / MAX_SPEED), 1.0 - exp(-10.0 * delta))
	var flip_progress := clampf(1.0 - _flip_remaining / _flip_duration, 0.0, 1.0)
	var flip_curve := smoothstep(0.04, 0.88, flip_progress)
	var flip_angles := _flip_pose_angles()
	var manual_sign := _manual_base_sign
	var deck_direction := cos(_deck_yaw)
	var board_pitch := deck_direction * manual_sign * (deg_to_rad(16.0) + manual_balance * 0.12) if manual_active else 0.0
	var manual_definition := TrickCatalog.definition(manual_trick_id)
	if manual_active and bool(manual_definition.get("manual_pogo", false)):
		board_pitch = deck_direction * (1.22 + manual_balance * 0.035)
	elif manual_active and bool(manual_definition.get("manual_casper", false)):
		board_pitch = deck_direction * (0.35 + manual_balance * 0.035)
	if airborne and _launch_age < 0.18 and _launch_id == "nollie" and _flip_remaining <= 0.0:
		board_pitch = -deck_direction * 0.22 * sin(PI * _launch_age / 0.18)
	var board_roll := float(manual_definition.get("manual_roll", 0.0)) * sin(_manual_elapsed * 6.0) if manual_active else 0.0
	if manual_active and bool(manual_definition.get("manual_casper", false)):
		board_roll = deck_direction * PI
	var board_yaw := _deck_yaw
	if lip_active:
		board_yaw = float(_lip_definition.get("lip_yaw", 0.0))
		board_pitch = float(_lip_definition.get("lip_pitch", 0.0))
		board_roll = float(_lip_definition.get("lip_roll", 0.0))
	elif grinding:
		board_yaw = float(_grind_definition.get("grind_yaw", 0.0))
		board_pitch = float(_grind_definition.get("grind_pitch", 0.0))
	elif _flip_remaining > 0.0:
		board_roll = deck_direction * flip_angles.x
		board_yaw += flip_angles.y
		board_pitch = deck_direction * flip_angles.z
	elif _grab_remaining > 0.0:
		board_roll = deck_direction * float(_grab_definition.get("board_roll", 0.0))
		board_pitch = deck_direction * float(_grab_definition.get("board_pitch", 0.0))
		board_yaw += float(_grab_definition.get("board_yaw", 0.0))
	_board_visual.rotation.z = board_roll if _flip_remaining > 0.0 or lip_active else lerpf(_board_visual.rotation.z, board_roll, 1.0 - exp(-16.0 * delta))
	_board_visual.rotation.x = board_pitch if _flip_remaining > 0.0 else lerpf(_board_visual.rotation.x, board_pitch, 1.0 - exp(-16.0 * delta))
	var special_progress := 1.0 - _special_remaining / maxf(_special_duration, 0.001)
	_board_visual.rotation.y = board_yaw
	if _special_remaining > 0.0:
		_board_visual.rotation.x += _special_axis(float(_special_definition.get("special_board_pitch", 0.0)), special_progress)
		_board_visual.rotation.y += _special_axis(float(_special_definition.get("special_board_yaw", 0.0)), special_progress)
		_board_visual.rotation.z += _special_axis(float(_special_definition.get("special_board_roll", 0.0)), special_progress)
	var grab_pose := 1.0 if _grab_remaining > 0.0 else 0.0
	var special_tuck := float(_special_definition.get("special_tuck", 0.0)) * sin(PI * special_progress)
	_rider_visual.position.y = lerpf(_rider_visual.position.y, -0.17 * grab_pose - special_tuck, 1.0 - exp(-16.0 * delta))
	var rider_pitch := manual_sign * (-0.18 - manual_balance * 0.12) if manual_active else -0.1 - grab_pose * 0.2
	_rider_visual.rotation.x = lerpf(_rider_visual.rotation.x, rider_pitch, 1.0 - exp(-16.0 * delta))
	if grinding:
		_visual.rotation.z = -grind_balance * 0.35
		_rider_visual.position.y = -0.12
	elif manual_active:
		_rider_visual.position.y = -0.10
	# Lean the visible board into slopes without pitching the upright collision.
	var desired_pitch := 0.0
	if grinding:
		desired_pitch = atan2(velocity.y, Vector2(velocity.x, velocity.z).length())
	elif lip_active:
		desired_pitch = 0.0
	elif transition_active:
		var support: Vector3 = global_basis.inverse() * _transition.normal
		desired_pitch = atan2(support.z, support.y)
	elif _native_floor_valid and is_on_floor():
		var local_normal := global_basis.inverse() * _native_floor_normal()
		desired_pitch = atan2(local_normal.z, local_normal.y)
	var curved_support: bool = transition_active and _transition.state == "surface"
	var native_support := _native_floor_valid and not transition_active and is_on_floor() and not grinding and not wallriding \
		and (bail_active or (not airborne and not _force_air_tick))
	if curved_support or native_support:
		# Keep the visible wheels in the real support frame. Pitch-only lag made
		# neutral bowl carving and ordinary cross-slopes penetrate on one side
		# and float on the other despite correct native capsule contact.
		var contact_normal: Vector3 = (global_basis.inverse() * (_native_floor_normal() if native_support else _transition.normal)).normalized()
		if Vector2(contact_normal.y, contact_normal.z).length_squared() > 0.00000001:
			_surface_pitch = atan2(contact_normal.z, contact_normal.y)
		var contact_roll := -asin(clampf(contact_normal.x, -1.0, 1.0))
		var support_basis := Basis.from_euler(Vector3(_surface_pitch, 0.0, contact_roll))
		_air_support_basis = support_basis
		_visual.basis = support_basis * Basis(Vector3.UP, _spin_angle - PI * (_revert_pose_remaining / REVERT_DURATION))
	else:
		_surface_pitch = lerpf(_surface_pitch, desired_pitch, 1.0 - exp(-14.0 * delta))
		_visual.rotation.x = _surface_pitch
	var air_visual_offset := Vector3.ZERO
	if airborne and not grinding and not wallriding and not bail_active:
		# Read the finite native surface below the flight. Anticipating that
		# frame preserves a continuous catch; rotating the entire figure only
		# after contact caused metre-long head jumps on bowl returns.
		var prediction := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.2,
			global_position - Vector3.UP * 3.0, collision_mask)
		prediction.exclude = [get_rid()]
		var upcoming := get_world_3d().direct_space_state.intersect_ray(prediction)
		var upcoming_normal: Vector3 = _transition.normal if transition_active else Vector3.UP
		var has_upcoming := not upcoming.is_empty() and Vector3(upcoming.normal).y > 0.05
		if has_upcoming: upcoming_normal = upcoming.normal
		var local_up := global_basis.inverse() * upcoming_normal
		var pitch := atan2(local_up.z, local_up.y)
		var target_basis := Basis.from_euler(Vector3(pitch, 0, -asin(clampf(local_up.x, -1, 1))))
		if has_upcoming and not transition_active:
			var distance_to_plane := (global_position - Vector3(upcoming.position)).dot(upcoming_normal)
			var anticipation := 1.0 - smoothstep(0.22, 1.2, distance_to_plane)
			var capsule := (get_node("BodyCollision") as CollisionShape3D).shape as CapsuleShape3D
			var foot_offset := maxf(0, capsule.radius * (1.0 - upcoming_normal.y) - 0.008)
			air_visual_offset = -upcoming_normal * foot_offset * anticipation
		var angle := _air_support_basis.get_rotation_quaternion().angle_to(target_basis.get_rotation_quaternion())
		_air_support_basis = _air_support_basis.slerp(target_basis, minf(1, 4.5 * delta / maxf(angle, 0.000001))).orthonormalized()
		_visual.basis = _air_support_basis * Basis(Vector3.UP, _spin_angle - PI * (_revert_pose_remaining / REVERT_DURATION))
	if wallriding:
		_visual.rotation.z = clampf(-(global_basis.inverse() * _wall.normal).x * 0.65, -0.65, 0.65)
	if not (curved_support or native_support) and (not airborne or wallriding) and not bail_active:
		_air_support_basis = (_visual.basis * Basis(Vector3.UP, -_spin_angle + PI * (_revert_pose_remaining / REVERT_DURATION))).orthonormalized()
	_visual.position = global_basis.inverse() * air_visual_offset
	if native_support:
		# An upright capsule's rounded end lifts its origin on steep floors.
		# Place only the presentation at the actual native support plane before
		# solving planted feet and palms; never move the physical player for it.
		var support_normal := _native_floor_normal()
		var support_query := PhysicsRayQueryParameters3D.create(global_position + support_normal * 0.35,
			global_position - support_normal * 0.6, collision_mask)
		support_query.exclude = [get_rid()]
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(support_query)
		if not floor_hit.is_empty() and Vector3(floor_hit.normal).dot(support_normal) > 0.98:
			_visual.position = global_basis.inverse() * (Vector3(floor_hit.position) + support_normal * 0.008 - global_position)
	if _special_remaining > 0.0:
		_visual.rotation.x += _special_axis(float(_special_definition.get("special_body_pitch", 0.0)), special_progress)
		_visual.rotation.y += _special_axis(float(_special_definition.get("special_body_yaw", 0.0)), special_progress)
		_visual.rotation.z += _special_axis(float(_special_definition.get("special_body_roll", 0.0)), special_progress)
		# Rotate the visible rider/board around the body, preserving the collision origin.
		var tumble_pivot := Vector3.UP * 0.8
		_visual.position = tumble_pivot - _visual.basis * tumble_pivot
	_visual_rig.animate(delta, {"airborne": airborne, "grab": _grab_remaining > 0.0,
		"flip": _flip_remaining > 0.0, "speed": absf(speed), "travel_sign": signf(speed), "manual": manual_active,
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
		"rest_deck_yaw": _deck_yaw, "takeoff_mode": takeoff_mode, "launch_id": _launch_id, "launch_age": _launch_age, "crouching": crouching, "ollie_charge": ollie_charge,
		"powersliding": powersliding, "wallriding": wallriding, "wall_normal": _wall.normal,
		"transition_active": transition_active, "lip_active": lip_active,
		"manual_walk": TrickCatalog.definition(manual_trick_id).get("manual_walk", false),
		"manual_roll": TrickCatalog.definition(manual_trick_id).get("manual_roll", 0.0),
		"manual_foot_lift": TrickCatalog.definition(manual_trick_id).get("manual_foot_lift", 0.0),
		"manual_definition": TrickCatalog.definition(manual_trick_id), "grab_definition": _grab_definition,
		"special_definition": _special_definition, "lip_definition": _lip_definition,
		"lip_ground_point": _transition.lip_frame().get("point", global_position) if lip_active else global_position,
		"lip_normal": Vector3.UP, "setup_active": setup_active, "setup_id": setup_id,
		"setup_phase": setup_phase, "setup_ground_point": _setup.ground_point, "setup_normal": _setup.normal,
		"bail_active": bail_active, "bail_phase": bail_phase, "bail_ground_point": _bail.ground_point,
		"skitching": skitch_caught, "skitch_caught": skitch_caught,
		"skitch_grips": _skitch.hand_targets() if skitching and _skitch.has_method("hand_targets") else [],
		"skitch_normal": _skitch.hand_normal() if skitching and _skitch.has_method("hand_normal") else Vector3.ZERO,
		"bail_normal": _bail.normal,
		"bail_recovery_transform": Transform3D(Basis(Vector3.UP, -PI / 2.0 + 0.28), Vector3.ZERO)})

	if wallriding: _place_wall_wheels()


func _place_wall_wheels() -> void:
	# Derive contact from the actual banked wheel cylinders and probed wall plane,
	# including any caught deck yaw/pitch. Only presentation moves; native capsule
	# adhesion, finite wall eligibility and physical momentum remain authoritative.
	var gap := INF
	for child: Node in _board_visual.get_children():
		if not child is MeshInstance3D or not child.mesh is CylinderMesh:
			continue
		var cylinder: CylinderMesh = child.mesh
		if not is_equal_approx(cylinder.top_radius, 0.032) or not is_equal_approx(cylinder.height, 0.032): continue
		var axis: Vector3 = child.global_basis.y.normalized()
		var along := clampf(absf(axis.dot(_wall.normal)), 0.0, 1.0)
		var extent := cylinder.height * 0.5 * along + cylinder.top_radius * sqrt(maxf(0.0, 1.0 - along * along))
		gap = minf(gap, (child.global_position - _wall.contact_point).dot(_wall.normal) - extent)
	if is_finite(gap):
		_visual.position -= (global_basis.inverse() * _wall.normal) * (gap - 0.015)


func _process(delta: float) -> void:
	_recovery_fade_remaining = maxf(0.0, _recovery_fade_remaining - delta)
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
