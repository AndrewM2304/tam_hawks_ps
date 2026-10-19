extends SceneTree
const TESTS = preload("res://tests/horizon_background_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var world=load("res://game/levels/glasgow_square.gd").new()
 root.add_child(world)
 await physics_frame
 await process_frame
 await TESTS.run(self,world,_check)
 await load("res://tests/map_connector_tests.gd").run(self,world,_check)
 print("RESULT: ",passed," passed, ",failed," failed")
 quit(0 if failed==0 else 1)
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
