extends RefCounted
## Standard SDL gamepad mappings; actual DualSense behavior requires hardware QA.

static func register_actions() -> void:
	_register_menu_actions()
	_key_action("push", [KEY_W, KEY_UP])
	_key_action("brake", [KEY_S, KEY_DOWN])
	_key_action("steer_left", [KEY_A, KEY_LEFT])
	_key_action("steer_right", [KEY_D, KEY_RIGHT])
	_key_action("ollie", [KEY_SPACE])
	_key_action("flip", [KEY_J])
	_key_action("grab", [KEY_K])
	_key_action("grind", [KEY_L])
	_key_action("manual", [KEY_M])
	_key_action("revert", [KEY_C])
	_key_action("special_one", [KEY_U])
	_key_action("special_two", [KEY_I])
	_key_action("interact", [KEY_X])
	_key_action("goals", [KEY_TAB])
	_key_action("spin_left", [KEY_Q])
	_key_action("spin_right", [KEY_E])
	_key_action("restart", [KEY_R])
	_key_action("pause", [KEY_ESCAPE])
	_key_action("free_skate", [KEY_F])
	_axis("steer_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("steer_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("revert", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_axis("manual", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_axis("push", JOY_AXIS_LEFT_Y, -1.0)
	_axis("brake", JOY_AXIS_LEFT_Y, 1.0)
	# Directional trick/manual input must never also fire a special or interact.
	_button("push", JOY_BUTTON_DPAD_UP)
	_button("brake", JOY_BUTTON_DPAD_DOWN)
	_button("steer_left", JOY_BUTTON_DPAD_LEFT)
	_button("steer_right", JOY_BUTTON_DPAD_RIGHT)
	_axis("special_one", JOY_AXIS_RIGHT_Y, -1.0)
	_axis("special_two", JOY_AXIS_RIGHT_Y, 1.0)
	_button("interact", JOY_BUTTON_LEFT_STICK)
	_button("goals", JOY_BUTTON_BACK)
	_button("grind", JOY_BUTTON_Y)
	_button("ollie", JOY_BUTTON_A)
	_button("flip", JOY_BUTTON_X)
	_button("grab", JOY_BUTTON_B)
	_button("spin_left", JOY_BUTTON_LEFT_SHOULDER)
	_button("spin_right", JOY_BUTTON_RIGHT_SHOULDER)
	_button("restart", JOY_BUTTON_RIGHT_STICK)
	_button("pause", JOY_BUTTON_START)
	_button("free_skate", JOY_BUTTON_TOUCHPAD)

static func _register_menu_actions() -> void:
	# Godot's built-in actions may contain only keyboard defaults. Add native
	# pad navigation once without replacing keyboard recovery or saved skating
	# bindings; remapping/reset must leave this independent menu map intact.
	for action: String in ["ui_accept", "ui_cancel", "ui_left", "ui_right", "ui_up", "ui_down"]:
		if not InputMap.has_action(action): InputMap.add_action(action, 0.5)
	_button("ui_accept", JOY_BUTTON_A)
	_button("ui_cancel", JOY_BUTTON_B)
	_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_button("ui_up", JOY_BUTTON_DPAD_UP)
	_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	_axis("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("ui_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0)

static func _key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for key: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

static func _axis(action: String, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

static func _button(action: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
