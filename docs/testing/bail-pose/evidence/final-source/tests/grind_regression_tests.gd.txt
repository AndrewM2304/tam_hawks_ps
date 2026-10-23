extends RefCounted
## Independent regressions for capture reached by play, blocked rides and timeout.


class RecoveryProbe extends Node:
	var rider:CharacterBody3D
	var previous:Vector3
	var maximum_step:=0.0
	var minimum_z:=INF
	func _ready()->void:
		process_physics_priority=100;previous=rider.global_position
	func _physics_process(_delta:float)->void:
		maximum_step=maxf(maximum_step,previous.distance_to(rider.global_position))
		minimum_z=minf(minimum_z,rider.global_position.z)
		previous=rider.global_position


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	_release_actions()
	if game.free_skate_mode:
		game.toggle_free_skate()
	await _ground_approach_and_obstruction(tree, game, check)
	game.skater.spawn_position = original_spawn
	await _overtime_admission(tree, game, check)
	_release_actions()
	game.restart_run()


static func _ground_approach_and_obstruction(tree: SceneTree, game: Node, check: Callable) -> void:
	# Establish a real supported approach, then use ordinary actions throughout
	# takeoff/capture. No airborne state, speed or travel velocity is injected.
	game.skater.spawn_position = Vector3(12.0, 0.8, 20.0)
	game.restart_run()
	await _frames(tree, 40)
	check.call(game.skater.is_on_floor() and not game.skater.airborne,
		"grind regression: ground approach starts with real floor support")
	var floor_height: float = game.skater.global_position.y
	var captures: Array[String] = []
	var on_capture := func(id: String) -> void: captures.append(id)
	game.skater.grind_captured.connect(on_capture)
	game.score.add_trick("Previously banked", 500)
	game.score.bank_combo()
	Input.action_press("push")
	Input.action_press("grind")
	await _frames(tree, 50)
	check.call(not game.skater.grinding and game.skater.is_on_floor()
		and game.skater.speed > 5.0 and game.score.get_combo_value() == 0,
		"grind regression: grounded push builds speed without snapping or scoring a rail")
	# Grounded hold already proved no snap. Request the specifically tested
	# descending catch after the apex; normal admission also allows <=1m/s rise.
	Input.action_release("grind")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	Input.action_release("push")
	var peak_height: float = game.skater.global_position.y
	var caught: bool = false
	var left_floor := false
	# Rail admission replaces velocity with its tangent. Keep the preceding
	# actual airborne sample as the independent descending-approach witness.
	var previous_airborne := false
	var previous_vertical_velocity := 0.0
	var descending_capture := false
	var descending_request := false
	for i in range(75):
		await _frames(tree, 1)
		peak_height = maxf(peak_height, game.skater.global_position.y)
		if not descending_request and game.skater.airborne and game.skater.velocity.y < 0.0:
			Input.action_press("grind")
			descending_request = true
		if game.skater.grinding:
			caught = true
			descending_capture = previous_airborne and previous_vertical_velocity < 0.0
			break
		previous_airborne = game.skater.airborne and not game.skater.is_on_floor()
		previous_vertical_velocity = game.skater.velocity.y
		left_floor = left_floor or (previous_airborne and game.skater.global_position.y > floor_height + 0.25)
	game.skater.grind_captured.disconnect(on_capture)
	check.call(caught and left_floor and descending_request and descending_capture and captures == ["Grind_Rail_Exchange"],
		"grind regression: real push and tap ollie leave support and descend into exactly one Exchange rail catch")
	print("GRIND APPROACH peak=", peak_height, " prior_air_vy=", previous_vertical_velocity,
		" departed=", left_floor, " descending_capture=", descending_capture, " captures=", captures)
	check.call(game.score.trick_history.has("Ollie")
		and game.score.trick_history.has("Rail Grind") and game.score.total_score == 500,
		"grind regression: played approach links ollie and rail without banking early")
	if caught:
		var bail_count: Array[int] = [0]
		var impact:Array[Vector3]=[]
		var recovered:Array[int]=[]
		var saved_spawn:Vector3=game.skater.spawn_position
		var probe:=RecoveryProbe.new();probe.rider=game.skater;tree.root.add_child(probe)
		var on_bail := func() -> void:
			bail_count[0] += 1;impact.append(game.skater.global_position)
		var on_recovered := func() -> void:recovered.append(Engine.get_physics_frames())
		game.skater.recovered.connect(on_recovered)
		game.skater.bailed.connect(on_bail)
		var wall := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(4.0, 4.0, 0.3)
		collider.shape = shape
		wall.add_child(collider)
		wall.position = game.skater.global_position + Vector3(0.0, 1.0, -1.5)
		game.world.add_child(wall)
		await _frames(tree, 30)
		check.call(bail_count[0] == 1 and not game.skater.grinding,
			"grind regression: scenery blocking an active ride produces exactly one bail")
		check.call(game.score.total_score == 500 and game.score.get_combo_value() == 0,
			"grind regression: obstructed ride loses its pending combo and preserves prior bank")
		for tick in 240:
			if not game.skater.bailing and game.skater.is_on_floor():break
			await _frames(tree,1)
		check.call(impact.size()==1 and recovered.size()==1 and not game.skater.bailing and game.skater.is_on_floor()
			and game.skater.spawn_position==saved_spawn and game.skater.global_position.distance_to(impact[0])<2.0
			and game.skater.global_position.distance_to(saved_spawn)>2.0,
			"grind regression: obstructed ride recovers locally on support and preserves the run restart spawn")
		check.call(probe.maximum_step<.3 and probe.minimum_z>=wall.position.z+.15+.28-.05 and bail_count[0]==1,
			"grind regression: the complete rail fall/get-up stays collision-safe without teleport or another failure")
		print("GRIND LOCAL RECOVERY step=",probe.maximum_step," impact=",impact," ready=",game.skater.global_position," spawn=",saved_spawn)
		game.skater.recovered.disconnect(on_recovered);probe.queue_free()
		game.skater.bailed.disconnect(on_bail)
		wall.queue_free()
		await _frames(tree, 2)
	_release_actions()


static func _overtime_admission(tree: SceneTree, game: Node, check: Callable) -> void:
	# Pre-position only for precise timeout-boundary checks; approach was tested
	# entirely through played movement above.
	await _air_fixture(tree, game, Vector3(-6, 5, 24), Vector3.ZERO)
	game.score.add_trick("Existing combo", 100)
	game.time_remaining = 0.01
	await _frames(tree, 3)
	Input.action_press("flip")
	Input.action_press("grab")
	Input.action_press("spin_right")
	await _frames(tree, 12)
	_release_actions()
	check.call(not game.run_finished and game.score.combo_base == 100,
		"grind regression: overtime rejects fresh aerial flip and grab entries")
	await _frames(tree, 60)
	check.call(game.run_finished and game.score.total_score == 100,
		"grind regression: fresh overtime spin cannot increase the landing award")

	await _air_fixture(tree, game, Vector3(12, 1.1, 11.5), Vector3(0, -1, -6))
	game.score.add_trick("Existing combo", 100)
	game.time_remaining = 0.01
	await _frames(tree, 3)
	Input.action_press("grind")
	await _frames(tree, 2)
	check.call(not game.skater.grinding and not game.score.trick_history.has("Rail Grind")
		and game.score.combo_base == 100,
		"grind regression: overtime rejects a fresh otherwise eligible rail attachment")
	_release_actions()

	await _air_fixture(tree, game, Vector3(12, 1.1, 11.5), Vector3(0, -1, -6))
	Input.action_press("grind")
	await _frames(tree, 3)
	check.call(game.skater.grinding, "grind regression: timeout fixture begins on a valid active rail")
	var rail_combo: int = game.score.get_combo_value()
	game.time_remaining = 0.01
	await _frames(tree, 3)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	check.call(game.skater.grinding and game.score.get_combo_value() == rail_combo
		and game.skater.velocity.y < 0.1,
		"grind regression: overtime cannot start a new scored rail ollie")
	Input.action_release("grind")
	await _frames(tree, 1)
	Input.action_press("grind")
	await _frames(tree, 2)
	Input.action_release("grind")
	check.call(not game.skater.grinding and game.skater.airborne,
		"grind regression: overtime still permits releasing an existing rail")
	await _frames(tree, 60)
	check.call(game.run_finished and game.score.total_score == rail_combo
		and game.score.get_combo_value() == 0,
		"grind regression: released overtime rail combo banks once on physical landing")

	await _air_fixture(tree, game, Vector3(-6, 6, 24), Vector3.ZERO)
	game.score.add_trick("Existing combo", 100)
	Input.action_press("spin_right")
	await _frames(tree, 30)
	Input.action_release("spin_right")
	game.time_remaining = 0.01
	await _frames(tree, 60)
	check.call(game.run_finished and game.score.total_score == 600,
		"grind regression: a spin completed before expiry still resolves in the landing combo")


static func _air_fixture(tree: SceneTree, game: Node, at: Vector3, motion: Vector3) -> void:
	_release_actions()
	game.restart_run()
	await _frames(tree, 2)
	game.skater.set_physics_process(false)
	game.skater.global_position = at
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = motion
	game.skater.speed = Vector2(motion.x, motion.z).length()
	game.skater.airborne = true
	game.skater.set_physics_process(true)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame
		await tree.process_frame


static func _release_actions() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
