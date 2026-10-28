extends SceneTree
const Grade=preload("res://tests/pt24_manual_grade_tests.gd")
const Manual=preload("res://tests/skater_wall_manual_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	await Grade.run(self,_check)
	await Manual.run(self,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
