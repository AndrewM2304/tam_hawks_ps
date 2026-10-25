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
	var state:Dictionary=recorder.snapshot(false)
	check.call(state.manual=="manual" and not state.active_states.manual
		and not state.active_states.grind and not state.active_states.lip
		and state.has("native_floor_valid") and state.bowl_transfer.has("recognized"),
		"debug recorder: configured default trick IDs are distinguished from active manual/grind/lip and transfer state")
	var old_reason:String=game.skater.bail_reason
	game.skater.bail_reason="recorded impact";game.skater.bailing=false
	state=recorder.snapshot(false)
	check.call(state.bail.last_reason=="recorded impact" and state.bail.active_reason.is_empty()
		and not state.bail.active,
		"debug recorder: a retained last bail reason never claims the rider is currently bailing")
	game.skater.bailing=true
	state=recorder.snapshot(false)
	check.call(state.bail.active and state.bail.active_reason=="recorded impact",
		"debug recorder: active bail cause is explicit while the recovery lifecycle runs")
	game.skater.bailing=false;game.skater.bail_reason=old_reason
	var action:=InputEventAction.new();action.action="push";action.pressed=true;action.strength=1.0
	recorder._input(action)
	action=InputEventAction.new();action.action="push";action.pressed=false;action.strength=0.0
	recorder._input(action)
	check.call(recorder.inputs.size()==2 and recorder.inputs[0].pressed and not recorder.inputs[0].released
		and recorder.inputs[1].released and not recorder.inputs[1].pressed
		and recorder.inputs[0].event_strength==1.0 and recorder.inputs[1].event_strength==0.0,
		"debug recorder: actual input press and release events retain separate strengths and engine tick IDs")
	var old_scale:float=game.hud._settings.get("ui_scale",1.0)
	for scale:float in [1.0,1.2,1.4]:
		game.hud._settings.ui_scale=scale;game.hud._relayout(true);recorder._layout_badge()
		var badge:Rect2=recorder._badge.get_global_rect()
		check.call(recorder.get_viewport().get_visible_rect().encloses(badge)
			and not badge.intersects(game.hud._special_panel.get_global_rect())
			and not badge.intersects(game.hud._timer_card.get_global_rect())
			and not badge.intersects(game.hud._goals.get_global_rect()),
			"debug recorder: indicator stays within safe HUD bounds away from Special/timer/goals at scale %.1f"%scale)
	game.hud._settings.ui_scale=old_scale;game.hud._relayout(true);recorder._layout_badge()
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
	check.call(report.capture.physics_frame==report.physics_frame
		and report.capture.requested_milliseconds<=report.capture.sampled_milliseconds
		and report.capture.requested_process_frame<=report.capture.completed_process_frame
		and report.capture.physics_frame_after_draw>=report.capture.physics_frame
		and report.presentation.has("camera") and report.presentation.has("board")
		and report.presentation.feet.size()==2 and report.presentation.hands.size()==2
		and report.last_player_physics_frame==game.skater.last_physics_frame,
		"debug recorder: frozen physics and completed rendered/interpolated presentation have explicit frame and timestamp alignment")
	var event:=InputEventKey.new();event.physical_keycode=KEY_R;event.pressed=true
	Input.parse_input_event(event)
	for i in 3:await tree.process_frame
	check.call(game.paused and game.skater.global_position==position,
		"debug recorder: typing a gameplay restart key cannot restart or move the paused skater")
	event.pressed=false;Input.parse_input_event(event)
	recorder._note.text="";recorder._note.grab_focus()
	for code:int in [KEY_1,KEY_2,KEY_3]:
		var number:=InputEventKey.new();number.physical_keycode=code;number.keycode=code;number.unicode=code;number.pressed=true
		Input.parse_input_event(number)
		number=InputEventKey.new();number.physical_keycode=code;number.keycode=code;number.pressed=false
		Input.parse_input_event(number)
	await tree.process_frame
	check.call(recorder.editing and recorder.reports.size()==1 and recorder._note.text=="123",
		"debug recorder: number shortcuts type normally inside notes without capturing, opening menus or ending the session")
	var note:="Legs folded after a fall.\nKelvingrove → right entrance."
	var writable_session:String=recorder.session_dir
	recorder.session_dir=writable_session.path_join("missing-parent")
	check.call(recorder.save_note(note)!=OK and recorder._pending==0 and recorder.reports[0].note==note,
		"debug recorder: a failed note write retains the comment and pending issue for retry")
	recorder.session_dir=writable_session
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
	check.call(result==OK and opened==OK and not recorder.active and manifest.get("active",true)==false and manifest.get("format",0)==2
		and saved.get("note","")==note and manifest.get("reports",[]).size()==2,
		"debug recorder: one independently readable ZIP includes completed manifest and both persisted issue comments")
	if opened==OK:reader.close()
	recorder.close_panel()
	check.call(recorder.begin_session()==OK and recorder.session_dir!=first and recorder.reports.is_empty()
		and FileAccess.file_exists(first.path_join("issue-0001.json")),
		"debug recorder: starting again preserves the prior session and uses a fresh directory")
	recorder.finish_session();recorder.close_panel();recorder.base_directory=old_base
	game.start_mode(true)
