extends RefCounted
## Original paintings inspired by Glasgow's public-art culture, not reproductions
## of named murals. Two existing blank rear walls; no new playable geometry.
## Construction only. Sources/placements: docs/research/GLASGOW-MURALS.md.

const MAX_TRIANGLES := 1200
const MAX_SURFACES := 2
const WALL_OFFSET := 0.018
const PAINT_LAYER_STEP := 0.0 # Painter order in a single surface, no competing depth strata.
const PAINT_LAYERS := 7
const PAINT_VISIBILITY_END := 45.0 # Bound small-detail work to nearby walls.
const NORMAL := Vector3.LEFT
const CANVASES: Array[Dictionary] = [
	{"id":"ClydeHeron", "title":"Clyde Heron", "wall_x":-47.0,
		"rect":Rect2(-10,3.1,16,8), "source_building":Vector3(-41,0,0),
		"wall_rect":Rect2(-15,0,30,16), "reference_note":"Original river-bird painting; fictional game placement"},
	{"id":"PrintworksBloom", "title":"Printworks Bloom", "wall_x":-81.7,
		"rect":Rect2(-61,3.4,12,7), "source_building":Vector3(-77.5,2.5,-55),
		"wall_rect":Rect2(-64,2.5,18,14), "reference_note":"Original thistle and printmaking painting; fictional game placement"},
]
const VIEWS: Array[Dictionary] = [
	{"id":"heron_front", "camera":Vector3(-62,7,-2), "target":Vector3(-47.018,7,-2)},
	{"id":"heron_approach", "camera":Vector3(-61,4.8,18), "target":Vector3(-47.018,7,-2)},
	{"id":"heron_close", "camera":Vector3(-53,7.2,-2), "target":Vector3(-47.018,7.2,-2)},
	{"id":"bloom_front", "camera":Vector3(-92,7,-55), "target":Vector3(-81.718,6.9,-55)},
	{"id":"bloom_oblique", "camera":Vector3(-91,5,-74), "target":Vector3(-81.718,6.9,-55)},
	{"id":"bloom_close", "camera":Vector3(-87,7,-55), "target":Vector3(-81.718,7,-55)},
]


class PaintData:
	extends RefCounted
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var canvas: Dictionary
	var shape_count := 0


static func build(world: Node3D, _materials: Dictionary) -> Node3D:
	assert(world != null and world.is_inside_tree())
	var existing := world.get_node_or_null("GlasgowMurals") as Node3D
	if existing != null: return existing
	var root := Node3D.new()
	root.name = "GlasgowMurals"
	root.set_meta("art_only", true)
	root.set_meta("original_art", true)
	world.add_child(root)
	var material := StandardMaterial3D.new()
	material.resource_name = "OriginalWallPaintVertexColour"
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Decal pass: draw after opaque walls, test their depth, write no paint depth.
	# All colour alpha stays one; author order resolves overlapping brush shapes.
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.no_depth_test = false
	material.disable_receive_shadows = true
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.roughness = 1.0
	var rows: Array[Dictionary] = []
	var triangles := 0
	for index: int in CANVASES.size():
		var data := PaintData.new()
		data.canvas = CANVASES[index]
		if index == 0: _heron(data)
		else: _bloom(data)
		var row := _flush(root,data,material)
		rows.append(row)
		triangles += int(row.triangles)
	assert(triangles <= MAX_TRIANGLES and rows.size() <= MAX_SURFACES,
		"Original murals exceeded their declared rendering budget")
	root.set_meta("mural_report", {"schema":1, "chunks":rows, "triangles":triangles,
		"mesh_instances":rows.size(), "surfaces":rows.size(), "shared_materials":1,
		"maximum_main_draws":rows.size(), "new_textures":0, "shadow_casting_instances":0,
		"receives_shadows":false, "physics_objects":0, "process_callbacks":0,
		"shading":"alpha_one_unshaded_painter_pass", "depth_test":true, "depth_writes":false,
		"visibility_end_m":PAINT_VISIBILITY_END, "min_wall_offset":WALL_OFFSET,
		"max_wall_offset":WALL_OFFSET + PAINT_LAYER_STEP * (PAINT_LAYERS - 1),
		"reference_note":"Original game paintings; named trail artworks are research only",
		"views":VIEWS.duplicate(true), "measured_performance":false})
	return root


static func _heron(data: PaintData) -> void:
	# Broad quiet fields leave the existing masonry visible around the painting.
	var chalk := Color("a69b79")
	var slate := Color("35494f")
	var pale := Color("b4b5a4")
	var blue := Color("617e83")
	var dark := Color("263738")
	_polygon(data,_oval(Vector2(0.53,0.55),Vector2(0.31,0.38),32),Color("777d6b"),0)
	_polygon(data,_oval(Vector2(0.52,0.57),Vector2(0.285,0.36),28),Color("858975"),1)
	# River strokes and reed stems have independent tapered brush ends.
	for i: int in range(3):
		var lift := float(i)*0.033
		_stroke(data,_curve(Vector2(0.04,0.12+lift),Vector2(0.33,0.015+lift),
			Vector2(0.57,0.23+lift),Vector2(0.97,0.13+lift),12),0.014,0.002,
			Color("547978").lightened(float(i)*0.045),2)
	for i: int in range(5):
		var x := 0.10+float(i)*0.032
		_stroke(data,_curve(Vector2(x,0.12),Vector2(x+0.012,0.24),Vector2(x-0.02,0.30),
			Vector2(x-0.055,0.39+float(i%3)*0.045),5),0.003,0.001,Color("5d654e"),2)
		_leaf(data,Vector2(x-0.011,0.25),Vector2(x-0.071,0.34),0.015,Color("7d8059"),2)
	# Two bent, properly joined legs stand in the river field.
	_stroke(data,PackedVector2Array([Vector2(0.54,0.42),Vector2(0.58,0.28),Vector2(0.56,0.15)]),0.008,0.004,chalk,2)
	_stroke(data,PackedVector2Array([Vector2(0.60,0.42),Vector2(0.64,0.24),Vector2(0.68,0.16)]),0.007,0.003,Color("8c8061"),2)
	_stroke(data,PackedVector2Array([Vector2(0.56,0.15),Vector2(0.61,0.14)]),0.004,0.001,chalk,3)
	_stroke(data,PackedVector2Array([Vector2(0.68,0.16),Vector2(0.73,0.15)]),0.004,0.001,chalk,3)
	# Continuous body, S-neck and crown; no copied reference outline.
	var body := _curve(Vector2(0.31,0.48),Vector2(0.31,0.72),Vector2(0.51,0.76),Vector2(0.65,0.58),10)
	body.append_array(_curve(Vector2(0.65,0.58),Vector2(0.69,0.47),Vector2(0.56,0.35),Vector2(0.40,0.40),8))
	body.append(Vector2(0.29,0.34))
	_polygon(data,body,slate,3)
	_stroke(data,_curve(Vector2(0.60,0.54),Vector2(0.79,0.65),Vector2(0.57,0.81),Vector2(0.72,0.84),15),0.044,0.025,pale,3)
	_stroke(data,_curve(Vector2(0.60,0.54),Vector2(0.78,0.65),Vector2(0.58,0.81),Vector2(0.72,0.84),15),0.011,0.009,Color("798a83"),4)
	_polygon(data,_oval(Vector2(0.735,0.845),Vector2(0.047,0.030),18),pale,4)
	_polygon(data,PackedVector2Array([Vector2(0.77,0.857),Vector2(0.91,0.835),Vector2(0.772,0.828)]),Color("b2a068"),4)
	_stroke(data,PackedVector2Array([Vector2(0.71,0.858),Vector2(0.765,0.852)]),0.006,0.004,dark,5)
	_stroke(data,_curve(Vector2(0.716,0.864),Vector2(0.69,0.88),Vector2(0.67,0.86),Vector2(0.64,0.855),6),0.006,0.001,dark,5)
	_polygon(data,_oval(Vector2(0.752,0.849),Vector2(0.006,0.008),8),Color("d1b776"),6)
	_polygon(data,_oval(Vector2(0.754,0.849),Vector2(0.0023,0.0045),6),dark,6)
	# Wing underpainting and fine tapered feather rows suggest painted detail.
	var wing := _curve(Vector2(0.34,0.57),Vector2(0.38,0.71),Vector2(0.56,0.67),Vector2(0.62,0.52),9)
	wing.append_array(_curve(Vector2(0.62,0.52),Vector2(0.53,0.46),Vector2(0.38,0.45),Vector2(0.32,0.39),8))
	_polygon(data,wing,blue,4)
	for i: int in range(15):
		var t := float(i)/14.0
		var begin := Vector2(0.36+t*0.23,0.60+sin(t*PI)*0.048)
		var end := Vector2(0.305+t*0.24,0.39+t*0.115)
		_stroke(data,_curve(begin,begin+Vector2(-0.015,-0.06),end+Vector2(0.035,0.06),end,4),
			0.0037,0.0006,Color("a1b1aa").darkened(float(i%3)*0.06),5)
	for i: int in range(5):
		var x := 0.60+float(i)*0.009
		_stroke(data,_curve(Vector2(x,0.59),Vector2(x+0.005,0.55),Vector2(x-0.02,0.51),Vector2(x-0.026,0.47),4),
			0.0022,0.0003,pale,5)
	_wear(data,Rect2(0.32,0.42,0.28,0.22),14,405,Color("697a76"),6)


static func _bloom(data: PaintData) -> void:
	var cream := Color("b5ad8b")
	var green := Color("677c63")
	var dark := Color("394c42")
	# Asymmetric ink ribbons leave broad gaps of the existing wall exposed.
	for i: int in range(3):
		var shift := float(i)*0.045
		_stroke(data,_curve(Vector2(0.06,0.24+shift),Vector2(0.37,0.03+shift),
			Vector2(0.58,0.19+shift),Vector2(0.94,0.65+shift),14),0.035,0.004,
			Color("887862").lightened(float(i)*0.05),0)
	_stroke(data,_curve(Vector2(0.46,0.09),Vector2(0.65,0.31),Vector2(0.40,0.47),Vector2(0.57,0.69),13),
		0.012,0.006,dark,2)
	_stroke(data,_curve(Vector2(0.46,0.09),Vector2(0.65,0.31),Vector2(0.40,0.47),Vector2(0.57,0.69),13),
		0.003,0.002,cream,3)
	var leaves: Array[Vector4] = [Vector4(0.51,0.20,0.27,0.32),Vector4(0.54,0.29,0.76,0.39),
		Vector4(0.51,0.39,0.28,0.53),Vector4(0.50,0.48,0.72,0.60),Vector4(0.53,0.58,0.37,0.68)]
	for i: int in leaves.size():
		var leaf := leaves[i]
		var start := Vector2(leaf.x,leaf.y)
		var end := Vector2(leaf.z,leaf.w)
		_thistle_leaf(data,start,end,0.052,green.lightened(float(i%2)*0.045),2)
		_stroke(data,PackedVector2Array([start,end]),0.0025,0.0005,cream.darkened(0.14),3)
		for vein: int in range(3):
			var at := start.lerp(end,0.25+float(vein)*0.18)
			var tip := at+(end-start)*0.11+Vector2(-0.006,0.023)
			_stroke(data,PackedVector2Array([at,tip]),0.0017,0.0003,cream.darkened(0.2),3)
	# Thistle bracts and rising florets form a botanical silhouette, not a logo.
	_polygon(data,_oval(Vector2(0.575,0.685),Vector2(0.095,0.095),24),green,3)
	for i: int in range(9):
		var t := float(i)/8.0
		var x := 0.485+t*0.18
		_polygon(data,PackedVector2Array([Vector2(x,0.66),Vector2(x-0.017,0.75+sin(t*PI)*0.02),
			Vector2(x+0.027,0.708)]),dark.lightened(float(i%3)*0.06),4)
	for i: int in range(17):
		var t := float(i)/16.0
		var start := Vector2(0.49+t*0.17,0.73+sin(t*PI)*0.015)
		var end := Vector2(0.465+t*0.225,0.82+sin(t*PI)*0.105)
		_stroke(data,_curve(start,start+Vector2(-0.006,0.045),end+Vector2(0.009,-0.035),end,5),
			0.0055,0.001,Color("836078").lightened(float(i%4)*0.05),5)
		_stroke(data,PackedVector2Array([end-Vector2(0,0.035),end]),0.0016,0.0004,Color("b49d9e"),6)
	# The offset seed head alludes to a printing wheel without painted lettering.
	_polygon(data,_oval(Vector2(0.23,0.69),Vector2(0.075,0.115),22),Color("9a8b6e"),1)
	_polygon(data,_oval(Vector2(0.23,0.69),Vector2(0.056,0.088),20),Color("79775f"),2)
	for i: int in range(10):
		var angle := TAU*float(i)/10.0
		var spoke := Vector2(cos(angle)*0.057,sin(angle)*0.088)
		_stroke(data,PackedVector2Array([Vector2(0.23,0.69)+spoke*0.2,Vector2(0.23,0.69)+spoke]),
			0.0025,0.001,cream.darkened(0.16),3)
	_wear(data,Rect2(0.29,0.22,0.44,0.28),14,642,Color("817e69"),6)


static func _curve(a: Vector2, b: Vector2, c: Vector2, d: Vector2, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in range(steps+1):
		var t := float(i)/float(steps)
		var inverse := 1.0-t
		points.append(a*inverse*inverse*inverse+b*3.0*inverse*inverse*t+c*3.0*inverse*t*t+d*t*t*t)
	return points


static func _oval(at: Vector2, radii: Vector2, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in steps:
		var angle := TAU*float(i)/float(steps)
		points.append(at+Vector2(cos(angle),sin(angle))*radii)
	return points


static func _leaf(data: PaintData, start: Vector2, end: Vector2, width: float, color: Color, layer: int) -> void:
	var normal := (end-start).orthogonal().normalized()*width
	var points := _curve(start,start.lerp(end,0.32)+normal,start.lerp(end,0.72)+normal,end,5)
	points.append_array(_curve(end,start.lerp(end,0.70)-normal,start.lerp(end,0.30)-normal,start,5))
	_polygon(data,points,color,layer)


static func _thistle_leaf(data: PaintData, start: Vector2, end: Vector2, width: float, color: Color, layer: int) -> void:
	var normal := (end-start).orthogonal().normalized()
	var points := PackedVector2Array([start])
	for i: int in range(1,8):
		var t := float(i)/8.0
		points.append(start.lerp(end,t)+normal*width*sin(t*PI)*(1.0 if i%2 else 0.35))
	points.append(end)
	for i: int in range(7,0,-1):
		var t := float(i)/8.0
		points.append(start.lerp(end,t)-normal*width*sin(t*PI)*(0.85 if i%2 else 0.30))
	_polygon(data,points,color,layer)


static func _stroke(data: PaintData, points: PackedVector2Array, start_width: float, end_width: float, color: Color, layer: int) -> void:
	# A single outline shares its joins; no overlapping segment quads.
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i: int in points.size():
		var tangent := points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]
		var width := lerpf(start_width,end_width,float(i)/float(points.size()-1))
		var offset := tangent.orthogonal().normalized()*width*0.5
		left.append(points[i]+offset)
		right.append(points[i]-offset)
	right.reverse()
	left.append_array(right)
	_polygon(data,left,color,layer)


static func _wear(data: PaintData, area: Rect2, count: int, seed_value: int, color: Color, layer: int) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for i: int in count:
		var at := area.position+Vector2(random.randf(),random.randf())*area.size
		var size := Vector2(random.randf_range(0.002,0.008),random.randf_range(0.001,0.004))
		_polygon(data,PackedVector2Array([at-size,at+Vector2(size.x,-size.y*0.4),at+size*0.6]),
			color.lightened(random.randf_range(0.0,0.08)),layer)


static func _polygon(data: PaintData, input: PackedVector2Array, color: Color, layer: int) -> void:
	assert(layer >= 0 and layer < PAINT_LAYERS)
	# Curves share endpoints. Remove duplicates before native triangulation.
	var points := PackedVector2Array()
	for point: Vector2 in input:
		if points.is_empty() or point.distance_squared_to(points[-1]) > 0.0000000001: points.append(point)
	if points.size()>2 and points[0].distance_squared_to(points[-1])<0.0000000001: points.remove_at(points.size()-1)
	var indices := Geometry2D.triangulate_polygon(points)
	assert(not indices.is_empty(), "Original paint outline must be a valid simple polygon")
	var rect: Rect2 = data.canvas.rect
	var wall_rect: Rect2 = data.canvas.wall_rect
	var x := float(data.canvas.wall_x)-WALL_OFFSET-float(layer)*PAINT_LAYER_STEP
	for i: int in range(0,indices.size(),3):
		var triangle: Array[Vector3] = []
		for offset: int in range(3):
			var point := points[indices[i+offset]]
			assert(point.x>=0 and point.x<=1 and point.y>=0 and point.y<=1)
			var face_point := rect.position+point*rect.size
			assert(wall_rect.has_point(face_point))
			triangle.append(Vector3(x,face_point.y,face_point.x))
		# Godot front faces use clockwise winding viewed from the normal side.
		if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).dot(NORMAL)>0:
			var swap := triangle[1]
			triangle[1] = triangle[2]
			triangle[2] = swap
		for vertex: Vector3 in triangle:
			data.vertices.append(vertex)
			data.normals.append(NORMAL)
			# Static rear-wall shade, with a restrained painted vertical gradient.
			var tone := 0.80+0.04*clampf((vertex.y-rect.position.y)/rect.size.y,0,1)
			data.colors.append(Color(color.r*tone,color.g*tone,color.b*tone,1))
	data.shape_count += 1


static func _flush(root: Node3D, data: PaintData, material: Material) -> Dictionary:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	var rect: Rect2 = data.canvas.rect
	var centre := Vector3(float(data.canvas.wall_x)-WALL_OFFSET, rect.get_center().y, rect.get_center().x)
	var local_vertices := PackedVector3Array()
	for vertex: Vector3 in data.vertices: local_vertices.append(vertex-centre)
	arrays[Mesh.ARRAY_VERTEX] = local_vertices
	arrays[Mesh.ARRAY_NORMAL] = data.normals
	arrays[Mesh.ARRAY_COLOR] = data.colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var instance := MeshInstance3D.new()
	instance.name = str(data.canvas.id)
	instance.position = centre
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	instance.visibility_range_end = PAINT_VISIBILITY_END
	instance.set_meta("original_wall_paint",true)
	root.add_child(instance)
	return {"id":data.canvas.id, "title":data.canvas.title, "triangles":data.vertices.size()/3,
		"surfaces":1, "shapes":data.shape_count, "bounds_local":mesh.get_aabb(),
		"material_instance_id":material.get_instance_id(), "wall_x":data.canvas.wall_x,
		"painted_rect":data.canvas.rect, "wall_rect":data.canvas.wall_rect,
		"normal":NORMAL, "source_building":data.canvas.source_building}
