extends RefCounted
## Independent callback boundaries and continuous real-input delivery routes.
## Only the caller's initial fixture resets position. Ground heading is aimed;
## speed, velocity, gap, trick, bank and success are never injected by the driver.
const MarketSource = preload("res://game/characters/market_encounter.gd")
const CareerSource = preload("res://game/progression/career_progress.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var definition := _definition(game)
	check.call(not definition.is_empty() and definition.routes.size() == 2,
		"delivery: two authored market choices and a stable encounter definition exist")
	if definition.is_empty(): return
	await _rules(tree, definition, check)
	await _navigation(tree, definition, check)
	var original_career = game.career
	var original_spawn: Vector3 = game.skater.spawn_position
	game.persistence_enabled = false
	game.career = CareerSource.new()
	for route: Dictionary in definition.routes:
		await _reset(tree, game, definition.position + Vector3.UP * 0.8, true)
		var completed: Array = game.career.completed_ids.duplicate()
		var record: int = game.career.best_score
		var observed_navigation: Dictionary = {}
		var observe_bank := func(stage: String, _evidence: Dictionary):
			if stage == "banked":
				observed_navigation.targets = game.market_encounter.status_snapshot().navigation_targets
				observed_navigation.text = game._market_navigation_text(observed_navigation.targets)
				observed_navigation.north_entries = true
				observed_navigation.left_sectors = true
				for target: Dictionary in observed_navigation.targets:
					observed_navigation.north_entries = observed_navigation.north_entries \
						and target.position.z < game.skater.global_position.z
					var facing := Vector2(-game.skater.global_basis.z.x, -game.skater.global_basis.z.z)
					var offset: Vector3 = target.position - game.skater.global_position
					var bearing := rad_to_deg(facing.angle_to(Vector2(offset.x, offset.z)))
					observed_navigation.left_sectors = observed_navigation.left_sectors \
						and bearing > -120.0 and bearing < -30.0
		var result: Dictionary = await drive_delivery(tree, game, route.id, observe_bank)
		check.call(result.accepted and result.carried and result.manual_entered,
			"delivery physics: real pickup attaches the parcel and fresh Manual starts " + route.id)
		check.call(result.gap_seen and result.tricks == ["Manual", "Ollie"]
			and result.bank == 1650 and result.line_banked,
			"delivery physics: actual Manual ollie gap and clean bank earn exactly 1650 " + route.id)
		check.call(result.reached and result.route_id == route.id and result.route_index == 3
			and result.success and result.wins == 1 and result.bails == 0,
			"delivery physics: continuous movement completes all three chosen gates and physical arrival " + route.id)
		check.call(result.camera_samples > 20 and result.camera_blocked == 0 and result.camera_hidden == 0,
			"delivery camera: actual chase remains finite unobstructed and sees the rider " + route.id)
		check.call(observed_navigation.get("targets", []).size() == 2
			and observed_navigation.get("north_entries", false)
			and observed_navigation.get("left_sectors", false)
			and str(observed_navigation.get("text", "")).contains("COVERED 1: LEFT")
			# A real stop before the manual line banks slightly farther north.
			# Calton is now 113 degrees left, within the 120-degree side cue.
			and str(observed_navigation.get("text", "")).contains("CALTON 1: LEFT"),
			"delivery navigation: the actual bank directs the south-facing rider back towards both north entries " + route.id)
		check.call(game.career.completed_ids == completed and game.career.best_score == record
			and game.career.goals_snapshot().size() == 10 and not game.persistence_enabled
			and game.encounters.status_snapshot().attempts == 0 and game.cat_encounter.status_snapshot().attempts == 0,
			"delivery isolation: free skating preserves career saves and both other side acts " + route.id)
		if route.id == "covered":
			await _payoff(tree, game, result, check)
			var reverse := route.gates.duplicate() as PackedVector3Array
			reverse.reverse()
			var returning := _evidence(route.id)
			var return_clear := true
			for target: Vector3 in reverse:
				return_clear = await _drive_to(tree, game, target, returning) and return_clear
			check.call(return_clear and returning.camera_blocked == 0 and returning.camera_hidden == 0,
				"delivery camera: the earned run returns north through the covered aisle without reset or camera blockage")
		print("DELIVERY route=%s reached=%s bank=%d bails=%d gates=%d time=%.2f camera_samples=%d blocked=%d hidden=%d" % [
			route.id, result.reached, result.bank, result.bails, result.route_index,
			60.0 - result.remaining, result.camera_samples, result.camera_blocked, result.camera_hidden])
	await _lifecycle(tree, game, definition, check)
	_release()
	game.career = original_career
	game.apply_settings(original_career.settings, false)
	game.skater.spawn_position = original_spawn
	game.start_mode(false)


static func _rules(tree: SceneTree, definition: Dictionary, check: Callable) -> void:
	var delivery = MarketSource.new()
	tree.root.add_child(delivery)
	delivery.configure([definition])
	var pickup: Vector3 = definition.position
	var destination: Vector3 = definition.delivery_position
	var covered: Dictionary = definition.routes[0]
	var other: Dictionary = definition.routes[1]
	delivery.poll(pickup, true, 0.0, 100)
	delivery.poll(pickup + Vector3(4.21, 0, 0), true, 0.0)
	delivery.poll(pickup + Vector3(0, 2.5, 0), true, 0.0)
	check.call(delivery.status_snapshot().state == "idle" and delivery.status_snapshot().attempts == 0,
		"delivery rules: pending combos and out-of-range offers cannot collect a parcel")
	delivery.poll(pickup, true, 0.0)
	delivery.poll(destination, false, 0.0)
	check.call(delivery.status_snapshot().state == "active" and delivery.status_snapshot().carrying
		and delivery.status_snapshot().wins == 0,
		"delivery rules: pickup and proximity to the counter alone cannot win")
	delivery.on_gap(definition.required_gap, pickup)
	delivery.on_trick("Manual", 100, pickup)
	delivery.on_bank(900, pickup)
	check.call(not delivery.status_snapshot().line_banked and not delivery.status_snapshot().manual_seen
		and not delivery.status_snapshot().gap_seen and delivery.status_snapshot().state == "active",
		"delivery rules: reversed gap/manual order cannot qualify and the early bank clears that line")
	delivery.on_trick("Manual", 0, pickup)
	delivery.on_gap(definition.required_gap, pickup)
	check.call(not delivery.status_snapshot().manual_seen and not delivery.status_snapshot().gap_seen,
		"delivery rules: a zero-point or missing Manual cannot arm the required gap")
	delivery.on_trick("Manual", 100, pickup)
	delivery.on_gap("central_gap", pickup)
	delivery.on_bank(9999, pickup)
	check.call(not delivery.status_snapshot().line_banked and not delivery.status_snapshot().manual_seen,
		"delivery rules: an unrelated gap and large bank cannot substitute for the market line")
	_qualifying_callbacks(delivery, definition)
	delivery.poll(covered.gates[0], false, 0.0)
	delivery.on_gap(definition.required_gap, covered.gates[0])
	delivery.poll(other.gates[0], false, 0.0)
	delivery.poll(covered.gates[2], false, 0.0)
	check.call(delivery.status_snapshot().route_id == covered.id and delivery.status_snapshot().route_index == 1,
		"delivery rules: first gate commits the branch and duplicate gap, other lane or skipped gates cannot advance it")
	delivery.on_bank(0, pickup)
	delivery.on_bank(-1, pickup)
	check.call(not delivery.status_snapshot().line_banked,
		"delivery rules: the qualified line still needs a positive clean bank")
	delivery.on_bank(1, pickup)
	delivery.poll(destination, false, 0.0)
	check.call(delivery.status_snapshot().line_banked and delivery.status_snapshot().state == "active",
		"delivery rules: a bank without the complete chosen route cannot deliver")
	delivery.poll(covered.gates[1], false, 0.0)
	delivery.poll(covered.gates[2], false, 0.0)
	delivery.poll(destination + Vector3(0, 2.5, 0), false, 0.0)
	check.call(delivery.status_snapshot().route_index == 3 and delivery.status_snapshot().state == "active",
		"delivery rules: arrival also checks actual vertical proximity")
	delivery.poll(destination, false, 0.0)
	delivery.on_bank(9999, destination)
	delivery.poll(destination, false, 0.0)
	check.call(delivery.status_snapshot().state == "success" and delivery.status_snapshot().wins == 1
		and not delivery.status_snapshot().carrying and delivery.status_snapshot().celebration_state == "queued",
		"delivery rules: valid arrival completes once and queues an unseen payoff without another reward")
	delivery.poll(destination + Vector3(10.01, 0, 0), false, 0.0, 0, true)
	delivery.poll(destination, false, 0.0, 0, false)
	check.call(not delivery.status_snapshot().celebration_started,
		"delivery rules: the gull payoff waits for both audience range and visibility")
	delivery.poll(destination, false, 0.0, 0, true)
	check.call(delivery.status_snapshot().celebration_started and delivery.status_snapshot().wins == 1,
		"delivery rules: an eligible visible audience starts the already earned response")
	delivery.poll(pickup, true, 0.0, 100)
	check.call(delivery.status_snapshot().attempts == 1 and delivery.status_snapshot().state == "success",
		"delivery rules: a pending combo cannot overwrite a completed attempt")
	delivery.poll(pickup, true, 0.0)
	check.call(delivery.status_snapshot().state == "active" and delivery.status_snapshot().attempts == 2
		and delivery.status_snapshot().wins == 1 and delivery.status_snapshot().route_index == 0,
		"delivery rules: clean replay resets parcel and route while preserving the run-local win")
	delivery.on_trick("Manual", 100, pickup)
	delivery.on_bail()
	check.call(delivery.status_snapshot().state == "failed" and not delivery.status_snapshot().carrying
		and not delivery.status_snapshot().manual_seen,
		"delivery rules: a bail returns the parcel and invalidates all line evidence")
	for callback: String in ["on_trick", "on_gap", "on_bank"]:
		delivery.poll(pickup, true, 0.0)
		var outside := Vector3(132, 0, 0)
		if callback == "on_trick": delivery.on_trick("Manual", 100, outside)
		elif callback == "on_gap": delivery.on_gap(definition.required_gap, outside)
		else: delivery.on_bank(1650, outside)
		check.call(delivery.status_snapshot().state == "failed" and not delivery.status_snapshot().carrying,
			"delivery rules: outside " + callback + " fails before any subsequent poll")
	delivery.poll(pickup, true, 0.0)
	var remaining: float = delivery.status_snapshot().remaining
	delivery.poll(pickup, false, NAN)
	delivery.poll(pickup, false, -1.0)
	var invalid_ignored: bool = is_equal_approx(delivery.status_snapshot().remaining, remaining)
	delivery.poll(pickup, false, 59.99)
	var before_deadline: bool = delivery.status_snapshot().state == "active"
	delivery.poll(pickup, false, 0.02)
	check.call(invalid_ignored and before_deadline and delivery.status_snapshot().state == "failed"
		and not delivery.status_snapshot().carrying,
		"delivery rules: invalid deltas are ignored and the actual sixty-second deadline returns the parcel")
	delivery.poll(pickup, true, 0.0)
	delivery.cancel_attempt()
	delivery.finish_run()
	delivery.finish_run()
	check.call(delivery.status_snapshot().state == "failed" and delivery.status_snapshot().wins == 1,
		"delivery rules: cancellation and repeated run finish cannot produce another delivery")
	delivery.reset_run()
	check.call(delivery.status_snapshot().state == "idle" and delivery.status_snapshot().attempts == 0
		and delivery.status_snapshot().wins == 0 and not delivery.status_snapshot().carrying,
		"delivery rules: reset clears every session-local attempt and parcel state")
	delivery.queue_free()
	await tree.process_frame


static func _navigation(tree: SceneTree, definition: Dictionary, check: Callable) -> void:
	var delivery = MarketSource.new()
	delivery.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(delivery)
	delivery.configure([definition])
	var markers := delivery.get_node("MarketStallholder/RouteMarkers") as Node3D
	var positions_match: bool = markers.get_child_count() == 7
	for route: Dictionary in definition.routes:
		for index in 3:
			var marker := markers.get_node_or_null("Route_%s_%d" % [route.id, index + 1]) as Node3D
			positions_match = positions_match and marker != null
			if marker != null:
				positions_match = positions_match and marker.global_position.is_equal_approx(route.gates[index])
	var arrival := markers.get_node_or_null("DeliveryArrival") as Node3D
	positions_match = positions_match and arrival != null
	if arrival != null: positions_match = positions_match and arrival.global_position.is_equal_approx(definition.delivery_position)
	check.call(positions_match, "delivery markers: all six numbered lane markers and arrival match the configured world positions")
	check.call(markers.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"delivery markers: visible route cues add no collision objects to either skating lane")
	var idle_empty: bool = delivery.status_snapshot().navigation_targets.is_empty()
	delivery.poll(definition.position, true, 0.0)
	check.call(idle_empty and delivery.status_snapshot().navigation_targets.is_empty() and _active_markers(markers) == 0,
		"delivery navigation: idle and pre-gap states do not invent a premature lane target")
	_qualifying_callbacks(delivery, definition)
	var choices: Array = delivery.status_snapshot().navigation_targets
	check.call(choices.size() == 2 and choices[0].position.is_equal_approx(definition.routes[0].gates[0])
		and choices[1].position.is_equal_approx(definition.routes[1].gates[0]) and _active_markers(markers) == 2,
		"delivery navigation: the real configured first gates of both choices become visible after the required gap")
	var route: Dictionary = definition.routes[0]
	delivery.poll(route.gates[0], false, 0.0)
	var next: Array = delivery.status_snapshot().navigation_targets
	check.call(next.size() == 1 and next[0].position.is_equal_approx(route.gates[1]) and _active_markers(markers) == 1,
		"delivery navigation: committing a branch highlights only its next ordered gate")
	delivery.poll(route.gates[1], false, 0.0)
	delivery.poll(route.gates[2], false, 0.0)
	var final_target: Array = delivery.status_snapshot().navigation_targets
	check.call(final_target.size() == 1 and final_target[0].position.is_equal_approx(definition.delivery_position)
		and _active_markers(markers) == 1,
		"delivery navigation: all three gates lead to the physical counter instead of another lane marker")
	var poses := _poses(markers)
	await _frames(tree, 10)
	var ordinary_steady := _unchanged_poses(markers, poses)
	delivery.reduced_motion = true
	await _frames(tree, 10)
	check.call(ordinary_steady and _unchanged_poses(markers, poses)
		and delivery.status_snapshot().navigation_targets == final_target,
		"delivery markers: ordinary and reduced-motion cues remain steady with identical navigation")
	delivery.on_bail()
	var failure_cleared: bool = delivery.status_snapshot().navigation_targets.is_empty() and _active_markers(markers) == 0
	delivery.reset_run()
	check.call(failure_cleared and delivery.status_snapshot().navigation_targets.is_empty() and _active_markers(markers) == 0,
		"delivery navigation: failure and reset remove stale target highlights")
	delivery.queue_free()
	await tree.process_frame


static func _active_markers(markers: Node3D) -> int:
	var count := 0
	for marker in markers.get_children():
		if bool(marker.get_meta("navigation_active", false)): count += 1
	return count


## Reused by actual capture tooling. Caller supplies one settled initial pickup
## fixture; observers may inspect/render stages but may not manufacture progress.
static func drive_delivery(tree: SceneTree, game: Node, route_id: String, observer: Callable = Callable()) -> Dictionary:
	var definition := _definition(game)
	var route: Dictionary = {}
	for candidate: Dictionary in definition.routes:
		if candidate.id == route_id: route = candidate
	var evidence := _evidence(route_id)
	if route.is_empty(): return evidence
	var on_trick := func(title: String, _points: int): evidence.tricks.append(title)
	var on_bail := func(): evidence.bails += 1
	game.skater.trick_performed.connect(on_trick)
	game.skater.bailed.connect(on_bail)
	await _observe(observer, "offer", evidence)
	Input.action_press("interact")
	await _step(tree, game, evidence)
	Input.action_release("interact")
	await _step(tree, game, evidence)
	evidence.accepted = game.market_encounter.status_snapshot().state == "active"
	var bags: Array = game.skater.find_children("CourierBag", "Node3D", true, false)
	evidence.carried = bags.size() == 1 and bags[0].is_visible_in_tree()
	await _observe(observer, "pickup", evidence)
	var reached: bool = await _drive_to(tree, game, Vector3(93, 1.5, -30), evidence)
	# Stop the navigation approach before beginning the deliberate manual line.
	# Both directions held for one real frame cancel its previous trick cue;
	# a full gesture interval on the brake prevents the next push being parsed
	# as the second half of a quick brake/push nose-manual command.
	Input.action_press("push")
	Input.action_press("brake")
	await _step(tree, game, evidence)
	Input.action_release("push")
	for frame in 20: await _step(tree, game, evidence)
	Input.action_release("brake")
	_aim(game.skater, Vector3.BACK)
	Input.action_press("push")
	for frame in 180:
		await _step(tree, game, evidence)
		if game.skater.global_position.z >= -22.0: break
	Input.action_release("push")
	Input.action_press("manual")
	await _step(tree, game, evidence)
	evidence.manual_entered = game.skater.manual_active
	await _observe(observer, "manual", evidence)
	for frame in 180:
		Input.action_release("push")
		Input.action_release("brake")
		if game.skater.manual_balance > 0.05: Input.action_press("push")
		elif game.skater.manual_balance < -0.05: Input.action_press("brake")
		if game.skater.global_position.z >= -15.3: break
		await _step(tree, game, evidence)
	Input.action_release("push")
	Input.action_release("brake")
	Input.action_press("ollie")
	await _step(tree, game, evidence)
	Input.action_release("ollie")
	Input.action_release("manual")
	# The delivery line calls for the ordinary Ollie. Cancel the balancing
	# direction on its release frame so a recent brake correction does not
	# deliberately select the new Boneless/No Comply takeoff instead.
	Input.action_press("push")
	Input.action_press("brake")
	await _step(tree, game, evidence)
	Input.action_release("push")
	Input.action_release("brake")
	var bank_reported := false
	for frame in 180:
		if game.skater.is_on_floor(): Input.action_press("brake")
		await _step(tree, game, evidence)
		if not evidence.gap_seen and game.score.trick_history.has("Market Loading Steps"):
			evidence.gap_seen = true
			await _observe(observer, "gap", evidence)
		if not bank_reported and game.score.total_score > 0:
			bank_reported = true
			evidence.bank = game.score.total_score
			evidence.line_banked = game.market_encounter.status_snapshot().line_banked
			await _observe(observer, "banked", evidence)
		if bank_reported and game.skater.speed < 0.1: break
	_release()
	for index in route.gates.size():
		reached = await _drive_to(tree, game, route.gates[index], evidence) and reached
		await _observe(observer, "gate_" + str(index + 1), evidence)
	reached = await _drive_to(tree, game, definition.delivery_position, evidence) and reached
	_release()
	var snapshot: Dictionary = game.market_encounter.status_snapshot()
	evidence.reached = reached
	evidence.route_id = snapshot.route_id
	evidence.route_index = snapshot.route_index
	evidence.success = snapshot.state == "success"
	evidence.wins = snapshot.wins
	evidence.remaining = snapshot.remaining
	await _observe(observer, "arrival", evidence)
	Input.action_press("brake")
	for frame in 120:
		if game.market_encounter.status_snapshot().celebration_started: break
		_aim(game.skater, definition.delivery_position - game.skater.global_position)
		await _step(tree, game, evidence)
	_release()
	evidence.payoff_started = game.market_encounter.status_snapshot().celebration_started
	var camera: Camera3D = tree.root.get_camera_3d()
	evidence.payoff_visible = camera.is_position_in_frustum(definition.delivery_position + Vector3.UP * 0.8)
	await _observe(observer, "payoff", evidence)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.bailed.disconnect(on_bail)
	return evidence


static func _payoff(tree: SceneTree, game: Node, evidence: Dictionary, check: Callable) -> void:
	var actor = game.market_encounter.get_node("MarketStallholder")
	check.call(evidence.payoff_started and evidence.payoff_visible and actor.animation_snapshot().payoff_active
		and actor.animation_snapshot().delivered and not actor.animation_snapshot().carrying,
		"delivery payoff: real arrival and the actual camera start the earned spare-parcel response")
	var elapsed: float = actor.animation_snapshot().payoff_time
	game.toggle_pause()
	await _frames(tree, 20)
	check.call(not actor.can_process() and is_equal_approx(actor.animation_snapshot().payoff_time, elapsed),
		"delivery payoff: menu pause freezes the visible gull response")
	game.toggle_pause()
	Input.action_press("brake")
	await _frames(tree, 220)
	_release()
	check.call(not actor.animation_snapshot().payoff_active and actor.animation_snapshot().spare_taken
		and game.market_encounter.status_snapshot().wins == 1 and game.score.total_score == 1650,
		"delivery payoff: the bounded gull takes only the spare with no repeated delivery or score")
	game.apply_settings({"reduced_motion": true}, false)
	var poses := _poses(actor)
	await _frames(tree, 20)
	check.call(_unchanged_poses(actor, poses) and not actor.animation_snapshot().payoff_active,
		"delivery payoff: reduced motion keeps the complete actor and parcels static")
	game.apply_settings({"reduced_motion": false}, false)


static func _lifecycle(tree: SceneTree, game: Node, definition: Dictionary, check: Callable) -> void:
	await _reset(tree, game, definition.position + Vector3.UP * 0.8, false)
	await _interact(tree)
	var remaining: float = game.market_encounter.status_snapshot().remaining
	game.toggle_pause()
	await _frames(tree, 20)
	check.call(game.market_encounter.status_snapshot().state == "active"
		and is_equal_approx(game.market_encounter.status_snapshot().remaining, remaining),
		"delivery lifecycle: real menu pause freezes the pickup deadline")
	game.toggle_pause()
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	game.time_remaining = 0.03 # Explicit career-clock boundary, never a score/movement fixture.
	await _frames(tree, 4)
	check.call(game.time_remaining == 0.0 and game.score.get_combo_value() > 0
		and game.market_encounter.status_snapshot().state == "failed"
		and not game.market_encounter.status_snapshot().carrying,
		"delivery lifecycle: first career expiry returns the parcel during ordinary combo overtime")
	await _frames(tree, 100)
	await _interact(tree)
	check.call(game.run_finished and game.market_encounter.status_snapshot().attempts == 1
		and game.market_encounter.status_snapshot().wins == 0,
		"delivery lifecycle: results input cannot revive the expired parcel")
	game.restart_run()
	await _frames(tree, 45)
	check.call(game.market_encounter.status_snapshot().state == "idle"
		and game.market_encounter.status_snapshot().attempts == 0,
		"delivery lifecycle: restart restores the pickup with no stale route or attempt")
	await _interact(tree)
	_aim(game.skater, Vector3.LEFT)
	Input.action_press("push")
	await _frames(tree, 40)
	Input.action_release("push")
	Input.action_press("manual")
	await _frames(tree, 2)
	var entered: bool = game.skater.manual_active
	var evidence := {"bails": 0}
	var on_bail := func(): evidence.bails += 1
	game.skater.bailed.connect(on_bail)
	for frame in 280:
		await _frames(tree, 1)
		if evidence.bails > 0: break
	_release()
	game.skater.bailed.disconnect(on_bail)
	var bag := game.skater.find_child("CourierBag", true, false) as Node3D
	var actor = game.market_encounter.get_node("MarketStallholder")
	check.call(entered and evidence.bails == 1 and game.score.get_combo_value() == 0
		and game.market_encounter.status_snapshot().state == "failed" and bag != null and not bag.visible
		and actor.get_node("PickupParcel").visible,
		"delivery lifecycle: a real unbalanced Manual bails once and visibly returns the carried parcel")


static func _definition(game: Node) -> Dictionary:
	for entry: Dictionary in game.world.get_encounter_definitions():
		if entry.id == "gull_proof_delivery": return entry.duplicate(true)
	return {}


static func _qualifying_callbacks(delivery: Node, definition: Dictionary) -> void:
	delivery.on_trick("Manual", 100, definition.position)
	delivery.on_gap(definition.required_gap, definition.position)


static func _evidence(route_id: String) -> Dictionary:
	return {"requested_route": route_id, "accepted": false, "carried": false, "manual_entered": false,
		"gap_seen": false, "bank": 0, "line_banked": false, "reached": false, "success": false,
		"wins": 0, "bails": 0, "tricks": [], "route_id": "", "route_index": 0, "remaining": 0.0,
		"frames": 0, "camera_samples": 0, "camera_blocked": 0, "camera_hidden": 0,
		"payoff_started": false, "payoff_visible": false}


static func _observe(observer: Callable, stage: String, evidence: Dictionary) -> void:
	if observer.is_valid(): await observer.call(stage, evidence.duplicate(true))


static func _drive_to(tree: SceneTree, game: Node, target: Vector3, evidence: Dictionary) -> bool:
	for frame in 480:
		var offset: Vector3 = target - game.skater.global_position
		offset.y = 0.0
		if offset.length() < 0.65:
			# End each navigation leg with a real cancelling input frame. The
			# next leg's acceleration is travel, not a brake/push trick gesture.
			Input.action_press("push")
			Input.action_press("brake")
			await _step(tree, game, evidence)
			_release()
			return true
		_aim(game.skater, offset)
		_navigation_input(game.skater.speed < -0.05 or game.skater.speed > sqrt(30.0 * offset.length()))
		await _step(tree, game, evidence)
		if game.market_encounter.status_snapshot().state == "failed": break
	_release()
	return false


static func _navigation_input(braking: bool) -> void:
	# Overlap once to cancel the trick direction before ordinary throttle
	# changes, rather than accidentally asking for a push/brake manual gesture.
	var crossing := Input.is_action_pressed("push" if braking else "brake") \
		and not Input.is_action_pressed("brake" if braking else "push")
	Input.action_press("brake" if braking else "push")
	if not crossing: Input.action_release("push" if braking else "brake")


static func _aim(skater: CharacterBody3D, direction: Vector3) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if direction.length_squared() < 0.01: return
	var desired := atan2(-direction.x, -direction.z)
	if skater.is_on_floor(): skater.rotation.y = desired
	else:
		var difference := angle_difference(skater.rotation.y, desired)
		if absf(difference) > 0.04:
			Input.action_press("steer_left" if difference > 0.0 else "steer_right", minf(1.0, absf(difference) * 4.0))


static func _step(tree: SceneTree, game: Node, evidence: Dictionary) -> void:
	await _frames(tree, 1)
	evidence.frames += 1
	var camera: Camera3D = tree.root.get_camera_3d()
	var body_point: Vector3 = game.skater.global_position + Vector3.UP * 0.85
	evidence.camera_samples += 1
	if not camera.global_position.is_finite() or not camera.is_position_in_frustum(body_point):
		evidence.camera_hidden += 1
	var query := PhysicsRayQueryParameters3D.create(body_point, camera.global_position, 1)
	if not game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		evidence.camera_blocked += 1


static func _poses(parent: Node3D) -> Dictionary:
	var poses: Dictionary = {".": parent.transform}
	for child in parent.find_children("*", "Node3D", true, false):
		poses[String(parent.get_path_to(child))] = child.transform
	return poses


static func _unchanged_poses(parent: Node3D, poses: Dictionary) -> bool:
	for path: String in poses:
		var node := parent.get_node_or_null(path) as Node3D
		if node == null or not node.transform.is_equal_approx(poses[path]): return false
	return true


static func _reset(tree: SceneTree, game: Node, at: Vector3, free: bool) -> void:
	_release()
	game.skater.spawn_position = at
	game.start_mode(free)
	Input.action_press("brake")
	await _frames(tree, 45)
	Input.action_release("brake")


static func _interact(tree: SceneTree) -> void:
	Input.action_press("interact")
	await _frames(tree, 1)
	Input.action_release("interact")
	await _frames(tree, 1)


static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
