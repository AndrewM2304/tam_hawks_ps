extends RefCounted
## Original poured-concrete transitions on the existing Clyde north quay.
## Toe-local +X spans the ramp; -Z climbs it. World collision and the analytic
## feature contract share one unit-scale transform and the same radius/angle.

const RADIUS := 3.2
const WIDTH := 10.0
const ANGLE := PI * 0.5
const SEGMENTS := 45 # 2 degrees, at most 0.112 m between samples.
const DECK_DEPTH := 2.0
const COPING_RADIUS := 0.055
const BASE_DEPTH := 0.24


static func build(parent: Node3D, materials: Dictionary) -> Array[Dictionary]:
	var root := Node3D.new()
	root.name = "TransitionPark"
	parent.add_child(root)
	# Reuse the verified existing mineral-concrete PBR set. A plain pale face
	# clipped to white in the actual quay view and hid the curved form.
	var concrete := StandardMaterial3D.new()
	if materials.get("cut_stone") is StandardMaterial3D:
		concrete = materials["cut_stone"].duplicate() as StandardMaterial3D
	concrete.albedo_color = Color("737a77")
	concrete.roughness = 0.92
	concrete.uv1_scale = Vector3.ONE
	concrete.vertex_color_use_as_albedo = true
	var sides := StandardMaterial3D.new()
	sides.albedo_color = Color("777d7a")
	sides.roughness = 0.94
	var coping: Material = materials.get("iron")
	if coping == null:
		var steel := StandardMaterial3D.new()
		steel.albedo_color = Color("727c83")
		steel.metallic = 0.7
		steel.roughness = 0.4
		coping = steel
	var features: Array[Dictionary] = []
	features.append(_quarter(root, "clyde_quarter", Vector3(17, 2, 64.5), 0.0,
		concrete, sides, coping))
	features.append(_quarter(root, "clyde_half_west", Vector3(-26, 2, 60.5), PI * 0.5,
		concrete, sides, coping))
	features.append(_quarter(root, "clyde_half_east", Vector3(-18, 2, 60.5), -PI * 0.5,
		concrete, sides, coping))
	# Open north/south ends admit riders from the existing z=67 quay through-line.
	# Six millimetres of real raised support prevents two visible coplanar floors.
	_box(root, "HalfPipeFlatBottom", Vector3(-22, 1.886, 60.5),
		Vector3(8, 0.24, WIDTH), concrete)
	return features


static func _quarter(parent: Node3D, id: String, toe: Vector3, yaw: float,
		concrete: Material, sides: Material, coping_material: Material) -> Dictionary:
	var frame := Transform3D(Basis(Vector3.UP, yaw), toe)
	var structure := Node3D.new()
	structure.name = id + "Structure"
	structure.transform = frame
	parent.add_child(structure)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()
	# Five broad formwork panels use vertex colour in a single material surface.
	# No high-frequency hash, transparency, tiny seam overlays or extra draw calls.
	for panel in 5:
		var left := -WIDTH * 0.5 + panel * 2.0
		var shade := Color(0.965, 0.965, 0.965) if panel % 2 == 0 else Color.WHITE
		var start := vertices.size()
		for step in range(SEGMENTS + 1):
			var theta := ANGLE * float(step) / SEGMENTS
			for x: float in [left, left + 2.0]:
				vertices.append(Vector3(x, RADIUS * (1.0 - cos(theta)), -RADIUS * sin(theta)))
				normals.append(Vector3(0, cos(theta), sin(theta)))
				uvs.append(Vector2(x * 0.5, RADIUS * theta * 0.5))
				colours.append(shade)
			if step < SEGMENTS:
				var at := start + step * 2
				# Clockwise front faces point into the usable concave ramp.
				indices.append_array(PackedInt32Array([at, at + 2, at + 1,
					at + 1, at + 2, at + 3]))
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var tangent_builder := SurfaceTool.new()
	tangent_builder.create_from(mesh, 0)
	tangent_builder.generate_tangents()
	mesh = tangent_builder.commit()
	var body := StaticBody3D.new()
	body.name = id
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("transition_id", id)
	body.set_meta("surface_audio", "stone")
	body.add_to_group("transition_surfaces")
	structure.add_child(body)
	var visual := MeshInstance3D.new()
	visual.name = "CurvedConcrete"
	visual.mesh = mesh
	visual.material_override = concrete
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.name = "MatchingCurveCollision"
	var shape := mesh.create_trimesh_shape()
	shape.backface_collision = false
	collision.shape = shape
	body.add_child(collision)
	# Deck has full physical depth, and its front abuts the exact vertical lip.
	_box(structure, "SupportedDeck", Vector3(0, (RADIUS - BASE_DEPTH) * 0.5,
		-RADIUS - DECK_DEPTH * 0.5), Vector3(WIDTH, RADIUS + BASE_DEPTH, DECK_DEPTH), sides)
	_capped_sides(structure, sides)
	_coping(structure, id, coping_material)
	var world_frame := structure.global_transform
	var coping_points := PackedVector3Array([
		world_frame * Vector3(-WIDTH * 0.5, RADIUS + COPING_RADIUS, -RADIUS),
		world_frame * Vector3(WIDTH * 0.5, RADIUS + COPING_RADIUS, -RADIUS),
	])
	return {"id": id, "transform": world_frame, "radius": RADIUS,
		"width": WIDTH, "angle": ANGLE, "body": body,
		"coping_points": coping_points,
		"entry": world_frame * Vector3(0, 0, 4),
		"checkpoint": world_frame * Vector3(0, 0.8, 4)}


static func _capped_sides(parent: Node3D, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var x := side * WIDTH * 0.5
		for step in SEGMENTS:
			var a := ANGLE * float(step) / SEGMENTS
			var b := ANGLE * float(step + 1) / SEGMENTS
			var front := Vector3(x, RADIUS * (1.0 - cos(a)), -RADIUS * sin(a))
			var back := Vector3(x, RADIUS * (1.0 - cos(b)), -RADIUS * sin(b))
			var down_front := Vector3(x, -BASE_DEPTH, front.z)
			var down_back := Vector3(x, -BASE_DEPTH, back.z)
			_quad(surface, front, back, down_back, down_front, Vector3(side, 0, 0))
	# Solid underside seals the curved construction; no invisible box fills the
	# skating volume above it, including close to the vertical coping.
	_quad(surface, Vector3(-WIDTH / 2, -BASE_DEPTH, 0),
		Vector3(WIDTH / 2, -BASE_DEPTH, 0), Vector3(WIDTH / 2, -BASE_DEPTH, -RADIUS),
		Vector3(-WIDTH / 2, -BASE_DEPTH, -RADIUS), Vector3.DOWN)
	_quad(surface, Vector3(-WIDTH / 2, -BASE_DEPTH, 0),
		Vector3(-WIDTH / 2, 0, 0), Vector3(WIDTH / 2, 0, 0),
		Vector3(WIDTH / 2, -BASE_DEPTH, 0), Vector3.BACK)
	var mesh := surface.commit()
	var body := StaticBody3D.new()
	body.name = "SealedRampSides"
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("surface_audio", "stone")
	parent.add_child(body)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)


static func _coping(parent: Node3D, id: String, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = "Coping"
	body.position = Vector3(0, RADIUS, -RADIUS)
	body.rotation.z = PI * 0.5
	body.collision_layer = 2 # Authored rail support, never a capsule snagging strip.
	body.collision_mask = 0
	body.set_meta("grind_id", id + "_coping")
	parent.add_child(body)
	var tube := CylinderMesh.new()
	tube.height = WIDTH
	tube.top_radius = COPING_RADIUS
	tube.bottom_radius = COPING_RADIUS
	tube.radial_segments = 16
	var visual := MeshInstance3D.new()
	visual.mesh = tube
	visual.material_override = material
	body.add_child(visual)
	var shape := CylinderShape3D.new()
	shape.height = WIDTH
	shape.radius = COPING_RADIUS
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)


static func _box(parent: Node3D, id: String, at: Vector3, size: Vector3,
		material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("surface_audio", "stone")
	parent.add_child(body)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	return body


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, normal: Vector3) -> void:
	_triangle(surface, a, b, c, normal)
	_triangle(surface, a, c, d, normal)


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		normal: Vector3) -> void:
	var vertices: Array[Vector3] = [a, b, c]
	if (b - a).cross(c - a).dot(normal) > 0.0:
		vertices = [a, c, b]
	for at: Vector3 in vertices:
		surface.set_normal(normal)
		surface.add_vertex(at)
