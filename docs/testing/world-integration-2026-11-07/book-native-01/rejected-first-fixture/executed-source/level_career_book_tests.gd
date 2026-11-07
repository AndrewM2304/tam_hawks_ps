extends SceneTree
const Book = preload("res://game/progression/level_career_book.gd")
const Catalog = preload("res://game/progression/level_catalog.gd")
const Base = preload("res://game/progression/career_progress.gd")
var checks := 0
var failures := 0
var root_path := ""
var cases: Array[Dictionary] = []

func _initialize() -> void: _run.call_deferred()
func _check(ok: bool, label: String) -> void:
	checks += 1
	cases.append({"pass":ok,"message":label})
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func _run() -> void:
	root_path = "user://fixtures-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path))
	_test_inert_constructor()
	_test_domains()
	_test_legacy_parity()
	_test_migration()
	_test_roundtrip()
	_test_recovery_and_protection()
	_test_invalid_data()
	var report := {"checks":checks,"failures":failures,"cases":cases,"fixture_root":ProjectSettings.globalize_path(root_path),
		"scope":"Native isolated progress/profile transition tests; no Main/world/Music instantiated, no ordinary user profile path opened. Failed fixture files retained.",
		"engine":Engine.get_version_info()}
	var output := FileAccess.open("res://.local/book-test-result.json", FileAccess.WRITE)
	if output: output.store_string(JSON.stringify(report,"\t")+"\n"); output.close()
	print("LEVEL_CAREER_BOOK: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)

func _test_inert_constructor() -> void:
	# These are default paths only within this fixture's separate XDG/project.
	# Poison them: constructors and explicit no-migration loads must ignore them.
	_write_text(Book.LEGACY_PATH,'{"version":99,"owner_data":"do not inspect during construction"}')
	_write_text(Book.DEFAULT_PATH,'{"version":99,"owner_data":"do not inspect during construction"}')
	var legacy_before: Dictionary = _family_bytes(Book.LEGACY_PATH)
	var book_before: Dictionary = _family_bytes(Book.DEFAULT_PATH)
	var nodes: int = get_root().get_child_count()
	var book = Book.new()
	_check(book.last_error.is_empty() and book.completed_ids.is_empty() and book.best_score == 0 and book.unlocks() == ["color_blue"]
		and get_root().get_child_count() == nodes and _family_bytes(Book.LEGACY_PATH) == legacy_before and _family_bytes(Book.DEFAULT_PATH) == book_before,
		"scripted/default constructor is inert: no profile application, scene/Music creation or user-file writes")
	var isolated := root_path.path_join("explicit-no-migration/book.json")
	_check(book.load_profile(isolated,"") == ERR_FILE_NOT_FOUND and book.save_profile(isolated) == OK,
		"explicit isolated no-migration CLI flow ignores poisoned ordinary defaults and only writes its fixture")

func _test_domains() -> void:
	var book = Book.new()
	var source: Dictionary = Catalog.definition(Catalog.DEFAULT_LEVEL)
	source.career.goals[0].target = 1
	_check(Catalog.career(Catalog.DEFAULT_LEVEL).goals[0].target == 1000 and source.world_path == "res://game/levels/merchant_neighbourhood.gd",
		"metadata copies cannot change canonical goals; world paths are strings without world construction")
	_check(book.configure_level(Catalog.career(Catalog.DEFAULT_LEVEL)) and not book.configure_level(source.career),"canonical registration accepts exact manifest and rejects mutated threshold")
	_check(book.record_score(15000,3000).is_empty() and book.record_event("interaction","md_cone").is_empty(),"inactive events cannot manufacture progress")
	book.begin_run(false)
	_check(book.record_score(999,999).is_empty() and book.record_score(1000,1000) == ["md_first_shift"],"Merchant score threshold is banked once with its own namespaced ID")
	_check(book.record_score(1000,1000).is_empty(),"repeated score cannot duplicate a completed goal")
	book.record_event("letter","md_letter_h")
	book.record_event("letter","md_letter_h")
	for pair: Array in [["letter","H"],["letter","md_letter_x"],["Letter","md_letter_a"],["district","george_square"],["gap","central_gap"]]:
		book.record_event(pair[0],pair[1])
	_check(_progress(book,"md_letters") == 1 and _progress(book,"md_roof_gap") == 0,"duplicate, malformed and other-level IDs cannot inflate or cross-credit collections")
	book.begin_run(false)
	_check(_progress(book,"md_letters") == 0,"starting another run clears unfinished collections")
	for kind: String in Catalog.MERCHANT_CAREER.accepted_events:
		for id: String in Catalog.MERCHANT_CAREER.accepted_events[kind]: book.record_event(kind,id)
	book.finish_run(15000,3000)
	_check(book.completed_ids.size() == 10 and book.best_score == 15000 and book.best_combo == 3000,"all ten Merchant goals are reachable from exactly the manifest's genuine accepted events")
	_check(book.record_event("interaction","md_cone").is_empty() and book.finish_run(999999,999999).is_empty() and book.best_score == 15000,"finished runs cannot extend records or accept late events")
	book.settings.cosmetic_id = "color_purple"
	var revision: int = book.presentation_revision()
	_check(book.select_level(Catalog.LEGACY_LEVEL) and book.completed_ids.is_empty() and book.best_score == 0 and book.best_combo == 0,"switching domains keeps every City Tour goal/record unearned")
	_check(book.presentation_revision() > revision and book.unlocks() == Book.UNLOCK_ORDER and book.settings.cosmetic_id == "color_purple","selection changes presentation and genuine Merchant achievements grant global rewards without fake City Tour IDs")
	book.begin_run(false)
	book.record_event("letter","H")
	_check(_progress(book,"letters") == 1 and book.record_event("letter","md_letter_a").is_empty(),"City Tour retains original IDs and rejects Merchant events")
	book.select_level(Catalog.DEFAULT_LEVEL)
	_check(book.completed_ids.size() == 10 and book.best_score == 15000 and book.settings.cosmetic_id == "color_purple","returning to Merchant restores its own records and the same global settings")
	var free = Book.new()
	free.begin_run(true)
	free.record_score(15000,3000)
	free.record_event("interaction","md_cone")
	free.finish_run(15000,3000)
	_check(free.completed_ids.is_empty() and free.best_score == 0 and _progress(free,"md_cone_duty") == 0,"free skate cannot create Merchant progress, collections or rewards")
	var equal = Book.new()
	var first: int = equal.presentation_revision()
	equal.select_level(Catalog.LEGACY_LEVEL)
	_check(equal.presentation_revision() > first,"empty-to-empty domain changes still invalidate cached goal presentation")

func _test_legacy_parity() -> void:
	var book = Book.new()
	book.select_level(Catalog.LEGACY_LEVEL)
	var base = Base.new()
	book.completed_ids = ["cone"]
	base.completed_ids = ["cone"]
	book.best_score = 2400
	base.best_score = 2400
	book.best_combo = 999
	base.best_combo = 999
	book.settings.captions = false
	base.settings.captions = false
	book.begin_run(false); base.begin_run(false)
	var parity := true
	for score: Vector2i in [Vector2i(999,999),Vector2i(1000,500),Vector2i(5000,3000),Vector2i(15000,3000)]:
		parity = parity and book.record_score(score.x,score.y) == base.record_score(score.x,score.y)
	for kind: String in Catalog.career(Catalog.LEGACY_LEVEL).accepted_events:
		for id: String in Catalog.career(Catalog.LEGACY_LEVEL).accepted_events[kind]:
			parity = parity and book.record_event(kind,id) == base.record_event(kind,id)
	_check(parity and book.goals_snapshot() == base.goals_snapshot() and book.completed_ids == base.completed_ids and book.best_score == base.best_score and book.best_combo == base.best_combo,
		"City Tour delegate matches existing goal/record behavior through a full run including direct writable fixture assignments")
	_check(book._profile_data() == base._profile_data(),"legacy graphics/settings snapshot stays exact v1 while persistence is v2")
	book.select_level(Catalog.DEFAULT_LEVEL)
	_check(book.completed_ids.is_empty() and book.best_score == 0 and book.unlocks() == base.unlocks(),"City Tour achievements remain globally earned without completing Merchant goals")

func _test_migration() -> void:
	for version: int in [0,1]:
		var directory := root_path.path_join("migrate"+str(version))
		var path := directory.path_join("career-v2.json")
		var legacy := directory.path_join("career.json")
		var raw: Dictionary = {"version":1,"completed_ids":["first_shift","some_shift"],"best_score":16000,"best_combo":2000,"settings":Base.DEFAULT_SETTINGS.duplicate(true)}
		raw.settings.cosmetic_id = "color_purple"
		raw.settings.captions = false
		if version == 0:
			raw.version = 0
			raw.completed_goals = raw.completed_ids
			raw.high_score = raw.best_score
			raw.erase("completed_ids");raw.erase("best_score")
		_write(legacy,raw)
		_write(legacy+".bak",raw)
		_write_text(legacy+".tmp","{legacy-interrupted")
		var bytes_before: Dictionary = _family_bytes(legacy)
		var book = Book.new()
		_check(book.load_profile(path,legacy) == OK and book.last_load_migrated_legacy and book.selected_level_id == Catalog.DEFAULT_LEVEL and book.completed_ids.is_empty(),"validated legacy v%d migrates only to City Tour and retains caller-selected Merchant" % version)
		_check(book.settings.cosmetic_id == "color_purple" and not book.settings.captions and book.unlocks().has("color_purple"),"legacy global cosmetics/settings/unlocks survive v%d migration" % version)
		book.select_level(Catalog.LEGACY_LEVEL)
		_check(book.best_score == 16000 and book.best_combo == 2000 and book.completed_ids == ["first_shift","some_shift"],"legacy v%d records are copied into the exact preserved domain" % version)
		_check(not FileAccess.file_exists(path) and _family_bytes(legacy) == bytes_before,"migration is memory-only and preserves every legacy primary/backup/temp byte")
		_check(book.save_profile(path) == OK and _family_bytes(legacy) == bytes_before,"saving the new book never mutates old legacy files")
		var loaded = Book.new()
		loaded.select_level(Catalog.LEGACY_LEVEL)
		_check(loaded.load_profile(path,legacy) == OK and loaded.selected_level_id == Catalog.LEGACY_LEVEL and loaded.best_score == 16000 and not loaded.last_load_migrated_legacy,"v2 reload keeps explicit selected legacy level and does not migrate twice")
		_check(loaded.save_profile(legacy) == ERR_INVALID_PARAMETER and _family_bytes(legacy) == bytes_before,"the migrated source path cannot be overwritten by the new book")

func _test_roundtrip() -> void:
	var path := root_path.path_join("roundtrip/book.json")
	var book = Book.new()
	_check(book.load_profile(path,"") == ERR_FILE_NOT_FOUND,"missing isolated book stays first-run without a save lock")
	book.begin_run(false);book.record_score(15000,3000)
	book.settings.cosmetic_id = "color_purple"
	book.settings.ui_scale = 9.0
	book.settings.audio = -2.0
	book.select_level(Catalog.LEGACY_LEVEL)
	book.completed_ids = ["cone"]
	book.best_score = 2100;book.best_combo = 500
	_check(book.save_profile(path) == OK,"global earned cosmetic and separately writable domains save as one validated v2 book")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(raw.version == 2 and raw.levels[Catalog.LEGACY_LEVEL].completed_ids == ["cone"] and raw.levels[Catalog.DEFAULT_LEVEL].completed_ids.has("md_some_shift") and not raw.levels[Catalog.LEGACY_LEVEL].completed_ids.has("some_shift"),"serialized domains retain genuine IDs without synthetic reward witnesses")
	var loaded = Book.new()
	loaded.select_level(Catalog.LEGACY_LEVEL)
	_check(loaded.load_profile(path,"") == OK and loaded.best_score == 2100 and loaded.settings.cosmetic_id == "color_purple" and loaded.settings.ui_scale == 1.4 and loaded.settings.audio == 0.0,"reload preserves the selected domain and reuses existing bounded global settings validator")
	loaded.begin_run(false);loaded.finish_run(3000,600)
	_check(loaded.save_profile(path) == OK and Book._read_book(path+".bak").profile.levels[Catalog.LEGACY_LEVEL].best_score == 2100,"healthy atomic save keeps the previous entire book as a validated backup")
	var stale = Book.new()
	stale.load_profile(path,"")
	loaded.begin_run(false);loaded.finish_run(5000,1000);loaded.save_profile(path)
	var protected: Dictionary = _family_bytes(path)
	_check(stale.save_profile(path) == ERR_BUSY and _family_bytes(path) == protected,"a stale loaded instance cannot overwrite another writer's newer valid book")

func _test_recovery_and_protection() -> void:
	var valid: Dictionary = Book._empty_book()
	valid.levels[Catalog.LEGACY_LEVEL] = {"completed_ids":["cone"],"best_score":2000,"best_combo":1000}
	for suffix: String in Book.SUFFIXES:
		var path := root_path.path_join("future"+str(Book.SUFFIXES.find(suffix))+"/book.json")
		_write(path,valid)
		_write_text(path+suffix,'{"version":99,"owner_data":"must survive"}')
		var before: Dictionary = _family_bytes(path)
		var book = Book.new();book.best_score = 123
		_check(book.load_profile(path,"") == ERR_UNAVAILABLE and book.best_score == 123 and book.save_profile(path) == ERR_UNAVAILABLE and _family_bytes(path) == before,"future primary/backup/temp blocks both fallback and overwrite, suffix="+suffix)
	var backup_path := root_path.path_join("corrupt-primary/book.json")
	_write_text(backup_path,"{damaged-primary")
	_write(backup_path+".bak",valid)
	var family: Dictionary = _family_bytes(backup_path)
	var backup = Book.new();backup.select_level(Catalog.LEGACY_LEVEL)
	_check(backup.load_profile(backup_path,"") == OK and backup.last_load_used_backup and backup.best_score == 2000 and backup.save_profile(backup_path) == ERR_FILE_CORRUPT and _family_bytes(backup_path) == family,"valid backup can be read while damaged primary bytes stay protected from autosave")
	_check(backup.recover_profile(backup_path) == OK and backup.completed_ids.is_empty() and _archive_contains(backup_path,"{damaged-primary"),"explicit selected recovery archives damaged primary before creating a fresh v2 book")
	var missing := root_path.path_join("orphan-backup/book.json")
	_write(missing+".bak",valid)
	var orphan = Book.new();orphan.select_level(Catalog.LEGACY_LEVEL)
	_check(orphan.load_profile(missing,"") == OK and orphan.last_load_used_backup and orphan.best_score == 2000 and orphan.save_profile(missing) == OK,"validated orphan backup can create a primary without replacing its recovery source")
	for suffix: String in [".bak",".tmp",".bak.tmp"]:
		var path := root_path.path_join("damaged"+str(Book.SUFFIXES.find(suffix))+"/book.json")
		_write(path,valid);_write_text(path+suffix,"{interrupted")
		var before: Dictionary = _family_bytes(path)
		var book = Book.new()
		_check(book.load_profile(path,"") == OK and book.save_profile(path) == ERR_FILE_CORRUPT and _family_bytes(path) == before,"valid primary remains readable while damaged sibling blocks overwrite, suffix="+suffix)
	var interrupted := root_path.path_join("only-temp/book.json")
	_write(interrupted+".tmp",valid)
	var legacy := root_path.path_join("only-temp/old.json")
	_write(legacy,{"version":1,"completed_ids":["first_shift"],"best_score":1000,"best_combo":1,"settings":Base.DEFAULT_SETTINGS})
	var before: Dictionary = _family_bytes(interrupted)
	var book = Book.new()
	_check(book.load_profile(interrupted,legacy) == ERR_FILE_CORRUPT and not book.last_load_migrated_legacy and book.save_profile(interrupted) == ERR_FILE_CORRUPT and _family_bytes(interrupted) == before,"a valid interrupted-only candidate prevents fallback to older legacy progress")

func _test_invalid_data() -> void:
	var invalid: Array = []
	for field: String in ["best_score","best_combo"]:
		for value: Variant in [-1,1.5,2000000001,"1000",null]:
			var raw: Dictionary = Book._empty_book();raw.levels[Catalog.DEFAULT_LEVEL][field] = value;invalid.append(raw)
	var crossed: Dictionary = Book._empty_book();crossed.levels[Catalog.DEFAULT_LEVEL].completed_ids = ["first_shift"];invalid.append(crossed)
	var duplicate: Dictionary = Book._empty_book();duplicate.levels[Catalog.LEGACY_LEVEL].completed_ids = ["cone","cone"];invalid.append(duplicate)
	var missing: Dictionary = Book._empty_book();missing.levels.erase(Catalog.LEGACY_LEVEL);invalid.append(missing)
	var bad_binding: Dictionary = Book._empty_book();bad_binding.settings.bindings = {"unknown_action":{"key":65}};invalid.append(bad_binding)
	var unearned: Dictionary = Book._empty_book();unearned.settings.cosmetic_id = "color_purple"
	_check(Book._validate_book(unearned).profile.settings.cosmetic_id == "color_blue","an unearned global cosmetic is sanitized rather than fabricated through City Tour IDs")
	var rejected := true
	for index: int in invalid.size():
		var path := root_path.path_join("invalid"+str(index)+"/book.json");_write(path,invalid[index])
		var before: Dictionary = _family_bytes(path)
		var book = Book.new()
		rejected = rejected and book.load_profile(path,"") == ERR_FILE_CORRUPT and book.save_profile(path) == ERR_FILE_CORRUPT and _family_bytes(path) == before
	_check(rejected,"malformed/fractional/out-of-range records, cross-domain/duplicate IDs and invalid bindings all preserve exact source bytes")
	var oversized := root_path.path_join("oversize/book.json")
	_write_text(oversized," ".repeat(Book.MAX_PROFILE_BYTES+1))
	var large = Book.new()
	_check(large.load_profile(oversized,"") == ERR_FILE_CORRUPT and large.save_profile(oversized) == ERR_FILE_CORRUPT and FileAccess.get_file_as_bytes(oversized).size() == Book.MAX_PROFILE_BYTES+1,"oversized input rejects before unbounded parsing and remains intact")
	var impossible: Dictionary = Book._empty_book();impossible.levels[Catalog.DEFAULT_LEVEL].best_score = 10;impossible.levels[Catalog.DEFAULT_LEVEL].best_combo = 11
	_check(Book._validate_book(impossible).error == ERR_FILE_CORRUPT,"a combo larger than its score cannot enter the book")
	var future_level: Dictionary = Book._empty_book();future_level.levels.future_world = {"owner_data":"preserve"}
	_check(Book._validate_book(future_level).error == ERR_UNAVAILABLE,"unknown future level records are preserved instead of discarded")

func _progress(book: RefCounted, id: String) -> int:
	for goal: Dictionary in book.goals_snapshot():
		if goal.id == id: return goal.progress
	return -1

func _write(path: String, value: Variant) -> void: _write_text(path,JSON.stringify(value))
func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text);file.close()
func _family_bytes(path: String) -> Dictionary:
	var result := {}
	for suffix: String in Book.SUFFIXES:
		result[suffix] = FileAccess.get_file_as_bytes(path+suffix).hex_encode() if FileAccess.file_exists(path+suffix) else "absent"
	return result
func _archive_contains(path: String, expected: String) -> bool:
	var directory := DirAccess.open(ProjectSettings.globalize_path(path).get_base_dir())
	if directory == null: return false
	for name: String in directory.get_files():
		if name.begins_with(path.get_file()+".recovery-") and FileAccess.get_file_as_string(ProjectSettings.globalize_path(path).get_base_dir().path_join(name)) == expected: return true
	return false
