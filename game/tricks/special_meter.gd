extends RefCounted
## Earned from resolved bank events only. Eligibility/unlocks belong to the caller.

const CAPACITY: float = 100.0
const POINTS_PER_UNIT: float = 25.0
const MAX_BANK_GAIN: float = 50.0

var value: float = 0.0


func earn_bank(points: int) -> void:
	_sanitize()
	if points <= 0:
		return
	value = minf(CAPACITY, value + minf(float(points) / POINTS_PER_UNIT, MAX_BANK_GAIN))


func consume() -> bool:
	_sanitize()
	if value < CAPACITY:
		return false
	value = 0.0
	return true


func reset() -> void:
	value = 0.0


func _sanitize() -> void:
	value = clampf(value, 0.0, CAPACITY) if is_finite(value) else 0.0
