extends SceneTree
## Render deterministic UI stress fixtures over the production scene.
## These prove text/layout behavior, not achieved scores or physical trick states.
## Run tools/ui_feedback_capture.sh; outputs actual 1080p and 960×600 PNG frames.
const Main = preload("res://game/main.gd")
const OUTPUT := "res://docs/testing/screenshots/ui-cleanup"
var game: Node
var snapshot: Dictionary
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("UI evidence capture needs a rendering display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_set_size(Vector2i(1920, 1080))
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	for i in 40: await physics_frame
	game.apply_settings({"ui_scale": 1.4, "reduced_motion": true,
		"bindings": {"interact": {"key": KEY_PAGEDOWN}, "manual": {"key": KEY_DELETE}}}, false)
	game._refresh_hud()
	game.set_process(false)
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	snapshot = game.hud._state.duplicate(true)
	snapshot.merge({"score": 2147483647, "combo": 98400, "combo_base": 12300, "multiplier": 8,
		"tricks": "Clyde Carousel + Tenement Tumble + Rail Grind + Manual + Kickflip",
		"landing_window": 0.27, "special_meter": 100, "caption": "One more run.",
		"manual": true, "manual_balance": 0.25,
		"feedback": "GOAL COMPLETE  /  ONE LONG LINE + 2 MORE", "interaction_prompt": "CONE DUTY",
		"save_warning": "Saved progress could not be loaded. Existing files are safe; this session will not be saved."}, true)
	game.save_warning = snapshot.save_warning
	game._feedback = snapshot.feedback
	game.hud.update_display(snapshot)
	await _save_frame("feedback-1080-large", Vector2i(1920, 1080))
	game.hud.show_title()
	await _save_frame("title-warning-1080-large", Vector2i(1920, 1080))
	game.hud.show_settings()
	game.hud.show_controls()
	await _save_frame("controls-1080-large", Vector2i(1920, 1080))
	_set_size(Vector2i(960, 600))
	game.hud.hide_menu()
	game.hud.update_display(snapshot)
	await _save_frame("feedback-960-large", Vector2i(960, 600))
	game.hud.show_settings()
	await _save_frame("settings-960-large", Vector2i(960, 600))
	paused = false
	print("UI CAPTURE RESULT: %d failures; fixtures use 1.4× UI, remapped keyboard prompts, no profile writes" % failures)
	quit(1 if failures > 0 else 0)


func _set_size(value: Vector2i) -> void:
	root.size = value
	root.content_scale_size = value


func _save_frame(label: String, expected_size: Vector2i) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var captured := root.get_texture().get_image()
	if not game.hud.is_menu_ready():
		failures += 1
		push_error("UI capture menu is transparent, out of bounds or unfocused: " + label)
		return
	if captured.get_size() != expected_size or not is_equal_approx(float(game.hud._settings.get("ui_scale", 0.0)), 1.4):
		failures += 1
		push_error("UI capture dimensions or 1.4× preference did not match fixture: " + label)
		return
	var result := captured.save_png(OUTPUT.path_join(label + ".png"))
	if result != OK: failures += 1
	print("UI CAPTURE %s size=%s ui_scale=%.1f result=%d" % [label, captured.get_size(), game.hud._settings.ui_scale, result])
