extends RefCounted
const Quality = preload("res://game/core/graphics_quality.gd")
const Career = preload("res://game/progression/career_progress.gd")

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
	game.hud._show_page("settings")
	var button: Button=_quality_button(game.hud._dialog)
	check.call(button!=null and button.text=="GRAPHICS: Balanced",
		"graphics quality: actual Settings page explains the selected preset")
	if button!=null:
		button.pressed.emit()
		check.call(game.career.settings.graphics_quality=="high" and button.text=="GRAPHICS: High",
			"graphics quality: actual Settings button changes the saved choice and visible label")
	game.apply_settings(original,false)
	game.skater.set_physics_process(true)
	game.hud.hide_menu()
	game.start_mode(false)

static func _quality_button(node: Node) -> Button:
	if node is Button and node.text.begins_with("GRAPHICS: "): return node
	for child: Node in node.get_children():
		var result := _quality_button(child)
		if result!=null:return result
	return null
