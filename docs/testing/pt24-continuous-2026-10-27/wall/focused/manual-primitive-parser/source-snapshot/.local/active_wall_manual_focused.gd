extends SceneTree
const Previous=preload("res://tests/skater_wall_presentation_tests.gd")
const Transitions=preload("res://tests/skater_wall_transition_tests.gd")
const Flip=preload("res://tests/skater_wall_flip_tests.gd")
const Manual=preload("res://tests/skater_wall_manual_tests.gd")
const Grab=preload("res://tests/skater_wall_grab_tests.gd")
var passed:=0
var failed:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	await Previous.run(self,_check)
	await Transitions.run(self,_check)
	await Flip.run(self,_check)
	await Grab.run(self,_check)
	await Manual.run(self,_check)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
