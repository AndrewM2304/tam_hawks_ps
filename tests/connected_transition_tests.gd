extends RefCounted
## Real finite connected surfaces. Declared setup positions/speeds are applied
## once; contact, carving, transfer, landing and rollback use native motion.
const Native = preload("res://tests/transition_ride_tests.gd")
const Bowl = preload("res://game/levels/bowl_feature.gd")
const Halfpipe = preload("res://game/levels/halfpipe_feature.gd")
const Spine = preload("res://game/levels/spine_feature.gd")

static func run(tree: SceneTree, check: Callable) -> void:
	await _bowl_geometry(tree,check)
	await _bowl_access(tree,check)
	await _bowl_lap(tree,check)
	await _bowl_rollback(tree,check)
	await _halfpipe_connection(tree,check)
	await _spine_transfer(tree,check)
	await _bowl_obstruction(tree,check)
	await _transformed_bowl(tree,check)
	await _upright_coping_contact(tree,check)

static func _bowl_geometry(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree,Bowl.new())
	var bowl = fixture.feature
	var matches := true
	for phi: float in [0.0,0.7,3.0,TAU-0.01]:
		for theta: float in [0.02,0.6,1.2,1.55]:
			var sample: Dictionary = bowl.sample(theta,phi*bowl.floor_radius)
			var query := PhysicsRayQueryParameters3D.create(sample.point+sample.normal*0.1,sample.point-sample.normal*0.08,1)
			query.exclude = [fixture.rider.get_rid()]
			var hit: Dictionary = fixture.rider.get_world_3d().direct_space_state.intersect_ray(query)
			matches = matches and not hit.is_empty() and hit.collider==bowl.surface_body \
				and hit.position.distance_to(sample.point)<0.004 and hit.normal.dot(sample.normal)>0.998
	check.call(matches,"connected transition: bowl visible samples match native collision around all sides and steepnesses")
	var a: Dictionary = bowl.sample(0.7,-bowl.width*0.5+0.001)
	var b: Dictionary = bowl.sample(0.7,bowl.width*0.5+0.001)
	check.call(a.point.distance_to(b.point)<0.0001 and a.normal.distance_to(b.normal)<0.0001,
		"connected transition: circular lateral seam has continuous actual position and contact frame")
	var radius: float = bowl.floor_radius+bowl.radius+bowl.deck_length
	var supported := true
	for point: Vector3 in [Vector3.ZERO,Vector3(0,bowl.radius,radius-0.8),Vector3(0,0,radius+8)]:
		var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.1,point-Vector3.UP*0.1,1)
		query.exclude = [fixture.rider.get_rid()]
		var hit: Dictionary = fixture.rider.get_world_3d().direct_space_state.intersect_ray(query)
		supported = supported and not hit.is_empty() and hit.normal.y>0.95 and hit.position.distance_to(point)<0.01
	check.call(supported,"connected transition: bowl bottom, external roll-in and deck are real supported surfaces")
	check.call(bowl.get_grind_lines().size()==1 and bowl.get_grind_lines()[0].length>35.0,
		"connected transition: complete bowl coping is one authored world-space grind track")
	await _dispose(tree,fixture.root)

static func _bowl_lap(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree,Bowl.new())
	var rider = fixture.rider
	var bowl = fixture.feature
	var theta := 0.6
	var sample: Dictionary = bowl.sample(theta,0.0)
	var around_speed := sqrt(22.0*(bowl.floor_radius+bowl.radius*sin(theta))*tan(theta))
	rider.global_position = sample.point+sample.normal*0.022
	rider.velocity = sample.lateral*around_speed
	var energy: float = rider.velocity.length_squared()*0.5+22.0*rider.global_position.y
	rider.running = true
	var swept := 0.0
	var previous := 0.0
	var min_theta := theta
	var max_theta := theta
	var max_motion := 0.0
	for i in 270:
		var before: Vector3 = rider.global_position
		await _frames(tree,1)
		var local: Vector3 = bowl.to_local(rider.global_position)
		var phi := atan2(local.x,-local.z)
		swept += angle_difference(previous,phi)
		previous = phi
		min_theta = minf(min_theta,rider.ride._theta)
		max_theta = maxf(max_theta,rider.ride._theta)
		max_motion = maxf(max_motion,rider.global_position.distance_to(before))
	print("BOWL LAP swept=%.4f theta=[%.4f,%.4f] energy=%.3f/%.3f entry=%d bail=%d" %[swept,min_theta,max_theta,rider.max_energy,energy,rider.entries,rider.bails])
	check.call(swept>TAU and rider.entries==1 and rider.bails==0 and rider.ride.state=="surface",
		"connected transition: unpowered native bowl carving completes a full wrapped lap without detaching")
	check.call(min_theta>0.3 and max_theta<0.9 and rider.launches==0 and rider.landings==0,
		"connected transition: lateral curvature sustains a physical carve without inventing air or repeated landings")
	check.call(rider.max_energy<energy*1.03 and max_motion<0.25 and rider.max_error<=0.045,
		"connected transition: bowl parallel transport adds no hidden energy, jumps or unbounded support correction")
	check.call(rider.ride.normal.is_finite() and rider.ride.forward.is_finite(),
		"connected transition: full-lap contact and travel normals remain finite at the seam")
	rider.rotation.y += 1.2
	rider.ride.refresh_frame(rider)
	check.call(rider.get_node("BodyCollision").global_basis.y.dot(rider.ride.normal)>0.999,
		"connected transition: root heading changes preserve the actual global collision support axis")
	rider.ride.reset(rider)
	check.call(rider.get_node("BodyCollision").position.is_equal_approx(Vector3(0,0.85,0)) and rider.up_direction==Vector3.UP,
		"connected transition: bowl reset restores ordinary capsule orientation and world up")
	await _dispose(tree,fixture.root)

static func _bowl_access(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree,Bowl.new())
	var rider = fixture.rider
	var bowl = fixture.feature
	var outer: float = bowl.floor_radius+bowl.radius+bowl.deck_length
	rider.position = Vector3(0,0.022,outer+9)
	rider.velocity = Vector3.FORWARD*12.0
	rider.running = true
	var entered_bottom := false
	for i in 210:
		await _frames(tree,1)
		if Vector2(rider.position.x,rider.position.z).length()<bowl.floor_radius-0.2 and rider.position.y<0.1:
			entered_bottom = true
	check.call(entered_bottom and rider.max_y>=bowl.radius-0.02 and rider.bails==0,
		"connected transition: real outside approach climbs the roll-in, clears the retaining wall and reaches the bowl bottom")
	await _dispose(tree,fixture.root)

static func _bowl_rollback(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree,Bowl.new())
	var rider = fixture.rider
	rider.position = Vector3(0,0.022,0)
	rider.velocity = Vector3.FORWARD*4.0
	rider.running = true
	await _frames(tree,145)
	check.call(rider.entries==1 and rider.exits==1 and rider.launches==0 and rider.bails==0,
		"connected transition: actual flat-bottom approach climbs and rolls back from a low-energy bowl wall")
	check.call(rider.max_y>0.25 and rider.max_y<0.43 and rider.velocity.z>3.0,
		"connected transition: bowl rollback height follows full gravity and preserves useful return momentum")
	await _dispose(tree,fixture.root)

static func _halfpipe_connection(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree,Halfpipe.new())
	var rider = fixture.rider
	rider.velocity = Vector3.FORWARD*12.0
	rider.running = true
	var faces: Dictionary = {}
	for i in 280:
		await _frames(tree,1)
		if rider.ride.active: faces[rider.ride.feature.name]=true
	print("HALFPIPE faces=%s entry=%d launch=%d landing=%d exit=%d bail=%d"%[faces.keys(),rider.entries,rider.launches,rider.landings,rider.exits,rider.bails])
	check.call(faces.size()==2 and rider.entries>=2 and rider.launches>=2 and rider.landings>=2 and rider.bails==0,
		"connected transition: real halfpipe bottom links two opposing vertical faces and their returns")
	check.call(rider.max_energy<73.5 and rider.max_error<=0.045,
		"connected transition: repeated halfpipe crossings preserve bounded unpowered energy and collision support")
	check.call(fixture.feature.get_grind_lines().size()==2,
		"connected transition: each halfpipe deck exposes its own original coping track")
	await _dispose(tree,fixture.root)

static func _spine_transfer(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree,Spine.new())
	var rider = fixture.rider
	var spine = fixture.feature
	rider.position = Vector3(0,0.022,spine.radius+spine.cap_width*0.5+0.05)
	rider.velocity = Vector3.FORWARD*12.0
	rider.push = 1.0
	rider.running = true
	for i in 90:
		await _frames(tree,1)
		if rider.ride.state=="air": break
	var launched: bool = rider.ride.state=="air"
	rider.push = 0.0
	await _frames(tree,1)
	rider.push = 1.0
	await _frames(tree,12)
	rider.push = 0.0
	var second_face := false
	for i in 170:
		await _frames(tree,1)
		if rider.ride.active and rider.ride.feature.name=="BackTransition" and rider.ride.state=="surface": second_face=true
	print("SPINE launch=%s second=%s entry=%d land=%d exit=%d bail=%d p=%s"%[launched,second_face,rider.entries,rider.landings,rider.exits,rider.bails,rider.position])
	check.call(launched and second_face and rider.landings==1 and rider.bails==0,
		"connected transition: deliberate airborne spine transfer crosses the solid cap and lands on the other real face")
	check.call(rider.position.z< -spine.radius-spine.cap_width*0.5 and rider.velocity.z< -5.0,
		"connected transition: spine transfer rolls down the second transition into its actual landing area")
	check.call(spine.get_grind_lines().size()==2,
		"connected transition: both sides of the narrow spine have independent real coping lines")
	await _dispose(tree,fixture.root)

static func _bowl_obstruction(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree,Bowl.new())
	var bowl = fixture.feature
	var rider = fixture.rider
	var sample: Dictionary = bowl.sample(0.6,0.0)
	rider.position = sample.point+sample.normal*0.022
	rider.velocity = sample.lateral*8.5
	fixture.root.add_child(Native._box(Vector3(0.3,3,4),Vector3(2,1.5,-4)))
	await _frames(tree,2)
	rider.running = true
	await _frames(tree,30)
	check.call(rider.entries==1 and rider.bails==1 and rider.position.x<1.8,
		"connected transition: a real bowl obstruction interrupts carving without crossing its collision")
	await _dispose(tree,fixture.root)

static func _transformed_bowl(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree,Bowl.new(),Vector3(35,4,28),0.73)
	var bowl = fixture.feature
	var rider = fixture.rider
	var sample: Dictionary = bowl.sample(0.6,0.0)
	rider.global_position = sample.point+sample.normal*0.022
	rider.velocity = sample.lateral*sqrt(22.0*(bowl.floor_radius+bowl.radius*sin(0.6))*tan(0.6))
	rider.running = true
	await _frames(tree,90)
	check.call(rider.entries==1 and rider.ride.state=="surface" and rider.bails==0
		and bowl.to_local(rider.global_position).x>2.0,
		"connected transition: translated and yawed bowl contact follows its actual world-space curved surface")
	await _dispose(tree,fixture.root)

static func _upright_coping_contact(tree: SceneTree, check: Callable) -> void:
	for curved: bool in [false,true]:
		var shape = Bowl.new() if curved else Native.TransitionFeature.new()
		var fixture := await _fixture(tree,shape)
		var rider = fixture.rider
		var initial: Dictionary = shape.sample(0.0,0.4*shape.floor_radius if curved else 0.0)
		rider.global_position = initial.point+Vector3.UP*0.022
		rider.velocity = initial.tangent*12.0
		rider.held = true
		rider.running = true
		await _frames(tree,50)
		var frame: Dictionary = rider.ride.lip_frame()
		check.call(rider.ride.state=="lip" and rider.ride.normal.dot(Vector3.UP)>0.999
			and rider.get_node("BodyCollision").global_basis.y.dot(Vector3.UP)>0.999,
			"connected transition: %s coping holds an upright native capsule on the steel top"%("bowl" if curved else "quarter-pipe"))
		check.call(not frame.is_empty() and frame.normal==Vector3.UP
			and absf(Vector3(frame.face_normal).dot(Vector3.UP))<0.001
			and rider.global_position.distance_to(frame.point+Vector3.UP*0.002)<0.01,
			"connected transition: lip pose frame separates actual steel contact from the curved face normal")
		var query := PhysicsRayQueryParameters3D.create(rider.global_position+Vector3.UP*0.03,rider.global_position-Vector3.UP*0.03,2)
		query.exclude = [rider.get_rid()]
		var hit: Dictionary = rider.get_world_3d().direct_space_state.intersect_ray(query)
		check.call(not hit.is_empty() and hit.collider.get_meta("coping_feature",null)==shape
			and hit.position.distance_to(frame.point)<0.008,
			"connected transition: lip support ray contacts the actual native steel coping collision")
		var was_supported: bool = rider.ride.state=="lip" and not hit.is_empty()
		var prior_bails: int = rider.bails
		if not hit.is_empty(): hit.collider.collision_layer=0
		await _frames(tree,2)
		check.call(was_supported and rider.bails==prior_bails+1 and not rider.ride.active,
			"connected transition: removing steel collision ends lip support even while its concrete face remains")
		await _dispose(tree,fixture.root)

static func _fixture(tree: SceneTree, feature: Node3D, at: Vector3=Vector3.ZERO, yaw: float=0.0) -> Dictionary:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = yaw
	tree.root.add_child(root)
	root.add_child(feature)
	root.add_child(Native._box(Vector3(70,0.5,70),Vector3(0,-0.25,0)))
	var rider = Native.Rider.new()
	rider.collision_layer = 2
	rider.collision_mask = 1
	rider.position.y = 0.022
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	collision.position.y = 0.85
	var shape := CapsuleShape3D.new()
	shape.height = 1.7
	shape.radius = 0.28
	collision.shape = shape
	rider.add_child(collision)
	root.add_child(rider)
	await _frames(tree,3)
	return {"root":root,"feature":feature,"rider":rider}

static func _frames(tree: SceneTree, count: int) -> void:
	await Native._frames(tree,count)

static func _dispose(tree: SceneTree, root: Node) -> void:
	await Native._dispose(tree,root)
