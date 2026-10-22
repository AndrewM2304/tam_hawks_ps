extends "res://docs/testing/camera-flow/observers/current_preview.gd"
var released:=false
var launched:=false
var landed_after:=false
var launch_y:=0.0
var launch_up:=0.0
var before_up:=0.0
var requested_before_up:=0.0
var request_tick:=0
var launch_tick:=0
var release_normal_y:=0.0
var peak_y:=0.0
func _run()->void:
	if DisplayServer.get_name()=='headless' or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	root.title='CURRENT CAMERA — charged ramp pop'
	game=MainScene.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.apply_settings({'graphics_quality':'balanced'},false)
	game.start_mode(true)
	var driver:=Driver.new();driver.audit=self;driver.process_physics_priority=-100;root.add_child(driver)
	var recorder:=Recorder.new();recorder.audit=self;recorder.process_physics_priority=100;root.add_child(recorder)
	game.skater.bailed.connect(func():if pipe_active:bails+=1)
	await _halfpipe()
	pipe_result.input='held physical W plus one held/released physical Space'
	var valid:=released and launched and landed_after and absf(launch_up-(before_up+13.0+release_normal_y*.25))<.15 and peak_y-launch_y>launch_up*launch_up/(2.0*22.0)*.85 and bails==0 and discontinuities==0 and errors.is_empty()
	var file:=FileAccess.open(output.path_join('pop.json'),FileAccess.WRITE)
	file.store_string(JSON.stringify({'valid':valid,'trial':pipe_result,'errors':errors,'images':images,'launched':launched,'landed':landed_after,'rise':peak_y-launch_y,'launch_up':launch_up,'before_up':before_up,'requested_before_up':requested_before_up,'request_tick':request_tick,'launch_tick':launch_tick,'release_normal_y':release_normal_y,'camera_rows':camera_rows},'\t'))
	print('RESULT: ',1 if valid else 0,' passed, ',0 if valid else 1,' failed')
	quit(0 if valid else 1)
func _drive(delta:float)->void:
	super._drive(delta)
	if not pipe_active:return
	if not released:
		_key(KEY_SPACE,true)
		if game.skater.transition_active and game.skater._transition.theta>=deg_to_rad(65.0):
			requested_before_up=game.skater.velocity.y
			request_tick=Engine.get_physics_frames()
			released=true
			_key(KEY_SPACE,false)
func _sample_pipe(delta:float)->void:
	super._sample_pipe(delta)
	if released and game.skater.airborne:
		if not launched:
			launched=true
			launch_y=game.skater.global_position.y
			launch_up=game.skater.velocity.y
			launch_tick=Engine.get_physics_frames()
			before_up=float(pipe_trace[-2].vertical_speed)
			release_normal_y=game.skater._ramp_air_normal.y
		peak_y=maxf(peak_y,game.skater.global_position.y)
	if launched and not game.skater.airborne:landed_after=true
