extends SceneTree
const Manual=preload("res://tests/skater_wall_manual_tests.gd")
const Arm=preload("res://tests/skater_obstacle_arm_tests.gd")
const Gait=preload("res://.local/gait_sequence_instrumented.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
 await Manual.run(self,_check)
 await Arm.run(self,_check)
 await Gait.run(self,_check)
 print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
