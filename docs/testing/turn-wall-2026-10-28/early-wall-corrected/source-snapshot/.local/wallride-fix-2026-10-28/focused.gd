extends SceneTree
const Physics = preload("res://tests/wall_ride_tests.gd")
const Presentation = preload("res://tests/wall_ride_presentation_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)
func _run() -> void:
	await Physics.run(self, _check)
	await Presentation.run(self, _check)
	print("RESULT: ", passed, " passed, ", failed, " failed")
	quit(0 if failed == 0 else 1)
