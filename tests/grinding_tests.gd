extends RefCounted
## Actual input/physics/scoring integration on the production scene.

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var lines: Array = game.world.get_grind_lines()
	check.call(lines.size() == 2 and lines[0].is_valid and lines[1].is_valid,
		"world publishes two valid tracks matching the visible rails")
	await _start(tree, game, Vector3(12.15, 1.10, 11.5), Vector3(0, -1, -6))
	game.score.add_trick("Kickflip", 300)
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(game.skater.grinding and not game.skater.airborne,
		"descending aligned skater catches the real east rail while grind is held")
	check.call(game.score.trick_history.has("Rail Grind") and game.score.total_score == 0,
		"rail catch adds one trick and preserves the unbanked aerial combo")
	var value: int = game.score.get_combo_value()
	var z: float = game.skater.global_position.z
	await _frames(tree, 12)
	check.call(game.skater.grinding and game.skater.global_position.z < z - 0.5,
		"held grind advances along the visible rail")
	check.call(game.score.get_combo_value() == value,
		"holding a rail does not award entry points every physics tick")
	game.toggle_pause()
	var paused_position: Vector3 = game.skater.global_position
	var paused_balance: float = game.skater.grind_balance
	await _frames(tree, 5)
	check.call(game.skater.global_position.is_equal_approx(paused_position)
		and is_equal_approx(game.skater.grind_balance, paused_balance),
		"pause freezes rail travel and balance")
	game.toggle_pause()
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	check.call(not game.skater.grinding and game.skater.airborne and game.skater.velocity.y > 0,
		"ollie releases a held rail upward and cooldown prevents immediate recapture")
	Input.action_release("grind")
	await _frames(tree, 85)
	check.call(game.score.total_score > value and game.score.get_combo_value() == 0,
		"rail-to-ollie-to-ground combo banks exactly once on real landing")
	var banked: int = game.score.total_score
	await _frames(tree, 12)
	check.call(game.score.total_score == banked, "resting after rail combo cannot bank it again")

	await _start(tree, game, Vector3(12, 1.10, 6.0), Vector3(0, -1, 6))
	Input.action_press("grind")
	await _frames(tree, 3)
	z = game.skater.global_position.z
	await _frames(tree, 10)
	check.call(game.skater.grinding and game.skater.global_position.z > z,
		"the production rail can be ridden in the reverse direction")
	Input.action_release("grind")
	await _frames(tree, 2)
	check.call(not game.skater.grinding and game.skater.airborne,
		"releasing grind drops off without teleporting to spawn")

	await _start(tree, game, Vector3(12, 1.08, 5.75), Vector3(0, -1, -6))
	Input.action_press("grind")
	await _frames(tree, 12)
	check.call(not game.skater.grinding and game.skater.global_position.z < 5.25,
		"open rail endpoint releases into forward airborne travel without wrapping")
	Input.action_release("grind")

	await _start(tree, game, Vector3(12, 1.1, 10), Vector3(6, -1, 0))
	Input.action_press("grind")
	await _frames(tree, 2)
	check.call(not game.skater.grinding and not game.score.trick_history.has("Rail Grind"),
		"perpendicular travel does not snap or score a rail")
	Input.action_release("grind")

	await _start(tree, game, Vector3(0, 1.1, 10), Vector3(0, -1, -6))
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(not game.skater.grinding and game.score.get_combo_value() == 0,
		"grind input away from authored rails cannot generate points")
	Input.action_release("grind")

	# A real world-layer obstacle must reject the acquisition sweep.
	var wall := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.12, 3, 3)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	wall.add_child(collider)
	wall.position = Vector3(12.28, 1.5, 10)
	game.world.add_child(wall)
	await _frames(tree, 2)
	await _start(tree, game, Vector3(12.6, 1.1, 10), Vector3(0, -1, -6))
	Input.action_press("grind")
	await _frames(tree, 2)
	check.call(not game.skater.grinding and game.score.get_combo_value() == 0,
		"solid scenery between rider and rail prevents capture through a wall")
	Input.action_release("grind")
	wall.queue_free()
	await _frames(tree, 2)

	await _start(tree, game, Vector3(12, 1.08, 11.5), Vector3(0, -1, -3))
	game.score.total_score = 500
	Input.action_press("grind")
	await _frames(tree, 2)
	Input.action_press("steer_right")
	await _frames(tree, 85)
	check.call(not game.skater.grinding and game.score.get_combo_value() == 0
		and game.score.total_score == 500,
		"excessive rail lean bails and loses only the pending combo")
	Input.action_release("grind")
	Input.action_release("steer_right")

	await _start(tree, game, Vector3(12, 1.1, 11.5), Vector3(0, -1, -3))
	Input.action_press("grind")
	await _frames(tree, 2)
	game.time_remaining = 0.01
	await _frames(tree, 5)
	check.call(game.skater.grinding and not game.run_finished,
		"a pending rail combo receives the same bounded run overtime as air")
	await _frames(tree, 200)
	check.call(game.run_finished, "rail overtime still resolves within its three-second bound")
	Input.action_release("grind")
	game.restart_run()
	check.call(not game.skater.grinding and is_zero_approx(game.skater.grind_balance)
		and game.score.get_combo_value() == 0, "restart clears the rail state, balance and pending score")

static func _start(tree: SceneTree, game: Node, at: Vector3, motion: Vector3) -> void:
	Input.action_release("grind")
	Input.action_release("ollie")
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	game.restart_run()
	await _frames(tree, 2)
	game.skater.set_physics_process(false)
	game.skater.global_position = at
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide() # Refresh contact classification at the fixture position.
	game.skater.velocity = motion
	game.skater.speed = Vector2(motion.x, motion.z).length()
	game.skater.rotation.y = atan2(-motion.x, -motion.z)
	game.skater.airborne = true
	game.skater.set_physics_process(true)

static func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
