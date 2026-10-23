extends "res://docs/testing/bail-pose/observers/focused.gd"
const Review=preload("res://tests/camera_turn_review_tests.gd")
const Feedback=preload("res://tests/ui_feedback_tests.gd")
const Recovery=preload("res://tests/bail_recovery_tests.gd")
func _run()->void:
	await Limbs.run(self,_check)
	await Review.run(self,_check)
	var game=load("res://game/main.tscn").instantiate()
	game.persistence_enabled=false;root.add_child(game)
	await Feedback.run(self,game,_check)
	game.queue_free();await process_frame
	await Recovery.run(self,_check)
	print('RESULT: ',passed,' passed, ',failed,' failed')
	quit(1 if failed else 0)
