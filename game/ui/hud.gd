extends CanvasLayer
## Controller-first presentation. Main owns all gameplay, persistence and audio state.

signal restart_requested
signal pause_requested
signal free_skate_requested
signal settings_changed(values: Dictionary)
signal cosmetic_selected(id: String)
signal start_requested(free_skate: bool)
signal ui_feedback

const INK := Color("101d22")
const PANEL := Color("14272c")
const PAPER := Color("f2f4e9")
const MUTED := Color("aebfbb")
const ACCENT := Color("d8ef96")
const ORANGE := Color("ffb27d")
const TRACK := Color("365056")

var _root: Control
var _hud: Control
var _top: HBoxContainer
var _brand: Label
var _timer: Label
var _score: Label
var _mode: Label
var _location: Label
var _speed: Label
var _speed_bar: ProgressBar
var _combo: Label
var _tricks: Label
var _feedback: Label
var _goals: Label
var _caption: Label
var _prompt: Label
var _controls_label: Label
var _special_label: Label
var _special_hint: Label
var _special_bar: ProgressBar
var _balance_panel: PanelContainer
var _balance_marker: ColorRect
var _balance_label: Label
var _balance_track: Control
var _speed_panel: PanelContainer
var _special_panel: PanelContainer
var _footer: PanelContainer
var _modal: ColorRect
var _dialog: PanelContainer
var _modal_title: Label
var _modal_details: Label
var _resume: Button
var _restart: Button
var _free: Button
var _focus_first: Control
var _page := ""
var _return_page := "pause"
var _goals_auto_paused := false
var _state: Dictionary = {}
var _settings: Dictionary = {}
var _binding_action := ""
var _binding_status: Label
var _input_profile: Script
var _binding_rows: Dictionary = {}
var _controller_active := false
var _last_size := Vector2.ZERO
var _last_scale := -1.0
var _last_combo := 0
var _combo_tween: Tween


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
	_top = HBoxContainer.new()
	_top.add_theme_constant_override("separation", 20)
	_hud.add_child(_top)
	var brand_column := VBoxContainer.new()
	brand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_column.add_theme_constant_override("separation", 1)
	_top.add_child(brand_column)
	_brand = _label(brand_column, "TAM HAWKS", 31, PAPER)
	_brand.add_theme_constant_override("outline_size", 5)
	_brand.add_theme_color_override("font_outline_color", INK)
	var sub := _label(brand_column, "PRO SKATER  /  GLASGOW", 13, ACCENT)
	sub.add_theme_constant_override("outline_size", 4)
	sub.add_theme_color_override("font_outline_color", INK)
	var timer_card := _card()
	timer_card.custom_minimum_size = Vector2(148, 90)
	_top.add_child(timer_card)
	var timer_box := _vbox(timer_card, 2)
	_mode = _label(timer_box, "CAREER RUN", 12, MUTED)
	_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer = _label(timer_box, "2:00", 36, PAPER)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var score_card := _card()
	score_card.custom_minimum_size = Vector2(248, 90)
	_top.add_child(score_card)
	var score_box := _vbox(score_card, 2)
	_label(score_box, "RUN SCORE", 12, MUTED)
	_score = _label(score_box, "0", 36, PAPER)
	_location = _floating_label("ROYAL EXCHANGE SQUARE", 17, PAPER)
	_goals = _floating_label("0 / 10 GOALS", 14, ACCENT)
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
	_speed_panel = _card()
	_hud.add_child(_speed_panel)
	var speed_box := _vbox(_speed_panel, 5)
	_label(speed_box, "STREET SPEED", 12, MUTED)
	_speed = _label(speed_box, "0 km/h", 27, PAPER)
	_speed_bar = _progress(speed_box, ACCENT)
	_special_panel = _card()
	_hud.add_child(_special_panel)
	var special_box := _vbox(_special_panel, 7)
	_special_label = _label(special_box, "SPECIAL  /  BUILD A COMBO", 12, MUTED)
	_special_bar = _progress(special_box, ORANGE)
	_special_hint = _label(special_box, "BANK POINTS TO FILL", 11, MUTED)
	_combo = _floating_label("", 34, ACCENT)
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tricks = _floating_label("", 19, PAPER)
	_tricks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tricks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tricks.max_lines_visible = 2
	_feedback = _floating_label("", 15, ORANGE)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption = _floating_label("", 20, PAPER)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt = _floating_label("", 17, ACCENT)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer = _card()
	_hud.add_child(_footer)
	_controls_label = _label(_footer, "", 13, MUTED)
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func update_display(state: Dictionary) -> void:
	if not is_instance_valid(_timer):
		return
	_state = state.duplicate(true)
	_settings = state.get("settings", {}).duplicate(true)
	_relayout()
	var seconds := maxi(0, ceili(float(state.get("time", 120.0))))
	var free: bool = state.get("free_skate", false)
	_timer.text = "∞" if free else "%d:%02d" % [seconds / 60, seconds % 60]
	_timer.modulate = ORANGE if seconds <= 15 and not free else Color.WHITE
	_mode.text = "FREE SKATE" if free else "CAREER RUN"
	_score.text = _number(int(state.get("score", 0)))
	_location.text = str(state.get("location", "Glasgow")).to_upper()
	var completed := 0
	for goal: Dictionary in state.get("goals", []):
		if goal.get("done", false): completed += 1
	_goals.text = "%d / 10 GOALS  ·  %s" % [completed, _prompt_for("goals", "TAB")]
	if free: _goals.text = "FREE SKATE  ·  CAREER GOALS PAUSED"
	var kmh := roundi(float(state.get("speed", 0.0)) * 3.6)
	_speed.text = "%d km/h" % kmh
	_speed_bar.value = clampf(float(kmh) / 60.0, 0.0, 1.0)
	var meter := clampf(float(state.get("special_meter", 0.0)), 0.0, 100.0)
	_special_bar.value = meter / 100.0
	_special_label.text = "SPECIAL READY" if meter >= 100.0 else "SPECIAL  /  %d%%" % roundi(meter)
	_special_label.modulate = ORANGE if meter >= 100.0 else Color.WHITE
	_special_hint.text = "%s / %s  ·  SPECIALS" % [_prompt_for("special_one", "U"), _prompt_for("special_two", "I")] if meter >= 100.0 else "BANK POINTS TO FILL"
	var grinding: bool = state.get("grinding", false)
	var manual: bool = state.get("manual", false)
	var balance := clampf(float(state.get("balance" if grinding else "manual_balance", 0.0)), -1.0, 1.0)
	_balance_panel.visible = grinding or manual
	_balance_marker.position = Vector2(138.0 + balance * 130.0, 0)
	_balance_marker.color = ORANGE if absf(balance) > 0.7 else ACCENT
	_balance_label.text = ("RAIL" if grinding else "MANUAL") + " BALANCE  /  " + (_prompt_for("steer_left", "A") + "–" + _prompt_for("steer_right", "D") if grinding else _prompt_for("push", "W") + "–" + _prompt_for("brake", "S"))
	if absf(balance) > 0.7:
		_balance_label.text = "CORRECT " + (("LEFT" if balance > 0.0 else "RIGHT") if grinding else ("WITH PUSH" if balance > 0.0 else "WITH BRAKE"))
	var combo: int = state.get("combo", 0)
	_combo.text = "%s × %d" % [_number(int(state.get("combo_base", 0))), int(state.get("multiplier", 0))] if combo > 0 else ""
	_tricks.text = str(state.get("tricks", "")) if combo > 0 else ""
	_feedback.text = str(state.get("feedback", ""))
	if combo > 0:
		var link_time := float(state.get("landing_window", 0.0))
		_feedback.text = "%s PENDING  ·  KEEP THE LINE ALIVE" % _number(combo)
		if link_time > 0.0:
			_feedback.text = "LINK IT  %.2fs  ·  MANUAL / REVERT" % link_time
	if combo != _last_combo and combo > 0 and not bool(_settings.get("reduced_motion", false)):
		if is_instance_valid(_combo_tween): _combo_tween.kill()
		_combo.modulate = Color(1.0, 1.0, 0.72)
		_combo_tween = create_tween()
		_combo_tween.tween_property(_combo, "modulate", Color.WHITE, 0.18)
	_last_combo = combo
	_caption.text = str(state.get("caption", "")) if bool(_settings.get("captions", true)) else ""
	_prompt.text = str(state.get("interaction_prompt", ""))
	_controls_label.text = "%s  Ollie     %s  Grind     %s  Manual     %s  Pause / controls" % [_prompt_for("ollie", "SPACE"), _prompt_for("grind", "L"), _prompt_for("manual", "M"), _prompt_for("pause", "ESC")]
	var finished: bool = state.get("finished", false)
	var paused_now: bool = state.get("paused", false)
	if _page == "" and (finished or paused_now):
		_show_page("results" if finished else "pause")
	elif _page not in ["", "title"] and not finished and not paused_now:
		_hide_modal()
	_hud.visible = _page != "title"


func show_title() -> void:
	_show_page("title")


func show_settings() -> void:
	_open_subpage("settings")


func show_controls() -> void:
	_open_subpage("controls")


func hide_menu() -> void:
	_hide_modal()


func toggle_goals() -> void:
	if _page == "goals":
		_back()
		return
	_goals_auto_paused = _page == "" and not bool(_state.get("paused", false)) and not bool(_state.get("finished", false))
	_return_page = _page if _page != "" else "pause"
	if _goals_auto_paused:
		pause_requested.emit()
	_show_page("goals")


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


func _show_page(page: String) -> void:
	_page = page
	_binding_action = ""
	_modal.visible = true
	_focus_first = null
	for child in _modal.get_children():
		_modal.remove_child(child)
		child.queue_free()
	_dialog = _card(true)
	_modal.add_child(_dialog)
	var box := _vbox(_dialog, 12)
	_label(box, "TAM HAWKS PRO SKATER  /  GLASGOW", 12, ACCENT)
	_modal_title = _label(box, "", 35, PAPER)
	_modal_details = _label(box, "", 17, MUTED)
	_modal_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_details.custom_minimum_size.y = 42
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	match page:
		"title": _build_title(content)
		"pause": _build_pause(content, false)
		"results": _build_pause(content, true)
		"goals": _build_goals(content)
		"settings": _build_settings(content)
		"controls": _build_controls(content)
	if page not in ["title", "pause", "results"]:
		_button(box, "BACK", _back)
	_relayout(true)
	if is_instance_valid(_focus_first): _focus_control.call_deferred(_focus_first)
	_hud.visible = page != "title"


func _focus_control(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
		control.grab_focus()


func _build_title(content: VBoxContainer) -> void:
	_modal_title.text = "Your city. Your line."
	_modal_title.add_theme_font_size_override("font_size", 45)
	_modal_details.text = "Four Glasgow districts. One board. Find a line worth another run."
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
	_label(intro, "TWO MINUTES. MAKE THEM COUNT.", 24, ACCENT)
	_label(intro, "Link tricks, explore the city and work through ten career goals.", 17, PAPER)
	_button(content, "START CAREER RUN", func(): _start_mode(false))
	_button(content, "FREE SKATE", func(): _start_mode(true))
	_button(content, "SETTINGS", func(): _open_subpage("settings"))
	_button(content, "CONTROLS", func(): _open_subpage("controls"))
	_label(content, "Play with a controller or keyboard. Progress stays on this device.", 14, MUTED)


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
	_button(content, "GOALS & UNLOCKS", toggle_goals)
	_button(content, "SETTINGS", func(): _open_subpage("settings"))
	_button(content, "CONTROLS", func(): _open_subpage("controls"))
	_free = _button(content, "START CAREER RUN" if _state.get("free_skate", false) else "SWITCH TO FREE SKATE", _switch_mode)


func _build_goals(content: VBoxContainer) -> void:
	_modal_title.text = "A good day's skating."
	_modal_details.text = "Career progress is saved on this device." if not _state.get("free_skate", false) else "Explore freely. Career goals and records advance in career runs."
	for goal: Dictionary in _state.get("goals", []):
		var card := _card()
		card.focus_mode = Control.FOCUS_ALL
		var focus_style := card.get_theme_stylebox("panel") as StyleBoxFlat
		card.focus_entered.connect(func(): focus_style.border_color = ACCENT; focus_style.set_border_width_all(2))
		card.focus_exited.connect(func(): focus_style.border_color = Color("294247"); focus_style.set_border_width_all(1))
		if _focus_first == null: _focus_first = card
		content.add_child(card)
		var row := _vbox(card, 5)
		var done: bool = goal.get("done", false)
		_label(row, ("✓  " if done else "○  ") + str(goal.get("title", "Goal")), 21, ACCENT if done else PAPER)
		var detail := _label(row, str(goal.get("detail", "")), 16, MUTED)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


func _build_settings(content: VBoxContainer) -> void:
	_modal_title.text = "Your kind of session."
	_modal_details.text = "Sound, readability and camera comfort. Changes save automatically."
	_slider(content, "Master volume", "audio", 0.0, 1.0, 0.05, 0.8)
	_slider(content, "Skating & voice", "sfx_volume", 0.0, 1.0, 0.05, 1.0)
	_slider(content, "City ambience", "ambience_volume", 0.0, 1.0, 0.05, 0.6)
	_slider(content, "Interface size", "ui_scale", 1.0, 1.4, 0.1, 1.0)
	_slider(content, "Camera sensitivity", "camera_sensitivity", 0.5, 2.0, 0.1, 1.0)
	_toggle(content, "Show captions", "captions", true)
	_toggle(content, "Reduce motion & camera shake", "reduced_motion", false)
	_label(content, str(_state.get("save_status", "")), 14, MUTED)


func _build_controls(content: VBoxContainer) -> void:
	_modal_title.text = "Make every button count."
	_modal_details.text = "Choose an action, then press a key, controller button or trigger. Escape cancels."
	_binding_status = _label(content, "Controller prompts follow your saved bindings.", 15, ACCENT)
	_binding_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not ResourceLoader.exists("res://game/core/input_profile.gd"):
		_label(content, "WASD skate · Space ollie · J/K tricks · L grind · M manual\nQ/E spin · Escape pause · R restart · Tab goals", 18, PAPER)
		return
	_input_profile = load("res://game/core/input_profile.gd")
	for row: Dictionary in _input_profile.binding_snapshot():
		var action: String = row.action
		_button(content, "%s  /  %s  ·  %s" % [row.label, row.key_text, row.pad_text], func():
			_binding_action = action
			_binding_status.text = "LISTENING: " + str(row.label) + "  —  press an input, or Escape to cancel.")
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
	button.custom_minimum_size.y = 48
	parent.add_child(button)
	button.toggled.connect(func(value: bool): _change_setting(key, value); ui_feedback.emit())
	if _focus_first == null: _focus_first = button


func _change_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	if key == "bindings": _binding_rows.clear()
	settings_changed.emit({key: value})
	_relayout()


func _open_subpage(page: String) -> void:
	_return_page = _page if _page != "" else "pause"
	if _page == "" and not bool(_state.get("paused", false)) and not bool(_state.get("finished", false)):
		pause_requested.emit()
	_show_page(page)


func _back() -> void:
	if _page == "title" or _page == "results": return
	if _page == "pause":
		_resume_run()
	elif _page == "goals" and _goals_auto_paused:
		_goals_auto_paused = false
		_resume_run()
	else:
		_show_page(_return_page)


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
	_goals_auto_paused = false


func _relayout(force: bool = false) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var preference := clampf(float(_settings.get("ui_scale", 1.0)), 1.0, 1.4)
	if not force and viewport_size == _last_size and preference == _last_scale: return
	_last_size = viewport_size
	_last_scale = preference
	var scale_factor := minf(viewport_size.x / 1440.0, viewport_size.y / 900.0) * preference
	scale_factor = maxf(0.5, scale_factor)
	_root.scale = Vector2.ONE * scale_factor
	_root.size = viewport_size / scale_factor
	var extent := _root.size
	_hud.size = extent
	_top.position = Vector2(28, 24)
	_top.size = Vector2(extent.x - 56, 90)
	_location.position = Vector2(29, 126)
	_location.size = Vector2(345, 30)
	_goals.position = Vector2(extent.x - 365, 126)
	_goals.size = Vector2(337, 28)
	_balance_panel.position = Vector2(extent.x * 0.5 - 158, 132)
	_balance_panel.size = Vector2(316, 76)
	_speed_panel.position = Vector2(28, extent.y - 175)
	_speed_panel.size = Vector2(180, 102)
	_special_panel.position = Vector2(extent.x - 240, extent.y - 175)
	_special_panel.size = Vector2(212, 102)
	for label in [_combo, _tricks, _feedback, _caption, _prompt]:
		label.position.x = 224
		label.size.x = extent.x - 480
	_combo.position.y = extent.y - 235
	_combo.size.y = 48
	_tricks.position.y = extent.y - 183
	_tricks.size.y = 48
	_feedback.position.y = extent.y - 130
	_feedback.size.y = 27
	_caption.position.y = extent.y - 97
	_caption.size.y = 40
	_prompt.position.y = extent.y - 273
	_prompt.size.y = 29
	_footer.position = Vector2(28, extent.y - 46)
	_footer.size = Vector2(extent.x - 56, 34)
	if is_instance_valid(_modal): _modal.size = extent
	if is_instance_valid(_dialog):
		var dialog_width := minf(850, extent.x - 96)
		var preferred_height := 660.0 if _page == "title" else (640.0 if _page == "pause" else 750.0)
		var dialog_height := minf(preferred_height, extent.y - 76)
		_dialog.position = (extent - Vector2(dialog_width, dialog_height)) * 0.5
		_dialog.size = Vector2(dialog_width, dialog_height)


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
	button.custom_minimum_size.y = 48
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	if _binding_rows.is_empty() and ResourceLoader.exists("res://game/core/input_profile.gd"):
		_input_profile = load("res://game/core/input_profile.gd")
		for row: Dictionary in _input_profile.binding_snapshot(): _binding_rows[row.action] = row
	if _binding_rows.has(action):
		return str(_binding_rows[action].get("pad_text" if _pad() else "key_text", fallback))
	return fallback


func _number(value: int) -> String:
	var raw := str(maxi(value, 0))
	var result := ""
	for i in range(raw.length()):
		if i > 0 and (raw.length() - i) % 3 == 0: result += ","
		result += raw[i]
	return result
