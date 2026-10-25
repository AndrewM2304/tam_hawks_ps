extends SceneTree
## Bounded matched world-camera evidence at the owner's exact flicker witnesses.
## Analytic camera motion is a rendering diagnostic, never input/feel acceptance.
const World = preload("res://game/levels/glasgow_square.gd")
const EVIDENCE := "res://docs/testing/debug-session-2026-10-24/reports/"
var _output := "res://.local/pt24-temporal/after"
var _baseline := false
var _numbers: Array[int] = [2,3,5,16,17,18,20,29,35]
var _samples := 8
var _records: Array[Dictionary] = []
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PT24 temporal evidence requires an actual rendering display")
		quit(2)
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--baseline":_baseline = true
		elif argument.begins_with("--output="):_output = argument.trim_prefix("--output=")
		elif argument.begins_with("--witness="):
			_numbers.clear()
			for number: String in argument.trim_prefix("--witness=").split(","):
				_numbers.append(number.to_int())
		elif argument.begins_with("--samples="):_samples = clampi(argument.trim_prefix("--samples=").to_int(),3,16)
	DirAccess.make_dir_recursive_absolute(_output)
	root.size = Vector2i(1280,800)
	root.content_scale_size = root.size
	root.msaa_3d = Viewport.MSAA_2X
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	var before := _sources()
	var world := World.new()
	world.set_meta("pt24_render_repairs_baseline",_baseline)
	root.add_child(world)
	var camera := Camera3D.new()
	camera.far = 220.0
	camera.current = true
	root.add_child(camera)
	for index: int in 2:
		await physics_frame
		await process_frame
	paused = true
	for number: int in _numbers:
		var path := EVIDENCE + "issue-%04d.json"%number
		if not FileAccess.file_exists(path):
			_failures += 1
			continue
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var position := _vector(data.camera.position)
		var forward := _vector(data.camera.forward)
		var up := _vector(data.camera.up)
		var travel := Vector3(forward.x,0,forward.z).normalized()
		for sample: int in _samples:
			# Identical bounded one-metre approach per source/mode. The owner's
			# exact camera is the first frame; geometry and simulation stay frozen.
			camera.global_position = position + travel * float(sample)/float(_samples-1)
			camera.look_at(camera.global_position+forward,up)
			camera.fov = float(data.camera.fov)
			camera.reset_physics_interpolation()
			await process_frame
			await process_frame
			RenderingServer.force_draw(true,1.0/60.0)
			var image := root.get_texture().get_image()
			var file := "issue-%04d-%02d.png"%[number,sample]
			if image.save_png(_output.path_join(file)) != OK:_failures += 1
			_records.append({"witness":number,"sample":sample,"file":file,
				"camera_position":[camera.global_position.x,camera.global_position.y,camera.global_position.z],
				"image_sha256":FileAccess.get_sha256(_output.path_join(file)),
				"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
				"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
				"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
				"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames()})
	var after := _sources()
	if before != after:_failures += 1
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
		"baseline_display":_baseline,"source_stable":before==after,"source_sha256":after,
		"records":_records,"failures":_failures,"size":[1280,800],"quality":"Balanced-equivalent PCF/MSAA/far",
		"repairs":world.get_meta("pt24_render_repairs",{}),
		"method":"World-only analytic owner-camera approach, paused simulation, actual completed native readbacks. No rider/HUD/input fixture. Global renderer/shadow quality settings are identical in both modes; baseline skips the complete PT24 render-repair helper, including all of its display repairs. Images/readbacks are not frame-time or target-Mac acceptance."}
	var output := FileAccess.open(_output.path_join("manifest.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t")+"\n")
	print("PT24_TEMPORAL frames=%d failures=%d baseline=%s source_stable=%s"%[_records.size(),_failures,_baseline,before==after])
	paused = false
	quit(1 if _failures else 0)


func _vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]),float(raw[1]),float(raw[2]))


func _sources() -> Dictionary:
	var paths := PackedStringArray(["res://project.godot","res://tools/pt24_temporal_probe.gd"])
	_collect("res://game",paths)
	paths.sort()
	var hashes := {}
	for path: String in paths:hashes[path] = FileAccess.get_sha256(path)
	return hashes


func _collect(path: String, paths: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	for child: String in directory.get_files():
		if child.get_extension() in ["gd","gdshader","tscn","tres"]:paths.append(path.path_join(child))
	for child: String in directory.get_directories():_collect(path.path_join(child),paths)
