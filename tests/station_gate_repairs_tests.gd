extends RefCounted
## Exact construction witnesses from PT24-06/27. Native gate traversal and
## late-entry safety remain in RemainingFeatureTests; these check display
## ownership and the real installed shortcut's two supported destinations.

const Halfpipe = preload("res://game/levels/halfpipe_feature.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var halfpipe: Node3D = game.world.find_child("StationConcourseHalfpipe", true, false)
	check.call(is_instance_valid(halfpipe), "PT24-06: the installed station halfpipe witness exists")
	if is_instance_valid(halfpipe):
		var flat: StaticBody3D = halfpipe.find_child("ConnectedFlatBottom", true, false)
		check.call(is_instance_valid(flat) and flat.find_children("*", "MeshInstance3D", true, false).is_empty()
			and flat.find_children("*", "CollisionShape3D", true, false).size() == 1,
			"PT24-06: station flat preserves native support and has no duplicate coplanar display")
		var floor: StaticBody3D = game.world.get_node("CentralStationFloor")
		var native_supported := true
		var visible_supported := true
		for x: float in [-62.4, -60.7, -58.3]:
			for z: float in [31.7, 34.3, 38.1]:
				var at := Vector3(x, 2.0, z)
				var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.15, at - Vector3.UP * 0.15, 1))
				native_supported = native_supported and not hit.is_empty() and absf(Vector3(hit.position).y - 2.0) < 0.002
				visible_supported = visible_supported and _top_covers(floor, at)
		check.call(native_supported and visible_supported,
			"PT24-06: nine off-centre native and triangle samples retain the original flush station paving")
	var standalone := Halfpipe.new()
	standalone.position = Vector3(900, 0, 900)
	tree.root.add_child(standalone)
	var standalone_flat := standalone.find_child("ConnectedFlatBottom", true, false)
	check.call(is_instance_valid(standalone_flat)
		and standalone_flat.find_children("*", "MeshInstance3D", true, false).size() == 1,
		"PT24-06: a standalone halfpipe still supplies its own visible flat by default")
	standalone.queue_free()
	var spine: Node3D = game.world.get_node("StationWestSpine")
	var space := spine.get_world_3d().direct_space_state
	var runouts_supported := true
	var runouts_clear := true
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	for direction: float in [-1.0, 1.0]:
		for metre: int in range(3, 19):
			var at := Vector3(-110.0 + direction * metre, 2.0, 35.0)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(
				at + Vector3.UP * 0.12, at - Vector3.UP * 0.12, 1))
			runouts_supported = runouts_supported and not hit.is_empty() \
				and absf(Vector3(hit.position).y - 2.0) < 0.002
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.collision_mask = 1
			query.margin = 0.001
			query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.88)
			runouts_clear = runouts_clear and space.intersect_shape(query).is_empty()
	check.call(spine.global_position.is_equal_approx(Vector3(-110, 2, 35))
		and absf(spine.global_basis.z.dot(Vector3.RIGHT)) > 0.999
		and runouts_supported and runouts_clear,
		"PT24-11: the same station spine now has two supported clear east-west runouts with over fifteen metres beyond each toe")
	var gate: Node3D = game.feature_hub.gate
	var route: Dictionary = gate.route_definition()
	var points: PackedVector3Array = route.points
	var destinations_supported := points.size() == 3
	for endpoint: int in [0, 2]:
		if points.size() < 3: break
		var at := points[endpoint]
		var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.15, at - Vector3.UP * 0.15, 1))
		destinations_supported = destinations_supported and not hit.is_empty() \
			and absf(Vector3(hit.position).y - at.y) < 0.01
	check.call(route.id == "service_gate_shortcut" and destinations_supported
		and route.destinations == PackedStringArray(["North station street", "South station street"])
		and points[0].z < gate.global_position.z and points[-1].z > gate.global_position.z,
		"PT24-27: unchanged shortcut ID connects supported north and south station streets")
	var sign: Label3D = gate.get_node("ActivitySign")
	check.call(sign.text.contains("NORTH STREET") and sign.text.contains("SOUTH STREET")
		and sign.pixel_size <= 0.0041 and not sign.no_depth_test
		and sign.billboard == BaseMaterial3D.BILLBOARD_ENABLED,
		"PT24-27: one compact depth-tested sign explains both destinations from either approach")
	var prompt: String = game.feature_hub.gate_prompt(gate.global_position + Vector3.FORWARD)
	check.call(prompt.contains("SHORTCUT") and prompt.contains("NORTH") and prompt.contains("SOUTH")
		and not prompt.contains("[X]"),
		"PT24-27: HUD action describes the route and leaves live input binding to the normal HUD")
	await tree.process_frame


static func _top_covers(body: StaticBody3D, at: Vector3) -> bool:
	for visual: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		if not visual.is_visible_in_tree() or visual.mesh == null: continue
		var vertices: PackedVector3Array = visual.mesh.get_faces()
		for index: int in range(0, vertices.size(), 3):
			var a := visual.to_global(vertices[index])
			var b := visual.to_global(vertices[index + 1])
			var c := visual.to_global(vertices[index + 2])
			if absf(a.y - at.y) > 0.002 or absf(b.y - at.y) > 0.002 or absf(c.y - at.y) > 0.002: continue
			if Geometry2D.point_is_inside_triangle(Vector2(at.x, at.z), Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)):
				return true
	return false
