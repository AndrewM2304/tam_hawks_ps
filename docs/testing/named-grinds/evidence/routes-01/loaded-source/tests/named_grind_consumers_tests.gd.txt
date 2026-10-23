extends RefCounted
## Independent entry-consumer checks. Main routing and scoring are production
## methods; fixture nodes omit world/HUD/actor construction and physical capture.

const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Mo = preload("res://game/characters/glasgow_encounters.gd")


class MainProbe extends "res://game/main.gd":
	func _ready() -> void:
		# Deliberately retain the inherited _on_trick, not the full scene setup.
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)


class AudioProbe extends Node:
	var events: Array[String] = []
	func play_event(event: String) -> void:
		events.append(event)


class EncounterProbe extends Node3D:
	var calls: Array[Dictionary] = []
	func on_trick(title: String,points: int,position: Vector3) -> void:
		calls.append({"title":title,"points":points,"position":position})


class CountingMo extends "res://game/characters/glasgow_encounters.gd":
	var calls: Array[Dictionary] = []
	func on_trick(title: String,points: int,position: Vector3) -> void:
		calls.append({"title":title,"points":points,"position":position})
		super.on_trick(title,points,position)


static func run(tree: SceneTree,check: Callable) -> void:
	_catalog_and_mo_names(check)
	var main := MainProbe.new()
	main.name="NamedGrindConsumerProbe"
	main.persistence_enabled=false
	main.process_mode=Node.PROCESS_MODE_DISABLED
	var audio := AudioProbe.new()
	var mo := CountingMo.new()
	var market := EncounterProbe.new()
	var rider := CharacterBody3D.new()
	main.audio=audio
	main.encounters=mo
	main.market_encounter=market
	main.skater=rider
	main.add_child(audio)
	main.add_child(mo)
	main.add_child(market)
	main.add_child(rider)
	tree.root.add_child(main)
	rider.position=Vector3(7,1,-4)
	# State fixture isolates callback classification, not encounter admission.
	mo._anchor=rider.global_position
	mo._state="active"
	mo._combo_valid=true
	for specification: Array in [["grind_50_50","50-50"],["boardslide","Boardslide"],["rail_grind","Rail Grind"]]:
		_clear(main,audio,mo,market)
		var title: String=specification[1]
		var points: int=Catalog.base_points(str(specification[0]))
		main._on_trick(title,points)
		check.call(main.score.trick_history==[title] and main.score.combo_base==points
			and main.score.combo_multiplier==1 and main.score.get_combo_value()==points
			and main.score.total_score==0,
			"named grind consumers: "+title+" enters real score exactly once without a duplicate legacy award or premature bank")
		check.call(audio.events==["grind"] and main._flips==0 and main._grabs==0,
			"named grind consumers: "+title+" dispatches one grind entry sound without flip/grab counter pollution")
		check.call(_one_call(mo.calls,title,points,rider.global_position)
			and _one_call(market.calls,title,points,rider.global_position),
			"named grind consumers: "+title+" forwards one unchanged event and actual rider position to each encounter")
		check.call(mo.status_snapshot().family_count==1 and mo._families.has("grind")
			and not mo._families.has("spin") and not mo._families.has("flip") and not mo._families.has("grab"),
			"named grind consumers: "+title+" reaches the actual Mo callback as exactly the grind family")

	_clear(main,audio,mo,market)
	main._on_trick("50-50",200)
	main._on_trick("Boardslide",200)
	check.call(main.score.trick_history==["50-50","Boardslide"]
		and main.score.combo_base==400 and main.score.combo_multiplier==2
		and main.score.get_combo_value()==800 and mo.status_snapshot().family_count==1,
		"named grind consumers: distinct contact styles retain separate score identities but one encounter family")
	check.call(audio.events==["grind","grind"] and mo.calls.size()==2 and market.calls.size()==2
		and main._flips==0 and main._grabs==0,
		"named grind consumers: two explicit style entries produce two total sounds/callbacks without extra consumer events")

	_clear(main,audio,mo,market)
	main._on_trick("Boardslide",200)
	main._on_trick("Boardslide",200)
	check.call(main.score.trick_history==["Boardslide","Boardslide"]
		and main.score.combo_base==300 and main.score.combo_multiplier==1
		and mo.status_snapshot().family_count==1 and audio.events.size()==2
		and mo.calls.size()==2 and market.calls.size()==2,
		"named grind consumers: separate repeated entries retain existing repeat devaluation and cannot manufacture family variety")

	# Unknown display names are not producer events. Zero-point callbacks let
	# routing refuse lookalike audio/families without changing Main's existing
	# contract that valid producers, rather than this dispatcher, admit scoring.
	for title: String in ["Boardslide Fake","50-50ish","boardslide","50-50 ","Rail Grind Fake"]:
		_clear(main,audio,mo,market)
		main._on_trick(title,0)
		check.call(audio.events.is_empty() and main.score.trick_history.is_empty()
			and main.score.get_combo_value()==0 and main._flips==0 and main._grabs==0
			and mo.status_snapshot().family_count==0
			and _one_call(mo.calls,title,0,rider.global_position)
			and _one_call(market.calls,title,0,rider.global_position),
			"named grind consumers: unscored lookalike cannot acquire grind audio, score or family through routing "+title)

	_clear(main,audio,mo,market)
	main._on_trick("Kickflip",300)
	main._on_trick("Melon Grab",250)
	check.call(main._flips==1 and main._grabs==1 and audio.events.is_empty()
		and mo.status_snapshot().family_count==2 and mo._families.has("flip") and mo._families.has("grab"),
		"named grind consumers: real flip/grab positive controls still exercise their counters and distinct families")
	main._on_trick("50-50",200)
	check.call(main._flips==1 and main._grabs==1 and audio.events==["grind"]
		and mo.status_snapshot().family_count==3 and mo.calls.size()==3 and market.calls.size()==3,
		"named grind consumers: named contact adds only grind after existing flip/grab events")

	_clear(main,audio,mo,market)
	main.run_finished=true
	main._on_trick("50-50",200)
	main._on_trick("Boardslide",200)
	main._on_trick("Rail Grind",200)
	check.call(main.score.trick_history.is_empty() and audio.events.is_empty()
		and mo.calls.is_empty() and market.calls.is_empty() and mo.status_snapshot().family_count==0
		and main._flips==0 and main._grabs==0,
		"named grind consumers: completed run rejects legacy and named entries before any score/audio/encounter dispatch")
	main.queue_free()
	await tree.process_frame
	check.call(not is_instance_valid(main) and not is_instance_valid(audio)
		and not is_instance_valid(mo) and not is_instance_valid(market) and not is_instance_valid(rider),
		"named grind consumers: isolated callback fixtures free all nodes without constructing a live gameplay scene")


static func _catalog_and_mo_names(check: Callable) -> void:
	var mo := Mo.new()
	for specification: Array in [["grind_50_50","50-50"],["boardslide","Boardslide"],["rail_grind","Rail Grind"]]:
		var id: String=specification[0]
		var title: String=specification[1]
		check.call(Catalog.definition(id).get("display_name","")==title and Catalog.is_grind_name(title)
			and Catalog.can_perform(id,"grind") and not Catalog.can_perform(id,"air")
			and mo._trick_family(title)=="grind",
			"named grind consumers: catalog state and actual Mo classifier recognize exact new/legacy name "+title)
	for title: String in ["Boardslide Fake","50-50ish","boardslide","50-50 ","Rail Grind Fake", "Ollie", "Manual", "Axle Stall", "Named Gap"]:
		check.call(not Catalog.is_grind_name(title),
			"named grind consumers: catalog refuses non-grind or non-exact display-name lookalike "+title)
	for title: String in ["Boardslide Fake","50-50ish","boardslide","50-50 "]:
		check.call(mo._trick_family(title).is_empty(),
			"named grind consumers: Mo cannot invent a named contact family from a lookalike "+title)
	check.call(mo._trick_family("Original Curved Grind")=="grind"
		and not Catalog.is_grind_name("Original Curved Grind"),
		"named grind consumers: Mo retains its existing legacy family fallback independently of exact catalog audio identity")
	mo.free()


static func _clear(main: Node,audio: Node,mo: Node,market: Node) -> void:
	main.score.reset()
	main._flips=0
	main._grabs=0
	main.run_finished=false
	audio.events.clear()
	mo.calls.clear()
	mo._families.clear()
	market.calls.clear()


static func _one_call(calls: Array,title: String,points: int,position: Vector3) -> bool:
	return calls.size()==1 and calls[0].title==title and calls[0].points==points \
		and (calls[0].position as Vector3).is_equal_approx(position)
