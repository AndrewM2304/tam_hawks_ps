extends Node
## Scene entry (no --script) exercises Main's actual normal title-start branch.
## The original Main scene uses a fresh in-memory profile, so this probe never writes player data.
const Main = preload("res://game/main.gd")
var game: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_cmdline_args().has("--script") or DisplayServer.get_name() == "headless":
		push_error("Normal title probe needs a rendered scene entry without --script.")
		get_tree().quit(1)
		return
	get_tree().root.size = Vector2i(1920, 1080)
	get_tree().root.content_scale_size = Vector2i(1920, 1080)
	game = Main.new()
	game.persistence_enabled = false
	add_child(game)
	for frame in 6:
		print("NORMAL TITLE frame=%d page=%s alpha=%.1f ready=%s" % [frame, game.hud._page,
			game.hud._dialog.modulate.a, game.hud.is_menu_ready()])
		await get_tree().process_frame
	if not game.paused or game.hud._page != "title" or not game.hud.is_menu_ready() or game.persistence_enabled:
		push_error("Normal startup did not present a focused, visible title safely.")
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	var captured := get_tree().root.get_texture().get_image()
	var destination := "res://docs/testing/screenshots/ui-cleanup/title-normal-boot-1080.png"
	var result := captured.save_png(destination)
	if result != OK or captured.get_size() != Vector2i(1920, 1080):
		push_error("Normal startup screenshot failed or had unexpected dimensions.")
		get_tree().quit(1)
		return
	print("NORMAL TITLE RESULT: visible/focused title at 1920×1080; real boot branch; no profile writes; result=0")
	get_tree().paused = false
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
