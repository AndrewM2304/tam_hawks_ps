extends RefCounted
## Real charged release and native pose sampling; no per-tick motion/pose forcing.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Authentic=preload("res://tests/authentic_pose_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const BoardGeometry=preload("res://tests/board_geometry_tests_support.gd")
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
	var apex_tick:=0
	var apex_hips:=0.0
	var first_level_tick:=-1
	var neutral_hips:=0.0
	var lowest_landing_hips:=INF
	var lowest_landing_tick:=-1
	var landing_samples:=0
	var maximum_pose_step:=0.0
	var maximum_grip_error:=0.0
	var minimum_sole_y:=INF
	var weighted:=true
	var clothing:=true
	var data:Dictionary
	var previous:Array[Vector3]=[]
	func _ready()->void:process_physics_priority=100
	func _physics_process(_delta:float)->void:
		if not seen and not rider.airborne:return
		var rig:RefCounted=rider._visual_rig
		if rider.airborne:
			if not seen:seen=true;launch=rider.velocity
			air_ticks+=1
			weighted=weighted and bool(rider.get("_weighted_ollie_air"))
			var height:float=rider.global_position.y-origin_y
			if height>peak:peak=height;apex_tick=air_ticks;apex_hips=rig._upper.position.y
			horizontal_error=maxf(horizontal_error,Vector2(rider.velocity.x-launch.x,rider.velocity.z-launch.z).length())
			var lead:float=rig._legs[0].foot.global_position.y-rig._legs[1].foot.global_position.y
			if air_ticks<=8:front_lead=maxf(front_lead,lead)
			if front_lead>.12 and first_level_tick<0 and absf(lead)<.015:first_level_tick=air_ticks
			if air_ticks>=16:
				level_samples+=1;level_error=maxf(level_error,absf(lead))
		else:
			landing_samples+=1
			var hips:float=rig._upper.position.y
			if hips<lowest_landing_hips:lowest_landing_hips=hips;lowest_landing_tick=landing_samples
		var markers:Array[Vector3]=[]
		for marker:Vector3 in Authentic._markers(rig):markers.append(rider.to_local(marker))
		if previous.size()==markers.size():maximum_pose_step=maxf(maximum_pose_step,Authentic._marker_delta(previous,markers))
		previous=markers
		var sample:Dictionary=Body._sample(rider,data)
		clothing=clothing and sample.finite and sample.seam<.08 and sample.joint_gap<.06 and sample.neck_gap<.05
		for leg:Dictionary in rig._legs:
			if air_ticks>=8:maximum_grip_error=maxf(maximum_grip_error,BoardGeometry.grip_distance(rig,leg.foot.to_global(Authentic.SOLE)))
			for point:Vector3 in rig._sole_points:minimum_sole_y=minf(minimum_sole_y,leg.foot.to_global(point).y)
static func run(tree:SceneTree,check:Callable)->void:
	Classic.Setup.register_actions()
	for moving:bool in [false,true]:
		for held:int in [2,24]:
			var f:Dictionary=await Classic._fixture(tree)
			var neutral_hips:float=f.rider._visual_rig._upper.position.y
			if moving:
				Input.action_press('push');await Classic._frames(tree,45);Input.action_release('push')
			var awards:Array[String]=[]
			f.rider.trick_performed.connect(func(id:String,_points:int):awards.append(id))
			Input.action_press('ollie');await Classic._frames(tree,held)
			var probe:=Probe.new();probe.rider=f.rider;probe.origin_y=f.rider.global_position.y
			probe.neutral_hips=neutral_hips;probe.data=Body._prepare(f.rider._visual_rig);tree.root.add_child(probe)
			Input.action_release('ollie');await Classic._frames(tree,75)
			var charged:=held>10
			check.call(probe.seen and probe.weighted and f.rider.is_on_floor() and awards==['Ollie'],'flat ollie: one mapped release earns the weighted profile once and a supported landing moving=%s held=%s'%[moving,held])
			check.call(probe.peak>(1.15 if charged else .75) and probe.peak<(1.45 if charged else .95) and probe.air_ticks>=(36 if charged else 28) and probe.air_ticks<=(42 if charged else 35),'flat ollie: unchanged measured height has a slower weighted flight moving=%s held=%s'%[moving,held])
			check.call(probe.front_lead>.12 and probe.first_level_tick>0 and probe.first_level_tick<=probe.apex_tick and probe.level_samples>3 and probe.level_error<.015,'flat ollie: front sole leads, rear follows into a level deck before actual apex moving=%s held=%s'%[moving,held])
			check.call(probe.horizontal_error<.001,'flat ollie: staged foot/deck motion adds no horizontal impulse moving=%s held=%s'%[moving,held])
			check.call(probe.landing_samples>=24 and probe.lowest_landing_tick<=5 and neutral_hips-probe.lowest_landing_hips>.09 and absf(f.rider._visual_rig._upper.position.y-neutral_hips)<.015,'flat ollie: native impact absorbs weight within five ticks and recovers without lingering crouch moving=%s held=%s'%[moving,held])
			check.call(probe.maximum_pose_step<.22 and probe.maximum_grip_error<.005 and probe.minimum_sole_y>=-.001 and neutral_hips-probe.apex_hips>.09 and probe.clothing,'flat ollie: apex tuck and actual shoes retain deck/floor contact and connected clothing through launch/impact moving=%s held=%s'%[moving,held])
			print('FLAT_OLLIE moving=',moving,' held=',held,' apex=',probe.peak,' airtime=',probe.air_ticks/60.0,' front_lead_m=',probe.front_lead,' level_error_m=',probe.level_error,' launch=',probe.launch,' level_tick=',probe.first_level_tick,' apex_tick=',probe.apex_tick,' apex_tuck=',neutral_hips-probe.apex_hips,' impact_tick=',probe.lowest_landing_tick,' impact_compression=',neutral_hips-probe.lowest_landing_hips,' pose_step=',probe.maximum_pose_step,' sole_grip=',probe.maximum_grip_error,' sole_floor=',probe.minimum_sole_y)
			probe.queue_free();await Classic._dispose(tree,f)
	var fall:Dictionary=await Classic._fixture(tree)
	fall.rider.position.y+=1.0 # Initial unsupported fixture; never assigned during travel.
	await Classic._frames(tree,8)
	var fall_speed:float=fall.rider.velocity.y
	await Classic._frames(tree,1)
	check.call(fall.rider.airborne and not bool(fall.rider.get("_weighted_ollie_air")) and absf(fall.rider.velocity.y-(fall_speed-34.0/60.0))<.001 and fall.rider._ollie_pose_remaining==0.0 and absf(fall.rider._board_visual.rotation.x)<.001,'flat ollie: unsupported falling retains actual34g without a pop pose or slower launch gravity')
	await Classic._dispose(tree,fall)
	var cancel:Dictionary=await Classic._fixture(tree)
	Input.action_press('ollie');await Classic._frames(tree,24);Input.action_release('ollie');await Classic._frames(tree,3)
	var active:bool=cancel.rider._ollie_pose_remaining>0.0
	cancel.rider.begin_bail('pose_cancel')
	check.call(active and cancel.rider._ollie_pose_remaining==0.0 and not bool(cancel.rider.get("_weighted_ollie_air")),'flat ollie: actual bail cancels launch pose and weighted flight authority')
	cancel.rider.reset_skater()
	check.call(cancel.rider._ollie_pose_remaining==0.0 and not cancel.rider.bailing,'flat ollie: explicit restart leaves no stale launch pose')
	await Classic._dispose(tree,cancel)
