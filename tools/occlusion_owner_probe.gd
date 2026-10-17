extends "res://tools/visibility_precision_probe.gd"
## One bounded discrimination: native culling with its own solid walls protected.
## This private-scene experiment does not enable occlusion in production.

const Visibility = preload("res://game/levels/city_visibility.gd")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(2)
		return
	output = ProjectSettings.globalize_path(args[0]).simplify_path()
	var allowed := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	if not (output + "/").begins_with(allowed) or DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(2)
		return
	var source_before := _owner_fingerprint()
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	root.use_occlusion_culling = false
	Engine.max_fps = 0
	Engine.time_scale = 0.0
	world = World.new()
	world.set_meta("render_budget_probe_baseline",true)
	root.add_child(world)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Budget.apply_static_decor(world)
	var batch_report: Dictionary = Batches.finalize(world,64)
	var owners: Array[Dictionary] = []
	for body: Node in world.find_children("*","Node3D",true,false):
		if not bool(body.get_meta(Visibility.WALL_MARK,false)): continue
		for child: Node in body.get_children():
			if child is MeshInstance3D and child.mesh is BoxMesh:
				owners.append({"node":child,"original_ignore":child.ignore_occlusion_culling,"path":str(child.get_path())})
				break
	if owners.size() != world.solid_wall_occluders:
		errors += 1
	camera = Camera3D.new()
	camera.near = 0.20
	camera.far = 220.0
	camera.fov = 68.0
	root.add_child(camera)
	camera.make_current()
	for view: Dictionary in VIEWS:
		camera.position = view.at
		camera.rotation = Vector3(-0.3154876,view.yaw,0)
		for phase: String in ["off","on","protected_on"]:
			for owner: Dictionary in owners:
				owner.node.ignore_occlusion_culling = true if phase == "protected_on" else owner.original_ignore
			root.use_occlusion_culling = phase != "off"
			for warmup: int in 6: await RenderingServer.frame_post_draw
			var draws: Array[int] = []
			var primitives: Array[int] = []
			for sample: int in 3:
				await RenderingServer.frame_post_draw
				draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
				primitives.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
			draws.sort()
			primitives.sort()
			var image_name := String(view.id)+"-"+phase+".png"
			var image := root.get_texture().get_image()
			if image.get_size()!=Vector2i(1280,800) or image.save_png(output.path_join(image_name))!=OK: errors+=1
			frames.append({"view":view.id,"near":camera.near,"phase":phase,
				"image":image_name,"image_sha256":FileAccess.get_sha256(output.path_join(image_name)),
				"draws":draws,"draws_p50":draws[1],"primitives":primitives,"primitives_p50":primitives[1],
				"protected_owner_walls":owners.size() if phase == "protected_on" else 0})
			print("OCCLUSION_OWNER_FRAME ",view.id," phase=",phase," draws=",draws[1]," primitives=",primitives[1])
	var source_after := _owner_fingerprint()
	var changed: Array[String] = []
	for path: String in source_before:
		if source_before[path] != source_after.get(path,""): changed.append(path)
	for path: String in source_after:
		if not source_before.has(path): changed.append(path)
	if not changed.is_empty(): errors+=1
	var paths: Array[String] = []
	for owner: Dictionary in owners: paths.append(owner.path)
	var report := {"schema":1,"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(),"resolution":[1280,800],"cell_size":64,"near":camera.near,
		"world_only":true,"production_integration":false,"performance_measurement":false,"target_hardware_acceptance":false,
		"source_stable":changed.is_empty(),"changed_inputs":changed,"source_inputs":source_before,
		"protected_owner_paths":paths,"owner_count":owners.size(),"occluder_count":world.solid_wall_occluders,
		"batch_report":batch_report,"frames":frames,"errors":errors,
		"limits":"One private frozen world; two fixed cameras, 64m batches and near .20. Off/on/protected-on changes only occlusion and its actual registered solid-wall visuals' ignore_occlusion_culling property. No production setting is changed. Captures/counters require external pixel comparison. A matching two-view experiment would not certify the remaining map, moving transitions, frame times or Mac performance."}
	var file := FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()
	print("OCCLUSION_OWNER errors=",errors," source_stable=",changed.is_empty()," output=",output)
	quit(1 if errors else 0)


func _owner_fingerprint() -> Dictionary:
	var sources := _fingerprint()
	sources["tools/occlusion_owner_probe.gd"] = FileAccess.get_sha256("res://tools/occlusion_owner_probe.gd")
	return sources
