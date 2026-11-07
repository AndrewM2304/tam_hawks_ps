extends SceneTree
const Transition=preload("res://tests/transition_player_tests.gd")
const Main=preload("res://game/main.gd")
var passes:int=0
var failures:int=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
 if ok:passes+=1
 else:failures+=1
 print("PASS " if ok else "FAIL ",label)
func _run()->void:
 print("TRANSITION_MAIN_CONSTRUCT")
 var game:Node=Main.new()
 game.persistence_enabled=false
 # Same established legacy Main fixture as actual tests/run_tests.gd. The
 # separate default-design line cohort remains a separate integration gate.
 game.set_meta("pt24_design_preview",false)
 root.add_child(game)
 for i:int in 35:
  await physics_frame
  await process_frame
 print("TRANSITION_MAIN_READY ",Engine.get_physics_frames())
 await Transition.run(self,game,_check)
 print("REQUIRED02_FOCUSED_RESULT ",passes,"/",failures)
 quit(0 if failures==0 else 1)
