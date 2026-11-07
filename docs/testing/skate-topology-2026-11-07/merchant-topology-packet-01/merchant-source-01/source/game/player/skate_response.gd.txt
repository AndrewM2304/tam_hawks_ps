extends RefCounted
## Original bounded street response. Collision, pushing, braking and tricks
## remain with Skater; this helper never reconstructs a travel velocity.

const COAST_BASE_DECELERATION := 1.0
const COAST_SPEED_RESISTANCE := 0.2
const REFERENCE_SPEED := 15.0
const GROUND_TURN_SLOW := 2.8
const GROUND_TURN_FAST := 2.2
const GROUND_RESPONSE_TIME := 0.055
const ANALOG_LINEAR_WEIGHT := 0.75
const AIR_TURN_RATE := 0.50
const SLOPE_GRAVITY_SCALE := 0.28

var _ground_turn_rate := 0.0


func reset() -> void:
	_ground_turn_rate = 0.0


func coast_speed(speed: float, delta: float) -> float:
	if not is_finite(speed):
		return 0.0
	if not is_finite(delta) or delta <= 0.0:
		return speed
	if is_zero_approx(speed):
		return 0.0
	# Exact integration of ds/dt = -(base + resistance * s), followed by a
	# stop at zero. Retain the sign so hills can produce controlled rollback.
	# Splitting the same duration across physics ticks is stable.
	var offset := COAST_BASE_DECELERATION / COAST_SPEED_RESISTANCE
	var magnitude := maxf(0.0, (absf(speed) + offset) * exp(-COAST_SPEED_RESISTANCE * delta) - offset)
	return signf(speed) * magnitude


func apply_slope_gravity(speed: float, downhill_alignment: float, delta: float, gravity: float) -> float:
	if not is_finite(speed) or not is_finite(downhill_alignment) or not is_finite(delta) \
			or not is_finite(gravity):
		return 0.0
	if delta <= 0.0 or gravity < 0.0:
		return clampf(speed, -REFERENCE_SPEED, REFERENCE_SPEED)
	# Alignment is the gravity component projected onto the board's forward
	# tangent. The modest scale gives ramps a readable push while street speed
	# and skateable courses retain an arcade feel.
	var slope_speed := speed + clampf(downhill_alignment, -1.0, 1.0) \
		* gravity * SLOPE_GRAVITY_SCALE * delta
	return clampf(slope_speed, -REFERENCE_SPEED, REFERENCE_SPEED)


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
	var speed_fraction := clampf(absf(speed) / REFERENCE_SPEED, 0.0, 1.0) if is_finite(speed) else 0.0
	# Keep full-stick carving useful inside the existing streets without making
	# a small correction as aggressive. A mostly linear, symmetric curve has no
	# extra deadzone; Godot's mapped axis already owns that device preference.
	var shaped_steer := lerpf(steer * steer * steer, steer, ANALOG_LINEAR_WEIGHT)
	var target_rate := -shaped_steer * lerpf(GROUND_TURN_SLOW, GROUND_TURN_FAST, speed_fraction)
	var decay := exp(-delta / GROUND_RESPONSE_TIME)
	# Integrate the response as well as updating its end value. At fixed input
	# and speed, 30/60/120 Hz therefore produce the same total heading change.
	var angle := target_rate * delta + (_ground_turn_rate - target_rate) * GROUND_RESPONSE_TIME * (1.0 - decay)
	_ground_turn_rate = target_rate + (_ground_turn_rate - target_rate) * decay
	return angle if is_finite(angle) else 0.0
