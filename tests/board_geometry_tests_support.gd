extends RefCounted
## Geometry-only test adapter for the actual visible native skateboard model.
## Material face arrays are board-local snapshots of rendered GLB surfaces;
## no reconstructed primitive or nominal stance plane is used as evidence.

static func grip_distance(rig: RefCounted, point: Vector3) -> float:
	return faces_distance(point, rig.board_contact_geometry().grip_faces, rig._board)

static func faces_distance(point: Vector3, faces: PackedVector3Array, space: Node3D) -> float:
	var distance := INF
	for index in range(0, faces.size(), 3):
		var a := space.to_global(faces[index])
		var b := space.to_global(faces[index + 1])
		var c := space.to_global(faces[index + 2])
		var normal := (b-a).cross(c-a).normalized()
		if normal.length_squared() > 0.5:
			var projected := point-normal*(point-a).dot(normal)
			if normal.dot((b-a).cross(projected-a)) >= -0.000001 \
				and normal.dot((c-b).cross(projected-b)) >= -0.000001 \
				and normal.dot((a-c).cross(projected-c)) >= -0.000001:
				distance = minf(distance,point.distance_to(projected))
		for edge: Array in [[a,b],[b,c],[c,a]]:
			distance = minf(distance,point.distance_to(Geometry3D.get_closest_point_to_segment(point,edge[0],edge[1])))
	return distance

static func visible_meshes(rig: RefCounted, include_head: bool = true) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if include_head: meshes.append(rig._head.get_node("AnatomicalHead"))
	for mesh: MeshInstance3D in rig.board_contact_geometry().meshes: meshes.append(mesh)
	return meshes
