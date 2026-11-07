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
const PushContact = preload("res://tests/motion_fidelity_tests.gd")
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
var _cohort := "all"
var _push_view := "contact"
var _push_selection := "all"
var _native_size := Vector2i(1280,800)
const NATURAL_PUSH_VIEWS := {"push_contact_regular":"front", "push_contact_from_rest":"side", "push_contact_fakie":"chase"}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Full fidelity motion capture requires a rendering display.")
		quit(1)
		return
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty(): output = arguments[0]
	if arguments.size()>1:_cohort=arguments[1]
	if arguments.size()>2:_push_view=arguments[2]
	if arguments.size()>3:_push_selection=arguments[3]
	if arguments.size()>4:
		if arguments[4]=="640x400":_native_size=Vector2i(640,400)
		elif arguments[4]!="1280x800":
			push_error("Unsupported native capture size: "+arguments[4])
			quit(1)
			return
	if _native_size!=Vector2i(1280,800) and _cohort!="push-contact":
		push_error("Native640 is restricted to focused diagnostic push motion.")
		quit(1)
		return
	if _push_selection not in ["all","natural-three"] or (_push_selection!="all" and _cohort!="push-contact"):
		push_error("Invalid push capture-only selection: "+_push_selection)
		quit(1)
		return
	if _cohort not in ["all","push-contact"]:
		push_error("Unknown full-fidelity cohort: "+_cohort)
		quit(1)
		return
	if _push_view not in ["contact","front","side","chase"]:
		push_error("Unknown push inspection view: "+_push_view)
		quit(1)
		return
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
	if _cohort=="all":await _overviews()
	await _synchronization_probe()
	if _cohort=="push-contact":
		await PushContact.run_main(self,game,_check,_observe)
	else:
		await Authentic.run(self, game, _check, _observe)
		await CurvedVisual.run(self, game, _check, _observe)
		await GrindSurface.run(self, game, _check, _observe)
		await Kelvingrove.run(self, game, _check, _observe)
		await Platform.run(self, game, _check, _observe)
		await Remaining.run_main(self, game, _check, _observe)
		await Repertoire.run_playable(self, game, _check, _observe)
		await Density.run_player(self, game, _check, _observe)
	var observed_clips: Array = _clips.values()
	var clips: Array = observed_clips.filter(func(clip: Dictionary): return not clip.frames.is_empty())
	_check(observed_clips.size() >= (7 if _cohort=="push-contact" else 50),
		"full motion: selected "+_cohort+" cohort produced its required real clips")
	if _push_selection=="natural-three":
		_check(clips.size()==3,"natural-three records exactly its three declared push cases")
		for clip: Dictionary in clips:
			_check(int(clip.native_steps)==117 and clip.frames.size()==117,"natural-three retains all72press+45release consecutive ticks in "+str(clip.id))
	var catalog_families := {}
	for family: String in Catalog.FAMILIES:
		catalog_families[family] = Catalog.family_ids(family)
	var report := {"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(), "platform": OS.get_name(),
		"production_main": true, "profile_writes_enabled": game.persistence_enabled,
		"checks": checks, "failures": failures, "physics_hz": 60, "motion_sample_hz": 60 if _cohort=="push-contact" else 15,
		"cohort":_cohort,"complete_repertoire_coverage":_cohort=="all",
		"push_camera_view":"mixed-per-case" if _push_selection=="natural-three" else _push_view,
		"push_capture_selection":_push_selection,
		"native_capture_size":[_native_size.x,_native_size.y],
		"logical_viewport_size":[root.get_visible_rect().size.x,root.get_visible_rect().size.y],
		"resolution_scope":"Native640x400 diagnostic motion; no upsampling, finaltexture/H1/targetFPS or finalAAA claim. Separate native1280Main/closeups own surface fidelity." if _native_size==Vector2i(640,400) else "Original native1280x800 capture.",
		"observed_phase_ids":_clips.keys(),
		"recorded_phase_ids":clips.map(func(clip: Dictionary): return clip.id),
		"unrecorded_phase_ids":observed_clips.filter(func(clip: Dictionary): return clip.frames.is_empty()).map(func(clip: Dictionary): return clip.id),
		"per_case_push_view":NATURAL_PUSH_VIEWS if _push_selection=="natural-three" else {},
		"visual_phase_coverage_complete":_push_selection=="all",
		"capture_selection_policy":"Every physical phase/check/native trace still runs. The natural-three selection records all117consecutive ticks (72push+45release) of regular/front, from-rest/side and fakie/productionchase; brake/pop are physically checked but visually UNREVIEWED. No discarded phase is claimed as a visual pass." if _push_selection=="natural-three" else "Original complete selected cohort and sampling policy unchanged.",
		"push_fixture_policy":"Regular/fakie moving-start cases seed signed6m/s and one initial heading on the same native spine; a separate actual push-from-rest case seeds no motion. Brake and6/18-tick push-to-pop interruptions use actual mapped input from rest.",
		"clips": clips, "overviews": _overview_frames, "synchronization_proofs": _sync_proofs, "native_timeline": _timeline, "catalog_families": catalog_families, "catalog_ids":Catalog.ids(),
		"fixture_policy": "Only declared restart/initial-contact fixtures from the linked integration tests; real input/native motion thereafter. Repertoire uses explicitly declared elevated air fixtures and special unlock/meter eligibility seeds." if _cohort=="all" else "Declared default-spawn restarts, regular/fakie initial headings and two signed6m/s moving starts. Separate from-rest, brake and6/18-tick pop cases use actual input without motion seeds; see push_fixture_policy.",
		"camera_policy": ("Explicit per-case camera map: regular/front and from-rest/side authored inspection; fakie uses the actual production chase camera and HUD. Every117 consecutive native push/release tick is recorded. Brake/pop stay physically checked but visually unreviewed." if _push_selection=="natural-three" else  "Native chase for world lines, connected surfaces and activities; authored marker-bounded contact inspection for tricks/setup/recovery; explicit cart-centred inspection for the empty parked turn." if _cohort=="all" else ("Production chase camera and HUD throughout actual push/brake/pop motion." if _push_view=="chase" else "Authored "+_push_view+" inspection of actual production Main input/motion; camera/Canvas boundary proofs retained.")),
		"render_fence_policy": "Production processing is fenced by a same-frame zero timer; each selected frame uses the natural render loop and awaits frame_post_draw, with unchanged physics/process counters. Independent coloured 3D markers at actual projected head/board and current Canvas swatches prove camera/Canvas boundary synchronization.",
		"pixel_storage_policy": "Every declared native640 RGBA8 pixel is hashed and losslessly encoded without resizing or upsampling; consecutive selected physics frames remain60Hz. This is diagnostic motion, not finalresolution acceptance." if _native_size==Vector2i(640,400) else "Native RGBA8 bytes are hashed before atomic raw spooling; a local standard-library lossless PNG worker encodes those exact bytes and independently checks the decoded pixel hash. No pixel/resolution/sample reduction.",
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
		if phase.begins_with("push_contact_") and inspection:camera_label="authored "+_phase_push_view(phase)+" push inspection"
		_clips[phase] = {"id": phase, "camera": camera_label,
			"native_steps": 0, "sample_stride": 1 if phase.begins_with("push_contact_") else 4, "frames": []}
		DirAccess.make_dir_recursive_absolute(output.path_join("frames/" + phase))
	var clip: Dictionary = _clips[phase]
	if clip.has("last_physics_frame"):
		_check(int(state.physics_frame)-int(clip.last_physics_frame)==1,
			"native motion has no missing physics observations in " + phase)
	clip.last_physics_frame = state.physics_frame
	clip.native_steps += 1
	if _push_selection=="natural-three" and not NATURAL_PUSH_VIEWS.has(phase):return
	if (int(clip.native_steps) - 1) % int(clip.sample_stride) != 0: return
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
		var view_axis:=Vector3(2.4,1.4,2.8).normalized()
		if phase.begins_with("push_contact_"):
			var forward:Vector3=(-game.skater.global_basis.z*game.skater._visual_rig._last_travel_direction).slide(Vector3.UP).normalized()
			if _phase_push_view(phase)=="front":view_axis=(forward+Vector3.UP*0.35).normalized()
			elif _phase_push_view(phase)=="side":view_axis=(forward.cross(Vector3.UP)+Vector3.UP*0.35).normalized()
		_inspection.global_position = center + view_axis * distance
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
		"camera_far": camera.far, "camera_cull_mask": camera.cull_mask, "visual_workload": "complete production world at declared native640; source geometry/assets/quality settings unchanged" if _native_size==Vector2i(640,400) else "complete production world; authored camera only",
		"pixels": storage})

func _snapshot(observed: Node) -> Dictionary:
	var skater: CharacterBody3D = observed.skater
	var vehicle: Node3D = observed.feature_hub.vehicle
	var vehicle_status: Dictionary = vehicle.status_snapshot()
	var cylindrical_feature: Dictionary=skater._transition.feature
	var cylindrical_body: StaticBody3D=cylindrical_feature.get("body")
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
		"push_phase":skater._visual_rig._push_phase,"push_blend":skater._visual_rig._push_blend,
		"torso_forward":_v(-skater._visual_rig._upper.global_basis.z),
		"hips_forward":_v(-(skater._visual_rig._garments.skeleton.global_basis \
			* skater._visual_rig._garments.skeleton.get_bone_global_pose(int(skater._visual_rig._garments._bones.hips)).basis).z),
		"head_forward":_v(-skater._visual_rig._head.global_basis.z),
		"front_shoe_forward":_v(-skater._visual_rig._legs[0].foot.global_basis.z),
		"rear_sole":_v(skater._visual_rig._legs[1].foot.to_global(Vector3(0,-0.0605,0))),
		"flip_remaining": skater._flip_remaining, "special_remaining": skater._special_remaining,
		"setup_active": skater.setup_active, "setup_id": skater.setup_id, "setup_phase": skater.setup_phase,
		"bail_active": skater.bail_active, "bail_phase": skater.bail_phase, "skitching": skater.skitching,
		"skitch_caught": skater.skitch_caught, "recovery_fade": skater.recovery_fade,
		"wallriding": skater.wallriding, "transition_active": skater.transition_active,
		"transition_state":skater._feature_transition.state,
		"transition_feature":str(skater._feature_transition.feature.get_path()) if is_instance_valid(skater._feature_transition.feature) else "",
		"cylindrical_transition_active":skater._transition.active,
		"cylindrical_transition_feature_id":str(cylindrical_feature.get("id","")),
		"cylindrical_transition_body":str(cylindrical_body.get_path()) if is_instance_valid(cylindrical_body) else "",
		"cylindrical_transition_theta":skater._transition.theta,
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

func _phase_push_view(phase: String) -> String:
	return str(NATURAL_PUSH_VIEWS.get(phase,_push_view)) if _push_selection=="natural-three" else _push_view

func _uses_inspection(phase: String) -> bool:
	return phase.begins_with("setup_") or phase.begins_with("bail_") or phase.begins_with("interrupted_") \
		or phase.begins_with("unsupported_plant_") or phase == "high_wall_bail" \
		or phase == "platform_roof_boneless" \
		or phase.begins_with("flip_") or phase.begins_with("grab_") or phase.begins_with("manual_") \
		or phase.begins_with("special_") or phase.begins_with("lip_") or phase.begins_with("grind_") \
		or phase == "triple_flip_one_entry" or (phase.begins_with("push_contact_") and _phase_push_view(phase)!="chase")

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
	var skin_current_before:=_pose_current()
	var skin_rendered_before:=_pose_rendered()
	var skin_camera_before:=_skin_camera()
	var skin_counts_before:=_skin_counts()
	RenderingServer.set_render_loop_enabled(true)
	await RenderingServer.frame_post_draw
	RenderingServer.set_render_loop_enabled(false)
	_check(Engine.get_physics_frames() == native_tick and Engine.get_process_frames() == process_tick,
		"natural readback completes the current frame without another physics/process tick")
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	_check(image.get_width() == _native_size.x and image.get_height() == _native_size.y,
		"native capture retains every pixel of its declared "+str(_native_size)+" viewport")
	image.set_meta("draw_and_read_microseconds", Time.get_ticks_usec() - started)
	var skin_current_after:=_pose_current()
	var skin_rendered_after:=_pose_rendered()
	var skin_camera_after:=_skin_camera()
	var skin_counts_after:=_skin_counts()
	_check(skin_current_before==skin_current_after and skin_camera_before==skin_camera_after and skin_counts_before==skin_counts_after,"nativeSkin currentpose/camera/counter readbackbarrier")
	_skin_pending={"native_step":_global_step,"before_current":skin_current_before,"after_current":skin_current_after,"before_rendered":skin_rendered_before,"after_rendered":skin_rendered_after,"camera_before":skin_camera_before,"camera_after":skin_camera_after,"counters_before":skin_counts_before,"counters_after":skin_counts_after}
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
	_flush_skin_row(image,relative,pixel_hash,bytes.size())
	return {"format":"RGBA8", "native_skin_sidecar_row":image.get_meta("native_skin_sidecar_row",-1),"rgba8_sha256":pixel_hash, "bytes":bytes.size(),
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
		var logical_viewport:Vector2=camera.get_viewport().get_visible_rect().size
		var native_scale:=Vector2(image.get_size())/logical_viewport
		var canvas_at:=Vector2i(Vector2(20,20)*native_scale)
		var proof := {"id":label, "file":"synchronization/" + label + ".png",
			"physics_frame":native_tick, "process_frame":process_tick,
			"same_native_frame":Engine.get_physics_frames() == native_tick and Engine.get_process_frames() == process_tick,
			"camera_position":_v(camera.global_position), "canvas_pixel":[canvas_at.x,canvas_at.y],
			"native_size":[image.get_width(),image.get_height()],"logical_viewport_size":[logical_viewport.x,logical_viewport.y],
			"canvas_expected":_color(swatch.color), "markers":[]}
		_check(image.get_pixelv(canvas_at).is_equal_approx(swatch.color),
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
	for y in range(maxi(0,int(projected.y)-12), mini(image.get_height(),int(projected.y)+13)):
		for x in range(maxi(0,int(projected.x)-12), mini(image.get_width(),int(projected.x)+13)):
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

# ADDITIVE PRIVATE OBSERVER. Geometry/binds once, only matrices/palettes/morph
# values per readback. Actualgame/physicaldriver/cameras/ticks unchanged.
var _native_geometry:Dictionary={}
var _skin_pending:Dictionary={}
var _skin_stream:FileAccess
var _skin_row:=0
func _nodes()->Dictionary:
	var rig:RefCounted=game.skater._visual_rig
	var result:={"actor":game.skater,"visual":game.skater._visual,"rider":rig._rider,"torso":rig._upper,"head_node":rig._head,"head_mesh":rig._head.get_node("AnatomicalHead"),"board":game.skater._board_visual,"skeleton":rig._garments.skeleton}
	for i:int in rig._legs.size():result["foot"+str(i)]=rig._legs[i].foot
	for i:int in rig._arms.size():result["hand"+str(i)]=rig._arms[i].hand
	return result
func _pose_current()->Dictionary:
	var nodes:=_nodes()
	var out:={"nodes":{},"bones":[]}
	for key:String in nodes:out.nodes[key]=_rows_matrix(nodes[key].global_transform)
	var skeleton:Skeleton3D=nodes.skeleton
	for i:int in skeleton.get_bone_count():out.bones.append(_rows_matrix(skeleton.get_bone_global_pose(i)))
	return out
func _pose_rendered()->Dictionary:
	var nodes:=_nodes()
	var result:={"nodes":{},"native_skin_palettes":{},"hand_morphs":{},"physics_fraction":Engine.get_physics_interpolation_fraction(),"inside_physics_frame":Engine.is_in_physics_frame()}
	for key:String in nodes:result.nodes[key]={"model":_rows_matrix(nodes[key].get_global_transform_interpolated()),"mode":nodes[key].physics_interpolation_mode,"interpolated":nodes[key].is_physics_interpolated_and_enabled()}
	var skeleton:Skeleton3D=nodes.skeleton
	for name:String in ["UpperChest","SkinnedJacket","SkinnedTrousers"]:
		var mesh:=nodes.rider.get_node_or_null(name)as MeshInstance3D
		if mesh==null:continue
		var skinref:SkinReference=skeleton.register_skin(mesh.skin)
		var palette:Array=[]
		for i:int in mesh.skin.get_bind_count():palette.append(_rows_matrix(RenderingServer.skeleton_bone_get_transform(skinref.get_skeleton(),i)))
		result.native_skin_palettes[name]={"palette":palette,"mesh_current":_rows_matrix(mesh.global_transform),"mesh_rendered":_rows_matrix(mesh.get_global_transform_interpolated())}
		if not _native_geometry.has(name):_native_geometry[name]=_mesh_geometry(mesh)
	for i:int in 2:
		var sole:MeshInstance3D=nodes["foot"+str(i)].get_node("Cupsole")
		result.nodes["sole"+str(i)]={"current":_rows_matrix(sole.global_transform),"model":_rows_matrix(sole.get_global_transform_interpolated())}
		if not _native_geometry.has("sole"+str(i)):_native_geometry["sole"+str(i)]=_mesh_geometry(sole)
		var hand:MeshInstance3D=nodes["hand"+str(i)].get_node("HandAndFingers")
		var values:Array=[]
		for shape:int in hand.mesh.get_blend_shape_count():values.append(hand.get_blend_shape_value(shape))
		result.hand_morphs["hand"+str(i)]={"values":values,"mesh_current":_rows_matrix(hand.global_transform),"mesh_rendered":_rows_matrix(hand.get_global_transform_interpolated())}
		if not _native_geometry.has("hand"+str(i)):_native_geometry["hand"+str(i)]=_mesh_geometry(hand)
	if not _native_geometry.has("head"):_native_geometry.head=_mesh_geometry(nodes.head_mesh)
	return result
func _mesh_geometry(mesh:MeshInstance3D)->Dictionary:
	var a:=mesh.mesh.surface_get_arrays(0)
	var points:Array=[]
	for p:Vector3 in a[Mesh.ARRAY_VERTEX]:points.append(_v(p))
	var out:={"path":mesh.mesh.resource_path,"vertices":points,"indices":Array(a[Mesh.ARRAY_INDEX]),"mesh_local":_rows_matrix(mesh.transform)}
	if a[Mesh.ARRAY_BONES]is PackedInt32Array:out.bones=Array(a[Mesh.ARRAY_BONES])
	if a[Mesh.ARRAY_WEIGHTS]is PackedFloat32Array:out.weights=Array(a[Mesh.ARRAY_WEIGHTS])
	if mesh.skin!=null:
		out.binds=[]
		for i:int in mesh.skin.get_bind_count():out.binds.append({"bone":mesh.skin.get_bind_bone(i),"name":String(mesh.skin.get_bind_name(i)),"pose":_rows_matrix(mesh.skin.get_bind_pose(i))})
	if mesh.mesh is ArrayMesh and mesh.mesh.get_blend_shape_count()>0:
		out.blend_shape_mode=mesh.mesh.blend_shape_mode
		out.blend_shape_vertices=[]
		for shape:int in mesh.mesh.get_blend_shape_count():
			var target:Array=[]
			for p:Vector3 in mesh.mesh.surface_get_blend_shape_arrays(0)[shape][Mesh.ARRAY_VERTEX]:target.append(_v(p))
			out.blend_shape_vertices.append(target)
	return out
func _rows_matrix(t:Transform3D)->Array:
	return [[t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x],[t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y],[t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z],[0,0,0,1]]
func _projection_rows(p:Projection)->Array:
	return [[p.x.x,p.y.x,p.z.x,p.w.x],[p.x.y,p.y.y,p.z.y,p.w.y],[p.x.z,p.y.z,p.z.z,p.w.z],[p.x.w,p.y.w,p.z.w,p.w.w]]
func _skin_counts()->Dictionary:
	return {"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames()}
func _skin_camera()->Dictionary:
	var camera:Camera3D=root.get_camera_3d()
	return {"model":_rows_matrix(camera.global_transform),"projection":_projection_rows(camera.get_camera_projection()),"near":camera.near,"far":camera.far,"fov":camera.fov,"logical_viewport":[root.get_visible_rect().size.x,root.get_visible_rect().size.y],"native_size":[_native_size.x,_native_size.y]}
func _flush_skin_row(image:Image,relative:String,pixel_hash:String,bytes:int)->void:
	if _skin_stream==null:
		var file:=FileAccess.open(output.path_join("native-rig-geometry.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"geometry":_native_geometry,"scope":"Actualnative imported/built arrays, rawweights/inversebinds andcachedhandtargets once. ShaderuseslocalweightedXYZ then MODELwithw1, no normalization. No current13artprototype; actual11source."}))
		file.close()
		_skin_stream=FileAccess.open(output.path_join("native-rig-readbacks.jsonl"),FileAccess.WRITE)
	_skin_pending["relative_file"]=relative
	_skin_pending["rgba8_sha256"]=pixel_hash
	_skin_pending["bytes"]=bytes
	_skin_pending["row"]=_skin_row
	_skin_stream.store_line(JSON.stringify(_skin_pending))
	_skin_stream.flush()
	image.set_meta("native_skin_sidecar_row",_skin_row)
	_skin_row+=1
