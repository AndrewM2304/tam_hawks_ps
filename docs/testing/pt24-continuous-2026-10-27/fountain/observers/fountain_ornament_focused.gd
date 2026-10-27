extends SceneTree
const Main=preload("res://game/main.gd")
const Ornament=preload("res://tests/fountain_ornament_tests.gd")
const Finish=preload("res://tests/fountain_finish_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var game:=Main.new()
 game.persistence_enabled=false
 _check(not game.has_meta("pt24_design_preview"),"ornament fixture: no content override before tree entry")
 root.add_child(game)
 game.start_mode(true)
 for frame in 30:
  await physics_frame
  await process_frame
 _check(not game.music._can_control and not game.music._persist,"ornament fixture: no personal Music or profile access")
 await Finish.run(self,game,_check)
 await Ornament.run(self,game,_check)
 print("RESULT: ",passed," passed, ",failed," failed")
 quit(1 if failed else 0)
func _check(value:bool,label:String)->void:
 if value:passed+=1;print("PASS: ",label)
 else:failed+=1;print("FAIL: ",label)
