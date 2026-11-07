extends SceneTree
const Motion=preload("res://tests/motion_fidelity_tests.gd")
const Main=preload("res://game/main.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred("run")
func run()->void:
	await Motion.run(self,check)
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await Motion.run_main(self,game,check)
	await Motion.run_main_support(self,game,check)
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
