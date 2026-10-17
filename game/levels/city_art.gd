extends Node3D
## Original, locally generated Glasgow architectural character.
## This layer has no collision or gameplay ownership. No source imagery/assets.

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
	var roof_glass := _plain(Color(0.42, 0.55, 0.58, 0.33), 0.26)
	roof_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roof_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials["roof_glass"] = roof_glass
	_shared_materials = materials
	return materials


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
			if y % course < 2 or shifted % block_width < 2:
				value = 0.42 + grain * 0.08
			elif y % course < 4 or shifted % block_width < 4:
				value *= 0.9
			bitmap.set_pixel(x, y, Color(value, value, value))
	bitmap.generate_mipmaps()
	return ImageTexture.create_from_image(bitmap)


func decorate_building(building: Node3D, width: float, height: float, stone: String, shop: String) -> void:
	# Window recesses have dark backplanes and separate raised surrounds. Repeated
	# identical pieces are batched per facade/material/size rather than one node each.
	var batches: Dictionary = {}
	_batch_box(batches, "slate", Vector3(width + 0.1, 1.0, 0.25), Vector3(0, 0.5, 6.08))
	for step: int in range(3):
		_batch_box(batches, "stone_light", Vector3(width + 0.3 + step * 0.18, 0.17, 0.4 + step * 0.17), Vector3(0, height - 0.45 + step * 0.17, 6.1))
	var columns := maxi(3, int(width / 3.3))
	var floors := maxi(2, int((height - 4.3) / 3.2))
	for row: int in range(floors):
		var y := 5.25 + row * 3.2
		_batch_box(batches, stone, Vector3(width, 0.13, 0.3), Vector3(0, y - 1.38, 6.1))
		for column: int in range(columns):
			var x := (float(column) - float(columns - 1) / 2.0) * (width - 2.0) / float(columns)
			_batch_box(batches, "window_shadow", Vector3(1.85, 2.4, 0.06), Vector3(x, y, 6.02))
			_batch_box(batches, "glass", Vector3(1.45, 2.04, 0.04), Vector3(x, y, 6.065))
			for side: float in [-1.0, 1.0]:
				_batch_box(batches, "stone_light", Vector3(0.19, 2.45, 0.23), Vector3(x + side * 0.88, y, 6.17))
				_batch_box(batches, "window_frame", Vector3(0.055, 2.05, 0.08), Vector3(x + side * 0.73, y, 6.11))
			_batch_box(batches, "window_frame", Vector3(0.055, 2.06, 0.08), Vector3(x, y, 6.12))
			_batch_box(batches, "window_frame", Vector3(1.48, 0.07, 0.08), Vector3(x, y + 0.08, 6.12))
			_batch_box(batches, "stone_light", Vector3(2.12, 0.2, 0.42), Vector3(x, y - 1.25, 6.2))
			_batch_box(batches, "stone_light", Vector3(2.03, 0.24, 0.28), Vector3(x, y + 1.25, 6.16))
			_batch_box(batches, "window_reflection", Vector3(0.15, 1.95, 0.012), Vector3(x + 0.45, y, 6.095))
			if row == 0 and column % 2 == 0:
				_pediment(building, Vector3(x, y + 1.4, 6.1), 2.25, 0.42, 0.35, materials["stone_light"])
	# Short signboards and glazed shop bays maintain believable shop scale.
	var shop_bays := maxi(2, int(width / 5.0))
	var bay_width := (width - 1.0) / float(shop_bays)
	for bay: int in range(shop_bays):
		var x := (float(bay) - float(shop_bays - 1) / 2.0) * bay_width
		_batch_box(batches, "window_shadow", Vector3(bay_width - 0.3, 2.5, 0.08), Vector3(x, 1.7, 6.1))
		_batch_box(batches, "glass", Vector3(bay_width - 0.65, 2.1, 0.06), Vector3(x, 1.7, 6.15))
		_batch_box(batches, "teal", Vector3(bay_width - 0.15, 0.7, 0.32), Vector3(x, 3.22, 6.18))
		_batch_box(batches, "stone_light", Vector3(0.23, 3.35, 0.4), Vector3(x - bay_width / 2.0, 1.67, 6.2))
		_batch_box(batches, "window_frame", Vector3(0.09, 2.2, 0.08), Vector3(x, 1.7, 6.21))
		_batch_box(batches, "wood", Vector3(bay_width - 0.4, 0.36, 0.14), Vector3(x, 0.55, 6.2))
	_label(building, shop, Vector3(0, 3.24, 6.38), mini(40, int(660.0 / maxf(12.0, shop.length()))), 0.013)
	_flush_batches(building, batches)
	# Pitched slate roof, ridge, drainpipes and rounded chimney pots break the box silhouette.
	for side: float in [-1.0, 1.0]:
		var roof := _box(building, Vector3(width + 0.9, 0.22, 6.75), Vector3(0, height + 1.22, side * 3.12), materials["slate"])
		roof.rotation.x = side * atan2(2.5, 6.25)
	_box(building, Vector3(width + 1.0, 0.25, 0.3), Vector3(0, height + 2.5, 0), materials["slate"])
	for side: float in [-1.0, 1.0]:
		_cylinder(building, Vector3(side * (width / 2.0 - 0.22), height / 2.0, 6.32), 0.065, height, materials["iron"])
		_box(building, Vector3(1.15, 2.7, 1.25), Vector3(side * width * 0.32, height + 2.0, -1.1), materials[stone])
		for pot: float in [-0.3, 0.3]:
			_cylinder(building, Vector3(side * width * 0.32 + pot, height + 3.65, -1.1), 0.17, 0.6, materials["sandstone"])


func dress_world(world: Node3D) -> void:
	# Hide only obsolete visual meshes; collision and authoring nodes stay intact.
	_hide_named_meshes(world, ["TreeCrown", "CivicTree", "StationCanopy", "ClockTower", "TowerSpire", "ClockFace", "ClockHand", "TowerCornice", "CivicPortico", "CivicColumn", "StallAwning", "StallPole", "StallCounter"])
	for at: Vector3 in [Vector3(-29, 0, 8), Vector3(28, 0, 18), Vector3(-27, 0, -32), Vector3(27, 0, -29), Vector3(-26, 0, -94), Vector3(26, 0, -94)]:
		_tree(at)
	_gallery_portico(Vector3(0, 0, -40.9), 14.0, 5.0)
	_civic_clock()
	_station_arches()
	_market_venue()
	for child in world.get_children():
		if child.get_meta("market_stall", false):
			_dress_market_stall(child)
	_npc(Vector3(28, 0, 31), Color("596e78"), 0.4)
	_npc(Vector3(-27, 0, -113), Color("766354"), -0.6)
	_npc(Vector3(-120, 0, 28), Color("6b5866"), 1.2)
	_npc(Vector3(119, 0, 29), Color("a78e57"), -0.3)
	# A quiet horizon ground and distant roofs stop the playground floating in sky.
	_box(self, Vector3(900, 0.2, 900), Vector3(0, -0.7, -30), materials["paving"])
	for x: float in [-140.0, -105.0, -70.0, 70.0, 105.0, 140.0]:
		_background_facade(Vector3(x, 0, -145), 32.0, 15.0 + fmod(absf(x), 7.0), 0.0)
	for side: float in [-1.0, 1.0]:
		for z: float in [-27.0, 11.0]:
			_background_facade(Vector3(side * 140.0, 0, z), 36.0, 17.0, -side * PI / 2.0)
		for x: float in [65.0, 103.0]:
			_background_facade(Vector3(side * x, 0, 51), 35.0, 15.0, PI)


func _background_facade(at: Vector3, width: float, height: float, yaw: float) -> void:
	var building := Node3D.new()
	building.position = at
	building.rotation.y = yaw
	add_child(building)
	_box(building, Vector3(width, height, 12), Vector3(0, height / 2.0, 0), materials["sandstone"])
	decorate_building(building, width, height, "sandstone", "")


func _dress_market_stall(stall: Node3D) -> void:
	# Merchandise stays entirely above the original solid counter footprint.
	_box(stall, Vector3(7, 1.2, 3), Vector3(0, 0.6, 0), materials["wood"])
	for x: float in [-3.5, 3.5]:
		for z: float in [-1.5, 1.5]:
			_cylinder(stall, Vector3(x, 1.55, z), 0.055, 3.1, materials["iron"])
	for side: float in [-1.0, 1.0]:
		for stripe: int in range(8):
			var panel := _box(stall, Vector3(1, 0.05, 2.35), Vector3(-3.5 + stripe, 3.08, side * 1.1), materials["coral"] if stripe % 2 else materials["cream"])
			panel.rotation.x = side * 0.17
	for x: float in [-2.6, -0.8, 1.0, 2.6]:
		_box(stall, Vector3(1.15, 0.13, 1.1), Vector3(x, 1.28, 0.1), materials["stone_light"])
		for row: int in range(4):
			var book := _box(stall, Vector3(0.19, 0.38, 0.42), Vector3(x - 0.32 + row * 0.21, 1.52, 0.1), materials["teal"] if row % 2 else materials["coral"])
			book.rotation.z = 0.05


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
	_gallery_portico(Vector3(0, 0, -124.7), 25.0, 8.0)
	var tower := Node3D.new()
	tower.position = Vector3(0, 20, -131)
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
			var start := Vector3(-94 + cos(a) * 18, 8.0 + sin(a) * 5, z)
			var end := Vector3(-94 + cos(b) * 18, 8.0 + sin(b) * 5, z)
			_beam(self, start, end, 0.18, materials["iron"])
	for segment: int in range(12):
		var a := PI * float(segment) / 12.0
		var b := PI * float(segment + 1) / 12.0
		var start := Vector3(-94 + cos(a) * 18, 8.0 + sin(a) * 5, 0)
		var end := Vector3(-94 + cos(b) * 18, 8.0 + sin(b) * 5, 0)
		var pane := _box(self, Vector3(start.distance_to(end), 0.06, 60), (start + end) / 2.0, materials["roof_glass"])
		pane.rotation.z = atan2(end.y - start.y, end.x - start.x)
		_beam(self, start + Vector3(0, 0, -30), start + Vector3(0, 0, 30), 0.1, materials["iron"])
	_label(self, "CENTRAL", Vector3(-94, 6.5, 30.3), 66, 0.035)


func _market_venue() -> void:
	var facade := Node3D.new()
	facade.position = Vector3(108, 0, -41.5)
	add_child(facade)
	_box(facade, Vector3(22, 3.1, 0.5), Vector3(0, 7.5, 0), materials["iron"])
	_label(facade, "BARROWLANDS", Vector3(0, 7.7, 0.3), 70, 0.037)
	_label(facade, "MARKET  /  MUSIC  /  GLASGOW", Vector3(0, 6.6, 0.31), 30, 0.021)
	for x: float in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		_mesh(facade, sphere, Vector3(x, 9.25, 0.2), materials["orange"])
	_box(facade, Vector3(23, 0.25, 2.3), Vector3(0, 4.1, 0.6), materials["coral"])


func _tree(at: Vector3) -> void:
	_cylinder(self, at + Vector3(0, 2.8, 0), 0.19, 4.5, materials["bark"])
	for branch: Vector3 in [Vector3(-1.1, 4.3, 0.2), Vector3(1.0, 4.6, 0.0), Vector3(0.2, 5.6, -0.3), Vector3(0, 4.6, 1.0)]:
		_beam(self, at + Vector3(0, 3.5, 0), at + branch, 0.12, materials["bark"])
		var foliage := SphereMesh.new()
		foliage.radius = 1.3
		foliage.height = 2.3
		foliage.radial_segments = 12
		foliage.rings = 6
		_mesh(self, foliage, at + branch, materials["leaf_light"] if branch.y > 5.0 else materials["leaf"])


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


func _batch_box(batches: Dictionary, material_key: String, size: Vector3, at: Vector3) -> void:
	var key := material_key + str(size)
	if not batches.has(key):
		batches[key] = {"material": material_key, "size": size, "transforms": []}
	batches[key]["transforms"].append(Transform3D(Basis.IDENTITY, at))


func _flush_batches(parent: Node3D, batches: Dictionary) -> void:
	for key: String in batches:
		var batch: Dictionary = batches[key]
		var mesh := BoxMesh.new()
		mesh.size = batch["size"]
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
