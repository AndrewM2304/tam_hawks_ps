extends SceneTree
## Dependency-free unit and physics integration checks. Run with tools/check.sh.

const SCORE_SCRIPT = preload("res://game/scoring/score_session.gd")
const MAIN_SCRIPT = preload("res://game/main.gd")
const RAIL_GEOMETRY_TESTS = preload("res://tests/rail_geometry_tests.gd")
const ACTIONS = [
	"push", "brake", "steer_left", "steer_right", "ollie", "flip", "grab",
	"spin_left", "spin_right", "restart", "pause", "free_skate",
]

var passed: int = 0
var failed: int = 0
var game: Node
var observed_tricks: Array[String] = []
var observed_landings: Array[bool] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Tam Hawks Pro Skater — independent QE checks")
	_test_score_session()
	RAIL_GEOMETRY_TESTS.run(_check)
	game = MAIN_SCRIPT.new()
	root.add_child(game)
	await _physics_frames(35)
	_test_structure()
	_test_world_floor()
	_test_ramp_collision_and_boundaries()
	await _test_movement()
	await _test_ramp_routes()
	await _test_jump_tricks_and_landing()
	await _test_spin_scoring()
	await _test_controls_disabled()
	await _test_bail_recovery()
	await _test_run_flow()
	await _test_overtime()
	await _test_input_events()
	_release_actions()
	paused = false
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + description)
	else:
		failed += 1
		push_error("FAIL: " + description)


func _test_score_session() -> void:
	var session = SCORE_SCRIPT.new()
	_check(session.total_score == 0 and session.get_combo_value() == 0,
		"new scoring session has no score or active combo")
	session.add_trick("Kickflip", 100)
	_check(session.combo_base == 100 and session.combo_multiplier == 1,
		"first trick contributes its base points and one multiplier")
	session.add_trick("Kickflip", 100)
	session.add_trick("Kickflip", 100)
	_check(session.combo_base == 175 and session.combo_multiplier == 1,
		"repeating a trick degrades to half then quarter without farming multiplier")
	session.add_trick("Melon Grab", 100)
	_check(session.combo_base == 275 and session.combo_multiplier == 2,
		"distinct tricks increase combo multiplier")
	_check(session.get_combo_value() == 550 and session.total_score == 0,
		"active combo previews multiplied value without awarding unlanded points")
	var awarded: int = session.bank_combo()
	_check(awarded == 550 and session.total_score == 550 and session.best_combo == 550,
		"landing bank awards combo and records best combo")
	_check(session.get_combo_value() == 0 and session.combo_base == 0,
		"banking clears active combo")
	_check(session.bank_combo() == 0 and session.total_score == 550,
		"banking twice cannot award the same combo again")
	session.add_trick("Kickflip", 100)
	_check(session.combo_base == 100, "repeat degradation resets for a new combo")
	session.drop_combo()
	_check(session.get_combo_value() == 0 and session.total_score == 550,
		"bailing drops the active combo and preserves previously banked score")
	for i in range(12):
		session.add_trick("Unique trick %d" % i, 100)
	_check(session.combo_multiplier <= 8, "unique trick multiplier obeys its cap")
	session.reset()
	_check(session.total_score == 0 and session.best_combo == 0
		and session.get_combo_value() == 0 and session.last_banked == 0,
		"run reset clears totals, best combo, bank feedback and active combo")


func _test_structure() -> void:
	_check(game.world is Node3D, "main instantiates the procedural world")
	_check(game.skater is CharacterBody3D, "main instantiates the skating physics body")
	_check(_count_nodes(game.skater, "Camera3D") >= 1, "skater includes a gameplay camera")
	_check(_count_nodes(game.world, "MeshInstance3D") >= 15,
		"square contains original procedural visible geometry")
	_check(_count_nodes(game.world, "StaticBody3D") >= 5,
		"floor, obstacles and boundaries include static collision")
	for action in ACTIONS:
		_check(InputMap.has_action(action), "input action is registered: " + action)
	var keyboard_actions: int = 0
	var controller_actions: int = 0
	for action in ACTIONS:
		var has_key: bool = false
		var has_pad: bool = false
		for event in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_pad = has_pad or event is InputEventJoypadButton or event is InputEventJoypadMotion
		keyboard_actions += 1 if has_key else 0
		controller_actions += 1 if has_pad else 0
	_check(keyboard_actions == ACTIONS.size(), "every gameplay action has a keyboard binding")
	_check(controller_actions == ACTIONS.size(), "every gameplay action has a gamepad binding")
	_check(game.world.get_spawn_position().is_equal_approx(Vector3(0, 0.8, 12)),
		"world spawn matches the shared coordinate contract")
	_check(not game.world.get_location_name(game.skater.global_position).is_empty(),
		"world provides a readable location label")


func _test_world_floor() -> void:
	var query = PhysicsRayQueryParameters3D.create(Vector3(0, 5, 12), Vector3(0, -2, 12))
	query.exclude = [game.skater.get_rid()]
	var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
	_check(not hit.is_empty(), "spawn has a supporting collision surface")
	if not hit.is_empty():
		_check(absf(hit.position.y) < 0.1 and hit.normal.y > 0.99,
			"spawn support is a level floor at the documented ground height")
	_check(game.skater.is_on_floor() and not game.skater.airborne,
		"spawn settles onto the floor without falling or becoming stuck airborne")


func _test_ramp_collision_and_boundaries() -> void:
	var ramps: Array[Node] = get_nodes_in_group("skateable_ramps")
	_check(ramps.size() == 4, "square exposes its four intended skateable ramps")
	for ramp in ramps:
		var from: Vector3 = ramp.global_position + Vector3.UP * 8.0
		var query = PhysicsRayQueryParameters3D.create(from, from - Vector3.UP * 10.0, 1)
		var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
		_check(not hit.is_empty() and hit.collider == ramp and hit.position.y > 0.25,
			"ramp has a raised supporting collision surface: " + ramp.name)
		if not hit.is_empty():
			_check(hit.normal.y >= cos(deg_to_rad(15.0)),
				"ramp top normal stays within its documented gentle incline: " + ramp.name)
		_check(_count_nodes(ramp, "MeshInstance3D") > 0,
			"ramp collision has visible procedural geometry: " + ramp.name)
	for direction in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var near_edge: Vector3 = direction * (32.0 if direction.x != 0.0 else 39.0)
		near_edge.y = 0.6
		var query = PhysicsRayQueryParameters3D.create(near_edge, near_edge + direction * 6.0, 1)
		var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
		_check(not hit.is_empty(), "boundary blocks outward floor travel toward " + str(direction))


func _test_movement() -> void:
	game.restart_run()
	await _physics_frames(30)
	var start: Vector3 = game.skater.global_position
	Input.action_press("push")
	await _physics_frames(30)
	Input.action_release("push")
	_check(game.skater.speed > 0.1 and game.skater.global_position.z < start.z - 0.5,
		"pushing accelerates and travels forward through the central route")
	_check(absf(game.skater.global_position.x - start.x) < 0.25,
		"unsteered flat-ground travel stays on its heading")
	var moving_speed: float = game.skater.speed
	Input.action_press("brake")
	await _physics_frames(24)
	Input.action_release("brake")
	_check(absf(game.skater.speed) < absf(moving_speed), "braking reduces forward speed")
	game.restart_run()
	await _physics_frames(30)
	var heading: float = game.skater.rotation.y
	Input.action_press("push")
	Input.action_press("steer_left")
	await _physics_frames(20)
	_release_actions()
	_check(absf(angle_difference(heading, game.skater.rotation.y)) > 0.05,
		"steering changes heading while skating")


func _test_ramp_routes() -> void:
	game.restart_run()
	await _physics_frames(30)
	Input.action_press("push")
	var max_height: float = 0.0
	for i in range(210):
		await _physics_frames(1)
		max_height = maxf(max_height, game.skater.global_position.y)
	Input.action_release("push")
	_check(max_height > 1.2, "central approach physically climbs the launch ramp")
	_check(game.skater.global_position.z < -16.0 and absf(game.skater.global_position.x) < 0.25,
		"central ramp route passes its crest and reaches the clear landing lane")
	_check(game.skater.is_on_floor(), "central ramp route returns to floor collision")
	game.restart_run()
	game.skater.global_position = Vector3(-17.0, 0.8, -23.0)
	game.skater.rotation.y = PI
	await _physics_frames(30)
	Input.action_press("push")
	max_height = 0.0
	for i in range(180):
		await _physics_frames(1)
		max_height = maxf(max_height, game.skater.global_position.y)
	Input.action_release("push")
	_check(max_height > 1.0, "tenement return approach physically climbs its ramp")
	_check(game.skater.global_position.z > 0.0 and absf(game.skater.global_position.x + 17.0) < 0.25,
		"tenement return route passes its crest and reaches its landing lane")
	_check(game.skater.is_on_floor(), "tenement return route returns to floor collision")


func _test_jump_tricks_and_landing() -> void:
	game.restart_run()
	await _physics_frames(30)
	observed_tricks.clear()
	observed_landings.clear()
	game.skater.trick_performed.connect(_record_trick)
	game.skater.landed.connect(_record_landing)
	var resting_y: float = game.skater.global_position.y
	Input.action_press("ollie")
	await _physics_frames(3)
	_check(game.skater.airborne and game.skater.global_position.y > resting_y + 0.1,
		"ollie launches from the floor")
	Input.action_press("flip")
	Input.action_press("grab")
	await _physics_frames(8)
	_check(game.score.get_combo_value() > 0 and game.score.total_score == 0,
		"aerial tricks create a pending combo before landing")
	# Keep trick inputs held until after touchdown: one press must not farm points.
	await _physics_frames(60)
	_release_actions()
	_check(observed_tricks.count("Ollie") == 1, "holding ollie does not auto-jump after landing")
	_check(observed_tricks.count("Kickflip") == 1, "held flip registers once during the jump")
	_check(observed_tricks.count("Melon Grab") == 1, "held grab registers once during the jump")
	_check(observed_landings.size() == 1 and observed_landings[0],
		"flat-ground airtime ends in exactly one clean landing signal")
	_check(game.score.total_score > 0 and game.score.get_combo_value() == 0,
		"clean landing banks the observed tricks through the main-to-score wiring")
	_check(game.skater.is_on_floor() and not game.skater.airborne,
		"skater returns to grounded physics state after landing")
	var banked_total: int = game.score.total_score
	await _physics_frames(12)
	_check(game.score.total_score == banked_total and observed_landings.size() == 1,
		"remaining grounded does not emit duplicate landings or awards")
	game.skater.trick_performed.disconnect(_record_trick)
	game.skater.landed.disconnect(_record_landing)


func _test_controls_disabled() -> void:
	game.restart_run()
	await _physics_frames(30)
	game.skater.set_controls_enabled(false)
	var start: Vector3 = game.skater.global_position
	Input.action_press("push")
	Input.action_press("ollie")
	Input.action_press("flip")
	await _physics_frames(20)
	_release_actions()
	_check(game.skater.global_position.distance_to(start) < 0.1
		and game.score.get_combo_value() == 0,
		"disabled controls prevent movement, jumps and scoring inputs")
	game.skater.set_controls_enabled(true)


func _test_spin_scoring() -> void:
	game.restart_run()
	await _physics_frames(30)
	observed_tricks.clear()
	game.skater.trick_performed.connect(_record_trick)
	Input.action_press("ollie")
	await _physics_frames(3)
	Input.action_release("ollie")
	Input.action_press("spin_right")
	await _physics_frames(35)
	Input.action_release("spin_right")
	await _physics_frames(40)
	_check(observed_tricks.count("Backside 180") == 1,
		"sustained aerial spin registers one completed 180 on landing")
	_check(game.score.total_score == 600,
		"spin points join the ollie combo before clean landing banks it")
	game.restart_run()
	await _physics_frames(30)
	observed_tricks.clear()
	Input.action_press("ollie")
	await _physics_frames(3)
	Input.action_release("ollie")
	Input.action_press("spin_left")
	await _physics_frames(14)
	Input.action_release("spin_left")
	Input.action_press("spin_right")
	await _physics_frames(14)
	Input.action_release("spin_right")
	await _physics_frames(45)
	_check(observed_tricks.size() == 1 and observed_tricks[0] == "Ollie"
		and game.score.total_score == 100,
		"opposing spins cancel net rotation instead of farming rotation awards")
	game.skater.trick_performed.disconnect(_record_trick)


func _test_bail_recovery() -> void:
	game.restart_run()
	await _physics_frames(30)
	game.score.add_trick("Prior bank", 100)
	game.score.bank_combo()
	game.score.add_trick("Pending trick", 500)
	game.skater.global_position.y = -10.0
	await _physics_frames(3)
	_check(game.skater.global_position.distance_to(game.skater.spawn_position) < 1.0,
		"out-of-world fall recovers to the spawn area")
	_check(game.score.total_score == 100 and game.score.get_combo_value() == 0,
		"bail signal drops the pending combo without erasing banked points")


func _test_run_flow() -> void:
	game.restart_run()
	await _physics_frames(3)
	var run_time: float = game.time_remaining
	await _physics_frames(6)
	_check(game.time_remaining < run_time, "run timer decreases during active play")
	game.toggle_pause()
	var pause_time: float = game.time_remaining
	var pause_position: Vector3 = game.skater.global_position
	Input.action_press("push")
	await _physics_frames(6)
	Input.action_release("push")
	_check(game.paused and is_equal_approx(game.time_remaining, pause_time),
		"pausing freezes the run timer")
	_check(game.skater.global_position.is_equal_approx(pause_position),
		"pausing freezes skater physics")
	game.toggle_pause()
	await _physics_frames(3)
	_check(not game.paused and game.time_remaining < pause_time,
		"unpausing resumes the run timer")
	game.toggle_free_skate()
	var free_time: float = game.time_remaining
	await _physics_frames(6)
	_check(game.free_skate_mode and is_equal_approx(game.time_remaining, free_time),
		"free skate disables countdown expiry")
	game.toggle_free_skate()
	game.restart_run()
	await _physics_frames(30)
	game.time_remaining = 0.01
	await _physics_frames(6)
	_check(game.run_finished and game.time_remaining <= 0.0,
		"grounded run ends when countdown reaches zero")
	var finished_position: Vector3 = game.skater.global_position
	Input.action_press("push")
	await _physics_frames(6)
	Input.action_release("push")
	_check(game.skater.global_position.distance_to(finished_position) < 0.1,
		"finished run gates player movement")
	game.restart_run()
	_check(not game.run_finished and not game.paused and game.time_remaining > 119.0
		and game.score.total_score == 0 and game.score.get_combo_value() == 0,
		"restart restores a fresh 120-second run and clears score")
	_check(game.skater.global_position.is_equal_approx(game.skater.spawn_position),
		"restart restores the world spawn position")


func _test_overtime() -> void:
	game.restart_run()
	await _physics_frames(30)
	Input.action_press("ollie")
	await _physics_frames(3)
	Input.action_release("ollie")
	game.time_remaining = 0.01
	await _physics_frames(6)
	_check(game.time_remaining <= 0.0 and not game.run_finished
		and game.score.get_combo_value() > 0,
		"timer expiry gives an active aerial combo time to land")
	await _physics_frames(65)
	_check(game.run_finished and game.score.total_score > 0
		and game.score.get_combo_value() == 0,
		"overtime clean landing banks its combo before finishing the run")
	game.restart_run()
	await _physics_frames(30)
	game.score.add_trick("Stalled aerial combo", 100)
	game.skater.airborne = true
	game.skater.set_physics_process(false)
	game.time_remaining = 0.01
	await _physics_frames(200)
	_check(game.run_finished and game.score.get_combo_value() == 0
		and game.score.total_score == 0,
		"overtime cannot preserve an unlanded combo indefinitely")
	game.restart_run()


func _test_input_events() -> void:
	await _physics_frames(30)
	_send_key(KEY_ESCAPE)
	await _physics_frames(2)
	_check(game.paused, "injected Escape key event reaches pause flow")
	_send_key(KEY_ESCAPE)
	await _physics_frames(2)
	_check(not game.paused, "injected Escape key event resumes paused play")
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_START
	button.pressed = true
	Input.parse_input_event(button)
	button = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_START
	button.pressed = false
	Input.parse_input_event(button)
	await _physics_frames(2)
	_check(game.paused, "injected standard gamepad Options event reaches pause flow")
	game.score.add_trick("Restart test", 100)
	_send_key(KEY_R)
	await _physics_frames(2)
	_check(not game.paused and not game.run_finished and game.score.get_combo_value() == 0
		and game.time_remaining > 119.0,
		"injected R key restarts directly from a paused run")


func _send_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)


func _physics_frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame


func _release_actions() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)


func _count_nodes(node: Node, type_name: String) -> int:
	var total: int = 1 if node.is_class(type_name) else 0
	for child in node.get_children():
		total += _count_nodes(child, type_name)
	return total


func _record_trick(trick_name: String, _points: int) -> void:
	observed_tricks.append(trick_name)


func _record_landing(clean: bool) -> void:
	observed_landings.append(clean)
