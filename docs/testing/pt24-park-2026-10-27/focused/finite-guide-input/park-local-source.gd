extends RefCounted
## Independent fixed-footprint contracts and a production-input park descent.
## No actor corrections after the declared starting pose, or direct score calls.
const Routes = preload("res://tests/world_routes_tests.gd")
const Density = preload("res://tests/full_level_density_tests.gd")
const Finish = preload("res://tests/pt24_boundary_tests.gd")


static func run(tree: SceneTree,game: Node,check: Callable) -> void:
	await _frames(tree,2)
	var world: Node3D = game.world
	check.call(world.get_meta("pt24_park_runs_composed",false),"L06 park: existing seats are composed before world snapshots")
	var tracks: Dictionary = {}
	for line in world.get_grind_lines(): tracks[line.id]=line
	for id: String in ["park_east_lower","park_east_gateway"]:
		var body: StaticBody3D = world.get_node(id)
		var top: PackedVector3Array = body.get_meta("top_polygon_local")
		var north := body.to_global((top[0]+top[1])*0.5)
		var south := body.to_global((top[2]+top[3])*0.5)
		var z := -136.0 if id=="park_east_lower" else -112.0
		check.call(north.x> -150 and north.x< -146 and south.x> -150 and south.x< -146
			and absf((north.z+south.z)*0.5-z)<0.2 and absf(Vector2(south.x-north.x,south.z-north.z).length()-8)<0.001,
			"L06 park: fixed west-shoulder eight-metre footprint "+id)
		var bearing := Vector2(south.x-north.x,south.z-north.z).normalized()
		print("PT24_PARK_SEAT ",id," north=",north," south=",south)
		check.call(bearing.dot(Vector2.DOWN)>0.98 and (south.y<north.y-0.5 if id=="park_east_lower" else absf(south.y-north.y)<0.001),
			"L06 park: catch and release follow the real downhill/flat road heading "+id)
		var physical := true
		var endcaps := true
		var native_vertices := true
		var native_vertex_error := 0.0
		var display_vertex_error := 0.0
		var query_vertex_error := 0.0
		var hull: PackedVector3Array = body.get_child(0).shape.points
		var drawn_vertices: PackedVector3Array = body.get_child(1).mesh.get_faces()
		for corner: Vector3 in top:
			var native_match := false
			var display_match := false
			var native_gap := INF
			var display_gap := INF
			for point: Vector3 in hull:
				native_match=native_match or point==corner
				native_gap=minf(native_gap,point.distance_to(corner))
			for point: Vector3 in drawn_vertices:
				display_match=display_match or point==corner
				display_gap=minf(display_gap,point.distance_to(corner))
			var at := body.to_global(corner)
			var query_gap := absf(world.get_ground_height(at)-at.y)
			native_vertex_error=maxf(native_vertex_error,native_gap)
			display_vertex_error=maxf(display_vertex_error,display_gap)
			query_vertex_error=maxf(query_vertex_error,query_gap)
			if native_gap>=0.001 or display_gap>=0.001 or query_gap>=0.001:
				print("PT24_PARK_VERTEX ",id," local=",corner," native_gap_m=",native_gap," display_gap_m=",display_gap,
					" query=",world.get_ground_height(at)," expected=",at.y)
			native_vertices=native_vertices and native_gap<0.001 and display_gap<0.001 and query_gap<0.001
		check.call(native_vertices,"L06 park: all four top vertices agree within1mm between existing convex hull, display and height query "+id)
		print("PT24_PARK_VERTEX_ERROR ",id," native_m=",native_vertex_error," display_m=",display_vertex_error," query_m=",query_vertex_error)
		var guide = tracks.get("Grind_Ledge_"+id)
		physical=physical and guide!=null
		if guide!=null:
			print("PT24_PARK_GUIDE ",id," verified=",guide.contact_verified," points=",guide.points)
			if id=="park_east_lower":
				check.call(guide.points.size()==2 and not guide.is_loop
					and guide.points[0].distance_to(Vector3(-147.3186,9.797273,-140.0116))<.001
					and guide.points[1].distance_to(Vector3(-147.3583,7.461024,-132.0117))<.001,
					"L06 park: same-ID finite downhill guide publishes the real inboard long edge without a transverse masking cap")
				var true_contact: bool= guide.contact_verified and guide.contact_source=="glasgow.lowered_cylinder_envelope"
				var contact_error := 0.0
				for sample: int in 9:
					var distance: float=guide.length*(float(sample)+.5)/9.0
					var point: Vector3=guide.contact_at(distance)
					var up: Vector3=guide.contact_up(distance)
					var native: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(
						PhysicsRayQueryParameters3D.create(point+up*.08,point-up*.08,2))
					var error: float=INF if native.is_empty() else native.position.distance_to(point)
					contact_error=maxf(contact_error,error)
					true_contact=true_contact and error<.001 and native.get("collider")==world.get_node("Grind_Ledge_"+id+"/NativeGrindBearing")
				check.call(true_contact,"L06 park: nine independent normal rays verify the straight-grade radial datum against the retained native bearing")
				print("PT24_PARK_LONG_EDGE_NATIVE max_error_m=",contact_error)
			for segment: int in guide.points.size()-1:
				var at: Vector3 = guide.points[segment].lerp(guide.points[segment+1],0.5)
				var contact := world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.08,at-Vector3.UP*0.08,2))
				var bearing_ok := not contact.is_empty() and absf(contact.position.y-at.y)<0.004
				if not bearing_ok: print("PT24_PARK_BEARING_FAIL ",id," at=",at," hit=",contact)
				physical=physical and bearing_ok
		for step: int in 9:
			for side: float in [-0.42,0,0.42]:
				# One regular cell-centre sample in each longitudinal ninth.
				# Exact convex endpoint classification is separate: shared top
				# vertices above and transverse physical end-plane rays below.
				var along := (float(step)+0.5)/9.0
				var point := north.lerp(south,along)+Vector3(bearing.y,0,-bearing.x)*side
				var hit := world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.08,point-Vector3.UP*0.08,1))
				var drawn := Finish._visible_segment(body,point+Vector3.UP*0.08,point-Vector3.UP*0.08)
				var point_ok: bool = not hit.is_empty() and hit.collider==body and absf(hit.position.y-point.y)<0.001 \
					and absf(world.get_ground_height(point)-point.y)<0.001 and drawn
				if not point_ok: print("PT24_PARK_SEAT_FAIL ",id," at=",point," query=",world.get_ground_height(point)," drawn=",drawn," native=",hit)
				physical=physical and point_ok
		check.call(physical,"L06 park:27 fixed native/visible/query samples agree on reused graded seat "+id)
		var end_error := 0.0
		for endpoint: int in 2:
			var center := (north if endpoint==0 else south)-Vector3.UP*0.1
			var outward := Vector3(-bearing.x,0,-bearing.y) if endpoint==0 else Vector3(bearing.x,0,bearing.y)
			for side: float in [-0.42,0,0.42]:
				var point := center+Vector3(bearing.y,0,-bearing.x)*side
				var first := point+outward*0.08
				var last := point-outward*0.08
				var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(first,last,1))
				if not hit.is_empty(): end_error=maxf(end_error,hit.position.distance_to(point))
				endcaps=endcaps and not hit.is_empty() and hit.collider==body and hit.position.distance_to(point)<0.001 \
					and Finish._visible_segment(body,first,last)
		check.call(endcaps,"L06 park: six independent transverse native/visible endcap rays close both reused seat ends "+id)
		print("PT24_PARK_ENDCAP ",id," native_plane_max_error_m=",end_error)
		check.call(body.get_child_count()==2 and body.get_child(1).mesh.get_faces().size()==36
			and world.get_node("Grind_Ledge_"+id).get_node("NativeGrindBearing").get_child_count()==4
			and body.get_child(1).mesh.get_surface_count()==1
			and body.get_child(1).material_override==world._materials["cut_stone"]
			and world.get_node("Grind_Ledge_"+id).get_child(1).multimesh.instance_count==4
			and world.get_node("Grind_Ledge_"+id).get_child(1).material_override==world._materials["cut_stone"],
			"L06 park: existing12-triangle seat and four native bearings retain their resource counts "+id)
	var corridor := true
	var at_count := 0
	for z: float in [-148,-144,-140,-136,-132,-128,-124,-120,-116,-112,-108,-104]:
		for x: float in [-145.8,-144.6,-143.4]:
			var at := Vector3(x,0,z)
			at.y=world.get_ground_height(at)
			corridor=corridor and is_finite(at.y) and Routes._ground_below(world,at) and Routes._clear_standing(world,at)
			at_count+=1
	check.call(corridor,"L06 park:36 independently fixed centre/east bypass supports remain capsule-clear")
	await _descent(tree,game,check)
	await _transit(tree,game,check)
	print("PT24_PARK_RUN_GEOMETRY fixed_bypass=",at_count," reused_seats=2 added_triangles=0 added_draws=0")


static func _descent(tree: SceneTree,game: Node,check: Callable) -> void:
	var previous_spawn: Vector3 = game.skater.spawn_position
	var previous_mode: bool = game.free_skate_mode
	_release()
	var spawn := Vector3(-147.34,0,-148)
	spawn.y=game.world.get_ground_height(spawn)+0.04
	game.skater.spawn_position=spawn
	game.start_mode(true)
	game.skater.rotation.y=PI
	await _frames(tree,8)
	var captures: Array[String] = []
	var tricks: Array[String] = []
	var bails := [0]
	var on_capture := func(id: String) -> void: captures.append(id)
	var on_trick := func(label: String,_points: int) -> void: tricks.append(label)
	var on_bail := func() -> void: bails[0]+=1
	game.skater.grind_captured.connect(on_capture)
	game.skater.trick_performed.connect(on_trick)
	game.skater.bailed.connect(on_bail)
	var camera_clear := true
	var grind_frames := 0
	var manual_frames := 0
	var bank_count := 0
	var total := 0
	var launched := false
	var first_pop_done := false
	var exit_pop_requested := false
	var exit_pop_released := false
	var manual_requested := false
	var grind_released := false
	var last_value := 0
	var manual_begin := Vector3.INF
	var manual_end := Vector3.INF
	var catch_visible := false
	var choice_visible := false
	var minimum_gap := INF
	var nearest_contact: Dictionary = {}
	var target_line: Variant
	for line in game.world.get_grind_lines():
		if line.id=="Grind_Ledge_park_east_lower": target_line=line
	Input.action_press("push",0.5)
	for frame: int in 660:
		await _frames(tree,1)
		var at: Vector3 = game.skater.global_position
		if target_line!=null and game.skater.airborne and not game.skater.grinding and game.skater.velocity.y<=1:
			var near: Dictionary = target_line.closest(at)
			if near.gap<minimum_gap:
				minimum_gap=near.gap
				nearest_contact={"rider":at,"guide":near.point,"velocity":game.skater.velocity,"gap":near.gap,"held":Input.is_action_pressed("grind")}
		if not launched and at.z>= -143.7:
			catch_visible=_visible_choice(game,game.world.get_node("park_east_lower"),Vector3(-144.5,0,-136))
			Input.action_press("ollie")
			launched=true
		elif launched and not first_pop_done and Input.is_action_pressed("ollie"):
			Input.action_release("ollie")
			Input.action_release("push")
			Input.action_press("grind")
			first_pop_done=true
		if game.skater.grinding:
			grind_frames+=1
			if not exit_pop_requested: _balance(game.skater.grind_balance)
		if exit_pop_requested and not exit_pop_released:
			Input.action_release("ollie")
			exit_pop_released=true
		if grind_frames>0 and at.z>= -135.3 and not exit_pop_requested:
			Input.action_press("ollie")
			_balance(0)
			Input.action_press("steer_left",0.6)
			exit_pop_requested=true
		if exit_pop_released and not game.skater.grinding and not grind_released:
			Input.action_release("grind")
			_balance(0)
			grind_released=true
		if grind_released and not game.skater.grinding and not game.skater.airborne and not manual_requested:
			Input.action_press("manual")
			manual_requested=true
		if game.skater.manual_active:
			if manual_frames==0: manual_begin=at
			manual_frames+=1
			_balance(game.skater.manual_balance)
			if at.z>= -120:
				choice_visible=_visible_choice(game,game.world.get_node("park_east_gateway"),Vector3(-144.5,0,-112))
				manual_end=at
				last_value=game.score.get_combo_value()
				Input.action_release("manual")
				_balance(0)
				Input.action_press("brake")
		if frame%8==0: camera_clear=camera_clear and Density._camera_clear(game)
		if game.score.total_score>total:
			bank_count+=1
			total=game.score.total_score
		if bails[0]>0 or (bank_count>0 and frame>120): break
	_release()
	Input.action_press("brake")
	await _frames(tree,40)
	_release()
	var banked: int = game.score.total_score
	await _frames(tree,24)
	check.call(captures==["Grind_Ledge_park_east_lower"] and grind_frames>=18 and bails[0]==0,
		"L06 park: native downhill Push/Ollie captures and rides the reused path-side seat without a bail")
	check.call(manual_frames>=45 and manual_begin.is_finite() and manual_end.is_finite()
		and manual_end.z-manual_begin.z>=6 and manual_end.z>= -120 and bails[0]==0,
		"L06 park: real landing/manual carries the same descent across the flattening into the next-feature choice")
	check.call(bank_count==1 and last_value>200 and banked==last_value and game.score.last_banked==last_value
		and game.score.total_score==banked and game.score.last_banked_tricks.has("Manual"),
		"L06 park: the earned grind/manual combo banks its exact pending value once and remains unchanged")
	check.call(camera_clear,"L06 park: complete rider/board and chase-camera volume remain clear throughout the actual descent")
	check.call(catch_visible and choice_visible,"L06 park: ordinary chase shows both the catch and the next seat/clear through-lane choice before commitment")
	print("PT24_PARK_DESCENT captures=",captures," grind_frames=",grind_frames," manual_frames=",manual_frames,
		" manual_begin=",manual_begin," manual_end=",manual_end," banks=",bank_count," pending=",last_value,
		" banked=",banked," bails=",bails[0]," camera=",camera_clear," catch_visible=",catch_visible," choice_visible=",choice_visible," at=",game.skater.global_position," tricks=",tricks)
	print("PT24_PARK_CLOSEST descending=",nearest_contact)
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.bailed.disconnect(on_bail)
	game.skater.spawn_position=previous_spawn
	game.start_mode(previous_mode)


static func _transit(tree: SceneTree,game: Node,check: Callable) -> void:
	var previous_spawn: Vector3 = game.skater.spawn_position
	var previous_mode: bool = game.free_skate_mode
	for direction: int in [-1,1]:
		_release()
		var at := Vector3(-144.6,0,-146 if direction==1 else -107)
		at.y=game.world.get_ground_height(at)+0.04
		game.skater.spawn_position=at
		game.start_mode(true)
		game.skater.rotation.y=PI if direction==1 else 0.0
		await _frames(tree,8)
		var bails := [0]
		var on_bail := func() -> void: bails[0]+=1
		game.skater.bailed.connect(on_bail)
		Input.action_press("push")
		var reached := false
		var supported := true
		for frame: int in 540:
			await _frames(tree,1)
			var point: Vector3 = game.skater.global_position
			supported=supported and not game.skater.airborne
			reached=point.z>= -107 if direction==1 else point.z<= -146
			if reached or bails[0]>0: break
		_release()
		check.call(reached and supported and bails[0]==0,"L06 park: ordinary no-jump "+("downhill" if direction==1 else "uphill")+" bypass travels past both seats")
		print("PT24_PARK_TRANSIT direction=",direction," reached=",reached," supported=",supported," bails=",bails[0]," at=",game.skater.global_position)
		game.skater.bailed.disconnect(on_bail)
	game.skater.spawn_position=previous_spawn
	game.start_mode(previous_mode)


static func _balance(value: float) -> void:
	var amount := clampf(-0.14-value*0.85,-0.6,0.6) if absf(value)>0.001 else 0.0
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if amount<0: Input.action_press("steer_left",-amount)
	elif amount>0: Input.action_press("steer_right",amount)


static func _visible_choice(game: Node,body: Node3D,through: Vector3) -> bool:
	var top: PackedVector3Array = body.get_meta("top_polygon_local")
	var center := Vector3.ZERO
	for point: Vector3 in top: center+=body.to_global(point)/4
	through.y=game.world.get_ground_height(through)+0.4
	var camera: Camera3D = game.skater._camera
	for target: Vector3 in [center+Vector3.UP*0.3,through]:
		if not camera.is_position_in_frustum(target): return false
		var query := PhysicsRayQueryParameters3D.create(camera.global_position,target,1|8)
		query.exclude=[game.skater.get_rid()]
		if not game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
	return true


static func _frames(tree: SceneTree,count: int) -> void:
	for frame: int in count:
		await tree.physics_frame
		await tree.create_timer(0.0,false,false).timeout


static func _release() -> void:
	for action: String in ["push","brake","manual","ollie","grind","steer_left","steer_right","spin_left","spin_right"]:
		Input.action_release(action)
