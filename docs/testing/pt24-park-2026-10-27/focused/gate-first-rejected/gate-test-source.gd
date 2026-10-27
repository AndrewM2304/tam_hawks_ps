extends RefCounted
## Installed Main gate, mapped interaction and native transit; one initial pose.
## No actor corrections, direct gate tick/toggle calls or manufactured score.
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Camera = preload("res://tests/full_level_density_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")

static func run(tree: SceneTree,game: Node,check: Callable) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await Driver._reset(tree,game,Vector3(-48.5,2.04,-18),PI)
	var e := {"ticks":0,"bails":0,"recoveries":0,"tricks":0,"supported":true,"camera":true,
		"closed_contacts":0,"phase":"","stages":[],"callbacks":[]}
	var on_bail := func()->void:e.bails+=1
	var on_recovery := func()->void:e.recoveries+=1
	var on_trick := func(_name: String,_points: int)->void:e.tricks+=1
	e.callbacks=[on_bail,on_recovery,on_trick]
	game.skater.bailed.connect(on_bail)
	game.skater.recovered.connect(on_recovery)
	game.skater.trick_performed.connect(on_trick)
	var gate: Node3D=game.feature_hub.gate
	# Approach the real closed shutter, rather than inferring blockage from metadata.
	for tick: int in 420:
		Driver._steer_to(game,Vector3(-48.5,2,3),false)
		Input.action_press("push",0.55)
		await _step(tree,game,e,"closed_approach")
		for index: int in game.skater.get_slide_collision_count():
			if game.skater.get_slide_collision(index).get_collider()==gate._panel:
				e.closed_contacts+=1
		if e.closed_contacts>=18 or e.bails>0:break
	var closed_blocked: bool=e.closed_contacts>=18 and game.skater.global_position.z> -3.0 \
		and game.skater.global_position.z< -2.25 and not gate.route_definition().enabled
	check.call(closed_blocked,"PT24-27 input: actual Push reaches and is stopped by the installed closed shutter")
	_release_motion()
	Input.action_press("brake")
	Input.action_press("interact")
	await _step(tree,game,e,"mapped_open")
	Input.action_release("interact")
	await _step(tree,game,e,"mapped_open_release")
	var mapped_open: bool=gate.requested_open
	for tick: int in 85:await _step(tree,game,e,"opening")
	check.call(mapped_open and gate.status_snapshot().open and gate.route_definition().enabled,
		"PT24-27 input: a fresh mapped Interact raises the real panel and enables its route")
	var south_reached := false
	if gate.status_snapshot().open:
		for tick: int in 360:
			_drive(game,Vector3(-48.5,2,15),3.8)
			await _step(tree,game,e,"south_traverse")
			if game.skater.global_position.z>=12:
				south_reached=true
				break
			if e.bails>0:break
	check.call(south_reached and e.bails==0,"PT24-27 input: ordinary supported Push traverses the opened alley to the south street mouth")
	_release_motion()
	Input.action_press("brake")
	for tick: int in 35:await _step(tree,game,e,"south_stop")
	# Ground steering while stopped is the ordinary mapped turnaround. The
	# fixture does not assign heading at the far mouth or reset for the return.
	for tick: int in 180:
		Driver._steer_to(game,Vector3(-48.5,2,-18),false)
		await _step(tree,game,e,"south_turnaround")
		var toward: Vector3=Vector3(-48.5,2,-18)-game.skater.global_position
		if absf(angle_difference(game.skater.rotation.y,atan2(-toward.x,-toward.z)))<0.015:break
	var north_return := false
	if south_reached:
		for tick: int in 420:
			_drive(game,Vector3(-48.5,2,-12),2.8)
			await _step(tree,game,e,"north_traverse")
			if game.skater.global_position.z<= -4.2:
				north_return=true
				break
			if e.bails>0:break
	check.call(north_return and e.bails==0,"PT24-27 input: the same rider turns using mapped steering and traverses the actual opening northward")
	_release_motion()
	Input.action_press("brake")
	for tick: int in 35:await _step(tree,game,e,"north_clear_sensor")
	var close_at: Vector3=game.skater.global_position
	var close_prompt: String=game.feature_hub.gate_prompt(close_at)
	Input.action_press("interact")
	await _step(tree,game,e,"mapped_close")
	Input.action_release("interact")
	for tick: int in 85:await _step(tree,game,e,"closing")
	var closed_again: bool=not gate.requested_open and gate.progress==0 and not gate.route_definition().enabled
	check.call(close_prompt.begins_with("CLOSE") and closed_again
		and not Routes._clear_sweep(game.world,Vector3(-48.5,2.04,-5),Vector3(-48.5,2.04,1)),
		"PT24-27 input: the returned rider clears the sensor and mapped Interact closes real collision and route together")
	var north_mouth := false
	if north_return:
		for tick: int in 240:
			_drive(game,Vector3(-48.5,2,-22),3.8)
			await _step(tree,game,e,"north_street_return")
			if game.skater.global_position.z<= -18:
				north_mouth=true
				break
			if e.bails>0:break
	check.call(north_mouth and e.supported and e.bails==0 and e.recoveries==0,
		"PT24-27 input: complete north→south→north street return stays natively supported without a bail or relocation")
	check.call(e.camera,"PT24-27 input: complete rider, board and ordinary chase volume remain clear through both alley directions")
	check.call(e.tricks==0 and game.score.total_score==0 and game.score.get_combo_value()==0,
		"PT24-27 input: gate interaction and ordinary transit manufacture no trick or score")
	print("PT24_GATE_INPUT ticks=",e.ticks," closedContacts=",e.closed_contacts," south=",south_reached,
		" north=",north_return," mouth=",north_mouth," closeAt=",close_at," closePrompt=",close_prompt,
		" closed=",closed_again," supported=",e.supported," camera=",e.camera,
		" bails=",e.bails," recoveries=",e.recoveries," tricks=",e.tricks," stages=",e.stages)
	Input.action_release("interact")
	Driver._release()
	game.skater.bailed.disconnect(on_bail)
	game.skater.recovered.disconnect(on_recovery)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await Driver._frames(tree,3)

static func _drive(game: Node,target: Vector3,speed: float) -> void:
	Driver._steer_to(game,target,false)
	Driver._speed_input(game,speed)

static func _release_motion() -> void:
	for action: String in ["push","brake","steer_left","steer_right"]:Input.action_release(action)

static func _step(tree: SceneTree,game: Node,e: Dictionary,phase: String) -> void:
	await Driver._frames(tree,1)
	e.ticks+=1
	if e.phase!=phase:
		e.phase=phase
		e.stages.append({"phase":phase,"at":game.skater.global_position,"speed":game.skater.speed})
	var at: Vector3=game.skater.global_position
	var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		at+Vector3.UP*0.2,at-Vector3.UP*0.2,1))
	e.supported=e.supported and not game.skater.airborne and not hit.is_empty() and absf(Vector3(hit.position).y-at.y)<0.13
	if e.ticks%8==0:
		await tree.create_timer(0.0,false,false).timeout
		e.camera=e.camera and Camera._camera_clear(game)
