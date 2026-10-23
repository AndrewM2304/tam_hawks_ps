extends RefCounted
## Original named-contact geometry for this project's original skateboard asset.
## Admission, world clearance, scoring and input freshness belong to the caller.

const LineSource = preload("res://game/tricks/grind_line.gd")
const DirectionalTricks = preload("res://game/tricks/directional_tricks.gd")
const TRUCK_HALF_SPAN: float = 0.255
const TRUCK_UNDERSIDE: float = -0.103
const DECK_UNDERSIDE: float = -0.014
const CONTACT_TOLERANCE: float = 0.0001
const BALANCE_ROLL: float = 0.35
const MAX_SPAN_EXPANSIONS: int = 8
const MAX_SPAN_BISECTIONS: int = 18


## Allocate once per rider. solve_into only changes values in these two fixed arrays.
class ContactPose extends RefCounted:
	var valid: bool = false
	var board_transform: Transform3D = Transform3D.IDENTITY
	var anchors := PackedVector3Array()
	var supports := PackedVector3Array()
	var anchor_count: int = 0
	var max_error: float = INF

	func _init() -> void:
		anchors.resize(2)
		supports.resize(2)


## Snapshot selection: board heading is independent of signed travel.
## Positive yaw turns the nose left of travel. A reversed parallel board stays fakie.
## A final quarter-turn alone cannot establish boardslide/lipslide crossing history.
static func select(direction: Vector2, board_forward: Vector3,
		travel_forward: Vector3) -> Dictionary:
	if (not direction.is_finite() or not board_forward.is_finite()
			or not travel_forward.is_finite()):
		return {}
	var board_flat := Vector3(board_forward.x, 0.0, board_forward.z)
	var travel_flat := Vector3(travel_forward.x, 0.0, travel_forward.z)
	if board_flat.length_squared() < 0.000001 or travel_flat.length_squared() < 0.000001:
		return {}
	if DirectionalTricks._past_threshold(absf(direction.x)):
		return {"id": "boardslide", "yaw": -signf(direction.x) * PI * 0.5}
	var angle: float = travel_flat.signed_angle_to(board_flat, Vector3.UP)
	var magnitude: float = absf(angle)
	if magnitude >= PI * 0.25 and magnitude <= PI * 0.75:
		return {"id": "boardslide", "yaw": signf(angle) * PI * 0.5}
	return {"id": "grind_50_50", "yaw": PI if magnitude > PI * 0.75 else 0.0}


## Reuse result for production ticks: no Dictionaries, arrays or Resources are built.
## The .51m rigid hanger chord must meet actual support points, including at bends.
## A bounded search may decline a tight corner rather than stretching the board.
static func solve_into(result: ContactPose, line: LineSource, distance: float,
		direction: float, yaw: float, style_id: String, balance: float) -> bool:
	if result == null:
		return false
	_clear(result)
	if (line == null or not line.is_valid or not line.contact_verified
			or not is_finite(line.length) or line.length <= 0.001
			or not is_finite(distance) or not is_finite(direction) or absf(direction) != 1.0
			or not is_finite(yaw) or not is_finite(balance) or absf(balance) > 1.0):
		return false
	var bounded: float = fposmod(distance, line.length) if line.is_loop else clampf(distance, 0.0, line.length)
	var normalized_yaw: float = wrapf(yaw, -PI, PI)
	if style_id == "grind_50_50":
		if absf(sin(normalized_yaw)) > 0.00001 or not _truck_contacts(result, line, bounded):
			return false
		var board_sign: float = direction * (1.0 if cos(normalized_yaw) > 0.0 else -1.0)
		# Scratch contacts begin in increasing-distance order; public order is nose/tail.
		if board_sign > 0.0:
			var first: Vector3 = result.supports[0]
			result.supports[0] = result.supports[1]
			result.supports[1] = first
		result.anchors[0] = Vector3(0.0, TRUCK_UNDERSIDE, -TRUCK_HALF_SPAN)
		result.anchors[1] = Vector3(0.0, TRUCK_UNDERSIDE, TRUCK_HALF_SPAN)
		result.anchor_count = 2
		var forward: Vector3 = (result.supports[0] - result.supports[1]).normalized()
		var up: Vector3 = line.contact_up(bounded)
		if not _install_frame(result, forward, up, balance):
			return false
		var midpoint: Vector3 = (result.supports[0] + result.supports[1]) * 0.5
		result.board_transform.origin = midpoint - result.board_transform.basis * Vector3(0.0, TRUCK_UNDERSIDE, 0.0)
	elif style_id == "boardslide":
		if absf(absf(normalized_yaw) - PI * 0.5) > 0.00001:
			return false
		var tangent: Vector3 = line.dir_at(bounded) * direction
		var up: Vector3 = line.contact_up(bounded)
		if not tangent.is_finite() or not up.is_finite() or up.length_squared() < 0.5:
			return false
		var forward: Vector3 = tangent.rotated(up, normalized_yaw)
		if not _install_frame(result, forward, up, balance):
			return false
		result.anchors[0] = Vector3(0.0, DECK_UNDERSIDE, 0.0)
		result.supports[0] = line.contact_at(bounded)
		result.anchor_count = 1
		result.board_transform.origin = result.supports[0] - result.board_transform.basis * result.anchors[0]
	else:
		return false
	if not result.board_transform.is_finite():
		return false
	result.max_error = 0.0
	for index in result.anchor_count:
		var error: float = (result.board_transform * result.anchors[index]).distance_to(result.supports[index])
		if not is_finite(error):
			result.max_error = INF
			return false
		result.max_error = maxf(result.max_error, error)
	result.valid = result.max_error <= CONTACT_TOLERANCE
	return result.valid


## Allocating convenience view for diagnostics; production uses solve_into above.
static func pose(line: LineSource, distance: float, direction: float, yaw: float,
		style_id: String, balance: float) -> Dictionary:
	var result := ContactPose.new()
	solve_into(result, line, distance, direction, yaw, style_id, balance)
	return {"valid": result.valid, "board_transform": result.board_transform,
		"anchors": result.anchors.slice(0, result.anchor_count),
		"supports": result.supports.slice(0, result.anchor_count), "max_error": result.max_error}


static func _clear(result: ContactPose) -> void:
	result.valid = false
	result.anchor_count = 0
	result.max_error = INF
	result.board_transform = Transform3D.IDENTITY
	result.anchors[0] = Vector3.ZERO
	result.anchors[1] = Vector3.ZERO
	result.supports[0] = Vector3.ZERO
	result.supports[1] = Vector3.ZERO


static func _install_frame(result: ContactPose, forward: Vector3, up: Vector3,
		balance: float) -> bool:
	if (not forward.is_finite() or not up.is_finite()
			or forward.length_squared() < 0.5 or up.length_squared() < 0.5):
		return false
	var z: Vector3 = -forward.normalized()
	var y: Vector3 = up.slide(z)
	if y.length_squared() < 0.000001:
		return false
	y = y.normalized()
	var x: Vector3 = y.cross(z).normalized()
	y = z.cross(x).normalized()
	var frame := Basis(x, y, z) * Basis(Vector3.BACK, -balance * BALANCE_ROLL)
	if not frame.is_finite() or absf(frame.determinant() - 1.0) > 0.00001:
		return false
	result.board_transform.basis = frame
	return true


## Straight support normally finishes with the first two samples. Curved support
## expands the arc interval, then bisects its actual world chord, never board scale.
static func _truck_contacts(result: ContactPose, line: LineSource, distance: float) -> bool:
	var target: float = TRUCK_HALF_SPAN * 2.0
	if line.length < target - CONTACT_TOLERANCE:
		return false
	var limit: float = minf(line.length * 0.5, target * 2.0)
	var lower: float = 0.0
	var upper: float = minf(TRUCK_HALF_SPAN, limit)
	var span: float = _sample_span(result, line, distance, upper)
	if not is_finite(span):
		return false
	if absf(span - target) <= CONTACT_TOLERANCE:
		return true
	if span < target:
		lower = upper
		for _iteration in MAX_SPAN_EXPANSIONS:
			upper = minf(upper * 1.35, limit)
			span = _sample_span(result, line, distance, upper)
			if not is_finite(span):
				return false
			if span >= target:
				break
			if upper >= limit:
				return false
			lower = upper
		if span < target:
			return false
	for _iteration in MAX_SPAN_BISECTIONS:
		var middle: float = (lower + upper) * 0.5
		span = _sample_span(result, line, distance, middle)
		if not is_finite(span):
			return false
		if absf(span - target) <= CONTACT_TOLERANCE:
			return true
		if span > target:
			upper = middle
		else:
			lower = middle
	return absf(span - target) <= CONTACT_TOLERANCE


static func _sample_span(result: ContactPose, line: LineSource, distance: float,
		half_span: float) -> float:
	var center: float = distance if line.is_loop else clampf(distance, half_span, line.length - half_span)
	var low: float = center - half_span
	var high: float = center + half_span
	if line.is_loop:
		low = fposmod(low, line.length)
		high = fposmod(high, line.length)
	result.supports[0] = line.contact_at(low)
	result.supports[1] = line.contact_at(high)
	if not result.supports[0].is_finite() or not result.supports[1].is_finite():
		return INF
	return result.supports[0].distance_to(result.supports[1])
