extends RefCounted
## Original cupsole skate shoes, authored in metres around the ankle/contact target.
## The sole bottom stays at -0.0605: the foot targets already account for this height.
const SOLE_CONTACT := Vector3(0, -0.0605, 0)
## Exact upper vertex on the low, tapered toe (-Z); the tall heel is +Z.
const TOE_CONTACT := Vector3(0, 0.001, -0.115)

const PROFILE: Array[Vector3] = [
	Vector3(0.130, 0.008, 0.039), Vector3(0.125, 0.025, 0.058), Vector3(0.115, 0.048, 0.073),
	Vector3(0.080, 0.050, 0.078), Vector3(0.025, 0.051, 0.073),
	Vector3(-0.025, 0.052, 0.062), Vector3(-0.075, 0.053, 0.044),
	Vector3(-0.115, 0.047, 0.035), Vector3(-0.140, 0.028, 0.025),
	Vector3(-0.146, 0.006, 0.017)]

static func build(parent: Node3D, upper_material: Material, sole_material: Material,
		_seam_material: Material) -> void:
	var upper := SurfaceTool.new()
	upper.begin(Mesh.PRIMITIVE_TRIANGLES)
	upper.set_smooth_group(0)
	var sole := SurfaceTool.new()
	sole.begin(Mesh.PRIMITIVE_TRIANGLES)
	sole.set_smooth_group(0)
	if upper_material is StandardMaterial3D:
		upper_material.vertex_color_use_as_albedo = true
	const STEPS := 32
	const SUBDIVISIONS := 3
	for row in range((PROFILE.size() - 1) * SUBDIVISIONS):
		for col in STEPS:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0),
				Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0)]:
				var sample := float(row + corner.x) / SUBDIVISIONS
				var profile := _profile_sample(sample)
				var angle := PI * float(col + corner.y) / STEPS
				upper.set_uv(Vector2(float(col + corner.y) / STEPS, sample / PROFILE.size()))
				var tongue := exp(-pow(cos(angle) / 0.36, 2.0)) * exp(-pow((profile.x + 0.042) / 0.068, 2.0))
				var heel_panel := smoothstep(0.070, 0.115, profile.x)
				var shade := 0.90 + tongue * 0.07 - heel_panel * 0.09
				upper.set_color(Color(shade, shade, shade))
				upper.add_vertex(Vector3(cos(angle) * profile.y, -0.034 + pow(sin(angle), 0.72) * profile.z, profile.x))
		for side: float in [-1.0, 1.0]:
			var a := _profile_sample(float(row) / SUBDIVISIONS)
			var b := _profile_sample(float(row + 1) / SUBDIVISIONS)
			# A small moulded bevel catches light along the cupsole. The bottom
			# remains the exact physical contact plane used by the skating rig.
			const BEVEL: Array[Vector2] = [Vector2(-0.031, 0.002), Vector2(-0.035, 0.004),
				Vector2(-0.0565, 0.004), Vector2(-0.0605, 0.001)]
			for band in BEVEL.size() - 1:
				var upper_edge: Vector2 = BEVEL[band]
				var lower_edge: Vector2 = BEVEL[band + 1]
				_quad(sole, Vector3(side * (a.y + upper_edge.y), upper_edge.x, a.x),
					Vector3(side * (a.y + lower_edge.y), lower_edge.x, a.x),
					Vector3(side * (b.y + upper_edge.y), upper_edge.x, b.x),
					Vector3(side * (b.y + lower_edge.y), lower_edge.x, b.x), side > 0)
			var bottom_a := Vector3(side * (a.y + 0.001), -0.0605, a.x)
			var bottom_b := Vector3(side * (b.y + 0.001), -0.0605, b.x)
			_quad(sole, bottom_a, Vector3(0, -0.0605, a.x), bottom_b,
				Vector3(0, -0.0605, b.x), side > 0)
	# Round off the heel/toe instead of leaving open extruded sections.
	for end: int in [0, PROFILE.size() - 1]:
		var p := PROFILE[end]
		for col in STEPS:
			var a := PI * float(col) / STEPS
			var b := PI * float(col + 1) / STEPS
			var first := Vector3(cos(a) * p.y, -0.034 + pow(sin(a), 0.72) * p.z, p.x)
			var second := Vector3(cos(b) * p.y, -0.034 + pow(sin(b), 0.72) * p.z, p.x)
			for point: Vector3 in [Vector3(0, -0.034, p.x), first if end != 0 else second, second if end != 0 else first]:
				upper.add_vertex(point)
		_quad(sole, Vector3(-p.y - 0.003, -0.031, p.x), Vector3(p.y + 0.003, -0.031, p.x),
			Vector3(-p.y - 0.003, -0.0605, p.x), Vector3(p.y + 0.003, -0.0605, p.x), end != 0)
	_finish(parent, "CanvasUpper", upper, upper_material)
	_finish(parent, "Cupsole", sole, sole_material)
	# Project laces and stitches onto the actual upper. Fixed height rods were
	# buried by its curved vamp, leaving a blank clog-like forefoot.
	var stitches := SurfaceTool.new()
	stitches.begin(Mesh.PRIMITIVE_TRIANGLES)
	stitches.set_smooth_group(0)
	var laces := SurfaceTool.new()
	laces.begin(Mesh.PRIMITIVE_TRIANGLES)
	laces.set_smooth_group(0)
	for side: float in [-1.0, 1.0]:
		var previous := _upper_point(-0.100, side * 0.78)
		for index in 10:
			var point := _upper_point(-0.100 + float(index + 1) * 0.0205, side * (0.78 - 0.08 * sin(index * 0.32)))
			_cord(stitches, previous, point, 0.0007)
			previous = point
	for index in 4:
		var z := -0.098 + index * 0.021
		for side: float in [-1.0, 1.0]:
			var start := _upper_point(z, side * 0.42, 0.003)
			var middle := _upper_point(z + 0.006, 0.0, 0.0038)
			var end := _upper_point(z + 0.012, -side * 0.42, 0.003)
			_cord(laces, start, middle, 0.0016)
			_cord(laces, middle, end, 0.0016)
	var stitch_material := StandardMaterial3D.new()
	stitch_material.albedo_color = Color("9b8d78")
	stitch_material.roughness = 0.92
	var lace_material := StandardMaterial3D.new()
	lace_material.albedo_color = Color("c8c1af")
	lace_material.roughness = 0.95
	_finish(parent, "QuarterStitches", stitches, stitch_material)
	_finish(parent, "CrossedLaces", laces, lace_material)

static func _profile_sample(sample: float) -> Vector3:
	var index := mini(int(sample), PROFILE.size() - 2)
	var t := sample - index
	var a := PROFILE[maxi(0, index - 1)]
	var b := PROFILE[index]
	var c := PROFILE[index + 1]
	var d := PROFILE[mini(PROFILE.size() - 1, index + 2)]
	var value := 0.5 * ((b * 2.0) + (-a + c) * t
		+ (a * 2.0 - b * 5.0 + c * 4.0 - d) * t * t
		+ (-a + b * 3.0 - c * 3.0 + d) * t * t * t)
	value.x = lerpf(b.x, c.x, t)
	return value

static func _upper_point(z: float, across: float, clearance: float = 0.0012) -> Vector3:
	var profile := PROFILE[0]
	for index in PROFILE.size() - 1:
		if z <= PROFILE[index].x and z >= PROFILE[index + 1].x:
			var t := inverse_lerp(PROFILE[index].x, PROFILE[index + 1].x, z)
			profile = _profile_sample(index + t)
			break
	# The renderer's three subdivisions are linear triangles between these
	# sections; a small clearance keeps thread above them without floating.
	return Vector3(profile.y * across, -0.034 + pow(sqrt(maxf(0.0, 1.0 - across * across)), 0.72) * profile.z + clearance, z)

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, reverse: bool) -> void:
	for point: Vector3 in ([a, c, b, b, c, d] if reverse else [a, b, c, b, d, c]):
		surface.add_vertex(point)

static func _finish(parent: Node3D, label: String, surface: SurfaceTool, material: Material) -> void:
	surface.generate_normals()
	if label == "CanvasUpper":
		surface.generate_tangents()
	surface.index()
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = surface.commit()
	node.material_override = material
	parent.add_child(node)

static func _cord(surface: SurfaceTool, a: Vector3, b: Vector3, radius: float) -> void:
	var along := (b - a).normalized()
	var across := along.cross(Vector3.UP).normalized()
	var normal := across.cross(along).normalized()
	for side in 8:
		for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0)]:
			var angle := TAU * float(side + corner.y) / 8.0
			var center := a if corner.x == 0 else b
			surface.add_vertex(center + radius * (across * cos(angle) + normal * sin(angle)))
