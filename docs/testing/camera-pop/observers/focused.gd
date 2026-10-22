extends "res://docs/testing/camera-flow/observers/focused.gd"
const Pop=preload("res://tests/ramp_pop_tests.gd")
const Arcade=preload("res://tests/arcade_response_integration_tests.gd")
func _run()->void:
	await Review.run(self,_check)
	await Pop.run(self,_check)
	await Arcade._flat_jump(self,_check,2)
	await Arcade._flat_jump(self,_check,24)
	await Arcade._wall_pop_repeat(self,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
