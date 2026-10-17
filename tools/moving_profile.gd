extends SceneTree
## Render-loop moving diagnostic. Route feedback submits ordinary InputMap
## actions at native physics rate; only declared trial starts set pose.

const Main = preload("res://game/main.gd")
const Quality = preload("res://game/core/graphics_quality.gd")
const Metrics = preload("res://tools/profile.gd")
const MIN_DISTANCE := 4.0
const MIN_SIM_SECONDS := 1.0
const MIN_TURN_RADIANS := 0.08
const MIN_SAMPLES := 3
const LONG_FRAME_MS := [16.666667, 33.333333, 50.0, 100.0]

class RouteDriver extends Node:
	var profiler: SceneTree
	func _physics_process(delta: float) -> void:
		profiler._drive(delta)

var game: Node
var _driver: RouteDriver
var _quality := "balanced"
var _output := ""
var _duration := 60.0
var _size := Vector2i(1920, 1080)
var _quick := false
var _samples: Array[Dictionary] = []
var _trials: Array[Dictionary] = []
var _route: Dictionary = {}
var _points := PackedVector3Array()
var _waypoint := 1
var _laps := 0
var _driving := false
var _sim_seconds := 0.0
var _distance := 0.0
var _turn_radians := 0.0
var _turn_ticks := 0
var _moving_ticks := 0
var _ticks := 0
var _bails := 0
var _teleports := 0
var _last_position := Vector3.ZERO
var _last_heading := 0.0
var _max_deviation := 0.0
var _controller_us := 0
var _total_controller_us := 0
var _command_vertical := 0
var _last_nonzero_vertical := 0
var _neutral_seconds := 1.0
var _steer := 0.0
var _errors: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("MOVING PROFILE: a graphical display is required; headless supplies no rendered evidence.")
		quit(2)
		return
	if not _arguments():
		quit(2)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = _size
	root.content_scale_size = _size
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.apply_settings({"graphics_quality":_quality},false)
	game.start_mode(true)
	_driver = RouteDriver.new()
	_driver.profiler = self
	_driver.process_physics_priority = -100
	root.add_child(_driver)
	game.skater.bailed.connect(func(): _bails += 1 if _driving else 0)
	var authored: Dictionary = {}
	for route: Dictionary in game.world.get_route_definitions(): authored[route.id] = route.points
	var quay := PackedVector3Array([
		Vector3(-80,2,67), Vector3(-74,2,69), Vector3(-56,2,67), Vector3(-38,2,69), Vector3(-20,2,67),
		Vector3(0,2,69), Vector3(20,2,67), Vector3(42,2,69), Vector3(64,2,67), Vector3(78,2,69),
		Vector3(82,2,72), Vector3(76,2,73), Vector3(60,2,71), Vector3(40,2,73), Vector3(20,2,71),
		Vector3(0,2,73), Vector3(-20,2,71), Vector3(-40,2,73), Vector3(-60,2,71),
		Vector3(-80,2,72), Vector3(-84,2,69), Vector3(-80,2,67)])
	var routes: Array[Dictionary] = [
		{"id": "quay_weave", "source": "declared gentle weave inside existing north quay; not a new game route", "points": quay, "yaw": -PI * 0.5},
		{"id": "market_inner_loop", "source": "barras_market_inner_loop", "points": authored.get("barras_market_inner_loop", PackedVector3Array())},
		{"id": "park_rolling_loop", "source": "kelvingrove_rolling_loop", "points": authored.get("kelvingrove_rolling_loop", PackedVector3Array())}]
	var started := Time.get_ticks_usec()
	for route: Dictionary in routes:
		if PackedVector3Array(route.points).size() < 3:
			_errors.append("Missing route " + str(route.id))
			continue
		await _trial(route, _duration / routes.size(), started)
	var adapter := RenderingServer.get_video_adapter_name()
	var report := {"schema_version": 1, "benchmark": "actual_input_moving_chase_v1", "quick_mode": _quick,
		"valid_rendered_run": _errors.is_empty() and _trials.size() == routes.size(),
		"target_hardware_acceptance": false, "errors": _errors, "recorded_at_utc": Time.get_datetime_string_from_system(true),
		"requested_sample_seconds": _duration, "elapsed_wall_seconds": float(Time.get_ticks_usec() - started) / 1000000.0,
		"engine": Engine.get_version_info(), "os": OS.get_name(), "os_version": OS.get_version(),
		"cpu": OS.get_processor_name(), "logical_cpu_count": OS.get_processor_count(), "memory_info": OS.get_memory_info(),
		"display_server": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(), "adapter": adapter,
		"adapter_vendor": RenderingServer.get_video_adapter_vendor(), "graphics_api": RenderingServer.get_video_adapter_api_version(),
		"software_renderer": "llvmpipe" in adapter.to_lower() or "softpipe" in adapter.to_lower() or "swiftshader" in adapter.to_lower(),
		"audio_driver": AudioServer.get_driver_name(), "requested_resolution": [_size.x, _size.y],
		"render_resolution": [root.get_texture().get_width(), root.get_texture().get_height()],
		"window_resolution": [root.size.x, root.size.y], "content_scale_size": [root.content_scale_size.x, root.content_scale_size.y],
		"vsync_mode": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps,
		"physics_ticks_per_second": Engine.physics_ticks_per_second, "max_physics_steps_per_frame": Engine.max_physics_steps_per_frame,
		"time_scale": Engine.time_scale, "render_loop_enabled": RenderingServer.render_loop_enabled, "scripted_frame_advance": false,
		"requested_quality":_quality,"graphics_budget":Quality.profile(_quality),"applied_graphics":{"scale_3d":root.scaling_3d_scale,"msaa_3d":root.msaa_3d,"camera_far":game.skater._camera.far,"shadow_distance":game.world.get_node("LateAfternoonSun").directional_shadow_max_distance},"occlusion_enabled":root.use_occlusion_culling,
		"settings": game.career.settings.duplicate(true), "profile_writes_enabled": game.persistence_enabled,
		"mode": "free_skate", "hud_visible": game.hud.visible, "controls_enabled_during_sampling": true,
		"admission": {"minimum_samples": MIN_SAMPLES, "minimum_distance_m": MIN_DISTANCE,
			"minimum_simulated_seconds": MIN_SIM_SECONDS, "minimum_turn_radians": MIN_TURN_RADIANS, "minimum_moving_tick_fraction": 0.6},
		"limitations": ["Post-draw intervals include CPU, rendering and presentation; they are not isolated GPU times.",
			"Physics uses normal real-time engine scheduling. Slow rendering may advance fewer simulated seconds; both clocks and motion are recorded.",
			"Initial fixtures, stationary warmups and screenshot readbacks are outside samples. This is three moving loops, not a continuous city tour or a trick stress test.",
			"Controller feedback cost is included and recorded. Scripted InputMap actions do not certify physical controls, human fun, Mac performance or final art.",
			"Insufficient samples, movement, turning, route deviation, bails or source changes reject the run; quick mode has the same movement gates."],
		"summary": _summary(_samples), "trials": _trials}
	var written := _write(report)
	_release()
	print("MOVING_PROFILE_RESULT valid=", report.valid_rendered_run, " frames=", _samples.size(), " output=", _output)
	quit(0 if report.valid_rendered_run and written else 1)


func _trial(route: Dictionary, seconds: float, started: int) -> void:
	_release()
	_driving = false
	_route = route
	_points = route.points
	var spawn := _points[0] + Vector3.UP * 0.8
	game.skater.spawn_position = spawn
	game.skater.set_physics_process(true)
	game.skater.set_process(true)
	game.set_physics_process(true)
	game.restart_run()
	var direction := _points[1] - _points[0]
	game.skater.rotation.y = float(route.get("yaw", atan2(-direction.x, -direction.z)))
	game.skater.set_controls_enabled(false)
	var warm_started := Time.get_ticks_usec()
	var stable := 0
	var warm_frames := 0
	while float(Time.get_ticks_usec() - warm_started) / 1000000.0 < 10.0:
		await RenderingServer.frame_post_draw
		warm_frames += 1
		stable = stable + 1 if game.skater.is_on_floor() and game.skater.velocity.length() < 0.05 else 0
		if stable >= 3 and float(Time.get_ticks_usec() - warm_started) / 1000000.0 >= 1.0: break
	var trial_errors: Array[String] = []
	if stable < 3: trial_errors.append("Initial rider did not settle on actual support.")
	if Vector2i(root.get_texture().get_size()) != _size: trial_errors.append("Framebuffer dimensions differ.")
	game.skater.set_controls_enabled(true)
	_waypoint = 1
	_laps = 0
	_sim_seconds = 0.0
	_distance = 0.0
	_turn_radians = 0.0
	_turn_ticks = 0
	_moving_ticks = 0
	_ticks = 0
	_bails = 0
	_teleports = 0
	_max_deviation = 0.0
	_total_controller_us = 0
	_last_position = game.skater.global_position
	_last_heading = game.skater.rotation.y
	_last_nonzero_vertical = 0
	_command_vertical = 0
	_neutral_seconds = 1.0
	var initial: Vector3 = game.skater.global_position
	var first := _samples.size()
	await RenderingServer.frame_post_draw
	var previous := Time.get_ticks_usec()
	var sample_start := previous
	_driving = true
	while float(Time.get_ticks_usec() - sample_start) / 1000000.0 < seconds:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var frame_ms := float(now - previous) / 1000.0
		previous = now
		if frame_ms <= 0.0: continue
		var at: Vector3 = game.skater.global_position
		_samples.append({"district": route.id, "elapsed_us": now - started, "frame_ms": frame_ms,
			"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			"render_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
			"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
			"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
			"video_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
			"sim_seconds": _sim_seconds, "distance_m": _distance, "x": at.x, "y": at.y, "z": at.z,
			"speed_mps": game.skater.velocity.length(), "heading_radians": game.skater.rotation.y,
			"waypoint": _waypoint, "laps": _laps, "steer": _steer, "vertical_command": _command_vertical,
			"controller_us": _controller_us, "bails": _bails, "manual": game.skater.manual_active})
	_driving = false
	_release()
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	var summary := _summary(_samples.slice(first))
	var moving_fraction := float(_moving_ticks) / maxi(1, _ticks)
	if int(summary.samples) < MIN_SAMPLES: trial_errors.append("Insufficient rendered samples.")
	if _distance < MIN_DISTANCE or _sim_seconds < MIN_SIM_SECONDS: trial_errors.append("Insufficient actual moving distance or simulated time.")
	if _turn_radians < MIN_TURN_RADIANS or _turn_ticks < 3: trial_errors.append("Actual route did not demonstrate turning.")
	if moving_fraction < 0.6: trial_errors.append("Too much of the sampled workload was stationary.")
	if _bails > 0 or _teleports > 0: trial_errors.append("Route bailed or discontinuous recovery occurred.")
	if _max_deviation > 5.5: trial_errors.append("Rider left the declared route corridor.")
	var screenshot := str(route.id) + ".png"
	# This copies the completed final rendered frame after timing has stopped.
	if root.get_texture().get_image().save_png(_output.path_join(screenshot)) != OK: trial_errors.append("Screenshot readback failed.")
	var points: Array = []
	for at: Vector3 in _points: points.append(Metrics._vector(at))
	summary.merge({"route": route.id, "route_source": route.source, "route_points": points, "initial_position": Metrics._vector(initial),
		"final_position": Metrics._vector(game.skater.global_position), "initial_heading": route.get("yaw", atan2(-direction.x, -direction.z)),
		"simulated_seconds": _sim_seconds, "distance_m": _distance, "absolute_turn_radians": _turn_radians,
		"steering_physics_ticks": _turn_ticks, "physics_ticks": _ticks, "moving_tick_fraction": moving_fraction,
		"waypoint_index": _waypoint, "completed_laps": _laps, "maximum_route_deviation_m": _max_deviation,
		"bails": _bails, "discontinuous_recoveries": _teleports, "controller_total_us": _total_controller_us,
		"warmup_seconds": float(sample_start - warm_started) / 1000000.0, "warmup_rendered_frames": warm_frames,
		"requested_sample_seconds": seconds, "valid_trial": trial_errors.is_empty(), "errors": trial_errors, "screenshot": screenshot,
		"camera_position": Metrics._vector(game.skater._camera.global_position), "camera_fov": game.skater._camera.fov,
		"camera_far": game.skater._camera.far, "camera_node": str(game.skater._camera.get_path())})
	_trials.append(summary)
	for reason: String in trial_errors: _errors.append(str(route.id) + ": " + reason)
	print("MOVING_PROFILE_TRIAL ", route.id, " frames=", summary.samples, " metres=", _distance,
		" sim_seconds=", _sim_seconds, " turn_radians=", _turn_radians, " errors=", trial_errors)


func _drive(delta: float) -> void:
	if not _driving: return
	var begin := Time.get_ticks_usec()
	_sim_seconds += delta
	_ticks += 1
	var at: Vector3 = game.skater.global_position
	var displacement := at.distance_to(_last_position)
	if displacement > 3.0: _teleports += 1
	else: _distance += displacement
	_turn_radians += absf(angle_difference(_last_heading, game.skater.rotation.y))
	_last_heading = game.skater.rotation.y
	_last_position = at
	if game.skater.velocity.length() > 0.5: _moving_ticks += 1
	if _horizontal(at - _points[_waypoint]).length() < 1.6:
		_waypoint += 1
		if _waypoint >= _points.size():
			_waypoint = 1
			_laps += 1
	var nearest := INF
	for index in _points.size() - 1:
		var start := _horizontal(_points[index])
		var segment := _horizontal(_points[index + 1]) - start
		var portion := clampf((_horizontal(at) - start).dot(segment) / maxf(segment.length_squared(), 0.0001), 0.0, 1.0)
		nearest = minf(nearest, _horizontal(at).distance_to(start + segment * portion))
	_max_deviation = maxf(_max_deviation, nearest)
	var to := _points[_waypoint] - at
	var error := angle_difference(game.skater.rotation.y, atan2(-to.x, -to.z))
	_steer = clampf(-error * 1.9, -1.0, 1.0)
	if absf(_steer) > 0.05: _turn_ticks += 1
	var target_speed := 3.3 if absf(error) > 0.45 else 6.0
	var magnitude: float = game.skater.velocity.length()
	var command := 1 if magnitude < target_speed - 0.4 else (-1 if magnitude > target_speed + 0.7 else 0)
	# Route steering must not accidentally request the game's Up-neutral-Down
	# trick gesture. Ordinary braking is delayed until that 220ms window closes.
	if command != 0 and _last_nonzero_vertical != 0 and command != _last_nonzero_vertical \
			and _command_vertical == 0 and _neutral_seconds < 0.25: command = 0
	if command == 0: _neutral_seconds += delta
	else:
		_last_nonzero_vertical = command
		_neutral_seconds = 0.0
	_command_vertical = command
	_input("push", 1.0 if command > 0 else 0.0)
	_input("brake", 1.0 if command < 0 else 0.0)
	_input("steer_left", maxf(-_steer, 0.0))
	_input("steer_right", maxf(_steer, 0.0))
	_controller_us = Time.get_ticks_usec() - begin
	_total_controller_us += _controller_us


func _arguments() -> bool:
	for launch_argument: String in OS.get_cmdline_args():
		if launch_argument in ["--fixed-fps", "--disable-render-loop"] or launch_argument.begins_with("--fixed-fps="):
			push_error("MOVING PROFILE: scripted frame advance is outside the native rendered workload.")
			return false
	var version := Engine.get_version_info()
	if int(version.major) != 4 or int(version.minor) != 6 or int(version.patch) != 3:
		return false
	if Engine.physics_ticks_per_second != 60: return false
	var args := OS.get_cmdline_user_args()
	if not args.size() in [5,6]: return false
	_quality = args[5] if args.size() == 6 else "balanced"
	if not Quality.IDS.has(_quality): return false
	_duration = float(args[0])
	_output = ProjectSettings.globalize_path(args[1]).simplify_path()
	_size = Vector2i(int(args[2]), int(args[3]))
	_quick = args[4] == "quick"
	var allowed := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	return _duration >= 15.0 and _duration <= 600.0 and (_output + "/").begins_with(allowed) \
		and _size.x >= 320 and _size.x <= 3840 and _size.y >= 200 and _size.y <= 2160 \
		and RenderingServer.render_loop_enabled and is_equal_approx(Engine.time_scale, 1.0) \
		and DirAccess.make_dir_recursive_absolute(_output) == OK


static func _summary(rows: Array[Dictionary]) -> Dictionary:
	var result := Metrics._summarize(rows)
	if rows.is_empty(): return result
	for column: String in ["process_ms", "physics_ms", "controller_us"]:
		var values: Array[float] = []
		for row: Dictionary in rows: values.append(float(row[column]))
		values.sort()
		for percentile: float in [0.50, 0.95, 0.99]: result[column + "_p" + str(int(percentile * 100))] = Metrics._percentile(values, percentile)
	var long_frames := {}
	for threshold: float in LONG_FRAME_MS:
		var count := 0
		for row: Dictionary in rows:
			if float(row.frame_ms) > threshold: count += 1
		long_frames[str(threshold)] = count
	result["frames_over_ms"] = long_frames
	return result


func _write(report: Dictionary) -> bool:
	var file := FileAccess.open(_output.path_join("report.json"), FileAccess.WRITE)
	if file == null:
		push_error("MOVING PROFILE: report unwritable")
		return false
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	var csv := FileAccess.open(_output.path_join("frames.csv"), FileAccess.WRITE)
	if csv == null:
		push_error("MOVING PROFILE: frames unwritable")
		return false
	var columns := PackedStringArray(["district", "elapsed_us", "frame_ms", "process_ms", "physics_ms", "draw_calls", "render_objects",
		"primitives", "nodes", "static_memory_bytes", "video_memory_bytes", "sim_seconds", "distance_m", "x", "y", "z", "speed_mps",
		"heading_radians", "waypoint", "laps", "steer", "vertical_command", "controller_us", "bails", "manual"])
	csv.store_csv_line(columns)
	for row: Dictionary in _samples:
		var values := PackedStringArray()
		for column: String in columns: values.append(str(row[column]))
		csv.store_csv_line(values)
	csv.flush()
	var error := csv.get_error()
	csv.close()
	return error == OK


static func _horizontal(value: Vector3) -> Vector2:
	return Vector2(value.x, value.z)


static func _input(action: String, strength: float) -> void:
	if strength > 0.001: Input.action_press(action, strength)
	else: Input.action_release(action)


static func _release() -> void:
	for action: String in ["push", "brake", "steer_left", "steer_right"]: Input.action_release(action)
