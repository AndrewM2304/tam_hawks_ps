extends SceneTree
const Main=preload("res://game/main.gd")
const Checks=preload("res://tests/fountain_finish_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var game=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 game.start_mode(true)
 for tick in 10:
  await physics_frame
  await process_frame
 await Checks.run(self,game,_check)
 print("RESULT: ",passed," passed, ",failed," failed")
 game.queue_free()
 await process_frame
 await physics_frame
 await process_frame
 quit(1 if failed else 0)
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;print("FAIL: ",label)
