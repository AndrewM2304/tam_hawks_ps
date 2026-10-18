extends "res://tools/moving_profile.gd"
## Bounded existing-frontage acceptance. Reuses the ordinary moving diagnostic's
## input driver and admission limits; no production per-frame feature is added.

const Bay = preload("res://game/levels/art/facade_bay.gd")
const Playability = preload("res://tests/playability_regression_tests.gd")
var _enabled := false
var _mode := ""
var _views: Array[Dictionary] = []
var _inspection: Camera3D


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 7 or DisplayServer.get_name() == "headless":
		quit(2)
		return
	_mode = args[0]
	_enabled = args[1] == "on"
	_output = ProjectSettings.globalize_path(args[2]).simplify_path()
	_size = Vector2i(int(args[3]), int(args[4]))
	_duration = float(args[5])
	_quality = args[6]
	var allowed := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	if not _mode in ["capture", "profile"] or not args[1] in ["on", "off"] \
			or not (_output + "/").begins_with(allowed) or not Quality.IDS.has(_quality) \
			or _size.x < 320 or _size.x > 1920 or _size.y < 200 or _size.y > 1080 \
			or _duration < 5 or _duration > 120 or not RenderingServer.render_loop_enabled \
			or not is_equal_approx(Engine.time_scale, 1.0):
		quit(2)
		return
	for arg: String in OS.get_cmdline_args():
		if arg in ["--fixed-fps", "--disable-render-loop"] or arg.begins_with("--fixed-fps="):
			quit(2)
			return
	if DirAccess.make_dir_recursive_absolute(_output) != OK:
		quit(2)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = _size
	root.content_scale_size = _size
	game = Main.new()
	game.persistence_enabled = false
	game.set_meta(&"facade_bay_enabled", _enabled)
	root.add_child(game)
	game.apply_settings({"graphics_quality":_quality}, false)
	game.start_mode(true)
	game.skater.set_controls_enabled(false)
	game.skater.set_trick_entries_enabled(false)
	var selected := 0
	for node: Node in game.world.get_children():
		if bool(node.get_meta(Bay.META, false)): selected += 1
	if selected != (1 if _enabled else 0): _errors.append("Unexpected pilot construction count.")
	_inspection = Camera3D.new()
	_inspection.fov = game.skater._camera.fov
	_inspection.near = 0.2
	_inspection.far = 220
	root.add_child(_inspection)
	await _settle()
	var started := Time.get_ticks_usec()
	if _mode == "capture":
		await _capture("01-spawn", "ordinary production spawn and chase", true)
		for fixture: Dictionary in _fixtures():
			_inspection.position = fixture.at
			_inspection.look_at(fixture.target)
			_inspection.current = true
			await _capture(fixture.id, "authored inspection camera; no traversal claim", false)
		for fixture: Dictionary in [{"id":"06-west-wall-chase", "at":Vector3(-32,1.25,4), "yaw":-PI/2},
			{"id":"07-west-join-chase", "at":Vector3(-31,1.25,9.5), "yaw":PI/2}]:
			game.skater.spawn_position = fixture.at
			game.restart_run()
			game.skater.rotation.y = fixture.yaw
			game.skater.set_controls_enabled(false)
			game.skater._camera.current = true
			await _settle()
			await _capture(fixture.id, "one supported fixture; ordinary production chase callbacks", true)
	else:
		await _stationary("spawn", started)
		for fixture: Dictionary in _fixtures().slice(0, 2):
			_inspection.position = fixture.at
			_inspection.look_at(fixture.target)
			_inspection.current = true
			await _stationary(fixture.id, started)
		game.skater._camera.current = true
		_driver = RouteDriver.new()
		_driver.profiler = self
		_driver.process_physics_priority = -100
		root.add_child(_driver)
		game.skater.bailed.connect(func(): _bails += 1 if _driving else 0)
		var found := false
		for route: Dictionary in game.world.get_route_definitions():
			if route.id == "exchange_west_bank_loop":
				found = true
				await _trial({"id":route.id, "source":"unchanged authored exchange_west_bank_loop", "points":route.points}, _duration * 2, started)
		if not found: _errors.append("Missing protected west bank route.")
	var report := {"schema":1, "mode":_mode, "pilot_enabled":_enabled, "valid":_errors.is_empty(),
		"errors":_errors, "engine":Engine.get_version_info(), "renderer":RenderingServer.get_current_rendering_method(),
		"device":RenderingServer.get_video_adapter_name(), "size":[_size.x,_size.y], "settings":game.career.settings,
		"normal_render_loop":true, "fixed_fps":false, "profile_writes":game.persistence_enabled,
		"stationary_views":_views, "moving_trials":_trials,
		"limits":["Linux diagnostic, not Apple Silicon performance or human visual/feel acceptance.",
			"Stationary inspection cameras are authored; moving trial uses the production chase and ordinary InputMap driver.",
			"Warmup and screenshot readbacks are outside samples. Counters distinguish visible and shadow work.",
			"Route admission requires actual movement and steering; partial laps are reported honestly."]}
	var written := _write(report)
	_release()
	print("FACADE_BAY_RESULT valid=", report.valid, " errors=", _errors, " output=", _output)
	quit(0 if report.valid and written else 1)


func _fixtures() -> Array[Dictionary]:
	return [{"id":"02-frontage-wide", "at":Vector3(-12,9,22), "target":Vector3(-35,7,5.75)},
		{"id":"03-frontage-near", "at":Vector3(-23,7.5,7), "target":Vector3(-35,7.5,5.75)},
		{"id":"04-threshold", "at":Vector3(-30,2,3.75), "target":Vector3(-35,1.7,3.75)},
		{"id":"05-oblique-join", "at":Vector3(-29,4,-2), "target":Vector3(-35,6,5.75)}]


func _settle() -> void:
	var begin := Time.get_ticks_usec()
	var stable := 0
	while Time.get_ticks_usec() - begin < 12000000:
		await RenderingServer.frame_post_draw
		stable = stable + 1 if game.skater.is_on_floor() and game.skater.velocity.length() < 0.05 else 0
		if stable >= 4 and Time.get_ticks_usec() - begin > 2000000: return
	_errors.append("Supported stationary rider did not settle.")


func _capture(id: String, fixture: String, chase: bool) -> void:
	for frame: int in range(4): await RenderingServer.frame_post_draw
	var check: Dictionary = Playability.camera_sample(game) if chase else {}
	if chase and (not check.full_body or check.blocked or not check.finite): _errors.append(id + " production chase obstructed or rider hidden.")
	var image := root.get_texture().get_image()
	if image.get_size() != _size or image.save_png(_output.path_join(id + ".png")) != OK: _errors.append(id + " capture failed.")
	_views.append({"id":id, "fixture":fixture, "camera_position":Metrics._vector(root.get_camera_3d().global_position),
		"chase":check, "file":id + ".png"})
	print("FACADE_CAPTURE ", id)


func _stationary(id: String, started: int) -> void:
	for frame: int in range(6): await RenderingServer.frame_post_draw
	var first := _samples.size()
	var begin := Time.get_ticks_usec()
	var previous := begin
	while Time.get_ticks_usec() - begin < _duration * 1000000:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var row := {"district":id, "elapsed_us":now-started, "frame_ms":float(now-previous)/1000,
			"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,
			"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,
			"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"render_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),
			"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
			"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
			"buffer_memory_bytes":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED), "controller_us":0,
			"visible_draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			"shadow_draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)}
		previous = now
		_samples.append(row)
	var summary := _summary(_samples.slice(first))
	if int(summary.samples) < 10: _errors.append(id + " insufficient stationary rendered samples.")
	var rows := _samples.slice(first)
	for key: String in ["visible_draws","shadow_draws","texture_memory_bytes","buffer_memory_bytes"]:
		var values: Array[float] = []
		for row: Dictionary in rows: values.append(float(row[key]))
		values.sort()
		summary[key + "_p50"] = Metrics._percentile(values,0.5)
		summary["id"] = id
	_views.append(summary)
	if root.get_texture().get_image().save_png(_output.path_join(id + ".png")) != OK: _errors.append(id + " screenshot failed.")
	print("FACADE_STATIONARY ", id, " ", summary)


func _write(report: Dictionary) -> bool:
	var file := FileAccess.open(_output.path_join("report.json"), FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	var columns := PackedStringArray()
	for row: Dictionary in _samples:
		for key: String in row:
			if not columns.has(key): columns.append(key)
	columns.sort()
	var csv := FileAccess.open(_output.path_join("frames.csv"), FileAccess.WRITE)
	if csv == null: return false
	csv.store_csv_line(columns)
	for row: Dictionary in _samples:
		var values := PackedStringArray()
		for key: String in columns: values.append(str(row.get(key, "")))
		csv.store_csv_line(values)
	csv.close()
	return true
