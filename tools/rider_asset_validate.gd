extends SceneTree
## Reuses independent native deformed-cloth/contact regressions and records the
## actual rider resource inventory. Headless checks cannot approve visual art.
const Classic = preload("res://tests/classic_tricks_integration_tests.gd")
const BodyAttachment = preload("res://tests/skater_body_attachment_tests.gd")
const LimbPose = preload("res://tests/limb_pose_tests.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await BodyAttachment.run(self, check)
	await LimbPose.run(self, check)
	var fixture := await Classic._fixture(self)
	var inventory := {"triangles": 0, "surfaces": 0, "textures": {}, "meshes": 0}
	_inventory(fixture.rider, inventory)
	check(inventory.triangles <= 65000, "rider inventory: at most 65000 actual source triangles")
	var bytes := 0
	for texture: Texture2D in inventory.textures.values():
		# Conservative uncompressed RGBA mip estimate; actual imported GPU bytes
		# are renderer/platform dependent and must be profiled separately.
		bytes += int(texture.get_width() * texture.get_height() * 4.0 * 4.0 / 3.0)
	check(bytes <= 64 * 1024 * 1024, "rider inventory: conservative unique texture mip estimate at most64MiB")
	print("RIDER_INVENTORY triangles=", inventory.triangles, " surfaces=", inventory.surfaces,
		" meshes=", inventory.meshes, " unique_textures=", inventory.textures.size(), " rgba_mip_bytes_estimate=", bytes)
	await Classic._dispose(self, fixture)
	print("RESULT: ", passed, " passed, ", failed, " failed")
	quit(1 if failed else 0)

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func _inventory(node: Node, result: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh != null:
		result.meshes += 1
		for surface in node.mesh.get_surface_count():
			result.surfaces += 1
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var indices: Variant = arrays[Mesh.ARRAY_INDEX]
			result.triangles += indices.size() / 3 if indices is PackedInt32Array and not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size() / 3
			var material: Material = node.get_active_material(surface)
			if material is StandardMaterial3D:
				for texture: Texture2D in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
					if texture != null:
						result.textures[texture.get_instance_id()] = texture
	for child in node.get_children():
		_inventory(child, result)
