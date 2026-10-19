extends SceneTree
## Native production chase/HUD observations; fixture placement is disclosed.
const Main = preload("res://game/main.gd")
const VIEWS = [
	["spawn",Vector3(-22,0,28),0.0],
	["forward-left",Vector3(-22,4,-72),PI*.5],
	["climbing-lane",Vector3(-88,3.625,-68),PI*.5],
	["back-street-park-side",Vector3(-63,4,-80),0.0],
	["civic-park-mouth",Vector3(-35,6,-122),PI*.5],
	["park-civic-connector",Vector3(-70,6,-122),PI],
	["park-city-return",Vector3(-151,6,-80),-PI*.5],
	["park-lawn",Vector3(-187.137,8.22,-101.715),0.0],
	["station-west",Vector3(-125,2,30),PI*.5]]
var game: Node
var output: String
var records: Array = []
var errors: Array[String] = []
func _initialize()->void: _run.call_deferred()
func _run()->void:
	var args:=OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless" or args.size()!=1:quit(2);return
	output=args[0]
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.apply_settings({"graphics_quality":"balanced"},false)
	for spec:Array in VIEWS:
		var at:Vector3=spec[1]
		var ground:float=game.world.get_ground_height(at)
		game.skater.spawn_position=Vector3(at.x,ground+.8,at.z)
		game.start_mode(true)
		game.skater.rotation.y=spec[2]
		game.skater.set_controls_enabled(false)
		game.skater.reset_physics_interpolation()
		for frame:int in 100:await RenderingServer.frame_post_draw
		var camera:Camera3D=root.get_camera_3d()
		var samples:Array=[]
		var previous:=Time.get_ticks_usec()
		for frame:int in 120:
			await RenderingServer.frame_post_draw
			var now:=Time.get_ticks_usec()
			samples.append({"ms":float(now-previous)/1000.0,"draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"triangles":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"buffer_bytes":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
			previous=now
		var file_name:String=spec[0]+".png"
		if root.get_texture().get_image().save_png(output.path_join(file_name))!=OK:errors.append("save "+file_name)
		records.append({"id":spec[0],"initial":str(at),"actual":str(game.skater.global_position),"ground":ground,"floor":game.skater.is_on_floor(),"camera":str(camera.global_transform),"fov":camera.fov,"samples":samples})
		print("MAP_SURVEY ",spec[0]," actual=",game.skater.global_position," floor=",game.skater.is_on_floor())
	var probes:Array=[]
	for x:float in [-130,-110,-100,-94,-88,-70,-50,-42,-35]:
		for z:float in [-122,-108,-95,-86,-80,-74,-68,-55]:
			var p:=Vector3(x,0,z)
			var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*40,p-Vector3.UP*40,1,[game.skater.get_rid()])
			var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(ray)
			probes.append({"x":x,"z":z,"height_query":game.world.get_ground_height(p),"hit":str(hit.get("collider","")),"hit_y":float(hit.position.y) if not hit.is_empty() else null})
	game.process_mode=Node.PROCESS_MODE_DISABLED
	game.hud.visible=false
	var overview:=Camera3D.new()
	root.add_child(overview)
	overview.position=Vector3(-100,130,70)
	overview.look_at(Vector3(-110,0,-90))
	overview.far=700
	overview.make_current()
	for frame:int in 6:await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("overview.png"))
	var report:={"records":records,"probes":probes,"errors":errors,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),"os":OS.get_name(),"resolution":[1280,800],"limits":"Stationary declared fixtures, not ordinary input replay, human feel or ten-minute target performance. Readbacks excluded from sample intervals."}
	var file:=FileAccess.open(output.path_join("survey.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("RESULT: ",records.size()," captured, ",errors.size()," errors")
	quit(0 if errors.is_empty() else 1)
