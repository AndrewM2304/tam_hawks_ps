extends RefCounted
## Native bounded towing. Caller owns held-Grind/fresh-Interact admission and
## competing trick states. No position snaps, speed injection or score awards.

const MAX_SECONDS := 6.0
const REENTRY_SECONDS := 0.70
const MAX_CATCH_GAP := 1.65
## Catch closer than the .4m admission allowance so the real bar remains inside
## the crouched rider's arm chain; pending attraction never stretches a hand.
const HANDLE_REACH := 0.12
const CATCH_SECONDS := 0.70
var active := false
var caught := false
var speed := 0.0
var balance := 0.0
var elapsed := 0.0
var cooldown := 0.0
var travel_velocity := Vector3.ZERO
var _vehicle: WeakRef
var _pending_seconds := 0.0

func reset() -> void:
	active = false
	caught = false
	speed = 0.0
	balance = 0.0
	elapsed = 0.0
	cooldown = 0.0
	travel_velocity = Vector3.ZERO
	_vehicle = null
	_pending_seconds = 0.0

func stop() -> void:
	if active: cooldown = REENTRY_SECONDS
	active = false
	caught = false
	_vehicle = null
	_pending_seconds = 0.0

func tick(delta: float) -> void:
	if not active and is_finite(delta) and delta > 0.0:
		cooldown = maxf(0.0, cooldown - delta)

func try_start(body: CharacterBody3D, vehicle: Node3D) -> bool:
	if active or cooldown > 0.0 or not _valid(body) or not is_instance_valid(vehicle) \
		or not vehicle.is_in_group("skate_vehicles") or not vehicle.has_method("get_skitch_anchor") \
		or not body.is_on_floor() or bool(vehicle.get("stopped")): return false
	var motion: Vector3 = vehicle.get("travel_velocity")
	if not motion.is_finite() or motion.length() < 2.0 or motion.length() > 8.0: return false
	var anchor: Vector3 = vehicle.get_skitch_anchor()
	var gap := anchor - body.global_position
	if absf(gap.y) > 0.6 or Vector2(gap.x, gap.z).length() > MAX_CATCH_GAP: return false
	var planar := Vector3(body.velocity.x, 0, body.velocity.z)
	if planar.length() < 1.0 or planar.normalized().dot(motion.normalized()) < 0.65: return false
	if (-body.global_basis.z).dot(motion.normalized()) < 0.5: return false
	var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3.UP * 0.9,
		anchor + Vector3.UP * 0.9, 1 | 8, [body.get_rid()])
	if not body.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
	# The anchor belongs to the cart chassis, whose grounded origin can sit a
	# few centimetres below skate contact. Admission sweeps horizontal clearance;
	# the existing support and bounded height checks own the floor relationship.
	if body.test_move(body.global_transform, Vector3(gap.x, 0, gap.z), null, body.safe_margin, false): return false
	active = true
	caught = Vector2(gap.x,gap.z).length() <= HANDLE_REACH
	_vehicle = weakref(vehicle)
	balance = 0.04
	elapsed = 0.0
	_pending_seconds = 0.0
	travel_velocity = motion
	speed = motion.length()
	return true

func step(body: CharacterBody3D, delta: float, steer: float = 0.0, jump: bool = false,
		held: bool = true, jump_impulse: float = 8.8) -> Dictionary:
	if not active: return _result(false, false, "inactive")
	if not _valid(body) or not is_finite(delta) or delta <= 0.0 or not is_finite(steer):
		stop()
		return _result(false, true, "invalid")
	jump_impulse = clampf(jump_impulse, 3.0, 12.0) if is_finite(jump_impulse) else 8.8
	var vehicle: Node3D = _vehicle.get_ref() if _vehicle != null else null
	if not is_instance_valid(vehicle) or bool(vehicle.get("stopped")):
		return _release(body, false, "vehicle_stopped", steer)
	var motion: Vector3 = vehicle.get("travel_velocity")
	if not motion.is_finite() or motion.length() < 0.5:
		return _release(body, false, "vehicle_stopped", steer)
	travel_velocity = motion
	if jump: return _release(body, true, "ollie", steer, jump_impulse)
	if not held: return _release(body, false, "released", steer)
	if caught:
		elapsed += delta
		if elapsed >= MAX_SECONDS: return _release(body, false, "time", steer)
		balance += ((0.16 + elapsed * 0.10) * (1.0 if balance >= 0.0 else -1.0) + clampf(steer, -1.0, 1.0) * 1.35) * delta
		if absf(balance) >= 1.0:
			stop()
			return _result(false, true, "balance")
	else:
		_pending_seconds += delta
		if _pending_seconds >= CATCH_SECONDS: return _release(body,false,"catch_timeout",steer)
	var anchor: Vector3 = vehicle.get_skitch_anchor()
	var gap := anchor - body.global_position
	if not gap.is_finite() or gap.length() > 3.0: return _release(body, false, "lost", steer)
	var pull := motion + Vector3(gap.x, 0, gap.z) * 3.2
	pull = pull.limit_length(11.0)
	body.velocity = pull + Vector3.UP * minf(-0.5, body.velocity.y - 22.0 * delta)
	body.move_and_slide()
	travel_velocity = Vector3(body.velocity.x, 0, body.velocity.z)
	speed = travel_velocity.length()
	for index in body.get_slide_collision_count():
		if body.get_slide_collision(index).get_normal().dot(Vector3.UP) < 0.65:
			stop()
			return _result(false, true, "obstruction")
	if not body.is_on_floor():
		stop()
		return _result(false, false, "edge")
	var remaining: Vector3 = vehicle.get_skitch_anchor()-body.global_position
	if not caught and Vector2(remaining.x,remaining.z).length() <= HANDLE_REACH:
		caught = true
		elapsed = 0.0
	return _result(false, false, "riding" if caught else "catching")

func hand_targets() -> Array[Vector3]:
	var vehicle: Node3D = _vehicle.get_ref() if _vehicle != null else null
	var result: Array[Vector3] = []
	if caught and is_instance_valid(vehicle) and vehicle.has_method("get_skitch_hand_targets"):
		result.assign(vehicle.get_skitch_hand_targets())
	return result

func hand_normal() -> Vector3:
	var vehicle: Node3D = _vehicle.get_ref() if _vehicle != null else null
	return vehicle.get_skitch_surface_normal() if caught and is_instance_valid(vehicle) and vehicle.has_method("get_skitch_surface_normal") else Vector3.ZERO

func _release(body: CharacterBody3D, jump: bool, reason: String, steer: float, jump_impulse: float = 8.8) -> Dictionary:
	stop()
	body.velocity = travel_velocity + Vector3.UP * (jump_impulse if jump else -0.5)
	if jump: body.velocity += body.global_basis.x * clampf(steer, -1.0, 1.0) * 2.0
	body.move_and_slide()
	travel_velocity = body.velocity
	speed = Vector2(body.velocity.x, body.velocity.z).length()
	return _result(jump, false, reason)

func _result(jump: bool, bailed: bool, reason: String) -> Dictionary:
	return {"active": active, "velocity": travel_velocity, "speed": speed,
		"caught": caught, "pending": active and not caught,
		"balance": balance, "launched": jump, "bailed": bailed, "reason": reason}

static func _valid(body: CharacterBody3D) -> bool:
	return is_instance_valid(body) and body.is_inside_tree() and body.global_position.is_finite()
