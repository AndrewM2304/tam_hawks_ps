extends SceneTree
const MainScene=preload("res://game/main.tscn")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Review=preload("res://tests/camera_turn_review_tests.gd")
var game:Node
var output:String
var images:Array=[]
var rows:Array=[]
var errors:Array=[]
func _initialize()->void:call_deferred('_run')
func _run()->void:
	if DisplayServer.get_name()=='headless' or OS.get_cmdline_user_args().is_empty():quit(2);return
	create_timer(60.0,true).timeout.connect(func():printerr('Quiet capture watchdog');quit(2))
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	root.title='CURRENT CAMERA — quiet ordinary ollies and tricks'
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	print('QUIET_CAPTURE start')
	game=MainScene.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.apply_settings({'graphics_quality':'balanced'},false)
	for held:int in [2,24]:
		print('QUIET_CAPTURE trial ',held)
		game.start_mode(true)
		await Classic._frames(self,90)
		Classic._key(KEY_SPACE,true)
		await Classic._frames(self,held)
		await RenderingServer.frame_post_draw
		var label:='charged' if held>10 else 'tap'
		_capture(label+'-crouch')
		var initial_y:float=game.skater._camera.global_position.y
		var origin_y:float=game.skater.global_position.y
		var highest:=0.0
		var camera_span:=0.0
		var apex:=false
		var rising_frame:=false
		Classic._key(KEY_SPACE,false)
		for tick in 110:
			await Classic._frames(self,1)
			await RenderingServer.frame_post_draw
			if tick==3:Classic._key(KEY_J,true)
			if tick==5:Classic._key(KEY_J,false)
			var rider:Node3D=game.skater
			highest=maxf(highest,rider.global_position.y-origin_y)
			camera_span=maxf(camera_span,absf(rider._camera.global_position.y-initial_y))
			if not Review._framed(rider):errors.append(label+' unsafe frame '+str(tick))
			rows.append({'trial':label,'tick':Engine.get_physics_frames(),'rider':str(rider.global_position),'velocity':str(rider.velocity),'camera':str(rider._camera.global_position),'air':rider.airborne})
			if not rising_frame and highest>.25 and rider.velocity.y>0.0:
				rising_frame=true
				_capture(label+'-rise')
			if not apex and highest>.5 and rider.velocity.y<=0 and rider.airborne:
				apex=true
				_capture(label+'-apex')
		_capture(label+'-landed')
		if camera_span>=.10 or highest<(.8 if held<10 else 2.3) or not apex or not game.skater.is_on_floor():errors.append(label+' quiet/real-jump gate')
		print('QUIET_NATIVE trial=',label,' body_rise=',highest,' camera_y_span=',camera_span)
	var file:=FileAccess.open(output.path_join('quiet.json'),FileAccess.WRITE)
	file.store_string(JSON.stringify({'errors':errors,'images':images,'rows':rows,'limits':'Actual native production camera, mapped Space/J input, reset between trials only. Image readbacks excluded from timing admission.'},'\t'))
	print('RESULT: ',1 if errors.is_empty() else 0,' passed, ',0 if errors.is_empty() else 1,' failed')
	quit(0 if errors.is_empty() else 1)
func _capture(name:String)->void:
	print('QUIET_CAPTURE frame ',name)
	var picture:=root.get_texture().get_image()
	if picture.get_size()!=Vector2i(1280,800) or picture.save_png(output.path_join(name+'.png'))!=OK:errors.append('PNG '+name)
	images.append({'file':name+'.png','rider':str(game.skater.global_position),'camera':str(game.skater._camera.global_position),'framed':Review._framed(game.skater),'velocity':str(game.skater.velocity),'tick':Engine.get_physics_frames()})
