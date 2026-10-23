extends SceneTree
const MainScene=preload("res://game/main.tscn")
var game:Node
var output:String
var images:Array=[]
func _initialize()->void:call_deferred('_run')
func _run()->void:
	if DisplayServer.get_name()=='headless' or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	game=MainScene.instantiate();game.persistence_enabled=false;root.add_child(game)
	for trial:Array in [[Vector2i(1280,800),1.0],[Vector2i(960,600),1.4],[Vector2i(640,480),1.4]]:
		root.size=trial[0];root.content_scale_size=trial[0]
		DisplayServer.window_set_size(trial[0])
		game.apply_settings({'ui_scale':trial[1],'graphics_quality':'balanced'},false)
		game.start_mode(false)
		for tick in 20:await physics_frame;await process_frame
		await RenderingServer.frame_post_draw
		var file:=output.path_join('hud-%dx%d-scale-%s.png'%[trial[0].x,trial[0].y,str(trial[1])])
		var picture:=root.get_texture().get_image();var code:=picture.save_png(file)
		images.append({'file':file,'width':picture.get_width(),'height':picture.get_height(),'error':code,'scale':trial[1]})
	FileAccess.open(output.path_join('images.json'),FileAccess.WRITE).store_string(JSON.stringify(images))
	var ok:=images.size()==3
	for row:Dictionary in images:ok=ok and row.error==OK
	print('RESULT: ',3 if ok else 0,' passed, ',0 if ok else 1,' failed');quit(0 if ok else 1)
