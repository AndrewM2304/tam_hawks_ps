extends RefCounted
## Actual input/physics/scoring integration on the production scene.
const Catalog = preload("res://game/tricks/trick_catalog.gd")

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var captures: Array[String] = []
	var capture_spy: Callable = func(rail_id: String): captures.append(rail_id)
	game.skater.grind_captured.connect(capture_spy)
	var lines: Array = game.world.get_grind_lines()
	check.call(lines.size() >= 6 and lines[0].is_valid and lines[1].is_valid,
		"world retains original rail tracks and adds valid district rails")
	await _start(tree, game, Vector3(12.15, 1.10, 11.5), Vector3(0, -1, -6))
	game.score.add_trick("Kickflip", 300)
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(game.skater.grinding and not game.skater.airborne,
		"descending aligned skater catches the real east rail while grind is held")
	check.call(game.score.trick_history.has("50-50") and game.score.total_score == 0,
		"rail catch adds one trick and preserves the unbanked aerial combo")
	var value: int = game.score.get_combo_value()
	var z: float = game.skater.global_position.z
	await _frames(tree, 12)
	check.call(game.skater.grinding and game.skater.global_position.z < z - 0.5,
		"held grind advances along the visible rail")
	check.call(game.score.get_combo_value() == value,
		"holding a rail does not award entry points every physics tick")
	check.call(captures == ["Grind_Rail_Exchange"],
		"a real capture emits its authored ID once, without per-tick repeats")
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
	await _frames(tree, 1)
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
	await _frames(tree, 1)
	var release_from: Vector3=game.skater.global_position
	Input.action_press("grind")
	await _frames(tree, 2)
	Input.action_release("grind")
	check.call(not game.skater.grinding and game.skater._grind_cooldown>=.30
		and game.skater.global_position.is_finite() and game.skater.global_position.distance_to(release_from)<.40
		and (game.skater.airborne or _solid_rail_support(game,"Grind_Rail_Exchange")),
		"a second fresh grind tap releases near the same solid rail without teleporting to spawn")

	await _start(tree, game, Vector3(12, 1.08, 5.75), Vector3(0, -1, -6))
	Input.action_press("grind")
	await _frames(tree, 12)
	check.call(not game.skater.grinding and game.skater.global_position.z < 5.25,
		"open rail endpoint releases into forward airborne travel without wrapping")
	Input.action_release("grind")

	var captures_before := captures.size()
	await _start(tree, game, Vector3(12.50, 1.1, 10), Vector3(6, -1, 0))
	Input.action_press("grind")
	await _frames(tree, 2)
	check.call(not game.skater.grinding and _grind_award_count(game.score.trick_history) == 0 and captures.size() == captures_before,
		"perpendicular travel away from the rail outside the close-contact band cannot snap, score or emit a capture")
	Input.action_release("grind")

	captures_before = captures.size()
	await _start(tree, game, Vector3(-6, 1.1, 24), Vector3(0, -1, -6))
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(not game.skater.grinding and game.score.get_combo_value() == 0 and captures.size() == captures_before,
		"grind input away from authored rails cannot generate points or capture events")
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
	captures_before = captures.size()
	await _start(tree, game, Vector3(12.6, 1.1, 10), Vector3(0, -1, -6))
	Input.action_press("grind")
	await _frames(tree, 2)
	check.call(not game.skater.grinding and not game.score.trick_history.has("Rail Grind")
		and captures.size() == captures_before,
		"solid scenery prevents through-wall rail capture and emits no rail-ID event")
	check.call(game.score.get_combo_value() == (300 if game.skater.wallriding else 0),
		"solid scenery permits only an actual wallride award while blocking the rail behind it")
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
	game.skater.grind_captured.disconnect(capture_spy)
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


static func _grind_award_count(names: Array) -> int:
	var count := 0
	for name: String in names:
		if Catalog.is_grind_name(name): count += 1
	return count


static func _solid_rail_support(game: Node, id: String) -> bool:
	# A fresh release may already have landed on the actual solid bar by the
	# second observation. Require native support from that exact authored rail.
	if not game.skater.is_on_floor() or game.skater.airborne:return false
	var at: Vector3=game.skater.global_position
	var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.04,at-Vector3.UP*.12,1|2)
	ray.exclude=[game.skater.get_rid()]
	var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or not hit.collider is StaticBody3D:return false
	var body: StaticBody3D=hit.collider
	var ids: Variant=body.get_meta("authored_grind_ids",[])
	return (body.collision_layer&(1|2))==(1|2) and (ids is Array or ids is PackedStringArray) \
		and ids.has(id) and Vector3(hit.normal).y>.99 and at.y-Vector3(hit.position).y>=-.001 \
		and at.y-Vector3(hit.position).y<=.03
