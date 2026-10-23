extends SceneTree
const Recovery=preload("res://tests/bail_recovery_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred('_run')
func _run()->void:
	await Recovery.run(self,_check)
	print('RESULT: ',passed,' passed, ',failed,' failed')
	quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print('PASS: ',message)
	else:failed+=1;printerr('FAIL: ',message)
