extends Node3D
## Original procedural test square. One unit represents approximately one metre.
## Keep geometry and collision together; skating physics belongs to the player.

const SPAWN := Vector3(0.0, 0.8, 12.0)
const FLOOR_SIZE := Vector3(70.0, 0.5, 84.0)
const PALETTE := {
	"stone": Color("b99777"),
	"stone_light": Color("d5b99b"),
	"sandstone": Color("b0775c"),
	"slate": Color("3c4f59"),
	"teal": Color("357a7a"),
	"coral": Color("df7353"),
	"cream": Color("f5dec0"),
	"paving": Color("778087"),
	"path": Color("a4aaa5"),
	"glass": Color("7ea5ab"),
	"bronze": Color("3e6767"),
	"orange": Color("f5883c"),
}

var _materials: Dictionary = {}


func _ready() -> void:
	name = "GlasgowSquare"
	_make_materials()
	_build_lighting()
	_build_floor()
	_build_skating_lines()
	_build_statue()
	_build_city()
	_build_street_furniture()


func get_spawn_position() -> Vector3:
	return SPAWN


func get_location_name(world_position: Vector3) -> String:
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
	for key: String in PALETTE:
		var material := StandardMaterial3D.new()
		material.albedo_color = PALETTE[key]
		material.roughness = 0.95
		material.metallic_specular = 0.2
		_materials[key] = material


func _build_lighting() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("597d99")
	sky_material.sky_horizon_color = Color("c9d5cc")
	sky_material.ground_bottom_color = Color("667579")
	sky_material.ground_horizon_color = Color("c9d5cc")
	sky_material.sun_angle_max = 5.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c7dfeb")
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "LateAfternoonSun"
	sun.rotation_degrees = Vector3(-42.0, -32.0, 0.0)
	sun.light_color = Color("ffe1b5")
	sun.light_energy = 0.75
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
		_box(self, "BoundaryWall", Vector3(x, 0.65, 0.0), Vector3(1.0, 1.3, 84.0), "stone", true)
	for z: float in [-41.5, 41.5]:
		_box(self, "BoundaryWall", Vector3(0.0, 0.65, z), Vector3(70.0, 1.3, 1.0), "stone", true)
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
	# Rail props have ordinary collision only; grinding arrives in M02.
	_rail(Vector3(12.0, 0.0, 9.0), 7.5)
	_rail(Vector3(-26.0, 0.0, -22.0), 8.0)


func _ramp(ramp_name: String, at: Vector3, width: float, run: float, rise: float, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = ramp_name
	body.position = at
	body.rotation.y = yaw
	body.add_to_group("skateable_ramps")
	body.set_meta("rise", rise)
	body.set_meta("run", run)
	body.set_meta("width", width)
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


func _rail(at: Vector3, length: float) -> void:
	_box(self, "RailProp", at + Vector3(0.0, 0.85, 0.0), Vector3(0.14, 0.14, length), "coral", true)
	for z: float in [-length / 2.0 + 0.4, length / 2.0 - 0.4]:
		_box(self, "RailPost", at + Vector3(0.0, 0.42, z), Vector3(0.12, 0.84, 0.12), "slate", true)


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
	_box(statue, "ConeFoot", Vector3(0.0, 6.86, 0.0), Vector3(1.1, 0.12, 1.1), "orange")
	_cylinder(statue, "TrafficCone", Vector3(0.0, 7.42, 0.0), 0.0, 0.5, 1.05, "orange")
	_cylinder(statue, "ConeReflector", Vector3(0.0, 7.34, 0.0), 0.22, 0.34, 0.24, "cream")


func _build_city() -> void:
	_building(Vector3(-24.0, 0.0, -47.0), 17.0, 17.0, "stone", "THE WEE PIE CO.", 0.0)
	_building(Vector3(-5.0, 0.0, -47.0), 18.0, 21.0, "sandstone", "CLYDE VINYL", 0.0)
	_building(Vector3(15.0, 0.0, -47.0), 19.0, 18.5, "stone_light", "EXCHANGE HALL", 0.0)
	_building(Vector3(33.0, 0.0, -47.0), 14.0, 15.0, "sandstone", "NICE ONE", 0.0)
	for z: float in [-28.0, -8.0, 12.0, 32.0]:
		_building(Vector3(-41.0, 0.0, z), 18.0, 15.0 + absf(z) * 0.12, "stone", "TENEMENT WORKS" if z < 0.0 else "PURE DEAD BRAW", PI / 2.0)
		_building(Vector3(41.0, 0.0, z), 18.0, 16.0 + absf(z) * 0.1, "sandstone", "CONE CULTURE" if z < 0.0 else "THE LATE BUS", -PI / 2.0)
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


func _building(at: Vector3, width: float, height: float, color: String, shop: String, yaw: float) -> void:
	var building := Node3D.new()
	building.name = "TenementFacade"
	building.position = at
	building.rotation.y = yaw
	add_child(building)
	_box(building, "Facade", Vector3(0.0, height / 2.0, 0.0), Vector3(width, height, 12.0), color, true)
	_box(building, "Foundation", Vector3(0.0, 0.7, 6.04), Vector3(width + 0.1, 1.4, 0.16), "slate")
	_box(building, "Roof", Vector3(0.0, height + 0.25, 0.0), Vector3(width + 0.6, 0.5, 12.5), "slate")
	_box(building, "Cornice", Vector3(0.0, height - 0.6, 6.1), Vector3(width + 0.3, 0.35, 0.4), "stone_light")
	_box(building, "ShopSign", Vector3(0.0, 3.0, 6.12), Vector3(width - 1.0, 1.0, 0.18), "teal")
	_label(building, "ShopName", shop, Vector3(0.0, 3.05, 6.24), 45, "cream", Vector3.ZERO, 0.014)
	var columns := maxi(3, int(width / 3.5))
	var floors := maxi(2, int((height - 4.0) / 3.2))
	for row: int in range(floors):
		var y := 5.2 + float(row) * 3.1
		_box(building, "StringCourse", Vector3(0.0, y - 1.3, 6.08), Vector3(width, 0.16, 0.25), "stone_light")
		for column: int in range(columns):
			var x := (float(column) - float(columns - 1) / 2.0) * (width - 2.2) / float(columns)
			_box(building, "WindowFrame", Vector3(x, y, 6.13), Vector3(1.65, 2.1, 0.15), "slate")
			_box(building, "WindowGlass", Vector3(x, y, 6.22), Vector3(1.34, 1.8, 0.04), "glass")
			_box(building, "WindowMullion", Vector3(x, y, 6.26), Vector3(0.09, 1.8, 0.04), "stone_light")
			_box(building, "WindowSill", Vector3(x, y - 1.1, 6.25), Vector3(1.95, 0.18, 0.32), "stone_light")
	for x: float in [-width * 0.3, width * 0.3]:
		_box(building, "ShopWindow", Vector3(x, 1.25, 6.17), Vector3(width * 0.25, 1.9, 0.1), "glass")
	_box(building, "ShopDoor", Vector3(0.0, 1.2, 6.2), Vector3(1.35, 2.4, 0.12), "slate")
	for x: float in [-width * 0.33, width * 0.33]:
		_box(building, "Chimney", Vector3(x, height + 1.0, -1.5), Vector3(1.5, 2.0, 1.5), color)


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
