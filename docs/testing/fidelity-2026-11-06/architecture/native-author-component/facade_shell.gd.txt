extends RefCounted
## Original finite wall shell with real recessed upper openings. Startup only.
## The complete native body/shape remains owned by the world.

const RECESS_DEPTH := 0.22
static var _meshes: Dictionary = {}


static func make(size: Vector3, local_front: Array[Rect2], local_sides: Array[Rect2], local_back: Array[Rect2] = []) -> ArrayMesh:
	var key: Array = [size, local_front, local_sides, local_back]
	if _meshes.has(key):
		return _meshes[key]
	var half := size * 0.5
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Front-plane coordinates are X/Y; each side uses Z/Y. Exact closed mass
	# faces survive except the intended apertures. No cap/ground seam is moved.
	_plane(surface, Rect2(-half.x, -half.y, size.x, size.y), local_front,
		Vector3(0, 0, half.z), Vector3.RIGHT, Vector3.UP, Vector3.BACK)
	for sign_value: float in [-1.0, 1.0]:
		_plane(surface, Rect2(-half.z, -half.y, size.z, size.y), local_sides,
			Vector3(sign_value * half.x, 0, 0), Vector3.BACK, Vector3.UP, Vector3(sign_value, 0, 0))
	_plane(surface, Rect2(-half.x, -half.y, size.x, size.y), local_back,
		Vector3(0, 0, -half.z), Vector3.RIGHT, Vector3.UP, Vector3.FORWARD)
	_quad(surface, Vector3(-half.x,half.y,-half.z), Vector3(half.x,half.y,-half.z),
		Vector3(half.x,half.y,half.z), Vector3(-half.x,half.y,half.z), Vector3.UP)
	_quad(surface, Vector3(-half.x,-half.y,-half.z), Vector3(-half.x,-half.y,half.z),
		Vector3(half.x,-half.y,half.z), Vector3(half.x,-half.y,-half.z), Vector3.DOWN)
	surface.index()
	surface.generate_tangents()
	var result := surface.commit()
	_meshes[key] = result
	return result


static func _plane(surface: SurfaceTool, bounds: Rect2, holes: Array[Rect2],
		origin: Vector3, across: Vector3, up: Vector3, normal: Vector3) -> void:
	var pieces: Array[Rect2] = [bounds]
	for aperture: Rect2 in holes:
		var next: Array[Rect2] = []
		for piece: Rect2 in pieces:
			var overlap := piece.intersection(aperture)
			if not overlap.has_area():
				next.append(piece)
				continue
			# Disjoint rectangular pieces; no overdraw plate behind the glazing.
			_append_rect(next, Rect2(piece.position.x, piece.position.y,
				overlap.position.x - piece.position.x, piece.size.y))
			_append_rect(next, Rect2(overlap.end.x, piece.position.y,
				piece.end.x - overlap.end.x, piece.size.y))
			_append_rect(next, Rect2(overlap.position.x, piece.position.y,
				overlap.size.x, overlap.position.y - piece.position.y))
			_append_rect(next, Rect2(overlap.position.x, overlap.end.y,
				overlap.size.x, piece.end.y - overlap.end.y))
		pieces = next
	for piece: Rect2 in pieces:
		_quad(surface, origin + across * piece.position.x + up * piece.position.y,
			origin + across * piece.end.x + up * piece.position.y,
			origin + across * piece.end.x + up * piece.end.y,
			origin + across * piece.position.x + up * piece.end.y, normal)


static func _append_rect(rectangles: Array[Rect2], rectangle: Rect2) -> void:
	if rectangle.size.x > 0.000001 and rectangle.size.y > 0.000001:
		rectangles.append(rectangle)


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, normal: Vector3) -> void:
	for triangle: Array in [[a,b,c],[a,c,d]]:
		if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).dot(normal) > 0.0:
			triangle.reverse()
		for at: Vector3 in triangle:
			surface.set_normal(normal)
			var uv := Vector2(at.x, at.y)
			if absf(normal.x) > 0.5:
				uv = Vector2(at.z, at.y)
			elif absf(normal.y) > 0.5:
				uv = Vector2(at.x, at.z)
			surface.set_uv(uv)
			surface.add_vertex(at)
