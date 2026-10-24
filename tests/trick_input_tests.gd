extends RefCounted
## Input timing and directional selection tests with no injected gamepad dependency.

const TrickInput = preload("res://game/tricks/trick_input.gd")

static func run(check: Callable) -> void:
	var expected: Array = [
		[Vector2.ZERO, "neutral"], [Vector2(0, -1), "north"],
		[Vector2(0, 1), "south"], [Vector2(1, 0), "east"], [Vector2(-1, 0), "west"],
		[Vector2(1, -1), "north_east"], [Vector2(-1, -1), "north_west"],
		[Vector2(1, 1), "south_east"], [Vector2(-1, 1), "south_west"],
	]
	for item: Array in expected:
		check.call(TrickInput.direction_for_axes(item[0]) == item[1],
			"trick input: %s axes select %s" % [item[0], item[1]])
	check.call(TrickInput.direction_for_axes(Vector2(0.49, -0.49)) == "neutral"
		and TrickInput.direction_for_axes(Vector2(0.5, 0)) == "east",
		"trick input: analog jitter below half strength stays neutral and threshold is explicit")
	check.call(TrickInput.direction_for_axes(Vector2(INF, 1)) == "neutral"
		and TrickInput.direction_for_axes(Vector2(NAN, 0)) == "neutral",
		"trick input: nonfinite axes cannot become trick selections")
	check.call(TrickInput.direction_for_axes(Vector2(100, 100)) == "south_east"
		and TrickInput.direction_for_axes(Vector2(0.55, -1)) == "north",
		"trick input: vector normalization preserves diagonals without weak off-axis leakage")
	var input = TrickInput.new()
	check.call(input.direction() == "neutral" and input.direction_age() > 0.18,
		"trick input: construction has no stale directional gesture")
	input.sample_axes(Vector2(1, 0), 1.0 / 60.0)
	check.call(input.direction() == "east" and is_zero_approx(input.direction_age()),
		"trick input: a fresh direction is available immediately")
	input.sample_axes(Vector2(1, 0), 0.5)
	check.call(input.direction() == "east" and input.direction_age() >= 0.5,
		"trick input: sustained controls stay selectable but do not refresh the direction edge")
	input.sample_axes(Vector2.ZERO, 0.10)
	check.call(input.direction() == "east",
		"trick input: a direction released shortly before a trick remains buffered")
	input.sample_axes(Vector2.ZERO, 0.081)
	check.call(input.direction() == "neutral",
		"trick input: released direction expires after the bounded memory")
	input.sample_axes(Vector2(0, -1), 1.0 / 60.0)
	check.call(input.direction() == "north" and is_zero_approx(input.direction_age()),
		"trick input: a new direction overrides old memory and refreshes edge eligibility")
	input.sample_axes(Vector2(0, -1), 0.30)
	input.sample_axes(Vector2.ZERO, 0.01)
	input.sample_axes(Vector2(0, -1), 0.01)
	check.call(is_zero_approx(input.direction_age()),
		"trick input: releasing and deliberately repeating the same direction is a fresh gesture")
	input.sample_axes(Vector2(1, 1), -1.0)
	input.sample_axes(Vector2(1, 1), NAN)
	check.call(input.direction() == "north" and is_zero_approx(input.direction_age()),
		"trick input: negative or nonfinite deltas cannot age or rewrite input memory")
	input.sample_axes(Vector2(INF, 0), 0.01)
	check.call(input.direction() == "neutral", "trick input: invalid axes clear old selection safely")
	input.sample_axes(Vector2(-1, 1), 0.01)
	input.reset()
	check.call(input.direction() == "neutral" and input.direction_age() > 0.18,
		"trick input: reset clears held direction and recent gesture timing")
	input.sample_axes(Vector2(0, -1), 0.01)
	input.sample_axes(Vector2(0, -1), 0.5)
	input.clear_recent()
	check.call(input.direction() == "north" and input.direction_age() >= 0.5,
		"trick input: takeoff memory clear preserves the physically held cue and its age")
	input.sample_axes(Vector2(0, -1), 0.01)
	input.sample_axes(Vector2.ZERO, 0.01)
	check.call(input.direction() == "neutral",
		"trick input: released takeoff push cannot select a stale directional trick")
	input.sample_axes(Vector2(0, -1), 0.01)
	input.sample_axes(Vector2.ZERO, 0.01)
	check.call(input.direction() == "north" and input.direction_age() < 0.18,
		"trick input: a genuine release and repress restores direction memory")
	input.sample_axes(Vector2(0, -1), 0.01)
	input.clear_recent()
	input.sample_axes(Vector2(1, 0), 0.01)
	input.sample_axes(Vector2.ZERO, 0.01)
	check.call(input.direction() == "east",
		"trick input: changing physical direction after takeoff restores recent cue selection")
	_test_opposing_strengths(check)
	_test_live_actions(check)

static func _test_opposing_strengths(check: Callable) -> void:
	var input = TrickInput.new()
	var delta := 1.0 / 60.0
	input.sample_strengths(1.0, 0.0, 0.0, 0.0, delta)
	input.sample_strengths(1.0, 1.0, 0.0, 0.0, delta)
	check.call(input.direction() == "neutral",
		"trick input: opposite vertical strengths immediately erase a remembered north cue")
	input.sample_strengths(1.0, 1.0, 0.0, 0.0, delta)
	input.sample_strengths(0.0, 0.0, 0.0, 0.0, delta)
	check.call(input.direction() == "neutral",
		"trick input: canceled input cannot reappear from memory on the next frame or full release")
	input.sample_strengths(1.0, 0.0, 0.0, 1.0, delta)
	input.sample_strengths(1.0, 1.0, 0.0, 1.0, delta)
	check.call(input.direction() == "east",
		"trick input: canceling vertical input preserves the nonconflicting horizontal cue")
	input.sample_strengths(1.0, 0.0, 0.0, 1.0, delta)
	input.sample_strengths(1.0, 0.0, 1.0, 1.0, delta)
	check.call(input.direction() == "north",
		"trick input: canceling horizontal input preserves the nonconflicting vertical cue")
	input.sample_strengths(1.0, 1.0, 1.0, 1.0, delta)
	check.call(input.direction() == "neutral",
		"trick input: canceling both axes immediately clears every directional memory component")
	input.sample_strengths(1.0, 0.0, 0.0, 0.0, delta)
	check.call(input.direction() == "north" and is_zero_approx(input.direction_age()),
		"trick input: a genuine unopposed edge after cancellation can select a new trick")
	input.reset()
	input.sample_strengths(0.0, 0.0, 1.0, 0.0, delta)
	input.sample_strengths(0.0, 0.0, 0.5, 1.0, delta)
	check.call(input.direction() == "neutral",
		"trick input: unequal opposing controls at threshold cancel instead of leaking the stronger side")

static func _test_live_actions(check: Callable) -> void:
	# Root's input setup registers these remappable actions before this suite.
	for action: String in ["push", "brake", "steer_left", "steer_right"]:
		Input.action_release(action)
	var input = TrickInput.new()
	Input.action_press("push")
	Input.action_press("steer_right")
	input.sample(1.0 / 60.0)
	check.call(input.direction() == "north_east",
		"trick input: real registered push and right actions select the diagonal")
	Input.action_press("brake")
	input.sample(1.0 / 60.0)
	check.call(input.direction() == "east",
		"trick input: actual opposing up/down cancels the vertical cue in the first physics frame")
	Input.action_press("steer_left")
	input.sample(1.0 / 60.0)
	check.call(input.direction() == "neutral",
		"trick input: actual simultaneous opposing controls clear recent cues immediately")
	input.sample(1.0 / 60.0)
	check.call(input.direction() == "neutral",
		"trick input: held opposing controls stay neutral on the following physics frame")
	for action: String in ["push", "brake", "steer_left", "steer_right"]:
		Input.action_release(action)
	input.reset()
