extends RefCounted
## Callback-driven presentation fixtures. No score, physics or human-play claim.
## Public encounter snapshots still feed the real HUD after world text is hidden.

const MoSource = preload("res://game/characters/glasgow_encounters.gd")
const CatSource = preload("res://game/characters/cat_encounter.gd")
const MarketSource = preload("res://game/characters/market_encounter.gd")
const HUDSource = preload("res://game/ui/hud.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var fixture := Node3D.new()
	fixture.name = "EnvironmentTextFixture"
	fixture.process_mode = Node.PROCESS_MODE_DISABLED
	tree.root.add_child(fixture)
	var hud = HUDSource.new()
	fixture.add_child(hud)
	var definitions: Array = game.world.get_encounter_definitions()
	var mo = MoSource.new()
	var cat = CatSource.new()
	var market = MarketSource.new()
	for encounter: Node3D in [mo, cat, market]:
		fixture.add_child(encounter)
		encounter.configure(definitions)
	var actors: Array[Node3D] = [mo.get_node("MoBusker"), cat.get_node("RaeBinBusker"), market.get_node("MarketStallholder")]
	check.call(_no_billboards(actors) and _state_labels_hidden(actors),
		"environment text: all three encounters start without visible hovering or billboard labels")
	_physical_lettering(actors, check)
	var original_geometry := _geometry_count(fixture)
	for encounter: Node3D in [mo, cat, market]:
		var at: Vector3 = encounter.status_snapshot().position
		_display(hud, encounter, at)
		check.call(not hud._prompt.text.is_empty() and hud._challenge.text.is_empty(),
			"environment text: nearby idle interaction remains in the HUD for " + encounter.status_snapshot().title)
		encounter.poll(at, true, 0.0)
		_display(hud, encounter, at)
		check.call(encounter.status_snapshot().state == "active" and not hud._challenge.text.is_empty()
			and hud._challenge.text == encounter.status_snapshot().hud_text,
			"environment text: accepted challenge progress reaches the real HUD for " + encounter.status_snapshot().title)
		encounter.on_bail()
		_display(hud, encounter, at)
		check.call(encounter.status_snapshot().state == "failed" and not hud._challenge.text.is_empty()
			and not hud._prompt.text.is_empty() and _state_labels_hidden(actors),
			"environment text: failure and retry remain visible in the HUD without restoring hovering signs")
		encounter.poll(at, true, 0.0)
	var mo_at: Vector3 = mo.status_snapshot().position
	for trick: String in ["Ollie", "Kickflip", "Melon Grab"]: mo.on_trick(trick, 300, mo_at)
	mo.on_bank(1000, mo_at)
	var cat_at: Vector3 = cat.status_snapshot().area_center
	for rail_id: String in cat.status_snapshot().required_ids: cat.on_grind_capture(rail_id, cat_at)
	cat.on_bank(600, cat_at)
	var market_at: Vector3 = market.status_snapshot().position
	market.on_trick("Manual", 100, market_at)
	market.on_gap(market.status_snapshot().required_gap, market_at)
	market.on_bank(1000, market_at)
	var route: Dictionary = {}
	for definition: Dictionary in definitions:
		if definition.id == "gull_proof_delivery": route = definition.routes[0]
	for gate: Vector3 in route.get("gates", []): market.poll(gate, false, 0.0)
	market.poll(market.status_snapshot().payoff_position, false, 0.0)
	for encounter: Node3D in [mo, cat, market]:
		_display(hud, encounter, encounter.status_snapshot().position)
		check.call(encounter.status_snapshot().state == "success" and not hud._challenge.text.is_empty()
			and hud._challenge.text == encounter.status_snapshot().hud_text and _state_labels_hidden(actors),
			"environment text: completed challenge stays readable in the HUD while world signs stay hidden")
	var market_actor: Node3D = actors[2]
	var marker: Node3D = market_actor.get_node("RouteMarkers/DeliveryArrival")
	market_actor.set_navigation_targets([{"position": marker.global_position}])
	check.call(bool(marker.get_meta("navigation_active", false))
		and marker.get_node("GroundRing").is_visible_in_tree()
		and not marker.get_node("RouteLabel").visible,
		"environment text: the existing ground ring can guide an active target without a floating route caption")
	market_actor.set_encounter_state("success", 0.0, true, "static", "")
	check.call(_no_billboards(actors) and _state_labels_hidden(actors)
		and _geometry_count(fixture) == original_geometry,
		"environment text: success, target updates and reduced motion add no geometry or visible billboard text")
	fixture.free()


static func _display(hud: CanvasLayer, encounter: Node3D, at: Vector3) -> void:
	var status: Dictionary = encounter.status_snapshot()
	hud.update_display({"challenge_text": status.hud_text, "interaction_prompt": encounter.nearby_prompt(at),
		"paused": false, "finished": false, "settings": {"reduced_motion": true}})


static func _state_labels_hidden(actors: Array[Node3D]) -> bool:
	for index in actors.size():
		var paths: Array[String] = []
		match index:
			0: paths.append("ChallengeSign")
			1: paths.append("PitchSign")
			2: paths.assign(["PickupSign", "DeliveryCounter/DeliverySign"])
		for path: String in paths:
			var label := actors[index].get_node_or_null(path) as Label3D
			if label == null or label.visible: return false
		if index == 2:
			for label: Label3D in actors[index].get_node("RouteMarkers").find_children("RouteLabel", "Label3D", true, false):
				if label.visible: return false
	return true


static func _no_billboards(actors: Array[Node3D]) -> bool:
	for actor: Node3D in actors:
		for label: Label3D in actor.find_children("*", "Label3D", true, false):
			if label.billboard != BaseMaterial3D.BILLBOARD_DISABLED: return false
	return true


static func _physical_lettering(actors: Array[Node3D], check: Callable) -> void:
	var case_sign := actors[0].get_node("BuskerCaseSign") as Label3D
	check.call(case_sign.is_visible_in_tree() and case_sign.billboard == BaseMaterial3D.BILLBOARD_DISABLED
		and case_sign.text == "GIE IT LALDY",
		"environment text: the existing backed guitar-case lettering remains fixed physical signage")
	var market_actor: Node3D = actors[2]
	var note := market_actor.get_node("PickupCounterNote") as Label3D
	var counter := market_actor.get_node("PickupCounter") as MeshInstance3D
	var top := counter.to_global(Vector3(0, counter.mesh.get_aabb().end.y, 0))
	check.call(note.is_visible_in_tree() and absf(note.global_position.y - top.y) < 0.005
		and note.global_basis.z.dot(Vector3.UP) > 0.99,
		"environment text: pickup lettering lies on the existing counter rather than hovering above it")
	var spare := market_actor.get_node("DeliveryCounter/SpareParcel") as Node3D
	var wrapper_note := spare.get_node("SpareWrapperNote") as Label3D
	check.call(wrapper_note.is_visible_in_tree() and wrapper_note.get_parent() == spare
		and wrapper_note.basis.z.dot(Vector3.UP) > 0.99 and wrapper_note.position.y < 0.05,
		"environment text: spare lettering is attached to the actual wrapper and follows the gull pickup")


static func _geometry_count(parent: Node) -> int:
	return parent.find_children("*", "MeshInstance3D", true, false).size()
