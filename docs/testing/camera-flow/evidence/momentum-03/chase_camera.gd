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
const HEADING_RATE := 8.0
const MAX_MOTION_PITCH := 1.1344640138 # 65 degrees, avoiding a vertical look-at singularity.
const PITCH_RATE := 4.0
const PITCH_RUN := 0.1
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
var _apex_rear := Vector3.ZERO
var _motion_pitch := 0.0
var _motion_direction := Vector3.FORWARD
var _ground_query := PhysicsRayQueryParameters3D.new()


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
	_apex_rear = Vector3.ZERO
	_motion_pitch = 0.0
	_motion_direction = Vector3.FORWARD


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
	_ground_query.exclude = excluded
	_ground_query.collision_mask = 1
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
	# Follow actual momentum, including ascent/descent. Body spins, flips and
	# the automatic vert-facing turn do not steer the camera. A small horizontal
	# reference makes pitch continuous as nearly vertical travel crosses its apex.
	var travel := rider.velocity
	var pitch := atan2(travel.y, maxf(Vector2(travel.x,travel.z).length(), PITCH_RUN)) if travel.length() > 0.5 else _motion_pitch
	pitch = clampf(pitch, -MAX_MOTION_PITCH, MAX_MOTION_PITCH)
	_motion_pitch = move_toward(_motion_pitch, pitch, PITCH_RATE * step)
	_motion_direction = -rear * cos(_motion_pitch) + Vector3.UP * sin(_motion_pitch)
	var selected := _choose(space, anchor, board, rear, distance, excluded, step)
	var desired: Vector3 = selected.position
	var resolved := desired
	if _ready:
		# Interpolate on an orbit, not a chord that passes through the torso.
		var old_offset := camera.global_position - anchor
		var new_offset := desired - anchor
		var old_yaw := atan2(old_offset.x, old_offset.z)
		var new_yaw := atan2(new_offset.x, new_offset.z)
		var follow_rate := 10.0 if bool(rider.get("transition_active")) or bool(rider.get("airborne")) else 7.0
		var blend := 1.0 - exp(-follow_rate * response * step)
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
			resolved = camera.global_position if _usable(space, board, anchor, camera.global_position, excluded) else desired
		elif not _clear_volume(space, resolved):
			resolved = desired
	# Every chosen endpoint has an anchor sweep and a clear camera volume.
	camera.global_position = resolved
	var actual_arm := anchor.distance_to(resolved)
	var lookahead := clampf((actual_arm - 3.0) / 3.0, 0.0, 1.0) \
		* (0.35 if reduced_motion else 0.35 + speed * 0.055)
	var target := anchor + _motion_direction * lookahead
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
	var vertical_return := false
	if bool(rider.get("transition_active")) or bool(rider.get("airborne")):
		var travel := Vector3(rider.velocity.x, 0, rider.velocity.z)
		var reliable_speed := 0.05 if bool(rider.get("transition_active")) else REVERSE_MIN_SPEED
		if travel.length() >= reliable_speed:
			requested = -travel.normalized()
			if rider.velocity.y > 1.0: _apex_rear = requested
		else:
			requested = _world_rear
			# Pure vertical momentum has no horizontal bearing. On a genuine
			# ramp return, reverse the remembered ascent bearing as descent begins;
			# do not follow the body's earlier automatic turn or a scored spin.
			var returning: Variant = rider.get("_vert_return")
			if returning is Dictionary and not returning.is_empty() and _apex_rear.length_squared() > 0.1:
				requested = -_apex_rear if rider.velocity.y < -0.25 else _apex_rear
				vertical_return = rider.velocity.y < -0.25
	else:
		_apex_rear = Vector3.ZERO
	if requested.length_squared() < 0.1: requested = facing_rear
	if _world_rear.length_squared() < 0.1:
		_world_rear = requested
		return _world_rear
	if bool(rider.get("airborne")) and not vertical_return and _world_rear.dot(requested) < -0.45:
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
	var desired := anchor + rear.rotated(Vector3.UP, angle) * distance 		+ Vector3.UP * (height - CHEST_HEIGHT - sin(_motion_pitch) * distance * 0.75)
	# During a ramp climb the trailing camera wants to move below the rider.
	# Raise it to real support instead of shortening into a first-person arm.
	# This is an actual world ray, not an invisible assumed ground plane.
	if _motion_pitch > 0.01:
		_ground_query.from = Vector3(desired.x, maxf(anchor.y + 2.0, desired.y + 2.0), desired.z)
		_ground_query.to = desired - Vector3.UP * (CAMERA_RADIUS + CLEARANCE)
		var floor_hit := space.intersect_ray(_ground_query)
		if not floor_hit.is_empty() and Vector3(floor_hit.normal).y > 0.45:
			desired.y = maxf(desired.y, Vector3(floor_hit.position).y + CAMERA_RADIUS + CLEARANCE + 0.02)
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
