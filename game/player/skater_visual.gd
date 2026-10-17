extends RefCounted
## Original procedural rider and board. Geometry and animation only: no physics.
## A small articulated rig keeps feet on the deck and reaches the grab target.

var _board: Node3D
var _rider: Node3D
var _upper: Node3D
var _pelvis: MeshInstance3D
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

func build(board: Node3D, rider: Node3D, shirt: StandardMaterial3D) -> void:
	_board = board
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
	var knit := _material(Color("bf5836"), 0.97)
	var eyes := _material(Color("d8cbb5"), 0.68)
	_build_board()
	_upper = Node3D.new()
	_upper.name = "TorsoRig"
	_rider.add_child(_upper)
	_pelvis = _ellipsoid(_rider, "TrouserHips", Vector3(0, 0.91, 0), Vector3(0.35, 0.26, 0.25), denim)
	_loft(_upper, "ShapedJacket", [Vector4(0.03, 0.155, 0.115, 0),
		Vector4(0.14, 0.16, 0.12, 0), Vector4(0.32, 0.205, 0.135, -0.01),
		Vector4(0.43, 0.22, 0.12, 0), Vector4(0.49, 0.12, 0.095, 0)], shirt)
	_loft(_upper, "JacketHem", [Vector4(0.025, 0.158, 0.119, 0), Vector4(0.065, 0.16, 0.12, 0)], seams)
	_loft(_upper, "Collar", [Vector4(0.455, 0.09, 0.08, -0.01), Vector4(0.51, 0.075, 0.065, -0.01)], seams)
	_segment(_upper, "JacketZip", Vector3(0, 0.08, -0.121), Vector3(0, 0.45, -0.115), 0.006, rubber)
	for side: float in [-1.0, 1.0]:
		_segment(_upper, "PocketSeam", Vector3(side * 0.065, 0.15, -0.115), Vector3(side * 0.13, 0.21, -0.112), 0.004, seams)
	_segment(_upper, "Neck", Vector3(0, 0.47, 0), Vector3(0, 0.59, 0), 0.062, skin)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.69, -0.015)
	head.rotation.y = 0.55
	_upper.add_child(head)
	_ellipsoid(head, "Face", Vector3.ZERO, Vector3(0.225, 0.295, 0.235), skin)
	_ellipsoid(head, "Jaw", Vector3(0, -0.075, -0.012), Vector3(0.185, 0.13, 0.19), skin)
	_ellipsoid(head, "Nose", Vector3(0, 0.005, -0.124), Vector3(0.043, 0.07, 0.065), skin)
	_ellipsoid(head, "LowerLip", Vector3(0, -0.059, -0.119), Vector3(0.066, 0.013, 0.012), _material(Color("805347")))
	_ellipsoid(head, "BackHair", Vector3(0, 0.045, 0.015), Vector3(0.228, 0.21, 0.242), dark)
	_ellipsoid(head, "KnittedBeanie", Vector3(0, 0.098, 0.004), Vector3(0.247, 0.18, 0.25), knit)
	_loft(head, "BeanieFold", [Vector4(0.052, 0.124, 0.126, 0), Vector4(0.095, 0.123, 0.125, 0)], knit)
	for side: float in [-1.0, 1.0]:
		_ellipsoid(head, "Ear", Vector3(side * 0.112, -0.008, 0.008), Vector3(0.041, 0.069, 0.044), skin)
		_ellipsoid(head, "Eye", Vector3(side * 0.042, 0.025, -0.108), Vector3(0.043, 0.023, 0.026), eyes)
		_ellipsoid(head, "Pupil", Vector3(side * 0.042, 0.025, -0.121), Vector3(0.012, 0.015, 0.009), dark)
		_segment(head, "Brow", Vector3(side * 0.023, 0.047, -0.111), Vector3(side * 0.065, 0.044, -0.104), 0.006, dark)
		var upper_leg := _segment(_rider, "Thigh", Vector3.ZERO, Vector3.UP, 0.105, denim)
		var lower_leg := _segment(_rider, "Calf", Vector3.ZERO, Vector3.UP, 0.078, denim)
		var knee := _ellipsoid(_rider, "Knee", Vector3.ZERO, Vector3(0.17, 0.18, 0.17), denim)
		var foot := Node3D.new()
		foot.name = "FrontFoot" if side < 0.0 else "PushFoot"
		_rider.add_child(foot)
		_ellipsoid(foot, "Sole", Vector3(0, -0.043, 0), Vector3(0.14, 0.035, 0.285), rubber)
		_ellipsoid(foot, "Shoe", Vector3(0, -0.006, -0.012), Vector3(0.135, 0.10, 0.265), shoes)
		_ellipsoid(foot, "HeelPatch", Vector3(0, 0.004, 0.10), Vector3(0.11, 0.065, 0.04), seams)
		for lace_z: float in [-0.06, -0.03, 0.0]:
			_segment(foot, "Lace", Vector3(-0.044, 0.036, lace_z), Vector3(0.044, 0.036, lace_z + 0.008), 0.004, rubber)
		_legs.append({"side": side, "upper": upper_leg, "lower": lower_leg, "knee": knee, "foot": foot})
		var upper_arm := _segment(_rider, "Sleeve", Vector3.ZERO, Vector3.UP, 0.081, shirt)
		var forearm := _segment(_rider, "Forearm", Vector3.ZERO, Vector3.UP, 0.052, skin)
		var elbow := _ellipsoid(_rider, "Elbow", Vector3.ZERO, Vector3(0.12, 0.13, 0.12), shirt)
		var hand := _ellipsoid(_rider, "Hand", Vector3.ZERO, Vector3(0.072, 0.11, 0.045), skin)
		_arms.append({"side": side, "upper": upper_arm, "lower": forearm, "elbow": elbow, "hand": hand})
	reset()

func reset() -> void:
	_push_phase = 0.0
	_push_blend = 0.0
	_air_blend = 0.0
	_grab_blend = 0.0
	_landing = 0.0
	_was_airborne = false

func animate(delta: float, state: Dictionary) -> void:
	var air: bool = state["airborne"]
	var grab: bool = state["grab"]
	var flip: bool = state["flip"]
	var ride_speed: float = state["speed"]
	var pushing: bool = state["push"] and not air and not state["manual"] and not state["grind"] and ride_speed < 14.5
	if _was_airborne and not air:
		_landing = 0.25
	_was_airborne = air
	_landing = maxf(0.0, _landing - delta)
	_push_blend = lerpf(_push_blend, 1.0 if pushing else 0.0, 1.0 - exp(-12.0 * delta))
	_air_blend = lerpf(_air_blend, 1.0 if air else 0.0, 1.0 - exp(-12.0 * delta))
	_grab_blend = lerpf(_grab_blend, 1.0 if grab else 0.0, 1.0 - exp(-20.0 * delta))
	if pushing:
		_push_phase = fmod(_push_phase + delta * (8.0 + ride_speed * 0.25), TAU)
	var compression := 0.11 * sin(PI * clampf(_landing / 0.25, 0.0, 1.0))
	var hips_y := 0.94 - 0.065 * _air_blend - 0.33 * _grab_blend - compression
	_upper.position.y = hips_y
	_upper.rotation.x = -0.08 - _grab_blend * 0.22 - _push_blend * 0.09
	_pelvis.position.y = hips_y
	for leg: Dictionary in _legs:
		var side: float = leg["side"]
		var deck_foot := Vector3(-0.015 if side < 0.0 else 0.015, 0.085, side * 0.255)
		if side > 0.0:
			deck_foot.x += 0.27 * _push_blend
			deck_foot.z += 0.43 * sin(_push_phase) * _push_blend
			deck_foot.y += (-0.145 + 0.18 * maxf(0.0, -sin(_push_phase))) * _push_blend
		var target: Vector3
		var foot_basis: Basis
		if flip:
			# Flip the board below lifted shoes; never attach shoes to its upside-down grip.
			target = _rider.to_local(_board.get_parent().to_global(Vector3(deck_foot.x, 0.35, deck_foot.z)))
			foot_basis = _board.get_parent().global_basis
		else:
			target = _rider.to_local(_board.to_global(deck_foot))
			foot_basis = _board.global_basis
		var hip := Vector3(side * 0.105, hips_y + 0.025, 0)
		var knee_bend := _rider.global_basis.inverse() * _board.global_basis * Vector3.UP + Vector3(side * 0.25, 0, -0.5)
		var knee := _joint(hip, target, 0.43, 0.41, knee_bend)
		_pose_segment(leg["upper"], hip, knee, 0.10)
		_pose_segment(leg["lower"], knee, target, 0.075)
		leg["knee"].position = knee
		leg["foot"].position = target
		leg["foot"].basis = _rider.global_basis.inverse() * foot_basis * Basis(Vector3.UP, -PI * 0.5 + side * 0.13)
	for arm: Dictionary in _arms:
		var side: float = arm["side"]
		var shoulder: Vector3 = _rider.to_local(_upper.to_global(Vector3(side * 0.225, 0.435, 0)))
		var hand := Vector3(side * (0.32 + _air_blend * 0.10), hips_y - 0.05, -0.08 + side * 0.11)
		hand.z += side * 0.13 * sin(_push_phase) * _push_blend
		if side < 0.0:
			var grab_target := _rider.to_local(_board.to_global(Vector3(-0.158, 0.022, -0.035)))
			hand = hand.lerp(grab_target, _grab_blend)
		var elbow := _joint(shoulder, hand, 0.30, 0.29, Vector3(side, 0, 0.45))
		_pose_segment(arm["upper"], shoulder, elbow, 0.078)
		_pose_segment(arm["lower"], elbow, hand, 0.05)
		arm["elbow"].position = elbow
		arm["hand"].position = hand
		arm["hand"].quaternion = Quaternion(Vector3.UP, (elbow - hand).normalized())

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
			var center_z := -0.33 if half == 0 else 0.33
			outline.append(Vector3(cos(angle) * 0.145, 0, center_z - sin(angle) * 0.145))
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
	_ellipsoid(_board, "DeckUndersideGraphic", Vector3(0, -0.017, 0), Vector3(0.20, 0.006, 0.50), art)
	for end: float in [-1.0, 1.0]:
		var z := end * 0.285
		_ellipsoid(_board, "TruckBaseplate", Vector3(0, -0.026, z), Vector3(0.095, 0.027, 0.11), silver)
		_segment(_board, "Kingpin", Vector3(0, -0.035, z - end * 0.018), Vector3(0, -0.061, z), 0.021, silver)
		_segment(_board, "Axle", Vector3(-0.18, -0.058, z), Vector3(0.18, -0.058, z), 0.016, silver)
		for side: float in [-1.0, 1.0]:
			var wheel := CylinderMesh.new()
			wheel.top_radius = 0.061
			wheel.bottom_radius = 0.061
			wheel.height = 0.041
			wheel.radial_segments = 20
			var wheel_node := _instance(_board, "Wheel", wheel, rubber)
			wheel_node.position = Vector3(side * 0.157, -0.058, z)
			wheel_node.rotation.z = PI / 2.0
			_ellipsoid(_board, "Bearing", Vector3(side * 0.181, -0.058, z), Vector3(0.008, 0.032, 0.032), bearing)
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
