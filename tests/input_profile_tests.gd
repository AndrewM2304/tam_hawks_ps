extends RefCounted
## InputMap contract checks. Always restore canonical gameplay bindings after execution.
const Profile = preload("res://game/core/input_profile.gd")

static func run(check: Callable) -> void:
	var ui_accept_before: Array[InputEvent] = InputMap.action_get_events("ui_accept").duplicate(true)
	var ui_cancel_before: Array[InputEvent] = InputMap.action_get_events("ui_cancel").duplicate(true)
	Profile.reset_defaults()
	var initial := Profile.binding_snapshot()
	check.call(initial.size() == 19 and _row(initial, "grind")["pad_text"] == "Triangle"
		and _row(initial, "revert")["pad_text"] == "R2" and _row(initial, "restart")["pad_text"] == "R3"
		and _row(initial, "interact")["pad_text"] == "L3"
		and _row(initial, "special_one")["pad_text"] == "Right stick up"
		and _row(initial, "special_two")["pad_text"] == "Right stick down"
		and _row(initial, "ollie")["key_text"] == "Space",
		"input profile: classic faces/revert/restart remain; specials and interact leave D-pad directions free")
	check.call(_row(initial, "push")["key_text"].contains("W")
		and _row(initial, "push")["key_text"].contains("Up"),
		"input profile: snapshot retains default keyboard alternatives")
	var result := Profile.rebind("flip", _key(KEY_Z))
	check.call(result["ok"] and result["bindings"] == {"flip": {"key": KEY_Z}}
		and _row(Profile.binding_snapshot(), "flip")["key_text"] == "Z"
		and _row(Profile.binding_snapshot(), "flip")["pad_text"] == "Square",
		"input profile: remapping a physical key preserves the controller binding")
	result = Profile.rebind("flip", _button(JOY_BUTTON_MISC1))
	check.call(result["ok"] and result["bindings"]["flip"] == {"key": KEY_Z, "button": JOY_BUTTON_MISC1}
		and _row(Profile.binding_snapshot(), "flip")["key_text"] == "Z",
		"input profile: controller remapping preserves the independently remapped keyboard slot")
	var alternate_controller := _button(JOY_BUTTON_MISC1)
	alternate_controller.device = 7
	check.call(InputMap.event_is_action(alternate_controller, "flip"),
		"input profile: remapped controller events accept a reconnected device at another index")
	result["bindings"]["flip"]["key"] = KEY_P
	check.call(_row(Profile.binding_snapshot(), "flip")["key_text"] == "Z",
		"input profile: caller edits to returned settings cannot mutate live assignments")
	var stable := Profile.binding_snapshot()
	check.call(not Profile.rebind("grab", _key(KEY_Z))["ok"]
		and Profile.binding_snapshot() == stable,
		"input profile: duplicate live keyboard bindings reject without partial changes")
	check.call(not Profile.rebind("grab", _button(JOY_BUTTON_MISC1))["ok"],
		"input profile: duplicate controller buttons reject")
	check.call(not Profile.rebind("flip", _key(KEY_UP))["ok"],
		"input profile: a default secondary keyboard alias also participates in collision checks")
	check.call(not Profile.apply_saved({"grab": {"key": KEY_SPACE}})
		and Profile.binding_snapshot() == stable,
		"input profile: saved overrides conflicting with an untouched default reject atomically")
	check.call(Profile.apply_saved({"flip": {"key": KEY_K}, "grab": {"key": KEY_J}})
		and _row(Profile.binding_snapshot(), "flip")["key_text"] == "K"
		and _row(Profile.binding_snapshot(), "grab")["key_text"] == "J",
		"input profile: a complete saved profile can atomically swap otherwise conflicting keys")
	Profile.reset_defaults()
	check.call(Profile.rebind("grind", _axis(JOY_AXIS_RIGHT_X, -0.8))["ok"]
		and _row(Profile.binding_snapshot(), "grind")["key_text"] == "L"
		and _row(Profile.binding_snapshot(), "grind")["pad_text"] == "Right stick left",
		"input profile: a signed axis capture retains keyboard fallback and normalizes its direction")
	check.call(Profile.rebind("manual", _axis(JOY_AXIS_RIGHT_X, 0.9))["ok"],
		"input profile: opposite directions of one stick remain distinct bindable inputs")
	check.call(not Profile.rebind("manual", _axis(JOY_AXIS_RIGHT_X, -0.8))["ok"],
		"input profile: duplicate axis directions reject even when capture magnitudes differ")
	check.call(not Profile.rebind("grind", _axis(JOY_AXIS_RIGHT_Y, 0.2))["ok"]
		and not Profile.rebind("grind", _axis(JOY_AXIS_RIGHT_Y, NAN))["ok"],
		"input profile: resting-stick noise and nonfinite axis values cannot capture a binding")
	check.call(not Profile.rebind("grind", _axis(JOY_AXIS_TRIGGER_RIGHT, -1.0))["ok"],
		"input profile: trigger bindings cannot use the unpressed negative direction")
	var menu_axis := Profile.rebind("pause", _axis(JOY_AXIS_RIGHT_X, 0.9))
	check.call(not menu_axis["ok"] and String(menu_axis["error"]).contains("held axis"),
		"input profile: held axes cannot repeatedly toggle a discrete menu action")
	check.call(Profile.rebind("grind", _button(JOY_BUTTON_MISC1))["ok"]
		and _row(Profile.binding_snapshot(), "grind")["pad_text"] == "Button %d" % JOY_BUTTON_MISC1
		and _row(Profile.binding_snapshot(), "grind")["key_text"] == "L",
		"input profile: switching from axis to button replaces the controller slot without losing keyboard input")
	check.call(not Profile.rebind("flip", _key(KEY_ESCAPE))["ok"]
		and not Profile.rebind("flip", _key(KEY_ENTER))["ok"]
		and not Profile.rebind("pause", _key(KEY_P))["ok"],
		"input profile: Escape pause recovery and Enter menu confirmation cannot be reassigned")
	Profile.reset_defaults()
	check.call(Profile.rebind("pause", _button(JOY_BUTTON_MISC1))["ok"]
		and _row(Profile.binding_snapshot(), "pause")["key_text"] == "Escape",
		"input profile: pause controller remapping still retains Escape recovery")
	var released := _key(KEY_Z)
	released.pressed = false
	var repeated := _key(KEY_Z)
	repeated.echo = true
	var modified := _key(KEY_Z)
	modified.ctrl_pressed = true
	check.call(not Profile.rebind("flip", released)["ok"]
		and not Profile.rebind("flip", repeated)["ok"]
		and not Profile.rebind("flip", modified)["ok"],
		"input profile: releases, repeated key events and modifier chords do not bind")
	check.call(not Profile.rebind("unknown", _key(KEY_Z))["ok"]
		and not Profile.rebind("flip", InputEventMouseButton.new())["ok"]
		and not Profile.rebind("flip", null)["ok"],
		"input profile: unknown actions and unsupported/null event types reject safely")
	_test_serialization(check)
	var reset := Profile.reset_defaults()
	check.call(reset.is_empty() and Profile.binding_snapshot() == initial,
		"input profile: reset returns an empty override profile and restores canonical controls")
	check.call(_same_events(ui_accept_before, InputMap.action_get_events("ui_accept"))
		and _same_events(ui_cancel_before, InputMap.action_get_events("ui_cancel")),
		"input profile: rebinding and resetting never alter built-in menu accept/cancel inputs")

static func _test_serialization(check: Callable) -> void:
	var before := Profile.binding_snapshot()
	var invalid: Array = [null, [], {"unknown": {"key": KEY_Z}}, {"flip": {}},
		{"flip": {"script": "res://anything.gd"}}, {"flip": {"key": "Z"}},
		{"flip": {"key": -1}}, {"flip": {"key": 1.5}}, {"flip": {"key": KEY_CTRL}},
		{"flip": {"button": JOY_BUTTON_MAX}}, {"grind": {"axis": JOY_AXIS_MAX, "axis_value": 1}},
		{"grind": {"axis": JOY_AXIS_RIGHT_X}}, {"grind": {"axis_value": 1}},
		{"grind": {"axis": JOY_AXIS_RIGHT_X, "axis_value": 0.3}},
		{"grind": {"axis": JOY_AXIS_RIGHT_X, "axis_value": INF}},
		{"grind": {"button": 1, "axis": JOY_AXIS_RIGHT_X, "axis_value": 1}},
		{"flip": {"key": KEY_Z}, "grab": {"key": KEY_Z}}]
	var rejected := true
	for value: Variant in invalid:
		rejected = rejected and not Profile.validate_saved(value)["ok"]
	check.call(rejected and Profile.binding_snapshot() == before,
		"input profile: malformed serialized data rejects without constructing resources or mutating InputMap")
	var serialized := JSON.stringify({"flip": {"key": KEY_Z}, "grind": {"axis": JOY_AXIS_RIGHT_X, "axis_value": -1.0},
		"special_one": {"axis": JOY_AXIS_RIGHT_Y, "axis_value": -1.0},
		"special_two": {"axis": JOY_AXIS_RIGHT_Y, "axis_value": 1.0}})
	var decoded: Dictionary = JSON.parse_string(serialized)
	check.call(Profile.apply_saved(decoded)
		and _row(Profile.binding_snapshot(), "flip")["key_text"] == "Z"
		and _row(Profile.binding_snapshot(), "grind")["pad_text"] == "Right stick left"
		and _row(Profile.binding_snapshot(), "special_one")["pad_text"] == "Right stick up"
		and _row(Profile.binding_snapshot(), "special_two")["pad_text"] == "Right stick down",
		"input profile: simple numeric JSON bindings round-trip through validated actual InputMap events")
	var button := _button(JOY_BUTTON_X)
	check.call(InputMap.event_is_action(button, "flip")
		and InputMap.event_is_action(_key(KEY_Z), "flip")
		and not InputMap.event_is_action(_key(KEY_J), "flip"),
		"input profile: Godot resolves new key events and preserved controller fallback while releasing the old key")

static func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event

static func _button(index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	return event

static func _axis(index: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = index
	event.axis_value = value
	return event

static func _row(rows: Array[Dictionary], action: String) -> Dictionary:
	for row: Dictionary in rows:
		if row["action"] == action:
			return row
	return {}

static func _same_events(left: Array[InputEvent], right: Array[InputEvent]) -> bool:
	if left.size() != right.size():
		return false
	for index: int in left.size():
		if left[index].as_text() != right[index].as_text():
			return false
	return true
