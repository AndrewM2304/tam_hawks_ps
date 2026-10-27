extends RefCounted
## Authored terrain patches and angled retained polygons; shared mesh/collision vertices.
## Heights describe terrain support, excluding props, rails and building roofs.

var patches: Array[Dictionary] = []
var polygons: Array[Dictionary] = []


func add_patch(parent: Node3D, label: String, bounds: Rect2, heights: Vector4,
		material: Material, surface_audio: String = "stone", deck_thickness: float = -1.0,
		visible_top_exclusions: Array[Rect2] = []) -> StaticBody3D:
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
	body.set_meta("art_label", label)
	body.position = Vector3(bounds.get_center().x, minimum, bounds.get_center().y)
	for index: int in range(points.size()):
		points[index] -= body.position
	body.set_meta("terrain_surface", true)
	var local_top := PackedVector3Array()
	for corner: Vector3 in corners: local_top.append(corner - body.position)
	body.set_meta("top_polygon_local", local_top)
	body.set_meta("retaining_bottom_local", bottom - body.position.y)
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
	var faces: Array = [[0,1,2], [0,2,3], [4,6,5], [4,7,6], [0,4,5], [0,5,1],
		[1,5,6], [1,6,2], [2,6,7], [2,7,3], [3,7,4], [3,4,0]]
	for face_index: int in faces.size():
		var face: Array = faces[face_index]
		if face_index<2 and not visible_top_exclusions.is_empty():
			_emit_patch_top(surface,body,PackedVector3Array([points[face[0]],points[face[1]],points[face[2]]]),visible_top_exclusions)
			continue
		for index: int in face:
			surface.add_vertex(points[index])
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = material
	body.add_child(mesh)
	patches.append({"bounds": bounds, "heights": heights, "id": label})
	return body


## Cut shared top-face seams only. Exclusions use world XZ and must reach a
## triangle edge; these material-ownership cuts do not excavate enclosed holes.
## Collision, retaining faces, support data and the original planes stay intact.
func _emit_patch_top(surface: SurfaceTool,body: StaticBody3D,local: PackedVector3Array,
		exclusions: Array[Rect2]) -> void:
	var source := PackedVector3Array()
	var footprint := PackedVector2Array()
	for point: Vector3 in local:
		var world := body.to_global(point)
		source.append(world)
		footprint.append(Vector2(world.x,world.z))
	var pieces: Array[PackedVector2Array] = [footprint]
	for exclusion: Rect2 in exclusions:
		var rectangle := PackedVector2Array([exclusion.position,
			Vector2(exclusion.end.x,exclusion.position.y),exclusion.end,
			Vector2(exclusion.position.x,exclusion.end.y)])
		var remaining: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in pieces:
			remaining.append_array(Geometry2D.clip_polygons(piece,rectangle))
		pieces = remaining
	var ab := footprint[1]-footprint[0]
	var ac := footprint[2]-footprint[0]
	var determinant := ab.cross(ac)
	for piece: PackedVector2Array in pieces:
		var indices := Geometry2D.triangulate_polygon(piece)
		for index in range(0,indices.size(),3):
			var triangle := PackedVector3Array()
			for corner: int in [indices[index],indices[index+1],indices[index+2]]:
				var relative := piece[corner]-footprint[0]
				var u := relative.cross(ac)/determinant
				var v := ab.cross(relative)/determinant
				triangle.append(body.to_local(source[0]*(1-u-v)+source[1]*u+source[2]*v))
			if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).dot((local[1]-local[0]).cross(local[2]-local[0]))<0:
				var swap := triangle[1]
				triangle[1] = triangle[2]
				triangle[2] = swap
			for point: Vector3 in triangle:surface.add_vertex(point)


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
	body.set_meta("art_label", label)
	body.set_meta("terrain_surface", true)
	body.set_meta("top_polygon_local", corners.duplicate())
	body.set_meta("retaining_bottom_local", minf(-3.0, minimum - 0.8))
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
	var outer_edge := NAN
	for patch: Dictionary in patches:
		var bounds: Rect2 = patch.bounds
		if x < bounds.position.x or x > bounds.end.x \
			or z < bounds.position.y or z > bounds.end.y:
			continue
		var heights: Vector4 = patch.heights
		var tx := clampf((x - bounds.position.x) / bounds.size.x, 0.0, 1.0)
		var tz := clampf((z - bounds.position.y) / bounds.size.y, 0.0, 1.0)
		var height := lerpf(lerpf(heights.x, heights.y, tx), lerpf(heights.w, heights.z, tx), tz)
		if height > maximum_height: continue
		# At a stair/deck's maximum edge the next interior floor owns the point,
		# matching actual downward rays. Closed inclusion formerly selected an
		# unsupported higher riser at exact seams (and a1.5m road corner).
		var owns_point := bounds.has_point(Vector2(x,z))
		if not owns_point:
			# A bank's lateral side remains real native top support. Admit only
			# that exact edge on a one-axis grade; longitudinal ends and corners
			# retain the stair/deck ownership policy above, with no widened bounds.
			owns_point = (x==bounds.end.x and z>bounds.position.y and z<bounds.end.y
				and heights.x==heights.y and heights.w==heights.z and heights.x!=heights.w) \
				or (z==bounds.end.y and x>bounds.position.x and x<bounds.end.x
				and heights.x==heights.w and heights.y==heights.z and heights.x!=heights.y)
		if owns_point:
			if is_nan(found) or height > found: found = height
		elif is_nan(outer_edge) or height > outer_edge:
			# Keep isolated exposed corners available to existing retained-edge
			# builders. This fallback cannot override an adjacent interior floor.
			outer_edge = height
	for polygon: Dictionary in polygons:
		var triangles: PackedInt32Array = polygon.triangles
		var corners: PackedVector3Array = polygon.points
		for index in range(0, triangles.size(), 3):
			var a := corners[triangles[index]]
			var b := corners[triangles[index + 1]]
			var c := corners[triangles[index + 2]]
			# Native retaining prisms include their shared diagonals and outer
			# edges. Strict polygon/triangle predicates excluded those exact
			# contacts and incorrectly selected the lower service-court floor.
			var ab := Vector2(b.x-a.x,b.z-a.z)
			var ac := Vector2(c.x-a.x,c.z-a.z)
			var relative := Vector2(x-a.x,z-a.z)
			var determinant := ab.cross(ac)
			if absf(determinant)<0.000000001:continue
			var u := relative.cross(ac)/determinant
			var v := ab.cross(relative)/determinant
			if u< -0.000001 or v< -0.000001 or u+v>1.000001:continue
			var normal := (b - a).cross(c - a)
			var height := a.y - (normal.x * (x - a.x) + normal.z * (z - a.z)) / normal.y
			if height <= maximum_height and (is_nan(found) or height > found): found = height
	return outer_edge if is_nan(found) else found


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
