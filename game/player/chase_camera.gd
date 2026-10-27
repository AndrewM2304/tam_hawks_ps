extends RefCounted
## Original volume-aware chase camera using Godot's native physics queries.
## The rider's movement and travel heading are never modified here.

const Footwear = preload("res://game/player/skater_footwear.gd")

const CHEST_HEIGHT := 1.05
const CAMERA_RADIUS := 0.25
const CLEARANCE := 0.045
const MIN_USEFUL_ARM := 3.0
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
const AIR_RAMP_ARM := 1.8
const FEATURE_RAMP_ARM := 2.0
const ROLL_RATE := 6.0
const MAX_CAMERA_SPEED := 48.0
const ORBIT_ANGLES := [0.7853981634, -0.7853981634, 1.5707963268, -1.5707963268, 2.3561944902, -2.3561944902, PI]

var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()
var _ready := false
var _selected_angle := 0.0
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
var _ramp_air_sequence := -1
var _ramp_exit_remaining := 0.0
var _return_arm := AIR_RAMP_ARM
var _minimum_arm := MIN_USEFUL_ARM
var _ground_query := PhysicsRayQueryParameters3D.new()
var _visibility_query := PhysicsRayQueryParameters3D.new()
var _ground_board_y := 0.0
var _wheel_landmarks:PackedVector3Array=PackedVector3Array()
var _head_landmarks := PackedVector3Array()
var _head_mesh: MeshInstance3D
var _framing_targets := PackedVector3Array()
var _foot_targets := PackedVector3Array()
var _head_targets := PackedVector3Array()
var _head_bounds := PackedVector3Array()
var _head_sight := ConvexPolygonShape3D.new()
var _head_query := PhysicsShapeQueryParameters3D.new()
var _travel_velocity := Vector3.ZERO
## Exact same-update answers only. No state survives into another render frame.
var debug_query_cache_enabled := true
var _query_cache_active := false
var _clear_results: Dictionary = {}
var _usable_results: Dictionary = {}
var _shape_queries := 0
var _visibility_rays := 0
var _motion_casts := 0
var _clear_hits := 0
var _usable_hits := 0
var last_update_queries: Dictionary:
	get:
		return {"shape":_shape_queries,"ray":_visibility_rays,"cast":_motion_casts,
			"clear_hits":_clear_hits,"usable_hits":_usable_hits}


func _init() -> void:
	_sphere.radius = CAMERA_RADIUS
	_query.shape = _sphere
	_query.collision_mask = 1
	_query.collide_with_bodies = true
	_query.collide_with_areas = false
	_query.margin = 0.015
	_visibility_query.collision_mask = 1 | 8
	_visibility_query.collide_with_bodies = true
	_visibility_query.collide_with_areas = false
	_visibility_query.hit_back_faces = true
	_visibility_query.hit_from_inside = false
	_head_sight.margin = 0.0
	_head_query.shape = _head_sight
	_head_query.collision_mask = 1 | 8
	_head_query.collide_with_bodies = true
	_head_query.collide_with_areas = false
	_head_query.margin = 0.0


func reset() -> void:
	_end_query_cache()
	_ready = false
	_selected_angle = 0.0
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
	_ramp_air_sequence = -1
	_ramp_exit_remaining = 0.0
	_return_arm = AIR_RAMP_ARM
	_minimum_arm = MIN_USEFUL_ARM
	_ground_board_y = 0.0
	_foot_targets.clear()
	_head_targets.clear()
	_head_bounds.clear()
	_travel_velocity = Vector3.ZERO


func prepare_board_landmarks(rig: Object) -> void:
	if not _wheel_landmarks.is_empty() or not is_instance_valid(rig) or not rig.has_method("board_contact_geometry"): return
	_head_mesh = rig._head.get_node_or_null("AnatomicalHead") as MeshInstance3D
	if is_instance_valid(_head_mesh) and _head_mesh.mesh != null:
		# Eight conservative head bounds contain its complete visible mesh.
		# Framing needs no per-frame scan of hundreds of anatomical hull vertices.
		var bounds := _head_mesh.mesh.get_aabb()
		for x: float in [bounds.position.x,bounds.end.x]:
			for y: float in [bounds.position.y,bounds.end.y]:
				for z: float in [bounds.position.z,bounds.end.z]:
					_head_landmarks.append(Vector3(x,y,z))
	var board_inverse: Transform3D = rig._board.global_transform.affine_inverse()
	var unique: Dictionary = {}
	for mesh: MeshInstance3D in rig.board_contact_geometry().meshes:
		var hull: ConvexPolygonShape3D = mesh.mesh.create_convex_shape(true,false)
		var vertices := PackedVector3Array()
		for surface in mesh.mesh.get_surface_count():
			vertices.append_array(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
		for extremity: Vector3 in hull.points:
			var nearest := Vector3.ZERO
			var distance := INF
			for vertex: Vector3 in vertices:
				var gap := vertex.distance_squared_to(extremity)
				if gap<distance:distance=gap;nearest=vertex
			unique[board_inverse*mesh.to_global(nearest)]=true
	for point: Vector3 in unique:_wheel_landmarks.append(point)


func update(rider: CharacterBody3D, camera: Camera3D, delta: float, sensitivity: float, reduced_motion: bool) -> void:
	_end_query_cache()
	_head_targets.clear()
	_head_bounds.clear()
	if not is_instance_valid(rider) or not is_instance_valid(camera) or not rider.is_inside_tree(): return
	# _process follows the same frame the renderer displays. Reading the newest
	# physics transform here makes an otherwise smoothed camera judder at 60 Hz.
	# Physics callers/tests retain their exact current contact frame.
	var frame := _follow_transform(rider)
	var board := frame.origin
	if not board.is_finite(): return
	_foot_targets.clear()
	var rig: Variant = rider.get("_visual_rig")
	if is_instance_valid(rig):
		if _wheel_landmarks.is_empty(): prepare_board_landmarks(rig)
		# A crouched head can be hidden by a thin overhead deck even when
		# the fixed1.8m proxy passes above it and foot rays pass below it.
		# Keep both ends of interpolation; all targets are fixed before caching.
		_head_targets.append(_follow_transform(rig._head).origin)
		var actual_head: Vector3 = rig._head.global_position
		if actual_head != _head_targets[0]: _head_targets.append(actual_head)
		if is_instance_valid(_head_mesh):
			var head_frame := _follow_transform(_head_mesh)
			var actual_frame := _head_mesh.global_transform
			for corner: Vector3 in _head_landmarks:
				_head_bounds.append(head_frame * corner)
				if actual_frame != head_frame: _head_bounds.append(actual_frame * corner)
		for leg: Dictionary in rig._legs:
			var foot := _follow_transform(leg.foot)
			_foot_targets.append(foot * Footwear.SOLE_CONTACT)
			_foot_targets.append(foot * Footwear.TOE_CONTACT)
			var actual_foot: Transform3D = leg.foot.global_transform
			if actual_foot != foot:
				_foot_targets.append(actual_foot * Footwear.SOLE_CONTACT)
				_foot_targets.append(actual_foot * Footwear.TOE_CONTACT)
		# The real wheel bearings sit below the nominal board landmark and
		# planted soles. A shallow arrival bank can hide them independently.
		if not _wheel_landmarks.is_empty() and not bool(rider.get("bail_active")):
			var deck:Variant=rider.get("_board_visual")
			if is_instance_valid(deck):
				var deck_frame:=_follow_transform(deck)
				for point:Vector3 in _wheel_landmarks:_foot_targets.append(deck_frame*point)
				var actual_deck: Transform3D=deck.global_transform
				if actual_deck != deck_frame:
					for point: Vector3 in _wheel_landmarks:_foot_targets.append(actual_deck*point)
	# Retain default heading confirmation/smoothing, but use completed native
	# platform travel where appropriate. Helper cache cannot reverse the view.
	var native_platform := rider.is_on_floor() and rider.get_platform_velocity().length_squared() > 0.01 \
		and bool(rider.get("_native_floor_valid")) \
		and not bool(rider.get("transition_active")) and not bool(rider.get("grinding"))
	_travel_velocity = rider.get_real_velocity() if native_platform else rider.velocity
	if not _travel_velocity.is_finite(): _travel_velocity = Vector3.ZERO
	# Transitions can lay the skater back against a curved wall. Occlusion rays
	# follow the actual body axis; ramps retain the skater's local up axis.
	_body_up = _contact_up(rider)
	var ordinary_air := bool(rider.get("airborne")) and not bool(rider.get("_ramp_air")) and not bool(rider.get("transition_active"))
	if not _ready or not bool(rider.get("airborne")):
		_ground_board_y = board.y
	elif ordinary_air:
		# Keep ordinary jumps inside a stable vertical viewing window. Follow
		# only a larger drop/rise, so a ledge fall cannot leave the body behind.
		_ground_board_y = clampf(_ground_board_y,board.y-2.6,board.y+1.0)
	var view_board := board
	if ordinary_air:view_board.y=_ground_board_y
	var anchor := view_board + _body_up * CHEST_HEIGHT
	var space := rider.get_world_3d().direct_space_state
	var excluded: Array[RID] = [rider.get_rid()]
	_query.exclude = excluded
	_ground_query.exclude = excluded
	_head_query.exclude = excluded
	_ground_query.collision_mask = 1
	# Bound a delayed render update to one simulation step so a scheduling
	# stall cannot spend its entire elapsed time on an apex camera turn.
	var step := clampf(delta, 0.0, 1.0 / 60.0) if is_finite(delta) else 0.0
	var response := clampf(sensitivity, 0.5, 2.0) if is_finite(sensitivity) else 1.0
	var speed := clampf(Vector2(_travel_velocity.x, _travel_velocity.z).length(), 0.0, 15.0)
	var distance := 4.9 if reduced_motion else 4.9 + speed * 0.02
	var rear := Vector3(frame.basis.z.x, 0, frame.basis.z.z).normalized()
	if rear.length_squared() < 0.1: rear = Vector3.BACK
	if _ready and anchor.distance_to(_last_anchor) > 12.0:
		reset()
		_body_up = _contact_up(rider)
	var ramp_mode := bool(rider.get("transition_active")) or (bool(rider.get("airborne")) and bool(rider.get("_ramp_air")))
	if _ramp_mode and not ramp_mode:
		_ramp_exit_remaining = 0.55
		# Continue behind the completed return; do not restart a second world
		# heading/pitch turn from stale pre-ramp camera state.
		var horizontal := Vector3(_travel_velocity.x,0,_travel_velocity.z)
		_world_rear = -horizontal.normalized() if horizontal.length()>.1 else rear
		_motion_pitch = atan2(rider.velocity.y,maxf(horizontal.length(),PITCH_RUN))
	if ramp_mode != _ramp_mode:
		_selected_angle = 0.0
	_ramp_mode = ramp_mode
	_minimum_arm = 1.6 if _ramp_mode or _ramp_exit_remaining>0.0 else MIN_USEFUL_ARM
	_orbit_up = _body_up if _ramp_mode else Vector3.UP
	if _ramp_mode:
		var curved: Variant = rider.get("_feature_transition")
		_return_arm = FEATURE_RAMP_ARM if curved!=null and curved.active else AIR_RAMP_ARM
		if bool(rider.get("transition_active")) and (not bool(rider.get("airborne")) or not bool(rider.get("_ramp_air"))):
			var support: Basis = rider.get_camera_support_frame()
			_motion_direction = -support.z
			_ramp_lift = clampf(_orbit_up.dot(Vector3.UP),0.0,1.0)
			_ramp_turn = 0.0
			distance = lerpf(_return_arm,distance,pow(_ramp_lift,4.0))
			if _travel_velocity.y< -0.1:distance=_return_arm
		else:
			# One half-circle in the skater's ramp plane, with one fixed side.
			# The local up axis is the ramp normal, never world-up or trick yaw.
			# A render may skip the brief supported frame between two returns.
			# Reset from the physics launch identity, not that missing frame.
			_advance_ramp_turn(int(rider.get("_ramp_air_sequence")),rider.velocity.y,rider.RAMP_AIR_GRAVITY)
			_motion_direction = rider._ramp_launch_forward.rotated(_orbit_up,_ramp_turn).normalized()
			_ramp_lift = 0.0
			distance = _return_arm
		rear = -_motion_direction
		_horizontal_scale = 1.0
		_motion_pitch = asin(clampf(_motion_direction.y,-1.0,1.0))
	else:
		_ramp_exit_remaining = maxf(0.0,_ramp_exit_remaining-step)
		if _ramp_exit_remaining>0.0:
			distance = lerpf(_return_arm,distance,smoothstep(0.0,0.30,0.30-_ramp_exit_remaining))
		rear = _heading(rider,rear,step)
		var travel := _travel_velocity
		# Ordinary ollies do not pitch the chase along their vertical velocity.
		# Ground grades still follow actual travel, and ramps have their own frame.
		var pitch := atan2(travel.y,maxf(Vector2(travel.x,travel.z).length(),PITCH_RUN)) if travel.length()>.5 and not ordinary_air else 0.0
		_motion_pitch = move_toward(_motion_pitch,clampf(pitch,-MAX_MOTION_PITCH,MAX_MOTION_PITCH),PITCH_RATE*step)
		_horizontal_scale = maxf(.6 if _motion_pitch>0.0 else 0.0,cos(_motion_pitch))
		_motion_direction = -rear*cos(_motion_pitch)+Vector3.UP*sin(_motion_pitch)
	# From here until return, physics, exclusions and all anatomical landmarks
	# are fixed. Repeated exact candidates can reuse their complete native result.
	_begin_query_cache()
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
	# Stable headroom for exaggerated charged flat ollies, without lifting the
	# camera along with the skater. Ramp views retain their local aiming frame.
	if not _ramp_mode:target += Vector3.UP*.55
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
	if (_ramp_mode or _ramp_exit_remaining > 0.0) and is_instance_valid(rig):
		# A clear short ramp arm can still crop the actual board at the edge
		# of the lens. Correct only the clipped aim; retain orbit, roll and FOV.
		_fit_ramp_framing(camera,_follow_transform(rig._head).origin,rig)
	_ready = true
	_last_anchor = anchor
	_end_query_cache()


func _fit_ramp_framing(camera: Camera3D, head: Vector3, rig: Object) -> void:
	if not head.is_finite() or _foot_targets.is_empty(): return
	var head_frame := _follow_transform(_head_mesh) if is_instance_valid(_head_mesh) else Transform3D.IDENTITY
	_framing_targets.clear()
	_framing_targets.append_array(_foot_targets)
	_framing_targets.append(head)
	# Include both ends of native interpolation. Otherwise a camera correct for
	# the displayed pose can crop the next physical pose during a fast return.
	var board_frame: Transform3D = rig._board.global_transform
	for point: Vector3 in _wheel_landmarks: _framing_targets.append(board_frame*point)
	for leg: Dictionary in rig._legs:
		_framing_targets.append(leg.foot.to_global(Footwear.SOLE_CONTACT))
		_framing_targets.append(leg.foot.to_global(Footwear.TOE_CONTACT))
	for point: Vector3 in _head_landmarks:
		_framing_targets.append(head_frame*point)
		_framing_targets.append(_head_mesh.global_transform*point)
	for attempt in 3:
		var projection := camera.get_camera_projection()
		var half_x := atan(1.0 / absf(projection.x.x)) * 0.97
		var half_y := atan(1.0 / absf(projection.y.y)) * 0.97
		var inverse := camera.global_transform.affine_inverse()
		var min_x := INF
		var max_x := -INF
		var min_y := INF
		var max_y := -INF
		for marker: Vector3 in _framing_targets:
			var local: Vector3 = inverse * marker
			var x := atan2(local.x,-local.z)
			var y := atan2(local.y,-local.z)
			min_x = minf(min_x,x)
			max_x = maxf(max_x,x)
			min_y = minf(min_y,y)
			max_y = maxf(max_y,y)
		var yaw_low := max_x-half_x
		var yaw_high := min_x+half_x
		var pitch_low := max_y-half_y
		var pitch_high := min_y+half_y
		var yaw := clampf(0.0,yaw_low,yaw_high) if yaw_low <= yaw_high else (min_x+max_x)*0.5
		var pitch := clampf(0.0,pitch_low,pitch_high) if pitch_low <= pitch_high else (min_y+max_y)*0.5
		if absf(yaw) < 0.00001 and absf(pitch) < 0.00001: return
		var direction := (camera.global_basis * Vector3(tan(yaw),tan(pitch),-1.0)).normalized()
		var up := camera.global_basis.y.slide(direction).normalized()
		if up.length_squared() < 0.1: return
		camera.global_basis = Basis.looking_at(direction,up)


func _begin_query_cache() -> void:
	_clear_results.clear()
	_usable_results.clear()
	_shape_queries = 0
	_visibility_rays = 0
	_motion_casts = 0
	_clear_hits = 0
	_usable_hits = 0
	_query_cache_active = debug_query_cache_enabled


func _end_query_cache() -> void:
	_query_cache_active = false
	_clear_results.clear()
	_usable_results.clear()


func _advance_ramp_turn(sequence: int, vertical_speed: float, gravity: float) -> void:
	if sequence != _ramp_air_sequence:
		_ramp_air_sequence = sequence
		_ramp_turn = 0.0
	var time_to_apex := vertical_speed / gravity
	var progress := clampf(1.0-(time_to_apex-1.0/14.0)/APEX_ORBIT_SECONDS,0.0,1.0)
	_ramp_turn = maxf(_ramp_turn,PI*smoothstep(0.0,1.0,progress))


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
	# A grazing lip may close the straight chord before the next frame. Search
	# the bounded neighbourhood for a clear continuation instead of jumping
	# straight to a distant fallback endpoint. Every trial keeps the same volume
	# and anatomical visibility checks.
	var toward := (desired-previous).normalized()
	for axis: Vector3 in [Vector3.UP,_body_up,Vector3.RIGHT,Vector3.LEFT,Vector3.BACK,Vector3.FORWARD]:
		for weight: float in [0.5,1.0,2.0]:
			var trial := previous+(toward+axis*weight).normalized()*max_move
			if _clear_volume(space,previous):trial=_sweep(space,previous,trial)
			if _usable(space,board,anchor,trial,excluded):return trial
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
	if rider.has_method("get_support_normal"):
		var value: Variant = rider.call("get_support_normal")
		if value is Vector3 and value.is_finite() and value.length_squared() > 0.1:
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
	var requested := facing_rear * _direction_sign(_travel_velocity,facing_rear,delta)
	if bool(rider.get("airborne")):
		var travel := Vector3(_travel_velocity.x,0,_travel_velocity.z)
		requested = -travel.normalized() if travel.length()>=REVERSE_MIN_SPEED else _world_rear
	if requested.length_squared()<.1:requested=facing_rear
	if _world_rear.length_squared()<.1:_world_rear=requested
	var yaw := rotate_toward(atan2(_world_rear.x,_world_rear.z),atan2(requested.x,requested.z),HEADING_RATE*delta)
	_world_rear=Vector3(sin(yaw),0,cos(yaw))
	return _world_rear


func _choose(space: PhysicsDirectSpaceState3D, anchor: Vector3, board: Vector3, rear: Vector3, distance: float, excluded: Array[RID], delta: float) -> Dictionary:
	var ordinary := _best_height(space, anchor, board, rear, distance, 0.0, excluded)
	# A shortened but fully usable rear arm beats a wider side view, including
	# the half-pipe's flat bottom (ordinary ground). Orbit interpolation already
	# smooths the return; a separate side-hold timer keeps it sideways too long.
	if ordinary.usable:
		_selected_angle=0.0
		return ordinary
	if not is_zero_approx(_selected_angle):
		var current := _best_height(space, anchor, board, rear, distance, _selected_angle, excluded)
		if current.usable:return current
	# Search only while the current view is obstructed. Retaining a useful
	# chosen side avoids alternating left/right against the same wall.
	var best := ordinary
	for angle: float in ORBIT_ANGLES:
		var candidate := _best_height(space, anchor, board, rear, distance, angle, excluded)
		if float(candidate.score) > float(best.score): best = candidate
	if not best.usable:
		# Retain the work branch's last-resort swept high arm only after all
		# ordinary rear/side heights fail the full body and real-foot checks.
		for angle:float in [0.0]+ORBIT_ANGLES:
			var candidate:=_candidate(space,anchor,board,rear,distance,angle,7.2,excluded)
			if float(candidate.score)>float(best.score):best=candidate
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
	_motion_casts += 1
	var fractions := space.cast_motion(_query)
	if fractions.size() < 2: return from
	var fraction := clampf(fractions[0], 0.0, 1.0)
	# Unclipped endpoints already receive the caller's full usable-volume check.
	if fraction>=.9999:return to
	var reach := maxf(0.0,length*fraction-CLEARANCE)
	# Native motion and overlap queries disagree slightly at a grazing floor.
	# Keep the full volume margin, backing off the same rear path until its
	# endpoint is actually clear; do not orbit sideways around that tiny error.
	for attempt in 6:
		var position := from+motion.normalized()*reach
		if _clear_volume(space,position):return position
		reach=maxf(0.0,reach-CLEARANCE*pow(2.0,float(attempt)))
	return from


func _clear_volume(space: PhysicsDirectSpaceState3D, position: Vector3) -> bool:
	if _query_cache_active and _clear_results.has(position):
		_clear_hits += 1
		return _clear_results[position]
	_query.transform = Transform3D(Basis.IDENTITY, position)
	_query.motion = Vector3.ZERO
	_shape_queries += 1
	var clear := space.intersect_shape(_query, 1).is_empty()
	if _query_cache_active: _clear_results[position] = clear
	return clear


func _usable(space: PhysicsDirectSpaceState3D, board: Vector3, anchor: Vector3, position: Vector3, excluded: Array[RID]) -> bool:
	if _query_cache_active and _usable_results.has(position):
		_usable_hits += 1
		return _usable_results[position]
	var usable := _usable_uncached(space,board,anchor,position,excluded)
	if _query_cache_active: _usable_results[position] = usable
	return usable


func _usable_uncached(space: PhysicsDirectSpaceState3D, board: Vector3, anchor: Vector3, position: Vector3, excluded: Array[RID]) -> bool:
	if anchor.distance_to(position) < _minimum_arm or not _clear_volume(space, position): return false
	# Chest alone can be clear while a lip or column hides the board or head.
	for height: float in [0.12, CHEST_HEIGHT, 1.8]:
		if not _visibility_ray(space, position, board + _body_up * height, excluded).is_empty(): return false
	for point: Vector3 in _head_targets:
		if not _visibility_ray(space, position, point, excluded).is_empty(): return false
	if not _head_bounds.is_empty():
		# Centers and corner rays can all miss a thin slab crossing the visible
		# head between them. One convex visibility volume contains both current
		# and displayed head bounds, plus the endpoint; no geometry scan per ray.
		# Landmarks stay fixed throughout this update, so _usable caches this
		# single native overlap together with the existing body/foot visibility.
		var sight := PackedVector3Array([Vector3.ZERO])
		for corner: Vector3 in _head_bounds: sight.append(corner-position)
		_head_sight.points = sight
		_head_query.transform = Transform3D(Basis.IDENTITY,position)
		_head_query.motion = Vector3.ZERO
		_head_query.exclude = excluded
		_shape_queries += 1
		if not space.intersect_shape(_head_query,1).is_empty(): return false
	for point: Vector3 in _foot_targets:
		var hit := _visibility_ray(space, position, point, excluded)
		if hit.is_empty(): continue
		# Grounded rubber already has a strict4mm contact band. Only that same
		# actual endpoint support may be touched; an intervening bank/wall fails.
		var support := _visibility_ray(space, point+_body_up*0.03, point-_body_up*0.03, excluded)
		if support.is_empty() or support.collider!=hit.collider or Vector3(hit.normal).dot(_body_up)<0.65 \
				or Vector3(support.normal).dot(hit.normal)<0.99 \
				or absf((point-Vector3(support.position)).dot(support.normal))>0.004 \
				or absf((point-Vector3(hit.position)).dot(hit.normal))>0.004: return false
	return true


func _visibility_ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, excluded: Array[RID]) -> Dictionary:
	# These queries complete sequentially. Reuse the parameter object, never a
	# native answer; every body/head/foot/support ray supplies fresh endpoints
	# and exclusions, including direct calls outside the same-update cache.
	_visibility_query.from = from
	_visibility_query.to = to
	_visibility_query.exclude = excluded
	_visibility_rays += 1
	return space.intersect_ray(_visibility_query)
