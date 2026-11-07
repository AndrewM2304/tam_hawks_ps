extends SceneTree
const Main = preload("res://game/main.gd")
const Signs = preload("res://tests/fidelity_acceptance_tests.gd")
var passed := 0
var failed := 0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
 var game:=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 game.start_mode(true)
 for frame in 40:await physics_frame;await process_frame
 await Signs.run(self,game,_check)
 game.queue_free()
 await process_frame
 print("BODY AXIS RESULT: ",passed," passed, ",failed," failed")
 quit(1 if failed else 0)
