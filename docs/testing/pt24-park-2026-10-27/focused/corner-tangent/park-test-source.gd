extends RefCounted
## Summit choice through the existing downhill catch and civic promenade.
## Only the declared start/facing is assigned; all travel uses mapped input.
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")
const LOWER := "Grind_Ledge_park_east_lower"

static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await run_player(tree,game,check,observer)
	await Driver._miss_return(tree,game,check,"summit_to_civic",Vector3(-157,17.08,-174),-2.25,
		PackedVector3Array([Vector3(-146,0,-164),Vector3(-144.6,0,-146),Vector3(-144.6,6,-126),
			Vector3(-134,6,-125),Vector3(-110,6,-125),Vector3(-80,6,-124),Vector3(-44,6,-122)]),observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)

static func run_player(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> bool:
	await Driver._reset(tree,game,Vector3(-157,17.08,-174),-2.25)
	var e: Dictionary=Driver._evidence(game,"park_summit_to_civic")
	e.merge({"summit_manual":false,"lower_ticks":0,"summit_start":game.skater.global_position,
		"city_return":false,"distance":0.0,"previous":game.skater.global_position})
	Driver._connect(game,e)
	Input.action_press("push",1.0)
	await _steps(tree,game,e,50,"summit_roll",observer)
	Input.action_press("ollie")
	await _steps(tree,game,e,2,"summit_ollie_charge",observer)
	Input.action_release("ollie")
	Input.action_release("push")
	await _step(tree,game,e,"summit_takeoff",observer)
	await _landing_manual(tree,game,e,150,"summit_manual_landing",observer)
	e.summit_manual=game.skater.manual_active
	var reached: bool=e.summit_manual
	if reached:
		for target: Vector3 in [Vector3(-147,0,-163),Vector3(-147.28,0,-148)]:
			reached=await _manual_target(tree,game,e,target,500,"summit_downhill_manual",observer)
			if not reached:break
	if reached:
		for tick: int in 180:
			Driver._manual_to(game,Vector3(-147.28,0,-120))
			if game.skater.global_position.z>=-144.7:
				Input.action_press("ollie")
				await _steps(tree,game,e,15,"downhill_pop_charge",observer)
				Input.action_release("ollie")
				Input.action_release("manual")
				Driver._axis("spin_left","spin_right",0)
				Driver._axis("steer_left","steer_right",0)
				Input.action_press("grind")
				break
			await _step(tree,game,e,"downhill_catch_approach",observer)
		for tick: int in 160:
			await _step(tree,game,e,"lower_seat_catch",observer)
			if game.skater.grinding or e.bails>0:break
	var caught: bool=game.skater.grinding and game.skater._grind.line.id==LOWER
	if caught:
		for tick: int in 180:
			Driver._axis("steer_left","steer_right",clampf(-0.14-game.skater.grind_balance*.85,-.6,.6))
			await _step(tree,game,e,"lower_seat_payoff",observer)
			if game.skater.global_position.z>=-135.3 or not game.skater.grinding:break
		Input.action_press("ollie")
		await _steps(tree,game,e,2,"lower_seat_exit_charge",observer)
		Driver._axis("steer_left","steer_right",.6)
		Input.action_release("ollie")
		await _step(tree,game,e,"lower_seat_outward_pop",observer)
		Input.action_release("grind")
		Driver._axis("steer_left","steer_right",0)
		await _landing_manual(tree,game,e,150,"lower_seat_manual_landing",observer)
		reached=game.skater.manual_active
		if reached:
			for target: Vector3 in [Vector3(-144,6,-126),Vector3(-134,6,-125),Vector3(-110,6,-125),
				Vector3(-80,6,-124),Vector3(-44,6,-122)]:
				reached=await _manual_target(tree,game,e,target,900,"civic_promenade_manual_return",observer)
				if not reached:break
		e.city_return=reached
	await Driver._finish_bank(tree,game,e,observer)
	check.call(e.summit_manual and caught and e.captures==[LOWER] and e.lower_ticks>=18
		and e.city_return and e.manual_ticks>=120 and e.summit_start.y>16.5 and e.distance>100,
		"C04-L06 flagship: summit Ollie/Manual feeds the existing downhill grind and civic-return flatland in one actual input line")
	Driver._check_receipt(game,e,check,"C04-L06 summit")
	print("PARK_FLAGSHIP summit_manual=",e.summit_manual," lower_ticks=",e.lower_ticks," city_return=",e.city_return,
		" distance_m=",e.distance," final_manual_elapsed=",game.skater._manual_elapsed)
	Driver._disconnect(game,e)
	Driver._report(e,game)
	return e.city_return and caught

static func _manual_target(tree: SceneTree,game: Node,e: Dictionary,target: Vector3,limit: int,
		phase: String,observer: Callable) -> bool:
	for tick: int in limit:
		if not game.skater.manual_active or e.bails>0:return false
		Driver._manual_to(game,target)
		await _step(tree,game,e,phase,observer)
		var point: Vector3=game.skater.global_position
		if Vector2(point.x-target.x,point.z-target.z).length()<1.2:return true
	return false

static func _step(tree: SceneTree,game: Node,e: Dictionary,phase: String,observer: Callable) -> void:
	await Driver._step(tree,game,e,phase,observer)
	if game.skater.grinding and game.skater._grind.line.id==LOWER:e.lower_ticks+=1
	if phase=="lower_seat_catch" and e.ticks%3==0 and game.skater.airborne:
		for line in game.world.get_grind_lines():
			if line.id!=LOWER:continue
			var near: Dictionary=line.closest(game.skater.global_position)
			if near.gap>1.2:continue
			var tangent: Vector3=line.dir_at(near.dist)
			var height: float=game.skater.global_position.y-near.point.y
			print("PARK_CAPTURE_DIAG at=",game.skater.global_position," velocity=",game.skater.velocity,
				" real_velocity=",game.skater.get_real_velocity()," near=",near," tangent=",tangent,
				" delta_y=",height," request=",game.skater._grind_request_available()," spin=",game.skater._spin_landing_clean(),
				" native_clear=",game.skater._rail_path_clear(game.skater.global_position,near.point))
	e.distance+=game.skater.global_position.distance_to(e.previous)
	e.previous=game.skater.global_position

static func _steps(tree: SceneTree,game: Node,e: Dictionary,count: int,phase: String,observer: Callable) -> void:
	for tick: int in count:await _step(tree,game,e,phase,observer)

static func _landing_manual(tree: SceneTree,game: Node,e: Dictionary,limit: int,phase: String,observer: Callable) -> void:
	# A slope changes time-to-contact; request the ordinary fresh Manual once
	# actual native ground contact has occurred, within the real landing link.
	for tick: int in limit:
		if game.skater.is_on_floor() and not game.skater.airborne:
			if not Input.is_action_pressed("manual"):print("PARK_MANUAL_REQUEST at=",game.skater.global_position," speed=",game.skater.speed," cooldown=",game.skater._manual_cooldown)
			Input.action_press("manual")
		await _step(tree,game,e,phase,observer)
		if game.skater.manual_active or e.bails>0:break
