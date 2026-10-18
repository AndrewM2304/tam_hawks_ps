extends Node3D
## Original, compressed Glasgow-inspired landscapes; not surveyed street geometry.
## Published coordinates are world-space board-contact positions except checkpoints.

const Surface = preload("res://game/levels/outdoors/surface_builder.gd")
const Vegetation = preload("res://game/levels/outdoors/vegetation.gd")
const ClydeLandmarks = preload("res://game/levels/art/clyde_landmarks.gd")
const GrindLineSource = preload("res://game/tricks/grind_line.gd")
const ExplorationBoundary = preload("res://game/levels/exploration_boundary.gd")
const PARK := Rect2(-220, -185, 80, 110)
const PARK_LANDSCAPE := Rect2(-255, -225, 115, 165)
const RIVER := Rect2(-150, 78, 300, 38)
const VISIBLE_WATER := Rect2(-450, 78, 900, 38)
const WATER_Y := -2.0
const YARD_BANK_RADIUS := 4.0
const YARD_BANK_ANGLE := deg_to_rad(35.0)
const YARD_BANK_RUN := YARD_BANK_RADIUS * sin(YARD_BANK_ANGLE)
const YARD_BANK_RISE := YARD_BANK_RADIUS * (1.0 - cos(YARD_BANK_ANGLE))

var _materials: Dictionary
var _surfaces: Array[Dictionary] = []
var _routes: Array[Dictionary] = []
var _rails: Array = []
var _park_path := PackedVector3Array()
var _park_cutback := PackedVector3Array()
var _clyde_yard := PackedVector3Array()
var _park_connector := PackedVector3Array()
var _george_connector := PackedVector3Array()
var _built := false


func build(world: Node3D, materials: Dictionary) -> void:
	if _built: return
	_built = true
	_materials = materials
	_build_clyde()
	_build_riverside_edge(world)
	_build_park()
	_build_exploration_boundaries()


func get_checkpoints() -> Dictionary:
	return {"clyde": to_global(Vector3(15, 2.8, 67)), "kelvingrove": to_global(Vector3(-155, 6.8, -82))}


func _build_exploration_boundaries() -> void:
	# These are the exposed edges of the three joined landscape rectangles,
	# not their internal seams. Preserve both real civic/station port mouths.
	for edge: Array in [
		[Vector2(-254.8,-224.8),Vector2(-254.8,-60.2)],
		[Vector2(-254.8,-224.8),Vector2(-140.2,-224.8)],
		[Vector2(-140.2,-224.8),Vector2(-140.2,-142)],
		[Vector2(-140.2,-108),Vector2(-140.2,-92)],
		[Vector2(-140,-141.8),Vector2(-42.2,-141.8)],
		[Vector2(-140,-108.2),Vector2(-42.2,-108.2)],
		[Vector2(-42.2,-141.8),Vector2(-42.2,-128)],
		[Vector2(-42.2,-116),Vector2(-42.2,-108.2)],
		[Vector2(-140,-91.8),Vector2(-130.2,-91.8)],
		[Vector2(-130.2,-91.8),Vector2(-130.2,-8)],
		[Vector2(-130.2,8),Vector2(-130.2,19.8)],
		[Vector2(-214.8,19.8),Vector2(-130.2,19.8)],
		[Vector2(-214.8,-60),Vector2(-214.8,19.8)],
		[Vector2(-254.8,-60.2),Vector2(-215,-60.2)]
	]: _boundary("ParkRetainedBoundary",edge[0],edge[1])
	# Bound BOTH sides of the landward void between the city and the quay.
	# The river-facing edges remain the explicit, recoverable skating hazard.
	for span: Vector2 in [Vector2(-149.8,-102),Vector2(-86,-15),Vector2(-9,9),Vector2(15,86),Vector2(102,149.8)]:
		_boundary("QuayLandwardBoundary",Vector2(span.x,55.2),Vector2(span.y,55.2))
	for x: float in [-149.8,149.8]:
		_boundary("NorthQuayEndBoundary",Vector2(x,55.2),Vector2(x,77.8))
		_boundary("SouthQuayEndBoundary",Vector2(x,116.2),Vector2(x,130.2))
	for x: float in [-279.8,279.8]:
		_boundary("SouthLandscapeEndBoundary",Vector2(x,130.2),Vector2(x,219.8))
	_boundary("SouthLandscapeRearBoundary",Vector2(-279.8,219.8),Vector2(279.8,219.8))
	_boundary("SouthLandscapeNorthBoundary",Vector2(-279.8,130.2),Vector2(-150,130.2))
	_boundary("SouthLandscapeNorthBoundary",Vector2(150,130.2),Vector2(279.8,130.2))


func _boundary(id: String, start: Vector2, end: Vector2) -> void:
	var points := PackedVector3Array()
	var count := maxi(1,ceili(start.distance_to(end)/2.0))
	for index: int in range(count+1):
		var at := start.lerp(end,float(index)/count)
		var height := _local_ground(at.x,at.y)
		assert(is_finite(height),"Outdoor boundary requires real supported ground: "+id+" "+str(at))
		points.append(Vector3(at.x,height,at.y))
	ExplorationBoundary.build(self,id,points,_material("cut_stone"),_material("iron"))


func get_district_id(world_position: Vector3) -> String:
	var at := to_local(world_position)
	if at.z >= 54.0 and at.z <= 220.0 and absf(at.x) <= 280.0: return "clyde"
	if PARK_LANDSCAPE.has_point(Vector2(at.x, at.z)): return "kelvingrove"
	# Narrow connector footprints avoid capturing Central/George from broad bounds.
	if at.x < -145.0 and float(Surface.nearest_segment(_park_connector, Vector2(at.x, at.z)).distance) < 6.5: return "kelvingrove"
	if at.x < -46.0 and float(Surface.nearest_segment(_george_connector, Vector2(at.x, at.z)).distance) < 5.0: return "kelvingrove"
	return ""


func get_location_name(world_position: Vector3) -> String:
	return "CLYDE QUAYS" if get_district_id(world_position) == "clyde" else "KELVINGROVE PARK"


func get_ground_height(world_x: float, world_z: float) -> float:
	var local := to_local(Vector3(world_x, global_position.y, world_z))
	var height := _local_ground(local.x, local.z)
	return NAN if is_nan(height) else to_global(Vector3(local.x, height, local.z)).y


func get_recovery_position(world_position: Vector3) -> Vector3:
	var at := to_local(world_position)
	# Every visible part of the river is the same readable water hazard. The
	# scenic plane is wider than the skating quays; do not leave its ends without
	# the prompt supported-quay recovery used by a missed bridge transfer.
	if not VISIBLE_WATER.has_point(Vector2(at.x, at.z)) or at.y >= WATER_Y + 0.25: return Vector3.INF
	var safe_z := 71.0 if at.z < RIVER.get_center().y else 124.0
	# Stay away from deck rails and place the skater directly on a broad quay.
	var safe_x := clampf(at.x, -140.0, 140.0)
	if absf(safe_x + 98.0) < 7.0: safe_x = -86.0
	if absf(safe_x - 35.0) < 5.0: safe_x = 25.0
	return to_global(Vector3(safe_x, 2.8, safe_z))


func get_grind_lines() -> Array:
	return _rails.duplicate()


func get_gap_definitions() -> Array[Dictionary]:
	return [{"id": "clyde_bridge_transfer", "name": "Clyde Broken Bridge", "start": to_global(Vector3(35, 3.05, 92)), "end": to_global(Vector3(35, 2.69, 104)), "radius": 2.4, "points": 900, "airborne_required": true}]


func get_route_definitions() -> Array[Dictionary]:
	var routes: Array[Dictionary] = []
	for source: Dictionary in _routes:
		var route := source.duplicate()
		var points := PackedVector3Array()
		for at: Vector3 in source.points: points.append(to_global(at))
		route.points = points
		routes.append(route)
	return routes


func _build_clyde() -> void:
	_patch("ClydeNorthQuay", Rect2(-150, 55, 300, 23), 2.0, _material("paving"))
	_patch("ClydeSouthQuay", Rect2(-150, 116, 300, 14), 2.0, _material("paving"))
	var west := PackedVector3Array([Vector3(-94, 2, 45), Vector3(-94, 2, 65)])
	var east := PackedVector3Array([Vector3(94, 0, 45), Vector3(94, 2, 55), Vector3(94, 2, 68)])
	# Road visuals meet the quay at Z55. Their original full collision strips
	# remain for route/support continuity, without coplanar asphalt over paving.
	_path("ClydeWestApproach", west, 16.0, _material("asphalt"), "asphalt",
		PackedVector3Array([west[0], Vector3(-94, 2, 55)]))
	_path("ClydeEastApproach", east, 16.0, _material("asphalt"), "asphalt",
		PackedVector3Array([east[0], east[1]]))
	var safe := PackedVector3Array([Vector3(-98, 2, 72), Vector3(-98, 3.4, 89), Vector3(-98, 3.4, 105), Vector3(-98, 2, 122)])
	_path("ClydeSafeBridge", safe, 8.0, _material("iron"), "metal")
	var north := PackedVector3Array([Vector3(35, 2, 74), Vector3(35, 2.6, 86), Vector3(35, 3.2, 94)])
	var south := PackedVector3Array([Vector3(35, 2.8, 102), Vector3(35, 2, 116), Vector3(35, 2, 124)])
	_path("ClydeBridgeNorthDeck", north, 5.0, _material("iron"), "metal")
	_path("ClydeBridgeSouthDeck", south, 5.0, _material("iron"), "metal")
	# Retaining masonry leaves the water visibly below skateable quays.
	_box("NorthEmbankment", Vector3(0, -0.2, 77.6), Vector3(300, 4.4, 0.8), _material("cut_stone"))
	_box("SouthEmbankment", Vector3(0, -0.2, 116.4), Vector3(300, 4.4, 0.8), _material("cut_stone"))
	for piece: Vector2 in [Vector2(-150,39), Vector2(53,62), Vector2(76,150)]:
		_box("SouthQuayBacking", Vector3((piece.x + piece.y) * 0.5, 1.25, 130), Vector3(piece.y - piece.x, 1.5, 1), _material("cut_stone"))
	_clyde_yard = PackedVector3Array([Vector3(35,2,124), Vector3(56,2,137), Vector3(78,2,124), Vector3(45,2,122), Vector3(35,2,124)])
	_path("ClydePrintYard", _clyde_yard, 8.0, _material("paving"))
	_box("PrintYardPlanter", Vector3(58,2.35,127), Vector3(9,0.7,5), _material("cut_stone"))
	_box("PrintYardSoil", Vector3(56,2.73,127), Vector3(3.0,0.08,4.4), _material("bark"), false)
	var hip_bounds := Rect2(58, 126, 4.5 + YARD_BANK_RUN, 3.5 + YARD_BANK_RUN)
	var hip_body := Surface.terrain(self, "PrintYardCurvedBankHip", hip_bounds, 0.25, _yard_hip_height, _material("cut_stone"))
	hip_body.add_to_group("curved_banks")
	hip_body.set_meta("max_angle_degrees", 35.0)
	hip_body.set_meta("radius", YARD_BANK_RADIUS)
	_surfaces.append({"bounds": hip_bounds, "height_at": _yard_hip_height, "spacing":0.25})
	var hip_route := PackedVector3Array([Vector3(69,2,127.5), Vector3(62.5 + YARD_BANK_RUN,2,127.5)])
	for degrees: float in [5.0,10.0,15.0,20.0,25.0,30.0,35.0]:
		var angle := deg_to_rad(degrees)
		hip_route.append(Vector3(62.5 + YARD_BANK_RUN - 4.0 * sin(angle), 2.0 + 4.0 * (1.0 - cos(angle)), 127.5))
	hip_route.append(Vector3(60,2 + YARD_BANK_RISE,127.5))
	hip_route.append(Vector3(60,2 + YARD_BANK_RISE,129.5))
	for degrees: float in [30.0,25.0,20.0,15.0,10.0,5.0,0.0]:
		var angle := deg_to_rad(degrees)
		hip_route.append(Vector3(60,2.0 + 4.0 * (1.0 - cos(angle)),129.5 + YARD_BANK_RUN - 4.0 * sin(angle)))
	hip_route.append(Vector3(60,2,135.5))
	_route("clyde_print_yard_hip", "Print-yard curved bank and hip", hip_route)
	_rail("clyde_print_yard_ledge", PackedVector3Array([Vector3(53.3,2.77,124.4), Vector3(62.7,2.77,124.4)]), "ledge", 0.16)
	_water()
	var bank_material := StandardMaterial3D.new()
	bank_material.albedo_color = Color(0.23, 0.29, 0.18)
	bank_material.roughness = 0.95
	var bank_bounds := Rect2(-280, 130, 560, 90)
	Surface.terrain(self, "ClydeSouthBankLandscape", bank_bounds, 5.0, _south_bank_height, bank_material)
	_surfaces.append({"bounds": bank_bounds, "height_at": _south_bank_height, "spacing":5.0})
	_bridge_structure(safe, 8.0, true)
	_bridge_structure(north, 5.0, false)
	_bridge_structure(south, 5.0, false)
	# Low coping is readable from the quay and accessible to ordinary ollies.
	_rail("clyde_quay_coping", PackedVector3Array([Vector3(-68, 2.42, 76.7), Vector3(-22, 2.42, 76.7)]), "coping", 0.22)
	_rail("clyde_bridge_rail", PackedVector3Array([Vector3(37.2, 3.25, 80), Vector3(37.2, 3.55, 86), Vector3(37.2, 4.0, 92)]), "rail", 0.065)
	for x: float in [-138.0, -118.0, -74.0, -48.0, -8.0, 15.0, 58.0, 84.0, 116.0, 140.0]:
		_bollard(Vector3(x, 2.0, 75.0))
	for x: float in [-135.0, -70.0, -10.0, 65.0, 130.0]:
		_bench(Vector3(x, 2.0, 59.0))
	_route("clyde_north_quay", "Station to Barras via Clyde", PackedVector3Array([Vector3(-94, 2, 45), Vector3(-94, 2, 67), Vector3(94, 2, 67), Vector3(94, 2, 55), Vector3(94, 0, 45)]))
	var safe_route := PackedVector3Array([Vector3(-98, 2, 67)])
	safe_route.append_array(safe)
	safe_route.append(Vector3(-98, 2, 125))
	_route("clyde_safe_crossing", "Clyde continuous crossing", safe_route)
	var transfer := PackedVector3Array([Vector3(35, 2, 65)])
	transfer.append_array(north)
	transfer.append_array(south)
	_route("clyde_bridge_transfer", "Clyde eight-metre transfer", transfer, true)
	_route("clyde_print_yard_loop", "Clyde print-yard landing loop", _clyde_yard)


func _build_park() -> void:
	_park_connector = Surface.smooth_points(PackedVector3Array([Vector3(-145, 2, 0), Vector3(-151, 3, -22), Vector3(-147, 4.5, -48), Vector3(-155, 6, -82)]))
	_george_connector = PackedVector3Array([Vector3(-42, 6, -122), Vector3(-145, 6, -125)])
	_park_cutback = Surface.smooth_points(PackedVector3Array([Vector3(-208,11,-126), Vector3(-226,10,-111), Vector3(-210,8,-86), Vector3(-185,6.5,-70), Vector3(-162,5,-54), Vector3(-147,4.5,-48)]))
	_park_path = Surface.smooth_points(PackedVector3Array([
		Vector3(-155, 6, -82), Vector3(-173, 7, -96), Vector3(-195, 9, -106), Vector3(-208, 11, -126), Vector3(-200, 13, -147), Vector3(-181, 15, -164), Vector3(-161, 17, -178), Vector3(-146, 15, -165), Vector3(-145, 11, -146), Vector3(-145, 6, -125), Vector3(-145, 6, -104), Vector3(-155, 6, -82)]))
	# A level fork apron joins the two graded branches without overlapping lips.
	for path: PackedVector3Array in [_park_path, _park_cutback]:
		for index in path.size():
			var distance := Vector2(path[index].x + 208, path[index].z + 126).length()
			var at := path[index]
			at.y = lerpf(11.0, at.y, smoothstep(6.0, 14.0, distance))
			path[index] = at
	var grass := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);vec2 u=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),u.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),u.x),u.y);}
void fragment(){
	// Keep detail broad enough to remain stable across the Mac and GL renderer.
	// Sub-10cm hash cells shimmer and alias on this large, shallow landscape.
	vec2 p=world_position.xz;
	float patches=noise(p*0.12)*0.68+noise(p*0.38)*0.32;
	float shade=0.96+0.04*sin(dot(p,vec2(0.037,0.051)));
	ALBEDO=mix(vec3(0.20,0.27,0.14),vec3(0.29,0.35,0.20),patches)*shade;
	ROUGHNESS=0.98;
	SPECULAR=0.08;
}
"""
	grass.shader = shader
	Surface.terrain(self, "KelvingroveRollingGround", PARK_LANDSCAPE, 2.5, _park_height, grass)
	# The approaches are raised park embankments, not unsupported road ribbons.
	var central_bank := Rect2(-215, -92, 85, 112)
	var george_bank := Rect2(-145, -142, 103, 34)
	Surface.terrain(self, "KelvingroveCentralEmbankment", central_bank, 2.5, _central_bank_height, grass)
	Surface.terrain(self, "KelvingroveGeorgeEmbankment", george_bank, 3.0, _george_bank_height, grass)
	_surfaces.append({"bounds": central_bank, "height_at": _central_bank_height, "spacing":2.5})
	_surfaces.append({"bounds": george_bank, "height_at": _george_bank_height, "spacing":3.0})
	# Broad smooth asphalt ribbons share exact sampled physics/query coordinates.
	_path("KelvingroveCentralApproach", _park_connector, 10.0, _material("asphalt"))
	_path("KelvingroveGeorgePromenade", _george_connector, 10.0, _material("paving"))
	_path("KelvingroveRollingLoop", _park_path, 8.0, _material("asphalt"))
	_path("KelvingroveCutbackReturn", _park_cutback, 8.0, _material("asphalt"))
	var hip := PackedVector3Array([Vector3(-224,8.0,-91), Vector3(-226,9.1,-84), Vector3(-220,8.4,-78)])
	_path("KelvingroveCutbackHip", hip, 4.5, _material("paving"))
	_rail("kelvingrove_cutback_ledge", PackedVector3Array([Vector3(-227.2,9.5,-84), Vector3(-221.2,8.8,-78)]), "ledge", 0.18)
	_path_border(_park_path)
	# Upper viewpoint sits off the riding line and is reached at the summit.
	_patch("KelvingroveViewTerrace", Rect2(-179, -185, 18, 5), 17.0, _material("paving"))
	_path("KelvingroveViewpointSpur", PackedVector3Array([Vector3(-161, 17, -178), Vector3(-165, 17, -182), Vector3(-173, 17, -182)]), 4.0, _material("paving"))
	_rail("kelvingrove_terrace_coping", PackedVector3Array([Vector3(-177, 17.4, -184), Vector3(-164, 17.4, -184)]), "coping", 0.2)
	var bend := PackedVector3Array()
	var bend_piece := 0
	for at: Vector3 in _park_path:
		var edge := at + Vector3(-3.3, 0.55, 0)
		var branch := Surface.nearest_segment(_park_cutback, Vector2(edge.x, edge.z))
		if at.x < -201 and at.z < -113 and at.z > -139 and float(branch.distance) > 6.0:
			bend.append(edge)
		else:
			if bend.size() >= 2:
				_rail("kelvingrove_s_bend_" + str(bend_piece), bend, "rail", 0.065)
				bend_piece += 1
			bend = PackedVector3Array()
	if bend.size() >= 2: _rail("kelvingrove_s_bend_" + str(bend_piece), bend, "rail", 0.065)
	_park_pavilion()
	var trees: Array[Dictionary] = []
	for row in 11:
		for col in 8:
			var x := -247.0 + col * 13.5 + sin(row * 5.13 + col) * 2.7
			var z := -217.0 + row * 14.5 + cos(col * 4.1 + row) * 2.5
			var nearest := Surface.nearest_segment(_park_path, Vector2(x, z))
			var central := Surface.nearest_segment(_park_connector, Vector2(x, z))
			var george := Surface.nearest_segment(_george_connector, Vector2(x, z))
			var cutback := Surface.nearest_segment(_park_cutback, Vector2(x, z))
			if minf(minf(float(nearest.distance), float(cutback.distance)), minf(float(central.distance), float(george.distance))) < 8.0 or (x > -184 and z < -172): continue
			trees.append({"position": Vector3(x, _park_height(x, z), z), "scale": 0.78 + fmod(row * 0.13 + col * 0.21, 0.36), "yaw": row * 1.7 + col * 0.7})
	Vegetation.build(self, trees, _material("bark"))
	_route("kelvingrove_central_climb", "Central to Kelvingrove", _park_connector)
	_route("kelvingrove_george_promenade", "George Square park promenade", _george_connector)
	_route("kelvingrove_rolling_loop", "Kelvingrove hillside loop", _park_path)
	_route("kelvingrove_cutback_return", "Kelvingrove cutback to Central", _park_cutback)


func _build_riverside_edge(_world: Node3D) -> void:
	# Original, researched bridge/terrace geometry replaces the generic shop row.
	# It adds no collision or grind path; tested routes remain authoritative.
	ClydeLandmarks.build(self, _materials)
	# The old generic facades were solid. Keep the new joined houses solid too,
	# matching their actual footprints instead of retaining hidden old boxes.
	for block: Vector2 in [Vector2(-100,96), Vector2(-1,88), Vector2(99,92)]:
		var body := StaticBody3D.new()
		body.name = "CarltonPlaceBoundary"
		body.position = Vector3(block.x,7.5,151.4)
		var shape := BoxShape3D.new()
		shape.size = Vector3(block.y,13.0,12.0)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _yard_hip_height(x: float, z: float) -> float:
	var distance := Vector2(maxf(0.0, x - 62.5), maxf(0.0, z - 129.5)).length()
	var toward_deck := clampf(YARD_BANK_RUN - distance, 0.0, YARD_BANK_RUN)
	return 2.0 + YARD_BANK_RADIUS - sqrt(maxf(0.0, YARD_BANK_RADIUS * YARD_BANK_RADIUS - toward_deck * toward_deck))


func _south_bank_height(x: float, z: float) -> float:
	var depth := smoothstep(130.0, 215.0, z)
	var natural := 2.0 + depth * (5.5 + sin(x * 0.025) * 2.0 + cos(x * 0.011 + z * 0.03))
	if not _clyde_yard.is_empty() and x > 24 and x < 88 and z < 149:
		var nearest := Surface.nearest_segment(_clyde_yard, Vector2(x,z))
		natural = minf(natural, lerpf(1.8, natural, smoothstep(8.0, 14.0, float(nearest.distance))))
	return natural


func _central_bank_height(x: float, z: float) -> float:
	var nearest := Surface.nearest_segment(_park_connector, Vector2(x, z))
	var cutback := Surface.nearest_segment(_park_cutback, Vector2(x, z))
	if float(cutback.distance) < float(nearest.distance): nearest = cutback
	return lerpf(float(nearest.height) - 0.35, 0.5, smoothstep(7.0, 15.0, float(nearest.distance)))


func _george_bank_height(x: float, z: float) -> float:
	var nearest := Surface.nearest_segment(_george_connector, Vector2(x, z))
	return lerpf(5.75, 0.5, smoothstep(6.0, 15.5, float(nearest.distance)))


func _park_height(x: float, z: float) -> float:
	var rise := clampf((-z - 80.0) / 100.0, 0.0, 1.0)
	var natural := 6.0 + rise * 10.0 + sin(x * 0.09 + z * 0.03) * 1.15 + sin(z * 0.12) * 0.65
	var nearest := Surface.nearest_segment(_park_path, Vector2(x, z))
	for path: PackedVector3Array in [_park_connector, _george_connector, _park_cutback]:
		var candidate := Surface.nearest_segment(path, Vector2(x, z))
		if float(candidate.distance) < float(nearest.distance): nearest = candidate
	var distance: float = nearest.distance
	var weight := smoothstep(6.0, 13.0, distance)
	var height := lerpf(float(nearest.height) - 0.25, natural, weight)
	# Flatten the summit apron into the hillside, not a floating slab.
	if x >= -181 and x <= -159 and z <= -178:
		var apron := Rect2(-179, -185, 18, 5)
		var distance_apron := Vector2(x, z).distance_to(Vector2(clampf(x, apron.position.x, apron.end.x), clampf(z, apron.position.y, apron.end.y)))
		height = minf(height, lerpf(16.75, height, smoothstep(0.0, 3.0, distance_apron)))
	# Blend the north/west woodland skirts continuously. A conditional applied
	# to all four rectangle edges previously produced a~16m discontinuity where
	# its north cutoff met the east edge, despite looking like ordinary grass.
	var woodland := minf(smoothstep(-255.0,-225.0,x),smoothstep(-225.0,-195.0,z))
	height = lerpf(1.0 + sin(x * 0.025 + z * 0.014),height,woodland)
	return height


func _local_ground(x: float, z: float) -> float:
	var at := Vector2(x, z)
	var highest := Surface.grid_height(PARK_LANDSCAPE,2.5,_park_height,x,z) if PARK_LANDSCAPE.has_point(at) else NAN
	for surface: Dictionary in _surfaces:
		var height := NAN
		if surface.has("bounds"):
			if surface.bounds.has_point(at): height = Surface.grid_height(surface.bounds,surface.spacing,surface.height_at,x,z) if surface.has("height_at") else surface.height
		else:
			height = Surface.strip_height(surface.support_vertices,at)
		if is_finite(height) and (is_nan(highest) or height > highest): highest = height
	if not is_nan(highest): return highest
	return NAN


func _patch(id: String, bounds: Rect2, height: float, material: Material) -> void:
	Surface.terrain(self, id, bounds, 5.0, func(_x: float, _z: float) -> float: return height, material)
	_surfaces.append({"bounds": bounds, "height": height})


func _path(id: String, points: PackedVector3Array, width: float, material: Material, audio: String = "asphalt", visual_points: PackedVector3Array = PackedVector3Array()) -> void:
	var body := Surface.strip(self, id, points, width, material, audio, visual_points)
	_surfaces.append({"points": points, "width": width, "support_vertices":body.get_meta("support_vertices")})


func _route(id: String, label: String, points: PackedVector3Array, jump: bool = false) -> void:
	_routes.append({"id": id, "label": label, "points": points, "requires_jump": jump})


func _material(id: String) -> Material:
	if _materials.has(id): return _materials[id]
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color(0.3, 0.32, 0.3)
	fallback.roughness = 0.9
	return fallback


func _box(id: String, at: Vector3, size: Vector3, material: Material, colliding: bool = true) -> Node3D:
	var root: Node3D = StaticBody3D.new() if colliding else Node3D.new()
	root.name = id
	root.set_meta("art_label", id)
	root.position = at
	add_child(root)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	root.add_child(visual)
	if colliding:
		root.set_meta("surface_audio", "stone")
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		root.add_child(collision)
	return root


func _beam(id: String, a: Vector3, b: Vector3, radius: float, material: Material, colliding: bool = false) -> void:
	var delta := b - a
	var piece := _box(id, (a + b) * 0.5, Vector3(radius * 2.0, radius * 2.0, delta.length()), material, colliding)
	piece.look_at(to_global(b), Vector3.UP if absf(delta.normalized().y) < 0.98 else Vector3.FORWARD)


func _rail(id: String, points: PackedVector3Array, kind: String, radius: float) -> void:
	_rails.append(GrindLineSource.from_local_points(id, points, global_transform, kind))
	for i in range(points.size() - 1): _beam(id + "Visual", points[i], points[i + 1], radius, _material("cut_stone" if kind == "coping" else "iron"))


func _bridge_structure(points: PackedVector3Array, width: float, safe: bool) -> void:
	for side: float in [-1.0, 1.0]:
		for i in range(points.size() - 1):
			var a := points[i] + Vector3(side * (width * 0.5 - 0.15), 0, 0)
			var b := points[i + 1] + Vector3(side * (width * 0.5 - 0.15), 0, 0)
			_beam("BridgeEdgeGirder", a - Vector3.UP * 0.25, b - Vector3.UP * 0.25, 0.18, _material("iron"))
			_beam("BridgeHandrail", a + Vector3.UP * 1.05, b + Vector3.UP * 1.05, 0.045, _material("iron"), safe)
			if safe: _beam("BridgeLowerRail", a + Vector3.UP * 0.5, b + Vector3.UP * 0.5, 0.025, _material("iron"))
			var steps := maxi(1, ceili(a.distance_to(b) / 4.0))
			for j in steps:
				var at := a.lerp(b, float(j) / steps)
				_beam("BridgePost", at, at + Vector3.UP * 1.1, 0.045, _material("iron"))
	for i in [0, points.size() - 1]:
		var at := points[i]
		_box("BridgePier", Vector3(at.x, -0.6, at.z), Vector3(width - 1.0, 4.0, 1.0), _material("cut_stone"), false)


func _water() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = VISIBLE_WATER.size
	var instance := MeshInstance3D.new()
	instance.name = "ClydeWater"
	instance.mesh = mesh
	instance.position = Vector3(0, WATER_Y, RIVER.get_center().y)
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=world_position.xz;
	float phase_a=dot(p,vec2(0.085,0.031))+TIME*0.31;
	float phase_b=dot(p,vec2(-0.028,0.13))-TIME*0.46;
	float phase_c=dot(p,vec2(0.21,-0.17))+TIME*0.22;
	float wave=0.58*sin(phase_a)+0.32*sin(phase_b)+0.10*sin(phase_c);
	float tone=clamp(0.5+0.5*wave,0.0,1.0);
	ALBEDO=mix(vec3(0.075,0.17,0.19),vec3(0.13,0.245,0.26),tone);
	ROUGHNESS=mix(0.62,0.76,tone);
	METALLIC=0.0;
	SPECULAR=0.10;
	vec2 slope=0.52*cos(phase_a)*vec2(0.085,0.031)
		+0.29*cos(phase_b)*vec2(-0.028,0.13)
		+0.10*cos(phase_c)*vec2(0.21,-0.17);
	vec3 tangent_normal=normalize(vec3(-slope.x*2.2,-slope.y*2.2,1.0));
	NORMAL_MAP=tangent_normal*0.5+0.5;
	NORMAL_MAP_DEPTH=0.55;
}
"""
	material.shader = shader
	instance.material_override = material
	add_child(instance)


func _bollard(at: Vector3) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.14
	cylinder.bottom_radius = 0.20
	cylinder.height = 0.70
	cylinder.radial_segments = 12
	var visual := MeshInstance3D.new()
	visual.mesh = cylinder
	visual.material_override = _material("iron")
	visual.position = at + Vector3.UP * 0.35
	add_child(visual)


func _bench(at: Vector3) -> void:
	_box("QuayBenchSeat", at + Vector3.UP * 0.44, Vector3(2.8, 0.10, 0.55), _material("wood"))
	for x: float in [-1.0, 1.0]: _box("QuayBenchSupport", at + Vector3(x, 0.20, 0), Vector3(0.14, 0.4, 0.45), _material("iron"), false)


func _path_border(points: PackedVector3Array) -> void:
	# One ribbon per edge rather than hundreds of individual kerb MeshInstances.
	for side: float in [-1.0, 1.0]:
		var edge := PackedVector3Array()
		for i in points.size():
			var direction := points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]
			var offset := Vector3(direction.z, 0, -direction.x).normalized() * (4.0 * side)
			var at := points[i] + offset + Vector3.UP * 0.025
			var branch := Surface.nearest_segment(_park_cutback, Vector2(at.x, at.z))
			if float(branch.distance) <= 6.0:
				if edge.size() >= 2: Surface.strip(self, "ParkGranitePathEdge", edge, 0.30, _material("cut_stone"))
				edge = PackedVector3Array()
			else:
				edge.append(at)
		if edge.size() >= 2: Surface.strip(self, "ParkGranitePathEdge", edge, 0.30, _material("cut_stone"))


func _park_pavilion() -> void:
	# Small original Victorian-inspired viewing shelter, outside the main ride line.
	var center := Vector3(-174, 17, -182.5)
	for x: float in [-2.0, 2.0]:
		for z: float in [-1.5, 1.5]: _beam("PavilionColumn", center + Vector3(x, 0, z), center + Vector3(x, 3.1, z), 0.08, _material("iron"), true)
	for side: float in [-1.0, 1.0]:
		var roof := _box("PavilionSlateRoof", center + Vector3(side * 1.25, 3.1, 0), Vector3(2.8, 0.14, 4.2), _material("slate"), true)
		roof.add_to_group("pavilion_roofs")
		roof.rotation.z = -side * 0.25
	_bench(center + Vector3(0, 0, -0.8))
