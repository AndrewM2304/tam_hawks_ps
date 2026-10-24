extends RefCounted
## Animation contracts: axes/endpoints and actual rig contact under authored board tilts.
const TrickMotion = preload("res://game/player/trick_animation.gd")
const Visual = preload("res://game/player/skater_visual.gd")
const BoardGeometry = preload("res://tests/board_geometry_tests_support.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")

static func run(tree: SceneTree, check: Callable) -> void:
	var kick := TrickMotion.board_angles("kickflip", 0.25)
	var heel := TrickMotion.board_angles("heelflip", 0.25)
	var shove := TrickMotion.board_angles("pop_shuvit", 0.25)
	var front := TrickMotion.board_angles("frontside_shuvit", 0.25)
	check.call(kick.z > 0.0 and heel.z < 0.0 and is_zero_approx(kick.y)
		and shove.y > 0.0 and front.y < 0.0 and is_zero_approx(shove.z),
		"trick animation: flips roll opposite ways and shuvits rotate flat in opposite directions")
	check.call(TrickMotion.board_angles("varial_flip", 0.5).z != 0.0
		and TrickMotion.board_angles("varial_flip", 0.5).y != 0.0
		and TrickMotion.board_angles("hardflip", 0.5).x > 0.8,
		"trick animation: combined flips add a shuvit and hardflip has a vertical deck accent")
	var finite_ends := true
	for id: String in ["kickflip", "heelflip", "pop_shuvit", "frontside_shuvit", "varial_flip", "hardflip"]:
		finite_ends = finite_ends and TrickMotion.board_angles(id, -1).is_zero_approx()
		for progress: float in [0.0, 0.01, 0.5, 0.99, 1.0, 2.0]:
			finite_ends = finite_ends and TrickMotion.board_angles(id, progress).is_finite()
		var finish := TrickMotion.board_angles(id, 1.0)
		finite_ends = finite_ends and absf(sin(finish.x)) < 0.001 and absf(sin(finish.y)) < 0.001 \
			and absf(sin(finish.z)) < 0.001
	check.call(finite_ends, "trick animation: all six rotations clamp safely and finish with a flat deck")

	var owner := Node3D.new()
	tree.root.add_child(owner)
	var visual := Node3D.new()
	owner.add_child(visual)
	var board := Node3D.new()
	board.position.y = 0.12
	visual.add_child(board)
	var rider := Node3D.new()
	visual.add_child(rider)
	var rig = Visual.new()
	rig.build(board, rider, StandardMaterial3D.new())
	var state := {"airborne": true, "grab": true, "flip": false, "manual": false,
		"grind": false, "push": false, "speed": 8.0}
	var grab_silhouettes: Array[Vector3] = []
	var grab_rotations: Array[Vector3] = []
	for id: String in ["melon_grab", "indy_grab", "nose_grab", "tail_grab", "method_grab"]:
		rig.reset()
		var pose := TrickMotion.grab_pose(id)
		board.rotation = Vector3(pose.pitch, 0.0, pose.roll)
		rider.position.y = -0.17
		rider.rotation.x = -0.3
		state["grab_id"] = id
		for i in 60:
			rig.animate(1.0 / 60.0, state)
		var index := 0 if pose.hand_side < 0.0 else 1
		var grabbing_hand: Node3D = rig._arms[index]["hand"]
		var palm := grabbing_hand.to_global(Vector3(0, -0.075, -0.015))
		var target := board.to_global(pose.deck_target)
		var shoulder: Vector3 = rig._upper.to_global(Vector3(pose.hand_side * 0.195, 0.425, 0))
		check.call(shoulder.distance_to(grabbing_hand.global_position) <= 0.595,
			"trick animation: %s wrist stays within the 59cm authored arm reach" % id)
		check.call(palm.distance_to(target) < 0.012,
			"trick animation: %s selected hand meets the tilted deck within 12mm" % id)
		var feet_attached := true
		for leg: Dictionary in rig._legs:
			feet_attached = feet_attached and BoardGeometry.grip_distance(rig,
				leg.foot.to_global(Footwear.SOLE_CONTACT)) < 0.001
		check.call(feet_attached, "trick animation: %s retains both shoe contacts on the tilted board" % id)
		grab_silhouettes.append(rig._upper.position)
		grab_rotations.append(rig._upper.rotation)
	check.call(grab_silhouettes[0].distance_to(grab_silhouettes[2]) > 0.09
		and grab_silhouettes[2].distance_to(grab_silhouettes[3]) > 0.18
		and grab_rotations[0].distance_to(grab_rotations[4]) > 0.15,
		"trick animation: nose, tail and method shift weight/tuck rather than changing only a label")

	rig.reset()
	rider.transform = Transform3D.IDENTITY
	board.rotation = Vector3.ZERO
	state = {"airborne": false, "grab": false, "flip": false, "manual": true,
		"grind": false, "push": false, "speed": 8.0, "manual_id": "manual"}
	for i in 60:
		rig.animate(1.0 / 60.0, state)
	var rear_weight: Vector3 = rig._upper.position
	state["manual_id"] = "nose_manual"
	for i in 60:
		rig.animate(1.0 / 60.0, state)
	check.call(rig._upper.position.z < rear_weight.z - 0.14,
		"trick animation: nose manual moves visible body weight toward the front truck")
	state["manual"] = false
	var lip_weights: Array[Vector3] = []
	for id: String in ["axle_stall", "nose_stall", "tail_stall", "disaster"]:
		rig.reset()
		state["lip_id"] = id
		state["lip_progress"] = 0.5
		for i in 60:
			rig.animate(1.0 / 60.0, state)
		lip_weights.append(rig._upper.position)
		var finite := true
		for arm: Dictionary in rig._arms:
			finite = finite and arm.hand.transform.is_finite()
		check.call(finite and rig._upper.position.y < 0.90,
			"trick animation: %s holds a finite crouched balance pose" % id)
	check.call(lip_weights[1].z < lip_weights[0].z - 0.09
		and lip_weights[2].z > lip_weights[0].z + 0.09
		and lip_weights[3].y < lip_weights[0].y - 0.07,
		"trick animation: lip variants visibly weight opposite ends or compress for disaster")
	state["lip_id"] = ""
	state["crouch"] = 0.0
	rig.reset()
	for i in 60:
		rig.animate(1.0 / 60.0, state)
	var standing_height: float = rig._upper.position.y
	state["crouch"] = 1.0
	for i in 60:
		rig.animate(1.0 / 60.0, state)
	check.call(rig._upper.position.y < standing_height - 0.16,
		"trick animation: held ollie crouch visibly lowers the connected body")
	owner.free()
