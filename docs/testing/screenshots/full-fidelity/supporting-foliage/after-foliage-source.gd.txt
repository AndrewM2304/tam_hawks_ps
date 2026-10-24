extends RefCounted
## Original opaque deciduous crown. One cached mesh/material serves all trees.
## Unit envelope is centred near zero; scale/rotate instances, not the mesh.
## 792 folded leaves, 99 irregular leaf sprays and 44 tapered branch segments:
## 4,796 triangles, including opaque interior cover instead of empty twig tips.

static var _canopy: ArrayMesh
static var _material: StandardMaterial3D


static func canopy_mesh() -> ArrayMesh:
	if _canopy != null:
		return _canopy
	var random := RandomNumberGenerator.new()
	random.seed = 704391
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for limb: int in range(11):
		var angle := float(limb) * 2.399963 + random.randf_range(-0.19, 0.19)
		var height := -0.35 + 1.15 * (float(limb) + 0.5) / 11.0
		var radius := sqrt(maxf(0.12, 1.0 - height * height)) * random.randf_range(0.56, 0.78)
		var fork := Vector3(cos(angle) * radius, height, sin(angle) * radius)
		var root := Vector3(sin(angle) * 0.045, -0.84 + limb * 0.035, cos(angle) * 0.035)
		_branch(surface, root, fork, 0.023, 0.009)
		for twig: int in range(3):
			var spread := angle + (float(twig) - 1.0) * 0.95
			var tip := fork + Vector3(cos(spread) * 0.18, random.randf_range(0.07, 0.26), sin(spread) * 0.18)
			_branch(surface, fork, tip, 0.009, 0.0025)
			var cluster_scale := random.randf_range(0.21, 0.29)
			# Overlapping, folded leaf sprays make a coherent crown from ordinary
			# chase distances. Their lobed outlines stay irregular in silhouette;
			# these are original opaque polygons, not spheres or alpha billboards.
			for spray: int in range(3):
				var facing := spread + float(spray) * 2.399963 + random.randf_range(-0.4, 0.4)
				var normal := Vector3(cos(facing) * random.randf_range(0.4, 0.85),
					random.randf_range(0.45, 1.0), sin(facing) * random.randf_range(0.4, 0.85)).normalized()
				var center := tip.lerp(fork, 0.18 + float(spray) * 0.22)
				# Fill inward from the outer twigs as well as around their tips.
				# The overlapping middle layers hide the empty branch cage while
				# retaining separate, uneven outer lobes and individual leaf edges.
				var inward := 1.0 - float(spray) * 0.30
				center.x *= inward
				center.z *= inward
				center += Vector3(cos(facing), random.randf_range(-0.1, 0.4), sin(facing)) * 0.055
				var colour := Color(0.115, 0.205, 0.080).lerp(Color(0.240, 0.335, 0.135), random.randf())
				_leaf_spray(surface, center, normal, facing, cluster_scale * random.randf_range(0.88, 1.12), colour, random)
			for leaf: int in range(24):
				# Golden-angle spacing fills each lobe without a visible sphere shell.
				var azimuth := float(leaf) * 2.399963 + random.randf_range(-0.4, 0.4)
				var elevation := random.randf_range(-0.85, 0.85)
				var reach := sqrt(maxf(0.0, 1.0 - elevation * elevation))
				var direction := Vector3(cos(azimuth) * reach, elevation * 0.7, sin(azimuth) * reach)
				var position := tip + direction * cluster_scale * random.randf_range(0.35, 1.15)
				var normal := Vector3(direction.x * 0.5, random.randf_range(0.25, 1.0), direction.z * 0.5).normalized()
				var length := random.randf_range(0.052, 0.079)
				var shade := random.randf_range(0.0, 1.0)
				var colour := Color(0.105, 0.175, 0.075).lerp(Color(0.235, 0.315, 0.135), shade)
				colour *= random.randf_range(0.86, 1.08)
				colour.a = 1.0
				_leaf(surface, position, normal, azimuth, length, colour)
	surface.index()
	_canopy = surface.commit()
	_canopy.surface_set_material(0, canopy_material())
	return _canopy


static func canopy_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_material.roughness = 0.94
		_material.metallic_specular = 0.12
	return _material


static func _leaf_spray(surface: SurfaceTool, at: Vector3, normal: Vector3, angle: float,
		radius: float, colour: Color, random: RandomNumberGenerator) -> void:
	var reference := Vector3.RIGHT if absf(normal.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var right := normal.cross(reference).normalized().rotated(normal, angle)
	var forward := right.cross(normal).normalized()
	var edge := PackedVector3Array()
	for index in 12:
		var azimuth := TAU * float(index) / 12.0
		var reach := radius * (1.0 if index % 2 == 0 else 0.69) * random.randf_range(0.89, 1.10)
		var fold := normal * radius * 0.08 * sin(azimuth * 3.0 + angle)
		edge.append(at + (right * cos(azimuth) + forward * sin(azimuth)) * reach + fold)
	var ridge := at + normal * radius * 0.14
	for index in 12:
		var shade := colour.lightened(0.018) if index % 3 == 0 else colour.darkened(0.012 * float(index % 3))
		_triangle(surface, ridge, edge[index], edge[(index + 1) % 12], normal, shade)


static func _leaf(surface: SurfaceTool, at: Vector3, normal: Vector3, angle: float, length: float, colour: Color) -> void:
	var reference := Vector3.RIGHT if absf(normal.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var right := normal.cross(reference).normalized().rotated(normal, angle)
	var forward := right.cross(normal).normalized()
	var tip := at + forward * length
	var base := at - forward * length * 0.78
	var left := at - right * length * 0.48 - forward * length * 0.05
	var edge := at + right * length * 0.48 - forward * length * 0.05
	var ridge := at + normal * length * 0.13
	_triangle(surface, tip, left, ridge, normal, colour.lightened(0.025))
	_triangle(surface, left, base, ridge, normal, colour)
	_triangle(surface, base, edge, ridge, normal, colour.darkened(0.05))
	_triangle(surface, edge, tip, ridge, normal, colour)


static func _branch(surface: SurfaceTool, start: Vector3, end: Vector3, lower: float, upper: float) -> void:
	var up := (end - start).normalized()
	var reference := Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var right := up.cross(reference).normalized()
	var forward := right.cross(up).normalized()
	for side: int in range(5):
		var a := TAU * float(side) / 5.0
		var b := TAU * float(side + 1) / 5.0
		var radial_a := right * cos(a) + forward * sin(a)
		var radial_b := right * cos(b) + forward * sin(b)
		var normal := (radial_a + radial_b).normalized()
		var colour := Color(0.16, 0.135, 0.09).lightened(float(side % 2) * 0.025)
		_triangle(surface, start + radial_a * lower, end + radial_a * upper, end + radial_b * upper, normal, colour)
		_triangle(surface, start + radial_a * lower, end + radial_b * upper, start + radial_b * lower, normal, colour)


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, desired: Vector3, colour: Color) -> void:
	var normal := (b - a).cross(c - a).normalized()
	var vertices: Array[Vector3] = [a, c, b]
	if normal.dot(desired) < 0.0:
		normal = -normal
		vertices = [a, b, c]
	for vertex: Vector3 in vertices:
		surface.set_color(colour)
		surface.set_normal(normal)
		surface.add_vertex(vertex)
