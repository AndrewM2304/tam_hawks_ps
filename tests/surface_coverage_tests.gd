extends RefCounted
## Real level collision + eligibility checks. No renderer/human-feel claim.

const Ride = preload("res://game/tricks/grind_ride.gd")
const WallRide = preload("res://game/player/wall_ride.gd")
const SkaterProbe = preload("res://game/player/skater.gd")
const DefaultEdges = preload("res://game/levels/skate_edges.gd")
const INHERITED_OBSTRUCTIONS := {
  "clyde_half_west_coping": "retained landward halfpipe wall blocks an interior coping approach",
  "Grind_Edge_StairCheek_x-1000y90z-900_3_0": "inner stair cheek meets the adjoining native stair solid",
  "Grind_Edge_StairCheek_x1000y90z-900_3_0": "inner stair cheek meets the adjoining native stair solid",
  "Grind_Edge_MarketCounter_x10800y60z200_0_0": "stocked counter approach intersects its preserved native goods",
  "Grind_Edge_MarketCounter_x12000y60z200_2_0": "stocked counter approach intersects its preserved native goods",
  "Grind_Edge_StreetBenchSeat_x-12700y200z2800_0_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x-12700y200z2800_1_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x-12700y200z2800_3_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x6000y0z4150_0_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x6000y0z4150_1_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x6000y0z4150_3_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x2900y600z-11600_0_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x2900y600z-11600_1_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x2900y600z-11600_3_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x2900y0z2700_0_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x2900y0z2700_1_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate",
  "Grind_Edge_StreetBenchSeat_x2900y0z2700_3_0": "backrest or end-frame obstructs part of this inherited seat-edge candidate"
}



static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	await tree.physics_frame
	await tree.process_frame
	var audit: Dictionary = world.get_surface_audit()
	check.call(audit.collider_count > 150 and audit.wallrideable_count > 20,
		"surface audit: inventories real level colliders and substantial rideable walls")
	var top_edges: Dictionary = {}
	for record: Dictionary in audit.surfaces:
		for id: String in record.grind_ids: top_edges[id] = true
	check.call(audit.generated_grind_count > 0 and top_edges.size() >= 40 and audit.ledge_body_count >= 20,
		"surface audit: generated and retained semantic furniture edges expose at least40 collision-backed top candidates")
	var lines: Dictionary = {}
	var duplicate_ids := false
	for line in world.get_grind_lines():
		duplicate_ids = duplicate_ids or lines.has(line.id)
		lines[line.id] = line
	check.call(not duplicate_ids, "surface audit: all authored and derived grind tracks retain unique stable IDs")
	var classified := true
	var boundary_excluded := true
	var eligible_helpers_agree := true
	var candidate_covered := true
	var referenced_tracks_exist := true
	var generated_capture_count := 0
	var authored_capture_count := 0
	var blocked: Array[String] = []
	# Use the real CharacterBody/profile and production admission policy, not
	# the separate ground-route volume with its floor-clearance allowance.
	if not InputMap.has_action("ollie"): preload("res://game/core/input_setup.gd").register_actions()
	var previous_camera := world.get_viewport().get_camera_3d()
	var rider := SkaterProbe.new()
	world.add_child(rider)
	rider.set_physics_process(false)
	rider.set_process(false)
	if is_instance_valid(previous_camera): previous_camera.current = true
	await tree.physics_frame
	await tree.process_frame
	for record: Dictionary in audit.surfaces:
		var body := world.get_node(NodePath(record.path)) as StaticBody3D
		classified = classified and body != null and body.has_meta("surface_audit_id") and not record.wall_reason.is_empty()
		if body.get_meta("exploration_boundary", false):
			if body.get_meta("boundary_family","")=="SouthPocketRearBoundary":
				boundary_excluded = boundary_excluded and record.wallrideable \
					and body.get_meta("solid_boundary",false) and not body.get_meta("no_wallride",true) \
					and _printyard_wall_backed(world,body)
			else:
				boundary_excluded = boundary_excluded and not record.wallrideable and body.get_meta("no_wallride", false)
		if record.wallrideable:
			eligible_helpers_agree = eligible_helpers_agree and WallRide.is_surface_eligible(body)
		if record.generated_ledge:
			candidate_covered = candidate_covered and not record.grind_ids.is_empty()
		for id: String in record.grind_ids:
			referenced_tracks_exist = referenced_tracks_exist and lines.has(id)
			var generated := id.begins_with("Grind_Ledge_" + record.id + "_")
			if not generated and not record.capture_check_ids.has(id): continue
			var line = lines[id]
			var usable := true
			for fraction: float in [0.2,0.5,0.8]:
				var at: Vector3 = line.point_at(line.length * fraction)
				var tangent: Vector3 = line.dir_at(line.length * fraction)
				var approach := Vector3(tangent.x,0,tangent.z).normalized()*6.0-Vector3.UP
				var ride = Ride.new()
				usable = usable and ride.start([line], at + Vector3.UP * 0.15,
					approach, func(from: Vector3, to: Vector3) -> bool: return rider._rail_path_clear(from,to))
			if usable:
				if generated: generated_capture_count += 1
				else: authored_capture_count += 1
			else: blocked.append(id)
	check.call(classified and boundary_excluded,
		"surface audit: every physical surface has a reason; fences stay excluded and only the independently backed print-yard masonry boundary admits wallrides")
	check.call(eligible_helpers_agree, "surface audit: architecture wall tags agree with production wallride eligibility")
	check.call(candidate_covered and referenced_tracks_exist,
		"surface audit: each selected visible ledge candidate references actual published grind tracks")
	if not blocked.is_empty(): print("SURFACE BLOCKED GENERATED TRACKS ", blocked)
	check.call(blocked.is_empty() and generated_capture_count == audit.generated_grind_count and authored_capture_count >= 10,
		"surface audit: new generated and raised-terrain ledges capture at three interior points with the production capsule and native collision sweep")
	var dense_samples := 0
	var dense_blocked: Array[String] = []
	var dense_positive: Dictionary = {}
	var dense_witnesses: Dictionary = {}
	for line in lines.values():
		var count := maxi(4,ceili(line.length/0.35))
		for i in range(1,count):
			var distance: float = line.length*i/count
			var point: Vector3 = line.point_at(distance)
			var next: Vector3 = line.point_at(minf(line.length,distance+0.20))
			dense_samples += 1
			if not rider._rail_path_clear(point+Vector3.UP*0.12,point) or not rider._rail_path_clear(point,next):
				if not dense_blocked.has(line.id):
					dense_blocked.append(line.id)
					dense_witnesses[line.id] = {"point":point,"next":next,"reason":INHERITED_OBSTRUCTIONS.get(line.id,"UNEXPECTED")}
			else: dense_positive[line.id] = int(dense_positive.get(line.id,0))+1
	if not dense_blocked.is_empty(): print("PRODUCTION DENSE ADMISSION BLOCKED ",dense_blocked)
	print("PRODUCTION DENSE ADMISSION samples=",dense_samples)
	var expected_blocked: Array = INHERITED_OBSTRUCTIONS.keys()
	expected_blocked.sort()
	dense_blocked.sort()
	check.call(dense_samples>=5000 and dense_blocked==expected_blocked,
		"surface audit: over5000 native-profile sweeps admit every unlisted track and independently reject exactly17 documented inherited obstructed candidates")
	for id: String in expected_blocked:
		check.call(dense_witnesses.has(id),"surface audit: actual native admission refuses documented obstruction "+id)
	print("SURFACE INHERITED NEGATIVE WITNESSES ",JSON.stringify(dense_witnesses))
	var bench_fronts_clear := true
	for location: String in ["x-12700y200z2800","x6000y0z4150","x2900y600z-11600","x2900y0z2700"]:
		var front := "Grind_Edge_StreetBenchSeat_"+location+"_2_0"
		bench_fronts_clear = bench_fronts_clear and dense_positive.get(front,0)>0 and not dense_blocked.has(front)
	check.call(bench_fronts_clear,"surface audit: each inherited bench retains its usable unobstructed front edge")
	rider.queue_free()
	var snapshot: Dictionary = world.get_surface_audit()
	snapshot.surfaces.clear()
	check.call(not world.get_surface_audit().surfaces.is_empty(), "surface audit: callers cannot mutate the level inventory")
	for family: String in ["safe", "north", "south"]:
		for side: String in ["west", "east"]:
			var id := "clyde_" + family + "_handrail_" + side
			var rail = lines.get(id)
			check.call(rail != null and rail.is_valid and rail.kind == "rail",
				"surface audit: visible bridge handrail is grindable " + family + " " + side)
			if rail != null and family != "safe":
				var bounded := true
				for at: Vector3 in rail.points: bounded = bounded and (at.z <= 94.001 if family == "north" else at.z >= 101.999)
				check.call(bounded, "surface audit: broken bridge rail cannot bridge the water gap " + family + " " + side)
	var pockets: Array = []
	for definition: Dictionary in world.get_skate_feature_definitions():
		if definition.id == "kelvingrove_promenade_practice": pockets.append(definition)
	for feature: Dictionary in world.get_transition_features():
		if feature.id != "clyde_quarter": continue
		var frame: Transform3D = feature.transform
		pockets.append({"id":"clyde_quarter_native","approach":PackedVector3Array([frame*Vector3(0,0,10),frame.origin])})
	check.call(pockets.size() == 2 and tree.get_nodes_in_group("skate_transitions").size() >= 2,
		"surface audit: existing quay and park connector each have a real transition practice pocket")
	for pocket: Dictionary in pockets:
		var supported := true
		var clear := true
		var points: PackedVector3Array = pocket.approach
		for step in 16:
			var at := points[0].lerp(points[1], float(step) / 16.0)
			var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.2, at - Vector3.UP * 0.4, 1)
			var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
			supported = supported and not hit.is_empty() and absf(hit.position.y - at.y) < 0.06
			clear = clear and _clear_capture(world, at, at)
		check.call(supported and clear and points[0].distance_to(points[1]) >= 10.0,
			"surface audit: ten-metre-plus transition approach and landing are truly supported and clear " + pocket.id)
	# Native side probes prove representative tagged masonry is real, finite
	# architecture, rather than a visual-only plane or an infinite metadata wall.
	# PT24-20 deliberately replaces the recording wall with a low kerb/bearing;
	# the substantial PT24-24 print-yard boundary remains real backed masonry.
	var wall := world.get_node("OutdoorRoutes/SouthPocketRearBoundary") as StaticBody3D
	var side_hit := world.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(61,3.4,141.9),Vector3(61,3.4,143.4),1))
	check.call(wall.get_meta("wallrideable",false) and side_hit.get("collider") == wall and absf(side_hit.normal.z) > 0.99,
		"surface audit: representative wallride masonry has the expected real vertical side face")
	var retaining := world.get_node("CivicForecourt") as StaticBody3D
	var retaining_hit := world.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(15,5.35,-106.8),Vector3(15,5.35,-108.5),1))
	check.call(retaining.get_meta("wallrideable",false) and retaining_hit.get("collider") == retaining and absf(retaining_hit.normal.z) > 0.99,
		"surface audit: exposed convex retaining masonry supports wallrides with a real vertical face")
	# A new raised deck must not sit above the old low-lying perimeter fence.
	# Test the actual swept capsule from apron and ordinary deck-ollie heights.
	for height: float in [6.0,6.0+pow(SkaterProbe.CHARGED_OLLIE_SPEED,2)/(2.0*SkaterProbe.GRAVITY)]:
		check.call(not _clear_capture(world,Vector3(-100,height,-139.8),Vector3(-100,height,-145)),
			"surface audit: visible park perimeter contains the new terrace at rider height " + str(height))
	# Previously decorative furniture was on accessible floors. Test the actual
	# support and track-to-rendered-face relationship, not its former scenery claim.
	var benches: Array[Node] = tree.get_nodes_in_group("physical_street_benches")
	var bins: Array[Node] = tree.get_nodes_in_group("physical_street_bins")
	check.call(benches.size()==4 and bins.size()==4,
		"surface audit: all four accessible street furniture groups have physical seats and containers")
	var space := world.get_world_3d().direct_space_state
	for bench: StaticBody3D in benches:
		var supported := true
		for x: float in [-1.1,1.1]:
			for z: float in [-0.2,0.2]:
				var foot := bench.to_global(Vector3(x,0,z))
				var query := PhysicsRayQueryParameters3D.create(foot+Vector3.UP*0.1,foot-Vector3.UP*0.2,1)
				query.exclude = [bench.get_rid()]
				var hit := space.intersect_ray(query)
				supported = supported and not hit.is_empty() and absf(hit.position.y-foot.y)<0.015
		var associated: Array = _associated_grinds(bench)
		var matching_faces := associated.size()>=2
		for id: String in associated:
			var track = lines[id]
			var hits := 0
			for fraction: float in [0.2,0.5,0.8]:
				var point: Vector3 = track.contact_at(track.length*fraction)
				if not track.contact_verified: point -= Vector3.UP*DefaultEdges.SKIN
				# Probe10mm inside a finite envelope edge; short side candidates
				# cross the real20mm slat gaps, which stay physically open.
				var local := bench.to_local(point)
				var toward := Vector3(-local.x,0,-0.01-local.z).normalized()*0.01
				var probe := point+bench.global_basis*toward
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(probe+Vector3.UP*0.12,probe-Vector3.UP*0.12,1))
				if hit.get("collider")==bench and absf(point.y-hit.get("position",Vector3.INF).y)<0.005: hits+=1
			matching_faces = matching_faces and hits>=2
		check.call(supported and matching_faces,
			"surface audit: actual slatted bench feet rest on ground and associated candidates meet real wood without filling its gaps "+str(bench.global_position))
	for container: StaticBody3D in bins:
		var at := container.global_position
		var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.1,at-Vector3.UP*0.2,1)
		query.exclude = [container.get_rid()]
		var ground := space.intersect_ray(query)
		var lid := space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*1.4,at+Vector3.UP*0.9,1))
		check.call(not ground.is_empty() and absf(ground.position.y-at.y)<0.015 and lid.get("collider")==container \
			and absf(lid.get("position",Vector3.INF).y-at.y-1.17)<0.005 and container.has_meta("grind_exclusion_reason"),
			"surface audit: upright litter container has actual floor and visible-lid collision with an explicit finite-ledge exclusion "+str(container.get_meta("street_furniture_id")))
	check.call(_clear_capture(world,Vector3(57,0,39),Vector3(67,0,39)) \
		and _clear_capture(world,Vector3(67,0,39),Vector3(57,0,39)),
		"surface audit: relocated Barras furniture leaves a clear native corridor around the entire manual bank")
	for record: Dictionary in audit.surfaces:
		if record.label!="CourtPlanterSeat": continue
		var body := world.get_node(NodePath(record.path)) as StaticBody3D
		var cap_ok: bool = record.shape_count==2
		for x: float in [-0.61,0.0,0.61]:
			for z: float in [-4.03,0.0,4.03]:
				var top := body.to_global(Vector3(x,0.30,z))
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top+Vector3.UP*0.1,top-Vector3.UP*0.1,1))
				cap_ok = cap_ok and hit.get("collider")==body and absf(hit.get("position",Vector3.INF).y-top.y)<0.004
		for outside: Vector3 in [Vector3(-0.65,0.3,0),Vector3(0.65,0.3,0),Vector3(0,0.3,-4.08),Vector3(0,0.3,4.08)]:
			var top := body.to_global(outside)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top+Vector3.UP*0.1,top-Vector3.UP*0.05,1))
			cap_ok = cap_ok and hit.get("collider")!=body
		check.call(cap_ok,"surface audit: visible60mm court seat cap has native top/50mm overhang and exact finite outer bounds "+str(record.id))
	await _sunken_excavation(tree,world,check)
	_native_rail_tops(world,lines,check)
	_visible_park_materials(tree,world,check)


static func _native_rail_tops(world: Node3D,lines: Dictionary,check: Callable) -> void:
	for id: String in ["clyde_print_yard_ledge","clyde_quay_coping","clyde_bridge_rail","kelvingrove_cutback_ledge",
		"kelvingrove_terrace_coping","kelvingrove_s_bend_0","kelvingrove_s_bend_1","Grind_Rail_ClydeSouthRelay",
		"clyde_north_handrail_west","clyde_north_handrail_east","clyde_south_handrail_west","clyde_south_handrail_east"]:
		var line = lines.get(id)
		var matches: bool = line!=null and line.is_valid
		if matches:
			for fraction: float in [0.2,0.5,0.8]:
				var point: Vector3 = line.contact_at(line.length*fraction)
				var tangent: Vector3 = line.dir_at(line.length*fraction)
				var normal := (Vector3.UP-tangent*tangent.dot(Vector3.UP)).normalized()
				# Retained changing-grade guides are intentionally unverified at
				# joints; sample their actual square-beam segment crowns directly.
				if not line.contact_verified and id in ["clyde_bridge_rail","kelvingrove_s_bend_0","kelvingrove_s_bend_1"]:
					point += normal*0.065
				var hit := world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(point+normal*0.12,point-normal*0.12,1|2))
				matches = matches and not hit.is_empty() and absf((hit.position-point).dot(normal))<0.007 \
					and _associated_grinds(hit.collider).has(id)
		check.call(matches,"surface audit: finite Outdoor bearing path has matching real native beam crown "+id)


static func _visible_park_materials(tree: SceneTree,world: Node3D,check: Callable) -> void:
	var entries: Array[Dictionary] = []
	var collision_unchanged := true
	for visual: MeshInstance3D in tree.get_nodes_in_group("park_native_visual_skins"):
		entries.append({"node":visual,"triangles":visual.mesh.generate_triangle_mesh(),"bounds":visual.global_transform*visual.get_aabb()})
		for child: Node in visual.get_parent().get_children():
			if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
				collision_unchanged = collision_unchanged and visual.get_meta("native_collision_sha256")==child.shape.get_faces().to_byte_array().hex_encode().sha256_text()
	check.call(entries.size()==5 and collision_unchanged,
		"park material: visual-only repair preserves the complete native shoulder/asphalt collision face snapshots")
	var count := 0
	var good := true
	var low := INF
	var high := -INF
	var bad: Array = []
	# These are the actual reviewed riding strips. The deliberately concealed
	# three-metre terrain separation farther east is not part of this repair.
	for region: Rect2 in [Rect2(-151.2,-123.7,8.7,26.4),Rect2(-193.7,-105.7,33.4,21.4)]:
		for x in ceili(region.size.x/0.4):
			for z in ceili(region.size.y/0.4):
				var from := Vector3(region.position.x+(x+0.5)*0.4,30,region.position.y+(z+0.5)*0.4)
				var to := from-Vector3.UP*40
				var native := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
				if native.is_empty(): continue
				var top := -INF
				for entry: Dictionary in entries:
					var bounds: AABB = entry.bounds
					if from.x<bounds.position.x or from.x>bounds.end.x or from.z<bounds.position.z or from.z>bounds.end.z: continue
					var hit: Dictionary = entry.triangles.intersect_segment(entry.node.to_local(from),entry.node.to_local(to))
					if not hit.is_empty(): top = maxf(top,entry.node.to_global(hit.position).y)
				if not is_finite(top): continue
				var separation: float = top-native.position.y
				count += 1
				low = minf(low,separation)
				high = maxf(high,separation)
				var matches: bool = separation>=0.0005 and separation<=0.009
				good = good and matches
				if not matches and bad.size()<5: bad.append({"point":Vector3(from.x,top,from.z),"gap":separation})
	if not bad.is_empty(): print("PARK MATERIAL MISMATCHES ",bad)
	print("PARK VISIBLE MATERIAL samples=",count," native_separation=",low,"..",high)
	check.call(good and count>=3000,
		"park material: actual visible mesh BVHs at over3000 reviewed road/stone sites stay above real support within nine millimetres")


static func _sunken_excavation(_tree: SceneTree,world: Node3D,check: Callable) -> void:
	var definition: Dictionary = world.get_park_skatepark_definition()
	check.call(not definition.is_empty() and world.get_node_or_null(definition.get("node_path",NodePath()))!=null,
		"sunken park: real facility, resolvable World node path and supported summit access are registered in the existing park")
	if definition.is_empty(): return
	var bounds: Rect2 = definition.bounds
	var landscape: StaticBody3D = world._outdoors.get_node("KelvingroveRollingGround")
	var faces := PackedVector3Array()
	for child: Node in landscape.get_children():
		if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
			faces = child.shape.get_faces()
	var surviving_old_hill := 0
	for i in range(0,faces.size(),3):
		var center := landscape.to_global((faces[i]+faces[i+1]+faces[i+2])/3.0)
		if bounds.has_point(Vector2(center.x,center.z)): surviving_old_hill += 1
	check.call(faces.size()/3==5688 and surviving_old_hill==0,
		"sunken park: all192 original hill cells and384 native triangles are truly excavated, with no hidden hill through the bowls")
	var space := world.get_world_3d().direct_space_state
	var grid_ok := true
	var grid_samples := 0
	var failures: Array = []
	for x in 40:
		for z in 30:
			var point := Vector3(bounds.position.x+x+0.5,0,bounds.position.y+z+0.5)
			var height: float = world.get_ground_height(point)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*30,point-Vector3.UP*2,1))
			var matches: bool = is_finite(height) and not hit.is_empty() and absf(hit.position.y-height)<0.006 and hit.collider!=landscape
			grid_ok = grid_ok and matches
			grid_samples += 1
			if not matches and failures.size()<6: failures.append({"point":point,"query":height,"native":hit.get("position",Vector3.INF)})
	if not failures.is_empty(): print("SUNKEN HEIGHT MISMATCHES ",failures)
	check.call(grid_ok and grid_samples==1200,
		"sunken park:1200 independent native rays agree with the actual deck, basin, bowl and stair height query")
	for bottom: Vector3 in [Vector3(-197,11,-194),Vector3(-219,13,-195)]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(bottom+Vector3.UP*6,bottom-Vector3.UP*0.3,1))
		check.call(not hit.is_empty() and absf(hit.position.y-bottom.y)<0.006 and hit.collider!=landscape \
			and absf(world.get_ground_height(bottom)-bottom.y)<0.006,
			"sunken park: visibly different bowl depth has real exposed native floor "+str(bottom))
	var entry_ok := true
	var access: PackedVector3Array = definition.access_route
	for segment in range(access.size()-1):
		for sample in 33:
			var point := access[segment].lerp(access[segment+1],float(sample)/32.0)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.3,point-Vector3.UP*0.3,1))
			entry_ok = entry_ok and not hit.is_empty() and absf(hit.position.y-point.y)<0.006 \
				and absf(world.get_ground_height(point)-point.y)<0.006 and absf(world.get_support_height(point,0.1)-point.y)<0.006
	check.call(entry_ok,"sunken park: every shared summit/ramp/entry seam has native support and inclusive exact height queries in both directions")
	var perimeter_ok := true
	for side in 4:
		for sample in 41:
			var fraction := float(sample)/40.0
			var point := Vector3.ZERO
			match side:
				0: point = Vector3(lerpf(bounds.position.x,bounds.end.x,fraction),0,bounds.position.y-0.04)
				1: point = Vector3(lerpf(bounds.position.x,bounds.end.x,fraction),0,bounds.end.y+0.04)
				2: point = Vector3(bounds.position.x-0.04,0,lerpf(bounds.position.y,bounds.end.y,fraction))
				3: point = Vector3(bounds.end.x+0.04,0,lerpf(bounds.position.y,bounds.end.y,fraction))
			var height: float = world.get_ground_height(point)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*30,point-Vector3.UP*2,1))
			perimeter_ok = perimeter_ok and is_finite(height) and not hit.is_empty() and absf(hit.position.y-height)<0.006
	check.call(perimeter_ok,"sunken park: actual grass collar remains continuously supported around all four excavated edges")


static func _clear_capture(world: Node3D, from: Vector3, to: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, from + Vector3.UP * 0.98)
	query.motion = to - from
	query.collision_mask = 1
	query.margin = 0.01
	var space := world.get_world_3d().direct_space_state
	if not space.intersect_shape(query).is_empty(): return false
	var cast := space.cast_motion(query)
	if cast.size() != 2 or cast[0] < 0.9999: return false
	query.transform.origin = to + Vector3.UP * 0.98
	query.motion = Vector3.ZERO
	return space.intersect_shape(query).is_empty()


static func _associated_grinds(body: Node) -> Array:
	var ids: Array = []
	for key: String in ["authored_grind_ids","grind_surface_ids"]:
		for id: String in body.get_meta(key,[]):
			if not ids.has(id): ids.append(id)
	return ids


static func _printyard_wall_backed(world: Node3D, body: StaticBody3D) -> bool:
	# Fixed physical envelope, independent of opt-in tags or surface-audit data.
	# The original safe perimeter remains solid beyond this authored wall line.
	var shapes := body.find_children("*","CollisionShape3D",false,false)
	if shapes.size()!=1: return false
	var shape: CollisionShape3D = shapes[0]
	if not shape.shape is BoxShape3D or shape.disabled: return false
	var bounds := shape.global_transform*AABB(-shape.shape.size*.5,shape.shape.size)
	if bounds.position.distance_to(Vector3(-38.98,1.75,142.62))>.001 \
		or bounds.end.distance_to(Vector3(75.98,5.,142.98))>.001: return false
	var display := body.get_node_or_null("PropertyMasonry") as MultiMeshInstance3D
	if display==null or not display.is_visible_in_tree() or display.multimesh.instance_count!=1 \
		or not display.multimesh.mesh is BoxMesh or display.material_override==null: return false
	for x: float in [-38.7,0.,75.7]:
		for y: float in [2.,3.,4.8]:
			for side: float in [-1.,1.]:
				var a := Vector3(x,y,142.8-side*.5)
				var b := Vector3(x,y,142.8+side*.5)
				var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1))
				if hit.get("collider")!=body: return false
	return true
