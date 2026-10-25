extends RefCounted

static func run(tree:SceneTree,game:Node,check:Callable)->void:
	var recorder:CanvasLayer=game.playtest_recorder
	var old_base:String=recorder.base_directory
	recorder.base_directory="res://.local/recorder-tests-"+str(Time.get_ticks_usec())
	game.start_mode(true)
	for i in 3:await tree.physics_frame;await tree.process_frame
	check.call(not recorder.active and recorder.history.is_empty(),"debug recorder: ordinary play has no active sampling or report files")
	check.call(recorder.begin_session()==OK,"debug recorder: explicit start creates a local session")
	var first:String=recorder.session_dir
	for i in 55:recorder._process(.26)
	check.call(recorder.history.size()==40,"debug recorder: long recording retains only ten seconds of bounded state history")
	var position:Vector3=game.skater.global_position
	var camera:Vector3=game.skater._camera.global_position
	await recorder.capture_issue()
	check.call(recorder.editing and game.paused and tree.paused and recorder.reports.size()==1,
		"debug recorder: capture freezes the live game before opening note entry")
	var report:Dictionary=recorder.reports[0]
	check.call(report.position==[position.x,position.y,position.z] and report.camera.position==[camera.x,camera.y,camera.z]
		and report.rig.bones.has("left_thigh") and report.source_sha256["res://game/player/skater.gd"]==FileAccess.get_sha256("res://game/player/skater.gd"),
		"debug recorder: report round-trips exact player/camera coordinates, anatomical bones and source fingerprint")
	var event:=InputEventKey.new();event.physical_keycode=KEY_R;event.pressed=true
	Input.parse_input_event(event)
	for i in 3:await tree.process_frame
	check.call(game.paused and game.skater.global_position==position,
		"debug recorder: typing a gameplay restart key cannot restart or move the paused skater")
	event.pressed=false;Input.parse_input_event(event)
	var note:="Legs folded after a fall.\nKelvingrove → right entrance."
	check.call(recorder.save_note(note)==OK,"debug recorder: Unicode multiline comment saves alongside the capture")
	recorder.close_panel()
	check.call(not recorder.editing and not game.paused and not tree.paused and not game.hud.debug_input_blocked,
		"debug recorder: saving restores the original live play state and input")
	var paused_before:bool=game.paused
	game.toggle_pause()
	await recorder.capture_issue()
	recorder.save_note("Second issue from pause menu")
	recorder.close_panel()
	check.call(game.paused and tree.paused and game.hud._modal.visible,
		"debug recorder: a report opened from the pause menu restores that paused menu")
	game.toggle_pause()
	check.call(game.paused==paused_before,"debug recorder: existing pause state is not inverted by note entry")
	var result:Error=recorder.finish_session()
	var reader:=ZIPReader.new()
	var opened:Error=reader.open(recorder.archive_path)
	var manifest:Dictionary=JSON.parse_string(reader.read_file("session.json").get_string_from_utf8()) if opened==OK else {}
	var saved:Dictionary=JSON.parse_string(reader.read_file("issue-0001.json").get_string_from_utf8()) if opened==OK else {}
	check.call(result==OK and opened==OK and not recorder.active and manifest.get("active",true)==false
		and saved.get("note","")==note and manifest.get("reports",[]).size()==2,
		"debug recorder: one independently readable ZIP includes completed manifest and both persisted issue comments")
	if opened==OK:reader.close()
	recorder.close_panel()
	check.call(recorder.begin_session()==OK and recorder.session_dir!=first and recorder.reports.is_empty()
		and FileAccess.file_exists(first.path_join("issue-0001.json")),
		"debug recorder: starting again preserves the prior session and uses a fresh directory")
	recorder.finish_session();recorder.close_panel();recorder.base_directory=old_base
	game.start_mode(true)
