extends SceneTree
const Review=preload("res://tests/camera_turn_review_tests.gd")
func _initialize()->void:call_deferred('_run')
func _run()->void:
	Review.Setup.register_actions()
	var f:=await Review._fixture(self)
	var rider:CharacterBody3D=f.rider
	Input.action_press('push')
	for i in 100:
		await Review._frames(self,1)
		if rider.speed>=11.99:break
	Input.action_release('push')
	var start:=Engine.get_physics_frames()
	var yaw:=rider.rotation.y
	Input.action_press('steer_left')
	for i in 60:
		if i==20:OS.delay_msec(120)
		await Review._frames(self,1)
	Input.action_release('steer_left')
	print('TURN_CLOCK actual_physics_ticks=',Engine.get_physics_frames()-start,' one_second_claim_samples=60 heading_deg=',rad_to_deg(angle_difference(yaw,rider.rotation.y)),' speed=',rider.speed)
	print('RESULT: 1 passed, 0 failed')
	quit()
