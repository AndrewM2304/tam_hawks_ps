extends RefCounted
## Production Main, original level geometry and real input. Only each restart's
## initial spawn/heading is declared; the complete transition process is native.

const SPAWN := Vector3(-85, 6.8, -130)

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	await _air_return(tree, game, check)
	await _lip_process(tree, game, check)
	await _air_grind(tree, game, check)
	await _deck_transfer(tree, game, check)
	_release()
	game.skater.spawn_position = original_spawn
	game.restart_run()


static func _air_return(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	var evidence := {"bails": 0, "landings": [], "tricks": []}
	var on_bail := func(): evidence.bails += 1
	var on_land := func(clean: bool): evidence.landings.append(clean)
	var on_trick := func(label: String, _points: int): evidence.tricks.append(label)
	game.skater.bailed.connect(on_bail)
	game.skater.landed.connect(on_land)
	game.skater.trick_performed.connect(on_trick)
	var launched := await _approach_air(tree, game)
	check.call(launched and evidence.bails == 0 and game.skater.global_position.y >= 8.39,
		"transition player: actual push approach launches from the true promenade vertical lip")
	if launched:
		Input.action_release("push")
		var before: float = game.skater.velocity.y
		await _frames(tree, 1)
		check.call(absf((before - game.skater.velocity.y) - 22.0 / 60.0) < 0.005,
			"transition player: associated vert air applies full gravity exactly once per physics step")
		Input.action_press("ollie")
		await _frames(tree, 2)
		check.call(not game.skater.crouching and absf(game.skater.velocity.x) < 0.01,
			"transition player: held ollie in associated air cannot crouch or invent a directional transfer")
		Input.action_release("ollie")
		await _frames(tree, 1)
		check.call(evidence.tricks.is_empty() and game.score.get_combo_value() == 0,
			"transition player: ordinary vertical takeoff manufactures no ollie or automatic spin award")
		Input.action_press("flip")
		await _frames(tree, 2)
		Input.action_release("flip")
		var peak: float = game.skater.global_position.y
		var camera_valid := true
		var reentered := false
		for i in 140:
			await _frames(tree, 1)
			peak = maxf(peak, game.skater.global_position.y)
			camera_valid = camera_valid and game.skater.get_node("ChaseCamera").global_position.is_finite()
			if game.skater.transition_active and game.skater._feature_transition.state == "surface" and not game.skater.airborne:
				reentered = true
				break
			if evidence.bails > 0: break
		check.call(reentered and evidence.bails == 0 and evidence.landings == [true],
			"transition player: descending real contact finishes one clean airborne trick segment")
		check.call(peak > 10.4 and camera_valid,
			"transition player: actual apex rises above the deck with a finite chase-camera path")
		check.call(game.score.pending_landing and game.score.total_score == 0
			and not game._combo_link_active() and evidence.tricks.size() == 1,
			"transition player: a flip returning to curved support opens the normal bank deadline")
		var window: float = game.score.landing_remaining
		await _frames(tree, 4)
		check.call(game.score.landing_remaining < window and not game.skater.airborne,
			"transition player: continued supported descent cannot refresh its landing window")
		await _frames(tree, 50)
		var banked: int = game.score.total_score
		check.call(banked > 0 and game.score.get_combo_value() == 0
			and not game.skater.transition_active and evidence.landings == [true],
			"transition player: the flip banks once through the physical toe exit")
		await _frames(tree, 20)
		check.call(game.score.total_score == banked and evidence.landings == [true],
			"transition player: ordinary rollout cannot duplicate the vert landing or its bank")
	game.skater.bailed.disconnect(on_bail)
	game.skater.landed.disconnect(on_land)
	game.skater.trick_performed.disconnect(on_trick)


static func _lip_process(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	Input.action_press("grind")
	Input.action_press("push")
	var caught := false
	for i in 160:
		await _frames(tree, 1)
		if game.skater.lip_active:
			caught = true
			break
	check.call(caught and absf(game.skater.global_position.y - 8.472) < 0.01
		and game.score.trick_history.count("Lip Stall") == 1,
		"transition player: held grind catches and names the actual coping once")
	if not caught: return
	Input.action_release("push")
	await _frames(tree, 20)
	check.call(game.skater.lip_active and game.score.total_score == 0
		and not game.score.pending_landing and game.score.trick_history.count("Lip Stall") == 1,
		"transition player: a held balanced lip preserves its link without repeated stall awards")
	game.toggle_pause()
	var position: Vector3 = game.skater.global_position
	var balance: float = game.skater.lip_balance
	await _frames(tree, 8)
	check.call(game.skater.global_position == position and game.skater.lip_balance == balance,
		"transition player: production pause freezes coping position and balance")
	game.toggle_pause()
	Input.action_release("grind")
	await _frames(tree, 1)
	check.call(not game.skater.lip_active and game.skater.transition_active
		and game.score.pending_landing and not game._combo_link_active(),
		"transition player: release starts the bank window on actual supported drop-in")
	await _frames(tree, 24)
	check.call(game.skater.transition_active and game.skater._feature_transition.state == "surface"
		and game.score.total_score > 0 and game.score.get_combo_value() == 0,
		"transition player: ordinary curved support cannot keep a released lip combo alive forever")
	await _frames(tree, 80)
	check.call(not game.skater.transition_active
		and game.skater.get_node("BodyCollision").position.is_equal_approx(Vector3(0, 0.85, 0)),
		"transition player: actual lip drop-out restores the normal collision capsule at the toe")


static func _air_grind(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	var launched := await _approach_air(tree, game)
	if launched:
		Input.action_release("push")
		Input.action_press("steer_right")
		await _frames(tree, 32)
		Input.action_release("steer_right")
		Input.action_press("grind")
		var captured := false
		for i in 90:
			await _frames(tree, 1)
			if game.skater.grinding:
				captured = true
				break
		check.call(captured and game.skater._grind.line.id.contains("KelvingrovePromenadeQuarter")
			and not game.skater.transition_active,
			"transition player: deliberate lateral vert air can hand off to the real coping grind")
		check.call(game.skater.get_node("BodyCollision").position.is_equal_approx(Vector3(0, 0.85, 0)),
			"transition player: successful coping capture restores upright collision before rail motion")
	else:
		check.call(false, "transition player: coping-grind approach must first reach real vert air")
	_release()


static func _deck_transfer(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	var launched := await _approach_air(tree, game)
	if launched:
		await _frames(tree, 5)
		check.call(absf(game.skater.velocity.x) < 0.01,
			"transition player: held approach push cannot accidentally transfer over the deck")
		Input.action_release("push")
		await _frames(tree, 2)
		Input.action_press("push")
		Input.action_press("ollie")
		var detached := false
		for i in 50:
			await _frames(tree, 1)
			if not game.skater.transition_active:
				detached = true
				break
		check.call(detached and game.skater.global_position.x < -98.95 and game.skater.velocity.x < -1.0,
			"transition player: a fresh airborne push deliberately transfers across the physical deck")
		Input.action_release("push")
		Input.action_release("ollie")
		var outgoing_y: float = game.skater.velocity.y
		await _frames(tree, 1)
		check.call(absf((outgoing_y - game.skater.velocity.y) - game.skater.GRAVITY / 60.0) < 0.005,
			"transition player: first ordinary transfer frame retains vertical momentum and applies gravity once")
		check.call(game.skater.airborne and game.skater._coyote_remaining == 0.0
			and not game.skater.crouching and game.score.get_combo_value() == 0,
			"transition player: stale transition floor flags cannot grant a coyote pop on airborne ollie release")
		for i in 90:
			await _frames(tree, 1)
			if game.skater.is_on_floor() and not game.skater.airborne: break
		check.call(not game.skater.transition_active and not game.skater.airborne
			and game.skater.global_position.y > 8.38,
			"transition player: deck transfer completes an ordinary real landing above the quay")
	else:
		check.call(false, "transition player: deck-transfer approach must first reach real vert air")
	_release()


static func _approach_air(tree: SceneTree, game: Node) -> bool:
	Input.action_press("push")
	for i in 160:
		await _frames(tree, 1)
		if game.skater.transition_active and game.skater._feature_transition.state == "air" and game.skater.airborne:
			return true
	return false


static func _reset(tree: SceneTree, game: Node) -> void:
	_release()
	if game.paused: game.toggle_pause()
	game.skater.spawn_position = SPAWN
	game.restart_run()
	await _frames(tree, 30)
	game.skater.rotation.y = PI * 0.5


static func _release() -> void:
	for action: String in ["push", "brake", "steer_left", "steer_right", "ollie", "grind", "flip", "grab", "manual", "revert", "spin_left", "spin_right"]:
		Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
