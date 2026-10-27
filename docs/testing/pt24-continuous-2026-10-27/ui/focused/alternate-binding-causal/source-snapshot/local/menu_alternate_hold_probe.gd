extends SceneTree
const Main=preload("res://game/main.gd")
const Actions=preload("res://tests/ui_integration_tests.gd")
var game: Node
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	game=Main.new();game.persistence_enabled=false;root.add_child(game)
	for mode: String in ["manual_hold","ollie_hold","ollie_release"]:
		for action: String in InputMap.get_actions():Input.action_release(action)
		var action: String="manual" if mode=="manual_hold" else "ollie"
		game.apply_settings({"bindings":{"grab":{"button":JOY_BUTTON_MISC1},action:{"button":JOY_BUTTON_B}}},false)
		game.hud.hide_menu();game.start_mode(false)
		await Actions._frames(self,45)
		if action=="manual":
			_key(KEY_W,true);await Actions._frames(self,42);_key(KEY_W,false)
			await Actions._frames(self,13);_key(KEY_M,true);await Actions._frames(self,1)
		else:
			_key(KEY_SPACE,true);await Actions._frames(self,20)
		var before:=_snapshot()
		game.hud.toggle_goals();await Actions._frames(self,2)
		if mode=="ollie_release":_key(KEY_SPACE,false)
		await Actions._frames(self,3)
		_button(true);await Actions._frames(self,1)
		var immediate:=_snapshot()
		_button(false);await Actions._frames(self,3)
		print("MENU_ALT_HOLD_PROBE ",{"mode":mode,"before":before,"immediate":immediate,"after":_snapshot()})
		_key(KEY_M,false);_key(KEY_SPACE,false)
	game.queue_free();await process_frame;quit(0)
func _snapshot() -> Dictionary:
	return {"manual":game.skater.manual_active,"ollie_held":game.skater._ollie_held,"charge":game.skater._crouch_charge,
		"raw_space":Input.is_physical_key_pressed(KEY_SPACE),"raw_m":Input.is_physical_key_pressed(KEY_M),
		"polled_manual":Input.is_action_pressed("manual"),"polled_ollie":Input.is_action_pressed("ollie"),
		"air":game.skater.airborne,"crouch":game.skater.crouching,"speed":game.skater.speed,
		"history":game.score.trick_history.duplicate(),"paused":game.paused}
func _key(code: Key,pressed: bool) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed
	Input.parse_input_event(e);Input.flush_buffered_events()
func _button(pressed: bool) -> void:
	var e:=InputEventJoypadButton.new();e.device=0;e.button_index=JOY_BUTTON_B;e.pressed=pressed
	Input.parse_input_event(e);Input.flush_buffered_events()
