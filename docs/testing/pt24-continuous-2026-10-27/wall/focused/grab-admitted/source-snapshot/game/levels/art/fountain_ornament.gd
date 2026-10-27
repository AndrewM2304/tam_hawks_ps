extends RefCounted
## Original turned-stone cup and patinated nozzle. These shared meshes replace
## the three display frusta only; the world retains collision and skating data.
static var _meshes: Dictionary = {}


static func shared_mesh(part: String) -> ArrayMesh:
	if _meshes.has(part): return _meshes[part]
	var profile := PackedVector2Array()
	var segments := 18
	var cap_start := false
	var cap_end := false
	var hard_ring := -1
	match part:
		"FountainPedestal":
			# Local to the unchanged Y1.2 node: submerged foot, shaft, capital.
			profile = PackedVector2Array([Vector2(1.0,-1.0), Vector2(.65,.65), Vector2(.70,.70)])
			cap_start = true
		"FountainBowl":
			# Local to Y2.1: outer wall, a real annular lip, then the inner cup.
			# Its open lower socket is hidden inside the pedestal capital.
			profile = PackedVector2Array([Vector2(.65,-.25), Vector2(1.65,.25),
				Vector2(1.48,.25), Vector2(.40,-.02)])
			hard_ring = 1
			cap_end = true
		"FountainCrown":
			# Local to Y2.7. The foot meets the new inner floor within the old
			# solid bowl's volume; the authored whole ornament envelope is kept.
			profile = PackedVector2Array([Vector2(.28,-.62), Vector2(.12,.12), Vector2(.22,.425)])
			segments = 12
			cap_start = true
			cap_end = true
		_:
			assert(false, "Unknown fountain ornament part: "+part)
			return null
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distances := PackedFloat32Array([0.0])
	for ring: int in range(1,profile.size()):
		distances.append(distances[ring-1]+profile[ring].distance_to(profile[ring-1]))
	for strip: int in range(profile.size()-1):
		var first_normal := _normal(profile,strip,strip,hard_ring)
		var last_normal := _normal(profile,strip+1,strip,hard_ring)
		for segment: int in segments:
			var a := TAU*float(segment)/float(segments)
			var b := TAU*float(segment+1)/float(segments)
			# Clockwise faces, including the inward-facing cup and upward lip.
			_vertex(surface,profile[strip],a,first_normal,distances[strip])
			_vertex(surface,profile[strip],b,first_normal,distances[strip])
			_vertex(surface,profile[strip+1],b,last_normal,distances[strip+1])
			_vertex(surface,profile[strip],a,first_normal,distances[strip])
			_vertex(surface,profile[strip+1],b,last_normal,distances[strip+1])
			_vertex(surface,profile[strip+1],a,last_normal,distances[strip+1])
	if cap_start: _cap(surface,profile[0],segments,false)
	if cap_end: _cap(surface,profile[profile.size()-1],segments,true)
	# Reuse coincident rings and fan centres instead of storing triangle soup.
	surface.index()
	var mesh := surface.commit()
	mesh.resource_name = part+"TurnedProfile"
	_meshes[part] = mesh
	return mesh


static func _normal(profile: PackedVector2Array, ring: int, strip: int, hard_ring: int) -> Vector2:
	if ring==0: return _strip_normal(profile,0)
	if ring==profile.size()-1: return _strip_normal(profile,ring-1)
	if ring==hard_ring: return _strip_normal(profile,strip)
	return (_strip_normal(profile,ring-1)+_strip_normal(profile,ring)).normalized()


static func _strip_normal(profile: PackedVector2Array, strip: int) -> Vector2:
	var edge := profile[strip+1]-profile[strip]
	return Vector2(edge.y,-edge.x).normalized()


static func _vertex(surface: SurfaceTool, point: Vector2, angle: float, normal: Vector2, along: float) -> void:
	var cosine := cos(angle)
	var sine := sin(angle)
	surface.set_normal(Vector3(cosine*normal.x,normal.y,sine*normal.x))
	surface.set_tangent(Plane(Vector3(-sine,0,cosine),-1.0))
	# Existing stone retains its world triplanar scale. Continuous angular /
	# profile UVs and analytic tangents also define a conventional UV frame.
	surface.set_uv(Vector2(angle,along))
	surface.add_vertex(Vector3(cosine*point.x,point.y,sine*point.x))


static func _cap(surface: SurfaceTool, point: Vector2, segments: int, upward: bool) -> void:
	var normal := Vector3.UP if upward else Vector3.DOWN
	for segment: int in segments:
		var a := TAU*float(segment)/float(segments)
		var b := TAU*float(segment+1)/float(segments)
		_cap_vertex(surface,Vector3(0,point.y,0),normal)
		for angle: float in [a,b] if upward else [b,a]:
			_cap_vertex(surface,Vector3(cos(angle)*point.x,point.y,sin(angle)*point.x),normal)


static func _cap_vertex(surface: SurfaceTool, point: Vector3, normal: Vector3) -> void:
	surface.set_normal(normal)
	surface.set_tangent(Plane(Vector3.RIGHT,-1.0 if normal.y>0.0 else 1.0))
	surface.set_uv(Vector2(point.x,point.z))
	surface.add_vertex(point)
