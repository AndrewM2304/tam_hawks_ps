extends "res://docs/testing/camera-flow/observers/motion.gd"
## Fresh identical scene instances, normal input, no readback during timed phases.
const Original = preload("res://docs/testing/camera-pop/observers/baseline_camera.gd")
const Candidate = preload("res://game/player/chase_camera.gd")
var columns: Array[String] = ["wall_usec","physics_tick","rider_x","rider_y","rider_z","velocity_x","velocity_y","velocity_z","camera_x","camera_y","camera_z","quat_x","quat_y","quat_z","quat_w","up_x","up_y","up_z","fov","transition","return_armed","theta","camera_update_usec","board_screen_x","board_screen_y","head_screen_x","head_screen_y","draws","triangles","floor","world_rear_x","world_rear_z","motion_pitch","selected_angle","heading_confirm","ramp_air","camera_delta"]
func _run()->void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().is_empty():quit(2);return
	create_timer(200.0,true).timeout.connect(func():
		printerr("Native comparison watchdog: paused=",paused," phase=",current_id," samples=",count," seconds=",seconds)
		quit(2))
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var driver:=Driver.new();driver.audit=self;driver.process_physics_priority=-100;root.add_child(driver)
	var recorder:=Recorder.new();recorder.audit=self;recorder.process_physics_priority=100;root.add_child(recorder)
	RenderingServer.frame_post_draw.connect(_record)
	for label:String in ["original-before","candidate","original-after"]:
		await _trial(label)
	RenderingServer.frame_post_draw.disconnect(_record)
	print("RESULT: ",3 if errors.is_empty() else 0," passed, ",0 if errors.is_empty() else 1," failed")
	quit(0 if errors.is_empty() else 1)
func _record()->void:
	if Time.get_ticks_usec()-clock_start<2000000:return
	super._record()
func _trial(label:String)->void:
	root.title="CURRENT CAMERA — candidate" if label=="candidate" else "REFERENCE CAMERA — original control ("+label+")"
	_release();active=false;pipe_active=false;current_id=label
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
		await physics_frame
	game=MainScene.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.apply_settings({"graphics_quality":"balanced"},false)
	game.skater.bailed.connect(func():if pipe_active:bails+=1)
	timed=TimedChase.new();timed.candidate=label=="candidate"
	timed.inner=Candidate.new() if timed.candidate else Original.new()
	game.skater._camera_follow=timed
	game.skater.spawn_position=Vector3(-42,2.8,60.5)
	game.start_mode(true)
	game.skater.rotation.y=-PI*0.5
	game.skater.reset_physics_interpolation()
	var settle_start:=Time.get_ticks_usec();var stable:=0
	while stable<3 and Time.get_ticks_usec()-settle_start<20000000:
		await RenderingServer.frame_post_draw
		stable=stable+1 if game.skater.is_on_floor() and game.skater.velocity.length()<0.05 else 0
	if stable<3:errors.append(label+": unsupported initial fixture")
	# Render-rate-dependent three-frame settling is insufficient for an A/B/A
	# physical reset. Give every fixture the same full second of native physics.
	for tick in 60:
		await physics_frame
		await process_frame
	game.skater._camera.fov=68.0
	game.skater._camera_follow.reset()
	seconds=0.0;bails=0;discontinuities=0;distance=0.0;count=0
	pipe_trace.clear();data.resize(MAX_ROWS*COLUMNS);last_position=game.skater.global_position
	clock_start=Time.get_ticks_usec();pipe_active=true
	while (seconds<32.2 or Time.get_ticks_usec()-clock_start<32200000) and bails==0 and discontinuities==0 and errors.is_empty():
		await RenderingServer.frame_post_draw
		if Time.get_ticks_usec()-clock_start>60000000:errors.append(label+": timed out");break
	pipe_active=false;_release();data.resize(count*COLUMNS)
	if bails or discontinuities or count<600:errors.append(label+": incomplete physical/render trial")
	var memory:Dictionary={}
	for entry:Array in [["texture",RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED],["buffer",RenderingServer.RENDERING_INFO_BUFFER_MEM_USED],["video",RenderingServer.RENDERING_INFO_VIDEO_MEM_USED]]:
		memory[entry[0]]=RenderingServer.get_rendering_info(entry[1])
	var file:=FileAccess.open(output.path_join(label+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"columns":columns,"data":data,"row_count":count,"trial":{"label":label,"sim_seconds":seconds,"bails":bails,"discontinuities":discontinuities,"distance_m":distance,"trace_rows":pipe_trace.size()},"memory":memory,"errors":errors,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1280,800],"diagnostic_always_on_top":true,"warmup_seconds":2.0,"input_reassertions":input_reassertions,"no_png_readback":true}))
	_write_trace(label,pipe_trace)
	print("CAMERA_COMPARE ",label," samples=",count," distance=",distance," errors=",errors)
