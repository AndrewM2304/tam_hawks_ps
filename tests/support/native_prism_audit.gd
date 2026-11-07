extends RefCounted
## Independent topology evidence for the inspected six-corner native bank prisms.
## This reads collision triangles; it does not consume renderer or intent vertices.
static func closed_bank_faces(shape: CollisionShape3D) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not shape.shape is ConcavePolygonShape3D or shape.disabled or not shape.shape.backface_collision:return result
	var raw: PackedVector3Array=shape.shape.get_faces()
	if raw.size()!=60:return result
	var vertices: Dictionary={}
	var edges: Dictionary={}
	var origin: Vector3=shape.to_global(raw[0])
	var signed_volume:=0.0
	for offset: int in range(0,raw.size(),3):
		var points:=PackedVector3Array()
		var ids: Array[int]=[]
		for index: int in 3:
			var at: Vector3=shape.to_global(raw[offset+index])
			if not at.is_finite():return []
			points.append(at)
			if not vertices.has(at):vertices[at]=vertices.size()
			ids.append(vertices[at])
		var cross: Vector3=(points[1]-points[0]).cross(points[2]-points[0])
		var area:=cross.length()*.5
		if not is_finite(area) or area<=.000001:return []
		var normal: Vector3=-cross.normalized()
		signed_volume+=(points[0]-origin).dot((points[1]-origin).cross(points[2]-origin))/6.0
		result.append({"normal":normal,"distance":normal.dot(points[0]),"corners":points,"area":area,"seen":0.0})
		for index: int in 3:
			var first: int=ids[index]
			var last: int=ids[(index+1)%3]
			var key:=Vector2i(mini(first,last),maxi(first,last))
			var record: Vector2i=edges.get(key,Vector2i.ZERO)
			edges[key]=record+Vector2i(1,1 if first<last else -1)
	if vertices.size()!=12 or not is_finite(signed_volume) or signed_volume>=-.000001:return []
	for record: Vector2i in edges.values():
		if record!=Vector2i(2,0):return []
	return result
