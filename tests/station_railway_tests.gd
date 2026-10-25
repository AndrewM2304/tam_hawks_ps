extends RefCounted
## The railway candidate is built in a separate native world position. Normal
## world inventories and default performance admission remain unchanged.

const Railway = preload("res://game/levels/station_railway.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	check.call(game.world.find_child("StationRailway", true, false) == null,
		"PT24-15: ordinary world does not bypass the railway's pending rendering admission")
	var preview := Node3D.new()
	preview.name = "IsolatedStationRailwayWitness"
	preview.position = Vector3(1500, 0, 1500)
	tree.root.add_child(preview)
	for z: float in [-26.0, 26.0]:
		var old := Node3D.new()
		old.position = Vector3(-136, 2, z)
		var facade := StaticBody3D.new()
		facade.name = "Facade"
		old.add_child(facade)
		preview.add_child(old)
	var railway := Railway.new()
	railway.build(preview, game.world._materials)
	railway.set_physics_process(false)
	check.call(railway.built and railway.report.removed_facades == 2
		and railway.report.budget_pass and railway.report.surfaces <= 8
		and railway.report.triangles <= 3000 and railway.report.bodies <= 6
		and railway.report.shapes <= 20 and railway.report.new_materials == 0
		and railway.report.new_textures == 0 and railway.report.new_lights == 0,
		"PT24-15: enclosed station replaces two old facade groups within its predeclared candidate budget")
	var stable_nodes := railway.find_children("*", "Node", true, false).size()
	var train_meshes: Array[Node] = railway.train.find_children("*", "MeshInstance3D", true, false)
	var triangle_total := 0
	var geometry_bounds := AABB()
	var first := true
	for visual: MeshInstance3D in train_meshes:
		triangle_total += visual.mesh.get_faces().size() / 3
		var bounds := visual.mesh.get_aabb()
		geometry_bounds = bounds if first else geometry_bounds.merge(bounds)
		first = false
	check.call(train_meshes.size() == 3 and triangle_total > 500
		and geometry_bounds.position.z >= -Railway.TRAIN_HALF_LENGTH
		and geometry_bounds.end.z <= Railway.TRAIN_HALF_LENGTH
		and railway.train.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"PT24-15: complete bounded two-coach geometry is scenic and has no moving collision or false grind tracks")
	var wrapped_hidden := true
	var moving := false
	var previous_z: float = railway.train.position.z
	for sample: int in range(1600):
		railway.tick(0.02)
		var current_z: float = railway.train.position.z
		if current_z < previous_z:
			wrapped_hidden = wrapped_hidden and absf(previous_z) > 51.0 \
				and railway.is_train_concealed()
		moving = moving or not railway.is_train_concealed()
		previous_z = current_z
	check.call(wrapped_hidden and moving and railway.find_children("*", "Node", true, false).size() == stable_nodes,
		"PT24-15: repeated complete train loops wrap only fully inside opaque tunnels without constructing per-frame nodes")
	railway.reset_run()
	check.call(railway.elapsed == 0.0 and railway.train.position.is_equal_approx(Vector3(-136, 8.36, -52))
		and railway.is_train_concealed(),
		"PT24-15: reset restores the same concealed railway phase")
	var reset_position: Vector3 = railway.train.position
	for invalid: float in [0.0, -1.0, NAN, INF]:
		railway.tick(invalid)
	check.call(railway.train.position.is_equal_approx(reset_position),
		"PT24-15: invalid tick deltas cannot corrupt train transforms")
	# Native lower-route clearance and backed rail boundary are independently
	# specified here, rather than read from the enclosure generator.
	await tree.physics_frame
	await tree.process_frame
	var space := preview.get_world_3d().direct_space_state
	var clear := true
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.30
	capsule.height = 1.8
	for x: float in [-144, -140, -136, -132, -128]:
		for z: float in [-7.5, 0.0, 7.5]:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.collision_mask = 1
			query.transform = Transform3D(Basis.IDENTITY, preview.to_global(Vector3(x, 2.95, z)))
			clear = clear and space.intersect_shape(query).is_empty()
	check.call(clear, "PT24-15: fifteen real capsule volumes preserve the complete lower park passage")
	var enclosure := true
	for z: float in [-60, -38, -20, 0, 20, 38, 60]:
		var from := preview.to_global(Vector3(-128, 10, z))
		var to := preview.to_global(Vector3(-143, 10, z))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
		enclosure = enclosure and not hit.is_empty()
	check.call(enclosure, "PT24-15: seven native boundaries keep the scenic tracks safely separate from playable station routes")
	var supported := true
	for z: float in [-52, -26, 0, 26, 52]:
		var from := preview.to_global(Vector3(-136, 8.3, z))
		var to := preview.to_global(Vector3(-136, 8.0, z))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
		supported = supported and not hit.is_empty() and absf(preview.to_local(hit.position).y - 8.2) < 0.002
	check.call(supported, "PT24-15: grounded wing and bridge deck support the entire elevated railway through the park opening")
	# Pausable scene-tree processing, not wall-clock timers, owns scenic motion.
	railway.set_physics_process(true)
	var paused_before: Vector3 = railway.train.position
	tree.paused = true
	await tree.process_frame
	await tree.process_frame
	check.call(railway.train.position.is_equal_approx(paused_before),
		"PT24-15: ordinary pause freezes the train without a background timer")
	tree.paused = false
	railway.set_physics_process(false)
	preview.queue_free()
	await tree.process_frame
