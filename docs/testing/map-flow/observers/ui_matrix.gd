extends SceneTree
## Keep the project's ordinary canvas_items stretch, unlike older probes that
## replaced content_scale_size with the physical window size.
const Main=preload("res://game/main.gd")
var game:Node
var output:String
var records:Array=[]
var failures:Array=[]
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var args:=OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless" or args.size()!=1:quit(2);return
	output=args[0]
	DirAccess.make_dir_recursive_absolute(output)
	game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	for size:Vector2i in [Vector2i(1280,720),Vector2i(1440,900),Vector2i(1920,1080),Vector2i(1280,800)]:
		DisplayServer.window_set_size(size)
		for scale:float in [1.0,1.4]:
			game.apply_settings({"ui_scale":scale},false)
			for frame:int in 60:await RenderingServer.frame_post_draw
			var visible:=root.get_visible_rect()
			var rectangles:Dictionary={}
			for key:String in ["_top","_goals","_speed_panel","_special_panel","_footer"]:
				var control:Control=game.hud.get(key)
				var rectangle:=control.get_global_rect()
				rectangles[key]=str(rectangle)
				if not visible.encloses(rectangle):failures.append(str(size)+" scale="+str(scale)+" clipped "+key)
			var label:="ui-%dx%d-%.1f"%[size.x,size.y,scale]
			var image:=root.get_texture().get_image()
			image.save_png(output.path_join(label+".png"))
			records.append({"requested":str(size),"actual_window":str(DisplayServer.window_get_size()),"viewport":str(root.size),"content_scale_size":str(root.content_scale_size),"visible_rect":str(visible),"scale":scale,"rectangles":rectangles,"image":label+".png","image_size":str(image.get_size())})
	var file:=FileAccess.open(output.path_join("matrix.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"records":records,"failures":failures,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),"limits":"Full viewport screenshots and rectangle checks, project stretch preserved; not external OS crop, all menu/stress states or physical controller acceptance."},"\t"))
	print("RESULT: ",records.size()," observations, ",failures.size()," clipped rectangles ",failures)
	quit(0 if failures.is_empty() else 1)
