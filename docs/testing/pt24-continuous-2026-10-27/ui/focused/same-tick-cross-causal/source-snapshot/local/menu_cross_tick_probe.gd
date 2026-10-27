extends SceneTree
const Main=preload("res://game/main.gd")
const Actions=preload("res://tests/ui_integration_tests.gd")
var game: Node
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	game=Main.new();game.persistence_enabled=false;root.add_child(game)
	for from_title: bool in [true,false]:
		for action: String in InputMap.get_actions():Input.action_release(action)
		game.hud.hide_menu();game.start_mode(false)
		await Actions._frames(self,45)
		game.toggle_pause()
		if from_title:game.hud.show_title()
		await Actions._frames(self,4)
		for pressed: bool in [true,false]:
			var event:=InputEventJoypadButton.new()
			event.device=0;event.button_index=JOY_BUTTON_A;event.pressed=pressed
			Input.parse_input_event(event);Input.flush_buffered_events()
		await Actions._frames(self,35)
		print("MENU_CROSS_TICK_PROBE ",{"title":from_title,"page":game.hud._page,"paused":game.paused,
			"history":game.score.trick_history,"air":game.skater.airborne,"at":game.skater.global_position,
			"ollie_held":game.skater._ollie_held,"jump_buffer":game.skater._jump_buffer_remaining})
	game.queue_free();await process_frame;quit(0)
