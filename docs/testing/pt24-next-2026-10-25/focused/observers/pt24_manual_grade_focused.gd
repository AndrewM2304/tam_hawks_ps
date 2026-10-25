extends SceneTree
const Main = preload("res://game/main.gd")
const Manual = preload("res://tests/pt24_manual_grade_tests.gd")
const Civic = preload("res://tests/pt24_civic_flagship_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func _check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	await Manual.run(self,_check)
	var game := Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	_check(not game.music._can_control and not game.music._persist,"manual focused does not access Music or preferences")
	await Civic.run_player(self,game,_check)
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
