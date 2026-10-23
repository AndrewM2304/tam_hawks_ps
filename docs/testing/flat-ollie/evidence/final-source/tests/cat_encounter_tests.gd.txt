extends RefCounted
## Independent callback rules and a separate real-input three-rail performance.
## Only restart sets position. Ground heading may be aimed directly; no speed,
## velocity, capture, trick, score or bank is injected into the physical route.
const CatSource = preload("res://game/characters/cat_encounter.gd")
const CareerSource = preload("res://game/progression/career_progress.gd")
const RAIL_IDS := ["Grind_Cat_A", "Grind_Cat_B", "Grind_Cat_C"]


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	await _rules(tree, check)
	var original_career = game.career
	var original_spawn: Vector3 = game.skater.spawn_position
	game.persistence_enabled = false
	game.career = CareerSource.new()
	await _physical_sequence(tree, game, check)
	await _lifecycle(tree, game, check)
	await _audio_controls(tree, game, check)
	_release()
	game.career = original_career
	game.apply_settings(original_career.settings, false)
	game.skater.spawn_position = original_spawn
	game.start_mode(false)


static func _rules(tree: SceneTree, check: Callable) -> void:
	var cat = CatSource.new()
	tree.root.add_child(cat)
	var definition := {"id": "cat_got_the_beat", "position": Vector3.ZERO,
		"sequence": RAIL_IDS.duplicate(), "area_center": Vector3.ZERO, "area_radius": 32.0}
	var invalid := definition.duplicate(true)
	invalid.sequence = [RAIL_IDS[0], RAIL_IDS[0], RAIL_IDS[2]]
	cat.configure([invalid])
	cat.poll(Vector3.ZERO, true, 0.0)
	check.call(cat.nearby_prompt(Vector3.ZERO).is_empty() and cat.status_snapshot().state == "idle",
		"cat rules: duplicate authored segment IDs cannot create an impossible accepted offer")
	cat.configure([definition])
	cat.poll(Vector3.ZERO, true, 0.0, 100)
	cat.poll(Vector3(4.21, 0, 0), true, 0.0)
	cat.poll(Vector3(0, 2.5, 0), true, 0.0)
	check.call(cat.status_snapshot().state == "idle" and cat.status_snapshot().attempts == 0,
		"cat rules: pending combos and horizontal or vertical distance reject fresh attempts")
	cat.poll(Vector3(4.19, 0, 0), true, 0.0)
	check.call(cat.status_snapshot().state == "active" and cat.status_snapshot().attempts == 1
		and cat.status_snapshot().sequence_index == 0 and cat.status_snapshot().next_rail_id == RAIL_IDS[0],
		"cat rules: a deliberate eligible offer starts at the first marked segment")
	cat.on_grind_capture("UnmarkedPublicRail", Vector3.ZERO)
	cat.on_grind_capture(RAIL_IDS[1], Vector3.ZERO)
	cat.on_bank(5000, Vector3.ZERO)
	check.call(cat.status_snapshot().sequence_index == 0 and cat.status_snapshot().state == "active",
		"cat rules: unmarked or wrong first captures and an unrelated bank cannot advance the sequence")
	cat.on_grind_capture(RAIL_IDS[0], Vector3.ZERO)
	cat.on_grind_capture(RAIL_IDS[0], Vector3.ZERO)
	cat.on_bank(600, Vector3.ZERO)
	check.call(cat.status_snapshot().sequence_index == 1 and cat.status_snapshot().next_rail_id == RAIL_IDS[1],
		"cat rules: duplicate latest capture is ignored while an intermediate clean bank preserves progress")
	cat.on_grind_capture(RAIL_IDS[2], Vector3.ZERO)
	check.call(cat.status_snapshot().sequence_index == 0,
		"cat rules: skipping the middle marked rail clears the ordered sequence")
	cat.on_grind_capture(RAIL_IDS[0], Vector3.ZERO)
	cat.on_grind_capture(RAIL_IDS[1], Vector3.ZERO)
	cat.on_grind_capture(RAIL_IDS[0], Vector3.ZERO)
	check.call(cat.status_snapshot().sequence_index == 1,
		"cat rules: the first marked rail restarts a wrong-order sequence at one")
	cat.on_grind_capture(RAIL_IDS[1], Vector3.ZERO)
	cat.on_bank(600, Vector3.ZERO)
	cat.on_grind_capture(RAIL_IDS[2], Vector3.ZERO)
	cat.on_grind_capture(RAIL_IDS[2], Vector3.ZERO)
	cat.on_bank(0, Vector3.ZERO)
	cat.on_bank(-1, Vector3.ZERO)
	check.call(cat.status_snapshot().sequence_index == 3 and cat.status_snapshot().state == "active"
		and cat.status_snapshot().wins == 0,
		"cat rules: all three captures still require a subsequent positive clean bank")
	cat.on_bank(1, Vector3.ZERO)
	cat.on_bank(9000, Vector3.ZERO)
	check.call(cat.status_snapshot().state == "success" and cat.status_snapshot().wins == 1,
		"cat rules: a positive final bank wins once without a hidden score threshold")
	cat.poll(Vector3.ZERO, false, 0.0)
	cat.poll(Vector3(10.01, 0, 0), false, 0.0, 0, true)
	cat.poll(Vector3(0, 2.5, 0), false, 0.0, 0, true)
	check.call(cat.status_snapshot().celebration_state == "queued"
		and not cat.status_snapshot().celebration_started and cat.status_snapshot().wins == 1,
		"cat rules: the earned payoff waits for both close audience and visibility without repeating rewards")
	cat.poll(Vector3(9.99, 0, 0), false, 0.0, 0, true)
	await _frames(tree, 5)
	var actor = cat.get_node("RaeBinBusker")
	var elapsed: float = actor.animation_snapshot().dance_elapsed
	cat.poll(Vector3.ZERO, false, 0.0, 0, true)
	check.call(cat.status_snapshot().celebration_started and actor.animation_snapshot().dance_active
		and elapsed > 0.0 and is_equal_approx(actor.animation_snapshot().dance_elapsed, elapsed),
		"cat rules: eligible visibility starts the queued payoff once without restarting its clock")
	cat.reduced_motion = true
	await _frames(tree, 2)
	cat.reduced_motion = false
	cat.poll(Vector3.ZERO, false, 0.0, 0, true)
	await _frames(tree, 2)
	check.call(not actor.animation_snapshot().dance_active and cat.status_snapshot().celebration_started
		and cat.status_snapshot().wins == 1,
		"cat rules: reduced motion stops an already started payoff without replaying it when disabled")
	cat.poll(Vector3.ZERO, true, 0.0, 100)
	check.call(cat.status_snapshot().state == "success" and cat.status_snapshot().attempts == 1,
		"cat rules: a pending combo cannot replace a completed attempt")
	cat.poll(Vector3.ZERO, true, 0.0)
	check.call(cat.status_snapshot().state == "active" and cat.status_snapshot().sequence_index == 0
		and cat.status_snapshot().attempts == 2 and cat.status_snapshot().wins == 1,
		"cat rules: immediate clean replay starts fresh and preserves the run-local win count")
	cat.on_grind_capture(RAIL_IDS[0], Vector3(32.1, 0, 0))
	check.call(cat.status_snapshot().state == "failed",
		"cat rules: an outside capture fails even before the next polling tick")
	cat.poll(Vector3.ZERO, true, 0.0)
	for id: String in RAIL_IDS: cat.on_grind_capture(id, Vector3.ZERO)
	cat.on_bank(600, Vector3(0, 10.01, 0))
	check.call(cat.status_snapshot().state == "failed" and cat.status_snapshot().wins == 1,
		"cat rules: an outside final bank cannot complete the attempt")
	cat.poll(Vector3.ZERO, true, 0.0)
	cat.poll(Vector3(32.1, 0, 0), false, 0.0)
	cat.poll(Vector3.ZERO, false, 0.0)
	check.call(cat.status_snapshot().state == "failed",
		"cat rules: leaving and returning cannot resume an invalidated attempt")
	cat.poll(Vector3.ZERO, true, 0.0)
	var remaining: float = cat.status_snapshot().remaining
	cat.poll(Vector3.ZERO, false, NAN)
	cat.poll(Vector3.ZERO, false, -1.0)
	var ignored_invalid: bool = is_equal_approx(cat.status_snapshot().remaining, remaining)
	cat.poll(Vector3.ZERO, false, 59.99)
	var before_deadline: bool = cat.status_snapshot().state == "active"
	cat.poll(Vector3.ZERO, false, 0.02)
	check.call(ignored_invalid and before_deadline and cat.status_snapshot().state == "failed",
		"cat rules: invalid deltas are ignored and the actual sixty-second deadline expires")
	cat.poll(Vector3.ZERO, true, 0.0)
	cat.on_grind_capture(RAIL_IDS[0], Vector3.ZERO)
	cat.on_bail()
	check.call(cat.status_snapshot().state == "failed" and cat.status_snapshot().wins == 1,
		"cat rules: bail invalidates an incomplete sequence without adding a win")
	cat.poll(Vector3.ZERO, true, 0.0)
	cat.finish_run()
	cat.finish_run()
	check.call(cat.status_snapshot().state == "failed" and cat.status_snapshot().wins == 1,
		"cat rules: repeated run-finish notification is idempotent")
	cat.reset_run()
	check.call(cat.status_snapshot().state == "idle" and cat.status_snapshot().attempts == 0
		and cat.status_snapshot().wins == 0 and cat.status_snapshot().sequence_index == 0,
		"cat rules: restart removes all run-local attempt progress")
	cat.queue_free()
	await tree.process_frame


static func _physical_sequence(tree: SceneTree, game: Node, check: Callable) -> void:
	var rails: Dictionary = {}
	for line in game.world.get_grind_lines():
		if RAIL_IDS.has(line.id): rails[line.id] = line
	check.call(rails.size() == 3 and game.skater.has_signal("grind_captured"),
		"cat integration: three distinct authored tracks expose real player capture identity")
	if rails.size() != 3 or not game.skater.has_signal("grind_captured"): return
	var anchor: Vector3 = game.cat_encounter.status_snapshot().position
	await _reset(tree, game, anchor + Vector3(0, 0.8, 3), true)
	_actor_structure(game.cat_encounter.get_node("RaeBinBusker"), check)
	var completed: Array = game.career.completed_ids.duplicate()
	var record: int = game.career.best_score
	var evidence := {"ids": [], "positions": [], "tricks": [], "bails": 0, "states": [],
		"launches": [], "first_landing": {}, "descending_samples": 0, "closest_a": {}}
	var on_capture := func(id: String):
		evidence.ids.append(id)
		evidence.positions.append(game.skater.global_position)
		evidence.states.append(game.cat_encounter.status_snapshot().sequence_index)
	var on_trick := func(title: String, _points: int):
		evidence.tricks.append(title)
		if title == "Ollie":
			evidence.launches.append({"position": game.skater.global_position,
				"speed": game.skater.speed, "velocity": game.skater.velocity})
	var on_landing := func(clean: bool):
		if not evidence.launches.is_empty() and evidence.first_landing.is_empty():
			evidence.first_landing = {"position": game.skater.global_position,
				"speed": game.skater.speed, "velocity": game.skater.velocity,
				"clean": clean, "captures": evidence.ids.duplicate()}
	var on_bail := func(): evidence.bails += 1
	game.skater.grind_captured.connect(on_capture)
	game.skater.trick_performed.connect(on_trick)
	game.skater.landed.connect(on_landing)
	game.skater.bailed.connect(on_bail)
	await _interact(tree)
	check.call(game.cat_encounter.status_snapshot().state == "active"
		and game.cat_encounter.status_snapshot().attempts == 1,
		"cat integration: a real free-skate interaction starts a fresh ordered attempt")
	var approach: bool = await _drive_to(tree, game, Vector3(-22, 4, -95))
	approach = await _drive_to(tree, game, Vector3(-28, 4, -91)) and approach
	var first = rails[RAIL_IDS[0]]
	var target: Vector3 = first.point_at(2.0)
	var tangent: Vector3 = first.dir_at(2.0)
	var launched := false
	var captured := false
	for frame in range(180):
		_aim(game.skater, tangent)
		Input.action_press("push")
		Input.action_press("grind")
		# The weighted tap has a shorter flight. Approach within about four
		# metres of A's beginning before the real one-frame press/release.
		if not launched and (target - game.skater.global_position).dot(tangent) < 6.0:
			Input.action_press("ollie")
			launched = true
		else: Input.action_release("ollie")
		_first_rail_witness(game, first, evidence)
		await _frames(tree, 1)
		_first_rail_witness(game, first, evidence)
		if evidence.ids.has(RAIL_IDS[0]) and game.skater.grinding:
			captured = true
			break
		if evidence.bails > 0 or game.cat_encounter.status_snapshot().state != "active": break
	Input.action_release("push")
	Input.action_release("ollie")
	# Sample the release before charging again: simultaneous synthetic
	# release/press edges otherwise request an immediate uncharged hop.
	await _frames(tree,1)
	print("CAT initial_flight launches=%s first_landing=%s descending_samples=%d closest_A=%s end_position=%s end_speed=%.3f" % [
		evidence.launches, evidence.first_landing, evidence.descending_samples,
		evidence.closest_a, game.skater.global_position, game.skater.speed])
	for index in range(1, 3):
		if not captured: break
		var prior = rails[RAIL_IDS[index - 1]]
		var exit_point: Vector3 = prior.point_at(prior.length - 1.0)
		for frame in range(90):
			_balance(game.skater)
			# Charge before the existing takeoff point: short rail taps no
			# longer provide the rejected oversized transfer airtime.
			var distance_to_exit: float = (exit_point - game.skater.global_position).dot(tangent)
			if distance_to_exit <= 5.5: Input.action_press("ollie")
			if distance_to_exit <= 0.0: break
			await _frames(tree, 1)
			if not game.skater.grinding: break
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		Input.action_press("ollie")
		await _frames(tree, 1)
		Input.action_release("ollie")
		Input.action_release("grind")
		await _frames(tree, 1)
		Input.action_press("grind")
		captured = false
		for frame in range(120):
			_aim(game.skater, tangent)
			await _frames(tree, 1)
			if evidence.ids.has(RAIL_IDS[index]) and game.skater.grinding:
				captured = true
				break
			if evidence.bails > 0 or game.cat_encounter.status_snapshot().state != "active": break
	check.call(approach and captured and evidence.ids == RAIL_IDS and evidence.states == [1, 2, 3]
		and evidence.bails == 0 and game.cat_encounter.status_snapshot().state == "active"
		and game.cat_encounter.status_snapshot().wins == 0,
		"cat integration: real push ollie and rail transfers capture A B C once before any success")
	_release()
	await _frames(tree, 1)
	Input.action_press("grind")
	await _frames(tree, 1)
	Input.action_release("grind")
	for frame in range(100):
		if game.skater.is_on_floor(): Input.action_press("brake")
		await _frames(tree, 1)
	_release()
	var banked: int = game.score.total_score
	check.call(captured and evidence.bails == 0 and game.cat_encounter.status_snapshot().state == "success"
		and game.cat_encounter.status_snapshot().wins == 1 and banked == 1050
		and evidence.tricks.count("Ollie") == 3 and evidence.tricks.count("Rail Grind") == 3,
		"cat integration: actual final release and landing bank complete the sequence with only earned trick points")
	await _frames(tree, 30)
	check.call(game.cat_encounter.status_snapshot().wins == 1 and game.score.total_score == banked
		and game.career.completed_ids == completed and game.career.best_score == record
		and game.career.goals_snapshot().size() == 10 and not game.persistence_enabled and evidence.ids == RAIL_IDS,
		"cat integration: success cannot repeat or add free-skate career progress, goals or profile writes")
	await _payoff(tree, game, check)
	print("CAT physical approach=%s captures=%s positions=%s sequence=%s tricks=%s bank=%d bails=%d state=%s remaining=%.2f" % [
		approach, evidence.ids, evidence.positions, evidence.states, evidence.tricks, banked,
		evidence.bails, game.cat_encounter.status_snapshot().state, game.cat_encounter.status_snapshot().remaining])
	print("CAT flight_witness launches=%s first_landing=%s" % [evidence.launches,evidence.first_landing])
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.landed.disconnect(on_landing)
	game.skater.bailed.disconnect(on_bail)


static func _first_rail_witness(game: Node, first, evidence: Dictionary) -> void:
	# Observations only: retain the closest actual descending approach so a
	# missing catch cannot be mistaken for a score/payoff or competing-ID issue.
	if not game.skater.airborne or game.skater.grinding or game.skater.velocity.y > 1.0:
		return
	var near: Dictionary = first.closest(game.skater.global_position)
	if near.is_empty(): return
	evidence.descending_samples += 1
	if not evidence.closest_a.is_empty() and float(near.gap) >= float(evidence.closest_a.gap): return
	var horizontal := Vector3(game.skater.velocity.x, 0, game.skater.velocity.z)
	var tangent: Vector3 = first.dir_at(near.dist)
	tangent.y = 0.0
	evidence.closest_a = {"position": game.skater.global_position, "rail_point": near.point,
		"gap": near.gap, "height_above_rail": game.skater.global_position.y - near.point.y,
		"speed": game.skater.speed, "velocity": game.skater.velocity,
		"alignment": horizontal.normalized().dot(tangent.normalized()),
		"grounded": game.skater.is_on_floor(), "grind_held": Input.is_action_pressed("grind")}


static func _payoff(tree: SceneTree, game: Node, check: Callable) -> void:
	var actor = game.cat_encounter.get_node("RaeBinBusker")
	var first_cat: Node3D = actor.get_node("FabricCatOne")
	var second_cat: Node3D = actor.get_node("FabricCatTwo")
	var drummer: Node3D = actor.get_node("StreetDrummer")
	var indicator: MeshInstance3D = actor.get_node("ChargeIndicator1")
	var anchor: Vector3 = game.cat_encounter.status_snapshot().position
	var stage_point := anchor + Vector3(0, 0.8, 0)
	var camera: Camera3D = tree.root.get_camera_3d()
	var banked: int = game.score.total_score
	check.call(game.cat_encounter.status_snapshot().celebration_state == "queued"
		and not game.cat_encounter.status_snapshot().celebration_started
		and not actor.animation_snapshot().dance_active
		and not camera.is_position_in_frustum(stage_point),
		"cat presentation: the real offscreen final bank queues its earned payoff for the returning player")
	var trigger_visible := false
	var trigger_distance := INF
	var return_frames := 0
	# Return through the real gap between B and C. No camera transform or
	# visibility flag is assigned: production main queries its chase camera.
	for frame in range(240):
		var offset := Vector3(4.0 - game.skater.global_position.x, 0.0,
			-93.0 - game.skater.global_position.z)
		_aim(game.skater, offset)
		Input.action_press("push")
		await _frames(tree, 1)
		return_frames += 1
		if game.cat_encounter.status_snapshot().celebration_started:
			trigger_visible = camera.is_position_in_frustum(stage_point)
			var relative: Vector3 = game.skater.global_position - anchor
			trigger_distance = Vector2(relative.x, relative.z).length()
			break
	_release()
	check.call(game.cat_encounter.status_snapshot().celebration_started and actor.animation_snapshot().dance_active
		and trigger_visible and trigger_distance <= 10.0 and game.cat_encounter.status_snapshot().wins == 1
		and game.score.total_score == banked,
		"cat presentation: actual input return and the production camera frustum start one visible payoff")
	var first_active_pose := _pose_snapshot(first_cat)
	var second_active_pose := _pose_snapshot(second_cat)
	var drummer_active_pose := _pose_snapshot(drummer)
	await _frames(tree, 8)
	check.call(actor.animation_snapshot().dance_active and not _same_pose(first_cat, first_active_pose)
		and not _same_pose(second_cat, second_active_pose) and not _same_pose(drummer, drummer_active_pose),
		"Techno Bin presentation: the earned visible payoff actually moves both soft cats and the drummer")
	var elapsed: float = actor.animation_snapshot().dance_elapsed
	game.toggle_pause()
	await _frames(tree, 20)
	check.call(not actor.can_process() and is_equal_approx(actor.animation_snapshot().dance_elapsed, elapsed),
		"cat presentation: menu pause freezes the accepted payoff")
	game.toggle_pause()
	Input.action_press("brake")
	for frame in range(210):
		_aim(game.skater, anchor - game.skater.global_position)
		await _frames(tree, 1)
	_release()
	check.call(not actor.animation_snapshot().dance_active
		and is_equal_approx(actor.animation_snapshot().dance_elapsed, actor.animation_snapshot().dance_duration)
		and game.cat_encounter.status_snapshot().celebration_state == "finished"
		and game.cat_encounter.status_snapshot().wins == 1 and game.score.total_score == banked,
		"cat presentation: the visible payoff completes its full bound without another completion")
	game.apply_settings({"reduced_motion": true}, false)
	var first_pose := _pose_snapshot(first_cat)
	var second_pose := _pose_snapshot(second_cat)
	var drummer_pose := _pose_snapshot(drummer)
	var reduced_beat_phase: float = actor.animation_snapshot().drum_phase
	var indicator_colour: Color = indicator.material_override.albedo_color
	await _frames(tree, 30)
	check.call(actor.animation_snapshot().reduced_motion and not actor.animation_snapshot().dance_active
		and _same_pose(first_cat, first_pose) and _same_pose(second_cat, second_pose)
		and _same_pose(drummer, drummer_pose)
		and not is_equal_approx(actor.animation_snapshot().drum_phase, reduced_beat_phase)
		and indicator.material_override.albedo_color == indicator_colour,
		"cat presentation: reduced motion holds both cats and drummer still while the underlying drum clock continues")
	game.apply_settings({"reduced_motion": false}, false)
	await _frames(tree, 30)
	check.call(not actor.animation_snapshot().dance_active
		and is_equal_approx(actor.animation_snapshot().dance_elapsed, actor.animation_snapshot().dance_duration)
		and game.cat_encounter.status_snapshot().wins == 1 and game.score.total_score == banked,
		"cat presentation: lingering and toggling motion cannot replay the completed payoff or reward")
	print("CAT audience returned_frames=%d trigger_distance=%.2f frustum=%s celebration=%s elapsed=%.2f" % [
		return_frames, trigger_distance, trigger_visible, game.cat_encounter.status_snapshot().celebration_state,
		actor.animation_snapshot().dance_elapsed])


static func _lifecycle(tree: SceneTree, game: Node, check: Callable) -> void:
	var anchor: Vector3 = game.cat_encounter.status_snapshot().position
	await _reset(tree, game, anchor + Vector3(0, 0.8, 3), false)
	await _interact(tree)
	check.call(game.cat_encounter.status_snapshot().state == "active",
		"cat integration: mapped nearby interaction starts the production attempt")
	var remaining: float = game.cat_encounter.status_snapshot().remaining
	game.toggle_pause()
	await _frames(tree, 20)
	check.call(game.paused and is_equal_approx(game.cat_encounter.status_snapshot().remaining, remaining),
		"cat integration: pause freezes the challenge deadline")
	game.toggle_pause()
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	game.time_remaining = 0.03 # Explicit clock boundary fixture, no score/movement injection.
	await _frames(tree, 4)
	check.call(game.time_remaining == 0.0 and game.score.get_combo_value() > 0
		and game.cat_encounter.status_snapshot().state == "failed"
		and game.cat_encounter.status_snapshot().wins == 0,
		"cat integration: career expiry ends the side attempt while the real airborne combo still resolves")
	await _frames(tree, 100)
	await _interact(tree)
	check.call(game.run_finished and game.cat_encounter.status_snapshot().attempts == 1
		and game.cat_encounter.status_snapshot().wins == 0,
		"cat integration: final banking or results-screen interaction cannot revive an expired attempt")
	var completed: Array = game.career.completed_ids.duplicate()
	game.restart_run()
	await _frames(tree, 45)
	check.call(game.cat_encounter.status_snapshot().state == "idle"
		and game.cat_encounter.status_snapshot().sequence_index == 0
		and game.cat_encounter.status_snapshot().attempts == 0
		and game.career.completed_ids == completed,
		"cat integration: restart clears the challenge while retaining career identity")
	await _interact(tree)
	var bail_approach: bool = await _drive_to(tree, game, anchor + Vector3(-10, 0, 3))
	game.skater.rotation.y = -PI / 2.0 # Aim the clear front of the workshop before motion.
	var evidence := {"bails": 0}
	var on_bail := func(): evidence.bails += 1
	game.skater.bailed.connect(on_bail)
	Input.action_press("push")
	await _frames(tree, 20)
	Input.action_release("push")
	Input.action_press("manual")
	await _frames(tree, 2)
	var entered: bool = game.skater.manual_active
	for frame in range(280):
		await _frames(tree, 1)
		if evidence.bails > 0: break
	_release()
	check.call(bail_approach and entered and evidence.bails == 1 and game.cat_encounter.status_snapshot().state == "failed"
		and game.cat_encounter.status_snapshot().wins == 0 and game.score.get_combo_value() == 0,
		"cat integration: actual manual imbalance bails once and clears the live attempt and pending score")
	print("CAT bail entered=%s bails=%d state=%s reason=%s position=%s speed=%.2f manual=%s" % [
		entered, evidence.bails, game.cat_encounter.status_snapshot().state,
		game.cat_encounter.status_snapshot().reason, game.skater.global_position,
		game.skater.speed, game.skater.manual_active])
	game.skater.bailed.disconnect(on_bail)


static func _actor_structure(actor: Node3D, check: Callable) -> void:
	var first_cat := actor.get_node_or_null("FabricCatOne") as Node3D
	var second_cat := actor.get_node_or_null("FabricCatTwo") as Node3D
	check.call(first_cat != null and second_cat != null and first_cat != second_cat
		and _has_fabric_mesh(first_cat) and _has_fabric_mesh(second_cat)
		and actor.animation_snapshot().soft_cat_count == 2,
		"Techno Bin presentation: two separate visible cat props use soft nonmetal materials")
	var drummer := actor.get_node_or_null("StreetDrummer") as Node3D
	var kit := actor.get_node_or_null("BinDrumKit") as Node3D
	check.call(drummer != null and kit != null and _has_visible_mesh(drummer)
		and _has_visible_mesh(kit) and actor.animation_snapshot().drummer_active,
		"Techno Bin presentation: the active street drummer has a visible improvised bin kit")
	var sign := actor.get_node_or_null("PitchSign") as Label3D
	# The owner removed hovering text; retain state identity without a rendered sign.
	check.call(sign != null and not sign.visible and sign.billboard == BaseMaterial3D.BILLBOARD_DISABLED
		and "TECHNO BIN" in sign.text.to_upper()
		and not "MECHANICAL" in sign.text.to_upper() and sign.font_size >= 24
		and sign.pixel_size >= 0.002 and sign.outline_size > 0 and sign.visibility_range_end >= 10.0,
		"Techno Bin presentation: hidden logical state identifies the corrected act without hovering text")


static func _audio_controls(tree: SceneTree, game: Node, check: Callable) -> void:
	var anchor: Vector3 = game.cat_encounter.status_snapshot().position
	await _reset(tree, game, anchor + Vector3(0, 0.8, 3), false)
	var actor: Node = game.cat_encounter.get_node("RaeBinBusker")
	var players := actor.find_children("*", "AudioStreamPlayer3D", true, false)
	check.call(players.size() == 1,
		"Techno Bin audio: the performer owns exactly one spatial percussion source")
	if players.size() != 1: return
	var player := players[0] as AudioStreamPlayer3D
	var stream := player.stream as AudioStreamWAV
	check.call(stream != null and stream.format == AudioStreamWAV.FORMAT_16_BITS
		and not stream.stereo and stream.get_length() >= 2.0 and stream.get_length() <= 12.0
		and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and player.max_distance <= 32.0,
		"Techno Bin audio: original percussion is a bounded spatial mono PCM loop")
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
			"Techno Bin audio: generated drum samples carry energy without clipping or a loud loop seam")
	game.apply_settings({"audio": 1.0, "ambience_volume": 1.0}, false)
	var full_gain: float = db_to_linear(player.volume_db)
	game.cat_encounter.set_mix(NAN, 1.0)
	var invalid_master_muted: bool = not player.playing and player.volume_db <= -70.0
	game.cat_encounter.set_mix(1.0, NAN)
	var invalid_ambience_muted: bool = not player.playing and player.volume_db <= -70.0
	game.cat_encounter.set_mix(2.0, 2.0)
	check.call(invalid_master_muted and invalid_ambience_muted
		and is_equal_approx(db_to_linear(player.volume_db), full_gain),
		"Techno Bin audio: nonfinite gains mute safely and excessive direct gains clamp to full mix")
	game.apply_settings({"audio": 0.5, "ambience_volume": 0.5}, false)
	check.call(full_gain > 0.0 and is_equal_approx(db_to_linear(player.volume_db), full_gain * 0.25),
		"Techno Bin audio: the public master and ambience controls both scale the drum mix")
	game.apply_settings({"audio": 0.0, "ambience_volume": 1.0}, false)
	var master_muted: bool = not player.playing and player.volume_db <= -70.0
	game.apply_settings({"audio": 1.0, "ambience_volume": 0.0}, false)
	check.call(master_muted and not player.playing and player.volume_db <= -70.0,
		"Techno Bin audio: either mute control stops the percussion source")
	game.apply_settings({"audio": 1.0, "ambience_volume": 1.0}, false)
	var phase: float = actor.animation_snapshot().drum_phase
	game.toggle_pause()
	await _frames(tree, 12)
	check.call(not player.can_process() and not actor.can_process()
		and is_equal_approx(actor.animation_snapshot().drum_phase, phase),
		"Techno Bin audio: a real menu pause suspends the source and visible drum rhythm")
	game.toggle_pause()
	await _frames(tree, 2)
	check.call(player.can_process() and actor.animation_snapshot().audio_enabled
		and actor.animation_snapshot().drum_phase > phase,
		"Techno Bin audio: resuming restores performer processing and rhythm")
	game.time_remaining = 0.01 # Explicit run-boundary fixture; no movement or score injection.
	await _frames(tree, 3)
	phase = actor.animation_snapshot().drum_phase
	game.apply_settings({"audio": 0.5, "ambience_volume": 1.0}, false)
	await _frames(tree, 3)
	check.call(game.run_finished and not actor.animation_snapshot().audio_enabled
		and not actor.animation_snapshot().drummer_active and not player.playing
		and is_equal_approx(actor.animation_snapshot().drum_phase, phase),
		"Techno Bin audio: run end stops the beat and changing settings cannot restart a finished act")
	game.restart_run()
	var restarted_phase: float = actor.animation_snapshot().drum_phase
	await _frames(tree, 3)
	check.call(actor.animation_snapshot().audio_enabled and actor.animation_snapshot().drummer_active
		and actor.animation_snapshot().drum_phase > restarted_phase,
		"Techno Bin audio: the next run restores the local street performance")
	# Dummy-driver evidence establishes data/gates, not audible playback quality.


static func _has_visible_mesh(parent: Node3D) -> bool:
	if parent == null or not parent.is_visible_in_tree(): return false
	for child in parent.find_children("*", "MeshInstance3D", true, false):
		if child.is_visible_in_tree() and child.mesh != null: return true
	return false


static func _has_fabric_mesh(parent: Node3D) -> bool:
	if parent == null or not parent.is_visible_in_tree(): return false
	for child in parent.find_children("*", "MeshInstance3D", true, false):
		var material: StandardMaterial3D = child.material_override as StandardMaterial3D
		if child.is_visible_in_tree() and child.mesh != null and material != null:
			if material.metallic <= 0.1 and material.roughness >= 0.65: return true
	return false


static func _pose_snapshot(parent: Node3D) -> Dictionary:
	var poses := {".": parent.transform}
	for child in parent.find_children("*", "Node3D", true, false):
		poses[String(parent.get_path_to(child))] = child.transform
	return poses


static func _same_pose(parent: Node3D, poses: Dictionary) -> bool:
	for path: String in poses:
		var node := parent.get_node_or_null(path) as Node3D
		if node == null or not node.transform.is_equal_approx(poses[path]): return false
	return true


static func _reset(tree: SceneTree, game: Node, at: Vector3, free: bool) -> void:
	_release()
	game.skater.spawn_position = at
	game.start_mode(free)
	await _frames(tree, 45)


static func _drive_to(tree: SceneTree, game: Node, target: Vector3) -> bool:
	for frame in range(360):
		var offset := Vector3(target.x - game.skater.global_position.x, 0.0,
			target.z - game.skater.global_position.z)
		if offset.length() < 0.65:
			_release()
			return true
		_aim(game.skater, offset)
		if game.skater.speed > sqrt(30.0 * offset.length()):
			Input.action_release("push")
			Input.action_press("brake")
		else:
			Input.action_release("brake")
			Input.action_press("push")
		await _frames(tree, 1)
		if game.cat_encounter.status_snapshot().state != "active": break
	_release()
	return false


static func _aim(skater: CharacterBody3D, direction: Vector3) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	var desired: float = atan2(-direction.x, -direction.z)
	if skater.is_on_floor(): skater.rotation.y = desired
	else:
		var difference: float = angle_difference(skater.rotation.y, desired)
		if absf(difference) > 0.04:
			Input.action_press("steer_left" if difference > 0.0 else "steer_right", minf(1.0, absf(difference) * 4.0))


static func _balance(skater: CharacterBody3D) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if skater.grind_balance > 0.05: Input.action_press("steer_left")
	elif skater.grind_balance < -0.05: Input.action_press("steer_right")


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
