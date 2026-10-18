extends RefCounted
## Actual player-state regressions; run without a gameplay scene in the tree.
const SkaterScript = preload("res://game/player/skater.gd")
const InputSetup = preload("res://game/core/input_setup.gd")
const ScoreSession = preload("res://game/scoring/score_session.gd")

## Native-tick input driver and parent-before-player score order, as in Main.
## Only controls change after spawning; no motion, cooldown or score injection.
class ManualBufferFixture extends Node3D:
	var rider: CharacterBody3D
	var score: RefCounted = ScoreSession.new()
	var scenario: String
	var phase: int = 0
	var exit_tick: int = -1
	var entries: Array[int] = []
	var manual_press_ticks: Array[int] = []
	var banks: Array[int] = []
	var samples: Dictionary = {}
	var bails: int = 0
	var done: bool = false
	var start_position: Vector3

	func _ready() -> void:
		var floor_body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(150, 1, 180)
		collision.shape = shape
		floor_body.position.y = -0.5
		floor_body.add_child(collision)
		add_child(floor_body)
		rider = SkaterScript.new()
		add_child(rider)
		start_position = rider.global_position
		rider.trick_performed.connect(score.add_trick)
		rider.combo_link_started.connect(func() -> void:
			entries.append(Engine.get_physics_frames())
			score.continue_combo())
		rider.combo_link_ended.connect(func() -> void:
			if exit_tick < 0: exit_tick = Engine.get_physics_frames()
			score.begin_landing())
		rider.bailed.connect(func() -> void:
			bails += 1
			score.drop_combo())

	func _physics_process(delta: float) -> void:
		var tick: int = Engine.get_physics_frames()
		if Input.is_action_just_pressed("manual"):
			manual_press_ticks.append(tick)
		if exit_tick >= 0:
			# The child completed the preceding native tick; retain even ticks
			# a slower rendered frame/coroutine would otherwise skip.
			samples[tick - exit_tick - 1] = {"active": rider.manual_active,
				"cooldown": rider._manual_cooldown, "buffer": rider._manual_buffer_remaining,
				"speed": rider.speed, "floor": rider.is_on_floor(),
				"held": Input.is_action_pressed("manual")}
		if phase == 0:
			if not Input.is_action_pressed("push"): Input.action_press("push")
			if rider.is_on_floor() and rider.speed >= 6.0:
				Input.action_release("push")
				Input.action_press("manual")
				phase = 1
		elif phase == 1:
			# A press sent during physics can expose its fresh edge next tick.
			# Keep it held until the real child confirms entry before releasing.
			if rider.manual_active:
				Input.action_release("manual")
				phase = 2
		elif exit_tick >= 0:
			var elapsed: int = tick - exit_tick
			if scenario == "too_early" and elapsed == 1:
				Input.action_press("manual")
			if scenario == "outside_window" and elapsed == 12:
				Input.action_press("manual")
			if scenario == "expired" and elapsed == 6:
				Input.action_press("brake")
			if scenario == "gesture":
				if elapsed == 13: Input.action_press("push")
				if elapsed == 14: Input.action_release("push")
				if elapsed == 15: Input.action_press("brake")
				if elapsed == 16: Input.action_release("brake")
			elif scenario != "too_early" and scenario != "outside_window" and elapsed == 15:
				Input.action_press("manual")
			if scenario == "released" and rider._manual_buffer_remaining > 0.0:
				Input.action_release("manual")
			if scenario == "expired":
				if elapsed == 25: Input.action_release("brake")
				if elapsed == 26: Input.action_press("push")
			done = elapsed >= (55 if scenario == "expired" else 27)
		if rider.airborne or rider.manual_active:
			score.continue_combo()
		if score.tick(delta) > 0:
			banks.append(tick)

static func run(tree: SceneTree, check: Callable) -> void:
	InputSetup.register_actions()
	_release_actions()
	var fixture := Node3D.new()
	tree.root.add_child(fixture)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(150, 1, 180)
	collision.shape = shape
	floor_body.position.y = -0.5
	floor_body.add_child(collision)
	fixture.add_child(floor_body)
	var skater = SkaterScript.new()
	fixture.add_child(skater)
	var events := {"Manual": 0, "Revert": 0, "starts": 0, "ends": 0, "bails": 0}
	skater.trick_performed.connect(func(label: String, _points: int) -> void:
		if events.has(label):
			events[label] += 1)
	skater.combo_link_started.connect(func() -> void: events["starts"] += 1)
	skater.combo_link_ended.connect(func() -> void: events["ends"] += 1)
	skater.bailed.connect(func() -> void: events["bails"] += 1)
	await _frames(tree, 45)
	check.call(skater.is_on_floor(), "manual: fixture reaches actual floor support")
	Input.action_press("manual")
	await _frames(tree, 1)
	check.call(not skater.manual_active, "manual: stopped input cannot start a manual")
	skater.speed = 8.0
	await _frames(tree, 2)
	check.call(not skater.manual_active, "manual: held rejected input cannot enter when speed becomes eligible")
	Input.action_release("manual")
	await _frames(tree, 1)
	Input.action_press("manual")
	await _frames(tree, 1)
	check.call(skater.manual_active and events["Manual"] == 1 and events["starts"] == 1,
		"manual: fresh supported entry scores once and starts one combo link")
	await _frames(tree, 20)
	check.call(skater.manual_active and events["Manual"] == 1 and skater.manual_balance > 0.05,
		"manual: held ride drifts visibly without repeat entry points")
	check.call(skater.get_node("SkaterVisual/Board").rotation.x > 0.20,
		"manual: real board pose raises its nose while balanced")
	var balance: float = skater.manual_balance
	Input.action_press("brake")
	await _frames(tree, 6)
	Input.action_release("brake")
	check.call(skater.manual_balance > balance + 0.1, "manual: braking input shifts balance forward")
	balance = skater.manual_balance
	Input.action_press("push")
	await _frames(tree, 6)
	Input.action_release("push")
	check.call(skater.manual_balance < balance - 0.1, "manual: pushing input corrects forward balance")
	Input.action_release("manual")
	await _frames(tree, 1)
	check.call(not skater.manual_active and events["ends"] == 1,
		"manual: release ends the supported link exactly once")
	Input.action_press("manual")
	await _frames(tree, 1)
	check.call(not skater.manual_active, "manual: immediate fresh reentry is blocked by cooldown")
	await _frames(tree, 25)
	check.call(not skater.manual_active and events["ends"] == 1,
		"manual: holding through cooldown cannot manufacture a new entry")
	Input.action_release("manual")
	await _frames(tree, 1)
	Input.action_press("manual")
	await _frames(tree, 1)
	check.call(skater.manual_active and events["Manual"] == 2,
		"manual: fresh input after cooldown can enter again")
	var starts: int = events["starts"]
	var ends: int = events["ends"]
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(skater.airborne and not skater.manual_active and events["starts"] == starts + 1
		and events["ends"] == ends, "manual: eligible ollie continues link without a ground-end event")
	await _land(tree, skater)
	check.call(not skater.manual_active and events["Manual"] == 2,
		"manual: holding through air and landing cannot auto-enter another manual")
	_release_actions()
	await _frames(tree, 24)
	skater.speed = 8.0
	Input.action_press("manual")
	await _frames(tree, 1)
	ends = events["ends"]
	skater.speed = 1.9
	await _frames(tree, 1)
	check.call(not skater.manual_active and events["ends"] == ends + 1,
		"manual: losing required speed ends one supported link")
	_release_actions()
	await _frames(tree, 23)
	skater.speed = 8.0
	Input.action_press("manual")
	await _frames(tree, 1)
	Input.action_press("brake")
	await _frames(tree, 40)
	check.call(events["bails"] == 1 and not skater.manual_active,
		"manual: actual balance input exceeding the limit bails once and clears state")
	_release_actions()
	await _frames(tree, 45)
	skater.speed = 8.0
	skater.set_trick_entries_enabled(false)
	Input.action_press("manual")
	Input.action_press("ollie")
	Input.action_press("revert")
	await _frames(tree, 2)
	check.call(not skater.manual_active and not skater.airborne and events["Revert"] == 0,
		"manual/revert: overtime entry gate rejects all fresh grounded links")
	_release_actions()
	skater.set_trick_entries_enabled(true)
	await _frames(tree, 1)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("revert")
	await _frames(tree, 2)
	check.call(events["Revert"] == 0, "revert: a fresh airborne press is ineligible")
	await _land(tree, skater)
	check.call(events["Revert"] == 0 and skater.revert_remaining > 0.0,
		"revert: landing opens eligibility but a held early press stays rejected")
	Input.action_release("revert")
	await _frames(tree, 1)
	var speed_before: float = skater.speed
	var window_before: float = skater.revert_remaining
	var heading_before: float = skater.rotation.y
	starts = events["starts"]
	Input.action_press("revert")
	await _frames(tree, 1)
	check.call(events["Revert"] == 1 and events["starts"] == starts,
		"revert: eligible fresh entry scores once without starting a new landing link")
	check.call(absf(skater.speed - (speed_before - 0.75 / 60.0) * 0.85) < 0.03,
		"revert: accepted entry applies the documented 15 percent speed cost")
	check.call(skater.revert_remaining < window_before and skater.rotation.y == heading_before,
		"revert: entry neither refreshes eligibility nor changes travel heading")
	Input.action_release("revert")
	await _frames(tree, 1)
	Input.action_press("revert")
	await _frames(tree, 1)
	check.call(events["Revert"] == 1, "revert: another fresh press on the same landing cannot score twice")
	Input.action_release("revert")
	await _frames(tree, 12)
	check.call(absf(absf(skater.get_node("SkaterVisual").rotation.y) - PI) < 0.05,
		"revert: completed visual turn visibly changes stance by 180 degrees")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	await _land(tree, skater)
	await _frames(tree, 23)
	Input.action_press("revert")
	await _frames(tree, 1)
	check.call(events["Revert"] == 1 and skater.revert_remaining == 0.0,
		"revert: a press after the original landing deadline is rejected")
	_release_actions()
	skater.reset_skater()
	check.call(not skater.manual_active and skater.manual_balance == 0.0 and skater.revert_remaining == 0.0,
		"manual/revert: reset clears balance, holds, cooldown eligibility and visual transition")
	await _frames(tree, 45)
	check.call(not skater.try_special("special_clyde_carousel"),
		"special: ordinary ground travel cannot execute an aerial special")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(not skater.try_special("unknown_special"), "special: unknown ID cannot score or use an air slot")
	tree.paused = true
	check.call(not skater.try_special("special_clyde_carousel"), "special: direct requests reject while gameplay is paused")
	tree.paused = false
	skater.set_trick_entries_enabled(false)
	check.call(not skater.try_special("special_clyde_carousel"), "special: overtime blocks a fresh aerial special")
	skater.set_trick_entries_enabled(true)
	skater.set_controls_enabled(false)
	check.call(not skater.try_special("special_clyde_carousel"), "special: disabled controls reject a fresh request")
	skater.set_controls_enabled(true)
	var original_velocity: Vector3 = skater.velocity
	check.call(skater.try_special("special_clyde_carousel") and skater.special_name == "Clyde Carousel",
		"special: eligible fresh air request exposes the accepted display name")
	check.call(skater.velocity == original_velocity,
		"special: accepting a cosmetic move preserves the physical velocity")
	check.call(not skater.try_special("special_clyde_carousel") and not skater.try_special("special_tenement_tumble"),
		"special: neither repeating nor switching IDs bypasses one execution per airtime")
	await _frames(tree, 5)
	check.call(skater.get_node("SkaterVisual/Board").rotation.y > 0.2,
		"special: Clyde Carousel actually rotates the visible board horizontally")
	await _frames(tree, 35)
	check.call(skater.special_name.is_empty() and not skater.try_special("special_clyde_carousel"),
		"special: finished animation clears its label without reopening the air slot")
	await _land(tree, skater)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(skater.try_special("special_tenement_tumble"),
		"special: a new actual airtime permits the other catalog special")
	await _frames(tree, 6)
	check.call(skater.get_node("SkaterVisual").rotation.x > 0.5
		and skater.get_node("BodyCollision").rotation == Vector3.ZERO,
		"special: Tenement Tumble rotates the visual while collision stays upright")
	skater.reset_skater()
	check.call(skater.special_name.is_empty() and skater.get_node("SkaterVisual").rotation == Vector3.ZERO,
		"special: reset clears the active label and restores the visual transform")
	_release_actions()
	fixture.queue_free()
	await tree.process_frame
	await _frames(tree, 1)
	await _manual_request_buffer(tree, check)

static func _manual_request_buffer(tree: SceneTree, check: Callable) -> void:
	InputSetup.register_actions()
	for scenario: String in ["held", "gesture", "too_early", "outside_window", "released", "expired"]:
		_release_actions()
		var fixture := ManualBufferFixture.new()
		fixture.scenario = scenario
		tree.root.add_child(fixture)
		for frame in 240:
			await _frames(tree, 1)
			if fixture.done: break
		var rider: CharacterBody3D = fixture.rider
		var prefix: String = "manual buffer (%s): " % scenario
		var request_elapsed: int = 15 if scenario == "gesture" else (
			fixture.manual_press_ticks.back() - fixture.exit_tick if fixture.manual_press_ticks.size() >= 2 else -1)
		print("MANUAL BUFFER %s phase=%d processing=%s done=%s entries=%s exit=%d presses=%s request_elapsed=%d samples=%d position=%s speed=%.6f floor=%s active=%s cooldown=%.15f controls=%s banks=%s request=%s before=%s eligible=%s" % [
			scenario, fixture.phase, fixture.is_physics_processing(), fixture.done, fixture.entries,
			fixture.exit_tick, fixture.manual_press_ticks, request_elapsed, fixture.samples.size(),
			rider.global_position, rider.speed, rider.is_on_floor(), rider.manual_active,
			rider._manual_cooldown, rider._controls_enabled, fixture.banks,
			fixture.samples.get(request_elapsed, {}), fixture.samples.get(20, {}), fixture.samples.get(21, {})])
		check.call(fixture.done and fixture.exit_tick >= 0 and fixture.bails == 0
			and rider.global_position.distance_to(fixture.start_position) > 2.0,
			prefix + "real push, supported manual and release establish the recovery window")
		var before: Dictionary = fixture.samples.get(20, {})
		var eligible: Dictionary = fixture.samples.get(21, {})
		check.call(not before.is_empty() and not eligible.is_empty()
			and not bool(before.get("active", true)) and float(before.get("cooldown", 0.0)) > 0.0
			and float(eligible.get("cooldown", -1.0)) == 0.0,
			prefix + "full 0.35-second recovery expires on native tick 21, never tick 20 or 22")
		check.call(fixture.banks.size() == 1 and fixture.banks[0] - fixture.exit_tick == 21
			and fixture.score.total_score == 100,
			prefix + "pending input cannot extend or duplicate the original 0.35-second bank")
		if scenario == "held" or scenario == "gesture":
			var requested: Dictionary = fixture.samples.get(request_elapsed, {})
			check.call(float(requested.get("buffer", 0.0)) > 0.0
				and not bool(requested.get("active", true))
				and fixture.entries.size() == 2 and fixture.entries[1] - fixture.exit_tick == 21
				and rider.manual_active and fixture.score.get_combo_value() == 100,
				prefix + "one fresh near-expiry request waits, then enters exactly once on eligible floor")
			if scenario == "gesture":
				check.call(not Input.is_action_pressed("manual") and rider.manual_id == "manual",
					prefix + "neutral-separated Up/Down retains its latched selection through recovery")
		else:
			check.call(fixture.entries.size() == 1 and not rider.manual_active
				and fixture.score.get_combo_value() == 0,
				prefix + "rejected, released or expired input cannot manufacture another link or award")
			if scenario == "too_early" or scenario == "outside_window":
				var early: Dictionary = fixture.samples.get(request_elapsed, {})
				check.call(float(early.get("cooldown", 0.0)) > 0.12
					and float(early.get("buffer", -1.0)) == 0.0 and Input.is_action_pressed("manual"),
					prefix + "a too-early fresh press stays rejected even when held beyond recovery")
				if scenario == "outside_window":
					check.call(request_elapsed == 13 and float(early.get("cooldown", 1.0)) < 0.14,
						prefix + "the observed fresh edge is just outside the 120ms buffer boundary")
			else:
				var requested: Dictionary = fixture.samples.get(request_elapsed, {})
				check.call(float(requested.get("buffer", 0.0)) > 0.0,
					prefix + "the fresh press was actually buffered before rejection")
				if scenario == "released":
					check.call(not bool(eligible.get("held", true)) and bool(eligible.get("floor", false))
						and absf(float(eligible.get("speed", 0.0))) >= 2.0,
						prefix + "release alone rejects the otherwise eligible supported entry")
				else:
					check.call(absf(float(eligible.get("speed", 10.0))) < 2.0
						and rider.speed > 2.0 and Input.is_action_pressed("manual")
						and rider._manual_buffer_remaining == 0.0,
						prefix + "actual braking spends the buffer; later pushing cannot revive the held request")
		_release_actions()
		fixture.queue_free()
		await tree.process_frame
		await _frames(tree, 1)

static func _land(tree: SceneTree, skater: CharacterBody3D) -> void:
	for i in range(100):
		if skater.is_on_floor() and not skater.airborne:
			return
		await _frames(tree, 1)

static func _frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame
		await tree.process_frame

static func _release_actions() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
