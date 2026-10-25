extends SceneTree
var passed := 0
var failed := 0
func _initialize(): call_deferred("_run")
func _check(ok: bool,label: String):
 if ok: passed+=1
 else:
  failed+=1
  push_error("FAIL: "+label)
func _run():
 await preload("res://tests/skater_body_attachment_tests.gd").run(self,_check)
 await preload("res://tests/authentic_pose_tests.gd").run(self,_check)
 await preload("res://tests/trick_pose_tests.gd").run(self,_check)
 await preload("res://tests/bail_recovery_tests.gd").run(self,_check)
 print("RESULT: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
