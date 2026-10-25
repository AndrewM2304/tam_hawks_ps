extends RefCounted
## The gallery seam keeps its full native slab while the two streets own
## exactly56m² of shared paving. World-XZ cuts also work under a translated root.
const Terrain = preload("res://game/levels/core_terrain.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	var root := Node3D.new()
	root.position = Vector3(200,20,300)
	tree.root.add_child(root)
	var terrain := Terrain.new()
	var material := StandardMaterial3D.new()
	var bounds := Rect2(-35,-56,70,2)
	var heights := Vector4(4,4,26.0/7.0,26.0/7.0)
	var baseline: StaticBody3D = terrain.add_patch(root,"FullFoundation",bounds,heights,material)
	var cut: StaticBody3D = terrain.add_patch(root,"TrimmedFoundation",bounds,heights,material,"stone",-1,
		[Rect2(171,244,14,2),Rect2(215,244,14,2)])
	var before := _faces(baseline)
	var after := _faces(cut)
	check.call(absf(_top_area(before)-140)<0.001 and absf(_top_area(after)-84)<0.005,
		"terrain top ownership: two14x2m street bands remove exactly56 of140 visible square metres")
	var supported_plane := true
	for i in range(0,after.size(),3):
		if not _top(after,i):continue
		for offset: int in 3:
			var point := cut.to_global(after[i+offset])
			var expected := 24.0-(point.z-244.0)/7.0
			supported_plane = supported_plane and absf(point.y-expected)<0.00025
	check.call(supported_plane,"terrain top ownership: every clipped paving vertex retains the original graded plane")
	var one_owner := true
	for x: float in [-28,-20,-16,16,20,28]:
		for z: float in [-55.875,-55.5,-54.125]:
			one_owner = one_owner and not _top_at(cut,after,Vector2(200+x,300+z))
	for x: float in [-34,-30,-14,-10,0,10,14,30,34]:
		for z: float in [-55.875,-55.5,-54.125]:
			one_owner = one_owner and _top_at(cut,after,Vector2(200+x,300+z))
	check.call(one_owner,"terrain top ownership: independent street/interior samples have exactly the intended visible foundation ownership")
	check.call(_retaining(before)==_retaining(after) and _retaining(after).size()==30,
		"terrain top ownership: all ten original side and bottom triangles remain byte-identical")
	var original_shape: ConvexPolygonShape3D = baseline.get_child(0).shape
	var clipped_shape: ConvexPolygonShape3D = cut.get_child(0).shape
	check.call(original_shape.points==clipped_shape.points and clipped_shape.points.size()==8 \
		and baseline.get_child_count()==cut.get_child_count() and baseline.get_child_count()==2,
		"terrain top ownership: native slab vertices, one shape and one mesh remain unchanged")
	check.call(terrain.height_at(-20,-55)==terrain.height_at(0,-55),
		"terrain top ownership: display exclusions preserve native terrain support queries inside street-owned bands")
	terrain.add_patch(root,"LowerCourt",Rect2(-90,-80,30,30),Vector4(1,1,1,1),material)
	terrain.add_polygon(root,"NativeReturn",PackedVector3Array([
		Vector3(-82,4,-74),Vector3(-74,4,-74),Vector3(-74,1,-66),Vector3(-82,1,-66)]),material)
	for i in 2:
		await tree.physics_frame
		await tree.process_frame
	var edges_agree := true
	for point: Vector3 in [Vector3(-75,4,-74),Vector3(-75,3.625,-73),Vector3(-75,1,-66)]:
		var at := root.to_global(point)
		var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.1,at-Vector3.UP*0.1,1)
		var hit := root.get_world_3d().direct_space_state.intersect_ray(query)
		edges_agree = edges_agree and not hit.is_empty() and absf(hit.get("position",Vector3.INF).y-at.y)<0.00025 \
			and absf(terrain.height_at(point.x,point.z)-point.y)<0.00001
	check.call(edges_agree,"terrain support: polygon outer edges and shared diagonal match actual higher native contacts above a lower floor")
	root.queue_free()
	await tree.process_frame


static func _faces(body: StaticBody3D) -> PackedVector3Array:
	return body.get_child(1).mesh.get_faces()


static func _top(faces: PackedVector3Array,index: int) -> bool:
	return (faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).y< -0.000001


static func _top_area(faces: PackedVector3Array) -> float:
	var area := 0.0
	for i in range(0,faces.size(),3):
		if _top(faces,i):area -= (faces[i+1]-faces[i]).cross(faces[i+2]-faces[i]).y*0.5
	return area


static func _retaining(faces: PackedVector3Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	for i in range(0,faces.size(),3):
		if not _top(faces,i):result.append_array(PackedVector3Array([faces[i],faces[i+1],faces[i+2]]))
	return result


static func _top_at(body: StaticBody3D,faces: PackedVector3Array,point: Vector2) -> bool:
	for i in range(0,faces.size(),3):
		if not _top(faces,i):continue
		var points := PackedVector2Array()
		for offset: int in 3:
			var at := body.to_global(faces[i+offset])
			points.append(Vector2(at.x,at.z))
		if Geometry2D.point_is_inside_triangle(point,points[0],points[1],points[2]):return true
	return false
