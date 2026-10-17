extends Node3D
## Compressed original Glasgow skating routes. One unit is approximately one metre.
## Keep geometry and collision together; skating physics belongs to the player.

const SPAWN := Vector3(-22.0, 0.8, 28.0)
const FLOOR_SIZE := Vector3(70.0, 0.5, 84.0)
const GrindLineSource = preload("res://game/tricks/grind_line.gd")
const CityArtSource = preload("res://game/levels/city_art.gd")
const TerrainSource = preload("res://game/levels/core_terrain.gd")
const RAIL_COLLISION_LAYER := 2
const RAIL_TOP_HEIGHT := 0.92
const PALETTE := {
	"stone": Color("a89d87"),
	"stone_light": Color("c1b8a4"),
	"sandstone": Color("927563"),
	"slate": Color("3b444b"),
	"teal": Color("315e60"),
	"coral": Color("a45d44"),
	"cream": Color("ddd5bf"),
	"paving": Color("777b7b"),
	"path": Color("979b98"),
	"glass": Color("213747"),
	"bronze": Color("42615a"),
	"orange": Color("cb752f"),
	"asphalt": Color("303b40"),
}

var _materials: Dictionary = {}
var _rail_authors: Array[Node3D] = []
var _city_art: Node3D
var _cone: Node3D
var _cone_tween: Tween
var cone_activated := false
var _terrain = TerrainSource.new()
var _outdoors: Node3D


func _ready() -> void:
	name = "GlasgowSquare"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_city_art = CityArtSource.new()
	_city_art.name = "CityArt"
	add_child(_city_art)
	_make_materials()
	_build_lighting()
	_build_floor()
	_build_skating_lines()
	_build_statue()
	_build_district_connections()
	_build_merchant_close()
	_build_george_square()
	_build_central_station()
	_build_barras()
	_build_city()
	_build_street_furniture()
	if ResourceLoader.exists("res://game/levels/outdoor_routes.gd"):
		_outdoors = load("res://game/levels/outdoor_routes.gd").new()
		_outdoors.name = "OutdoorRoutes"
		add_child(_outdoors)
		_outdoors.build(self, _materials)
	_city_art.dress_world(self)


func get_spawn_position() -> Vector3:
	return SPAWN


func get_npc_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for at: Vector3 in _city_art.npc_positions:
		positions.append(to_global(at))
	return positions


func get_encounter_definitions() -> Array[Dictionary]:
	return [
		{"id": "busker_big_finish", "position": to_global(Vector3(28,0,31)), "heading": 0.93},
		{"id": "cat_got_the_beat", "position": to_global(Vector3(0,4.65,-98)), "heading": PI,
			"sequence": ["Grind_Cat_A", "Grind_Cat_B", "Grind_Cat_C"],
			"area_center": to_global(Vector3(0,4,-91)), "area_radius": 32.0},
	]


func activate_cone() -> void:
	if cone_activated:
		return
	cone_activated = true
	_cone_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cone_tween.tween_property(_cone, "position:y", 7.65, 0.24)
	_cone_tween.parallel().tween_property(_cone, "rotation:z", -0.45, 0.24)
	_cone_tween.tween_property(_cone, "position:y", 6.86, 0.35).set_trans(Tween.TRANS_BOUNCE)
	_cone_tween.parallel().tween_property(_cone, "rotation:z", 0.18, 0.35)


func reset_interactions() -> void:
	if _cone_tween and _cone_tween.is_valid():
		_cone_tween.kill()
	cone_activated = false
	if is_instance_valid(_cone):
		_cone.position = Vector3(0.0, 6.86, 0.0)
		_cone.rotation = Vector3.ZERO


func get_district_id(world_position: Vector3) -> String:
	if is_instance_valid(_outdoors):
		var outdoor_id: String = _outdoors.get_district_id(world_position)
		if not outdoor_id.is_empty():
			return outdoor_id
	var at := to_local(world_position)
	if at.x < -42.0:
		return "central_station"
	if at.x > 42.0:
		return "barras"
	if at.z < -48.0:
		return "george_square"
	return "royal_exchange"


func get_district_checkpoints() -> Dictionary:
	var checkpoints := {
		"royal_exchange": to_global(SPAWN),
		"george_square": to_global(Vector3(-22.0, 4.8, -74.0)),
		"central_station": to_global(Vector3(-62.0, 2.8, 22.0)),
		"barras": to_global(Vector3(60.0, 0.8, 22.0)),
	}
	if is_instance_valid(_outdoors):
		checkpoints.merge(_outdoors.get_checkpoints())
	return checkpoints


func get_gap_definitions() -> Array[Dictionary]:
	var gaps: Array[Dictionary] = [
		{"id": "exchange_launch", "name": "Gallery Steps", "start": Vector3(0, 2.4, -13), "end": Vector3(0, 0.8, -5), "radius": 2.2, "points": 300, "airborne_required": true},
		{"id": "central_gap", "name": "Mind The Gap", "start": Vector3(-94, 5.4, 0), "end": Vector3(-94, 5.4, -6), "radius": 2.0, "points": 600, "airborne_required": true},
		{"id": "market_hop", "name": "Market Loading Steps", "start": Vector3(93, 1.9, -15), "end": Vector3(93, 0.8, -7), "radius": 2.0, "points": 350, "airborne_required": true},
	]
	for gap: Dictionary in gaps:
		gap.start = to_global(gap.start)
		gap.end = to_global(gap.end)
	if is_instance_valid(_outdoors):
		gaps.append_array(_outdoors.get_gap_definitions())
	return gaps


func get_location_name(world_position: Vector3) -> String:
	var at := to_local(world_position)
	if at.x > -83 and at.x < -49 and at.z <= -30 and at.z > -85:
		return "MERCHANT CLOSE / SERVICE COURT" if at.y < 1.9 else "MERCHANT CLOSE / PRINT WORKS"
	if at.x >= -123 and at.x <= -86 and at.z >= -20 and at.z <= 4 and at.y < 4.4:
		return "CENTRAL STATION / LOW LEVEL CLOSE"
	if is_instance_valid(_outdoors) and not _outdoors.get_district_id(world_position).is_empty():
		return _outdoors.get_location_name(world_position)
	match get_district_id(world_position):
		"george_square": return "GEORGE SQUARE / CIVIC TERRACES"
		"central_station":
			return "CENTRAL STATION / HIGH LINE" if at.y >= 4.4 else "CENTRAL STATION / CONCOURSE"
		"barras": return "THE BARRAS / MARKET LANES"
	if world_position.z < -18.0:
		return "EXCHANGE GALLERY TERRACE"
	return "ROYAL EXCHANGE / FOUNTAIN COURT"


func _make_materials() -> void:
	_materials = _city_art.make_materials(PALETTE)


func _build_lighting() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("8e9eaa")
	sky_material.sky_horizon_color = Color("c4c8c4")
	sky_material.ground_bottom_color = Color("727b7c")
	sky_material.ground_horizon_color = Color("c4c8c4")
	sky_material.sun_angle_max = 5.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c7dfeb")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_density = 0.0015
	environment.fog_light_color = Color("b4bec3")
	environment.fog_sky_affect = 0.15
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "LateAfternoonSun"
	sun.rotation_degrees = Vector3(-42.0, -32.0, 0.0)
	sun.light_color = Color("ffe8d1")
	sun.light_energy = 0.85
	sun.shadow_opacity = 0.65
	# One short-range shadow source; no dynamic local lights or post-processing.
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 75.0
	add_child(sun)


func _build_floor() -> void:
	_flat("ExchangeLowerCourt", Rect2(-35, -18, 70, 60), 0.0, "paving")
	_flat("GalleryTerrace", Rect2(-35, -42, 70, 24), 2.0, "path")
	_slope("GalleryWestApproach", Rect2(-35, -18, 24, 14), Vector4(2, 2, 0, 0), "paving")
	_slope("GalleryEastApproach", Rect2(11, -18, 24, 14), Vector4(2, 2, 0, 0), "paving")
	_steps("GallerySteps", -9, 9, -4, -12, 0, 2, 8)
	_flat("GalleryStepLanding", Rect2(-11, -18, 22, 6), 2.0, "path")
	# The low retaining cheeks are architecture beside, never across, the banks.
	for x: float in [-10.0, 10.0]:
		_box(self, "GalleryStairCheek", Vector3(x, 0.9, -9), Vector3(1.0, 1.8, 10), "stone", true)
	# Furniture and normal urban edges define the court; no runway markings.
	_fountain(Vector3(0, 0, 10), 6.2)


func _build_skating_lines() -> void:
	# Low public-space handrails and ledges give the fountain loop optional links.
	_rail("Grind_Rail_Exchange", Vector3(12, 0, 9), 7.5)
	_rail("Grind_Rail_Tenement", Vector3(-29, 2, -27), 10)
	_grind_path("Grind_Rail_GallerySteps", PackedVector3Array([
		Vector3(9.4, 0.92, -3), Vector3(9.4, 2.92, -13), Vector3(9.4, 2.92, -17)]), "rail")
	for at: Vector3 in [Vector3(-15, 0, 13), Vector3(17, 0, 13)]:
		_box(self, "CourtPlanterSeat", at + Vector3(0, 0.24, 0), Vector3(1.15, 0.48, 8), "stone", true)
		_box(self, "CourtPlanterCap", at + Vector3(0, 0.51, 0), Vector3(1.25, 0.06, 8.1), "cut_stone")
	_grind_path("Grind_Ledge_Court", PackedVector3Array([Vector3(-15.6, 0.55, 17), Vector3(-15.6, 0.55, 9)]), "ledge")


func _ramp(ramp_name: String, at: Vector3, width: float, run: float, rise: float, yaw: float) -> void:
	# Retained helper for small authored banks; material is the adjacent masonry.
	var start := at + Basis(Vector3.UP, yaw) * Vector3(0, 0, run / 2.0)
	var end := at + Basis(Vector3.UP, yaw) * Vector3(0, rise, -run / 2.0)
	_street(ramp_name, start, end, width, "paving")


func _rail(rail_id: String, at: Vector3, length: float) -> void:
	var rail := Node3D.new()
	rail.name = rail_id
	rail.position = at
	rail.add_to_group("grind_rails")
	rail.set_meta("grind_id", rail_id)
	# First point is the south approach; increasing distance travels north (-Z).
	rail.set_meta("grind_points", PackedVector3Array([
		Vector3(0.0, RAIL_TOP_HEIGHT, length / 2.0),
		Vector3(0.0, RAIL_TOP_HEIGHT, -length / 2.0),
	]))
	add_child(rail)
	_rail_authors.append(rail)
	var bar := _box(rail, "RailProp", Vector3(0.0, RAIL_TOP_HEIGHT - 0.07, 0.0), Vector3(0.14, 0.14, length), "coral", true) as StaticBody3D
	bar.collision_layer = RAIL_COLLISION_LAYER
	bar.collision_mask = 0
	for z: float in [-length / 2.0 + 0.4, length / 2.0 - 0.4]:
		var post := _box(rail, "RailPost", Vector3(0.0, 0.42, z), Vector3(0.12, 0.84, 0.12), "slate", true) as StaticBody3D
		# Thin supports cannot catch a rider entering/leaving the authored line.
		# Ordinary world solids stay on layer1 for clearance and collision checks.
		post.collision_layer = RAIL_COLLISION_LAYER
		post.collision_mask = 0


func _build_statue() -> void:
	var statue := Node3D.new()
	statue.name = "ProvostOfPush"
	statue.position = Vector3(18.0, 2.0, -27.0)
	add_child(statue)
	_box(statue, "PlinthFoot", Vector3(0.0, 0.25, 0.0), Vector3(5.0, 0.5, 5.0), "stone_light", true)
	_box(statue, "Plinth", Vector3(0.0, 1.85, 0.0), Vector3(3.4, 2.7, 3.4), "stone", true)
	_box(statue, "PlinthCrown", Vector3(0.0, 3.3, 0.0), Vector3(3.9, 0.3, 3.9), "stone_light", true)
	_box(statue, "Plaque", Vector3(0.0, 1.9, 1.715), Vector3(2.4, 1.3, 0.04), "slate")
	_label(statue, "PlaqueText", "THE PROVOST\nOF PUSH\nEST. WHENEVER", Vector3(0.0, 1.95, 1.75), 30, "cream", Vector3.ZERO, 0.012)
	# An original standing civic skater, deliberately not a replica of a real statue.
	_box(statue, "BronzeBoard", Vector3(0.0, 3.58, 0.0), Vector3(2.6, 0.2, 0.75), "bronze")
	for x: float in [-0.48, 0.48]:
		var leg := _box(statue, "BronzeLeg", Vector3(x, 4.3, 0.0), Vector3(0.34, 1.4, 0.4), "bronze")
		leg.rotation.z = x * 0.2
	_box(statue, "BronzeCoat", Vector3(0.0, 5.35, 0.0), Vector3(1.25, 1.5, 0.65), "bronze")
	var arm := _box(statue, "PointingArm", Vector3(-0.95, 5.9, 0.0), Vector3(1.2, 0.3, 0.34), "bronze")
	arm.rotation.z = -0.28
	_box(statue, "OtherArm", Vector3(0.8, 5.3, 0.0), Vector3(0.3, 1.3, 0.34), "bronze")
	_cylinder(statue, "StatueHead", Vector3(0.0, 6.45, 0.0), 0.43, 0.43, 0.7, "bronze")
	_cone = Node3D.new()
	_cone.name = "InteractiveCone"
	_cone.position = Vector3(0.0, 6.86, 0.0)
	statue.add_child(_cone)
	_box(_cone, "ConeFoot", Vector3.ZERO, Vector3(1.1, 0.12, 1.1), "orange")
	_cylinder(_cone, "TrafficCone", Vector3(0.0, 0.56, 0.0), 0.0, 0.5, 1.05, "orange")
	_cylinder(_cone, "ConeReflector", Vector3(0.0, 0.48, 0.0), 0.22, 0.34, 0.24, "cream")


func _build_city() -> void:
	_building(Vector3(0, 2, -48), 18, 19, "sandstone", "EXCHANGE GALLERY", 0)
	for x: float in [-32.0, 32.0]:
		_building(Vector3(x, 2, -48), 10, 17, "stone", "THE WEE PIE CO.", 0)
	for z: float in [-33.0, 0.0, 35.0]:
		var height := 2.0 if z < -18.0 else 0.0
		var width := 30.0 if z == 0.0 else 10.0
		_building(Vector3(-41, height, z), width, 16, "stone", "TENEMENT WORKS", PI / 2.0)
		_building(Vector3(41, height, z), width, 18, "sandstone", "CLOSE COFFEE", -PI / 2.0)
	# South retail edge has two shallow closes, rather than a sealed sandbox wall.
	for x: float in [-24.0, 0.0, 24.0]:
		_building(Vector3(x, 0, 48), 18, 15, "stone_light", "EXCHANGE ARCADE", PI)
	_building(Vector3(0, 6, -134), 62, 19, "stone_light", "CIVIC CHAMBERS", 0)
	for side: float in [-1.0, 1.0]:
		# Two frontage blocks frame the Z=-80 cross street instead of sealing it.
		_building(Vector3(side * 42, 4, -99), 20, 17, "sandstone", "CIVIC CLOSE", -side * PI / 2.0)
		_building(Vector3(side * 42, 4, -63.5), 14, 16, "sandstone", "CIVIC CLOSE", -side * PI / 2.0)
	# Western station facade is split to leave the Kelvingrove route open.
	for z: float in [-26.0, 26.0]:
		_building(Vector3(-136, 2, z), 30, 17, "stone", "STATION APPROACH", PI / 2.0)
	_building(Vector3(108, 1.5, -48), 32, 12, "sandstone", "BARROWLANDS / MARKET QUARTER", 0)
	_building(Vector3(65, 1.5, -48), 28, 13, "stone", "THE MARKET HALL", 0)


func _build_district_connections() -> void:
	for x: float in [-22.0, 22.0]:
		_street("GeorgeGradedStreet", Vector3(x, 2, -42), Vector3(x, 4, -56), 14)
	_street("CentralSouthStreet", Vector3(-35, 0, 22), Vector3(-50, 2, 22), 14)
	_street("CentralNorthStreet", Vector3(-35, 2, -22), Vector3(-50, 2, -22), 14)
	_street("BarrasSouthStreet", Vector3(35, 0, 22), Vector3(50, 0, 22), 14)
	_street("BarrasNorthStreet", Vector3(35, 2, -22), Vector3(50, 1.5, -22), 14)
	for x: float in [-88.0, 88.0]:
		var start_height := 2.0 if x < 0 else 1.5
		_street("NorthClimbingLane", Vector3(x, start_height, -42), Vector3(x, 4, -74), 12)
		_street("CivicBackStreet", Vector3(x, 4, -80), Vector3(signf(x) * 35, 4, -80), 12)
		_flat("BackStreetCorner", Rect2(x - 6, -86, 12, 12), 4, "asphalt")
	_street("KelvingroveWestPort", Vector3(-130, 2, 0), Vector3(-145, 2, 0), 16)
	_street("KelvingroveCivicPort", Vector3(-35, 6, -122), Vector3(-42, 6, -122), 12)


func _build_merchant_close() -> void:
	# Lower service ground makes the retained close part of a city block, rather
	# than a road ribbon suspended over the sky. Both sides have supported exits.
	_flat("MerchantServiceCourt", Rect2(-94,-86,60,56), 1.0, "paving")
	_slope("MerchantCourtEastReturn", Rect2(-61,-54,4,12), Vector4(1,1,2,2), "paving")
	_slope("MerchantCourtWestReturn", Rect2(-82,-72,8,4), Vector4(3.875,1,1,3.625), "paving")
	# Original dogleg through a close between the station and civic district.
	# Its angled footprint occupies previously unsupported negative space.
	var points := PackedVector3Array([Vector3(-64,2,-30), Vector3(-68,2,-44), Vector3(-69,2.5,-50), Vector3(-61,3.2,-60), Vector3(-55,3.5,-65), Vector3(-59,4,-74), Vector3(-59,4,-80)])
	_retained_path("MerchantClose", points, 8.0, "asphalt")
	_terrain.add_polygon(self, "MerchantClosePocket", PackedVector3Array([Vector3(-70,3.2,-58), Vector3(-74,3.2,-69), Vector3(-60,3.2,-65)]), _materials["path"])
	var print_works := _building(Vector3(-77.5,2.5,-55), 18, 14, "stone", "THE CLOSE / PRINT WORKS", PI / 2.0)
	print_works.scale.z = 0.7
	_box(print_works, "CloseRetainingFoundation", Vector3(0,-2.75,0), Vector3(18,5.5,12), "stone", true)
	var close_frontage := _building(Vector3(-44,2.7,-45), 16, 17, "sandstone", "MERCHANT CLOSE", -0.32)
	_box(close_frontage, "CloseRetainingFoundation", Vector3(0,-2.85,0), Vector3(16,5.7,12), "sandstone", true)
	_box(self, "ClosePocketPlanter", Vector3(-71,3.45,-66), Vector3(1.0,0.5,3.8), "stone", true)
	_grind_path("Grind_Ledge_MerchantClose", PackedVector3Array([Vector3(-67.8,3.65,-61.3), Vector3(-61.8,3.95,-66.3)]), "ledge")
	_label(self, "MerchantCloseWayfinding", "MERCHANT CLOSE / CIVIC SQUARE", Vector3(-65,4.9,-42), 26, "cream", Vector3(0, 20, 0), 0.012)


func _retained_path(id: String, points: PackedVector3Array, width: float, material: String) -> void:
	var edges: Array[Vector3] = []
	for index in points.size():
		var direction := points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]
		edges.append(Vector3(direction.z, 0, -direction.x).normalized() * width * 0.5)
	for index in range(points.size() - 1):
		_terrain.add_polygon(self, id + str(index), PackedVector3Array([
			points[index] - edges[index], points[index] + edges[index],
			points[index + 1] + edges[index + 1], points[index + 1] - edges[index + 1]]),
			_materials[material], "asphalt" if material == "asphalt" else "stone")


func _build_george_square() -> void:
	_flat("GeorgeSquareFloor", Rect2(-35, -128, 70, 72), 4, "path")
	_flat("CivicForecourt", Rect2(-35, -128, 70, 20), 6, "path")
	_slope("CivicWestBank", Rect2(-35, -108, 18, 12), Vector4(6, 6, 4, 4), "paving")
	_slope("CivicEastBank", Rect2(17, -108, 18, 12), Vector4(6, 6, 4, 4), "paving")
	_steps("CivicStairs", -13, 13, -102, -108, 4, 6, 10)
	_build_civic_workshop()
	for side: float in [-1.0, 1.0]:
		var wing := PackedVector3Array()
		for at: Vector2 in [Vector2(18,-87),Vector2(11,-88.5),Vector2(7,-84.5),Vector2(10,-80),Vector2(17,-81)]:
			wing.append(Vector3(at.x * side,4.55,at.y))
		_terrain.add_polygon(self, "ChamferedCivicGarden", wing, _materials["stone"])
		_box(self, "CivicGardenSoil", Vector3(side * 13,4.59,-84), Vector3(4.8,0.08,3.5), "bark")
	_grind_path("Grind_Rail_George", PackedVector3Array([
		Vector3(14, 4.92, -100), Vector3(14, 6.92, -109), Vector3(14, 6.92, -117)]), "rail")
	_grind_path("Grind_Ledge_Civic", PackedVector3Array([Vector3(-17,4.65,-81),Vector3(-18,4.65,-87),Vector3(-11,4.65,-88.5)]), "ledge")


func _build_civic_workshop() -> void:
	# The original civic garden/busking backdrop is a real chamfered terrace. The
	# ordered coping course in front stays on the ordinary Y4 civic floor.
	_terrain.add_polygon(self, "CivicWorkshopBackdrop", PackedVector3Array([
		Vector3(-16,4.65,-95),Vector3(-13,4.65,-99),Vector3(13,4.65,-99),
		Vector3(16,4.65,-95),Vector3(12,4.65,-94),Vector3(-12,4.65,-94)]), _materials["cut_stone"])
	# Toe heights match the existing civic banks beyond Z=-96 exactly.
	for side: float in [-1.0,1.0]:
		_terrain.add_polygon(self, "CivicWorkshopFrontBank", PackedVector3Array([
			Vector3(20 * side,4,-95),Vector3(16 * side,4.65,-95),
			Vector3(15.25 * side,4.65,-96),Vector3(19.25 * side,4,-96)]), _materials["paving"])
		_terrain.add_polygon(self, "CivicWorkshopRearBank", PackedVector3Array([
			Vector3(19.25 * side,4,-96),Vector3(15.25 * side,4.65,-96),
			Vector3(13 * side,4.65,-99),Vector3(17 * side,4.5,-99)]), _materials["paving"])
	_terrain.add_polygon(self, "CivicWorkshopApron", PackedVector3Array([
		Vector3(-18,4.01,-94),Vector3(18,4.01,-94),Vector3(20,4.01,-90),
		Vector3(17,4.01,-86),Vector3(-17,4.01,-86),Vector3(-20,4.01,-90)]), _materials["paving"])
	for entry: Dictionary in [
		{"id":"Grind_Cat_A", "from":-16.0, "to":-10.0, "label":"A", "accent":"teal"},
		{"id":"Grind_Cat_B", "from":-4.0, "to":2.0, "label":"B", "accent":"coral"},
		{"id":"Grind_Cat_C", "from":8.0, "to":14.0, "label":"C", "accent":"cream"}]:
		var middle := (float(entry.from) + float(entry.to)) * 0.5
		_box(self, entry.id + "Plinth", Vector3(middle,4.225,-91), Vector3(6,0.45,1.5), "stone", true)
		_grind_path(entry.id, PackedVector3Array([Vector3(entry.from,4.60,-91),Vector3(entry.to,4.60,-91)]), "coping")
		_box(self, entry.id + "Accent",Vector3(entry.from + 0.22,4.46,-91),Vector3(0.32,0.02,1.54),entry.accent)
		var marker := _label(self, entry.id + "Marker", entry.label, Vector3(middle,5.35,-92.25), 28, "cream", Vector3.ZERO, 0.012)
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.outline_size = 8
	# The low side-seat caps explain the raised backdrop as civic architecture.
	for x: float in [-10.5,10.5]:
		_box(self, "WorkshopBackSeat", Vector3(x,4.91,-98), Vector3(5.2,0.52,0.7), "stone", true)
	_label(self, "WorkshopBackdropSign", "THE WEE BIN SESSION / DRUMS & DANCING CATS", Vector3(0,5.25,-99.0), 26, "cream", Vector3.ZERO, 0.01)


func _build_central_station() -> void:
	_flat("CentralStationFloor", Rect2(-130, -42, 80, 87), 2, "paving")
	_slope("CentralPlatformApproach", Rect2(-101, 14, 14, 18), Vector4(5, 5, 2, 2), "stone")
	_terrain.add_patch(self, "CentralPlatformSouth", Rect2(-101, -1, 14, 15), Vector4.ONE * 5, _materials["path"], "stone", 0.4)
	_terrain.add_patch(self, "CentralPlatformNorth", Rect2(-101, -20, 14, 15), Vector4.ONE * 5, _materials["path"], "stone", 0.4)
	_slope("CentralPlatformExit", Rect2(-101, -38, 14, 18), Vector4(2, 2, 5, 5), "stone")
	_rail("Grind_Rail_CentralPlatform", Vector3(-99, 5, 6), 11)
	_rail("Grind_Rail_CentralGround", Vector3(-64, 2, -5), 17)
	# The adjacent station steps make the raised route part of its architecture.
	_steps("StationEntranceSteps", -117, -105, 16, 4, 2, 5, 12)
	# A real suspended service walk creates overlapping high/low routes.
	# The deck underside is Y4.6, leaving 2.6m above the lower concourse.
	_terrain.add_patch(self, "StationUpperWalk", Rect2(-122, -20, 17, 24), Vector4.ONE * 5.0, _materials["path"], "stone", 0.4)
	for x: float in [-121.0, -106.0]:
		for z: float in [-18.5, 2.5]:
			_box(self, "ServiceWalkPier", Vector3(x, 3.25, z), Vector3(0.65, 2.5, 0.65), "stone", true)
	_grind_path("Grind_Ledge_ServiceWalk", PackedVector3Array([Vector3(-121.6, 5.45, 1), Vector3(-121.6, 5.45, -17)]), "ledge")
	_label(self, "StationCloseSign", "LOW LEVEL / QUAY & PARK", Vector3(-126, 4.1, -3), 28, "cream", Vector3(0, 90, 0), 0.012)
	_slope("StationUpperReturn", Rect2(-122, -38, 17, 18), Vector4(2, 2, 5, 5), "stone")
	for x: float in [-124.0, -76.0]:
		for z: float in [-28.0, -17.0, 10.0, 28.0]:
			_box(self, "CanopyColumn", Vector3(x, 7, z), Vector3(0.48, 10, 0.48), "slate", true)


func _build_barras() -> void:
	_flat("BarrasFloor", Rect2(50, -42, 80, 87), 0, "paving")
	_flat("MarketLoadingTerrace", Rect2(50, -42, 80, 24), 1.5, "stone")
	_slope("MarketWestLoadingBank", Rect2(54, -18, 22, 12), Vector4(1.5, 1.5, 0, 0), "stone")
	_slope("MarketEastLoadingBank", Rect2(108, -18, 22, 12), Vector4(1.5, 1.5, 0, 0), "stone")
	_steps("MarketLoadingSteps", 87, 99, -8, -14, 0, 1.5, 6)
	_flat("MarketStepLanding", Rect2(87, -18, 12, 4), 1.5, "stone")
	_build_market_hall_island()
	for at: Vector3 in [Vector3(105, 0, -2), Vector3(80, 0, -2), Vector3(104, 0, 16), Vector3(118, 0, 1)]:
		_market_stall(at)
	_rail("Grind_Rail_Barras", Vector3(114, 0, 27), 12)
	_grind_path("Grind_Rail_MarketSteps", PackedVector3Array([Vector3(99.8, 0.92, -7), Vector3(99.8, 2.42, -15), Vector3(99.8, 2.42, -19)]), "rail")
	# A lower side opening and the loading bank give the hidden court an exit.
	_box(self, "RecordingAlcoveSide", Vector3(113, 3.0, -31), Vector3(0.5, 3, 14), "warehouse_brick", true)
	_box(self, "RecordingAlcoveBack", Vector3(120, 3.0, -39), Vector3(14, 3, 0.5), "warehouse_brick", true)
	_label(self, "RecordingHint", "AFTER HOURS", Vector3(120, 3.6, -38.7), 30, "cream")


func _build_market_hall_island() -> void:
	# A raised, chamfered loading/seating skirt attaches to a proper brick hall;
	# its low banks face the clear market aisle instead of the career corridor.
	_terrain.add_polygon(self, "MarketHallMasonrySkirt", PackedVector3Array([
		Vector3(50,0.65,-2),Vector3(66,0.65,-2),Vector3(76,0.65,4),
		Vector3(76,0.65,10),Vector3(69,0.65,17),Vector3(50,0.65,17)]), _materials["cut_stone"])
	var hall := _building(Vector3(56,0.65,7.5),15,10,"warehouse_brick","MARKET REPAIR HALL",PI / 2.0)
	_box(hall,"MarketHallFoundation",Vector3(0,-1.825,0),Vector3(15,3.65,12),"warehouse_brick",true)
	_terrain.add_polygon(self, "MarketHallEastBank", PackedVector3Array([
		Vector3(76,0.65,4),Vector3(80,0,4),Vector3(80,0,10),Vector3(76,0.65,10)]), _materials["paving"])
	_terrain.add_polygon(self, "MarketHallCornerBank", PackedVector3Array([
		Vector3(76,0.65,10),Vector3(80,0,10),Vector3(73,0,17),Vector3(69,0.65,17)]), _materials["paving"])
	_grind_path("Grind_Ledge_MarketHall",PackedVector3Array([Vector3(76,0.77,4),Vector3(76,0.77,10),Vector3(69,0.77,17)]),"ledge")
	_label(self,"MarketHallAisleSign","MARKET AISLE / LOADING BANK",Vector3(68,2.8,15.5),24,"cream",Vector3(0,90,0),0.01)


func _market_stall(at: Vector3) -> void:
	var stall := Node3D.new()
	stall.name = "MarketStall"
	stall.set_meta("market_stall", true)
	stall.position = at
	add_child(stall)
	_box(stall, "StallCounter", Vector3(0.0, 0.6, 0.0), Vector3(7.0, 1.2, 3.0), "stone", true)
	for x: float in [-3.5, 3.5]:
		_box(stall, "StallPole", Vector3(x, 1.5, 0.0), Vector3(0.12, 3.0, 0.12), "slate")
	for x: float in [-3.0, -1.0, 1.0, 3.0]:
		_box(stall, "StallAwning", Vector3(x, 3.1, 0.0), Vector3(2.0, 0.16, 4.5), "coral" if x < 0.0 else "cream")


func _street(node_name: String, start: Vector3, end: Vector3, width: float = 12.0, material: String = "asphalt") -> void:
	var bounds: Rect2
	var heights: Vector4
	if absf(end.x - start.x) > absf(end.z - start.z):
		bounds = Rect2(minf(start.x, end.x), start.z - width / 2.0, absf(end.x - start.x), width)
		var left := start.y if start.x < end.x else end.y
		var right := end.y if start.x < end.x else start.y
		heights = Vector4(left, right, right, left)
	else:
		bounds = Rect2(start.x - width / 2.0, minf(start.z, end.z), width, absf(end.z - start.z))
		var north := start.y if start.z < end.z else end.y
		var south := end.y if start.z < end.z else start.y
		heights = Vector4(north, north, south, south)
	_slope(node_name, bounds, heights, material)


func _wall_x(node_name: String, z: float, start: float, end: float, openings: Array) -> void:
	var cursor := start
	for opening: float in openings:
		var length: float = opening - 6.0 - cursor
		if length > 0.0:
			_box(self, node_name, Vector3(cursor + length / 2.0, 0.65, z), Vector3(length, 1.3, 1.0), "stone", true)
		cursor = opening + 6.0
	if end > cursor:
		_box(self, node_name, Vector3((cursor + end) / 2.0, 0.65, z), Vector3(end - cursor, 1.3, 1.0), "stone", true)


func _wall_z(node_name: String, x: float, start: float, end: float, openings: Array) -> void:
	var cursor := start
	for opening: float in openings:
		var length: float = opening - 6.0 - cursor
		if length > 0.0:
			_box(self, node_name, Vector3(x, 0.65, cursor + length / 2.0), Vector3(1.0, 1.3, length), "stone", true)
		cursor = opening + 6.0
	if end > cursor:
		_box(self, node_name, Vector3(x, 0.65, (cursor + end) / 2.0), Vector3(1.0, 1.3, end - cursor), "stone", true)


func _ground_label(node_name: String, words: String, at: Vector3, yaw: float) -> void:
	_label(self, node_name, words, at, 34, "cream", Vector3(-90.0, rad_to_deg(yaw), 0.0), 0.015)


func _building(at: Vector3, width: float, height: float, color: String, shop: String, yaw: float) -> Node3D:
	var building := Node3D.new()
	building.name = "TenementFacade"
	building.position = at
	building.rotation.y = yaw
	add_child(building)
	_box(building, "Facade", Vector3(0.0, height / 2.0, 0.0), Vector3(width, height, 12.0), color, true)
	_city_art.decorate_building(building, width, height, color, shop)
	return building


func _build_street_furniture() -> void:
	for at: Vector3 in [Vector3(-29, 0, 13), Vector3(28, 0, 14), Vector3(-28, 2, -32), Vector3(28, 2, -32)]:
		_box(self, "Planter", at + Vector3(0, 0.4, 0), Vector3(3, 0.8, 3), "stone", true)
	for at: Vector3 in [Vector3(-31, 0, 30), Vector3(31, 0, 30), Vector3(-31, 2, -29), Vector3(31, 2, -29)]:
		_cylinder(self, "LampPost", at + Vector3(0, 2.5, 0), 0.07, 0.12, 5, "slate")
		_box(self, "LampLantern", at + Vector3(0, 5.2, 0), Vector3(0.45, 0.7, 0.45), "cream")
	_label(self, "GalleryWayfinding", "GALLERY / CIVIC TERRACES", Vector3(-31, 1.8, -2), 28, "cream")


func _box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, color: String, solid: bool = false) -> Node3D:
	var root: Node3D
	if solid:
		root = StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		root.add_child(collider)
	else:
		root = Node3D.new()
	root.name = node_name
	root.set_meta("art_label", node_name)
	root.position = at
	parent.add_child(root)
	var geometry := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	geometry.mesh = mesh
	geometry.material_override = _materials[color]
	root.add_child(geometry)
	return root


func _cylinder(parent: Node3D, node_name: String, at: Vector3, top_radius: float, bottom_radius: float, height: float, color: String) -> void:
	var geometry := MeshInstance3D.new()
	geometry.name = node_name
	geometry.set_meta("art_label", node_name)
	geometry.position = at
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 10
	geometry.mesh = mesh
	geometry.material_override = _materials[color]
	parent.add_child(geometry)


func _label(parent: Node3D, node_name: String, words: String, at: Vector3, font_size: int, color: String, angles: Vector3 = Vector3.ZERO, pixel_size: float = 0.01) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = words
	label.position = at
	label.rotation_degrees = angles
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = PALETTE[color]
	label.outline_size = 0
	parent.add_child(label)
	return label


## Highest authored terrain support, excluding rail caps and decorative props.
## Unsupported positions return NAN rather than inventing a flat world floor.
func get_ground_height(world_position: Vector3) -> float:
	var at := to_local(world_position)
	var height: float = _terrain.height_at(at.x, at.z)
	if not is_nan(height):
		return to_global(Vector3(at.x, height, at.z)).y
	if is_instance_valid(_outdoors):
		return _outdoors.get_ground_height(world_position.x, world_position.z)
	return NAN


## Highest terrain support near/below the supplied height, including low routes
## underneath suspended decks. This is a query, not a collision/clearance proof.
func get_support_height(world_position: Vector3, max_step_up: float = 1.0) -> float:
	var at := to_local(world_position)
	var height: float = _terrain.height_at(at.x, at.z, at.y + maxf(0.0, max_step_up))
	if not is_nan(height): return to_global(Vector3(at.x, height, at.z)).y
	if is_instance_valid(_outdoors):
		var outdoor_height: float = _outdoors.get_ground_height(world_position.x, world_position.z)
		if outdoor_height <= world_position.y + maxf(0.0, max_step_up): return outdoor_height
	return NAN


func get_recovery_position(world_position: Vector3) -> Vector3:
	if is_instance_valid(_outdoors):
		return _outdoors.get_recovery_position(world_position)
	return Vector3.INF


func get_route_definitions() -> Array[Dictionary]:
	var routes: Array[Dictionary] = [
		_route("cat_coping_approach", "Busking coping approach", [Vector3(-28,4,-91),Vector3(-22,4,-91),Vector3(-18,4,-91)], false),
		_route("cat_coping_runout", "Busking coping landing and return", [Vector3(16,4,-91),Vector3(22,4,-91),Vector3(22,4,-74)]),
		_route("cat_ordered_coping_line", "Busking A to B to C coping line", [Vector3(-28,4,-91),Vector3(-16,4.60,-91),Vector3(-10,4.60,-91),Vector3(-7,4,-91),Vector3(-4,4.60,-91),Vector3(2,4.60,-91),Vector3(5,4,-91),Vector3(8,4.60,-91),Vector3(14,4.60,-91),Vector3(22,4,-91)], true),
		_route("cat_workshop_bypass", "Busking permanent civic bypass", [Vector3(-22,4,-91),Vector3(-22,4,-74),Vector3(22,4,-74),Vector3(22,4,-91)]),
		_route("civic_workshop_bank_loop", "Civic busking terrace banks", [Vector3(-22,4,-95.5),Vector3(-19.625,4,-95.5),Vector3(-15.625,4.65,-95.5),Vector3(-10,4.65,-94.5),Vector3(10,4.65,-94.5),Vector3(15.625,4.65,-95.5),Vector3(19.625,4,-95.5),Vector3(22,4,-95.5)]),
		_route("market_hall_bank_loop", "Market hall bank and angled aisle", [Vector3(82,0,8),Vector3(80,0,8),Vector3(76,0.65,8),Vector3(68,0.65,8),Vector3(67,0.65,13),Vector3(69,0.65,17),Vector3(73,0,17),Vector3(78,0,17),Vector3(82,0,8)]),
		_route("gallery_civic_ascent", "Gallery to civic terraces", [Vector3(-22,0,28), Vector3(-22,0,-4), Vector3(-22,2,-18), Vector3(-22,2,-42), Vector3(-22,4,-56), Vector3(-22,4,-96), Vector3(-22,6,-108), Vector3(-22,6,-118)]),
		_route("exchange_fountain_loop", "Fountain court loop", [Vector3(-22,0,28), Vector3(22,0,28), Vector3(22,0,-2), Vector3(-22,0,-2), Vector3(-22,0,28)]),
		_route("central_south_link", "Station climbing street", [Vector3(-22,0,22), Vector3(-35,0,22), Vector3(-50,2,22), Vector3(-70,2,22)]),
		_route("central_north_link", "Gallery station street", [Vector3(-22,2,-22), Vector3(-35,2,-22), Vector3(-50,2,-22), Vector3(-64,2,-22)]),
		_route("barras_south_link", "Market approach", [Vector3(22,0,22), Vector3(35,0,22), Vector3(50,0,22), Vector3(94,0,22)]),
		_route("barras_north_link", "Gallery loading street", [Vector3(22,2,-22), Vector3(35,2,-22), Vector3(50,1.5,-22), Vector3(75,1.5,-22)]),
		_route("central_back_lane", "Station to civic back lane", [Vector3(-88,2,-38), Vector3(-88,2,-42), Vector3(-88,4,-74), Vector3(-88,4,-80), Vector3(-35,4,-80), Vector3(-22,4,-80)]),
		_route("barras_back_lane", "Market to civic back lane", [Vector3(88,1.5,-30), Vector3(88,1.5,-42), Vector3(88,4,-74), Vector3(88,4,-80), Vector3(35,4,-80), Vector3(22,4,-80)]),
		_route("central_high_line", "Station platform transfer", [Vector3(-94,2,34), Vector3(-94,2,32), Vector3(-94,5,14), Vector3(-94,5,0), Vector3(-94,5,-6), Vector3(-94,5,-20), Vector3(-94,2,-38)], true),
		_route("central_high_line_bypass", "Station concourse bypass", [Vector3(-82,2,34), Vector3(-82,2,-34)]),
		_route("market_loading_ascent", "Warehouse loading street", [Vector3(126,0,30), Vector3(126,0,-6), Vector3(126,1.5,-18), Vector3(120,1.5,-24), Vector3(120,1.5,-33)]),
		_route("gallery_step_drop", "Gallery stair drop", [Vector3(0,2,-20), Vector3(0,2,-13), Vector3(0,0,-3)], true),
		_route("market_step_drop", "Market stair drop", [Vector3(93,1.5,-24), Vector3(93,1.5,-15), Vector3(93,0,-5)], true),
		_route("merchant_service_east_return", "Service court to station concourse", [Vector3(-56,1,-56), Vector3(-59,1,-54), Vector3(-59,2,-42), Vector3(-59,2,-34)]),
		_route("merchant_service_west_return", "Service court to outer climbing lane", [Vector3(-72,1,-70), Vector3(-74,1,-70), Vector3(-82,3.75,-70), Vector3(-88,3.75,-70)]),
		_route("merchant_close_cutthrough", "Merchant Close dogleg", [Vector3(-64,2,-30), Vector3(-68,2,-44), Vector3(-69,2.5,-50), Vector3(-61,3.2,-60), Vector3(-55,3.5,-65), Vector3(-59,4,-74), Vector3(-59,4,-80)]),
		_route("station_low_level_close", "Station service-walk underpass", [Vector3(-126,2,0), Vector3(-126,2,-8), Vector3(-114,2,-8), Vector3(-103,2,-8), Vector3(-82,2,-8), Vector3(-82,2,22)]),
		_route("station_park_port", "Station to Kelvingrove", [Vector3(-126,2,0), Vector3(-145,2,0)]),
		_route("civic_park_port", "Civic terrace to park", [Vector3(-22,6,-122), Vector3(-42,6,-122)]),
	]
	if is_instance_valid(_outdoors):
		routes.append_array(_outdoors.get_route_definitions())
	return routes


func _route(id: String, label: String, points: Array, requires_jump: bool = false) -> Dictionary:
	var world_points := PackedVector3Array()
	for at: Vector3 in points:
		world_points.append(to_global(at))
	return {"id": id, "label": label, "points": world_points, "requires_jump": requires_jump}


func _flat(label: String, bounds: Rect2, height: float, material: String) -> StaticBody3D:
	return _terrain.add_patch(self, label, bounds, Vector4.ONE * height, _materials[material], "asphalt" if material == "asphalt" else "stone")


func _slope(label: String, bounds: Rect2, heights: Vector4, material: String) -> StaticBody3D:
	var body: StaticBody3D = _terrain.add_patch(self, label, bounds, heights, _materials[material], "asphalt" if material == "asphalt" else "stone")
	var lowest := minf(minf(heights.x, heights.y), minf(heights.z, heights.w))
	var highest := maxf(maxf(heights.x, heights.y), maxf(heights.z, heights.w))
	if highest - lowest > 0.01:
		body.add_to_group("skateable_ramps")
		body.set_meta("rise", highest - lowest)
		body.set_meta("run", bounds.size.x if heights.x != heights.y else bounds.size.y)
		body.set_meta("width", bounds.size.y if heights.x != heights.y else bounds.size.x)
		body.set_meta("support_probe", to_global(Vector3(bounds.get_center().x, (heights.x + heights.y + heights.z + heights.w) * 0.25, bounds.get_center().y)))
	return body


func _steps(label: String, x_min: float, x_max: float, z_start: float, z_end: float, low: float, high: float, count: int) -> void:
	var depth := absf(z_end - z_start) / float(count)
	for index: int in range(count):
		var z := lerpf(z_start, z_end, float(index) / float(count))
		var height := lerpf(low, high, float(index + 1) / float(count))
		_flat(label + str(index + 1), Rect2(x_min, z - depth, x_max - x_min, depth), height, "cut_stone")


func _grind_path(id: String, points: PackedVector3Array, kind: String = "rail") -> void:
	var author := Node3D.new()
	author.name = id
	author.add_to_group("grind_rails")
	author.set_meta("grind_id", id)
	author.set_meta("grind_kind", kind)
	author.set_meta("grind_points", points)
	add_child(author)
	_rail_authors.append(author)
	var radius := 0.23 if kind == "coping" else 0.07
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 1.0
	cylinder.radial_segments = 12
	var batches := MultiMesh.new()
	batches.transform_format = MultiMesh.TRANSFORM_3D
	batches.mesh = cylinder
	batches.instance_count = points.size() - 1
	for index: int in range(points.size() - 1):
		var start := points[index] - Vector3.UP * radius
		var end := points[index + 1] - Vector3.UP * radius
		var direction := end - start
		var basis := Basis(Quaternion(Vector3.UP, direction.normalized())) * Basis.from_scale(Vector3(1, direction.length(), 1))
		batches.set_instance_transform(index, Transform3D(basis, (start + end) / 2.0))
	var visual := MultiMeshInstance3D.new()
	visual.multimesh = batches
	visual.material_override = _materials["cut_stone" if kind != "rail" else "iron"]
	author.add_child(visual)
	# Rail supports are decorative only; they cannot snag acquisition/exit.
	if kind == "rail":
		for index: int in range(0, points.size(), 2):
			var at := points[index]
			var ground := get_ground_height(to_global(at))
			if not is_nan(ground):
				var height := at.y - ground - radius
				_cylinder(author, "HandrailSupport", Vector3(at.x, ground + height / 2.0, at.z), 0.045, 0.045, height, "iron")


func _fountain(at: Vector3, radius: float) -> void:
	var body := StaticBody3D.new()
	body.name = "ExchangeFountain"
	body.position = at
	body.set_meta("surface_audio", "stone")
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.55
	collision.shape = shape
	collision.position.y = 0.275
	body.add_child(collision)
	_cylinder(body, "FountainBasin", Vector3(0, 0.275, 0), radius, radius, 0.55, "stone")
	var pedestal_collision := CollisionShape3D.new()
	var pedestal_shape := CylinderShape3D.new()
	pedestal_shape.radius = 0.7
	pedestal_shape.height = 2.7
	pedestal_collision.shape = pedestal_shape
	pedestal_collision.position.y = 1.35
	body.add_child(pedestal_collision)
	_cylinder(body, "FountainWater", Vector3(0, 0.57, 0), radius - 0.85, radius - 0.85, 0.04, "glass")
	_cylinder(body, "FountainPedestal", Vector3(0, 1.2, 0), 0.65, 1.0, 2.0, "stone_light")
	_cylinder(body, "FountainBowl", Vector3(0, 2.1, 0), 1.65, 0.65, 0.5, "stone_light")
	_cylinder(body, "FountainCrown", Vector3(0, 2.7, 0), 0.22, 0.42, 0.85, "bronze")
	var points := PackedVector3Array()
	for index: int in range(65):
		var angle := TAU * float(index) / 64.0
		points.append(at + Vector3(cos(angle) * radius, 0.92, sin(angle) * radius))
	_grind_path("Grind_Coping_ExchangeFountain", points, "coping")


func get_goal_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = [
		{"id": "H", "kind": "letter", "position": Vector3(-22, 2.9, -26), "radius": 1.8},
		{"id": "A", "kind": "letter", "position": Vector3(20, 6.9, -116), "radius": 1.8},
		{"id": "W", "kind": "letter", "position": Vector3(-94, 5.9, -12), "radius": 1.8},
		{"id": "K", "kind": "letter", "position": Vector3(94, 0.9, 20), "radius": 1.8},
		{"id": "S", "kind": "letter", "position": Vector3(-60, 4.9, -80), "radius": 1.8},
		{"id": "market_1", "kind": "market_item", "position": Vector3(70, 0.9, 22), "radius": 1.8},
		{"id": "market_2", "kind": "market_item", "position": Vector3(106, 0.9, 26), "radius": 1.8},
		{"id": "market_3", "kind": "market_item", "position": Vector3(106, 2.4, -26), "radius": 1.8},
		{"id": "cone", "kind": "interaction", "position": Vector3(18, 2.8, -22), "radius": 2.4},
		{"id": "secret_recording", "kind": "collectible", "position": Vector3(120, 2.4, -33), "radius": 1.8},
	]
	for marker: Dictionary in markers:
		marker.position = to_global(marker.position)
	var checkpoints := get_district_checkpoints()
	for id: String in checkpoints:
		markers.append({"id": id, "kind": "district", "position": checkpoints[id], "radius": 3.5})
	return markers


func get_grind_lines() -> Array:
	var lines: Array = []
	for rail: Node3D in _rail_authors:
		var local_points: PackedVector3Array = rail.get_meta("grind_points")
		lines.append(GrindLineSource.from_local_points(String(rail.get_meta("grind_id")),
			local_points, rail.global_transform, String(rail.get_meta("grind_kind", "rail"))))
	if is_instance_valid(_outdoors):
		lines.append_array(_outdoors.get_grind_lines())
	return lines
