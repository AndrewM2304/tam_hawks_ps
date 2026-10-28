extends SceneTree
const Suite=preload("res://tests/grind_intent_integration_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
 await Suite.run(self,_check)
 print("RESULT: ",passed," passed, ",failed," failed")
 quit(1 if failed else 0)
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
