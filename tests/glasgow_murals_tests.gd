extends RefCounted
## Paint has no self-competing depth and still tests against real opaque walls.
const Murals = preload("res://game/levels/glasgow_murals.gd")

static func run(world: Node3D, check: Callable) -> void:
	var before_bodies := world.get_tree().get_nodes_in_group("exploration_boundaries").size()
	var existing := world.get_node_or_null("GlasgowMurals")
	var art := Murals.build(world, {})
	var report: Dictionary = art.get_meta("mural_report")
	check.call(report.triangles > 500 and report.triangles <= 1200 and art.get_child_count() == 2,
		"murals: two original paintings fit the declared geometry budget")
	check.call(Murals.build(world,{}) == art and world.get_tree().get_nodes_in_group("exploration_boundaries").size() == before_bodies,
		"murals: repeated build preserves the same art and physical world")
	var material: Material
	var same_material := true
	for child: MeshInstance3D in art.get_children():
		if material == null: material = child.material_override
		same_material = same_material and material == child.material_override
		var paint: StandardMaterial3D = child.material_override
		check.call(child.mesh.get_surface_count() == 1 and paint.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
			and paint.depth_draw_mode == BaseMaterial3D.DEPTH_DRAW_DISABLED and not paint.no_depth_test,
			"murals: one painter-order surface uses real scenery depth without self depth conflicts")
		check.call(child.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			and child.visibility_range_end == 45.0 and paint.disable_receive_shadows,
			"murals: near-wall detail adds no distant/shadow workload")
		var arrays: Array = child.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var planar := true
		for index: int in vertices.size():
			planar = planar and absf(vertices[index].x) < 0.000001 and is_equal_approx(colours[index].a, 1.0)
		check.call(planar and paint.albedo_texture == null and paint.normal_texture == null,
			"murals: all original brush shapes share one plane/opaque colour with no added textures")
	check.call(same_material and not art.is_processing() and not art.is_physics_processing(),
		"murals: both walls share one startup-only material")
	# Leave ordinary gameplay exactly as it was before this isolated preview.
	if existing == null: art.free()
