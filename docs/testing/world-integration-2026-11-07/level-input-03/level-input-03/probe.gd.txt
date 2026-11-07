extends SceneTree
## Parsed native GUI events, not physical-device or real-time feel acceptance.
const Main = preload("res://game/main.gd")
const Catalog = preload("res://game/progression/level_catalog.gd")
var passed := 0
var failed := 0
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _focus() -> String:
	var focused := root.gui_get_focus_owner()
	return str(focused.get_meta("focus_token", "")) if is_instance_valid(focused) else ""

func _event(pad: bool, code: int, down: bool) -> void:
	var event: InputEvent
	if pad:
		var button := InputEventJoypadButton.new()
		button.device = 0
		button.button_index = code
		button.pressed = down
		event = button
	else:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = down
		event = key
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _tap(pad: bool, code: int) -> void:
	_event(pad, code, true)
	await _frames(1)
	_event(pad, code, false)
	await _frames(4)

func _wait_level(id: String) -> void:
	for i in 90:
		await _frames(1)
		if game.level_id == id: return

func _run() -> void:
	game = Main.new()
	game.persistence_enabled = false
	game.profile_path = "user://parsed-level-input.json"
	game.legacy_profile_path = ""
	root.add_child(game)
	await _frames(10)
	# Scripted Main deliberately skips ordinary title. Establish that origin
	# once; all subsequent navigation/activation uses parsed native events.
	game.toggle_pause()
	game.hud.show_title()
	await _frames(6)
	var music_id: int = game.music.get_instance_id()
	for pad: bool in [false, true]:
		var down: int = JOY_BUTTON_DPAD_DOWN if pad else KEY_DOWN
		var accept: int = JOY_BUTTON_A if pad else KEY_ENTER
		var cancel: int = JOY_BUTTON_B if pad else KEY_ESCAPE
		var kind := "pad" if pad else "keyboard"
		_check(game.paused and game.hud._page == "title" and _focus() == "START CAREER RUN",
			kind + " starts at visible native title focus")
		await _tap(pad, down)
		await _tap(pad, down)
		_check(_focus() == "CHOOSE LEVEL", kind + " navigates to Choose Level")
		await _tap(pad, accept)
		_check(game.hud._page == "levels" and game.paused and _focus().begins_with("Merchant District"),
			kind + " opens level list with native focus")
		await _tap(pad, cancel)
		_check(game.hud._page == "title" and game.paused and game.level_id == Catalog.DEFAULT_LEVEL,
			kind + " cancels to title without replacing the world")
		# Returning restores the opener focus. Re-enter and choose City Tour.
		_check(_focus() == "CHOOSE LEVEL", kind + " restores level-list opener focus")
		await _tap(pad, accept)
		await _tap(pad, down)
		_check(_focus().begins_with("City Tour"), kind + " focuses City Tour")
		var previous_world: WeakRef = weakref(game.world)
		_event(pad, accept, true)
		await _frames(5)
		_check(game.level_id == Catalog.DEFAULT_LEVEL and game.hud._page == "levels" and game.paused,
			kind + " held accept waits for release before replacing the world")
		_event(pad, accept, false)
		await _wait_level(Catalog.LEGACY_LEVEL)
		await _frames(6)
		_check(game.level_id == Catalog.LEGACY_LEVEL and game.paused and game.hud._page == "title"
			and previous_world.get_ref() == null and game.score.trick_history.is_empty(),
			kind + " released accept replaces one world without a skating award")
		_check(game.music.get_instance_id() == music_id and not game.music._can_control,
			kind + " selection preserves isolated Music instance")
		# Return through the same ordinary menu, then actually start free skate.
		await _tap(pad, down)
		await _tap(pad, down)
		await _tap(pad, accept)
		await _tap(pad, accept)
		await _wait_level(Catalog.DEFAULT_LEVEL)
		await _frames(6)
		_check(game.level_id == Catalog.DEFAULT_LEVEL and game.hud._page == "title" and game.paused,
			kind + " returns to Merchant through ordinary level selection")
		await _tap(pad, down)
		await _tap(pad, accept)
		await _frames(25)
		_check(game.free_skate_mode and not game.paused and game.hud._page.is_empty()
			and game.skater.is_on_floor() and not game.skater.airborne and not game.skater.bailing
			and game.score.trick_history.is_empty(),
			kind + " starts native free skate after selection without an accidental ollie")
		await _tap(pad, JOY_BUTTON_START if pad else KEY_ESCAPE)
		_check(game.paused and game.hud._page == "pause", kind + " opens ordinary pause")
		# The live Music card can contain additional focusable controls.
		# Traverse using native events; never assign focus to the destination.
		for i in 14:
			print("PAUSE FOCUS ", kind, " ", i, " ", _focus())
			if _focus() == "CHOOSE LEVEL": break
			await _tap(pad, down)
		_check(_focus() == "CHOOSE LEVEL", kind + " reaches level selection from pause")
		await _tap(pad, accept)
		await _tap(pad, cancel)
		_check(game.paused and game.hud._page == "pause" and _focus() == "CHOOSE LEVEL",
			kind + " cancelling the pause level list preserves run and focus")
		await _tap(pad, cancel)
		_check(not game.paused and game.hud._page.is_empty() and game.score.trick_history.is_empty(),
			kind + " resumes once with no accidental gameplay award")
		# Reset only the declared test origin between device cohorts.
		game.toggle_pause()
		game.hud.show_title()
		await _frames(6)
	_check(not FileAccess.file_exists(game.profile_path) and not game.persistence_enabled,
		"both input cohorts preserve player profile isolation")
	paused = false
	game.free()
	await process_frame
	print("LEVEL INPUT RESULT: ", passed, " passed, ", failed, " failed")
	quit(1 if failed else 0)
