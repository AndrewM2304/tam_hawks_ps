extends RefCounted
## Actual model unweight/turn/reseat. Input, rail movement, cancellation, scoring
## and committing the target style remain controller responsibilities.
const Style = preload("res://game/tricks/grind_style.gd")
const DURATION := 0.27
const LEG_SECONDS := DURATION / 3.0
const MAX_ANGULAR_SPEED := 15.0
const LIFTS := [0.10,0.16,0.22,0.28]
var active := false
var board_transform := Transform3D.IDENTITY
var lift := 0.0
var last_rejection := ""
var phase: String:
	get: return ["lift","rotate","reseat"][_leg] if active else "idle"
var duration: float:
	get: return LEG_SECONDS*2.0+_rotate_seconds
var _leg := 0
var _elapsed := 0.0
var _relative_from := Transform3D.IDENTITY
var _previous_target := Vector3.ZERO
var _rotate_seconds := LEG_SECONDS


func begin(from: Transform3D, target: Style.ContactPose, up: Vector3, clearance: RefCounted) -> bool:
	if active: return false
	last_rejection = "invalid_request"
	if not _valid(target,up,clearance) or not from.is_finite() \
			or from.origin.distance_to(target.board_transform.origin)>0.85: return false
	if not clearance.allows_frame_path(from,from,up):
		last_rejection = "start_obstruction"
		return false
	if not clearance.allows(target,up):
		last_rejection = "target_obstruction"
		return false
	var normal := up.normalized()
	var selected := 0.0
	for height: float in LIFTS:
		var first := from
		first.origin += normal*height
		var last := target.board_transform
		last.origin += normal*height
		if clearance.allows_frame_path(from,first,up) \
			and clearance.allows_frame_path(first,last,up) \
			and clearance.allows_frame_path(last,target.board_transform,up):
			selected = height
			break
	if selected==0.0:
		last_rejection = "no_clear_unweight_path"
		return false
	_relative_from = target.board_transform.affine_inverse()*from
	var angle := from.basis.get_rotation_quaternion().angle_to(target.board_transform.basis.get_rotation_quaternion())
	# smoothstep's peak derivative is1.5; cap the actual authored turn rate,
	# rather than packing a180-degree whole-rider turn into the minimum leg.
	_rotate_seconds = maxf(LEG_SECONDS,1.5*angle/MAX_ANGULAR_SPEED)
	_previous_target = target.board_transform.origin
	board_transform = from
	lift = selected
	_leg = 0
	_elapsed = 0.0
	active = true
	last_rejection = ""
	return true


func step(delta: float, current_target: Style.ContactPose, up: Vector3, clearance: RefCounted) -> Dictionary:
	if not active: return _result(false,false)
	if not is_finite(delta) or delta<0.0 or not _valid(current_target,up,clearance):
		return _fail("invalid_tick")
	if delta==0.0: return _result(false,false)
	if current_target.board_transform.origin.distance_to(_previous_target)>1.0:
		return _fail("target_discontinuity")
	# At most one leg ends in a call, even after a long frame. A rendered frame
	# must not shortcut a complete lift/rotation/reseat into a direct crossing.
	var leg_seconds := _rotate_seconds if _leg==1 else LEG_SECONDS
	_elapsed = minf(leg_seconds,_elapsed+delta)
	var target := current_target.board_transform
	var first := target*_relative_from
	var raised_first := first
	var raised_target := target
	raised_first.origin += up.normalized()*lift
	raised_target.origin += up.normalized()*lift
	var weight := smoothstep(0.0,1.0,_elapsed/leg_seconds)
	var next: Transform3D
	match _leg:
		0: next=first.interpolate_with(raised_first,weight)
		1: next=raised_first.interpolate_with(raised_target,weight)
		_: next=raised_target.interpolate_with(target,weight)
	if _elapsed>=leg_seconds:
		next = raised_first if _leg==0 else (raised_target if _leg==1 else target)
	if not clearance.allows_frame_path(board_transform,next,up):
		return _fail("moving_path_obstruction")
	board_transform = next
	_previous_target = target.origin
	if _elapsed>=leg_seconds:
		_elapsed = 0.0
		_leg += 1
		if _leg==3:
			active = false
			return _result(true,false)
	return _result(false,false)


## Read the returned last safe frame BEFORE ordinary air/bail release posing.
func cancel() -> Transform3D:
	active = false
	_leg = 0
	_elapsed = 0.0
	return board_transform


func reset() -> void:
	cancel()
	board_transform = Transform3D.IDENTITY
	_relative_from = Transform3D.IDENTITY
	lift = 0.0
	_rotate_seconds = LEG_SECONDS
	last_rejection = ""


func _fail(reason: String) -> Dictionary:
	active = false
	last_rejection = reason
	return _result(false,true)


func _result(complete: bool, failed: bool) -> Dictionary:
	return {"active":active,"complete":complete,"failed":failed,
		"poseTransform":board_transform,"phase":"complete" if complete else ("failed" if failed else phase),
		"reason":last_rejection}


static func _valid(target: Style.ContactPose, up: Vector3, clearance: RefCounted) -> bool:
	return target!=null and target.valid and target.anchor_count>0 \
		and target.max_error<=Style.CONTACT_TOLERANCE and target.board_transform.is_finite() \
		and up.is_finite() and up.length_squared()>0.5 and clearance!=null \
		and clearance.has_method("allows_frame_path") and clearance.get("ready")==true
