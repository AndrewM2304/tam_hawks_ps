extends RefCounted
## Supported preparation for a real planted-foot setup before native takeoff.
var active := false
var id := ""
var phase := 0.0
var ground_point := Vector3.ZERO
var normal := Vector3.UP
var duration := 0.22
var elapsed := 0.0
var _travel := Vector3.ZERO
var _anchor_body: WeakRef
var _anchor_local := Vector3.ZERO

func reset() -> void:
	active = false
	id = ""
	phase = 0.0
	elapsed = 0.0
	ground_point = Vector3.ZERO
	normal = Vector3.UP
	_travel = Vector3.ZERO
	_anchor_body = null

func try_start(body: CharacterBody3D, trick_id: String, foot_offset: Vector3) -> bool:
	if active or trick_id not in ["boneless", "no_comply"] or not body.is_on_floor():
		return false
	var foot := body.global_transform * foot_offset
	var hit := _ray(body, foot + Vector3.UP * 0.45, foot - Vector3.UP * 0.35)
	if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP) < 0.65 \
		or absf(Vector3(hit.position).y - body.global_position.y) > 0.22:
		return false
	id = trick_id
	duration = 0.22 if id == "boneless" else 0.16
	elapsed = 0.0
	phase = 0.0
	ground_point = hit.position
	normal = hit.normal
	_anchor_body = weakref(hit.collider)
	_anchor_local = (hit.collider as Node3D).to_local(ground_point)
	_travel = body.velocity.slide(normal).limit_length(1.65)
	active = true
	return true

func step(body: CharacterBody3D, delta: float) -> Dictionary:
	if not active: return {"event": "idle"}
	var retained: Object = _anchor_body.get_ref() if _anchor_body != null else null
	if is_instance_valid(retained) and retained is Node3D: ground_point = retained.to_global(_anchor_local)
	var hit := _ray(body, ground_point + normal * 0.12, ground_point - normal * 0.16)
	if hit.is_empty() or not is_instance_valid(retained) or hit.collider != retained \
		or Vector3(hit.normal).dot(normal) < 0.95 or not body.is_on_floor():
		active = false
		return {"event": "unsupported", "moved": false}
	elapsed += delta
	phase = clampf(elapsed / duration, 0.0, 1.0)
	if elapsed + 0.000001 >= duration:
		active = false
		body.velocity = _travel
		return {"event": "launch", "id": id, "moved": false}
	# One native movement per preparation frame. The foot's real ground anchor
	# persists while the slow body motion stays within an articulated leg reach.
	_travel = _travel.move_toward(Vector3.ZERO, 2.0 * delta)
	body.velocity = _travel - normal * 0.15
	body.move_and_slide()
	if not body.is_on_floor():
		active = false
		return {"event": "unsupported", "moved": true}
	return {"event": "preparing", "moved": true}

func _ray(body: CharacterBody3D, start: Vector3, end: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, end, body.collision_mask)
	query.exclude = [body.get_rid()]
	return body.get_world_3d().direct_space_state.intersect_ray(query)
