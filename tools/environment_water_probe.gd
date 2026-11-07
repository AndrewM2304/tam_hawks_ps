extends "res://tools/full_fidelity_capture.gd"
## Source-bound native water inspection and three diagnostic A/B/A brackets.
## Readbacks never contribute to steady-loop timing samples.
const BASELINE := "res://tools/fixtures/environment/clyde_water_before_2026_11_06.gdshader"
const BASELINE_SHA := "e60ac5cbafce8eaaca67ed1d44903ca6fe94329b4fd1c375306bba7dd9cc71f3"
const CANDIDATE := "res://game/art/assets/horizon/clyde_water.gdshader"
var _water_material: ShaderMaterial
var _baseline_shader: Shader
var _candidate_shader: Shader
var _views: Array[Dictionary] = []
var _cells: Array[Dictionary] = []
var _sample_count := 48
var _minimum_seconds := 3.0
var _normal_quality := {}

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1 or DisplayServer.get_name() == "headless": quit(2); return
	output = arguments[0]
	if not (ProjectSettings.globalize_path(output).simplify_path() + "/").begins_with(ProjectSettings.globalize_path("res://.local/").simplify_path() + "/"):
		quit(2); return
	for argument: String in OS.get_cmdline_args():
		if argument in ["--fixed-fps", "--disable-render-loop"] or argument.begins_with("--fixed-fps="):
			quit(2); return
	_check(FileAccess.get_sha256(BASELINE) == BASELINE_SHA, "baseline is the exact pre-change source, not an approximation")
	DirAccess.make_dir_recursive_absolute(output)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(1280,800)
	root.content_scale_size = root.size
	RenderingServer.set_render_loop_enabled(false)
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	_check(not game.music._can_control and not game.music._persist, "probe isolates personal Music")
	game.start_mode(true)
	for tick in 40:
		await physics_frame
		await process_frame
	await create_timer(0.0,true).timeout
	_inspection = Camera3D.new()
	_inspection.name = "DeclaredEnvironmentWaterInspection"
	_inspection.fov = 68
	_inspection.far = 220
	game.add_child(_inspection)
	await _synchronization_probe()
	_inspection.fov = 68 # The shared synchronization fixture temporarily uses40.
	game.skater.set_controls_enabled(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	game.skater._camera.set_process(false)
	game.hud.visible = false
	_normal_quality = await _normal_quality_control()
	_write_report(false,"normal-quality-complete")
	# Exact2K control textures are local to the helper and must leave residency
	# before any water timing. Production1K normal bindings are restored there.
	RenderingServer.set_render_loop_enabled(true)
	for frame: int in 12: await RenderingServer.frame_post_draw
	RenderingServer.set_render_loop_enabled(false)
	_water_material = game.world.get_node("OutdoorRoutes/ClydeWater").material_override
	_check(game.world.get_node("ExchangeFountain/FountainWater").material_override == _water_material,
		"fountain retains the exact shared river material")
	_check(game.world._park_pond.get_node("PondWater").material_override == _water_material,
		"enabled park pond retains the exact shared river material")
	_candidate_shader = _water_material.shader
	_check(_candidate_shader == load(CANDIDATE), "candidate is the exact production shader resource")
	_baseline_shader = Shader.new()
	_baseline_shader.code = FileAccess.get_file_as_string(BASELINE)
	for mode: String in ["before", "candidate"]:
		_water_material.shader = _baseline_shader if mode == "before" else _candidate_shader
		for fixture: Dictionary in _fixtures():
			for sample: int in 8:
				# Identical one-metre camera approach. Native TIME remains active;
				# this sequence diagnoses water/aliasing, never traversal or feel.
				var travel: Vector3 = (fixture.target - fixture.at).normalized()
				_inspection.global_position = fixture.at + travel * float(sample) / 7.0
				_inspection.look_at(fixture.target)
				_inspection.current = true
				await process_frame
				await create_timer(0.0,true).timeout
				var image: Image = await _render_current_frame()
				var filename := "%s-%s-%02d.png" % [mode, fixture.id, sample]
				var stored := _store_frame(image,filename)
				_views.append({"mode":mode,"id":fixture.id,"sample":sample,"file":filename,"pixels":stored,
					"camera_position":_v(_inspection.global_position),"camera_fov":_inspection.fov,
					"wall_time_usec":Time.get_ticks_usec(),"native_counters":_counters()})
			_write_report(false,"water-snapshots")
	RenderingServer.set_render_loop_enabled(true)
	for repetition: int in 3:
		for fixture: Dictionary in _fixtures():
			_inspection.global_position = fixture.at
			_inspection.look_at(fixture.target)
			_inspection.current = true
			for mode: String in ["before-a", "candidate", "before-b"]:
				_water_material.shader = _candidate_shader if mode == "candidate" else _baseline_shader
				await _measure(repetition,fixture.id,mode)
				_write_report(false,"water-timing")
	_water_material.shader = _candidate_shader
	_write_report(true,"complete")
	print("ENVIRONMENT_WATER_RESULT checks=",checks," failures=",failures," images=",_views.size()," cost_cells=",_cells.size())
	quit(1 if failures else 0)

func _write_report(complete: bool,phase: String) -> void:
	var file := FileAccess.open(output.path_join("water-report.json"),FileAccess.WRITE)
	_check(file != null,"water report is writable")
	if file == null: return
	var report := {"schema":1,"complete":complete,"phase":phase,"checks":checks,"failures":failures,"engine":Engine.get_version_info(),
		"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),
		"resolution":[1280,800],"baseline_source":BASELINE,"baseline_sha256":BASELINE_SHA,
		"candidate_source":CANDIDATE,"candidate_sha256":FileAccess.get_sha256(CANDIDATE),
		"production_main":true,"profile_writes":game.persistence_enabled,"station_pond_enabled":game.world._station_railway!=null and game.world._park_pond!=null,
		"synchronization_proofs":_sync_proofs,"images":_views,"cost_brackets":_cells,
		"surface_allocation_control":"texture-report.json from the fresh native isolated allocation process; wrapper requires its budget/engine checks as well",
		"normal_quality_control":_normal_quality,
		"limits":"Linux software-renderer diagnostic, not target-Mac or human acceptance. Only the shared water shader changes inside this A/B/A test. Complete production world enabled; stationary player processing and HUD disabled equally in all cells. Authored eye-height cameras and analytic one-metre approaches are not gameplay routes. Native shader TIME remains active; phases are not pixel-identical. Normal render loop, unlimited FPS, three repeats at three views, eight warm frames then at least48frames/3seconds; screenshot/hash/storage costs excluded from all timing cells."}
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()

func _fixtures() -> Array[Dictionary]:
	return [{"id":"clyde-east","at":Vector3(18,5,69),"target":Vector3(78,4,69)},
		{"id":"fountain","at":game.world.get_node("ExchangeFountain").global_position+Vector3(5,2.5,6),"target":game.world.get_node("ExchangeFountain").global_position+Vector3(0,0.55,0)},
		{"id":"pond","at":Vector3(-173,3.5,-13),"target":Vector3(-184,0.12,-21)}]

func _normal_quality_control() -> Dictionary:
	const CONTROL := "res://.local/environment-fidelity/normal2k-control/manifest.json"
	if not FileAccess.file_exists(CONTROL):
		return {"requested":false,"limit":"No preserved exact2K import payloads; this water run cannot admit a normal-resolution change."}
	var controls: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTROL))
	var sources: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/assets/environment_pbr/manifest.json"))
	var groups := {"pavement_01":["paving","path"],"sandstone_blocks_04":["stone","stone_light","sandstone"],"asphalt_02":["asphalt"]}
	var originals := {}
	var reference := {}
	for asset: String in groups:
		var resource := "res://"+str(controls.maps[asset].compiled_snapshot)
		_check(controls.maps[asset].source_jpeg_sha256==sources.materials[asset].file_sha256.normal_opengl,
			"normal reference comes from the same retained photographic source: "+asset)
		_check(FileAccess.get_sha256(resource)==controls.maps[asset].compiled_sha256,"normal control retains exact2K compiled bytes: "+asset)
		reference[asset] = load(resource) as Texture2D
		_check(reference[asset]!=null and reference[asset].get_image().get_width()==2048,"normal reference native payload is actually2K: "+asset)
		for key: String in groups[asset]:
			originals[key] = game.world._materials[key].normal_texture
			_check(originals[key]!=null and originals[key].get_image().get_width()==1024,"production normal native payload is actually1K: "+key)
	var records: Array[Dictionary] = []
	for mode: String in ["2k-reference","1k-production"]:
		for asset: String in groups:
			for key: String in groups[asset]:
				game.world._materials[key].normal_texture = reference[asset] if mode=="2k-reference" else originals[key]
		for fixture: Dictionary in [
			{"id":"ordinary-chase"},
			{"id":"wall-eye","at":Vector3(-29,2,-2),"target":Vector3(-35,2.2,1),"fov":68.0},
			{"id":"paving-oblique","at":Vector3(-12,1.3,11),"target":Vector3(-8,0,17),"fov":58.0}]:
			if fixture.id=="ordinary-chase": game.skater._camera.current=true
			else:
				_inspection.global_position=fixture.at
				_inspection.look_at(fixture.target)
				_inspection.fov=fixture.fov
				_inspection.current=true
			await process_frame
			await create_timer(0.0,true).timeout
			var image: Image = await _render_current_frame()
			var filename: String = "normals-"+mode+"-"+str(fixture.id)+".png"
			var pixels := _store_frame(image,filename)
			var camera: Camera3D = root.get_camera_3d()
			records.append({"mode":mode,"id":fixture.id,"file":filename,"pixels":pixels,
				"camera_position":_v(camera.global_position),"camera_forward":_v(-camera.global_basis.z),"camera_fov":camera.fov,
				"player_position":_v(game.skater.global_position),"native_counters":_counters()})
	for key: String in originals: game.world._materials[key].normal_texture=originals[key]
	_inspection.fov=68
	return {"requested":true,"reference_receipt":CONTROL,"reference_receipt_sha256":FileAccess.get_sha256(CONTROL),
		"controls":controls,"frames":records,"limit":"Only three normal-map resource resolutions change. Albedo remains2K, all surface parameters/light/geometry and player pose stay identical. Ordinary chase uses its actual settled native camera with processing frozen; two authored close cameras are labelled. Native world TIME remains active, so incidental animated background/water can differ. Reference2K maps are released after this helper and before water cost brackets."}

func _counters() -> Dictionary:
	return {"draws":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"visible_draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"shadow_draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"buffer_bytes":int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED))}

func _measure(repetition: int,id: String,mode: String) -> void:
	for frame: int in 8: await RenderingServer.frame_post_draw
	var samples: Array[Dictionary] = []
	var started := Time.get_ticks_usec()
	var previous := started
	while samples.size() < _sample_count or Time.get_ticks_usec() - started < _minimum_seconds * 1000000:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var row := _counters()
		row.frame_ms = float(now - previous) / 1000.0
		row.process_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		samples.append(row)
		previous = now
	var summary := {"repetition":repetition,"id":id,"mode":mode,"sample_count":samples.size(),"raw_samples":samples}
	for key: String in ["frame_ms","draws","primitives","texture_bytes","buffer_bytes","visible_draws","shadow_draws"]:
		var values: Array[float] = []
		for row: Dictionary in samples: values.append(float(row[key]))
		values.sort()
		for percentile: float in [0.5,0.95,0.99]:
			summary[key+"_p"+str(int(percentile*100))] = values[clampi(int(ceil(percentile*values.size()))-1,0,values.size()-1)]
	_cells.append(summary)
	print("ENVIRONMENT_WATER_CELL repeat=",repetition," view=",id," mode=",mode," p50_ms=",summary.frame_ms_p50," p95_ms=",summary.frame_ms_p95)
