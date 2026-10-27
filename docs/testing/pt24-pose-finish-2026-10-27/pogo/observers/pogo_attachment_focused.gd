extends SceneTree
const Pogo = preload("res://tests/skater_pogo_attachment_tests.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
var passed:=0
var failed:=0
func _initialize():call_deferred("_run")
func _check(ok: bool,label: String):
	if ok:passed+=1
	else:failed+=1;push_error("FAIL: "+label)
func _run():
	await Pogo.run(self,_check)
	await Authentic.run(self,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
