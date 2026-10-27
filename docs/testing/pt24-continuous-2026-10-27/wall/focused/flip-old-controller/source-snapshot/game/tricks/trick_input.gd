extends RefCounted
## Directional trick selection reuses live remapped movement actions.
## A direction released just before a trick remains available for 0.18 seconds.
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const DirectionalTricks = preload("res://game/tricks/directional_tricks.gd")

const DIRECTION_MEMORY := 0.18
const AXIS_THRESHOLD := 0.5
const ACTION_MEMORY := 0.18
const MAX_QUEUE_AGE := 0.45
const DOUBLE_TAP_SECONDS := 0.22
const MIN_TAP_GAP := 0.025
const MANUAL_GESTURE_SECONDS := 0.22
const ADVANCED_DIRECTION_SECONDS := 0.30
const SPECIAL_SEQUENCE_SECONDS := 0.45
const MAX_ACTIONS := 16
const TRICK_ACTIONS: Array[String] = ["ollie", "flip", "grab", "grind", "manual", "revert",
	"special_one", "special_two", "spin_left", "spin_right"]

var _held := "neutral"
var _recent := "neutral"
var _age := DIRECTION_MEMORY + 1.0
var _edge_age := DIRECTION_MEMORY + 1.0
var _memory_suppressed := false
var _clock := 0.0
var _actions: Array[Dictionary] = []
var _button_held: Dictionary = {}
var _last_press: Dictionary = {}
var _tap_counts: Dictionary = {}
var _direction_edges: Array[Dictionary] = []
var _manual_gesture := ""
var _manual_gesture_at := -1.0
var _sampled_axes := Vector2.ZERO

func reset() -> void:
	_held = "neutral"
	_recent = "neutral"
	_age = DIRECTION_MEMORY + 1.0
	_edge_age = DIRECTION_MEMORY + 1.0
	_memory_suppressed = false
	_clock = 0.0
	_sampled_axes = Vector2.ZERO
	_button_held.clear()
	clear_actions()

func synchronize_held() -> void:
	# Runtime resets must observe existing holds without inventing button edges
	# or direction flicks. Pure reset() remains deterministic for replay tools.
	sample(0.0)
	clear_actions()
	clear_recent()
	_edge_age = DIRECTION_MEMORY + 1.0


func clear_actions() -> void:
	# Preserve physical held states so disabling/re-enabling input cannot invent
	# another fresh press. Release and press again is required after a clear.
	_actions.clear()
	_last_press.clear()
	_tap_counts.clear()
	_direction_edges.clear()
	_manual_gesture = ""
	_manual_gesture_at = -1.0

func clear_recent() -> void:
	# A takeoff clears released approach cues without manufacturing a new press.
	# The current direction remains usable while physically held. Once released,
	# it is remembered only after another genuine direction edge.
	_recent = "neutral"
	_age = DIRECTION_MEMORY + 1.0
	_memory_suppressed = _held != "neutral"
	_direction_edges.clear()
	_manual_gesture = ""

func sample(delta: float) -> void:
	# Inspect raw strengths as well as their difference: opposing controls must
	# cancel a remembered cue immediately, not after its release grace expires.
	if not is_finite(delta) or delta < 0.0:
		return
	sample_strengths(_strength("push"), _strength("brake"), _strength("steer_left"), _strength("steer_right"), delta)
	var pressed: Array[String] = []
	for action: String in TRICK_ACTIONS:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			pressed.append(action)
	_sample_buttons(pressed)

func sample_frame(axes: Vector2, pressed_actions: Array, delta: float) -> void:
	# Deterministic seam: pressed_actions describes current held buttons, not a
	# stream of synthetic repeats. Runtime uses the same edge recognition below.
	if not is_finite(delta) or delta < 0.0:
		return
	if not axes.is_finite():
		reset()
		return
	sample_axes(axes, delta)
	_sample_buttons(pressed_actions)

func _strength(action: String) -> float:
	return Input.get_action_strength(action) if InputMap.has_action(action) else 0.0

func sample_strengths(north: float, south: float, west: float, east: float, delta: float) -> void:
	if not is_finite(delta) or delta < 0.0:
		return
	for strength: float in [north, south, west, east]:
		if not is_finite(strength):
			reset()
			return
	var cancel_horizontal := west >= AXIS_THRESHOLD and east >= AXIS_THRESHOLD
	var cancel_vertical := north >= AXIS_THRESHOLD and south >= AXIS_THRESHOLD
	if cancel_horizontal or cancel_vertical:
		_direction_edges.clear()
		_manual_gesture = ""
		var horizontal := "east" if _recent.contains("east") else ("west" if _recent.contains("west") else "")
		var vertical := "north" if _recent.contains("north") else ("south" if _recent.contains("south") else "")
		if cancel_horizontal:
			horizontal = ""
		if cancel_vertical:
			vertical = ""
		_recent = vertical + "_" + horizontal if not vertical.is_empty() and not horizontal.is_empty() else vertical + horizontal
		if _recent.is_empty():
			_recent = "neutral"
			_age = DIRECTION_MEMORY + 1.0
	var horizontal_axis := 0.0 if cancel_horizontal else clampf(east, 0.0, 1.0) - clampf(west, 0.0, 1.0)
	var vertical_axis := 0.0 if cancel_vertical else clampf(south, 0.0, 1.0) - clampf(north, 0.0, 1.0)
	sample_axes(Vector2(horizontal_axis, vertical_axis), delta)

func sample_axes(axes: Vector2, delta: float) -> void:
	if not is_finite(delta) or delta < 0.0:
		return
	if not axes.is_finite():
		reset()
		return
	_clock += minf(delta, 3600.0)
	_expire()
	var previous_held := _held
	_sampled_axes = axes.limit_length(1.0)
	_held = direction_for_axes(axes)
	_edge_age = minf(3600.0, _edge_age + delta)
	if _held != "neutral" and _held != previous_held:
		_edge_age = 0.0
		_memory_suppressed = false
		_record_direction(_held,previous_held == "neutral")
	if _held != "neutral":
		if not _memory_suppressed:
			_recent = _held
			_age = 0.0
	else:
		_memory_suppressed = false
		_age = minf(DIRECTION_MEMORY + 1.0, _age + delta)

func direction() -> String:
	if _held != "neutral":
		return _held
	return _recent if _age <= DIRECTION_MEMORY else "neutral"

func direction_age() -> float:
	# Age of a deliberate direction edge; sustained pushing is not a new cue.
	return _edge_age

func has_action(action: String, max_age: float = ACTION_MEMORY) -> bool:
	# Read accepted edges without consuming a queued trick/extension. Native
	# just-pressed history can outlive a menu's release of its matching action.
	if not TRICK_ACTIONS.has(action) or not is_finite(max_age) or max_age < 0.0:
		return false
	var lifetime := minf(max_age, MAX_QUEUE_AGE)
	for entry: Dictionary in _actions:
		if entry.action == action and _clock - float(entry.at) <= lifetime + 0.0000001:
			return true
	return false

func pop_action(action: String, max_age: float = ACTION_MEMORY) -> Dictionary:
	if not TRICK_ACTIONS.has(action) or not is_finite(max_age) or max_age < 0.0:
		return {}
	_expire()
	var lifetime := minf(max_age, MAX_QUEUE_AGE)
	var index := 0
	while index < _actions.size():
		var entry: Dictionary = _actions[index]
		if entry.action != action:
			index += 1
			continue
		_actions.remove_at(index)
		if _clock - float(entry.at) > lifetime + 0.0000001:
			continue
		var result := entry.duplicate(true)
		result["age"] = maxf(0.0, _clock - float(entry.at))
		return result
	return {}

func consume_double_tap(action: String) -> bool:
	return not consume_tap_upgrade(action).is_empty()

func consume_tap_upgrade(action: String) -> Dictionary:
	if not TRICK_ACTIONS.has(action): return {}
	_expire()
	for index: int in _actions.size():
		var entry: Dictionary = _actions[index]
		if entry.action == action and bool(entry.double_tap) \
				and _clock - float(entry.at) <= ACTION_MEMORY + 0.0000001:
			# One second press upgrades one move; it cannot also queue another.
			_actions.remove_at(index)
			var result := entry.duplicate(true)
			result["age"] = maxf(0.0, _clock - float(entry.at))
			return result
	return {}

func consume_manual_gesture() -> String:
	_expire()
	var result := _manual_gesture
	_manual_gesture = ""
	return result

func consume_special() -> String:
	_expire()
	for index: int in _actions.size():
		var entry: Dictionary = _actions[index]
		if not String(entry.special_id).is_empty() \
				and _clock - float(entry.at) <= ACTION_MEMORY + 0.0000001:
			_actions.remove_at(index)
			_manual_gesture = ""
			return String(entry.special_id)
	return ""

func queued_action_count() -> int:
	_expire()
	return _actions.size()

func _sample_buttons(pressed_actions: Array) -> void:
	var pressed: Dictionary = {}
	for raw: Variant in pressed_actions:
		if raw is String and TRICK_ACTIONS.has(raw):
			pressed[raw] = true
	for action: String in TRICK_ACTIONS:
		var down: bool = pressed.get(action, false)
		if down and not bool(_button_held.get(action, false)):
			var gap := _clock - float(_last_press.get(action, -100.0))
			var double_tap := gap >= MIN_TAP_GAP and gap <= DOUBLE_TAP_SECONDS + 0.0000001
			var taps := mini(3, int(_tap_counts.get(action, 1)) + 1) if double_tap else 1
			_last_press[action] = _clock
			_tap_counts[action] = taps
			var special := _special_for(action)
			var advanced := _advanced_for(action)
			_actions.append({"action": action, "direction": direction(), "double_tap": double_tap,
				"tap_count": taps, "special_id": special, "advanced_direction": advanced,
				"axes": _sampled_axes,"at": _clock})
			if _actions.size() > MAX_ACTIONS:
				_actions.pop_front()
			if not special.is_empty() or advanced:
				_direction_edges.clear()
				_manual_gesture = ""
		_button_held[action] = down

func _record_direction(value: String, neutral_release: bool = false) -> void:
	_direction_edges.append({"direction": value, "at": _clock,"neutral_release":neutral_release})
	if _direction_edges.size() > 6:
		_direction_edges.pop_front()
	if _direction_edges.size() < 2:
		return
	var first: Dictionary = _direction_edges[-2]
	var second: Dictionary = _direction_edges[-1]
	if not bool(second.get("neutral_release",false)): return
	if float(second.at) - float(first.at) > MANUAL_GESTURE_SECONDS + 0.0000001:
		return
	if first.direction == "north" and second.direction == "south":
		_manual_gesture = "manual"
	elif first.direction == "south" and second.direction == "north":
		_manual_gesture = "nose_manual"
	else:
		return
	_manual_gesture_at = _clock


func _advanced_for(action: String) -> bool:
	if action not in ["flip","grab"] or _direction_edges.size() < 2: return false
	var first: Dictionary = _direction_edges[-2]
	var second: Dictionary = _direction_edges[-1]
	return first.direction == second.direction and bool(second.get("neutral_release",false)) \
		and float(second.at)-float(first.at) >= MIN_TAP_GAP \
		and _clock-float(first.at) <= ADVANCED_DIRECTION_SECONDS+0.0000001 \
		and _clock-float(second.at) <= DIRECTION_MEMORY+0.0000001


static func select_action(family: String, token: Dictionary, default_axes: Vector2) -> Dictionary:
	if family not in ["flip","grab"]: return {}
	if bool(token.get("advanced_direction",false)) and token.get("action") == family:
		return Catalog.resolve(family,str(token.get("direction","neutral")))
	var raw_axes: Variant = token.get("axes",default_axes)
	return DirectionalTricks.select(family,raw_axes) if raw_axes is Vector2 else {}

func _special_for(action: String) -> String:
	if _direction_edges.size() < 2:
		return ""
	var first: Dictionary = _direction_edges[-2]
	var second: Dictionary = _direction_edges[-1]
	if _clock - float(first.at) > SPECIAL_SEQUENCE_SECONDS + 0.0000001:
		return ""
	for command: Dictionary in Catalog.SPECIAL_COMMANDS:
		if command.action == action and command.directions == [first.direction, second.direction]:
			return str(command.id)
	return ""

func _expire() -> void:
	while not _actions.is_empty() and _clock - float(_actions[0].at) > MAX_QUEUE_AGE + 0.0000001:
		_actions.pop_front()
	while not _direction_edges.is_empty() and _clock - float(_direction_edges[0].at) > SPECIAL_SEQUENCE_SECONDS + 0.0000001:
		_direction_edges.pop_front()
	if _manual_gesture_at < 0.0 or _clock - _manual_gesture_at > ACTION_MEMORY + 0.0000001:
		_manual_gesture = ""

static func direction_for_axes(axes: Vector2) -> String:
	if not axes.is_finite():
		return "neutral"
	var bounded := axes.limit_length(1.0)
	var horizontal := "east" if bounded.x >= AXIS_THRESHOLD else ("west" if bounded.x <= -AXIS_THRESHOLD else "")
	var vertical := "south" if bounded.y >= AXIS_THRESHOLD else ("north" if bounded.y <= -AXIS_THRESHOLD else "")
	if not vertical.is_empty() and not horizontal.is_empty():
		return vertical + "_" + horizontal
	if not vertical.is_empty():
		return vertical
	return horizontal if not horizontal.is_empty() else "neutral"
