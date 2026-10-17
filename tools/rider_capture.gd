extends SceneTree
## Actual input/physics at 60 Hz; explicit renders freeze only after each requested action.
## Run tools/rider_capture.sh. Outputs are ignored .local/rider-capture PNGs.
## Full-meter special fixtures and authored close cameras are inspection, not human playtests.
const Main = preload("res://game/main.gd")
var game: Node
var errors := 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rider screenshots require a rendering display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://.local/rider-capture")
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.start_mode(true)
	await frames(40)
	await shot("idle", true)
	Input.action_press("push")
	await frames(31)
	await shot("push", true)
	Input.action_release("push")
	Input.action_press("brake")
	await frames(8)
	await shot("brake", true)
	Input.action_release("brake")
	await frames(8)
	await shot("coast", true)
	await fresh_approach()
	await launch()
	Input.action_press("grab")
	await frames(11)
	Input.action_release("grab")
	check(game.skater.airborne and game.skater._grab_remaining > 0, "real airborne grab")
	await shot("grab", true)
	await land()
	await frames(5)
	await shot("landing", true)
	await fresh_approach()
	await launch()
	Input.action_press("flip")
	await frames(7)
	Input.action_release("flip")
	check(game.skater.airborne and game.skater._flip_remaining > 0, "real airborne flip")
	await shot("flip", true)
	await fresh_approach()
	Input.action_press("manual")
	await frames(9)
	check(game.skater.manual_active, "real manual")
	await shot("manual", true)
	Input.action_release("manual")
	await launch()
	await land()
	Input.action_press("revert")
	await frames(4)
	Input.action_release("revert")
	check(game.skater._revert_pose_remaining > 0, "real revert")
	await shot("revert", true)
	for special: String in ["special_one", "special_two"]:
		await fresh_approach()
		game.special_meter.value = 100.0 # Explicit meter fixture; actual input/player gating follows.
		await launch()
		var event := InputEventAction.new()
		event.action = special
		event.pressed = true
		Input.parse_input_event(event)
		await frames(11)
		event.pressed = false
		Input.parse_input_event(event)
		check(not game.skater.special_name.is_empty(), "real " + special)
		await shot(special, true)
	print("RIG ACTION CAPTURE errors=", errors, " meshes=", count_meshes(game.skater), " bones=", game.skater._visual_rig._garments.skeleton.get_bone_count())
	quit(1 if errors else 0)
func fresh_approach() -> void:
	for action: String in ["push", "brake", "manual", "ollie", "grab", "flip", "revert"]:
		Input.action_release(action)
	game.restart_run()
	await frames(40)
	Input.action_press("push")
	await frames(35)
	Input.action_release("push")
func launch() -> void:
	Input.action_press("ollie")
	await frames(2)
	Input.action_release("ollie")
	check(game.skater.airborne, "actual launch")
func land() -> void:
	for i in 180:
		await frames(1)
		if not game.skater.airborne:
			return
	check(false, "landing bounded")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func shot(label: String, close: bool) -> void:
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	RenderingServer.force_draw(true, 1.0 / 60.0)
	print("RIG FRAME ", label, " speed=", game.skater.speed, " air=", game.skater.airborne,
		" grab=", game.skater._grab_remaining, " manual=", game.skater.manual_active,
		" revert=", game.skater._revert_pose_remaining, " special=", game.skater.special_name)
	check(root.get_texture().get_image().save_png("res://.local/rider-capture/" + label + "-chase.png") == OK, label + " chase saved")
	if close:
		game.hud.visible = false
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.position = game.skater.global_position + Vector3(2.3, 1.65, 2.65)
		camera.look_at(game.skater.global_position + Vector3(0, 0.82, 0))
		camera.fov = 40
		camera.current = true
		await process_frame
		RenderingServer.force_draw(true, 1.0 / 60.0)
		check(root.get_texture().get_image().save_png("res://.local/rider-capture/" + label + "-close.png") == OK, label + " close saved")
		if label == "idle":
			var rider: Node3D = game.skater._rider_visual
			var head: Node3D = game.skater._visual_rig._head
			var body_target: Vector3 = game.skater.global_position + Vector3(0, 0.86, 0)
			await inspection_view(camera, "idle-front", body_target - rider.global_basis.z * 3.15 + Vector3.UP * 0.12, body_target, 38)
			await inspection_view(camera, "idle-side", body_target + rider.global_basis.x * 3.15 + Vector3.UP * 0.12, body_target, 38)
			var face_target := head.to_global(Vector3(0, 0.02, -0.025))
			await inspection_view(camera, "idle-face", face_target - head.global_basis.z * 0.82, face_target, 35)
			await inspection_view(camera, "idle-profile", face_target + head.global_basis.x * 0.82, face_target, 35)
			var deck: Node3D = game.skater._board_visual
			await inspection_view(camera, "idle-feet", deck.to_global(Vector3(0.70, 0.38, 0.80)), deck.to_global(Vector3(0, 0.04, 0)), 38)
		if label == "grab":
			var hand: Node3D = game.skater._visual_rig._arms[0]["hand"]
			var deck: Node3D = game.skater._board_visual
			var contact := deck.to_global(Vector3(-0.128, 0.022, -0.035))
			print("RIG CONTACT palm_to_deck_m=", hand.to_global(Vector3(0, -0.075, -0.015)).distance_to(contact))
			await inspection_view(camera, "grab-hand", deck.to_global(Vector3(-0.72, 0.45, -0.40)), contact, 38)
		camera.queue_free()
		game.skater._camera.current = true
		game.hud.visible = true
	game.set_physics_process(true)
	game.skater.set_physics_process(true)
	game.skater.set_process(true)
func inspection_view(camera: Camera3D, label: String, from: Vector3, toward: Vector3, field_of_view: float) -> void:
	camera.global_position = from
	camera.look_at(toward)
	camera.fov = field_of_view
	await process_frame
	RenderingServer.force_draw(true, 1.0 / 60.0)
	check(root.get_texture().get_image().save_png("res://.local/rider-capture/" + label + ".png") == OK, label + " saved")
func check(value: bool, label: String) -> void:
	if not value:
		errors += 1
		push_error(label)
func count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += count_meshes(child)
	return count
