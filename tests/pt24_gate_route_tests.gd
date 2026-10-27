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
		"closed_contacts":0,"phase":"","stages":[]}
	var on_bail := func()->void:e.bails+=1
	var on_recovery := func()->void:e.recoveries+=1
	var on_trick := func(_name: String,_points: int)->void:e.tricks+=1
	game.skater.bailed.connect(on_bail)
	game.skater.recovered.connect(on_recovery)
	game.skater.trick_performed.connect(on_trick)
	var gate: Node3D=game.feature_hub.gate
	# Stop safely in normal prompt range. The deliberate closed-shutter
	# collision control runs separately after this complete return.
	for tick: int in 360:
		_drive(game,Vector3(-48.5,2,0),3.2)
		await _step(tree,game,e,"north_prompt_approach")
		if game.skater.global_position.z>= -4.7 or e.bails>0:break
	_release_motion()
	Input.action_press("brake")
	for tick: int in 35:await _step(tree,game,e,"north_prompt_stop")
	var initial_prompt: String=game.feature_hub.gate_prompt(game.skater.global_position)
	check.call(initial_prompt.begins_with("OPEN") and not gate.route_definition().enabled
		and not Routes._clear_sweep(game.world,Vector3(-48.5,2.04,-5),Vector3(-48.5,2.04,1)),
		"PT24-27 input: safe north-street approach exposes mapped Open while the real closed route remains blocked")
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
	# Independent adverse control after the full normal route. The original
	# rejected input witness showed finite shoes/board beyond the capsule;
	# actual rendered vertices must now remain clear at impact and release.
	_release_motion()
	Input.action_press("brake")
	for tick: int in 35:await _step(tree,game,e,"impact_control_stop",false)
	for tick: int in 180:
		Driver._steer_to(game,Vector3(-48.5,2,3),false)
		await _step(tree,game,e,"impact_control_turn",false)
		var toward: Vector3=Vector3(-48.5,2,3)-game.skater.global_position
		if absf(angle_difference(game.skater.rotation.y,atan2(-toward.x,-toward.z)))<0.015:break
	var impact_at := Vector3.INF
	var impact_camera := true
	var impact_geometry := {}
	for tick: int in 420:
		_drive(game,Vector3(-48.5,2,3),3.2)
		await _step(tree,game,e,"closed_impact_control",false)
		for index: int in game.skater.get_slide_collision_count():
			if game.skater.get_slide_collision(index).get_collider()==gate._panel:
				e.closed_contacts+=1
		if e.closed_contacts>0:
			impact_at=game.skater.global_position
			impact_camera=Camera._camera_clear(game)
			impact_geometry=_wall_clearance(game,-2.09)
			break
		if e.bails>0:break
	_release_motion()
	Input.action_press("brake")
	for tick: int in 40:await _step(tree,game,e,"closed_impact_stopped",false)
	var stopped_at: Vector3=game.skater.global_position
	for tick: int in 20:await _step(tree,game,e,"closed_impact_stationary",false)
	check.call(e.closed_contacts>0 and impact_at.z> -3.0 and impact_at.z< -2.25
		and absf(game.skater.speed)<0.02 and game.skater.global_position.distance_to(stopped_at)<0.001
		and not gate.route_definition().enabled and e.bails==0,
		"PT24-27 adverse input: actual closed-panel collision stops native movement and remains stationary without a bail")
	var stopped_geometry := _wall_clearance(game,-2.09)
	var stopped_camera := Camera._camera_clear(game)
	check.call(not impact_geometry.is_empty() and impact_geometry.board_vertices>100 and impact_geometry.shoe_vertices>100
		and impact_geometry.board_gap>=0.007 and impact_geometry.shoe_gap>=0.007 and impact_camera,
		"PT24-27 adverse input: every actual displayed board/shoe vertex clears the closed wall by seven millimetres at native impact with strict chase visibility")
	check.call(stopped_geometry.board_gap>=0.007 and stopped_geometry.shoe_gap>=0.007 and stopped_camera,
		"PT24-27 adverse input: native Brake/idle keeps actual board/shoes clear after the collision response settles")
	print("PT24_GATE_ADVERSE impactAt=",impact_at," stoppedAt=",stopped_at,
		" actualContacts=",e.closed_contacts," camera=",impact_camera," stoppedCamera=",stopped_camera,
		" impactGeometry=",impact_geometry," stoppedGeometry=",stopped_geometry)
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

static func _step(tree: SceneTree,game: Node,e: Dictionary,phase: String,normal_camera: bool=true) -> void:
	await Driver._frames(tree,1)
	e.ticks+=1
	if e.phase!=phase:
		e.phase=phase
		e.stages.append({"phase":phase,"at":game.skater.global_position,"speed":game.skater.speed})
	var at: Vector3=game.skater.global_position
	var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		at+Vector3.UP*0.2,at-Vector3.UP*0.2,1))
	e.supported=e.supported and not game.skater.airborne and not hit.is_empty() and absf(Vector3(hit.position).y-at.y)<0.13
	if normal_camera and e.ticks%8==0:
		await tree.create_timer(0.0,false,false).timeout
		e.camera=e.camera and Camera._camera_clear(game)

static func _wall_clearance(game: Node,wall_z: float) -> Dictionary:
	# Exact actual drawn geometry, independent of the production cached fit.
	var rig: RefCounted=game.skater._visual_rig
	var board_front := -INF
	var shoe_front := -INF
	var board_vertices := 0
	var shoe_vertices := 0
	for mesh: MeshInstance3D in rig.board_contact_geometry().meshes:
		for point: Vector3 in mesh.mesh.get_faces():
			board_front=maxf(board_front,mesh.to_global(point).z)
			board_vertices+=1
	for leg: Dictionary in rig._legs:
		for mesh: MeshInstance3D in leg.foot.find_children("*","MeshInstance3D",true,false):
			for point: Vector3 in mesh.mesh.get_faces():
				shoe_front=maxf(shoe_front,mesh.to_global(point).z)
				shoe_vertices+=1
	return {"board_vertices":board_vertices,"shoe_vertices":shoe_vertices,
		"board_gap":wall_z-board_front,"shoe_gap":wall_z-shoe_front}
