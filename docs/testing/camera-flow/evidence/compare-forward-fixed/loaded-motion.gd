extends "res://tools/area_audit_play.gd"
## Native post-draw camera telemetry without PNG readback during the trial.
const COLUMNS := 37
const MAX_ROWS := 30000
class TimedChase extends RefCounted:
	var inner:RefCounted
	var last_usec:=0
	var last_delta:=0.0
	var candidate:=true
	func reset()->void:inner.reset()
	func update(rider:CharacterBody3D,camera:Camera3D,delta:float,sensitivity:float,reduced_motion:bool)->void:
		last_delta=delta
		var started:=Time.get_ticks_usec()
		inner.update(rider,camera,delta,sensitivity,reduced_motion)
		last_usec=Time.get_ticks_usec()-started
var data:=PackedFloat64Array()
var count:=0
var timed:TimedChase
var clock_start:=0
var input_reassertions:=0
func _run()->void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().is_empty():quit(2);return
	# An interrupted/paused native draw loop must not outlive the bounded trial.
	create_timer(60.0,true).timeout.connect(func():
		printerr("Native camera watchdog: paused=",paused," render_samples=",count," physics_seconds=",seconds)
		quit(2))
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game=MainScene.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.apply_settings({"graphics_quality":"balanced"},false)
	timed=TimedChase.new()
	timed.inner=game.skater._camera_follow
	game.skater._camera_follow=timed
	game.start_mode(true)
	var driver:=Driver.new()
	driver.audit=self
	driver.process_physics_priority=-100
	root.add_child(driver)
	var recorder:=Recorder.new()
	recorder.audit=self
	recorder.process_physics_priority=100
	root.add_child(recorder)
	game.skater.bailed.connect(func():if pipe_active:bails+=1)
	data.resize(MAX_ROWS*COLUMNS)
	RenderingServer.frame_post_draw.connect(_record)
	clock_start=Time.get_ticks_usec()
	await _halfpipe()
	RenderingServer.frame_post_draw.disconnect(_record)
	data.resize(count*COLUMNS)
	var file:=FileAccess.open(output.path_join("motion.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"trial":pipe_result,"errors":errors,"row_count":count,"columns":["wall_usec","physics_tick","rider_x","rider_y","rider_z","velocity_x","velocity_y","velocity_z","camera_x","camera_y","camera_z","quat_x","quat_y","quat_z","quat_w","up_x","up_y","up_z","fov","transition","return_armed","theta","camera_update_usec","board_screen_x","board_screen_y","head_screen_x","head_screen_y","draws","triangles","floor","world_rear_x","world_rear_z","motion_pitch","selected_angle","heading_confirm","ramp_air","camera_delta"],"data":data,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1280,800],"diagnostic_always_on_top":true,"no_png_readback":true,"input_reassertions":input_reassertions,"source_camera_sha256":FileAccess.get_sha256("res://game/player/chase_camera.gd"),"limits":"One declared initial fixture then held physical W. Camera/axis proxy samples are native post-draw; no per-tick transform/velocity forcing, no PNG readbacks or per-frame dictionary/monitor allocation. Not human feel or whole-map performance."}))
	print("RESULT: ",1 if pipe_result.valid and errors.is_empty() and count>300 else 0," passed, ",0 if pipe_result.valid and errors.is_empty() and count>300 else 1," failed; render_rows=",count)
	quit(0 if pipe_result.valid and errors.is_empty() and count>300 else 1)
func _capture(_name:String)->void:pass
func _record()->void:
	if not pipe_active:return
	if count>=MAX_ROWS:
		if errors.is_empty():errors.append("Post-draw storage exhausted")
		return
	var camera:Camera3D=root.get_camera_3d()
	var rider:Node3D=game.skater
	var frame:=rider.get_global_transform_interpolated()
	var body:Node3D=rider.get_node("SkaterVisual") if rider.transition_active or (rider.airborne and rider._ramp_air) else rider.get_node("BodyCollision")
	var up:Vector3=body.get_global_transform_interpolated().basis.y.normalized()
	var q:=camera.global_basis.get_rotation_quaternion()
	var b:=camera.unproject_position(frame.origin+up*.12)
	var h:=camera.unproject_position(frame.origin+up*1.8)
	var at:=frame.origin
	var c:=camera.global_position
	var v:Vector3=game.skater.velocity
	var offset:=count*COLUMNS
	data[offset]=Time.get_ticks_usec()-clock_start
	data[offset+1]=Engine.get_physics_frames()
	data[offset+2]=at.x;data[offset+3]=at.y;data[offset+4]=at.z
	data[offset+5]=v.x;data[offset+6]=v.y;data[offset+7]=v.z
	data[offset+8]=c.x;data[offset+9]=c.y;data[offset+10]=c.z
	data[offset+11]=q.x;data[offset+12]=q.y;data[offset+13]=q.z;data[offset+14]=q.w
	data[offset+15]=up.x;data[offset+16]=up.y;data[offset+17]=up.z
	data[offset+18]=camera.fov
	data[offset+19]=int(game.skater.transition_active)
	data[offset+20]=int(not game.skater._vert_return.is_empty())
	data[offset+21]=game.skater._transition.theta if game.skater.transition_active else 0
	data[offset+22]=timed.last_usec
	data[offset+23]=b.x;data[offset+24]=b.y;data[offset+25]=h.x;data[offset+26]=h.y
	data[offset+27]=root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	data[offset+28]=root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	data[offset+29]=int(game.skater.is_on_floor())
	if timed.candidate:
		data[offset+30]=timed.inner._world_rear.x
		data[offset+31]=timed.inner._world_rear.z
		data[offset+32]=timed.inner._motion_pitch
		data[offset+33]=timed.inner._selected_angle
		data[offset+34]=timed.inner._heading_confirm
	else:
		for index in range(30,35):data[offset+index]=0.0
	data[offset+35]=int(game.skater._ramp_air)
	data[offset+36]=timed.last_delta
	count+=1

func _sample_pipe(delta:float)->void:
	super._sample_pipe(delta)
	pipe_trace[-1]["push_strength"]=Input.get_action_strength("push")
	pipe_trace[-1]["on_floor"]=game.skater.is_on_floor()

func _drive(delta:float)->void:
	# Native focus changes can clear Godot's held keyboard state while the
	# driver cache still says W is down. Re-emit the same physical key event;
	# never restore speed, transforms, contacts or other simulation state.
	if pipe_active and bool(key_states.get(KEY_W,false)) and not Input.is_action_pressed("push"):
		input_reassertions+=1
		print("HELD_W_REASSERT phase=",current_id," tick=",Engine.get_physics_frames())
		key_states[KEY_W]=false
	super._drive(delta)
