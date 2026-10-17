extends CanvasLayer

signal restart_requested
signal pause_requested
signal free_skate_requested

const INK := Color("142a31")
const PAPER := Color("f8edce")
const MUTED := Color("abc2bf")
const ORANGE := Color("ff9867")

var _root: Control
var _timer: Label
var _score: Label
var _mode: Label
var _location: Label
var _speed: Label
var _speed_bar: ColorRect
var _combo: Label
var _tricks: Label
var _feedback: Label
var _goals: Label
var _controls_label: Label
var _actions_label: Label
var _modal: ColorRect
var _modal_title: Label
var _modal_details: Label
var _resume: Button
var _restart: Button
var _free: Button
var _balance_panel: Panel
var _balance_marker: ColorRect
var _balance_label: Label
var _was_modal: bool = false

func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var brand := _panel(Vector2(28, 26), Vector2(300, 102))
	_label(brand, "TAM HAWKS", Vector2(18, 9), 32, PAPER)
	_label(brand, "P R O  S K A T E R", Vector2(20, 49), 15, ORANGE)
	_label(brand, "GLASGOW  /  FIRST PUSH", Vector2(20, 76), 11, MUTED)
	var timer_panel := _panel(Vector2(-95, 26), Vector2(190, 102))
	timer_panel.anchor_left = 0.5
	timer_panel.anchor_right = 0.5
	_mode = _label(timer_panel, "TWO MINUTE RUN", Vector2(0, 10), 12, MUTED)
	_mode.size.x = 190
	_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer = _label(timer_panel, "2:00", Vector2(0, 27), 42, PAPER)
	_timer.size.x = 190
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var score_panel := _panel(Vector2(-288, 26), Vector2(260, 102))
	score_panel.anchor_left = 1.0
	score_panel.anchor_right = 1.0
	_label(score_panel, "RUN SCORE", Vector2(18, 10), 12, MUTED)
	_score = _label(score_panel, "000000", Vector2(18, 29), 40, PAPER)
	_location = _label(_root, "ROYAL EXCHANGE SQUARE", Vector2(32, 145), 16, PAPER)
	_location.add_theme_constant_override("outline_size", 5)
	_location.add_theme_color_override("font_outline_color", INK)
	var goals_panel := _panel(Vector2(-288, 151), Vector2(260, 146))
	goals_panel.anchor_left = 1.0
	goals_panel.anchor_right = 1.0
	_label(goals_panel, "01 / FIND YOUR FEET", Vector2(18, 12), 14, ORANGE)
	_goals = _label(goals_panel, "", Vector2(18, 43), 14, PAPER)
	_goals.add_theme_constant_override("line_spacing", 10)
	var speed_panel := _panel(Vector2(28, -164), Vector2(190, 90))
	speed_panel.anchor_top = 1.0
	speed_panel.anchor_bottom = 1.0
	_label(speed_panel, "STREET SPEED", Vector2(15, 9), 11, MUTED)
	_speed = _label(speed_panel, "0 KM/H", Vector2(15, 24), 28, PAPER)
	var track := ColorRect.new()
	track.color = Color("36535a")
	track.position = Vector2(16, 69)
	track.size = Vector2(158, 5)
	speed_panel.add_child(track)
	_speed_bar = ColorRect.new()
	_speed_bar.color = ORANGE
	_speed_bar.size = Vector2(0, 5)
	track.add_child(_speed_bar)
	_combo = _label(_root, "", Vector2(-400, -208), 40, ORANGE)
	_combo.anchor_left = 0.5
	_combo.anchor_right = 0.5
	_combo.anchor_top = 1.0
	_combo.anchor_bottom = 1.0
	_combo.size.x = 800
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo.add_theme_constant_override("outline_size", 8)
	_combo.add_theme_color_override("font_outline_color", INK)
	_tricks = _label(_root, "", Vector2(-400, -153), 20, PAPER)
	_tricks.anchor_left = 0.5
	_tricks.anchor_right = 0.5
	_tricks.anchor_top = 1.0
	_tricks.anchor_bottom = 1.0
	_tricks.size.x = 800
	_tricks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tricks.add_theme_constant_override("outline_size", 6)
	_tricks.add_theme_color_override("font_outline_color", INK)
	_feedback = _label(_root, "", Vector2(-400, -120), 18, PAPER)
	_feedback.anchor_left = 0.5
	_feedback.anchor_right = 0.5
	_feedback.anchor_top = 1.0
	_feedback.anchor_bottom = 1.0
	_feedback.size.x = 800
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_constant_override("outline_size", 6)
	_feedback.add_theme_color_override("font_outline_color", INK)
	var footer := _panel(Vector2(28, -57), Vector2(-56, 39))
	footer.anchor_right = 1.0
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_right = -28
	_controls_label = _label(footer, "", Vector2(15, 9), 14, PAPER)
	_actions_label = _label(footer, "", Vector2(-337, 9), 14, MUTED)
	_actions_label.anchor_left = 1.0
	_actions_label.anchor_right = 1.0
	_balance_panel = _panel(Vector2(-155, 145), Vector2(310, 76))
	_balance_panel.anchor_left = 0.5
	_balance_panel.anchor_right = 0.5
	_balance_label = _label(_balance_panel, "RAIL BALANCE  /  A-D", Vector2(15, 9), 15, PAPER)
	var balance_track := ColorRect.new()
	balance_track.color = Color("36535a")
	balance_track.position = Vector2(20, 39)
	balance_track.size = Vector2(270, 7)
	_balance_panel.add_child(balance_track)
	var centre := ColorRect.new()
	centre.color = MUTED
	centre.position = Vector2(153, 34)
	centre.size = Vector2(4, 18)
	_balance_panel.add_child(centre)
	_balance_marker = ColorRect.new()
	_balance_marker.color = ORANGE
	_balance_marker.position = Vector2(151, 32)
	_balance_marker.size = Vector2(8, 22)
	_balance_panel.add_child(_balance_marker)
	_label(_balance_panel, "KEEP CENTRED  /  OLLIE TO JUMP OFF", Vector2(15, 57), 11, MUTED)
	_balance_panel.visible = false
	_build_modal()

func update_display(state: Dictionary) -> void:
	if not is_instance_valid(_timer):
		return
	var seconds := ceili(float(state.get("time", 120.0)))
	var free: bool = state.get("free_skate", false)
	_timer.text = "∞" if free else "%d:%02d" % [seconds / 60, seconds % 60]
	_timer.modulate = ORANGE if seconds <= 15 and not free else Color.WHITE
	_mode.text = "FREE SKATE" if free else "TWO MINUTE RUN"
	_score.text = "%06d" % int(state.get("score", 0))
	_location.text = str(state.get("location", "GLASGOW")).to_upper()
	var controller := not Input.get_connected_joypads().is_empty()
	_controls_label.text = "STICK skate   CROSS ollie   SQUARE/CIRCLE tricks   L1/R1 spin   R2 grind" if controller else "WASD skate   SPACE ollie   J/K tricks   Q/E spin   L grind"
	_actions_label.text = "TRIANGLE  restart     OPTIONS  pause" if controller else "R  restart     F  free skate     ESC  pause"
	var grinding: bool = state.get("grinding", false)
	var balance := clampf(float(state.get("balance", 0.0)), -1.0, 1.0)
	_balance_panel.visible = grinding
	_balance_marker.position.x = 151.0 + balance * 131.0
	_balance_label.text = "RAIL BALANCE  /  %s" % ("LEFT STICK" if controller else "A-D")
	if absf(balance) >= 0.7:
		_balance_label.text = "LEAN " + ("LEFT" if balance > 0.0 else "RIGHT") + "  /  LOSING BALANCE"
	var kmh := roundi(float(state.get("speed", 0.0)) * 3.6)
	_speed.text = "%d KM/H" % kmh
	_speed_bar.size.x = 158.0 * clampf(float(kmh) / 60.0, 0.0, 1.0)
	var combo: int = state.get("combo", 0)
	_combo.text = "%s  ×%d" % [state.get("combo_base", 0), state.get("multiplier", 0)] if combo > 0 else ""
	_tricks.text = str(state.get("tricks", ""))
	_feedback.text = str(state.get("feedback", "")) if combo == 0 else "%s POINTS — LAND IT TO BANK IT" % combo
	if grinding:
		_feedback.text = "%s POINTS — HOLD GRIND / LAND TO BANK" % combo
	_goals.text = "%s  Land an ollie\n%s  Try a flip + grab\n%s  Bank 1,000 points" % [
		"✓" if int(state.get("landings", 0)) > 0 else "○",
		"✓" if int(state.get("flips", 0)) > 0 and int(state.get("grabs", 0)) > 0 else "○",
		"✓" if int(state.get("score", 0)) >= 1000 else "○"]
	var finished: bool = state.get("finished", false)
	var show_modal: bool = finished or state.get("paused", false)
	_modal.visible = show_modal
	if show_modal:
		_modal_title.text = "THAT'S YER LOT." if finished else "TAKE A BREATHER."
		_modal_details.text = "RUN SCORE   %s\nBEST COMBO   %s\n\n" % [state.get("score", 0), state.get("best", 0)]
		_modal_details.text += "Same square. A better line. One more go."
		_resume.visible = not finished
		_free.text = "START A TWO-MINUTE RUN" if free else "SWITCH TO FREE SKATE"
		if not _was_modal:
			(_restart if finished else _resume).grab_focus()
	_was_modal = show_modal

func _build_modal() -> void:
	_modal = ColorRect.new()
	_modal.color = Color(0.025, 0.07, 0.085, 0.87)
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	_modal.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -250
	box.offset_right = 250
	box.offset_top = -210
	box.offset_bottom = 210
	_modal_title = Label.new()
	_modal_title.add_theme_font_size_override("font_size", 36)
	_modal_title.add_theme_color_override("font_color", ORANGE)
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_modal_title)
	_modal_details = Label.new()
	_modal_details.add_theme_color_override("font_color", PAPER)
	_modal_details.add_theme_font_size_override("font_size", 18)
	_modal_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_modal_details)
	_resume = _menu_button(box, "BACK TO THE BOARD", func(): pause_requested.emit())
	_restart = _menu_button(box, "RESTART RUN", func(): restart_requested.emit())
	_free = _menu_button(box, "SWITCH TO FREE SKATE", func(): free_skate_requested.emit())
	_modal.visible = false

func _menu_button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_stylebox_override("normal", _style(INK, 4))
	button.add_theme_stylebox_override("hover", _style(ORANGE, 4))
	var focus := _style(Color(0, 0, 0, 0), 4)
	focus.border_color = ORANGE
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _panel(pos: Vector2, dimensions: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = dimensions
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color(INK, 0.94), 4))
	_root.add_child(panel)
	return panel

func _label(parent: Node, text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
