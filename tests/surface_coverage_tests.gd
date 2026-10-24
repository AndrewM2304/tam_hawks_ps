extends RefCounted
## Real level collision + eligibility checks. No renderer/human-feel claim.

const Ride = preload("res://game/tricks/grind_ride.gd")
const WallRide = preload("res://game/player/wall_ride.gd")


static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	await tree.physics_frame
	await tree.process_frame
	var audit: Dictionary = world.get_surface_audit()
	check.call(audit.collider_count > 150 and audit.wallrideable_count > 20,
		"surface audit: inventories real level colliders and substantial rideable walls")
	check.call(audit.generated_grind_count >= 40 and audit.ledge_body_count >= 20,
		"surface audit: previously bare furniture and planters expose collision-backed top edges")
	var lines: Dictionary = {}
	var duplicate_ids := false
	for line in world.get_grind_lines():
		duplicate_ids = duplicate_ids or lines.has(line.id)
		lines[line.id] = line
	check.call(not duplicate_ids, "surface audit: all authored and derived grind tracks retain unique stable IDs")
	var classified := true
	var boundary_excluded := true
	var eligible_helpers_agree := true
	var candidate_covered := true
	var referenced_tracks_exist := true
	var generated_capture_count := 0
	var authored_capture_count := 0
	var blocked: Array[String] = []
	for record: Dictionary in audit.surfaces:
		var body := world.get_node(NodePath(record.path)) as StaticBody3D
		classified = classified and body != null and body.has_meta("surface_audit_id") and not record.wall_reason.is_empty()
		if body.get_meta("exploration_boundary", false):
			boundary_excluded = boundary_excluded and not record.wallrideable and body.get_meta("no_wallride", false)
		if record.wallrideable:
			eligible_helpers_agree = eligible_helpers_agree and WallRide.is_surface_eligible(body)
		if record.generated_ledge:
			candidate_covered = candidate_covered and not record.grind_ids.is_empty()
		for id: String in record.grind_ids:
			referenced_tracks_exist = referenced_tracks_exist and lines.has(id)
			var generated := id.begins_with("Grind_Ledge_" + record.id + "_")
			if not generated and not record.capture_check_ids.has(id): continue
			var line = lines[id]
			var usable := true
			for fraction: float in [0.2,0.5,0.8]:
				var at: Vector3 = line.point_at(line.length * fraction)
				var tangent: Vector3 = line.dir_at(line.length * fraction)
				var approach := Vector3(tangent.x,0,tangent.z).normalized()*6.0-Vector3.UP
				var ride = Ride.new()
				usable = usable and ride.start([line], at + Vector3.UP * 0.15,
					approach, func(from: Vector3, to: Vector3) -> bool: return _clear_capture(world, from, to))
			if usable:
				if generated: generated_capture_count += 1
				else: authored_capture_count += 1
			else: blocked.append(id)
	check.call(classified and boundary_excluded,
		"surface audit: every physical surface has a reason and retained fences are explicitly excluded")
	check.call(eligible_helpers_agree, "surface audit: architecture wall tags agree with production wallride eligibility")
	check.call(candidate_covered and referenced_tracks_exist,
		"surface audit: each selected visible ledge candidate references actual published grind tracks")
	if not blocked.is_empty(): print("SURFACE BLOCKED GENERATED TRACKS ", blocked)
	check.call(blocked.is_empty() and generated_capture_count == audit.generated_grind_count and authored_capture_count >= 10,
		"surface audit: new generated and raised-terrain ledges capture at three interior points with the production capsule and native collision sweep")
	var snapshot: Dictionary = world.get_surface_audit()
	snapshot.surfaces.clear()
	check.call(not world.get_surface_audit().surfaces.is_empty(), "surface audit: callers cannot mutate the level inventory")
	for family: String in ["safe", "north", "south"]:
		for side: String in ["west", "east"]:
			var id := "clyde_" + family + "_handrail_" + side
			var rail = lines.get(id)
			check.call(rail != null and rail.is_valid and rail.kind == "rail",
				"surface audit: visible bridge handrail is grindable " + family + " " + side)
			if rail != null and family != "safe":
				var bounded := true
				for at: Vector3 in rail.points: bounded = bounded and (at.z <= 94.001 if family == "north" else at.z >= 101.999)
				check.call(bounded, "surface audit: broken bridge rail cannot bridge the water gap " + family + " " + side)
	var pockets: Array = []
	for definition: Dictionary in world.get_skate_feature_definitions():
		if definition.id in ["clyde_quay_practice","kelvingrove_promenade_practice"]: pockets.append(definition)
	check.call(pockets.size() == 2 and tree.get_nodes_in_group("skate_transitions").size() >= 2,
		"surface audit: existing quay and park connector each have a real transition practice pocket")
	for pocket: Dictionary in pockets:
		var supported := true
		var clear := true
		var points: PackedVector3Array = pocket.approach
		for step in 16:
			var at := points[0].lerp(points[1], float(step) / 16.0)
			var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.2, at - Vector3.UP * 0.4, 1)
			var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
			supported = supported and not hit.is_empty() and absf(hit.position.y - at.y) < 0.06
			clear = clear and _clear_capture(world, at, at)
		check.call(supported and clear and points[0].distance_to(points[1]) >= 10.0,
			"surface audit: ten-metre-plus transition approach and landing are truly supported and clear " + pocket.id)
	# Native side probes prove representative tagged masonry is real, finite
	# architecture, rather than a visual-only plane or an infinite metadata wall.
	var wall := world.get_node("RecordingAlcoveBack") as StaticBody3D
	var side_hit := world.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(119,2.85,-37.5),Vector3(119,2.85,-39.5),1))
	check.call(wall.get_meta("wallrideable",false) and side_hit.get("collider") == wall and absf(side_hit.normal.z) > 0.99,
		"surface audit: representative wallride masonry has the expected real vertical side face")
	var retaining := world.get_node("CivicForecourt") as StaticBody3D
	var retaining_hit := world.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(15,5.35,-106.8),Vector3(15,5.35,-108.5),1))
	check.call(retaining.get_meta("wallrideable",false) and retaining_hit.get("collider") == retaining and absf(retaining_hit.normal.z) > 0.99,
		"surface audit: exposed convex retaining masonry supports wallrides with a real vertical face")
	# A new raised deck must not sit above the old low-lying perimeter fence.
	# Test the actual swept capsule from apron and ordinary deck-ollie heights.
	for height: float in [6.0,10.0]:
		check.call(not _clear_capture(world,Vector3(-100,height,-139.8),Vector3(-100,height,-145)),
			"surface audit: visible park perimeter contains the new terrace at rider height " + str(height))


static func _clear_capture(world: Node3D, from: Vector3, to: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, from + Vector3.UP * 0.98)
	query.motion = to - from
	query.collision_mask = 1
	query.margin = 0.01
	var space := world.get_world_3d().direct_space_state
	if not space.intersect_shape(query).is_empty(): return false
	var cast := space.cast_motion(query)
	if cast.size() != 2 or cast[0] < 0.9999: return false
	query.transform.origin = to + Vector3.UP * 0.98
	query.motion = Vector3.ZERO
	return space.intersect_shape(query).is_empty()
