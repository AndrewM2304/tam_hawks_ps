extends RefCounted
## Actual Main/world edge rides. Each trial declares a supported initial fixture;
## mapped keys alone then accelerate, crouch, pop, seek, ride and drop.
const MainScene = preload("res://game/main.tscn")
const Setup = preload("res://game/core/input_setup.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")


static func probe_idle_support(tree: SceneTree) -> void:
	# Standalone diagnostic entry, deliberately separate from the acceptance
	# trials: retain the same even-tick fixture and inspect subsequent real ticks.
	Setup.register_actions()
	_release()
	var game: Node=MainScene.instantiate()
	game.persistence_enabled=false
	tree.root.add_child(game)
	game.skater.spawn_position=Vector3(-31.28,0.8,11.15)
	game.start_mode(true)
	game.skater.rotation.y=-PI*0.5
	game.skater.reset_physics_interpolation()
	await _ticks(tree,40)
	for offset: int in range(11):
		if offset>0: await _ticks(tree,1)
		print("EDGE_IDLE_PROBE offset=",offset," ",JSON.stringify(_support_snapshot(game.skater)))
	_release()
	game.free()
	tree.paused=false
	await tree.process_frame


static func _support_snapshot(rider: CharacterBody3D) -> Dictionary:
	var body: CollisionShape3D=rider.get_node("BodyCollision")
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=body.shape
	query.transform=body.global_transform
	query.collision_mask=1
	query.exclude=[rider.get_rid()]
	query.margin=0.001
	var overlaps: Array[String]=[]
	for hit: Dictionary in rider.get_world_3d().direct_space_state.intersect_shape(query,8):
		overlaps.append(str(hit.collider.get_path())+" shape="+str(hit.shape))
	var ray:=PhysicsRayQueryParameters3D.create(rider.global_position+Vector3.UP*0.5,rider.global_position-Vector3.UP*0.5,1,[rider.get_rid()])
	var below: Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(ray)
	var ray_record: Dictionary={}
	if not below.is_empty():
		ray_record={"collider":str(below.collider.get_path()),"position":str(below.position),"normal":str(below.normal),"origin_clearance":rider.global_position.y-float(below.position.y)}
	var collisions: Array[Dictionary]=[]
	for index: int in rider.get_slide_collision_count():
		var collision:=rider.get_slide_collision(index)
		collisions.append({"collider":str(collision.get_collider().get_path()),"normal":str(collision.get_normal()),"depth":collision.get_depth()})
	return {"tick":Engine.get_physics_frames(),"on_floor":rider.is_on_floor(),"airborne":rider.airborne,
		"position":str(rider.global_position),"velocity":str(rider.velocity),"real_velocity":str(rider.get_real_velocity()),
		"speed":rider.speed,"safe_margin":rider.safe_margin,"floor_snap":rider.floor_snap_length,
		"capsule_margin":query.margin,"capsule_overlaps":overlaps,"ray":ray_record,"slide_collisions":collisions}


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	_release()
	var game: Node=MainScene.instantiate()
	game.persistence_enabled=false
	tree.root.add_child(game)
	game.start_mode(true)
	var lines: Array=game.world.get_grind_lines()
	for specification: Dictionary in [
		{"family":"Planter_","at":Vector3(-29,0.84,11.5),"direction":Vector3.RIGHT,"outside":Vector3.FORWARD,"behind":0.9,"charge":2},
		{"family":"MarketCounter_","at":Vector3(109.5,1.24,2),"direction":Vector3.FORWARD,"outside":Vector3.RIGHT,"behind":3.0,"charge":18},
		{"family":"StreetBenchSeat_","at":Vector3(29,0.585,27.26),"direction":Vector3.LEFT,"outside":Vector3.BACK,"behind":0.9,"charge":2},
		{"family":"BridgeRail_","at":Vector3(-28.85,3.8,81),"direction":Vector3.BACK,"outside":Vector3.RIGHT,"behind":3.0,"charge":18}]:
		await _approach(tree,game,lines,check,specification)
	_release()
	game.free()
	tree.paused=false
	await tree.process_frame


static func _approach(tree: SceneTree,game: Node,lines: Array,check: Callable,specification: Dictionary) -> void:
	var selected: RefCounted=null
	var closest := INF
	for line: RefCounted in lines:
		if not str(line.id).begins_with("Grind_Edge_"+str(specification.family)) or line.length<1.5: continue
		var near: Dictionary=line.closest(specification.at)
		if not near.is_empty() and float(near.gap)<closest:
			selected=line
			closest=near.gap
	check.call(selected!=null and closest<0.30,
		"world edge: actual selected %s line exists at its authored physical prop" % specification.family)
	if selected==null or closest>=0.30: return
	var a: Vector3=selected.points[0]
	var b: Vector3=selected.points[-1]
	if (b-a).dot(specification.direction)<0.0:
		var swap:=a
		a=b
		b=swap
	var direction: Vector3=(b-a).normalized()
	var start: Vector3=a-direction*float(specification.behind)+specification.outside*0.35
	var ground: float=game.world.get_ground_height(start)
	check.call(is_finite(ground),"world edge: %s declared outside approach has actual authored ground" % specification.family)
	if not is_finite(ground): return
	start.y=ground+0.8
	_release()
	game.skater.spawn_position=start
	game.start_mode(true)
	game.skater.rotation.y=atan2(-direction.x,-direction.z)
	game.skater.reset_physics_interpolation()
	await _ticks(tree,40)
	var stable_support: bool=game.skater.is_on_floor() and _standing_clear(game.skater)
	var settled: Vector3=game.skater.global_position
	for tick: int in range(10):
		await _ticks(tree,1)
		stable_support=stable_support and game.skater.is_on_floor() and _standing_clear(game.skater)
		stable_support=stable_support and game.skater.global_position.distance_to(settled)<0.005 and game.skater.velocity.length()<0.05
	check.call(stable_support,
		"world edge: %s initial body retains real floor/height and scenery clearance for ten consecutive idle ticks" % specification.family)
	var captures: Array[String]=[]
	var tricks: Array[String]=[]
	var bails: Array[int]=[0]
	var on_capture:=func(id: String): captures.append(id)
	var on_trick:=func(id: String,_points: int): tricks.append(id)
	var on_bail:=func(): bails[0]+=1
	game.skater.grind_captured.connect(on_capture)
	game.skater.trick_performed.connect(on_trick)
	game.skater.bailed.connect(on_bail)
	_key(KEY_W,true)
	await _ticks(tree,18)
	_key(KEY_SPACE,true)
	await _ticks(tree,int(specification.charge))
	_key(KEY_W,false)
	_key(KEY_SPACE,false)
	var descending := false
	var caught := false
	for tick: int in range(90):
		await _ticks(tree,1)
		if game.skater.airborne and game.skater.velocity.y<0.0 and not descending:
			descending=true
			_key(KEY_L,true)
		if game.skater.grinding:
			caught=true
			break
		if bails[0]>0: break
	check.call(descending and caught and captures==[str(selected.id)] and _grind_award_count(tricks)==1 and bails[0]==0,
		"world edge: mapped approach descends into exactly the selected real %s edge once" % specification.family)
	var travelled := 0.0
	var clear := caught
	if caught:
		var previous: Vector3=game.skater.global_position
		for tick: int in range(30):
			await _ticks(tree,1)
			if not game.skater.grinding: break
			travelled+=game.skater.global_position.distance_to(previous)
			previous=game.skater.global_position
			clear=clear and _capsule_clear(game.skater)
			if travelled>0.40: break
	check.call(caught and clear and travelled>0.30 and game.skater.grinding,
		"world edge: %s carries the actual clear capsule over 0.30m along the selected edge" % specification.family)
	_key(KEY_L,false)
	await _ticks(tree,1)
	_key(KEY_L,true)
	await _ticks(tree,1)
	_key(KEY_L,false)
	await _ticks(tree,3)
	check.call(caught and not game.skater.grinding and captures.size()==1 and _grind_award_count(tricks)==1 and bails[0]==0,
		"world edge: fresh mapped L tap exits %s with one total catch/award and no bail" % specification.family)
	print("WORLD_EDGE family=",specification.family," selected=",selected.id," fixture=",start,
		" captured=",captures," ride_m=",travelled," clear=",clear," bails=",bails[0]," final=",game.skater.global_position)
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.bailed.disconnect(on_bail)
	_release()


static func _capsule_clear(rider: CharacterBody3D) -> bool:
	var body: CollisionShape3D=rider.get_node("BodyCollision")
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=body.shape
	query.transform=body.global_transform
	query.collision_mask=1
	query.exclude=[rider.get_rid()]
	query.margin=0.001
	return rider.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()


static func _standing_clear(rider: CharacterBody3D) -> bool:
	# A .001m query skin exceeded the measured .000506m idle floor gap. Lift
	# only this diagnostic volume by the existing native .015m safe_margin;
	# never move the rider or apply that allowance to an active grind ride.
	var body: CollisionShape3D=rider.get_node("BodyCollision")
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=body.shape
	query.transform=body.global_transform
	query.transform.origin+=Vector3.UP*rider.safe_margin
	query.collision_mask=1
	query.exclude=[rider.get_rid()]
	query.margin=0.001
	if not rider.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return false
	var ray:=PhysicsRayQueryParameters3D.create(rider.global_position+Vector3.UP*0.05,rider.global_position-Vector3.UP*0.05,1,[rider.get_rid()])
	var hit: Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty(): return false
	var gap: float=rider.global_position.y-float(hit.position.y)
	return gap>=-rider.safe_margin and gap<=rider.safe_margin and hit.normal.dot(Vector3.UP)>=cos(rider.floor_max_angle)


static func _ticks(tree: SceneTree,count: int) -> void:
	var target:=Engine.get_physics_frames()+count
	while Engine.get_physics_frames()<target:
		await tree.physics_frame
		await tree.process_frame


static func _key(code: Key,down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


static func _release() -> void:
	for code: Key in [KEY_W,KEY_SPACE,KEY_L]: _key(code,false)
	for action: StringName in InputMap.get_actions(): Input.action_release(action)


static func _grind_award_count(names: Array) -> int:
	var count := 0
	for name: String in names:
		if Catalog.is_grind_name(name): count += 1
	return count
