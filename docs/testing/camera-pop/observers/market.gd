extends "res://docs/testing/camera-flow/observers/playability.gd"
const Market=preload("res://tests/market_encounter_tests.gd")
func _run()->void:
	var game=MainScene.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await Market.run(self,game,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
