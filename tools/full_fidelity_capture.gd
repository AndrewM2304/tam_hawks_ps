extends SceneTree
## Continuous source-bound motion from the exact native integration tests.
## Inspection cameras are declared; genuine chase clips retain the player camera.
const Main = preload("res://game/main.gd")
const Authentic = preload("res://tests/authentic_fidelity_integration_tests.gd")
const Repertoire = preload("res://tests/full_repertoire_tests.gd")
const Density = preload("res://tests/full_level_density_tests.gd")
const CurvedVisual = preload("res://tests/curved_visual_contact_tests.gd")
const Platform = preload("res://tests/platform_contact_tests.gd")
const GrindSurface = preload("res://tests/grind_surface_contact_tests.gd")
const Kelvingrove = preload("res://tests/kelvingrove_skatepark_tests.gd")
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
var _sync_proofs: Array[Dictionary] = []
var _raw_spool := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Full fidelity motion capture requires a rendering display.")
		quit(1)
		return
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty(): output = arguments[0]
	_raw_spool = OS.get_environment("FULL_FIDELITY_RAW_SPOOL") == "1"
	RenderingServer.set_render_loop_enabled(false)
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
	await _synchronization_probe()
	await Authentic.run(self, game, _check, _observe)
	await CurvedVisual.run(self, game, _check, _observe)
	await GrindSurface.run(self, game, _check, _observe)
	await Kelvingrove.run(self, game, _check, _observe)
	await Platform.run(self, game, _check, _observe)
	await Remaining.run_main(self, game, _check, _observe)
	await Repertoire.run_playable(self, game, _check, _observe)
	await Density.run_player(self, game, _check, _observe)
	var clips: Array = _clips.values()
	_check(clips.size() >= 50, "full motion: all connected mechanics and repertoire phases produced real clips")
	var catalog_families := {}
	for family: String in Catalog.FAMILIES:
		catalog_families[family] = Catalog.family_ids(family)
	var report := {"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(), "platform": OS.get_name(),
		"production_main": true, "profile_writes_enabled": game.persistence_enabled,
		"checks": checks, "failures": failures, "physics_hz": 60, "motion_sample_hz": 15,
		"clips": clips, "overviews": _overview_frames, "synchronization_proofs": _sync_proofs, "native_timeline": _timeline, "catalog_families": catalog_families, "catalog_ids":Catalog.ids(),
		"fixture_policy": "Only declared restart/initial-contact fixtures from the linked integration tests; real input/native motion thereafter. Repertoire uses explicitly declared elevated air fixtures and special unlock/meter eligibility seeds.",
		"camera_policy": "Native chase for world lines, connected surfaces and activities; authored marker-bounded contact inspection for tricks/setup/recovery; explicit cart-centred inspection for the empty parked turn.",
		"render_fence_policy": "Production processing is fenced by a same-frame zero timer; each selected frame uses the natural render loop and awaits frame_post_draw, with unchanged physics/process counters. Independent coloured 3D markers at actual projected head/board and current Canvas swatches prove camera/Canvas boundary synchronization.",
		"pixel_storage_policy": "Native RGBA8 bytes are hashed before atomic raw spooling; a local standard-library lossless PNG worker encodes those exact bytes and independently checks the decoded pixel hash. No pixel/resolution/sample reduction.",
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
	if clip.has("last_physics_frame"):
		_check(int(state.physics_frame)-int(clip.last_physics_frame)==1,
			"native motion has no missing physics observations in " + phase)
	clip.last_physics_frame = state.physics_frame
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
	var image: Image = await _render_current_frame()
	var relative := "frames/%s/%05d.png" % [phase, clip.frames.size()]
	var storage := _store_frame(image, relative)
	var camera: Camera3D = root.get_camera_3d()
	clip.frames.append({"file": relative, "native_step": _global_step, "state": state,
		"camera_position": _v(camera.global_position), "camera_forward": _v(-camera.global_basis.z), "camera_fov": camera.fov,
		"camera_far": camera.far, "camera_cull_mask": camera.cull_mask, "visual_workload": "complete production world; authored camera only",
		"pixels": storage})

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
		"transition_state":skater._transition.state, "transition_feature":str(skater._transition.feature.get_path()) if is_instance_valid(skater._transition.feature) else "",
		"native_floor_valid":skater._native_floor_valid, "force_air_tick":skater._force_air_tick, "up_direction":_v(skater.up_direction),
		"capsule_up":_v(skater.get_node("BodyCollision").global_basis.y.normalized()),
		"combo": observed.score.get_combo_value(), "entries": observed.score.combo_trick_count,
		"banked": observed.score.total_score, "accepted_score_identities":observed.score._repetitions.keys(),
		"current_receipt_labels":observed.score.trick_history.duplicate(), "last_banked_receipt_labels":observed.score.last_banked_tricks.duplicate(), "markers_head_board_feet_hands": encoded, "actions": actions}

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
	var views: Array = [
		["overview_exchange", Vector3(20,32,38), Vector3(0,2,-12)],
		["overview_george", Vector3(43,32,-43), Vector3(0,4,-85)],
		["overview_central", Vector3(-52,36,54), Vector3(-90,3,1)],
		["overview_barras", Vector3(75,28,43), Vector3(113,2,-5)],
		["overview_clyde", Vector3(-22,43,151), Vector3(-55,2,100)],
		["overview_park", Vector3(-115,47,-62), Vector3(-174,10,-128)],
	]
	var facility: Dictionary = game.world.get_park_skatepark_definition()
	_check(facility.has("position"), "the new sunken facility publishes an actual overview target")
	if facility.has("position"):
		views.append(["overview_sunken_kelvingrove", Vector3(facility.position)+Vector3(28,15,24), Vector3(facility.position)])
	for view: Array in views:
		_inspection.global_position = view[1]
		_inspection.look_at(view[2])
		_inspection.fov = 62.0
		_inspection.current = true
		await process_frame
		await create_timer(0.0, true).timeout
		var image: Image = await _render_current_frame()
		var relative: String = view[0] + ".png"
		var storage := _store_frame(image, relative)
		_overview_frames.append({"file": relative, "camera": "authored district inspection",
			"camera_position": _v(_inspection.global_position), "target": _v(view[2]), "pixels": storage})
	_inspection.fov = 40.0
	game.skater._camera.current = true
	game.hud.visible = true
	game.set_physics_process(true)
	game.skater.set_physics_process(true)
	game.skater.set_process(true)

func _render_current_frame() -> Image:
	# Let the engine flush current Node3D, Skeleton and Canvas notifications in
	# its normal render pass. Manual force_draw immediately after changing the
	# camera can read the previous camera, even when metadata is already current.
	var native_tick := Engine.get_physics_frames()
	var process_tick := Engine.get_process_frames()
	var started := Time.get_ticks_usec()
	RenderingServer.set_render_loop_enabled(true)
	await RenderingServer.frame_post_draw
	RenderingServer.set_render_loop_enabled(false)
	_check(Engine.get_physics_frames() == native_tick and Engine.get_process_frames() == process_tick,
		"natural readback completes the current frame without another physics/process tick")
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	_check(image.get_width() == 1280 and image.get_height() == 800,
		"native capture retains the full 1280 by 800 viewport")
	image.set_meta("draw_and_read_microseconds", Time.get_ticks_usec() - started)
	return image

func _store_frame(image: Image, relative: String) -> Dictionary:
	var started := Time.get_ticks_usec()
	var bytes := image.get_data()
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	var pixel_hash := hash.finish().hex_encode()
	if _raw_spool:
		var raw_path := output.path_join(relative.get_basename() + ".rgba")
		var file := FileAccess.open(raw_path + ".tmp", FileAccess.WRITE)
		_check(file != null, "raw pixel spool opened " + relative)
		if file != null:
			file.store_buffer(bytes)
			file.close()
			_check(DirAccess.rename_absolute(raw_path + ".tmp", raw_path) == OK,
				"complete native pixel spool published atomically " + relative)
	else:
		_check(image.save_png(output.path_join(relative)) == OK, "lossless frame saved " + relative)
	return {"format":"RGBA8", "rgba8_sha256":pixel_hash, "bytes":bytes.size(),
		"draw_and_read_microseconds":image.get_meta("draw_and_read_microseconds", 0),
		"hash_and_store_microseconds":Time.get_ticks_usec() - started,
		"encoding":"atomic raw spool to standard-library lossless PNG" if _raw_spool else "Godot lossless PNG"}

func _synchronization_probe() -> void:
	# Separate diagnostic images, never used as gameplay/movie samples. Visible
	# 3D spheres sit at the actual head/board world points, so a stale camera
	# buffer fails an independent projected-pixel test; a Canvas swatch proves
	# the HUD/Canvas commands belong to that same logical frame as well.
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var swatch := ColorRect.new()
	swatch.position = Vector2(12,12)
	swatch.size = Vector2(32,32)
	canvas.add_child(swatch)
	var markers: Array[MeshInstance3D] = []
	for color: Color in [Color.RED, Color.GREEN]:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.055
		sphere.height = 0.11
		marker.mesh = sphere
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = true
		material.albedo_color = color
		marker.material_override = material
		game.add_child(marker)
		markers.append(marker)
	DirAccess.make_dir_recursive_absolute(output.path_join("synchronization"))
	for index in 3:
		await physics_frame
		await process_frame
		await create_timer(0.0, true).timeout
		var points := _markers(game)
		for part in 2: markers[part].global_position = points[part]
		var label: String = ["overview_before_contact", "first_contact_inspection", "return_to_production_chase"][index]
		swatch.color = [Color.BLUE, Color.YELLOW, Color.MAGENTA][index]
		if index == 0:
			_inspection.global_position = Vector3(-115,47,-62)
			_inspection.look_at(Vector3(-174,10,-128))
			_inspection.fov = 62.0
			_inspection.current = true
		elif index == 1:
			var center := (points[0] + points[1]) * 0.5
			_inspection.global_position = center + Vector3(2.4,1.4,2.8).normalized() * 3.8
			_inspection.look_at(center)
			_inspection.fov = 40.0
			_inspection.current = true
		else:
			game.skater._camera.current = true
		game.hud.visible = index == 2
		var native_tick := Engine.get_physics_frames()
		var process_tick := Engine.get_process_frames()
		var camera := root.get_camera_3d()
		var image: Image = await _render_current_frame()
		var proof := {"id":label, "file":"synchronization/" + label + ".png",
			"physics_frame":native_tick, "process_frame":process_tick,
			"same_native_frame":Engine.get_physics_frames() == native_tick and Engine.get_process_frames() == process_tick,
			"camera_position":_v(camera.global_position), "canvas_pixel":[20,20],
			"canvas_expected":_color(swatch.color), "markers":[]}
		_check(image.get_pixel(20,20).is_equal_approx(swatch.color),
			"current Canvas pixel survives camera boundary " + label)
		if index > 0:
			for part in 2:
				var logical_projected := camera.unproject_position(points[part])
				var viewport_size := camera.get_viewport().get_visible_rect().size
				var projected := logical_projected * Vector2(image.get_size()) / viewport_size
				var evidence := _marker_pixels(image, projected, part)
				evidence.world = _v(points[part])
				evidence.projected_pixel = [projected.x,projected.y]
				evidence.logical_viewport_size = [viewport_size.x,viewport_size.y]
				evidence.logical_projected = [logical_projected.x,logical_projected.y]
				evidence.kind = "actual head" if part == 0 else "actual board"
				proof.markers.append(evidence)
				_check(evidence.count >= 4 and evidence.centroid_error <= 2.5,
					"actual projected head/board pixels use the current camera at " + label)
		proof.pixels = _store_frame(image, proof.file)
		_sync_proofs.append(proof)
	for marker in markers: marker.queue_free()
	canvas.queue_free()
	await process_frame
	await create_timer(0.0, true).timeout
	game.skater._camera.current = true
	game.hud.visible = true

func _marker_pixels(image: Image, projected: Vector2, part: int) -> Dictionary:
	var total := Vector2.ZERO
	var count := 0
	for y in range(maxi(0,int(projected.y)-12), mini(800,int(projected.y)+13)):
		for x in range(maxi(0,int(projected.x)-12), mini(1280,int(projected.x)+13)):
			var color := image.get_pixel(x,y)
			var match_color := color.r > 0.75 and color.r - color.g > 0.20 and color.r - color.b > 0.20 if part == 0 else color.g > 0.75 and color.g - color.r > 0.20 and color.g - color.b > 0.20
			if match_color:
				count += 1
				total += Vector2(x + 0.5,y + 0.5)
	return {"count":count, "centroid_error":(total / count).distance_to(projected) if count else 999.0,
		"color_channel":"red" if part == 0 else "green"}

func _color(color: Color) -> Array:
	return [roundi(color.r*255),roundi(color.g*255),roundi(color.b*255),roundi(color.a*255)]

func _v(point: Vector3) -> Array:
	return [point.x, point.y, point.z]

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
