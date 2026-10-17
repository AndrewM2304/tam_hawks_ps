extends SceneTree
## Actual Main/input/physics inspection for directional trick silhouettes.
## Initial reset fixtures and authored close cameras are recorded explicitly;
## these screenshots do not establish human control feel or target-Mac timing.

const Main = preload("res://game/main.gd")
const OUTPUT := "res://.local/classic-tricks-capture/"
var game: Node
var errors := 0
var records: Array[Dictionary] = []
var normal_spawn := Vector3.ZERO


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Classic trick captures require a real rendering display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	normal_spawn = game.skater.spawn_position
	await _frames(45)
	Input.action_press("ollie")
	await _frames(24)
	_check(not game.skater.airborne, "held ollie remains supported")
	await _shot("01-crouch", "hold Ollie 24 frames from normal spawn", false)
	for entry: Dictionary in [
		{"direction": Vector2.LEFT, "id": "kickflip"},
		{"direction": Vector2.RIGHT, "id": "heelflip"},
		{"direction": Vector2.UP, "id": "frontside_shuvit"},
		{"direction": Vector2.DOWN, "id": "pop_shuvit"},
		{"direction": Vector2(-1, 1), "id": "varial_flip"},
		{"direction": Vector2(1, -1), "id": "hardflip"}]:
		await _launch()
		_direction(entry.direction)
		Input.action_press("flip")
		await _frames(7)
		_check(game.skater.airborne and game.skater.active_flip_id == entry.id,
			"real directional " + entry.id)
		await _shot("flip-" + entry.id, "normal reset, Push 30f, hold Ollie 20f, release 3f, direction=%s + Flip 7f" % entry.direction)
	for entry: Dictionary in [
		{"direction": Vector2.LEFT, "id": "melon_grab"},
		{"direction": Vector2.RIGHT, "id": "indy_grab"},
		{"direction": Vector2.UP, "id": "nose_grab"},
		{"direction": Vector2.DOWN, "id": "tail_grab"},
		{"direction": Vector2(-1, -1), "id": "method_grab"}]:
		await _launch()
		_direction(entry.direction)
		Input.action_press("grab")
		await _frames(11)
		_check(game.skater.airborne and game.skater.active_grab_id == entry.id,
			"real directional " + entry.id)
		await _shot("grab-" + entry.id, "normal reset, Push 30f, hold Ollie 20f, release 3f, direction=%s + hold Grab 11f" % entry.direction)
	for nose: bool in [false, true]:
		await _fresh()
		Input.action_press("push")
		await _frames(45)
		Input.action_release("push")
		if nose: Input.action_press("push")
		Input.action_press("manual")
		await _frames(9)
		Input.action_release("push")
		var id := "nose_manual" if nose else "manual"
		_check(game.skater.manual_active and game.skater.manual_id == id, "real " + id)
		await _shot(id, "normal reset, Push 45f, direction=%s + hold Manual 9f" % ("up" if nose else "neutral"))
	await _ramp_overview()
	await _curved_motion_poses()
	for entry: Dictionary in [
		{"direction": Vector2.ZERO, "id": "axle_stall"},
		{"direction": Vector2.UP, "id": "nose_stall"},
		{"direction": Vector2.DOWN, "id": "tail_stall"},
		{"direction": Vector2.RIGHT, "id": "disaster"}]:
		_release()
		game.skater.spawn_position = Vector3(17, 2.8, 73)
		game.restart_run()
		await _frames(45)
		Input.action_press("push")
		var reached := false
		for frame in 180:
			await _frames(1)
			if game.skater.transition_active and game.skater._transition.theta >= deg_to_rad(72):
				reached = true
				break
		_check(reached, "actual current-quay transition approach " + entry.id)
		_direction(entry.direction)
		Input.action_press("grind")
		for frame in 12:
			await _frames(1)
			if game.skater.lip_active: break
		_direction(Vector2.ZERO)
		await _frames(8)
		_check(game.skater.lip_active and game.skater.lip_id == entry.id, "actual current-quay lip " + entry.id)
		await _shot("lip-" + entry.id, "declared current-quay initial(17,2.8,73), Push until actual curve theta>=72deg, direction=%s + hold Triangle through coping, neutral balance 8f" % entry.direction)
	_release()
	var receipt := {"format": 1, "engine": Engine.get_version_info().string,
		"driver": RenderingServer.get_video_adapter_name(), "viewport": root.size,
		"physics_hz": Engine.physics_ticks_per_second, "persistence_enabled": false,
		"errors": errors, "records": records,
		"fixture_boundary": "Initial resets only. Actual player inputs and physics. Each saved pose is frozen after admission. Close cameras are authored inspection views."}
	var file := FileAccess.open(OUTPUT + "recipe.json", FileAccess.WRITE)
	if file == null:
		_check(false, "recipe writable")
	else:
		file.store_string(JSON.stringify(receipt, "\t") + "\n")
	print("CLASSIC TRICK CAPTURE errors=", errors, " records=", records.size())
	quit(1 if errors else 0)


func _fresh() -> void:
	_release()
	game.skater.spawn_position = normal_spawn
	game.restart_run()
	await _frames(45)


func _launch() -> void:
	await _fresh()
	Input.action_press("push")
	await _frames(30)
	Input.action_release("push")
	Input.action_press("ollie")
	await _frames(20)
	Input.action_release("ollie")
	await _frames(3)
	_check(game.skater.airborne, "release ollie created real airtime")


func _shot(label: String, recipe: String, close: bool = true, close_offset: Vector3 = Vector3(2.25, 1.65, 2.65)) -> void:
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	var entry := {"label": label, "recipe": recipe, "position": game.skater.global_position,
		"velocity": game.skater.velocity, "speed": game.skater.speed,
		"airborne": game.skater.airborne, "flip": game.skater.active_flip_id,
		"grab": game.skater.active_grab_id, "manual": game.skater.manual_id,
		"lip": game.skater.lip_id, "lip_balance": game.skater.lip_balance,
		"transition_active": game.skater.transition_active, "transition_normal": game.skater.transition_normal,
		"transition_theta_degrees": rad_to_deg(game.skater._transition.theta),
		"visual_basis": game.skater.get_node("SkaterVisual").global_basis,
		"chase_camera_position": game.skater._camera.global_position,
		"board_angles": game.skater.get_node("SkaterVisual/Board").rotation,
		"images": []}
	RenderingServer.force_draw(true, 1.0 / 60.0)
	_check(root.get_texture().get_image().save_png(OUTPUT + label + "-chase.png") == OK, label + " chase saved")
	entry.images.append(label + "-chase.png")
	if close:
		game.hud.visible = false
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.global_position = game.skater.global_position + close_offset
		var body_up: Vector3 = game.skater.transition_normal if game.skater.transition_active else Vector3.UP
		camera.look_at(game.skater.global_position + body_up * 0.82)
		camera.fov = 40
		camera.current = true
		await process_frame
		RenderingServer.force_draw(true, 1.0 / 60.0)
		_check(root.get_texture().get_image().save_png(OUTPUT + label + "-close.png") == OK, label + " close saved")
		entry.images.append(label + "-close.png")
		camera.queue_free()
		game.skater._camera.current = true
		game.hud.visible = true
	records.append(entry)
	print("CLASSIC FRAME ", JSON.stringify(entry))
	game.set_physics_process(true)
	game.skater.set_physics_process(true)
	game.skater.set_process(true)


func _curved_motion_poses() -> void:
	# The only placement/heading assignments in these fixtures are initial.
	# Subsequent changes come entirely from ordinary Push and real collisions.
	_release()
	game.skater.spawn_position = Vector3(17, 2.8, 73)
	game.restart_run()
	await _frames(45)
	Input.action_press("push")
	var reached := false
	for frame in 180:
		await _frames(1)
		if game.skater.transition_active and game.skater._transition.theta >= deg_to_rad(60):
			reached = true
			break
	_check(reached and game.skater.transition_normal.y < 0.55 and not game.skater.airborne,
		"actual quarterpipe mid-wall support and body orientation")
	await _shot("quarterpipe-mid-wall", "declared current-quay initial(17,2.8,73), ordinary Push until actual supported curve theta>=60deg; no Jump or state correction")
	var departed := false
	for frame in 90:
		await _frames(1)
		if not game.skater.transition_active and game.skater.airborne:
			departed = true
			break
	Input.action_release("push")
	await _frames(2)
	_check(departed and game.skater.airborne and game.skater.velocity.y > 4.0
		and not game.score.trick_history.has("Ollie"), "actual natural vert release without an Ollie impulse")
	await _shot("quarterpipe-natural-vert-air", "continue ordinary Push from supported quarterpipe60deg through its physical lip, release Push on actual departure, coast 2f; no Ollie input")
	_release()
	game.skater.spawn_position = Vector3(-22, 2.8, 60.5)
	game.restart_run()
	await _frames(45)
	game.skater.rotation.y = -PI * 0.5 # Declared initial east-facing heading only.
	Input.action_press("push")
	reached = false
	for frame in 180:
		await _frames(1)
		if game.skater.transition_active and game.skater._transition.feature.id == "clyde_half_east" \
				and game.skater._transition.theta >= deg_to_rad(60):
			reached = true
			break
	_check(reached and game.skater.transition_normal.x < -0.8 and not game.skater.airborne,
		"actual halfpipe east-wall contact reached from its flat bottom")
	await _shot("halfpipe-east-wall", "declared flat-bottom initial(-22,2.8,60.5), initial yaw=-90deg, ordinary Push until actual east-wall curve theta>=60deg; no per-tick heading/velocity correction", true, Vector3(-2.65, 1.65, 2.25))


func _ramp_overview() -> void:
	_release()
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	game.hud.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = Vector3(9, 16, 82)
	camera.look_at(Vector3(-7, 3, 61))
	camera.fov = 65
	camera.current = true
	await process_frame
	RenderingServer.force_draw(true, 1.0 / 60.0)
	var name := "quarter-and-halfpipe-overview.png"
	_check(root.get_texture().get_image().save_png(OUTPUT + name) == OK, "current-quay ramp overview saved")
	records.append({"label": "quarter-and-halfpipe-overview", "recipe": "authored area-inspection camera at(9,16,82), looking(-7,3,61), FOV65; no moving-play claim", "images": [name]})
	camera.queue_free()
	game.skater._camera.current = true
	game.hud.visible = true
	game.set_physics_process(true)
	game.skater.set_physics_process(true)
	game.skater.set_process(true)


func _direction(value: Vector2) -> void:
	for action: String in ["steer_left", "steer_right", "push", "brake"]:
		Input.action_release(action)
	if value.x < 0.0: Input.action_press("steer_left", absf(value.x))
	if value.x > 0.0: Input.action_press("steer_right", absf(value.x))
	if value.y < 0.0: Input.action_press("push", absf(value.y))
	if value.y > 0.0: Input.action_press("brake", absf(value.y))


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame


func _release() -> void:
	for action: String in InputMap.get_actions(): Input.action_release(action)


func _check(value: bool, label: String) -> void:
	if not value:
		errors += 1
		push_error(label)
