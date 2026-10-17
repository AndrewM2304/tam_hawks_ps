extends RefCounted
## Independent regressions for capture reached by play, blocked rides and timeout.


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	_release_actions()
	if game.free_skate_mode:
		game.toggle_free_skate()
	await _ground_approach_and_obstruction(tree, game, check)
	game.skater.spawn_position = original_spawn
	await _overtime_admission(tree, game, check)
	_release_actions()
	game.restart_run()


static func _ground_approach_and_obstruction(tree: SceneTree, game: Node, check: Callable) -> void:
	# Establish a real supported approach, then use ordinary actions throughout
	# takeoff/capture. No airborne state, speed or travel velocity is injected.
	game.skater.spawn_position = Vector3(12.0, 0.8, 20.0)
	game.restart_run()
	await _frames(tree, 40)
	check.call(game.skater.is_on_floor() and not game.skater.airborne,
		"grind regression: ground approach starts with real floor support")
	game.score.add_trick("Previously banked", 500)
	game.score.bank_combo()
	Input.action_press("push")
	Input.action_press("grind")
	await _frames(tree, 50)
	check.call(not game.skater.grinding and game.skater.is_on_floor()
		and game.skater.speed > 5.0 and game.score.get_combo_value() == 0,
		"grind regression: grounded push builds speed without snapping or scoring a rail")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	Input.action_release("push")
	var peak_height: float = game.skater.global_position.y
	var caught: bool = false
	for i in range(75):
		await _frames(tree, 1)
		peak_height = maxf(peak_height, game.skater.global_position.y)
		if game.skater.grinding:
			caught = true
			break
	check.call(caught and peak_height > 1.5,
		"grind regression: real push and ollie descend into an eligible rail catch")
	check.call(game.score.trick_history.has("Ollie")
		and game.score.trick_history.has("Rail Grind") and game.score.total_score == 500,
		"grind regression: played approach links ollie and rail without banking early")
	if caught:
		var bail_count: Array[int] = [0]
		var on_bail := func() -> void: bail_count[0] += 1
		game.skater.bailed.connect(on_bail)
		var wall := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(4.0, 4.0, 0.3)
		collider.shape = shape
		wall.add_child(collider)
		wall.position = game.skater.global_position + Vector3(0.0, 1.0, -1.5)
		game.world.add_child(wall)
		await _frames(tree, 30)
		check.call(bail_count[0] == 1 and not game.skater.grinding,
			"grind regression: scenery blocking an active ride produces exactly one bail")
		check.call(game.score.total_score == 500 and game.score.get_combo_value() == 0,
			"grind regression: obstructed ride loses its pending combo and preserves prior bank")
		check.call(game.skater.global_position.distance_to(game.skater.spawn_position) < 1.0,
			"grind regression: obstructed ride recovers at the supported spawn")
		game.skater.bailed.disconnect(on_bail)
		wall.queue_free()
		await _frames(tree, 2)
	_release_actions()


static func _overtime_admission(tree: SceneTree, game: Node, check: Callable) -> void:
	# Pre-position only for precise timeout-boundary checks; approach was tested
	# entirely through played movement above.
	await _air_fixture(tree, game, Vector3(-6, 5, 24), Vector3.ZERO)
	game.score.add_trick("Existing combo", 100)
	game.time_remaining = 0.01
	await _frames(tree, 3)
	Input.action_press("flip")
	Input.action_press("grab")
	Input.action_press("spin_right")
	await _frames(tree, 12)
	_release_actions()
	check.call(not game.run_finished and game.score.combo_base == 100,
		"grind regression: overtime rejects fresh aerial flip and grab entries")
	await _frames(tree, 60)
	check.call(game.run_finished and game.score.total_score == 100,
		"grind regression: fresh overtime spin cannot increase the landing award")

	await _air_fixture(tree, game, Vector3(12, 1.1, 11.5), Vector3(0, -1, -6))
	game.score.add_trick("Existing combo", 100)
	game.time_remaining = 0.01
	await _frames(tree, 3)
	Input.action_press("grind")
	await _frames(tree, 2)
	check.call(not game.skater.grinding and not game.score.trick_history.has("Rail Grind")
		and game.score.combo_base == 100,
		"grind regression: overtime rejects a fresh otherwise eligible rail attachment")
	_release_actions()

	await _air_fixture(tree, game, Vector3(12, 1.1, 11.5), Vector3(0, -1, -6))
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(game.skater.grinding, "grind regression: timeout fixture begins on a valid active rail")
	var rail_combo: int = game.score.get_combo_value()
	game.time_remaining = 0.01
	await _frames(tree, 3)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	check.call(game.skater.grinding and game.score.get_combo_value() == rail_combo
		and game.skater.velocity.y < 0.1,
		"grind regression: overtime cannot start a new scored rail ollie")
	Input.action_release("grind")
	await _frames(tree, 1)
	Input.action_press("grind")
	await _frames(tree, 2)
	Input.action_release("grind")
	check.call(not game.skater.grinding and game.skater.airborne,
		"grind regression: overtime still permits releasing an existing rail")
	await _frames(tree, 60)
	check.call(game.run_finished and game.score.total_score == rail_combo
		and game.score.get_combo_value() == 0,
		"grind regression: released overtime rail combo banks once on physical landing")

	await _air_fixture(tree, game, Vector3(-6, 6, 24), Vector3.ZERO)
	game.score.add_trick("Existing combo", 100)
	Input.action_press("spin_right")
	await _frames(tree, 30)
	Input.action_release("spin_right")
	game.time_remaining = 0.01
	await _frames(tree, 60)
	check.call(game.run_finished and game.score.total_score == 600,
		"grind regression: a spin completed before expiry still resolves in the landing combo")


static func _air_fixture(tree: SceneTree, game: Node, at: Vector3, motion: Vector3) -> void:
	_release_actions()
	game.restart_run()
	await _frames(tree, 2)
	game.skater.set_physics_process(false)
	game.skater.global_position = at
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = motion
	game.skater.speed = Vector2(motion.x, motion.z).length()
	game.skater.airborne = true
	game.skater.set_physics_process(true)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame
		await tree.process_frame


static func _release_actions() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
