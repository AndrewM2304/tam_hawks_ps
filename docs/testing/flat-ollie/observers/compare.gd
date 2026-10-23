extends SceneTree
## Fixed mapped-input 7s attempts; explicit Restart is the only placement action.
const Reference=preload("res://docs/testing/flat-ollie/observers/baseline_main.gd")
const Current=preload("res://game/main.gd")
const Framing=preload("res://tests/camera_turn_review_tests.gd")
const WIDTH:=19
const MAX_ROWS:=30000
var game:Node
var output:String
var active:=false
var trial:=""
var ticks:=0
var count:=0
var clock_start:=0
var data:=PackedFloat64Array()
var trace:Array=[]
var keys:Dictionary={}
var bail_count:=0
var jump_count:=0
var unsafe:=0
var flights:Array=[]
var flight:Dictionary={}
var flight_age:=0
var bail_tick:=-1
var restarts:=0
var reassertions:=0
var maximum_bail_step:=0.0
var previous:=Vector3.ZERO
var errors:Array=[]
var pose_timer:TimedVisual
class Driver extends Node:
	var audit:SceneTree
	func _ready()->void:process_physics_priority=-100
	func _physics_process(_delta:float)->void:audit.drive()
class Sampler extends Node:
	var audit:SceneTree
	func _ready()->void:process_physics_priority=100
	func _physics_process(_delta:float)->void:audit.sample()
class TimedVisual extends RefCounted:
	var inner:RefCounted
	var audit:SceneTree
	var values:=PackedInt64Array()
	var count:=0
	func reset()->void:inner.reset()
	func animate(delta:float,state:Dictionary)->void:
		var start:=Time.get_ticks_usec();inner.animate(delta,state)
		if audit.active and audit.ticks>=120 and count<values.size():values[count]=Time.get_ticks_usec()-start;count+=1
func _initialize()->void:call_deferred('_run')
func _run()->void:
	if DisplayServer.get_name()=='headless' or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	create_timer(180.0,true).timeout.connect(func():printerr('Recovery benchmark watchdog');quit(2))
	root.size=Vector2i(1280,800);root.content_scale_size=root.size
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	var driver:=Driver.new();driver.audit=self;root.add_child(driver)
	var sampler:=Sampler.new();sampler.audit=self;root.add_child(sampler)
	RenderingServer.frame_post_draw.connect(record)
	for label:String in ['original-before','candidate','original-after']:await run_trial(label)
	RenderingServer.frame_post_draw.disconnect(record)
	print('RESULT: ',3 if errors.is_empty() else 0,' passed, ',0 if errors.is_empty() else 1,' failed');quit(0 if errors.is_empty() else 1)
func run_trial(label:String)->void:
	release();active=false;trial=label
	root.title='CURRENT calmer flat ollie' if label=='candidate' else 'REFERENCE high flat ollie — '+label
	if is_instance_valid(game):game.queue_free();await process_frame;await physics_frame
	game=Current.new() if label=='candidate' else Reference.new()
	game.persistence_enabled=false;root.add_child(game);game.apply_settings({'graphics_quality':'balanced'},false);game.start_mode(true)
	pose_timer=TimedVisual.new();pose_timer.inner=game.skater._visual_rig;pose_timer.audit=self;pose_timer.values.resize(4096);game.skater._visual_rig=pose_timer
	game.skater.trick_performed.connect(func(id:String,_points:int):
		if active and id=='Ollie':
			jump_count+=1;flight_age=0;flight={'origin':game.skater.global_position.y,'peak':0.0,'front_lead':0.0,'air_ticks':0})
	game.skater.landed.connect(func(_clean:bool):
		if active and not flight.is_empty():flights.append(flight.duplicate());flight={})
	game.skater.bailed.connect(func():
		if active:bail_count+=1;bail_tick=Engine.get_physics_frames())
	for tick in 60:await physics_frame;await process_frame
	ticks=0;count=0;bail_count=0;jump_count=0;unsafe=0;flights.clear();flight.clear();bail_tick=-1;restarts=0;reassertions=0;maximum_bail_step=0;trace.clear()
	previous=game.skater.global_position;data.resize(MAX_ROWS*WIDTH);clock_start=Time.get_ticks_usec();active=true
	while ticks<1933 or Time.get_ticks_usec()-clock_start<32200000:
		await RenderingServer.frame_post_draw
		if Time.get_ticks_usec()-clock_start>60000000:errors.append(label+' timeout');break
	active=false;release();data.resize(count*WIDTH)
	if count<600 or bail_count!=0 or jump_count!=5 or flights.size()!=5 or pose_timer.count<1700 or unsafe>0:errors.append(label+' incomplete input/recovery workload')
	var memory:Dictionary={}
	for entry:Array in [['texture',RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED],['buffer',RenderingServer.RENDERING_INFO_BUFFER_MEM_USED],['video',RenderingServer.RENDERING_INFO_VIDEO_MEM_USED]]:memory[entry[0]]=RenderingServer.get_rendering_info(entry[1])
	FileAccess.open(output.path_join(label+'.json'),FileAccess.WRITE).store_string(JSON.stringify({'columns':['wall_usec','tick','x','y','z','vx','vy','vz','camera_x','camera_y','camera_z','draws','triangles','frame_static_bytes','frame_physics_usec','bailing','phase_tick','board_pitch','front_sole_lead_m'],'data':data,'row_count':count,'trace':trace,'pose_update_usec':pose_timer.values.slice(0,pose_timer.count),'memory':memory,'bails':bail_count,'unsafe_frames':unsafe,'jumps':jump_count,'flights':flights,'restarts':restarts,'input_reassertions':reassertions,'maximum_bail_tick_step_m':maximum_bail_step,'errors':errors,'engine':Engine.get_version_info(),'adapter':RenderingServer.get_video_adapter_name(),'resolution':[1280,800],'renderer':RenderingServer.get_current_rendering_method(),'limits':'Matched fixed mapped input/time, fresh scenes and exactde6505d project Main/Skater/Visual/TrickAnimation controls with preload redirects only. Flat trajectories intentionally differ. No PNG readbacks or per-tick pose/motion assignment.'}))
	print('RECOVERY_COMPARE ',label,' samples=',count,' bails=',bail_count,' max_bail_step=',maximum_bail_step,' errors=',errors)
func drive()->void:
	if not active:return
	var phase_tick:=ticks%420
	key(KEY_R,phase_tick==0,'restart')
	if phase_tick==0:restarts+=1
	key(KEY_W,phase_tick>=60 and phase_tick<105,'push')
	key(KEY_SPACE,phase_tick>=105 and phase_tick<129,'ollie')
func key(code:Key,down:bool,action:String)->void:
	if down and bool(keys.get(code,false)) and not Input.is_action_pressed(action):keys[code]=false;reassertions+=1
	if bool(keys.get(code,false))==down:return
	keys[code]=down
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()
func release()->void:
	for pair:Array in [[KEY_R,'restart'],[KEY_W,'push'],[KEY_SPACE,'ollie']]:key(pair[0],false,pair[1])
	for action:StringName in InputMap.get_actions():Input.action_release(action)
func sample()->void:
	if not active:return
	var at:Vector3=game.skater.global_position
	unsafe+=int(not Framing._framed(game.skater))
	if bail_tick==Engine.get_physics_frames():maximum_bail_step=maxf(maximum_bail_step,at.distance_to(previous))
	previous=at
	if game.skater.airborne and not flight.is_empty():
		flight_age+=1;flight.air_ticks=flight_age;flight.peak=maxf(float(flight.peak),at.y-float(flight.origin))
		var rig:RefCounted=pose_timer.inner
		if flight_age<=6:flight.front_lead=maxf(float(flight.front_lead),rig._legs[0].foot.global_position.y-rig._legs[1].foot.global_position.y)
	trace.append({'tick':ticks,'at':[at.x,at.y,at.z],'velocity':[game.skater.velocity.x,game.skater.velocity.y,game.skater.velocity.z],'bailing':(game.skater.get('bailing')==true),'phase':str(game.skater.get('bail_phase'))})
	ticks+=1
func record()->void:
	if not active or ticks<120 or count>=MAX_ROWS:return
	var at:Vector3=game.skater.global_position;var velocity:Vector3=game.skater.velocity;var camera:Camera3D=game.skater._camera
	var row:=count*WIDTH
	data[row]=Time.get_ticks_usec();data[row+1]=ticks
	data[row+2]=at.x;data[row+3]=at.y;data[row+4]=at.z
	data[row+5]=velocity.x;data[row+6]=velocity.y;data[row+7]=velocity.z
	data[row+8]=camera.global_position.x;data[row+9]=camera.global_position.y;data[row+10]=camera.global_position.z
	data[row+11]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	data[row+12]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	data[row+13]=Performance.get_monitor(Performance.MEMORY_STATIC)
	data[row+14]=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000000.0
	data[row+15]=int((game.skater.get('bailing')==true));data[row+16]=ticks%420
	data[row+17]=game.skater._board_visual.rotation.x
	var rig:RefCounted=pose_timer.inner
	data[row+18]=rig._legs[0].foot.global_position.y-rig._legs[1].foot.global_position.y
	count+=1
