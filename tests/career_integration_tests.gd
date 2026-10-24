extends RefCounted
## Production-scene career, objective, gap and special wiring. Never saves profiles.

const CareerSource = preload("res://game/progression/career_progress.gd")
const SAFE_SPAWN := Vector3(5, 0.8, 24)


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_career = game.career
	var original_spawn: Vector3 = game.skater.spawn_position
	game.persistence_enabled = false
	game.career = CareerSource.new()
	if game.free_skate_mode:
		game.toggle_free_skate()
	await _objectives_and_free_skate(tree, game, check)
	await _special_admission(tree, game, check)
	await _physical_gap_and_reset(tree, game, check)
	_release_actions()
	game.career = original_career
	game.skater.spawn_position = original_spawn
	if game.free_skate_mode:
		game.toggle_free_skate()
	game.restart_run()


static func _objectives_and_free_skate(tree: SceneTree, game: Node, check: Callable) -> void:
	var letter: Dictionary = _marker(game, "letter", "H")
	check.call(not letter.is_empty(), "career integration: level publishes the H objective marker")
	await _reset_at(tree, game, letter.position + Vector3(0, 0.3, 3))
	Input.action_press("push")
	await _frames(tree, 40)
	Input.action_release("push")
	check.call(_progress(game, "letters") == 1,
		"career integration: actual skating through the world marker collects one letter")
	await _frames(tree, 6)
	check.call(_progress(game, "letters") == 1,
		"career integration: remaining near a collected marker cannot duplicate progress")
	var cone: Dictionary = _marker(game, "interaction", "cone")
	await _reset_at(tree, game, cone.position + Vector3(0, 0.3, 3))
	Input.action_press("push")
	await _frames(tree, 30)
	Input.action_release("push")
	check.call(not game.career.completed_ids.has("cone"),
		"career integration: passing near the cone requires an explicit interaction")
	_key(KEY_X, true)
	await _frames(tree, 1)
	_key(KEY_X, false)
	await _frames(tree, 2)
	check.call(game.career.completed_ids.has("cone"),
		"career integration: mapped X input completes the nearby cone interaction")
	game.restart_run()
	check.call(game.career.completed_ids.has("cone") and _progress(game, "letters") == 0,
		"career integration: restart clears run collections and retains completed career goals")
	var completed_before: Array = game.career.completed_ids.duplicate()
	var best_before: int = game.career.best_score
	game.toggle_free_skate()
	game.skater.spawn_position = letter.position + Vector3(0, 0.3, 3)
	game.restart_run()
	await _frames(tree, 45)
	Input.action_press("push")
	await _frames(tree, 40)
	Input.action_release("push")
	# Resolve an actual pending bank through main's fixed-step session update.
	game.score.add_trick("Free skate fixture", 20000)
	game.score.begin_landing()
	await _frames(tree, 25)
	check.call(game.score.total_score == 20000 and _progress(game, "letters") == 0
		and game.career.completed_ids == completed_before and game.career.best_score == best_before,
		"career integration: free-skate collection and banking do not grant career progress or records")
	check.call(not game.persistence_enabled,
		"career integration: automated scene checks keep profile persistence disabled")
	game.toggle_free_skate()


static func _special_admission(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset_at(tree, game, SAFE_SPAWN)
	game.career.completed_ids.erase("first_shift")
	game.career.completed_ids.erase("one_long_line")
	_fill_meter(game)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	var locked_charge: float = game.special_meter.value
	_key(KEY_U, true)
	_key(KEY_U, false)
	await _frames(tree, 2)
	check.call(game.special_meter.ready() and game.special_meter.value >= locked_charge - 1.0
		and not game.score.trick_history.has("Clyde Carousel"),
		"career integration: locked special input retains active charge and cannot award points")
	game.career.completed_ids.append("first_shift")
	game.special_meter.reset()
	game.special_meter.earn_trick(500)
	_key(KEY_U, true)
	_key(KEY_U, false)
	await _frames(tree, 2)
	check.call(game.special_meter.value == 50.0
		and not game.score.trick_history.has("Clyde Carousel"),
		"career integration: unlocked special still requires a full meter")
	await _reset_at(tree, game, SAFE_SPAWN)
	_fill_meter(game)
	_key(KEY_U, true)
	_key(KEY_U, false)
	await _frames(tree, 2)
	check.call(game.skater.is_on_floor() and game.special_meter.ready() and game.special_meter.value > 99.0
		and game.score.get_combo_value() == 0,
		"career integration: a grounded special request cannot spend its charge")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	_key(KEY_U, true)
	_key(KEY_U, false)
	await _frames(tree, 2)
	check.call(game.skater.airborne and game.special_meter.ready() and game.special_meter.value > 90.0
		and game.score.trick_history.count("Clyde Carousel") == 1,
		"career integration: mapped U input performs an unlocked aerial special while special mode remains active")
	_fill_meter(game)
	_key(KEY_U, true)
	_key(KEY_U, false)
	await _frames(tree, 2)
	check.call(game.special_meter.ready() and game.special_meter.value > 99.0
		and game.score.trick_history.count("Clyde Carousel") == 1,
		"career integration: an immediate request during the special animation cannot award again")
	await _frames(tree, 80)
	check.call(game.score.total_score == 2200,
		"career integration: the earned special joins the ollie and banks through real landing")
	game.restart_run()
	check.call(game.special_meter.value == 0.0 and game.career.unlocks().has("special_clyde_carousel")
		and game.score.total_score == 0,
		"career integration: restart clears run score and meter while keeping career unlocks")


static func _physical_gap_and_reset(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset_at(tree, game, Vector3(-94, 2.8, 30))
	var definition: Dictionary = {}
	for entry: Dictionary in game.world.get_gap_definitions():
		if entry.id == "central_gap":
			definition = entry
	check.call(not definition.is_empty(), "career integration: central platform gap has authored trigger geometry")
	# This initial fixture rests on the grade. Stop its genuine downhill roll
	# before pushing uphill; backwards travel now remains functional fakie.
	Input.action_press("brake")
	await _frames(tree, 6)
	Input.action_release("brake")
	Input.action_press("push")
	var reached_takeoff: bool = false
	for i in range(240):
		await _frames(tree, 1)
		if game.skater.global_position.z <= 4.5 and game.skater.is_on_floor():
			reached_takeoff = true
			break
	check.call(reached_takeoff and game.skater.global_position.y > 4.8,
		"career integration: actual push-driven approach climbs onto the Central platform")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_release("push")
	var awarded: bool = false
	for i in range(90):
		await _frames(tree, 1)
		if game.score.trick_history.has(definition.name):
			awarded = true
			break
	check.call(awarded and game.skater.airborne
		and game.score.trick_history.count(definition.name) == 1,
		"career integration: a physical platform ollie crosses both gap triggers and awards once")
	check.call(game.career.completed_ids.has("platform_change"),
		"career integration: the real Central gap event completes its career goal")
	await _frames(tree, 55)
	var banked: int = game.score.total_score
	check.call(banked >= 1400 and game.score.get_combo_value() == 0,
		"career integration: physical gap points and ollie resolve through the landing bank")
	await _frames(tree, 10)
	check.call(game.score.total_score == banked,
		"career integration: continued travel after the gap cannot award or bank it twice")
	# Isolate bail-signal wiring after verifying the real route above. Arm the
	# public helper, emit the production bail signal, then query its former end.
	game.gaps.reset()
	var direction: Vector3 = (definition.end - definition.start).normalized()
	game.gaps.update(definition.start - direction * 3.0, true, 0.016)
	game.gaps.update(definition.start, true, 0.1)
	game.score.add_trick("Pending bail fixture", 100)
	game.skater.bailed.emit()
	var stale_awards: Array = game.gaps.update(definition.end, true, 0.1)
	check.call(stale_awards.is_empty() and game.score.total_score == banked
		and game.score.get_combo_value() == 0,
		"career integration: main bail wiring resets an armed gap and drops only pending score")
	game.restart_run()
	check.call(game.career.completed_ids.has("platform_change") and game.score.total_score == 0,
		"career integration: restart retains the completed gap goal and resets run scoring")


static func _marker(game: Node, kind: String, id: String) -> Dictionary:
	for entry: Dictionary in game.world.get_goal_markers():
		if entry.kind == kind and entry.id == id:
			return entry
	return {}


static func _progress(game: Node, id: String) -> int:
	for goal: Dictionary in game.career.goals_snapshot():
		if goal.id == id:
			return goal.progress
	return -1


static func _fill_meter(game: Node) -> void:
	game.special_meter.reset()
	game.special_meter.earn_trick(500)
	game.special_meter.earn_trick(500)


static func _reset_at(tree: SceneTree, game: Node, at: Vector3) -> void:
	_release_actions()
	game.skater.spawn_position = at
	game.restart_run()
	await _frames(tree, 45)


static func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


static func _release_actions() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame
		await tree.process_frame
