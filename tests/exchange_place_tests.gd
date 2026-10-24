extends RefCounted
## Independent motion proof for the two Exchange attachments. The caller may
## choose an initial supported fixture; subsequent movement uses real inputs.
## Ground heading is aimed directly. This is feasibility, not natural steering.
const GALLERY_LEDGE := "Grind_Ledge_GalleryEntrance"
const TrickCatalog = preload("res://game/tricks/trick_catalog.gd")
const ROUTE_IDS: Array[String] = ["gallery_entrance_bank_loop", "gallery_entrance_front_return",
	"gallery_entrance_bypass", "exchange_west_bank_loop", "exchange_west_bypass"]


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	game.persistence_enabled = false
	var all_routes := true
	for id: String in ROUTE_IDS:
		var route := _route(game, id)
		all_routes = all_routes and not route.is_empty() and not route.get("requires_jump", true)
	check.call(all_routes, "Exchange place: both attachments publish their supported bank joins and permanent bypasses")
	for id: String in ROUTE_IDS:
		var route := _route(game, id)
		if route.is_empty(): continue
		for reverse in [false, true]:
			var points: PackedVector3Array = route.points.duplicate()
			if reverse: points.reverse()
			await _reset(tree, game, points[0] + Vector3.UP * 0.8)
			var evidence: Dictionary = await _drive_route(tree, game, points)
			var expected_rise := 0.65 if id.begins_with("gallery_entrance_") else 0.45
			var bank_verified: bool = id.ends_with("bypass") or (evidence.slope_frames >= 4
				and evidence.max_y - evidence.min_y > expected_rise - 0.08)
			var label: String = id + (" reverse" if reverse else " forward")
			check.call(evidence.reached and evidence.bails == 0 and evidence.stalled_frames == 0
				and bank_verified and absf(game.skater.global_position.y - points[-1].y) < 0.12
				and evidence.camera_samples > 10 and evidence.camera_blocked == 0 and evidence.camera_hidden == 0,
				"Exchange place: real grade join and unobstructed chase " + label)
			_report(label, evidence, game)
	await _columns(tree, game, check)
	var protected := {
		"station south port": PackedVector3Array([Vector3(-35,0,22),Vector3(-22,0,22)]),
		"cone and east spine": PackedVector3Array([Vector3(22,2,-31),Vector3(22,2,-19)])}
	for id: String in protected:
		for reverse in [false, true]:
			var points: PackedVector3Array = protected[id].duplicate()
			if reverse: points.reverse()
			await _reset(tree, game, points[0] + Vector3.UP * 0.8)
			var evidence := await _drive_route(tree, game, points)
			check.call(evidence.reached and evidence.bails == 0 and evidence.stalled_frames == 0
				and evidence.camera_blocked == 0 and evidence.camera_hidden == 0,
				"Exchange place: preserved physical port and chase " + id + (" reverse" if reverse else " forward"))
	await _reset(tree, game, combo_fixture(game).position)
	var combo: Dictionary = await drive_ledge_combo(tree, game)
	check.call(combo.bank_ascent and combo.slope_frames >= 4 and combo.grounded_ascent > 0.18,
		"Exchange combo: actual push rides the new entrance bank before the ollie")
	check.call(combo.captured and combo.capture_ids == [GALLERY_LEDGE] and combo.south_exit,
		"Exchange combo: one real capture follows the bent seating ledge into its south-facing exit")
	check.call(combo.manual_entered and combo.connected and combo.bails == 0
		and combo.tricks == ["Ollie", TrickCatalog.resolve("grind", "north").display_name,
			"Ollie", "Kickflip", "Melon Grab", "Manual"] and combo.entries.size() == 6,
		"Exchange combo: rail ollie air tricks and a fresh Manual remain one physical line")
	var earned := _earned_combo(combo)
	check.call(earned.valid and combo.hold_valid and combo.hold_points >= 0 and combo.hold_points <= 300
		and earned.multiplier == 6 and combo.bank == earned.value
		and combo.banked_once and game.score.get_combo_value() == 0,
		"Exchange combo: exact catalog entries, repeat decay and bounded holds bank their independently calculated value once")
	check.call(combo.camera_samples > 30 and combo.camera_blocked == 0 and combo.camera_hidden == 0,
		"Exchange combo: actual bank ledge and landing chase remains finite clear and visible")
	print("EXCHANGE COMBO captured=%s south_exit=%s manual=%s connected=%s bank=%d entry_base=%d hold_points=%d multiplier=%d earned=%d bails=%d grounded_ascent=%.3f camera=%d/%d/%d tricks=%s" % [
		combo.captured,combo.south_exit,combo.manual_entered,combo.connected,combo.bank,
		earned.entry_base,combo.hold_points,earned.multiplier,earned.value,combo.bails,
		combo.grounded_ascent,combo.camera_samples,combo.camera_blocked,combo.camera_hidden,combo.tricks])
	_release()
	game.skater.spawn_position = original_spawn
	game.start_mode(false)


static func _columns(tree: SceneTree, game: Node, check: Callable) -> void:
	await _frames(tree, 2)
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	var blocked := true
	for index in 8:
		var x := lerpf(-6.08, 6.08, float(index) / 7.0)
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(x,3.4,-38),Vector3(x,3.4,-42),1))
		blocked = blocked and not hit.is_empty()
		if not hit.is_empty(): blocked = blocked and absf(hit.position.z + 40.4) < 0.6 and hit.normal.z > 0.7
	check.call(blocked, "Exchange portico: each exposed column has actual blocking collision above its base")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform = Transform3D(Basis.IDENTITY,Vector3(-6.1,3.63,-37))
	query.motion = Vector3(12.2,0,0)
	var sweep := space.cast_motion(query)
	check.call(sweep.size() == 2 and sweep[0] >= 0.9999,
		"Exchange portico: the front terrace crossing remains clear of the real columns")


## Shared with capture tooling. The caller settles this one supported fixture.
static func combo_fixture(_game: Node) -> Dictionary:
	return {"position": Vector3(-18,2.8,-35.3), "heading": -PI / 2.0}


## Awaited observers inspect actual states; they may render, never award progress.
static func drive_ledge_combo(tree: SceneTree, game: Node, observer: Callable = Callable()) -> Dictionary:
	var evidence := _evidence()
	evidence.merge({"bank_ascent": false, "grounded_ascent": 0.0, "captured": false,
		"capture_ids": [], "south_exit": false, "manual_entered": false, "connected": false,
		"tricks": [], "entries": [], "hold_points": 0, "hold_valid": true,
		"bank": 0, "banked_once": false})
	var initial_y: float = game.skater.global_position.y
	var on_bail := func(): evidence.bails += 1
	var on_trick := func(title: String, points: int):
		evidence.tricks.append(title)
		evidence.entries.append({"id": game.skater.last_trick_id, "title": title, "points": points})
	var on_hold := func(points: int):
		evidence.hold_points += points
		evidence.hold_valid = evidence.hold_valid and points > 0 and points % 25 == 0 and game.skater.grinding
	var on_capture := func(id: String): evidence.capture_ids.append(id)
	game.skater.bailed.connect(on_bail)
	game.skater.trick_performed.connect(on_trick)
	game.skater.hold_points_awarded.connect(on_hold)
	game.skater.grind_captured.connect(on_capture)
	var jumped := false
	for frame in 240:
		_aim(game.skater, Vector3.RIGHT)
		# The short ledge rewards a controlled approach. Real braking keeps the
		# existing bank-assisted ollie from sailing beyond it before descent.
		_navigation_input(game.skater.speed < -0.05 or game.skater.speed > 6.5)
		Input.action_press("grind")
		if not jumped and game.skater.is_on_floor():
			evidence.grounded_ascent = maxf(evidence.grounded_ascent,game.skater.global_position.y-initial_y)
			if not evidence.bank_ascent and evidence.grounded_ascent > 0.18:
				evidence.bank_ascent = true
				await _observe(observer,"bank_ascent",evidence)
		if not jumped and game.skater.global_position.x >= -8.7:
			Input.action_press("ollie")
			jumped = true
		else:
			if Input.is_action_pressed("ollie"):
				# This line intentionally uses the neutral Ollie. Cancel the
				# throttle cue on the pop frame instead of requesting a Nollie
				# from the approach controller's recent north-direction edge.
				Input.action_press("push")
				Input.action_press("brake")
			Input.action_release("ollie")
		await _step(tree,game,evidence)
		if game.skater.grinding:
			evidence.captured = true
			await _observe(observer,"captured",evidence)
			break
		if evidence.bails > 0: break
	Input.action_release("push")
	Input.action_release("brake")
	Input.action_release("ollie")
	if evidence.captured:
		for frame in 180:
			if not game.skater.grinding: break
			if game.skater.global_position.z > -33.85 and game.skater.velocity.z > absf(game.skater.velocity.x):
				evidence.south_exit = true
				break
			await _step(tree,game,evidence)
		if game.skater.grinding:
			Input.action_press("ollie")
			await _step(tree,game,evidence)
			Input.action_release("ollie")
			Input.action_release("grind")
			await _step(tree,game,evidence)
			Input.action_press("flip")
			Input.action_press("grab")
			await _step(tree,game,evidence)
			Input.action_release("flip")
			Input.action_release("grab")
			await _observe(observer,"rail_air",evidence)
			for frame in 120:
				await _step(tree,game,evidence)
				if game.skater.is_on_floor() and not game.skater.airborne:
					Input.action_press("manual")
					await _step(tree,game,evidence)
					evidence.manual_entered = game.skater.manual_active
					break
				if evidence.bails > 0: break
			for frame in 12: await _step(tree,game,evidence)
			evidence.connected = game.score.total_score == 0 and game.skater.manual_active
			await _observe(observer,"manual",evidence)
	_release()
	for frame in 30: await _step(tree,game,evidence)
	evidence.bank = game.score.total_score
	await _observe(observer,"banked",evidence)
	for frame in 30: await _step(tree,game,evidence)
	evidence.banked_once = evidence.bank > 0 and game.score.total_score == evidence.bank
	game.skater.bailed.disconnect(on_bail)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.hold_points_awarded.disconnect(on_hold)
	game.skater.grind_captured.disconnect(on_capture)
	return evidence


## Independent receipt calculation: no ScoreSession values or methods are used.
## This line has exactly one rail attachment; only that hold may contribute its
## bounded duration points. Every raw entry must match its actual catalog ID.
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


static func _drive_route(tree: SceneTree, game: Node, points: PackedVector3Array) -> Dictionary:
	var evidence := _evidence()
	var on_bail := func(): evidence.bails += 1
	game.skater.bailed.connect(on_bail)
	for target: Vector3 in points:
		var reached := false
		for frame in 600:
			var before: Vector3 = game.skater.global_position
			var offset := Vector3(target.x-before.x,0,target.z-before.z)
			if offset.length() <= 0.55:
				reached = true
				break
			if evidence.bails > 0: break
			_aim(game.skater,offset)
			_navigation_input(game.skater.speed < -0.05 or game.skater.speed > sqrt(30.0 * offset.length()))
			await _step(tree,game,evidence)
			if game.skater.global_position.distance_to(before) < 0.01 and frame > 90:
				evidence.stalled_frames += 1
		evidence.reached = evidence.reached and reached
		if not reached: break
	_release()
	game.skater.bailed.disconnect(on_bail)
	return evidence


static func _navigation_input(braking: bool) -> void:
	var crossing := Input.is_action_pressed("push" if braking else "brake") \
		and not Input.is_action_pressed("brake" if braking else "push")
	Input.action_press("brake" if braking else "push")
	if not crossing: Input.action_release("push" if braking else "brake")


static func _evidence() -> Dictionary:
	return {"reached": true,"bails": 0,"frames": 0,"slope_frames": 0,"min_y": INF,"max_y": -INF,
		"stalled_frames": 0,"camera_samples": 0,"camera_blocked": 0,"camera_hidden": 0}


static func _step(tree: SceneTree, game: Node, evidence: Dictionary) -> void:
	await _frames(tree,1)
	evidence.frames += 1
	evidence.min_y = minf(evidence.min_y,game.skater.global_position.y)
	evidence.max_y = maxf(evidence.max_y,game.skater.global_position.y)
	if game.skater.is_on_floor() and game.skater.get_floor_normal().y < 0.999:
		evidence.slope_frames += 1
	var camera: Camera3D = tree.root.get_camera_3d()
	var body_point: Vector3 = game.skater.global_position + Vector3.UP * 0.85
	evidence.camera_samples += 1
	if not camera.global_position.is_finite() or not camera.is_position_in_frustum(body_point):
		evidence.camera_hidden += 1
	var query := PhysicsRayQueryParameters3D.create(body_point,camera.global_position,1)
	var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		evidence.camera_blocked += 1
		if evidence.camera_blocked == 1:
			print("EXCHANGE CAMERA BLOCK rider=%s camera=%s hit=%s collider=%s" % [game.skater.global_position,camera.global_position,hit.position,hit.collider.name])


static func _route(game: Node, id: String) -> Dictionary:
	for route: Dictionary in game.world.get_route_definitions():
		if route.id == id: return route
	return {}


static func _report(label: String, evidence: Dictionary, game: Node) -> void:
	print("EXCHANGE ROUTE %s reached=%s seconds=%.2f height=%.3f..%.3f slope_frames=%d bails=%d stalls=%d camera=%d/%d/%d final=%s" % [
		label,evidence.reached,evidence.frames/60.0,evidence.min_y,evidence.max_y,evidence.slope_frames,
		evidence.bails,evidence.stalled_frames,evidence.camera_samples,evidence.camera_blocked,evidence.camera_hidden,game.skater.global_position])


static func _observe(observer: Callable, stage: String, evidence: Dictionary) -> void:
	if observer.is_valid(): await observer.call(stage,evidence.duplicate(true))


static func _reset(tree: SceneTree, game: Node, at: Vector3) -> void:
	_release()
	game.skater.spawn_position = at
	game.start_mode(true)
	Input.action_press("brake")
	await _frames(tree,45)
	Input.action_release("brake")


static func _aim(skater: CharacterBody3D, direction: Vector3) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if direction.length_squared() < 0.01: return
	var desired := atan2(-direction.x,-direction.z)
	if skater.is_on_floor(): skater.rotation.y = desired
	else:
		var difference := angle_difference(skater.rotation.y,desired)
		if absf(difference) > 0.04:
			Input.action_press("steer_left" if difference > 0.0 else "steer_right",minf(1.0,absf(difference)*4.0))


static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
