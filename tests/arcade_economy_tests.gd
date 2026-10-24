extends RefCounted
## Public arithmetic/lifecycle contracts for entry-count combos and live specials.

const Score = preload("res://game/scoring/score_session.gd")
const Meter = preload("res://game/tricks/special_meter.gd")

static func run(check: Callable) -> void:
	_score_cases(check)
	_upgrade_cases(check)
	_meter_cases(check)

static func _upgrade_cases(check: Callable) -> void:
	var score = Score.new()
	check.call(score.upgrade_last_trick("Double Kickflip", 600, "double_kickflip") == 0,
		"arcade upgrade: a double-tap cannot manufacture an empty trick entry")
	score.add_trick("Switch Kickflip", 300, "kickflip")
	score.add_hold_points(50)
	score.add_spin_bonus(200, "Backside 180")
	score.begin_landing()
	score.tick(0.1)
	var remaining: float = score.landing_remaining
	check.call(score.upgrade_last_trick("Switch Double Kickflip", 600, "double_kickflip") == 300
		and score.combo_base == 850 and score.combo_multiplier == 1 and score.combo_trick_count == 1,
		"arcade upgrade: a double flip replaces one provisional move and preserves its holds and spin")
	check.call(score.last_trick == "Switch Double Kickflip · Backside 180"
		and score.trick_history == [score.last_trick] and score.last_award == 600 and not score.last_repeat,
		"arcade upgrade: the receipt names the final move and retains attached rotation")
	check.call(score.pending_landing and is_equal_approx(score.landing_remaining, remaining),
		"arcade upgrade: refining an entry cannot restart or suspend the bank deadline")
	check.call(score.upgrade_last_trick("Switch Double Kickflip", 600, "double_kickflip") == 0
		and score.combo_base == 850 and not score.last_repeat,
		"arcade upgrade: duplicate refinement neither re-awards points nor makes itself stale")
	score.bank_combo()
	check.call(score.add_trick("Kickflip", 300, "kickflip") == 300 and not score.last_repeat,
		"arcade upgrade: a replaced provisional single does not poison future single-flip staleness")
	check.call(score.upgrade_last_trick("Double Kickflip", 600, "double_kickflip") == 0
		and score.combo_base == 300 and score.last_repeat,
		"arcade upgrade: the completed double owns its prior run use and repeat value")
	score.drop_combo()
	score.add_trick("Kickflip", 300, "kickflip")
	check.call(score.upgrade_last_trick("Double Kickflip", 600, "double_kickflip") == -150
		and score.combo_base == 150 and score.last_award == 150 and score.combo_trick_count == 1,
		"arcade upgrade: a stale double can reduce its provisional value without increasing entries")
	score.drop_combo()
	score.add_trick("Kickflip", 300, "kickflip")
	check.call(score.upgrade_last_trick(" ", 600, "double_kickflip") == 0
		and score.upgrade_last_trick("Double Kickflip", 0, "double_kickflip") == 0
		and score.combo_base == 300 and not score.last_repeat,
		"arcade upgrade: invalid refinements leave the accepted entry and staleness intact")
	score.bank_combo()
	check.call(score.upgrade_last_trick("Double Kickflip", 600, "double_kickflip") == 0,
		"arcade upgrade: a completed combo cannot be refined after banking")
	var bounded = Score.new()
	bounded.add_trick("Prelude", Score.MAX_EVENT_POINTS, "prelude")
	bounded.combo_base = Score.MAX_SCORE - 10
	bounded.add_trick("Kickflip", 300, "kickflip")
	check.call(bounded.upgrade_last_trick("Double Kickflip", 9223372036854775807, "double_kickflip") == 0
		and bounded.combo_base == Score.MAX_SCORE and bounded.last_award == 10,
		"arcade upgrade: saturated refinements report only actual score capacity without overflow")
	score.reset()
	check.call(score.upgrade_last_trick("Double Kickflip", 600, "double_kickflip") == 0
		and score.add_trick("Double Kickflip", 600, "double_kickflip") == 600,
		"arcade upgrade: restart clears provisional state and all completed-move staleness")

static func _score_cases(check: Callable) -> void:
	var score = Score.new()
	check.call(score.add_trick("Kickflip", 300, "kickflip") == 300,
		"arcade economy: a first accepted trick returns its effective live award")
	check.call(score.add_trick("Switch Kickflip", 300, "kickflip") == 150
		and score.combo_multiplier == 2 and score.get_combo_value() == 900,
		"arcade economy: a repeated trick still builds the multiplier while its stable-ID value decays")
	score.add_trick("Heelflip", 300, "heelflip")
	check.call(score.combo_base == 750 and score.combo_multiplier == 3 and score.combo_trick_count == 3,
		"arcade economy: accepted entry count owns the multiplier independently of distinct names")
	score.begin_landing()
	score.tick(0.10)
	var remaining: float = score.landing_remaining
	var history_count: int = score.trick_history.size()
	check.call(score.add_spin_bonus(200, "Backside 180") == 200
		and score.combo_base == 950 and score.combo_multiplier == 3,
		"arcade economy: rotation extends an existing air trick without another multiplier entry")
	check.call(score.combo_trick_count == 3 and score.trick_history.size() == history_count
		and score.trick_history.back() == "Heelflip · Backside 180",
		"arcade economy: rotation remains readable in its parent trick receipt")
	check.call(score.pending_landing and is_equal_approx(score.landing_remaining, remaining),
		"arcade economy: rotation cannot suspend or refresh the banking deadline")
	check.call(score.add_hold_points(100) == 100 and score.combo_base == 1050
		and score.combo_multiplier == 3 and score.combo_trick_count == 3,
		"arcade economy: hold extension returns only added base points with no new entry")
	check.call(score.pending_landing and is_equal_approx(score.landing_remaining, remaining),
		"arcade economy: sustained scoring leaves the authoritative landing deadline intact")
	check.call(score.tick(remaining) == 3150 and score.total_score == 3150
		and score.last_banked_tricks == ["Kickflip", "Switch Kickflip", "Heelflip · Backside 180"],
		"arcade economy: the full entry/hold/rotation combination banks exactly once")
	check.call(score.tick(5.0) == 0 and score.total_score == 3150,
		"arcade economy: supported time after banking cannot duplicate the score")
	check.call(score.add_trick("Kickflip", 300, "kickflip") == 75
		and score.last_repeat and score.combo_multiplier == 1,
		"arcade economy: banking clears the combo but retains trick staleness for the run")
	score.drop_combo()
	check.call(score.last_dropped_value == 75 and score.total_score == 3150
		and score.add_trick("Kickflip", 300, "kickflip") == 37,
		"arcade economy: bailing loses pending points without restoring a stale move's value")
	score.drop_combo()
	check.call(score.add_trick("Kickflip", 300, "kickflip") == 18,
		"arcade economy: run-long staleness reaches its explicit sixteenth-value floor")
	score.drop_combo()
	check.call(score.add_trick("Kickflip", 300, "kickflip") == 18,
		"arcade economy: further short banks or bails cannot refresh the repetition floor")
	score.reset()
	check.call(score.add_trick("Kickflip", 300, "kickflip") == 300 and not score.last_repeat,
		"arcade economy: a new run restores the original move value")
	var empty = Score.new()
	check.call(empty.add_hold_points(100) == 0 and empty.add_spin_bonus(200, "Frontside 180") == 0
		and empty.combo_trick_count == 0 and empty.get_combo_value() == 0,
		"arcade economy: bonus callbacks cannot manufacture an empty combo")
	check.call(empty.add_trick(" ", 100, "kickflip") == 0
		and empty.add_trick("Kickflip", 0, "kickflip") == 0
		and empty.add_trick("Kickflip", -100, "kickflip") == 0
		and empty.add_trick("Kickflip", 300, "kickflip") == 300,
		"arcade economy: rejected entries neither score nor poison future staleness")
	var long_line = Score.new()
	for index in 150:
		long_line.add_trick("Kickflip", 300, "kickflip")
	check.call(long_line.combo_trick_count == 150 and long_line.combo_multiplier == Score.MULTIPLIER_LIMIT
		and long_line.trick_history.size() == 8,
		"arcade economy: long chains retain their entry count, bounded multiplier and readable recent history")
	var bounded = Score.new()
	check.call(bounded.add_trick("Oversized", 9223372036854775807) == Score.MAX_EVENT_POINTS,
		"arcade economy: event values clamp before arithmetic and live meter earnings")
	bounded.combo_base = Score.MAX_SCORE - 20
	check.call(bounded.add_trick("Another", 100) == 20 and bounded.get_combo_value() == Score.MAX_SCORE,
		"arcade economy: accepted-point return values respect base saturation")
	check.call(bounded.add_hold_points(100) == 0 and bounded.add_spin_bonus(200) == 0,
		"arcade economy: score saturation cannot create fictitious bonus earnings")
	bounded.total_score = Score.MAX_SCORE - 10
	check.call(bounded.bank_combo() == Score.MAX_SCORE and bounded.total_score == Score.MAX_SCORE,
		"arcade economy: larger combo multipliers and banks still saturate without overflow")
	bounded.reset()
	check.call(bounded.combo_trick_count == 0 and bounded.combo_multiplier == 0
		and bounded.last_award == 0 and bounded.last_bonus == 0
		and bounded.last_banked_tricks.is_empty() and bounded.last_dropped_value == 0,
		"arcade economy: restart clears every live and outcome receipt")

static func _meter_cases(check: Callable) -> void:
	var meter = Meter.new()
	check.call(not meter.ready() and not meter.consume() and meter.value == 0.0,
		"live special: an empty performance state rejects use")
	check.call(is_equal_approx(meter.earn_trick(250), 25.0) and meter.value == 25.0
		and not meter.ready(), "live special: accepted unbanked trick points build partial charge")
	check.call(meter.earn_trick(0) == 0.0 and meter.earn_trick(-100) == 0.0 and meter.value == 25.0,
		"live special: rejected or zero-value moves cannot add charge")
	check.call(is_equal_approx(meter.earn_trick(9223372036854775807), 50.0)
		and meter.value == 75.0 and not meter.consume(),
		"live special: one oversized event has a bounded gain and cannot use partial charge")
	meter.earn_trick(250)
	check.call(meter.value == 100.0 and meter.active and meter.ready(),
		"live special: enough live points activate the sustained special state before banking")
	check.call(meter.consume() and meter.consume() and meter.value == 100.0,
		"live special: successful eligibility checks do not spend the full performance state")
	meter.tick(1.0)
	check.call(is_equal_approx(meter.value, 100.0 - 100.0 / 6.0) and meter.ready(),
		"live special: an active state remains usable while its meter drains below full")
	var before: float = meter.value
	check.call(meter.consume() and meter.value == before,
		"live special: a subsequent special can be accepted without one-shot meter consumption")
	meter.tick(5.0)
	check.call(meter.value == 0.0 and not meter.active and not meter.consume(),
		"live special: an unsupported sustained state expires after six active seconds")
	meter.value = 100.0
	meter.tick(6.0, true)
	check.call(is_equal_approx(meter.value, 50.0) and meter.ready(),
		"live special: continuing a real combo slows drain without making the state permanent")
	meter.tick(6.0, true)
	check.call(meter.value == 0.0 and not meter.ready(),
		"live special: even a held combo has a finite no-award special lifetime")
	meter.value = 100.0
	meter.tick(3.0)
	check.call(meter.earn_trick(500) == 50.0 and meter.value == 100.0 and meter.ready(),
		"live special: earned tricks refresh a sustained state instead of requiring a new bank")
	meter.on_bail()
	check.call(meter.value == 0.0 and not meter.active and not meter.ready(),
		"live special: a bail drops the live performance state")
	meter.earn_trick(250)
	meter.tick(2.0)
	check.call(meter.value == 25.0, "live special: partial charge has an explicit short idle grace")
	meter.tick(1.0)
	check.call(meter.value == 21.0, "live special: an idle partial charge decays after its grace")
	meter.earn_trick(100)
	meter.tick(2.0)
	check.call(meter.value == 31.0, "live special: another accepted move refreshes the partial-charge grace")
	meter.earn_trick(0)
	meter.tick(1.0)
	check.call(meter.value == 27.0, "live special: zero-value callbacks cannot stall idle decay")
	var stepped = Meter.new()
	stepped.earn_trick(250)
	for index in 60: stepped.tick(0.05)
	var single = Meter.new()
	single.earn_trick(250)
	single.tick(3.0)
	check.call(is_equal_approx(stepped.value, single.value),
		"live special: partial-charge decay is stable across split physics updates")
	meter.value = 100.0
	before = meter.value
	for delta in [0.0, -1.0, NAN, INF]: meter.tick(delta)
	check.call(meter.value == before and meter.ready(),
		"live special: unticked pauses and invalid deltas do not consume special time")
	meter.value = NAN
	check.call(not meter.ready() and meter.value == 0.0 and not meter.active,
		"live special: nonfinite public state resets without unlocking a special")
	meter.value = -20.0
	check.call(meter.earn_trick(25) == 2.5 and meter.value == 2.5,
		"live special: negative public state is bounded before earning")
	meter.earn_bank(25)
	check.call(meter.value == 5.0,
		"live special: old fixture helpers retain a bounded compatibility earning alias")
	meter.reset()
	check.call(meter.value == 0.0 and not meter.ready(),
		"live special: restart clears charge, idle clock and maintained readiness")
