extends RefCounted
## Local fixtures only: never read/write the real user:// profile during tests.
const Career = preload("res://game/progression/career_progress.gd")

static func run(check: Callable) -> void:
	_test_goals(check)
	var fixture := ProjectSettings.globalize_path("res://.local/progression-tests-%d" % Time.get_ticks_usec())
	var directory_error := DirAccess.make_dir_recursive_absolute(fixture)
	check.call(directory_error == OK, "career persistence: unique local fixture directory is writable")
	if directory_error != OK:
		return
	_test_roundtrip_and_backup(check, fixture)
	_test_validation_and_migration(check, fixture)
	_test_write_protection(check, fixture)
	_test_bindings_and_cosmetics(check, fixture)
	_remove_fixture(fixture)

static func _test_goals(check: Callable) -> void:
	var career = Career.new()
	check.call(career.goals_snapshot().size() == 10 and career.completed_ids.is_empty(),
		"career: a new profile has exactly ten incomplete goals")
	check.call(career.unlocks() == ["color_blue"] and career.best_score == 0,
		"career: a fresh profile provides its base colour without locking basic skating")
	check.call(career.record_score(15000, 3000).is_empty()
		and career.record_event("interaction", "cone").is_empty(),
		"career: events before an active run cannot award progress")
	career.begin_run(false)
	check.call(career.record_score(999, 999).is_empty(),
		"career: the first score goal rejects a value one point below its threshold")
	check.call(career.record_score(1000, 500) == ["first_shift"],
		"career: banking the first threshold completes its goal exactly once")
	check.call(career.record_score(1000, 500).is_empty() and career.best_combo == 999,
		"career: repeated score events cannot duplicate rewards or lower a record")
	check.call(career.unlocks().has("color_orange") and career.unlocks().has("special_clyde_carousel")
		and not career.unlocks().has("special_tenement_tumble"),
		"career: first score unlocks only the first special and its cosmetic reward")
	career.record_event("letter", "H")
	career.record_event("letter", "H")
	career.record_event("letter", "invalid")
	check.call(_goal(career, "letters")["progress"] == 1,
		"career: duplicate and unknown collectible events cannot inflate progress")
	career.record_event("letter", "A")
	career.begin_run(false)
	for letter: String in ["W", "K", "S"]:
		career.record_event("letter", letter)
	check.call(_goal(career, "letters")["progress"] == 3 and not career.completed_ids.has("letters"),
		"career: partial collection resets between runs instead of accumulating across them")
	career.record_event("letter", "H")
	check.call(career.record_event("letter", "A") == ["letters"]
		and career.record_event("letter", "A").is_empty(),
		"career: all five unique HAWKS letters complete one goal once")
	career.begin_run(false)
	check.call(_goal(career, "letters")["done"] and _goal(career, "letters")["progress"] == 5,
		"career: completed goals remain completed after per-run state resets")
	check.call(career.record_score(3000, 2999).is_empty(),
		"career: combo goal uses a banked single combo rather than total score")
	check.call(career.record_score(3000, 3000) == ["one_long_line"]
		and career.unlocks().has("special_tenement_tumble"),
		"career: the combo threshold unlocks its separate special once")
	check.call(career.record_score(5000, 3000) == ["good_shift"]
		and career.record_score(15000, 3000) == ["some_shift"],
		"career: intermediate and advanced score thresholds complete independently")
	check.call(career.unlocks().has("color_purple"),
		"career: advanced score completion unlocks the third cosmetic colour")
	check.call(career.record_event("interaction", "unknown").is_empty()
		and career.record_event("gap", "unknown").is_empty()
		and career.record_event("unknown", "cone").is_empty(),
		"career: unrecognized event kinds and target IDs cannot complete goals")
	check.call(career.record_event("interaction", "cone") == ["cone"]
		and career.record_event("gap", "central_gap") == ["platform_change"],
		"career: validated cone and Central gap events complete their distinct goals")
	for item: String in Career.MARKET_IDS:
		career.record_event("market_item", item)
	for district: String in Career.DISTRICT_IDS:
		career.record_event("district", district)
	check.call(career.completed_ids.has("market_sweep") and career.completed_ids.has("across_toon"),
		"career: three market items and four distinct districts complete their respective goals")
	check.call(career.record_event("collectible", "secret_recording") == ["lost_recording"]
		and career.completed_ids.size() == 10,
		"career: the secret recording makes all ten authored goals achievable through their events")
	var snapshot: Array[Dictionary] = career.goals_snapshot()
	snapshot[0]["done"] = false
	check.call(_goal(career, "first_shift")["done"],
		"career: HUD snapshot edits cannot alter persistent completion")
	career.finish_run(16000, 4000)
	check.call(career.finish_run(99999, 99999).is_empty() and career.best_score == 16000
		and career.record_event("interaction", "cone").is_empty(),
		"career: finishing closes event admission and duplicate results cannot rewrite records")
	var free = Career.new()
	free.begin_run(true)
	free.record_score(15000, 3000)
	for letter: String in Career.LETTER_IDS:
		free.record_event("letter", letter)
	free.record_event("interaction", "cone")
	free.finish_run(99999, 99999)
	check.call(free.completed_ids.is_empty() and free.best_score == 0 and free.best_combo == 0
		and _goal(free, "letters")["progress"] == 0,
		"career: free skate cannot award career goals, partial collections or records")
	var invalid = Career.new()
	invalid.begin_run(false)
	invalid.record_score(-100, 3000)
	check.call(invalid.best_score == 0 and invalid.best_combo == 0 and invalid.completed_ids.is_empty(),
		"career: negative scores and impossible larger combos cannot manufacture records")

static func _test_roundtrip_and_backup(check: Callable, fixture: String) -> void:
	var path := fixture.path_join("roundtrip.json")
	var career = Career.new()
	check.call(career.load_profile(path) == ERR_FILE_NOT_FOUND,
		"career persistence: a missing profile is a first-run state without an overwrite lock")
	career.begin_run(false)
	career.record_score(2000, 1200)
	career.settings["audio"] = 4.0
	career.settings["ui_scale"] = 2.0
	career.settings["camera_sensitivity"] = 0.0
	career.settings["captions"] = false
	career.settings["reduced_motion"] = true
	check.call(career.save_profile(path) == OK and FileAccess.file_exists(path),
		"career persistence: a first profile is written and verified successfully")
	var loaded = Career.new()
	check.call(loaded.load_profile(path) == OK and loaded.best_score == 2000
		and loaded.best_combo == 1200 and loaded.completed_ids == ["first_shift"],
		"career persistence: completion and records survive a new instance load")
	check.call(loaded.settings["audio"] == 1.0 and loaded.settings["ui_scale"] == 1.4
		and loaded.settings["camera_sensitivity"] == 0.5 and not loaded.settings["captions"]
		and loaded.settings["reduced_motion"],
		"career persistence: finite setting values clamp to supported bounds while booleans survive")
	check.call(loaded.record_event("interaction", "cone").is_empty()
		and loaded.unlocks() == career.unlocks(),
		"career persistence: loading restores derived unlocks without admitting a phantom active run")
	loaded.begin_run(false)
	loaded.record_score(6000, 3500)
	check.call(loaded.save_profile(path) == OK and FileAccess.file_exists(path + ".bak"),
		"career persistence: replacing a profile creates a verified prior-generation backup")
	var backup = Career.new()
	check.call(backup.load_profile(path + ".bak") == OK and backup.best_score == 2000,
		"career persistence: backup contains the previous good profile rather than the new write")
	loaded.record_score(16000, 4000)
	check.call(loaded.save_profile(path) == OK,
		"career persistence: a third save atomically replaces both existing primary and backup")
	_write_text(path, "{broken")
	var recovered = Career.new()
	check.call(recovered.load_profile(path) == OK and recovered.last_load_used_backup
		and recovered.best_score == 6000,
		"career persistence: corrupt primary recovers the most recent valid backup")
	var backup_before := FileAccess.get_file_as_string(path + ".bak")
	check.call(recovered.save_profile(path) == OK
		and FileAccess.get_file_as_string(path + ".bak") == backup_before,
		"career persistence: saving recovered data does not replace a good backup with corrupt bytes")
	_write_text(path + ".tmp", "{interrupted-write")
	check.call(Career.new().load_profile(path) == OK,
		"career persistence: an interrupted temporary write cannot shadow a valid primary")
	DirAccess.remove_absolute(path)
	var missing_primary = Career.new()
	check.call(missing_primary.load_profile(path) == OK and missing_primary.last_load_used_backup
		and missing_primary.save_profile(path) == OK,
		"career persistence: missing primary can recover and safely restore its existing backup")

static func _test_validation_and_migration(check: Callable, fixture: String) -> void:
	var valid := {"version": 1, "completed_ids": ["first_shift", "first_shift", "unknown_future_goal"],
		"best_score": 1200, "best_combo": 1000, "settings": {"unknown_option": {"anything": true}},
		"unknown_root_key": [1, 2, 3]}
	var path := fixture.path_join("unknowns.json")
	_write_json(path, valid)
	var career = Career.new()
	check.call(career.load_profile(path) == OK and career.completed_ids == ["first_shift"]
		and career.settings == Career.DEFAULT_SETTINGS,
		"career persistence: unknown keys and goal names are ignored, duplicates deduplicate and settings default")
	var legacy_path := fixture.path_join("legacy.json")
	_write_json(legacy_path, {"version": 0, "completed_goals": ["cone"], "high_score": 2100, "best_combo": 1500})
	var legacy = Career.new()
	check.call(legacy.load_profile(legacy_path) == OK and legacy.completed_ids == ["cone"]
		and legacy.best_score == 2100 and legacy.settings == Career.DEFAULT_SETTINGS,
		"career persistence: explicit version-zero fields migrate to the current in-memory schema")
	check.call(legacy.save_profile(legacy_path) == OK
		and int(JSON.parse_string(FileAccess.get_file_as_string(legacy_path))["version"]) == 1,
		"career persistence: saving a migrated profile writes version one while preserving a backup")
	var bad_cases: Array = [
		null, [], {}, {"version": "1"}, {"version": -1},
		_override(valid, "best_score", -1), _override(valid, "best_score", 1.5),
		_override(valid, "best_score", Career.MAX_SCORE + 1), _override(valid, "best_combo", 5000),
		_override(valid, "completed_ids", [123]), _override(valid, "settings", []),
		_override(valid, "settings", {"captions": "true"}),
		_override(valid, "settings", {"audio": "loud"}),
	]
	var all_rejected := true
	for index: int in bad_cases.size():
		var invalid_path := fixture.path_join("invalid-%d.json" % index)
		_write_json(invalid_path, bad_cases[index])
		var invalid = Career.new()
		all_rejected = all_rejected and invalid.load_profile(invalid_path) == ERR_FILE_CORRUPT
	check.call(all_rejected,
		"career persistence: malformed structures, versions, scores, goal IDs and setting types reject safely")
	var oversized_path := fixture.path_join("oversized.json")
	_write_text(oversized_path, " ".repeat(Career.MAX_PROFILE_BYTES + 1))
	check.call(Career.new().load_profile(oversized_path) == ERR_FILE_CORRUPT,
		"career persistence: oversized files reject before unrestricted parsing")
	check.call(Career.new().load_profile("") == ERR_INVALID_PARAMETER
		and Career.new().save_profile("") == ERR_INVALID_PARAMETER,
		"career persistence: empty paths do not resolve to a directory or real default profile")

static func _test_write_protection(check: Callable, fixture: String) -> void:
	var future_path := fixture.path_join("future.json")
	var future_text := '{"version":99,"owner_data":"must survive"}'
	_write_text(future_path, future_text)
	_write_json(future_path + ".bak", {"version": 1, "completed_ids": [], "best_score": 0,
		"best_combo": 0, "settings": {}})
	var future = Career.new()
	future.begin_run(false)
	future.record_score(5000, 1000)
	check.call(future.load_profile(future_path) == ERR_UNAVAILABLE and future.best_score == 5000
		and not future.last_load_used_backup,
		"career persistence: a future primary version preserves memory and cannot downgrade through its older backup")
	check.call(future.save_profile(future_path) == ERR_UNAVAILABLE
		and Career.new().save_profile(future_path) == ERR_UNAVAILABLE
		and FileAccess.get_file_as_string(future_path) == future_text,
		"career persistence: both loaded and fresh instances refuse to overwrite future-version data")
	var broken_path := fixture.path_join("broken.json")
	_write_text(broken_path, "{unrecoverable")
	var broken = Career.new()
	check.call(broken.load_profile(broken_path) == ERR_FILE_CORRUPT
		and broken.save_profile(broken_path) == ERR_FILE_CORRUPT
		and FileAccess.get_file_as_string(broken_path) == "{unrecoverable",
		"career persistence: unrecoverable data locks saving and is preserved byte for byte")
	var orphan_path := fixture.path_join("orphan.json")
	_write_text(orphan_path + ".bak", "{broken-backup")
	check.call(Career.new().save_profile(orphan_path) != OK and not FileAccess.file_exists(orphan_path),
		"career persistence: a missing primary cannot silently overwrite an unread backup")
	var future_backup_path := fixture.path_join("future-backup.json")
	_write_text(future_backup_path + ".bak", future_text)
	check.call(Career.new().load_profile(future_backup_path) == ERR_UNAVAILABLE
		and Career.new().save_profile(future_backup_path) == ERR_UNAVAILABLE,
		"career persistence: a newer orphan backup is protected from fresh-profile replacement")
	var valid_with_future_backup := fixture.path_join("valid-with-future-backup.json")
	var valid_primary = Career.new()
	valid_primary.save_profile(valid_with_future_backup)
	_write_text(valid_with_future_backup + ".bak", future_text)
	check.call(valid_primary.load_profile(valid_with_future_backup) == OK
		and valid_primary.save_profile(valid_with_future_backup) == ERR_UNAVAILABLE
		and FileAccess.get_file_as_string(valid_with_future_backup + ".bak") == future_text,
		"career persistence: a valid older primary cannot overwrite a newer-version backup")
	var valid_with_future_temp := fixture.path_join("valid-with-future-temp.json")
	var temporary_owner = Career.new()
	temporary_owner.save_profile(valid_with_future_temp)
	_write_text(valid_with_future_temp + ".tmp", future_text)
	check.call(temporary_owner.save_profile(valid_with_future_temp) == ERR_UNAVAILABLE
		and FileAccess.get_file_as_string(valid_with_future_temp + ".tmp") == future_text,
		"career persistence: a pending newer-version temporary profile is preserved")
	check.call(future.recover_profile(future_path) == OK and future.best_score == 0
		and future.completed_ids.is_empty(),
		"career persistence: explicit recovery resets memory only after archiving existing data")
	var preserved_future := false
	for filename: String in DirAccess.get_files_at(fixture):
		if filename.begins_with("future.json.recovery-"):
			preserved_future = FileAccess.get_file_as_string(fixture.path_join(filename)) == future_text
	check.call(preserved_future and Career.new().load_profile(future_path) == OK,
		"career persistence: explicit recovery retains the exact future-version file beside a valid new profile")
	var blocked_parent := fixture.path_join("not-a-directory")
	_write_text(blocked_parent, "preserve parent")
	check.call(Career.new().save_profile(blocked_parent.path_join("career.json")) != OK
		and FileAccess.get_file_as_string(blocked_parent) == "preserve parent",
		"career persistence: directory/write failures preserve existing files")
	var backup_block_path := fixture.path_join("backup-block.json")
	var existing = Career.new()
	existing.save_profile(backup_block_path)
	var existing_bytes := FileAccess.get_file_as_string(backup_block_path)
	DirAccess.make_dir_recursive_absolute(backup_block_path + ".bak")
	existing.begin_run(false)
	existing.record_score(5000, 2000)
	check.call(existing.save_profile(backup_block_path) != OK
		and FileAccess.get_file_as_string(backup_block_path) == existing_bytes,
		"career persistence: failed backup replacement cannot replace the valid primary")
	var invalid_memory_path := fixture.path_join("invalid-memory.json")
	var invalid_memory = Career.new()
	invalid_memory.save_profile(invalid_memory_path)
	var valid_bytes := FileAccess.get_file_as_string(invalid_memory_path)
	invalid_memory.settings["audio"] = NAN
	check.call(invalid_memory.save_profile(invalid_memory_path) == ERR_INVALID_DATA
		and FileAccess.get_file_as_string(invalid_memory_path) == valid_bytes,
		"career persistence: nonfinite in-memory settings cannot corrupt an existing save")

static func _test_bindings_and_cosmetics(check: Callable, fixture: String) -> void:
	var path := fixture.path_join("bindings-cosmetics.json")
	var career = Career.new()
	career.begin_run(false)
	career.record_score(15000, 3000)
	career.settings["bindings"] = {"flip": {"key": KEY_Z}, "grind": {"axis": JOY_AXIS_RIGHT_X, "axis_value": -1.0}}
	career.settings["cosmetic_id"] = "color_purple"
	check.call(career.save_profile(path) == OK, "career settings: known bindings and earned cosmetic save successfully")
	var loaded = Career.new()
	check.call(loaded.load_profile(path) == OK and loaded.settings["bindings"] == career.settings["bindings"]
		and loaded.settings["cosmetic_id"] == "color_purple",
		"career settings: numeric binding overrides and earned selected colour round-trip")
	var unearned_path := fixture.path_join("unearned-cosmetic.json")
	_write_json(unearned_path, {"version": 1, "completed_ids": [], "best_score": 0, "best_combo": 0,
		"settings": {"cosmetic_id": "color_purple"}})
	var unearned = Career.new()
	check.call(unearned.load_profile(unearned_path) == OK and unearned.settings["cosmetic_id"] == "color_blue",
		"career settings: loading an unearned known colour safely selects the unlocked base colour")
	loaded.settings["bindings"] = {"execute_script": {"key": KEY_Z}}
	check.call(loaded.save_profile(path) == ERR_INVALID_DATA,
		"career settings: an unknown binding action cannot enter a saved profile")
	loaded.settings["bindings"] = {"flip": {"key": KEY_Z}, "grab": {"key": KEY_Z}}
	check.call(loaded.save_profile(path) == ERR_INVALID_DATA,
		"career settings: duplicate explicit binding assignments reject before writing")
	loaded.settings["bindings"] = {}
	loaded.settings["cosmetic_id"] = "downloaded_unknown_colour"
	check.call(loaded.save_profile(path) == ERR_INVALID_DATA,
		"career settings: unknown cosmetic IDs reject rather than loading external data")

static func _goal(career: RefCounted, id: String) -> Dictionary:
	for goal: Dictionary in career.goals_snapshot():
		if goal["id"] == id:
			return goal
	return {}

static func _override(original: Dictionary, key: String, value: Variant) -> Dictionary:
	var result := original.duplicate(true)
	result[key] = value
	return result

static func _write_json(path: String, value: Variant) -> void:
	_write_text(path, JSON.stringify(value))

static func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "Fixture write failed: " + path)
	file.store_string(content)
	file.close()

static func _remove_fixture(path: String) -> void:
	for file: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	for directory: String in DirAccess.get_directories_at(path):
		_remove_fixture(path.path_join(directory))
	DirAccess.remove_absolute(path)
