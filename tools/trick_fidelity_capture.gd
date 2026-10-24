extends SceneTree
## Real production actions, with explicit reset/rail fixture starts and authored
## close inspection cameras. Frames are frozen only after the action executes.
const Main = preload("res://game/main.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
var game: Node
var output := "res://.local/trick-fidelity-capture"
var failures := 0
var checks := 0
var captures: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Trick-fidelity capture requires a rendering display.")
		quit(1)
		return
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() > 0:
		output = arguments[0]
	DirAccess.make_dir_recursive_absolute(output)
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	await _frames(40)
	await _shot("01-free-skate", false)
	for request: Array in [
		["02-kickflip", "neutral"], ["03-heelflip", "east"],
		["04-pop-shove-it", "south"], ["05-diagonal-flip", "north_east"],
	]:
		await _approach()
		await _launch()
		_direction(request[1])
		Input.action_press("flip")
		await _frames(8)
		_check(game.skater.airborne and game.skater.flip_trick_id == Catalog.resolve("flip", request[1])["id"],
			request[0] + " actual directional flip")
		await _shot(request[0], true)
		if request[1] == "south":
			await _frames(20)
			_check(game.skater.airborne and game.skater._flip_remaining <= 0.0,
				"actual pop shove-it reaches recovered board orientation")
			await _shot("04b-pop-shove-it-catch", true)
	await _approach()
	await _launch()
	_direction("east")
	Input.action_press("flip")
	await _frames(2)
	Input.action_release("steer_right")
	Input.action_release("flip")
	for frame in 45:
		if game.skater._flip_remaining <= 0.0 and game.skater._flip_catch_remaining <= 0.0:
			break
		await _frames(1)
	Input.action_press("flip")
	await _frames(6)
	_check(game.skater.flip_trick_id == "kickflip"
		and game.score.trick_history.has("Heelflip") and game.score.trick_history.has("Kickflip"),
		"natural flat-ground heelflip into kickflip")
	await _shot("05b-natural-double-flip", true)
	_release()
	for frame in 100:
		await _frames(1)
		if not game.skater.airborne:
			break
	await _frames(23)
	_check(game.score.total_score == 2100, "actual double-flip combo banks 2100 points cleanly")
	await _shot("05c-double-flip-banked", false)
	for request: Array in [
		["06-melon", "neutral"], ["07-indy", "east"],
		["08-nose-grab", "north"], ["09-tail-grab", "south"],
	]:
		await _approach()
		await _launch()
		_direction(request[1])
		Input.action_press("grab")
		await _frames(13)
		_check(game.skater.airborne and game.skater.grab_trick_id == Catalog.resolve("grab", request[1])["id"],
			request[0] + " actual directional grab")
		await _shot(request[0], true)
	await _approach()
	_direction("north")
	Input.action_press("manual")
	await _frames(1)
	Input.action_release("push")
	await _frames(8)
	_check(game.skater.manual_active and game.skater.manual_trick_id == "nose_manual", "actual nose manual")
	await _shot("10-nose-manual", true)
	for request: Array in [["11-rail-grind", "neutral"], ["12-directional-slide", "east"]]:
		await _rail_start()
		_direction(request[1])
		Input.action_press("grind")
		await _frames(3)
		_check(game.skater.grinding and game.skater.grind_trick_id == Catalog.resolve("grind", request[1])["id"],
			request[0] + " actual rail capture")
		await _shot(request[0], true)
	await _approach()
	await _launch()
	Input.action_press("flip")
	Input.action_press("grab")
	await _frames(7)
	await _shot("13-combo-flip-phase", true)
	await _frames(33)
	_check(not game.skater.grab_trick_id.is_empty(), "queued grab executes after flip recovery")
	await _shot("14-combo-grab-phase", true)
	_release()
	var buffered := false
	for frame in 100:
		if game.skater.airborne and game.skater.velocity.y < -5.5 and not buffered:
			Input.action_press("manual")
			buffered = true
		await _frames(1)
		if not game.skater.airborne:
			break
	_check(game.skater.manual_active and game.score.total_score == 0, "actual landing links into buffered manual")
	await _shot("15-linked-combo-manual", false)
	Input.action_release("manual")
	await _frames(25)
	_check(game.score.total_score > 0, "linked combo banks after manual release")
	await _shot("16-banked-combo", false)
	_release()
	game.toggle_pause()
	game.hud.show_trick_guide()
	await _frames(2)
	await _shot("17-trick-guide", false)
	game.hud._scroll.scroll_vertical = 100000
	await _frames(2)
	await _shot("18-trick-directory", false)
	var report := {
		"schema_version": 1,
		"captured_at_utc": Time.get_datetime_string_from_system(true) + "Z",
		"engine": Engine.get_version_info()["string"],
		"display_server": DisplayServer.get_name(),
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"checks": checks, "failures": failures, "captures": captures,
		"profile_writes_enabled": game.persistence_enabled,
		"production_main": true,
		"evidence_scope": "Actual directional input, controller physics and production HUD. Each rail starts from a declared descending fixture. Close views use an authored inspection camera; these frames do not certify continuous human play, enjoyment, Mac output or physical controllers.",
	}
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t") + "\n")
	else:
		_check(false, "manifest writable")
	print("TRICK_FIDELITY_CAPTURE: %d images, %d checks, %d failures" % [captures.size(), checks, failures])
	quit(1 if failures else 0)

func _approach() -> void:
	_release()
	game.restart_run()
	await _frames(40)
	Input.action_press("push")
	await _frames(38)
	Input.action_release("push")
	await _frames(14)

func _launch() -> void:
	Input.action_press("ollie")
	await _frames(2)
	Input.action_release("ollie")
	_check(game.skater.airborne, "actual ollie launch")

func _rail_start() -> void:
	_release()
	game.restart_run()
	await _frames(2)
	game.skater.set_physics_process(false)
	game.skater.global_position = Vector3(12.15, 1.10, 11.5)
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = Vector3(0, -1, -6)
	game.skater.speed = 6.0
	game.skater.airborne = true
	game.skater.set_physics_process(true)

func _direction(direction: String) -> void:
	if "north" in direction:
		Input.action_press("push")
	if "south" in direction:
		Input.action_press("brake")
	if "east" in direction:
		Input.action_press("steer_right")
	if "west" in direction:
		Input.action_press("steer_left")

func _shot(label: String, close: bool) -> void:
	var main_physics: bool = game.is_physics_processing()
	var skater_physics: bool = game.skater.is_physics_processing()
	var skater_process: bool = game.skater.is_processing()
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	await _save(label + "-chase", "production chase")
	if close:
		game.hud.visible = false
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.global_position = game.skater.global_position + Vector3(2.3, 1.65, 2.65)
		camera.look_at(game.skater.global_position + Vector3(0, 0.82, 0))
		camera.fov = 40
		camera.current = true
		await process_frame
		await _save(label + "-close", "authored inspection camera")
		camera.queue_free()
		game.skater._camera.current = true
		game.hud.visible = true
	game.set_physics_process(main_physics)
	game.skater.set_physics_process(skater_physics)
	game.skater.set_process(skater_process)

func _save(label: String, camera_kind: String) -> void:
	RenderingServer.force_draw(true, 1.0 / 60.0)
	var file_name := label + ".png"
	var result: Error = root.get_texture().get_image().save_png(output.path_join(file_name))
	_check(result == OK, file_name + " saved")
	captures.append({
		"file": file_name, "camera": camera_kind,
		"position": var_to_str(game.skater.global_position),
		"speed": game.skater.speed, "airborne": game.skater.airborne,
		"grinding": game.skater.grinding, "manual": game.skater.manual_active,
		"flip_id": game.skater.flip_trick_id, "grab_id": game.skater.grab_trick_id,
		"grind_id": game.skater.grind_trick_id, "manual_id": game.skater.manual_trick_id,
		"stance": game.skater.stance, "board_rotation": var_to_str(game.skater._board_visual.rotation),
		"combo": game.score.get_combo_value(), "total_score": game.score.total_score,
	})

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _release() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + label)
