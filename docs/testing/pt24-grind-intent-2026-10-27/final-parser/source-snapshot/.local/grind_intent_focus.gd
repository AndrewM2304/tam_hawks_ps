extends SceneTree
const Pure=preload("res://tests/grind_ride_tests.gd")
const Bounds=preload("res://tests/grind_capture_bounds_tests.gd")
const Index=preload("res://tests/grind_index_tests.gd")
const Intent=preload("res://tests/grind_intent_integration_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
	Pure.run(_check);Bounds.run(_check);Index.run(_check)
	await Intent.run(self,_check)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
