extends Node
## Normal scene launch: Main's ordinary title branch and ordinary player callbacks.
## Initial diagnostic placements are explicit; no camera/pose/process method is called manually.
const MainScene = preload("res://game/main.tscn")
const Playability = preload("res://tests/playability_regression_tests.gd")
const SIZE := Vector2i(1280, 800)
const EXPECTED := 19
var game: Node
var output := ""
var failures := 0
var captures: Array[Dictionary] = []
var routes: Array = []
var natural: Dictionary = {}
var coast: Dictionary = {}
var _draw_seen := false
var _started_ms := 0
var _normal_title := false
var _visual_checks: Array[Dictionary] = []
var _stage_evidence: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_started_ms = Time.get_ticks_msec()
	_run.call_deferred()

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - _started_ms > 360000:
		push_error("PLAYABILITY CAPTURE TIMEOUT")
		get_tree().quit(2)

func _run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--script"):
		push_error("Playability evidence requires a graphical normal scene launch, without --script.")
		get_tree().quit(2)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not DirAccess.dir_exists_absolute(args[0]):
		push_error("Expected one existing local output directory.")
		get_tree().quit(2)
		return
	output = args[0]
	RenderingServer.render_loop_enabled = false
	get_tree().root.size = SIZE
	get_tree().root.content_scale_size = SIZE
	game = MainScene.instantiate()
	game.persistence_enabled = false
	add_child(game)
	await _frames(4)
	_normal_title = game.paused and get_tree().paused and game.hud._page == "title"
	_check(_normal_title, "ordinary Main entered its actual paused title branch")
	Playability._check_visuals(game, _visual_check)
	routes = game.world.get_route_definitions()
	_check(routes.size() == 48, "current world has 48 routes")
	await _menu_ready("title")
	await _capture("01-normal-title", "ordinary_title", "Real Main title branch; profile writes disabled before entering the tree.", false)
	await Playability._activate(get_tree(), game.hud, "FREE SKATE")
	await _frames(45)
	_check(game.free_skate_mode and not game.paused and game.hud._page.is_empty(), "mapped Enter activates visible FREE SKATE")
	await _capture("02-normal-spawn", "ordinary_gameplay", "Actual title-to-Free-Skate spawn, settled 45 physics ticks; no initial transform override.")
	natural = await Playability.drive_natural_spawn(get_tree(), game, _natural_stage)
	_check(natural.bails == 0 and natural.hidden == 0 and natural.blocked == 0 and natural.close == 0 and natural.nonfinite == 0,
		"shared natural push/left/right driver has no bails or camera failures")
	await _coast_and_brake()
	await _fixture_view("08-shop-wall-camera", Vector3(-34, 1.25, 4), -PI / 2.0,
		"Initial shop-wall diagnostic placement from the reproduced 45/60 cropped-frame failure; ordinary callbacks settle the repaired chase.")
	await _fixture_view("09-station-undercroft-camera", Vector3(-114, 2.8, -8), -PI / 2.0,
		"Initial lower station floor placement at Y2, beneath the separate Y5 deck; ordinary chase and physics, no authored camera.")
	await _fixture_view("10-gallery-column-camera", Vector3(3, 3.45, -37), PI,
		"Initial supported terrace placement with gallery columns behind the rider; ordinary chase handles the obstruction.")
	for entry: Array in [
		["11-north-west-close", "gallery_west_close"], ["12-north-east-close", "gallery_east_close"],
		["13-south-west-close", "exchange_west_quay_close"], ["14-south-east-close", "exchange_east_quay_close"]]:
		var points := _route_points(entry[1])
		if points.size() < 2: continue
		var reverse: bool = str(entry[1]).contains("east")
		var start: Vector3 = points[-1] if reverse else points[0]
		var target: Vector3 = points[-2] if reverse else points[1]
		var direction: Vector3 = target - start
		await _fixture_view(entry[0], start + Vector3.UP * 0.8, atan2(-direction.x, -direction.z),
			"Initial supported " + ("far exit looking back into " if reverse else "city mouth of ") + entry[1] + "; static ordinary chase inspection, not a traversed-route claim.")
	await _park_views()
	game.hud.show_map()
	await _menu_ready("map")
	await _capture("17-current-48-route-map", "production_map", "Actual production map opened through HUD.show_map(), after the ordinary game launch; 48 runtime routes and six area checkpoints.", false)
	game.hud.hide_menu()
	await _fixture_view("18-barras-through-market", Vector3(114, 0.8, 10), 0.0,
		"Initial supported ordinary chase inside the existing Barras lane; current-source landmark regression context, no delivery replay.")
	await _fixture_view("19-clyde-safe-bridge", Vector3(-98, 2.8, 72), PI,
		"Initial supported ordinary chase toward the existing safe Clyde bridge; current-source regression context, no jump or recovery claim.")
	_write_manifest()
	Playability._release()
	get_tree().paused = false
	print("PLAYABILITY CAPTURE RESULT: %d frames, %d failures; normal scene callbacks, no profile writes" % [captures.size(), failures])
	get_tree().quit(0 if failures == 0 and captures.size() == EXPECTED else 1)

func _natural_stage(stage: String, evidence: Dictionary) -> void:
	_stage_evidence = evidence.duplicate(true)
	var names := {"push": "03-natural-push", "left": "04-natural-left-turn", "right": "05-natural-right-turn"}
	_check(names.has(stage), "known shared natural input observer stage")
	await _capture(names.get(stage, "unexpected-stage"), "actual_input_stage",
		"Shared drive_natural_spawn stage " + stage + "; only actual Input actions since the ordinary default spawn. The observer freezes processing for this PNG, then resumes ordinary callbacks.")
	_stage_evidence.clear()

func _coast_and_brake() -> void:
	await _fixture(game.world.get_spawn_position(), 0.0)
	var evidence := Playability._evidence()
	var bails := [0]
	var callback := func(): bails[0] += 1
	game.skater.bailed.connect(callback)
	Input.action_press("push")
	await Playability._observe(get_tree(), game, 90, evidence)
	Playability._release()
	coast.launch_speed = game.skater.speed
	await Playability._observe(get_tree(), game, 180, evidence)
	coast.after_three_seconds = game.skater.speed
	_stage_evidence = evidence.duplicate(true)
	await _capture("06-natural-coast", "actual_input_stage", "Separate ordinary default-spawn initial fixture: push for 90 ticks, release for 180 ticks. No wall, velocity or heading assistance performs the slowing.")
	Input.action_press("brake")
	var ticks := 0
	while ticks < 120 and game.skater.speed > 0.05:
		await Playability._observe(get_tree(), game, 1, evidence)
		ticks += 1
	Playability._release()
	coast.brake_ticks = ticks
	coast.final_speed = game.skater.speed
	coast.evidence = evidence.duplicate(true)
	coast.bails = bails[0]
	_check(coast.launch_speed > 12.0 and coast.after_three_seconds > 0.2 and coast.after_three_seconds < 8.0
		and coast.final_speed <= 0.05 and evidence.wall_contacts == 0 and bails[0] == 0,
		"ordinary push release and actual brake stop without walls or bails")
	_stage_evidence = evidence.duplicate(true)
	await _capture("07-actual-brake-stop", "actual_input_stage", "Same separate coast run, followed by mapped brake until speed is at most 0.05 m/s. This proves active braking; the independent focused tests separately measure an automatic coast stop.")
	_stage_evidence.clear()
	game.skater.bailed.disconnect(callback)

func _park_views() -> void:
	# These grounded fixtures are checked against actual collision before publication.
	await _fixture_view("15-park-repaired-taper", Vector3(-234, game.world.get_ground_height(Vector3(-234, 0, -204)) + 0.8, -204), -PI / 2.0,
		"Initial supported park taper inspection; ordinary chase, not a completed off-route traversal.")
	await _fixture_view("16-park-visible-boundary", Vector3(-249, game.world.get_ground_height(Vector3(-249, 0, -160)) + 0.8, -160), PI / 2.0,
		"Initial supported park edge facing visible dry-land boundary; ordinary chase, not a physical boundary stress test.")

func _fixture_view(label: String, point: Vector3, heading: float, description: String) -> void:
	await _fixture(point, heading)
	_check(game.skater.is_on_floor(), label + " settled onto actual collision")
	await _capture(label, "initial_placement_chase", description)

func _fixture(point: Vector3, heading: float) -> void:
	_check(point.is_finite(), "fixture position is finite")
	await Playability._fixture(get_tree(), game, point, heading)

func _menu_ready(page: String) -> void:
	for tick in 90:
		await _frames(1)
		if game.hud._page == page and game.hud.is_menu_ready(): return
	_check(false, "production menu becomes ready: " + page)

func _capture(label: String, kind: String, fixture: String, require_body: bool = true) -> void:
	var states := [game.is_processing(), game.is_physics_processing(), game.skater.is_processing(), game.skater.is_physics_processing()]
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	# Allow ordinary idle callbacks to finish camera/HUD presentation of the actual physics state.
	await get_tree().process_frame
	await get_tree().process_frame
	game.set_process(false)
	game.skater.set_process(false)
	var sample := Playability.camera_sample(game)
	var visuals := _visual_snapshot()
	if require_body:
		_check(sample.current and sample.finite and sample.full_body and not sample.blocked and sample.distance >= 2.0,
			label + " ordinary current chase frames the rider and board without a blocked chest ray")
		_check(visuals.head.all_corners_in_frustum and visuals.board.all_corners_in_frustum, label + " actual head and deck mesh bounds are inside the frustum")
	var page: String = game.hud._page
	if not page.is_empty(): _check(game.hud.is_menu_ready(), label + " menu ready before draw")
	_draw_seen = false
	RenderingServer.frame_post_draw.connect(_on_draw, CONNECT_ONE_SHOT)
	RenderingServer.force_draw(true, 1.0 / 60.0)
	for tick in 8:
		if _draw_seen: break
		await get_tree().process_frame
	_check(_draw_seen, label + " actual frame_post_draw")
	if not _draw_seen and RenderingServer.frame_post_draw.is_connected(_on_draw): RenderingServer.frame_post_draw.disconnect(_on_draw)
	var frame := get_viewport().get_texture().get_image()
	_check(frame.get_size() == SIZE, label + " actual framebuffer 1280x800")
	_check(frame.save_png(output.path_join(label + ".png")) == OK, label + " PNG saved")
	if not page.is_empty(): _check(game.hud._page == page and game.hud.is_menu_ready(), label + " menu ready after draw")
	var camera: Camera3D = get_viewport().get_camera_3d()
	captures.append(_serialise({"file": label + ".png", "kind": kind, "fixture": fixture,
		"player_position": game.skater.global_position, "heading": game.skater.rotation.y, "speed": game.skater.speed,
		"on_floor": game.skater.is_on_floor(), "camera": sample, "visuals": visuals,
		"camera_node": str(camera.get_path()), "camera_position": camera.global_position, "camera_rotation": camera.global_rotation,
		"camera_fov": camera.fov, "menu_page": page, "menu_ready": game.hud.is_menu_ready(), "game_paused": game.paused,
		"input_stage_evidence": _stage_evidence, "held_actions": _held_actions(), "banked_score": game.score.total_score,
		"physics_frames": Engine.get_physics_frames(), "process_frames": Engine.get_process_frames()}))
	game.set_process(states[0])
	game.set_physics_process(states[1])
	game.skater.set_process(states[2])
	game.skater.set_physics_process(states[3])
	print("PLAYABILITY FRAME: ", label, " position=", game.skater.global_position, " camera=", sample)

func _visual_snapshot() -> Dictionary:
	var head := game.skater.get_node("SkaterVisual/Rider/TorsoRig/Head/AnatomicalHead") as MeshInstance3D
	var deck := game.skater.get_node("SkaterVisual/Board/DetailedSkateboard/TamSkateboard") as MeshInstance3D
	return {"head": _mesh_frame(head), "board": _mesh_frame(deck), "all_construction_checks_passed": _visual_checks.all(func(item): return item.ok)}

func _mesh_frame(mesh: MeshInstance3D) -> Dictionary:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var corners: Array[Dictionary] = []
	var inside := true
	var box := mesh.get_aabb()
	for i in 8:
		var point: Vector3 = mesh.global_transform * box.get_endpoint(i)
		var visible := camera.is_position_in_frustum(point)
		inside = inside and visible
		corners.append({"world": point, "screen": camera.unproject_position(point), "in_frustum": visible})
	return {"node": str(mesh.get_path()), "visible": mesh.is_visible_in_tree(), "mesh_surfaces": mesh.mesh.get_surface_count(),
		"position": mesh.global_position, "all_corners_in_frustum": inside, "corners": corners}

func _write_manifest() -> void:
	var boundaries: Array[Dictionary] = []
	for boundary: Node in get_tree().get_nodes_in_group("exploration_boundaries"):
		boundaries.append({"node": str(boundary.get_path()), "family": boundary.get_meta("boundary_family", ""),
			"points": boundary.get_meta("boundary_points", []), "height": boundary.get_meta("boundary_height", 0.0)})
	_check(boundaries.size() == 58, "current world exposes all 58 visible exploration boundaries")
	var report := {"schema_version": 5, "evidence_slice": "ordinary_launch_camera_response_and_exploration_repair",
		"recorded_at_utc": Time.get_datetime_string_from_system(true), "expected_captures": EXPECTED,
		"valid_capture_set": failures == 0 and captures.size() == EXPECTED, "failures": failures,
		"normal_scene_launch": not OS.get_cmdline_args().has("--script"), "actual_title_branch": _normal_title,
		"scene": "res://tools/playability_capture.tscn", "main_scene": "res://game/main.tscn",
		"engine": Engine.get_version_info(), "display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [SIZE.x, SIZE.y], "content_scale_override": true, "render_loop_enabled": RenderingServer.render_loop_enabled,
		"fixed_physics_hz": Engine.physics_ticks_per_second, "profile_writes_enabled": game.persistence_enabled,
		"performance_measurement": false, "target_hardware_acceptance": false, "human_fun_acceptance": false,
		"natural_driver": "tests/playability_regression_tests.gd::drive_natural_spawn",
		"natural_input_evidence": natural, "coast_and_brake": coast, "visual_construction_checks": _visual_checks,
		"route_count": routes.size(), "routes": routes, "checkpoints": game.world.get_district_checkpoints(),
		"exploration_boundary_count": boundaries.size(), "exploration_boundaries": boundaries,
		"fixture_limits": ["Normal CLI Node scene instantiates Main with persistence disabled before entering the tree; its ordinary title branch is used and visible FREE SKATE is activated by mapped Enter.",
			"Normal engine callbacks update player physics, rider pose, camera and HUD. No player/camera/pose method is manually called; no gameplay camera transform is authored.",
			"Natural push/left/right use only Input actions from the ordinary spawn. Coast/brake and diagnostic views explicitly reset once to initial supported fixtures.",
			"Static close/park/landmark views are inspection fixtures, not proof of traversal, natural route finding or a human playtest.",
			"Physics and player/Main processing pause only for still readback; ordinary callbacks resume afterward. Automatic rendering is disabled and each PNG is synchronously forced.",
			"Fixed 60 Hz input sampling and software-rendered stills are not continuous motion, real-time performance, Mac launch, physical-controller or owner fun acceptance.",
			"The independent focused module contains bidirectional close traversal, dry-boundary recovery and roof-collision checks; these static images do not substitute for those tests."],
		"captures": captures}
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	if not _check(file != null, "manifest writable"): return
	file.store_string(JSON.stringify(_serialise(report), "\t") + "\n")
	file.flush()
	_check(file.get_error() == OK, "manifest saved")
	file.close()

func _route_points(id: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for route: Dictionary in routes:
		if route.id == id:
			for point: Vector3 in route.points: result.append(point)
			return result
	_check(false, "route exists: " + id)
	return result

func _held_actions() -> Array[String]:
	var result: Array[String] = []
	for action: StringName in InputMap.get_actions():
		if Input.is_action_pressed(action): result.append(str(action))
	return result

func _visual_check(ok: bool, label: String) -> void:
	_visual_checks.append({"ok": ok, "label": label})
	_check(ok, label)

func _check(ok: bool, label: String) -> bool:
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	return ok

func _on_draw() -> void:
	_draw_seen = true

func _frames(count: int) -> void:
	await Playability._frames(get_tree(), count)

func _serialise(value: Variant) -> Variant:
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Vector2 or value is Vector2i: return [value.x, value.y]
	if value is float and not is_finite(value): return str(value)
	if value is Dictionary:
		var result := {}
		for key in value: result[str(key)] = _serialise(value[key])
		return result
	if value is Array or value is PackedVector3Array:
		var result: Array = []
		for item in value: result.append(_serialise(item))
		return result
	return value
