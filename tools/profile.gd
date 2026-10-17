extends SceneTree
## Fixed-view rendered diagnostic. It never loads/saves the player's career profile.
const Main = preload("res://game/main.gd")
const DISTRICTS: Array[String] = ["royal_exchange", "george_square", "central_station", "barras"]
const HEADINGS: Dictionary = {"royal_exchange": 0.0, "george_square": 0.0, "central_station": PI / 4.0, "barras": -PI / 4.0}
const WARMUP_SECONDS: float = 1.5
var game: Node
var _duration: float = 36.0
var _output: String = ""
var _requested_size := Vector2i(1920, 1080)
var _samples: Array[Dictionary] = []
var _views: Array[Dictionary] = []
var _errors: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PROFILE: --headless cannot provide rendered GPU/frame evidence; use a graphical display.")
		quit(2)
		return
	if not _parse_arguments():
		quit(2)
		return
	var version := Engine.get_version_info()
	if int(version["major"]) != 4 or int(version["minor"]) != 6 or int(version["patch"]) != 3:
		push_error("PROFILE: the reproducible benchmark requires Godot 4.6.3.")
		quit(2)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = _requested_size
	# Fix the measured framebuffer independently of the project's 1440x900 design canvas.
	# HUD already scales itself from the actual viewport, as in ui_feedback_capture.gd.
	root.content_scale_size = _requested_size
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process_unhandled_input(false)
	game.hud.set_process_input(false)
	game.hud.set_process_unhandled_input(false)
	if not game.free_skate_mode:
		game.toggle_free_skate()
	var started := Time.get_ticks_usec()
	var checkpoints: Dictionary = game.world.get_district_checkpoints()
	for district: String in DISTRICTS:
		game.skater.spawn_position = checkpoints[district]
		game.restart_run()
		game.skater.rotation.y = HEADINGS[district]
		game.skater.set_controls_enabled(false)
		game.skater.set_trick_entries_enabled(false)
		await _wait_rendered(WARMUP_SECONDS)
		var actual_size: Vector2i = root.get_texture().get_size()
		if actual_size != _requested_size:
			push_error("PROFILE: actual render size %s differs from requested %s." % [actual_size, _requested_size])
			_errors += 1
			break
		var first := _samples.size()
		var previous := Time.get_ticks_usec()
		var sample_start := previous
		var sample_seconds := _duration / float(DISTRICTS.size()) - WARMUP_SECONDS
		while float(Time.get_ticks_usec() - sample_start) / 1000000.0 < sample_seconds:
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			var elapsed_ms := float(now - previous) / 1000.0
			previous = now
			if elapsed_ms <= 0.0:
				continue
			_samples.append({"district": district, "elapsed_us": now - started, "frame_ms": elapsed_ms,
				"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				"render_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
				"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
				"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC))})
		var camera: Camera3D = root.get_camera_3d()
		var view := _summarize(_samples.slice(first))
		view["district"] = district
		view["player_position"] = _vector(game.skater.global_position)
		view["player_heading_radians"] = game.skater.rotation.y
		view["camera_position"] = _vector(camera.global_position)
		view["camera_fov"] = camera.fov
		view["camera_far"] = camera.far
		view["warmup_seconds"] = WARMUP_SECONDS
		view["requested_sample_seconds"] = sample_seconds
		view["screenshot"] = district + ".png"
		_views.append(view)
		# Readback and PNG encoding occur outside all timed sample intervals.
		var capture_error := root.get_texture().get_image().save_png(_output.path_join(district + ".png"))
		if capture_error != OK or int(view["samples"]) < 3:
			_errors += 1
			push_error("PROFILE: capture failed or fewer than three frames were sampled for " + district)
		print("PROFILE_VIEW: %s frames=%d mean_fps=%.2f p95_ms=%.3f draw_calls_p50=%.0f" % [
			district, view["samples"], view.get("mean_fps", 0.0), view.get("p95_ms", 0.0), view.get("draw_calls_p50", 0.0)])
	var adapter := RenderingServer.get_video_adapter_name()
	var lowered := adapter.to_lower()
	var report: Dictionary = {
		"schema_version": 1, "valid_rendered_run": _errors == 0 and _views.size() == 4,
		"recorded_at_utc": Time.get_datetime_string_from_system(true),
		"benchmark": "four_fixed_production_chase_views", "target_hardware_acceptance": false,
		"limitations": ["Stationary viewpoints do not reproduce a ten-minute moving gameplay route.",
			"Wall-clock post-draw frame intervals include CPU, rendering and presentation; they are not isolated GPU times.",
			"Warmups and screenshot readback are excluded; scene loading and traversal stutters are not measured.",
			"Audio uses the declared driver; this is not audible-output or controller certification."],
		"engine": version, "os": OS.get_name(), "os_version": OS.get_version(),
		"cpu": OS.get_processor_name(), "logical_cpu_count": OS.get_processor_count(),
		"display_server": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": adapter, "adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"adapter_type": RenderingServer.get_video_adapter_type(), "graphics_api": RenderingServer.get_video_adapter_api_version(),
		"software_renderer": "llvmpipe" in lowered or "softpipe" in lowered or "swiftshader" in lowered,
		"audio_driver": AudioServer.get_driver_name(), "requested_resolution": [_requested_size.x, _requested_size.y],
		"render_resolution": [root.get_texture().get_width(), root.get_texture().get_height()],
		"window_resolution": [root.size.x, root.size.y], "ui_design_resolution": [root.content_scale_size.x, root.content_scale_size.y],
		"benchmark_content_scale_override": true,
		"vsync_mode": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps,
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"settings": game.career.settings.duplicate(true), "profile_writes_enabled": game.persistence_enabled,
		"mode": "free_skate", "hud_visible": game.hud.visible, "skater_controls_enabled": false,
		"requested_scan_seconds": _duration, "elapsed_scan_seconds": float(Time.get_ticks_usec() - started) / 1000000.0,
		"summary": _summarize(_samples), "views": _views,
	}
	if _write_report(report) != OK:
		_errors += 1
	game.queue_free()
	await process_frame
	print("PROFILE_RESULT: %d frames across %d views; outputs %s" % [_samples.size(), _views.size(), _output])
	quit(0 if _errors == 0 else 1)

func _parse_arguments() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4 or not args[0].is_valid_int() or not args[2].is_valid_int() or not args[3].is_valid_int():
		push_error("PROFILE: run tools/profile.sh; expected duration, output directory, width and height.")
		return false
	_duration = float(args[0])
	_output = ProjectSettings.globalize_path(args[1]).simplify_path()
	_requested_size = Vector2i(int(args[2]), int(args[3]))
	var local_root := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	if _duration < 12.0 or _duration > 600.0 or not (_output + "/").begins_with(local_root):
		push_error("PROFILE: duration must be 12–600 seconds and outputs must stay under .local.")
		return false
	if _requested_size.x < 320 or _requested_size.x > 3840 or _requested_size.y < 200 or _requested_size.y > 2160:
		push_error("PROFILE: requested resolution is outside supported diagnostic bounds.")
		return false
	return DirAccess.make_dir_recursive_absolute(_output) == OK

func _wait_rendered(seconds: float) -> void:
	var start := Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - start) / 1000000.0 < seconds:
		await RenderingServer.frame_post_draw

static func _summarize(rows: Array[Dictionary]) -> Dictionary:
	if rows.is_empty():
		return {"samples": 0}
	var frames: Array[float] = []
	var draws: Array[float] = []
	var nodes: Array[float] = []
	var primitives: Array[float] = []
	var total := 0.0
	for row: Dictionary in rows:
		frames.append(float(row["frame_ms"]))
		total += float(row["frame_ms"])
		draws.append(float(row["draw_calls"]))
		nodes.append(float(row["nodes"]))
		primitives.append(float(row["primitives"]))
	frames.sort()
	draws.sort()
	nodes.sort()
	primitives.sort()
	return {"samples": rows.size(), "sampled_seconds": total / 1000.0,
		"mean_ms": total / rows.size(), "mean_fps": float(rows.size()) * 1000.0 / total,
		"p50_ms": _percentile(frames, 0.50), "p95_ms": _percentile(frames, 0.95),
		"p99_ms": _percentile(frames, 0.99), "max_ms": frames.back(),
		"draw_calls_p50": _percentile(draws, 0.50), "draw_calls_p95": _percentile(draws, 0.95),
		"draw_calls_max": draws.back(), "nodes_max": nodes.back(), "primitives_p95": _percentile(primitives, 0.95)}

static func _percentile(sorted: Array[float], proportion: float) -> float:
	return sorted[clampi(int(ceil(float(sorted.size()) * proportion)) - 1, 0, sorted.size() - 1)]

func _write_report(report: Dictionary) -> Error:
	var json := FileAccess.open(_output.path_join("report.json"), FileAccess.WRITE)
	if json == null:
		push_error("PROFILE: report could not be written.")
		return FileAccess.get_open_error()
	json.store_string(JSON.stringify(report, "\t") + "\n")
	json.flush()
	var json_error := json.get_error()
	json.close()
	if json_error != OK:
		push_error("PROFILE: report write failed.")
		return json_error
	var csv := FileAccess.open(_output.path_join("frames.csv"), FileAccess.WRITE)
	if csv == null:
		push_error("PROFILE: frame CSV could not be written.")
		return FileAccess.get_open_error()
	var columns: PackedStringArray = ["district", "elapsed_us", "frame_ms", "process_ms", "physics_ms",
		"draw_calls", "render_objects", "primitives", "nodes", "static_memory_bytes"]
	csv.store_csv_line(columns)
	for sample: Dictionary in _samples:
		var values: PackedStringArray = []
		for column: String in columns:
			values.append(str(sample[column]))
		csv.store_csv_line(values)
	csv.flush()
	var csv_error := csv.get_error()
	csv.close()
	if csv_error != OK:
		push_error("PROFILE: frame CSV write failed.")
	return csv_error

static func _vector(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
