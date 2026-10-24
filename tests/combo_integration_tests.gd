extends RefCounted
## Independent real-input/physics checks for manuals, reverts and pending banks.

# The west approach has clear flat runout before the new gallery grade.
const FLAT_SPAWN := Vector3(-22.0, 0.8, 28.0)


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	if game.free_skate_mode:
		game.toggle_free_skate()
	game.skater.spawn_position = FLAT_SPAWN
	await _eligibility(tree, game, check)
	await _continuous_manual_line(tree, game, check)
	await _revert_windows(tree, game, check)
	await _manual_release_and_bail(tree, game, check)
	await _link_boundary(tree, game, check)
	await _manual_overtime(tree, game, check)
	_release_actions()
	game.skater.spawn_position = original_spawn
	game.restart_run()


static func _eligibility(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset_ground(tree, game)
	Input.action_press("manual")
	Input.action_press("revert")
	await _frames(tree, 2)
	check.call(not game.skater.manual_active and game.score.get_combo_value() == 0,
		"combo integration: stationary manual and out-of-window revert cannot award points")
	_release_actions()
	Input.action_press("push")
	await _frames(tree, 40)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("manual")
	await _frames(tree, 2)
	check.call(game.skater.airborne and not game.skater.manual_active
		and not game.score.trick_history.has("Manual"),
		"combo integration: fresh manual input cannot enter from the air")
	await _wait_landing(tree, game)
	await _frames(tree, 25)
	check.call(not game.skater.manual_active and game.score.total_score == 100,
		"combo integration: manual held from the air does not manufacture a landing entry")
	_release_actions()


static func _continuous_manual_line(tree: SceneTree, game: Node, check: Callable) -> void:
	await _moving_ground(tree, game)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("flip")
	await _frames(tree, 2)
	Input.action_release("flip")
	await _wait_landing(tree, game)
	check.call(game.score.pending_landing and game.score.total_score == 0
		and game.score.get_combo_value() == 800,
		"combo integration: real ollie and flip land into an unbanked 0.35-second link window")
	await _frames(tree, 6)
	_key(KEY_M, true)
	await _frames(tree, 2)
	check.call(game.skater.manual_active and not game.score.pending_landing
		and game.score.trick_history.count("Manual") == 1,
		"combo integration: mapped M key links the landing into one manual entry")
	await _balance_manual(tree, game, 40)
	check.call(game.skater.manual_active and game.score.total_score == 0
		and game.score.get_combo_value() == 1500,
		"combo integration: balanced held manual preserves the combo beyond the landing deadline")
	game.toggle_pause()
	var paused_position: Vector3 = game.skater.global_position
	var paused_balance: float = game.skater.manual_balance
	var paused_time: float = game.time_remaining
	await _frames(tree, 8)
	check.call(game.skater.global_position.is_equal_approx(paused_position)
		and is_equal_approx(game.skater.manual_balance, paused_balance)
		and is_equal_approx(game.time_remaining, paused_time),
		"combo integration: pause freezes manual movement, balance and run time")
	game.toggle_pause()
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	_key(KEY_M, false)
	check.call(game.skater.airborne and not game.skater.manual_active
		and not game.score.pending_landing and game.score.total_score == 0,
		"combo integration: ollie exits the manual into air without prematurely banking")
	Input.action_press("grab")
	await _frames(tree, 2)
	Input.action_release("grab")
	await _wait_landing(tree, game)
	check.call(game.score.combo_base == 800 and game.score.combo_multiplier == 5
		and game.score.pending_landing,
		"combo integration: air-manual-air sequence retains repeat degradation across links")
	await _frames(tree, 15)
	check.call(game.score.pending_landing and game.score.total_score == 0,
		"combo integration: 0.25 seconds of clean ground time is still inside the bank window")
	await _frames(tree, 10)
	check.call(game.score.total_score == 4000 and game.score.best_combo == 4000
		and game.score.get_combo_value() == 0 and not game.score.pending_landing,
		"combo integration: the complete five-entry line banks exactly 4000 after the deadline")
	await _frames(tree, 20)
	check.call(game.score.total_score == 4000,
		"combo integration: continued ground travel cannot bank the linked line twice")


static func _revert_windows(tree: SceneTree, game: Node, check: Callable) -> void:
	await _moving_ground(tree, game)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("revert")
	await _frames(tree, 2)
	check.call(not game.score.trick_history.has("Revert"),
		"combo integration: an early aerial revert press is rejected")
	await _wait_landing(tree, game)
	await _frames(tree, 2)
	check.call(not game.score.trick_history.has("Revert"),
		"combo integration: holding an early revert does not queue a landing award")
	Input.action_release("revert")
	await _frames(tree, 1)
	var speed_before: float = game.skater.speed
	var window_before: float = game.score.landing_remaining
	Input.action_press("revert")
	await _frames(tree, 1)
	Input.action_release("revert")
	check.call(game.score.trick_history.count("Revert") == 1
		and game.skater.speed < 0.0 and absf(game.skater.speed) < speed_before * 0.87
		and absf(game.skater.speed) > speed_before * 0.82,
		"combo integration: a valid fresh landing revert scores once and costs 15 percent speed")
	check.call(game.score.pending_landing and game.score.landing_remaining < window_before,
		"combo integration: revert consumes the original bank window without refreshing it")
	await _frames(tree, 1)
	Input.action_press("revert")
	await _frames(tree, 2)
	Input.action_release("revert")
	check.call(game.score.trick_history.count("Revert") == 1,
		"combo integration: repeated fresh revert presses cannot score twice on one landing")
	await _frames(tree, 25)
	check.call(game.score.total_score == 500 and not game.score.pending_landing,
		"combo integration: revert alone cannot keep an ollie combo alive indefinitely")
	Input.action_press("revert")
	await _frames(tree, 2)
	Input.action_release("revert")
	check.call(game.score.total_score == 500 and game.score.get_combo_value() == 0,
		"combo integration: late revert after the landing window cannot open a new combo")


static func _manual_release_and_bail(tree: SceneTree, game: Node, check: Callable) -> void:
	await _moving_ground(tree, game)
	Input.action_press("manual")
	await _frames(tree, 2)
	Input.action_release("manual")
	await _frames(tree, 1)
	check.call(not game.skater.manual_active and game.score.pending_landing,
		"combo integration: clean manual release opens a single pending bank")
	Input.action_press("manual")
	await _frames(tree, 1)
	check.call(not game.skater.manual_active,
		"combo integration: immediate manual reentry is blocked by its cooldown")
	await _frames(tree, 25)
	check.call(not game.skater.manual_active and game.score.total_score == 100,
		"combo integration: holding through cooldown cannot farm manual entry or postpone banking")
	Input.action_release("manual")
	await _frames(tree, 1)
	Input.action_press("manual")
	await _frames(tree, 2)
	check.call(game.skater.manual_active and game.score.combo_base == 50,
		"combo integration: fresh eligible manual after a bank retains run-level repeat degradation")
	var bail_count: Array[int] = [0]
	var on_bail := func() -> void: bail_count[0] += 1
	game.skater.bailed.connect(on_bail)
	Input.action_press("steer_right")
	await _frames(tree, 65)
	check.call(bail_count[0] == 1 and not game.skater.manual_active
		and game.score.total_score == 100 and game.score.get_combo_value() == 0,
		"combo integration: failed manual balance bails once and preserves only the previous bank")
	game.skater.bailed.disconnect(on_bail)
	_release_actions()


static func _link_boundary(tree: SceneTree, game: Node, check: Callable) -> void:
	await _moving_ground(tree, game)
	await _ollie_and_land(tree, game)
	await _frames(tree, 15)
	await _ollie_and_land(tree, game)
	await _frames(tree, 25)
	check.call(game.score.total_score == 300,
		"combo integration: an ollie inside the window links two entries with repeat degradation")
	await _moving_ground(tree, game)
	await _ollie_and_land(tree, game)
	await _frames(tree, 25)
	await _ollie_and_land(tree, game)
	await _frames(tree, 25)
	check.call(game.score.total_score == 150,
		"combo integration: an ollie after the bank starts a new combo while retaining run-level staleness")


static func _manual_overtime(tree: SceneTree, game: Node, check: Callable) -> void:
	await _moving_ground(tree, game)
	Input.action_press("manual")
	await _frames(tree, 2)
	game.time_remaining = 0.01
	await _frames(tree, 3)
	check.call(game.skater.manual_active and not game.run_finished,
		"combo integration: an already active manual receives bounded overtime")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(game.skater.manual_active and not game.skater.airborne
		and game.score.combo_base == 100,
		"combo integration: overtime blocks starting an ollie link from a manual")
	Input.action_release("manual")
	await _frames(tree, 30)
	check.call(game.run_finished and game.score.total_score == 100
		and game.score.get_combo_value() == 0,
		"combo integration: clean overtime manual release completes its pending bank before results")
	await _moving_ground(tree, game)
	Input.action_press("manual")
	await _frames(tree, 2)
	game.time_remaining = 0.01
	await _balance_manual(tree, game, 200)
	check.call(game.run_finished and game.score.total_score == 0
		and game.score.get_combo_value() == 0,
		"combo integration: maintained manual cannot extend the three-second overtime deadline")
	await _moving_ground(tree, game)
	Input.action_press("ollie")
	await _frames(tree, 3)
	Input.action_release("ollie")
	await _frames(tree, 1)
	game.time_remaining = 0.01
	await _wait_landing(tree, game)
	Input.action_press("manual")
	await _frames(tree, 2)
	check.call(not game.skater.manual_active and not game.score.trick_history.has("Manual"),
		"combo integration: a fresh manual cannot enter after expiry even inside a landing window")
	Input.action_release("manual")
	await _frames(tree, 25)
	check.call(game.run_finished and game.score.total_score == 100,
		"combo integration: rejected overtime link still permits the earned ollie to bank")


static func _reset_ground(tree: SceneTree, game: Node) -> void:
	_release_actions()
	game.restart_run()
	await _frames(tree, 45)


static func _moving_ground(tree: SceneTree, game: Node) -> void:
	await _reset_ground(tree, game)
	Input.action_press("push")
	await _frames(tree, 40)
	Input.action_release("push")


static func _ollie_and_land(tree: SceneTree, game: Node) -> void:
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	await _wait_landing(tree, game)


static func _wait_landing(tree: SceneTree, game: Node) -> void:
	for i in range(90):
		await _frames(tree, 1)
		if game.skater.is_on_floor() and not game.skater.airborne:
			return


static func _balance_manual(tree: SceneTree, game: Node, count: int) -> void:
	for i in range(count):
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if game.skater.manual_balance > 0.025:
			Input.action_press("steer_left", 0.3)
		elif game.skater.manual_balance < -0.025:
			Input.action_press("steer_right", 0.3)
		await _frames(tree, 1)
	Input.action_release("steer_left")
	Input.action_release("steer_right")


static func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


static func _release_actions() -> void:
	_key(KEY_M, false)
	for action in InputMap.get_actions():
		Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame
		await tree.process_frame
