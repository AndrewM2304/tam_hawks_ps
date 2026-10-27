extends SceneTree
const Main = preload("res://game/main.gd")
const CivicPark = preload("res://.local/pt24_civic_park_candidate.gd")
var passed := 0
var failed := 0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var game := Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await process_frame
	_check(not game.music._can_control and game.music._worker==null and game.music._pending.is_empty(),
		"Civic/park fixture: Music is inert before start_mode")
	_check(bool(game.get_meta("pt24_design_preview",false)),"Civic/park fixture: normal Main enables merged content without override")
	await CivicPark._combo(self,game,_check,Callable())
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok:
		passed+=1
		print("PASS: ",label)
	else:
		failed+=1
		print("FAIL: ",label)
