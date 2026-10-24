extends RefCounted

const Meter = preload("res://game/tricks/special_meter.gd")
const Tracker = preload("res://game/tricks/gap_tracker.gd")


static func run(check: Callable) -> void:
	var meter = Meter.new()
	check.call(meter.value == 0.0 and not meter.consume(), "special meter: empty meter cannot spend a special")
	meter.earn_trick(250)
	check.call(is_equal_approx(meter.value, 25.0), "special meter: earned live trick points charge one unit per ten points")
	meter.earn_trick(0)
	meter.earn_trick(-100)
	check.call(meter.value == 25.0, "special meter: zero or negative awards earn nothing")
	meter.earn_trick(9223372036854775807)
	check.call(meter.value == 75.0 and not meter.consume(), "special meter: an event earns at most 50 and cannot authorize a partial charge")
	meter.earn_trick(1250)
	check.call(meter.value == 100.0 and meter.consume() and meter.value == 100.0
		and meter.consume(), "special meter: full charge activates sustained special admission without consuming the mode")
	meter.tick(1.0, false)
	check.call(is_equal_approx(meter.value, 100.0 - 100.0 / 6.0) and meter.ready(),
		"special meter: active mode drains over time while retaining special admission")
	meter.earn_trick(1250)
	meter.reset()
	check.call(meter.value == 0.0, "special meter: run reset clears charge")
	meter.value = NAN
	check.call(not meter.consume() and meter.value == 0.0, "special meter: nonfinite state cannot unlock a special")
	meter.value = -20.0
	meter.earn_trick(25)
	check.call(meter.value == 2.5, "special meter: public meter state is bounded before earning")

	var ordered = _tracker()
	check.call(ordered.update(Vector3(-2, 0, 0), false, 0.0).is_empty(),
		"gap tracker: first sample only primes the route")
	check.call(ordered.update(Vector3(0, 0, 0), true, 0.1).is_empty(),
		"gap tracker: crossing start alone does not award")
	ordered.update(Vector3(3, 0, 0), true, 0.2)
	var awards: Array[Dictionary] = ordered.update(Vector3(6, 0, 0), true, 0.2)
	check.call(awards.size() == 1 and awards[0] == {"id": "central_gap", "name": "Central Gap", "points": 500},
		"gap tracker: ordered forward airborne traversal produces the defined reward")
	check.call(ordered.update(Vector3(6.1, 0, 0), true, 0.1).is_empty()
		and ordered.update(Vector3(5.9, 0, 0), true, 0.1).is_empty(),
		"gap tracker: staying in the finish trigger cannot duplicate rewards")
	ordered.update(Vector3(8, 0, 0), true, 0.1)
	ordered.update(Vector3(-2, 0, 0), true, 0.5)
	ordered.update(Vector3(0, 0, 0), true, 0.1)
	check.call(ordered.update(Vector3(6, 0, 0), true, 0.3).size() == 1,
		"gap tracker: leaving both triggers allows a new forward traversal")

	var reverse = _tracker()
	reverse.update(Vector3(8, 0, 0), true, 0.0)
	check.call(reverse.update(Vector3(-2, 0, 0), true, 0.5).is_empty(),
		"gap tracker: reverse crossing of both triggers does not award")
	var backtrack = _tracker()
	backtrack.update(Vector3(-2, 0, 0), true, 0.0)
	backtrack.update(Vector3(1, 0, 0), true, 0.1)
	backtrack.update(Vector3(-1, 0, 0), true, 0.1)
	check.call(backtrack.update(Vector3(6, 0, 0), true, 0.2).is_empty(),
		"gap tracker: reversing an armed traversal invalidates that attempt")
	var teleport = _tracker()
	teleport.update(Vector3(-2, 0, 0), true, 0.0)
	teleport.update(Vector3(0, 0, 0), true, 0.1)
	check.call(teleport.update(Vector3(25, 0, 0), true, 0.1).is_empty(),
		"gap tracker: teleporting over a finish cannot claim the route")
	var reset = _tracker()
	reset.update(Vector3(-2, 0, 0), true, 0.0)
	reset.update(Vector3(0, 0, 0), true, 0.1)
	reset.reset()
	check.call(reset.update(Vector3(6, 0, 0), true, 0.1).is_empty(),
		"gap tracker: bail or restart reset removes armed progress")
	var expired = _tracker()
	expired.update(Vector3(-2, 0, 0), true, 0.0)
	expired.update(Vector3(0, 0, 0), true, 0.1)
	expired.update(Vector3(3, 0, 0), true, 4.1)
	check.call(expired.update(Vector3(6, 0, 0), true, 0.1).is_empty(),
		"gap tracker: an expired four-second attempt cannot finish later")
	var grounded = _tracker()
	grounded.update(Vector3(-2, 0, 0), false, 0.0)
	check.call(grounded.update(Vector3(8, 0, 0), false, 0.5).is_empty(),
		"gap tracker: a required aerial gap cannot be rolled along the ground")
	var landed = _tracker()
	landed.update(Vector3(-2, 0, 0), true, 0.0)
	landed.update(Vector3(2, 0, 0), true, 0.2)
	check.call(landed.update(Vector3(6, 0, 0), false, 0.2).is_empty(),
		"gap tracker: air earlier in the route is insufficient when grounded at the finish")
	var finish_only_air = _tracker()
	finish_only_air.update(Vector3(-2, 0, 0), false, 0.0)
	finish_only_air.update(Vector3(0, 0, 0), false, 0.1)
	finish_only_air.update(Vector3(3, 0, 0), false, 0.1)
	check.call(finish_only_air.update(Vector3(6, 0, 0), true, 0.1).is_empty(),
		"gap tracker: becoming airborne only at the finish does not establish air between triggers")
	var ground_route = _tracker(false)
	ground_route.update(Vector3(-2, 0, 0), false, 0.0)
	check.call(ground_route.update(Vector3(8, 0, 0), false, 0.5).size() == 1,
		"gap tracker: an explicitly ground-optional route accepts ground travel")
	var fast = _tracker()
	fast.update(Vector3(-2, 0, 0), true, 0.0)
	check.call(fast.update(Vector3(8, 0, 0), true, 0.1).size() == 1,
		"gap tracker: swept segments detect both ordered triggers without endpoint samples inside")
	var near_miss = _tracker()
	near_miss.update(Vector3(-2, 0, 1.01), true, 0.0)
	check.call(near_miss.update(Vector3(8, 0, 1.01), true, 0.2).is_empty(),
		"gap tracker: a segment passing outside the trigger radius does not award")

	var duplicate = Tracker.new()
	duplicate.configure([_definition(), _definition()])
	duplicate.update(Vector3(-2, 0, 0), true, 0.0)
	check.call(duplicate.update(Vector3(8, 0, 0), true, 0.2).size() == 1,
		"gap tracker: duplicate definition IDs cannot double-award")
	var overlap_definition: Dictionary = _definition()
	overlap_definition.end = Vector3(1, 0, 0)
	var overlap = Tracker.new()
	overlap.configure([overlap_definition])
	overlap.update(Vector3(-2, 0, 0), true, 0.0)
	check.call(overlap.update(Vector3(3, 0, 0), true, 0.2).is_empty(),
		"gap tracker: overlapping start and finish spheres are rejected as invalid authoring")
	var second: Dictionary = _definition()
	second.id = "second_gap"
	second.start += Vector3(0, 0, 5)
	second.end += Vector3(0, 0, 5)
	var independent = Tracker.new()
	independent.configure([_definition(), second])
	independent.update(Vector3(-2, 0, 0), true, 0.0)
	var first_awards: Array[Dictionary] = independent.update(Vector3(8, 0, 0), true, 0.2)
	independent.update(Vector3(-2, 0, 5), true, 0.4)
	var second_awards: Array[Dictionary] = independent.update(Vector3(8, 0, 5), true, 0.2)
	check.call(first_awards.size() == 1 and first_awards[0].id == "central_gap"
		and second_awards.size() == 1 and second_awards[0].id == "second_gap",
		"gap tracker: independent definitions preserve their own progress and IDs")
	var edited: Dictionary = _definition()
	var snapshot = Tracker.new()
	snapshot.configure([edited])
	edited.points = 999
	edited.end = Vector3(100, 0, 0)
	snapshot.update(Vector3(-2, 0, 0), true, 0.0)
	var snapshot_awards: Array[Dictionary] = snapshot.update(Vector3(8, 0, 0), true, 0.2)
	check.call(snapshot_awards.size() == 1 and snapshot_awards[0].points == 500,
		"gap tracker: configuration snapshots authoring data")
	var malformed: Array = [null, "gap", {}, _definition()]
	malformed[3].start = Vector3(NAN, 0, 0)
	var bad_radius: Dictionary = _definition()
	bad_radius.radius = INF
	malformed.append(bad_radius)
	var bad_points: Dictionary = _definition()
	bad_points.points = -1
	malformed.append(bad_points)
	var invalid_geometry = Tracker.new()
	invalid_geometry.configure(malformed)
	invalid_geometry.update(Vector3(-2, 0, 0), true, 0.0)
	check.call(invalid_geometry.update(Vector3(8, 0, 0), true, 0.2).is_empty(),
		"gap tracker: malformed and nonfinite authoring entries are ignored")
	for invalid_delta in [-0.1, NAN, INF]:
		var invalid = _tracker()
		invalid.update(Vector3(-2, 0, 0), true, 0.0)
		invalid.update(Vector3(0, 0, 0), true, 0.1)
		check.call(invalid.update(Vector3(6, 0, 0), true, invalid_delta).is_empty()
			and invalid.update(Vector3(6, 0, 0), true, 0.1).is_empty(),
			"gap tracker: invalid update timing cannot bridge a route")
	var bad_position = _tracker()
	bad_position.update(Vector3(0, 0, 0), true, 0.0)
	bad_position.update(Vector3(NAN, 0, 0), true, 0.1)
	check.call(bad_position.update(Vector3(6, 0, 0), true, 0.1).is_empty(),
		"gap tracker: a nonfinite position resets continuous traversal evidence")


static func _tracker(air_required: bool = true) -> RefCounted:
	var tracker = Tracker.new()
	var definition: Dictionary = _definition()
	definition.airborne_required = air_required
	tracker.configure([definition])
	return tracker


static func _definition() -> Dictionary:
	return {"id": "central_gap", "name": "Central Gap", "start": Vector3.ZERO,
		"end": Vector3(6, 0, 0), "radius": 1.0, "points": 500, "airborne_required": true}
