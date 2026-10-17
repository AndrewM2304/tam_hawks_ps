extends RefCounted
## A shared closed arch band with continuous edges, scaled by each facade bay.

static var _mesh: ArrayMesh


static func shared_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 24
	for segment: int in range(SEGMENTS):
		var a := PI * float(segment) / float(SEGMENTS)
		var b := PI * float(segment + 1) / float(SEGMENTS)
		var outer_a := Vector3(cos(a) * 1.12, sin(a) * 1.12, 0)
		var outer_b := Vector3(cos(b) * 1.12, sin(b) * 1.12, 0)
		var inner_a := Vector3(cos(a) * 0.88, sin(a) * 0.88, 0)
		var inner_b := Vector3(cos(b) * 0.88, sin(b) * 0.88, 0)
		var front := Vector3(0, 0, 0.5)
		var back := -front
		_quad(surface, outer_a + front, outer_b + front, inner_b + front, inner_a + front, Vector3.BACK)
		_quad(surface, outer_a + back, inner_a + back, inner_b + back, outer_b + back, Vector3.FORWARD)
		var outward := Vector3(cos((a + b) / 2.0), sin((a + b) / 2.0), 0)
		_quad(surface, outer_a + back, outer_b + back, outer_b + front, outer_a + front, outward)
		_quad(surface, inner_a + back, inner_a + front, inner_b + front, inner_b + back, -outward)
		if segment == 0:
			_quad(surface, inner_a + back, outer_a + back, outer_a + front, inner_a + front, Vector3.DOWN)
		if segment == SEGMENTS - 1:
			_quad(surface, inner_b + back, inner_b + front, outer_b + front, outer_b + back, Vector3.DOWN)
	_mesh = surface.commit()
	return _mesh


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	# Godot's visible face uses clockwise winding when viewed from its normal.
	var vertices: Array[Vector3] = [a, b, c, a, c, d]
	if (b - a).cross(c - a).dot(normal) > 0.0:
		vertices = [a, c, b, a, d, c]
	for vertex: Vector3 in vertices:
		surface.set_normal(normal)
		surface.add_vertex(vertex)
