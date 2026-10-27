extends CanvasLayer
## Controller-first presentation. Main owns all gameplay, persistence and audio state.

signal restart_requested
signal debug_requested
var debug_input_blocked := false
signal pause_requested
signal free_skate_requested
signal settings_changed(values: Dictionary)
signal cosmetic_selected(id: String)
signal start_requested(free_skate: bool)
signal ui_feedback
signal music_requested(action: String, value: String)

const GraphicsQuality = preload("res://game/core/graphics_quality.gd")
const TrickCatalog = preload("res://game/tricks/trick_catalog.gd")
const RouteMap = preload("res://game/ui/route_map.gd")
const InputProfile = preload("res://game/core/input_profile.gd")

const INK := Color("101d22")
const PANEL := Color("14272c")
const PAPER := Color("f2f4e9")
const MUTED := Color("aebfbb")
const ACCENT := Color("d8ef96")
const ORANGE := Color("ffb27d")
const TRACK := Color("365056")
const FOCUS_REVEAL_PADDING := 4.0

var _map_checkpoints: Dictionary = {}
var _map_routes: Array = []
var _active_route_map: Control
var _map_availability: Label
var _recovery_layer: Control
var _recovery_overlay: ColorRect
var _recovery_caption: Label

var _root: Control
var _hud: Control
var _top: Control
var _timer_card: PanelContainer
var _score_card: PanelContainer
var _timer: Label
var _score: Label
var _mode: Label
var _combo: Label
var _tricks: Label
var _feedback: Label
var _combo_status: Label
var _save_warning: Label
var _modal_warning: Label
var _modal_notice: Label
var _feedback_panel: PanelContainer
var _goals: Label
var _challenge: Label
var _caption: Label
var _prompt: Label
var _special_label: Label
var _special_hint: Label
var _special_bar: ProgressBar
var _balance_panel: PanelContainer
var _balance_marker: ColorRect
var _balance_label: Label
var _balance_track: Control
var _special_panel: PanelContainer
var _modal: ColorRect
var _dialog: PanelContainer
var _modal_title: Label
var _modal_details: Label
var _resume: Button
var _restart: Button
var _free: Button
var _focus_first: Control
var _page := ""
var _page_revision := 0
var _gameplay_transition_serial := 0
var _pending_gameplay_transition: Dictionary = {}
var _consumed_menu_inputs: Dictionary = {}
var _navigation: Array[Dictionary] = []
var _scroll: ScrollContainer
var _state: Dictionary = {}
var _settings: Dictionary = {}
var _binding_action := ""
var _binding_status: Label
var _input_profile: Script
var _binding_rows: Dictionary = {}
var _binding_preferences: Dictionary = {}
var _controller_active := false
var _last_size := Vector2.ZERO
var _last_scale := -1.0
var _last_combo := 0
var _combo_tween: Tween
var _prompt_texts: Dictionary = {}
var _display_controller_active := false
var _score_fit_text := ""
var _score_fit_width := -1.0
var _feedback_layout_texts: Array[String] = []
var _layout_visibility_revision := 0
var _layout_visibility_pending := false
var _music_controls: Dictionary = {}
var _music_playlist_rows: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_menu_controller_connection_changed)
	_controller_active = not Input.get_connected_joypads().is_empty()
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hud)
	_build_hud()
	_build_recovery_overlay()
	_modal = ColorRect.new()
	_modal.color = Color(0.025, 0.055, 0.065, 0.96)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_modal)
	_modal.visible = false
	_relayout()


func _build_hud() -> void:
	_top = Control.new()
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_top)
	_timer_card = _card()
	_timer_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_top.add_child(_timer_card)
	var timer_box := _vbox(_timer_card, 0)
	_mode = _label(timer_box, "CAREER RUN", 13, MUTED)
	_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer = _label(timer_box, "2:00", 42, PAPER)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_card = _card()
	_score_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_top.add_child(_score_card)
	var score_box := _vbox(_score_card, 0)
	_label(score_box, "SCORE", 14, PAPER)
	_score = _label(score_box, "0", 36, PAPER)
	_goals = _floating_label("0 / 10 GOALS", 16, ACCENT)
	_goals.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_balance_panel = _card()
	_hud.add_child(_balance_panel)
	var balance_box := _vbox(_balance_panel, 7)
	_balance_label = _label(balance_box, "RAIL BALANCE", 14, PAPER)
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_balance_track = Control.new()
	_balance_track.custom_minimum_size.y = 18
	balance_box.add_child(_balance_track)
	var rail := ColorRect.new()
	rail.color = TRACK
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rail.offset_top = 5
	rail.offset_bottom = -5
	_balance_track.add_child(rail)
	var centre := ColorRect.new()
	centre.color = MUTED
	centre.position = Vector2(141, 0)
	centre.size = Vector2(3, 18)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balance_track.add_child(centre)
	_balance_marker = ColorRect.new()
	_balance_marker.color = ACCENT
	_balance_marker.size = Vector2(9, 18)
	_balance_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balance_track.add_child(_balance_marker)
	_balance_panel.visible = false
	_special_panel = _card()
	_special_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_hud.add_child(_special_panel)
	# Reclaim height once wrapped text has settled at the panel's real width.
	_special_panel.minimum_size_changed.connect(func() -> void:
		_special_panel.size.y = maxf(76, _special_panel.get_combined_minimum_size().y))
	var special_box := _vbox(_special_panel, 7)
	_special_label = _label(special_box, "SPECIAL  /  BUILD A COMBO", 15, MUTED)
	_special_bar = _progress(special_box, ORANGE)
	_special_hint = _label(special_box, "BANK POINTS TO FILL", 13, MUTED)
	_special_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_special_hint.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_combo = _floating_label("", 34, ACCENT)
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tricks = _floating_label("", 19, PAPER)
	_tricks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tricks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tricks.max_lines_visible = 2
	_combo_status = _floating_label("", 15, ACCENT)
	_combo_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_panel = _card()
	_hud.add_child(_feedback_panel)
	_feedback = _label(_feedback_panel, "", 17, ORANGE)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.max_lines_visible = 2
	_save_warning = _floating_label("", 14, ORANGE)
	_save_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption = _floating_label("", 20, PAPER)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_challenge = _floating_label("", 16, ACCENT)
	_challenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_challenge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_challenge.max_lines_visible = 2
	_challenge.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_prompt = _floating_label("", 17, ACCENT)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING



func update_display(state: Dictionary) -> void:
	if not is_instance_valid(_timer):
		return
	var device_changed := _display_controller_active != _controller_active
	var viewport_changed := get_viewport().get_visible_rect().size != _last_size
	var incoming_settings: Dictionary = state.get("settings", {})
	var needs_page_transition := (_page == "" and (bool(state.get("paused", false)) or bool(state.get("finished", false)))) \
		or (_page not in ["", "title"] and not bool(state.get("paused", false)) and not bool(state.get("finished", false)))
	if state == _state and incoming_settings == _settings and not device_changed \
			and not viewport_changed and not needs_page_transition:
		return
	var previous := _state
	_state = _detached_display_state(state)
	_display_controller_active = _controller_active
	if incoming_settings != _settings:
		_settings = incoming_settings.duplicate(true)
	var bindings: Dictionary = _settings.get("bindings", {})
	var bindings_changed := bindings != _binding_preferences
	if bindings_changed:
		_binding_preferences = bindings.duplicate(true)
		_binding_rows.clear()
		_prompt_texts.clear()
	_relayout()
	var seconds := maxi(0, ceili(float(state.get("time", 120.0))))
	var free: bool = state.get("free_skate", false)
	_timer.text = "∞" if free else "%d:%02d" % [seconds / 60, seconds % 60]
	_timer.modulate = ORANGE if seconds <= 15 and not free else Color.WHITE
	_mode.text = "FREE SKATE" if free else "CAREER RUN"
	if state.get("score", 0) != previous.get("score", -1):
		_score.text = _number(int(state.get("score", 0)))
	_fit_line(_score, 36, 22)
	if state.get("goals", []) != previous.get("goals", []) or previous.is_empty() \
			or free != bool(previous.get("free_skate", false)) or device_changed or bindings_changed:
		var completed := 0
		for goal: Dictionary in state.get("goals", []):
			if goal.get("done", false): completed += 1
		_goals.text = "FREE SKATE  ·  NO TIMER" if free else "%d / 10 GOALS  ·  %s" % [completed, _prompt_for("goals", "TAB")]
	var meter := clampf(float(state.get("special_meter",0.0)),0.0,100.0)
	var ready := bool(state.get("special_ready",meter >= 100.0))
	var active := bool(state.get("special_active",false))
	_special_bar.value = meter/100.0
	_special_label.text = "SPECIAL ACTIVE" if active else ("SPECIAL READY" if ready else "SPECIAL")
	_special_label.modulate = ORANGE if ready or active else Color.WHITE
	_special_hint.text = "%s / %s  ·  SPECIALS" % [_prompt_for("special_one","U"),_prompt_for("special_two","I")] if ready or active else ""
	var grinding := bool(state.get("grinding",false))
	var manual := bool(state.get("manual",false))
	var lip := bool(state.get("lip_active",state.get("lip",false)))
	var skitch := bool(state.get("skitching",false)) and bool(state.get("skitch_caught",true))
	var balance_key := "lip_balance" if lip else ("skitch_balance" if skitch else ("balance" if grinding else "manual_balance"))
	var balance := clampf(float(state.get(balance_key,0.0)),-1.0,1.0)
	_balance_panel.visible = grinding or manual or lip or skitch
	_balance_marker.position = Vector2(138.0+balance*130.0,0)
	_balance_marker.color = ORANGE if absf(balance)>0.7 else ACCENT
	var ride_name := str(state.get("grind_name","RAIL")) if grinding else (str(state.get("lip_name","LIP")) if lip else ("SKITCH" if skitch else str(state.get("manual_name","MANUAL"))))
	_balance_label.text = ride_name.to_upper()+"  /  "+_prompt_for("steer_left","A").replace("D-pad ","")+"–"+_prompt_for("steer_right","D").replace("D-pad ","")
	if absf(balance)>0.7:
		_balance_label.text = "CORRECT  ·  "+_prompt_for("steer_left" if balance>0.0 else "steer_right","")
	var combo: int = state.get("combo", 0)
	_combo.text = "%s × %d" % [_number(int(state.get("combo_base", 0))), int(state.get("multiplier", 0))] if combo > 0 else ""
	_tricks.text = str(state.get("tricks", "")) if combo > 0 else ""
	_feedback.text = str(state.get("feedback", ""))
	_feedback_panel.visible = not _feedback.text.is_empty()
	_combo_status.text = ""
	if combo > 0:
		var link_time := float(state.get("landing_window", 0.0))
		_combo_status.text = "%s PENDING  ·  KEEP THE LINE ALIVE" % _number(combo)
		if link_time > 0.0:
			_combo_status.text = "LINK IT  %.2fs  ·  %s MANUAL / UP–DOWN  ·  %s REVERT" % [link_time, _prompt_for("manual", "M"), _prompt_for("revert", "C")]
	if combo != _last_combo and combo > 0 and not bool(_settings.get("reduced_motion", false)):
		if is_instance_valid(_combo_tween): _combo_tween.kill()
		_combo.modulate = Color(1.0, 1.0, 0.72)
		_combo_tween = create_tween()
		_combo_tween.tween_property(_combo, "modulate", Color.WHITE, 0.18)
	_last_combo = combo
	_challenge.text = str(state.get("challenge_text", ""))
	_caption.text = str(state.get("caption", "")) if bool(_settings.get("captions", true)) else ""
	var interaction := str(state.get("interaction_prompt", ""))
	_prompt.text = "%s  ·  %s" % [_prompt_for("interact", "X"), interaction] if not interaction.is_empty() else ""
	if _prompt.text.is_empty() and _challenge.text.is_empty() and _caption.text.is_empty():
		_prompt.text = _activity_hint(state)
		if _prompt.text.is_empty(): _prompt.text = str(state.get("sidefeature_status",""))
		if _prompt.text.is_empty(): _prompt.text = _route_location_hint(state)
	_update_recovery(state)
	_save_warning.text = str(state.get("save_warning", ""))
	_save_warning.visible = not _save_warning.text.is_empty()
	if is_instance_valid(_modal_warning):
		_modal_warning.text = _save_warning.text
		_modal_warning.visible = _save_warning.visible
	if is_instance_valid(_modal_notice):
		_modal_notice.text = _feedback.text
		_modal_notice.visible = not _feedback.text.is_empty() and _page != "title"

	_layout_feedback_stack()
	var finished: bool = state.get("finished", false)
	var paused_now: bool = state.get("paused", false)
	if _page == "" and (finished or paused_now):
		_show_page("results" if finished else "pause")
	elif _page not in ["", "title"] and not finished and not paused_now:
		_hide_modal()
	_hud.visible = _page != "title"
	# Main keeps the soundtrack snapshot stable between asynchronous Music
	# responses. Gameplay ticks must not rebuild playlist rows or touch labels.
	# Detached state still notices metadata-only updates while gameplay is paused.
	if state.get("music", {}) != previous.get("music", {}):
		_update_music_controls()


func _detached_display_state(incoming: Dictionary) -> Dictionary:
	# Scalar fields change every frame. Retain owned nested snapshots when their
	# values agree; never retain a caller's mutable arrays or dictionaries.
	var detached := incoming.duplicate()
	for key: Variant in incoming:
		var value: Variant = incoming[key]
		if value is Dictionary or value is Array:
			detached[key] = _state[key] if _state.has(key) and _state[key] == value else value.duplicate(true)
	return detached


func show_title() -> void:
	_navigation.clear()
	_show_page("title")


func show_settings() -> void:
	_open_subpage("settings")


func show_controls() -> void:
	_open_subpage("controls")


func show_soundtrack() -> void:
	_open_subpage("soundtrack")


func is_menu_ready() -> bool:
	# Physics ticks can outnumber rendered frames. Evidence and automation must
	# wait for settled presentation, not infer readiness from elapsed physics.
	if _page.is_empty() or not visible: return true
	if not is_instance_valid(_dialog) or _dialog.modulate.a < 1.0: return false
	if not get_viewport().get_visible_rect().encloses(_dialog.get_global_rect()): return false
	var focused := get_viewport().gui_get_focus_owner()
	return is_instance_valid(focused) and _dialog.is_ancestor_of(focused) and focused.is_visible_in_tree()


func hide_menu() -> void:
	_hide_modal()


func set_map_data(checkpoints: Dictionary, routes: Array) -> void:
	_map_checkpoints = checkpoints.duplicate(true)
	_map_routes = routes.duplicate(true)
	if _page == "map" and is_instance_valid(_active_route_map) and _active_route_map.is_inside_tree():
		_refresh_route_map()


func show_map() -> void:
	_open_subpage("map")


func toggle_goals() -> void:
	if _page == "goals":
		_back()
		return
	_open_subpage("goals")


func _input(event: InputEvent) -> void:
	_restore_consumed_menu_release(event)
	if debug_input_blocked:return
	if event is InputEventKey and event.pressed: _controller_active = false
	elif event is InputEventJoypadButton and event.pressed: _controller_active = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5: _controller_active = true
	if _page == "": return
	if _binding_action != "":
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			_binding_action = ""
			_binding_status.text = "Binding cancelled. Select another action to edit."
			get_viewport().set_input_as_handled()
			return
		var admissible: bool = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5)
		if admissible and is_instance_valid(_input_profile):
			var result: Dictionary = _input_profile.rebind(_binding_action, event)
			get_viewport().set_input_as_handled()
			if result.get("ok", false):
				_binding_action = ""
				_change_setting("bindings", result.bindings)
				_show_page("controls")
			else:
				_binding_status.text = str(result.get("error", "That input cannot be assigned."))
		return
	var menu_cancel: bool = event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton
		and event.pressed and event.button_index == JOY_BUTTON_B)
	# GUI activation runs after _input. Settle its gameplay actions too, including
	# a Cross tap pressed and released before the next physics update.
	if event.is_action_pressed("ui_accept"):
		_consume_menu_input(event)
	if event.is_action_pressed("pause") or menu_cancel:
		_consume_menu_input(event)
		_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart"):
		_consume_menu_input(event)
		if _page in ["pause", "results"]: _restart_run()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("free_skate"):
		_consume_menu_input(event)
		if _page in ["pause", "results"]: _switch_mode()
		get_viewport().set_input_as_handled()
	elif InputMap.has_action("goals") and event.is_action_pressed("goals"):
		_consume_menu_input(event)
		toggle_goals()
		get_viewport().set_input_as_handled()


func _menu_input_token(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		return "pad:%d:%d" % [event.device, event.button_index]
	if event is InputEventKey:
		return "key:%d" % (event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	return ""


func _consume_menu_input(event: InputEvent) -> void:
	var token := _menu_input_token(event)
	if token.is_empty(): return
	_consumed_menu_inputs[token] = event.duplicate()
	if not _pending_gameplay_transition.is_empty():
		_pending_gameplay_transition.input_revision = int(_pending_gameplay_transition.input_revision) + 1
		_pending_gameplay_transition.settling = false
	for action: String in InputProfile.ACTION_LABELS:
		if event.is_action(action):
			Input.action_release(action)
			_restore_other_held_keys(action, event)


func _restore_consumed_menu_release(event: InputEvent) -> void:
	var token := _menu_input_token(event)
	if token.is_empty() or event.is_pressed() or not _consumed_menu_inputs.has(token): return
	var consumed: InputEvent = _consumed_menu_inputs[token]
	_consumed_menu_inputs.erase(token)
	# Godot releases the action when either binding releases. A paired menu
	# release must preserve a keyboard hold that existed independently of it.
	for action: String in InputProfile.ACTION_LABELS:
		if consumed.is_action(action): _restore_other_held_keys(action, consumed)
	_arm_gameplay_transition()


func _restore_other_held_keys(action: String, consumed: InputEvent) -> void:
	for binding: InputEvent in InputMap.action_get_events(action):
		if not binding is InputEventKey or binding.is_match(consumed): continue
		var held: bool = Input.is_physical_key_pressed(binding.physical_keycode) if binding.physical_keycode != 0 \
			else Input.is_key_pressed(binding.keycode)
		if held:
			Input.action_press(action)
			return


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_consumed_menu_inputs.clear()
		_pending_gameplay_transition.clear()


func _menu_controller_connection_changed(device: int, connected: bool) -> void:
	if connected: return
	_pending_gameplay_transition.clear()
	for token: String in _consumed_menu_inputs.keys():
		if token.begins_with("pad:%d:" % device): _consumed_menu_inputs.erase(token)


func _show_page(page: String, focus_token: String = "", scroll_position: int = 0) -> void:
	# Rebuilding the current page (for example after rebinding) keeps its place.
	if page == _page and focus_token.is_empty():
		focus_token = _focused_token()
		scroll_position = _scroll.scroll_vertical if is_instance_valid(_scroll) else 0
	_page = page
	_page_revision += 1
	_pending_gameplay_transition.clear()
	_binding_action = ""
	_modal.visible = true
	_focus_first = null
	_music_controls.clear()
	_music_playlist_rows.clear()
	for child in _modal.get_children():
		_modal.remove_child(child)
		child.queue_free()
	_dialog = _card(true)
	_dialog.modulate.a = 0.0
	_modal.add_child(_dialog)
	var box := _vbox(_dialog, 12)
	_label(box, "TAM HAWKS PRO SKATER  /  GLASGOW", 12, ACCENT)
	_modal_title = _label(box, "", 35, PAPER)
	_modal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_modal_details = _label(box, "", 17, MUTED)
	_modal_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_details.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_modal_details.custom_minimum_size.y = 42
	_modal_warning = _label(box, str(_state.get("save_warning", "")), 14, ORANGE)
	_modal_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_warning.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_modal_warning.visible = not _modal_warning.text.is_empty()
	_modal_notice = _label(box, str(_state.get("feedback", "")), 14, ACCENT)
	_modal_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_notice.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_modal_notice.visible = not _modal_notice.text.is_empty() and page != "title"
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	box.add_child(_scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	_scroll.add_child(content)
	match page:
		"title": _build_title(content)
		"pause": _build_pause(content, false)
		"results": _build_pause(content, true)
		"goals": _build_goals(content)
		"map": _build_map(content)
		"settings": _build_settings(content)
		"controls": _build_controls(content)
		"tricks": _build_trick_guide(content)
		"soundtrack": _build_soundtrack(content)
	_update_music_controls()
	if page not in ["title", "pause", "results"]:
		_button(box, "BACK", _back)
	_relayout(true)
	_restore_page_focus.call_deferred(_page_revision, focus_token, scroll_position)
	_hud.visible = page != "title"


func _focus_control(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
		control.grab_focus()


func _build_title(content: VBoxContainer) -> void:
	_modal_title.text = "Your city. Your line."
	_modal_title.add_theme_font_size_override("font_size", 45)
	_modal_title.custom_minimum_size.y = 59
	_modal_details.text = "City terraces. Riverside transfers. Park descents. Find your line."
	var art := PanelContainer.new()
	var art_style := _style(Color("243e3f"), 10)
	art_style.content_margin_left = 18
	art_style.content_margin_right = 18
	art_style.content_margin_top = 14
	art_style.content_margin_bottom = 14
	art.add_theme_stylebox_override("panel", art_style)
	art.custom_minimum_size.y = 100
	content.add_child(art)
	var intro := _vbox(art, 6)
	_label(intro, "TWO MINUTES. MAKE THEM COUNT.", 24, ACCENT).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(intro, "Link tricks, explore the city and work through ten career goals.", 17, PAPER).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(content, "START CAREER RUN", func(): _start_mode(false))
	_button(content, "FREE SKATE", func(): _start_mode(true))
	_button(content, "SOUNDTRACK", show_soundtrack)
	_button(content, "SETTINGS", func(): _open_subpage("settings"))
	_button(content, "CONTROLS", func(): _open_subpage("controls"))
	_button(content, "PLAYTEST RECORDER  ·  2", func(): debug_requested.emit())
	_label(content, "Play with a controller or keyboard. Your city is ready.", 14, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _build_pause(content: VBoxContainer, finished: bool) -> void:
	_modal_title.text = "That's yer lot." if finished else "Take a breather."
	_modal_details.text = "RUN  %s     BEST COMBO  %s" % [_number(int(_state.get("score", 0))), _number(int(_state.get("best", 0)))]
	if finished:
		var records := _card()
		content.add_child(records)
		var rows := _vbox(records, 5)
		_label(rows, "YOUR PERSONAL BESTS", 13, ACCENT)
		_label(rows, "Run  %s     Combo  %s" % [_number(int(_state.get("record_score", 0))), _number(int(_state.get("record_combo", 0)))], 23, PAPER)
		_label(rows, str(_state.get("save_status", "")), 14, MUTED)
	else:
		_resume = _button(content, "BACK TO THE BOARD", _resume_run)
	_build_music_card(content)
	_button(content, "SOUNDTRACK", show_soundtrack)
	_restart = _button(content, "ONE MORE RUN" if finished else "RESTART RUN", _restart_run)
	if finished: _focus_first = _restart
	_button(content, "CITY MAP & ROUTES", show_map)
	_button(content, "GOALS & UNLOCKS", toggle_goals)
	_button(content, "SETTINGS", func(): _open_subpage("settings"))
	_button(content, "CONTROLS", func(): _open_subpage("controls"))
	_free = _button(content, "START CAREER RUN" if _state.get("free_skate", false) else "SWITCH TO FREE SKATE", _switch_mode)
	_button(content,"TRICK GUIDE",show_trick_guide)


func _build_goals(content: VBoxContainer) -> void:
	_modal_title.text = "A good day's skating."
	_modal_details.text = "Your career goals, rewards and personal progress." if not _state.get("free_skate", false) else "Explore freely. Career goals and records advance in career runs."
	_button(content, "CITY MAP & ROUTES", show_map)
	var side_hint := _label(content, "SIDE CHALLENGES  /  Mo plays by the Exchange fountain. Find Rae’s bin drums and dancing cats in George Square, or Mairi’s delivery stall by Barrowland.", 14, MUTED)
	side_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_hint.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	for goal: Dictionary in _state.get("goals", []):
		var card := _card()
		card.focus_mode = Control.FOCUS_ALL
		card.set_meta("focus_token", "goal:" + str(goal.get("id", goal.get("title", "Goal"))))
		var focus_style := card.get_theme_stylebox("panel") as StyleBoxFlat
		card.focus_entered.connect(func(): focus_style.border_color = ACCENT; focus_style.set_border_width_all(2))
		card.focus_exited.connect(func(): focus_style.border_color = Color("294247"); focus_style.set_border_width_all(1))
		if _focus_first == null: _focus_first = card
		content.add_child(card)
		var row := _vbox(card, 5)
		var done: bool = goal.get("done", false)
		_label(row, ("✓  " if done else "○  ") + str(goal.get("title", "Goal")), 21, ACCENT if done else PAPER).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var detail := _label(row, str(goal.get("detail", "")), 16, MUTED)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		var progress := _progress(row, ACCENT)
		progress.value = float(goal.get("progress", 0)) / maxf(1.0, float(goal.get("target", 1)))
		_label(row, "COMPLETE" if done else "%s / %s" % [_number(int(goal.get("progress", 0))), _number(int(goal.get("target", 1)))], 13, MUTED)
	_label(content, "MAKE IT YOURS", 19, ACCENT)
	var unlocks: Array = _state.get("unlocks", ["color_blue"])
	for item in [["color_blue", "CLYDE BLUE"], ["color_orange", "CONE ORANGE  /  FIRST SHIFT"], ["color_purple", "NIGHT PURPLE  /  SOME SHIFT"]]:
		var id: String = item[0]
		var owned := unlocks.has(id)
		var selected := str(_settings.get("cosmetic_id", "color_blue")) == id
		var button := _button(content, ("✓  " if selected else "") + str(item[1]) + ("" if owned else "  ·  LOCKED"), func():
			_settings["cosmetic_id"] = id
			cosmetic_selected.emit(id)
			_show_page("goals"))
		button.disabled = not owned
	for item in [["special_clyde_carousel", "Clyde Carousel"], ["special_tenement_tumble", "Tenement Tumble"]]:
		_label(content, ("UNLOCKED  " if unlocks.has(item[0]) else "LOCKED  ") + str(item[1]), 16, MUTED)


func _build_map(content: VBoxContainer) -> void:
	_modal_title.text = "Find your next line."
	_modal_details.text = "You are in " + str(_state.get("location", "Glasgow")) + ". Explore the city, river and park."
	var map := RouteMap.new()
	map.custom_minimum_size = Vector2(0, 360)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_availability = _label(content,"",16,ACCENT)
	_map_availability.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_availability.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	content.add_child(map)
	_active_route_map = map
	_refresh_route_map()
	for row: Array in [
		["PALE SOLID  /  OPEN ROUTES     DIM DASHES  /  CLOSED     ORANGE  /  JUMP LINE", 13, MUTED],
		["Gallery steps & fountain → station platforms → hilly park paths. Follow the south quay to the Clyde bridge transfer.", 16, PAPER],
		["SUNKEN SKATEPARK  /  Follow the park climb to the summit link. The diamond marks its east entrance: roll down to the street basin, then choose the shallow or deep bowl.", 16, PAPER],
		["Career goals are in the four city districts. Meet Mo by the Exchange fountain, or Rae’s bin drums and dancing cats in George Square, or Mairi’s parcel challenge through the Barras. Free skate gives you time to explore.", 14, MUTED],
	]:
		var description := _label(content, row[0], row[1], row[2])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING



func _build_settings(content: VBoxContainer) -> void:
	_modal_title.text = "Your kind of session."
	_modal_details.text = "Sound, readability and camera comfort. Changes take effect immediately."
	_button(content, "SOUNDTRACK", show_soundtrack)
	_slider(content, "Master volume", "audio", 0.0, 1.0, 0.05, 0.8)
	_slider(content, "Skating & voice", "sfx_volume", 0.0, 1.0, 0.05, 1.0)
	_slider(content, "City ambience", "ambience_volume", 0.0, 1.0, 0.05, 0.6)
	_slider(content, "Interface size", "ui_scale", 1.0, 1.4, 0.1, 1.0)
	_slider(content, "Camera sensitivity", "camera_sensitivity", 0.5, 2.0, 0.1, 1.0)
	_toggle(content, "Show captions", "captions", true)
	_toggle(content, "Reduce motion & camera shake", "reduced_motion", false)
	var quality := _button(content, "", func(): pass)
	quality.set_meta("focus_token", "setting:graphics_quality")
	var update_quality := func(): quality.text = "GRAPHICS: " + GraphicsQuality.LABELS[GraphicsQuality.normalized(_settings.get("graphics_quality", "balanced"))]
	update_quality.call()
	quality.pressed.connect(func():
		var current := GraphicsQuality.IDS.find(GraphicsQuality.normalized(_settings.get("graphics_quality", "balanced")))
		_change_setting("graphics_quality", GraphicsQuality.IDS[(current + 1) % GraphicsQuality.IDS.size()])
		update_quality.call())
	var quality_help := _label(content, "Choose Performance for a lighter scene, Balanced for sharper nearby detail, or High for longer shadows.", 15, MUTED)
	quality_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quality_help.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_button(content, "CONTROLS", show_controls)


func _build_music_card(parent: Node) -> void:
	var card := _card()
	parent.add_child(card)
	var box := _vbox(card, 8)
	_music_controls["badge"] = _label(box, "APPLE MUSIC", 12, ACCENT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var sleeve := PanelContainer.new()
	sleeve.custom_minimum_size = Vector2(94, 94)
	sleeve.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sleeve.add_theme_stylebox_override("panel", _style(TRACK, 7))
	row.add_child(sleeve)
	var artwork := TextureRect.new()
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sleeve.add_child(artwork)
	_music_controls["artwork"] = artwork
	var fallback := _label(sleeve, "♪", 42, ACCENT)
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_music_controls["fallback"] = fallback
	var info := _vbox(row, 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for field: String in ["title", "artist", "album"]:
		var label := _label(info, "", 22 if field == "title" else (16 if field == "artist" else 14), PAPER if field == "title" else MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.max_lines_visible = 2
		_music_controls[field] = label
	var transport := HBoxContainer.new()
	transport.add_theme_constant_override("separation", 10)
	box.add_child(transport)
	for item: Array in [["toggle", "PLAY"], ["next", "SKIP TRACK  →"]]:
		var action := str(item[0])
		var button := _button(transport, str(item[1]), func(): music_requested.emit(action, ""))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("focus_token", "music:" + action)
		_music_controls[action] = button


func _build_soundtrack(content: VBoxContainer) -> void:
	_modal_title.text = "Set the session soundtrack."
	_modal_details.text = "Shuffle a playlist from the Music app on your Mac."
	var music: Dictionary = _state.get("music", {})
	var has_default := not str(music.get("default_playlist_name", "")).is_empty() and not str(music.get("default_playlist_url", "")).is_empty()
	if has_default:
		var default_name := str(music.default_playlist_name)
		var curator := str(music.get("default_playlist_curator", ""))
		var default_label := _label(content, "Default: " + default_name + (" · " + curator if not curator.is_empty() else ""), 17, ACCENT)
		default_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		default_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		_music_controls["default_label"] = default_label
		_music_controls["open_default"] = _button(content, "OPEN DEFAULT PLAYLIST IN MUSIC", func(): music_requested.emit("open_default", ""))
		_music_controls.open_default.set_meta("focus_token", "music:open_default")
	_build_music_card(content)
	_music_controls["status"] = _label(content, "", 15, ACCENT)
	_music_controls.status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_music_controls.status.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	var setup_text := "Open the default playlist in Music and add it to your library once. Connect or refresh playlists here, allow Automation access, then start skating to autoplay. You can choose another library playlist below. Streaming uses your Apple Music subscription." if has_default else "Sign into Music and add your playlist to its library. Connect here, then allow macOS to control Music. Streaming uses your Apple Music subscription."
	var instructions := _label(content, setup_text, 15, MUTED)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_music_controls["connect"] = _button(content, "CONNECT TO MUSIC", func(): music_requested.emit("connect", ""))
	_music_controls.connect.set_meta("focus_token", "music:connect")
	var caption := _label(content, "YOUR LIBRARY PLAYLIST", 13, ACCENT)
	caption.custom_minimum_size.y = 21
	var playlist := OptionButton.new()
	playlist.custom_minimum_size.y = 48
	playlist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playlist.fit_to_longest_item = false
	playlist.allow_reselect = true
	playlist.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	playlist.set_meta("focus_token", "music:playlist")
	content.add_child(playlist)
	playlist.item_selected.connect(func(index: int):
		music_requested.emit("select", str(playlist.get_item_metadata(index)))
		ui_feedback.emit())
	_music_controls["playlist"] = playlist
	_music_controls["play"] = _button(content, "SHUFFLE & PLAY PLAYLIST", func(): music_requested.emit("play", ""))
	_music_controls.play.set_meta("focus_token", "music:play")
	var autoplay := CheckButton.new()
	autoplay.text = "Play automatically when I start skating"
	autoplay.custom_minimum_size.y = 48
	autoplay.set_meta("focus_token", "music:autoplay")
	content.add_child(autoplay)
	autoplay.toggled.connect(func(value: bool):
		music_requested.emit("enable", "true" if value else "false")
		ui_feedback.emit())
	_music_controls["autoplay"] = autoplay
	var detail := _label(content, "Music keeps playing while the game is paused. Adjust its volume in Music; the game’s audio sliders control skating and city sounds.", 14, MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_music_controls["refresh"] = _button(content, "REFRESH PLAYLISTS", func(): music_requested.emit("refresh", ""))
	_music_controls.refresh.set_meta("focus_token", "music:refresh")
	_music_controls["disconnect"] = _button(content, "DISCONNECT MUSIC", func(): music_requested.emit("disconnect", ""))
	_music_controls.disconnect.set_meta("focus_token", "music:disconnect")
	# Opening setup starts on its connection control rather than a disabled
	# transport button. Polls update controls in place and retain this focus.
	_focus_first = null
	if bool(music.get("supported", false)) and not bool(music.get("busy", false)):
		if not bool(music.get("connected", false)):
			_focus_first = _music_controls.open_default if has_default else _music_controls.connect
		elif not music.get("playlists", []).is_empty():
			_focus_first = playlist
		else:
			_focus_first = _music_controls.refresh


func _update_music_controls() -> void:
	if _music_controls.is_empty(): return
	var music: Dictionary = _state.get("music", {})
	var supported := bool(music.get("supported", false))
	var connected := supported and bool(music.get("connected", false))
	var playing := connected and bool(music.get("playing", false))
	var title := str(music.get("title", ""))
	var has_track := connected and not title.is_empty()
	_music_controls.badge.text = ("NOW PLAYING" if playing else "PAUSED") + "  /  APPLE MUSIC" if playing or has_track else "YOUR SOUNDTRACK  /  APPLE MUSIC"
	if has_track:
		_music_controls.title.text = title
		_music_controls.artist.text = str(music.get("artist", ""))
	elif playing:
		_music_controls.title.text = "Music is playing."
		_music_controls.artist.text = "Track details unavailable. Add these songs to your Music library."
	else:
		_music_controls.title.text = "Choose your skate playlist." if connected else ("Music is not connected." if supported else "Apple Music on your Mac.")
		_music_controls.artist.text = "Select a playlist, then shuffle & play." if connected else str(music.get("status", "Connect in Soundtrack to get started."))
	# A selected playlist is a preference, not evidence of the actual current
	# playback source. Do not substitute it for missing track metadata.
	_music_controls.album.text = str(music.get("album", "")) if has_track else ""
	var texture: Texture2D = music.get("artwork") as Texture2D if connected else null
	_music_controls.artwork.texture = texture
	_music_controls.fallback.visible = texture == null
	_music_controls.toggle.text = "PAUSE MUSIC" if playing else "PLAY MUSIC"
	_music_controls.toggle.disabled = not connected or not (playing or has_track)
	_music_controls.next.disabled = not connected or not (playing or has_track)
	if not _music_controls.has("playlist"): return
	if _music_controls.has("open_default"):
		_music_controls.open_default.disabled = not supported
	_music_controls.status.text = str(music.get("status", "Connect to the Music app to choose a playlist.")) if supported else "Apple Music playback is available when you run this game on macOS."
	_music_controls.connect.disabled = not supported or connected or bool(music.get("busy", false))
	_music_controls.connect.text = "MUSIC CONNECTED" if connected else ("CONNECTING…" if bool(music.get("busy", false)) else "CONNECT TO MUSIC")
	_music_controls.refresh.disabled = not connected or bool(music.get("busy", false))
	_music_controls.disconnect.disabled = not connected
	_music_controls.play.disabled = not connected or str(music.get("playlist_id", "")).is_empty()
	_music_controls.autoplay.disabled = not supported
	_music_controls.autoplay.set_pressed_no_signal(bool(music.get("enabled", false)))
	var rows: Array = music.get("playlists", [])
	var picker: OptionButton = _music_controls.playlist
	if rows != _music_playlist_rows or picker.item_count == 0:
		_music_playlist_rows = rows.duplicate(true)
		picker.clear()
		if rows.is_empty():
			picker.add_item("Connect to load your playlists" if not connected else "No playlists found in Music")
		else:
			for entry: Dictionary in rows:
				picker.add_item(str(entry.get("name", "Playlist")))
				picker.set_item_metadata(picker.item_count - 1, str(entry.get("id", "")))
	picker.disabled = not connected or rows.is_empty()
	var selected_id := str(music.get("playlist_id", ""))
	var found_selection := false
	for index: int in range(picker.item_count):
		if str(picker.get_item_metadata(index)) == selected_id:
			picker.select(index)
			found_selection = true
			break
	if not rows.is_empty() and not found_selection:
		# Adding the first item selects it visually without emitting a user
		# selection. Keep the picker honest until a playlist is actually chosen.
		picker.select(-1)
		picker.text = "Choose playlist…"


func _build_controls(content: VBoxContainer) -> void:
	_modal_title.text = "Make every button count."
	_modal_details.text = "Choose an action, then press a key, controller button or trigger. Escape cancels."
	_binding_status = _label(content, "Controller prompts follow your saved bindings.", 15, ACCENT)
	_binding_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_binding_status.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	var trick_help := _label(content, "Hold Ollie to crouch; release to pop. Direction + Flip / Grab selects a trick. Hold grabs.\nTap Grind to lock a rail; tap again to drop. Hold Grind at quarter-pipe coping for a lip trick.\nManual + Up selects Nose Manual. D-pad or stick Up–neutral–Down starts Manual; Down–neutral–Up starts Nose Manual.\nBalance manuals, rails and lips with Left/Right. Turn manuals with %s / %s.\nAir left/right spins the skater; shoulders spin too. Specials: %s / %s. Interact: %s. Quarter/half-pipe: Clyde quay." % [_prompt_for("spin_left", "Q"), _prompt_for("spin_right", "E"), _prompt_for("special_one", "U"), _prompt_for("special_two", "I"), _prompt_for("interact", "X")], 15, PAPER)
	trick_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trick_help.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	if not ResourceLoader.exists("res://game/core/input_profile.gd"):
		_label(content, "WASD skate · Space ollie · J/K tricks · L grind · M manual\nQ/E spin · Escape pause · R restart · Tab goals", 18, PAPER)
		return
	_input_profile = load("res://game/core/input_profile.gd")
	for row: Dictionary in _input_profile.binding_snapshot():
		var action: String = row.action
		var button := _button(content, "%s  /  %s  ·  %s" % [row.label, row.key_text, row.pad_text], func():
			_binding_action = action
			_binding_status.text = "LISTENING: " + str(row.label) + "  —  press an input, or Escape to cancel.")
		button.set_meta("focus_token", "binding:" + action)
	_button(content, "RESTORE DEFAULT CONTROLS", func():
		_change_setting("bindings", _input_profile.reset_defaults())
		_show_page("controls"))
	_button(content,"TRICK GUIDE",show_trick_guide)


func _slider(parent: Node, title: String, key: String, minimum: float, maximum: float, step: float, fallback: float) -> void:
	var panel := _card()
	parent.add_child(panel)
	var box := _vbox(panel, 8)
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := _label(row, title, 18, PAPER)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label := _label(row, "", 17, ACCENT)
	value_label.custom_minimum_size.x = 80
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = float(_settings.get(key, fallback))
	slider.custom_minimum_size.y = 28
	slider.focus_mode = Control.FOCUS_ALL
	slider.set_meta("focus_token", "setting:" + key)
	box.add_child(slider)
	value_label.text = "%.1f×" % slider.value if key in ["ui_scale", "camera_sensitivity"] else "%d%%" % roundi(slider.value * 100.0)
	slider.value_changed.connect(func(value: float):
		value_label.text = "%.1f×" % value if key in ["ui_scale", "camera_sensitivity"] else "%d%%" % roundi(value * 100.0)
		_change_setting(key, value))
	if _focus_first == null: _focus_first = slider


func _toggle(parent: Node, title: String, key: String, fallback: bool) -> void:
	var button := CheckButton.new()
	button.text = title
	button.button_pressed = bool(_settings.get(key, fallback))
	button.set_meta("focus_token", "setting:" + key)
	button.custom_minimum_size.y = 48
	parent.add_child(button)
	button.toggled.connect(func(value: bool): _change_setting(key, value); ui_feedback.emit())
	if _focus_first == null: _focus_first = button


func _change_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	if key == "bindings":
		_binding_rows.clear()
		_prompt_texts.clear()
	settings_changed.emit({key: value})
	_relayout()


func _open_subpage(page: String) -> void:
	if page == _page: return
	var live := _page.is_empty() and not bool(_state.get("paused", false)) and not bool(_state.get("finished", false))
	var origin := _page
	if origin.is_empty() and not live:
		origin = "results" if _state.get("finished", false) else "pause"
	_navigation.append({"page": origin, "focus": _focused_token(), "resume": live,
		"scroll": _scroll.scroll_vertical if is_instance_valid(_scroll) else 0})
	if live: pause_requested.emit()
	_show_page(page)


func _back() -> void:
	if not _pending_gameplay_transition.is_empty(): return
	if not _navigation.is_empty():
		var origin: Dictionary = _navigation.back()
		if str(origin.page).is_empty():
			if origin.get("resume", false): _resume_run()
			else: _hide_modal()
		else:
			_navigation.pop_back()
			_show_page(str(origin.page), str(origin.focus), int(origin.scroll))
	elif _page == "pause":
		_resume_run()


func _focused_token() -> String:
	var focused := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused) and _modal.is_ancestor_of(focused):
		return str(focused.get_meta("focus_token", ""))
	return ""


func _restore_page_focus(revision: int, token: String, scroll_position: int) -> void:
	# Wrapped labels briefly report their height at zero width during container
	# creation. Fit the dialog after its first layout, then restore visible focus.
	await get_tree().process_frame
	if _page_revision != revision or _page.is_empty(): return
	_relayout(true)
	await get_tree().process_frame
	if _page_revision != revision or _page.is_empty(): return
	_dialog.modulate.a = 1.0
	var target := _find_focus_token(_dialog, token) if not token.is_empty() else null
	if not is_instance_valid(target): target = _focus_first
	if is_instance_valid(_scroll): _scroll.scroll_vertical = scroll_position
	_focus_control(target)
	if is_instance_valid(target) and _scroll.is_ancestor_of(target):
		_scroll.ensure_control_visible(target)


func _find_focus_token(node: Node, token: String) -> Control:
	if node is Control and str(node.get_meta("focus_token", "")) == token: return node
	for child in node.get_children():
		var found := _find_focus_token(child, token)
		if found != null: return found
	return null


func _resume_run() -> void:
	_queue_gameplay_transition("resume")


func _restart_run() -> void:
	_queue_gameplay_transition("restart")


func _switch_mode() -> void:
	_queue_gameplay_transition("switch")


func _start_mode(free: bool) -> void:
	_queue_gameplay_transition("start", free)


func _queue_gameplay_transition(kind: String, free: bool = false) -> void:
	if debug_input_blocked or _page.is_empty() or not _pending_gameplay_transition.is_empty(): return
	_gameplay_transition_serial += 1
	_pending_gameplay_transition = {"serial": _gameplay_transition_serial, "page": _page,
		"revision": _page_revision, "kind": kind, "free": free,
		"input_revision": 0, "settling": false,
		"paused": bool(_state.get("paused", false)), "finished": bool(_state.get("finished", false))}
	_arm_gameplay_transition()


func _arm_gameplay_transition() -> void:
	if _pending_gameplay_transition.is_empty(): return
	var serial := int(_pending_gameplay_transition.serial)
	if not _gameplay_transition_valid(serial):
		_cancel_gameplay_transition(serial)
		return
	# Resume on release. Its restoration of another held binding can create
	# native action edges too; those must expire while gameplay is still paused.
	if not _consumed_menu_inputs.is_empty() or bool(_pending_gameplay_transition.settling): return
	_pending_gameplay_transition.settling = true
	# A rendered frame can precede the next physics tick. Keep the modal and
	# pause in place through a physics pass, then dispatch during idle.
	var input_revision := int(_pending_gameplay_transition.input_revision)
	var receiver: WeakRef = weakref(self)
	get_tree().physics_frame.connect(func() -> void:
		var hud: Node = receiver.get_ref()
		if is_instance_valid(hud) and not hud.is_queued_for_deletion():
			hud._settle_gameplay_transition(serial, input_revision)
	, CONNECT_ONE_SHOT)


func _gameplay_transition_valid(serial: int) -> bool:
	return not _pending_gameplay_transition.is_empty() and int(_pending_gameplay_transition.serial) == serial \
		and is_inside_tree() and not is_queued_for_deletion() and not debug_input_blocked \
		and visible and is_instance_valid(_modal) and _modal.visible and not _page.is_empty() \
		and _page == str(_pending_gameplay_transition.page) and _page_revision == int(_pending_gameplay_transition.revision) \
		and bool(_state.get("paused", false)) == bool(_pending_gameplay_transition.paused) \
		and bool(_state.get("finished", false)) == bool(_pending_gameplay_transition.finished)


func _settle_gameplay_transition(serial: int, input_revision: int) -> void:
	if not _gameplay_transition_valid(serial):
		_cancel_gameplay_transition(serial)
		return
	if input_revision != int(_pending_gameplay_transition.input_revision) or not _consumed_menu_inputs.is_empty(): return
	var receiver: WeakRef = weakref(self)
	get_tree().process_frame.connect(func() -> void:
		var hud: Node = receiver.get_ref()
		if is_instance_valid(hud) and not hud.is_queued_for_deletion():
			hud._finish_gameplay_transition(serial, input_revision)
	, CONNECT_ONE_SHOT)


func _cancel_gameplay_transition(serial: int) -> void:
	if not _pending_gameplay_transition.is_empty() and int(_pending_gameplay_transition.serial) == serial:
		_pending_gameplay_transition.clear()


func _finish_gameplay_transition(serial: int, input_revision: int) -> void:
	if not _gameplay_transition_valid(serial):
		_cancel_gameplay_transition(serial)
		return
	if input_revision != int(_pending_gameplay_transition.input_revision) or not _consumed_menu_inputs.is_empty(): return
	var transition := _pending_gameplay_transition.duplicate()
	_hide_modal()
	match str(transition.kind):
		"resume": pause_requested.emit()
		"restart": restart_requested.emit()
		"switch": free_skate_requested.emit()
		"start": start_requested.emit(bool(transition.free))


func _hide_modal() -> void:
	_page_revision += 1
	_pending_gameplay_transition.clear()
	_page = ""
	_binding_action = ""
	_modal.visible = false
	_hud.visible = true
	_navigation.clear()


func _relayout(force: bool = false) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var preference := clampf(float(_settings.get("ui_scale", 1.0)), 1.0, 1.4)
	if not force and viewport_size == _last_size and preference == _last_scale: return
	_last_size = viewport_size
	_last_scale = preference
	var scale_factor := minf(viewport_size.x / 1440.0, viewport_size.y / 900.0) * preference
	scale_factor = maxf(0.1, scale_factor)
	_root.scale = Vector2.ONE * scale_factor
	_root.size = viewport_size / scale_factor
	var extent := _root.size
	_hud.size = extent
	if is_instance_valid(_recovery_layer):
		_recovery_layer.size = extent
		_recovery_caption.position = Vector2(28,extent.y*0.43)
		_recovery_caption.size = Vector2(extent.x-56,64)
	_top.position = Vector2(28, 24)
	_top.size = Vector2(extent.x - 56, 96)
	_score_card.position = Vector2.ZERO
	_score_card.size = Vector2(248, 76)
	_timer_card.position = Vector2((extent.x - 56) * .5 - 74, 0)
	_timer_card.size = Vector2(148, 82)
	var side_width := minf(345.0, (extent.x - 412.0) * 0.5)
	_goals.position = Vector2(extent.x - side_width - 28, 126)
	_goals.size = Vector2(side_width, 28)
	_balance_panel.position = Vector2(extent.x * 0.5 - 158, 132)
	_balance_panel.size = Vector2(316, 76)
	_save_warning.position = Vector2(28, extent.y - 288)
	_save_warning.size = Vector2(180, 84)
	_special_panel.position = Vector2(28, 106)
	_special_panel.size = Vector2(248, 76)
	for label in [_combo, _tricks, _combo_status, _caption, _prompt, _challenge]:
		label.position.x = 224
		label.size.x = extent.x - 480
	_combo.position.y = extent.y - 264
	_combo.size.y = 48
	_tricks.position.y = extent.y - 211
	_tricks.size.y = 48
	_combo_status.position.y = extent.y - 160
	_combo_status.size.y = 40
	_caption.position.y = extent.y - 116
	_caption.size.y = 48
	_prompt.position.y = extent.y - 304
	_prompt.size.y = 36
	# Event notices have their own space, so a live combo cannot replace them.
	var notice_width := minf(440.0, extent.x - 56)
	_feedback_panel.position = Vector2(28, 192)
	_feedback_panel.size = Vector2(notice_width, 52)
	if is_instance_valid(_modal): _modal.size = extent
	if is_instance_valid(_dialog):
		var dialog_width := minf(850, extent.x - 96)
		var preferred_height := 660.0 if _page == "title" else (640.0 if _page == "pause" else 750.0)
		var dialog_height := minf(preferred_height, extent.y - 76)
		_dialog.position = (extent - Vector2(dialog_width, dialog_height)) * 0.5
		_dialog.size = Vector2(dialog_width, dialog_height)
	_layout_feedback_stack(true)
	_layout_visibility_revision += 1
	_queue_focused_visibility()


func _queue_focused_visibility() -> void:
	if _layout_visibility_pending or _page.is_empty() or not is_inside_tree() \
			or is_queued_for_deletion() or not is_instance_valid(_scroll): return
	_layout_visibility_pending = true
	get_tree().process_frame.connect(_settle_focused_visibility.bind(
		_page_revision, _layout_visibility_revision, _scroll.get_instance_id(), 1), CONNECT_ONE_SHOT)


func _settle_focused_visibility(page_revision: int, layout_revision: int, scroll_instance_id: int, remaining_frames: int) -> void:
	# follow_focus reacts to focus changes. A resize can clip an already focused
	# child, so let wrapping/container sorts settle before revealing it again.
	if not is_inside_tree() or is_queued_for_deletion():
		_layout_visibility_pending = false
		return
	if remaining_frames > 0:
		# One-shot connections are disconnected with this HUD on teardown; there
		# is no suspended coroutine retaining arguments after a menu is freed.
		get_tree().process_frame.connect(_settle_focused_visibility.bind(
			page_revision, layout_revision, scroll_instance_id, remaining_frames - 1), CONNECT_ONE_SHOT)
		return
	_layout_visibility_pending = false
	if page_revision != _page_revision or layout_revision != _layout_visibility_revision:
		_queue_focused_visibility()
		return
	var scroll := instance_from_id(scroll_instance_id) as ScrollContainer
	if not is_instance_valid(scroll) or scroll != _scroll or not scroll.is_inside_tree(): return
	var focused := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused) and scroll.is_ancestor_of(focused) and focused.is_visible_in_tree():
		scroll.ensure_control_visible(focused)
		# Leave real space for the focus border and fractional-scale rasterization.
		# Exact edge alignment can round outside the clip even after integer repair.
		var local_rect := scroll.get_global_transform().affine_inverse() * focused.get_global_rect()
		var height := scroll.size.y
		var horizontal_bar := scroll.get_h_scroll_bar()
		if horizontal_bar.is_visible_in_tree(): height -= horizontal_bar.size.y
		var padding := minf(FOCUS_REVEAL_PADDING, maxf(0.0, (height - local_rect.size.y) * 0.5))
		if local_rect.end.y > height - padding:
			scroll.scroll_vertical += ceili(local_rect.end.y - height + padding)
		elif local_rect.position.y < padding:
			scroll.scroll_vertical -= ceili(padding - local_rect.position.y)


func _layout_feedback_stack(force: bool = false) -> void:
	# Empty slots collapse and short lines use their actual height. Large UI
	# text stays near the bottom without reserving a second line for every cue.
	var labels := [_challenge, _caption, _combo_status, _tricks, _combo, _prompt]
	var texts: Array[String] = []
	for label: Label in labels: texts.append(label.text)
	if not force and texts == _feedback_layout_texts: return
	_feedback_layout_texts = texts
	var bottom := _root.size.y - 36.0
	for label: Label in labels:
		label.visible = not label.text.is_empty()
		if not label.visible: continue
		var lines := mini(label.get_line_count(), 1 if label == _combo else 2)
		var font: Font = label.get_theme_font("font")
		var height := ceilf(font.get_height(label.get_theme_font_size("font_size"))) * maxi(lines, 1)
		height += label.get_theme_constant("line_spacing") * maxi(lines - 1, 0)
		bottom -= height
		label.position.y = bottom
		label.size.y = height
		bottom -= 8.0


func _fit_line(label: Label, largest: int, smallest: int) -> void:
	if label.text == _score_fit_text and label.size.x == _score_fit_width: return
	_score_fit_text = label.text
	_score_fit_width = label.size.x
	var font := label.get_theme_font("font")
	var font_size := largest
	while font_size > smallest and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)


func _card(dialog: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _style(Color(INK, 0.94) if not dialog else PANEL, 10)
	style.content_margin_left = 28 if dialog else 16
	style.content_margin_right = 28 if dialog else 16
	style.content_margin_top = 24 if dialog else 12
	style.content_margin_bottom = 24 if dialog else 12
	style.border_color = Color("3e5758") if dialog else Color("294247")
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _vbox(parent: Node, separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box


func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size.y = ceilf(font_size * 1.3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label


func _floating_label(text: String, font_size: int, color: Color) -> Label:
	var label := _label(_hud, text, font_size, color)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", INK)
	return label


func _progress(parent: Node, color: Color) -> ProgressBar:
	var progress := ProgressBar.new()
	progress.max_value = 1.0
	progress.show_percentage = false
	progress.custom_minimum_size.y = 6
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", _style(TRACK, 3))
	progress.add_theme_stylebox_override("fill", _style(color, 3))
	parent.add_child(progress)
	return progress


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.set_meta("focus_token", text.trim_prefix("✓  "))
	button.custom_minimum_size.y = 48
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.pressed.connect(func(): ui_feedback.emit(); callback.call())
	parent.add_child(button)
	if _focus_first == null: _focus_first = button
	return button


func _make_theme() -> Theme:
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["DejaVu Sans", "Arial", "sans-serif"])
	theme.default_font = font
	theme.default_font_size = 18
	for kind in ["Button", "CheckButton", "Label"]:
		theme.set_color("font_color", kind, PAPER)
		theme.set_color("font_hover_color", kind, INK)
		theme.set_color("font_focus_color", kind, PAPER)
		theme.set_color("font_pressed_color", kind, INK)
		theme.set_color("font_disabled_color", kind, MUTED)
	for kind in ["Button", "CheckButton"]:
		var normal := _style(Color("20383c"), 7)
		normal.content_margin_left = 18
		normal.content_margin_right = 18
		normal.content_margin_top = 8
		normal.content_margin_bottom = 8
		theme.set_stylebox("normal", kind, normal)
		theme.set_stylebox("disabled", kind, _style(Color("172b30"), 7))
		var hover := normal.duplicate()
		hover.bg_color = ACCENT
		theme.set_stylebox("hover", kind, hover)
		theme.set_stylebox("pressed", kind, hover)
		var focus := _style(Color(0, 0, 0, 0), 7)
		focus.border_color = ACCENT
		focus.set_border_width_all(3)
		theme.set_stylebox("focus", kind, focus)
	return theme


func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style


func _pad() -> bool:
	return _controller_active


func _prompt_for(action: String, fallback: String) -> String:
	var cache_key := action + (":pad:" if _pad() else ":key:") + fallback
	if _prompt_texts.has(cache_key): return _prompt_texts[cache_key]
	if _binding_rows.is_empty() and ResourceLoader.exists("res://game/core/input_profile.gd"):
		_input_profile = load("res://game/core/input_profile.gd")
		for row: Dictionary in _input_profile.binding_snapshot(): _binding_rows[row.action] = row
	if _binding_rows.has(action):
		var text := str(_binding_rows[action].get("pad_text" if _pad() else "key_text", fallback))
		# In play, one primary binding is enough. Controls keeps every full name.
		var choices := text.split(" / ")
		text = choices[0]
		# The default directional profile makes D-pad the primary control while
		# retaining the stick. A custom single-axis binding still names itself.
		if _pad() and action in ["push","brake","steer_left","steer_right"]:
			for choice: String in choices:
				if choice.begins_with("D-pad "):
					text = choice
					break
		for pair in [["Left stick", "LS"], ["Right stick", "RS"], [" left", " ←"], [" right", " →"], [" up", " ↑"], [" down", " ↓"]]:
			text = text.replace(pair[0], pair[1])
		_prompt_texts[cache_key] = text if not text.is_empty() else fallback
		return _prompt_texts[cache_key]
	return fallback


func _number(value: int) -> String:
	var raw := str(maxi(value, 0))
	var result := ""
	for i in range(raw.length()):
		if i > 0 and (raw.length() - i) % 3 == 0: result += ","
		result += raw[i]
	return result


func show_trick_guide() -> void:
	_open_subpage("tricks")




func _route_location_hint(state: Dictionary) -> String:
	# A location cue never asks for Interact or displaces an active skating cue.
	for key: String in ["airborne","grinding","manual","manual_active","wallriding","transition_active",
		"lip_active","skitching","crouching","setup_active","bail_active","powersliding"]:
		if bool(state.get(key,false)): return ""
	if int(state.get("combo",0)) > 0: return ""
	var at: Vector3 = state.get("player_position",Vector3.INF)
	if not at.is_finite(): return ""
	for route: Dictionary in _map_routes:
		if str(route.get("map_kind","")) != "skatepark" or not route.get("enabled",true): continue
		if not route.get("map_marker") is Vector3: continue
		var entry: Vector3 = route.map_marker
		var points := PackedVector3Array(route.get("points",[]))
		var distance := INF
		for index in range(1,points.size()):
			if points[index-1].is_finite() and points[index].is_finite():
				distance = minf(distance,at.distance_to(Geometry3D.get_closest_point_to_segment(at,points[index-1],points[index])))
		if distance > 7.0 or not entry.is_finite(): continue
		var label := str(route.get("map_label","")).strip_edges()
		if label.is_empty(): continue
		return label + ("  /  East roll-in to street & bowls" if at.distance_to(entry) < 6.0 else "  /  Follow the summit link")
	return ""




func _refresh_route_map() -> void:
	# Keep stable bounds while availability changes. Closed paths get explicit
	# dashed geometry instead of being painted as ordinary bright connections.
	_active_route_map.configure(_map_checkpoints,_map_routes,
		_state.get("player_position",Vector3.ZERO),float(_state.get("player_heading",0.0)))
	var open: Array = []
	var closed: Array = []
	var labels: Array[String] = []
	for route: Dictionary in _map_routes:
		var enabled: bool = route.get("enabled",true)
		if enabled: open.append(route.duplicate(true))
		else: closed.append(route.duplicate(true))
		if route.has("enabled"):
			var title := str(route.get("label",route.get("id","Shortcut"))).to_upper()
			if not title.ends_with("OPEN") and not title.ends_with("CLOSED"):
				title += "  /  " + ("OPEN" if enabled else "CLOSED")
			labels.append(title)
	_active_route_map.routes = open
	_active_route_map.queue_redraw()
	var layer := _active_route_map.get_node_or_null("ClosedRoutes") as Control
	if layer == null:
		layer = Control.new()
		layer.name = "ClosedRoutes"
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_active_route_map.add_child(layer)
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.resized.connect(layer.queue_redraw)
		layer.draw.connect(_draw_closed_routes.bind(_active_route_map,layer))
	layer.set_meta("routes",closed)
	layer.queue_redraw()
	_map_availability.text = "   ·   ".join(labels)
	_map_availability.visible = not labels.is_empty()
	_map_availability.add_theme_color_override("font_color",ORANGE if not closed.is_empty() else ACCENT)




func _draw_closed_routes(map: Control, layer: Control) -> void:
	var font := ThemeDB.fallback_font
	for route: Dictionary in layer.get_meta("routes",[]):
		var points := PackedVector3Array(route.get("points",[]))
		for index in range(1,points.size()):
			var from: Vector2 = map.call("_map",points[index-1])
			var to: Vector2 = map.call("_map",points[index])
			layer.draw_dashed_line(from,to,Color("6b7f7c"),2.0,6.0)
		if points.size() > 1:
			var at: Vector2 = map.call("_map",points[points.size()/2])
			layer.draw_circle(at,5.0,Color("6b7f7c"))
			layer.draw_line(at-Vector2(3,3),at+Vector2(3,3),INK,1.5)
			layer.draw_line(at+Vector2(-3,3),at+Vector2(3,-3),INK,1.5)
			layer.draw_string(font,at+Vector2(9,-7),"CLOSED",HORIZONTAL_ALIGNMENT_LEFT,-1,12,MUTED)




func _build_trick_guide(content: VBoxContainer) -> void:
	_modal_title.text = "Your next trick."
	_modal_details.text = "Normal controls and advanced tap sequences, using your saved bindings."
	var directions := "%s forward · %s back · %s left · %s right" % [
		_prompt_for("push", "W"), _prompt_for("brake", "S"),
		_prompt_for("steer_left", "A"), _prompt_for("steer_right", "D")]
	_guide_card(content, "BUILD YOUR TRICK SET", [
		directions,
		"%d flips · %d grabs · %d grinds · %d manuals · %d lip tricks · %d specials" % [TrickCatalog.family_ids("flip").size(), TrickCatalog.family_ids("grab").size(), TrickCatalog.family_ids("grind").size(), TrickCatalog.family_ids("manual").size(), TrickCatalog.family_ids("lip").size(), TrickCatalog.family_ids("special").size()],
		"Hold %s to crouch and charge your ollie. Release to pop; a longer charge gives more height. Watch the charge percentage while crouching." % _prompt_for("ollie", "SPACE"),
		"While setting up, tap forward for Nollie or back for Boneless. Back + %s selects No Comply. Use a fresh direction tap to choose a setup." % _prompt_for("manual", "M"),
		"Brake + a hard left or right turn powerslides to scrub speed. Hold %s / %s in the air for frontside / backside spins." % [_prompt_for("spin_left", "Q"), _prompt_for("spin_right", "E")],
	])
	_guide_card(content, "AIR TRICKS & THE CATCH", [
		"For the advanced air set below, tap the same direction twice with a neutral release, then press Flip / Grab on the second tap within 0.30 seconds. Ordinary one-direction controls keep their normal tricks.",
		"Normal flips: neutral / left Kickflip, right Heelflip, up Frontside Shuvit, down Pop Shuvit, down-left Varial Flip, up-right Hardflip. Normal grabs include up-left Method.",
		"In the air, choose a direction and tap %s for a flip or hold %s for a grab. Your normal directional set stays available. Release a grab before the next flip." % [_prompt_for("flip", "J"), _prompt_for("grab", "K")],
		"Tap %s twice or three times quickly to upgrade any flip to its double or triple. Shove-its become 360 / 540 Shove-its. More rotations take longer to catch: leave room before landing." % _prompt_for("flip", "J"),
		"Double-tap %s during a grab to tweak it once. Forward bones it, back tucks it, right twists it and left extends it. The extra style increases that trick's points; it keeps the same multiplier entry." % _prompt_for("grab", "K"),
		"Let the board catch, then make a fresh press for the next trick. A press just before the catch can queue your next move; holding the button never repeats it.",
	])
	_guide_card(content, "RAILS, WALLS & TRANSITIONS", [
		"Catch a rail with %s: neutral / up / down requests 50-50, left / right requests a signed Boardslide. Balance with %s / %s; directions with %s / %s change to the expanded styles." % [_prompt_for("grind", "L"), _prompt_for("steer_left", "A"), _prompt_for("steer_right", "D"), _prompt_for("flip", "J"), _prompt_for("grab", "K")],
		"During a grind, press %s to pivot your facing 180° while keeping travel along the rail. It changes stance, costs some speed and adds one trick. Make a fresh press after the cooldown for another pivot." % _prompt_for("revert", "C"),
		"Tap %s again to leave a locked rail, or hold and release %s to ollie into your next trick." % [_prompt_for("grind", "L"), _prompt_for("ollie", "SPACE")],
		"In the air beside a wall, hold %s to wallride. Hold and release %s for a Wallie away from the wall, or release %s to drop off." % [_prompt_for("grind", "L"), _prompt_for("ollie", "SPACE"), _prompt_for("grind", "L")],
		"Carry speed up curved transitions. Hold %s near the lip to stall, then release it to drop back in. Keep your balance with left / right." % _prompt_for("grind", "L"),
		"In vert air, release your approach input, then tap forward to transfer over the deck or back to move outward. Left / right adjusts your line. Holding forward through the ramp keeps the normal vertical return.",
	])
	_guide_card(content, "LIP TRICKS & HANDPLANTS", [
		"On the original Clyde transitions, hold %s at the lip: neutral Axle Stall, up Nose Stall, down Tail Stall, left / right Disaster. Other authored transitions can enter Lip Stall; direction plus Flip / Grab changes the supported style." % _prompt_for("grind", "L"),
		"For lip style changes, forward + right selects Handplant; forward + left Invert; back + right Eggplant; back + left Disaster Stall. Palms support inverted poses on actual coping.",
		"While stalled, choose a direction and tap %s / %s to change style. With no direction these select Handplant / Invert; %s pivots to Rock and Roll. Balance left / right, release %s to drop in or release a charged ollie to pop out." % [_prompt_for("flip", "J"), _prompt_for("grab", "K"), _prompt_for("revert", "C"), _prompt_for("grind", "L")],
	])
	_guide_card(content, "MANUALS & LANDING LINKS", [
		"Tap up, release to neutral, then down for Manual; down, neutral, then up gives Nose Manual. Complete the pair within 220 ms. A held opposition or direct reversal does not count.",
		"You can also hold %s just before landing; forward selects Nose Manual. Balance with %s / %s; %s / %s steer separately during a manual." % [_prompt_for("manual", "M"), _prompt_for("steer_left", "A"), _prompt_for("steer_right", "D"), _prompt_for("spin_left","Q"), _prompt_for("spin_right","E")],
		"During a manual, tap %s for One-foot Manual, %s for Spacewalk or %s for a Manual Pivot." % [_prompt_for("flip", "J"), _prompt_for("grab", "K"), _prompt_for("revert", "C")],
		"Add forward + %s for One-foot Nose Manual, back + %s for Casper Manual, or left / right + %s for Crossfoot Manual. Forward + %s gives Hang Ten; back + %s gives Pogo; forward + %s gives Nose Manual Pivot." % [_prompt_for("flip", "J"), _prompt_for("flip", "J"), _prompt_for("flip", "J"), _prompt_for("grab", "K"), _prompt_for("grab", "K"), _prompt_for("revert", "C")],
		"After landing, press %s for Revert, then manual or ollie before the link timer ends. Revert changes stance; it does not restart that timer." % _prompt_for("revert", "C"),
	])
	var special_lines: Array[String] = []
	for command: Dictionary in TrickCatalog.special_commands():
		var prompts: Array[String] = []
		for direction: String in command.directions: prompts.append(_direction_prompt(direction))
		prompts.append(_prompt_for(str(command.action), str(command.action)))
		var entry: Dictionary = TrickCatalog.definition(command.id)
		var unlocked: bool = _state.get("unlocks", []).has(entry.required_unlock)
		special_lines.append("%s  /  %s%s" % [" → ".join(prompts), entry.display_name, "" if unlocked else "  ·  LOCKED"])
	_guide_card(content, "SPECIAL COMMANDS", special_lines)
	_guide_card(content, "SPECIALS & YOUR COMBO", [
		"Accepted tricks charge Special as you skate. When active, it drains over time; keeping a combo going slows the drain. A special does not spend the whole meter.",
		"In the air with Special ready, tap left, right, then %s for Clyde Carousel. Forward, back, then %s selects Tenement Tumble. The directions must be a quick sequence." % [_prompt_for("flip", "J"), _prompt_for("grab", "K")],
		"Unlocked specials also use %s / %s. Finish your current flip or grab before starting a special." % [_prompt_for("special_one", "U"), _prompt_for("special_two", "I")],
		"Each accepted trick adds a multiplier step up to ×100. Holds add base points. Repeating a trick lowers its value; mix your set. Land and finish the link window to bank it. A bail drops the combo and Special.",
	])
	_guide_card(content, "FIND A DIFFERENT LINE", [
		"Behind the moving service cart, match its direction, hold %s and make a fresh %s press to skitch. Balance left / right; release %s to let go or hold and release %s to jump clear." % [_prompt_for("grind", "L"), _prompt_for("interact", "X"), _prompt_for("grind", "L"), _prompt_for("ollie", "SPACE")],
		"Look for nearby activity prompts around the city. Open the city map from Pause to find routes and practice features; keep your approach and landing space in mind.",
	])
	var directory := _card()
	content.add_child(directory)
	var directory_rows := _vbox(directory, 10)
	var directory_heading := _label(directory_rows, "ADVANCED AIR SET  /  RAIL STYLE CHANGES", 15, ACCENT)
	directory_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	directory_heading.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_guide_focus(directory, "direction directory", directory_heading)
	var direction_actions := {
		"neutral": [], "north": ["push"], "south": ["brake"],
		"west": ["steer_left"], "east": ["steer_right"],
		"north_west": ["push", "steer_left"], "north_east": ["push", "steer_right"],
		"south_west": ["brake", "steer_left"], "south_east": ["brake", "steer_right"],
	}
	for direction: String in direction_actions:
		var prompts: Array[String] = []
		for action: String in direction_actions[direction]: prompts.append(_prompt_for(action, action))
		var selection := "No direction" if prompts.is_empty() else " + ".join(prompts)
		var names: Array[String] = []
		for family: String in ["flip", "grab", "grind"]:
			names.append(str(TrickCatalog.resolve(family, direction).get("display_name", "")))
		var row := _label(directory_rows, "%s  /  %s" % [selection, "  ·  ".join(names)], 17, PAPER)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		_guide_focus(directory, "direction:" + direction, row)




func _guide_card(content: VBoxContainer, title: String, lines: Array) -> void:
	var card := _card()
	content.add_child(card)
	var rows := _vbox(card, 9)
	var heading := _label(rows, title, 16, ACCENT)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_guide_focus(card, title, heading)
	for text: String in lines:
		var line := _label(rows, text, 17, PAPER)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		_guide_focus(card, title + ":" + text, line)




func _guide_focus(card: PanelContainer, title: String, target: Control) -> void:
	# Focus paragraphs instead of whole tall cards so every instruction remains
	# reachable with the stick, including at large UI with persistent notices.
	target.focus_mode = Control.FOCUS_ALL
	target.set_meta("focus_token", "guide:" + title)
	var style := card.get_theme_stylebox("panel") as StyleBoxFlat
	target.focus_entered.connect(func(): style.border_color = ACCENT; style.set_border_width_all(2))
	target.focus_exited.connect(func(): style.border_color = Color("294247"); style.set_border_width_all(1))
	if _focus_first == null: _focus_first = target




func _skating_controls(state: Dictionary) -> String:
	var ollie := _prompt_for("ollie", "SPACE")
	var grind := _prompt_for("grind", "L")
	var flip := _prompt_for("flip", "J")
	var grab := _prompt_for("grab", "K")
	var pause_hint := "     %s  Pause / guide" % _prompt_for("pause", "ESC")
	if bool(state.get("bail_active", false)):
		return "Getting back on the board" + pause_hint
	if bool(state.get("skitching", false)):
		if not bool(state.get("skitch_caught", true)):
			return "Match the cart · Reach for the bar     %s  Cancel reach" % grind + pause_hint
		return "%s / %s  Balance     %s  Release tow     %s  Hold / release Ollie" % [_prompt_for("steer_left", "A"), _prompt_for("steer_right", "D"), grind, ollie] + pause_hint
	if bool(state.get("wallriding", false)):
		return "%s  Hold / release Wallie     %s  Release to drop" % [ollie, grind] + pause_hint
	if bool(state.get("lip_active", false)):
		return "%s / %s  Change lip trick     %s  Pivot     %s  Release to drop in" % [flip, grab, _prompt_for("revert", "C"), grind] + pause_hint
	if bool(state.get("grinding", false)):
		return "%s / %s  Change grind     %s  Pivot     %s  Release     %s  Ollie" % [flip, grab, _prompt_for("revert", "C"), grind, ollie] + pause_hint
	if bool(state.get("manual", false)):
		return "%s  One-foot     %s  Spacewalk     %s  Pivot     %s  Ollie" % [flip, grab, _prompt_for("revert", "C"), ollie] + pause_hint
	if bool(state.get("crouching", false)):
		return "%s  Release to pop     %s / %s  Nollie / Boneless     %s + %s  No Comply" % [ollie, _prompt_for("push", "W"), _prompt_for("brake", "S"), _prompt_for("brake", "S"), _prompt_for("manual", "M")] + pause_hint
	if bool(state.get("transition_active", false)):
		if bool(state.get("airborne", false)):
			return "%s / %s  Fresh tap transfer     %s / %s  Adjust line" % [_prompt_for("push", "W"), _prompt_for("brake", "S"), _prompt_for("steer_left", "A"), _prompt_for("steer_right", "D")] + pause_hint
		return "%s  Hold / release air     %s  Hold at lip" % [ollie, grind] + pause_hint
	return "%s  Hold / release Ollie     %s  Grind / wallride     %s  Manual" % [ollie, grind, _prompt_for("manual", "M")] + pause_hint




func _direction_prompt(direction: String) -> String:
	var prompts: Array[String] = []
	if direction.contains("north"): prompts.append(_prompt_for("push", "W"))
	elif direction.contains("south"): prompts.append(_prompt_for("brake", "S"))
	if direction.contains("west"): prompts.append(_prompt_for("steer_left", "A"))
	elif direction.contains("east"): prompts.append(_prompt_for("steer_right", "D"))
	return " + ".join(prompts) if not prompts.is_empty() else "No direction"




func _update_recovery(state: Dictionary) -> void:
	var recovering: bool = state.get("bail_active", false)
	var fade_value: float = state.get("recovery_fade", 0.0)
	var fade := clampf(fade_value, 0.0, 1.0) if is_finite(fade_value) else 0.0
	_recovery_layer.visible = recovering or fade > 0.0
	_recovery_overlay.color = Color(0, 0, 0, fade)
	_recovery_caption.visible = recovering
	var phase: Variant = state.get("bail_progress",state.get("bail_phase",0.0))
	var getting_up := float(phase) > 0.55 if phase is float or phase is int else str(phase).to_lower() in ["getup", "get_up", "recover", "recovery", "fade"]
	_recovery_caption.text = "GETTING BACK UP" if getting_up else "BAIL"
	_recovery_caption.modulate = PAPER if getting_up else ORANGE




func _build_recovery_overlay() -> void:
	_recovery_layer = Control.new()
	_recovery_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_recovery_layer)
	_recovery_overlay = ColorRect.new()
	_recovery_overlay.color = Color(0,0,0,0)
	_recovery_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recovery_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_recovery_layer.add_child(_recovery_overlay)
	_recovery_caption = _label(_recovery_layer,"",32,PAPER)
	_recovery_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recovery_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recovery_caption.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_recovery_caption.add_theme_constant_override("outline_size",5)
	_recovery_caption.add_theme_color_override("font_outline_color",INK)
	_recovery_layer.visible = false




func _activity_hint(state: Dictionary) -> String:
	if bool(state.get("bail_active",false)): return ""
	if bool(state.get("setup_active",false)):
		return str(state.get("setup_id","Setup")).replace("_"," ").to_upper()+"  /  Plant and pop"
	if bool(state.get("crouching",false)):
		return "OLLIE CHARGE %d%%  /  Release %s to pop" % [roundi(clampf(float(state.get("ollie_charge",0.0)),0.0,1.0)*100.0),_prompt_for("ollie","SPACE")]
	if bool(state.get("skitching",false)):
		return ("SKITCH" if bool(state.get("skitch_caught",true)) else "REACH FOR BAR")+"  /  "+_prompt_for("grind","L")+" release · "+_prompt_for("ollie","SPACE")+" ollie"
	if bool(state.get("wallriding",false)):
		return "WALLRIDE  /  "+_prompt_for("ollie","SPACE")+" hold / release Wallie"
	if bool(state.get("lip_active",state.get("lip",false))):
		return str(state.get("lip_name","Lip"))+"  /  "+_prompt_for("grind","L")+" release to drop in"
	if bool(state.get("grinding",false)):
		return _prompt_for("flip","J")+" / "+_prompt_for("grab","K")+" style · "+_prompt_for("revert","C")+" pivot · "+_prompt_for("grind","L")+" tap to drop"
	if bool(state.get("manual",false)):
		return _prompt_for("steer_left","A")+" / "+_prompt_for("steer_right","D")+" balance · "+_prompt_for("spin_left","Q")+" / "+_prompt_for("spin_right","E")+" steer"
	return ""


