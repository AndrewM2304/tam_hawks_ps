extends RefCounted
## HUD route availability is reflected by actual drawing, not just route flags.
const HUD = preload("res://game/ui/hud.gd")
const POINTS := {"a":Vector3(-40,2,-15),"b":Vector3(40,2,15)}

static func run_ui(tree: SceneTree, check: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(viewport)
	var hud := HUD.new()
	viewport.add_child(hud)
	for size: Vector2i in [Vector2i(1920,1080),Vector2i(960,600),Vector2i(640,480)]:
		viewport.size = size
		hud.update_display({"settings":{"ui_scale":1.4,"reduced_motion":true},"player_position":Vector3(-35,2,-15)})
		hud.set_map_data(POINTS,_routes(false))
		hud.show_map()
		await _frames(tree,5)
		var map: Control = hud._active_route_map
		var layer: Control = map.get_node("ClosedRoutes")
		var bounds: Rect2 = map.get("_bounds")
		check.call(map.routes.size() == 1 and map.routes[0].id == "main_route"
			and layer.get_meta("routes").size() == 1 and hud._map_availability.text.contains("CLOSED"),
			"route availability: a closed shortcut is removed from bright geometry and gets explicit dashed/status drawing at " + str(size))
		check.call(Rect2(Vector2.ZERO,Vector2(size)).encloses(hud._dialog.get_global_rect())
			and hud._scroll.size.y >= 80 and _all_lines_fit(hud._map_availability),
			"route availability: live map and complete route status fit the supported viewport at " + str(size))
		var revision: int = hud._page_revision
		hud.set_map_data(POINTS,_routes(true))
		await _frames(tree,3)
		check.call(hud._active_route_map == map and hud._page_revision == revision and hud._page == "map"
			and map.routes.size() == 2 and layer.get_meta("routes").is_empty()
			and hud._map_availability.text.contains("OPEN") and map.get("_bounds").is_equal_approx(bounds),
			"route availability: opening the native shortcut updates live bright geometry with stable map bounds/navigation at " + str(size))
		hud.hide_menu()
	viewport.queue_free()
	await tree.process_frame


static func run_rendered(tree: SceneTree, check: Callable, output: String = "res://.local/route-availability") -> void:
	if DisplayServer.get_name() == "headless":
		check.call(false,"route availability render: actual GPU image readback requires a rendering display")
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960,600)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var hud := HUD.new()
	viewport.add_child(hud)
	hud.update_display({"settings":{"ui_scale":1.4,"reduced_motion":true},"player_position":Vector3(-35,2,-15)})
	hud.set_map_data(POINTS,_routes(false))
	hud.show_map()
	await _frames(tree,8)
	await RenderingServer.frame_post_draw
	var closed := viewport.get_texture().get_image()
	var map: Control = hud._active_route_map
	var closed_pixels := _route_pixels(closed,map)
	hud.set_map_data(POINTS,_routes(true))
	await _frames(tree,5)
	await RenderingServer.frame_post_draw
	var open := viewport.get_texture().get_image()
	var open_pixels := _route_pixels(open,map)
	check.call(closed.get_size() == Vector2i(960,600) and open.get_size() == closed.get_size(),
		"route availability render: actual closed/open screenshots have the expected full viewport")
	check.call(closed_pixels.dim > 10 and closed_pixels.bright < 5
		and open_pixels.bright > closed_pixels.bright+20,
		"route availability render: closed shortcut pixels are visibly dim/dashed and become a bright solid accessible line")
	DirAccess.make_dir_recursive_absolute(output)
	check.call(closed.save_png(output.path_join("service-shortcut-closed.png")) == OK
		and open.save_png(output.path_join("service-shortcut-open.png")) == OK,
		"route availability render: actual before/after map frames are saved for visual review")
	print("ROUTE_AVAILABILITY pixels closed=",closed_pixels," open=",open_pixels," output=",output)
	viewport.queue_free()
	await tree.process_frame


static func _routes(enabled: bool) -> Array:
	return [{"id":"main_route","label":"Main route","points":PackedVector3Array([Vector3(-30,2,12),Vector3(30,2,12)]),"requires_jump":false},
		{"id":"service_gate_shortcut","label":"Service cut-through · "+("OPEN" if enabled else "CLOSED"),
		"points":PackedVector3Array([Vector3(-30,2,0),Vector3(0,2,0),Vector3(30,2,0)]),"requires_jump":false,"enabled":enabled}]


static func _route_pixels(image: Image, map: Control) -> Dictionary:
	var from: Vector2 = map.get_global_transform()*Vector2(map.call("_map",Vector3(-22,2,0)))
	var to: Vector2 = map.get_global_transform()*Vector2(map.call("_map",Vector3(-8,2,0)))
	var bright := 0
	var dim := 0
	for x in range(ceili(from.x),floori(to.x)):
		for y in range(roundi(from.y)-3,roundi(from.y)+4):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height(): continue
			var pixel := image.get_pixel(x,y)
			if pixel.g > 0.60 and pixel.r > 0.50: bright += 1
			elif pixel.g > 0.37 and pixel.r > 0.30: dim += 1
	return {"bright":bright,"dim":dim}


static func _all_lines_fit(label: Label) -> bool:
	var lines := label.get_line_count()
	var font: Font = label.get_theme_font("font")
	var height := font.get_height(label.get_theme_font_size("font_size"))*lines
	height += label.get_theme_constant("line_spacing")*maxi(0,lines-1)
	return lines == label.get_visible_line_count() and label.size.y+1.0 >= height \
		and label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count: await tree.process_frame
