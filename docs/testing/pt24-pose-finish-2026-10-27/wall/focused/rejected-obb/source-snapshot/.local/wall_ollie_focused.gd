extends SceneTree
const Wall = preload("res://tests/skater_wall_presentation_tests.gd")
const Transition = preload("res://tests/skater_wall_transition_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	await Wall.run(self,_check)
	await Transition.run(self,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok:
		passed+=1
		print("PASS: "+label)
	else:
		failed+=1
		print("FAIL: "+label)
