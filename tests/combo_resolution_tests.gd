extends RefCounted
## Timing and arithmetic checks for authoritative combo resolution.

const Score = preload("res://game/scoring/score_session.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")


static func run(check: Callable) -> void:
	var empty = Score.new()
	empty.begin_landing()
	check.call(not empty.pending_landing and empty.landing_remaining == 0.0
		and empty.tick(1.0) == 0, "combo resolution: landing without a combo creates no deadline")
	var score = _pending()
	check.call(score.pending_landing and is_equal_approx(score.landing_remaining, 0.35)
		and score.total_score == 0, "combo resolution: clean landing starts the 0.35-second pending window")
	check.call(score.tick(0.349) == 0 and score.pending_landing and score.total_score == 0,
		"combo resolution: the combo remains pending immediately before the deadline")
	check.call(score.tick(0.001) == 100 and not score.pending_landing
		and score.landing_remaining == 0.0 and score.total_score == 100,
		"combo resolution: expiry banks once and clears its deadline")
	check.call(score.tick(10.0) == 0 and score.total_score == 100 and score.last_banked == 100,
		"combo resolution: later ticks cannot duplicate the bank or erase its feedback")
	var exact = _pending()
	check.call(exact.tick(0.35) == 100 and exact.best_combo == 100,
		"combo resolution: one update exactly at the deadline awards the combo")
	var overrun = _pending()
	check.call(overrun.tick(1.0) == 100 and overrun.tick(1.0) == 0,
		"combo resolution: an update crossing the deadline resolves once")
	var stepped = _pending()
	var stepped_award: int = 0
	for index in range(21):
		stepped_award += stepped.tick(1.0 / 60.0)
	check.call(stepped_award == 100 and not stepped.pending_landing,
		"combo resolution: 21 physics steps expire 0.35 seconds without floating-point delay")

	var duplicate = _pending()
	duplicate.tick(0.2)
	duplicate.begin_landing()
	check.call(is_equal_approx(duplicate.landing_remaining, 0.15)
		and duplicate.tick(0.15) == 100, "combo resolution: repeated landing notifications cannot refresh the window")
	var revert = _pending()
	revert.tick(0.2)
	revert.add_trick("Revert", 150)
	check.call(revert.pending_landing and is_equal_approx(revert.landing_remaining, 0.15)
		and revert.tick(0.15) == 500, "combo resolution: a revert adds points without refreshing the deadline")
	var linked = _pending()
	linked.tick(0.2)
	linked.continue_combo()
	check.call(not linked.pending_landing and linked.landing_remaining == 0.0
		and linked.tick(20.0) == 0 and linked.get_combo_value() == 100,
		"combo resolution: a valid movement link suspends banking without losing points")
	linked.add_trick("Rail Grind", 200)
	linked.begin_landing()
	check.call(is_equal_approx(linked.landing_remaining, Catalog.LANDING_LINK_SECONDS)
		and linked.tick(0.35) == 600, "combo resolution: the next real landing starts a fresh window for the linked combo")

	var bailed = _pending()
	bailed.tick(0.349)
	bailed.drop_combo()
	check.call(not bailed.pending_landing and bailed.landing_remaining == 0.0
		and bailed.tick(1.0) == 0 and bailed.total_score == 0 and bailed.last_banked == 0,
		"combo resolution: a bail before expiry discards the combo and its pending award")
	var direct_bank = _pending()
	check.call(direct_bank.bank_combo() == 100 and not direct_bank.pending_landing
		and direct_bank.tick(1.0) == 0, "combo resolution: explicit bank clears the pending timer too")
	var reset = _pending()
	reset.tick(0.2)
	reset.reset()
	check.call(not reset.pending_landing and reset.landing_remaining == 0.0
		and reset.tick(1.0) == 0 and reset.total_score == 0,
		"combo resolution: restarting cannot retain a delayed score award")
	var paused = _pending()
	paused.tick(0.2)
	var paused_remaining: float = paused.landing_remaining
	# Pause has no wall-clock callback: the owner stops supplying active physics deltas.
	check.call(paused.tick(0.0) == 0 and paused.landing_remaining == paused_remaining
		and paused.tick(0.15) == 100, "combo resolution: unticked or zero-delta pause preserves the remaining active time")
	for invalid_delta in [-0.1, NAN, INF, -INF]:
		var invalid = _pending()
		invalid.tick(0.2)
		check.call(invalid.tick(invalid_delta) == 0 and invalid.pending_landing
			and is_equal_approx(invalid.landing_remaining, 0.15) and invalid.tick(0.15) == 100,
			"combo resolution: invalid delta cannot consume, extend or poison the deadline")

	var repeated = Score.new()
	for index in range(7):
		repeated.add_trick("Kickflip", 100)
	check.call(repeated.combo_base == 205 and repeated.combo_multiplier == 7,
		"combo resolution: repeat reduction stays at one sixteenth after four halvings")
	repeated.add_trick("Spin 180", 200)
	repeated.add_trick("Spin 360", 400)
	check.call(repeated.combo_base == 805 and repeated.combo_multiplier == 9,
		"combo resolution: existing dynamic spin names retain distinct repeat identities")
	var bounded = Score.new()
	bounded.add_trick("Oversized caller", 9223372036854775807)
	check.call(bounded.combo_base == Score.MAX_EVENT_POINTS,
		"combo resolution: event awards clamp before float conversion or accumulation")
	bounded.combo_base = Score.MAX_SCORE - 50
	bounded.add_trick("Other trick", 100)
	check.call(bounded.combo_base == Score.MAX_SCORE and bounded.get_combo_value() == Score.MAX_SCORE,
		"combo resolution: combo arithmetic saturates without integer overflow")
	bounded.total_score = Score.MAX_SCORE - 10
	check.call(bounded.bank_combo() == Score.MAX_SCORE and bounded.total_score == Score.MAX_SCORE
		and bounded.best_combo == Score.MAX_SCORE, "combo resolution: total and best records respect the documented portable cap")
	var invalid_award = _pending()
	invalid_award.add_trick("   ", 100)
	invalid_award.add_trick("invalid", 0)
	invalid_award.add_trick("invalid", -100)
	check.call(invalid_award.get_combo_value() == 100 and invalid_award.tick(0.35) == 100,
		"combo resolution: malformed awards cannot alter a pending combo")


static func _pending() -> RefCounted:
	var score = Score.new()
	score.add_trick("Ollie", 100)
	score.begin_landing()
	return score
