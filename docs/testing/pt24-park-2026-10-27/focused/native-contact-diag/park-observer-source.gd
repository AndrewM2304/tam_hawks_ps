extends SceneTree
const Main=preload("res://game/main.gd")
const Gallery=preload("res://.local/pt24_park_combo_candidate.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred("_run")
func _run()->void:
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await process_frame
	var music: Node=game.music
	_check(not music._can_control and music._worker==null and music._pending.is_empty()
		and not music.snapshot().enabled and not music.snapshot().connected,
		"Park flagship fixture: Music is inert before any start_mode and no content override was applied")
	_check(bool(game.get_meta("pt24_design_preview",false)),
		"Park flagship fixture: actual Main defaults merged trial content on")
	if failed==0:await Gallery.run_player(self,game,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	game.queue_free()
	await process_frame
	quit(1 if failed>0 else 0)
func _check(valid: bool,label: String)->void:
	if valid:
		passed+=1
		print("PASS: ",label)
	else:
		failed+=1
		print("FAIL: ",label)
