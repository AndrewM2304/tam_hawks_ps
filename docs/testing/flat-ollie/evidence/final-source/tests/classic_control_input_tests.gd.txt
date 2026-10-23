extends RefCounted
## Independent controller trials: mapped joypad events and real supported physics.
## Only trial resets assign a starting state. No tick forces speed, pose, balance,
## trick timers or floor contact, and these checks do not certify a real DualSense.
const Profile = preload("res://game/core/input_profile.gd")
const Skater = preload("res://game/player/skater.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Line = preload("res://game/tricks/grind_line.gd")

class SpecialProbe extends "res://game/main.gd":
	var attempts: Array[String] = []
	func _try_special(trick_id: String) -> void:
		attempts.append(trick_id)


static func run(tree: SceneTree, check: Callable) -> void:
	var saved: Dictionary = Profile._bindings.duplicate(true)
	Profile.reset_defaults()
	_release()
	_special_freshness(check)
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	check.call(rider.is_on_floor() and absf(rider.global_position.y)<.025,
		"classic pad: production Skater settles on real supported floor")
	await _mapping(tree, rider, check)
	await _ground_drive(tree, rider, check)
	for device: String in ["dpad","stick"]:
		for nose: bool in [false,true]:
			await _manual(tree, rider, check, device, nose)
	await _manual(tree,rider,check,"dpad",false,true)
	await _shortcut(tree, rider, check)
	for scenario: String in ["direct","opposite_hold","expired","noise","releases","slow","disabled","entry_reset"]:
		await _refusal(tree, rider, check, scenario)
	await _cooldown(tree, rider, check)
	await _pause(tree,rider,check)
	for released: bool in [false,true]:
		await _air_manual_refusal(tree, rider, check, released)
	await _face_tricks(tree, rider, check)
	_release()
	fixture.root.queue_free()
	await tree.process_frame
	await _frames(tree,1)
	var restored: bool = Profile.apply_saved(saved)
	var quiet := true
	for action: String in Profile.ACTION_LABELS:
		quiet = not Input.is_action_pressed(action) and quiet
	check.call(restored and quiet and not is_instance_valid(rider),
		"classic pad: every physical input, saved profile and supported fixture is cleaned up")


static func _special_freshness(check: Callable) -> void:
	# Exercise only Main's discrete event handler. This node never enters a tree
	# or builds World/HUD; the override records attempts, not score eligibility.
	var probe := SpecialProbe.new()
	for value: float in [-.8,-.95,-.7,-1.0]:
		probe._unhandled_input(_motion(JOY_AXIS_RIGHT_Y,value))
	check.call(probe.attempts==["special_clyde_carousel"],
		"classic pad: repeated held right-stick events attempt a special only once")
	for value: float in [.9,.75,1.0]:
		probe._unhandled_input(_motion(JOY_AXIS_RIGHT_Y,value))
	check.call(probe.attempts==["special_clyde_carousel","special_tenement_tumble"],
		"classic pad: opposite right-stick excursion reaches the distinct special once")
	probe._unhandled_input(_motion(JOY_AXIS_RIGHT_Y,0))
	for value: float in [.9,.8]:
		probe._unhandled_input(_motion(JOY_AXIS_RIGHT_Y,value))
	probe._unhandled_input(_motion(JOY_AXIS_RIGHT_Y,0))
	for value: float in [-.9,-.8]:
		probe._unhandled_input(_motion(JOY_AXIS_RIGHT_Y,value))
	check.call(probe.attempts==["special_clyde_carousel","special_tenement_tumble",
		"special_tenement_tumble","special_clyde_carousel"],
		"classic pad: sampled neutral resets each special latch without held-event spam")
	probe.free()


static func _mapping(tree: SceneTree, rider: Node3D, check: Callable) -> void:
	var directions := true
	for pair: Array in [[JOY_BUTTON_DPAD_UP,"push"],[JOY_BUTTON_DPAD_DOWN,"brake"],
		[JOY_BUTTON_DPAD_LEFT,"steer_left"],[JOY_BUTTON_DPAD_RIGHT,"steer_right"]]:
		_pad(pair[0],true)
		await _frames(tree,1)
		directions = Input.get_action_strength(pair[1])>.99 and not Input.is_action_pressed("special_one") \
			and not Input.is_action_pressed("special_two") and not Input.is_action_pressed("interact") and directions
		_pad(pair[0],false)
		await _frames(tree,1)
	check.call(directions,
		"classic pad: all four actual D-pad events drive movement without specials or interaction")
	var specials := true
	for direction: float in [-.9,.9]:
		_axis(JOY_AXIS_RIGHT_Y,direction)
		await _frames(tree,1)
		var expected: String = "special_one" if direction<0 else "special_two"
		var other: String = "special_two" if direction<0 else "special_one"
		specials = Input.is_action_pressed(expected) and not Input.is_action_pressed(other) \
			and not Input.is_action_pressed("push") and not Input.is_action_pressed("brake") \
			and not Input.is_action_pressed("interact") and specials
	_axis(JOY_AXIS_RIGHT_Y,0)
	check.call(specials, "classic pad: signed right-stick Y reaches two distinct specials without movement")
	var shortcuts := true
	for pair: Array in [[JOY_BUTTON_LEFT_STICK,"interact"],[JOY_BUTTON_RIGHT_STICK,"restart"],
		[JOY_BUTTON_TOUCHPAD,"free_skate"]]:
		_pad(pair[0],true)
		await _frames(tree,1)
		shortcuts = Input.is_action_pressed(pair[1]) and shortcuts
		_pad(pair[0],false)
		await _frames(tree,1)
	_axis(JOY_AXIS_TRIGGER_RIGHT,.9)
	await _frames(tree,1)
	shortcuts = Input.is_action_pressed("revert") and not Input.is_action_pressed("manual") and shortcuts
	_axis(JOY_AXIS_TRIGGER_RIGHT,0)
	check.call(shortcuts and not rider.manual_active,
		"classic pad: L3 interaction, R3 restart, Touchpad free skate and R2 revert retain distinct inputs")


static func _ground_drive(tree: SceneTree, rider: Node3D, check: Callable) -> void:
	await _reset(tree,rider)
	var start: Vector3 = rider.global_position
	_pad(JOY_BUTTON_DPAD_UP,true)
	await _frames(tree,45)
	_pad(JOY_BUTTON_DPAD_UP,false)
	var accelerated: bool = rider.speed>5 and rider.global_position.distance_to(start)>1
	var heading: float = rider.rotation.y
	_pad(JOY_BUTTON_DPAD_RIGHT,true)
	await _frames(tree,6)
	_pad(JOY_BUTTON_DPAD_RIGHT,false)
	var turned: bool = absf(wrapf(rider.rotation.y-heading,-PI,PI))>.025
	var before: float = rider.speed
	_pad(JOY_BUTTON_DPAD_DOWN,true)
	await _frames(tree,8)
	_pad(JOY_BUTTON_DPAD_DOWN,false)
	check.call(accelerated and turned and rider.speed<before-1 and rider.is_on_floor() and not rider.manual_active,
		"classic pad: D-pad pushes, physically carves and brakes without creating a manual")


static func _manual(tree: SceneTree, rider: Node3D, check: Callable, device: String, nose: bool, same_tick: bool = false) -> void:
	await _roll(tree,rider)
	var seen: Array[String] = []
	var listener: Callable = func(name: String, _points: int): seen.append(name)
	rider.trick_performed.connect(listener)
	var first: float = 1 if nose else -1
	_vertical(device,first)
	await _frames(tree,2)
	_vertical(device,0)
	if not same_tick: await _frames(tree,2)
	_vertical(device,-first)
	await _frames(tree,2)
	var id: String = "nose_manual" if nose else "manual"
	check.call(rider.manual_active and rider.manual_id==id and _manual_count(seen)==1,
		"classic pad: %s %s gesture enters %s exactly once" % [device,
			"release/opposite within one tick" if same_tick else "sampled-neutral",id])
	_vertical(device,0)
	await _frames(tree,2)
	var heading: float = rider.rotation.y
	var positive: float = rider.manual_balance
	_horizontal(device,-.9)
	await _frames(tree,2)
	var left: float = rider.manual_balance
	check.call(rider.manual_active and positive>0 and absf(left)<absf(positive)-.008,
		"classic pad: %s Left corrects positive %s balance" % [device,id])
	await _frames(tree,6)
	_horizontal(device,0)
	await _frames(tree,1)
	var negative: float = rider.manual_balance
	_horizontal(device,.9)
	await _frames(tree,4)
	_horizontal(device,0)
	print("CLASSIC PAD MANUAL device=",device," nose=",nose," same_tick=",same_tick,
		" balance=",[positive,left,negative,rider.manual_balance]," yaw_delta=",wrapf(rider.rotation.y-heading,-PI,PI),
		" speed=",rider.speed," active=",rider.manual_active," awards=",seen)
	check.call(rider.manual_active and negative<-.025 and absf(rider.manual_balance)<absf(negative)-.008
		and absf(wrapf(rider.rotation.y-heading,-PI,PI))<.0001 and _manual_count(seen)==1
		and rider.manual_id==id and rider.is_on_floor(),
		"classic pad: %s Right corrects negative %s balance without carving, relabel or duplicate award" % [device,id])
	if device=="dpad" and not nose and not same_tick:
		_pad(JOY_BUTTON_RIGHT_SHOULDER,true)
		await _frames(tree,5)
		_pad(JOY_BUTTON_RIGHT_SHOULDER,false)
		check.call(rider.manual_active and absf(wrapf(rider.rotation.y-heading,-PI,PI))>.015
			and _manual_count(seen)==1,
			"classic pad: R1 can deliberately carve during a latched manual while directions balance")
	rider.trick_performed.disconnect(listener)


static func _shortcut(tree: SceneTree, rider: Node3D, check: Callable) -> void:
	await _roll(tree,rider)
	_axis(JOY_AXIS_TRIGGER_LEFT,.9)
	await _frames(tree,2)
	var entered: bool = rider.manual_active and rider.manual_id=="manual"
	_axis(JOY_AXIS_TRIGGER_LEFT,0)
	await _frames(tree,2)
	check.call(entered and not rider.manual_active,
		"classic pad: optional held L2 manual still enters on real ground and ends when released")


static func _refusal(tree: SceneTree, rider: Node3D, check: Callable, scenario: String) -> void:
	if scenario=="slow": await _reset(tree,rider)
	else: await _roll(tree,rider)
	var seen: Array[String] = []
	var listener: Callable = func(name: String, _points: int): seen.append(name)
	rider.trick_performed.connect(listener)
	if scenario=="disabled": rider.set_trick_entries_enabled(false)
	if scenario=="noise":
		for value: float in [-.15,0,.15,0]:
			_vertical("stick",value)
			await _frames(tree,2)
	elif scenario=="releases":
		_pad(JOY_BUTTON_DPAD_UP,false)
		await _frames(tree,2)
		_pad(JOY_BUTTON_DPAD_DOWN,false)
		await _frames(tree,2)
	elif scenario=="direct":
		_vertical("stick",-1)
		await _frames(tree,2)
		_vertical("stick",1)
		await _frames(tree,2)
		_vertical("stick",0)
	elif scenario=="opposite_hold":
		_pad(JOY_BUTTON_DPAD_UP,true)
		await _frames(tree,2)
		_pad(JOY_BUTTON_DPAD_DOWN,true)
		await _frames(tree,2)
		_pad(JOY_BUTTON_DPAD_UP,false)
		await _frames(tree,2)
	elif scenario=="entry_reset":
		_vertical("dpad",-1)
		await _frames(tree,2)
		_vertical("dpad",0)
		await _frames(tree,1)
		rider.set_trick_entries_enabled(false)
		_vertical("dpad",1)
		rider.set_trick_entries_enabled(true)
		await _frames(tree,2)
	else:
		_vertical("dpad",-1)
		await _frames(tree,2)
		_vertical("dpad",0)
		await _frames(tree,16 if scenario=="expired" else 2)
		_vertical("dpad",1)
		await _frames(tree,2)
	_vertical("dpad",0)
	await _frames(tree,2)
	print("CLASSIC PAD REFUSAL scenario=",scenario," speed=",rider.speed," active=",rider.manual_active," awards=",seen)
	check.call(not rider.manual_active and _manual_count(seen)==0,
		"classic pad: %s input cannot fabricate a fresh manual" % scenario)
	rider.trick_performed.disconnect(listener)


static func _cooldown(tree: SceneTree, rider: Node3D, check: Callable) -> void:
	await _roll(tree,rider)
	var seen: Array[String] = []
	var listener: Callable = func(name: String, _points: int): seen.append(name)
	rider.trick_performed.connect(listener)
	_axis(JOY_AXIS_TRIGGER_LEFT,.9)
	await _frames(tree,2)
	_axis(JOY_AXIS_TRIGGER_LEFT,0)
	await _frames(tree,2)
	var prior: bool = not rider.manual_active and _manual_count(seen)==1
	_vertical("dpad",-1)
	await _frames(tree,2)
	_vertical("dpad",0)
	await _frames(tree,2)
	_vertical("dpad",1)
	await _frames(tree,2)
	_vertical("dpad",0)
	await _frames(tree,25)
	check.call(prior and not rider.manual_active and _manual_count(seen)==1,
		"classic pad: early post-exit gesture is refused and cannot revive when cooldown later expires")
	rider.trick_performed.disconnect(listener)


static func _air_manual_refusal(tree: SceneTree, rider: Node3D, check: Callable, released: bool) -> void:
	await _roll(tree,rider)
	var seen: Array[String] = []
	var listener: Callable = func(name: String, _points: int): seen.append(name)
	rider.trick_performed.connect(listener)
	await _hop(tree)
	var eligible: bool = rider.airborne and rider.velocity.y>0
	if released:
		eligible = false
		for frame: int in 60:
			await _frames(tree,1)
			if rider.airborne and rider.velocity.y<0 and rider.global_position.y>.5 and rider.global_position.y<1:
				eligible = true
				break
	var requested_at: Vector3 = rider.global_position
	var requested_velocity: Vector3 = rider.velocity
	_axis(JOY_AXIS_TRIGGER_LEFT,.9)
	await _frames(tree,1)
	if released: _axis(JOY_AXIS_TRIGGER_LEFT,0)
	for frame: int in 80:
		await _frames(tree,1)
		if rider.is_on_floor() and not rider.airborne: break
	print("CLASSIC PAD AIR released=",released," eligible=",eligible," request=",requested_at,
		" velocity=",requested_velocity," final=",rider.global_position," floor=",rider.is_on_floor()," awards=",seen)
	check.call(eligible and rider.is_on_floor() and not rider.airborne and not rider.manual_active
		and _manual_count(seen)==0 and (released or Input.is_action_pressed("manual")),
		"classic pad: %s L2 request cannot create a manual at actual landing" % [
			"released near-landing" if released else "expired early-air held"])
	_axis(JOY_AXIS_TRIGGER_LEFT,0)
	rider.trick_performed.disconnect(listener)


static func _pause(tree: SceneTree, rider: Node3D, check: Callable) -> void:
	await _roll(tree,rider)
	var seen: Array[String] = []
	var listener: Callable = func(name: String, _points: int): seen.append(name)
	rider.trick_performed.connect(listener)
	# A genuinely sampled first direction/neutral remains young in physics
	# time throughout pause. Menu Down must not finish that pre-pause request.
	_vertical("dpad",-1)
	await _frames(tree,2)
	_vertical("dpad",0)
	await _frames(tree,1)
	var eligible: bool = rider.speed>3 and rider.is_on_floor() and not rider.manual_active
	var before_pause: Vector3 = rider.global_position
	var before_velocity: Vector3 = rider.velocity
	tree.paused=true
	for frame: int in 2: await tree.process_frame
	_pad(JOY_BUTTON_DPAD_DOWN,true)
	for frame: int in 2: await tree.process_frame
	var frozen: bool = rider.global_position==before_pause and rider.velocity==before_velocity
	var menu_held: bool = Input.is_action_pressed("brake")
	# Never await physics or invoke the assertion callback while paused.
	tree.paused=false
	await _frames(tree,2)
	check.call(eligible and frozen and menu_held and rider.speed>2 and rider.is_on_floor()
		and not rider.manual_active and _manual_count(seen)==0,
		"classic pause: real tree pause discards the pending Up-neutral edge before menu Down/resume")
	_pad(JOY_BUTTON_DPAD_DOWN,false)
	await _roll(tree,rider)
	seen.clear()
	_vertical("dpad",-1)
	await _frames(tree,2)
	_vertical("dpad",0)
	await _frames(tree,2)
	_vertical("dpad",1)
	await _frames(tree,2)
	_vertical("dpad",0)
	await _frames(tree,2)
	var admitted: bool = rider.manual_active and rider.manual_id=="manual" and _manual_count(seen)==1
	var state: Dictionary = _paused_manual_state(rider)
	tree.paused=true
	await tree.process_frame
	_pad(JOY_BUTTON_DPAD_LEFT,true)
	for frame: int in 3: await tree.process_frame
	_pad(JOY_BUTTON_DPAD_LEFT,false)
	await tree.process_frame
	var unchanged: bool = _paused_manual_state(rider)==state and _manual_count(seen)==1
	tree.paused=false
	check.call(admitted and unchanged,
		"classic pause: latched manual motion, balance, identity and visible pose stay exactly frozen during menu input")
	await _frames(tree,3)
	var resumed_distance: float = rider.global_position.distance_to(state.position)
	print("CLASSIC PAD PAUSE ghost_eligible=",eligible," ghost_frozen=",frozen,
		" manual_admitted=",admitted," manual_unchanged=",unchanged,
		" resumed_distance=",resumed_distance," active=",rider.manual_active," awards=",seen)
	check.call(rider.manual_active and rider.manual_id=="manual" and rider.speed>2 and rider.is_on_floor()
		and resumed_distance>.02 and _manual_count(seen)==1,
		"classic pause: existing manual latch resumes actual travel without a new gesture or duplicate award")
	rider.trick_performed.disconnect(listener)


static func _paused_manual_state(rider: Node3D) -> Dictionary:
	var board := rider.get_node("SkaterVisual/Board") as Node3D
	var visual := rider.get_node("SkaterVisual/Rider") as Node3D
	return {"position":rider.global_position,"frame":rider.global_transform,"velocity":rider.velocity,
		"speed":float(rider.speed),"balance":float(rider.manual_balance),"id":str(rider.manual_id),
		"active":bool(rider.manual_active),"board_pose":board.transform,"rider_pose":visual.transform}


static func _face_tricks(tree: SceneTree, rider: Node3D, check: Callable) -> void:
	await _roll(tree,rider)
	var seen: Array[String] = []
	var captures: Array[String] = []
	var listener: Callable = func(name: String, _points: int): seen.append(name)
	var caught: Callable = func(id: String): captures.append(id)
	rider.trick_performed.connect(listener)
	rider.grind_captured.connect(caught)
	rider.set_grind_lines([Line.new("ControllerRail",PackedVector3Array([Vector3(0,.92,60),Vector3(0,.92,-80)]))])
	await _hop(tree)
	check.call(rider.airborne and rider.velocity.y>0 and seen.count("Ollie")==1,
		"classic pad: holding then releasing Cross produces a real supported Ollie")
	_pad(JOY_BUTTON_DPAD_RIGHT,true)
	_pad(JOY_BUTTON_X,true)
	await _frames(tree,2)
	check.call(rider.airborne and rider.active_flip_id=="heelflip" \
		and seen.count(Catalog.definition("heelflip").display_name)==1,
		"classic pad: D-pad Right plus Square selects and performs the airborne heelflip")
	_pad(JOY_BUTTON_X,false)
	_pad(JOY_BUTTON_DPAD_RIGHT,false)
	_pad(JOY_BUTTON_DPAD_UP,true)
	_pad(JOY_BUTTON_B,true)
	await _frames(tree,2)
	check.call(rider.airborne and rider.active_grab_id=="nose_grab" \
		and seen.count(Catalog.definition("nose_grab").display_name)==1,
		"classic pad: D-pad Up plus Circle selects and performs the airborne nose grab")
	_pad(JOY_BUTTON_B,false)
	_pad(JOY_BUTTON_DPAD_UP,false)
	var descending := false
	for frame: int in 60:
		await _frames(tree,1)
		if rider.airborne and rider.velocity.y<0 and rider.global_position.y>1.05 and rider.global_position.y<1.20:
			descending = true
			break
	_pad(JOY_BUTTON_Y,true)
	for frame: int in 12:
		await _frames(tree,1)
		if rider.grinding: break
	print("CLASSIC PAD FACES descending=",descending," captures=",captures," awards=",seen," at=",rider.global_position)
	check.call(descending and rider.grinding and captures==["ControllerRail"] \
		and seen.count(Catalog.definition("rail_grind").display_name)==1,
		"classic pad: Triangle reaches actual rail capture and awards exactly one grind")
	_pad(JOY_BUTTON_Y,false)
	rider.trick_performed.disconnect(listener)
	rider.grind_captured.disconnect(caught)


static func _manual_count(seen: Array[String]) -> int:
	return seen.count(Catalog.definition("manual").display_name)+seen.count(Catalog.definition("nose_manual").display_name)


static func _hop(tree: SceneTree) -> void:
	_pad(JOY_BUTTON_A,true)
	await _frames(tree,15)
	_pad(JOY_BUTTON_A,false)
	await _frames(tree,2)


static func _roll(tree: SceneTree, rider: Node3D) -> void:
	await _reset(tree,rider)
	_pad(JOY_BUTTON_DPAD_UP,true)
	await _frames(tree,45)
	_pad(JOY_BUTTON_DPAD_UP,false)
	# Separate normal acceleration from the fresh two-edge trick request.
	await _frames(tree,18)


static func _reset(tree: SceneTree, rider: Node3D) -> void:
	_release()
	await _frames(tree,1)
	rider.set_controls_enabled(true)
	rider.set_trick_entries_enabled(true)
	rider.set_grind_lines([])
	rider.reset_skater()
	await _frames(tree,24)


static func _fixture(tree: SceneTree) -> Dictionary:
	var root := Node3D.new()
	root.name="IndependentControllerFixture"
	tree.root.add_child(root)
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=Vector3(200,.4,200)
	collision.shape=shape
	floor.add_child(collision)
	floor.position.y=-.2
	root.add_child(floor)
	var rider=Skater.new()
	# Mirror Main's explicit setting even if a surrounding runner processes
	# while paused; these regressions must exercise the real pause notification.
	rider.process_mode=Node.PROCESS_MODE_PAUSABLE
	rider.spawn_position=Vector3(0,.8,30)
	root.add_child(rider)
	await _frames(tree,24)
	return {"root":root,"rider":rider}


static func _vertical(device: String, value: float) -> void:
	if device=="stick":
		_axis(JOY_AXIS_LEFT_Y,value)
	else:
		_pad(JOY_BUTTON_DPAD_UP,value<-.5)
		_pad(JOY_BUTTON_DPAD_DOWN,value>.5)


static func _horizontal(device: String, value: float) -> void:
	if device=="stick":
		_axis(JOY_AXIS_LEFT_X,value)
	else:
		_pad(JOY_BUTTON_DPAD_LEFT,value<-.5)
		_pad(JOY_BUTTON_DPAD_RIGHT,value>.5)


static func _pad(button: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device=0
	event.button_index=button
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


static func _axis(axis: int, value: float) -> void:
	Input.parse_input_event(_motion(axis,value))
	Input.flush_buffered_events()


static func _motion(axis: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device=0
	event.axis=axis
	event.axis_value=value
	return event


static func _release() -> void:
	for button: int in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_DPAD_UP,
		JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_LEFT_STICK,
		JOY_BUTTON_RIGHT_STICK,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_TOUCHPAD]:
		_pad(button,false)
	for axis: int in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y,JOY_AXIS_RIGHT_X,JOY_AXIS_RIGHT_Y,
		JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]: _axis(axis,0)
	for action: StringName in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame: int in count:
		await tree.physics_frame
		await tree.process_frame
