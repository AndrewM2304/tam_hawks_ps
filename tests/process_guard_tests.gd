extends RefCounted
## Input-driven regressions for previously reproduced skating process defects.
## Only the descending rail fixture assigns initial motion/air classification;
## all gestures, facing changes, launches, deck yaw and poses use production input.

const SAFE_SPAWN := Vector3(-22.0, 0.8, 28.0)

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	var original_free: bool = game.free_skate_mode
	await _expired_manual_gestures(tree, game, check)
	await _backwards_powerslide(tree, game, check)
	await _rail_nollie(tree, game, check)
	await _reversed_deck_nollie(tree, game, check)
	await _unsafe_transition_contact(tree, game, check)
	_release()
	game.skater.spawn_position = original_spawn
	game.start_mode(original_free)

static func _expired_manual_gestures(tree: SceneTree, game: Node, check: Callable) -> void:
	for actions: Array in [["push", "brake"], ["brake", "push"]]:
		await _reset(tree, game)
		Input.action_press(actions[0])
		await _frames(tree, 1)
		Input.action_release(actions[0])
		await _frames(tree, 1)
		Input.action_press(actions[1])
		await _frames(tree, 1)
		Input.action_release(actions[1])
		var had_pending: bool = not game.skater._manual_gesture_pending.is_empty()
		var below_entry_speed: bool = absf(game.skater.speed) < 2.0
		await _frames(tree, 22)
		check.call(had_pending and below_entry_speed and not game.skater.manual_active
			and game.skater._manual_gesture_pending.is_empty(),
			"process guard: an insufficient-speed %s/%s manual gesture actually expires" % actions)
		Input.action_press("push")
		await _frames(tree, 50)
		Input.action_release("push")
		Input.action_press("manual")
		await _frames(tree, 1)
		check.call(game.skater.manual_active and not game.skater._manual_latched
			and game.skater.manual_trick_id == "manual",
			"process guard: a fresh shortcut after expired %s/%s enters a held manual without stale latching" % actions)
		Input.action_release("manual")
		await _frames(tree, 2)
		check.call(not game.skater.manual_active and game.score.pending_landing,
			"process guard: releasing that fresh shortcut ends the manual and opens ordinary banking")

static func _backwards_powerslide(tree: SceneTree, game: Node, check: Callable) -> void:
	for action: String in ["steer_left", "steer_right"]:
		var ordinary_turn := 0.0
		var slide_turn := 0.0
		var valid_reverse := true
		for slide: bool in [false, true]:
			await _reverse_from_pivot(tree, game)
			valid_reverse = valid_reverse and game.skater.speed < -4.0 \
				and game.skater.is_on_floor() and not game.skater.manual_active
			var heading: float = game.skater.rotation.y
			Input.action_press(action)
			if slide: Input.action_press("brake")
			await _frames(tree, 7)
			var turn := angle_difference(heading, game.skater.rotation.y)
			if slide:
				slide_turn = turn
				valid_reverse = valid_reverse and game.skater.powersliding and game.skater.speed < -4.0
			else:
				ordinary_turn = turn
		check.call(valid_reverse,
			"process guard: actual manual-pivot travel supplies a supported negative-speed %s comparison" % action)
		check.call(absf(ordinary_turn) > 0.02 and ordinary_turn * slide_turn > 0.0
			and absf(slide_turn) > absf(ordinary_turn) + 0.12,
			"process guard: negative-speed powerslide keeps ordinary %s yaw direction and turns more sharply" % action)

static func _rail_nollie(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	# Explicit initial descending contact, matching the independent rail suite.
	game.skater.set_physics_process(false)
	game.skater.global_position = Vector3(12.15, 1.10, 11.5)
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = Vector3(0, -1, -6)
	game.skater.speed = 6.0
	game.skater.rotation.y = 0.0
	game.skater.airborne = true
	game.skater.set_physics_process(true)
	Input.action_press("grind")
	await _frames(tree, 3)
	var captured: bool = game.skater.grinding
	Input.action_press("push")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(captured and game.skater.airborne and not game.skater.grinding
		and game.skater.takeoff_mode == "Nollie" and game.skater.last_trick_id == "nollie"
		and game.skater.velocity.y > 8.0,
		"process guard: a fresh forward release-pop leaves a real rail with Nollie takeoff mode")
	Input.action_release("push")
	Input.action_release("grind")
	Input.action_press("flip")
	await _frames(tree, 2)
	Input.action_release("flip")
	check.call(game.skater.last_trick_id == "kickflip"
		and game.score.trick_history.has("Nollie Kickflip") and game.score.combo_trick_count == 3,
		"process guard: the rail Nollie prefixes the next real air flip without replacing its stable identity")

static func _reversed_deck_nollie(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	await _nollie(tree)
	var ordinary_dip := _front_height_difference(game.skater)
	check.call(game.skater.airborne and game.skater.takeoff_mode == "Nollie" and ordinary_dip < -0.03,
		"process guard: a normal-deck Nollie visibly dips the travel-relative front end")
	await _reset(tree, game)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("brake")
	Input.action_press("flip")
	await _frames(tree, 2)
	_release()
	for frame in 90:
		await _frames(tree, 1)
		if not game.skater.airborne: break
	await _frames(tree, 25)
	var reversed_deck: bool = absf(absf(wrapf(game.skater._deck_yaw, -PI, PI)) - PI) < 0.01
	var shove_banked: bool = game.score.total_score == 700 \
		and game.score.last_banked_tricks.has("Pop Shove-it")
	await _nollie(tree)
	var reversed_dip := _front_height_difference(game.skater)
	check.call(reversed_deck and shove_banked and game.skater.airborne
		and game.skater.takeoff_mode == "Nollie" and reversed_dip < -0.03
		and absf(reversed_dip - ordinary_dip) < 0.02,
		"process guard: after a completed real shove-it, Nollie still dips the same travel-relative board end")

static func _front_height_difference(skater: CharacterBody3D) -> float:
	var board: Node3D = skater.get_node("SkaterVisual/Board")
	var nose := board.to_global(Vector3(0, 0, -0.38))
	var tail := board.to_global(Vector3(0, 0, 0.38))
	var forward := -skater.global_basis.z
	return nose.y - tail.y if (nose - tail).dot(forward) > 0.0 else tail.y - nose.y

static func _unsafe_transition_contact(tree: SceneTree, game: Node, check: Callable) -> void:
	var feature: Node3D
	for candidate: Node in tree.get_nodes_in_group("skate_transitions"):
		if str(candidate.get("feature_id")) == "ClydeQuayQuarter":
			feature = candidate
			break
	if feature == null:
		check.call(false, "process guard: the unsafe-contact regression requires the real Clyde quarter-pipe")
		return
	_release()
	# One initial drop fixture above the shallow real arc; no placement or
	# trick-state mutation follows. Native gravity supplies the entire approach.
	var contact: Dictionary = feature.sample(0.30, 0.0)
	game.skater.spawn_position = Vector3(contact.point) + Vector3.UP * 0.6 + Vector3(contact.normal) * 0.3
	game.start_mode(true)
	var evidence := {"bails": 0, "entries": [], "transition_bail": false}
	var on_bail := func():
		evidence.bails += 1
		# Recovery clears active movement helpers before emitting the single loss
		# signal. Prove the actual finite native face rather than its cleared flag.
		var sample: Dictionary = feature.surface_sample(game.skater.global_position)
		var query := PhysicsRayQueryParameters3D.create(sample.point + sample.normal * 0.10,
			sample.point - sample.normal * 0.10, 1)
		query.exclude = [game.skater.get_rid()]
		var native: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
		evidence.transition_bail = game.skater.bail_active and float(sample.distance) <= 0.10 \
			and not native.is_empty() and native.collider == feature.surface_body
	var on_trick := func(label: String, _points: int): evidence.entries.append(label)
	game.skater.bailed.connect(on_bail)
	game.skater.trick_performed.connect(on_trick)
	await _frames(tree, 1)
	Input.action_press("ollie")
	var release_distance := INF
	var unfinished_at_release := false
	for frame in 100:
		if evidence.bails > 0: break
		var approach: Dictionary = feature.surface_sample(game.skater.global_position)
		if game.skater.airborne and not game.skater.transition_active and float(approach.distance) < 0.23:
			Input.action_press("flip")
			await _frames(tree, 1)
			release_distance = float(feature.surface_sample(game.skater.global_position).distance)
			unfinished_at_release = game.skater._flip_remaining > 0.0 and game.skater.airborne \
				and 1.0 - game.skater._flip_remaining / game.skater._flip_duration < 0.8
			Input.action_release("ollie")
			Input.action_release("flip")
			await _frames(tree, 1)
			break
		await _frames(tree, 1)
	check.call(release_distance <= 0.10 and unfinished_at_release and evidence.entries == ["Kickflip"],
		"process guard: native drop reaches transition contact with a real unfinished flip and simultaneous release-pop")
	await _frames(tree, 25)
	check.call(evidence.bails == 1 and evidence.transition_bail and game.score.total_score == 0
		and game.score.get_combo_value() == 0 and not evidence.entries.has("Ollie"),
		"process guard: release-pop cannot bypass the transition landing catch or award a new launch before the bail")
	print("PROCESS CONTACT distance=%.5f unfinished=%s transition_bail=%s bails=%d entries=%s" % [
		release_distance, unfinished_at_release, evidence.transition_bail, evidence.bails, evidence.entries])
	game.skater.bailed.disconnect(on_bail)
	game.skater.trick_performed.disconnect(on_trick)
	_release()

static func _nollie(tree: SceneTree) -> void:
	Input.action_press("push")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 3)
	Input.action_release("push")

static func _reverse_from_pivot(tree: SceneTree, game: Node) -> void:
	await _reset(tree, game)
	Input.action_press("push")
	await _frames(tree, 55)
	Input.action_release("push")
	await _frames(tree, 20)
	Input.action_press("manual")
	await _frames(tree, 1)
	Input.action_press("revert")
	await _frames(tree, 1)
	Input.action_release("revert")
	Input.action_release("manual")
	await _frames(tree, 2)

static func _reset(tree: SceneTree, game: Node) -> void:
	_release()
	game.skater.spawn_position = SAFE_SPAWN
	game.start_mode(true)
	await _frames(tree, 35)

static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)

static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
