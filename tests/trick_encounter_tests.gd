extends RefCounted
## Callback contract fixtures: these check catalog-to-encounter integration, not
## physical performances. The ordinary encounter suites retain actual play routes.
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Busker = preload("res://game/characters/glasgow_encounters.gd")
const Market = preload("res://game/characters/market_encounter.gd")

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var busker = Busker.new()
	tree.root.add_child(busker)
	busker.configure([{"id": "busker_big_finish", "position": Vector3.ZERO}])
	busker.on_trick("Pop Shove-it", 250, Vector3.ZERO)
	check.call(busker.status_snapshot().family_count == 0,
		"trick encounters: catalog variants cannot enter an inactive busker attempt")
	busker.poll(Vector3.ZERO, true, 0.0)
	busker.on_trick("Pop Shove-it", 0, Vector3.ZERO)
	busker.on_trick("Boardslide", -1, Vector3.ZERO)
	check.call(busker.status_snapshot().family_count == 0,
		"trick encounters: nonpositive variant awards cannot add challenge variety")
	busker.on_trick("Pop Shove-it", 250, Vector3.ZERO)
	check.call(busker.status_snapshot().family_count == 1,
		"trick encounters: Pop Shove-it supplies the flip family despite its display name")
	busker.on_trick("Boardslide", 250, Vector3.ZERO)
	busker.on_trick("Lipslide", 300, Vector3.ZERO)
	check.call(busker.status_snapshot().family_count == 2,
		"trick encounters: board and lip slides supply one shared grind family")
	busker.on_trick("Nose Manual", 150, Vector3.ZERO)
	busker.on_bank(1950, Vector3.ZERO)
	check.call(busker.status_snapshot().state == "success" and busker.status_snapshot().wins == 1,
		"trick encounters: three real catalog families can complete the busker's bank contract")
	for family: String in ["flip", "grab", "grind", "manual"]:
		busker.reset_run()
		busker.poll(Vector3.ZERO, true, 0.0)
		for trick_id: String in Catalog.family_ids(family):
			var entry := Catalog.definition(trick_id)
			busker.on_trick(entry.display_name, entry.base_points, Vector3.ZERO)
		check.call(busker.status_snapshot().family_count == 1,
			"trick encounters: every authored %s variant resolves to one challenge family" % family)
	busker.on_trick("Pop Shove-it", 250, Vector3(35, 0, 0))
	busker.on_trick("Indy Grab", 250, Vector3.ZERO)
	check.call(not busker.status_snapshot().combo_valid and busker.status_snapshot().family_count == 0,
		"trick encounters: catalog lookup cannot bypass the busker's court boundary")
	busker.queue_free()

	var definition: Dictionary = {}
	for raw: Dictionary in game.world.get_encounter_definitions():
		if raw.get("id", "") == "gull_proof_delivery":
			definition = raw.duplicate(true)
	check.call(not definition.is_empty(), "trick encounters: delivery uses the real authored market definition")
	if definition.is_empty():
		await tree.process_frame
		return
	var market = Market.new()
	tree.root.add_child(market)
	market.configure([definition])
	var pickup: Vector3 = definition.position
	market.on_trick("Nose Manual", 150, pickup)
	check.call(not market.status_snapshot().manual_seen,
		"trick encounters: a nose manual cannot arm delivery before pickup")
	market.poll(pickup, true, 0.0)
	market.on_trick("Nose Manual", 0, pickup)
	market.on_trick("Imaginary Nose Manual", 150, pickup)
	market.on_trick("Pop Shove-it", 250, pickup)
	check.call(not market.status_snapshot().manual_seen,
		"trick encounters: delivery rejects zero awards, invented manual labels and other families")
	market.on_trick("Nose Manual", 150, pickup)
	check.call(market.status_snapshot().manual_seen,
		"trick encounters: a supported catalog nose manual arms the requested market line")
	market.on_gap(definition.required_gap, pickup)
	market.on_bank(1800, pickup)
	check.call(market.status_snapshot().line_banked and market.status_snapshot().state == "active",
		"trick encounters: nose manual then required gap and bank qualify without inventing route arrival")
	market.reset_run()
	market.poll(pickup, true, 0.0)
	market.finish_run()
	market.on_trick("Nose Manual", 150, pickup)
	check.call(not market.status_snapshot().manual_seen,
		"trick encounters: run expiry rejects catalog manual callbacks")
	market.queue_free()
	await tree.process_frame
