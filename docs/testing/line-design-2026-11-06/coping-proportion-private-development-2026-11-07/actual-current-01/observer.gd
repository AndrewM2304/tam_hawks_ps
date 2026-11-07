extends SceneTree
const Setup = preload("res://game/core/input_setup.gd")
const Clyde = preload("res://tests/clyde_surface_tests.gd")
const Bowl = preload("res://tests/pt24_bowl_contact_tests.gd")
const Feature = preload("res://tests/feature_transition_ride_tests.gd")
const Connected = preload("res://tests/connected_transition_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok:bool,label:String) -> void:
	if ok:passed+=1
	else:failed+=1
	print("PASS " if ok else "FAIL ",label)
func _run() -> void:
	Setup.register_actions()
	await Clyde.run(self,_check)
	await Bowl.run(self,_check)
	await Feature.run(self,_check)
	await Connected.run(self,_check)
	print("ROOT COPING CURRENT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
