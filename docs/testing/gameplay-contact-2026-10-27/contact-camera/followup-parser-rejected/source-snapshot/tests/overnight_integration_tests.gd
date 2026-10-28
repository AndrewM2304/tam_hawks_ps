extends RefCounted
const BoardGeometry = preload("res://tests/board_geometry_tests_support.gd")
## Production input/physics regressions for the complete skate process.
## Restarts set each initial fixture; every launch, turn and landing is simulated.

const SAFE_SPAWN := Vector3(-22.0, 0.8, 28.0)

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	game.skater.spawn_position = SAFE_SPAWN
	await _charged_launch(tree, game, check)
	await _rotation_landings(tree, game, check)
	await _live_meter(tree, game, check)
	await _special_timing(tree, game, check)
	await _buffered_special(tree, game, check)
	await _manual_process(tree, game, check)
	await _rail_process(tree, game, check)
	await _launch_setups(tree, game, check)
	await _powerslide(tree, game, check)
	await _world_wall_and_transition(tree, game, check)
	_release()
	game.skater.spawn_position = original_spawn
	game.restart_run()

static func _charged_launch(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	Input.action_press("ollie")
	await _frames(tree, 1)
	check.call(game.skater.is_on_floor() and not game.skater.airborne
		and game.score.get_combo_value() == 0,
		"overnight process: initial ollie press crouches without launching or scoring")
	Input.action_release("ollie")
	await _frames(tree, 1)
	var tap_velocity: float = game.skater.velocity.y
	check.call(game.skater.airborne and absf(tap_velocity - game.skater.OLLIE_SPEED * game.skater.WEIGHTED_OLLIE_IMPULSE_SCALE) < 0.01,
		"overnight process: releasing a tap uses the height-preserving weighted flat-ground impulse")
	var tap_peak: float = game.skater.global_position.y
	for frame in 90:
		await _frames(tree, 1)
		tap_peak = maxf(tap_peak, game.skater.global_position.y)
		if not game.skater.airborne: break
	check.call(game.skater.is_on_floor(), "overnight process: a tap returns to real supporting collision")

	await _reset(tree, game)
	var start: Vector3 = game.skater.global_position
	Input.action_press("ollie")
	await _frames(tree, 36)
	check.call(game.skater.is_on_floor() and not game.skater.airborne
		and game.score.get_combo_value() == 0,
		"overnight process: full charge stays grounded and cannot farm launch entries")
	check.call(game.skater.speed > 2.0 and game.skater.global_position.distance_to(start) > 0.4,
		"overnight process: held crouch builds useful approach speed through actual movement")
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(game.skater.airborne and game.skater.velocity.y > tap_velocity + 1.5
		and game.skater.velocity.y <= game.skater.CHARGED_OLLIE_SPEED + 0.01,
		"overnight process: a complete charge increases the bounded release impulse")
	var charged_peak: float = game.skater.global_position.y
	for frame in 100:
		await _frames(tree, 1)
		charged_peak = maxf(charged_peak, game.skater.global_position.y)
		if not game.skater.airborne: break
	check.call(charged_peak > tap_peak + 0.4 and game.skater.is_on_floor(),
		"overnight process: charge produces visibly higher physical airtime and a clean landing")

	await _reset(tree, game)
	Input.action_press("ollie")
	await _frames(tree, 6)
	game.toggle_pause()
	var paused_position: Vector3 = game.skater.global_position
	var paused_velocity: Vector3 = game.skater.velocity
	await _frames(tree, 18)
	check.call(game.skater.global_position.is_equal_approx(paused_position)
		and game.skater.velocity.is_equal_approx(paused_velocity),
		"overnight process: pausing during charge freezes its physical approach")
	game.toggle_pause()
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(game.skater.airborne,
		"overnight process: an intentional release after resume still launches once")

static func _rotation_landings(tree: SceneTree, game: Node, check: Callable) -> void:
	for turn: Dictionary in [
		{"frames": 13, "clean": false, "stance": "REGULAR"},
		{"frames": 26, "clean": true, "stance": "SWITCH"},
		{"frames": 52, "clean": true, "stance": "REGULAR"},
	]:
		await _reset(tree, game)
		var evidence := {"bails": 0, "landings": [], "entries": []}
		var on_bail := func(): evidence.bails += 1
		var on_land := func(clean: bool): evidence.landings.append(clean)
		var on_entry := func(label: String, _points: int): evidence.entries.append(label)
		game.skater.bailed.connect(on_bail)
		game.skater.landed.connect(on_land)
		game.skater.trick_performed.connect(on_entry)
		if turn.frames == 52:
			# Declared high-drop fixture provides enough native airtime for360
			# under retained default flat gravity; the entry is a real flip.
			game.skater.spawn_position = SAFE_SPAWN + Vector3.UP * 28.0
			game.restart_run()
			await _frames(tree, 1)
			Input.action_press("flip")
			await _frames(tree, 1)
			Input.action_release("flip")
		else:
			Input.action_press("ollie")
			await _frames(tree, 28)
			Input.action_release("ollie")
			await _frames(tree, 1)
		var travel: Vector3 = Vector3(game.skater.velocity.x, 0, game.skater.velocity.z).normalized()
		var heading: float = game.skater.rotation.y
		Input.action_press("spin_right")
		await _frames(tree, int(turn.frames))
		Input.action_release("spin_right")
		for frame in 120:
			await _frames(tree, 1)
			if evidence.bails > 0 or not game.skater.airborne: break
		await _frames(tree, 25)
		if not turn.clean:
			check.call(evidence.bails == 1 and game.score.total_score == 0
				and game.score.get_combo_value() == 0,
				"overnight process: a sideways quarter-turn bails once and loses the unlanded combo")
		else:
			var expected_angle: float = PI if turn.stance == "SWITCH" else 0.0
			var angle: float = absf(angle_difference(heading, game.skater.rotation.y))
			var after: Vector3 = Vector3(game.skater.velocity.x, 0, game.skater.velocity.z).normalized()
			check.call(evidence.bails == 0 and evidence.landings == [true]
				and game.skater.stance == turn.stance and absf(angle - expected_angle) < deg_to_rad(12),
				"overnight process: a completed %s turn lands with aligned physical heading and functional stance" % ("half" if turn.stance == "SWITCH" else "full"))
			check.call((after.dot(travel) > 0.98 if travel.length_squared()>0.5 else after.length_squared()<0.01) and game.score.total_score == (300 if turn.stance == "SWITCH" else 700),
				"overnight process: landed rotation preserves travel and adds base spin points without an entry multiplier")
		game.skater.bailed.disconnect(on_bail)
		game.skater.landed.disconnect(on_land)
		game.skater.trick_performed.disconnect(on_entry)
		_release()
		game.skater.spawn_position = SAFE_SPAWN

static func _live_meter(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("flip")
	await _frames(tree, 2)
	Input.action_release("flip")
	check.call(game.skater.airborne and game.score.total_score == 0
		and game.special_meter.value >= 39.0 and game.special_meter.value <= 41.0,
		"overnight process: real ollie and flip charge special before their combo is banked")
	for frame in 100:
		await _frames(tree, 1)
		if not game.skater.airborne: break
	var before_bank: float = game.special_meter.value
	await _frames(tree, 25)
	check.call(game.score.total_score == 800
		and absf(game.special_meter.value - before_bank) < 0.1,
		"overnight process: banking pays the combo exactly once without charging special twice")
	game.special_meter.earn_trick(500)
	game.special_meter.earn_trick(500)
	check.call(game.special_meter.ready(), "overnight process: live earned charge activates special mode")
	var before_pause: float = game.special_meter.value
	game.toggle_pause()
	await _frames(tree, 24)
	check.call(game.special_meter.value == before_pause,
		"overnight process: pausing freezes active special duration")
	game.toggle_pause()
	game.skater.bailed.emit()
	check.call(game.special_meter.value == 0.0 and not game.special_meter.ready(),
		"overnight process: production bail wiring clears active special mode")

static func _special_timing(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	var original_completed: Array = game.career.completed_ids.duplicate()
	if not game.career.completed_ids.has("first_shift"):
		game.career.completed_ids.append("first_shift")
	_release()
	# Explicit high-drop fixture provides enough real airtime for two completed
	# animations; gravity and collision after restart remain production physics.
	game.skater.spawn_position = Vector3(-22, 28, 28)
	game.restart_run()
	await _frames(tree, 2)
	game.special_meter.earn_trick(500)
	game.special_meter.earn_trick(500)
	_key(KEY_U)
	await _frames(tree, 2)
	check.call(game.skater.airborne and game.skater.special_name == "Clyde Carousel"
		and game.score.combo_trick_count == 1,
		"overnight process: a genuine high drop admits an unlocked special through mapped input")
	_key(KEY_U)
	await _frames(tree, 2)
	check.call(game.score.combo_trick_count == 1,
		"overnight process: fresh special spam cannot interrupt or duplicate the current animation")
	await _frames(tree, 38)
	_key(KEY_U)
	await _frames(tree, 2)
	check.call(game.skater.airborne and game.skater.special_name == "Clyde Carousel"
		and game.score.combo_trick_count == 2 and game.score.last_repeat,
		"overnight process: completing an animation permits another special in the same real airtime with stale base points")
	for frame in 180:
		await _frames(tree, 1)
		if not game.skater.airborne: break
	await _frames(tree, 25)
	check.call(game.score.total_score == 3000 and game.score.get_combo_value() == 0,
		"overnight process: two physically completed specials land and bank their exact two-entry value")

	game.skater.spawn_position = original_spawn
	await _reset(tree, game)
	game.special_meter.earn_trick(500)
	game.special_meter.earn_trick(500)
	var evidence := {"bails": 0}
	var on_bail := func(): evidence.bails += 1
	game.skater.bailed.connect(on_bail)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	var late_support_gap := INF
	for frame in 80:
		var ray := PhysicsRayQueryParameters3D.create(game.skater.global_position + Vector3.UP * .05,
			game.skater.global_position + Vector3.DOWN, 1)
		ray.exclude = [game.skater.get_rid()]
		var support := game.world.get_world_3d().direct_space_state.intersect_ray(ray)
		if game.skater.airborne and game.skater.velocity.y < 0.0 and not support.is_empty():
			late_support_gap = game.skater.global_position.y - Vector3(support.position).y
			if late_support_gap > .20 and late_support_gap < .32: break
		await _frames(tree, 1)
	_key(KEY_U)
	await _frames(tree, 2)
	check.call(game.skater.special_name == "Clyde Carousel",
		"overnight process: a late special still requires its full physical animation")
	await _frames(tree, 40)
	check.call(evidence.bails == 1 and game.score.total_score == 0
		and game.score.get_combo_value() == 0 and game.special_meter.value == 0.0,
		"overnight process: landing an unfinished special bails once and drops score and live charge")
	game.skater.bailed.disconnect(on_bail)
	game.career.completed_ids.assign(original_completed)

static func _manual_process(tree: SceneTree, game: Node, check: Callable) -> void:
	await _moving(tree, game)
	Input.action_press("push")
	await _frames(tree, 2)
	Input.action_release("push")
	await _frames(tree, 1)
	Input.action_press("brake")
	await _frames(tree, 2)
	Input.action_release("brake")
	await _frames(tree, 1)
	check.call(game.skater.manual_active and game.skater.manual_trick_id == "manual"
		and not Input.is_action_pressed("manual") and game.score.combo_trick_count == 1,
		"overnight process: deliberate up-down movement gesture enters a latched manual without the shortcut")
	await _neutral_direction(tree)
	Input.action_press("flip")
	await _frames(tree, 1)
	Input.action_release("flip")
	check.call(game.skater.manual_active and game.skater.manual_trick_id == "one_foot_manual"
		and game.score.combo_trick_count == 2,
		"overnight process: fresh flip extends a real manual to a one-foot manual")
	await _balance(tree, game, 23)
	await _neutral_direction(tree)
	Input.action_press("grab")
	await _frames(tree, 1)
	Input.action_release("grab")
	check.call(game.skater.manual_active and game.skater.manual_trick_id == "spacewalk"
		and game.score.combo_trick_count == 3,
		"overnight process: recovered fresh grab changes the supported manual into a spacewalk")
	await _balance(tree, game, 23)
	await _neutral_direction(tree)
	var heading: float = game.skater.rotation.y
	var motion: Vector3 = game.skater.velocity
	Input.action_press("revert")
	await _frames(tree, 1)
	check.call(game.skater.manual_active and game.skater.manual_trick_id == "manual_pivot"
		and game.score.combo_trick_count == 4 and game.skater.speed < -2.0
		and absf(absf(angle_difference(heading, game.skater.rotation.y)) - PI) < 0.01
		and game.skater.velocity.normalized().dot(motion.normalized()) > 0.98,
		"overnight process: manual pivot physically turns the board into switch while preserving its travel and live combo")
	await _frames(tree, 4)
	check.call(game.skater.manual_active and game.score.combo_trick_count == 4
		and game.score.total_score == 0,
		"overnight process: held style inputs cannot duplicate entries or prematurely bank a manual")
	_release()
	Input.action_press("manual")
	await _frames(tree, 1)
	Input.action_release("manual")
	await _frames(tree, 25)
	check.call(not game.skater.manual_active and game.score.total_score == 3400,
		"overnight process: fresh shortcut exits a latched manual and banks its exact four-entry extension line")

static func _buffered_special(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game)
	var completed: Array = game.career.completed_ids.duplicate()
	if not game.career.completed_ids.has("first_shift"):
		game.career.completed_ids.append("first_shift")
	game.special_meter.earn_trick(500)
	game.special_meter.earn_trick(500)
	Input.action_press("ollie")
	Input.action_press("steer_left")
	await _frames(tree, 2)
	Input.action_release("steer_left")
	await _frames(tree, 1)
	Input.action_press("steer_right")
	await _frames(tree, 2)
	Input.action_press("flip")
	await _frames(tree, 1)
	check.call(game.skater.is_on_floor() and game.skater.special_name.is_empty()
		and game.score.get_combo_value() == 0,
		"overnight process: preparing a directional special during crouch cannot score before takeoff")
	Input.action_release("steer_right")
	Input.action_release("ollie")
	await _frames(tree, 2)
	check.call(game.skater.airborne and game.skater.special_name == "Clyde Carousel"
		and game.score.combo_trick_count == 2 and not game.score.trick_history.has("Kickflip"),
		"overnight process: a buffered left-right-flip sequence executes once on actual release-pop airtime")
	await _frames(tree, 16)
	check.call(game.score.combo_trick_count == 2 and game.skater.special_name == "Clyde Carousel",
		"overnight process: holding the buffered special button cannot duplicate its accepted animation")
	_release()
	game.career.completed_ids.assign(completed)

static func _rail_process(tree: SceneTree, game: Node, check: Callable) -> void:
	_release()
	game.restart_run()
	await _frames(tree, 2)
	# Explicit descending rail fixture; attachment and all following movement
	# use the actual Main controller and level geometry.
	game.skater.set_physics_process(false)
	game.skater.global_position = Vector3(-63.85, 3.10, 1.5)
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = Vector3(0, -1, -6)
	game.skater.speed = 6.0
	game.skater.airborne = true
	game.skater.set_physics_process(true)
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(game.skater.grinding and game.skater.grind_trick_id == "grind_50_50"
		and game.score.combo_trick_count == 1,
		"overnight process: actual descending contact captures one authored rail entry")
	Input.action_press("steer_right")
	Input.action_press("flip")
	await _frames(tree, 2)
	Input.action_release("steer_right")
	for transfer_tick in 48:
		if game.skater.grind_trick_id == "boardslide" or not game.skater.grinding: break
		await _frames(tree, 1)
	check.call(game.skater.grinding and game.skater.grind_trick_id == "boardslide"
		and game.score.combo_trick_count == 2,
		"overnight process: fresh directional flip changes a live rail ride into boardslide")
	await _frames(tree, 24)
	check.call(game.skater.grinding and game.score.combo_trick_count == 2,
		"overnight process: holding a rail style beyond its cooldown cannot score it repeatedly")
	Input.action_release("flip")
	Input.action_press("steer_left")
	Input.action_press("grab")
	await _frames(tree, 2)
	Input.action_release("steer_left")
	Input.action_release("grab")
	for transfer_tick in 48:
		if game.skater.grind_trick_id == "lipslide" or not game.skater.grinding: break
		await _frames(tree, 1)
	check.call(game.skater.grinding and game.skater.grind_trick_id == "lipslide"
		and game.score.combo_trick_count == 3 and game.score.total_score == 0,
		"overnight process: fresh opposite-direction grab selects lipslide without breaking the rail combo")
	Input.action_press("steer_right")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(game.skater.airborne and not game.skater.grinding
		and game.skater.velocity.x > 3.5 and absf(game.skater.velocity.y-game.skater.OLLIE_SPEED)<0.01
		and game.score.combo_trick_count == 4 and game.score.total_score == 0,
		"overnight process: releasing a directional rail ollie adds real lateral momentum and keeps the line live")

static func _launch_setups(tree: SceneTree, game: Node, check: Callable) -> void:
	for setup: Dictionary in [{"direction": "push", "id": "nollie", "points": 150},
		{"direction": "brake", "id": "boneless", "points": 250}]:
		await _reset(tree, game)
		Input.action_press(str(setup.direction))
		Input.action_press("ollie")
		await _frames(tree, 2)
		Input.action_release("ollie")
		await _frames(tree, 1)
		Input.action_release(str(setup.direction))
		for frame in 20:
			if not game.skater.setup_active: break
			await _frames(tree, 1)
		check.call(game.skater.airborne and game.skater.last_trick_id == setup.id
			and game.score.combo_base == setup.points,
			"overnight process: deliberate %s setup selects its actual launch and independent base award" % setup.id)
		if setup.id == "nollie":
			await _frames(tree, 2)
			Input.action_press("flip")
			await _frames(tree, 2)
			Input.action_release("flip")
			check.call(game.skater.takeoff_mode == "Nollie"
				and game.skater.last_trick_id == "kickflip"
				and game.score.trick_history.has("Nollie Kickflip"),
				"overnight process: launch stance prefixes the air trick while retaining its stable repetition identity")

static func _powerslide(tree: SceneTree, game: Node, check: Callable) -> void:
	await _moving(tree, game)
	Input.action_press("brake")
	await _frames(tree, 12)
	var braking_speed: float = absf(game.skater.speed)
	await _moving(tree, game)
	var heading: float = game.skater.rotation.y
	Input.action_press("brake")
	Input.action_press("steer_right")
	await _frames(tree, 12)
	check.call(game.skater.powersliding and game.skater.is_on_floor()
		and absf(angle_difference(heading, game.skater.rotation.y)) > 0.4
		and absf(game.skater.speed) > braking_speed + 1.5 and game.score.get_combo_value() == 0,
		"overnight process: brake-steer powerslide turns sharply with retained speed and earns no invented trick points")

static func _world_wall_and_transition(tree: SceneTree, game: Node, check: Callable) -> void:
	# PT24-20 replaces the old recording walls with a low loading edge. Mirror
	# that fixture onto the solid PT24-24 print-yard wall: the same 0.55m face
	# gap and 0.8m initial height above its supported floor, with no speed seed.
	game.skater.spawn_position = Vector3(61, 2.8, 142.07)
	await _reset(tree, game)
	game.skater.rotation.y = -PI / 2.0
	Input.action_press("push")
	await _frames(tree, 30)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("grind")
	await _frames(tree, 4)
	check.call(game.skater.wallriding and game.skater._wall.wall_id.ends_with("SouthPocketRearBoundary")
		and game.score.trick_history.count("Wallride") == 1,
		"overnight process: actual backed print-yard wall contact enters the Main wallride state and scores once")
	var head_clear := false
	var wheel_contact := false
	if game.skater.wallriding:
		var outward: Vector3 = game.skater._wall.normal
		var probe: Vector3 = game.skater.global_position + Vector3.UP * 1.4
		var query := PhysicsRayQueryParameters3D.create(probe + outward * 2.0, probe - outward * 2.0, 1)
		query.exclude = [game.skater.get_rid()]
		var face: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(query)
		var head: Node3D = game.skater.get_node("SkaterVisual/Rider/TorsoRig/Head")
		head_clear = not face.is_empty() and (head.global_position - Vector3(face.position)).dot(face.normal) > 0.15
		var nearest_wheel := INF
		var wheel_count := 0
		if not face.is_empty():
			for wheel: Dictionary in game.skater._visual_rig.board_contact_geometry().wheels:
				wheel_count += 1
				for vertex: Vector3 in wheel.points:
					nearest_wheel = minf(nearest_wheel,
						(game.skater._board_visual.to_global(vertex) - Vector3(face.position)).dot(face.normal))
		wheel_contact = wheel_count == 4 and nearest_wheel >= -0.01 and nearest_wheel <= 0.06
		print("OVERNIGHT WALL head_clear=%s wheels=%d nearest_wheel=%.5f" % [head_clear, wheel_count, nearest_wheel])
	check.call(head_clear,
		"overnight process: the actual wallride keeps the visible head fully outside the contacted solid wall")
	check.call(wheel_contact,
		"overnight process: banked wheel mesh reaches actual wall contact without floating or penetrating it")
	var wall_position: Vector3 = game.skater.global_position
	await _frames(tree, 5)
	check.call(game.skater.wallriding and game.skater.global_position.x > wall_position.x + 0.3,
		"overnight process: a real architectural wall supports continuing tangent motion")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(not game.skater.wallriding and game.skater.airborne
		and game.skater.velocity.y > 7.0 and game.skater.velocity.z < -3.0
		and game.score.trick_history.count("Wallie") == 1,
		"overnight process: release-pop wallie leaves real architecture with upward and outward momentum")

	game.skater.spawn_position = Vector3(-85, 6.8, -130)
	await _reset(tree, game)
	game.skater.rotation.y = PI / 2.0
	Input.action_press("push")
	var entered := false
	var max_height: float = game.skater.global_position.y
	for frame in 200:
		await _frames(tree, 1)
		max_height = maxf(max_height, game.skater.global_position.y)
		if game.skater.transition_active:
			entered = true
			break
	check.call(entered and game.skater.global_position.x < -95.5,
		"overnight process: actual promenade approach captures the authored quarterpipe through Main")
	for frame in 100:
		await _frames(tree, 1)
		max_height = maxf(max_height, game.skater.global_position.y)
		if game.skater.airborne: break
	# The launch event occurs exactly at the four-metre lip. Sample the next
	# native motion step to verify that the reported airtime actually rises.
	await _frames(tree, 1)
	max_height = maxf(max_height, game.skater.global_position.y)
	check.call(entered and game.skater.airborne and max_height > 8.4
		and game.skater.velocity.y > 1.0,
		"overnight process: curved contact carries a real approach into upward vert airtime")
	await tree.create_timer(0.0).timeout
	var displayed_kmh: int = int(game.hud._state.speed * 3.6)
	check.call(absf(game.skater.speed) < 0.1 and displayed_kmh > 30
		and absf(float(displayed_kmh) - game.skater.velocity.length() * 3.6) < 3.0,
		"overnight process: vert HUD snapshot receives real airborne movement while signed planar physics speed remains unchanged")
	print("OVERNIGHT QUARTER entered=%s peak=%.3f pos=%s velocity=%s active=%s state=%s airborne=%s" % [
		entered, max_height, game.skater.global_position, game.skater.velocity,
		game.skater.transition_active, game.skater._feature_transition.state, game.skater.airborne])
	game.skater.spawn_position = SAFE_SPAWN

static func _moving(tree: SceneTree, game: Node) -> void:
	game.skater.spawn_position = SAFE_SPAWN
	await _reset(tree, game)
	Input.action_press("push")
	await _frames(tree, 45)
	Input.action_release("push")
	await _frames(tree, 1)

static func _neutral_direction(tree: SceneTree) -> void:
	# Expanded manual selectors remember a recent balance cue. Let its .18s
	# window expire while actual opposed inputs make
	# the intended neutral extension explicit without changing recognizer state.
	Input.action_press("push")
	Input.action_press("brake")
	await _frames(tree, 12)
	Input.action_release("push")
	Input.action_release("brake")

static func _balance(tree: SceneTree, game: Node, frames: int) -> void:
	for frame in frames:
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if game.skater.manual_balance > 0.08: Input.action_press("steer_left")
		elif game.skater.manual_balance < -0.08: Input.action_press("steer_right")
		await _frames(tree, 1)
	Input.action_release("steer_left")
	Input.action_release("steer_right")

static func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)

static func _reset(tree: SceneTree, game: Node) -> void:
	_release()
	game.restart_run()
	await _frames(tree, 40)

static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)

static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
