extends RefCounted
## Safe, local binding overrides around Godot InputMap; built-in ui_* actions stay intact.

const InputSetup = preload("res://game/core/input_setup.gd")
const ACTION_LABELS: Dictionary = {
	"push": "Push", "brake": "Brake", "steer_left": "Steer left", "steer_right": "Steer right",
	"ollie": "Ollie", "flip": "Flip", "grab": "Grab", "grind": "Grind", "manual": "Manual",
	"revert": "Revert", "special_one": "Clyde Carousel", "special_two": "Tenement Tumble",
	"interact": "Interact", "goals": "Goals", "spin_left": "Spin left", "spin_right": "Spin right",
	"restart": "Restart", "pause": "Pause", "free_skate": "Free skate",
}
const AXIS_ACTIONS: Array[String] = [
	"push", "brake", "steer_left", "steer_right", "grind", "manual", "spin_left", "spin_right",
]
const CAPTURE_THRESHOLD: float = 0.5
const COSMETIC_IDS: Array[String] = ["color_blue", "color_orange", "color_purple"]
static var last_error: String = ""
static var _bindings: Dictionary = {}
static var _defaults: Dictionary = {}

static func binding_snapshot() -> Array[Dictionary]:
	_ensure_defaults()
	var result: Array[Dictionary] = []
	for action: String in ACTION_LABELS:
		var keys: Array[String] = []
		var pads: Array[String] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append(OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode))
			elif event is InputEventJoypadButton:
				pads.append(_button_text(event.button_index))
			elif event is InputEventJoypadMotion:
				pads.append(_axis_text(event.axis, event.axis_value))
		result.append({"action": action, "label": ACTION_LABELS[action],
			"key_text": " / ".join(keys), "pad_text": " / ".join(pads)})
	return result

static func rebind(action: String, event: InputEvent) -> Dictionary:
	if not ACTION_LABELS.has(action):
		return _failure("Unknown skating action.")
	if event == null:
		return _failure("Press a key, controller button or supported stick/trigger direction.")
	var override: Dictionary = {}
	if event is InputEventKey:
		if not event.pressed or event.echo or event.shift_pressed or event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
			return _failure("Use a fresh key press without modifier keys.")
		override["key"] = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	elif event is InputEventJoypadButton:
		if not event.pressed:
			return _failure("Press a controller button to bind it.")
		override["button"] = event.button_index
	elif event is InputEventJoypadMotion:
		if not is_finite(event.axis_value) or absf(event.axis_value) < CAPTURE_THRESHOLD:
			return _failure("Move the stick or trigger at least halfway.")
		override["axis"] = event.axis
		override["axis_value"] = -1.0 if event.axis_value < 0.0 else 1.0
	else:
		return _failure("This input type cannot be used for skating controls.")
	var candidate := _bindings.duplicate(true)
	var action_binding: Dictionary = candidate.get(action, {}).duplicate(true)
	if override.has("key"):
		action_binding["key"] = override["key"]
	else:
		for key: String in ["button", "axis", "axis_value"]:
			action_binding.erase(key)
		action_binding.merge(override)
	candidate[action] = action_binding
	if not apply_saved(candidate):
		return _failure(last_error)
	return {"ok": true, "error": "", "bindings": _bindings.duplicate(true)}

static func apply_saved(bindings: Dictionary) -> bool:
	var validation := validate_saved(bindings)
	if not validation["ok"]:
		last_error = validation["error"]
		return false
	_ensure_defaults()
	var candidate: Dictionary = _defaults.duplicate(true)
	for action: String in validation["bindings"]:
		var override: Dictionary = validation["bindings"][action]
		var events: Array = candidate[action]
		if override.has("key"):
			events = events.filter(func(event: InputEvent) -> bool: return not event is InputEventKey)
			var key_event := InputEventKey.new()
			key_event.physical_keycode = int(override["key"])
			events.append(key_event)
		if override.has("button") or override.has("axis"):
			events = events.filter(func(event: InputEvent) -> bool:
				return not (event is InputEventJoypadButton or event is InputEventJoypadMotion))
			if override.has("button"):
				var button_event := InputEventJoypadButton.new()
				button_event.device = -1
				button_event.button_index = int(override["button"])
				events.append(button_event)
			else:
				var axis_event := InputEventJoypadMotion.new()
				axis_event.device = -1
				axis_event.axis = int(override["axis"])
				axis_event.axis_value = float(override["axis_value"])
				events.append(axis_event)
		candidate[action] = events
	var conflict := _find_conflict(candidate)
	if not conflict.is_empty():
		last_error = conflict
		return false
	for action: String in ACTION_LABELS:
		Input.action_release(action)
		InputMap.action_erase_events(action)
		for event: InputEvent in candidate[action]:
			InputMap.action_add_event(action, event.duplicate())
	_bindings = validation["bindings"].duplicate(true)
	last_error = ""
	return true

static func reset_defaults() -> Dictionary:
	for action: String in ACTION_LABELS:
		if InputMap.has_action(action):
			Input.action_release(action)
			InputMap.action_erase_events(action)
			InputMap.action_set_deadzone(action, 0.2)
	InputSetup.register_actions()
	_defaults = _snapshot_map()
	_bindings.clear()
	last_error = ""
	return {}

static func validate_saved(raw: Variant) -> Dictionary:
	## Pure schema validation: no disk, InputMap mutation or arbitrary event deserialization.
	if not raw is Dictionary:
		return {"ok": false, "error": "Bindings must be a dictionary.", "bindings": {}}
	var cleaned: Dictionary = {}
	var used: Dictionary = {}
	for action: Variant in raw:
		if not action is String or not ACTION_LABELS.has(action):
			return {"ok": false, "error": "Bindings contain an unknown action.", "bindings": {}}
		var value: Variant = raw[action]
		if not value is Dictionary or value.is_empty():
			return {"ok": false, "error": "Each binding needs a keyboard or controller input.", "bindings": {}}
		for key: Variant in value:
			if key not in ["key", "button", "axis", "axis_value"]:
				return {"ok": false, "error": "Binding data contains an unsupported field.", "bindings": {}}
		var entry: Dictionary = {}
		if value.has("key"):
			if not _whole(value["key"]) or not _valid_key(int(value["key"])):
				return {"ok": false, "error": "Choose a supported physical key.", "bindings": {}}
			var code := int(value["key"])
			if code in [KEY_ENTER, KEY_KP_ENTER] or (code == KEY_ESCAPE and action != "pause"):
				return {"ok": false, "error": "Escape and Enter are reserved for pause and menu navigation.", "bindings": {}}
			if action == "pause" and code != KEY_ESCAPE:
				return {"ok": false, "error": "Escape stays available for pause and menu recovery.", "bindings": {}}
			entry["key"] = code
		if value.has("button"):
			if value.has("axis") or value.has("axis_value") or not _whole(value["button"]) or int(value["button"]) < 0 or int(value["button"]) >= JOY_BUTTON_MAX:
				return {"ok": false, "error": "Choose one valid controller button or signed axis.", "bindings": {}}
			entry["button"] = int(value["button"])
		if value.has("axis") or value.has("axis_value"):
			if not AXIS_ACTIONS.has(action):
				return {"ok": false, "error": "This action needs a key or controller button, not a held axis.", "bindings": {}}
			if not value.has_all(["axis", "axis_value"]) or not _whole(value["axis"]) or int(value["axis"]) < 0 or int(value["axis"]) >= JOY_AXIS_MAX:
				return {"ok": false, "error": "Choose a valid controller axis and direction.", "bindings": {}}
			var direction: Variant = value["axis_value"]
			if not (direction is int or direction is float) or not is_finite(float(direction)) or absf(float(direction)) != 1.0:
				return {"ok": false, "error": "Axis direction must be -1 or +1.", "bindings": {}}
			if int(value["axis"]) in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT] and float(direction) < 0.0:
				return {"ok": false, "error": "Triggers use their positive pressed direction.", "bindings": {}}
			entry["axis"] = int(value["axis"])
			entry["axis_value"] = float(direction)
		if entry.is_empty():
			return {"ok": false, "error": "A binding has no usable input.", "bindings": {}}
		for token: String in _binding_tokens(entry):
			if used.has(token) and used[token] != action:
				return {"ok": false, "error": "That input is already assigned to " + ACTION_LABELS[used[token]] + ".", "bindings": {}}
			used[token] = action
		cleaned[action] = entry
	return {"ok": true, "error": "", "bindings": cleaned}

static func _ensure_defaults() -> void:
	if not _defaults.is_empty():
		return
	# Derive canonical bindings from the one existing setup source, then restore live state.
	var previous: Dictionary = _snapshot_map()
	for action: String in previous:
		InputMap.action_erase_events(action)
	InputSetup.register_actions()
	_defaults = _snapshot_map()
	for action: String in previous:
		InputMap.action_erase_events(action)
		for event: InputEvent in previous[action]:
			InputMap.action_add_event(action, event)

static func _snapshot_map() -> Dictionary:
	var result: Dictionary = {}
	for action: String in ACTION_LABELS:
		if InputMap.has_action(action):
			result[action] = InputMap.action_get_events(action).duplicate(true)
	return result

static func _find_conflict(map: Dictionary) -> String:
	var used: Dictionary = {}
	for action: String in map:
		for event: InputEvent in map[action]:
			var token := ""
			if event is InputEventKey:
				token = "key:%d" % (event.physical_keycode if event.physical_keycode != 0 else event.keycode)
			elif event is InputEventJoypadButton:
				token = "button:%d" % event.button_index
			elif event is InputEventJoypadMotion:
				token = "axis:%d:%d" % [event.axis, -1 if event.axis_value < 0 else 1]
			if token.is_empty():
				continue
			if used.has(token) and used[token] != action:
				return "That input is already assigned to " + ACTION_LABELS[used[token]] + "."
			used[token] = action
	return ""

static func _binding_tokens(binding: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if binding.has("key"):
		result.append("key:%d" % binding["key"])
	if binding.has("button"):
		result.append("button:%d" % binding["button"])
	if binding.has("axis"):
		result.append("axis:%d:%d" % [binding["axis"], int(binding["axis_value"])])
	return result

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= 0 and float(value) <= 16777215

static func _valid_key(code: int) -> bool:
	if code in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK, KEY_NUMLOCK, KEY_SCROLLLOCK]:
		return false
	return (code >= KEY_SPACE and code <= KEY_ASCIITILDE) or (code >= KEY_ESCAPE and code <= KEY_F35)

static func _failure(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "error": message, "bindings": _bindings.duplicate(true)}

static func _button_text(button: int) -> String:
	var names := {JOY_BUTTON_A: "Cross", JOY_BUTTON_B: "Circle", JOY_BUTTON_X: "Square", JOY_BUTTON_Y: "Triangle",
		JOY_BUTTON_BACK: "Create", JOY_BUTTON_GUIDE: "PS", JOY_BUTTON_START: "Options",
		JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_LEFT_SHOULDER: "L1",
		JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_DPAD_UP: "D-pad up", JOY_BUTTON_DPAD_DOWN: "D-pad down",
		JOY_BUTTON_DPAD_LEFT: "D-pad left", JOY_BUTTON_DPAD_RIGHT: "D-pad right", JOY_BUTTON_TOUCHPAD: "Touchpad"}
	return names.get(button, "Button %d" % button)

static func _axis_text(axis: int, direction: float) -> String:
	match axis:
		JOY_AXIS_LEFT_X: return "Left stick left" if direction < 0 else "Left stick right"
		JOY_AXIS_LEFT_Y: return "Left stick up" if direction < 0 else "Left stick down"
		JOY_AXIS_RIGHT_X: return "Right stick left" if direction < 0 else "Right stick right"
		JOY_AXIS_RIGHT_Y: return "Right stick up" if direction < 0 else "Right stick down"
		JOY_AXIS_TRIGGER_LEFT: return "L2"
		JOY_AXIS_TRIGGER_RIGHT: return "R2"
	return "Axis %d %s" % [axis, "−" if direction < 0 else "+"]
