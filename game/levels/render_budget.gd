extends RefCounted
## Startup-only visual resource sharing and spatial batches for existing decor.
## No camera, collision, processing, encounter or district lifetime is changed.

const TREE_CELL_METRES := 96.0
const TREE_BATCH_NAMES: Array[StringName] = [&"ParkTreeTrunks", &"ParkTreeCanopies"]


static func apply_static_decor(world: Node3D, split_trees: bool = false) -> Dictionary:
	var report := {"primitive_assignments_shared": 0, "tree_batches_split": 0,
		"tree_chunks_created": 0, "tree_instances_preserved": 0,
		"tree_partition_enabled": split_trees}
	var canonical_meshes: Dictionary = {}
	_share_meshes(world, canonical_meshes, report)
	# Spatial experiments reduced triangles but added draws at the park's normal
	# checkpoint without a triangle saving. Keep them opt-in for diagnostics.
	if split_trees:
		_split_tree_batches(world, report)
	return report


static func _share_meshes(node: Node, canonical: Dictionary, report: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh != null:
		node.mesh = _shared_primitive(node.mesh, canonical, report)
	elif node is MultiMeshInstance3D and node.multimesh != null and node.multimesh.mesh != null:
		node.multimesh.mesh = _shared_primitive(node.multimesh.mesh, canonical, report)
	for child: Node in node.get_children():
		_share_meshes(child, canonical, report)


static func _shared_primitive(mesh: Mesh, canonical: Dictionary, report: Dictionary) -> Mesh:
	# ArrayMesh imports, procedural vertex art, scripted/local resources and their
	# LODs are owned by their author. Only exact built-in primitives are shared.
	if not mesh is PrimitiveMesh or mesh.get_script() != null or mesh.resource_local_to_scene:
		return mesh
	var key: Array = [mesh.get_class()]
	for property: Dictionary in mesh.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_STORAGE:
			key.append(property.name)
			key.append(mesh.get(property.name))
	if canonical.has(key):
		if mesh != canonical[key]:
			report.primitive_assignments_shared += 1
		return canonical[key]
	canonical[key] = mesh
	return mesh


static func _split_tree_batches(node: Node, report: Dictionary) -> void:
	for child: Node in node.get_children():
		if child is MultiMeshInstance3D and child.name in TREE_BATCH_NAMES:
			_split_tree_batch(child, report)
		else:
			_split_tree_batches(child, report)


static func _split_tree_batch(source: MultiMeshInstance3D, report: Dictionary) -> void:
	var original: MultiMesh = source.multimesh
	# This intentionally narrow contract covers only static authored park trees.
	# A changed/animated source must be reviewed rather than silently rewritten.
	if original == null or original.mesh == null or original.instance_count < 2 \
		or original.transform_format != MultiMesh.TRANSFORM_3D \
		or original.visible_instance_count != -1 or original.custom_aabb != AABB() \
		or source.get_script() != null or source.get_child_count() != 0:
		return
	var cells: Dictionary = {}
	var records: Array[Dictionary] = []
	for index: int in range(original.instance_count):
		records.append({"transform": original.get_instance_transform(index),
			"colour": original.get_instance_color(index) if original.use_colors else Color.WHITE,
			"custom": original.get_instance_custom_data(index) if original.use_custom_data else Color.BLACK})
	cells = _partition_records(records)
	if cells.size() < 2:
		return
	for cell: Vector2i in cells:
		var cell_records: Array = cells[cell]
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = original.use_colors
		batch.use_custom_data = original.use_custom_data
		batch.mesh = original.mesh
		batch.instance_count = cell_records.size()
		for index: int in range(cell_records.size()):
			var record: Dictionary = cell_records[index]
			batch.set_instance_transform(index, record.transform)
			if original.use_colors:
				batch.set_instance_color(index, record.colour)
			if original.use_custom_data:
				batch.set_instance_custom_data(index, record.custom)
		# Duplicate the visual properties, not a hand-maintained subset: material
		# overrides, layers, visibility, transforms and shadow settings remain exact.
		var chunk := source.duplicate(0) as MultiMeshInstance3D
		chunk.name = "%s_Cell_%d_%d" % [source.name, cell.x, cell.y]
		chunk.multimesh = batch
		source.get_parent().add_child(chunk)
		report.tree_chunks_created += 1
		report.tree_instances_preserved += cell_records.size()
	report.tree_batches_split += 1
	source.free()


static func _partition_records(records: Array[Dictionary]) -> Dictionary:
	var cells: Dictionary = {}
	for record: Dictionary in records:
		var at: Vector3 = record.transform.origin
		var cell := Vector2i(floori(at.x / TREE_CELL_METRES), floori(at.z / TREE_CELL_METRES))
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(record)
	return cells
