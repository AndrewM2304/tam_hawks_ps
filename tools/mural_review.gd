extends SceneTree
## Bounded real-renderer world-only diagnosis, composition and A/B/A cost check.
## Authored observer views are not a gameplay replay or target-hardware result.
const Murals = preload("res://game/levels/glasgow_murals.gd")
const World = preload("res://game/levels/glasgow_square.gd")
const VIEWS := [
 {"id":"exchange", "at":Vector3(-22,3.6,34), "target":Vector3(0,3,-12)},
 {"id":"george", "at":Vector3(0,7,-77), "target":Vector3(0,7,-118)},
 {"id":"station", "at":Vector3(-116,5.2,34), "target":Vector3(-116,5,53)},
 {"id":"barras", "at":Vector3(92,4,36), "target":Vector3(92,4,-18)},
 {"id":"clyde", "at":Vector3(94,5.6,53), "target":Vector3(94,3,78)},
 {"id":"park", "at":Vector3(-204,16,-185), "target":Vector3(-204,14,-242)},
 {"id":"heron", "at":Vector3(-62,7,-2), "target":Vector3(-47.018,7,-2)},
 {"id":"bloom", "at":Vector3(-92,7,-55), "target":Vector3(-81.718,6.9,-55)}]
const SAMPLES := 120

var world: Node3D
var camera: Camera3D
var output: String
var records: Array[Dictionary] = []
var errors := 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless" or args.size()!=1: quit(2); return
	output=ProjectSettings.globalize_path(args[0]).simplify_path()
	if not (output+"/").begins_with(ProjectSettings.globalize_path("res://.local/").simplify_path().trim_suffix("/")+"/"):
		quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(960,600)
	root.content_scale_size=root.size
	root.msaa_3d=Viewport.MSAA_DISABLED
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var construction_started := Time.get_ticks_usec()
	world=World.new()
	world.set_meta("arcade_murals_preview",true)
	root.add_child(world)
	world.process_mode=Node.PROCESS_MODE_DISABLED
	camera=Camera3D.new()
	camera.near=0.2
	camera.far=220
	camera.fov=68
	root.add_child(camera)
	camera.make_current()
	world.get_node("LateAfternoonSun").directional_shadow_max_distance=45
	var backdrop:Node3D=world.get_node_or_null("GlasgowMurals")
	if backdrop==null: push_error("Missing integrated murals");quit(1);return
	print("MURAL_READY construction_ms=", (Time.get_ticks_usec()-construction_started)/1000.0)
	# The only A/B/A difference is visibility of the new shadowless paint.
	for view:Dictionary in VIEWS:
		camera.position=view.at
		camera.look_at(view.target)
		for phase:String in ["before-a","murals","before-b"]:
			print("MURAL_PHASE_BEGIN ",view.id," ",phase)
			backdrop.visible=phase=="murals"
			for warm:int in 15: await RenderingServer.frame_post_draw
			var samples:Array[Dictionary]=[]
			var previous:=Time.get_ticks_usec()
			for sample:int in SAMPLES:
				await RenderingServer.frame_post_draw
				var now:=Time.get_ticks_usec()
				samples.append({"frame_ms":float(now-previous)/1000,
					"draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
					"primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
					"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
					"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC)})
				previous=now
			print("MURAL_PHASE_END ",view.id," ",phase," ",JSON.stringify(_summary(samples)))
			var label:String=view.id+"-"+phase
			if phase!="before-b":
				if root.get_texture().get_image().save_png(output+"/"+label+".png")!=OK:errors+=1
			records.append({"view":view.id,"phase":phase,"camera":str(camera.transform),"samples":samples,"summary":_summary(samples)})
	backdrop.visible=true
	for view: Dictionary in Murals.VIEWS:
		camera.position = view.camera
		camera.look_at(view.target)
		for warm: int in 3: await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(output+"/"+str(view.id)+".png") != OK: errors += 1
	var report:={"schema":2,"errors":errors,"explicit_preview_fixture":true,"normal_default_enabled":false,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),
		"renderer":RenderingServer.get_current_rendering_method(),"resolution":[960,600],"msaa":"off","camera_near":0.2,"camera_far":220,"fov":68,"shadows_m":45,
		"mural_budget":backdrop.get_meta("mural_report",{}),"records":records,
		"limits":"World-only authored stationary observers and camera perturbations, no HUD/player/input. Native frame scheduling, 120 measured frames per phase, readbacks excluded. Linux software rendering cannot certify Mac performance or human gameplay."}
	var file:=FileAccess.open(output+"/measurements.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("MURAL_REVIEW errors=",errors," views=",VIEWS.size()," measured_frames=",records.size()*SAMPLES)
	quit(1 if errors else 0)

func _summary(samples:Array[Dictionary])->Dictionary:
	var times:Array[float]=[]
	var long_frames:=0
	for sample:Dictionary in samples:
		times.append(sample.frame_ms)
		if sample.frame_ms>100:long_frames+=1
	times.sort()
	return {"p50_ms":times[ceili(times.size()*0.5)-1],"p95_ms":times[ceili(times.size()*0.95)-1],"p99_ms":times[ceili(times.size()*0.99)-1],
		"over_100ms":long_frames,"draws":samples[-1].draws,"primitives":samples[-1].primitives,"video_memory":samples[-1].video_memory,"static_memory":samples[-1].static_memory}
