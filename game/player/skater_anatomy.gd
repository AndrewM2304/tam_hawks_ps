extends RefCounted
## Anatomical MakeHuman CC0 derivatives; see the asset manifest and retained licence.
## Only visible geometry/materials live here. The skating rig owns every pose target.

const HEAD: Mesh = preload("res://game/art/assets/makehuman_hm08/head.obj")
const HAIR: Mesh = preload("res://game/art/rider/short_crop.obj")
const LEFT_HAND: Mesh = preload("res://game/art/assets/makehuman_hm08/left_hand.obj")
const RIGHT_HAND: Mesh = preload("res://game/art/assets/makehuman_hm08/right_hand.obj")
## Physical marker on the retained palm mesh, unchanged by distal finger curl.
const PALM_CONTACT := Vector3(0, -0.075, -0.015)
# Baked from manifest head_markers_m; no runtime JSON/file-service dependency.
const EYE_CENTERS: Array[Vector3] = [Vector3(0.0294083333, 0.04127, -0.0787933333),
	Vector3(-0.0294083333, 0.04127, -0.0787933333)]
static var _head_cache: ArrayMesh
static var _hair_cache: ArrayMesh
static var _hand_cache: Dictionary = {}
static var _brow_cache: ArrayMesh
static var _iris_cache: ShaderMaterial
var _skin: StandardMaterial3D
var _sphere: SphereMesh
var _head_skin: StandardMaterial3D

func _init() -> void:
	_skin = _material(Color.WHITE, 0.68)
	_skin.metallic_specular = 0.30
	_skin.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_head_skin = _skin.duplicate()
	_apply_skin_maps(_head_skin, "head")
	_sphere = SphereMesh.new()
	_sphere.radius = 1.0
	_sphere.height = 2.0
	_sphere.radial_segments = 24
	_sphere.rings = 16

func build_head(parent: Node3D) -> void:
	_instance(parent, "AnatomicalHead", _head_surface(), _head_skin)
	var hair_material := _material(Color("352b25"), 0.86)
	hair_material.metallic_specular = 0.15
	hair_material.albedo_texture = preload("res://game/art/rider/hair_albedo.png")
	hair_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_instance(parent, "CroppedHair", _styled_hair(), hair_material)
	var brow_material := _material(Color("554235"), 0.82)
	brow_material.metallic_specular = 0.18
	brow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_instance(parent, "RootedEyebrows", _brow_surface(), brow_material)
	var sclera := _material(Color("c9c7b9"), 0.24)
	sclera.metallic_specular = 0.55
	var iris := _iris_material()
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
	var hand_material: StandardMaterial3D = _skin.duplicate()
	_apply_skin_maps(hand_material, "right_hand" if side < 0 else "left_hand")
	_instance(node, "HandAndFingers", _hand_mesh(mesh), hand_material)
	return node

func _apply_skin_maps(material: StandardMaterial3D, part: String) -> void:
	material.albedo_texture = load("res://game/art/rider/" + part + "_albedo.png")
	material.roughness_texture = load("res://game/art/rider/" + part + "_roughness.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled = true
	material.normal_texture = load("res://game/art/rider/" + part + "_normal.png")
	material.normal_scale = 0.35
	material.roughness = 1.0

func _styled_hair() -> ArrayMesh:
	if _hair_cache != null:
		return _hair_cache
	_hair_cache = ArrayMesh.new()
	for surface in HAIR.get_surface_count():
		# The fibers are one startup-shared native surface. Keep its authored
		# silhouette matched to the full-detail face rather than an unrelated LOD.
		_hair_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, HAIR.surface_get_arrays(surface))
	return _hair_cache

func pose_hand(node: Node3D, grabbing: float) -> void:
	var mesh: MeshInstance3D = node.get_node("HandAndFingers")
	mesh.set_blend_shape_value(0, lerpf(0.22, 1.0, grabbing))

func _hand_mesh(source: Mesh) -> ArrayMesh:
	var key := source.get_instance_id()
	if _hand_cache.has(key):
		return _hand_cache[key]
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
	# Blend values belong to each MeshInstance3D; the immutable geometry and
	# authored curl deltas can be shared by every activity actor and the player.
	_hand_cache[key] = result
	return result

func _head_surface() -> ArrayMesh:
	if _head_cache != null:
		return _head_cache
	_head_cache = ArrayMesh.new()
	# Keep full-detail head and scalp matched at chase distance. Imported generated
	# LODs must not independently collapse one surface through the other.
	for surface in HEAD.get_surface_count():
		_head_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, HEAD.surface_get_arrays(surface))
	return _head_cache

func _brow_surface() -> ArrayMesh:
	if _brow_cache != null:
		return _brow_cache
	# Original short fibres follow the retained face, rather than floating
	# cylinders or a painted rectangular strip above each eye. Only this small
	# forehead region is searched, once, when creating the shared native mesh.
	var triangles := PackedVector3Array()
	var faces := HEAD.get_faces()
	for index in range(0, faces.size(), 3):
		var a := faces[index]
		var b := faces[index + 1]
		var c := faces[index + 2]
		if minf(a.y, minf(b.y, c.y)) > 0.074 or maxf(a.y, maxf(b.y, c.y)) < 0.047:
			continue
		if minf(a.z, minf(b.z, c.z)) > -0.075:
			continue
		triangles.append_array(PackedVector3Array([a, b, c]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		for index in 84:
			var t := float(index) / 83.0
			var jitter := sin(float(index) * 37.71 + side) * 0.0012
			var x := side * lerpf(0.012, 0.052, t)
			var y := 0.059 + 0.0045 * sin(PI * t) - 0.004 * t + jitter
			var length := 0.0027 * (1.0 - 0.55 * t)
			var root := Vector2(x, y)
			var tip := root + Vector2(side * length * (0.25 + 0.65 * t), length * (1.0 - 0.65 * t))
			var width := 0.00020 * (1.0 - 0.55 * t)
			var a := _face_point(root + Vector2(-width, 0), triangles)
			var b := _face_point(root + Vector2(width, 0), triangles)
			var c := _face_point(tip, triangles)
			for point: Vector3 in [a, b, c]:
				surface.set_normal(Vector3.FORWARD)
				surface.add_vertex(point)
	_brow_cache = surface.commit()
	return _brow_cache

func _face_point(point: Vector2, triangles: PackedVector3Array) -> Vector3:
	var front := INF
	for index in range(0, triangles.size(), 3):
		var a := triangles[index]
		var b := triangles[index + 1]
		var c := triangles[index + 2]
		var ab := Vector2(b.x - a.x, b.y - a.y)
		var ac := Vector2(c.x - a.x, c.y - a.y)
		var offset := point - Vector2(a.x, a.y)
		var determinant := ab.cross(ac)
		if absf(determinant) < 0.0000000001:
			continue
		var u := offset.cross(ac) / determinant
		var v := ab.cross(offset) / determinant
		if u >= -0.00001 and v >= -0.00001 and u + v <= 1.00001:
			front = minf(front, a.z + (b.z - a.z) * u + (c.z - a.z) * v)
	assert(is_finite(front), "Every original eyebrow fibre must have an actual retained face surface.")
	return Vector3(point.x, point.y, front - 0.00022)

func _iris_material() -> ShaderMaterial:
	if _iris_cache != null:
		return _iris_cache
	# Original radial pigmentation at actual iris scale. This is evaluated on
	# the existing six native eye surfaces; it adds no texture or draw surface.
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec2 iris_xy;
void vertex() { iris_xy = VERTEX.xy; }
void fragment() {
    float radius = clamp(length(iris_xy), 0.0, 1.0);
    float angle = atan(iris_xy.y, iris_xy.x);
    float fibres = 0.5 + 0.24 * sin(angle * 83.0 + sin(angle * 19.0) * 1.8 + radius * 13.0)
        + 0.15 * sin(angle * 157.0 - radius * 31.0);
    float collarette = exp(-pow((radius - 0.48) / 0.12, 2.0));
    vec3 pigment = mix(vec3(0.025, 0.039, 0.022), vec3(0.115, 0.145, 0.073), clamp(fibres, 0.0, 1.0));
    pigment += vec3(0.025, 0.012, 0.002) * collarette;
    ALBEDO = pigment * (1.0 - 0.65 * smoothstep(0.80, 1.0, radius));
    ROUGHNESS = 0.34;
    SPECULAR = 0.50;
}
"""
	_iris_cache = ShaderMaterial.new()
	_iris_cache.shader = shader
	return _iris_cache

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
