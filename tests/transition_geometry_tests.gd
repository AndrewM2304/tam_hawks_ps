extends RefCounted
## Shared-sample geometry and actual physical support, independent of movement.

const Park = preload("res://game/levels/transition_park.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	var fixture := Node3D.new()
	fixture.name = "TransitionGeometryFixture"
	fixture.transform = Transform3D(Basis(Vector3.UP, 0.23), Vector3(160, 3, -120))
	tree.root.add_child(fixture)
	var features: Array[Dictionary] = Park.build(fixture, {})
	await tree.physics_frame
	await tree.physics_frame
	check.call(features.size() == 3, "transition geometry: one quarter and both half-pipe sides are published")
	for feature: Dictionary in features:
		var frame: Transform3D = feature.transform
		var body: StaticBody3D = feature.body
		check.call(feature.has_all(["id", "transform", "radius", "width", "angle", "body", "coping_points"])
			and frame == body.global_transform and frame.basis.is_conformal()
			and absf(frame.basis.determinant() - 1.0) < 0.0001,
			"transition geometry: " + feature.id + " exposes a unit world-space contact frame")
		check.call(body.get_meta("transition_id") == feature.id and body.collision_layer == 1
			and absf(feature.radius - 3.2) < 0.0001 and absf(feature.width - 10.0) < 0.0001
			and absf(feature.angle - PI * 0.5) < 0.0001,
			"transition geometry: " + feature.id + " is a physical tagged 90-degree transition")
		var mesh: ArrayMesh = body.get_node("CurvedConcrete").mesh
		var shape: ConcavePolygonShape3D = body.get_node("MatchingCurveCollision").shape
		check.call(shape.get_faces() == mesh.get_faces() and not shape.backface_collision,
			"transition geometry: " + feature.id + " collision uses every visible front-face triangle exactly")
		var arrays: Array = mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var valid := true
		var max_step := 0.0
		for index in range(0, indices.size(), 3):
			var a := vertices[indices[index]]
			var b := vertices[indices[index + 1]]
			var c := vertices[indices[index + 2]]
			var cross := (b - a).cross(c - a)
			valid = valid and a.is_finite() and b.is_finite() and c.is_finite()
			valid = valid and cross.length() > 0.0001 and cross.dot(normals[indices[index]]) < 0.0
		for index in range(0, 2 * Park.SEGMENTS, 2):
			max_step = maxf(max_step, vertices[index].distance_to(vertices[index + 2]))
		check.call(valid and max_step <= 0.112,
			"transition geometry: " + feature.id + " has finite correctly wound samples no more than 2 degrees apart")
		# The exact toe is a shared boundary with the quay/bottom rather than a
		# guaranteed hit on this open triangle edge; sample inside its first face.
		for degrees: float in [1.0, 20.0, 44.0, 70.0, 88.0]:
			var theta := deg_to_rad(degrees)
			var local := Vector3(0.7, feature.radius * (1.0 - cos(theta)), -feature.radius * sin(theta))
			var normal := frame.basis * Vector3(0, cos(theta), sin(theta))
			var at := frame * local
			var hit := _ray(fixture, at + normal * 0.2, at - normal * 0.2)
			check.call(not hit.is_empty() and hit.collider == body
				and hit.position.distance_to(at) < 0.002
				and hit.normal.dot(normal) > 0.999,
				"transition geometry: " + feature.id + " actual collision supports " + str(degrees) + " degrees")
		var lip: Vector3 = frame * Vector3(0, feature.radius, -feature.radius)
		var coping: PackedVector3Array = feature.coping_points
		check.call(coping.size() == 2 and absf(coping[0].distance_to(coping[1]) - feature.width) < 0.0001
			and ((coping[0] + coping[1]) * 0.5).distance_to(lip + frame.basis.y * Park.COPING_RADIUS) < 0.0001,
			"transition geometry: " + feature.id + " publishes the visible coping top in world metres")
		var deck_at: Vector3 = frame * Vector3(0, feature.radius, -feature.radius - 1)
		var deck := _ray(fixture, deck_at + Vector3.UP, deck_at - Vector3.UP)
		check.call(not deck.is_empty() and deck.collider.name == "SupportedDeck"
			and deck.position.distance_to(deck_at) < 0.001,
			"transition geometry: " + feature.id + " raised deck has matching physical support")
	var west: Transform3D = features[1].transform
	var east: Transform3D = features[2].transform
	check.call((west.basis * Vector3.FORWARD).dot(east.basis * Vector3.FORWARD) < -0.999
		and absf(west.origin.distance_to(east.origin) - 8.0) < 0.0001,
		"transition geometry: half-pipe sides oppose across an eight-metre flat bottom")
	var bottom_at := fixture.to_global(Vector3(-22, 2.006, 61.5))
	var bottom := _ray(fixture, bottom_at + Vector3.UP, bottom_at - Vector3.UP)
	check.call(not bottom.is_empty() and bottom.collider.name == "HalfPipeFlatBottom"
		and bottom.position.distance_to(bottom_at) < 0.001,
		"transition geometry: half-pipe bottom has real visible flat collision support")
	var access_from := fixture.to_global(Vector3(-22, 2.4, 68))
	var access_to := fixture.to_global(Vector3(-22, 2.4, 60))
	check.call(_ray(fixture, access_from, access_to).is_empty(),
		"transition geometry: quay approach enters the open half-pipe bottom without a side wall")
	var back_theta := deg_to_rad(44.0)
	var back_local := Vector3(0.7, Park.RADIUS * (1.0 - cos(back_theta)), -Park.RADIUS * sin(back_theta))
	var front_normal: Vector3 = features[0].transform.basis * Vector3(0, cos(back_theta), sin(back_theta))
	var back_at: Vector3 = features[0].transform * back_local
	check.call(_ray(fixture, back_at - front_normal * 0.1, back_at + front_normal * 0.1).is_empty(),
		"transition geometry: back-facing curve cannot masquerade as front support")
	fixture.queue_free()
	await tree.physics_frame


static func _ray(fixture: Node3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.hit_back_faces = false
	return fixture.get_world_3d().direct_space_state.intersect_ray(query)
