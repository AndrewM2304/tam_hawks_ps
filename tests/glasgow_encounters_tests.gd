extends RefCounted
## Independent encounter rules and actual production input/bank/bail integration.
## Pure callback fixtures are separate from the physical successful performances.
const EncounterSource = preload("res://game/characters/glasgow_encounters.gd")
const CareerSource = preload("res://game/progression/career_progress.gd")

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	await _rules(tree, check)
	var original_career = game.career
	var original_spawn: Vector3 = game.skater.spawn_position
	game.persistence_enabled = false
	game.career = CareerSource.new()
	await _physical_performance(tree, game, check)
	await _physical_failure_and_reset(tree, game, check)
	await _free_skate(tree, game, check)
	await _audio_controls(tree, game, check)
	_release()
	game.career = original_career
	game.apply_settings(original_career.settings, false)
	game.skater.spawn_position = original_spawn
	game.start_mode(false)


static func _rules(tree: SceneTree, check: Callable) -> void:
	var encounter = EncounterSource.new()
	tree.root.add_child(encounter)
	encounter.configure([{"id": "busker_big_finish", "position": Vector3.ZERO}])
	encounter.poll(Vector3.ZERO, true, 0.0, 100)
	check.call(encounter.status_snapshot().state == "idle" and encounter.status_snapshot().attempts == 0,
		"encounter rules: a pre-existing unbanked combo cannot enter a fresh attempt")
	encounter.poll(Vector3(4.21, 0, 0), true, 0.0)
	encounter.poll(Vector3(0, 2.5, 0), true, 0.0)
	check.call(encounter.status_snapshot().state == "idle", "encounter rules: interaction checks horizontal and vertical proximity")
	encounter.poll(Vector3(4.19, 0, 0), true, 0.0)
	check.call(encounter.status_snapshot().state == "active" and encounter.status_snapshot().attempts == 1,
		"encounter rules: eligible deliberate nearby interaction starts one attempt")
	encounter.on_trick("Ollie", 100, Vector3.ZERO)
	encounter.on_trick("Frontside 180", 200, Vector3.ZERO)
	encounter.on_trick("Backside 360", 400, Vector3.ZERO)
	check.call(encounter.status_snapshot().family_count == 2,
		"encounter rules: real frontside/backside labels share a single spin family")
	encounter.on_trick("Melon Grab", 250, Vector3.ZERO)
	encounter.on_bank(999, Vector3.ZERO)
	check.call(encounter.status_snapshot().state == "active" and encounter.status_snapshot().family_count == 0,
		"encounter rules: a short bank cannot win or carry trick families into the next combo")
	for title: String in ["Kickflip", "Kickflip", "KICKFLIP"]: encounter.on_trick(title, 300, Vector3.ZERO)
	encounter.on_bank(9000, Vector3.ZERO)
	check.call(encounter.status_snapshot().state == "active" and encounter.status_snapshot().wins == 0,
		"encounter rules: repeating one trick family cannot satisfy variety even with a large bank")
	_three_families(encounter)
	encounter.poll(Vector3(34.1, 0, 0), false, 0.0)
	encounter.poll(Vector3.ZERO, false, 0.0)
	_three_families(encounter)
	encounter.on_bank(1950, Vector3.ZERO)
	check.call(encounter.status_snapshot().state == "active" and encounter.status_snapshot().wins == 0,
		"encounter rules: leaving and returning cannot import a qualifying outside combo")
	_three_families(encounter)
	encounter.on_bank(1950, Vector3.ZERO)
	encounter.on_bank(1950, Vector3.ZERO)
	check.call(encounter.status_snapshot().state == "success" and encounter.status_snapshot().wins == 1,
		"encounter rules: a fresh valid combo wins once and duplicate bank callbacks cannot repeat it")
	encounter.poll(Vector3.ZERO, true, 0.0)
	var deadline: float = encounter.status_snapshot().remaining
	encounter.poll(Vector3.ZERO, false, -1.0)
	encounter.poll(Vector3.ZERO, false, NAN)
	check.call(encounter.status_snapshot().remaining == deadline,
		"encounter rules: invalid elapsed time neither extends nor consumes the deadline")
	encounter.poll(Vector3.ZERO, false, 34.99)
	var still_active: bool = encounter.status_snapshot().state == "active"
	encounter.poll(Vector3.ZERO, false, 0.02)
	check.call(still_active and encounter.status_snapshot().state == "failed"
		and encounter.status_snapshot().wins == 1,
		"encounter rules: the actual 35-second boundary expires a replay without inventing a win")
	encounter.reset_run()
	check.call(encounter.status_snapshot().state == "idle" and encounter.status_snapshot().attempts == 0
		and encounter.status_snapshot().wins == 0 and encounter.status_snapshot().family_count == 0,
		"encounter rules: reset clears run-local attempt and performance state")
	encounter.queue_free()
	await tree.process_frame


static func _physical_performance(tree: SceneTree, game: Node, check: Callable) -> void:
	var anchor: Vector3 = game.encounters.status_snapshot().position
	await _reset(tree, game, anchor + Vector3(0, 0.8, 7), false)
	check.call(game.encounters.status_snapshot().state == "idle"
		and game.encounters.nearby_prompt(game.skater.global_position).is_empty(),
		"encounter integration: restarting outside interaction range does not auto-start Mo")
	Input.action_press("push")
	for frame in range(100):
		await _frames(tree, 1)
		if game.skater.global_position.distance_to(anchor) < 3.8: break
	Input.action_release("push")
	Input.action_press("brake")
	await _frames(tree, 25)
	Input.action_release("brake")
	check.call(game.skater.is_on_floor() and not game.encounters.nearby_prompt(game.skater.global_position).is_empty()
		and game.encounters.status_snapshot().state == "idle",
		"encounter integration: a physical push/brake approach reveals the offer without activating it")
	await _interact(tree)
	check.call(game.encounters.status_snapshot().state == "active"
		and game.encounters.status_snapshot().attempts == 1,
		"encounter integration: mapped interaction input starts the live challenge")
	var remaining: float = game.encounters.status_snapshot().remaining
	game.toggle_pause()
	await _frames(tree, 20)
	check.call(game.paused and is_equal_approx(game.encounters.status_snapshot().remaining, remaining),
		"encounter integration: pause freezes the live challenge deadline")
	game.toggle_pause()
	await _performance(tree, false)
	check.call(game.score.total_score == 1950 and game.encounters.status_snapshot().state == "success"
		and game.encounters.status_snapshot().family_count == 3 and game.encounters.status_snapshot().wins == 1,
		"encounter integration: real ollie flip grab and landing bank complete Mo's challenge")
	await _frames(tree, 30)
	check.call(game.encounters.status_snapshot().wins == 1 and game.score.total_score == 1950,
		"encounter integration: lingering after completion cannot repeat the win or bank")
	# Attempt replay with a genuinely pending Ollie; no score/model state is seeded.
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	await _interact(tree)
	check.call(game.score.get_combo_value() > 0 and game.encounters.status_snapshot().attempts == 1
		and game.encounters.status_snapshot().state == "success",
		"encounter integration: mapped replay input rejects a real pending airborne combo")
	await _frames(tree, 80)
	await _interact(tree)
	var before: int = game.score.total_score
	await _performance(tree, true)
	check.call(game.score.total_score - before == 1050 and game.encounters.status_snapshot().state == "success"
		and game.encounters.status_snapshot().wins == 2 and game.encounters.status_snapshot().family_count == 3,
		"encounter integration: fresh heelflip and aligned frontside spin bonus satisfy variety in a stale-ollie replay")
	print("ENCOUNTER physical wins=%d score=%d attempts=%d" % [game.encounters.status_snapshot().wins,
		game.score.total_score, game.encounters.status_snapshot().attempts])


static func _physical_failure_and_reset(tree: SceneTree, game: Node, check: Callable) -> void:
	var anchor: Vector3 = game.encounters.status_snapshot().position
	await _reset(tree, game, anchor + Vector3(0, 0.8, 3), false)
	await _interact(tree)
	game.skater.rotation.y = PI / 2.0 # Aim the unobstructed west court before motion.
	Input.action_press("push")
	await _frames(tree, 40)
	Input.action_release("push")
	Input.action_press("manual")
	await _frames(tree, 2)
	var entered: bool = game.skater.manual_active
	for frame in range(280):
		await _frames(tree, 1)
		if game.encounters.status_snapshot().state == "failed": break
	_release()
	check.call(entered and game.encounters.status_snapshot().state == "failed"
		and game.encounters.status_snapshot().wins == 0 and game.score.get_combo_value() == 0,
		"encounter integration: a real unbalanced manual bail fails the attempt and drops pending score")
	var completed: Array = game.career.completed_ids.duplicate()
	game.restart_run()
	await _frames(tree, 45)
	check.call(game.encounters.status_snapshot().state == "idle" and game.encounters.status_snapshot().attempts == 0
		and game.career.completed_ids == completed,
		"encounter integration: restart clears the side challenge while retaining existing career identity")
	await _interact(tree)
	game.time_remaining = 0.03 # Timer boundary fixture; movement/score remain production-owned.
	await _frames(tree, 4)
	await _interact(tree)
	check.call(game.run_finished and game.encounters.status_snapshot().state == "failed"
		and game.encounters.status_snapshot().attempts == 1,
		"encounter integration: timed run completion ends Mo's active attempt and blocks results-screen replay")


static func _free_skate(tree: SceneTree, game: Node, check: Callable) -> void:
	var anchor: Vector3 = game.encounters.status_snapshot().position
	var completed: Array = game.career.completed_ids.duplicate()
	var record: int = game.career.best_score
	await _reset(tree, game, anchor + Vector3(0, 0.8, 3), true)
	await _interact(tree)
	await _performance(tree, false)
	check.call(game.encounters.status_snapshot().state == "success" and game.score.total_score == 1950
		and game.career.completed_ids == completed and game.career.best_score == record
		and not game.persistence_enabled,
		"encounter integration: free-skate performance succeeds without career awards, records or profile writes")
	check.call(game.career.goals_snapshot().size() == 10,
		"encounter integration: the replayable side activity preserves the original ten-goal career")


static func _audio_controls(tree: SceneTree, game: Node, check: Callable) -> void:
	var actor: Node = game.encounters.get_node("MoBusker")
	var player: AudioStreamPlayer3D = actor.get_node("OriginalBuskerPlucks")
	var stream: AudioStreamWAV = player.stream as AudioStreamWAV
	check.call(stream != null and stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.stereo
		and stream.get_length() >= 2.0 and stream.get_length() <= 12.0
		and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and player.max_distance <= 34.0,
		"encounter audio: a bounded local mono PCM loop is spatially limited to Mo's court")
	if stream != null:
		var peak := 0
		var energy := 0.0
		for sample in range(stream.data.size() / 2):
			var value: int = stream.data.decode_s16(sample * 2)
			peak = maxi(peak, absi(value))
			energy += float(value) * value
		var rms := sqrt(energy / maxf(1.0, stream.data.size() / 2.0))
		check.call(peak > 500 and peak < 32767 and rms > 100
			and absi(stream.data.decode_s16(0) - stream.data.decode_s16(stream.data.size() - 2)) < 128,
			"encounter audio: plucks contain non-silent unclipped samples and a quiet loop seam")
	game.apply_settings({"audio": 1.0, "ambience_volume": 1.0}, false)
	var full_gain: float = db_to_linear(player.volume_db)
	game.apply_settings({"audio": 0.5, "ambience_volume": 0.5}, false)
	check.call(full_gain > 0.0 and is_equal_approx(db_to_linear(player.volume_db), full_gain * 0.25),
		"encounter audio: live master and ambience settings both scale the local instrument")
	game.apply_settings({"audio": 0.0, "ambience_volume": 1.0}, false)
	var master_muted: bool = not player.playing and player.volume_db <= -70.0
	game.apply_settings({"audio": 1.0, "ambience_volume": 0.0}, false)
	check.call(master_muted and not player.playing and player.volume_db <= -70.0,
		"encounter audio: either master mute or ambience mute stops the local instrument")
	game.apply_settings({"audio": 1.0, "ambience_volume": 1.0}, false)
	var phase: float = actor._phase
	game.toggle_pause()
	await _frames(tree, 12)
	check.call(not player.can_process() and not actor.can_process() and actor._phase == phase,
		"encounter audio: menu pause suspends the instrument node and its visible performance")
	game.toggle_pause()
	await _frames(tree, 2)
	check.call(player.can_process() and actor._phase > phase,
		"encounter audio: resume restores the local performer processing")
	# Dummy-driver fixtures deliberately do not claim audible playback quality.


static func _three_families(encounter: Node) -> void:
	encounter.on_trick("Ollie", 100, Vector3.ZERO)
	encounter.on_trick("Kickflip", 300, Vector3.ZERO)
	encounter.on_trick("Melon Grab", 250, Vector3.ZERO)


static func _performance(tree: SceneTree, spin: bool) -> void:
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	if spin: Input.action_press("steer_right")
	Input.action_press("flip")
	Input.action_press("spin_left" if spin else "grab")
	await _frames(tree, 1)
	Input.action_release("flip")
	Input.action_release("grab")
	Input.action_release("steer_right")
	if spin:
		await _frames(tree, 26)
		Input.action_release("spin_left")
	await _frames(tree, 85)


static func _reset(tree: SceneTree, game: Node, at: Vector3, free_skate: bool) -> void:
	_release()
	game.skater.spawn_position = at
	game.start_mode(free_skate)
	await _frames(tree, 45)


static func _interact(tree: SceneTree) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_X
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(tree, 1)
	event = InputEventKey.new()
	event.physical_keycode = KEY_X
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(tree, 1)


static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
