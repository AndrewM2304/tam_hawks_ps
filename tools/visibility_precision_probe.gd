extends SceneTree
## Isolate near-plane depth precision from occlusion with one frozen world.
## Actual image/counter diagnostic; no frame-time, Mac or gameplay acceptance.

const World = preload("res://game/levels/glasgow_square.gd")
const Budget = preload("res://game/levels/render_budget.gd")
const Batches = preload("res://game/levels/static_batches.gd")
const VIEWS: Array[Dictionary] = [
	{"id":"park_south","at":Vector3(-204,16,-146),"yaw":PI},
	{"id":"central_station","at":Vector3(-57.757,5.4,26.243),"yaw":PI/4.0},
]
const NEAR_PLANES: Array[float] = [0.05, 0.20]

var world: Node3D
var camera: Camera3D
var output := ""
var frames: Array[Dictionary] = []
var errors := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("VISIBILITY_PRECISION requires an actual renderer.")
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() < 1 or args.size() > 2:
		quit(2)
		return
	output = ProjectSettings.globalize_path(args[0]).simplify_path()
	var allowed := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	if not (output + "/").begins_with(allowed) or DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(2)
		return
	var cell_size := float(args[1]) if args.size() == 2 else 32.0
	if not cell_size in [0.0, 32.0, 48.0, 64.0]:
		quit(2)
		return
	var source_before := _fingerprint()
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	root.use_occlusion_culling = false
	Engine.max_fps = 0
	Engine.time_scale = 0.0
	world = World.new()
	world.set_meta("render_budget_probe_baseline", true)
	root.add_child(world)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Budget.apply_static_decor(world)
	var batch_report: Dictionary = Batches.finalize(world, cell_size) if cell_size > 0 else {"disabled":true}
	camera = Camera3D.new()
	camera.fov = 68.0
	camera.far = 220.0
	root.add_child(camera)
	camera.make_current()
	for near_plane: float in NEAR_PLANES:
		camera.near = near_plane
		for view: Dictionary in VIEWS:
			camera.position = view.at
			camera.rotation = Vector3(-0.3154876, view.yaw, 0)
			# Off/on/off with the same camera distinguishes repeatable culling
			# changes from animation, stale visibility history or nondeterminism.
			for phase: String in ["off", "on", "off_repeat"]:
				root.use_occlusion_culling = phase == "on"
				for warmup: int in 6:
					await RenderingServer.frame_post_draw
				var draws: Array[int] = []
				var primitives: Array[int] = []
				for sample: int in 3:
					await RenderingServer.frame_post_draw
					draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
					primitives.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
				draws.sort()
				primitives.sort()
				var image_name := "%s-near-%03d-occlusion-%s.png" % [view.id, roundi(near_plane * 1000), phase]
				var image := root.get_texture().get_image()
				if image.get_size() != Vector2i(1280,800) or image.save_png(output.path_join(image_name)) != OK:
					errors += 1
				frames.append({"view":view.id,"near":camera.near,"far":camera.far,"fov":camera.fov,
					"camera_position":[camera.position.x,camera.position.y,camera.position.z],
					"camera_rotation":[camera.rotation.x,camera.rotation.y,camera.rotation.z],
					"occlusion":root.use_occlusion_culling,"phase":phase,"image":image_name,
					"image_sha256":FileAccess.get_sha256(output.path_join(image_name)),
					"draws":draws,"draws_p50":draws[1],"primitives":primitives,"primitives_p50":primitives[1]})
				print("VISIBILITY_PRECISION_FRAME ", view.id, " near=", camera.near,
					" phase=",phase," draws=",draws[1]," primitives=",primitives[1])
	var source_after := _fingerprint()
	var changed: Array[String] = []
	for path: String in source_before:
		if source_before[path] != source_after.get(path, ""): changed.append(path)
	for path: String in source_after:
		if not source_before.has(path): changed.append(path)
	var containment := _occluder_containment()
	if not changed.is_empty() or not containment.ok: errors += 1
	var report := {"schema":1,"engine":Engine.get_version_info(),
		"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"recorded_at_utc":Time.get_datetime_string_from_system(true),"resolution":[1280,800],
		"world_only":true,"performance_measurement":false,"target_hardware_acceptance":false,
		"cell_size":cell_size,"batch_report":batch_report,"frames":frames,
		"occluder_containment":containment,"source_stable":changed.is_empty(),"changed_inputs":changed,
		"source_inputs":source_before,"errors":errors,
		"limits":"One frozen production world and identical fixed cameras: near .05/.20, occlusion off/on/off-repeat. No moving gameplay, frame-time or Mac result. The near change tests depth precision; current depth-buffer format is not asserted. Compare PNGs and repeat baselines externally; a smaller pixel delta alone is not proof of correct occlusion. Occluder containment checks exact actual box wall bounds, not semantic doorway intent."}
	var file := FileAccess.open(output.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()
	print("VISIBILITY_PRECISION errors=",errors," source_stable=",changed.is_empty()," output=",output)
	quit(1 if errors else 0)


func _occluder_containment() -> Dictionary:
	var details: Array[Dictionary] = []
	var valid := true
	for occluder: OccluderInstance3D in world.find_children("*", "OccluderInstance3D", true, false):
		var wall: MeshInstance3D
		for child: Node in occluder.get_parent().get_children():
			if child is MeshInstance3D and child.mesh is BoxMesh:
				wall = child
				break
		var inside := wall != null and occluder.occluder is BoxOccluder3D
		if inside:
			var relative: Transform3D = wall.global_transform.affine_inverse() * occluder.global_transform
			var half: Vector3 = wall.mesh.size * 0.5
			var occluder_half: Vector3 = occluder.occluder.size * 0.5
			for sx: float in [-1,1]:
				for sy: float in [-1,1]:
					for sz: float in [-1,1]:
						var corner := relative * (occluder_half * Vector3(sx,sy,sz))
						inside = inside and absf(corner.x) <= half.x + 0.0001 \
							and absf(corner.y) <= half.y + 0.0001 and absf(corner.z) <= half.z + 0.0001
		valid = valid and inside
		details.append({"occluder":str(occluder.get_path()),"wall":str(wall.get_path()) if wall != null else "",
			"inside_actual_wall_box":inside})
	return {"ok":valid,"count":details.size(),"walls":details}


func _fingerprint() -> Dictionary:
	var paths: Array[String] = ["res://project.godot","res://tools/visibility_precision_probe.gd"]
	for folder: String in ["res://game/levels","res://game/art","res://game/tricks"]:
		_collect_files(folder, paths)
	paths.sort()
	var hashes: Dictionary = {}
	for path: String in paths:
		hashes[path.trim_prefix("res://")] = FileAccess.get_sha256(path)
	return hashes


func _collect_files(folder: String, paths: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(folder): paths.append(folder.path_join(file))
	for subfolder: String in DirAccess.get_directories_at(folder): _collect_files(folder.path_join(subfolder), paths)
