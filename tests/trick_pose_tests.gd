extends RefCounted
## Native visual-rig contact checks, independent of gameplay admission/scoring.
const Visual = preload("res://game/player/skater_visual.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const ContactGeometry = preload("res://tests/full_repertoire_tests.gd")

static func run(tree: SceneTree, check: Callable) -> void:
	var fixture := Node3D.new()
	tree.root.add_child(fixture)
	var visual := Node3D.new()
	fixture.add_child(visual)
	var board := Node3D.new()
	board.position.y = 0.12
	visual.add_child(board)
	var rider := Node3D.new()
	rider.rotation.y = -PI / 2.0 + 0.28
	visual.add_child(rider)
	var rig = Visual.new()
	rig.build(board, rider, StandardMaterial3D.new())
	var neutral := {"airborne": false, "grab": false, "flip": false, "manual": false,
		"grind": false, "speed": 8.0, "push": false, "brake": false}
	_settle(rig, neutral)
	check.call(_feet_error(rig, board) < 0.001,
		"trick pose: neutral shoe contacts plant on the actual visible deck")
	var idle_head: Vector3 = rig._head.global_position
	var contacts: Array[Vector3] = []
	for id: String in ["melon_grab", "indy_grab", "nose_grab", "tail_grab", "mute_grab", "japan_grab", "method_grab", "stalefish_grab"]:
		var entry: Dictionary = Catalog.definition(id)
		check.call(not entry.is_empty(), "trick pose: authored grab exists " + id)
		if entry.is_empty():
			continue
		rig.reset()
		rider.position.y = -0.17
		rider.rotation.x = -0.30
		board.rotation = Vector3(float(entry.get("board_pitch", 0)), 0, float(entry.get("board_roll", 0)))
		var state := neutral.duplicate()
		state.merge({"airborne": true, "grab": true, "grab_id": id,
			"grab_side": entry["grab_side"], "grab_target": entry["grab_target"]}, true)
		_settle(rig, state)
		var side: float = entry["grab_side"]
		var hand: Node3D = rig._arms[0 if side < 0 else 1]["hand"]
		var palm := hand.to_global(Vector3(0, -0.075, -0.015))
		var target := board.to_global(entry["grab_target"])
		check.call(palm.distance_to(target) < 0.025,
			"trick pose: selected palm meets its authored deck contact " + id)
		check.call(_feet_error(rig, board) < 0.002,
			"trick pose: grab feet remain planted through deck pitch/roll " + id)
		check.call(_limbs_finite(rig), "trick pose: limbs stay finite during " + id)
		check.call(_arm_reach(rig, side) < 1.12,
			"trick pose: grabbing arm stays within human reach " + id)
		contacts.append(palm)
	check.call(contacts.size() >= 6 and contacts[0].distance_to(contacts[1]) > 0.15,
		"trick pose: left/right grabs use visibly different hand contacts")
	rider.position = Vector3.ZERO
	rider.rotation.x = 0
	board.rotation = Vector3.ZERO
	rig.reset()
	var flip_state := neutral.duplicate()
	flip_state.merge({"airborne": true, "flip": true, "flip_progress": 0.5, "flip_id": "kickflip"}, true)
	board.rotation.z = PI
	_settle(rig, flip_state)
	check.call(_feet_error(rig, board) > 0.15,
		"trick pose: flip separates both soles from the inverted deck")
	flip_state.flip_progress = 1.0
	board.rotation.z = 0
	_settle(rig, flip_state)
	check.call(_feet_error(rig, board) < 0.002,
		"trick pose: flip catches deck before the action finishes")
	# A shove-it reverses the physical deck. Feet keep their rider stance as
	# it catches and retains that PI rest yaw; finishing must not swap feet.
	rig.reset()
	var last_feet: Array[Vector3] = []
	var catch_displacement := 0.0
	var last_bases: Array[Basis] = []
	var catch_turn := 0.0
	for frame in 37:
		var progress := clampf(float(frame) / 24.0, 0.0, 1.0)
		var curve := smoothstep(0.04, 0.88, progress)
		board.rotation = Vector3(0, PI * curve, TAU * curve)
		flip_state.merge({"flip": progress < 1.0, "flip_id": "varial_kickflip",
			"flip_progress": progress, "deck_yaw": board.rotation.y}, true)
		rig.animate(1.0 / 60.0, flip_state)
		for index in 2:
			var foot: Node3D = rig._legs[index].foot
			if frame > 0 and progress > 0.90:
				catch_displacement = maxf(catch_displacement, foot.global_position.distance_to(last_feet[index]))
				catch_turn = maxf(catch_turn, foot.global_basis.get_rotation_quaternion().angle_to(last_bases[index].get_rotation_quaternion()))
			if frame == 0:
				last_feet.append(foot.global_position)
				last_bases.append(foot.global_basis)
			else:
				last_feet[index] = foot.global_position
				last_bases[index] = foot.global_basis
	check.call(catch_displacement < 0.07 and catch_turn < 0.35,
		"trick pose: odd-yaw flip catches without a foot teleport or orientation snap")
	check.call(_feet_error(rig, board, PI) < 0.003,
		"trick pose: feet retain rider stance on the reversed deck after a shove-it")
	# Rest-yaw compensation must also preserve later manual/grab semantics.
	# These are matching authored poses with a physical deck reversed by PI.
	var manual_state := neutral.duplicate()
	manual_state.merge({"manual": true, "manual_sign": 1.0}, true)
	rig.reset()
	board.rotation = Vector3(deg_to_rad(16), 0, 0)
	_settle(rig, manual_state)
	var manual_before: Vector3 = rig._legs[0].foot.global_position
	manual_state.merge({"deck_yaw": PI, "rest_deck_yaw": PI}, true)
	board.rotation = Vector3(-deg_to_rad(16), PI, 0)
	_settle(rig, manual_state)
	check.call(rig._legs[0].foot.global_position.distance_to(manual_before) < 0.001,
		"trick pose: manual after a shove-it keeps the same lifted axle and foot stance")
	var grab_entry := Catalog.definition("nose_grab")
	var post_shove_grab := neutral.duplicate()
	post_shove_grab.merge({"airborne": true, "grab": true, "grab_id": "nose_grab",
		"grab_side": grab_entry.grab_side, "grab_target": grab_entry.grab_target}, true)
	rider.position.y = -0.17
	rider.rotation.x = -0.30
	rig.reset()
	board.rotation = Vector3(grab_entry.board_pitch, 0, grab_entry.board_roll)
	_settle(rig, post_shove_grab)
	var grab_palm: Vector3 = rig._arms[0].hand.to_global(Vector3(0, -0.075, -0.015))
	post_shove_grab.merge({"deck_yaw": PI, "rest_deck_yaw": PI}, true)
	board.rotation = Vector3(-grab_entry.board_pitch, PI, -grab_entry.board_roll)
	_settle(rig, post_shove_grab)
	check.call(rig._arms[0].hand.to_global(Vector3(0, -0.075, -0.015)).distance_to(grab_palm) < 0.002,
		"trick pose: nose grab after a shove-it uses the same hand and travel-relative deck end")
	rider.position = Vector3.ZERO
	rider.rotation.x = 0
	rig.reset()
	last_feet.clear()
	catch_displacement = 0.0
	for frame in 37:
		var progress := clampf(float(frame) / 24.0, 0.0, 1.0)
		var curve := smoothstep(0.04, 0.88, progress)
		board.rotation = Vector3(0, PI, -TAU * curve)
		flip_state.merge({"flip": progress < 1.0, "flip_id": "kickflip", "rest_deck_yaw": PI,
			"flip_progress": progress, "deck_yaw": PI}, true)
		rig.animate(1.0 / 60.0, flip_state)
		for index in 2:
			var foot: Node3D = rig._legs[index].foot
			if frame > 0 and progress > 0.90:
				catch_displacement = maxf(catch_displacement, foot.global_position.distance_to(last_feet[index]))
			if frame == 0:
				last_feet.append(foot.global_position)
			else:
				last_feet[index] = foot.global_position
	check.call(catch_displacement < 0.07 and _feet_error(rig, board, PI) < 0.003,
		"trick pose: another flip after a shove-it catches the reversed deck without a foot swap")
	var grind_state := neutral.duplicate()
	grind_state.merge({"grind": true, "grind_id": "boardslide", "grind_yaw": PI / 2.0, "grind_balance": 0.4}, true)
	board.rotation.y = PI / 2.0
	rig.reset()
	_settle(rig, grind_state)
	check.call(_feet_error(rig, board) < 0.002 and rig._pelvis_turn > 0.6,
		"trick pose: boardslide turns hips with the deck while feet keep contact")
	check.call(absf(rig._torso_turn) < absf(rig._pelvis_turn),
		"trick pose: slide torso retains travel-facing counter rotation")
	check.call(_limbs_finite(rig), "trick pose: perpendicular slide has finite clothed limbs")
	var supports := {
		"rail_grind": [Vector3(0, -0.104, -0.255), Vector3(0, -0.104, 0.255)],
		"boardslide": [Vector3(0, -0.020, 0)], "lipslide": [Vector3(0, -0.020, 0)],
		"nosegrind": [Vector3(0, -0.104, -0.255)],
		"five_o_grind": [Vector3(0, -0.104, 0.255)],
		"crooked_grind": [Vector3(0, -0.104, -0.255)],
		"overcrook_grind": [Vector3(0, -0.104, -0.255)],
		"smith_grind": [Vector3(0, -0.104, 0.255)],
		"feeble_grind": [Vector3(0, -0.104, 0.255)],
	}
	for id: String in supports:
		var entry := Catalog.definition(id)
		board.rotation = Vector3(entry.grind_pitch, entry.grind_yaw, 0)
		grind_state.merge({"grind_id": id, "grind_yaw": entry.grind_yaw,
			"grind_pitch": entry.grind_pitch}, true)
		rig.reset()
		_settle(rig, grind_state)
		var contact_error := 0.0
		for contact: Vector3 in supports[id]:
			contact_error = maxf(contact_error, absf(board.to_global(contact).y))
		check.call(contact_error < 0.001,
			"trick pose: authored grind bearing surface touches the support line " + id)
		check.call(_feet_error(rig, board) < 0.002,
			"trick pose: shoes follow the supported deck pose " + id)
		if id != "rail_grind":
			check.call(board.to_global(supports[id][0]).length() < 0.001,
				"trick pose: weighted grind contact stays centered on the ride line " + id)
	var last_grind_deck := board.position
	var release_state := neutral.duplicate()
	release_state.airborne = true
	rig.animate(1.0 / 60.0, release_state)
	check.call(board.position.distance_to(last_grind_deck) < 0.08,
		"trick pose: grind release returns the deck smoothly underneath the rider")
	board.rotation = Vector3.ZERO
	rig.reset()
	_settle(rig, neutral)
	check.call(_feet_error(rig, board) < 0.001 and rig._head.global_position.distance_to(idle_head) < 0.02,
		"trick pose: reset restores planted feet and idle anatomy after all variants")
	check.call(board.position.distance_to(Vector3(0, 0.12, 0)) < 0.001,
		"trick pose: grind exit/reset restores ordinary wheel support height and deck centering")
	fixture.queue_free()
	await tree.process_frame

static func _settle(rig: RefCounted, state: Dictionary) -> void:
	for i in 60:
		rig.animate(1.0 / 60.0, state)

static func _feet_error(rig: RefCounted, board: Node3D, _deck_yaw: float = 0.0) -> float:
	var error := 0.0
	var tape: MeshInstance3D = board.get_node("Griptape")
	for leg: Dictionary in rig._legs:
		var sole: Vector3 = leg.foot.to_global(Vector3(0, -0.0605, 0))
		error = maxf(error, ContactGeometry._surface_distance(sole, [tape]))
	return error

static func _limbs_finite(rig: RefCounted) -> bool:
	var skeleton: Skeleton3D = rig._garments.skeleton
	for index in skeleton.get_bone_count():
		var pose := skeleton.get_bone_pose(index)
		if not pose.origin.is_finite() or not pose.basis.is_finite():
			return false
	return true

static func _arm_reach(rig: RefCounted, side: float) -> float:
	var skeleton: Skeleton3D = rig._garments.skeleton
	var prefix := "left" if side < 0 else "right"
	var arm_scale := skeleton.get_bone_pose_scale(skeleton.find_bone(prefix + "_forearm"))
	return arm_scale.y
