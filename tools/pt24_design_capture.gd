extends SceneTree
## Twelve frames (twenty with --run-layout; eight with --ordinary-trial).
## Authored static inspection, not motion/input/performance proof.

const Main = preload("res://game/main.gd")
const BowlContact = preload("res://tests/pt24_bowl_contact_tests.gd")
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
var _run_layout := false
var _ordinary_trial := false


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
	if not _ordinary_trial:
		await _new_game(false)
		await _capture("default-normal-startup", game.skater._camera,
			"Normal completed play frame after ordinary startup/physics; no pose or camera fixture before this draw.")
		for number: int in [11, 27, 28, 38]:
			await _owner_view(number)
		if _run_layout:
			await _run_layout_views()
		await _free_game()
	await _new_game(true)
	if _ordinary_trial:
		await _capture("normal-startup",game.skater._camera,
			"Normal Main default with no preview CLI flag or pt24_design_preview override; completed ordinary startup/physics before any pose or authored camera fixture.")
	_check(is_instance_valid(game.world._station_railway) and is_instance_valid(game.world._park_pond),
		"ordinary Main defaults contain station and pond" if _ordinary_trial else "explicit preview contains the station and pond candidates")
	var prefix := "normal" if _ordinary_trial else "preview"
	await _owner_view(25)
	await _owner_view(26)
	await _inspection_view(prefix+"-pond-overview", Vector3(-165, 12, -4), Vector3(-184, 0.4, -21), 58.0,
		"Authored static pond/lawn/rail overview; no pond grind, water entry or recovery is driven by this image.")
	var railway: Node3D = game.world._station_railway
	if is_instance_valid(railway):
		railway.reset_run()
		railway.tick(6.5)
	await _inspection_view(prefix+"-station-overview", Vector3(-110, 14, 36), Vector3(-136, 9, 0), 58.0,
		"Authored static station/park-passage overview. Train phase is explicitly set to 6.5s; this is not motion evidence.")
	if is_instance_valid(railway): railway.reset_run()
	await _inspection_view(prefix+"-train-concealed", Vector3(-125, 11, 16), Vector3(-136, 9, 0), 60.0,
		"Static train reset phase0 while paused: complete train should be inside the opaque north tunnel.")
	if is_instance_valid(railway): railway.tick(6.5)
	await _inspection_view(prefix+"-train-visible", Vector3(-125, 11, 16), Vector3(-136, 9, 0), 60.0,
		"Static train phase6.5s while paused: train is explicitly advanced into the clerestory. No actual-time train-loop acceptance.")
	await _inspection_view(prefix+"-bridge-cable-detail", Vector3(-34, 11, 86), Vector3(-25, 6.5, 97), 52.0,
		"Authored static safe-bridge/cable inspection near X-25/Z97; no rail-to-cable transfer is claimed by a still.")
	_check(records.size() == _expected_frames(), "all declared frames were captured")
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
	if not _ordinary_trial: game.set_meta("pt24_design_preview", preview)
	else: _check(not game.has_meta("pt24_design_preview"),"ordinary Main has no assigned design override")
	root.add_child(game)
	_check(not game.music._can_control and not game.music._persist,
		"capture cannot read soundtrack preferences or control a personal Music session")
	game.start_mode(true)
	game.set_process_unhandled_input(false)
	for step: int in range(8):
		await physics_frame
		await process_frame
	_check(bool(game.world.get_meta("pt24_design_preview", false)) == preview,
		"world construction matches ordinary Main defaults" if _ordinary_trial else "world construction matches the declared preview state")
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
	await _capture(("normal" if _ordinary_trial else ("preview" if _preview else "default")) + "-issue-%04d" % number, camera,
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


func _run_layout_views() -> void:
	await _inspection_view("default-park-seat-approach",Vector3(-130,18,-151),Vector3(-147.94,8.61,-136.01),56.0,
		"Paused authored overview of park_east_lower, its downhill approach and centre/east bypass; no input, catch or motion proof.")
	await _inspection_view("default-park-seat-runout",Vector3(-130,13,-124),Vector3(-147.30,6.46,-111.94),54.0,
		"Paused authored overview of park_east_gateway and the lower straight/runout after the upper seat; no connected-combo or motion proof.")
	await _inspection_view("default-clyde-cleared-arrival",Vector3(-43,11,115),Vector3(-27,2,129),56.0,
		"Paused authored overview of safe-bridge landfall, cleared Z124 apron and existing west ledge; no bridge-to-ledge input proof.")
	await _inspection_view("default-clyde-bank-bowl-return",Vector3(-13,9,128),Vector3(-22,2.4,139.5),55.0,
		"Paused authored overview of clyde_south_link at X[-28.5,-15.5]/Z[138,141], its west run-up and existing bowl-deck endpoint; no moving return proof.")
	await _contact_view(true)
	await _contact_view(false)
	await _air_contact_views()


func _air_contact_views() -> void:
	# Reconstruct the classified actual last-air frame, then invoke only the
	# production finite fit. This is a declared static control, not flight input.
	var rider: CharacterBody3D=game.skater
	rider.reset_skater()
	rider.global_transform=Transform3D(Basis(Vector3(.80915,0,.5876),Vector3.UP,Vector3(-.5876,0,.80915)).orthonormalized(),
		Vector3(-9.289708,2.102755,127.4841))
	rider.airborne=true
	rider.velocity=Vector3(4.7677145,-6.4583817,-7.5835876)
	rider._visual_rig.reset()
	rider._visual_rig.animate(1.0,{"airborne":true,"grab":false,"flip":false,"manual":false,"grind":false,"speed":9.0,"push":false})
	rider._visual.global_transform=Transform3D(Basis(Vector3(.767991,-.592711,.242660),
		Vector3(.438894,.762984,.474582),Vector3(-.466435,-.257972,.846102)).orthonormalized(),rider.global_position)
	rider.visible=true
	game.hud.visible=false
	inspection.global_position=rider.global_position+Vector3(-1.6,.45,1.4)
	inspection.look_at(rider.global_position+Vector3.UP*.20,Vector3.UP)
	inspection.fov=58.0
	inspection.make_current()
	rider.reset_physics_interpolation()
	await _capture("default-last-air-control",inspection,
		"Paused assigned actual last-air witness before finite fitting; source diagnostic recorded a rear tyre38.428mm and axle22.736mm inside this native flat quay. Rig animation is a neutral static fixture, not the recorded input sequence.")
	var physical:=rider.global_transform
	var board_local: Transform3D=rider._board_visual.transform
	var hit:=rider.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		rider.global_position+Vector3.UP*.2,rider.global_position-Vector3.UP*.5,1|8,[rider.get_rid()]))
	_check(not hit.is_empty() and Vector3(hit.normal).y>.999,"last-air diagnostic has actual finite flat native support")
	if hit.is_empty(): return
	rider._place_air_landing_wheels(hit)
	_check(rider.global_transform==physical and rider._board_visual.transform==board_local,
		"last-air diagnostic preserves physical actor and local board frame")
	rider.reset_physics_interpolation()
	await _capture("default-last-air-fitted",inspection,
		"Same paused assigned last-air witness after production _place_air_landing_wheels(actual native hit). Only rigid presentation orientation changes; no translation, lift, physical/input/score correction or motion proof.")


func _contact_view(manual: bool) -> void:
	var rider: CharacterBody3D=game.skater
	rider.reset_skater()
	rider.global_position=Vector3(-9.898241,2.03735,-37.07586) if manual else Vector3(-4.377836,0.793868,139.2057)
	rider.rotation.y=atan2(-0.785988,-0.618235) if manual else -PI*0.5
	rider.airborne=false
	rider.visible=true
	game.hud.visible=false
	rider._visual_rig.reset()
	if manual:
		rider.manual_active=true
		rider.manual_trick_id="manual"
		rider.manual_id="manual"
		rider.manual_balance=0.0507407405
		for step: int in 24: rider._update_pose(1.0/60.0)
		rider._place_manual_wheels()
	else:
		var fit: Dictionary=rider._native_board_floor()
		_check(not fit.is_empty(),"fixed Clyde bowl diagnostic has an actual native presentation fit")
		if fit.is_empty(): return
		var pose: Transform3D=BowlContact._presentation_pose(rider,fit)
		rider._visual.global_transform=Transform3D(pose.basis,pose.origin-pose.basis*rider._visual_rig._board_rest_position)
		rider._visual_rig.animate(1.0,{"airborne":false,"grab":false,"flip":false,"manual":false,"grind":false,"speed":0.0,"push":false})
	rider.reset_physics_interpolation()
	inspection.global_position=rider.global_position+(Vector3(-1.4,0.9,1.5) if manual else Vector3(-1.5,1.3,-1.2))
	inspection.look_at(rider.global_position+Vector3.UP*0.25,Vector3.UP)
	inspection.fov=58.0
	inspection.reset_physics_interpolation()
	inspection.make_current()
	await _capture("default-civic-manual-contact" if manual else "default-clyde-bowl-contact",inspection,
		"Paused fixed contact closeview on actual Main native terrain: initial actor position/heading and Manual state are assigned;24 production pose calls and explicit loaded-axle fit." if manual else
		"Paused fixed contact closeview on actual Main native bowl: initial actor position/heading assigned; production native fit and existing test presentation frame applied, then rig.animate. No earned input, motion, landing or camera-follow proof.")


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
		"width": frame.get_width(), "height": frame.get_height(), "preview": _preview and not _ordinary_trial,
		"ordinary_trial":_ordinary_trial,"main_has_design_override":game.has_meta("pt24_design_preview"),
		"world_content_enabled":bool(game.world.get_meta("pt24_design_preview",false)),
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


func _expected_frames() -> int:
	return 8 if _ordinary_trial else EXPECTED_FRAMES + (8 if _run_layout else 0)


func _write_manifest(after: Dictionary, timed_out: bool) -> void:
	var manifest := {"schema": 1, "recorded_at_utc": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(), "adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [SIZE.x, SIZE.y], "expected_frames":_expected_frames(), "run_layout":_run_layout, "failures": failures,
		"mode":"ordinary-trial" if _ordinary_trial else "legacy-preview-pair",
		"ordinary_trial":_ordinary_trial,"main_design_override_assigned":not _ordinary_trial,
		"timed_out": timed_out, "source_stable": before == after, "source_before": before,
		"source_after": after, "records": records, "profile_writes_enabled": false,
		"method": ("Actual normal Main default built once without preview CLI flag or pt24_design_preview metadata assignment; no persistence. " if _ordinary_trial else "Actual Main built once with preview=false and once with preview=true; no persistence. ") + "Completed normal process and frame_post_draw synchronization before every PNG. Static owner/authored camera placements; physics and Main frozen after ordinary startup. Train phases explicitly reset/ticked while paused. Optional legacy --run-layout adds four layout overviews, two assigned contact-pose diagnostics and two last-air orientation controls; no input or motion proof.",
		"limits": ["Static placement and scene-construction evidence only; no new ordinary-camera gameplay, combo, temporal flicker or motion acceptance.",
			"Native counters are snapshots, not an uncontended matched frame-time benchmark or target-Mac performance result.",
			"Ordinary trial uses actual Main defaults; legacy mode explicitly compares false/true internal construction overrides."]}
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
	var paths := PackedStringArray(["res://project.godot", "res://tools/pt24_design_capture.gd", "res://tests/pt24_bowl_contact_tests.gd"])
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
		elif argument == "--run-layout":
			_run_layout = true
		elif argument == "--ordinary-trial":
			_ordinary_trial = true
		else:
			push_error("Unknown design capture argument: " + argument)
			return false
		index += 1
	if _ordinary_trial and _run_layout:
		push_error("--ordinary-trial and --run-layout are separate capture modes")
		return false
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
