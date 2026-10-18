extends SceneTree
## Production chase views plus a labelled authored overview; native scheduling.
const Independent=preload("res://tests/horizon_background_tests.gd")
const Main = preload("res://game/main.gd")
const Horizon = preload("res://game/levels/horizon_background.gd")
const EXTRA = [["clyde-river-west",Vector3(-25,3.4,90),PI*.5]]
const TIMED = ["clyde-river-west","exchange-east","civic-reported-gap","station-south","barras-reported-gap","park-west-slope","park-terrace-west","park-northwest-corner","park-northeast-corner","station-platform-axis","clyde-raised-deck","clyde-river-east","clyde-west-end","clyde-east-end","clyde-southeast-corner"]
const Quality = preload("res://game/core/graphics_quality.gd")
const VIEWS = preload("res://.local/horizon-background/views.gd").VIEWS
var passed_checks:int=0
var failed_checks:int=0
var game: Node
var output: String
var views: Array=[]
var errors: Array=[]
func _initialize()->void: _run.call_deferred()
func _run()->void:
	var args:=OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless" or args.size()!=1: quit(2);return
	output=args[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.apply_settings({"graphics_quality":"balanced"},false)
	await Independent.run(self,game.world,_check)
	print("RESULT: ",passed_checks," passed, ",failed_checks," failed")
	var workloads: Array=[]
	for row: Array in VIEWS.filter(func(v):return v[0] in ["station-south","barras-reported-gap","park-terrace-west","park-civic-connector"]):
		for phase: String in (["original-a","candidate","original-b"] if str(row[0]) in TIMED else ["candidate"]): workloads.append(row+[phase])
	for specification: Array in workloads:
		var phase: String=specification[3]
		Horizon.set_enabled(game.world,phase=="candidate")
		var at: Vector3=specification[1]
		var height: float=game.world.get_ground_height(at)
		if not is_finite(height): errors.append(str(specification[0])+" no support");continue
		game.skater.spawn_position=Vector3(at.x,(at.y if str(specification[0])=="clyde-raised-deck" else height)+.8,at.z)
		game.start_mode(true)
		game.skater.rotation.y=float(specification[2])
		game.skater.set_controls_enabled(false)
		game.skater.reset_physics_interpolation()
		var camera: Camera3D=root.get_camera_3d()
		var last:=camera.global_transform
		var stable:=0
		for warm: int in 48:
			await RenderingServer.frame_post_draw
			var current:=camera.global_transform
			var angle:=current.basis.get_rotation_quaternion().angle_to(last.basis.get_rotation_quaternion())
			stable=stable+1 if current.origin.distance_to(last.origin)<.02 and angle<.005 and game.skater.is_on_floor() and game.skater.velocity.length()<.05 else 0
			last=current
			if warm>=11 and stable>=3:break
		if stable<3: errors.append(str(specification[0])+" unsettled chase")
		var actual: Vector3=game.skater.global_position
		var expected_y: float=at.y if str(specification[0])=="clyde-raised-deck" else height
		var xz_error: float=Vector2(actual.x-at.x,actual.z-at.z).length()
		var query:=PhysicsRayQueryParameters3D.create(actual+Vector3.UP*.05,actual-Vector3.UP*.15,1,[game.skater.get_rid()])
		var contact: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(query)
		if xz_error>.15 or absf(actual.y-expected_y)>.1 or contact.is_empty(): errors.append(str(specification[0])+" wrong fixture layer/contact")
		var rows:Array=[]
		var previous:=Time.get_ticks_usec()
		for frame: int in 40:
			await RenderingServer.frame_post_draw
			var now:=Time.get_ticks_usec()
			rows.append({"ms":float(now-previous)/1000.0,
				"draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
				"primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
				"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
				"buffer_bytes":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),
				"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
			previous=now
		var file_name:=str(specification[0])+"-"+phase+".png"
		if root.get_texture().get_image().save_png(output.path_join(file_name))!=OK:errors.append(file_name+" save failed")
		views.append({"id":specification[0],"phase":phase,"fixture":_v(at),"actual_player":_v(game.skater.global_position),
			"initial_yaw":specification[2],"grounded":game.skater.is_on_floor(),"camera":str(camera.global_transform),
			"fov":camera.fov,"far":camera.far,"stable":stable,"ground_reference":expected_y,"xz_error":xz_error,"contact":str(contact.get("collider","")),"contact_y":float(contact.position.y) if not contact.is_empty() else null,"rows":rows,"image":file_name})
		print("HORIZON_CAPTURE ",specification[0]," ",phase," frames=",rows.size())
	Horizon.set_enabled(game.world,true)
	game.toggle_pause()
	game.hud.show_map()
	for frame: int in 5: await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("route-map.png"))
	game.hud.visible=false
	var overview:=Camera3D.new()
	root.add_child(overview)
	overview.position=Vector3(-40,155,235)
	overview.look_at(Vector3(-55,0,-55))
	overview.far=700
	overview.fov=68
	overview.make_current()
	for frame: int in 6: await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("authored-overview.png"))
	var result={"schema":1,"functional_counts":[passed_checks,failed_checks],"valid":errors.is_empty() and views.size()==10,"errors":errors,"views":views,
		"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"resolution":[1280,800],"quality":Quality.profile("balanced"),"native_render_loop":RenderingServer.render_loop_enabled,
		"limits":"4 candidate chase views;3 matched original/candidate/original triples.40 native samples each/10observations/400samples,12warmminimum; no readbacks in timings. Same-process controls retain candidate allocations; cold baseline/resource check separate. No moving-input/human/Mac claim."}
	var file:=FileAccess.open(output.path_join("capture.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")+"\n")
	print("HORIZON_CAPTURE_RESULT views=",views.size()," errors=",errors)
	quit(0 if result.valid else 1)
func _v(at:Vector3)->Array:return [at.x,at.y,at.z]

func _check(ok:bool,label:String)->void:
	if ok: passed_checks+=1;print("PASS: ",label)
	else: failed_checks+=1;errors.append(label);push_error("FAIL: "+label)
