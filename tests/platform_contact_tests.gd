extends RefCounted
## Actual Main cart support. One native roof ray declares each initial supported
## pose; all carrying, acceleration, braking, jumping and landing then use input.
const Visual = preload("res://game/player/skater_visual.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const Anatomy = preload("res://game/player/skater_anatomy.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Quarter = preload("res://game/levels/transition_feature.gd")

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_spawn: Vector3 = game.skater.spawn_position
	await _passive_carry(tree,game,check)
	await _relative_controls(tree,game,check)
	await _platform_ollie(tree,game,check)
	await _moving_boneless(tree,game,check)
	await _cart_transition_camera(tree,game,check)
	await _restart_detaches_support(tree,game,check)
	_release()
	game.skater.spawn_position = original_spawn
	game.restart_run()

static func _passive_carry(tree: SceneTree, game: Node, check: Callable) -> void:
	var fixture := await _roof_fixture(tree,game)
	var cart = fixture.cart
	check.call(fixture.ready,"platform contact: real layer-eight cart roof accepts the native supported player pose")
	if not fixture.ready: return
	var initial: Vector3 = cart.to_local(game.skater.global_position)
	var cart_start: Vector3 = cart.global_position
	var largest_relative_speed := 0.0
	var largest_drift := 0.0
	var supported := true
	var camera_clear := true
	for i in 72:
		await _frames(tree,1)
		largest_relative_speed = maxf(largest_relative_speed,absf(game.skater.speed))
		largest_drift = maxf(largest_drift,cart.to_local(game.skater.global_position).distance_to(initial))
		supported = supported and game.skater.is_on_floor() and not game.skater.airborne and not cart.stopped
		camera_clear = camera_clear and _camera_clear(game)
	print("PLATFORM CARRY relative_speed=%.6f drift=%.6f cart_distance=%.3f"%[largest_relative_speed,largest_drift,cart.global_position.distance_to(cart_start)])
	check.call(supported and cart.global_position.distance_to(cart_start)>6.5,
		"platform contact: zero-input rider travels on the moving cart with continuous actual floor support")
	check.call(largest_relative_speed<0.15 and largest_drift<0.20,
		"platform contact: passive carrying cannot accumulate board speed or inject repeated platform momentum")
	check.call(camera_clear and _planar(game.skater.get_node("ChaseCamera").global_position-game.skater.global_position).dot(cart.travel_velocity.normalized())< -2.0,
		"platform contact: chase camera follows actual carried travel with a clear native view")
	game.toggle_pause()
	var player_at: Vector3 = game.skater.global_position
	var cart_at: Vector3 = cart.global_position
	await _frames(tree,10)
	check.call(game.skater.global_position==player_at and cart.global_position==cart_at,
		"platform contact: pausing freezes both the rider and its native moving support")
	game.toggle_pause()

static func _relative_controls(tree: SceneTree, game: Node, check: Callable) -> void:
	var fixture := await _roof_fixture(tree,game)
	var cart = fixture.cart
	check.call(fixture.ready,"platform contact: push/brake fixture starts on actual moving roof support")
	if not fixture.ready: return
	var initial: Vector3 = cart.to_local(game.skater.global_position)
	Input.action_press("push")
	await _frames(tree,12)
	Input.action_release("push")
	var relative_speed: float = game.skater.speed
	var distance: float = _planar(cart.to_local(game.skater.global_position)-initial).length()
	check.call(game.skater.is_on_floor() and relative_speed>1.7 and relative_speed<2.2 and distance>0.12 and distance<0.35,
		"platform contact: pushing adds controlled board motion relative to the cart rather than adding its speed again")
	Input.action_press("brake")
	await _frames(tree,8)
	Input.action_release("brake")
	var stop_at: Vector3 = cart.to_local(game.skater.global_position)
	await _frames(tree,20)
	check.call(game.skater.is_on_floor() and not game.skater.airborne and absf(game.skater.speed)<0.15
		and _planar(cart.to_local(game.skater.global_position)-stop_at).length()<0.10,
		"platform contact: braking stops relative skating while native platform carrying continues")
	check.call(not cart.stopped and _camera_clear(game),
		"platform contact: an ordinarily standing roof rider does not obstruct or stop the service cart")

static func _platform_ollie(tree: SceneTree, game: Node, check: Callable) -> void:
	var fixture := await _roof_fixture(tree,game)
	var cart = fixture.cart
	check.call(fixture.ready,"platform contact: ollie fixture starts on real native moving support")
	if not fixture.ready: return
	var evidence := {"bails":0,"landings":[]}
	var on_bail := func(): evidence.bails+=1
	var on_land := func(clean: bool): evidence.landings.append(clean)
	game.skater.bailed.connect(on_bail)
	game.skater.landed.connect(on_land)
	Input.action_press("ollie")
	await _frames(tree,2)
	Input.action_release("ollie")
	await _frames(tree,1)
	var outgoing: Vector3 = game.skater.velocity
	var takeoff: Vector3 = game.skater.global_position
	var platform: Vector3 = cart.travel_velocity
	check.call(game.skater.airborne and outgoing.y>8.0 and outgoing.y<9.3
		and _planar(outgoing).dot(platform.normalized())>platform.length()-0.15
		and _planar(outgoing).length()<platform.length()+1.0,
		"platform contact: roof ollie adds one platform carry velocity to the actual upward pop")
	await _frames(tree,1)
	check.call(absf((outgoing.y-game.skater.velocity.y)-22.0/60.0)<0.005
		and _planar(game.skater.velocity-outgoing).length()<0.005,
		"platform contact: first free frame preserves carried horizontal momentum and applies gravity exactly once")
	await _frames(tree,11)
	check.call(_planar(game.skater.velocity-outgoing).length()<0.01
		and _planar(game.skater.global_position-takeoff-outgoing*0.2).length()<0.03,
		"platform contact: ongoing air displacement retains one carry velocity without compounding it")
	for i in 100:
		await _frames(tree,1)
		if not game.skater.airborne or evidence.bails>0: break
	check.call(evidence.bails==0 and evidence.landings==[true] and game.skater.is_on_floor()
		and game.skater.global_position.y>cart.global_position.y+1.40,
		"platform contact: a carried ollie returns to the moving roof through one clean native landing")
	print("PLATFORM LAND relative_speed=%.6f local=%s velocity=%s platform=%s"%[game.skater.speed,cart.to_local(game.skater.global_position),game.skater.velocity,game.skater.get_platform_velocity()])
	await _frames(tree,25)
	print("PLATFORM AFTER LAND relative_speed=%.6f local=%s score=%d combo=%d"%[game.skater.speed,cart.to_local(game.skater.global_position),game.score.total_score,game.score.get_combo_value()])
	check.call(game.score.total_score==100 and game.score.get_combo_value()==0 and absf(game.skater.speed)<0.4,
		"platform contact: landing banks the ollie once and returns to bounded relative board speed")
	check.call(_camera_clear(game),"platform contact: native camera remains clear through roof takeoff and return")
	game.skater.bailed.disconnect(on_bail)
	game.skater.landed.disconnect(on_land)

static func _roof_fixture(tree: SceneTree, game: Node) -> Dictionary:
	_release()
	if game.paused: game.toggle_pause()
	game.skater.spawn_position = Vector3(-22,0.8,28)
	game.restart_run()
	await _frames(tree,120)
	var cart = game.feature_hub.vehicle
	# The compound cart has a cab roof and a lower bed. Aim at the visible cab
	# centre; the native layer-eight ray still supplies the exact contact height.
	var cab: Node3D = cart.get_node("Cab")
	var query := PhysicsRayQueryParameters3D.create(cab.global_position+Vector3.UP*2.0,cab.global_position-Vector3.UP,8)
	query.exclude = [game.skater.get_rid()]
	var hit: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider!=cart or hit.normal.y<0.99:
		return {"cart":cart,"ready":false}
	# The only declared placement: roof contact comes from the actual layer8
	# collision, rather than a guessed visual height or a per-frame follower.
	game.skater.spawn_position = hit.position+Vector3.UP*0.035
	game.skater.reset_skater()
	game.skater.rotation.y = cart.rotation.y
	await _frames(tree,12)
	return {"cart":cart,"ready":game.skater.is_on_floor() and not game.skater.airborne and not cart.stopped
		and absf(game.skater.get_platform_velocity().length()-cart.travel_velocity.length())<0.2}

static func _restart_detaches_support(tree: SceneTree, game: Node, check: Callable) -> void:
	var fixture := await _roof_fixture(tree,game)
	check.call(fixture.ready,"platform contact: restart fixture begins with native moving-cart contact")
	if not fixture.ready: return
	game.skater.spawn_position = Vector3(-22,0.8,28)
	game.restart_run()
	var fresh_spawn: Vector3 = game.skater.global_position
	await _frames(tree,1)
	check.call(_planar(game.skater.global_position-fresh_spawn).length()<0.01
		and _planar(game.skater.velocity).length()<0.05,
		"platform contact: restart discards native platform carry and leave momentum on its first frame")
	await _frames(tree,30)
	check.call(game.skater.is_on_floor() and not game.skater.airborne
		and _planar(game.skater.global_position-fresh_spawn).length()<0.05 and _camera_clear(game),
		"platform contact: restarted skater settles on ordinary ground without drifting from old moving support")

static func _moving_boneless(tree: SceneTree, game: Node, check: Callable) -> void:
	var fixture := await _roof_fixture(tree,game)
	var cart = fixture.cart
	if not fixture.ready:
		check.call(false,"platform contact: moving Boneless requires actual native roof support")
		return
	Input.action_press("brake")
	Input.action_press("ollie")
	await _frames(tree,2)
	Input.action_release("ollie")
	await _frames(tree,1)
	var first_anchor: Vector3 = cart.to_local(game.skater._setup.ground_point)
	await _frames(tree,7)
	var anchor: Vector3 = game.skater._setup.ground_point
	var query := PhysicsRayQueryParameters3D.create(anchor+Vector3.UP*0.08,anchor-Vector3.UP*0.08,8)
	query.exclude = [game.skater.get_rid()]
	var hit: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(query)
	check.call(game.skater.setup_active and game.skater.setup_id=="boneless" and game.skater.is_on_floor()
		and not hit.is_empty() and hit.collider==cart and cart.to_local(anchor).distance_to(first_anchor)<0.025,
		"platform contact: Boneless preparation keeps its planted ground anchor on the real moving cart")
	var sole: Node3D = game.skater.get_node("SkaterVisual/Rider/FrontFoot")
	var palm: Node3D = game.skater.get_node("SkaterVisual/Rider/RightAnatomicalHand")
	var board: Node3D = game.skater.get_node("SkaterVisual/Board")
	check.call(sole.to_global(Footwear.SOLE_CONTACT).distance_to(anchor)<0.005
		and palm.to_global(Anatomy.PALM_CONTACT).distance_to(board.to_global(Visual.boneless_grab_target()))<0.012,
		"platform contact: supported Boneless sole and gripping palm meet their actual roof and deck targets")
	Input.action_release("brake")
	var platform_before_pop := Vector3.ZERO
	var before_pop := Vector3.ZERO
	for i in 20:
		platform_before_pop = cart.get_real_velocity()
		before_pop = game.skater.global_position
		await _frames(tree,1)
		if game.skater.airborne: break
	print("PLATFORM BONELESS airborne=%s setup=%s velocity=%s platform_before=%s history=%s delta=%s expected=%s"%[game.skater.airborne,game.skater.setup_active,game.skater.velocity,platform_before_pop,game.score.trick_history,game.skater.global_position-before_pop,game.skater.velocity/60.0])
	var declared_pop: float = game.skater.OLLIE_SPEED*float(Catalog.definition("boneless").launch_speed_scale)
	check.call(game.skater.airborne and not game.skater.setup_active
		and game.score.trick_history.count("Boneless")==1 and absf(game.skater.velocity.y-declared_pop-platform_before_pop.y)<0.02
		and absf(_planar(game.skater.velocity).length()-cart.travel_velocity.length())<0.15
		# Native recovery can consume the configured margin before leaving a
		# floor, while leave momentum is added after that one translated move.
		and (game.skater.global_position-before_pop).distance_to(game.skater.velocity/60.0)<game.skater.safe_margin+0.002,
		"platform contact: completed moving Boneless produces one pop with one retained cart velocity")

static func _cart_transition_camera(tree: SceneTree, game: Node, check: Callable) -> void:
	var fixture := await _roof_fixture(tree,game)
	if not fixture.ready:
		check.call(false,"platform camera: rollback regression requires actual native cart roof support")
		return
	Input.action_press("push")
	await _frames(tree,8)
	Input.action_release("push")
	# One declared piece of real finite fixture geometry adjoins the cart roof.
	# Every approach, acquisition and rollback thereafter uses production input,
	# actual contact and native capsule motion; no support fields are assigned.
	var ramp := Quarter.new()
	ramp.name = "PlatformCameraQuarterFixture"
	ramp.feature_id = "platform_camera_quarter"
	ramp.build_access = false
	ramp.deck_length = 0.0
	ramp.rotation.y = game.skater.rotation.y
	ramp.position = game.skater.global_position-Vector3.UP*0.015-game.skater.global_basis.z*0.10
	tree.root.add_child(ramp)
	var stale_cache_observed := false
	var camera_opposes_travel := false
	for i in 100:
		await _frames(tree,1)
		if not game.skater.transition_active: continue
		var actual: Vector3 = _planar(game.skater.velocity)
		var retained: Vector3 = _planar(game.skater.get_real_velocity())
		if actual.length()>0.8 and retained.length()>0.8 and actual.normalized().dot(retained.normalized())< -0.9:
			stale_cache_observed = game.skater.is_on_floor() and game.skater.get_platform_velocity().length_squared()>0.01
			# process_frame is emitted before node _process callbacks. Let the
			# real chase update finish before inspecting this threshold frame.
			await tree.create_timer(0.0).timeout
			var rear: Vector3 = game.skater._camera_follow._travel_rear
			camera_opposes_travel = rear.dot(actual.normalized())< -0.99 and _camera_clear(game)
			print("PLATFORM CAMERA actual=%s retained=%s native_platform=%s rear=%s"%[actual,retained,game.skater.get_platform_velocity(),rear])
			break
	check.call(stale_cache_observed,
		"platform camera: native cart-to-quarter rollback reproduces retained floor and platform cache")
	check.call(stale_cache_observed and camera_opposes_travel,
		"platform camera: curved rollback follows actual travel despite opposite stale platform velocity")
	game.restart_run()
	ramp.queue_free()
	await tree.process_frame

static func _camera_clear(game: Node) -> bool:
	var camera: Camera3D = game.skater.get_node("ChaseCamera")
	if not camera.global_position.is_finite(): return false
	var chest: Vector3 = game.skater.global_position+Vector3.UP*1.05
	var query := PhysicsRayQueryParameters3D.create(camera.global_position,chest,1|8)
	query.exclude = [game.skater.get_rid()]
	return game.skater.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

static func _planar(vector: Vector3) -> Vector3:
	return Vector3(vector.x,0,vector.z)

static func _release() -> void:
	for action: String in ["push","brake","steer_left","steer_right","ollie","grind","flip","grab","manual","revert","spin_left","spin_right","interact"]:
		Input.action_release(action)

static func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
