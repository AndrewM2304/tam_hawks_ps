extends RefCounted
## Independent production-player proof. Only documented initial fixtures assign
## position/motion; all preparation, contacts, tricks and recovery then run native.
## An optional observer records these same physics steps as continuous evidence.
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const ContactGeometry = preload("res://tests/full_repertoire_tests.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const WheelContact = preload("res://tests/curved_visual_contact_tests.gd")
const SOLE := Vector3(0, -0.0605, 0)
const PALM := Vector3(0, -0.075, -0.015)
const SAFE := Vector3(-22, 0.8, 28)
static var _observer := Callable()
static var _phase := ""
static var _step := 0
static var _game: Node
static var _navigation_action := ""
static var _camera_hulls: Dictionary = {}
static var _shoe_floor_stats: Dictionary = {}
static var _climb_visual_stats: Dictionary = {}

static func run(tree: SceneTree, game: Node, check: Callable,
		observer: Callable = Callable(), cases: Array = []) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	var original_free: bool = game.free_skate_mode
	_observer = observer
	_game = game
	_step = 0
	_camera_hulls.clear()
	game.start_mode(true)
	if cases.is_empty() or cases.has("core"): await _core_navigation(tree, game, check)
	if cases.is_empty() or cases.has("setup"): await _native_setups(tree, game, check)
	if cases.is_empty() or cases.has("bail"): await _native_recovery(tree, game, check)
	if cases.is_empty() or cases.has("connected"): await _connected_world(tree, game, check)
	if cases.is_empty() or cases.has("wall"): await _wall_line(tree, game, check)
	if cases.is_empty() or cases.has("repertoire"): await _live_repertoire(tree, game, check)
	if cases.is_empty() or cases.has("selections"): await _all_grabs_and_grinds(tree, game, check)
	if cases.is_empty() or cases.has("gate"): await _service_gate(tree, game, check)
	if cases.is_empty() or cases.has("cone"): await _cone_cruise(tree, game, check)
	if cases.is_empty() or cases.has("skitch"): await _cart_skitch(tree, game, check)
	if cases.is_empty() or cases.has("laps"): await _park_laps(tree, game, check)
	if cases.is_empty() or cases.has("facility"): await _sunken_facility_journey(tree, game, check)
	if cases.is_empty() or cases.has("facility_skating"): await _sunken_facility_skating(tree, game, check)
	_release()
	_phase = ""
	_observer = Callable()
	_game = null
	game.skater.spawn_position = original_spawn
	game.start_mode(original_free)

static func _core_navigation(tree: SceneTree, game: Node, check: Callable) -> void:
	# Real ground launches, not the elevated repertoire eligibility fixtures.
	await _reset(tree, game, SAFE)
	_phase = "nollie_native_launch"
	var events: Array[String] = []
	var record := func(_label: String, _points: int): events.append(game.skater.last_trick_id)
	game.skater.trick_performed.connect(record)
	Input.action_press("ollie")
	await _frames(tree,28)
	Input.action_press("push")
	await _frames(tree,2)
	Input.action_release("ollie")
	await _frames(tree,1)
	check.call(game.skater.airborne and game.skater.takeoff_mode == "Nollie"
		and events == ["nollie"] and game.score.combo_trick_count == 1
		and game.score.combo_base == Catalog.base_points("nollie"),
		"authentic Main: a fresh north cue on charged ground release physically launches one Nollie")
	_release()
	await _land(tree,game,120)
	await _frames(tree,25)
	check.call(not game.skater.bail_active and game.skater.is_on_floor() and events == ["nollie"]
		and game.score.total_score == Catalog.base_points("nollie")
		and game.score.last_banked_tricks == ["Nollie"],
		"authentic Main: the native Nollie catches and lands with exactly its accepted once-only receipt")
	game.skater.trick_performed.disconnect(record)
	for action: String in ["spin_left","spin_right"]:
		await _reset(tree,game,SAFE)
		_phase = "rotation_native_" + action
		var evidence := {"ids":[],"labels":[],"landings":[],"bails":0,"speed_on_land":0.0}
		var on_entry := func(label: String,_points: int):
			evidence.ids.append(game.skater.last_trick_id)
			evidence.labels.append(label)
		var on_land := func(clean: bool):
			evidence.landings.append(clean)
			evidence.speed_on_land = game.skater.speed
		var on_bail := func(): evidence.bails += 1
		game.skater.trick_performed.connect(on_entry)
		game.skater.landed.connect(on_land)
		game.skater.bailed.connect(on_bail)
		Input.action_press("push")
		await _frames(tree,25)
		Input.action_release("push")
		Input.action_press("ollie")
		await _frames(tree,28)
		Input.action_release("ollie")
		await _frames(tree,1)
		var takeoff_heading: float = game.skater.rotation.y
		Input.action_press(action)
		await _frames(tree,26)
		Input.action_release(action)
		await _land(tree,game,120)
		await _frames(tree,25)
		var expected := "Frontside 180" if action == "spin_left" else "Backside 180"
		check.call(evidence.bails == 0 and evidence.landings == [true]
			and evidence.ids == ["ollie","spin_180"] and evidence.labels == ["Ollie",expected]
			and game.skater.stance == "SWITCH" and evidence.speed_on_land < -1.0
			and absf(absf(angle_difference(takeoff_heading,game.skater.rotation.y))-PI) < deg_to_rad(12),
			"authentic Main: actual %s input completes a clean physical 180 and preserves backwards travel"%action)
		check.call(game.score.total_score == Catalog.base_points("ollie") + Catalog.base_points("spin_180")
			and game.score.last_banked_tricks.size() == 1 and game.score.last_banked_tricks[0].contains(expected),
			"authentic Main: the completed %s adds rotation base to one launch entry and banks exactly once"%action)
		print("AUTHENTIC CORE SPIN %s ids=%s labels=%s stance=%s landed_speed=%.3f bank=%d"%[
			action,evidence.ids,evidence.labels,game.skater.stance,evidence.speed_on_land,game.score.total_score])
		game.skater.trick_performed.disconnect(on_entry)
		game.skater.landed.disconnect(on_land)
		game.skater.bailed.disconnect(on_bail)
	# Named gaps are production Main swept-world awards, not Skater trick
	# signals. Observe the actual published Central gap and its score identity.
	var gap: Dictionary = {}
	for definition: Dictionary in game.world.get_gap_definitions():
		if definition.id == "central_gap": gap = definition
	check.call(not gap.is_empty(),"authentic Main: the real Central platform gap is published for native crossing")
	if gap.is_empty(): return
	await _reset(tree,game,Vector3(-94,5.8,12))
	_phase = "named_gap_native_central"
	Input.action_press("push")
	for frame in 150:
		if game.skater.global_position.z <= 4.5: break
		await _frames(tree,1)
	check.call(game.skater.is_on_floor() and game.skater.speed > 6.0 and game.skater.global_position.z > 3.5,
		"authentic Main: real pushes reach the actual Central gap takeoff without a motion injection")
	Input.action_press("ollie")
	await _frames(tree,1)
	Input.action_release("ollie")
	await _frames(tree,1)
	Input.action_release("push")
	var air_crossing := false
	for frame in 150:
		air_crossing = air_crossing or (game.skater.airborne and game.score._repetitions.has("gap:"+str(gap.id)))
		await _frames(tree,1)
		if game.skater.is_on_floor() and not game.skater.airborne and game.skater.global_position.z < -6.0: break
	await _frames(tree,25)
	check.call(air_crossing and not game.skater.bail_active and game.skater.is_on_floor()
		and game.skater.global_position.z < -6.0 and game.score._repetitions.get("gap:"+str(gap.id),0) == 1
		and game.score.last_banked_tricks == ["Ollie",str(gap.name)]
		and game.score.total_score == (Catalog.base_points("ollie")+int(gap.points))*2,
		"authentic Main: a real airborne platform crossing earns the named gap and banks exactly two accepted entries")
	print("AUTHENTIC CORE GAP air=%s at=%s receipts=%s bank=%d"%[
		air_crossing,game.skater.global_position,game.score.last_banked_tricks,game.score.total_score])
	_release()
	_phase = ""

static func _native_setups(tree: SceneTree, game: Node, check: Callable) -> void:
	for id: String in ["boneless", "no_comply"]:
		await _reset(tree, game, SAFE)
		var events: Array[String] = []
		var record := func(_label: String, _points: int): events.append(game.skater.last_trick_id)
		game.skater.trick_performed.connect(record)
		_phase = "setup_" + id
		Input.action_press("brake")
		if id == "no_comply": Input.action_press("manual")
		Input.action_press("ollie")
		await _frames(tree, 2)
		Input.action_release("ollie")
		await _frames(tree, 1)
		check.call(game.skater.setup_active and game.skater.setup_id == id
			and not game.skater.airborne and game.skater.is_on_floor()
			and events.is_empty() and game.score.get_combo_value() == 0,
			"authentic Main: actual %s release enters supported preparation before launch or points" % id)
		var anchor: Vector3 = game.skater._setup.ground_point
		var normal: Vector3 = game.skater._setup.normal
		var prep_frames := 1
		var contact_samples := 0
		var sole_error := 0.0
		var rear_error := 0.0
		var palm_error := 0.0
		var finite := true
		var no_early_award := true
		var rig = game.skater._visual_rig
		while game.skater.setup_active and prep_frames < 25:
			no_early_award = no_early_award and events.is_empty() and not game.skater.airborne
			if game.skater.setup_phase >= 0.40:
				contact_samples += 1
				var foot: Node3D = rig._legs[0].foot
				sole_error = maxf(sole_error, foot.to_global(SOLE).distance_to(anchor))
				sole_error = maxf(sole_error, _sole_plane_error(foot, anchor, normal))
				var rear: Node3D = rig._legs[1].foot
				rear_error = maxf(rear_error, _griptape_distance(rear.to_global(SOLE), game.skater._board_visual))
				if id == "boneless" and game.skater.setup_phase >= 0.60:
					var hand: Node3D = rig._arms[1].hand
					var edge: Vector3 = game.skater._board_visual.to_global(
						Basis(Vector3.UP, -game.skater._deck_yaw) * Vector3(0.128, 0.022, 0.02))
					palm_error = maxf(palm_error, hand.to_global(PALM).distance_to(edge))
			finite = finite and _markers(game).all(func(point: Vector3): return point.is_finite())
			await _frames(tree, 1)
			prep_frames += 1
		check.call(contact_samples >= 4 and sole_error < 0.004 and rear_error < 0.004,
			"authentic Main: native %s preparation keeps the complete real sole on its ray plane and rear foot on deck" % id)
		if id == "boneless":
			check.call(palm_error < 0.025,
				"authentic Main: native Boneless palm reaches the moving visible board during actual preparation")
		check.call(finite and no_early_award and prep_frames >= (12 if id == "boneless" else 9)
			and game.skater.airborne and not game.skater.setup_active
			and events == [id] and game.score.combo_base == Catalog.base_points(id),
			"authentic Main: %s completes native preparation and awards exactly one actual launch" % id)
		Input.action_release("brake")
		Input.action_release("manual")
		await _land(tree, game, 100)
		await _frames(tree, 25)
		check.call(not game.skater.bail_active and game.skater.is_on_floor()
			and game.score.total_score == Catalog.base_points(id) and events == [id],
			"authentic Main: actual %s catches and lands, then banks exactly once" % id)
		print("AUTHENTIC SETUP %s frames=%d samples=%d sole=%.6f rear=%.6f palm=%.6f bank=%d" % [
			id, prep_frames, contact_samples, sole_error, rear_error, palm_error, game.score.total_score])
		game.skater.trick_performed.disconnect(record)
		_phase = ""
	await _moving_no_comply(tree, game, check)
	await _unsupported_plants(tree, game, check)
	await _accepted_revert_queue(tree, game, check)

static func _moving_no_comply(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, SAFE)
	_phase = "setup_moving_no_comply"
	var entries: Array[String] = []
	var on_entry := func(_label: String, _points: int): entries.append(game.skater.last_trick_id)
	game.skater.trick_performed.connect(on_entry)
	Input.action_press("push")
	await _frames(tree, 42)
	Input.action_press("ollie")
	await _frames(tree, 18)
	Input.action_release("push")
	Input.action_press("brake")
	Input.action_press("manual")
	await _frames(tree, 2)
	check.call(game.skater.crouching and game.skater.speed > 2.0 and not game.skater.manual_active
		and entries.is_empty() and game.score.get_combo_value() == 0,
		"authentic Main: moving No Comply charge uses its Manual modifier without awarding an unrelated ground manual")
	Input.action_release("ollie")
	await _frames(tree, 1)
	check.call(game.skater.setup_active and game.skater.setup_id == "no_comply" and entries.is_empty()
		and not game.skater.airborne and game.skater.is_on_floor(),
		"authentic Main: moving No Comply release enters a real supported sole plant before any points")
	for frame in 20:
		await _frames(tree, 1)
		if not game.skater.setup_active: break
	check.call(game.skater.airborne and entries == ["no_comply"]
		and game.score.combo_base == Catalog.base_points("no_comply") and not game.skater.manual_active,
		"authentic Main: moving planted setup launches exactly one No Comply and no buffered manual")
	Input.action_release("brake")
	await _land(tree, game, 140)
	await _frames(tree, 25)
	check.call(entries == ["no_comply"] and not game.skater.bail_active and not game.skater.manual_active
		and game.score.total_score == Catalog.base_points("no_comply"),
		"authentic Main: held moving setup modifier cannot add a phantom manual on landing or duplicate its bank")
	game.skater.trick_performed.disconnect(on_entry)
	_release()
	_phase = ""

static func _unsupported_plants(tree: SceneTree, game: Node, check: Callable) -> void:
	# A declared narrow raised platform supports the native capsule, while the
	# actual planted-foot ray lies beyond its edge and above the existing floor.
	var fixture := StaticBody3D.new()
	fixture.name = "DeclaredUnsupportedSolePlatform"
	fixture.position = Vector3(-22, 1, 28)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.25, 2, 2)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	fixture.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	fixture.add_child(mesh)
	game.world.add_child(fixture)
	await _reset(tree, game, Vector3(-22, 2.8, 28))
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	var ordinary_launch_velocity: float = game.skater.velocity.y
	for id: String in ["boneless", "no_comply"]:
		await _reset(tree, game, Vector3(-22, 2.8, 28))
		_phase = "unsupported_plant_" + id
		var foot: Vector3 = game.skater.global_transform * Vector3(-0.34, 0, -0.255)
		var ray := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * 0.45, foot - Vector3.UP * 0.35, game.skater.collision_mask)
		ray.exclude = [game.skater.get_rid()]
		var missing_sole: bool = game.skater.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
		var entries: Array[String] = []
		var on_entry := func(_label: String, _points: int): entries.append(game.skater.last_trick_id)
		game.skater.trick_performed.connect(on_entry)
		var supported: bool = game.skater.is_on_floor()
		Input.action_press("brake")
		if id == "no_comply": Input.action_press("manual")
		Input.action_press("ollie")
		await _frames(tree, 2)
		Input.action_release("ollie")
		await _frames(tree, 1)
		check.call(supported and missing_sole and game.skater.airborne and not game.skater.setup_active
			and entries == ["ollie"] and absf(game.skater.velocity.y - ordinary_launch_velocity) < 0.001,
			"authentic Main: unsupported %s sole honestly falls back to an ordinary unboosted Ollie" % id)
		Input.action_release("brake")
		Input.action_release("manual")
		await _land(tree, game, 110)
		await _frames(tree, 25)
		check.call(not game.skater.bail_active and entries == ["ollie"] and game.score.total_score == Catalog.base_points("ollie"),
			"authentic Main: missing %s plant cannot award planted-foot points on later landing" % id)
		game.skater.trick_performed.disconnect(on_entry)
	_release()
	_phase = ""
	fixture.queue_free()
	await tree.process_frame

static func _accepted_revert_queue(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, SAFE)
	_phase = "accepted_revert_manual_link"
	var entries: Array[String] = []
	var on_entry := func(_label: String, _points: int): entries.append(game.skater.last_trick_id)
	game.skater.trick_performed.connect(on_entry)
	Input.action_press("push")
	await _frames(tree, 55)
	Input.action_release("push")
	await _frames(tree, 13)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	await _land(tree, game, 100)
	Input.action_press("revert")
	await _frames(tree, 1)
	Input.action_release("revert")
	var heading: float = game.skater.rotation.y
	Input.action_press("manual")
	await _frames(tree, 3)
	check.call(game.skater.manual_active and game.skater.manual_trick_id == "manual" and entries == ["ollie", "revert", "manual"]
		and absf(angle_difference(heading, game.skater.rotation.y)) < 0.001 and game.skater.speed < -2.0,
		"authentic Main: a consumed ground Revert joins one ordinary manual without replaying as a second physical pivot")
	Input.action_release("manual")
	await _frames(tree, 30)
	var expected: int = (Catalog.base_points("ollie") + Catalog.base_points("revert") + Catalog.base_points("manual")) * 3
	check.call(game.score.total_score == expected and entries == ["ollie", "revert", "manual"] and not game.skater.bail_active,
		"authentic Main: native Ollie-Revert-manual earns exactly its three entries and banks once")
	game.skater.trick_performed.disconnect(on_entry)
	_release()
	_phase = ""

static func _native_recovery(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, SAFE)
	var evidence := {"bails": 0, "entries": []}
	var on_bail := func(): evidence.bails += 1
	var on_entry := func(_label: String, _points: int): evidence.entries.append(game.skater.last_trick_id)
	game.skater.bailed.connect(on_bail)
	game.skater.trick_performed.connect(on_entry)
	_phase = "bail_getup"
	Input.action_press("push")
	await _frames(tree, 42)
	Input.action_release("push")
	await _frames(tree, 13)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	for frame in 80:
		if game.skater.velocity.y < -6.0: break
		await _frames(tree, 1)
	Input.action_press("flip")
	var previous: Array[Vector3] = _markers(game)
	var max_step := 0.0
	var entry_position := Vector3.INF
	var head_min := INF
	var body_motion := 0.0
	var recovering_frames := 0
	var dropped_once := true
	for frame in 110:
		await _frames(tree, 1)
		var current: Array[Vector3] = _markers(game)
		if game.skater.bail_active:
			if not entry_position.is_finite(): entry_position = game.skater.global_position
			recovering_frames += 1
			body_motion = maxf(body_motion, game.skater.global_position.distance_to(entry_position))
			head_min = minf(head_min, current[0].y)
			dropped_once = dropped_once and evidence.bails == 1 and game.score.get_combo_value() == 0
			for index in current.size(): max_step = maxf(max_step, current[index].distance_to(previous[index]))
		previous = current
		if recovering_frames > 0 and not game.skater.bail_active: break
	check.call(evidence.bails == 1 and recovering_frames >= 60 and dropped_once,
		"authentic Main: a genuinely unfinished landing loses score immediately once while visible recovery continues")
	check.call(entry_position.is_finite() and entry_position.distance_to(game.skater.spawn_position) > 1.0
		and body_motion > 0.05 and max_step < 0.24,
		"authentic Main: bail keeps native local motion and continuous body markers instead of instantly teleporting")
	check.call(head_min < entry_position.y + 1.0 and head_min > -0.03
		and not game.skater.bail_active and game.skater.global_position.distance_to(entry_position) < 3.0,
		"authentic Main: the visible rider falls towards real ground and gets up at a supported local recovery")
	await _frames(tree, 15)
	check.call(evidence.bails == 1 and evidence.entries == ["ollie", "kickflip"]
		and game.score.get_combo_value() == 0 and game.score.total_score == 0,
		"authentic Main: holding the failed flip through get-up cannot create another entry or duplicate the bail")
	print("AUTHENTIC BAIL frames=%d motion=%.4f max_marker_step=%.4f head_min=%.4f entries=%s" % [
		recovering_frames, body_motion, max_step, head_min, evidence.entries])
	game.skater.bailed.disconnect(on_bail)
	game.skater.trick_performed.disconnect(on_entry)
	_release()
	_phase = ""
	await _interrupted_tumble(tree, game, check)
	await _high_wall_bail(tree, game, check)
	await _results_recovery(tree, game, check)
	await _recovery_clearance(tree, game, check)
	await _recovery_floor_seam(tree, game, check)
	await _sloped_recovery_first_frame(tree, game, check)

static func _sloped_recovery_first_frame(tree: SceneTree, game: Node, check: Callable) -> void:
	for degrees: float in [20.0, 35.0, 45.0]:
		var slope := tan(deg_to_rad(degrees))
		var origin := Vector3(-22, 12, 28)
		var support := StaticBody3D.new()
		support.name = "DeclaredSlopedRecoveryBank" + str(int(degrees))
		support.position = origin
		var a := Vector3(-4, -4 * slope, -10)
		var b := Vector3(-4, -4 * slope, 10)
		var c := Vector3(4, 4 * slope, 10)
		var d := Vector3(4, 4 * slope, -10)
		var faces := PackedVector3Array([a, c, b, a, d, c])
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		support.add_child(collision)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for vertex: Vector3 in faces: surface.add_vertex(vertex)
		surface.generate_normals()
		var mesh := MeshInstance3D.new()
		mesh.mesh = surface.commit()
		support.add_child(mesh)
		game.world.add_child(support)
		await _reset(tree, game, origin + Vector3.UP * 0.8)
		_phase = "bail_native_bank_" + str(int(degrees))
		Input.action_press("push")
		await _frames(tree, 35)
		Input.action_release("push")
		await _frames(tree, 13)
		var evidence := {"bails": 0, "entries": []}
		var on_bail := func(): evidence.bails += 1
		var on_entry := func(_label: String, _points: int): evidence.entries.append(game.skater.last_trick_id)
		game.skater.bailed.connect(on_bail)
		game.skater.trick_performed.connect(on_entry)
		Input.action_press("manual")
		await _frames(tree, 1)
		check.call(game.skater.manual_active and game.skater.is_on_floor() and game.score.get_combo_value() == 100
			and game.skater.get_floor_normal().dot(Vector3.UP) > 0.70,
			"authentic Main: genuine push and Manual earn one supported entry on the %.0f-degree native bank" % degrees)
		Input.action_press("brake")
		var previous: Array[Vector3] = _markers(game)
		var active_max := 0.0
		var recovered_max := -1.0
		var seen := false
		var finite := true
		for frame in 220:
			var was_bail: bool = game.skater.bail_active
			await _frames(tree, 1)
			var current: Array[Vector3] = _markers(game)
			var step := _marker_distance(previous, current)
			finite = finite and current.all(func(point: Vector3): return point.is_finite())
			if game.skater.bail_active:
				active_max = maxf(active_max, step)
				if not seen:
					Input.action_release("brake")
					Input.action_release("manual")
				seen = true
			if was_bail and not game.skater.bail_active:
				recovered_max = step
				previous = current
				for after in 5:
					await _frames(tree, 1)
					current = _markers(game)
					recovered_max = maxf(recovered_max, _marker_distance(previous, current))
					finite = finite and current.all(func(point: Vector3): return point.is_finite())
					previous = current
				break
			previous = current
		check.call(seen and evidence.bails == 1 and not game.skater.bail_active and game.skater.is_on_floor()
			and game.score.get_combo_value() == 0 and game.score.total_score == 0 and evidence.entries == ["manual"],
			"authentic Main: actual %.0f-degree manual imbalance drops its real combo once and gets up on native support" % degrees)
		check.call(finite and active_max < 0.24 and recovered_max >= 0.0 and recovered_max < 0.24,
			"authentic Main: %.0f-degree recovery stays continuous through the first ordinary frame and five following frames" % degrees)
		print("AUTHENTIC SLOPED RECOVERY degrees=%.0f active_step=%.5f first_recovered_step=%.5f bails=%d" % [
			degrees, active_max, recovered_max, evidence.bails])
		game.skater.bailed.disconnect(on_bail)
		game.skater.trick_performed.disconnect(on_entry)
		_release()
		_phase = ""
		support.queue_free()
		await tree.process_frame

static func _recovery_floor_seam(tree: SceneTree, game: Node, check: Callable) -> void:
	# Two real twenty-degree native floors meet in a valley. The production
	# capsule contacts both, although their normals differ by forty degrees.
	var fixture := Node3D.new()
	fixture.name = "DeclaredTwoFloorRecoverySeam"
	fixture.position = Vector3(-22, 2, 28)
	game.world.add_child(fixture)
	for side: float in [-1.0, 1.0]:
		var x := 2.0 * side
		var height := absf(x) * tan(deg_to_rad(20.0))
		var a := Vector3(minf(x, 0), height if side < 0 else 0, -3)
		var b := Vector3(minf(x, 0), height if side < 0 else 0, 3)
		var c := Vector3(maxf(x, 0), height if side > 0 else 0, 3)
		var d := Vector3(maxf(x, 0), height if side > 0 else 0, -3)
		var faces := PackedVector3Array([a, c, b, a, d, c])
		var body := StaticBody3D.new()
		body.name = "NativeFloorFacet" + str(side)
		var collision := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		collision.shape = shape
		body.add_child(collision)
		var visual := MeshInstance3D.new()
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for vertex: Vector3 in faces: surface.add_vertex(vertex)
		surface.generate_normals()
		visual.mesh = surface.commit()
		body.add_child(visual)
		fixture.add_child(body)
	await _reset(tree, game, Vector3(-22, 3, 28))
	_phase = "bail_floor_seam"
	var contact := KinematicCollision3D.new()
	var hit: bool = game.skater.test_move(game.skater.global_transform, Vector3.ZERO, contact, 0.001, true, 16)
	var distinct := false
	var only_floors := true
	var normals: Array[Vector3] = []
	for index in contact.get_collision_count():
		var normal := contact.get_normal(index)
		normals.append(normal)
		distinct = distinct or normal.dot(game.skater.get_floor_normal()) < 0.98
		only_floors = only_floors and normal.dot(game.skater.up_direction) >= cos(game.skater.floor_max_angle)
	check.call(game.skater.is_on_floor() and hit and normals.size() >= 2 and distinct and only_floors
		and game.skater._bail._can_get_up(game.skater),
		"authentic Main: distinct actual traversable floor facets allow standing without accepting walls or ceilings")
	var evidence := {"bails": 0}
	var on_bail := func(): evidence.bails += 1
	game.skater.bailed.connect(on_bail)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	for frame in 80:
		if game.skater.velocity.y < -6.0: break
		await _frames(tree, 1)
	Input.action_press("flip")
	var impact := Vector3.INF
	var last: Vector3 = game.skater.global_position
	var greatest_step := 0.0
	for frame in 130:
		await _frames(tree, 1)
		if game.skater.bail_active:
			if not impact.is_finite(): impact = game.skater.global_position
			greatest_step = maxf(greatest_step, last.distance_to(game.skater.global_position))
		elif impact.is_finite():
			greatest_step = maxf(greatest_step, last.distance_to(game.skater.global_position))
			break
		last = game.skater.global_position
	check.call(evidence.bails == 1 and impact.is_finite() and not game.skater.bail_active and game.skater.is_on_floor()
		and game.skater.global_position.distance_to(impact) < 0.1 and greatest_step < 0.12,
		"authentic Main: a genuine late-flip bail gets up continuously at a real two-floor seam instead of returning to spawn")
	check.call(game.score.total_score == 0 and game.score.get_combo_value() == 0 and evidence.bails == 1,
		"authentic Main: seam recovery still drops the actual unfinished combo exactly once")
	print("AUTHENTIC FLOOR SEAM normals=%s depth=%.7f max_body_step=%.5f" % [normals, contact.get_depth(), greatest_step])
	game.skater.bailed.disconnect(on_bail)
	_release()
	_phase = ""
	fixture.queue_free()
	await tree.process_frame

static func _recovery_clearance(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, SAFE)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	for frame in 80:
		if game.skater.velocity.y < -6.0: break
		await _frames(tree, 1)
	Input.action_press("flip")
	for frame in 30:
		await _frames(tree, 1)
		if game.skater.bail_active and game.skater.is_on_floor(): break
	_release()
	game.toggle_pause()
	var at: Vector3 = game.skater.global_position
	check.call(game.skater.bail_active and game.skater.is_on_floor() and game.skater._bail._can_get_up(game.skater),
		"authentic Main: actual native floor support permits standing during a genuine paused recovery")
	for item: Array in [
		["DiagnosticSideWall", Vector3(0.35, 0.85, 0), Vector3(0.3, 1.7, 2)],
		["DiagnosticLowCeiling", Vector3(0, 1.42, 0), Vector3(2, 0.25, 2)],
	]:
		var body := StaticBody3D.new()
		body.name = item[0]
		body.position = at + Vector3(item[1])
		var shape := BoxShape3D.new()
		shape.size = item[2]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		game.world.add_child(body)
		await _frames(tree, 2)
		var native := PhysicsShapeQueryParameters3D.new()
		var body_shape: CollisionShape3D = game.skater.get_node("BodyCollision")
		native.shape = body_shape.shape
		native.transform = body_shape.global_transform
		native.collision_mask = game.skater.collision_mask
		native.exclude = [game.skater.get_rid()]
		var observed := false
		for hit: Dictionary in game.skater.get_world_3d().direct_space_state.intersect_shape(native, 8):
			observed = observed or hit.collider == body
		check.call(observed and not game.skater._bail._can_get_up(game.skater)
			and game.skater.global_position.distance_to(at) < 0.00001,
			"authentic Main: real %s blocks the actual standing capsule without being mistaken for support" % item[0])
		body.queue_free()
		await _frames(tree, 2)
	check.call(game.skater._bail._can_get_up(game.skater),
		"authentic Main: removing diagnostic obstructions restores clear supported get-up")
	game.toggle_pause()
	for frame in 100:
		await _frames(tree, 1)
		if not game.skater.bail_active: break
	check.call(not game.skater.bail_active and game.skater.is_on_floor() and game.skater.global_position.distance_to(at) < 0.1,
		"authentic Main: unobstructed recovery resumes native get-up at its real supported position")

static func _high_wall_bail(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, SAFE)
	# Declared native diagnostic geometry: a tall wall and a perpendicular
	# obstacle above the existing floor. Actual wallride collision triggers bail.
	var fixture := Node3D.new()
	fixture.name = "DeclaredHighWallBailFixture"
	game.world.add_child(fixture)
	for item: Array in [
		["TallDiagnosticWall", Vector3(-22.8, 10, 25), Vector3(0.4, 20, 20)],
		["HighWallObstruction", Vector3(-22, 12, 26.2), Vector3(3, 3, 0.3)],
	]:
		var body := StaticBody3D.new()
		body.name = item[0]
		body.position = item[1]
		body.set_meta("wallrideable", true)
		var shape := BoxShape3D.new()
		shape.size = item[2]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = item[2]
		visual.mesh = mesh
		body.add_child(visual)
		fixture.add_child(body)
	game.skater.set_physics_process(false)
	game.skater.global_position = Vector3(-22.1, 12, 28)
	game.skater.velocity = Vector3(0, -1, -6)
	game.skater.speed = 6.0
	game.skater.airborne = true
	game.skater.set_physics_process(true)
	var evidence := {"bails": 0}
	var on_bail := func(): evidence.bails += 1
	game.skater.bailed.connect(on_bail)
	_phase = "high_wall_bail"
	Input.action_press("grind")
	var entered := false
	for frame in 40:
		await _frames(tree, 1)
		entered = entered or game.skater.wallriding
		if game.skater.bail_active: break
	check.call(entered and game.skater.bail_active and evidence.bails == 1 and game.skater.global_position.y > 9.0,
		"authentic Main: a real high-wall obstruction starts one airborne native bail")
	var airborne_frames := 0
	var no_air_getup := true
	var touched := false
	for frame in 180:
		await _frames(tree, 1)
		if game.skater.bail_active and not game.skater.is_on_floor():
			airborne_frames += 1
			no_air_getup = no_air_getup and game.skater.bail_phase <= 0.45001
		if game.skater.is_on_floor(): touched = true
		if not game.skater.bail_active: break
	check.call(airborne_frames > 40 and no_air_getup and touched and not game.skater.bail_active
		and game.skater.is_on_floor() and evidence.bails == 1,
		"authentic Main: long native fall holds its falling pose until real ground contact before completing get-up")
	print("AUTHENTIC HIGH BAIL air_frames=%d no_air_getup=%s touched=%s" % [airborne_frames, no_air_getup, touched])
	game.skater.bailed.disconnect(on_bail)
	_release()
	_phase = ""
	fixture.queue_free()
	await tree.process_frame

static func _results_recovery(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, SAFE)
	game.start_mode(false)
	await _frames(tree, 40)
	_phase = "results_recovery_fade"
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	for frame in 80:
		await _frames(tree, 1)
		if game.skater.velocity.y < -6.0: break
	Input.action_press("flip")
	await _frames(tree, 1)
	game.time_remaining = 0.01
	for frame in 150:
		await _frames(tree, 1)
		if game.run_finished and not game.skater.bail_active: break
	await _frames(tree, 20)
	check.call(game.run_finished and not game.skater.bail_active and game.score.total_score == 0
		and game.skater.recovery_fade < 0.001 and not game.hud._recovery_layer.visible,
		"authentic Main: a run ending during real recovery still clears its fade after native get-up with controls disabled")
	_release()
	game.start_mode(true)
	_phase = ""

static func _interrupted_tumble(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, SAFE)
	var completed: Array = game.career.completed_ids.duplicate()
	for id: String in ["first_shift", "one_long_line"]:
		if not game.career.completed_ids.has(id): game.career.completed_ids.append(id)
	game.special_meter.earn_trick(500)
	game.special_meter.earn_trick(500)
	var evidence := {"bails": 0}
	var on_bail := func(): evidence.bails += 1
	game.skater.bailed.connect(on_bail)
	_phase = "interrupted_tumble_recovery"
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	for frame in 80:
		await _frames(tree, 1)
		if game.skater.velocity.y < -5.5: break
	_key(KEY_I, true)
	await _frames(tree, 1)
	check.call(game.skater.special_name == "Tenement Tumble",
		"authentic Main: a real late Tumble begins before its unfinished landing")
	var previous: Array[Vector3] = _markers(game)
	var entry_step := 0.0
	for frame in 25:
		await _frames(tree, 1)
		var now: Array[Vector3] = _markers(game)
		for index in now.size(): entry_step = maxf(entry_step, now[index].distance_to(previous[index]))
		previous = now
		if game.skater.bail_active: break
	check.call(evidence.bails == 1 and game.skater.bail_active and entry_step < 0.35
		and game.score.get_combo_value() == 0,
		"authentic Main: interrupted Tumble preserves actual world pose into one continuous score-losing bail")
	await _frames(tree, 10)
	game.toggle_pause()
	var phase: float = game.skater.bail_phase
	var paused: Array[Vector3] = _markers(game)
	await _frames(tree, 8)
	check.call(game.skater.bail_phase == phase and _marker_distance(paused, _markers(game)) < 0.00001,
		"authentic Main: production pause freezes native recovery and every visible limb marker")
	game.toggle_pause()
	for frame in 90:
		await _frames(tree, 1)
		if not game.skater.bail_active: break
	await _frames(tree, 15)
	check.call(evidence.bails == 1 and not game.skater.bail_active and game.score.get_combo_value() == 0
		and game.special_meter.value == 0.0 and game.skater.is_on_floor(),
		"authentic Main: Tumble get-up finishes on real support with no held-special resurrection")
	print("AUTHENTIC TUMBLE entry_max_step=%.5f bails=%d" % [entry_step, evidence.bails])
	_key(KEY_I, false)
	game.skater.bailed.disconnect(on_bail)
	game.career.completed_ids.assign(completed)
	_release()
	_phase = ""

static func _connected_world(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, Vector3(145, 2.8, 66), PI / 2.0)
	_phase = "bowl_world_approach"
	Input.action_press("push")
	var entered := false
	for frame in 400:
		await _frames(tree, 1)
		if game.skater.transition_active and game.skater._transition.feature.name == "ClydeEastBowl":
			entered = true
			break
		if game.skater.bail_active: break
	check.call(entered and not game.skater.bail_active and game.skater.global_position.x < 128.0,
		"authentic Main: an ordinary outside approach rides the real world roll-in and enters the bowl without fixture motion")
	# The circular carve uses one explicit initial contact/momentum fixture, as
	# a native bowl has no controller pumping assist. There are no later snaps.
	await _reset(tree, game, SAFE)
	var bowl: Node3D = game.world.get_node("ClydeEastBowl")
	var sample: Dictionary = bowl.sample(0.6, 0.0)
	var around_speed := sqrt(22.0 * (bowl.floor_radius + bowl.radius * sin(0.6)) * tan(0.6))
	game.skater.set_physics_process(false)
	game.skater.spawn_position = sample.point + sample.normal * 0.022
	game.skater.reset_skater()
	game.skater.velocity = sample.lateral * around_speed
	game.skater.speed = around_speed
	game.skater.airborne = false
	game.skater.rotation.y = atan2(-game.skater.velocity.x, -game.skater.velocity.z)
	game.skater.set_physics_process(true)
	_phase = "bowl_native_lap"
	var previous := atan2(bowl.to_local(game.skater.global_position).x, -bowl.to_local(game.skater.global_position).z)
	var sweep := 0.0
	var supported := true
	var finite_camera := true
	var native_distance := 0.0
	for frame in 300:
		var before: Vector3 = game.skater.global_position
		await _frames(tree, 1)
		var local: Vector3 = bowl.to_local(game.skater.global_position)
		var phi := atan2(local.x, -local.z)
		sweep += angle_difference(previous, phi)
		previous = phi
		native_distance += before.distance_to(game.skater.global_position)
		supported = supported and not game.skater.bail_active and game.skater.transition_active
		finite_camera = finite_camera and game.skater._camera.global_position.is_finite()
		if absf(sweep) >= TAU: break
	check.call(supported and absf(sweep) >= TAU and native_distance > 25.0 and finite_camera,
		"authentic Main: the production player actually circles the connected bowl with native support and a finite chase camera")
	print("AUTHENTIC BOWL sweep=%.4f distance=%.3f supported=%s" % [sweep, native_distance, supported])

	var halfpipe: Node3D = game.world.get_node("StationConcourseHalfpipe")
	await _reset(tree, game, halfpipe.global_position + Vector3(2.4, 0.8, 0), PI / 2.0)
	_phase = "halfpipe_connected_return"
	Input.action_press("push")
	var walls: Dictionary = {}
	for frame in 460:
		await _frames(tree, 1)
		if game.skater.transition_active:
			walls[str(game.skater._transition.feature.name)] = true
		if walls.size() >= 2: break
	check.call(walls.has("NorthTransition") and walls.has("SouthTransition") and not game.skater.bail_active,
		"authentic Main: a real push-driven halfpipe line crosses its flat bottom and reaches both connected walls")
	print("AUTHENTIC HALFPIPE walls=%s position=%s" % [walls.keys(), game.skater.global_position])

	var spine: Node3D = game.world.get_node("StationWestSpine")
	var spine_definition: Dictionary = spine.get_feature_definitions()[0]
	var approach: PackedVector3Array = spine_definition.approach
	var direction: Vector3 = approach[1] - approach[0]
	await _reset(tree, game, approach[0] + Vector3.UP * 0.8, atan2(-direction.x, -direction.z))
	_phase = "spine_native_transfer"
	Input.action_press("push")
	var departed := false
	for frame in 180:
		await _frames(tree, 1)
		if game.skater.airborne and game.skater.transition_active:
			departed = true
			break
	Input.action_release("push")
	await _frames(tree, 1)
	Input.action_press("push")
	await _frames(tree, 8)
	Input.action_release("push")
	var arrived := false
	var spine_states: Dictionary = {}
	for frame in 150:
		await _frames(tree, 1)
		if game.skater.transition_active:
			var key := "%s/%s/air=%s" % [game.skater._transition.feature.name, game.skater._transition.state, game.skater.airborne]
			if not spine_states.has(key): spine_states[key] = game.skater.global_position
		if game.skater.transition_active and game.skater._transition.feature.name == "BackTransition" \
				and not game.skater.airborne:
			arrived = true
			break
		if game.skater.bail_active: break
	check.call(departed and arrived and not game.skater.bail_active and game.skater.global_position.z < spine.global_position.z,
		"authentic Main: a fresh airborne transfer crosses the real spine and lands on its opposite connected face")
	print("AUTHENTIC SPINE departed=%s arrived=%s position=%s states=%s" % [departed, arrived, game.skater.global_position, spine_states])
	_release()
	_phase = ""

static func _live_repertoire(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, SAFE)
	_phase = "triple_flip_one_entry"
	Input.action_press("ollie")
	await _frames(tree, 36)
	Input.action_release("ollie")
	await _frames(tree, 1)
	for tap in 3:
		Input.action_press("flip")
		await _frames(tree, 2)
		Input.action_release("flip")
		await _frames(tree, 2)
	check.call(game.skater.flip_trick_id == "triple_kickflip" and game.score.combo_trick_count == 2,
		"authentic Main: three real taps upgrade one physical flip to a triple without multiplying its entry")
	await _land(tree, game, 110)
	await _frames(tree, 25)
	check.call(game.score.total_score == (100 + Catalog.base_points("triple_kickflip")) * 2
		and not game.skater.bail_active,
		"authentic Main: the genuine charged triple catches, lands and banks its exact single-upgrade receipt")
	_phase = ""

static func _wall_line(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, Vector3(117, 2.3, -38.2), -PI / 2.0)
	_phase = "wallride_wallie_combo"
	var evidence := {"entries": [], "points": [], "holds": 0, "bails": 0}
	var on_trick := func(_label: String, points: int):
		evidence.entries.append(game.skater.last_trick_id)
		evidence.points.append(points)
	var on_hold := func(points: int): evidence.holds += points
	var on_bail := func(): evidence.bails += 1
	game.skater.trick_performed.connect(on_trick)
	game.skater.hold_points_awarded.connect(on_hold)
	game.skater.bailed.connect(on_bail)
	Input.action_press("push")
	await _frames(tree, 30)
	Input.action_release("push")
	await _frames(tree, 13)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("grind")
	await _frames(tree, 5)
	check.call(game.skater.wallriding and evidence.entries == ["ollie", "wallride"],
		"authentic Main: actual architectural contact admits one genuine wallride in the live combo")
	await _frames(tree, 3)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_release("grind")
	check.call(game.skater.airborne and not game.skater.wallriding and game.skater.velocity.z > 3.0
		and evidence.entries == ["ollie", "wallride", "wallie"],
		"authentic Main: release-pop wallie creates outward native momentum without banking its wall line")
	Input.action_press("flip")
	Input.action_press("grab")
	await _frames(tree, 2)
	Input.action_release("flip")
	Input.action_release("grab")
	await _land(tree, game, 150)
	await _frames(tree, 30)
	var base: int = evidence.holds
	var definitions_match := true
	for index in evidence.entries.size():
		var expected: int = Catalog.base_points(str(evidence.entries[index]))
		definitions_match = definitions_match and int(evidence.points[index]) == expected
		base += expected
	var bank: int = game.score.total_score
	await _frames(tree, 25)
	check.call(definitions_match and evidence.entries == ["ollie", "wallride", "wallie", "kickflip", "melon_grab"]
		and evidence.bails == 0 and bank == base * 5 and game.score.total_score == bank,
		"authentic Main: wallie-to-flip-to-grab catches and physically lands, banking its independently earned five-entry line once")
	print("AUTHENTIC WALL entries=%s bank=%d holds=%d bails=%d" % [evidence.entries, bank, evidence.holds, evidence.bails])
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.hold_points_awarded.disconnect(on_hold)
	game.skater.bailed.disconnect(on_bail)
	_release()
	_phase = ""

static func _all_grabs_and_grinds(tree: SceneTree, game: Node, check: Callable) -> void:
	var seen_grabs: Array[String] = []
	for direction: String in Catalog.DIRECTIONS:
		var entry: Dictionary = Catalog.resolve("grab", direction)
		if seen_grabs.has(entry.id): continue
		seen_grabs.append(entry.id)
		await _reset(tree, game, SAFE)
		_phase = "grab_native_" + str(entry.id)
		var evidence := {"ids": [], "holds": 0, "bails": 0}
		var on_entry := func(_label: String, _points: int): evidence.ids.append(game.skater.last_trick_id)
		var on_hold := func(points: int): evidence.holds += points
		var on_bail := func(): evidence.bails += 1
		game.skater.trick_performed.connect(on_entry)
		game.skater.hold_points_awarded.connect(on_hold)
		game.skater.bailed.connect(on_bail)
		Input.action_press("ollie")
		await _frames(tree, 2)
		Input.action_release("ollie")
		await _frames(tree, 1)
		_set_direction(direction)
		Input.action_press("grab")
		await _frames(tree, 2)
		_set_direction("neutral")
		await _frames(tree, 16)
		var hand_index := 0 if float(entry.grab_side) < 0.0 else 1
		var hand: Node3D = game.skater._visual_rig._arms[hand_index].hand
		var board: Node3D = game.skater._board_visual
		var target: Vector3 = board.to_global(Basis(Vector3.UP, -board.rotation.y) * Vector3(entry.grab_target))
		var palm_error := hand.to_global(PALM).distance_to(target)
		var surface_error := _griptape_distance(hand.to_global(PALM), board)
		var surface_limit := 0.004 if entry.id in ["nose_grab", "tail_grab"] else 0.025
		check.call(game.skater.grab_trick_id == entry.id and evidence.ids == ["ollie", entry.id]
			and game.score.combo_trick_count == 2 and palm_error < 0.025 and surface_error < surface_limit,
			"authentic Main: actual %s input selects %s and its real palm reaches the visible board" % [direction, entry.id])
		Input.action_release("grab")
		await _land(tree, game, 110)
		await _frames(tree, 25)
		var expected: int = (Catalog.base_points("ollie") + int(entry.base_points) + int(evidence.holds)) * 2
		check.call(evidence.bails == 0 and game.score.total_score == expected and evidence.ids == ["ollie", entry.id],
			"authentic Main: native %s takeoff, grip, catch and landing bank only their two earned entries" % entry.id)
		print("AUTHENTIC GRAB %s palm=%.6f actual_griptape=%.6f bank=%d" % [entry.id, palm_error, surface_error, game.score.total_score])
		game.skater.trick_performed.disconnect(on_entry)
		game.skater.hold_points_awarded.disconnect(on_hold)
		game.skater.bailed.disconnect(on_bail)
	check.call(seen_grabs.size() == Catalog.family_ids("grab").size(),
		"authentic Main: every catalog grab has an actual ordinary-input native execution and landing")
	var seen_grinds: Array[String] = []
	for direction: String in Catalog.DIRECTIONS:
		var entry: Dictionary = Catalog.resolve("grind", direction)
		await _reset(tree, game, SAFE)
		# Declared descending native rail fixture; this assigns no trick, capture,
		# score or input state. Production collision and actions own everything next.
		game.skater.set_physics_process(false)
		game.skater.global_position = Vector3(12.15, 1.10, 11.5)
		game.skater.velocity = Vector3.ZERO
		game.skater.move_and_slide()
		game.skater.velocity = Vector3(0, -1, -6)
		game.skater.speed = 6.0
		game.skater.airborne = true
		game.skater.rotation.y = 0.0
		game.skater.set_physics_process(true)
		_phase = "grind_native_" + str(entry.id)
		var evidence := {"captures": [], "ids": [], "holds": 0, "bails": 0}
		var on_capture := func(id: String): evidence.captures.append(id)
		var on_entry := func(_label: String, _points: int): evidence.ids.append(game.skater.last_trick_id)
		var on_hold := func(points: int): evidence.holds += points
		var on_bail := func(): evidence.bails += 1
		game.skater.grind_captured.connect(on_capture)
		game.skater.trick_performed.connect(on_entry)
		game.skater.hold_points_awarded.connect(on_hold)
		game.skater.bailed.connect(on_bail)
		_set_direction(direction)
		Input.action_press("grind")
		await _frames(tree, 3)
		_set_direction("neutral")
		await _frames(tree, 8)
		check.call(game.skater.grinding and game.skater.grind_trick_id == entry.id
			and evidence.captures.size() == 1 and evidence.ids == [entry.id]
			and game.score.combo_trick_count == 1,
			"authentic Main: native rail contact with %s selects exactly one real %s capture" % [direction, entry.id])
		Input.action_release("grind")
		await _land(tree, game, 100)
		await _frames(tree, 25)
		check.call(evidence.bails == 0 and evidence.captures.size() == 1 and evidence.ids == [entry.id]
			and game.score.total_score == int(entry.base_points) + int(evidence.holds),
			"authentic Main: actual %s releases, lands and banks its single native capture once" % entry.id)
		if not seen_grinds.has(entry.id): seen_grinds.append(entry.id)
		game.skater.grind_captured.disconnect(on_capture)
		game.skater.trick_performed.disconnect(on_entry)
		game.skater.hold_points_awarded.disconnect(on_hold)
		game.skater.bailed.disconnect(on_bail)
	check.call(seen_grinds.size() + 1 == Catalog.family_ids("grind").size(),
		"authentic Main: every directional grind style is physically played; the separately tested Revert pivot completes its family")
	for direction: String in ["neutral", "north"]:
		var entry: Dictionary = Catalog.resolve("manual", direction)
		await _reset(tree, game, SAFE)
		_phase = "manual_native_" + str(entry.id)
		Input.action_press("push")
		await _frames(tree, 50)
		Input.action_release("push")
		await _frames(tree, 13)
		_set_direction(direction)
		Input.action_press("manual")
		await _frames(tree, 3)
		_set_direction("neutral")
		await _frames(tree, 8)
		check.call(game.skater.manual_active and game.skater.manual_trick_id == entry.id
			and game.score.combo_trick_count == 1 and game.score.combo_base == int(entry.base_points),
			"authentic Main: actual supported %s manual input enters its real board balance with one entry" % direction)
		Input.action_release("manual")
		await _frames(tree, 30)
		check.call(not game.skater.manual_active and not game.skater.bail_active
			and game.score.total_score == int(entry.base_points) and game.score.get_combo_value() == 0,
			"authentic Main: real %s release banks exactly its single native manual entry" % entry.id)
	_release()
	_phase = ""

static func _set_direction(direction: String) -> void:
	for action: String in ["push", "brake", "steer_left", "steer_right"]: Input.action_release(action)
	if direction.contains("north"): Input.action_press("push")
	if direction.contains("south"): Input.action_press("brake")
	if direction.contains("east"): Input.action_press("steer_right")
	if direction.contains("west"): Input.action_press("steer_left")

static func _service_gate(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, Vector3(-48.5, 2.8, -5), PI)
	_phase = "service_gate_route"
	var gate: Node3D = game.feature_hub.gate
	Input.action_press("push")
	await _frames(tree, 55)
	Input.action_release("push")
	check.call(game.skater.global_position.z < -2.35 and not gate.status_snapshot().open
		and not game.skater.bail_active and game.score.get_combo_value() == 0,
		"authentic Main: the closed service shortcut actually blocks native player motion without trick awards")
	await _interact(tree)
	await _frames(tree, 16)
	var moving: float = gate.status_snapshot().progress
	game.toggle_pause()
	await _frames(tree, 8)
	check.call(moving > 0.0 and moving < 1.0 and gate.status_snapshot().progress == moving,
		"authentic Main: real gate interaction begins opening and production pause freezes its native panel")
	game.toggle_pause()
	await _frames(tree, 80)
	check.call(gate.status_snapshot().open and game.feature_hub.get_route_definitions()[0].enabled,
		"authentic Main: completed gate movement enables its matching real map shortcut")
	Input.action_press("push")
	for frame in 100:
		await _frames(tree, 1)
		if game.skater.global_position.z >= -0.1: break
	Input.action_release("push")
	Input.action_press("brake")
	await _frames(tree, 18)
	Input.action_release("brake")
	check.call(game.skater.global_position.z > -0.2 and game.skater.is_on_floor() and not game.skater.bail_active,
		"authentic Main: the player physically crosses the open doorway on its retained supporting route")
	await _interact(tree)
	await _frames(tree, 90)
	check.call(not gate.status_snapshot().open and not game.feature_hub.get_route_definitions()[0].enabled
		and game.score.total_score == 0 and game.score.get_combo_value() == 0,
		"authentic Main: fresh interaction reverses the shortcut and cannot manufacture score")
	_release()

static func _cone_cruise(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, Vector3(-5, 2.8, 66), PI)
	_phase = "cone_cruise_native"
	var cone: Node3D = game.feature_hub.cone_stunt
	await _interact(tree)
	check.call(cone.status_snapshot().state == "active" and cone.status_snapshot().attempts == 1,
		"authentic Main: real steward interaction starts exactly one cone-cruise attempt")
	Input.action_press("push")
	for frame in 70:
		await _frames(tree, 1)
		if game.skater.speed >= 6.5: break
	Input.action_press("push", 0.06)
	for frame in 40:
		await _frames(tree, 1)
		if game.skater.global_position.z >= 68.9: break
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_release("push")
	for frame in 30:
		await _frames(tree, 1)
		if game.skater.global_position.z >= 70.85: break
	await _interact(tree)
	check.call(game.skater.airborne and cone.status_snapshot().launched
		and not cone.cone.freeze and cone.cone.linear_velocity.length() > 6.0,
		"authentic Main: actual airborne approach launches the real moving cone through normal interaction")
	Input.action_press("brake")
	for frame in 160:
		await _frames(tree, 1)
		if cone.status_snapshot().state in ["success", "failed"]: break
	Input.action_release("brake")
	var outcome: Dictionary = cone.status_snapshot()
	check.call(outcome.target_hit and outcome.raft_landed and outcome.landed and outcome.banked
		and outcome.state == "success" and outcome.wins == 1 and not game.skater.bail_active,
		"authentic Main: native cone crosses its ring, physically lands on the raft, and the real player lands and banks")
	var bank: int = game.score.total_score
	await _frames(tree, 30)
	check.call(bank == 100 and game.score.total_score == bank and cone.status_snapshot().wins == 1,
		"authentic Main: the complete cone stunt awards no fabricated bonus or repeated success")
	print("AUTHENTIC CONE %s player=%s bank=%d" % [outcome, game.skater.global_position, bank])
	_release()

static func _cart_skitch(tree: SceneTree, game: Node, check: Callable) -> void:
	await _reset(tree, game, Vector3(-82.3, 2.8, 70.5), -PI / 2.0)
	_phase = "skitch_native_cart"
	var vehicle: CharacterBody3D = game.feature_hub.vehicle
	Input.action_press("push")
	var caught := false
	var requested := false
	var pending_honest := true
	for frame in 110:
		var gap: float = game.skater.global_position.distance_to(vehicle.get_skitch_anchor())
		if not requested and gap < 1.0 and game.skater.speed > 1.0:
			Input.action_press("grind")
			Input.action_press("interact")
			requested = true
		await _frames(tree, 1)
		Input.action_release("interact")
		if game.skater.skitching and not game.skater.skitch_caught:
			pending_honest = pending_honest and game.score.combo_trick_count == 0 and game.skater._skitch.hand_targets().is_empty()
		if game.skater.skitch_caught:
			caught = true
			break
	Input.action_release("push")
	check.call(caught and pending_honest and game.skater.last_trick_id == "skitch" and game.score.combo_trick_count == 1,
		"authentic Main: actual push catches the moving world cart through held Grind and fresh Interact")
	var start: Vector3 = game.skater.global_position
	for frame in 40:
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if absf(game.skater.skitch_balance) > 0.05:
			Input.action_press("steer_left" if game.skater.skitch_balance > 0.0 else "steer_right",
				minf(0.6, absf(game.skater.skitch_balance) * 4.0))
		await _frames(tree, 1)
	check.call(game.skater.skitching and game.skater.global_position.distance_to(start) > 2.0
		and game.score.combo_trick_count == 1 and game.score.total_score == 0,
		"authentic Main: the cart physically tows the balanced player while one live entry remains unbanked")
	var tow_error := INF
	var grips: Array[Vector3] = game.skater._skitch.hand_targets()
	if grips.size() == 2:
		tow_error = 0.0
		for index in 2:
			var hand: Node3D = game.skater._visual_rig._arms[index].hand
			tow_error = maxf(tow_error, hand.to_global(PALM).distance_to(grips[index]))
	check.call(tow_error < 0.025,
		"authentic Main: both actual palms remain on the current moving cart bar, not its previous-frame location")
	game.toggle_pause()
	var paused: Vector3 = game.skater.global_position
	var cart_paused: Vector3 = vehicle.global_position
	await _frames(tree, 10)
	check.call(game.skater.global_position == paused and vehicle.global_position == cart_paused,
		"authentic Main: pausing freezes the actual attached player and moving vehicle together")
	game.toggle_pause()
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_release("grind")
	check.call(game.skater.airborne and not game.skater.skitching and game.skater.velocity.y > 8.0
		and game.score.combo_trick_count == 2,
		"authentic Main: actual release-pop exits the cart with native upward momentum and an ordinary Ollie entry")
	Input.action_press("grab")
	await _frames(tree, 14)
	var grab: Dictionary = Catalog.definition(game.skater.grab_trick_id)
	var palm_error := INF
	if not grab.is_empty():
		var index := 0 if float(grab.grab_side) < 0.0 else 1
		var hand: Node3D = game.skater._visual_rig._arms[index].hand
		palm_error = hand.to_global(PALM).distance_to(game.skater._board_visual.to_global(grab.grab_target))
	check.call(grab.get("family", "") == "grab" and palm_error < 0.03,
		"authentic Main: a fresh airborne board grab replaces the released tow grip at its actual palm contact")
	Input.action_release("grab")
	await _land(tree, game, 100)
	await _frames(tree, 25)
	check.call(not game.skater.bail_active and game.score.total_score == (Catalog.base_points("skitch") + 100 + int(grab.get("base_points", 0))) * 3,
		"authentic Main: skitch-to-Ollie-to-grab really lands and banks only its three catalog entries")
	print("AUTHENTIC SKITCH tow=%.6f grab=%s palm=%.6f bank=%d" % [tow_error, grab.get("id", ""), palm_error, game.score.total_score])
	_release()

static func _park_laps(tree: SceneTree, game: Node, check: Callable) -> void:
	var lap: Node3D = game.feature_hub.park_lap
	var definitions: Dictionary = lap.status_snapshot()
	for branch: Dictionary in definitions.branches:
		var points: PackedVector3Array = branch.points
		var at: Vector3 = definitions.position
		var direction: Vector3 = points[0] - at
		await _reset(tree, game, at + Vector3.UP * 0.8, atan2(-direction.x, -direction.z))
		_phase = "park_lap_" + str(branch.id)
		await _interact(tree)
		check.call(lap.status_snapshot().state == "active" and lap.status_snapshot().attempts == 1,
			"authentic Main: the park offer starts one real timed lap " + str(branch.id))
		var reached := true
		var popped := false
		var travelled := 0.0
		var camera_clear := true
		for target: Vector3 in points:
			var result: Dictionary = await _drive_native_to(tree, game, target, not popped)
			reached = reached and result.reached
			popped = popped or result.popped
			travelled += result.distance
			camera_clear = camera_clear and result.camera_clear
			if not result.reached: break
		if reached:
			var result: Dictionary = await _drive_native_to(tree, game, at, not popped)
			reached = reached and result.reached
			travelled += result.distance
			camera_clear = camera_clear and result.camera_clear
		_release()
		await _frames(tree, 30)
		var state: Dictionary = lap.status_snapshot()
		check.call(reached and state.state == "success" and state.wins == 1 and state.gate_index == points.size()
			and state.landed_pop and state.remaining > 0.0 and not game.skater.bail_active,
			"authentic Main: real steering, ordered world gates, an actual landed pop and return finish " + str(branch.id))
		check.call(camera_clear and travelled > 120.0 and game.score.total_score == 100,
			"authentic Main: the completed park route has a clear ground chase and only its earned Ollie bank " + str(branch.id))
		print("AUTHENTIC PARK %s reached=%s distance=%.2f camera=%s state=%s position=%s" % [
			branch.id, reached, travelled, camera_clear, state, game.skater.global_position])
	_phase = ""

static func _sunken_facility_journey(tree: SceneTree, game: Node, check: Callable) -> void:
	_climb_visual_stats={"samples":0,"ray_misses":0,"wheel_min":INF,"wheel_max":-INF,"head_relative":0.0,"previous_body":Vector3.INF,"previous_head":Vector3.INF}
	_shoe_floor_stats={"bank":{"samples":0,"vertices":0,"minimum":INF,"leg_scale":0.0},"flat":{"samples":0,"vertices":0,"minimum":INF,"leg_scale":0.0}}
	var definition: Dictionary = game.world.get_park_skatepark_definition()
	var rolling := PackedVector3Array()
	var access := PackedVector3Array()
	var beginner := PackedVector3Array()
	for route: Dictionary in game.world.get_route_definitions():
		if route.id == "kelvingrove_rolling_loop": rolling = route.points
		if route.id == "kelvingrove_summit_skatepark": access = route.points
		if route.id == "kelvingrove_facility_beginner": beginner = route.points
	check.call(definition.has_all(["entry","bounds","rim_y"]) and rolling.size()>6
		and access.size()>=4 and beginner.size()>=8,
		"sunken park Main: the actual installed facility publishes its full climb, summit link and beginner return")
	if definition.is_empty() or rolling.is_empty() or access.is_empty() or beginner.is_empty(): return
	var lap: Node3D = game.feature_hub.park_lap
	var at: Vector3 = lap.status_snapshot().position
	var first_direction := rolling[1]-at
	await _reset(tree,game,at+Vector3.UP*0.8,atan2(-first_direction.x,-first_direction.z))
	_phase = "sunken_park_active_lap_climb"
	await _interact(tree)
	check.call(lap.status_snapshot().state=="active" and lap.status_snapshot().attempts==1,
		"sunken park Main: actual Interact starts One More Lap before the independent uphill destination journey")
	var summit_index := 0
	var nearest := INF
	for index in rolling.size():
		var distance := rolling[index].distance_to(Vector3(-161,17,-178))
		if distance<nearest: nearest=distance;summit_index=index
	var reached := true
	var camera_clear := true
	var travelled := 0.0
	for index in summit_index+1:
		var result: Dictionary = await _drive_facility_to(tree,game,rolling[index],true)
		reached = reached and result.reached
		camera_clear = camera_clear and result.camera_clear
		travelled += result.distance
		if not reached: break
	if reached:
		for target: Vector3 in [Vector3(-165,17,-182),access[0]]:
			var result: Dictionary = await _drive_facility_to(tree,game,target,true)
			reached = reached and result.reached
			camera_clear = camera_clear and result.camera_clear
			travelled += result.distance
			if not reached: break
	check.call(reached and game.skater.global_position.y>16.0 and travelled>110.0
		and camera_clear and not game.skater.bail_active and lap.status_snapshot().state=="active",
		"sunken park Main: genuine steering and pushes climb the existing hillside to the real summit with a clear full-body chase")
	check.call(_climb_visual_stats.samples>=10 and _climb_visual_stats.ray_misses==0
		and _climb_visual_stats.wheel_min>=-0.003 and _climb_visual_stats.head_relative<=0.30,
		"sunken park Main: every actual wheel clears the finite summit-junction surfaces and the complete head motion stays continuous through the uneven crest")
	print("SUNKEN PARK CREST VISUAL "+JSON.stringify(_climb_visual_stats))
	_climb_visual_stats.clear()
	_phase = "sunken_park_active_lap_entry"
	if reached:
		for target: Vector3 in access:
			var result: Dictionary = await _drive_facility_to(tree,game,target,true)
			reached = reached and result.reached
			camera_clear = camera_clear and result.camera_clear
			travelled += result.distance
			if not reached: break
	if reached:
		var inside: Vector3 = definition.entry + Vector3.LEFT*0.8
		var result: Dictionary = await _drive_facility_to(tree,game,inside,true,0.35)
		reached = reached and result.reached
		camera_clear = camera_clear and result.camera_clear
		travelled += result.distance
	check.call(reached and lap.status_snapshot().state=="active" and lap.status_snapshot().remaining>0.0
		and Vector2(game.skater.global_position.x-definition.entry.x,game.skater.global_position.z-definition.entry.z).length()<1.2
		and absf(game.skater.global_position.y-float(definition.rim_y))<0.25
		and game.score.total_score==0 and game.score.get_combo_value()==0 and not game.skater.bail_active,
		"sunken park Main: the live timed lap admits a real supported summit-to-facility entry without a teleport or free points")
	print("SUNKEN PARK CLIMB reached=%s distance=%.2f remaining=%.2f camera=%s at=%s"%[
		reached,travelled,lap.status_snapshot().remaining,camera_clear,game.skater.global_position])
	_phase = "sunken_park_active_lap_visit"
	var visited := reached
	var visit_camera := true
	var visit_path := PackedVector3Array()
	for index in range(1,mini(4,beginner.size())): visit_path.append(beginner[index])
	visit_path.append_array(PackedVector3Array([Vector3(-200,13,-177),Vector3(-204,13,-177),
		Vector3(-204,13,-178),Vector3(-204,14.5,-184),Vector3(-204,14.5,-185),
		Vector3(-209,14.5,-185),Vector3(-209,14.5,-194)]))
	if visited:
		for target: Vector3 in visit_path:
			var result: Dictionary = await _drive_facility_to(tree,game,target,true)
			visited = visited and result.reached
			visit_camera = visit_camera and result.camera_clear
			if not visited: break
	var original_lap_area := Rect2(-225,-190,90,125)
	check.call(visited and visit_camera and game.skater.global_position.z < -191.0
		and not original_lap_area.has_point(Vector2(game.skater.global_position.x,game.skater.global_position.z))
		and lap.is_in_attempt_area(game.skater.global_position) and lap.status_snapshot().state=="active"
		and lap.status_snapshot().remaining>0.0 and not game.skater.bail_active and game.score.total_score==0,
		"sunken park Main: an actual active-lap journey enters the lower basin and supported upper corridor beyond the original area without cancelling or earning free points")
	print("SUNKEN PARK ACTIVE VISIT reached=%s remaining=%.2f camera=%s at=%s"%[
		visited,lap.status_snapshot().remaining,visit_camera,game.skater.global_position])
	# A separate ordinary approach checks the real HUD location prompt. Active
	# lap guidance correctly takes priority and must not be suppressed for it.
	var direction := access[1]-access[0]
	await _reset(tree,game,access[0]+Vector3.UP*0.8,atan2(-direction.x,-direction.z))
	await _frames(tree,150)
	if not _observer.is_valid(): await tree.create_timer(0.0,true).timeout
	_phase = "sunken_park_native_entry_hint"
	check.call(game.skater.is_on_floor() and game.hud._prompt.visible
		and game.hud._prompt.text.contains("SUNKEN SKATEPARK")
		and not game.hud._prompt.text.contains("Interact"),
		"sunken park Main: the actual supported summit approach shows its complete non-interaction navigation cue")
	for target: Vector3 in access:
		var result: Dictionary = await _drive_facility_to(tree,game,target,false)
		if not result.reached: reached=false;break
	_phase = "sunken_park_beginner_circuit"
	var circuit := true
	var circuit_camera := true
	var min_height := INF
	var max_height := -INF
	var circuit_distance := 0.0
	for target: Vector3 in beginner:
		var result: Dictionary = await _drive_facility_to(tree,game,target,false)
		circuit = circuit and result.reached
		circuit_camera = circuit_camera and result.camera_clear
		circuit_distance += result.distance
		min_height=minf(min_height,result.min_height)
		max_height=maxf(max_height,result.max_height)
		if not circuit: break
	check.call(circuit and circuit_camera and not game.skater.bail_active and game.skater.is_on_floor()
		and max_height-min_height>1.25 and circuit_distance>35.0 and game.score.total_score==0,
		"sunken park Main: real ordinary inputs descend to the lower street basin, circulate and climb its supported return with a clear chase")
	_phase = "sunken_park_safe_exit"
	var reversed := access.duplicate()
	reversed.reverse()
	var escaped := circuit
	if escaped:
		for target: Vector3 in reversed:
			var result: Dictionary = await _drive_facility_to(tree,game,target,false)
			escaped = escaped and result.reached and result.camera_clear
			if not escaped: break
	check.call(escaped and game.skater.is_on_floor() and not game.skater.bail_active
		and game.skater.global_position.y>16.5 and game.score.total_score==0,
		"sunken park Main: the genuine beginner circuit leaves through the same real entrance and returns safely uphill without a mandatory jump")
	print("SUNKEN PARK BEGINNER circuit=%s exit=%s distance=%.2f heights=%.3f..%.3f camera=%s at=%s"%[
		circuit,escaped,circuit_distance,min_height,max_height,circuit_camera,game.skater.global_position])
	var shoe_healthy := true
	for location: String in ["bank","flat"]:
		var stats: Dictionary = _shoe_floor_stats[location]
		shoe_healthy = shoe_healthy and stats.samples>=2 and stats.vertices>=100 and stats.minimum>=-0.0015 and stats.leg_scale<=1.12
		print("SUNKEN PARK ACTUAL SHOE %s samples=%d native_vertices=%d minimum=%.7f leg_scale=%.6f"%[
			location,stats.samples,stats.vertices,stats.minimum,stats.leg_scale])
		print("SUNKEN PARK LIMB WORST "+location+" "+JSON.stringify(stats.get("worst",{})))
	check.call(shoe_healthy,
		"sunken park Main: complete pushing/brake-drag Cupsole and CanvasUpper meshes stay above finite native bank-to-flat and basin floors within the existing1.5mm compression bound")
	_shoe_floor_stats.clear()
	_release()
	_phase = ""

static func _sunken_facility_skating(tree: SceneTree, game: Node, check: Callable) -> void:
	var park: Node3D = game.world.find_child("KelvingroveSunkenSkatepark",true,false)
	check.call(park!=null,"sunken park skating: the production world contains the actual excavated facility")
	if park==null: return
	for item: Array in [["DeepBowl",Vector3(-197,13.8,-182.0),11.5],
		["ShallowBowl",Vector3(-219,13.8,-182.5),13.1]]:
		var bowl: Node3D = park.get_node(item[0])
		await _reset(tree,game,item[1],0.0)
		_phase = "sunken_park_" + str(item[0]).to_snake_case() + "_native_lip"
		var events: Array[String] = []
		var on_entry := func(_label: String,_points: int): events.append(game.skater.last_trick_id)
		game.skater.trick_performed.connect(on_entry)
		var min_height: float = game.skater.global_position.y
		var real_face := false
		var clear := true
		Input.action_press("push")
		Input.action_press("grind")
		for frame in 260:
			await _frames(tree,1)
			if not _observer.is_valid(): await tree.create_timer(0.0,true).timeout
			min_height=minf(min_height,game.skater.global_position.y)
			real_face = real_face or (game.skater.transition_active and game.skater._transition.feature==bowl)
			if frame%6==0: clear = clear and _facility_camera_clear(game)
			if game.skater.lip_active or game.skater.bail_active: break
		check.call(real_face and game.skater.lip_active and game.skater._transition.feature==bowl
			and min_height<float(item[2]) and not game.skater.bail_active and events==["lip_stall"]
			and game.skater.get_support_normal().dot(Vector3.UP)>0.999,
			"sunken park skating: real ground input enters %s through its open port, reaches its actual bottom and bears on native coping"%item[0])
		Input.action_release("push")
		await _frames(tree,12)
		var accepted: int = game.score.get_combo_value()
		check.call(clear and accepted>=Catalog.base_points("lip_stall") and game.score.total_score==0
			and game.score.combo_trick_count==1 and events==["lip_stall"],
			"sunken park skating: held %s lip remains one earned entry with clear actual head/deck/sole/toe and camera volume"%item[0])
		Input.action_release("grind")
		Input.action_press("brake")
		await _frames(tree,75)
		var bank: int = game.score.total_score
		await _frames(tree,25)
		check.call(not game.skater.bail_active and bank==accepted and game.score.total_score==bank
			and events==["lip_stall"] and game.score.last_banked_tricks==["Lip Stall"],
			"sunken park skating: %s releases its real lip, returns without collision and banks exactly its held receipt once"%item[0])
		print("SUNKEN PARK MAIN LIP %s minimum=%.4f face=%s camera=%s entries=%s accepted=%d bank=%d at=%s"%[
			item[0],min_height,real_face,clear,events,accepted,bank,game.skater.global_position])
		game.skater.trick_performed.disconnect(on_entry)
		_release()
	# Explicit one-time curved-contact/tangent fixture, independently matched
	# to the real native wall. The complete lower carve thereafter is unforced.
	await _reset(tree,game,SAFE)
	var deep: Node3D = park.get_node("DeepBowl")
	var sample: Dictionary = deep.sample(0.6,0.0)
	var speed := sqrt(22.0*(deep.floor_radius+deep.radius*sin(0.6))*tan(0.6))
	game.skater.set_physics_process(false)
	game.skater.spawn_position=sample.point+sample.normal*0.022
	game.skater.reset_skater()
	game.skater.velocity=sample.lateral*speed
	game.skater.speed=speed
	game.skater.airborne=false
	game.skater.rotation.y=atan2(-game.skater.velocity.x,-game.skater.velocity.z)
	game.skater.set_physics_process(true)
	_phase="sunken_park_deep_native_carve"
	var stats: Dictionary = WheelContact._stats()
	var sweep := 0.0
	var previous := 0.0
	var supported := true
	var camera_clear := true
	for frame in 300:
		await _frames(tree,1)
		if not _observer.is_valid(): await tree.create_timer(0.0,true).timeout
		var local: Vector3 = deep.to_local(game.skater.global_position)
		var phi := atan2(local.x,-local.z)
		sweep += angle_difference(previous,phi)
		previous=phi
		supported = supported and game.skater.transition_active and game.skater._transition.feature==deep 			and not game.skater.airborne and not game.skater.bail_active
		if frame>=12: WheelContact._measure(game.skater,deep,stats)
		if frame%6==0: camera_clear = camera_clear and _facility_camera_clear(game)
		if sweep>=TAU: break
	check.call(supported and sweep>=TAU and stats.samples>=180 and camera_clear and game.score.total_score==0,
		"sunken park skating: production Main circles the actual lower deep bowl through its whole open-port azimuth with clear native chase")
	check.call(stats.ray_misses==0 and stats.complete_frames==stats.samples and stats.board_dot_min>=0.999
		and stats.capsule_dot_min>=0.9999 and WheelContact._healthy(stats),
		"sunken park skating: all four actual wheels maintain the unchanged strict native-face contact bands throughout the full deep carve")
	WheelContact._print("sunken_deep",stats)
	# A complete real ground Ollie captures the lower street rail; this is not
	# the descending initial rail-contact fixture used by the catalog matrix.
	await _reset(tree,game,Vector3(-215,13.8,-174.9),-PI*0.5)
	_phase="sunken_park_street_native_grind"
	var captures: Array[String] = []
	var events: Array[String] = []
	var on_capture := func(id: String): captures.append(id)
	var on_entry := func(_label: String,_points: int): events.append(game.skater.last_trick_id)
	game.skater.grind_captured.connect(on_capture)
	game.skater.trick_performed.connect(on_entry)
	Input.action_press("push")
	await _frames(tree,42)
	Input.action_press("ollie")
	await _frames(tree,2)
	Input.action_release("ollie")
	await _frames(tree,1)
	Input.action_release("push")
	Input.action_press("grind")
	var held := 0
	var clear := true
	for frame in 150:
		await _frames(tree,1)
		if not _observer.is_valid(): await tree.create_timer(0.0,true).timeout
		if game.skater.grinding: held+=1
		if frame%6==0: clear = clear and _facility_camera_clear(game)
		if held>=18 or game.skater.bail_active: break
	var accepted: int = game.score.get_combo_value()
	check.call(captures==["Grind_Park_StreetFlatbar"] and held>=18 and events==["ollie","rail_grind"]
		and not game.skater.bail_active and game.skater.global_position.x> -209.5 and clear
		and game.score.total_score==0 and game.score.combo_trick_count==2,
		"sunken park skating: a real pushed approach and ground Ollie capture and hold the actual street flatbar with two connected entries")
	Input.action_release("grind")
	await _land(tree,game,100)
	await _frames(tree,30)
	var bank: int = game.score.total_score
	await _frames(tree,25)
	check.call(not game.skater.bail_active and game.skater.is_on_floor() and bank==accepted
		and game.score.total_score==bank and captures==["Grind_Park_StreetFlatbar"],
		"sunken park skating: the native street grind releases, lands and banks exactly its accepted combo once")
	print("SUNKEN PARK MAIN RAIL held=%d captures=%s entries=%s accepted=%d bank=%d at=%s"%[
		held,captures,events,accepted,bank,game.skater.global_position])
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.trick_performed.disconnect(on_entry)
	_release()
	await _sunken_hip_transfer(tree,game,park,check)
	await _sunken_port_departure(tree,game,park,check)
	_phase=""

static func _sunken_hip_transfer(tree: SceneTree, game: Node, park: Node3D, check: Callable) -> void:
	var hip: Node3D = park.get_node("ForegroundHip")
	var front: Node3D = hip.get_node("FrontTransition")
	var back: Node3D = hip.get_node("BackTransition")
	await _reset(tree,game,Vector3(-210.7,13.8,-176.5),PI*0.5)
	_phase="sunken_park_hip_native_transfer"
	Input.action_press("push")
	var front_seen := false
	var upward_air := false
	var clear := true
	for frame in 220:
		await _frames(tree,1)
		if not _observer.is_valid(): await tree.create_timer(0.0,true).timeout
		if game.skater.transition_active and game.skater._transition.feature==front:
			front_seen=true
			Input.action_release("push")
		if frame%6==0: clear = clear and _facility_camera_clear(game)
		if game.skater.airborne and game.skater.transition_active and game.skater._transition.state=="air":
			upward_air=game.skater.velocity.y>1.0
			break
		if game.skater.bail_active: break
	check.call(front_seen and upward_air and not game.skater.bail_active,
		"sunken park skating: a genuine eight-metre pushed approach and coast ride the compact hip face into real vert air")
	await _frames(tree,4)
	Input.action_press("push")
	await _frames(tree,9)
	Input.action_release("push")
	var back_seen := false
	var exited := false
	var minimum_x: float = game.skater.global_position.x
	for frame in 250:
		await _frames(tree,1)
		if not _observer.is_valid(): await tree.create_timer(0.0,true).timeout
		minimum_x=minf(minimum_x,game.skater.global_position.x)
		back_seen = back_seen or (game.skater.transition_active and game.skater._transition.feature==back
			and game.skater._transition.state=="surface")
		if back_seen and not game.skater.transition_active and game.skater.is_on_floor():
			exited=true
			Input.action_press("brake")
		if frame%6==0: clear = clear and _facility_camera_clear(game)
		if game.skater.bail_active or (exited and absf(game.skater.speed)<0.3): break
	check.call(back_seen and exited and not game.skater.bail_active and game.skater.is_on_floor()
		and game.skater.global_position.x< -222.3 and minimum_x> -227.2 and clear,
		"sunken park skating: a fresh in-air transfer reaches the true back hip face, rides out and brakes within the visible finite west runout")
	check.call(game.score.total_score==0 and game.score.get_combo_value()==0,
		"sunken park skating: pumping and transferring the compact hip cannot manufacture trick entries or bank points")
	print("SUNKEN PARK MAIN HIP front=%s air=%s back=%s exit=%s camera=%s min_x=%.5f speed=%.4f at=%s"%[
		front_seen,upward_air,back_seen,exited,clear,minimum_x,game.skater.speed,game.skater.global_position])
	_release()

static func _sunken_port_departure(tree: SceneTree, game: Node, park: Node3D, check: Callable) -> void:
	await _reset(tree,game,SAFE)
	var bowl: Node3D = park.get_node("DeepBowl")
	var phi: float = PI-bowl.port_half_angle()-0.08
	var sample: Dictionary = bowl.sample(0.95,phi*bowl.floor_radius)
	# Same declared one-time native curved contact used by the independent
	# optional-port helper regression; production Main owns everything after it.
	game.skater.set_physics_process(false)
	game.skater.spawn_position=sample.point+sample.normal*0.022
	game.skater.reset_skater()
	game.skater.velocity=sample.lateral*8.0
	game.skater.speed=8.0
	game.skater.airborne=false
	game.skater.rotation.y=atan2(-game.skater.velocity.x,-game.skater.velocity.z)
	game.skater.set_physics_process(true)
	_phase="sunken_park_native_port_departure"
	var evidence := {"bails":0,"landings":[],"tricks":[],"landing_frames":[]}
	var on_bail := func(): evidence.bails+=1
	var on_land := func(clean: bool):
		evidence.landings.append(clean)
		evidence.landing_frames.append({"tick":Engine.get_physics_frames(),"body":game.skater.global_position,
			"transition":game.skater.transition_active,"state":game.skater._transition.state,
			"native_floor_valid":game.skater._native_floor_valid,"is_on_floor":game.skater.is_on_floor(),
			"airborne":game.skater.airborne,"force_air_tick":game.skater._force_air_tick})
	var on_trick := func(_label: String,_points: int): evidence.tricks.append(game.skater.last_trick_id)
	game.skater.bailed.connect(on_bail)
	game.skater.landed.connect(on_land)
	game.skater.trick_performed.connect(on_trick)
	var entered := false
	var departed := false
	var ordinary := false
	var after_departure := Vector3.INF
	var travel := 0.0
	var clear := true
	var maximum_step := 0.0
	var previous: Vector3 = game.skater.global_position
	for frame in 180:
		await _frames(tree,1)
		if not _observer.is_valid(): await tree.create_timer(0.0,true).timeout
		var at: Vector3 = game.skater.global_position
		maximum_step=maxf(maximum_step,previous.distance_to(at))
		previous=at
		entered = entered or (game.skater.transition_active and game.skater._transition.feature==bowl
			and game.skater._transition.state=="surface")
		if entered and not departed and game.skater.airborne:
			departed=true
			after_departure=at
		if departed: travel=maxf(travel,at.distance_to(after_departure))
		ordinary = ordinary or (departed and not game.skater.transition_active and game.skater.is_on_floor()
			and not game.skater.airborne and game.skater.up_direction.dot(Vector3.UP)>0.999)
		if frame%6==0: clear=clear and _facility_camera_clear(game)
		if game.skater.bail_active or (ordinary and travel>2.4): break
	check.call(entered and departed and ordinary and travel>2.4 and maximum_step<0.20
		and not game.skater.transition_active and not game.skater.bail_active,
		"sunken park Main: the genuine finite upper-port departure moves through air and returns to the actual ordinary bank without a capture loop or teleport")
	check.call(evidence.bails==0 and evidence.landings==[true] and evidence.tricks.is_empty()
		and game.score.total_score==0 and game.score.get_combo_value()==0,
		"sunken park Main: actual open-port flight emits one clean landing and no phantom tricks, repeated bank or score")
	var collision: CollisionShape3D = game.skater.get_node("BodyCollision")
	check.call(clear and game.skater._native_floor_valid and game.skater.is_on_floor()
		and not game.skater._force_air_tick and collision.global_basis.y.normalized().dot(Vector3.UP)>0.999,
		"sunken park Main: the optional-port return restores the real upright native capsule/floor cache and clear actual body/feet/camera")
	print("SUNKEN PARK MAIN PORT entered=%s air=%s ordinary=%s travel=%.6f max_step=%.6f camera=%s landings=%s tricks=%s at=%s"%[
		entered,departed,ordinary,travel,maximum_step,clear,evidence.landings,evidence.tricks,game.skater.global_position])
	print("SUNKEN PARK PORT EVENT TRACE "+JSON.stringify({"events":evidence.landing_frames,
		"final_floor":game.skater.is_on_floor(),"final_native":game.skater._native_floor_valid,
		"final_airborne":game.skater.airborne,"final_force_air":game.skater._force_air_tick,
		"final_capsule_up":collision.global_basis.y,"final_helper":game.skater._transition.state}))
	game.skater.bailed.disconnect(on_bail)
	game.skater.landed.disconnect(on_land)
	game.skater.trick_performed.disconnect(on_trick)
	_release()

static func _drive_facility_to(tree: SceneTree, game: Node, target: Vector3, require_lap: bool, arrival_radius: float=0.95) -> Dictionary:
	var distance := 0.0
	var camera_clear := true
	var camera_diagnosed := false
	var min_height: float = game.skater.global_position.y
	var max_height := min_height
	for frame in 1200:
		var at: Vector3 = game.skater.global_position
		var offset := Vector3(target.x-at.x,0,target.z-at.z)
		if offset.length()<arrival_radius and absf(at.y-target.y)<0.30:
			return {"reached":true,"camera_clear":camera_clear,"distance":distance,"min_height":min_height,"max_height":max_height}
		if game.skater.bail_active or (require_lap and game.feature_hub.park_lap.status_snapshot().state!="active"): break
		var desired := atan2(-offset.x,-offset.z)
		var angle := angle_difference(game.skater.rotation.y,desired)
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if absf(angle)>0.025:
			Input.action_press("steer_left" if angle>0.0 else "steer_right",minf(1.0,absf(angle)*2.0))
		var stop: bool = game.skater.speed < -0.4 or (absf(angle)>0.9 and absf(game.skater.speed)>1.0) 			or (absf(angle)>0.35 and absf(game.skater.speed)>4.0) or (offset.length()<4.0 and game.skater.speed>4.0)
		_navigation_throttle("brake" if stop else "push")
		await _frames(tree,1)
		if not _observer.is_valid(): await tree.create_timer(0.0,true).timeout
		distance += at.distance_to(game.skater.global_position)
		min_height=minf(min_height,game.skater.global_position.y)
		max_height=maxf(max_height,game.skater.global_position.y)
		_sample_climb_visuals(game)
		if frame%6==0:
			_sample_facility_shoe(game)
			var actual_clear := _facility_camera_clear(game)
			if not actual_clear and not camera_diagnosed:
				_diagnose_facility_mesh(game)
				camera_diagnosed=true
			camera_clear = camera_clear and actual_clear
	var contacts := []
	for index in game.skater.get_slide_collision_count():
		var hit: KinematicCollision3D = game.skater.get_slide_collision(index)
		contacts.append({"body":str(hit.get_collider().name),"normal":hit.get_normal(),"point":hit.get_position()})
	print("SUNKEN PARK NAV STOP target=%s at=%s speed=%.3f heading=%.3f normal=%s contacts=%s"%[
		target,game.skater.global_position,game.skater.speed,game.skater.rotation.y,game.skater.get_floor_normal(),contacts])
	return {"reached":false,"camera_clear":camera_clear,"distance":distance,"min_height":min_height,"max_height":max_height}

static func _sample_climb_visuals(game: Node) -> void:
	if _climb_visual_stats.is_empty() or _phase!="sunken_park_active_lap_climb": return
	var stats: Dictionary = _climb_visual_stats
	var body: Vector3 = game.skater.global_position
	var head: Vector3 = game.skater._visual_rig._head.global_position
	if Vector3(stats.previous_body).is_finite():
		var relative := (head-Vector3(stats.previous_head)-(body-Vector3(stats.previous_body))).length()
		stats.head_relative=maxf(stats.head_relative,relative)
	stats.previous_body=body
	stats.previous_head=head
	if body.x< -165.2 or body.x> -162.0 or body.z> -175.0 or body.z< -180.0: return
	stats.samples += 1
	for child: Node in game.skater._board_visual.get_children():
		if not child is MeshInstance3D or not child.mesh is CylinderMesh: continue
		var cylinder: CylinderMesh = child.mesh
		if not is_equal_approx(cylinder.top_radius,0.032) or not is_equal_approx(cylinder.height,0.032): continue
		var ray := PhysicsRayQueryParameters3D.create(child.global_position+Vector3.UP*0.35,child.global_position-Vector3.UP*0.50,1|8)
		ray.exclude=[game.skater.get_rid()]
		var hit: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty(): stats.ray_misses+=1;continue
		var minimum := INF
		for surface in child.mesh.get_surface_count():
			for point: Vector3 in child.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				minimum=minf(minimum,(child.to_global(point)-Vector3(hit.position)).dot(Vector3(hit.normal)))
		if minimum<stats.wheel_min:
			stats.worst={"step":_step,"tick":Engine.get_physics_frames(),"body":body,"velocity":game.skater.velocity,
				"normal":game.skater.get_floor_normal(),"airborne":game.skater.airborne,"on_floor":game.skater.is_on_floor(),
				"native":game.skater._native_floor_valid,"force_air":game.skater._force_air_tick,
				"wheel":str(child.name),"point":child.global_position,"floor":hit.position,"floor_normal":hit.normal,
				"collider":str(hit.collider.name),"board_up":game.skater._board_visual.global_basis.y,
				"chosen_plane":game.skater._native_board_floor()}
		stats.wheel_min=minf(stats.wheel_min,minimum)
		stats.wheel_max=maxf(stats.wheel_max,minimum)

static func _sample_facility_shoe(game: Node) -> void:
	if _shoe_floor_stats.is_empty() or game.skater.airborne or not game.skater.is_on_floor(): return
	var at: Vector3 = game.skater.global_position
	var location := "bank" if absf(at.x+204)<1.5 and at.z< -177 and at.z> -183 else 		("flat" if at.x> -201 and at.x< -192 and at.z< -173 and at.z> -177.5 else "")
	if location.is_empty(): return
	var rig = game.skater._visual_rig
	if maxf(rig._push_blend,rig._brake_blend)<0.1: return
	var foot: Node3D = rig._legs[1].foot
	var stats: Dictionary = _shoe_floor_stats[location]
	stats.samples += 1
	var skeleton: Skeleton3D = rig._garments.skeleton
	for bone in skeleton.get_bone_count():
		if skeleton.get_bone_name(bone).ends_with("_thigh") or skeleton.get_bone_name(bone).ends_with("_calf"):
			var scale_y := skeleton.get_bone_pose_scale(bone).y
			if scale_y>stats.leg_scale:
				stats.leg_scale=scale_y
				var right := skeleton.get_bone_name(bone).begins_with("right_")
				var prefix := "right" if right else "left"
				var hip: Vector3 = skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(prefix+"_thigh")).origin)
				var ankle: Vector3 = rig._legs[1 if right else 0].foot.global_position
				stats.worst={"phase":_phase,"step":_step,"physics_frame":Engine.get_physics_frames(),
					"bone":skeleton.get_bone_name(bone),"scale":scale_y,"hip":hip,"ankle":ankle,
					"front_ankle":rig._legs[0].foot.global_position,"rear_ankle":rig._legs[1].foot.global_position,
					"push_phase":rig._push_phase,"push_blend":rig._push_blend,"brake_blend":rig._brake_blend,
					"rider_transform":rig._rider.global_transform,"visual_transform":game.skater._visual.global_transform,
					"body":game.skater.global_position,"normal":game.skater.get_floor_normal(),
					"actions":[Input.get_action_strength("push"),Input.get_action_strength("brake")]}
	for label: String in ["Cupsole","CanvasUpper"]:
		var mesh: MeshInstance3D = foot.get_node(label)
		for surface in mesh.mesh.get_surface_count():
			for vertex: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var point := mesh.to_global(vertex)
				var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.35,point-Vector3.UP*0.45,1|8)
				ray.exclude=[game.skater.get_rid()]
				var hit: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(ray)
				if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP)<0.65: continue
				stats.vertices += 1
				stats.minimum=minf(stats.minimum,(point-Vector3(hit.position)).dot(Vector3(hit.normal)))

static func _facility_camera_clear(game: Node) -> bool:
	var camera: Camera3D = game.skater._camera
	if not camera.global_position.is_finite(): return false
	var rig = game.skater._visual_rig
	var points := PackedVector3Array([rig._head.global_position,rig._board.global_position])
	# A box corner can combine the lowest mid-deck height with a raised kick's
	# maximum X/Z where no actual board geometry exists. Native clean convex
	# points preserve every real extremity without inventing those corners.
	for mesh: MeshInstance3D in [rig._head.get_node("AnatomicalHead"),rig._board.get_node("CurvedMapleDeck")]:
		var key := mesh.mesh.get_instance_id()
		if not _camera_hulls.has(key):
			var hull: ConvexPolygonShape3D = mesh.mesh.create_convex_shape(true,false)
			_camera_hulls[key] = hull.points
		for point: Vector3 in _camera_hulls[key]: points.append(mesh.to_global(point))
	for leg: Dictionary in rig._legs:
		points.append(leg.foot.to_global(Footwear.SOLE_CONTACT))
		points.append(leg.foot.to_global(Footwear.TOE_CONTACT))
	var space: PhysicsDirectSpaceState3D = game.skater.get_world_3d().direct_space_state
	for point_index in points.size():
		var point: Vector3 = points[point_index]
		if not point.is_finite() or not camera.is_position_in_frustum(point):
			print("SUNKEN PARK CAMERA FRUSTUM rider=%s camera=%s actual_point=%s"%[game.skater.global_position,camera.global_position,point])
			return false
		var kind: String = ["front_sole","front_toe","rear_sole","rear_toe"][point_index-(points.size()-4)] if point_index>=points.size()-4 else "actual_head_or_deck_hull"
		var ray := PhysicsRayQueryParameters3D.create(camera.global_position,point,1|8)
		ray.exclude=[game.skater.get_rid()]
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			if kind.ends_with("_sole") and _verified_sole_endpoint(game,point,hit): continue
			print("SUNKEN PARK CAMERA ACTUAL OCCLUSION rider=%s camera=%s point=%s hit=%s normal=%s kind=%s collider=%s"%[
				game.skater.global_position,camera.global_position,point,hit.position,hit.normal,kind,hit.collider.name])
			return false
	var sphere := SphereShape3D.new()
	sphere.radius=0.25
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=sphere
	query.transform=Transform3D(Basis.IDENTITY,camera.global_position)
	query.collision_mask=1|8
	query.exclude=[game.skater.get_rid()]
	query.margin=0.015
	return space.intersect_shape(query,1).is_empty()

static func _verified_sole_endpoint(game: Node, point: Vector3, sight_hit: Dictionary) -> bool:
	# The real outsole deliberately contacts native support. Preserve the
	# existing 4mm sole-plane band, never a generic camera ray-distance escape.
	# A wall, another collider, non-support face or deep penetration still fails.
	var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.15,point-Vector3.UP*0.15,1|8)
	ray.exclude=[game.skater.get_rid()]
	var support: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(ray)
	if support.is_empty() or support.collider != sight_hit.collider: return false
	var normal: Vector3 = support.normal
	var floor_cos := cos(float(game.skater.floor_max_angle))
	return (normal.dot(Vector3.UP)>=floor_cos and Vector3(sight_hit.normal).dot(normal)>=0.98
		and absf((point-Vector3(support.position)).dot(normal))<=0.004
		and absf((Vector3(sight_hit.position)-Vector3(support.position)).dot(normal))<=0.001)

static func _diagnose_facility_mesh(game: Node) -> void:
	var camera: Camera3D = game.skater._camera
	var rig = game.skater._visual_rig
	var reports := []
	for mesh: MeshInstance3D in [rig._head.get_node("AnatomicalHead"),rig._board.get_node("CurvedMapleDeck")]:
		var vertices := 0
		var blocked := 0
		var first := {}
		for surface in mesh.mesh.get_surface_count():
			for point: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				vertices += 1
				var world := mesh.to_global(point)
				var ray := PhysicsRayQueryParameters3D.create(camera.global_position,world,1|8)
				ray.exclude = [game.skater.get_rid()]
				var hit: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(ray)
				if not hit.is_empty():
					blocked += 1
					if first.is_empty(): first={"vertex":world,"hit":hit.position,"collider":str(hit.collider.name),"distance_to_vertex":Vector3(hit.position).distance_to(world)}
			reports.append({"mesh":str(mesh.name),"vertices":vertices,"blocked":blocked,"first":first})
	print("SUNKEN PARK ACTUAL MESH rider=%s camera=%s normal=%s board_up=%s reports=%s"%[
		game.skater.global_position,camera.global_position,game.skater.get_floor_normal(),rig._board.global_basis.y,reports])

static func _drive_native_to(tree: SceneTree, game: Node, target: Vector3, request_pop: bool) -> Dictionary:
	var distance := 0.0
	var popped := false
	var camera_clear := true
	for frame in 1200:
		var at: Vector3 = game.skater.global_position
		var offset := Vector3(target.x - at.x, 0, target.z - at.z)
		if offset.length() < 1.5:
			return {"reached": true, "popped": popped, "distance": distance, "camera_clear": camera_clear}
		var lap_state: Dictionary = game.feature_hub.park_lap.status_snapshot()
		if lap_state.state == "success" and target.distance_to(lap_state.position) < 0.01 and offset.length() <= 3.2:
			return {"reached": true, "popped": popped, "distance": distance, "camera_clear": camera_clear}
		if game.skater.bail_active or game.feature_hub.park_lap.status_snapshot().state != "active": break
		var desired := atan2(-offset.x, -offset.z)
		var angle := angle_difference(game.skater.rotation.y, desired)
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if absf(angle) > 0.03:
			Input.action_press("steer_left" if angle > 0.0 else "steer_right", minf(1.0, absf(angle) * 2.0))
		var stop: bool = game.skater.speed < -0.4 or (absf(angle) > 0.9 and absf(game.skater.speed) > 1.0) \
			or (absf(angle) > 0.35 and absf(game.skater.speed) > 5.0) or (offset.length() < 5.0 and game.skater.speed > 5.0)
		_navigation_throttle("brake" if stop else "push")
		if request_pop and not popped and game.skater.is_on_floor() and game.skater.speed > 4.0 and absf(angle) < 0.15:
			Input.action_press("ollie")
			await _frames(tree, 2)
			Input.action_release("ollie")
			popped = true
		await _frames(tree, 1)
		distance += at.distance_to(game.skater.global_position)
		if frame % 6 == 0:
			var head: Vector3 = game.skater._visual_rig._head.global_position
			camera_clear = camera_clear and game.skater._camera.global_position.is_finite() \
				and game.skater._camera.is_position_in_frustum(head)
			var query := PhysicsRayQueryParameters3D.create(game.skater._camera.global_position, head, 1)
			query.exclude = [game.skater.get_rid()]
			camera_clear = camera_clear and game.skater.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	var contacts: Array = []
	for index in game.skater.get_slide_collision_count():
		var hit: KinematicCollision3D = game.skater.get_slide_collision(index)
		contacts.append({"collider": str(hit.get_collider().name), "normal": hit.get_normal(), "position": hit.get_position()})
	print("AUTHENTIC NAV STOP target=%s at=%s heading=%.3f speed=%.3f floor=%s wall=%s normal=%s manual=%s inputs=%s contacts=%s" % [
		target, game.skater.global_position, game.skater.rotation.y, game.skater.speed,
		game.skater.is_on_floor(), game.skater.is_on_wall(), game.skater.get_floor_normal(), game.skater.manual_active,
		[Input.get_action_strength("push"), Input.get_action_strength("brake")], contacts])
	return {"reached": false, "popped": popped, "distance": distance, "camera_clear": camera_clear}

static func _navigation_throttle(action: String) -> void:
	if not _navigation_action.is_empty() and _navigation_action != action:
		# A real opposed-input frame separates travel braking from a deliberate
		# quick up/down manual gesture. This does not alter the input recognizer.
		Input.action_press("push")
		Input.action_press("brake")
	else:
		Input.action_release("brake" if action == "push" else "push")
		Input.action_press(action)
	_navigation_action = action

static func _interact(tree: SceneTree) -> void:
	Input.action_press("interact")
	await _frames(tree, 1)
	Input.action_release("interact")
	await _frames(tree, 1)

static func _reset(tree: SceneTree, game: Node, at: Vector3, yaw: float = 0.0) -> void:
	_release()
	_navigation_action = ""
	_phase = ""
	game.skater.spawn_position = at
	game.restart_run()
	await _frames(tree, 40)
	game.skater.rotation.y = yaw

static func _land(tree: SceneTree, game: Node, maximum: int) -> void:
	for frame in maximum:
		if game.skater.is_on_floor() and not game.skater.airborne and not game.skater.setup_active \
				and not game.skater.bail_active: return
		await _frames(tree, 1)

static func _markers(game: Node) -> Array[Vector3]:
	var rig = game.skater._visual_rig
	var points: Array[Vector3] = [rig._head.global_position, game.skater._board_visual.global_position]
	for leg: Dictionary in rig._legs: points.append(leg.foot.global_position)
	for arm: Dictionary in rig._arms: points.append(arm.hand.global_position)
	return points

static func _marker_distance(a: Array[Vector3], b: Array[Vector3]) -> float:
	var greatest := 0.0
	for index in a.size(): greatest = maxf(greatest, a[index].distance_to(b[index]))
	return greatest

static func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

static func _sole_plane_error(foot: Node3D, point: Vector3, normal: Vector3) -> float:
	var mesh: MeshInstance3D = foot.get_node("Cupsole")
	var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var error := 0.0
	for vertex: Vector3 in vertices:
		if is_equal_approx(vertex.y, SOLE.y):
			error = maxf(error, absf((mesh.to_global(vertex) - point).dot(normal)))
	return error

static func _griptape_distance(point: Vector3, board: Node3D) -> float:
	# Measure the rendered curved deck, rather than a fixed nominal ankle
	# height that can agree with an embedded sole on the raised nose/tail fan.
	var tape: MeshInstance3D = board.get_node("Griptape")
	return ContactGeometry._surface_distance(point, [tape])

static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)

static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
		_step += 1
		if _observer.is_valid() and not _phase.is_empty(): await _observer.call(_phase, _game, _step)
