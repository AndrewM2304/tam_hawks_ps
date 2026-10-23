extends RefCounted
## Directional trick selection reuses live remapped movement actions.
## A direction released just before a trick remains available for 0.18 seconds.

const DIRECTION_MEMORY := 0.18
const AXIS_THRESHOLD := 0.5

var _held := "neutral"
var _recent := "neutral"
var _age := DIRECTION_MEMORY + 1.0
var _edge_age := DIRECTION_MEMORY + 1.0
var _memory_suppressed := false

func reset() -> void:
	_held = "neutral"
	_recent = "neutral"
	_age = DIRECTION_MEMORY + 1.0
	_edge_age = DIRECTION_MEMORY + 1.0
	_memory_suppressed = false

func clear_recent() -> void:
	# A takeoff clears released approach cues without manufacturing a new press.
	# The current direction remains usable while physically held. Once released,
	# it is remembered only after another genuine direction edge.
	_recent = "neutral"
	_age = DIRECTION_MEMORY + 1.0
	_memory_suppressed = _held != "neutral"

func sample(delta: float) -> void:
	# Inspect raw strengths as well as their difference: opposing controls must
	# cancel a remembered cue immediately, not after its release grace expires.
	sample_strengths(Input.get_action_strength("push"), Input.get_action_strength("brake"),
		Input.get_action_strength("steer_left"), Input.get_action_strength("steer_right"), delta)

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
	var previous_held := _held
	_held = direction_for_axes(axes)
	_edge_age = minf(3600.0, _edge_age + delta)
	if _held != "neutral" and _held != previous_held:
		_edge_age = 0.0
		_memory_suppressed = false
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
