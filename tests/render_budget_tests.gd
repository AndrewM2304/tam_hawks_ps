extends RefCounted

const Budget = preload("res://game/levels/render_budget.gd")


static func run(check: Callable) -> void:
	var world := Node3D.new()
	world.transform = Transform3D(Basis(Vector3.UP, 0.4), Vector3(12, 3, -9))
	var material := StandardMaterial3D.new()
	var first := _box(world, Vector3(1, 2, 3), material)
	var second := _box(world, Vector3(1, 2, 3), material)
	second.transform = Transform3D(Basis(Vector3.UP, 0.3), Vector3(7, 5, 4))
	var original_transform := second.transform
	var different_size := _box(world, Vector3(1, 2, 4), material)
	var different_uv := _box(world, Vector3(1, 2, 3), material)
	different_uv.mesh.flip_faces = true
	var different_surface := _box(world, Vector3(1, 2, 3), material)
	different_surface.mesh.material = StandardMaterial3D.new()
	var local_mesh := _box(world, Vector3(1, 2, 3), material)
	local_mesh.mesh.resource_local_to_scene = true
	var local_before := local_mesh.mesh
	var untouched := MeshInstance3D.new()
	untouched.mesh = ArrayMesh.new()
	var array_before := untouched.mesh
	world.add_child(untouched)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	body.add_child(shape)
	world.add_child(body)
	var collision_before := shape.shape

	# Headless's dummy RenderingServer does not retain MultiMesh transforms or
	# colours. Test authored partition records directly; graphical probes own
	# actual MultiMesh readback and visual/shadow comparison.
	var records := _tree_records()
	var expected: Dictionary = {}
	for record: Dictionary in records:
		expected[record.transform.origin] = record
	var cells: Dictionary = Budget._partition_records(records)
	var default_tree := _trees(world, material)
	var default_batch := default_tree.multimesh
	var report: Dictionary = Budget.apply_static_decor(world)
	check.call(first.mesh == second.mesh and report.primitive_assignments_shared == 1,
		"render budget: exact primitive duplicates share one mesh resource")
	check.call(second.transform == original_transform and second.material_override == material,
		"render budget: mesh sharing retains transforms and instance material")
	check.call(first.mesh != different_size.mesh and first.mesh != different_uv.mesh
		and first.mesh != different_surface.mesh and local_mesh.mesh == local_before,
		"render budget: different geometry, UV/winding, surface material and local meshes remain distinct")
	check.call(untouched.mesh == array_before and shape.shape == collision_before
		and body.get_parent() == world and body.get_child_count() == 1,
		"render budget: imported/vertex meshes and physics resources are unchanged")
	check.call(not report.tree_partition_enabled and report.tree_batches_split == 0
		and is_instance_valid(default_tree) and default_tree.multimesh == default_batch,
		"render budget: production default retains the original tree batches")
	check.call(cells.size() == 3 and cells[Vector2i(-2, 0)].size() == 2
		and cells[Vector2i(0, 0)].size() == 1 and cells[Vector2i(1, 0)].size() == 1,
		"render budget: authored tree records form bounded cells on both sides of zero")
	var seen: Dictionary = {}
	var state_preserved := true
	for cell_records: Array in cells.values():
		for record: Dictionary in cell_records:
			var at: Vector3 = record.transform.origin
			if not expected.has(at):
				state_preserved = false
				continue
			state_preserved = state_preserved and record == expected[at] and not seen.has(at)
			seen[at] = true
	check.call(state_preserved and seen.size() == expected.size(),
		"render budget: partition preserves every authored transform, colour and custom channel exactly once")
	var second_report: Dictionary = Budget.apply_static_decor(world)
	check.call(second_report.tree_batches_split == 0 and second_report.primitive_assignments_shared == 0,
		"render budget: startup preparation is idempotent")
	default_tree.free()

	var unsupported := _trees(world, material)
	unsupported.multimesh.visible_instance_count = 2
	var unsupported_before := unsupported.multimesh
	Budget.apply_static_decor(world)
	check.call(is_instance_valid(unsupported) and unsupported.multimesh == unsupported_before
		and unsupported.multimesh.visible_instance_count == 2,
		"render budget: a partial/dynamic tree batch is left for explicit author review")
	world.free()
	check.call(Budget._partition_records([]).is_empty(),
		"render budget: empty authored placement input creates no chunks")


static func _box(parent: Node3D, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance


static func _trees(parent: Node3D, material: Material) -> MultiMeshInstance3D:
	var instance := MultiMeshInstance3D.new()
	instance.name = "ParkTreeCanopies"
	instance.transform = Transform3D(Basis(Vector3.UP, -0.2), Vector3(-10, 6, 8))
	instance.material_override = material
	instance.layers = 5
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	instance.visibility_range_end = 180.0
	instance.extra_cull_margin = 2.0
	instance.visible = false
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.use_custom_data = true
	batch.mesh = SphereMesh.new()
	batch.instance_count = 4
	var records := _tree_records()
	for index: int in range(records.size()):
		batch.set_instance_transform(index, records[index].transform)
		batch.set_instance_color(index, records[index].colour)
		batch.set_instance_custom_data(index, records[index].custom)
	instance.multimesh = batch
	parent.add_child(instance)
	return instance


static func _tree_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var positions := [Vector3(-100, 4, 0), Vector3(-99, 5, 2), Vector3(5, 6, 4), Vector3(100, 8, 4)]
	for index: int in range(positions.size()):
		records.append({"transform": Transform3D(Basis(Vector3.UP, index * 0.2).scaled(Vector3.ONE * (index + 1)), positions[index]),
			"colour": Color(0.5 + index * 0.1, 0.8, 0.9, 1.0),
			"custom": Color(index * 0.25, 0.5, 0.75, 1.0)})
	return records
