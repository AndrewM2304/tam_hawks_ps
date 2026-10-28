extends RefCounted
const ClydeLayout = preload("res://game/levels/clyde_layout.gd")
## Independent real-body checks for the classic control/trick pass.
## Each trial declares only its initial fixture. Controls drive all subsequent
## movement; no tick rewrites heading, position, velocity or animation timers.

const SkaterSource = preload("res://game/player/skater.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Line = preload("res://game/tricks/grind_line.gd")
const TransitionPark = preload("res://game/levels/transition_park.gd")
const FLIPS: Array[String] = ["kickflip", "heelflip", "frontside_shuvit", "pop_shuvit", "varial_flip", "hardflip"]
const GRABS: Array[String] = ["melon_grab", "indy_grab", "nose_grab", "tail_grab", "method_grab"]


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	_release()
	await _release_ollies(tree, check)
	for entry: Dictionary in [
		{"direction": Vector2.ZERO, "id": "kickflip"},
		{"direction": Vector2.RIGHT, "id": "heelflip"},
		{"direction": Vector2.UP, "id": "frontside_shuvit"},
		{"direction": Vector2.DOWN, "id": "pop_shuvit"},
		{"direction": Vector2(-1, 1), "id": "varial_flip"},
		{"direction": Vector2(1, -1), "id": "hardflip"}]:
		await _directional_flip(tree, check, entry)
	for entry: Dictionary in [
		{"direction": Vector2.LEFT, "id": "melon_grab"},
		{"direction": Vector2.RIGHT, "id": "indy_grab"},
		{"direction": Vector2.UP, "id": "nose_grab"},
		{"direction": Vector2.DOWN, "id": "tail_grab"},
		{"direction": Vector2(-1, -1), "id": "method_grab"}]:
		await _directional_grab(tree, check, entry)
	await _repeat_flip(tree, check)
	await _manual_variants(tree, check)
	for nose: bool in [false, true]:
		await _manual_gesture(tree, check, nose)
	await _manual_gesture_rejections(tree, check)
	await _air_stick(tree, check)
	await _latched_rail(tree, check)
	await _entry_gates(tree, check)
	for entry: Dictionary in [
		{"direction": Vector2.ZERO, "id": "axle_stall", "exit": "drop"},
		{"direction": Vector2.UP, "id": "nose_stall", "exit": "ollie"},
		{"direction": Vector2.DOWN, "id": "tail_stall", "exit": "overtime"},
		{"direction": Vector2.RIGHT, "id": "disaster", "exit": "drop"}]:
		await _pipe_lip(tree, check, entry)
	await _pipe_flat_rejection(tree, check)
	await _pipe_blocked_coping(tree, check)
	await _pipe_natural_vert(tree, check)
	await _halfpipe_rollback(tree, check)
	_release()


static func _release_ollies(tree: SceneTree, check: Callable) -> void:
	var short_apex := 0.0
	var charged_apex := 0.0
	for held: int in [2, 36]:
		var fixture: Dictionary = await _fixture(tree)
		var rider: Node3D = fixture.rider
		var seen: Array[String] = []
		rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
		var standing_hips: float = rider.get_node("SkaterVisual/Rider/TorsoRig").global_position.y
		_key(KEY_SPACE, true)
		await _frames(tree, held)
		check.call(rider.is_on_floor() and not rider.airborne and seen.is_empty(),
			"classic input: holding mapped Space for %d frames crouches without launching or scoring" % held)
		check.call(rider.get_node("SkaterVisual/Rider/TorsoRig").global_position.y < standing_hips - 0.015,
			"classic input: held ollie visibly lowers the rider before release (%df)" % held)
		_key(KEY_SPACE, false)
		await _frames(tree, 2)
		# Preserve the release/one-entry contract at the slower flat-pop speeds;
		# exact height, flight duration and gravity have their own native checks.
		check.call(rider.airborne and rider._weighted_ollie_air and rider.velocity.y > (6.5 if held > 2 else 5.0) \
			and rider.velocity.y < (7.7 if held > 2 else 6.2) and seen.count("Ollie") == 1,
			"classic input: releasing mapped Space pops exactly once (%df)" % held)
		var apex: float = rider.global_position.y
		for frame in 85:
			await _frames(tree, 1)
			apex = maxf(apex, rider.global_position.y)
		check.call(rider.is_on_floor() and seen.count("Ollie") == 1,
			"classic input: one held/released request lands without automatic hopping (%df)" % held)
		if held == 2: short_apex = apex
		else: charged_apex = apex
		await _dispose(tree, fixture)
	check.call(charged_apex > short_apex + 0.25,
		"classic input: a deliberate crouch charges a measurably higher real ollie")
	print("CLASSIC OLLIE short_apex=%.3f charged_apex=%.3f" % [short_apex, charged_apex])


static func _directional_flip(tree: SceneTree, check: Callable, entry: Dictionary) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	Input.action_press("ollie")
	await _frames(tree, 3)
	_direction(entry.direction)
	_key(KEY_J, true)
	await _frames(tree, 1)
	# The family-button press snapshots the direction; changing it before pop
	# must not turn a selected kickflip into another trick or a repeated award.
	_direction(-entry.direction)
	Input.action_release("ollie")
	await _frames(tree, 2)
	var name: String = Catalog.definition(entry.id).display_name
	check.call(rider.airborne and rider.active_flip_id == entry.id and seen.count(name) == 1,
		"classic flip: mapped J snapshots %s across a direction change before release" % entry.id)
	_direction(Vector2.ZERO)
	await _frames(tree, 55)
	check.call(_family_count(seen, FLIPS) == 1 and rider.is_on_floor(),
		"classic flip: held %s finishes with one family award and a real landing" % entry.id)
	await _dispose(tree, fixture)


static func _directional_grab(tree: SceneTree, check: Callable, entry: Dictionary) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	Input.action_press("ollie")
	await _frames(tree, 3)
	Input.action_release("ollie")
	await _frames(tree, 3)
	_direction(entry.direction)
	_key(KEY_K, true)
	await _frames(tree, 3)
	var name: String = Catalog.definition(entry.id).display_name
	check.call(rider.active_grab_id == entry.id and seen.count(name) == 1,
		"classic grab: direction plus mapped K selects %s in real airtime" % entry.id)
	_direction(-entry.direction)
	await _frames(tree, 9)
	check.call(rider.active_grab_id == entry.id and _family_count(seen, GRABS) == 1,
		"classic grab: held %s stays selected while the stick changes direction" % entry.id)
	_direction(Vector2.ZERO)
	_key(KEY_K, false)
	await _frames(tree, 4)
	check.call(rider._grab_remaining <= 0.0 and _family_count(seen, GRABS) == 1,
		"classic grab: release ends %s without a second award" % entry.id)
	await _dispose(tree, fixture)


static func _repeat_flip(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	Input.action_press("ollie")
	await _frames(tree, 36)
	Input.action_release("ollie")
	await _frames(tree, 1)
	Input.action_press("flip")
	await _frames(tree, 1)
	Input.action_release("flip")
	await _frames(tree, 1)
	Input.action_press("flip")
	await _frames(tree, 2)
	check.call(seen.count("Kickflip") == 1,
		"classic flip: a fresh press during the unfinished clip cannot overlap or score twice")
	Input.action_release("flip")
	# That double tap legitimately upgrades the existing flip. A flat ollie
	# cannot fit an upgraded double plus another flip. Test fresh sequencing in
	# a separate real single-flip flight, without changing production pop.
	await _dispose(tree,fixture)
	fixture = await _fixture(tree)
	rider = fixture.rider
	seen.clear()
	rider.trick_performed.connect(func(name: String, _points: int):seen.append(name))
	Input.action_press("ollie")
	await _frames(tree,36)
	Input.action_release("ollie")
	await _frames(tree,1)
	Input.action_press("flip")
	await _frames(tree,1)
	Input.action_release("flip")
	# Wait for both the actual single clip and physical catch phase.
	for frame in 30:
		if rider._flip_remaining <= 0.0 and rider._flip_catch_remaining <= 0.0: break
		await _frames(tree, 1)
	Input.action_press("steer_right")
	Input.action_press("flip")
	await _frames(tree, 2)
	check.call(rider.airborne and rider.active_flip_id == "heelflip" and seen.count("Heelflip") == 1
		and seen.count("Kickflip") == 1,
		"classic flip: a fresh directional press after clip completion starts a second distinct flip")
	await _dispose(tree, fixture)


static func _manual_variants(tree: SceneTree, check: Callable) -> void:
	var pitches: Array[float] = []
	for nose: bool in [false, true]:
		var fixture: Dictionary = await _fixture(tree)
		var rider: Node3D = fixture.rider
		var seen: Array[String] = []
		rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
		Input.action_press("push")
		await _frames(tree, 45)
		Input.action_release("push")
		if nose: Input.action_press("push")
		_key(KEY_M, true)
		await _frames(tree, 3)
		Input.action_release("push")
		var id := "nose_manual" if nose else "manual"
		var name: String = Catalog.definition(id).display_name
		check.call(rider.manual_active and rider.manual_id == id and seen.count(name) == 1,
			"classic manual: mapped M selects %s at eligible real ground speed" % id)
		Input.action_press("steer_right" if nose else "steer_left")
		await _frames(tree, 9)
		check.call(rider.manual_active and rider.manual_id == id and seen.count(name) == 1,
			"classic manual: %s balance correction cannot relabel or duplicate the trick" % id)
		pitches.append(rider.get_node("SkaterVisual/Board").rotation.x)
		_key(KEY_M, false)
		await _frames(tree, 2)
		check.call(not rider.manual_active, "classic manual: releasing M ends %s" % id)
		await _dispose(tree, fixture)
	check.call(pitches[0] > 0.10 and pitches[1] < -0.10,
		"classic manual: tail and nose variants tilt the visible board in opposite directions")


static func _manual_gesture(tree: SceneTree, check: Callable, nose: bool) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	Input.action_press("push")
	await _frames(tree, 45)
	Input.action_release("push")
	await _frames(tree, 18)
	var first := 1.0 if nose else -1.0
	_stick_y(first)
	await _frames(tree, 3)
	_stick_y(0.0)
	await _frames(tree, 2)
	_stick_y(-first)
	await _frames(tree, 3)
	var id := "nose_manual" if nose else "manual"
	var name: String = Catalog.definition(id).display_name
	check.call(rider.manual_active and rider.manual_id == id and seen.count(name) == 1,
		"classic gesture: mapped Left-Y %s-neutral-%s admits %s once within 220ms" % [
			"Down" if nose else "Up", "Up" if nose else "Down", id])
	_stick_y(0.0)
	await _frames(tree, 8)
	check.call(rider.manual_active and rider.manual_id == id and seen.count(name) == 1,
		"classic gesture: releasing the completed %s gesture keeps its existing balance link latched" % id)
	rider.set_trick_entries_enabled(false)
	await _frames(tree, 8)
	check.call(rider.manual_active and rider.manual_id == id and seen.count(name) == 1,
		"classic gesture: entry-disabled overtime preserves the existing latched %s" % id)
	_stick_y(first)
	await _frames(tree, 2)
	_stick_y(0.0)
	await _frames(tree, 2)
	_stick_y(-first)
	await _frames(tree, 2)
	_stick_y(0.0)
	await _frames(tree, 2)
	check.call(rider.manual_active and _family_count(seen, ["manual", "nose_manual"]) == 1,
		"classic gesture: another stick gesture during overtime cannot create or relabel a manual award")
	_key(KEY_M, true)
	await _frames(tree, 2)
	check.call(not rider.manual_active and _family_count(seen, ["manual", "nose_manual"]) == 1,
		"classic gesture: a fresh mapped M press can drop an existing gesture manual during overtime")
	_key(KEY_M, false)
	await _frames(tree, 25)
	_stick_y(first)
	await _frames(tree, 2)
	_stick_y(0.0)
	await _frames(tree, 2)
	_stick_y(-first)
	await _frames(tree, 3)
	check.call(not rider.manual_active and _family_count(seen, ["manual", "nose_manual"]) == 1,
		"classic gesture: overtime rejects a new gesture entry after the previous manual has ended")
	await _dispose(tree, fixture)


static func _manual_gesture_rejections(tree: SceneTree, check: Callable) -> void:
	for neutral: int in [0, 16]:
		var fixture: Dictionary = await _fixture(tree)
		var rider: Node3D = fixture.rider
		var seen: Array[String] = []
		rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
		Input.action_press("push")
		await _frames(tree, 45)
		Input.action_release("push")
		await _frames(tree, 18)
		_stick_y(-1.0)
		await _frames(tree, 2)
		if neutral > 0:
			_stick_y(0.0)
			await _frames(tree, neutral)
		_stick_y(1.0)
		await _frames(tree, 3)
		check.call(not rider.manual_active and _family_count(seen, ["manual", "nose_manual"]) == 0,
			"classic gesture: %s cannot turn ordinary braking into an automatic manual" % [
				"a direct push-to-brake reversal with no sampled neutral" if neutral == 0
				else "an expired >220ms stick sequence"])
		await _dispose(tree, fixture)


static func _air_stick(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	Input.action_press("push")
	await _frames(tree, 60)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(tree, 4)
	Input.action_release("ollie")
	await _frames(tree, 3)
	var heading: float = rider.rotation.y
	var velocity: Vector2 = Vector2(rider.velocity.x, rider.velocity.z)
	var visual_angle: float = rider.get_node("SkaterVisual").rotation.y
	Input.action_press("steer_right", 0.65)
	await _frames(tree, 12)
	var actual: Vector2 = Vector2(rider.velocity.x, rider.velocity.z)
	check.call(rider.airborne and absf(angle_difference(heading, rider.rotation.y)) < 0.005
		and actual.distance_to(velocity) < 0.03,
		"classic air: partial stick spin preserves physical flight heading and horizontal momentum")
	check.call(absf(angle_difference(visual_angle, rider.get_node("SkaterVisual").rotation.y)) > 0.3,
		"classic air: the same partial stick visibly spins rider and deck")
	await _dispose(tree, fixture)


static func _latched_rail(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	# A finite solid bar leaves the Push/crouch approach clear. Its endpoint
	# enters reach after the one-tick Triangle request has been released.
	var line = Line.new("ClassicTapRail", PackedVector3Array([
		Vector3(0, 0.92, -2), Vector3(0, 0.92, -30)]))
	line.configure_contact(0.0,0.0,"classic_tap.native_box_top")
	var bar := StaticBody3D.new()
	bar.collision_layer = 1|2
	bar.collision_mask = 0
	bar.position = Vector3(0,0.85,-16)
	bar.set_meta("authored_grind_ids",[line.id])
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.14,0.14,28)
	collision.shape = shape
	bar.add_child(collision)
	fixture.root.add_child(bar)
	rider.set_grind_lines([line])
	var captures: Array[String] = []
	var capture_ticks: Array[int] = []
	var capture_buttons: Array[bool] = []
	var capture_support: Array[bool] = []
	var capture_board_support: Array[bool] = []
	var capture_body_gaps: Array[float] = []
	var seen: Array[String] = []
	rider.grind_captured.connect(func(id: String):
		captures.append(id)
		capture_ticks.append(Engine.get_physics_frames())
		capture_buttons.append(Input.is_action_pressed("grind"))
		var near: Dictionary = line.closest(rider.global_position)
		var crown: Vector3 = line.contact_at(float(near.dist))
		var hit := rider.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(crown+Vector3.UP*0.1,crown-Vector3.UP*0.1,1))
		var body_shape: CollisionShape3D = rider.get_node("BodyCollision")
		var capsule := body_shape.shape as CapsuleShape3D
		var bottom: float = body_shape.global_position.y-capsule.height*0.5
		capture_body_gaps.append(bottom-crown.y)
		capture_support.append(not hit.is_empty() and hit.collider == bar
			and Vector3(hit.normal).y > 0.99 and absf(Vector3(hit.position).y-crown.y)<0.001
			and rider.safe_margin > 0.0 and absf(bottom-crown.y-rider.safe_margin)<0.001)
		var pose = rider._grind_contact
		var board_supported: bool = rider.grind_style_id == "grind_50_50" and pose.valid and pose.anchor_count == 2
		for index in pose.anchor_count:
			var support: Vector3 = pose.supports[index]
			var truck_hit := rider.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(support+Vector3.UP*0.1,support-Vector3.UP*0.1,1))
			board_supported = board_supported and not truck_hit.is_empty() and truck_hit.collider == bar \
				and Vector3(truck_hit.normal).y > 0.99 and absf(Vector3(truck_hit.position).y-support.y)<0.001 \
				and (pose.board_transform*pose.anchors[index]).distance_to(support)<0.001
		capture_board_support.append(board_supported))
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	Input.action_press("push")
	await _frames(tree, 60)
	Input.action_release("push")
	Input.action_press("ollie")
	# Charge this jump so a released Triangle tap can precede real admission.
	# Tap-jump height/airtime are checked separately; they are no longer tied to
	# the old 34-frame airborne schedule here.
	await _frames(tree, 24)
	Input.action_release("ollie")
	# Rising catches are allowed. Request while the finite endpoint is still
	# outside the point envelope, then witness its released buffered catch.
	var admission_window := false
	for frame in 90:
		await _frames(tree, 1)
		if rider.airborne and rider.velocity.y > 2.0 and rider.velocity.y < 3.5 \
				and rider.global_position.y > 1.10:
			admission_window = true
			break
	var request_tick := Engine.get_physics_frames()
	var request_position: Vector3 = rider.global_position
	var request_velocity: Vector3 = rider.velocity
	var outside_reach: bool = request_position.distance_to(line.point_at(0.0)) > 0.85
	_pad(JOY_BUTTON_Y, true)
	await _frames(tree, 1)
	var released_tick := Engine.get_physics_frames()
	var uncaptured_while_pressed: bool = not rider.grinding and captures.is_empty()
	_pad(JOY_BUTTON_Y, false)
	await _frames(tree, 7)
	var released_catch := capture_ticks.size() == 1 and capture_buttons.size() == 1 \
		and not capture_buttons[0] and capture_ticks[0] > released_tick \
		and float(capture_ticks[0] - request_tick) / Engine.physics_ticks_per_second <= 0.18
	check.call(admission_window and outside_reach and released_tick - request_tick == 1 and uncaptured_while_pressed
		and released_catch and capture_support == [true] and capture_board_support == [true]
		and rider.grinding and captures == ["ClassicTapRail"]
		and seen.size() == 2 and seen.count("Ollie") == 1 \
		and _family_count(seen,["rail_grind","grind_50_50"]) == 1,
		"classic rail: a released one-tick mapped Triangle tap buffers one native solid-endpoint catch within180ms")
	print("CLASSIC RAIL request_tick=", request_tick, " release_tick=", released_tick,
		" capture_ticks=", capture_ticks, " request_at=", request_position, " request_velocity=", request_velocity,
		" uncaptured_while_pressed=", uncaptured_while_pressed, " buttons_at_capture=", capture_buttons,
		" native_support=", capture_support, " native_board_support=", capture_board_support,
		" body_crown_gaps=", capture_body_gaps, " safe_margin=", rider.safe_margin)
	await _frames(tree, 5)
	check.call(rider.grinding and captures.size() == 1,
		"classic rail: a released capture button neither drops nor repeatedly awards the locked rail")
	_pad(JOY_BUTTON_Y, true)
	await _frames(tree, 2)
	check.call(not rider.grinding and rider.airborne and captures.size() == 1,
		"classic rail: a second fresh mapped Triangle press drops without an immediate recapture")
	await _dispose(tree, fixture)


static func _entry_gates(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _fixture(tree)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	Input.action_press("ollie")
	await _frames(tree, 12)
	rider.set_controls_enabled(false)
	Input.action_release("ollie")
	rider.set_controls_enabled(true)
	await _frames(tree, 3)
	check.call(not rider.airborne and seen.is_empty(),
		"classic gates: disabling controls clears a crouch so its stale release cannot pop")
	Input.action_press("ollie")
	await _frames(tree, 4)
	Input.action_release("ollie")
	await _frames(tree, 3)
	rider.set_trick_entries_enabled(false)
	Input.action_press("flip")
	Input.action_press("grab")
	await _frames(tree, 4)
	check.call(rider.airborne and _family_count(seen, FLIPS) == 0 and _family_count(seen, GRABS) == 0,
		"classic gates: overtime allows existing airtime but rejects new flip and grab entries")
	rider.reset_skater()
	await _frames(tree, 2)
	check.call(rider._flip_remaining <= 0.0 and rider._grab_remaining <= 0.0
		and not rider.manual_active and not rider.lip_active and rider.lip_id.is_empty(),
		"classic gates: reset clears every selected/active trick family")
	await _dispose(tree, fixture)


static func _pipe_lip(tree: SceneTree, check: Callable, entry: Dictionary) -> void:
	var fixture: Dictionary = await _pipe_fixture(tree)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	var bails := [0]
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	rider.bailed.connect(func(): bails[0] += 1)
	Input.action_press("push")
	var reached := false
	var max_normal_pitch := 0.0
	for frame in 180:
		await _frames(tree, 1)
		if rider.transition_active:
			max_normal_pitch = maxf(max_normal_pitch, acos(clampf(rider.transition_normal.y, -1, 1)))
			if rider._transition.theta >= deg_to_rad(72.0):
				reached = true
				break
	check.call(reached and max_normal_pitch >= deg_to_rad(70.0) and rider.global_position.y > 4.0,
		"classic pipe: ordinary Push reaches the finite curved quarter above 70 degrees before %s" % entry.id)
	_direction(entry.direction)
	_pad(JOY_BUTTON_Y, true)
	for frame in 10:
		await _frames(tree, 1)
		if rider.lip_active: break
	var name: String = Catalog.definition(entry.id).display_name
	if not rider.lip_active:
		print("CLASSIC LIP REJECT ", entry.id, " theta=", rad_to_deg(rider._transition.theta), " active=", rider.transition_active, " held=", Input.is_action_pressed("grind"), " buf=", rider._grind_buffer_remaining, " controls=", rider._controls_enabled, " entries=", rider._trick_entries_enabled, " pos=", rider.global_position, " velocity=", rider.velocity, " seen=", seen)
	check.call(rider.lip_active and rider.lip_id == entry.id and seen.count(name) == 1,
		"classic lip: a fresh mapped Triangle plus direction admits %s at actual coping" % entry.id)
	_direction(Vector2.ZERO)
	await _frames(tree, 10)
	check.call(rider.lip_active and seen.count(name) == 1 and rider.velocity.is_zero_approx()
		and rider.global_transform.is_finite(),
		"classic lip: held %s balances finitely and awards only its single admitted entry" % entry.id)
	if entry.exit == "ollie":
		Input.action_press("ollie")
		await _frames(tree, 6)
		check.call(rider.lip_active and seen.count("Ollie") == 0,
			"classic lip: holding Ollie crouches in the stall until release")
		Input.action_release("ollie")
		await _frames(tree, 2)
		print("CLASSIC LIP POP air=", rider.airborne, " lip=", rider.lip_active, " velocity=", rider.velocity, " seen=", seen)
		check.call(not rider.lip_active and rider.airborne and rider.velocity.y > 6.0 and seen.count("Ollie") == 1,
			"classic lip: release-pop exits the real coping once into upward airtime")
	elif entry.exit == "overtime":
		rider.set_trick_entries_enabled(false)
		Input.action_press("flip")
		Input.action_press("grab")
		Input.action_press("ollie")
		await _frames(tree, 3)
		Input.action_release("ollie")
		await _frames(tree, 2)
		check.call(rider.lip_active and _family_count(seen, FLIPS) == 0 and _family_count(seen, GRABS) == 0
			and seen.count("Ollie") == 0,
			"classic lip: overtime preserves an existing stall but rejects new tricks and pop")
		_pad(JOY_BUTTON_Y, false)
		await _frames(tree, 3)
		check.call(not rider.lip_active and seen.count(name) == 1,
			"classic lip: existing overtime stall still permits an ordinary release/drop")
	else:
		_pad(JOY_BUTTON_Y, false)
		await _frames(tree, 3)
		check.call(not rider.lip_active and seen.count(name) == 1 and rider.velocity.z > 0.0,
			"classic lip: releasing Triangle drops %s inward toward its own ramp" % entry.id)
	_release()
	await _frames(tree, 150)
	check.call(bails[0] == 0 and rider.global_position.y >= 1.95 and rider.global_transform.is_finite(),
		"classic lip: %s exits and returns to supported current fixture without falling through" % entry.id)
	print("CLASSIC PIPE ", entry.id, " max_pitch=", rad_to_deg(max_normal_pitch),
		" position=", rider.global_position, " bails=", bails[0])
	await _dispose(tree, fixture)


static func _pipe_flat_rejection(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _pipe_fixture(tree)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	_pad(JOY_BUTTON_Y, true)
	await _frames(tree, 12)
	check.call(not rider.lip_active and seen.is_empty(),
		"classic lip: Triangle on ordinary flat approach cannot create a stall")
	_pad(JOY_BUTTON_Y, false)
	Input.action_press("push")
	await _frames(tree, 140)
	check.call(not rider.lip_active and not seen.has("Axle Stall"),
		"classic lip: a released expired Triangle from flat ground cannot acquire a later coping")
	await _dispose(tree, fixture)


static func _pipe_blocked_coping(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _pipe_fixture(tree, true)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	Input.action_press("push")
	_pad(JOY_BUTTON_Y, true)
	var entered := false
	var warped := false
	for frame in 180:
		await _frames(tree, 1)
		entered = entered or rider.lip_active
		warped = warped or rider.global_position.y > 6.5 or rider.global_position.z < 60.5
	check.call(not entered and not seen.has("Axle Stall"),
		"classic lip: a real solid obstruction at the coping rejects an otherwise held approach")
	check.call(not warped and rider.global_transform.is_finite(),
		"classic pipe: blocked coping contact never restores an analytic target through the obstacle")
	Input.action_release("push")
	await _frames(tree, 1)
	var collision_speed: float = rider.velocity.length()
	fixture.root.get_node("ActualCopingObstruction").queue_free()
	await tree.process_frame
	await _frames(tree, 2)
	check.call(rider.velocity.length() <= collision_speed + 1.0 and rider.global_transform.is_finite(),
		"classic pipe: removing a real obstruction cannot resurrect momentum already removed by its collision")
	await _dispose(tree, fixture)


static func _pipe_natural_vert(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _pipe_fixture(tree)
	var rider: Node3D = fixture.rider
	var seen: Array[String] = []
	rider.trick_performed.connect(func(name: String, _points: int): seen.append(name))
	Input.action_press("push")
	var entered := false
	var released := false
	for frame in 180:
		await _frames(tree, 1)
		if rider.transition_active:
			entered = true
			if rider._transition.theta > deg_to_rad(72.0): Input.action_release("push")
		elif entered and rider.airborne:
			released = true
			break
	var launch_velocity: Vector3 = rider.velocity
	var launch_tick := Engine.get_physics_frames()
	check.call(released and rider.global_position.y > 5.0 and launch_velocity.y > 4.0 and not seen.has("Ollie"),
		"classic vert: ordinary roll-up naturally releases upward from the actual quarter without a jump input")
	await _frames(tree, 2)
	var elapsed_ticks := Engine.get_physics_frames() - launch_tick
	var expected_up := launch_velocity.y - 22.0 * float(elapsed_ticks) / Engine.physics_ticks_per_second
	check.call(elapsed_ticks == 2 and rider.airborne and not rider.transition_active
		and rider._ramp_air and absf(rider.velocity.y - expected_up) < 0.05
		and Vector2(rider.velocity.x, rider.velocity.z).distance_to(Vector2(launch_velocity.x, launch_velocity.z)) < 0.05,
		"classic vert: exactly two real air ticks preserve XZ momentum and apply the owner-requested22m/s2 ramp gravity")
	print("CLASSIC VERT released=", released, " launch_tick=", launch_tick, " elapsed_ticks=", elapsed_ticks,
		" launch=", launch_velocity, " expected_up=", expected_up, " after=", rider.velocity)
	var takeoff_height: float = rider.global_position.y
	var apex: float = takeoff_height
	var landed := false
	for tick in 150:
		await _frames(tree, 1)
		apex = maxf(apex, rider.global_position.y)
		if not rider.airborne:
			landed = true
			break
	var rise := apex - takeoff_height
	var ballistic_rise := expected_up * expected_up / (2.0 * 22.0)
	check.call(rise > ballistic_rise * .90 and rise < ballistic_rise * 1.05
		and rise > expected_up * expected_up / (2.0 * 34.0) * 1.3,
		"classic vert: preserved ramp launch gains real height from gentler air gravity")
	check.call(landed and not rider._ramp_air,
		"classic vert: ramp-air gravity ends on real support without leaking into subsequent flat ollies")
	print("CLASSIC RAMP HEIGHT rise=", rise, " expected=", ballistic_rise, " landed=", landed)
	await _dispose(tree, fixture)


static func _halfpipe_rollback(tree: SceneTree, check: Callable) -> void:
	var fixture: Dictionary = await _pipe_fixture(tree, false, Vector3(-41.5, 2.8, 61.5), -PI * 0.5, true)
	var rider: Node3D = fixture.rider
	Input.action_press("push")
	await _frames(tree, 42)
	Input.action_release("push")
	var entered := false
	var reversed := false
	var crossed := false
	var max_height := rider.global_position.y
	for frame in 240:
		await _frames(tree, 1)
		max_height = maxf(max_height, rider.global_position.y)
		if rider.transition_active and rider._transition.feature.id == "clyde_half_east":
			entered = true
			reversed = reversed or rider._transition.along_speed < -0.5
		if entered and reversed and rider.global_position.x < -40.0:
			crossed = true
			break
	check.call(entered and reversed and max_height > 2.25,
		"classic halfpipe: a modest actual push climbs its finite east wall and naturally reverses below the coping")
	check.call(crossed and rider.global_position.y >= 1.95 and rider.velocity.x < -0.5,
		"classic halfpipe: reverse wall exit carries momentum back across the supported flat bottom")
	print("CLASSIC HALFPIPE entered=", entered, " reversed=", reversed, " crossed=", crossed,
		" maxheight=", max_height, " position=", rider.global_position, " velocity=", rider.velocity)
	await _dispose(tree, fixture)


static func _pipe_fixture(tree: SceneTree, blocked: bool = false, initial: Vector3 = Vector3(17, 2.8, 73), yaw: float = 0.0, native_half: bool = false) -> Dictionary:
	_release()
	var root := Node3D.new()
	tree.root.add_child(root)
	var floor := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 0.4, 100)
	shape.shape = box
	floor.add_child(shape)
	floor.position = Vector3(0, 1.8, 64)
	root.add_child(floor)
	# These isolated response checks keep their canonical quarter orientation.
	# The real relocated/rotated production frames have separate World tests.
	var ramp_root := Node3D.new()
	root.add_child(ramp_root)
	if not native_half:
		ramp_root.transform = Transform3D(Basis.IDENTITY,Vector3(17,2,64.5)) * Transform3D(Basis(Vector3.UP,ClydeLayout.QUARTER_YAW),ClydeLayout.QUARTER_TOE).affine_inverse()
	var features := TransitionPark.build(ramp_root, {})
	if blocked:
		var obstruction := StaticBody3D.new()
		obstruction.name = "ActualCopingObstruction"
		var solid := CollisionShape3D.new()
		var block := BoxShape3D.new()
		block.size = Vector3(6, 2, 0.4)
		solid.shape = block
		obstruction.add_child(solid)
		obstruction.position = Vector3(17, 5.8, 61.3)
		root.add_child(obstruction)
	var rider = SkaterSource.new()
	rider.spawn_position = initial
	root.add_child(rider)
	rider.set_transition_features(features)
	await _frames(tree, 45)
	rider.rotation.y = yaw
	return {"root": root, "rider": rider, "features": features}


static func _family_count(seen: Array[String], ids: Array[String]) -> int:
	var count := 0
	for id: String in ids:
		count += seen.count(Catalog.definition(id).display_name)
	return count


static func _direction(value: Vector2) -> void:
	for action: String in ["steer_left", "steer_right", "push", "brake"]:
		Input.action_release(action)
	if value.x < 0.0: Input.action_press("steer_left", absf(value.x))
	if value.x > 0.0: Input.action_press("steer_right", absf(value.x))
	if value.y < 0.0: Input.action_press("push", absf(value.y))
	if value.y > 0.0: Input.action_press("brake", absf(value.y))


static func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


static func _pad(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


static func _stick_y(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_LEFT_Y
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()


static func _fixture(tree: SceneTree) -> Dictionary:
	_release()
	var root := Node3D.new()
	tree.root.add_child(root)
	var floor := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 0.4, 100)
	shape.shape = box
	floor.add_child(shape)
	floor.position.y = -0.2
	root.add_child(floor)
	var rider = SkaterSource.new()
	rider.spawn_position = Vector3(0, 0.8, 12)
	root.add_child(rider)
	await _frames(tree, 45)
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
	for code: Key in [KEY_SPACE, KEY_J, KEY_K, KEY_M]: _key(code, false)
	_pad(JOY_BUTTON_Y, false)
	_stick_y(0.0)
