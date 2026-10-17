extends "res://tools/rider_capture.gd"
## A deterministic normal-speed input replay: 60 Hz physics sampled into 30 fps images.
## Resets between labelled cuts and full-meter fixtures for the two specials are explicit.
var recording := false
var video_frame := 0
var physics_tick := 0
var cuts: Array[Dictionary] = []
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rider motion capture requires a rendering display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://.local/rider-motion-frames")
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	if not is_instance_valid(game.skater) or not is_instance_valid(game.hud):
		push_error("Rider motion capture requires a fully initialized Main scene.")
		quit(1)
		return
	game.start_mode(true)
	await frames(40)
	cut("Push, foot-drag brake, coast")
	Input.action_press("push")
	await frames(90)
	Input.action_release("push")
	Input.action_press("brake")
	await frames(20)
	Input.action_release("brake")
	await frames(20)
	recording = false
	await fresh_approach()
	cut("Ollie, grab, landing recovery")
	await launch()
	Input.action_press("grab")
	await frames(18)
	Input.action_release("grab")
	await land()
	await frames(22)
	recording = false
	await fresh_approach()
	cut("Manual, ollie, flip, landing, revert")
	Input.action_press("manual")
	await frames(24)
	check(game.skater.manual_active, "motion manual active")
	Input.action_release("manual")
	await launch()
	Input.action_press("flip")
	await frames(12)
	Input.action_release("flip")
	await land()
	Input.action_press("revert")
	await frames(6)
	Input.action_release("revert")
	check(game.skater._revert_pose_remaining > 0, "motion revert active")
	await frames(26)
	recording = false
	for special: String in ["special_one", "special_two"]:
		await fresh_approach()
		game.special_meter.value = 100.0
		cut(special + " (meter fixture: 100)")
		await launch()
		var event := InputEventAction.new()
		event.action = special
		event.pressed = true
		Input.parse_input_event(event)
		await frames(10)
		event.pressed = false
		Input.parse_input_event(event)
		check(not game.skater.special_name.is_empty(), "motion " + special + " accepted")
		await land()
		await frames(18)
		recording = false
	var file := FileAccess.open("res://.local/rider-motion-sequence.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"fps": 30, "physics_hz": 60, "frames": video_frame,
		"duration": float(video_frame) / 30.0, "cuts": cuts, "errors": errors}, "\t"))
	var frame_count := FileAccess.open("res://.local/rider-motion-frame-count.txt", FileAccess.WRITE)
	frame_count.store_line(str(video_frame))
	print("RIG MOTION frames=", video_frame, " duration=", float(video_frame) / 30.0, " errors=", errors)
	quit(1 if errors else 0)
func cut(label: String) -> void:
	cuts.append({"at_seconds": float(video_frame) / 30.0, "label": label})
	print("RIG MOTION CUT ", float(video_frame) / 30.0, " ", label)
	recording = true
	physics_tick = 0
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
		physics_tick += 1
		if recording and physics_tick % 2 == 0:
			RenderingServer.force_draw(true, 1.0 / 30.0)
			var path := "res://.local/rider-motion-frames/%05d.png" % video_frame
			check(root.get_texture().get_image().save_png(path) == OK, "motion frame saved")
			video_frame += 1
