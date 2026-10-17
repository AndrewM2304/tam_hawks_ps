extends RefCounted
const Quality = preload("res://game/core/graphics_quality.gd")
const Career = preload("res://game/progression/career_progress.gd")
const UIActions = preload("res://tests/ui_integration_tests.gd")

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original: Dictionary = game.career.settings.duplicate(true)
	game.start_mode(true)
	game.skater.set_physics_process(false)
	var camera: Camera3D = game.skater.get_node("ChaseCamera")
	var fov := camera.fov
	var origin: Vector3 = game.skater.global_position
	var nodes := tree.get_node_count()
	for id: String in Quality.IDS:
		game.apply_settings({"graphics_quality":id},false)
		check.call(game.career.settings.graphics_quality==id and is_equal_approx(tree.root.scaling_3d_scale,Quality.profile(id).scale),
			"graphics quality: applying %s changes the real 3D render budget"%id)
		check.call(game.skater.global_position==origin and camera.fov==fov and tree.get_node_count()==nodes,
			"graphics quality: %s preserves position, framing and loaded gameplay nodes"%id)
		var data: Dictionary=game.career._profile_data()
		var validated: Dictionary=Career._validate_profile(data)
		check.call(validated.error==OK and validated.profile.settings.graphics_quality==id,
			"graphics quality: %s round-trips through the existing local profile"%id)
	var legacy: Dictionary=game.career._profile_data()
	legacy.settings.erase("graphics_quality")
	var old: Dictionary=Career._validate_profile(legacy)
	check.call(old.error==OK and old.profile.settings.graphics_quality=="balanced",
		"graphics quality: existing profiles gain Balanced without losing progress or changing version")
	for invalid: Variant in ["ultra",0,null]:
		var bad: Dictionary=game.career._profile_data()
		bad.settings.graphics_quality=invalid
		check.call(Career._validate_profile(bad).error==ERR_FILE_CORRUPT,
			"graphics quality: invalid saved preset is refused safely (%s)"%str(invalid))
	game.apply_settings({"graphics_quality":"unsupported"},false)
	check.call(game.career.settings.graphics_quality=="balanced",
		"graphics quality: a bad live request falls back to a finite Balanced budget")
	game._refresh_hud()
	game.toggle_pause()
	game.hud._show_page("settings")
	await UIActions._frames(tree, 6)
	var button: Button=_quality_button(game.hud._dialog)
	check.call(button!=null and button.text=="GRAPHICS: Balanced",
		"graphics quality: actual Settings page explains the selected preset")
	if button!=null:
		button.grab_focus()
		await UIActions._tap(tree, KEY_ENTER)
		check.call(game.career.settings.graphics_quality=="high" and button.text=="GRAPHICS: High",
			"graphics quality: native Settings button activation changes the saved choice and visible label")
		await _focused_quality_resize(tree, game, button, check)
	game.apply_settings(original,false)
	game.skater.set_physics_process(true)
	game.hud.hide_menu()
	game.start_mode(false)


static func _focused_quality_resize(tree: SceneTree, game: Node, button: Button, check: Callable) -> void:
	var original_size := tree.root.size
	tree.root.size = Vector2i(1280, 800)
	game.apply_settings({"ui_scale": 1.0}, false)
	game._refresh_hud()
	await UIActions._frames(tree, 6)
	button.grab_focus()
	await UIActions._frames(tree, 3)
	var page_revision: int = game.hud._page_revision
	var slider: HSlider = game.hud._find_focus_token(game.hud._dialog, "setting:ui_scale")
	check.call(slider != null and button.get_meta("focus_token", "") == "setting:graphics_quality",
		"graphics quality: settings controls expose stable UI-scale and Graphics focus identities")
	if slider != null: slider.value = 1.4
	tree.root.size = Vector2i(960, 540)
	await UIActions._frames(tree, 8)
	var clip: Rect2 = game.hud._scroll.get_global_rect()
	check.call(game.career.settings.ui_scale == 1.4 and tree.root.gui_get_focus_owner() == button
		and game.hud._page_revision == page_revision and clip.encloses(button.get_global_rect()),
		"graphics quality: an already focused Graphics control stays fully inside its scroll clip after 960x540/1.4x relayout without rebuilding")
	var previous: String = game.career.settings.graphics_quality
	await UIActions._tap(tree, KEY_ENTER)
	check.call(game.career.settings.graphics_quality != previous
		and button.text == "GRAPHICS: " + Quality.LABELS[game.career.settings.graphics_quality]
		and game.hud._scroll.get_global_rect().encloses(button.get_global_rect()),
		"graphics quality: the visible focused Graphics control still accepts native keyboard activation after the resize")
	var layout_revision: int = game.hud._layout_visibility_revision
	for index in 20: game._refresh_hud()
	check.call(game.hud._layout_visibility_revision == layout_revision and not game.hud._layout_visibility_pending,
		"graphics quality: settled unchanged refreshes create no repeated layout or deferred visibility work")
	# A newer page invalidates pending resize work instead of targeting freed controls.
	tree.root.size = Vector2i(1024, 600)
	game._refresh_hud()
	game.hud.show_controls()
	await UIActions._frames(tree, 8)
	var focused := tree.root.gui_get_focus_owner()
	check.call(game.hud._page == "controls" and is_instance_valid(focused)
		and game.hud._scroll.is_ancestor_of(focused)
		and game.hud._scroll.get_global_rect().encloses(focused.get_global_rect()),
		"graphics quality: a page change during deferred resize reveals only a live control in the new scroll view")
	tree.root.size = original_size
	game._refresh_hud()
	await UIActions._frames(tree, 6)

static func _quality_button(node: Node) -> Button:
	if node is Button and node.text.begins_with("GRAPHICS: "): return node
	for child: Node in node.get_children():
		var result := _quality_button(child)
		if result!=null:return result
	return null
