extends "res://.local/facade_stage4/facade_bay_reduced_probe.gd"
## Diagnostic only: fresh process, same real Main and geometry, one changed
## sandstone sampling path. Never writes production resources or user settings.

const VARIANTS := ["full", "no-normal", "constant-orm", "both"]
const ORM_GREEN_MEAN := 0.8099872925702263


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3 or not args[0] in VARIANTS or DisplayServer.get_name() == "headless":
		quit(2)
		return
	var variant: String = args[0]
	_output = ProjectSettings.globalize_path(args[1]).simplify_path()
	_duration = float(args[2])
	_size = Vector2i(1280, 800)
	_quality = "balanced"
	var allowed := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	if not (_output + "/").begins_with(allowed) or _duration != 20.0 \
			or not RenderingServer.render_loop_enabled or not is_equal_approx(Engine.time_scale, 1.0):
		quit(2)
		return
	for arg: String in OS.get_cmdline_args():
		if arg in ["--fixed-fps", "--disable-render-loop"] or arg.begins_with("--fixed-fps="):
			quit(2)
			return
	if DirAccess.make_dir_recursive_absolute(_output) != OK:
		quit(2)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = _size
	root.content_scale_size = _size
	game = Main.new()
	game.persistence_enabled = false
	game.set_meta(&"facade_bay_enabled", true)
	root.add_child(game)
	game.apply_settings({"graphics_quality":_quality}, false)
	game.start_mode(true)
	var ordinary_defaults := {"main_default":bool(game.get_meta("pt24_design_preview",false)),
		"world_default":bool(game.world.get_meta("pt24_design_preview",false)),
		"station":game.world.find_child("StationRailway",true,false)!=null,
		"train":game.world.find_child("ScenicTwoCoachTrain",true,false)!=null,
		"pond":game.world.find_child("KelvingrovePond",true,false)!=null,
		"civic_return":game.world.find_child("CivicPortReturn",true,false)!=null,
		"central_green":game.world.has_meta("pt24_central_green_report")}
	for field: String in ordinary_defaults:
		if not ordinary_defaults[field]: _errors.append("Missing ordinary default: " + field)
	game.skater.set_controls_enabled(false)
	game.skater.set_trick_entries_enabled(false)
	var buildings: Array[Node] = []
	for node: Node in game.world.get_children():
		if bool(node.get_meta(Bay.META, false)): buildings.append(node)
	if buildings.size() != 1 or not buildings[0].has_node("GlasgowBayLOD"):
		_errors.append("Expected one unchanged candidate facade.")
		quit(1)
		return
	var holder := buildings[0].get_node("GlasgowBayLOD")
	var levels: Array[MeshInstance3D] = []
	for child: Node in holder.get_children():
		if child is MeshInstance3D: levels.append(child)
	if levels.size() != 3:
		_errors.append("Expected three original LOD instances.")
		quit(1)
		return
	var original := levels[0].get_surface_override_material(0) as StandardMaterial3D
	if original == null or not original.normal_enabled or original.normal_texture == null \
			or original.roughness_texture == null or original.roughness_texture_channel != BaseMaterial3D.TEXTURE_CHANNEL_GREEN:
		_errors.append("Original authored sandstone contract changed.")
		quit(1)
		return
	# Duplicate only the material; textures remain the exact shared resources and
	# Bay's original materials keep all four maps resident for every variant.
	var stone := original.duplicate() as StandardMaterial3D
	var before := _material_contract(original)
	if variant in ["no-normal", "both"]: stone.normal_enabled = false
	if variant in ["constant-orm", "both"]:
		stone.roughness_texture = null
		stone.roughness = ORM_GREEN_MEAN
	var after := _material_contract(stone)
	var changed: Array[String] = []
	for key: String in before:
		if typeof(before[key]) != typeof(after[key]) or before[key] != after[key]: changed.append(key)
	var expected: Array[String] = []
	if variant in ["no-normal", "both"]: expected.append("normal_enabled")
	if variant in ["constant-orm", "both"]:
		expected.append("roughness")
		expected.append("roughness_texture")
	changed.sort()
	expected.sort()
	if changed != expected: _errors.append("Material changed outside declared sampling fields.")
	var geometry: Array[Dictionary] = []
	for level: MeshInstance3D in levels:
		var mesh := level.mesh
		var transform_before := level.transform
		var untouched: Array[Material] = []
		if mesh.get_surface_count() != 4: _errors.append("Original four material surfaces changed.")
		for slot: int in range(4):
			var material := level.get_surface_override_material(slot) as StandardMaterial3D
			if material == null or material.resource_name != Bay.SLOT_NAMES[slot] \
					or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				_errors.append("Original opaque material class changed.")
		for slot: int in range(1,4): untouched.append(level.get_surface_override_material(slot))
		if level.get_surface_override_material(0) != original: _errors.append("Original stone was not shared.")
		level.set_surface_override_material(0, stone)
		if level.mesh != mesh or level.transform != transform_before: _errors.append("Geometry moved.")
		for slot: int in range(1,4):
			if level.get_surface_override_material(slot) != untouched[slot-1]: _errors.append("Untargeted material changed.")
		geometry.append({"name":str(level.name), "mesh_path":mesh.resource_path,
			"surfaces":mesh.get_surface_count(), "face_vertices":mesh.get_faces().size(),
			"bounds_position":Metrics._vector(mesh.get_aabb().position),
			"bounds_size":Metrics._vector(mesh.get_aabb().size),
			"transform":str(level.transform), "shadow_mode":level.cast_shadow,
			"visibility_begin":level.visibility_range_begin,"visibility_end":level.visibility_range_end})
	_inspection = Camera3D.new()
	_inspection.fov = game.skater._camera.fov
	_inspection.near = 0.2
	_inspection.far = 220
	root.add_child(_inspection)
	_inspection.position = Vector3(-23,7.5,7)
	_inspection.look_at(Vector3(-35,7.5,5.75))
	_inspection.current = true
	await _settle()
	# Same inherited six completed-draw warmup frames and sample/counter writer
	# used by the failed near cell. No fixed clock or render-loop alteration.
	var started := Time.get_ticks_usec()
	await _stationary("03-frontage-near", started)
	var summary: Dictionary = _views[0]
	if int(summary.samples) < 30: _errors.append("Fewer than30 native rendered samples.")
	var report := {"schema":1,"mode":"near_material_ablation","variant":variant,
		"valid":_errors.is_empty(),"errors":_errors,"engine":Engine.get_version_info(),
		"renderer":RenderingServer.get_current_rendering_method(),
		"device":RenderingServer.get_video_adapter_name(),"size":[_size.x,_size.y],
		"settings":game.career.settings,"normal_render_loop":true,"fixed_fps":false,
		"profile_writes":game.persistence_enabled,"ordinary_defaults":ordinary_defaults,
		"mesh_root":Bay.MESH_ROOT,"texture_root":Bay.ASSET_ROOT,
		"geometry":geometry,"four_original_opaque_classes":true,
		"camera_position":Metrics._vector(_inspection.position),"camera_target":[-35,7.5,5.75],
		"camera_fov":_inspection.fov,"camera_near":_inspection.near,"camera_far":_inspection.far,
		"stone_before":before,"stone_after":after,"changed_fields":changed,
		"original_maps_resident":original.normal_texture != null and original.roughness_texture != null,
		"stationary_views":_views,"moving_trials":[],"requested_seconds":_duration,
		"limits":["Linux software renderer attribution only; no target Mac or production admission.",
			"Removing detail changes appearance intentionally; these variants are diagnostic controls.",
			"No moving-loop, facade-off baseline, resolution1920 or human-art acceptance is measured.",
			"p99 at20seconds is exploratory; attribution needs improvements beyond both bracket repeat noise and5percent."]}
	var written := _write(report)
	_release()
	print("FACADE_ABLATION_RESULT valid=",report.valid," variant=",variant," frames=",_samples.size())
	quit(0 if report.valid and written else 1)


func _material_contract(material: StandardMaterial3D) -> Dictionary:
	var result := {}
	for property: Dictionary in material.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var key := str(property.name)
		# Resource object identity differs deliberately for every fresh duplicate.
		if key in ["resource_local_to_scene", "resource_name", "script"]: continue
		var value: Variant = material.get(key)
		if value is Resource:
			result[key] = {"path":value.resource_path,"class":value.get_class()}
		else:
			result[key] = var_to_str(value)
	return result
