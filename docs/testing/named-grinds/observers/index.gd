extends SceneTree
const IndexTests=preload("res://tests/grind_index_tests.gd")
const Bounds=preload("res://tests/grind_capture_bounds_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:
	IndexTests.run(_check);Bounds.run(_check)
	print('RESULT: ',passed,' passed, ',failed,' failed');quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print('PASS: ',message)
	else:failed+=1;printerr('FAIL: ',message)
