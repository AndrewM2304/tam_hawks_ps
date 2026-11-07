extends SceneTree
const Main=preload("res://game/main.tscn")
const Setup=preload("res://game/core/input_setup.gd")
const LineTests=preload("res://tests/line_design_tests.gd")
const ClydeSurface=preload("res://tests/clyde_surface_tests.gd")
const Routes=preload("res://tests/world_routes_tests.gd")
var passed:=0
var failed:=0
func _initialize():_run.call_deferred()
func _check(ok: bool,label: String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	Setup.register_actions()
	var game=Main.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await Routes.run(self,game.world,_check)
	await LineTests.run(self,game,_check)
	print("NOVEMBER FOCUSED RESULT: ",passed," passed, ",failed," failed")
	game.free()
	await process_frame
	await ClydeSurface.run(self,_check)
	print("NOVEMBER INCLUDING INVENTORY: ",passed," passed, ",failed," failed")
	quit(1 if failed>0 else 0)
