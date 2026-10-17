extends RefCounted
## Authored rectangular terrain patches. Mesh and convex collision share corners.
## Heights describe terrain support, excluding props, rails and building roofs.

var patches: Array[Dictionary] = []


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


func height_at(x: float, z: float) -> float:
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
		if is_nan(found) or height > found:
			found = height
	return found
