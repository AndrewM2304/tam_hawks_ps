extends RefCounted
## Pure state checks; player/collision/input integration is checked by the main runner.

const Line = preload("res://game/tricks/grind_line.gd")
const Ride = preload("res://game/tricks/grind_ride.gd")


static func run(check: Callable) -> void:
	var rail = _rail("straight", Vector3.ZERO, Vector3(0, 0, -20))
	var ride = Ride.new()
	check.call(ride.start([rail], Vector3(0.2, 0.1, -5), Vector3(0, 0, -6)),
		"grind ride: an airborne approach within capture bounds attaches")
	check.call(ride.active and ride.direction == 1.0 and is_equal_approx(ride.speed, 6.0)
		and ride.position().distance_to(Vector3(0, 0, -5)) < 0.025,
		"grind ride: entry preserves projected speed and samples the rail")
	check.call(ride.step(0.1, 0.0) == "riding" and ride.distance > 5.5
		and ride.position().z < -5.5 and ride.speed < 6.0,
		"grind ride: forward travel advances distance and loses speed to friction")
	var held_position: Vector3 = ride.position()
	var held_velocity: Vector3 = ride.travel_velocity()
	ride.stop()
	check.call(not ride.active and ride.position() == held_position and ride.travel_velocity() == held_velocity,
		"grind ride: stop retains finite release position and momentum")
	check.call(ride.step(0.2, 0.0) == "slow" and ride.position() == held_position,
		"grind ride: inactive updates do not keep moving the released skater")

	var farther = _rail("far", Vector3(0.4, 0, 0), Vector3(0.4, 0, -20))
	var near = _rail("near", Vector3(0.1, 0, 0), Vector3(0.1, 0, -20))
	var nearest = Ride.new()
	check.call(nearest.start([farther, near], Vector3(0, 0.1, -5), Vector3(0, 0, -6))
		and nearest.line == near, "grind ride: selects nearest eligible rail regardless of list order")
	var obstructed = Ride.new()
	var clear_only_far := func(_from: Vector3, to: Vector3) -> bool: return to.x > 0.2
	check.call(obstructed.start([near, farther], Vector3(0, 0.1, -5), Vector3(0, 0, -6), clear_only_far)
		and obstructed.line == farther, "grind ride: blocked nearest rail falls back to a clear eligible rail")
	var none_clear = Ride.new()
	check.call(not none_clear.start([rail], Vector3(0, 0.1, -5), Vector3(0, 0, -6),
		func(_from: Vector3, _to: Vector3) -> bool: return false),
		"grind ride: obstructed snap is rejected")

	var reverse = Ride.new()
	check.call(reverse.start([rail], Vector3(0, 0.1, -5), Vector3(0, 0, 6))
		and reverse.direction == -1.0, "grind ride: reverse entry keeps its signed travel direction")
	check.call(reverse.step(0.1, 0.0) == "riding" and reverse.distance < 4.5
		and reverse.travel_velocity().z > 0.0, "grind ride: reverse motion decreases distance and keeps momentum")
	for sign_value in [-1.0, 1.0]:
		var edge = Ride.new()
		var at := Vector3(0, 0.05, -0.1 if sign_value < 0 else -19.9)
		check.call(edge.start([rail], at, Vector3(0, 0, -6 * sign_value))
			and edge.step(0.1, 0.0) == "end" and not edge.active,
			"grind ride: crossing an open endpoint releases in direction " + str(sign_value))
		check.call(edge.position().distance_to(Vector3.ZERO if sign_value < 0 else Vector3(0, 0, -20)) < 0.025
			and edge.travel_velocity().z * sign_value < 0.0,
			"grind ride: endpoint clamps without wrapping and preserves outgoing direction")
	check.call(not Ride.new().start([rail], Vector3(0, 0.05, 0.1), Vector3(0, 0, 6))
		and not Ride.new().start([rail], Vector3(0, 0.05, -20.1), Vector3(0, 0, -6)),
		"grind ride: outward approaches beyond either endpoint do not attach")
	check.call(Ride.new().start([rail], Vector3(0, 0.05, 0.1), Vector3(0, 0, -6)),
		"grind ride: an inward approach near an endpoint can attach")
	var curved = Line.new("corner", PackedVector3Array([
		Vector3(4, 2, 8), Vector3(4, 2, 4), Vector3(12, 2, 4),
	]))
	var corner = Ride.new()
	check.call(corner.start([curved], Vector3(4, 2.05, 4.2), Vector3(0, 0, -6))
		and corner.step(0.15, 0.0) == "riding" and corner.position().x > 4.5
		and absf(corner.position().z - 4.0) < 0.025 and corner.travel_velocity().x > 5.0,
		"grind ride: distance follows a translated bent rail and the outgoing tangent turns with it")
	for degrees in [84.0, 86.0]:
		var approach := Vector3(sin(deg_to_rad(degrees)), 0, -cos(deg_to_rad(degrees))) * 8.0
		check.call(Ride.new().start([rail], Vector3(0.5, 0.1, -5), approach) == (degrees < 85.0),
			"grind ride: rough aim accepts84degrees while a distant86degree crossing remains outside its separate near-contact band")
	for offset: Vector3 in [Vector3(0.78,0.1,-5),Vector3(0,0.58,-5),Vector3(0,-0.13,-5)]:
		check.call(Ride.new().start([rail],offset,Vector3(0,-2,-8)),
			"grind ride: deliberate enlarged margin admits a near-edge lateral/vertical approach "+str(offset))
	for direction: float in [-1.0,1.0]:
		var approach := Vector3(sin(deg_to_rad(64.0))*direction,0,-cos(deg_to_rad(64.0)))*8.0
		var level := Ride.new()
		var falling := Ride.new()
		check.call(level.start([rail],Vector3(0,0.1,-5),approach)
			and falling.start([rail],Vector3(0,0.1,-5),approach+Vector3.DOWN*40.0)
			and level.speed >= 7.2 and level.speed <= 8.00001 and is_equal_approx(level.speed,falling.speed),
			"grind ride: angled catch retains at least 90 percent horizontal speed without converting a fall to flat-rail boost")

	var slope = _rail("slope", Vector3.ZERO, Vector3(0, 8, -20))
	var uphill = Ride.new()
	var downhill = Ride.new()
	check.call(uphill.start([slope], Vector3(0, 4.05, -10), Vector3(0, 0, -8))
		and downhill.start([slope], Vector3(0, 4.05, -10), Vector3(0, 0, 8)),
		"grind ride: sloped rails capture both travel directions")
	var up_before: float = uphill.speed
	var down_before: float = downhill.speed
	uphill.step(0.1, 0.0)
	downhill.step(0.1, 0.0)
	check.call(uphill.speed < up_before and downhill.speed > down_before
		and uphill.travel_velocity().y > 0.0 and downhill.travel_velocity().y < 0.0,
		"grind ride: slope gravity changes speed and outgoing velocity retains the vertical tangent")
	var slow = Ride.new()
	slow.start([slope], Vector3(0, 4.05, -10), Vector3(0, 0, -3))
	check.call(slow.step(0.3, 0.0) == "slow" and not slow.active and slow.speed >= 0.0,
		"grind ride: insufficient uphill momentum releases without silently reversing")
	var fast = Ride.new()
	fast.start([slope], Vector3(0, 4.05, -10), Vector3(0, 0, 18))
	fast.step(0.3, 0.0)
	check.call(fast.speed <= 18.0, "grind ride: downhill acceleration respects the speed ceiling")

	var bad_cases := [
		[Vector3(0.86, 0, -5), Vector3(0, 0, -6), "full snap distance"],
		[Vector3(0, 0.61, -5), Vector3(0, 0, -6), "vertical reach"],
		[Vector3(0, -0.15, -5), Vector3(0, 0, -6), "below the rail"],
		[Vector3(0, -0.05, -5), Vector3(0, 1.01, -6), "ascending below the actual rail datum"],
		[Vector3(0.5, 0.1, -5), Vector3(6, 0, 0), "distant sideways approach"],
		[Vector3(0, 0.1, -5), Vector3(0, 0, -1.99), "too little speed"],
		[Vector3(0, 0.1, -5), Vector3(0, 0, -18.01), "excessive speed"],
		[Vector3(INF, 0, -5), Vector3(0, 0, -6), "nonfinite position"],
		[Vector3(0, 0.1, -5), Vector3(0, NAN, -6), "nonfinite velocity"],
	]
	for entry in bad_cases:
		var rejected = Ride.new()
		check.call(not rejected.start([rail], entry[0], entry[1]) and not rejected.active,
			"grind ride: rejects " + entry[2])
	check.call(not Ride.new().start([null, "not a rail", Line.new("empty", PackedVector3Array())],
		Vector3(0, 0.1, -5), Vector3(0, 0, -6)), "grind ride: malformed rail lists cannot attach")
	check.call(not Ride.new().start([_rail("vertical", Vector3.ZERO, Vector3(0, 10, 0))],
		Vector3(0, 5, 0), Vector3(0, 0, -6)), "grind ride: vertical lines have no usable horizontal approach")

	var long_rail = _rail("balance", Vector3.ZERO, Vector3(0, 0, -200))
	var unbalanced = Ride.new()
	var corrected = Ride.new()
	unbalanced.start([long_rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	corrected.start([long_rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	for tick in range(360):
		unbalanced.step(1.0 / 60.0, 0.0)
		corrected.step(1.0 / 60.0, -0.14 - corrected.balance)
	check.call(not unbalanced.active and unbalanced.step(0.0, 0.0) == "bail",
		"grind ride: unattended deterministic balance eventually bails")
	check.call(corrected.active and absf(corrected.balance) < 0.1,
		"grind ride: countersteering controls the balance instead of an unavoidable timeout")
	var bounded = Ride.new()
	var unit_input = Ride.new()
	bounded.start([long_rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	unit_input.start([long_rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	bounded.step(0.1, 1000.0)
	unit_input.step(0.1, 1.0)
	check.call(is_equal_approx(bounded.balance, unit_input.balance),
		"grind ride: analog correction is bounded to the normal input range")
	for invalid_step in [[NAN, 0.0], [INF, 0.0], [-0.1, 0.0], [0.1, NAN]]:
		var invalid = Ride.new()
		invalid.start([rail], Vector3(0, 0.1, -5), Vector3(0, 0, -6))
		check.call(invalid.step(invalid_step[0], invalid_step[1]) == "bail"
			and not invalid.active and invalid.position().is_finite() and invalid.travel_velocity().is_finite(),
			"grind ride: invalid update safely releases without contaminating body transforms")
	_human_error_margin(check, rail)
	_held_intent_capture(check,rail)


static func _human_error_margin(check: Callable, rail: RefCounted) -> void:
	# An offset approach must remain usable across angle, speed and tick phase;
	# these are envelopes for a human playtest, not evidence that it feels good.
	var approaches := [
		[30.0, -0.4, -35.0, 8.0, 22.0, 0.50],
		[60.0, 0.4, 35.0, 12.0, 42.0, 0.50],
		[120.0, -0.5, -25.0, 17.0, 60.0, 0.46],
		[60.0, 0.55, 0.0, 4.0, 28.0, 0.46],
		[120.0, -0.3, 45.0, 10.0, 18.0, 0.46],
		[30.0, 0.0, 0.0, 17.0, 18.0, 0.46],
	]
	for entry in approaches:
		var from := Vector3(entry[1], entry[5], -5.0)
		var radians: float = deg_to_rad(entry[2])
		var velocity := Vector3(sin(radians) * entry[3], -entry[4], -cos(radians) * entry[3])
		var to: Vector3 = from + velocity / entry[0]
		check.call(Ride.new().start_swept([rail], from, to, velocity),
			"grind forgiveness: offset/angle/speed admission survives tick phase " + str(entry))

	# Both endpoints still lie outside the revised .60m above/.14m below
	# envelope; their actual sub-metre segment crosses valid contact in between.
	var from := Vector3(0.35, 0.66, -5.0)
	var velocity := Vector3(0, -54, -12)
	var to: Vector3 = from + velocity / 60.0
	check.call(not Ride.new().start([rail], from, velocity)
		and not Ride.new().start([rail], to, velocity)
		and Ride.new().start_swept([rail], from, to, velocity),
		"grind forgiveness: actual descending travel recovers a window missed at both frame endpoints")

	var queried_origins: Array[Vector3] = []
	var reject_path := func(origin: Vector3, _at: Vector3) -> bool:
		queried_origins.append(origin)
		return false
	check.call(not Ride.new().start_swept([rail], from, to, velocity, reject_path)
		and not queried_origins.is_empty(),
		"grind forgiveness: a blocked actual-body sweep rejects every historical sample")
	var actual_origin_only := true
	for origin in queried_origins:
		actual_origin_only = actual_origin_only and origin.is_equal_approx(to)
	check.call(actual_origin_only,
		"grind forgiveness: clearance always starts at the current body, never a past sample")

	var rejected_approaches := [
		[Vector3(0.95, 0.1, -5), Vector3(0.95, 0.05, -5.2), Vector3(0, -3, -12), "lateral miss"],
		[Vector3(0, 0.9, -5), Vector3(0, 0.7, -5.2), Vector3(0, -12, -12), "wrong upper level"],
		[Vector3(0, -0.3, -5), Vector3(0, -0.5, -5.2), Vector3(0, -12, -12), "below rail"],
		[Vector3(0.4, 0.3, -5), Vector3(0.4, 0.1, -5), Vector3(8, -12, 0), "distant perpendicular motion"],
		[Vector3(0, 0.1, 0.1), Vector3(0, 0.05, 0.3), Vector3(0, -3, 12), "rail behind travel"],
		[Vector3(0, -0.1, -5), Vector3(0, -0.01, -5.2), Vector3(0, 6, -12), "rising below support"],
		[Vector3(0, 0.3, -5), Vector3(0, 0.1, -5.02), Vector3(0, -12, -1), "insufficient forward speed"],
		[Vector3(0, 0.3, -5), Vector3(0, 0.1, -5.32), Vector3(0, -12, -19), "excessive forward speed"],
		[Vector3(0, 1, -5), Vector3(0, -1, -5.2), Vector3(0, -120, -12), "teleport-sized sweep"],
		[Vector3(INF, 0.3, -5), Vector3(0, 0.1, -5.2), Vector3(0, -12, -12), "nonfinite history"],
	]
	for entry in rejected_approaches:
		check.call(not Ride.new().start_swept([rail], entry[0], entry[1], entry[2]),
			"grind forgiveness: no larger admission envelope for " + entry[3])

	var riding = Ride.new()
	riding.start([rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	var held_distance: float = riding.distance
	check.call(not riding.start_swept([rail], from, to, velocity)
		and is_equal_approx(riding.distance, held_distance),
		"grind forgiveness: a second sweep cannot restart an active rail or duplicate its admission")


static func _held_intent_capture(check: Callable, rail: RefCounted) -> void:
	for ascent: float in [1.01,4.0,9.0]:
		var ride := Ride.new()
		check.call(ride.start([rail],Vector3(0.4,0.1,-5),Vector3(0,ascent,-8))
			and ride.position().distance_to(Vector3(0,0,-5))<0.025 and ride.speed==8.0,
			"grind intent: rising Ollie catches above the real datum without converting ascent into flat-rail speed "+str(ascent))
	check.call(not Ride.new().start([rail],Vector3(0,-0.01,-5),Vector3(0,9,-8)),
		"grind intent: ascent below the rail cannot pull a rider through its underside")
	for side: float in [-1.0,1.0]:
		var crossing := Ride.new()
		check.call(crossing.start([rail],Vector3(side*0.15,0.1,-5),Vector3(-side*8,-2,0))
			and crossing.direction==1.0 and crossing.speed>=7.2 and crossing.speed<=8.0,
			"grind intent: close inward perpendicular crossing catches with stable tangent direction from side "+str(side))
		check.call(not Ride.new().start([rail],Vector3(side*0.15,0.1,-5),Vector3(side*8,-2,0))
			and not Ride.new().start([rail],Vector3(side*0.30,0.1,-5),Vector3(-side*8,-2,0)),
			"grind intent: sideways travel away from the rail or outside contact range has no broad magnetic catch "+str(side))
	var endpoint := Ride.new()
	check.call(endpoint.start([rail],Vector3(0.1,0.1,-19.9),Vector3(-8,-2,0)) and endpoint.direction==-1.0,
		"grind intent: perpendicular catch near an open end chooses the finite inward run")
	var blocked := Ride.new()
	check.call(not blocked.start([rail],Vector3(0.1,0.1,-5),Vector3(-8,4,0),
		func(_from: Vector3,_to: Vector3)->bool:return false)
		and not Ride.new().start([rail],Vector3(0.1,0.1,-5),Vector3(-8,4,0),Callable(),
		func(_line,_offset:float,_direction:float)->bool:return false),
		"grind intent: rising and sideways forgiveness never bypass actual path or support rejection")
	var from := Vector3(0.1,-0.1,-5)
	var to := Vector3(0.1,0.1,-5.1)
	var swept := Ride.new()
	check.call(swept.start_swept([rail],from,to,Vector3(0,12,-6))
		and swept.position().distance_to(to)<=Ride.MAX_CAPTURE_CORRECTION
		and swept.position().distance_to(from)<=Ride.MAX_CAPTURE_TICK_DISPLACEMENT,
		"grind intent: an actual upward crossing uses the same present and previous native correction caps")
	check.call(not Ride.new().start([rail],Vector3(0.1,0.7,-5),Vector3(-8,4,0))
		and not Ride.new().start([rail],Vector3(0.1,-0.2,-5),Vector3(-8,-4,0))
		and not Ride.new().start_swept([rail],Vector3(0,2,-5),Vector3(0,0.1,-5),Vector3(0,-114,-8)),
		"grind intent: new intent handling preserves wrong-level, underside and over-metre sweep exclusions")


static func _rail(id: String, start: Vector3, end: Vector3) -> RefCounted:
	return Line.new(id, PackedVector3Array([start, end]))
