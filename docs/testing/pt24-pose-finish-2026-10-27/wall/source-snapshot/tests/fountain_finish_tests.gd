extends RefCounted
## PT24-26: the original shared water finish must not alter basin/contact data.

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	await tree.physics_frame
	var world: Node3D = game.world
	var body: StaticBody3D = world.get_node("ExchangeFountain")
	var water: MeshInstance3D = body.get_node("FountainWater")
	var basin: MeshInstance3D = body.get_node("FountainBasin")
	var river: MeshInstance3D = world.get_node("OutdoorRoutes/ClydeWater")
	var pond: MeshInstance3D = world.get_node("KelvingrovePond/PondWater")
	check.call(water.material_override is ShaderMaterial and water.material_override == river.material_override
		and water.material_override == pond.material_override,
		"PT24 fountain finish: fountain, pond and river share one existing water material")
	var water_mesh := water.mesh as CylinderMesh
	var basin_mesh := basin.mesh as CylinderMesh
	check.call(body.position == Vector3(0,0,10) and water.position == Vector3(0,.55,0)
		and water_mesh.radial_segments == 64 and water_mesh.rings == 0
		and is_equal_approx(water_mesh.top_radius,5.96) and is_equal_approx(water_mesh.bottom_radius,5.96)
		and is_equal_approx(water_mesh.height,.01) and is_equal_approx(basin_mesh.top_radius,6.2),
		"PT24 fountain finish: existing circular water mesh, height and coping margin remain exact")
	var contained := true
	var vertices := 0
	for p: Vector3 in water_mesh.get_faces():
		vertices += 1
		contained = contained and Vector2(p.x,p.z).length() < 5.961 and p.y <= .00501 and p.y >= -.00501
	check.call(contained and vertices == 768,
		"PT24 fountain finish: all 768 original water face vertices retain their fixed basin footprint")
	var shapes: Array[CollisionShape3D] = []
	for child: Node in body.get_children():
		if child is CollisionShape3D: shapes.append(child)
	check.call(shapes.size() == 2 and shapes[0].shape is CylinderShape3D
		and is_equal_approx(shapes[0].shape.radius,6.2) and is_equal_approx(shapes[0].shape.height,.55)
		and is_equal_approx(shapes[0].position.y,.275)
		and shapes[1].shape is CylinderShape3D and is_equal_approx(shapes[1].shape.radius,.7)
		and is_equal_approx(shapes[1].shape.height,2.7) and is_equal_approx(shapes[1].position.y,1.35),
		"PT24 fountain finish: both original basin and pedestal native shapes remain exact")
	var native := true
	var safe := true
	var space := world.get_world_3d().direct_space_state
	for sample: int in 32:
		var angle := float(sample) * TAU / 32.0
		var at := Vector3(cos(angle)*5.4,1.4,10+sin(angle)*5.4)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at,at-Vector3.UP*1.3,1))
		native = native and not hit.is_empty() and hit.collider == body and absf(hit.position.y-.55)<.001
		safe = safe and not world.get_recovery_position(Vector3(at.x,.55,at.z)).is_finite()
	check.call(native,"PT24 fountain finish: 32 native basin contacts keep their unchanged .55m support")
	check.call(safe,"PT24 fountain finish: the existing fountain has no new water-recovery trigger")
	var guides: Array = world.get_grind_lines().filter(func(line): return line.id == "Grind_Coping_ExchangeFountain")
	var guide_ok := guides.size() == 1
	if guide_ok:
		var line = guides[0]
		guide_ok = line.is_valid and line.is_loop and line.kind == "coping" and line.points.size() == 65
		for point: Vector3 in line.points:
			guide_ok = guide_ok and absf(point.y-.92)<.00001 and absf(Vector2(point.x,point.z-10).length()-6.2)<.00001
	check.call(guide_ok,"PT24 fountain finish: original closed coping ID and all 65 authored guide points remain")
