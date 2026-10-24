extends RefCounted
## Original volume-aware chase camera using Godot's native physics queries.
## The rider's movement and travel heading are never modified here.

const CHEST_HEIGHT := 1.05
const CAMERA_RADIUS := 0.25
const CLEARANCE := 0.045
const MIN_USEFUL_ARM := 3.0
const REAR_RETURN_DELAY := 0.40
const NORMAL_HEIGHT := 3.4
const LOW_HEIGHT := 2.4
const ORBIT_ANGLES := [0.7853981634, -0.7853981634, 1.5707963268, -1.5707963268, 2.3561944902, -2.3561944902, PI]

var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()
var _ready := false
var _selected_angle := 0.0
var _rear_clear_time := 0.0
var _last_anchor := Vector3.ZERO
var _travel_rear := Vector3.BACK
var _has_travel_heading := false
var _support_up := Vector3.UP


func _init() -> void:
	_sphere.radius = CAMERA_RADIUS
	_query.shape = _sphere
	_query.collision_mask = 1 | 8
	_query.collide_with_bodies = true
	_query.collide_with_areas = false
	_query.margin = 0.015


func reset() -> void:
	_ready = false
	_selected_angle = 0.0
	_rear_clear_time = 0.0
	_last_anchor = Vector3.ZERO
	_travel_rear = Vector3.BACK
	_has_travel_heading = false
	_support_up = Vector3.UP


func update(rider: CharacterBody3D, camera: Camera3D, delta: float, sensitivity: float, reduced_motion: bool) -> void:
	if not is_instance_valid(rider) or not is_instance_valid(camera) or not rider.is_inside_tree(): return
	var board := rider.global_position
	if not board.is_finite(): return
	var support_up := Vector3.UP
	if rider.has_method("get_support_normal"):
		var supplied: Variant = rider.call("get_support_normal")
		if supplied is Vector3 and supplied.is_finite() and supplied.length_squared() > 0.01:
			support_up = supplied.normalized()
	var anchor := board + support_up * CHEST_HEIGHT
	var space := rider.get_world_3d().direct_space_state
	var excluded: Array[RID] = [rider.get_rid()]
	_query.exclude = excluded
	var step := clampf(delta, 0.0, 0.15) if is_finite(delta) else 0.0
	var response := clampf(sensitivity, 0.5, 2.0) if is_finite(sensitivity) else 1.0
	# Curved/rail movement does not refresh CharacterBody's floor/platform cache.
	# After leaving a cart that cache can point opposite to a true rollback.
	var native_platform := rider.is_on_floor() and rider.get_platform_velocity().length_squared() > 0.01 \
		and bool(rider.get("_native_floor_valid")) \
		and not bool(rider.get("transition_active")) and not bool(rider.get("grinding"))
	var motion := rider.get_real_velocity() if native_platform else rider.velocity
	var planar := Vector3(motion.x, 0.0, motion.z)
	if not planar.is_finite(): planar = Vector3.ZERO
	var speed := clampf(planar.length(), 0.0, 15.0)
	var distance := 6.0 if reduced_motion else 6.0 + speed * 0.04
	if _ready and anchor.distance_to(_last_anchor) > 12.0: reset()
	_support_up = support_up
	# A landed 180/revert can reverse board facing while preserving momentum.
	# Follow the actual line of travel, and retain it through a vert apex where
	# horizontal velocity approaches zero instead of orbiting with a board spin.
	if speed >= 0.8:
		_travel_rear = -planar.normalized()
		_has_travel_heading = true
	elif not _has_travel_heading:
		_travel_rear = Vector3(rider.global_basis.z.x, 0, rider.global_basis.z.z).normalized()
		if _travel_rear.length_squared() < 0.1: _travel_rear = Vector3.BACK
	var rear := _travel_rear
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
	var lookahead := clampf((actual_arm - 3.0) * 0.3, 0.0, 1.2)
	var target := anchor - rear * lookahead
	if resolved.distance_squared_to(target) > 0.01:
		camera.look_at(target, Vector3.UP)
	var desired_fov := 68.0 if reduced_motion else 68.0 + speed * 0.35
	camera.fov = lerpf(camera.fov, desired_fov, 1.0 - exp(-3.0 * step))
	_ready = true
	_last_anchor = anchor


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
	var endpoint := to if fraction >= 0.9999 else from + motion.normalized() * maxf(0.0, length * fraction - CLEARANCE)
	# A native sweep can leave a small endpoint overlap at a shallow ceiling
	# angle. Verify the actual sphere with the same margin; retract to a tested
	# clear point instead of selecting that invalid endpoint again as fallback.
	if _clear_volume(space, endpoint) or not _clear_volume(space, from): return endpoint
	var clear_fraction := 0.0
	var blocked_fraction := 1.0
	for iteration in 12:
		var middle := (clear_fraction + blocked_fraction) * 0.5
		if _clear_volume(space, from.lerp(endpoint, middle)):
			clear_fraction = middle
		else:
			blocked_fraction = middle
	return from.lerp(endpoint, clear_fraction)


func _clear_volume(space: PhysicsDirectSpaceState3D, position: Vector3) -> bool:
	_query.transform = Transform3D(Basis.IDENTITY, position)
	_query.motion = Vector3.ZERO
	return space.intersect_shape(_query, 1).is_empty()


func _usable(space: PhysicsDirectSpaceState3D, board: Vector3, anchor: Vector3, position: Vector3, excluded: Array[RID]) -> bool:
	if anchor.distance_to(position) < MIN_USEFUL_ARM or not _clear_volume(space, position): return false
	# Chest alone can be clear while a lip or column hides the board or head.
	for height: float in [0.12, CHEST_HEIGHT, 1.8]:
		var query := PhysicsRayQueryParameters3D.create(position, board + _support_up * height, 1 | 8, excluded)
		if not space.intersect_ray(query).is_empty(): return false
	return true
