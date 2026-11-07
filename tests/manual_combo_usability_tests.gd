extends RefCounted
## Actual Main landing requests and links. Only mapped input changes after reset.
## HUD endpoint fixtures are separate presentation diagnostics, not earned runs.
const ManualBalance = preload("res://tests/support/manual_balance_driver.gd")
const HUD = preload("res://game/ui/hud.gd")
const Profile = preload("res://game/core/input_profile.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var old_spawn: Vector3 = game.skater.spawn_position
	var old_free: bool = game.free_skate_mode
	game.skater.spawn_position = game.world.get_spawn_position()
	var calibration: Dictionary = await _landing_case(tree, game, "calibration", -1000, "none", false, check)
	var contact: int = calibration.contact
	check.call(contact > 22, "manual usability: actual default Main Ollie/Kickflip calibrates an independent native landing")
	# The 350 ms freshness window is exclusive at expiry; 333 ms is still
	# fresh, 350/367/450 ms are stale. Ground recovery remains 120 ms.
	for before: int in [6, 12, 18, 20, 21, 22, 27]:
		await _landing_case(tree, game, "held_%dms" % roundi(before * 1000.0 / 60.0), contact - before, "held", before < 21, check)
	await _landing_case(tree, game, "released_200ms", contact - 12, "released", false, check)
	await _landing_case(tree, game, "held_since_takeoff", 1, "held", false, check)
	await _landing_case(tree, game, "gesture_200ms", contact - 12, "gesture", true, check)
	await _landing_case(tree, game, "paused_request", contact - 12, "paused", false, check)
	await _linked_air_again(tree, game, contact, check)
	await _restart_request(tree, game, check)
	await _meter(tree, check)
	_release()
	game.skater.spawn_position = old_spawn
	game.start_mode(old_free)
	await _frames(tree, 2)


static func _prepare_jump(tree: SceneTree, game: Node) -> void:
	_release()
	game.start_mode(true)
	await _frames(tree, 40)
	Input.action_press("push")
	await _frames(tree, 40)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")


static func _landing_case(tree: SceneTree, game: Node, label: String, request: int,
		mode: String, expect_manual: bool, check: Callable) -> Dictionary:
	await _prepare_jump(tree, game)
	var seen: Array[String] = []
	var on_trick := func(name: String, _points: int) -> void: seen.append(name)
	game.skater.trick_performed.connect(on_trick)
	var contact := -1
	var entry := -1
	var supported := true
	var queued_seen := false
	for tick: int in 82:
		if tick == 1: Input.action_press("flip")
		if tick == 3: Input.action_release("flip")
		if tick == request:
			if mode == "gesture": Input.action_press("push")
			else: Input.action_press("manual")
		if mode == "released" and tick == request + 4: Input.action_release("manual")
		if mode == "gesture":
			if tick == request + 1: Input.action_release("push")
			if tick == request + 2: Input.action_press("brake")
			if tick == request + 3: Input.action_release("brake")
		if mode == "paused" and tick == request + 2:
			game.toggle_pause()
			await _frames(tree, 3)
			game.toggle_pause()
		await _frames(tree, 1)
		if bool(game.hud._state.get("manual_queued",false)):
			queued_seen = true
			check.call(game.hud._combo_status.text.contains("MANUAL QUEUED"),
				"manual usability: a fresh airborne request has immediate queued feedback")
		if contact < 0 and game.skater.is_on_floor() and not game.skater.airborne: contact = tick
		if game.skater.manual_active:
			if entry < 0: entry = tick
			supported = supported and game.skater.is_on_floor() and not game.skater.airborne
			ManualBalance.hold(game.skater, 0.025, 0.3)
	var manual_count: int = seen.count("Manual")
	check.call(not game.skater.manual_request_pending() and not bool(game.hud._state.get("manual_queued",false)),
		"manual usability: %s consumed, expired or cancelled request clears the queued cue" % label)
	if expect_manual:
		check.call(queued_seen, "manual usability: %s actually presents its fresh landing request before admission" % label)
	check.call(contact >= 0 and not game.skater.bail_active and supported,
		"manual usability: %s completes actual native contact without an unsupported manual or bail" % label)
	check.call((entry >= 0) == expect_manual and manual_count == (1 if expect_manual else 0),
		"manual usability: %s has the declared fresh/stale/cancelled admission exactly once" % label)
	if expect_manual:
		check.call(entry >= contact and game.score.total_score == 0 and game.score.get_combo_value() == 1500,
			"manual usability: %s links the actual Ollie/Kickflip without a premature bank" % label)
		_release()
		if mode == "gesture":
			# Completed gestures intentionally latch: a fresh Manual press ends
			# them. Releasing their direction inputs must not terminate the ride.
			Input.action_press("manual")
			await _frames(tree, 1)
			Input.action_release("manual")
		await _frames(tree, 26)
		var banked: int = game.score.total_score
		await _frames(tree, 24)
		check.call(banked == 1500 and game.score.total_score == banked and game.score.get_combo_value() == 0,
			"manual usability: %s release banks the three-entry combo once" % label)
	else:
		check.call(game.score.total_score == 800 and game.score.get_combo_value() == 0,
			"manual usability: %s preserves the actual two-entry bank with no fabricated link" % label)
	print("MANUAL_USABILITY ", JSON.stringify({"case":label,"request_tick":request,"native_contact":contact,
		"entry":entry,"actual_ms_before_contact":(contact-request)*1000.0/60.0 if request >= 0 else null,"manual_awards":manual_count,
		"score":game.score.total_score,"fixture":"Only reset at case boundary; production mapped input/native collision."}))
	game.skater.trick_performed.disconnect(on_trick)
	_release()
	return {"contact":contact,"entry":entry}


static func _linked_air_again(tree: SceneTree, game: Node, contact: int, check: Callable) -> void:
	await _prepare_jump(tree, game)
	for tick: int in contact + 8:
		if tick == 1: Input.action_press("flip")
		if tick == 3: Input.action_release("flip")
		if tick == contact - 18: Input.action_press("manual")
		await _frames(tree, 1)
		if game.skater.manual_active: ManualBalance.hold(game.skater, 0.025, 0.3)
	check.call(game.skater.manual_active and game.score.combo_trick_count == 3 and game.score.total_score == 0,
		"manual usability: a fresh 300 ms airborne request reaches a real supported three-trick manual")
	ManualBalance.correct(game.skater, 0)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_release("manual")
	check.call(game.skater.airborne and not game.skater.manual_active and game.score.total_score == 0
		and game.skater._launch_id == "ollie",
		"manual usability: fore/aft correction cannot turn the linking Ollie into an unintended launch setup")
	Input.action_press("grab")
	await _frames(tree, 3)
	Input.action_release("grab")
	for tick: int in 80:
		await _frames(tree, 1)
		if game.skater.is_on_floor() and not game.skater.airborne: break
	check.call(game.score.combo_trick_count == 5 and game.score.pending_landing and game.score.total_score == 0,
		"manual usability: actual air/manual/air/grab lands as one five-entry line")
	var earned: int = game.score.get_combo_value()
	await _frames(tree, 26)
	check.call(earned > 1500 and game.score.total_score == earned,
		"manual usability: the connected five-entry line banks its earned value exactly")
	await _frames(tree, 24)
	check.call(game.score.total_score == earned, "manual usability: subsequent ground time never banks the line twice")
	_release()


static func _restart_request(tree: SceneTree, game: Node, check: Callable) -> void:
	await _prepare_jump(tree, game)
	await _frames(tree, 17)
	Input.action_press("manual")
	await _frames(tree, 1)
	check.call(game.skater.airborne and game.skater._manual_buffer_remaining > 0.3,
		"manual usability: restart negative control first earns a fresh airborne request")
	game.restart_run()
	await _frames(tree, 48)
	check.call(not game.skater.manual_active and game.skater._manual_buffer_remaining == 0.0
		and game.score.total_score == 0 and game.score.get_combo_value() == 0,
		"manual usability: restart cancels the request and a still-held button cannot resurrect it")
	_release()


static func _meter(tree: SceneTree, check: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	viewport.size = Vector2i(1280, 800)
	tree.root.add_child(viewport)
	var hud := HUD.new()
	viewport.add_child(hud)
	var bindings := {"push":{"key":KEY_PAGEUP},"brake":{"key":KEY_PAGEDOWN}}
	check.call(Profile.apply_saved(bindings), "manual meter: remapped forward/back diagnostic controls apply")
	for size: Vector2i in [Vector2i(960,540),Vector2i(1280,800),Vector2i(1920,1080)]:
		viewport.size = size
		for ui_scale: float in [1.0,1.4]:
			var state := {"manual":true,"manual_name":"Nose Manual","balance_axis":"fore_aft",
				"balance_negative_action":"brake","balance_positive_action":"push",
				"settings":{"ui_scale":ui_scale,"bindings":bindings,"reduced_motion":true}}
			state.balance_value = -1.0
			hud.update_display(state)
			await _frames(tree, 3)
			var bottom: Vector2 = hud._balance_marker.position
			check.call(hud._balance_vertical and hud._balance_label.text.contains("BACK RISK")
				and hud._balance_label.text.contains("PageUp"), "manual meter: back endpoint asks for the remapped forward correction")
			state.balance_value = 0.0
			hud.update_display(state)
			var middle: Vector2 = hud._balance_marker.position
			state.balance_value = 1.0
			hud.update_display(state)
			await _frames(tree, 2)
			var top: Vector2 = hud._balance_marker.position
			check.call(top.y < middle.y - 40 and middle.y < bottom.y - 40 and is_equal_approx(top.x,bottom.x)
				and hud._balance_label.text.contains("FORWARD RISK") and hud._balance_label.text.contains("PageDown"),
				"manual meter: top/centre/bottom are truly vertical and forward risk prompts backward")
			var rect: Rect2 = hud._balance_panel.get_global_rect()
			check.call(Rect2(Vector2.ZERO,Vector2(size)).encloses(rect)
				and rect.encloses(hud._balance_marker.get_global_rect()),
				"manual meter: panel/marker fit %s at UI scale %.1f" % [size,ui_scale])
			var skating_corridor := Rect2(Vector2(size.x * 0.4, size.y * 0.3), Vector2(size.x * 0.2, size.y * 0.55))
			check.call(not rect.intersects(skating_corridor)
				and hud._balance_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
				and hud._balance_label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING
				and hud._balance_label.size.y >= 44,
				"manual meter: correction text stays multiline beside the skating corridor at %s / %.1f" % [size,ui_scale])
	var lateral := {"grinding":true,"balance_axis":"lateral","balance_value":-0.8,
		"balance_negative_action":"steer_left","balance_positive_action":"steer_right"}
	hud.update_display(lateral)
	var left: Vector2 = hud._balance_marker.position
	lateral.balance_value = 0.8
	hud.update_display(lateral)
	check.call(not hud._balance_vertical and hud._balance_marker.position.x > left.x + 150
		and is_equal_approx(hud._balance_marker.position.y,left.y), "manual meter: rails retain a lateral marker and correction axis")
	hud.update_display({})
	check.call(not hud._balance_panel.visible, "manual meter: ending balance clears the meter immediately")
	hud.queue_free()
	viewport.queue_free()
	await tree.process_frame
	Profile.apply_saved({})


static func _frames(tree: SceneTree, count: int) -> void:
	for tick: int in count:
		await tree.physics_frame
		await tree.process_frame
		await tree.create_timer(0.0,true).timeout


static func _release() -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)
