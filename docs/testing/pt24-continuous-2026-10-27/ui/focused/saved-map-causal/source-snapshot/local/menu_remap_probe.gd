extends SceneTree
const Main=preload("res://game/main.gd")
const Actions=preload("res://tests/ui_integration_tests.gd")
const Profile=preload("res://game/core/input_profile.gd")
var game: Node
var spawn: Vector3
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	spawn=game.skater.spawn_position
	for action: String in ["ollie","manual","revert","grind"]:
		for circle: bool in [false,true]:
			_release()
			game.hud.hide_menu()
			game.apply_settings({"bindings":{"grab":{"button":JOY_BUTTON_MISC1},action:{"button":JOY_BUTTON_B}}},false)
			game.skater.spawn_position=Vector3(12,.8,20) if action=="grind" else spawn
			game.start_mode(false)
			await Actions._frames(self,45)
			var prepared:=true
			if action=="manual":
				_key(KEY_W,true)
				await Actions._frames(self,42)
				_key(KEY_W,false)
				await Actions._frames(self,13)
			elif action=="revert":
				_key(KEY_SPACE,true)
				await Actions._frames(self,20)
				_key(KEY_SPACE,false)
				var air:=false
				for tick: int in 60:
					await Actions._frames(self,1)
					air=air or game.skater.airborne
					if air and game.skater.is_on_floor() and not game.skater.airborne: break
				prepared=air and game.skater.revert_remaining>0.0
			elif action=="grind":
				prepared=await _grind()
			var before:=_snapshot()
			game.hud.toggle_goals()
			if action=="grind":_key(KEY_L,false)
			await Actions._frames(self,2)
			_cancel(circle,true)
			await Actions._frames(self,1)
			print("MENU_REMAP_PROBE ",{"action":action,"circle":circle,"profile_error":Profile.last_error,
				"prepared":prepared,"before":before,"after":_snapshot(),"held_target":Input.is_action_pressed(action)})
			_cancel(circle,false)
	_release()
	game.queue_free()
	await process_frame
	quit(0)
func _grind() -> bool:
	_key(KEY_W,true)
	_key(KEY_L,true)
	await Actions._frames(self,50)
	_key(KEY_L,false)
	_key(KEY_SPACE,true)
	await Actions._frames(self,24)
	_key(KEY_SPACE,false)
	await Actions._frames(self,1)
	_key(KEY_W,false)
	var request:=false
	for tick: int in 75:
		await Actions._frames(self,1)
		if not request and game.skater.airborne and game.skater.velocity.y<0.0:
			_key(KEY_L,true)
			request=true
		if game.skater.grinding:return true
	return false
func _snapshot() -> Dictionary:
	return {"air":game.skater.airborne,"manual":game.skater.manual_active,"grinding":game.skater.grinding,
		"revert_used":game.skater._revert_used,"revert_remaining":game.skater.revert_remaining,
		"history":game.score.trick_history.duplicate(),"heading":game.skater.rotation.y,
		"at":game.skater.global_position,"speed":game.skater.speed,"paused":game.paused,
		"jump_buffer":game.skater._jump_buffer_remaining,"grind_buffer":game.skater._grind_buffer_remaining}
func _key(code: Key,pressed: bool) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed
	Input.parse_input_event(e);Input.flush_buffered_events()
func _cancel(circle: bool,pressed: bool) -> void:
	if not circle:_key(KEY_ESCAPE,pressed);return
	var e:=InputEventJoypadButton.new();e.device=0;e.button_index=JOY_BUTTON_B;e.pressed=pressed
	Input.parse_input_event(e);Input.flush_buffered_events()
func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
