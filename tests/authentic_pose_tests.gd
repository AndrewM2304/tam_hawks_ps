extends RefCounted
## Contact/continuity proof for authored setup and recovery animation. These
## fixtures inspect the actual rig meshes; they do not admit or score a trick.

const Visual = preload("res://game/player/skater_visual.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const SOLE := Vector3(0, -0.0605, 0)
const PALM := Vector3(0, -0.075, -0.015)
const STEP := Vector3(-0.34, 0, -0.255)
const BONELESS_EDGE := Vector3(0.128, 0.022, 0.02)


static func run(tree: SceneTree, check: Callable) -> void:
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
		var grip: MeshInstance3D = fixture.board.get_node("Griptape")
		var faces: PackedVector3Array = grip.mesh.get_faces()
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
		var bolt_count := 0
		var bolt_gap := 0.0
		for child: Node in fixture.board.get_children():
			if not child is MeshInstance3D or not child.mesh is SphereMesh: continue
			if not child.scale.is_equal_approx(Vector3(0.006, 0.002, 0.006)): continue
			bolt_count += 1
			var cap: Vector3 = child.position + Vector3.UP * 0.002
			bolt_gap = maxf(bolt_gap, absf(cap.y - _triangle_height(faces, cap)))
		check.call(bolt_count == 8 and bolt_gap < 0.0002,
			"authentic board: all eight countersunk bolt caps finish flush with the real grip rest=%.2f" % rest)
		var wood: MeshInstance3D = fixture.board.get_node("CurvedMapleDeck")
		var wood_faces: PackedVector3Array = wood.mesh.get_faces()
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
			var distance := preload("res://tests/full_repertoire_tests.gd")._surface_distance(
				hand.to_global(PALM), [grip, wood])
			check.call(not inside_wood and distance < 0.025 and _feet_error(fixture) < 0.001
				and _max_stretch(fixture.rig) <= 1.12,
				"authentic board: grab palm wraps the rendered surface while caught soles stay clear %s rest=%.2f" % [id, rest])
		print("AUTHENTIC_BOARD rest=%.2f caught_sole=%.6f complete_shoe=%.6f bolt_gap=%.6f" % [rest, sole_min, complete_min, bolt_gap])
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
	var grip: MeshInstance3D = fixture.board.get_node("Griptape")
	var local := grip.to_local(contact)
	return absf(local.y - _triangle_height(grip.mesh.get_faces(), local))


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
	state.merge({"bail_active": true, "bail_phase": 0.0,
		"bail_ground_point": fixture.body.global_position, "bail_normal": Vector3.UP}, true)
	for frame in 91:
		state.bail_phase = float(frame) / 90.0
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
		"authentic pose: bail visibly falls and rolls below the riding head height")
	check.call(finite and stretch <= 1.12 and max_jump < 0.22,
		"authentic pose: fall slide and get-up stay finite without limb stretch or pose teleports")
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
		normal: Vector3 = Vector3.UP) -> Dictionary:
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
	var body := Node3D.new()
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
					for child: Node in fixture.board.get_children():
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
						real_grip_error = maxf(real_grip_error, _nearest_vertex(fixture.board.get_node("Griptape"), target))
						check.call(foot.global_basis.y.dot(Vector3.UP) > 0.998,
							"authentic pose: Pogo shoe stays horizontal on actual rear wheel rest=%.2f side=%.0f" % [rest, side])
					check.call(sole_error < 0.005 and palm_error < 0.025 and real_grip_error < 0.005,
						"authentic pose: Pogo soles and anatomical palms meet actual wheel and nose geometry rest=%.2f" % rest)
					print("AUTHENTIC_MANUAL pogo rest=%.2f sole=%.4f palm=%.4f grip_vertex=%.4f" % [rest, sole_error, palm_error, real_grip_error])
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
			for child: Node in fixture.board.get_children():
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
			var grip_faces: PackedVector3Array = fixture.board.get_node("Griptape").mesh.get_faces()
			var lift := free.y - _triangle_height(grip_faces, free)
			check.call(_grip_distance(fixture, fixture.rig._legs[planted].foot.to_global(SOLE)) < 0.001
				and lift > 0.15 and _max_stretch(fixture.rig) <= 1.12,
				"authentic manual: %s loads the %s foot and raises its partner rest=%.2f" % [id, "rear" if planted == 1 else "front", rest])
		state.manual_definition = Catalog.definition("hang_ten")
		for frame in 90: _manual_frame(fixture, state)
		var tape_faces: PackedVector3Array = fixture.board.get_node("Griptape").mesh.get_faces()
		var wood_faces: PackedVector3Array = fixture.board.get_node("CurvedMapleDeck").mesh.get_faces()
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
		var bearing := Vector3(0, -0.020, 0)
		if id == "nose_stall": bearing = Vector3(0, -0.104, -0.255)
		elif id == "tail_stall": bearing = Vector3(0, -0.104, 0.255)
		elif id == "axle_stall": bearing = Vector3(0, -0.104, 0)
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
	var ordinary: Transform3D = fixture.rider.transform
	fixture.body.position.y = 2.0
	fixture.visual.rotation = Vector3(0.9, 0.5, 0.35)
	fixture.rider.position.y = -0.17
	fixture.rider.rotation.x = -0.30
	fixture.board.rotation.z = PI
	var state := _neutral()
	state.merge({"airborne": true, "flip": true, "flip_progress": 0.5}, true)
	_settle(fixture.rig, state)
	var before := _markers(fixture.rig)
	var deck_before: Transform3D = fixture.board.global_transform
	fixture.rig.begin_bail()
	# Model controller-owned parent/state changes after the pre-clear snapshot.
	fixture.visual.rotation = Vector3.ZERO
	fixture.board.rotation = Vector3.ZERO
	fixture.rider.position.y = 0.0
	fixture.rider.rotation.x = 0.0
	state.merge({"bail_active": true, "bail_phase": 0.0,
		"bail_ground_point": fixture.root.global_position, "bail_normal": Vector3.UP,
		"bail_recovery_transform": ordinary}, true)
	fixture.rig.animate(1.0 / 60.0, state)
	check.call(_marker_delta(before, _markers(fixture.rig)) < 0.005
		and fixture.board.global_position.distance_to(deck_before.origin) < 0.005,
		"authentic pose: pre-clear bail snapshot preserves actual interrupted world pose")
	state.bail_phase = 0.30
	fixture.rig.animate(1.0 / 60.0, state)
	check.call(fixture.rig._head.global_position.y > fixture.root.global_position.y + 1.5,
		"authentic pose: a distant floor ray cannot teleport airborne recovery below the native body")
	state.bail_phase = 1.0
	fixture.rig.animate(1.0 / 60.0, state)
	check.call(fixture.rider.transform.origin.distance_to(ordinary.origin) < 0.005
		and fixture.rider.basis.get_rotation_quaternion().angle_to(ordinary.basis.get_rotation_quaternion()) < 0.01,
		"authentic pose: recovery removes interrupted grab offsets before controller reset")
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
