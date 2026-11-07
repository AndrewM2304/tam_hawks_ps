extends RefCounted
## Original restrained order, authored in metres; native collision remains world-owned.

static var _mesh: ArrayMesh
const SEGMENTS := 24


static func shared_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	# (radius,height). Rounded base courses, a restrained shaft entasis and neck
	# meet the existing square abacus. Maximum radius0.54 and top5.175 are exact.
	var profile := PackedVector2Array([
		Vector2(0.54,0.0), Vector2(0.54,0.08), Vector2(0.51,0.115),
		Vector2(0.48,0.14), Vector2(0.48,0.245), Vector2(0.45,0.275),
		Vector2(0.42,0.315), Vector2(0.42,0.40), Vector2(0.35,0.43),
		Vector2(0.34,0.46), Vector2(0.34,1.25), Vector2(0.333,2.70),
		Vector2(0.327,4.70), Vector2(0.316,4.96), Vector2(0.35,5.00),
		Vector2(0.35,5.06), Vector2(0.39,5.10), Vector2(0.46,5.175)])
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring: int in range(profile.size()):
		var before: Vector2 = profile[maxi(0,ring-1)]
		var after: Vector2 = profile[mini(profile.size()-1,ring+1)]
		var direction := (after-before).normalized()
		for segment: int in range(SEGMENTS+1):
			var angle := TAU*float(segment)/float(SEGMENTS)
			var radial := Vector3(cos(angle),0,sin(angle))
			vertices.append(radial*profile[ring].x + Vector3.UP*profile[ring].y)
			normals.append((radial*direction.y-Vector3.UP*direction.x).normalized())
			tangents.append_array(PackedFloat32Array([-sin(angle),0,cos(angle),-1]))
			uvs.append(Vector2(float(segment)/float(SEGMENTS),profile[ring].y))
			if ring == profile.size()-1 or segment == SEGMENTS:
				continue
			var a := ring*(SEGMENTS+1)+segment
			var b := a+1
			var c := a+SEGMENTS+2
			var d := a+SEGMENTS+1
			# Godot's clockwise front winding, outward facing on the shaft.
			indices.append_array(PackedInt32Array([a,b,c,a,c,d]))
	for cap: int in [0, profile.size()-1]:
		var normal := Vector3.DOWN if cap == 0 else Vector3.UP
		var center := vertices.size()
		vertices.append(Vector3.UP*profile[cap].y)
		normals.append(normal)
		tangents.append_array(PackedFloat32Array([1,0,0,1 if cap == 0 else -1]))
		uvs.append(Vector2(0.5,0.5))
		for segment: int in range(SEGMENTS+1):
			var angle := TAU*float(segment)/float(SEGMENTS)
			var radial := Vector3(cos(angle),0,sin(angle))
			vertices.append(radial*profile[cap].x+Vector3.UP*profile[cap].y)
			normals.append(normal)
			tangents.append_array(PackedFloat32Array([1,0,0,1 if cap == 0 else -1]))
			uvs.append(Vector2(0.5+cos(angle)*0.5,0.5+sin(angle)*0.5))
			if segment == SEGMENTS:
				continue
			var first := center+segment+1
			if cap == 0:
				indices.append_array(PackedInt32Array([center,first+1,first]))
			else:
				indices.append_array(PackedInt32Array([center,first,first+1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _mesh
