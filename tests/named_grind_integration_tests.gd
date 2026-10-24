extends RefCounted
## Independent named-contact acceptance using mapped pad events and live physics.
## Only fixture construction places geometry/rider. No travel tick assigns motion,
## airborne flags, board pose, balance, contact results or scoring state.
const Profile = preload("res://game/core/input_profile.gd")
const Skater = preload("res://game/player/skater.gd")
const Line = preload("res://game/tricks/grind_line.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")


## Input admission is scheduled from native physics state, independently of the
## render/coroutine cadence. The next real rider tick consumes these mapped edges.
class RequestDriver extends Node:
	var rider: CharacterBody3D
	var side := 0
	var armed := false
	var requested := false
	var request_velocity := Vector3.ZERO
	var request_position := Vector3.ZERO
	var direction_released := false
	var verify_goal_capsule := false
	var goal_capsule_clear := false
	func _ready() -> void:
		process_physics_priority = -100
	func _physics_process(_delta: float) -> void:
		if not armed:
			return
		if not requested and rider.airborne and rider.velocity.y < 0.0 \
				and rider.global_position.y > 1.05 and rider.global_position.y < 1.20:
			requested = true
			request_velocity = rider.velocity
			request_position = rider.global_position
			if verify_goal_capsule:
				var collider: CollisionShape3D = rider.get_node("BodyCollision")
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = collider.shape
				query.transform = collider.global_transform
				query.transform.origin += Vector3(0, .92, request_position.z) - rider.global_position
				query.margin = rider.safe_margin
				query.collision_mask = 1
				query.exclude = [rider.get_rid()]
				goal_capsule_clear = rider.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
			if side != 0:
				button(JOY_BUTTON_DPAD_RIGHT if side > 0 else JOY_BUTTON_DPAD_LEFT, true)
			button(JOY_BUTTON_Y, true)
		elif requested and rider.grinding and not direction_released:
			direction_released = true
			if side != 0:
				button(JOY_BUTTON_DPAD_RIGHT if side > 0 else JOY_BUTTON_DPAD_LEFT, false)
	static func button(index: int, pressed: bool) -> void:
		var event := InputEventJoypadButton.new()
		event.device = 0
		event.button_index = index
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()


## Every motion/contact observation comes from one post-rider native tick.
class Sampler extends Node:
	var rider: CharacterBody3D
	var rail_origin := Vector3.ZERO
	var rail_forward := Vector3.FORWARD
	var rail_up := Vector3.UP
	var ticks := 0
	var supported_ticks := 0
	var airborne_ticks := 0
	var grind_ticks := 0
	var styles: Array[String] = []
	var finite := true
	var max_pose_position_error := 0.0
	var max_pose_axis_error := 0.0
	var max_actual_contact_error := 0.0
	var max_rail_plane_error := 0.0
	var max_rail_side_error := 0.0
	var max_foot_deck_error := 0.0
	var min_root_travel_alignment := 1.0
	var max_board_travel_alignment := 0.0
	var min_board_travel_alignment := 1.0
	var min_camera_rear_alignment := 1.0
	var min_anchor_count := 99
	var max_anchor_count := 0
	var last_grind_velocity := Vector3.ZERO
	var last_grind_board_forward := Vector3.FORWARD
	var last_grind_board_origin := Vector3.ZERO
	var last_grind_root_origin := Vector3.ZERO
	var first_exit: Dictionary = {}
	var airborne_after_grind := 0
	var min_exit_heading_alignment := 1.0
	var max_air_spin := 0.0
	var previous_grinding := false
	func _ready() -> void:
		process_physics_priority = 100
	func _physics_process(_delta: float) -> void:
		ticks += 1
		finite = finite and rider.global_transform.is_finite() and rider.velocity.is_finite()
		if rider.is_on_floor(): supported_ticks += 1
		if rider.airborne: airborne_ticks += 1
		var board: Node3D = rider.get_node("SkaterVisual/Board")
		if rider.grinding:
			grind_ticks += 1
			var style: String = rider.grind_style_id
			if not styles.has(style): styles.append(style)
			var forward := _flat(-board.global_basis.z)
			var travel := _flat(rider.velocity)
			var alignment := absf(forward.dot(travel))
			max_board_travel_alignment = maxf(max_board_travel_alignment, alignment)
			min_board_travel_alignment = minf(min_board_travel_alignment, alignment)
			min_root_travel_alignment = minf(min_root_travel_alignment, _flat(-rider.global_basis.z).dot(travel))
			if grind_ticks > 5:
				var camera: Camera3D = rider.get_node("ChaseCamera")
				min_camera_rear_alignment = minf(min_camera_rear_alignment, _flat(camera.global_position - rider.global_position).dot(-travel))
			var contact: RefCounted = rider._grind_contact
			if style != "rail_grind":
				finite = finite and contact.valid and board.global_transform.is_finite()
				min_anchor_count = mini(min_anchor_count, contact.anchor_count)
				max_anchor_count = maxi(max_anchor_count, contact.anchor_count)
				max_pose_position_error = maxf(max_pose_position_error, board.global_position.distance_to(contact.board_transform.origin))
				for axis: int in 3:
					max_pose_axis_error = maxf(max_pose_axis_error, board.global_basis[axis].distance_to(contact.board_transform.basis[axis]))
				for index: int in contact.anchor_count:
					var actual: Vector3 = board.global_transform * contact.anchors[index]
					max_actual_contact_error = maxf(max_actual_contact_error, actual.distance_to(contact.supports[index]))
					# The authored long box's top is this independent analytic plane;
					# do not use the solver's residual as evidence of visible contact.
					max_rail_plane_error = maxf(max_rail_plane_error, absf((actual - rail_origin).dot(rail_up)))
					max_rail_side_error = maxf(max_rail_side_error, absf(actual.x))
				for leg: Dictionary in rider._visual_rig._legs:
					var actual_foot := board.to_local(leg.foot.global_position)
					# Current original GLB stance sits inside the kicks,35mm inboard
					# of the previous procedural board's axle-centred foot targets.
					var expected := Vector3(-.015 if leg.side < 0.0 else .015, .0784, float(leg.side) * .220)
					max_foot_deck_error = maxf(max_foot_deck_error, actual_foot.distance_to(expected))
			last_grind_velocity = rider.velocity
			last_grind_board_forward = forward
			last_grind_board_origin = board.global_position
			last_grind_root_origin = rider.global_position
		elif previous_grinding:
			first_exit = {"velocity": rider.velocity, "airborne": rider.airborne,
				"position": rider.global_position, "board_forward": _flat(-board.global_basis.z),
				"bailing": rider.bailing, "board_relative_step":
				((board.global_position - last_grind_board_origin) - (rider.global_position - last_grind_root_origin)).length()}
		if not first_exit.is_empty() and rider.airborne and not rider.bailing:
			airborne_after_grind += 1
			min_exit_heading_alignment = minf(min_exit_heading_alignment, _flat(-board.global_basis.z).dot(last_grind_board_forward))
			max_air_spin = maxf(max_air_spin, absf(float(rider._air_spin)))
		previous_grinding = rider.grinding
	static func _flat(value: Vector3) -> Vector3:
		return Vector3(value.x, 0.0, value.z).normalized()


## Direct clearance units deliberately supply query transforms, not player input.
## This exercises actual native walls during a physics callback; it never moves
## the production rider or represents the fixture as a played rail approach.
class ClearanceProbe extends Node:
	var rider: CharacterBody3D
	var cases: Array[Dictionary] = []
	var observations: Array[Dictionary] = []
	var done := false
	func _ready() -> void:
		process_physics_priority = 100
	func _physics_process(_delta: float) -> void:
		if done: return
		for item: Dictionary in cases:
			var before_size: Vector3 = rider._grind_board_box.size
			var from_clear: bool = rider._grind_board_clear(item.from)
			var to_clear: bool = rider._grind_board_clear(item.to)
			var middle_clear: bool = rider._grind_board_clear(item.middle)
			var path_clear: bool = rider._grind_board_path_clear(item.from, item.to)
			var rejected_size: Vector3 = rider._grind_board_box.size
			var control_from: Transform3D = item.from
			var control_to: Transform3D = item.to
			control_from.origin += Vector3(0, 0, 5)
			control_to.origin += Vector3(0, 0, 5)
			var control_clear: bool = rider._grind_board_path_clear(control_from, control_to)
			observations.append({"id": item.id, "from_clear": from_clear, "to_clear": to_clear,
				"middle_clear": middle_clear, "path_clear": path_clear, "control_clear": control_clear,
				"restored_rejected": rejected_size == before_size,
				"restored_control": rider._grind_board_box.size == before_size})
		done = true
		set_physics_process(false)


static func run(tree: SceneTree, check: Callable) -> void:
	var saved: Dictionary = Profile._bindings.duplicate(true)
	Profile.reset_defaults()
	_release()
	await _named_contact(tree, check, 0, false, false)
	await _named_contact(tree, check, 1, false, false)
	await _named_contact(tree, check, -1, true, true)
	await _pause_and_fresh_drop(tree, check)
	await _clear_lifecycle(tree, check, "reset")
	await _clear_lifecycle(tree, check, "bail")
	await _legacy_unknown(tree, check)
	await _outside_capsule_blocker(tree, check)
	await _below_capsule_parallel_blocker(tree, check)
	await _continuous_clearance_units(tree, check)
	await _natural_endpoint(tree, check)
	_release()
	check.call(Profile.apply_saved(saved), "named grind: saved input profile is restored after mapped native trials")


static func _named_contact(tree: SceneTree, check: Callable, side: int,
		reversed_line: bool, sloped: bool) -> void:
	var f: Dictionary = await _fixture(tree, true, side, reversed_line, sloped)
	var tag := "side=%s reversed=%s slope=%s" % [side, reversed_line, sloped]
	check.call(f.rider.is_on_floor() and f.sample.supported_ticks > 10,
		"named grind: approach begins on actual supported floor " + tag)
	await _approach(tree, f)
	var style := "grind_50_50" if side == 0 else "boardslide"
	var name: String = Catalog.definition(style).get("display_name", "MISSING NAMED DEFINITION")
	check.call(f.driver.requested and f.driver.request_velocity.y < 0.0 and f.sample.airborne_ticks > 12 \
		and f.rider.grinding and f.sample.styles == [style] and f.captures == [f.line.id],
		"named grind: charged real approach captures exact style and one authored rail ID " + tag)
	check.call(f.awards.count(name) == 1 and _grind_award_count(f.awards) == 1 \
		and f.awards.count("Rail Grind") == 0,
		"named grind: named entry awards once without a legacy compatibility duplicate " + tag)
	check.call(f.sample.finite and f.sample.grind_ticks >= 10 \
		and f.sample.max_pose_position_error < .001 and f.sample.max_pose_axis_error < .001 \
		and f.sample.max_actual_contact_error < .001 and f.sample.max_rail_plane_error < .001 \
		and f.sample.max_rail_side_error < .001,
		"named grind: actual mounted board follows contact frame and native rail top " + tag)
	check.call(f.sample.min_anchor_count == (2 if side == 0 else 1) \
		and f.sample.max_anchor_count == (2 if side == 0 else 1) \
		and (f.sample.min_board_travel_alignment > .995 if side == 0 else f.sample.max_board_travel_alignment < .02),
		"named grind: truck pair is parallel or deck contact is sideways independently of travel " + tag)
	check.call(f.sample.max_foot_deck_error < .025 and f.sample.min_root_travel_alignment > .995 \
		and f.sample.min_camera_rear_alignment > .80,
		"named grind: soles stay planted while root and chase remain behind signed travel " + tag)
	var before_count: int = f.awards.size()
	await _frames(tree, 8)
	check.call(f.rider.grinding and f.awards.size() == before_count and f.captures.size() == 1,
		"named grind: continued held Triangle cannot reaward the locked ride " + tag)
	if f.rider.grinding:
		_button(JOY_BUTTON_A, true)
		await _frames(tree, 3)
		_button(JOY_BUTTON_A, false)
		await _frames(tree, 9)
		var exit: Dictionary = f.sample.first_exit
		var xz_error := INF
		if not exit.is_empty():
			xz_error = Vector2(exit.velocity.x - f.sample.last_grind_velocity.x, exit.velocity.z - f.sample.last_grind_velocity.z).length()
		check.call(not exit.is_empty() and exit.airborne and not exit.bailing and xz_error < .05 \
			and f.sample.airborne_after_grind >= 5 and f.sample.min_exit_heading_alignment > .995,
			"named grind: actual release-pop preserves signed XZ momentum and chosen board heading " + tag)
		# A flat slide previously gained .106m of visible board height in the
		# release tick. Preserved offset decay changes that first relative step
		# by about .033m; this bound rejects the old snap without moving the body.
		check.call(not exit.is_empty() and exit.board_relative_step < .04,
			"named grind: release-pop preserves board origin before bounded offset decay " + tag)
		check.call(_cleared(f.rider), "named grind: release-pop clears the reusable contact and style " + tag)
		_release()
		await _frames(tree, 75)
		check.call(f.rider.is_on_floor() and not f.rider.bailing and f.sample.max_air_spin < .001 \
			and not _has_spin_award(f.awards) and f.awards.count("Ollie") == 2,
			"named grind: sideways base heading earns no fake spin and two real pops land cleanly " + tag)
	else:
		check.call(false, "named grind: release-pop requires a still-active real contact " + tag)
	print("NAMED_GRIND ", tag, " styles=", f.sample.styles, " captures=", f.captures,
		" awards=", f.awards, " native_ticks=", f.sample.grind_ticks,
		" contact_error=", f.sample.max_actual_contact_error, " plane_error=", f.sample.max_rail_plane_error,
		" foot_error=", f.sample.max_foot_deck_error, " rear=", f.sample.min_camera_rear_alignment,
		" first_exit=", f.sample.first_exit)
	await _dispose(tree, f)


static func _pause_and_fresh_drop(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await _fixture(tree, true, 1)
	await _approach(tree, f)
	check.call(f.rider.grinding and f.rider.grind_style_id == "boardslide",
		"named grind: pause/drop fixture reaches an actual sideways locked contact")
	if f.rider.grinding:
		var transform: Transform3D = f.rider.global_transform
		var board: Transform3D = f.rider.get_node("SkaterVisual/Board").global_transform
		var velocity: Vector3 = f.rider.velocity
		var balance: float = f.rider.grind_balance
		var ticks: int = f.sample.ticks
		var count: int = f.awards.size()
		tree.paused = true
		_button(JOY_BUTTON_Y, false)
		for frame: int in 10: await tree.process_frame
		check.call(f.sample.ticks == ticks and f.rider.global_transform == transform \
			and f.rider.get_node("SkaterVisual/Board").global_transform == board \
			and f.rider.velocity == velocity and f.rider.grind_balance == balance \
			and f.rider.grind_style_id == "boardslide" and f.awards.size() == count,
			"named grind: real pause freezes motion, contact, feet and style without reaward")
		tree.paused = false
		await _frames(tree, 3)
		check.call(f.rider.grinding and f.rider.global_position.distance_to(transform.origin) > .02,
			"named grind: releasing held Triangle during pause resumes the same locked contact")
		_button(JOY_BUTTON_Y, true)
		await _frames(tree, 2)
		check.call(_cleared(f.rider) and f.rider.airborne and not f.rider.bailing \
			and f.captures.size() == 1 and f.awards.size() == count,
			"named grind: second fresh Triangle exits without a jump, recapture or extra award")
		check.call(not f.sample.first_exit.is_empty() and f.sample.first_exit.board_relative_step < .04,
			"named grind: fresh drop preserves the deck origin instead of snapping .106m upward")
	await _dispose(tree, f)


static func _clear_lifecycle(tree: SceneTree, check: Callable, action: String) -> void:
	var f: Dictionary = await _fixture(tree, true, 1)
	await _approach(tree, f)
	var captured: bool = f.rider.grinding and f.rider.grind_style_id == "boardslide"
	if action == "reset":
		# Exercise the public lifecycle API, as Main does for explicit Restart.
		f.rider.reset_skater()
		await _frames(tree, 24)
		check.call(captured and _cleared(f.rider) and f.rider.is_on_floor() and not f.rider.bailing \
			and absf(f.rider.get_node("SkaterVisual/Board").rotation.y) < .001,
			"named grind: explicit restart clears contact, sideways heading and stale held capture")
	else:
		f.rider.begin_bail("named_contact_lifecycle")
		await _frames(tree, 2)
		check.call(captured and _cleared(f.rider) and f.rider.bailing and f.bails.size() == 1 \
			and f.rider.get_node("LooseBoard").freeze == false,
			"named grind: actual bail clears contact and releases the board with exactly one failure")
	await _dispose(tree, f)


static func _legacy_unknown(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await _fixture(tree, false, 1)
	await _approach(tree, f)
	check.call(f.driver.requested and f.rider.grinding and f.sample.styles == ["rail_grind"] \
		and f.captures == [f.line.id] and f.awards.count("Rail Grind") == 1 \
		and _grind_award_count(f.awards) == 1 and not f.rider._grind_contact.valid,
		"named grind: an unverified legacy guide stays explicitly generic even after directional input")
	await _dispose(tree, f)


static func _outside_capsule_blocker(tree: SceneTree, check: Callable) -> void:
	for side: int in [0, 1]:
		var f: Dictionary = await _fixture(tree, true, side, false, false, true)
		await _approach(tree, f)
		if side == 0:
			check.call(f.rider.grinding and f.rider.grind_style_id == "grind_50_50" \
				and f.captures == [f.line.id] and f.bails.is_empty(),
				"named grind: blocker outside the native capsule leaves a parallel truck catch reachable")
		else:
			await _frames(tree, 50)
			check.call(f.driver.requested and f.sample.airborne_ticks > 12 and f.sample.grind_ticks == 0 \
				and f.captures.is_empty() and _grind_award_count(f.awards) == 0 \
				and not f.rider.grinding and f.rider.is_on_floor() and f.bails.is_empty(),
				"named grind: real wall inside sideways nose envelope refuses contact and award without generic fallback")
		print("NAMED_GRIND_BLOCKER side=", side, " captures=", f.captures, " awards=", f.awards,
			" body=", f.rider.global_position, " requests=", f.driver.requested)
		await _dispose(tree, f)


static func _below_capsule_parallel_blocker(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await _fixture(tree, true, 0, false, false, false, true)
	await _approach(tree, f)
	check.call(f.driver.requested and f.driver.goal_capsule_clear and f.sample.airborne_ticks > 12,
		"named grind: parallel blocker fixture independently clears the actual capsule at the capture target")
	check.call(f.sample.grind_ticks == 0 and f.captures.is_empty() and _grind_award_count(f.awards) == 0,
		"named grind: supported truck geometry blocked below the capsule rejects capture without generic fallback")
	print("NAMED_GRIND_PARALLEL_BLOCKER capsule_clear=", f.driver.goal_capsule_clear,
		" requested_at=", f.driver.request_position, " captures=", f.captures, " awards=", f.awards)
	await _dispose(tree, f)


static func _continuous_clearance_units(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await _fixture(tree, true, 0)
	# Translation: both mounted boxes are more than .5m from this 20mm wall,
	# while the actual midpoint box intersects it. This is a query unit only.
	_box(f.root, Vector3(10, 4, 0), Vector3(.8, .4, .02), 1)
	# Rotation: +/-45-degree endpoint noses miss the 20mm cube laterally;
	# the zero-degree midpoint nose crosses it at fixed board origin.
	_box(f.root, Vector3(-10, 4, -.40), Vector3(.02, .04, .02), 1)
	var probe := ClearanceProbe.new()
	probe.rider = f.rider
	probe.cases = [
		{"id": "thin_translation_wall", "from": Transform3D(Basis.IDENTITY, Vector3(10, 4, -1)),
			"to": Transform3D(Basis.IDENTITY, Vector3(10, 4, 1)),
			"middle": Transform3D(Basis.IDENTITY, Vector3(10, 4, 0))},
		{"id": "rotation_only_nose_arc", "from": Transform3D(Basis(Vector3.UP, -PI * .25), Vector3(-10, 4, 0)),
			"to": Transform3D(Basis(Vector3.UP, PI * .25), Vector3(-10, 4, 0)),
			"middle": Transform3D(Basis.IDENTITY, Vector3(-10, 4, 0))},
	]
	f.root.add_child(probe)
	while not probe.done: await tree.process_frame
	for observation: Dictionary in probe.observations:
		var tag: String = observation.id
		check.call(observation.from_clear and observation.to_clear,
			"named clearance unit: exact start/end boxes are genuinely clear " + tag)
		check.call(not observation.middle_clear and not observation.path_clear,
			"named clearance unit: native midpoint obstacle rejects the continuous envelope " + tag)
		check.call(observation.control_clear,
			"named clearance unit: translated unobstructed motion stays admitted " + tag)
		check.call(observation.restored_rejected and observation.restored_control,
			"named clearance unit: reusable query box size restores after rejected and clear paths " + tag)
		print("NAMED_GRIND_CLEARANCE_UNIT ", observation)
	await _dispose(tree, f)


static func _natural_endpoint(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await _fixture(tree, true, 1, false, false, false, false, true)
	await _approach(tree, f)
	var caught: bool = f.rider.grinding and f.rider.grind_style_id == "boardslide"
	var deadline: int = f.sample.ticks + 45
	while f.sample.first_exit.is_empty() and f.sample.ticks < deadline:
		await tree.process_frame
	var exit: Dictionary = f.sample.first_exit
	check.call(caught and not exit.is_empty() and exit.airborne and not exit.bailing \
		and absf(exit.position.z - 16.0) < .01 and _cleared(f.rider) \
		and f.captures == [f.line.id] and _grind_award_count(f.awards) == 1,
		"named grind: natural finite endpoint releases actual contact once at the authored end")
	var xz_error := INF
	if not exit.is_empty():
		xz_error = Vector2(exit.velocity.x - f.sample.last_grind_velocity.x,
			exit.velocity.z - f.sample.last_grind_velocity.z).length()
	check.call(not exit.is_empty() and xz_error < .05 and f.awards.count("Ollie") == 1,
		"named grind: natural endpoint preserves signed carry without inventing an Ollie")
	_release()
	await _frames(tree, 75)
	check.call(f.rider.is_on_floor() and f.bails.is_empty() and not _has_spin_award(f.awards),
		"named grind: natural endpoint lands once without fake spin or held-input recapture")
	print("NAMED_GRIND_ENDPOINT exit=", exit, " awards=", f.awards, " captures=", f.captures)
	await _dispose(tree, f)


static func _fixture(tree: SceneTree, verified: bool, side: int,
		reversed_line: bool = false, sloped: bool = false, blocked: bool = false,
		parallel_blocked: bool = false, short_endpoint: bool = false) -> Dictionary:
	_release()
	var root := Node3D.new()
	root.name = "IndependentNamedGrindFixture"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	tree.root.add_child(root)
	_box(root, Vector3(0, -.2, 0), Vector3(200, .4, 200), 1)
	var a := Vector3(0, 1.02 if sloped else .92, 60)
	var b := Vector3(0, .82 if sloped else .92, 16 if short_endpoint else -80)
	var tangent := (b - a).normalized()
	var up := Vector3.UP.slide(tangent).normalized()
	var frame := Basis(tangent.cross(up).normalized(), up, -tangent).orthonormalized()
	var rail := _box(root, (a + b) * .5 - up * .05, Vector3(.08, .10, a.distance_to(b)), 2)
	rail.basis = frame
	var line = Line.new("IndependentVerifiedRail" if verified else "IndependentLegacyRail",
		PackedVector3Array([b, a] if reversed_line else [a, b]))
	if verified:
		line.configure_contact(0.0, 0.0, "native fixture: inspected box top, 80mm wide")
	if blocked:
		# Its inner X=.32 plane clears the existing .28m capsule and parallel
		# board. A sideways .82m deck would physically cross the same wall.
		_box(root, Vector3(.36, .96, -10), Vector3(.08, .18, 140), 1)
	if parallel_blocked:
		# The board's lowest wheel/truck skin is below the capsule's curved
		# lower hemisphere at X=.116.. .134. This raised strip ends at Z20,
		# after the real ground run-up/launch; the charged jump clears its end.
		# At guideY=.92 its top=.91 intersects the parallel board's underside
		# while the actual capsule remains clear, checked by a native query.
		_box(root, Vector3(.125, .90, -30), Vector3(.018, .020, 100), 1)
	var rider = Skater.new()
	rider.process_mode = Node.PROCESS_MODE_PAUSABLE
	rider.spawn_position = Vector3(0, .8, 30)
	root.add_child(rider)
	rider.set_grind_lines([line])
	var driver := RequestDriver.new()
	driver.rider = rider
	driver.side = side
	driver.verify_goal_capsule = parallel_blocked
	root.add_child(driver)
	var sample := Sampler.new()
	sample.rider = rider
	sample.rail_origin = a
	sample.rail_forward = tangent
	sample.rail_up = up
	root.add_child(sample)
	var awards: Array[String] = []
	var captures: Array[String] = []
	var bails: Array[int] = []
	rider.trick_performed.connect(func(name: String, _points: int): awards.append(name))
	rider.grind_captured.connect(func(id: String): captures.append(id))
	rider.bailed.connect(func(): bails.append(Engine.get_physics_frames()))
	await _frames(tree, 24)
	return {"root": root, "rider": rider, "line": line, "driver": driver,
		"sample": sample, "awards": awards, "captures": captures, "bails": bails}


static func _approach(tree: SceneTree, fixture: Dictionary) -> void:
	_button(JOY_BUTTON_DPAD_UP, true)
	await _frames(tree, 45)
	_button(JOY_BUTTON_A, true)
	await _frames(tree, 24)
	_button(JOY_BUTTON_DPAD_UP, false)
	_button(JOY_BUTTON_A, false)
	fixture.driver.armed = true
	# Wait for a bounded native sample count; coroutine cadence cannot stand in
	# for actual contiguous physics observations or trigger an early fake catch.
	var deadline: int = fixture.sample.ticks + 55
	while fixture.sample.ticks < deadline and fixture.sample.grind_ticks < 12:
		await tree.process_frame


static func _box(root: Node3D, position: Vector3, size: Vector3, layer: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	body.position = position
	root.add_child(body)
	return body


static func _cleared(rider: CharacterBody3D) -> bool:
	return not rider.grinding and rider.grind_style_id == "" and not rider._grind_contact.valid


static func _grind_award_count(awards: Array[String]) -> int:
	var total := 0
	for id: String in ["rail_grind", "grind_50_50", "boardslide"]:
		var name: String = Catalog.definition(id).get("display_name", "MISSING NAMED DEFINITION")
		total += awards.count(name)
	return total


static func _has_spin_award(awards: Array[String]) -> bool:
	for name: String in awards:
		if name.begins_with("Frontside ") or name.begins_with("Backside "): return true
	return false


static func _button(index: int, pressed: bool) -> void:
	RequestDriver.button(index, pressed)


static func _release() -> void:
	for index: int in [JOY_BUTTON_A, JOY_BUTTON_Y, JOY_BUTTON_DPAD_UP,
		JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		_button(index, false)
	for action: StringName in InputMap.get_actions(): Input.action_release(action)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame: int in count:
		await tree.physics_frame
		await tree.process_frame


static func _dispose(tree: SceneTree, fixture: Dictionary) -> void:
	_release()
	fixture.root.queue_free()
	await tree.process_frame
	await _frames(tree, 1)
