extends RefCounted
## Facility navigation follows authored World route data, not extra save areas.
const HUD = preload("res://game/ui/hud.gd")

static func run_ui(tree: SceneTree, check: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(viewport)
	var hud := HUD.new()
	viewport.add_child(hud)
	# Deliberately different coordinates prove the cue follows data rather than
	# remembering the production hill location in the presentation layer.
	var entry := Vector3(-243,17,-240)
	var start := entry+Vector3(14,2.5,0)
	var route := {"id":"test_skatepark_access","label":"Summit link",
		"points":PackedVector3Array([start,entry]),"requires_jump":false,
		"map_marker":entry,"map_label":"SUNKEN SKATEPARK","map_kind":"skatepark"}
	var checkpoints := {"royal_exchange":Vector3(-22,0,28),"kelvingrove_park":Vector3(-165,9,-110)}
	hud.set_map_data(checkpoints,[route])
	for size: Vector2i in [Vector2i(1920,1080),Vector2i(960,600),Vector2i(640,480)]:
		viewport.size = size
		var state := {"settings":{"ui_scale":1.4,"reduced_motion":true},"player_position":start}
		hud.update_display(state)
		await _frames(tree,3)
		check.call(hud._prompt.visible and hud._prompt.text == "SUNKEN SKATEPARK  /  Follow the summit link"
			and _all_lines_fit(hud._prompt),
			"skatepark navigation: summit approach shows a complete non-interaction location cue at "+str(size))
		hud.show_map()
		await _frames(tree,6)
		var map: Control = hud._active_route_map
		var markers: Array = map.feature_markers()
		check.call(markers.size() == 1 and markers[0].position == entry and markers[0].label == "SUNKEN SKATEPARK"
			and map.checkpoints == checkpoints and Rect2(Vector2.ZERO,map.size).has_point(map.call("_map",entry)),
			"skatepark navigation: authored east entry is mapped separately from preserved district checkpoints at "+str(size))
		var descriptions: Array[Label] = []
		_find_labels(hud._dialog,"The diamond marks",descriptions)
		check.call(descriptions.size() == 1 and _all_lines_fit(descriptions[0])
			and Rect2(Vector2.ZERO,Vector2(size)).encloses(hud._dialog.get_global_rect())
			and hud._scroll.size.y >= 80,
			"skatepark navigation: full facility directions fit the existing scrollable map at "+str(size))
		hud.hide_menu()
		state.player_position = entry
		hud.update_display(state)
		await _frames(tree,2)
		check.call(hud._prompt.text == "SUNKEN SKATEPARK  /  East roll-in to street & bowls"
			and _all_lines_fit(hud._prompt),
			"skatepark navigation: entrance cue describes its ordinary roll-in without adding an interaction at "+str(size))
	for key: String in ["airborne","grinding","manual","wallriding","transition_active","lip_active",
		"skitching","crouching","setup_active","bail_active","powersliding","combo"]:
		var state := {"player_position":start}
		state[key] = 100 if key == "combo" else true
		check.call(hud._route_location_hint(state).is_empty(),
			"skatepark navigation: facility hint yields to the active "+key+" cue")
	for key: String in ["interaction_prompt","challenge_text","caption","sidefeature_status"]:
		var state := {"player_position":start}
		state[key] = "CURRENT ACTIVITY"
		hud.update_display(state)
		check.call(not hud._prompt.text.contains("SUNKEN SKATEPARK"),
			"skatepark navigation: facility cue preserves existing "+key+" priority")
	check.call(hud._route_location_hint({"player_position":start+Vector3(0,0,30)}).is_empty()
		and hud._route_location_hint({}).is_empty(),
		"skatepark navigation: distant or missing positions cannot show an unrelated access cue")
	var closed := route.duplicate(true)
	closed.enabled = false
	hud.set_map_data(checkpoints,[closed])
	check.call(hud._route_location_hint({"player_position":start}).is_empty(),
		"skatepark navigation: unavailable access is never promoted as an open entrance")
	viewport.queue_free()
	await tree.process_frame


static func run_world(tree: SceneTree, game: Node, check: Callable) -> void:
	check.call(game.world.has_method("get_park_skatepark_definition"),
		"skatepark navigation: native World publishes the facility entrance contract")
	if not game.world.has_method("get_park_skatepark_definition"): return
	var definition: Dictionary = game.world.get_park_skatepark_definition()
	check.call(definition.has_all(["id","entry","access_route"]),
		"skatepark navigation: the actual native facility instance supplies its live access data")
	if not definition.has_all(["id","entry","access_route"]): return
	var authored: Dictionary = {}
	for route: Dictionary in game.world.get_route_definitions():
		if route.id == "kelvingrove_summit_skatepark": authored = route
	check.call(not authored.is_empty() and authored.get("map_marker") == definition.get("entry")
		and authored.get("map_kind") == "skatepark" and authored.get("map_label") == "SUNKEN SKATEPARK"
		and authored.get("points") == definition.get("access_route"),
		"skatepark navigation: the live mapped route and marker use the exact authored access/entry")
	if authored.is_empty(): return
	var live: Dictionary = {}
	for route: Dictionary in game.hud._map_routes:
		if route.id == authored.id: live = route
	check.call(live == authored and not game.hud._map_checkpoints.has(definition.id)
		and game.hud._map_checkpoints.size() == game.world.get_district_checkpoints().size(),
		"skatepark navigation: ordinary Main initialization delivers facility data without a new district/save checkpoint")
	var points := PackedVector3Array(authored.points)
	check.call(points.size() > 1 and game.hud._route_location_hint({"player_position":points[0]}).contains("summit link")
		and game.hud._route_location_hint({"player_position":definition.entry}).contains("East roll-in"),
		"skatepark navigation: native authored summit and entrance positions select their proper access cues")
	await tree.process_frame


static func run_rendered(tree: SceneTree, game: Node, check: Callable,
		output: String = "res://.local/skatepark-navigation") -> void:
	if DisplayServer.get_name() == "headless":
		check.call(false,"skatepark navigation render: a real rendering display is required")
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960,600)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var hud := HUD.new()
	viewport.add_child(hud)
	var definition: Dictionary = game.world.get_park_skatepark_definition()
	hud.set_map_data(game.world.get_district_checkpoints(),game.world.get_route_definitions())
	hud.update_display({"settings":{"ui_scale":1.4,"reduced_motion":true},"player_position":game.skater.global_position})
	hud.show_map()
	await _frames(tree,8)
	RenderingServer.force_draw(true,1.0/60.0)
	var map_image := viewport.get_texture().get_image()
	var map: Control = hud._active_route_map
	var at: Vector2 = map.get_global_transform()*Vector2(map.call("_map",definition.entry))
	var orange := 0
	for x in range(roundi(at.x)-5,roundi(at.x)+6):
		for y in range(roundi(at.y)-5,roundi(at.y)+6):
			if x < 0 or y < 0 or x >= map_image.get_width() or y >= map_image.get_height(): continue
			var pixel := map_image.get_pixel(x,y)
			if pixel.r > 0.8 and pixel.g > 0.4 and pixel.g < 0.85 and pixel.b < 0.7: orange += 1
	check.call(orange >= 5 and map.feature_markers().size() == 1,
		"skatepark navigation render: the real facility entry produces a visible orange map diamond")
	DirAccess.make_dir_recursive_absolute(output)
	check.call(map_image.save_png(output.path_join("sunken-skatepark-map.png")) == OK,
		"skatepark navigation render: actual World-data map image is saved for visual review")
	hud.hide_menu()
	hud.update_display({"settings":{"ui_scale":1.4,"reduced_motion":true},"player_position":definition.entry})
	await _frames(tree,4)
	RenderingServer.force_draw(true,1.0/60.0)
	check.call(hud._prompt.visible and _all_lines_fit(hud._prompt)
		and viewport.get_texture().get_image().save_png(output.path_join("sunken-skatepark-entry-cue.png")) == OK,
		"skatepark navigation render: complete east-entry cue is saved without an invented Interact prompt")
	viewport.queue_free()
	await tree.process_frame


static func _all_lines_fit(label: Label) -> bool:
	var lines := label.get_line_count()
	var font: Font = label.get_theme_font("font")
	var height := font.get_height(label.get_theme_font_size("font_size"))*lines
	height += label.get_theme_constant("line_spacing")*maxi(0,lines-1)
	return lines == label.get_visible_line_count() and label.size.y+1.0 >= height \
		and label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING


static func _find_labels(node: Node, text: String, result: Array[Label]) -> void:
	if node is Label and node.text.contains(text): result.append(node)
	for child: Node in node.get_children(): _find_labels(child,text,result)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count: await tree.process_frame
