extends SceneTree
const Previous=preload("res://tests/skater_wall_presentation_tests.gd")
const Transitions=preload("res://tests/skater_wall_transition_tests.gd")
const Active=preload("res://tests/skater_wall_flip_tests.gd")
var passed:=0
var failed:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	await Previous.run(self,_check)
	await Transitions.run(self,_check)
	await Active.run(self,_check)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
