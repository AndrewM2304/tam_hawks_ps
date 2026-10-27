extends RefCounted
## Real HUD controls and input routing against the production scene; no profile writes.

const InputProfileSource = preload("res://game/core/input_profile.gd")
const CareerSource = preload("res://game/progression/career_progress.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_career = game.career
	var original_spawn: Vector3 = game.skater.spawn_position
	game.persistence_enabled = false
	game.career = CareerSource.new()
	game.apply_settings(game.career.settings, false)
	game.skater.spawn_position = Vector3(5, 0.8, 24)
	game.start_mode(false)
	await _frames(tree, 45)
	await _title_and_modes(tree, game, check)
	await _goals_pause(tree, game, check)
	await _settings_and_controls(tree, game, check)
	await _cosmetics_and_results(tree, game, check)
	await load("res://tests/menu_cancel_tests.gd").run(tree, game, check)
	await load("res://tests/controller_menu_tests.gd").run(tree, game, check)
	_release_actions()
	game.hud.hide_menu()
	game.career = original_career
	game.skater.spawn_position = original_spawn
	game.apply_settings(game.career.settings, false)
	game.start_mode(false)
	check.call(not game.persistence_enabled, "UI integration: all scene flows keep profile writes disabled")


static func _title_and_modes(tree: SceneTree, game: Node, check: Callable) -> void:
	# Script runners intentionally skip boot's title branch. Recreate that public
	# paused/title state, then use the same visible controls as a normal launch.
	game.toggle_pause()
	game.hud.show_title()
	await _frames(tree, 3)
	var time_before: float = game.time_remaining
	await _tap(tree, KEY_ESCAPE)
	await _tap(tree, KEY_R)
	await _tap(tree, KEY_F)
	check.call(game.paused and tree.paused and game.hud._page == "title"
		and game.time_remaining == time_before and not game.free_skate_mode,
		"UI integration: title consumes Escape and gameplay restart/mode shortcuts")
	await _activate(tree, game.hud, "SETTINGS")
	check.call(game.hud._page == "settings" and game.paused,
		"UI integration: keyboard activation opens title settings without starting a run")
	await _tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "title" and game.paused,
		"UI integration: settings Escape returns to its title origin")
	await _activate(tree, game.hud, "START CAREER RUN")
	check.call(not game.paused and not tree.paused and game.hud._page == ""
		and not game.free_skate_mode and game.time_remaining > 119.0,
		"UI integration: title career button starts a fresh timed run")
	game.toggle_pause()
	game.hud.show_title()
	await _activate(tree, game.hud, "FREE SKATE")
	var free_time: float = game.time_remaining
	await _frames(tree, 10)
	check.call(game.free_skate_mode and not game.paused and game.hud._page == ""
		and game.time_remaining == free_time,
		"UI integration: title free-skate button starts untimed skating")
	await _tap(tree, KEY_ESCAPE)
	await _activate(tree, game.hud, "START CAREER RUN")
	check.call(not game.free_skate_mode and not game.paused and game.hud._page == "",
		"UI integration: pause mode button switches free skate back to career")


static func _goals_pause(tree: SceneTree, game: Node, check: Callable) -> void:
	await _tap(tree, KEY_TAB)
	var stopped_time: float = game.time_remaining
	var stopped_position: Vector3 = game.skater.global_position
	Input.action_press("push")
	await _frames(tree, 10)
	Input.action_release("push")
	check.call(game.hud._page == "goals" and game.paused and tree.paused
		and game.time_remaining == stopped_time
		and game.skater.global_position.is_equal_approx(stopped_position),
		"UI integration: mapped goals input pauses timer and physical skating")
	await _activate(tree, game.hud, "CITY MAP & ROUTES")
	await _frames(tree, 5)
	check.call(game.hud._page == "map" and game.paused and tree.paused
		and game.time_remaining == stopped_time,
		"UI integration: route map opened through goals keeps the run paused")
	check.call(game.hud._map_checkpoints.size() == 6 and game.hud._map_routes.size() >= 6,
		"UI integration: map receives six places and authored world routes")
	await _tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "goals" and game.paused,
		"UI integration: closing map returns to the goals page without resuming")
	await _tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "" and not game.paused and not tree.paused,
		"UI integration: closing goals opened during skating resumes the run")
	await _tap(tree, KEY_ESCAPE)
	await _activate(tree, game.hud, "GOALS & UNLOCKS")
	check.call(game.hud._page == "goals" and game.paused,
		"UI integration: pause-menu goals opens while retaining pause")
	await _tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "pause" and game.paused,
		"UI integration: goals opened from pause returns to pause without resuming")
	await _tap(tree, KEY_ESCAPE)
	Input.joy_connection_changed.emit(99, false)
	await _frames(tree, 3)
	check.call(game.paused and game.hud._page == "pause"
		and game.audio.get_debug_state().paused,
		"UI integration: synthetic controller disconnect pauses gameplay and skating audio")
	await _activate(tree, game.hud, "GOALS & UNLOCKS")
	Input.joy_connection_changed.emit(99, false)
	await _frames(tree, 2)
	check.call(game.paused and game.hud._page == "goals",
		"UI integration: repeated disconnect preserves an already open modal")
	await _tap(tree, KEY_ESCAPE)


static func _settings_and_controls(tree: SceneTree, game: Node, check: Callable) -> void:
	await _activate(tree, game.hud, "SETTINGS")
	var sliders: Array = _nodes_of_type(game.hud._modal, "HSlider")
	check.call(sliders.size() == 5, "UI integration: settings exposes audio, readability and camera controls")
	if sliders.size() == 5:
		sliders[0].value = 0.5
		sliders[1].value = 0.4
		sliders[2].value = 0.2
		sliders[3].value = 1.3
		sliders[4].value = 1.7
	var captions: Button = _find_button(game.hud._modal, "Show captions")
	var reduced: Button = _find_button(game.hud._modal, "Reduce motion")
	if captions != null: captions.button_pressed = false
	if reduced != null: reduced.button_pressed = true
	await _frames(tree, 3)
	var mix: Dictionary = game.audio.get_debug_state()
	check.call(is_equal_approx(mix.sfx, 0.2) and is_equal_approx(mix.ambience, 0.1),
		"UI integration: actual sliders combine master and channel volumes in audio")
	check.call(is_equal_approx(game.career.settings.ui_scale, 1.3)
		and is_equal_approx(game.skater._camera_sensitivity, 1.7)
		and game.skater._reduced_motion and game.objectives.reduced_motion
		and not game.career.settings.captions,
		"UI integration: settings widgets update saved preferences and active presentation")
	await _tap(tree, KEY_ESCAPE)
	await _activate(tree, game.hud, "CONTROLS")
	await _activate(tree, game.hud, "Ollie  /")
	await _tap(tree, KEY_J)
	check.call(game.hud._binding_action == "ollie" and game.career.settings.bindings.is_empty(),
		"UI integration: conflicting live rebind keeps capture open without changing preferences")
	await _tap(tree, KEY_ESCAPE)
	check.call(game.hud._binding_action == "" and game.hud._page == "controls" and game.paused,
		"UI integration: Escape cancels binding capture without closing controls or resuming")
	await _activate(tree, game.hud, "Ollie  /")
	await _tap(tree, KEY_B)
	check.call(game.hud._page == "controls" and game.hud._binding_action == ""
		and game.career.settings.bindings.get("ollie", {}).get("key", 0) == KEY_B,
		"UI integration: physical rebind input updates both live controls and profile preferences")
	await _tap(tree, KEY_ESCAPE)
	await _tap(tree, KEY_ESCAPE)
	await _frames(tree, 45)
	_key(KEY_B, true)
	await _frames(tree, 2)
	_key(KEY_B, false)
	await _frames(tree, 2)
	check.call(game.skater.airborne and game.score.trick_history.has("Ollie"),
		"UI integration: releasing the newly bound key performs an actual ollie after menu exit")
	await _frames(tree, 80)
	await _tap(tree, KEY_ESCAPE)
	await _activate(tree, game.hud, "CONTROLS")
	await _activate(tree, game.hud, "RESTORE DEFAULT CONTROLS")
	check.call(game.career.settings.bindings.is_empty()
		and _has_key("ollie", KEY_SPACE) and not _has_key("ollie", KEY_B),
		"UI integration: restore-defaults button clears persisted overrides and restores Space")
	await _tap(tree, KEY_ESCAPE)


static func _cosmetics_and_results(tree: SceneTree, game: Node, check: Callable) -> void:
	game.career.completed_ids.append("first_shift")
	await _frames(tree, 2)
	await _activate(tree, game.hud, "GOALS & UNLOCKS")
	var locked: Button = _find_button(game.hud._modal, "NIGHT PURPLE")
	check.call(locked != null and locked.disabled,
		"UI integration: locked cosmetic remains unavailable in goals menu")
	await _activate(tree, game.hud, "CONE ORANGE")
	check.call(game.career.settings.cosmetic_id == "color_orange"
		and game.skater._shirt_color.is_equal_approx(Color("a66642")),
		"UI integration: selecting an earned cosmetic changes rider and stored selection")
	await _tap(tree, KEY_ESCAPE)
	await _activate(tree, game.hud, "RESTART RUN")
	check.call(not game.paused and not game.run_finished and game.hud._page == ""
		and game.score.total_score == 0 and game.time_remaining > 119.0
		and game.career.settings.cosmetic_id == "color_orange",
		"UI integration: pause restart clears run state and retains customization")
	await _frames(tree, 45)
	game.score.add_trick("UI results fixture", 500)
	game.score.begin_landing()
	await _frames(tree, 25)
	game.time_remaining = 0.01
	await _frames(tree, 4)
	check.call(game.run_finished and game.hud._page == "results"
		and game.score.total_score == 500 and not game.skater.is_physics_processing(),
		"UI integration: timed expiry presents final banked score and stops skating")
	await _tap(tree, KEY_ESCAPE)
	check.call(game.run_finished and game.hud._page == "results",
		"UI integration: results consumes Escape without resuming a finished run")
	await _activate(tree, game.hud, "SETTINGS")
	await _tap(tree, KEY_ESCAPE)
	check.call(game.run_finished and game.hud._page == "results",
		"UI integration: results settings returns to results")
	await _activate(tree, game.hud, "ONE MORE RUN")
	check.call(not game.run_finished and not game.paused and game.hud._page == ""
		and game.score.total_score == 0 and game.time_remaining > 119.0,
		"UI integration: results replay button starts a fresh timed run")


static func _activate(tree: SceneTree, hud: Node, prefix: String) -> void:
	await _frames(tree, 2)
	var button: Button = _find_button(hud._modal, prefix)
	if button == null or button.disabled:
		push_error("UI fixture could not activate button: " + prefix)
		return
	button.grab_focus()
	await _frames(tree, 1)
	await _tap(tree, KEY_ENTER)


static func _find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.trim_prefix("✓  ").begins_with(prefix):
		return node
	for child in node.get_children():
		var found: Button = _find_button(child, prefix)
		if found != null: return found
	return null


static func _nodes_of_type(node: Node, type: String) -> Array:
	var result: Array = []
	if node.is_class(type): result.append(node)
	for child in node.get_children(): result.append_array(_nodes_of_type(child, type))
	return result


static func _has_key(action: String, key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == key: return true
	return false


static func _tap(tree: SceneTree, key: Key) -> void:
	_key(key, true)
	await _frames(tree, 1)
	_key(key, false)
	await _frames(tree, 2)


static func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


static func _release_actions() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame
		await tree.process_frame
