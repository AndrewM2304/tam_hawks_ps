extends SceneTree
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Motion=preload("res://tests/motion_fidelity_tests.gd")
const Acceptance=preload("res://tests/fidelity_acceptance_tests.gd")
const LineTests=preload("res://tests/line_design_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
var passed:=0
var failed:=0
func _initialize():_run.call_deferred()
func _check(ok: bool,label: String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	create_timer(180,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await Driver._frames(self,40)
	await Motion.run_main(self,game,_check)
	await Motion.run_main_support(self,game,_check)
	print("CURRENT ORDER MOTION: ",passed," passed, ",failed," failed")
	await Acceptance.run(self,game,_check)
	print("CURRENT ORDER ACCEPTANCE: ",passed," passed, ",failed," failed")
	await LineTests.run(self,game,_check)
	print("CURRENT ORDER LINE RESULT: ",passed," passed, ",failed," failed")
	game.free()
	quit(1 if failed>0 else 0)
