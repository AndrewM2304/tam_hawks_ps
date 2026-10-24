extends SceneTree
## Bounded production-scene visual evidence. Restarts establish initial fixtures;
## screenshots freeze only after real input has produced the recorded state.
const Main = preload("res://game/main.gd")
var game: Node
var output := "res://.local/overnight-capture"
var failures := 0
var checks := 0
var captures: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Overnight capture requires a rendering display.")
		quit(1)
		return
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() > 0: output = arguments[0]
	DirAccess.make_dir_recursive_absolute(output)
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	await _frames(40)
	for view: Array in [
		["01-exchange", Vector3(20, 32, 38), Vector3(0, 2, -12)],
		["02-george", Vector3(43, 32, -43), Vector3(0, 4, -85)],
		["03-central", Vector3(-57, 27, 42), Vector3(-95, 3, -5)],
		["04-barras", Vector3(75, 28, 33), Vector3(113, 2, -13)],
		["05-clyde-pocket", Vector3(-100, 22, 84), Vector3(-125, 2, 65)],
		["06-park-promenade", Vector3(-67, 27, -112), Vector3(-100, 6, -131)],
	]:
		await _overview(view[0], view[1], view[2])

	await _approach()
	Input.action_press("ollie")
	await _frames(28)
	_check(game.skater.is_on_floor() and not game.skater.airborne,
		"charged ollie remains on real supporting ground")
	await _shot("07-charged-crouch")
	Input.action_release("ollie")
	await _frames(12)
	_check(game.skater.airborne and game.skater.global_position.y > 1.2,
		"released charge produces physical airtime")
	await _shot("08-charged-air")

	await _approach()
	await _launch()
	Input.action_press("flip")
	await _frames(1)
	Input.action_release("flip")
	await _frames(2)
	Input.action_press("flip")
	await _frames(7)
	_check(game.skater.flip_trick_id == "double_kickflip", "actual double tap selects double kickflip")
	await _shot("09-double-kickflip")

	await _rail_start()
	Input.action_press("grind")
	await _frames(3)
	_check(game.skater.grinding, "authored rail captures through actual grind input")
	Input.action_press("steer_right")
	Input.action_press("flip")
	await _frames(3)
	_check(game.skater.grinding and game.skater.grind_trick_id == "boardslide"
		and game.score.combo_trick_count == 2, "fresh rail input changes the physical trick and adds one entry")
	await _shot("10-rail-trick-change")

	await _approach()
	Input.action_press("manual")
	await _frames(2)
	Input.action_press("revert")
	await _frames(6)
	_check(game.skater.manual_active and game.score.combo_trick_count == 2,
		"actual manual pivot preserves supported balance and adds one entry")
	await _shot("11-manual-pivot")

	await _approach()
	var heading: float = game.skater.rotation.y
	Input.action_press("brake")
	Input.action_press("steer_right")
	await _frames(8)
	_check(game.skater.is_on_floor() and absf(angle_difference(heading, game.skater.rotation.y)) > 0.1,
		"brake and steering produce a physical powerslide turn")
	await _shot("12-powerslide")

	await _approach()
	if not game.career.completed_ids.has("first_shift"): game.career.completed_ids.append("first_shift")
	game.special_meter.earn_trick(500)
	game.special_meter.earn_trick(500)
	await _launch()
	_key(KEY_U)
	await _frames(13)
	_check(game.skater.airborne and not game.skater.special_name.is_empty()
		and game.special_meter.ready(), "actual unlocked special executes during sustained special mode")
	await _shot("13-live-special")

	await _reset_at(Vector3(117, 2.3, -38.2), -PI / 2.0)
	Input.action_press("push")
	await _frames(32)
	Input.action_release("push")
	await _launch()
	Input.action_press("grind")
	await _frames(4)
	_check(bool(game.skater.get("wallriding")), "actual side contact captures a solid recording-court wall")
	await _shot("14-wallride")

	await _reset_at(Vector3(-113, 2.8, 65), PI / 2.0)
	Input.action_press("push")
	for frame in 180:
		await _frames(1)
		if bool(game.skater.get("transition_active")): break
	_check(bool(game.skater.get("transition_active")), "actual approach enters the Clyde quarterpipe")
	await _frames(4)
	await _shot("15-quarterpipe")
	for frame in 100:
		await _frames(1)
		if game.skater.airborne: break
	await _frames(8)
	_check(game.skater.transition_active and game.skater.airborne
		and game.skater.global_position.y > 4.5, "actual quarterpipe carries the rider above its coping")
	await _shot("16-vert-air")
	await _reset_at(Vector3(-113, 2.8, 65), PI / 2.0)
	Input.action_press("push")
	Input.action_press("grind")
	for frame in 180:
		await _frames(1)
		if game.skater.lip_active: break
	Input.action_release("push")
	await _frames(4)
	_check(game.skater.lip_active and game.score.trick_history.count("Lip Stall") == 1,
		"actual held grind catches a single balanced lip stall on the coping")
	await _shot("17-lip-stall")

	_release()
	_check(captures.size() == 28, "complete capture set contains twenty-eight real frames")
	var manifest := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"platform": OS.get_name(), "production_main": true, "profile_writes_enabled": game.persistence_enabled,
		"checks": checks, "failures": failures, "captures": captures,
		"fixture_policy": "Initial restart or explicitly documented rail fixture only; actual gameplay actions precede action captures.",
		"human_or_target_hardware_certification": false}
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	print("OVERNIGHT CAPTURE RESULT: %d checks, %d failures, %d PNGs" % [checks, failures, captures.size()])
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)

func _approach() -> void:
	await _reset_at(Vector3(-22, 0.8, 28), 0.0)
	Input.action_press("push")
	await _frames(45)
	Input.action_release("push")
	await _frames(1)

func _reset_at(position: Vector3, heading: float) -> void:
	_release()
	game.skater.spawn_position = position
	game.restart_run()
	await _frames(40)
	game.skater.rotation.y = heading

func _launch() -> void:
	Input.action_press("ollie")
	await _frames(2)
	Input.action_release("ollie")
	await _frames(1)
	_check(game.skater.airborne, "actual release-pop launch")

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

func _overview(label: String, position: Vector3, target: Vector3) -> void:
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	game.hud.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = position
	camera.look_at(target)
	camera.fov = 62
	camera.current = true
	await process_frame
	await _save(label, "authored district overview")
	camera.queue_free()
	game.skater._camera.current = true
	game.hud.visible = true
	game.set_physics_process(true)
	game.skater.set_physics_process(true)
	game.skater.set_process(true)

func _shot(label: String) -> void:
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	await _save(label + "-chase", "production chase")
	game.hud.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = game.skater.global_position + Vector3(2.3, 1.65, 2.65)
	var inspection_up: Vector3 = game.skater.get_support_normal() if game.skater.transition_active else Vector3.UP
	camera.look_at(game.skater.global_position + inspection_up * 0.82)
	camera.fov = 40
	camera.current = true
	await process_frame
	await _save(label + "-close", "authored inspection camera")
	camera.queue_free()
	game.skater._camera.current = true
	game.hud.visible = true
	game.set_physics_process(true)
	game.skater.set_physics_process(true)
	game.skater.set_process(true)

func _save(label: String, camera_kind: String) -> void:
	RenderingServer.force_draw(true, 1.0 / 60.0)
	var filename := label + ".png"
	var camera: Camera3D = root.get_camera_3d()
	_check(root.get_texture().get_image().save_png(output.path_join(filename)) == OK, filename + " saved")
	captures.append({"file": filename, "camera": camera_kind, "position": var_to_str(game.skater.global_position),
		"camera_position": var_to_str(camera.global_position), "camera_forward": var_to_str(-camera.global_basis.z),
		"camera_fov": camera.fov, "support_normal": var_to_str(game.skater.get_support_normal()),
		"speed": game.skater.speed, "airborne": game.skater.airborne, "grinding": game.skater.grinding,
		"manual": game.skater.manual_active, "flip_id": game.skater.flip_trick_id, "grind_id": game.skater.grind_trick_id,
		"stance": game.skater.stance, "combo": game.score.get_combo_value(), "special_meter": game.special_meter.value,
		"wallriding": game.skater.get("wallriding"), "transition_active": game.skater.get("transition_active")})

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)

func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
