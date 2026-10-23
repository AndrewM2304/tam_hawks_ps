extends RefCounted
## Real charged release and native pose sampling; no per-tick motion/pose forcing.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
class Probe extends Node:
	var rider:CharacterBody3D
	var origin_y:=0.0
	var air_ticks:=0
	var seen:=false
	var peak:=0.0
	var front_lead:=0.0
	var level_error:=0.0
	var level_samples:=0
	var horizontal_error:=0.0
	var launch:=Vector3.ZERO
	func _ready()->void:process_physics_priority=100
	func _physics_process(_delta:float)->void:
		if not rider.airborne:return
		if not seen:seen=true;launch=rider.velocity
		air_ticks+=1;peak=maxf(peak,rider.global_position.y-origin_y)
		horizontal_error=maxf(horizontal_error,Vector2(rider.velocity.x-launch.x,rider.velocity.z-launch.z).length())
		var rig:RefCounted=rider._visual_rig
		var lead:float=rig._legs[0].foot.global_position.y-rig._legs[1].foot.global_position.y
		if air_ticks<=6:front_lead=maxf(front_lead,lead)
		if air_ticks>=13 and air_ticks<=19:
			level_samples+=1;level_error=maxf(level_error,absf(lead))
static func run(tree:SceneTree,check:Callable)->void:
	Classic.Setup.register_actions()
	for moving:bool in [false,true]:
		for held:int in [2,24]:
			var f:Dictionary=await Classic._fixture(tree)
			if moving:
				Input.action_press('push');await Classic._frames(tree,45);Input.action_release('push')
			var awards:Array[String]=[]
			f.rider.trick_performed.connect(func(id:String,_points:int):awards.append(id))
			Input.action_press('ollie');await Classic._frames(tree,held)
			var probe:=Probe.new();probe.rider=f.rider;probe.origin_y=f.rider.global_position.y;tree.root.add_child(probe)
			Input.action_release('ollie');await Classic._frames(tree,75)
			var charged:=held>10
			check.call(probe.seen and f.rider.is_on_floor() and awards==['Ollie'],'flat ollie: one mapped release makes one real jump and supported landing moving=%s held=%s'%[moving,held])
			check.call(probe.peak>(1.15 if charged else .75) and probe.peak<(1.45 if charged else .95) and probe.air_ticks>20 and probe.air_ticks<37,'flat ollie: calmer measured apex and airtime moving=%s held=%s'%[moving,held])
			check.call(probe.front_lead>.12 and probe.level_samples>3 and probe.level_error<.015,'flat ollie: front sole leads, rear follows into a level deck before apex moving=%s held=%s'%[moving,held])
			check.call(probe.horizontal_error<.001,'flat ollie: staged foot/deck motion adds no horizontal impulse moving=%s held=%s'%[moving,held])
			print('FLAT_OLLIE moving=',moving,' held=',held,' apex=',probe.peak,' airtime=',probe.air_ticks/60.0,' front_lead_m=',probe.front_lead,' level_error_m=',probe.level_error,' launch=',probe.launch)
			probe.queue_free();await Classic._dispose(tree,f)
	var fall:Dictionary=await Classic._fixture(tree)
	fall.rider.position.y+=1.0 # Initial unsupported fixture; never assigned during travel.
	await Classic._frames(tree,8)
	check.call(fall.rider.airborne and fall.rider._ollie_pose_remaining==0.0 and absf(fall.rider._board_visual.rotation.x)<.001,'flat ollie: falling from unsupported initial placement cannot invent a pop pose')
	await Classic._dispose(tree,fall)
	var cancel:Dictionary=await Classic._fixture(tree)
	Input.action_press('ollie');await Classic._frames(tree,24);Input.action_release('ollie');await Classic._frames(tree,3)
	var active:bool=cancel.rider._ollie_pose_remaining>0.0
	cancel.rider.begin_bail('pose_cancel')
	check.call(active and cancel.rider._ollie_pose_remaining==0.0,'flat ollie: actual bail cancels the launch pose')
	cancel.rider.reset_skater()
	check.call(cancel.rider._ollie_pose_remaining==0.0 and not cancel.rider.bailing,'flat ollie: explicit restart leaves no stale launch pose')
	await Classic._dispose(tree,cancel)
