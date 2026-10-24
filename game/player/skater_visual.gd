extends RefCounted
## Original skating clothes/board with attributed CC0 anatomical head and hands.
## Geometry and animation only: native skinning and analytic contact poses, no physics.

const Garments = preload("res://game/player/skater_garments.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const Anatomy = preload("res://game/player/skater_anatomy.gd")

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
var _slide_direction := 1.0

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
	_slide_direction = 1.0

func animate(delta: float, state: Dictionary) -> void:
	var air: bool = state["airborne"]
	var grab: bool = state["grab"]
	var flip: bool = state["flip"]
	var manual: bool = state["manual"]
	var grind: bool = state["grind"]
	var ride_speed := absf(float(state["speed"]))
	var wall: bool = state.get("wallriding", false)
	var lip: bool = state.get("lip_active", false)
	var sliding: bool = state.get("powersliding", false) and not air and not manual and not grind
	var crouching: bool = state.get("crouching", false) and not air and not manual and not grind and not lip
	var charge := clampf(float(state.get("ollie_charge", 0.0)), 0.0, 1.0)
	var walking: bool = manual and bool(state.get("manual_walk", false))
	var manual_roll := float(state.get("manual_roll", 0.0))
	var foot_lift := clampf(float(state.get("manual_foot_lift", 0.0)), 0.0, 0.3) if manual else 0.0
	var braking: bool = state.get("brake", false) and not air and not manual and not grind and not sliding and ride_speed > 0.2
	var pushing: bool = state["push"] and not braking and not air and not manual and not grind and not crouching and not sliding and not lip and ride_speed < 14.5
	var steer: float = state.get("steering", 0.0)
	var manual_balance: float = state.get("manual_balance", 0.0)
	var grind_balance: float = state.get("grind_balance", 0.0)
	var special_id: String = state.get("special_id", "")
	var special_progress: float = state.get("special_progress", 0.0)
	var flip_progress := clampf(float(state.get("flip_progress", 0.5)), 0.0, 1.0)
	var flip_id: String = state.get("flip_id", "kickflip")
	var grab_side := -1.0 if float(state.get("grab_side", -1.0)) < 0.0 else 1.0
	var grab_target: Vector3 = state.get("grab_target", Vector3(-0.128, 0.022, -0.035))
	var rest_deck_yaw: float = state.get("rest_deck_yaw", 0.0)
	var grab_stance := Basis(Vector3.UP, -rest_deck_yaw)
	grab_target = grab_stance * grab_target
	var grind_yaw: float = state.get("grind_yaw", 0.0)
	var grind_id: String = state.get("grind_id", "rail_grind")
	var deck_yaw: float = state.get("deck_yaw", 0.0) if not grind else 0.0
	var manual_sign: float = state.get("manual_sign", 1.0)
	var takeoff_mode := str(state.get("takeoff_mode", "Regular")).to_lower()
	var launch_id := str(state.get("launch_id", "nollie" if takeoff_mode == "nollie" else "ollie"))
	var launch_age := maxf(0.0, float(state.get("launch_age", 1.0)))
	var launch_curve := sin(PI * clampf(launch_age / 0.22, 0.0, 1.0)) if air and not flip else 0.0
	var nose_pop := launch_curve if launch_id == "nollie" else 0.0
	var wall_normal: Vector3 = state.get("wall_normal", Vector3.ZERO)
	var wall_local := Vector3.ZERO
	if wall_normal.is_finite() and wall_normal.length_squared() > 0.01:
		wall_local = _rider.global_basis.inverse() * wall_normal.normalized()
	var board_spin := special_id == "special_clyde_carousel"
	var tumble := sin(PI * special_progress) if special_id == "special_tenement_tumble" else 0.0
	if _was_airborne and not air:
		_landing = 0.30
	if not _was_airborne and air:
		_air_time = 0.0
	_was_airborne = air
	_air_time += delta if air else 0.0
	_motion_time += delta
	_landing = maxf(0.0, _landing - delta)
	_push_blend = _blend(_push_blend, 1.0 if pushing else 0.0, delta, 10.0)
	_brake_blend = _blend(_brake_blend, 1.0 if braking else 0.0, delta, 12.0)
	_air_blend = _blend(_air_blend, 1.0 if air else 0.0, delta, 14.0)
	_grab_blend = _blend(_grab_blend, 1.0 if grab else 0.0, delta, 22.0)
	# The flick separates the soles from a rotating deck, then brings both feet
	# back to their planted contact targets before the animation finishes.
	var flick := smoothstep(0.0, 0.16, flip_progress) * (1.0 - smoothstep(0.72, 0.98, flip_progress))
	var separation := flick if flip else (1.0 if board_spin else 0.0)
	_flip_blend = _blend(_flip_blend, separation, delta, 36.0)
	_manual_blend = _blend(_manual_blend, 1.0 if manual else 0.0, delta, 12.0)
	_grind_blend = _blend(_grind_blend, 1.0 if grind else 0.0, delta, 12.0)
	_crouch_blend = _blend(_crouch_blend, 0.55 + 0.45 * charge if crouching else 0.0, delta, 15.0)
	_wall_blend = _blend(_wall_blend, 1.0 if wall else 0.0, delta, 14.0)
	_slide_blend = _blend(_slide_blend, 1.0 if sliding else 0.0, delta, 14.0)
	_lip_blend = _blend(_lip_blend, 1.0 if lip else 0.0, delta, 14.0)
	_transition_blend = _blend(_transition_blend, 1.0 if bool(state.get("transition_active", false)) else 0.0, delta, 10.0)
	_walk_blend = _blend(_walk_blend, 1.0 if walking else 0.0, delta, 12.0)
	_foot_lift = _blend(_foot_lift, foot_lift, delta, 13.0)
	if walking: _walk_phase = fmod(_walk_phase + delta * TAU * 1.1, TAU)
	if sliding and absf(steer) > 0.1: _slide_direction = signf(steer)
	# The rear axle stays above the supporting plane as the manual lifts the nose.
	# Apply the geometric compensation before solving shoe/hand contact targets.
	var deck_pitch := _board.rotation.x
	_board.position = _board_rest_position
	if grind:
		# Ride geometry supplies the support line at the player origin. Put the
		# visible bearing surface on it: deck belly for slides, the weighted axle
		# for one-truck grinds, both axle bottoms for a neutral 50-50.
		var support := _grind_support(grind_id, grind_yaw)
		_board.position = -(_board.basis * support)
		if grind_id == "rail_grind":
			var front := _board.basis * Vector3(0, -0.104, -0.255)
			var rear := _board.basis * Vector3(0, -0.104, 0.255)
			_board.position = Vector3(0, -minf(front.y, rear.y), 0)
		_grind_release_offset = _board.position - _board_rest_position
	else:
		# One-truck poses offset the deck along the rail. Return it underneath
		# the rider over several frames on release rather than swapping feet.
		_grind_release_offset = _grind_release_offset.lerp(Vector3.ZERO, 1.0 - exp(-14.0 * delta))
		_board.position += _grind_release_offset
		_board.position.y += maxf(0.0,
			0.255 * absf(sin(deck_pitch)) + 0.088 * (cos(deck_pitch) - 1.0))
	if pushing:
		_push_phase = fmod(_push_phase + delta * (1.25 + ride_speed * 0.025), 1.0)
	var landing_curve := sin(PI * clampf(_landing / 0.30, 0.0, 1.0))
	var compression := 0.14 * landing_curve
	var launch_tuck := sin(PI * clampf(_air_time / 0.35, 0.0, 1.0)) * _air_blend
	# Nose/tail grabs use the same planted feet with a deeper crouch and a lean
	# toward the chosen contact. The arm solver therefore keeps human reach.
	var end_grab := clampf(absf(grab_target.z) / 0.38, 0.0, 1.0)
	var hips_y := 0.955 - 0.055 * _air_blend - (0.38 + 0.035 * end_grab) * _grab_blend - compression - 0.08 * launch_tuck - 0.05 * tumble
	hips_y += (_board.position.y - _board_rest_height) * _grind_blend
	hips_y -= 0.025 * _push_blend + 0.035 * _brake_blend
	hips_y -= 0.20 * _crouch_blend + 0.10 * _wall_blend + 0.10 * _slide_blend + 0.08 * _lip_blend + 0.035 * _transition_blend
	var breathing := sin(_motion_time * 2.1) * 0.004 * (1.0 - _air_blend)
	var grab_local: Vector3 = _rider.to_local(_board.to_global(grab_target))
	var grab_lean := Vector3(grab_local.x, 0, grab_local.z).limit_length(0.11) * _grab_blend
	var wall_lean := Vector3(wall_local.x, 0, wall_local.z) * 0.09 * _wall_blend
	var walk_sway := sin(_walk_phase) * clampf(absf(manual_roll), 0.0, 0.2) * _walk_blend
	var support_lean := wall_lean + Vector3(walk_sway * 0.35 + _slide_direction * 0.025 * _slide_blend, 0, -0.025 * _crouch_blend - 0.045 * nose_pop)
	var hips_origin := Vector3(0, hips_y, 0) + grab_lean * 0.7 + support_lean
	_upper.position = Vector3(0.025 * _push_blend - 0.018 * _brake_blend, hips_y + breathing, 0) + grab_lean + support_lean
	_upper.rotation.x = -0.07 - _grab_blend * 0.23 - _push_blend * 0.13 + _brake_blend * 0.09 - compression * 0.4
	_upper.rotation.x -= 0.19 * _crouch_blend + 0.08 * _slide_blend + 0.06 * _lip_blend + 0.04 * _transition_blend
	_upper.rotation.x += wall_local.z * 0.18 * _wall_blend
	_upper.rotation.x -= 0.10 * nose_pop
	_pelvis_turn = _blend(_pelvis_turn, grind_yaw * 0.45 * _grind_blend - _slide_direction * 0.12 * _slide_blend + walk_sway * 0.25, delta, 12.0)
	_torso_turn = _blend(_torso_turn, 0.08 + steer * 0.10 + sin(TAU * _push_phase) * _push_blend * 0.08 + grind_yaw * 0.25 * _grind_blend - _slide_direction * 0.30 * _slide_blend - walk_sway * 0.45, delta, 9.0)
	_upper.rotation.y = _torso_turn
	_upper.rotation.z = -steer * 0.045 - manual_balance * _manual_blend * 0.07 * manual_sign
	_upper.rotation.z -= grab_lean.x * 0.7
	_upper.rotation.z += -wall_local.x * 0.18 * _wall_blend - _slide_direction * 0.09 * _slide_blend - walk_sway * 0.6
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
	var pelvis_basis := Basis(Vector3.UP, _pelvis_turn)
	var deck_stance := Basis(Vector3.UP, -deck_yaw)
	_garments.pose_body(Transform3D(pelvis_basis, hips_origin), _upper.transform)
	for leg: Dictionary in _legs:
		var side: float = leg["side"]
		var deck_foot := Vector3(-0.015 if side < 0.0 else 0.015, 0.079, side * 0.255)
		var shoe_yaw := -PI * 0.5 + side * 0.13
		if side > 0.0:
			# Push: planted rearward stroke, then lifted return. Brake: sole drags beside the deck.
			var stroke := minf(_push_phase / 0.60, 1.0)
			var recovery := maxf(0.0, (_push_phase - 0.60) / 0.40)
			var push_z := lerpf(-0.25, 0.40, stroke) if _push_phase < 0.60 else lerpf(0.40, -0.25, recovery)
			var push_y := -0.139 + (0.26 * sin(PI * recovery) if recovery > 0.0 else 0.008 * sin(PI * stroke))
			deck_foot.x += 0.25 * _push_blend + 0.24 * _brake_blend
			deck_foot.z = lerpf(deck_foot.z, push_z, _push_blend)
			deck_foot.z = lerpf(deck_foot.z, 0.40, _brake_blend)
			deck_foot.y += push_y * _push_blend - 0.139 * _brake_blend
			shoe_yaw = lerpf(shoe_yaw, -0.08, maxf(_push_blend, _brake_blend))
		else:
			shoe_yaw += 0.20 * _push_blend
		# A spacewalk shuffles one foot while the other stays loaded. A one-foot
		# manual lifts the rear shoe clear using the catalog's authored metres.
		var walk_step := sin(_walk_phase + (0.0 if side < 0.0 else PI))
		deck_foot.z += walk_step * 0.045 * _walk_blend
		deck_foot.y += maxf(0.0, walk_step) * 0.025 * _walk_blend
		if side > 0.0:
			deck_foot.y += _foot_lift
			deck_foot.x += _foot_lift * 0.35
			deck_foot.z -= _foot_lift * 0.25
		elif launch_id == "boneless":
			deck_foot += Vector3(-0.15, 0.14, -0.035) * launch_curve
		elif launch_id == "no_comply":
			deck_foot += Vector3(-0.19, -0.11, 0.13) * launch_curve
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
		var hip := pelvis_basis * Vector3(side * 0.105, 0.025, 0) + hips_origin
		var knee_bend: Vector3 = _rider.global_basis.inverse() * _board.get_parent().global_basis * Vector3.UP + Vector3(side * 0.25, 0, -0.65)
		var knee := _joint(hip, target, 0.43, 0.41, knee_bend)
		_garments.pose_leg(side, hip, knee, target)
		leg["foot"].position = target
		leg["foot"].basis = _rider.global_basis.inverse() * foot_basis * Basis(Vector3.UP, shoe_yaw)
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
		if side * wall_local.x < 0.0:
			var wall_hand := Vector3(side * 0.32, hips_y + 0.38, -0.10) - wall_local * 0.045
			hand = hand.lerp(wall_hand, _wall_blend)
		var revert_remaining: float = state.get("revert_remaining", 0.0)
		hand.z += side * 0.16 * sin(PI * clampf(revert_remaining / 0.18, 0.0, 1.0))
		if tumble > 0.0:
			hand = hand.lerp(Vector3(side * 0.16, hips_y + 0.12, -0.18), tumble * 0.8)
		if side == grab_side:
			var contact_target := _rider.to_local(_board.to_global(grab_target))
			# The anatomical hand's origin is its wrist, not its palm. Solve that
			# offset so the distal palm meets the rail edge instead of passing through it.
			var grab_wrist := contact_target + (shoulder - contact_target).normalized() * 0.075
			for iteration in 4:
				var grab_elbow := _joint(shoulder, grab_wrist, 0.30, 0.29, Vector3(side * 0.65, -0.10, 0.55))
				var grab_basis := _hand_basis(side, grab_elbow - grab_wrist, 1.0, grab_stance.x)
				grab_wrist = contact_target - grab_basis * Vector3(0, -0.075, -0.015)
			hand = hand.lerp(grab_wrist, _grab_blend)
		var elbow := _joint(shoulder, hand, 0.30, 0.29, Vector3(side * 0.65, -0.10, 0.55))
		_garments.pose_arm(side, shoulder, elbow, hand)
		arm["hand"].position = hand
		var palm_grip := _grab_blend if side == grab_side else 0.0
		arm["hand"].basis = _hand_basis(side, elbow - hand, palm_grip, grab_stance.x)
		_anatomy.pose_hand(arm["hand"], palm_grip)

func _grind_support(grind_id: String, grind_yaw: float) -> Vector3:
	# The underside graphic extends 3mm below its -17mm center. Axles have
	# a 16mm radius below their -88mm centers. These are visible mesh surfaces.
	if grind_id in ["boardslide", "lipslide"] or absf(sin(grind_yaw)) > 0.7:
		return Vector3(0, -0.020, 0)
	if grind_id in ["nosegrind", "crooked_grind", "overcrook_grind"]:
		return Vector3(0, -0.104, -0.255)
	if grind_id in ["five_o_grind", "smith_grind", "feeble_grind"]:
		return Vector3(0, -0.104, 0.255)
	return Vector3(0, -0.104, 0)

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
	var direction := offset / distance
	var reach := clampf(distance, absf(upper_length - lower_length) + 0.001, upper_length + lower_length - 0.001)
	var along := (upper_length * upper_length - lower_length * lower_length + reach * reach) / (2.0 * reach)
	var height := sqrt(maxf(0.0, upper_length * upper_length - along * along))
	var pole := bend.slide(direction).normalized()
	if pole.length_squared() < 0.01:
		pole = Vector3.RIGHT.slide(direction).normalized()
	return start + direction * along + pole * height

func _build_board() -> void:
	var maple := _material(Color("c99a5b"), 0.75)
	var grip := _material(Color("202529"), 0.98)
	var art := _material(Color("b65035"), 0.82)
	var silver := _material(Color("9da7ac"), 0.32, 0.65)
	var rubber := _material(Color("e5d7b7"), 0.83)
	var bearing := _material(Color("546066"), 0.48, 0.40)
	var outline := PackedVector3Array()
	for half in range(2):
		for i in range(13):
			var angle := PI * float(i) / 12.0 + half * PI
			var center_z := -0.30 if half == 0 else 0.30
			outline.append(Vector3(cos(angle) * 0.118, 0, center_z - sin(angle) * 0.118))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var next := (i + 1) % outline.size()
		var a := _deck_point(outline[i], -0.014)
		var b := _deck_point(outline[next], -0.014)
		var c := _deck_point(outline[i], 0.014)
		var d := _deck_point(outline[next], 0.014)
		_triangle(surface, a, c, b)
		_triangle(surface, b, c, d)
		_triangle(surface, Vector3(0, -0.014, 0), a, b)
	surface.generate_normals()
	_instance(_board, "CurvedMapleDeck", surface.commit(), maple)
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var next := (i + 1) % outline.size()
		_triangle(top, Vector3(0, 0.017, 0), _deck_point(outline[next] * 0.94, 0.017), _deck_point(outline[i] * 0.94, 0.017))
	top.generate_normals()
	_instance(_board, "Griptape", top.commit(), grip)
	_ellipsoid(_board, "DeckUndersideGraphic", Vector3(0, -0.017, 0), Vector3(0.17, 0.006, 0.50), art)
	for end: float in [-1.0, 1.0]:
		var z := end * 0.255
		_ellipsoid(_board, "TruckBaseplate", Vector3(0, -0.026, z), Vector3(0.095, 0.027, 0.11), silver)
		_segment(_board, "Kingpin", Vector3(0, -0.035, z - end * 0.018), Vector3(0, -0.084, z), 0.021, silver)
		_segment(_board, "Axle", Vector3(-0.14, -0.088, z), Vector3(0.14, -0.088, z), 0.016, silver)
		for side: float in [-1.0, 1.0]:
			var wheel := CylinderMesh.new()
			wheel.top_radius = 0.032
			wheel.bottom_radius = 0.032
			wheel.height = 0.032
			wheel.radial_segments = 20
			var wheel_node := _instance(_board, "Wheel", wheel, rubber)
			wheel_node.position = Vector3(side * 0.115, -0.088, z)
			wheel_node.rotation.z = PI / 2.0
			_ellipsoid(_board, "Bearing", Vector3(side * 0.133, -0.088, z), Vector3(0.006, 0.019, 0.019), bearing)
			for bolt_z: float in [-0.035, 0.035]:
				_ellipsoid(_board, "DeckBolt", Vector3(side * 0.045, 0.021, z + bolt_z), Vector3(0.012, 0.004, 0.012), silver)

func _deck_point(point: Vector3, offset_y: float) -> Vector3:
	# Rounded concave deck with lifted nose/tail and a shallow cross-section dish.
	return Vector3(point.x, offset_y + 0.65 * pow(maxf(0.0, absf(point.z) - 0.28), 1.5) + point.x * point.x * 0.14, point.z)

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
