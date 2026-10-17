extends RefCounted
## Original cupsole skate shoes, authored in metres around the ankle/contact target.
## The sole bottom stays at -0.0605: the foot targets already account for this height.

const PROFILE: Array[Vector3] = [
	Vector3(0.125, 0.025, 0.058), Vector3(0.115, 0.048, 0.073),
	Vector3(0.080, 0.053, 0.078), Vector3(0.025, 0.056, 0.073),
	Vector3(-0.025, 0.059, 0.062), Vector3(-0.075, 0.061, 0.044),
	Vector3(-0.115, 0.053, 0.035), Vector3(-0.140, 0.030, 0.025),
	Vector3(-0.146, 0.006, 0.017)]

static func build(parent: Node3D, upper_material: Material, sole_material: Material,
		seam_material: Material) -> void:
	var upper := SurfaceTool.new()
	upper.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sole := SurfaceTool.new()
	sole.begin(Mesh.PRIMITIVE_TRIANGLES)
	const STEPS := 16
	for row in range(PROFILE.size() - 1):
		for col in STEPS:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0),
				Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0)]:
				var profile := PROFILE[row + corner.x]
				var angle := PI * float(col + corner.y) / STEPS
				upper.set_uv(Vector2(float(col + corner.y) / STEPS, float(row + corner.x) / PROFILE.size()))
				upper.add_vertex(Vector3(cos(angle) * profile.y, -0.034 + pow(sin(angle), 0.72) * profile.z, profile.x))
		for side: float in [-1.0, 1.0]:
			var a := PROFILE[row]
			var b := PROFILE[row + 1]
			var top_a := Vector3(side * (a.y + 0.003), -0.031, a.x)
			var top_b := Vector3(side * (b.y + 0.003), -0.031, b.x)
			var bottom_a := Vector3(top_a.x * 0.97, -0.0605, a.x)
			var bottom_b := Vector3(top_b.x * 0.97, -0.0605, b.x)
			_quad(sole, top_a, bottom_a, top_b, bottom_b, side > 0)
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
	# The low contrast quarter-panel stitches read as seams, not white piping.
	for side: float in [-1.0, 1.0]:
		_segment(parent, Vector3(side * 0.048, -0.003, -0.067), Vector3(side * 0.049, 0.018, 0.057), 0.0013, seam_material)
		_segment(parent, Vector3(side * 0.042, 0.010, 0.079), Vector3(side * 0.034, 0.036, 0.101), 0.0013, seam_material)
	for index in 4:
		var z := -0.052 + index * 0.022
		var y := 0.020 + index * 0.006
		_segment(parent, Vector3(-0.025, y, z), Vector3(0.025, y, z + 0.008), 0.0022, sole_material)

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, reverse: bool) -> void:
	for point: Vector3 in ([a, c, b, b, c, d] if reverse else [a, b, c, b, d, c]):
		surface.add_vertex(point)

static func _finish(parent: Node3D, label: String, surface: SurfaceTool, material: Material) -> void:
	surface.generate_normals()
	surface.index()
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = surface.commit()
	node.material_override = material
	parent.add_child(node)

static func _segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = (a + b) * 0.5
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
