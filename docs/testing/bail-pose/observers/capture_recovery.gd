extends "res://docs/testing/bail-recovery/observers/current_audit.gd"
const Framing=preload("res://tests/camera_turn_review_tests.gd")
var trial_results:Array=[]
var push_requested:=false
var manual_requested:=false
class InputDriver extends Node:
	var audit:SceneTree
	func _ready()->void:process_physics_priority=-100
	func _physics_process(_delta:float)->void:
		if audit.push_requested!=Input.is_action_pressed('push'):Classic._key(KEY_W,audit.push_requested)
		if audit.manual_requested!=Input.is_action_pressed('manual'):Classic._key(KEY_M,audit.manual_requested)

var maximum_physics_step:=0.0
var trace_phase:=""
var trace_position:=Vector3.ZERO
func _run()->void:
	if DisplayServer.get_name()=='headless' or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	create_timer(90.0,true).timeout.connect(func():printerr('Recovery capture watchdog');quit(2))
	root.size=Vector2i(1280,800);root.content_scale_size=root.size
	root.title='CURRENT — physical bail and authored get-up; profile views diagnostic'
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	game=MainScene.instantiate();game.persistence_enabled=false;root.add_child(game)
	var driver:=InputDriver.new();driver.audit=self;root.add_child(driver)
	sampler=Sample.new();sampler.owner_audit=self;root.add_child(sampler)
	game.skater.bailed.connect(func():bails.append({'tick':Engine.get_physics_frames(),'at':str(game.skater.global_position),'velocity':str(game.skater.velocity),'trial':phase}))
	for reduced:bool in [false,true]:
		push_requested=false;manual_requested=false;Classic._release();phase='settle';game.start_mode(true)
		game.apply_settings({'graphics_quality':'balanced','reduced_motion':reduced},false)
		await Classic._frames(self,60)
		phase='reduced' if reduced else 'normal'
		maximum_physics_step=0.0;trace_phase=phase;trace_position=game.skater.global_position
		push_requested=true
		await Classic._frames(self,45)
		push_requested=false;manual_requested=true
		print('RECOVERY_RUNUP ',phase,' speed=',game.skater.speed)
		var stages:Array[String]=[];var seen:=false;var unsafe:=0
		var before_bails:=bails.size();var maximum_step:=0.0;var previous:Vector3=game.skater.global_position
		var entry:=Vector3.ZERO;var elapsed:=0.0
		for tick in 500:
			await Classic._frames(self,1);await create_timer(0.0).timeout
			maximum_step=maxf(maximum_step,previous.distance_to(game.skater.global_position));previous=game.skater.global_position
			unsafe+=int(not Framing._framed(game.skater))
			var stage:String=game.skater.bail_phase
			if not seen and game.skater.manual_active and game.skater.manual_balance>.85 and not stages.has('before'):
				stages.append('before');await capture(phase+'-before')
			if game.skater.bailing:
				if not seen:entry=game.skater.global_position
				seen=true;elapsed=game.skater.bail_elapsed
				if stage=='fall' and game.skater.bail_elapsed>.16 and not stages.has('fall'):
					stages.append('fall');await capture(phase+'-fall')
				if stage=='slide' and not stages.has('slide'):
					stages.append('slide');await capture(phase+'-slide')
				if stage=='get_up' and game.skater._bail_phase_elapsed>.30 and not stages.has('get_up'):
					stages.append('get_up');await capture(phase+'-get-up')
			elif seen:
				stages.append('ready');await capture(phase+'-ready');break
		maximum_step=maximum_physics_step
		if stages!=['before','fall','slide','get_up','ready'] or bails.size()!=before_bails+1 or unsafe or maximum_step>.30 or game.skater.bailing:errors.append(phase+' sequence/local/framing gate')
		trial_results.append({'trial':phase,'stages':stages,'bails':bails.size()-before_bails,'unsafe':unsafe,'maximum_step_m':maximum_step,'recovery_seconds':elapsed,'distance_from_impact_m':entry.distance_to(game.skater.global_position)})
		manual_requested=false
	FileAccess.open(output.path_join('recovery.json'),FileAccess.WRITE).store_string(JSON.stringify({'trials':trial_results,'errors':errors,'images':images,'maxima':maxima,'rows':rows,'bails':bails,'limits':'Actual production Main, mapped push/manual and no balance correction. Reset between normal/reduced trials only. Chase images are production camera; profile images explicitly freeze gameplay and place/restore camera. No synthesized images, per-tick motion forcing or timing admission.'},'\t'))
	print('RECOVERY_NATIVE ',trial_results)
	print('RESULT: ',2 if errors.is_empty() else 0,' passed, ',0 if errors.is_empty() else 1,' failed');quit(0 if errors.is_empty() else 1)
func sample()->void:
	if phase!='settle':
		if trace_phase==phase:maximum_physics_step=maxf(maximum_physics_step,trace_position.distance_to(game.skater.global_position))
		trace_phase=phase;trace_position=game.skater.global_position
	super.sample()
	if not rows.is_empty() and rows[-1].tick==Engine.get_physics_frames():
		rows[-1].bailing=game.skater.bailing;rows[-1].bail_phase=game.skater.bail_phase
		rows[-1].bail_elapsed=game.skater.bail_elapsed;rows[-1].pose_weight=game.skater._bail_pose_weight()
func capture(label:String)->void:
	await RenderingServer.frame_post_draw;save_frame(label+'-chase')
	var processing:bool=game.is_physics_processing();game.set_physics_process(false);paused=true
	var camera:Camera3D=game.skater._camera;var original:=camera.global_transform
	var at:Vector3=game.skater.global_position
	camera.global_position=at+Vector3(2.7,1.1,1.8);camera.look_at(at+Vector3.UP*.7)
	await RenderingServer.frame_post_draw;save_frame(label+'-profile')
	camera.global_transform=original;paused=false;game.set_physics_process(processing)
