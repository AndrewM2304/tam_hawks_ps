extends RefCounted
## Independent production-scene input regressions for the trick-fidelity slice.
## Resets and high-drop starts are explicit fixture setup. Movement and contacts
## after setup always use the real controller and Godot physics.

const Catalog = preload("res://game/tricks/trick_catalog.gd")
const GrindLineSource = preload("res://game/tricks/grind_line.gd")

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var events: Array[String] = []
	var hold := {"points": 0, "events": 0}
	var record: Callable = func(label: String, _points: int) -> void:
		events.append(label)
	var record_hold: Callable = func(points: int) -> void:
		hold["points"] += points
		hold["events"] += 1
	game.skater.trick_performed.connect(record)
	game.skater.hold_points_awarded.connect(record_hold)
	await _approach(tree, game)
	events.clear()
	Input.action_press("flip")
	Input.action_press("grab")
	await _frames(tree, 2)
	check.call(game.skater.is_on_floor() and events.is_empty(),
		"trick fidelity: supported ground travel cannot execute aerial flips or grabs")
	_release()

	# The ordinary weighted tap pop still has a short, height-preserving arc.
	# Two complete .32s flips plus catch need an explicit higher-drop fixture;
	# no score or trick state is injected after this initial placement.
	await _high_drop(tree, game, 12.0)
	events.clear()
	Input.action_press("steer_right")
	Input.action_press("flip")
	await _frames(tree, 2)
	Input.action_release("steer_right")
	check.call(events.has(Catalog.resolve("flip", "east")["display_name"]),
		"trick fidelity: actual east plus flip input selects the directional heelflip")
	var flip_count := _family_count(events, "flip")
	for frame in 45:
		if game.skater._flip_remaining <= 0.0 and game.skater._flip_catch_remaining <= 0.0:
			break
		await _frames(tree, 1)
	check.call(_family_count(events, "flip") == flip_count,
		"trick fidelity: holding a flip beyond its animation never repeats its entry award")
	Input.action_release("flip")
	await _frames(tree, 2)
	Input.action_press("flip")
	await _frames(tree, 1)
	check.call(game.skater.airborne and _family_count(events, "flip") == flip_count + 1,
		"trick fidelity: a fresh press after board recovery accepts a second flip in the same airtime")
	await _land(tree, game, check)
	_release()
	await _frames(tree, 25)
	var expected_double := (Catalog.base_points("heelflip")+Catalog.base_points("kickflip"))*2
	check.call(game.score.total_score == expected_double and game.score.get_combo_value() == 0,
		"trick fidelity: a declared high-drop heelflip-to-kickflip sequence catches both boards and banks once")
	var banked: int = game.score.total_score
	await _frames(tree, 25)
	check.call(game.score.total_score == banked,
		"trick fidelity: further supported frames cannot bank the completed combo again")

	await _approach(tree, game)
	events.clear()
	await _launch(tree, game, check)
	Input.action_press("flip")
	await _frames(tree, 2)
	Input.action_release("flip")
	await _frames(tree, 2)
	Input.action_press("flip")
	await _frames(tree, 2)
	check.call(_family_count(events, "flip") == 1,
		"trick fidelity: fresh spam before recovery cannot overwrite the current board trick or score")
	_release()

	await _approach(tree, game)
	events.clear()
	await _launch(tree, game, check)
	Input.action_press("grab")
	Input.action_press("flip")
	await _frames(tree, 2)
	check.call(_family_count(events, "flip") == 1 and _family_count(events, "grab") == 0,
		"trick fidelity: simultaneous flip and grab orders the board trick before a queued grab")
	await _frames(tree, 34)
	check.call(_family_count(events, "grab") == 1,
		"trick fidelity: the queued grab executes once after the flip recovers")
	_release()

	await _high_drop(tree, game, 300.0)
	events.clear()
	hold["points"] = 0
	hold["events"] = 0
	Input.action_press("steer_right")
	Input.action_press("grab")
	await _frames(tree, 14)
	Input.action_release("steer_right")
	check.call(events.has(Catalog.resolve("grab", "east")["display_name"]),
		"trick fidelity: actual directional grab input selects its distinct catalog move")
	var pending_before_pause: int = game.score.get_combo_value()
	var hold_before_pause: int = hold["points"]
	game.toggle_pause()
	await _frames(tree, 20)
	check.call(game.score.get_combo_value() == pending_before_pause
		and hold["points"] == hold_before_pause,
		"trick fidelity: pausing freezes active hold extension and pending points")
	game.toggle_pause()
	await _frames(tree, 220)
	check.call(_family_count(events, "grab") == 1 and hold["points"] == 300,
		"trick fidelity: a sustained grab adds bounded hold points without repeat entries")
	Input.action_release("grab")
	await _frames(tree, 3)
	Input.action_press("grab")
	await _frames(tree, 8)
	check.call(hold["points"] <= 300,
		"trick fidelity: releasing and regrabbing cannot reset the airtime hold-point cap")
	_release()

	await _approach(tree, game)
	events.clear()
	await _launch(tree, game, check)
	var bails := {"count": 0}
	var record_bail: Callable = func() -> void: bails["count"] += 1
	game.skater.bailed.connect(record_bail)
	game.score.total_score = 500
	var late_flip_window := false
	var late_clearance := INF
	for frame in 80:
		if game.skater.airborne and game.skater.velocity.y < 0.0:
			var at: Vector3 = game.skater.global_position
			var hit := game.world.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.05,at-Vector3.UP*0.30,1))
			if not hit.is_empty() and Vector3(hit.normal).y > 0.99:
				late_clearance = at.y-Vector3(hit.position).y
				if late_clearance > 0.04 and late_clearance <= 0.24:
					late_flip_window = true
					break
		await _frames(tree, 1)
	check.call(late_flip_window,
		"trick fidelity: late flip starts while descending above native flat support before touchdown")
	Input.action_press("flip")
	await _frames(tree, 20)
	check.call(bails["count"] == 1 and game.score.get_combo_value() == 0
		and game.score.total_score == 500,
		"trick fidelity: an unfinished late board flip bails once and preserves previously banked score")
	print("FIDELITY LATE FLIP native_clearance=%.6f bails=%d total=%d pending=%d pos=%s airborne=%s" % [
		late_clearance,
		bails["count"], game.score.total_score, game.score.get_combo_value(),
		game.skater.global_position, game.skater.airborne])
	game.skater.bailed.disconnect(record_bail)
	_release()

	await _approach(tree, game)
	events.clear()
	Input.action_press("push")
	Input.action_press("manual")
	await _frames(tree, 1)
	check.call(game.skater.manual_active
		and events.has(Catalog.resolve("manual", "north")["display_name"]),
		"trick fidelity: forward plus manual input enters the supported nose manual")
	await _frames(tree, 8)
	check.call(game.skater.get_node("SkaterVisual/Board").rotation.x < -0.10,
		"trick fidelity: an actual nose manual pitches the opposite end of the board")
	_release()

	await _approach(tree, game)
	events.clear()
	await _launch(tree, game, check)
	Input.action_press("manual")
	await _land(tree, game, check)
	check.call(not game.skater.manual_active and _family_count(events, "manual") == 0,
		"trick fidelity: an early held airborne manual expires instead of auto-entering on touchdown")
	_release()

	await _approach(tree, game)
	events.clear()
	await _launch(tree, game, check)
	var pressed := false
	for frame in 100:
		if game.skater.airborne and game.skater.velocity.y < -5.5 and not pressed:
			Input.action_press("manual")
			pressed = true
		await _frames(tree, 1)
		if not game.skater.airborne:
			break
	check.call(pressed and game.skater.manual_active and _family_count(events, "manual") == 1,
		"trick fidelity: a fresh late airborne manual is buffered into actual supported landing")
	check.call(game.score.total_score == 0 and not game.score.pending_landing,
		"trick fidelity: the buffered landing manual continues the unbanked aerial combo")
	Input.action_release("manual")
	await _frames(tree, 25)
	check.call(game.score.total_score > 0 and game.score.get_combo_value() == 0,
		"trick fidelity: releasing the buffered manual starts one bank deadline")
	_release()

	await _approach(tree, game)
	events.clear()
	await _launch(tree, game, check)
	for frame in 100:
		if game.skater.velocity.y < -5.5:
			break
		await _frames(tree, 1)
	Input.action_press("manual")
	await _frames(tree, 1)
	Input.action_release("manual")
	await _land(tree, game, check)
	check.call(not game.skater.manual_active and _family_count(events, "manual") == 0,
		"trick fidelity: releasing a buffered manual before touchdown cancels the landing link")
	_release()

	await _approach(tree, game)
	events.clear()
	await _launch(tree, game, check)
	var heading: float = game.skater.rotation.y
	Input.action_press("spin_left")
	await _frames(tree, 25)
	Input.action_release("spin_left")
	await _land(tree, game, check)
	check.call(events.count("Frontside 180") == 1 and game.skater.stance == "SWITCH"
		and absf(absf(angle_difference(heading, game.skater.rotation.y)) - PI) < deg_to_rad(8.0),
		"trick fidelity: a real half-turn changes functional stance and physical board heading")
	_release()

	await _rail_start(tree, game)
	events.clear()
	Input.action_press("flip")
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(not game.skater.grinding and _family_count(events, "grind") == 0,
		"trick fidelity: rail capture cannot cancel an unfinished board rotation into a grind")
	_release()

	await _rail_start(tree, game)
	events.clear()
	Input.action_press("steer_right")
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(game.skater.grinding and events.has(Catalog.resolve("grind", "east")["display_name"]),
		"trick fidelity: eligible real rail capture selects the directional slide")
	var rail_count := _family_count(events, "grind")
	Input.action_release("steer_right")
	Input.action_press("steer_left")
	await _frames(tree, 3)
	check.call(_family_count(events, "grind") == rail_count,
		"trick fidelity: balance correction while riding cannot generate a new grind entry")
	_release()

	# A declared long, elevated track isolates duration from short authored rail
	# endpoints. After capture, only real balance actions control its four seconds.
	await _long_rail_start(tree, game)
	events.clear()
	hold["points"] = 0
	Input.action_press("grind")
	await _frames(tree, 3)
	var rail_start: Vector3 = game.skater.global_position
	for frame in 240:
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if game.skater.grind_balance > 0.08:
			Input.action_press("steer_left")
		elif game.skater.grind_balance < -0.08:
			Input.action_press("steer_right")
		await _frames(tree, 1)
	check.call(game.skater.grinding and game.skater.global_position.distance_to(rail_start) > 10.0,
		"trick fidelity: real balance correction sustains physical rail travel for four seconds")
	check.call(hold["points"] == 300 and _family_count(events, "grind") == 1
		and game.score.combo_multiplier == 1 and game.score.trick_history.size() == 1,
		"trick fidelity: sustained grind reaches its 300-point cap without extra entry, history or multiplier")
	_release()
	game.skater.set_grind_lines(game.world.get_grind_lines())

	await _high_drop(tree, game, 8.0)
	events.clear()
	# Main owns this gate every physics tick: expire an actual career run while
	# supported airtime is resolving rather than overriding its child directly.
	game.free_skate_mode = false
	game.time_remaining = 0.0
	await _frames(tree, 1)
	Input.action_press("flip")
	Input.action_press("grab")
	Input.action_press("manual")
	await _frames(tree, 2)
	check.call(events.is_empty(),
		"trick fidelity: overtime rejects fresh directional flips, grabs and buffered links")
	_release()
	events.clear()
	game.time_remaining = 120.0
	await _frames(tree, 1)
	game.skater.set_controls_enabled(false)
	await _frames(tree, 1)
	Input.action_press("flip")
	Input.action_press("grab")
	await _frames(tree, 2)
	check.call(events.is_empty(),
		"trick fidelity: disabled controls reject fresh aerial trick entries")
	_release()
	game.skater.set_controls_enabled(true)
	game.start_mode(true)
	await _frames(tree, 35)
	check.call(not game.skater.manual_active and not game.skater.grinding
		and game.score.get_combo_value() == 0,
		"trick fidelity: restart clears active tricks, buffered links and pending score")
	game.skater.trick_performed.disconnect(record)
	game.skater.hold_points_awarded.disconnect(record_hold)

static func _family_count(events: Array[String], family: String) -> int:
	var names: Dictionary = {}
	for id: String in Catalog.ids()+Catalog.compatibility_ids():
		var entry: Dictionary = Catalog.definition(id)
		if entry.get("family", "") == family:
			names[entry["display_name"]] = true
	var count := 0
	for label: String in events:
		if names.has(label):
			count += 1
	return count

static func _approach(tree: SceneTree, game: Node) -> void:
	_release()
	game.restart_run()
	await _frames(tree, 40)
	Input.action_press("push")
	await _frames(tree, 38)
	Input.action_release("push")
	await _frames(tree, 14) # Expire recent direction for truly neutral actions.

static func _launch(tree: SceneTree, game: Node, check: Callable) -> void:
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(game.skater.airborne, "trick fidelity: fixture launches through actual ollie input")

static func _high_drop(tree: SceneTree, game: Node, height: float) -> void:
	_release()
	game.restart_run()
	await _frames(tree, 2)
	game.skater.spawn_position = Vector3(-22, height, 28)
	game.skater.reset_skater()
	await _frames(tree, 2)
	game.skater.spawn_position = game.world.get_spawn_position()

static func _rail_start(tree: SceneTree, game: Node) -> void:
	_release()
	game.restart_run()
	await _frames(tree, 2)
	game.skater.set_physics_process(false)
	game.skater.global_position = Vector3(12.15, 1.10, 11.5)
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = Vector3(0, -1, -6)
	game.skater.speed = 6.0
	game.skater.airborne = true
	game.skater.set_physics_process(true)

static func _long_rail_start(tree: SceneTree, game: Node) -> void:
	_release()
	game.restart_run()
	await _frames(tree, 2)
	var line = GrindLineSource.new("Grind_QE_Duration", PackedVector3Array([
		Vector3(-22, 30, 30), Vector3(-22, 30, -40)]))
	game.skater.set_grind_lines([line])
	game.skater.set_physics_process(false)
	game.skater.global_position = Vector3(-22, 30.10, 28)
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = Vector3(0, -1, -6)
	game.skater.speed = 6.0
	game.skater.airborne = true
	game.skater.set_physics_process(true)

static func _land(tree: SceneTree, game: Node, check: Callable) -> void:
	for frame in 120:
		await _frames(tree, 1)
		if not game.skater.airborne:
			check.call(game.skater.is_on_floor(), "trick fidelity: airtime resolves on actual support")
			return
	check.call(false, "trick fidelity: landing occurs within its bounded fixture timeout")

static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame

static func _release() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
