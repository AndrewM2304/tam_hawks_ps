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
	for degrees in [54.0, 56.0]:
		var approach := Vector3(sin(deg_to_rad(degrees)), 0, -cos(deg_to_rad(degrees))) * 8.0
		check.call(Ride.new().start([rail], Vector3(0, 0.1, -5), approach) == (degrees < 55.0),
			"grind ride: approach angle gate distinguishes either side of 55 degrees")

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
		[Vector3(0.66, 0, -5), Vector3(0, 0, -6), "full snap distance"],
		[Vector3(0, 0.46, -5), Vector3(0, 0, -6), "vertical reach"],
		[Vector3(0, -0.11, -5), Vector3(0, 0, -6), "below the rail"],
		[Vector3(0, 0.1, -5), Vector3(0, 1.01, -6), "rising ascent"],
		[Vector3(0, 0.1, -5), Vector3(6, 0, -1), "sideways approach"],
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


static func _rail(id: String, start: Vector3, end: Vector3) -> RefCounted:
	return Line.new(id, PackedVector3Array([start, end]))
