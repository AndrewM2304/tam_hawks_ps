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
	var after := north_visual.mesh.get_faces().size() / 3 + south_visual.mesh.get_faces().size() / 3
	assert(after <= before)
	var report := {"duplicate_top_area_m2": 228.0, "north_display_triangles": 2,
		"before_triangles": before, "after_triangles": after,
		"new_bodies": 0, "new_shapes": 0, "new_surfaces": 0,
		"new_materials": 0, "new_textures": 0,
		"station_plinth_instances": plinths,
		"method": "Existing Y2 stone coping owns its footprint; display-only paving trim, original native support retained."}
	world.set_meta("pt24_render_repairs", report)
	return report


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
