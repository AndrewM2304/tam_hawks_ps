extends SceneTree
## Fixed-view rendered diagnostic. It never loads/saves the player's career profile.
const Main = preload("res://game/main.gd")
const Quality = preload("res://game/core/graphics_quality.gd")
const DISTRICTS: Array[String] = ["royal_exchange", "george_square", "central_station", "barras", "clyde", "kelvingrove"]
const HEADINGS: Dictionary = {"royal_exchange": 0.0, "george_square": 0.0, "central_station": PI / 4.0,
	"barras": 0.0, "clyde": PI, "kelvingrove": PI / 4.0}
const WARMUP_SECONDS: float = 2.0
const MAX_WARMUP_SECONDS: float = 12.0
const MIN_STABLE_FRAMES: int = 3
const MIN_SAMPLES: int = 3
const POSITION_TOLERANCE: float = 0.01
const SPEED_TOLERANCE: float = 0.05
const CAMERA_POSITION_TOLERANCE: float = 0.02
const CAMERA_ANGLE_TOLERANCE: float = 0.005
var game: Node
var _duration: float = 60.0
var _quality := "balanced"
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
	game.apply_settings({"graphics_quality":_quality},false)
	if not is_instance_valid(game.skater) or not is_instance_valid(game.hud):
		push_error("PROFILE: production scene did not initialize its rider and HUD.")
		quit(1)
		return
	game.set_process_unhandled_input(false)
	game.hud.set_process_input(false)
	game.hud.set_process_unhandled_input(false)
	game.start_mode(true)
	var started := Time.get_ticks_usec()
	var checkpoints: Dictionary = game.world.get_district_checkpoints()
	for district: String in DISTRICTS:
		if not checkpoints.has(district):
			push_error("PROFILE: missing current district checkpoint: " + district)
			_errors += 1
			break
		var checkpoint: Vector3 = checkpoints[district]
		var ground_height: float = game.world.get_ground_height(checkpoint)
		if not is_finite(ground_height):
			push_error("PROFILE: current district checkpoint has no authored support: " + district)
			_errors += 1
			break
		game.skater.spawn_position = Vector3(checkpoint.x, ground_height + 0.8, checkpoint.z)
		game.restart_run()
		game.skater.rotation.y = HEADINGS[district]
		game.skater.set_controls_enabled(false)
		game.skater.set_trick_entries_enabled(false)
		var warmup: Dictionary = await _settle_view()
		if not warmup.settled:
			push_error("PROFILE: rider/camera did not settle on current ground within the warmup bound: " + district)
			_errors += 1
			break
		var actual_size: Vector2i = root.get_texture().get_size()
		if actual_size != _requested_size:
			push_error("PROFILE: actual render size %s differs from requested %s." % [actual_size, _requested_size])
			_errors += 1
			break
		var anchor: Vector3 = game.skater.global_position
		var camera: Camera3D = root.get_camera_3d()
		var camera_start: Transform3D = camera.global_transform
		var contact_all_frames := true
		var max_displacement := 0.0
		var max_speed := 0.0
		var max_camera_displacement := 0.0
		var max_camera_angle := 0.0
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
			contact_all_frames = contact_all_frames and game.skater.is_on_floor()
			max_displacement = maxf(max_displacement, game.skater.global_position.distance_to(anchor))
			max_speed = maxf(max_speed, game.skater.get_real_velocity().length())
			max_camera_displacement = maxf(max_camera_displacement, camera.global_position.distance_to(camera_start.origin))
			max_camera_angle = maxf(max_camera_angle, _camera_angle(camera.global_basis, camera_start.basis))
			_samples.append({"district": district, "elapsed_us": now - started, "frame_ms": elapsed_ms,
				"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				"render_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
				"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
				"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC))})
		var view := _summarize(_samples.slice(first))
		view["district"] = district
		view["authored_checkpoint"] = _vector(checkpoint)
		view["authored_ground_height"] = ground_height
		view["ground_contact_verified"] = contact_all_frames
		view["max_player_displacement_m"] = max_displacement
		view["max_real_speed_mps"] = max_speed
		view["max_camera_displacement_m"] = max_camera_displacement
		view["max_camera_angle_radians"] = max_camera_angle
		view["player_start_position"] = _vector(anchor)
		view["camera_start_position"] = _vector(camera_start.origin)
		view["player_position"] = _vector(game.skater.global_position)
		view["player_heading_radians"] = game.skater.rotation.y
		view["camera_position"] = _vector(camera.global_position)
		view["camera_rotation_radians"] = _vector(camera.global_rotation)
		view["camera_node_path"] = str(camera.get_path())
		view["render_resolution"] = [actual_size.x, actual_size.y]
		view["camera_fov"] = camera.fov
		view["camera_far"] = camera.far
		view["warmup"] = warmup
		view["minimum_warmup_seconds"] = WARMUP_SECONDS
		view["requested_sample_seconds"] = sample_seconds
		view["screenshot"] = district + ".png"
		_views.append(view)
		# Readback and PNG encoding occur outside all timed sample intervals.
		var capture_error := root.get_texture().get_image().save_png(_output.path_join(district + ".png"))
		view["valid_view"] = capture_error == OK and int(view["samples"]) >= MIN_SAMPLES \
			and contact_all_frames and max_displacement <= POSITION_TOLERANCE and max_speed <= SPEED_TOLERANCE \
			and max_camera_displacement <= CAMERA_POSITION_TOLERANCE and max_camera_angle <= CAMERA_ANGLE_TOLERANCE
		if not view.valid_view:
			_errors += 1
			push_error("PROFILE: capture/sample minimum or supported stationary-view contract failed for " + district)
		print("PROFILE_VIEW: %s frames=%d mean_fps=%.2f p95_ms=%.3f draw_calls_p50=%.0f" % [
			district, view["samples"], view.get("mean_fps", 0.0), view.get("p95_ms", 0.0), view.get("draw_calls_p50", 0.0)])
	var adapter := RenderingServer.get_video_adapter_name()
	var lowered := adapter.to_lower()
	var report: Dictionary = {
		"schema_version": 2, "valid_rendered_run": _errors == 0 and _views.size() == DISTRICTS.size(),
		"expected_view_count": DISTRICTS.size(), "expected_districts": DISTRICTS, "minimum_samples_per_view": MIN_SAMPLES,
		"recorded_at_utc": Time.get_datetime_string_from_system(true),
		"benchmark": "six_supported_production_chase_views_v2", "target_hardware_acceptance": false,
		"limitations": ["Stationary viewpoints do not reproduce a ten-minute moving gameplay route.",
			"One stationary checkpoint view per area is sampled; no area-wide or worst-case rendering claim is made.",
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
		"max_physics_steps_per_frame": Engine.max_physics_steps_per_frame, "time_scale": Engine.time_scale,
		"render_loop_enabled": RenderingServer.render_loop_enabled, "scripted_frame_advance": false,
		"requested_quality":_quality,"graphics_budget":Quality.profile(_quality),"applied_graphics":{"scale_3d":root.scaling_3d_scale,"msaa_3d":root.msaa_3d,"camera_far":game.skater._camera.far,"shadow_distance":game.world.get_node("LateAfternoonSun").directional_shadow_max_distance},"occlusion_enabled":root.use_occlusion_culling,
		"settings": game.career.settings.duplicate(true), "profile_writes_enabled": game.persistence_enabled,
		"mode": "free_skate", "hud_visible": game.hud.visible, "skater_controls_enabled": false,
		"settle_contract": {"minimum_seconds": WARMUP_SECONDS, "maximum_seconds": MAX_WARMUP_SECONDS,
			"consecutive_rendered_frames": MIN_STABLE_FRAMES, "player_displacement_m": POSITION_TOLERANCE,
			"real_speed_mps": SPEED_TOLERANCE, "camera_displacement_m": CAMERA_POSITION_TOLERANCE,
			"camera_angle_radians": CAMERA_ANGLE_TOLERANCE},
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
	if not args.size() in [4,5] or not args[0].is_valid_int() or not args[2].is_valid_int() or not args[3].is_valid_int():
		push_error("PROFILE: run tools/profile.sh; expected duration, output directory, width and height.")
		return false
	_quality = args[4] if args.size() == 5 else "balanced"
	if not Quality.IDS.has(_quality): return false
	_duration = float(args[0])
	_output = ProjectSettings.globalize_path(args[1]).simplify_path()
	_requested_size = Vector2i(int(args[2]), int(args[3]))
	var local_root := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	if _duration < 60.0 or _duration > 600.0 or not (_output + "/").begins_with(local_root):
		push_error("PROFILE: duration must be 60–600 seconds and outputs must stay under .local.")
		return false
	if _requested_size.x < 320 or _requested_size.x > 3840 or _requested_size.y < 200 or _requested_size.y > 2160:
		push_error("PROFILE: requested resolution is outside supported diagnostic bounds.")
		return false
	return DirAccess.make_dir_recursive_absolute(_output) == OK

func _settle_view() -> Dictionary:
	var start := Time.get_ticks_usec()
	var stable_frames := 0
	var rendered_frames := 0
	var previous_position: Vector3 = game.skater.global_position
	var camera: Camera3D = root.get_camera_3d()
	if not is_instance_valid(camera):
		return {"settled": false, "reason": "Production chase camera is missing."}
	var previous_camera: Transform3D = camera.global_transform
	while float(Time.get_ticks_usec() - start) / 1000000.0 < MAX_WARMUP_SECONDS:
		await RenderingServer.frame_post_draw
		rendered_frames += 1
		var stable: bool = game.skater.is_on_floor() and game.skater.get_real_velocity().length() <= SPEED_TOLERANCE \
			and game.skater.global_position.distance_to(previous_position) <= POSITION_TOLERANCE \
			and camera.global_position.distance_to(previous_camera.origin) <= CAMERA_POSITION_TOLERANCE \
			and _camera_angle(camera.global_basis, previous_camera.basis) <= CAMERA_ANGLE_TOLERANCE
		stable_frames = stable_frames + 1 if stable else 0
		previous_position = game.skater.global_position
		previous_camera = camera.global_transform
		var elapsed := float(Time.get_ticks_usec() - start) / 1000000.0
		if elapsed >= WARMUP_SECONDS and stable_frames >= MIN_STABLE_FRAMES:
			return {"settled": true, "elapsed_seconds": elapsed, "rendered_frames": rendered_frames,
				"consecutive_stable_frames": stable_frames}
	return {"settled": false, "elapsed_seconds": float(Time.get_ticks_usec() - start) / 1000000.0,
		"rendered_frames": rendered_frames, "consecutive_stable_frames": stable_frames}

static func _camera_angle(first: Basis, second: Basis) -> float:
	return first.orthonormalized().get_rotation_quaternion().angle_to(second.orthonormalized().get_rotation_quaternion())

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
