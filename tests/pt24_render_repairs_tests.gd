extends RefCounted
## Independently fixed river-edge witnesses: native support and displayed
## paving/coping ownership are checked separately, including inherited cuts.
const Repairs = preload("res://game/levels/pt24_render_repairs.gd")
const Surface = preload("res://game/levels/outdoors/surface_builder.gd")
const Boundary = preload("res://game/levels/exploration_boundary.gd")


static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	var north := world.get_node("OutdoorRoutes/ClydeNorthQuay") as StaticBody3D
	var south := world.get_node("OutdoorRoutes/ClydeSouthQuay") as StaticBody3D
	var north_faces := _faces(north)
	var south_faces := _faces(south)
	check.call(north_faces.size() == 6 and absf(_area(north_faces) - 3774.0) < 0.01,
		"PT24-21: north quay keeps its full inland paving while stone owns exactly136 square metres of coplanar edge")
	var owned := true
	for x: float in [-83.0, -67.0, -40.0, -4.0, 25.0, 60.0, 82.0]:
		for z: float in [77.3, 77.65, 77.9]:
			owned = owned and not _covers(north_faces, Vector2(x, z)) \
				and _stone_covers(world,"NorthEmbankment",Vector2(x,z))
		for z: float in [55.1, 69.0, 76.9]:
			owned = owned and _covers(north_faces, Vector2(x, z))
	for x: float in [-37.0, -25.0, -7.0, 20.0, 42.0, 74.0]:
		for z: float in [116.1, 116.4, 116.7]:
			owned = owned and not _covers(south_faces, Vector2(x, z)) \
				and _stone_covers(world,"SouthEmbankment",Vector2(x,z))
		for z: float in [117.0, 120.0, 123.0]:
			owned = owned and _covers(south_faces, Vector2(x, z))
	check.call(owned,
		"PT24-21: fixed samples on both quays have one paving/stone owner on each side of their exact seam")
	var supported := true
	# The south stone strip passes below the safe bridge's final 17m grade.
	# Its highest native/public support is the deck, rather than the Y2 quay.
	var bridge_height := 2.0+(122.0-116.4)*1.4/17.0
	for local: Vector3 in [Vector3(-67,2,77.6),Vector3(76,2,77.6),Vector3(-25,bridge_height,116.4),Vector3(60,2,116.4),
			Vector3(-25.4,2,122.315),Vector3(76.298,2,69.859)]:
		var at := world.to_global(local)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(at + Vector3.UP*0.15,at - Vector3.UP*0.15,1))
		supported = supported and not hit.is_empty() and absf(Vector3(hit.position).y - at.y) < 0.001 \
			and absf(world.get_ground_height(at) - at.y) < 0.001
	check.call(supported,
		"PT24-21: exact reported quay/bridge locations and coping strips retain their declared native/public support heights")
	var report: Dictionary = world.get_meta("pt24_render_repairs", {})
	check.call(report.get("after_triangles",INF) <= report.get("before_triangles",-INF) \
		and report.get("duplicate_top_area_m2",0) == 228.0,
		"PT24-21: the display repair removes228 square metres of duplicate faces without increasing triangles")
	check.call(int(report.get("station_plinth_instances",0)) > 0,
		"PT24-12: station north plinth construction removes its overlapping box skins without adding instances")
	await _fixture(tree,check)


static func _fixture(tree: SceneTree, check: Callable) -> void:
	var fixture := Node3D.new()
	fixture.position = Vector3(300,30,300)
	tree.root.add_child(fixture)
	var outdoors := Node3D.new()
	outdoors.name = "OutdoorRoutes"
	fixture.add_child(outdoors)
	var material := StandardMaterial3D.new()
	var height := func(_x: float,_z: float) -> float: return 2.0
	var north := Surface.terrain(outdoors,"ClydeNorthQuay",Rect2(-85,55,170,23),5,height,material)
	var south := Surface.terrain(outdoors,"ClydeSouthQuay",Rect2(-39,116,115,14),5,height,material)
	var boundary := Boundary.build(fixture,"StationNorthBoundary",PackedVector3Array([
		Vector3(-130,2,-41.8),Vector3(-112,2,-41.8),Vector3(-94,2,-41.8)]),material,material)
	var boundary_shape: ConvexPolygonShape3D = boundary.get_child(0).shape
	var boundary_points := boundary_shape.points
	# An unrelated earlier display exclusion stands in for the real bowl/hip
	# excavation. The new coping repair must not reconstruct/fill that patch.
	Surface.trim_visual_rect(south,Rect2(40,125,5,5))
	var native_before := [_native(north),_native(south)]
	var south_area := _area(_faces(south))
	var materials_before := [Repairs._display(north).material_override,Repairs._display(south).material_override]
	Repairs.install(fixture)
	var masonry := boundary.get_node("RetainedMasonry") as MultiMeshInstance3D
	var pieces: Array = masonry.get_meta("pt24_plinth_transforms",[])
	var joined := pieces.size() == 24
	var previous_end := -130.0
	for transform: Transform3D in pieces:
		var half_extent := absf(transform.basis.z.x)*0.5
		joined = joined and absf(transform.origin.x-half_extent-previous_end) < 0.0001 \
			and absf(transform.origin.z+41.8) < 0.0001 and absf(transform.origin.y-2.15) < 0.0001
		previous_end = transform.origin.x+half_extent
	check.call(joined and absf(previous_end+94)<0.0001 and boundary_shape.points == boundary_points,
		"PT24-12: all24 real plinth segments meet exact fixed endpoints with no overlap/gap and unchanged native panel")
	check.call(_native(north) == native_before[0] and _native(south) == native_before[1]
		and north.get_child_count() == 2 and south.get_child_count() == 2,
		"PT24-21: both original native terrain grids and resident shape/mesh counts remain byte-identical")
	check.call(absf(south_area - _area(_faces(south)) - 92.0) < 0.01
		and not _covers(_faces(south),Vector2(42,127))
		and Repairs._display(north).material_override == materials_before[0]
		and Repairs._display(south).material_override == materials_before[1],
		"PT24-21: south cut removes exactly92 square metres, preserves earlier holes and shares the original materials")
	var first_faces := [_faces(north),_faces(south)]
	Repairs.install(fixture)
	check.call(first_faces[0] == _faces(north) and first_faces[1] == _faces(south),
		"PT24-21: repeated installation is idempotent and does not re-triangulate an already-owned seam")
	fixture.queue_free()
	await tree.process_frame


static func _native(body: StaticBody3D) -> PackedVector3Array:
	for child: Node in body.get_children():
		if child is CollisionShape3D:
			return (child.shape as ConcavePolygonShape3D).get_faces()
	return PackedVector3Array()


static func _faces(body: StaticBody3D) -> PackedVector3Array:
	return Repairs._display(body).mesh.get_faces()


static func _area(faces: PackedVector3Array) -> float:
	var area := 0.0
	for index: int in range(0,faces.size(),3):
		area += absf((faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).y)*0.5
	return area


static func _covers(faces: PackedVector3Array, at: Vector2) -> bool:
	for index: int in range(0,faces.size(),3):
		var a := Vector2(faces[index].x,faces[index].z)
		var b := Vector2(faces[index+1].x,faces[index+1].z)
		var c := Vector2(faces[index+2].x,faces[index+2].z)
		if Geometry2D.point_is_inside_triangle(at,a,b,c):return true
	return false


static func _stone_covers(world: Node3D, id: String, at: Vector2) -> bool:
	var body := world.get_node("OutdoorRoutes/" + id) as Node3D
	for child: Node in body.get_children():
		if not child is MeshInstance3D:continue
		var local: PackedVector3Array = child.mesh.get_faces()
		var top := PackedVector3Array()
		for index: int in range(0,local.size(),3):
			var a := world.to_local(child.to_global(local[index]))
			var b := world.to_local(child.to_global(local[index+1]))
			var c := world.to_local(child.to_global(local[index+2]))
			if absf(a.y-2)<0.0001 and absf(b.y-2)<0.0001 and absf(c.y-2)<0.0001:
				top.append_array(PackedVector3Array([a,b,c]))
		if _covers(top,at):return true
	return false
