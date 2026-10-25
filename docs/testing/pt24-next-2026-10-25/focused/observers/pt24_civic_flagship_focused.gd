extends SceneTree
const Main = preload("res://game/main.gd")
const Civic = preload("res://tests/pt24_civic_flagship_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await process_frame
	await Civic.run(self,game,_check)
	print("CIVIC_FOCUSED_RESULT %d passed / %d failed"%[passed,failed])
	game.queue_free()
	await process_frame
	quit(1 if failed>0 else 0)
func _check(valid: bool,label: String) -> void:
	if valid:
		passed+=1
		print("PASS ",label)
	else:
		failed+=1
		print("FAIL ",label)
