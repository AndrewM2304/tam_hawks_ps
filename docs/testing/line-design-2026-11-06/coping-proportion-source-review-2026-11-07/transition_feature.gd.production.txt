extends Node3D
## Original finite quarter-pipe. Visible and colliding face share sampled vertices.
## Local toe is zero; approach along -Z. Yaw/translation supported, scale must be 1.

const GrindLineSource = preload("res://game/tricks/grind_line.gd")
static var _shared_concrete: StandardMaterial3D
var radius := 2.4
var width := 10.0
var minimum_width := 6.0
var deck_length := 3.0
var feature_id := "transition"
var build_access := true
var wrap_lateral := false
var _built := false
var surface_body: StaticBody3D

func _ready() -> void:
	build()

func build() -> void:
	if _built:
		return
	_built = true
	radius = clampf(radius, 1.5, 5.0)
	width = clampf(width, clampf(minimum_width,4.5,6.0), 24.0)
	deck_length = clampf(deck_length, 0.0, 6.0)
	add_to_group("skate_transitions")
	set_meta("skate_feature", "quarter_pipe")
	var concrete := _concrete_material()
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("c6cbc8")
	steel.metallic = 0.7
	steel.roughness = 0.38
	var faces := PackedVector3Array()
	const SEGMENTS := 90
	for i in SEGMENTS:
		var a: Vector3 = local_sample(float(i) / SEGMENTS * PI * 0.5, -width * 0.5).point
		var b: Vector3 = local_sample(float(i) / SEGMENTS * PI * 0.5, width * 0.5).point
		var c: Vector3 = local_sample(float(i + 1) / SEGMENTS * PI * 0.5, -width * 0.5).point
		var d: Vector3 = local_sample(float(i + 1) / SEGMENTS * PI * 0.5, width * 0.5).point
		faces.append_array(PackedVector3Array([a, c, b, b, c, d]))
	surface_body = StaticBody3D.new()
	surface_body.name = "QuarterPipeFace"
	surface_body.collision_layer = 1
	surface_body.set_meta("transition_feature", self)
	surface_body.set_meta("surface_audio", "stone")
	surface_body.set_meta("wallrideable", false)
	add_child(surface_body)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	surface_body.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in faces:
		var theta := atan2(-point.z, radius - point.y)
		surface.set_normal(Vector3(0, cos(theta), sin(theta)))
		surface.set_uv(Vector2(point.x / 2.0, radius * theta / 2.0))
		surface.add_vertex(point)
	var mesh := MeshInstance3D.new()
	mesh.name = "ContinuousConcreteFace"
	mesh.mesh = surface.commit()
	mesh.material_override = concrete
	surface_body.add_child(mesh)
	if deck_length > 0.0:
		_box("RearDeck", Vector3(width, 0.24, deck_length),
			Vector3(0, radius - 0.12, -radius - deck_length * 0.5), concrete)
		_box("RearRetainingWall", Vector3(width, radius, 0.20),
			Vector3(0, radius * 0.5, -radius - deck_length), concrete)
	# A supported, low-angle side roll-in joins the deck to the approach.
	if build_access and deck_length >= 2.0:
		var bypass_start := Vector3(width * 0.5 + 2.0, 0, 4.0)
		var bypass_end := Vector3(width * 0.5 + 2.0, radius, -radius - deck_length + 2.0)
		var bypass_length := (bypass_end - bypass_start).length()
		var bypass_angle := atan2(radius, 2.0 + radius + deck_length)
		var bypass := _box("SideRollIn", Vector3(4.0, 0.24, bypass_length),
			(bypass_start + bypass_end) * 0.5 - Vector3(0, cos(bypass_angle), sin(bypass_angle)) * 0.12, concrete)
		bypass.rotation.x = bypass_angle
		_box("SideRollInLanding", Vector3(4.0, 0.24, 2.0),
			Vector3(width * 0.5 + 2.0, radius - 0.12, -radius - deck_length + 1.0), concrete)
	# Close the sides below the curved face. The matching polygon remains below
	# skate contact and makes the feature read as poured concrete, not a sheet.
	for side: float in [-1.0, 1.0]:
		var side_faces := PackedVector3Array()
		var anchor := Vector3(side * width * 0.5, 0, -radius - deck_length)
		for i in SEGMENTS:
			var a: Vector3 = local_sample(float(i) / SEGMENTS * PI * 0.5, side * width * 0.5).point
			var b: Vector3 = local_sample(float(i + 1) / SEGMENTS * PI * 0.5, side * width * 0.5).point
			side_faces.append_array(PackedVector3Array([anchor, a, b] if side < 0 else [anchor, b, a]))
		var lip_point: Vector3 = local_sample(PI * 0.5, side * width * 0.5).point
		var rear_top := anchor + Vector3.UP * radius
		side_faces.append_array(PackedVector3Array([anchor, lip_point, rear_top] if side < 0 else [anchor, rear_top, lip_point]))
		_panel("ConcreteSide", side_faces, concrete)
	var coping := MeshInstance3D.new()
	coping.name = "ContinuousSteelCoping"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.045
	cylinder.bottom_radius = 0.045
	cylinder.height = width
	cylinder.radial_segments = 12
	coping.mesh = cylinder
	coping.material_override = steel
	coping.position = Vector3(0, radius + 0.025, -radius)
	coping.rotation.z = PI * 0.5
	add_child(coping)
	var coping_body := StaticBody3D.new()
	coping_body.name = "NativeSteelCoping"
	coping_body.set_meta("authored_grind_ids",["Grind_"+feature_id+"_Coping"])
	coping_body.set_meta("audit_capture_ids",["Grind_"+feature_id+"_Coping"])
	coping_body.collision_layer = 1 | 2
	coping_body.transform = coping.transform
	coping_body.set_meta("coping_feature",self)
	coping_body.set_meta("surface_audio","metal")
	add_child(coping_body)
	var coping_shape := CylinderShape3D.new()
	coping_shape.radius = 0.045
	coping_shape.height = width
	var coping_collision := CollisionShape3D.new()
	coping_collision.shape = coping_shape
	coping_body.add_child(coping_collision)
	# Distinct trim makes the finite sides and approach legible at skating speed.
	for side: float in [-1.0, 1.0]:
		for i in 18:
			var a: Vector3 = local_sample(float(i) / 18.0 * PI * 0.5, side * width * 0.5).point
			var b: Vector3 = local_sample(float(i + 1) / 18.0 * PI * 0.5, side * width * 0.5).point
			var edge := MeshInstance3D.new()
			edge.name = "EdgeTrim"
			var box := BoxMesh.new()
			box.size = Vector3(0.06, 0.035, (b - a).length())
			edge.mesh = box
			edge.material_override = steel
			edge.position = (a + b) * 0.5 + Vector3.UP * 0.018
			edge.rotation.x = float(i + 0.5) / 18.0 * PI * 0.5
			add_child(edge)


static func _concrete_material() -> StandardMaterial3D:
	if _shared_concrete != null: return _shared_concrete
	# Original restrained concrete grain, shared by both features. World-space
	# projection keeps the same two-metre texture scale on arc, deck and sides.
	var noise := FastNoiseLite.new()
	noise.seed = 27917
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.32
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("5b6261"), Color("7d8481")])
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.noise = noise
	texture.color_ramp = gradient
	_shared_concrete = StandardMaterial3D.new()
	_shared_concrete.albedo_texture = texture
	_shared_concrete.roughness = 0.94
	_shared_concrete.metallic_specular = 0.15
	_shared_concrete.uv1_triplanar = true
	_shared_concrete.uv1_world_triplanar = true
	_shared_concrete.uv1_triplanar_sharpness = 4.0
	_shared_concrete.uv1_scale = Vector3.ONE * 0.5
	_shared_concrete.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return _shared_concrete

func local_sample(theta: float, lateral: float) -> Dictionary:
	return {"point": Vector3(lateral, radius * (1.0 - cos(theta)), -radius * sin(theta)),
		"normal": Vector3(0, cos(theta), sin(theta)),
		"tangent": Vector3(0, sin(theta), -cos(theta)), "lateral": Vector3.RIGHT,
		"theta": theta, "x": lateral}

func sample(theta: float, lateral: float) -> Dictionary:
	var value := local_sample(theta, lateral)
	value.point = to_global(value.point)
	value.normal = (global_basis * value.normal).normalized()
	value.tangent = (global_basis * value.tangent).normalized()
	value.lateral = (global_basis * Vector3.RIGHT).normalized()
	return value

func surface_sample(world_point: Vector3) -> Dictionary:
	if not world_point.is_finite() or global_basis.get_scale().distance_to(Vector3.ONE) > 0.001:
		return {}
	var local := to_local(world_point)
	var theta := atan2(-local.z, radius - local.y)
	var value := sample(clampf(theta, 0.0, PI * 0.5), clampf(local.x, -width * 0.5, width * 0.5))
	value.in_bounds = absf(local.x) <= width * 0.5 + 0.03 \
		and local.z <= 0.10 and theta >= -0.03 and theta <= PI * 0.5 + 0.04
	value.distance = world_point.distance_to(value.point)
	return value

func advance_lateral(_theta: float, lateral: float, metres: float) -> float:
	return lateral + metres

func lip_frame(lateral: float) -> Dictionary:
	var frame := sample(PI * 0.5, lateral)
	frame.face_normal = frame.normal
	frame.point += Vector3.UP * 0.070
	frame.normal = Vector3.UP
	frame.coping_tangent = frame.lateral
	return frame

func air_return_frame(world_point: Vector3, lateral: float) -> Dictionary:
	var frame := lip_frame(lateral)
	frame.normal = frame.face_normal
	var local := to_local(world_point)
	frame.over_lip = local.y >= radius - 0.12 and absf(local.z + radius) < 0.55 \
		and absf(local.x) < width * 0.5 - 0.10
	frame.lip_height = frame.point.y
	return frame

func get_feature_definitions() -> Array:
	return [{"id":feature_id, "kind":"quarter_pipe", "floor_y":global_position.y,
		"approach":PackedVector3Array([to_global(Vector3(0,0,10)),to_global(Vector3.ZERO)]),
		"lip":lip_frame(0.0).point}]

func get_grind_lines() -> Array:
	var points := PackedVector3Array([
		to_global(Vector3(-width * 0.5, radius + 0.070, -radius)),
		to_global(Vector3(width * 0.5, radius + 0.070, -radius))])
	return [_native_coping_line("Grind_" + feature_id + "_Coping", points)]


func _native_coping_line(id: String, points: PackedVector3Array, kind: String=""):
	var line := GrindLineSource.new(id,points,kind)
	# These guides already follow the native steel crown, not its tube axis.
	# World-up scalar contact is certified only under the supported unit yaw.
	if contact_frame_supported(global_transform):
		line.configure_contact(0.0,0.0,"feature.native_coping_crown")
	return line

static func contact_frame_supported(frame: Transform3D) -> bool:
	var b := frame.basis
	return frame.origin.is_finite() and b.x.is_finite() and b.y.is_finite() and b.z.is_finite() \
		and b.y.distance_to(Vector3.UP)<0.00001 \
		and absf(b.x.length_squared()-1.0)<0.00001 and absf(b.z.length_squared()-1.0)<0.00001 \
		and absf(b.x.dot(b.z))<0.00001 and absf(b.determinant()-1.0)<0.00001

func _panel(label: String, faces: PackedVector3Array, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.set_meta("surface_audio", "stone")
	add_child(body)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in faces:
		surface.add_vertex(point)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = material
	body.add_child(mesh)

func _box(label: String, size: Vector3, at: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	body.set_meta("surface_audio", "stone")
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	body.add_child(mesh)
	return body
