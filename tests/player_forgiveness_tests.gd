extends RefCounted
## Ordinary mapped-input margins on isolated real CharacterBody fixtures.
## Initial placement/heading is declared once; movement is never corrected.

const SkaterSource = preload("res://game/player/skater.gd")
const Line = preload("res://game/tricks/grind_line.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Profile = preload("res://game/core/input_profile.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	_release()
	await _slope_holds(tree, check)
	for lead: int in [0, 3, 6, 9]:
		await _early_tricks(tree, check, lead)
	await _early_manual(tree, check)
	await _disabled_buffer(tree, check)
	for entry: Dictionary in [
		{"offset": -0.22, "yaw": 0.0, "when": "early", "push": 45, "input": "action", "catch": true},
		{"offset": 0.22, "yaw": 0.0, "when": "descending", "push": 60, "input": "pad", "catch": true},
		{"offset": 0.0, "yaw": 2.0, "when": "descending", "push": 45, "input": "remap", "catch": true},
		{"offset": 0.0, "yaw": -2.0, "when": "descending", "push": 60, "input": "action", "catch": true},
		{"offset": 0.9, "yaw": 0.0, "when": "early", "push": 45, "input": "action", "catch": false},
		{"offset": 0.0, "yaw": 0.0, "when": "after_landing", "push": 45, "input": "action", "catch": false}]:
		await _rail_approach(tree, check, entry)
	Profile.reset_defaults()
	_release()


static func _slope_holds(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _fixture(tree, 0.0, 0.0, true)
	var rider: Node3D = fixture.rider
	rider.set_controls_enabled(false)
	var start: Vector3 = rider.global_position
	await _frames(tree, 60)
	check.call(rider.is_on_floor() and rider.global_position.distance_to(start) < 0.03 and absf(rider.speed) < 0.05,
		"human input: disabled controls keep the rider stopped on an actual 20-degree bank")
	rider.set_controls_enabled(true)
	Input.action_press("brake")
	start = rider.global_position
	await _frames(tree, 60)
	check.call(rider.is_on_floor() and rider.global_position.distance_to(start) < 0.03 and absf(rider.speed) < 0.05,
		"human input: holding the brake at rest prevents downhill creep")
	Input.action_release("brake")
	await _frames(tree, 180)
	check.call(rider.is_on_floor() and rider.speed < -2.0 and rider.global_position.z > start.z + 1.0,
		"human input: releasing the brake allows supported downhill rollback")
	Input.action_press("manual")
	await _frames(tree, 2)
	check.call(rider.manual_active and rider.speed < -2.0,
		"human input: a fresh manual can balance while rolling backwards")
	print("HUMAN SLOPE reverse_speed=%.3f distance=%.3f manual=%s" % [
		rider.speed, rider.global_position.z - start.z, rider.manual_active])
	await _dispose(tree, fixture)


static func _early_tricks(tree: SceneTree, check: Callable, lead: int) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	var observed: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): observed.append(name))
	Input.action_press("push")
	await _frames(tree, 45)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(tree, 1)
	Input.action_press("flip")
	Input.action_press("grab")
	if lead > 0: await _frames(tree, lead)
	Input.action_release("ollie")
	await _frames(tree, 65)
	var expected := 1 if lead <= 6 else 0
	check.call(observed.count("Kickflip") == expected and observed.count("Melon Grab") == expected
		and observed.count("Ollie") == 1 and rider.is_on_floor(),
		"human input: %d-frame early flip/grab request %s and held buttons cannot repeat" % [
			lead, "survives takeoff" if expected == 1 else "expires before takeoff"])
	await _dispose(tree, fixture)


static func _early_manual(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	var observed: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): observed.append(name))
	Input.action_press("push")
	await _frames(tree, 60)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(tree, 1)
	Input.action_release("ollie")
	var descending := false
	for frame in 65:
		if rider.airborne and rider.velocity.y < 0.0 and rider.global_position.y < 0.45:
			descending = true
			break
		await _frames(tree, 1)
	Input.action_press("manual")
	await _frames(tree, 8)
	check.call(descending and rider.is_on_floor() and rider.manual_active and observed.count("Manual") == 1,
		"human input: a held manual pressed just before real landing links once after contact")
	await _dispose(tree, fixture)


static func _disabled_buffer(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	var observed: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): observed.append(name))
	Input.action_press("flip")
	await _frames(tree, 1)
	Input.action_release("flip")
	rider.set_controls_enabled(false)
	rider.set_controls_enabled(true)
	Input.action_press("ollie")
	await _frames(tree, 2)
	Input.action_release("ollie")
	check.call(not observed.has("Kickflip"),
		"human input: disabled controls clear a pending pre-takeoff trick")
	await _dispose(tree, fixture)


static func _rail_approach(tree: SceneTree, check: Callable, entry: Dictionary) -> void:
	var fixture: Dictionary = await _fixture(tree, entry.offset, entry.yaw)
	var rider: Node3D = fixture.rider
	rider.set_grind_lines([Line.new("HumanMarginRail", PackedVector3Array([
		Vector3(0, 0.92, 30), Vector3(0, 0.92, -30)]))])
	var captures: Array[String] = []
	rider.grind_captured.connect(func(id: String): captures.append(id))
	if entry.input == "remap":
		var key := InputEventKey.new()
		key.physical_keycode = KEY_P
		key.pressed = true
		check.call(Profile.rebind("grind", key).ok, "human rail: alternate physical grind key is admitted")
	Input.action_press("push")
	await _frames(tree, entry.push)
	Input.action_press("ollie")
	await _frames(tree, 1)
	Input.action_release("ollie")
	Input.action_release("push")
	var requested := false
	var had_air := false
	var request_tick := -1
	for frame in 65:
		had_air = had_air or rider.airborne
		var eligible_event: bool = (entry.when == "early" or
			(entry.when == "descending" and rider.airborne and rider.velocity.y < 0.0 and rider.global_position.y > 0.78) or
			(entry.when == "after_landing" and had_air and rider.is_on_floor() and not rider.airborne))
		if not requested and eligible_event:
			_rail_input(entry.input, true)
			requested = true
			request_tick = Engine.get_physics_frames()
		await _frames(tree, 1)
	var caught: bool = captures.size() == 1
	check.call(requested and caught == entry.catch and captures.size() <= 1,
		"human rail: offset=%.2fm yaw=%.1fdeg request=%s push=%df via=%s capture=%s" % [
			entry.offset, entry.yaw, entry.when, entry.push, entry.input, caught])
	print("HUMAN_RAIL_EVENT when=",entry.when," requested=",requested," tick=",request_tick," captures=",captures.size())
	_rail_input(entry.input, false)
	Profile.reset_defaults()
	await _dispose(tree, fixture)


static func _rail_input(mode: String, pressed: bool) -> void:
	if mode == "action":
		if pressed: Input.action_press("grind")
		else: Input.action_release("grind")
	elif mode == "pad":
		var pad := InputEventJoypadButton.new()
		pad.device = 0
		pad.button_index = JOY_BUTTON_Y
		pad.pressed = pressed
		Input.parse_input_event(pad)
	else:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_P
		key.pressed = pressed
		Input.parse_input_event(key)


static func _fixture(tree: SceneTree, offset: float = 0.0, yaw: float = 0.0, bank: bool = false) -> Dictionary:
	_release()
	var root := Node3D.new()
	tree.root.add_child(root)
	var floor := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 0.4, 80)
	shape.shape = box
	floor.add_child(shape)
	floor.position.y = 6.0 if bank else -0.2
	var angle := deg_to_rad(20.0) if bank else 0.0
	floor.rotation.x = angle
	root.add_child(floor)
	var rider = SkaterSource.new()
	var start_z := -3.0 if bank else 12.0
	var ground := 6.0 + 0.2 / cos(angle) - tan(angle) * start_z if bank else 0.0
	rider.spawn_position = Vector3(offset, ground + 0.8, start_z)
	root.add_child(rider)
	await _frames(tree, 45)
	rider.rotation.y = deg_to_rad(yaw)
	return {"root": root, "rider": rider}


static func _dispose(tree: SceneTree, fixture: Dictionary) -> void:
	_release()
	fixture.root.queue_free()
	await tree.process_frame
	await _frames(tree, 1)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame


static func _release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
