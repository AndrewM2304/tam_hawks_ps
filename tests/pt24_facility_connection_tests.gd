extends RefCounted
## One earned promenade practice bank, then the supported facility journey and
## return. Only initial spawn/facing are assigned; travel is not a200m combo.
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")
const Camera = preload("res://tests/full_level_density_tests.gd")
const HILL := [Vector3(-88,6,-124),Vector3(-110,6,-124),Vector3(-134,6,-125),
	Vector3(-144.6,6,-126),Vector3(-144.6,0,-146),Vector3(-146,0,-164),
	Vector3(-157,17,-174),Vector3(-161,17,-178),Vector3(-165,17,-182.5),
	Vector3(-173,17,-182.5),Vector3(-179,17,-182.5),Vector3(-183.25,15.75,-182.5),
	Vector3(-187.5,14.5,-182.5)]

static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await Driver._reset(tree,game,Vector3(-85,6.08,-130),PI*.5)
	var e: Dictionary=Driver._evidence(game,"promenade_practice_to_facility")
	e.merge({"distance":0.0,"previous":game.skater.global_position,"transit_supported":true,
		"transit_ticks":0,"facility_ticks":0,"entry_visible":false,"basin_visible":false,
		"targets":[],"throttle":"","summit_hint":"","entry_hint":"","arrival_y":INF})
	Driver._connect(game,e)
	await _geometry(tree,game,check)
	Input.action_press("push")
	var launched := false
	for tick: int in 180:
		await _step(tree,game,e,"practice_quarter_approach",observer)
		if game.skater._feature_transition.active and game.skater._feature_transition.state=="air" and game.skater.airborne:
			launched=String(game.skater._feature_transition.feature.feature_id)=="KelvingrovePromenadeQuarter"
			break
		if e.bails>0:break
	if launched:
		Input.action_release("push")
		Input.action_press("flip")
		await _steps(tree,game,e,2,"practice_real_flip",observer)
		Input.action_release("flip")
		Input.action_press("grab")
		await _steps(tree,game,e,2,"practice_real_grab",observer)
		Input.action_release("grab")
		for tick: int in 220:
			await _step(tree,game,e,"practice_native_return",observer)
			if e.banks==1 and not game.skater.transition_active and not game.skater.airborne:break
			if e.bails>0:break
	var practice_banked: bool=launched and e.entries.size()>=2 and e.banks==1 and game.score.total_score>0 and not game.skater.airborne
	check.call(practice_banked,"C04-L06 facility: real promenade-quarter air tricks return to native support and earn one practice bank")
	Driver._check_receipt(game,e,check,"C04-L06 promenade practice")
	var bank: int=game.score.total_score
	var entries: int=e.entries.size()
	var outbound := practice_banked
	# A genuine quarter return rolls backwards before the ordinary toe exit.
	# Stop with mapped Brake before steering the new route; turning a fast
	# backwards actor as if travelling forward is a driver error.
	if outbound:
		Input.action_release("push")
		Input.action_press("brake")
		for tick: int in 70:
			await _step(tree,game,e,"practice_native_rollout_stop",observer)
			if absf(game.skater.speed)<.05 and not game.skater.airborne:break
	if outbound:
		for target: Vector3 in HILL:
			outbound=await _drive(tree,game,e,target,"practice_to_summit_access",observer,.18 if target.x== -187.5 else .65)
			if not outbound:break
			if target.x== -173:
				e.summit_hint=game.hud._route_location_hint({"player_position":game.skater.global_position})
			if target.x== -179:
				e.entry_visible=_visible(game,Vector3(-187.5,15.2,-182.5))
			if target.x== -187.5:
				e.arrival_y=game.skater.global_position.y
				e.entry_hint=game.hud._route_location_hint({"player_position":game.skater.global_position})
	var definition: Dictionary=game.world.get_park_skatepark_definition()
	var park: Node3D=game.world.get_node("OutdoorRoutes/KelvingroveSunkenSkatepark")
	var circuit: PackedVector3Array=park.get_safety_routes()[0].points
	var beginner := outbound
	if beginner:
		for index: int in circuit.size():
			if index==0:e.basin_visible=_visible(game,Vector3(-199,13.8,-179))
			beginner=await _drive(tree,game,e,circuit[index],"facility_beginner_arrival_return",observer)
			if not beginner:break
	var returned := beginner
	if returned:
		for index: int in range(HILL.size()-2,-1,-1):
			returned=await _drive(tree,game,e,HILL[index],"facility_to_practice_return",observer)
			if not returned:break
		if returned:returned=await _drive(tree,game,e,Vector3(-85,6,-124),"practice_return_mouth",observer)
		if returned:returned=await _drive(tree,game,e,Vector3(-85,6,-130),"practice_return_start",observer)
	Driver._release()
	Input.action_press("brake")
	await _steps(tree,game,e,35,"final_stopped_bank_observation",observer)
	Driver._release()
	check.call(outbound and definition.entry.distance_to(Vector3(-187.5,14.5,-182.5))<.001 and absf(float(e.arrival_y)-14.5)<.15,
		"C04-L06 facility: the same rider travels the real promenade/hillside/summit access to the mapped sunken-park entrance")
	check.call(beginner and e.facility_ticks>120,
		"C04-L06 facility: actual no-jump deck turn enters the lower basin and returns through its finite beginner bank")
	check.call(returned and e.distance>350 and e.transit_supported and e.bails==0 and e.recoveries==0,
		"C04-L06 facility: the complete hill/facility journey returns to practice on supported ground without a reset or relocation")
	check.call(e.entry_visible and e.basin_visible and e.camera_clear
		and String(e.summit_hint).contains("summit link") and String(e.entry_hint).contains("East roll-in"),
		"C04-L06 facility: ordinary full-body chase keeps the rider clear and reveals the entry and beginner landing before commitment")
	check.call(game.score.total_score==bank and e.banks==1 and e.entries.size()==entries and game.score.get_combo_value()==0,
		"C04-L06 facility: ordinary hill/facility travel cannot manufacture extra tricks or duplicate the earned practice bank")
	print("FACILITY_CONNECTION ",{"practice":practice_banked,"outbound":outbound,"beginner":beginner,"returned":returned,
		"bank":bank,"distance_m":e.distance,"transit_ticks":e.transit_ticks,"facility_ticks":e.facility_ticks,
		"arrival_y":e.arrival_y,"entry_visible":e.entry_visible,"basin_visible":e.basin_visible,"summit_hint":e.summit_hint,"entry_hint":e.entry_hint,"supported":e.transit_supported,
		"camera":e.camera_clear,"bails":e.bails,"recoveries":e.recoveries,"targets":e.targets})
	Driver._report(e,game)
	Driver._disconnect(game,e)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await Driver._frames(tree,3)

static func _geometry(tree: SceneTree,game: Node,check: Callable) -> void:
	await Driver._frames(tree,2)
	var support := true
	var clear := true
	var samples := 0
	var error := 0.0
	var intended := true
	var authored_error := 0.0
	for point: Vector3 in HILL:
		if point.y==0:continue
		var height: float=game.world.get_ground_height(point)
		var gap: float=absf(height-point.y)
		authored_error=maxf(authored_error,gap)
		intended=intended and is_finite(height) and gap<.15
	check.call(intended,"C04-L06 facility: independently declared promenade/summit/access levels remain6/17/15.75/14.5m rather than accepting a matching lower floor")
	for index: int in HILL.size()-1:
		var first: Vector3=HILL[index]
		var last: Vector3=HILL[index+1]
		var side:=Vector3((last-first).z,0,-(last-first).x).normalized()*.35
		var steps:=maxi(2,ceili(Vector2(last.x-first.x,last.z-first.z).length()))
		var previous:=Vector3.INF
		for step: int in steps+1:
			var center:=first.lerp(last,float(step)/steps)
			center.y=game.world.get_ground_height(center)
			if previous.is_finite():clear=clear and Routes._clear_sweep(game.world,previous,center) and Routes._clear_sweep(game.world,center,previous)
			previous=center
			for lateral: float in [-1,0,1]:
				var point:=center+side*lateral
				point.y=game.world.get_ground_height(point)
				var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*.1,point-Vector3.UP*.1,1))
				var gap: float=INF if hit.is_empty() else absf(hit.position.y-point.y)
				error=maxf(error,gap)
				support=support and is_finite(point.y) and gap<.002 and not hit.is_empty() and hit.normal.y>cos(deg_to_rad(56))
				samples+=1
	check.call(support and clear,"C04-L06 facility: independently fixed full-width promenade/hillside/summit access has matching native support and two-way capsule clearance")
	print("FACILITY_CONNECTION_GEOMETRY samples=",samples," max_error_m=",error," authored_height_error_m=",authored_error," clear=",clear)

static func _drive(tree: SceneTree,game: Node,e: Dictionary,target: Vector3,phase: String,observer: Callable,tolerance: float=.65) -> bool:
	var origin: Vector3=game.skater.global_position
	var distance:=Vector2(target.x-origin.x,target.z-origin.z).length()
	var limit:=clampi(ceili((distance/3.5+4)*60),300,1800)
	var previous: Vector3=origin
	var stalled := 0
	for tick: int in limit:
		var delta: Vector3=target-game.skater.global_position
		var remaining:=Vector2(delta.x,delta.z).length()
		if remaining<tolerance:
			e.targets.append({"phase":phase,"target":target,"at":game.skater.global_position,"ticks":e.ticks})
			return true
		var angle: float=angle_difference(game.skater.rotation.y,atan2(-delta.x,-delta.z))
		Driver._axis("steer_left","steer_right",-clampf(angle*2,-1,1))
		var action: String="brake" if absf(angle)>.55 or absf(game.skater.speed)>3.8 else "push"
		if e.throttle!="" and e.throttle!=action:
			Input.action_press("push");Input.action_press("brake")
		else:
			Input.action_release("brake" if action=="push" else "push")
			Input.action_press(action)
		e.throttle=action
		await _step(tree,game,e,phase,observer)
		e.transit_ticks+=1
		if phase=="facility_beginner_arrival_return":e.facility_ticks+=1
		var point: Vector3=game.skater.global_position
		var height: float=game.world.get_support_height(point,.3)
		e.transit_supported=e.transit_supported and is_finite(height) and absf(point.y-height)<.18 and not game.skater.airborne
		stalled=stalled+1 if point.distance_to(previous)<.001 else 0
		previous=point
		if stalled>=35 or e.bails>0:
			var contacts: Array=[]
			for collision_index: int in game.skater.get_slide_collision_count():
				var hit: KinematicCollision3D=game.skater.get_slide_collision(collision_index)
				contacts.append({"name":str(hit.get_collider().name),"point":hit.get_position(),"normal":hit.get_normal()})
			print("FACILITY_CONNECTION_BLOCKED ",{"phase":phase,"at":point,"target":target,"contacts":contacts,"speed":game.skater.speed})
			return false
	return false

static func _step(tree: SceneTree,game: Node,e: Dictionary,phase: String,observer: Callable) -> void:
	await Driver._step(tree,game,e,phase,observer)
	e.distance+=game.skater.global_position.distance_to(e.previous)
	e.previous=game.skater.global_position

static func _steps(tree: SceneTree,game: Node,e: Dictionary,count: int,phase: String,observer: Callable) -> void:
	for tick: int in count:await _step(tree,game,e,phase,observer)

static func _visible(game: Node,target: Vector3) -> bool:
	var camera: Camera3D=game.skater._camera
	if not camera.is_position_in_frustum(target):return false
	var query:=PhysicsRayQueryParameters3D.create(camera.global_position,target,1|8,[game.skater.get_rid()])
	return game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
