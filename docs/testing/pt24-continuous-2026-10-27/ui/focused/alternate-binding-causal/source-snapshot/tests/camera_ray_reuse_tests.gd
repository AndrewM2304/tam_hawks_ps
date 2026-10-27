extends RefCounted
## Native equality and parameter-object reuse, not a target frame-time benchmark.
const Chase = preload("res://game/player/chase_camera.gd")
const Acceptance = preload("res://tests/pt24_acceptance_tests.gd")

class FreshVisibility extends "res://game/player/chase_camera.gd":
	var allocations := 0
	func _visibility_ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, excluded: Array[RID]) -> Dictionary:
		allocations += 1
		_visibility_rays += 1
		return space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1|8,excluded))


static func run(tree: SceneTree,check: Callable) -> void:
	Acceptance.Setup.register_actions()
	for action: String in InputMap.get_actions(): Input.action_release(action)
	var fixture := await Acceptance._fixture(tree)
	await _solver_pairs(tree,fixture,check)
	await _native_parameters(tree,fixture,check)
	fixture.viewport.queue_free()
	await tree.process_frame


static func _solver_pairs(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
	var rider: CharacterBody3D = fixture.rider
	var reused := Chase.new()
	var fresh := FreshVisibility.new()
	var reused_camera := Camera3D.new()
	var fresh_camera := Camera3D.new()
	fixture.root.add_child(reused_camera)
	fixture.root.add_child(fresh_camera)
	var persistent_id := reused._visibility_query.get_instance_id()
	var original_physics := Acceptance._physics_snapshot(rider)
	var total_rays := 0
	var pairs := 0
	for geometry: String in ["open","rear_wall","corner","low_roof","open"]:
		Acceptance._arrange(fixture,geometry)
		await Acceptance._frames(tree,2)
		reused.reset()
		fresh.reset()
		var initial := Transform3D(Basis.IDENTITY,rider.global_position+Vector3(0,2.5,5))
		reused_camera.global_transform=initial
		fresh_camera.global_transform=initial
		reused_camera.fov=70
		fresh_camera.fov=70
		var same := true
		var counts := true
		var unchanged := true
		for sample: int in 8:
			reused.update(rider,reused_camera,1.0/60.0,1.0,false)
			fresh.update(rider,fresh_camera,1.0/60.0,1.0,false)
			same = same and reused_camera.global_transform==fresh_camera.global_transform \
				and reused_camera.fov==fresh_camera.fov and Acceptance._state(reused)==Acceptance._state(fresh)
			counts = counts and reused.last_update_queries==fresh.last_update_queries
			unchanged = unchanged and Acceptance._physics_snapshot(rider)==original_physics \
				and reused._visibility_query.get_instance_id()==persistent_id
			total_rays += int(reused.last_update_queries.ray)
			pairs += 1
		check.call(same and counts,
			"camera ray reuse: exact native transform/FOV/state and query-count parity against fresh parameters "+geometry)
		check.call(unchanged,
			"camera ray reuse: one parameter identity survives native view changes/reset without touching rider physics "+geometry)
	check.call(total_rays>100 and fresh.allocations==total_rays,
		"camera ray reuse: the control constructs one native parameter object per visibility ray while the actual solver retains one")
	print("CAMERA_RAY_REUSE_SOLVER ",{"pairs":pairs,"visibility_rays":total_rays,"fresh_parameter_allocations":fresh.allocations,
		"reused_parameter_objects":1,"native_queries_unchanged":true})
	reused_camera.queue_free()
	fresh_camera.queue_free()
	await tree.process_frame


static func _native_parameters(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
	var rider: CharacterBody3D = fixture.rider
	var space := rider.get_world_3d().direct_space_state
	var reused := Chase.new()
	var defaults := PhysicsRayQueryParameters3D.create(Vector3.ZERO,Vector3.ONE,1|8)
	var parameter: PhysicsRayQueryParameters3D = reused._visibility_query
	check.call(parameter.collision_mask==defaults.collision_mask
		and parameter.collide_with_bodies==defaults.collide_with_bodies
		and parameter.collide_with_areas==defaults.collide_with_areas
		and parameter.hit_back_faces==defaults.hit_back_faces
		and parameter.hit_from_inside==defaults.hit_from_inside,
		"camera ray reuse: persistent mask and all native ray flags match the original factory defaults")
	var bodies: Array[StaticBody3D] = []
	for record: Array in [[10.0,1],[12.0,8],[14.0,2]]:
		var body := Acceptance._box(Vector3.ONE,Vector3(record[0],1,-2))
		body.collision_layer=record[1]
		fixture.root.add_child(body)
		bodies.append(body)
	await Acceptance._frames(tree,2)
	var persistent_id := parameter.get_instance_id()
	var paired := true
	var outcomes := true
	var prior_result := {}
	var rows: Array[Dictionary] = []
	# The third request clears prior exclusions; the rail-only layer is kept,
	# while a player-only layer remains outside the unchanged1|8 mask.
	for record: Array in [[10.0,[],true],[10.0,[bodies[0].get_rid()],false],
		[10.0,[],true],[12.0,[],true],[14.0,[],false],[10.0,[],true]]:
		var from := Vector3(record[0],1,2)
		var to := Vector3(record[0],1,-4)
		var excluded: Array[RID] = []
		excluded.assign(record[1])
		var actual := reused._visibility_ray(space,from,to,excluded)
		var control := space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1|8,excluded))
		paired = paired and actual==control and parameter.from==from and parameter.to==to \
			and parameter.exclude==excluded and parameter.get_instance_id()==persistent_id
		outcomes = outcomes and (not actual.is_empty())==bool(record[2])
		if rows.is_empty():prior_result=actual
		rows.append({"x":record[0],"excluded":excluded.size(),"hit":not actual.is_empty()})
	check.call(paired and outcomes,
		"camera ray reuse: real hit/miss, changed endpoints, layer8 and cleared exclusions exactly match fresh native queries")
	check.call(prior_result.get("collider")==bodies[0] and Vector3(prior_result.get("position",Vector3.INF)).distance_to(Vector3(10,1,-1.5))<.00001,
		"camera ray reuse: a later query cannot mutate an earlier returned native hit dictionary")
	# Native removal must be observed immediately; only parameter storage is
	# retained, not any hit answer from a previous call or update.
	bodies[0].position.x=20
	await Acceptance._frames(tree,2)
	var empty: Array[RID] = []
	check.call(reused._visibility_ray(space,Vector3(10,1,2),Vector3(10,1,-4),empty).is_empty(),
		"camera ray reuse: moving the native blocker away invalidates the result on the very next direct ray")
	var floor_point := Vector3(10,0,0)
	var actual := reused._visibility_ray(space,floor_point+Vector3.UP*.03,floor_point-Vector3.UP*.03,empty)
	var control := space.intersect_ray(PhysicsRayQueryParameters3D.create(floor_point+Vector3.UP*.03,floor_point-Vector3.UP*.03,1|8,empty))
	check.call(not actual.is_empty() and actual==control and Vector3(actual.normal).dot(Vector3.UP)>.99,
		"camera ray reuse: the tiny endpoint-support ray preserves native floor point/normal after an unrelated miss")
	print("CAMERA_RAY_REUSE_PARAMETERS ",{"cases":rows,"reused_parameter_objects":1,"support_hit":actual})
	for body: StaticBody3D in bodies:body.queue_free()
	await tree.process_frame
