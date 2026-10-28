extends SceneTree
const Main = preload("res://game/main.gd")
const Suite = preload("res://.local/contact-camera-diagnostic/connected_adapter.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool,description: String) -> void:
	if condition:
		passed+=1
		print("PASS: "+description)
	else:
		failed+=1
		push_error("FAIL: "+description)

func _run() -> void:
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	for frame: int in 35:
		await physics_frame
		await process_frame
	await Suite.run_player(self,game,_check)
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(0 if failed==0 else 1)
