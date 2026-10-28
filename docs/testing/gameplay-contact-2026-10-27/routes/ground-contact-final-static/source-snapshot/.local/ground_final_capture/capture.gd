extends SceneTree
## One static diagnostic of the finite arrival-bank tyre fit, using production Main/Skater.
## No actor, model, velocity or camera assignment follows the declared start.
const Main = preload("res://game/main.gd")
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Density = preload("res://tests/full_level_density_tests.gd")
const Body = preload("res://tests/skater_body_attachment_tests.gd")
const Board = preload("res://tests/board_geometry_tests_support.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const SIZE := Vector2i(960, 640)
const START := Vector3(-199.9204, 13.01199, -176.7438)
const HEADING := 0.0
const SETTLE_TICKS := 30
var output: String
var errors: Array[String] = []
var game: Node3D
var counter: NativeCounter
class NativeCounter extends Node:
	var ticks := 0
	func _physics_process(_delta: float) -> void: ticks += 1

func _initialize() -> void:
	RenderingServer.set_render_loop_enabled(false)
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().size() != 1:
		quit(2)
		return
	output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size = SIZE
	root.content_scale_size = SIZE
	counter = NativeCounter.new()
	counter.process_physics_priority = 100
	root.add_child(counter)
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	await Driver._frames(self, 3)
	# One declared native initial condition. No position, velocity, heading,
	# model or camera correction follows this restart; inputs stay released.
	Driver._release()
	var rider: CharacterBody3D = game.skater
	rider.spawn_position = START
	game.start_mode(true)
	rider.rotation.y = HEADING
	var signals: Array[String] = []
	rider.trick_performed.connect(func(label: String, _points: int) -> void: signals.append(label))
	await Driver._frames(self, SETTLE_TICKS)
	var native_tick := Engine.get_physics_frames()
	var process_tick := Engine.get_process_frames()
	await create_timer(0.0, true).timeout
	if native_tick != Engine.get_physics_frames() or process_tick != Engine.get_process_frames():
		errors.append("Normal presentation fence advanced a logical frame")
	var details := _contact_state(rider)
	var ground_witness := _finite_ground_witness(rider)
	details.merge({"declared_start": _v(START), "declared_heading": HEADING,
		"stage": "native_beginner_arrival_bank_finite_tyre_rim", "native_updates": SETTLE_TICKS,
		"signals": signals, "finite_ground_witness": ground_witness})
	if rider.airborne or not rider.is_on_floor() or rider.bailing or rider.transition_active \
		or rider.manual_active or rider.lip_active or not signals.is_empty() \
		or game.score.total_score != 0 or game.score.get_combo_value() != 0:
		errors.append("Neutral native grounded fixture changed mode, bailed or manufactured score")
	await _capture(rider, details)

func _capture(rider: CharacterBody3D, details: Dictionary) -> void:
	var camera: Camera3D = rider._camera
	var before_reset := _pose(rider, false)
	var camera_before: Transform3D = camera.global_transform
	# Static diagnostic only: stop processing after actual normal presentation,
	# reset interpolation to that native pose, then request two completed draws.
	game.process_mode = Node.PROCESS_MODE_DISABLED
	paused = true
	for node: Node3D in _pose_nodes(rider): node.get_global_transform_interpolated()
	rider.reset_physics_interpolation()
	camera.get_global_transform_interpolated()
	camera.reset_physics_interpolation()
	var tick: int = counter.ticks
	var native_frame := Engine.get_physics_frames()
	var physical_before := _pose(rider, false)
	RenderingServer.set_render_loop_enabled(true)
	await RenderingServer.frame_post_draw
	var first_draw_counter := Engine.get_frames_drawn()
	await RenderingServer.frame_post_draw
	var second_draw_counter := Engine.get_frames_drawn()
	var physical := _pose(rider, false)
	var drawn := _pose(rider, true)
	var matches := _same_pose(before_reset, physical_before) and _same_pose(physical_before, physical) \
		and _same_pose(physical, drawn) and tick == counter.ticks \
		and camera_before.is_equal_approx(camera.global_transform) \
		and camera.global_transform.is_equal_approx(camera.get_global_transform_interpolated())
	if not matches: errors.append("Frozen grounded native/draw nine-node or chase witness changed")
	var cloth: Dictionary = Body._sample(rider, Body._prepare(rider._visual_rig))
	var grip := 0.0
	for leg: Dictionary in rider._visual_rig._legs:
		grip = maxf(grip, Board.grip_distance(rider._visual_rig, leg.foot.to_global(Authentic.SOLE)))
	if not cloth.finite or cloth.seam >= .08 or cloth.joint_gap >= .06 or cloth.neck_gap >= .05 or grip >= .004:
		errors.append("Actual connected clothing or shoe/deck contact failed")
	var clear: bool = Density._camera_clear(game)
	if not clear: errors.append("Original strict whole-rider native chase check failed at native grounded contact")
	var picture := root.get_texture().get_image()
	var file := "ordinary-ground-finite-rim-contact.png"
	if picture.get_size() != SIZE or picture.save_png(output.path_join(file)) != OK:
		errors.append("Completed native PNG write failed")
	details.merge({"file": file, "sha256": FileAccess.get_sha256(output.path_join(file)),
		"size": [SIZE.x, SIZE.y], "completed_draw_pose_matches": matches,
		"native_pose": _pose_json(physical), "draw_pose": _pose_json(drawn),
		"pose_nodes": ["actor", "visual", "board", "rider", "head", "front_foot", "rear_foot", "left_hand", "right_hand"],
		"camera_policy": "unchanged ordinary production chase", "camera": str(camera.global_transform),
		"strict_native_chase_clear": clear, "clothing_seam": cloth.seam, "joint_gap": cloth.joint_gap,
		"neck_gap": cloth.neck_gap, "shoe_deck_distance": grip,
		"observed_engine_physics_frame": Engine.get_physics_frames(),
		"frozen_actor_tick_before": tick, "frozen_actor_tick_after": counter.ticks,
		"engine_physics_frame_before_static_draws": native_frame,
		"observed_engine_draw_frame": Engine.get_frames_drawn(),
		"completed_draw_signal_counters": [first_draw_counter, second_draw_counter],
		"observed_engine_process_frame": Engine.get_process_frames(),
		"interpolation_fraction": Engine.get_physics_interpolation_fraction()})
	_finish(details)

func _contact_state(rider: CharacterBody3D) -> Dictionary:
	var feature: Node3D = rider._feature_transition.feature
	return {"actor_position": _v(rider.global_position), "velocity": _v(rider.velocity),
		"speed": rider.speed, "airborne": rider.airborne, "bailing": rider.bailing,
		"feature": str(feature.get_path()) if is_instance_valid(feature) else "",
		"feature_state": rider._feature_transition.state, "feature_theta_degrees": rad_to_deg(rider._feature_transition._theta),
		"lip_active": rider.lip_active, "lip_id": rider.lip_id,
		"production_actor_script": rider.get_script().resource_path,
		"ordinary_trial_content": game.world.get_meta("pt24_design_preview", false)}

func _finite_ground_witness(rider: CharacterBody3D) -> Dictionary:
	var bank := game.world.get_node("OutdoorRoutes/KelvingroveSunkenSkatepark/BeginnerArrivalBank") as StaticBody3D
	var collision := bank.get_child(0) as CollisionShape3D
	var top_vertices: Array = []
	var native_top_valid := collision.shape is ConcavePolygonShape3D
	if native_top_valid:
		var faces: PackedVector3Array = collision.shape.get_faces()
		for index: int in range(0, faces.size(), 3):
			var a: Vector3 = collision.to_global(faces[index])
			var b: Vector3 = collision.to_global(faces[index+1])
			var c: Vector3 = collision.to_global(faces[index+2])
			var normal := (b-a).cross(c-a).normalized()
			if absf(normal.y) < .5: continue
			for point: Vector3 in [a, b, c]:
				native_top_valid = native_top_valid and absf(point.y-_bank_y(point.x)) < .0001 \
					and point.x >= -200.0001 and point.x <= -189.9999 \
					and point.z >= -181.0001 and point.z <= -176.9999
				top_vertices.append(_v(point))
	native_top_valid = native_top_valid and top_vertices.size() == 6
	if not native_top_valid: errors.append("Actual finite native BeginnerArrivalBank top does not match its authored plane and bounds")
	var space: PhysicsDirectSpaceState3D = rider.get_world_3d().direct_space_state
	var wheels: Array[Dictionary] = []
	var finite_rim_wheels := 0
	var lower_rim_vertices := 0
	var native_rim_hits := 0
	var tyre_contacts: Array[Dictionary] = []
	var geometry: Dictionary = rider._visual_rig.board_contact_geometry()
	for index: int in geometry.wheels.size():
		var wheel: Dictionary = geometry.wheels[index]
		var center: Vector3 = rider._board_visual.to_global(wheel.center)
		var closest := Vector3.INF
		var lowest := INF
		var inside_vertices := 0
		for vertex: Vector3 in wheel.points:
			var point: Vector3 = rider._board_visual.to_global(vertex)
			if point.x < -200.0 or point.x > -190.0 or point.z < -181.0 or point.z > -177.0: continue
			inside_vertices += 1
			var gap: float = point.y-_bank_y(point.x)
			if gap < lowest:
				lowest = gap
				closest = point
		var support: Dictionary = {}
		if inside_vertices > 0 and center.z > -177.0:
			finite_rim_wheels += 1
			lower_rim_vertices += inside_vertices
			support = space.intersect_ray(PhysicsRayQueryParameters3D.create(
				closest+Vector3.UP*.15, closest-Vector3.UP*.15, 1|8, [rider.get_rid()]))
			if not support.is_empty() and support.collider == bank \
				and absf(Vector3(support.position).y-_bank_y(closest.x)) < .0001:
				native_rim_hits += 1
			if lowest < -.0001: errors.append("An actual retained tyre vertex lies below the finite bank top")
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = rider._floor_wheel_shapes[index]
		query.transform = rider._board_visual.global_transform
		query.margin = 0.0
		query.collision_mask = 1|2|8
		query.exclude = [rider.get_rid()]
		var overlaps: Array[Dictionary] = space.intersect_shape(query, 8)
		for hit: Dictionary in overlaps:
			tyre_contacts.append({"wheel": index, "body": str(hit.collider.get_path()), "shape": hit.shape, "rid": str(hit.rid)})
		wheels.append({"index": index, "center": _v(center), "center_beyond_z_edge": center.z > -177.0,
			"retained_vertices_in_finite_bank_footprint": inside_vertices, "minimum_vertical_bank_gap": lowest,
			"lowest_finite_vertex": _v(closest), "independent_native_ray": _hit(support)})
	if finite_rim_wheels < 1 or lower_rim_vertices < 1 or native_rim_hits != finite_rim_wheels:
		errors.append("Declared native fixture did not exercise a finite tyre rim across the real bank edge")
	var model_contacts: Array[Dictionary] = []
	for index: int in rider._grind_clearance._parts.size():
		var part: Dictionary = rider._grind_clearance._parts[index]
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = part.shape
		query.transform = rider._board_visual.global_transform
		query.margin = 0.0
		query.collision_mask = 1|2|8
		query.exclude = [rider.get_rid()]
		var overlaps: Array[Dictionary] = space.intersect_shape(query, 8)
		for hit: Dictionary in overlaps:
			model_contacts.append({"component": index, "body": str(hit.collider.get_path()), "shape": hit.shape, "rid": str(hit.rid)})
	if not tyre_contacts.is_empty() or not model_contacts.is_empty():
		errors.append("Actual final finite native tyre or connected model volumes overlap a solid")
	var root_support := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		rider.global_position+Vector3.UP*.2, rider.global_position-Vector3.UP*.2, 1|8, [rider.get_rid()]))
	return {"bank": str(bank.get_path()), "bank_rid": str(bank.get_rid()), "native_top_valid": native_top_valid,
		"authored_top_equation": "Y=13+.15*(X+200)", "authored_top_x": [-200, -190], "authored_top_z": [-181, -177],
		"actual_native_top_vertices": top_vertices, "finite_rim_wheels": finite_rim_wheels,
		"retained_rim_vertices_inside_finite_bank": lower_rim_vertices, "native_rim_hits": native_rim_hits,
		"wheels": wheels, "tyre_volume_overlaps": tyre_contacts, "connected_model_overlaps": model_contacts,
		"connected_model_components": rider._grind_clearance._parts.size(),
		"root_native_support": _hit(root_support), "visual_frame": str(rider._visual.global_transform),
		"board_frame": str(rider._board_visual.global_transform)}

func _bank_y(x: float) -> float: return 13.0+.15*(x+200.0)

func _hit(hit: Dictionary) -> Dictionary:
	if hit.is_empty(): return {}
	return {"body": str(hit.collider.get_path()), "point": _v(hit.position), "normal": _v(hit.normal),
		"rid": str(hit.rid), "shape": hit.shape}

func _finish(details: Dictionary) -> void:
	var report := {"images": [details] if details.has("file") else [], "details": details, "errors": errors,
		"method": "Current production Main and Skater; one declared native BeginnerArrivalBank start, heading0, all inputs released,30 native settle updates. Rendering disabled only during native warmup. Normal presentation fenced; game paused and interpolation reset for two completed static draws. No assigned post-start actor/model/physics/camera pose. Native finite bank faces, retained tyre vertices and complete model volumes independently checked; image pixels do not establish clearance.",
		"limits": "One static ground-fit diagnostic frame plus native geometry and native/drawn pose witnesses; not pixel clearance, FPS, moving presentation, Mac/controller or human feel acceptance."}
	FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	Driver._release()
	print("GROUND_STATIC_CONTACT ", JSON.stringify(details))
	print("RESULT: ", 1 if errors.is_empty() else 0, " passed, ", errors.size(), " failed")
	for failure: String in errors: push_error(failure)
	quit(0 if errors.is_empty() else 1)

func _pose_nodes(actor: CharacterBody3D) -> Array[Node3D]:
	var rig: RefCounted = actor._visual_rig
	var nodes: Array[Node3D] = [actor, actor._visual, actor._board_visual, actor._rider_visual, rig._head]
	for leg: Dictionary in rig._legs: nodes.append(leg.foot)
	for arm: Dictionary in rig._arms: nodes.append(arm.hand)
	return nodes

func _pose(actor: CharacterBody3D, interpolated: bool) -> Array[Transform3D]:
	var frames: Array[Transform3D] = []
	for node: Node3D in _pose_nodes(actor):
		frames.append(node.get_global_transform_interpolated() if interpolated else node.global_transform)
	return frames

func _same_pose(a: Array[Transform3D], b: Array[Transform3D]) -> bool:
	if a.size() != b.size(): return false
	for index: int in a.size():
		if not a[index].is_equal_approx(b[index]): return false
	return true

func _pose_json(frames: Array[Transform3D]) -> Array:
	var rows: Array = []
	for frame: Transform3D in frames:
		rows.append({"origin": _v(frame.origin), "basis_x": _v(frame.basis.x), "basis_y": _v(frame.basis.y), "basis_z": _v(frame.basis.z)})
	return rows

func _v(point: Vector3) -> Array: return [point.x, point.y, point.z]
