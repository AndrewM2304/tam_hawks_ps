extends RefCounted
## Live performance charge. Main ticks only during active, unpaused play.
## Full charge enters a sustained state; specials no longer spend it all at once.

const CAPACITY: float = 100.0
const POINTS_PER_UNIT: float = 10.0
const MAX_TRICK_GAIN: float = 50.0
const ACTIVE_SECONDS: float = 6.0
const COMBO_DRAIN_SCALE: float = 0.5
const IDLE_GRACE_SECONDS: float = 2.0
const IDLE_DRAIN_PER_SECOND: float = 4.0
const MAX_EVENT_POINTS: int = 1000000
## Compatibility name for older tools; production earns from accepted tricks.
const MAX_BANK_GAIN: float = MAX_TRICK_GAIN

var value: float = 0.0
var active: bool = false
var _idle_seconds: float = 0.0


## Return the actual gain for truthful feedback. Invalid events change nothing.
func earn_trick(points: int) -> float:
	_sanitize()
	if points <= 0:
		return 0.0
	var before := value
	var gain := minf(float(mini(points, MAX_EVENT_POINTS)) / POINTS_PER_UNIT, MAX_TRICK_GAIN)
	value = minf(CAPACITY, value + gain)
	_idle_seconds = 0.0
	if value >= CAPACITY:
		active = true
	return value - before


## Deprecated compatibility alias. Main must not also earn at bank time.
func earn_bank(points: int) -> float:
	return earn_trick(points)


func ready() -> bool:
	_sanitize()
	return active and value > 0.0


func consume() -> bool:
	# Eligibility/unlocks and accepted player execution still belong to Main.
	return ready()


func tick(delta: float, combo_active: bool = false) -> void:
	_sanitize()
	if not is_finite(delta) or delta <= 0.0:
		return
	var previous_idle := _idle_seconds
	_idle_seconds = minf(3600.0, _idle_seconds + delta)
	if active:
		var drain := CAPACITY / ACTIVE_SECONDS
		if combo_active:
			drain *= COMBO_DRAIN_SCALE
		value = maxf(0.0, value - drain * delta)
	elif _idle_seconds > IDLE_GRACE_SECONDS:
		var decaying_time := _idle_seconds - maxf(previous_idle, IDLE_GRACE_SECONDS)
		value = maxf(0.0, value - IDLE_DRAIN_PER_SECOND * decaying_time)
	if value <= 0.000000001:
		value = 0.0
		active = false


func on_bail() -> void:
	reset()


func reset() -> void:
	value = 0.0
	active = false
	_idle_seconds = 0.0


func _sanitize() -> void:
	if not is_finite(value):
		reset()
		return
	value = clampf(value, 0.0, CAPACITY)
	if value <= 0.0:
		active = false
	elif value >= CAPACITY:
		# Support explicit full-meter fixtures and older debug callers.
		active = true
