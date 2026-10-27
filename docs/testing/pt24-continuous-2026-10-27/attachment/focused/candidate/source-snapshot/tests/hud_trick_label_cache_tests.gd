extends RefCounted
## Actual Main/HUD values and counted metadata reads; no profile writes.
const Catalog = preload("res://game/tricks/trick_catalog.gd")

class CountingNames extends "res://game/main.gd":
	var name_reads := 0
	func _read_hud_trick_name(trick_id: String,fallback: String) -> String:
		name_reads += 1
		return super._read_hud_trick_name(trick_id,fallback)


static func run(_tree: SceneTree,game: Node,check: Callable) -> void:
	game._refresh_hud()
	var hud_before: Dictionary=game.hud._state.duplicate(true)
	var probe := CountingNames.new()
	probe.persistence_enabled=false
	# This unparented Main references existing scene dependencies without owning
	# them. Only declared label IDs change in this synchronous metadata fixture;
	# they are restored before any next frame. No motion/input/score is injected.
	for key: String in ["score","career","special_meter","objectives","encounters","cat_encounter",
		"market_encounter","feature_hub","music","world","skater","hud","time_remaining",
		"run_finished","paused","free_skate_mode","_focused_encounter","_feedback","_feedback_timer",
		"_caption","_caption_time","_landings","_flips","_grabs","save_status","save_warning"]:
		probe.set(key,game.get(key))
	var saved_grind: String=game.skater.grind_trick_id
	var saved_manual: String=game.skater.manual_trick_id
	var physics := {"at":game.skater.global_transform,"velocity":game.skater.velocity,"speed":game.skater.speed,
		"manual":game.skater.manual_active,"grinding":game.skater.grinding}
	game.skater.grind_trick_id=""
	game.skater.manual_trick_id=""
	probe._refresh_hud()
	check.call(probe.name_reads==0 and game.hud._state.grind_name=="" and game.hud._state.manual_name=="Manual",
		"HUD label cache: first empty identities have the original distinct fallbacks without a catalog read")
	game.skater.grind_trick_id="rail_grind"
	game.skater.manual_trick_id="manual"
	probe._refresh_hud()
	var first_reads: int=probe.name_reads
	for sample: int in 30:probe._refresh_hud()
	check.call(first_reads==2 and probe.name_reads==first_reads
		and game.hud._state.grind_name==Catalog.definition("rail_grind").get("display_name","")
		and game.hud._state.manual_name==Catalog.definition("manual").get("display_name","Manual"),
		"HUD label cache: thirty unchanged real refreshes retain both exact labels without repeating catalog reads")
	game.skater.grind_trick_id="nosegrind"
	probe._refresh_hud()
	check.call(probe.name_reads==first_reads+1
		and game.hud._state.grind_name==Catalog.definition("nosegrind").get("display_name","")
		and game.hud._state.manual_name==Catalog.definition("manual").get("display_name","Manual"),
		"HUD label cache: changing one identity updates that live label in the same call and does not reread its unchanged partner")
	game.skater.manual_trick_id="pogo"
	probe._refresh_hud()
	check.call(probe.name_reads==first_reads+2 and game.hud._state.manual_name=="Pogo",
		"HUD label cache: a new manual identity reaches the actual HUD immediately")
	var ids: Array=Catalog.ids()
	ids.append_array(Catalog.compatibility_ids())
	var labels_equal := true
	for id: String in ids:
		game.skater.grind_trick_id=id
		game.skater.manual_trick_id=id
		probe._refresh_hud()
		var expected: Dictionary=Catalog.definition(id)
		labels_equal=labels_equal and game.hud._state.grind_name==expected.get("display_name","") \
			and game.hud._state.manual_name==expected.get("display_name","Manual")
	check.call(labels_equal and ids.size()>=78,
		"HUD label cache: every canonical and compatibility identity preserves its original catalog label")
	for id: String in ["unknown_hud_label_fixture",""]:
		game.skater.grind_trick_id=id
		game.skater.manual_trick_id=id
		probe._refresh_hud()
		check.call(game.hud._state.grind_name=="" and game.hud._state.manual_name=="Manual",
			"HUD label cache: unknown and empty identities retain each family's distinct fallback "+id)
	var stable_reads: int=probe.name_reads
	var time_before: float=game.time_remaining
	probe.time_remaining=time_before-1.0
	probe._refresh_hud()
	check.call(probe.name_reads==stable_reads and game.hud._state.time==probe.time_remaining
		and game.time_remaining==time_before,
		"HUD label cache: a changed timer snapshot is accepted without rereading unchanged metadata")
	game.skater.grind_trick_id=saved_grind
	game.skater.manual_trick_id=saved_manual
	game._refresh_hud()
	check.call(game.hud._state.grind_name==Catalog.definition(saved_grind).get("display_name","")
		and game.hud._state.manual_name==Catalog.definition(saved_manual).get("display_name","Manual")
		and game.hud._state==hud_before
		and physics=={"at":game.skater.global_transform,"velocity":game.skater.velocity,"speed":game.skater.speed,
			"manual":game.skater.manual_active,"grinding":game.skater.grinding},
		"HUD label cache: returning to previous IDs restores the entire real HUD snapshot without changing physics or active ride state")
	print("HUD_TRICK_LABEL_CACHE ",{"unchanged_refreshes":31,"initial_label_reads":first_reads,
		"canonical_and_compatibility_ids":ids.size(),"total_label_reads":probe.name_reads,
		"retained_label_slots":2})
	probe.free()
	check.call(not game.persistence_enabled and not game.music._can_control and not game.music._persist,
		"HUD label cache: refresh-only witness never writes a career profile or controls personal Music")
