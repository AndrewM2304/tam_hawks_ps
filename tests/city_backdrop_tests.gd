extends RefCounted
## Inspect actual scenery geometry/resources. Metadata budgets are not evidence.

const World = preload("res://game/levels/glasgow_square.gd")
const Backdrop = preload("res://game/levels/city_backdrop.gd")
const PORTS := {
	"river channel": Rect2(-450,78,900,38),
	"station quay access": Rect2(-102,40,16,31),
	"market quay access": Rect2(86,40,16,31),
	"station park access": Rect2(-151,-8,23,16),
	"civic park access": Rect2(-48,-128,18,12),
}


static func run(tree: SceneTree, check: Callable) -> void:
	# Failed timing gates keep all candidate scenery out of normal startup.
	# Assert that policy before constructing an explicit diagnostic preview.
	var ordinary := World.new()
	ordinary.set_meta(&"render_budget_probe_baseline", true)
	tree.root.add_child(ordinary)
	await tree.process_frame
	var ordinary_has_candidate := ordinary.get_node_or_null("CityBackdrop") != null
	for id: String in ["ClydeWestContext", "ClydeEastContext", "ExistingBoundaryRetainingSkirts", "StationServiceBacks", "ParkWestHillside", "ParkNorthHillside"]:
		ordinary_has_candidate = ordinary_has_candidate or not ordinary.find_children(id, "MeshInstance3D", true, false).is_empty()
	check.call(not ordinary_has_candidate,
		"City backdrop: ordinary startup constructs no rejected candidate geometry")
	ordinary.free()
	var world := World.new()
	world.set_meta(&"render_budget_probe_baseline", true)
	world.set_meta(&"render_repair_backdrop_preview", true)
	tree.root.add_child(world)
	await tree.process_frame
	var backdrop := world.get_node_or_null("CityBackdrop") as Node3D
	check.call(backdrop != null, "City backdrop: explicit preview world installs the actual candidate scenery")
	if backdrop == null:
		world.free()
		return
	var meshes := backdrop.find_children("*", "MeshInstance3D", true, false)
	var triangles := 0
	var surfaces := 0
	var materials: Dictionary = {}
	var all_faces := PackedVector3Array()
	var valid_meshes := not meshes.is_empty()
	var no_casting := true
	for node: MeshInstance3D in meshes:
		valid_meshes = valid_meshes and node.mesh is ArrayMesh and node.get_script() == null
		no_casting = no_casting and node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and node.gi_mode == GeometryInstance3D.GI_MODE_DISABLED
		surfaces += node.mesh.get_surface_count()
		var faces := node.mesh.get_faces()
		triangles += faces.size() / 3
		for at: Vector3 in faces: all_faces.append(node.global_transform * at)
		for surface: int in range(node.mesh.get_surface_count()):
			var material := node.get_active_material(surface)
			if material == null:
				valid_meshes = false
			else:
				materials[material.get_instance_id()] = material
	check.call(valid_meshes and meshes.size() <= 8 and surfaces <= 8 and triangles <= 6000 and triangles > 0,
		"City backdrop: actual visible arrays fit eight mesh/surface submissions and 6000 triangles")
	var names: Array[String] = []
	for child: Node in backdrop.get_children(): names.append(str(child.name))
	names.sort()
	check.call(names == ["ClydeEastContext", "ClydeWestContext"] and meshes.size() == 2 and surfaces == 2 and triangles == 2132,
		"City backdrop: explicit preview contains only the two Clyde chunks, exactly 2132 real triangles and two surfaces")
	check.call(no_casting, "City backdrop: every actual scenery mesh avoids additional shadow/GI submissions")
	var quiet_nodes := backdrop.get_script() == null and not backdrop.is_processing() and not backdrop.is_physics_processing()
	for node: Node in backdrop.find_children("*", "Node", true, false):
		quiet_nodes = quiet_nodes and node is MeshInstance3D and node.get_script() == null and not node.is_processing() and not node.is_physics_processing()
	check.call(quiet_nodes and backdrop.find_children("*", "CollisionObject3D", true, false).is_empty()
		and backdrop.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"City backdrop: actual node tree contains only static visuals, no physics/light/camera/processing actors")
	var valid_materials := materials.size() == 1
	for resource: Material in materials.values():
		var material := resource as StandardMaterial3D
		valid_materials = valid_materials and material != null
		if material == null: continue
		valid_materials = valid_materials and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and material.cull_mode == BaseMaterial3D.CULL_BACK
		valid_materials = valid_materials and _textures(material).is_empty() and material.next_pass == null and material.vertex_color_use_as_albedo
		valid_materials = valid_materials and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and material.specular_mode == BaseMaterial3D.SPECULAR_DISABLED and material.disable_receive_shadows
	check.call(valid_materials,
		"City backdrop: exactly one shared opaque unshaded vertex-colour material, no textures/extra passes/specular or received shadows")
	var finite_faces := all_faces.size() % 3 == 0
	for offset: int in range(0, all_faces.size(), 3):
		var a := all_faces[offset]
		var b := all_faces[offset+1]
		var c := all_faces[offset+2]
		finite_faces = finite_faces and a.is_finite() and b.is_finite() and c.is_finite() and (b-a).cross(c-a).length() > 0.000001
	check.call(finite_faces, "City backdrop: actual visible triangles remain finite and nondegenerate")
	for id: String in PORTS:
		var clear := true
		for offset: int in range(0, all_faces.size(), 3):
			var triangle := PackedVector2Array()
			for corner: int in range(3):
				var at := all_faces[offset+corner]
				triangle.append(Vector2(at.x,at.z))
			if _enters_rectangle(triangle, PORTS[id]): clear = false
		check.call(clear, "City backdrop: actual triangles/vertical segments leave protected geometry open: " + id)
	var count_before := backdrop.get_child_count()
	var same := Backdrop.build(world,world._materials)
	check.call(same == backdrop and backdrop.get_child_count() == count_before,
		"City backdrop: repeated build retains the same single geometry tree")
	check.call(world.find_children("*", "StaticBody3D", true, false).size() == 351
		and world.find_children("*", "CollisionShape3D", true, false).size() == 1863
		and world.get_route_definitions().size() == 48,
		"City backdrop: original physical-body/shape and authored-route inventories remain unchanged")
	# The explicit preview above must succeed independently. Only now replace
	# its art node for a declared diagnostic fixture of the explicit held option.
	backdrop.free()
	var held := Backdrop.build(world, world._materials, true)
	var held_names: Array[String] = []
	var held_triangles := 0
	var held_surfaces := 0
	var held_ports_clear := true
	for child: Node in held.get_children(): held_names.append(str(child.name))
	held_names.sort()
	for node: MeshInstance3D in held.find_children("*", "MeshInstance3D", true, false):
		held_surfaces += node.mesh.get_surface_count()
		var faces := node.mesh.get_faces()
		held_triangles += faces.size() / 3
		for offset: int in range(0, faces.size(), 3):
			var triangle := PackedVector2Array()
			for corner: int in range(3):
				var at: Vector3 = node.global_transform * faces[offset+corner]
				triangle.append(Vector2(at.x, at.z))
			for id: String in PORTS:
				if _enters_rectangle(triangle, PORTS[id]): held_ports_clear = false
	check.call(held_names == ["ClydeEastContext", "ClydeWestContext", "ExistingBoundaryRetainingSkirts", "ParkNorthHillside", "ParkWestHillside", "StationServiceBacks"]
		and held_surfaces == 6 and held_triangles == 4036 and held_ports_clear,
		"City backdrop: explicit fresh held-context fixture preserves six surfaces/4036 actual triangles and every protected opening")
	world.free()
	await tree.process_frame


static func _textures(material: Material) -> Dictionary:
	var result: Dictionary = {}
	for property: Dictionary in material.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var value: Variant = material.get(property.name)
		if value is Texture2D: result[value.get_instance_id()] = value
	return result


static func _enters_rectangle(triangle: PackedVector2Array, bounds: Rect2) -> bool:
	# Interior-only testing permits exactly meeting a port/channel edge. Segment
	# checks are essential: a vertical wall projects to zero XZ triangle area.
	var interior := bounds.grow(-0.001)
	for at: Vector2 in triangle:
		if interior.has_point(at): return true
	var corners := PackedVector2Array([interior.position,Vector2(interior.end.x,interior.position.y),interior.end,Vector2(interior.position.x,interior.end.y)])
	for edge: int in range(3):
		for side: int in range(4):
			if Geometry2D.segment_intersects_segment(triangle[edge],triangle[(edge+1)%3],corners[side],corners[(side+1)%4]) != null: return true
	if absf((triangle[1]-triangle[0]).cross(triangle[2]-triangle[0])) > 0.000001:
		return Geometry2D.is_point_in_polygon(interior.get_center(),triangle)
	return false
