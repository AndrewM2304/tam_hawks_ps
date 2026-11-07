extends RefCounted
## Original ordered, swept gap triggers; no physics nodes or external dependencies.
## Positions are world-space board contacts. Call only during active play and reset
## after bail/restart. A first update establishes position; it cannot award a gap.

const WINDOW: float = 4.0
const MAX_STEP_DISTANCE: float = 20.0
const MAX_POINTS: int = 1000000
const EPSILON: float = 0.000001

var _definitions: Array[Dictionary] = []
var _states: Array[Dictionary] = []
var _previous: Vector3 = Vector3.ZERO
var _previous_airborne: bool = false
var _has_previous: bool = false


## Duplicate IDs, overlapping start/end spheres and malformed entries are ignored.
## Snapshot definitions so later level-authoring edits do not mutate an active route.
func configure(definitions: Array) -> void:
	_definitions.clear()
	var ids: Dictionary = {}
	for raw in definitions:
		if not raw is Dictionary or not raw.has_all([
			"id", "name", "start", "end", "radius", "points", "airborne_required"]):
			continue
		if not raw.id is String or String(raw.id).strip_edges().is_empty() or ids.has(raw.id):
			continue
		if not raw.name is String or String(raw.name).strip_edges().is_empty():
			continue
		if not raw.start is Vector3 or not raw.end is Vector3 or not raw.airborne_required is bool:
			continue
		if not raw.radius is float and not raw.radius is int:
			continue
		if not raw.points is int or raw.points <= 0 or raw.points > MAX_POINTS:
			continue
		var start: Vector3 = raw.start
		var end: Vector3 = raw.end
		var radius: float = raw.radius
		var route: Vector3 = end - start
		var length: float = route.length()
		if not start.is_finite() or not end.is_finite() or not is_finite(radius) or radius <= 0.0:
			continue
		if not is_finite(length) or length <= radius * 2.0 + EPSILON:
			continue
		var entry: Dictionary = raw.duplicate(true)
		entry["direction"] = route / length
		_definitions.append(entry)
		ids[raw.id] = true
	reset()


func reset() -> void:
	_has_previous = false
	_states.clear()
	for _definition in _definitions:
		_states.append({"phase": "ready", "elapsed": 0.0, "air": false})


## Awards have only {id, name, points}. Each route resolves once before leaving both
## triggers. A segment may cross both triggers in one step, with ordered entry times.
func update(position: Vector3, airborne: bool, delta: float) -> Array[Dictionary]:
	var awards: Array[Dictionary] = []
	if not position.is_finite() or not is_finite(delta) or delta < 0.0:
		reset()
		return awards
	if not _has_previous:
		_previous = position
		_previous_airborne = airborne
		_has_previous = true
		return awards
	var displacement: Vector3 = position - _previous
	var movement: float = displacement.length()
	if not is_finite(movement) or movement > MAX_STEP_DISTANCE or (delta == 0.0 and movement > EPSILON):
		_lock_all()
		_previous = position
		_previous_airborne = airborne
		return awards
	for index in _definitions.size():
		var definition: Dictionary = _definitions[index]
		var state: Dictionary = _states[index]
		if state.phase == "locked":
			if _outside_both(position, definition):
				state.phase = "ready"
			continue
		var forward: float = displacement.dot(definition.direction)
		var start_t: float = _sphere_entry(_previous, position, definition.start, definition.radius)
		var end_t: float = _sphere_entry(_previous, position, definition.end, definition.radius)
		var elapsed_before: float = state.elapsed
		if state.phase == "ready":
			if start_t < 0.0 or forward <= EPSILON:
				continue
			state.phase = "armed"
			state.air = false
			# Count time after crossing the start, not time before reaching it.
			elapsed_before = -delta * start_t
		elif forward < -EPSILON:
			state.phase = "locked"
			continue
		if end_t >= 0.0 and forward > EPSILON:
			var flight_time: float = maxf(0.0, elapsed_before + delta * end_t)
			var ordered: bool = start_t < 0.0 or end_t > start_t + EPSILON
			# Being airborne only at the final sample is insufficient evidence of air
			# between triggers. A fully aerial swept step may still cross both at once.
			var air_between: bool = state.air or (_previous_airborne and airborne)
			var required_air: bool = not definition.airborne_required or (air_between and airborne)
			if ordered and flight_time <= WINDOW and required_air:
				awards.append({"id": definition.id, "name": definition.name, "points": definition.points})
			state.phase = "locked"
			continue
		state.air = state.air or airborne
		state.elapsed = maxf(0.0, elapsed_before + delta)
		if state.elapsed > WINDOW:
			state.phase = "locked"
	_previous = position
	_previous_airborne = airborne
	return awards


func _lock_all() -> void:
	for state in _states:
		state.phase = "locked"
		state.elapsed = 0.0
		state.air = false


static func _outside_both(position: Vector3, definition: Dictionary) -> bool:
	var squared_radius: float = definition.radius * definition.radius
	return (position.distance_squared_to(definition.start) > squared_radius
		and position.distance_squared_to(definition.end) > squared_radius)


## First contact fraction on [0,1], or -1 for no intersection. Starting inside is 0.
static func _sphere_entry(from: Vector3, to: Vector3, center: Vector3, radius: float) -> float:
	var offset: Vector3 = from - center
	var radius_squared: float = radius * radius
	if offset.length_squared() <= radius_squared:
		return 0.0
	var segment: Vector3 = to - from
	var squared_length: float = segment.length_squared()
	if squared_length < EPSILON * EPSILON:
		return -1.0
	var half_b: float = offset.dot(segment)
	var c: float = offset.length_squared() - radius_squared
	var discriminant: float = half_b * half_b - squared_length * c
	if discriminant < 0.0 or not is_finite(discriminant):
		return -1.0
	var entry: float = (-half_b - sqrt(discriminant)) / squared_length
	if entry < 0.0 or entry > 1.0:
		return -1.0
	return entry
