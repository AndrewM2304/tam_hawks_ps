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
var saved_modes:Dictionary={}
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
	var ground_display:=game.world.get_node("HorizonContext/CityFootings") as MeshInstance3D
	var candidate_mesh:=ground_display.mesh
	var original_tool:=SurfaceTool.new()
	original_tool.create_from(candidate_mesh,0)
	var original_arrays:=candidate_mesh.surface_get_arrays(0)
	var base:Array=[]
	base.resize(Mesh.ARRAY_MAX)
	# Land is appended last after the original boundary/foundation vertices.
	for channel:int in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_COLOR,Mesh.ARRAY_TANGENT]:
		var removed:=72 if channel==Mesh.ARRAY_TANGENT else 18
		base[channel]=original_arrays[channel].slice(0,original_arrays[channel].size()-removed)
	var original_mesh:=ArrayMesh.new()
	original_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,base,[],{},candidate_mesh.surface_get_format(0)&Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
	print("MATCHED_FORMAT original=",original_mesh.surface_get_format(0)," candidate=",candidate_mesh.surface_get_format(0))
	if original_mesh.surface_get_format(0)!=candidate_mesh.surface_get_format(0):quit(2);return
	var workloads:Array=[]
	for source:Array in VIEWS:
		for phase:String in ["original-a","candidate","original-b"]:workloads.append(source+[phase])
	for spec:Array in workloads:
		ground_display.mesh=candidate_mesh if spec[3]=="candidate" else original_mesh
		var at:Vector3=spec[1]
		var ground:float=game.world.get_ground_height(at)
		if spec[3]=="original-a":
			for node:Node in saved_modes:node.process_mode=saved_modes[node]
			game.skater.set_process(true)
			game.skater.spawn_position=Vector3(at.x,ground+.8,at.z)
			game.start_mode(true)
			game.skater.rotation.y=spec[2]
			game.skater.set_controls_enabled(false)
			game.skater.reset_physics_interpolation()
			await create_timer(4.0).timeout
			for frame:int in 100:await RenderingServer.frame_post_draw
			game.skater.set_process(false)
			for node:Node in [game]+game.find_children("*","",true,false):
				if not saved_modes.has(node):saved_modes[node]=node.process_mode
				node.process_mode=Node.PROCESS_MODE_DISABLED
		await create_timer(2.0).timeout
		for warm:int in 100:await RenderingServer.frame_post_draw
		var camera:Camera3D=root.get_camera_3d()
		# Preallocate timing storage; avoid per-frame Dictionary allocation and
		# monitor queries contaminating the native frame intervals.
		var times:=PackedFloat64Array()
		times.resize(20000)
		var measured:=0
		var started:=Time.get_ticks_usec()
		var previous:=started
		while measured<times.size() and (Time.get_ticks_usec()-started<30000000 or measured<600):
			await RenderingServer.frame_post_draw
			var now:=Time.get_ticks_usec()
			times[measured]=float(now-previous)/1000.0
			measured+=1
			previous=now
		times.resize(measured)
		var counters:={"draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"triangles":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"buffer_bytes":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
		var samples:Array=[]
		for ms:float in times:
			var row:Dictionary=counters.duplicate()
			row.ms=ms
			samples.append(row)
		var file_name:String=spec[0]+"-"+spec[3]+".png"
		if root.get_texture().get_image().save_png(output.path_join(file_name))!=OK:errors.append("save "+file_name)
		records.append({"id":spec[0],"phase":spec[3],"initial":str(at),"actual":str(game.skater.global_position),"ground":ground,"floor":game.skater.is_on_floor(),"camera":str(camera.global_transform),"fov":camera.fov,"feedback_visible":game.hud._feedback_panel.visible,"feedback_modulate":str(game.hud._feedback_panel.modulate),"samples":samples})
		print("MAP_SURVEY ",spec[0]," actual=",game.skater.global_position," floor=",game.skater.is_on_floor())
	var probes:Array=[]
	for x:float in [-130,-110,-100,-94,-88,-70,-50,-42,-35]:
		for z:float in [-122,-108,-95,-86,-80,-74,-68,-55]:
			var p:=Vector3(x,0,z)
			var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*40,p-Vector3.UP*40,1,[game.skater.get_rid()])
			var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(ray)
			probes.append({"x":x,"z":z,"height_query":game.world.get_ground_height(p),"hit":str(hit.get("collider","")),"hit_y":float(hit.position.y) if not hit.is_empty() else null})
	ground_display.mesh=candidate_mesh
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
	var report:={"records":records,"probes":probes,"errors":errors,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),"os":OS.get_name(),"resolution":[1280,800],"limits":"Stationary production poses with all Main subtree process modes frozen equally across phases; not ordinary input replay, human feel or ten-minute target performance. Readbacks excluded from sample intervals."}
	var file:=FileAccess.open(output.path_join("survey.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("RESULT: ",records.size()," captured, ",errors.size()," errors")
	quit(0 if errors.is_empty() else 1)
