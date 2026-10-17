extends RefCounted
## Real terrain motion, curved coping and river recovery. Initial fixtures may
## relocate the spawn; after restart, only production physics moves the rider.
## Grounded heading is aimed directly: this is idealized feasibility, not feel.

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	game.persistence_enabled = false
	await _terrain_heights(tree, game, check)
	await _slopes(tree, game, check)
	await _fountain(tree, game, check)
	await _outdoor_routes(tree, game, check)
	await _bridge_and_recovery(tree, game, check)
	_release()
	game.skater.spawn_position = original_spawn
	game.start_mode(false)


static func _terrain_heights(tree: SceneTree, game: Node, check: Callable) -> void:
	game.start_mode(true)
	await _frames(tree, 2)
	var expected := [
		["Exchange lower square", Vector3(-22, 0, 28)],
		["Exchange gallery", Vector3(-22, 2, -26)],
		["George square", Vector3(-22, 4, -74)],
		["George civic terrace", Vector3(20, 6, -116)],
		["Central concourse", Vector3(-62, 2, 22)],
		["Central elevated platform", Vector3(-94, 5, -12)],
		["Barras market", Vector3(60, 0, 22)],
		["Barras loading terrace", Vector3(106, 1.5, -26)],
	]
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	for sample: Array in expected:
		var at: Vector3 = sample[1]
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
			at + Vector3.UP * 1.5, at - Vector3.UP * 1.0, 1))
		check.call(not hit.is_empty() and absf(hit.position.y - at.y) < 0.05
			and hit.normal.y > 0.99,
			"topography: actual level and upward support " + sample[0])


static func _slopes(tree: SceneTree, game: Node, check: Callable) -> void:
	for id: String in ["gallery_civic_ascent", "central_south_link", "market_loading_ascent"]:
		var route: Dictionary = _route(game, id)
		check.call(not route.is_empty(), "topography: authored graded route " + id)
		if route.is_empty(): continue
		for reverse in [false, true]:
			var points: PackedVector3Array = route.points.duplicate()
			if reverse: points.reverse()
			await _reset_at(tree, game, points[0] + Vector3.UP * 0.8)
			var evidence: Dictionary = await _drive(tree, game, points)
			var expected_change := absf(points[-1].y - points[0].y)
			var label: String = id + (" downhill" if reverse else " uphill")
			check.call(evidence.reached and evidence.bails == 0 and evidence.stalled_frames == 0
				and evidence.slope_frames >= 5 and evidence.max_y - evidence.min_y >= expected_change - 0.15,
				"topography: physical grade and seam transit " + label)
			print("TOPOGRAPHY route=%s reached=%s seconds=%.2f height=%.2f..%.2f slope_frames=%d bails=%d stalled=%d" % [
				label, evidence.reached, evidence.frames / 60.0, evidence.min_y, evidence.max_y,
				evidence.slope_frames, evidence.bails, evidence.stalled_frames])


static func _route(game: Node, id: String) -> Dictionary:
	for entry: Dictionary in game.world.get_route_definitions():
		if entry.id == id: return entry
	return {}


static func _fountain(tree: SceneTree, game: Node, check: Callable) -> void:
	var coping = null
	for line in game.world.get_grind_lines():
		if line.id == "Grind_Coping_ExchangeFountain": coping = line
	check.call(coping != null and coping.is_valid and coping.length > 35.0,
		"topography: fountain publishes a full curved coping circuit")
	if coping == null or not coping.is_valid: return
	var contact: Vector3 = coping.point_at(coping.length * 0.125)
	var tangent: Vector3 = coping.dir_at(coping.length * 0.125)
	var start: Vector3 = contact - tangent * 20.0
	start.y = game.world.get_ground_height(start) + 0.8
	await _reset_at(tree, game, start)
	var state := {"bails": 0}
	var on_bail := func(): state.bails += 1
	game.skater.bailed.connect(on_bail)
	var jumped := false
	var captured := false
	for frame in range(240):
		_aim(game.skater, tangent)
		Input.action_press("push")
		Input.action_press("grind")
		if not jumped and (contact - game.skater.global_position).dot(tangent) < 9.5:
			Input.action_press("ollie")
			jumped = true
		else:
			Input.action_release("ollie")
		await _frames(tree, 1)
		if game.skater.grinding:
			captured = true
			break
		if state.bails > 0: break
	Input.action_release("push")
	Input.action_release("ollie")
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	check.call(captured and jumped and game.score.trick_history.has("Ollie")
		and game.score.trick_history.count("Rail Grind") == 1,
		"topography: real ground approach and descending ollie capture fountain coping")
	if captured:
		var initial_heading: float = game.skater.rotation.y
		var initial_at: Vector3 = game.skater.global_position
		var max_error := 0.0
		for frame in range(36):
			Input.action_release("steer_left")
			Input.action_release("steer_right")
			if game.skater.grind_balance > 0.05: Input.action_press("steer_left")
			elif game.skater.grind_balance < -0.05: Input.action_press("steer_right")
			await _frames(tree, 1)
			var near: Dictionary = coping.closest(game.skater.global_position)
			max_error = maxf(max_error, near.get("gap", INF))
		check.call(game.skater.grinding and state.bails == 0 and max_error < 0.05
			and game.skater.global_position.distance_to(initial_at) > 4.0
			and absf(angle_difference(initial_heading, game.skater.rotation.y)) > 0.5,
			"topography: curved grind follows changing tangent without cutting through the fountain")
		_release()
		await _frames(tree, 80)
		check.call(not game.skater.grinding and state.bails == 0
			and game.score.total_score >= 600 and game.score.get_combo_value() == 0,
			"topography: released curved coping lands and banks once without a bail")
	else:
		check.call(false, "topography: curved grind follows changing tangent without cutting through the fountain")
		check.call(false, "topography: released curved coping lands and banks once without a bail")
	print("TOPOGRAPHY fountain captured=%s bails=%d position=%s" % [captured, state.bails, game.skater.global_position])
	game.skater.bailed.disconnect(on_bail)
	_release()


static func _outdoor_routes(tree: SceneTree, game: Node, check: Callable) -> void:
	for id: String in ["clyde_north_quay", "clyde_safe_crossing"]:
		var route: Dictionary = _route(game, id)
		check.call(not route.is_empty(), "topography: authored outdoor connection " + id)
		if route.is_empty(): continue
		await _reset_at(tree, game, route.points[0] + Vector3.UP * 0.8)
		var evidence: Dictionary = await _drive(tree, game, route.points)
		check.call(evidence.reached and evidence.bails == 0 and evidence.stalled_frames == 0
			and evidence.visited.has("clyde") and (id != "clyde_north_quay" or evidence.checkpoints.has("clyde")),
			"topography: actual supported outdoor travel " + id)
		print("TOPOGRAPHY outdoor=%s reached=%s seconds=%.2f bails=%d stalled=%d" % [
			id, evidence.reached, evidence.frames / 60.0, evidence.bails, evidence.stalled_frames])
	var climb: Dictionary = _route(game, "kelvingrove_central_climb")
	var circuit: Dictionary = _route(game, "kelvingrove_rolling_loop")
	check.call(not climb.is_empty() and not circuit.is_empty(), "topography: park climb and rolling loop published")
	if climb.is_empty() or circuit.is_empty(): return
	var points: PackedVector3Array = climb.points.duplicate()
	points.append_array(circuit.points)
	var back: PackedVector3Array = climb.points.duplicate()
	back.reverse()
	points.append_array(back)
	await _reset_at(tree, game, points[0] + Vector3.UP * 0.8)
	var park: Dictionary = await _drive(tree, game, points)
	check.call(park.reached and park.bails == 0 and park.stalled_frames == 0
		and park.visited.has("kelvingrove") and park.checkpoints.has("kelvingrove") and park.slope_frames > 100
		and park.max_y >= 16.5 and park.min_y < 2.2
		and game.skater.global_position.distance_to(points[0]) < 1.2,
		"topography: actual park climb, hill circuit and descent return to the Central port")
	print("TOPOGRAPHY park reached=%s seconds=%.2f height=%.2f..%.2f slopes=%d bails=%d stalled=%d" % [
		park.reached, park.frames / 60.0, park.min_y, park.max_y,
		park.slope_frames, park.bails, park.stalled_frames])


static func _bridge_and_recovery(tree: SceneTree, game: Node, check: Callable) -> void:
	var route: Dictionary = _route(game, "clyde_bridge_transfer")
	check.call(not route.is_empty(), "topography: broken bridge publishes its run-up and landing")
	if route.is_empty(): return
	var definition: Dictionary = {}
	for gap: Dictionary in game.world.get_gap_definitions():
		if gap.id == "clyde_bridge_transfer": definition = gap
	check.call(not definition.is_empty(), "topography: broken bridge has a named scored gap")
	if definition.is_empty(): return
	var start: Vector3 = route.points[0] + Vector3.UP * 0.8
	await _reset_at(tree, game, start)
	var state := {"bails": 0, "awards": 0}
	var on_bail := func(): state.bails += 1
	game.skater.bailed.connect(on_bail)
	var reached_takeoff := false
	Input.action_press("push")
	for frame in range(300):
		_aim(game.skater, Vector3.BACK)
		await _frames(tree, 1)
		if game.skater.global_position.z >= 91.8 and game.skater.is_on_floor():
			reached_takeoff = true
			break
		if state.bails > 0: break
	check.call(reached_takeoff and game.skater.speed >= 12.0 and game.skater.global_position.y > 2.8,
		"topography: actual push run-up reaches the bridge launch grade")
	Input.action_press("ollie")
	await _frames(tree, 1)
	Input.action_release("ollie")
	var landed_south := false
	for frame in range(240):
		await _frames(tree, 1)
		state.awards = maxi(state.awards, game.score.trick_history.count(definition.name))
		if game.skater.global_position.z >= 115.0 and game.skater.is_on_floor():
			landed_south = true
			break
		if state.bails > 0: break
	_release()
	Input.action_press("brake")
	await _frames(tree, 30)
	_release()
	check.call(landed_south and state.bails == 0 and state.awards == 1
		and game.score.total_score >= 2000 and game.score.get_combo_value() == 0,
		"topography: physical eight-metre bridge ollie reaches south bank and banks the named gap once")
	print("TOPOGRAPHY bridge takeoff=%s landed=%s awards=%d bank=%d bails=%d" % [
		reached_takeoff, landed_south, state.awards, game.score.total_score, state.bails])
	game.skater.bailed.disconnect(on_bail)
	# A separate missed-jump fixture earns an actual bank first, then rides off
	# the real deck without an ollie and performs a flip during the fall.
	await _reset_at(tree, game, start)
	Input.action_press("ollie")
	await _frames(tree, 1)
	Input.action_release("ollie")
	await _frames(tree, 80)
	var bank_before: int = game.score.total_score
	var failure := {"bails": 0, "water": false}
	var on_miss := func():
		failure.bails += 1
		var at: Vector3 = game.skater.global_position
		failure.water = at.y < -1.75 and at.z > 78.0 and at.z < 116.0
	game.skater.bailed.connect(on_miss)
	var pending_before_water := false
	var fall_trick := false
	var entered_water := false
	Input.action_press("push")
	for frame in range(360):
		_aim(game.skater, Vector3.BACK)
		if game.skater.airborne and game.skater.global_position.z > 94.0 and not fall_trick:
			Input.action_press("flip")
			fall_trick = true
		else:
			Input.action_release("flip")
		await _frames(tree, 1)
		pending_before_water = pending_before_water or (fall_trick and game.score.get_combo_value() > 0)
		entered_water = entered_water or game.skater.global_position.y < -1.5
		if failure.bails > 0: break
	_release()
	await _frames(tree, 50)
	check.call(bank_before == 100 and pending_before_water and failure.bails == 1
		and failure.water and game.score.total_score == bank_before and game.score.get_combo_value() == 0,
		"topography: missed bridge drops the real fall combo once and preserves the earned bank")
	check.call(game.skater.is_on_floor() and game.skater.global_position.y > 1.8
		and game.skater.spawn_position.is_equal_approx(start)
		and not game.world.get_recovery_position(game.skater.global_position).is_finite(),
		"topography: water recovery returns to supported quay without changing the run restart spawn")
	print("TOPOGRAPHY water bails=%d pending=%s sampled_water=%s bank=%d position=%s" % [
		failure.bails, pending_before_water, entered_water, game.score.total_score, game.skater.global_position])
	game.skater.bailed.disconnect(on_miss)


static func _drive(tree: SceneTree, game: Node, points: PackedVector3Array) -> Dictionary:
	var evidence := {"reached": true, "bails": 0, "frames": 0, "slope_frames": 0,
		"min_y": game.skater.global_position.y, "max_y": game.skater.global_position.y,
		"stalled_frames": 0, "visited": {}, "checkpoints": {}}
	var on_bail := func(): evidence.bails += 1
	game.skater.bailed.connect(on_bail)
	var checkpoints: Dictionary = game.world.get_district_checkpoints()
	for target: Vector3 in points:
		var reached := false
		for frame in range(900):
			var before: Vector3 = game.skater.global_position
			var offset := Vector3(target.x - before.x, 0, target.z - before.z)
			if offset.length() <= 0.8:
				reached = true
				break
			if evidence.bails > 0: break
			_aim(game.skater, offset)
			Input.action_press("push")
			await _frames(tree, 1)
			evidence.frames += 1
			evidence.visited[game.world.get_district_id(game.skater.global_position)] = true
			for id: String in checkpoints:
				var checkpoint: Vector3 = checkpoints[id]
				if Vector2(game.skater.global_position.x - checkpoint.x, game.skater.global_position.z - checkpoint.z).length() < 3.5:
					evidence.checkpoints[id] = true
			evidence.min_y = minf(evidence.min_y, game.skater.global_position.y)
			evidence.max_y = maxf(evidence.max_y, game.skater.global_position.y)
			if game.skater.is_on_floor() and game.skater.get_floor_normal().y < 0.999:
				evidence.slope_frames += 1
			if game.skater.global_position.distance_to(before) < 0.01 and frame > 90:
				evidence.stalled_frames += 1
		evidence.reached = evidence.reached and reached
		if not reached: break
	game.skater.bailed.disconnect(on_bail)
	_release()
	return evidence


static func _reset_at(tree: SceneTree, game: Node, at: Vector3) -> void:
	_release()
	game.skater.spawn_position = at
	game.start_mode(true)
	await _frames(tree, 45)


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


static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
