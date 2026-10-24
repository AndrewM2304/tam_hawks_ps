extends RefCounted
## Real terrain motion, curved coping and river recovery. Initial fixtures may
## relocate the spawn; after restart, only production physics moves the rider.
## Grounded heading is aimed directly: this is idealized feasibility, not feel.
const TrickCatalog = preload("res://game/tricks/trick_catalog.gd")

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	game.persistence_enabled = false
	await _terrain_heights(tree, game, check)
	await _slopes(tree, game, check)
	await _nonlinear_routes(tree, game, check)
	await _court_routes(tree, game, check)
	await _local_combo(tree, game, check)
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


static func _nonlinear_routes(tree: SceneTree, game: Node, check: Callable) -> void:
	# Each new branch is ridden in both directions. Straight-line endpoint
	# reachability alone would not prove the intermediate close/return is open.
	for id: String in ["station_low_level_close", "merchant_close_cutthrough",
		"kelvingrove_cutback_return", "clyde_print_yard_loop", "clyde_print_yard_hip",
		"merchant_service_east_return", "merchant_service_west_return"]:
		var route: Dictionary = _route(game, id)
		check.call(not route.is_empty(), "topography: nonlinear branch published " + id)
		if route.is_empty(): continue
		for reverse in [false, true]:
			var points: PackedVector3Array = route.points.duplicate()
			if reverse: points.reverse()
			await _reset_at(tree, game, points[0] + Vector3.UP * 0.8)
			var evidence: Dictionary = await _drive(tree, game, points)
			var label: String = id + (" reverse" if reverse else " forward")
			var shaped_support: bool = id != "clyde_print_yard_hip" or (
				evidence.max_y - evidence.min_y > 0.65 and evidence.slope_frames >= 5)
			if id.begins_with("merchant_service_"):
				shaped_support = evidence.slope_frames >= 5 \
					and evidence.max_y - evidence.min_y >= absf(points[-1].y - points[0].y) - 0.15 \
					and absf(game.skater.global_position.y - points[-1].y) < 0.15
			check.call(evidence.reached and evidence.bails == 0 and evidence.stalled_frames == 0 and shaped_support,
				"topography: real physical transit through every bend " + label)
			print("TOPOGRAPHY branch=%s reached=%s seconds=%.2f height=%.2f..%.2f bails=%d stalled=%d position=%s" % [
				label, evidence.reached, evidence.frames / 60.0, evidence.min_y, evidence.max_y,
				evidence.bails, evidence.stalled_frames, game.skater.global_position])
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	var hip: Dictionary = _route(game, "clyde_print_yard_hip")
	if not hip.is_empty():
		var angle_bins: Dictionary = {}
		var steepest := 0.0
		for index in range(hip.points.size() - 1):
			var at: Vector3 = hip.points[index]
			if hip.points[index + 1].y <= at.y + 0.005: continue
			var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
				at + Vector3.UP * 0.8, at - Vector3.UP * 0.4, 1))
			if hit.is_empty(): continue
			var angle := rad_to_deg(acos(clampf(hit.normal.y, -1.0, 1.0)))
			steepest = maxf(steepest, angle)
			angle_bins[floori(angle / 5.0)] = true
		check.call(angle_bins.size() >= 4 and steepest >= 30.0 and steepest <= 36.0,
			"topography: curved bank has multiple actual collision grades within its 35-degree contract")
		print("TOPOGRAPHY hip slope_bins=%d steepest=%.2f" % [angle_bins.size(), steepest])
	for x: float in [-114.0, -94.0]:
		var floor_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(x, 3.0, -8), Vector3(x, 1.0, -8), 1))
		var ceiling_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(x, 3.0, -8), Vector3(x, 6.0, -8), 1))
		var deck_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(x, 6.0, -8), Vector3(x, 4.8, -8), 1))
		check.call(not floor_hit.is_empty() and not ceiling_hit.is_empty() and not deck_hit.is_empty()
			and absf(floor_hit.position.y - 2.0) < 0.05 and floor_hit.normal.y > 0.99
			and absf(ceiling_hit.position.y - 4.6) < 0.05 and ceiling_hit.normal.y < -0.99
			and absf(deck_hit.position.y - 5.0) < 0.05 and deck_hit.normal.y > 0.99,
			"topography: independent low floor, overhead clearance and upper deck support x=" + str(x))


static func _local_combo(tree: SceneTree, game: Node, check: Callable) -> void:
	var ledge = null
	for line in game.world.get_grind_lines():
		if line.id == "clyde_print_yard_ledge": ledge = line
	check.call(ledge != null and ledge.is_valid, "topography: print-yard ledge publishes a usable local trick line")
	if ledge == null or not ledge.is_valid: return
	var target: Vector3 = ledge.point_at(2.2)
	var tangent: Vector3 = ledge.dir_at(2.2)
	var start: Vector3 = target - tangent * 20.0
	start.y = 2.8
	await _reset_at(tree, game, start)
	var evidence := {"bails": 0, "names": [], "entries": [], "capture_ids": [],
		"hold_points": 0, "hold_valid": true}
	var on_bail := func(): evidence.bails += 1
	var on_trick := func(title: String, points: int):
		evidence.names.append(title)
		evidence.entries.append({"id": game.skater.last_trick_id, "title": title, "points": points})
	var on_hold := func(points: int):
		evidence.hold_points += points
		evidence.hold_valid = evidence.hold_valid and points > 0 and points % 25 == 0 and game.skater.grinding
	var on_capture := func(id: String): evidence.capture_ids.append(id)
	game.skater.bailed.connect(on_bail)
	game.skater.trick_performed.connect(on_trick)
	game.skater.hold_points_awarded.connect(on_hold)
	game.skater.grind_captured.connect(on_capture)
	var launched := false
	var captured := false
	for frame in range(240):
		_aim(game.skater, tangent)
		Input.action_press("push")
		Input.action_press("grind")
		if not launched and (target - game.skater.global_position).dot(tangent) < 9.5:
			Input.action_press("ollie")
			launched = true
		else: Input.action_release("ollie")
		await _frames(tree, 1)
		if game.skater.grinding:
			captured = true
			break
		if evidence.bails > 0: break
	var manual_entered := false
	var connected := false
	if captured:
		Input.action_release("push")
		Input.action_release("ollie")
		await _frames(tree, 6)
		Input.action_press("ollie")
		await _frames(tree, 1)
		Input.action_release("ollie")
		await _frames(tree, 1)
		Input.action_release("grind")
		await _frames(tree, 2)
		Input.action_press("flip")
		Input.action_press("grab")
		await _frames(tree, 1)
		Input.action_release("flip")
		Input.action_release("grab")
		for frame in range(100):
			await _frames(tree, 1)
			if game.skater.is_on_floor() and not game.skater.airborne:
				Input.action_press("manual")
				await _frames(tree, 2)
				manual_entered = game.skater.manual_active
				break
			if evidence.bails > 0: break
		await _frames(tree, 12)
		connected = game.score.total_score == 0 and game.skater.manual_active
	check.call(captured and manual_entered and connected and evidence.bails == 0
		and evidence.capture_ids == [ledge.id] and evidence.entries.size() == 6
		and evidence.names == ["Ollie", TrickCatalog.resolve("grind", "north").display_name,
			"Ollie", "Kickflip", "Melon Grab", "Manual"],
		"topography: actual yard ollie capture rail-ollie air tricks and manual stay in one unbanked line")
	_release()
	await _frames(tree, 30)
	var banked: int = game.score.total_score
	await _frames(tree, 30)
	var earned := _earned_combo(evidence)
	check.call(evidence.bails == 0 and earned.valid and evidence.hold_valid
		and evidence.hold_points >= 0 and evidence.hold_points <= 300
		and earned.multiplier == 6 and banked == earned.value and game.score.total_score == banked
		and game.score.get_combo_value() == 0,
		"topography: local rail-air-manual route banks its independently calculated entries and bounded holds once")
	print("TOPOGRAPHY localcombo captured=%s manual=%s connected=%s bank=%d entry_base=%d hold_points=%d multiplier=%d earned=%d bails=%d tricks=%s" % [
		captured, manual_entered, connected, banked, earned.entry_base, evidence.hold_points,
		earned.multiplier, earned.value, evidence.bails, evidence.names])
	game.skater.bailed.disconnect(on_bail)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.hold_points_awarded.disconnect(on_hold)
	game.skater.grind_captured.disconnect(on_capture)


## Calculate the receipt from raw production events and catalog rules, without
## consulting ScoreSession's accumulated base, repetitions or multiplier.
static func _earned_combo(evidence: Dictionary) -> Dictionary:
	var repetitions: Dictionary = {}
	var entry_base := 0
	var valid := true
	for entry: Dictionary in evidence.entries:
		var definition := TrickCatalog.definition(str(entry.id))
		if definition.is_empty():
			valid = false
			continue
		valid = valid and entry.title == definition.display_name and entry.points == definition.base_points
		var count := int(repetitions.get(entry.id, 0))
		entry_base += maxi(1, int(float(definition.base_points) / pow(2.0, mini(count, 4))))
		repetitions[entry.id] = count + 1
	var multiplier := mini(evidence.entries.size(), 100)
	return {"valid": valid, "entry_base": entry_base, "multiplier": multiplier,
		"value": (entry_base + int(evidence.hold_points)) * multiplier}


static func _court_routes(tree: SceneTree, game: Node, check: Callable) -> void:
	for id: String in ["cat_coping_approach", "cat_coping_runout", "cat_workshop_bypass",
		"civic_workshop_bank_loop", "market_hall_bank_loop"]:
		var route: Dictionary = _route(game, id)
		check.call(not route.is_empty() and not route.requires_jump,
			"topography: permanent court approach or bank loop published " + id)
		if route.is_empty(): continue
		for reverse in [false, true]:
			var points: PackedVector3Array = route.points.duplicate()
			if reverse: points.reverse()
			await _reset_at(tree, game, points[0] + Vector3.UP * 0.8)
			var evidence: Dictionary = await _drive(tree, game, points)
			var grade_verified: bool = not id.ends_with("bank_loop") or (
				evidence.max_y - evidence.min_y > 0.6 and evidence.slope_frames >= 5)
			var label: String = id + (" reverse" if reverse else " forward")
			check.call(evidence.reached and evidence.bails == 0 and evidence.stalled_frames == 0
				and grade_verified and absf(game.skater.global_position.y - points[-1].y) < 0.15,
				"topography: physical court access and grade transit " + label)
			print("TOPOGRAPHY court=%s reached=%s seconds=%.2f height=%.2f..%.2f slope_frames=%d bails=%d stalled=%d position=%s" % [
				label, evidence.reached, evidence.frames / 60.0, evidence.min_y, evidence.max_y,
				evidence.slope_frames, evidence.bails, evidence.stalled_frames, game.skater.global_position])


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
	var state := {"bails": 0, "capture_ids": [], "tricks": []}
	var on_bail := func(): state.bails += 1
	var on_capture := func(id: String): state.capture_ids.append(id)
	var on_trick := func(title: String, _points: int): state.tricks.append(title)
	game.skater.bailed.connect(on_bail)
	game.skater.grind_captured.connect(on_capture)
	game.skater.trick_performed.connect(on_trick)
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
		and state.capture_ids == [coping.id]
		and state.tricks == ["Ollie", TrickCatalog.resolve("grind", "north").display_name],
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
	print("TOPOGRAPHY fountain captured=%s bails=%d position=%s captures=%s tricks=%s" % [
		captured, state.bails, game.skater.global_position, state.capture_ids, state.tricks])
	game.skater.bailed.disconnect(on_bail)
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.trick_performed.disconnect(on_trick)
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
	await _frames(tree, 1)
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
	for frame in 90:
		if not game.skater.bail_active: break
		await _frames(tree, 1)
	await _frames(tree, 15)
	for frame in 60:
		if game.skater.is_on_floor() and not game.skater.bail_active: break
		await _frames(tree, 1)
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
	Input.action_press("brake")
	await _frames(tree, 45)
	Input.action_release("brake")


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
