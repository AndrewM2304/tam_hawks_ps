extends SceneTree
const Checks = preload("res://tests/camera_ray_reuse_tests.gd")
const Existing = preload("res://tests/pt24_acceptance_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	await Checks.run(self,_check)
	await Existing.run(self,_check)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok: passed+=1;print("PASS: ",label)
	else: failed+=1;print("FAIL: ",label)
