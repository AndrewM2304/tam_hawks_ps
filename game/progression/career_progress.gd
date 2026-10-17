class_name CareerProgress
extends RefCounted
## Local-only career state. Callers supply validated gameplay events, never frame counts.

const InputProfile = preload("res://game/core/input_profile.gd")
const PROFILE_VERSION: int = 1
const MAX_SCORE: int = 2000000000
const MAX_PROFILE_BYTES: int = 1048576
const DEFAULT_PATH: String = "user://career.json"
const DEFAULT_SETTINGS: Dictionary = {
	"audio": 0.8, "sfx_volume": 1.0, "ambience_volume": 0.6,
	"captions": true, "reduced_motion": false,
	"ui_scale": 1.0, "camera_sensitivity": 1.0,
	"bindings": {}, "cosmetic_id": "color_blue",
}
const LETTER_IDS: Array[String] = ["H", "A", "W", "K", "S"]
const MARKET_IDS: Array[String] = ["market_1", "market_2", "market_3"]
const DISTRICT_IDS: Array[String] = ["george_square", "royal_exchange", "central_station", "barras"]
const GOALS: Array = [
	{"id": "first_shift", "title": "First shift", "detail": "Bank 1,000 points in one career run.", "target": 1000},
	{"id": "good_shift", "title": "Good shift", "detail": "Bank 5,000 points in one career run.", "target": 5000},
	{"id": "some_shift", "title": "Some shift", "detail": "Bank 15,000 points in one career run.", "target": 15000},
	{"id": "one_long_line", "title": "One long line", "detail": "Bank one combo worth 3,000 points.", "target": 3000},
	{"id": "letters", "title": "Letters round the square", "detail": "Collect H A W K S in one career run.", "target": 5},
	{"id": "cone", "title": "Cone duty", "detail": "Knock the statue's cone loose.", "target": 1},
	{"id": "platform_change", "title": "Platform change", "detail": "Clear the Central route gap.", "target": 1},
	{"id": "market_sweep", "title": "Market sweep", "detail": "Collect three market items in one career run.", "target": 3},
	{"id": "across_toon", "title": "Across the toon", "detail": "Visit all four districts in one career run.", "target": 4},
	{"id": "lost_recording", "title": "Lost recording", "detail": "Find the hidden recording.", "target": 1},
]

var completed_ids: Array[String] = []
var best_score: int = 0
var best_combo: int = 0
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var last_load_used_backup: bool = false
var last_error: String = ""
var _run_active: bool = false
var _free_skate: bool = false
var _run_score: int = 0
var _run_combo: int = 0
var _collections: Dictionary = {}
var _blocked_paths: Dictionary = {}
var _recovered_paths: Dictionary = {}

func begin_run(free_skate: bool) -> void:
	_clear_run()
	_run_active = true
	_free_skate = free_skate

func record_score(total: int, run_best_combo: int) -> Array[String]:
	if not _run_active or _free_skate:
		return []
	_run_score = maxi(_run_score, clampi(total, 0, MAX_SCORE))
	_run_combo = maxi(_run_combo, clampi(run_best_combo, 0, _run_score))
	best_score = maxi(best_score, _run_score)
	best_combo = maxi(best_combo, _run_combo)
	return _evaluate_goals()

func record_event(kind: String, id: String) -> Array[String]:
	if not _run_active or _free_skate:
		return []
	var accepted := false
	match kind:
		"letter": accepted = LETTER_IDS.has(id)
		"market_item": accepted = MARKET_IDS.has(id)
		"district": accepted = DISTRICT_IDS.has(id)
		"interaction": accepted = id == "cone"
		"gap": accepted = id == "central_gap"
		"collectible": accepted = id == "secret_recording"
	if not accepted:
		return []
	if not _collections.has(kind):
		_collections[kind] = {}
	_collections[kind][id] = true
	return _evaluate_goals()

func finish_run(total: int, run_best_combo: int) -> Array[String]:
	var newly_completed := record_score(total, run_best_combo)
	_run_active = false
	return newly_completed

func goals_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for goal: Dictionary in GOALS:
		var item: Dictionary = goal.duplicate(true)
		item["done"] = completed_ids.has(goal["id"])
		item["progress"] = goal["target"] if item["done"] else mini(_goal_progress(goal["id"]), goal["target"])
		result.append(item)
	return result

func unlocks() -> Array[String]:
	var result: Array[String] = ["color_blue"]
	if completed_ids.has("first_shift"):
		result.append("color_orange")
		result.append("special_clyde_carousel")
	if completed_ids.has("some_shift"):
		result.append("color_purple")
	if completed_ids.has("one_long_line"):
		result.append("special_tenement_tumble")
	return result

func load_profile(path: String = DEFAULT_PATH) -> Error:
	last_load_used_backup = false
	last_error = ""
	var target := _absolute(path)
	if target.is_empty():
		return _error(ERR_INVALID_PARAMETER, "A profile path is required.")
	var primary := _read_profile(target)
	if primary["error"] == OK:
		_apply_profile(primary["profile"])
		_blocked_paths.erase(target)
		_recovered_paths.erase(target)
		return OK
	if primary["error"] == ERR_UNAVAILABLE:
		_blocked_paths[target] = ERR_UNAVAILABLE
		return _error(ERR_UNAVAILABLE, "Profile version is newer than this game; it was preserved.")
	var backup := _read_profile(target + ".bak")
	if backup["error"] == OK:
		_apply_profile(backup["profile"])
		last_load_used_backup = true
		_blocked_paths.erase(target)
		_recovered_paths[target] = true
		return OK
	if primary["error"] == ERR_FILE_NOT_FOUND and backup["error"] == ERR_FILE_NOT_FOUND:
		_blocked_paths.erase(target)
		return _error(ERR_FILE_NOT_FOUND, "No profile exists yet.")
	var failure: Error = ERR_UNAVAILABLE if backup["error"] == ERR_UNAVAILABLE else ERR_FILE_CORRUPT
	_blocked_paths[target] = failure
	return _error(failure, "Profile and backup could not be loaded; files were preserved. Explicit recovery is required.")

func save_profile(path: String = DEFAULT_PATH) -> Error:
	last_error = ""
	var target := _absolute(path)
	if target.is_empty():
		return _error(ERR_INVALID_PARAMETER, "A profile path is required.")
	if _blocked_paths.has(target):
		return _error(_blocked_paths[target], "Saving is blocked to preserve an unreadable or newer profile.")
	var checked := _validate_profile(_profile_data())
	if checked["error"] != OK:
		return _error(ERR_INVALID_DATA, "In-memory career data is invalid; nothing was written.")
	# A newer backup or interrupted candidate is also user data, even with a valid primary.
	for suffix: String in [".bak", ".tmp", ".bak.tmp"]:
		if _read_profile(target + suffix)["error"] == ERR_UNAVAILABLE:
			_blocked_paths[target] = ERR_UNAVAILABLE
			return _error(ERR_UNAVAILABLE, "Refusing to overwrite newer backup or temporary profile data.")
	var existing := _read_profile(target)
	if existing["error"] == ERR_UNAVAILABLE:
		_blocked_paths[target] = ERR_UNAVAILABLE
		return _error(ERR_UNAVAILABLE, "Refusing to overwrite a newer profile.")
	if existing["error"] not in [OK, ERR_FILE_NOT_FOUND] and not _recovered_paths.has(target):
		_blocked_paths[target] = ERR_FILE_CORRUPT
		return _error(ERR_FILE_CORRUPT, "Load a valid backup or explicitly recover before replacing a damaged profile.")
	if existing["error"] == ERR_FILE_NOT_FOUND:
		var backup := _read_profile(target + ".bak")
		if backup["error"] != ERR_FILE_NOT_FOUND and not _recovered_paths.has(target):
			var failure: Error = ERR_UNAVAILABLE if backup["error"] == ERR_UNAVAILABLE else ERR_FILE_CORRUPT
			_blocked_paths[target] = failure
			return _error(failure, "An existing backup must be loaded before creating the primary profile.")
	var directory_error := DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	if directory_error != OK:
		return _error(directory_error, "Could not create the local save directory.")
	var temporary := target + ".tmp"
	var write_error := _write_verified(temporary, checked["profile"])
	if write_error != OK:
		return _error(write_error, "Could not write and verify a temporary profile; previous files remain intact.")
	if existing["error"] == OK:
		var backup_temporary := target + ".bak.tmp"
		var copy_error := DirAccess.copy_absolute(target, backup_temporary)
		if copy_error != OK or _read_profile(backup_temporary)["error"] != OK:
			return _error(ERR_FILE_CANT_WRITE, "Could not verify the backup; primary profile was preserved.")
		var backup_error := DirAccess.rename_absolute(backup_temporary, target + ".bak")
		if backup_error != OK:
			return _error(backup_error, "Could not replace the backup; primary profile was preserved.")
	var replace_error := DirAccess.rename_absolute(temporary, target)
	if replace_error != OK:
		return _error(replace_error, "Could not replace the primary profile; its backup was preserved.")
	settings = checked["profile"]["settings"].duplicate(true)
	_recovered_paths.erase(target)
	return OK

func recover_profile(path: String = DEFAULT_PATH) -> Error:
	## Explicit user-selected reset only. Archives all existing files before resetting.
	var target := _absolute(path)
	if target.is_empty():
		return _error(ERR_INVALID_PARAMETER, "A profile path is required.")
	var suffix := ".recovery-%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	for extension: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		var source := target + extension
		if FileAccess.file_exists(source):
			var archive_error := DirAccess.rename_absolute(source, source + suffix)
			if archive_error != OK:
				return _error(archive_error, "Recovery could not archive every file; no fresh profile was written.")
	_blocked_paths.erase(target)
	_recovered_paths.erase(target)
	completed_ids.clear()
	best_score = 0
	best_combo = 0
	settings = DEFAULT_SETTINGS.duplicate(true)
	_clear_run()
	return save_profile(target)

func _evaluate_goals() -> Array[String]:
	var result: Array[String] = []
	for goal: Dictionary in GOALS:
		var id: String = goal["id"]
		if not completed_ids.has(id) and _goal_progress(id) >= goal["target"]:
			completed_ids.append(id)
			result.append(id)
	return result

func _goal_progress(id: String) -> int:
	match id:
		"first_shift", "good_shift", "some_shift": return _run_score
		"one_long_line": return _run_combo
		"letters": return _count("letter")
		"cone": return _count("interaction")
		"platform_change": return _count("gap")
		"market_sweep": return _count("market_item")
		"across_toon": return _count("district")
		"lost_recording": return _count("collectible")
	return 0

func _count(kind: String) -> int:
	return (_collections.get(kind, {}) as Dictionary).size()

func _clear_run() -> void:
	_run_active = false
	_free_skate = false
	_run_score = 0
	_run_combo = 0
	_collections.clear()

func _profile_data() -> Dictionary:
	return {"version": PROFILE_VERSION, "completed_ids": completed_ids.duplicate(),
		"best_score": best_score, "best_combo": best_combo, "settings": settings.duplicate(true)}

func _apply_profile(profile: Dictionary) -> void:
	completed_ids.clear()
	for id: String in profile["completed_ids"]:
		completed_ids.append(id)
	best_score = profile["best_score"]
	best_combo = profile["best_combo"]
	settings = profile["settings"].duplicate(true)
	_clear_run()

static func _absolute(path: String) -> String:
	if path.strip_edges().is_empty():
		return ""
	return ProjectSettings.globalize_path(path).simplify_path()

static func _read_profile(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": ERR_FILE_CANT_READ if DirAccess.dir_exists_absolute(path) else ERR_FILE_NOT_FOUND}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": FileAccess.get_open_error()}
	if file.get_length() > MAX_PROFILE_BYTES:
		file.close()
		return {"error": ERR_FILE_CORRUPT}
	var content := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return {"error": read_error}
	var parser := JSON.new()
	if parser.parse(content) != OK:
		return {"error": ERR_FILE_CORRUPT}
	return _validate_profile(parser.data)

static func _validate_profile(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not _whole_number(raw.get("version"), 0, MAX_SCORE):
		return {"error": ERR_FILE_CORRUPT}
	var data: Dictionary = raw
	var version := int(data["version"])
	if version > PROFILE_VERSION:
		return {"error": ERR_UNAVAILABLE}
	# Version 0 is a documented local prototype format; migrate without guessing unversioned files.
	var raw_ids: Variant = data.get("completed_ids" if version == 1 else "completed_goals", [])
	var raw_score: Variant = data.get("best_score" if version == 1 else "high_score", 0)
	var raw_combo: Variant = data.get("best_combo", 0)
	if not raw_ids is Array or not _whole_number(raw_score, 0, MAX_SCORE) or not _whole_number(raw_combo, 0, int(raw_score)):
		return {"error": ERR_FILE_CORRUPT}
	if version == 1 and not data.has_all(["completed_ids", "best_score", "best_combo", "settings"]):
		return {"error": ERR_FILE_CORRUPT}
	var cleaned_ids: Array[String] = []
	for id: Variant in raw_ids:
		if not id is String:
			return {"error": ERR_FILE_CORRUPT}
		for goal: Dictionary in GOALS:
			if id == goal["id"] and not cleaned_ids.has(id):
				cleaned_ids.append(id)
	var raw_settings: Variant = data.get("settings", {})
	if not raw_settings is Dictionary:
		return {"error": ERR_FILE_CORRUPT}
	var cleaned_settings := DEFAULT_SETTINGS.duplicate(true)
	for key: String in DEFAULT_SETTINGS:
		if not raw_settings.has(key):
			continue
		var value: Variant = raw_settings[key]
		if key == "bindings":
			var checked_bindings := InputProfile.validate_saved(value)
			if not checked_bindings["ok"]:
				return {"error": ERR_FILE_CORRUPT}
			cleaned_settings[key] = checked_bindings["bindings"].duplicate(true)
		elif key == "cosmetic_id":
			if not value is String or not InputProfile.COSMETIC_IDS.has(value):
				return {"error": ERR_FILE_CORRUPT}
			var earned: bool = value == "color_blue" or (value == "color_orange" and cleaned_ids.has("first_shift")) or (value == "color_purple" and cleaned_ids.has("some_shift"))
			cleaned_settings[key] = value if earned else "color_blue"
		elif DEFAULT_SETTINGS[key] is bool:
			if not value is bool:
				return {"error": ERR_FILE_CORRUPT}
			cleaned_settings[key] = value
		else:
			if not (value is int or value is float) or not is_finite(float(value)):
				return {"error": ERR_FILE_CORRUPT}
			var minimum := 1.0 if key == "ui_scale" else (0.5 if key == "camera_sensitivity" else 0.0)
			var maximum := 1.4 if key == "ui_scale" else (2.0 if key == "camera_sensitivity" else 1.0)
			cleaned_settings[key] = clampf(float(value), minimum, maximum)
	return {"error": OK, "profile": {"version": PROFILE_VERSION, "completed_ids": cleaned_ids,
		"best_score": int(raw_score), "best_combo": int(raw_combo), "settings": cleaned_settings}}

static func _whole_number(value: Variant, minimum: int, maximum: int) -> bool:
	return ((value is int or value is float) and is_finite(float(value))
		and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum)

static func _write_verified(path: String, profile: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(profile, "\t") + "\n")
	file.flush()
	var result := file.get_error()
	file.close()
	if result != OK:
		return result
	return _read_profile(path)["error"]

func _error(code: Error, message: String) -> Error:
	last_error = message
	return code
