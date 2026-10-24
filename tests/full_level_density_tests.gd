extends RefCounted
## Whole-map authored opportunity, native route clearance and real input lines.
const SurfaceChecks = preload("res://tests/surface_coverage_tests.gd")
const Ride = preload("res://game/tricks/grind_ride.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")


static func run(tree: SceneTree,game: Node,check: Callable) -> void:
	var world: Node3D = game.world
	var definitions: Array = world.get_skate_feature_definitions()
	var districts: Dictionary = {}
	var lines: Dictionary = {}
	for line in world.get_grind_lines(): lines[line.id] = line
	for feature: Dictionary in definitions:
		if feature.has("district"): districts[feature.district] = int(districts.get(feature.district,0))+1
		for id: String in feature.get("grind_ids",[]):
			var track = lines.get(id)
			var clear: bool = track != null and track.is_valid
			if clear:
				for fraction: float in [0.2,0.5,0.8]:
					var at: Vector3 = track.point_at(track.length*fraction)
					var tangent: Vector3 = track.dir_at(track.length*fraction)
					var velocity := Vector3(tangent.x,0,tangent.z).normalized()*6.0-Vector3.UP
					clear = clear and Ride.new().start([track],at+Vector3.UP*0.15,velocity,
						func(from: Vector3,to: Vector3) -> bool: return SurfaceChecks._clear_capture(world,from,to))
			check.call(clear,"full map: new visible ledge/rail has three actual capsule-clear contacts "+id)
		if feature.get("kind","") == "spine":
			for key: String in ["approach","landing"]:
				var points: PackedVector3Array = feature[key]
				var supported := points[0].distance_to(points[1]) >= 9.99
				for step in 11:
					var at := points[0].lerp(points[1],float(step)/10.0)
					var hit := world.get_world_3d().direct_space_state.intersect_ray(
						PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.2,at-Vector3.UP*0.4,1))
					supported = supported and not hit.is_empty() and absf(hit.position.y-at.y)<0.06 \
						and SurfaceChecks._clear_capture(world,at,at)
				check.call(supported,"full map: complete declared ten-metre spine "+key+" is supported and clear in the actual map")
	for district: String in ["royal_exchange","george_square","central_station","barras","clyde","kelvingrove"]:
		check.call(int(districts.get(district,0)) >= 2,"full map: district has multiple published connected skating features "+district)
	check.call(SurfaceChecks._clear_capture(world,Vector3(-62,2,22),Vector3(-82,2,34)) \
		and SurfaceChecks._clear_capture(world,Vector3(-82,2,34),Vector3(-62,2,22)),
		"full map: original career's south-concourse diagonal stays clear of the new halfpipe in both directions")
	for crossing: Vector3 in [Vector3(-180.904,0,-158.432),Vector3(-192.639,0,-109.843),Vector3(-150.909,0,-99.273)]:
		crossing.y = world.get_ground_height(crossing)
		check.call(SurfaceChecks._clear_capture(world,crossing,crossing),
			"full map: previously stalled park-edge crossing has matching support and clear native rider capsule "+str(crossing))
	var density: Dictionary = world.get_level_density_audit()
	var quay: Dictionary = density.explorable_spans.clyde_south_quay
	check.call(quay.samples>=42 and quay.within_15m==quay.samples and quay.max_distance_m<15.0,
		"full map: explorable south-quay width has useful intermediate skating within fifteen metres")
	var through_supported := true
	for route: Dictionary in world.get_route_definitions():
		if route.id!="clyde_south_east_west": continue
		var points: PackedVector3Array = route.points
		for segment in range(points.size()-1):
			through_supported = through_supported and SurfaceChecks._clear_capture(world,points[segment],points[segment+1]) \
				and SurfaceChecks._clear_capture(world,points[segment+1],points[segment])
			for sample in 14:
				var at := points[segment].lerp(points[segment+1],float(sample)/13)
				var hit := world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.2,at-Vector3.UP*0.4,1))
				through_supported = through_supported and not hit.is_empty() and absf(hit.position.y-at.y)<0.06
	check.call(through_supported,"full map: entire south-quay east-west through lane is supported and clear in both directions")
	for district: String in density.districts:
		var record: Dictionary = density.districts[district]
		print("DENSITY ",district," samples=",record.samples," within20=",record.within_20m," within35=",record.within_35m," max=",record.max_distance_m)
		check.call(record.samples >= 30 and float(record.within_35m)/record.samples >= 0.95 and record.max_distance_m < 40.0,
			"full map: bounded quiet travel along sampled supported routes "+district)
	await run_player(tree,game,check)


static func run_player(tree: SceneTree,game: Node,check: Callable,observer: Callable = Callable()) -> void:
	# These are genuine roll-on/off combo lines, not objects placed across the
	# old career circuit. Native input drives every metre after the restart.
	var definitions: Array = game.world.get_skate_feature_definitions()
	var original_spawn: Vector3 = game.skater.spawn_position
	var original_free: bool = game.free_skate_mode
	for feature: Dictionary in definitions:
		if feature.get("kind","") == "bank_manual_ledge_line":
			await _manual_crossing(tree,game,feature,check,observer)
	await _quay_through_crossing(tree,game,check,observer)
	await _quay_relay_capture(tree,game,check,observer)
	_release()
	game.skater.spawn_position = original_spawn
	game.start_mode(original_free)
	await _frames(tree,3)


static func _manual_crossing(tree: SceneTree,game: Node,feature: Dictionary,check: Callable,observer: Callable) -> void:
	_release()
	var points: PackedVector3Array = feature.line
	game.skater.spawn_position = points[0]+Vector3(-3,0.08,0)
	game.start_mode(true)
	game.skater.rotation.y = -PI*0.5
	await _frames(tree,30)
	if observer.is_valid(): await observer.call(feature.id,game,-1)
	var bails := [0]
	var on_bail := func():
		bails[0] += 1
		print("DENSITY BAIL ",feature.id," at=",game.skater.global_position," manual=",game.skater.manual_active," balance=",game.skater.manual_balance," air=",game.skater.airborne)
	game.skater.bailed.connect(on_bail)
	Input.action_press("push")
	var began := false
	var finished := false
	var manual_frames := 0
	var crossed_deck := false
	var reached := false
	var camera_clear := true
	for frame in 420:
		var at: Vector3 = game.skater.global_position
		if not began and at.x >= points[2].x+1.6:
			began = true
			Input.action_press("manual")
		if game.skater.manual_active:
			manual_frames += 1
			crossed_deck = crossed_deck or (at.x >= points[2].x and at.x <= points[3].x and absf(at.y-points[2].y)<0.12)
			Input.action_release("brake")
			Input.action_press("push",clampf(0.15+(game.skater.manual_balance-0.05)*2.0,0.0,0.4))
		else:
			Input.action_release("brake")
			Input.action_press("push")
		if began and not finished and at.x >= points[4].x+0.5:
			Input.action_release("manual")
			Input.action_release("brake")
			Input.action_press("push")
			finished = true
		if at.x >= points[5].x-0.2:
			reached = true
			break
		if frame%6==0: camera_clear = camera_clear and _camera_clear(game)
		if observer.is_valid(): await observer.call(feature.id,game,frame)
		await _frames(tree,1)
	_release()
	await _frames(tree,2)
	if game.skater.manual_active:
		# A buffered landing can latch the manual. Its documented fresh-button
		# toggle ends that link; brake is balance input until it has ended.
		Input.action_press("manual")
		await _frames(tree,1)
		Input.action_release("manual")
	await _frames(tree,45)
	var first_bank: int = game.score.total_score
	await _frames(tree,12)
	game.skater.bailed.disconnect(on_bail)
	print("DENSITY LINE ",feature.id," reached=",reached," manual_frames=",manual_frames," deck=",crossed_deck," bails=",bails[0]," camera=",camera_clear," score=",game.score.total_score," at=",game.skater.global_position)
	check.call(reached and crossed_deck and manual_frames >= 10 and bails[0] == 0 and camera_clear and first_bank > 0 and game.score.total_score == first_bank,
		"full map: actual push/manual crosses both banks and raised deck, then banks once "+feature.id)


static func _release() -> void:
	for action: String in ["push","brake","steer_left","steer_right","manual","ollie","grind","flip","grab"]: Input.action_release(action)


static func _quay_through_crossing(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	_release()
	game.skater.spawn_position = Vector3(-38,2.08,120)
	game.start_mode(true)
	game.skater.rotation.y = -PI*0.5
	await _frames(tree,30)
	var bails := [0]
	var on_bail := func(): bails[0] += 1
	game.skater.bailed.connect(on_bail)
	var distance := 0.0
	var supported := true
	var camera_clear := true
	var reached := false
	if observer.is_valid(): await observer.call("clyde_south_east_west",game,-1)
	var previous: Vector3 = game.skater.global_position
	Input.action_press("push")
	for step in 600:
		await _frames(tree,1)
		supported = supported and game.skater.is_on_floor() and absf(game.skater.global_position.y-2.0)<0.08
		if step%6==0: camera_clear = camera_clear and _camera_clear(game)
		if observer.is_valid(): await observer.call("clyde_south_east_west",game,step)
		# A render observer can await another real frame. Count that genuine
		# travel too, without changing position, speed or simulation time.
		distance += previous.distance_to(game.skater.global_position)
		previous = game.skater.global_position
		if game.skater.global_position.x>=34.8:
			reached = true
			break
	_release()
	game.skater.bailed.disconnect(on_bail)
	print("SOUTH QUAY CROSS reached=",reached," distance=",distance," supported=",supported," camera=",camera_clear," bails=",bails[0])
	check.call(reached and distance>=72.0 and supported and camera_clear and bails[0]==0 and game.score.total_score==0,
		"full map: native push crosses the complete new south-quay scene with support, clear chase and no invented score")


static func _quay_relay_capture(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	_release()
	game.skater.spawn_position = Vector3(9.25,2.66,126)
	game.start_mode(true)
	game.skater.rotation.y = -PI*0.5
	await _frames(tree,30)
	var bails := [0]
	var captures: Array[String] = []
	var on_bail := func(): bails[0] += 1
	var on_capture := func(id: String): captures.append(id)
	game.skater.bailed.connect(on_bail)
	game.skater.grind_captured.connect(on_capture)
	var camera_clear := true
	var held := 0
	var capture_frame := -1
	var frame := 0
	if observer.is_valid(): await observer.call("clyde_south_link_capture",game,-1)
	Input.action_press("push")
	for i in 120:
		await _frames(tree,1)
		if observer.is_valid(): await observer.call("clyde_south_link_capture",game,frame)
		frame += 1
		if game.skater.global_position.x>=14.0: break
	Input.action_press("ollie")
	await _frames(tree,2)
	Input.action_release("ollie")
	await _frames(tree,1)
	Input.action_release("push")
	Input.action_press("grind")
	for i in 150:
		await _frames(tree,1)
		if game.skater.grinding:
			if capture_frame<0: capture_frame = Engine.get_physics_frames()
			held = Engine.get_physics_frames()-capture_frame+1
		if frame%6==0: camera_clear = camera_clear and _camera_clear(game)
		if observer.is_valid(): await observer.call("clyde_south_link_capture",game,frame)
		frame += 1
		if held>=18: break
	Input.action_release("grind")
	await _frames(tree,90)
	_release()
	game.skater.bailed.disconnect(on_bail)
	game.skater.grind_captured.disconnect(on_capture)
	print("SOUTH QUAY RELAY captures=",captures," held=",held," score=",game.score.total_score," bails=",bails[0]," camera=",camera_clear," at=",game.skater.global_position)
	check.call(captures==["Grind_Rail_ClydeSouthRelay"] and held>=18 and game.score.total_score>100 and bails[0]==0 and camera_clear,
		"full map: native seat approach, real Ollie and descending flatbar capture form an earned south-quay relay")


static func _camera_clear(game: Node) -> bool:
	var camera: Camera3D = game.skater._camera
	if not camera.global_position.is_finite(): return false
	var rig: RefCounted = game.skater._visual_rig
	var markers := PackedVector3Array([rig._head.global_position,game.skater._board_visual.global_position])
	# Derive extremities from the actual rendered meshes, including the curved
	# deck nose/tail and head extent, rather than a guessed player-height box.
	for visible_mesh: MeshInstance3D in [rig._head.get_node("AnatomicalHead"),rig._board.get_node("CurvedMapleDeck")]:
		var bounds := visible_mesh.get_aabb()
		for corner in 8: markers.append(visible_mesh.to_global(bounds.get_endpoint(corner)))
	for leg: Dictionary in rig._legs:
		markers.append(leg.foot.to_global(Footwear.SOLE_CONTACT))
		markers.append(leg.foot.to_global(Footwear.TOE_CONTACT))
	var space: PhysicsDirectSpaceState3D = game.skater.get_world_3d().direct_space_state
	for marker: Vector3 in markers:
		if not marker.is_finite() or not camera.is_position_in_frustum(marker):
			print("DENSITY CAMERA FRUSTUM rider=",game.skater.global_position," camera=",camera.global_position," marker=",marker)
			return false
		var ray := PhysicsRayQueryParameters3D.create(camera.global_position,marker,1|8)
		ray.exclude = [game.skater.get_rid()]
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			print("DENSITY CAMERA OCCLUSION rider=",game.skater.global_position," camera=",camera.global_position," marker=",marker," hit=",hit.position," collider=",hit.collider.get_meta("art_label",str(hit.collider.name)))
			return false
	var sphere := SphereShape3D.new()
	sphere.radius = 0.25
	var volume := PhysicsShapeQueryParameters3D.new()
	volume.shape = sphere
	volume.transform = Transform3D(Basis.IDENTITY,camera.global_position)
	volume.collision_mask = 1|8
	volume.exclude = [game.skater.get_rid()]
	volume.margin = 0.015
	var contacts := space.intersect_shape(volume,1)
	if not contacts.is_empty(): print("DENSITY CAMERA VOLUME rider=",game.skater.global_position," camera=",camera.global_position," collider=",contacts[0].collider.get_meta("art_label",str(contacts[0].collider.name)))
	return contacts.is_empty()


static func _frames(tree: SceneTree,count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
