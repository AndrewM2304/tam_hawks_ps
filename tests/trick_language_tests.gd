extends RefCounted
## Bounded command-language tests; physical eligibility belongs to Skater.
const TrickInput = preload("res://game/tricks/trick_input.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")

static func run(check: Callable) -> void:
	_catalog(check)
	_queue(check)
	_double_taps(check)
	_manual_gestures(check)
	_specials(check)
	_lifecycle(check)

static func _catalog(check: Callable) -> void:
	check.call(Catalog.validate_definitions().is_empty(),
		"trick language: complete catalog validates all new physical-state and pose definitions")
	for id: String in ["nollie", "boneless", "no_comply", "double_kickflip", "double_heelflip",
		"spacewalk", "one_foot_manual", "manual_pivot", "wallride", "wallie", "lip_stall"]:
		var entry := Catalog.definition(id)
		check.call(not entry.is_empty() and entry.base_points > 0,
			"trick language: stable authored definition exists " + id)
	var kick := Catalog.definition("double_kickflip")
	var heel := Catalog.definition("double_heelflip")
	check.call(is_equal_approx(kick.board_roll, TAU * 2.0)
		and is_equal_approx(heel.board_roll, -TAU * 2.0) and kick.duration >= 0.40,
		"trick language: double flips actually author two opposite-direction rotations and enough airtime")
	check.call(Catalog.can_perform("wallride", "wall") and not Catalog.can_perform("wallride", "ground")
		and Catalog.can_perform("lip_stall", "lip") and Catalog.can_perform("wallie", "wall"),
		"trick language: wall and lip entries cannot be structurally scored as ordinary ground tricks")
	check.call(Catalog.can_transition("air", "wall") and Catalog.can_transition("transition", "lip")
		and Catalog.can_transition("lip", "air") and not Catalog.can_transition("bail", "wall"),
		"trick language: finite wall and transition states expose guarded entry and exit structure")
	var malformed := Catalog.definition("one_foot_manual")
	malformed.manual_foot_lift = INF
	check.call(not Catalog.validate_definitions([malformed]).is_empty(),
		"trick language: nonfinite extension contact targets are rejected")
	malformed = Catalog.definition("boneless")
	malformed.launch_speed_scale = 5.0
	check.call(not Catalog.validate_definitions([malformed]).is_empty(),
		"trick language: malformed launch multipliers cannot create unbounded setup boosts")

static func _queue(check: Callable) -> void:
	var input = TrickInput.new()
	input.sample_frame(Vector2(1, 0), ["flip"], 0.016)
	input.sample_frame(Vector2.ZERO, ["flip"], 0.05)
	input.sample_frame(Vector2.ZERO, ["flip"], 0.05)
	var command: Dictionary = input.pop_action("flip")
	check.call(command.get("action") == "flip" and command.get("direction") == "east"
		and not command.get("double_tap", true) and command.age > 0.09,
		"trick language: fresh buffered command retains its direction at the physical button press")
	check.call(input.pop_action("flip").is_empty(),
		"trick language: holding through recovery cannot manufacture another queued flip")
	input.sample_frame(Vector2.ZERO, [], 0.01)
	input.sample_frame(Vector2(0, -1), ["flip", "grab"], 0.016)
	check.call(input.pop_action("grab").direction == "north"
		and input.pop_action("flip").direction == "north",
		"trick language: independent action queues preserve simultaneous flip and grab commands")
	input.sample_frame(Vector2.ZERO, [], 0.01)
	input.sample_frame(Vector2.ZERO, ["flip"], 0.01)
	input.sample_frame(Vector2.ZERO, [], 0.181)
	check.call(input.pop_action("flip").is_empty(),
		"trick language: a move whose recovery exceeds the input window cannot execute a stale command")
	input.sample_frame(Vector2.ZERO, ["grab"], 0.01)
	input.sample_frame(Vector2.ZERO, [], 0.20)
	check.call(not input.pop_action("grab", 0.25).is_empty(),
		"trick language: an explicitly wider bounded state buffer is available to contextual mechanics")
	input.sample_frame(Vector2.ZERO, ["grind"], 0.01)
	check.call(input.pop_action("unknown").is_empty() and input.pop_action("grind", NAN).is_empty()
		and input.pop_action("grind", -1).is_empty() and input.queued_action_count() == 1,
		"trick language: malformed consumers cannot destroy a valid pending command")
	check.call(not input.pop_action("grind").is_empty(),
		"trick language: rejected consumer requests leave the genuine action usable")
	input.sample_frame(Vector2.ZERO, [], 0.01)
	input.sample_frame(Vector2.ZERO, [null, 3, "imaginary", "flip", "flip"], 0.01)
	check.call(input.queued_action_count() == 1,
		"trick language: unsupported and duplicate button names cannot inflate the queue")
	input.clear_actions()
	for index in 40:
		input.sample_frame(Vector2.ZERO, [], 0.001)
		input.sample_frame(Vector2.ZERO, ["flip"], 0.001)
	check.call(input.queued_action_count() == TrickInput.MAX_ACTIONS,
		"trick language: pathological fresh-input volume remains bounded to sixteen pending actions")
	input.sample_frame(Vector2.ZERO, [], 0.46)
	check.call(input.queued_action_count() == 0,
		"trick language: expired actions leave no unbounded historical queue")

static func _double_taps(check: Callable) -> void:
	var input = TrickInput.new()
	input.sample_frame(Vector2.ZERO, ["flip"], 0.016)
	input.pop_action("flip")
	input.sample_frame(Vector2.ZERO, [], 0.05)
	input.sample_frame(Vector2.ZERO, ["flip"], 0.05)
	check.call(input.consume_double_tap("flip") and not input.consume_double_tap("flip")
		and input.pop_action("flip").is_empty(),
		"trick language: second fresh tap upgrades exactly once and cannot also become a third trick")
	input.reset()
	input.sample_frame(Vector2.ZERO, ["flip"], 0.016)
	input.pop_action("flip")
	input.sample_frame(Vector2.ZERO, ["flip"], 0.10)
	check.call(not input.consume_double_tap("flip"),
		"trick language: held input is not a double tap even inside the recognition interval")
	input.sample_frame(Vector2.ZERO, [], 0.23)
	input.sample_frame(Vector2.ZERO, ["flip"], 0.016)
	check.call(not input.pop_action("flip").double_tap,
		"trick language: a later fresh flip starts another move rather than a stale double upgrade")
	input.reset()
	input.sample_frame(Vector2.ZERO, ["grab"], 0.01)
	input.pop_action("grab")
	input.sample_frame(Vector2.ZERO, [], 0.0)
	input.sample_frame(Vector2.ZERO, ["grab"], 0.0)
	check.call(not input.pop_action("grab").double_tap,
		"trick language: same-timestamp echo cycles cannot qualify as a second deliberate tap")

static func _manual_gestures(check: Callable) -> void:
	var input = TrickInput.new()
	input.sample_frame(Vector2(0, -1), [], 0.016)
	input.sample_frame(Vector2.ZERO, [], 0.04)
	input.sample_frame(Vector2(0, 1), [], 0.04)
	check.call(input.consume_manual_gesture() == "manual" and input.consume_manual_gesture().is_empty(),
		"trick language: deliberate up-down sequence enters one latched manual gesture")
	input.reset()
	input.sample_frame(Vector2(0, 1), [], 0.016)
	input.sample_frame(Vector2.ZERO, [], 0.04)
	input.sample_frame(Vector2(0, -1), [], 0.04)
	check.call(input.consume_manual_gesture() == "nose_manual",
		"trick language: reverse down-up sequence selects nose manual")
	input.reset()
	input.sample_frame(Vector2(0, -1), [], 0.016)
	input.sample_frame(Vector2(0, -1), [], 0.40)
	input.sample_frame(Vector2(0, 1), [], 0.016)
	check.call(input.consume_manual_gesture().is_empty(),
		"trick language: prolonged forward travel followed by braking is not a manual gesture")
	input.reset()
	input.sample_frame(Vector2(0, -1), [], 0.016)
	input.sample_frame(Vector2(1, 0), [], 0.04)
	input.sample_frame(Vector2(0, 1), [], 0.04)
	check.call(input.consume_manual_gesture().is_empty(),
		"trick language: unrelated intervening direction breaks a manual command sequence")
	input.reset()
	input.sample_frame(Vector2(0, -1), [], 0.016)
	input.sample_frame(Vector2(0, 1), [], 0.04)
	input.sample_frame(Vector2.ZERO, [], 0.181)
	check.call(input.consume_manual_gesture().is_empty(),
		"trick language: unused manual gesture expires before it can cause a later surprise entry")

static func _specials(check: Callable) -> void:
	var input = TrickInput.new()
	input.sample_frame(Vector2(-1, 0), [], 0.016)
	input.sample_frame(Vector2.ZERO, [], 0.04)
	input.sample_frame(Vector2(1, 0), ["flip"], 0.04)
	check.call(input.consume_special() == "special_clyde_carousel" and input.pop_action("flip").is_empty()
		and input.consume_special().is_empty(),
		"trick language: left-right-flip consumes one original special command and its regular flip")
	input.sample_frame(Vector2(1, 0), [], 0.03)
	input.sample_frame(Vector2(1, 0), ["flip"], 0.03)
	check.call(input.consume_special().is_empty() and not input.pop_action("flip").is_empty(),
		"trick language: one directional sequence cannot be reused by repeatedly tapping its final button")
	input.reset()
	input.sample_frame(Vector2(0, -1), [], 0.016)
	input.sample_frame(Vector2(0, 1), ["grab"], 0.08)
	check.call(input.consume_special() == "special_tenement_tumble"
		and input.consume_manual_gesture().is_empty() and input.pop_action("grab").is_empty(),
		"trick language: up-down-grab consumes its special without also activating a normal grab or manual")
	input.reset()
	input.sample_frame(Vector2(-1, 0), [], 0.016)
	input.sample_frame(Vector2(1, 0), [], 0.46)
	input.sample_frame(Vector2.ZERO, ["flip"], 0.016)
	check.call(input.consume_special().is_empty(),
		"trick language: old directions cannot unlock a future special command")
	input.reset()
	input.sample_frame(Vector2(-1, 0), [], 0.016)
	input.sample_frame(Vector2(1, 0), ["flip"], 0.04)
	var command: Dictionary = input.pop_action("flip")
	check.call(command.special_id == "special_clyde_carousel",
		"trick language: command metadata exposes the recognized special to context-specific callers")

static func _lifecycle(check: Callable) -> void:
	var input = TrickInput.new()
	input.sample_frame(Vector2(1, 0), ["flip"], 0.016)
	input.clear_actions()
	input.sample_frame(Vector2(1, 0), ["flip"], 0.016)
	check.call(input.pop_action("flip").is_empty() and input.direction() == "east",
		"trick language: clearing disabled-state commands preserves held inputs without fabricating fresh presses")
	input.sample_frame(Vector2.ZERO, [], 0.016)
	input.sample_frame(Vector2.ZERO, ["flip"], 0.016)
	check.call(not input.pop_action("flip").is_empty(),
		"trick language: a genuine release and repress works after a command clear")
	input.sample_frame(Vector2(0, -1), ["grab"], 0.016)
	input.reset()
	check.call(input.queued_action_count() == 0 and input.direction() == "neutral"
		and input.consume_manual_gesture().is_empty() and input.consume_special().is_empty(),
		"trick language: reset clears command history, physical button snapshots and direction memory")
	input.sample_frame(Vector2(-1, 0), ["flip"], 0.016)
	input.sample_frame(Vector2(1, 0), ["grab"], NAN)
	input.sample_frame(Vector2(1, 0), ["grab"], -1.0)
	check.call(input.direction() == "west" and input.queued_action_count() == 1,
		"trick language: invalid sample timing cannot age or append queued actions")
	input.sample_frame(Vector2(INF, 0), ["flip"], 0.016)
	check.call(input.direction() == "neutral" and input.queued_action_count() == 0,
		"trick language: invalid physical samples clear stale directions and queued commands safely")
