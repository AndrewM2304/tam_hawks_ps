extends RefCounted
## Independently fixed river-edge witnesses: native support and displayed
## paving/coping ownership are checked separately, including inherited cuts.
const Repairs = preload("res://game/levels/pt24_render_repairs.gd")
const Surface = preload("res://game/levels/outdoors/surface_builder.gd")
const Boundary = preload("res://game/levels/exploration_boundary.gd")
const Terrain = preload("res://game/levels/core_terrain.gd")


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
	_c02_world(world,check)
	await _c02_fixture(tree,check)


static func _c02_world(world: Node3D,check: Callable) -> void:
	var civic: StaticBody3D = world.get_node("GeorgeSquareFloor")
	var civic_faces := _level_faces(world,civic)
	var asphalt := PackedVector3Array()
	for body: Node in world.get_children():
		if body is StaticBody3D and body.get_meta("art_label","") == "CivicBackStreet":
			asphalt.append_array(_level_faces(world,body))
	var civic_owned := absf(_plane_area(civic_faces,1,4)-5100.0)<0.01
	for x: float in [35.2,35.5,35.8]:
		for z: float in [-85,-80,-75]:
			var at := Vector3(x,4,z)
			civic_owned = civic_owned and not _on_plane(civic_faces,at,1,Vector2i(0,2)) \
				and _on_plane(asphalt,at,1,Vector2i(0,2))
	for z: float in [-85,-80,-75]:
		civic_owned = civic_owned and _on_plane(civic_faces,Vector3(34.8,4,z),1,Vector2i(0,2))
	check.call(civic_owned,
		"PT24-01: fixed east civic seam removes exactly12 square metres of tile/asphalt overlap with real asphalt ownership and adjacent paving retained")
	var street: StaticBody3D = world.get_node("CentralSouthStreet")
	var street_faces := _level_faces(world,street)
	var building_faces := PackedVector3Array()
	for building: Node in world.get_children():
		if building is Node3D and building.position.distance_to(Vector3(-41,0,0))<0.0001 and building.has_node("Facade"):
			building_faces = _level_faces(world,building.get_node("Facade"))
	var exchange_owned := absf(_plane_area(street_faces,2,15)-50.4)<0.01
	for x: float in [-46.5,-44,-40,-36]:
		for weight: float in [0.25,0.5,0.75]:
			var at := Vector3(x,(-35.0-x)*2.0/15.0*weight,15)
			exchange_owned = exchange_owned and not _on_plane(street_faces,at,2,Vector2i(0,1)) \
				and _on_plane(building_faces,at,2,Vector2i(0,1))
		for y: float in [-2,-1,-0.1]:
			exchange_owned = exchange_owned and _on_plane(street_faces,Vector3(x,y,15),2,Vector2i(0,1))
	check.call(exchange_owned,
		"PT24-10: exact9.6 square metre road-wall wedge belongs to the actual tenement while the exposed below-ground street foundation remains")
	var park: Node3D = world.get_node("OutdoorRoutes/KelvingroveSunkenSkatepark")
	var upper := _level_faces(park,park.get_node("ExcavatedUpperDeck"))
	var arrival := _level_faces(park,park.get_node("EastArrivalDeck"))
	var park_owned := true
	var north_count := 0
	var arrival_count := 0
	for body: Node in park.get_children():
		if not body is StaticBody3D:continue
		var size := _box_size(body)
		if absf(body.position.z-3.425)<0.0001 and absf(size.z-0.15)<0.0001 and absf(size.y-1.5)<0.0001:
			north_count += 1
			var faces := _level_faces(park,body)
			for weight: float in [-0.3,0,0.3]:
				var at := Vector3(body.position.x+size.x*weight,0,3.425)
				park_owned = park_owned and not _on_plane(faces,at,1,Vector2i(0,2)) \
					and _on_plane(upper,at,1,Vector2i(0,2)) \
					and _on_plane(faces,Vector3(at.x,-0.7,3.5),2,Vector2i(0,1))
		elif absf(body.position.x-17.55)<0.0001 and absf(size.x-0.1)<0.0001 and absf(size.y-1.5)<0.0001:
			arrival_count += 1
			var faces := _level_faces(park,body)
			for weight: float in [-0.3,0,0.3]:
				var z: float = body.position.z+size.z*weight
				var top := Vector3(17.55,0,z)
				var side := Vector3(17.5,-0.7,z)
				park_owned = park_owned and not _on_plane(faces,top,1,Vector2i(0,2)) \
					and _on_plane(arrival,top,1,Vector2i(0,2)) \
					and not _on_plane(faces,side,0,Vector2i(2,1)) \
					and _on_plane(arrival,side,0,Vector2i(2,1))
	check.call(park_owned and north_count==5 and arrival_count==2,
		"PT24-09: five retained north walls keep exposed fronts while actual paving/arrival deck singly own all covered caps and two duplicated west faces")
	var supported := true
	for local: Vector3 in [Vector3(35.5,4,-80),Vector3(34.8,4,-80),Vector3(-40,2.0/3.0,22)]:
		var at := world.to_global(local)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.1,at-Vector3.UP*0.1,1))
		supported = supported and not hit.is_empty() and absf(Vector3(hit.position).y-at.y)<0.001 \
			and absf(world.get_ground_height(at)-at.y)<0.001
	check.call(supported,
		"C02 ownership: civic cross-street and Exchange graded road retain their exact native/public top supports")
	var report: Dictionary = world.get_meta("pt24_render_repairs").covered_faces
	check.call(absf(report.civic.removed_area_m2-12)<0.01 and absf(report.exchange.removed_area_m2-9.6)<0.01 \
		and report.park_removed_triangles==18 and report.after_triangles<=report.before_triangles,
		"C02 ownership: fixed duplicate areas and eighteen removed park triangles fit the zero-extra-draw/triangle budget")
	print("PT24_C02_OWNERSHIP ",report)


static func _c02_fixture(tree: SceneTree,check: Callable) -> void:
	var fixture := Node3D.new()
	fixture.position = Vector3(500,50,500)
	tree.root.add_child(fixture)
	var terrain := Terrain.new()
	var material := StandardMaterial3D.new()
	var civic := terrain.add_patch(fixture,"GeorgeSquareFloor",Rect2(-35,-128,71,72),Vector4(4,4,4,4),material)
	var street := terrain.add_patch(fixture,"CentralSouthStreet",Rect2(-50,15,15,14),Vector4(2,0,0,2),material)
	var outdoors := Node3D.new();outdoors.name="OutdoorRoutes";fixture.add_child(outdoors)
	var park := Node3D.new();park.name="KelvingroveSunkenSkatepark";park.position=Vector3(-207.5,14.5,-187.5);outdoors.add_child(park)
	for span: Vector2 in [Vector2(-20,-14.328380421),Vector2(-8.671619579,-3.5),Vector2(-0.5,2),
			Vector2(5,6.994048234),Vector2(14.005951766,20)]:
		_fixture_box(park,Vector3((span.x+span.y)*0.5,-0.75,3.425),Vector3(span.y-span.x,1.5,0.15),material)
	for span: Vector2 in [Vector2(3.5,6.5),Vector2(10.5,15)]:
		_fixture_box(park,Vector3(17.55,-0.75,(span.x+span.y)*0.5),Vector3(0.1,1.5,span.y-span.x),material)
	var before := _physics_snapshot(fixture)
	var civic_native: ConvexPolygonShape3D = civic.get_child(0).shape
	var street_native: ConvexPolygonShape3D = street.get_child(0).shape
	var civic_vertices := civic_native.points.to_byte_array()
	var street_vertices := street_native.points.to_byte_array()
	var civic_faces := _level_faces(fixture,civic)
	var street_faces := _level_faces(fixture,street)
	var retained_civic := _except_plane(civic_faces,1,4)
	var retained_street := _except_plane(street_faces,2,15)
	check.call(absf(_plane_area(civic_faces,1,4)-5112)<0.01 and absf(_plane_area(street_faces,2,15)-60)<0.01,
		"C02 ownership: independent original civic/Exchange fixture exhibits the exact5112 and60 square metre pre-repair planes")
	Repairs._additional_repairs(fixture)
	check.call(before==_physics_snapshot(fixture) and civic_vertices==civic_native.points.to_byte_array() \
		and street_vertices==street_native.points.to_byte_array(),
		"C02 ownership: every original fixture body/shape/transform and convex vertex byte remains identical")
	check.call(retained_civic==_except_plane(_level_faces(fixture,civic),1,4) \
		and retained_street==_except_plane(_level_faces(fixture,street),2,15) \
		and Repairs._first_display(civic).material_override==material \
		and Repairs._first_display(street).material_override==material,
		"C02 ownership: unrelated side/bottom/top triangles and original material resources remain byte-identical")
	fixture.queue_free()
	await tree.process_frame


static func _fixture_box(parent: Node3D,at: Vector3,size: Vector3,material: Material) -> void:
	var body := StaticBody3D.new();body.position=at;parent.add_child(body)
	var collision := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size=size;collision.shape=shape;body.add_child(collision)
	var mesh := MeshInstance3D.new();var box := BoxMesh.new();box.size=size;mesh.mesh=box;mesh.material_override=material;body.add_child(mesh)


static func _physics_snapshot(root: Node3D) -> Array:
	var records: Array = []
	for body: Node3D in root.find_children("*","StaticBody3D",true,false):
		for child: Node in body.get_children():
			if not child is CollisionShape3D:continue
			var data: Variant = child.shape.points.to_byte_array() if child.shape is ConvexPolygonShape3D else child.shape.size
			records.append([str(root.get_path_to(body)),body.transform,body.collision_layer,body.collision_mask,
				child.transform,child.disabled,child.shape.get_class(),data])
	return records


static func _box_size(body: Node3D) -> Vector3:
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:return child.shape.size
	return Vector3.ZERO


static func _level_faces(reference: Node3D,body: Node3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	for display: Node in body.get_children():
		if display is MeshInstance3D and display.is_visible_in_tree():
			for point: Vector3 in display.mesh.get_faces():result.append(reference.to_local(display.to_global(point)))
	return result


static func _except_plane(faces: PackedVector3Array,axis: int,plane: float) -> PackedVector3Array:
	var result := PackedVector3Array()
	for index: int in range(0,faces.size(),3):
		if absf(faces[index][axis]-plane)<0.00005 and absf(faces[index+1][axis]-plane)<0.00005 and absf(faces[index+2][axis]-plane)<0.00005:continue
		result.append_array(PackedVector3Array([faces[index],faces[index+1],faces[index+2]]))
	return result


static func _plane_area(faces: PackedVector3Array,axis: int,plane: float) -> float:
	var area := 0.0
	for index: int in range(0,faces.size(),3):
		if absf(faces[index][axis]-plane)<0.00005 and absf(faces[index+1][axis]-plane)<0.00005 and absf(faces[index+2][axis]-plane)<0.00005:
			area += (faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).length()*0.5
	return area


static func _on_plane(faces: PackedVector3Array,point: Vector3,axis: int,project: Vector2i) -> bool:
	for index: int in range(0,faces.size(),3):
		var a := faces[index];var b := faces[index+1];var c := faces[index+2]
		if maxf(absf(a[axis]-point[axis]),maxf(absf(b[axis]-point[axis]),absf(c[axis]-point[axis])))>0.0001:continue
		var ab := Vector2(b[project.x]-a[project.x],b[project.y]-a[project.y])
		var ac := Vector2(c[project.x]-a[project.x],c[project.y]-a[project.y])
		var rel := Vector2(point[project.x]-a[project.x],point[project.y]-a[project.y])
		var determinant := ab.cross(ac)
		if absf(determinant)<0.000001:continue
		var wb := rel.cross(ac)/determinant;var wc := ab.cross(rel)/determinant
		if minf(1-wb-wc,minf(wb,wc))>=-0.00001:return true
	return false


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
