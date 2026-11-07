extends SceneTree
func _initialize() -> void:
	var report: Dictionary = {"voice_streams": {}, "textures": {}, "human_meshes": {}, "main_scene_loaded": false}
	var main_scene := load("res://game/main.tscn") as PackedScene
	if main_scene == null:
		push_error("Pack is missing its main scene or script dependencies.")
		quit(1)
		return
	var instance := main_scene.instantiate()
	if instance.get_script() == null:
		push_error("Pack main scene has no loadable game script.")
		instance.free()
		quit(1)
		return
	instance.free()
	report.main_scene_loaded = true
	var durations: Dictionary = {"landing": 0.9495, "cone": 1.2485, "again": 1.137875}
	for id: String in durations:
		var path := "res://game/audio/generated/%s.wav" % id
		var stream := load(path) as AudioStreamWAV
		if stream == null or absf(stream.get_length() - float(durations[id])) > 0.03:
			push_error("Pack is missing the expected imported voice stream: " + path)
			quit(1)
			return
		report.voice_streams[id] = {"resource": path, "seconds": stream.get_length()}
	for material: String in ["T_bricks01", "T_concrete01"]:
		for channel: String in ["albedo", "normal_opengl"]:
			var path := "res://game/art/assets/zc_textures/%s/%s_%s.jpg" % [material, material, channel]
			var texture := load(path) as Texture2D
			if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0 or texture.get_width() > 1024 or texture.get_height() > 1024:
				push_error("Pack is missing a bounded imported material texture: " + path)
				quit(1)
				return
			var image := texture.get_image()
			if image == null or not image.has_mipmaps():
				push_error("Pack texture is missing its image or required mipmaps: " + path)
				quit(1)
				return
			report.textures[path] = {"width": texture.get_width(), "height": texture.get_height(), "mipmaps": image.get_mipmap_count()}
	for id: String in ["head", "hair", "left_hand", "right_hand"]:
		var path := "res://game/art/assets/makehuman_hm08/%s.obj" % id
		var mesh := load(path) as ArrayMesh
		if mesh == null or mesh.get_surface_count() == 0 or mesh.surface_get_array_len(0) < 50:
			push_error("Pack is missing cropped anatomical mesh: " + path)
			quit(1)
			return
		report.human_meshes[id] = {"resource": path, "surfaces": mesh.get_surface_count(), "vertices": mesh.surface_get_array_len(0)}
	var environment_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/assets/environment_pbr/manifest.json"))
	var rider_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/rider/manifest.json"))
	if not environment_manifest is Dictionary or not rider_manifest is Dictionary:
		push_error("Pack is missing its readable fidelity provenance manifests.")
		quit(1)
		return
	for material: Dictionary in environment_manifest.materials.values():
		for channel: String in material.files:
			var policy: Dictionary = environment_manifest.import_policy.maximum_dimension_by_map
			var cap := int(policy.get(channel, 1024)) if material.provider == "Poly Haven" else int(policy.zc_materials_all_maps)
			if not _fidelity_texture(str(material.files[channel]), cap, report):
				quit(1)
				return
	for name: String in rider_manifest.maps:
		if not _fidelity_texture("res://game/art/rider/" + name, 2048, report):
			quit(1)
			return
	var derived_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/assets/environment_pbr/derived/manifest.json"))
	if not derived_manifest is Dictionary:
		push_error("Pack is missing its derived-surface provenance.")
		quit(1)
		return
	for name: String in derived_manifest.files:
		var cap := 2048 if name.begins_with("pavement_") else 1024
		if not _fidelity_texture("res://game/art/assets/environment_pbr/derived/" + name, cap, report):
			quit(1)
			return
	var fitted_path := "res://game/art/rider/fitted-manifest.json"
	var has_fitted := FileAccess.file_exists(fitted_path)
	var hair_path := "res://game/art/rider/fitted_hair.obj" if has_fitted else "res://game/art/rider/short_crop.obj"
	var hair := load(hair_path) as ArrayMesh
	if hair == null or hair.get_surface_count() != 1 or hair.surface_get_array_len(0) < 1000:
		push_error("Pack is missing its single-surface cropped hair mesh.")
		quit(1)
		return
	if has_fitted and not _fitted_resources(fitted_path, report):
		quit(1)
		return
	var output := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	if output == null:
		push_error("Could not write packaged resource report.")
		quit(1)
		return
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	print("RESOURCES VERIFIED: main scene/scripts, 3 voice streams, ", report.textures.size(), " material/rider textures and 4 anatomical meshes")
	quit(0)

func _fidelity_texture(path: String, cap: int, report: Dictionary) -> bool:
	var texture := load(path) as Texture2D
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0 or texture.get_width() > cap or texture.get_height() > cap:
		push_error("Pack is missing its bounded fidelity texture: " + path)
		return false
	var image := texture.get_image()
	if image == null or not image.has_mipmaps():
		push_error("Packed fidelity texture has no image/mipmaps: " + path)
		return false
	report.textures[path] = {"width": texture.get_width(), "height": texture.get_height(), "mipmaps": image.get_mipmap_count()}
	return true

func _fitted_resources(manifest_path: String, report: Dictionary) -> bool:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary or int(manifest.get("schema", -1)) != 1:
		push_error("Pack is missing readable fitted-rider provenance.")
		return false
	report.fitted_resources = {}
	for name: String in manifest.outputs:
		var path := "res://game/art/rider/" + name
		if name.ends_with(".json"):
			var parser := JSON.new()
			if not FileAccess.file_exists(path) or parser.parse(FileAccess.get_file_as_string(path)) != OK:
				push_error("Pack is missing readable fitted-rider metadata: " + path)
				return false
			report.fitted_resources[name] = {"kind": "json"}
		elif name.ends_with(".obj"):
			var mesh := load(path) as ArrayMesh
			if mesh == null or mesh.get_surface_count() == 0 or mesh.surface_get_array_len(0) < 3:
				push_error("Pack is missing an imported fitted-rider mesh: " + path)
				return false
			report.fitted_resources[name] = {"kind": "mesh", "surfaces": mesh.get_surface_count(), "vertices": mesh.surface_get_array_len(0)}
		elif name.ends_with(".glb"):
			var scene := load(path) as PackedScene
			if scene == null:
				push_error("Pack is missing an imported fitted-rider scene: " + path)
				return false
			var actor := scene.instantiate()
			var meshes := actor.find_children("*", "MeshInstance3D", true, false)
			var skeletons := actor.find_children("*", "Skeleton3D", true, false)
			var valid := not meshes.is_empty()
			var skinned := 0
			for node: MeshInstance3D in meshes:
				valid = valid and node.mesh != null and node.mesh.get_surface_count() > 0
				if node.skin != null and node.skin.get_bind_count() >= 11:
					skinned += 1
			if name == "fitted_outfit.glb":
				valid = valid and skinned >= 2 and not skeletons.is_empty()
			if not valid:
				actor.free()
				push_error("Pack contains an incomplete fitted-rider scene: " + path)
				return false
			report.fitted_resources[name] = {"kind": "scene", "mesh_nodes": meshes.size(), "skeletons": skeletons.size(), "skinned_meshes": skinned}
			actor.free()
	return true