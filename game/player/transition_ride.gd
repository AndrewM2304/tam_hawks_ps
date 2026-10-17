extends RefCounted
## Original finite cylindrical transition contact. This helper proposes a board
## contact frame; the caller still moves the real collider and must reconcile its
## collision-adjusted position/velocity. It never moves a player or awards tricks.
## The surface-frame approach was researched in TRANSITION-SKATING.md; no upstream
## implementation or assets are copied here.

const GRAVITY := 22.0
const MAX_SPEED := 18.0
const PUSH_SPEED := 15.0
const PUSH_ACCELERATION := 6.0
const PUMP_ACCELERATION := 1.5
const BRAKE_DECELERATION := 12.0
const ROLL_DECELERATION := 0.18
const CAPTURE_GAP := 0.20
const PENETRATION_ALLOWANCE := 0.045
const END_ALLOWANCE := 0.035
const MAX_OUTWARD_SPEED := 1.0
const MAX_STEP_TIME := 0.25
const INTEGRATION_TIME := 1.0 / 240.0

var active := false
var feature: Dictionary = {}
var theta := 0.0
var across := 0.0
var along_speed := 0.0
var lateral_speed := 0.0
var unused_time := 0.0
var _position := Vector3.ZERO
var _normal := Vector3.UP
var _velocity := Vector3.ZERO
var _support := Callable()
var _result := "stopped"


## Features use an orthonormal, yaw-only toe transform, local +X across and -Z
## uphill. `support(world_point, world_normal, curve_body)` must confirm collision
## with that exact live body. A metadata tag alone is never enough to admit contact.
func try_start(features: Array, point: Vector3, velocity: Vector3,
		support: Callable) -> bool:
	if active or not point.is_finite() or not velocity.is_finite() or not support.is_valid():
		return false
	var nearest := INF
	var selected: Dictionary = {}
	var sample: Dictionary = {}
	for candidate in features:
		if not candidate is Dictionary or not _valid_feature(candidate):
			continue
		var contact := _closest(candidate, point)
		if contact.is_empty() or contact.gap >= nearest:
			continue
		var normal_velocity: float = velocity.dot(contact.normal)
		if normal_velocity > MAX_OUTWARD_SPEED:
			continue
		# Above the steep face, only a descending rider can acquire a new contact.
		# This prevents a fresh capture from cancelling an intentional vert takeoff.
		if contact.theta > deg_to_rad(65.0) and velocity.y > 0.25:
			continue
		if support.call(contact.point, contact.normal, candidate.body) != true:
			continue
		selected = candidate
		sample = contact
		nearest = contact.gap
	if selected.is_empty():
		return false
	feature = selected.duplicate()
	_support = support
	theta = sample.theta
	across = sample.across
	_adopt_velocity(velocity)
	_sample()
	active = true
	unused_time = 0.0
	_result = "riding"
	return true


## Signed arc velocity naturally crosses zero and rolls back. Steering rotates
## velocity in the tangent frame without adding speed. Only explicit push/pump
## input can add energy; brake/coast remove it. Curved integration is bounded to
## 240 Hz internally, independent of the caller's 30/60/120 Hz physics interval.
## Releases are `toe`, `lip`, `side`, `unsupported` or `invalid`; the contact point
## and tangent release velocity remain available after release.
func step(delta: float, steer: float, push: bool, brake: bool) -> String:
	if not active:
		return _result
	if (not is_finite(delta) or delta < 0.0 or delta > MAX_STEP_TIME
			or not is_finite(steer) or not _valid_state()):
		return _release("invalid")
	unused_time = 0.0
	if delta == 0.0:
		return "riding"
	if not _confirmed():
		return _release("unsupported")
	var remaining := delta
	while remaining > 0.0000001:
		var dt := minf(remaining, INTEGRATION_TIME)
		var speed := Vector2(along_speed, lateral_speed).length()
		var turn := clampf(steer, -1.0, 1.0) * lerpf(2.4, 1.5, clampf(speed / PUSH_SPEED, 0.0, 1.0)) * dt
		var rotated := Vector2(along_speed, lateral_speed).rotated(turn)
		along_speed = rotated.x
		lateral_speed = rotated.y
		var before_along := along_speed
		var before_lateral := lateral_speed
		var acceleration := _gravity_along(theta)
		var half_along := along_speed + acceleration * dt * 0.5
		var next_theta := theta + half_along * dt / float(feature.radius)
		var next_across := across + lateral_speed * dt
		var fraction := 1.0
		var reason := ""
		if next_theta < 0.0:
			fraction = (0.0 - theta) / (next_theta - theta)
			reason = "toe"
		elif next_theta > float(feature.angle):
			fraction = (float(feature.angle) - theta) / (next_theta - theta)
			reason = "lip"
		var half_width: float = float(feature.width) * 0.5
		if absf(next_across) > half_width:
			var edge := half_width * signf(next_across)
			var side_fraction := (edge - across) / (next_across - across)
			if side_fraction < fraction:
				fraction = side_fraction
				reason = "side"
		fraction = clampf(fraction, 0.0, 1.0)
		var used := dt * fraction
		theta = clampf(lerpf(theta, next_theta, fraction), 0.0, float(feature.angle))
		across = clampf(lerpf(across, next_across, fraction), -half_width, half_width)
		along_speed = before_along + (acceleration + _gravity_along(theta)) * used * 0.5
		lateral_speed = before_lateral
		if push and not brake and along_speed >= 0.0 and speed < PUSH_SPEED:
			var drive := PUSH_ACCELERATION if theta < deg_to_rad(25.0) else PUMP_ACCELERATION
			along_speed = minf(PUSH_SPEED, along_speed + drive * used)
		var current := Vector2(along_speed, lateral_speed)
		var deceleration := BRAKE_DECELERATION if brake else ROLL_DECELERATION
		current = current.move_toward(Vector2.ZERO, deceleration * used).limit_length(MAX_SPEED)
		along_speed = current.x
		lateral_speed = current.y
		_sample()
		remaining -= used
		if not reason.is_empty():
			unused_time = remaining
			return _release(reason)
		if not _confirmed():
			unused_time = remaining
			return _release("unsupported")
	return "riding"


## Call after the real collision move, using the resulting velocity. Obstructions
## can shorten a move or remove momentum; neither is rebuilt from the proposal.
## The caller must handle an unsupported result as ordinary airborne movement.
func reconcile(point: Vector3, velocity: Vector3) -> bool:
	if not active or not _valid_state() or not point.is_finite() or not velocity.is_finite():
		_release("invalid")
		return false
	var contact := _closest(feature, point)
	if contact.is_empty() or _support.call(contact.point, contact.normal, feature.body) != true:
		_release("unsupported")
		return false
	theta = contact.theta
	across = contact.across
	_adopt_velocity(velocity)
	_sample()
	return true


func position() -> Vector3:
	return _position


func normal() -> Vector3:
	return _normal


func travel_velocity() -> Vector3:
	return _velocity


func stop() -> void:
	_release("stopped")
	_support = Callable()


func _adopt_velocity(velocity: Vector3) -> void:
	var transform: Transform3D = feature.transform
	var local_velocity := transform.basis.transposed() * velocity
	var tangent := Vector3(0.0, sin(theta), -cos(theta))
	var projected := Vector2(local_velocity.dot(tangent), local_velocity.x).limit_length(MAX_SPEED)
	along_speed = projected.x
	lateral_speed = projected.y


func _sample() -> void:
	var transform: Transform3D = feature.transform
	var radius: float = feature.radius
	_position = transform * Vector3(across, radius * (1.0 - cos(theta)), -radius * sin(theta))
	_normal = transform.basis * Vector3(0.0, cos(theta), sin(theta))
	_velocity = transform.basis * (Vector3(0.0, sin(theta), -cos(theta)) * along_speed
		+ Vector3.RIGHT * lateral_speed)


func _gravity_along(angle: float) -> float:
	var transform: Transform3D = feature.transform
	return Vector3.DOWN.dot(transform.basis * Vector3(0.0, sin(angle), -cos(angle))) * GRAVITY


func _confirmed() -> bool:
	return _support.is_valid() and _support.call(_position, _normal, feature.body) == true


func _valid_state() -> bool:
	return (_valid_feature(feature) and _support.is_valid() and is_finite(theta)
		and is_finite(across) and is_finite(along_speed) and is_finite(lateral_speed)
		and theta >= 0.0 and theta <= float(feature.angle)
		and absf(across) <= float(feature.width) * 0.5)


func _release(reason: String) -> String:
	active = false
	_result = reason
	return reason


static func _valid_feature(candidate: Dictionary) -> bool:
	if not candidate.has_all(["id", "transform", "radius", "width", "angle", "body"]):
		return false
	if (not candidate.id is String or candidate.id.is_empty()
			or not candidate.transform is Transform3D
			or not (candidate.radius is float or candidate.radius is int)
			or not (candidate.width is float or candidate.width is int)
			or not (candidate.angle is float or candidate.angle is int)
			or not is_instance_valid(candidate.body) or not candidate.body is StaticBody3D):
		return false
	var body: StaticBody3D = candidate.body
	var transform: Transform3D = candidate.transform
	if (not body.is_inside_tree() or body.is_queued_for_deletion() or body.collision_layer == 0
			or str(body.get_meta("transition_id", "")) != candidate.id
			or not transform.is_finite() or not transform.basis.is_equal_approx(transform.basis.orthonormalized())
			or transform.basis.determinant() < 0.99 or transform.basis.y.distance_to(Vector3.UP) > 0.001):
		return false
	return (is_finite(candidate.radius) and float(candidate.radius) >= 0.5
		and is_finite(candidate.width) and float(candidate.width) >= 1.0
		and is_finite(candidate.angle) and float(candidate.angle) >= deg_to_rad(10.0)
		and float(candidate.angle) <= PI * 0.5 + 0.000001)


static func _closest(candidate: Dictionary, point: Vector3) -> Dictionary:
	var transform: Transform3D = candidate.transform
	var local := transform.affine_inverse() * point
	var radius: float = candidate.radius
	var angle: float = candidate.angle
	var half_width: float = float(candidate.width) * 0.5
	if absf(local.x) > half_width:
		return {}
	var at := atan2(-local.z, radius - local.y)
	# Only a few centimetres of seam tolerance, never an infinite support plane.
	if at < -END_ALLOWANCE / radius or at > angle + END_ALLOWANCE / radius:
		return {}
	at = clampf(at, 0.0, angle)
	var contact := Vector3(local.x, radius * (1.0 - cos(at)), -radius * sin(at))
	var normal := Vector3(0.0, cos(at), sin(at))
	var offset := local - contact
	var signed_gap := offset.dot(normal)
	if signed_gap < -PENETRATION_ALLOWANCE or signed_gap > CAPTURE_GAP or offset.length() > CAPTURE_GAP:
		return {}
	return {"theta": at, "across": local.x, "point": transform * contact,
		"normal": transform.basis * normal, "gap": offset.length()}
