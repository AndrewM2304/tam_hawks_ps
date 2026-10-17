extends SceneTree
## Actual rendered terrain/map inspection. Authored placements are fixtures, not route playtests.
## Run tools/level_design_capture.sh; the wrapper publishes only a source-stable complete set.
const Main = preload("res://game/main.gd")
const CAPTURE_SIZE := Vector2i(1280, 800)
const EXPECTED_CAPTURES := 34
const AREA_IDS: Array[String] = ["royal_exchange", "george_square", "central_station", "barras", "clyde", "kelvingrove"]
var game: Node
var failures := 0
var output := ""
var captures: Array[Dictionary] = []
var checkpoints: Dictionary
var routes: Array
var _post_draw_seen := false
var _cat_capture_ids: Array[String] = []
var _cat_payoff_trigger: Dictionary = {}
var _capture_cat_motion := false
var _cat_motion: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("LEVEL CAPTURE requires a graphical renderer; headless is not image evidence.")
		quit(2)
		return
	if not _read_arguments():
		quit(2)
		return
	RenderingServer.render_loop_enabled = false
	root.size = CAPTURE_SIZE
	root.content_scale_size = CAPTURE_SIZE
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	game.set_process_unhandled_input(false)
	checkpoints = game.world.get_district_checkpoints()
	routes = game.world.get_route_definitions()
	for area: String in AREA_IDS:
		_check(checkpoints.has(area), "world checkpoint exists: " + area)
	_check(not routes.is_empty(), "world supplies authored route data")
	if failures:
		quit(1)
		return
	await _chase("01-exchange-spawn", checkpoints.royal_exchange, 0.0, "World spawn checkpoint; northbound approach with fountain beside the line.")
	var gallery := _route_point("gallery_civic_ascent", 2)
	if gallery.is_finite():
		gallery.z -= 6.0
		await _chase("02-gallery-descent", gallery, PI, "Positioned on the gallery terrace, facing down toward the fountain court.")
	await _chase("03-george-civic-rise", checkpoints.george_square, 0.0, "World George checkpoint; civic bank and higher terrace ahead.")
	await _chase("04-central-platforms", checkpoints.central_station, PI / 4.0, "World Central checkpoint; real station canopy and elevated platform line.")
	await _chase("05-barras-loading-street", checkpoints.barras, 0.0, "World Barras checkpoint; market and higher loading-street approach.")
	var river_gap := _gap("clyde_bridge_transfer")
	if not river_gap.is_empty():
		var direction: Vector3 = river_gap.end - river_gap.start
		direction.y = 0.0
		direction = direction.normalized()
		await _chase("06-clyde-bridge-approach", river_gap.start - direction * 6.0,
			atan2(-direction.x, -direction.z), "Positioned six metres before the actual Clyde gap start; no jump execution is implied.")
	var park := _park_approach()
	if not park.is_empty():
		await _chase("07-kelvingrove-climb", park.position, park.heading,
			"Low point of the authored kelvingrove_rolling_loop, facing its next point; static climb inspection.")
	await _route_chase("14-station-undercroft", "station_low_level_close", 2)
	await _route_chase("15-merchant-close", "merchant_close_cutthrough")
	await _route_chase("16-park-cutback", "kelvingrove_cutback_return")
	await _route_chase("17-clyde-print-yard", "clyde_print_yard_hip")
	await _route_chase("19-merchant-close-return", "merchant_close_cutthrough", -1, true)
	await _route_chase("20-park-cutback-join", "kelvingrove_cutback_return", -1, true)
	await _route_chase("21-clyde-hip-return", "clyde_print_yard_hip", -1, true)
	await _overview("08-core-terraces-overview", false)
	await _overview("09-six-area-overview", true)
	await _map_view()
	await _busker_views()
	await _court_views()
	await _cat_views()
	var report: Dictionary = {
		"schema_version": 3, "evidence_slice": "bin_drumming_and_dancing_cats_correction", "expected_captures": EXPECTED_CAPTURES, "recorded_at_utc": Time.get_datetime_string_from_system(true),
		"valid_capture_set": failures == 0 and captures.size() == EXPECTED_CAPTURES, "failures": failures,
		"engine": Engine.get_version_info(), "display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "resolution": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"content_scale_override": true, "render_loop_enabled": RenderingServer.render_loop_enabled,
		"fixed_physics_hz": Engine.physics_ticks_per_second, "profile_writes_enabled": game.persistence_enabled,
		"settings": game.career.settings.duplicate(true), "gameplay_input_injected": true,
		"performance_measurement": false, "target_hardware_acceptance": false,
		"fixture_limits": ["Chase views position the production skater on authored ground and settle actual physics; they are not completed routes.",
			"Overview cameras are explicitly authored inspection viewpoints, with the HUD hidden.",
			"The map is the real production page opened through show_map(), with readiness checked around the actual draw.",
			"Busker images position a supported rider, then use actual interact/ollie/flip/grab input actions and runtime banking; no trick, score or encounter completion is injected.",
			"Cat states come from real production rail-capture events and a positive clean bank; direct grounded heading, if used, is explicitly idealized. No encounter completion is injected.",
			"Automatic rendering is disabled; force_draw produces each captured frame after 60 Hz fixture steps. No real-time FPS claim."],
		"checkpoints": _serialise(checkpoints), "routes": _serialise(routes), "cat_payoff_trigger": _serialise(_cat_payoff_trigger), "cat_motion": _serialise(_cat_motion), "captures": captures,
	}
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		_check(false, "manifest opens for writing")
	else:
		file.store_string(JSON.stringify(report, "\t") + "\n")
		file.flush()
		_check(file.get_error() == OK, "manifest writes successfully")
		file.close()
	paused = false
	print("LEVEL CAPTURE RESULT: %d frames, %d failures; no profile writes or performance claim" % [captures.size(), failures])
	quit(0 if failures == 0 and captures.size() == EXPECTED_CAPTURES else 1)


func _read_arguments() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1 or args.size() > 2: return false
	if args.size() == 2:
		if args[1] != "--cat-motion": return false
		_capture_cat_motion = true
	output = ProjectSettings.globalize_path(args[0]).simplify_path()
	var local := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	if not (output + "/").begins_with(local): return false
	return DirAccess.make_dir_recursive_absolute(output) == OK


func _chase(label: String, authored_position: Vector3, heading: float, fixture: String) -> void:
	paused = false
	game.hud.hide_menu()
	game.set_process(true)
	game.set_physics_process(true)
	game.skater.set_process(true)
	# Route points carry the intended surface Y. At stacked station routes the
	# highest ground is the upper deck; select support near this route's level.
	var ground: float = game.world.get_support_height(authored_position) if game.world.has_method("get_support_height") else game.world.get_ground_height(authored_position)
	if not _check(is_finite(ground), label + " has authored ground"): return
	game.skater.spawn_position = Vector3(authored_position.x, ground + 0.8, authored_position.z)
	game.restart_run()
	game.skater.rotation.y = heading
	game.skater.set_controls_enabled(false)
	game.skater._camera.current = true
	game.hud.visible = true
	await _frames(100)
	if not _check(game.skater.is_on_floor(), label + " settles on actual collision"): return
	if not _check(absf(game.skater.global_position.y - ground) < 0.06, label + " settles on the intended terrain, not atop a prop"): return
	var body_shape: CollisionShape3D = game.skater.get_node("BodyCollision")
	var clearance := PhysicsShapeQueryParameters3D.new()
	clearance.shape = body_shape.shape
	clearance.transform = body_shape.global_transform
	clearance.transform.origin.y += 0.08
	clearance.collision_mask = 1
	clearance.exclude = [game.skater.get_rid()]
	if not _check(game.skater.get_world_3d().direct_space_state.intersect_shape(clearance, 8).is_empty(), label + " has body clearance above the intended ground"): return
	game._refresh_hud()
	_freeze_player()
	await _capture(label, "production_chase", fixture)


func _route_chase(label: String, id: String, index: int = 0, reverse: bool = false) -> void:
	var at := _route_point(id, index)
	var next := _route_point(id, index - 1 if reverse else index + 1)
	if not at.is_finite() or not next.is_finite(): return
	var direction := next - at
	if not _check(Vector2(direction.x, direction.z).length() > 0.01, label + " has a nonzero authored heading"): return
	await _chase(label, at, atan2(-direction.x, -direction.z),
		"Positioned at point %d of runtime route %s, facing the %s point. Intended support selected near the route height; static route/clearance inspection, not a completed traversal." % [index, id, "previous" if reverse else "next"])


func _overview(label: String, whole_level: bool) -> void:
	_freeze_player()
	game.hud.visible = false
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for route: Dictionary in routes:
		for point: Vector3 in route.get("points", []):
			if not whole_level and (point.x < -135.0 or point.x > 140.0 or point.z < -130.0 or point.z > 45.0): continue
			minimum = minimum.min(point)
			maximum = maximum.max(point)
	if not _check(minimum.is_finite() and maximum.is_finite(), label + " has route bounds"): return
	var centre := (minimum + maximum) * 0.5
	var span := maxf(maximum.x - minimum.x, maximum.z - minimum.z) + 60.0
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = centre + Vector3(span * 0.45, span * 0.75, span * 0.65)
	camera.look_at(centre, Vector3.UP)
	camera.fov = 55.0
	camera.far = maxf(800.0, span * 4.0)
	camera.current = true
	await _frames(2)
	await _capture(label, "authored_overview", "Inspection camera derived from %s route bounds; HUD hidden; not the playable chase camera." % ("six-area" if whole_level else "core"))
	camera.queue_free()
	await process_frame
	game.skater._camera.current = true
	game.hud.visible = true


func _map_view() -> void:
	await _chase_position_only(checkpoints.royal_exchange)
	game.hud.show_map()
	for i in 180:
		await process_frame
		if game.hud._page == "map" and game.hud.is_menu_ready(): break
	if not _check(game.hud._page == "map" and game.hud.is_menu_ready(), "map page ready before draw"): return
	await _capture("10-city-map-routes", "production_menu", "Real CITY MAP & ROUTES page opened by show_map(); player reset to the authored spawn; readiness checked before/after rendering.", true)
	game.hud.hide_menu()
	paused = false
	game.restart_run()
	_freeze_player()


func _chase_position_only(position: Vector3) -> void:
	paused = false
	game.set_process(true)
	game.set_physics_process(true)
	game.skater.set_process(true)
	game.skater.spawn_position = position
	game.restart_run()
	game.skater.set_controls_enabled(false)
	await _frames(100)
	game._refresh_hud()
	_freeze_player()


func _busker_views() -> void:
	if not _check(is_instance_valid(game.get("encounters")), "production encounter integration exists"): return
	var initial: Dictionary = game.encounters.status_snapshot()
	var anchor: Vector3 = initial.get("position", Vector3.INF)
	if not _check(anchor.is_finite(), "Mo has an authored world position"): return
	await _chase("11-busker-offer", anchor + Vector3(0, 0, 3.0), 0.0,
		"Positioned on supported ground three metres from the original fictional busker; production approach prompt and actor.")
	await _busker_medium(anchor)
	_resume_player()
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(2)
	if not _check(game.encounters.status_snapshot().get("state") == "active", "actual interact starts the busker challenge"):
		_freeze_player()
		return
	Input.action_press("ollie")
	await _frames(3)
	Input.action_release("ollie")
	Input.action_press("flip")
	Input.action_press("grab")
	await _frames(12)
	Input.action_release("flip")
	Input.action_release("grab")
	var active: Dictionary = game.encounters.status_snapshot()
	if not _check(active.get("state") == "active" and int(active.get("family_count", 0)) >= 3,
		"actual aerial inputs supply three distinct busker trick families"):
		_freeze_player()
		return
	game._refresh_hud()
	_freeze_player()
	await _capture("12-busker-active-line", "production_challenge",
		"Actual interact, ollie, flip and grab actions from a positioned supported rider; three real trick families in the pending line. Frozen for this image; no score/event injection.")
	_resume_player()
	for frame in 180:
		await _frames(1)
		if game.encounters.status_snapshot().get("state") == "success": break
	var completed: Dictionary = game.encounters.status_snapshot()
	if not _check(completed.get("state") == "success" and int(completed.get("wins", 0)) == 1 and game.score.total_score >= 1000,
		"actual landing and bank complete the optional busker challenge once"):
		_freeze_player()
		return
	game._refresh_hud()
	_freeze_player()
	await _capture("13-busker-success", "production_challenge",
		"Same actual-input attempt after production landing/banking; success and one win asserted. No career profile writes or direct trick/score/encounter event injection.")


func _busker_medium(anchor: Vector3) -> void:
	var actor: Node3D = game.encounters.get_node_or_null("MoBusker")
	if not _check(is_instance_valid(actor), "original Mo actor exists for the medium view"): return
	game.hud.visible = false
	game.skater.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = anchor + actor.global_basis * Vector3(1.65, 1.85, -4.0)
	camera.look_at(anchor + Vector3(0, 1.05, 0))
	camera.fov = 38.0
	camera.current = true
	await _capture("18-busker-medium", "authored_character_view",
		"Authored three-quarter camera for actual Mo geometry, guitar, hands and planted shoes in the production world; HUD and unrelated player visual hidden only for this isolated actor frame. No likeness or music claim.")
	camera.queue_free()
	await process_frame
	game.skater._camera.current = true
	game.hud.visible = true
	game.skater.visible = true


func _court_views() -> void:
	# These authored inspection positions preserve the protected court approaches.
	# They are not a claim that the player completed the optional technical line.
	await _chase("22-george-workshop-approach", Vector3(-22, 4, -74), atan2(-22.0, 17.0),
		"Authored supported south George approach, aimed toward the workshop/garden pocket; actual chase camera, not a completed route.")
	await _chase("23-barras-west-market", Vector3(86, 0, 11), atan2(14.0, 3.0),
		"Authored supported Barras aisle approach aimed toward (72,0.65,8), showing the attached brick hall, chamfered bank/skirt and clear beginner aisle.")
	await _chase("24-barras-aisle-return", Vector3(82, 0, 17), atan2(12.0, 7.0),
		"Authored supported southeast Barras return aimed toward (70,0.65,10), clear of the existing market stall; static place/exit inspection.")
	await _chase("25-cat-course-west", Vector3(-28, 4, -91), -PI / 2.0,
		"Authored supported west approach to three independently numbered coping benches; actual chase camera aimed east.")
	await _chase("26-cat-course-return", Vector3(22, 4, -91), PI / 2.0,
		"Authored supported east runout, facing the cat coping sequence in reverse; beginner return remains visible.")


func _cat_views() -> void:
	if not _check(is_instance_valid(game.get("cat_encounter")), "production cat encounter integration exists"): return
	var initial: Dictionary = game.cat_encounter.status_snapshot()
	var anchor: Vector3 = initial.get("position", Vector3.INF)
	if not _check(anchor.is_finite(), "Rae has an authored supported world anchor"): return
	await _chase("27-cat-offer", anchor + Vector3(0, 0, 3.0), 0.0,
		"Positioned on actual support three metres in front of the original bin-busking pitch; production drummer, bin percussion and dancing cats and input-aware offer.")
	await _cat_medium(anchor)
	_resume_player()
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(2)
	if not _check(game.cat_encounter.status_snapshot().get("state") == "active", "actual interact starts the cat challenge"):
		_freeze_player()
		return
	# The driver is explicitly idealized only in grounded heading. Production
	# push/brake/ollie/grind inputs move the body; no position/speed/score or
	# capture callback is written after the initial supported offer placement.
	for target: Vector3 in [Vector3(-22, 4, -95), Vector3(-28, 4, -91)]:
		if not await _cat_drive_to(target): return
	var ids: Array = initial.get("required_ids", [])
	if not _check(ids.size() == 3, "cat challenge supplies three ordered runtime rail IDs"): return
	_cat_capture_ids.clear()
	game.skater.grind_captured.connect(_record_cat_capture)
	var prior = null
	for index in ids.size():
		var line = null
		for candidate in game.world.get_grind_lines():
			if candidate.id == ids[index]: line = candidate
		if not _check(line != null and line.is_valid, "cat capture fixture resolves real track " + str(ids[index])): return
		if index == 0:
			if not await _cat_capture_track(line, index): return
		else:
			if not await _cat_transfer(prior, line, index): return
		Input.action_release("push")
		Input.action_release("ollie")
		game._refresh_hud()
		_freeze_player()
		await _capture("%02d-cat-capture-%s" % [29 + index, ["a", "b", "c"][index]], "production_challenge",
			"Same continuous attempt after actual production capture of %s; sequence progress %d/3 asserted from real grind signals. The rider approaches through push/brake and transfers through actual rail ollies; only grounded heading is directly aimed, with no post-start position, speed, callback or score injection." % [ids[index], index + 1])
		_resume_player()
		prior = line
	_release_fixture_inputs()
	for frame in 100:
		if game.skater.is_on_floor(): Input.action_press("brake")
		await _frames(1)
	_release_fixture_inputs()
	var completed: Dictionary = game.cat_encounter.status_snapshot()
	if not _check(completed.get("state") == "success" and int(completed.get("sequence_index", 0)) == 3 and int(completed.get("wins", 0)) == 1 and game.score.total_score == 1050 and _cat_capture_ids == ids,
		"three actual ordered coping captures and the earned 1050 bank complete the cat challenge once"): return
	game.skater.grind_captured.disconnect(_record_cat_capture)
	game._refresh_hud()
	_freeze_player()
	await _capture("32-cat-success", "production_challenge",
		"Same continuous attempt after all three production captures and a positive clean bank, with exactly one win. Direct grounded heading is an explicit fixture idealization; no fake capture, score, progress or win injection.")
	await _cat_payoff_views(anchor)


func _cat_payoff_views(anchor: Vector3) -> void:
	var actor: Node3D = game.cat_encounter.get_node("RaeBinBusker")
	if not _check(game.cat_encounter.status_snapshot().get("celebration_state") == "queued" and not actor.animation_snapshot().dance_active,
		"the offscreen earned cat payoff remains queued before the real return"): return
	_resume_player()
	for frame in 240:
		var offset := Vector3(4.0 - game.skater.global_position.x, 0, -93.0 - game.skater.global_position.z)
		_cat_aim(offset)
		Input.action_press("push")
		await _frames(1)
		if game.cat_encounter.status_snapshot().get("celebration_started", false):
			var relative: Vector3 = game.skater.global_position - anchor
			_cat_payoff_trigger = {"return_frames": frame + 1, "player_position": game.skater.global_position,
				"distance": Vector2(relative.x, relative.z).length(),
				"stage_in_production_chase_frustum": game.skater._camera.is_position_in_frustum(anchor + Vector3(0, 0.8, 0)),
				"camera_position": game.skater._camera.global_position, "camera_rotation": game.skater._camera.global_rotation,
				"banked_score": game.score.total_score, "wins": game.cat_encounter.status_snapshot().wins}
			break
	_release_fixture_inputs()
	if not _check(not _cat_payoff_trigger.is_empty() and _cat_payoff_trigger.stage_in_production_chase_frustum
		and _cat_payoff_trigger.distance <= 10.0 and actor.animation_snapshot().dance_active
		and game.score.total_score == 1050 and game.cat_encounter.status_snapshot().wins == 1,
		"actual return and the production chase frustum trigger one earned cat dance"): return
	_freeze_player()
	# Only ordinary actor processing advances this already-earned response.
	# The authored camera is created after production visibility triggered it.
	if _capture_cat_motion:
		await _cat_stage_motion(anchor, actor)
	else:
		await _frames(35)
		await _cat_medium(anchor, "33-cat-earned-payoff",
			"Same real 1,050-point win after a push-driven return within 10 m and production chase-frustum visibility triggered the queued 3.2-second response. Player movement freezes for inspection; normal actor animation advances before this authored stage camera shows the live bin-drumming/dancing-cat pose. No success, animation time, visibility or reward is injected; unrelated rider/HUD are hidden only for framing.")
		if not _check(actor.animation_snapshot().dance_active, "earned cat dance is still live in its actual stage capture"): return
	var prior_motion: bool = game.career.settings.reduced_motion
	game.apply_settings({"reduced_motion": true}, false)
	if not _check(actor.animation_snapshot().reduced_motion and not actor.animation_snapshot().dance_active,
		"public reduced-motion preference selects the earned static alternative"): return
	await _cat_medium(anchor, "34-cat-reduced-motion",
		"Same real earned success, with the public reduced-motion preference enabled through Main.apply_settings(persist=false). The actor shows its static raised-paw alternative and steady charged A/B/C indicators. Authored stage camera hides only unrelated rider/HUD; no replay, score, win or animation-state injection.")
	game.apply_settings({"reduced_motion": prior_motion}, false)


func _cat_stage_motion(anchor: Vector3, actor: Node3D) -> void:
	var frame_dir := output.path_join("cat-motion-frames")
	if not _check(DirAccess.make_dir_recursive_absolute(frame_dir) == OK, "cat motion output opens"): return
	game.hud.visible = false
	game.skater.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = anchor + Vector3(4.0, 2.4, 5.0)
	camera.look_at(anchor + Vector3(0, 0.95, 0))
	camera.fov = 42.0
	camera.current = true
	var samples: Array[Dictionary] = []
	var active_frames := 0
	var finished_frames := 0
	for index in 100:
		# Advance ordinary process callbacks for two physics ticks, then hold the
		# actor only during draw/readback. No animation phase/state is assigned.
		actor.set_process(true)
		await _frames(2)
		actor.set_process(false)
		var snapshot: Dictionary = actor.animation_snapshot().duplicate(true)
		_post_draw_seen = false
		RenderingServer.frame_post_draw.connect(_on_post_draw, CONNECT_ONE_SHOT)
		RenderingServer.force_draw(true, 1.0 / 60.0)
		for attempt in 8:
			if _post_draw_seen: break
			await process_frame
		if not _check(_post_draw_seen, "cat motion actual frame_post_draw"):
			if RenderingServer.frame_post_draw.is_connected(_on_post_draw): RenderingServer.frame_post_draw.disconnect(_on_post_draw)
			break
		var rendered := root.get_texture().get_image()
		if not _check(rendered.get_size() == CAPTURE_SIZE, "cat motion actual framebuffer size"): break
		var filename := "%05d.png" % index
		if not _check(rendered.save_png(frame_dir.path_join(filename)) == OK, "cat motion frame saved"): break
		if snapshot.get("dance_active", false): active_frames += 1
		else: finished_frames += 1
		samples.append({"file": filename, "frame_index": index, "animation": _serialise(snapshot),
			"banked_score": game.score.total_score, "wins": game.cat_encounter.status_snapshot().wins})
		if index == 20:
			if _check(snapshot.get("dance_active", false), "motion still shows the live earned response"):
				var label := "33-cat-earned-payoff"
				_check(rendered.save_png(output.path_join(label + ".png")) == OK, "live payoff still saved from actual motion frame")
				_record_capture(label, "authored_character_view", "Actual frame 20 from the same earned bin-drumming/dancing-cat motion recording. Real A/B/C captures banked 1,050 once; the physical return and production chase frustum triggered the response before this authored stage camera. Ordinary animation callbacks advance two physics ticks per sample and pause only for image readback. No phase, score, win or visibility is injected; unrelated rider/HUD are hidden.")
		if index % 20 == 0: print("CAT MOTION FRAME: ", index)
	actor.set_process(true)
	_cat_motion = {"frame_count": samples.size(), "encoded_fps": 30, "silent": true,
		"active_frames": active_frames, "finished_frames": finished_frames, "frames": samples,
		"camera_position": _serialise(camera.global_position), "camera_rotation": _serialise(camera.global_rotation),
		"fixture": "Same actual earned response after physical return; authored stage camera and hidden unrelated rider/HUD. Normal actor callbacks advance two physics ticks per sample; actor processing pauses only during draw/readback. Silent 30 fps presentation, not real-time rendering, output-audio, human play or Mac performance evidence."}
	_check(samples.size() == 100 and active_frames > 30 and finished_frames > 0,
		"cat motion records the actual bounded response through its finish")
	_check(game.score.total_score == 1050 and game.cat_encounter.status_snapshot().wins == 1,
		"cat motion preserves the sole actual earned win")
	camera.queue_free()
	await process_frame
	game.skater._camera.current = true
	game.hud.visible = true
	game.skater.visible = true


func _cat_medium(anchor: Vector3, label: String = "28-bin-busker-medium", fixture: String = "") -> void:
	var actor: Node3D = game.cat_encounter.get_node_or_null("RaeBinBusker")
	if not _check(is_instance_valid(actor), "original bin-busking actor exists"): return
	game.hud.visible = false
	game.skater.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = anchor + Vector3(4.0, 2.4, 5.0)
	camera.look_at(anchor + Vector3(0, 0.95, 0))
	camera.fov = 42.0
	camera.current = true
	if fixture.is_empty():
		fixture = "Authored three-quarter inspection camera for the original fictional drummer, fake-bin percussion, dancing-cat figures and steady A/B/C stage indicators; unrelated player visual and HUD hidden only in this medium view. No injected challenge or animation state."
	await _capture(label, "authored_character_view", fixture)
	camera.queue_free()
	await process_frame
	game.skater._camera.current = true
	game.hud.visible = true
	game.skater.visible = true


func _cat_animation_snapshot() -> Dictionary:
	if not is_instance_valid(game.get("cat_encounter")): return {}
	var actor: Node3D = game.cat_encounter.get_node_or_null("RaeBinBusker")
	return actor.animation_snapshot() if is_instance_valid(actor) else {}


func _cat_drive_to(target: Vector3, expected_state: String = "active") -> bool:
	# Same actual-input recipe independently verified by the cat QE fixture.
	for frame in 360:
		var offset: Vector3 = target - game.skater.global_position
		offset.y = 0.0
		if offset.length() < 0.65:
			_release_fixture_inputs()
			return true
		_cat_aim(offset)
		if game.skater.speed > sqrt(30.0 * offset.length()):
			Input.action_release("push")
			Input.action_press("brake")
		else:
			Input.action_release("brake")
			Input.action_press("push")
		await _frames(1)
		if game.cat_encounter.status_snapshot().get("state") != expected_state: break
	_release_fixture_inputs()
	return _check(false, "cat actual-input approach reaches " + str(target))


func _cat_aim(direction: Vector3) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	var desired := atan2(-direction.x, -direction.z)
	if game.skater.is_on_floor(): game.skater.rotation.y = desired
	else:
		var difference := angle_difference(game.skater.rotation.y, desired)
		if absf(difference) > 0.04:
			Input.action_press("steer_left" if difference > 0.0 else "steer_right", minf(1.0, absf(difference) * 4.0))


func _cat_transfer(prior, line, index: int) -> bool:
	var tangent: Vector3 = prior.dir_at(2.0)
	var exit_point: Vector3 = prior.point_at(prior.length - 1.0)
	for frame in 90:
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if game.skater.grind_balance > 0.05: Input.action_press("steer_left")
		elif game.skater.grind_balance < -0.05: Input.action_press("steer_right")
		if (exit_point - game.skater.global_position).dot(tangent) <= 0.0: break
		await _frames(1)
		if not game.skater.grinding: break
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	Input.action_press("ollie")
	await _frames(1)
	Input.action_release("ollie")
	for frame in 120:
		_cat_aim(tangent)
		await _frames(1)
		var snapshot: Dictionary = game.cat_encounter.status_snapshot()
		if snapshot.get("state") != "active": break
		if game.skater.grinding and _cat_capture_ids.has(line.id) and int(snapshot.get("sequence_index", 0)) == index + 1:
			return true
	_release_fixture_inputs()
	return _check(false, "actual rail ollie transfers to expected cat track " + line.id)


func _record_cat_capture(id: String) -> void:
	_cat_capture_ids.append(id)


func _cat_capture_track(line, index: int) -> bool:
	var tangent: Vector3 = line.dir_at(0.0)
	var target: Vector3 = line.point_at(2.0)
	var launched := false
	for frame in 240:
		_cat_aim(tangent)
		Input.action_press("push")
		Input.action_press("grind")
		if not launched and (target - game.skater.global_position).dot(tangent) < 9.5:
			Input.action_press("ollie")
			launched = true
		else: Input.action_release("ollie")
		await _frames(1)
		var snapshot: Dictionary = game.cat_encounter.status_snapshot()
		if snapshot.get("state") != "active": break
		if game.skater.grinding and _cat_capture_ids.has(line.id) and int(snapshot.get("sequence_index", 0)) == index + 1:
			Input.action_release("ollie")
			return true
	_release_fixture_inputs()
	return _check(false, "actual ollie/grind captures expected cat track " + line.id)


func _release_fixture_inputs() -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)


func _resume_player() -> void:
	game.set_process(true)
	game.set_physics_process(true)
	game.skater.set_process(true)
	game.skater.set_physics_process(true)
	game.skater.set_controls_enabled(true)


func _freeze_player() -> void:
	game.set_process(false)
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)


func _capture(label: String, kind: String, fixture: String, require_map: bool = false) -> void:
	for i in 8: await process_frame
	if require_map and not _check(game.hud._page == "map" and game.hud.is_menu_ready(), label + " remains ready before draw"): return
	_post_draw_seen = false
	RenderingServer.frame_post_draw.connect(_on_post_draw, CONNECT_ONE_SHOT)
	RenderingServer.force_draw(true, 1.0 / 60.0)
	for i in 8:
		if _post_draw_seen: break
		await process_frame
	if not _check(_post_draw_seen, label + " emitted frame_post_draw"):
		if RenderingServer.frame_post_draw.is_connected(_on_post_draw): RenderingServer.frame_post_draw.disconnect(_on_post_draw)
		return
	if require_map and not _check(game.hud._page == "map" and game.hud.is_menu_ready(), label + " remains ready after draw"): return
	var captured := root.get_texture().get_image()
	if not _check(captured.get_size() == CAPTURE_SIZE, label + " actual framebuffer size"): return
	if not _check(captured.save_png(output.path_join(label + ".png")) == OK, label + " saved"): return
	_record_capture(label, kind, fixture)


func _record_capture(label: String, kind: String, fixture: String) -> void:
	var camera: Camera3D = root.get_camera_3d()
	captures.append({"file": label + ".png", "kind": kind, "fixture": fixture,
		"player_position": _serialise(game.skater.global_position), "player_heading": game.skater.rotation.y,
		"ground_height": game.world.get_ground_height(game.skater.global_position),
		"support_height": game.world.get_support_height(game.skater.global_position) if game.world.has_method("get_support_height") else game.world.get_ground_height(game.skater.global_position),
		"supported": game.skater.is_on_floor(),
		"camera_position": _serialise(camera.global_position), "camera_rotation": _serialise(camera.global_rotation),
		"camera_fov": camera.fov, "camera_far": camera.far, "hud_visible": game.hud.visible,
		"player_visual_visible": game.skater.visible,
		"menu_page": game.hud._page, "menu_ready": game.hud.is_menu_ready(), "paused": paused,
		"encounter": _serialise(game.encounters.status_snapshot()) if is_instance_valid(game.get("encounters")) else {},
		"cat_encounter": _serialise(game.cat_encounter.status_snapshot()) if is_instance_valid(game.get("cat_encounter")) else {},
		"observed_cat_capture_ids": _cat_capture_ids.duplicate(),
		"cat_animation": _cat_animation_snapshot(), "presentation_settings": game.career.settings.duplicate(true),
		"banked_score": game.score.total_score, "pending_combo": game.score.get_combo_value(),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	print("LEVEL CAPTURE: ", label, " size=", CAPTURE_SIZE, " kind=", kind)


func _on_post_draw() -> void:
	_post_draw_seen = true


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


func _route_point(id: String, index: int) -> Vector3:
	for route: Dictionary in routes:
		if route.get("id", "") != id: continue
		var count: int = route.get("points", []).size()
		var resolved := count + index if index < 0 else index
		if resolved >= 0 and resolved < count:
			return route.points[resolved]
	_check(false, "required authored route point exists: " + id)
	return Vector3.INF


func _gap(id: String) -> Dictionary:
	for gap: Dictionary in game.world.get_gap_definitions():
		if gap.get("id", "") == id: return gap
	_check(false, "required authored gap exists: " + id)
	return {}


func _park_approach() -> Dictionary:
	var best: Array = []
	var highest := -INF
	for route: Dictionary in routes:
		if route.get("id", "") != "kelvingrove_rolling_loop": continue
		var points: Array = []
		for point: Vector3 in route.get("points", []): points.append(point)
		if points.size() < 2: continue
		best = points
		for point: Vector3 in points:
			highest = maxf(highest, point.y)
	if not _check(best.size() >= 2 and highest > 10.0, "authored park climb reaches its hill"): return {}
	var lowest_index := 0
	for i in best.size():
		if best[i].y < best[lowest_index].y: lowest_index = i
	var next_index := lowest_index + 1 if lowest_index + 1 < best.size() else lowest_index - 1
	var direction: Vector3 = best[next_index] - best[lowest_index]
	return {"position": best[lowest_index], "heading": atan2(-direction.x, -direction.z)}


func _check(condition: bool, label: String) -> bool:
	if not condition:
		failures += 1
		push_error("LEVEL CAPTURE: " + label)
	return condition


func _serialise(value: Variant) -> Variant:
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Dictionary:
		var result := {}
		for key: Variant in value: result[str(key)] = _serialise(value[key])
		return result
	if value is Array or value is PackedVector3Array:
		var result: Array = []
		for item: Variant in value: result.append(_serialise(item))
		return result
	return value
