extends SceneTree
## Bounded real-renderer world-only diagnosis, composition and A/B/A cost check.
## Authored observer views are not a gameplay replay or target-hardware result.
const World = preload("res://game/levels/glasgow_square.gd")
const VIEWS := [
	{"id":"station-edge", "at":Vector3(-116,5.2,34), "target":Vector3(-116,5,53)},
	{"id":"station-canopy", "at":Vector3(-102,4.7,-3), "target":Vector3(-90,5,36)},
	{"id":"clyde-approach", "at":Vector3(94,5.6,53), "target":Vector3(94,3,78)},
	{"id":"clyde-east-end", "at":Vector3(132,5.4,70), "target":Vector3(200,4,90)},
	{"id":"clyde-west-end", "at":Vector3(-132,5.4,70), "target":Vector3(-200,4,90)},
	{"id":"park-north", "at":Vector3(-204,16,-185), "target":Vector3(-204,14,-242)}]
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
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	root.msaa_3d=Viewport.MSAA_2X
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	world=World.new()
	world.set_meta("render_repair_backdrop_preview",true)
	root.add_child(world)
	world.process_mode=Node.PROCESS_MODE_DISABLED
	camera=Camera3D.new()
	camera.near=0.2
	camera.far=220
	camera.fov=68
	root.add_child(camera)
	camera.make_current()
	world.get_node("LateAfternoonSun").directional_shadow_max_distance=45
	var backdrop:Node3D=world.get_node_or_null("CityBackdrop")
	if backdrop==null: push_error("Missing integrated backdrop");quit(1);return
	# The only A/B/A difference is visibility of the new shadowless scenery.
	for view:Dictionary in VIEWS:
		camera.position=view.at
		camera.look_at(view.target)
		for phase:String in ["before-a","backdrop","before-b"]:
			backdrop.visible=phase=="backdrop"
			for warm:int in 5: await RenderingServer.frame_post_draw
			var samples:Array[Dictionary]=[]
			var previous:=Time.get_ticks_usec()
			for sample:int in 24:
				await RenderingServer.frame_post_draw
				var now:=Time.get_ticks_usec()
				samples.append({"frame_ms":float(now-previous)/1000,
					"draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
					"primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
					"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
					"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC)})
				previous=now
			var label:String=view.id+"-"+phase
			if phase!="before-b":
				if root.get_texture().get_image().save_png(output+"/"+label+".png")!=OK:errors+=1
			records.append({"view":view.id,"phase":phase,"camera":str(camera.transform),"samples":samples,"summary":_summary(samples)})
	backdrop.visible=true
	# Same camera perturbations over each former coplanar road/quay overlap.
	# Road-hidden control isolates the disputed material without touching physics.
	for side:int in [-1,1]:
		var road:Node3D=world.get_node("OutdoorRoutes/Clyde%sApproach"%("West" if side<0 else "East"))
		var road_visual:MeshInstance3D
		for child:Node in road.get_children():
			if child is MeshInstance3D:road_visual=child
		for pose:int in 4:
			camera.position=Vector3(side*94+pose*0.11,5.6,53+pose*0.17)
			camera.look_at(camera.position+Vector3(0,-2.6,8))
			for control:bool in [false,true]:
				road_visual.visible=not control
				for warm:int in 2:await RenderingServer.frame_post_draw
				var label:="seam-%s-%d-%s"%["west" if side<0 else "east",pose,"control" if control else "fixed"]
				if root.get_texture().get_image().save_png(output+"/"+label+".png")!=OK:errors+=1
			road_visual.visible=true
	var report:={"schema":1,"errors":errors,"explicit_preview_fixture":true,"normal_default_enabled":false,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),
		"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1280,800],"msaa":"2x","camera_near":0.2,"camera_far":220,"fov":68,"shadows_m":45,
		"backdrop_budget":backdrop.get_meta("backdrop_report",{}),"records":records,
		"limits":"World-only authored stationary observers and camera perturbations, no HUD/player/input. Native frame scheduling, 24 measured frames per phase, readbacks excluded. Linux software rendering cannot certify Mac performance or human gameplay."}
	var file:=FileAccess.open(output+"/measurements.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("RENDER_REPAIR_CAPTURE errors=",errors," views=",VIEWS.size()," measured_frames=",records.size()*24)
	quit(1 if errors else 0)

func _summary(samples:Array[Dictionary])->Dictionary:
	var times:Array[float]=[]
	var long_frames:=0
	for sample:Dictionary in samples:
		times.append(sample.frame_ms)
		if sample.frame_ms>100:long_frames+=1
	times.sort()
	return {"p50_ms":times[ceili(times.size()*0.5)-1],"p95_ms":times[ceili(times.size()*0.95)-1],"p99_ms":times[-1],
		"over_100ms":long_frames,"draws":samples[-1].draws,"primitives":samples[-1].primitives,"video_memory":samples[-1].video_memory,"static_memory":samples[-1].static_memory}
