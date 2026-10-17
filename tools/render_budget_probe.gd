extends SceneTree
## Same-process before/after visual-budget diagnostic, not a gameplay FPS claim.
const World = preload("res://game/levels/glasgow_square.gd")
const Budget = preload("res://game/levels/render_budget.gd")
const VIEWS: Array[Dictionary] = [
	{"id": "royal_exchange", "at": Vector3(-22, 3.4, 34), "yaw": 0.0},
	{"id": "george_square", "at": Vector3(-22, 7.4, -68), "yaw": 0.0},
	{"id": "central_station", "at": Vector3(-57.757, 5.4, 26.243), "yaw": PI / 4.0},
	{"id": "barras", "at": Vector3(60, 3.4, 28), "yaw": 0.0},
	{"id": "clyde", "at": Vector3(15, 5.4, 61), "yaw": PI},
	{"id": "kelvingrove", "at": Vector3(-150.757, 9.4, -77.757), "yaw": PI / 4.0},
	{"id": "park_north", "at": Vector3(-204, 16, -146), "yaw": 0.0},
	{"id": "park_south", "at": Vector3(-204, 16, -146), "yaw": PI},
]
var world: Node3D
var camera: Camera3D
var output := ""
var rows: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("RENDER_BUDGET: MultiMesh/counter evidence requires a real renderer; use the wrapper.")
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(2)
		return
	output = ProjectSettings.globalize_path(args[0]).simplify_path()
	var local_root := ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/") + "/"
	if not (output + "/").begins_with(local_root) or DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(2)
		return
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	world = World.new()
	# Allows this probe to preserve its baseline after normal-world integration.
	world.set_meta("render_budget_probe_baseline", true)
	root.add_child(world)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	camera = Camera3D.new()
	camera.fov = 68.0
	camera.far = 220.0
	root.add_child(camera)
	camera.make_current()
	var before := _inventory(world)
	var tree_before := _tree_records(world)
	await _scan("before")
	var changes: Dictionary = Budget.apply_static_decor(world, true)
	var after := _inventory(world)
	var tree_after := _tree_records(world)
	var tree_data_preserved := _same_records(tree_before, tree_after)
	await _scan("after")
	var report := {"schema_version": 1, "engine": Engine.get_version_info(),
		"recorded_at_utc": Time.get_datetime_string_from_system(true),
		"adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"render_resolution": [root.get_texture().get_width(), root.get_texture().get_height()],
		"world_only": true, "target_hardware_acceptance": false,
		"scope": "Frozen production world, exact same eight cameras before/after one startup helper. No rider, HUD, gameplay, frame-time or Mac acceptance claim.",
		"tree_data_preserved": tree_data_preserved, "inventory_before": before,
		"inventory_after": after, "changes": changes, "views": rows}
	var file := FileAccess.open(output.path_join("report.json"), FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("RENDER_BUDGET: tree_data_preserved=%s changes=%s output=%s" % [tree_data_preserved, changes, output])
	world.free()
	camera.free()
	quit(0 if tree_data_preserved and changes.tree_batches_split == 2 else 1)


func _scan(phase: String) -> void:
	for view: Dictionary in VIEWS:
		camera.position = view.at
		camera.rotation = Vector3(-0.3154876, view.yaw, 0.0)
		for warmup: int in range(2):
			await RenderingServer.frame_post_draw
		var draws: Array[int] = []
		var primitives: Array[int] = []
		var objects: Array[int] = []
		for sample: int in range(3):
			await RenderingServer.frame_post_draw
			draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
			primitives.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
			objects.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
		var screenshot := phase + "-" + String(view.id) + ".png"
		var error := root.get_texture().get_image().save_png(output.path_join(screenshot))
		if error != OK:
			push_error("RENDER_BUDGET: could not write actual rendered PNG: " + screenshot)
		draws.sort()
		primitives.sort()
		objects.sort()
		rows.append({"phase": phase, "view": view.id,
			"camera_position": [camera.position.x, camera.position.y, camera.position.z],
			"camera_rotation": [camera.rotation.x, camera.rotation.y, camera.rotation.z],
			"draw_calls": draws, "primitives": primitives, "objects": objects,
			"draw_calls_p50": draws[1], "primitives_p50": primitives[1],
			"screenshot": screenshot, "screenshot_error": error})
		print("RENDER_BUDGET_VIEW: %s %s draws=%d primitives=%d" % [phase, view.id, draws[1], primitives[1]])


func _inventory(node: Node) -> Dictionary:
	var result := {"nodes": 0, "meshes": {}, "multimeshes": 0, "physics_bodies": 0, "shapes": 0}
	_inventory_node(node, result)
	result.unique_meshes = result.meshes.size()
	result.erase("meshes")
	return result


func _inventory_node(node: Node, result: Dictionary) -> void:
	result.nodes += 1
	if node is MeshInstance3D and node.mesh:
		result.meshes[node.mesh.get_instance_id()] = true
	elif node is MultiMeshInstance3D and node.multimesh:
		result.multimeshes += 1
		result.meshes[node.multimesh.mesh.get_instance_id()] = true
	if node is PhysicsBody3D:
		result.physics_bodies += 1
	if node is CollisionShape3D:
		result.shapes += 1
	for child: Node in node.get_children():
		_inventory_node(child, result)


func _tree_records(node: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if node is MultiMeshInstance3D and (node.name in Budget.TREE_BATCH_NAMES or "_Cell_" in String(node.name)):
		var batch: MultiMesh = node.multimesh
		for index: int in range(batch.instance_count):
			result.append({"transform": node.global_transform * batch.get_instance_transform(index),
				"colour": batch.get_instance_color(index) if batch.use_colors else Color.WHITE,
				"custom": batch.get_instance_custom_data(index) if batch.use_custom_data else Color.BLACK,
				"mesh": batch.mesh, "material": node.material_override,
				"layers": node.layers, "cast_shadow": node.cast_shadow,
				"visible": node.visible, "cull_margin": node.extra_cull_margin,
				"range_begin": node.visibility_range_begin, "range_end": node.visibility_range_end})
	for child: Node in node.get_children():
		result.append_array(_tree_records(child))
	return result


func _same_records(before: Array[Dictionary], after: Array[Dictionary]) -> bool:
	if before.size() != after.size():
		return false
	for record: Dictionary in before:
		var index := after.find(record)
		if index < 0:
			return false
		after.remove_at(index)
	return after.is_empty()
