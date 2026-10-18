extends RefCounted
## Independent DENSITY-01 contract checks against actual production collision.
## Fixed anchors come from COMPACT-CLYDE-CONTRACT, not candidate success metadata.
## Does not certify ordinary-input loops, temporal rendering, fun or Mac timing.

const NORTH := Rect2(-85, 55, 170, 23)
const SOUTH := Rect2(-39, 116, 115, 14)
const YARD := Rect2(-39, 130, 115, 13)
const SAFE_X := -25.0
const BROKEN_X := 20.0
const SAFE := [Vector3(-25,2,67), Vector3(-25,2,72), Vector3(-25,3.4,89),
	Vector3(-25,3.4,105), Vector3(-25,2,122), Vector3(-25,2,125)]


static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	await tree.physics_frame
	await tree.process_frame
	var outdoors: Node3D = world.get_node("OutdoorRoutes")
	_patch_bounds(outdoors, "ClydeNorthQuay", NORTH, check)
	_patch_bounds(outdoors, "ClydeSouthQuay", SOUTH, check)
	check.call(not outdoors.has_node("ClydeSouthBankLandscape"),
		"compact Clyde: obsolete 560x90m landscape body is removed")
	_retained_support(world, outdoors, check)
	_quay_route(world, outdoors, check)
	_safe_crossing(world, outdoors, check)
	_broken_crossing(world, outdoors, check)
	_transition_groups(world, outdoors, check)
	_yard_group(world, outdoors, check)
	_grind_mouths(world, outdoors, check)
	_visible_boundaries(world, outdoors, check)
	_water_recovery(world, outdoors, check)
	_landmark_group(outdoors, check)


static func _patch_bounds(outdoors: Node3D, id: String, expected: Rect2, check: Callable) -> void:
	var body: Node3D = outdoors.get_node_or_null(id)
	var extent := _visible_extent(outdoors, body)
	check.call(body is StaticBody3D and not extent.is_empty()
		and Vector2(extent.low.x, extent.low.z).distance_to(expected.position) < 0.001
		and Vector2(extent.high.x, extent.high.z).distance_to(expected.end) < 0.001
		and absf(extent.low.y - 2.0) < 0.001 and absf(extent.high.y - 2.0) < 0.001,
		"compact Clyde: actual visible supported footprint matches the retained " + id)


static func _retained_support(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var valid := true
	for at: Vector3 in [Vector3(-80,2,70), Vector3(-58,2,74), Vector3(-42,2,74),
		Vector3(-10,2,74), Vector3(45,2,74), Vector3(80,2,70),
		Vector3(-33,2,122), Vector3(-15,2,122), Vector3(0,2,122),
		Vector3(55,2,122), Vector3(70,2,122)]:
		valid = _supported_clear(world, outdoors.to_global(at), at.y + outdoors.global_position.y) and valid
	check.call(valid, "compact Clyde: retained quay approaches and useful return have real clear rider support")
	var rear_supported := true
	for x: float in [-33.0,0.0,70.0]:
		var at := outdoors.to_global(Vector3(x,2,139))
		var expected: float = world.get_ground_height(at)
		rear_supported = is_finite(expected) and expected >= 1.8 and expected < 3.5 \
			and _supported_clear(world, Vector3(at.x,expected,at.z), expected) and rear_supported
	check.call(rear_supported, "compact Clyde: bounded rear strip is real support rather than a hidden catch plane")
	var removed := true
	for x: float in [-250.0,-200.0,-140.0,-90.0,-50.0,0.0,50.0,90.0,140.0,200.0,250.0]:
		for z: float in [170.0,195.0,215.0]:
			var at := outdoors.to_global(Vector3(x,0,z))
			removed = _ray(world,at+Vector3.UP*20,at-Vector3.UP*5).is_empty() \
				and not is_finite(outdoors.get_ground_height(at.x,at.z)) and removed
	for at: Vector3 in [Vector3(-135,0,68), Vector3(135,0,68), Vector3(-100,0,124), Vector3(120,0,124)]:
		var global_at := outdoors.to_global(at)
		removed = _ray(world,global_at+Vector3.UP*8,global_at-Vector3.UP*5).is_empty() and removed
	check.call(removed, "compact Clyde: old outer quays and 33 former landscape samples contain no obsolete floor or query support")
	check.call(outdoors.get_district_id(outdoors.to_global(Vector3(200,3,180))) != "clyde"
		and outdoors.get_district_id(outdoors.to_global(Vector3(0,3,180))) != "clyde",
		"compact Clyde: removed south roaming space is not advertised as the Clyde district")


static func _quay_route(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var route := _route(world,"clyde_north_quay")
	var found_clear_lane := false
	var support := not route.is_empty()
	var swept_both := not route.is_empty()
	if not route.is_empty():
		for segment in range(route.points.size()-1):
			var a: Vector3 = route.points[segment]
			var b: Vector3 = route.points[segment+1]
			var local_a := outdoors.to_local(a)
			var local_b := outdoors.to_local(b)
			if absf(local_a.z-69)<.001 and absf(local_b.z-69)<.001 and absf(local_a.x-local_b.x)>150:
				found_clear_lane = true
			var direction := Vector3(b.x-a.x,0,b.z-a.z).normalized()
			var side := Vector3(direction.z,0,-direction.x)
			var steps := maxi(2,ceili(a.distance_to(b)/.5))
			for lateral: float in [-.7,0.0,.7]:
				var previous := Vector3.INF
				for index in range(steps+1):
					var at := a.lerp(b,float(index)/steps)+side*lateral
					# Follow actual terrain elevation across the graded triangles;
					# do not aim an upright sweep through the sloping road itself.
					# Capsule solids still catch a bridge rail crossing the lane.
					var height: float = world.get_ground_height(at)
					if not is_finite(height):
						print("COMPACT_CLYDE_ROUTE_NO_HEIGHT segment=",segment," lateral=",lateral," at=",at)
						support = false
						previous = Vector3.INF
						continue
					at.y = height
					var sample := _supported_clear(world,at,height)
					if not sample:
						print("COMPACT_CLYDE_ROUTE_BLOCKED segment=",segment," lateral=",lateral," at=",at)
					support = sample and support
					if previous.is_finite():
						swept_both = _clear_sweep(world,previous,at) and _clear_sweep(world,at,previous) and swept_both
					previous = at
	check.call(found_clear_lane,
		"compact Clyde: complete cross-quay route is landward atZ69 rather than behind solid bridge handrails")
	check.call(support,
		"compact Clyde: full city-to-city quay route retains actual rider support and plus/minus0.7m lateral clearance")
	check.call(swept_both,
		"compact Clyde: full3-track quay route clears real capsule motion in both directions through every join")


static func _safe_crossing(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var supported := true
	var clear_both := true
	for segment in range(SAFE.size()-1):
		var a: Vector3 = SAFE[segment]
		var b: Vector3 = SAFE[segment+1]
		var steps := maxi(2,ceili(a.distance_to(b)))
		for side: float in [-2.5,0.0,2.5]:
			var offset := Vector3(side,0,0)
			for index in range(steps+1):
				var local := a.lerp(b,float(index)/steps)+offset
				var at := outdoors.to_global(local)
				supported = _supported_clear(world,at,at.y) and supported
			var from := outdoors.to_global(a+offset)
			var to := outdoors.to_global(b+offset)
			clear_both = _clear_sweep(world,from,to) and _clear_sweep(world,to,from) and clear_both
	check.call(supported, "compact Clyde: true safe bridge supports centre and both novice lateral margins for the full crossing")
	check.call(clear_both, "compact Clyde: rider-size sweeps clear safe bridge joins and both travel directions without jumping")
	var published := _route(world,"clyde_safe_crossing")
	check.call(not published.is_empty() and not published.get("requires_jump",true)
		and _all_x(published.points,SAFE_X),
		"compact Clyde: safe navigation route follows the moved continuous crossing rather than the removed bridge")


static func _broken_crossing(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var open := true
	for z: float in [94.1,96.0,98.0,100.0,101.9]:
		for side: float in [-1.2,0.0,1.2]:
			var at := outdoors.to_global(Vector3(BROKEN_X+side,0,z))
			open = _ray(world,at+Vector3.UP*6,at-Vector3.UP*5).is_empty() and open
	check.call(open, "compact Clyde: native eight-metre optional opening has no collision filler across its usable deck width")
	var ends := true
	for sample: Vector3 in [Vector3(20,3.185,93.8),Vector3(20,2.78857,102.2),Vector3(20,2,120)]:
		for side: float in [-1.2,0.0,1.2]:
			var at := outdoors.to_global(sample+Vector3(side,0,0))
			ends = _supported_clear(world,at,at.y) and ends
	check.call(ends, "compact Clyde: actual launch and landing decks retain native heights and recoverable lateral margins")
	var gap: Dictionary = {}
	for source: Dictionary in world.get_gap_definitions():
		if source.id == "clyde_bridge_transfer": gap = source
	check.call(not gap.is_empty() and gap.start.distance_to(outdoors.to_global(Vector3(20,3.05,92))) < 0.001
		and gap.end.distance_to(outdoors.to_global(Vector3(20,2.69,104))) < 0.001
		and gap.get("airborne_required",false) and absf(gap.radius-2.4) < 0.001,
		"compact Clyde: stable scored gap moves with the physical bridge without wider scoring gates")
	var route := _route(world,"clyde_bridge_transfer")
	check.call(not route.is_empty() and route.get("requires_jump",false) and _all_x(route.points,BROKEN_X)
		and absf(BROKEN_X-SAFE_X-45.0) < 0.001,
		"compact Clyde: distinct optional and safe bridge routes are 45m apart with the real opening retained")


static func _transition_groups(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var expected := {
		"clyde_half_west":{"toe":Vector3(-46,2,60.5),"yaw":PI*.5},
		"clyde_half_east":{"toe":Vector3(-38,2,60.5),"yaw":-PI*.5},
		"clyde_quarter":{"toe":Vector3(-15,2,62),"yaw":PI*.5}}
	var seen: Dictionary = {}
	var geometry := true
	for feature: Dictionary in world.get_transition_features():
		if not expected.has(feature.id): continue
		seen[feature.id] = true
		var intended: Dictionary = expected[feature.id]
		var frame: Transform3D = feature.transform
		var target := outdoors.global_transform*Transform3D(Basis(Vector3.UP,intended.yaw),intended.toe)
		geometry = frame.is_equal_approx(target) and frame.is_equal_approx(feature.body.global_transform) \
			and absf(frame.basis.determinant()-1.0) < 0.001 and absf(feature.radius-3.2) < 0.001 \
			and absf(feature.width-10.0) < 0.001 and absf(feature.angle-PI*.5) < 0.001 and geometry
		var theta := deg_to_rad(44.0)
		var at := frame*Vector3(0,3.2*(1.0-cos(theta)),-3.2*sin(theta))
		var normal := frame.basis*Vector3(0,cos(theta),sin(theta))
		var contact := _ray(world,at+normal*.2,at-normal*.2)
		geometry = not contact.is_empty() and contact.collider == feature.body \
			and contact.position.distance_to(at) < .003 and contact.normal.dot(normal) > .999 and geometry
		var deck_at := frame*Vector3(0,3.2,-4.2)
		var deck := _ray(world,deck_at+Vector3.UP*.4,deck_at-Vector3.UP*.4)
		geometry = not deck.is_empty() and deck.collider.name == "SupportedDeck" \
			and deck.position.distance_to(deck_at) < .003 and geometry
	check.call(seen.size() == expected.size() and geometry,
		"compact Clyde: both half-pipe faces and east-facing quarter move physical contact frames and decks intact at native dimensions")
	var access := true
	for x: float in [-44.5,-42.0,-39.5]:
		var a := outdoors.to_global(Vector3(x,2,70))
		var b := outdoors.to_global(Vector3(x,2,60.5))
		access = _clear_sweep(world,a,b) and _clear_sweep(world,b,a) and access
	var quarter_entry := outdoors.to_global(Vector3(-11,2,62))
	access = _supported_clear(world,quarter_entry,quarter_entry.y) and access
	check.call(access, "compact Clyde: half-pipe open end and rotated quarter entry remain clear rider-size approaches")
	var flat_body: StaticBody3D = world.get_node("TransitionPark/HalfPipeFlatBottom")
	var native_bottom := false
	for shape: Node in flat_body.get_children():
		if not shape is CollisionShape3D or not shape.shape is BoxShape3D: continue
		var size: Vector3 = shape.shape.size
		var frame: Transform3D = shape.global_transform
		var low := frame*Vector3(-size.x/2,size.y/2,-size.z/2)
		var high := frame*Vector3(size.x/2,size.y/2,size.z/2)
		native_bottom = size.distance_to(Vector3(8,.24,10))<.001 \
			and low.distance_to(outdoors.to_global(Vector3(-46,2,55.5)))<.001 \
			and high.distance_to(outdoors.to_global(Vector3(-38,2,65.5)))<.001 \
			and not shape.disabled
	var supported_bottom := true
	for x: float in [-45.999,-42.0,-38.001]:
		var flat := _ray(world,outdoors.to_global(Vector3(x,2.4,60.5)),outdoors.to_global(Vector3(x,1.8,60.5)))
		# The unchanged quay and native bottom share Y2 exactly. Ray ownership
		# may choose either collider; physical box corners above prove the flat.
		supported_bottom = not flat.is_empty() and absf(outdoors.to_local(flat.position).y-2)<.001 \
			and (flat.collider==flat_body or flat.collider.name=="ClydeNorthQuay") and supported_bottom
	check.call(native_bottom and supported_bottom,
		"compact Clyde: moved native flat box retains its8m footprint and actual Y2 support across both opposing toes")



static func _yard_group(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var ledge = null
	for line in world.get_grind_lines():
		if line.id == "clyde_print_yard_ledge": ledge = line
	var expected := PackedVector3Array([outdoors.to_global(Vector3(38.3,2.77,124.4)),outdoors.to_global(Vector3(47.7,2.77,124.4))])
	check.call(ledge != null and ledge.is_valid and ledge.points == expected and absf(ledge.length-9.4) < .001,
		"compact Clyde: stable yard ledge moves its complete native 9.4m profile with the planter")
	var planter := _ray(world,outdoors.to_global(Vector3(40,4,125.5)),outdoors.to_global(Vector3(40,2,125.5)))
	check.call(not planter.is_empty() and str(planter.collider.name).begins_with("PrintYardPlanter")
		and absf(outdoors.to_local(planter.position).y-2.7) < .001,
		"compact Clyde: moved planter has matching real top support rather than only a moved grind track")
	var landing := outdoors.to_global(Vector3(52,2,124.4))
	check.call(_supported_clear(world,landing,landing.y)
		and _clear_sweep(world,landing,outdoors.to_global(Vector3(61,2,124.4))),
		"compact Clyde: ledge runout beyond the planter remains supported with a useful recovery margin")
	var hip := _route(world,"clyde_print_yard_hip")
	var shaped := not hip.is_empty()
	var steepest := 0.0
	var min_y := INF
	var max_y := -INF
	if not hip.is_empty():
		for point: Vector3 in hip.points:
			var local := outdoors.to_local(point)
			min_y = minf(min_y,local.y)
			max_y = maxf(max_y,local.y)
			var hit := _ray(world,point+Vector3.UP*.3,point-Vector3.UP*.3)
			var supported := local.x >= 43.0 and local.x <= 54.1 and not hit.is_empty() \
				and absf(hit.position.y-point.y) < .025
			if not supported:
				print("COMPACT_CLYDE_HIP_FAILURE expected=",point," hit=",hit.get("position",Vector3.INF),
					" body=",str(hit.collider.name) if not hit.is_empty() else "NONE",
					" normal=",hit.get("normal",Vector3.ZERO))
			shaped = supported and shaped
			if not hit.is_empty(): steepest = maxf(steepest,rad_to_deg(acos(clampf(hit.normal.y,-1,1))))
	print("COMPACT_CLYDE_HIP_RANGE min=",min_y," max=",max_y," steepest=",steepest," support=",shaped)
	check.call(shaped and max_y-min_y > .7 and steepest >= 30 and steepest <= 36,
		"compact Clyde: translated yard hip retains actual curved support and its original 35-degree rise")


static func _grind_mouths(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var clear := true
	for line in world.get_grind_lines():
		if not line.is_valid: continue
		for index in range(line.points.size()-1):
			var a := outdoors.to_local(line.points[index])
			var b := outdoors.to_local(line.points[index+1])
			if absf(a.z-b.z) > .15: continue
			if not ((a.z > 76 and a.z < 79) or (a.z > 115 and a.z < 118)): continue
			for mouth: Vector2 in [Vector2(-29,-21),Vector2(17.5,22.5)]:
				var overlap := minf(maxf(a.x,b.x),mouth.y-.15)-maxf(minf(a.x,b.x),mouth.x+.15)
				if overlap > .02:
					print("COMPACT CLYDE PHANTOM MOUTH ",line.id," ",a," -> ",b)
					clear = false
	check.call(clear, "compact Clyde: no low coping or selected embankment grind crosses either flush bridge mouth")


static func _visible_boundaries(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var closed := true
	for pair: Array in [[Vector3(-83,3.1,70),Vector3(-90,3.1,70)],
		[Vector3(83,3.1,70),Vector3(90,3.1,70)],
		[Vector3(-37,3.1,138),Vector3(-43,3.1,138)],
		[Vector3(74,3.1,138),Vector3(80,3.1,138)],
		[Vector3(0,3.1,141),Vector3(0,3.1,148)]]:
		var hit := _ray(world,outdoors.to_global(pair[0]),outdoors.to_global(pair[1]))
		var visible := false
		if not hit.is_empty():
			var body: Node3D = hit.collider
			visible = body.is_in_group("exploration_boundaries") and _has_visible_geometry(body)
		closed = visible and closed
	check.call(closed, "compact Clyde: retained dry ends have real collision with visible matching boundary geometry")


static func _water_recovery(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var safe := true
	for x: float in [-449.0,-200.0,-84.0,-25.0,0.0,20.0,75.0,200.0,449.0]:
		for z: float in [80.0,95.0,110.0,115.5]:
			var at := outdoors.to_global(Vector3(x,-2.2,z))
			var recovered: Vector3 = world.get_recovery_position(at)
			if not recovered.is_finite():
				safe = false
				continue
			var local := outdoors.to_local(recovered)
			var on_retained_bank := NORTH.grow(-.5).has_point(Vector2(local.x,local.z)) \
				or SOUTH.grow(-.5).has_point(Vector2(local.x,local.z))
			var hit := _ray(world,recovered,recovered-Vector3.UP*1.5)
			safe = on_retained_bank and not hit.is_empty() and hit.normal.y > .99 \
				and absf(hit.position.y-(outdoors.global_position.y+2)) < .001 \
				and _capsule_clear(world,hit.position) and safe
	check.call(safe, "compact Clyde: both banks and scenic-water extremes recover onto retained clear quay rather than deleted grass")
	var checkpoint: Vector3 = world.get_district_checkpoints().get("clyde",Vector3.INF)
	var floor_hit := _ray(world,checkpoint,checkpoint-Vector3.UP*1.5)
	check.call(checkpoint.is_finite() and not floor_hit.is_empty() and _capsule_clear(world,floor_hit.position),
		"compact Clyde: moved-layout district checkpoint remains a real supported clear retry point")


static func _landmark_group(outdoors: Node3D, check: Callable) -> void:
	var north := false
	var south := false
	var landmarks: Node3D = outdoors.get_node_or_null("ClydeLandmarks")
	if landmarks != null:
		# Duplicate sibling names are engine-renamed. Inspect every real portal
		# mesh under this group rather than treating a name wildcard as absence.
		for portal: Node in landmarks.get_children():
			if not portal is MeshInstance3D or not portal.mesh is ArrayMesh or not portal.is_visible_in_tree(): continue
			var local := outdoors.to_local(portal.global_position)
			var extent: AABB = portal.mesh.get_aabb()
			var arch := absf(extent.size.x-10.8)<.001 and absf(extent.size.z-1.44)<.001 \
				and absf(extent.position.y-7.1)<.001
			north = north or (arch and local.distance_to(Vector3(-25,0,72))<.001)
			south = south or (arch and local.distance_to(Vector3(-25,0,122))<.001)
	check.call(north and south, "compact Clyde: both visible suspension portals follow the physical safe crossing")


static func _supported_clear(world: Node3D, at: Vector3, expected_y: float) -> bool:
	var hit := _ray(world,Vector3(at.x,expected_y+.32,at.z),Vector3(at.x,expected_y-.32,at.z))
	if hit.is_empty() or absf(hit.position.y-expected_y) > .025 or hit.normal.y < .8: return false
	var published: float = world.get_ground_height(at)
	return is_finite(published) and absf(published-hit.position.y) < .025 and _capsule_clear(world,hit.position)


static func _ray(world: Node3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	query.hit_back_faces = false
	return world.get_world_3d().direct_space_state.intersect_ray(query)


static func _capsule_query(at: Vector3) -> PhysicsShapeQueryParameters3D:
	var shape := CapsuleShape3D.new()
	shape.radius = .28
	shape.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = at+Vector3.UP*.98
	query.collision_mask = 1
	query.margin = .005
	return query


static func _capsule_clear(world: Node3D, at: Vector3) -> bool:
	return world.get_world_3d().direct_space_state.intersect_shape(_capsule_query(at)).is_empty()


static func _clear_sweep(world: Node3D, from: Vector3, to: Vector3) -> bool:
	var query := _capsule_query(from)
	query.motion = to-from
	var result := world.get_world_3d().direct_space_state.cast_motion(query)
	return result.size() == 2 and result[0] >= .9999


static func _route(world: Node3D, id: String) -> Dictionary:
	for route: Dictionary in world.get_route_definitions():
		if route.id == id: return route
	return {}


static func _all_x(points: PackedVector3Array, x: float) -> bool:
	if points.is_empty(): return false
	for point: Vector3 in points:
		if absf(point.x-x) > .001: return false
	return true


static func _visible_extent(outdoors: Node3D, body: Node3D) -> Dictionary:
	if body == null: return {}
	var low := Vector3(INF,INF,INF)
	var high := Vector3(-INF,-INF,-INF)
	var found := false
	for display: MeshInstance3D in body.find_children("*","MeshInstance3D",true,false):
		if display.mesh == null or not display.is_visible_in_tree(): continue
		for point: Vector3 in display.mesh.get_faces():
			var local := outdoors.to_local(display.to_global(point))
			low = low.min(local)
			high = high.max(local)
			found = true
	return {"low":low,"high":high} if found else {}


static func _has_visible_geometry(body: Node3D) -> bool:
	for display: Node3D in body.find_children("*","GeometryInstance3D",true,false):
		if not display.is_visible_in_tree(): continue
		if display is MeshInstance3D and display.mesh != null: return true
		if display is MultiMeshInstance3D and display.multimesh != null and display.multimesh.instance_count > 0: return true
	return false
