extends RefCounted
## Contact/continuity proof for authored setup and recovery animation. These
## fixtures inspect the actual rig meshes; they do not admit or score a trick.

const BoardGeometry = preload("res://tests/board_geometry_tests_support.gd")
const Visual = preload("res://.local/skitch_attachment_baseline_visual.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const SOLE := Vector3(0, -0.0605, 0)
const PALM := Vector3(0, -0.075, -0.015)
const STEP := Vector3(-0.34, 0, -0.255)
const BONELESS_EDGE := Vector3(0.128, 0.022, 0.02)


static func run(tree: SceneTree, check: Callable) -> void:
	await _startup_pose(tree, check)
	await _setup_contacts(tree, check)
	await _board_mesh_contacts(tree, check)
	await _catch_and_landing(tree, check)
	await _recovery(tree, check)
	await _lip_contacts(tree, check)
	await _manual_styles(tree, check)
	await _manual_motion(tree, check)
	await _weighted_manual_contacts(tree, check)
	await _bearing_lips(tree, check)
	await _specials_and_stance(tree, check)
	await _interrupted_recovery(tree, check)
	await _grab_extension(tree, check)
	await _skitch_contacts(tree, check)
	await _ordinary_foot_support(tree, check)
	await _recorded_drag_reach(tree, check)
	await _helper_keeps_deck_contact(tree, check)


static func _startup_pose(tree: SceneTree, check: Callable) -> void:
	# The fixture never ticks the rig. These are its construction/reset poses,
	# including when Main is still at the title or a report freezes the first frame.
	var fixture := await _fixture(tree)
	var initial := _markers(fixture.rig)
	check.call(fixture.rig._upper.position.y > 0.75
		and fixture.rig._head.global_position.y-fixture.rider.global_position.y > 1.35,
		"startup pose: complete torso and head are placed before the first animation tick")
	check.call(_feet_error(fixture) < 0.001 and _finite(fixture.rig)
		and _max_stretch(fixture.rig) <= 1.12,
		"startup pose: both visible shoes contact the board with finite anatomical limbs immediately after construction")
	var state := _neutral()
	state["bail"] = 1.0
	_settle(fixture.rig, state)
	fixture.rig.reset()
	check.call(_marker_delta(initial, _markers(fixture.rig)) < 0.001
		and _feet_error(fixture) < 0.001 and fixture.rig._bail_blend == 0.0,
		"startup pose: reset immediately restores the complete neutral rig after an interrupted bail")
	await _dispose(tree, fixture.root)


static func _setup_contacts(tree: SceneTree, check: Callable) -> void:
	for request: Array in [[0.0, 0.0, Vector3.UP], [0.8, PI, Vector3.UP],
		[0.4, 0.0, Vector3(0.12, 0.985, 0.08).normalized()]]:
		var fixture := await _fixture(tree, request[0], request[1], request[2])
		var label := "yaw %.2f / rest %.2f" % [request[0], request[1]]
		check.call(not fixture.contact.is_empty(), "authentic pose: real support ray exists " + label)
		if fixture.contact.is_empty():
			await _dispose(tree, fixture.root)
			continue
		for id: String in ["boneless", "no_comply"]:
			fixture.rig.reset()
			var state := _neutral()
			state.merge({"setup_active": true, "setup_id": id, "setup_phase": 0.55,
				"setup_ground_point": fixture.contact.position, "setup_normal": fixture.contact.normal,
				"deck_yaw": request[1], "rest_deck_yaw": request[1]}, true)
			_settle(fixture.rig, state)
			var front: Node3D = fixture.rig._legs[0].foot
			var rear: Node3D = fixture.rig._legs[1].foot
			var planted: Vector3 = front.to_global(SOLE)
			var normal: Vector3 = fixture.contact.normal
			var sole_error := _sole_plane_error(front, fixture.contact.position, normal)
			check.call(planted.distance_to(fixture.contact.position) < 0.004
				and front.global_basis.y.normalized().dot(normal) > 0.998 and sole_error < 0.004,
				"authentic pose: actual front shoe sole plants on ray point and plane " + id + " " + label)
			check.call(_grip_distance(fixture, rear.to_global(SOLE)) < 0.004,
				"authentic pose: supporting rear shoe stays on the visible deck " + id + " " + label)
			check.call(_finite(fixture.rig) and _max_stretch(fixture.rig) <= 1.12,
				"authentic pose: setup limbs remain finite and within human reach " + id + " " + label)
			if id == "boneless":
				var hand: Node3D = fixture.rig._arms[1].hand
				var palm := hand.to_global(PALM)
				var edge: Vector3 = fixture.board.to_global(Basis(Vector3.UP, -request[1]) * BONELESS_EDGE)
				var fingers: MeshInstance3D = hand.get_node("HandAndFingers")
				check.call(palm.distance_to(edge) < 0.025 and fingers.get_blend_shape_value(0) > 0.8,
					"authentic pose: Boneless palm grips the real deck edge with curled fingers " + label)
				check.call(_nearest_vertex(fingers, edge) < 0.025,
					"authentic pose: visible anatomical palm geometry reaches the Boneless contact " + label)
		await _dispose(tree, fixture.root)


static func _board_mesh_contacts(tree: SceneTree, check: Callable) -> void:
	for rest: float in [0.0, PI]:
		var fixture := await _fixture(tree, 0.6, rest)
		fixture.board.rotation = Vector3(0.30, rest, -0.15)
		var state := _neutral()
		state.merge({"deck_yaw": rest, "rest_deck_yaw": rest}, true)
		_settle(fixture.rig, state)
		var geometry: Dictionary = fixture.rig.board_contact_geometry()
		var faces: PackedVector3Array = geometry.grip_faces
		var sole_min := INF
		var complete_min := INF
		for leg: Dictionary in fixture.rig._legs:
			var contact: Vector3 = fixture.board.to_local(leg.foot.to_global(SOLE))
			var height := _triangle_height(faces, contact)
			sole_min = minf(sole_min, contact.y - height)
			for mesh: MeshInstance3D in [leg.foot.get_node("Cupsole"), leg.foot.get_node("CanvasUpper")]:
				var unique: Dictionary = {}
				for point: Vector3 in mesh.mesh.get_faces(): unique[point] = true
				for point: Vector3 in unique:
					var local: Vector3 = fixture.board.to_local(mesh.to_global(point))
					var surface := _triangle_height(faces, local)
					if is_finite(surface): complete_min = minf(complete_min, local.y - surface)
		check.call(sole_min >= -0.001 and sole_min < 0.001 and _feet_error(fixture) < 0.001,
			"authentic board: both caught sole markers rest on actual griptape triangles rest=%.2f" % rest)
		check.call(complete_min >= -0.0015,
			"authentic board: complete cupsole and shoe upper vertices stay outside the deck rest=%.2f" % rest)
		# Retain the latest default asset exactly: its joined metal surface
		# contains the authored bolt caps, not eight old procedural spheres.
		check.call(geometry.meshes.size() == 1 and geometry.meshes[0].mesh.get_surface_count() == 4
			and FileAccess.get_sha256("res://game/art/assets/tam_skateboard/tam_skateboard.glb") == "d5a68a8bd94fa8ad5c374ceddeb3804cc38d7ef780c5b87d3093ef8e15431f99",
			"authentic board: original native GLB geometry including its hardware remains unchanged rest=%.2f" % rest)
		var wood_faces: PackedVector3Array = geometry.wood_faces
		check.call(_triangle_height(faces, Vector3(0, 0, 0.255)) < 0.018
			and _triangle_height(faces, Vector3(0, 0, 0.38)) > 0.036
			and is_finite(_triangle_height(wood_faces, Vector3(0.115, 0, 0))),
			"authentic board: flat stance, curved kicks and closed exposed wood border are actual triangles rest=%.2f" % rest)
		for id: String in Catalog.family_ids("grab"):
			var definition: Dictionary = Catalog.definition(id)
			fixture.board.rotation = Vector3(cos(rest) * float(definition.get("board_pitch", 0)), rest,
				cos(rest) * float(definition.get("board_roll", 0)))
			fixture.rider.position.y = -0.17
			fixture.rider.rotation.x = -0.30
			state.merge({"airborne": true, "grab": true, "grab_side": definition.grab_side,
				"grab_target": definition.grab_target, "grab_definition": definition}, true)
			_settle(fixture.rig, state)
			var hand: Node3D = fixture.rig._arms[0 if definition.grab_side < 0 else 1].hand
			var palm: Vector3 = fixture.board.to_local(hand.to_global(PALM))
			var height := _triangle_height(faces, palm)
			var inside_wood := is_finite(height) and palm.y < height - 0.001
			var distance := minf(BoardGeometry.faces_distance(hand.to_global(PALM), faces, fixture.board),
				BoardGeometry.faces_distance(hand.to_global(PALM), wood_faces, fixture.board))
			check.call(not inside_wood and distance < 0.025 and _feet_error(fixture) < 0.001
				and _max_stretch(fixture.rig) <= 1.12,
				"authentic board: grab palm wraps the rendered surface while caught soles stay clear %s rest=%.2f" % [id, rest])
		print("AUTHENTIC_BOARD rest=%.2f caught_sole=%.6f complete_shoe=%.6f retained_native_model=true" % [rest, sole_min, complete_min])
		await _dispose(tree, fixture.root)


static func _triangle_height(faces: PackedVector3Array, point: Vector3) -> float:
	var height := -INF
	var p := Vector2(point.x, point.z)
	for index in range(0, faces.size(), 3):
		var a := Vector2(faces[index].x, faces[index].z)
		var b := Vector2(faces[index + 1].x, faces[index + 1].z)
		var c := Vector2(faces[index + 2].x, faces[index + 2].z)
		var ab := b - a
		var ac := c - a
		var determinant := ab.cross(ac)
		if absf(determinant) < 0.0000000001: continue
		var u := (p - a).cross(ac) / determinant
		var v := ab.cross(p - a) / determinant
		if u >= -0.00001 and v >= -0.00001 and u + v <= 1.00001:
			height = maxf(height, faces[index].y * (1.0 - u - v) + faces[index + 1].y * u + faces[index + 2].y * v)
	return height


static func _grip_distance(fixture: Dictionary, contact: Vector3) -> float:
	return BoardGeometry.grip_distance(fixture.rig, contact)


static func _catch_and_landing(tree: SceneTree, check: Callable) -> void:
	for id: String in ["boneless", "no_comply"]:
		var fixture := await _fixture(tree)
		var state := _neutral()
		_settle(fixture.rig, state)
		state.merge({"setup_active": true, "setup_id": id, "setup_phase": 0.0,
			"setup_ground_point": fixture.contact.position, "setup_normal": fixture.contact.normal}, true)
		var previous := _markers(fixture.rig)
		var max_jump := 0.0
		var finite := true
		# Advance the authored setup in its real duration, then the launch/catch.
		var duration := 0.22 if id == "boneless" else 0.16
		var setup_frames := ceili(duration * 60.0)
		for frame in range(setup_frames + 1):
			state.setup_phase = float(frame) / setup_frames
			fixture.rig.animate(1.0 / 60.0, state)
			var current := _markers(fixture.rig)
			max_jump = maxf(max_jump, _marker_delta(previous, current))
			previous = current
			finite = finite and _finite(fixture.rig)
		state.merge({"setup_active": false, "airborne": true, "launch_id": id, "launch_age": 0.0}, true)
		for frame in 25:
			state.launch_age = float(frame) / 60.0
			fixture.rig.animate(1.0 / 60.0, state)
			var current := _markers(fixture.rig)
			max_jump = maxf(max_jump, _marker_delta(previous, current))
			previous = current
			finite = finite and _finite(fixture.rig)
		check.call(finite and max_jump < 0.22,
			"authentic pose: setup to airborne catch has continuous finite articulated motion " + id)
		print("AUTHENTIC_POSE setup=%s max_step=%.3f" % [id, max_jump])
		check.call(_feet_error(fixture) < 0.005,
			"authentic pose: both actual shoe targets catch the deck after the bounded release " + id)
		var caught_head: float = fixture.rig._head.global_position.y
		state.airborne = false
		var lowest_head := caught_head
		for frame in 30:
			fixture.rig.animate(1.0 / 60.0, state)
			lowest_head = minf(lowest_head, fixture.rig._head.global_position.y)
		check.call(caught_head - lowest_head > 0.045 and _feet_error(fixture) < 0.005,
			"authentic pose: caught landing compresses knees and torso while shoes remain planted " + id)
		await _dispose(tree, fixture.root)


static func _recovery(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var state := _neutral()
	_settle(fixture.rig, state)
	var ordinary: Transform3D = fixture.rider.transform
	var ordinary_head: Vector3 = fixture.rig._head.global_position
	var previous := _markers(fixture.rig)
	var max_jump := 0.0
	var lowest_head := ordinary_head.y
	var head_clearance := INF
	var shoe_clearance := INF
	var finite := true
	var stretch := 0.0
	state.merge({"bail_active": true, "bail_phase": "fall", "bail": 0.0,
		"bail_ground_point": fixture.body.global_position, "bail_normal": Vector3.UP}, true)
	for frame in 91:
		state.bail = sin(PI * float(frame) / 90.0)
		fixture.rig.animate(1.0 / 60.0, state)
		var current := _markers(fixture.rig)
		max_jump = maxf(max_jump, _marker_delta(previous, current))
		previous = current
		lowest_head = minf(lowest_head, fixture.rig._head.global_position.y)
		finite = finite and _finite(fixture.rig)
		stretch = maxf(stretch, _max_stretch(fixture.rig))
		var head_mesh: MeshInstance3D = fixture.rig._head.get_node("AnatomicalHead")
		head_clearance = minf(head_clearance, _minimum_plane_distance(head_mesh, fixture.body.global_position, Vector3.UP))
		for leg: Dictionary in fixture.rig._legs:
			shoe_clearance = minf(shoe_clearance, _minimum_plane_distance(
				leg.foot.get_node("Cupsole"), fixture.body.global_position, Vector3.UP))
	check.call(ordinary_head.y - lowest_head > 0.65,
		"authentic pose: native local bail lowers the figure below the riding head height")
	check.call(finite and stretch <= 1.12 and max_jump < 0.22,
		"authentic pose: native local fall and get-up stay finite without limb stretch or pose teleports")
	check.call(head_clearance > -0.02 and shoe_clearance > -0.02,
		"authentic pose: actual head and sole meshes stay above the supplied recovery plane")
	state.bail_active = false
	fixture.rig.animate(1.0 / 60.0, state)
	check.call(fixture.rider.transform.origin.distance_to(ordinary.origin) < 0.005
		and fixture.rider.basis.get_rotation_quaternion().angle_to(ordinary.basis.get_rotation_quaternion()) < 0.01
		and _feet_error(fixture) < 0.005 and _marker_delta(previous, _markers(fixture.rig)) < 0.08,
		"authentic pose: completed get-up restores the original stance and deck contact continuously")
	fixture.rig.reset()
	_settle(fixture.rig, _neutral())
	check.call(_feet_error(fixture) < 0.005 and _finite(fixture.rig),
		"authentic pose: explicit reset clears all setup and recovery offsets")
	print("AUTHENTIC_POSE recovery head_drop=%.3f head_clearance=%.3f sole_clearance=%.3f max_step=%.3f max_stretch=%.3f" % [
		ordinary_head.y-lowest_head, head_clearance, shoe_clearance, max_jump, stretch])
	await _dispose(tree, fixture.root)


static func _fixture(tree: SceneTree, yaw: float = 0.0, rest_yaw: float = 0.0,
		normal: Vector3 = Vector3.UP, native_body: bool = false) -> Dictionary:
	var root := Node3D.new()
	root.position = Vector3(6, 3, -8)
	tree.root.add_child(root)
	var floor := StaticBody3D.new()
	floor.basis = Basis(Quaternion(Vector3.UP, normal))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 0.1, 8)
	collision.shape = shape
	collision.position.y = -0.05
	floor.add_child(collision)
	root.add_child(floor)
	var body: Node3D = CharacterBody3D.new() if native_body else Node3D.new()
	body.rotation.y = yaw
	root.add_child(body)
	var visual := Node3D.new()
	body.add_child(visual)
	visual.global_basis = Basis(Quaternion(Vector3.UP, normal)) * body.global_basis
	var board := Node3D.new()
	board.position.y = 0.12
	board.rotation.y = rest_yaw
	visual.add_child(board)
	var rider := Node3D.new()
	rider.rotation.y = -PI / 2.0 + 0.28
	visual.add_child(rider)
	var rig = Visual.new()
	rig.build(board, rider, StandardMaterial3D.new())
	for frame in 2:
		await tree.physics_frame
		await tree.process_frame
	var at := body.to_global(STEP)
	var query := PhysicsRayQueryParameters3D.create(at + normal * 0.8, at - normal * 0.8, 1)
	var contact := root.get_world_3d().direct_space_state.intersect_ray(query)
	return {"root": root, "body": body, "visual": visual, "board": board,
		"rider": rider, "rig": rig, "contact": contact, "rest_yaw": rest_yaw}


static func _lip_contacts(tree: SceneTree, check: Callable) -> void:
	for id: String in ["handplant", "invert", "eggplant"]:
		var fixture := await _fixture(tree)
		var definition: Dictionary = Catalog.definition(id)
		var state := _neutral()
		state.merge({"lip_active": true, "lip_definition": definition,
			"lip_ground_point": fixture.body.global_position, "lip_normal": Vector3.UP}, true)
		_settle(fixture.rig, state)
		var side := float(definition.get("lip_hand_side", 1.0))
		var hand: Node3D = fixture.rig._arms[0 if side < 0 else 1].hand
		var expected_palm: Vector3 = fixture.body.global_position + (Vector3.RIGHT * 0.14 if is_zero_approx(side) else Vector3.ZERO)
		var error := hand.to_global(PALM).distance_to(expected_palm)
		var lip_stretch := _max_stretch(fixture.rig)
		check.call(error < 0.005 and _feet_error(fixture) < 0.005,
			"authentic pose: lip palm supports actual coping point while both shoes hold inverted deck " + id)
		check.call(_finite(fixture.rig) and _max_stretch(fixture.rig) <= 1.12
			and fixture.rig._head.global_position.y < fixture.board.global_position.y - 0.8,
			"authentic pose: inverted lip body remains finite and within human reach " + id)
		check.call(_minimum_plane_distance(fixture.rig._head.get_node("AnatomicalHead"), fixture.body.global_position, Vector3.UP) > -0.02,
			"authentic pose: actual inverted anatomical head stays above coping plane " + id)
		state.lip_active = false
		_settle(fixture.rig, state)
		check.call(_feet_error(fixture) < 0.005 and fixture.board.position.y < 0.14,
			"authentic pose: handplant release returns body and board to ordinary shoe contacts " + id)
		print("AUTHENTIC_POSE lip=%s palm_error=%.4f stretch=%.3f" % [id, error, lip_stretch])
		await _dispose(tree, fixture.root)


static func _manual_styles(tree: SceneTree, check: Callable) -> void:
	for id: String in ["hang_ten", "crossfoot_manual", "pogo", "casper_manual"]:
		var fixture := await _fixture(tree)
		var definition: Dictionary = Catalog.definition(id)
		var state := _neutral()
		state.merge({"manual": true, "manual_definition": definition,
			"manual_sign": definition.get("manual_sign", 1.0)}, true)
		fixture.board.rotation.x = -0.28 if id == "hang_ten" else (1.22 if id == "pogo" else 0.35)
		if id == "casper_manual": fixture.board.rotation.z = PI
		_settle(fixture.rig, state)
		check.call(_finite(fixture.rig) and _max_stretch(fixture.rig) <= 1.12,
			"authentic pose: authored manual extension keeps finite human limb reach " + id)
		check.call(fixture.rig._legs[0].foot.global_position.distance_to(fixture.rig._legs[1].foot.global_position) > 0.05,
			"authentic pose: manual extension gives each actual shoe a distinct support target " + id)
		if id == "casper_manual":
			check.call(fixture.rig._legs[0].foot.to_global(Vector3(0, 0.001, -0.115)).distance_to(
				fixture.board.to_global(Vector3(0, 0.022, -0.29))) < 0.005,
				"authentic pose: Casper uses the actual low toe vertex under the visible deck nose")
		await _dispose(tree, fixture.root)


static func _manual_motion(tree: SceneTree, check: Callable) -> void:
	for rest: float in [0.0, PI]:
		var fixture := await _fixture(tree, 0.6, rest)
		var state := _neutral()
		state.merge({"manual": true, "manual_definition": Catalog.definition("manual"),
			"deck_yaw": rest, "rest_deck_yaw": rest}, true)
		fixture.rider.position.y = -0.10
		fixture.rider.rotation.x = -0.18
		_settle(fixture.rig, state)
		var previous := _markers(fixture.rig)
		for id: String in ["hang_ten", "crossfoot_manual", "pogo", "casper_manual"]:
			var max_step := 0.0
			var stretch := 0.0
			var board_clearance := INF
			var sole_clearance := INF
			for phase in 2:
				var definition: Dictionary = Catalog.definition(id if phase == 0 else "manual")
				state.manual_definition = definition
				state.manual_sign = definition.get("manual_sign", 1.0)
				for frame in 40:
					_manual_frame(fixture, state)
					var current := _markers(fixture.rig)
					max_step = maxf(max_step, _marker_delta(previous, current))
					previous = current
					stretch = maxf(stretch, _max_stretch(fixture.rig))
					for child: MeshInstance3D in fixture.rig.board_contact_geometry().meshes:
						if child is MeshInstance3D:
							board_clearance = minf(board_clearance, _minimum_plane_distance(child,
								fixture.body.global_position, Vector3.UP))
					for leg: Dictionary in fixture.rig._legs:
						sole_clearance = minf(sole_clearance, _minimum_plane_distance(leg.foot.get_node("Cupsole"),
							fixture.body.global_position, Vector3.UP))
				if phase == 0 and id == "pogo":
					var sole_error := 0.0
					var palm_error := 0.0
					var real_grip_error := 0.0
					for index in 2:
						var side := -1.0 if index == 0 else 1.0
						var foot: Node3D = fixture.rig._legs[index].foot
						sole_error = maxf(sole_error, foot.to_global(SOLE).distance_to(fixture.rig.pogo_foot_contact(side, rest)))
						var target: Vector3 = fixture.board.to_global(Basis(Vector3.UP, -rest) * Visual.pogo_hand_target(side))
						var hand: Node3D = fixture.rig._arms[index].hand
						palm_error = maxf(palm_error, hand.to_global(PALM).distance_to(target))
						real_grip_error = maxf(real_grip_error, BoardGeometry.faces_distance(target, fixture.rig.board_contact_geometry().grip_faces, fixture.board))
						check.call(foot.global_basis.y.dot(Vector3.UP) > 0.998,
							"authentic pose: Pogo shoe stays horizontal on actual rear wheel rest=%.2f side=%.0f" % [rest, side])
					check.call(sole_error < 0.005 and palm_error < 0.025 and real_grip_error < 0.005,
						"authentic pose: Pogo soles and anatomical palms meet actual wheel and nose geometry rest=%.2f" % rest)
					print("AUTHENTIC_MANUAL pogo rest=%.2f sole=%.4f palm=%.4f grip_surface=%.4f" % [rest, sole_error, palm_error, real_grip_error])
				if phase == 0 and id == "casper_manual":
					var toe: Vector3 = fixture.rig._legs[0].foot.to_global(Vector3(0, 0.001, -0.115))
					var target: Vector3 = fixture.board.to_global(Basis(Vector3.UP, -rest) * Vector3(0, 0.022, -0.29))
					check.call(toe.distance_to(target) < 0.005 and fixture.board.global_basis.y.dot(Vector3.UP) < -0.85,
						"authentic pose: Casper real toe bears under the inverted functional nose rest=%.2f" % rest)
			check.call(max_step < 0.22 and stretch <= 1.12 and _finite(fixture.rig),
				"authentic pose: manual entry and release preserve articulated continuity and reach %s rest=%.2f" % [id, rest])
			check.call(board_clearance > -0.005 and sole_clearance > -0.02,
				"authentic pose: actual complete board and shoe meshes clear floor throughout %s rest=%.2f" % [id, rest])
			print("AUTHENTIC_MANUAL id=%s rest=%.2f step=%.4f stretch=%.4f board=%.4f sole=%.4f" % [id, rest, max_step, stretch, board_clearance, sole_clearance])
		# A grounded Casper may be followed immediately by an Ollie. Keep its
		# departing sole/board sweep above support while the native body rises.
		state.manual_definition = Catalog.definition("casper_manual")
		for frame in 40: _manual_frame(fixture, state)
		previous = _markers(fixture.rig)
		state.manual = false
		state.airborne = true
		var exit_step := 0.0
		var exit_clearance := INF
		for frame in 25:
			_manual_frame(fixture, state)
			exit_step = maxf(exit_step, _marker_delta(previous, _markers(fixture.rig)))
			previous = _markers(fixture.rig)
			for child: MeshInstance3D in fixture.rig.board_contact_geometry().meshes:
				if child is MeshInstance3D: exit_clearance = minf(exit_clearance,
					_minimum_plane_distance(child, fixture.body.global_position, Vector3.UP))
		check.call(exit_step < 0.22 and exit_clearance > -0.005 and _max_stretch(fixture.rig) <= 1.12,
			"authentic pose: Casper to airborne catch clears support without a pose teleport rest=%.2f" % rest)
		fixture.rig.reset()
		check.call(absf(fixture.rig._manual_shift) < 0.0001 and fixture.rig._cross_blend == 0.0
			and fixture.rig._pogo_blend == 0.0 and fixture.rig._casper_blend == 0.0,
			"authentic pose: explicit reset clears every manual style blend rest=%.2f" % rest)
		await _dispose(tree, fixture.root)


static func _manual_frame(fixture: Dictionary, state: Dictionary) -> void:
	var definition: Dictionary = state.manual_definition
	var sign_value := float(definition.get("manual_sign", 1.0))
	state.manual_sign = sign_value
	state.manual_foot_lift = float(definition.get("manual_foot_lift", 0.0))
	var pitch := sign_value * deg_to_rad(16.0) if state.manual else 0.0
	var roll := 0.0
	if state.manual and definition.get("manual_pogo", false): pitch = 1.22
	if state.manual and definition.get("manual_casper", false):
		pitch = 0.35
		roll = PI
	fixture.board.rotation.x = lerpf(fixture.board.rotation.x, cos(fixture.rest_yaw) * pitch, 1.0 - exp(-16.0 / 60.0))
	fixture.board.rotation.z = lerpf(fixture.board.rotation.z, cos(fixture.rest_yaw) * roll, 1.0 - exp(-16.0 / 60.0))
	fixture.rider.rotation.x = lerpf(fixture.rider.rotation.x, sign_value * -0.18 if state.manual else -0.10, 1.0 - exp(-16.0 / 60.0))
	fixture.rider.position.y = -0.10 if state.manual else lerpf(fixture.rider.position.y, 0, 1.0 - exp(-16.0 / 60.0))
	fixture.rig.animate(1.0 / 60.0, state)


static func _weighted_manual_contacts(tree: SceneTree, check: Callable) -> void:
	for rest: float in [0.0, PI]:
		var fixture := await _fixture(tree, 0.5, rest)
		var state := _neutral()
		state.merge({"manual": true, "manual_definition": Catalog.definition("manual"),
			"deck_yaw": rest, "rest_deck_yaw": rest}, true)
		for id: String in ["one_foot_manual", "one_foot_nose_manual"]:
			state.manual_definition = Catalog.definition(id)
			for frame in 90: _manual_frame(fixture, state)
			var planted := 1 if id == "one_foot_manual" else 0
			var raised := 1 - planted
			var free: Vector3 = fixture.board.to_local(fixture.rig._legs[raised].foot.to_global(SOLE))
			var grip_faces: PackedVector3Array = fixture.rig.board_contact_geometry().grip_faces
			var lift := free.y - _triangle_height(grip_faces, free)
			check.call(_grip_distance(fixture, fixture.rig._legs[planted].foot.to_global(SOLE)) < 0.001
				and lift > 0.15 and _max_stretch(fixture.rig) <= 1.12,
				"authentic manual: %s loads the %s foot and raises its partner rest=%.2f" % [id, "rear" if planted == 1 else "front", rest])
		state.manual_definition = Catalog.definition("hang_ten")
		for frame in 90: _manual_frame(fixture, state)
		var tape_faces: PackedVector3Array = fixture.rig.board_contact_geometry().grip_faces
		var wood_faces: PackedVector3Array = fixture.rig.board_contact_geometry().wood_faces
		for leg: Dictionary in fixture.rig._legs:
			var foot: Node3D = leg.foot
			var functional: Vector3 = Basis(Vector3.UP, rest) * fixture.board.to_local(foot.to_global(SOLE))
			var forward: Vector3 = fixture.board.global_basis * Basis(Vector3.UP, -rest) * Vector3.FORWARD
			check.call(functional.z < -0.22 and functional.z > -0.28
				and functional.x * float(leg.side) > 0.055 and foot.global_basis.z.dot(-forward) > 0.99,
				"authentic manual: Hang Ten clusters a forward-facing shoe over the functional nose rest=%.2f side=%.0f" % [rest, leg.side])
			var front_bearing := INF
			var heel_bearing := INF
			var complete := INF
			for mesh: MeshInstance3D in [foot.get_node("Cupsole"), foot.get_node("CanvasUpper")]:
				var unique: Dictionary = {}
				for point: Vector3 in mesh.mesh.get_faces(): unique[point] = true
				for point: Vector3 in unique:
					var local: Vector3 = fixture.board.to_local(mesh.to_global(point))
					var height := maxf(_triangle_height(tape_faces, local), _triangle_height(wood_faces, local))
					if not is_finite(height): continue
					var gap: float = local.y - height
					complete = minf(complete, gap)
					if mesh.name == "Cupsole" and point.y < -0.0604:
						if point.z < -0.025: front_bearing = minf(front_bearing, absf(gap))
						elif point.z > 0.025: heel_bearing = minf(heel_bearing, absf(gap))
			check.call(front_bearing < 0.001 and heel_bearing < 0.001 and complete > -0.0015
				and _max_stretch(fixture.rig) <= 1.12,
				"authentic manual: Hang Ten real heel and forefoot bear on curved grip or wood without embedding rest=%.2f side=%.0f" % [rest, leg.side])
			print("AUTHENTIC_HANG rest=%.2f side=%.0f sole=%s forefoot=%.6f heel=%.6f whole=%.6f" % [rest, leg.side, functional, front_bearing, heel_bearing, complete])
		fixture.rig.reset()
		check.call(fixture.rig._front_foot_lift == 0.0 and fixture.rig._rear_foot_lift == 0.0,
			"authentic manual: reset clears both weighted-foot role blends rest=%.2f" % rest)
		await _dispose(tree, fixture.root)


static func _bearing_lips(tree: SceneTree, check: Callable) -> void:
	for id: String in ["lip_stall", "nose_stall", "tail_stall", "axle_stall", "rock_and_roll", "disaster_stall"]:
		var fixture := await _fixture(tree)
		var definition: Dictionary = Catalog.definition(id)
		fixture.board.rotation = Vector3(definition.get("lip_pitch", 0.0), definition.get("lip_yaw", 0.0), definition.get("lip_roll", 0.0))
		var state := _neutral()
		state.merge({"lip_active": true, "lip_definition": definition,
			"lip_ground_point": fixture.body.global_position, "lip_normal": Vector3.UP}, true)
		_settle(fixture.rig, state)
		var bearing := Vector3(0, -0.014, 0)
		if id == "nose_stall": bearing = Vector3(0, -0.103, -0.255)
		elif id == "tail_stall": bearing = Vector3(0, -0.103, 0.255)
		elif id == "axle_stall": bearing = Vector3(0, -0.103, 0)
		check.call(fixture.board.to_global(bearing).distance_to(fixture.body.global_position) < 0.005
			and _feet_error(fixture) < 0.005,
			"authentic pose: visible lip bearing and actual shoe targets meet their authored support " + id)
		check.call(_finite(fixture.rig) and _max_stretch(fixture.rig) <= 1.12,
			"authentic pose: turned lip stance remains within human reach " + id)
		await _dispose(tree, fixture.root)


static func _specials_and_stance(tree: SceneTree, check: Callable) -> void:
	for id: String in Catalog.family_ids("special"):
		var fixture := await _fixture(tree)
		var definition: Dictionary = Catalog.definition(id)
		var state := _neutral()
		fixture.visual.rotation = Vector3(float(definition.special_body_pitch), float(definition.special_body_yaw), float(definition.special_body_roll)) * 0.5
		fixture.board.rotation = Vector3(float(definition.special_board_pitch), float(definition.special_board_yaw) * 0.5, float(definition.special_board_roll) * 0.5)
		fixture.rider.position.y = -float(definition.special_tuck)
		state.merge({"airborne": true, "special_id": id, "special_progress": 0.5,
			"special_definition": definition}, true)
		_settle(fixture.rig, state)
		check.call(_finite(fixture.rig) and _max_stretch(fixture.rig) <= 1.12,
			"authentic pose: authored special body and board turns retain finite human articulation " + id)
		if bool(definition.special_grab):
			var hand: Node3D = fixture.rig._arms[1].hand
			check.call(hand.to_global(PALM).distance_to(fixture.board.to_global(BONELESS_EDGE)) < 0.025,
				"authentic pose: Salute palm keeps the actual raised deck contact")
		await _dispose(tree, fixture.root)
	var fixture := await _fixture(tree)
	var state := _neutral()
	state.push = true
	state.travel_sign = 1.0
	_settle(fixture.rig, state)
	var forward_toe: Vector3 = -fixture.rig._legs[1].foot.global_basis.z
	fixture.rig.reset()
	state.travel_sign = -1.0
	_settle(fixture.rig, state)
	var reverse_toe: Vector3 = -fixture.rig._legs[1].foot.global_basis.z
	check.call(forward_toe.dot(Vector3.FORWARD) > 0.98 and reverse_toe.dot(Vector3.BACK) > 0.98,
		"authentic pose: pushing shoes point along actual regular and fakie travel")
	await _dispose(tree, fixture.root)


static func _interrupted_recovery(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	fixture.body.position.y = 2.0
	fixture.rider.position.y = -0.17
	fixture.rider.rotation.x = -0.30
	var state := _neutral()
	state.merge({"airborne": true, "flip": true, "flip_progress": 0.5}, true)
	_settle(fixture.rig, state)
	fixture.rig.begin_bail()
	var parent_frame: Transform3D = fixture.rider.transform
	state.merge({"airborne": false, "flip": false, "bail_active": true, "bail_phase": "fall",
		"bail": 0.0, "bail_ground_point": fixture.root.global_position}, true)
	var maximum := 0.0
	var local_frame_held := true
	var lowest := INF
	for frame in 91:
		state.bail = sin(PI * float(frame) / 90.0)
		fixture.rig.animate(1.0 / 60.0, state)
		maximum = maxf(maximum, _max_stretch(fixture.rig))
		local_frame_held = local_frame_held and fixture.rider.transform.is_equal_approx(parent_frame)
		lowest = minf(lowest, fixture.rig._head.global_position.y)
	check.call(local_frame_held,
		"authentic pose: interrupted native bail retains controller-owned local parent frame")
	check.call(lowest > fixture.root.global_position.y + 1.5,
		"authentic pose: distant recovery ground cannot teleport the locally posed rider below its native body")
	check.call(maximum <= 1.12 and _finite(fixture.rig),
		"authentic pose: interrupted native local recovery keeps fixed anatomical reach")
	await _dispose(tree, fixture.root)


static func _grab_extension(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var definition: Dictionary = Catalog.definition("melon_grab")
	fixture.rider.position.y = -0.17
	fixture.rider.rotation.x = -0.30
	var state := _neutral()
	state.merge({"airborne": true, "grab": true, "grab_side": definition.grab_side,
		"grab_target": definition.grab_target, "grab_definition": definition}, true)
	_settle(fixture.rig, state)
	var skeleton: Skeleton3D = fixture.rig._garments.skeleton
	var hip: Vector3 = skeleton.get_bone_pose_position(skeleton.find_bone("left_thigh"))
	var ordinary_reach := hip.distance_to(fixture.rig._legs[0].foot.position)
	state.grab_definition = definition.duplicate(true)
	state.grab_definition.tweak_leg_extension = 0.20
	_settle(fixture.rig, state)
	hip = skeleton.get_bone_pose_position(skeleton.find_bone("left_thigh"))
	var boned_reach := hip.distance_to(fixture.rig._legs[0].foot.position)
	check.call(boned_reach > ordinary_reach + 0.01,
		"authentic pose: Boned tweak visibly straightens the actual articulated front leg")
	var hand: Node3D = fixture.rig._arms[0].hand
	check.call(hand.to_global(PALM).distance_to(fixture.board.to_global(definition.grab_target)) < 0.025
		and _feet_error(fixture) < 0.005 and _max_stretch(fixture.rig) <= 1.12,
		"authentic pose: Boned extension preserves anatomical palm and planted shoe contacts within human reach")
	await _dispose(tree, fixture.root)


static func _skitch_contacts(tree: SceneTree, check: Callable) -> void:
	for yaw: float in [0.0, 0.8]:
		var fixture := await _fixture(tree, yaw)
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.04, 0.08, 0.08)
		bar.mesh = mesh
		bar.position = Vector3(0, 0.93, -0.545)
		fixture.body.add_child(bar)
		var grips: Array[Vector3] = [fixture.body.to_global(Vector3(-0.40, 0.93, -0.505)),
			fixture.body.to_global(Vector3(0.40, 0.93, -0.505))]
		var state := _neutral()
		state.merge({"skitching": true, "skitch_grips": grips,
			"skitch_normal": fixture.body.global_basis.z}, true)
		_settle(fixture.rig, state)
		var error := 0.0
		var visible_error := 0.0
		for index in 2:
			var hand: Node3D = fixture.rig._arms[index].hand
			error = maxf(error, hand.to_global(PALM).distance_to(grips[index]))
			visible_error = maxf(visible_error, _nearest_vertex(hand.get_node("HandAndFingers"), grips[index]))
		check.call(error < 0.025 and visible_error < 0.025 and _feet_error(fixture) < 0.005,
			"authentic pose: both skitch palms grip the visible rear bar while shoes stay on deck yaw=" + str(yaw))
		check.call(_finite(fixture.rig) and _max_stretch(fixture.rig) <= 1.12,
			"authentic pose: skitch shoulder fold reaches real handles without rubber arms yaw=" + str(yaw))
		var previous := _markers(fixture.rig)
		var max_step := 0.0
		state.skitching = false
		state.skitch_grips = []
		for frame in 40:
			fixture.rig.animate(1.0 / 60.0, state)
			var current := _markers(fixture.rig)
			max_step = maxf(max_step, _marker_delta(previous, current))
			previous = current
		check.call(max_step < 0.22 and _feet_error(fixture) < 0.005,
			"authentic pose: releasing a tow blends hands clear without a stance teleport yaw=" + str(yaw))
		state.skitching = true
		state.skitch_grips = grips
		_settle(fixture.rig, state)
		var grab_definition: Dictionary = Catalog.definition("melon_grab")
		state.merge({"skitching": false, "skitch_grips": [], "airborne": true, "grab": true,
			"grab_side": grab_definition.grab_side, "grab_target": grab_definition.grab_target,
			"grab_definition": grab_definition}, true)
		fixture.rider.position.y = -0.17
		fixture.rider.rotation.x = -0.30
		for frame in 14: fixture.rig.animate(1.0 / 60.0, state)
		var palm: Vector3 = fixture.rig._arms[0].hand.to_global(PALM)
		check.call(palm.distance_to(fixture.board.to_global(grab_definition.grab_target)) < 0.025,
			"authentic pose: fresh airborne Melon overrides released tow wrist and palm orientation yaw=" + str(yaw))
		print("AUTHENTIC_POSE skitch yaw=%.2f palm_error=%.4f release_step=%.3f" % [yaw, error, max_step])
		await _dispose(tree, fixture.root)


static func _ordinary_foot_support(tree: SceneTree, check: Callable) -> void:
	# Native finite-floor presentation fixtures. They do not admit or score a
	# trick; independent Main input tests exercise the same real route.
	for drag: bool in [false, true]:
		var fixture := await _fixture(tree, 0.0, 0.0, Vector3.UP, true)
		var bank := StaticBody3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(PackedVector3Array([Vector3(-4, 1, -4), Vector3(4, 1, -4), Vector3(-4, 0, 0),
			Vector3(4, 1, -4), Vector3(4, 0, 0), Vector3(-4, 0, 0)]))
		var collision := CollisionShape3D.new()
		collision.shape = shape
		bank.add_child(collision)
		fixture.root.add_child(bank)
		fixture.body.position = Vector3(0, 0.030, -0.10)
		fixture.visual.basis = Basis(Quaternion(Vector3.UP, Vector3(0, 1, 0.25).normalized()))
		# Ordinary controller presentation leans the rider forward by 0.10 rad.
		fixture.rider.rotation.x = -0.10
		await tree.physics_frame
		await tree.process_frame
		var state := _neutral()
		state.speed = 6.0
		state.push = not drag
		state.brake = drag
		var minimum := INF
		var recovery := 0.0
		for frame in 65:
			fixture.rig.animate(1.0 / 60.0, state)
			var foot: Node3D = fixture.rig._legs[1].foot
			for mesh: MeshInstance3D in [foot.get_node("Cupsole"), foot.get_node("CanvasUpper")]:
				var unique: Dictionary = {}
				for point: Vector3 in mesh.mesh.get_faces(): unique[point] = true
				for point: Vector3 in unique:
					var at := mesh.to_global(point)
					var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.4, at - Vector3.UP * 0.8, 9)
					query.exclude = [fixture.body.get_rid()]
					var hit: Dictionary = fixture.root.get_world_3d().direct_space_state.intersect_ray(query)
					if not hit.is_empty(): minimum = minf(minimum, at.y - float(hit.position.y))
			var sole: Vector3 = foot.to_global(SOLE)
			if fixture.rig._push_phase > 0.65:
				recovery = maxf(recovery, sole.y - fixture.root.global_position.y)
		var sole: Vector3 = fixture.rig._legs[1].foot.to_global(SOLE)
		check.call(minimum > -0.0015 and _max_stretch(fixture.rig) <= 1.12,
			"authentic push: complete shoe clears actual finite bank toe and adjoining flat floor drag=%s" % drag)
		check.call((absf(sole.y - fixture.root.global_position.y) < 0.001 if drag else recovery > 0.10),
			"authentic push: native drag plants within 1mm while push return retains its lifted arc drag=%s" % drag)
		print("AUTHENTIC_PUSH drag=%s whole=%.6f recovery=%.4f stretch=%.6f" % [drag, minimum, recovery, _max_stretch(fixture.rig)])
		await _dispose(tree, fixture.root)
	# Steel-only and absent support must not become an imaginary broad floor.
	for layer: int in [0, 2]:
		var fixture := await _fixture(tree, 0.0, 0.0, Vector3.UP, true)
		var floor: StaticBody3D = fixture.root.get_child(0)
		floor.collision_layer = layer
		await tree.physics_frame
		await tree.process_frame
		check.call(fixture.rig._native_foot_ground(fixture.body.global_position).is_empty(),
			"authentic push: absent ground or layer2 steel cannot create a foot plant layer=%d" % layer)
		await _dispose(tree, fixture.root)


static func _recorded_drag_reach(tree: SceneTree, check: Callable) -> void:
	# Actual Main brake-frame data from the independent beginner-circuit trace:
	# right calf previously scaled 1.266663 for a 0.948m hip-to-ankle distance.
	var fixture := await _fixture(tree, atan2(-0.205270, -0.978702), 0.0, Vector3.UP, true)
	fixture.root.position = Vector3(-200.0731, 13.0, -176.2168)
	fixture.body.position.y = 0.01305
	fixture.visual.position.y = -0.00505
	fixture.rider.rotation.x = -0.10
	fixture.rig._push_blend = 0.181164142798062
	fixture.rig._brake_blend = 0.862733098363659
	fixture.rig._push_phase = 0.454624990001322
	await tree.physics_frame
	await tree.process_frame
	var state := _neutral()
	state.speed = 5.162
	state.brake = true
	fixture.rig.animate(0.0, state)
	var rear: Vector3 = fixture.rig._legs[1].foot.to_global(SOLE)
	check.call(_max_stretch(fixture.rig) <= 1.12 and absf(rear.y - 13.0) < 0.001
		and _grip_distance(fixture, fixture.rig._legs[0].foot.to_global(SOLE)) < 0.001
		and fixture.rig._drag_crouch > 0.10 and fixture.rig._drag_crouch < 0.18,
		"authentic push: recorded genuine long-calf brake frame fits both actual contacts by lowering the common pelvis")
	var previous := _markers(fixture.rig)
	var movement := 0.0
	state.brake = false
	for frame in 65:
		fixture.rig.animate(1.0 / 60.0, state)
		var current := _markers(fixture.rig)
		movement = maxf(movement, _marker_delta(previous, current))
		previous = current
	check.call(movement < 0.22 and fixture.rig._drag_crouch == 0.0 and _feet_error(fixture) < 0.001,
		"authentic push: recorded native brake crouch returns smoothly to the unchanged neutral stance")
	await _dispose(tree, fixture.root)


static func _helper_keeps_deck_contact(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 0.0, 0.0, Vector3.UP, true)
	var state := _neutral()
	state.merge({"transition_active": true, "push": true, "brake": true, "speed": 6.0}, true)
	_settle(fixture.rig, state)
	check.call(_feet_error(fixture) < 0.001 and fixture.rig._push_blend == 0.0
		and fixture.rig._brake_blend == 0.0 and fixture.rig._drag_crouch == 0.0,
		"authentic pump: actual helper state keeps both soles on the deck and rejects ordinary kick/drag ground solving")
	await _dispose(tree, fixture.root)


static func _neutral() -> Dictionary:
	return {"airborne": false, "grab": false, "flip": false, "manual": false,
		"grind": false, "speed": 2.0, "push": false, "brake": false}


static func _settle(rig: RefCounted, state: Dictionary) -> void:
	for frame in 60: rig.animate(1.0 / 60.0, state)


static func _feet_error(fixture: Dictionary) -> float:
	var error := 0.0
	for leg: Dictionary in fixture.rig._legs:
		error = maxf(error, _grip_distance(fixture, leg.foot.to_global(SOLE)))
	return error


static func _markers(rig: RefCounted) -> Array[Vector3]:
	var points: Array[Vector3] = [rig._head.global_position]
	for leg: Dictionary in rig._legs: points.append(leg.foot.global_position)
	for arm: Dictionary in rig._arms: points.append(arm.hand.global_position)
	return points


static func _marker_delta(before: Array[Vector3], after: Array[Vector3]) -> float:
	var result := 0.0
	for index in before.size(): result = maxf(result, before[index].distance_to(after[index]))
	return result


static func _finite(rig: RefCounted) -> bool:
	var skeleton: Skeleton3D = rig._garments.skeleton
	for index in skeleton.get_bone_count():
		var pose := skeleton.get_bone_pose(index)
		if not pose.origin.is_finite() or not pose.basis.is_finite(): return false
	return true


static func _max_stretch(rig: RefCounted) -> float:
	var skeleton: Skeleton3D = rig._garments.skeleton
	var result := 0.0
	for index in skeleton.get_bone_count():
		if skeleton.get_bone_name(index) in ["hips", "torso"]: continue
		result = maxf(result, skeleton.get_bone_pose_scale(index).y)
	return result


static func _sole_plane_error(foot: Node3D, at: Vector3, normal: Vector3) -> float:
	var sole: MeshInstance3D = foot.get_node("Cupsole")
	var result := 0.0
	for surface in sole.mesh.get_surface_count():
		var arrays := sole.mesh.surface_get_arrays(surface)
		for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			if absf(point.y - SOLE.y) < 0.0001:
				result = maxf(result, absf((sole.to_global(point) - at).dot(normal)))
	return result


static func _minimum_plane_distance(mesh: MeshInstance3D, at: Vector3, normal: Vector3) -> float:
	var result := INF
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			result = minf(result, (mesh.to_global(point) - at).dot(normal))
	return result


static func _nearest_vertex(mesh: MeshInstance3D, target: Vector3) -> float:
	var result := INF
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			result = minf(result, mesh.to_global(point).distance_to(target))
	return result


static func _dispose(tree: SceneTree, node: Node) -> void:
	node.queue_free()
	await tree.process_frame
