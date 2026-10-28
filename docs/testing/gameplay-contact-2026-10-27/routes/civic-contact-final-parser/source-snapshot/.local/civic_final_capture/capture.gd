extends SceneTree
## One static diagnostic of an earned Civic contact, using production Main/Skater.
## No actor, model, velocity or camera assignment follows the declared start.
const Main = preload("res://game/main.gd")
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Density = preload("res://tests/full_level_density_tests.gd")
const Body = preload("res://tests/skater_body_attachment_tests.gd")
const Board = preload("res://tests/board_geometry_tests_support.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const SIZE := Vector2i(960, 640)
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
	# Exact declared start from the original C04 Civic combo; all later motion
	# comes from the same held Push + Grind used by that ordinary-input route.
	await Driver._reset(self, game, Vector3(-38.5, 6.08, -124.8), PI)
	var rider: CharacterBody3D = game.skater
	var signals: Array[String] = []
	rider.trick_performed.connect(func(label: String, _points: int) -> void: signals.append(label))
	Input.action_press("push")
	Input.action_press("grind")
	var reached := false
	var updates := 0
	var stage := ""
	for tick: int in 420:
		await Driver._frames(self, 1)
		updates += 1
		# process_frame fires before production presentation; fence its current
		# update without requesting another physics step or editing a pose.
		var native_tick := Engine.get_physics_frames()
		var process_tick := Engine.get_process_frames()
		await create_timer(0.0, true).timeout
		if native_tick != Engine.get_physics_frames() or process_tick != Engine.get_process_frames():
			errors.append("Normal presentation fence advanced a logical frame")
			break
		if rider.bailing:
			errors.append("Native input approach bailed: " + rider.bail_reason)
			break
		if rider.lip_active:
			reached = true
			stage = "native_civic_coping_lip"
			break
		if rider._feature_transition.active and rider._feature_transition._theta >= deg_to_rad(85.0):
			reached = true
			stage = "native_civic_85_degree_ascent"
			break
	if not reached:
		errors.append("Original mapped Civic inputs did not reach 85 degrees or the native lip")
		_finish({"reached": false, "native_updates": updates, "signals": signals})
		return
	var details := _contact_state(rider)
	details.merge({"reached": reached, "stage": stage, "native_updates": updates, "signals": signals})
	await _capture(rider, details)

func _capture(rider: CharacterBody3D, details: Dictionary) -> void:
	var camera: Camera3D = rider._camera
	var before_reset := _pose(rider, false)
	var camera_before: Transform3D = camera.global_transform
	# Static diagnostic only: stop processing after actual normal presentation,
	# reset interpolation to that earned pose, then request two completed draws.
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
	await RenderingServer.frame_post_draw
	var physical := _pose(rider, false)
	var drawn := _pose(rider, true)
	var matches := _same_pose(before_reset, physical_before) and _same_pose(physical_before, physical) \
		and _same_pose(physical, drawn) and tick == counter.ticks \
		and camera_before.is_equal_approx(camera.global_transform) \
		and camera.global_transform.is_equal_approx(camera.get_global_transform_interpolated())
	if not matches: errors.append("Frozen earned native/draw nine-node or chase witness changed")
	var cloth: Dictionary = Body._sample(rider, Body._prepare(rider._visual_rig))
	var grip := 0.0
	for leg: Dictionary in rider._visual_rig._legs:
		grip = maxf(grip, Board.grip_distance(rider._visual_rig, leg.foot.to_global(Authentic.SOLE)))
	if not cloth.finite or cloth.seam >= .08 or cloth.joint_gap >= .06 or cloth.neck_gap >= .05 or grip >= .004:
		errors.append("Actual connected clothing or shoe/deck contact failed")
	var clear: bool = Density._camera_clear(game)
	if not clear: errors.append("Original strict whole-rider native chase check failed at earned contact")
	var picture := root.get_texture().get_image()
	var file := "ordinary-civic-coping-contact.png"
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

func _finish(details: Dictionary) -> void:
	var report := {"images": [details] if details.has("file") else [], "details": details, "errors": errors,
		"method": "Current production Main and Skater; exact Civic combo start, then ordinary held Push + Grind until actual 85 degree ascent or lip. Rendering disabled only during native warmup. Normal presentation fenced; game paused and interpolation reset for two completed static draws. No assigned post-start actor/model/physics/camera pose.",
		"limits": "One static diagnostic frame and native/drawn pose witness; not FPS, moving presentation, Mac/controller or human feel acceptance."}
	FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	Driver._release()
	print("CIVIC_STATIC_CONTACT ", JSON.stringify(details))
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
