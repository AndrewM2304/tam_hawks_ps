extends RefCounted
## Original shallow facade modules. Styles are architectural composites, not
## surveyed shopfronts. All pieces are visual and keep existing collision intact.

const SHOP_NAMES: Array[String] = ["CLOSE COFFEE", "CLYDE VINYL", "NORTHSIDE BOOKS", "THE WEE PIE CO."]
const SHOP_PAINT: Array[String] = ["shop_green", "shop_burgundy", "shop_navy", "shop_umber"]


static func decorate(art: Node3D, building: Node3D, width: float, height: float, stone: String, shop: String) -> void:
	var style := _style(building, shop)
	var seed_value := absi(int(building.global_position.x * 7.0 + building.global_position.z * 11.0))
	var batches: Dictionary = {}
	var facade_stone := "warehouse_brick" if style == "market" else stone
	_recolor_wall(art, building, facade_stone)
	art._batch_box(batches, "slate", Vector3(width, 0.55, 0.18), Vector3(0, 0.275, 6.08))
	var bay_spacing := 3.6 if style == "civic" else (4.2 if style == "market" else 3.25)
	var columns := maxi(3, int(width / bay_spacing))
	var actual_spacing := (width - 1.6) / float(columns)
	var floors := maxi(2, int((height - 4.25) / 3.2))
	for row: int in range(floors):
		var y := 5.25 + row * 3.2
		if style != "market" or row == 0:
			art._batch_box(batches, "cut_stone", Vector3(width, 0.13, 0.25), Vector3(0, y - 1.43, 6.1))
		for column: int in range(columns):
			var x := (float(column) - float(columns - 1) / 2.0) * actual_spacing
			var projection := 0.22 if style == "retail" and column % 3 == 1 else 0.0
			var opening_width := 1.8 if style in ["market", "station"] else 1.45
			var opening_height := 1.8 if row == floors - 1 else 2.1
			_window(art, batches, x, y, opening_width, opening_height, projection, style, (seed_value + column + row * 3) % 5)
			if style == "civic" and column % 3 == 0:
				art._batch_box(batches, "cut_stone", Vector3(0.3, 3.05, 0.27), Vector3(x - actual_spacing * 0.5, y, 6.16))
			if row == 0 and (column + seed_value) % 3 == 0 and style == "retail":
				art._batch_prism(batches, "cut_stone", Vector3(2.18, 0.37, 0.35), Vector3(x, y + 1.3, 6.16 + projection))
	# Quoins and restrained facade pilasters establish building edges.
	for side: float in [-1.0, 1.0]:
		for course: int in range(int(height / 0.65)):
			var quoin_width := 0.48 if course % 2 else 0.72
			art._batch_box(batches, "cut_stone", Vector3(quoin_width, 0.6, 0.22), Vector3(side * (width / 2.0 - quoin_width / 2.0), course * 0.65 + 0.3, 6.12))
	if style == "civic":
		_civic_ground(art, building, batches, width)
	elif style == "station":
		_station_ground(art, building, batches, width)
	else:
		_shops(art, building, batches, width, style, shop, seed_value)
	_roof(art, building, batches, width, height, facade_stone, style, seed_value)
	_return_windows(art, batches, width, floors, style)
	art._flush_batches(building, batches)


static func _return_windows(art: Node3D, batches: Dictionary, width: float, floors: int, style: String) -> void:
	# Exposed ends face the linked streets. Reuse the facade's existing batches
	# so a side elevation is an authored return rather than a blank giant box.
	for side: float in [-1.0, 1.0]:
		var local_batches: Dictionary = {}
		for floor_index: int in range(floors):
			for column: int in range(3):
				_window(art, local_batches, float(column - 1) * 3.2,
					5.25 + floor_index * 3.2, 1.3, 1.9, 0, style, (column + floor_index) % 5)
		var transform := Transform3D(Basis(Vector3.UP, side * PI / 2.0), Vector3(side * (width / 2.0 - 6.0), 0, 0))
		for key: String in local_batches:
			if not batches.has(key):
				batches[key] = {"material": local_batches[key].material, "transforms": []}
			for instance: Transform3D in local_batches[key].transforms:
				batches[key].transforms.append(transform * instance)


static func _style(building: Node3D, shop: String) -> String:
	if shop.contains("CIVIC"):
		return "civic"
	if building.global_position.x < -48.0:
		return "station"
	if building.global_position.x > 48.0:
		return "market"
	return "retail"


static func _recolor_wall(art: Node3D, building: Node3D, material_key: String) -> void:
	for child: Node in building.get_children():
		if child.get_meta("art_label", "") == "Facade":
			for geometry: Node in child.get_children():
				if geometry is MeshInstance3D:
					geometry.material_override = art.materials[material_key]
		elif child is MeshInstance3D and child.mesh is BoxMesh and child.position.y > 4.0:
			child.material_override = art.materials[material_key]


static func _window(art: Node3D, batches: Dictionary, x: float, y: float, width: float, height: float,
		projection: float, style: String, variation: int) -> void:
	var z := 6.0 + projection
	art._batch_box(batches, "window_shadow", Vector3(width + 0.5, height + 0.42, 0.14 + projection), Vector3(x, y, 6.04 + projection / 2.0))
	var pane := "window_lit" if variation == 2 else ("window_dull" if variation == 4 else "glass")
	art._batch_box(batches, pane, Vector3(width, height, 0.04), Vector3(x, y, z + 0.13))
	var frame := "iron" if style == "market" else "window_frame"
	for side: float in [-1.0, 1.0]:
		art._batch_box(batches, "cut_stone", Vector3(0.17, height + 0.42, 0.3), Vector3(x + side * (width / 2.0 + 0.18), y, z + 0.2))
		art._batch_box(batches, frame, Vector3(0.055, height, 0.09), Vector3(x + side * width / 2.0, y, z + 0.19))
	art._batch_box(batches, frame, Vector3(0.06, height, 0.09), Vector3(x, y, z + 0.19))
	art._batch_box(batches, frame, Vector3(width, 0.07, 0.09), Vector3(x, y + 0.1, z + 0.19))
	if style in ["market", "station"]:
		art._batch_box(batches, frame, Vector3(width, 0.04, 0.09), Vector3(x, y - 0.5, z + 0.19))
		art._batch_box(batches, frame, Vector3(width, 0.04, 0.09), Vector3(x, y + 0.65, z + 0.19))
	art._batch_box(batches, "cut_stone", Vector3(width + 0.6, 0.18, 0.48), Vector3(x, y - height / 2.0 - 0.15, z + 0.26))
	art._batch_box(batches, "cut_stone", Vector3(width + 0.48, 0.22, 0.3), Vector3(x, y + height / 2.0 + 0.13, z + 0.2))
	if variation == 4:
		art._batch_box(batches, "curtain", Vector3(width * 0.3, height - 0.1, 0.015), Vector3(x - width * 0.32, y, z + 0.16))
	elif variation == 1:
		art._batch_box(batches, "window_reflection", Vector3(width * 0.32, height - 0.1, 0.015), Vector3(x + width * 0.28, y, z + 0.16))


static func _shops(art: Node3D, building: Node3D, batches: Dictionary, width: float, style: String,
		shop: String, seed_value: int) -> void:
	var bays := maxi(1, int(width / 6.0))
	var bay_width := (width - 0.8) / float(bays)
	for bay: int in range(bays):
		var x := (float(bay) - float(bays - 1) / 2.0) * bay_width
		var variant := (seed_value + bay) % 4
		var paint: String = SHOP_PAINT[variant]
		var left := x - bay_width / 2.0 + 0.15
		var display_width := bay_width - 1.75
		var display_x := left + display_width / 2.0
		var door_x := x + bay_width / 2.0 - 0.83
		# The shallow lit display sits in front of the opaque collision facade;
		# a clear outer pane and projecting frame create actual 0.5m depth.
		art._batch_box(batches, "window_shadow", Vector3(bay_width - 0.2, 2.9, 0.08), Vector3(x, 1.8, 6.05))
		art._batch_box(batches, "interior_plaster", Vector3(display_width - 0.1, 2.2, 0.04), Vector3(display_x, 1.8, 6.12))
		art._batch_box(batches, "wood", Vector3(display_width - 0.1, 0.17, 0.4), Vector3(display_x, 1.18, 6.35))
		art._batch_box(batches, paint, Vector3(bay_width - 0.15, 0.63, 0.46), Vector3(x, 3.25, 6.3))
		art._batch_box(batches, "brass", Vector3(bay_width - 0.3, 0.035, 0.035), Vector3(x, 3.48, 6.55))
		art._batch_box(batches, paint, Vector3(display_width + 0.14, 0.55, 0.4), Vector3(display_x, 0.6, 6.32))
		for edge: float in [left - 0.1, left + display_width + 0.11, x + bay_width / 2.0 - 0.03]:
			art._batch_box(batches, paint, Vector3(0.2, 3.1, 0.55), Vector3(edge, 1.75, 6.3))
		# Different shop objects make each frontage legible without an interior level.
		_display(art, batches, display_x, display_width, variant)
		art._batch_box(batches, "shop_glass", Vector3(display_width - 0.1, 2.1, 0.025), Vector3(display_x, 1.9, 6.58))
		art._batch_box(batches, paint, Vector3(1.05, 2.55, 0.17), Vector3(door_x, 1.62, 6.19))
		art._batch_box(batches, "glass", Vector3(0.79, 1.4, 0.035), Vector3(door_x, 2.0, 6.3))
		art._batch_box(batches, "brass", Vector3(0.035, 0.32, 0.05), Vector3(door_x + 0.34, 1.48, 6.33))
		art._batch_box(batches, "cut_stone", Vector3(1.2, 0.13, 0.52), Vector3(door_x, 0.26, 6.3))
		art._batch_box(batches, paint, Vector3(display_width, 0.07, 0.1), Vector3(display_x, 2.45, 6.63))
		var sign_text: String = SHOP_NAMES[variant]
		if style == "market":
			sign_text = ["RECORDS & REPAIRS", "SECOND HAND", "MARKET BOOKS", "THE OLD WORKSHOP"][variant]
		if bay == 0 and not shop.is_empty() and shop.length() < 22:
			sign_text = shop
		var pixel_size: float = minf(0.014, (bay_width - 0.75) / (float(sign_text.length()) * 18.0))
		art._label(building, sign_text, Vector3(x, 3.25, 6.66), 30, pixel_size)
		if variant == 0 or style == "market":
			art._batch_box(batches, paint, Vector3(bay_width - 0.1, 0.055, 1.1), Vector3(x, 3.77, 6.83), Basis.from_euler(Vector3(0.17, 0, 0)))


static func _display(art: Node3D, batches: Dictionary, x: float, width: float, variant: int) -> void:
	if variant in [1, 2]:
		for shelf_y: float in [1.4, 2.0]:
			art._batch_box(batches, "wood", Vector3(width - 0.2, 0.07, 0.22), Vector3(x, shelf_y, 6.37))
			for index: int in range(maxi(4, int(width / 0.28))):
				var book_x := x - width / 2.0 + 0.2 + float(index) * 0.26
				var color: String = ["shop_burgundy", "cream", "shop_green", "shop_umber"][index % 4]
				art._batch_box(batches, color, Vector3(0.19, 0.35 + float(index % 3) * 0.045, 0.12), Vector3(book_x, shelf_y + 0.23, 6.4))
	elif variant == 0:
		for side: float in [-1.0, 1.0]:
			art._batch_box(batches, "cream", Vector3(0.4, 0.22, 0.22), Vector3(x + side * width * 0.25, 1.37, 6.4))
			art._batch_box(batches, "iron", Vector3(0.035, 0.7, 0.035), Vector3(x + side * width * 0.25, 2.65, 6.3))
			art._batch_box(batches, "window_lit", Vector3(0.42, 0.12, 0.22), Vector3(x + side * width * 0.25, 2.32, 6.3))
	else:
		for index: int in range(4):
			art._batch_box(batches, "shop_umber", Vector3(0.45, 0.25, 0.2), Vector3(x - 0.95 + index * 0.63, 1.39, 6.4))
		art._batch_box(batches, "cream", Vector3(width * 0.7, 0.4, 0.02), Vector3(x, 2.13, 6.17))


static func _civic_ground(art: Node3D, building: Node3D, batches: Dictionary, width: float) -> void:
	var bays := maxi(3, int(width / 4.5))
	var step := (width - 2.0) / float(bays)
	for index: int in range(bays):
		var x := (float(index) - float(bays - 1) / 2.0) * step
		art._batch_box(batches, "window_shadow", Vector3(2.1, 2.6, 0.08), Vector3(x, 1.8, 6.05))
		art._batch_box(batches, "wood", Vector3(1.75, 2.5, 0.14), Vector3(x, 1.7, 6.17))
		for side: float in [-1.0, 1.0]:
			art._batch_box(batches, "cut_stone", Vector3(0.3, 2.7, 0.42), Vector3(x + side * 1.14, 1.65, 6.25))
			art._batch_box(batches, "glass", Vector3(0.65, 1.25, 0.03), Vector3(x + side * 0.42, 2.0, 6.27))
		_arch(art, batches, Vector3(x, 2.9, 6.2), 1.15, "cut_stone")
		art._batch_box(batches, "brass", Vector3(0.07, 0.3, 0.05), Vector3(x, 1.55, 6.3))
	art._label(building, "CIVIC CHAMBERS", Vector3(0, 3.85, 6.4), 36, 0.018)


static func _station_ground(art: Node3D, building: Node3D, batches: Dictionary, width: float) -> void:
	var bays := maxi(2, int(width / 6.0))
	var step := (width - 1.5) / float(bays)
	for index: int in range(bays):
		var x := (float(index) - float(bays - 1) / 2.0) * step
		art._batch_box(batches, "window_shadow", Vector3(step - 0.6, 3.1, 0.1), Vector3(x, 1.9, 6.05))
		art._batch_box(batches, "shop_navy", Vector3(step - 0.85, 0.55, 0.3), Vector3(x, 0.6, 6.2))
		art._batch_box(batches, "glass", Vector3(step - 1.0, 2.1, 0.05), Vector3(x, 2.0, 6.2))
		for split: float in [-0.3, 0.0, 0.3]:
			art._batch_box(batches, "iron", Vector3(0.08, 2.6, 0.14), Vector3(x + split * step, 1.9, 6.28))
		_arch(art, batches, Vector3(x, 2.8, 6.2), (step - 0.7) / 2.0, "cut_stone")
		if index % 3 == 1:
			art._label(building, "STATION APPROACH", Vector3(x, 1.9, 6.35), 24, minf(0.012, step / 400.0))


static func _arch(art: Node3D, batches: Dictionary, at: Vector3, radius: float, material: String) -> void:
	art._batch_arch(batches, material, radius, at)


static func _roof(art: Node3D, _building: Node3D, batches: Dictionary, width: float, height: float,
		stone: String, style: String, seed_value: int) -> void:
	for step: int in range(3):
		art._batch_box(batches, "cut_stone", Vector3(width + 0.3 + step * 0.16, 0.16, 0.4 + step * 0.15), Vector3(0, height - 0.5 + step * 0.16, 6.1))
	for bracket: int in range(int(width / 0.8)):
		art._batch_box(batches, "cut_stone", Vector3(0.18, 0.23, 0.36), Vector3(-width / 2.0 + bracket * 0.8 + 0.4, height - 0.72, 6.2))
	if style == "market":
		art._batch_box(batches, stone, Vector3(width, 0.85, 0.55), Vector3(0, height + 0.3, 5.8))
		art._batch_box(batches, "cut_stone", Vector3(width + 0.4, 0.18, 0.75), Vector3(0, height + 0.78, 5.8))
	for side: float in [-1.0, 1.0]:
		art._batch_box(batches, "slate", Vector3(width + 0.9, 0.22, 6.75), Vector3(0, height + 1.22, side * 3.12), Basis.from_euler(Vector3(side * atan2(2.5, 6.25), 0, 0)))
		art._batch_cylinder(batches, "iron", 0.065, height, Vector3(side * (width / 2.0 - 0.22), height / 2.0, 6.32))
		art._batch_box(batches, stone, Vector3(1.15, 2.7, 1.25), Vector3(side * width * 0.32, height + 2, -1.1))
		for pot: float in [-0.3, 0.3]:
			art._batch_cylinder(batches, "sandstone", 0.17, 0.6, Vector3(side * width * 0.32 + pot, height + 3.65, -1.1))
	art._batch_box(batches, "slate", Vector3(width + 1.0, 0.25, 0.3), Vector3(0, height + 2.5, 0))
	if style == "retail":
		for x: float in [-width * 0.27, width * 0.27]:
			art._batch_box(batches, stone, Vector3(1.65, 1.45, 1.2), Vector3(x, height + 1.25, 3.9))
			art._batch_box(batches, "glass", Vector3(1.1, 1.0, 0.06), Vector3(x, height + 1.25, 4.53))
			art._batch_box(batches, "window_frame", Vector3(0.06, 1.0, 0.07), Vector3(x, height + 1.25, 4.58))
			art._batch_prism(batches, "slate", Vector3(2.0, 0.65, 1.6), Vector3(x, height + 1.95, 4))
	elif style == "station" and seed_value % 2 == 0:
		art._batch_prism(batches, "cut_stone", Vector3(minf(width * 0.6, 12), 2.6, 0.65), Vector3(0, height - 0.2, 5.9))
