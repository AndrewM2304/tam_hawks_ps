extends RefCounted
## Actual player-state regressions; run without a gameplay scene in the tree.
const SkaterScript = preload("res://game/player/skater.gd")
const InputSetup = preload("res://game/core/input_setup.gd")

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
