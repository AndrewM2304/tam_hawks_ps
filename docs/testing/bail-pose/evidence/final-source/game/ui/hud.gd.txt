extends CanvasLayer
## Controller-first presentation. Main owns all gameplay, persistence and audio state.

signal restart_requested
signal pause_requested
signal free_skate_requested
signal settings_changed(values: Dictionary)
signal cosmetic_selected(id: String)
signal start_requested(free_skate: bool)
signal ui_feedback

const GraphicsQuality = preload("res://game/core/graphics_quality.gd")
const RouteMap = preload("res://game/ui/route_map.gd")

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_controller_active = not Input.get_connected_joypads().is_empty()
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hud)
	_build_hud()
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
	var special_box := _vbox(_special_panel, 7)
	_special_label = _label(special_box, "SPECIAL  /  BUILD A COMBO", 15, MUTED)
	_special_bar = _progress(special_box, ORANGE)
	_special_hint = _label(special_box, "BANK POINTS TO FILL", 13, MUTED)
	_special_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	var meter := clampf(float(state.get("special_meter", 0.0)), 0.0, 100.0)
	_special_bar.value = meter / 100.0
	_special_label.text = "SPECIAL READY" if meter >= 100.0 else "SPECIAL"
	_special_label.modulate = ORANGE if meter >= 100.0 else Color.WHITE
	_special_hint.text = "%s / %s  ·  SPECIALS" % [_prompt_for("special_one", "U"), _prompt_for("special_two", "I")] if meter >= 100.0 else ""
	var grinding: bool = state.get("grinding", false)
	var manual: bool = state.get("manual", false)
	var lip: bool = state.get("lip", false)
	var balance_key := "lip_balance" if lip else ("balance" if grinding else "manual_balance")
	var balance := clampf(float(state.get(balance_key, 0.0)), -1.0, 1.0)
	_balance_panel.visible = grinding or manual or lip
	_balance_marker.position = Vector2(138.0 + balance * 130.0, 0)
	_balance_marker.color = ORANGE if absf(balance) > 0.7 else ACCENT
	_balance_label.text = ("LIP" if lip else ("RAIL" if grinding else "MANUAL")) + "  /  " + _prompt_for("steer_left", "A") + "–" + _prompt_for("steer_right", "D")
	if absf(balance) > 0.7:
		var correction: String = "steer_left" if balance > 0.0 else "steer_right"
		_balance_label.text = "CORRECT  ·  " + _prompt_for(correction, "")
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


func show_map() -> void:
	_open_subpage("map")


func toggle_goals() -> void:
	if _page == "goals":
		_back()
		return
	_open_subpage("goals")


func _input(event: InputEvent) -> void:
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
	if event.is_action_pressed("pause"):
		_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart"):
		if _page in ["pause", "results"]: _restart_run()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("free_skate"):
		if _page in ["pause", "results"]: _switch_mode()
		get_viewport().set_input_as_handled()
	elif InputMap.has_action("goals") and event.is_action_pressed("goals"):
		toggle_goals()
		get_viewport().set_input_as_handled()


func _show_page(page: String, focus_token: String = "", scroll_position: int = 0) -> void:
	# Rebuilding the current page (for example after rebinding) keeps its place.
	if page == _page and focus_token.is_empty():
		focus_token = _focused_token()
		scroll_position = _scroll.scroll_vertical if is_instance_valid(_scroll) else 0
	_page = page
	_page_revision += 1
	_binding_action = ""
	_modal.visible = true
	_focus_first = null
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
	_button(content, "SETTINGS", func(): _open_subpage("settings"))
	_button(content, "CONTROLS", func(): _open_subpage("controls"))
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
	_restart = _button(content, "ONE MORE RUN" if finished else "RESTART RUN", _restart_run)
	_button(content, "CITY MAP & ROUTES", show_map)
	_button(content, "GOALS & UNLOCKS", toggle_goals)
	_button(content, "SETTINGS", func(): _open_subpage("settings"))
	_button(content, "CONTROLS", func(): _open_subpage("controls"))
	_free = _button(content, "START CAREER RUN" if _state.get("free_skate", false) else "SWITCH TO FREE SKATE", _switch_mode)


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
	map.configure(_map_checkpoints, _map_routes,
		_state.get("player_position", Vector3.ZERO), float(_state.get("player_heading", 0.0)))
	content.add_child(map)
	for row: Array in [
		["PALE LINES  /  CONNECTED ROUTES     ORANGE  /  JUMP LINE", 13, MUTED],
		["Gallery steps & fountain → station platforms → hilly park paths. Follow the south quay to the Clyde bridge transfer.", 16, PAPER],
		["Career goals are in the four city districts. Meet Mo by the Exchange fountain, or Rae’s bin drums and dancing cats in George Square, or Mairi’s parcel challenge through the Barras. Free skate gives you time to explore.", 14, MUTED],
	]:
		var description := _label(content, row[0], row[1], row[2])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING



func _build_settings(content: VBoxContainer) -> void:
	_modal_title.text = "Your kind of session."
	_modal_details.text = "Sound, readability and camera comfort. Changes take effect immediately."
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
	if not _navigation.is_empty():
		var origin: Dictionary = _navigation.pop_back()
		if str(origin.page).is_empty():
			_hide_modal()
			if origin.get("resume", false): pause_requested.emit()
		else:
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
	_hide_modal()
	pause_requested.emit()


func _restart_run() -> void:
	_hide_modal()
	restart_requested.emit()


func _switch_mode() -> void:
	_hide_modal()
	free_skate_requested.emit()


func _start_mode(free: bool) -> void:
	_hide_modal()
	start_requested.emit(free)


func _hide_modal() -> void:
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
		text = text.split(" / ")[0]
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
