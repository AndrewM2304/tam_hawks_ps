extends RefCounted
## Standard SDL gamepad mappings; actual DualSense behavior requires hardware QA.

static func register_actions() -> void:
	_key_action("push", [KEY_W, KEY_UP])
	_key_action("brake", [KEY_S, KEY_DOWN])
	_key_action("steer_left", [KEY_A, KEY_LEFT])
	_key_action("steer_right", [KEY_D, KEY_RIGHT])
	_key_action("ollie", [KEY_SPACE])
	_key_action("flip", [KEY_J])
	_key_action("grab", [KEY_K])
	_key_action("spin_left", [KEY_Q])
	_key_action("spin_right", [KEY_E])
	_key_action("restart", [KEY_R])
	_key_action("pause", [KEY_ESCAPE])
	_key_action("free_skate", [KEY_F])
	_axis("steer_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("steer_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("push", JOY_AXIS_LEFT_Y, -1.0)
	_axis("brake", JOY_AXIS_LEFT_Y, 1.0)
	_button("ollie", JOY_BUTTON_A)
	_button("flip", JOY_BUTTON_X)
	_button("grab", JOY_BUTTON_B)
	_button("spin_left", JOY_BUTTON_LEFT_SHOULDER)
	_button("spin_right", JOY_BUTTON_RIGHT_SHOULDER)
	_button("restart", JOY_BUTTON_Y)
	_button("pause", JOY_BUTTON_START)
	_button("free_skate", JOY_BUTTON_TOUCHPAD)

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
	event.axis = axis
	event.axis_value = value
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

static func _button(action: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
