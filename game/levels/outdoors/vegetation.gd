extends RefCounted
## Original batched deciduous planting. No downloaded foliage or runtime CPU animation.

const Foliage = preload("res://game/levels/art/foliage_mesh.gd")

static func build(parent: Node3D, placements: Array[Dictionary], bark_material: Material) -> void:
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.12
	cylinder.bottom_radius = 0.25
	cylinder.height = 1.0
	cylinder.radial_segments = 10
	_branch(bark, cylinder, Vector3.ZERO, Vector3(0.1, 5.7, 0.1), 1.0)
	for branch in [[Vector3(0, 3.5, 0), Vector3(-2.0, 6.7, 0.8)], [Vector3(0, 4.2, 0), Vector3(1.8, 7.4, 0.4)], [Vector3(0, 4.9, 0), Vector3(-0.6, 8.2, -1.4)]]:
		_branch(bark, cylinder, branch[0], branch[1], 0.58)
	var crown := SurfaceTool.new()
	crown.begin(Mesh.PRIMITIVE_TRIANGLES)
	crown.append_from(Foliage.canopy_mesh(), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(3.4, 3.3, 3.2)), Vector3(0, 7.3, 0)))
	_batch(parent, "ParkTreeTrunks", bark.commit(), bark_material, placements, false)
	_batch(parent, "ParkTreeCanopies", crown.commit(), Foliage.canopy_material(), placements, true)


static func _branch(surface: SurfaceTool, mesh: Mesh, a: Vector3, b: Vector3, radius_scale: float) -> void:
	var up := (b - a).normalized()
	var reference := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var right := up.cross(reference).normalized()
	var basis := Basis(right * radius_scale, up * a.distance_to(b), right.cross(up) * radius_scale)
	surface.append_from(mesh, 0, Transform3D(basis, (a + b) * 0.5))


static func _batch(parent: Node3D, id: String, mesh: Mesh, material: Material, placements: Array[Dictionary], varied: bool) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = mesh
	batch.instance_count = placements.size()
	var authored_transforms: Array[Transform3D] = []
	for i in placements.size():
		var placement: Dictionary = placements[i]
		var size: float = placement.get("scale", 1.0)
		var frame := Transform3D(Basis(Vector3.UP, float(placement.get("yaw", 0.0))).scaled(Vector3(size, size, size)), placement.position)
		authored_transforms.append(frame)
		batch.set_instance_transform(i, frame)
		batch.set_instance_color(i, Color(0.85 + fmod(i * 0.137, 0.2), 0.9 + fmod(i * 0.17, 0.1), 0.85 + fmod(i * 0.11, 0.15)) if varied else Color.WHITE)
	var instance := MultiMeshInstance3D.new()
	instance.name = id
	instance.multimesh = batch
	instance.material_override = material
	instance.set_meta("authored_tree_transforms",authored_transforms)
	parent.add_child(instance)
