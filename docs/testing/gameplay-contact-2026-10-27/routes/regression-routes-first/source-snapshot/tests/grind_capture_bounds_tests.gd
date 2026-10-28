extends RefCounted
## Reproduce actual recorded endpoints; smoothing cannot hide a physical snap.
const Line = preload("res://game/tricks/grind_line.gd")
const Ride = preload("res://game/tricks/grind_ride.gd")

static func run(check: Callable) -> void:
	var yard = Line.new("yard endpoint", PackedVector3Array([
		Vector3(38.3,2.77,124.4),Vector3(50,2.77,124.4)]))
	var previous := Vector3(37.21791,2.844792,124.400116)
	var velocity := Vector3(14.526484,-5.166666,-0.000692)
	var current := previous + velocity / 60.0
	var ordinary = Ride.new()
	check.call(ordinary.start([yard],current,velocity),
		"capture bounds: recorded yard current position is inside the unchanged point envelope")
	var swept = Ride.new()
	check.call(not swept.start_swept([yard],previous,current,velocity) and not swept.active,
		"capture bounds: recorded1.085m previous-sample correction is refused without activating")
	var next := current + Vector3(velocity.x,velocity.y-34.0/60.0,velocity.z)/60.0
	check.call(swept.start_swept([yard],current,next,velocity-Vector3.UP*34.0/60.0)
		and current.distance_to(swept.position()) < 1.0
		and next.distance_to(swept.position()) <= 0.85,
		"capture bounds: next real step catches the same endpoint within both independent budgets")
	var missed = Line.new("missed window",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-20)]))
	var high := Vector3(.35,.66,-5)
	var fall := Vector3(0,-54,-12)
	var low := high+fall/60.0
	var recovery = Ride.new()
	check.call(not Ride.new().start([missed],high,fall) and not Ride.new().start([missed],low,fall)
		and not recovery.start_swept([missed],high,low,fall) and not recovery.active,
		"capture bounds: the retained .66m to -.24m overshoot rejects despite an eligible historical sample")
	fall = Vector3(0,-45.6,-12)
	low = high+fall/60.0
	check.call(recovery.start_swept([missed],high,low,fall)
		and high.distance_to(recovery.position()) < 1.0 and low.distance_to(recovery.position()) <= .85,
		"capture bounds: .66m to -.10m descending recovery retains the current height and both displacement bounds")
	var rejected = Line.new("unsupported contact",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-20)]))
	var supported = Line.new("supported contact",PackedVector3Array([Vector3(.3,0,0),Vector3(.3,0,-20)]))
	var filtered = Ride.new()
	var permit := func(line, _distance: float, _direction: float) -> bool: return line.id == "supported contact"
	check.call(filtered.start([rejected,supported],Vector3(0,.1,-5),Vector3(0,-2,-8),Callable(),permit)
		and filtered.line == supported,
		"capture bounds: unsupported nearest contact continues to a clear eligible candidate")
	check.call(not Ride.new().start_swept([rejected],Vector3(0,.2,-5),Vector3(0,.1,-5.1),Vector3(0,-6,-6),
		Callable(),func(_line,_distance,_direction):return false),
		"capture bounds: swept entry applies the same contact policy without a phantom capture")
