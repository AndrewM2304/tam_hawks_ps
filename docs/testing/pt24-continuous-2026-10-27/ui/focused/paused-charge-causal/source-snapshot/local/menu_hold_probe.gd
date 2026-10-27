extends SceneTree
const Main=preload("res://game/main.gd")
const Actions=preload("res://tests/ui_integration_tests.gd")
var game: Node
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	game=Main.new();game.persistence_enabled=false;root.add_child(game)
	for release_in_menu: bool in [false,true]:
		for action: String in InputMap.get_actions():Input.action_release(action)
		game.apply_settings({"bindings":{}},false)
		game.hud.hide_menu();game.start_mode(false)
		await Actions._frames(self,45)
		_key(KEY_SPACE,true)
		await Actions._frames(self,20)
		var before:=_snapshot()
		game.hud.toggle_goals()
		await Actions._frames(self,2)
		if release_in_menu:_key(KEY_SPACE,false)
		await Actions._frames(self,3)
		_key(KEY_ESCAPE,true)
		await Actions._frames(self,1)
		_key(KEY_ESCAPE,false)
		await Actions._frames(self,8)
		var resumed:=_snapshot()
		if not release_in_menu:
			_key(KEY_SPACE,false)
			await Actions._frames(self,6)
		print("MENU_HOLD_PROBE ",{"release_in_menu":release_in_menu,"before":before,"resumed":resumed,"after":_snapshot()})
	game.queue_free();await process_frame;quit(0)
func _snapshot() -> Dictionary:
	return {"held":game.skater._ollie_held,"charge":game.skater._crouch_charge,"raw":Input.is_action_pressed("ollie"),
		"crouch":game.skater.crouching,"air":game.skater.airborne,"speed":game.skater.speed,
		"at":game.skater.global_position,"history":game.score.trick_history.duplicate(),"paused":game.paused}
func _key(code: Key,pressed: bool) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed
	Input.parse_input_event(e);Input.flush_buffered_events()
