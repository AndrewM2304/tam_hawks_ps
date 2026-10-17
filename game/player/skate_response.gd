extends RefCounted
## Original bounded street response. Collision, pushing, braking and tricks
## remain with Skater; this helper never reconstructs a travel velocity.

const COAST_BASE_DECELERATION := 1.0
const COAST_SPEED_RESISTANCE := 0.2
const REFERENCE_SPEED := 15.0
const GROUND_TURN_SLOW := 2.3
const GROUND_TURN_FAST := 1.1
const GROUND_RESPONSE_TIME := 0.10
const AIR_TURN_RATE := 0.50

var _ground_turn_rate := 0.0


func reset() -> void:
	_ground_turn_rate = 0.0


func coast_speed(speed: float, delta: float) -> float:
	if not is_finite(speed) or speed <= 0.0:
		return 0.0
	if not is_finite(delta) or delta <= 0.0:
		return speed
	# Exact integration of ds/dt = -(base + resistance * s), followed by a
	# stop at zero. Splitting the same duration across physics ticks is stable.
	var offset := COAST_BASE_DECELERATION / COAST_SPEED_RESISTANCE
	return maxf(0.0, (speed + offset) * exp(-COAST_SPEED_RESISTANCE * delta) - offset)


func steering_step(input: float, speed: float, grounded: bool, delta: float) -> float:
	if not is_finite(delta) or delta <= 0.0:
		return 0.0
	var steer := clampf(input, -1.0, 1.0) if is_finite(input) else 0.0
	if not grounded:
		# A jump cannot inherit a fast ground carve, and a release cannot keep
		# bending flight. Air correction is immediate but deliberately small.
		reset()
		var air_angle := -steer * AIR_TURN_RATE * delta
		return air_angle if is_finite(air_angle) else 0.0
	var speed_fraction := clampf(speed / REFERENCE_SPEED, 0.0, 1.0) if is_finite(speed) else 0.0
	var target_rate := -steer * lerpf(GROUND_TURN_SLOW, GROUND_TURN_FAST, speed_fraction)
	var decay := exp(-delta / GROUND_RESPONSE_TIME)
	# Integrate the response as well as updating its end value. At fixed input
	# and speed, 30/60/120 Hz therefore produce the same total heading change.
	var angle := target_rate * delta + (_ground_turn_rate - target_rate) * GROUND_RESPONSE_TIME * (1.0 - decay)
	_ground_turn_rate = target_rate + (_ground_turn_rate - target_rate) * decay
	return angle if is_finite(angle) else 0.0
