extends RefCounted
## Two bounded C04 lines. Only each declared restart/facing is assigned;
## every subsequent turn, contact, trick and bank uses ordinary mapped input.

const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Routes = preload("res://tests/world_routes_tests.gd")
const Camera = preload("res://tests/full_level_density_tests.gd")
const STAIR := "Grind_Rail_GallerySteps"
const FOUNTAIN := "Grind_Coping_ExchangeFountain"


static func run(tree: SceneTree,game: Node,check: Callable) -> void:
	check.call(not game.persistence_enabled,"C04 flagship: scripted Main disables persistent Music control before fixtures")
	var ids: Array[String]=[]
	for line in game.world.get_grind_lines(): ids.append(String(line.id))
	check.call(ids.has(STAIR) and ids.has(FOUNTAIN) and ids.has("Grind_Ledge_station_low_manual")
		and ids.has("Grind_Rail_Exchange"),"C04 flagship: existing gallery/fountain/station/teaching identities remain available")
	for path: Array in [
		[Vector3(9.1,2,-24),Vector3(9.1,2,-18)],
		[Vector3(14.6,2,-22),Vector3(14.6,2,-18),Vector3(14.6,0,-4),Vector3(14.6,0,24)],
		[Vector3(-124,2,42.3),Vector3(-70,2,42.3),Vector3(-69.5,2,24.5),Vector3(-62,2,24.5),Vector3(-62,2,22)],
		[Vector3(-62,2,22),Vector3(-50,2,22),Vector3(-35,0,22),Vector3(-26,0,22)]]:
		var supported := true
		var clear := true
		for i: int in path.size()-1:
			var start: Vector3=path[i]
			var finish: Vector3=path[i+1]
			clear=clear and Routes._clear_sweep(game.world,start,finish) and Routes._clear_sweep(game.world,finish,start)
			var side:=Vector3((finish-start).z,0,-(finish-start).x).normalized()*0.4
			for step: int in 13:
				for offset: float in [-1,0,1]:
					var point:=start.lerp(finish,float(step)/12)+side*offset
					var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
						point+Vector3.UP*0.15,point-Vector3.UP*0.15,1))
					supported=supported and not hit.is_empty() and absf(Vector3(hit.position).y-point.y)<0.025
		check.call(supported and clear,"C04 flagship: fixed full-width approach/miss/return has native support and two-way clearance "+str(path))
	await run_player(tree,game,check)


static func run_player(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await _gallery(tree,game,check,observer)
	await _station(tree,game,check,observer)
	await _miss_return(tree,game,check,"gallery",Vector3(14.6,2.08,-22),PI,
		PackedVector3Array([Vector3(14.6,0,0),Vector3(14.6,0,24)]),observer)
	await _miss_return(tree,game,check,"station",Vector3(-124,2.08,42.3),-PI*0.5,
		PackedVector3Array([Vector3(-72,2,42.3),Vector3(-69.5,2,38),Vector3(-69.5,2,24.5),
			Vector3(-62,2,24.5),Vector3(-62,2,22),Vector3(-50,2,22),Vector3(-35,0,22),Vector3(-26,0,22)]),observer)
	_release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await _frames(tree,3)


static func _gallery(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	await _reset(tree,game,Vector3(9.1,2.08,-24),PI)
	var e:=_evidence(game,"gallery_to_fountain")
	_connect(game,e)
	var charged := false
	var popped := false
	for tick: int in 240:
		if not popped: _speed_input(game,4.2)
		if game.skater.global_position.z> -21 and not charged:
			Input.action_press("ollie")
			charged=true
		if game.skater.global_position.z> -18.5 and not popped:
			Input.action_release("ollie")
			Input.action_release("push")
			Input.action_release("brake")
			Input.action_press("grind")
			popped=true
		await _step(tree,game,e,"gallery_rail_entry",observer)
		if game.skater.grinding or e.bails>0: break
	var stair_caught: bool=game.skater.grinding and game.skater._grind.line.id==STAIR
	if stair_caught:
		for tick: int in 180:
			await _step(tree,game,e,"gallery_stair_descent",observer)
			if game.skater.global_position.z>=-9.5 or not game.skater.grinding: break
		Input.action_release("push")
		Input.action_release("brake")
		Input.action_press("ollie")
		await _steps(tree,game,e,2,"gallery_side_pop_charge",observer)
		# Pop outside the stair/cheek footprint onto the continuous side bank.
		# Popping inward lands on a tread and cannot sustain the flatland link.
		_axis("steer_left","steer_right",-0.9)
		Input.action_release("ollie")
		await _step(tree,game,e,"gallery_side_pop",observer)
		Input.action_release("grind")
		_axis("steer_left","steer_right",0)
		await _landing_manual(tree,game,e,150,"gallery_court_manual",observer)
	var court_manual: bool=game.skater.manual_active
	if court_manual:
		for tick: int in 120:
			_manual_to(game,Vector3(11.5,0,-3.4))
			await _step(tree,game,e,"gallery_clear_stair_runout",observer)
			if game.skater.global_position.z>=-3.8 or e.bails>0: break
		for tick: int in 300:
			_manual_to(game,Vector3(6.65,0,4.3))
			await _step(tree,game,e,"fountain_tangent_manual",observer)
			if game.skater.global_position.z>=3.8 or e.bails>0: break
		# Reuse the established15-frame full-charge fountain entry, with a
		# runway appropriate to this slower manual approach. The release stays
		# outside the basin+capsule envelope, while aiming along its east tangent.
		e.fountain_charge_at=game.skater.global_position
		Input.action_press("ollie")
		for tick: int in 15:
			_manual_to(game,Vector3(6.65,0,10))
			await _step(tree,game,e,"fountain_pop_charge",observer)
		e.fountain_release_at=game.skater.global_position
		e.fountain_release_speed=game.skater.speed
		Input.action_release("ollie")
		Input.action_release("manual")
		_axis("spin_left","spin_right",0)
		_axis("steer_left","steer_right",0)
		Input.action_release("push")
		Input.action_press("grind")
		for tick: int in 140:
			await _step(tree,game,e,"fountain_coping_catch",observer)
			if game.skater.grinding or e.bails>0: break
	var fountain_caught: bool=game.skater.grinding and game.skater._grind.line.id==FOUNTAIN
	if fountain_caught:
		for tick: int in 90:
			await _step(tree,game,e,"fountain_coping_payoff",observer)
			if e.fountain_ticks>=36 or not game.skater.grinding: break
		Input.action_press("ollie")
		await _steps(tree,game,e,2,"fountain_dry_exit_charge",observer)
		_axis("steer_left","steer_right",-1)
		Input.action_release("ollie")
		await _step(tree,game,e,"fountain_outward_pop",observer)
		Input.action_release("grind")
		_axis("steer_left","steer_right",0)
		await _landing_manual(tree,game,e,150,"fountain_dry_manual",observer)
		for tick: int in 12:
			_balance_manual(game)
			await _step(tree,game,e,"fountain_dry_manual",observer)
	await _finish_bank(tree,game,e,observer)
	check.call(stair_caught and court_manual and fountain_caught and e.stair_ticks>=12 and e.fountain_ticks>=36
		and e.captures==[STAIR,FOUNTAIN] and e.manual_ticks>=20,
		"C04-L01: actual gallery stair grind, flatland Manual and fountain coping are one connected input line")
	_check_receipt(game,e,check,"C04-L01")
	_disconnect(game,e)
	_report(e,game)


static func _station(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	await _reset(tree,game,Vector3(-126,2.08,35),-PI*0.5)
	var e:=_evidence(game,"station_to_city")
	_connect(game,e)
	Input.action_press("push")
	var launched := false
	for tick: int in 210:
		await _step(tree,game,e,"station_spine_approach",observer)
		if game.skater._feature_transition.active and game.skater._feature_transition.state=="air":
			launched=true
			break
		if e.bails>0: break
	if launched:
		Input.action_release("push")
		await _step(tree,game,e,"station_fresh_transfer_release",observer)
		Input.action_press("push")
		Input.action_press("flip")
		await _step(tree,game,e,"station_fresh_transfer_push",observer)
		Input.action_release("flip")
		await _steps(tree,game,e,11,"station_spine_transfer",observer)
		# Keep the mapped transfer Push through the actual far landing. Releasing
		# at an old air tick can land back on the newly solid front transition.
		for tick: int in 210:
			if not game.skater._feature_transition.active and game.skater.global_position.x> -107.5 \
					and game.skater.is_on_floor() and not game.skater.airborne:
				Input.action_release("push")
				Input.action_press("manual")
			await _step(tree,game,e,"station_far_concourse_landing",observer)
			if game.skater.manual_active or e.bails>0: break
	var linked: bool=game.skater.manual_active
	if linked:
		linked=await _station_flatland_pop(tree,game,e,Vector3(-96,2,40),observer)
	if linked:
		var targets:=PackedVector3Array([Vector3(-96,2,40),Vector3(-88,2,40),Vector3(-73,2,40),
			Vector3(-70.5,2,35),Vector3(-70.5,2,28.5),Vector3(-62,2,26.5),Vector3(-62,2,22),
			Vector3(-50,2,22),Vector3(-35,0,22),Vector3(-26,0,22)])
		for target_index: int in targets.size():
			var target: Vector3=targets[target_index]
			var segment_start: Vector3=game.skater.global_position
			var incoming:=Vector2(target.x-segment_start.x,target.z-segment_start.z).normalized()
			var reached := false
			for tick: int in 210:
				var point: Vector3=game.skater.global_position
				var distance:=Vector2(point.x-target.x,point.z-target.z).length()
				var steer_target:=target
				var lookahead: float=clampf(absf(game.skater.speed)*0.45,2.0,5.0)
				# Finish the narrow bank's straight east toe before rounding the
				# broad concourse corners; never cut diagonally off its side face.
				if target_index==2: lookahead=0.0
				if target_index+1<targets.size() and distance<lookahead:
					var outgoing: Vector3=targets[target_index+1]-target
					steer_target+=outgoing.normalized()*minf(lookahead-distance,outgoing.length())
				_manual_to(game,steer_target)
				await _step(tree,game,e,"station_city_manual_"+str(target_index),observer)
				point=game.skater.global_position
				var delta:=Vector2(point.x-target.x,point.z-target.z)
				var passed: bool=delta.dot(incoming)>=0.0 and absf(delta.cross(incoming))<3.5
				if delta.length()<1.8 or (target_index+1<targets.size() and passed):
					reached=true
					e.route_gates.append({"target":target,"at":point,"distance":delta.length(),"passed_plane":passed})
					break
				if e.bails>0 or not game.skater.manual_active: break
			if not reached:
				linked=false
				break
			if target_index+1<targets.size():
				linked=await _station_flatland_pop(tree,game,e,targets[target_index+1],observer)
				if not linked: break
	await _finish_bank(tree,game,e,observer)
	check.call(launched and e.transfer and e.spine_crossed and e.native_far_landing and e.bank_manual_ticks>=6
		and linked and e.districts.has("central_station") and e.districts.has("royal_exchange")
		and game.skater.global_position.x> -30 and e.manual_ticks>=60,
		"C04-L02: actual spine transfer feeds the existing manual bank and city street in one mapped-input continuation")
	_check_receipt(game,e,check,"C04-L02")
	_disconnect(game,e)
	_report(e,game)


static func _station_flatland_pop(tree: SceneTree,game: Node,e: Dictionary,target: Vector3,observer: Callable) -> bool:
	# Native coping/face contact no longer supplies the former ghost carry.
	# Earn fresh speed with a real short Push/charged Ollie between Manuals,
	# within the unchanged .35s combo link. No velocity or score is assigned.
	Input.action_release("manual")
	_axis("spin_left","spin_right",0)
	_axis("steer_left","steer_right",0)
	Input.action_press("push")
	Input.action_press("ollie")
	for tick: int in 15:
		_steer_to(game,target,false)
		await _step(tree,game,e,"station_flatland_push_charge",observer)
	Input.action_release("ollie")
	Input.action_release("push")
	_axis("steer_left","steer_right",0)
	await _step(tree,game,e,"station_flatland_takeoff",observer)
	await _landing_manual(tree,game,e,150,"station_flatland_manual_landing",observer)
	return game.skater.manual_active and e.bails==0 and e.banks==0


static func _miss_return(tree: SceneTree,game: Node,check: Callable,id: String,start: Vector3,
		heading: float,targets: PackedVector3Array,observer: Callable) -> void:
	await _reset(tree,game,start,heading)
	var e:=_evidence(game,id+"_miss_return")
	_connect(game,e)
	var all_reached := true
	var supported := true
	var stalled := 0
	var previous: Vector3=game.skater.global_position
	for target: Vector3 in targets:
		var reached := false
		# A fixed ten-second cap cannot cover the first 52m concourse leg at
		# this actual 4.2m/s input cap. Budget its measured horizontal distance,
		# with a lower 3.5m/s allowance and three seconds for turn/acceleration.
		var start_point: Vector3=game.skater.global_position
		var distance:=Vector2(target.x-start_point.x,target.z-start_point.z).length()
		var tick_limit:=clampi(ceili((distance/3.5+3.0)*Engine.physics_ticks_per_second),240,1800)
		for tick: int in tick_limit:
			_steer_to(game,target,false)
			_speed_input(game,4.2)
			await _step(tree,game,e,id+"_ordinary_miss_return",observer)
			var point: Vector3=game.skater.global_position
			stalled=stalled+1 if point.distance_to(previous)<0.001 else 0
			previous=point
			var height: float=game.world.get_support_height(point,0.3)
			supported=supported and is_finite(height) and absf(point.y-height)<0.18 and not game.skater.airborne
			if Vector2(point.x-target.x,point.z-target.z).length()<1.2:
				reached=true
				break
			if e.bails>0: break
			if stalled>=30:
				var contacts: Array[Dictionary]=[]
				for collision_index: int in game.skater.get_slide_collision_count():
					var contact: KinematicCollision3D=game.skater.get_slide_collision(collision_index)
					var collider: Object=contact.get_collider()
					contacts.append({"collider":str(collider.get_path()) if collider is Node else str(collider),
						"point":contact.get_position(),"normal":contact.get_normal(),"shape":contact.get_collider_shape()})
				print("C04_MISS_BLOCKER id=",id," at=",point," target=",target,
					" contacts=",contacts," feature_active=",game.skater._feature_transition.active)
				break
		if not reached:
			all_reached=false
			break
	_release()
	check.call(all_reached and supported and e.bails==0 and e.recoveries==0 and e.entries.is_empty() and e.camera_clear,
		"C04 flagship: actual no-jump "+id+" miss bypass returns on supported ground with clear chase")
	_disconnect(game,e)
	_report(e,game)


static func _landing_manual(tree: SceneTree,game: Node,e: Dictionary,limit: int,phase: String,observer: Callable) -> void:
	var requested := false
	for tick: int in limit:
		var point: Vector3=game.skater.global_position
		var ground: float=game.world.get_support_height(point,0.3)
		if not requested and ((game.skater.velocity.y<0 and is_finite(ground) and point.y-ground<0.3)
			or (game.skater.is_on_floor() and not game.skater.airborne)):
			Input.action_press("manual")
			requested=true
		await _step(tree,game,e,phase,observer)
		if game.skater.manual_active or e.bails>0: break


static func _manual_to(game: Node,target: Vector3) -> void:
	_balance_manual(game)
	_steer_to(game,target,true)


static func _balance_manual(game: Node) -> void:
	Input.action_release("push")
	Input.action_release("brake")
	if game.skater.manual_active:
		var outward := 1.0 if game.skater.manual_balance>=0 else -1.0
		var correction: float=-(outward*(0.18+0.08*game.skater._manual_elapsed)+game.skater.manual_balance*1.4)/1.5
		_axis("steer_left","steer_right",clampf(correction,-1,1))
	else: _axis("steer_left","steer_right",0)


static func _steer_to(game: Node,target: Vector3,manual: bool) -> void:
	var delta: Vector3=target-game.skater.global_position
	var desired := atan2(-delta.x,-delta.z)
	var error: float=angle_difference(game.skater.rotation.y,desired)
	var amount: float=-clampf(error*1.8,-1,1)
	_axis("spin_left" if manual else "steer_left","spin_right" if manual else "steer_right",amount)


static func _speed_input(game: Node,ceiling: float) -> void:
	if absf(game.skater.speed)>ceiling:
		Input.action_release("push")
		Input.action_press("brake")
	else:
		Input.action_release("brake")
		Input.action_press("push")


static func _finish_bank(tree: SceneTree,game: Node,e: Dictionary,observer: Callable) -> void:
	_release()
	Input.action_press("brake")
	for tick: int in 90:
		await _step(tree,game,e,"clean_bank",observer)
		if e.banks>0 and not game.skater.airborne: break
	await _steps(tree,game,e,24,"single_bank_observation",observer)
	_release()


static func _evidence(game: Node,id: String) -> Dictionary:
	return {"id":id,"ticks":0,"phase":"","stages":[],"captures":[],"entries":[],"hold_points":0,"hold_valid":true,
		"bails":0,"recoveries":0,"banks":0,"last_score":game.score.total_score,"camera_clear":true,
		"manual_ticks":0,"stair_ticks":0,"fountain_ticks":0,"bank_manual_ticks":0,
		"districts":[],"spine_faces":[],"spine_crossed":false,"native_far_landing":false,
		"far_landing_at":Vector3.INF,"transfer":false,"callbacks":[],"ground_supported":true,"route_gates":[],
		"fountain_charge_at":Vector3.INF,"fountain_release_at":Vector3.INF,"fountain_release_speed":0.0}


static func _connect(game: Node,e: Dictionary) -> void:
	var on_bail:=func()->void: e.bails+=1
	var on_recovery:=func()->void: e.recoveries+=1
	var on_capture:=func(id:String)->void: e.captures.append(id)
	var on_trick:=func(label:String,points:int)->void:
		e.entries.append({"id":String(game.skater.last_trick_id),"label":label,"points":points})
	var on_hold:=func(points:int)->void:
		e.hold_points+=points
		e.hold_valid=e.hold_valid and points>0 and points%25==0 and game.skater.grinding
	e.callbacks=[on_bail,on_recovery,on_capture,on_trick,on_hold]
	game.skater.bailed.connect(on_bail)
	game.skater.recovered.connect(on_recovery)
	game.skater.grind_captured.connect(on_capture)
	game.skater.trick_performed.connect(on_trick)
	game.skater.hold_points_awarded.connect(on_hold)


static func _disconnect(game: Node,e: Dictionary) -> void:
	game.skater.bailed.disconnect(e.callbacks[0])
	game.skater.recovered.disconnect(e.callbacks[1])
	game.skater.grind_captured.disconnect(e.callbacks[2])
	game.skater.trick_performed.disconnect(e.callbacks[3])
	game.skater.hold_points_awarded.disconnect(e.callbacks[4])
	e.callbacks=[]


static func _step(tree: SceneTree,game: Node,e: Dictionary,phase: String,observer: Callable) -> void:
	await _frames(tree,1)
	e.ticks+=1
	if phase!=e.phase:
		e.phase=phase
		e.stages.append({"phase":phase,"at":game.skater.global_position,"speed":game.skater.speed})
	if game.score.total_score!=e.last_score:
		e.banks+=1
		e.last_score=game.score.total_score
	if game.skater.manual_active:
		e.manual_ticks+=1
		var point: Vector3=game.skater.global_position
		var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			point+Vector3.UP*0.2,point-Vector3.UP*0.2,1))
		e.ground_supported=e.ground_supported and not hit.is_empty() and absf(Vector3(hit.position).y-point.y)<0.18 \
			and Vector3(hit.normal).y>0.5
		if point.x>=-83 and point.x<=-77 and absf(point.z-40)<1.05 and point.y>2.25: e.bank_manual_ticks+=1
	if game.skater.grinding:
		if game.skater._grind.line.id==STAIR: e.stair_ticks+=1
		if game.skater._grind.line.id==FOUNTAIN: e.fountain_ticks+=1
	var district: String=game.world.get_district_id(game.skater.global_position)
	if not e.districts.has(district): e.districts.append(district)
	if e.id=="station_to_city":
		var point: Vector3=game.skater.global_position
		if game.skater.airborne and point.x> -109.7 and point.y>=4.2: e.spine_crossed=true
		if e.spine_crossed and not e.native_far_landing and game.skater.is_on_floor() \
				and not game.skater.airborne and point.x> -107.5 and absf(point.y-2.0)<0.13:
			var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
				point+Vector3.UP*0.12,point-Vector3.UP*0.15,1))
			if not hit.is_empty() and hit.collider==game.world.get_node("CentralStationFloor"):
				e.native_far_landing=true
				e.far_landing_at=point
	if game.skater._feature_transition.active:
		var feature: Node3D=game.skater._feature_transition.feature
		if String(feature.feature_id).begins_with("StationWestSpine") and game.skater._feature_transition.state=="surface":
			if not e.spine_faces.has(String(feature.name)): e.spine_faces.append(String(feature.name))
		var intent: Dictionary=game.skater._feature_transition.transfer_intent_snapshot()
		e.transfer=e.transfer or bool(intent.recognized)
	if e.ticks%8==0:
		await tree.create_timer(0.0,false,false).timeout
		e.camera_clear=e.camera_clear and Camera._camera_clear(game)
	if observer.is_valid(): await observer.call(String(e.id)+"_"+phase,game,e.ticks)


static func _steps(tree: SceneTree,game: Node,e: Dictionary,count: int,phase: String,observer: Callable) -> void:
	for tick: int in count: await _step(tree,game,e,phase,observer)


static func _check_receipt(game: Node,e: Dictionary,check: Callable,id: String) -> void:
	var repetitions: Dictionary={}
	var base: int=int(e.hold_points)
	var count := 0
	var valid := true
	for entry: Dictionary in e.entries:
		var definition: Dictionary=Catalog.definition(String(entry.id))
		valid=valid and not definition.is_empty() and String(definition.get("display_name",""))==String(entry.label) \
			and int(definition.get("base_points",0))==int(entry.points)
		if String(definition.get("family",""))=="spin":
			base+=int(entry.points)
		else:
			var key: String=Catalog.repetition_id(String(entry.id))
			var repeats: int=int(repetitions.get(key,0))
			base+=Catalog.repeated_points(int(entry.points),repeats)
			repetitions[key]=repeats+1
			count+=1
	var expected: int=base*mini(count,100)
	check.call(valid and e.hold_valid and count>=2 and expected>0 and e.banks==1 and game.score.total_score==expected
		and game.score.get_combo_value()==0 and e.bails==0 and e.recoveries==0 and e.camera_clear and e.ground_supported,
		id+": independently calculated catalog/repetition/hold receipt banks once without bail or hidden rider")


static func _report(e: Dictionary,game: Node) -> void:
	print("C04_FLAGSHIP ",e.id," captures=",e.captures," entries=",e.entries," holds=",e.hold_points,
		" banks=",e.banks," total=",game.score.total_score," bails=",e.bails," recoveries=",e.recoveries,
		" manual=",e.manual_ticks," bankManual=",e.bank_manual_ticks," faces=",e.spine_faces,
		" transfer=",e.transfer," crossed=",e.spine_crossed," farFloor=",e.native_far_landing," farAt=",e.far_landing_at,
		" camera=",e.camera_clear," supported=",e.ground_supported," at=",game.skater.global_position," stages=",e.stages,
		" gates=",e.route_gates," fountainCharge=",e.fountain_charge_at," fountainRelease=",e.fountain_release_at,
		" fountainReleaseSpeed=",e.fountain_release_speed)


static func _reset(tree: SceneTree,game: Node,start: Vector3,heading: float) -> void:
	_release()
	game.skater.spawn_position=start
	game.start_mode(true)
	game.skater.rotation.y=heading
	await _frames(tree,10)


static func _frames(tree: SceneTree,count: int) -> void:
	for tick: int in count:
		await tree.physics_frame
		await tree.process_frame


static func _axis(negative: String,positive: String,amount: float) -> void:
	Input.action_release(negative)
	Input.action_release(positive)
	if amount<0: Input.action_press(negative,-amount)
	if amount>0: Input.action_press(positive,amount)


static func _release() -> void:
	for action: String in ["push","brake","steer_left","steer_right","spin_left","spin_right","ollie","manual","grind","flip","grab"]:
		Input.action_release(action)
