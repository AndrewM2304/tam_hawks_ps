extends SceneTree
const InputSetup=preload("res://game/core/input_setup.gd")
const Main=preload("res://game/main.gd")
const Transition=preload("res://tests/transition_player_tests.gd")
const Round=preload("res://tests/round_coping_contact_tests.gd")
const Metadata=preload("res://tests/grind_contact_metadata_tests.gd")
const StyleTests=preload("res://tests/grind_style_tests.gd")
const Variants=preload("res://tests/grind_variant_contact_tests.gd")
const FeatureTests=preload("res://tests/feature_transition_ride_tests.gd")
const Connected=preload("res://tests/connected_transition_tests.gd")
var passes:int=0
var failures:int=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
 if ok:passes+=1
 else:failures+=1
 print("PASS " if ok else "FAIL ",label)
func _run()->void:
 InputSetup.register_actions()
 Metadata.run(_check)
 StyleTests.run(_check)
 await Variants.run(self,_check)
 await FeatureTests.run(self,_check)
 await Connected.run(self,_check)
 var game:Node=Main.new()
 game.persistence_enabled=false
 game.set_meta("pt24_design_preview",false)
 root.add_child(game)
 for tick:int in 35:
  await physics_frame
  await process_frame
 await Transition.run(self,game,_check)
 await Round.run(self,game,_check)
 print("REQUIRED02_FOCUSED_RESULT ",passes,"/",failures)
 quit(0 if failures==0 else 1)
