extends Node3D
## Original procedural test square. One unit represents approximately one metre.
## Keep geometry and collision together; skating physics belongs to the player.

const SPAWN := Vector3(0.0, 0.8, 12.0)
const FLOOR_SIZE := Vector3(70.0, 0.5, 84.0)
const GrindLineSource = preload("res://game/tricks/grind_line.gd")
const CityArtSource = preload("res://game/levels/city_art.gd")
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
	_build_city()
	_build_street_furniture()
	_build_district_connections()
	_build_george_square()
	_build_central_station()
	_build_barras()
	_city_art.dress_world(self)


func get_spawn_position() -> Vector3:
	return SPAWN


func get_npc_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for at: Vector3 in _city_art.npc_positions:
		positions.append(to_global(at))
	return positions


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
	var at := to_local(world_position)
	if at.x < -42.0:
		return "central_station"
	if at.x > 42.0:
		return "barras"
	if at.z < -48.0:
		return "george_square"
	return "royal_exchange"


func get_district_checkpoints() -> Dictionary:
	return {
		"royal_exchange": to_global(SPAWN),
		"george_square": to_global(Vector3(0.0, 0.8, -70.0)),
		"central_station": to_global(Vector3(-65.0, 0.8, 22.0)),
		"barras": to_global(Vector3(65.0, 0.8, 22.0)),
	}


## Markers are authored here, but rendering/collection belongs to the goal system.
func get_goal_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = [
		{"id": "H", "kind": "letter", "position": Vector3(0.0, 0.9, -20.0), "radius": 1.8},
		{"id": "A", "kind": "letter", "position": Vector3(15.0, 0.9, -106.0), "radius": 1.8},
		{"id": "W", "kind": "letter", "position": Vector3(-94.0, 2.9, -10.0), "radius": 1.8},
		{"id": "K", "kind": "letter", "position": Vector3(88.0, 0.9, 0.0), "radius": 1.8},
		{"id": "S", "kind": "letter", "position": Vector3(-60.0, 0.9, -78.0), "radius": 1.8},
		{"id": "market_1", "kind": "market_item", "position": Vector3(72.0, 0.9, 2.0), "radius": 1.8},
		{"id": "market_2", "kind": "market_item", "position": Vector3(105.0, 0.9, 22.0), "radius": 1.8},
		{"id": "market_3", "kind": "market_item", "position": Vector3(105.0, 0.9, -24.0), "radius": 1.8},
		{"id": "cone", "kind": "interaction", "position": Vector3(14.0, 0.8, -10.0), "radius": 2.4},
		{"id": "secret_recording", "kind": "collectible", "position": Vector3(120.0, 0.9, -33.0), "radius": 1.8},
	]
	for marker: Dictionary in markers:
		marker["position"] = to_global(marker["position"])
	var checkpoints := get_district_checkpoints()
	for id: String in checkpoints:
		markers.append({"id": id, "kind": "district", "position": checkpoints[id], "radius": 3.5})
	return markers


func get_gap_definitions() -> Array[Dictionary]:
	var gaps: Array[Dictionary] = [
		{"id": "exchange_launch", "name": "Exchange Air", "start": Vector3(0.0, 1.5, -12.5), "end": Vector3(0.0, 0.8, -18.0), "radius": 2.2, "points": 300, "airborne_required": true},
		{"id": "central_gap", "name": "Mind The Gap", "start": Vector3(-94.0, 2.4, 1.0), "end": Vector3(-94.0, 2.4, -5.0), "radius": 2.0, "points": 600, "airborne_required": true},
		{"id": "market_hop", "name": "Barras Basket Hop", "start": Vector3(88.0, 0.8, 8.0), "end": Vector3(88.0, 0.8, 2.0), "radius": 2.0, "points": 350, "airborne_required": true},
	]
	for gap: Dictionary in gaps:
		gap["start"] = to_global(gap["start"])
		gap["end"] = to_global(gap["end"])
	return gaps


## Snapshot authored rail tops into world coordinates. Call again after moving
## this level; the returned GrindLine instances deliberately own fixed curves.
func get_grind_lines() -> Array:
	var lines: Array = []
	for rail: Node3D in _rail_authors:
		var local_points: PackedVector3Array = rail.get_meta("grind_points")
		lines.append(GrindLineSource.from_local_points(
			String(rail.get_meta("grind_id")), local_points, rail.global_transform, "rail"))
	return lines


func get_location_name(world_position: Vector3) -> String:
	match get_district_id(world_position):
		"george_square":
			return "GEORGE SQUARE"
		"central_station":
			return "CENTRAL STATION"
		"barras":
			return "THE BARRAS"
	if world_position.x > 7.0 and world_position.z < -5.0:
		return "CONE COURT"
	if world_position.x < -9.0:
		return "TENEMENT RUN"
	if world_position.z < -23.0:
		return "BUCHANAN BANKS"
	if world_position.z > 20.0:
		return "THE WEE WARM-UP"
	return "EXCHANGE SQUARE"


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
	_box(self, "SquareFloor", Vector3(0.0, -0.25, 0.0), FLOOR_SIZE, "paving", true)
	# Paint is slightly above the collision surface and never obstructs wheels.
	_box(self, "CentralPromenade", Vector3(0.0, 0.006, 0.0), Vector3(11.0, 0.01, 78.0), "path")
	_box(self, "CrossPromenade", Vector3(0.0, 0.008, -19.0), Vector3(65.0, 0.01, 9.0), "path")
	for x: float in [-29.0, -20.0, -11.0, 11.0, 20.0, 29.0]:
		_box(self, "PavingJoint", Vector3(x, 0.012, 0.0), Vector3(0.055, 0.012, 80.0), "slate")
	for z: float in [-35.0, -26.0, -17.0, -8.0, 1.0, 10.0, 19.0, 28.0, 37.0]:
		_box(self, "PavingJoint", Vector3(0.0, 0.014, z), Vector3(68.0, 0.012, 0.055), "slate")
	for x: float in [-34.5, 34.5]:
		_wall_z("BoundaryWall", x, -42.0, 42.0, [-22.0, 22.0])
	_wall_x("BoundaryWall", -41.5, -35.0, 35.0, [-20.0, 20.0])
	_wall_x("BoundaryWall", 41.5, -35.0, 35.0, [])
	_label(self, "GroundTitle", "TAM HAWKS", Vector3(0.0, 0.035, 22.0), 80, "cream", Vector3(-90.0, 0.0, 0.0), 0.018)
	_label(self, "GroundSubtitle", "PRO SKATER  /  GLASGOW", Vector3(0.0, 0.037, 24.0), 36, "cream", Vector3(-90.0, 0.0, 0.0), 0.018)
	# Spawn starts on a clear 14 m approach to the central ramp.
	for z: float in [7.0, 3.0, -1.0]:
		_box(self, "ApproachDash", Vector3(0.0, 0.03, z), Vector3(0.18, 0.02, 1.25), "cream")


func _build_skating_lines() -> void:
	# Each wedge is a true convex solid. Central incline: 1.6 m / 8 m = 11.3 degrees.
	_ramp("CentralRamp", Vector3(0.0, 0.0, -8.0), 7.0, 8.0, 1.6, 0.0)
	_ramp("TenementReturnRamp", Vector3(-17.0, 0.0, -11.0), 6.0, 7.0, 1.35, PI)
	_ramp("NorthBank", Vector3(-5.0, 0.0, -33.0), 9.0, 7.0, 1.8, 0.0)
	_ramp("WarmUpBank", Vector3(16.0, 0.0, 24.0), 6.0, 7.0, 1.1, -PI / 2.0)
	for z: float in [-8.0, 13.0]:
		_box(self, "LowSkateLedge", Vector3(-11.5, 0.24, z), Vector3(1.25, 0.48, 7.0), "stone", true)
		_box(self, "LedgeCap", Vector3(-11.5, 0.495, z), Vector3(1.35, 0.03, 7.1), "cream")
	_box(self, "EastLedge", Vector3(22.0, 0.28, 2.0), Vector3(7.0, 0.56, 1.3), "stone", true)
	_box(self, "EastLedgeCap", Vector3(22.0, 0.575, 2.0), Vector3(7.1, 0.03, 1.4), "cream")
	# Rail tops and their geometry share one local coordinate system. The
	# controller acquires these lines explicitly; unrelated ledges stay solid.
	_rail("Grind_Rail_Exchange", Vector3(12.0, 0.0, 9.0), 7.5)
	_rail("Grind_Rail_Tenement", Vector3(-26.0, 0.0, -22.0), 8.0)
	_label(self, "RailApproachHint", "OLLIE ON / HOLD GRIND", Vector3(12.0, 0.04, 17.0), 28, "cream", Vector3(-90.0, 0.0, 0.0), 0.012)
	for z: float in [15.0, 14.0]:
		_box(self, "RailApproachDash", Vector3(12.0, 0.03, z), Vector3(0.12, 0.02, 0.5), "coral")


func _ramp(ramp_name: String, at: Vector3, width: float, run: float, rise: float, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = ramp_name
	body.position = at
	body.rotation.y = yaw
	body.add_to_group("skateable_ramps")
	body.set_meta("rise", rise)
	body.set_meta("run", run)
	body.set_meta("width", width)
	body.set_meta("surface_audio", "metal")
	add_child(body)
	var a := Vector3(-width / 2.0, 0.02, run / 2.0)
	var b := Vector3(width / 2.0, 0.02, run / 2.0)
	var c := Vector3(-width / 2.0, rise, -run / 2.0)
	var d := Vector3(width / 2.0, rise, -run / 2.0)
	var e := Vector3(-width / 2.0, 0.0, -run / 2.0)
	var f := Vector3(width / 2.0, 0.0, -run / 2.0)
	var points := PackedVector3Array([a, b, c, d, e, f])
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	# Godot front faces use clockwise winding; preserve outward normals.
	for triangle: Array in [[a, c, b], [b, c, d], [a, e, c], [b, d, f], [c, e, d], [d, e, f], [a, b, e], [b, f, e]]:
		for vertex: Vector3 in triangle:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = _materials["teal"]
	body.add_child(mesh)
	for x: float in [-width / 2.0 + 0.25, width / 2.0 - 0.25]:
		var stripe := _box(body, "RampEdgePaint", Vector3(x, rise / 2.0 + 0.045, 0.0), Vector3(0.1, 0.025, sqrt(run * run + rise * rise)), "cream")
		stripe.rotation.x = atan2(rise - 0.02, run)
	for x: float in [-0.3, 0.3]:
		var direction_mark := _box(body, "RampDirectionPaint", Vector3(x, rise / 2.0 + 0.06, 0.0), Vector3(0.08, 0.025, 1.4), "cream")
		direction_mark.rotation.x = atan2(rise - 0.02, run)


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
	statue.position = Vector3(14.0, 0.0, -15.0)
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
	# Leave real openings through facades at the paired district connectors.
	_building(Vector3(-32.0, 0.0, -47.0), 10.0, 17.0, "stone", "THE WEE PIE CO.", 0.0)
	_building(Vector3(0.0, 0.0, -47.0), 16.0, 21.0, "sandstone", "EXCHANGE HALL", 0.0)
	_building(Vector3(32.0, 0.0, -47.0), 10.0, 18.5, "stone_light", "CLYDE VINYL", 0.0)
	for z: float in [-35.0, 0.0, 35.0]:
		var width := 24.0 if is_zero_approx(z) else 10.0
		_building(Vector3(-41.0, 0.0, z), width, 16.0, "stone", "TENEMENT WORKS", PI / 2.0)
		_building(Vector3(41.0, 0.0, z), width, 17.0, "sandstone", "CONE CULTURE", -PI / 2.0)
	for x: float in [-24.0, -4.0, 16.0, 33.0]:
		_building(Vector3(x, 0.0, 47.0), 17.0, 15.0, "stone_light", "GLASGOW / KEEP ROLLING", PI)
	# Clock tower silhouette anchors the north end without copying a real building.
	_box(self, "ClockTower", Vector3(-5.0, 24.0, -47.0), Vector3(5.0, 9.0, 5.0), "stone", true)
	_box(self, "TowerCornice", Vector3(-5.0, 28.4, -47.0), Vector3(5.8, 0.6, 5.8), "slate")
	_cylinder(self, "TowerSpire", Vector3(-5.0, 31.0, -47.0), 0.0, 3.1, 5.0, "teal")
	_box(self, "ClockFace", Vector3(-5.0, 25.0, -44.46), Vector3(2.7, 2.7, 0.06), "cream")
	_box(self, "ClockHand", Vector3(-5.0, 25.43, -44.40), Vector3(0.13, 1.0, 0.04), "slate")
	var hand := _box(self, "ClockHand", Vector3(-4.66, 24.85, -44.39), Vector3(0.8, 0.13, 0.04), "slate")
	hand.rotation.z = -0.3


func _build_district_connections() -> void:
	# This compressed skating map is original; these are not surveyed streets.
	for x: float in [-20.0, 20.0]:
		_street("GeorgeConnector", Vector3(x, 0.0, -42.0), Vector3(x, 0.0, -55.0))
	for z: float in [-22.0, 22.0]:
		_street("CentralConnector", Vector3(-35.0, 0.0, z), Vector3(-48.0, 0.0, z))
		_street("BarrasConnector", Vector3(35.0, 0.0, z), Vector3(48.0, 0.0, z))
	for x: float in [-88.0, 88.0]:
		_street("NorthShortcut", Vector3(x, 0.0, -42.0), Vector3(x, 0.0, -78.0))
		_street("NorthShortcut", Vector3(x, 0.0, -78.0), Vector3(signf(x) * 35.0, 0.0, -78.0))
		# The corner square bridges the two orthogonal road footprints.
		_box(self, "ShortcutCorner", Vector3(x, -0.25, -78.0), Vector3(12.0, 0.5, 12.0), "paving", true)
	_ground_label("GeorgeWayfinding", "GEORGE SQUARE", Vector3(20.0, 0.04, -38.0), 0.0)
	_ground_label("CentralWayfinding", "CENTRAL STATION", Vector3(-29.0, 0.04, 22.0), PI / 2.0)
	_ground_label("BarrasWayfinding", "THE BARRAS", Vector3(29.0, 0.04, 22.0), -PI / 2.0)
	_ground_label("ShortcutWayfinding", "THE BACK LANES", Vector3(-60.0, 0.04, -78.0), PI / 2.0)


func _build_george_square() -> void:
	_box(self, "GeorgeSquareFloor", Vector3(0.0, -0.25, -90.0), Vector3(70.0, 0.5, 70.0), "path", true)
	_wall_x("GeorgeBoundary", -124.5, -35.0, 35.0, [])
	_wall_x("GeorgeBoundary", -55.5, -35.0, 35.0, [-20.0, 20.0])
	for x: float in [-34.5, 34.5]:
		_wall_z("GeorgeBoundary", x, -125.0, -55.0, [-78.0])
	_ground_label("GeorgeTitle", "GEORGE SQUARE", Vector3(0.0, 0.04, -66.0), 0.0)
	# An open civic loop with broad sightlines, modest learning banks and ledges.
	_ramp("GeorgeLearningBank", Vector3(-15.0, 0.0, -90.0), 8.0, 10.0, 1.1, 0.0)
	_ramp("GeorgeReturnBank", Vector3(15.0, 0.0, -90.0), 8.0, 10.0, 1.1, PI)
	_rail("Grind_Rail_George", Vector3(22.0, 0.0, -106.0), 12.0)
	for x: float in [-8.0, 8.0]:
		_box(self, "GeorgeLowLedge", Vector3(x, 0.22, -108.0), Vector3(1.1, 0.44, 9.0), "stone", true)
	for x: float in [-26.0, 26.0]:
		_box(self, "CivicPlanter", Vector3(x, 0.35, -94.0), Vector3(5.0, 0.7, 6.0), "stone", true)
		_cylinder(self, "CivicTree", Vector3(x, 3.0, -94.0), 0.3, 1.8, 4.0, "teal")
	_building(Vector3(0.0, 0.0, -131.0), 62.0, 19.0, "stone_light", "CIVIC CHAMBERS", 0.0)
	# Civic portico silhouette is deliberately an original composition.
	for x: float in [-9.0, -3.0, 3.0, 9.0]:
		_cylinder(self, "CivicColumn", Vector3(x, 4.0, -123.0), 0.6, 0.75, 8.0, "stone_light")
	_box(self, "CivicPortico", Vector3(0.0, 8.25, -122.5), Vector3(24.0, 0.8, 5.0), "stone", false)


func _build_central_station() -> void:
	_box(self, "CentralStationFloor", Vector3(-88.0, -0.25, 0.0), Vector3(80.0, 0.5, 84.0), "paving", true)
	_wall_z("CentralBoundary", -127.5, -42.0, 42.0, [])
	_wall_z("CentralBoundary", -48.5, -42.0, 42.0, [-22.0, 22.0])
	_wall_x("CentralBoundary", -41.5, -128.0, -48.0, [-88.0])
	_wall_x("CentralBoundary", 41.5, -128.0, -48.0, [])
	_ground_label("CentralTitle", "CENTRAL STATION", Vector3(-64.0, 0.04, 28.0), 0.0)
	# Raised platforms have a real 4m break, with a safe floor underneath.
	_ramp("CentralPlatformApproach", Vector3(-94.0, 0.0, 18.0), 12.0, 12.0, 2.0, 0.0)
	_box(self, "CentralPlatformSouth", Vector3(-94.0, 1.0, 6.0), Vector3(12.0, 2.0, 12.0), "stone", true)
	_box(self, "CentralPlatformNorth", Vector3(-94.0, 1.0, -10.0), Vector3(12.0, 2.0, 12.0), "stone", true)
	_ramp("CentralPlatformExit", Vector3(-94.0, 0.0, -22.0), 12.0, 12.0, 2.0, PI)
	_rail("Grind_Rail_CentralPlatform", Vector3(-98.0, 2.0, 6.0), 9.0)
	_rail("Grind_Rail_CentralGround", Vector3(-69.0, 0.0, -5.0), 17.0)
	_box(self, "PlatformGapPaint", Vector3(-94.0, 0.02, -2.0), Vector3(12.0, 0.025, 4.0), "coral")
	_ground_label("PlatformGapHint", "OLLIE / MIND THE GAP", Vector3(-94.0, 2.04, 5.0), 0.0)
	# Broad, high canopy leaves a clear camera corridor above the elevated route.
	for x: float in [-112.0, -76.0]:
		for z: float in [-27.0, -9.0, 9.0, 27.0]:
			_box(self, "CanopyColumn", Vector3(x, 4.0, z), Vector3(0.45, 8.0, 0.45), "slate", true)
	for side: float in [-1.0, 1.0]:
		var roof := _box(self, "StationCanopy", Vector3(-94.0 + side * 9.0, 9.4, 0.0), Vector3(19.0, 0.18, 62.0), "glass")
		roof.rotation.z = -side * 0.16
	for z: float in [-30.0, -15.0, 0.0, 15.0, 30.0]:
		_box(self, "CanopyCrossBeam", Vector3(-94.0, 8.1, z), Vector3(37.0, 0.3, 0.3), "slate")
	_building(Vector3(-134.0, 0.0, 0.0), 72.0, 17.0, "stone", "CENTRAL / KEEP MOVING", PI / 2.0)


func _build_barras() -> void:
	_box(self, "BarrasFloor", Vector3(88.0, -0.25, 0.0), Vector3(80.0, 0.5, 84.0), "paving", true)
	_wall_z("BarrasBoundary", 127.5, -42.0, 42.0, [])
	_wall_z("BarrasBoundary", 48.5, -42.0, 42.0, [-22.0, 22.0])
	_wall_x("BarrasBoundary", -41.5, 48.0, 128.0, [88.0])
	_wall_x("BarrasBoundary", 41.5, 48.0, 128.0, [])
	_ground_label("BarrasTitle", "THE BARRAS", Vector3(64.0, 0.04, 28.0), 0.0)
	for x: float in [70.0, 105.0]:
		for z: float in [-12.0, 12.0]:
			_market_stall(Vector3(x, 0.0, z))
	_ramp("MarketHopBank", Vector3(88.0, 0.0, 11.0), 5.0, 6.0, 0.7, 0.0)
	_box(self, "MarketBasket", Vector3(88.0, 0.26, 5.0), Vector3(2.5, 0.52, 1.0), "stone", true)
	_rail("Grind_Rail_Barras", Vector3(114.0, 0.0, 18.0), 12.0)
	_building(Vector3(108.0, 0.0, -48.0), 32.0, 11.0, "sandstone", "BARROWLANDS / MARKET QUARTER", 0.0)
	_building(Vector3(65.0, 0.0, -48.0), 28.0, 13.0, "stone", "THE MARKET HALL", 0.0)
	# Open south entrance: a hidden court that always has a ground-level exit.
	_box(self, "RecordingAlcoveSide", Vector3(114.0, 1.5, -30.0), Vector3(0.5, 3.0, 16.0), "sandstone", true)
	_box(self, "RecordingAlcoveBack", Vector3(120.0, 1.5, -38.0), Vector3(12.0, 3.0, 0.5), "sandstone", true)
	_label(self, "RecordingHint", "AFTER HOURS", Vector3(120.0, 2.2, -37.7), 34, "cream")


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


func _street(node_name: String, start: Vector3, end: Vector3, width: float = 12.0) -> void:
	var span := end - start
	var center := (start + end) * 0.5
	var size := Vector3(maxf(absf(span.x), width), 0.5, maxf(absf(span.z), width))
	var road := _box(self, node_name, center + Vector3(0.0, -0.25, 0.0), size, "asphalt", true)
	road.set_meta("surface_audio", "asphalt")
	# Ends stay open for turning from the connector into either district.
	if absf(span.x) > absf(span.z):
		for edge: float in [-1.0, 1.0]:
			_box(self, "StreetEdge", center + Vector3(0.0, 0.65, edge * width / 2.0), Vector3(maxf(1.0, size.x - width), 1.3, 0.4), "stone", true)
	else:
		for edge: float in [-1.0, 1.0]:
			_box(self, "StreetEdge", center + Vector3(edge * width / 2.0, 0.65, 0.0), Vector3(0.4, 1.3, maxf(1.0, size.z - width)), "stone", true)


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


func _building(at: Vector3, width: float, height: float, color: String, shop: String, yaw: float) -> void:
	var building := Node3D.new()
	building.name = "TenementFacade"
	building.position = at
	building.rotation.y = yaw
	add_child(building)
	_box(building, "Facade", Vector3(0.0, height / 2.0, 0.0), Vector3(width, height, 12.0), color, true)
	_city_art.decorate_building(building, width, height, color, shop)


func _build_street_furniture() -> void:
	for at: Vector3 in [Vector3(-29.0, 0.0, 8.0), Vector3(28.0, 0.0, 18.0), Vector3(-27.0, 0.0, -32.0), Vector3(27.0, 0.0, -29.0)]:
		_box(self, "Planter", at + Vector3(0.0, 0.5, 0.0), Vector3(3.0, 1.0, 3.0), "stone", true)
		_cylinder(self, "TreeTrunk", at + Vector3(0.0, 2.4, 0.0), 0.22, 0.3, 3.0, "slate")
		_cylinder(self, "TreeCrown", at + Vector3(0.0, 4.8, 0.0), 0.85, 2.2, 3.5, "teal")
	for x: float in [-31.0, 31.0]:
		for z: float in [-20.0, 0.0, 22.0]:
			_cylinder(self, "LampPost", Vector3(x, 2.5, z), 0.07, 0.12, 5.0, "slate")
			_box(self, "LampLantern", Vector3(x, 5.2, z), Vector3(0.45, 0.7, 0.45), "cream")
			_box(self, "LampCap", Vector3(x, 5.62, z), Vector3(0.65, 0.12, 0.65), "slate")
	_box(self, "WelcomeSign", Vector3(-8.0, 1.3, 23.0), Vector3(3.0, 2.6, 0.2), "teal", true)
	_label(self, "WelcomeText", "AYE, YOU CAN\nSKATE HERE.", Vector3(-8.0, 1.45, 23.12), 40, "cream", Vector3.ZERO, 0.012)
	_box(self, "SessionSign", Vector3(8.0, 1.3, 29.0), Vector3(3.0, 2.6, 0.2), "coral", true)
	_label(self, "SessionText", "GOOD LUCK.\nMIND THE CONE.", Vector3(8.0, 1.45, 29.12), 36, "cream", Vector3.ZERO, 0.012)


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


func _label(parent: Node3D, node_name: String, words: String, at: Vector3, font_size: int, color: String, angles: Vector3 = Vector3.ZERO, pixel_size: float = 0.01) -> void:
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
