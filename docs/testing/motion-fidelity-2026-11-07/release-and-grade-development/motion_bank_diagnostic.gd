extends SceneTree
const Main=preload("res://game/main.tscn")
const Setup=preload("res://game/core/input_setup.gd")
const Lines=preload("res://tests/line_design_tests.gd")
var passed:=0
var failed:=0
var samples:=0
func _initialize():_run.call_deferred()
func _check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	create_timer(120,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await Lines._uphill_rollback(self,game,73.5,12.0,_check,_observe)
	print("MOTION_BANK_DIAGNOSTIC ",passed,"/",failed)
	game.free()
	quit(1 if failed>0 else 0)
func _observe(phase:String,game:Node,tick:int)->void:
	var rider:Node=game.skater
	if rider.global_position.x<84.30 or samples>=12:return
	samples+=1
	var maximum:=-INF
	var at:=Vector3.ZERO
	for point:Vector3 in rider._visual_rig.board_contact_geometry().support_points:
		var actual:Vector3=rider._board_visual.to_global(point)
		if actual.x>maximum:maximum=actual.x;at=actual
	var contacts:Array=[]
	for slide:int in rider.get_slide_collision_count():
		var contact:KinematicCollision3D=rider.get_slide_collision(slide)
		for index:int in contact.get_collision_count():
			contacts.append({"point":contact.get_position(index),"normal":contact.get_normal(index),"label":contact.get_collider(index).get_meta("art_label",contact.get_collider(index).name),"shape":contact.get_collider_shape_index(index)})
	print("MOTION_BANK_WALL tick=",tick," physics=",Engine.get_physics_frames()," body=",rider.global_position,
		" speed=",rider.speed," floor_normal=",rider._native_floor_normal()," support=",rider._native_floor_hit(rider._native_floor_normal()),
		" board=",rider._board_visual.global_transform," board_max_x=",maximum," extremity=",at," wall_gap=",84.7-maximum,
		" offset=",rider._obstacle_visual_offset," model_clear=",rider._manual_model_frame_clear(rider._board_visual.global_transform)," contacts=",contacts)
