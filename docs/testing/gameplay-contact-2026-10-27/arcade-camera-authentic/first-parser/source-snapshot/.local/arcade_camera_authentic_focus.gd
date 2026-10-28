extends SceneTree
const Arcade=preload("res://tests/arcade_response_integration_tests.gd")
const Camera=preload("res://tests/camera_turn_review_tests.gd")
const Authentic=preload("res://tests/authentic_fidelity_integration_tests.gd")
const Main=preload("res://game/main.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
	# Isolated standalone fixtures must finish before ordinary Main's world exists.
	print("FOCUS_BEGIN arcade_response")
	await Arcade.run(self,_check)
	print("FOCUS_BEGIN camera_turn_review")
	await Camera.run(self,_check)
	print("FOCUS_BEGIN authentic_native_bail_styles_and_sunken_skating")
	var game:=Main.new();game.persistence_enabled=false;root.add_child(game)
	await physics_frame;await process_frame
	_check(not game.persistence_enabled and not game.music._persist and not game.music._can_control,"focused actual Main remains isolated from profile writes and personal Music")
	await Authentic.run(self,game,_check,Callable(),["bail","selections","facility_skating"])
	for action:StringName in InputMap.get_actions():Input.action_release(action)
	game.queue_free();await process_frame;await physics_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(0 if failed==0 else 1)
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
