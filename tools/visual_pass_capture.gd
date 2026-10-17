extends SceneTree
var errors := 0
var pass_label := "after"
func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("pass="): pass_label = argument.trim_prefix("pass=")
	if pass_label not in ["before", "after"]:
		push_error("Use pass=before or pass=after")
		quit(1)
		return
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.local/visual-pass")
	root.size = Vector2i(1280, 800)
	var game = load("res://game/main.gd").new()
	game.persistence_enabled = false
	root.add_child(game)
	await frames(12)
	game.hud.hide()
	var shots := [
		["exchange", Vector3(-27,.04,0), PI/2, Vector3(-29,2.0,-2), Vector3(-35,2.2,1)],
		["george", Vector3(13,.04,-114), 0.0, Vector3(12,2.1,-119), Vector3(12,2.3,-125)],
		["central", Vector3(-117,.04,-8), PI/2, Vector3(-121,2,-8), Vector3(-128,2.4,-8)],
		["barras", Vector3(105,.04,-30), 0.0, Vector3(105,2,-36), Vector3(105,2.4,-42)],
	]
	var detail_camera := Camera3D.new()
	detail_camera.fov = 68.0
	detail_camera.far = 250.0
	game.add_child(detail_camera)
	for shot: Array in shots:
		game.skater.reset_skater()
		game.skater.global_position = shot[1]
		game.skater.rotation.y = shot[2]
		game.skater._camera.current = true
		await frames(35)
		await save_frame(shot[0] + "-chase")
		detail_camera.position = shot[3]
		detail_camera.look_at(shot[4])
		detail_camera.current = true
		await frames(4)
		await save_frame(shot[0] + "-close")
	game.queue_free()
	await process_frame
	quit(errors)
func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func save_frame(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://.local/visual-pass/" + pass_label + "-" + label + ".png"
	var result := root.get_texture().get_image().save_png(path)
	if result != OK: errors += 1
	print("VISUAL_CAPTURE ", path, " result=", result, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
