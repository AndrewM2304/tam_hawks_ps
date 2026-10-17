extends RefCounted
## Production collision checks for district access and collectible reachability.
## Does not establish controller feel or certify the final visual direction.

static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	await tree.physics_frame
	await tree.process_frame
	var checkpoints: Dictionary = world.get_district_checkpoints()
	check.call(checkpoints.size() == 6, "district routes: six named checkpoints")
	for id: String in checkpoints:
		var at: Vector3 = checkpoints[id]
		check.call(world.get_district_id(at) == id, "district routes: checkpoint classification " + id)
		check.call(_ground_below(world, at), "district routes: supported checkpoint " + id)
		check.call(_clear_standing(world, at), "district routes: clear checkpoint capsule " + id)

	# Authored ground-contact waypoints are checked against production collision,
	# not trusted as evidence themselves. The separate player route suite tests
	# acceleration, slope support and actual transit along these connections.
	var routes: Array = world.get_route_definitions()
	check.call(routes.size() >= 8, "district routes: core and outdoor navigation routes published")
	for route: Dictionary in routes:
		var points: PackedVector3Array = route.points
		check.call(points.size() >= 2, "district routes: usable waypoint route " + route.id)
		if points.size() < 2 or route.get("requires_jump", false):
			continue
		var supported := true
		var clear := true
		for segment in range(points.size() - 1):
			var start: Vector3 = points[segment]
			var end: Vector3 = points[segment + 1]
			var samples: int = maxi(2, ceili(start.distance_to(end) / 1.5))
			for step in range(samples + 1):
				var ground := start.lerp(end, float(step) / samples)
				var hit := _floor_hit(world, ground + Vector3.UP * 0.8)
				var sample_ok: bool = not hit.is_empty() and absf(hit.position.y - ground.y) < 0.25 and hit.normal.y >= cos(deg_to_rad(56.0))
				if not sample_ok and supported:
					print("ROUTE SUPPORT %s expected=%s actual=%s" % [route.id, ground, hit.get("position", Vector3.INF)])
				supported = supported and sample_ok
			var segment_clear := _clear_sweep(world, start, end) and _clear_sweep(world, end, start)
			if not segment_clear and clear:
				print("ROUTE CLEARANCE %s start=%s end=%s" % [route.id, start, end])
			clear = clear and segment_clear
		check.call(supported, "district routes: continuous collision matches route elevation " + route.id)
		check.call(clear, "district routes: unobstructed capsule in both directions " + route.id)

	var marker_ids: Array[String] = []
	for marker: Dictionary in world.get_goal_markers():
		check.call(not marker_ids.has(marker.id), "district routes: unique marker " + marker.id)
		marker_ids.append(marker.id)
		check.call(_ground_below(world, marker.position), "district routes: supported marker " + marker.id)
		check.call(_clear_standing(world, marker.position), "district routes: reachable marker capsule " + marker.id)
	check.call(marker_ids.has("H") and marker_ids.has("A") and marker_ids.has("W")
		and marker_ids.has("K") and marker_ids.has("S") and marker_ids.has("secret_recording"),
		"district routes: complete letters and recording hooks")

	var gap_ids: Array[String] = []
	for gap: Dictionary in world.get_gap_definitions():
		gap_ids.append(gap.id)
		check.call(gap.start.distance_to(gap.end) > 1.0 and gap.start.distance_to(gap.end) <= 16.0 and gap.radius > 0.0 and gap.points > 0,
			"district routes: bounded authored gap " + gap.id)
	check.call(gap_ids.has("central_gap") and gap_ids.size() >= 3, "district routes: platform gap and two other routes")
	var space := world.get_world_3d().direct_space_state
	var gap_floor := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-94, 8, -3), Vector3(-94, -1, -3), 1))
	check.call(not gap_floor.is_empty() and absf(gap_floor.position.y - 2.0) < 0.05,
		"district routes: platform gap has a real break and safe lower floor")
	for z: float in [6.0, -10.0]:
		var platform := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-94, 8, z), Vector3(-94, -1, z), 1))
		check.call(not platform.is_empty() and is_equal_approx(platform.position.y, 5.0),
			"district routes: raised platform supports its route " + str(z))
	var supported_npcs := true
	var npc_positions: Array[Vector3] = world.get_npc_positions()
	for at: Vector3 in npc_positions:
		supported_npcs = supported_npcs and _ground_below(world, at + Vector3.UP * 0.8)
	check.call(npc_positions.size() == 4 and supported_npcs, "district routes: bystanders stand on actual district floors")

	var cone: Node3D = world.get_node("ProvostOfPush/InteractiveCone")
	var cone_start := cone.position
	# Let initial texture/scene construction leave the first idle frame before
	# measuring the animation; its startup cost is not a simulation timestep.
	for i: int in range(3):
		await tree.physics_frame
		await tree.process_frame
	world.activate_cone()
	for i: int in range(8):
		await tree.physics_frame
		await tree.process_frame
	check.call(world.cone_activated and cone.position.y > cone_start.y + 0.1,
		"district routes: cone interaction visibly pops the original cone")
	var paused_before := tree.paused
	tree.paused = true
	var paused_cone := cone.position
	await tree.create_timer(0.08, true).timeout
	check.call(cone.position.is_equal_approx(paused_cone), "district routes: cone animation freezes while paused")
	tree.paused = paused_before
	world.reset_interactions()
	check.call(not world.cone_activated and cone.position.is_equal_approx(cone_start)
		and cone.rotation.is_zero_approx(), "district routes: reset restores cone and clears interaction state")


static func _ground_below(world: Node3D, at: Vector3) -> bool:
	var hit := _floor_hit(world, at)
	return not hit.is_empty() and hit.normal.y >= cos(deg_to_rad(56.0))


static func _floor_hit(world: Node3D, at: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.1, at - Vector3.UP * 1.5, 1)
	return world.get_world_3d().direct_space_state.intersect_ray(query)


static func _clear_standing(world: Node3D, marker: Vector3) -> bool:
	var floor_query := PhysicsRayQueryParameters3D.create(marker + Vector3.UP * 0.1, marker - Vector3.UP * 1.5, 1)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(floor_query)
	if hit.is_empty():
		return false
	var query := _capsule_query(hit.position)
	return world.get_world_3d().direct_space_state.intersect_shape(query).is_empty()


static func _clear_sweep(world: Node3D, start: Vector3, end: Vector3) -> bool:
	var query := _capsule_query(start)
	query.motion = end - start
	var result := world.get_world_3d().direct_space_state.cast_motion(query)
	return result.size() == 2 and result[0] >= 0.9999


static func _capsule_query(floor_at: Vector3) -> PhysicsShapeQueryParameters3D:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, floor_at + Vector3.UP * 0.98)
	query.collision_mask = 1
	query.margin = 0.01
	return query
