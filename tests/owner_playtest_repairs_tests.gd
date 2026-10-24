extends RefCounted
## Native owner-defect regressions. Fixtures set initial contact/momentum once;
## ordinary mapped inputs and production collision own all later movement.

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var spawn: Vector3 = game.skater.spawn_position
	var free: bool = game.free_skate_mode
	var ground := true
	for x in range(-165,-160):
		for z in range(-182,-177):
			var point := Vector3(x,17,z)
			var hit: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(point+Vector3.UP,point-Vector3.UP,1))
			ground = ground and not hit.is_empty() and absf(hit.position.y-17)<0.001 \
				and absf(game.world.get_ground_height(point)-17)<0.001
			if hit.is_empty() or absf(hit.position.y-17)>=0.001 or absf(game.world.get_ground_height(point)-17)>=0.001:
				print("OWNER_SUMMIT mismatch at=",point," hit=",hit," query=",game.world.get_ground_height(point)," path=",hit.get("collider").get_path() if hit.has("collider") else "none"," label=",hit.get("collider").get_meta("art_label","") if hit.has("collider") else "none")
	check.call(ground,"owner path:25 summit overlap rays share the17m spur/loop datum and support query")
	for speed: float in [3.0,12.0]:
		for reverse: bool in [false,true]:
			await _junction(tree,game,check,speed,reverse)
	for held: int in [2,24]:
		await _bowl_air(tree,game,check,held,false)
	await _bowl_air(tree,game,check,24,true)
	_release()
	game.skater.spawn_position=spawn
	game.start_mode(free)


static func _junction(tree: SceneTree,game: Node,check: Callable,speed: float,reverse: bool) -> void:
	_release()
	var start := Vector3(-161,17.8,-178) if not reverse else Vector3(-169,17.8,-182)
	var target := Vector3(-169,17,-182) if not reverse else Vector3(-161,17,-178)
	game.skater.spawn_position=start
	game.start_mode(true)
	await _frames(tree,40)
	var direction := (target-Vector3(start.x,17,start.z)).normalized()
	game.skater.rotation.y=atan2(-direction.x,-direction.z)
	game.skater.speed=speed
	game.skater.velocity=direction*speed
	Input.action_press("push")
	var reached := false
	var supported := true
	for tick in 240:
		await _frames(tree,1)
		supported = supported and not game.skater.bail_active and not game.skater.airborne
		if Vector2(game.skater.position.x-target.x,game.skater.position.z-target.z).length()<0.7:
			reached=true
			break
	check.call(reached and supported,"owner path: no-jump native junction traversal speed=%.0f reverse=%s"%[speed,reverse])


static func _bowl_air(tree: SceneTree,game: Node,check: Callable,held: int,transfer: bool) -> void:
	_release()
	game.start_mode(true)
	var rider: CharacterBody3D = game.skater
	var bowl: Node3D = game.world.get_node("ClydeEastBowl")
	var frame: Dictionary = bowl.sample(1.1,0.0)
	rider.spawn_position=frame.point+frame.normal*0.022
	rider.reset_skater()
	rider.velocity=frame.tangent*5.0
	rider.speed=5.0
	rider.rotation.y=atan2(-rider.velocity.x,-rider.velocity.z)
	await _frames(tree,2)
	Input.action_press("push") # held approach is deliberately NOT exit intent
	Input.action_press("ollie")
	await _frames(tree,held)
	Input.action_release("ollie")
	print("OWNER_BOWL_RELEASE held=",held," position=",rider.position," velocity=",rider.velocity," state=",rider._feature_transition.state," charge=",rider.ollie_charge," impulse=",rider._ramp_pop_impulse," enabled=",rider._trick_entries_enabled," held=",rider._ollie_held," control=",rider._controls_enabled)
	var air := false
	var returned := false
	var exited := false
	var peak: float = rider.position.y
	var radius_max := 0.0
	var intact := true
	var limb_error := 0.0
	var knee_core_contacts := 0
	var limb_samples := 0
	for tick in 240:
		if transfer and tick==8:Input.action_release("push")
		if transfer and tick==10:Input.action_press("push")
		await _frames(tree,1)
		if transfer and tick in [7,9,11,20]:print("OWNER_BOWL_INTENT tick=",tick," state=",rider._feature_transition.state," armed=",rider._feature_transition._air_push_armed," transfer=",rider._feature_transition._transfer_direction," push=",Input.get_action_strength("push")," velocity=",rider.velocity)
		air = air or rider.airborne
		peak=maxf(peak,rider.position.y)
		var local: Vector3 = bowl.to_local(rider.global_position)
		radius_max=maxf(radius_max,Vector2(local.x,local.z).length())
		intact = intact and not rider.bail_active and rider.position.is_finite()
		var rig: RefCounted = rider._visual_rig
		var skin: Skeleton3D = rig._garments.skeleton
		for index in 2:
			var side := "left" if index==0 else "right"
			var hip := skin.get_bone_pose_position(skin.find_bone(side+"_thigh"))
			var knee := skin.get_bone_pose_position(skin.find_bone(side+"_calf"))
			var ankle: Vector3 = rig._legs[index].foot.position
			limb_error=maxf(limb_error,maxf(absf(hip.distance_to(knee)-0.43),absf(knee.distance_to(ankle)-0.41)))
			var chest: Vector3 = rig._upper.to_local(skin.to_global(knee))
			knee_core_contacts+=int(chest.y>0.12 and chest.y<0.50 and absf(chest.x)<0.18 and absf(chest.z)<0.09)
			limb_samples+=1
		if air and not rider.airborne:
			returned=rider.transition_active or radius_max<float(bowl.floor_radius)+float(bowl.radius)
			break
		if air and not rider._feature_transition.active and radius_max>float(bowl.floor_radius)+float(bowl.radius)+0.15:
			exited=true
			break
	var success := exited if transfer else returned and not exited
	check.call(air and intact and success and peak>float(frame.point.y)+0.5,
		"owner bowl: charged%df %s follows native air with useful height and explicit intent"%[held,"fresh transfer exits" if transfer else "held approach returns"])
	check.call(limb_samples>30 and limb_error<0.001 and knee_core_contacts==0,
		"owner pose: real bowl air/return retains anatomical leg lengths and keeps knees outside the chest core")
	print("OWNER_LIMBS ",{"held":held,"transfer":transfer,"samples":limb_samples,"length_error_m":limb_error,"knee_core_contacts":knee_core_contacts})
	print("OWNER_BOWL held=%d transfer=%s air=%s returned=%s exited=%s intact=%s peak=%.3f radius=%.3f"%[held,transfer,air,returned,exited,intact,peak,radius_max])


static func _release() -> void:
	for action in InputMap.get_actions():Input.action_release(action)


static func _frames(tree: SceneTree,count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
