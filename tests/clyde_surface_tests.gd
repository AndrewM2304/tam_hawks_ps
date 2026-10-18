extends RefCounted
## Actual production triangles, not authored bounds or success metadata.
## The old Clyde/Station coplanar road areas survive in unchanged collision.

const World = preload("res://game/levels/glasgow_square.gd")
const EPS := 0.00001


static func run(tree: SceneTree, check: Callable) -> void:
	var world := World.new()
	world.set_meta(&"render_budget_probe_baseline", true)
	tree.root.add_child(world)
	await tree.physics_frame
	await tree.process_frame
	var outdoors: Node3D = world.get_node("OutdoorRoutes")
	var quay: StaticBody3D = outdoors.get_node("ClydeNorthQuay")
	var quay_faces := _visual_faces(quay)
	var quay_top := _horizontal_triangles(quay_faces, 2.0)
	check.call(not quay_top.is_empty(), "Clyde surface separation: actual quay has its original Y2 paving triangles")
	for id: String in ["ClydeWestApproach", "ClydeEastApproach"]:
		var road: StaticBody3D = outdoors.get_node(id)
		var visual := _visual_faces(road)
		var collision := _collision_faces(road)
		var east := id == "ClydeEastApproach"
		var x := 94.0 if east else -94.0
		var original := _original_faces(east)
		check.call(_same_triangles(collision, original) and road.collision_layer == 1 and road.collision_mask == 0
			and road.get_meta("surface_audio", "") == "asphalt" and _backface_collision(road),
			"Clyde surface separation: full original collision faces/layers/audio/backface support remain " + id)
		var old_overlap := _overlap_area(_horizontal_triangles(collision, 2.0), quay_top)
		var new_overlap := _overlap_area(_horizontal_triangles(visual, 2.0), quay_top)
		check.call(absf(old_overlap - (208.0 if east else 160.0)) < 0.0001,
			"Clyde surface separation: independent intersection detects the original positive-area coplanar counterexample " + id)
		check.call(new_overlap < EPS, "Clyde surface separation: displayed triangles have no positive-area Y2 road/quay overlap " + id)
		var correct_vertices := visual.size() == 6
		for point: Vector3 in visual:
			var expected_y := (point.z - 45.0) * 0.2 if east else 2.0
			correct_vertices = correct_vertices and point.z >= 45.0 - EPS and point.z <= 55.0 + EPS
			correct_vertices = correct_vertices and absf(absf(point.x - x) - 8.0) < EPS and absf(point.y - expected_y) < EPS
		check.call(correct_vertices and absf(_projected_area(visual) - 160.0) < EPS,
			"Clyde surface separation: visible road covers its complete original 16m-wide approach up to Z55 without any height offset " + id)
		var support := true
		for z: float in [50.0, 55.0, 60.0, 64.0]:
			var expected := minf(2.0, (z - 45.0) * 0.2) if east else 2.0
			var at := Vector3(x, expected + 1.0, z)
			var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at, at - Vector3.UP * 2.0, 1))
			support = support and not hit.is_empty() and absf(hit.position.y - expected) < 0.001
			support = support and absf(world.get_ground_height(at) - expected) < 0.001
		check.call(support, "Clyde surface separation: real collision and terrain queries retain original grade and quay support " + id)
	_check_station(world, check)
	check.call(original_physics_inventory(world),
		"Surface separation: original 351 bodies/1863 shapes remain after the identified four-bench 12-body/44-box repair")
	var routes: Array = world.get_route_definitions()
	var published: Dictionary = {}
	for route: Dictionary in routes: published[route.id] = route
	check.call(routes.size() == 48 and published.size() == 48
		and published.has("clyde_north_quay") and not published.clyde_north_quay.requires_jump
		and published.clyde_north_quay.points == PackedVector3Array([
			Vector3(-94,2,45),Vector3(-94,2,67),Vector3(94,2,67),
			Vector3(94,2,55),Vector3(94,0,45)])
		and published.has("merchant_close_cutthrough") and published.merchant_close_cutthrough.points == PackedVector3Array([
			Vector3(-64,2,-30),Vector3(-68,2,-44),Vector3(-69,2.5,-50),Vector3(-61,3.2,-60),
			Vector3(-55,3.5,-65),Vector3(-59,4,-74),Vector3(-59,4,-80)]),
		"Surface separation: 48 unique routes and the original Clyde/Merchant Close points remain unchanged")
	world.free()
	await tree.process_frame


static func original_physics_inventory(world: Node3D) -> bool:
	# Exclude only the authorized, reachable street furniture. A group tag alone
	# cannot hide another body: require all twelve unique anchor/part identities,
	# direct world ownership, normal scenery layers and the actual box counts.
	var anchors := [Vector3(-127,2,28), Vector3(60,0,36), Vector3(29,6,-116), Vector3(29,0,27)]
	var part_shapes := {"StreetBenchSeat":4, "StreetBenchBack":3, "StreetBenchFrame":4}
	var bodies := world.find_children("*", "StaticBody3D", true, false)
	var shapes := world.find_children("*", "CollisionShape3D", true, false)
	var identities: Dictionary = {}
	var bench_shapes: Dictionary = {}
	var bench_bodies := 0
	var valid := true
	for body: StaticBody3D in bodies:
		if not body.is_in_group("street_bench_solids"): continue
		bench_bodies += 1
		var label := str(body.get_meta("art_label", ""))
		var anchor := anchors.find(body.position)
		var identity := str(anchor) + ":" + label
		valid = valid and anchor >= 0 and part_shapes.has(label) and not identities.has(identity)
		valid = valid and body.get_parent() == world and body.basis.is_equal_approx(Basis.IDENTITY)
		valid = valid and body.collision_layer == 1 and body.collision_mask == 0
		identities[identity] = true
		var count := 0
		for child: Node in body.get_children():
			if not child is CollisionShape3D: continue
			count += 1
			bench_shapes[child.get_instance_id()] = true
			valid = valid and child.shape is BoxShape3D and not child.disabled
			valid = valid and child.transform.basis.is_equal_approx(Basis.IDENTITY) and child.position.is_finite()
		valid = valid and count == int(part_shapes.get(label, -1))
	print("PHYSICS_INVENTORY bodies=%d shapes=%d bench_bodies=%d bench_boxes=%d identified=%s" % [
		bodies.size(), shapes.size(), bench_bodies, bench_shapes.size(), valid])
	return valid and identities.size() == 12 and bench_bodies == 12 and bench_shapes.size() == 44 \
		and bodies.size() - bench_bodies == 351 and shapes.size() - bench_shapes.size() == 1863


static func _check_station(world: Node3D, check: Callable) -> void:
	var road: StaticBody3D = world.get_node("MerchantClose0")
	var floor_top := _horizontal_triangles(_visual_faces(world.get_node("CentralStationFloor")), 2.0)
	var expected := PackedVector3Array([Vector3(-60.1539042094,2,-31.0988845116),Vector3(-67.8460957906,2,-28.9011154884),
		Vector3(-71.8805700006,2,-43.0298574999),Vector3(-64.1194299994,2,-44.9701425001)])
	var old_top := PackedVector3Array()
	var prisms := 0
	var original_points := true
	for node: Node in road.get_children():
		if not node is CollisionShape3D: continue
		prisms += 1
		if not node.shape is ConvexPolygonShape3D:
			original_points = false
			continue
		var upper := PackedVector3Array()
		var lower := PackedVector3Array()
		for point: Vector3 in node.shape.points:
			var at: Vector3 = node.global_transform * point
			if absf(at.y - 2.0) < EPS: upper.append(at)
			elif absf(at.y + 3.0) < EPS: lower.append(at)
			else: original_points = false
			var found := false
			for corner: Vector3 in expected:
				if Vector2(at.x,at.z).distance_to(Vector2(corner.x,corner.z)) < 0.00002: found = true
			original_points = original_points and found
		original_points = original_points and upper.size() == 3 and lower.size() == 3
		for at: Vector3 in upper:
			var paired := false
			for below: Vector3 in lower:
				if Vector2(at.x,at.z).distance_to(Vector2(below.x,below.z)) < EPS: paired = true
			original_points = original_points and paired
		old_top.append_array(upper)
	check.call(prisms == 2 and original_points and absf(_projected_area(old_top) - 116.449429) < 0.001,
		"Station surface separation: both original full-height collision prisms retain all authored corners and complete footprint")
	var old_overlap := _overlap_area(_horizontal_triangles(old_top,2.0), floor_top)
	var visible_top := _horizontal_triangles(_visual_faces(road),2.0)
	var visual_faces := PackedVector3Array()
	for triangle: PackedVector2Array in visible_top:
		for at: Vector2 in triangle: visual_faces.append(Vector3(at.x,2,at.y))
	check.call(absf(old_overlap - 99.817594) < 0.001,
		"Station surface separation: actual original prism tops independently expose the 99.8176m2 asphalt/paving counterexample")
	var bound := not visible_top.is_empty()
	for at: Vector3 in visual_faces: bound = bound and at.z <= -42.0 + EPS
	check.call(bound and _overlap_area(visible_top,floor_top) < EPS
		and absf(_projected_area(visual_faces) - 16.631835) < 0.001,
		"Station surface separation: displayed top stops at the real floor edge, preserving the exterior road at Y2 without offsets")
	var supported := true
	for at: Vector3 in [Vector3(-65,2.8,-35),Vector3(-68,2.8,-41),Vector3(-68.5,2.8,-43)]:
		var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at,at-Vector3.UP*1.5,1))
		supported = supported and not hit.is_empty() and absf(hit.position.y-2.0)<0.001 and absf(world.get_ground_height(at)-2.0)<0.001
	check.call(supported, "Station surface separation: original collision and terrain height support remain across the clipped visual seam")


static func _visual_faces(body: Node3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	for node: Node in body.get_children():
		if node is MeshInstance3D and node.is_visible_in_tree():
			for point: Vector3 in node.mesh.get_faces(): result.append(node.global_transform * point)
	return result


static func _collision_faces(body: Node3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	for node: Node in body.get_children():
		if node is CollisionShape3D and node.shape is ConcavePolygonShape3D:
			for point: Vector3 in node.shape.get_faces(): result.append(node.global_transform * point)
	return result


static func _backface_collision(body: Node3D) -> bool:
	var count := 0
	for node: Node in body.get_children():
		if node is CollisionShape3D:
			if not node.shape is ConcavePolygonShape3D or not node.shape.backface_collision: return false
			count += 1
	return count == 1


static func _original_faces(east: bool) -> PackedVector3Array:
	# Literal pre-repair geometry, independent of the optional visual-point API.
	var points := PackedVector3Array([Vector3(-102,2,45),Vector3(-86,2,45),Vector3(-102,2,65),Vector3(-86,2,65)])
	var indices := [0,1,2,1,3,2]
	if east:
		points = PackedVector3Array([Vector3(86,0,45),Vector3(102,0,45),Vector3(86,2,55),Vector3(102,2,55),Vector3(86,2,68),Vector3(102,2,68)])
		indices = [0,1,2,1,3,2,2,3,4,3,5,4]
	var result := PackedVector3Array()
	for index: int in indices: result.append(points[index])
	return result


static func _same_triangles(left: PackedVector3Array, right: PackedVector3Array) -> bool:
	if left.size() != right.size(): return false
	return _signatures(left) == _signatures(right)


static func _signatures(faces: PackedVector3Array) -> PackedStringArray:
	var result := PackedStringArray()
	for offset: int in range(0, faces.size(), 3):
		var points := PackedStringArray()
		for corner: int in range(3):
			var at := faces[offset + corner]
			points.append(str(Vector3i(roundi(at.x / EPS), roundi(at.y / EPS), roundi(at.z / EPS))))
		points.sort()
		result.append("/".join(points))
	result.sort()
	return result


static func _horizontal_triangles(faces: PackedVector3Array, height: float) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for offset: int in range(0, faces.size(), 3):
		var level := true
		var triangle := PackedVector2Array()
		for corner: int in range(3):
			var at := faces[offset + corner]
			level = level and absf(at.y - height) < EPS
			triangle.append(Vector2(at.x, at.z))
		if level: result.append(triangle)
	return result


static func _overlap_area(left: Array[PackedVector2Array], right: Array[PackedVector2Array]) -> float:
	var result := 0.0
	for a: PackedVector2Array in left:
		for b: PackedVector2Array in right:
			if not _bounds(a).intersects(_bounds(b)): continue
			for overlap: PackedVector2Array in Geometry2D.intersect_polygons(a, b): result += _polygon_area(overlap)
	return result


static func _bounds(polygon: PackedVector2Array) -> Rect2:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for at: Vector2 in polygon: bounds = bounds.expand(at)
	return bounds


static func _polygon_area(polygon: PackedVector2Array) -> float:
	var twice := 0.0
	for index: int in range(polygon.size()): twice += polygon[index].cross(polygon[(index + 1) % polygon.size()])
	return absf(twice) * 0.5


static func _projected_area(faces: PackedVector3Array) -> float:
	var area := 0.0
	for offset: int in range(0, faces.size(), 3):
		var a := Vector2(faces[offset].x, faces[offset].z)
		var b := Vector2(faces[offset + 1].x, faces[offset + 1].z)
		var c := Vector2(faces[offset + 2].x, faces[offset + 2].z)
		area += absf((b-a).cross(c-a)) * 0.5
	return area
