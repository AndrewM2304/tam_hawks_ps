extends RefCounted
## One display owner for the Clyde's flush stone coping and paved quays.
## Native terrain, recovery, route queries and embankment solids stay intact.
const Surface = preload("res://game/levels/outdoors/surface_builder.gd")
const NORTH_PAVING := Rect2(-85, 55, 170, 22.2)
const NORTH_COPING := Rect2(-85, 77.2, 170, 0.8)
const SOUTH_COPING := Rect2(-39, 116, 115, 0.8)


static func install(world: Node3D) -> Dictionary:
	# Read-only matched diagnostics construct the previous display ownership.
	# This is an internal fixture flag, never a profile or player setting.
	if bool(world.get_meta("pt24_render_repairs_baseline",false)):
		return {}
	if world.has_meta("pt24_render_repairs"):
		return world.get_meta("pt24_render_repairs")
	var north := world.get_node("OutdoorRoutes/ClydeNorthQuay") as StaticBody3D
	var south := world.get_node("OutdoorRoutes/ClydeSouthQuay") as StaticBody3D
	var north_visual := _display(north)
	var south_visual := _display(south)
	var before := north_visual.mesh.get_faces().size() / 3 + south_visual.mesh.get_faces().size() / 3
	# This source is a complete flat rectangle. Its native five-metre grid
	# remains unchanged, but a dense display grid is unnecessary for a plane.
	# Refuse unexpected later holes rather than filling an authored opening.
	var original := north_visual.mesh.get_faces()
	var source_area := 0.0
	for index: int in range(0, original.size(), 3):
		var a := original[index]
		var b := original[index + 1]
		var c := original[index + 2]
		assert(absf(a.y - 2.0) < 0.00001 and absf(b.y - 2.0) < 0.00001 and absf(c.y - 2.0) < 0.00001)
		source_area += absf((b - a).cross(c - a).y) * 0.5
	assert(absf(source_area - 3910.0) < 0.01)
	north_visual.mesh = _flat_rectangle(NORTH_PAVING, 2.0)
	# The south display already contains the bowl/hip cuts. Preserve those
	# independent cuts and remove only the duplicate northern coping strip.
	Surface.trim_visual_rect(south, SOUTH_COPING)
	var plinths := _station_plinths(world)
	var covered_faces := _additional_repairs(world)
	var after := north_visual.mesh.get_faces().size() / 3 + south_visual.mesh.get_faces().size() / 3
	assert(after <= before)
	var report := {"duplicate_top_area_m2": 228.0, "north_display_triangles": 2,
		"before_triangles": before, "after_triangles": after,
		"new_bodies": 0, "new_shapes": 0, "new_surfaces": 0,
		"new_materials": 0, "new_textures": 0,
		"station_plinth_instances": plinths,
		"covered_faces":covered_faces,
		"method": "Existing Y2 stone coping owns its footprint; display-only paving trim, original native support retained."}
	world.set_meta("pt24_render_repairs", report)
	return report


static func _additional_repairs(world: Node3D) -> Dictionary:
	var result := {"civic":{},"exchange":{},"park_removed_triangles":0,"park_removed_area_m2":0.0,
		"before_triangles":0,"after_triangles":0}
	var civic := world.get_node_or_null("GeorgeSquareFloor") as StaticBody3D
	if civic != null:
		# The repaired civic paving reaches X36; the existing east asphalt
		# cross street already begins at X35, leaving a12m² duplicate top.
		result.civic = _clip_display_plane(world,civic,1,4.0,Vector2i(0,2),Rect2(35,-86,1,12))
		result.before_triangles += result.civic.before_triangles
		result.after_triangles += result.civic.after_triangles
	var exchange := world.get_node_or_null("CentralSouthStreet") as StaticBody3D
	if exchange != null:
		# The closed tenement at(-41,0,0) owns this Z15 wall. Remove only the
		# road's internal9.6m² wedge; its below-Y0 foundation remains visible.
		result.exchange = _clip_display_plane(world,exchange,2,15.0,Vector2i(0,1),Rect2(-47,0,12,16))
		result.before_triangles += result.exchange.before_triangles
		result.after_triangles += result.exchange.after_triangles
	var park := world.get_node_or_null("OutdoorRoutes/KelvingroveSunkenSkatepark") as Node3D
	if park != null:
		for body: Node in park.get_children():
			if not body is StaticBody3D:continue
			var native: BoxShape3D
			for child: Node in body.get_children():
				if child is CollisionShape3D and child.shape is BoxShape3D:native = child.shape
			if native == null:continue
			var planes: Array[Vector2] = []
			if absf(body.position.z-3.425)<0.0001 and absf(body.position.y+0.75)<0.0001 \
				and absf(native.size.y-1.5)<0.0001 and absf(native.size.z-0.15)<0.0001:
				# Upper paving covers the full top of each closed north span.
				planes = [Vector2(1,0.75)]
			elif absf(body.position.x-17.55)<0.0001 and absf(body.position.y+0.75)<0.0001 \
				and absf(native.size.x-0.1)<0.0001 and absf(native.size.y-1.5)<0.0001:
				# EastArrivalDeck supplies both its complete western wall and top.
				planes = [Vector2(1,0.75),Vector2(0,-0.05)]
			if planes.is_empty():continue
			var removed := _remove_box_planes(body,planes)
			result.before_triangles += removed.before_triangles
			result.after_triangles += removed.after_triangles
			result.park_removed_triangles += removed.before_triangles-removed.after_triangles
			result.park_removed_area_m2 += removed.removed_area_m2
	# Paving triangulation is offset by deleted covered box faces. Never add
	# a new resident surface, material, native shape or per-frame operation.
	assert(result.after_triangles <= result.before_triangles)
	return result


static func _clip_display_plane(reference: Node3D,body: StaticBody3D,axis: int,plane: float,
		project: Vector2i,cut: Rect2) -> Dictionary:
	var display := _first_display(body)
	var original := display.mesh.get_faces()
	var output := PackedVector3Array()
	var removed_area := 0.0
	var clip := PackedVector2Array([cut.position,Vector2(cut.end.x,cut.position.y),cut.end,Vector2(cut.position.x,cut.end.y)])
	for index: int in range(0,original.size(),3):
		var local := PackedVector3Array([original[index],original[index+1],original[index+2]])
		var level := PackedVector3Array()
		var selected := true
		var polygon := PackedVector2Array()
		for point: Vector3 in local:
			var at := reference.to_local(display.to_global(point))
			level.append(at)
			selected = selected and absf(at[axis]-plane)<0.00005
			polygon.append(Vector2(at[project.x],at[project.y]))
		if not selected:
			output.append_array(local)
			continue
		var before_area := (level[1]-level[0]).cross(level[2]-level[0]).length()*0.5
		var kept_area := 0.0
		for piece: PackedVector2Array in Geometry2D.clip_polygons(polygon,clip):
			var indices := Geometry2D.triangulate_polygon(piece)
			for offset: int in range(0,indices.size(),3):
				var triangle := PackedVector3Array()
				var relative := PackedVector3Array()
				for corner: int in 3:
					var uv := piece[indices[offset+corner]]
					var point := Vector3.ZERO
					point[axis] = plane
					point[project.x] = uv.x
					point[project.y] = uv.y
					relative.append(point)
					triangle.append(display.to_local(reference.to_global(point)))
				kept_area += (relative[1]-relative[0]).cross(relative[2]-relative[0]).length()*0.5
				if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).dot((local[1]-local[0]).cross(local[2]-local[0]))<0:
					var swap := triangle[1];triangle[1]=triangle[2];triangle[2]=swap
				output.append_array(triangle)
		removed_area += before_area-kept_area
	display.mesh = _hard_faces(output)
	return {"before_triangles":original.size()/3,"after_triangles":output.size()/3,"removed_area_m2":removed_area}


static func _remove_box_planes(body: StaticBody3D,planes: Array[Vector2]) -> Dictionary:
	var display := _first_display(body)
	var original := display.mesh.get_faces()
	var kept := PackedVector3Array()
	var area := 0.0
	for index: int in range(0,original.size(),3):
		var a := original[index]
		var b := original[index+1]
		var c := original[index+2]
		var remove := false
		for plane: Vector2 in planes:
			var axis := int(plane.x)
			if absf(a[axis]-plane.y)<0.00005 and absf(b[axis]-plane.y)<0.00005 and absf(c[axis]-plane.y)<0.00005:remove=true
		if remove:area += (b-a).cross(c-a).length()*0.5
		else:kept.append_array(PackedVector3Array([a,b,c]))
	display.mesh = _hard_faces(kept)
	return {"before_triangles":original.size()/3,"after_triangles":kept.size()/3,"removed_area_m2":area}


static func _first_display(body: Node3D) -> MeshInstance3D:
	for child: Node in body.get_children():
		if child is MeshInstance3D:return child
	assert(false,"Required display missing: "+str(body.name))
	return null


static func _hard_faces(faces: PackedVector3Array) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)
	for point: Vector3 in faces:tool.add_vertex(point)
	tool.generate_normals()
	return tool.commit()


static func _station_plinths(world: Node3D) -> int:
	var repaired := 0
	for body: Node in world.find_children("*","StaticBody3D",true,false):
		if body.get_meta("boundary_family","") != "StationNorthBoundary":continue
		var display := body.get_node_or_null("RetainedMasonry") as MultiMeshInstance3D
		if display == null:continue
		var points: PackedVector3Array = body.get_meta("boundary_points",PackedVector3Array())
		var transforms: Array[Transform3D] = []
		for index: int in range(points.size()-1):
			var a := points[index]
			var b := points[index+1]
			var run := Vector2(b.x-a.x,b.z-a.z).length()
			if run < 0.01:continue
			var divisions := maxi(1,ceili(run/1.5))
			for step: int in divisions:
				var start := a.lerp(b,float(step)/divisions) + Vector3.UP*0.15
				var finish := a.lerp(b,float(step+1)/divisions) + Vector3.UP*0.15
				var delta := finish-start
				var basis := Basis(Quaternion(Vector3.FORWARD,delta.normalized()))
				# The old +4cm overlength made adjacent flat top/side skins
				# coplanar over a positive area. Exact adjoining endpoints retain
				# the complete original plinth without doubled faces or gaps.
				transforms.append(Transform3D(basis*Basis.from_scale(Vector3(0.5,0.5,delta.length())),(start+finish)*0.5))
		assert(transforms.size() == display.multimesh.instance_count)
		for index: int in transforms.size():
			display.multimesh.set_instance_transform(index,transforms[index])
		# Keep construction transforms available to the headless dummy renderer,
		# which cannot reliably read MultiMesh GPU state back for verification.
		display.set_meta("pt24_plinth_transforms",transforms)
		repaired += transforms.size()
	return repaired


static func _display(body: StaticBody3D) -> MeshInstance3D:
	assert(body.transform.is_equal_approx(Transform3D.IDENTITY))
	for child: Node in body.get_children():
		if child is MeshInstance3D:
			return child
	assert(false, "Quay display missing: " + str(body.name))
	return null


static func _flat_rectangle(bounds: Rect2, height: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := PackedVector3Array([
		Vector3(bounds.position.x, height, bounds.position.y),
		Vector3(bounds.end.x, height, bounds.position.y),
		Vector3(bounds.position.x, height, bounds.end.y),
		Vector3(bounds.end.x, height, bounds.end.y)])
	for index: int in [0, 1, 2, 1, 3, 2]:
		var point := corners[index]
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(point.x, point.z) * 0.2)
		tool.add_vertex(point)
	tool.index()
	tool.generate_tangents()
	return tool.commit()
