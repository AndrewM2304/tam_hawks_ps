extends SceneTree
## Private unchanged shared-constructor regression: no Main/persistence or input tuning.
const Setup = preload("res://game/core/input_setup.gd")
const Feature = preload("res://tests/feature_transition_ride_tests.gd")
const Connected = preload("res://tests/connected_transition_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("_run")
func _check(condition: bool,label: String) -> void:
	if condition:passed+=1
	else:failed+=1
	print("PASS " if condition else "FAIL ",label)
func _run() -> void:
	Setup.register_actions()
	await Feature.run(self,_check)
	await Connected.run(self,_check)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
