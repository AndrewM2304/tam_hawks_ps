extends RefCounted
## Original procedural set dressing shared by the optional local activities.

static func material(colour: Color, metal: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = colour
	result.roughness = 0.82
	result.metallic = metal
	return result

static func box(parent: Node3D, label: String, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var result := MeshInstance3D.new()
	result.name = label
	result.position = at
	result.mesh = mesh
	result.material_override = material(colour)
	parent.add_child(result)
	return result

static func cylinder(parent: Node3D, label: String, at: Vector3, radius: float, height: float, colour: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var result := MeshInstance3D.new()
	result.name = label
	result.position = at
	result.mesh = mesh
	result.material_override = material(colour)
	parent.add_child(result)
	return result

static func sign(parent: Node3D, at: Vector3, title: String, colour: Color = Color("eee7d8")) -> Label3D:
	var result := Label3D.new()
	result.name = "ActivitySign"
	result.position = at
	result.text = title
	result.font_size = 42
	result.pixel_size = 0.009
	result.modulate = colour
	result.outline_modulate = Color("202a2b")
	result.outline_size = 12
	result.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	result.no_depth_test = false
	parent.add_child(result)
	return result

static func regular(parent: Node3D, at: Vector3, steward: bool = false) -> Node3D:
	var figure = preload("res://game/features/activity_actor.gd").new()
	figure.steward = steward
	figure.name = "FestivalSteward" if steward else "ParkRegular"
	figure.position = at
	parent.add_child(figure)
	return figure

## Thin original activity paint, fitted once to native support after physics
## synchronization. Unsupported samples are omitted rather than bridged in air.
static func fit_terrain_gate(paint: MeshInstance3D, radius: float) -> void:
	if not is_instance_valid(paint) or not paint.is_inside_tree() or not is_finite(radius) or radius<=0.2: return
	var data := {"paint":paint,"space":paint.get_world_3d().direct_space_state,
		"cache":{},"vertices":[],"normals":[],"indices":[],"skipped":0}
	const SEGMENTS := 256
	const STRIPS := 3
	for segment in SEGMENTS:
		var a := Vector2(cos(TAU*segment/SEGMENTS),sin(TAU*segment/SEGMENTS))
		var b := Vector2(cos(TAU*((segment+1)%SEGMENTS)/SEGMENTS),sin(TAU*((segment+1)%SEGMENTS)/SEGMENTS))
		for strip in STRIPS:
			var inner := radius-0.18+0.18*strip/STRIPS
			var outer := radius-0.18+0.18*(strip+1)/STRIPS
			_paint_triangle(data,a*inner,b*inner,b*outer,0)
			_paint_triangle(data,a*inner,b*outer,a*outer,0)
	# Four inward cues identify a gate from either route direction without
	# suggesting a false route arrow at a shared gate.
	for side in 4:
		var radial := Vector2(cos(side*PI*0.5),sin(side*PI*0.5))
		var tangent := Vector2(-radial.y,radial.x)
		for sign_side: float in [-1.0,1.0]:
			_paint_stroke(data,radial*1.25,radial*1.75+tangent*0.28*sign_side,0.10)
	if data.indices.is_empty(): return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(data.vertices)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(data.normals)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(data.indices)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	paint.mesh = mesh
	var colour := material(Color("9b955a"))
	colour.roughness = 0.96
	colour.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.material_override = colour
	paint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	paint.set_meta("paint_skin",0.009)
	paint.set_meta("paint_radius",radius)
	paint.set_meta("paint_skipped_triangles",int(data.skipped))

static func _paint_sample(data: Dictionary, at: Vector2) -> Dictionary:
	if data.cache.has(at): return data.cache[at]
	var paint: MeshInstance3D = data.paint
	var origin := paint.to_global(Vector3(at.x,0,at.y))
	var query := PhysicsRayQueryParameters3D.create(origin+Vector3.UP*2.0,origin-Vector3.UP*2.0,1)
	var hit: Dictionary = data.space.intersect_ray(query)
	var result := {}
	if not hit.is_empty() and Vector3(hit.normal).y>=0.5 and Vector3(hit.position).is_finite():
		var world: Vector3 = Vector3(hit.position)+Vector3.UP*0.009
		result = {"position":paint.to_local(world),"height":world.y,
			"normal":(paint.global_basis.transposed()*Vector3(hit.normal)).normalized()}
	data.cache[at] = result
	return result

static func _paint_triangle(data: Dictionary, a: Vector2, b: Vector2, c: Vector2, depth: int) -> void:
	var pa := _paint_sample(data,a)
	var pb := _paint_sample(data,b)
	var pc := _paint_sample(data,c)
	if pa.is_empty() or pb.is_empty() or pc.is_empty():
		data.skipped = int(data.skipped)+1
		return
	var conforms := true
	for weights: Vector3 in [Vector3(1.0/3.0,1.0/3.0,1.0/3.0),Vector3(0.5,0.5,0),Vector3(0,0.5,0.5),Vector3(0.5,0,0.5)]:
		var sample := _paint_sample(data,a*weights.x+b*weights.y+c*weights.z)
		var expected: float = float(pa.height)*weights.x+float(pb.height)*weights.y+float(pc.height)*weights.z
		if sample.is_empty() or absf(float(sample.height)-expected)>0.0015:
			conforms = false
			break
	if not conforms:
		if depth<4:
			var ab := (a+b)*0.5
			var bc := (b+c)*0.5
			var ca := (c+a)*0.5
			_paint_triangle(data,a,ab,ca,depth+1)
			_paint_triangle(data,ab,b,bc,depth+1)
			_paint_triangle(data,ca,bc,c,depth+1)
			_paint_triangle(data,ab,bc,ca,depth+1)
		else:
			# Do not connect paint over a real step or unsupported seam.
			data.skipped = int(data.skipped)+1
		return
	for point: Dictionary in [pa,pb,pc]:
		if not point.has("index"):
			point["index"] = data.vertices.size()
			data.vertices.append(point.position)
			data.normals.append(point.normal)
		data.indices.append(int(point.index))

static func _paint_stroke(data: Dictionary, from: Vector2, to: Vector2, width: float) -> void:
	var tangent := (to-from).normalized()
	var across := Vector2(-tangent.y,tangent.x)*width*0.5
	var count := maxi(1,ceili(from.distance_to(to)/0.06))
	for segment in count:
		var a := from.lerp(to,float(segment)/count)
		var b := from.lerp(to,float(segment+1)/count)
		_paint_triangle(data,a-across,a+across,b+across,0)
		_paint_triangle(data,a-across,b+across,b-across,0)
