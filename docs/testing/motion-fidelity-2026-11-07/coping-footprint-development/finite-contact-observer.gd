extends SceneTree
const Suite=preload("res://tests/pt24_bowl_contact_tests.gd")
var passed:=0
var failed:=0
func _initialize():run.call_deferred()
func run():
	await Suite.run(self,check)
	print("BOWL FOCUSED RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
