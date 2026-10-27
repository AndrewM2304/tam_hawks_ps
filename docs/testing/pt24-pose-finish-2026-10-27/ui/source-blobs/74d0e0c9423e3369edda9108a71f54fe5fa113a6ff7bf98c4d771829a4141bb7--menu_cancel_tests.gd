extends RefCounted
## Actual Circle/B events through Main's production HUD; no controller hardware claim.
const Actions = preload("res://tests/ui_integration_tests.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var settings: Dictionary = game.career.settings.duplicate(true)
	var menu_events := _menu_events()
	var pauses: Array = []
	var on_pause := func(): pauses.append(true)
	game.hud.pause_requested.connect(on_pause)
	game.apply_settings({"bindings": {}}, false)
	game.hud.hide_menu()
	game.start_mode(false)
	game.toggle_pause()
	game.hud.show_title()
	await Actions._frames(tree, 4)
	var circle := _button(true)
	print("MENU_CANCEL_NATIVE_MAPS ", _menu_events(), " grab=", InputMap.action_get_events("grab"), " event=", circle.as_text())
	check.call(circle.is_action_pressed("grab") and InputMap.has_action("ui_cancel"),
		"menu cancel: real default Circle event resolves its overlapping skating Grab")
	await _tap(tree)
	check.call(game.hud._page == "title" and game.paused and tree.paused,
		"menu cancel: Circle at title is consumed without starting or resuming a run")
	await Actions._activate(tree, game.hud, "SETTINGS")
	await Actions._activate(tree, game.hud, "CONTROLS")
	await _tap(tree)
	check.call(game.hud._page == "settings" and game.paused and _focus(tree) == "CONTROLS",
		"menu cancel: Circle returns nested controls to settings and restores opener focus")
	# Reset the declared menu origin so a causal failure cannot cascade.
	game.hud.show_title()
	await Actions._activate(tree, game.hud, "SETTINGS")
	await _tap(tree)
	check.call(game.hud._page == "title" and game.paused and _focus(tree) == "SETTINGS",
		"menu cancel: Circle returns settings to its paused title origin")
	game.hud.hide_menu()
	game.start_mode(false)
	pauses.clear()
	game.hud.toggle_goals()
	var stopped_time: float = game.time_remaining
	game.hud.show_map()
	await Actions._frames(tree, 4)
	await _tap(tree)
	check.call(game.hud._page == "goals" and game.paused and tree.paused
		and game.time_remaining == stopped_time and pauses.size() == 1,
		"menu cancel: Circle returns map to goals without resuming or advancing time")
	await _tap(tree)
	check.call(game.hud._page.is_empty() and not game.paused and not tree.paused and pauses.size() == 2,
		"menu cancel: Circle closes live-origin goals and resumes exactly once")
	game.hud.hide_menu()
	game.start_mode(false)
	game.toggle_pause()
	var pause_count := pauses.size()
	await _tap(tree)
	check.call(game.hud._page.is_empty() and not game.paused and pauses.size() == pause_count + 1,
		"menu cancel: Circle closes ordinary pause and resumes exactly once")
	game.hud.hide_menu()
	game.start_mode(false)
	game.time_remaining = 0.01
	await Actions._frames(tree, 4)
	await _tap(tree)
	check.call(game.run_finished and game.hud._page == "results" and not game.skater.is_physics_processing(),
		"menu cancel: Circle cannot resume a finished results run")
	await Actions._activate(tree, game.hud, "SETTINGS")
	await _tap(tree)
	check.call(game.run_finished and game.hud._page == "results" and _focus(tree) == "SETTINGS",
		"menu cancel: Circle returns results settings to the finished results origin")
	game.hud.hide_menu()
	game.start_mode(false)
	game.toggle_pause()
	game.hud.show_controls()
	await Actions._activate(tree, game.hud, "Grab  /")
	await _tap(tree)
	check.call(game.hud._page == "controls" and game.hud._binding_action.is_empty()
		and game.career.settings.bindings.get("grab", {}).get("button", -1) == JOY_BUTTON_B,
		"menu cancel: Circle remains capturable as a skating binding without closing controls")
	await Actions._activate(tree, game.hud, "Grab  /")
	await Actions._tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "controls" and game.hud._binding_action.is_empty() and game.paused,
		"menu cancel: Escape still cancels binding capture without leaving controls")
	game.hud.hide_menu()
	game.start_mode(false)
	await Actions._frames(tree, 35)
	Input.action_press("ollie")
	await Actions._frames(tree, 20)
	Input.action_release("ollie")
	await Actions._frames(tree, 2)
	check.call(game.skater.airborne and game.skater._grab_remaining <= 0.0,
		"menu cancel: no-injection fixture reaches real airborne skating before pausing")
	game.hud.toggle_goals()
	var history: Array = game.score.trick_history.duplicate()
	await _tap(tree)
	print("MENU_CANCEL_AIR_RESUME page=", game.hud._page, " paused=", game.paused, " air=", game.skater.airborne,
		" used=", game.skater._grab_used, " pressed=", Input.is_action_pressed("grab"), " buffer=", game.skater._grab_buffer_remaining,
		" history=", game.score.trick_history, " previous=", history)
	check.call(game.hud._page.is_empty() and not game.paused and game.skater.airborne
		and game.skater._grab_remaining <= 0.0 and game.skater._pending_grab.is_empty()
		and game.score.trick_history == history and not Input.is_action_pressed("grab"),
		"menu cancel: airborne Circle resume adds no actual or pending Grab and no trick score")
	# Restore live skating even on the old-source causal failure, then prove
	# Circle still performs its normal gameplay Grab outside every modal.
	game.hud.hide_menu()
	if game.paused: game.toggle_pause()
	await _tap(tree)
	print("MENU_CANCEL_LIVE_GRAB air=", game.skater.airborne, " used=", game.skater._grab_used,
		" buffer=", game.skater._grab_buffer_remaining, " history=", game.score.trick_history)
	check.call(game.skater.airborne and game.skater.grab_trick_id == "melon_grab"
		and game.score.trick_history.size() == history.size() + 1 and game.score.trick_history.back() == "Melon Grab",
		"menu cancel: Circle still performs a real Grab during ordinary airborne gameplay")
	check.call(menu_events == _menu_events(),
		"menu cancel: navigation and capture leave built-in accept/cancel maps unchanged")
	game.hud.pause_requested.disconnect(on_pause)
	Actions._release_actions()
	game.hud.hide_menu()
	game.apply_settings(settings, false)
	game.start_mode(false)
	check.call(not game.persistence_enabled and not game.music._can_control and not game.music._persist,
		"menu cancel: fixture never writes career or controls a personal Music account")


static func _tap(tree: SceneTree) -> void:
	Input.parse_input_event(_button(true))
	Input.flush_buffered_events()
	await Actions._frames(tree, 1)
	Input.parse_input_event(_button(false))
	Input.flush_buffered_events()
	await Actions._frames(tree, 3)


static func _button(pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_B
	event.pressed = pressed
	return event


static func _focus(tree: SceneTree) -> String:
	var focused := tree.root.gui_get_focus_owner()
	return str(focused.get_meta("focus_token", "")) if is_instance_valid(focused) else ""


static func _menu_events() -> Dictionary:
	var result: Dictionary = {}
	for action: String in ["ui_accept", "ui_cancel"]:
		var events: Array[String] = []
		for event: InputEvent in InputMap.action_get_events(action): events.append(event.as_text())
		result[action] = events
	return result
