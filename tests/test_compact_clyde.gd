extends RefCounted
## Independent DENSITY-01 contract checks against actual production collision.
## Fixed anchors come from COMPACT-CLYDE-CONTRACT, not candidate success metadata.
## Does not certify ordinary-input loops, temporal rendering, fun or Mac timing.

const FaceProbe = preload("res://tests/clyde_surface_tests.gd")

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
	_patch_bounds(world,outdoors, "ClydeNorthQuay", NORTH, check)
	_patch_bounds(world,outdoors, "ClydeSouthQuay", SOUTH, check)
	check.call(not outdoors.has_node("ClydeSouthBankLandscape"),
		"compact Clyde: obsolete 560x90m landscape body is removed")
	_retained_support(world, outdoors, check)
	_quay_route(world, outdoors, check)
	_safe_crossing(world, outdoors, check)
	_broken_crossing(world, outdoors, check)
	_transition_groups(world, outdoors, check)
	_yard_group(world, outdoors, check)
	_south_return(world, outdoors, check)
	_grind_mouths(world, outdoors, check)
	_visible_boundaries(world, outdoors, check)
	_raised_deck_containment(world, outdoors, check)
	_opaque_boundary_faces(world, outdoors, check)
	_compact_surface_separation(outdoors, check)
	_water_recovery(world, outdoors, check)
	_landmark_group(outdoors, check)


static func _patch_bounds(world: Node3D,outdoors: Node3D, id: String, expected: Rect2, check: Callable) -> void:
	var body: Node3D = outdoors.get_node_or_null(id)
	if not body is StaticBody3D:
		check.call(false,"compact Clyde: original native and complete visible quay footprint retained with stone-edge ownership " + id)
		return
	var native := FaceProbe._collision_faces(body)
	var paving := FaceProbe._visual_faces(body)
	var native_extent := _face_extent(outdoors,native)
	var paving_extent := _face_extent(outdoors,paving)
	# The native rectangle remains unchanged. Coplanar paving under the actual
	# Y2 embankment top is intentionally removed:136m² north and92m² south.
	var north := id == "ClydeNorthQuay"
	var paving_bounds := Rect2(-85,55,170,22.2) if north else Rect2(-39,116.8,115,13.2)
	var stone := outdoors.get_node("NorthEmbankment" if north else "SouthEmbankment")
	var stone_top := _local_level_faces(outdoors,FaceProbe._visual_faces(stone),2.0)
	var visible_union := paving.duplicate()
	visible_union.append_array(stone_top)
	var union_extent := _face_extent(outdoors,visible_union)
	var exact := _matches_patch_extent(native_extent,expected) \
		and _matches_patch_extent(paving_extent,paving_bounds) \
		and _matches_patch_extent(union_extent,expected)
	# Do not replace an omitted wall with an accepted rectangle in the test:
	# inspect actual mesh coverage over every resident native triangle.
	var complete := true
	var substitute := PackedVector3Array()
	if not north:
		substitute.append_array(FaceProbe._visual_faces(outdoors.get_node("PrintYardCurvedBankHip")))
		substitute.append_array(FaceProbe._visual_faces(world.get_node("ClydeEastBowl/AnnularDeck")))
	for index: int in range(0,native.size(),3):
		for weights: Vector3 in [Vector3.ONE/3.0,Vector3(.2,.4,.4),Vector3(.4,.2,.4),Vector3(.4,.4,.2)]:
			var at := native[index]*weights.x+native[index+1]*weights.y+native[index+2]*weights.z
			var covered := FaceProbe._on_faces(at,visible_union) or _raised_display_at(at,substitute)
			if not covered and complete:print("COMPACT_CLYDE_DISPLAY_MISSING ",id," at=",at)
			complete = covered and complete
	if not north:
		# The original bowl excavation remains a hole in the quay, rather than
		# being silently filled when its surviving display rectangle is checked.
		var mouth := outdoors.to_global(Vector3(-7,2,129.5))
		complete = complete and not FaceProbe._on_faces(mouth,native) \
			and not FaceProbe._on_faces(mouth,visible_union)
	check.call(exact and complete,
		"compact Clyde: original native and complete visible quay footprint retained with stone-edge ownership " + id)


static func _face_extent(outdoors: Node3D,faces: PackedVector3Array) -> Dictionary:
	if faces.is_empty():return {}
	var low := Vector3(INF,INF,INF)
	var high := Vector3(-INF,-INF,-INF)
	for global_point: Vector3 in faces:
		var local := outdoors.to_local(global_point)
		low = low.min(local)
		high = high.max(local)
	return {"low":low,"high":high}


static func _matches_patch_extent(extent: Dictionary,bounds: Rect2) -> bool:
	return not extent.is_empty() \
		and Vector2(extent.low.x,extent.low.z).distance_to(bounds.position)<0.001 \
		and Vector2(extent.high.x,extent.high.z).distance_to(bounds.end)<0.001 \
		and absf(extent.low.y-2)<0.001 and absf(extent.high.y-2)<0.001


static func _local_level_faces(outdoors: Node3D,faces: PackedVector3Array,height: float) -> PackedVector3Array:
	var result := PackedVector3Array()
	for index: int in range(0,faces.size(),3):
		if absf(outdoors.to_local(faces[index]).y-height)<0.0001 \
			and absf(outdoors.to_local(faces[index+1]).y-height)<0.0001 \
			and absf(outdoors.to_local(faces[index+2]).y-height)<0.0001:
			result.append_array(PackedVector3Array([faces[index],faces[index+1],faces[index+2]]))
	return result


static func _raised_display_at(at: Vector3,faces: PackedVector3Array) -> bool:
	# The existing hip and annular bowl deck legitimately replace paving below
	# their own real meshes. Require an upward face at/above the native plane,
	# rather than accepting an authored bounding rectangle as visible support.
	for index: int in range(0,faces.size(),3):
		var a := faces[index]
		var b := faces[index+1]
		var c := faces[index+2]
		var ab := Vector2(b.x-a.x,b.z-a.z)
		var ac := Vector2(c.x-a.x,c.z-a.z)
		var relative := Vector2(at.x-a.x,at.z-a.z)
		var determinant := ab.cross(ac)
		if determinant<=0.000001:continue
		var wb := relative.cross(ac)/determinant
		var wc := ab.cross(relative)/determinant
		var wa := 1.0-wb-wc
		if minf(wa,minf(wb,wc))>=-0.00001 and a.y*wa+b.y*wb+c.y*wc>=at.y-0.0001:return true
	return false


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


static func _south_return(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var yard := _route(world,"clyde_print_yard_loop")
	var safe := _route(world,"clyde_safe_crossing")
	var endpoint := outdoors.to_global(Vector3(-25,2,125))
	var joined := not yard.is_empty() and not safe.is_empty()
	var declared_return := false
	if joined:
		var points: PackedVector3Array = yard.points
		joined = points.size()>2 and points[0].distance_to(endpoint)<.001 and points[-1].distance_to(endpoint)<.001 \
			and safe.points[-1].distance_to(endpoint)<.001 and not yard.get("requires_jump",true)
		for index in range(points.size()-1):
			var a := outdoors.to_local(points[index])
			var b := outdoors.to_local(points[index+1])
			if absf(a.z-124)<.001 and absf(b.z-124)<.001 and absf(a.y-2)<.001 and absf(b.y-2)<.001 \
				and minf(a.x,b.x)<=-25.0+.001 and maxf(a.x,b.x)>=20.0-.001:
				declared_return=true
	check.call(joined and declared_return,
		"compact Clyde: published yard circuit joins the safe crossing at both ends through the actual south-return lane")
	var clear := true
	for offset: float in [-.7,0.0,.7]:
		var previous := Vector3.INF
		for index: int in range(91):
			var at := outdoors.to_global(Vector3(-25+float(index)*.5,2,124+offset))
			clear=_supported_clear(world,at,at.y) and clear
			if previous.is_finite(): clear=_clear_sweep(world,previous,at) and _clear_sweep(world,at,previous) and clear
			previous=at
	check.call(clear,
		"compact Clyde: complete south return has real centre/plus-minus0.7m rider support and capsule motion in both directions")


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


static func _raised_deck_containment(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var guard: StaticBody3D = null
	for body: StaticBody3D in outdoors.find_children("*","StaticBody3D",true,false):
		if str(body.get_meta("boundary_family",""))!="QuayLandwardBoundary": continue
		var points: PackedVector3Array = body.get_meta("boundary_points",PackedVector3Array())
		if points.size()>1 and points[0].x < -70 and absf(points[-1].x+15)<.001:
			guard = body
	var solid := guard!=null
	var real_top := -INF
	if guard!=null:
		solid = bool(guard.get_meta("solid_boundary",false)) and _has_visible_geometry(guard)
		for node: Node in guard.get_children():
			if node is CollisionShape3D and node.shape is BoxShape3D and not node.disabled:
				var top: Vector3 = node.to_global(Vector3(0,node.shape.size.y/2,0))
				real_top = maxf(real_top,outdoors.to_local(top).y)
	check.call(solid and absf(real_top-12)<.001,
		"compact Clyde: existing west landward span is visible solid masonry with actual topY12 behind the raised ramps")
	var decks := [Vector3(-50.2,5.2,60.5),Vector3(-33.8,5.2,60.5),Vector3(-19.2,5.2,62)]
	var supported := true
	var roll_blocked := true
	var charged_blocked := true
	var vert_bound_blocked := true
	for local: Vector3 in decks:
		var at := outdoors.to_global(local)
		var floor_hit := _ray(world,at+Vector3.UP*.2,at-Vector3.UP*.2)
		supported = not floor_hit.is_empty() and floor_hit.collider.name=="SupportedDeck" \
			and floor_hit.position.distance_to(at)<.001 and _capsule_clear(world,at) and supported
		for foot_y: float in [5.2,7.4,10.2]:
			var from := outdoors.to_global(Vector3(local.x,foot_y,local.z))
			var to := outdoors.to_global(Vector3(local.x,foot_y,52))
			var hit := _ray(world,from+Vector3.UP*.2,to+Vector3.UP*.2)
			var blocked: bool = not _clear_sweep(world,from,to) and not hit.is_empty() and hit.collider==guard
			if foot_y<6: roll_blocked = blocked and roll_blocked
			elif foot_y<8: charged_blocked = blocked and charged_blocked
			else: vert_bound_blocked = blocked and vert_bound_blocked
	check.call(supported,
		"compact Clyde: both half-pipe decks and quarter deck retain actual supported clear Y5.2 starts")
	check.call(roll_blocked,
		"compact Clyde: real rider capsules cannot roll north from any raised deck above the oldY5 guard")
	check.call(charged_blocked,
		"compact Clyde: physical west closure blocks northward capsules at charged deck-jump heightY7.4")
	check.call(vert_bound_blocked,
		"compact Clyde: physical west closure blocks northward capsules above the conservative native lip-apex heightY10.2")
	var joins := true
	for x: float in [-80.9,-15.1]:
		var hit := _ray(world,outdoors.to_global(Vector3(x,3.1,56)),outdoors.to_global(Vector3(x,3.1,54)))
		joins = not hit.is_empty() and hit.collider==guard and joins
	var port := true
	for x: float in [-14.3,-12.0,-9.7]:
		var previous := Vector3.INF
		for z: float in [50.0,52.0,54.0,55.5,57.0,59.0]:
			var at := outdoors.to_global(Vector3(x,0,z))
			var height: float = world.get_ground_height(at)
			if not is_finite(height):
				port=false
				previous=Vector3.INF
				continue
			at.y=height
			port = _supported_clear(world,at,height) and port
			if previous.is_finite(): port=_clear_sweep(world,previous,at) and _clear_sweep(world,at,previous) and port
			previous=at
	check.call(joins and port,
		"compact Clyde: taller west closure meets the road edge and preserves all3 clear Exchange-close tracks in both directions")


static func _opaque_boundary_faces(world: Node3D, outdoors: Node3D, check: Callable) -> void:
	var scope := true
	var material_and_data := true
	var face_coverage := true
	var panels := 0
	var prisms := 0
	var triangles := 0
	var shared_materials: Dictionary = world.get("_materials")
	var shared_stone: Material = shared_materials.get("stone_light")
	for body: StaticBody3D in outdoors.find_children("*","StaticBody3D",true,false):
		var family := str(body.get_meta("boundary_family",""))
		var intended := family in ["QuayApproachBoundary","NorthQuayEndBoundary","QuayLandwardBoundary"] \
			and not bool(body.get_meta("solid_boundary",false))
		var opaque := bool(body.get_meta("opaque_boundary",false))
		scope = intended==opaque and scope
		if not intended: continue
		panels+=1
		var faces: Array[Dictionary] = []
		for shape: Node in body.get_children():
			if not shape is CollisionShape3D: continue
			if not shape.shape is ConvexPolygonShape3D or shape.disabled:
				face_coverage=false
				continue
			prisms+=1
			var points := PackedVector3Array()
			for point: Vector3 in shape.shape.points: points.append(shape.to_global(point))
			var hull_faces := _convex_supporting_faces(points)
			face_coverage = points.size()==8 and hull_faces.size()==6 and face_coverage
			faces.append_array(hull_faces)
		var displays: Array[MeshInstance3D] = []
		for child: Node in body.get_children():
			if child is MeshInstance3D and child.is_visible_in_tree(): displays.append(child)
			if child is MultiMeshInstance3D: material_and_data=false
		material_and_data = displays.size()==1 and material_and_data
		for display: MeshInstance3D in displays:
			if not display.mesh is ArrayMesh or display.mesh.get_surface_count()!=1:
				material_and_data=false
				continue
			material_and_data = display.material_override==shared_stone \
				and shared_stone is BaseMaterial3D \
				and shared_stone.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED \
				and not shared_stone.normal_enabled and material_and_data
			var data: Array = display.mesh.surface_get_arrays(0)
			if not data[Mesh.ARRAY_VERTEX] is PackedVector3Array or not data[Mesh.ARRAY_NORMAL] is PackedVector3Array \
				or not data[Mesh.ARRAY_TEX_UV] is PackedVector2Array or not data[Mesh.ARRAY_TANGENT] is PackedFloat32Array:
				material_and_data=false
				continue
			var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = data[Mesh.ARRAY_TEX_UV]
			var tangents: PackedFloat32Array = data[Mesh.ARRAY_TANGENT]
			var indices := PackedInt32Array()
			if data[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=data[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for index: int in vertices.size(): indices.append(index)
			if normals.size()!=vertices.size() or uvs.size()!=vertices.size() or tangents.size()!=vertices.size()*4:
				material_and_data=false
				continue
			var normal_frame: Basis = display.global_basis.inverse().transposed()
			for offset: int in range(0,indices.size(),3):
				var ia: int=indices[offset]
				var ib: int=indices[offset+1]
				var ic: int=indices[offset+2]
				var a: Vector3=display.to_global(vertices[ia])
				var b: Vector3=display.to_global(vertices[ib])
				var c: Vector3=display.to_global(vertices[ic])
				var cross: Vector3=(b-a).cross(c-a)
				var area: float=cross.length()*.5
				var outward: Vector3=-cross.normalized()
				var triangle:=PackedVector3Array([a,b,c])
				triangles+=1
				face_coverage = area>.000001 and _record_matching_face(faces,triangle,outward,area) and face_coverage
				material_and_data = absf((uvs[ib]-uvs[ia]).cross(uvs[ic]-uvs[ia]))>.000001 and material_and_data
				for index: int in [ia,ib,ic]:
					var normal: Vector3=(normal_frame*normals[index]).normalized()
					var tangent:=Vector3(tangents[index*4],tangents[index*4+1],tangents[index*4+2])
					material_and_data = normal.is_finite() and normal.dot(outward)>.999 \
						and tangent.is_finite() and tangent.length()>.9 \
						and absf(normals[index].dot(tangent))<.001 and material_and_data
		for face: Dictionary in faces:
			if absf(float(face.seen)-float(face.area))>maxf(.0003,float(face.area)*.00003):
				print("COMPACT_CLYDE_OPAQUE_FACE body=",body.name," normal=",face.normal," required=",face.area," actual=",face.seen)
				face_coverage=false
	check.call(scope and panels==8,
		"compact Clyde: opaque treatment is limited to all8 existing dry approach/end/ordinary-landward boundary bodies")
	check.call(material_and_data,
		"compact Clyde: each graded closure uses one opaque shared-stone surface with finite outward normals and valid texture tangents")
	check.call(face_coverage and triangles==prisms*12,
		"compact Clyde: displayed closed prism faces match every actual graded convex collision face without a bounding-box shortcut")
	print("COMPACT_CLYDE_OPAQUE panels=",panels," preserved_prisms=",prisms," triangles=",triangles," surfaces=",panels)


static func _convex_supporting_faces(points: PackedVector3Array) -> Array[Dictionary]:
	# Derive supporting planes from the actual convex points, independently of
	# the renderer's face index list. Each prism must expose six closed quads.
	var result: Array[Dictionary]=[]
	for ia: int in range(points.size()-2):
		for ib: int in range(ia+1,points.size()-1):
			for ic: int in range(ib+1,points.size()):
				var normal: Vector3=(points[ib]-points[ia]).cross(points[ic]-points[ia])
				if normal.length()<.000001: continue
				normal=normal.normalized()
				var distance: float=normal.dot(points[ia])
				var positive:=false
				var negative:=false
				for point: Vector3 in points:
					positive=positive or normal.dot(point)-distance>.0003
					negative=negative or normal.dot(point)-distance<-.0003
				if positive and negative: continue
				if positive:
					normal=-normal
					distance=-distance
				var duplicate:=false
				for face: Dictionary in result:
					if normal.dot(face.normal)>.99999 and absf(distance-float(face.distance))<.0003: duplicate=true
				if duplicate: continue
				var corners:=PackedVector3Array()
				var center:=Vector3.ZERO
				for point: Vector3 in points:
					if absf(normal.dot(point)-distance)<.0003:
						corners.append(point)
						center+=point
				if corners.size()!=4: continue
				center/=corners.size()
				var axis: Vector3=(corners[0]-center).normalized()
				var other: Vector3=normal.cross(axis)
				var ordered: Array[Dictionary]=[]
				for point: Vector3 in corners:
					var offset: Vector3=point-center
					ordered.append({"point":point,"angle":atan2(offset.dot(other),offset.dot(axis))})
				ordered.sort_custom(func(a: Dictionary,b: Dictionary)->bool: return float(a.angle)<float(b.angle))
				var area:=0.0
				for index: int in ordered.size():
					var a: Vector3=ordered[index].point-center
					var b: Vector3=ordered[(index+1)%ordered.size()].point-center
					area+=a.cross(b).dot(normal)*.5
				result.append({"normal":normal,"distance":distance,"corners":corners,"area":absf(area),"seen":0.0})
	return result


static func _record_matching_face(faces: Array[Dictionary], triangle: PackedVector3Array,
		outward: Vector3, area: float) -> bool:
	for face: Dictionary in faces:
		if outward.dot(face.normal)<.999: continue
		var matches:=true
		for vertex: Vector3 in triangle:
			var found:=false
			for corner: Vector3 in face.corners:
				if vertex.distance_to(corner)<.0003: found=true
			matches=matches and found
		if matches:
			face.seen=float(face.seen)+area
			return true
	return false


static func _compact_surface_separation(outdoors: Node3D, check: Callable) -> void:
	var run: float=4*sin(deg_to_rad(35))
	var footprint:=Rect2(43,126,4.5+run,3.5+run)
	var hip: Node3D=outdoors.get_node("PrintYardCurvedBankHip")
	var hip_faces: PackedVector3Array=FaceProbe._visual_faces(hip)
	var hip_flat: Array[PackedVector2Array]=FaceProbe._horizontal_triangles(hip_faces,2)
	var extent: Dictionary=_visible_extent(outdoors,hip)
	var coverage: bool=not extent.is_empty() and not hip_faces.is_empty() \
		and Vector2(extent.low.x,extent.low.z).distance_to(footprint.position)<.001 \
		and Vector2(extent.high.x,extent.high.z).distance_to(footprint.end)<.001 \
		and absf(FaceProbe._projected_area(hip_faces)-footprint.get_area())<.005
	var previous_overlap:=0.0
	var current_overlap:=0.0
	for id: String in ["ClydeSouthQuay","ClydePrintYardGround"]:
		var body: Node3D=outdoors.get_node(id)
		var original: PackedVector3Array=FaceProbe._collision_faces(body)
		var visible: PackedVector3Array=FaceProbe._visual_faces(body)
		previous_overlap+=FaceProbe._overlap_area(FaceProbe._horizontal_triangles(original,2),hip_flat)
		current_overlap+=FaceProbe._overlap_area(FaceProbe._horizontal_triangles(visible,2),hip_flat)
		var expected_region: Rect2=SOUTH if id=="ClydeSouthQuay" else YARD
		var expected_removed: float=expected_region.intersection(footprint).get_area()
		# Other approved features also cut the floor skin. Measure only this
		# protected hip footprint, retaining its original exact local removal.
		var region: Array[PackedVector2Array] = [PackedVector2Array([footprint.position,Vector2(footprint.end.x,footprint.position.y),footprint.end,Vector2(footprint.position.x,footprint.end.y)])]
		var removed_here: float = FaceProbe._overlap_area(FaceProbe._horizontal_triangles(original,2),region) 			-FaceProbe._overlap_area(FaceProbe._horizontal_triangles(visible,2),region)
		coverage=absf(removed_here-expected_removed)<.01 and coverage
		for vertex: Vector3 in visible: coverage=FaceProbe._on_faces(vertex,original) and coverage
	check.call(previous_overlap>.001 and current_overlap<.00001 and coverage,
		"compact Clyde: genuine hip-to-floor coplanar counterexample is removed while the whole physical hip footprint stays visibly covered")
	var deck: Node3D=outdoors.get_node("ClydeBridgeSouthDeck")
	var quay: Node3D=outdoors.get_node("ClydeSouthQuay")
	var collision: PackedVector3Array=FaceProbe._collision_faces(deck)
	var display: PackedVector3Array=FaceProbe._visual_faces(deck)
	var ground: Array[PackedVector2Array]=FaceProbe._horizontal_triangles(FaceProbe._collision_faces(quay),2)
	var old_area: float=FaceProbe._overlap_area(FaceProbe._horizontal_triangles(collision,2),ground)
	var new_area: float=FaceProbe._overlap_area(FaceProbe._horizontal_triangles(display,2),ground)
	var slope_preserved: bool=not display.is_empty()
	for vertex: Vector3 in display: slope_preserved=FaceProbe._on_faces(vertex,collision) and slope_preserved
	check.call(absf(old_area-40)<.001 and new_area<.00001 and slope_preserved \
		and absf(FaceProbe._projected_area(collision)-FaceProbe._projected_area(display)-40)<.005,
		"compact Clyde: flat metal landing loses its actual40m2 paving overlap while its complete graded approach remains visible")
	print("COMPACT_CLYDE_SURFACE hip_old_overlap=",previous_overlap," hip_current_overlap=",current_overlap,
		" hip_projected_area=",FaceProbe._projected_area(hip_faces)," bridge_old_overlap=",old_area," bridge_current_overlap=",new_area)


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
