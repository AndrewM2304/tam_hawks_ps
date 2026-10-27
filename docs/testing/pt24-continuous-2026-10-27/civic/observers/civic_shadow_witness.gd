extends SceneTree
## Bounded source-bound rendering diagnostic at the two omitted owner cameras.
## Authored camera movement is not a played route or target-Mac acceptance.
const Main = preload("res://game/main.gd")
const SIZE := Vector2i(1440,900)
const REPORTS := "res://docs/testing/debug-session-2026-10-24/reports/"
const STATIONARY_FRAMES := 6
const MOVING_FRAMES := 12
var mode := "normal"
var output := "res://.local/civic-shadow-witness/normal"
var passed := 0
var failed := 0
var camera: Camera3D
var records: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Civic shadow witness needs an actual rendering display")
		quit(2)
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--output="):output=argument.trim_prefix("--output=")
	if mode not in ["normal","sun-shadow-off-diagnostic"]:
		quit(2)
		return
	root.size=SIZE
	root.content_scale_size=SIZE
	create_timer(150.0,true).timeout.connect(func():push_error("Bounded civic shadow witness timed out");quit(2))
	var before:=_sources()
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"civic shadow: local output available")
	var game:=Main.new()
	game.persistence_enabled=false
	_check(not game.has_meta("pt24_design_preview"),"civic shadow: ordinary Main has no feature override before entry")
	root.add_child(game)
	game.start_mode(true)
	game.apply_settings({"graphics_quality":"balanced"},false)
	for tick: int in 12:
		await physics_frame
		await process_frame
	_check(bool(game.get_meta("pt24_design_preview",false)) and bool(game.world.get_meta("pt24_design_preview",false)),
		"civic shadow: ordinary Main enables all merged trial features")
	_check(not game.persistence_enabled and not game.music._can_control and not game.music._persist and game.music._worker==null,
		"civic shadow: profile and personal Music remain isolated")
	game.toggle_pause()
	game.hud.visible=false
	_check(paused and game.paused,"civic shadow: only camera moves while native gameplay is paused")
	var body_before:=_body(game)
	var sun: DirectionalLight3D=game.world.get_node("LateAfternoonSun")
	var original_sun:=_sun(sun)
	_check(sun.shadow_enabled,"civic shadow: normal source retains directional shadows")
	if mode=="sun-shadow-off-diagnostic":sun.shadow_enabled=false
	camera=Camera3D.new()
	camera.process_mode=Node.PROCESS_MODE_ALWAYS
	camera.near=game.skater._camera.near
	camera.far=game.skater._camera.far
	root.add_child(camera)
	camera.make_current()
	for number: int in [2,3]:
		var source_path:=REPORTS+"issue-%04d.json"%number
		var issue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_path))
		_check(Vector2i(int(issue.viewport[0]),int(issue.viewport[1]))==SIZE,
			"civic shadow: original owner viewport matches the diagnostic %d"%number)
		var position:=_vector(issue.camera.position)
		var forward:=_vector(issue.camera.forward)
		var up:=_vector(issue.camera.up)
		var travel:=Vector3(forward.x,0.0,forward.z).normalized()
		_place(position,forward,up,float(issue.camera.fov))
		for warm: int in 6:await RenderingServer.frame_post_draw
		for phase: String in ["stationary","moving"]:
			var count: int=STATIONARY_FRAMES if phase=="stationary" else MOVING_FRAMES
			var rows: Array[Dictionary]=[]
			for sample: int in count:
				var distance:=0.0 if phase=="stationary" else float(sample)/float(count-1)
				_place(position+travel*distance,forward,up,float(issue.camera.fov))
				var requested:=Time.get_ticks_usec()
				await RenderingServer.frame_post_draw
				var completed:=Time.get_ticks_usec()
				var row: Dictionary={"sample":sample,"distance_m":distance,"camera":_camera(),
					"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),
					"wait_to_completed_draw_ms":float(completed-requested)/1000.0,
					"draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
					"primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
					"objects":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
					"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
					"buffer_bytes":int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),
					"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))}
				var image:=root.get_texture().get_image()
				var filename:="issue-%04d-%s-%02d.png"%[number,phase,sample]
				_check(image.get_size()==SIZE and image.save_png(output.path_join(filename))==OK,
					"civic shadow: completed native frame "+filename)
				row.image=filename
				row.image_sha256=FileAccess.get_sha256(output.path_join(filename))
				rows.append(row)
			_check(rows.size()==count and _vector(rows[0].camera.position)==position,
				"civic shadow: exact owner first camera for %d %s"%[number,phase])
			_check(phase!="moving" or is_equal_approx(rows[-1].distance_m,1.0),
				"civic shadow: bounded one-metre camera sequence %d %s"%[number,phase])
			records.append({"witness":number,"note":issue.note,"source_report":source_path,
				"source_report_sha256":FileAccess.get_sha256(source_path),"phase":phase,"rows":rows})
	_check(_body(game)==body_before,"civic shadow: rendered observation preserves frozen actor and score")
	_check(not game.music._can_control and not game.music._persist and game.music._worker==null,
		"civic shadow: rendering never starts personal Music work")
	var after:=_sources()
	_check(before==after,"civic shadow: all observer/source/report inputs remain frozen")
	var report: Dictionary={"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),"size":[SIZE.x,SIZE.y],
		"mode":mode,"source_before":before,"source_after":after,"source_stable":before==after,
		"passed":passed,"failed":failed,"records":records,"sun_before":original_sun,"sun_observed":_sun(sun),
		"viewport":{"scaling_3d_scale":root.scaling_3d_scale,"msaa_3d":root.msaa_3d,"occlusion":root.use_occlusion_culling},
		"method":"Ordinary default-on Main, persistence disabled before tree entry, Balanced settings, 12 normal setup ticks; native gameplay then paused and HUD hidden. Each exact owner camera warms six draws, observes six stationary and twelve one-metre moving completed native frames. Camera movement is authored; no gameplay input, played route, normal chase, frame-time, target-Mac, final temporal or human acceptance is claimed. Draw-wait intervals exclude the following PNG write but are observer scheduling measurements, not frame times. Optional shadow-off mode changes only this diagnostic process's directional shadow_enabled value; it is never a proposed production fix. No entire repair helper is bypassed."}
	var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	if file==null:
		push_error("Cannot write civic shadow manifest")
		quit(2)
		return
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()
	print("CIVIC_SHADOW_WITNESS ",{"mode":mode,"witnesses":[2,3],"frames":36,"output":output,"source_stable":before==after})
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)

func _place(position: Vector3,forward: Vector3,up: Vector3,fov: float) -> void:
	camera.global_position=position
	camera.look_at(position+forward,up)
	camera.fov=fov
	camera.reset_physics_interpolation()

func _camera() -> Dictionary:
	return {"position":_array(camera.global_position),"forward":_array(-camera.global_basis.z),
		"up":_array(camera.global_basis.y),"fov":camera.fov,"near":camera.near,"far":camera.far}

func _body(game: Node) -> Dictionary:
	return {"transform":game.skater.global_transform,"velocity":game.skater.velocity,"speed":game.skater.speed,
		"score":game.score.total_score,"combo":game.score.get_combo_value(),"time":game.time_remaining}

func _sun(sun: DirectionalLight3D) -> Dictionary:
	return {"transform":str(sun.global_transform),"shadow_enabled":sun.shadow_enabled,
		"shadow_mode":sun.directional_shadow_mode,"shadow_distance":sun.directional_shadow_max_distance,
		"bias":sun.shadow_bias,"normal_bias":sun.shadow_normal_bias,"energy":sun.light_energy}

func _vector(value: Array) -> Vector3:return Vector3(float(value[0]),float(value[1]),float(value[2]))
func _array(value: Vector3) -> Array:return [value.x,value.y,value.z]

func _check(value: bool,label: String) -> void:
	if value:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)

func _sources() -> Dictionary:
	var files:=PackedStringArray(["res://project.godot","res://.local/civic_shadow_witness.gd",
		"res://.local/civic_shadow_witness.sh",REPORTS+"issue-0002.json",REPORTS+"issue-0003.json"])
	for directory: String in ["res://game","res://tests","res://tools"]:_collect(directory,files)
	files.sort()
	var result: Dictionary={}
	for path: String in files:result[path]=FileAccess.get_sha256(path)
	return result

func _collect(path: String,files: PackedStringArray) -> void:
	var directory:=DirAccess.open(path)
	for filename: String in directory.get_files():files.append(path.path_join(filename))
	for child: String in directory.get_directories():
		if child!="__pycache__":_collect(path.path_join(child),files)
