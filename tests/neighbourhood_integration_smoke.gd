extends SceneTree
## Consumer/lifecycle fixtures, not natural trick-route or art acceptance.
const Main = preload("res://game/main.gd")
const Catalog = preload("res://game/progression/level_catalog.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _world_count(game: Node) -> int:
	var count := 0
	for child: Node in game.get_children():
		if child.get_script() == null: continue
		for id: String in Catalog.ids():
			if child.get_script().resource_path == str(Catalog.definition(id).world_path): count += 1
	return count

func _run() -> void:
	var game = Main.new()
	game.persistence_enabled = false
	game.profile_path = "user://combined-selection-fixture.json"
	game.legacy_profile_path = ""
	_check(game.level_id == Catalog.DEFAULT_LEVEL and not game.persistence_enabled,
		"new Main defaults to Merchant with explicit profile isolation before tree entry")
	root.add_child(game)
	await _frames(8)
	_check(game.world.get_script().resource_path == Catalog.definition(Catalog.DEFAULT_LEVEL).world_path and _world_count(game) == 1,
		"default creates exactly one Merchant world without the legacy city")
	_check(game.career.selected_level_id == Catalog.DEFAULT_LEVEL and game.career.goals_snapshot().size() == 10,
		"actual Main begins the Merchant career domain with ten namespaced goals")
	_check(not game.music._persist and not game.music._can_control and not FileAccess.file_exists(game.profile_path),
		"default scene keeps personal Music and profile writes isolated")
	_check(game.skater.is_on_floor() and game.skater.global_position.distance_to(game.world.get_spawn_position()) < 0.2 and not game.skater.bailing,
		"ordinary Merchant spawn settles on its actual paving without a bail")
	_check(game.feature_hub.challenges().is_empty() and game.feature_hub.get_route_definitions().is_empty() and game.feature_hub.get_child_count() == 0,
		"empty activity layout constructs no old cart, gate, lap or cone actors")
	game.feature_hub.on_trick("Ollie", 100, game.skater.global_position, "ollie")
	game.feature_hub.on_landed(true)
	game.feature_hub.on_bank(100, game.skater.global_position)
	game.feature_hub.on_bail()
	game.feature_hub.finish_run()
	game.feature_hub.reset_run()
	_check(game.feature_hub.definitions_snapshot().vehicle.is_empty(),
		"all omitted-activity callbacks and snapshots are safe")
	var letter_label_ok := false
	for marker: Dictionary in game.objectives._markers:
		if marker.id != "md_letter_h": continue
		for child: Node in marker.node.get_children():
			if child is Label3D and child.text == "H": letter_label_ok = true
	_check(letter_label_ok and game._pickup_message({"kind":"letter","id":"md_letter_h","label":"H"}).begins_with("LETTER H"),
		"namespaced objective identity displays the human letter H")
	# Declared score-consumer fixture exercises Main's real bank callback; it is
	# intentionally not evidence of an ordinary-input trick or connected line.
	game.score.add_trick("Declared integration score fixture", 1500)
	game.score.begin_landing()
	await _frames(35)
	_check(game.career.completed_ids.has("md_first_shift") and game.career.best_score == 1500,
		"actual Main bank callback credits only the current Merchant record")
	game.apply_settings({"audio":0.4}, false)
	var music_id: int = game.music.get_instance_id()
	var audio_id: int = game.audio.get_instance_id()
	var old_world: WeakRef = weakref(game.world)
	var old_skater: WeakRef = weakref(game.skater)
	game.paused = true
	paused = true
	game.audio.set_paused(true)
	game.hud.show_title()
	await _frames(15)
	game.hud.show_levels()
	await _frames(15)
	_check(game.hud._page == "levels", "ordinary HUD opens its level-selection page")
	game.hud._choose_level(Catalog.LEGACY_LEVEL)
	_check(game.level_id == Catalog.DEFAULT_LEVEL, "level callback waits for the existing menu transition boundary")
	for i in 90:
		await _frames(1)
		if game.level_id == Catalog.LEGACY_LEVEL: break
	_check(game.level_id == Catalog.LEGACY_LEVEL and game.world.get_script().resource_path == Catalog.definition(Catalog.LEGACY_LEVEL).world_path and _world_count(game) == 1,
		"HUD selection lazily creates one City Tour world")
	_check(old_world.get_ref() == null and old_skater.get_ref() == null,
		"switch releases the previous world and skater instead of hiding them")
	_check(game.music.get_instance_id() == music_id and game.audio.get_instance_id() == audio_id,
		"world selection preserves existing Music and audio objects")
	var legacy_report: Dictionary = game.playtest_recorder.snapshot(true)
	_check(legacy_report.level_id == Catalog.LEGACY_LEVEL and legacy_report.level_name == "City Tour"
		and legacy_report.source_sha256["res://game/progression/level_career_book.gd"] == FileAccess.get_sha256("res://game/progression/level_career_book.gd"),
		"retained recorder identifies the new current level and career source")
	_check(game.career.completed_ids.is_empty() and game.career.best_score == 0 and game.career.unlocks().has("color_orange") and is_equal_approx(game.career.settings.audio, 0.4),
		"City Tour starts independently while genuine global unlocks and settings travel")
	_check(game.score.total_score == 0 and game.score.get_combo_value() == 0 and game.paused and game.hud._page == "title",
		"selected level returns to title with a clean score chain")
	game.start_mode(false)
	game.score.add_trick("Declared legacy integration score fixture", 6000)
	game.score.begin_landing()
	await _frames(35)
	_check(game.career.completed_ids.has("first_shift") and game.career.completed_ids.has("good_shift") and game.career.best_score == 6000,
		"City Tour retains the existing career event semantics")
	game.change_level(Catalog.DEFAULT_LEVEL)
	await _frames(8)
	_check(_world_count(game) == 1 and game.career.selected_level_id == Catalog.DEFAULT_LEVEL and game.career.best_score == 1500 and game.career.completed_ids.has("md_first_shift") and not game.career.completed_ids.has("first_shift"),
		"switching back restores Merchant progress without borrowing old goal clears")
	_check(game.world.get_script().resource_path == Catalog.definition(Catalog.DEFAULT_LEVEL).world_path and game.skater._grind_lines.size() == game.world.get_grind_lines().size(),
		"returned Merchant skater receives only the current world's grind registry")
	var returned_report: Dictionary = game.playtest_recorder.snapshot(false)
	_check(returned_report.level_id == Catalog.DEFAULT_LEVEL and returned_report.level_name == "Merchant District",
		"mixed-level recorder history returns to Merchant without stale identity")
	_check(not game.persistence_enabled and not FileAccess.file_exists(game.profile_path),
		"the full lifecycle never writes the isolated or ordinary profile")
	paused = false
	game.free()
	await process_frame
	print("NEIGHBOURHOOD RESULT: ", passed, " passed, ", failed, " failed")
	quit(1 if failed else 0)
