extends SceneTree
const Main = preload("res://game/main.gd")
const Flagship = preload("res://tests/pt24_flagship_runs_tests.gd")
var passed:=0
var failed:=0
func _initialize(): _run.call_deferred()
func _check(ok:bool,label:String):
 if ok: passed+=1
 else: failed+=1
 print("PASS: " if ok else "FAIL: ",label)
func _run():
 var game:=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 game.start_mode(true)
 for tick in 12:
  await physics_frame
  await process_frame
 await Flagship.run(self,game,_check)
 game.queue_free()
 for tick in 3:
  await physics_frame
  await process_frame
 print("RESULT: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
