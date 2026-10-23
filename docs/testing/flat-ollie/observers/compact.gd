extends SceneTree
const Compact=preload("res://tests/compact_clyde_lines_tests.gd")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Main=preload("res://game/main.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred('_run')
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game)
	await Classic._frames(self,35)
	await Compact._line(self,game,_check,'clyde_print_yard_ledge',2.2,20.0,true)
	await Compact._river_circuit(self,game,_check)
	await Compact._deck_containment(self,game,_check)
	game.queue_free();await process_frame
	print('RESULT: ',passed,' passed, ',failed,' failed');quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print('PASS: ',message)
	else:failed+=1;printerr('FAIL: ',message)
