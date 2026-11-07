extends RefCounted
## November geometry admission: fixed native witnesses, directed bank input,
## ordinary seating captures and an unbroken two-bearing/manual relay.
const Routes=preload("res://tests/world_routes_tests.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const BoundaryFaces=preload("res://tests/pt24_boundary_tests.gd")
const EdgeTrial=preload("res://tests/edge_grind_integration_tests.gd")
const FIRST="Grind_Edge_Bench_x800y244z5900_0_0"
const SECOND="Grind_Edge_Bench_x7000y244z5900_0_0"


static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await Driver._frames(tree,2)
	var world: Node3D=game.world
	var feature: Dictionary={}
	for candidate: Dictionary in world.get_skate_feature_definitions():
		if candidate.id=="exchange_south_line":feature=candidate
	check.call(not feature.is_empty() and feature.position.distance_to(Vector3(-10,0,20))<0.002
		and feature.line[0].distance_to(Vector3(-10,0,9))<0.002
		and feature.line[-1].distance_to(Vector3(-10,0,31))<0.002,
		"November lines: existing Exchange bank follows fixed west-fountain exit witnesses")
	var parity:=true
	for z: float in [12.8,13.2,14,15,16,16.8,17.2,19,22.8,23.2,24,25,26,26.8,27.2]:
		for x: float in [-11.7,-10,-8.3]:
			var expected:=0.55*clampf(minf(z-13,27-z)/4.0,0,1)
			var at:=Vector3(x,expected,z)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.1,at-Vector3.UP*0.1,1))
			parity=parity and absf(world.get_ground_height(at)-expected)<0.002 \
				and not hit.is_empty() and absf(Vector3(hit.position).y-expected)<0.002
	check.call(parity,"November lines:45 independent rotated-bank witnesses match native and query support")
	var passage:=true
	for x: float in [-22,-12,-10,-8,0,12,22]:
		passage=passage and Routes._clear_standing(world,Vector3(x,0,28))
	passage=passage and Routes._clear_sweep(world,Vector3(-22,0,28),Vector3(22,0,28)) \
		and Routes._clear_sweep(world,Vector3(22,0,28),Vector3(-22,0,28))
	check.call(passage,"November lines: unchanged Z28 beginner crossing keeps full native two-way passage")
	var tracks: Dictionary={}
	for line in world.get_grind_lines():tracks[line.id]=line
	var seats:=tracks.has(FIRST) and tracks.has(SECOND)
	if seats:
		seats=tracks[FIRST].points[0].distance_to(Vector3(39.32,2.53,63.725))<0.002 \
			and tracks[FIRST].length>5.3 and tracks[SECOND].length>5.3
	check.call(seats,"November lines: both real extended seats preserve original semantic edge identities")
	var bypass:=true
	for z: float in [68.0,68.5,69.0,69.5,70.0,70.5,71.0,71.5,72.0]:
		var start:=Vector3(24,2,z)
		var finish:=Vector3(78,2,z)
		bypass=bypass and Routes._clear_sweep(world,start,finish) and Routes._clear_sweep(world,finish,start)
		for x: float in [24,32,42,54,64,76]:
			bypass=bypass and Routes._ground_below(world,Vector3(x,2,z))
	check.call(bypass,"November lines: independent nine-lane sweeps retain the complete4m east-quay bypass")
	var seat_count:=0
	var seat_shapes:=0
	var supports:=0
	for body: Node3D in world.find_children("*","Node3D",true,false):
		if body.global_position.z<55 or body.global_position.z>78:continue
		var label:=String(body.get_meta("art_label",""))
		if label=="QuayBenchSupport":supports+=1
		if label!="QuayBenchSeat":continue
		seat_count+=1
		for child: Node in body.get_children():
			if child is CollisionShape3D:seat_shapes+=1
	check.call(seat_count==3 and seat_shapes==3 and supports==6,
		"November lines: existing quay seating retains exactly three bodies/shapes and six decorative supports")
	if not feature.is_empty():await Density._manual_crossing(tree,game,feature,check,observer)
	if seats:
		await EdgeTrial._approach(tree,game,world.get_grind_lines(),check,
			{"family":"Bench_x800y244z5900_","at":Vector3(40,2.53,63.725),"direction":Vector3.RIGHT,"outside":Vector3.FORWARD,"behind":0.9,"charge":2})
		var direction:=Vector3(cos(deg_to_rad(15)),0,-sin(deg_to_rad(15)))
		await EdgeTrial._approach(tree,game,world.get_grind_lines(),check,
			{"family":"Bench_x7000y244z5900_","at":tracks[SECOND].points[0],"direction":direction,"outside":Vector3(-direction.z,0,direction.x)*-1,"behind":0.9,"charge":2})
		await run_relay(tree,game,check,observer)
	await run_bank_return(tree,game,check,observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await Driver._frames(tree,3)


static func run_relay(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	await Driver._reset(tree,game,Vector3(33,2.08,63.55),-PI*.5)
	await Driver._frames(tree,40)
	var e:=Driver._evidence(game,"east_quay_seating_relay")
	e["event_ticks"]=[]
	e["physics_start"]=Engine.get_physics_frames()
	Driver._connect(game,e)
	var popped:=false
	for tick: int in 240:
		if not popped:
			Driver._steer_to(game,Vector3(48,2,63.55),false)
			# Hold Push through the cap, matching the existing gallery driver.
			# Equal brake pressure controls speed without repeatedly arming a
			# directional Boneless/Nollie cue immediately before the plain pop.
			Input.action_press("push")
			Input.action_release("brake")
			if absf(game.skater.speed)>6.6:Input.action_press("brake")
			if game.skater.global_position.x>=36.5:Input.action_press("ollie")
			if game.skater.global_position.x>=38:
				Input.action_release("ollie")
				Input.action_release("push")
				Input.action_release("brake")
				popped=true
		Input.action_press("grind")
		await Driver._step(tree,game,e,"first_seat_approach",observer)
		if game.skater.grinding or e.bails>0:break
	var first: bool=game.skater.grinding and game.skater._grind.line.id==FIRST
	if first:
		e.event_ticks.append({"event":"first_catch","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		for tick: int in 120:
			await Driver._step(tree,game,e,"first_seat_ride",observer)
			if game.skater.global_position.x>=43.4 or not game.skater.grinding:break
		e.event_ticks.append({"event":"first_exit_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"first_outward_pop_charge",observer)
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"first_outward_pop",observer)
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"seats_manual_link",observer)
	var linked: bool=first and game.skater.manual_active
	if linked:
		e.event_ticks.append({"event":"manual_landing","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		for tick: int in 420:
			Driver._manual_to(game,Vector3(62,2,64.4))
			await Driver._step(tree,game,e,"seats_manual_link",observer)
			if game.skater.global_position.x>=58 or e.bails>0:break
	var second:=false
	if linked and game.skater.manual_active and e.bails==0:
		e.event_ticks.append({"event":"second_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		for tick: int in 16:
			Driver._manual_to(game,Vector3(66,2,63.2))
			await Driver._step(tree,game,e,"second_seat_charge",observer)
		e.event_ticks.append({"event":"second_release","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_release("ollie")
		Input.action_release("manual")
		Input.action_release("push")
		Input.action_release("brake")
		Driver._axis("steer_left","steer_right",0)
		Driver._axis("spin_left","spin_right",0)
		Input.action_press("grind")
		for tick: int in 150:
			await Driver._step(tree,game,e,"second_seat_catch",observer)
			if game.skater.grinding or e.bails>0:break
		second=game.skater.grinding and game.skater._grind.line.id==SECOND
	if second:
		e.event_ticks.append({"event":"second_catch","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		# Ride the finite bearing toward its end so the intended landing is the
		# paving runout. The earlier twelve-tick exit landed atop the seat and
		# exposed a separately retained native-prop visual support defect.
		for tick: int in 120:
			await Driver._step(tree,game,e,"second_seat_payoff",observer)
			if game.skater.global_position.x>=65.2 or not game.skater.grinding:break
		e.event_ticks.append({"event":"second_exit_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"second_exit_charge",observer)
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"second_exit",observer)
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"second_landing",observer)
	await Driver._finish_bank(tree,game,e,observer)
	e.event_ticks.append({"event":"banked","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
	check.call(first and linked and second and e.captures==[FIRST,SECOND] and e.manual_ticks>=20,
		"November lines: real mapped Ollie/grind/manual/Ollie/grind connects two native east-quay seats")
	if first and linked and second:Driver._check_receipt(game,e,check,"November east quay")
	print("NOVEMBER_RELAY physics_start=",e.physics_start," events=",e.event_ticks," first=",first," linked=",linked," second=",second)
	Driver._disconnect(game,e)
	Driver._report(e,game)
	Driver._release()
	if first and linked and second and e.bails==0:
		await _return_to_entry(tree,game,check,observer)


static func _return_to_entry(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	# Continue from the actual banked landing through the terminal bank and
	# back to the entry. Neither this turnback nor the bypass uses a restart.
	var e:=Driver._evidence(game,"east_quay_bank_and_return")
	Driver._connect(game,e)
	var approach: bool=await _travel_targets(tree,game,e,[Vector3(75,2,68),Vector3(76,2,73.5),Vector3(78,2,73.5)],observer)
	var bank: Dictionary={"returned":false,"supported":false}
	if approach:bank=await _roll_bank_phase(tree,game,e,73.5,4.0,observer)
	var complete:=false
	if bank.returned:
		complete=await _travel_targets(tree,game,e,[Vector3(73,2,71),Vector3(34,2,71),Vector3(30,2,66),Vector3(33,2,63.55)],observer)
	Driver._release()
	check.call(approach and bank.returned and bank.supported and complete and e.bails==0 and e.recoveries==0
		and e.entries.is_empty() and e.camera_clear,
		"November lines: the actual relay landing climbs the terminal bank and returns fakie to entry without a reset")
	Driver._disconnect(game,e)
	Driver._report(e,game)


static func _travel_targets(tree: SceneTree,game: Node,e: Dictionary,targets: Array,observer: Callable) -> bool:
	for target: Vector3 in targets:
		var reached:=false
		for tick: int in 900:
			# A negative real speed is fakie travel. Aim the facing away from
			# its travel target, preserving native reverse motion and controls.
			var delta: Vector3=target-game.skater.global_position
			if game.skater.speed< -0.5:delta=-delta
			var desired:=atan2(-delta.x,-delta.z)
			var error: float=angle_difference(game.skater.rotation.y,desired)
			Driver._axis("steer_left","steer_right",-clampf(error*1.8,-1,1))
			Driver._speed_input(game,4.2)
			await Driver._step(tree,game,e,"supported_return",observer)
			var point: Vector3=game.skater.global_position
			var height: float=game.world.get_support_height(point,0.3)
			if not is_finite(height) or absf(point.y-height)>=0.18 or game.skater.airborne or e.bails>0:return false
			if Vector2(point.x-target.x,point.z-target.z).length()<1.2:
				reached=true
				e.route_gates.append({"target":target,"at":point,"tick":e.ticks,"physics":Engine.get_physics_frames()})
				break
		if not reached:return false
	return true


static func run_bank_return(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var world: Node3D=game.world
	var record: Dictionary={}
	var boundary: StaticBody3D
	for body: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		if body.has_meta("bank_terminal_return"):
			boundary=body
			record=body.get_meta("bank_terminal_return")
	check.call(is_instance_valid(boundary) and not record.is_empty(),
		"November bank: original eastern terminal wall owns the integrated finite return")
	if record.is_empty():return
	var bounds: Rect2=record.bounds
	var native_triangles:=0
	var display_triangles:=0
	var live_shapes:=0
	var live_meshes:=0
	for child: Node in boundary.get_children():
		if child is CollisionShape3D:
			live_shapes+=1
			if child.shape is ConcavePolygonShape3D:native_triangles+=child.shape.get_faces().size()/3
		if child is MeshInstance3D:
			live_meshes+=1
			display_triangles+=child.mesh.get_faces().size()/3
	check.call(live_shapes==int(record.shape_count) and live_meshes==1 and native_triangles==display_triangles
		and display_triangles==live_shapes*20 and display_triangles-live_shapes*12==int(record.added_triangles),
		"November bank: direct native/display counts retain one mesh and original slots with eight added triangles per panel")
	var middle: float=bounds.get_center().y
	var geometry:=true
	for x: float in [80.9,81.3,82.0,82.9,83.6,84.2]:
		for z: float in [bounds.position.y+0.35,middle,bounds.end.y-0.35]:
			var expected:=2.0+(x-80.8)*2.0/3.9
			var at:=Vector3(x,expected,z)
			var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.08,at-Vector3.UP*.08,1)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(ray)
			geometry=geometry and not hit.is_empty() and hit.collider==boundary \
				and absf(hit.position.y-expected)<0.002 and absf(world.get_ground_height(at)-expected)<0.002 \
				and Vector3(hit.normal).dot(Vector3(-2.0/3.9,1,0).normalized())>0.999 \
				and BoundaryFaces._visible_segment(boundary,at+Vector3.UP*.08,at-Vector3.UP*.08)
	check.call(geometry,"November bank:18 independent slope witnesses share exact native/display/query planes and normals")
	var backing:=true
	for y: float in [4.15,4.5,4.85]:
		for z: float in [bounds.position.y+0.35,middle,bounds.end.y-0.35]:
			var start:=Vector3(84.4,y,z)
			var finish:=Vector3(85.1,y,z)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,finish,1))
			backing=backing and not hit.is_empty() and hit.collider==boundary \
				and absf(hit.position.x-84.7)<0.002 and BoundaryFaces._visible_segment(boundary,start,finish)
	check.call(backing,"November bank: nine fixed elevated rays preserve real opaque terminal containment")
	var shoulder:=true
	var mouth:=PackedVector3Array([Vector3(75,2,69),Vector3(78,2,67),Vector3(94,2,55)])
	for index: int in mouth.size()-1:
		var side:=Vector3((mouth[index+1]-mouth[index]).z,0,-(mouth[index+1]-mouth[index]).x).normalized()
		for offset: float in [-1.0,-0.5,0,0.5,1.0]:
			var a:=mouth[index]+side*offset
			var b:=mouth[index+1]+side*offset
			shoulder=shoulder and Routes._clear_sweep(world,a,b) and Routes._clear_sweep(world,b,a)
			for sample: int in 13:
				var point:=a.lerp(b,float(sample)/12)
				shoulder=shoulder and Routes._ground_below(world,point)
	check.call(shoulder,"November bank: existing diagonal Barras mouth retains five supported two-way shoulder sweeps")
	# Independent fixed inboard line leaves the existing river bollards clear.
	for ceiling: float in [3.2,4.0,4.6]:
		await _uphill_rollback(tree,game,73.5,ceiling,check,observer)
	await Driver._miss_return(tree,game,check,"east_quay_banked_wall",Vector3(74,2.08,69),-PI*.5,
		PackedVector3Array([Vector3(78,2,67),Vector3(94,2,55),Vector3(94,0,45)]),observer)
	print("NOVEMBER_BANK_GEOMETRY bounds=",bounds," profile=",record.profile,
		" shapes=",record.shape_count," native_triangles=",native_triangles," display_triangles=",display_triangles," added_triangles=",record.added_triangles)


static func _uphill_rollback(tree: SceneTree,game: Node,z: float,ceiling: float,check: Callable,observer: Callable) -> void:
	await Driver._reset(tree,game,Vector3(76,2.08,z),-PI*.5)
	await Driver._frames(tree,40)
	var e:=Driver._evidence(game,"east_bank_rollback_"+str(ceiling))
	Driver._connect(game,e)
	var result: Dictionary=await _roll_bank_phase(tree,game,e,z,ceiling,observer)
	check.call(result.released and result.reverse and result.returned and result.peak.x>81.1 and result.peak.x<84.4 and result.peak.y>2.2
		and result.supported and e.bails==0 and e.recoveries==0 and e.entries.is_empty() and e.captures.is_empty() and e.camera_clear,
		"November bank: native climb/stop/fakie plus mapped Push fully clears the toe at approach cap"+str(ceiling))
	Driver._disconnect(game,e)


static func _roll_bank_phase(tree: SceneTree,game: Node,e: Dictionary,z: float,ceiling: float,observer: Callable) -> Dictionary:
	var released:=false
	var returned:=false
	var peak:=Vector3.ZERO
	var entry_speed:=0.0
	var reverse:=false
	var supported:=true
	var events: Array[Dictionary]=[]
	var physics_start:=Engine.get_physics_frames()
	for tick: int in 900:
		if not released:
			Driver._steer_to(game,Vector3(84.0,2,z),false)
			Driver._speed_input(game,ceiling)
			if game.skater.global_position.x>=80.5:
				Driver._release()
				released=true
				entry_speed=game.skater.speed
				events.append({"event":"input_release","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position,"speed":entry_speed})
		# Native grade gravity must establish reversal first. Then ordinary
		# fakie pushing supplies a useful re-entry instead of slowly coasting
		# with the upright capsule/loaded wheels still straddling the toe.
		if reverse:Driver._speed_input(game,3.2)
		await Driver._step(tree,game,e,"real_uphill_and_rollback",observer)
		var point: Vector3=game.skater.global_position
		if point.y>peak.y:peak=point
		var height: float=game.world.get_support_height(point,0.3)
		supported=supported and is_finite(height) and absf(point.y-height)<0.18 and game.skater.is_on_floor() and not game.skater.airborne
		if released and game.skater.speed< -0.5 and not reverse:
			reverse=true
			events.append({"event":"native_rollback_then_fakie_push","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"speed":game.skater.speed})
		if reverse and point.x<80.3:
			returned=true
			events.append({"event":"flat_reentry","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"speed":game.skater.speed})
			break
		if e.bails>0 or e.recoveries>0:break
	Driver._release()
	print("NOVEMBER_BANK_RETURN physics_start=",physics_start," cap=",ceiling," entry_speed=",entry_speed," peak=",peak," events=",events,
		" supported=",supported," camera=",e.camera_clear," bails=",e.bails)
	return {"released":released,"reverse":reverse,"returned":returned,"supported":supported,"peak":peak}
