extends Node
## Normal scene entry with an isolated in-memory profile; no personal Music.
const Main = preload("res://game/main.gd")
var game: Node
var passed := 0
var failed := 0
var output := ""
var captures: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _check(ok: bool,label: String) -> void:
	if ok: passed += 1;print("PASS: ",label)
	else: failed += 1;push_error("FAIL: "+label)

func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func _key(code: Key,down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()

func _tap(code: Key) -> void:
	_key(code,true);await _frames(1);_key(code,false);await _frames(4)

func _capture(name_value: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	var path := output.path_join(name_value+".png")
	var actor_position: Vector3 = game.skater.get_global_transform_interpolated().origin
	var head_position: Vector3 = game.skater._visual_rig._head.get_global_transform_interpolated().origin
	var board_position: Vector3 = game.skater._board_visual.get_global_transform_interpolated().origin
	var camera_arm: float = game.skater._camera.global_position.distance_to(actor_position+Vector3.UP*1.05)
	var pixel_height: float = absf(game.skater._camera.unproject_position(head_position).y-game.skater._camera.unproject_position(board_position).y)
	if name_value=="normal-pushing":
		_check(camera_arm<12.0 and pixel_height>=70.0,"ordinary low-rate renderer retains a readable rider and bounded camera arm")
	_check(image.save_png(path)==OK and image.get_size()==Vector2i(1280,800),"native1280pixel capture "+name_value)
	var bytes := image.get_data()
	var hash := HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	captures.append({"file":path,"rgba_sha256":hash.finish().hex_encode(),"bytes":bytes.size(),
		"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames(),
		"camera":game.skater._camera.global_transform,"level_id":game.level_id,
		"actor_position":actor_position,"head_position":head_position,"board_position":board_position,
		"camera_arm_m":camera_arm,"rider_height_pixels":pixel_height})

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=1 or OS.get_cmdline_args().has("--script") or DisplayServer.get_name()=="headless":
		push_error("Merchant boot probe requires ordinary rendered scene entry and one output directory.")
		get_tree().quit(2);return
	output=args[0];DirAccess.make_dir_recursive_absolute(output)
	get_tree().root.size=Vector2i(1280,800);get_tree().root.content_scale_size=Vector2i(1280,800)
	game=Main.new();game.persistence_enabled=false;game.profile_path="user://merchant-normal-boot-fixture.json";game.legacy_profile_path=""
	add_child(game)
	await _frames(8)
	_check(game.paused and game.hud._page=="title" and game.hud.is_menu_ready(),"ordinary Main branch opens its visible focused title")
	_check(game.level_id=="merchant_neighbourhood_v1" and game.world.name=="MerchantDistrict","normal default constructs Merchant District")
	_check(not game.persistence_enabled and not game.music._persist and not game.music._can_control,"pre-tree profile isolation also disables personal Music")
	_check(game.world.get_node("MerchantArchitecture").report.errors.is_empty(),"whole-street native architecture reports no construction errors")
	_check(game.world.get_meta("merchant_surface_report").source_triangles==59920,"ordinary world applies exact photographic ground partition")
	await _capture("normal-title")
	await _tap(KEY_DOWN)
	_check(str(get_viewport().gui_get_focus_owner().get_meta("focus_token",""))=="FREE SKATE","actual Down focuses Free Skate")
	await _tap(KEY_ENTER)
	await _frames(30)
	_check(not game.paused and game.free_skate_mode and game.hud._page.is_empty(),"actual Enter starts Free Skate through release boundary")
	_check(game.skater.is_on_floor() and not game.skater.bailing and not game.skater.airborne and game.score.trick_history.is_empty(),"normal spawn settles without accidental tricks or bail")
	var before: Vector3=game.skater.global_position
	_key(KEY_W,true);await _frames(24);_key(KEY_W,false)
	_check(game.skater.global_position.distance_to(before)>.1 and not game.skater.bailing,"ordinary W input actually pushes across native paving")
	await _capture("normal-pushing")
	_check(not FileAccess.file_exists(game.profile_path) and not game.music._can_control,"normal title/play probe keeps profile and account isolation")
	var report:={"passed":passed,"failed":failed,"captures":captures,"level":game.level_id,
		"scope":"Ordinary rendered Main scene entry and parsed keyboard; isolated profile. Native stills, not physical-device/normal-speed/human/M5/performance acceptance."}
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	get_tree().paused=false;game.free();await get_tree().process_frame
	print("MERCHANT_NORMAL_BOOT: ",passed," passed, ",failed," failed")
	get_tree().quit(1 if failed else 0)
