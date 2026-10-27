extends SceneTree
## Actual Main location state and its normal map modal at two practice starts.
## No location label, HUD snapshot or world content flag is assigned.
const Main = preload("res://game/main.gd")
const SIZE := Vector2i(1280,800)
const OUTPUT := "res://.local/practice-location-captures"
var records: Array[Dictionary] = []
var failures := 0
var game: Node

func _initialize() -> void:_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name()=="headless":push_error("Practice location requires a native rendering display");quit(2);return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size=SIZE
	root.content_scale_size=SIZE
	_check(RenderingServer.render_loop_enabled,"normal rendering loop is enabled")
	_check(RenderingServer.get_current_rendering_method()=="gl_compatibility","native Compatibility renderer is active")
	var before := _sources()
	create_timer(180.0,true).timeout.connect(_timeout)
	for fixture: Dictionary in [
		{"name":"practice-quarter-map","position":Vector3(-85,6.08,-130),"heading":PI*.5},
		{"name":"practice-manual-pad-map","position":Vector3(-82,6.08,-135),"heading":PI*.5}]:
		paused=false
		for action: String in InputMap.get_actions():Input.action_release(action)
		game=Main.new()
		game.persistence_enabled=false
		_check(not game.has_meta("pt24_design_preview"),"fixture assigns no content override "+fixture.name)
		root.add_child(game)
		_check(not game.music._can_control and not game.music._persist and game.music._worker==null,
			"actual Main cannot control Music or access personal soundtrack preferences "+fixture.name)
		game.skater.spawn_position=fixture.position
		game.start_mode(true)
		game.skater.rotation.y=float(fixture.heading)
		for tick: int in 30:
			await physics_frame
			await process_frame
		var at: Vector3=game.skater.global_position
		var district: String=game.world.get_district_id(at)
		var location: String=game.world.get_location_name(at)
		var hud_location: String=String(game.hud._state.get("location",""))
		_check(bool(game.get_meta("pt24_design_preview",false)) and game.world.get_node_or_null("StationRailway")!=null
			and is_instance_valid(game.world._park_pond),"ordinary Main keeps merged trial content enabled "+fixture.name)
		_check(district=="kelvingrove" and location=="KELVINGROVE PARK" and hud_location==location,
			"public World and ordinary Main HUD agree on actual practice location "+fixture.name)
		# This is the production map-opening path. It pauses normal gameplay and
		# renders its own location description from Main's actual state.
		game.hud.show_map()
		for tick: int in 20:await process_frame
		await RenderingServer.frame_post_draw
		var text: String=game.hud._modal_details.text
		_check(game.hud._page=="map" and game.paused and paused
			and text.contains("You are in KELVINGROVE PARK") and game.hud._modal_details.is_visible_in_tree()
			and game.hud._dialog.modulate.a>.95,"real normal map modal visibly names Kelvingrove Park "+fixture.name)
		var image:=root.get_texture().get_image()
		var file: String=fixture.name+".png"
		_check(image.get_size()==SIZE and image.save_png(OUTPUT.path_join(file))==OK,
			"completed native viewport readback saved "+fixture.name)
		var ground: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(at+Vector3.UP*.2,at-Vector3.UP*.4,1))
		var camera: Camera3D=game.skater._camera
		records.append({"file":file,"sha256":FileAccess.get_sha256(OUTPUT.path_join(file)),"size":[SIZE.x,SIZE.y],
			"declared_spawn":_v(fixture.position),"actual_position":_v(at),"native_floor":game.skater.is_on_floor(),
			"native_hit":_v(ground.position) if not ground.is_empty() else null,"bailing":game.skater.bail_active,
			"district":district,"world_location":location,"actual_hud_location":hud_location,"visible_modal_text":text,
			"hud_page":game.hud._page,"ordinary_chase_position":_v(camera.global_position),"ordinary_chase_forward":_v(-camera.global_basis.z),
			"chase_camera_current":camera.is_current(),"warm_native_updates":30,"map_process_updates":20,
			"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
			"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
			"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
			"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames()})
		print("PRACTICE_LOCATION_FRAME ",fixture.name," district=",district," actual_location=",location," visible=",text)
		paused=false
		game.queue_free()
		await process_frame
		await physics_frame
		await process_frame
		game=null
	var after := _sources()
	_check(before==after,"complete game/capture sources stayed unchanged")
	_check(records.size()==2,"both declared practice-location frames were captured")
	var manifest := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),"size":[SIZE.x,SIZE.y],"frames":records,
		"failures":failures,"source_stable":before==after,"source_before":before,"source_after":after,
		"method":"Two independent declared initial starts on actual normal Main, persistence disabled before entering the tree and no content override. Each uses30 native updates with ordinary unmodified chase/HUD, then calls the production HUD.show_map path and allows20 normal UI process updates before completed frame_post_draw readback. Map description uses Main's real location state and World queries; no HUD snapshot/text or camera transform is assigned. Only initial spawn/facing differs. These are actual normal map-modal cue stills, not a route playthrough, temporal rendering or target-performance/Mac acceptance."}
	var report:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("PRACTICE_LOCATION_CAPTURE frames=",records.size()," failures=",failures," source_stable=",before==after)
	quit(1 if failures else 0)

func _check(condition: bool,label: String) -> void:
	if condition:print("PASS: ",label)
	else:failures+=1;print("FAIL: ",label)

func _sources() -> Dictionary:
	var paths:=PackedStringArray(["res://project.godot","res://.local/practice_location_capture.gd","res://.local/practice_location_capture.sh","res://tools/xorg-dummy.conf"])
	_collect("res://game",paths)
	paths.sort()
	var hashes: Dictionary={}
	for path: String in paths:hashes[path]=FileAccess.get_sha256(path)
	return hashes

func _collect(path: String,paths: PackedStringArray) -> void:
	var directory:=DirAccess.open(path)
	for file: String in directory.get_files():paths.append(path.path_join(file))
	for child: String in directory.get_directories():_collect(path.path_join(child),paths)

func _v(value: Vector3) -> Array:return [value.x,value.y,value.z]

func _timeout() -> void:
	push_error("Practice location capture exceeded its bounded deadline")
	quit(2)
