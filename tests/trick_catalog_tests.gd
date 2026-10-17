extends RefCounted
## Contract tests for trick authoring, defensive lookup and structural state guards.

const Catalog = preload("res://game/tricks/trick_catalog.gd")
const ScoreSession = preload("res://game/scoring/score_session.gd")

static func run(check: Callable) -> void:
	check.call(Catalog.validate_definitions().is_empty(),
		"trick catalog: every authored definition satisfies the schema")
	var ids: Array[String] = Catalog.ids()
	var unique_ids: Dictionary = {}
	for trick_id: String in ids:
		unique_ids[trick_id] = true
	check.call(ids.size() == unique_ids.size() and ids.has("rail_grind")
		and ids.has("manual") and ids.has("revert"),
		"trick catalog: core continuation mechanics have unique stable IDs")
	var kickflip: Dictionary = Catalog.definition("kickflip")
	kickflip["base_points"] = 99999
	kickflip["allowed_states"].append("bail")
	check.call(Catalog.base_points("kickflip") == 300
		and not Catalog.can_perform("kickflip", "bail"),
		"trick catalog: editing a lookup copy cannot alter shared scoring or state data")
	ids.clear()
	check.call(not Catalog.ids().is_empty(),
		"trick catalog: editing an ID-list copy cannot erase the catalog")
	check.call(Catalog.definition("not_a_trick").is_empty()
		and not Catalog.is_known("not_a_trick") and Catalog.base_points("not_a_trick") == 0,
		"trick catalog: unknown IDs cannot acquire a fallback scoring definition")
	check.call(not Catalog.can_perform("not_a_trick", "air")
		and not Catalog.can_perform("kickflip", "not_a_state"),
		"trick catalog: unknown trick or state rejects execution eligibility")
	check.call(Catalog.can_perform("kickflip", "air")
		and not Catalog.can_perform("kickflip", "ground")
		and not Catalog.can_perform("rail_grind", "air"),
		"trick catalog: air tricks and rail-entry awards cannot use the wrong movement state")
	check.call(Catalog.can_perform("ollie", "ground")
		and Catalog.can_perform("ollie", "grind")
		and Catalog.can_perform("ollie", "manual")
		and not Catalog.can_perform("ollie", "air"),
		"trick catalog: supported launch states are explicit and midair ollies reject")

	var expected_links: Array = [
		["ground", "air"], ["ground", "manual"], ["ground", "revert"],
		["air", "ground"], ["air", "grind"], ["grind", "air"], ["grind", "ground"],
		["manual", "ground"], ["manual", "air"], ["revert", "ground"],
		["revert", "manual"], ["revert", "air"], ["bail", "ground"],
	]
	var links_allowed := true
	for link: Array in expected_links:
		links_allowed = links_allowed and Catalog.can_transition(link[0], link[1])
	check.call(links_allowed,
		"trick catalog: launch, landing, grind release, manual/revert links and recovery have structural paths")
	var invalid_links: Array = [
		["ground", "grind"], ["air", "manual"], ["air", "revert"],
		["grind", "manual"], ["grind", "revert"], ["manual", "revert"],
		["bail", "air"], ["bail", "grind"], ["bail", "manual"],
		["not_a_state", "air"], ["air", "not_a_state"],
	]
	var invalid_rejected := true
	for link: Array in invalid_links:
		invalid_rejected = invalid_rejected and not Catalog.can_transition(link[0], link[1])
	check.call(invalid_rejected,
		"trick catalog: unsupported snaps, airborne manuals, bail tricks and unknown states reject")
	var self_updates_rejected := true
	var bail_paths_present := true
	for state: String in Catalog.STATES:
		self_updates_rejected = self_updates_rejected and not Catalog.can_transition(state, state)
		if state != "bail":
			bail_paths_present = bail_paths_present and Catalog.can_transition(state, "bail")
	check.call(self_updates_rejected,
		"trick catalog: same-state updates cannot become repeated entry awards")
	check.call(bail_paths_present,
		"trick catalog: every active movement state can enter hazard recovery")

	var session = ScoreSession.new()
	var repeat_matches := true
	for repeats: int in 8:
		var before: int = session.combo_base
		session.add_trick("Reference kickflip", 300)
		repeat_matches = repeat_matches and Catalog.repeated_points(300, repeats) == session.combo_base - before
	check.call(repeat_matches,
		"trick catalog: proposed repeat helper preserves current scoring through and beyond the degradation cap")
	check.call(Catalog.repeated_points(0, 0) == 0 and Catalog.repeated_points(-10, 0) == 0
		and Catalog.repeated_points(100, -10) == 100,
		"trick catalog: invalid base points award nothing and negative repeat counts cannot boost values")
	check.call(Catalog.repeated_points(1, 999) == 1 and Catalog.repeated_points(100, 999) == 6,
		"trick catalog: long repetition remains bounded and positive with integer rounding")

	check.call(_has_error(Catalog.validate_definitions([]), "at least one"),
		"trick catalog: empty authoring data reports an error")
	check.call(_has_error(Catalog.validate_definitions([null, 123, "bad"]), "Dictionary"),
		"trick catalog: non-record values reject without unsafe conversion")
	check.call(_has_error(Catalog.validate_definitions([{}]), "id must")
		and _has_error(Catalog.validate_definitions([{}]), "base_points")
		and _has_error(Catalog.validate_definitions([{}]), "allowed_states"),
		"trick catalog: missing required fields produce actionable validation errors")
	check.call(_has_error(Catalog.validate_definitions(_with_field("id", 123)), "id must")
		and _has_error(Catalog.validate_definitions(_with_field("id", "")), "id must"),
		"trick catalog: numeric and empty IDs reject")
	check.call(_has_error(Catalog.validate_definitions(_with_field("id", "Bad ID")), "lowercase identifier"),
		"trick catalog: unstable display-like IDs reject")
	var duplicate: Array = [Catalog.definition("kickflip"), Catalog.definition("kickflip")]
	check.call(_has_error(Catalog.validate_definitions(duplicate), "duplicate id"),
		"trick catalog: duplicate stable IDs reject")
	check.call(_has_error(Catalog.validate_definitions(_with_field("display_name", "  ")), "display_name")
		and _has_error(Catalog.validate_definitions(_with_field("display_name", 123)), "display_name"),
		"trick catalog: blank or non-text visible names reject")
	var bad_points_rejected := true
	for points: Variant in [null, "300", 300.0, 0, -1, Catalog.MAX_BASE_POINTS + 1]:
		bad_points_rejected = bad_points_rejected and _has_error(
			Catalog.validate_definitions(_with_field("base_points", points)), "base_points")
	check.call(bad_points_rejected,
		"trick catalog: missing, non-integer, nonpositive and excessive base points reject")
	check.call(_has_error(Catalog.validate_definitions(_with_field("allowed_states", [])), "nonempty Array")
		and _has_error(Catalog.validate_definitions(_with_field("allowed_states", "air")), "nonempty Array"),
		"trick catalog: missing state membership cannot silently authorize all states")
	check.call(_has_error(Catalog.validate_definitions(_with_field("allowed_states", ["flying"])), "unknown state")
		and _has_error(Catalog.validate_definitions(_with_field("allowed_states", [null])), "unknown state"),
		"trick catalog: unknown and non-text state names reject")
	check.call(_has_error(Catalog.validate_definitions(_with_field("allowed_states", ["air", "air"])), "duplicate state"),
		"trick catalog: duplicate state membership is reported to the author")
	check.call(_has_error(Catalog.validate_definitions(_with_field("activation", "every_frame")), "activation")
		and _has_error(Catalog.validate_definitions(_with_field("activation", 123)), "activation"),
		"trick catalog: unrecognized scoring-event authoring rejects")

static func _with_field(key: String, value: Variant) -> Array:
	var entry: Dictionary = Catalog.definition("kickflip")
	entry[key] = value
	return [entry]

static func _has_error(errors: Array[String], fragment: String) -> bool:
	for error: String in errors:
		if fragment in error:
			return true
	return false
