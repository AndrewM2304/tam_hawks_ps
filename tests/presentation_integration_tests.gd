extends RefCounted
## Real floor-contact audio and player-facing objective/save feedback.
const CareerSource = preload("res://game/progression/career_progress.gd")

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original_career = game.career
	var original_spawn: Vector3 = game.skater.spawn_position
	var original_path: String = game.profile_path
	game.persistence_enabled = false
	game.career = CareerSource.new()
	game.start_mode(false)
	await _frames(tree, 35)
	check.call(game.audio.get_debug_state().surface == "stone",
		"presentation: real square floor selects stone wheel sound")
	check.call(not "ROYAL_EXCHANGE" in game._feedback and "EXCHANGE SQUARE" in game._feedback,
		"presentation: district welcome uses a readable location, not its internal ID")
	check.call(game.objectives.get_child_count() == 10,
		"presentation: district visits do not leave misleading collectible orbs")
	game.skater.spawn_position = Vector3(40, 0.8, 22)
	game.restart_run()
	await _frames(tree, 35)
	Input.action_press("push")
	await _frames(tree, 6)
	Input.action_release("push")
	check.call(game.audio.get_debug_state().surface == "asphalt",
		"presentation: real connector floor contact selects asphalt wheel sound")
	game.skater.spawn_position = original_spawn
	game.restart_run()
	await _frames(tree, 35)
	Input.action_press("push")
	var metal_heard := false
	for i in 150:
		await _frames(tree, 1)
		metal_heard = metal_heard or game.audio.get_debug_state().surface == "metal"
	Input.action_release("push")
	check.call(metal_heard, "presentation: actual ramp approach selects painted-metal wheel sound")
	# Collect using the production tracker; rendering and count use the same event.
	game.restart_run()
	game.objectives.poll(Vector3(0, 0.9, -20), false)
	check.call(game._pickup_message({"kind": "letter", "id": "H"}) == "LETTER H  /  1 OF 5",
		"presentation: pickup feedback reports the actual run collection count")
	game._notify_goals(["letters"])
	check.call(game._feedback == "GOAL COMPLETE  /  LETTERS ROUND THE SQUARE",
		"presentation: completed goals display their authored player-facing titles")
	game._notify_goals(["first_shift", "good_shift", "some_shift", "one_long_line"])
	check.call(game._feedback == "GOAL COMPLETE  /  FIRST SHIFT  +3 MORE",
		"presentation: simultaneous goals use bounded readable feedback")
	var fixture := "res://.local/presentation-profile-%d.json" % Time.get_ticks_usec()
	var preserved := '{"version":999}'
	var file := FileAccess.open(fixture, FileAccess.WRITE)
	file.store_string(preserved)
	file.close()
	game.career.load_profile(fixture)
	game.profile_path = fixture
	game.persistence_enabled = true
	game._save_profile()
	check.call(not game.save_warning.is_empty() and FileAccess.get_file_as_string(fixture) == preserved,
		"presentation: real protected-save failure exposes a warning and preserves file bytes")
	game.persistence_enabled = false
	game.profile_path = original_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))
	game.save_warning = ""
	game.save_status = ""
	game.career = original_career
	game.skater.spawn_position = original_spawn
	game.start_mode(false)

static func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
