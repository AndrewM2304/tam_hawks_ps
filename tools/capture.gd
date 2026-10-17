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
	await _save("pause-menu")
	game.toggle_pause()
	game.queue_free()
	await process_frame
	quit(0 if errors == 0 else 1)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _save(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.local/%s.png" % label
	var result := root.get_texture().get_image().save_png(path)
	if result != OK:
		errors += 1
	print("CAPTURE: %s result=%d" % [path, result])
