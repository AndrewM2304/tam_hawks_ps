extends RefCounted
## Broad-phase equivalence across negative cells, long segments and completed
## swept captures. Admission itself remains owned by GrindRide.
const Line = preload("res://game/tricks/grind_line.gd")
const Ride = preload("res://game/tricks/grind_ride.gd")
const Index = preload("res://game/tricks/grind_index.gd")

static func run(check: Callable) -> void:
	var lines: Array = []
	for i in range(160):
		lines.append(Line.new("line_" + str(i), PackedVector3Array([
			Vector3(i * 12 - 960, 2, -40), Vector3(i * 12 - 960, 2, 40)])))
	var index := Index.new()
	index.rebuild(lines)
	for x: float in [-960.0, -948.0, -12.0, 0.0, 12.0, 948.0]:
		for side: float in [-0.8, 0.8]:
			var at := Vector3(x + side, 2.12, -8.01)
			var all := Ride.new()
			var nearby := Ride.new()
			var full_capture := all.start(lines, at, Vector3(0, -2, 8))
			var indexed_capture := nearby.start(index.nearby(at), at, Vector3(0, -2, 8))
			check.call(full_capture and indexed_capture and all.line == nearby.line,
				"rail index: exact candidate preserved across signed cell boundary " + str(at))
			check.call(index.nearby(at).size() <= 2,
				"rail index: local request excludes distant curves from 160-line world")
	var at := Vector3(-0.8, 2.66, -8.01)
	var velocity := Vector3(0, -54, 12)
	var to := at + velocity / 60.0
	var full := Ride.new()
	var indexed := Ride.new()
	var expected_line: RefCounted = lines[80] # The original guide at world X=0/Y=2.
	var old_nearest: Dictionary = expected_line.closest(at)
	check.call(not old_nearest.is_empty() and float(old_nearest.gap) > 0.99
		and index.nearby(to).has(expected_line)
		and not full.start_swept(lines, at, to, velocity)
		and not indexed.start_swept(index.nearby(to), at, to, velocity)
		and not full.active and not indexed.active,
		"rail index: historical oversized correction is refused by full and indexed sweeps despite candidate availability")
	# Preserve the older below-band tuple across a negative Z cell. Even when
	# correction budgets fit, a historical sample cannot waive present height.
	at = Vector3(-0.65, 2.66, -8.01)
	to = at + velocity / 60.0
	var local: Array = index.nearby(to)
	check.call(index._key(at).x < 0 and index._key(to).x < 0
		and index._key(at).z < 0 and index._key(to).z < 0
		and index._key(at).z != index._key(to).z and local.has(expected_line),
		"rail index: bounded missed window retains its real guide across negative cell boundaries")
	check.call(not Ride.new().start(lines, at, velocity)
		and not Ride.new().start(lines, to, velocity)
		and not Ride.new().start(index.nearby(at), at, velocity)
		and not Ride.new().start(local, to, velocity),
		"rail index: both actual point endpoints refuse the bounded descending window with full and indexed candidates")
	full = Ride.new()
	indexed = Ride.new()
	check.call(not full.start_swept(lines, at, to, velocity)
		and not indexed.start_swept(local, at, to, velocity)
		and not full.active and not indexed.active,
		"rail index: full and indexed sweeps both reject the retained .66m to -.24m present-height overshoot")
	var target: Vector3 = expected_line.point_at(float(expected_line.closest(to).dist))
	check.call(to.distance_to(target) <= 0.85 and at.distance_to(target) <= 0.99,
		"rail index: below-band overshoot rejection remains necessary even when both independent displacement budgets fit")
	velocity = Vector3(0, -45.6, 12)
	to = at + velocity / 60.0
	local = index.nearby(to)
	check.call(full.start_swept(lines, at, to, velocity)
		and indexed.start_swept(local, at, to, velocity)
		and full.line == expected_line and indexed.line == expected_line
		and full.position().distance_to(indexed.position()) < 0.00001,
		"rail index: .66m to -.10m captures the same actual guide and point through full and indexed sweeps")
	check.call(full.active and indexed.active
		and to.distance_to(full.position()) <= 0.85 and at.distance_to(full.position()) <= 0.99
		and to.distance_to(indexed.position()) <= 0.85 and at.distance_to(indexed.position()) <= 0.99,
		"rail index: both recovered captures satisfy independent current .85m and prior-native-sample .99m budgets")
	var loop := Line.new("fountain_loop", PackedVector3Array([
		Vector3(0, 1, 0), Vector3(0, 1, -8), Vector3(8, 1, -8),
		Vector3(8, 1, 0), Vector3(0, 1, 0)]), "coping")
	for direction: float in [-1.0, 1.0]:
		var ride := Ride.new()
		var progress := 0.1 if direction < 0.0 else loop.length - 0.1
		var start := loop.point_at(progress) + Vector3.UP * 0.1
		check.call(ride.start([loop], start, loop.dir_at(progress) * direction * 8.0)
			and ride.step(0.1, 0.0) == "riding" and ride.active
			and ride.position().distance_to(loop.points[0]) < 1.0,
			"closed coping: crosses authored seam continuously in direction " + str(direction))
	index.rebuild([])
	check.call(index.nearby(Vector3.ZERO).is_empty() and index.nearby(Vector3(INF, 0, 0)).is_empty(),
		"rail index: replaced lists and nonfinite positions cannot reuse stale tracks")
