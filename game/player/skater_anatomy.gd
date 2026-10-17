extends RefCounted
## Anatomical MakeHuman CC0 derivatives; see the asset manifest and retained licence.
## Only visible geometry/materials live here. The skating rig owns every pose target.

const HEAD: Mesh = preload("res://game/art/assets/makehuman_hm08/head.obj")
const HAIR: Mesh = preload("res://game/art/assets/makehuman_hm08/hair.obj")
const LEFT_HAND: Mesh = preload("res://game/art/assets/makehuman_hm08/left_hand.obj")
const RIGHT_HAND: Mesh = preload("res://game/art/assets/makehuman_hm08/right_hand.obj")
# Baked from manifest head_markers_m; no runtime JSON/file-service dependency.
const EYE_CENTERS: Array[Vector3] = [Vector3(0.0294083333, 0.04127, -0.0787933333),
	Vector3(-0.0294083333, 0.04127, -0.0787933333)]
var _skin: StandardMaterial3D
var _sphere: SphereMesh

func _init() -> void:
	_skin = _material(Color("bd9c88"), 0.76)
	_skin.vertex_color_use_as_albedo = true
	_skin.metallic_specular = 0.24
	_sphere = SphereMesh.new()
	_sphere.radius = 1.0
	_sphere.height = 2.0
	_sphere.radial_segments = 24
	_sphere.rings = 16

func build_head(parent: Node3D) -> void:
	_instance(parent, "AnatomicalHead", _pigmented(HEAD), _skin)
	var hair_material := _material(Color("302b26"), 0.97)
	hair_material.metallic_specular = 0.12
	_instance(parent, "CroppedHair", HAIR, hair_material)
	var sclera := _material(Color("b5b1a0"), 0.43)
	var iris := _material(Color("414535"), 0.55)
	var pupil := _material(Color("101311"), 0.40)
	for center: Vector3 in EYE_CENTERS:
		_ellipsoid(parent, "Eye", center, Vector3.ONE * 0.0138, sclera)
		_ellipsoid(parent, "Iris", center + Vector3(0, 0, -0.0131), Vector3(0.0056, 0.0056, 0.0010), iris)
		_ellipsoid(parent, "Pupil", center + Vector3(0, 0, -0.0139), Vector3(0.0021, 0.0021, 0.00055), pupil)

func build_hand(parent: Node3D, side: float) -> Node3D:
	var node := Node3D.new()
	node.name = "LeftAnatomicalHand" if side < 0 else "RightAnatomicalHand"
	parent.add_child(node)
	# MakeHuman subject-left is +X; the rig's negative side is subject-right.
	var mesh := RIGHT_HAND if side < 0 else LEFT_HAND
	_instance(node, "HandAndFingers", _hand_mesh(mesh), _skin)
	return node

func pose_hand(node: Node3D, grabbing: float) -> void:
	var mesh: MeshInstance3D = node.get_node("HandAndFingers")
	mesh.set_blend_shape_value(0, lerpf(0.22, 1.0, grabbing))

func _hand_mesh(source: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	result.add_blend_shape("GripCurl")
	result.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var curled := PackedVector3Array()
		var curled_normals := PackedVector3Array()
		for index in points.size():
			var point := points[index]
			# A continuous distal bend preserves the palm contact and leaves the
			# shorter thumb untouched. It is an authored visual curl, not hand physics.
			var distance := maxf(0.0, -point.y - 0.090)
			var angle := distance * 11.0
			curled.append(Vector3(point.x, point.y + distance - sin(angle) / 11.0,
				point.z - (1.0 - cos(angle)) / 11.0))
			curled_normals.append(Basis(Vector3.RIGHT, angle) * normals[index])
		var shape: Array = []
		shape.resize(Mesh.ARRAY_MAX)
		shape[Mesh.ARRAY_VERTEX] = curled
		shape[Mesh.ARRAY_NORMAL] = curled_normals
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [shape])
	return result

func _pigmented(source: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var colors := PackedColorArray()
		for point: Vector3 in points:
			var grain := 0.985 + 0.012 * sin(point.x * 987.0 + point.y * 463.0) * sin(point.z * 791.0)
			var color := Color(grain, grain, grain)
			# Restrained pigmentation follows the anatomical surface; no attached cartoon lips.
			if point.z < -0.065:
				var mouth := exp(-pow(point.x / 0.029, 4.0) - pow((point.y + 0.047) / 0.008, 2.0))
				color = color.lerp(Color(0.79, 0.57, 0.53), mouth * 0.62)
				var cheeks := exp(-pow((absf(point.x) - 0.049) / 0.020, 2.0) - pow((point.y + 0.006) / 0.025, 2.0))
				color = color.lerp(Color(1.0, 0.89, 0.85), cheeks * 0.36)
				var brow_curve := 0.058 + 0.005 * sin(clampf((absf(point.x) - 0.015) / 0.043, 0.0, 1.0) * PI)
				var brow := exp(-pow((absf(point.x) - 0.036) / 0.024, 6.0) - pow((point.y - brow_curve) / 0.004, 2.0))
				color = color.lerp(Color(0.31, 0.28, 0.25), brow * 0.85)
			colors.append(color)
		arrays[Mesh.ARRAY_COLOR] = colors
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _ellipsoid(parent: Node3D, label: String, point: Vector3, radii: Vector3, material: Material) -> void:
	var node := _instance(parent, label, _sphere, material)
	node.position = point
	node.scale = radii

func _instance(parent: Node3D, label: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	return node
