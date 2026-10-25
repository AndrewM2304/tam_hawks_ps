extends Node3D
## Original sunken hilltop facility. Every floor/deck/bank uses shared visible
## and native collision triangles; the support query indexes those same faces.

const SunkenBowl = preload("res://game/levels/sunken_bowl_feature.gd")
const Quarter = preload("res://game/levels/transition_feature.gd")
const Spine = preload("res://game/levels/spine_feature.gd")
const Grind = preload("res://game/tricks/grind_line.gd")
const LOCAL_BOUNDS := Rect2(-20,-15,40,30)
const STREET_Y := -1.5
var _built := false
var _features: Array[Node3D] = []
var _lines: Array = []
var _surface_cells: Dictionary = {}
var _support_triangles: Array[PackedVector3Array] = []
var _concrete: Material
var _steel: Material

func _ready() -> void:
	build()

func build() -> void:
	if _built: return
	_built = true
	set_meta("skate_feature", "sunken_skatepark")
	set_meta("district", "kelvingrove")
	_concrete = Quarter._concrete_material()
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("8d9795")
	metal.metallic = 0.72
	metal.roughness = 0.32
	_steel = metal
	var deep := SunkenBowl.new()
	deep.name = "DeepBowl"
	deep.feature_id = "kelvingrove_deep_bowl"
	deep.radius = 3.5
	deep.floor_radius = 3.2
	deep.deck_length = 1.5
	deep.port_half_segments = 9
	deep.port_cut_theta = deg_to_rad(40.0)
	deep.access_height = 2.0
	deep.channel_end_z = 10.0
	deep.position = Vector3(10.5,-3.5,-6.5)
	add_child(deep)
	_features.append(deep)
	var shallow := SunkenBowl.new()
	shallow.name = "ShallowBowl"
	shallow.feature_id = "kelvingrove_shallow_bowl"
	shallow.radius = 1.5
	shallow.floor_radius = 3.0
	shallow.deck_length = 1.5
	shallow.port_half_segments = 10
	shallow.port_cut_theta = 0.0
	shallow.access_height = 0.0
	shallow.channel_end_z = 11.0
	shallow.position = Vector3(-11.5,-1.5,-7.5)
	add_child(shallow)
	_features.append(shallow)
	var holes: Array[PackedVector2Array] = []
	for bowl: Node3D in [deep,shallow]:
		for world_polygon: PackedVector2Array in bowl.get_deck_voids():
			var polygon := PackedVector2Array()
			for p: Vector2 in world_polygon:
				var local := to_local(Vector3(p.x,global_position.y,p.y))
				polygon.append(Vector2(local.x,local.z))
			holes.append(polygon)
	_upper_deck(holes)
	_flat("LowerStreetBasin",Rect2(-20,3.5,40,11.5),STREET_Y)
	_box("EastArrivalDeck",Vector3(18.75,-0.75,9.25),Vector3(2.5,1.5,11.5),true)
	# A ten-metre bank makes the destination usable before the first drop-in.
	_ramp("BeginnerArrivalBank",PackedVector3Array([
		Vector3(17.5,0,6.5),Vector3(7.5,STREET_Y,6.5),
		Vector3(7.5,STREET_Y,10.5),Vector3(17.5,0,10.5)]))
	var hip := Spine.new()
	hip.name = "ForegroundHip"
	hip.feature_id = "kelvingrove_foreground_hip"
	hip.radius = 1.5
	hip.width = 7.0
	hip.cap_width = 0.6
	hip.position = Vector3(-13.0,STREET_Y,11.0)
	hip.rotation.y = PI*0.5
	add_child(hip)
	_features.append(hip)
	_stairs()
	# The ramp beside the stairs is a genuine supported return to the rim.
	_ramp("StepBypassBank",PackedVector3Array([
		Vector3(2.0,0,3.5),Vector3(2.0,STREET_Y,9.5),
		Vector3(5.0,STREET_Y,9.5),Vector3(5.0,0,3.5)]))
	# Close the under-deck openings while preserving both bowl ports, stairs
	# and the bypass bank. These spans meet their real entrance cheeks.
	var openings:Array[Vector2]=[Vector2(-3.5,-.5),Vector2(2,5)]
	for bowl:Node3D in [shallow,deep]:
		var half:float=(bowl.floor_radius+bowl.radius+bowl.deck_length)*sin(bowl.port_half_angle())
		openings.append(Vector2(bowl.position.x-half,bowl.position.x+half))
	openings.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.x<b.x)
	var cursor:float=-20.
	for opening:Vector2 in openings:
		_box("NorthStreetRetaining",Vector3((cursor+opening.x)*.5,-.75,3.425),Vector3(opening.x-cursor,1.5,.15),true)
		cursor=opening.y
	_box("NorthStreetRetaining",Vector3((cursor+20.)*.5,-.75,3.425),Vector3(20.-cursor,1.5,.15),true)
	var south_wall := _box("SouthRetainingFace",Vector3(0,-0.75,14.925),Vector3(40,1.5,0.15),true)
	var west_wall := _box("WestRetainingFace",Vector3(-19.925,-0.75,9.25),Vector3(0.15,1.5,11.5),true)
	_tag_grinds(south_wall,["Grind_Park_SouthRim"])
	_tag_grinds(west_wall,["Grind_Park_WestRim"])
	for interval: Vector2 in [Vector2(3.5,6.5),Vector2(10.5,15.0)]:
		var wall := _box("ArrivalDeckRetaining",Vector3(17.55,-0.75,(interval.x+interval.y)*0.5),Vector3(0.10,1.5,interval.y-interval.x),true)
		var edge_id := "Grind_Park_ArrivalEdge_"+str(interval.x)
		_tag_grinds(wall,[edge_id])
		_line(edge_id,PackedVector3Array([
			Vector3(17.5,0.02,interval.x),Vector3(17.5,0.02,interval.y)]),"ledge")
	_line("Grind_Park_SouthRim",PackedVector3Array([Vector3(-19.9,0.02,14.925),Vector3(19.9,0.02,14.925)]),"ledge",0.02)
	_line("Grind_Park_WestRim",PackedVector3Array([Vector3(-19.925,0.02,3.6),Vector3(-19.925,0.02,14.85)]),"ledge",0.02)
	_ledge("ProgressionLedge",Vector3(-1.0,STREET_Y+0.25,9.3),Vector3(5.5,0.50,0.65))
	_rail("Grind_Park_StreetFlatbar",PackedVector3Array([Vector3(-2,STREET_Y+0.62,12.6),Vector3(4.5,STREET_Y+0.62,12.6)]))
	_index_native_surfaces(self)

func _upper_deck(holes: Array[PackedVector2Array]) -> void:
	var faces := PackedVector3Array()
	# Native polygon clipping preserves exact curved boundaries. Small tiles
	# avoid ambiguous polygons-with-holes and never cap an excavated bowl.
	for x in 40:
		for z in 19:
			var left := -20.0+x
			var north := -15.0+float(z)
			var south := minf(north+1.0,3.5)
			if south<=north: continue
			var pieces: Array[PackedVector2Array] = [PackedVector2Array([
				Vector2(left,north),Vector2(left+1,north),Vector2(left+1,south),Vector2(left,south)])]
			for hole: PackedVector2Array in holes:
				var remaining: Array[PackedVector2Array] = []
				for piece: PackedVector2Array in pieces: remaining.append_array(Geometry2D.clip_polygons(piece,hole))
				pieces = remaining
			for piece: PackedVector2Array in pieces:
				var indices := Geometry2D.triangulate_polygon(piece)
				for index in range(0,indices.size(),3):
					var a := piece[indices[index]]
					var b := piece[indices[index+1]]
					var c := piece[indices[index+2]]
					faces.append_array(PackedVector3Array([Vector3(a.x,0,a.y),Vector3(b.x,0,b.y),Vector3(c.x,0,c.y)]))
	_panel("ExcavatedUpperDeck",faces)

func _flat(label: String, bounds: Rect2, height: float) -> void:
	_ramp(label,PackedVector3Array([Vector3(bounds.position.x,height,bounds.position.y),
		Vector3(bounds.position.x,height,bounds.end.y),Vector3(bounds.end.x,height,bounds.end.y),
		Vector3(bounds.end.x,height,bounds.position.y)]))


func apply_finishes(materials: Dictionary) -> void:
	# Existing world-space mineral concrete, paving and masonry resources.
	# No new textures/surfaces or doubled faces; steel retains its own finish.
	for mesh: Node in find_children("*","MeshInstance3D",true,false):
		if mesh.material_override!=_concrete:continue
		var label := str(mesh.get_parent().name)
		var key := "skate_concrete"
		if label in ["ExcavatedUpperDeck","AnnularDeck"] or "Step" in label:key="paving"
		elif "Retaining" in label or "OuterWall" in label or label=="NativePortCheeks":key="stone"
		mesh.material_override=materials[key]

func _ramp(label: String, corners: PackedVector3Array) -> void:
	var faces := PackedVector3Array([corners[0],corners[1],corners[2],corners[0],corners[2],corners[3]])
	if (faces[1]-faces[0]).cross(faces[2]-faces[0]).y>0:
		faces = PackedVector3Array([corners[0],corners[2],corners[1],corners[0],corners[3],corners[2]])
	_panel(label,faces)

func _panel(label: String, faces: PackedVector3Array) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.set_meta("terrain_surface",true)
	body.set_meta("facility_surface",true)
	body.set_meta("surface_audio","stone")
	add_child(body)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p: Vector3 in faces: surface.add_vertex(p)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = _concrete
	body.add_child(mesh)
	return body

func _box(label: String, at: Vector3, size: Vector3, wall: bool=false, layer: int=1, material: Material=null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	body.collision_layer = layer
	body.set_meta("wallrideable",wall)
	body.set_meta("surface_audio","stone" if layer==1 else "metal")
	body.set_meta("facility_surface",true)
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = _concrete if material==null else material
	body.add_child(mesh)
	return body

func _stairs() -> void:
	for step in 5:
		var top := -0.3*float(step+1)
		var thickness := maxf(0.08,top-STREET_Y)
		var z := 3.5+0.55*float(step)+0.275
		var tread := _box("FiveStepTread"+str(step+1),Vector3(-2,top-thickness*0.5,z),Vector3(3,thickness,0.55))
		var id := "Grind_Park_StairNose_"+str(step+1)
		# Lower three noses have independently matched native edge rays. The
		# upper two exact boundary rays are uncertain and remain generic guides.
		_line(id,PackedVector3Array([Vector3(-3.5,top+0.02,z+0.275),Vector3(-0.5,top+0.02,z+0.275)]),"ledge",0.02 if step>=2 else NAN)
		tread.set_meta("authored_grind_ids",[id])
		tread.set_meta("audit_capture_ids",[id])
	# Actual solid hubba tops descend with the flight and land on both decks.
	var start := Vector3(-4.0,0.4,2.8)
	var finish := Vector3(-4.0,STREET_Y+0.4,7.0)
	var direction := finish-start
	var angle := atan2(-direction.y,direction.z)
	var normal := Vector3(0,cos(angle),sin(angle))
	var hubba := _box("FiveStepHubba",(start+finish)*0.5-normal*0.22,Vector3(0.45,0.44,direction.length()),true)
	hubba.rotation.x = angle
	_line("Grind_Park_FiveStepHubba",PackedVector3Array([start+Vector3.UP*0.02,finish+Vector3.UP*0.02]),"ledge")
	# This narrow, real steel bearing stands clear of the broad stone. The
	# original guide/stone stay unchanged; named hardware bears on its crown.
	var coping := StaticBody3D.new()
	coping.name = "FiveStepHubbaSteelCoping"
	coping.position = (start+finish)*0.5+normal*0.06
	coping.basis = Basis(Quaternion(Vector3.UP,direction.normalized()))
	coping.collision_layer = 2
	coping.collision_mask = 0
	coping.set_meta("art_label","FiveStepHubbaSteelCoping")
	coping.set_meta("surface_audio","metal")
	coping.set_meta("authored_grind_ids",["Grind_Park_FiveStepHubba"])
	coping.set_meta("audit_capture_ids",["Grind_Park_FiveStepHubba"])
	add_child(coping)
	var coping_shape := CylinderShape3D.new()
	coping_shape.radius = 0.06
	coping_shape.height = direction.length()
	var coping_collision := CollisionShape3D.new()
	coping_collision.shape = coping_shape
	coping.add_child(coping_collision)
	var coping_mesh := CylinderMesh.new()
	coping_mesh.top_radius = 0.06
	coping_mesh.bottom_radius = 0.06
	coping_mesh.height = direction.length()
	coping_mesh.radial_segments = 24
	var coping_visual := MeshInstance3D.new()
	coping_visual.mesh = coping_mesh
	coping_visual.material_override = _steel
	coping.add_child(coping_visual)
	if Quarter.contact_frame_supported(global_transform):
		_lines.back().configure_contact(-0.02,0.12,"actual_raised_hubba_coping")
	hubba.set_meta("authored_grind_ids",["Grind_Park_FiveStepHubba"])
	hubba.set_meta("audit_capture_ids",["Grind_Park_FiveStepHubba"])
	_rail("Grind_Park_FiveStepHandrail",PackedVector3Array([Vector3(0.1,0.82,2.8),Vector3(0.1,STREET_Y+0.82,7.0)]))

func _ledge(label: String, at: Vector3, size: Vector3) -> void:
	var body := _box(label,at,size,true)
	var points := PackedVector3Array()
	for offset: Vector3 in [Vector3(-1,1,-1),Vector3(1,1,-1),Vector3(1,1,1),Vector3(-1,1,1),Vector3(-1,1,-1)]:
		points.append(at+offset*size*0.5+Vector3.UP*0.02)
	_line("Grind_Park_"+label,points,"ledge",0.02)
	body.set_meta("authored_grind_ids",["Grind_Park_"+label])
	body.set_meta("audit_capture_ids",["Grind_Park_"+label])

func _line(id: String, local_points: PackedVector3Array, kind: String, native_top_skin: float=NAN) -> void:
	var points := PackedVector3Array()
	for p: Vector3 in local_points: points.append(to_global(p))
	var line := Grind.new(id,points,kind)
	if is_finite(native_top_skin) and Quarter.contact_frame_supported(global_transform):
		# The capsule travel guide retains its ordinary20mm skin. Named board
		# contact uses the actual solid top, not that collision-admission skin.
		line.configure_contact(-native_top_skin,0.0,"sunken.native_box_top")
	_lines.append(line)

func _tag_grinds(body: StaticBody3D, ids: Array) -> void:
	body.set_meta("authored_grind_ids",ids)
	body.set_meta("audit_capture_ids",ids)

func _rail(id: String, points: PackedVector3Array) -> void:
	_line(id,points,"rail")
	var direction := points[1]-points[0]
	var radius := 0.045
	var lift := radius*sqrt(1.0-pow(direction.normalized().y,2))
	if Quarter.contact_frame_supported(global_transform):
		# Keep the existing finite native cylinder and guide unchanged. A grade
		# uses the actual axis drop and projected-up radial crown independently;
		# its guide at the originalXZ is not an exact cylinder bearing point.
		_lines.back().configure_contact(-lift,radius,"sunken.lowered_cylinder_crown")
	var center := (points[0]+points[1])*0.5-Vector3.UP*lift
	var bar := StaticBody3D.new()
	bar.name = id
	bar.collision_layer = 2
	bar.position = center
	bar.basis = Basis(Quaternion(Vector3.UP,direction.normalized()))
	bar.set_meta("surface_audio","metal")
	bar.set_meta("authored_grind_ids",[id])
	bar.set_meta("audit_capture_ids",[id])
	add_child(bar)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = direction.length()
	var collision := CollisionShape3D.new()
	collision.shape = shape
	bar.add_child(collision)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = direction.length()
	cylinder.radial_segments = 16
	var mesh := MeshInstance3D.new()
	mesh.mesh = cylinder
	mesh.material_override = _steel
	bar.add_child(mesh)
	for t: float in [0.12,0.88]:
		var top := points[0].lerp(points[1],t)-Vector3.UP*lift
		var bottom := Vector3(top.x,STREET_Y,top.z)
		_box("SteelRailPost",(top+bottom)*0.5,Vector3(0.065,top.y-bottom.y,0.065),false,2,_steel)

func _index_native_surfaces(node: Node) -> void:
	if node is StaticBody3D and (node.collision_layer & 1)!=0:
		for child: Node in node.get_children():
			if not child is MeshInstance3D or child.mesh==null: continue
			var faces: PackedVector3Array = child.mesh.get_faces()
			for index in range(0,faces.size(),3):
				var triangle := PackedVector3Array([child.to_global(faces[index]),child.to_global(faces[index+1]),child.to_global(faces[index+2])])
				# Godot's visible front faces are clockwise: mathematical cross
				# points down for an upward top, including native primitives.
				if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).y>=-0.00000001: continue
				var id := _support_triangles.size()
				_support_triangles.append(triangle)
				var minimum := Vector2(INF,INF)
				var maximum := Vector2(-INF,-INF)
				for p: Vector3 in triangle:
					minimum = minimum.min(Vector2(p.x,p.z))
					maximum = maximum.max(Vector2(p.x,p.z))
				for x in range(floori(minimum.x),floori(maximum.x)+1):
					for z in range(floori(minimum.y),floori(maximum.y)+1):
						var key := Vector2i(x,z)
						if not _surface_cells.has(key): _surface_cells[key]=[]
						_surface_cells[key].append(id)
	for child: Node in node.get_children(): _index_native_surfaces(child)

func get_surface_height(world_point: Vector3, max_step_up: float=INF) -> float:
	if not world_point.is_finite(): return NAN
	var local := to_local(world_point)
	if not LOCAL_BOUNDS.has_point(Vector2(local.x,local.z)): return NAN
	var highest := -INF
	var limit := world_point.y+max_step_up
	for id: int in _surface_cells.get(Vector2i(floori(world_point.x),floori(world_point.z)),[]):
		var triangle: PackedVector3Array = _support_triangles[id]
		var a := Vector2(triangle[0].x,triangle[0].z)
		var ab := Vector2(triangle[1].x,triangle[1].z)-a
		var ac := Vector2(triangle[2].x,triangle[2].z)-a
		var determinant := ab.cross(ac)
		if absf(determinant)<0.000000001: continue
		var p := Vector2(world_point.x,world_point.z)-a
		var u := p.cross(ac)/determinant
		var v := ab.cross(p)/determinant
		if u< -0.00001 or v< -0.00001 or u+v>1.00001: continue
		var y := triangle[0].y*(1-u-v)+triangle[1].y*u+triangle[2].y*v
		if y<=limit: highest=maxf(highest,y)
	return NAN if highest == -INF else highest

func get_grind_lines() -> Array:
	var result := _lines.duplicate()
	for feature: Node3D in _features: result.append_array(feature.get_grind_lines())
	return result

func get_feature_definitions() -> Array:
	var result: Array = [{"id":"kelvingrove_skatepark","kind":"sunken_skatepark","district":"kelvingrove",
		"label":"Kelvingrove Sunken Skatepark","position":global_position,"entry":to_global(Vector3(20,0,5)),
		"bounds":Rect2(global_position.x-20,global_position.z-15,40,30),"rim_y":global_position.y,
		"floor_y":global_position.y+STREET_Y,"review_from":to_global(Vector3(28,15,24)),"review_target":global_position}]
	for feature: Node3D in _features:
		if feature.name=="ForegroundHip":
			var a := feature.to_global(Vector3(0,0,9.8))
			var b := feature.to_global(Vector3(0,0,1.8))
			var c := feature.to_global(Vector3(0,0,-1.8))
			var d := feature.to_global(Vector3(0,0,-6.3))
			result.append({"id":"kelvingrove_foreground_hip","kind":"spine","label":"Compact foreground hip",
				"position":feature.global_position,"floor_y":feature.global_position.y,
				"bounds":Rect2(feature.global_position.x-1.8,feature.global_position.z-3.5,3.6,7.0),"minimum_run_lengths":{"approach":8.0,"landing":4.5},
				"max_exit_speed":13.0,"brake_on_landing":true,
				"approach":PackedVector3Array([a,b]),"landing":PackedVector3Array([c,d]),
				"lips":PackedVector3Array([feature.to_global(Vector3(0,1.5,-0.3)),feature.to_global(Vector3(0,1.5,0.3))])})
		else: result.append_array(feature.get_feature_definitions())
	return result

func get_safety_routes() -> Array:
	return [{"id":"kelvingrove_facility_beginner","label":"Sunken park gentle roll-in and return","requires_jump":false,
		"points":PackedVector3Array([to_global(Vector3(20,0,5)),to_global(Vector3(18.5,0,8.5)),
		to_global(Vector3(17.5,0,8.5)),to_global(Vector3(7.5,STREET_Y,8.5)),
		to_global(Vector3(7.5,STREET_Y,12.0)),to_global(Vector3(13.5,STREET_Y,12.0)),
		to_global(Vector3(13.5,STREET_Y,14.0)),to_global(Vector3(7.5,STREET_Y,14.0)),
		to_global(Vector3(7.5,STREET_Y,8.5)),to_global(Vector3(17.5,0,8.5)),
		to_global(Vector3(18.5,0,8.5)),to_global(Vector3(20,0,5))])}]
