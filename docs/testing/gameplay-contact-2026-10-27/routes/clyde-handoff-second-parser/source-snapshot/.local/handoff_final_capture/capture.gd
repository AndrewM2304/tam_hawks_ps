extends SceneTree
## One static diagnostic immediately after the actual Clyde ramp-air handoff.
## No actor, model, velocity or camera assignment follows the declared start.
const Main = preload("res://game/main.gd")
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Clyde = preload("res://tests/pt24_clyde_flagship_tests.gd")
const Density = preload("res://tests/full_level_density_tests.gd")
const Body = preload("res://tests/skater_body_attachment_tests.gd")
const Board = preload("res://tests/board_geometry_tests_support.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const SIZE := Vector2i(960, 640)
var output: String
var errors: Array[String] = []
var game: Node3D
var counter: NativeCounter
var capturing := false
var route_checks: Array[Dictionary] = []
var frozen_driver_waiters := 0
var suspended_driver_connections: Array[Dictionary] = []
class NativeCounter extends Node:
	var ticks := 0
	func _physics_process(_delta: float) -> void: ticks += 1

class HandoffObserver extends Node:
	var host: SceneTree
	var game: Node
	var previous: Dictionary = {}
	func _ready() -> void: process_priority = 101
	func _process(_delta: float) -> void:
		if host.capturing or not is_instance_valid(game): return
		var current: Dictionary = host._sample(game.skater)
		var at: Vector3 = current.at
		if not previous.is_empty() and previous.ramp_air and not current.ramp_air \
			and current.airborne and not current.feature_active and current.feature_state == "idle" \
			and current.force_air and at.x >= -12.0 and at.x <= -8.0 \
			and at.z >= 128.0 and at.z <= 131.0 and at.y >= 3.0 and at.y <= 5.5:
			set_process(false)
			host._handoff_detected(previous, current)
		previous = current

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
	# The original module owns its original declared starts and every later
	# input. Its bank-return loop has no observer callback, so a passive final
	# presentation node detects the actual state transition without adapting it.
	var observer := HandoffObserver.new()
	observer.host = self
	observer.game = game
	root.add_child(observer)
	_drive.call_deferred()

func _drive() -> void:
	await Clyde.run(self, game, _route_check)
	if not capturing:
		errors.append("Original Clyde run completed without the specified actual bowl handoff")
		_finish({"handoff_detected": false, "route_checks": route_checks})

func _route_check(ok: bool, label: String) -> void:
	route_checks.append({"ok": ok, "label": label})
	if not ok: errors.append("Original route assertion before diagnostic stop: " + label)

func _sample(rider: CharacterBody3D) -> Dictionary:
	var yaw: float = rider._spin_angle + rider._stance_angle + rider._air_grind_yaw \
		- PI * (rider._revert_pose_remaining / rider.REVERT_DURATION)
	var base: Basis = (rider._visual.basis * Basis(Vector3.UP, -yaw)).orthonormalized()
	return {"at": rider.global_position, "velocity": rider.velocity,
		"native_frame": Engine.get_physics_frames(), "actor_physics_frame": rider.last_physics_frame,
		"process_frame": Engine.get_process_frames(), "ramp_air": rider._ramp_air,
		"airborne": rider.airborne, "feature_active": rider._feature_transition.active,
		"feature_state": rider._feature_transition.state, "force_air": rider._force_air_tick,
		"visual_yaw": yaw, "actual_local_pre_yaw_base": base,
		"actual_world_pre_yaw_base": rider.global_basis * base,
		"native_pose": _pose_json(_pose(rider, false))}

func _handoff_detected(previous: Dictionary, current: Dictionary) -> void:
	if capturing: return
	capturing = true
	var rider: CharacterBody3D = game.skater
	var local_angle: float = _normalized_angle(previous.actual_local_pre_yaw_base, current.actual_local_pre_yaw_base)
	var world_angle: float = _normalized_angle(previous.actual_world_pre_yaw_base, current.actual_world_pre_yaw_base)
	var native_step: int = int(current.native_frame) - int(previous.native_frame)
	var actor_step: int = int(current.actor_physics_frame) - int(previous.actor_physics_frame)
	if native_step != 1 or actor_step != 1:
		errors.append("Handoff observation skipped an actual native physics step")
	if local_angle > .075: errors.append("Actual first ordinary-air base turn exceeds the original .075 rad step")
	var details := _contact_state(rider)
	details.merge({"stage": "actual_clyde_ramp_air_to_ordinary_air", "handoff_detected": true,
		"previous": previous, "after": current, "relative_local_base_angle_radians": local_angle,
		"relative_world_base_angle_radians": world_angle,
		"actual_native_step": native_step, "actual_actor_physics_step": actor_step,
		"physical_step_m": Vector3(current.at).distance_to(previous.at), "route_checks_before_stop": route_checks,
		"original_route_completed": false})
	# End this static diagnostic at its earned frame. The original controller
	# is suspended on SceneTree.physics_frame, which still emits when paused.
	# Disconnect only those suspended scheduler waiters before the two draws;
	# no camera/pose/velocity state or production predicate is assigned.
	for connection: Dictionary in physics_frame.get_connections():
		var callback: Callable = connection.callable
		suspended_driver_connections.append(connection)
		physics_frame.disconnect(callback)
		frozen_driver_waiters += 1
	if frozen_driver_waiters < 1: errors.append("No suspended native controller waiter was frozen")
	details["frozen_physics_frame_waiters"] = frozen_driver_waiters
	game.process_mode = Node.PROCESS_MODE_DISABLED
	paused = true
	_capture.call_deferred(rider, details)


func _normalized_angle(a: Basis, b: Basis) -> float:
	# Godot stores the native rotations in float32; normalize their quaternion
	# dot in GDScript double precision before acos. The original .075 bound is
	# unchanged. Avoid float32 acos cancellation turning .0749995 into .0750002.
	var qa: Quaternion = a.get_rotation_quaternion()
	var qb: Quaternion = b.get_rotation_quaternion()
	var dot: float = float(qa.x)*float(qb.x) + float(qa.y)*float(qb.y) \
		+ float(qa.z)*float(qb.z) + float(qa.w)*float(qb.w)
	var an: float = float(qa.x)*float(qa.x) + float(qa.y)*float(qa.y) \
		+ float(qa.z)*float(qa.z) + float(qa.w)*float(qa.w)
	var bn: float = float(qb.x)*float(qb.x) + float(qb.y)*float(qb.y) \
		+ float(qb.z)*float(qb.z) + float(qb.w)*float(qb.w)
	return 2.0*acos(clampf(absf(dot)/sqrt(an*bn), 0.0, 1.0))

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
	var first_draw_counter := Engine.get_frames_drawn()
	await RenderingServer.frame_post_draw
	var second_draw_counter := Engine.get_frames_drawn()
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
	if not clear: errors.append("Original strict whole-rider native chase check failed at the real post-handoff pose")
	var picture := root.get_texture().get_image()
	var file := "ordinary-clyde-post-handoff.png"
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

func _finish(details: Dictionary) -> void:
	var report := {"images": [details] if details.has("file") else [], "details": details, "errors": errors,
		"method": "Current production Main/Skater and unchanged original Clyde.run, with only its declared starts and normal input. Passive priority101 presentation observer selects the actual ramp-air true to false / ordinary airborne / Feature idle / force-air handoff in the specified bowl region. Previous actual pre-yaw base frame and one-native-step after frame retained. Rendering disabled only during native warmup. At diagnostic stop, suspended controller waiters and production processing are frozen; interpolation reset for two natural static draws. No assigned post-start actor/model/physics/camera pose.",
		"limits": "One static post-handoff frame and adjacent actual base/native-step witnesses; the diagnostic stops at capture and does not certify full route completion, continuous motion, FPS, Mac/controller or human feel."}
	FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	Driver._release()
	print("CLYDE_HANDOFF_STATIC ", JSON.stringify(details))
	print("RESULT: ", 1 if errors.is_empty() else 0, " passed, ", errors.size(), " failed")
	for failure: String in errors: push_error(failure)
	# Draw evidence is already saved. Restore the original suspended awaiters
	# immediately before quitting so SceneTree owns their normal cleanup;
	# no further native update or route step is requested.
	for connection: Dictionary in suspended_driver_connections:
		var callback: Callable = connection.callable
		physics_frame.connect(callback, int(connection.flags))
	suspended_driver_connections.clear()
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
