extends SceneTree
const Tests = preload("res://tests/skater_skitch_attachment_tests.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	await Tests.run(self,_check)
	await Authentic.run(self,_check)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
