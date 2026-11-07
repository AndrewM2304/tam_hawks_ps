extends SceneTree
## Native diagnostic studio for the actual rider rig and real-input poses.
## No world, HUD or commercial-game visual acceptance is implied by these views.
const Classic = preload("res://tests/classic_tricks_integration_tests.gd")
const OUTPUT := "res://.local/fidelity/rider-studio"
var fixture: Dictionary
var camera: Camera3D
var frames: Array[Dictionary] = []
var failures := 0
var source_before: Dictionary
var sync_markers: Array[MeshInstance3D] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rider inspection requires a rendering display.")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	source_before = source_manifest()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	Classic.Setup.register_actions()
	fixture = await Classic._fixture(self)
	var scene: Node3D = fixture.root
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("29333d")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b9c9dc")
	environment.environment.ambient_light_energy = 0.62
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	scene.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -35, 0)
	key.light_energy = 1.6
	key.light_color = Color("fff1dd")
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 145, 0)
	fill.light_energy = 0.65
	fill.light_color = Color("abc9e9")
	scene.add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("38434b")
	ground_material.roughness = 0.92
	ground.material_override = ground_material
	scene.add_child(ground)
	ground.position.y = -0.002
	camera = Camera3D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scene.add_child(camera)
	camera.current = true
	DirAccess.make_dir_recursive_absolute(OUTPUT + "/synchronization")
	for color: Color in [Color.RED, Color.GREEN, Color.BLUE]:
		var marker := MeshInstance3D.new()
		marker.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		marker.mesh = sphere
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = true
		material.albedo_color = color
		marker.material_override = material
		marker.visible = false
		scene.add_child(marker)
		sync_markers.append(marker)
	await Classic._frames(self, 3)
	var rider: Node3D = fixture.rider._visual_rig._rider
	var head: Node3D = fixture.rider._visual_rig._head
	var body_target: Vector3 = fixture.rider.global_position + Vector3(0, 0.9, 0)
	await shot("idle-front", body_target - rider.global_basis.z * 3.1 + Vector3.UP * 0.05, body_target, 38)
	await shot("idle-side", body_target + rider.global_basis.x * 3.1 + Vector3.UP * 0.05, body_target, 38)
	var jacket_target: Vector3 = fixture.rider._visual_rig._upper.to_global(Vector3(0, 0.22, -0.01))
	await shot("idle-jacket", jacket_target - rider.global_basis.z * 1.55, jacket_target, 38)
	await shot("idle-jacket-side", jacket_target + rider.global_basis.x * 1.55, jacket_target, 38)
	var face_target := head.to_global(Vector3(0, 0.02, -0.025))
	await shot("idle-face", face_target - head.global_basis.z * 0.78, face_target, 35)
	await shot("idle-profile", face_target + head.global_basis.x * 0.78, face_target, 35)
	var board: Node3D = fixture.rider._visual_rig._board
	await shot("idle-feet", board.to_global(Vector3(0.70, 0.38, 0.80)), board.to_global(Vector3(0, 0.04, 0)), 38)
	Input.action_press("push")
	await Classic._frames(self, 31)
	Input.action_release("push")
	body_target = fixture.rider.global_position + Vector3(0, 0.85, 0)
	await shot("push", body_target + Vector3(2.3, 0.7, 2.65), body_target, 40)
	Input.action_press("ollie")
	await Classic._frames(self, 18)
	Input.action_release("ollie")
	await Classic._frames(self, 3)
	Classic._direction(Vector2.LEFT)
	Classic._key(KEY_K, true)
	await Classic._frames(self, 14)
	Classic._key(KEY_K, false)
	Classic._direction(Vector2.ZERO)
	if not fixture.rider.airborne or fixture.rider._visual_rig._grab_blend < 0.1:
		failures += 1
		push_error("Studio grab requires a real airborne accepted input.")
	body_target = fixture.rider.global_position + Vector3(0, 0.85, 0)
	await shot("grab", body_target + Vector3(2.3, 0.7, 2.65), body_target, 40)
	var source_after := source_manifest()
	var stable := source_before == source_after
	if not stable:
		failures += 1
		push_error("Rider source changed during inspection; reject this capture epoch.")
	var file := FileAccess.open(OUTPUT + "/receipt.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"purpose": "Native diagnostic studio; actual rig on a flat fixture, not normal Main or human acceptance.",
		"renderer": RenderingServer.get_current_rendering_method(), "frames": frames, "failures": failures,
		"captured_at_utc": Time.get_datetime_string_from_system(true) + "Z",
		"source_stable": stable, "source_sha256": source_before, "source_after_sha256": source_after}, "\t"))
	print("RIDER_STUDIO frames=", frames.size(), " failures=", failures)
	await Classic._dispose(self, fixture)
	quit(1 if failures else 0)

func shot(label: String, from: Vector3, toward: Vector3, field_of_view: float) -> void:
	fixture.rider.set_physics_process(false)
	fixture.rider.set_process(false)
	camera.global_position = from
	camera.look_at(toward)
	camera.fov = field_of_view
	camera.current = true
	camera.reset_physics_interpolation()
	var depth := from.distance_to(toward)
	var marker_points: Array[Vector3] = [toward,
		toward + camera.global_basis.x * depth * 0.07,
		toward + camera.global_basis.y * depth * 0.07]
	for index in sync_markers.size():
		sync_markers[index].global_position = marker_points[index]
		sync_markers[index].scale = Vector3.ONE * depth * 0.003
		sync_markers[index].visible = true
	var pose_before := _pose_snapshot()
	await _native_frame()
	var proof_pose_before := _pose_snapshot()
	var proof_tick_before := _frame_counts()
	var proof_image := root.get_texture().get_image()
	var proof_tick_after := _frame_counts()
	var proof_pose_after := _pose_snapshot()
	proof_image.convert(Image.FORMAT_RGBA8)
	var proof_path := OUTPUT + "/synchronization/" + label + ".png"
	if proof_image.save_png(proof_path) != OK:
		failures += 1
		push_error("Could not save studio synchronization frame " + label)
	for marker: MeshInstance3D in sync_markers:
		marker.visible = false
	# Let the native draw loop consume the current camera and scene transforms.
	# A manual force_draw immediately after a camera change can retain pixels
	# from the preceding view, so it is not used as current-frame proof.
	await _native_frame()
	var path := OUTPUT + "/" + label + ".png"
	var clean_pose_before := _pose_snapshot()
	var clean_tick_before := _frame_counts()
	var clean_image := root.get_texture().get_image()
	var clean_tick_after := _frame_counts()
	var clean_pose_after := _pose_snapshot()
	clean_image.convert(Image.FORMAT_RGBA8)
	if clean_image.save_png(path) != OK:
		failures += 1
		push_error("Could not save rider studio frame " + label)
	var proofs: Array[Dictionary] = []
	for index in sync_markers.size():
		var projected := camera.unproject_position(marker_points[index])
		projected *= Vector2(proof_image.get_size()) / root.get_visible_rect().size
		var proof := _marker_pixels(proof_image, clean_image, projected, index)
		proof.world_position = marker_points[index]
		proof.projected_pixel = projected
		proofs.append(proof)
		if proof.count < 4 or proof.centroid_error > 2.5:
			failures += 1
			push_error("Studio projected-pixel camera synchronization failed " + label)
	if pose_before != proof_pose_before or pose_before != proof_pose_after or pose_before != clean_pose_before or pose_before != clean_pose_after or proof_tick_before != proof_tick_after or clean_tick_before != clean_tick_after:
		failures += 1
		push_error("Studio rig/camera pose or frame counter changed during readback: " + label)
	if not camera.is_current():
		failures += 1
		push_error("The intended rider studio camera did not own the native frame.")
	frames.append({"label": label, "path": path, "position": fixture.rider.global_position,
		"airborne": fixture.rider.airborne, "speed": fixture.rider.speed,
		"png_sha256": FileAccess.get_sha256(path), "camera_current": camera.is_current(),
		"camera_position": camera.global_position, "camera_fov": camera.fov,
		"native_frame": Engine.get_process_frames(), "synchronization": proofs,
		"native_rgba_sha256": _image_sha256(clean_image), "synchronization_native_rgba_sha256": _image_sha256(proof_image),
		"proof_readback_counter_bracket": [proof_tick_before,proof_tick_after], "clean_readback_counter_bracket": [clean_tick_before,clean_tick_after],
		"proof_readback_pose_bracket": [proof_pose_before,proof_pose_after], "clean_readback_pose_bracket": [clean_pose_before,clean_pose_after],
		"native_state": clean_pose_after, "rendered_head_world": _matrix(fixture.rider._visual_rig._head.get_global_transform_interpolated()),
		"rendered_rider_world": _matrix(fixture.rider._visual_rig._rider.get_global_transform_interpolated()),
		"physics_interpolation_fraction": Engine.get_physics_interpolation_fraction(),
		"synchronization_png_sha256": FileAccess.get_sha256(proof_path)})
	fixture.rider.set_physics_process(true)
	fixture.rider.set_process(true)

func _native_frame() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw

func _marker_pixels(image: Image, clean_image: Image, projected: Vector2, channel: int) -> Dictionary:
	var total := Vector2.ZERO
	var count := 0
	for y in range(maxi(0, int(projected.y) - 12), mini(image.get_height(), int(projected.y) + 13)):
		for x in range(maxi(0, int(projected.x) - 12), mini(image.get_width(), int(projected.x) + 13)):
			var pixel := image.get_pixel(x, y)
			var clean := clean_image.get_pixel(x,y)
			var changed := absf(pixel.r-clean.r)+absf(pixel.g-clean.g)+absf(pixel.b-clean.b)>0.12
			var components := [pixel.r, pixel.g, pixel.b]
			if changed and components[channel] > 0.75 and components[channel] - components[(channel + 1) % 3] > 0.2 \
				and components[channel] - components[(channel + 2) % 3] > 0.2:
				count += 1
				total += Vector2(x + 0.5, y + 0.5)
	return {"count": count, "centroid_error": (total / count).distance_to(projected) if count else 999.0,
		"color_channel": ["red", "green", "blue"][channel]}

func source_manifest() -> Dictionary:
	var result := {}
	for path: String in ["res://project.godot", "res://game/player/skater.gd",
		"res://game/player/skater_visual.gd", "res://game/player/skater_anatomy.gd",
		"res://game/player/skater_garments.gd", "res://game/player/skater_footwear.gd",
		"res://game/player/trick_animation.gd", "res://game/art/assets/tam_skateboard/tam_skateboard.glb",
		"res://tools/rider_asset_inspect.gd", "res://tools/rider_asset_inspect.sh",
		"res://tools/run.sh", "res://tests/classic_tricks_integration_tests.gd"]:
		result[path] = FileAccess.get_sha256(path)
	for directory: String in ["res://game/art/rider", "res://game/art/assets/makehuman_hm08"]:
		for file in DirAccess.get_files_at(directory):
			if file.ends_with(".png") or file.ends_with(".obj") or file.ends_with(".glb") or file.ends_with(".json") or file.ends_with(".import"):
				result[directory + "/" + file] = FileAccess.get_sha256(directory + "/" + file)
	return result

func _frame_counts() -> Dictionary:
	return {"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames()}

func _matrix(value: Transform3D) -> Array:
	return [[value.basis.x.x,value.basis.y.x,value.basis.z.x,value.origin.x],
		[value.basis.x.y,value.basis.y.y,value.basis.z.y,value.origin.y],
		[value.basis.x.z,value.basis.y.z,value.basis.z.z,value.origin.z],[0,0,0,1]]

func _pose_snapshot() -> Dictionary:
	var rig: RefCounted = fixture.rider._visual_rig
	var skeleton: Skeleton3D = rig._garments.skeleton
	var bones := {}
	for bone in skeleton.get_bone_count():
		bones[skeleton.get_bone_name(bone)] = _matrix(skeleton.get_bone_global_pose(bone))
	var projection := camera.get_camera_projection()
	return {"camera_global":_matrix(camera.global_transform), "camera_near":camera.near, "camera_far":camera.far,
		"camera_projection_columns":[[projection.x.x,projection.x.y,projection.x.z,projection.x.w],
			[projection.y.x,projection.y.y,projection.y.z,projection.y.w],[projection.z.x,projection.z.y,projection.z.z,projection.z.w],
			[projection.w.x,projection.w.y,projection.w.z,projection.w.w]],"viewport_pixels":[root.size.x,root.size.y],
		"head_global":_matrix(rig._head.global_transform),"rider_global":_matrix(rig._rider.global_transform),
		"skeleton_global":_matrix(skeleton.global_transform),"bone_global_pose_in_skeleton":bones,
		"scope":"Current actual native pose. Rendered interpolation and moving contact remain separate gates."}

func _image_sha256(value: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.get_data())
	return context.finish().hex_encode()
