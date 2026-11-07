extends RefCounted
## Per-world local progress. No world, audio, Music or scene is loaded here.
const Base = preload("res://game/progression/career_progress.gd")
const Catalog = preload("res://game/progression/level_catalog.gd")
const PROFILE_VERSION := 2
const MAX_SCORE := Base.MAX_SCORE
const MAX_PROFILE_BYTES := Base.MAX_PROFILE_BYTES
const DEFAULT_PATH := "user://career-v2.json"
const LEGACY_PATH := "user://career.json"
const DEFAULT_SETTINGS := Base.DEFAULT_SETTINGS
const SUFFIXES: Array[String] = ["", ".bak", ".tmp", ".bak.tmp"]
const UNLOCK_ORDER: Array[String] = ["color_blue", "color_orange", "special_clyde_carousel", "color_purple", "special_tenement_tumble"]

# Writable compatibility fields: callers may replace arrays/dictionaries as well
# as mutate them. They always represent the currently selected level.
var completed_ids: Array[String] = []
var best_score: int = 0
var best_combo: int = 0
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var last_error: String = ""
var last_load_used_backup: bool = false
var last_load_migrated_legacy: bool = false
var selected_level_id: String = Catalog.DEFAULT_LEVEL
var _levels: Dictionary = {}
var _legacy = Base.new()
var _run_active := false
var _free_skate := false
var _run_score := 0
var _run_combo := 0
var _collections: Dictionary = {}
var _blocked_paths: Dictionary = {}
var _loaded_signatures: Dictionary = {}
var _protected_legacy: Dictionary = {}
var _revision := 0
var _generation := 0
var _shown_generation := -1
var _shown_legacy := -1
var _shown_score := -1
var _shown_combo := -1
var _shown_completed: Array[String] = []
var _shown_collections: Dictionary = {}

func _init() -> void:
	for id: String in Catalog.ids(): _levels[id] = _empty_record()
	_protect_legacy(LEGACY_PATH)

func configure_level(manifest_career: Dictionary) -> bool:
	var id: String = str(manifest_career.get("level_id", ""))
	# Runtime metadata has one canonical source, not a second mutable goal table.
	return id in Catalog.ids() and manifest_career == Catalog.career(id)

func level_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in Catalog.ids(): result.append(Catalog.definition(id))
	return result

func select_level(id: String) -> bool:
	if id not in Catalog.ids(): return false
	_stash_active()
	_clear_run()
	selected_level_id = id
	_restore_active()
	_generation += 1
	return true

func begin_run(free_skate: bool) -> void:
	_clear_run()
	if selected_level_id == Catalog.LEGACY_LEVEL:
		_sync_legacy()
		_legacy.begin_run(free_skate)
	else:
		_run_active = true
		_free_skate = free_skate

func record_score(total: int, run_best_combo: int) -> Array[String]:
	if selected_level_id == Catalog.LEGACY_LEVEL:
		_sync_legacy()
		var result: Array[String] = _legacy.record_score(total, run_best_combo)
		_pull_legacy()
		return result
	if not _run_active or _free_skate: return []
	_run_score = maxi(_run_score, clampi(total, 0, MAX_SCORE))
	_run_combo = maxi(_run_combo, clampi(run_best_combo, 0, _run_score))
	best_score = maxi(best_score, _run_score)
	best_combo = maxi(best_combo, _run_combo)
	return _evaluate_goals()

func record_event(kind: String, id: String) -> Array[String]:
	if selected_level_id == Catalog.LEGACY_LEVEL:
		_sync_legacy()
		var result: Array[String] = _legacy.record_event(kind, id)
		_pull_legacy()
		return result
	if not _run_active or _free_skate: return []
	var accepted: Dictionary = Catalog.MERCHANT_CAREER.accepted_events
	if not accepted.has(kind) or not (accepted[kind] as Array).has(id): return []
	if not _collections.has(kind): _collections[kind] = {}
	_collections[kind][id] = true
	return _evaluate_goals()

func finish_run(total: int, run_best_combo: int) -> Array[String]:
	if selected_level_id == Catalog.LEGACY_LEVEL:
		_sync_legacy()
		var result: Array[String] = _legacy.finish_run(total, run_best_combo)
		_pull_legacy()
		return result
	var result: Array[String] = record_score(total, run_best_combo)
	_run_active = false
	return result

func goals_snapshot() -> Array[Dictionary]:
	if selected_level_id == Catalog.LEGACY_LEVEL:
		_sync_legacy()
		return _legacy.goals_snapshot()
	var result: Array[Dictionary] = []
	for goal: Dictionary in Catalog.MERCHANT_CAREER.goals:
		var row: Dictionary = goal.duplicate(true)
		row["done"] = completed_ids.has(goal.id)
		row["progress"] = int(goal.target) if row.done else mini(_goal_progress(goal), int(goal.target))
		result.append(row)
	return result

func unlocks() -> Array[String]:
	return _earned_unlocks(_records_with_active())

func presentation_revision() -> int:
	var legacy_revision := -1
	if selected_level_id == Catalog.LEGACY_LEVEL:
		_sync_legacy()
		legacy_revision = _legacy.presentation_revision()
	if _shown_generation != _generation or _shown_legacy != legacy_revision \
		or _shown_score != _run_score or _shown_combo != _run_combo \
		or _shown_completed != completed_ids or _shown_collections != _collections:
		_shown_generation = _generation
		_shown_legacy = legacy_revision
		_shown_score = _run_score
		_shown_combo = _run_combo
		_shown_completed = completed_ids.duplicate()
		_shown_collections = _collections.duplicate(true)
		_revision += 1
	return _revision

func load_profile(path: String = DEFAULT_PATH, legacy_path: String = LEGACY_PATH) -> Error:
	last_error = ""
	last_load_used_backup = false
	last_load_migrated_legacy = false
	var target: String = Base._absolute(path)
	if target.is_empty(): return _error(ERR_INVALID_PARAMETER, "A career book path is required.")
	if not legacy_path.is_empty(): _protect_legacy(legacy_path)
	if _protected_legacy.has(target): return _error(ERR_INVALID_PARAMETER, "The legacy profile belongs to City Tour and cannot become the new book.")
	var family: Dictionary = _read_family(target)
	for suffix: String in SUFFIXES:
		if family[suffix].error == ERR_UNAVAILABLE:
			return _block(target, ERR_UNAVAILABLE, "Newer career data was preserved; this version cannot replace it.")
	if family[""].error == OK:
		_apply_book(family[""].profile)
		_remember_loaded(target, family)
		_lock_unsafe_siblings(target, family)
		return OK
	if family[".bak"].error == OK:
		_apply_book(family[".bak"].profile)
		last_load_used_backup = true
		_remember_loaded(target, family)
		_lock_unsafe_siblings(target, family)
		return OK
	var absent := true
	for suffix: String in SUFFIXES: absent = absent and family[suffix].error == ERR_FILE_NOT_FOUND
	if not absent: return _block(target, ERR_FILE_CORRUPT, "Career data or an interrupted candidate requires recovery; every file was preserved.")
	_blocked_paths.erase(target)
	_loaded_signatures[target] = _signatures(family)
	if legacy_path.is_empty(): return _error(ERR_FILE_NOT_FOUND, "No career book exists yet.")
	# Inspect only after ALL new slots are absent. Base alone validates v0/v1.
	var legacy_target: String = Base._absolute(legacy_path)
	for suffix: String in SUFFIXES:
		if Base._read_profile(legacy_target + suffix).error == ERR_UNAVAILABLE:
			return _block(target, ERR_UNAVAILABLE, "Newer legacy progress was preserved; migration did not run.")
	var legacy = Base.new()
	var loaded: Error = legacy.load_profile(legacy_target)
	if loaded != OK:
		if loaded == ERR_FILE_NOT_FOUND: return _error(loaded, "No career book or legacy profile exists yet.")
		return _block(target, loaded, "Legacy progress could not be validated; no new book was written.")
	var migrated: Dictionary = _empty_book()
	migrated.levels[Catalog.LEGACY_LEVEL] = {"completed_ids":legacy.completed_ids.duplicate(), "best_score":legacy.best_score, "best_combo":legacy.best_combo}
	migrated.settings = legacy.settings.duplicate(true)
	var checked: Dictionary = _validate_book(migrated)
	if checked.error != OK: return _block(target, checked.error, "Validated legacy data could not be adopted safely.")
	_apply_book(checked.profile)
	last_load_used_backup = legacy.last_load_used_backup
	last_load_migrated_legacy = true
	return OK

func save_profile(path: String = DEFAULT_PATH) -> Error:
	last_error = ""
	var target: String = Base._absolute(path)
	if target.is_empty() or _protected_legacy.has(target): return _error(ERR_INVALID_PARAMETER, "The new career book needs a separate path from legacy data.")
	if _blocked_paths.has(target): return _error(_blocked_paths[target], "Saving is blocked to preserve existing player data; explicit recovery or a valid reload is required.")
	_stash_active()
	var checked: Dictionary = _validate_book(_book_data())
	if checked.error != OK: return _error(ERR_INVALID_DATA, "In-memory career data is invalid; nothing was written.")
	var family: Dictionary = _read_family(target)
	for suffix: String in SUFFIXES:
		if family[suffix].error == ERR_UNAVAILABLE: return _block(target, ERR_UNAVAILABLE, "A newer primary, backup or temporary book was preserved.")
	for suffix: String in SUFFIXES:
		if family[suffix].error not in [OK, ERR_FILE_NOT_FOUND]: return _block(target, ERR_FILE_CORRUPT, "Unreadable career data was preserved; saving is blocked.")
	for suffix: String in [".tmp", ".bak.tmp"]:
		if family[suffix].error != ERR_FILE_NOT_FOUND: return _block(target, ERR_FILE_CORRUPT, "An interrupted candidate was preserved; explicit recovery is required.")
	if family[""].error == OK or family[".bak"].error == OK:
		if not _loaded_signatures.has(target) or _loaded_signatures[target] != _signatures(family):
			return _error(ERR_BUSY, "The existing career book must be loaded again before it can be replaced.")
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	if directory_error != OK: return _error(directory_error, "Could not create the local career directory.")
	var write_error: Error = _write_verified(target + ".tmp", checked.profile)
	if write_error != OK: return _error(write_error, "Temporary career data could not be verified; previous files remain intact.")
	# Every observed slot matters, including an interrupted backup which appeared
	# after the initial read. The only expected change is our exact candidate.
	var expected: Dictionary = _signatures(family)
	expected[".tmp"] = (JSON.stringify(checked.profile, "\t") + "\n").sha256_text()
	var guard_error: Error = _guard_save_family(target, expected)
	if guard_error != OK: return guard_error
	if family[""].error == OK:
		var copy_error: Error = DirAccess.copy_absolute(target, target + ".bak.tmp")
		if copy_error != OK or _read_book(target + ".bak.tmp").signature != family[""].signature:
			return _error(ERR_FILE_CANT_WRITE, "The backup could not be verified; primary and temporary data were preserved.")
		expected[".bak.tmp"] = family[""].signature
		guard_error = _guard_save_family(target, expected)
		if guard_error != OK: return guard_error
		var backup_error: Error = DirAccess.rename_absolute(target + ".bak.tmp", target + ".bak")
		if backup_error != OK: return _error(backup_error, "The backup could not be replaced; primary data was preserved.")
		expected[".bak"] = expected[".bak.tmp"]
		expected[".bak.tmp"] = "absent"
	guard_error = _guard_save_family(target, expected)
	if guard_error != OK: return guard_error
	var replace_error: Error = DirAccess.rename_absolute(target + ".tmp", target)
	if replace_error != OK: return _error(replace_error, "The primary could not be replaced; all recovery data remains available.")
	settings = checked.profile.settings.duplicate(true)
	_remember_loaded(target, _read_family(target))
	return OK

func recover_profile(path: String = DEFAULT_PATH) -> Error:
	## Explicit user-selected reset only; never called by load/save fallback.
	var target: String = Base._absolute(path)
	if target.is_empty() or _protected_legacy.has(target): return _error(ERR_INVALID_PARAMETER, "Legacy data cannot be reset by the new book.")
	var archive_suffix := ".recovery-%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	for suffix: String in SUFFIXES:
		var source := target + suffix
		if DirAccess.dir_exists_absolute(source): return _error(ERR_FILE_CANT_WRITE, "A save path is a directory; no recovery files were replaced.")
		if FileAccess.file_exists(source):
			var archived: Error = DirAccess.rename_absolute(source, source + archive_suffix)
			if archived != OK: return _error(archived, "Recovery could not archive every file; no fresh book was written.")
	_blocked_paths.erase(target)
	_loaded_signatures.erase(target)
	_apply_book(_empty_book())
	return save_profile(target)

func _profile_data() -> Dictionary:
	## Legacy graphics/settings fixtures use this active v1 view. Persistence is v2.
	if selected_level_id == Catalog.LEGACY_LEVEL:
		_sync_legacy()
		return _legacy._profile_data()
	return _book_data()

func _book_data() -> Dictionary:
	return {"version":PROFILE_VERSION, "levels":_records_with_active(), "settings":settings.duplicate(true)}

func _active_record() -> Dictionary:
	return {"completed_ids":completed_ids.duplicate(), "best_score":best_score, "best_combo":best_combo}

func _records_with_active() -> Dictionary:
	var result: Dictionary = _levels.duplicate(true)
	result[selected_level_id] = _active_record()
	return result

func _stash_active() -> void:
	_levels[selected_level_id] = _active_record()

func _restore_active() -> void:
	var restored: Array[String] = []
	for id: String in _levels[selected_level_id].completed_ids: restored.append(id)
	completed_ids = restored
	best_score = int(_levels[selected_level_id].best_score)
	best_combo = int(_levels[selected_level_id].best_combo)

func _sync_legacy() -> void:
	_legacy.completed_ids = completed_ids
	_legacy.best_score = best_score
	_legacy.best_combo = best_combo
	_legacy.settings = settings

func _pull_legacy() -> void:
	completed_ids = _legacy.completed_ids
	best_score = _legacy.best_score
	best_combo = _legacy.best_combo

func _clear_run() -> void:
	_run_active = false
	_free_skate = false
	_run_score = 0
	_run_combo = 0
	_collections.clear()
	_legacy._clear_run()

func _evaluate_goals() -> Array[String]:
	var result: Array[String] = []
	for goal: Dictionary in Catalog.MERCHANT_CAREER.goals:
		if not completed_ids.has(goal.id) and _goal_progress(goal) >= int(goal.target):
			completed_ids.append(goal.id)
			result.append(goal.id)
	return result

func _goal_progress(goal: Dictionary) -> int:
	if goal.kind == "score": return _run_score
	if goal.kind == "combo": return _run_combo
	return (_collections.get(goal.kind, {}) as Dictionary).size()

func _apply_book(profile: Dictionary) -> void:
	_levels = profile.levels.duplicate(true)
	settings = profile.settings.duplicate(true)
	_clear_run()
	_restore_active()
	_generation += 1

func _protect_legacy(path: String) -> void:
	var absolute: String = Base._absolute(path)
	if absolute.is_empty(): return
	for suffix: String in SUFFIXES: _protected_legacy[absolute + suffix] = true

func _remember_loaded(target: String, family: Dictionary) -> void:
	_blocked_paths.erase(target)
	_loaded_signatures[target] = _signatures(family)

func _lock_unsafe_siblings(target: String, family: Dictionary) -> void:
	for suffix: String in SUFFIXES:
		if family[suffix].error not in [OK, ERR_FILE_NOT_FOUND]: _blocked_paths[target] = ERR_FILE_CORRUPT
	for suffix: String in [".tmp", ".bak.tmp"]:
		if family[suffix].error != ERR_FILE_NOT_FOUND: _blocked_paths[target] = ERR_FILE_CORRUPT

func _block(target: String, code: Error, message: String) -> Error:
	_blocked_paths[target] = code
	return _error(code, message)

func _error(code: Error, message: String) -> Error:
	last_error = message
	return code

static func _empty_record() -> Dictionary:
	return {"completed_ids":[], "best_score":0, "best_combo":0}

static func _empty_book() -> Dictionary:
	var levels := {}
	for id: String in Catalog.ids(): levels[id] = _empty_record()
	return {"version":PROFILE_VERSION, "levels":levels, "settings":DEFAULT_SETTINGS.duplicate(true)}

static func _earned_unlocks(records: Dictionary) -> Array[String]:
	var earned: Dictionary = {"color_blue":true}
	for level: String in Catalog.ids():
		var grants: Dictionary = Catalog.career(level).global_unlocks
		for goal_id: String in grants:
			if not (records[level].completed_ids as Array).has(goal_id): continue
			for id: String in grants[goal_id]: earned[id] = true
	var result: Array[String] = []
	for id: String in UNLOCK_ORDER:
		if earned.has(id): result.append(id)
	return result

static func _validate_book(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not Base._whole_number(raw.get("version"), 0, MAX_SCORE): return {"error":ERR_FILE_CORRUPT}
	if int(raw.version) > PROFILE_VERSION: return {"error":ERR_UNAVAILABLE}
	if int(raw.version) != PROFILE_VERSION or not raw.has_all(["levels", "settings"]) or not raw.levels is Dictionary or not raw.settings is Dictionary: return {"error":ERR_FILE_CORRUPT}
	for key: Variant in raw.keys():
		if key not in ["version", "levels", "settings"]: return {"error":ERR_FILE_CORRUPT}
	for level: Variant in raw.levels:
		if not level is String or level not in Catalog.ids(): return {"error":ERR_UNAVAILABLE}
	var cleaned: Dictionary = {}
	for level: String in Catalog.ids():
		if not raw.levels.has(level) or not raw.levels[level] is Dictionary: return {"error":ERR_FILE_CORRUPT}
		var record: Dictionary = raw.levels[level]
		if not record.has_all(["completed_ids", "best_score", "best_combo"]) or record.size() != 3 \
			or not record.completed_ids is Array or not Base._whole_number(record.best_score, 0, MAX_SCORE) \
			or not Base._whole_number(record.best_combo, 0, int(record.best_score)): return {"error":ERR_FILE_CORRUPT}
		var allowed: Array[String] = []
		for goal: Dictionary in Catalog.career(level).goals: allowed.append(goal.id)
		var ids: Array[String] = []
		for id: Variant in record.completed_ids:
			if not id is String or not allowed.has(id) or ids.has(id): return {"error":ERR_FILE_CORRUPT}
			ids.append(id)
		cleaned[level] = {"completed_ids":ids, "best_score":int(record.best_score), "best_combo":int(record.best_combo)}
	var grants: Array[String] = _earned_unlocks(cleaned)
	var internal_ids: Array[String] = []
	if grants.has("color_orange"): internal_ids.append("first_shift")
	if grants.has("color_purple"): internal_ids.append("some_shift")
	if grants.has("special_tenement_tumble"): internal_ids.append("one_long_line")
	# Only the existing settings validator sees these internal reward witnesses.
	# The returned legacy IDs are discarded; no City Tour completion is fabricated.
	var checked: Dictionary = Base._validate_profile({"version":1, "completed_ids":internal_ids, "best_score":0, "best_combo":0, "settings":raw.settings})
	if checked.error != OK: return {"error":checked.error}
	return {"error":OK, "profile":{"version":PROFILE_VERSION, "levels":cleaned, "settings":checked.profile.settings}}

static func _read_book(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"error":ERR_FILE_CANT_READ if DirAccess.dir_exists_absolute(path) else ERR_FILE_NOT_FOUND, "signature":"absent"}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null: return {"error":FileAccess.get_open_error(), "signature":"unreadable"}
	if file.get_length() > MAX_PROFILE_BYTES:
		file.close()
		return {"error":ERR_FILE_CORRUPT, "signature":"oversize"}
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	var read_error: Error = file.get_error()
	file.close()
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	var signature: String = hash.finish().hex_encode()
	if read_error not in [OK, ERR_FILE_EOF]: return {"error":read_error, "signature":signature}
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK: return {"error":ERR_FILE_CORRUPT, "signature":signature}
	var checked: Dictionary = _validate_book(parser.data)
	checked["signature"] = signature
	return checked

static func _read_family(target: String) -> Dictionary:
	var result := {}
	for suffix: String in SUFFIXES: result[suffix] = _read_book(target + suffix)
	return result

static func _signatures(family: Dictionary, authoritative_only: bool = false) -> Dictionary:
	var result := {}
	for suffix: String in (["", ".bak"] if authoritative_only else SUFFIXES): result[suffix] = family[suffix].signature
	return result

func _guard_save_family(target: String, expected: Dictionary) -> Error:
	var current: Dictionary = _read_family(target)
	for suffix: String in SUFFIXES:
		if current[suffix].error == ERR_UNAVAILABLE:
			return _block(target, ERR_UNAVAILABLE, "Newer career data appeared during saving; every observed candidate was preserved.")
	if _signatures(current) != expected:
		return _error(ERR_BUSY, "Career data changed during saving; all observed files were preserved.")
	return OK

func _write_verified(path: String, profile: Dictionary) -> Error:
	if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path): return ERR_ALREADY_EXISTS
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(profile, "\t") + "\n")
	file.flush()
	var result: Error = file.get_error()
	file.close()
	if result != OK: return result
	var checked: Dictionary = _read_book(path)
	if checked.error != OK: return checked.error
	return OK if checked.signature == (JSON.stringify(profile, "\t") + "\n").sha256_text() else ERR_BUSY
