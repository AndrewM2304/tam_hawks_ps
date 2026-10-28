extends SceneTree
const Main=preload("res://game/main.gd")
const Driver=preload("res://.local/station-contact-diagnostic/driver_adapter.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	await Driver._frames(self,3)
	await Driver._station(self,game,_check,Callable())
	print("RESULT: %d passed, %d failed"%[passed,failed])
	game.queue_free();await process_frame
	quit(1 if failed else 0)
