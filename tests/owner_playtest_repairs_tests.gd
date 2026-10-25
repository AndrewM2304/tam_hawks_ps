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
	for lateral: float in [0.0, PI]:
		await _natural_bowl_air(tree,game,check,lateral)
	await _natural_bowl_air(tree,game,check,0.0,true)
	await _print_yard_wall(tree,game,check)
	await _recorded_rim_join(tree,game,check)
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
	var recognized := false
	var applied := false
	for tick in 240:
		if transfer and tick==8:Input.action_release("push")
		if transfer and tick==10:Input.action_press("push")
		await _frames(tree,1)
		var intent: Dictionary = rider._feature_transition.transfer_intent_snapshot()
		recognized = recognized or bool(intent.recognized)
		applied = applied or float(intent.applied_direction) < 0.0
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
	check.call(recognized == transfer and applied == transfer,
		"owner bowl: held approach and fresh airborne Push report distinct recognized/applied transfer intent")
	check.call(limb_samples>30 and limb_error<0.001 and knee_core_contacts==0,
		"owner pose: real bowl air/return retains anatomical leg lengths and keeps knees outside the chest core")
	print("OWNER_LIMBS ",{"held":held,"transfer":transfer,"samples":limb_samples,"length_error_m":limb_error,"knee_core_contacts":knee_core_contacts})
	print("OWNER_BOWL held=%d transfer=%s air=%s returned=%s exited=%s intact=%s peak=%.3f radius=%.3f"%[held,transfer,air,returned,exited,intact,peak,radius_max])


static func _natural_bowl_air(tree: SceneTree,game: Node,check: Callable,lateral_angle: float,lip_jump: bool=false) -> void:
	_release()
	game.start_mode(true)
	var rider: CharacterBody3D = game.skater
	var bowl: Node3D = game.world.get_node("ClydeEastBowl")
	var frame: Dictionary = bowl.sample(1.1,lateral_angle * float(bowl.floor_radius))
	rider.spawn_position = frame.point + frame.normal * 0.022
	rider.reset_skater()
	rider.velocity = frame.tangent * 12.0
	rider.speed = 12.0
	rider.rotation.y = atan2(-rider.velocity.x,-rider.velocity.z)
	if lip_jump: Input.action_press("grind")
	var popped := false
	var launched := false
	var returned := false
	var ramp_tag := true
	var monotone := true
	var previous_turn := 0.0
	var maximum_turn := 0.0
	var downward_view := false
	for tick in 180:
		if lip_jump and rider.lip_active and not popped:
			Input.action_press("ollie")
			await _frames(tree,2)
			Input.action_release("ollie")
			popped = true
		await _frames(tree,1)
		await tree.create_timer(0.0).timeout
		if rider.airborne and rider._feature_transition.state == "air":
			launched = true
			ramp_tag = ramp_tag and rider._ramp_air and rider._ramp_air_normal.is_normalized() \
				and absf(rider._ramp_air_normal.dot(Vector3.UP)) < 0.001
			var turn: float = rider._camera_follow._ramp_turn
			monotone = monotone and turn >= previous_turn - 0.001
			previous_turn = turn
			maximum_turn = maxf(maximum_turn,turn)
			downward_view = downward_view or (rider.velocity.y < -1.0 and (-rider._camera.global_basis.z).y < -0.85)
		elif launched and not rider.airborne:
			returned = true
			break
		if rider.bail_active: break
	check.call(launched and returned and ramp_tag and not rider.bail_active,
		"owner bowl: wall %.0f lip jump=%s receives a finite ramp flight frame and returns" % [lateral_angle,lip_jump])
	check.call(monotone and maximum_turn > PI - 0.01 and downward_view,
		"owner bowl: natural wall %.0f air completes one apex handoff and looks down before landing" % lateral_angle)
	print("PT24_NATURAL_BOWL ",{"wall":lateral_angle,"lip_jump":lip_jump,"launched":launched,"returned":returned,
		"ramp_tag":ramp_tag,"monotone":monotone,"max_turn":maximum_turn,"downward_view":downward_view})


static func _print_yard_wall(tree: SceneTree,game: Node,check: Callable) -> void:
	_release()
	game.start_mode(true)
	var rider: CharacterBody3D = game.skater
	var wall: Node3D = game.world.get_node("OutdoorRoutes/SouthPocketRearBoundary")
	check.call(bool(wall.get_meta("wallrideable",false)) and not bool(wall.get_meta("no_wallride",false)),
		"owner print yard: visible backed masonry explicitly admits wallrides without opening void guards")
	rider.spawn_position = Vector3(61,2.8,141.85)
	rider.reset_skater()
	await _frames(tree,35)
	var seen: Array[String] = []
	var record := func(name: String,_points: int): seen.append(name)
	rider.trick_performed.connect(record)
	var approach := Vector3(8,0,3)
	rider.rotation.y = atan2(-approach.x,-approach.z)
	rider.speed = approach.length()
	rider.velocity = approach
	Input.action_press("ollie")
	await _frames(tree,2)
	Input.action_release("ollie")
	Input.action_press("grind")
	for tick in 20:
		await _frames(tree,1)
		if rider.wallriding: break
	var admitted: bool = rider.wallriding and rider._wall.wall_id.ends_with("SouthPocketRearBoundary")
	Input.action_press("ollie")
	await _frames(tree,3)
	Input.action_release("ollie")
	await _frames(tree,2)
	check.call(admitted and not rider.wallriding and rider.velocity.z < -1.0 and rider.velocity.y > 4.0
		and seen.count("Wallride") == 1 and seen.count("Wallie") == 1 and not rider.bail_active,
		"owner print yard: actual jump/glancing capture/wall jump leaves masonry once with outward momentum and one award")
	_release()
	rider.spawn_position = Vector3(61,2.8,141.85)
	rider.reset_skater()
	await _frames(tree,35)
	seen.clear()
	rider.rotation.y = PI
	rider.speed = 8.0
	rider.velocity = Vector3.BACK * 8.0
	Input.action_press("ollie")
	await _frames(tree,2)
	Input.action_release("ollie")
	Input.action_press("grind")
	await _frames(tree,15)
	check.call(not rider.wallriding and seen.count("Wallride") == 0 and seen.count("Wallie") == 0,
		"owner print yard: a head-on jump into the same masonry does not award a wallride or wall jump")
	rider.trick_performed.disconnect(record)
	_release()


static func _recorded_rim_join(tree: SceneTree,game: Node,check: Callable) -> void:
	_release()
	game.start_mode(true)
	var rider: CharacterBody3D = game.skater
	# Exact rejected lower-rim witness beside the newly closed arrival-bank
	# side. All four wheel centres still lie on the lower flat at this pose.
	rider.spawn_position = Vector3(-199.9817,13.01387,-176.7265)
	rider.reset_skater()
	rider.rotation.y = 0.032637
	await _frames(tree,4)
	await tree.create_timer(0.0).timeout
	var fit: Dictionary = rider._native_board_floor()
	var buried := 0
	var lowest := INF
	var highest := -INF
	var space := rider.get_world_3d().direct_space_state
	for wheel: Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		var center: Vector3 = rider._board_visual.to_global(wheel.center)
		var support := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			center+Vector3.UP*0.1,center-Vector3.UP*0.2,1|8,[rider.get_rid()]))
		var gap := INF
		for vertex: Vector3 in wheel.points:
			var actual: Vector3 = rider._board_visual.to_global(vertex)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(
				actual+Vector3.UP*0.05,actual,1|8,[rider.get_rid()]))
			buried += int(not hit.is_empty() and Vector3(hit.position).y > actual.y+0.0001)
			if not support.is_empty(): gap=minf(gap,(actual-Vector3(support.position)).dot(support.normal))
		lowest=minf(lowest,gap)
		highest=maxf(highest,gap)
	check.call(not fit.is_empty() and float(fit.position.y)-13.0>0.0
		and float(fit.position.y)-13.0<=0.025 and buried==0 and lowest>=-0.003 and highest<=0.030,
		"owner arrival bank: exact finite toe witness clears every actual lower tyre vertex within unchanged wheel/presentation bounds")
	check.call(preload("res://tests/authentic_fidelity_integration_tests.gd")._facility_camera_clear(game)
		and not rider.airborne and not rider.bail_active and game.score.total_score==0,
		"owner arrival bank: exact finite rim fit preserves native support, full-model chase and zero manufactured score")
	print("PT24_RECORDED_RIM ",{"fit":fit,"buried":buried,"wheel_min":lowest,"wheel_max":highest,
		"body":rider.global_position,"presentation":rider._visual.global_position})


static func _release() -> void:
	for action in InputMap.get_actions():Input.action_release(action)


static func _frames(tree: SceneTree,count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
