extends SceneTree
## Twelve bounded native frames of the actual Main, ordinary and opt-in design
## construction. Authored static inspection, not motion/input/performance proof.

const Main = preload("res://game/main.gd")
const SIZE := Vector2i(1280, 800)
const EVIDENCE := "res://docs/testing/debug-session-2026-10-24/reports/"
const EXPECTED_FRAMES := 12
var output := "res://.local/pt24-design-capture"
var game: Node
var inspection: Camera3D
var records: Array[Dictionary] = []
var failures := 0
var before: Dictionary = {}
var _preview := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PT24 design capture requires an actual rendering display.")
		quit(2)
		return
	if not _arguments():
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("Cannot create PT24 design capture directory: " + output)
		quit(2)
		return
	root.size = SIZE
	root.content_scale_size = SIZE
	before = _sources()
	_check(RenderingServer.render_loop_enabled, "normal render loop is enabled")
	_check(RenderingServer.get_current_rendering_method() == "gl_compatibility",
		"declared Compatibility renderer is active")
	# Bound a broken renderer/scene even if a completed draw never arrives.
	create_timer(180.0, true).timeout.connect(_timeout)
	inspection = Camera3D.new()
	inspection.name = "AuthoredPT24InspectionCamera"
	root.add_child(inspection)
	await _new_game(false)
	await _capture("default-normal-startup", game.skater._camera,
		"Normal completed play frame after ordinary startup/physics; no pose or camera fixture before this draw.")
	for number: int in [11, 27, 28, 38]:
		await _owner_view(number)
	await _free_game()
	await _new_game(true)
	_check(is_instance_valid(game.world._station_railway) and is_instance_valid(game.world._park_pond),
		"explicit preview contains the station and pond candidates")
	await _owner_view(25)
	await _owner_view(26)
	await _inspection_view("preview-pond-overview", Vector3(-165, 12, -4), Vector3(-184, 0.4, -21), 58.0,
		"Authored static pond/lawn/rail overview; no pond grind, water entry or recovery is driven by this image.")
	var railway: Node3D = game.world._station_railway
	if is_instance_valid(railway):
		railway.reset_run()
		railway.tick(6.5)
	await _inspection_view("preview-station-overview", Vector3(-110, 14, 36), Vector3(-136, 9, 0), 58.0,
		"Authored static station/park-passage overview. Train phase is explicitly set to 6.5s; this is not motion evidence.")
	if is_instance_valid(railway): railway.reset_run()
	await _inspection_view("preview-train-concealed", Vector3(-125, 11, 16), Vector3(-136, 9, 0), 60.0,
		"Static train reset phase0 while paused: complete train should be inside the opaque north tunnel.")
	if is_instance_valid(railway): railway.tick(6.5)
	await _inspection_view("preview-train-visible", Vector3(-125, 11, 16), Vector3(-136, 9, 0), 60.0,
		"Static train phase6.5s while paused: train is explicitly advanced into the clerestory. No actual-time train-loop acceptance.")
	await _inspection_view("preview-bridge-cable-detail", Vector3(-34, 11, 86), Vector3(-25, 6.5, 97), 52.0,
		"Authored static safe-bridge/cable inspection near X-25/Z97; no rail-to-cable transfer is claimed by a still.")
	_check(records.size() == EXPECTED_FRAMES, "all twelve declared frames were captured")
	var after := _sources()
	_check(before == after, "complete game and capture sources stayed unchanged")
	_write_manifest(after, false)
	await _free_game()
	print("PT24_DESIGN_CAPTURE frames=%d failures=%d source_stable=%s" % [records.size(), failures, before == after])
	quit(0 if failures == 0 else 1)


func _new_game(preview: bool) -> void:
	paused = false
	_preview = preview
	game = Main.new()
	game.persistence_enabled = false
	game.set_meta("pt24_design_preview", preview)
	root.add_child(game)
	game.start_mode(true)
	game.set_process_unhandled_input(false)
	for step: int in range(8):
		await physics_frame
		await process_frame
	_check(bool(game.world.get_meta("pt24_design_preview", false)) == preview,
		"world construction matches the declared preview state")
	# Freeze after ordinary startup, retaining a valid actor presentation. Main
	# is ALWAYS-processing in production; freeze it explicitly as well as physics.
	game.set_process(false)
	game.set_physics_process(false)
	paused = true
	game.hud.hide_menu()
	game.skater._camera.make_current()
	game._refresh_hud()


func _free_game() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
		await process_frame
	game = null
	paused = false


func _owner_view(number: int) -> void:
	var path := EVIDENCE.path_join("issue-%04d.json" % number)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary or not raw.has_all(["position", "forward", "camera"]):
		_check(false, "owner placement record is complete: " + str(number))
		return
	var data: Dictionary = raw
	var skater: Node3D = game.skater
	skater.visible = true
	game.hud.visible = true
	skater.global_position = _vector(data.position)
	skater.global_basis = Basis.looking_at(_vector(data.forward), Vector3.UP)
	game.skater._visual_rig.reset()
	skater.reset_physics_interpolation()
	var camera: Camera3D = game.skater._camera
	camera.global_position = _vector(data.camera.position)
	camera.look_at(camera.global_position + _vector(data.camera.forward), _vector(data.camera.up))
	camera.fov = float(data.camera.fov)
	camera.reset_physics_interpolation()
	camera.make_current()
	game._refresh_hud()
	await _capture(("preview" if _preview else "default") + "-issue-%04d" % number, camera,
		"Exact original owner player/camera placement from issue-%04d.json; static paused fixture, not a completed route or temporal flicker check." % number,
		{"owner_record": path, "owner_record_sha256": FileAccess.get_sha256(path)})


func _inspection_view(label: String, at: Vector3, target: Vector3, fov: float, note: String) -> void:
	game.skater.visible = false
	game.hud.visible = false
	inspection.global_position = at
	inspection.look_at(target, Vector3.UP)
	inspection.fov = fov
	inspection.reset_physics_interpolation()
	inspection.make_current()
	await _capture(label, inspection, note)


func _capture(label: String, camera: Camera3D, note: String, extra: Dictionary = {}) -> void:
	# No forced pre-process draw: both scene changes and ordinary processing must
	# reach a completed native frame before viewport readback.
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var dimensions_ok := not frame.is_empty() and frame.get_size() == SIZE
	_check(dimensions_ok, label + " returns the complete native viewport")
	var detail := dimensions_ok and _has_detail(frame)
	_check(detail, label + " contains actual rendered scene detail")
	var path := output.path_join(label + ".png")
	var saved := frame.save_png(path) == OK
	_check(saved, label + " PNG saves")
	var counters := {
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"render_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"video_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"texture_memory_bytes": int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}
	_check(counters.draw_calls > 0 and counters.primitives > 0, label + " has native rendering counters")
	var record := {"file": label + ".png", "sha256": FileAccess.get_sha256(path) if saved else "",
		"width": frame.get_width(), "height": frame.get_height(), "preview": _preview,
		"physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames(),
		"camera_position": _array(camera.global_position), "camera_forward": _array(-camera.global_basis.z),
		"camera_up": _array(camera.global_basis.y), "camera_fov": camera.fov,
		"skater_visible": game.skater.visible, "skater_position": _array(game.skater.global_position),
		"hud_visible": game.hud.visible, "tree_paused": paused, "fixture_note": note,
		"render_counters": counters, "scene_detail": detail}
	record.merge(extra)
	if is_instance_valid(game.world._station_railway):
		record["station_state"] = _serialise(game.world._station_railway.status_snapshot())
		record["station_geometry"] = game.world._station_railway.report.duplicate(true)
	records.append(record)
	print("PT24_DESIGN_FRAME ", label, " draws=", counters.draw_calls, " primitives=", counters.primitives)


func _write_manifest(after: Dictionary, timed_out: bool) -> void:
	var manifest := {"schema": 1, "recorded_at_utc": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(), "adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [SIZE.x, SIZE.y], "expected_frames": EXPECTED_FRAMES, "failures": failures,
		"timed_out": timed_out, "source_stable": before == after, "source_before": before,
		"source_after": after, "records": records, "profile_writes_enabled": false,
		"method": "Actual Main built once with preview=false and once with preview=true; no persistence. Completed normal process and frame_post_draw synchronization before every PNG. Static owner/authored camera placements; physics and Main frozen after ordinary startup. Train phases explicitly reset/ticked while paused.",
		"limits": ["Static placement and scene-construction evidence only; no new ordinary-camera gameplay, combo, temporal flicker or motion acceptance.",
			"Native counters are snapshots, not an uncontended matched frame-time benchmark or target-Mac performance result.",
			"Preview content retains the existing performance admission gate in ordinary play."]}
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		_check(false, "manifest opens for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.flush()
	_check(file.get_error() == OK, "manifest writes successfully")
	file.close()


func _timeout() -> void:
	failures += 1
	push_error("PT24 design capture exceeded its bounded 180-second lifetime.")
	_write_manifest(_sources(), true)
	quit(124)


func _has_detail(frame: Image) -> bool:
	var colors: Dictionary = {}
	var low := 1.0
	var high := 0.0
	for y: int in range(16, SIZE.y, 48):
		for x: int in range(16, SIZE.x, 48):
			var color := frame.get_pixel(x, y)
			var brightness := color.get_luminance()
			low = minf(low, brightness)
			high = maxf(high, brightness)
			var key := Vector3i(roundi(color.r * 31), roundi(color.g * 31), roundi(color.b * 31))
			colors[key] = true
	return colors.size() >= 12 and high - low > 0.03


func _sources() -> Dictionary:
	var paths := PackedStringArray(["res://project.godot", "res://tools/pt24_design_capture.gd"])
	_collect("res://game", paths)
	paths.sort()
	var result: Dictionary = {}
	for path: String in paths:
		result[path] = FileAccess.get_sha256(path)
	return result


func _collect(path: String, paths: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		_check(false, "source directory opens: " + path)
		return
	for child: String in directory.get_files():
		paths.append(path.path_join(child))
	for child: String in directory.get_directories():
		_collect(path.path_join(child), paths)


func _arguments() -> bool:
	var arguments := OS.get_cmdline_user_args()
	var index := 0
	while index < arguments.size():
		var argument := arguments[index]
		if argument == "--output" and index + 1 < arguments.size():
			index += 1
			output = arguments[index]
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		else:
			push_error("Unknown design capture argument (the script owns both preview states): " + argument)
			return false
		index += 1
	return not output.is_empty()


func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


func _array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _serialise(value: Variant) -> Variant:
	if value is Vector3:
		return _array(value)
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			result[key] = _serialise(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(_serialise(item))
		return result
	return value


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", label)
