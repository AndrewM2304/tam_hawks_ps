extends SceneTree
## Developer-only rendered evidence: run with a display, never --headless.
const Main = preload("res://game/main.gd")
var game: Node
var errors := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Screenshot capture requires a rendering display.")
		quit(1)
		return
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	await _frames(30)
	await _save("prototype")
	Input.action_press("push")
	await _frames(48)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(3)
	Input.action_release("ollie")
	Input.action_press("flip")
	Input.action_press("grab")
	await _frames(12)
	Input.action_release("flip")
	Input.action_release("grab")
	await _save("air-tricks")
	game.toggle_pause()
	await _frames(3)
	await _save("pause-menu", "pause")
	game.toggle_pause()
	game.restart_run()
	game.skater.global_position = Vector3(12, 0.04, 18)
	await _frames(45)
	game.skater.speed = 10.0
	game.skater.velocity = Vector3(0, 0, -10)
	Input.action_press("push")
	Input.action_press("ollie")
	Input.action_press("grind")
	await _frames(2)
	Input.action_release("ollie")
	var caught := false
	for i in 90:
		await _frames(1)
		if game.skater.grinding:
			caught = true
			break
	if caught:
		await _frames(8)
		if game.skater.grinding:
			await _save("rail-grind")
		else:
			errors += 1
			push_error("Rail capture released before evidence frame.")
	else:
		errors += 1
		push_error("Ground approach failed to catch the authored east rail.")
	Input.action_release("push")
	Input.action_release("grind")
	game.restart_run()
	await _frames(35)
	Input.action_press("push")
	await _frames(30)
	Input.action_release("push")
	Input.action_press("manual")
	await _frames(10)
	if game.skater.manual_active:
		await _save("manual")
	else:
		errors += 1
		push_error("Manual capture did not enter from a real ground approach.")
	Input.action_release("manual")
	game.restart_run()
	await _frames(3)
	game.hud.toggle_goals()
	await _frames(4)
	await _save("career-goals", "goals")
	game.hud.toggle_goals()
	game.hud.show_settings()
	await _frames(4)
	await _save("settings", "settings")
	game.apply_settings({"ui_scale": 1.4}, false)
	game.hud.hide_menu()
	game._refresh_hud()
	game.hud.show_settings()
	await _frames(4)
	await _save("settings-large", "settings")
	game.hud.show_controls()
	await _frames(4)
	await _save("controls-large", "controls")
	game.apply_settings({"ui_scale": 1.0}, false)
	game.hud.show_title()
	await _frames(4)
	await _save("title", "title")
	game.hud.hide_menu()
	game.restart_run()
	game.time_remaining = 0.01
	await _frames(4)
	await _save("results", "results")
	game.hud.hide()
	game.skater.set_physics_process(false)
	var camera := Camera3D.new()
	camera.far = 900.0
	camera.fov = 68.0
	game.add_child(camera)
	camera.current = true
	# Authored overview viewpoints document scenery, not completed player routes.
	for shot: Array in [
		["district-george", Vector3(29, 18, -62), Vector3(0, 0, -98)],
		["district-central", Vector3(-61, 7, 31), Vector3(-94, 2, -7)],
		["district-barras", Vector3(57, 16, 31), Vector3(95, 0, -8)],
		["district-overview", Vector3(180, 210, 180), Vector3(0, 0, -40)],
	]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		await _frames(8)
		await _save(shot[0])
	game.queue_free()
	await process_frame
	quit(0 if errors == 0 else 1)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _save(label: String, expected_page: String = "") -> void:
	# Physics ticks can finish a run before _process opens results. Require the
	# intended page and verify it again after drawing, never just a saved PNG.
	var presented := false
	for frame in 12:
		if not _presentation_matches(expected_page):
			await process_frame
			continue
		await RenderingServer.frame_post_draw
		if _presentation_matches(expected_page):
			presented = true
			break
	if not presented:
		errors += 1
		push_error("Expected page '%s' did not become visible, bounded and focused: %s" % [expected_page, label])
		return
	var path := "res://.local/%s.png" % label
	var result := root.get_texture().get_image().save_png(path)
	if result != OK:
		errors += 1
	print("CAPTURE: %s result=%d page=%s" % [path, result, expected_page])

func _presentation_matches(expected_page: String) -> bool:
	if not game.hud.visible: return expected_page.is_empty()
	if expected_page == "results" and not game.run_finished: return false
	return game.hud._page == expected_page and game.hud.is_menu_ready()
