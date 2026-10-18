extends Node3D
const StaticBatches = preload("res://game/levels/static_batches.gd")
## Original Glasgow architectural composites with inspected CC0 material maps.
## This layer has no collision or gameplay ownership; provenance is in the manifest.

const FacadeKit = preload("res://game/levels/art/facade_kit.gd")
const StreetDressing = preload("res://game/levels/art/street_dressing.gd")
const ArchMesh = preload("res://game/levels/art/arch_mesh.gd")
const FoliageMesh = preload("res://game/levels/art/foliage_mesh.gd")
const MarketArchitecture = preload("res://game/levels/art/barras_market.gd")
const ExchangeGallery = preload("res://game/levels/art/exchange_gallery.gd")
static var _shared_materials: Dictionary = {}
var materials: Dictionary = {}
var npc_positions: Array[Vector3] = []


func make_materials(palette: Dictionary) -> Dictionary:
	if not _shared_materials.is_empty():
		materials = _shared_materials
		return materials
	var masonry := _surface_texture("masonry")
	var paving := _surface_texture("paving")
	var slate := _surface_texture("slate")
	var asphalt := _surface_texture("asphalt")
	for key: String in palette:
		var material := StandardMaterial3D.new()
		material.albedo_color = palette[key]
		material.roughness = 0.88
		material.metallic_specular = 0.28
		if key in ["stone", "stone_light", "sandstone"]:
			_textured(material, masonry, 0.8)
		elif key in ["paving", "path"]:
			_textured(material, paving, 0.65)
		elif key == "slate":
			_textured(material, slate, 0.8)
		elif key == "asphalt":
			_textured(material, asphalt, 1.2)
			material.roughness = 0.93
		elif key == "glass":
			material.roughness = 0.18
			material.metallic = 0.35
		elif key in ["teal", "coral", "bronze"]:
			material.roughness = 0.62
		materials[key] = material
	materials["window_shadow"] = _plain(Color("111d27"), 0.9)
	materials["window_frame"] = _plain(Color("c9c7b7"), 0.68)
	materials["window_reflection"] = _plain(Color("59747e"), 0.27)
	materials["iron"] = _plain(Color("26383e"), 0.48)
	materials["wood"] = _plain(Color("65513f"), 0.9)
	materials["leaf"] = _plain(Color("4e6656"), 1.0)
	materials["leaf_light"] = _plain(Color("63765e"), 1.0)
	materials["bark"] = _plain(Color("4c463c"), 1.0)
	materials["shop_green"] = _plain(Color("284b43"), 0.76)
	materials["shop_burgundy"] = _plain(Color("56333b"), 0.73)
	materials["shop_navy"] = _plain(Color("2e404e"), 0.75)
	materials["shop_umber"] = _plain(Color("755849"), 0.8)
	materials["brass"] = _plain(Color("a69061"), 0.48)
	materials["brass"].metallic = 0.65
	materials["interior_plaster"] = _plain(Color("aaa08a"), 0.95)
	materials["curtain"] = _plain(Color("85867a"), 1.0)
	materials["window_dull"] = _plain(Color("354349"), 0.4)
	materials["window_lit"] = _plain(Color("b8a782"), 0.5)
	materials["window_lit"].emission_enabled = true
	materials["window_lit"].emission = Color("403a27")
	materials["warehouse_brick"] = _plain(Color("826451"), 0.9)
	_textured(materials["warehouse_brick"], masonry, 1.8)
	var shop_glass := _plain(Color(0.43, 0.53, 0.57, 0.18), 0.22)
	shop_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shop_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials["shop_glass"] = shop_glass
	materials["cut_stone"] = materials["stone_light"].duplicate()
	_apply_external_materials()
	var roof_glass := _plain(Color(0.42, 0.55, 0.58, 0.33), 0.26)
	roof_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roof_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials["roof_glass"] = roof_glass
	_shared_materials = materials
	return materials


func _apply_external_materials() -> void:
	# Imported through Godot with tracked 1024px limits/mipmaps. The procedural
	# fallback keeps source inspection possible before an editor import completes.
	const MANIFEST := "res://game/art/assets/zc_textures/manifest.json"
	if not FileAccess.file_exists(MANIFEST):
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not raw is Dictionary or not raw.get("materials") is Dictionary:
		return
	for pair: Array in [["weathered_brick", "warehouse_brick"], ["mineral_concrete", "cut_stone"]]:
		var source: Dictionary = raw.materials.get(pair[0], {})
		var files: Dictionary = source.get("files", {})
		if not files.has_all(["albedo", "normal_opengl"]) or not ResourceLoader.exists(files.albedo) or not ResourceLoader.exists(files.normal_opengl):
			continue
		var albedo := load(String(files.albedo)) as Texture2D
		var normal := load(String(files.normal_opengl)) as Texture2D
		if albedo == null or normal == null:
			continue
		var material: StandardMaterial3D = materials[pair[1]]
		var tile: Array = source.get("authored_tile_size_m", [1.0, 1.0])
		_textured(material, albedo, 1.0 / maxf(0.1, float(tile[0])))
		material.normal_enabled = true
		material.normal_texture = normal
		material.normal_scale = clampf(float(source.get("normal_scale", 0.2)), 0.0, 0.5)
		material.roughness = clampf(float(source.get("roughness", 0.9)), 0.0, 1.0)
		if pair[1] == "warehouse_brick":
			material.albedo_color = Color("dfdbd4")


func _textured(material: StandardMaterial3D, texture: Texture2D, scale_value: float) -> void:
	material.albedo_texture = texture
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * scale_value
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


func _plain(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _surface_texture(kind: String) -> ImageTexture:
	# Repeatable 256px albedo tiles; no downloaded texture or image manipulation.
	var bitmap := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y: int in range(256):
		for x: int in range(256):
			var row: int = y / (32 if kind == "slate" else 64)
			var block_width := 64 if kind == "paving" else 128
			var shifted: int = x + (row % 2) * (block_width / 2)
			var cell_x: int = shifted / block_width
			var grain := float(((x * 73856093) ^ (y * 19349663)) & 255) / 255.0
			var cell_tone := float(((cell_x * 17 + row * 13) % 11)) / 11.0
			var value := 0.62 + grain * 0.08 + cell_tone * 0.1
			var course := 32 if kind == "slate" else 64
			if kind == "asphalt":
				value = 0.72 + grain * 0.22
			elif y % course < 2 or shifted % block_width < 2:
				value = 0.42 + grain * 0.08
			elif y % course < 4 or shifted % block_width < 4:
				value *= 0.9
			bitmap.set_pixel(x, y, Color(value, value, value))
	bitmap.generate_mipmaps()
	return ImageTexture.create_from_image(bitmap)


func decorate_building(building: Node3D, width: float, height: float, stone: String, shop: String) -> void:
	if shop == "EXCHANGE GALLERY":
		ExchangeGallery.adapt_gallery_front(self,building)
		return
	FacadeKit.decorate(self, building, width, height, stone, shop)
	if shop == "TENEMENT WORKS" and building.position.is_equal_approx(Vector3(-41,0,0)):
		ExchangeGallery.align_west_thresholds(building)


func dress_world(world: Node3D) -> void:
	# Geography belongs to world/outdoors. No horizon plane may cover the Clyde.
	_hide_named_meshes(world, ["StallAwning", "StallPole", "StallCounter"])
	for at: Vector3 in [Vector3(-29,0.8,13), Vector3(28,0.8,14), Vector3(-28,2.8,-32), Vector3(28,2.8,-32), Vector3(-13,4.6,-84), Vector3(13,4.6,-84)]:
		_tree(at)
	ExchangeGallery.build(self)
	_civic_clock()
	_station_arches()
	_market_venue()
	MarketArchitecture.build_rows(self)
	StreetDressing.build(self, world)
	for child in world.get_children():
		if child.get_meta("market_stall", false):
			_dress_market_stall(child)
	npc_positions.append(Vector3(28,0,31)) # The interactive busker owns this visible actor.
	_npc(Vector3(-27,6,-116), Color("766354"), -0.6)
	_npc(Vector3(-120,2,28), Color("6b5866"), 1.2)
	_npc(Vector3(123,0,29), Color("847c67"), -0.3)
	# Beyond the civic square, a restrained skyline frames the horizon. Western
	# and southern edges remain open to real park/river terrain and route ports.
	for x: float in [-105.0,-70.0,70.0,105.0]:
		_background_facade(Vector3(x,6,-149), 32.0, 15.0 + fmod(absf(x),7.0), 0.0)
	for z: float in [-24.0,18.0]:
		_background_facade(Vector3(142,0,z), 34, 16, -PI / 2.0)
	_background_facade(Vector3(42,6,-118), 20, 18, -PI / 2.0)

func _background_facade(at: Vector3, width: float, height: float, yaw: float) -> void:
	var building := Node3D.new()
	building.position = at
	building.rotation.y = yaw
	add_child(building)
	var mass := _box(building, Vector3(width, height, 12), Vector3(0, height / 2.0, 0), materials["sandstone"])
	mass.set_meta("horizon_frontage", true)
	decorate_building(building, width, height, "sandstone", "")


func _dress_market_stall(stall: Node3D) -> void:
	MarketArchitecture.dress_stall(self,stall)


func _gallery_portico(at: Vector3, width: float, height: float) -> void:
	var portico := Node3D.new()
	portico.position = at
	add_child(portico)
	for x: float in [-width * 0.38, -width * 0.13, width * 0.13, width * 0.38]:
		_cylinder(portico, Vector3(x, height / 2.0, 0), 0.34, height, materials["stone_light"])
		_cylinder(portico, Vector3(x, 0.2, 0), 0.48, 0.4, materials["stone"])
		_box(portico, Vector3(0.95, 0.35, 0.95), Vector3(x, height, 0), materials["stone_light"])
	_box(portico, Vector3(width, 0.6, 2.2), Vector3(0, height + 0.45, -0.4), materials["stone_light"])
	_pediment(portico, Vector3(0, height + 0.75, 0.5), width + 0.4, 2.1, 2.3, materials["stone"])


func _civic_clock() -> void:
	_gallery_portico(Vector3(0, 6, -127.7), 25.0, 8.0)
	var tower := Node3D.new()
	tower.position = Vector3(0, 26, -134)
	add_child(tower)
	_box(tower, Vector3(7, 8, 7), Vector3(0, 4, 0), materials["stone"])
	for y: float in [0.0, 5.7, 8.0]:
		_box(tower, Vector3(8, 0.45, 8), Vector3(0, y, 0), materials["stone_light"])
	for side: float in [-1.0, 1.0]:
		for x: float in [-2.6, 2.6]:
			_cylinder(tower, Vector3(x, 9.5, side * 2.6), 0.3, 3.0, materials["stone_light"])
	var dome := SphereMesh.new()
	dome.radius = 3.8
	dome.height = 4.6
	dome.radial_segments = 24
	dome.rings = 12
	_mesh(tower, dome, Vector3(0, 11.8, 0), materials["bronze"])
	_cylinder(tower, Vector3(0, 15.0, 0), 0.15, 3.0, materials["bronze"])
	var clock := CylinderMesh.new()
	clock.top_radius = 2.2
	clock.bottom_radius = 2.2
	clock.height = 0.12
	clock.radial_segments = 48
	var clock_face := _mesh(tower, clock, Vector3(0, 4.0, 3.57), materials["cream"])
	clock_face.rotation.x = PI / 2.0
	for hour: int in range(12):
		var angle := TAU * float(hour) / 12.0
		var mark := _box(tower, Vector3(0.1, 0.3, 0.06), Vector3(sin(angle) * 1.8, 4.0 + cos(angle) * 1.8, 3.66), materials["iron"])
		mark.rotation.z = -angle
	_box(tower, Vector3(0.12, 1.5, 0.08), Vector3(0, 4.6, 3.7), materials["iron"])
	var hand := _box(tower, Vector3(1.25, 0.12, 0.08), Vector3(0.5, 3.8, 3.7), materials["iron"])
	hand.rotation.z = -0.35


func _station_arches() -> void:
	for z: float in [-30.0, -20.0, -10.0, 0.0, 10.0, 20.0, 30.0]:
		for segment: int in range(12):
			var a := PI * float(segment) / 12.0
			var b := PI * float(segment + 1) / 12.0
			var start := Vector3(-100 + cos(a) * 24, 12.0 + sin(a) * 5, z)
			var end := Vector3(-100 + cos(b) * 24, 12.0 + sin(b) * 5, z)
			_beam(self, start, end, 0.18, materials["iron"])
	for segment: int in range(12):
		var a := PI * float(segment) / 12.0
		var b := PI * float(segment + 1) / 12.0
		var start := Vector3(-100 + cos(a) * 24, 12.0 + sin(a) * 5, 0)
		var end := Vector3(-100 + cos(b) * 24, 12.0 + sin(b) * 5, 0)
		var pane := _box(self, Vector3(start.distance_to(end), 0.06, 60), (start + end) / 2.0, materials["roof_glass"])
		pane.rotation.z = atan2(end.y - start.y, end.x - start.x)
		_beam(self, start + Vector3(0, 0, -30), start + Vector3(0, 0, 30), 0.1, materials["iron"])


func _market_venue() -> void:
	MarketArchitecture.build_venue(self)


func _tree(at: Vector3) -> void:
	_cylinder(self, at + Vector3(0, 2.8, 0), 0.19, 4.5, materials["bark"])
	for branch: Vector3 in [Vector3(-1.1, 4.3, 0.2), Vector3(1.0, 4.6, 0.0), Vector3(0.2, 5.6, -0.3), Vector3(0, 4.6, 1.0)]:
		_beam(self, at + Vector3(0, 3.5, 0), at + branch, 0.12, materials["bark"])
	var crown := _mesh(self, FoliageMesh.canopy_mesh(), at + Vector3(0, 4.9, 0), FoliageMesh.canopy_material())
	crown.scale = Vector3(2.3, 1.9, 2.2)
	crown.rotation.y = fmod(absf(at.x + at.z), TAU)


func _npc(at: Vector3, coat_color: Color, yaw: float) -> void:
	npc_positions.append(at)
	var person := Node3D.new()
	person.name = "LocalBystander"
	person.position = at
	person.rotation.y = yaw
	add_child(person)
	var coat := _plain(coat_color, 0.95)
	var skin := _plain(Color("ac8770"), 0.95)
	_capsule(person, Vector3(0, 1.12, 0), 0.23, 0.67, coat)
	for side: float in [-1.0, 1.0]:
		_capsule(person, Vector3(side * 0.12, 0.47, 0), 0.095, 0.8, materials["iron"])
		_capsule(person, Vector3(side * 0.31, 1.04, 0), 0.085, 0.65, coat)
		_box(person, Vector3(0.18, 0.12, 0.29), Vector3(side * 0.12, 0.06, 0.06), materials["slate"])
	_capsule(person, Vector3(0, 1.6, 0), 0.145, 0.32, skin)
	_capsule(person, Vector3(0, 1.74, 0), 0.15, 0.15, materials["iron"])


func _capsule(parent: Node3D, at: Vector3, radius: float, height: float, material: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	mesh.radial_segments = 12
	mesh.rings = 6
	_mesh(parent, mesh, at, material)


func _hide_named_meshes(node: Node, names: Array[String]) -> void:
	if String(node.name) in names or String(node.get_meta("art_label", "")) in names:
		_hide_visuals(node)
	else:
		for child in node.get_children():
			_hide_named_meshes(child, names)


func _hide_visuals(node: Node) -> void:
	if node is MeshInstance3D:
		node.visible = false
	for child in node.get_children():
		_hide_visuals(child)


func _batch_box(batches: Dictionary, material_key: String, size: Vector3, at: Vector3, basis: Basis = Basis.IDENTITY) -> void:
	# One unit-box MultiMesh per material. Per-instance transforms carry dimensions
	# and rotation, so window sizes do not multiply draw calls for the same facade.
	var key := material_key
	if not batches.has(key):
		batches[key] = {"material": material_key, "transforms": []}
	batches[key]["transforms"].append(Transform3D(basis * Basis.from_scale(size), at))


func _batch_cylinder(batches: Dictionary, material_key: String, radius: float, height: float, at: Vector3) -> void:
	var key := "cylinder:" + material_key
	if not batches.has(key):
		batches[key] = {"material": material_key, "mesh_kind": "cylinder", "transforms": []}
	batches[key]["transforms"].append(Transform3D(Basis.from_scale(Vector3(radius * 2.0, height, radius * 2.0)), at))


func _batch_prism(batches: Dictionary, material_key: String, size: Vector3, at: Vector3) -> void:
	var key := "prism:" + material_key
	if not batches.has(key):
		batches[key] = {"material": material_key, "mesh_kind": "prism", "transforms": []}
	batches[key]["transforms"].append(Transform3D(Basis.from_scale(size), at + Vector3.UP * size.y / 2.0))


func _batch_arch(batches: Dictionary, material_key: String, radius: float, at: Vector3) -> void:
	var key := "arch:" + material_key
	if not batches.has(key):
		batches[key] = {"material": material_key, "mesh_kind": "arch", "transforms": []}
	batches[key]["transforms"].append(Transform3D(Basis.from_scale(Vector3(radius, radius * 0.52, 0.42)), at))


func _flush_batches(parent: Node3D, batches: Dictionary) -> void:
	set_meta(StaticBatches.META_STATIC_SCOPE, true)
	for key: String in batches:
		var batch: Dictionary = batches[key]
		var mesh: Mesh
		match batch.get("mesh_kind", "box"):
			"arch":
				mesh = ArchMesh.shared_mesh()
			"cylinder":
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.46
				cylinder.bottom_radius = 0.5
				cylinder.height = 1.0
				cylinder.radial_segments = 12
				mesh = cylinder
			"prism":
				var prism := PrismMesh.new()
				prism.size = Vector3.ONE
				mesh = prism
			_:
				var box := BoxMesh.new()
				box.size = Vector3.ONE
				mesh = box
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = batch["transforms"].size()
		for i: int in range(multimesh.instance_count):
			multimesh.set_instance_transform(i, batch["transforms"][i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = materials[batch["material"]]
		parent.add_child(instance)
		StaticBatches.register(instance, batch["transforms"])


func _pediment(parent: Node3D, at: Vector3, width: float, height: float, depth: float, material: Material) -> void:
	var prism := PrismMesh.new()
	prism.size = Vector3(width, height, depth)
	_mesh(parent, prism, at + Vector3(0, height / 2.0, 0), material)


func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, at, material)


func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.92
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	_mesh(parent, mesh, at, material)


func _beam(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 8
	var beam := _mesh(parent, mesh, (start + end) / 2.0, material)
	beam.quaternion = Quaternion(Vector3.UP, (end - start).normalized())


func _label(parent: Node3D, words: String, at: Vector3, font_size: int, pixel_size: float) -> void:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = Color("ddd7c5")
	label.outline_size = 0
	parent.add_child(label)
