extends SceneTree
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Transition=preload("res://tests/transition_player_tests.gd")
const Round=preload("res://tests/round_coping_contact_tests.gd")
const Motion=preload("res://tests/motion_fidelity_tests.gd")
const Registry=preload("res://.local/motion_round_registry_helper.gd")
const Clyde=preload("res://tests/pt24_clyde_flagship_tests.gd")
var passes:int=0
var failures:Array[String]=[]
var modules:Array[Dictionary]=[]
var music_isolated:=true
class LateTrace extends Node:
	var game:Node
	var rows:Array[Dictionary]=[]
	func _ready()->void:process_priority=1000
	func _process(_delta:float)->void:
		var r:CharacterBody3D=game.skater
		var active:=false
		for sampler:Node in game.get_children():
			if sampler.has_method("_contact_failure") and bool(sampler.get("active")) and int(sampler.get("warmup_frames"))<=0:active=true;break
		if not active:return
		rows.append({"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames(),"camera_process":r.last_presentation_process_frame,"in_physics_frame":Engine.is_in_physics_frame(),"fraction":Engine.get_physics_interpolation_fraction(),"body":r._d022_matrix(r.global_transform),"body_GTI":r._d022_matrix(r.get_global_transform_interpolated()),"current":r._d022_capture(),"visual_GTI":r._d022_matrix(r._visual.get_global_transform_interpolated()),"board_GTI":r._d022_matrix(r._board_visual.get_global_transform_interpolated()),"head_GTI":r._d022_matrix(r._visual_rig._head.get_global_transform_interpolated()),"camera":r._d022_matrix(r._camera.global_transform)})

func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
 if ok:passes+=1
 else:failures.append(label)
 print("PASS " if ok else "FAIL ",label)
func _entry(label:String,old_pass:int,old_fail:int)->void:
 var row:Dictionary={"module":label,"passed":passes-old_pass,"failed":failures.size()-old_fail}
 modules.append(row)
 print("ACTUAL_ROUND_MODULE ",JSON.stringify(row))
func _main(legacy:bool)->Node:
 var game:Node=Main.new()
 music_isolated=music_isolated and not game.persistence_enabled
 game.persistence_enabled=false
 if legacy:game.set_meta("pt24_design_preview",false)
 root.add_child(game)
 music_isolated=music_isolated and not game.music._can_control and not game.music._persist
 return game
func _run()->void:
 Setup.register_actions()
 var game:Node=_main(true)
 for tick:int in 35:
  await physics_frame
  await process_frame
 var p:int=passes
 var f:int=failures.size()
 await Transition.run(self,game,_check)
 _entry("original_legacyMainTransition",p,f)
 p=passes;f=failures.size()
 await Round.run(self,game,_check)
 _entry("registered_publicRoundContact",p,f)
 game.queue_free()
 await physics_frame
 await process_frame
 game=_main(false)
 for tick:int in 40:
  await physics_frame
  await process_frame
 var inventory:Dictionary=Registry.capture(game)
 var inventory_file:=FileAccess.open(OS.get_environment("TAM_ACTUAL_ROUND_REGISTRY_RESULT"),FileAccess.WRITE)
 if inventory_file==null:push_error("Cannot write read-only ordinary Main registry");quit(2);return
 inventory_file.store_string(JSON.stringify(inventory,"\t",true,true)+"\n")
 inventory_file.close()
 p=passes;f=failures.size()
 await Motion.run_main(self,game,_check)
 await Motion.run_main_support(self,game,_check)
 _entry("original_defaultMainMotion_and_nativeSupport",p,f)
 p=passes;f=failures.size()
 var trace:=LateTrace.new();trace.game=game;root.add_child(trace)
 await Clyde.run(self,game,_check)
 _entry("original_fullClydeLocalPrefix_and_bankReturn",p,f)
 _check(music_isolated,"scripted legacy/default Main isolate personal Music/profile before and after tree entry")
 var controls:Dictionary=load("res://.local/handoff_controls.gd").run(game)
 var pipeline:Array=game.skater._d022_rows
 var late_models:Array=trace.rows
 trace.queue_free()
 var data:Dictionary={"passed":passes,"failed":failures.size(),"failures":failures,"modules":modules,"handoff_controls":controls,"physics_pose_pipeline":pipeline,"late_postCamera_models":late_models,
   "scope":"Actual installed modules and original inputs/checks: legacy Main Transition/publicRound, separate default Main Motion/nativeSupport and complete Clyde local prefix/bank return. No pixel/moving/M5/performance claim; ordinary full-runner global order remains separate."}
 var file:=FileAccess.open(OS.get_environment("TAM_ACTUAL_ROUND_FOCUS_RESULT"),FileAccess.WRITE)
 if file==null:push_error("Cannot write actual round focus result");quit(2);return
 file.store_string(JSON.stringify(data,"\t",true,true)+"\n")
 file.close()
 game.queue_free()
 await process_frame
 print("ACTUAL_ROUND_FOCUS_RESULT ",JSON.stringify(data))
 quit(0 if failures.is_empty() and controls.passed else 1)
