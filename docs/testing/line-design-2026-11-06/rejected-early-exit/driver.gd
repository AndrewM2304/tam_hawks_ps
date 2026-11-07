extends RefCounted
## November geometry admission: fixed native witnesses, directed bank input,
## ordinary seating captures and an unbroken two-bearing/manual relay.
const Routes=preload("res://tests/world_routes_tests.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const EdgeTrial=preload("res://tests/edge_grind_integration_tests.gd")
const FIRST="Grind_Edge_Bench_x800y244z5900_0_0"
const SECOND="Grind_Edge_Bench_x7000y244z5900_0_0"


static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
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
	Driver._release()


static func run_relay(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	await Driver._reset(tree,game,Vector3(33,2.08,63.55),-PI*.5)
	var e:=Driver._evidence(game,"east_quay_seating_relay")
	e["event_ticks"]=[]
	Driver._connect(game,e)
	var popped:=false
	for tick: int in 240:
		if not popped:
			Driver._steer_to(game,Vector3(48,2,63.55),false)
			Driver._speed_input(game,6.6)
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
		e.event_ticks.append({"event":"first_catch","tick":e.ticks,"at":game.skater.global_position})
		for tick: int in 120:
			await Driver._step(tree,game,e,"first_seat_ride",observer)
			if game.skater.global_position.x>=43.4 or not game.skater.grinding:break
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"first_outward_pop_charge",observer)
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"first_outward_pop",observer)
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"seats_manual_link",observer)
	var linked: bool=first and game.skater.manual_active
	if linked:
		e.event_ticks.append({"event":"manual_landing","tick":e.ticks,"at":game.skater.global_position})
		for tick: int in 420:
			Driver._manual_to(game,Vector3(62,2,64.4))
			Driver._speed_input(game,6.8)
			await Driver._step(tree,game,e,"seats_manual_link",observer)
			if game.skater.global_position.x>=58 or e.bails>0:break
	var second:=false
	if linked and game.skater.manual_active and e.bails==0:
		Input.action_press("ollie")
		for tick: int in 16:
			Driver._manual_to(game,Vector3(66,2,63.2))
			await Driver._step(tree,game,e,"second_seat_charge",observer)
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
		e.event_ticks.append({"event":"second_catch","tick":e.ticks,"at":game.skater.global_position})
		await Driver._steps(tree,game,e,12,"second_seat_payoff",observer)
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"second_exit_charge",observer)
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"second_exit",observer)
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"second_landing",observer)
	await Driver._finish_bank(tree,game,e,observer)
	check.call(first and linked and second and e.captures==[FIRST,SECOND] and e.manual_ticks>=20,
		"November lines: real mapped Ollie/grind/manual/Ollie/grind connects two native east-quay seats")
	if first and linked and second:Driver._check_receipt(game,e,check,"November east quay")
	print("NOVEMBER_RELAY events=",e.event_ticks," first=",first," linked=",linked," second=",second)
	Driver._disconnect(game,e)
	Driver._report(e,game)
	Driver._release()
