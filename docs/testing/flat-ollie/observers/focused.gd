extends SceneTree
const Flat=preload("res://tests/flat_ollie_tests.gd")
const Ramp=preload("res://tests/ramp_pop_tests.gd")
const Limbs=preload("res://tests/limb_pose_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred('_run')
func _run()->void:
	await Flat.run(self,_check)
	await Ramp.run(self,_check)
	await Limbs.run(self,_check)
	print('RESULT: ',passed,' passed, ',failed,' failed');quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print('PASS: ',message)
	else:failed+=1;printerr('FAIL: ',message)
