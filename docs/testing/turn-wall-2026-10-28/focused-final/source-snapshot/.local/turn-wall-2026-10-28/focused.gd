extends SceneTree

const Landing = preload("res://tests/landing_turn_tests.gd")
const Walls = preload("res://tests/wall_ride_tests.gd")
const Presentation = preload("res://tests/wall_ride_presentation_tests.gd")
const Ollie = preload("res://tests/flat_ollie_tests.gd")
const Overnight = preload("res://tests/overnight_integration_tests.gd")
const Main = preload("res://game/main.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func _run() -> void:
	await Landing.run(self, _check)
	await Walls.run(self, _check)
	await Presentation.run(self, _check)
	await Ollie.run(self, _check)
	var game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.skater.spawn_position = Overnight.SAFE_SPAWN
	await Overnight._rotation_landings(self, game, _check)
	game.queue_free()
	await process_frame
	await physics_frame
	print("RESULT: ", passed, " passed, ", failed, " failed")
	quit(0 if failed == 0 else 1)
