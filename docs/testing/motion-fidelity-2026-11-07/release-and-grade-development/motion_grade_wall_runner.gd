extends SceneTree
const Main=preload("res://game/main.tscn")
const Motion=preload("res://tests/motion_fidelity_tests.gd")
const Setup=preload("res://game/core/input_setup.gd")
var passed:=0
var failed:=0
func _initialize():_run.call_deferred()
func _check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	create_timer(120,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await Motion._main_graded_wall(self,game,_check)
	print("MOTION_GRADED_WALL_RESULT ",passed,"/",failed)
	game.free()
	quit(1 if failed>0 else 0)
