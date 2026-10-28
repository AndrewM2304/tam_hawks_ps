extends SceneTree
const Bowl=preload("res://tests/pt24_bowl_contact_tests.gd")
const Board=preload("res://tests/board_floor_ray_reuse_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	print("FOCUS_BEGIN canonicalBowl")
	await Bowl.run(self,_check)
	print("FOCUS_BEGIN canonicalBoardRay")
	await Board.run(self,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
