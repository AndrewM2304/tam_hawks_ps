extends RefCounted
## Full entrance-bank/angled-ledge extension of the existing stair/fountain
## representative. Initial spawn/facing only; no corrections or mid-run reset.

const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")
const ENTRANCE := "Grind_Ledge_GalleryEntrance"
const STAIR := "Grind_Rail_GallerySteps"
const FOUNTAIN := "Grind_Coping_ExchangeFountain"


static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await _construction(tree,game,check)
	await run_player(tree,game,check,observer)
	await Driver._miss_return(tree,game,check,"gallery_entrance",Vector3(-22,2.08,-39),PI,
		PackedVector3Array([Vector3(-22,2,-22),Vector3(14.6,2,-22),
			Vector3(14.6,0,0),Vector3(14.6,0,24)]),observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)


static func _construction(tree: SceneTree,game: Node,check: Callable) -> void:
	await Driver._frames(tree,2)
	var line = null
	for candidate in game.world.get_grind_lines():
		if candidate.id==ENTRANCE:line=candidate
	check.call(line!=null and line.contact_verified and line.points.size()==4
		and line.points[0].distance_to(Vector3(-5,3.2,-35))<0.002
		and line.points[-1].distance_to(Vector3(0,3.2,-33.4))<0.002,
		"Gallery entrance extension: existing finite angled ledge and actual contact identity are unchanged")
	var support := true
	var clear := true
	for path: PackedVector3Array in [
		PackedVector3Array([Vector3(-18,2,-35.3),Vector3(-10,2,-35.3),Vector3(-6.75,2.65,-35.3)]),
		PackedVector3Array([Vector3(0,2,-30),Vector3(6.5,2,-26),Vector3(9.1,2,-24),Vector3(9.1,2,-18)]),
		PackedVector3Array([Vector3(-22,2,-39),Vector3(-22,2,-22),Vector3(14.6,2,-22),
			Vector3(14.6,2,-18),Vector3(14.6,0,-4),Vector3(14.6,0,24)])]:
		for index: int in path.size()-1:
			var start: Vector3=path[index]
			var finish: Vector3=path[index+1]
			clear=clear and Routes._clear_sweep(game.world,start,finish) and Routes._clear_sweep(game.world,finish,start)
			var side:=Vector3((finish-start).z,0,-(finish-start).x).normalized()*0.4
			for step: int in 9:
				for lateral: float in [-1,0,1]:
					var point:=start.lerp(finish,float(step)/8)+side*lateral
					var height: float=game.world.get_ground_height(point)
					var hit:=game.world.get_world_3d().direct_space_state.intersect_ray(
						PhysicsRayQueryParameters3D.create(Vector3(point.x,height+.1,point.z),Vector3(point.x,height-.1,point.z),1))
					support=support and is_finite(height) and absf(point.y-height)<0.12 \
						and not hit.is_empty() and absf(hit.position.y-height)<0.002
	check.call(support and clear,
		"Gallery entrance extension: fixed bank/apron/stair handoff and protected miss have full-width native support and two-way clearance")


static func run_player(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await Driver._reset(tree,game,Vector3(-18,2.08,-35.3),-PI*.5)
	var e: Dictionary=Driver._evidence(game,"gallery_entrance_stair_fountain")
	e.merge({"entrance_ticks":0,"entrance_ascent":0.0,"entrance_south_exit":false,
		"entrance_manual":false,"entrance_handoff":false})
	Driver._connect(game,e)
	var popped := false
	for tick: int in 240:
		if not popped:
			Driver._steer_to(game,Vector3(20,2,-35.3),false)
			Driver._speed_input(game,6.5)
			if game.skater.is_on_floor():e.entrance_ascent=maxf(e.entrance_ascent,game.skater.global_position.y-2.0)
		Input.action_press("grind")
		if not popped and game.skater.global_position.x>=-11.5:Input.action_press("ollie")
		if not popped and game.skater.global_position.x>=-8.7:
			Input.action_release("ollie")
			Input.action_release("push")
			Input.action_release("brake")
			popped=true
		await _step(tree,game,e,"entrance_bank_pop_catch",observer)
		if game.skater.grinding or e.bails>0:break
	var entrance_caught: bool=game.skater.grinding and game.skater._grind.line.id==ENTRANCE
	if entrance_caught:
		for tick: int in 180:
			await _step(tree,game,e,"angled_entrance_ledge",observer)
			if game.skater.global_position.z>-33.85 and game.skater.velocity.z>absf(game.skater.velocity.x):
				e.entrance_south_exit=true
				break
			if not game.skater.grinding or e.bails>0:break
		if game.skater.grinding and e.entrance_south_exit:
			Input.action_press("ollie")
			await _steps(tree,game,e,2,"entrance_south_pop_charge",observer)
			Input.action_release("ollie")
			await _step(tree,game,e,"entrance_south_pop",observer)
			Input.action_release("grind")
			await Driver._landing_manual(tree,game,e,150,"entrance_apron_manual",observer)
			e.entrance_manual=game.skater.manual_active
	if e.entrance_manual:
		var targets:=PackedVector3Array([Vector3(6.5,2,-26),Vector3(9.1,2,-23.8),Vector3(9.1,2,-22.4)])
		var all_reached := true
		for target: Vector3 in targets:
			var incoming:=Vector2(target.x-game.skater.global_position.x,target.z-game.skater.global_position.z).normalized()
			var reached := false
			for tick: int in 210:
				Driver._manual_to(game,target)
				await _step(tree,game,e,"entrance_to_stair_manual",observer)
				var at: Vector3=game.skater.global_position
				var delta:=Vector2(at.x-target.x,at.z-target.z)
				if delta.length()<1.15 or (delta.dot(incoming)>=0 and absf(delta.cross(incoming))<1.6):
					reached=true
					e.route_gates.append({"target":target,"at":at})
					break
				if not game.skater.manual_active or e.bails>0 or e.banks>0:break
			if not reached:
				all_reached=false
				break
		e.entrance_handoff=all_reached and game.skater.manual_active and e.banks==0
	var stair_caught := false
	var fountain_caught := false
	var court_manual := false
	if e.entrance_handoff:
		var charged := false
		popped=false
		for tick: int in 240:
			if not popped:
				Driver._manual_to(game,Vector3(9.1,2,-10))
				Driver._speed_input(game,4.2)
			if game.skater.global_position.z>-21 and not charged:
				Input.action_press("ollie")
				charged=true
			if game.skater.global_position.z>-18.5 and not popped:
				Input.action_release("ollie")
				Input.action_release("manual")
				Input.action_release("push")
				Input.action_release("brake")
				Driver._axis("spin_left","spin_right",0)
				Driver._axis("steer_left","steer_right",0)
				Input.action_press("grind")
				popped=true
			await _step(tree,game,e,"gallery_rail_entry",observer)
			if game.skater.grinding or e.bails>0:break
		stair_caught=game.skater.grinding and game.skater._grind.line.id==STAIR
	# The remaining mapped-input sequence is the existing successful Gallery
	# driver, with its original native contacts, release coordinates and limits.
	if stair_caught:
		for tick: int in 180:
			await _step(tree,game,e,"gallery_stair_descent",observer)
			if game.skater.global_position.z>=-9.5 or not game.skater.grinding:break
		Input.action_release("push")
		Input.action_release("brake")
		Input.action_press("ollie")
		await _steps(tree,game,e,2,"gallery_side_pop_charge",observer)
		Driver._axis("steer_left","steer_right",-.9)
		Input.action_release("ollie")
		await _step(tree,game,e,"gallery_side_pop",observer)
		Input.action_release("grind")
		Driver._axis("steer_left","steer_right",0)
		await Driver._landing_manual(tree,game,e,150,"gallery_court_manual",observer)
		court_manual=game.skater.manual_active
	if court_manual:
		for tick: int in 120:
			Driver._manual_to(game,Vector3(11.5,0,-3.4))
			await _step(tree,game,e,"gallery_clear_stair_runout",observer)
			if game.skater.global_position.z>=-3.8 or e.bails>0:break
		for tick: int in 300:
			Driver._manual_to(game,Vector3(6.65,0,4.3))
			await _step(tree,game,e,"fountain_tangent_manual",observer)
			if game.skater.global_position.z>=3.8 or e.bails>0:break
		e.fountain_charge_at=game.skater.global_position
		Input.action_press("ollie")
		for tick: int in 15:
			Driver._manual_to(game,Vector3(6.65,0,10))
			await _step(tree,game,e,"fountain_pop_charge",observer)
		e.fountain_release_at=game.skater.global_position
		e.fountain_release_speed=game.skater.speed
		Input.action_release("ollie")
		Input.action_release("manual")
		Driver._axis("spin_left","spin_right",0)
		Driver._axis("steer_left","steer_right",0)
		Input.action_release("push")
		Input.action_press("grind")
		for tick: int in 140:
			await _step(tree,game,e,"fountain_coping_catch",observer)
			if game.skater.grinding or e.bails>0:break
		fountain_caught=game.skater.grinding and game.skater._grind.line.id==FOUNTAIN
	if fountain_caught:
		for tick: int in 90:
			await _step(tree,game,e,"fountain_coping_payoff",observer)
			if e.fountain_ticks>=36 or not game.skater.grinding:break
		Input.action_press("ollie")
		await _steps(tree,game,e,2,"fountain_dry_exit_charge",observer)
		Driver._axis("steer_left","steer_right",-1)
		Input.action_release("ollie")
		await _step(tree,game,e,"fountain_outward_pop",observer)
		Input.action_release("grind")
		Driver._axis("steer_left","steer_right",0)
		await Driver._landing_manual(tree,game,e,150,"fountain_dry_manual",observer)
		for tick: int in 12:
			Driver._balance_manual(game)
			await _step(tree,game,e,"fountain_dry_manual",observer)
	await Driver._finish_bank(tree,game,e,observer)
	check.call(entrance_caught and e.entrance_ticks>=12 and e.entrance_ascent>.18 and e.entrance_south_exit,
		"Gallery entrance extension: actual bank/Ollie captures the angled ledge and follows its real south exit")
	check.call(e.entrance_manual and e.entrance_handoff and stair_caught and court_manual and fountain_caught
		and e.captures==[ENTRANCE,STAIR,FOUNTAIN] and e.stair_ticks>=12 and e.fountain_ticks>=36,
		"Gallery entrance extension: entrance-ledge/manual/stair-rail/manual/fountain contacts stay in one mapped-input run")
	Driver._check_receipt(game,e,check,"Gallery entrance extension")
	Driver._disconnect(game,e)
	Driver._report(e,game)
	print("GALLERY_ENTRANCE_EXTENSION ascent=",e.entrance_ascent," entrance_ticks=",e.entrance_ticks,
		" south_exit=",e.entrance_south_exit," manual=",e.entrance_manual," handoff=",e.entrance_handoff)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)


static func _step(tree: SceneTree,game: Node,e: Dictionary,phase: String,observer: Callable) -> void:
	await Driver._step(tree,game,e,phase,observer)
	if game.skater.grinding and game.skater._grind.line.id==ENTRANCE:e.entrance_ticks+=1


static func _steps(tree: SceneTree,game: Node,e: Dictionary,count: int,phase: String,observer: Callable) -> void:
	for tick: int in count:await _step(tree,game,e,phase,observer)
