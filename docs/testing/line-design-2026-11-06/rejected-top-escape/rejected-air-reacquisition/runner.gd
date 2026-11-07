extends SceneTree
const Main=preload("res://game/main.tscn")
const Setup=preload("res://game/core/input_setup.gd")
const LineTests=preload("res://tests/line_design_tests.gd")
var passed:=0
var failed:=0
func _initialize():_run.call_deferred()
func _check(ok: bool,label: String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	create_timer(120,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await LineTests.run_bank_jump_misses(self,game,_check)
	game.free()
	print("NOVEMBER BANK JUMP RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed>0 else 0)
