extends RefCounted
## Independent native-Godot checks for the adapted, world-space rail helper.

const GrindLineScript = preload("res://game/tricks/grind_line.gd")
const EPSILON: float = 0.025


static func run(check: Callable) -> void:
	var straight = GrindLineScript.new("Grind_rail_test", PackedVector3Array([
		Vector3(2, 1, 3), Vector3(2, 1, -7),
	]))
	check.call(straight.is_valid and straight.curve is Curve3D,
		"rail geometry: two finite distinct world points form a valid Curve3D line")
	check.call(absf(straight.length - 10.0) < EPSILON,
		"rail geometry: straight line length is measured in world metres")
	check.call(straight.point_at(4.0).distance_to(Vector3(2, 1, -1)) < EPSILON,
		"rail geometry: point sampling preserves nonzero world origin")
	check.call(straight.dir_at(4.0).distance_to(Vector3.FORWARD) < EPSILON,
		"rail geometry: straight tangent is a normalized increasing-distance direction")
	var closest: Dictionary = straight.closest(Vector3(5, 5, -1))
	check.call(_closest_matches(closest, 4.0, Vector3(2, 1, -1), 5.0),
		"rail geometry: closest query reports world point, along-line offset and 3D gap")
	check.call(straight.point_at(-100.0).distance_to(Vector3(2, 1, 3)) < EPSILON,
		"rail geometry: negative point distance clamps to start")
	check.call(straight.point_at(100.0).distance_to(Vector3(2, 1, -7)) < EPSILON,
		"rail geometry: overshooting point distance clamps to end")
	check.call(_closest_matches(straight.closest(Vector3(2, 1, -10)),
		10.0, Vector3(2, 1, -7), 3.0),
		"rail geometry: nearest projection beyond the rail clamps to its endpoint")

	var slope_end := Vector3(3, 4, -12)
	var slope = GrindLineScript.new("Slope", PackedVector3Array([Vector3.ZERO, slope_end]))
	check.call(absf(slope.length - 13.0) < EPSILON,
		"rail geometry: slope length uses all three dimensions")
	check.call(slope.point_at(6.5).distance_to(slope_end * 0.5) < EPSILON,
		"rail geometry: sloped midpoint includes its vertical component")
	check.call(slope.dir_at(6.5).distance_to(slope_end.normalized()) < EPSILON,
		"rail geometry: sloped tangent is normalized in 3D")

	var curved = GrindLineScript.new("Grind_coping_turn", PackedVector3Array([
		Vector3.ZERO, Vector3(0, 0, -4), Vector3(3, 0, -4),
	]))
	check.call(absf(curved.length - 7.0) < EPSILON,
		"rail geometry: multisegment line retains its authored path length")
	check.call(curved.point_at(2.0).distance_to(Vector3(0, 0, -2)) < EPSILON
		and curved.point_at(6.0).distance_to(Vector3(2, 0, -4)) < EPSILON,
		"rail geometry: curved line samples follow both legs instead of the endpoint chord")
	check.call(curved.dir_at(2.0).distance_to(Vector3.FORWARD) < EPSILON
		and curved.dir_at(6.0).distance_to(Vector3.RIGHT) < EPSILON,
		"rail geometry: tangent follows the local segment on a curved path")
	check.call(_closest_matches(curved.closest(Vector3(2, 2, -4)),
		6.0, Vector3(2, 0, -4), 2.0),
		"rail geometry: closest offset follows path distance across a corner")
	check.call(curved.dir_at(-100.0).distance_to(curved.dir_at(0.0)) < EPSILON,
		"rail geometry: negative tangent distance clamps to the start tangent")
	check.call(curved.dir_at(100.0).distance_to(curved.dir_at(curved.length)) < EPSILON,
		"rail geometry: overshooting tangent distance clamps to the end tangent")
	var reverse_displacement: Vector3 = (curved.point_at(5.5) - curved.point_at(6.0)).normalized()
	check.call(curved.dir_at(6.0).dot(reverse_displacement) < -0.99
		and (-curved.dir_at(6.0)).dot(reverse_displacement) > 0.99,
		"rail geometry: reverse travel has the opposite signed tangent")

	var local_points := PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -2)])
	var basis := Basis(Vector3.UP, PI / 2.0) * Basis.from_scale(Vector3(2, 3, 4))
	var transform := Transform3D(basis, Vector3(10, 5, -8))
	var transformed = GrindLineScript.from_local_points("Grind_bench_authoring", local_points,
		transform, "coping")
	check.call(transformed.is_valid and absf(transformed.length - 8.0) < EPSILON,
		"rail geometry: authoring scale changes physical world length")
	check.call(transformed.point_at(0.0).distance_to(Vector3(10, 5, -8)) < EPSILON
		and transformed.point_at(8.0).distance_to(Vector3(2, 5, -8)) < EPSILON,
		"rail geometry: authoring rotation and translation produce world endpoints")
	check.call(transformed.dir_at(4.0).distance_to(Vector3.LEFT) < EPSILON,
		"rail geometry: authoring rotation changes the world tangent")
	check.call(_closest_matches(transformed.closest(Vector3(6, 7, -5)),
		4.0, Vector3(6, 5, -8), sqrt(13.0)),
		"rail geometry: transformed closest query stays in world coordinates and metres")
	check.call(transformed.kind == "coping",
		"rail geometry: explicit kind overrides ID inference in authoring factory")

	var source_points := PackedVector3Array([Vector3(1, 2, 3), Vector3(1, 2, 8)])
	var snapshot = GrindLineScript.new("Snapshot", source_points)
	source_points[0] = Vector3(100, 100, 100)
	check.call(snapshot.points[0] == Vector3(1, 2, 3)
		and snapshot.point_at(0.0).distance_to(Vector3(1, 2, 3)) < EPSILON,
		"rail geometry: line snapshots authored points rather than sharing mutable input")

	var invalid_sets: Array[PackedVector3Array] = [
		PackedVector3Array(),
		PackedVector3Array([Vector3(1, 2, 3)]),
		PackedVector3Array([Vector3.ONE, Vector3.ONE, Vector3.ONE]),
		PackedVector3Array([Vector3.ZERO, Vector3(INF, 1, 2)]),
		PackedVector3Array([Vector3.ZERO, Vector3(1, NAN, 2)]),
	]
	var invalid_names: Array[String] = ["empty", "single point", "all duplicates", "infinity", "NaN"]
	for i in range(invalid_sets.size()):
		var invalid = GrindLineScript.new("Invalid", invalid_sets[i])
		check.call(not invalid.is_valid and invalid.length == 0.0,
			"rail geometry: invalid authoring is rejected safely: " + invalid_names[i])
		check.call(invalid.point_at(0.0) == Vector3.ZERO
			and invalid.dir_at(0.0) == Vector3.ZERO and invalid.closest(Vector3.ZERO).is_empty(),
			"rail geometry: invalid queries return defined empty results: " + invalid_names[i])
	var duplicates = GrindLineScript.new("Duplicates", PackedVector3Array([
		Vector3.ZERO, Vector3.ZERO, Vector3(0, 0, -4), Vector3(0, 0, -4),
	]))
	check.call(duplicates.is_valid and absf(duplicates.length - 4.0) < EPSILON,
		"rail geometry: duplicate vertices do not invalidate an otherwise nonzero path")
	check.call(duplicates.dir_at(0.0).distance_to(Vector3.FORWARD) < EPSILON
		and duplicates.dir_at(4.0).distance_to(Vector3.FORWARD) < EPSILON,
		"rail geometry: duplicate endpoints still produce finite usable tangents")
	check.call(straight.point_at(INF) == Vector3.ZERO and straight.point_at(NAN) == Vector3.ZERO
		and straight.dir_at(INF) == Vector3.ZERO and straight.dir_at(NAN) == Vector3.ZERO,
		"rail geometry: nonfinite sample distances return safe empty vectors")
	check.call(straight.closest(Vector3(INF, 0, 0)).is_empty()
		and straight.closest(Vector3(0, 0, NAN)).is_empty(),
		"rail geometry: nonfinite closest-query coordinates return no result")
	var invalid_transform := Transform3D(Basis.IDENTITY, Vector3(INF, 0, 0))
	check.call(not GrindLineScript.from_local_points("Invalid transform", local_points,
		invalid_transform).is_valid,
		"rail geometry: a nonfinite authoring transform cannot produce a valid rail")
	check.call(GrindLineScript.kind_from_id("Grind_coping_corner") == "coping"
		and GrindLineScript.kind_from_id("Grind_curb_street") == "curb",
		"rail geometry: coping and curb kinds are inferred from upstream naming convention")
	check.call(GrindLineScript.kind_from_id("Grind_ledge_square") == "ledge"
		and GrindLineScript.kind_from_id("Grind_bench_seat") == "ledge"
		and GrindLineScript.kind_from_id("Grind_funbox_platform") == "ledge",
		"rail geometry: ledge, bench and funbox IDs share ledge classification")
	check.call(GrindLineScript.kind_from_id("unknown") == "rail"
		and GrindLineScript.kind_from_id("") == "rail"
		and GrindLineScript.new("Grind_curb_example", local_points, "ledge").kind == "ledge",
		"rail geometry: unknown IDs default to rail and constructor accepts explicit kind")


static func _closest_matches(result: Dictionary, expected_dist: float,
		expected_point: Vector3, expected_gap: float) -> bool:
	return (result.has_all(["dist", "point", "gap"])
		and absf(result.dist - expected_dist) < EPSILON
		and result.point.distance_to(expected_point) < EPSILON
		and absf(result.gap - expected_gap) < EPSILON)
