extends SceneTree
const Test=preload("res://tests/pt24_bowl_contact_tests.gd")
const Setup=preload("res://game/core/input_setup.gd")
var passed:=0
var failed:=0
func _initialize():call_deferred("_run")
func _check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1
	print("PASS " if ok else "FAIL ",label)
func _run():
	Setup.register_actions()
	await Test.run(self,_check)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
