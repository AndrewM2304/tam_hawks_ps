extends RefCounted
## Original contact checks use actual authored model coordinates and native Curve3D.
const Line = preload("res://game/tricks/grind_line.gd")
const Style = preload("res://game/tricks/grind_style.gd")
const EPSILON: float = 0.0002


static func run(check: Callable) -> void:
	_selection(check)
	var straight = _line("original straight", PackedVector3Array([
		Vector3(2, 1, 3), Vector3(2, 1, -7)]))
	var reusable := Style.ContactPose.new()
	for travel: float in [-1.0, 1.0]:
		for yaw: float in [0.0, PI]:
			for balance: float in [-0.8, 0.0, 0.8]:
				var label: String = " travel=" + str(travel) + " yaw=" + str(yaw) + " balance=" + str(balance)
				var solved: bool = Style.solve_into(reusable, straight, 4.0, travel, yaw, "grind_50_50", balance)
				check.call(solved and _contacts_match(reusable, 2),
					"grind styles: both original hanger undersides stay on support" + label)
				var board_forward: Vector3 = -reusable.board_transform.basis.z
				var expected_forward: Vector3 = Vector3.FORWARD * travel * (1.0 if yaw == 0.0 else -1.0)
				check.call(_rigid(reusable.board_transform.basis) and board_forward.dot(expected_forward) > 0.99999,
					"grind styles: signed travel/fakie and balance retain a rigid board" + label)
	check.call(reusable.anchors[0] == Vector3(0, -0.103, -0.255)
		and reusable.anchors[1] == Vector3(0, -0.103, 0.255),
		"grind styles: 50-50 uses asset hanger undersides, not wheel/deck or guessed root height")
	for at: float in [0.0, 0.05, straight.length - 0.05, straight.length]:
		var solved: bool = Style.solve_into(reusable, straight, at, 1.0, 0.0, "grind_50_50", 0.65)
		check.call(solved and _contacts_match(reusable, 2)
			and _on_line(straight, reusable.supports[0]) and _on_line(straight, reusable.supports[1]),
			"grind styles: open endpoint clamps both support contacts inside the finite guide " + str(at))
	var at_start: Dictionary = Style.pose(straight, 0.0, 1.0, 0.0, "grind_50_50", 0.0)
	check.call(at_start.valid and at_start.supports[1].distance_to(Vector3(2, 1, 3)) < EPSILON
		and at_start.supports[0].distance_to(Vector3(2, 1, 2.49)) < EPSILON,
		"grind styles: finite start supports span exactly .51m without extrapolating the rail")
	_slopes_and_bends(check, reusable)
	_boardslides(check, reusable, straight)
	_rejections(check, reusable, straight)


static func _selection(check: Callable) -> void:
	for direction: Vector2 in [Vector2.ZERO, Vector2.UP, Vector2.DOWN]:
		var parallel: Dictionary = Style.select(direction, Vector3.FORWARD, Vector3.FORWARD)
		check.call(parallel.get("id") == "grind_50_50" and parallel.get("yaw") == 0.0,
			"grind styles: neutral/up/down snapshot selects parallel 50-50 " + str(direction))
	var fakie: Dictionary = Style.select(Vector2.ZERO, Vector3.BACK, Vector3.FORWARD)
	check.call(fakie.get("id") == "grind_50_50" and absf(fakie.get("yaw", 0.0)) == PI,
		"grind styles: a reversed parallel board preserves fakie heading")
	for side: float in [-1.0, 1.0]:
		var explicit: Dictionary = Style.select(Vector2(side, 0.0), Vector3.FORWARD, Vector3.FORWARD)
		check.call(explicit.get("id") == "boardslide" and is_equal_approx(explicit.get("yaw", 0.0), -side * PI * 0.5),
			"grind styles: horizontal snapshot selects a signed deck-crossing quarter-turn " + str(side))
		var perpendicular: Dictionary = Style.select(Vector2.ZERO,
			Vector3.FORWARD.rotated(Vector3.UP, side * PI * 0.5), Vector3.FORWARD)
		check.call(perpendicular.get("id") == "boardslide" and is_equal_approx(perpendicular.get("yaw", 0.0), side * PI * 0.5),
			"grind styles: already-perpendicular captured board selects deck contact independently of travel " + str(side))
		var boundary: Dictionary = Style.select(Vector2(side * 0.35, 0.0), Vector3.FORWARD, Vector3.FORWARD)
		var below: Dictionary = Style.select(Vector2(side * 0.3498, 0.0), Vector3.FORWARD, Vector3.FORWARD)
		check.call(boundary.get("id") == "boardslide" and is_equal_approx(boundary.get("yaw", 0.0), -side * PI * 0.5),
			"grind styles: authored +/-0.35 direction boundary follows shared input precision semantics " + str(side))
		check.call(below.get("id") == "grind_50_50" and below.get("yaw") == 0.0,
			"grind styles: direction just below the shared threshold retains neutral truck contact " + str(side))
	for degrees: float in [44.0, 46.0, 134.0, 136.0]:
		var selected: Dictionary = Style.select(Vector2.ZERO,
			Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(degrees)), Vector3.FORWARD)
		check.call((selected.get("id") == "boardslide") == (degrees > 45.0 and degrees < 135.0),
			"grind styles: captured heading distinguishes sides of 45/135 degree contact boundaries " + str(degrees))
	var snapshot: Vector2 = Vector2.LEFT
	var selected: Dictionary = Style.select(snapshot, Vector3.FORWARD, Vector3.FORWARD)
	snapshot = Vector2.RIGHT
	var later: Dictionary = Style.select(snapshot, Vector3.FORWARD, Vector3.FORWARD)
	check.call(selected.get("yaw") == PI * 0.5 and later.get("yaw") == -PI * 0.5,
		"grind styles: selection retains the passed capture snapshot when later direction changes")
	later["yaw"] = 0.0
	check.call(selected.get("yaw") == PI * 0.5,
		"grind styles: separate selections own their result without shared mutable style state")
	check.call(Style.select(Vector2(INF, 0), Vector3.FORWARD, Vector3.FORWARD).is_empty()
		and Style.select(Vector2.ZERO, Vector3(0, NAN, -1), Vector3.FORWARD).is_empty()
		and Style.select(Vector2.ZERO, Vector3.UP, Vector3.FORWARD).is_empty()
		and Style.select(Vector2.ZERO, Vector3.FORWARD, Vector3.ZERO).is_empty(),
		"grind styles: nonfinite and missing horizontal board/travel headings cannot select a style")


static func _slopes_and_bends(check: Callable, result: Style.ContactPose) -> void:
	var slope = _line("original slope", PackedVector3Array([
		Vector3(12, 4, 3), Vector3(15, 8, -9)]))
	for travel: float in [-1.0, 1.0]:
		for yaw: float in [0.0, PI]:
			var solved: bool = Style.solve_into(result, slope, 6.0, travel, yaw, "grind_50_50", 0.75)
			var expected: Vector3 = Vector3(3, 4, -12).normalized() * travel * (1.0 if yaw == 0.0 else -1.0)
			check.call(solved and _contacts_match(result, 2) and _rigid(result.board_transform.basis)
				and (-result.board_transform.basis.z).dot(expected) > 0.99999,
				"grind styles: tilted support keeps both rigid truck contacts for uphill/downhill/fakie " + str(travel) + "/" + str(yaw))
	var corner = _line("original right angle", PackedVector3Array([
		Vector3(0, 2, 2), Vector3(0, 2, 0), Vector3(2, 2, 0)]))
	check.call(Style.solve_into(result, corner, 2.0, 1.0, 0.0, "grind_50_50", 0.7)
		and _contacts_match(result, 2) and _rigid(result.board_transform.basis)
		and _on_line(corner, result.supports[0]) and _on_line(corner, result.supports[1])
		and absf(result.supports[0].distance_to(result.supports[1]) - 0.51) < EPSILON,
		"grind styles: right-angle bend solves an actual .51m support chord without stretching or tangent-only fake contact")
	check.call(result.supports[0].x > 0.35 and result.supports[1].z > 0.35,
		"grind styles: bent-guide contacts straddle the corner beyond the .255m straight arc offset")
	var loop = _line("original loop", PackedVector3Array([
		Vector3.ZERO, Vector3(0, 0, -2), Vector3(2, 0, -2), Vector3(2, 0, 0), Vector3.ZERO]))
	check.call(loop.is_loop and Style.solve_into(result, loop, 0.0, -1.0, PI, "grind_50_50", -0.8)
		and _contacts_match(result, 2) and _on_line(loop, result.supports[0]) and _on_line(loop, result.supports[1]),
		"grind styles: loop seam wraps actual truck supports for signed fakie travel")
	var tiny_loop = _line("original tight loop", PackedVector3Array([
		Vector3.ZERO, Vector3(0, 0, -0.2), Vector3(0.2, 0, -0.2), Vector3(0.2, 0, 0), Vector3.ZERO]))
	check.call(not Style.solve_into(result, tiny_loop, 0.1, 1.0, 0.0, "grind_50_50", 0.0)
		and not result.valid,
		"grind styles: a loop whose entire diameter is below the fixed hanger span is rejected")
	var short_bend = _line("original impossible bend", PackedVector3Array([
		Vector3(0, 0, 0.255), Vector3.ZERO, Vector3(0.255, 0, 0)]))
	check.call(not Style.solve_into(result, short_bend, 0.255, 1.0, 0.0, "grind_50_50", 0.0),
		"grind styles: sufficient arc length alone cannot fake a rigid contact chord on a short right-angle guide")


static func _boardslides(check: Callable, result: Style.ContactPose, straight: Line) -> void:
	for travel: float in [-1.0, 1.0]:
		for yaw: float in [-PI * 0.5, PI * 0.5]:
			for balance: float in [-0.8, 0.0, 0.8]:
				var solved: bool = Style.solve_into(result, straight, 4.0, travel, yaw, "boardslide", balance)
				check.call(solved and _contacts_match(result, 1) and _rigid(result.board_transform.basis)
					and result.anchors[0] == Vector3(0, -0.014, 0)
					and absf((-result.board_transform.basis.z).dot(Vector3.FORWARD)) < 0.00001,
					"grind styles: signed boardslide keeps the asset deck centre fixed through balance " + str(travel) + "/" + str(yaw) + "/" + str(balance))
	var slope = _line("original tilted slide", PackedVector3Array([
		Vector3(2, 3, 4), Vector3(4, 5, -4)]))
	check.call(Style.solve_into(result, slope, 2.0, -1.0, PI * 0.5, "boardslide", -0.6)
		and _contacts_match(result, 1) and _rigid(result.board_transform.basis)
		and absf((-result.board_transform.basis.z).dot(slope.dir_at(2.0))) < 0.00001,
		"grind styles: sloped boardslide crosses the rail in its support plane while holding the deck centre")
	var lifted = Line.new("original beam centre", PackedVector3Array([
		Vector3(0, 1, 0), Vector3(0, 1, -2)])).configure_contact(0.0, 0.04, "original test beam centre")
	check.call(Style.solve_into(result, lifted, 1.0, 1.0, PI * 0.5, "boardslide", 0.0)
		and result.supports[0].distance_to(Vector3(0, 1.04, -1)) < EPSILON
		and (result.board_transform * result.anchors[0]).distance_to(Vector3(0, 1.04, -1)) < EPSILON,
		"grind styles: authored beam support offset, rather than its centreline, receives the deck")
	var short = _line("original short support", PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -0.4)]))
	check.call(not Style.solve_into(result, short, 0.2, 1.0, 0.0, "grind_50_50", 0.0)
		and Style.solve_into(result, short, 0.2, 1.0, PI * 0.5, "boardslide", 0.0)
		and _contacts_match(result, 1),
		"grind styles: short finite support rejects two trucks but can support one deck contact")


static func _rejections(check: Callable, result: Style.ContactPose, straight: Line) -> void:
	for entry: Array in [
		[INF, 1.0, 0.0, "grind_50_50", 0.0],
		[1.0, 0.0, 0.0, "grind_50_50", 0.0],
		[1.0, 1.0, NAN, "grind_50_50", 0.0],
		[1.0, 1.0, 0.2, "grind_50_50", 0.0],
		[1.0, 1.0, 0.0, "boardslide", 0.0],
		[1.0, 1.0, 0.0, "unimplemented_lipslide", 0.0],
		[1.0, 1.0, 0.0, "grind_50_50", NAN],
		[1.0, 1.0, 0.0, "grind_50_50", 1.01],
	]:
		Style.solve_into(result, straight, 1.0, 1.0, 0.0, "grind_50_50", 0.0)
		check.call(not Style.solve_into(result, straight, entry[0], entry[1], entry[2], entry[3], entry[4])
			and not result.valid and not is_finite(result.max_error),
			"grind styles: invalid request cannot retain a previously valid contact pose " + str(entry))
	var unverified = Line.new("unknown prop", PackedVector3Array([Vector3.ZERO, Vector3.FORWARD * 2.0]))
	var vertical = _line("vertical support", PackedVector3Array([Vector3.ZERO, Vector3.UP * 2.0]))
	var empty = _line("empty support", PackedVector3Array())
	for line in [null, unverified, vertical, empty]:
		check.call(not Style.solve_into(result, line, 1.0, 1.0, 0.0, "grind_50_50", 0.0),
			"grind styles: missing/unverified/vertical/empty support cannot claim named contact " + str(line))
	Style.solve_into(result, straight, 2.0, 1.0, 0.0, "grind_50_50", 0.8)
	var stored_front: Vector3 = result.supports[0]
	Style.solve_into(result, straight, 3.0, 1.0, PI * 0.5, "boardslide", -0.8)
	check.call(result.valid and result.anchor_count == 1 and result.anchors.size() == 2
		and result.supports.size() == 2 and result.supports[1] == Vector3.ZERO
		and result.supports[0].distance_to(stored_front) > 0.5,
		"grind styles: one reused result replaces contact count/data while retaining its two fixed array slots")


static func _line(id: String, points: PackedVector3Array):
	return Line.new(id, points).configure_contact(0.0, 0.0, "original test support")


static func _contacts_match(result: Style.ContactPose, expected_count: int) -> bool:
	if not result.valid or result.anchor_count != expected_count or result.max_error > EPSILON:
		return false
	for index in result.anchor_count:
		if (result.board_transform * result.anchors[index]).distance_to(result.supports[index]) > EPSILON:
			return false
	return true


static func _rigid(frame: Basis) -> bool:
	return (frame.is_finite() and absf(frame.determinant() - 1.0) < 0.00001
		and absf(frame.x.length() - 1.0) < 0.00001 and absf(frame.y.length() - 1.0) < 0.00001
		and absf(frame.z.length() - 1.0) < 0.00001 and absf(frame.x.dot(frame.y)) < 0.00001
		and absf(frame.y.dot(frame.z)) < 0.00001 and absf(frame.x.dot(frame.z)) < 0.00001)


static func _on_line(line: Line, point: Vector3) -> bool:
	var closest: Dictionary = line.closest(point)
	return not closest.is_empty() and closest.gap < EPSILON
