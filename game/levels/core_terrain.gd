extends RefCounted
## Authored terrain patches and angled retained polygons; shared mesh/collision vertices.
## Heights describe terrain support, excluding props, rails and building roofs.

var patches: Array[Dictionary] = []
var polygons: Array[Dictionary] = []


func add_patch(parent: Node3D, label: String, bounds: Rect2, heights: Vector4,
		material: Material, surface_audio: String = "stone", deck_thickness: float = -1.0) -> StaticBody3D:
	var corners: Array[Vector3] = [
		Vector3(bounds.position.x, heights.x, bounds.position.y),
		Vector3(bounds.end.x, heights.y, bounds.position.y),
		Vector3(bounds.end.x, heights.z, bounds.end.y),
		Vector3(bounds.position.x, heights.w, bounds.end.y),
	]
	var minimum := minf(minf(heights.x, heights.y), minf(heights.z, heights.w))
	var bottom := minimum - deck_thickness if deck_thickness > 0.0 else minf(-3.0, minimum - 0.8)
	var points := PackedVector3Array(corners)
	for corner: Vector3 in corners:
		points.append(Vector3(corner.x, bottom, corner.z))
	var body := StaticBody3D.new()
	body.name = label
	body.position = Vector3(bounds.get_center().x, minimum, bounds.get_center().y)
	for index: int in range(points.size()):
		points[index] -= body.position
	body.set_meta("terrain_surface", true)
	body.set_meta("surface_audio", surface_audio)
	parent.add_child(body)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for face: Array in [[0,1,2], [0,2,3], [4,6,5], [4,7,6], [0,4,5], [0,5,1],
		[1,5,6], [1,6,2], [2,6,7], [2,7,3], [3,7,4], [3,4,0]]:
		for index: int in face:
			surface.add_vertex(points[index])
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = material
	body.add_child(mesh)
	patches.append({"bounds": bounds, "heights": heights, "id": label})
	return body


## A simple polygon footprint with a retaining foundation, for angled streets/courts.
## Collision and support retain authored vertices; an optional top seam clip
## removes hidden coplanar paving without changing retaining prisms.
func add_polygon(parent: Node3D, label: String, corners: PackedVector3Array,
		material: Material, surface_audio: String = "stone", visible_top_max_z: float = INF) -> StaticBody3D:
	var footprint := PackedVector2Array()
	var minimum := INF
	for at: Vector3 in corners:
		footprint.append(Vector2(at.x, at.z))
		minimum = minf(minimum, at.y)
	var triangles := Geometry2D.triangulate_polygon(footprint)
	var points := corners.duplicate()
	for at: Vector3 in corners:
		points.append(Vector3(at.x, minf(-3.0, minimum - 0.8), at.z))
	var body := StaticBody3D.new()
	body.name = label
	body.set_meta("terrain_surface", true)
	body.set_meta("surface_audio", surface_audio)
	parent.add_child(body)
	# Each triangle has its own convex retaining prism. This keeps collision
	# identical to the displayed diagonal on graded, turning quad patches.
	for index in range(0, triangles.size(), 3):
		var prism := PackedVector3Array()
		for corner: int in [triangles[index], triangles[index + 1], triangles[index + 2]]:
			prism.append(points[corner])
			prism.append(points[corner + corners.size()])
		var shape := ConvexPolygonShape3D.new()
		shape.points = prism
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for index in range(0, triangles.size(), 3):
		var top := PackedVector3Array([points[triangles[index]], points[triangles[index+1]], points[triangles[index+2]]])
		if is_finite(visible_top_max_z): top = _clip_top_north(top, visible_top_max_z)
		for corner: int in range(1, top.size()-1):
			for at: Vector3 in [top[0], top[corner], top[corner+1]]: surface.add_vertex(at)
	# Mirrored/clockwise footprints need the opposite side winding. Keep top
	# triangulation and collision unchanged, and face retaining walls outward.
	var clockwise := Geometry2D.is_polygon_clockwise(footprint)
	for index in corners.size():
		var next := (index + 1) % corners.size()
		var side_faces: Array[int] = [index, index + corners.size(), next + corners.size(), index, next + corners.size(), next]
		for triangle in range(0, side_faces.size(), 3):
			for offset: int in ([0,2,1] if clockwise else [0,1,2]):
				surface.add_vertex(points[side_faces[triangle + offset]])
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = material
	body.add_child(mesh)
	polygons.append({"footprint": footprint, "points": corners, "triangles": triangles})
	return body


func height_at(x: float, z: float, maximum_height: float = INF) -> float:
	var found := NAN
	for patch: Dictionary in patches:
		var bounds: Rect2 = patch.bounds
		if x < bounds.position.x - 0.001 or x > bounds.end.x + 0.001 \
			or z < bounds.position.y - 0.001 or z > bounds.end.y + 0.001:
			continue
		var heights: Vector4 = patch.heights
		var tx := clampf((x - bounds.position.x) / bounds.size.x, 0.0, 1.0)
		var tz := clampf((z - bounds.position.y) / bounds.size.y, 0.0, 1.0)
		var height := lerpf(lerpf(heights.x, heights.y, tx), lerpf(heights.w, heights.z, tx), tz)
		if height <= maximum_height and (is_nan(found) or height > found):
			found = height
	for polygon: Dictionary in polygons:
		if not Geometry2D.is_point_in_polygon(Vector2(x, z), polygon.footprint): continue
		var triangles: PackedInt32Array = polygon.triangles
		var corners: PackedVector3Array = polygon.points
		for index in range(0, triangles.size(), 3):
			var a := corners[triangles[index]]
			var b := corners[triangles[index + 1]]
			var c := corners[triangles[index + 2]]
			if not Geometry2D.point_is_inside_triangle(Vector2(x, z), Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)): continue
			var normal := (b - a).cross(c - a)
			var height := a.y - (normal.x * (x - a.x) + normal.z * (z - a.z)) / normal.y
			if height <= maximum_height and (is_nan(found) or height > found): found = height
	return found


## One horizontal half-plane, with edge interpolation and original winding.
## Used only at the flat Merchant Close / Central Station paving seam.
static func _clip_top_north(points: PackedVector3Array, maximum_z: float) -> PackedVector3Array:
	var result := PackedVector3Array()
	for index: int in points.size():
		var start := points[index]
		var end := points[(index+1)%points.size()]
		var start_inside := start.z <= maximum_z
		var end_inside := end.z <= maximum_z
		if start_inside: result.append(start)
		if start_inside != end_inside:
			result.append(start.lerp(end,(maximum_z-start.z)/(end.z-start.z)))
	return result
