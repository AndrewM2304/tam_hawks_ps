extends SceneTree
## Bounded shader-only diagnostic. Exact production water plane and daylight;
## no Main, rider, city geometry, save access or target-Mac performance claim.
const World = preload("res://game/levels/glasgow_square.gd")
const Outdoors = preload("res://game/levels/outdoor_routes.gd")
const BASELINE := "res://tools/fixtures/environment/clyde_water_before_2026_11_06.gdshader"
const BASELINE_SHA := "e60ac5cbafce8eaaca67ed1d44903ca6fe94329b4fd1c375306bba7dd9cc71f3"
const CANDIDATE := "res://game/art/assets/horizon/clyde_water.gdshader"
var _output := ""
var _checks := 0
var _failures := 0
var _camera: Camera3D
var _material: ShaderMaterial
var _before: Shader
var _candidate: Shader
var _cells: Array[Dictionary] = []
var _images: Array[Dictionary] = []
var _started := 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or DisplayServer.get_name() == "headless": quit(2); return
	_output = args[0]
	if not (ProjectSettings.globalize_path(_output).simplify_path()+"/").begins_with(ProjectSettings.globalize_path("res://.local/").simplify_path()+"/"):
		quit(2); return
	for argument: String in OS.get_cmdline_args():
		if argument in ["--fixed-fps", "--disable-render-loop"] or argument.begins_with("--fixed-fps="):
			quit(2); return
	_started = Time.get_ticks_usec()
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(640,400)
	root.content_scale_size = root.size
	_check(FileAccess.get_sha256(BASELINE) == BASELINE_SHA,"exact pre-change shader identity")
	# Invoke the actual production function without ever attaching the world:
	# its _ready() must not construct the whole city in this isolated workload.
	var lighting := World.new()
	lighting._build_lighting()
	for child: Node in lighting.get_children():
		lighting.remove_child(child)
		root.add_child(child)
	lighting.free()
	var outdoors := Outdoors.new()
	outdoors._water()
	root.add_child(outdoors)
	var water: MeshInstance3D = outdoors.get_node("ClydeWater")
	_material = water.material_override
	_candidate = _material.shader
	_check(_candidate == load(CANDIDATE),"exact production shader resource")
	_check(water.mesh is PlaneMesh and water.mesh.size == Outdoors.VISIBLE_WATER.size,
		"exact production 900 by38 metre water plane")
	_before = Shader.new()
	_before.code = FileAccess.get_file_as_string(BASELINE)
	_camera = Camera3D.new()
	_camera.fov = 68
	_camera.far = 1000
	root.add_child(_camera)
	_camera.current = true
	# Every completed phase is written outside timing samples. A timeout leaves
	# an explicitly incomplete report instead of discarding completed evidence.
	_write_report(false,"startup")
	for mode: String in ["before","candidate"]:
		_material.shader = _before if mode == "before" else _candidate
		for view: Dictionary in _views():
			_place(view)
			for frame: int in 3: await RenderingServer.frame_post_draw
			await process_frame
			await create_timer(0.0,true).timeout
			var tick := Engine.get_physics_frames()
			var process_tick := Engine.get_process_frames()
			await RenderingServer.frame_post_draw
			_check(tick == Engine.get_physics_frames() and process_tick == Engine.get_process_frames(),
				"preview readback stays in the selected natural frame")
			var image := root.get_texture().get_image()
			image.convert(Image.FORMAT_RGBA8)
			_check(image.get_width() == 640 and image.get_height() == 400,"actual isolated readback is640by400")
			var filename: String = mode+"-"+str(view.id)+".png"
			_check(image.save_png(_output.path_join(filename)) == OK,"lossless isolated preview saved")
			var hash := HashingContext.new()
			hash.start(HashingContext.HASH_SHA256)
			hash.update(image.get_data())
			_images.append({"file":filename,"mode":mode,"view":view.id,
				"rgba8_sha256":hash.finish().hex_encode(),"camera_position":_vector(_camera.global_position),
				"camera_forward":_vector(-_camera.global_basis.z),"fov":_camera.fov,"counters":_counters()})
			_write_report(false,"previews")
	for view: Dictionary in _views():
		_place(view)
		for mode: String in ["before-a","candidate","before-b"]:
			_material.shader = _candidate if mode == "candidate" else _before
			await _measure(str(view.id),mode)
			_write_report(false,"timing")
			if Time.get_ticks_usec()-_started > 110000000:
				_check(false,"isolated workload exceeded110second safety bound")
				_write_report(false,"time-bound")
				quit(1); return
	_material.shader = _candidate
	_check(_cells.size() == 9,"all nine declared isolated A/B/A cells completed")
	_write_report(true,"complete")
	print("ENVIRONMENT_WATER_ISOLATED_RESULT checks=",_checks," failures=",_failures," cells=",_cells.size())
	quit(1 if _failures else 0)

func _views() -> Array[Dictionary]:
	return [{"id":"river-oblique","at":Vector3(18,5,69),"target":Vector3(78,4,69)},
		{"id":"high-coverage","at":Vector3(0,7,80),"target":Vector3(0,-2,100)},
		{"id":"grazing","at":Vector3(0,-0.3,80),"target":Vector3(0,-2,116)}]

func _place(view: Dictionary) -> void:
	_camera.global_position = view.at
	_camera.look_at(view.target)

func _measure(view: String,mode: String) -> void:
	for frame: int in 8: await RenderingServer.frame_post_draw
	var samples: Array[Dictionary] = []
	var started := Time.get_ticks_usec()
	var previous := started
	while samples.size() < 48 or Time.get_ticks_usec()-started < 3000000:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var row := _counters()
		row.frame_ms = float(now-previous)/1000.0
		row.process_ms = Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
		samples.append(row)
		previous = now
		if now-started > 8000000: break
	_check(samples.size() >= 48,"at least48 natural samples within each bounded cell: "+view+"/"+mode)
	var summary := {"id":view,"mode":mode,"sample_count":samples.size(),"raw_samples":samples,
		"camera_position":_vector(_camera.global_position),"camera_forward":_vector(-_camera.global_basis.z)}
	for key: String in ["frame_ms","draws","visible_draws","shadow_draws","primitives","texture_bytes","buffer_bytes"]:
		var values: Array[float] = []
		for row: Dictionary in samples: values.append(float(row[key]))
		values.sort()
		for percentile: float in [0.5,0.95,0.99]:
			summary[key+"_p"+str(int(percentile*100))] = values[clampi(int(ceil(percentile*values.size()))-1,0,values.size()-1)]
	_cells.append(summary)
	print("ENVIRONMENT_WATER_ISOLATED_CELL view=",view," mode=",mode," samples=",samples.size()," p50_ms=",summary.frame_ms_p50," p95_ms=",summary.frame_ms_p95)

func _counters() -> Dictionary:
	return {"draws":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"visible_draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"shadow_draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"buffer_bytes":int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED))}

func _write_report(complete: bool,phase: String) -> void:
	var report := {"schema":1,"complete":complete,"phase":phase,"checks":_checks,"failures":_failures,
		"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(),"resolution":[root.size.x,root.size.y],
		"baseline_sha256":BASELINE_SHA,"candidate_sha256":FileAccess.get_sha256(CANDIDATE),
		"lighting_source":"GlasgowSquare._build_lighting() invoked directly, with no full-world _ready()",
		"geometry_source":"OutdoorRoutes._water() invoked directly: exact central production plane and material",
		"images":_images,"cost_brackets":_cells,"elapsed_seconds":float(Time.get_ticks_usec()-_started)/1000000.0,
		"limits":"Shader-only Linux software-renderer diagnostic at640x400. One exact production water plane and actual production daylight; no Main, rider, city geometry, Music, saves or game route. Nine cells: A/B/A at three fixed authored cameras, eight warm frames then at least48 natural frames and3seconds, with8second per-cell safety bound. Readbacks/storage outside timing samples. Native shader TIME active. This does not measure whole-world1080p cost, target-Mac performance or normal-speed gameplay water motion."}
	var file := FileAccess.open(_output.path_join("isolated-water-report.json"),FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	else: _check(false,"isolated report writable")

func _vector(value: Vector3) -> Array: return [value.x,value.y,value.z]

func _check(condition: bool,message: String) -> void:
	_checks += 1
	if condition: return
	_failures += 1
	push_error(message)
