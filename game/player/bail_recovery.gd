extends RefCounted
## A bounded native slide/fall followed by supported get-up or a safe return.
const DURATION := 1.05
var active := false
var phase := 0.0
var elapsed := 0.0
var ground_point := Vector3.ZERO
var normal := Vector3.UP
var recovery_target := Vector3.INF
var _fallback := Vector3.ZERO
var _void_return := false

func reset() -> void:
	active = false
	phase = 0.0
	elapsed = 0.0
	ground_point = Vector3.ZERO
	normal = Vector3.UP
	recovery_target = Vector3.INF
	_void_return = false

func start(body: CharacterBody3D, fallback: Vector3, target: Vector3 = Vector3.INF, outward: Vector3 = Vector3.ZERO) -> void:
	if active: return
	active = true
	phase = 0.0
	elapsed = 0.0
	_fallback = fallback
	recovery_target = target
	_void_return = target.is_finite() or body.global_position.y < -8.0 or absf(body.global_position.x) > 400.0 or absf(body.global_position.z) > 400.0
	body.up_direction = Vector3.UP
	body.velocity = Vector3(body.velocity.x * 0.3, minf(body.velocity.y, 1.0), body.velocity.z * 0.3)
	if outward.length_squared() > 0.1:
		body.velocity += Vector3(outward.x, 0, outward.z).normalized() * 3.0
	_update_ground(body)

func step(body: CharacterBody3D, delta: float) -> Dictionary:
	if not active: return {"event": "idle"}
	elapsed += delta
	var planar := Vector3(body.velocity.x, 0, body.velocity.z).move_toward(Vector3.ZERO, 7.0 * delta)
	body.velocity = planar + Vector3.UP * maxf(-24.0, body.velocity.y - 22.0 * delta)
	body.move_and_slide()
	_update_ground(body)
	# A fall cannot begin getting up while it is still physically airborne.
	# Void/hazard returns fade independently before the safe-position recovery.
	if body.is_on_floor():
		phase = minf(1.0, phase + delta / DURATION)
	elif phase < 0.45:
		phase = minf(0.45, phase + delta / DURATION)
	_void_return = _void_return or body.global_position.y < -8.0
	if not ((body.is_on_floor() and phase >= 0.999999) or (_void_return and elapsed >= DURATION) or elapsed >= 3.0):
		return {"event": "recovering"}
	var target := recovery_target
	if not target.is_finite():
		target = body.global_position if _can_get_up(body) else _fallback
	phase = 1.0
	active = false
	return {"event": "recovered", "target": target}

func fade() -> float:
	return smoothstep(DURATION - 0.22, DURATION, elapsed) if _void_return else smoothstep(0.78, 1.0, phase)

func _update_ground(body: CharacterBody3D) -> void:
	var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3.UP * 0.3,
		body.global_position - Vector3.UP * 2.8, body.collision_mask)
	query.exclude = [body.get_rid()]
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and Vector3(hit.normal).y > 0.6:
		ground_point = hit.position
		normal = hit.normal
	else:
		ground_point = body.global_position
		normal = Vector3.UP

func _can_get_up(body: CharacterBody3D) -> bool:
	if not body.is_on_floor() or body.global_position.y < -7.0: return false
	var collision := body.get_node_or_null("BodyCollision") as CollisionShape3D
	if collision == null: return false
	# Native floor recovery can retain a sub-millimetre support overlap. An
	# inflated overlap query treated that floor as a blocked get-up and sent a
	# perfectly supported rider back to spawn. Ask the same native capsule for
	# recovery contacts, permitting only its shallow supporting-floor contact.
	# Walls, ceilings and deep penetration still require the safe fallback.
	var contact := KinematicCollision3D.new()
	# The walking recovery envelope is 15 mm, wider than actual stand clearance:
	# a nearby wall within that envelope must not count as an overlap. Retain the
	# original 1 mm clearance query while tolerating shallow native floor contact.
	const CLEARANCE_MARGIN := 0.001
	if not body.test_move(body.global_transform, Vector3.ZERO, contact, CLEARANCE_MARGIN, true, 16): return true
	if contact.get_depth() > body.safe_margin + CLEARANCE_MARGIN: return false
	# At a native valley/seam more than one legitimate floor normal can touch
	# the capsule. Match CharacterBody's floor-angle rule, rather than requiring
	# every supporting facet to be parallel to its one cached floor normal.
	var floor_limit := cos(body.floor_max_angle)
	for index in contact.get_collision_count():
		if contact.get_normal(index).dot(body.up_direction) + 0.000001 < floor_limit: return false
	return true
