extends SceneTree
## Actual production recorder captures; independent completed-draw readbacks.
const Main = preload("res://game/main.gd")
const Recorder = preload("res://game/core/playtest_recorder.gd")
const SIZE := Vector2i(1440,900)
const OUTPUT := "res://.local/recorder-display-witness"
var game: Node
var recorder: CanvasLayer
var draws: Dictionary = {}
var records: Array[Dictionary] = []
var passed := 0
var failed := 0

func _initialize() -> void:_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	root.size=SIZE;root.content_scale_size=SIZE
	create_timer(85.0,true).timeout.connect(func():push_error("Recorder display witness timed out");quit(2))
	_check(DirAccess.make_dir_recursive_absolute(OUTPUT)==OK,"recorder display: isolated local evidence directory")
	game=Main.new();game.persistence_enabled=false;root.add_child(game)
	game.start_mode(true);game.apply_settings({"graphics_quality":"balanced"},false)
	recorder=game.playtest_recorder;recorder.base_directory=OUTPUT.path_join("session")
	for tick: int in 12:await physics_frame;await process_frame
	_check(not game.persistence_enabled and not game.music._can_control and not game.music._persist and game.music._worker==null,
		"recorder display: personal save and Music disabled before ordinary Main entry")
	_check(bool(game.get_meta("pt24_design_preview",false)) and not recorder.active and not game.paused,
		"recorder display: ordinary default-on play with inactive recorder")
	var start: Vector3=game.skater.global_position
	_check(recorder.begin_session()==OK,"recorder display: production local recorder session starts")
	_key(KEY_W,true)
	for tick: int in 6:await physics_frame;await process_frame
	_key(KEY_W,false)
	for tick: int in 2:await physics_frame;await process_frame
	_check(game.skater.global_position.distance_to(start)>0.01 and recorder.inputs.size()>=2,
		"recorder display: real input events move ordinary skater and record press/release")
	RenderingServer.frame_post_draw.connect(_draw_witness)
	await _capture("live",false)
	game.toggle_pause()
	_check(game.paused and paused and game.hud._modal.visible,"recorder display: ordinary pause menu before second capture")
	await _capture("paused",true)
	_check(game.paused and paused and game.hud._modal.visible,"recorder display: capture restores original paused menu")
	_check(recorder.finish_session()==OK,"recorder display: normal recorder creates completed ZIP")
	var zip:=ZIPReader.new()
	var opened:=zip.open(recorder.archive_path)
	_check(opened==OK and zip.get_files().has("issue-0001.png") and zip.get_files().has("issue-0002.json"),
		"recorder display: readable ZIP contains actual PNG and JSON pairs")
	if opened==OK:
		var manifest: Dictionary=JSON.parse_string(zip.read_file("session.json").get_string_from_utf8())
		_check(manifest.format==2 and not manifest.active and manifest.reports.size()==2,"recorder display: persisted completed manifest matches both captures")
		zip.close()
	_check(not game.music._can_control and not game.music._persist and game.music._worker==null,
		"recorder display: capture and ZIP never start personal Music work")
	RenderingServer.frame_post_draw.disconnect(_draw_witness)
	var manifest: Dictionary={"passed":passed,"failed":failed,"records":records,"session":recorder.session_dir,
		"archive":recorder.archive_path,"archive_sha256":FileAccess.get_sha256(recorder.archive_path),
		"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_video_adapter_name(),
		"method":"Ordinary default-on Main with persistence false before tree entry. Production recorder runs via normal physical-key events after six genuine Push ticks. Two actual native completed-draw captures cover live gameplay and pre-existing pause menu. Independent frame_post_draw observer reads the same viewport and exact interpolated transforms before recorder resumes, binds engine drawn/process IDs and pixel hashes to actual recorder PNG/JSON. No synthetic recorder replacement, posed actor, camera override, manual draw, long movie or target-device claim."}
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n");file.close()
	print("RECORDER_DISPLAY_OUTPUT ",OUTPUT)
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)

func _capture(label: String,was_paused: bool) -> void:
	var expected: int=recorder.reports.size()+1
	draws.clear()
	_key(KEY_1,true);_key(KEY_1,false)
	for tick: int in 12:
		await process_frame
		if recorder.reports.size()==expected and not recorder.busy:break
	_check(recorder.reports.size()==expected and recorder.editing and game.paused and paused,
		"recorder display: normal1 shortcut completes "+label+" capture before note entry")
	if recorder.reports.size()!=expected:return
	var report: Dictionary=recorder.reports[-1]
	var frame_id:=int(report.capture.rendered_frame)
	_check(draws.has(frame_id),"recorder display: independently observed exact completed drawn frame "+label)
	if not draws.has(frame_id):return
	var draw: Dictionary=draws[frame_id]
	_check(report.presentation==draw.presentation and report.capture.completed_process_frame==draw.process_frame,
		"recorder display: JSON presentation equals independent same-draw camera/body/board/head/feet/hands "+label)
	_check(report.basis==draw.body and report.velocity==draw.velocity and report.last_player_physics_frame==draw.last_player_physics_frame,
		"recorder display: frozen physical actor agrees with raw recorded tick "+label)
	_check(not draw.panel_visible and not draw.modal_visible and draw.paused,
		"recorder display: actual PNG draw contains gameplay HUD without note or pause overlays "+label)
	_check(report.paused==was_paused and report.capture.physics_frame==report.physics_frame
		and report.capture.requested_process_frame<=draw.process_frame and report.capture.physics_frame_after_draw==draw.physics_frame
		and report.capture.requested_milliseconds<=draw.milliseconds and draw.milliseconds<=report.capture.sampled_milliseconds
		and report.capture.sampled_milliseconds<=report.capture.image_read_milliseconds,
		"recorder display: ordered raw/request/draw/read timestamps and exact engine frame IDs "+label)
	var png_path: String=recorder.session_dir.path_join(report.screenshot)
	var png:=Image.load_from_file(png_path)
	_check(png!=null and png.get_size()==SIZE,"recorder display: production PNG exists at actual viewport dimensions "+label)
	if png!=null:
		png.convert(Image.FORMAT_RGBA8)
		_check(_pixel_hash(png)==draw.pixel_sha256,
			"recorder display: production PNG pixels exactly equal independent same-draw readback "+label)
		var independent: Image=draw.image
		_check(independent.save_png(OUTPUT.path_join(label+"-independent.png"))==OK,"recorder display: independent same-draw PNG retained "+label)
	_check(report.inputs.size()>=2 and report.presentation.feet.size()==2 and report.presentation.hands.size()==2,
		"recorder display: recorded real input edges and complete body presentation remain readable "+label)
	var serial: Dictionary=draw.duplicate();serial.erase("image")
	records.append({"phase":label,"report":report.id,"png":png_path,"png_sha256":FileAccess.get_sha256(png_path),"draw":serial})
	_check(recorder.save_note("Displayed recorder alignment: "+label)==OK,"recorder display: production note saves "+label)
	recorder.close_panel()
	_check(game.paused==was_paused and paused==was_paused and not recorder.editing and not game.hud.debug_input_blocked,
		"recorder display: original live/pause state and inputs restore "+label)

func _draw_witness() -> void:
	if recorder==null or not recorder.busy:return
	var rider: CharacterBody3D=game.skater
	var rig: RefCounted=rider._visual_rig
	var presentation: Dictionary={"interpolation_fraction":Engine.get_physics_interpolation_fraction(),
		"last_player_presentation_process_frame":rider.last_presentation_process_frame,
		"player":Recorder.frame(rider.get_global_transform_interpolated()),
		"visual":Recorder.frame(rider._visual.get_global_transform_interpolated()),
		"rider":Recorder.frame(rider._rider_visual.get_global_transform_interpolated()),
		"board":Recorder.frame(rig._board.get_global_transform_interpolated()),
		"head":Recorder.frame(rig._head.get_global_transform_interpolated()),"feet":[],"hands":[],
		"camera":Recorder.frame(rider._camera.get_global_transform_interpolated())}
	for leg: Dictionary in rig._legs:presentation.feet.append(Recorder.frame(leg.foot.get_global_transform_interpolated()))
	for arm: Dictionary in rig._arms:presentation.hands.append(Recorder.frame(arm.hand.get_global_transform_interpolated()))
	var image:=root.get_texture().get_image();image.convert(Image.FORMAT_RGBA8)
	draws[Engine.get_frames_drawn()]={"presentation":presentation,"body":Recorder.frame(rider.global_transform),
		"velocity":Recorder.vec(rider.velocity),"last_player_physics_frame":rider.last_physics_frame,
		"milliseconds":Time.get_ticks_msec(),"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),
		"panel_visible":recorder._panel.visible,"modal_visible":game.hud._modal.visible,"paused":paused,
		"pixel_sha256":_pixel_hash(image),"image":image}

func _pixel_hash(image: Image) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(image.get_data())
	return hash.finish().hex_encode()

func _key(code: Key,pressed: bool) -> void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=pressed
	Input.parse_input_event(event)

func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
