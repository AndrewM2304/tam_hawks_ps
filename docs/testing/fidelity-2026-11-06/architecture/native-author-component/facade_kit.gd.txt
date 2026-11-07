extends RefCounted
## Original shallow facade modules. Styles are architectural composites, not
## surveyed shopfronts. All pieces are visual and keep existing collision intact.

const SHOP_NAMES: Array[String] = ["CLOSE COFFEE", "CLYDE VINYL", "NORTHSIDE BOOKS", "THE WEE PIE CO."]
const SHOP_PAINT: Array[String] = ["shop_green", "shop_burgundy", "shop_navy", "shop_umber"]
const FacadeShell = preload("res://game/levels/art/facade_shell.gd")
const FacadeBay = preload("res://game/levels/art/facade_bay.gd")


static func decorate(art: Node3D, building: Node3D, width: float, height: float, stone: String, shop: String) -> void:
	var style := _style(building, shop)
	var seed_value := absi(int(building.global_position.x * 7.0 + building.global_position.z * 11.0))
	var batches: Dictionary = {}
	var facade_stone := "warehouse_brick" if style == "market" else stone
	var recessed := _recolor_wall(art, building, facade_stone, width, height, style, shop)
	art._batch_box(batches, "slate", Vector3(width, 0.55, 0.18), Vector3(0, 0.275, 6.08))
	var bay_spacing := 3.6 if style == "civic" else (4.2 if style == "market" else 3.25)
	var columns := maxi(3, int(width / bay_spacing))
	var actual_spacing := (width - 1.6) / float(columns)
	var floors := maxi(2, int((height - 4.25) / 3.2))
	var fitted := bool(building.get_meta(FacadeBay.META, false))
	for row: int in range(floors):
		var y := 5.25 + row * 3.2
		if style != "market" or row == 0:
			art._batch_box(batches, "cut_stone", Vector3(width, 0.13, 0.25), Vector3(0, y - 1.43, 6.1))
		for column: int in range(columns):
			var x := (float(column) - float(columns - 1) / 2.0) * actual_spacing
			var projection := 0.0
			var opening_width := 1.8 if style in ["market", "station"] else 1.45
			var opening_height := 1.8 if row == floors - 1 else 2.1
			# Remove complete crossing groups, including their sill/pediment.
			# Splitting a window around the imported strip would leave fragments.
			var group_width := maxf(opening_width + 0.6, 2.18)
			if fitted and FacadeBay.overlaps(x, group_width):
				var report: Dictionary = building.get_meta(FacadeBay.REPORT)
				report.omitted_window_groups += 1
				continue
			_window(art, batches, x, y, opening_width, opening_height, projection, style, (seed_value + column + row * 3) % 5, recessed)
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
	FacadeBay.filter_front(batches, building)
	_roof(art, building, batches, width, height, facade_stone, style, seed_value)
	_return_windows(art, batches, width, floors, style, recessed)
	art._flush_batches(building, batches)


static func _return_windows(art: Node3D, batches: Dictionary, width: float, floors: int, style: String, recessed: bool) -> void:
	# Exposed ends face the linked streets. Reuse the facade's existing batches
	# so a side elevation is an authored return rather than a blank giant box.
	for side: float in [-1.0, 1.0]:
		var local_batches: Dictionary = {}
		for floor_index: int in range(floors):
			for column: int in range(3):
				_window(art, local_batches, float(column - 1) * 3.2,
					5.25 + floor_index * 3.2, 1.3, 1.9, 0, style, (column + floor_index) % 5, recessed)
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


static func _recolor_wall(art: Node3D, building: Node3D, material_key: String,
		width: float, height: float, style: String, shop: String) -> bool:
	var recessed := false
	for child: Node in building.get_children():
		if child.get_meta("art_label", "") == "Facade":
			for geometry: Node in child.get_children():
				if not geometry is MeshInstance3D:
					continue
				geometry.material_override = art.materials[material_key]
				# Arcade depth is changed by the world after this helper. Marked
				# skyline masses are extended by HorizonBackground after dressing.
				# Preserve both exact BoxMesh contracts and the separate fitted pilot.
				if not geometry.mesh is BoxMesh or shop == "EXCHANGE ARCADE" \
					or bool(geometry.get_meta("horizon_frontage", false)) \
					or bool(building.get_meta(FacadeBay.META, false)):
					continue
				var box := geometry.mesh as BoxMesh
				var local_frame: Transform3D = building.global_transform.affine_inverse() * geometry.global_transform
				# Construction owns an axis-aligned, unit-scale native wall. Refuse
				# unrelated geometry rather than carve an assumed transformed mass.
				if not local_frame.basis.is_equal_approx(Basis.IDENTITY):
					continue
				var opening_rows := maxi(2, int((height - 4.25) / 3.2))
				var spacing := 3.6 if style == "civic" else (4.2 if style == "market" else 3.25)
				var columns := maxi(3, int(width / spacing))
				var actual_spacing := (width - 1.6) / float(columns)
				var front: Array[Rect2] = []
				var sides: Array[Rect2] = []
				for row: int in range(opening_rows):
					var y := 5.25 + row * 3.2 - local_frame.origin.y
					var opening_width := 1.8 if style in ["market", "station"] else 1.45
					var opening_height := 1.8 if row == opening_rows - 1 else 2.1
					for column: int in range(columns):
						var x := (float(column) - float(columns - 1) / 2.0) * actual_spacing - local_frame.origin.x
						front.append(Rect2(x - opening_width / 2.0, y - opening_height / 2.0, opening_width, opening_height))
					for column: int in range(3):
						var z := float(column - 1) * 3.2 - local_frame.origin.z
						sides.append(Rect2(z - 0.65, y - 0.95, 1.3, 1.9))
				geometry.mesh = FacadeShell.make(box.size, front, sides)
				geometry.set_meta("architectural_recess_shell", true)
				recessed = true
		elif child is MeshInstance3D and child.mesh is BoxMesh and child.position.y > 4.0:
			child.material_override = art.materials[material_key]
	return recessed


static func _window(art: Node3D, batches: Dictionary, x: float, y: float, width: float, height: float,
		projection: float, style: String, variation: int, recessed: bool = false) -> void:
	var wall := 6.0 + projection
	var pane_z := wall - FacadeShell.RECESS_DEPTH if recessed else wall + 0.035
	var frame_z := pane_z + 0.055
	var frame := "iron" if style == "market" else "window_frame"
	var pane := "window_lit" if variation == 2 else ("window_dull" if variation == 4 else "facade_glass")
	# The opaque pane closes the actual aperture. Stone reveals meet the wall,
	# rather than an oversized black plate floating in front of the sandstone.
	art._batch_box(batches, pane, Vector3(width, height, 0.025), Vector3(x, y, pane_z))
	var reveal_depth := maxf(0.12, wall + 0.07 - pane_z)
	for side: float in [-1.0, 1.0]:
		art._batch_box(batches, "cut_stone", Vector3(0.13, height + 0.18, reveal_depth),
			Vector3(x + side * (width / 2.0 + 0.065), y, wall + 0.07 - reveal_depth / 2.0))
		# Separate timber sash stile and deep dressed-stone reveal.
		art._batch_box(batches, frame, Vector3(0.065, height, 0.08), Vector3(x + side * (width / 2.0 - 0.035), y, frame_z))
	for edge: float in [-1.0, 1.0]:
		art._batch_box(batches, frame, Vector3(width, 0.085, 0.09), Vector3(x, y + edge * (height / 2.0 - 0.04), frame_z))
	# A traditional sash meeting rail with a deeper bottom rail. Retail/civic
	# panes avoid the thick repeated white cross; warehouse openings keep fine
	# vertical iron glazing bars and three genuinely distinct lights.
	art._batch_box(batches, frame, Vector3(width, 0.055, 0.095), Vector3(x, y + 0.08, frame_z + 0.01))
	if style in ["station", "market"]:
		for split: float in [-1.0, 1.0]:
			art._batch_box(batches, frame, Vector3(0.025, height, 0.065), Vector3(x + split * width / 6.0, y, frame_z))
	else:
		art._batch_box(batches, frame, Vector3(0.028, height * 0.48, 0.065),
			Vector3(x, y + height * 0.25, frame_z))
	# Full-depth head and a sloped sill have a legible stone profile and drip.
	var head_depth := reveal_depth + 0.13
	art._batch_box(batches, "cut_stone", Vector3(width + 0.40, 0.16, head_depth),
		Vector3(x, y + height / 2.0 + 0.08, wall + 0.20 - head_depth / 2.0))
	if recessed:
		art._batch_box(batches, "cut_stone", Vector3(width + 0.48, 0.065, 0.29),
			Vector3(x, y + height / 2.0 + 0.1925, wall + 0.11))
	# The sloped sill IS the lower reveal: its rear upper edge meets the
	# aperture exactly, and falls toward the outside instead of leaving a gap.
	var sill_depth := wall + 0.38 - pane_z
	var sill_drop := 0.06 * cos(0.08) + sill_depth / 2.0 * sin(0.08)
	art._batch_box(batches, "cut_stone", Vector3(width + 0.48, 0.12, sill_depth),
		Vector3(x, y - height / 2.0 - sill_drop, pane_z + sill_depth / 2.0), Basis.from_euler(Vector3(0.08, 0, 0)))
	if recessed:
		art._batch_box(batches, "cut_stone", Vector3(width + 0.38, 0.055, 0.10),
			Vector3(x, y - height / 2.0 - 0.1775, wall + 0.23))
	if variation == 4:
		# Curtain is behind the sash and wholly inside its aperture.
		art._batch_box(batches, "curtain", Vector3(width * 0.23, height - 0.12, 0.015),
			Vector3(x - width * 0.35, y, pane_z + 0.024))


static func _shops(art: Node3D, building: Node3D, batches: Dictionary, width: float, style: String,
		shop: String, seed_value: int) -> void:
	var bays := maxi(1, int(width / 6.0))
	var bay_width := (width - 0.8) / float(bays)
	var fitted := bool(building.get_meta(FacadeBay.META, false))
	for bay: int in range(bays):
		var x := (float(bay) - float(bays - 1) / 2.0) * bay_width
		if fitted and bay == 1:
			var report: Dictionary = building.get_meta(FacadeBay.REPORT)
			report.omitted_shop_bays += 1
			var fitted_name: String = SHOP_NAMES[(seed_value + bay) % 4]
			art._label(building, fitted_name, Vector3(FacadeBay.MOUNT.x,3.25,6.40),30,0.014)
			continue
		var variant := (seed_value + bay) % 4
		var paint: String = SHOP_PAINT[variant]
		var left := x - bay_width / 2.0 + 0.15
		var display_width := bay_width - 1.75
		var display_x := left + display_width / 2.0
		var door_x := x + bay_width / 2.0 - 0.83
		# The display remains entirely behind the original outer glazing plane.
		# A restrained dark reveal and warm rear wall preserve real 0.46m depth.
		art._batch_box(batches, "window_shadow", Vector3(bay_width - 0.2, 2.9, 0.05), Vector3(x, 1.8, 6.035))
		art._batch_box(batches, "interior_plaster", Vector3(display_width - 0.1, 2.2, 0.035), Vector3(display_x, 1.8, 6.10))
		art._batch_box(batches, "wood", Vector3(display_width - 0.1, 0.10, 0.39), Vector3(display_x, 1.18, 6.33))
		# Fascia and cornice are constructed courses, not one oversized block.
		art._batch_box(batches, paint, Vector3(bay_width - 0.15, 0.49, 0.25), Vector3(x, 3.25, 6.33))
		art._batch_box(batches, paint, Vector3(bay_width - 0.10, 0.065, 0.38), Vector3(x, 3.545, 6.37))
		art._batch_box(batches, "brass", Vector3(bay_width - 0.30, 0.025, 0.025), Vector3(x, 3.48, 6.515))
		art._batch_box(batches, paint, Vector3(bay_width - 0.20, 0.07, 0.30), Vector3(x, 2.97, 6.36))
		art._batch_box(batches, paint, Vector3(display_width + 0.14, 0.55, 0.25), Vector3(display_x, 0.6, 6.32))
		# A recessed kick-panel and fine raised border make the base read as timber.
		art._batch_box(batches, "window_shadow", Vector3(display_width - 0.28, 0.31, 0.012), Vector3(display_x, 0.61, 6.453))
		art._batch_box(batches, paint, Vector3(display_width - 0.34, 0.25, 0.012), Vector3(display_x, 0.61, 6.466))
		art._batch_box(batches, paint, Vector3(display_width + 0.22, 0.065, 0.40), Vector3(display_x, 0.91, 6.35))
		for edge: float in [left - 0.1, left + display_width + 0.11, x + bay_width / 2.0 - 0.03]:
			_shop_pilaster(art, batches, edge, paint)
		if fitted and bay == 2:
			art._batch_box(batches, paint, Vector3(0.12, 3.1, 0.66), Vector3(FacadeBay.STRIP.y + 0.06, 1.75, 6.31))
		_display(art, batches, display_x, display_width, variant, style)
		art._batch_box(batches, "shop_glass", Vector3(display_width - 0.1, 2.1, 0.025), Vector3(display_x, 1.9, 6.58))
		# Fine glazing beads at the actual glass edge; lower opening stays clear.
		for side: float in [-1.0, 1.0]:
			art._batch_box(batches, paint, Vector3(0.035, 2.10, 0.065), Vector3(display_x + side * (display_width / 2.0 - 0.055), 1.9, 6.59))
		art._batch_box(batches, paint, Vector3(display_width, 0.045, 0.075), Vector3(display_x, 2.53, 6.60))
		_door(art, batches, door_x, paint)
		var sign_text: String = SHOP_NAMES[variant]
		if style == "market":
			sign_text = ["RECORDS & REPAIRS", "SECOND HAND", "MARKET BOOKS", "THE OLD WORKSHOP"][variant]
		if bay == 0 and not shop.is_empty() and shop.length() < 22:
			sign_text = shop
		var pixel_size: float = minf(0.014, (bay_width - 0.75) / (float(sign_text.length()) * 18.0))
		art._label(building, sign_text, Vector3(x, 3.25, 6.52), 30, pixel_size)
		if variant == 0 or style == "market":
			art._batch_box(batches, paint, Vector3(bay_width - 0.1, 0.055, 1.1), Vector3(x, 3.77, 6.83), Basis.from_euler(Vector3(0.17, 0, 0)))


static func _shop_pilaster(art: Node3D, batches: Dictionary, x: float, paint: String) -> void:
	art._batch_box(batches, paint, Vector3(0.17, 2.62, 0.38), Vector3(x, 1.76, 6.30))
	art._batch_box(batches, paint, Vector3(0.25, 0.27, 0.47), Vector3(x, 0.47, 6.33))
	art._batch_box(batches, paint, Vector3(0.24, 0.095, 0.47), Vector3(x, 2.99, 6.33))
	art._batch_box(batches, paint, Vector3(0.28, 0.055, 0.52), Vector3(x, 3.065, 6.35))


static func _door(art: Node3D, batches: Dictionary, x: float, paint: String) -> void:
	# Door leaf sits 0.25m behind the shop's outer moulding, with separate
	# stiles, rails and a panel. All leaf centres remain within the existing
	# west-door lift filter's X±0.45/Z>6.15 envelope.
	art._batch_box(batches, "window_shadow", Vector3(1.05, 2.55, 0.045), Vector3(x, 1.62, 6.16))
	for side: float in [-1.0, 1.0]:
		art._batch_box(batches, paint, Vector3(0.10, 2.55, 0.12), Vector3(x + side * 0.44, 1.62, 6.23))
	for rail: Vector2 in [Vector2(0.40,0.11), Vector2(1.26,0.12), Vector2(2.82,0.14)]:
		art._batch_box(batches, paint, Vector3(0.98, rail.y, 0.12), Vector3(x, rail.x, 6.23))
	art._batch_box(batches, "facade_glass", Vector3(0.79, 1.42, 0.025), Vector3(x, 2.04, 6.23))
	art._batch_box(batches, paint, Vector3(0.79, 0.69, 0.045), Vector3(x, 0.83, 6.21))
	for side: float in [-1.0, 1.0]:
		art._batch_box(batches, paint, Vector3(0.035, 0.62, 0.03), Vector3(x + side * 0.34, 0.83, 6.25))
		art._batch_box(batches, paint, Vector3(0.70, 0.035, 0.03), Vector3(x, 0.83 + side * 0.29, 6.25))
	art._batch_box(batches, "brass", Vector3(0.035, 0.32, 0.05), Vector3(x + 0.34, 1.48, 6.33))
	art._batch_box(batches, "brass", Vector3(0.09, 0.38, 0.018), Vector3(x + 0.34, 1.48, 6.29))
	art._batch_box(batches, "cut_stone", Vector3(1.2, 0.13, 0.52), Vector3(x, 0.26, 6.3))


static func _display(art: Node3D, batches: Dictionary, x: float, width: float, variant: int, style: String = "retail") -> void:
	if style == "market" and variant == 3:
		_workshop_display(art, batches, x, width)
	elif variant == 1 or (style == "market" and variant == 0):
		_record_display(art, batches, x, width)
	elif variant == 2:
		_book_display(art, batches, x, width)
	elif variant == 0:
		_cafe_display(art, batches, x, width)
	else:
		_bakery_display(art, batches, x, width)


static func _disc(art: Node3D, batches: Dictionary, material: String, radius: float,
		depth: float, at: Vector3, vertical: bool = false) -> void:
	art._batch_cylinder(batches, material, radius, depth, at)
	if vertical:
		var frames: Array = batches["cylinder:" + material].transforms
		var frame: Transform3D = frames[-1]
		frame.basis = Basis(Vector3.RIGHT, PI / 2.0) * frame.basis
		frames[-1] = frame


static func _record_display(art: Node3D, batches: Dictionary, x: float, width: float) -> void:
	var count := clampi(int(width / 0.62), 3, 4)
	var spacing := (width - 0.5) / float(count)
	for shelf_y: float in [1.35, 1.97]:
		art._batch_box(batches, "wood", Vector3(width - 0.2, 0.055, 0.25), Vector3(x, shelf_y, 6.35))
		for index: int in range(count):
			var record_x := x + (float(index) - float(count - 1) / 2.0) * spacing
			var paper: String = ["shop_burgundy", "cream", "shop_green", "shop_umber"][index % 4]
			var tilt := -0.035 if index % 2 == 0 else 0.025
			art._batch_box(batches, paper, Vector3(0.34, 0.34, 0.025), Vector3(record_x, shelf_y + 0.20, 6.27), Basis.from_euler(Vector3(0,0,tilt)))
			if index == 1:
				_disc(art, batches, "iron", 0.147, 0.016, Vector3(record_x + 0.055, shelf_y + 0.20, 6.31), true)
				_disc(art, batches, "cream", 0.035, 0.018, Vector3(record_x + 0.055, shelf_y + 0.20, 6.325), true)
			else:
				# Original abstract sleeve composition, without copied album art.
				art._batch_box(batches, "cream", Vector3(0.23, 0.014, 0.012), Vector3(record_x, shelf_y + 0.30, 6.29))
				art._batch_box(batches, "iron", Vector3(0.11, 0.17, 0.012), Vector3(record_x + 0.055, shelf_y + 0.19, 6.29))


static func _book_display(art: Node3D, batches: Dictionary, x: float, width: float) -> void:
	var count := clampi(int(width / 0.23), 5, 12)
	var spacing := (width - 0.45) / float(count)
	for shelf_y: float in [1.35, 1.98]:
		art._batch_box(batches, "wood", Vector3(width - 0.2, 0.045, 0.24), Vector3(x, shelf_y, 6.35))
		for index: int in range(count):
			var book_x := x + (float(index) - float(count - 1) / 2.0) * spacing
			var book_height := 0.30 + float((index * 3 + 1) % 5) * 0.032
			var color: String = ["shop_burgundy", "cream", "shop_green", "shop_umber", "shop_navy"][index % 5]
			var lean := -0.12 if index == count - 1 else (0.08 if index == 0 else 0.0)
			var frame := Basis.from_euler(Vector3(0,0,lean))
			art._batch_box(batches, color, Vector3(spacing * 0.70, book_height, 0.14), Vector3(book_x, shelf_y + book_height / 2.0 + 0.025, 6.36), frame)
			if index % 3 == 0:
				art._batch_box(batches, "brass", Vector3(spacing * 0.50, 0.014, 0.012), Vector3(book_x, shelf_y + book_height * 0.75, 6.438), frame)


static func _cup(art: Node3D, batches: Dictionary, x: float, y: float, z: float) -> void:
	_disc(art, batches, "cream", 0.075, 0.15, Vector3(x,y,z))
	_disc(art, batches, "shop_umber", 0.061, 0.008, Vector3(x,y+0.075,z))
	_disc(art, batches, "cream", 0.11, 0.014, Vector3(x,y-0.076,z))
	# A finite open handle, not a detached decorative solid.
	for sign_value: float in [-1.0, 1.0]:
		art._batch_box(batches, "cream", Vector3(0.055,0.018,0.025), Vector3(x+0.085,y+sign_value*0.044,z))
	art._batch_box(batches, "cream", Vector3(0.018,0.088,0.025), Vector3(x+0.111,y,z))


static func _cafe_display(art: Node3D, batches: Dictionary, x: float, width: float) -> void:
	# One lived-in place setting and one hanging light avoid a repeated catalogue
	# of identical cups. All objects stay inside the existing display recess.
	_cup(art, batches, x - minf(width*0.20,0.7), 1.31, 6.34)
	art._batch_box(batches, "iron", Vector3(0.016,0.60,0.016), Vector3(x,2.68,6.30))
	_disc(art, batches, "iron", 0.19, 0.11, Vector3(x,2.34,6.30))
	art._batch_box(batches, "window_lit", Vector3(0.25,0.015,0.20), Vector3(x,2.28,6.30))
	var menu_x := x + minf(width*0.22,0.65)
	art._batch_box(batches, "iron", Vector3(0.42,0.58,0.035), Vector3(menu_x,1.52,6.30), Basis.from_euler(Vector3(0.10,0,0)))
	for row: int in range(4):
		art._batch_box(batches, "cream", Vector3(0.25-float(row%2)*0.05,0.012,0.012), Vector3(menu_x,1.68-float(row)*0.09,6.35))


static func _bakery_display(art: Node3D, batches: Dictionary, x: float, width: float) -> void:
	var count := 3
	art._batch_box(batches, "wood", Vector3(width-0.25,0.055,0.28), Vector3(x,1.30,6.34))
	for index: int in range(count):
		var pie_x := x + (float(index) - float(count-1) / 2.0) * (width-0.45) / float(count)
		_disc(art, batches, "cream", 0.17, 0.015, Vector3(pie_x,1.34,6.34))
		_disc(art, batches, "sandstone", 0.135, 0.085, Vector3(pie_x,1.39,6.34))
		for slash: float in [-1.0,0.0,1.0]:
			art._batch_box(batches, "shop_umber", Vector3(0.012,0.007,0.08), Vector3(pie_x+slash*0.055,1.435,6.34), Basis.from_euler(Vector3(0,0.45,0)))
	art._batch_box(batches, "cream", Vector3(width*0.55,0.40,0.025), Vector3(x,2.12,6.15))
	for row: int in range(3):
		art._batch_box(batches, "shop_umber", Vector3(width*0.36,0.018,0.012), Vector3(x,2.23-row*0.10,6.17))


static func _workshop_display(art: Node3D, batches: Dictionary, x: float, width: float) -> void:
	art._batch_box(batches, "wood", Vector3(width-0.2,0.08,0.28), Vector3(x,1.35,6.34))
	# Repair-radio cases have inset faces, a speaker grille and paired knobs.
	for side: float in [-1.0,1.0]:
		var at_x := x + side * minf(width*0.24,0.65)
		art._batch_box(batches, "shop_umber", Vector3(0.47,0.28,0.19), Vector3(at_x,1.53,6.32))
		art._batch_box(batches, "iron", Vector3(0.29,0.19,0.012), Vector3(at_x-0.05,1.53,6.424))
		for row: int in range(4):
			art._batch_box(batches, "brass", Vector3(0.25,0.008,0.012), Vector3(at_x-0.05,1.47+row*0.04,6.433))
		for knob_y: float in [1.46,1.60]:
			_disc(art, batches, "iron", 0.025, 0.018, Vector3(at_x+0.16,knob_y,6.43), true)


static func _civic_ground(art: Node3D, building: Node3D, batches: Dictionary, width: float) -> void:
	var bays := maxi(3, int(width / 4.5))
	var step := (width - 2.0) / float(bays)
	for index: int in range(bays):
		var x := (float(index) - float(bays - 1) / 2.0) * step
		art._batch_box(batches, "window_shadow", Vector3(2.1, 2.6, 0.08), Vector3(x, 1.8, 6.05))
		art._batch_box(batches, "wood", Vector3(1.75, 2.5, 0.14), Vector3(x, 1.7, 6.17))
		for side: float in [-1.0, 1.0]:
			art._batch_box(batches, "cut_stone", Vector3(0.3, 2.7, 0.42), Vector3(x + side * 1.14, 1.65, 6.25))
			art._batch_box(batches, "facade_glass", Vector3(0.65, 1.25, 0.03), Vector3(x + side * 0.42, 2.0, 6.27))
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
		art._batch_box(batches, "facade_glass", Vector3(step - 1.0, 2.1, 0.05), Vector3(x, 2.0, 6.2))
		for split: float in [-0.3, 0.0, 0.3]:
			art._batch_box(batches, "iron", Vector3(0.08, 2.6, 0.14), Vector3(x + split * step, 1.9, 6.28))
		_arch(art, batches, Vector3(x, 2.8, 6.2), (step - 0.7) / 2.0, "cut_stone")
		if index % 3 == 1:
			art._label(building, "STATION APPROACH", Vector3(x, 1.9, 6.35), 24, minf(0.012, step / 400.0))


static func _arch(art: Node3D, batches: Dictionary, at: Vector3, radius: float, material: String) -> void:
	art._batch_arch(batches, material, radius, at)


static func _roof(art: Node3D, _building: Node3D, batches: Dictionary, width: float, height: float,
		stone: String, style: String, seed_value: int) -> void:
	var front: Dictionary = {}
	for step: int in range(3):
		art._batch_box(front, "cut_stone", Vector3(width + 0.3 + step * 0.16, 0.16, 0.4 + step * 0.15), Vector3(0, height - 0.5 + step * 0.16, 6.1))
	for bracket: int in range(int(width / 0.8)):
		art._batch_box(front, "cut_stone", Vector3(0.18, 0.23, 0.36), Vector3(-width / 2.0 + bracket * 0.8 + 0.4, height - 0.72, 6.2))
	FacadeBay.filter_front(front, _building)
	for key: String in front:
		if not batches.has(key): batches[key] = front[key]
		else: batches[key].transforms.append_array(front[key].transforms)
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
			art._batch_box(batches, "facade_glass", Vector3(1.1, 1.0, 0.06), Vector3(x, height + 1.25, 4.53))
			art._batch_box(batches, "window_frame", Vector3(0.06, 1.0, 0.07), Vector3(x, height + 1.25, 4.58))
			art._batch_prism(batches, "slate", Vector3(2.0, 0.65, 1.6), Vector3(x, height + 1.95, 4))
	elif style == "station" and seed_value % 2 == 0:
		art._batch_prism(batches, "cut_stone", Vector3(minf(width * 0.6, 12), 2.6, 0.65), Vector3(0, height - 0.2, 5.9))
