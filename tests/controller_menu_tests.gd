extends RefCounted
## Production menu focus/activation via native parsed pad events; not hardware QA.
const Actions = preload("res://tests/ui_integration_tests.gd")
const Setup = preload("res://game/core/input_setup.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var settings: Dictionary = game.career.settings.duplicate(true)
	var original := _map()
	Setup.register_actions()
	Setup.register_actions()
	check.call(_map() == original,
		"controller menu: repeated input registration preserves all existing menu events without duplicates")
	var cross := _button(JOY_BUTTON_A, true)
	var circle := _button(JOY_BUTTON_B, true)
	check.call(cross.is_action_pressed("ui_accept") and circle.is_action_pressed("ui_cancel")
		and _button(JOY_BUTTON_DPAD_DOWN, true).is_action_pressed("ui_down")
		and _motion(JOY_AXIS_LEFT_Y, -1).is_action_pressed("ui_up")
		and _motion(JOY_AXIS_LEFT_X, -1).is_action_pressed("ui_left")
		and _motion(JOY_AXIS_LEFT_X, 1).is_action_pressed("ui_right"),
		"controller menu: Cross/Circle, D-pad and signed left stick resolve native UI actions")
	game.hud.hide_menu()
	game.start_mode(false)
	game.toggle_pause()
	game.hud.show_title()
	await Actions._frames(tree, 4)
	await _tap(tree, JOY_BUTTON_DPAD_DOWN)
	check.call(_focus(tree) == "FREE SKATE" and game.hud._page == "title" and game.paused,
		"controller menu: actual D-pad Down moves visible title focus to Free skate")
	await _tap(tree, JOY_BUTTON_A)
	# A fresh run starts above its native floor; allow ordinary gravity to
	# settle the actor instead of mistaking that initial fall for an Ollie.
	await Actions._frames(tree, 35)
	check.call(game.free_skate_mode and not game.paused and game.hud._page.is_empty()
		and not game.skater.airborne and game.score.trick_history.is_empty(),
		"controller menu: actual Cross activates Free skate without an accidental Ollie")
	game.hud.hide_menu()
	game.start_mode(false)
	game.toggle_pause()
	game.hud.show_title()
	await Actions._frames(tree, 4)
	await _axis(tree, JOY_AXIS_LEFT_Y, 1)
	check.call(_focus(tree) == "FREE SKATE",
		"controller menu: actual left-stick Down moves native title focus")
	await _axis(tree, JOY_AXIS_LEFT_Y, -1)
	check.call(_focus(tree) == "START CAREER RUN",
		"controller menu: neutral then left-stick Up returns native title focus")
	await _tap(tree, JOY_BUTTON_A)
	await Actions._frames(tree, 35)
	check.call(not game.free_skate_mode and not game.paused and game.hud._page.is_empty()
		and not game.skater.airborne and game.score.trick_history.is_empty(),
		"controller menu: actual Cross activates Career without an accidental Ollie")
	await _tap(tree, JOY_BUTTON_START)
	check.call(game.paused and game.hud._page == "pause" and _focus(tree) == "BACK TO THE BOARD",
		"controller menu: actual Options opens pause with visible Resume focus")
	await _tap(tree, JOY_BUTTON_A)
	check.call(not game.paused and game.hud._page.is_empty() and not game.skater.airborne
		and game.score.trick_history.is_empty(),
		"controller menu: actual Cross resumes the run without an accidental Ollie")
	await _tap(tree, JOY_BUTTON_START)
	game.hud.show_settings()
	await Actions._frames(tree, 4)
	# The first settings control is Soundtrack; reach the following volume
	# slider with the actual D-pad rather than assigning focus to it.
	await _tap(tree, JOY_BUTTON_DPAD_DOWN)
	var slider: HSlider = tree.root.gui_get_focus_owner() as HSlider
	check.call(slider != null,
		"controller menu: settings begins on its native focused volume slider")
	if slider != null:
		var before := slider.value
		await _tap(tree, JOY_BUTTON_DPAD_RIGHT)
		var right := slider.value
		await _tap(tree, JOY_BUTTON_DPAD_LEFT)
		check.call(right > before and is_equal_approx(slider.value, before),
			"controller menu: actual D-pad Left/Right adjusts and restores the live setting")
		await _axis(tree, JOY_AXIS_LEFT_X, 1)
		right = slider.value
		await _axis(tree, JOY_AXIS_LEFT_X, -1)
		check.call(right > before and is_equal_approx(slider.value, before),
			"controller menu: actual stick Left/Right adjusts and restores the live setting")
	await _tap(tree, JOY_BUTTON_B)
	await _tap(tree, JOY_BUTTON_B)
	check.call(not game.paused and game.hud._page.is_empty(),
		"controller menu: initialized Circle mapping still traverses settings/pause and resumes once")
	await _tap(tree, JOY_BUTTON_START)
	game.hud.show_controls()
	await Actions._activate(tree, game.hud, "Ollie  /")
	await _tap(tree, JOY_BUTTON_A)
	check.call(game.hud._page == "controls" and game.hud._binding_action.is_empty()
		and game.career.settings.bindings.get("ollie", {}).get("button", -1) == JOY_BUTTON_A,
		"controller menu: capture accepts Cross as Ollie before native UI activation")
	game.hud.hide_menu()
	Actions._release_actions()
	game.apply_settings(settings, false)
	game.start_mode(false)
	check.call(_map() == original and not game.persistence_enabled and not game.music._can_control,
		"controller menu: remapping restores settings, keeps menu maps stable and isolates personal state")


static func _tap(tree: SceneTree, button: JoyButton) -> void:
	Input.parse_input_event(_button(button, true))
	Input.flush_buffered_events()
	await Actions._frames(tree, 1)
	Input.parse_input_event(_button(button, false))
	Input.flush_buffered_events()
	await Actions._frames(tree, 3)


static func _axis(tree: SceneTree, axis: JoyAxis, value: float) -> void:
	Input.parse_input_event(_motion(axis, value))
	Input.flush_buffered_events()
	await Actions._frames(tree, 1)
	Input.parse_input_event(_motion(axis, 0))
	Input.flush_buffered_events()
	await Actions._frames(tree, 3)


static func _button(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	return event


static func _motion(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	return event


static func _focus(tree: SceneTree) -> String:
	var focused := tree.root.gui_get_focus_owner()
	return str(focused.get_meta("focus_token", "")) if is_instance_valid(focused) else ""


static func _map() -> Dictionary:
	var result: Dictionary = {}
	for action: String in ["ui_accept", "ui_cancel", "ui_left", "ui_right", "ui_up", "ui_down"]:
		var events: Array[String] = []
		for event: InputEvent in InputMap.action_get_events(action): events.append(event.as_text())
		result[action] = events
	return result
