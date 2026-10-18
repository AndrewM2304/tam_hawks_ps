extends SceneTree
const Main=preload("res://game/main.gd")
const Combo=preload("res://tests/combo_integration_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var game=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 for frame in 35:
  await physics_frame
  await process_frame
 await Combo.run(self,game,_check)
 game.queue_free()
 await process_frame
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(0 if failed==0 else 1)
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
