extends SceneTree
const Main = preload("res://game/main.gd")
const CountedOriginal = preload("res://.local/hud_label_original_counted_main.gd")
const Labels = preload("res://tests/hud_trick_label_cache_tests.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
var passed := 0
var failed := 0
var pairs := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var game := Main.new()
	_check(not game.persistence_enabled,"HUD legacy parity: Main is profile-isolated before scene construction")
	if game.persistence_enabled:
		game.free()
		quit(1)
		return
	root.add_child(game)
	for frame: int in 35:
		await physics_frame
		await process_frame
	var old := CountedOriginal.new()
	var current := Labels.CountingNames.new()
	for probe: Node in [old,current]:
		probe.persistence_enabled=false
		for key: String in ["score","career","special_meter","objectives","encounters","cat_encounter",
			"market_encounter","feature_hub","music","world","skater","hud","time_remaining",
			"run_finished","paused","free_skate_mode","_focused_encounter","_feedback","_feedback_timer",
			"_caption","_caption_time","_landings","_flips","_grabs","save_status","save_warning"]:
			probe.set(key,game.get(key))
	var saved_grind: String=game.skater.grind_trick_id
	var saved_manual: String=game.skater.manual_trick_id
	game._refresh_hud()
	var before: Dictionary=game.hud._state.duplicate(true)
	game.skater.grind_trick_id=""
	game.skater.manual_trick_id=""
	_check(_pair(old,current,game),"HUD legacy parity: first empty IDs preserve the entire original HUD snapshot")
	var old_before: int=old.label_reads
	var new_before: int=current.name_reads
	game.skater.grind_trick_id="rail_grind"
	game.skater.manual_trick_id="manual"
	var unchanged_equal := true
	for sample: int in 31:unchanged_equal=_pair(old,current,game) and unchanged_equal
	_check(unchanged_equal and old.label_reads-old_before==62 and current.name_reads-new_before==2,
		"HUD legacy parity: thirty-one unchanged refresh pairs retain full state with sixty-two original label reads versus two cached reads")
	var ids: Array=Catalog.ids()
	ids.append_array(Catalog.compatibility_ids())
	ids.append_array(["unknown_hud_label_fixture",""])
	var identities_equal := true
	for id: String in ids:
		game.skater.grind_trick_id=id
		game.skater.manual_trick_id=id
		identities_equal=_pair(old,current,game) and identities_equal
	_check(identities_equal,"HUD legacy parity: every canonical, compatibility, unknown and empty ID preserves the complete HUD")
	old.time_remaining-=1.0
	current.time_remaining-=1.0
	_check(_pair(old,current,game),"HUD legacy parity: a changed timer snapshot preserves complete original HUD values")
	game.skater.grind_trick_id=saved_grind
	game.skater.manual_trick_id=saved_manual
	game._refresh_hud()
	_check(game.hud._state==before and not game.music._can_control and not game.music._persist,
		"HUD legacy parity: fixture restores the complete live HUD and leaves personal Music isolated")
	print("HUD_IMMUTABLE_LEGACY_PARITY ",{"pairs":pairs,"old_label_reads":old.label_reads,
		"new_label_reads":current.name_reads,"unchanged_pairs":31,"unchanged_old_reads":62,
		"unchanged_new_reads":2,"label_slots":2})
	old.free()
	current.free()
	game.queue_free()
	await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _pair(old: Node,current: Node,game: Node) -> bool:
	old._refresh_hud()
	var snapshot: Dictionary=game.hud._state.duplicate(true)
	current._refresh_hud()
	pairs+=1
	return game.hud._state==snapshot
func _check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
