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
const MAX_MOTION_PITCH := 1.1344640138 # Generic flight only; ramp frame can point exactly vertical.
const PITCH_RATE := 6.0
const PITCH_RUN := 0.1
const APEX_ORBIT_SECONDS := 0.36
const AIR_RAMP_ARM := 3.6
const ROLL_RATE := 6.0
const MAX_CAMERA_SPEED := 48.0
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
var _horizontal_scale := 1.0
var _motion_direction := Vector3.FORWARD
var _orbit_up := Vector3.UP
var _ramp_mode := false
var _ramp_lift := 1.0
var _ramp_turn := 0.0
var _minimum_arm := MIN_USEFUL_ARM
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
	_horizontal_scale = 1.0
	_motion_direction = Vector3.FORWARD
	_orbit_up = Vector3.UP
	_ramp_mode = false
	_ramp_lift = 1.0
	_ramp_turn = 0.0
	_minimum_arm = MIN_USEFUL_ARM


func update(rider: CharacterBody3D, camera: Camera3D, delta: float, sensitivity: float, reduced_motion: bool) -> void:
	if not is_instance_valid(rider) or not is_instance_valid(camera) or not rider.is_inside_tree(): return
	# _process follows the same frame the renderer displays. Reading the newest
	# physics transform here makes an otherwise smoothed camera judder at 60 Hz.
	# Physics callers/tests retain their exact current contact frame.
	var frame := _follow_transform(rider)
	var board := frame.origin
	if not board.is_finite(): return
	# Transitions can lay the skater back against a curved wall. Occlusion rays
	# follow the actual body axis; ramps retain the skater's local up axis.
	_body_up = _contact_up(rider)
	var anchor := board + _body_up * CHEST_HEIGHT
	var space := rider.get_world_3d().direct_space_state
	var excluded: Array[RID] = [rider.get_rid()]
	_query.exclude = excluded
	_ground_query.exclude = excluded
	_ground_query.collision_mask = 1
	# Bound a delayed render update to one simulation step so a scheduling
	# stall cannot spend its entire elapsed time on an apex camera turn.
	var step := clampf(delta, 0.0, 1.0 / 60.0) if is_finite(delta) else 0.0
	var response := clampf(sensitivity, 0.5, 2.0) if is_finite(sensitivity) else 1.0
	var speed := clampf(Vector2(rider.velocity.x, rider.velocity.z).length(), 0.0, 15.0)
	var distance := 4.9 if reduced_motion else 4.9 + speed * 0.02
	var rear := Vector3(frame.basis.z.x, 0, frame.basis.z.z).normalized()
	if rear.length_squared() < 0.1: rear = Vector3.BACK
	if _ready and anchor.distance_to(_last_anchor) > 12.0:
		reset()
		_body_up = _contact_up(rider)
	var ramp_mode := bool(rider.get("transition_active")) or (bool(rider.get("airborne")) and bool(rider.get("_ramp_air")))
	if _ramp_mode and not ramp_mode:
		# Continue behind the completed return; do not restart a second world
		# heading/pitch turn from stale pre-ramp camera state.
		var horizontal := Vector3(rider.velocity.x,0,rider.velocity.z)
		_world_rear = -horizontal.normalized() if horizontal.length()>.1 else rear
		_motion_pitch = atan2(rider.velocity.y,maxf(horizontal.length(),PITCH_RUN))
	if ramp_mode != _ramp_mode:
		_selected_angle = 0.0
		_rear_clear_time = 0.0
	_ramp_mode = ramp_mode
	_minimum_arm = 1.6 if _ramp_mode else MIN_USEFUL_ARM
	_orbit_up = _body_up if _ramp_mode else Vector3.UP
	if _ramp_mode:
		if bool(rider.get("transition_active")):
			var support: Basis = rider.get_camera_support_frame()
			_motion_direction = -support.z
			_ramp_lift = clampf(_orbit_up.dot(Vector3.UP),0.0,1.0)
			_ramp_turn = 0.0
			distance = lerpf(AIR_RAMP_ARM,distance,_ramp_lift)
		else:
			# One half-circle in the skater's ramp plane, with one fixed side.
			# The local up axis is the ramp normal, never world-up or trick yaw.
			var time_to_apex: float = rider.velocity.y / rider.RAMP_AIR_GRAVITY
			var progress := clampf(1.0-(time_to_apex-1.0/14.0)/APEX_ORBIT_SECONDS,0.0,1.0)
			_ramp_turn = maxf(_ramp_turn,PI*smoothstep(0.0,1.0,progress))
			_motion_direction = rider._ramp_launch_forward.rotated(_orbit_up,_ramp_turn).normalized()
			_ramp_lift = 0.0
			distance = AIR_RAMP_ARM
		rear = -_motion_direction
		_horizontal_scale = 1.0
		_motion_pitch = asin(clampf(_motion_direction.y,-1.0,1.0))
	else:
		rear = _heading(rider,rear,step)
		var travel := rider.velocity
		# A stopped landing must release its last falling pitch, especially
		# under a low ceiling; only airborne near-zero momentum keeps it.
		var idle_pitch := _motion_pitch if bool(rider.get("airborne")) else 0.0
		var pitch := atan2(travel.y,maxf(Vector2(travel.x,travel.z).length(),PITCH_RUN)) if travel.length()>.5 else idle_pitch
		_motion_pitch = move_toward(_motion_pitch,clampf(pitch,-MAX_MOTION_PITCH,MAX_MOTION_PITCH),PITCH_RATE*step)
		_horizontal_scale = maxf(.6 if _motion_pitch>0.0 else 0.0,cos(_motion_pitch))
		_motion_direction = -rear*cos(_motion_pitch)+Vector3.UP*sin(_motion_pitch)
	var selected := _choose(space, anchor, board, rear, distance, excluded, step)
	var desired: Vector3 = selected.position
	var resolved := desired
	if _ready:
		# Interpolate on an orbit, not a chord that passes through the torso.
		var old_offset := camera.global_position - anchor
		var new_offset := desired - anchor
		var follow_rate := 14.0 if _ramp_mode or bool(rider.get("airborne")) else 7.0
		var blend := 1.0-exp(-follow_rate*response*step)
		var direction := old_offset.normalized().slerp(new_offset.normalized(),blend)
		var radius := lerpf(old_offset.length(),new_offset.length(),blend)
		var proposed := anchor+direction*radius
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
			resolved = _advance_clear(space, board, anchor, camera.global_position, desired, excluded, MAX_CAMERA_SPEED * step)
		elif not _clear_volume(space, resolved):
			resolved = desired
	if _ready and camera.global_position.distance_to(resolved) > MAX_CAMERA_SPEED * step:
		resolved = _advance_clear(space, board, anchor, camera.global_position, resolved, excluded, MAX_CAMERA_SPEED * step)
	# Every chosen endpoint has a clear camera volume and body landmarks.
	camera.global_position = resolved
	var actual_arm := anchor.distance_to(resolved)
	var lookahead := clampf((actual_arm - 3.0) / 3.0, 0.0, 1.0) \
		* (0.35 if reduced_motion else 0.35 + speed * 0.055)
	var target := anchor + _motion_direction * lookahead
	if resolved.distance_squared_to(target) > 0.01:
		var forward := (target-resolved).normalized()
		var desired_up := _orbit_up.slide(forward)
		var transported := camera.global_basis.y.slide(forward)
		if transported.length_squared()<.01:
			transported=(Vector3.UP if absf(forward.y)<.9 else Vector3.FORWARD).slide(forward)
		transported=transported.normalized()
		var up := transported
		# Near collinearity has no defined roll. Transport the existing frame
		# instead of letting look_at choose the opposite side of a singularity.
		if desired_up.length_squared()>.1:
			desired_up=desired_up.normalized()
			var roll := transported.signed_angle_to(desired_up,forward)
			up=transported.rotated(forward,clampf(roll,-ROLL_RATE*step,ROLL_RATE*step)) if _ready else desired_up
		camera.global_basis=Basis.looking_at(forward,up)
	var desired_fov := 64.0 if reduced_motion else 64.0 + speed * 0.13
	camera.fov = lerpf(camera.fov, desired_fov, 1.0 - exp(-3.0 * step))
	_ready = true
	_last_anchor = anchor


func _advance_clear(space: PhysicsDirectSpaceState3D, board: Vector3, anchor: Vector3, previous: Vector3, desired: Vector3, excluded: Array[RID], max_move: float) -> Vector3:
	# The swept arm can shorten before a landmark ray is blocked. Holding the
	# old camera until that last ray fails causes a large endpoint jump. Advance
	# through the nearest clear part of the existing fallback path instead.
	# Every admitted point retains actual camera-volume, travel-sweep and all
	# three body-landmark checks; an abstract arm is not the moving camera.
	if _clear_volume(space, previous):
		var limited := previous.move_toward(desired, max_move)
		for index in range(8,0,-1):
			var candidate := _sweep(space, previous, previous.lerp(limited, float(index)/8.0))
			if _usable(space, board, anchor, candidate, excluded): return candidate
		if _usable(space, board, anchor, previous, excluded): return previous
	return desired


func _contact_up(rider: CharacterBody3D) -> Vector3:
	# The collider is aligned to curved support in physics and upright elsewhere.
	# Its displayed axis also blends across a transition exit, instead of popping
	# when the current physics-state Boolean changes ahead of the rendered body.
	if bool(rider.get("transition_active")) or (bool(rider.get("airborne")) and bool(rider.get("_ramp_air"))):
		return rider.get_camera_support_up()
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
	var requested := facing_rear * _direction_sign(rider.velocity,facing_rear,delta)
	if bool(rider.get("airborne")):
		var travel := Vector3(rider.velocity.x,0,rider.velocity.z)
		requested = -travel.normalized() if travel.length()>=REVERSE_MIN_SPEED else _world_rear
	if requested.length_squared()<.1:requested=facing_rear
	if _world_rear.length_squared()<.1:_world_rear=requested
	var yaw := rotate_toward(atan2(_world_rear.x,_world_rear.z),atan2(requested.x,requested.z),HEADING_RATE*delta)
	_world_rear=Vector3(sin(yaw),0,cos(yaw))
	return _world_rear


func _choose(space: PhysicsDirectSpaceState3D, anchor: Vector3, board: Vector3, rear: Vector3, distance: float, excluded: Array[RID], delta: float) -> Dictionary:
	var ordinary := _best_height(space, anchor, board, rear, distance, 0.0, excluded)
	var rear_open: bool = ordinary.usable and (_ramp_mode or ordinary.reach >= distance * _horizontal_scale * 0.93)
	_rear_clear_time = _rear_clear_time + delta if rear_open else 0.0
	if is_zero_approx(_selected_angle) and rear_open:
		return ordinary
	if not is_zero_approx(_selected_angle):
		var current := _best_height(space, anchor, board, rear, distance, _selected_angle, excluded)
		if rear_open and (_ramp_mode or _rear_clear_time >= REAR_RETURN_DELAY):
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
	if normal.usable and (_ramp_mode or normal.reach >= distance * _horizontal_scale * 0.98): return normal
	var low := _candidate(space, anchor, board, rear, distance, angle, LOW_HEIGHT, excluded)
	return low if float(low.score) > float(normal.score) else normal


func _candidate(space: PhysicsDirectSpaceState3D, anchor: Vector3, board: Vector3, rear: Vector3, distance: float, angle: float, height: float, excluded: Array[RID]) -> Dictionary:
	var desired:Vector3
	if _ramp_mode:
		desired=anchor+rear.rotated(_orbit_up,angle)*distance+_orbit_up*(height-CHEST_HEIGHT)*_ramp_lift
	else:
		desired=anchor+rear.rotated(Vector3.UP,angle)*distance*_horizontal_scale+Vector3.UP*(height-CHEST_HEIGHT-sin(_motion_pitch)*distance*.75)
	if not _ramp_mode and _motion_pitch>0.01:
		_ground_query.from=Vector3(desired.x,maxf(anchor.y+2.0,desired.y+2.0),desired.z)
		_ground_query.to=desired-Vector3.UP*(CAMERA_RADIUS+CLEARANCE)
		var hit:=space.intersect_ray(_ground_query)
		if not hit.is_empty() and Vector3(hit.normal).y>.45:
			desired.y=maxf(desired.y,Vector3(hit.position).y+CAMERA_RADIUS+CLEARANCE+.02)
	var position := _sweep(space, anchor, desired)
	var reach := position.distance_to(anchor) if _ramp_mode else Vector2(position.x-anchor.x,position.z-anchor.z).length()
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
	if anchor.distance_to(position) < _minimum_arm or not _clear_volume(space, position): return false
	# Chest alone can be clear while a lip or column hides the board or head.
	for height: float in [0.12, CHEST_HEIGHT, 1.8]:
		var query := PhysicsRayQueryParameters3D.create(position, board + _body_up * height, 1, excluded)
		if not space.intersect_ray(query).is_empty(): return false
	return true
