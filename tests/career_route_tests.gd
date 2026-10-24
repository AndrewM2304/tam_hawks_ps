extends RefCounted
## Input-driven route feasibility, not a human playtest or target-device benchmark.
## Position is assigned only by restart at each route's initial fixture. The driver
## may aim heading on supported ground; velocity/speed/collision are never injected.

const CareerSource = preload("res://game/progression/career_progress.gd")
const CIRCUIT: Array[Vector3] = [
	Vector3(-22, 2, -26), Vector3(-22, 2, -22), Vector3(18, 2, -22),
	Vector3(22, 2, -22), Vector3(22, 4, -74), Vector3(-22, 4, -74),
	Vector3(22, 4, -74), Vector3(22, 6, -116), Vector3(20, 6, -116),
	Vector3(22, 4, -74), Vector3(-60, 4, -80), Vector3(-88, 4, -80),
	Vector3(-88, 2, -40), Vector3(-82, 2, -40), Vector3(-62, 2, 22),
	Vector3(-82, 2, 34), Vector3(-94, 2, 34), Vector3(-94, 5, 4.5),
	Vector3(-94, 5, -12), Vector3(-94, 2, -38), Vector3(-62, 2, -38),
	Vector3(-62, 2, 22), Vector3(-22, 0, 22), Vector3(22, 0, 22),
	Vector3(60, 0, 22), Vector3(70, 0, 22), Vector3(94, 0, 20),
	Vector3(106, 0, 26), Vector3(126, 0, 26), Vector3(126, 1.5, -18),
	Vector3(120, 1.5, -22), Vector3(120, 1.5, -33), Vector3(120, 1.5, -22),
	Vector3(106, 1.5, -22), Vector3(106, 1.5, -26), Vector3(75, 1.5, -26),
	Vector3(75, 1.5, -22), Vector3(22, 2, -22), Vector3(-22, 2, -22),
	Vector3(-22, 0, 28),
]
const COMBO_WAYPOINTS: Array[int] = [0, 4, 10, 21, 29, 37]


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_career = game.career
	var original_spawn: Vector3 = game.skater.spawn_position
	_release()
	game.persistence_enabled = false
	game.career = CareerSource.new()
	await _collection_circuit(tree, game, check)
	await _boundary_combos(tree, game, check)
	_release()
	game.career = original_career
	game.skater.spawn_position = original_spawn
	game.start_mode(false)


static func _collection_circuit(tree: SceneTree, game: Node, check: Callable) -> void:
	game.skater.spawn_position = game.world.get_spawn_position()
	game.start_mode(false)
	await _frames(tree, 45)
	var evidence := {"bails": 0, "frames": 45, "distance": 0.0, "stalled_frames": 0,
		"checkpoints": {}, "letters_at": -1.0, "market_at": -1.0, "secret_at": -1.0,
		"all_goals_at": -1.0, "tricks": {}, "scoring_legs": 0, "central_upper_landing": false}
	var on_bail := func(): evidence.bails += 1
	var on_trick := func(name: String, _points: int): evidence.tricks[name] = evidence.tricks.get(name, 0) + 1
	game.skater.bailed.connect(on_bail)
	game.skater.trick_performed.connect(on_trick)
	var completed_route := true
	for index in CIRCUIT.size():
		var target: Vector3 = CIRCUIT[index]
		var scoring_leg: bool = COMBO_WAYPOINTS.has(index)
		var result: Dictionary = await _drive_to(tree, game, target, evidence, scoring_leg)
		print("ROUTE waypoint %d %s reached=%s t=%.2f pos=%s speed=%.2f" % [
			index, CIRCUIT[index], result.reached, 120.0 - game.time_remaining,
			game.skater.global_position, game.skater.speed])
		if not result.reached:
			completed_route = false
			break
		if target == Vector3(18, 2, -22):
			Input.action_press("interact")
			await _recorded_frames(tree, game, evidence, 1)
			Input.action_release("interact")
		elif target == Vector3(-94, 5, 4.5):
			# Charge while physically traversing the remaining south platform.
			# A one-tick tap now lands in its gap rather than on the north deck.
			Input.action_press("ollie")
			await _recorded_frames(tree, game, evidence, 15)
			Input.action_release("ollie")
		elif target == Vector3(-94, 5, -12):
			evidence.central_upper_landing = game.skater.is_on_floor() and not game.skater.airborne \
				and absf(game.skater.global_position.y - 5.0) < 0.20
		if scoring_leg:
			_release()
			Input.action_press("brake")
			await _recorded_frames(tree, game, evidence, 25)
			Input.action_release("brake")
	_release()
	game.skater.bailed.disconnect(on_bail)
	game.skater.trick_performed.disconnect(on_trick)
	check.call(completed_route and not game.run_finished and evidence.bails == 0,
		"career routes: input-driven collection circuit returns to spawn within 120 seconds without recovery")
	check.call(evidence.checkpoints.has_all(["royal_exchange", "george_square", "central_station", "barras"]),
		"career routes: continuous circuit physically passes all four district checkpoints")
	check.call(game.career.completed_ids.has("letters"),
		"career routes: continuous career run collects every HAWKS letter")
	check.call(game.career.completed_ids.has("market_sweep") and game.career.completed_ids.has("lost_recording"),
		"career routes: continuous route collects all market items and enters/exits the recording court")
	check.call(game.career.completed_ids.has("across_toon"),
		"career routes: physical district traversal grants Across the toon")
	check.call(game.career.completed_ids.has("cone") and game.world.cone_activated
		and game.career.completed_ids.has("platform_change"),
		"career routes: continuous circuit interacts with the cone and physically ollies the Central gap")
	check.call(evidence.central_upper_landing,
		"career routes: charged Central gap traversal lands on the real upper platform rather than the lower concourse")
	check.call(game.career.completed_ids.size() == 10 and game.score.total_score >= 15000
		and game.score.best_combo >= 3000 and evidence.tricks.get("Manual", 0) >= 5,
		"career routes: actual input tricks and collections complete all ten goals in one timed career run")
	print("ROUTE SUMMARY circuit=%s seconds=%.2f distance=%.2f bails=%d stalled_frames=%d letters_at=%.2f market_at=%.2f secret_at=%.2f" % [
		completed_route, 120.0 - game.time_remaining, evidence.distance, evidence.bails,
		evidence.stalled_frames, evidence.letters_at, evidence.market_at, evidence.secret_at])
	print("ROUTE CAREER all_goals_at=%.2f score=%d best_combo=%d trick_inputs=%s" % [
		evidence.all_goals_at, game.score.total_score, game.score.best_combo, evidence.tricks])


static func _boundary_combos(tree: SceneTree, game: Node, check: Callable) -> void:
	var routes := [
		["Exchange to George east grade", Vector3(22, 2.8, -26), Vector3(22, 4, -74)],
		["Exchange to Central south grade", Vector3(-20, 0.8, 22), Vector3(-65, 2, 22)],
		["Exchange to Barras north grade", Vector3(22, 2.8, -22), Vector3(65, 1.5, -22)],
	]
	for route: Array in routes:
		for reverse in [false, true]:
			var start: Vector3 = route[2] + Vector3.UP * 0.8 if reverse else route[1]
			var target: Vector3 = route[1] if reverse else route[2]
			_release()
			game.skater.spawn_position = start
			game.start_mode(false)
			await _frames(tree, 45)
			var evidence := {"bails": 0, "crossed": false, "connected": true, "manual": false, "entries": 0, "transitions": []}
			var on_bail := func(): evidence.bails += 1
			game.skater.bailed.connect(on_bail)
			var on_trick := func(name: String, _points: int):
				if name == "Manual": evidence.entries += 1
			game.skater.trick_performed.connect(on_trick)
			var origin_district: String = game.world.get_district_id(start)
			var jumped := false
			var performed_air_tricks := false
			var manual_entered := false
			var reached := false
			var trace: bool = str(route[0]) == "Exchange to Barras north grade" and reverse
			var previous_airborne: bool = game.skater.airborne
			var previous_manual: bool = game.skater.manual_active
			var previous_bank := 0
			var previous_manual_input := false
			var previous_manual_buffer := 0.0
			for frame in range(900):
				var offset: Vector3 = target - game.skater.global_position
				offset.y = 0
				if offset.length() <= 1.0:
					reached = true
					break
				if game.run_finished or evidence.bails > 0: break
				_aim(game.skater, offset)
				Input.action_release("ollie")
				Input.action_release("flip")
				Input.action_release("grab")
				Input.action_release("brake")
				Input.action_release("steer_left")
				Input.action_release("steer_right")
				if not jumped:
					Input.action_press("push")
					if game.skater.is_on_floor() and game.skater.speed >= 12.0:
						Input.action_press("ollie")
						jumped = true
				elif game.skater.airborne:
					Input.action_release("manual")
					Input.action_release("push")
					if not performed_air_tricks:
						Input.action_press("flip")
						Input.action_press("grab")
						performed_air_tricks = true
				elif performed_air_tricks and game.skater.is_on_floor() and not game.skater.manual_active:
					Input.action_release("push")
					# Make one deliberate held request near eligibility. Alternating
					# presses every tick tests an artificial release phase instead of
					# the bounded human request buffer after a natural crest landing.
					var cooldown: float = game.skater.get("_manual_cooldown")
					if cooldown > 0.10:
						Input.action_release("manual")
					elif not Input.is_action_pressed("manual"):
						Input.action_press("manual")
					manual_entered = true
				elif game.skater.manual_active:
					Input.action_release("push")
					Input.action_release("steer_left")
					Input.action_release("steer_right")
					if game.skater.manual_balance > 0.08: Input.action_press("steer_left")
					elif game.skater.manual_balance < -0.08: Input.action_press("steer_right")
				await _frames(tree, 1)
				var manual_input: bool = Input.is_action_pressed("manual")
				var manual_buffer: float = game.skater.get("_manual_buffer_remaining")
				if trace and (previous_airborne != game.skater.airborne or previous_manual != game.skater.manual_active \
						or previous_bank != game.score.total_score or previous_manual_input != manual_input \
						or (previous_manual_buffer <= 0.0 and manual_buffer > 0.0)):
					evidence.transitions.append({"frame": frame, "position": game.skater.global_position,
						"velocity": game.skater.velocity, "airborne": game.skater.airborne,
						"manual": game.skater.manual_active, "manual_cooldown": game.skater.get("_manual_cooldown"),
						"manual_input": manual_input, "manual_buffer": manual_buffer,
						"landing_remaining": game.score.landing_remaining, "bank": game.score.total_score})
				previous_airborne = game.skater.airborne
				previous_manual = game.skater.manual_active
				previous_bank = game.score.total_score
				previous_manual_input = manual_input
				previous_manual_buffer = manual_buffer
				if manual_entered:
					evidence.connected = evidence.connected and game.score.total_score == 0
				if game.world.get_district_id(game.skater.global_position) != origin_district:
					evidence.crossed = true
					evidence.manual = evidence.manual or game.skater.manual_active
			_release()
			await _frames(tree, 25)
			game.skater.bailed.disconnect(on_bail)
			game.skater.trick_performed.disconnect(on_trick)
			var expected_bank: int = {1: 3000, 2: 4000, 3: 4950}.get(evidence.entries, -1)
			var bank_before: int = game.score.total_score
			await _frames(tree, 25)
			var label: String = route[0] + (" reverse" if reverse else " forward")
			if trace: print("ROUTE COMBO WITNESS ", label, " ", evidence.transitions)
			check.call(reached and evidence.bails == 0 and evidence.crossed and evidence.manual
				and evidence.connected and bank_before == expected_bank and game.score.total_score == bank_before
				and game.score.get_combo_value() == 0,
				"career routes: uninterrupted air/manual combo crosses and banks " + label)
			print("ROUTE COMBO %s seconds=%.2f bank=%d crossed=%s connected=%s manual=%s entries=%d bails=%d" % [
				label, 120.0 - game.time_remaining, game.score.total_score, evidence.crossed,
				evidence.connected, evidence.manual, evidence.entries, evidence.bails])


static func _drive_to(tree: SceneTree, game: Node, target: Vector3, evidence: Dictionary, scoring: bool = false) -> Dictionary:
	var jumped := false
	var air_tricks := false
	# A timed career now rewards repertoire across separate banks: choose real
	# directional inputs instead of repeatedly earning fresh default-trick values.
	var scoring_direction := "neutral"
	if scoring:
		var directions: Array[String] = ["neutral", "east", "north", "north_west", "north_east", "south_west"]
		scoring_direction = directions[int(evidence.scoring_legs) % directions.size()]
		evidence.scoring_legs += 1
	for frame in range(900):
		var at: Vector3 = game.skater.global_position
		var offset := Vector3(target.x - at.x, 0, target.z - at.z)
		if offset.length() <= 1.0:
			return {"reached": true}
		if game.run_finished or evidence.bails > 0:
			return {"reached": false}
		_aim(game.skater, offset)
		if not scoring:
			Input.action_press("push")
		else:
			Input.action_release("ollie")
			Input.action_release("flip")
			Input.action_release("grab")
			Input.action_release("brake")
			Input.action_release("steer_left")
			Input.action_release("steer_right")
			if not jumped:
				Input.action_press("push")
				if game.skater.is_on_floor() and game.skater.speed >= 12.0:
					Input.action_press("ollie")
					jumped = true
			elif game.skater.airborne:
				Input.action_release("manual")
				Input.action_release("push")
				if not air_tricks:
					if "north" in scoring_direction: Input.action_press("push")
					if "south" in scoring_direction: Input.action_press("brake")
					if "west" in scoring_direction: Input.action_press("steer_left")
					if "east" in scoring_direction: Input.action_press("steer_right")
					Input.action_press("flip")
					Input.action_press("grab")
					air_tricks = true
			elif air_tricks and not game.skater.manual_active:
				Input.action_release("push")
				if Input.is_action_pressed("manual"): Input.action_release("manual")
				else: Input.action_press("manual")
			elif game.skater.manual_active:
				Input.action_release("push")
				Input.action_release("steer_left")
				Input.action_release("steer_right")
				if game.skater.manual_balance > 0.08: Input.action_press("steer_left")
				elif game.skater.manual_balance < -0.08: Input.action_press("steer_right")
		await _frames(tree, 1)
		_record(game, at, evidence)
	return {"reached": false}


static func _aim(skater: CharacterBody3D, direction: Vector3) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	var desired: float = atan2(-direction.x, -direction.z)
	if skater.is_on_floor():
		skater.rotation.y = desired
	else:
		var difference: float = angle_difference(skater.rotation.y, desired)
		if absf(difference) > 0.04:
			Input.action_press("steer_left" if difference > 0 else "steer_right", minf(1.0, absf(difference) * 4.0))


static func _record(game: Node, previous: Vector3, evidence: Dictionary) -> void:
	var at: Vector3 = game.skater.global_position
	var travel := Vector2(at.x - previous.x, at.z - previous.z).length()
	evidence.distance += travel
	evidence.frames += 1
	if travel < 0.01 and evidence.frames > 90:
		evidence.stalled_frames += 1
	for id: String in game.world.get_district_checkpoints():
		var target: Vector3 = game.world.get_district_checkpoints()[id]
		if Vector2(at.x - target.x, at.z - target.z).length() < 3.5:
			evidence.checkpoints[id] = true
	var elapsed: float = 120.0 - game.time_remaining
	for key: String in ["letters", "market_sweep", "lost_recording"]:
		var field: String = {"letters": "letters_at", "market_sweep": "market_at", "lost_recording": "secret_at"}[key]
		if evidence[field] < 0 and game.career.completed_ids.has(key):
			evidence[field] = elapsed
	if evidence.all_goals_at < 0 and game.career.completed_ids.size() == 10:
		evidence.all_goals_at = elapsed


static func _recorded_frames(tree: SceneTree, game: Node, evidence: Dictionary, count: int) -> void:
	for frame in range(count):
		var before: Vector3 = game.skater.global_position
		await _frames(tree, 1)
		_record(game, before, evidence)


static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame
		await tree.process_frame
