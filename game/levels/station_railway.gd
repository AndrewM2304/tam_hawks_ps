extends Node3D
## Original, scenic west-edge railway wing. Explicit preview only until the
## shared performance/stutter admission passes; normal world construction owns
## that switch. No new playable district or collision-bearing moving train.

const TRACK_X := -136.0
const TRACK_Y := 8.36
const OPENING_HALF_LENGTH := 28.0
const TRAIN_HALF_LENGTH := 8.25
const LOOP_START := -52.0
const LOOP_END := 52.0
const TRAIN_SPEED := 8.0
const PORT_HALF_WIDTH := 10.0
const PORT_CEILING_Y := 7.2
const MAX_SURFACES := 8
const MAX_TRIANGLES := 3000
const MAX_MESH_BYTES := 512 * 1024
const MAX_BODIES := 6
const MAX_SHAPES := 20
const MATERIAL_KEYS: Array[String] = ["stone", "cut_stone", "iron", "roof_glass", "shop_green", "glass"]

var train: Node3D
var elapsed := 0.0
var built := false
var report: Dictionary = {}
var _materials: Dictionary = {}
var _static_surfaces: Dictionary = {}
var _train_surfaces: Dictionary = {}
var _unit_box: BoxMesh
var _wheel: CylinderMesh
var _body_count := 0
var _shape_count := 0
var _triangle_count := 0
var _surface_count := 0


func build(world: Node3D, materials: Dictionary = {}) -> Node3D:
	if built:
		return self
	if materials.is_empty():
		materials = world.get("_materials")
	for key: String in MATERIAL_KEYS:
		if not materials.has(key) or not materials[key] is Material:
			push_error("Station railway needs the world's existing material: " + key)
			return self
	_materials = materials
	name = "StationRailway"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_meta("station_railway_preview", true)
	set_meta("performance_admitted", false)
	if get_parent() == null:
		world.add_child(self)
	_unit_box = BoxMesh.new()
	_unit_box.size = Vector3.ONE
	_wheel = CylinderMesh.new()
	_wheel.top_radius = 0.34
	_wheel.bottom_radius = 0.34
	_wheel.height = 0.18
	_wheel.radial_segments = 8
	_wheel.rings = 0
	var removed := _replace_west_facades(world)
	_build_station_wing()
	_build_train()
	_flush(_static_surfaces, self, "Station")
	_flush(_train_surfaces, train, "Coach")
	var title := Label3D.new()
	title.name = "StationRailwayTitle"
	title.text = "CENTRAL STATION\nCONCOURSE & PARK PASSAGE"
	title.position = Vector3(-129.65, 7.68, 0)
	title.rotation.y = PI * 0.5
	title.font_size = 48
	title.pixel_size = 0.004
	title.outline_size = 4
	title.modulate = Color("e8e1cf")
	title.no_depth_test = false
	add_child(title)
	_surface_count += 1
	built = true
	reset_run()
	report = {"surfaces": _surface_count, "triangles": _triangle_count,
		"bodies": _body_count, "shapes": _shape_count, "removed_facades": removed,
		"new_textures": 0, "new_materials": 0, "new_lights": 0,
		"mesh_bytes_estimate": _triangle_count * 3 * 48,
		"moving_collision_bodies": 0, "preview_only": true,
		"budget_pass": _surface_count <= MAX_SURFACES and _triangle_count <= MAX_TRIANGLES
			and _body_count <= MAX_BODIES and _shape_count <= MAX_SHAPES
			and _triangle_count * 3 * 48 <= MAX_MESH_BYTES}
	return self


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not built or not is_finite(delta) or delta <= 0.0:
		return
	elapsed = fposmod(elapsed + delta, (LOOP_END - LOOP_START) / TRAIN_SPEED)
	_place_train()


func reset_run() -> void:
	elapsed = 0.0
	if is_instance_valid(train):
		_place_train()


func status_snapshot() -> Dictionary:
	return {"elapsed": elapsed, "train_position": train.position if is_instance_valid(train) else Vector3.ZERO,
		"fully_inside_tunnel": is_train_concealed(), "loop_seconds": (LOOP_END - LOOP_START) / TRAIN_SPEED,
		"performance_admitted": false, "preview_only": true}


func is_train_concealed() -> bool:
	if not is_instance_valid(train):
		return true
	return train.position.z + TRAIN_HALF_LENGTH <= -OPENING_HALF_LENGTH \
		or train.position.z - TRAIN_HALF_LENGTH >= OPENING_HALF_LENGTH


func _place_train() -> void:
	train.position = Vector3(TRACK_X, TRACK_Y, LOOP_START + elapsed * TRAIN_SPEED)


func _replace_west_facades(world: Node3D) -> int:
	var removed := 0
	for child: Node in world.get_children():
		if not child is Node3D or child == self:
			continue
		var at: Vector3 = child.position
		if absf(at.x + 136.0) > 0.001 or absf(at.y - 2.0) > 0.001 \
				or absf(absf(at.z) - 26.0) > 0.001:
			continue
		var facade := child.get_node_or_null("Facade")
		if not facade is StaticBody3D:
			continue
		world.remove_child(child)
		child.free()
		removed += 1
	return removed


func _build_station_wing() -> void:
	# The same west frontage remains closed and grounded. Only the established
	# central park mouth is open below the elevated railway (Y2 to Y7.2).
	var body := _body("StationRailwayMasonry")
	for side: float in [-1.0, 1.0]:
		_solid(body, Vector3(TRACK_X, 2.6, side * 39), Vector3(12, 11.2, 58), "stone")
		# Concealed tunnel end sections; train wraps behind all five opaque sides.
		_solid(body, Vector3(-130.3, 10.85, side * 48), Vector3(0.6, 5.3, 40), "stone")
		_solid(body, Vector3(TRACK_X, 10.85, side * 67.7), Vector3(12, 5.3, 0.6), "stone")
	# West wall is opaque from the hillside; rails and train stay behind safety
	# glazing on the station side, rather than exposing an unmarked playable gap.
	_solid(body, Vector3(-141.7, 10.85, 0), Vector3(0.6, 5.3, 136), "stone")
	_solid(body, Vector3(TRACK_X, 7.7, 0), Vector3(12, 1.0, 20), "stone")
	_solid(body, Vector3(TRACK_X, 15.25, 0), Vector3(12, 3.5, 136), "stone")
	# Explicit glass collision blocks rail access while letting the scenic train
	# read through the large clerestory. No wallride eligibility on this glazing.
	var glazing := _body("StationRailwayGlazing")
	_solid(glazing, Vector3(-130.25, 10.85, 0), Vector3(0.16, 5.3, 56), "roof_glass")
	_box(_static_surfaces, "cut_stone", Vector3(-129.83, 8.28, 0), Vector3(0.55, 0.16, 56))
	_box(_static_surfaces, "cut_stone", Vector3(-129.83, 13.42, 0), Vector3(0.55, 0.16, 56))
	for z: float in [-28, -14, 0, 14, 28]:
		_box(_static_surfaces, "iron", Vector3(-129.95, 10.85, z), Vector3(0.16, 5.3, 0.16))
	# Track and sleepers are merged at startup. The running rails themselves are
	# scenic, deliberately absent from the skating grind registry.
	for x: float in [-136.85, -135.15]:
		_box(_static_surfaces, "iron", Vector3(x, TRACK_Y - 0.04, 0), Vector3(0.09, 0.12, 132))
	for z: int in range(-65, 66, 2):
		_box(_static_surfaces, "iron", Vector3(TRACK_X, 8.23, z), Vector3(2.5, 0.08, 0.22))
	for side: float in [-1.0, 1.0]:
		_portal(side * OPENING_HALF_LENGTH)
	# Restrained cornice and regular structural piers give the wing a railway
	# composition rather than another generic shop frontage.
	_box(_static_surfaces, "cut_stone", Vector3(-129.8, 17.14, 0), Vector3(0.8, 0.24, 136))
	for z: float in [-59, -43, -27, -11, 11, 27, 43, 59]:
		_box(_static_surfaces, "cut_stone", Vector3(-129.8, 3.1, z), Vector3(0.7, 12.2, 0.7))


func _portal(z: float) -> void:
	for side: float in [-1.0, 1.0]:
		_box(_static_surfaces, "cut_stone", Vector3(TRACK_X + side * 2.7, 8.9, z), Vector3(0.6, 1.4, 0.75))
	for segment: int in range(10):
		var a := PI * float(segment) / 10.0
		var b := PI * float(segment + 1) / 10.0
		var start := Vector3(TRACK_X + cos(a) * 2.7, 9.4 + sin(a) * 3.7, z)
		var finish := Vector3(TRACK_X + cos(b) * 2.7, 9.4 + sin(b) * 3.7, z)
		var direction := finish - start
		var rotation := Basis(Vector3.BACK, atan2(direction.y, direction.x))
		_box(_static_surfaces, "cut_stone", (start + finish) * 0.5, Vector3(direction.length() + 0.07, 0.5, 0.75), rotation)


func _build_train() -> void:
	train = Node3D.new()
	train.name = "ScenicTwoCoachTrain"
	train.set_meta("static_batch_scope", false)
	add_child(train)
	# Two short original coaches, with bevelled driving ends, coherent window
	# rhythm, bogies and a raised roof. No copied operator livery or branding.
	for coach: int in range(2):
		var centre := -3.95 if coach == 0 else 3.95
		_box(_train_surfaces, "iron", Vector3(0, 0.59, centre), Vector3(2.7, 0.34, 7.7))
		_box(_train_surfaces, "shop_green", Vector3(0, 1.76, centre), Vector3(2.62, 2.1, 6.9))
		_box(_train_surfaces, "iron", Vector3(0, 2.9, centre), Vector3(2.5, 0.18, 7.0))
		for side: float in [-1.0, 1.0]:
			for slot: int in range(4):
				_box(_train_surfaces, "glass", Vector3(side * 1.321, 2.08, centre - 2.45 + slot * 1.62), Vector3(0.025, 0.77, 1.2))
			for axle: float in [-2.4, -1.7, 1.7, 2.4]:
				var transform := Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * 1.0, 0.38, centre + axle))
				_emit(_train_surfaces, "iron", _wheel, transform)
		# Selected thin door strips establish a believable side layout without
		# separate transparent windows or additional draw surfaces.
		for side: float in [-1.0, 1.0]:
			_box(_train_surfaces, "iron", Vector3(side * 1.327, 1.65, centre), Vector3(0.03, 1.72, 0.07))
			_box(_train_surfaces, "iron", Vector3(side * 1.327, 0.86, centre), Vector3(0.03, 0.06, 1.2))
	# Driving ends slope inward; four front windows sit on the matching incline.
	for side: float in [-1.0, 1.0]:
		var nose_basis := Basis(Vector3.RIGHT, side * 0.22)
		_box(_train_surfaces, "shop_green", Vector3(0, 1.75, side * 7.47), Vector3(2.60, 2.05, 0.8), nose_basis)
		_box(_train_surfaces, "glass", Vector3(0, 2.12, side * 7.86), Vector3(2.1, 0.64, 0.035), nose_basis)
		_box(_train_surfaces, "iron", Vector3(0, 0.78, side * 7.82), Vector3(1.4, 0.22, 0.18))
	_box(_train_surfaces, "iron", Vector3(0, 0.76, 0), Vector3(0.5, 0.16, 0.38))


func _body(id: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("no_wallride", true)
	body.set_meta("wallride_exclusion_reason", "scenic railway enclosure")
	add_child(body)
	_body_count += 1
	return body


func _solid(body: StaticBody3D, centre: Vector3, size: Vector3, material: String) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.position = centre
	collision.shape = shape
	body.add_child(collision)
	_shape_count += 1
	_box(_static_surfaces, material, centre, size)


func _box(surfaces: Dictionary, material: String, centre: Vector3, size: Vector3, basis: Basis = Basis.IDENTITY) -> void:
	_emit(surfaces, material, _unit_box, Transform3D(basis * Basis.from_scale(size), centre))


func _emit(surfaces: Dictionary, material: String, mesh: Mesh, transform: Transform3D) -> void:
	if not surfaces.has(material):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		surfaces[material] = tool
	var surface: SurfaceTool = surfaces[material]
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var count := indices.size() if not indices.is_empty() else vertices.size()
	var normal_basis := transform.basis.inverse().transposed()
	for index: int in count:
		var source := indices[index] if not indices.is_empty() else index
		var vertex: Vector3 = transform * vertices[source]
		var normal: Vector3 = (normal_basis * normals[source]).normalized()
		surface.set_normal(normal)
		if absf(normal.y) > 0.6:
			surface.set_uv(Vector2(vertex.x, vertex.z))
		elif absf(normal.x) > 0.6:
			surface.set_uv(Vector2(vertex.z, -vertex.y))
		else:
			surface.set_uv(Vector2(vertex.x, -vertex.y))
		surface.add_vertex(vertex)
	_triangle_count += count / 3


func _flush(surfaces: Dictionary, parent: Node3D, prefix: String) -> void:
	for material: String in surfaces:
		var visual := MeshInstance3D.new()
		visual.name = prefix + material.capitalize()
		var surface: SurfaceTool = surfaces[material]
		surface.generate_tangents()
		visual.mesh = surface.commit()
		visual.material_override = _materials[material]
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		parent.add_child(visual)
		_surface_count += 1
	surfaces.clear()
