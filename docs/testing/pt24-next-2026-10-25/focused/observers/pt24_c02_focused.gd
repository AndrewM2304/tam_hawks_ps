extends SceneTree
const Main = preload("res://game/main.gd")
const Render = preload("res://tests/pt24_render_repairs_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:_run.call_deferred()
func _check(ok: bool,label: String) -> void:
	if ok:passed += 1
	else:failed += 1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	var game := Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	for index: int in 4:
		await physics_frame
		await process_frame
	await Render.run(self,game.world,_check)
	print("PT24_C02_RESOURCE_REPORT ",game.world.get_meta("pt24_render_repairs",{}))
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
