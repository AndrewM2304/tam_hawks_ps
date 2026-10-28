extends SceneTree
const Main=preload("res://game/main.gd")
const Grinding=preload("res://tests/grinding_tests.gd")
const Regression=preload("res://tests/grind_regression_tests.gd")
const Overnight=preload("res://tests/overnight_integration_tests.gd")
const Process=preload("res://tests/process_guard_tests.gd")
const Platform=preload("res://tests/platform_contact_tests.gd")
const Menu=preload("res://tests/menu_launch_tests.gd")
const Repertoire=preload("res://tests/full_repertoire_tests.gd")
const Connected=preload("res://tests/pt24_connected_runs_tests.gd")
var passed:=0
var failed:=0
class Poll extends Node:
	var game:Node
	var frame:=0
	var previous:=""
	var emitted:=0
	var admission_seen:=0
	func _physics_process(_delta:float)->void:
		frame+=1
		if not is_instance_valid(game):return
		var r=game.skater
		var signature:="%s/%s/%s/%s/%s/%s/%s"%[r.grinding,r.grind_trick_id,r.airborne,r.is_on_floor(),r.bail_active,r.special_name,r._grind_transfer.active]
		var relevant:=r.grinding or Input.is_action_pressed("grind") or r._grind_cooldown>0.15
		if emitted<260 and (signature!=previous or (relevant and frame%2==0)):
			print("LATE_CONTACT tick=",frame," at=",r.global_position," v=",r.velocity," state=",signature," body=",r._native_floor_valid," stylecool=",r._style_cooldown," flip=",r._flip_remaining," launchage=",r._launch_age," modelreason=",r._grind_clearance.last_rejection," obstruction=",r._grind_clearance.last_obstruction," entries=",game.score.trick_history," combo=",game.score.get_combo_value()," total=",game.score.total_score)
			emitted+=1
		if admission_seen<32 and not r.grinding and Input.is_action_pressed("grind") and r.airborne and absf(r.global_position.x-12)<.3 and game.score.trick_history.has("Ollie"):
			for line in game.world.get_grind_lines():
				if line.id!="Grind_Rail_Exchange":continue
				var near:Dictionary=line.closest(r.global_position)
				var shift:Vector3=r._grind._body_point(line,float(near.dist))-line.point_at(float(near.dist))
				near=line.closest(r.global_position-shift)
				var target:Vector3=r._grind._body_point(line,float(near.dist))
				var dir:float=1 if r.velocity.dot(line.dir_at(float(near.dist)))>=0 else -1
				print("LATE_ADMISSION ", {"at":r.global_position,"velocity":r.velocity,"target":target,"height":r.global_position.y-target.y,"gap":r.global_position.distance_to(target),"crown":r._grind_native_crown(line,float(near.dist)),"body":r._grind_capture_path_clear(line,r.global_position,target,float(near.dist),dir,r.velocity,false),"model":r._grind_candidate_supported(line,float(near.dist),dir),"request":r._grind_request_available(),"pose":r._ollie_pose_remaining})
				admission_seen+=1
		previous=signature
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(false)
	var poll:=Poll.new();poll.game=game;poll.process_physics_priority=100;root.add_child(poll)
	var args:=OS.get_cmdline_user_args();var mode:=args[0] if not args.is_empty() else "rail"
	match mode:
		"all":
			game.skater.spawn_position=Overnight.SAFE_SPAWN
			await Overnight._charged_launch(self,game,_check)
			await Overnight._special_timing(self,game,_check)
			await Process._reversed_deck_nollie(self,game,_check)
			await Platform._platform_ollie(self,game,_check)
			await Repertoire._playable_manuals(self,game,_check)
			await Grinding.run(self,game,_check)
			await Regression._ground_approach_and_obstruction(self,game,_check)
			await Regression._overtime_admission(self,game,_check)
			await Overnight._rail_process(self,game,_check)
			await Repertoire._playable_rail_pivot(self,game,_check)
			await Connected.run_player(self,game,_check)
		"connected":await Connected.run_player(self,game,_check)
		"known":
			game.skater.spawn_position=Overnight.SAFE_SPAWN
			await Overnight._charged_launch(self,game,_check)
			await Overnight._special_timing(self,game,_check)
			await Process._reversed_deck_nollie(self,game,_check)
			await Platform._platform_ollie(self,game,_check)
			await Repertoire._playable_manuals(self,game,_check)
		"common":
			await Grinding.run(self,game,_check)
			await Regression._ground_approach_and_obstruction(self,game,_check)
			await Regression._overtime_admission(self,game,_check)
			await Overnight._rail_process(self,game,_check)
			await Repertoire._playable_rail_pivot(self,game,_check)
		"grinding":await Grinding.run(self,game,_check)
		"approach":await Regression._ground_approach_and_obstruction(self,game,_check)
		"overtime":await Regression._overtime_admission(self,game,_check)
		"overnight":await Overnight.run(self,game,_check)
		"rail":await Overnight._rail_process(self,game,_check)
		"special":
			game.skater.spawn_position=Overnight.SAFE_SPAWN
			await Overnight._special_timing(self,game,_check)
		"repertoire":await Repertoire.run_playable(self,game,_check)
		"pivot":await Repertoire._playable_rail_pivot(self,game,_check)
		"platform":await Platform._platform_ollie(self,game,_check)
		"menu":await Menu._saved_back_matrix(self,game,_check)
		"process":await Process.run(self,game,_check)
		"nollie":await Process._reversed_deck_nollie(self,game,_check)
	poll.queue_free();game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
