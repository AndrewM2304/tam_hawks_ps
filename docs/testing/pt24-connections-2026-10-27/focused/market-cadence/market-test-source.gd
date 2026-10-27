extends RefCounted
## Loading stair drop -> flatland -> existing hall ledge -> dry return.
## Initial placement only; all later travel/contact/banking uses mapped input.
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")
const LEDGE := "Grind_Ledge_MarketHall"
const RETURN := [Vector3(83,0,18),Vector3(83,0,-6),Vector3(70,0,-6),Vector3(70,1.5,-18),Vector3(93,1.5,-24)]

static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await _construction(tree,game,check)
	await run_player(tree,game,check,observer)
	await Driver._miss_return(tree,game,check,"market_hall_to_loading",Vector3(83,.08,18),0,
		PackedVector3Array(RETURN.slice(1)),observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await Driver._frames(tree,3)

static func _construction(tree: SceneTree,game: Node,check: Callable) -> void:
	await Driver._frames(tree,2)
	var guide: Variant=null
	for line: Variant in game.world.get_grind_lines():
		if String(line.id)==LEDGE:guide=line
	check.call(guide!=null and guide.points.size()==3
		and guide.points[0].distance_to(Vector3(76,.77,4))<.001
		and guide.points[1].distance_to(Vector3(76,.77,10))<.001
		and guide.points[2].distance_to(Vector3(69,.77,17))<.001,
		"C04-L04: existing hall edge retains its exact supported straight/angled bearing and stable guide identity")
	var supported:=true
	var clear:=true
	var count:=0
	var failures:=0
	for segment: int in RETURN.size()-1:
		var a: Vector3=RETURN[segment]
		var b: Vector3=RETURN[segment+1]
		var side:=Vector3((b-a).z,0,-(b-a).x).normalized()*.4
		var steps:=maxi(2,ceili(a.distance_to(b)))
		var previous:=Vector3.INF
		for i: int in steps+1:
			var at:=a.lerp(b,float(i)/steps)
			at.y=game.world.get_ground_height(at)
			if previous.is_finite():clear=clear and Routes._clear_sweep(game.world,previous,at) and Routes._clear_sweep(game.world,at,previous)
			previous=at
			for lateral: float in [-1,0,1]:
				var point:=at+side*lateral
				point.y=game.world.get_ground_height(point)
				var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*.12,point-Vector3.UP*.12,1))
				var ok: bool=is_finite(point.y) and not hit.is_empty() and absf(hit.position.y-point.y)<.002
				if not ok and failures<8:print("MARKET_SUPPORT_FAIL point=",point," hit=",hit)
				if not ok:failures+=1
				supported=supported and ok
				count+=1
	check.call(supported and clear,"C04-L04: fixed full-width dry hall-to-loading return has native support and two-way capsule clearance")
	print("MARKET_FULL_GEOMETRY samples=",count," support=",supported," clear=",clear)

static func run_player(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	await Driver._reset(tree,game,Vector3(100.8,1.58,-24),PI)
	var e: Dictionary=Driver._evidence(game,"market_loading_to_hall")
	e.merge({"drop_air":false,"drop_landing":false,"hall_ticks":0,"return_reached":false,"drop_at":Vector3.INF})
	Driver._connect(game,e)
	for tick: int in 300:
		_speed(game,6.0)
		Driver._steer_to(game,Vector3(100.8,1.5,-10),false)
		if game.skater.global_position.z>=-19.3:
			Input.action_press("ollie")
			await _step(tree,game,e,"loading_pop_charge",observer)
			Input.action_release("ollie")
			Input.action_release("push")
			Input.action_release("brake")
			Driver._axis("steer_left","steer_right",0)
			await _step(tree,game,e,"loading_takeoff",observer)
			e.drop_at=game.skater.global_position
			break
		await _step(tree,game,e,"loading_approach",observer)
	await _landing_manual(tree,game,e,180,"loading_native_landing",observer)
	e.drop_landing=game.skater.manual_active and game.skater.global_position.z> -18 and game.skater.global_position.y<.20
	var reached: bool=e.drop_landing
	if reached:
		for target: Vector3 in [Vector3(100.8,0,-8),Vector3(98,0,-2),Vector3(89,0,-2),Vector3(82,0,-2),Vector3(78,0,-2),Vector3(76.65,0,.5)]:
			reached=await _manual_to(tree,game,e,target,360,"hall_flatland_approach",observer)
			if not reached:break
			if target==Vector3(100.8,0,-8) or target==Vector3(89,0,-2):
				reached=await _refresh_manual(tree,game,e,observer)
				if not reached:break
	if reached:
		Input.action_release("manual")
		Driver._axis("spin_left","spin_right",0)
		Input.action_press("ollie")
		for tick: int in 10:
			_speed(game,7.2)
			Driver._steer_to(game,Vector3(76.4,0,12),false)
			await _step(tree,game,e,"hall_pop_charge",observer)
		Input.action_release("ollie")
		Input.action_release("manual")
		Input.action_release("push")
		Input.action_release("brake")
		Driver._axis("spin_left","spin_right",0)
		Driver._axis("steer_left","steer_right",0)
		Input.action_press("grind")
		for tick: int in 150:
			await _step(tree,game,e,"hall_native_catch",observer)
			if game.skater.grinding or e.bails>0:break
	var caught: bool=game.skater.grinding and String(game.skater._grind.line.id)==LEDGE
	if caught:
		for tick: int in 180:
			Driver._axis("steer_left","steer_right",clampf(-.14-game.skater.grind_balance*.85,-.6,.6))
			await _step(tree,game,e,"hall_edge_payoff",observer)
			if game.skater.global_position.z>=8.5 or not game.skater.grinding:break
		Input.action_press("ollie")
		await _steps(tree,game,e,2,"hall_outward_pop_charge",observer)
		Driver._axis("steer_left","steer_right",-1)
		Input.action_release("ollie")
		await _step(tree,game,e,"hall_outward_takeoff",observer)
		Input.action_release("grind")
		Driver._axis("steer_left","steer_right",0)
		await _landing_manual(tree,game,e,150,"hall_dry_landing",observer)
		if game.skater.manual_active:e.return_reached=await _manual_to(tree,game,e,RETURN[0],500,"hall_dry_return",observer)
	await Driver._finish_bank(tree,game,e,observer)
	check.call(e.drop_air and e.drop_landing and caught and e.captures==[LEDGE] and e.hall_ticks>=18 and e.return_reached and e.manual_ticks>=45,
		"C04-L04: actual loading-drop Ollie/Manual links to the hall ledge and dry return in one connected mapped-input line")
	Driver._check_receipt(game,e,check,"C04-L04 market")
	print("MARKET_FULL_INPUT drop_air=",e.drop_air," drop_landing=",e.drop_landing," hall_ticks=",e.hall_ticks," dry_return=",e.return_reached," pop_at=",e.drop_at)
	Driver._disconnect(game,e)
	Driver._report(e,game)

static func _manual_to(tree: SceneTree,game: Node,e: Dictionary,target: Vector3,limit: int,phase: String,observer: Callable) -> bool:
	for tick: int in limit:
		if not game.skater.manual_active or e.bails>0:return false
		Driver._manual_to(game,target)
		await _step(tree,game,e,phase,observer)
		var at: Vector3=game.skater.global_position
		if Vector2(at.x-target.x,at.z-target.z).length()<1.2:return true
	return false

static func _landing_manual(tree: SceneTree,game: Node,e: Dictionary,limit: int,phase: String,observer: Callable) -> void:
	for tick: int in limit:
		if game.skater.is_on_floor() and not game.skater.airborne:Input.action_press("manual")
		await _step(tree,game,e,phase,observer)
		if game.skater.manual_active or e.bails>0:break

static func _speed(game: Node,ceiling: float) -> void:
	Input.action_press("push")
	if absf(game.skater.speed)>ceiling:Input.action_press("brake")
	else:Input.action_release("brake")

static func _step(tree: SceneTree,game: Node,e: Dictionary,phase: String,observer: Callable) -> void:
	await Driver._step(tree,game,e,phase,observer)
	if game.skater.airborne and game.skater.global_position.z> -18 and game.skater.global_position.z< -5:e.drop_air=true
	if game.skater.grinding and String(game.skater._grind.line.id)==LEDGE:e.hall_ticks+=1

static func _steps(tree: SceneTree,game: Node,e: Dictionary,count: int,phase: String,observer: Callable) -> void:
	for tick: int in count:await _step(tree,game,e,phase,observer)

static func _refresh_manual(tree: SceneTree,game: Node,e: Dictionary,observer: Callable) -> bool:
	Input.action_release("manual")
	Driver._axis("spin_left","spin_right",0)
	Driver._axis("steer_left","steer_right",0)
	Input.action_press("ollie")
	for tick: int in 15:
		_speed(game,8.0)
		await _step(tree,game,e,"market_flatland_push_charge",observer)
	Input.action_release("ollie")
	Input.action_release("push")
	Input.action_release("brake")
	await _step(tree,game,e,"market_flatland_takeoff",observer)
	await _landing_manual(tree,game,e,150,"market_flatland_native_manual",observer)
	return game.skater.manual_active and e.bails==0
