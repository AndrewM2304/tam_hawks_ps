extends RefCounted
## Original procedural rider and board. Geometry and animation only: no physics.
## Original smooth clothing uses native skinning; analytic posing preserves contact.

const Garments = preload("res://game/player/skater_garments.gd")

var _board: Node3D
var _board_rest_height := 0.12
var _rider: Node3D
var _upper: Node3D
var _garments: RefCounted
var _head: Node3D
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

func build(board: Node3D, rider: Node3D, shirt: StandardMaterial3D) -> void:
	_board = board
	_board_rest_height = board.position.y
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
	var skin := _material(Color("bb8668"), 0.78)
	var denim := _material(Color("253247"), 0.96)
	var seams := _material(Color("46516a"), 0.92)
	var rubber := _material(Color("deddd1"), 0.90)
	var shoes := _material(Color("263236"), 0.88)
	var dark := _material(Color("262123"), 0.98)
	var knit := _material(Color("884b36"), 0.97)
	var eyes := _material(Color("d8cbb5"), 0.68)
	_build_board()
	_upper = Node3D.new()
	_upper.name = "TorsoRig"
	_rider.add_child(_upper)
	_garments = Garments.new()
	_garments.build(_rider, shirt, denim)
	_loft(_upper, "JacketHem", [Vector4(0.024, 0.188, 0.146, 0), Vector4(0.050, 0.187, 0.145, 0)], seams)
	_loft(_upper, "Collar", [Vector4(0.455, 0.09, 0.08, -0.01), Vector4(0.51, 0.075, 0.065, -0.01)], seams)
	_segment(_upper, "JacketZip", Vector3(0, 0.08, -0.126), Vector3(0, 0.43, -0.126), 0.006, rubber)
	for side: float in [-1.0, 1.0]:
		_segment(_upper, "PocketSeam", Vector3(side * 0.065, 0.15, -0.115), Vector3(side * 0.13, 0.21, -0.112), 0.004, seams)
	_segment(_upper, "Neck", Vector3(0, 0.47, 0), Vector3(0, 0.59, 0), 0.062, skin)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.675, -0.015)
	head.rotation.y = 1.05
	_head = head
	_upper.add_child(head)
	_loft(head, "SculptedFace", [Vector4(-0.135, 0.037, 0.060, -0.015),
		Vector4(-0.105, 0.068, 0.082, -0.008), Vector4(-0.065, 0.089, 0.099, 0),
		Vector4(-0.015, 0.106, 0.112, 0), Vector4(0.025, 0.109, 0.112, 0.002),
		Vector4(0.075, 0.106, 0.106, 0.008), Vector4(0.115, 0.089, 0.090, 0.012),
		Vector4(0.145, 0.052, 0.055, 0.015)], skin)
	_ellipsoid(head, "Nose", Vector3(0, 0.005, -0.124), Vector3(0.043, 0.07, 0.065), skin)
	_ellipsoid(head, "LowerLip", Vector3(0, -0.059, -0.119), Vector3(0.066, 0.013, 0.012), _material(Color("805347")))
	_ellipsoid(head, "BackHair", Vector3(0, 0.072, 0.025), Vector3(0.223, 0.16, 0.228), dark)
	_ellipsoid(head, "KnittedBeanie", Vector3(0, 0.111, 0.010), Vector3(0.237, 0.166, 0.242), knit)
	_loft(head, "BeanieFold", [Vector4(0.052, 0.119, 0.121, 0.008), Vector4(0.095, 0.118, 0.120, 0.008)], knit)
	for side: float in [-1.0, 1.0]:
		_ellipsoid(head, "Ear", Vector3(side * 0.112, -0.008, 0.008), Vector3(0.041, 0.069, 0.044), skin)
		_ellipsoid(head, "Eye", Vector3(side * 0.042, 0.025, -0.108), Vector3(0.034, 0.016, 0.010), eyes)
		_ellipsoid(head, "Pupil", Vector3(side * 0.042, 0.025, -0.113), Vector3(0.010, 0.011, 0.004), dark)
		_segment(head, "Brow", Vector3(side * 0.023, 0.047, -0.111), Vector3(side * 0.065, 0.044, -0.104), 0.006, dark)
		var foot := Node3D.new()
		foot.name = "FrontFoot" if side < 0.0 else "PushFoot"
		_rider.add_child(foot)
		_ellipsoid(foot, "Sole", Vector3(0, -0.043, 0), Vector3(0.14, 0.035, 0.285), rubber)
		_ellipsoid(foot, "Shoe", Vector3(0, -0.006, -0.012), Vector3(0.135, 0.10, 0.265), shoes)
		_ellipsoid(foot, "HeelPatch", Vector3(0, 0.004, 0.10), Vector3(0.11, 0.065, 0.04), seams)
		for lace_z: float in [-0.06, -0.03, 0.0]:
			_segment(foot, "Lace", Vector3(-0.044, 0.036, lace_z), Vector3(0.044, 0.036, lace_z + 0.008), 0.004, rubber)
		_legs.append({"side": side, "foot": foot})
		var hand := _loft(_rider, "Hand", [Vector4(-0.055, 0.026, 0.017, 0),
			Vector4(-0.035, 0.035, 0.022, 0), Vector4(0.015, 0.037, 0.022, 0),
			Vector4(0.050, 0.026, 0.020, 0)], skin)
		_ellipsoid(hand, "Thumb", Vector3(side * 0.036, -0.005, -0.006), Vector3(0.031, 0.065, 0.032), skin)
		_arms.append({"side": side, "hand": hand})
	reset()

func reset() -> void:
	if is_instance_valid(_board):
		_board.position.y = _board_rest_height
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
	_was_airborne = false

func animate(delta: float, state: Dictionary) -> void:
	var air: bool = state["airborne"]
	var grab: bool = state["grab"]
	var flip: bool = state["flip"]
	var manual: bool = state["manual"]
	var grind: bool = state["grind"]
	var ride_speed: float = state["speed"]
	var braking: bool = state.get("brake", false) and not air and not manual and not grind and ride_speed > 0.2
	var pushing: bool = state["push"] and not braking and not air and not manual and not grind and ride_speed < 14.5
	var steer: float = state.get("steering", 0.0)
	var manual_balance: float = state.get("manual_balance", 0.0)
	var grind_balance: float = state.get("grind_balance", 0.0)
	var special_id: String = state.get("special_id", "")
	var special_progress: float = state.get("special_progress", 0.0)
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
	_flip_blend = _blend(_flip_blend, 1.0 if flip or board_spin else 0.0, delta, 24.0)
	_manual_blend = _blend(_manual_blend, 1.0 if manual else 0.0, delta, 12.0)
	_grind_blend = _blend(_grind_blend, 1.0 if grind else 0.0, delta, 12.0)
	# The rear axle stays above the supporting plane as the manual lifts the nose.
	# Apply the geometric compensation before solving shoe/hand contact targets.
	var deck_pitch := _board.rotation.x
	_board.position.y = _board_rest_height + maxf(0.0,
		0.255 * absf(sin(deck_pitch)) + 0.088 * (cos(deck_pitch) - 1.0))
	if pushing:
		_push_phase = fmod(_push_phase + delta * (1.25 + ride_speed * 0.025), 1.0)
	var landing_curve := sin(PI * clampf(_landing / 0.30, 0.0, 1.0))
	var compression := 0.14 * landing_curve
	var launch_tuck := sin(PI * clampf(_air_time / 0.35, 0.0, 1.0)) * _air_blend
	var hips_y := 0.955 - 0.055 * _air_blend - 0.31 * _grab_blend - compression - 0.08 * launch_tuck - 0.05 * tumble
	hips_y -= 0.025 * _push_blend + 0.035 * _brake_blend
	var breathing := sin(_motion_time * 2.1) * 0.004 * (1.0 - _air_blend)
	_upper.position = Vector3(0.025 * _push_blend - 0.018 * _brake_blend, hips_y + breathing, 0)
	_upper.rotation.x = -0.07 - _grab_blend * 0.23 - _push_blend * 0.13 + _brake_blend * 0.09 - compression * 0.4
	_torso_turn = _blend(_torso_turn, 0.08 + steer * 0.10 + sin(TAU * _push_phase) * _push_blend * 0.08, delta, 9.0)
	_upper.rotation.y = _torso_turn
	_upper.rotation.z = -steer * 0.045 - manual_balance * _manual_blend * 0.07
	# Look along accepted travel after a revert, within a comfortable neck turn.
	var travel_basis: Basis = _board.get_parent().get_parent().global_basis
	var look_direction := _rider.global_basis.inverse() * -travel_basis.z
	var look_yaw := clampf(atan2(-look_direction.x, -look_direction.z) - _torso_turn, -1.10, 1.10)
	_head.rotation.y = lerp_angle(_head.rotation.y, look_yaw + steer * 0.06, 1.0 - exp(-8.0 * delta))
	_head.rotation.x = -0.04 + _grab_blend * 0.20 + compression * 0.6
	_garments.pose_body(Transform3D(Basis.IDENTITY, Vector3(0, hips_y, 0)), _upper.transform)
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
		var attached: Vector3 = _rider.to_local(_board.to_global(deck_foot))
		# Shoes follow the planted board except during a deliberately separated board spin/flip.
		var detached := _rider.to_local(_board.get_parent().to_global(Vector3(deck_foot.x, 0.40, deck_foot.z)))
		var target := attached.lerp(detached, _flip_blend)
		# Parent rotations can accumulate harmless floating-point drift; slerp needs unit bases.
		var detached_basis: Basis = _board.get_parent().global_basis.orthonormalized()
		var foot_basis := _board.global_basis.orthonormalized().slerp(detached_basis, _flip_blend)
		var hip := Vector3(side * 0.105, hips_y + 0.025, 0)
		var knee_bend: Vector3 = _rider.global_basis.inverse() * _board.get_parent().global_basis * Vector3.UP + Vector3(side * 0.25, 0, -0.65)
		var knee := _joint(hip, target, 0.43, 0.41, knee_bend)
		_garments.pose_leg(side, hip, knee, target)
		leg["foot"].position = target
		leg["foot"].basis = _rider.global_basis.inverse() * foot_basis * Basis(Vector3.UP, shoe_yaw)
	for arm: Dictionary in _arms:
		var side: float = arm["side"]
		var shoulder: Vector3 = _rider.to_local(_upper.to_global(Vector3(side * 0.215, 0.425, 0)))
		var spread := 0.33 + 0.12 * _air_blend + 0.13 * _grind_blend + 0.07 * _manual_blend
		var hand := Vector3(side * spread, hips_y + 0.015 + 0.12 * _air_blend + 0.10 * _grind_blend, -0.14 + side * 0.09)
		hand.z += side * 0.17 * sin(TAU * _push_phase) * _push_blend
		hand.y += side * (grind_balance * _grind_blend * 0.13 + manual_balance * _manual_blend * 0.08)
		var revert_remaining: float = state.get("revert_remaining", 0.0)
		hand.z += side * 0.16 * sin(PI * clampf(revert_remaining / 0.18, 0.0, 1.0))
		if tumble > 0.0:
			hand = hand.lerp(Vector3(side * 0.16, hips_y + 0.12, -0.18), tumble * 0.8)
		if side < 0.0:
			var grab_target := _rider.to_local(_board.to_global(Vector3(-0.128, 0.022, -0.035)))
			hand = hand.lerp(grab_target, _grab_blend)
		var elbow := _joint(shoulder, hand, 0.30, 0.29, Vector3(side * 0.65, -0.10, 0.55))
		_garments.pose_arm(side, shoulder, elbow, hand)
		arm["hand"].position = hand
		arm["hand"].quaternion = Quaternion(Vector3.UP, (elbow - hand).normalized())

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
