extends SceneTree
## Same-scene original-glass / shared-water / original-glass control sweeps.
## Cameras are labelled authored observations; this is not chase/play evidence.
const Main = preload("res://game/main.gd")
const Checks = preload("res://tests/fountain_finish_tests.gd")
const SIZE := Vector2i(960,640)
const OUTPUT := "res://.local/fountain-finish-captures"
const SAMPLES := 60
var passed := 0
var failed := 0
var records: Array[Dictionary] = []
var game: Node
var camera: Camera3D

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless": quit(2); return
	root.size = SIZE
	root.content_scale_size = SIZE
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	create_timer(240.0,true).timeout.connect(func(): push_error("Fountain capture exceeded bounded deadline"); quit(2))
	var before := _sources()
	game = Main.new()
	game.persistence_enabled = false
	_check(not game.has_meta("pt24_design_preview"),"actual Main receives no feature override")
	root.add_child(game)
	game.start_mode(true)
	game.apply_settings({"graphics_quality":"balanced"},false)
	for tick: int in 30:
		await physics_frame
		await process_frame
	_check(not game.music._can_control and not game.music._persist and game.music._worker == null,
		"actual Main has no personal Music control or preferences")
	_check(bool(game.get_meta("pt24_design_preview",false)) and is_instance_valid(game.world._park_pond)
		and game.world.get_node_or_null("StationRailway") != null,"ordinary Main retains all merged trial content")
	await Checks.run(self,game,_check)
	var water: MeshInstance3D = game.world.get_node("ExchangeFountain/FountainWater")
	var actual_water: Material = water.material_override
	var original_glass: Material = game.world._materials["glass"]
	# Freeze gameplay only after an ordinary Main start. The water shader's TIME
	# remains live; only the declared material override and authored camera vary.
	paused = true
	game.hud.visible = false
	camera = Camera3D.new()
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.near = .04
	camera.far = 220
	camera.fov = 55
	root.add_child(camera)
	camera.make_current()
	for view: String in ["overhead","low-rim"]:
		for phase: String in ["original-a","shared-water","original-b"]:
			water.material_override = actual_water if phase == "shared-water" else original_glass
			_place(view,0.0)
			for warm: int in 18: await RenderingServer.frame_post_draw
			var rows: Array[Dictionary] = []
			var previous := Time.get_ticks_usec()
			for sample: int in SAMPLES:
				_place(view,float(sample)/float(SAMPLES-1))
				await RenderingServer.frame_post_draw
				var now := Time.get_ticks_usec()
				rows.append({"ms":float(now-previous)/1000.0,
					"draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
					"primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
					"objects":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
					"total_draws":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
					"total_primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
					"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
					"buffer_bytes":int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),
					"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))})
				previous = now
			var name := view+"-"+phase+".png"
			var frame := root.get_texture().get_image()
			_check(frame.get_size() == SIZE and frame.save_png(OUTPUT.path_join(name)) == OK,
				"completed native viewport saved "+name)
			records.append({"view":view,"phase":phase,"image":name,"sha256":FileAccess.get_sha256(OUTPUT.path_join(name)),
				"size":[SIZE.x,SIZE.y],"camera_end":str(camera.global_transform),"camera_fov":camera.fov,
				"rows":rows,"material_same_as_river":water.material_override == game.world.get_node("OutdoorRoutes/ClydeWater").material_override,
				"source_water_material_id":actual_water.get_instance_id(),"applied_material_id":water.material_override.get_instance_id()})
			print("FOUNTAIN_CAPTURE ",view," ",phase," samples=",rows.size())
	water.material_override = actual_water
	_check(water.material_override == game.world.get_node("OutdoorRoutes/ClydeWater").material_override,
		"actual production water override restored after controls")
	_check(records.size() == 6,"both authored views retain all three A/B/A phases")
	var after := _sources()
	_check(before == after,"complete source inputs remained unchanged")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),"size":[SIZE.x,SIZE.y],
		"graphics_quality":"balanced","gameplay_paused":paused,"hud_hidden":not game.hud.visible,
		"shader_time_live":true,"views":records,"passed":passed,"failed":failed,
		"source_before":before,"source_after":after,"source_stable":before == after,
		"method":"One actual default-enabled Main; persistence false before tree entry, normal free-skate start and30 native updates. Pause gameplay/hide HUD only for clearly labelled authored world cameras. For each overhead/low-rim view:18 warm rendered frames, then60 identical slightly moving camera positions per A/B/A phase. A restores only the old generic glass material; B uses the actual shared Clyde/Pond material instance; A restores the same original glass again. All meshes, native bodies, lights, settings, actors, world state and resource identities remain fixed. Water shader TIME remains live. Samples are native frame_post_draw wall-clock intervals with visible draw/primitive and memory counters; Linux diagnostic only, no Mac/1080p/long-play acceptance or normal-chase claim."}
	var out := FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"\t")+"\n")
	out.close()
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)

func _place(view: String,t: float) -> void:
	if view == "overhead":
		camera.position = Vector3(1.2*t,17.5,10.1)
		camera.look_at(Vector3(.4*t,.55,10))
	else:
		var angle := lerpf(.68,.78,t)
		camera.position = Vector3(cos(angle)*10.5,2.6,10+sin(angle)*10.5)
		camera.look_at(Vector3(0,.6,10))
	camera.reset_physics_interpolation()

func _check(condition: bool,label: String) -> void:
	if condition: passed += 1; print("PASS: ",label)
	else: failed += 1; print("FAIL: ",label)

func _sources() -> Dictionary:
	var paths := PackedStringArray(["res://project.godot","res://.local/fountain_capture.gd","res://.local/fountain_capture.sh",
		"res://tests/fountain_finish_tests.gd","res://tools/xorg-dummy.conf"])
	_collect("res://game",paths)
	paths.sort()
	var hashes: Dictionary = {}
	for path: String in paths: hashes[path] = FileAccess.get_sha256(path)
	return hashes

func _collect(path: String,paths: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	for file: String in directory.get_files(): paths.append(path.path_join(file))
	for child: String in directory.get_directories(): _collect(path.path_join(child),paths)
