extends CharacterBody3D
## Forgiving arcade controller. Origin is at the ground beneath the skateboard.
## Travel momentum and visible trick rotation are separate; directional input
## selects original trick families and finite authored transitions own wall contact.

signal trick_performed(trick_name: String, points: int)
signal grind_captured(rail_id: String)
signal landed(clean: bool)
signal bailed()
signal recovered()
signal combo_link_started()
signal combo_link_ended()

const GrindIndex = preload("res://game/tricks/grind_index.gd")
const GrindRideSource = preload("res://game/tricks/grind_ride.gd")
const GrindStyle = preload("res://game/tricks/grind_style.gd")
const GrindClearance = preload("res://game/tricks/grind_clearance.gd")
var _grind_clearance=GrindClearance.new()
const GrindTransfer=preload("res://game/tricks/grind_transfer.gd")
var _grind_transfer=GrindTransfer.new()
var _grind_pending:Dictionary={}
var _grind_exact_pose:=false
const GRIND_BOARD_SIZE := Vector3(.28,.166864,.835)
const GRIND_BOARD_CENTER := Vector3(0,-.036568,0)
# Farthest declared model-box corner from its model origin: <.457m.
const GRIND_BOARD_CORNER_RADIUS := .457
const GRIND_SUPPORT_META: Array[StringName]=[&"authored_grind_ids",&"grind_surface_ids",&"audit_capture_ids"]
const GRIND_SUPPORT_SIDES: Array[float]=[0.0,-0.005,0.005]
const TrickCatalog = preload("res://game/tricks/trick_catalog.gd")
const SkaterVisualSource = preload("res://game/player/skater_visual.gd")
const ObstacleArmFit = preload("res://game/player/skater_obstacle_arm_fit.gd")
const SkateResponse = preload("res://game/player/skate_response.gd")
const DirectionalTricks = preload("res://game/tricks/directional_tricks.gd")
const TrickAnimation = preload("res://game/player/trick_animation.gd")
const TransitionRide = preload("res://game/player/transition_ride.gd")
const ChaseCamera = preload("res://game/player/chase_camera.gd")
const GRIND_RECAPTURE_DELAY := 0.35

const MAX_SPEED := 15.0
const PUSH_ACCELERATION := 10.0
const BRAKE_DECELERATION := 22.0
const ROLLING_DRAG := 0.75
const GRAVITY := 34.0 # Short weighted free flight; finite transition contact uses its own gravity.
const WEIGHTED_OLLIE_GRAVITY := 24.0
# sqrt(24 / 34): retain the authored flat jump height with a less rushed arc.
const WEIGHTED_OLLIE_IMPULSE_SCALE := 0.8401680504168059
const RAMP_AIR_GRAVITY := 22.0 # Preserve launch momentum; give ramp tricks more rise and airtime.
const GROUND_GRAVITY := 22.0
const OLLIE_SPEED := 7.2
const CHARGED_OLLIE_SPEED := 9.0
const RAMP_OLLIE_SPEED := 8.0
const CHARGED_RAMP_OLLIE_SPEED := 13.0
const OLLIE_POSE_SECONDS := 0.28
const OLLIE_CHARGE_SECONDS := 0.25
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.12
const TRICK_BUFFER_TIME := 0.12
const SPIN_SPEED := 7.2
const FLIP_DURATION := 0.32
const MANUAL_MIN_SPEED := 2.0
const MANUAL_REENTRY_DELAY := 0.35
const MANUAL_BALANCE_CONTROL := 1.5
const REVERT_DURATION := 0.18
const REVERT_SPEED_RETAINED := 0.85
const SPECIAL_DURATION := 0.65
const WORLD_LIMIT := 400.0

# Recovery uses real native collision; only explicit hazards/blocked support relocate.
var bailing := false
var bail_phase := ""
var bail_reason := ""
var bail_elapsed := 0.0
var _bail_phase_elapsed := 0.0
var _bail_visual_basis:=Basis.IDENTITY
var _bail_visual_offset:=Vector3.ZERO
var _bail_fallback_used := false
var _last_supported_position := Vector3.ZERO
var _recovery_shape_query := PhysicsShapeQueryParameters3D.new()
var _recovery_floor_query := PhysicsRayQueryParameters3D.new()
var speed: float = 0.0
var airborne: bool = false
var spawn_position: Vector3 = Vector3(0.0, 0.8, 12.0)
var manual_active := false
var manual_balance := 0.0
var revert_remaining := 0.0
var special_name := ""

var active_flip_id := "kickflip"
var active_grab_id := "melon_grab"
var manual_id := "manual"
var lip_id := ""
var lip_active := false
var lip_balance := 0.0
var transition_normal := Vector3.UP
var transition_active: bool:
	get: return _transition.active or _feature_transition.active
var _transition = TransitionRide.new()
var _transition_features: Array = []
var _transition_cooldown := 0.0
var _transition_facing := 1.0
var _ramp_air := false
var _ramp_air_sequence := 0
var last_physics_frame := -1
var last_presentation_process_frame := -1
var _ramp_air_frame := Basis.IDENTITY
var _previous_ramp_air_frame := Basis.IDENTITY
var _loose_board: RigidBody3D
var _board_model: Node3D

var _ramp_air_normal := Vector3.UP
var _ramp_launch_forward := Vector3.FORWARD
var _vert_return: Dictionary = {}
var _vert_start_yaw := 0.0
var _vert_start_up := 0.0
var _grind_visual_offset := Vector3.ZERO
var _obstacle_visual_offset := Vector3.ZERO
var _obstacle_ollie_continuation := false
var _obstacle_manual_continuation := false
var _obstacle_shoe_bounds: Array[AABB] = []
var _lip_feature: Dictionary = {}
var _lip_across := 0.0
var _lip_elapsed := 0.0
var _lip_entry_speed := 0.0
var _body_collision: CollisionShape3D
var _ollie_held := false
var _crouch_charge := 0.0
var _pop_impulse := OLLIE_SPEED
var _ramp_pop_impulse := RAMP_OLLIE_SPEED
var _ollie_pose_remaining := 0.0
var _flip_request: Dictionary = {}
var _grab_request: Dictionary = {}
var _manual_request: Dictionary = {}
var _grind_buffer_remaining := 0.0
var _grind_held_armed := false
var _grind_direction := Vector2.ZERO
var _selection_remaining := 0.0
var _vertical_edge := 0
var _vertical_edge_age := 1.0
var _last_vertical := 0
var _manual_gesture_hold := false
var _vertical_neutral_seen := false

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
var _grind_index = GrindIndex.new()
var _grind_cooldown := 0.0
var grind_style_id := ""
var _grind_style_yaw := 0.0
var _air_grind_yaw := 0.0
var _grind_contact := GrindStyle.ContactPose.new()
var _grind_candidate_contact := GrindStyle.ContactPose.new()
var _grind_board_forward := Vector3.FORWARD
var _grind_choices: Dictionary = {}
var _grind_entry_action:Dictionary={}
var _grind_grip_age:=0.0
var _grind_held_exit:=false
var _grind_board_box := BoxShape3D.new()
var _grind_board_query := PhysicsShapeQueryParameters3D.new()
var _grind_support_ray := PhysicsRayQueryParameters3D.new()
var _grind_capsule_rest := KinematicCollision3D.new()
var _grind_rail_intent_remaining := 0.0
var _grind_rail_intent_velocity := Vector3.ZERO
var _grind_rail_intent_position := Vector3.ZERO
var _grind_rail_intent_rid := RID()
var _grind_rail_intent_ids: Array[String]=[]
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
var _flip_buffer_remaining := 0.0
var _grab_buffer_remaining := 0.0
var _manual_buffer_remaining := 0.0
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
var _visual_rig: RefCounted
var _obstacle_arm_fit: RefCounted = ObstacleArmFit.new()
var _response = SkateResponse.new()
var _camera_follow = ChaseCamera.new()


signal hold_points_awarded(points: int)
signal special_requested(trick_id: String)
signal trick_upgraded(trick_name: String, points: int, trick_id: String)

const TrickInput = preload("res://game/tricks/trick_input.gd")
const WallRideSource = preload("res://game/player/wall_ride.gd")
const LaunchSetupSource = preload("res://game/player/launch_setup.gd")
const SkitchRideSource = preload("res://game/player/skitch_ride.gd")
const FLIP_CATCH_COOLDOWN := 0.06
const FLIP_LANDING_TOLERANCE := 0.80
const MANUAL_BUFFER_SECONDS := 0.18
const GRAB_MINIMUM_SECONDS := 0.20
const HOLD_INTERVAL := 0.25
const HOLD_AWARD := 25
const HOLD_LIMIT := 300

var last_trick_id := ""
var flip_trick_id := ""
var grab_trick_id := ""
var grind_trick_id := ""
var manual_trick_id := "manual"
var ollie_charge := 0.0
var crouching := false
var powersliding := false
var takeoff_mode := "Regular"
var _ollie_was_held := false
var _ollie_blocked_until_release := false
var _ollie_released := false
var _launch_impulse := OLLIE_SPEED
var _launch_base_impulse := OLLIE_SPEED
var _launch_id := "ollie"
var _launch_age := 0.0
var _weighted_ollie_air := false
var _weighted_ollie_duration := 0.0
var _switch_stance := false
var _rail_backwards := false
var _style_cooldown := 0.0
var _manual_latched := false
var _manual_base_sign := 1.0
var _manual_gesture_pending := ""
var _force_air_tick := false
var _wall = WallRideSource.new()
var wallriding: bool:
	get: return _wall.active
var _setup = LaunchSetupSource.new()
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
		if bail_active: return "Getting back up" if bail_progress > 0.55 else "Bail"
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
var _grind_hold_age:=0.0
var _grind_hold_tick := 0
var _grind_hold_points := 0
var _buffered_manual_id := "manual"

var _air_support_basis := Basis.IDENTITY
const PLANAR_RIM_MAX_LIFT := 0.025
const GROUND_PRESENTATION_SKIN := 0.008
var _floor_wheel_shapes: Array[ConvexPolygonShape3D] = []
var _floor_wheel_query := PhysicsShapeQueryParameters3D.new()
var _board_floor_ray := PhysicsRayQueryParameters3D.create(Vector3.ZERO,Vector3.ZERO,1|8)
const FeatureTransitionRide = preload("res://game/player/feature_transition_ride.gd")
var _feature_transition = FeatureTransitionRide.new()
var bail_progress: float:
	get: return clampf(bail_elapsed/1.2,0.0,1.0)

var bail_active: bool:
	get: return bailing
var recovery_fade: float:
	get: return clampf(_recovery_fade_remaining/.18,0.0,1.0)


func _ready() -> void:
	# Movement/poses remain fixed-tick physics. Only their presentation is
	# interpolated; the independently updated chase camera opts out below.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	floor_max_angle = deg_to_rad(56.0)
	floor_snap_length = 0.45
	floor_constant_speed = true
	floor_stop_on_slope = true
	safe_margin = 0.015
	collision_layer = 2
	collision_mask = 1 | 8
	_build_skater()
	var grind_capsule:=_body_collision.shape as CapsuleShape3D
	_grind.body_radius=grind_capsule.radius
	_grind.body_base_offset=_body_collision.position.y-grind_capsule.height*0.5
	_grind.body_clearance=safe_margin
	_grind_support_ray.collision_mask=1|2|8
	_grind_support_ray.exclude=[get_rid()]
	_grind_support_ray.collide_with_areas=false
	# Cache each authored shoe envelope once; the air continuation reuses the
	# existing board query/box and never scans rendered meshes per frame.
	for leg: Dictionary in _visual_rig._legs:
		var bounds := AABB()
		var first := true
		for child: Node in leg.foot.get_children():
			if not child is MeshInstance3D or child.mesh == null: continue
			var local: AABB = child.transform * child.mesh.get_aabb()
			bounds = local if first else bounds.merge(local)
			first = false
		_obstacle_shoe_bounds.append(bounds)
	# Prepare exact displayed-wheel landmarks at construction, before first play.
	_camera_follow.prepare_board_landmarks(_visual_rig)
	_grind_clearance.rebuild(_board_visual,_visual_rig.board_contact_geometry(),get_rid())
	# Startup-only exact tyre hulls; native finite-volume checks must not scan
	# thousands of GLB vertices during ordinary skating.
	for wheel: Dictionary in _visual_rig.board_contact_geometry().wheels:
		var shape := ConvexPolygonShape3D.new()
		shape.margin = 0.0
		shape.points = wheel.points
		_floor_wheel_shapes.append(shape)
	_floor_wheel_query.collision_mask = collision_mask
	_floor_wheel_query.collide_with_areas = false
	_floor_wheel_query.exclude = [get_rid()]
	# Original board's declared model bounds, reused for native world clearance.
	_grind_board_box.size = GRIND_BOARD_SIZE
	_grind_board_query.shape = _grind_board_box
	_grind_board_query.collision_mask = 1 | 8
	_grind_board_query.margin = .001
	_grind_board_query.exclude = [get_rid()]
	_recovery_shape_query.shape = _body_collision.shape
	_recovery_shape_query.collision_mask = 1 | 8
	_recovery_shape_query.margin = .001
	_recovery_shape_query.exclude = [get_rid()]
	_recovery_floor_query.collision_mask = 1 | 8
	_recovery_floor_query.exclude = [get_rid()]
	_obstacle_arm_fit.prepare(self)
	_camera = Camera3D.new()
	_camera.name = "ChaseCamera"
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_camera)
	_camera.top_level = true
	_camera.current = true
	_camera.fov = 68.0
	_camera.near = 0.20 # More depth precision; native ramp camera may shorten to a clear1.6m arm.
	_camera.far = 220.0
	reset_skater()
	_native_floor_valid=false


func reset_skater(preserve_camera:bool=false,preserve_support:bool=false) -> void:
	_clear_grind_rail_intent()
	_clear_weighted_ollie()
	_obstacle_arm_fit.reset()
	_grind_transfer.reset()
	_grind_pending.clear()
	_grind_exact_pose=false
	last_trick_id = ""
	flip_trick_id = ""
	grab_trick_id = ""
	grind_trick_id = ""
	manual_trick_id = "manual"
	ollie_charge = 0.0
	crouching = false
	powersliding = false
	takeoff_mode = "Regular"
	_ollie_was_held = false
	_ollie_blocked_until_release = false
	_ollie_released = false
	_launch_impulse = OLLIE_SPEED
	_launch_base_impulse = OLLIE_SPEED
	_launch_id = "ollie"
	_launch_age = 0.0
	_switch_stance = false
	_rail_backwards = false
	_style_cooldown = 0.0
	_manual_latched = false
	_manual_base_sign = 1.0
	_manual_gesture_pending = ""
	_force_air_tick = false
	_setup_impulse = OLLIE_SPEED
	_recovery_fade_remaining = 0.0
	_flip_motion_origin = Vector3.ZERO
	_grab_tweaked = false
	lip_trick_id = "lip_stall"
	_lip_definition = {}
	_special_definition = {}
	_special_duration = SPECIAL_DURATION
	_transition_backwards = false
	_skitch_scored = false
	_flip_definition = {}
	_grab_definition = {}
	_grind_definition = {}
	_pending_grab = {}
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
	_buffered_manual_id = "manual"
	_air_support_basis = Basis.IDENTITY
	_setup.reset()
	_feature_transition.reset(self)
	_wall.stop()
	_skitch.reset()
	_trick_input.reset()
	_pending_grab.clear()
	_flip_definition.clear()
	_grab_definition.clear()
	_grind_definition.clear()
	_lip_definition.clear()
	_native_floor_valid=preserve_support and is_on_floor()
	if not preserve_support: _discard_cached_support()
	bailing = false
	bail_phase = ""
	bail_reason = ""
	bail_elapsed = 0.0
	_bail_phase_elapsed = 0.0
	_bail_fallback_used = false
	_last_supported_position = spawn_position
	_response.reset()
	if not preserve_camera: _camera_follow.reset()
	_grind.stop()
	_clear_grind_style()
	_air_grind_yaw = 0.0
	_transition.stop()
	_vert_return.clear()
	_grind_visual_offset = Vector3.ZERO
	_obstacle_visual_offset = Vector3.ZERO
	_obstacle_ollie_continuation = false
	_obstacle_manual_continuation = false
	transition_normal = Vector3.UP
	_transition_cooldown = 0.0
	lip_active = false
	lip_id = ""
	lip_balance = 0.0
	_lip_feature.clear()
	_lip_elapsed = 0.0
	_ollie_held = false
	_crouch_charge = 0.0
	_grind_buffer_remaining = 0.0
	_grind_held_armed = false
	_selection_remaining = 0.0
	_vertical_edge = 0
	_vertical_edge_age = 1.0
	_last_vertical = 0
	_vertical_neutral_seen = false
	_manual_gesture_hold = false
	active_flip_id = "kickflip"
	active_grab_id = "melon_grab"
	manual_id = "manual"
	_restore_contact_shape()
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
	basis = Basis.IDENTITY
	_ramp_air_frame = global_basis
	_previous_ramp_air_frame = _ramp_air_frame
	_ramp_air_normal = Vector3.UP
	_ramp_launch_forward = -global_basis.z
	velocity = Vector3.ZERO
	speed = 0.0
	airborne = false
	_ramp_air = false
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0
	_clear_trick_buffers()
	_flip_used = false
	_grab_used = false
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_ollie_pose_remaining = 0.0
	_spin_angle = 0.0
	_air_spin = 0.0
	_steering = 0.0
	if is_instance_valid(_visual):
		_mount_board()
		_visual.position = Vector3.ZERO
		_visual.basis = Basis.IDENTITY
		_board_visual.basis = Basis.IDENTITY
		_rider_visual.position = Vector3.ZERO
		_rider_visual.basis = Basis(Vector3.UP,-PI / 2.0 + 0.28)
		_visual_rig.reset()
	if is_instance_valid(_camera) and not preserve_camera:
		_camera.global_position = global_position + Vector3(0.0, 3.4, 6.0)
		_camera.look_at(global_position + Vector3(0.0, 1.0, -1.5))
	# Prime native interpolation pumps before resetting them, including the
	# support axis used by the per-render camera. Descendant poses reset too.
	get_global_transform_interpolated()
	if is_instance_valid(_body_collision): _body_collision.get_global_transform_interpolated()
	reset_physics_interpolation()
	if InputMap.has_action("ollie"): _trick_input.synchronize_held()


func recover_to(safe_position: Vector3) -> void:
	# Repeated hazard polls coalesce into one failure and preserve run restart.
	if safe_position.is_finite():begin_bail("hazard", safe_position)


func begin_bail(reason: String, safe_position: Vector3 = Vector3.INF) -> void:
	_clear_grind_rail_intent()
	_clear_weighted_ollie()
	_grind_transfer.reset()
	_grind_pending.clear()
	_grind_exact_pose=false
	if bailing:return
	_obstacle_arm_fit.reset()
	_setup.reset()
	_feature_transition.reset(self)
	_wall.stop()
	_skitch.stop()
	_trick_input.clear_actions()
	_discard_cached_support()
	if _visual_rig.has_method("begin_bail"): _visual_rig.begin_bail()
	_obstacle_visual_offset = Vector3.ZERO
	_obstacle_ollie_continuation = false
	_obstacle_manual_continuation = false
	# Retain only body-local interrupted presentation; native motion stays authoritative.
	_bail_visual_basis=_visual.basis.orthonormalized()
	_bail_visual_offset=_visual.position
	bailing = true
	bail_phase = "fall"
	bail_reason = reason
	bail_elapsed = 0.0
	_bail_phase_elapsed = 0.0
	_bail_fallback_used = false
	_grind.stop()
	_clear_grind_style()
	_air_grind_yaw = 0.0
	_transition.stop()
	_vert_return.clear()
	manual_active = false
	lip_active = false
	lip_id = ""
	_lip_feature.clear()
	_ramp_air = false
	transition_normal = Vector3.UP
	_ollie_held = false
	_crouch_charge = 0.0
	_jump_buffer_remaining = 0.0
	_grind_buffer_remaining = 0.0
	_grind_held_armed = false
	_clear_trick_buffers()
	_clear_special_visual()
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_ollie_pose_remaining = 0.0
	_air_spin = 0.0
	_steering = 0.0
	_selection_remaining = 0.0
	revert_remaining = 0.0
	_revert_pose_remaining = 0.0
	_flip_request.clear();_grab_request.clear();_manual_request.clear()
	if not velocity.is_finite():velocity = Vector3.ZERO
	# Score/encounters fail once, at the real impact location, before relocation.
	bailed.emit()
	if safe_position.is_finite():
		_relocate_recovery(safe_position)
	_restore_contact_shape()
	_drop_board()


func _recovery_volume_clear(at: Vector3) -> bool:
	if not at.is_finite() or absf(at.x)>WORLD_LIMIT or absf(at.z)>WORLD_LIMIT or at.y< -8.0:return false
	# Conservative upward skin clears floor contact without accepting a ceiling.
	_recovery_shape_query.transform = Transform3D(global_basis, at + Vector3.UP * .875)
	return get_world_3d().direct_space_state.intersect_shape(_recovery_shape_query, 1).is_empty()


func _relocate_recovery(preferred: Vector3) -> bool:
	for at: Vector3 in [preferred, _last_supported_position, spawn_position]:
		if not _recovery_volume_clear(at):continue
		_recovery_floor_query.from = at + Vector3.UP * .2
		_recovery_floor_query.to = at + Vector3.DOWN * 1.2
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(_recovery_floor_query)
		if floor_hit.is_empty() or floor_hit.normal.y < cos(floor_max_angle):continue
		global_position = at
		velocity = Vector3.ZERO
		speed = 0.0
		_bail_fallback_used = true
		reset_physics_interpolation()
		_camera_follow.reset()
		return true
	return false


func _tick_bail(delta: float) -> void:
	bail_elapsed += delta
	_bail_phase_elapsed += delta
	velocity.y -= GRAVITY * delta
	var drag := exp(-(6.0 if is_on_floor() else .4) * delta)
	velocity.x *= drag
	velocity.z *= drag
	move_and_slide()
	_restore_platform_after_move()
	airborne = not is_on_floor()
	speed = Vector2(velocity.x, velocity.z).length()
	if (bail_elapsed > 4.0 or global_position.y < -8.0 or absf(global_position.x) > WORLD_LIMIT or absf(global_position.z) > WORLD_LIMIT) and not _bail_fallback_used:
		_bail_fallback_used = true
		if _relocate_recovery(Vector3.INF):
			bail_phase = "fall";_bail_phase_elapsed = 0.0
		else:
			bail_phase = "blocked"
	if bail_phase == "fall" and _bail_phase_elapsed >= .28 and is_on_floor():
		bail_phase = "slide";_bail_phase_elapsed = 0.0
	elif bail_phase in ["slide", "blocked"] and _bail_phase_elapsed >= .15 and is_on_floor() and speed < .65 and _recovery_volume_clear(global_position):
		bail_phase = "get_up";_bail_phase_elapsed = 0.0
	elif bail_phase in ["get_up", "ready"]:
		if not is_on_floor() or not _recovery_volume_clear(global_position):
			bail_phase = "slide";_bail_phase_elapsed = 0.0
		elif bail_phase == "get_up" and _bail_phase_elapsed >= .65:
			bail_phase = "ready";_bail_phase_elapsed = 0.0
		elif bail_phase == "ready" and _bail_phase_elapsed >= .12:
			_mount_board()
			bailing = false
			bail_phase = ""
			_clear_trick_buffers()
			_manual_cooldown = MANUAL_REENTRY_DELAY
			_grind_cooldown = GRIND_RECAPTURE_DELAY
			_transition_cooldown = .1
			recovered.emit()
	_update_pose(delta)


func _drop_board() -> void:
	# Only geometry detaches; the mounted marker remains the stable pose reference.
	_loose_board.global_transform = _board_visual.global_transform
	_board_model.reparent(_loose_board, false)
	_board_model.transform = Transform3D.IDENTITY
	_loose_board.freeze = false
	_loose_board.sleeping = false
	_loose_board.linear_velocity = velocity + global_basis * Vector3(1.8, 2.2, -1.0)
	_loose_board.angular_velocity = global_basis * Vector3(4.0, 2.0, 3.0)
	_loose_board.reset_physics_interpolation()


func _mount_board() -> void:
	if not is_instance_valid(_loose_board):return
	_loose_board.freeze = true
	_loose_board.linear_velocity = Vector3.ZERO
	_loose_board.angular_velocity = Vector3.ZERO
	if _board_model.get_parent() != _board_visual:
		_board_model.reparent(_board_visual, false)
		_board_model.transform = Transform3D.IDENTITY
		_board_model.reset_physics_interpolation()


func _bail_pose_weight() -> float:
	if not bailing:return 0.0
	if bail_phase == "get_up":return 1.0 - smoothstep(0.0, .65, _bail_phase_elapsed)
	if bail_phase == "ready":return 0.0
	return smoothstep(0.0, .28, bail_elapsed)


func set_controls_enabled(enabled: bool) -> void:
	if not enabled:_clear_grind_rail_intent()
	_controls_enabled = enabled
	if not enabled:
		_response.reset()
		_end_manual(true)
		speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		if _transition.active: _transition.reconcile(global_position, Vector3.ZERO)
		_trick_input.clear_actions()
		_setup.reset()
		_skitch.stop()
		_jump_buffer_remaining = 0.0
		_clear_trick_buffers()
		_ollie_held = false
		_crouch_charge = 0.0
		_grind_buffer_remaining = 0.0
		_grind_held_armed = false
		revert_remaining = 0.0


func set_trick_entries_enabled(enabled: bool) -> void:
	if not enabled:_clear_grind_rail_intent()
	# Run overtime permits an existing combo to land, without starting links.
	_trick_entries_enabled = enabled
	if not enabled:
		_trick_input.clear_actions()
		_jump_buffer_remaining = 0.0
		_clear_trick_buffers()
		_ollie_held = false
		_crouch_charge = 0.0
		_grind_buffer_remaining = 0.0
		_grind_held_armed = false
		revert_remaining = 0.0


func set_transition_features(features: Array) -> void:
	_transition_features = features.duplicate()


func set_grind_lines(lines: Array) -> void:
	_clear_grind_rail_intent()
	# Snapshot the collection; geometry itself is immutable during a run.
	_grind_lines = lines.duplicate()
	_grind_index.rebuild(_grind_lines)


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
	_special_used_this_air=true
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


func _direction_snapshot() -> Vector2:
	return Vector2(Input.get_axis("steer_left", "steer_right"), Input.get_axis("push", "brake"))


func _clear_direction_gesture() -> void:
	_vertical_edge = 0
	_vertical_edge_age = 1.0
	_last_vertical = 0
	_vertical_neutral_seen = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		# Menu navigation cannot complete a half-entered gesture on resume.
		# An existing manual, motion, pose and eligibility timers remain frozen.
		_clear_direction_gesture()

	if what == NOTIFICATION_UNPAUSED and grinding:
		# Menu releases do not drop a locked rail; a fresh gameplay edge still exits.
		_grind_held_exit=false
		_grind_grip_age=0.0
	if what == NOTIFICATION_UNPAUSED and _ollie_held and not Input.is_action_pressed("ollie"):
		# A charge released while menus own input is cancelled, not popped on
		# resume. Preserve a real held charge and an already accepted jump buffer.
		_ollie_held = false
		_crouch_charge = 0.0
		crouching = false


func _input(event: InputEvent) -> void:
	# A real D-pad release can cross neutral between physics ticks. Preserve
	# that event; a direct stick reversal or two held directions still refuses.
	if _controls_enabled and _trick_entries_enabled and _last_vertical != 0 \
			and (event.is_action("push") or event.is_action("brake")) \
			and not Input.is_action_pressed("push") and not Input.is_action_pressed("brake"):
		_vertical_neutral_seen = true


func _sample_trick_requests(delta: float) -> void:
	_tick_grind_rail_intent(delta)
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	_flip_buffer_remaining = maxf(0.0, _flip_buffer_remaining - delta)
	_grab_buffer_remaining = maxf(0.0, _grab_buffer_remaining - delta)
	_manual_buffer_remaining = maxf(0.0, _manual_buffer_remaining - delta)
	_grind_buffer_remaining = maxf(0.0, _grind_buffer_remaining - delta)
	_selection_remaining = maxf(0.0, _selection_remaining - delta)
	_vertical_edge_age += delta
	if _controls_enabled and manual_active and _manual_gesture_hold and Input.is_action_just_pressed("manual"):
		_end_manual(true)
	if not _controls_enabled or not _trick_entries_enabled:
		return
	if Input.is_action_just_pressed("ollie"):
		_ollie_held = true
		_crouch_charge = 0.0
	if _ollie_held and Input.is_action_pressed("ollie"):
		_crouch_charge = minf(OLLIE_CHARGE_SECONDS, _crouch_charge + delta)
	if Input.is_action_just_released("ollie") and _ollie_held:
		var charge := smoothstep(0.035, OLLIE_CHARGE_SECONDS, _crouch_charge)
		_pop_impulse = lerpf(OLLIE_SPEED, CHARGED_OLLIE_SPEED, charge)
		_ramp_pop_impulse = lerpf(RAMP_OLLIE_SPEED, CHARGED_RAMP_OLLIE_SPEED, charge)
		_jump_buffer_remaining = JUMP_BUFFER_TIME
		_ollie_held = false
		_crouch_charge = 0.0
	var direction := _direction_snapshot()
	if Input.is_action_just_pressed("flip") and _flip_remaining <= 0.0:
		_flip_request = DirectionalTricks.select("flip", direction)
		_flip_buffer_remaining = TRICK_BUFFER_TIME
		_selection_remaining = TRICK_BUFFER_TIME
	if Input.is_action_just_pressed("grab") and _grab_remaining <= 0.0:
		_grab_request = DirectionalTricks.select("grab", direction)
		_grab_buffer_remaining = TRICK_BUFFER_TIME
		_selection_remaining = TRICK_BUFFER_TIME
	if Input.is_action_just_pressed("grind"):
		_grind_held_armed = true
		_grind_buffer_remaining = 0.18
		_grind_direction = direction
		_grind_entry_action=_trick_input.pop_action("grind")
		_selection_remaining = 0.14
	# Fresh requests may wait for the last buffer-length of recovery; actual
	# entry still needs the full cooldown, floor support and a held request.
	if Input.is_action_just_pressed("manual") and not manual_active and _manual_cooldown <= TRICK_BUFFER_TIME \
			and (airborne or absf(speed) >= MANUAL_MIN_SPEED):
		_manual_request = DirectionalTricks.select("manual", direction)
		_manual_buffer_remaining = TRICK_BUFFER_TIME
		_manual_gesture_hold = false
	var vertical := -1 if direction.y < -0.5 else (1 if direction.y > 0.5 else 0)
	if vertical == 0 and _last_vertical != 0 \
			and not Input.is_action_pressed("push") and not Input.is_action_pressed("brake"):
		_vertical_neutral_seen = true
	if vertical != 0 and vertical != _last_vertical:
		if _vertical_neutral_seen and _vertical_edge != 0 and vertical == -_vertical_edge and _vertical_edge_age <= 0.22 \
				and not manual_active and not transition_active and not lip_active \
				and _manual_cooldown <= TRICK_BUFFER_TIME and (airborne or absf(speed) >= MANUAL_MIN_SPEED):
			_manual_request = TrickCatalog.definition("manual" if _vertical_edge < 0 else "nose_manual")
			_manual_buffer_remaining = TRICK_BUFFER_TIME
			_manual_gesture_hold = true
		_vertical_neutral_seen = false
		_vertical_edge = vertical
		_vertical_edge_age = 0.0
	_last_vertical = vertical


func _restore_contact_shape() -> void:
	if is_instance_valid(_body_collision):
		_body_collision.position = Vector3.UP * 0.85
		_body_collision.basis = Basis.IDENTITY


func _orient_contact_shape(normal: Vector3) -> void:
	transition_normal = normal.normalized()
	var local_normal := global_basis.inverse() * transition_normal
	_body_collision.position = local_normal * 0.85
	_body_collision.basis = Basis(Quaternion(Vector3.UP, local_normal))


var _transition_coping_ray := PhysicsRayQueryParameters3D.new()


## Inspect the live finite cylinder before using its radius for body clearance.
## The analytic concrete remains separate from this physical steel crown.
func _transition_coping_data(feature: Dictionary, point: Vector3) -> Dictionary:
	if not is_instance_valid(feature.get("body")) or not point.is_finite(): return {}
	var toe: Transform3D = feature.transform
	var local := toe.affine_inverse()*point
	var radius: float = feature.radius
	var angle: float = feature.angle
	if absf(local.x)>float(feature.width)*0.5: return {}
	var lip := toe*Vector3(local.x,radius*(1.0-cos(angle)),-radius*sin(angle))
	if point.distance_squared_to(lip)>0.35*0.35: return {}
	var parent: Node = feature.body.get_parent()
	if parent==null: return {}
	for candidate: Node in parent.get_children():
		if not candidate is StaticBody3D or candidate.collision_layer&1==0 				or str(candidate.get_meta("grind_id",""))!=str(feature.id)+"_coping": continue
		for child: Node in candidate.get_children():
			if not child is CollisionShape3D or child.disabled or not child.shape is CylinderShape3D: continue
			var frame: Transform3D = child.global_transform
			if not frame.basis.get_scale().is_equal_approx(Vector3.ONE): continue
			var axis := frame.basis.y.normalized()
			if absf(axis.dot(toe.basis.x))<0.999999: continue
			var along := (lip-frame.origin).dot(axis)
			var tube := child.shape as CylinderShape3D
			if absf(along)>tube.height*0.5: continue
			var centre := frame.origin+axis*along
			if centre.distance_to(lip)>GrindStyle.CONTACT_TOLERANCE: continue
			var crown := centre+Vector3.UP*tube.radius
			_transition_coping_ray.from=crown+Vector3.UP*0.04
			_transition_coping_ray.to=crown-Vector3.UP*0.08
			_transition_coping_ray.collision_mask=1
			_transition_coping_ray.exclude=[get_rid()]
			var hit:=get_world_3d().direct_space_state.intersect_ray(_transition_coping_ray)
			if hit.is_empty() or hit.collider!=candidate or Vector3(hit.normal).y<0.98 					or Vector3(hit.position).distance_to(crown)>GrindStyle.CONTACT_TOLERANCE: continue
			return {"body":candidate,"centre":centre,"crown":crown,"radius":tube.radius,"axis":axis}
	return {}


## The capsule's first hemisphere must clear the real coping circle. The curve
## contact/normal and tangent momentum are unchanged; native movement owns it.
func _transition_body_target(point: Vector3, normal: Vector3, coping: Dictionary) -> Vector3:
	var offset := 0.003
	if not coping.is_empty() and _body_collision.shape is CapsuleShape3D:
		var capsule := _body_collision.shape as CapsuleShape3D
		var relative: Vector3 = point-Vector3(coping.centre)
		relative=relative.slide(Vector3(coping.axis))
		var projection := relative.dot(normal)
		var perpendicular_squared := maxf(0.0,relative.length_squared()-projection*projection)
		var combined: float = capsule.radius+float(coping.radius)+0.001
		if perpendicular_squared<combined*combined:
			var needed := sqrt(combined*combined-perpendicular_squared)-projection-capsule.radius
			offset=maxf(offset,minf(needed,float(coping.radius)+0.003))
	return point+normal*offset


## All segments and both endpoint volumes see steel, scenery and platforms.
func _transition_capsule_segment_clear(query: PhysicsShapeQueryParameters3D, from: Vector3, to: Vector3, axis: Vector3) -> bool:
	query.transform=Transform3D(Basis(Quaternion(Vector3.UP,axis)),from+axis*0.85)
	query.motion=Vector3.ZERO
	var space:=get_world_3d().direct_space_state
	if not space.intersect_shape(query,1).is_empty(): return false
	query.motion=to-from
	var sweep:=space.cast_motion(query)
	if sweep.size()!=2 or sweep[0]<0.9999: return false
	query.motion=Vector3.ZERO
	query.transform.origin=to+axis*0.85
	return space.intersect_shape(query,1).is_empty()


func _transition_support(at: Vector3, normal: Vector3, body: StaticBody3D) -> bool:
	if not is_instance_valid(body) or not body.is_inside_tree(): return false
	var query := PhysicsRayQueryParameters3D.create(at + normal * 0.15, at - normal * 0.10, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	for feature: Dictionary in _transition_features:
		if feature.get("body")!=body: continue
		var coping:=_transition_coping_data(feature,at)
		if not coping.is_empty():
			# Authenticate concrete behind this independently proven steel only.
			# Movement sweeps continue to include that same solid cylinder.
			query.exclude=[get_rid(),coping.body.get_rid()]
			hit=get_world_3d().direct_space_state.intersect_ray(query)
		break
	if not hit.is_empty() and hit.collider == body and Vector3(hit.normal).dot(normal) > 0.85:
		return true
	# The exact coping seam is shared with the deck. Resolve that one endpoint
	# on the curve's interior, rather than accepting the neighbouring deck body.
	for feature: Dictionary in _transition_features:
		if feature.get("body") != body: continue
		var toe: Transform3D = feature.transform
		var local := toe.affine_inverse() * at
		var radius: float = feature.radius
		var angle: float = feature.angle
		var lip := Vector3(local.x, radius * (1.0 - cos(angle)), -radius * sin(angle))
		if absf(local.x) > float(feature.width) * 0.5 or local.distance_to(lip) > 0.005:
			return false
		var inside := angle - deg_to_rad(0.5)
		var point := toe * Vector3(local.x, radius * (1.0 - cos(inside)), -radius * sin(inside))
		var inward := toe.basis * Vector3(0, cos(inside), sin(inside))
		query.from = point + inward * 0.15
		query.to = point - inward * 0.10
		hit = get_world_3d().direct_space_state.intersect_ray(query)
		return not hit.is_empty() and hit.collider == body and Vector3(hit.normal).dot(inward) > 0.85
	return false


func _try_transition() -> bool:
	if _transition_cooldown > 0.0 or lip_active or grinding or not _controls_enabled:
		return false
	if not _transition.try_start(_transition_features, global_position, velocity, _transition_support):
		return false
	_clear_grind_rail_intent()
	_clear_weighted_ollie()
	_end_manual(true)
	_coyote_remaining = 0.0
	if airborne and not _finish_landing(): return false
	var toe: Transform3D = _transition.feature.transform
	_transition_facing = 1.0 if (-global_basis.z).dot(-toe.basis.z) >= 0.0 else -1.0
	if _transition.along_speed < -0.3:
		_face_transition_travel()
	_vert_return.clear()
	_orient_contact_shape(_transition.normal())
	velocity = _transition.travel_velocity()
	speed = velocity.length()
	return true


func _tick_transition(delta: float) -> void:
	_discard_cached_support()
	if not _controls_enabled:
		velocity = Vector3.ZERO
		speed = 0.0
		return
	_steering = Input.get_axis("steer_left", "steer_right")
	if _jump_buffer_remaining > 0.0 and _trick_entries_enabled:
		_jump_buffer_remaining = 0.0
		# Deliberate ramp pop adds to real ascent; charge must still matter
		# when the ramp already supplied more upward speed than a flat ollie.
		velocity = _transition.travel_velocity()
		velocity.y = maxf(0.0,velocity.y) + _ramp_pop_impulse
		velocity += _transition.normal() * 0.25
		_arm_vert_return()
		_transition.stop()
		if _leave_transition(true):
			combo_link_started.emit()
			_emit_trick("ollie")
		return
	if _try_begin_lip(): return
	var steps := maxi(1, ceili(delta * maxf(velocity.length(), 1.0) / 0.075))
	for index in steps:
		var result: String = _transition.step(delta / steps, _steering,
			Input.is_action_pressed("push") or _ollie_held, Input.is_action_pressed("brake"))
		var coping:=_transition_coping_data(_transition.feature,_transition.position())
		var target:=_transition_body_target(_transition.position(),_transition.normal(),coping)
		_orient_contact_shape(_transition.normal())
		var previous := global_position
		var collision := move_and_collide(target - previous, false, 0.001, false)
		var real_motion := global_position - previous
		var proposed: Vector3 = _transition.travel_velocity()
		velocity = proposed.slide(collision.get_normal()) if collision != null else proposed
		if collision != null and real_motion.length() < (target - previous).length() * 0.4:
			# Retain real confirmed contact with collision-adjusted momentum. A
			# blocked steep capsule must not become an upright grounded capsule.
			if _transition.active and _transition.reconcile(global_position, velocity):
				speed = velocity.length()
				return
			_transition.stop()
			_leave_transition(true)
			return
		if not _transition.active:
			if result == "lip": _arm_vert_return()
			if result == "toe" or result == "side": _align_to_travel()
			_leave_transition(result != "toe")
			return
		if not _transition.reconcile(global_position, velocity):
			_leave_transition(true)
			return
		speed = velocity.length()
		if _transition.along_speed < -0.3 or absf(_transition.lateral_speed) > 0.3:
			_face_transition_travel()
		if _try_begin_lip(): return


func _face_transition_travel() -> void:
	var travel: Vector3 = _transition.travel_velocity()
	if Vector2(travel.x, travel.z).length_squared() > 0.04:
		rotation.y = atan2(-travel.x, -travel.z)
	if absf(_transition.along_speed) > 0.3:
		_transition_facing = signf(_transition.along_speed)
	_orient_contact_shape(_transition.normal())


func _arm_vert_return() -> void:
	# Only a real steep, upward departure can arm the automatic arcade turn.
	# No infinite ramp plane, position snap, added speed or spin points.
	if _transition.theta < deg_to_rad(65.0) or velocity.y <= 1.0:
		return
	_vert_return = _transition.feature.duplicate()
	_vert_start_yaw = rotation.y
	_vert_start_up = velocity.y


func _tick_vert_return() -> void:
	if _vert_return.is_empty(): return
	if not is_instance_valid(_vert_return.get("body")) or not _vert_return.body.is_inside_tree() \
			or _vert_return.body.is_queued_for_deletion() or _vert_return.body.collision_layer == 0:
		_vert_return.clear()
		return
	var toe: Transform3D = _vert_return.transform
	var local := toe.affine_inverse() * global_position
	if absf(local.x) > float(_vert_return.width) * 0.5 + 0.4 \
			or absf(local.z + float(_vert_return.radius)) > 1.0:
		_vert_return.clear()
		return
	var downhill := toe.basis.z
	var return_yaw := atan2(-downhill.x, -downhill.z)
	var progress := clampf(1.0 - velocity.y / maxf(_vert_start_up, 0.1), 0.0, 1.0)
	rotation.y = lerp_angle(_vert_start_yaw, return_yaw, smoothstep(0.0, 1.0, progress))


func _prepare_vert_return_contact(delta: float) -> bool:
	if _vert_return.is_empty() or not airborne or not _controls_enabled \
			or _transition_cooldown > 0.0 or velocity.y >= -0.25:
		return false
	var toe: Transform3D = _vert_return.transform
	var local := toe.affine_inverse() * global_position
	var next := toe.affine_inverse() * (global_position + velocity * delta)
	var radius: float = _vert_return.radius
	var angle: float = _vert_return.angle
	var lip_height := radius * (1.0 - cos(angle))
	# Only the imminent downward crossing of this finite, previously departed
	# lip can change the air collider's frame. No position or velocity is changed.
	if local.y < lip_height or next.y > lip_height or local.y - lip_height > 0.35:
		return false
	var fraction := (lip_height - local.y) / (next.y - local.y)
	var crossing := local.lerp(next, fraction)
	var contact := Vector3(crossing.x, lip_height, -radius * sin(angle))
	if absf(crossing.x) > float(_vert_return.width) * 0.5 \
			or crossing.distance_to(contact) > TransitionRide.CAPTURE_GAP:
		return false
	var normal := toe.basis * Vector3(0, cos(angle), sin(angle))
	if velocity.dot(normal) > TransitionRide.MAX_OUTWARD_SPEED \
			or not _transition_support(toe * contact, normal, _vert_return.body):
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _body_collision.shape
	query.collision_mask = 1 | 8
	query.exclude = [get_rid()]
	query.margin = 0.001
	for progress: float in [0.25, 0.5, 0.75, 1.0]:
		var axis := Vector3.UP.slerp(normal, progress).normalized()
		query.transform = Transform3D(Basis(Quaternion(Vector3.UP, axis)), global_position + axis * 0.85)
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return false
	# The real move below still determines position/impact velocity; normal
	# transition admission after it must confirm the actual same-face contact.
	_orient_contact_shape(normal)
	return true


func _leave_transition(in_air: bool) -> bool:
	_coyote_remaining = 0.0
	_transition_cooldown = 0.10
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _body_collision.shape
	query.collision_mask = 1 | 8
	query.exclude = [get_rid()]
	# An upright capsule occupies different space from a wall-aligned capsule.
	# Sweep away from confirmed contact by at most one capsule radius plus skin;
	# require the complete upright volume to clear ordinary scenery as well.
	var detached := false
	var origin := global_position
	for clearance: float in [0.0, 0.08, 0.16, 0.24, 0.34]:
		var target := origin + transition_normal * clearance
		query.transform = Transform3D(global_basis, target) * Transform3D(Basis.IDENTITY, Vector3.UP * 0.875)
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(): continue
		if clearance > 0.0:
			if test_move(global_transform, target - global_position, null, 0.001, false): continue
			move_and_collide(target - global_position, false, 0.001, false)
		if global_position.distance_to(target) <= 0.005:
			detached = true
			break
	if not detached:
		begin_bail("blocked_detachment", spawn_position)
		return false
	_ramp_air_normal = transition_normal
	_ramp_launch_forward = velocity.slide(_ramp_air_normal).normalized()
	_restore_contact_shape()
	transition_normal = Vector3.UP
	if in_air:
		_begin_air(velocity.y > 1.0)
	else:
		airborne = false
		_ramp_air = false
	speed = velocity.dot(-global_basis.z) if not in_air else Vector2(velocity.x, velocity.z).length()
	return true


func _try_begin_lip() -> bool:
	if not _trick_entries_enabled or not _grind_request_available() \
			or not Input.is_action_pressed("grind") or not _transition.active:
		return false
	var feature: Dictionary = _transition.feature
	if _transition.theta < float(feature.angle) - deg_to_rad(6.0) \
			or _transition.along_speed <= 0.0 or absf(_transition.lateral_speed) > 2.5:
		return false
	var toe: Transform3D = feature.transform
	var angle: float = feature.angle
	var radius: float = feature.radius
	var at := toe * Vector3(_transition.across, radius * (1.0 - cos(angle)), -radius * sin(angle))
	var normal := toe.basis * Vector3(0, cos(angle), sin(angle))
	# The deck and curve share the exact edge. Confirm the front face just inside
	# its final segment, then sweep to the coping before changing capsule frame.
	var inside_angle := maxf(0.0, angle - deg_to_rad(0.5))
	var inside := toe * Vector3(_transition.across, radius * (1.0 - cos(inside_angle)), -radius * sin(inside_angle))
	var inside_normal := toe.basis * Vector3(0, cos(inside_angle), sin(inside_angle))
	if not _transition_support(inside, inside_normal, feature.body): return false
	var coping:=_transition_coping_data(feature,at)
	var crown: Vector3=coping.crown if not coping.is_empty() else at
	var target:=crown+Vector3.UP*0.025+normal*0.025
	var outward:=global_position
	if not coping.is_empty():
		# Move at most this real tube's radius away before lifting around it.
		var gap: float=(global_position-Vector3(coping.centre)).dot(normal)
		outward+=normal*maxf(0.0,float(coping.radius)+0.003-gap)
	var turn:=outward+Vector3.UP*maxf(0.0,target.y-outward.y)
	var axis:=_body_collision.global_basis.y.normalized()
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=_body_collision.shape
	query.collision_mask=1|8
	query.exclude=[get_rid()]
	query.margin=0.001
	if not _transition_capsule_segment_clear(query,global_position,outward,axis) 			or not _transition_capsule_segment_clear(query,outward,turn,axis): return false
	for progress: float in [0.25,0.5,0.75,1.0]:
		var turn_axis:=axis.slerp(Vector3.UP,progress).normalized()
		if not _transition_capsule_segment_clear(query,turn,turn,turn_axis): return false
	if not _transition_capsule_segment_clear(query,turn,target,Vector3.UP): return false
	for waypoint: Vector3 in [outward,turn]:
		move_and_collide(waypoint-global_position,false,0.001,false)
		if global_position.distance_to(waypoint)>0.005: return false
	_restore_contact_shape()
	move_and_collide(target-global_position,false,0.001,false)
	if global_position.distance_to(target)>0.005: return false
	_lip_feature=feature.duplicate()
	_lip_feature["coping_contact"]=crown
	_lip_across = _transition.across
	_lip_entry_speed = minf(absf(_transition.along_speed), 10.0)
	_transition.stop()
	transition_normal = Vector3.UP
	lip_active = true
	_lip_elapsed = 0.0
	lip_balance = 0.05
	_clear_grind_rail_intent()
	var chosen := DirectionalTricks.select("lip", _grind_direction)
	lip_id = chosen.id
	lip_trick_id=lip_id
	_lip_definition=TrickCatalog.definition(lip_id)
	_grind_buffer_remaining = 0.0
	_grind_held_armed = false
	airborne = false
	_ramp_air = false
	velocity = Vector3.ZERO
	speed = 0.0
	_clear_trick_buffers()
	combo_link_started.emit()
	_emit_trick(lip_id)
	return true


func _tick_lip(delta: float) -> void:
	_clear_weighted_ollie()
	if not _controls_enabled: return
	_try_lip_extension()
	lip_id=lip_trick_id
	_lip_elapsed += delta
	_steering = Input.get_axis("steer_left", "steer_right")
	lip_balance += (signf(lip_balance) * (0.15 + _lip_elapsed * 0.06) + _steering * 1.4) * delta
	if absf(lip_balance) >= 1.0 or not is_instance_valid(_lip_feature.get("body")):
		begin_bail("lip_balance")
		return
	if _jump_buffer_remaining > 0.0 and _trick_entries_enabled:
		_jump_buffer_remaining = 0.0
		_release_lip(true)
	elif not Input.is_action_pressed("grind") or _lip_elapsed >= 4.0:
		_release_lip(false)


func _release_lip(jump: bool) -> void:
	var toe: Transform3D = _lip_feature.transform
	# A small explicit inward drop clears the coping; ordinary gravity and the
	# finite collision-confirmed surface handle the return, not a hidden plane.
	velocity = toe.basis.z * 1.2 + Vector3.UP * (_ramp_pop_impulse if jump else -0.8)
	_ramp_air_normal = toe.basis*Vector3(0,cos(float(_lip_feature.angle)),sin(float(_lip_feature.angle)))
	_ramp_launch_forward = velocity.slide(_ramp_air_normal).normalized()
	_align_to_travel()
	lip_active = false
	lip_id = ""
	_grind_buffer_remaining = 0.0
	_transition_cooldown = 0.06
	_begin_air(jump)
	if jump:
		combo_link_started.emit()
		_emit_trick("ollie")


func _physics_process(delta: float) -> void:
	last_physics_frame = Engine.get_physics_frames()
	if bailing:
		_tick_bail(delta)
		return
	_recovery_fade_remaining = maxf(0.0,_recovery_fade_remaining-delta)
	_trick_input.sample(delta)
	_wall.tick(delta)
	_skitch.tick(delta)
	_launch_age += delta
	_style_cooldown = maxf(0.0,_style_cooldown-delta)
	_flip_catch_remaining = maxf(0.0,_flip_catch_remaining-delta)
	_grab_cooldown = maxf(0.0,_grab_cooldown-delta)
	_grind_cooldown = maxf(0.0, _grind_cooldown - delta)
	_transition_cooldown = maxf(0.0, _transition_cooldown - delta)
	_manual_cooldown = maxf(0.0, _manual_cooldown - delta)
	# Match the score deadline's treatment of accumulated physics-step residue.
	if _manual_cooldown <= 0.000000000001:
		_manual_cooldown = 0.0
	revert_remaining = maxf(0.0, revert_remaining - delta)
	var held_before := _ollie_held
	_sample_trick_requests(delta)
	_sample_feature_charge(held_before)
	var feature_push := Input.get_action_strength("push") if _controls_enabled else 0.0
	var feature_brake := Input.get_action_strength("brake") if _controls_enabled else 0.0
	_steering = Input.get_axis("steer_left","steer_right") if _controls_enabled else 0.0
	if setup_active:
		_tick_setup(delta)
		_update_pose(delta)
		return
	if skitching:
		_tick_skitch(delta)
		_update_pose(delta)
		return
	if _controls_enabled and _trick_entries_enabled and not (grinding or transition_active or wallriding or manual_active) and Input.is_action_pressed("grind") and Input.is_action_just_pressed("interact"):
		for vehicle: Node in get_tree().get_nodes_in_group("skate_vehicles"):
			if _skitch.try_start(self,vehicle):
				_jump_buffer_remaining=0.0
				_coyote_remaining=0.0
				airborne=false
				_clear_grind_rail_intent()
				_clear_weighted_ollie()
				_skitch_scored=false
				var tow: Vector3=_skitch.travel_velocity
				rotation.y=atan2(-tow.x,-tow.z)
				_tick_skitch(delta)
				_update_pose(delta)
				return
	if _feature_transition.active or (_controls_enabled and not (wallriding or grinding or manual_active or _transition.active or lip_active) and _feature_transition.try_enter(self,velocity)):
		_clear_grind_rail_intent()
		_tick_feature_transition(delta,feature_push,feature_brake)
		_update_pose(delta)
		return
	if wallriding:
		_tick_wall(delta)
		_update_pose(delta)
		return
	if lip_active:
		_tick_lip(delta)
		_update_pose(delta)
		return
	if grinding:
		_tick_grind(delta)
		_update_pose(delta)
		return
	if _transition.active or _try_transition():
		_tick_transition(delta)
		_update_pose(delta)
		return
	if bailing:
		_update_pose(delta)
		return
	var grounded_before := is_on_floor() and not airborne and not _force_air_tick
	_force_air_tick=false
	var push_input := 0.0
	var brake_input := 0.0
	_steering = 0.0
	if _controls_enabled:
		push_input = maxf(Input.get_action_strength("push"), 1.0 if _ollie_held else 0.0)
		brake_input = Input.get_action_strength("brake")
		_steering = Input.get_axis("steer_left", "steer_right")
	_coyote_remaining = COYOTE_TIME if grounded_before else maxf(0.0, _coyote_remaining - delta)

	if manual_active:
		if not grounded_before:
			_end_manual(false)
		elif not _controls_enabled or not (Input.is_action_pressed("manual") or _manual_gesture_hold) or absf(speed) < MANUAL_MIN_SPEED:
			_end_manual(true)
		elif not _tick_manual_balance(delta, _steering):
			return

	powersliding=grounded_before and _controls_enabled and not manual_active and brake_input>.5 and absf(_steering)>.6 and absf(speed)>4.0
	if grounded_before:
		# Apply hill acceleration before deliberate braking, so a stopped brake
		# holds a grade and disabled controls cannot restart a finished run.
		if _controls_enabled:
			var normal := _native_floor_normal()
			var tangent := (-global_basis.z).slide(normal).normalized()
			speed = _response.apply_slope_gravity(speed, Vector3.DOWN.slide(normal).dot(tangent), delta, GROUND_GRAVITY)
		else:
			speed = 0.0
		if manual_active:
			# Directional input balances while the manual coasts.
			speed = move_toward(speed, 0.0, ROLLING_DRAG * delta)
		elif brake_input > 0.05:
			speed = move_toward(speed, 0.0, (8.0 if powersliding else BRAKE_DECELERATION) * brake_input * delta)
		elif push_input > 0.05:
			var travel_sign := -1.0 if speed < -0.5 else 1.0
			speed = travel_sign*minf(MAX_SPEED,absf(speed)+PUSH_ACCELERATION*push_input*delta)
		else:
			speed = _response.coast_speed(speed, delta)
	# Ground carving turns travel; airborne stick input drives visible spin.
	# Camera preferences cannot change physical turning or carried momentum.
	# Balance correction must not also carve. Shoulders provide an independent
	# turning input during manuals; ordinary ground/air controls stay the same.
	var turn_input := Input.get_axis("spin_left", "spin_right") if manual_active else _steering
	var steering_angle: float = _response.steering_step(turn_input, speed, true, delta) if grounded_before else 0.0
	if powersliding: steering_angle+=-_steering*2.0*delta
	rotation.y += steering_angle
	var forward := -global_basis.z
	if grounded_before:
		var floor_normal := _native_floor_normal()
		var ground_direction := forward.slide(floor_normal).normalized()
		velocity = ground_direction * speed
	else:
		# Carry the ramp/contact-adjusted momentum into air. Rebuilding X/Z
		# from surface speed adds energy at lips and restores blocked motion.
		velocity = velocity.rotated(Vector3.UP, steering_angle)
		var air_gravity := RAMP_AIR_GRAVITY if _ramp_air else (WEIGHTED_OLLIE_GRAVITY if _weighted_ollie_air else GRAVITY)
		velocity.y -= air_gravity * delta
		_tick_vert_return()

	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0:
		if _launch_id in ["boneless","no_comply"] and _setup.try_start(self,_launch_id,SkaterVisualSource.setup_foot_offset()):
			_setup_impulse=_launch_impulse
			_jump_buffer_remaining=0.0
			_coyote_remaining=0.0
			_end_manual(false)
			_tick_setup(delta)
			_update_pose(delta)
			return
		if _launch_id in ["boneless","no_comply"]:
			_launch_id="ollie"
			_launch_impulse=_launch_base_impulse
		_end_manual(false)
		# Only this actual plain, flat-ground jump may carry a prior finite
		# wall fit into air, including a real within-frame tap. Falls and
		# transition launches never arm this presentation continuation.
		_obstacle_ollie_continuation=grounded_before and _native_floor_valid \
			and _native_floor_normal().y>0.999 and _launch_id=="ollie" \
			and _obstacle_visual_offset.length_squared()>0.0
		_begin_air()
		_set_launch_mode()
		_weighted_ollie_air = not _ramp_air and _launch_id in ["ollie", "nollie"] and _native_floor_normal().y > 0.999
		var pop_impulse := _launch_impulse * WEIGHTED_OLLIE_IMPULSE_SCALE if _weighted_ollie_air else _launch_impulse
		velocity.y = maxf(0.0, velocity.y) + pop_impulse
		_weighted_ollie_duration = 2.0 * velocity.y / WEIGHTED_OLLIE_GRAVITY if _weighted_ollie_air else 0.0
		_ollie_pose_remaining = OLLIE_POSE_SECONDS
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		combo_link_started.emit()
		_emit_trick(_launch_id)

	if airborne and _controls_enabled and _trick_entries_enabled:
		_apply_air_tricks(delta)
		if bailing:
			_update_pose(delta)
			return
		if _try_grind():
			_update_pose(delta)
			return

		if Input.is_action_pressed("grind") and _flip_remaining<=0.0 and _special_remaining<=0.0 and _spin_landing_clean() and _wall.try_start(self,velocity):
			_clear_grind_rail_intent()
			_complete_flip()
			_award_air_spin()
			_emit_trick("wallride")
			combo_link_started.emit()
			_tick_wall(delta)
			_update_pose(delta)
			return
	var previous_platform := _native_platform_floor
	var previous_carry_ready := _native_platform_ready
	var arriving_from_air := airborne
	var before_move := global_position
	var was_airborne := airborne
	var pre_move_grind_velocity := velocity
	var returning_to_curve := _prepare_vert_return_contact(delta)
	move_and_slide()
	if grounded_before and not airborne and not is_on_floor(): apply_floor_snap()
	_restore_platform_after_move()
	if was_airborne:_remember_grind_rail_impact(pre_move_grind_velocity)
	if returning_to_curve:
		if _try_transition():
			_update_pose(delta)
			return
		# An unexpected obstruction/edge miss cannot leave an air/grind rider
		# using the temporary contact frame. Restore only with real clearance.
		if not _leave_transition(true):
			_update_pose(delta)
			return
	if was_airborne and _controls_enabled and _trick_entries_enabled \
			and _try_grind(before_move, true, pre_move_grind_velocity):
		_update_pose(delta)
		return
	if _try_transition():
		_update_pose(delta)
		return
	if bailing:
		_update_pose(delta)
		return
	if is_on_floor():
		# Derive signed board-forward speed from actual contact-adjusted travel.
		# This preserves collision response while allowing a steep uphill to
		# become a controlled roll back down its bank.
		var contact_direction := (-global_basis.z).slide(_native_floor_normal()).normalized()
		var continuing_platform := previous_carry_ready and previous_platform==_native_platform_floor
		var carry := get_platform_velocity() if arriving_from_air or continuing_platform else Vector3.ZERO
		speed = clampf((get_real_velocity()-carry).dot(contact_direction), -MAX_SPEED, MAX_SPEED)
		if airborne and not _finish_landing():
			_update_pose(delta)
			return
		if manual_active and absf(speed) < MANUAL_MIN_SPEED:
			_end_manual(true)
		_try_ground_links()
		if not manual_active:_last_supported_position = global_position
	else:
		_end_manual(false)
		speed = Vector2(velocity.x, velocity.z).length()
		if not airborne:
			_begin_air()

	if global_position.y < -8.0 or absf(global_position.x) > WORLD_LIMIT or absf(global_position.z) > WORLD_LIMIT:
		begin_bail("out_of_world", spawn_position)

	_update_pose(delta)


func _clear_weighted_ollie() -> void:
	_weighted_ollie_air = false
	_weighted_ollie_duration = 0.0


func _begin_air(from_ramp: bool = false) -> void:
	if airborne:
		return
	_clear_weighted_ollie()
	airborne = true
	_ramp_air_sequence += 1
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
	_ramp_air = from_ramp
	revert_remaining = 0.0
	_special_used_this_air = false
	_clear_special_visual()
	_flip_used = false
	_grab_used = false
	_air_spin = 0.0
	_spin_angle = 0.0
	_air_grind_yaw = 0.0


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
		if not flip_action.is_empty() and not bool(flip_action.get("advanced_direction",false)) and float(flip_action.get("age",0.0))>TRICK_BUFFER_TIME+.0000001:
			flip_action={}
		if not flip_action.is_empty():
			_flip_definition = _trick_input.select_action("flip",flip_action,_direction_snapshot())
			flip_trick_id = str(_flip_definition.id)
			active_flip_id=flip_trick_id
			_flip_buffer_remaining=0.0
			_flip_duration = float(_flip_definition.get("duration", FLIP_DURATION))
			_flip_remaining = _flip_duration
			_flip_yaw_committed = false
			_flip_motion_origin = Vector3.ZERO
			_grab_remaining = 0.0
			_grab_cooldown = 0.10
			_pending_grab.clear()
			_emit_trick(flip_trick_id)
		var grab_action: Dictionary = _trick_input.pop_action("grab") if _grab_remaining <= 0.0 and _pending_grab.is_empty() else {}
		if not grab_action.is_empty() and not bool(grab_action.get("advanced_direction",false)) and float(grab_action.get("age",0.0))>TRICK_BUFFER_TIME+.0000001:
			grab_action={}
		if not grab_action.is_empty():
			var grab_choice := _trick_input.select_action("grab",grab_action,_direction_snapshot())
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
	if is_zero_approx(spin_input) and _selection_remaining<=0.0 and not Input.is_action_pressed("flip") and not Input.is_action_pressed("grab"):
		spin_input=Input.get_axis("steer_left","steer_right")
	_air_spin -= spin_input * SPIN_SPEED * delta
	_spin_angle = _air_spin


func _award_air_spin() -> void:
	# M01 uses forgiving, clean landings at any heading. Small spin tolerance
	# keeps the 180 accessible without precise last-frame timing.
	var half_turns := int(floor((absf(_air_spin) + deg_to_rad(20.0)) / PI))
	if half_turns > 0:
		var direction := "Frontside" if _air_spin > 0.0 else "Backside"
		_emit_trick("spin_180","%s %d" % [direction,half_turns*180],half_turns*200)
		var turn:=signf(_air_spin)*half_turns*PI
		rotation.y+=turn
		if half_turns%2==1:_switch_stance=not _switch_stance
		_spin_angle=wrapf(_air_spin-turn,-PI,PI)
		speed=Vector3(velocity.x,0,velocity.z).dot(-global_basis.z)
	_air_spin = 0.0


func _finish_landing() -> bool:
	_clear_grind_rail_intent()
	_clear_weighted_ollie()
	if _special_remaining>0.0 and _special_remaining<=.15:_complete_special()
	if _special_remaining>.15 or not _spin_landing_clean() or (_flip_remaining>0.0 and 1.0-_flip_remaining/_flip_duration<FLIP_LANDING_TOLERANCE):
		_start_bail()
		return false
	_complete_flip()
	_flip_buffer_remaining = 0.0
	_grab_buffer_remaining = 0.0
	var board_stance:=roundf(_air_grind_yaw/PI)*PI
	_award_air_spin()
	_stance_angle=wrapf(_stance_angle+board_stance,-PI,PI)
	_spin_angle=wrapf(_spin_angle+_air_grind_yaw-board_stance,-PI,PI)
	_air_grind_yaw = 0.0
	_clear_special_visual()
	airborne = false
	_ramp_air = false
	_vert_return.clear()
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_ollie_pose_remaining = 0.0
	revert_remaining = TrickCatalog.LANDING_LINK_SECONDS if _trick_entries_enabled else 0.0
	_revert_used = false
	_pending_grab.clear()
	landed.emit(true)
	return true


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
		manual_id=manual_trick_id
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
				manual_id=manual_trick_id
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


func _tick_manual_balance(delta: float, correction: float) -> bool:
	_manual_elapsed += delta
	var outward := 1.0 if manual_balance >= 0.0 else -1.0
	var drift := outward * (0.18 + 0.08 * _manual_elapsed)
	manual_balance += (drift + correction * MANUAL_BALANCE_CONTROL) * delta
	if absf(manual_balance) >= 1.0:
		begin_bail("manual_balance")
		_manual_cooldown = MANUAL_REENTRY_DELAY
		return false
	return true


func _end_manual(grounded_exit: bool) -> void:
	if not manual_active:
		return
	manual_active = false
	_manual_gesture_hold = false
	_manual_latched=false
	manual_balance = 0.0
	_manual_elapsed = 0.0
	_manual_cooldown = MANUAL_REENTRY_DELAY
	if grounded_exit:
		combo_link_ended.emit()


func _clear_trick_buffers() -> void:
	if not manual_active: _manual_gesture_hold = false
	_clear_direction_gesture()
	_flip_buffer_remaining = 0.0
	_grab_buffer_remaining = 0.0
	_manual_buffer_remaining = 0.0


func _grind_request_available() -> bool:
	return _grind_buffer_remaining > 0.0 or (_grind_held_armed and Input.is_action_pressed("grind"))


func _try_grind(previous_position: Vector3 = Vector3.ZERO, swept: bool = false, swept_velocity: Vector3 = Vector3.INF) -> bool:
	if _grind_cooldown > 0.0 or _flip_remaining>0.0 or _flip_buffer_remaining>0.0 or _special_remaining>0.0 or not _spin_landing_clean() or not _grind_request_available():
		return false
	# Read the drawn board before travel alignment, spin scoring or stance reset.
	_grind_board_forward = -_board_visual.global_basis.z
	_grind_choices.clear()
	var feature_capture:bool = _feature_transition.active
	var admission: Callable = _feature_transition.grind_path_clear.bind(self) if feature_capture else _rail_path_clear
	var capture_motion: Vector3=(swept_velocity if swept_velocity.is_finite() else get_real_velocity()) if swept else velocity
	var replaying_rail_intent:=false
	if not feature_capture and _grind_rail_intent_remaining>0.0 and capture_motion.y>0.0 \
		and Input.is_action_pressed("grind") and Vector2(capture_motion.x,capture_motion.z).length()<GrindRideSource.ENTRY_SPEED:
		# Collision still clips physical movement. Only capture intent retains
		# the actual incoming XZ briefly, for that exact native RID and IDs.
		capture_motion.x=_grind_rail_intent_velocity.x;capture_motion.z=_grind_rail_intent_velocity.z
		replaying_rail_intent=true
	var target_admission: Callable
	if not feature_capture:target_admission=_grind_capture_path_clear.bind(capture_motion,replaying_rail_intent)
	var captured: bool
	if swept:
		captured = _grind.start_swept(_grind_index.nearby(global_position), previous_position, global_position, capture_motion, admission, _grind_candidate_supported,target_admission)
	else:
		captured = _grind.start(_grind_index.nearby(global_position), global_position, capture_motion, admission, _grind_candidate_supported,target_admission)
	if not captured:
		return false
	_clear_grind_rail_intent()
	_clear_weighted_ollie()
	_feature_transition.reset(self)
	_wall.stop()
	lip_active=false
	_discard_cached_support()
	var selected: Dictionary = _grind_choices[_grind.line.get_instance_id()]
	_grind_transfer.reset()
	_grind_pending.clear()
	_grind_exact_pose=false
	grind_style_id = str(selected.id)
	grind_trick_id=grind_style_id
	_grind_definition=TrickCatalog.definition(grind_style_id)
	_grind_grip_age=0.0
	_grind_held_exit=false
	_rail_backwards=false
	_grind_hold_age=0.0
	_grind_hold_tick=0
	_grind_hold_points=0
	_grind_style_yaw = float(selected.yaw)
	if grind_style_id != "rail_grind":
		_solve_grind_contact(_grind_contact,_grind.line,_grind.distance,_grind.direction,_grind_style_yaw,grind_style_id,0.0)
	_grind_buffer_remaining = 0.0
	_grind_held_armed = false
	_vert_return.clear()
	_clear_trick_buffers()
	_award_air_spin()
	# Preserve committed body stance independently of drawn board Shove-It yaw.
	_rail_backwards=(-global_basis.z).dot(_grind.travel_velocity())<0.0
	_clear_special_visual()
	airborne = false
	_ramp_air = false
	_flip_remaining = 0.0
	_grab_remaining = 0.0
	_ollie_pose_remaining = 0.0
	_spin_angle = 0.0
	_air_grind_yaw = 0.0
	_jump_buffer_remaining = 0.0
	_coyote_remaining = 0.0
	revert_remaining = 0.0
	_grind_visual_offset += global_position - _grind.position()
	global_position = _grind.position()
	velocity = _grind.travel_velocity()
	speed=-_grind.speed if _rail_backwards else _grind.speed
	_align_to_travel()
	combo_link_started.emit()
	grind_captured.emit(_grind.line.id)
	_emit_trick(grind_style_id)
	return true


func _solve_grind_contact(result: GrindStyle.ContactPose, line, distance: float,
		direction: float, yaw: float, style_id: String, balance: float) -> bool:
	# The native crown stays fixed. Only explicit box edges may use the roll
	# derived once from this rider's actual connected board model.
	return GrindStyle.solve_into(result,line,distance,direction,yaw,style_id,balance,
		_grind_clearance.edge_roll_angle)


func _grind_candidate_supported(line, distance: float, direction: float) -> bool:
	var key: int = line.get_instance_id()
	# Legacy guides retain their explicit generic path; metadata is not inferred.
	if not line.contact_verified:
		_grind_choices[key] = {"id":"rail_grind","yaw":0.0}
		return true
	var selected: Dictionary = GrindStyle.select(_grind_direction,_grind_board_forward,line.dir_at(distance)*direction)
	if bool(_grind_entry_action.get("advanced_direction",false)):
		var advanced:=TrickCatalog.resolve("grind",str(_grind_entry_action.get("direction","neutral")))
		if not advanced.is_empty() and str(advanced.id)!="rail_grind":
			selected={"id":str(advanced.id),"yaw":float(advanced.get("grind_yaw",0.0))}
	if selected.is_empty(): return false
	var supported := _solve_grind_contact(_grind_candidate_contact,line,distance,direction,float(selected.yaw),str(selected.id),0.0)
	if supported and _requires_model_grind_clearance(str(selected.id)):
		supported=_grind_clearance.allows_path(_board_visual.global_transform,_grind_candidate_contact,line.contact_up(distance))
	if supported:
		var model_origin := _grind_candidate_contact.board_transform.origin - _grind_candidate_contact.board_transform.basis * Vector3(0,.12,0)
		# A known board obstruction or oversized visual correction must not gain
		# admission through the legacy path, which has no named-board envelope.
		if model_origin.distance_to(_visual.global_position) > GrindRideSource.MAX_CAPTURE_TICK_DISPLACEMENT \
				or not _grind_board_clear(_grind_candidate_contact.board_transform,line,distance):
			return false
		_grind_choices[key] = selected
		return true
	# A neutral legacy route may lack a supported two-truck chord/board envelope.
	# Do not award a named style for it; explicit sideways selection must refuse.
	if selected.id == "grind_50_50" and line.contact_edge_outward == Vector3.ZERO:
		_grind_choices[key] = {"id":"rail_grind","yaw":0.0}
		return true
	return false


func _grind_board_clear(board_transform: Transform3D,line=null,distance: float=0.0) -> bool:
	# Bounds centre Y=(-.12+.046864)/2; only ordinary world blocks the board.
	_grind_board_query.transform = board_transform * Transform3D(Basis.IDENTITY,GRIND_BOARD_CENTER)
	var hits:=get_world_3d().direct_space_state.intersect_shape(_grind_board_query,16)
	if hits.is_empty():return true
	# The conservative whole-board box extends below the actual truck crowns.
	# Refine only its intended support contact with the cached real model; all
	# solids, including this rail and neighbouring rails, stay in that query.
	return _only_intended_grind_hits(hits,line) and _grind_clearance.allows_frame_path(
		board_transform,board_transform,line.contact_up(distance))


func _only_intended_grind_hits(hits: Array,line) -> bool:
	if line==null or not line.is_valid or hits.is_empty() or hits.size()>=16:return false
	var target_id: String=str(line.id)
	for hit: Dictionary in hits:
		var collider: Variant=hit.get("collider")
		if not collider is StaticBody3D:return false
		var matched:=false
		for key: StringName in GRIND_SUPPORT_META:
			if not collider.has_meta(key):continue
			var ids: Variant=collider.get_meta(key)
			if (ids is Array or ids is PackedStringArray) and ids.has(target_id):matched=true
		matched=matched or str(collider.get_meta("grind_id",""))==target_id
		if not matched:return false
	return true


func _grind_board_path_clear(from: Transform3D, to: Transform3D,line=null,distance: float=0.0) -> bool:
	# Native shape casts do not sweep rotation. One conservative box encloses
	# all intermediate board corners under linear origin/shortest-arc rotation.
	var motion := from.basis.inverse() * (to.origin-from.origin)
	var angle := from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion())
	var angular_size := 4.0*GRIND_BOARD_CORNER_RADIUS*sin(angle*.5)
	_grind_board_box.size = GRIND_BOARD_SIZE + motion.abs() + Vector3.ONE*angular_size
	_grind_board_query.transform = Transform3D(from.basis,(from.origin+to.origin)*.5+from.basis*GRIND_BOARD_CENTER)
	var hits:=get_world_3d().direct_space_state.intersect_shape(_grind_board_query,16)
	var clear: bool=hits.is_empty()
	if not clear and _only_intended_grind_hits(hits,line):
		clear=_grind_clearance.allows_frame_path(from,to,line.contact_up(distance))
	_grind_board_box.size = GRIND_BOARD_SIZE
	return clear


func _clear_grind_style() -> void:
	grind_style_id = ""
	_grind_style_yaw = 0.0
	_grind_contact.valid = false
	_grind_contact.anchor_count = 0


func _rail_path_clear(from: Vector3, to: Vector3) -> bool:
	var start := global_transform
	start.origin = from
	# Sweep the real rider capsule against ordinary scenery, including overlap
	# recovery. Rail-only props are layer 2; world obstacles remain layer 1.
	var contact := KinematicCollision3D.new()
	if not test_move(start,to-from,contact,safe_margin,true,16): return true
	# A real supporting top can be inside the15mm safety shell without
	# intersecting the capsule itself. That floor proximity is legal on a low
	# bridge rail or sloped hubba; walls and ceilings keep the original margin.
	if not _rail_floor_contacts_only(contact): return false
	var collision := get_node("BodyCollision") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = start*collision.transform
	query.motion = to-from
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.margin = 0.0
	var sweep := get_world_3d().direct_space_state.cast_motion(query)
	if sweep.size()!=2 or sweep[0]<0.9999: return false
	# cast_motion ignores initial overlap. Independently prove both endpoint
	# volumes have only resting floor contact within the native1mm margin.
	for endpoint: Vector3 in [from,to]:
		var transform := start
		transform.origin = endpoint
		var resting := KinematicCollision3D.new()
		if test_move(transform,Vector3.ZERO,resting,0.001,true,16):
			if not _rail_floor_contacts_only(resting) or not is_finite(resting.get_depth()) \
					or resting.get_depth()>0.001 or resting.get_travel().length()>0.002: return false
	return true


func _clear_grind_rail_intent() -> void:
	_grind_rail_intent_remaining=0.0;_grind_rail_intent_velocity=Vector3.ZERO
	_grind_rail_intent_position=Vector3.ZERO;_grind_rail_intent_rid=RID();_grind_rail_intent_ids.clear()


func _tick_grind_rail_intent(delta: float) -> void:
	if _grind_rail_intent_remaining<=0.0:return
	if not _controls_enabled or not _trick_entries_enabled or not Input.is_action_pressed("grind") \
		or not airborne or velocity.y<=0.0 or bailing or wallriding or transition_active or lip_active or grinding \
		or setup_active or skitching or global_position.distance_to(_grind_rail_intent_position)>GrindRideSource.CAPTURE_RADIUS:
		_clear_grind_rail_intent();return
	_grind_rail_intent_remaining=maxf(0.0,_grind_rail_intent_remaining-maxf(0.0,delta))
	if _grind_rail_intent_remaining<=0.0:_clear_grind_rail_intent()


func _remember_grind_rail_impact(incoming: Vector3) -> void:
	if _grind_rail_intent_remaining>0.0 or not _controls_enabled or not _trick_entries_enabled \
		or not airborne or incoming.y<=0.0 or not Input.is_action_pressed("grind") or not _grind_request_available() \
		or Vector2(incoming.x,incoming.z).length()<GrindRideSource.ENTRY_SPEED \
		or Vector2(velocity.x,velocity.z).length()>=GrindRideSource.ENTRY_SPEED:return
	for index: int in mini(get_slide_collision_count(),16):
		var contact:=get_slide_collision(index)
		var collider: Variant=contact.get_collider()
		if not collider is StaticBody3D or collider.collision_layer & 1==0:continue
		var native_rid: RID=collider.get_rid()
		for candidate in _grind_index.nearby(global_position):
			if not candidate.contact_verified or not _only_intended_grind_hits([{"collider":collider}],candidate):continue
			var near: Dictionary=candidate.closest(global_position)
			if near.is_empty():continue
			var at: Vector3=_grind._body_point(candidate,float(near.dist))
			if at.distance_to(global_position)>GrindRideSource.CAPTURE_RADIUS or not _grind_native_crown(candidate,float(near.dist),native_rid):continue
			if _grind_rail_intent_ids.size()>=16:break
			_grind_rail_intent_ids.append(str(candidate.id))
		if not _grind_rail_intent_ids.is_empty():
			_grind_rail_intent_remaining=TRICK_BUFFER_TIME
			_grind_rail_intent_velocity=Vector3(incoming.x,0.0,incoming.z)
			_grind_rail_intent_position=global_position;_grind_rail_intent_rid=native_rid
			return


func _grind_capture_path_clear(line,from: Vector3,to: Vector3,distance: float,_direction: float,motion: Vector3,replaying: bool=false) -> bool:
	if not from.is_finite() or not to.is_finite() or from.distance_to(to)>GrindRideSource.MAX_CAPTURE_CORRECTION:return false
	if replaying and not _grind_rail_intent_ids.has(str(line.id)):return false
	if not line.contact_verified:return not replaying and _rail_path_clear(from,to)
	# A catalogue datum alone cannot authorize a remembered or moved rail.
	if not _grind_native_crown(line,distance,_grind_rail_intent_rid if replaying else RID()):return false
	if _rail_path_clear(from,to):return true
	var rise:=to.y-from.y
	if motion.y<=0.0 or rise<=0.0 or rise>GrindRideSource.BELOW_ALLOWANCE:return false
	var lifted:=Vector3(from.x,to.y,from.z)
	# Only the existing14cm lower band may use this two-leg native body path.
	# No segment excludes the target, other rails, walls or ceilings.
	return _grind_capsule_segment_clear(from,lifted,line) and _grind_capsule_segment_clear(lifted,to,line)


func _grind_native_crown(line,distance: float,expected_rid: RID=RID()) -> bool:
	var crown: Vector3=line.contact_at(distance)
	var up: Vector3=line.contact_up(distance)
	if not crown.is_finite() or not up.is_finite() or up.y<=0.0:return false
	var side: Vector3=up.cross(line.dir_at(distance)).normalized()
	for lateral: float in GRIND_SUPPORT_SIDES:
		var at:=crown+side*lateral
		_grind_support_ray.from=at+up*0.04
		_grind_support_ray.to=at-up*0.08
		var hit:=get_world_3d().direct_space_state.intersect_ray(_grind_support_ray)
		if hit.is_empty() or not _only_intended_grind_hits([hit],line):continue
		if expected_rid.is_valid() and hit.collider.get_rid()!=expected_rid:continue
		if Vector3(hit.normal).dot(up)>0.98 and absf((Vector3(hit.position)-crown).dot(up))<=GrindStyle.CONTACT_TOLERANCE:return true
	return false


func _grind_capsule_rest_clear(at: Vector3,line) -> bool:
	var frame:=global_transform;frame.origin=at
	if not test_move(frame,Vector3.ZERO,_grind_capsule_rest,GrindStyle.CONTACT_TOLERANCE,true,16):return true
	if _grind_capsule_rest.get_collision_count()>=16 or not is_finite(_grind_capsule_rest.get_depth()) \
		or _grind_capsule_rest.get_depth()>GrindStyle.CONTACT_TOLERANCE*1.01 \
		or _grind_capsule_rest.get_travel().length()>GrindStyle.CONTACT_TOLERANCE*2.0:return false
	for index: int in _grind_capsule_rest.get_collision_count():
		if not _only_intended_grind_hits([{"collider":_grind_capsule_rest.get_collider(index)}],line):return false
	return true


func _grind_capsule_segment_clear(from: Vector3,to: Vector3,line) -> bool:
	if not _grind_capsule_rest_clear(from,line) or not _grind_capsule_rest_clear(to,line):return false
	var query:=_recovery_shape_query
	var saved_transform:=query.transform;var saved_motion:=query.motion
	var saved_margin:=query.margin;var saved_mask:=query.collision_mask
	query.transform=global_transform*Transform3D(Basis.IDENTITY,_body_collision.position)
	query.transform.origin+=from-global_position
	query.motion=to-from;query.margin=0.0;query.collision_mask=collision_mask
	var sweep:=get_world_3d().direct_space_state.cast_motion(query)
	query.transform=saved_transform;query.motion=saved_motion
	query.margin=saved_margin;query.collision_mask=saved_mask
	return sweep.size()==2 and sweep[0]>=0.9999


func _align_to_travel() -> void:
	if Vector2(velocity.x, velocity.z).length_squared() > 0.001:
		rotation.y = atan2(-velocity.x, -velocity.z)+(PI if grinding and _rail_backwards else 0.0)


func _tick_grind(delta: float) -> void:
	if not _controls_enabled:
		return
	_steering = Input.get_axis("steer_left", "steer_right")
	if _trick_entries_enabled and _jump_buffer_remaining > 0.0:
		_jump_buffer_remaining = 0.0
		_release_grind(true)
		return
	if Input.is_action_pressed("grind"):
		_grind_grip_age+=delta
		if _grind_grip_age>=.12:_grind_held_exit=true
	if _grind_held_exit and not Input.is_action_pressed("grind"):
		_release_grind(false)
		return
	if Input.is_action_just_pressed("grind"):
		_grind_buffer_remaining = 0.0
		_grind_held_armed = false
		_release_grind(false)
		return
	_try_grind_extension()
	_grind_hold_age+=delta
	var hold_tick := maxi(0,int(floor((_grind_hold_age+0.000001)/HOLD_INTERVAL)))
	var hold_award := mini(HOLD_LIMIT-_grind_hold_points,maxi(0,hold_tick-_grind_hold_tick)*HOLD_AWARD)
	_grind_hold_tick=hold_tick
	if hold_award>0:
		_grind_hold_points+=hold_award
		hold_points_awarded.emit(hold_award)
	# Short collision sweeps follow bends instead of cutting through scenery.
	var steps := maxi(1, ceili(delta * maxf(_grind.speed, 1.0) / 0.20))
	for i in steps:
		var result: String = _grind.step(delta / steps, _steering)
		var target: Vector3 = _grind.position()
		if result == "bail" or not _rail_path_clear(global_position, target):
			begin_bail("rail_balance_or_obstruction")
			_grind_cooldown = GRIND_RECAPTURE_DELAY
			return
		if grind_style_id != "rail_grind":
			var previous_board: Transform3D = _grind_contact.board_transform
			if not _solve_grind_contact(_grind_contact,_grind.line,_grind.distance,_grind.direction,_grind_style_yaw,grind_style_id,0.0) \
					or not _grind_board_path_clear(previous_board,_grind_contact.board_transform,_grind.line,_grind.distance) \
					or (_requires_model_grind_clearance(grind_style_id) and not _grind_clearance.allows_path(previous_board,_grind_contact,_grind.line.contact_up(_grind.distance))):
				begin_bail("grind_board_obstruction")
				_grind_cooldown = GRIND_RECAPTURE_DELAY
				return
		if _requires_model_grind_clearance(grind_style_id) and not _grind_clearance.allows(_grind_contact,_grind.line.contact_up(_grind.distance)):
			begin_bail("grind_model_obstruction")
			return
		global_position = target
		velocity = _grind.travel_velocity()
		speed=-_grind.speed if _rail_backwards else _grind.speed
		if _grind_transfer.active:
			if not _solve_grind_contact(_grind_candidate_contact,_grind.line,_grind.distance,_grind.direction,float(_grind_pending.yaw),str(_grind_pending.pose_id),0.0):
				begin_bail("unsupported_grind_transfer")
				return
			var transfer:Dictionary=_grind_transfer.step(delta/steps,_grind_candidate_contact,_grind.line.contact_up(_grind.distance),_grind_clearance)
			if bool(transfer.get("failed",false)):
				begin_bail("blocked_grind_transfer")
				return
			if bool(transfer.get("complete",false)):_complete_grind_transfer()
			speed=-_grind.speed if _rail_backwards else _grind.speed
		_align_to_travel()
		if result != "riding":
			_release_grind(false)
			return


func _release_grind(jump: bool) -> void:
	var exit_board:Transform3D=_grind_transfer.board_transform if _grind_transfer.active else _grind_contact.board_transform
	var named := grind_style_id != "" and grind_style_id != "rail_grind"
	var exit_yaw := _stance_angle
	if named:
		# Preserve the actually drawn rigid chord at bends, not just the input
		# quarter-turn. Reuse the existing short visual offset decay on release.
		var contact_frame: Basis = global_basis.inverse() * exit_board.basis
		var local_forward := -contact_frame.z
		local_forward.y = 0.0
		if local_forward.length_squared() > .000001:
			exit_yaw = Vector3.FORWARD.signed_angle_to(local_forward.normalized(),Vector3.UP)
		_grind_visual_offset = exit_board.origin - exit_board.basis * Vector3(0,.12,0) - global_position
		_surface_pitch = contact_frame.get_euler().x
		_visual.rotation.z = contact_frame.get_euler().z
	velocity = _grind.travel_velocity()
	_grind_transfer.reset()
	_grind_pending.clear()
	_grind_exact_pose=false
	_grind.stop()
	_clear_grind_style()
	_grind_cooldown = GRIND_RECAPTURE_DELAY
	if not jump: _launch_id="ollie"
	_begin_air()
	if named:
		_air_grind_yaw = angle_difference(_stance_angle,exit_yaw)
	speed=Vector3(velocity.x,0,velocity.z).dot(-global_basis.z)
	if jump:
		_set_launch_mode()
		velocity+=global_basis.x*_steering*4.0
		velocity.y = maxf(0.0, velocity.y) + _launch_impulse
		_ollie_pose_remaining = OLLIE_POSE_SECONDS
		combo_link_started.emit()
		_emit_trick(_launch_id)


func get_camera_support_frame() -> Basis:
	# Base travel frame only: no scored yaw, board flip or body special.
	if not Engine.is_in_physics_frame() and is_physics_interpolated_and_enabled():
		return _previous_ramp_air_frame.orthonormalized().slerp(_ramp_air_frame.orthonormalized(),Engine.get_physics_interpolation_fraction())
	return _ramp_air_frame


func get_camera_support_up() -> Vector3:
	return get_camera_support_frame().y.normalized()


func _update_pose(delta: float) -> void:
	# These are rigid presentation frames. Repeated Euler/basis edits otherwise
	# retain tiny scale errors across long runs and eventually reject real rail
	# transfers or feed a nonrotation into landing-frame interpolation.
	_visual.basis = _visual.basis.orthonormalized()
	_board_visual.basis = _board_visual.basis.orthonormalized()
	_rider_visual.basis = _rider_visual.basis.orthonormalized()
	var was_flipping := _flip_remaining > 0.0
	var was_grabbing := _grab_remaining > 0.0
	_previous_ramp_air_frame=_ramp_air_frame
	_ollie_pose_remaining=maxf(0.0,_ollie_pose_remaining-delta)
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
	var visual_yaw := _spin_angle + _stance_angle + _air_grind_yaw - PI * (_revert_pose_remaining / REVERT_DURATION)
	_visual.rotation.y = visual_yaw
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
	if airborne and _launch_age < 0.24 and _launch_id == "nollie" and _flip_remaining <= 0.0:
		board_pitch = -deck_direction * 0.22 * sin(PI * _launch_age / 0.24)
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
	var ordinary_pop := airborne and not _ramp_air and _ollie_pose_remaining > 0.0 \
		and _flip_remaining <= 0.0 and _grab_remaining <= 0.0 and _launch_id != "nollie"
	if ordinary_pop: board_pitch += TrickAnimation.ollie_pitch(OLLIE_POSE_SECONDS - _ollie_pose_remaining)
	_board_visual.rotation.z = board_roll if _flip_remaining > 0.0 or lip_active else lerpf(_board_visual.rotation.z, board_roll, 1.0 - exp(-16.0 * delta))
	_board_visual.rotation.x = board_pitch if _flip_remaining > 0.0 or ordinary_pop else lerpf(_board_visual.rotation.x, board_pitch, 1.0 - exp(-16.0 * delta))
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
		desired_pitch = atan2(velocity.y * (-1.0 if _rail_backwards else 1.0), Vector2(velocity.x, velocity.z).length())
	elif lip_active:
		desired_pitch = 0.0
	elif _feature_transition.active:
		var support: Vector3 = global_basis.inverse() * _feature_transition.normal
		desired_pitch = atan2(support.z, support.y)
	elif _native_floor_valid and is_on_floor():
		var local_normal := global_basis.inverse() * _native_floor_normal()
		desired_pitch = atan2(local_normal.z, local_normal.y)
	var curved_support: bool = _feature_transition.active and _feature_transition.state == "surface"
	var native_support := _native_floor_valid and not transition_active and is_on_floor() and not grinding and not wallriding \
		and (bail_active or (not airborne and not _force_air_tick))
	var board_floor := _native_board_floor() if native_support and not bail_active and not setup_active \
		and not manual_active and not skitching else {}
	if curved_support or native_support:
		# Keep the visible wheels in the real support frame. Pitch-only lag made
		# neutral bowl carving and ordinary cross-slopes penetrate on one side
		# and float on the other despite correct native capsule contact.
		var ground_normal: Vector3 = _feature_transition.normal if curved_support \
			else (board_floor.normal if not board_floor.is_empty() else _native_floor_normal())
		var contact_normal: Vector3 = (global_basis.inverse() * ground_normal).normalized()
		if Vector2(contact_normal.y, contact_normal.z).length_squared() > 0.00000001:
			_surface_pitch = atan2(contact_normal.z, contact_normal.y)
		var contact_roll := -asin(clampf(contact_normal.x, -1.0, 1.0))
		var support_basis := Basis.from_euler(Vector3(_surface_pitch, 0.0, contact_roll))
		_air_support_basis = support_basis
		_visual.basis = support_basis * Basis(Vector3.UP, visual_yaw)
	else:
		# The board's bearing is already on the finite rail. Its longitudinal
		# frame must agree on the first caught frame and an actual 180 pivot;
		# delaying pitch would drive a truck through the slope while it turns.
		if grinding:
			_surface_pitch = desired_pitch
			# Turn the visible pivot within the rail plane. World-up yaw before
			# tilt would rotate the board out of a sloped bearing surface.
			_visual.basis = Basis(Vector3.RIGHT,_surface_pitch) \
				* Basis(Vector3.UP,visual_yaw) \
				* Basis(Vector3.BACK,-grind_balance*0.35)
		else:
			_surface_pitch = lerpf(_surface_pitch, desired_pitch, 1.0 - exp(-14.0 * delta))
			_visual.rotation.x = _surface_pitch
	var air_visual_offset := Vector3.ZERO
	var air_landing_support: Dictionary = {}
	if airborne and not _ramp_air and not grinding and not wallriding and not bail_active:
		# Read the finite native surface below the flight. Anticipating that
		# frame preserves a continuous catch; rotating the entire figure only
		# after contact caused metre-long head jumps on bowl returns.
		var prediction := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.2,
			global_position - Vector3.UP * 3.0, collision_mask)
		prediction.exclude = [get_rid()]
		var upcoming := get_world_3d().direct_space_state.intersect_ray(prediction)
		var upcoming_normal: Vector3 = _feature_transition.normal if transition_active else Vector3.UP
		var has_upcoming := not upcoming.is_empty() and Vector3(upcoming.normal).y > 0.05
		if has_upcoming: upcoming_normal = upcoming.normal
		if has_upcoming and not transition_active and velocity.y<0.0 \
				and upcoming_normal.y>0.999 and _flip_remaining<=0.0 and _grab_remaining<=0.0 \
				and _special_remaining<=0.0 and _ollie_pose_remaining<=0.0 \
				and not manual_active and not setup_active and not skitching and not lip_active:
			var gap_to_landing: float=(global_position-Vector3(upcoming.position)).dot(upcoming_normal)
			if gap_to_landing>=0.0 and gap_to_landing<=0.35: air_landing_support=upcoming
		var local_up := global_basis.inverse() * upcoming_normal
		var pitch := atan2(local_up.z, local_up.y)
		var target_basis := Basis.from_euler(Vector3(pitch, 0, -asin(clampf(local_up.x, -1, 1))))
		if has_upcoming and _feature_transition.active and _feature_transition.feature.wrap_lateral and velocity.y<0.0:
			# A carving bowl catch also changes heading to the landed tangent.
			# Anticipate that whole frame, rather than snapping the torso's yaw
			# on contact after having anticipated only the floor tilt.
			var landing_forward := velocity.slide(upcoming_normal).normalized()
			if landing_forward.length_squared()>0.5:
				var landing_right := landing_forward.cross(upcoming_normal).normalized()
				var landing_frame := Basis(landing_right,upcoming_normal,-landing_forward).orthonormalized()
				target_basis = (global_basis.inverse()*landing_frame).orthonormalized()
		if has_upcoming and not transition_active:
			var distance_to_plane := (global_position - Vector3(upcoming.position)).dot(upcoming_normal)
			var anticipation := 1.0 - smoothstep(0.22, 1.2, distance_to_plane)
			var capsule := (get_node("BodyCollision") as CollisionShape3D).shape as CapsuleShape3D
			var foot_offset := maxf(0, capsule.radius * (1.0 - upcoming_normal.y) - 0.008)
			air_visual_offset = -upcoming_normal * foot_offset * anticipation
		var angle := _air_support_basis.get_rotation_quaternion().angle_to(target_basis.get_rotation_quaternion())
		_air_support_basis = _air_support_basis.slerp(target_basis, minf(1, 4.5 * delta / maxf(angle, 0.000001))).orthonormalized()
		_visual.basis = _air_support_basis * Basis(Vector3.UP, visual_yaw)
	if wallriding:
		_visual.rotation.z = clampf(-(global_basis.inverse() * _wall.normal).x * 0.65, -0.65, 0.65)
	if not (curved_support or native_support) and (not airborne or wallriding) and not bail_active:
		_air_support_basis = (_visual.basis * Basis(Vector3.UP, -visual_yaw)).orthonormalized()
	_grind_visual_offset *= exp(-delta / 0.045)
	_visual.position = global_basis.inverse() * (air_visual_offset + _grind_visual_offset)
	if native_support:
		# An upright capsule's rounded end lifts its origin on steep floors.
		# Place only the presentation at the actual native support plane before
		# solving planted feet and palms; never move the physical player for it.
		var support_normal: Vector3 = board_floor.normal if not board_floor.is_empty() else _native_floor_normal()
		var floor_hit := board_floor if not board_floor.is_empty() else _native_floor_hit(support_normal)
		if not floor_hit.is_empty() and Vector3(floor_hit.normal).dot(support_normal) > 0.98:
			_visual.position = global_basis.inverse() * (Vector3(floor_hit.position) + support_normal * 0.008 - global_position)
	if _special_remaining > 0.0:
		_visual.rotation.x += _special_axis(float(_special_definition.get("special_body_pitch", 0.0)), special_progress)
		_visual.rotation.y += _special_axis(float(_special_definition.get("special_body_yaw", 0.0)), special_progress)
		_visual.rotation.z += _special_axis(float(_special_definition.get("special_body_roll", 0.0)), special_progress)
		# Rotate the visible rider/board around the body, preserving the collision origin.
		var tumble_pivot := Vector3.UP * 0.8
		_visual.position = tumble_pivot - _visual.basis * tumble_pivot
	_ramp_air_frame = global_basis * _air_support_basis if _feature_transition.active else global_basis * Basis(Vector3.RIGHT,_surface_pitch)
	if airborne and _ramp_air:
		# Camera orbit and rider orientation are independent. The camera keeps its
		# agreed apex arc; the assisted body return has its own slower curve.
		var air_turn_progress := smoothstep(-2.0,2.0,-velocity.y)
		var flight_forward := _ramp_launch_forward.rotated(_ramp_air_normal,PI*air_turn_progress).normalized()
		var right := flight_forward.cross(_ramp_air_normal).normalized()
		_ramp_air_frame = Basis(right,_ramp_air_normal,-flight_forward).orthonormalized()
		# Spread the assisted return over ~0.55s at current gravity instead
		# of the old ~0.18s pivot. Keep the body outside the departed wall.
		var body_progress := smoothstep(-6.0, 6.0, -velocity.y)
		var body_forward := _ramp_launch_forward.rotated(_ramp_air_normal, PI * body_progress)
		var body_right := body_forward.cross(_ramp_air_normal).normalized()
		var body_frame := Basis(body_right, _ramp_air_normal, -body_forward).orthonormalized()
		_visual.basis = global_basis.inverse()*body_frame*Basis(Vector3.UP,visual_yaw)
	if _transition.active:
		var toe: Transform3D = _transition.feature.transform
		var forward: Vector3 = _transition.travel_velocity().normalized()
		if forward.length_squared() < 0.5:
			forward = toe.basis * Vector3(0, sin(_transition.theta), -cos(_transition.theta)) * _transition_facing
		var right := forward.cross(transition_normal).normalized()
		var contact_basis := Basis(right, transition_normal, -forward).orthonormalized()
		_ramp_air_frame = contact_basis
		_visual.basis = global_basis.inverse() * contact_basis * Basis(Vector3.UP, visual_yaw)
	if lip_active:
		_visual.rotation.z = -lip_balance * 0.20
	if bailing:
		var fall := clampf(bail_elapsed / .28, 0.0, 1.0)
		_rider_visual.position.y = lerpf(_rider_visual.position.y,.22*sin(PI*fall),1.0-exp(-12.0*delta))
		_rider_visual.rotation.z = lerp_angle(_rider_visual.rotation.z,(.20 if _reduced_motion else .65)*sin(PI*fall),1.0-exp(-12.0*delta))
	else:
		_rider_visual.rotation.z = 0.0
	if grinding and (_grind_contact.valid or _grind_transfer.active):
		# Exact declared contacts take precedence over entry mesh smoothing and
		# independent slope/balance rotations. During an unweighted transfer,
		# display only the helper's natively tested frame; feet follow the deck.
		var displayed_grind: Transform3D = _grind_transfer.board_transform if _grind_transfer.active else _grind_contact.board_transform
		_board_visual.rotation = Vector3.ZERO
		_board_visual.position.y = .12
		_visual.basis = global_basis.inverse() * displayed_grind.basis
		_visual.position = to_local(displayed_grind.origin - displayed_grind.basis * Vector3(0,.12,0))
		_grind_visual_offset = Vector3.ZERO
	if bailing:
		var target_basis:=_visual.basis.orthonormalized()
		var angle:=_bail_visual_basis.get_rotation_quaternion().angle_to(target_basis.get_rotation_quaternion())
		var blend:=minf(1.0-exp(-12.0*delta),6.0*delta/maxf(angle,.000001))
		_bail_visual_basis=_bail_visual_basis.slerp(target_basis,blend).orthonormalized()
		_bail_visual_offset=_bail_visual_offset.move_toward(_visual.position,4.5*delta)
		_visual.basis=_bail_visual_basis
		_visual.position=_bail_visual_offset
	_visual_rig.animate(delta, {"airborne": airborne, "grab": _grab_remaining > 0.0,
		"flip": _flip_remaining > 0.0, "speed": absf(speed), "travel_sign": signf(speed), "manual": manual_active,
		"grind": grinding, "push": not bailing and _controls_enabled and Input.is_action_pressed("push"),
		"brake": not bailing and _controls_enabled and Input.is_action_pressed("brake"),
		"steering": _steering, "manual_balance": manual_balance, "grind_balance": grind_balance,
		"revert_remaining": _revert_pose_remaining, "special_id": _special_id,
		"native_grind_contact": grinding and (_grind_contact.valid or _grind_transfer.active), "bail": _bail_pose_weight(), "crouch": maxf(0.35, ollie_charge) if crouching else 0.0,
		"ramp_turn": smoothstep(-6.0,6.0,-velocity.y) if airborne and _ramp_air else -1.0,
		"manual_id":manual_trick_id, "lip_id":lip_id, "lip_progress":_lip_elapsed,
		"special_progress": special_progress, "flip_id": flip_trick_id, "flip_progress": flip_progress,
		"grab_id": grab_trick_id, "grab_side": _grab_definition.get("grab_side", -1.0),
		"grab_target": _grab_definition.get("grab_target", Vector3(-0.128, 0.022, -0.035)),
		"grind_id": grind_trick_id, "grind_yaw": _grind_definition.get("grind_yaw", 0.0),
		"grind_pitch": _grind_definition.get("grind_pitch", 0.0), "manual_sign": manual_sign,
		"deck_yaw": _board_visual.rotation.y if not grinding else 0.0,
		"rest_deck_yaw": _deck_yaw, "takeoff_mode": takeoff_mode, "launch_id": _launch_id, "launch_age": _launch_age, "crouching": crouching, "ollie_charge": ollie_charge,
		"weighted_ollie_air": _weighted_ollie_air, "weighted_ollie_duration": _weighted_ollie_duration,
		"powersliding": powersliding, "wallriding": wallriding, "wall_normal": _wall.normal,
		"transition_active": transition_active, "lip_active": lip_active,
		"manual_walk": manual_definition.get("manual_walk", false),
		"manual_roll": manual_definition.get("manual_roll", 0.0),
		"manual_foot_lift": manual_definition.get("manual_foot_lift", 0.0),
		"manual_definition": manual_definition, "grab_definition": _grab_definition,
		"special_definition": _special_definition, "lip_definition": _lip_definition,
		"lip_ground_point": _feature_transition.lip_frame().get("point", global_position) if _feature_transition.lip else _lip_feature.get("coping_contact",global_position),
		"lip_normal": Vector3.UP, "setup_active": setup_active, "setup_id": setup_id,
		"setup_phase": setup_phase, "setup_ground_point": _setup.ground_point, "setup_normal": _setup.normal,
		"bail_active": bail_active, "bail_phase": bail_progress, "bail_ground_point": _last_supported_position,
		"skitching": skitch_caught, "skitch_caught": skitch_caught,
		"skitch_grips": _skitch.hand_targets() if skitching and _skitch.has_method("hand_targets") else [],
		"skitch_normal": _skitch.hand_normal() if skitching and _skitch.has_method("hand_normal") else Vector3.ZERO,
		"bail_normal": Vector3.UP,
		"bail_recovery_transform": Transform3D(Basis(Vector3.UP, -PI / 2.0 + 0.28), Vector3.ZERO)})

	if wallriding: _place_wall_wheels()
	if transition_active and not airborne and not lip_active and not grinding:
		_place_transition_wheels()
	elif native_support and manual_active and not bail_active and not setup_active and not skitching:
		_place_manual_wheels()
	if not air_landing_support.is_empty(): _place_air_landing_wheels(air_landing_support)
	_place_obstacle_wheels(delta)
	_obstacle_arm_fit.apply(delta)


func _place_obstacle_wheels(delta: float) -> void:
	# The upright locomotion capsule is narrower than the actual deck/shoes.
	# Reuse its real vertical-wall contacts to fit only the connected figure;
	# an obstacle must never move the physical actor or split feet from board.
	var manual_pose: bool = manual_active or _visual_rig._manual_blend>0.0001
	if manual_pose and (manual_active or _obstacle_manual_continuation) \
			and not airborne and _native_floor_valid and is_on_floor() \
			and not _force_air_tick and _native_floor_normal().y>0.999 \
			and not (transition_active or grinding or wallriding or bail_active or setup_active \
				or skitching or lip_active or powersliding) \
			and _flip_remaining<=0.0 and _grab_remaining<=0.0 and _special_remaining<=0.0 \
			and _ollie_pose_remaining<=0.0:
		_place_obstacle_manual_wheels(delta)
		return
	if manual_pose:
		_obstacle_visual_offset=Vector3.ZERO
		_obstacle_ollie_continuation=false
		_obstacle_manual_continuation=false
		return
	if airborne and _obstacle_manual_continuation:
		# This grounded slice must not arm a new Manual-origin airborne fit.
		_obstacle_visual_offset=Vector3.ZERO
		_obstacle_ollie_continuation=false
		_obstacle_manual_continuation=false
		return
	_obstacle_manual_continuation=false
	if manual_active or transition_active or grinding or wallriding or bail_active \
			or setup_active or skitching or lip_active or powersliding \
			or _special_remaining>0.0:
		_obstacle_visual_offset=Vector3.ZERO
		_obstacle_ollie_continuation=false
		return
	if airborne:
		# Continue only a real flat-ground jump's already proven fit into a
		# Ollie/Flip/Grab. Every proposal needs fresh finite board/shoe
		# clearance; only a Grab may derive a bounded live-face correction.
		if _obstacle_ollie_continuation and not _ramp_air and _launch_id=="ollie" \
				and _obstacle_visual_offset.is_finite() and _obstacle_visual_offset.length_squared()>0.0 \
				and _obstacle_visual_offset.length()<=0.18:
			var decay := _obstacle_visual_offset*exp(-maxf(0.0,delta)/0.045)
			if decay.length_squared()<0.0000000001: decay=Vector3.ZERO
			for attempt: int in 2:
				var candidate := decay if attempt==0 else _obstacle_visual_offset
				if attempt==1 and candidate==decay: continue
				if not _obstacle_air_clear(candidate): continue
				_visual.position+=global_basis.inverse()*candidate
				_obstacle_visual_offset=candidate
				if candidate==Vector3.ZERO: _obstacle_ollie_continuation=false
				return
			if _grab_remaining>0.0:
				var candidate := _obstacle_grab_air_offset(_obstacle_visual_offset)
				if candidate!=Vector3.ZERO:
					_visual.position+=global_basis.inverse()*candidate
					_obstacle_visual_offset=candidate
					return
		_obstacle_visual_offset=Vector3.ZERO
		_obstacle_ollie_continuation=false
		return
	if not _native_floor_valid or not is_on_floor() or _force_air_tick \
			or _flip_remaining>0.0 or _grab_remaining>0.0 \
			or _ollie_pose_remaining>0.0 or _native_floor_normal().y<0.999:
		_obstacle_visual_offset=Vector3.ZERO
		_obstacle_ollie_continuation=false
		return
	var offset := _obstacle_visual_offset*exp(-maxf(0.0,delta)/0.045)
	if offset.length_squared()<0.0000000001:offset=Vector3.ZERO
	if offset==Vector3.ZERO and not is_on_wall():
		_obstacle_visual_offset=Vector3.ZERO
		_obstacle_ollie_continuation=false
		return
	var geometry: Dictionary=_visual_rig.board_contact_geometry()
	var planes: Array[Vector4]=[]
	for slide_index: int in get_slide_collision_count():
		var contact := get_slide_collision(slide_index)
		for index: int in contact.get_collision_count():
			var normal := contact.get_normal(index)
			if not normal.is_finite() or absf(normal.y)>0.001:continue
			normal=Vector3(normal.x,0,normal.z).normalized()
			if normal.length_squared()<0.99:continue
			var point := contact.get_position(index)
			planes.append(Vector4(normal.x,normal.y,normal.z,point.dot(normal)))
			var gap := INF
			for vertex: Vector3 in geometry.support_points:
				gap=minf(gap,(_board_visual.to_global(vertex)+offset-point).dot(normal))
			# Cupsole XZ encloses the upper's XZ for these authored shoes. A
			# horizontal plane therefore needs no new hull or per-frame mesh scan.
			for leg: Dictionary in _visual_rig._legs:
				for vertex: Vector3 in _visual_rig._sole_points:
					gap=minf(gap,(leg.foot.to_global(vertex)+offset-point).dot(normal))
			if is_finite(gap) and gap<GROUND_PRESENTATION_SKIN:
				offset+=normal*(GROUND_PRESENTATION_SKIN-gap)
	if offset.length_squared()<0.0000000001:
		_obstacle_visual_offset=Vector3.ZERO
		_obstacle_ollie_continuation=false
		return
	if not offset.is_finite() or offset.length()>0.18:
		_obstacle_visual_offset=Vector3.ZERO
		_obstacle_ollie_continuation=false
		return
	var floor_y := _visual.global_position.y-GROUND_PRESENTATION_SKIN
	# A collision rebound can release the capsule while the longer deck still
	# needs clearance. If decay is obstructed, retain the previous safe offset
	# only after validating it again; resetting it would snap through the wall.
	for attempt: int in 2:
		var candidate := offset if attempt==0 else _obstacle_visual_offset
		if candidate==Vector3.ZERO or (attempt==1 and candidate==offset):continue
		if not _obstacle_offset_supported(geometry,candidate,planes,floor_y):continue
		_visual.position+=global_basis.inverse()*candidate
		_obstacle_visual_offset=candidate
		_obstacle_ollie_continuation=false
		return
	_obstacle_visual_offset=Vector3.ZERO
	_obstacle_ollie_continuation=false


func _place_obstacle_manual_wheels(delta: float) -> void:
	# Only the two ordinary axle manuals use this separate flat-floor path.
	# Residual pose continuation requires a fit actually earned by that Manual.
	var valid_id := manual_trick_id in ["manual","nose_manual"]
	var prior := _obstacle_visual_offset
	var valid_prior := prior.is_finite() and prior.length_squared()>0.0 and prior.length()<=0.18
	var candidate := Vector3.ZERO
	var accepted := false
	if valid_id and (manual_active or (_obstacle_manual_continuation and valid_prior)):
		var geometry: Dictionary=_visual_rig.board_contact_geometry()
		if valid_prior:
			var decay := prior*exp(-maxf(0.0,delta)/0.045)
			if decay.length_squared()<0.0000000001: decay=Vector3.ZERO
			if _obstacle_manual_supported(geometry,decay):
				candidate=decay
				accepted=true
		if not accepted:
			# Derive the current finite minimum before retaining a safe but
			# oversized prior fit, so a fading axle pose cannot leave a snap
			# when the ordinary ground solver resumes at the end of its blend.
			candidate=_obstacle_manual_contact_offset(geometry)
			if candidate!=Vector3.ZERO and _obstacle_manual_supported(geometry,candidate):
				accepted=true
			else:
				candidate=Vector3.ZERO
		if not accepted and valid_prior and _obstacle_manual_supported(geometry,prior):
			candidate=prior
	if candidate!=Vector3.ZERO:
		_visual.position+=global_basis.inverse()*candidate
	_obstacle_visual_offset=candidate
	_obstacle_ollie_continuation=false
	_obstacle_manual_continuation=candidate!=Vector3.ZERO


func _obstacle_manual_supported(geometry: Dictionary,offset: Vector3) -> bool:
	if geometry.wheels.size()!=4: return false
	var ray := _recovery_floor_query
	var saved_from := ray.from
	var saved_to := ray.to
	var saved_mask := ray.collision_mask
	ray.collision_mask=collision_mask
	var space := get_world_3d().direct_space_state
	var count := 0
	var valid := absf(_board_visual.rotation.x)>0.000001
	var floor_hit: Dictionary={}
	for wheel: Dictionary in geometry.wheels:
		if Vector3(wheel.center).z*_board_visual.rotation.x<=0.0: continue
		count+=1
		var at: Vector3=_board_visual.to_global(wheel.center)+offset
		ray.from=at+Vector3.UP*0.16
		ray.to=at-Vector3.UP*0.20
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or Vector3(hit.get("normal",Vector3.ZERO)).y<0.999:
			valid=false
			break
		var point: Vector3=hit.position
		var normal: Vector3=hit.normal
		if floor_hit.is_empty():
			floor_hit=hit
		elif hit.get("rid")!=floor_hit.get("rid") or hit.get("shape")!=floor_hit.get("shape") \
				or normal.dot(Vector3(floor_hit.normal))<0.999 \
				or absf((point-Vector3(floor_hit.position)).dot(floor_hit.normal))>0.001:
			valid=false
			break
		var lowest := INF
		for vertex: Vector3 in wheel.points:
			lowest=minf(lowest,(_board_visual.to_global(vertex)+offset-point).dot(normal))
		# Same flat support as the actually planted axle: a lower step cannot
		# authorize floating, and a raised step cannot bury its finite tyre.
		if lowest<GROUND_PRESENTATION_SKIN-0.00001 or lowest>GROUND_PRESENTATION_SKIN+0.001:
			valid=false
			break
	ray.from=saved_from
	ray.to=saved_to
	ray.collision_mask=saved_mask
	return valid and count==2 and _obstacle_manual_clear(offset,floor_hit)


func _obstacle_manual_floor_shape(hit: Dictionary) -> Dictionary:
	# The native shape index, not its entire body, owns this exception. A
	# compound floor's separate wall/raised shape must still block the fit.
	var body := hit.get("collider") as StaticBody3D
	if body==null: return {}
	var shape_index := int(hit.get("shape",-1))
	if shape_index<0: return {}
	var owner := body.shape_find_owner(shape_index)
	var count := body.shape_owner_get_shape_count(owner)
	if count>8: return {}
	var shape: Shape3D
	for index: int in count:
		if body.shape_owner_get_shape_index(owner,index)==shape_index:
			shape=body.shape_owner_get_shape(owner,index)
			break
	if shape==null: return {}
	var pose := body.global_transform*body.shape_owner_get_transform(owner)
	var normal: Vector3=hit.normal
	if not normal.is_finite() or normal.y<0.999 or not is_equal_approx(normal.length_squared(),1.0): return {}
	var maximum := -INF
	if shape is BoxShape3D:
		var half: Vector3=shape.size*0.5
		maximum=pose.origin.dot(normal)+absf(pose.basis.x.dot(normal))*half.x \
			+absf(pose.basis.y.dot(normal))*half.y+absf(pose.basis.z.dot(normal))*half.z
	elif shape is ConvexPolygonShape3D:
		var points: PackedVector3Array=shape.points
		if points.is_empty() or points.size()>64: return {}
		for point: Vector3 in points: maximum=maxf(maximum,(pose*point).dot(normal))
	else:
		return {}
	# Use the exact primitive support plane, not the rounded native ray hit.
	# Every point of this finite shape is at/below maximum; the complete
	# query geometry must stay at least the unchanged native margin above it.
	if not is_finite(maximum): return {}
	return {"normal":normal,"maximum":maximum,"rid":hit.rid,"shape":shape_index}


func _obstacle_manual_clear(offset: Vector3,hit: Dictionary) -> bool:
	var floor_shape := _obstacle_manual_floor_shape(hit)
	if floor_shape.is_empty(): return false
	var hull: Shape3D=_visual_rig.board_contact_geometry().get("convex_shape")
	if hull==null: return false
	var query := _grind_board_query
	var saved_shape := query.shape
	var saved_size := _grind_board_box.size
	var saved_margin := query.margin
	var saved_transform := query.transform
	var saved_motion := query.motion
	query.margin=GROUND_PRESENTATION_SKIN-0.00001
	query.motion=Vector3.ZERO
	var space := get_world_3d().direct_space_state
	var clear := true
	for index: int in 3:
		if index==0:
			query.shape=hull
			query.transform=_board_visual.global_transform
		else:
			var bounds: AABB=_obstacle_shoe_bounds[index-1]
			_grind_board_box.size=bounds.size
			query.shape=_grind_board_box
			query.transform=_visual_rig._legs[index-1].foot.global_transform \
				* Transform3D(Basis.IDENTITY,bounds.get_center())
		var pose := query.transform
		pose.origin+=offset
		query.transform=pose
		var normal: Vector3=floor_shape.normal
		var minimum := INF
		if query.shape is ConvexPolygonShape3D:
			# The current authored cached hull has3,729 native points. Read
			# those exact points, not its slightly simplified debug faces.
			var points: PackedVector3Array=query.shape.points
			if points.is_empty() or points.size()>4096:
				clear=false
				break
			var local_normal := pose.basis.transposed()*normal
			for point: Vector3 in points: minimum=minf(minimum,point.dot(local_normal)+pose.origin.dot(normal))
		else:
			var half := _grind_board_box.size*0.5
			minimum=pose.origin.dot(normal)-absf(pose.basis.x.dot(normal))*half.x \
				-absf(pose.basis.y.dot(normal))*half.y-absf(pose.basis.z.dot(normal))*half.z
		if not is_finite(minimum) or minimum-float(floor_shape.maximum)<query.margin:
			clear=false
			break
		var hits := space.intersect_shape(query,8)
		if hits.size()>=8:
			clear=false
			break
		for contact: Dictionary in hits:
			if contact.get("rid")!=floor_shape.rid or int(contact.get("shape",-1))!=int(floor_shape.shape):
				clear=false
				break
		if not clear: break
	_grind_board_box.size=saved_size
	query.shape=saved_shape
	query.margin=saved_margin
	query.transform=saved_transform
	query.motion=saved_motion
	return clear


func _obstacle_manual_contact_offset(geometry: Dictionary) -> Vector3:
	# At most17 DirectSpace queries: a decayed five-call validation, one live
	# rest and face ray, a fresh five-call fit and a retained five-call fallback.
	# Clear ordinary Manual skating adds only one rest query, with no wall fit.
	var hull: Shape3D=geometry.get("convex_shape")
	if hull==null: return Vector3.ZERO
	var query := _grind_board_query
	var saved_shape := query.shape
	var saved_margin := query.margin
	var saved_transform := query.transform
	var saved_motion := query.motion
	query.shape=hull
	query.margin=GROUND_PRESENTATION_SKIN-0.00001
	query.transform=_board_visual.global_transform
	query.motion=Vector3.ZERO
	var space := get_world_3d().direct_space_state
	var rest := space.get_rest_info(query)
	query.shape=saved_shape
	query.margin=saved_margin
	query.transform=saved_transform
	query.motion=saved_motion
	if rest.is_empty(): return Vector3.ZERO
	var hint: Vector3=rest.get("normal",Vector3.ZERO)
	var axis := Vector3(hint.x,0,hint.z).normalized()
	if not axis.is_finite() or axis.length_squared()<0.99: return Vector3.ZERO
	var point: Vector3=rest.point
	var ray := _recovery_floor_query
	var saved_from := ray.from
	var saved_to := ray.to
	var saved_mask := ray.collision_mask
	ray.from=point+axis*(GROUND_PRESENTATION_SKIN*2.0)
	ray.to=point-axis*(GROUND_PRESENTATION_SKIN*2.0)
	ray.collision_mask=query.collision_mask
	var face := space.intersect_ray(ray)
	ray.from=saved_from
	ray.to=saved_to
	ray.collision_mask=saved_mask
	var normal: Vector3=face.get("normal",Vector3.ZERO)
	if face.is_empty() or face.get("rid")!=rest.get("rid") or not normal.is_finite() \
			or absf(normal.y)>0.001 or normal.dot(axis)<0.999: return Vector3.ZERO
	axis=Vector3(normal.x,0,normal.z).normalized()
	point=face.position
	var gap := INF
	for vertex: Vector3 in geometry.support_points:
		gap=minf(gap,(_board_visual.to_global(vertex)-point).dot(normal))
	for index: int in _visual_rig._legs.size():
		var bounds: AABB=_obstacle_shoe_bounds[index]
		var foot: Transform3D=_visual_rig._legs[index].foot.global_transform
		for x: float in [bounds.position.x,bounds.end.x]:
			for y: float in [bounds.position.y,bounds.end.y]:
				for z: float in [bounds.position.z,bounds.end.z]:
					gap=minf(gap,(foot*Vector3(x,y,z)-point).dot(normal))
	var amount := (GROUND_PRESENTATION_SKIN-gap)/normal.dot(axis)
	if not is_finite(amount) or amount<=0.0 or amount>0.18: return Vector3.ZERO
	return axis*amount


func _obstacle_air_clear(offset: Vector3) -> bool:
	# Each proposal has one board and two shoe volume checks. The ordinary
	# air branch tries two; a late Grab may derive one bounded final proposal.
	# Only an existing grounded fit reaches this path; ordinary clear skating
	# adds no work. The skin prevents decay from accepting a near-wall clip.
	var hull: Shape3D=_visual_rig.board_contact_geometry().get("convex_shape")
	if hull==null: return false
	var saved_shape := _grind_board_query.shape
	var saved_size := _grind_board_box.size
	var saved_margin := _grind_board_query.margin
	var saved_transform := _grind_board_query.transform
	_grind_board_query.margin=GROUND_PRESENTATION_SKIN-0.00001
	var board: Transform3D=_board_visual.global_transform
	board.origin+=offset
	# The old box's empty lower nose corner intersects a wall while the real
	# curved kick clears it. Reuse the actual cached whole-board convex hull.
	_grind_board_query.shape=hull
	_grind_board_query.transform=board
	var space := get_world_3d().direct_space_state
	var clear := space.intersect_shape(_grind_board_query,1).is_empty()
	if clear:
		_grind_board_query.shape=_grind_board_box
		for index: int in _visual_rig._legs.size():
			var bounds: AABB=_obstacle_shoe_bounds[index]
			_grind_board_box.size=bounds.size
			var shoe: Transform3D=_visual_rig._legs[index].foot.global_transform \
				* Transform3D(Basis.IDENTITY,bounds.get_center())
			shoe.origin+=offset
			_grind_board_query.transform=shoe
			if not space.intersect_shape(_grind_board_query,1).is_empty():
				clear=false
				break
	_grind_board_box.size=saved_size
	_grind_board_query.shape=saved_shape
	_grind_board_query.margin=saved_margin
	_grind_board_query.transform=saved_transform
	return clear


func _obstacle_grab_air_offset(prior: Vector3) -> Vector3:
	# A late Grab can rotate beyond both previously proven candidates. Fit
	# only along that original axis, never create a new unarmed air fit.
	# Worst case including the prior checks: 6+3+3+1+1+3=17 native calls.
	if not airborne or not _obstacle_ollie_continuation or _ramp_air \
			or _launch_id!="ollie" or _grab_remaining<=0.0 or not prior.is_finite() \
			or prior.length_squared()==0.0 or prior.length()>0.18:
		return Vector3.ZERO
	var hull: Shape3D=_visual_rig.board_contact_geometry().get("convex_shape")
	if hull==null: return Vector3.ZERO
	var query := _grind_board_query
	var saved_shape := query.shape
	var saved_size := _grind_board_box.size
	var saved_margin := query.margin
	var saved_transform := query.transform
	var saved_motion := query.motion
	var ray := _recovery_floor_query
	var saved_from := ray.from
	var saved_to := ray.to
	var saved_mask := ray.collision_mask
	var space := get_world_3d().direct_space_state
	var axis := prior.normalized()
	var ceiling := axis*0.18
	var safe := 1.0
	var unsafe := 1.0
	var critical := -1
	var valid := true
	for index: int in 3:
		if index==0:
			query.shape=hull
			query.transform=_board_visual.global_transform
		else:
			var bounds: AABB=_obstacle_shoe_bounds[index-1]
			_grind_board_box.size=bounds.size
			query.shape=_grind_board_box
			query.transform=_visual_rig._legs[index-1].foot.global_transform \
				* Transform3D(Basis.IDENTITY,bounds.get_center())
		var pose := query.transform
		pose.origin+=ceiling
		query.transform=pose
		query.motion=Vector3.ZERO
		query.margin=GROUND_PRESENTATION_SKIN-0.00001
		if not space.intersect_shape(query,1).is_empty():
			valid=false
			break
		# Cast fractions locate contact, not the query skin. Add only the
		# existing skin after authenticating this contact's finite face.
		query.margin=0.0
		query.motion=-ceiling
		var fractions := space.cast_motion(query)
		if fractions[0]<safe:
			safe=fractions[0]
			unsafe=fractions[1]
			critical=index
	var normal := Vector3.ZERO
	if valid and critical>=0:
		if critical==0:
			query.shape=hull
			query.transform=_board_visual.global_transform
		else:
			var bounds: AABB=_obstacle_shoe_bounds[critical-1]
			_grind_board_box.size=bounds.size
			query.shape=_grind_board_box
			query.transform=_visual_rig._legs[critical-1].foot.global_transform \
				* Transform3D(Basis.IDENTITY,bounds.get_center())
		var pose := query.transform
		pose.origin+=ceiling*(1.0-unsafe)
		query.transform=pose
		query.motion=Vector3.ZERO
		query.margin=0.0
		var rest := space.get_rest_info(query)
		valid=not rest.is_empty()
		if valid:
			var point: Vector3=rest.point
			ray.from=point+axis*(GROUND_PRESENTATION_SKIN*2.0)
			ray.to=point-axis*(GROUND_PRESENTATION_SKIN*2.0)
			ray.collision_mask=query.collision_mask
			var face := space.intersect_ray(ray)
			normal=face.get("normal",Vector3.ZERO)
			valid=not face.is_empty() and face.get("rid")==rest.get("rid") \
				and normal.is_finite() and absf(normal.y)<=0.001 and normal.dot(axis)>=0.999
	else:
		valid=false
	query.shape=saved_shape
	_grind_board_box.size=saved_size
	query.margin=saved_margin
	query.transform=saved_transform
	query.motion=saved_motion
	ray.from=saved_from
	ray.to=saved_to
	ray.collision_mask=saved_mask
	if not valid: return Vector3.ZERO
	var candidate := ceiling*(1.0-safe)+axis*(GROUND_PRESENTATION_SKIN/normal.dot(axis))
	if candidate.length()>0.18 or not _obstacle_air_clear(candidate): return Vector3.ZERO
	return candidate


func _obstacle_offset_supported(geometry: Dictionary,offset: Vector3,planes: Array[Vector4],floor_y: float) -> bool:
	# Sequential corner corrections must still satisfy every earlier actual
	# contact plane; refusing an impossible fit is preferable to oscillation.
	for plane: Vector4 in planes:
		var normal:=Vector3(plane.x,plane.y,plane.z)
		for vertex: Vector3 in geometry.support_points:
			if (_board_visual.to_global(vertex)+offset).dot(normal)-plane.w<GROUND_PRESENTATION_SKIN-0.00001:return false
		for leg: Dictionary in _visual_rig._legs:
			for vertex: Vector3 in _visual_rig._sole_points:
				if (leg.foot.to_global(vertex)+offset).dot(normal)-plane.w<GROUND_PRESENTATION_SKIN-0.00001:return false
	var candidate: Transform3D=_board_visual.global_transform
	candidate.origin+=offset
	var space := get_world_3d().direct_space_state
	# At most two proposals, each with four finite support rays and the reused
	# board query. Ordinary clear skating performs none of these queries.
	for wheel: Dictionary in geometry.wheels:
		var at: Vector3=candidate*Vector3(wheel.center)
		var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.16,at-Vector3.UP*0.20,collision_mask)
		query.exclude=[get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty() or Vector3(hit.normal).y<0.999 or absf(Vector3(hit.position).y-floor_y)>0.001:return false
	return _grind_board_clear(candidate)


func _place_air_landing_wheels(support: Dictionary) -> void:
	# A last descending bowl-air pose can retain enough roll to bury a tyre
	# before the upright capsule lands. Correct only proven finite flat-floor
	# overlap, after the rig has planted its feet; never move the physical body
	# or flatten ordinary clear flight, active tricks or a curved ramp return.
	var wheels: Array=_visual_rig.board_contact_geometry().wheels
	if wheels.size()!=4: return
	var axis: Vector3=support.normal
	if axis.y<=0.999: return
	var point: Vector3=support.position
	var original: Transform3D=_visual.global_transform
	var board_local: Transform3D=original.affine_inverse()*_board_visual.global_transform
	if _air_landing_wheel_gap(original*board_local,wheels,point,axis)>=0.0: return
	var space:=get_world_3d().direct_space_state
	# Every real bearing must have the same finite native landing plane. A
	# centre ray's infinite plane cannot establish support at an edge/wall.
	for wheel: Dictionary in wheels:
		var bearing: Vector3=_board_visual.to_global(wheel.center)
		var query:=PhysicsRayQueryParameters3D.create(bearing+Vector3.UP*.35,bearing-Vector3.UP*.50,collision_mask)
		query.exclude=[get_rid()]
		var hit:=space.intersect_ray(query)
		if hit.is_empty() or Vector3(hit.normal).dot(axis)<0.999 \
				or absf((Vector3(hit.position)-point).dot(axis))>0.001: return
	var overlaps:=false
	for shape: ConvexPolygonShape3D in _floor_wheel_shapes:
		_floor_wheel_query.shape=shape
		_floor_wheel_query.transform=original*board_local
		_floor_wheel_query.motion=Vector3.ZERO
		_floor_wheel_query.margin=0.0
		overlaps=not space.intersect_shape(_floor_wheel_query,1).is_empty() or overlaps
	if not overlaps: return
	var local_axis: Vector3=global_basis.inverse()*axis
	var landing_basis:=Basis.from_euler(Vector3(atan2(local_axis.z,local_axis.y),0,-asin(clampf(local_axis.x,-1,1))))
	var yaw:=_spin_angle+_stance_angle+_air_grind_yaw-PI*(_revert_pose_remaining/REVERT_DURATION)
	var target:=Transform3D(global_basis*landing_basis*Basis(Vector3.UP,yaw),original.origin)
	if _air_landing_wheel_gap(target*board_local,wheels,point,axis)<GROUND_PRESENTATION_SKIN: return
	var low:=0.0
	var high:=1.0
	# Fixed eight math-only passes find the smallest safe orientation change.
	# There is no translation/lift and no native query inside this search.
	for pass_index: int in 8:
		var middle: float=(low+high)*0.5
		var candidate:=original.interpolate_with(target,middle)
		if _air_landing_wheel_gap(candidate*board_local,wheels,point,axis)>=GROUND_PRESENTATION_SKIN: high=middle
		else: low=middle
	var fitted:=original.interpolate_with(target,high)
	for shape: ConvexPolygonShape3D in _floor_wheel_shapes:
		_floor_wheel_query.shape=shape
		_floor_wheel_query.transform=fitted*board_local
		if not space.intersect_shape(_floor_wheel_query,1).is_empty(): return
	_visual.global_transform=fitted
	_air_support_basis=(_visual.basis*Basis(Vector3.UP,-yaw)).orthonormalized()


func _air_landing_wheel_gap(pose: Transform3D,wheels: Array,point: Vector3,axis: Vector3) -> float:
	var minimum:=INF
	for wheel: Dictionary in wheels:
		for vertex: Vector3 in wheel.points:
			minimum=minf(minimum,(pose*vertex-point).dot(axis))
	return minimum


func _place_manual_wheels() -> void:
	# The capsule can leave a grade before the loaded axle, or enter a bank
	# while that axle is still on flat paving. Fit that real pair AFTER the rig
	# has applied its manual pivot and planted the shoes. The board's local
	# manual pitch/position and every articulated contact stay unchanged.
	var definition := TrickCatalog.definition(manual_trick_id)
	if bool(definition.get("manual_pogo",false)) or bool(definition.get("manual_casper",false)) \
			or absf(float(definition.get("manual_roll",0.0)))>0.00001: return
	var wheels: Array = _visual_rig.board_contact_geometry().wheels
	if wheels.size()!=4 or absf(_board_visual.rotation.x)<0.00001: return
	var loaded: Array[int] = []
	for index: int in wheels.size():
		if Vector3(wheels[index].center).z*_board_visual.rotation.x>0.0: loaded.append(index)
	if loaded.size()!=2: return
	var original := _visual.transform
	var original_pitch := _surface_pitch
	var original_air_basis := _air_support_basis
	var minimum_normal := cos(floor_max_angle)
	var space := get_world_3d().direct_space_state
	var axis := _visual.global_basis.y.normalized()
	var fitted := false
	for pass_index: int in 3:
		var hits: Array[Dictionary] = []
		var aligned := true
		for index: int in loaded:
			var bearing: Vector3 = _board_visual.to_global(wheels[index].center)
			var query := PhysicsRayQueryParameters3D.create(bearing+Vector3.UP*0.35,bearing-Vector3.UP*0.50,collision_mask)
			query.exclude = [get_rid()]
			var hit := space.intersect_ray(query)
			if hit.is_empty() or Vector3(hit.normal).y<minimum_normal:
				_visual.transform=original;_surface_pitch=original_pitch;_air_support_basis=original_air_basis
				return
			hits.append(hit)
			aligned = aligned and Vector3(hit.normal).dot(axis)>0.999
		var lowest := INF
		var highest := -INF
		for side: int in loaded.size():
			var wheel_gap := INF
			for point: Vector3 in wheels[loaded[side]].points:
				wheel_gap = minf(wheel_gap,(_board_visual.to_global(point)-Vector3(hits[side].position)).dot(hits[side].normal))
			lowest=minf(lowest,wheel_gap)
			highest=maxf(highest,wheel_gap)
		# Leave established same-plane manuals exactly alone. This also avoids
		# adding a neutral four-wheel fit which would erase the manual pivot.
		if pass_index==0 and aligned and lowest>=0.004 and highest-lowest<=0.001: return
		var axle: Vector3 = Vector3(hits[1].position)-Vector3(hits[0].position)
		if axle.length_squared()<0.01:
			_visual.transform=original;_surface_pitch=original_pitch;_air_support_basis=original_air_basis
			return
		# Native rear planes supply longitudinal grade; their actual finite hit
		# positions determine axle roll across a join. A capsule normal or a
		# simple averaged normal cannot support wheels on two different planes.
		axis = (Vector3(hits[0].normal)+Vector3(hits[1].normal)).slide(axle.normalized()).normalized()
		if axis.y<minimum_normal:
			_visual.transform=original;_surface_pitch=original_pitch;_air_support_basis=original_air_basis
			return
		var local_axis := global_basis.inverse()*axis
		var pitch := atan2(local_axis.z,local_axis.y)
		var support := Basis.from_euler(Vector3(pitch,0,-asin(clampf(local_axis.x,-1,1))))
		var visual_yaw := _spin_angle+_stance_angle+_air_grind_yaw-PI*(_revert_pose_remaining/REVERT_DURATION)
		_visual.basis=support*Basis(Vector3.UP,visual_yaw)
		var lift := -INF
		for side: int in loaded.size():
			var normal: Vector3 = hits[side].normal
			var gap := INF
			for point: Vector3 in wheels[loaded[side]].points:
				gap=minf(gap,(_board_visual.to_global(point)-Vector3(hits[side].position)).dot(normal))
			lift=maxf(lift,(GROUND_PRESENTATION_SKIN-gap)/normal.y)
		if not is_finite(lift) or absf(lift)>0.10:
			_visual.transform=original;_surface_pitch=original_pitch;_air_support_basis=original_air_basis
			return
		_visual.position += global_basis.inverse()*Vector3.UP*lift
		_surface_pitch=pitch
		_air_support_basis=support
		fitted=true
	if not fitted: return
	# A centre ray's infinite plane does not prove a finite tyre rim clear at
	# an edge. Reuse the immutable real tyre hulls, with the actual manual pose.
	var pose: Transform3D = _board_visual.global_transform
	var rim_lift := 0.0
	for shape: ConvexPolygonShape3D in _floor_wheel_shapes:
		_floor_wheel_query.shape=shape
		_floor_wheel_query.transform=pose
		_floor_wheel_query.motion=Vector3.ZERO
		_floor_wheel_query.margin=0.0
		if space.intersect_shape(_floor_wheel_query,1).is_empty(): continue
		var raised := pose
		raised.origin.y += PLANAR_RIM_MAX_LIFT
		_floor_wheel_query.transform=raised
		_floor_wheel_query.margin=GROUND_PRESENTATION_SKIN
		if not space.intersect_shape(_floor_wheel_query,1).is_empty():
			_visual.transform=original;_surface_pitch=original_pitch;_air_support_basis=original_air_basis
			return
		_floor_wheel_query.motion=Vector3.DOWN*PLANAR_RIM_MAX_LIFT
		var fractions := space.cast_motion(_floor_wheel_query)
		if fractions.size()!=2:
			_visual.transform=original;_surface_pitch=original_pitch;_air_support_basis=original_air_basis
			return
		rim_lift=maxf(rim_lift,PLANAR_RIM_MAX_LIFT*(1.0-clampf(fractions[0],0,1)))
	_visual.position += global_basis.inverse()*Vector3.UP*rim_lift


func _place_transition_wheels() -> void:
	# An arc's chord can put the tyre edges below concrete even when its
	# wheel-centre plane is clear. Fit the whole rigid presentation to the
	# four native bearing planes; physical contact/momentum remain untouched.
	var axis: Vector3 = transition_normal.normalized()
	var lift := 0.0
	for wheel: Dictionary in _visual_rig.board_contact_geometry().wheels:
		var center: Vector3 = _board_visual.to_global(wheel.center)
		var query := PhysicsRayQueryParameters3D.create(center+axis*0.18,center-axis*0.30,1)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or Vector3(hit.normal).dot(axis)<0.7:continue
		var normal: Vector3 = hit.normal
		for vertex: Vector3 in wheel.points:
			var gap := (_board_visual.to_global(vertex)-Vector3(hit.position)).dot(normal)
			lift = maxf(lift,(0.002-gap)/maxf(0.7,normal.dot(axis)))
	_visual.position += global_basis.inverse()*axis*minf(lift,0.025)


func _process(delta: float) -> void:
	last_presentation_process_frame = Engine.get_process_frames()
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
	_body_collision = collision
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
	_build_loose_board()


func _build_loose_board() -> void:
	# One shared mesh, one native world-only collider; no per-frame construction.
	_board_model = _board_visual.get_node("DetailedSkateboard")
	_loose_board = RigidBody3D.new()
	_loose_board.name = "LooseBoard"
	_loose_board.top_level = true
	_loose_board.freeze = true
	_loose_board.mass = 2.5
	_loose_board.collision_layer = 0
	_loose_board.collision_mask = 1 | 8
	_loose_board.continuous_cd = true
	_loose_board.linear_damp = .6
	_loose_board.angular_damp = .8
	var material := PhysicsMaterial.new()
	material.friction = .65
	material.bounce = .18
	_loose_board.physics_material_override = material
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(.24, .12, .82)
	collider.shape = shape
	_loose_board.add_child(collider)
	add_child(_loose_board)

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
	_clear_weighted_ollie()
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
	_clear_weighted_ollie()
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



func get_support_normal() -> Vector3:
	if _feature_transition.active: return _feature_transition.normal
	if _transition.active: return _transition.normal()
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



func _clear_charge() -> void:
	ollie_charge = 0.0
	crouching = false
	_ollie_held = false
	_ollie_was_held = false
	_ollie_released = false



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
	_clear_weighted_ollie()
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



func _start_grab(choice: Dictionary) -> void:
	_grab_definition = choice.duplicate(true)
	_grab_buffer_remaining=0.0
	active_grab_id=str(choice.id)
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



func _spin_landing_clean() -> bool:
	return absf(_air_spin - roundf(_air_spin / PI) * PI) <= deg_to_rad(45.0)



func _manual_choice() -> String:
	# Sustained pushing is travel input, not a deliberate nose-manual modifier.
	var direction: String = _trick_input.direction() if _trick_input.direction_age() <= MANUAL_BUFFER_SECONDS else "neutral"
	return str(TrickCatalog.resolve("manual", direction).id)



func _physical_revert() -> void:
	rotation.y += PI
	_switch_stance = not _switch_stance
	_revert_pose_remaining = REVERT_DURATION
	speed = -speed * REVERT_SPEED_RETAINED
	velocity.x *= REVERT_SPEED_RETAINED
	velocity.z *= REVERT_SPEED_RETAINED



func _rail_floor_contacts_only(contact: KinematicCollision3D) -> bool:
	for index in contact.get_collision_count():
		var normal := contact.get_normal(index)
		if not normal.is_finite() or normal.y<cos(floor_max_angle): return false
	return contact.get_collision_count()>0



func _place_wall_wheels() -> void:
	# Actual retained GLB tyre vertices against the native wall plane.
	var gap:=INF
	for wheel:Dictionary in _visual_rig.board_contact_geometry().wheels:
		for point:Vector3 in wheel.points:
			gap=minf(gap,(_board_visual.to_global(point)-_wall.contact_point).dot(_wall.normal))
	if is_finite(gap):
		_visual.position-=(global_basis.inverse()*_wall.normal)*(gap-.015)



func _start_bail(target: Vector3 = Vector3.INF) -> void:
	begin_bail("contact_or_balance",target)


func _sample_feature_charge(was_held:bool) -> void:
	_ollie_released=was_held and not _ollie_held and _jump_buffer_remaining>0.0
	var plant_supported:bool = _feature_transition.state!="air" if _feature_transition.active else (grinding or _transition.active or wallriding or skitching or (is_on_floor() and not airborne and not _force_air_tick))
	crouching=_ollie_held and plant_supported
	ollie_charge=clampf(_crouch_charge/OLLIE_CHARGE_SECONDS,0,1)
	if _ollie_released:
		_launch_base_impulse=_pop_impulse
		_launch_impulse=_pop_impulse
		_launch_id="ollie"
		var family_prepared:=(_flip_buffer_remaining>0.0 and not _flip_request.is_empty()) or (_grab_buffer_remaining>0.0 and not _grab_request.is_empty())
		var direction: String=_trick_input.direction() if _trick_input.direction_age()<=.18 else "neutral"
		if not family_prepared and direction=="north":_launch_id="nollie"
		elif not family_prepared and direction=="south" and is_on_floor() and not (grinding or transition_active or wallriding or skitching):
			_launch_id="no_comply" if Input.is_action_pressed("manual") else "boneless"
		_launch_impulse*=float(TrickCatalog.definition(_launch_id).get("launch_speed_scale",1.0))
	if _manual_buffer_remaining>0.0 and not _manual_request.is_empty():
		_buffered_manual_id=str(_manual_request.id)
		_manual_gesture_pending=_buffered_manual_id if _manual_gesture_hold else ""


func _tick_feature_transition(delta: float, push: float, brake: float) -> void:
	_clear_weighted_ollie()
	if not _controls_enabled: return
	_discard_cached_support()
	lip_active=_feature_transition.lip
	lip_balance=_feature_transition.lip_balance
	transition_normal=_feature_transition.normal
	_coyote_remaining = 0.0
	# A released pop cannot skip the landing catch/alignment check on first contact.
	if airborne and _feature_transition.state in ["surface", "lip"]:
		if not _finish_landing(): return
	var was_lip: bool = _feature_transition.state == "lip"
	var was_air: bool = _feature_transition.state == "air"
	if was_lip and _trick_entries_enabled: _try_lip_extension()
	if was_air:
		_apply_air_tricks(delta)
		if _trick_entries_enabled and _try_grind(): return
	var result: Dictionary = _feature_transition.step(self, delta, push, brake, _steering,
		_ollie_released and _trick_entries_enabled, Input.is_action_pressed("grind") and _trick_entries_enabled, _ramp_pop_impulse)
	lip_active=_feature_transition.lip
	lip_balance=_feature_transition.lip_balance
	transition_normal=_feature_transition.normal
	speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)
	if was_lip and _feature_transition.active and _feature_transition.state == "surface":
		combo_link_ended.emit()
	match str(result.get("event", "")):
		"launch":
			if not _ollie_released: _launch_id = "ollie"
			_begin_air()
			# Natural vertical bowl departures need the same finite apex handoff
			# as explicit steep pops. Otherwise the camera treats associated air
			# as supported travel and keeps looking up through the return.
			if _feature_transition.feature.wrap_lateral and _feature_transition._theta >= PI * 0.25 and velocity.y > 1.0:
				_ramp_air = true
				# Coping support is upright, unlike the departed curved face.
				# Keep that real face normal for a lip jump's flight plane too.
				var departure: Dictionary = _feature_transition.feature.lip_frame(_feature_transition._x)
				_ramp_air_normal = Vector3(departure.face_normal).normalized()
				_ramp_launch_forward = velocity.slide(_ramp_air_normal).normalized()
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
			_ramp_air = false
			_force_air_tick = true
			_coyote_remaining = 0.0
			if not airborne: _begin_air()
	if _feature_transition.active and _feature_transition.state == "surface" and airborne:
		_finish_landing()
	if _feature_transition.active and _feature_transition.state == "surface" and _feature_transition.feature.get("wrap_lateral") == true:
		var travel: Vector3 = Vector3(_feature_transition.forward.x, 0, _feature_transition.forward.z)
		if travel.length_squared() > 0.001:
			rotation.y = atan2(-travel.x, -travel.z) + (PI if _transition_backwards else 0.0)
			speed = Vector3(velocity.x, 0, velocity.z).dot(-global_basis.z)
	if _feature_transition.active: _feature_transition.refresh_frame(self)



func _native_board_floor() -> Dictionary:
	# Rounded capsule contact at a short step can report a much steeper normal
	# than the actual wheelbase. Fit the presentation to four finite native
	# supports only in that ambiguous case. Physics keeps its original normal.
	var wheels: Array = _visual_rig.board_contact_geometry().wheels
	if wheels.size() != 4: return {}
	var center := _native_floor_hit(Vector3.UP)
	if center.is_empty(): return {}
	var bowl: Node3D
	var contacted: Object = center.get("collider")
	if contacted is Node and contacted.has_meta("transition_feature"):
		var feature: Variant = contacted.get_meta("transition_feature")
		if is_instance_valid(feature) and feature is Node3D and bool(feature.get("wrap_lateral")) \
				and feature.get("surface_body")==contacted:
			bowl=feature
	# Locomotion's capsule floor limit cannot classify the finite surface
	# beneath every wheel on a concave bowl. This exception is presentation
	# only, tied to the actual native wrapped wall beneath the board centre.
	if not _native_board_support_allowed(center,bowl): return {}
	var axis: Vector3 = center.normal
	var point := global_position-axis*(global_position-Vector3(center.position)).dot(axis)
	var space := get_world_3d().direct_space_state
	# Re-probe after fitting: pitching the board changes the projected wheel
	# locations slightly at a bank or a six-centimetre path/apron join.
	for pass_index in 3:
		var local_axis: Vector3 = global_basis.inverse()*axis
		var frame := global_basis*Basis.from_euler(Vector3(atan2(local_axis.z,local_axis.y),0,
			-asin(clampf(local_axis.x,-1,1))))
		var samples := PackedVector3Array()
		var same_plane := pass_index==0 and axis.dot(_native_floor_normal())>0.999
		var front := Vector3.ZERO
		var rear := Vector3.ZERO
		var left := Vector3.ZERO
		var right := Vector3.ZERO
		for wheel: Dictionary in wheels:
			var wheel_center: Vector3 = wheel.center
			# Probe the real centre, including board height, axle height and the
			# presentation skin. Flattening its localY shifts XZ on a bank and
			# can select the wrong side of a short step by a few millimetres.
			var bearing: Vector3 = point+axis*0.008+frame*(_visual_rig._board_rest_position+wheel_center)
			var hit := _native_board_floor_ray(space,bearing+Vector3.UP*0.35,bearing-Vector3.UP*0.50)
			if not _native_board_support_allowed(hit,bowl): return {}
			var support: Vector3 = hit.position
			same_plane = same_plane and Vector3(hit.normal).dot(axis)>0.999 \
				and absf((support-Vector3(center.position)).dot(axis))<=0.001
			samples.append(support)
			if wheel_center.z<0: front+=support
			else: rear+=support
			if wheel_center.x<0: left+=support
			else: right+=support
		if samples.size()!=4: return {}
		# Preserve the established planar-floor pose exactly. A wheel can reach
		# a short step before the rounded capsule does, even if their centre
		# normals still agree, so verify all four locations before this shortcut.
		if same_plane: return _native_planar_rim_fit(point,axis,frame)
		axis = (rear-front).cross(right-left).normalized()
		if axis.y<(0.05 if is_instance_valid(bowl) else cos(floor_max_angle)): return {}
		var average := (front+rear)*0.25
		var clearance := 0.0
		for sample: Vector3 in samples:
			clearance = maxf(clearance,(sample-average).dot(axis))
		# A slightly twisted four-point patch cannot touch every rigid wheel at
		# once. Keep the fitted bearing above every sampled solid, never inside.
		point = global_position-axis*((global_position-average).dot(axis)-clearance)
	# Verify the resulting actual tyre volumes against their finite native
	# supports. A final vertical correction cannot change which side of the
	# step each wheel occupies, unlike another normal-offset iteration.
	var final_axis: Vector3 = global_basis.inverse()*axis
	var final_frame := global_basis*Basis.from_euler(Vector3(atan2(final_axis.z,final_axis.y),0,
		-asin(clampf(final_axis.x,-1,1))))
	var lift := 0.0
	for wheel: Dictionary in wheels:
		var wheel_center: Vector3 = wheel.center
		var bearing: Vector3 = point+axis*0.008+final_frame*(_visual_rig._board_rest_position+wheel_center)
		var hit := _native_board_floor_ray(space,bearing+Vector3.UP*0.35,bearing-Vector3.UP*0.50)
		if not _native_board_support_allowed(hit,bowl): return {}
		# Use the real rounded GLB tyre vertices, not a primitive cylinder
		# extent or the urethane bushings in the joined material surface.
		var gap := INF
		for vertex: Vector3 in wheel.points:
			var drawn: Vector3 = point+axis*0.008+final_frame*(_visual_rig._board_rest_position+vertex)
			gap = minf(gap,(drawn-Vector3(hit.position)).dot(Vector3(hit.normal)))
		lift = maxf(lift,(0.008-gap)/Vector3(hit.normal).y)
	if lift>0.10: return {}
	point.y += lift
	if is_instance_valid(bowl):
		# Plane samples alone cannot establish that each finite tyre volume is
		# clear. Keep the existing skin/lift ceilings and reject an unfittable
		# pose, rather than moving the physical capsule or hiding an obstacle.
		var pose := Transform3D(final_frame,point+axis*GROUND_PRESENTATION_SKIN+final_frame*_visual_rig._board_rest_position)
		for shape: ConvexPolygonShape3D in _floor_wheel_shapes:
			_floor_wheel_query.shape=shape
			_floor_wheel_query.transform=pose
			_floor_wheel_query.motion=Vector3.ZERO
			_floor_wheel_query.margin=0.0
			if not space.intersect_shape(_floor_wheel_query,1).is_empty(): return {}
	return {"position":point,"normal":axis}


func _native_board_floor_ray(space: PhysicsDirectSpaceState3D,from: Vector3,to: Vector3) -> Dictionary:
	# Only parameter storage is retained. Each sequential support request uses
	# the current endpoints, mask and self-exclusion, with factory ray defaults.
	_board_floor_ray.from = from
	_board_floor_ray.to = to
	_board_floor_ray.collision_mask = collision_mask
	_board_floor_ray.exclude = [get_rid()]
	return space.intersect_ray(_board_floor_ray)


func _native_board_support_allowed(hit: Dictionary,bowl: Node3D) -> bool:
	if hit.is_empty(): return false
	var normal: Vector3 = hit.normal
	if not normal.is_finite(): return false
	if normal.y>=cos(floor_max_angle): return true
	return is_instance_valid(bowl) and normal.y>0.05 and hit.get("collider")==bowl.get("surface_body")


func _native_planar_rim_fit(point: Vector3, axis: Vector3, frame: Basis) -> Dictionary:
	# Four centre rays can all see a flat floor while a lower diagonal tyre
	# contour reaches a finite bank side. Keep the unchanged planar pose unless
	# an actual tyre volume overlaps native scenery. Only presentation may lift.
	var space := get_world_3d().direct_space_state
	var pose := Transform3D(frame,point+axis*GROUND_PRESENTATION_SKIN+frame*_visual_rig._board_rest_position)
	var lift := 0.0
	for shape: ConvexPolygonShape3D in _floor_wheel_shapes:
		_floor_wheel_query.shape = shape
		_floor_wheel_query.transform = pose
		_floor_wheel_query.motion = Vector3.ZERO
		_floor_wheel_query.margin = 0.0
		if space.intersect_shape(_floor_wheel_query,1).is_empty(): continue
		var raised := pose
		raised.origin.y += PLANAR_RIM_MAX_LIFT
		_floor_wheel_query.transform = raised
		_floor_wheel_query.margin = GROUND_PRESENTATION_SKIN
		# A tall wall/ceiling is not a small support join and cannot be crossed
		# by moving the drawn rider through it.
		if not space.intersect_shape(_floor_wheel_query,1).is_empty(): return {}
		_floor_wheel_query.motion = Vector3.DOWN*PLANAR_RIM_MAX_LIFT
		var fractions := space.cast_motion(_floor_wheel_query)
		if fractions.size()!=2: return {}
		lift = maxf(lift,PLANAR_RIM_MAX_LIFT*(1.0-clampf(fractions[0],0.0,1.0)))
	if lift<=0.000001: return {}
	return {"position":point+Vector3.UP*lift,"normal":axis}



func _requires_model_grind_clearance(id:String) -> bool:
	return _grind_exact_pose or id not in ["","rail_grind","grind_50_50","boardslide"]

func _try_grind_extension() -> void:
	if not _trick_entries_enabled or _style_cooldown>0.0 or _grind_transfer.active:return
	var action:Dictionary=_trick_input.pop_action("flip")
	if action.is_empty():action=_trick_input.pop_action("grab")
	if action.is_empty():action=_trick_input.pop_action("revert")
	if action.is_empty():return
	var choice:=TrickCatalog.resolve_extension("grind",str(action.action),str(action.direction),grind_trick_id)
	if choice.is_empty() or TrickCatalog.repetition_id(str(choice.id))==TrickCatalog.repetition_id(grind_trick_id):return
	var pivot:=str(choice.id)=="grind_pivot"
	var pose_id:=grind_style_id if pivot else str(choice.id)
	var yaw:float=_grind_style_yaw+PI if pivot else float(choice.get("grind_yaw",0.0))+(PI if _rail_backwards else 0.0)
	if not _solve_grind_contact(_grind_candidate_contact,_grind.line,_grind.distance,_grind.direction,yaw,pose_id,0.0):return
	if not _grind_board_clear(_grind_candidate_contact.board_transform):return
	if not _grind_transfer.begin(_board_visual.global_transform,_grind_candidate_contact,_grind.line.contact_up(_grind.distance),_grind_clearance):return
	_grind_pending={"definition":choice,"pose_id":pose_id,"yaw":yaw,"pivot":pivot}
	_style_cooldown=.35



func _complete_grind_transfer() -> void:
	if _grind_pending.is_empty():return
	var choice:Dictionary=_grind_pending.definition
	var pivot:bool=_grind_pending.pivot
	if pivot:
		_rail_backwards=not _rail_backwards
		rotation.y+=PI
		_switch_stance=not _switch_stance
		_grind.speed*=REVERT_SPEED_RETAINED
	else:
		grind_style_id=str(_grind_pending.pose_id)
		grind_trick_id=grind_style_id
		_grind_definition=choice
	_grind_style_yaw=float(_grind_pending.yaw)
	_grind_exact_pose=true
	_solve_grind_contact(_grind_contact,_grind.line,_grind.distance,_grind.direction,_grind_style_yaw,grind_style_id,0.0)
	_grind_pending.clear()
	_emit_trick(str(choice.id))

