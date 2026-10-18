extends SceneTree
const Profile=preload("res://tests/input_profile_tests.gd")
const Controls=preload("res://tests/classic_control_input_tests.gd")
const Manuals=preload("res://tests/manual_revert_tests.gd")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
 Profile.run(_check)
 await Controls.run(self,_check)
 await Manuals.run(self,_check)
 await Classic.run(self,_check)
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(0 if failed==0 else 1)
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
