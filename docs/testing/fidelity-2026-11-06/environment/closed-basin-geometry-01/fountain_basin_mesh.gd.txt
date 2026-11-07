extends RefCounted
## Credible hollow visual basin: annular top, inward walls and raised inner floor.
## Outer side/bottom streams and annular coping retain their native material,
## bounds and casting. The authoritative world collider is never accessed.
const FLOOR_THICKNESS := 0.05

static func create(source: CylinderMesh, inner_radius: float) -> ArrayMesh:
	assert(source != null and source.get_surface_count() == 1)
	assert(is_equal_approx(source.top_radius,source.bottom_radius))
	assert(inner_radius > 0.0 and inner_radius < source.top_radius)
	assert(source.height > FLOOR_THICKNESS)
	var arrays: Array=source.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
	var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var original_indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	assert(tangents.size()==vertices.size()*4 and uvs.size()==vertices.size())
	var indices:=PackedInt32Array()
	var removed:=0
	for offset: int in range(0,original_indices.size(),3):
		var a:=original_indices[offset]
		var b:=original_indices[offset+1]
		var c:=original_indices[offset+2]
		if normals[a].y>0.9999 and normals[b].y>0.9999 and normals[c].y>0.9999:
			removed+=1
			continue
		indices.append_array(PackedInt32Array([a,b,c]))
	assert(removed==source.radial_segments)
	var rim:=top_boundary(source)
	assert(rim.size()==source.radial_segments)
	var first:=vertices.size()
	for point: Vector3 in rim:
		for radius: float in [source.top_radius,inner_radius]:
			var position:=Vector3(point.x*radius/source.top_radius,point.y,point.z*radius/source.top_radius)
			# Reuse the exact native exterior boundary, without recomputing angles.
			if radius==source.top_radius:position=point
			vertices.append(position)
			normals.append(Vector3.UP)
			tangents.append_array(PackedFloat32Array([1.0,0.0,0.0,-1.0]))
			uvs.append(Vector2(position.x,position.z))
	for segment: int in rim.size():
		var current:=first+segment*2
		var following:=first+((segment+1)%rim.size())*2
		# Clockwise native front faces, normal UP. The hole boundary shares the
		# water's regular polygon; no hidden top triangles span the water area.
		indices.append_array(PackedInt32Array([current,following,current+1,current+1,following,following+1]))
	# Close the cavity with inward walls. A duplicated UV seam preserves a
	# conventional frame even though the existing stone is world triplanar.
	var top_y: float=rim[0].y
	var floor_y: float=source.get_aabb().position.y+FLOOR_THICKNESS
	var wall_first:=vertices.size()
	for segment: int in range(rim.size()+1):
		var point: Vector3=rim[segment%rim.size()]
		var radial:=Vector3(point.x,0.0,point.z).normalized()
		var tangent:=Vector3(-radial.z,0.0,radial.x)
		for height: float in [top_y,floor_y]:
			vertices.append(Vector3(point.x*inner_radius/source.top_radius,height,point.z*inner_radius/source.top_radius))
			normals.append(-radial)
			tangents.append_array(PackedFloat32Array([tangent.x,tangent.y,tangent.z,1.0]))
			uvs.append(Vector2(float(segment)/float(rim.size()),(height-floor_y)/(top_y-floor_y)))
	for segment: int in rim.size():
		var current:=wall_first+segment*2
		var following:=current+2
		indices.append_array(PackedInt32Array([current,following,current+1,current+1,following,following+1]))
	# A5cm base separates this upward inner floor from the retained downward
	# exterior bottom. The closed volume prevents light leaking through backfaces.
	var floor_first:=vertices.size()
	vertices.append(Vector3(0.0,floor_y,0.0))
	normals.append(Vector3.UP)
	tangents.append_array(PackedFloat32Array([1.0,0.0,0.0,-1.0]))
	uvs.append(Vector2.ZERO)
	for point: Vector3 in rim:
		var position:=Vector3(point.x*inner_radius/source.top_radius,floor_y,point.z*inner_radius/source.top_radius)
		vertices.append(position)
		normals.append(Vector3.UP)
		tangents.append_array(PackedFloat32Array([1.0,0.0,0.0,-1.0]))
		uvs.append(Vector2(position.x,position.z))
	for segment: int in rim.size():
		indices.append_array(PackedInt32Array([floor_first,floor_first+1+segment,floor_first+1+(segment+1)%rim.size()]))
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TANGENT]=tangents
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.resource_name="FountainHollowBasin"
	# Keep the exact original documented render-bound override. ArrayMesh and
	# PrimitiveMesh compute their own resource bounds with tiny rounding differences.
	mesh.custom_aabb=source.get_aabb()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,source.surface_get_material(0))
	return mesh

static func top_boundary(source: CylinderMesh) -> PackedVector3Array:
	var arrays: Array=source.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var points: Array[Vector3]=[]
	for index: int in vertices.size():
		var point:=vertices[index]
		if normals[index].y<=0.9999 or Vector2(point.x,point.z).length()<source.top_radius*0.99:continue
		var repeated:=false
		for existing: Vector3 in points:
			if existing.distance_to(point)<0.00001:repeated=true;break
		if not repeated:points.append(point)
	points.sort_custom(func(a: Vector3,b: Vector3):return atan2(a.z,a.x)<atan2(b.z,b.x))
	return PackedVector3Array(points)
