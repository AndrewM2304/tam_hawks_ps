extends RefCounted
## Original skating clothes/board with attributed CC0 anatomical head and hands.
## Geometry and animation only: native skinning and analytic contact poses, no physics.

const Garments = preload("res://game/player/skater_garments.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const Anatomy = preload("res://game/player/skater_anatomy.gd")
const Skateboard = preload("res://game/art/assets/tam_skateboard/tam_skateboard.glb")
const TrickAnimation = preload("res://game/player/trick_animation.gd")
const PLANTED_FOOT_Z := 0.220
const PLANTED_FOOT_Y := 0.0784
static var _hang_ten_support: Dictionary = {}
static var _native_board_cache: Dictionary = {}
var _board_meshes: Array[MeshInstance3D] = []
var _bail_blend := 0.0
var _ramp_anticipation := 0.0

var _board: Node3D
var _board_rest_height := 0.12
var _board_rest_position := Vector3(0, 0.12, 0)
var _rider: Node3D
var _upper: Node3D
var _garments: RefCounted
var _head: Node3D
var _anatomy: RefCounted
var _legs: Array[Dictionary] = []
var _arms: Array[Dictionary] = []
var _sphere: SphereMesh
var _cylinder: CylinderMesh
var _push_phase := 0.0
var _push_blend := 0.0
var _air_blend := 0.0
var _grab_blend := 0.0
var _landing := 0.0
var _was_airborne := false
var _brake_blend := 0.0
var _flip_blend := 0.0
var _manual_blend := 0.0
var _grind_blend := 0.0
var _air_time := 0.0
var _motion_time := 0.0
var _torso_turn := 0.0
var _pelvis_turn := 0.0
var _grind_release_offset := Vector3.ZERO
var _crouch_blend := 0.0
var _wall_blend := 0.0
var _slide_blend := 0.0
var _lip_blend := 0.0
var _transition_blend := 0.0
var _walk_blend := 0.0
var _walk_phase := 0.0
var _foot_lift := 0.0
var _front_foot_lift := 0.0
var _rear_foot_lift := 0.0
var _drag_crouch := 0.0
var _manual_shift := 0.0
var _manual_weight_z := 0.0
var _lip_weight_z := 0.0
var _cross_blend := 0.0
var _pogo_blend := 0.0
var _casper_blend := 0.0
var _board_support_points := PackedVector3Array()
var _wheel_surfaces: Array[Dictionary] = []
var _sole_points := PackedVector3Array()
var _grip_faces := PackedVector3Array()
var _wood_faces := PackedVector3Array()
var _deck_top_faces := PackedVector3Array()
var _deck_surface_grid: Dictionary = {}
var _slide_direction := 1.0
var _setup_catch_offset := Vector3.ZERO
var _setup_catch_basis := Basis.IDENTITY
var _setup_last_id := ""
var _handplant_blend := 0.0
var _lip_point := Vector3.ZERO
var _lip_normal := Vector3.UP
var _lip_definition: Dictionary = {}
var _skitch_blend := 0.0
var _skitch_local_grips: Array[Vector3] = []

func build(board: Node3D, rider: Node3D, shirt: StandardMaterial3D) -> void:
	_board = board
	_board_rest_height = board.position.y
	_board_rest_position = board.position
	_rider = rider
	_sphere = SphereMesh.new()
	_sphere.radius = 1.0
	_sphere.height = 2.0
	_sphere.radial_segments = 20
	_sphere.rings = 12
	_cylinder = CylinderMesh.new()
	_cylinder.top_radius = 0.88
	_cylinder.bottom_radius = 1.0
	_cylinder.height = 1.0
	_cylinder.radial_segments = 12
	_anatomy = Anatomy.new()
	var denim := _material(Color("343b42"), 0.96)
	var seams := _material(Color("435057"), 0.92)
	var rubber := _material(Color("aaa79a"), 0.90)
	var shoes := _material(Color("35332e"), 0.88)
	var dark := _material(Color("262123"), 0.98)
	_build_board()
	_upper = Node3D.new()
	_upper.name = "TorsoRig"
	_rider.add_child(_upper)
	_garments = Garments.new()
	_garments.build(_rider, shirt, denim)
	_loft(_upper, "JacketHem", [Vector4(0.016, 0.177, 0.128, 0), Vector4(0.035, 0.178, 0.128, 0)], seams)
	_loft(_upper, "Collar", [Vector4(0.475, 0.075, 0.064, -0.008), Vector4(0.515, 0.062, 0.054, -0.008)], seams)
	_segment(_upper, "JacketZip", Vector3(0, 0.055, -0.128), Vector3(0, 0.415, -0.124), 0.0025, dark)
	for side: float in [-1.0, 1.0]:
		_segment(_upper, "PocketSeam", Vector3(side * 0.065, 0.13, -0.117), Vector3(side * 0.125, 0.19, -0.107), 0.002, seams)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.655, -0.015)
	head.rotation.y = 1.05
	_head = head
	_upper.add_child(head)
	_anatomy.build_head(head)
	for side: float in [-1.0, 1.0]:
		var foot := Node3D.new()
		foot.name = "FrontFoot" if side < 0.0 else "PushFoot"
		_rider.add_child(foot)
		Footwear.build(foot, shoes, rubber, seams)
		_legs.append({"side": side, "foot": foot})
		var hand: Node3D = _anatomy.build_hand(_rider, side)
		_arms.append({"side": side, "hand": hand})
	_cache_support_geometry()
	_cache_deck_surface_grid()
	_cache_hang_ten_support()
	reset()

func reset() -> void:
	if is_instance_valid(_board):
		_board.position = _board_rest_position
	_push_phase = 0.0
	_push_blend = 0.0
	_air_blend = 0.0
	_grab_blend = 0.0
	_brake_blend = 0.0
	_flip_blend = 0.0
	_manual_blend = 0.0
	_grind_blend = 0.0
	_landing = 0.0
	_air_time = 0.0
	_motion_time = 0.0
	_torso_turn = 0.0
	_pelvis_turn = 0.0
	_grind_release_offset = Vector3.ZERO
	_was_airborne = false
	_crouch_blend = 0.0
	_wall_blend = 0.0
	_slide_blend = 0.0
	_lip_blend = 0.0
	_transition_blend = 0.0
	_walk_blend = 0.0
	_walk_phase = 0.0
	_foot_lift = 0.0
	_front_foot_lift = 0.0
	_rear_foot_lift = 0.0
	_drag_crouch = 0.0
	_manual_shift = 0.0
	_manual_weight_z = 0.0
	_lip_weight_z = 0.0
	_cross_blend = 0.0
	_pogo_blend = 0.0
	_casper_blend = 0.0
	_slide_direction = 1.0
	_setup_catch_offset = Vector3.ZERO
	_setup_catch_basis = Basis.IDENTITY
	_setup_last_id = ""
	_bail_blend = 0.0
	_ramp_anticipation = 0.0
	_handplant_blend = 0.0
	_lip_definition.clear()
	_skitch_blend = 0.0
	_skitch_local_grips.clear()
	# Title/pause and an immediate report can render before the first physics
	# tick. Apply the complete contact pose now; clearing blend weights alone
	# leaves the head, shoes and hands at their construction origins.
	_head.rotation = Vector3.ZERO
	animate(0.0, {"airborne": false, "grab": false, "flip": false,
		"manual": false, "grind": false, "speed": 0.0, "push": false,
		"brake": false})


static func setup_foot_offset() -> Vector3:
	return Vector3(-0.34, 0, -0.255)


static func boneless_grab_target() -> Vector3:
	return Vector3(0.128, 0.022, 0.02)


static func pogo_hand_target(side: float) -> Vector3:
	# Authored griptape perimeter vertices at the two 45-degree nose shoulders.
	var point := Vector3(side * 0.118 * sqrt(0.5), 0, -0.30 - 0.118 * sqrt(0.5)) * 0.94
	point.y = 0.017 + 0.65 * pow(maxf(0.0, absf(point.z) - 0.28), 1.5) + point.x * point.x * 0.14
	return point


func begin_bail() -> void:
	# Native recovery and local presentation stay owned by the controller.
	# Never retain an interrupted world transform across its moving capsule.
	_handplant_blend = 0.0
	_skitch_blend = 0.0
	_skitch_local_grips.clear()


func animate(delta: float, state: Dictionary) -> void:
	_bail_blend = clampf(float(state.get("bail", 0.0)), 0.0, 1.0)
	var ramp_turn := float(state.get("ramp_turn", -1.0))
	_ramp_anticipation = sin(TAU * ramp_turn) if ramp_turn >= 0.0 else 0.0
	var air: bool = state["airborne"]
	var grab: bool = state["grab"]
	var flip: bool = state["flip"]
	var manual: bool = state["manual"]
	var grind: bool = state["grind"]
	var ride_speed := absf(float(state["speed"]))
	var travel_sign := -1.0 if float(state.get("travel_sign", 1.0)) < 0.0 else 1.0
	var wall: bool = state.get("wallriding", false)
	var transition: bool = state.get("transition_active", false)
	var skitch: bool = state.get("skitching", false)
	var skitch_grips: Array = state.get("skitch_grips", [])
	if skitch_grips.size() != 2: skitch = false
	for point: Variant in skitch_grips:
		if not point is Vector3 or not point.is_finite(): skitch = false
	var travel_node: Node3D = _board.get_parent().get_parent()
	if skitch:
		_skitch_local_grips.assign([travel_node.to_local(skitch_grips[0]), travel_node.to_local(skitch_grips[1])])
	_skitch_blend = _blend(_skitch_blend, 1.0 if skitch else 0.0, delta, 14.0)
	if not skitch and _skitch_local_grips.size() == 2 and _skitch_blend > 0.0001:
		skitch_grips = [travel_node.to_global(_skitch_local_grips[0]), travel_node.to_global(_skitch_local_grips[1])]
	var skitch_pose := skitch_grips.size() == 2 and _skitch_blend > 0.0001
	var skitch_axis := Vector3.FORWARD
	if state.get("skitch_normal") is Vector3:
		var normal: Vector3 = state.skitch_normal
		if normal.is_finite() and normal.length_squared() > 0.01:
			skitch_axis = _board.global_basis.inverse() * -normal.normalized()
	var lip: bool = state.get("lip_active", not str(state.get("lip_id", "")).is_empty())
	var lip_definition: Dictionary = state.get("lip_definition", {})
	var handplant := lip and str(lip_definition.get("lip_support", "deck")) == "palms"
	_handplant_blend = _blend(_handplant_blend, 1.0 if handplant else 0.0, delta, 12.0)
	if handplant:
		_lip_point = state.get("lip_ground_point", _board.get_parent().global_position)
		_lip_normal = state.get("lip_normal", Vector3.UP)
		_lip_definition = lip_definition.duplicate(true)
		_board.rotation = Vector3(float(lip_definition.get("lip_pitch", 0.0)),
			float(lip_definition.get("lip_yaw", 0.0)) + float(state.get("rest_deck_yaw", 0.0)),
			float(lip_definition.get("lip_roll", 0.0)))
	elif _handplant_blend > 0.0001 and not flip and not grab and str(state.get("special_id", "")).is_empty():
		_board.rotation = Vector3(0, float(state.get("rest_deck_yaw", 0.0)), 0)
	var sliding: bool = state.get("powersliding", false) and not air and not manual and not grind
	var crouching: bool = state.get("crouching", float(state.get("crouch", 0.0)) > 0.0) and not air and not manual and not grind and not lip
	var charge := clampf(float(state.get("ollie_charge", 0.0)), 0.0, 1.0)
	var crouch := clampf(float(state.get("crouch", 0.55 + 0.45 * charge if crouching else 0.0)), 0.0, 1.0)
	var walking: bool = manual and bool(state.get("manual_walk", false))
	var manual_roll := float(state.get("manual_roll", 0.0))
	var foot_lift := clampf(float(state.get("manual_foot_lift", 0.0)), 0.0, 0.3) if manual else 0.0
	var manual_definition: Dictionary = state.get("manual_definition", {})
	var foot_shift := float(manual_definition.get("manual_foot_shift", 0.0)) if manual else 0.0
	var crossfoot: bool = manual and bool(manual_definition.get("manual_cross", false))
	var pogo: bool = manual and bool(manual_definition.get("manual_pogo", false))
	var casper: bool = manual and bool(manual_definition.get("manual_casper", false))
	var grab_definition: Dictionary = state.get("grab_definition", {})
	var extension := clampf(float(state.get("tweak_leg_extension", grab_definition.get("tweak_leg_extension", 0.0))), -0.2, 0.3) if grab else 0.0
	var setup: bool = state.get("setup_active", false)
	var setup_id := str(state.get("setup_id", ""))
	var setup_phase := clampf(float(state.get("setup_phase", 0.0)), 0.0, 1.0)
	var setup_plant := smoothstep(0.02, 0.30, setup_phase) if setup else 0.0
	var setup_point: Vector3 = state.get("setup_ground_point", Vector3.ZERO)
	var setup_normal: Vector3 = state.get("setup_normal", Vector3.UP)
	if not setup_point.is_finite() or not setup_normal.is_finite() or setup_normal.length_squared() < 0.01:
		setup_plant = 0.0
		setup_normal = Vector3.UP
	setup_normal = setup_normal.normalized()
	var braking: bool = state.get("brake", false) and not transition and not air and not manual and not grind and not sliding and ride_speed > 0.2
	var pushing: bool = state["push"] and not transition and not braking and not air and not manual and not grind and not crouching and not sliding and not lip and ride_speed < 14.5
	pushing = pushing and not setup
	braking = braking and not setup
	pushing = pushing and not skitch
	braking = braking and not skitch
	var steer: float = state.get("steering", 0.0)
	var manual_balance: float = state.get("manual_balance", 0.0)
	var grind_balance: float = state.get("grind_balance", 0.0)
	var special_id: String = state.get("special_id", "")
	var special_progress: float = state.get("special_progress", 0.0)
	var flip_progress := clampf(float(state.get("flip_progress", 0.5)), 0.0, 1.0)
	var flip_id: String = state.get("flip_id", "kickflip")
	var grab_id := str(state.get("grab_id", "melon_grab"))
	var native_grab := TrickAnimation.grab_pose(grab_id)
	var grab_side := -1.0 if float(state.get("grab_side", native_grab.hand_side)) < 0.0 else 1.0
	var grab_target: Vector3 = state.get("grab_target", native_grab.deck_target)
	var rest_deck_yaw: float = state.get("rest_deck_yaw", 0.0)
	var grab_stance := Basis(Vector3.UP, -rest_deck_yaw)
	grab_target = grab_stance * grab_target
	var grind_yaw: float = state.get("grind_yaw", 0.0)
	var grind_id: String = state.get("grind_id", "rail_grind")
	var deck_yaw: float = state.get("deck_yaw", 0.0) if not grind else 0.0
	if lip: deck_yaw = rest_deck_yaw
	var manual_sign: float = state.get("manual_sign", -1.0 if str(state.get("manual_id", "manual")) == "nose_manual" else 1.0)
	var lip_id := str(lip_definition.get("id", state.get("lip_id", "")))
	var grab_tuck := float(grab_definition.get("grab_tuck", native_grab.tuck))
	var grab_weight_z := float(grab_definition.get("grab_weight_z", -0.10 if grab_id == "nose_grab" else (0.24 if grab_id == "tail_grab" else 0.0)))
	var grab_body_pitch := float(grab_definition.get("grab_body_pitch", 0.18 if grab_id == "method_grab" else 0.0))
	var grab_body_roll := float(grab_definition.get("grab_body_roll", 0.16 if grab_id == "method_grab" else 0.0))
	_manual_weight_z = _blend(_manual_weight_z, float(manual_definition.get("manual_weight_z", -0.105 if manual_sign < 0.0 else 0.055)) if manual else 0.0, delta, 12.0)
	_lip_weight_z = _blend(_lip_weight_z, float(lip_definition.get("lip_weight_z", -0.10 if lip_id == "nose_stall" else (0.10 if lip_id == "tail_stall" else 0.0))) if lip and not handplant else 0.0, delta, 14.0)
	var takeoff_mode := str(state.get("takeoff_mode", "Regular")).to_lower()
	var launch_id := str(state.get("launch_id", "nollie" if takeoff_mode == "nollie" else "ollie"))
	var launch_age := maxf(0.0, float(state.get("launch_age", 1.0)))
	var launch_curve := sin(PI * clampf(launch_age / 0.22, 0.0, 1.0)) if air and not flip else 0.0
	var nose_pop := launch_curve if launch_id == "nollie" else 0.0
	var boneless_grip := smoothstep(0.0, 0.55, setup_phase) if setup and setup_id == "boneless" else 0.0
	if air and launch_id == "boneless" and not flip and not grab:
		boneless_grip = 1.0 - smoothstep(0.12, 0.32, launch_age)
	var setup_catch := 1.0 - smoothstep(0.0, 0.28, launch_age) if air and launch_id == _setup_last_id else 0.0
	var wall_normal: Vector3 = state.get("wall_normal", Vector3.ZERO)
	var wall_local := Vector3.ZERO
	if wall_normal.is_finite() and wall_normal.length_squared() > 0.01:
		wall_local = _rider.global_basis.inverse() * wall_normal.normalized()
	var board_spin := special_id == "special_clyde_carousel"
	var special_definition: Dictionary = state.get("special_definition", {})
	var salute: bool = bool(special_definition.get("special_grab", false)) and not special_id.is_empty()
	if salute: boneless_grip = maxf(boneless_grip, sin(PI * clampf(special_progress, 0.0, 1.0)))
	var separated_special := board_spin or absf(float(special_definition.get("special_board_roll", 0.0))) > PI \
		or absf(float(special_definition.get("special_board_yaw", 0.0))) > PI
	var tumble := sin(PI * special_progress) if special_id == "special_tenement_tumble" else 0.0
	if _was_airborne and not air:
		_landing = 0.30
	if not _was_airborne and air:
		_air_time = 0.0
	_was_airborne = air
	_air_time += delta if air else 0.0
	_motion_time += delta
	_landing = maxf(0.0, _landing - delta)
	_push_blend = _blend(_push_blend, 1.0 if pushing else 0.0, delta, 22.0 if transition else 10.0)
	_brake_blend = _blend(_brake_blend, 1.0 if braking else 0.0, delta, 22.0 if transition else 12.0)
	if transition:
		if _push_blend < 0.002: _push_blend = 0.0
		if _brake_blend < 0.002: _brake_blend = 0.0
	_air_blend = _blend(_air_blend, 1.0 if air else 0.0, delta, 14.0)
	_grab_blend = _blend(_grab_blend, 1.0 if grab else 0.0, delta, 22.0)
	# The flick separates the soles from a rotating deck, then brings both feet
	# back to their planted contact targets before the animation finishes.
	var flick := smoothstep(0.0, 0.16, flip_progress) * (1.0 - smoothstep(0.72, 0.98, flip_progress))
	var separation := flick if flip else (smoothstep(0.0, 0.12, special_progress) * (1.0 - smoothstep(0.78, 1.0, special_progress)) if separated_special else 0.0)
	_flip_blend = _blend(_flip_blend, separation, delta, 36.0)
	_manual_blend = _blend(_manual_blend, 1.0 if manual else 0.0, delta, 12.0)
	_grind_blend = _blend(_grind_blend, 1.0 if grind else 0.0, delta, 12.0)
	_crouch_blend = _blend(_crouch_blend, crouch, delta, 15.0)
	_wall_blend = _blend(_wall_blend, 1.0 if wall else 0.0, delta, 14.0)
	_slide_blend = _blend(_slide_blend, 1.0 if sliding else 0.0, delta, 14.0)
	_lip_blend = _blend(_lip_blend, 1.0 if lip else 0.0, delta, 14.0)
	_transition_blend = _blend(_transition_blend, 1.0 if transition else 0.0, delta, 10.0)
	_walk_blend = _blend(_walk_blend, 1.0 if walking else 0.0, delta, 12.0)
	_foot_lift = _blend(_foot_lift, foot_lift, delta, 13.0)
	# Tail manuals load the rear foot; nose manuals load the front. When the
	# weighted role changes, plant the formerly raised shoe before lifting its
	# partner rather than leaving both feet suspended during the handover.
	var front_lift := foot_lift if manual_sign > 0.0 and _rear_foot_lift < 0.0005 else 0.0
	var rear_lift := foot_lift if manual_sign < 0.0 and _front_foot_lift < 0.0005 else 0.0
	_front_foot_lift = _blend(_front_foot_lift, front_lift, delta, 13.0)
	_rear_foot_lift = _blend(_rear_foot_lift, rear_lift, delta, 13.0)
	_manual_shift = _blend(_manual_shift, foot_shift, delta, 12.0)
	var hang_ten := smoothstep(0.0, 1.0, clampf(-_manual_shift / 0.20, 0.0, 1.0))
	_cross_blend = _blend(_cross_blend, 1.0 if crossfoot else 0.0, delta, 16.0)
	_pogo_blend = _blend(_pogo_blend, 1.0 if pogo else 0.0, delta, 16.0)
	_casper_blend = _blend(_casper_blend, 1.0 if casper else 0.0, delta, 16.0)
	if walking: _walk_phase = fmod(_walk_phase + delta * TAU * 1.1, TAU)
	if sliding and absf(steer) > 0.1: _slide_direction = signf(steer)
	# The rear axle stays above the supporting plane as the manual lifts the nose.
	# Apply the geometric compensation before solving shoe/hand contact targets.
	var deck_pitch := _board.rotation.x
	_board.position = _board_rest_position
	var native_grind_contact := grind and bool(state.get("native_grind_contact", false))
	if native_grind_contact:
		# The native GrindStyle solver already placed this exact model frame.
		# Keep its declared truck/deck contacts instead of applying a second lift.
		_grind_release_offset = Vector3.ZERO
	elif grind:
		# Ride geometry supplies the support line at the player origin. Put the
		# visible bearing surface on it: deck belly for slides, the weighted axle
		# for one-truck grinds, both axle bottoms for a neutral 50-50.
		var support := _grind_support(grind_id, grind_yaw)
		_board.position = -(_board.basis * support)
		if grind_id == "rail_grind":
			var front := _board.basis * Vector3(0, -0.103, -0.255)
			var rear := _board.basis * Vector3(0, -0.103, 0.255)
			_board.position = Vector3(0, -minf(front.y, rear.y), 0)
		_grind_release_offset = _board.position - _board_rest_position
	else:
		# One-truck poses offset the deck along the rail. Return it underneath
		# the rider over several frames on release rather than swapping feet.
		_grind_release_offset = _grind_release_offset.lerp(Vector3.ZERO, 1.0 - exp(-14.0 * delta))
		_board.position += _grind_release_offset
		if not air:
			_board.position.y += maxf(0.0,
				0.255 * absf(sin(deck_pitch)) + 0.088 * (cos(deck_pitch) - 1.0))
		if maxf(_pogo_blend, _casper_blend) > 0.0001:
			# Project the actual rendered convex support hull, including curved deck,
			# trucks and wheels. The lowest point changes during a Casper roll;
			# selecting only its tail would bury the opposite edge at half-roll.
			var lowest := INF
			for point: Vector3 in _board_support_points:
				lowest = minf(lowest, (_board.basis * point).y)
			_board.position.y = -lowest + 0.003
	if lip and not handplant:
		var bearing := Vector3(0, -0.014, 0)
		match str(lip_definition.get("lip_support", "deck")):
			"front_truck": bearing = Vector3(0, -0.103, -0.255)
			"rear_truck": bearing = Vector3(0, -0.103, 0.255)
			"both_trucks": bearing = Vector3(0, -0.103, 0)
		var support_point: Vector3 = state.get("lip_ground_point", _board.get_parent().global_position)
		if support_point.is_finite(): _board.global_position = support_point - _board.global_basis * bearing
	if pushing:
		_push_phase = fmod(_push_phase + delta * (1.25 + ride_speed * 0.025), 1.0)
	var landing_curve := sin(PI * clampf(_landing / 0.30, 0.0, 1.0))
	var compression := 0.14 * landing_curve
	var launch_tuck := sin(PI * clampf(_air_time / 0.35, 0.0, 1.0)) * _air_blend
	# Nose/tail grabs use the same planted feet with a deeper crouch and a lean
	# toward the chosen contact. The arm solver therefore keeps human reach.
	var hips_y := 0.955 - 0.055 * _air_blend - grab_tuck * _grab_blend - compression - 0.08 * launch_tuck - 0.05 * tumble
	var bearing_blend := maxf(_grind_blend, _lip_blend if lip and not handplant else 0.0)
	hips_y += (_board.position.y - _board_rest_height) * bearing_blend
	hips_y -= 0.025 * _push_blend + 0.035 * _brake_blend
	hips_y -= 0.17 * _crouch_blend + 0.10 * _wall_blend + 0.10 * _slide_blend + 0.08 * _lip_blend + 0.035 * _transition_blend
	hips_y -= float(lip_definition.get("lip_tuck", 0.08 if lip_id in ["disaster", "disaster_stall"] else 0.0)) * _lip_blend
	hips_y -= 0.08 * absf(_ramp_anticipation)
	hips_y = lerpf(hips_y, 0.23, _bail_blend)
	var no_comply_pose := setup_plant if setup and setup_id == "no_comply" else (setup_catch if launch_id == "no_comply" else 0.0)
	hips_y = lerpf(hips_y, 0.70, no_comply_pose)
	hips_y = lerpf(hips_y, 0.34, boneless_grip)
	hips_y += extension * 0.10 * _grab_blend
	hips_y = lerpf(hips_y, 0.74, _skitch_blend)
	hips_y = lerpf(hips_y, 0.84, _pogo_blend)
	hips_y -= 0.06 * hang_ten
	var breathing := sin(_motion_time * 2.1) * 0.004 * (1.0 - _air_blend)
	var grab_local: Vector3 = _rider.to_local(_board.to_global(grab_target))
	var grab_lean := Vector3(grab_local.x, 0, grab_local.z).limit_length(0.11) * _grab_blend
	var wall_lean := Vector3(wall_local.x, 0, wall_local.z) * 0.09 * _wall_blend
	var walk_sway := sin(_walk_phase) * clampf(absf(manual_roll), 0.0, 0.2) * _walk_blend
	var support_lean := wall_lean + Vector3(walk_sway * 0.35 + _slide_direction * 0.025 * _slide_blend, 0, -0.025 * _crouch_blend - 0.045 * nose_pop)
	var nose_forward := _rider.global_basis.inverse() * (_board.global_basis * grab_stance * Vector3.FORWARD)
	# Keep the original named weight shifts in the functional deck frame, so
	# both id-only callers and metadata-driven poses load the correct end.
	var deck_back := -Vector3(nose_forward.x, 0, nose_forward.z).normalized()
	support_lean += deck_back * (_manual_weight_z + _lip_weight_z + grab_weight_z * _grab_blend)
	support_lean += Vector3(nose_forward.x, 0, nose_forward.z).normalized() * 0.10 * hang_ten
	support_lean.z += extension * 0.35 * _grab_blend
	var hips_origin := Vector3(0, hips_y, 0) + grab_lean * 0.7 + support_lean
	hips_origin.z = lerpf(hips_origin.z, 0.08, _bail_blend)
	_upper.position = Vector3(0.025 * _push_blend - 0.018 * _brake_blend, hips_y + breathing, 0) + grab_lean + support_lean
	_upper.rotation.x = -0.07 - _grab_blend * 0.23 - _push_blend * 0.13 + _brake_blend * 0.09 - compression * 0.4
	_upper.rotation.x -= 0.19 * _crouch_blend + 0.08 * _slide_blend + 0.06 * _lip_blend + 0.04 * _transition_blend
	_upper.rotation.x += wall_local.z * 0.18 * _wall_blend
	_upper.rotation.x -= 0.10 * nose_pop
	_upper.rotation.x += (grab_weight_z * 2.0 + grab_body_pitch) * _grab_blend
	_upper.rotation.x = lerpf(_upper.rotation.x, -0.65, boneless_grip)
	var support_turn := float(lip_definition.get("lip_yaw", 0.0)) * _lip_blend if lip and not handplant else grind_yaw * _grind_blend
	_pelvis_turn = _blend(_pelvis_turn, support_turn * 0.45 - _slide_direction * 0.12 * _slide_blend + walk_sway * 0.25, delta, 12.0)
	_torso_turn = _blend(_torso_turn, 0.08 + steer * 0.10 + sin(TAU * _push_phase) * _push_blend * 0.08 + support_turn * 0.25 - _slide_direction * 0.30 * _slide_blend - walk_sway * 0.45, delta, 9.0)
	var nose_turn := atan2(-nose_forward.x, -nose_forward.z)
	var pelvis_turn := lerp_angle(_pelvis_turn, nose_turn, hang_ten)
	_upper.rotation.y = _torso_turn
	_upper.rotation.y -= 0.25 * _ramp_anticipation
	_upper.rotation.y = lerp_angle(_upper.rotation.y, nose_turn, hang_ten)
	if _pogo_blend > 0.0001:
		var nose := _rider.to_local(_board.to_global(grab_stance * pogo_hand_target(0.0))) - hips_origin
		_upper.rotation.y = lerp_angle(_upper.rotation.y, atan2(-nose.x, -nose.z), _pogo_blend)
	if skitch_pose:
		var center: Vector3 = (Vector3(skitch_grips[0]) + Vector3(skitch_grips[1])) * 0.5
		var toward := (_rider.to_local(center) - hips_origin)
		var yaw := atan2(-toward.x, -toward.z)
		_upper.rotation.y = lerp_angle(_upper.rotation.y, yaw, _skitch_blend)
		_upper.position += Vector3(toward.x, 0, toward.z).limit_length(0.12) * _skitch_blend
	_upper.rotation.z = -steer * 0.045 - manual_balance * _manual_blend * 0.07 * manual_sign
	_upper.rotation.z -= grind_balance * _grind_blend * 0.20
	_upper.rotation.z += grab_body_roll * _grab_blend
	_upper.rotation.z -= grab_lean.x * 0.7
	_upper.rotation.z += -wall_local.x * 0.18 * _wall_blend - _slide_direction * 0.09 * _slide_blend - walk_sway * 0.6
	_upper.rotation.x = lerpf(_upper.rotation.x, -1.50, _bail_blend)
	_upper.rotation.z = lerpf(_upper.rotation.z, 0.30, _bail_blend)
	if _grab_blend > 0.0:
		var unconstrained_torso := _upper.position
		var contact := _rider.to_local(_board.to_global(grab_target))
		for iteration in 4:
			var shoulder := _rider.to_local(_upper.to_global(Vector3(grab_side * 0.195, 0.425, 0)))
			var wrist := _grip_wrist(grab_side, shoulder, contact, grab_stance.x)
			var reach := wrist - shoulder
			if reach.length() <= 0.575: break
			# Solve actual palm reach without lengthening the arm.
			_upper.position += reach.normalized() * (reach.length() - 0.575)
		# Reach belongs to the connected pelvis/torso. Moving only the jacket
		# detached it from the hips; applying a full correction for an arbitrarily
		# small decaying grab influence also kept it at the deck after release.
		var grab_shift := (_upper.position-unconstrained_torso)*_grab_blend
		_upper.position = unconstrained_torso+grab_shift
		hips_origin += grab_shift
		hips_y = hips_origin.y
	if skitch_pose:
		for iteration in 5:
			var correction := Vector3.ZERO
			var count := 0
			for index in 2:
				var side := -1.0 if index == 0 else 1.0
				var shoulder := _rider.to_local(_upper.to_global(Vector3(side * 0.195, 0.425, 0)))
				var contact := _rider.to_local(Vector3(skitch_grips[index]))
				var reach := _grip_wrist(side, shoulder, contact, skitch_axis) - shoulder
				if reach.length() > 0.575:
					correction += reach.normalized() * (reach.length() - 0.575)
					count += 1
			if count == 0: break
			_upper.position += correction / count * _skitch_blend
	if _pogo_blend > 0.0001:
		var unconstrained_torso := _upper.position
		for iteration in 5:
			var correction := Vector3.ZERO
			for side: float in [-1.0, 1.0]:
				var shoulder := _rider.to_local(_upper.to_global(Vector3(side * 0.195, 0.425, 0)))
				var contact := _rider.to_local(_board.to_global(grab_stance * pogo_hand_target(side)))
				var reach := _grip_wrist(side, shoulder, contact, grab_stance.x) - shoulder
				if reach.length() > 0.565: correction += reach.normalized() * (reach.length() - 0.565)
			if correction.length_squared() < 0.000001: break
			_upper.position += correction * 0.5 * _pogo_blend
		# Palm reach lowers the connected body during the wheelstand's entry.
		# Preserve that already blended correction at the pelvis as well, before
		# fitting the fixed-length legs to the unchanged wheel/shoe contacts.
		hips_origin += _upper.position - unconstrained_torso
		hips_y = hips_origin.y
	# Look along accepted travel after a revert, within a comfortable neck turn.
	var travel_body: Node3D = _board.get_parent().get_parent()
	var travel_direction := -travel_body.global_basis.z
	if travel_body is CharacterBody3D:
		var actual: Vector3 = (travel_body as CharacterBody3D).velocity
		if Vector2(actual.x, actual.z).length_squared() > 0.64:
			travel_direction = Vector3(actual.x, 0, actual.z).normalized()
	var look_direction := _rider.global_basis.inverse() * travel_direction
	var look_yaw := clampf(atan2(-look_direction.x, -look_direction.z) - _torso_turn, -1.10, 1.10)
	_head.rotation.y = lerp_angle(_head.rotation.y, look_yaw + steer * 0.06, 1.0 - exp(-8.0 * delta))
	_head.rotation.x = -0.04 + _grab_blend * 0.20 + compression * 0.6
	# Turn about the base of the anatomical neck, keeping its crop inside the collar.
	_head.position = Vector3(0, 0.51, 0.010) - _head.basis * Vector3(0, -0.13, 0.036)
	var pelvis_basis := Basis(Vector3.UP, pelvis_turn)
	var deck_stance := Basis(Vector3.UP, -deck_yaw)
	var foot_poses: Array[Dictionary] = []
	var grounded_drag := false
	for leg: Dictionary in _legs:
		var side: float = leg["side"]
		var deck_foot := Vector3(-0.015 if side < 0.0 else 0.015, PLANTED_FOOT_Y, side * PLANTED_FOOT_Z)
		var shoe_yaw := -PI * 0.5 + side * 0.13
		deck_foot = deck_foot.lerp(Vector3(side * 0.045, PLANTED_FOOT_Y, -side * 0.15), _cross_blend)
		shoe_yaw += side * 0.45 * _cross_blend
		if side > 0.0:
			# Push: planted rearward stroke, then lifted return. Brake: sole drags beside the deck.
			var stroke := minf(_push_phase / 0.60, 1.0)
			var recovery := maxf(0.0, (_push_phase - 0.60) / 0.40)
			var push_z := (lerpf(-0.25, 0.40, stroke) if _push_phase < 0.60 else lerpf(0.40, -0.25, recovery)) * travel_sign
			var push_y := -0.139 + (0.26 * sin(PI * recovery) if recovery > 0.0 else 0.008 * sin(PI * stroke))
			deck_foot.x += 0.25 * _push_blend + 0.24 * _brake_blend
			deck_foot.z = lerpf(deck_foot.z, push_z, _push_blend)
			deck_foot.z = lerpf(deck_foot.z, 0.40 * travel_sign, _brake_blend)
			deck_foot.y += push_y * _push_blend - 0.139 * _brake_blend
			shoe_yaw = lerp_angle(shoe_yaw, -0.08 if travel_sign > 0.0 else PI - 0.08, maxf(_push_blend, _brake_blend))
		else:
			shoe_yaw += 0.20 * _push_blend
		# A spacewalk shuffles one foot while the other stays loaded. The
		# unweighted one-foot leg lifts outward and slightly toward the centre.
		var walk_step := sin(_walk_phase + (0.0 if side < 0.0 else PI))
		deck_foot.z += walk_step * 0.045 * _walk_blend
		deck_foot.y += maxf(0.0, walk_step) * 0.025 * _walk_blend
		var leg_lift := _front_foot_lift if side < 0.0 else _rear_foot_lift
		deck_foot.y += leg_lift
		deck_foot.x += side * leg_lift * 0.35
		deck_foot.z -= side * leg_lift * 0.25
		var helper_catch := transition and side > 0.0 and maxf(_push_blend, _brake_blend) > 0.0
		if helper_catch:
			deck_foot.y += 0.12 * sin(PI * clampf(maxf(_push_blend, _brake_blend), 0.0, 1.0))
		var attached: Vector3 = _rider.to_local(_board.to_global(deck_stance * deck_foot))
		# Shoes follow the planted board except during a deliberately separated board spin/flip.
		var flick_side := -1.0 if flip_id in ["heelflip", "inward_heelflip", "varial_heelflip"] else 1.0
		var flick_offset := Vector3(flick_side * side * 0.065 * flick, 0.40, deck_foot.z)
		var detached := _rider.to_local(_board.get_parent().to_global(flick_offset))
		var target := attached.lerp(detached, _flip_blend)
		# Parent rotations can accumulate harmless floating-point drift; slerp needs unit bases.
		var detached_basis: Basis = _board.get_parent().global_basis.orthonormalized()
		var planted_basis := (_board.global_basis * deck_stance).orthonormalized()
		var foot_basis := planted_basis.slerp(detached_basis, _flip_blend)
		var shoe_basis := foot_basis * Basis(Vector3.UP, shoe_yaw)
		if hang_ten > 0.0001:
			var hang: Dictionary = _hang_ten_support[Vector2(side, 1.0 if cos(rest_deck_yaw) < 0.0 else 0.0)]
			var hang_basis: Basis = _board.global_basis * grab_stance * hang.basis
			target = target.lerp(_rider.to_local(_board.to_global(grab_stance * Vector3(hang.position))), hang_ten)
			shoe_basis = shoe_basis.slerp(hang_basis.orthonormalized(), hang_ten)
		var horizontal_shoe := _surface_basis(Vector3.UP, _board.get_parent().global_basis * Vector3.BACK)
		if _pogo_blend > 0.0001:
			var crown := pogo_foot_contact(side, rest_deck_yaw)
			target = target.lerp(_rider.to_local(crown - horizontal_shoe * Footwear.SOLE_CONTACT), _pogo_blend)
			shoe_basis = shoe_basis.slerp(horizontal_shoe, _pogo_blend)
		if _casper_blend > 0.0001:
			var casper_contact := _board.to_global(grab_stance * Vector3(0, 0.022, -0.29))
			var casper_target: Vector3
			if side < 0:
				casper_target = _rider.to_local(casper_contact - horizontal_shoe * Footwear.TOE_CONTACT)
			else:
				var tail := _board.to_global(grab_stance * Vector3(0, -0.025, 0.255))
				casper_target = _rider.to_local(tail - horizontal_shoe * Footwear.SOLE_CONTACT)
			target = target.lerp(casper_target, _casper_blend)
			shoe_basis = shoe_basis.slerp(horizontal_shoe, _casper_blend)
		if maxf(_pogo_blend, _casper_blend) > 0.0001:
			# A changing shoe orientation sweeps a wider sole than its ankle target.
			# Keep every actual cupsole vertex above the native support plane.
			var floor_up: Vector3 = _board.get_parent().global_basis.y.normalized()
			var floor_at: Vector3 = _board.get_parent().global_position
			var ankle := _rider.to_global(target)
			var lowest := INF
			for point: Vector3 in _sole_points:
				lowest = minf(lowest, (ankle + shoe_basis * point - floor_at).dot(floor_up))
			if lowest < 0.001: target = _rider.to_local(ankle + floor_up * (0.001 - lowest))
		if hang_ten > 0.0001 or maxf(_front_foot_lift, _rear_foot_lift) > 0.0001 or helper_catch:
			# A rotating/moving sole sweeps across the kick before reaching its
			# settled bearing. Bound real rubber compression through that sweep.
			var ankle := _board.to_local(_rider.to_global(target))
			var local_shoe := _board.global_basis.inverse() * shoe_basis
			var lowest := INF
			for point: Vector3 in _sole_points:
				var sample := ankle + local_shoe * point
				var height := _deck_top_height_at(sample)
				if is_finite(height): lowest = minf(lowest, sample.y - height)
			if lowest < -0.001:
				ankle.y += -0.001 - lowest
				target = _rider.to_local(_board.to_global(ankle))
		if side < 0.0:
			if setup and setup_plant > 0.0:
				var ground_basis := _surface_basis(setup_normal, shoe_basis.z)
				var ground_ankle := _rider.to_local(setup_point - ground_basis * Footwear.SOLE_CONTACT)
				target = target.lerp(ground_ankle, setup_plant)
				shoe_basis = shoe_basis.slerp(ground_basis, setup_plant)
				_setup_catch_offset = target - attached
				_setup_catch_basis = shoe_basis
				_setup_last_id = setup_id
			elif setup_catch > 0.0:
				target += _setup_catch_offset * setup_catch
				shoe_basis = shoe_basis.slerp(_setup_catch_basis, setup_catch)
		if side > 0.0 and not air and not manual and not grind and not lip and not wall and not setup and not skitch \
				and not transition \
				and maxf(_push_blend, _brake_blend) > 0.0001:
			var loaded := maxf(_brake_blend, _push_blend if _push_phase < 0.60 else 0.0)
			var contact := _drag_foot_contact(target, shoe_basis, loaded)
			target = contact.target
			shoe_basis = contact.basis
			grounded_drag = bool(contact.supported)
		target = target.lerp(Vector3(side * 0.30, 0.14, 0.72), _bail_blend)
		shoe_basis = shoe_basis.slerp((_rider.global_basis * Basis(Vector3.UP, side * 0.08)).orthonormalized(), _bail_blend)
		foot_poses.append({"leg": leg, "target": target, "basis": shoe_basis})
	var crouch_needed := 0.0
	if grounded_drag:
		# Keep both actual shoe contacts. Lower the common pelvis/torso only
		# enough for the two real leg chains to reach them, instead of stretching
		# a calf or lifting a supposedly planted shoe away from its native floor.
		for pose: Dictionary in foot_poses:
			var hip := pelvis_basis * Vector3(float(pose.leg.side) * 0.105, 0.025, 0) + hips_origin
			var target: Vector3 = pose.target
			var across := Vector2(hip.x - target.x, hip.z - target.z).length_squared()
			var vertical := sqrt(maxf(0.0001, 0.825 * 0.825 - across))
			crouch_needed = maxf(crouch_needed, hip.y - target.y - vertical)
	_drag_crouch = maxf(crouch_needed, _blend(_drag_crouch, 0.0, delta, 14.0))
	if _drag_crouch < 0.00001: _drag_crouch = 0.0
	hips_origin.y -= _drag_crouch
	hips_y -= _drag_crouch
	_upper.position.y -= _drag_crouch
	# Retain the default branch's fixed-length leg fit in every pose, including
	# local bail recovery. Keep both real contact targets and fit their common
	# pelvis, rather than stretching a calf or clamping a planted shoe.
	var pelvis_offset := Vector3.ZERO
	for iteration in 8:
		var previous := pelvis_offset
		for pose: Dictionary in foot_poses:
			var hip := pelvis_basis * Vector3(float(pose.leg.side) * 0.105, 0.025, 0) + hips_origin + pelvis_offset
			var offset: Vector3 = hip - Vector3(pose.target)
			var excess := offset.length() - 0.832
			if excess > 0.0: pelvis_offset -= offset.normalized() * excess
		if previous.distance_squared_to(pelvis_offset) < 0.0000000001: break
	hips_origin += pelvis_offset
	hips_y = hips_origin.y
	_upper.position += pelvis_offset
	_garments.pose_body(Transform3D(pelvis_basis, hips_origin), _upper.transform)
	for pose: Dictionary in foot_poses:
		var leg: Dictionary = pose.leg
		var side: float = leg.side
		var target: Vector3 = pose.target
		var shoe_basis: Basis = pose.basis
		var hip := pelvis_basis * Vector3(side * 0.105, 0.025, 0) + hips_origin
		# Knees bend in the rider's sagittal plane, independently of a spinning
		# deck or a wall normal. An upward pole can reverse through the pelvis.
		var knee_bend := pelvis_basis * Vector3(side*0.35,0,-1.0)
		var knee := _joint(hip, target, 0.43, 0.41, knee_bend)
		_garments.pose_leg(side, hip, knee, target)
		leg["foot"].position = target
		leg["foot"].basis = (_rider.global_basis.inverse() * shoe_basis).orthonormalized()
	for arm: Dictionary in _arms:
		var side: float = arm["side"]
		var shoulder: Vector3 = _rider.to_local(_upper.to_global(Vector3(side * 0.195, 0.425, 0)))
		var spread := 0.33 + 0.12 * _air_blend + 0.13 * _grind_blend + 0.07 * _manual_blend + 0.08 * _slide_blend + 0.055 * _lip_blend
		var hand := Vector3(side * spread, hips_y + 0.015 + 0.12 * _air_blend + 0.10 * _grind_blend, -0.14 + side * 0.09)
		hand.z += side * 0.17 * sin(TAU * _push_phase) * _push_blend
		hand.y += side * (grind_balance * _grind_blend * 0.13 + manual_balance * _manual_blend * 0.08 * manual_sign)
		hand.z += side * sin(grind_yaw) * _grind_blend * 0.10
		hand.y -= 0.09 * _crouch_blend
		hand.z -= 0.10 * _crouch_blend
		hand.y += side * walk_sway * 0.65 + 0.07 * _lip_blend
		hand.z += side * _slide_direction * 0.12 * _slide_blend
		if hang_ten > 0.0:
			# Both arms turn with the forward-facing Hang Ten torso rather than
			# retaining the ordinary sideways stance's far wrist positions.
			hand = hand.lerp(_rider.to_local(_upper.to_global(Vector3(side * 0.34, 0.10, -0.10))), hang_ten)
		if side * wall_local.x < 0.0:
			var wall_hand := Vector3(side * 0.32, hips_y + 0.38, -0.10) - wall_local * 0.045
			hand = hand.lerp(wall_hand, _wall_blend)
		var revert_remaining: float = state.get("revert_remaining", 0.0)
		hand.z += side * 0.16 * sin(PI * clampf(revert_remaining / 0.18, 0.0, 1.0))
		if tumble > 0.0:
			hand = hand.lerp(Vector3(side * 0.16, hips_y + 0.12, -0.18), tumble * 0.8)
		if salute and side < 0.0:
			hand = hand.lerp(Vector3(-0.30, hips_y + 0.68, -0.03), sin(PI * special_progress))
		hand = hand.lerp(Vector3(side * 0.48, 0.12, -0.48), _bail_blend)
		var palm_grip := _grab_blend if side == grab_side else 0.0
		var palm_axis := grab_stance.x
		if side == grab_side and _grab_blend > 0.0:
			var contact_target := _rider.to_local(_board.to_global(grab_target))
			# The anatomical hand's origin is its wrist, not its palm. Solve that
			# offset so the distal palm meets the rail edge instead of passing through it.
			var grab_wrist := contact_target + (shoulder - contact_target).normalized() * 0.075
			for iteration in 4:
				var grab_elbow := _joint(shoulder, grab_wrist, 0.30, 0.29, Vector3(side * 0.65, -0.10, 0.55))
				var grab_basis := _hand_basis(side, grab_elbow - grab_wrist, 1.0, grab_stance.x)
				grab_wrist = contact_target - grab_basis * Vector3(0, -0.075, -0.015)
			hand = hand.lerp(grab_wrist, _grab_blend)
		if side > 0.0 and boneless_grip > 0.0:
			var boneless_target := _rider.to_local(_board.to_global(grab_stance * boneless_grab_target()))
			hand = hand.lerp(_grip_wrist(side, shoulder, boneless_target, grab_stance.x), boneless_grip)
			palm_grip = maxf(palm_grip, boneless_grip)
		if _pogo_blend > 0.0001:
			var nose_contact := _rider.to_local(_board.to_global(grab_stance * pogo_hand_target(side)))
			hand = hand.lerp(_grip_wrist(side, shoulder, nose_contact, grab_stance.x), _pogo_blend)
			palm_grip = maxf(palm_grip, _pogo_blend)
		if skitch_pose:
			var grip: Vector3 = skitch_grips[0 if side < 0 else 1]
			var tow_weight := _skitch_blend * (1.0 - maxf(_grab_blend, boneless_grip)) * (1.0 - _flip_blend)
			hand = hand.lerp(_grip_wrist(side, shoulder, _rider.to_local(grip), skitch_axis), tow_weight)
			palm_grip = maxf(palm_grip, tow_weight)
			palm_axis = palm_axis.slerp(skitch_axis, tow_weight).normalized()
		hand = _reachable(shoulder, hand, 0.30, 0.29)
		var elbow := _joint(shoulder, hand, 0.30, 0.29, Vector3(side * 0.65, -0.10, 0.55))
		_garments.pose_arm(side, shoulder, elbow, hand)
		arm["hand"].position = hand
		arm["hand"].basis = _hand_basis(side, elbow - hand, palm_grip, palm_axis)
		_anatomy.pose_hand(arm["hand"], palm_grip)
	if _handplant_blend > 0.0001:
		_apply_handplant(_handplant_blend, rest_deck_yaw)


func _surface_basis(up: Vector3, facing: Vector3) -> Basis:
	var z := facing.slide(up).normalized()
	if z.length_squared() < 0.01: z = Vector3.FORWARD.slide(up).normalized()
	if z.length_squared() < 0.01: z = Vector3.RIGHT.slide(up).normalized()
	var x := up.cross(z).normalized()
	return Basis(x, up, x.cross(up).normalized())


func _native_foot_ground(at: Vector3) -> Dictionary:
	var body: Node3D = _board.get_parent().get_parent()
	if not body is CharacterBody3D: return {}
	# World/cart solids only. Grind steel and triggers cannot become invented
	# foot support, and an absent finite floor produces no fallback plane.
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.35,
		at - Vector3.UP * 0.45, body.collision_mask & 9)
	query.exclude = [body.get_rid()]
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP) < 0.65: return {}
	return hit


func _drag_foot_contact(target: Vector3, shoe_basis: Basis, loaded: float) -> Dictionary:
	var ankle := _rider.to_global(target)
	var ground := _native_foot_ground(ankle + shoe_basis * Footwear.SOLE_CONTACT)
	var supported := not ground.is_empty()
	if not ground.is_empty() and loaded > 0.0001:
		var normal: Vector3 = ground.normal
		var planted := _surface_basis(normal, shoe_basis.z)
		shoe_basis = shoe_basis.slerp(planted, loaded).orthonormalized()
		var contact: Vector3 = ground.position + normal * 0.0007
		ankle = ankle.lerp(contact - shoe_basis * Footwear.SOLE_CONTACT, loaded)
	# The trailing shoe can straddle a bank toe and its adjoining flat floor.
	# Check its actual outline against each finite native surface, rather than
	# extending the board's tangent plane underneath the entire stroke.
	var correction := 0.0
	for point: Vector3 in _sole_points:
		if point.y > -0.0604: continue
		var sole := ankle + shoe_basis * point
		var support := _native_foot_ground(sole)
		if not support.is_empty():
			supported = true
			correction = maxf(correction, float(support.position.y) + 0.0007 - sole.y)
	var toe := ankle + shoe_basis * Footwear.TOE_CONTACT
	var support := _native_foot_ground(toe)
	if not support.is_empty():
		supported = true
		correction = maxf(correction, float(support.position.y) + 0.0007 - toe.y)
	return {"target": _rider.to_local(ankle + Vector3.UP * correction), "basis": shoe_basis, "supported": supported}


func _cache_support_geometry() -> void:
	if _native_board_cache.is_empty():
		var points := PackedVector3Array()
		var grip := PackedVector3Array()
		var wood := PackedVector3Array()
		var wheels: Array[Dictionary] = []
		for end: float in [-1.0, 1.0]:
			for side: float in [-1.0, 1.0]:
				wheels.append({"center": Vector3(side * 0.115, -0.088, end * 0.255), "points": PackedVector3Array()})
		for mesh: MeshInstance3D in _board_meshes:
			var local := _board.global_transform.affine_inverse() * mesh.global_transform
			for surface in mesh.mesh.get_surface_count():
				var arrays := mesh.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var material := mesh.mesh.surface_get_material(surface)
				var name := material.resource_name if material != null else ""
				for point: Vector3 in vertices:
					var at := local * point
					points.append(at)
					# Wheel and bushing use the same urethane surface. Only the
					# four actual outer wheel components belong in the floor fit.
					if name == "Urethane" and absf(at.x) > 0.09:
						var wheel_index := (2 if at.z > 0.0 else 0) + (1 if at.x > 0.0 else 0)
						wheels[wheel_index].points.append(at)
				if name not in ["Griptape", "MapleAndRiverInk"]: continue
				var faces := PackedVector3Array()
				if indices.is_empty():
					for point: Vector3 in vertices: faces.append(local * point)
				else:
					for index: int in indices: faces.append(local * vertices[index])
				if name == "Griptape": grip.append_array(faces)
				else: wood.append_array(faces)
		var hull := ConvexPolygonShape3D.new()
		hull.points = points
		_native_board_cache = {"grip": grip, "wood": wood, "wheels": wheels,
			"support": hull.get_debug_mesh().get_faces()}
	_grip_faces = _native_board_cache.grip
	_wood_faces = _native_board_cache.wood
	_wheel_surfaces.assign(_native_board_cache.wheels)
	_board_support_points = _native_board_cache.support
	var sole: MeshInstance3D = _legs[0].foot.get_node("Cupsole")
	var unique: Dictionary = {}
	for point: Vector3 in sole.mesh.get_faces(): unique[point] = true
	_sole_points.clear()
	for point: Vector3 in unique: _sole_points.append(point)


func _cache_deck_surface_grid() -> void:
	# Native mesh triangles remain the contact authority; a small fixed spatial
	# index avoids scanning the whole tessellated deck for each moving sole.
	_deck_top_faces.clear()
	_deck_surface_grid.clear()
	for faces: PackedVector3Array in [_grip_faces, _wood_faces]:
		for index in range(0, faces.size(), 3):
			var a := faces[index]
			var b := faces[index + 1]
			var c := faces[index + 2]
			# Godot's front faces use clockwise winding: the rendered top's
			# geometric cross product points down, while its visible normal is up.
			if (b - a).cross(c - a).y > -0.0000000001: continue
			var triangle := _deck_top_faces.size()
			_deck_top_faces.append_array(PackedVector3Array([a, b, c]))
			var from := Vector2i(floori(minf(a.x, minf(b.x, c.x)) / 0.025), floori(minf(a.z, minf(b.z, c.z)) / 0.025))
			var to := Vector2i(floori(maxf(a.x, maxf(b.x, c.x)) / 0.025), floori(maxf(a.z, maxf(b.z, c.z)) / 0.025))
			for x in range(from.x, to.x + 1):
				for z in range(from.y, to.y + 1):
					var cell := Vector2i(x, z)
					if not _deck_surface_grid.has(cell): _deck_surface_grid[cell] = []
					_deck_surface_grid[cell].append(triangle)


func _deck_top_height_at(point: Vector3) -> float:
	var height := -INF
	var p := Vector2(point.x, point.z)
	var cell := Vector2i(floori(point.x / 0.025), floori(point.z / 0.025))
	for index: int in _deck_surface_grid.get(cell, []):
		var a := Vector2(_deck_top_faces[index].x, _deck_top_faces[index].z)
		var ab := Vector2(_deck_top_faces[index + 1].x, _deck_top_faces[index + 1].z) - a
		var ac := Vector2(_deck_top_faces[index + 2].x, _deck_top_faces[index + 2].z) - a
		var determinant := ab.cross(ac)
		var u := (p - a).cross(ac) / determinant
		var v := ab.cross(p - a) / determinant
		if u >= -0.00001 and v >= -0.00001 and u + v <= 1.00001:
			height = maxf(height, _deck_top_faces[index].y * (1.0 - u - v)
				+ _deck_top_faces[index + 1].y * u + _deck_top_faces[index + 2].y * v)
	return height


func _cache_hang_ten_support() -> void:
	if not _hang_ten_support.is_empty(): return
	# A rigid shoe bridges the curved kick on its actual heel/forefoot edges.
	# Fit those rendered sole vertices once during loading, rather than sliding
	# a nominal ankle point beyond the nose or deforming the deck underneath it.
	for rest: float in [0.0, PI]:
		for side: float in [-1.0, 1.0]:
			var at := Vector3(side * 0.066, 0, -0.240)
			var pitch := 0.08
			for iteration in 4:
				var limits := _hang_ten_limits(at, Basis(Vector3.RIGHT, pitch), rest)
				pitch = clampf(pitch + (limits.x - limits.y) / 0.265, 0.0, 0.22)
			var basis := Basis(Vector3.RIGHT, pitch)
			var limits := _hang_ten_limits(at, basis, rest)
			at.y = maxf(limits.x, maxf(limits.y, limits.z)) + 0.00015
			_hang_ten_support[Vector2(side, 1.0 if rest > 0.0 else 0.0)] = {"position": at, "basis": basis}


func _hang_ten_limits(at: Vector3, basis: Basis, rest: float) -> Vector3:
	var result := Vector3(-INF, -INF, -INF)
	var stance := Basis(Vector3.UP, -rest)
	for point: Vector3 in _sole_points:
		if point.y > -0.0604: continue
		var rotated := basis * point
		var sample := stance * (at + rotated)
		var height := _deck_top_height_at(sample)
		if not is_finite(height): continue
		var required := height - rotated.y
		if point.z < -0.025: result.x = maxf(result.x, required)
		elif point.z > 0.025: result.y = maxf(result.y, required)
		else: result.z = maxf(result.z, required)
	return result


func pogo_foot_contact(side: float, rest_yaw: float) -> Vector3:
	# Select the functional rear wheel after a committed deck half-turn, then
	# use its real rendered crown. Averaging equal-height cap vertices gives
	# the centre of that same top edge, rather than an invented contact offset.
	var center := Basis(Vector3.UP, -rest_yaw) * Vector3(side * 0.115, -0.088, 0.255)
	var selected: Dictionary = {}
	var distance := INF
	for wheel: Dictionary in _wheel_surfaces:
		var gap := center.distance_squared_to(wheel.center)
		if gap < distance:
			distance = gap
			selected = wheel
	var crown := Vector3.ZERO
	var height := -INF
	var count := 0
	for point: Vector3 in selected.get("points", PackedVector3Array()):
		var world := _board.to_global(point)
		if world.y > height + 0.00001:
			height = world.y
			crown = world
			count = 1
		elif absf(world.y - height) < 0.00001:
			crown += world
			count += 1
	return crown / maxf(1.0, count)


func _grip_wrist(side: float, shoulder: Vector3, contact: Vector3, palm_axis: Vector3) -> Vector3:
	var wrist := contact + (shoulder - contact).normalized() * 0.075
	for iteration in 8:
		var elbow := _joint(shoulder, wrist, 0.30, 0.29, Vector3(side * 0.65, -0.10, 0.55))
		var basis := _hand_basis(side, elbow - wrist, 1.0, palm_axis)
		wrist = contact - basis * Anatomy.PALM_CONTACT
	return wrist


func _palm_surface_basis(up: Vector3, finger_heading: Vector3) -> Basis:
	var y := -finger_heading.slide(up).normalized()
	if y.length_squared() < 0.01: y = Vector3.RIGHT.slide(up).normalized()
	var x := y.cross(up).normalized()
	return Basis(x, up.cross(x).normalized(), up)


func _apply_handplant(weight: float, rest_yaw: float) -> void:
	if not _lip_point.is_finite() or not _lip_normal.is_finite() or _lip_normal.length_squared() < 0.01:
		return
	var ordinary := _snapshot_pose()
	var normal := _lip_normal.normalized()
	var world_forward: Vector3 = _board.get_parent().global_basis.z.slide(normal).normalized()
	var world_frame := _surface_basis(normal, world_forward)
	var inverted := _surface_basis(-normal, world_forward)
	var hand_side := float(_lip_definition.get("lip_hand_side", 1.0))
	var body_roll := float(_lip_definition.get("lip_body_roll", 0.0))
	var hips_world := _lip_point + normal * 0.92 + world_frame.x * hand_side * 0.08
	var world_body_basis := inverted * Basis(Vector3.BACK, body_roll)
	var original_hips := hips_world
	var world_palm_basis := _palm_surface_basis(normal, world_frame.z)
	# Fit the pelvis to the planted arm span, rather than stretching a sleeve
	# to disguise an unreachable two-palm invert. The board follows the legs.
	for iteration in 6:
		var correction := Vector3.ZERO
		var count := 0
		for side: float in [-1.0, 1.0]:
			if not is_zero_approx(hand_side) and side != hand_side: continue
			var palm := _lip_point + (world_frame.x * side * 0.14 if is_zero_approx(hand_side) else Vector3.ZERO)
			var shoulder := hips_world + world_body_basis * Vector3(side * 0.195, 0.425, 0)
			var wrist := palm - world_palm_basis * Anatomy.PALM_CONTACT
			var reach := wrist - shoulder
			if reach.length() > 0.575:
				correction += reach.normalized() * (reach.length() - 0.575)
				count += 1
		if count == 0: break
		hips_world += correction / count
	var hips := _rider.to_local(hips_world)
	var body_basis := (_rider.global_basis.inverse() * world_body_basis).orthonormalized()
	_upper.transform = Transform3D(body_basis, hips)
	_garments.pose_body(Transform3D(body_basis, hips), _upper.transform)
	_head.rotation = Vector3(0.08, 0, 0)
	_head.position = Vector3(0, 0.51, 0.010) - _head.basis * Vector3(0, -0.13, 0.036)
	# When the palms carry the rider, the deck follows the soles above the
	# inverted body. The actual root-provided steel contact remains the support.
	_board.global_basis = inverted * Basis.from_euler(Vector3(float(_lip_definition.get("lip_pitch", 0.0)),
		float(_lip_definition.get("lip_yaw", 0.0)), float(_lip_definition.get("lip_roll", 0.0)))) * Basis(Vector3.UP, rest_yaw)
	_board.global_position = _lip_point + normal * 1.60 + world_frame.x * hand_side * 0.08 + hips_world - original_hips
	var deck_stance := Basis(Vector3.UP, -rest_yaw)
	for iteration in 4:
		var excess := 0.0
		for side: float in [-1.0, 1.0]:
			var ankle := _board.to_global(deck_stance * Vector3(-0.015 if side < 0 else 0.015, PLANTED_FOOT_Y, side * PLANTED_FOOT_Z))
			var hip := hips_world + world_body_basis * Vector3(side * 0.105, 0.025, 0)
			excess = maxf(excess, ankle.distance_to(hip) - 0.825)
		if excess <= 0.0001: break
		_board.global_position -= normal * excess * 1.2
	for leg: Dictionary in _legs:
		var side: float = leg.side
		var target := _rider.to_local(_board.to_global(deck_stance * Vector3(-0.015 if side < 0 else 0.015, PLANTED_FOOT_Y, side * PLANTED_FOOT_Z)))
		var hip := hips + body_basis * Vector3(side * 0.105, 0.025, 0)
		var knee := _joint(hip, target, 0.43, 0.41, body_basis * Vector3(side * 0.7, 0.3, -0.4))
		_garments.pose_leg(side, hip, knee, target)
		var shoe_basis := (_rider.global_basis.inverse() * _board.global_basis * deck_stance * Basis(Vector3.UP, -PI * 0.5 + side * 0.13)).orthonormalized()
		leg.foot.transform = Transform3D(shoe_basis, target)
	for arm: Dictionary in _arms:
		var side: float = arm.side
		var shoulder := _rider.to_local(_upper.to_global(Vector3(side * 0.195, 0.425, 0)))
		var contact := _lip_point
		if is_zero_approx(hand_side): contact += world_frame.x * side * 0.14
		var planted := is_zero_approx(hand_side) or side == hand_side
		var palm_basis := (_rider.global_basis.inverse() * _palm_surface_basis(normal, world_frame.z)).orthonormalized()
		var wrist := _rider.to_local(contact) - palm_basis * Anatomy.PALM_CONTACT
		if not planted:
			wrist = _rider.to_local(_lip_point + normal * 0.86 + world_frame.x * side * 0.40)
			wrist = shoulder + (wrist - shoulder).limit_length(0.575)
		var elbow := _joint(shoulder, wrist, 0.30, 0.29, body_basis * Vector3(side * 0.8, 0.1, -0.6))
		_garments.pose_arm(side, shoulder, elbow, wrist)
		arm.hand.transform = Transform3D(palm_basis if planted else _hand_basis(side, elbow - wrist, 0.0), wrist)
		_anatomy.pose_hand(arm.hand, 0.0)
	_blend_pose_snapshot(ordinary, weight)


func _snapshot_pose() -> Dictionary:
	var result := {"board": _board.transform, "upper": _upper.transform,
		"head": _head.transform, "feet": [], "hands": [], "bones": []}
	for leg: Dictionary in _legs: result.feet.append(leg.foot.transform)
	for arm: Dictionary in _arms: result.hands.append(arm.hand.transform)
	for index in _garments.skeleton.get_bone_count():
		result.bones.append(_garments.skeleton.get_bone_pose(index))
	return result


func _blend_pose_snapshot(from: Dictionary, weight: float) -> void:
	_board.transform = (from.board as Transform3D).interpolate_with(_board.transform, weight)
	_upper.transform = (from.upper as Transform3D).interpolate_with(_upper.transform, weight)
	_head.transform = (from.head as Transform3D).interpolate_with(_head.transform, weight)
	for index in _legs.size():
		_legs[index].foot.transform = (from.feet[index] as Transform3D).interpolate_with(_legs[index].foot.transform, weight)
	for index in _arms.size():
		_arms[index].hand.transform = (from.hands[index] as Transform3D).interpolate_with(_arms[index].hand.transform, weight)
	for index in _garments.skeleton.get_bone_count():
		var desired: Transform3D = _garments.skeleton.get_bone_pose(index)
		var result: Transform3D = (from.bones[index] as Transform3D).interpolate_with(desired, weight)
		_garments.skeleton.set_bone_pose_position(index, result.origin)
		_garments.skeleton.set_bone_pose_rotation(index, result.basis.orthonormalized().get_rotation_quaternion())
		_garments.skeleton.set_bone_pose_scale(index, result.basis.get_scale())

func _grind_support(grind_id: String, grind_yaw: float) -> Vector3:
	# Actual default GLB belly and cast hanger undersides. Native verified
	# GrindStyle transforms bypass this legacy compatibility path entirely.
	if grind_id in ["boardslide", "lipslide"] or absf(sin(grind_yaw)) > 0.7:
		return Vector3(0, -0.014, 0)
	if grind_id in ["nosegrind", "crooked_grind", "overcrook_grind"]:
		return Vector3(0, -0.103, -0.255)
	if grind_id in ["five_o_grind", "smith_grind", "feeble_grind"]:
		return Vector3(0, -0.103, 0.255)
	return Vector3(0, -0.103, 0)

func _hand_basis(side: float, forearm: Vector3, grabbing: float, palm_axis: Vector3 = Vector3.RIGHT) -> Basis:
	var y := forearm.normalized()
	var neutral := Basis(Quaternion(Vector3.UP, y)) * Basis(Vector3.UP, side * PI * 0.5)
	var palm_direction: Vector3 = _rider.global_basis.inverse() * _board.global_basis * palm_axis
	var z := -palm_direction.slide(y).normalized()
	if z.length_squared() < 0.01:
		return neutral
	var x := y.cross(z).normalized()
	var grab_basis := Basis(x, y, x.cross(y).normalized())
	return neutral.orthonormalized().slerp(grab_basis, grabbing)

func _blend(current: float, target: float, delta: float, rate: float) -> float:
	return lerpf(current, target, 1.0 - exp(-rate * delta))

func _joint(start: Vector3, end: Vector3, upper_length: float, lower_length: float, bend: Vector3) -> Vector3:
	var offset := end - start
	var distance := maxf(offset.length(), 0.001)
	var direction := offset / distance if offset.length_squared() > 0.000001 else Vector3.DOWN
	var reach := clampf(distance, absf(upper_length - lower_length) + 0.001, upper_length + lower_length - 0.001)
	var along := (upper_length * upper_length - lower_length * lower_length + reach * reach) / (2.0 * reach)
	var height := sqrt(maxf(0.0, upper_length * upper_length - along * along))
	var pole := bend.slide(direction).normalized()
	if pole.length_squared() < 0.01:
		pole = (Vector3.UP if absf(direction.dot(Vector3.RIGHT)) > 0.9 else Vector3.RIGHT).slide(direction).normalized()
	return start + direction * along + pole * height


func _reachable(start: Vector3, target: Vector3, upper: float, lower: float) -> Vector3:
	var offset := target - start
	var direction := offset.normalized() if offset.length_squared() > 0.000001 else Vector3.DOWN
	return start + direction * clampf(offset.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)

func _build_board() -> void:
	# The default branch's original one-mesh/four-surface board is the visible
	# asset and the contact authority. Do not rebuild the procedural substitute.
	var model := Skateboard.instantiate()
	model.name = "DetailedSkateboard"
	_board.add_child(model)
	_collect_board_meshes(model)


func _collect_board_meshes(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null: _board_meshes.append(node)
	for child: Node in node.get_children(): _collect_board_meshes(child)


func board_contact_geometry() -> Dictionary:
	# Board-local immutable actual rendered vertices. Callers must not mutate
	# these shared cached arrays; mesh references point at the visible GLB.
	return {"grip_faces": _grip_faces, "wood_faces": _wood_faces,
		"wheels": _wheel_surfaces, "support_points": _board_support_points,
		"meshes": _board_meshes}


func _grip_height_at(point: Vector3) -> float:
	return _surface_height_at(_grip_faces, point)


func _surface_height_at(faces: PackedVector3Array, point: Vector3) -> float:
	var height := -INF
	var p := Vector2(point.x, point.z)
	for index in range(0, faces.size(), 3):
		var a := Vector2(faces[index].x, faces[index].z)
		var ab := Vector2(faces[index + 1].x, faces[index + 1].z) - a
		var ac := Vector2(faces[index + 2].x, faces[index + 2].z) - a
		var determinant := ab.cross(ac)
		if absf(determinant) < 0.0000000001: continue
		var u := (p - a).cross(ac) / determinant
		var v := ab.cross(p - a) / determinant
		if u >= -0.00001 and v >= -0.00001 and u + v <= 1.00001:
			height = maxf(height, faces[index].y * (1.0 - u - v)
				+ faces[index + 1].y * u + faces[index + 2].y * v)
	return height

func _loft(parent: Node3D, node_name: String, rings: Array, material: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 20
	for ring_index in range(rings.size() - 1):
		var lower: Vector4 = rings[ring_index]
		var upper: Vector4 = rings[ring_index + 1]
		for i in range(SEGMENTS):
			var angle := TAU * float(i) / SEGMENTS
			var next_angle := TAU * float(i + 1) / SEGMENTS
			var a := Vector3(cos(angle) * lower.y, lower.x, sin(angle) * lower.z + lower.w)
			var b := Vector3(cos(next_angle) * lower.y, lower.x, sin(next_angle) * lower.z + lower.w)
			var c := Vector3(cos(angle) * upper.y, upper.x, sin(angle) * upper.z + upper.w)
			var d := Vector3(cos(next_angle) * upper.y, upper.x, sin(next_angle) * upper.z + upper.w)
			_triangle(surface, a, b, c)
			_triangle(surface, b, d, c)
	for end_index: int in [0, rings.size() - 1]:
		var ring: Vector4 = rings[end_index]
		for i in range(SEGMENTS):
			var a := Vector3(cos(TAU * float(i) / SEGMENTS) * ring.y, ring.x, sin(TAU * float(i) / SEGMENTS) * ring.z + ring.w)
			var b := Vector3(cos(TAU * float(i + 1) / SEGMENTS) * ring.y, ring.x, sin(TAU * float(i + 1) / SEGMENTS) * ring.z + ring.w)
			_triangle(surface, Vector3(0, ring.x, ring.w), a if end_index > 0 else b, b if end_index > 0 else a)
	surface.generate_normals()
	return _instance(parent, node_name, surface.commit(), material)

func _material(color: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _ellipsoid(parent: Node3D, node_name: String, center: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var result := _instance(parent, node_name, _sphere, material)
	result.position = center
	result.scale = size * 0.5
	return result

func _segment(parent: Node3D, node_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var result := _instance(parent, node_name, _cylinder, material)
	_pose_segment(result, start, end, radius)
	return result

func _pose_segment(node: MeshInstance3D, start: Vector3, end: Vector3, radius: float) -> void:
	var direction := end - start
	node.position = (start + end) * 0.5
	node.quaternion = Quaternion(Vector3.UP, direction.normalized()) if direction.length_squared() > 0.000001 else Quaternion.IDENTITY
	node.scale = Vector3(radius, maxf(direction.length(), 0.001), radius)

func _instance(parent: Node3D, node_name: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = node_name
	result.mesh = mesh
	result.material_override = material
	parent.add_child(result)
	return result

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
