extends RefCounted
## Real civic transition -> park mouth -> existing practice approach.
## No actor/velocity/heading/score assignments after each declared start.
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const ParkCadence = preload("res://tests/pt24_park_full_combo_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")
const LOW_PATH := [Vector3(-78,1,-64.2),Vector3(-78,4,-74),Vector3(-78,4,-80),
	Vector3(-48,4,-80),Vector3(-28,4,-80),Vector3(-28,4,-96),Vector3(-28,6,-108),
	Vector3(-28,6,-121),Vector3(-36,6,-122),Vector3(-46,6,-123),
	Vector3(-65,6,-123),Vector3(-75,6,-125),Vector3(-82,6,-129),Vector3(-86,6,-130)]

static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await _construction(tree,game,check)
	_classification(game,check)
	await _combo(tree,game,check,observer)
	await _low_point_return(tree,game,check,observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await Driver._frames(tree,3)

static func _construction(tree: SceneTree,game: Node,check: Callable) -> void:
	await Driver._frames(tree,2)
	var supported := true
	var clear := true
	var maximum_error := 0.0
	var samples := 0
	for segment: int in LOW_PATH.size()-1:
		var first: Vector3=LOW_PATH[segment]
		var last: Vector3=LOW_PATH[segment+1]
		var side := Vector3((last-first).z,0,-(last-first).x).normalized()*.4
		var count := maxi(2,ceili(Vector2(last.x-first.x,last.z-first.z).length()))
		var previous := Vector3.INF
		for step: int in count+1:
			var centre := first.lerp(last,float(step)/count)
			var height: float=game.world.get_ground_height(centre)
			supported=supported and is_finite(height) and absf(height-centre.y)<.15
			centre.y=height
			if previous.is_finite():
				clear=clear and Routes._clear_sweep(game.world,previous,centre) and Routes._clear_sweep(game.world,centre,previous)
			previous=centre
			for lateral: float in [-1,0,1]:
				var point := centre+side*lateral
				point.y=game.world.get_ground_height(point)
				var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(point+Vector3.UP*.1,point-Vector3.UP*.1,1))
				var error: float=INF if hit.is_empty() else absf(hit.position.y-point.y)
				maximum_error=maxf(maximum_error,error)
				supported=supported and error<.002 and is_finite(point.y)
				samples+=1
	check.call(supported and clear,"C04 civic/park: fixed full-width low-court/bank/forecourt/mouth/practice supports and two-way capsules agree with native ground")
	check.call(is_instance_valid(game.world.get_node_or_null("CivicPortReturn"))
		and is_instance_valid(game.world.get_node_or_null("OutdoorRoutes/KelvingrovePromenadeQuarter")),
		"C04 civic/park: normal Main supplies the existing civic return and practice quarter without a content override")
	print("CIVIC_PARK_FIXED samples=",samples," support=",supported," clear=",clear," max_error_m=",maximum_error)


static func _classification(game: Node,check: Callable) -> void:
	for row: Array in [
		[Vector3(-96,6,-130),"kelvingrove","actual practice quarter"],
		[Vector3(-82,6.4,-135),"kelvingrove","actual practice manual pad"],
		[Vector3(-111,6.55,-130),"kelvingrove","actual practice ledge"],
		[Vector3(-117.8,6,-139.3),"kelvingrove","inside southwest apron edge"],
		[Vector3(-76.2,6,-126.2),"kelvingrove","inside northeast apron edge"],
		[Vector3(-118.2,6,-139.3),"central_station","outside west apron edge"],
		[Vector3(-75.8,6,-132),"central_station","outside east apron edge"],
		[Vector3(-72,2,20),"central_station","unchanged station concourse"],
		[Vector3(-22,4,-74),"george_square","unchanged civic court"],
		[Vector3(-38.5,6,-124.8),"george_square","unchanged civic quarter approach"],
		[Vector3(-65,6,-123),"kelvingrove","unchanged narrow promenade"]]:
		var actual: String=game.world.get_district_id(row[0])
		check.call(actual==String(row[1]),"C04 park classification: "+String(row[2])+" is "+actual+"; expected "+String(row[1]))
	for path: String in ["OutdoorRoutes/KelvingrovePromenadeQuarter","OutdoorRoutes/PracticeManualPad","OutdoorRoutes/PracticeLedge"]:
		var feature: Node3D=game.world.get_node(path)
		check.call(game.world.get_location_name(feature.global_position)=="KELVINGROVE PARK",
			"C04 park presentation: actual named feature's public HUD/audio location is KELVINGROVE PARK "+path)

static func _combo(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	await Driver._reset(tree,game,Vector3(-38.5,6.08,-124.8),PI)
	var e := Driver._evidence(game,"civic_return_to_park_practice")
	e.merge({"air":false,"climbed":false,"lip":false,"flip_requested":false,"mouth":false,"practice":false,
		"distance":0.0,"previous":game.skater.global_position,"max_y":game.skater.global_position.y})
	Driver._connect(game,e)
	Input.action_press("push")
	Input.action_press("grind")
	for tick: int in 420:
		await _step(tree,game,e,"civic_native_coping_lip",observer)
		e.climbed=e.climbed or game.skater.global_position.y>7.5
		if game.skater.lip_active:
			e.lip=true
			Input.action_release("push")
			Input.action_press("ollie")
			await _step(tree,game,e,"civic_coping_pop_charge",observer)
			await _step(tree,game,e,"civic_coping_pop_charge",observer)
			Input.action_release("ollie")
			Input.action_release("grind")
			await _step(tree,game,e,"civic_coping_outward_ollie",observer)
			break
		if e.bails>0:break
	for tick: int in 30:
		if game.skater.airborne:
			e.air=true
			Input.action_press("flip")
			e.flip_requested=true
			await _step(tree,game,e,"civic_earned_air_flip",observer)
			Input.action_release("flip")
			break
		await _step(tree,game,e,"civic_coping_air_confirm",observer)
		if e.bails>0:break
	if e.air:
		await _flat_manual(tree,game,e,180,"civic_native_flat_landing_manual",observer)
	var linked: bool=game.skater.manual_active and e.bails==0 and e.banks==0
	if linked:
		linked=await _manual_target(tree,game,e,Vector3(-44,6,-122),600,"civic_mouth_manual",observer)
		e.mouth=linked and game.skater.global_position.x< -42
	if linked:
		for target: Vector3 in [Vector3(-56,6,-122.5),Vector3(-70,6,-123),Vector3(-82,6,-129)]:
			linked=await ParkCadence._flatland_pop(tree,game,e,target,observer)
			if not linked:break
			linked=await _manual_target(tree,game,e,target,600,"park_practice_manual",observer)
			if not linked:break
	if linked:
		linked=await _manual_target(tree,game,e,Vector3(-86,6,-130),600,"park_practice_arrival",observer)
		e.practice=linked
	var choice_visible: bool=e.practice and _practice_visible(game)
	await Driver._finish_bank(tree,game,e,observer)
	check.call(e.lip and e.air and e.flip_requested and e.climbed and e.mouth and e.practice and e.manual_ticks>=120
		and e.distance>55 and e.max_y>7.5,
		"C04 civic/park: actual native civic coping lip/Ollie/flip lands into Manual through the real west mouth and earned flatland links to park practice")
	Driver._check_receipt(game,e,check,"C04 civic/park")
	check.call(choice_visible,"C04 civic/park: ordinary chase shows the existing practice quarter mouth and curved face before the next commitment")
	print("CIVIC_PARK_COMBO lip=",e.lip," air=",e.air," climbed=",e.climbed," mouth=",e.mouth," practice=",e.practice,
		" distance_m=",e.distance," max_y=",e.max_y," choice_visible=",choice_visible)
	Driver._disconnect(game,e)
	Driver._report(e,game)

static func _manual_target(tree: SceneTree,game: Node,e: Dictionary,target: Vector3,limit: int,
		phase: String,observer: Callable) -> bool:
	for tick: int in limit:
		if not game.skater.manual_active or e.bails>0 or e.banks>0:return false
		Driver._manual_to(game,target)
		await _step(tree,game,e,phase,observer)
		if Vector2(game.skater.global_position.x-target.x,game.skater.global_position.z-target.z).length()<1.2:return true
	return false

static func _practice_visible(game: Node) -> bool:
	var quarter: Node3D=game.world.get_node("OutdoorRoutes/KelvingrovePromenadeQuarter")
	var sample: Dictionary=quarter.sample(PI/6.0,0)
	var camera: Camera3D=game.skater._camera
	for target: Vector3 in [Vector3(-94,6.4,-130),sample.point+sample.normal*.1]:
		if not camera.is_position_in_frustum(target):return false
		var query := PhysicsRayQueryParameters3D.create(camera.global_position,target,1|8,[game.skater.get_rid()])
		if not game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty():return false
	return true

static func _low_point_return(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	await Driver._reset(tree,game,LOW_PATH[0]+Vector3.UP*.04,0)
	var e := Driver._evidence(game,"merchant_low_point_park_round_trip")
	e.merge({"distance":0.0,"previous":game.skater.global_position,"max_y":game.skater.global_position.y})
	Driver._connect(game,e)
	var reached := true
	for index: int in range(1,LOW_PATH.size()):
		reached=await _ordinary_target(tree,game,e,LOW_PATH[index],observer)
		if not reached:break
	var outbound: bool=reached
	if outbound:
		Driver._release()
		Input.action_press("brake")
		for tick: int in 35:await _step(tree,game,e,"park_miss_stop",observer)
		for tick: int in 180:
			Driver._steer_to(game,LOW_PATH[LOW_PATH.size()-2],false)
			await _step(tree,game,e,"park_miss_turnaround",observer)
			var delta: Vector3=LOW_PATH[LOW_PATH.size()-2]-game.skater.global_position
			if absf(angle_difference(game.skater.rotation.y,atan2(-delta.x,-delta.z)))<.015:break
		for index: int in range(LOW_PATH.size()-2,-1,-1):
			reached=await _ordinary_target(tree,game,e,LOW_PATH[index],observer)
			if not reached:break
	Driver._release()
	check.call(outbound and reached and e.ground_supported and e.bails==0 and e.recoveries==0
		and e.entries.is_empty() and game.score.total_score==0 and game.skater.global_position.y<1.15,
		"C04 civic/park: ordinary no-jump inputs leave the real Y1 low court, reach park practice and return to that low point without a reset or manufactured score")
	check.call(e.camera_clear,"C04 civic/park: complete body and chase stay clear through the entire low-point/practice round trip")
	print("CIVIC_PARK_LOW_RETURN outbound=",outbound," returned=",reached," distance_m=",e.distance,
		" max_y=",e.max_y," at=",game.skater.global_position)
	Driver._disconnect(game,e)
	Driver._report(e,game)

static func _ordinary_target(tree: SceneTree,game: Node,e: Dictionary,target: Vector3,observer: Callable) -> bool:
	var point: Vector3=game.skater.global_position
	var limit := clampi(ceili((Vector2(target.x-point.x,target.z-point.z).length()/3.5+4)*60),240,1800)
	for tick: int in limit:
		Driver._steer_to(game,target,false)
		ParkCadence._speed_push(game,4.2)
		await _step(tree,game,e,"ordinary_low_point_practice_route",observer)
		point=game.skater.global_position
		var height: float=game.world.get_support_height(point,.3)
		e.ground_supported=e.ground_supported and is_finite(height) and absf(point.y-height)<.18 and not game.skater.airborne
		if Vector2(point.x-target.x,point.z-target.z).length()<1.2:return true
		if e.bails>0:return false
	print("CIVIC_PARK_TRANSIT_UNREACHED target=",target," at=",point," speed=",game.skater.speed)
	return false

static func _step(tree: SceneTree,game: Node,e: Dictionary,phase: String,observer: Callable) -> void:
	await Driver._step(tree,game,e,phase,observer)
	e.distance+=game.skater.global_position.distance_to(e.previous)
	e.previous=game.skater.global_position
	e.max_y=maxf(e.max_y,game.skater.global_position.y)

static func _flat_manual(tree: SceneTree,game: Node,e: Dictionary,limit: int,phase: String,observer: Callable) -> void:
	# Curved recapture is an ordinary landing with its real bank deadline.
	# A fresh Manual requires neutral native floor, not stale on_floor from
	# the last flat physics move while the finite transition still owns travel.
	var reverted := false
	for tick: int in limit:
		if game.skater.is_on_floor() and not game.skater.airborne and not game.skater.transition_active:
			# A coping pop carries travel away from the face while the body can
			# still face the ramp. Turn the stance with its real landing Revert,
			# not a heading or velocity assignment, before entering the Manual.
			if game.skater.speed< -.5 and not reverted:
				Input.action_press("revert")
				await _step(tree,game,e,phase+"_revert",observer)
				Input.action_release("revert")
				reverted=true
			else:Input.action_press("manual")
		await _step(tree,game,e,phase,observer)
		if game.skater.manual_active or e.bails>0:break
