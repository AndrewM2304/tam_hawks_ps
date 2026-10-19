extends SceneTree
const Review = preload("res://tests/camera_turn_review_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred("_run")
func _run()->void:
	await Review.run(self,_check)
	await Review.Classic._pipe_natural_vert(self,_check)
	print("RESULT: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print("PASS: ",message)
	else:failed+=1;print("FAIL: ",message)
