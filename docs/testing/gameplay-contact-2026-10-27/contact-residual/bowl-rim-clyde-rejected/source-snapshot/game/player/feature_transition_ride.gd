extends RefCounted
## Original finite transition state around real tagged collision, native capsule
## movement and full tangent gravity. No upstream implementation is copied.

const GRAVITY := 22.0
const CONTACT_OFFSET := 0.022
const CONTACT_REACH := 0.10
const MAX_STEP_METRES := 0.055
const MAX_STEP_ANGLE := PI / 90.0
const MAX_SPEED := 19.0

var active := false
var state := "idle"
var feature: Node3D = null
var air_feature: Node3D = null
var normal := Vector3.UP
var forward := Vector3.FORWARD
var lip := false
var lip_balance := 0.0
var max_support_error := 0.0
var _theta := 0.0
var _x := 0.0
var _speed := 0.0
var _lateral_speed := 0.0
var _air_velocity := Vector3.ZERO
var _air_age := 0.0
var _lip_age := 0.0
var _pending_event := ""
var _last_push := 0.0
var _last_brake := 0.0
var _air_push_armed := false
var _air_brake_armed := false
var _transfer_direction := 0.0
var _applied_transfer_direction := 0.0
var _collision: CollisionShape3D
var _collision_rest := Transform3D.IDENTITY
var _has_rest := false
var _half_height := 0.85
var _coping_ray := PhysicsRayQueryParameters3D.new()
var _coping_body_query := PhysicsShapeQueryParameters3D.new()
var _coping_sections: Dictionary = {}
var _coping_turn_shape := CapsuleShape3D.new()
var _coping_turn_queries := 0
var _air_contact_pending := false

func reset(body: CharacterBody3D = null) -> void:
	if is_instance_valid(_collision) and _has_rest:
		_collision.transform = _collision_rest
		# The visible figure returns upright on release. Do not let the
		# camera keep the invisible capsule's previous wall axis for one
		# interpolated frame after that physical support has already ended.
		_collision.reset_physics_interpolation()
	if is_instance_valid(body):
		body.up_direction = Vector3.UP
	active = false
	state = "idle"
	feature = null
	air_feature = null
	normal = Vector3.UP
	forward = Vector3.FORWARD
	lip = false
	lip_balance = 0.0
	_theta = 0.0
	_x = 0.0
	_speed = 0.0
	_lateral_speed = 0.0
	_air_velocity = Vector3.ZERO
	_air_age = 0.0
	_lip_age = 0.0
	_pending_event = ""
	_air_contact_pending = false
	_last_push = 0.0
	_last_brake = 0.0
	_air_push_armed = false
	_air_brake_armed = false
	_transfer_direction = 0.0
	_applied_transfer_direction = 0.0
	max_support_error = 0.0

func try_enter(body: CharacterBody3D, velocity: Vector3) -> bool:
	if active or not is_instance_valid(body) or not body.is_inside_tree() or not velocity.is_finite():
		return false
	for candidate: Node in body.get_tree().get_nodes_in_group("skate_transitions"):
		if candidate is Node3D and _acquire(body, candidate, velocity):
			return true
	# A completed ordinary floor landing ends a released-air handoff even
	# when no other finite feature acquired it. Do not carry it into a new run.
	if body.is_on_floor(): _air_contact_pending=false
	return false

func _acquire(body: CharacterBody3D, candidate: Node3D, velocity: Vector3) -> bool:
	if not is_instance_valid(candidate) or not candidate.has_method("surface_sample"):
		return false
	var contact: Dictionary = candidate.surface_sample(body.global_position)
	if contact.is_empty() or not contact.in_bounds or contact.distance > CONTACT_REACH:
		return false
	if (body.global_position - Vector3(contact.point)).dot(contact.normal) < -0.008:
		return false
	if velocity.dot(contact.normal) > 1.1:
		return false
	# A returning rider leaves the finite toe with ordinary ground physics.
	# Recapturing outward motion here would repeatedly exit without moving.
	if float(contact.theta) < 0.06 and velocity.dot(contact.tangent) <= 0.1:
		return false
	if not _real_face_contact(body, candidate, contact):
		return false
	_cache_collision(body)
	if not _surface_body_target(body,candidate,contact).is_finite(): return false
	feature = candidate
	air_feature = null
	_theta = float(contact.theta)
	_x = float(contact.x)
	_speed = velocity.dot(contact.tangent)
	_lateral_speed = velocity.dot(contact.lateral)
	var was_air := _air_contact_pending or state == "air" or (not body.is_on_floor() and velocity.y < -0.5)
	_air_contact_pending=false
	active = true
	state = "surface"
	lip = false
	normal = contact.normal
	forward = _travel_direction(contact)
	_orient_collision(body, normal)
	if was_air:
		_pending_event = "landed"
	return true

func step(body: CharacterBody3D, delta: float, push: float, brake: float,
		steer: float, jump: bool = false, lip_held: bool = false,
		jump_impulse: float = 8.8) -> Dictionary:
	if not active:
		return _result(body, "")
	if not is_instance_valid(feature) or not is_finite(delta) or delta <= 0.0 \
			or not is_finite(push) or not is_finite(brake) or not is_finite(steer):
		return _end(body, "bail")
	push = clampf(push, 0.0, 1.0)
	brake = clampf(brake, 0.0, 1.0)
	steer = clampf(steer, -1.0, 1.0)
	_last_push = push
	_last_brake = brake
	jump_impulse = clampf(jump_impulse, 3.0, 11.5) if is_finite(jump_impulse) else 8.8
	var event := _pending_event
	_pending_event = ""
	if state == "air":
		return _tick_air(body, delta, steer, push, brake)
	if state == "lip":
		var support: Dictionary = feature.sample(PI * 0.5, _x)
		if not _real_face_contact(body, feature, support) or not _real_lip_contact(body,feature.lip_frame(_x)) \
				or not _can_occupy(body, body.global_position, normal):
			return _end(body, "bail")
		_lip_age += delta
		lip_balance += ((0.16 + _lip_age * 0.06) * (1.0 if lip_balance >= 0.0 else -1.0) + steer * 1.2) * delta
		if absf(lip_balance) >= 1.0:
			return _end(body, "bail")
		if jump:
			var frame: Dictionary = feature.lip_frame(_x)
			var lift := Vector3.UP*jump_impulse
			if not feature.wrap_lateral:lift+=frame.face_normal*jump_impulse*0.6
			return _launch(body, lift, "launch")
		if not lip_held:
			if not _drop_from_lip(body,support): return _end(body,"bail")
			state = "surface"
			lip = false
			_speed = -0.6
			_theta = PI * 0.5 - 0.006
			normal = support.normal
		else:
			body.velocity = Vector3.ZERO
			return _result(body, event)
	if jump:
		var sample: Dictionary = feature.sample(_theta, _x)
		if feature.wrap_lateral and _theta>=PI*0.25:
			# A steep bowl ollie is a vert air, not an inward normal blast
			# across the whole bowl. Retain upward carry and lateral momentum;
			# a fresh in-air direction remains the explicit break-out control.
			return _launch(body,Vector3.UP*(maxf(0.0,Vector3(sample.tangent).y*_speed)+jump_impulse)
				+sample.lateral*_lateral_speed,"launch")
		return _launch(body, sample.tangent * _speed + sample.lateral * _lateral_speed + normal * jump_impulse, "launch")
	var travel_speed := Vector2(_speed,_lateral_speed).length() if feature.wrap_lateral else absf(_speed)
	var travel := maxf(travel_speed, 1.0) * delta
	var steps := maxi(1, ceili(travel / minf(MAX_STEP_METRES, float(feature.radius) * MAX_STEP_ANGLE)))
	var h := delta / float(steps)
	for index in steps:
		var sample: Dictionary = feature.sample(_theta, _x)
		if feature.wrap_lateral:
			# Parallel-transport the two tangent components around the bowl.
			# This rotates existing kinetic energy; it is not a lateral boost.
			var curve: Vector2 = feature.lateral_acceleration(_theta, _x, _speed, _lateral_speed)
			var tangent_velocity := Vector2(_speed, _lateral_speed)
			var squared_speed := tangent_velocity.length_squared()
			var transport := (curve.y * _speed - curve.x * _lateral_speed) / squared_speed if squared_speed > 0.001 else 0.0
			tangent_velocity = tangent_velocity.rotated((transport + steer * 1.4) * h)
			tangent_velocity.x -= GRAVITY * sin(_theta) * h
			var magnitude := tangent_velocity.length()
			if push > 0.0:
				tangent_velocity = (tangent_velocity.normalized() if magnitude > 0.1 else Vector2.RIGHT) * minf(MAX_SPEED,magnitude+push*6.0*h)
			magnitude = tangent_velocity.length()
			if magnitude > 0.001:
				tangent_velocity *= move_toward(magnitude,0.0,(brake*20.0 if brake>0.0 else 0.10)*h)/magnitude
			tangent_velocity = tangent_velocity.limit_length(MAX_SPEED)
			_speed = tangent_velocity.x
			_lateral_speed = tangent_velocity.y
		else:
			# Existing straight quarter-pipe control remains unchanged.
			_speed += (-GRAVITY * sin(_theta) + push * 6.0) * h
			if brake > 0.0:
				_speed = move_toward(_speed, 0.0, brake * 20.0 * h)
			elif absf(_speed) > 0.05:
				_speed = move_toward(_speed, 0.0, 0.10 * h)
			_speed = clampf(_speed, -MAX_SPEED, MAX_SPEED)
			_lateral_speed = move_toward(_lateral_speed, steer * absf(_speed) * 0.45, 5.0 * h)
		var next_theta := _theta + _speed / float(feature.radius) * h
		var next_x: float = feature.advance_lateral(_theta,_x,_lateral_speed*h)
		# Some authored bowls have an actual opening in their finite concrete
		# face. Leave the last verified contact with its tangent momentum rather
		# than trying to occupy missing collision or inventing a pop impulse.
		# The optional predicate describes openings only; the ordinary toe,
		# width and lip bounds below remain authoritative for every feature.
		if feature.has_method("contact_is_valid") and not feature.contact_is_valid(next_theta,next_x):
			return _launch(body, sample.tangent * _speed + sample.lateral * _lateral_speed, "launch")
		if not feature.wrap_lateral and absf(next_x) > float(feature.width) * 0.5 - 0.005:
			return _launch(body, sample.tangent * _speed + sample.lateral * _lateral_speed, "launch")
		if next_theta < 0.0:
			var toe: Dictionary = feature.sample(0.0, next_x)
			if not _move_supported(body, toe, true):
				return _end(body, "bail")
			body.velocity = toe.tangent * _speed + toe.lateral * _lateral_speed
			return _end(body, "exit")
		if next_theta >= PI * 0.5:
			var lip_sample: Dictionary = feature.sample(PI * 0.5, next_x)
			if not _move_supported(body, lip_sample):
				return _end(body, "bail")
			_theta = PI * 0.5
			_x = next_x
			if lip_held:
				if not _move_to_lip(body): return _end(body,"bail")
				state = "lip"
				lip = true
				lip_balance = 0.03
				_lip_age = 0.0
				body.velocity = Vector3.ZERO
				return _result(body, "lip")
			return _launch(body, lip_sample.tangent * _speed + lip_sample.lateral * _lateral_speed, "launch")
		var target: Dictionary = feature.sample(next_theta, next_x)
		if not _move_supported(body, target):
			return _end(body, "bail")
		_theta = next_theta
		_x = next_x
		body.velocity = target.tangent * _speed + target.lateral * _lateral_speed
	return _result(body, event)

func _tick_air(body: CharacterBody3D, delta: float, steer: float, push: float, brake: float) -> Dictionary:
	var had_air_move := _air_age > 0.0
	_air_age += delta
	var air_frame: Dictionary = feature.air_return_frame(body.global_position,_x)
	_update_transfer_intent(push, brake)
	var transfer := _transfer_direction
	if transfer < 0.0 and (push < 0.2 or body.global_position.y < float(air_frame.lip_height) + 0.30): transfer = 0.0
	if transfer > 0.0 and brake < 0.2: transfer = 0.0
	_applied_transfer_direction = transfer
	var horizontal := Vector3(_air_velocity.x, 0, _air_velocity.z)
	var limit := maxf(3.5, horizontal.length())
	var outward: Vector3 = air_frame.normal
	var lateral: Vector3 = air_frame.lateral
	horizontal += (outward * transfer * 6.0 + lateral * steer * 4.0) * delta
	horizontal = horizontal.limit_length(limit)
	_air_velocity.x = horizontal.x
	_air_velocity.z = horizontal.z
	# A finite opening launches from the last verified face sample. Advance
	# native air once before testing proximity to that same sample, otherwise
	# a tangent departure can repeatedly land/relaunch without travelling.
	# Actual collision on the first air move still admits a real landing below.
	if had_air_move and _air_velocity.y <= 0.0 and _find_return(body, _air_velocity):
		body.velocity = _air_velocity
		var result := step(body, delta, 0.0, 0.0, steer)
		result.event = "landed"
		return result
	var contact: Dictionary = feature.surface_sample(body.global_position)
	# Above the actual vertical lip, retain its contact frame through the apex.
	# Euclidean distance from the finite arc grows with height; it must not detach
	# an otherwise vertical return and put an upright capsule into the wall.
	var over_lip: bool = air_frame.over_lip
	var inside_bowl := false
	if feature.wrap_lateral:
		var local: Vector3 = feature.to_local(body.global_position)
		inside_bowl = Vector2(local.x,local.z).length()<float(feature.floor_radius)+float(feature.radius)
	if _air_age > 0.08 and not over_lip and not inside_bowl and (contact.is_empty() or contact.distance > 0.55):
		if _can_occupy(body, body.global_position, Vector3.UP):
			body.velocity = _air_velocity
			return _end(body, "exit_air")
	_air_velocity = _air_velocity.rotated(Vector3.UP, -steer * 0.50 * delta)
	_air_velocity.y -= GRAVITY * delta
	var hit := body.move_and_collide(_air_velocity * delta, false, 0.001)
	body.velocity = _air_velocity
	if hit:
		var obstacle: Object = hit.get_collider()
		if _air_velocity.y <= 0.0 and obstacle is Node and obstacle.has_meta("transition_feature") \
				and _acquire(body,obstacle.get_meta("transition_feature"),_air_velocity):
			return _result(body, "landed")
		if hit.get_normal().y > 0.65 and (_can_occupy(body, body.global_position, Vector3.UP) \
				or _recover_upright_floor(body)):
			# An oriented end-cap can touch a deck while the restored upright
			# board is still above it. Ordinary air confirms that final landing.
			body.velocity = _air_velocity
			return _end(body, "landed" if normal.dot(Vector3.UP) > 0.999 else "exit_air")
		return _end(body, "bail")
	if _air_age > 4.0 or body.global_position.y < -8.0:
		body.velocity = _air_velocity
		return _end(body, "exit_air")
	return _result(body, "")

## Recognize the input edge independently of clearance. The recorder must be
## able to distinguish a held approach from a recognized request below the lip.
func _update_transfer_intent(push: float, brake: float) -> void:
	if push < 0.2: _air_push_armed = true
	elif _air_push_armed:
		_transfer_direction = -1.0
		_air_push_armed = false
	if brake < 0.2: _air_brake_armed = true
	elif _air_brake_armed:
		_transfer_direction = 1.0
		_air_brake_armed = false

func transfer_intent_snapshot() -> Dictionary:
	var in_air := active and state == "air"
	return {"active": in_air, "requested_direction": _transfer_direction if in_air else 0.0,
		"recognized": in_air and not is_zero_approx(_transfer_direction),
		"applied_direction": _applied_transfer_direction if in_air else 0.0,
		"push_armed": in_air and _air_push_armed, "brake_armed": in_air and _air_brake_armed,
		"air_age": _air_age if in_air else 0.0,
		"last_push": _last_push, "last_brake": _last_brake}

func _recover_upright_floor(body: CharacterBody3D) -> bool:
	# An oriented foot can touch a bank below the legal upright capsule origin.
	# Ask native collision for its bounded recovery; never author an upward
	# teleport or ignore a wall/ceiling in order to restore ordinary air.
	var previous := _collision.transform
	_orient_collision(body,Vector3.UP)
	var proof := KinematicCollision3D.new()
	var contact := body.test_move(body.global_transform,Vector3.ZERO,proof,0.001,true,16)
	if contact and not _legal_floor_recovery(proof):
		_collision.transform = previous
		return false
	var before := body.global_position
	var recovered := body.move_and_collide(Vector3.ZERO,false,0.001,true,16)
	var movement := body.global_position-before
	if not movement.is_finite() or movement.length()>CONTACT_REACH or movement.y< -0.001 \
			or (recovered!=null and not _legal_floor_recovery(recovered)):
		_collision.transform = previous
		return false
	# A resting native floor may remain within the same1mm contact margin.
	# Shape-query emptiness incorrectly treats that legitimate contact as a wall.
	var resting := KinematicCollision3D.new()
	if body.test_move(body.global_transform,Vector3.ZERO,resting,0.001,true,16) \
			and not _legal_floor_recovery(resting):
		_collision.transform = previous
		return false
	return true

func _legal_floor_recovery(contact: KinematicCollision3D) -> bool:
	var motion := contact.get_travel()
	if not motion.is_finite() or motion.length()>CONTACT_REACH or motion.y< -0.001 \
			or not is_finite(contact.get_depth()) or contact.get_depth()>0.001: return false
	for index in contact.get_collision_count():
		var face := contact.get_normal(index)
		if not face.is_finite() or face.y<=0.65: return false
	return contact.get_collision_count()>0

func _find_return(body: CharacterBody3D, velocity: Vector3) -> bool:
	if _acquire(body,feature,velocity): return true
	for candidate: Node in body.get_tree().get_nodes_in_group("skate_transitions"):
		if candidate is Node3D and candidate != feature and _acquire(body,candidate,velocity): return true
	return false

func lip_frame() -> Dictionary:
	return feature.lip_frame(_x) if is_instance_valid(feature) else {}

## Root yaw may follow a curved line or commit a scored half-turn. Reapply the
## existing global contact axis immediately after that cosmetic/root change.
func refresh_frame(body: CharacterBody3D) -> void:
	if active:
		_orient_collision(body,normal)
		body.up_direction = normal

func _move_to_lip(body: CharacterBody3D) -> bool:
	var frame: Dictionary=feature.lip_frame(_x)
	var target: Vector3=frame.point+Vector3.UP*0.002
	if not _real_lip_contact(body,frame) or not _can_occupy(body,target,Vector3.UP): return false
	var support: Dictionary=feature.sample(PI*0.5,_x)
	var coping:=_coping_profile(body,feature,support)
	if coping.is_empty(): return false
	var face: Vector3=frame.face_normal
	var gap: float=(body.global_position-Vector3(support.point)).dot(face)
	var outward:=body.global_position+face*maxf(0.0,float(coping.offset)+0.002-gap)
	var turn:=outward+Vector3.UP*maxf(0.0,target.y-outward.y)
	var axis:=_collision.global_basis.y.normalized()
	if not _coping_segment_clear(body,body.global_position,outward,axis) \
			or not _coping_segment_clear(body,outward,turn,axis) \
			or not _coping_turn_clear(body,turn,axis,Vector3.UP) \
			or not _coping_segment_clear(body,turn,target,Vector3.UP): return false
	for point: Vector3 in [outward,turn]:
		if body.move_and_collide(point-body.global_position,false,0.001) \
				or body.global_position.distance_to(point)>0.01: return false
	_orient_collision(body,Vector3.UP)
	if body.move_and_collide(target-body.global_position,false,0.001) \
			or body.global_position.distance_to(target)>0.01: return false
	normal=Vector3.UP
	forward=-face
	body.up_direction=normal
	return true

func _drop_from_lip(body: CharacterBody3D,support: Dictionary) -> bool:
	var coping:=_coping_profile(body,feature,support)
	if coping.is_empty(): return false
	var axis: Vector3=support.normal
	var gap: float=(body.global_position-Vector3(support.point)).dot(axis)
	var turn:=body.global_position+axis*maxf(0.0,float(coping.offset)+0.002-gap)
	var old_axis:=_collision.global_basis.y.normalized()
	if not _coping_segment_clear(body,body.global_position,turn,old_axis) \
			or not _coping_turn_clear(body,turn,old_axis,axis): return false
	if body.move_and_collide(turn-body.global_position,false,0.001) \
			or body.global_position.distance_to(turn)>0.01: return false
	_orient_collision(body,axis)
	return true

func _coping_segment_clear(body: CharacterBody3D,from: Vector3,to: Vector3,axis: Vector3) -> bool:
	_coping_body_query.shape=_collision.shape
	_coping_body_query.transform=Transform3D(Basis(Quaternion(Vector3.UP,axis)),from+axis*_half_height)
	_coping_body_query.motion=Vector3.ZERO
	_coping_body_query.collision_mask=body.collision_mask
	_coping_body_query.exclude=[body.get_rid()]
	_coping_body_query.margin=0.001
	var space:=body.get_world_3d().direct_space_state
	if not space.intersect_shape(_coping_body_query,1).is_empty(): return false
	_coping_body_query.motion=to-from
	var sweep:=space.cast_motion(_coping_body_query)
	if sweep.size()!=2 or sweep[0]<0.9999: return false
	_coping_body_query.motion=Vector3.ZERO
	_coping_body_query.transform.origin=to+axis*_half_height
	return space.intersect_shape(_coping_body_query,1).is_empty()

## The union of enlarged native endpoint capsules encloses the continuous
## turn. Dimensions carry the enclosure; this does not rely on query margin.
func _coping_turn_clear(body: CharacterBody3D,at: Vector3,from: Vector3,to: Vector3) -> bool:
	_coping_turn_queries=0
	var capsule: CapsuleShape3D=_collision.shape as CapsuleShape3D
	if capsule==null or _coping_body_query.shape==null or not at.is_finite() or not from.is_finite() or not to.is_finite() \
			or absf(from.length_squared()-1.0)>0.00001 or absf(to.length_squared()-1.0)>0.00001: return false
	var angle:=from.angle_to(to)
	if not is_finite(angle) or from.dot(to)<-0.999999: return false
	var intervals:=0 if angle<=0.000001 else ceili(angle/deg_to_rad(1.0))
	if intervals<0 or intervals>180: return false
	var r:=capsule.radius
	var outer:=capsule.height-r
	var half_interval:=angle/float(maxi(intervals,1))*0.5
	# An arc-point ball lies in one of these two enlarged endpoint balls.
	# The outer head on the angle bisector gives the largest required radius.
	var enlargement:=sqrt(r*r+2.0*outer*(outer+r)*(1.0-cos(half_interval)))-r
	if intervals>0: enlargement+=0.000001
	_coping_turn_shape.radius=r+enlargement
	_coping_turn_shape.height=capsule.height+2.0*enlargement
	_coping_turn_shape.margin=capsule.margin
	var previous_shape: Shape3D=_coping_body_query.shape
	var previous_transform: Transform3D=_coping_body_query.transform
	var previous_motion: Vector3=_coping_body_query.motion
	var previous_margin: float=_coping_body_query.margin
	var previous_mask: int=_coping_body_query.collision_mask
	var previous_exclude: Array[RID]=_coping_body_query.exclude
	_coping_body_query.shape=_coping_turn_shape
	_coping_body_query.motion=Vector3.ZERO
	_coping_body_query.margin=0.001
	_coping_body_query.collision_mask=body.collision_mask
	_coping_body_query.exclude=[body.get_rid()]
	var space: PhysicsDirectSpaceState3D=body.get_world_3d().direct_space_state
	var clear:=true
	for index: int in range(intervals+1):
		var progress:=float(index)/intervals if intervals>0 else 0.0
		var axis:=from.slerp(to,progress).normalized()
		# Keep the ORIGINAL centre: radius/height grow equally at each end,
		# leaving both underlying spine endpoints fixed in the real body frame.
		_coping_body_query.transform=Transform3D(Basis(Quaternion(Vector3.UP,axis)),at+axis*_half_height)
		_coping_turn_queries+=1
		if not space.intersect_shape(_coping_body_query,1).is_empty(): clear=false;break
	_coping_body_query.shape=previous_shape
	_coping_body_query.transform=previous_transform
	_coping_body_query.motion=previous_motion
	_coping_body_query.margin=previous_margin
	_coping_body_query.collision_mask=previous_mask
	_coping_body_query.exclude=previous_exclude
	return clear


func _real_lip_contact(body: CharacterBody3D, frame: Dictionary) -> bool:
	var point: Vector3 = frame.point
	var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.03,point-Vector3.UP*0.03,2)
	query.exclude = [body.get_rid()]
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider is Node and hit.collider.get_meta("coping_feature",null)==feature \
		and hit.normal.y>0.95 and hit.position.distance_to(point)<0.008

func _launch(body: CharacterBody3D, velocity: Vector3, event: String) -> Dictionary:
	state = "air"
	lip = false
	air_feature = feature
	_air_velocity = velocity
	_air_age = 0.0
	_air_push_armed = _last_push < 0.2
	_air_brake_armed = _last_brake < 0.2
	_transfer_direction = 0.0
	_applied_transfer_direction = 0.0
	body.velocity = velocity
	return _result(body, event)

## Read-only upright-capsule clearance for a prospective air-to-grind capture.
## Only reset after GrindRide.start and the player's spin checks both succeed.
## Failed rail admission must leave this associated contact frame untouched.
func grind_path_clear(from: Vector3, to: Vector3, body: CharacterBody3D) -> bool:
	if not active or state != "air" or not from.is_finite() or not to.is_finite():
		return false
	if not _can_occupy(body, from, Vector3.UP) or not _can_occupy(body, to, Vector3.UP):
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collision.shape
	query.transform = Transform3D(Basis.IDENTITY, from + Vector3.UP * _half_height)
	query.motion = to - from
	query.collision_mask = body.collision_mask
	query.exclude = [body.get_rid()]
	query.margin = 0.001
	var fractions := body.get_world_3d().direct_space_state.cast_motion(query)
	return fractions.size() == 2 and fractions[0] >= 0.9999

func _end(body: CharacterBody3D, event: String) -> Dictionary:
	var velocity := body.velocity
	reset(body)
	# The caller still owns ordinary air. Preserve only its pending contact
	# provenance until native floor completion or the next acquired feature.
	_air_contact_pending=event=="exit_air"
	body.velocity = velocity
	return _result(body, event)

## Native feature-owned steel supplies only this finite clearance profile.
## Ordinary movement still sees every solid, including this exact primitive.
func _coping_profile(body: CharacterBody3D,candidate: Node3D,sample: Dictionary) -> Dictionary:
	var frame: Dictionary=candidate.lip_frame(float(sample.x))
	var crown: Vector3=frame.point
	if Vector3(sample.point).distance_squared_to(crown)>0.35*0.35: return {}
	_coping_ray.from=crown+Vector3.UP*0.03
	_coping_ray.to=crown-Vector3.UP*0.03
	_coping_ray.collision_mask=2
	_coping_ray.exclude=[body.get_rid()]
	var hit:=body.get_world_3d().direct_space_state.intersect_ray(_coping_ray)
	if hit.is_empty() or not hit.collider is StaticBody3D \
			or not hit.collider.has_meta("coping_feature") or hit.collider.get_meta("coping_feature")!=candidate \
			or Vector3(hit.normal).y<0.95 or Vector3(hit.position).distance_to(crown)>0.008: return {}
	var steel:=hit.collider as StaticBody3D
	var primitive:=steel.shape_owner_get_owner(steel.shape_find_owner(int(hit.shape))) as CollisionShape3D
	if primitive==null or primitive.disabled: return {}
	var transform: Transform3D=primitive.global_transform
	if not transform.basis.get_scale().is_equal_approx(Vector3.ONE): return {}
	var axis: Vector3=sample.normal
	var support: float=(transform.origin-Vector3(sample.point)).dot(axis)
	if primitive.shape is BoxShape3D:
		var half: Vector3=primitive.shape.size*0.5
		support+=absf(axis.dot(transform.basis.x))*half.x+absf(axis.dot(transform.basis.y))*half.y+absf(axis.dot(transform.basis.z))*half.z
	elif primitive.shape is CylinderShape3D:
		var along:=axis.dot(transform.basis.y)
		support+=absf(along)*primitive.shape.height*0.5+sqrt(maxf(0.0,1.0-along*along))*primitive.shape.radius
	elif candidate.wrap_lateral and primitive.shape is ConcavePolygonShape3D:
		var section:=_coping_torus_section(primitive.shape)
		if section.is_empty(): return {}
		var local_point:=transform.affine_inverse()*Vector3(sample.point)
		var radial:=Vector3(local_point.x,0.0,local_point.z).normalized()
		if radial.length_squared()<0.5: return {}
		var centre: Vector3=radial*float(section.major)+Vector3.UP*float(section.centre_y)
		var local_axis:=transform.basis.transposed()*axis
		support=(centre-local_point).dot(local_axis)+float(section.minor)
	else: return {}
	if not is_finite(support) or support<0.0 or support>0.1: return {}
	return {"body":steel,"offset":support,"crown":crown}

## Validate every native torus vertex once and cache only its section radii.
## The enclosing section proposes a target; native capsule queries remain final.
func _coping_torus_section(shape: ConcavePolygonShape3D) -> Dictionary:
	var identity:=shape.get_instance_id()
	if _coping_sections.has(identity): return _coping_sections[identity]
	var faces:=shape.get_faces()
	if faces.is_empty(): return {}
	var radial_min:=INF
	var radial_max:=-INF
	var lower:=INF
	var upper:=-INF
	for point: Vector3 in faces:
		if not point.is_finite(): return {}
		var rho:=Vector2(point.x,point.z).length()
		radial_min=minf(radial_min,rho);radial_max=maxf(radial_max,rho)
		lower=minf(lower,point.y);upper=maxf(upper,point.y)
	var major:=(radial_min+radial_max)*0.5
	var minor:=(upper-lower)*0.5
	var centre_y:=(upper+lower)*0.5
	if minor<=0.0 or minor>0.1 or major<=minor \
			or absf((radial_max-radial_min)*0.5-minor)>0.0001: return {}
	for point: Vector3 in faces:
		var section:=Vector2(Vector2(point.x,point.z).length()-major,point.y-centre_y).length()
		if absf(section-minor)>0.0001: return {}
	var result:={"major":major,"minor":minor,"centre_y":centre_y}
	_coping_sections[identity]=result
	var invalidate:=_forget_coping_section.bind(identity)
	if not shape.changed.is_connected(invalidate): shape.changed.connect(invalidate)
	return result

func _forget_coping_section(identity: int) -> void:
	_coping_sections.erase(identity)

func _surface_body_target(body: CharacterBody3D,candidate: Node3D,sample: Dictionary) -> Vector3:
	# The capsule can clear steel while the leading tyre still reaches it.
	# Keep the native coping profile authoritative before the nominal target.
	var offset:=CONTACT_OFFSET
	var coping:=_coping_profile(body,candidate,sample)
	if not coping.is_empty(): offset=maxf(offset,float(coping.offset)+0.002)
	var target: Vector3=sample.point+sample.normal*offset
	return target if _can_occupy(body,target,sample.normal) else Vector3.INF

func _move_supported(body: CharacterBody3D, sample: Dictionary, allow_ground: bool = false) -> bool:
	var physical_contact := _real_face_contact(body, feature, sample)
	if allow_ground:
		physical_contact = physical_contact or _real_ground_contact(body, sample.point)
	if not physical_contact: return false
	var target:=_surface_body_target(body,feature,sample)
	if not target.is_finite(): return false
	_orient_collision(body, sample.normal)
	var hit := body.move_and_collide(target - body.global_position, false, 0.001)
	if hit and hit.get_collider() != feature.surface_body:
		return false
	var error := body.global_position.distance_to(target)
	max_support_error = maxf(max_support_error, error)
	if error > 0.045:
		return false
	normal = sample.normal
	forward = _travel_direction(sample)
	body.up_direction = normal
	return true

func _travel_direction(sample: Dictionary) -> Vector3:
	var direction: Vector3 = sample.tangent * _speed + sample.lateral * _lateral_speed
	return direction.normalized() if direction.length_squared() > 0.001 else sample.tangent

func _real_face_contact(body: CharacterBody3D, candidate: Node3D, sample: Dictionary) -> bool:
	if not is_instance_valid(candidate.surface_body):
		return false
	var physical_sample: Dictionary = sample
	# Coincident floor/toe and deck/lip edges can win the same native ray.
	# Probe 0.01rad inside the real finite face (at most5cm from either
	# endpoint); collider identity must never depend on broad-phase order.
	var probe_theta := clampf(float(sample.theta), 0.01, PI * 0.5 - 0.01)
	if probe_theta != float(sample.theta):
		physical_sample = candidate.sample(probe_theta, float(sample.x))
	var point: Vector3 = physical_sample.point
	var axis: Vector3 = physical_sample.normal
	var query := PhysicsRayQueryParameters3D.create(point + axis * 0.10, point - axis * 0.08, body.collision_mask)
	query.exclude = [body.get_rid()]
	var coping:=_coping_profile(body,candidate,physical_sample)
	if not coping.is_empty(): query.exclude=[body.get_rid(),coping.body.get_rid()]
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == candidate.surface_body \
		and Vector3(hit.normal).dot(axis) > 0.93

func _real_ground_contact(body: CharacterBody3D, point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.10, point - Vector3.UP * 0.08, body.collision_mask)
	query.exclude = [body.get_rid()]
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and Vector3(hit.normal).dot(Vector3.UP) > 0.93 \
		and Vector3(hit.position).distance_to(point) < 0.04

func _cache_collision(body: CharacterBody3D) -> void:
	var collision := body.get_node_or_null("BodyCollision") as CollisionShape3D
	if collision != _collision:
		_collision = collision
		_has_rest = false
	if is_instance_valid(_collision) and not _has_rest:
		_collision_rest = _collision.transform
		_has_rest = true
		_half_height = float(_collision.shape.height) * 0.5 if _collision.shape is CapsuleShape3D else 0.85

	if is_instance_valid(_collision) and _coping_body_query.shape==null:
		_coping_body_query.shape=_collision.shape

func _orient_collision(body: CharacterBody3D, axis: Vector3) -> void:
	if not is_instance_valid(_collision):
		return
	var transform := Transform3D(Basis(Quaternion(Vector3.UP, axis.normalized())), body.global_position + axis * _half_height)
	_collision.transform = body.global_transform.affine_inverse() * transform

func _can_occupy(body: CharacterBody3D, origin: Vector3, axis: Vector3) -> bool:
	_cache_collision(body)
	if not is_instance_valid(_collision):
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collision.shape
	query.transform = Transform3D(Basis(Quaternion(Vector3.UP, axis.normalized())), origin + axis * _half_height)
	query.collision_mask = body.collision_mask
	query.exclude = [body.get_rid()]
	query.margin = 0.001
	return body.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _result(body: CharacterBody3D, event: String) -> Dictionary:
	return {"active": active, "state": state, "event": event, "velocity": body.velocity,
		"normal": normal, "forward": forward, "surface_pitch": asin(clampf(forward.y, -1.0, 1.0)),
		"lip": lip, "lip_balance": lip_balance}
