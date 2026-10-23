extends SceneTree
const MainScene=preload("res://game/main.tscn")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Framing=preload("res://tests/camera_turn_review_tests.gd")
var game:Node
var output:String
var desired_ollie:=false
var phase:="settle"
var rows:Array=[]
var images:Array=[]
var errors:Array=[]
var air_age:=0
var peak:=0.0
var origin_y:=0.0
var initial_camera_y:=0.0
var camera_span:=0.0
var pending_front:=false
var front_requested:=false
var native_front_lead:=0.0
var saved_processing:=true
var frozen:=false
class Driver extends Node:
	var audit:SceneTree
	func _ready()->void:process_physics_priority=-100
	func _physics_process(_delta:float)->void:
		if audit.desired_ollie!=Input.is_action_pressed('ollie'):Classic._key(KEY_SPACE,audit.desired_ollie)
class Sampler extends Node:
	var audit:SceneTree
	func _ready()->void:process_physics_priority=100
	func _physics_process(_delta:float)->void:audit.sample()
func _initialize()->void:call_deferred('_run')
func _run()->void:
	if DisplayServer.get_name()=='headless' or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800);root.content_scale_size=root.size
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	root.title='CURRENT — calmer flat ollie; original front-foot lead and rear-foot level'
	game=MainScene.instantiate();game.persistence_enabled=false;root.add_child(game)
	game.apply_settings({'graphics_quality':'balanced'},false)
	var driver:=Driver.new();driver.audit=self;root.add_child(driver)
	var sampler:=Sampler.new();sampler.audit=self;root.add_child(sampler)
	var trials:Array=[]
	for held:int in [2,24]:
		phase='settle';desired_ollie=false;Classic._release();game.start_mode(true);await Classic._frames(self,60)
		desired_ollie=true;await Classic._frames(self,held)
		phase='charged' if held>10 else 'tap';air_age=0;peak=0.0;camera_span=0.0;pending_front=false;front_requested=false;native_front_lead=0.0
		origin_y=game.skater.global_position.y;initial_camera_y=game.skater._camera.global_position.y
		await capture(phase+'-crouch')
		desired_ollie=false
		var stages:Array[String]=[];var maximum_front:=0.0;var level_error:=INF
		for tick in 100:
			await Classic._frames(self,1)
			var rig:RefCounted=game.skater._visual_rig
			var lead:float=rig._legs[0].foot.global_position.y-rig._legs[1].foot.global_position.y
			if game.skater.airborne:
				maximum_front=maxf(maximum_front,lead)
				if pending_front and not stages.has('front'):
					pending_front=false;stages.append('front');await capture(phase+'-front-lead')
				if air_age>=13 and not stages.has('level'):
					level_error=absf(lead);stages.append('level');await capture(phase+'-rear-level')
				if game.skater.velocity.y<=0 and not stages.has('apex'):
					stages.append('apex');await capture(phase+'-apex')
			elif not stages.is_empty():stages.append('landed');await capture(phase+'-landed');break
		maximum_front=native_front_lead
		var valid:=stages==['front','level','apex','landed'] and maximum_front>.12 and level_error<.02 and peak>(1.15 if held>10 else .75) and peak<(1.45 if held>10 else .95) and camera_span<.1
		if not valid:errors.append(phase+' sequence/height/quiet-camera gate')
		trials.append({'held':held,'stages':stages,'peak_m':peak,'front_lead_m':maximum_front,'level_error_m':level_error,'camera_y_span_m':camera_span,'valid':valid})
	FileAccess.open(output.path_join('capture.json'),FileAccess.WRITE).store_string(JSON.stringify({'trials':trials,'errors':errors,'images':images,'rows':rows,'limits':'Actual production Main and mapped key edges before native physics. Native sample per tick; snapshot readbacks freeze SceneTree/Main physics. Chase is production camera; profile explicitly placed/restored for diagnosis. No pose/motion assignment, synthesized images or timing admission.'},'\t'))
	print('FLAT_NATIVE ',trials);print('RESULT: ',2 if errors.is_empty() else 0,' passed, ',0 if errors.is_empty() else 1,' failed');quit(0 if errors.is_empty() else 1)
func sample()->void:
	if phase=='settle':return
	if game.skater.airborne:air_age+=1
	peak=maxf(peak,game.skater.global_position.y-origin_y)
	camera_span=maxf(camera_span,absf(game.skater._camera.global_position.y-initial_camera_y))
	if not Framing._framed(game.skater):errors.append(phase+' actual framing tick '+str(Engine.get_physics_frames()))
	var rig:RefCounted=game.skater._visual_rig
	if game.skater.airborne and air_age<=6:native_front_lead=maxf(native_front_lead,rig._legs[0].foot.global_position.y-rig._legs[1].foot.global_position.y)
	if game.skater.airborne and air_age==3 and not front_requested:
		front_requested=true;pending_front=true;freeze_scene()
	rows.append({'phase':phase,'tick':Engine.get_physics_frames(),'age':air_age,'at':str(game.skater.global_position),'velocity':str(game.skater.velocity),'front_y':rig._legs[0].foot.global_position.y,'rear_y':rig._legs[1].foot.global_position.y,'pitch':game.skater._board_visual.rotation.x,'camera':str(game.skater._camera.global_position)})
func freeze_scene()->void:
	saved_processing=game.is_physics_processing();game.set_physics_process(false);paused=true;frozen=true
func capture(label:String)->void:
	if not frozen:freeze_scene()
	var camera:Camera3D=game.skater._camera;var original:=camera.global_transform
	await RenderingServer.frame_post_draw;save(label+'-chase',false)
	camera.global_position=game.skater.global_position+Vector3(2.6,1.0,1.7);camera.look_at(game.skater.global_position+Vector3.UP*.8)
	await RenderingServer.frame_post_draw;save(label+'-profile',true)
	camera.global_transform=original;paused=false;game.set_physics_process(saved_processing);frozen=false
func save(label:String,profile:bool)->void:
	var picture:=root.get_texture().get_image();var file:=label+'.png'
	if picture.save_png(output.path_join(file))!=OK:errors.append('PNG '+file)
	images.append({'file':file,'diagnostic_camera':profile,'tick':Engine.get_physics_frames(),'air_age':air_age,'at':str(game.skater.global_position),'pitch':game.skater._board_visual.rotation.x})
