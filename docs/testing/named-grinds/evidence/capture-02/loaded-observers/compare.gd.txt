extends SceneTree
## Fresh actual-map scenes, fixed mapped run-up, native-state grind requests.
const Original=preload("res://docs/testing/named-grinds/observers/original_timed_main.gd")
const Current=preload("res://docs/testing/named-grinds/observers/current_timed_main.gd")
const BaseSkater=preload("res://docs/testing/named-grinds/observers/baseline_skater.gd")
const NewSkater=preload("res://game/player/skater.gd")
const Native=preload("res://tests/named_grind_integration_tests.gd")
const Framing=preload("res://tests/camera_turn_review_tests.gd")
const WIDTH:=15
const BUTTONS:={KEY_R:JOY_BUTTON_RIGHT_STICK,KEY_W:JOY_BUTTON_DPAD_UP,KEY_SPACE:JOY_BUTTON_A,KEY_L:JOY_BUTTON_Y,KEY_D:JOY_BUTTON_DPAD_RIGHT}
var game:Node
var output:String
var active:=false
var label:=""
var ticks:=0
var started:=0
var count:=0
var data:=PackedFloat64Array()
var keys:Dictionary={}
var captures:Array=[]
var awards:Array=[]
var bails:=0
var landings:=0
var supported_returns:=0
var return_seen:=false
var pop_air_seen:=false
var input_reassertions:=0
var unsafe:=0
var requested:=false
var released_side:=false
var grind_ticks:=0
var popped:=false
var pop_tick:=0
var errors:Array=[]
var grind_times:=PackedInt64Array()
var entry_times:=PackedInt64Array()
var capture_times:=PackedInt64Array()
var pose_times:=PackedInt64Array()
var initial_static:Dictionary={}
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
	func reset()->void:inner.reset()
	func animate(delta:float,state:Dictionary)->void:
		var start:=Time.get_ticks_usec();inner.animate(delta,state)
		if audit.active:audit.pose_times.append(Time.get_ticks_usec()-start)
func _initialize()->void:call_deferred('_run')
func _run()->void:
	if DisplayServer.get_name()=='headless' or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800);root.content_scale_size=root.size
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	create_timer(180,true).timeout.connect(func():printerr('Named grind benchmark watchdog');quit(2))
	for kind:String in ['original','candidate']:
		var before:=OS.get_static_memory_usage();var nodes:Array=[]
		for n:int in 100:nodes.append(BaseSkater.new() if kind=='original' else NewSkater.new())
		initial_static[kind]=(OS.get_static_memory_usage()-before)/100.0
		for node:Node in nodes:node.free()
	var driver:=Driver.new();driver.audit=self;root.add_child(driver)
	var sampler:=Sampler.new();sampler.audit=self;root.add_child(sampler)
	RenderingServer.frame_post_draw.connect(record)
	for trial:String in ['original-before','candidate','original-after']:await run_trial(trial)
	RenderingServer.frame_post_draw.disconnect(record)
	FileAccess.open(output.path_join('startup-memory.json'),FileAccess.WRITE).store_string(JSON.stringify(initial_static,'\t'))
	print('RESULT: ',3 if errors.is_empty() else 0,' passed, ',0 if errors.is_empty() else 1,' failed');quit(0 if errors.is_empty() else 1)
func run_trial(trial:String)->void:
	release();active=false;label=trial
	if is_instance_valid(game):game.queue_free();await process_frame;await physics_frame
	game=Current.new() if trial=='candidate' else Original.new()
	game.persistence_enabled=false;root.add_child(game)
	game.apply_settings({'graphics_quality':'balanced'},false)
	game.skater.audit=self
	var timed_visual:=TimedVisual.new();timed_visual.inner=game.skater._visual_rig;timed_visual.audit=self;game.skater._visual_rig=timed_visual
	# Fixture setup only. Thereafter Restart and mapped input own all movement.
	game.skater.spawn_position=Vector3(12,.8,23)
	game.start_mode(true)
	game.skater.grind_captured.connect(func(id:String):
		if active:captures.append({'tick':ticks,'id':id,'style':game.skater.get('grind_style_id')}))
	game.skater.trick_performed.connect(func(title:String,_points:int):
		if active:awards.append({'tick':ticks,'name':title}))
	game.skater.bailed.connect(func():
		if active:bails+=1)
	game.skater.landed.connect(func(_clean:bool):
		if active:
			landings+=1
			if popped and pop_air_seen and not return_seen:return_seen=true;supported_returns+=1)
	for tick:int in 60:await physics_frame;await process_frame
	ticks=0;count=0;captures.clear();awards.clear();bails=0;landings=0;supported_returns=0;input_reassertions=0;unsafe=0;grind_times.clear();entry_times.clear();capture_times.clear();pose_times.clear()
	data.resize(30000*WIDTH);started=Time.get_ticks_usec();active=true
	while ticks<1933 or Time.get_ticks_usec()-started<32200000:
		await RenderingServer.frame_post_draw
		if Time.get_ticks_usec()-started>60000000:errors.append(trial+' timeout');break
	active=false;release();data.resize(count*WIDTH)
	if captures.size()!=5 or bails!=0 or supported_returns!=5 or not game.skater.is_on_floor() or unsafe!=0 or count<600 or grind_times.size()<50:errors.append(trial+' incomplete native workload')
	var memory:Dictionary={}
	for entry:Array in [['texture',RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED],['buffer',RenderingServer.RENDERING_INFO_BUFFER_MEM_USED],['video',RenderingServer.RENDERING_INFO_VIDEO_MEM_USED]]:memory[entry[0]]=RenderingServer.get_rendering_info(entry[1])
	FileAccess.open(output.path_join(trial+'.json'),FileAccess.WRITE).store_string(JSON.stringify({'columns':['wall_usec','tick','x','y','z','vx','vy','vz','draws','triangles','static_bytes','physics_usec','grinding','board_yaw','board_y'],'data':data,'row_count':count,'grind_usec':grind_times,'entry_attempt_usec':entry_times,'successful_capture_usec':capture_times,'rig_animate_usec':pose_times,'captures':captures,'awards':awards,'bails':bails,'landings':landings,'supported_returns':supported_returns,'input_reassertions':input_reassertions,'final_supported':game.skater.is_on_floor(),'unsafe':unsafe,'memory':memory,'errors':errors,'engine':Engine.get_version_info(),'adapter':RenderingServer.get_video_adapter_name(),'renderer':RenderingServer.get_current_rendering_method(),'resolution':[1280,800],'limits':'Exactef0eb9f Main/Skater/GrindRide controls with observer preload/timer redirects only; common current world metadata/catalogue, unchanged travel/collision/render geometry. Fixed mapped controller-button run-up, fresh native descending Triangle, five actual Exchange catches and pops. Alternating neutral/right selection changes board pose by design. No screenshots during measured intervals; no per-tick motion assignments.'}))
	print('NAMED_COMPARE ',trial,' captures=',captures,' awards=',awards,' samples=',count,' errors=',errors)
func drive()->void:
	if not active:return
	var phase:=ticks%420
	if phase==0:
		requested=false;released_side=false;grind_ticks=0;popped=false;pop_tick=0;return_seen=false;pop_air_seen=false
		key(KEY_L,false,'grind');key(KEY_D,false,'steer_right')
	key(KEY_R,phase==0,'restart')
	key(KEY_W,phase>=60 and phase<129,'push')
	var charging:=phase>=105 and phase<129
	if not requested and phase>=129 and phase<210 and game.skater.airborne and game.skater.velocity.y<0 and game.skater.global_position.y>1.05 and game.skater.global_position.y<1.2:
		requested=true
		key(KEY_D,int(ticks/420)%2==1,'steer_right')
		key(KEY_L,true,'grind')
	if requested and game.skater.grinding:
		grind_ticks+=1
		if not released_side:released_side=true;key(KEY_D,false,'steer_right')
		if grind_ticks>=12 and not popped:popped=true;pop_tick=ticks
	key(KEY_SPACE,charging or (popped and ticks-pop_tick<3),'ollie')
func sample()->void:
	if not active:return
	if popped and game.skater.airborne:pop_air_seen=true
	unsafe+=int(not Framing._framed(game.skater));ticks+=1
func key(code:Key,down:bool,action:String)->void:
	if down and bool(keys.get(code,false)) and not Input.is_action_pressed(action):keys[code]=false;input_reassertions+=1
	if bool(keys.get(code,false))==down:return
	keys[code]=down
	var event:=InputEventJoypadButton.new();event.device=0;event.button_index=BUTTONS[code];event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()
func release()->void:
	for pair:Array in [[KEY_R,'restart'],[KEY_W,'push'],[KEY_SPACE,'ollie'],[KEY_L,'grind'],[KEY_D,'steer_right']]:key(pair[0],false,pair[1])
	for action:StringName in InputMap.get_actions():Input.action_release(action)
func record()->void:
	if not active or ticks<120 or count>=30000:return
	var at:Vector3=game.skater.global_position;var velocity:Vector3=game.skater.velocity;var row:=count*WIDTH
	data[row]=Time.get_ticks_usec();data[row+1]=ticks
	data[row+2]=at.x;data[row+3]=at.y;data[row+4]=at.z;data[row+5]=velocity.x;data[row+6]=velocity.y;data[row+7]=velocity.z
	data[row+8]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	data[row+9]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	data[row+10]=Performance.get_monitor(Performance.MEMORY_STATIC)
	data[row+11]=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000000
	data[row+12]=int(game.skater.grinding);data[row+13]=game.skater._board_visual.global_basis.get_euler().y;data[row+14]=game.skater._board_visual.global_position.y;count+=1
