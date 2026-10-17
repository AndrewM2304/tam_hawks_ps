extends SceneTree
## Actual Main Controls modal at normal/stress sizes. Readback freezes no UI
## state: only native pause, saved-setting application, focus, clicks and wheel.

const Main = preload("res://game/main.gd")
const Profile = preload("res://game/core/input_profile.gd")
const OUTPUT := "res://.local/classic-controls-capture/"
var game: Node
var errors := 0
var records: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Controls screenshots require a rendering display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	_set_size(Vector2i(1280, 800))
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	await _frames(12)
	game.toggle_pause()
	await _ready_menu()
	var controls := _button(game.hud._dialog, "CONTROLS")
	_check(is_instance_valid(controls), "actual pause page has a Controls button")
	if not is_instance_valid(controls):
		quit(1)
		return
	controls.grab_focus()
	await _frames(8)
	await _click(controls)
	await _ready_menu()
	_check(game.hud._page == "controls", "actual GUI click opens Controls")
	await _top()
	await _shot("controls-1280-top", 1.0, true)
	_set_size(Vector2i(960, 540))
	game.apply_settings({"ui_scale": 1.4}, false)
	game._refresh_hud()
	await _frames(16)
	await _top()
	await _shot("controls-960-large-top", 1.4, true)
	var scroll: ScrollContainer = game.hud._scroll
	var bottom_reached := false
	for attempt in 50:
		var bar := scroll.get_v_scroll_bar()
		if bar.value >= bar.max_value - bar.page - 1.0:
			bottom_reached = true
			break
		_wheel(scroll.get_global_rect().get_center())
		await _frames(2)
	_check(bottom_reached, "actual wheel events reach the end of the binding list")
	await _shot("controls-960-large-bottom", 1.4, false)
	var receipt := {"format": 1, "engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_video_adapter_name(), "persistence_enabled": false,
		"errors": errors, "records": records,
		"recipe": "Main free-skate -> native pause -> focus and actual mouse click Controls. Resize native viewport and apply 1.4x user setting. Actual wheel events scroll to bottom; focus reaches Back. No profile writes or synthetic HUD snapshot.",
		"inputs": {}}
	for path: String in ["res://project.godot", "res://game/main.gd", "res://game/ui/hud.gd", "res://tools/classic_controls_capture.gd"]:
		receipt.inputs[path] = FileAccess.get_sha256(path)
	var file := FileAccess.open(OUTPUT + "recipe.json", FileAccess.WRITE)
	if file == null: _check(false, "controls recipe writable")
	else: file.store_string(JSON.stringify(receipt, "\t") + "\n")
	print("CLASSIC CONTROLS CAPTURE errors=", errors, " records=", records.size())
	paused = false
	quit(1 if errors else 0)


func _set_size(value: Vector2i) -> void:
	root.size = value
	root.content_scale_size = value


func _top() -> void:
	# This is the scroll reset for each declared layout fixture, not production
	# navigation. Wheel-only bottom navigation is checked separately below.
	game.hud._scroll.scroll_vertical = 0
	await _frames(8)


func _shot(label: String, preference: float, top: bool) -> void:
	await _frames(8)
	var hud: CanvasLayer = game.hud
	var scroll: ScrollContainer = hud._scroll
	var content: Control = scroll.get_child(0)
	var help := _help_label(content)
	var footer := _button(hud._dialog, "BACK")
	var restore := _button(content, "RESTORE DEFAULT CONTROLS")
	var viewport := Rect2(Vector2.ZERO, Vector2(root.size))
	_check(hud.is_menu_ready() and hud._page == "controls", label + " modal is settled, visible and focused")
	_check(is_equal_approx(float(hud._settings.get("ui_scale", 0)), preference), label + " uses the requested interface preference")
	_check(viewport.encloses(hud._dialog.get_global_rect()), label + " dialog fits the actual viewport")
	_check(is_instance_valid(help) and is_instance_valid(footer) and is_instance_valid(restore), label + " exposes help, bindings, restore and Back")
	if not is_instance_valid(help) or not is_instance_valid(footer) or not is_instance_valid(restore): return
	var help_rect: Rect2 = help.get_global_rect()
	var scroll_rect: Rect2 = scroll.get_global_rect()
	var footer_rect: Rect2 = footer.get_global_rect()
	_check(viewport.encloses(footer_rect) and footer_rect.position.y >= scroll_rect.end.y - 1.0,
		label + " Back remains reachable below the scrolling list")
	var first_binding: Button
	var binding_count := 0
	for node in content.get_children():
		if node is Button and str(node.get_meta("focus_token", "")).begins_with("binding:"):
			binding_count += 1
			if first_binding == null: first_binding = node
	_check(binding_count == Profile.ACTION_LABELS.size(), label + " contains the actual full binding list")
	if top:
		_check(help.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
			label + " trick instructions preserve all text instead of truncating to an ellipsis")
		_check(help.get_line_count() > 1 and help.get_visible_line_count() >= help.get_line_count(),
			label + " every wrapped trick-help line is actually visible")
		_check(scroll_rect.grow(1.0).encloses(help_rect), label + " all trick instructions fit at the top")
		_check(not help_rect.intersects(hud._modal_details.get_global_rect())
			and (first_binding == null or first_binding.get_global_rect().position.y >= help_rect.end.y - 1.0),
			label + " trick instructions do not overlap the heading or binding rows")
	else:
		_check(scroll_rect.grow(1.0).encloses(restore.get_global_rect()), label + " Restore defaults is visible after wheel scrolling")
		footer.grab_focus()
		await _frames(2)
		_check(root.gui_get_focus_owner() == footer, label + " Back accepts native GUI focus")
	RenderingServer.force_draw(true, 1.0 / 60.0)
	var image := root.get_texture().get_image()
	_check(image.get_size() == root.size, label + " pixel size matches the actual requested viewport")
	_check(image.save_png(OUTPUT + label + ".png") == OK, label + " saved")
	var bar := scroll.get_v_scroll_bar()
	records.append({"label": label, "image": label + ".png", "resolution": [root.size.x, root.size.y],
		"ui_scale": preference, "dialog": _rect(hud._dialog.get_global_rect()),
		"scroll": _rect(scroll_rect), "help": _rect(help_rect), "help_lines": help.get_line_count(),
		"help_visible_lines": help.get_visible_line_count(), "help_overrun_behavior": help.text_overrun_behavior, "help_text": help.text,
		"first_binding": _rect(first_binding.get_global_rect()) if first_binding != null else [],
		"restore": _rect(restore.get_global_rect()), "back": _rect(footer_rect),
		"bindings": binding_count, "scroll_value": bar.value, "scroll_maximum": bar.max_value - bar.page})
	print("CLASSIC CONTROLS FRAME ", JSON.stringify(records.back()))


func _button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := _button(child, text)
		if found != null: return found
	return null


func _help_label(node: Node) -> Label:
	if node is Label and node.text.begins_with("Hold Ollie to crouch"): return node
	for child in node.get_children():
		var found := _help_label(child)
		if found != null: return found
	return null


func _click(button: Button) -> void:
	var at := button.get_global_rect().get_center()
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).has_point(at), "Controls button is within the viewport before clicking")
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _frames(2)


func _wheel(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	event.factor = 2.0
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _ready_menu() -> void:
	for frame in 90:
		await process_frame
		if game.hud.is_menu_ready(): return
	_check(false, "modal reached settled native GUI focus within its bound")


func _frames(count: int) -> void:
	for frame in count: await process_frame


func _rect(value: Rect2) -> Array[float]:
	return [value.position.x, value.position.y, value.size.x, value.size.y]


func _check(value: bool, label: String) -> void:
	if not value:
		errors += 1
		push_error(label)
