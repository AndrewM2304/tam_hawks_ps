extends RefCounted
## Independent author-record/state checks; does not claim dummy GPU readback.

const Batches = preload("res://game/levels/static_batches.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	var world := Node3D.new()
	world.name = "StaticBatchFixture"
	tree.root.add_child(world)
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var material := StandardMaterial3D.new()
	var left := Node3D.new()
	left.position.x = 100
	world.add_child(left)
	var right := Node3D.new()
	right.position.x = -90
	world.add_child(right)
	var authored: Array = [Transform3D(Basis(Vector3.UP, 0.3) * Basis.from_scale(Vector3(2, 0.7, 1)),
		Vector3(-99, 1, 2)), Transform3D(Basis.IDENTITY, Vector3(-98, 2, 3))]
	var a := _source(left, mesh, material, authored, true)
	var b := _source(right, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(92, 1, 2)),
		Transform3D(Basis.IDENTITY, Vector3(93, 1, 4))], true)
	for source: MultiMeshInstance3D in [a, b]:
		source.layers = 3
		source.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		source.extra_cull_margin = 1.5
		source.ignore_occlusion_culling = true
	var saved: Array = Batches.authored_transforms(a)
	authored[0] = Transform3D(Basis.IDENTITY, Vector3(999, 999, 999))
	saved[0] = Transform3D.IDENTITY
	check.call(Batches.authored_transforms(a)[0].origin == Vector3(-99, 1, 2),
		"static batches: registration and public reads copy authored transforms")
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	body.add_child(collider)
	world.add_child(body)
	var unregistered := _source(world, mesh, material,
		[Transform3D(Basis.IDENTITY, Vector3(3, 1, 2))], false, false)
	var before: Array[Dictionary] = Batches.snapshot(world)
	check.call(before.size() == 4, "static batches: snapshot excludes unregistered art/gameplay")
	var report: Dictionary = Batches.finalize(world, 64)
	check.call(report.valid_configuration and report.eligible_sources == 2
		and report.families_merged == 1 and report.sources_removed == 2
		and report.batches_created == 1 and report.instances_preserved == 4
		and report.validation_failures == 0,
		"static batches: actual instance positions merge two distant-parent sources into one cell")
	var after: Array[Dictionary] = Batches.snapshot(world)
	check.call(_same_records(before, after),
		"static batches: every world transform/color/custom channel/mesh/render setting survives once")
	check.call(is_instance_valid(body) and body.get_child(0) == collider
		and is_instance_valid(unregistered) and world.get_child_count() == 5,
		"static batches: collision, author parents and unregistered visuals remain intact")
	var second: Dictionary = Batches.finalize(world, 64)
	check.call(second.sources_removed == 0 and second.batches_created == 0
		and _same_records(after, Batches.snapshot(world)),
		"static batches: finalized output is idempotent")
	world.free()

	world = _world(tree)
	var rotated := Node3D.new()
	rotated.transform = Transform3D(Basis(Vector3.UP, 0.67) * Basis.from_scale(Vector3(0.7, 1, 1)), Vector3(4, 2, 4))
	world.add_child(rotated)
	_source(rotated, mesh, material, [Transform3D(Basis(Vector3.UP, -0.2), Vector3(2, 3, 2))])
	_source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(6, 2, 4))])
	before = Batches.snapshot(world)
	report = Batches.finalize(world, 32)
	check.call(report.sources_removed == 2 and _same_records(before, Batches.snapshot(world)),
		"static batches: rotated/nonuniform author parents preserve final world geometry")
	world.free()
	world = _world(tree)
	world.transform = Transform3D(Basis(Vector3.UP, 0.27) * Basis.from_scale(Vector3(0.8, 1, 1.1)), Vector3(100, 4, -100))
	_source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(1, 0, 1))])
	_source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(2, 0, 1))])
	before = Batches.snapshot(world)
	report = Batches.finalize(world, 64)
	check.call(report.sources_removed == 2 and _same_records(before, Batches.snapshot(world)),
		"static batches: transformed world root retains world-space geometry and visibility state")
	world.free()

	world = _world(tree)
	_source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(1, 0, 1)),
		Transform3D(Basis.IDENTITY, Vector3(70, 0, 1))])
	_source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(2, 0, 1)),
		Transform3D(Basis.IDENTITY, Vector3(71, 0, 1))])
	before = Batches.snapshot(world)
	report = Batches.finalize(world, 64)
	check.call(report.sources_removed == 0 and report.families_without_saving == 1
		and _same_records(before, Batches.snapshot(world)),
		"static batches: partition without a strict batch-node saving remains untouched")
	world.free()

	for exclusion: String in ["material", "mesh", "shadow", "layers", "alpha", "shader",
		"hidden", "range", "partial", "bounds", "child", "moving_parent", "scripted_parent"]:
		world = _world(tree)
		a = _source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(1, 0, 1))])
		b = _source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(2, 0, 1))])
		match exclusion:
			"material": b.material_override = material.duplicate()
			"mesh": b.multimesh.mesh = BoxMesh.new()
			"shadow": b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			"layers": b.layers = 2
			"alpha":
				var alpha := StandardMaterial3D.new()
				alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				b.material_override = alpha
			"shader": b.material_override = ShaderMaterial.new()
			"hidden": b.visible = false
			"range": b.visibility_range_end = 55.0
			"partial": b.multimesh.visible_instance_count = 0
			"bounds": b.multimesh.custom_aabb = AABB(Vector3.ZERO, Vector3.ONE)
			"child": b.add_child(Node3D.new())
			"moving_parent":
				var mover := CharacterBody3D.new()
				world.add_child(mover)
				b.reparent(mover)
			"scripted_parent":
				var scripted := Node3D.new()
				var script := GDScript.new()
				script.source_code = "extends Node3D\n"
				script.reload()
				scripted.set_script(script)
				world.add_child(scripted)
				b.reparent(scripted)
		report = Batches.finalize(world)
		check.call(report.sources_removed == 0 and is_instance_valid(a) and is_instance_valid(b),
			"static batches: incompatible or dynamic source stays unchanged: " + exclusion)
		world.free()

	world = _world(tree)
	a = _source(world, mesh, material, [Transform3D.IDENTITY])
	check.call(not Batches.register(a, []) and not Batches.register(a,
		[Transform3D(Basis.IDENTITY, Vector3(NAN, 0, 0))])
		and not Batches.register(a, [Transform3D(Basis.from_scale(Vector3(-1, 1, 1)), Vector3.ZERO)]),
		"static batches: missing/nonfinite/mirrored authored data is rejected safely")
	check.call(not Batches.finalize(world, NAN).valid_configuration
		and not Batches.finalize(world, 0).valid_configuration
		and not Batches.finalize(world, 512).valid_configuration,
		"static batches: nonfinite/out-of-bounds cell configuration is refused")
	world.free()
	world = _world(tree)
	_source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(1e20, 0, 1))])
	_source(world, mesh, material, [Transform3D(Basis.IDENTITY, Vector3(1e20, 0, 1))])
	report = Batches.finalize(world, 64)
	check.call(report.excluded_sources == 2 and report.sources_removed == 0,
		"static batches: finite transforms outside integer cell coordinates are rejected")
	world.free()


static func _world(tree: SceneTree) -> Node3D:
	var world := Node3D.new()
	tree.root.add_child(world)
	return world


static func _source(parent: Node3D, mesh: Mesh, material: Material, transforms: Array,
		channels: bool = false, registered: bool = true) -> MultiMeshInstance3D:
	var source := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.use_colors = channels
	batch.use_custom_data = channels
	batch.instance_count = transforms.size()
	var colors: Array = []
	var custom: Array = []
	for index: int in range(transforms.size()):
		batch.set_instance_transform(index, transforms[index])
		if channels:
			var color := Color(0.2 + index * 0.1, 0.4, 0.6, 0.8)
			var data := Color(0.1, 0.2 + index * 0.1, 0.3, 0.4)
			batch.set_instance_color(index, color)
			batch.set_instance_custom_data(index, data)
			colors.append(color)
			custom.append(data)
	source.multimesh = batch
	source.material_override = material
	parent.add_child(source)
	if registered:
		Batches.register(source, transforms, colors, custom)
	return source


static func _same_records(before: Array[Dictionary], after: Array[Dictionary]) -> bool:
	if before.size() != after.size():
		return false
	var remaining: Array[Dictionary] = after.duplicate()
	for original: Dictionary in before:
		var found := -1
		for index: int in range(remaining.size()):
			var candidate: Dictionary = remaining[index]
			if original.mesh == candidate.mesh and original.render_state == candidate.render_state \
				and original.use_colors == candidate.use_colors and original.use_custom_data == candidate.use_custom_data \
				and original.color == candidate.color and original.custom_data == candidate.custom_data \
				and Batches._same_transform(original.transform, candidate.transform):
				found = index
				break
		if found < 0:
			return false
		remaining.remove_at(found)
	return remaining.is_empty()
