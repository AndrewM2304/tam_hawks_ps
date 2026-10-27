extends SceneTree
const Tests=preload("res://tests/skater_gait_direction_tests.gd")
var passed:=0
var failed:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	await Tests.run(self,_check)
	if passed+failed!=18:push_error("Expected18 gait direction checks, executed%d"%(passed+failed));failed+=1
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
