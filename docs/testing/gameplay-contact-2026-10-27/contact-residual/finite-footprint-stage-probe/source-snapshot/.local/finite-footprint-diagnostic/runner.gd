extends SceneTree
const Tests=preload("res://.local/finite-footprint-diagnostic/bowl_adapter.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	Tests.Setup.register_actions()
	var fixture:=await Tests._fixture(self)
	Tests._native_footprint_phase_controls(fixture,_check)
	fixture.viewport.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
