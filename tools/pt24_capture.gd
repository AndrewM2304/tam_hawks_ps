extends SceneTree
## One bounded render of the owner's exact cameras, after deterministic checks.
## Static placement evidence; this does not certify temporal flicker or gameplay.
const Main = preload("res://game/main.gd")
const OUTPUT := "res://.local/pt24-capture/"
const EVIDENCE := "res://docs/testing/debug-session-2026-10-24/reports/"
var records: Array[Dictionary] = []
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("PT24 frames require a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	var before := _sources()
	var game := Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	# Initial construction has a valid pose before the first physical update.
	RenderingServer.force_draw(true,1.0/60.0)
	_shot("startup-before-physics",game.skater._camera)
	for i in 8:
		await physics_frame
		await process_frame
	game.playtest_recorder.base_directory=OUTPUT.path_join("recorder")
	if game.playtest_recorder.begin_session()!=OK: failures+=1
	paused=true
	for number: int in [4,6,10,11,14,15,17,19,21,22,30,31,36,38]:
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(EVIDENCE+"issue-%04d.json"%number))
		var skater: Node3D=game.skater
		skater.global_position=_vector(data.position)
		var forward := _vector(data.forward)
		skater.global_basis=Basis.looking_at(forward,Vector3.UP)
		game.skater._visual_rig.reset()
		skater.reset_physics_interpolation()
		var camera: Camera3D=game.skater._camera
		camera.global_position=_vector(data.camera.position)
		camera.look_at(camera.global_position+_vector(data.camera.forward),_vector(data.camera.up))
		camera.fov=float(data.camera.fov)
		camera.reset_physics_interpolation()
		game._refresh_hud()
		for i in 2: await process_frame
		RenderingServer.force_draw(true,1.0/60.0)
		_shot("issue-%04d"%number,camera)
	var after := _sources()
	if before!=after: failures+=1
	var manifest := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
		"source_stable":before==after,"source_sha256":after,"records":records,"failures":failures,
		"method":"Actual Main, no persistence. Initial frame before physics, then static owner player/camera placement. Two completed process frames before each native draw/readback. Not moving flicker, performance or input acceptance."}
	var file := FileAccess.open(OUTPUT+"manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("PT24_CAPTURE frames=%d failures=%d source_stable=%s"%[records.size(),failures,before==after])
	paused=false
	quit(1 if failures else 0)

func _shot(label: String,camera: Camera3D) -> void:
	var frame := root.get_texture().get_image()
	var result := frame.save_png(OUTPUT+label+".png")
	if result!=OK: failures+=1
	records.append({"file":label+".png","width":frame.get_width(),"height":frame.get_height(),
		"sha256":FileAccess.get_sha256(OUTPUT+label+".png"),"physics_frame":Engine.get_physics_frames(),
		"process_frame":Engine.get_process_frames(),"camera_position":[camera.global_position.x,camera.global_position.y,camera.global_position.z]})
	print("PT24_FRAME ",label)

func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]),float(value[1]),float(value[2]))

func _sources() -> Dictionary:
	var files := PackedStringArray(["res://project.godot","res://tools/pt24_capture.gd"])
	_collect("res://game",files)
	_collect("res://tests",files)
	files.sort()
	var result := {}
	for path: String in files: result[path]=FileAccess.get_sha256(path)
	return result

func _collect(path: String,files: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	for child: String in directory.get_files():
		if child.get_extension() in ["gd","gdshader","tscn","tres"]: files.append(path.path_join(child))
	for child: String in directory.get_directories(): _collect(path.path_join(child),files)
