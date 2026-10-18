extends SceneTree
## Disposable import/material/native-LOD comparison, never a live-game probe.

const LEVELS: Array[String] = ["near", "mid", "far"]
const VARIANTS: Array[String] = ["fitted", "candidate"]
const TWO_SLOTS: Array[String] = ["01_Original_sandstone", "02_Original_accent_atlas"]
const FOUR_SLOTS: Array[String] = ["01_Original_sandstone", "02_Painted_forest_joinery", "03_Opaque_glazing", "04_Aged_dark_metal"]
const YAW := PI / 2.0
var _errors: Array[String] = []
var _manifest: Dictionary = {}
var _meshes: Dictionary = {}
var _textures: Dictionary = {}
var _materials: Dictionary = {}
var _mesh_records: Array[Dictionary] = []
var _texture_records: Array[Dictionary] = []
var _native_records: Array[Dictionary] = []
var _image_records: Array[Dictionary] = []
var _material_records: Array[Dictionary] = []
var _mip_records: Array[Dictionary] = []
var _environment_record: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> bool:
	if not condition:
		_errors.append(message)
		push_error(message)
	return condition


func _run() -> void:
	if not _check(DisplayServer.get_name() != "headless", "Actual rendered Compatibility display required"):
		_finish()
		return
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	root.msaa_3d = Viewport.MSAA_2X
	_manifest = JSON.parse_string(FileAccess.get_file_as_string("res://input-manifest.json"))
	for recipe: String in ["render.gd", "project.godot"]:
		_check(FileAccess.get_sha256("res://" + recipe) == str(_manifest.staged_executed_recipes_sha256[recipe]), "Actual executed recipe hash: " + recipe)
	if not _errors.is_empty():
		_finish()
		return
	if not _load_textures() or not _load_meshes():
		_finish()
		return
	_make_materials()
	await _native_lod_checks()
	if not _errors.is_empty():
		_finish()
		return
	await _capture_views()
	_finish()


func _load_textures() -> bool:
	for item: Dictionary in _manifest.textures:
		var path: String = "res://" + str(item.path)
		var texture := load(path) as Texture2D
		if not _check(texture != null, "Texture loads: " + path): return false
		var config := ConfigFile.new()
		if not _check(config.load(path + ".import") == OK, "Texture import exists: " + path): return false
		_check(config.get_value("params", "mipmaps/generate", null) == bool(item.mipmaps), "Exact texture mip import: " + path)
		_check(int(config.get_value("params", "compress/mode", -1)) == 2, "VRAM compressed import: " + path)
		var expected_normal: int = 1 if item.role == "normal_opengl_linear" else 2
		_check(int(config.get_value("params", "compress/normal_map", -1)) == expected_normal, "Normal/data role: " + path)
		_check(not bool(config.get_value("params", "process/normal_map_invert_y", true)), "Preserve OpenGL normal direction: " + path)
		_check(texture.get_width() == int(item.size) and texture.get_height() == int(item.size), "Imported dimensions: " + path)
		_check(FileAccess.get_sha256(path) == str(item.sha256), "Texture source hash: " + path)
		var image := texture.get_image()
		if not _check(image != null and not image.is_empty(), "Actual imported texture has data: " + path): return false
		_check(image.has_mipmaps() == bool(item.mipmaps), "Actual imported mip chain: " + path)
		var record := {"path":path, "role":item.role, "source_sha256":item.sha256,
			"resource_class":texture.get_class(), "resource_id":texture.get_instance_id(), "size":[image.get_width(),image.get_height()],
			"image_format":image.get_format(), "compressed":image.is_compressed(), "has_mipmaps":image.has_mipmaps(),
			"mipmap_count":image.get_mipmap_count(), "imported_data_bytes":image.get_data().size(),
			"import_sha256":FileAccess.get_sha256(path + ".import")}
		_texture_records.append(record)
		_textures[path.get_file()] = texture
		if path.get_file() in ["accent_basecolor.png", "accent_orm.png", "opaque_glazing_basecolor.png"]:
			_export_imported_mips(image, path.get_file().get_basename())
	return _errors.is_empty()


func _export_imported_mips(image: Image, label: String) -> void:
	# Read back actual imported compressed data. These decoded mip PNGs are
	# diagnostics; they do not claim the GPU's exact anisotropic filter result.
	if image.is_compressed():
		if not _check(image.decompress() == OK, "Imported mip decode: " + label): return
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	for level: int in range(image.get_mipmap_count() + 1):
		var width: int = maxi(1, image.get_width() >> level)
		var height: int = maxi(1, image.get_height() >> level)
		var offset: int = image.get_mipmap_offset(level)
		var decoded := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, bytes.slice(offset, offset + width * height * 4))
		var filename := "mip-" + label + "-" + str(level).pad_zeros(2) + ".png"
		_check(decoded.save_png("res://" + filename) == OK, "Decoded actual mip PNG: " + filename)
		_mip_records.append({"image":filename, "texture":label, "level":level, "size":[width,height]})


func _load_meshes() -> bool:
	for variant: String in VARIANTS: _meshes[variant] = {}
	for item: Dictionary in _manifest.assets:
		var path: String = "res://" + str(item.path)
		var config := ConfigFile.new()
		if not _check(config.load(path + ".import") == OK, "Mesh import exists: " + path): return false
		_check(config.get_value("params", "meshes/generate_lods", true) == false, "No generated mesh LODs: " + path)
		_check(FileAccess.get_sha256(path) == str(item.sha256), "Mesh source hash: " + path)
		var packed := load(path) as PackedScene
		if not _check(packed != null, "Mesh loads: " + path): return false
		var model := packed.instantiate()
		var nodes := model.find_children("*", "MeshInstance3D", true, false)
		if not _check(nodes.size() == 1, "Single imported mesh: " + path):
			model.free()
			return false
		var instance: MeshInstance3D = nodes[0]
		var mesh := instance.mesh
		_check(mesh.get_surface_count() == int(item.surfaces), "Exact imported surface count: " + path)
		var triangles: int = mesh.get_faces().size() / 3
		_check(triangles == int(item.triangles), "Exact imported triangle count: " + path)
		var bounds := mesh.get_aabb()
		_check(bounds.position.is_equal_approx(Vector3(-3.25, 0, -0.5)) and bounds.size.is_equal_approx(Vector3(6.5, 16, 0.86)), "Imported metre bounds: " + path)
		var transform := instance.transform
		var ancestor := instance.get_parent()
		while ancestor != null:
			if ancestor is Node3D: transform = ancestor.transform * transform
			if ancestor == model: break
			ancestor = ancestor.get_parent()
		_check(transform.is_equal_approx(Transform3D.IDENTITY), "Applied import transform: " + path)
		var slots: Array[String] = TWO_SLOTS if item.variant == "candidate" else FOUR_SLOTS
		var formats: Array[int] = []
		for index: int in range(mesh.get_surface_count()):
			var material := mesh.surface_get_material(index)
			_check(material != null and material.resource_name == slots[index], "Imported named slot: " + path + ":" + str(index))
			formats.append(mesh.surface_get_format(index))
		_meshes[item.variant][item.lod] = mesh
		_mesh_records.append({"path":path, "sha256":item.sha256, "triangles":triangles, "surfaces":mesh.get_surface_count(),
			"surface_formats":formats, "bounds_min":_vector(bounds.position), "bounds_size":_vector(bounds.size),
			"import_sha256":FileAccess.get_sha256(path + ".import"), "auto_mesh_lods":false})
		model.free()
	return _errors.is_empty()


func _make_materials() -> void:
	var stone := StandardMaterial3D.new()
	stone.resource_name = FOUR_SLOTS[0]
	stone.albedo_texture = _textures["sandstone_basecolor.png"]
	stone.albedo_color = Color(0.32, 0.42, 0.57).linear_to_srgb()
	stone.normal_enabled = true
	stone.normal_texture = _textures["sandstone_normal_opengl.png"]
	stone.normal_scale = 1.0
	stone.roughness_texture = _textures["sandstone_orm.png"]
	stone.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	stone.roughness = 1.0
	var paint := StandardMaterial3D.new()
	paint.resource_name = FOUR_SLOTS[1]
	paint.albedo_color = Color(0.028, 0.085, 0.067).linear_to_srgb()
	paint.roughness = 0.48
	var glass := StandardMaterial3D.new()
	glass.resource_name = FOUR_SLOTS[2]
	glass.albedo_texture = _textures["opaque_glazing_basecolor.png"]
	glass.roughness = 0.32
	glass.metallic = 0.0
	var metal := StandardMaterial3D.new()
	metal.resource_name = FOUR_SLOTS[3]
	metal.albedo_color = Color(0.105, 0.095, 0.069).linear_to_srgb()
	metal.roughness = 0.46
	metal.metallic = 0.65
	var accent := ORMMaterial3D.new()
	accent.resource_name = TWO_SLOTS[1]
	accent.albedo_color = Color.WHITE
	accent.albedo_texture = _textures["accent_basecolor.png"]
	accent.orm_texture = _textures["accent_orm.png"]
	accent.roughness = 1.0
	accent.metallic = 1.0
	_materials = {"fitted":[stone,paint,glass,metal], "candidate":[stone,accent]}
	for material: BaseMaterial3D in [stone,paint,glass,metal,accent]:
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material.cull_mode = BaseMaterial3D.CULL_BACK
		material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_material_records.append({"name":material.resource_name, "class":material.get_class(), "resource_id":material.get_instance_id(),
			"texture_filter":material.texture_filter, "opaque":material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED,
			"backface_culling":material.cull_mode == BaseMaterial3D.CULL_BACK, "normal_enabled":material.normal_enabled,
			"albedo_srgb":[material.albedo_color.r,material.albedo_color.g,material.albedo_color.b],
			"roughness_factor":material.roughness, "metallic_factor":material.metallic,
			"albedo_texture":material.albedo_texture.resource_path if material.albedo_texture != null else "",
			"normal_texture":material.normal_texture.resource_path if material.normal_texture != null else "",
			"packed_orm_texture":accent.orm_texture.resource_path if material == accent else "",
			"packed_orm_channels":"R=occlusion, G=roughness, B=metallic; linear data" if material == accent else "",
			"roughness_texture":material.roughness_texture.resource_path if material is StandardMaterial3D and material.roughness_texture != null else ""})
	_check(_materials.fitted[0] == _materials.candidate[0], "Both variants share the exact stone material/resource")
	_check(accent.orm_texture == _textures["accent_orm.png"] and accent.albedo_texture == _textures["accent_basecolor.png"], "Packed linear ORM / sRGB albedo roles are bound on built-in ORMMaterial3D")
	_check(accent.roughness == 1.0 and accent.metallic == 1.0 and accent.albedo_color == Color.WHITE, "Packed channels have unit factors; no scalar tint/metallic suppression")
	_check(accent.normal_enabled == false, "Accent has no unintended stone normal map")


func _lod_holder(parent: Node3D, variant: String) -> Node3D:
	var holder := Node3D.new()
	holder.name = variant.capitalize()
	parent.add_child(holder)
	var instances: Array[MeshInstance3D] = []
	for lod: String in LEVELS:
		var instance := MeshInstance3D.new()
		instance.name = lod.capitalize()
		instance.mesh = _meshes[variant][lod]
		for slot: int in range(_materials[variant].size()):
			instance.set_surface_override_material(slot, _materials[variant][slot])
			_check(instance.get_surface_override_material(slot) == _materials[variant][slot], "LOD reuses cached material: " + variant + "/" + lod)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		holder.add_child(instance)
		instances.append(instance)
	instances[2].visibility_range_begin = 80.0
	instances[2].visibility_range_begin_margin = 6.0
	instances[1].visibility_range_begin = 25.0
	instances[1].visibility_range_begin_margin = 4.0
	instances[1].visibility_parent = instances[1].get_path_to(instances[2])
	instances[0].visibility_parent = instances[0].get_path_to(instances[1])
	return holder


func _native_lod_checks() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := Node3D.new()
	viewport.add_child(scene)
	var camera := Camera3D.new()
	camera.fov = 90
	camera.far = 220
	scene.add_child(camera)
	camera.current = true
	var sweep := [[20.0,"near"],[28.0,"near"],[30.0,"mid"],[22.0,"mid"],[20.0,"near"],[45.0,"mid"],[85.0,"mid"],[87.0,"far"],[75.0,"far"],[73.0,"mid"],[110.0,"far"]]
	for variant: String in VARIANTS:
		var holder := _lod_holder(scene, variant)
		var center: Vector3 = _meshes[variant].near.get_aabb().get_center()
		for point: Array in sweep:
			camera.position = center + Vector3(0, 0, float(point[0]))
			camera.look_at(center)
			for tick: int in range(3): await RenderingServer.frame_post_draw
			var actual := viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
			var expected: int = _meshes[variant][point[1]].get_faces().size() / 3
			_check(actual == expected, "Native LOD primitive count: " + variant + " at " + str(point[0]))
			_native_records.append({"variant":variant, "distance_m":point[0], "expected_lod":point[1], "expected_triangles":expected, "actual_visible_primitives":actual})
		holder.free()
	viewport.free()
	await process_frame


func _capture_views() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("8e9eaa")
	sky_material.sky_horizon_color = Color("c4c8c4")
	sky_material.ground_bottom_color = Color("727b7c")
	sky_material.ground_horizon_color = Color("c4c8c4")
	sky_material.sun_angle_max = 5.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c7dfeb")
	environment.ambient_light_energy = 0.44
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.fog_enabled = true
	environment.fog_density = 0.0015
	environment.fog_light_color = Color("b4bec3")
	environment.fog_sky_affect = 0.15
	var env := WorldEnvironment.new()
	env.environment = environment
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -32, 0)
	sun.light_color = Color("ffe8d1")
	sun.light_energy = 0.80
	sun.shadow_opacity = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 75.0
	world.add_child(sun)
	_environment_record = {"source":"game/levels/glasgow_square.gd:_build_lighting", "source_sha256":_manifest.sources_sha256["game/levels/glasgow_square.gd"],
		"background_mode":environment.background_mode, "sky_material_class":sky_material.get_class(), "sky_radiance_size":sky.radiance_size,
		"sky_top_color":sky_material.sky_top_color.to_html(), "sky_horizon_color":sky_material.sky_horizon_color.to_html(),
		"ground_bottom_color":sky_material.ground_bottom_color.to_html(), "ground_horizon_color":sky_material.ground_horizon_color.to_html(),
		"sky_sun_angle_max":sky_material.sun_angle_max, "ambient_source":environment.ambient_light_source,
		"ambient_color":environment.ambient_light_color.to_html(), "ambient_energy":environment.ambient_light_energy,
		"ambient_sky_contribution":environment.ambient_light_sky_contribution, "reflected_source":environment.reflected_light_source,
		"tonemap_mode":environment.tonemap_mode, "tonemap_exposure":environment.tonemap_exposure,
		"fog_enabled":environment.fog_enabled, "fog_density":environment.fog_density, "fog_color":environment.fog_light_color.to_html(),
		"fog_sky_affect":environment.fog_sky_affect, "sun_rotation_degrees":_vector(sun.rotation_degrees),
		"sun_color":sun.light_color.to_html(), "sun_energy":sun.light_energy, "shadow_opacity":sun.shadow_opacity,
		"shadow_mode":sun.directional_shadow_mode, "shadow_max_distance":sun.directional_shadow_max_distance}
	var fixture := Node3D.new()
	fixture.rotation.y = YAW
	world.add_child(fixture)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("64706b")
	ground_material.roughness = 0.9
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(300, 300)
	ground.mesh = plane
	ground.material_override = ground_material
	ground.position.y = -0.015
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fixture.add_child(ground)
	var apron := MeshInstance3D.new()
	var deck := BoxMesh.new()
	deck.size = Vector3(7, 0.45, 4)
	apron.mesh = deck
	apron.material_override = ground_material
	apron.position = Vector3(0, 0.225, 2.125)
	fixture.add_child(apron)
	var mass_shadow := MeshInstance3D.new()
	var mass := BoxMesh.new()
	mass.size = Vector3(30, 16, 12)
	mass_shadow.mesh = mass
	mass_shadow.position = Vector3(5.75, 8, -6)
	mass_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	fixture.add_child(mass_shadow)
	var camera := Camera3D.new()
	camera.near = 0.10
	camera.far = 220
	world.add_child(camera)
	camera.current = true
	var views := [
		{"id":"01-front","at":Vector3(0,8,22),"target":Vector3(0,8,0),"fov":55.0,"lod":"near"},
		{"id":"02-close","at":Vector3(0,3.7,7.3),"target":Vector3(0,3.7,0),"fov":60.0,"lod":"near"},
		{"id":"03-threshold","at":Vector3(3,1.6,2.7),"target":Vector3(2,0.9,0.05),"fov":55.0,"lod":"near"},
		{"id":"04-oblique","at":Vector3(6.5,6,9.5),"target":Vector3(0,5.8,0),"fov":55.0,"lod":"near"},
		{"id":"05-foreshortened","at":Vector3(9.2,3.2,1.5),"target":Vector3(0,3.1,0.03),"fov":60.0,"lod":"near"},
		{"id":"06-distant-near","at":Vector3(0,8,24),"target":Vector3(0,8,0),"fov":50.0,"lod":"near"},
		{"id":"07-distant-mid","at":Vector3(0,8,45),"target":Vector3(0,8,0),"fov":55.0,"lod":"mid"},
		{"id":"08-distant-far","at":Vector3(0,8,110),"target":Vector3(0,8,0),"fov":55.0,"lod":"far"}]
	for variant: String in VARIANTS:
		var holder := _lod_holder(fixture, variant)
		for view: Dictionary in views:
			camera.position = fixture.to_global(view.at)
			camera.fov = float(view.fov)
			camera.look_at(fixture.to_global(view.target))
			# Measure only the identical fixture from this exact camera first.
			holder.hide()
			for tick: int in range(3): await RenderingServer.frame_post_draw
			var fixture_primitives := root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
			holder.show()
			# Seed an unambiguous native state before views inside hysteresis.
			# The stage still has to prove itself from the captured frame's
			# primitive delta; this does not set any per-stage visible flag.
			var seed_distance: float = {"near":18.0,"mid":45.0,"far":110.0}[view.lod]
			camera.position = fixture.to_global(Vector3(0,8,seed_distance))
			camera.look_at(fixture.to_global(Vector3(0,8,0)))
			for tick: int in range(3): await RenderingServer.frame_post_draw
			camera.position = fixture.to_global(view.at)
			camera.look_at(fixture.to_global(view.target))
			for tick: int in range(4): await RenderingServer.frame_post_draw
			var visible_primitives := root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
			var expected_triangles: int = _meshes[variant][view.lod].get_faces().size() / 3
			_check(visible_primitives - fixture_primitives == expected_triangles, "Captured actual native stage: " + variant + "/" + str(view.id))
			var filename: String = variant + "-" + str(view.id) + ".png"
			var image := root.get_texture().get_image()
			_check(image.get_size() == Vector2i(1920,1080) and image.save_png("res://" + filename) == OK, "Actual matched capture: " + filename)
			_image_records.append({"image":filename, "variant":variant, "view":view.id, "expected_native_lod":view.lod,
				"camera_position":_vector(camera.position), "target":_vector(fixture.to_global(view.target)), "fov":camera.fov,
				"fixture_only_primitives":fixture_primitives, "visible_primitives_including_fixture":visible_primitives,
				"actual_holder_primitive_delta":visible_primitives-fixture_primitives, "expected_triangles":expected_triangles,
				"native_seed_distance_m":seed_distance, "captured_process_frame":Engine.get_process_frames(),
				"source_sha256":FileAccess.get_sha256("res://" + variant + "/glasgow_bay_" + str(view.lod) + ".glb")})
			print("MATCHED_BAY_CAPTURE ", filename)
		holder.free()
	world.free()


func _finish() -> void:
	var report := {"schema":1, "engine":Engine.get_version_info().string, "adapter":RenderingServer.get_video_adapter_name(),
		"renderer":RenderingServer.get_current_rendering_method(), "images":_image_records, "errors":_errors,
		"meshes":_mesh_records, "textures":_texture_records, "materials":_material_records, "native_lod_samples":_native_records,
		"decoded_imported_mip_images":_mip_records, "performance_measurement":false, "live_integration":false,
		"environment":_environment_record,
		"lighting":"Production procedural sky/radiance, ambient, fog, sun, ACES and west-frontage yaw; identical isolated floor/apron/mass-shadow fixture",
		"limits":"Isolated static visual/import comparison; no full-game FPS, collision, camera, actual mip selection, Mac or human acceptance claim"}
	var file := FileAccess.open("res://report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("TWO_SURFACE_PREVIEW images=", _image_records.size(), " native_samples=", _native_records.size(), " errors=", _errors.size())
	quit(0 if _errors.is_empty() else 1)


func _vector(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
