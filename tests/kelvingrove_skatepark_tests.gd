extends RefCounted
## Native world/feature proof for the excavated facility. Declared initial
## contact fixtures are applied once; subsequent motion is never injected.
const Facility = preload("res://game/levels/kelvingrove_skatepark.gd")
const Native = preload("res://tests/transition_ride_tests.gd")
static var _observer := Callable()
static var _game: Node
static var _phase := ""
static var _step := 0
static var _throttle := ""

static func run(tree: SceneTree, game: Node, check: Callable, observer: Callable=Callable()) -> void:
	var spawn: Vector3 = game.skater.spawn_position
	var free: bool = game.free_skate_mode
	_observer = observer
	_game = game
	_step = 0
	game.start_mode(true)
	await _geometry(tree,game,check)
	await _open_port(tree,check)
	await _blocked_port_reorientation(tree,check)
	await _lower_carve(tree,check)
	await _beginner(tree,game,check)
	await _compact_hip(tree,game,check)
	_release()
	_phase = ""
	_observer = Callable()
	_game = null
	game.skater.spawn_position = spawn
	game.start_mode(free)

static func _park(game: Node) -> Node3D:
	return game.world.find_child("KelvingroveSunkenSkatepark",true,false)

static func _geometry(tree: SceneTree, game: Node, check: Callable) -> void:
	var park := _park(game)
	await _frames(tree,3)
	var floor_valid := true
	for pair: Array in [[Vector3(-197,11,-194),"DeepBowl"],[Vector3(-219,13,-195),"ShallowBowl"],
		[Vector3(-194,13,-174),"LowerStreetBasin"],[Vector3(-188.5,14.5,-182.5),"EastArrivalDeck"]]:
		var p: Vector3 = pair[0]
		var hit := _ray(game.skater,p+Vector3.UP*8,p-Vector3.UP*2,1)
		floor_valid = floor_valid and not hit.is_empty() and absf(Vector3(hit.position).y-p.y)<0.003 \
			and absf(park.get_surface_height(p+Vector3.UP)-p.y)<0.003
	check.call(floor_valid,"sunken park: deep11/shallow13/street13/rim14.5 native floors replace the real excavated hill")
	var upwards := true
	for label: String in ["ExcavatedUpperDeck","LowerStreetBasin","BeginnerArrivalBank","StepBypassBank"]:
		for child: Node in park.get_node(label).get_children():
			if not child is MeshInstance3D: continue
			var normals: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
			upwards = upwards and child.material_override.cull_mode==BaseMaterial3D.CULL_BACK
			for normal: Vector3 in normals: upwards = upwards and normal.y>0.90
	check.call(upwards,"sunken park: actual floor mesh normals face upward with normal backface culling")
	var compared := 0
	var max_error := 0.0
	var missing := 0
	for ix in 20:
		for iz in 15:
			var p := Vector3(-226.5+ix*2.0,25,-201.5+iz*2.0)
			var hit := _ray(game.skater,p,Vector3(p.x,9,p.z),1)
			var indexed: float = park.get_surface_height(p)
			if hit.is_empty() or is_nan(indexed):
				missing += 1
				continue
			compared += 1
			max_error = maxf(max_error,absf(indexed-Vector3(hit.position).y))
	check.call(compared>=290 and missing==0 and max_error<0.004,
		"sunken park: dense native floor rays and the shared mesh support index agree without pit caps or underside support")
	var actual_curve := true
	var ports := true
	var coping := true
	for name: String in ["DeepBowl","ShallowBowl"]:
		var bowl: Node3D = park.get_node(name)
		for phi: float in [0.1,1.1,4.8]:
			var s: Dictionary = bowl.sample(0.6,phi*bowl.floor_radius)
			var hit := _ray(game.skater,s.point+s.normal*0.1,s.point-s.normal*0.1,1)
			actual_curve = actual_curve and not hit.is_empty() and hit.collider==bowl.surface_body \
				and Vector3(hit.position).distance_to(s.point)<0.004 \
				and absf(bowl.get_parent().get_surface_height(s.point+Vector3.UP)-Vector3(hit.position).y)<0.004
		var absent: Dictionary = bowl.sample(1.1,PI*bowl.floor_radius)
		var gap_hit := _ray(game.skater,absent.point+absent.normal*0.1,absent.point-absent.normal*0.1,1)
		ports = ports and not bowl.surface_sample(absent.point).in_bounds \
			and (gap_hit.is_empty() or gap_hit.collider!=bowl.surface_body)
		for line in bowl.get_grind_lines():
			for fraction: float in [0.2,0.5,0.8]:
				var point: Vector3 = line.point_at(line.length*fraction)
				var hit := _ray(game.skater,point+Vector3.UP*0.12,point-Vector3.UP*0.12,2)
				coping = coping and not hit.is_empty() and hit.collider.get_meta("coping_feature",null)==bowl \
					and point.distance_to(hit.position)<0.004
	check.call(actual_curve,"sunken park: sampled curved walls have actual native collision and exact indexed support")
	check.call(ports,"sunken park: both entry ports are real missing wall sectors with no phantom transition acquisition")
	check.call(coping,"sunken park: both finite coping tracks lie on actual steel crowns and stop at the entry openings")
	check.call(park.get_node("DeepBowl").get_node_or_null("BowlAccessRollIn")==null \
		and park.get_node("ShallowBowl").get_node_or_null("BowlAccessRollIn")==null,
		"sunken park: standalone external bowl ramps are removed rather than buried beneath the facility")
	print("SUNKEN_GEOMETRY compared=%d missing=%d native_index_error=%.6f"%[compared,missing,max_error])

static func _native_fixture(tree: SceneTree) -> Dictionary:
	var root := Node3D.new()
	root.position = Vector3(600,30,600)
	tree.root.add_child(root)
	var park := Facility.new()
	root.add_child(park)
	var rider := Native.Rider.new()
	rider.collision_layer = 2
	rider.collision_mask = 1
	rider.floor_max_angle = deg_to_rad(56)
	rider.floor_snap_length = 0.45
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	collision.position.y = 0.85
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.7
	capsule.radius = 0.28
	collision.shape = capsule
	rider.add_child(collision)
	root.add_child(rider)
	await _frames(tree,3)
	return {"root":root,"park":park,"rider":rider,"bowl":park.get_node("DeepBowl")}

static func _open_port(tree: SceneTree, check: Callable) -> void:
	var fixture := await _native_fixture(tree)
	var bowl: Node3D = fixture.bowl
	var rider = fixture.rider
	var phi: float = PI-bowl.port_half_angle()-0.08
	var sample: Dictionary = bowl.sample(0.95,phi*bowl.floor_radius)
	rider.global_position = sample.point+sample.normal*0.022
	rider.velocity = sample.lateral*8.0
	rider.running = true
	var launched := false
	var departure := Vector3.ZERO
	var max_delta := 0.0
	var energy_gain := 0.0
	for frame in 30:
		var before: Vector3 = rider.global_position
		var before_energy: float = rider.velocity.length_squared()*0.5+22.0*(before.y-bowl.global_position.y)
		await _frames(tree,1)
		max_delta = maxf(max_delta,before.distance_to(rider.global_position))
		if rider.last_result.get("event","")=="launch":
			launched = true
			departure = rider.global_position
			energy_gain = rider.velocity.length_squared()*0.5+22.0*(rider.global_position.y-bowl.global_position.y)-before_energy
			break
	check.call(launched and rider.entries==1 and rider.launches==1 and rider.bails==0,
		"sunken park: actual finite upper-port departure emits one native launch instead of bailing or inventing another entry")
	check.call(launched and energy_gain<0.15 and rider.velocity.length()<8.2 and max_delta<0.20,
		"sunken park: open-port departure preserves tangent momentum with no impulse, energy boost or position jump")
	await _frames(tree,20)
	var floor_hit := _ray(rider,rider.global_position+Vector3.UP*0.15,rider.global_position-Vector3.UP*0.25,1)
	check.call(rider.launches==1 and rider.landings<=1 and rider.bails==0 and rider.global_position.distance_to(departure)>1.0 \
		and rider.ride.state=="idle" and rider.is_on_floor() and not floor_hit.is_empty() \
		and floor_hit.collider.name=="NativeGentlePort" \
		and rider.get_node("BodyCollision").transform.is_equal_approx(Transform3D(Basis.IDENTITY,Vector3(0,0.85,0))),
		"sunken park: the open port advances to actual bank support once and restores the upright capsule without phantom catches")
	print("SUNKEN_PORT launches=%d landings=%d bails=%d gain=%.6f max_step=%.6f departure_travel=%.5f state=%s floor=%s position=%s"%[
		rider.launches,rider.landings,rider.bails,energy_gain,max_delta,rider.global_position.distance_to(departure),rider.ride.state,rider.is_on_floor(),rider.global_position])
	await Native._dispose(tree,fixture.root)

static func _lower_carve(tree: SceneTree, check: Callable) -> void:
	var fixture := await _native_fixture(tree)
	var rider = fixture.rider
	var bowl: Node3D = fixture.bowl
	var sample: Dictionary = bowl.sample(0.6,0.0)
	var speed := sqrt(22.0*(bowl.floor_radius+bowl.radius*sin(0.6))*tan(0.6))
	rider.global_position = sample.point+sample.normal*0.022
	rider.velocity = sample.lateral*speed
	rider.running = true
	var sweep := 0.0
	var previous := 0.0
	var energy: float = speed*speed*0.5+22.0*(rider.global_position.y-bowl.global_position.y)
	var max_energy := energy
	for frame in 290:
		await _frames(tree,1)
		var local: Vector3 = bowl.to_local(rider.global_position)
		var phi := atan2(local.x,-local.z)
		sweep += angle_difference(previous,phi)
		previous = phi
		max_energy = maxf(max_energy,rider.velocity.length_squared()*0.5+22.0*(rider.global_position.y-bowl.global_position.y))
		if sweep>=TAU: break
	check.call(sweep>=TAU and rider.entries==1 and rider.launches==0 and rider.bails==0 and rider.ride.state=="surface",
		"sunken park: the genuine lower deep-bowl wall supports an entire native carve beneath its open upper port")
	check.call(max_energy<=energy+0.15 and rider.max_error<=0.045,
		"sunken park: deep-bowl carving retains existing strict native energy and bounded-contact limits")
	print("SUNKEN_CARVE sweep=%.5f entries=%d bail=%d energy_gain=%.6f"%[sweep,rider.entries,rider.bails,max_energy-energy])
	await Native._dispose(tree,fixture.root)

static func _blocked_port_reorientation(tree: SceneTree, check: Callable) -> void:
	# These actual solids leave room for the departing inclined capsule but
	# deliberately obstruct an upright stand-up at the lower bank contact.
	for ceiling: bool in [true,false]:
		var fixture := await _native_fixture(tree)
		var rider = fixture.rider
		var bowl: Node3D = fixture.bowl
		var blocker: StaticBody3D
		if ceiling:
			blocker = Native._box(Vector3(4,0.24,4),Vector3(612.3,29.42,599.3))
		else:
			blocker = Native._box(Vector3(0.24,2.0,0.68),Vector3(612.76,28.8,599.55))
		tree.root.add_child(blocker)
		await _frames(tree,2)
		var sample: Dictionary = bowl.sample(0.95,(PI-bowl.port_half_angle()-0.08)*bowl.floor_radius)
		rider.global_position = sample.point+sample.normal*0.022
		rider.velocity = sample.lateral*8.0
		rider.running = true
		for frame in 45:
			await _frames(tree,1)
			if rider.bails>0: break
		check.call(rider.bails==1 and rider.landings==0,
			"sunken park: upright port recovery cannot manufacture a safe landing through a real "+("ceiling" if ceiling else "side wall"))
		blocker.queue_free()
		await Native._dispose(tree,fixture.root)

static func _beginner(tree: SceneTree, game: Node, check: Callable) -> void:
	_release()
	game.skater.spawn_position = Vector3(-187.9,15.3,-182.5)
	game.restart_run()
	await _frames(tree,40)
	game.skater.rotation.y = atan2(1.0,-3.5)
	var park := _park(game)
	var points: PackedVector3Array = park.get_safety_routes()[0].points
	_phase = "sunken_park_geometry_beginner"
	var reached := true
	var distance := 0.0
	var camera_clear := true
	# Mutable evidence is used because GDScript lambda captures scalar values.
	var evidence := {"bails":0}
	var counted_bail := func(): evidence.bails+=1
	game.skater.bailed.connect(counted_bail)
	for point: Vector3 in points:
		var result := await _drive(tree,game,point)
		reached = reached and result.reached
		distance += result.distance
		camera_clear = camera_clear and result.camera
		if not result.reached: break
	_release()
	game.skater.bailed.disconnect(counted_bail)
	await _frames(tree,20)
	check.call(reached and evidence.bails==0 and not game.skater.airborne and not game.skater.bail_active and distance>20.0,
		"sunken park: ordinary mapped push/brake/steer enters the lower basin and returns through the gentle bank without a mandatory jump")
	check.call(camera_clear and game.score.total_score==0 and game.score.get_combo_value()==0,
		"sunken park: the real beginner circuit keeps the rider visible and cannot award manufactured surface tricks")
	print("SUNKEN_BEGINNER reached=%s distance=%.3f bails=%d position=%s score=%d"%[
		reached,distance,evidence.bails,game.skater.global_position,game.score.total_score])
	_phase = ""

static func _drive(tree: SceneTree, game: Node, target: Vector3) -> Dictionary:
	var distance := 0.0
	var camera := true
	for frame in 500:
		var delta: Vector3 = target-game.skater.global_position
		var planar := Vector2(delta.x,delta.z).length()
		if planar<0.65: return {"reached":true,"distance":distance,"camera":camera}
		if game.skater.bail_active: break
		var error := angle_difference(game.skater.rotation.y,atan2(-delta.x,-delta.z))
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if absf(error)>0.035: Input.action_press("steer_left" if error>0 else "steer_right",minf(1.0,absf(error)*2.0))
		var action := "brake" if absf(error)>0.55 or absf(game.skater.speed)>3.8 else "push"
		if _throttle!="" and _throttle!=action:
			Input.action_press("push")
			Input.action_press("brake")
		else:
			Input.action_release("brake" if action=="push" else "push")
			Input.action_press(action)
		_throttle = action
		var before: Vector3 = game.skater.global_position
		await _frames(tree,1)
		if not (_observer.is_valid() and not _phase.is_empty()):
			await tree.create_timer(0.0).timeout
		distance += before.distance_to(game.skater.global_position)
		var head: Vector3 = game.skater._visual_rig._head.global_position
		camera = camera and game.skater._camera.global_position.is_finite() and game.skater._camera.is_position_in_frustum(head) \
			and _ray(game.skater,game.skater._camera.global_position,head,9).is_empty()
	return {"reached":false,"distance":distance,"camera":camera}

static func _compact_hip(tree: SceneTree, game: Node, check: Callable) -> void:
	_release()
	game.skater.spawn_position = Vector3(-210.7,13.8,-176.5)
	game.restart_run()
	await _frames(tree,40)
	game.skater.rotation.y = PI*0.5
	var hip: Node3D = _park(game).get_node("ForegroundHip")
	var evidence := {"bails":0}
	var on_bail := func(): evidence.bails+=1
	game.skater.bailed.connect(on_bail)
	_phase = "sunken_park_geometry_compact_hip"
	Input.action_press("push")
	var launched := false
	var approach_released := false
	for frame in 180:
		await _frames(tree,1)
		if game.skater.bail_active: break
		if game.skater.transition_active and game.skater._transition.feature.get_parent()==hip \
			and game.skater._transition.state=="surface" and not approach_released:
			# The compact line's stated approach supplies its momentum. Coast
			# the transition instead of pumping extra speed into a short runout.
			Input.action_release("push")
			approach_released = true
		if game.skater.transition_active and game.skater._transition.state=="air" \
			and game.skater._transition.feature.get_parent()==hip:
			launched = true
			break
	check.call(launched and evidence.bails==0,
		"sunken park: compact hip reaches genuine native vert air from its declared eight-metre push approach")
	Input.action_release("push")
	await _frames(tree,4)
	if launched:
		Input.action_press("push")
		await _frames(tree,9)
		Input.action_release("push")
	var back := false
	var exited := false
	var stopped := false
	var maximum_exit := 0.0
	var minimum_x: float = game.skater.global_position.x
	var camera := true
	for frame in 200:
		await _frames(tree,1)
		if not (_observer.is_valid() and not _phase.is_empty()): await tree.create_timer(0.0).timeout
		if game.skater.bail_active: break
		if game.skater.transition_active and game.skater._transition.state=="surface" \
			and game.skater._transition.feature.name=="BackTransition":
			back = true
		if back and not game.skater.transition_active and game.skater.is_on_floor() and not game.skater.airborne:
			exited = true
			Input.action_press("brake")
			maximum_exit = maxf(maximum_exit,absf(game.skater.speed))
		minimum_x = minf(minimum_x,game.skater.global_position.x)
		var head: Vector3 = game.skater._visual_rig._head.global_position
		camera = camera and game.skater._camera.is_position_in_frustum(head) \
			and _ray(game.skater,game.skater._camera.global_position,head,9).is_empty()
		if exited and absf(game.skater.speed)<0.15:
			stopped = true
			break
	_release()
	game.skater.bailed.disconnect(on_bail)
	check.call(back and exited and stopped and evidence.bails==0,
		"sunken park: a fresh airborne direction transfers to the actual opposite hip face and brakes to a native stop")
	check.call(maximum_exit<=13.0 and minimum_x>=-226.8 and game.skater.global_position.x<-222.3,
		"sunken park: the compact hip's real transfer and braking fit its declared four-and-a-half-metre west runout")
	check.call(camera and game.score.total_score==0 and game.score.get_combo_value()==0,
		"sunken park: compact hip transfer keeps actual head visibility and manufactures no trick or bank")
	print("SUNKEN_COMPACT_HIP launched=%s back=%s exit=%s stop=%s bails=%d exit_speed=%.5f min_x=%.5f position=%s"%[
		launched,back,exited,stopped,evidence.bails,maximum_exit,minimum_x,game.skater.global_position])
	_phase = ""

static func _ray(rider: CharacterBody3D, start: Vector3, finish: Vector3, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start,finish,mask)
	query.exclude = [rider.get_rid()]
	return rider.get_world_3d().direct_space_state.intersect_ray(query)

static func _release() -> void:
	for action: String in InputMap.get_actions(): Input.action_release(action)
	_throttle = ""

static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
		_step += 1
		if _observer.is_valid() and not _phase.is_empty(): await _observer.call(_phase,_game,_step)
