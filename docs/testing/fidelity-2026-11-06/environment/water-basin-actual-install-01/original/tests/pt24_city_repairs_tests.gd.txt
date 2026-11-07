extends RefCounted
## Fixed owner locations; actual native support decides whether each seam exists.

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	await tree.physics_frame
	var world: Node3D = game.world
	var space := world.get_world_3d().direct_space_state
	var shoulder := true
	for x: float in [-82.25,-81.95,-81.75,-81.55]:
		for z: float in [-44.5,-45.5]:
			var y := 2.0+(-42.0-z)/16.0
			var at := Vector3(x,y,z)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.15,1))
			shoulder = shoulder and not hit.is_empty() and absf(hit.position.y-y)<.001 \
				and absf(world.get_ground_height(at)-y)<.001
	check.call(shoulder,"PT24-13: eight native samples span the former 30cm climbing-lane frontage crack")
	var ramp := true
	var previous := NAN
	for step: int in range(33):
		var z := -74.0+step*.25
		var at := Vector3(-75,5,z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at,at-Vector3.UP*5,1))
		if hit.is_empty():
			ramp = false
			continue
		var actual: float = hit.position.y
		ramp = ramp and absf(world.get_ground_height(Vector3(-75,actual,z))-actual)<.001
		if is_finite(previous): ramp = ramp and absf(previous-actual)<.13
		previous = actual
	check.call(ramp and absf(previous-1)<.001,"PT24-14: low-court exit joins back street to lower paving without a discontinuity")
	var overlap := true
	for x: float in [-143.0,-141.5,-140.0]:
		var at := Vector3(x,3,-3.586)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at,at-Vector3.UP*2,1))
		overlap = overlap and not hit.is_empty() and absf(world.get_ground_height(at)-hit.position.y)<.002 \
			and absf(world.get_support_height(Vector3(x,2.1,-3.586),.3)-hit.position.y)<.002
	check.call(overlap,"PT24-07: overlapping city/park support queries select the actual higher native shoulder")
	check.call(absf(world.get_support_height(Vector3(-114,2,-8),.3)-2)<.001 \
		and absf(world.get_ground_height(Vector3(-114,5,-8))-5)<.001,
		"PT24 support: height-limited lower station passage and suspended route remain distinct")
	var basin: MeshInstance3D = world.get_node("ExchangeFountain/FountainBasin")
	var water: MeshInstance3D = world.get_node("ExchangeFountain/FountainWater")
	var basin_mesh := basin.mesh as CylinderMesh
	var water_mesh := water.mesh as CylinderMesh
	check.call(basin_mesh.radial_segments==64 and water_mesh.radial_segments==64 \
		and absf(basin_mesh.top_radius-water_mesh.top_radius-.24)<.00001 \
		and absf(water.position.y+water_mesh.height*.5-.555)<.00001,
		"PT24-26: circular water shares the basin's 64 segments and fits inside a 24cm rim")
	var contained := true
	for vertex: Vector3 in water_mesh.get_faces():
		contained = contained and Vector2(vertex.x,vertex.z).length()<=basin_mesh.top_radius-.2399
	check.call(contained,"PT24-26: every actual water vertex remains inside the basin coping")
