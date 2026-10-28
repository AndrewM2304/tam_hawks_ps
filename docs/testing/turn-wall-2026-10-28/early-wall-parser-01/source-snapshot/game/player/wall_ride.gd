extends RefCounted
## Original bounded wall support using native Godot ray/capsule collision queries.
## No position assignments, invisible wall planes or collider rotation. Admission
## is structural here; the player owns held input, competing states and awards.

const MIN_SPEED := 3.0
const MAX_SPEED := 18.0
const MAX_SECONDS := 1.25
const REENTRY_SECONDS := 0.35
const PROBE_DISTANCE := 0.72
const ENTRY_SWEEP := 0.46
const ADHESION_SPEED := 2.4
const GRAVITY := 22.0
const WALL_GRAVITY_SCALE := 0.32
const FRICTION := 1.2
const WALLIE_OUTWARD_SPEED := 4.8
const WALLIE_UP_SPEED := 8.0
const PRESENTATION_ROLL := 0.65
const PRESENTATION_RESPONSE := 14.0
const PRESENTATION_MAX_RATE := 4.5
const PRESENTATION_MAX_TRANSLATION_SPEED := 4.5

var active := false
var normal := Vector3.ZERO
var elapsed := 0.0
var cooldown := 0.0
var wall_id := ""
var contact_point := Vector3.ZERO
var travel_velocity := Vector3.ZERO
var _wall: WeakRef


func reset() -> void:
	active = false
	normal = Vector3.ZERO
	elapsed = 0.0
	cooldown = 0.0
	wall_id = ""
	contact_point = Vector3.ZERO
	travel_velocity = Vector3.ZERO
	_wall = null


func tick(delta: float) -> void:
	if not active and is_finite(delta) and delta > 0.0:
		cooldown = maxf(0.0, cooldown - delta)


func stop() -> void:
	if active:
		cooldown = REENTRY_SECONDS
	active = false
	_wall = null


func try_start(body: CharacterBody3D, motion: Vector3) -> bool:
	if active or cooldown > 0.0 or not _valid_body(body) or body.is_on_floor() or not motion.is_finite():
		return false
	var planar := Vector3(motion.x, 0.0, motion.z)
	if planar.length() < MIN_SPEED:
		return false
	var side := planar.normalized().cross(Vector3.UP)
	var best: Dictionary = {}
	for direction: Vector3 in [side, -side]:
		var contact := _probe(body, body.global_position, direction)
		if contact.is_empty():
			continue
		var surface_normal: Vector3 = contact.normal
		var closing := planar.dot(surface_normal)
		var tangent := planar.slide(surface_normal)
		# A glancing approach carries useful tangent speed. A head-on impact or
		# rider already travelling away must keep its ordinary collision response.
		if tangent.length() < MIN_SPEED or closing > 0.35 \
				or absf(closing) / planar.length() > 0.80:
			continue
		var sweep := KinematicCollision3D.new()
		if not body.test_move(body.global_transform, -surface_normal * ENTRY_SWEEP, sweep, body.safe_margin, true):
			continue
		if sweep.get_collider() != contact.collider:
			continue
		if best.is_empty() or contact.distance < best.distance:
			best = contact
	if best.is_empty():
		return false
	active = true
	normal = best.normal
	contact_point = best.position
	elapsed = 0.0
	_wall = weakref(best.collider)
	wall_id = str(best.collider.get_path())
	var tangent := planar.slide(normal).limit_length(MAX_SPEED)
	travel_velocity = tangent + Vector3.UP * motion.y
	return true


## This owns exactly one native move_and_slide for a valid physics step,
## including release/jump steps. The caller must not integrate it again.
func step(body: CharacterBody3D, delta: float, steer: float = 0.0,
		jump: bool = false, held: bool = true) -> Dictionary:
	if not active:
		return _result(false, false, "inactive")
	if not _valid_body(body) or not is_finite(delta) or delta <= 0.0 \
			or not is_finite(steer) or not travel_velocity.is_finite():
		stop()
		return _result(false, true, "invalid")
	var contacted := _probe(body, body.global_position, -normal)
	var retained: Variant = _wall.get_ref() if _wall != null else null
	if contacted.is_empty() or not is_instance_valid(retained) \
			or contacted.collider != retained or normal.dot(contacted.normal) < 0.96:
		return _release_move(body, travel_velocity + normal * 0.8, false, "edge")
	contact_point = contacted.position
	if jump:
		var launch := Vector3(travel_velocity.x, 0.0, travel_velocity.z)
		launch += normal * WALLIE_OUTWARD_SPEED + Vector3.UP * WALLIE_UP_SPEED
		return _release_move(body, launch, true, "wallie")
	if not held:
		return _release_move(body, travel_velocity + normal * 0.8, false, "released")
	var away := normal.dot(body.global_basis.x) * clampf(steer, -1.0, 1.0)
	if away > 0.75:
		return _release_move(body, travel_velocity + normal * 1.6, false, "steer_away")
	elapsed += delta
	if elapsed >= MAX_SECONDS:
		return _release_move(body, travel_velocity + normal * 0.8, false, "time")
	var along := Vector3(travel_velocity.x, 0.0, travel_velocity.z).slide(normal)
	var speed := move_toward(along.length(), 0.0, FRICTION * delta)
	if speed < MIN_SPEED * 0.65:
		return _release_move(body, travel_velocity + normal * 0.8, false, "slow")
	var vertical := travel_velocity.y - GRAVITY * WALL_GRAVITY_SCALE * delta
	travel_velocity = along.normalized() * speed + Vector3.UP * vertical
	body.velocity = travel_velocity - normal * ADHESION_SPEED
	body.move_and_slide()
	# Never restore tangent speed or vertical momentum removed by actual impact.
	# The inward support component is the only discarded part of the request.
	var actual := body.velocity.slide(normal)
	travel_velocity = Vector3(actual.x, actual.y, actual.z)
	if body.is_on_floor():
		stop()
		return _result(false, false, "floor")
	for index in body.get_slide_collision_count():
		var collision := body.get_slide_collision(index)
		if collision.get_collider() != retained and absf(collision.get_normal().dot(normal)) < 0.90:
			stop()
			return _result(false, true, "obstruction")
	return _result(false, false, "riding")


func _release_move(body: CharacterBody3D, motion: Vector3, launched: bool, reason: String) -> Dictionary:
	stop()
	travel_velocity = motion
	body.velocity = motion
	body.move_and_slide()
	travel_velocity = body.velocity
	return _result(launched, false, reason)


func _result(launched: bool, bailed: bool, reason: String) -> Dictionary:
	return {"active": active, "velocity": travel_velocity, "normal": normal,
		"launched": launched, "bailed": bailed, "reason": reason, "wall_id": wall_id}


## Original pose easing; the real retained wall and native wheel fit still own
## support. Blend the incoming pre-trick frame instead of snapping the connected
## rider and board through the complete wall lean on the first contact frame.
func presentation_basis(previous: Basis, body_basis: Basis, delta: float) -> Basis:
	if not active or not previous.is_finite() or not body_basis.is_finite() \
			or not is_finite(delta) or delta <= 0.0:
		return previous
	var local_normal := body_basis.inverse() * normal
	var roll := clampf(-local_normal.x * PRESENTATION_ROLL, -PRESENTATION_ROLL, PRESENTATION_ROLL)
	var target := Basis(Vector3.BACK, roll)
	var current := previous.orthonormalized()
	var angle := current.get_rotation_quaternion().angle_to(target.get_rotation_quaternion())
	var blend := minf(1.0 - exp(-PRESENTATION_RESPONSE * delta),
		PRESENTATION_MAX_RATE * delta / maxf(angle, 0.000001))
	return current.slerp(target, blend).orthonormalized()


## Positive wheel-plane gaps may close over a few real frames inside the
## existing acquisition reach. The caller independently corrects penetration
## against its freshly measured tyre vertices after this bounded approach.
func presentation_offset(previous: Vector3, target: Vector3, delta: float) -> Vector3:
	if not active or not previous.is_finite() or not target.is_finite() \
			or not is_finite(delta) or delta <= 0.0:
		return previous
	return previous.move_toward(target, PRESENTATION_MAX_TRANSLATION_SPEED * delta)


func _probe(body: CharacterBody3D, at: Vector3, direction: Vector3) -> Dictionary:
	var contacts: Array[Dictionary] = []
	for height: float in [0.55, 1.35]:
		var start := at + Vector3.UP * height
		var query := PhysicsRayQueryParameters3D.create(start, start + direction * PROBE_DISTANCE,
			body.collision_mask, [body.get_rid()])
		query.hit_from_inside = false
		var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or not is_surface_eligible(hit.collider):
			return {}
		var wall_normal: Vector3 = hit.normal
		if not wall_normal.is_finite() or absf(wall_normal.y) > 0.18:
			return {}
		hit["normal"] = Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()
		hit["distance"] = start.distance_to(hit.position)
		contacts.append(hit)
	if contacts[0].collider != contacts[1].collider \
			or contacts[0].normal.dot(contacts[1].normal) < 0.98:
		return {}
	return contacts[0]


static func _valid_body(body: CharacterBody3D) -> bool:
	return is_instance_valid(body) and body.is_inside_tree() and body.global_position.is_finite()


static func is_surface_eligible(collider: Object) -> bool:
	if not is_instance_valid(collider) or not collider is StaticBody3D:
		return false
	var node: Node = collider
	var explicit_allow := false
	for depth in 8:
		if node == null:
			break
		if bool(node.get_meta("no_wallride", false)):
			return false
		if node.has_meta("wallrideable"):
			if not bool(node.get_meta("wallrideable")):
				return false
			explicit_allow = true
		var surface := str(node.get_meta("surface_audio", "")).to_lower()
		if surface in ["water", "fabric"]:
			return false
		node = node.get_parent()
	if explicit_allow:
		return true
	var name := String((collider as Node).name).to_lower()
	for excluded: String in ["water", "curtain", "canvas", "fabric", "fence", "railing",
		"tree", "foliage", "bench", "bin", "cone", "sign", "lamp", "canopy", "boundary", "transition"]:
		if excluded in name:
			return false
	for raw: Node in (collider as Node).get_children():
		if raw is CollisionShape3D and not raw.disabled and raw.shape != null:
			var size := _shape_world_size(raw)
			if size.y >= 1.6 and maxf(size.x, size.z) >= 2.0:
				return true
	return false


static func _shape_world_size(collision: CollisionShape3D) -> Vector3:
	var size: Vector3
	if collision.shape is BoxShape3D:
		size = (collision.shape as BoxShape3D).size
	else:
		size = collision.shape.get_debug_mesh().get_aabb().size
	var world_basis := collision.basis
	if collision.is_inside_tree():
		world_basis = collision.global_basis
	else:
		# Audits also inspect detached scene fixtures. Compose their ancestors
		# directly instead of asking Godot for an unavailable global transform.
		var ancestor := collision.get_parent()
		while ancestor is Node3D:
			world_basis = (ancestor as Node3D).basis * world_basis
			if (ancestor as Node3D).is_set_as_top_level():
				break
			ancestor = ancestor.get_parent()
	return world_basis.x.abs() * size.x + world_basis.y.abs() * size.y + world_basis.z.abs() * size.z
