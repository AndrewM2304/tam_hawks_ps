extends RefCounted
## Native menu input settles before gameplay; real held and rapid trick inputs survive.
const Actions = preload("res://tests/ui_integration_tests.gd")


static func run(tree: SceneTree,game: Node,check: Callable) -> void:
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
	await _saved_back_matrix(tree,game,check)
	await _held_bindings(tree,game,check)
	await run_boundary(tree,game,check)
	await _transition_invalidation(tree,game,check)
	_release()
	game.hud.hide_menu()
	game.apply_settings(settings,false)
	game.start_mode(false)
	check.call(not game.persistence_enabled and not game.music._can_control and not game.music._persist,
		"menu launch: all native jump controls preserve personal profile and Music isolation")


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
	await Actions._frames(tree,2)


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
	var expected: String="Nose Grab" if family=="grab" else "Frontside Shuvit"
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
	var remembered: bool=game.skater._grab_buffer_remaining>0.0 and game.skater._trick_input.queued_action_count()==0
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
	for key: Key in [KEY_W,KEY_S,KEY_D,KEY_M,KEY_K,KEY_J,KEY_SPACE,KEY_L,KEY_ESCAPE]: _key(key,false)
	for button: JoyButton in [JOY_BUTTON_A,JOY_BUTTON_B]: _button(button,false)
	for action: String in InputMap.get_actions(): Input.action_release(action)


static func _saved_back_matrix(tree: SceneTree,game: Node,check: Callable) -> void:
	var spawn: Vector3=game.skater.spawn_position
	for action: String in ["ollie","manual","revert","grind"]:
		game.apply_settings({"bindings":{"grab":{"button":JOY_BUTTON_MISC1},action:{"button":JOY_BUTTON_B}}},false)
		game.skater.spawn_position=Vector3(12,0.8,20) if action=="grind" else spawn
		await _fresh(tree,game)
		var prepared:=true
		if action=="manual":
			_key(KEY_W,true)
			await Actions._frames(tree,42)
			_key(KEY_W,false)
			await Actions._frames(tree,13)
		elif action=="revert":
			_key(KEY_SPACE,true)
			await Actions._frames(tree,20)
			_key(KEY_SPACE,false)
			var flew:=false
			for tick: int in 60:
				await Actions._frames(tree,1)
				flew=flew or game.skater.airborne
				if flew and game.skater.is_on_floor() and not game.skater.airborne: break
			prepared=flew and game.skater.revert_remaining>0.0
		elif action=="grind": prepared=await _catch_rail(tree,game)
		var before: Array=game.score.trick_history.duplicate()
		var heading: float=game.skater.rotation.y
		game.hud.toggle_goals()
		if action=="grind": _key(KEY_L,false)
		await Actions._frames(tree,2)
		_button(JOY_BUTTON_B,true)
		await Actions._frames(tree,1)
		_button(JOY_BUTTON_B,false)
		await Actions._frames(tree,3)
		var state_ok: bool=game.skater.grinding if action=="grind" else not game.skater.airborne and not game.skater.manual_active
		check.call(prepared and state_ok and not game.paused and game.score.trick_history==before
			and absf(game.skater.rotation.y-heading)<0.0001,
			"menu launch: saved Circle "+action+" Back preserves actual native state and awards no gameplay action")
		print("MENU_SAVED_BACK ",{"action":action,"prepared":prepared,"state_ok":state_ok,"history":game.score.trick_history})
	game.skater.spawn_position=spawn
	game.apply_settings({"bindings":{}},false)


static func _catch_rail(tree: SceneTree,game: Node) -> bool:
	_key(KEY_W,true)
	_key(KEY_L,true)
	await Actions._frames(tree,50)
	_key(KEY_L,false)
	_key(KEY_SPACE,true)
	await Actions._frames(tree,24)
	_key(KEY_SPACE,false)
	await Actions._frames(tree,1)
	_key(KEY_W,false)
	var requested:=false
	for tick: int in 75:
		await Actions._frames(tree,1)
		if not requested and game.skater.airborne and game.skater.velocity.y<0.0:
			_key(KEY_L,true)
			requested=true
		if game.skater.grinding: return true
	return false


static func _held_bindings(tree: SceneTree,game: Node,check: Callable) -> void:
	for mode: String in ["manual_hold","ollie_hold","ollie_release","default_release"]:
		var action: String="manual" if mode=="manual_hold" else "ollie"
		var bindings: Dictionary={} if mode=="default_release" else {"grab":{"button":JOY_BUTTON_MISC1},action:{"button":JOY_BUTTON_B}}
		game.apply_settings({"bindings":bindings},false)
		await _fresh(tree,game)
		if action=="manual":
			_key(KEY_W,true)
			await Actions._frames(tree,42)
			_key(KEY_W,false)
			await Actions._frames(tree,13)
			_key(KEY_M,true)
			await Actions._frames(tree,1)
		else:
			_key(KEY_SPACE,true)
			await Actions._frames(tree,20)
		var charge: float=game.skater._crouch_charge
		var before: Array=game.score.trick_history.duplicate()
		game.hud.toggle_goals()
		await Actions._frames(tree,2)
		if mode.ends_with("release"): _key(KEY_SPACE,false)
		await Actions._frames(tree,3)
		_cancel(mode!="default_release",true)
		await Actions._frames(tree,3)
		_cancel(mode!="default_release",false)
		await Actions._frames(tree,3)
		var valid: bool=not game.paused and not game.skater.airborne and game.score.trick_history==before
		if mode=="manual_hold": valid=valid and game.skater.manual_active and Input.is_action_pressed("manual") and Input.is_physical_key_pressed(KEY_M)
		elif mode=="ollie_hold": valid=valid and game.skater._ollie_held and Input.is_action_pressed("ollie") and game.skater._crouch_charge>=charge
		else: valid=valid and not game.skater._ollie_held and game.skater._crouch_charge==0.0 and not game.skater.crouching
		check.call(valid,"menu launch: "+mode+" preserves the independent physical hold or cancels only its paused release through paired Back release")
		print("MENU_HELD_BINDING ",{"mode":mode,"valid":valid,"charge":game.skater._crouch_charge,"held":game.skater._ollie_held,"history":game.score.trick_history})
		if mode=="ollie_hold":
			_key(KEY_SPACE,false)
			await Actions._frames(tree,2)
			check.call(game.skater.airborne and game.score.trick_history.has("Ollie"),
				"menu launch: the preserved real Space charge still jumps on its later gameplay release")
		if mode=="ollie_release":
			_button(JOY_BUTTON_B,true)
			await Actions._frames(tree,12)
			_button(JOY_BUTTON_B,false)
			await Actions._frames(tree,2)
			check.call(game.skater.airborne and game.score.trick_history.has("Ollie"),
				"menu launch: a new genuine Circle Ollie works after its consumed menu press and release retire")
	game.apply_settings({"bindings":{}},false)


static func run_boundary(tree: SceneTree,game: Node,check: Callable) -> void:
	game.apply_settings({"bindings":{}},false)
	for kind: String in ["start","resume","restart","switch"]:
		await _fresh(tree,game)
		game.toggle_pause()
		if kind=="start": game.hud.show_title()
		await Actions._frames(tree,4)
		if kind=="restart": game.hud._restart.grab_focus()
		elif kind=="switch": game.hud._free.grab_focus()
		var requested:=Engine.get_physics_frames()
		_button(JOY_BUTTON_A,true)
		_button(JOY_BUTTON_A,false)
		var remained_paused: bool=game.paused and not game.hud._page.is_empty()
		await Actions._frames(tree,35)
		check.call(remained_paused and Engine.get_physics_frames()>requested and not game.paused
			and game.hud._page.is_empty() and game.score.trick_history.is_empty() and not game.skater.airborne
			and game.free_skate_mode==(kind=="switch"),
			"menu launch boundary: same-physics-tick native Cross "+kind+" settles while paused before actual gameplay without Ollie")
		print("MENU_BOUNDARY ",{"kind":kind,"physics_hz":Engine.physics_ticks_per_second,"fixed_render_hz":Engine.get_frames_per_second(),"same_update_paused":remained_paused,"history":game.score.trick_history})
	await _fresh(tree,game)
	game.hud.toggle_goals()
	await Actions._frames(tree,3)
	var resumes:={"count":0,"physics":-1}
	var requested:=Engine.get_physics_frames()
	var observer:=func(): resumes.count+=1;resumes.physics=Engine.get_physics_frames()
	game.hud.pause_requested.connect(observer)
	_button(JOY_BUTTON_B,true)
	_button(JOY_BUTTON_B,false)
	_button(JOY_BUTTON_B,true)
	_button(JOY_BUTTON_B,false)
	var remained_paused: bool=game.paused and game.hud._page=="goals"
	await Actions._frames(tree,4)
	game.hud.pause_requested.disconnect(observer)
	check.call(remained_paused and resumes.count==1 and resumes.physics>requested and not game.paused
		and game.score.trick_history.is_empty() and game.skater._grab_buffer_remaining<=0.0,
		"menu launch boundary: duplicate same-update Circle Back dispatches once after a paused physics pass")


static func _transition_invalidation(tree: SceneTree,game: Node,check: Callable) -> void:
	for change: String in ["page","restart","results","blocked","hidden"]:
		await _fresh(tree,game)
		game.hud.toggle_goals()
		await Actions._frames(tree,3)
		_button(JOY_BUTTON_B,true)
		_button(JOY_BUTTON_B,false)
		match change:
			"page": game.hud.show_settings()
			"restart": game.restart_run()
			"results":
				game._finish_run()
				game._refresh_hud()
			"blocked": game.hud.debug_input_blocked=true
			"hidden": game.hud.hide()
		await Actions._frames(tree,4)
		var expected_pause: bool=change!="restart"
		var valid: bool=game.paused==expected_pause and game.hud._pending_gameplay_transition.is_empty()
		if change=="results": valid=valid and game.run_finished
		if change=="page": valid=valid and game.hud._page=="settings"
		check.call(valid,"menu launch boundary: queued Back aborts after "+change+" invalidates its originating modal")
		game.hud.debug_input_blocked=false
		game.hud.show()
		if game.run_finished: game.start_mode(false)


static func _button(button: JoyButton,pressed: bool) -> void:
	var event:=InputEventJoypadButton.new()
	event.device=0
	event.button_index=button
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
