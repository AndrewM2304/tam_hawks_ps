extends "res://docs/testing/camera-pop/observers/focused.gd"
func _run()->void:
	Review.Setup.register_actions()
	for reduced:bool in [false,true]:
		await Review._natural_returns(self,_check,reduced)
		await Review._quiet_ollie(self,_check,reduced,24)
	await Pop.run(self,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
