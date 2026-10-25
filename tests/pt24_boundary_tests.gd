extends RefCounted
## Fixed screenshot contracts, independent of the generator's existing bodies.
## Native collision and displayed triangles are sampled without playing routes.

static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	await tree.physics_frame
	await tree.process_frame
	var samples := 0
	var civic := true
	# Capture4: the last1.2m between the east civic fence and solid frontage.
	# The below-baseline face is the real Horizon foundation; above it, the
	# native panel must stop a rider at ankle/torso/jump heights from both sides.
	for index: int in 13:
		var x := lerpf(34.8,36.,float(index)/12.)
		for y: float in [4.15,5.,6.75]:
			for side: float in [-1.,1.]:
				var at := Vector3(x,y,-56.)
				civic = not _ray(world,at+Vector3.FORWARD*side*.3,at-Vector3.FORWARD*side*.3).is_empty() and civic
				samples += 1
		var at := Vector3(x,3.9,-56.)
		civic = _visible_segment(world.get_node("HorizonContext"),at+Vector3.FORWARD*.1,at-Vector3.FORWARD*.1) and civic
	check.call(civic,"PT24-02: all fixed Civic frontage-return sites have native rider-height closure and a displayed foundation, including both endpoints")
	# Capture6: the north-going dead end beside the Civic port is a closed
	# outside edge; the west-going park connection atZ-122 remains traversable.
	var civic_port_edge := true
	for index: int in 28:
		var x := lerpf(-41.9,-35.2,float(index)/27.)
		for y: float in [6.15,7.,8.75]:
			for side: float in [-1.,1.]:
				var at := Vector3(x,y,-127.8)
				civic_port_edge = not _ray(world,at+Vector3.FORWARD*side*.3,at-Vector3.FORWARD*side*.3).is_empty() and civic_port_edge
				samples += 1
		var below := Vector3(x,5.5,-127.8)
		civic_port_edge = _visible_segment(world.get_node("HorizonContext"),below+Vector3.FORWARD*.1,below-Vector3.FORWARD*.1) and civic_port_edge
	check.call(civic_port_edge,"PT24-03 capture6: the fixed Civic-port north edge has native ankle, torso and jump closure plus displayed grounded foundations")
	# Capture31: ironwork originally let the void behind the station show.
	# Required opaque spans are explicit; a wholly omitted wall fails here.
	var station := true
	for span: Vector2 in [Vector2(-130,-102),Vector2(-86,-50)]:
		for index: int in ceili((span.y-span.x)/.5)+1:
			var x := minf(span.x+index*.5,span.y)
			for y: float in [2.15,3.,4.75]:
				var at := Vector3(x,y,44.8)
				for side: float in [-1.,1.]:
					var start := at+Vector3.FORWARD*side*.3
					var end := at-Vector3.FORWARD*side*.3
					var hit := _ray(world,start,end)
					station = not hit.is_empty() and _visible_segment(hit.get("collider"),start,end) and station
					samples += 1
	check.call(station,"PT24-22 capture31: both independently fixed station spans are opaque visible/native masonry at half-metre spacing from both sides")
	# Capture30: frontZ42 is preserved; the three existing retail backs meet
	# quayZ55.2 on each side of the intentional six-metre closes.
	var retail := true
	var first_retail_failure := {}
	for span: Vector2 in [Vector2(-33,-15),Vector2(-9,9),Vector2(15,33)]:
		for index: int in 19:
			var x := clampf(lerpf(span.x,span.y,float(index)/18.),span.x+.005,span.y-.005)
			for y: float in [2.2,3.,6.]:
				var start := Vector3(x,y,54.9)
				var end := Vector3(x,y,55.4)
				var query := PhysicsRayQueryParameters3D.create(end,start,1)
				var exclusions: Array[RID] = []
				for boundary: CollisionObject3D in tree.get_nodes_in_group("exploration_boundaries"):
					exclusions.append(boundary.get_rid())
				query.exclude=exclusions
				var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
				var valid := not hit.is_empty() and absf(hit.get("position",Vector3.INF).z-55.2)<.005 \
					and _visible_segment(hit.get("collider"),start,end)
				if not valid and first_retail_failure.is_empty(): first_retail_failure={"at":start,"hit":hit}
				retail = valid and retail
				samples += 1
	if not retail: print("PT24_RETAIL_MISSING ",first_retail_failure)
	check.call(retail,"PT24-22 capture30: all three fixed retail rear spans meet quayZ55.2 with matching displayed faces and actual collision")
	# Capture21: sample across the repaired lane shoulder, including the old
	# X-82 edge. Expected height is the independent two-in32-metre lane grade.
	var shoulder := true
	for x: float in [-82.1,-82.,-81.8,-81.55]:
		for z: float in [-44.8,-44.5,-44.2]:
			var expected := 2.+(-42.-z)/16.
			var at := Vector3(x,expected,z)
			var hit := _ray(world,at+Vector3.UP*.2,at-Vector3.UP*.2)
			shoulder = not hit.is_empty() and absf(hit.get("position",Vector3.INF).y-expected)<.006 \
				and absf(world.get_ground_height(at)-expected)<.006 and shoulder
			samples += 1
	check.call(shoulder,"PT24-13: independent cross-lane sites on both sides of the formerX-82 crack match the real graded floor and height query")
	var ports := true
	for segment: Array in [
		[Vector3(34,4.8,-80),Vector3(36,4.8,-80)],
		[Vector3(-40,6.8,-122),Vector3(-43,6.8,-122)],
		[Vector3(-94,3.,44.3),Vector3(-94,3.,45.3)],
		[Vector3(-12,2.8,54.4),Vector3(-12,2.8,55.5)],
		[Vector3(12,2.8,54.4),Vector3(12,2.8,55.5)]]:
		ports = _ray(world,segment[0],segment[1]).is_empty() and _ray(world,segment[1],segment[0]).is_empty() and ports
	check.call(ports,"PT24 boundaries: the fixed civic backstreet, station/quay mouth and both Exchange closes remain open in both directions")
	print("PT24_FIXED_BOUNDARY_SAMPLES ",samples)


static func _ray(world: Node3D, start: Vector3, end: Vector3) -> Dictionary:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,1))


static func _visible_segment(parent: Node, start: Vector3, end: Vector3) -> bool:
	if parent==null: return false
	for display: MeshInstance3D in parent.find_children("*","MeshInstance3D",true,false):
		if display.mesh==null or not display.is_visible_in_tree(): continue
		var triangles := display.mesh.generate_triangle_mesh()
		if triangles==null: continue
		if not triangles.intersect_segment(display.to_local(start),display.to_local(end)).is_empty(): return true
	return false
