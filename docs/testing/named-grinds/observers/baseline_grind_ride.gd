extends RefCounted
## Original ride state around the attributed MIT geometry helper. World units are metres.
## Capture and balance patterns were reviewed in docs/research/SKATING_REUSE.md.
## The caller owns collision sweeps, input edges, cooldowns, scoring and player transitions.

const GrindLine = preload("res://game/tricks/grind_line.gd")
const CAPTURE_RADIUS: float = 0.85
const VERTICAL_REACH: float = 0.60
const BELOW_ALLOWANCE: float = 0.14
const APPROACH_COS: float = 0.4226182617 # cos(65 degrees), measured in the horizontal plane.
const ENTRY_SPEED: float = 2.0
const MAX_SPEED: float = 18.0
const RELEASE_SPEED: float = 1.0
const GRAVITY: float = 22.0
const FRICTION: float = 0.6 # Linear speed loss in metres/second squared.
const END_EPSILON: float = 0.001
const CAPTURE_SWEEP_STEP: float = 0.10
const MAX_CAPTURE_SWEEP: float = 1.0

var active: bool = false
var line: GrindLine = null
var distance: float = 0.0
var direction: float = 1.0
var speed: float = 0.0
var balance: float = 0.0
var elapsed: float = 0.0
var _position: Vector3 = Vector3.ZERO
var _velocity: Vector3 = Vector3.ZERO
var _result: String = "slow"


## Capture the nearest eligible line. Optional clearance receives world-space from/to.
## A failed attempt leaves no active ride. A request during an active ride is ignored.
func start(lines: Array, from: Vector3, velocity: Vector3,
		clearance: Callable = Callable()) -> bool:
	if active:
		return false
	if not from.is_finite() or not velocity.is_finite() or velocity.y > 1.0:
		return false
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < 0.000001:
		return false
	var best: GrindLine = null
	var best_distance: float = 0.0
	var best_direction: float = 1.0
	var best_speed: float = 0.0
	var best_gap: float = INF
	for candidate in lines:
		if not candidate is GrindLine or not candidate.is_valid:
			continue
		if not is_finite(candidate.length) or candidate.length <= END_EPSILON:
			continue
		var near: Dictionary = candidate.closest(from)
		if not near.has_all(["point", "dist", "gap"]):
			continue
		var at: Vector3 = near.point
		var offset: float = near.dist
		var gap: float = near.gap
		if not at.is_finite() or not is_finite(offset) or not is_finite(gap):
			continue
		var height: float = from.y - at.y
		if absf(height) > VERTICAL_REACH or height < -BELOW_ALLOWANCE:
			continue
		if gap > CAPTURE_RADIUS or gap >= best_gap:
			continue
		var tangent: Vector3 = candidate.dir_at(offset)
		var horizontal_tangent := Vector3(tangent.x, 0.0, tangent.z)
		if not tangent.is_finite() or horizontal_tangent.length_squared() < 0.000001:
			continue
		var alignment: float = horizontal.normalized().dot(horizontal_tangent.normalized())
		if absf(alignment) < APPROACH_COS:
			continue
		var signed_direction: float = signf(alignment)
		var projected_speed: float = velocity.dot(tangent) * signed_direction
		# A deliberate angled catch redirects momentum without discarding most
		# of its speed. Never convert falling velocity into a horizontal boost.
		projected_speed = maxf(projected_speed, horizontal.length() * lerpf(0.9, 1.0, absf(alignment)))
		if not is_finite(projected_speed) or projected_speed < ENTRY_SPEED or projected_speed > MAX_SPEED:
			continue
		if not candidate.is_loop and (offset <= END_EPSILON and signed_direction < 0.0
				or offset >= candidate.length - END_EPSILON and signed_direction > 0.0):
			continue
		if clearance.is_valid() and clearance.call(from, at) != true:
			continue
		best = candidate
		best_distance = offset
		best_direction = signed_direction
		best_speed = projected_speed
		best_gap = gap
	if best == null:
		return false
	line = best
	distance = best_distance
	direction = best_direction
	speed = best_speed
	balance = 0.0
	elapsed = 0.0
	active = true
	_result = "riding"
	_sample()
	return true


## Recover a capture window crossed during one completed physics move. `to` is
## the body's actual current origin, never a predicted position. Keep the same
## admission envelope as point capture; do not widen it with speed or frame time.
## Clearance always starts at that actual origin, including for earlier samples.
func start_swept(lines: Array, from: Vector3, to: Vector3, velocity: Vector3,
		clearance: Callable = Callable()) -> bool:
	if active or not from.is_finite() or not to.is_finite() or not velocity.is_finite():
		return false
	var travel: float = from.distance_to(to)
	if not is_finite(travel) or travel > MAX_CAPTURE_SWEEP:
		return false
	var sample_count: int = maxi(1, ceili(travel / CAPTURE_SWEEP_STEP))
	var actual_origin_clearance := func(_sample_origin: Vector3, at: Vector3) -> bool:
		return not clearance.is_valid() or clearance.call(to, at) == true
	for i in range(sample_count + 1):
		var sample_origin: Vector3 = from.lerp(to, float(i) / sample_count)
		if start(lines, sample_origin, velocity, actual_origin_clearance):
			return true
	return false


## Positive input tips toward positive balance; counter that lean with negative input.
## Released position and travel velocity remain available until the next capture.
func step(delta: float, balance_input: float) -> String:
	if not active:
		return _result
	if not is_finite(delta) or delta < 0.0 or not is_finite(balance_input):
		return _release("bail")
	if (line == null or not line.is_valid or not is_finite(distance)
			or not is_finite(speed) or not is_finite(balance) or not is_finite(elapsed)
			or absf(direction) != 1.0):
		return _release("bail")
	if delta == 0.0:
		return "riding"
	var tangent: Vector3 = line.dir_at(distance) * direction
	if not tangent.is_finite() or tangent.length_squared() < 0.5:
		return _release("bail")
	var next_speed: float = clampf(speed + (-tangent.y * GRAVITY - FRICTION) * delta, 0.0, MAX_SPEED)
	var next_distance: float = distance + direction * (speed + next_speed) * 0.5 * delta
	var next_elapsed: float = elapsed + delta
	var next_balance: float = balance + (0.14 + balance * 0.75 * (1.0 + elapsed * 0.15)
		+ clampf(balance_input, -1.0, 1.0)) * delta
	if not is_finite(next_distance) or not is_finite(next_elapsed) or not is_finite(next_balance):
		return _release("bail")
	speed = next_speed
	distance = fposmod(next_distance, line.length) if line.is_loop else clampf(next_distance, 0.0, line.length)
	elapsed = next_elapsed
	balance = next_balance
	_sample()
	if not line.is_loop and (next_distance <= 0.0 or next_distance >= line.length):
		return _release("end")
	if absf(balance) >= 1.0:
		return _release("bail")
	if speed < RELEASE_SPEED:
		return _release("slow")
	return "riding"


func position() -> Vector3:
	return _position


func travel_velocity() -> Vector3:
	return _velocity


func stop() -> void:
	_release("slow")


func _sample() -> void:
	_position = line.point_at(distance)
	_velocity = line.dir_at(distance) * direction * speed


func _release(reason: String) -> String:
	active = false
	_result = reason
	return reason
