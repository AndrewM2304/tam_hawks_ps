extends SceneTree
const Main = preload("res://game/main.gd")
const Actions = preload("res://tests/ui_integration_tests.gd")
var game: Node
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	for use_circle: bool in [false,true]:
		Actions._release_actions()
		game.hud.hide_menu()
		game.start_mode(false)
		await Actions._frames(self,45)
		var initial: Vector3=game.skater.global_position
		game.hud.toggle_goals()
		await Actions._frames(self,2)
		var cancel: InputEvent
		if use_circle:
			cancel=InputEventJoypadButton.new()
			cancel.button_index=JOY_BUTTON_B
			cancel.device=0
		else:
			cancel=InputEventKey.new()
			cancel.physical_keycode=KEY_ESCAPE
		cancel.pressed=true
		Input.parse_input_event(cancel)
		Input.flush_buffered_events()
		await Actions._frames(self,1)
		var ghost: Dictionary={"grab_buffer":game.skater._grab_buffer_remaining,
			"grab_request":game.skater._grab_request.duplicate(),"held_grab":Input.is_action_pressed("grab"),
			"pending":game.skater._pending_grab.duplicate(),"history":game.score.trick_history.duplicate()}
		cancel.pressed=false
		Input.parse_input_event(cancel)
		for code: Key in [KEY_W,KEY_SPACE]:
			var key:=InputEventKey.new()
			key.physical_keycode=code
			key.pressed=true
			Input.parse_input_event(key)
		Input.flush_buffered_events()
		await Actions._frames(self,1)
		var pop:=InputEventKey.new()
		pop.physical_keycode=KEY_SPACE
		pop.pressed=false
		Input.parse_input_event(pop)
		Input.flush_buffered_events()
		await Actions._frames(self,8)
		print("MENU_LAUNCH_PROBE ",{"circle":use_circle,"initial":initial,"paused":game.paused,
			"ghost":ghost,"history":game.score.trick_history,"launch":game.skater._launch_id,
			"takeoff":game.skater.takeoff_mode,"airborne":game.skater.airborne,"at":game.skater.global_position})
	Actions._release_actions()
	game.queue_free()
	await process_frame
	quit(0)
