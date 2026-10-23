extends SceneTree
## Run affected complete controller/classic suites and real route proofs.
const Pad=preload("res://tests/classic_control_input_tests.gd")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Career=preload("res://tests/career_integration_tests.gd")
const Cat=preload("res://tests/cat_encounter_tests.gd")
const Exchange=preload("res://tests/exchange_place_tests.gd")
const Topography=preload("res://tests/topography_tests.gd")
const Main=preload("res://game/main.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred('_run')
func _run()->void:
	await Pad.run(self,_check)
	await Classic.run(self,_check)
	var game=Main.new();game.persistence_enabled=false;root.add_child(game)
	await Classic._frames(self,35)
	await Career.run(self,game,_check)
	await Cat.run(self,game,_check)
	# Existing complete Exchange checks include the bent-ledge combo.
	await Exchange.run(self,game,_check)
	await Topography._bridge_and_recovery(self,game,_check)
	game.queue_free();await process_frame
	print('RESULT: ',passed,' passed, ',failed,' failed');quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print('PASS: ',message)
	else:failed+=1;printerr('FAIL: ',message)
