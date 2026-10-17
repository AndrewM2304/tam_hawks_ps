extends SceneTree
const Main=preload("res://game/main.gd")
const Quality=preload("res://game/core/graphics_quality.gd")
const OUTPUT="res://.local/performance-capture/"
var game: Node
var errors:=0
var records:Array[Dictionary]=[]
func _initialize(): _run.call_deferred()
func _run():
	if DisplayServer.get_name()=="headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await _frames(30)
	game.toggle_pause()
	await _ready_menu()
	var settings:=_button(game.hud._dialog,"SETTINGS")
	_check(settings!=null,"actual pause exposes Settings")
	if settings==null: quit(1); return
	settings.grab_focus()
	await _frames(4)
	await _click(settings)
	await _ready_menu()
	var quality:=_quality_button(game.hud._dialog)
	_check(quality!=null,"actual settings exposes graphics choice")
	if quality==null: quit(1); return
	quality.grab_focus()
	await _frames(10)
	await _shot("settings-balanced",{"kind":"actual GUI","quality":game.career.settings.graphics_quality})
	for id:String in ["high","performance","balanced"]:
		await _click(quality)
		await _frames(4)
		_check(game.career.settings.graphics_quality==id,"native GUI click selects "+id)
	var size_slider: HSlider=game.hud._find_focus_token(game.hud._dialog,"setting:ui_scale")
	_check(size_slider!=null,"actual Settings exposes interface-size slider")
	if size_slider==null: quit(1); return
	size_slider.grab_focus()
	await _frames(4)
	for pressed:bool in [true,false]:
		var end:=InputEventKey.new()
		end.keycode=KEY_END
		end.pressed=pressed
		Input.parse_input_event(end)
		Input.flush_buffered_events()
		await _frames(2)
	_check(is_equal_approx(game.career.settings.ui_scale,1.4) and is_equal_approx(size_slider.value,1.4),"native slider input selects enlarged UI")
	await _frames(12)
	quality.grab_focus()
	await _frames(8)
	# Preserve existing focus while the viewport shrinks, matching a window resize.
	root.size=Vector2i(960,540)
	root.content_scale_size=root.size
	await _frames(12)
	_check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(quality.get_global_rect()) and game.hud._scroll.get_global_rect().encloses(quality.get_global_rect()),"focused quality control remains inside the resized scroll clip at enlarged UI")
	await _shot("settings-small-large-ui",{"kind":"actual GUI","ui_scale":1.4})
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	game.apply_settings({"ui_scale":1.0},false)
	game.start_mode(true)
	for fixture:Dictionary in [{"name":"spawn","at":game.world.get_spawn_position(),"heading":0.0},
			{"name":"park","at":game.world.get_district_checkpoints()["kelvingrove"],"heading":PI/4}]:
		for id:String in ["high","balanced","performance"]:
			game.apply_settings({"graphics_quality":id},false)
			var start: Vector3=fixture.at
			start.y=game.world.get_ground_height(start)+0.8
			game.skater.spawn_position=start
			game.skater.reset_skater()
			game.skater.rotation.y=fixture.heading
			await _frames(60)
			_check(game.skater.is_on_floor(),"supported quality fixture "+fixture.name+" "+id)
			await _shot(fixture.name+"-"+id,{"kind":"declared supported initial fixture; production chase","quality":id,
				"position":str(game.skater.global_position),"far":game.skater._camera.far,"fov":game.skater._camera.fov,
				"scale_3d":root.scaling_3d_scale,"msaa":root.msaa_3d,"shadow_distance":game.world.get_node("LateAfternoonSun").directional_shadow_max_distance})
	var file:=FileAccess.open(OUTPUT+"recipe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"errors":errors,"records":records,"persistence":false,"performance_measurement":false,
		"limits":"Actual GUI clicks and supported initial fixtures, production chase, fixed clock captures. Not Mac/FPS/human acceptance."},"\t")+"\n")
	print("PERFORMANCE CAPTURE errors=",errors," records=",records.size())
	quit(1 if errors else 0)
func _quality_button(node:Node)->Button:
	if node is Button and node.text.begins_with("GRAPHICS: "):return node
	for child:Node in node.get_children():
		var result:=_quality_button(child)
		if result!=null:return result
	return null
func _shot(label:String,fixture:Dictionary):
	RenderingServer.force_draw(true,1.0/60.0)
	var pixels:=root.get_texture().get_image()
	_check(pixels.save_png(OUTPUT+label+".png")==OK,"save "+label)
	records.append({"image":label+".png","resolution":[root.size.x,root.size.y],"fixture":fixture})

func _button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := _button(child, text)
		if found != null: return found
	return null


func _click(button: Button) -> void:
	var at := button.get_global_rect().get_center()
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).has_point(at), "Controls button is within the viewport before clicking")
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _frames(2)


func _ready_menu() -> void:
	for frame in 90:
		await process_frame
		if game.hud.is_menu_ready(): return
	_check(false, "modal reached settled native GUI focus within its bound")


func _frames(count: int) -> void:
	for frame in count: await process_frame


func _rect(value: Rect2) -> Array[float]:
	return [value.position.x, value.position.y, value.size.x, value.size.y]


func _check(value: bool, label: String) -> void:
	if not value:
		errors += 1
		push_error(label)
