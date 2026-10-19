extends SceneTree
const Review=preload("res://tests/camera_turn_review_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred("_run")
func _check(ok:bool,message:String)->void:
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",message)
func _run()->void:
	Review.Setup.register_actions()
	for reduced:bool in [false,true]:await Review._natural_returns(self,_check,reduced)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(0 if failed==0 else 1)
