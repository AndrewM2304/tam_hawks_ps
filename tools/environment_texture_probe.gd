extends SceneTree
## Isolated native allocation control for the exact shared surface upgrade.
## Reuses the production retired-map generator and the production PBR library.
const CityArt = preload("res://game/levels/city_art.gd")
const Library = preload("res://game/levels/art/material_library.gd")
const KEYS: Array[String] = ["stone","stone_light","sandstone","paving","path","asphalt","wood","grass"]
var _materials := {}
var _meshes: Array[MeshInstance3D] = []
var _failures := 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=1 or DisplayServer.get_name()=="headless": quit(2); return
	root.size = Vector2i(1280,800)
	root.content_scale_size = root.size
	var camera := Camera3D.new()
	camera.position = Vector3(0,5,12)
	root.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-30,0)
	root.add_child(light)
	_baseline_materials()
	for index: int in KEYS.size():
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		mesh.position = Vector3((index%4-1.5)*2.0,0,(index/4-0.5)*2.5)
		root.add_child(mesh)
		_meshes.append(mesh)
	_bind_grid()
	await _warm()
	var before := _record()
	Library.apply(_materials)
	_bind_grid()
	await _warm()
	var after := _record()
	var delta := int(after.texture_bytes)-int(before.texture_bytes)
	_check(before.unique_bound_maps==3,"control binds the exact three retired procedural maps")
	_check(after.unique_bound_maps==15,"production library binds exactly fifteen unique maps")
	_check(delta>16*1048576 and delta<=32*1048576,"native allocation delta fits the declared32MiB additional surface budget")
	for row: Dictionary in after.maps:
		var path: String = row.resource_path
		if path.contains("_nor_gl_2k.jpg"):
			_check(row.width==1024 and row.height==1024,"core normal map actually imported at1K: "+path)
		elif path.contains("_diff_2k.jpg") or path.ends_with("/pavement_albedo.png"):
			_check(row.width==2048 and row.height==2048,"core albedo retains2K: "+path)
	var report := {"schema":1,"failures":_failures,"engine":Engine.get_version_info(),
		"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),
		"before":before,"after":after,"additional_texture_bytes":delta,"additional_texture_mib":float(delta)/1048576.0,
		"budget_mib":32,"budget_pass":delta>16*1048576 and delta<=32*1048576,
		"method":"Fresh native process; eight identical visible material cubes, camera, light and viewport. Before uses exact existing CityArt._surface_texture masonry/paving/asphalt256px generator with original sharing. After calls the exact production MaterialLibrary.apply. Twelve completed natural frames after each state; actual Performance.RENDER_TEXTURE_MEM_USED difference. Texture readbacks separately record native formats, dimensions, compression and mip payloads. No Main/rider/HUD/network/save state. This isolates surface allocation, not whole-game performance or final visual quality."}
	var file := FileAccess.open(args[0].path_join("texture-report.json"),FileAccess.WRITE)
	_check(file!=null,"texture control report writable")
	if file: file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("ENVIRONMENT_TEXTURE_RESULT failures=",_failures," additional_mib=",float(delta)/1048576.0)
	quit(1 if _failures else 0)

func _baseline_materials() -> void:
	for key: String in KEYS+["glass","window_dull","window_lit","shop_glass","iron"]:
		_materials[key] = StandardMaterial3D.new()
	var art := CityArt.new()
	_materials.stone.albedo_texture = art._surface_texture("masonry")
	_materials.stone_light.albedo_texture = _materials.stone.albedo_texture
	_materials.sandstone.albedo_texture = _materials.stone.albedo_texture
	_materials.paving.albedo_texture = art._surface_texture("paving")
	_materials.path.albedo_texture = _materials.paving.albedo_texture
	_materials.asphalt.albedo_texture = art._surface_texture("asphalt")
	art.free()

func _bind_grid() -> void:
	for index: int in KEYS.size(): _meshes[index].material_override = _materials[KEYS[index]]

func _warm() -> void:
	for frame: int in 12: await RenderingServer.frame_post_draw

func _record() -> Dictionary:
	var maps: Array[Dictionary] = []
	var seen := {}
	for key: String in KEYS:
		var material: StandardMaterial3D = _materials[key]
		for texture: Texture2D in [material.albedo_texture,material.normal_texture,material.roughness_texture,material.ao_texture]:
			if texture==null or seen.has(texture.get_rid()): continue
			seen[texture.get_rid()] = true
			var image := texture.get_image()
			_check(image!=null,"live texture can be inspected")
			if image==null: continue
			maps.append({"first_binding":key,"resource_path":texture.resource_path,"width":image.get_width(),"height":image.get_height(),
				"format":image.get_format(),"compressed":image.is_compressed(),"mipmap_count":image.get_mipmap_count(),"native_readback_payload_bytes":image.get_data().size()})
	return {"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"draws":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),"unique_bound_maps":seen.size(),"maps":maps}

func _check(condition: bool,message: String) -> void:
	if condition:return
	_failures += 1
	push_error(message)
