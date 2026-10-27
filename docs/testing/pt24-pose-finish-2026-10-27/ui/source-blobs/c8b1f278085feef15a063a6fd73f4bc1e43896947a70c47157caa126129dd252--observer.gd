extends SceneTree
const Main = preload("res://game/main.gd")
const Tests = preload("res://tests/menu_cancel_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	create_timer(42.0, true).timeout.connect(func(): print("FAIL: bounded menu timeout"); quit(2))
	var game := Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	await Tests.run(self, game, _check)
	paused = false
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
func _check(condition: bool, label: String) -> void:
	if condition: passed += 1; print("PASS: ", label)
	else: failed += 1; print("FAIL: ", label)
