extends RefCounted
## Isolated production Main score callbacks; these declared receipt fixtures do
## not claim natural input, physical trick admission or animation evidence.
const Main = preload("res://game/main.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")

class ReceiptSkater extends CharacterBody3D:
	var last_trick_id := ""

class EncounterProbe extends Node3D:
	var identities: Array[String] = []
	func on_trick(_label: String, _points: int, _at: Vector3, identity: String = "") -> void:
		identities.append(identity)

class AudioProbe extends Node:
	func play_event(_event: String) -> void: pass

static func run(tree: SceneTree, check: Callable) -> void:
	var fixture := Node3D.new()
	tree.root.add_child(fixture)
	var game := Main.new()
	game.persistence_enabled = false
	game.skater = ReceiptSkater.new()
	game.encounters = EncounterProbe.new()
	game.market_encounter = EncounterProbe.new()
	game.feature_hub = EncounterProbe.new()
	game.audio = AudioProbe.new()
	for node: Node in [game.skater,game.encounters,game.market_encounter,game.feature_hub,game.audio]:
		fixture.add_child(node)
	for pair: Array in [["pop_shuvit","pop_shove_it"],["varial_flip","varial_kickflip"],
		["grind_50_50","rail_grind"],["disaster","disaster_stall"]]:
		game.score.reset()
		var alias_entry := Catalog.definition(pair[0])
		var canonical := Catalog.definition(pair[1])
		game._on_trick(alias_entry.display_name,alias_entry.base_points)
		game._on_trick(canonical.display_name,canonical.base_points)
		var history: Array[String] = game.score.trick_history
		var forwarded: Array[String] = game.feature_hub.identities
		check.call(game.score.combo_trick_count == 2
			and game.score.combo_base == int(alias_entry.base_points)+Catalog.repeated_points(canonical.base_points,1)
			and history == [alias_entry.display_name,canonical.display_name]
			and forwarded[-2] == alias_entry.id and forwarded[-1] == canonical.id,
			"alias repetition: %s then %s share staleness while real receipt names and feature IDs survive" % pair)
		game.score.reset()
		game._on_trick(canonical.display_name,canonical.base_points)
		game._on_trick(alias_entry.display_name,alias_entry.base_points)
		check.call(game.score.last_award == Catalog.repeated_points(alias_entry.base_points,1),
			"alias repetition: reverse canonical-to-alias order cannot evade degradation "+str(pair[0]))
	for pair: Array in [["double_varial_flip","double_varial_kickflip"],["triple_varial_flip","triple_varial_kickflip"]]:
		game.score.reset()
		var alias_entry := Catalog.definition(pair[0])
		var canonical := Catalog.definition(pair[1])
		var base := Catalog.definition("varial_flip")
		game._on_trick(canonical.display_name,canonical.base_points)
		game._on_trick(base.display_name,base.base_points)
		game._on_trick_upgraded(alias_entry.display_name,alias_entry.base_points,alias_entry.id)
		check.call(game.score.combo_trick_count == 2 and game.score.trick_history.size() == 2
			and game.score.last_award == Catalog.repeated_points(alias_entry.base_points,1)
			and game.score.combo_base == int(canonical.base_points)+Catalog.repeated_points(alias_entry.base_points,1)
			and game.score.trick_history[-1] == alias_entry.display_name,
			"alias repetition: a real upgrade callback retains one entry and canonical staleness "+str(pair[0]))
	game.score.reset()
	var backside := Catalog.definition("pop_shuvit")
	var frontside := Catalog.definition("frontside_shuvit")
	game._on_trick(backside.display_name,backside.base_points)
	game._on_trick(frontside.display_name,frontside.base_points)
	check.call(game.score.last_award == int(frontside.base_points)
		and Catalog.repetition_id(frontside.id) == frontside.id
		and frontside.board_yaw < 0.0 and backside.board_yaw > 0.0
		and Catalog.repetition_id("frontside_shuvit_360") == "frontside_shuvit_360"
		and Catalog.repetition_id("frontside_shuvit_540") == "frontside_shuvit_540",
		"alias repetition: genuinely opposite Frontside rotations keep their own identities and full first award")
	check.call(Catalog.repetition_id("grind_50_50") == Catalog.repetition_id("rail_grind")
		and Catalog.repetition_id("boardslide") != Catalog.repetition_id("lipslide")
		and Catalog.repetition_id("unknown").is_empty(),
		"alias repetition: equivalent loaded rails compare equal while distinct slides and unknown IDs remain separate")
	game.free()
	fixture.queue_free()
	await tree.process_frame
