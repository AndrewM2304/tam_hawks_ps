extends RefCounted
## Production Main/HUD cache contracts: immediate changes and detached snapshots.

const Career = preload("res://game/progression/career_progress.gd")
const InputProfile = preload("res://game/core/input_profile.gd")

class CountingCareer extends Career:
	var goal_reads := 0
	var unlock_reads := 0
	func goals_snapshot() -> Array[Dictionary]:
		goal_reads += 1
		return super.goals_snapshot()
	func unlocks() -> Array[String]:
		unlock_reads += 1
		return super.unlocks()


static func run(_tree: SceneTree, game: Node, check: Callable) -> void:
	_loaded_career_revision(check)
	var original_career = game.career
	var original_spawn: Vector3 = game.skater.spawn_position
	var original_mode: bool = game.free_skate_mode
	game.persistence_enabled = false
	game.career = CountingCareer.new()
	game.apply_settings(game.career.settings, false)
	game.start_mode(false)
	game._refresh_hud()
	var goals_before: int = game.career.goal_reads
	var unlocks_before: int = game.career.unlock_reads
	for index in 30: game._refresh_hud()
	check.call(game.career.goal_reads == goals_before and game.career.unlock_reads == unlocks_before,
		"HUD efficiency: unchanged refreshes reuse career snapshots without weakening their copy boundary")
	game.career.record_event("letter", "H")
	game._refresh_hud()
	check.call(_goal(game.hud._state.goals, "letters").progress == 1
		and game.career.goal_reads == goals_before + 1,
		"HUD efficiency: a public collection event updates goal progress on the very next explicit refresh")
	game.career.completed_ids.append("first_shift")
	game._refresh_hud()
	check.call(_goal(game.hud._state.goals, "first_shift").done
		and game.hud._state.unlocks.has("color_orange") and game.hud._goals.text.begins_with("1 / 10"),
		"HUD efficiency: direct completed-ID edits invalidate both goals and unlocks")
	game.career.begin_run(false)
	game._refresh_hud()
	check.call(_goal(game.hud._state.goals, "letters").progress == 0,
		"HUD efficiency: starting a fresh career run clears cached collection progress")
	game.career.record_score(15000, 3000)
	game._refresh_hud()
	check.call(_goal(game.hud._state.goals, "some_shift").done
		and game.hud._state.unlocks.has("special_tenement_tumble") and game.hud._state.record_score == 15000,
		"HUD efficiency: a bank immediately refreshes completed goals, new rewards and record text")
	var revision: int = game.career.presentation_revision()
	game.career.record_event("letter", "H")
	var after_event: int = game.career.presentation_revision()
	game.career.record_event("letter", "H")
	check.call(after_event > revision and game.career.presentation_revision() == after_event,
		"HUD efficiency: an accepted new event changes presentation while a duplicate event creates no revision churn")
	var detached: Dictionary = game.hud._state.duplicate(true)
	detached["fixture"] = {"items": [{"value": 1}]}
	game.hud.update_display(detached)
	detached.fixture.items[0].value = 2
	detached.goals[0].title = "CALLER EDIT"
	detached.settings.ui_scale = 1.2
	check.call(game.hud._state.fixture.items[0].value == 1
		and game.hud._state.goals[0].title != "CALLER EDIT" and game.hud._settings.ui_scale == 1.0,
		"HUD efficiency: nested state arrays/dictionaries and editable settings remain detached from callers")
	game.hud.update_display(detached)
	check.call(game.hud._state.fixture.items[0].value == 2
		and game.hud._state.goals[0].title == "CALLER EDIT" and game.hud._settings.ui_scale == 1.2,
		"HUD efficiency: changed nested values are accepted immediately after an earlier cached snapshot")
	game._refresh_hud()
	check.call(not game.hud._state.has("fixture") and game.hud._state.goals[0].title != "CALLER EDIT"
		and game.career.goals_snapshot()[0].title != "CALLER EDIT",
		"HUD efficiency: refreshing production data discards removed fields and caller edits cannot corrupt career data")
	var at: Vector3 = game.encounters.status_snapshot().position
	game.skater.global_position = at + Vector3(1, 0, 0)
	game.encounters.poll(game.skater.global_position, true, 0.0, 0)
	game._refresh_hud()
	var challenge: String = game.hud._challenge.text
	game.encounters.poll(game.skater.global_position, false, 1.2, 0)
	game._refresh_hud()
	check.call(challenge.contains("MO") and game.hud._challenge.text != challenge,
		"HUD efficiency: active encounter start and elapsed-time text update without a refresh throttle")
	game._on_encounter_feedback("A FRESH CHALLENGE NOTICE")
	game._refresh_hud()
	check.call(game.hud._feedback.text == "A FRESH CHALLENGE NOTICE",
		"HUD efficiency: new encounter feedback reaches the live event card immediately")
	game.skater.manual_active = true
	game.skater.manual_balance = 0.4
	game._refresh_hud()
	var marker_x: float = game.hud._balance_marker.position.x
	game.skater.manual_balance = -0.4
	game._refresh_hud()
	check.call(game.hud._balance_marker.position.x < marker_x - 100.0,
		"HUD efficiency: each balance change moves the correction marker in the same call")
	game.skater.manual_active = false
	game.encounters.reset_run()
	game.apply_settings({"captions": false, "ui_scale": 1.2,
		"bindings": {"interact": {"key": KEY_PAGEDOWN, "button": JOY_BUTTON_LEFT_STICK}}}, false)
	game._caption = "SHOULD BE HIDDEN"
	game._caption_time = 2.0
	game.hud._controller_active = false
	game._refresh_hud()
	check.call(game.hud._prompt.text.begins_with("PageDown") and game.hud._caption.text.is_empty()
		and game.hud._settings.ui_scale == 1.2,
		"HUD efficiency: remapped key, captions and UI-scale changes invalidate their cached presentation")
	game.hud._settings.captions = true
	game._refresh_hud()
	check.call(not game.hud._settings.captions,
		"HUD efficiency: authoritative settings restore a rejected local preference even when the source snapshot is unchanged")
	game.hud._controller_active = true
	game._refresh_hud()
	check.call(game.hud._prompt.text.begins_with("L3"),
		"HUD efficiency: controller-device changes refresh prompts even when the game snapshot is unchanged")
	game.toggle_pause()
	check.call(game.paused and game.hud._page == "pause" and game.hud._state.paused,
		"HUD efficiency: explicit pause refresh still opens the menu in the same call")
	game.hud.hide_menu()
	game._refresh_hud()
	check.call(game.hud._page == "pause",
		"HUD efficiency: an explicit unchanged-state refresh still reconciles a required menu transition")
	game.toggle_pause()
	check.call(not game.paused and game.hud._page == "",
		"HUD efficiency: explicit resume immediately restores the live HUD")
	game.run_finished = true
	game._refresh_hud()
	check.call(game.hud._page == "results" and game.hud._state.finished,
		"HUD efficiency: run completion immediately opens current results")
	game.hud.hide_menu()
	game.career = original_career
	game.skater.spawn_position = original_spawn
	game.apply_settings(original_career.settings, false)
	game.hud._controller_active = false
	game.start_mode(original_mode)
	check.call(game.hud._state.goals == original_career.goals_snapshot() and not game.persistence_enabled,
		"HUD efficiency: replacing the career object invalidates cache and the review writes no profile")


static func _goal(goals: Array, id: String) -> Dictionary:
	for goal: Dictionary in goals:
		if goal.id == id: return goal
	return {}


static func _loaded_career_revision(check: Callable) -> void:
	# This disposable regression fixture never reads/writes the player's profile.
	var path := ProjectSettings.globalize_path("res://.local/hud-revision-%d.json" % Time.get_ticks_usec())
	var source = Career.new()
	source.begin_run(false)
	source.record_score(5000, 1500)
	var written: Error = source.save_profile(path)
	check.call(written == OK, "HUD efficiency: disposable career-load fixture is writable")
	if written == OK:
		var loaded = Career.new()
		var before: int = loaded.presentation_revision()
		var result: Error = loaded.load_profile(path)
		check.call(result == OK and loaded.presentation_revision() > before
			and _goal(loaded.goals_snapshot(), "good_shift").done,
			"HUD efficiency: loading saved completed goals invalidates presentation revision on the same career object")
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
