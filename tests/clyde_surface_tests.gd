extends RefCounted
## Actual production triangles, not authored bounds or success metadata.
## The compact bent roads retain full collision and clip only their paving overlap.
## The unrelated Station repair remains unchanged.

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
	check.call(not quay_top.is_empty(), "Clyde surface separation: compact quay has actual Y2 paving triangles")
	for id: String in ["ClydeWestApproach", "ClydeEastApproach"]:
		var road: StaticBody3D = outdoors.get_node(id)
		var visual := _visual_faces(road)
		var collision := _collision_faces(road)
		var east := id == "ClydeEastApproach"
		var expected := _compact_faces(east)
		check.call(_same_triangles(collision, expected) and road.collision_layer == 1 and road.collision_mask == 0
			and road.get_meta("surface_audio", "") == "asphalt" and _backface_collision(road),
			"Clyde surface separation: bent16m collision retains independently fixed corners/layers/audio/backface support " + id)
		var overlap := _overlap_area(_horizontal_triangles(collision,2),quay_top)
		var visible_overlap := _overlap_area(_horizontal_triangles(visual,2),quay_top)
		check.call(absf(overlap-132.000652) < .002,
			"Clyde surface separation: actual bent-road collision independently exposes132.00065m2 paving overlap " + id)
		check.call(visible_overlap < EPS,
			"Clyde surface separation: displayed bent road has no positive-area Y2 overlap with compact paving " + id)
		var on_original_plane := not visual.is_empty()
		for point: Vector3 in visual: on_original_plane = _on_faces(point,expected) and on_original_plane
		var expected_area := _projected_area(expected)-overlap
		check.call(on_original_plane and absf(_projected_area(visual)-expected_area)<.003,
			"Clyde surface separation: complete exterior road footprint retains original triangle planes without height offsets " + id)
		var support := true
		var visible_complete := true
		var capsule := CapsuleShape3D.new()
		capsule.radius = .28
		capsule.height = 1.7
		for index: int in range(0,expected.size(),3):
			for weights: Vector3 in [Vector3(1,1,1)/3,Vector3(.2,.4,.4),Vector3(.4,.2,.4),Vector3(.4,.4,.2)]:
				var at := expected[index]*weights.x+expected[index+1]*weights.y+expected[index+2]*weights.z
				var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*.3,at-Vector3.UP*.3,1)
				var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
				var standing := PhysicsShapeQueryParameters3D.new()
				standing.shape = capsule
				standing.transform.origin = at+Vector3.UP*.98
				standing.collision_mask = 1
				standing.margin = .005
				support = not hit.is_empty() and absf(hit.position.y-at.y)<.001 \
					and absf(world.get_ground_height(at)-at.y)<.001 \
					and world.get_world_3d().direct_space_state.intersect_shape(standing).is_empty() and support
				if not Rect2(-85,55,170,23).has_point(Vector2(at.x,at.z)):
					visible_complete = _on_faces(at,visual) and visible_complete
		check.call(support,
			"Clyde surface separation: real graded ray/query and rider capsule support cover every bent-road collision triangle " + id)
		check.call(visible_complete,
			"Clyde surface separation: exterior graded road remains visibly covered after native clipping " + id)
	_check_station(world, check)
	_check_sunken_bowl(world, check)
	check.call(original_physics_inventory(world),
		"Surface separation: core/benches retain the approved civic guard panel delta and compact totals stay exact")
	var diagonal_fraction := 8.0/(102.0-87.5301113256)
	var east_diagonal := Vector3(94,2*diagonal_fraction,45+(50.2946264186-45)*diagonal_fraction)
	var routes: Array = world.get_route_definitions()
	var published: Dictionary = {}
	for route: Dictionary in routes: published[route.id] = route
	check.call(routes.size() == published.size()
		and published.has("clyde_north_quay") and not published.clyde_north_quay.requires_jump
		and published.clyde_north_quay.points == PackedVector3Array([
			Vector3(-94,2,45),Vector3(-94,2,55),Vector3(-78,2,67),Vector3(-78,2,69),
			Vector3(78,2,69),Vector3(78,2,67),Vector3(94,2,55),east_diagonal,Vector3(94,0,45)])
		and published.has("merchant_close_cutthrough") and published.merchant_close_cutthrough.points == PackedVector3Array([
			Vector3(-64,2,-30),Vector3(-68,2,-44),Vector3(-69,2.5,-50),Vector3(-61,3.2,-60),
			Vector3(-55,3.5,-65),Vector3(-59,4,-74),Vector3(-59,4,-80)]),
		"Surface separation: unique current routes use compact Clyde joins while unrelated Merchant Close points stay unchanged")
	world.free()
	await tree.process_frame


static func original_physics_inventory(world: Node3D) -> bool:
	# Exclude only the authorized, reachable street furniture. A group tag alone
	# cannot hide another body: require all twelve unique anchor/part identities,
	# direct world ownership, normal scenery layers and the actual box counts.
	var anchors := [Vector3(-127,2,28), Vector3(60,0,41.5), Vector3(29,6,-116), Vector3(29,0,27)]
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
	var outdoors := world.get_node("OutdoorRoutes")
	var transitions := world.get_node("TransitionPark")
	var additions: Dictionary = {}
	var added_shape_ids: Dictionary = {}
	var added_body_ids: Dictionary = {}
	var cap_shapes := 0
	for body: StaticBody3D in bodies:
		if outdoors.is_ancestor_of(body) or transitions.is_ancestor_of(body): continue
		var category := _combined_addition(world,body)
		if category.is_empty():
			# Exactly two approved60mm Court lids are compound additions; the
			# old seat body/base remains protected and cannot be excluded.
			if str(body.get_meta("art_label",""))=="CourtPlanterSeat":
				for child: Node in body.get_children():
					if child is CollisionShape3D and child.shape is BoxShape3D \
							and child.shape.size.is_equal_approx(Vector3(1.25,0.06,8.1)) \
							and child.position.is_equal_approx(Vector3(0,0.27,0)) and not child.disabled:
						cap_shapes+=1
						added_shape_ids[child.get_instance_id()]=true
			continue
		added_body_ids[body.get_instance_id()]=true
		if not additions.has(category): additions[category]={"bodies":0,"shapes":0}
		additions[category].bodies+=1
		for child: Node in body.get_children():
			if not child is CollisionShape3D: continue
			valid=valid and child.shape!=null and not child.disabled and child.position.is_finite()
			added_shape_ids[child.get_instance_id()]=true
			additions[category].shapes+=1
	var protected_bodies := 0
	var protected_shapes := 0
	for body: StaticBody3D in bodies:
		if not outdoors.is_ancestor_of(body) and not transitions.is_ancestor_of(body) and not added_body_ids.has(body.get_instance_id()): protected_bodies+=1
	for shape: CollisionShape3D in shapes:
		if not outdoors.is_ancestor_of(shape) and not transitions.is_ancestor_of(shape) and not added_shape_ids.has(shape.get_instance_id()): protected_shapes+=1
	var expected := {"new_bins":{"bodies":4,"shapes":8},"new_composites":{"bodies":31,"shapes":31},
		"new_infill_rail":{"bodies":3,"shapes":3},"new_infill_solids":{"bodies":38,"shapes":38},
		"new_native_factory":{"bodies":47,"shapes":195}}
	print("PHYSICS_INVENTORY bodies=%d shapes=%d protected_bodies=%d protected_shapes=%d bench_bodies=%d bench_boxes=%d identified=%s additions=%s court_caps=%d" % [
		bodies.size(),shapes.size(),protected_bodies,protected_shapes,bench_bodies,bench_shapes.size(),valid,additions,cap_shapes])
	return valid and identities.size()==12 and bench_bodies==12 and bench_shapes.size()==44 \
		and protected_bodies==271 and protected_shapes==721 and additions==expected and cap_shapes==2 \
		and bodies.size()==557 and shapes.size()==1654 # Clyde access removal; east civic guard gains one graded panel.


static func _check_sunken_bowl(world: Node3D, check: Callable) -> void:
	var bowl: Node3D = world.get_node("ClydeEastBowl")
	var definition: Dictionary = bowl.get_feature_definitions()[0]
	check.call(absf(definition.floor_y+0.4)<0.00001 and absf(definition.rim_y-2)<0.00001
		and not bowl.has_node("BowlAccessRollIn") and not bowl.has_node("BowlAccessTopLanding")
		and definition.id=="ClydeEastBowl",
		"Clyde sunken bowl: unchanged identity, Y2 flush rim,2.4m excavation and no raised access bodies")
	var matched := true
	var no_cap := true
	var samples := 0
	var max_error := 0.0
	# Off-spoke/near-lip points detect the analytic-circle vs faceted-mesh error.
	for spoke in 33:
		var phi := (float(spoke)*3.87+0.37)*TAU/128
		for rho: float in [0.0,2.7,3.49,3.6,4.1,4.9,5.5,5.78,5.86,5.895]:
			var point: Vector3 = bowl.to_global(Vector3(sin(phi)*rho,0,-cos(phi)*rho))
			var query := PhysicsRayQueryParameters3D.create(Vector3(point.x,3,point.z),Vector3(point.x,-1,point.z),1)
			var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty():
				matched = false
				continue
			var error := absf(world.get_ground_height(point)-hit.position.y)
			max_error = maxf(max_error,error)
			matched = matched and error<0.001 and absf(world.get_support_height(point+Vector3.UP*3,0)-hit.position.y)<0.001
			no_cap = no_cap and hit.position.y<1.95
			samples+=1
	check.call(matched and no_cap and samples==330,
		"Clyde sunken bowl:330 independent native pit rays agree with ground/support queries; no invisible quay cap")
	var exterior := true
	for spoke in 32:
		var phi := float(spoke)/32*TAU
		var point: Vector3 = bowl.to_global(Vector3(sin(phi)*7.8,0,-cos(phi)*7.8))
		var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(point.x,3,point.z),Vector3(point.x,1,point.z),1))
		exterior = exterior and not hit.is_empty() and absf(hit.position.y-2)<0.001
	for x in range(-17,4):
		var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(x,3,124),Vector3(x,1,124),1))
		exterior = exterior and not hit.is_empty() and absf(hit.position.y-2)<0.001
	check.call(exterior,"Clyde sunken bowl:53 native exterior/through-lane rays retain Y2 support")
	var added := 0
	for id: String in ["ClydePrintYardGround","ClydeSouthQuay"]:
		added+=int(world._outdoors.get_node(id).get_meta("excavation_added_visual_triangles"))
	var deck_visual: MeshInstance3D = bowl.get_node("AnnularDeck").get_child(1)
	check.call(added<=1024 and deck_visual.material_override==world._materials["paving"],
		"Clyde sunken bowl: existing quay paving reused and startup triangle addition within1024 budget")
	print("CLYDE_SUNKEN_BOWL native_samples=%d max_height_error_m=%.7f added_visual_triangles=%d" % [samples,max_error,added])


static func _combined_addition(world: Node3D,body: StaticBody3D) -> String:
	var label := str(body.get_meta("art_label",body.name))
	if body.is_in_group("physical_street_bins") and label=="StreetLitterBin": return "new_bins"
	if label=="NativeGrindBearing" and body.collision_layer==2 and body.collision_mask==0 \
			and body.get_parent().is_in_group("grind_rails"): return "new_native_factory"
	var new_ids: Array = []
	var labels: Array[String] = []
	for feature: Dictionary in world._fidelity_infill.get_features():
		new_ids.append_array(feature.get("grind_ids",[]))
		if feature.get("kind","")=="bank_manual_ledge_line":
			for suffix: String in ["ManualDeck","WestBank","EastBank"]: labels.append(str(feature.id)+suffix)
		if feature.get("kind","")=="graded_park_ledge": labels.append(str(feature.id))
		for id: String in feature.get("grind_ids",[]): labels.append(id+"Masonry")
	if label in labels and body.get_parent()==world and body.collision_layer==1: return "new_infill_solids"
	var owner_node: Node = body
	while owner_node!=world and owner_node!=null:
		var source: Script = owner_node.get_script()
		if source!=null and source.resource_path in ["res://game/levels/bowl_feature.gd",
				"res://game/levels/halfpipe_feature.gd","res://game/levels/spine_feature.gd"]: return "new_composites"
		if str(owner_node.get_meta("grind_id","")) in new_ids and body.collision_layer==2: return "new_infill_rail"
		owner_node=owner_node.get_parent()
	return ""



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


static func _compact_faces(east: bool) -> PackedVector3Array:
	# Fixed contract corners calculated independently from the 16m bent ribbon:
	# its middle cross-section is perpendicular to the45->67m chord, and the
	# final section to the16x12m bend. No Surface builder or candidate metadata.
	var points := PackedVector3Array([
		Vector3(-102,2,45),Vector3(-86,2,45),
		Vector3(-100.4698886744,2,59.7053735814),Vector3(-87.5301113256,2,50.2946264186),
		Vector3(-82.8,2,73.4),Vector3(-73.2,2,60.6)])
	if east:
		points = PackedVector3Array([Vector3(86,0,45),Vector3(102,0,45),
			Vector3(87.5301113256,2,50.2946264186),Vector3(100.4698886744,2,59.7053735814),
			Vector3(73.2,2,60.6),Vector3(82.8,2,73.4)])
	var result := PackedVector3Array()
	for index: int in [0,1,2,1,3,2,2,3,4,3,5,4]: result.append(points[index])
	return result


static func _on_faces(point: Vector3, faces: PackedVector3Array) -> bool:
	for index: int in range(0,faces.size(),3):
		var a := faces[index]
		var b := faces[index+1]
		var c := faces[index+2]
		var ab := Vector2(b.x-a.x,b.z-a.z)
		var ac := Vector2(c.x-a.x,c.z-a.z)
		var offset := Vector2(point.x-a.x,point.z-a.z)
		var determinant := ab.cross(ac)
		if absf(determinant)<.000001: continue
		var wb := offset.cross(ac)/determinant
		var wc := ab.cross(offset)/determinant
		var wa := 1.0-wb-wc
		if minf(wa,minf(wb,wc))>=-.00002 and absf(point.y-(a.y*wa+b.y*wb+c.y*wc))<.00003: return true
	return false


static func _same_triangles(left: PackedVector3Array, right: PackedVector3Array) -> bool:
	if left.size() != right.size(): return false
	# Actual ConcavePolygon collision readback rounds these mesh coordinates:
	# measured maximum error is34.12 micrometres from the independent corners.
	# Use a true0.1mm tolerance, preserving every triangle/corner bijectively;
	# a rounded hash bucket is not a geometric-distance comparison.
	if _signatures(left) != _signatures(right):
		var maximum_error := 0.0
		for actual: Vector3 in left:
			var nearest := INF
			for intended: Vector3 in right: nearest = minf(nearest,actual.distance_to(intended))
			maximum_error = maxf(maximum_error,nearest)
		print("CLYDE_LITERAL_FLOAT actual=",left," independent=",right," maximum_corner_error_m=",maximum_error)
	var used_triangles: Array[int] = []
	for offset: int in range(0,left.size(),3):
		var matched := false
		for target: int in range(0,right.size(),3):
			if used_triangles.has(target): continue
			var corners: Array[int] = []
			for index: int in 3:
				for other: int in 3:
					if not corners.has(other) and left[offset+index].distance_to(right[target+other])<.0001:
						corners.append(other)
						break
			if corners.size()==3:
				used_triangles.append(target)
				matched=true
				break
		if not matched: return false
	return used_triangles.size()==left.size()/3


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
