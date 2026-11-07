extends SceneTree
const Main=preload("res://game/main.gd")
const Clyde=preload("res://tests/pt24_clyde_flagship_tests.gd")
var passes:=0
var failures:Array[String]=[]
class Late extends Node:
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
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	if ok:passes+=1
	else:failures.append(label)
	print("PASS " if ok else "ASSERTION_FAILURE ",label)
func run()->void:
	var game:=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	var observer:=Late.new();observer.game=game;root.add_child(observer)
	await Clyde.run(self,game,check)
	var report:Dictionary={"passes":passes,"failures":failures,"physics_pose_pipeline":game.skater._d022_rows,"late_postCamera_models":observer.rows,"scope":"Matched originalC04construction/player/bankreturn, unchangedinputs/assertions. Puregetter instrumentation atposebegin/anticipation/airlandingprepost/poseend pluspostCamera currentandnativeNode3DGTImodels. NoactualGPU/pixel or withinrender fractionalproof, noFPS/M5."}
	var f:=FileAccess.open(OS.get_environment("D022_OUTPUT"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t",true,true));f.close()
	observer.queue_free();game.queue_free();await process_frame
	print("D022_MATCHED_RESULT ",passes," ",failures.size());quit(0 if failures.is_empty() else 1)
