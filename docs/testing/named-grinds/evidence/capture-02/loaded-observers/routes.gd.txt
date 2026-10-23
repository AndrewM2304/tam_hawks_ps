extends SceneTree
const Main=preload("res://game/main.gd")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Grinding=preload("res://tests/grinding_tests.gd")
const Regression=preload("res://tests/grind_regression_tests.gd")
const Edges=preload("res://tests/edge_grind_integration_tests.gd")
const Cat=preload("res://tests/cat_encounter_tests.gd")
const Exchange=preload("res://tests/exchange_place_tests.gd")
const Topography=preload("res://tests/topography_tests.gd")
const Compact=preload("res://tests/compact_clyde_lines_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred('_run')
func _run()->void:
	await Edges.run(self,_check)
	var game=Main.new();game.persistence_enabled=false;root.add_child(game)
	await Classic._frames(self,35)
	await Grinding.run(self,game,_check)
	await Regression.run(self,game,_check)
	await Cat.run(self,game,_check)
	await Exchange.run(self,game,_check)
	await Topography.run(self,game,_check)
	await Compact.run(self,game,_check)
	game.queue_free();await process_frame
	print('RESULT: ',passed,' passed, ',failed,' failed');quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print('PASS: ',message)
	else:failed+=1;printerr('FAIL: ',message)
