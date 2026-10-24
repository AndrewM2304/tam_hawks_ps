extends RefCounted
## Material-only coverage clipped from the actual native floor triangles.
## There is no sampled height mesh, changed collision or bridge over a void.

const AREAS: Array[Rect2] = [Rect2(-151.5,-124,14,27),Rect2(-194,-106,34,22)]
const MAX_LIFT := 0.25
const CELL := 2.0
var _native_faces: Array[Dictionary] = []
var _cells: Dictionary = {}
var _body: StaticBody3D
var _surface: SurfaceTool
var _source := PackedVector3Array()
var _source_uv := PackedVector2Array()
var _skin := 0.006
var _changed := 0
var _max_lift := 0.0


func prepare(parent: Node3D) -> void:
	_native_faces.clear()
	_cells.clear()
	for body: Node in parent.get_children():
		if not body is StaticBody3D: continue
		if str(body.get_meta("art_label","")) not in ["KelvingroveRollingGround","KelvingroveRollingLoop","KelvingroveCentralEmbankment","ParkGranitePathEdge"]: continue
		for child: Node in body.get_children():
			if not child is CollisionShape3D or not child.shape is ConcavePolygonShape3D: continue
			var faces: PackedVector3Array = child.shape.get_faces()
			var transform: Transform3D = body.transform*child.transform
			for i in range(0,faces.size(),3):
				var triangle := PackedVector3Array([transform*faces[i],transform*faces[i+1],transform*faces[i+2]])
				var polygon := PackedVector2Array()
				for point: Vector3 in triangle: polygon.append(Vector2(point.x,point.z))
				if absf((polygon[1]-polygon[0]).cross(polygon[2]-polygon[0]))<0.00000001: continue
				var bounds := _bounds(polygon)
				var selected := false
				for area: Rect2 in AREAS: selected = selected or area.intersects(bounds,true)
				if not selected: continue
				var id := _native_faces.size()
				_native_faces.append({"triangle":triangle,"polygon":polygon,"bounds":bounds})
				for x in range(floori(bounds.position.x/CELL),floori(bounds.end.x/CELL)+1):
					for z in range(floori(bounds.position.y/CELL),floori(bounds.end.y/CELL)+1):
						var key := Vector2i(x,z)
						if not _cells.has(key): _cells[key] = []
						_cells[key].append(id)


func fit(body: StaticBody3D,_ground: Callable,skin: float = 0.006) -> void:
	var visual: MeshInstance3D
	for child: Node in body.get_children():
		if child is MeshInstance3D:
			visual = child
			break
	if visual == null or not visual.mesh is ArrayMesh: return
	_body = body
	_skin = skin
	_changed = 0
	_max_lift = 0.0
	var collision_hash := ""
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
			collision_hash = child.shape.get_faces().to_byte_array().hex_encode().sha256_text()
	_surface = SurfaceTool.new()
	_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arrays := visual.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in range(0,indices.size(),3):
		_source = PackedVector3Array()
		_source_uv = PackedVector2Array()
		var polygon := PackedVector2Array()
		for offset in 3:
			var point := body.transform*vertices[indices[i+offset]]
			_source.append(point)
			_source_uv.append(uv[indices[i+offset]])
			polygon.append(Vector2(point.x,point.z))
		var bounds := _bounds(polygon)
		var outside: Array[PackedVector2Array] = [polygon]
		for area: Rect2 in AREAS:
			if not area.intersects(bounds,true): continue
			var rectangle := _rectangle(area)
			var remaining: Array[PackedVector2Array] = []
			for piece: PackedVector2Array in outside: remaining.append_array(Geometry2D.clip_polygons(piece,rectangle))
			outside = remaining
		for piece: PackedVector2Array in outside: _emit_polygon(piece,_source,0.0)
		var omit_interior := false
		if body.has_meta("visual_trim_outer_side"):
			var side: float = body.get_meta("visual_trim_outer_side")
			omit_interior = (side>0 and i%12<6) or (side<0 and i%12>=6)
		if omit_interior: continue
		for area: Rect2 in AREAS:
			if not area.intersects(bounds,true): continue
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(polygon,_rectangle(area)):
				for id: int in _candidates(_bounds(piece)):
					var native: Dictionary = _native_faces[id]
					if not native.bounds.intersects(_bounds(piece),true): continue
					for clipped: PackedVector2Array in Geometry2D.intersect_polygons(piece,native.polygon):
						var largest_lift := -INF
						for point: Vector2 in clipped:
							largest_lift = maxf(largest_lift,_height(native.triangle,point)-_height(_source,point))
						if largest_lift>MAX_LIFT or largest_lift< -0.02: continue
						_emit_polygon(clipped,native.triangle,_skin)
						_changed += clipped.size()
						_max_lift = maxf(_max_lift,largest_lift+_skin)
	_surface.index()
	visual.mesh = _surface.commit()
	visual.set_meta("native_support_skin",true)
	visual.set_meta("visual_skin_areas",AREAS)
	visual.set_meta("visual_skin_vertices_changed",_changed)
	visual.set_meta("visual_skin_max_lift",_max_lift)
	visual.set_meta("visual_skin_offset",_skin)
	visual.set_meta("native_collision_sha256",collision_hash)
	visual.add_to_group("park_native_visual_skins")
	_surface = null
	_body = null


func _emit_polygon(polygon: PackedVector2Array,triangle: PackedVector3Array,lift: float) -> void:
	if polygon.size()<3: return
	for i in range(1,polygon.size()-1):
		var points := PackedVector3Array()
		for point: Vector2 in [polygon[0],polygon[i],polygon[i+1]]:
			points.append(Vector3(point.x,_height(triangle,point)+lift,point.y))
		var normal := (points[1]-points[0]).cross(points[2]-points[0])
		if normal.length_squared()<0.0000000001: continue
		if normal.y>0:
			var swap := points[1]
			points[1] = points[2]
			points[2] = swap
			normal = -normal
		for point: Vector3 in points:
			var weights := _weights(_source,Vector2(point.x,point.z))
			_surface.set_uv(_source_uv[0]*weights.x+_source_uv[1]*weights.y+_source_uv[2]*weights.z)
			_surface.set_normal(-normal.normalized())
			_surface.add_vertex(_body.transform.affine_inverse()*point)


func _candidates(bounds: Rect2) -> Array[int]:
	var unique: Dictionary = {}
	for x in range(floori(bounds.position.x/CELL),floori(bounds.end.x/CELL)+1):
		for z in range(floori(bounds.position.y/CELL),floori(bounds.end.y/CELL)+1):
			for id: int in _cells.get(Vector2i(x,z),[]): unique[id] = true
	var result: Array[int] = []
	for id: int in unique: result.append(id)
	return result


func _height(triangle: PackedVector3Array,point: Vector2) -> float:
	var weights := _weights(triangle,point)
	return triangle[0].y*weights.x+triangle[1].y*weights.y+triangle[2].y*weights.z


func _weights(triangle: PackedVector3Array,point: Vector2) -> Vector3:
	var a := Vector2(triangle[0].x,triangle[0].z)
	var ab := Vector2(triangle[1].x,triangle[1].z)-a
	var ac := Vector2(triangle[2].x,triangle[2].z)-a
	var determinant := ab.cross(ac)
	var relative := point-a
	var u := relative.cross(ac)/determinant
	var v := ab.cross(relative)/determinant
	return Vector3(1-u-v,u,v)


func _bounds(polygon: PackedVector2Array) -> Rect2:
	var minimum := polygon[0]
	var maximum := polygon[0]
	for point: Vector2 in polygon:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum,maximum-minimum)


func _rectangle(bounds: Rect2) -> PackedVector2Array:
	return PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
