extends RefCounted
## Original volume-aware chase camera using Godot's native physics queries.
## The rider's movement and travel heading are never modified here.

const CHEST_HEIGHT := 1.05
const CAMERA_RADIUS := 0.25
const CLEARANCE := 0.045
const MIN_USEFUL_ARM := 3.0
const REAR_RETURN_DELAY := 0.40
const NORMAL_HEIGHT := 2.5
const LOW_HEIGHT := 1.95
const REVERSE_MIN_SPEED := 1.2
const REVERSE_CONFIRM_TIME := 0.28
const FORWARD_CONFIRM_TIME := 0.22
const HEADING_RATE := 6.0
const STEEP_ANGLE := 0.6981317008 # Forty degrees; keeps the body axis readable.
const ORBIT_ANGLES := [0.7853981634, -0.7853981634, 1.5707963268, -1.5707963268, 2.3561944902, -2.3561944902, PI]

var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()
var _ready := false
var _selected_angle := 0.0
var _rear_clear_time := 0.0
var _last_anchor := Vector3.ZERO
var _body_up := Vector3.UP
var _travel_sign := 1.0
var _direction_confirm := 0.0
var _world_rear := Vector3.ZERO
var _heading_confirm := 0.0
var _steep_bias := 0.0
var _steep_side := 1.0
var _steep_active := false


func _init() -> void:
	_sphere.radius = CAMERA_RADIUS
	_query.shape = _sphere
	_query.collision_mask = 1
	_query.collide_with_bodies = true
	_query.collide_with_areas = false
	_query.margin = 0.015


func reset() -> void:
	_ready = false
	_selected_angle = 0.0
	_rear_clear_time = 0.0
	_last_anchor = Vector3.ZERO
	_body_up = Vector3.UP
	_travel_sign = 1.0
	_direction_confirm = 0.0
	_world_rear = Vector3.ZERO
	_heading_confirm = 0.0
	_steep_bias = 0.0
	_steep_side = 1.0
	_steep_active = false


func update(rider: CharacterBody3D, camera: Camera3D, delta: float, sensitivity: float, reduced_motion: bool) -> void:
	if not is_instance_valid(rider) or not is_instance_valid(camera) or not rider.is_inside_tree(): return
	# _process follows the same frame the renderer displays. Reading the newest
	# physics transform here makes an otherwise smoothed camera judder at 60 Hz.
	# Physics callers/tests retain their exact current contact frame.
	var frame := _follow_transform(rider)
	var board := frame.origin
	if not board.is_finite(): return
	# Transitions can lay the skater back against a curved wall. Occlusion rays
	# follow the actual body axis, while the camera's horizon stays world-up.
	_body_up = _contact_up(rider)
	var anchor := board + _body_up * CHEST_HEIGHT
	var space := rider.get_world_3d().direct_space_state
	var excluded: Array[RID] = [rider.get_rid()]
	_query.exclude = excluded
	var step := clampf(delta, 0.0, 0.15) if is_finite(delta) else 0.0
	var response := clampf(sensitivity, 0.5, 2.0) if is_finite(sensitivity) else 1.0
	var speed := clampf(Vector2(rider.velocity.x, rider.velocity.z).length(), 0.0, 15.0)
	var distance := 4.9 if reduced_motion else 4.9 + speed * 0.02
	var rear := Vector3(frame.basis.z.x, 0, frame.basis.z.z).normalized()
	if rear.length_squared() < 0.1: rear = Vector3.BACK
	if _ready and anchor.distance_to(_last_anchor) > 12.0:
		reset()
		_body_up = _contact_up(rider)
	rear = _heading(rider, rear, step)
	# A direct rear view looks down the torso on a steep transition. Establish
	# the clear side early, before that view becomes foreshortened or occluded.
	var incline := acos(clampf(_body_up.y, -1.0, 1.0))
	if bool(rider.get("transition_active")):
		var support: Vector3 = rider.get("transition_normal")
		incline = maxf(incline, acos(clampf(support.y, -1.0, 1.0)))
	var bias_amount := smoothstep(deg_to_rad(10.0), deg_to_rad(40.0), incline) * STEEP_ANGLE
	if bias_amount > 0.0 and not _steep_active:
		var left := _best_height(space, anchor, board, rear, distance, STEEP_ANGLE, excluded)
		var right := _best_height(space, anchor, board, rear, distance, -STEEP_ANGLE, excluded)
		_steep_side = 1.0 if float(left.score) >= float(right.score) - 0.05 else -1.0
		_steep_active = true
	if _steep_active and (bool(rider.get("airborne")) or bool(rider.get("transition_active"))):
		# Keep the established side through an aerial return. The contact axis
		# becomes upright at the apex and tilts again on re-entry.
		bias_amount = maxf(bias_amount, absf(_steep_bias))
	elif is_zero_approx(bias_amount):
		_steep_active = false
	_steep_bias = move_toward(_steep_bias, bias_amount * _steep_side, step * 4.0)
	rear = rear.rotated(Vector3.UP, _steep_bias)
	var selected := _choose(space, anchor, board, rear, distance, excluded, step)
	var desired: Vector3 = selected.position
	var resolved := desired
	if _ready:
		# Interpolate on an orbit, not a chord that passes through the torso.
		var old_offset := camera.global_position - anchor
		var new_offset := desired - anchor
		var old_yaw := atan2(old_offset.x, old_offset.z)
		var new_yaw := atan2(new_offset.x, new_offset.z)
		var blend := 1.0 - exp(-7.0 * response * step)
		var yaw := lerp_angle(old_yaw, new_yaw, blend)
		var radius := lerpf(Vector2(old_offset.x, old_offset.z).length(), Vector2(new_offset.x, new_offset.z).length(), blend)
		var lift := lerpf(old_offset.y, new_offset.y, blend)
		var proposed := anchor + Vector3(sin(yaw) * radius, lift, cos(yaw) * radius)
		resolved = _sweep(space, anchor, proposed)
		# Check the moving camera volume as well as the final arm. This catches
		# corners which a clear endpoint or a single chest ray cannot establish.
		if _clear_volume(space, camera.global_position):
			resolved = _sweep(space, camera.global_position, resolved)
		resolved = _sweep(space, anchor, resolved)
		if not _usable(space, board, anchor, resolved, excluded):
			# A newly blocked arm can already be too short to show the body. Use
			# the independently clear orbit endpoint immediately, rather than
			# easing through first person or through a wall for several frames.
			resolved = desired
		elif not _clear_volume(space, resolved):
			resolved = desired
	# Every chosen endpoint has an anchor sweep and a clear camera volume.
	camera.global_position = resolved
	var actual_arm := anchor.distance_to(resolved)
	var lookahead := clampf((actual_arm - 3.0) / 3.0, 0.0, 1.0) \
		* (0.35 if reduced_motion else 0.35 + speed * 0.055)
	var target := anchor - rear * lookahead
	if resolved.distance_squared_to(target) > 0.01:
		camera.look_at(target, Vector3.UP)
	var desired_fov := 64.0 if reduced_motion else 64.0 + speed * 0.13
	camera.fov = lerpf(camera.fov, desired_fov, 1.0 - exp(-3.0 * step))
	_ready = true
	_last_anchor = anchor


func _contact_up(rider: CharacterBody3D) -> Vector3:
	# The collider is aligned to curved support in physics and upright elsewhere.
	# Its displayed axis also blends across a transition exit, instead of popping
	# when the current physics-state Boolean changes ahead of the rendered body.
	var collision := rider.get_node_or_null("BodyCollision") as Node3D
	if is_instance_valid(collision):
		var value := _follow_transform(collision).basis.y
		if value.is_finite() and value.length_squared() > 0.1:
			return value.normalized()
	return Vector3.UP


func _follow_transform(node: Node3D) -> Transform3D:
	# A reset can happen after this render frame's native interpolation cache was
	# prepared. Use the new transform once, then resume displayed-frame tracking.
	if _ready and not Engine.is_in_physics_frame() and node.is_physics_interpolated_and_enabled():
		return node.get_global_transform_interpolated()
	return node.global_transform


func _direction_sign(velocity: Vector3, facing_rear: Vector3, delta: float) -> float:
	var travel := Vector3(velocity.x, 0.0, velocity.z)
	if not travel.is_finite() or travel.length() < REVERSE_MIN_SPEED:
		# Stopping on a ramp must not trigger alternating front/back views.
		_direction_confirm = 0.0
		return _travel_sign
	var facing_alignment := travel.normalized().dot(-facing_rear)
	var request := -1.0 if facing_alignment < -0.45 else (1.0 if facing_alignment > 0.45 else _travel_sign)
	if request == _travel_sign:
		_direction_confirm = 0.0
	else:
		_direction_confirm += delta
		var delay := REVERSE_CONFIRM_TIME if request < 0.0 else FORWARD_CONFIRM_TIME
		if _direction_confirm >= delay:
			_travel_sign = request
			_direction_confirm = 0.0
	return _travel_sign


func _heading(rider: CharacterBody3D, facing_rear: Vector3, delta: float) -> Vector3:
	var requested := facing_rear * _direction_sign(rider.velocity, facing_rear, delta)
	# Spins and the automatic vert return rotate the body independently of
	# travel. Keep a world-space heading through a near-vertical apex instead.
	if bool(rider.get("transition_active")):
		var support: Vector3 = rider.get("transition_normal")
		if support.y < cos(deg_to_rad(20.0)):
			requested = Vector3(support.x, 0, support.z).normalized()
	elif bool(rider.get("airborne")):
		var travel := Vector3(rider.velocity.x, 0, rider.velocity.z)
		requested = -travel.normalized() if travel.length() >= REVERSE_MIN_SPEED else _world_rear
	if requested.length_squared() < 0.1: requested = facing_rear
	if _world_rear.length_squared() < 0.1:
		_world_rear = requested
		return _world_rear
	if bool(rider.get("airborne")) and _world_rear.dot(requested) < -0.45:
		_heading_confirm += delta
		if _heading_confirm < REVERSE_CONFIRM_TIME: return _world_rear
	else:
		_heading_confirm = 0.0
	var old_yaw := atan2(_world_rear.x, _world_rear.z)
	var target_yaw := atan2(requested.x, requested.z)
	var yaw := rotate_toward(old_yaw, target_yaw, HEADING_RATE * delta)
	_world_rear = Vector3(sin(yaw), 0, cos(yaw))
	return _world_rear


func _choose(space: PhysicsDirectSpaceState3D, anchor: Vector3, board: Vector3, rear: Vector3, distance: float, excluded: Array[RID], delta: float) -> Dictionary:
	var ordinary := _best_height(space, anchor, board, rear, distance, 0.0, excluded)
	var rear_open: bool = ordinary.usable and ordinary.reach >= distance * 0.93
	_rear_clear_time = _rear_clear_time + delta if rear_open else 0.0
	if is_zero_approx(_selected_angle) and rear_open:
		return ordinary
	if not is_zero_approx(_selected_angle):
		var current := _best_height(space, anchor, board, rear, distance, _selected_angle, excluded)
		if rear_open and _rear_clear_time >= REAR_RETURN_DELAY:
			_selected_angle = 0.0
			return ordinary
		if current.usable:
			return current
	# Search only while the current view is obstructed. Retaining a useful
	# chosen side avoids alternating left/right against the same wall.
	var best := ordinary
	for angle: float in ORBIT_ANGLES:
		var candidate := _best_height(space, anchor, board, rear, distance, angle, excluded)
		if float(candidate.score) > float(best.score): best = candidate
	_selected_angle = best.angle
	return best


func _best_height(space: PhysicsDirectSpaceState3D, anchor: Vector3, board: Vector3, rear: Vector3, distance: float, angle: float, excluded: Array[RID]) -> Dictionary:
	var normal := _candidate(space, anchor, board, rear, distance, angle, NORMAL_HEIGHT, excluded)
	# The normal rear/side height is preferred whenever fully available.
	if normal.usable and normal.reach >= distance * 0.98: return normal
	var low := _candidate(space, anchor, board, rear, distance, angle, LOW_HEIGHT, excluded)
	return low if float(low.score) > float(normal.score) else normal


func _candidate(space: PhysicsDirectSpaceState3D, anchor: Vector3, board: Vector3, rear: Vector3, distance: float, angle: float, height: float, excluded: Array[RID]) -> Dictionary:
	var desired := anchor + rear.rotated(Vector3.UP, angle) * distance + Vector3.UP * (height - CHEST_HEIGHT)
	var position := _sweep(space, anchor, desired)
	var reach := Vector2(position.x - anchor.x, position.z - anchor.z).length()
	var usable := _usable(space, board, anchor, position, excluded)
	var score := reach - absf(angle) * 0.22 - absf(height - NORMAL_HEIGHT) * 0.18
	if not usable: score -= 20.0
	return {"position": position, "reach": reach, "angle": angle, "usable": usable, "score": score}


func _sweep(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Vector3:
	var motion := to - from
	var length := motion.length()
	if length < 0.0001: return from
	_query.transform = Transform3D(Basis.IDENTITY, from)
	_query.motion = motion
	var fractions := space.cast_motion(_query)
	if fractions.size() < 2: return from
	var fraction := clampf(fractions[0], 0.0, 1.0)
	if fraction >= 0.9999: return to
	return from + motion.normalized() * maxf(0.0, length * fraction - CLEARANCE)


func _clear_volume(space: PhysicsDirectSpaceState3D, position: Vector3) -> bool:
	_query.transform = Transform3D(Basis.IDENTITY, position)
	_query.motion = Vector3.ZERO
	return space.intersect_shape(_query, 1).is_empty()


func _usable(space: PhysicsDirectSpaceState3D, board: Vector3, anchor: Vector3, position: Vector3, excluded: Array[RID]) -> bool:
	if anchor.distance_to(position) < MIN_USEFUL_ARM or not _clear_volume(space, position): return false
	# Chest alone can be clear while a lip or column hides the board or head.
	for height: float in [0.12, CHEST_HEIGHT, 1.8]:
		var query := PhysicsRayQueryParameters3D.create(position, board + _body_up * height, 1, excluded)
		if not space.intersect_ray(query).is_empty(): return false
	return true
