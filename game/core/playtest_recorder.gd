extends CanvasLayer
## Explicit local bug reports. No upload, mesh rebuild or sampling while inactive.
signal session_changed(active: bool)
var game: Node
var active := false
var session_dir := ""
var archive_path := ""
var base_directory := "user://debug_sessions"
var reports: Array[Dictionary] = []
var history: Array[Dictionary] = []
var inputs: Array[Dictionary] = []
var busy := false
var editing := false
var _clock := 0.0
var _was_paused := false
var _modal_was_visible := false
var _panel: PanelContainer
var _note: TextEdit
var _heading: Label
var _status: Label
var _save: Button
var _capture: Button
var _finish: Button
var _reveal: Button
var _resume: Button
var _pending := -1
var _badge: Label
const ACTIONS := ["push","brake","steer_left","steer_right","ollie","flip","grab","grind","manual","revert","spin_left","spin_right"]
const SOURCES := ["res://project.godot","res://game/main.gd","res://game/core/playtest_recorder.gd","res://game/levels/outdoors/surface_builder.gd","res://game/player/skater.gd","res://game/player/skater_visual.gd","res://game/player/skater_garments.gd","res://game/levels/outdoor_routes.gd","res://game/levels/kelvingrove_skatepark.gd","res://game/levels/sunken_bowl_feature.gd"]

func _ready() -> void:
	layer=100
	process_mode=Node.PROCESS_MODE_ALWAYS
	_panel=PanelContainer.new();add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_left=-300;_panel.offset_right=300;_panel.offset_top=-245;_panel.offset_bottom=245
	var margin:=MarginContainer.new();_panel.add_child(margin)
	for edge:String in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,20)
	var rows:=VBoxContainer.new();rows.add_theme_constant_override("separation",12);margin.add_child(rows)
	_heading=Label.new();_heading.add_theme_font_size_override("font_size",26);rows.add_child(_heading)
	_status=Label.new();_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;rows.add_child(_status)
	_note=TextEdit.new();_note.custom_minimum_size=Vector2(0,150);_note.placeholder_text="What went wrong? What were you doing just before it happened?";rows.add_child(_note)
	_save=_button(rows,"SAVE NOTE & RETURN",_save_and_close)
	_capture=_button(rows,"CAPTURE ISSUE  ·  1",capture_issue)
	_finish=_button(rows,"END SESSION & CREATE ZIP  ·  3",finish_session)
	_reveal=_button(rows,"SHOW FILES",reveal_files)
	_resume=_button(rows,"BACK TO THE BOARD",close_panel)
	_panel.hide()
	_badge=Label.new();add_child(_badge);_badge.position=Vector2(20,100)
	_badge.add_theme_color_override("font_color",Color("d8ef96"));_badge.hide()

func _update_badge()->void:
	_badge.visible=active
	_badge.text="DEBUG REC  ·  %d issues  ·  1 capture  ·  2 menu  ·  3 finish"%reports.size()

func _button(parent:Node,title:String,callback:Callable)->Button:
	var button:=Button.new();button.text=title;button.custom_minimum_size.y=38
	parent.add_child(button);button.pressed.connect(callback);return button

func configure(owner_game:Node)->void:game=owner_game

func _process(delta:float)->void:
	if not active or busy or editing or game==null or game.paused:return
	_clock+=delta
	if _clock<.25:return
	_clock=0.
	history.append(snapshot(false))
	if history.size()>40:history.pop_front()

func _input(event:InputEvent)->void:
	if game==null:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_ESCAPE and editing and not busy:
			get_viewport().set_input_as_handled();close_panel();return
		if event.physical_keycode==KEY_1 and not editing:
			get_viewport().set_input_as_handled();capture_issue.call_deferred();return
		if event.physical_keycode==KEY_2 and not editing:
			get_viewport().set_input_as_handled();show_menu();return
		if event.physical_keycode==KEY_3 and not editing:
			get_viewport().set_input_as_handled();finish_session();return
	if not active or editing or busy:return
	for action:String in ACTIONS:
		if event.is_action(action):
			inputs.append({"milliseconds":Time.get_ticks_msec(),"action":action,"strength":Input.get_action_strength(action)})
			if inputs.size()>128:inputs.pop_front()

func begin_session()->Error:
	if active:return OK
	var stamp:=Time.get_datetime_string_from_system(true).replace(":","-")
	session_dir=base_directory.path_join(stamp+"-"+str(Time.get_ticks_usec()))
	var error:=DirAccess.make_dir_recursive_absolute(session_dir)
	if error!=OK:return error
	reports.clear();history.clear();inputs.clear();archive_path="";_clock=0.
	active=true
	_write_text("README.txt","Tam Hawks Pro Skater playtest session\nShare the ZIP after ending the session. Each issue has a PNG, JSON state and your note.\n1 capture; 2 session menu; 3 finish.\nPlayer axes: forward is -Z; camera forward is separate. Raw local evidence is retained if ZIP export fails.\n")
	var written:=_write_manifest()
	if written!=OK:active=false;return written
	_update_badge()
	session_changed.emit(true)
	return OK

func _pause_for_panel()->void:
	if editing:return
	_was_paused=game.paused
	_modal_was_visible=game.hud._modal.visible
	editing=true
	game.hud.debug_input_blocked=true
	game.paused=true;get_tree().paused=true;game.audio.set_paused(true)
	for action:String in ACTIONS:Input.action_release(action)

func show_menu()->void:
	if busy:return
	_pause_for_panel()
	_heading.text="PLAYTEST RECORDER"
	_status.text=("Recording · %d issues captured. 1 marks a new issue."%reports.size()) if active else "1 starts a session and captures your current view. Finish here to create one ZIP to share."
	_note.hide();_save.hide();_capture.show();_finish.visible=active;_reveal.visible=not session_dir.is_empty();_resume.show()
	_panel.show();_capture.grab_focus()

func capture_issue()->void:
	if busy or (_pending>=0):return
	var error:=begin_session()
	if error!=OK:show_menu();_status.text="Could not create capture folder: "+error_string(error);return
	busy=true
	var report:=snapshot(true)
	report["history"]=history.duplicate(true);report["inputs"]=inputs.duplicate(true)
	_pause_for_panel();_panel.hide();game.hud._modal.hide()
	# Freeze first, then draw the same camera without note/pause overlays.
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
	var id:="issue-%04d"%(reports.size()+1)
	report["id"]=id;report["note"]="";report["screenshot"]=""
	if DisplayServer.get_name()!="headless":
		var pixels:=get_viewport().get_texture().get_image()
		error=pixels.save_png(session_dir.path_join(id+".png"))
		if error==OK:report.screenshot=id+".png"
		report["screenshot_error"]=error_string(error)
	else:report["screenshot_error"]="Headless renderer: screenshot unavailable"
	var log_path:=str(ProjectSettings.get_setting("debug/file_logging/log_path","user://logs/godot.log"))
	report["engine_log_available"]=FileAccess.file_exists(log_path)
	if FileAccess.file_exists(log_path):
		var log:=FileAccess.open(log_path,FileAccess.READ)
		if log!=null:
			log.seek(maxi(0,log.get_length()-65536))
			_write_text(id+"-engine.log",log.get_buffer(mini(65536,log.get_length())).get_string_from_utf8())
	reports.append(report);_pending=reports.size()-1
	var written:=_write_report(_pending)
	_write_manifest();_update_badge()
	busy=false
	_heading.text="ISSUE %d CAPTURED"%reports.size()
	_status.text="Location, direction and pose state saved. Add a note, then return to skating. 2 opens session controls."
	if written!=OK:_status.text="Report could not be written: "+error_string(written)+". Retry Save Note; the capture remains in memory. "
	if report.screenshot.is_empty():_status.text+=" Screenshot unavailable: "+str(report.screenshot_error)
	_note.text="";_note.show();_save.show();_capture.hide();_finish.hide();_reveal.hide();_resume.hide()
	_panel.show();_note.grab_focus()

func save_note(text:String)->Error:
	if _pending<0:return ERR_INVALID_PARAMETER
	reports[_pending].note=text.left(8000)
	var error:=_write_report(_pending)
	_write_manifest()
	if error==OK:_pending=-1
	return error

func _save_and_close()->void:
	var error:=save_note(_note.text)
	if error==OK:close_panel()
	else:_status.text="Could not save note: "+error_string(error)+". Keep this window open and retry."

func close_panel()->void:
	if busy:return
	if _pending>=0 and save_note(_note.text)!=OK:return
	_panel.hide()
	for action:String in ACTIONS:Input.action_release(action)
	game.hud._modal.visible=_modal_was_visible
	game.hud.debug_input_blocked=false
	game.paused=_was_paused;get_tree().paused=_was_paused;game.audio.set_paused(_was_paused)
	editing=false

func finish_session()->Error:
	if busy:return ERR_BUSY
	if not active:show_menu();_status.text="Capture an issue with 1 to start a session.";return ERR_UNCONFIGURED
	if _pending>=0:
		var saved:=save_note(_note.text)
		if saved!=OK:return saved
	active=false
	_write_manifest()
	archive_path=session_dir+".zip"
	var pack:=ZIPPacker.new()
	var error:=pack.open(archive_path)
	if error==OK:
		for name:String in DirAccess.get_files_at(session_dir):
			var bytes:=FileAccess.get_file_as_bytes(session_dir.path_join(name))
			error=pack.start_file(name)
			if error==OK:error=pack.write_file(bytes)
			if error==OK:error=pack.close_file()
			if error!=OK:break
		var closed:=pack.close()
		if error==OK:error=closed
	if error==OK:session_changed.emit(false)
	else:active=true;_write_manifest()
	_update_badge()
	show_menu()
	_heading.text="SESSION READY TO SHARE" if error==OK else "EXPORT NEEDS ATTENTION"
	_status.text=("Share this ZIP:\n"+ProjectSettings.globalize_path(archive_path)) if error==OK else ("ZIP could not be completed: "+error_string(error)+". Your reports remain in "+ProjectSettings.globalize_path(session_dir)+". Retry End Session.")
	_capture.visible=error==OK;_finish.visible=error!=OK;_reveal.show();_resume.show();_reveal.grab_focus()
	return error

func reveal_files()->void:
	var path:=archive_path if not active and FileAccess.file_exists(archive_path) else session_dir
	if not path.is_empty():OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))

func snapshot(detailed:bool)->Dictionary:
	var rider:CharacterBody3D=game.skater
	var camera:Camera3D=rider._camera
	var ground:float=game.world.get_ground_height(rider.global_position)
	var state:={"utc":Time.get_datetime_string_from_system(true),"milliseconds":Time.get_ticks_msec(),
		"position":vec(rider.global_position),"velocity":vec(rider.velocity),"forward":vec(-rider.global_basis.z),"basis":frame(rider.global_transform),
		"camera":{"position":vec(camera.global_position),"forward":vec(-camera.global_basis.z),"up":vec(camera.global_basis.y),"fov":camera.fov},
		"ground_height":ground if is_finite(ground) else null,"on_floor":rider.is_on_floor(),"airborne":rider.airborne,
		"bailing":rider.bail_active,"bail_phase":rider.bail_phase,"bail_reason":rider.bail_reason,"speed":rider.speed,
		"charge":rider.ollie_charge,"crouching":rider.crouching,"grind":rider.grind_style_id,"lip":rider.lip_id,"manual":rider.manual_trick_id,
		"flip":rider.flip_trick_id,"grab":rider.grab_trick_id,"paused":game.paused}
	if not detailed:return state
	state["engine"]=Engine.get_version_info();state["renderer"]=RenderingServer.get_current_rendering_method()
	state["viewport"]=vec(Vector3(get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y,0))
	state["graphics"]=game.career.settings.graphics_quality
	state["source_sha256"]={}
	for path:String in SOURCES:state.source_sha256[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "unavailable in this build"
	state["inputs_held"]={}
	for action:String in ACTIONS:state.inputs_held[action]=Input.get_action_strength(action)
	var rig:RefCounted=rider._visual_rig
	state["rig"]={"visual":frame(rider._visual.global_transform),"rider":frame(rider._rider_visual.global_transform),"board":frame(rig._board.global_transform),"upper":frame(rig._upper.transform),"drag_crouch":rig._drag_crouch,"handplant_blend":rig._handplant_blend,"bones":{}}
	for i in rig._garments.skeleton.get_bone_count():state.rig.bones[rig._garments.skeleton.get_bone_name(i)]=frame(rig._garments.skeleton.get_bone_pose(i))
	state["contacts"]=[]
	for i in rider.get_slide_collision_count():
		var collision:=rider.get_slide_collision(i)
		var collider:=collision.get_collider()
		state.contacts.append({"position":vec(collision.get_position()),"normal":vec(collision.get_normal()),"collider":str(collider.get_path()) if collider is Node else str(collider)})
	return state

static func vec(value:Vector3)->Array:return [value.x,value.y,value.z]
static func frame(value:Transform3D)->Dictionary:return {"origin":vec(value.origin),"x":vec(value.basis.x),"y":vec(value.basis.y),"z":vec(value.basis.z)}

func _write_text(name:String,text:String)->Error:
	var file:=FileAccess.open(session_dir.path_join(name),FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(text);file.flush();return file.get_error()
func _write_report(index:int)->Error:
	return _write_text(str(reports[index].id)+".json",JSON.stringify(reports[index],"\t"))
func _write_manifest()->Error:
	return _write_text("session.json",JSON.stringify({"format":1,"engine":Engine.get_version_info(),"active":active,"reports":reports},"\t"))
