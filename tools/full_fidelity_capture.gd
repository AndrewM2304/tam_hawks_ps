extends SceneTree
## Continuous source-bound motion from the exact native integration tests.
## Inspection cameras are declared; genuine chase clips retain the player camera.
const Main = preload("res://game/main.gd")
const Authentic = preload("res://tests/authentic_fidelity_integration_tests.gd")
const Repertoire = preload("res://tests/full_repertoire_tests.gd")
const Density = preload("res://tests/full_level_density_tests.gd")
const CurvedVisual = preload("res://tests/curved_visual_contact_tests.gd")
const Platform = preload("res://tests/platform_contact_tests.gd")
const Remaining = preload("res://tests/remaining_feature_tests.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
var game: Node
var output := "res://.local/full-fidelity-motion"
var checks := 0
var failures := 0
var _clips: Dictionary = {}
var _timeline: Array[Dictionary] = []
var _overview_frames: Array[Dictionary] = []
var _inspection: Camera3D
var _global_step := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Full fidelity motion capture requires a rendering display.")
		quit(1)
		return
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty(): output = arguments[0]
	DirAccess.make_dir_recursive_absolute(output)
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	for frame in 40:
		await physics_frame
		await process_frame
	_inspection = Camera3D.new()
	_inspection.name = "DeclaredMotionInspectionCamera"
	_inspection.fov = 40.0
	game.add_child(_inspection)
	await _overviews()
	await Authentic.run(self, game, _check, _observe)
	await CurvedVisual.run(self, game, _check, _observe)
	await Platform.run(self, game, _check, _observe)
	await Remaining.run_main(self, game, _check, _observe)
	await Repertoire.run_playable(self, game, _check, _observe)
	await Density.run_player(self, game, _check, _observe)
	var clips: Array = _clips.values()
	_check(clips.size() >= 50, "full motion: all connected mechanics and repertoire phases produced real clips")
	var catalog_families := {}
	for family: String in ["flip", "grab", "grind", "manual", "special", "lip"]:
		catalog_families[family] = Catalog.family_ids(family)
	var report := {"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(), "platform": OS.get_name(),
		"production_main": true, "profile_writes_enabled": game.persistence_enabled,
		"checks": checks, "failures": failures, "physics_hz": 60, "motion_sample_hz": 15,
		"clips": clips, "overviews": _overview_frames, "native_timeline": _timeline, "catalog_families": catalog_families,
		"fixture_policy": "Only declared restart/initial-contact fixtures from the linked integration tests; real input/native motion thereafter. Repertoire uses explicitly declared elevated air fixtures and special unlock/meter eligibility seeds.",
		"camera_policy": "Native chase for world lines, connected surfaces and activities; authored marker-bounded contact inspection for tricks/setup/recovery; explicit cart-centred inspection for the empty parked turn.",
		"raw_frame_policy": "Lossless input PNGs remain in the ignored staging directory; published movies are fully decoded and source-frame hashes/timeline plus selected lossless review frames are retained.",
		"human_or_target_hardware_certification": false}
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("FULL FIDELITY MOTION RESULT: %d checks, %d failures, %d clips, %d native steps" % [
		checks, failures, clips.size(), _global_step])
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)

func _observe(phase: String, observed_game: Node, _phase_step: int) -> void:
	if phase.is_empty() or phase == "fixture" or _phase_step < 0: return
	# process_frame is emitted before the production Camera/HUD _process calls.
	# An always-running zero timer fences those nodes in this same logical frame,
	# including intentional pause clips, without advancing another physics step.
	var native_tick := Engine.get_physics_frames()
	var process_tick := Engine.get_process_frames()
	await create_timer(0.0, true).timeout
	_check(Engine.get_physics_frames() == native_tick and Engine.get_process_frames() == process_tick,
		"full motion observer fences production processing without advancing a logical frame")
	_global_step += 1
	var state := _snapshot(observed_game)
	_timeline.append({"phase": phase, "step": _global_step, "state": state})
	if not _clips.has(phase):
		var inspection := _uses_inspection(phase)
		var camera_label := "authored vehicle inspection" if phase == "cart_parked_turn" else ("authored contact inspection" if inspection else "production chase")
		_clips[phase] = {"id": phase, "camera": camera_label,
			"native_steps": 0, "sample_stride": 4, "frames": []}
		DirAccess.make_dir_recursive_absolute(output.path_join("frames/" + phase))
	var clip: Dictionary = _clips[phase]
	clip.native_steps += 1
	if (int(clip.native_steps) - 1) % 4 != 0: return
	var inspection: bool = _uses_inspection(phase)
	var vehicle_inspection := phase == "cart_parked_turn"
	game.hud.visible = not (inspection or vehicle_inspection)
	_inspection.fov = 48.0 if vehicle_inspection else 40.0
	if vehicle_inspection:
		var vehicle: Node3D = game.feature_hub.vehicle
		var focus: Vector3 = vehicle.global_position + Vector3.UP * 0.75
		_inspection.global_position = focus + Vector3(5, 3.2, 6).normalized() * 7.0
		_inspection.look_at(focus)
		_inspection.current = true
	elif inspection:
		var points := _markers(game)
		var minimum: Vector3 = points[0]
		var maximum: Vector3 = points[0]
		for point: Vector3 in points:
			minimum = minimum.min(point)
			maximum = maximum.max(point)
		var center := (minimum + maximum) * 0.5
		var radius := maximum.distance_to(minimum) * 0.5 + 0.20
		var distance := maxf(3.8, radius / tan(deg_to_rad(20.0)) * 1.20)
		_inspection.global_position = center + Vector3(2.4, 1.4, 2.8).normalized() * distance
		_inspection.look_at(center)
		_inspection.current = true
	else:
		game.skater._camera.current = true
	RenderingServer.force_draw(true, 1.0 / 60.0)
	var relative := "frames/%s/%05d.png" % [phase, clip.frames.size()]
	_check(root.get_texture().get_image().save_png(output.path_join(relative)) == OK,
		"full motion frame saved " + relative)
	var camera: Camera3D = root.get_camera_3d()
	clip.frames.append({"file": relative, "native_step": _global_step, "state": state,
		"camera_position": _v(camera.global_position), "camera_forward": _v(-camera.global_basis.z), "camera_fov": camera.fov})

func _snapshot(observed: Node) -> Dictionary:
	var skater: CharacterBody3D = observed.skater
	var vehicle: Node3D = observed.feature_hub.vehicle
	var vehicle_status: Dictionary = vehicle.status_snapshot()
	var actions: Dictionary = {}
	for action in InputMap.get_actions():
		var strength := Input.get_action_strength(action)
		if strength > 0.0: actions[action] = strength
	var points := _markers(observed)
	_check(skater.global_position.is_finite() and points.all(func(point: Vector3): return point.is_finite()),
		"full motion native/body coordinates remain finite")
	var encoded: Array = []
	for point: Vector3 in points: encoded.append(_v(point))
	return {"physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames(),
		"paused": observed.get_tree().paused, "run_finished": observed.run_finished,
		"vehicle_position": _v(vehicle.global_position), "vehicle_yaw": vehicle.rotation.y,
		"vehicle_velocity": _v(vehicle.travel_velocity), "vehicle_phase": vehicle_status.get("phase", ""),
		"vehicle_turn_blocked": vehicle_status.get("turn_blocked", ""),
		"position": _v(skater.global_position), "velocity": _v(skater.velocity),
		"speed": skater.speed, "airborne": skater.airborne, "on_floor": skater.is_on_floor(),
		"stance": skater.stance, "active_trick": skater.active_trick, "last_trick_id": skater.last_trick_id,
		"flip_id": skater.flip_trick_id, "grab_id": skater.grab_trick_id, "grind_id": skater.grind_trick_id,
		"manual_id": skater.manual_trick_id, "lip_id": skater.lip_trick_id,
		"grinding": skater.grinding, "manual_active": skater.manual_active, "lip_active": skater.lip_active,
		"grab_remaining": skater._grab_remaining, "grab_blend": skater._visual_rig._grab_blend,
		"flip_remaining": skater._flip_remaining, "special_remaining": skater._special_remaining,
		"setup_active": skater.setup_active, "setup_id": skater.setup_id, "setup_phase": skater.setup_phase,
		"bail_active": skater.bail_active, "bail_phase": skater.bail_phase, "skitching": skater.skitching,
		"skitch_caught": skater.skitch_caught, "recovery_fade": skater.recovery_fade,
		"wallriding": skater.wallriding, "transition_active": skater.transition_active,
		"combo": observed.score.get_combo_value(), "entries": observed.score.combo_trick_count,
		"banked": observed.score.total_score, "markers_head_board_feet_hands": encoded, "actions": actions}

func _markers(observed: Node) -> Array[Vector3]:
	var rig = observed.skater._visual_rig
	var points: Array[Vector3] = [rig._head.global_position, observed.skater._board_visual.global_position]
	for leg: Dictionary in rig._legs: points.append(leg.foot.global_position)
	for arm: Dictionary in rig._arms: points.append(arm.hand.global_position)
	return points

func _uses_inspection(phase: String) -> bool:
	return phase.begins_with("setup_") or phase.begins_with("bail_") or phase.begins_with("interrupted_") \
		or phase.begins_with("unsupported_plant_") or phase == "high_wall_bail" \
		or phase == "platform_roof_boneless" \
		or phase.begins_with("flip_") or phase.begins_with("grab_") or phase.begins_with("manual_") \
		or phase.begins_with("special_") or phase.begins_with("lip_") or phase.begins_with("grind_") \
		or phase == "triple_flip_one_entry"

func _overviews() -> void:
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	game.hud.visible = false
	for view: Array in [
		["overview_exchange", Vector3(20,32,38), Vector3(0,2,-12)],
		["overview_george", Vector3(43,32,-43), Vector3(0,4,-85)],
		["overview_central", Vector3(-52,36,54), Vector3(-90,3,1)],
		["overview_barras", Vector3(75,28,43), Vector3(113,2,-5)],
		["overview_clyde", Vector3(-22,43,151), Vector3(-55,2,100)],
		["overview_park", Vector3(-115,47,-62), Vector3(-174,10,-128)],
	]:
		_inspection.global_position = view[1]
		_inspection.look_at(view[2])
		_inspection.fov = 62.0
		_inspection.current = true
		await process_frame
		await create_timer(0.0, true).timeout
		RenderingServer.force_draw(true, 1.0 / 60.0)
		var relative: String = view[0] + ".png"
		_check(root.get_texture().get_image().save_png(output.path_join(relative)) == OK, relative + " saved")
		_overview_frames.append({"file": relative, "camera": "authored district inspection",
			"camera_position": _v(_inspection.global_position), "target": _v(view[2])})
	_inspection.fov = 40.0
	game.skater._camera.current = true
	game.hud.visible = true
	game.set_physics_process(true)
	game.skater.set_physics_process(true)
	game.skater.set_process(true)

func _v(point: Vector3) -> Array:
	return [point.x, point.y, point.z]

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
