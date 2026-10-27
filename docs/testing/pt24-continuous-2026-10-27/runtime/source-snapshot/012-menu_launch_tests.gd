extends RefCounted
## A consumed Back press must not select a family or suppress steer-spin on
## the next actual jump. Preserve real queued and already consumed extensions.
const Actions = preload("res://tests/ui_integration_tests.gd")
const TrickInput = preload("res://game/tricks/trick_input.gd")


static func run(tree: SceneTree,game: Node,check: Callable) -> void:
	_queue(check)
	var settings: Dictionary=game.career.settings.duplicate(true)
	game.apply_settings({"bindings":{}},false)
	for circle: bool in [false,true]:
		await _launch_after_back(tree,game,check,circle)
	var spin: Array[float]=[]
	for circle: bool in [false,true]: spin.append(await _spin_after_back(tree,game,check,circle))
	check.call(spin[0]>0.1 and absf(spin[0]-spin[1])<0.0001,
		"menu launch: consumed Circle Back preserves the same immediate native steering-spin response as Escape")
	for family: String in ["grab","flip"]:
		await _real_family(tree,game,check,family)
	await _manual_extension(tree,game,check)
	_release()
	game.hud.hide_menu()
	game.apply_settings(settings,false)
	game.start_mode(false)
	check.call(not game.persistence_enabled and not game.music._can_control and not game.music._persist,
		"menu launch: all native jump controls preserve personal profile and Music isolation")


static func _queue(check: Callable) -> void:
	var input:=TrickInput.new()
	input.sample_frame(Vector2.ZERO,["grab"],1.0/60.0)
	var count:=input.queued_action_count()
	check.call(input.has_action("grab",0.0) and not input.has_action("flip",0.0)
		and input.queued_action_count()==count,
		"menu launch queue: a fresh accepted family is queried without consuming or creating an edge")
	check.call(not input.has_action("unknown") and not input.has_action("grab",-0.1)
		and not input.has_action("grab",INF) and not input.has_action("grab",NAN),
		"menu launch queue: invalid family or non-finite/negative lifetime never admits an edge")
	input.sample_frame(Vector2.ZERO,[],0.02)
	check.call(not input.has_action("grab",0.0) and input.has_action("grab",0.03),
		"menu launch queue: same-sample membership distinguishes a real remembered family from a new edge")
	var real:=input.pop_action("grab",0.03)
	check.call(real.get("action")=="grab" and not input.has_action("grab"),
		"menu launch queue: an inspected edge remains available to its real consumer exactly once")
	input.sample_frame(Vector2.ZERO,["flip"],0.01)
	input.sample_frame(Vector2.ZERO,[],0.46)
	check.call(not input.has_action("flip",10.0),
		"menu launch queue: requested lifetime cannot revive an edge beyond the original maximum queue age")


static func _fresh(tree: SceneTree,game: Node) -> void:
	_release()
	game.hud.hide_menu()
	game.start_mode(false)
	await Actions._frames(tree,45)


static func _back(tree: SceneTree,game: Node,circle: bool) -> void:
	game.hud.toggle_goals()
	await Actions._frames(tree,2)
	_cancel(circle,true)
	await Actions._frames(tree,1)
	_cancel(circle,false)


static func _launch_after_back(tree: SceneTree,game: Node,check: Callable,circle: bool) -> void:
	await _fresh(tree,game)
	var supported: bool=game.skater.is_on_floor() and not game.skater.airborne
	await _back(tree,game,circle)
	var buffer: float=game.skater._grab_buffer_remaining
	_key(KEY_W,true)
	_key(KEY_SPACE,true)
	await Actions._frames(tree,1)
	_key(KEY_SPACE,false)
	await Actions._frames(tree,8)
	check.call(supported and not game.paused and game.hud._page.is_empty()
		and game.skater.airborne and not game.skater.bail_active,
		"menu launch: real "+("Circle" if circle else "Escape")+" Back returns a supported run to actual fresh-input flight")
	check.call(game.score.trick_history==["Nollie"] and game.skater._launch_id=="nollie"
		and game.skater.takeoff_mode=="Nollie" and game.skater._pending_grab.is_empty(),
		"menu launch: "+("Circle" if circle else "Escape")+" Back cannot turn the next north-modified Nollie into an Ollie or Grab")
	print("MENU_LAUNCH_RESULT ",{"circle":circle,"back_grab_buffer":buffer,
		"history":game.score.trick_history,"launch":game.skater._launch_id,
		"takeoff":game.skater.takeoff_mode,"at":game.skater.global_position})


static func _spin_after_back(tree: SceneTree,game: Node,check: Callable,circle: bool) -> float:
	await _fresh(tree,game)
	_key(KEY_SPACE,true)
	await Actions._frames(tree,20)
	_key(KEY_SPACE,false)
	await Actions._frames(tree,2)
	await _back(tree,game,circle)
	var before: float=game.skater._air_spin
	var history: Array=game.score.trick_history.duplicate()
	_key(KEY_D,true)
	await Actions._frames(tree,3)
	_key(KEY_D,false)
	var spin: float=absf(game.skater._air_spin-before)
	check.call(game.skater.airborne and game.skater._grab_remaining<=0.0
		and game.score.trick_history==history,
		"menu launch: actual "+("Circle" if circle else "Escape")+" airborne Back/steer adds no unintended family award")
	print("MENU_BACK_SPIN ",{"circle":circle,"spin_delta":spin,
		"selection_remaining":game.skater._selection_remaining,"history":game.score.trick_history})
	return spin


static func _real_family(tree: SceneTree,game: Node,check: Callable,family: String) -> void:
	await _fresh(tree,game)
	_key(KEY_W,true)
	_key(KEY_K if family=="grab" else KEY_J,true)
	_key(KEY_SPACE,true)
	await Actions._frames(tree,1)
	_key(KEY_SPACE,false)
	await Actions._frames(tree,5)
	var expected: String="Nose Grab" if family=="grab" else "Hardflip"
	check.call(game.skater.airborne and game.skater._launch_id=="ollie"
		and game.score.trick_history==["Ollie",expected],
		"menu launch: a genuine queued north "+family+" still uses plain Ollie and its actual directional family award")
	print("MENU_REAL_FAMILY ",{"family":family,"history":game.score.trick_history,
		"launch":game.skater._launch_id,"takeoff":game.skater.takeoff_mode})


static func _manual_extension(tree: SceneTree,game: Node,check: Callable) -> void:
	await _fresh(tree,game)
	_key(KEY_W,true)
	await Actions._frames(tree,42)
	_key(KEY_W,false)
	await Actions._frames(tree,13)
	_key(KEY_M,true)
	await Actions._frames(tree,1)
	_key(KEY_S,true)
	_key(KEY_K,true)
	await Actions._frames(tree,1)
	var extended: bool=game.skater.manual_active and game.skater.manual_trick_id=="pogo"
	var remembered: bool=game.skater._grab_buffer_remaining>0.0 and not game.skater._trick_input.has_action("grab")
	_key(KEY_S,false)
	_key(KEY_K,false)
	_key(KEY_W,true)
	_key(KEY_SPACE,true)
	await Actions._frames(tree,1)
	_key(KEY_SPACE,false)
	await Actions._frames(tree,5)
	check.call(extended and remembered,
		"menu launch: real Manual then south/Grab consumes its queued Pogo extension after establishing remembered launch metadata")
	check.call(game.skater.airborne and game.skater._launch_id=="ollie"
		and game.score.trick_history.has("Pogo") and game.score.trick_history.back()=="Ollie",
		"menu launch: immediate real extension-to-pop preserves its existing plain-Ollie family preparation after queue consumption")
	print("MENU_MANUAL_EXTENSION_POP ",{"extended":extended,"remembered":remembered,
		"history":game.score.trick_history,"launch":game.skater._launch_id,"at":game.skater.global_position})


static func _key(code: Key,pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


static func _cancel(circle: bool,pressed: bool) -> void:
	if not circle:
		_key(KEY_ESCAPE,pressed)
		return
	var event:=InputEventJoypadButton.new()
	event.device=0
	event.button_index=JOY_BUTTON_B
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


static func _release() -> void:
	for action: String in InputMap.get_actions(): Input.action_release(action)
