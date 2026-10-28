extends SceneTree
const Camera = preload("res://tests/camera_turn_review_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(condition: bool,description: String) -> void:
	if condition:
		passed+=1;print("PASS: "+description)
	else:
		failed+=1;push_error("FAIL: "+description)
func _run() -> void:
	await Camera.run(self,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(0 if failed==0 else 1)
