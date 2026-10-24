extends RefCounted
## Original shared mesh/collision construction for continuous outdoor surfaces.

## The same two triangles used by terrain(), rather than the unsampled height
## function between mesh vertices. Queries/fence feet must agree with collision.
static func grid_height(bounds: Rect2, spacing: float, height_at: Callable, x: float, z: float) -> float:
	var nx := ceili(bounds.size.x/spacing)
	var nz := ceili(bounds.size.y/spacing)
	var dx := bounds.size.x/nx
	var dz := bounds.size.y/nz
	var gx := clampf((x-bounds.position.x)/dx,0,nx)
	var gz := clampf((z-bounds.position.y)/dz,0,nz)
	var ix := mini(floori(gx),nx-1)
	var iz := mini(floori(gz),nz-1)
	var u := gx-ix
	var v := gz-iz
	var left := bounds.position.x+ix*dx
	var north := bounds.position.y+iz*dz
	var a := float(height_at.call(left,north))
	var b := float(height_at.call(left+dx,north))
	var c := float(height_at.call(left,north+dz))
	var d := float(height_at.call(left+dx,north+dz))
	return a+u*(b-a)+v*(c-a) if u+v<=1.0 else d+(1-u)*(c-d)+(1-v)*(b-d)


static func terrain(parent: Node3D, id: String, bounds: Rect2, spacing: float, height_at: Callable, material: Material,
		cutouts: Array[Rect2] = []) -> StaticBody3D:
	var nx := ceili(bounds.size.x / spacing)
	var nz := ceili(bounds.size.y / spacing)
	var dx := bounds.size.x / nx
	var dz := bounds.size.y / nz
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for z in range(nz + 1):
		for x in range(nx + 1):
			var px := bounds.position.x + x * dx
			var pz := bounds.position.y + z * dz
			vertices.append(Vector3(px, float(height_at.call(px, pz)), pz))
			uvs.append(Vector2(px, pz) * 0.2)
	for z in range(nz + 1):
		for x in range(nx + 1):
			var left := vertices[z * (nx + 1) + maxi(0, x - 1)].y
			var right := vertices[z * (nx + 1) + mini(nx, x + 1)].y
			var north := vertices[maxi(0, z - 1) * (nx + 1) + x].y
			var south := vertices[mini(nz, z + 1) * (nx + 1) + x].y
			normals.append(Vector3((left - right) / dx, 2.0, (north - south) / dz).normalized())
			if x < nx and z < nz:
				var cell_center := Vector2(bounds.position.x+(x+0.5)*dx,bounds.position.y+(z+0.5)*dz)
				var excavated := false
				for cutout: Rect2 in cutouts:
					if cutout.has_point(cell_center):
						excavated = true
						break
				if excavated: continue
				var a := z * (nx + 1) + x
				indices.append_array(PackedInt32Array([a, a + 1, a + nx + 1, a + 1, a + nx + 2, a + nx + 1]))
	var result := _body(parent, id, vertices, normals, uvs, indices, material, "stone")
	result.set_meta("terrain_cutouts",cutouts.duplicate())
	return result


static func strip(parent: Node3D, id: String, points: PackedVector3Array, width: float, material: Material, audio: String = "stone") -> StaticBody3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var distance := 0.0
	for i in points.size():
		var direction := points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]
		var side := Vector3(direction.z, 0.0, -direction.x).normalized()
		var normal := side.cross(direction).normalized()
		if normal.y < 0.0: normal = -normal
		if i > 0: distance += points[i].distance_to(points[i - 1])
		vertices.append(points[i] - side * width * 0.5)
		vertices.append(points[i] + side * width * 0.5)
		normals.append_array(PackedVector3Array([normal, normal]))
		uvs.append_array(PackedVector2Array([Vector2(0, distance * 0.2), Vector2(width * 0.2, distance * 0.2)]))
		if i < points.size() - 1:
			var a := i * 2
			indices.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
	var body := _body(parent, id, vertices, normals, uvs, indices, material, audio)
	body.set_meta("strip_vertices", vertices)
	body.set_meta("strip_indices", indices)
	return body


static func _body(parent: Node3D, id: String, vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, material: Material, audio: String) -> StaticBody3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var body := StaticBody3D.new()
	body.name = id
	body.set_meta("art_label", id)
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("surface_audio", audio)
	body.add_to_group("outdoor_surfaces")
	parent.add_child(body)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	shape.backface_collision = true
	collision.shape = shape
	body.add_child(collision)
	return body


static func smooth_points(knots: PackedVector3Array, spacing: float = 2.0) -> PackedVector3Array:
	var curve := Curve3D.new()
	curve.bake_interval = 0.4
	for i in knots.size():
		var tangent := (knots[mini(i + 1, knots.size() - 1)] - knots[maxi(i - 1, 0)]) * 0.16
		# A flat landing/port must stay flat: unconstrained cardinal Y tangents
		# overshoot below it and allow neighbouring paving to intersect the path.
		if i > 0 and i < knots.size() - 1:
			var before := knots[i].y - knots[i - 1].y
			var after := knots[i + 1].y - knots[i].y
			if before * after <= 0.0: tangent.y = 0.0
		curve.add_point(knots[i], -tangent if i > 0 else Vector3.ZERO, tangent if i < knots.size() - 1 else Vector3.ZERO)
	var samples := PackedVector3Array()
	var steps := maxi(1, ceili(curve.get_baked_length() / spacing))
	for i in range(steps + 1): samples.append(curve.sample_baked(curve.get_baked_length() * float(i) / steps, true))
	samples[0] = knots[0]
	samples[samples.size() - 1] = knots[knots.size() - 1]
	return samples


static func nearest_segment(points: PackedVector3Array, at: Vector2) -> Dictionary:
	var best := INF
	var result := {"distance": INF, "height": NAN}
	for i in range(points.size() - 1):
		var a := Vector2(points[i].x, points[i].z)
		var b := Vector2(points[i + 1].x, points[i + 1].z)
		var delta := b - a
		var raw_weight := (at - a).dot(delta) / maxf(0.0001, delta.length_squared())
		var weight := clampf(raw_weight, 0.0, 1.0)
		var distance := at.distance_squared_to(a + delta * weight)
		if distance < best:
			best = distance
			result = {"distance": sqrt(distance), "height": lerpf(points[i].y, points[i + 1].y, weight), "within": not ((i == 0 and raw_weight < 0.0) or (i == points.size() - 2 and raw_weight > 1.0))}
	return result
