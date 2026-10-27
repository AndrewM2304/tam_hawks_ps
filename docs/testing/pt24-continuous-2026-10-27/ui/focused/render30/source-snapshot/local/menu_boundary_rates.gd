extends SceneTree
const Main=preload("res://game/main.gd")
const Tests=preload("res://tests/menu_launch_tests.gd")
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	create_timer(45.0,true).timeout.connect(func(): print("FAIL: menu launch deadline"); quit(2))
	var game:=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await Tests.run_boundary(self,game,_check)
	paused=false
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
