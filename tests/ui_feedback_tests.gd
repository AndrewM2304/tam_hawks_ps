extends RefCounted
## Regression checks for simultaneous notices, nested menu return and constrained layouts.
const HUDSource = preload("res://game/ui/hud.gd")
const InputProfileSource = preload("res://game/core/input_profile.gd")
const UIActions = preload("res://tests/ui_integration_tests.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var settings: Dictionary = game.career.settings.duplicate(true)
	var warning: String = game.save_warning
	game.persistence_enabled = false
	game.start_mode(false)
	game.apply_settings({"bindings": {}, "ui_scale": 1.0}, false)
	game.toggle_pause()
	game.hud.show_title()
	check.call(not game.hud.is_menu_ready(),
		"UI feedback: a newly built menu reports its pending layout instead of false readiness")
	for frame in 6: await tree.process_frame
	check.call(game.hud.is_menu_ready() and game.hud._dialog.modulate.a == 1.0
		and _focused_text(tree) == "START CAREER RUN",
		"UI feedback: title becomes opaque, bounded and focused after actual process frames")
	game.hud.hide_menu()
	game.start_mode(false)
	await _nested_menus(tree, game, check)
	Input.joy_connection_changed.emit(99, false)
	await UIActions._frames(tree, 3)
	check.call(game.paused and game.hud._modal_notice.is_visible_in_tree()
		and game.hud._modal_notice.text.contains("CONTROLLER DISCONNECTED"),
		"UI feedback: controller-disconnect explanation is readable above the pause menu")
	await UIActions._tap(tree, KEY_ESCAPE)
	await _binding_focus(tree, game, check)
	await _notices_and_geometry(tree, game, check)
	game.save_warning = warning
	game.hud.hide_menu()
	game.apply_settings(settings, false)
	game.start_mode(false)


static func _nested_menus(tree: SceneTree, game: Node, check: Callable) -> void:
	game.toggle_pause()
	game.hud.show_title()
	await UIActions._activate(tree, game.hud, "SETTINGS")
	await UIActions._activate(tree, game.hud, "CONTROLS")
	await UIActions._tap(tree, KEY_TAB)
	check.call(game.hud._page == "goals" and game.paused,
		"UI feedback: title → settings → controls → goals preserves paused title session")
	await UIActions._tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "controls", "UI feedback: nested goals returns to controls")
	await UIActions._tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "settings" and _focused_text(tree) == "CONTROLS",
		"UI feedback: controls returns to settings and the button that opened it")
	await UIActions._tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "title" and _focused_text(tree) == "SETTINGS" and game.paused,
		"UI feedback: settings returns to title with original focus instead of looping")
	await UIActions._activate(tree, game.hud, "START CAREER RUN")
	await UIActions._tap(tree, KEY_TAB)
	game.hud.show_settings()
	await UIActions._frames(tree, 3)
	await UIActions._activate(tree, game.hud, "CONTROLS")
	await UIActions._tap(tree, KEY_ESCAPE)
	await UIActions._tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "goals" and game.paused,
		"UI feedback: nested controls/settings return to goals without prematurely resuming")
	await UIActions._tap(tree, KEY_ESCAPE)
	check.call(game.hud._page.is_empty() and not game.paused and not tree.paused,
		"UI feedback: the live goals origin resumes exactly once after nested menus")
	game.time_remaining = 0.01
	await UIActions._frames(tree, 4)
	await UIActions._activate(tree, game.hud, "SETTINGS")
	await UIActions._activate(tree, game.hud, "CONTROLS")
	await UIActions._tap(tree, KEY_TAB)
	for i in 3: await UIActions._tap(tree, KEY_ESCAPE)
	check.call(game.hud._page == "results" and game.run_finished and _focused_text(tree) == "SETTINGS",
		"UI feedback: three nested results pages return to results with focus and finished state")
	await UIActions._activate(tree, game.hud, "ONE MORE RUN")


static func _binding_focus(tree: SceneTree, game: Node, check: Callable) -> void:
	await UIActions._tap(tree, KEY_ESCAPE)
	await UIActions._activate(tree, game.hud, "CONTROLS")
	await UIActions._activate(tree, game.hud, "Interact  /")
	var modified := InputEventKey.new()
	modified.physical_keycode = KEY_B
	modified.keycode = KEY_B
	modified.ctrl_pressed = true
	modified.pressed = true
	Input.parse_input_event(modified)
	await UIActions._frames(tree, 2)
	modified.pressed = false
	Input.parse_input_event(modified)
	check.call(game.hud._binding_action == "interact" and game.career.settings.bindings.is_empty()
		and game.hud._binding_status.text.contains("modifier"),
		"UI feedback: modified key rejection leaves binding capture and preferences intact")
	await UIActions._tap(tree, KEY_ESCAPE)
	check.call(str(tree.root.gui_get_focus_owner().get_meta("focus_token", "")) == "binding:interact",
		"UI feedback: cancelling binding capture keeps the selected action focused")
	await UIActions._activate(tree, game.hud, "Interact  /")
	await UIActions._tap(tree, KEY_PAGEDOWN)
	check.call(str(tree.root.gui_get_focus_owner().get_meta("focus_token", "")) == "binding:interact"
		and game.hud._scroll.scroll_vertical > 0,
		"UI feedback: successful rebinding preserves action focus and scroll position")
	await UIActions._activate(tree, game.hud, "RESTORE DEFAULT CONTROLS")
	check.call(_focused_text(tree) == "RESTORE DEFAULT CONTROLS" and game.hud._scroll.scroll_vertical > 0,
		"UI feedback: restoring defaults leaves its visible button focused after rebuilding")
	await UIActions._tap(tree, KEY_ESCAPE)
	await UIActions._tap(tree, KEY_ESCAPE)


static func _notices_and_geometry(tree: SceneTree, game: Node, check: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(viewport)
	var hud := HUDSource.new()
	viewport.add_child(hud)
	var snapshot: Dictionary = {
		"time": 72, "score": 2147483647, "combo": 98400, "combo_base": 12300, "multiplier": 8,
		"tricks": "Clyde Carousel + Tenement Tumble + Rail Grind + Manual + Kickflip",
		"feedback": "GOAL COMPLETE  /  ONE LONG LINE + 2 MORE", "landing_window": 0.27,
		"caption": "One more run.", "interaction_prompt": "CONE DUTY", "special_meter": 100,
		"location": "Royal Exchange Square", "manual": true, "manual_balance": 0.3,
		"save_warning": "Saved progress could not be loaded. Existing files are safe; this session will not be saved.",
		"goals": game.career.goals_snapshot(), "unlocks": game.career.unlocks(),
		"settings": {"ui_scale": 1.4, "captions": true, "reduced_motion": true, "bindings": {}}
	}
	hud.update_display(snapshot)
	await UIActions._frames(tree, 3)
	check.call(hud._feedback.text == snapshot.feedback and hud._combo_status.text.contains("LINK IT")
		and not hud._combo.text.is_empty(),
		"UI feedback: event notice, active combo and timed link cue remain visible together")
	check.call(not hud._feedback.get_global_rect().intersects(hud._combo.get_global_rect())
		and not hud._feedback.get_global_rect().intersects(hud._combo_status.get_global_rect()),
		"UI feedback: event and combo text occupy separate screen regions")
	var bindings := {"interact": {"key": KEY_PAGEDOWN, "button": JOY_BUTTON_LEFT_STICK}, "manual": {"key": KEY_DELETE}}
	check.call(InputProfileSource.apply_saved(bindings), "UI feedback: long-key prompt fixture applies valid live bindings")
	snapshot.settings.bindings = bindings
	hud.update_display(snapshot)
	check.call(hud._prompt.text == "PageDown  ·  CONE DUTY" and hud._combo_status.text.contains("Delete MANUAL"),
		"UI feedback: externally changed bindings refresh both interaction and combo link prompts")
	hud._controller_active = true
	hud.update_display(snapshot)
	check.call(hud._prompt.text == "L3  ·  CONE DUTY" and not hud._balance_label.text.contains("Left stick"),
		"UI feedback: controller prompts use mapped buttons and compact stick directions")
	check.call(hud._save_warning.is_visible_in_tree() and hud._save_warning.text == snapshot.save_warning,
		"UI feedback: persistent save failure stays visible during a live combo")
	for size in [Vector2i(1920, 1080), Vector2i(960, 600), Vector2i(640, 480)]:
		viewport.size = size
		hud.update_display(snapshot)
		await UIActions._frames(tree, 3)
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		var all_inside := true
		for control in [hud._top, hud._goals, hud._balance_panel, hud._speed_panel,
			hud._special_panel, hud._combo, hud._tricks, hud._combo_status,
			hud._feedback_panel, hud._feedback,
			hud._caption, hud._prompt, hud._footer, hud._save_warning]:
			all_inside = all_inside and bounds.encloses(control.get_global_rect())
		check.call(all_inside, "UI feedback: all active HUD regions fit %s at 1.4× UI" % size)
		check.call(not hud._balance_panel.get_global_rect().intersects(hud._goals.get_global_rect())
			and not hud._save_warning.get_global_rect().intersects(hud._speed_panel.get_global_rect()),
			"UI feedback: balance, goals and save warning have clear space at %s" % size)
		var score_font: Font = hud._score.get_theme_font("font")
		check.call(score_font.get_string_size(hud._score.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			hud._score.get_theme_font_size("font_size")).x <= hud._score.size.x,
			"UI feedback: full ten-digit score fits without ellipsis at %s" % size)
		hud.show_title()
		await UIActions._frames(tree, 3)
		check.call(bounds.encloses(hud._dialog.get_global_rect()) and hud._modal_warning.is_visible_in_tree(),
			"UI feedback: title and persistent warning fit %s at 1.4× UI" % size)
		check.call(hud._modal_title.size.y >= hud._modal_title.get_theme_font("font").get_height(45),
			"UI feedback: large title has enough height to render its complete line at %s" % size)
		hud.show_settings()
		hud.show_controls()
		await UIActions._frames(tree, 3)
		check.call(bounds.encloses(hud._dialog.get_global_rect()) and hud._scroll.size.y >= 80,
			"UI feedback: nested controls retain a usable scroll region at %s" % size)
		hud.hide_menu()
	snapshot.save_warning = ""
	hud.update_display(snapshot)
	hud.show_settings()
	await UIActions._frames(tree, 3)
	check.call(not hud._save_warning.visible and not hud._modal_warning.visible,
		"UI feedback: successful save recovery removes the warning from live and modal layouts")
	viewport.queue_free()
	await tree.process_frame
	InputProfileSource.reset_defaults()


static func _focused_text(tree: SceneTree) -> String:
	var focus := tree.root.gui_get_focus_owner()
	return focus.text if focus is Button else ""
