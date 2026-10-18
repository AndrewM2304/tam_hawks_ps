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
	check.call(full.start_swept(lines, at, to, velocity)
		and indexed.start_swept(index.nearby(to), at, to, velocity) and full.line == indexed.line,
		"rail index: historical swept window remains in actual-origin candidate cell")
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
