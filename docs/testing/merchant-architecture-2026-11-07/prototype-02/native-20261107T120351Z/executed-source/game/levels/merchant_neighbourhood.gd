extends Node3D
## PRIVATE original neighbourhood graybox. Geometry/playability prototype, not final art.
const Catalog = preload("res://game/progression/level_catalog.gd")
const Surface = preload("res://game/levels/outdoors/surface_builder.gd")
const Terrain = preload("res://game/levels/core_terrain.gd")
const CityArt = preload("res://game/levels/city_art.gd")
const Bowl = preload("res://game/levels/sunken_bowl_feature.gd")
const Spine = preload("res://game/levels/spine_feature.gd")
const Quarter = preload("res://game/levels/transition_feature.gd")
const Grind = preload("res://game/tricks/grind_line.gd")
const BOUNDS := Rect2(-100,-80,200,160)
const BASIN_BOUNDS := Rect2(30,20,48,40)
const PORT_BANK := Rect2(48,14,10,10)
const WEST_ENTRY := Rect2(20,24,10,6)
const WAREHOUSE := Rect2(30,-52,46,30)
const SPACING := 1.0
const TERRACE_PATCHES := [
	{"rect":Rect2(-30,-6,52,46),"y":4.0,"blend":8.0},
	{"rect":Rect2(-61,-53,21,17),"y":10.0,"blend":6.0},
	{"rect":Rect2(-51,-32,21,17),"y":7.0,"blend":6.0},
	# Whole quarter/side-roll-in envelope and the stair landing approach.
	{"rect":Rect2(-74,-66,24,14),"y":12.0,"blend":4.0}]
const PALETTE := {"stone":Color("a89d87"),"stone_light":Color("c1b8a4"),
	"sandstone":Color("927563"),"slate":Color("3b444b"),"teal":Color("315e60"),
	"coral":Color("a45d44"),"cream":Color("ddd5bf"),"paving":Color("777b7b"),
	"path":Color("979b98"),"glass":Color("213747"),"bronze":Color("42615a"),
	"orange":Color("cb752f"),"asphalt":Color("303b40")}
var _materials: Dictionary
var _layout: Dictionary
var _terrain = Terrain.new()
var _court_features: Array[Node3D] = []
var _support_triangles: Array[PackedVector3Array] = []
var _support_cells: Dictionary = {}
var _upper_terrain = Terrain.new()
var _lines: Array = []
var _quarters: Array[Node3D] = []
var _features: Array[Dictionary] = []
var _routes: Array[Dictionary] = []
var _roof_patches: Array[Dictionary] = []
var _cone: Node3D
var cone_activated := false
var render_budget_report: Dictionary = {}
var static_batch_report: Dictionary = {}
var solid_wall_occluders := 0

func _ready() -> void:
	name = "MerchantDistrict"
	_layout = JSON.parse_string(FileAccess.get_file_as_string("res://game/levels/merchant_layout.json"))
	var material_factory := CityArt.new()
	_materials = material_factory.make_materials(PALETTE)
	material_factory.free()
	_materials["skate_concrete"] = Quarter._concrete_material()
	_build_light()
	Surface.terrain(self,"NeighbourhoodGround",BOUNDS,SPACING,_height,_materials.asphalt,
		[BASIN_BOUNDS,PORT_BANK,WEST_ENTRY])
	_build_blocks()
	_build_market()
	_build_upper_steps()
	_build_loading()
	_build_street_choices()
	_build_basin()
	_build_routes()

func _height(x: float,z: float) -> float:
	# Only High Street climbs. The rest of the neighbourhood shares a useful
	# street datum, with stairs/banks/upper structures authored as real geometry.
	var hill_weight := 1.0-smoothstep(-24.0,-14.0,x)
	var y := 4.0+8.0*clampf((8.0-z)/64.0,0.0,1.0)*hill_weight
	for patch: Dictionary in TERRACE_PATCHES:
		var r: Rect2 = patch.rect
		var distance := Vector2(maxf(maxf(r.position.x-x,0.0),x-r.end.x),
			maxf(maxf(r.position.y-z,0.0),z-r.end.y)).length()
		y = lerpf(y,float(patch.y),1.0-smoothstep(0.0,float(patch.blend),distance))
	return y

func _ground(x: float,z: float) -> float:
	return Surface.grid_height(BOUNDS,SPACING,_height,x,z)

func _build_light() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("8e9eaa")
	sky_material.sky_horizon_color = Color("c4c8c4")
	sky_material.ground_horizon_color = Color("c4c8c4")
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_energy = 0.5
	environment.ambient_light_color = Color("d0dce2")
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48,-32,0)
	light.light_energy = 1.3
	light.shadow_enabled = true
	add_child(light)

func _box(id: String,at: Vector3,size: Vector3,material: Material,wall := false,layer := 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.position = at
	body.collision_layer = layer
	body.set_meta("surface_audio","stone")
	body.set_meta("wallrideable",wall)
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	body.add_child(mesh)
	return body

func _subtract_rectangle(source: Rect2,cut: Rect2) -> Array[Rect2]:
	var intersection := source.intersection(cut)
	if not intersection.has_area(): return [source]
	var result: Array[Rect2] = []
	for r: Rect2 in [Rect2(source.position,Vector2(source.size.x,intersection.position.y-source.position.y)),
		Rect2(Vector2(source.position.x,intersection.end.y),Vector2(source.size.x,source.end.y-intersection.end.y)),
		Rect2(Vector2(source.position.x,intersection.position.y),Vector2(intersection.position.x-source.position.x,intersection.size.y)),
		Rect2(Vector2(intersection.end.x,intersection.position.y),Vector2(source.end.x-intersection.end.x,intersection.size.y))]:
		if r.has_area(): result.append(r)
	return result

func _build_blocks() -> void:
	for mass: Dictionary in _layout.building_masses:
		var b: Array = mass.bounds_xz
		var r := Rect2(b[0],b[1],b[2]-b[0],b[3]-b[1])
		var piece := 0
		var pieces: Array[Rect2] = _subtract_rectangle(r,WAREHOUSE)
		var open_pieces: Array[Rect2] = []
		# The upper close crosses here at Y10; retain a real lower opening
		# rather than passing its slab through an unchanged solid block.
		for source: Rect2 in pieces:
			open_pieces.append_array(_subtract_rectangle(source,Rect2(-24,-40,54,6)))
		for footprint: Rect2 in open_pieces:
			var bottom := minf(_ground(footprint.position.x,footprint.position.y),_ground(footprint.end.x,footprint.end.y))-0.5
			var top := maxf(_ground(footprint.position.x,footprint.position.y),_ground(footprint.end.x,footprint.end.y))+8.0
			var center := footprint.get_center()
			_box(str(mass.id)+"_"+str(piece),Vector3(center.x,(top+bottom)*0.5,center.y),
				Vector3(footprint.size.x,top-bottom,footprint.size.y),_materials.sandstone,true)
			piece += 1
	# Two actual roof masses leave the short visible channel being jumped.
	for footprint: Rect2 in [Rect2(30,-52,22,30),Rect2(54,-52,22,30)]:
		var center := footprint.get_center()
		_box("DepotWarehouse",Vector3(center.x,7.0,center.y),
			Vector3(footprint.size.x,6.0,footprint.size.y),_materials.warehouse_brick,true)
		_roof_patches.append({"bounds":footprint,"height":10.0})
	_features.append({"id":"md_depot_roofs","kind":"roof_gap","gap_width":2.0,"height":10.0})

func _patch(id: String,r: Rect2,heights: Vector4,material: Material=null) -> StaticBody3D:
	return _terrain.add_patch(self,id,r,heights,_materials.paving if material==null else material)

func _rail(id: String,a: Vector3,b: Vector3) -> void:
	var direction := (b-a).normalized()
	var frame := Basis.looking_at(direction,Vector3.UP)
	var normal := frame.y
	var body := _box(id,(a+b)*0.5-normal*0.05,Vector3(0.10,0.10,a.distance_to(b)),_materials.slate,false,3)
	body.basis = frame
	var line := Grind.new(id,PackedVector3Array([a,b]),"rail")
	line.configure_contact(0.0,0.0,"merchant.native_box_crown")
	line.native_support_rids.append(body.get_rid())
	line.body_profile_radius = 0.05
	line.body_profile_source = "merchant.actual_box_half_height"
	_lines.append(line)
	for t: float in [0.1,0.9]:
		var top := a.lerp(b,t)-normal*0.10
		var ground := _ground(top.x,top.z)
		if top.y-ground>0.08:
			_box(id+"_Post",Vector3(top.x,(top.y+ground)*0.5,top.z),Vector3(0.07,top.y-ground,0.07),_materials.slate,false,3)
	_features.append({"id":id,"kind":"rail","points":PackedVector3Array([a,b]),"native_body":body.get_path()})

func _ledge(id: String,r: Rect2,y: float,height: float) -> void:
	_patch(id,r,Vector4.ONE*(y+height))
	for side: float in [r.position.x,r.end.x]:
		var line := Grind.new(id+"_"+str(side),PackedVector3Array([
			Vector3(side,y+height+0.02,r.position.y+0.3),Vector3(side,y+height+0.02,r.end.y-0.3)]),"ledge")
		# Generic until the finite native edge contract is independently exercised.
		_lines.append(line)
	_features.append({"id":id,"kind":"ledge","bounds":r,"height":y+height})

func _stairs(id: String,x: float,z: float,width: float,ground: float,rise: float,count: int,run: float) -> void:
	_patch(id+"_UpperLanding",Rect2(x,z-4,width,4),Vector4.ONE*(ground+rise))
	for step: int in count:
		var h := ground+rise*(1.0-float(step)/count)
		_patch(id+"_Step_"+str(step),Rect2(x,z+run*step/count,width,run/count),Vector4.ONE*h)
	_patch(id+"_Bypass",Rect2(x+width+1,z-4,4,run+4),
		Vector4(ground+rise,ground+rise,ground,ground))
	_rail(id+"_Handrail",Vector3(x+width*0.5,ground+rise+0.75,z-2),
		Vector3(x+width*0.5,ground+0.75,z+run+1.0))
	_features.append({"id":id,"kind":"stairs","count":count,"rise":rise,"run":run,
		"position":Vector3(x+width*.5,ground,z),"bypass_width":4.0})

func _quarter(id: String,at: Vector3,yaw: float) -> void:
	var quarter := Quarter.new()
	quarter.name = id
	quarter.feature_id = id
	quarter.radius = 2.2
	quarter.width = 8.0
	quarter.deck_length = 2.5
	quarter.position = at
	quarter.rotation.y = yaw
	add_child(quarter)
	_quarters.append(quarter)
	_index_support(quarter)

func _build_market() -> void:
	_ledge("Grind_MD_Civic_Island",Rect2(-7,13,8,12),4.0,0.45)
	_rail("Grind_MD_Market_East",Vector3(9,4.65,13),Vector3(9,4.65,25))
	_stairs("MD_Market_Steps",-20,4,5,4.0,0.8,4,4)
	_patch("MD_Market_Corner_Bank",Rect2(12,0,8,10),Vector4(5.2,4,4,5.2))
	_ledge("Grind_MD_Market_Seats",Rect2(-21,19,2,10),4.0,.45)
	_cone = _box("MerchantSignCone",Vector3(15,4.3,29),Vector3(.35,.6,.35),_materials.orange)
	_features.append({"id":"md_market_choices","kind":"plaza","bounds":Rect2(-30,-6,52,46),"floor_y":4.0})

func _build_upper_steps() -> void:
	_stairs("MD_High_Stair",-58,-48,6,10.0,2.0,10,8)
	_stairs("MD_Middle_Stair",-48,-27,6,7.0,2.0,10,8)
	_stairs("MD_Lower_Stair",-36,-7,6,4.0,1.5,6,6)
	_quarter("MD_High_Street_Return",Vector3(-66,_ground(-66,-57),-57),0.0)
	_rail("Grind_MD_Hill_Bypass_Upper",Vector3(-73,_ground(-73,-51)+.65,-51),Vector3(-73,_ground(-73,-37)+.65,-37))
	_rail("Grind_MD_Hill_Bypass_Lower",Vector3(-70,_ground(-70,-30)+.65,-30),Vector3(-70,_ground(-70,-16)+.65,-16))
	_box("MD_Middle_Retaining_Wall",Vector3(-31,8.5,-25),Vector3(.4,3.0,12),_materials.sandstone,true)
	# Upper close has a real slab, rather than an arrow through a building.
	_upper_terrain.add_patch(self,"MD_Upper_Close",Rect2(-24,-40,54,6),Vector4.ONE*10.0,_materials.paving,"stone",.5)
	_rail("Grind_MD_Upper_Close_A",Vector3(-19,10.65,-37),Vector3(-5,10.65,-37))
	_rail("Grind_MD_Upper_Close_B",Vector3(1,10.65,-37),Vector3(15,10.65,-37))
	_rail("Grind_MD_Roof_West",Vector3(36,10.65,-37),Vector3(49,10.65,-37))
	_rail("Grind_MD_Roof_East",Vector3(57,10.65,-37),Vector3(70,10.65,-37))

func _build_loading() -> void:
	_patch("MD_Loading_Dock",Rect2(30,-22,46,6),Vector4.ONE*6.0)
	_stairs("MD_Loading_Stairs",36,-16,6,4.0,2.0,10,6)
	_ledge("Grind_MD_Dock_Edge",Rect2(55,-19,14,2),6.0,.35)
	# Actual bridge: the floor is 4 m, underside 8.5 m, deck 9 m.
	_upper_terrain.add_patch(self,"MD_Depot_Bridge",Rect2(28,-12,48,12),Vector4.ONE*9.0,_materials.paving,"stone",.5)
	for x: float in [30,52,74]:
		for z: float in [-13.2,1.2]:
			_box("MD_Brick_Bridge_Pier",Vector3(x,6.25,z),Vector3(2.0,4.5,2.0),_materials.warehouse_brick,true)
	_upper_terrain.add_patch(self,"MD_Roof_To_Bridge",Rect2(62,-22,8,10),Vector4(10,10,9,9),_materials.paving,"stone",.5)
	_rail("Grind_MD_Bridge_Upper",Vector3(36,9.65,-5),Vector3(49,9.65,-5))
	_rail("Grind_MD_Underpass",Vector3(47,4.65,-5),Vector3(61,4.65,-5))
	# Deliberate dock-to-ground kicker and street return outside the stair lane.
	_patch("MD_Dock_Kicker",Rect2(69,-13,5,6),Vector4(5.2,5.2,4,4))
	_rail("Grind_MD_Depot_Exit",Vector3(78,4.65,4),Vector3(78,4.65,16))
	_features.append({"id":"md_underpass","kind":"underpass","bounds":Rect2(28,-12,48,12),
		"floor_y":4.0,"underside_y":8.5,"minimum_clearance":4.5,"grounded_route":true})

func _build_street_choices() -> void:
	_rail("Grind_MD_West_Corner",Vector3(-54,4.65,22),Vector3(-42,4.65,30))
	_rail("Grind_MD_Foundry_Street",Vector3(84,4.65,25),Vector3(84,4.65,39))
	_ledge("Grind_MD_Lower_Arcade",Rect2(36,65,14,2),4,.45)
	_box("MD_Lower_Arcade_Wall",Vector3(43,5.5,68),Vector3(18,3,.4),_materials.warehouse_brick,true)
	_patch("MD_Lower_Corner_Bank",Rect2(18,48,8,8),Vector4(4,5.4,5.4,4))
	_features.append({"id":"md_arcade_wall","kind":"wallride","position":Vector3(43,5.5,68),"length":18.0,"height":3.0})

func _panel(id: String,faces: PackedVector3Array,material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.set_meta("surface_audio","stone")
	body.set_meta("wallrideable",false)
	add_child(body)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex: Vector3 in faces:
		surface.set_uv(Vector2(vertex.x,vertex.z)*.2)
		surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = material
	body.add_child(mesh)
	return body

func _index_support(node: Node) -> void:
	if node is StaticBody3D and (node.collision_layer&1)!=0 and (node.collision_layer&2)==0:
		for child: Node in node.get_children():
			if not child is MeshInstance3D or child.mesh==null: continue
			var faces: PackedVector3Array = child.mesh.get_faces()
			for i: int in range(0,faces.size(),3):
				var triangle := PackedVector3Array([child.to_global(faces[i]),child.to_global(faces[i+1]),child.to_global(faces[i+2])])
				if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).y>=-0.00000001: continue
				var index := _support_triangles.size()
				_support_triangles.append(triangle)
				var minimum := Vector2(INF,INF)
				var maximum := Vector2(-INF,-INF)
				for p: Vector3 in triangle:
					minimum=minimum.min(Vector2(p.x,p.z))
					maximum=maximum.max(Vector2(p.x,p.z))
				for x: int in range(floori(minimum.x),floori(maximum.x)+1):
					for z: int in range(floori(minimum.y),floori(maximum.y)+1):
						var cell := Vector2i(x,z)
						if not _support_cells.has(cell):_support_cells[cell]=[]
						_support_cells[cell].append(index)
	for child: Node in node.get_children(): _index_support(child)

func _component_height(at: Vector3,limit: float) -> float:
	var highest := NAN
	for index: int in _support_cells.get(Vector2i(floori(at.x),floori(at.z)),[]):
		var t: PackedVector3Array = _support_triangles[index]
		var a := Vector2(t[0].x,t[0].z)
		var ab := Vector2(t[1].x,t[1].z)-a
		var ac := Vector2(t[2].x,t[2].z)-a
		var determinant := ab.cross(ac)
		if absf(determinant)<0.000000001:continue
		var p := Vector2(at.x,at.z)-a
		var u := p.cross(ac)/determinant
		var v := ab.cross(p)/determinant
		if u< -0.00001 or v< -0.00001 or u+v>1.00001:continue
		var y := t[0].y*(1-u-v)+t[1].y*u+t[2].y*v
		if y<=limit and (not is_finite(highest) or y>highest): highest=y
	return highest

func _build_basin() -> void:
	# Individual transition parts form a new street court. No old facility loads.
	var holes: Array[PackedVector2Array] = []
	for spec: Dictionary in [
		{"id":"md_foundry_deep","at":Vector3(44,1,41),"radius":3.0,"floor":3.0,"access":1.5,"end":11.0,"port":9},
		{"id":"md_foundry_shallow","at":Vector3(65,2.5,40),"radius":1.5,"floor":3.0,"access":0.0,"end":11.0,"port":10}]:
		var bowl := Bowl.new()
		bowl.name = str(spec.id)
		bowl.feature_id = str(spec.id)
		bowl.position = spec.at
		bowl.rotation.y = PI
		bowl.radius = spec.radius
		bowl.floor_radius = spec.floor
		bowl.deck_length = 1.2
		bowl.port_half_segments = spec.port
		bowl.port_cut_theta = deg_to_rad(40) if float(spec.radius)>2 else 0.0
		bowl.access_height = spec.access
		bowl.channel_end_z = spec.end
		add_child(bowl)
		_court_features.append(bowl)
		holes.append_array(bowl.get_deck_voids())
		_index_support(bowl)
	var deck_faces := PackedVector3Array()
	# One-metre polygon clipping uses actual transformed component voids;
	# native and display share every resulting triangle, including curved mouths.
	for x: int in range(30,78):
		for z: int in range(30,60):
			var pieces: Array[PackedVector2Array] = [PackedVector2Array([Vector2(x,z),Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)])]
			for hole: PackedVector2Array in holes:
				var remaining: Array[PackedVector2Array] = []
				for piece: PackedVector2Array in pieces:remaining.append_array(Geometry2D.clip_polygons(piece,hole))
				pieces=remaining
			for piece: PackedVector2Array in pieces:
				var indices := Geometry2D.triangulate_polygon(piece)
				for i: int in range(0,indices.size(),3):
					var a := Vector3(piece[indices[i]].x,4,piece[indices[i]].y)
					var b := Vector3(piece[indices[i+1]].x,4,piece[indices[i+1]].y)
					var c := Vector3(piece[indices[i+2]].x,4,piece[indices[i+2]].y)
					if (b-a).cross(c-a).y>0:
						var swap:=b
						b=c
						c=swap
					deck_faces.append_array(PackedVector3Array([a,b,c]))
	var deck := _panel("MD_Foundry_Excavated_Deck",deck_faces,_materials.skate_concrete)
	_index_support(deck)
	_patch("MD_Foundry_Lower_Street",Rect2(30,24,48,6),Vector4.ONE*2.5)
	_patch("MD_Foundry_North_West_Deck",Rect2(30,20,18,4),Vector4.ONE*4.0)
	_patch("MD_Foundry_North_East_Deck",Rect2(58,20,20,4),Vector4.ONE*4.0)
	_patch("MD_Foundry_North_Bank",PORT_BANK,Vector4(4,4,2.5,2.5))
	_patch("MD_Foundry_West_Bank",WEST_ENTRY,Vector4(4,2.5,2.5,4))
	for interval: Vector2 in [Vector2(30,48),Vector2(58,78)]:
		_box("MD_Foundry_North_Retaining",Vector3((interval.x+interval.y)*.5,3.25,23.925),
			Vector3(interval.y-interval.x,1.5,.15),_materials.warehouse_brick,true)
	_rail("Grind_MD_Foundry_Lower",Vector3(47,3.15,27),Vector3(58,3.15,27))
	_ledge("Grind_MD_Foundry_Street_Deck",Rect2(31,50,2,8),4,.45)
	var hip := Spine.new()
	hip.name = "MD_Foundry_Hip"
	hip.feature_id = "md_foundry_hip"
	hip.radius = 1.5
	hip.width = 7.0
	hip.cap_width = .6
	hip.position = Vector3(57,4,54)
	hip.rotation.y = PI*.5
	add_child(hip)
	_court_features.append(hip)
	_index_support(hip)
	_features.append({"id":"md_foundry_court","kind":"custom_transition_court","bounds":BASIN_BOUNDS,
		"rim_y":4.0,"entry_street_y":2.5,"old_facility_instantiated":false,"openings":2})

func _build_routes() -> void:
	for road: Dictionary in _layout.street_corridors:
		var points := PackedVector3Array()
		for p: Array in road.points:
			points.append(Vector3(p[0],_ground(p[0],p[2]),p[2]))
		_routes.append({"id":"md_"+str(road.id),"label":str(road.label) if road.has("label") else str(road.id).replace("_"," "),
			"points":points,"requires_jump":false,"design_guide_only":true})
	_routes.append({"id":"md_foundry_north","label":"Foundry north bank","requires_jump":false,
		"points":PackedVector3Array([Vector3(53,4,14),Vector3(53,2.5,24),Vector3(53,2.5,27)])})
	_routes.append({"id":"md_foundry_west","label":"Foundry west bank","requires_jump":false,
		"points":PackedVector3Array([Vector3(20,4,27),Vector3(30,2.5,27),Vector3(38,2.5,27)])})

func get_level_manifest() -> Dictionary:
	return {"schema_version":1,"id":Catalog.DEFAULT_LEVEL,"label":"Merchant District",
		"career":Catalog.career(Catalog.DEFAULT_LEVEL),"interaction_ids":{"cone":"md_cone"},
		"status":"private_native_graybox","bounds":BOUNDS}

func get_activity_layout() -> Dictionary:
	return {}

func get_spawn_position() -> Vector3:
	return Vector3(-14,4.8,31)

func get_transition_features() -> Array:
	return [] # Quarter/bowl actors publish the existing skate_transitions group.

func get_npc_positions() -> Array[Vector3]:
	return []

func get_encounter_definitions() -> Array[Dictionary]:
	return []

func activate_cone() -> void:
	cone_activated = true
	if is_instance_valid(_cone): _cone.rotation.z = -0.8

func reset_interactions() -> void:
	cone_activated = false
	if is_instance_valid(_cone): _cone.rotation = Vector3.ZERO

func get_district_id(at: Vector3) -> String:
	if BASIN_BOUNDS.grow(6).has_point(Vector2(at.x,at.z)): return "md_foundry_basin"
	if at.x>24 and at.z<4: return "md_warehouse_row"
	if at.z< -30: return "md_upper_steps"
	return "md_market_cross"

func get_district_checkpoints() -> Dictionary:
	return {"md_upper_steps":Vector3(-54,10,-39),"md_market_cross":Vector3(-14,4,31),
		"md_warehouse_row":Vector3(48,4,-6),"md_foundry_basin":Vector3(53,2.5,27)}

func get_gap_definitions() -> Array[Dictionary]:
	return [{"id":"md_roof_channel","name":"Across the roofs","start":Vector3(51,10.4,-37),
		"end":Vector3(55,10.4,-37),"radius":1.0,"points":500,"airborne_required":true}]

func get_gap_grind_destinations() -> Dictionary:
	return {}

func get_location_name(at: Vector3) -> String:
	return str(get_district_id(at)).trim_prefix("md_").replace("_"," ").to_upper()

func get_ground_height(at: Vector3) -> float:
	# Terrain semantics exclude an overhead roof; support queries admit that
	# separately only when it is beneath the caller's finite height limit.
	return _surface_height(Vector3(at.x,1000,at.z),INF,false)

func get_support_height(at: Vector3,max_step_up: float=1.0) -> float:
	return _surface_height(at,max_step_up,true)

func _surface_height(at: Vector3,max_step_up: float,include_roofs: bool) -> float:
	if not at.is_finite() or not BOUNDS.has_point(Vector2(at.x,at.z)): return NAN
	var limit := at.y+max_step_up
	var y := NAN
	if not BASIN_BOUNDS.has_point(Vector2(at.x,at.z)) and not PORT_BANK.has_point(Vector2(at.x,at.z)) and not WEST_ENTRY.has_point(Vector2(at.x,at.z)):
		var h := _ground(at.x,at.z)
		if h<=limit: y=h
	var component_y := _component_height(at,limit)
	if is_finite(component_y) and (not is_finite(y) or component_y>y): y=component_y
	var patch_y: float = _terrain.height_at(at.x,at.z,limit)
	if is_finite(patch_y) and (not is_finite(y) or patch_y>y): y=patch_y
	if include_roofs:
		var upper_y: float = _upper_terrain.height_at(at.x,at.z,limit)
		if is_finite(upper_y) and (not is_finite(y) or upper_y>y): y=upper_y
		for roof: Dictionary in _roof_patches:
			if roof.bounds.has_point(Vector2(at.x,at.z)) and float(roof.height)<=limit:
				if not is_finite(y) or float(roof.height)>y: y=float(roof.height)
	return y

func get_recovery_position(at: Vector3) -> Vector3:
	if at.is_finite() and BOUNDS.grow(3).has_point(Vector2(at.x,at.z)) and at.y> -12: return Vector3(INF,INF,INF)
	return get_spawn_position()

func get_recovery_message(_at: Vector3) -> String:
	return "BACK IN THE DISTRICT"

func get_route_definitions() -> Array[Dictionary]:
	return _routes.duplicate(true)

func get_goal_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	var letters := [Vector3(-19,5.2,21),Vector3(-54,11.5,-45),Vector3(40,7,-18),Vector3(53,3.5,27),Vector3(43,5,65)]
	var labels := ["H","A","W","K","S"]
	for i: int in labels.size():
		markers.append({"id":"md_letter_"+str(labels[i]).to_lower(),"label":labels[i],"kind":"letter","position":letters[i],"radius":1.8})
	for i: int in 3:
		markers.append({"id":"md_market_"+str(i+1),"kind":"market_item","position":Vector3(32+i*8,5,-6),"radius":1.8})
	markers.append({"id":"md_cone","kind":"interaction","position":Vector3(15,4.8,29),"radius":2.0})
	markers.append({"id":"md_secret_recording","kind":"collectible","position":Vector3(70,11,-40),"radius":1.8})
	for id: String in get_district_checkpoints():
		markers.append({"id":id,"kind":"district","position":get_district_checkpoints()[id],"radius":3.5})
	return markers

func get_grind_lines() -> Array:
	var lines := _lines.duplicate()
	for quarter: Node3D in _quarters: lines.append_array(quarter.get_grind_lines())
	for feature: Node3D in _court_features: lines.append_array(feature.get_grind_lines())
	return lines

func get_surface_audit() -> Dictionary:
	return {"status":"unmeasured_private_graybox","static_geometry_only":true,"no_legacy_world_instantiated":true}

func get_park_skatepark_definition() -> Dictionary:
	return {"id":"md_foundry_court","position":Vector3(54,4,40),"bounds":BASIN_BOUNDS,
		"floor_y":2.5,"rim_y":4.0,"entry":Vector3(30,2.5,27),"north_entry":Vector3(53,2.5,24)}

func get_skate_feature_definitions() -> Array[Dictionary]:
	var features := _features.duplicate(true)
	for feature: Node3D in _court_features: features.append_array(feature.get_feature_definitions())
	for quarter: Node3D in _quarters: features.append_array(quarter.get_feature_definitions())
	return features

func get_level_density_audit() -> Dictionary:
	return {"status":"design_targets_unmeasured","loop_targets":3,"native_completed_loops":0,
		"preferred_choice_interval_m":Vector2(12,16),"private_geometry":true}
