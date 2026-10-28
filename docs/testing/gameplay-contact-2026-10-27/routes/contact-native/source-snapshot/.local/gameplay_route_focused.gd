extends SceneTree
## Current production modules, with the same isolated Main fixture as RunTests.
const Clyde = preload("res://tests/clyde_surface_tests.gd")
const Classic = preload("res://tests/classic_tricks_integration_tests.gd")
const Fidelity = preload("res://tests/trick_fidelity_tests.gd")
const Main = preload("res://game/main.gd")
const Ride = preload("res://tests/grind_ride_tests.gd")
const Bounds = preload("res://tests/grind_capture_bounds_tests.gd")
const Index = preload("res://tests/grind_index_tests.gd")
const Intent = preload("res://tests/grind_intent_integration_tests.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: "+description)
	else:
		failed += 1
		push_error("FAIL: "+description)

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var mode: String = "all" if arguments.is_empty() else arguments[0]
	if mode in ["all", "grind", "contact"]:
		Ride.run(_check)
		Bounds.run(_check)
		Index.run(_check)
		await Intent.run(self,_check)
	if mode in ["all", "clyde", "contact"]:
		await Clyde.run(self,_check)
	if mode in ["all", "classic"]:
		await Classic.run(self,_check)
	if mode in ["all", "fidelity", "contact"]:
		var game = Main.new()
		game.persistence_enabled = false
		# Match the full-suite historical geometry fixture. Normal play stays on.
		game.set_meta("pt24_design_preview",false)
		root.add_child(game)
		for frame in 35:
			await physics_frame
			await process_frame
		await Fidelity.run(self,game,_check)
		game.queue_free()
		await process_frame
	print("RESULT: %d passed, %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)
