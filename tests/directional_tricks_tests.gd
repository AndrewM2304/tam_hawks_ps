extends RefCounted
## Directional selection is tested independently of player motion and animation.

const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Directional = preload("res://game/tricks/directional_tricks.gd")


static func run(check: Callable) -> void:
	var cases: Array = [
		["flip", Vector2.ZERO, "kickflip"],
		["flip", Vector2.LEFT, "kickflip"],
		["flip", Vector2.RIGHT, "heelflip"],
		["flip", Vector2.UP, "frontside_shuvit"],
		["flip", Vector2.DOWN, "pop_shuvit"],
		["flip", Vector2(-1, 1), "varial_flip"],
		["flip", Vector2(1, -1), "hardflip"],
		["grab", Vector2.ZERO, "melon_grab"],
		["grab", Vector2.LEFT, "melon_grab"],
		["grab", Vector2.RIGHT, "indy_grab"],
		["grab", Vector2.UP, "nose_grab"],
		["grab", Vector2.DOWN, "tail_grab"],
		["grab", Vector2(-1, -1), "method_grab"],
		["manual", Vector2.ZERO, "manual"],
		["manual", Vector2.UP, "nose_manual"],
		["manual", Vector2.DOWN, "manual"],
		["manual", Vector2.LEFT, "manual"],
		["manual", Vector2.RIGHT, "manual"],
		["lip", Vector2.ZERO, "axle_stall"],
		["lip", Vector2.UP, "nose_stall"],
		["lip", Vector2.DOWN, "tail_stall"],
		["lip", Vector2.LEFT, "disaster"],
		["lip", Vector2.RIGHT, "disaster"],
	]
	for sample: Array in cases:
		check.call(_id(sample[0], sample[1]) == sample[2],
			"directional tricks: %s %s selects %s" % sample)

	check.call(_id("flip", Vector2(0.349, -0.349)) == "kickflip"
		and _id("grab", Vector2(0.349, -0.349)) == "melon_grab"
		and _id("manual", Vector2(0, -0.349)) == "manual",
		"directional tricks: small stick drift preserves each neutral default")
	check.call(_id("flip", Vector2(0.35, 0)) == "heelflip"
		and _id("manual", Vector2(0, -0.35)) == "nose_manual"
		and _id("flip", Vector2(-0.35, 0.35)) == "varial_flip",
		"directional tricks: cardinal and named diagonal thresholds include exactly 0.35")
	check.call(_id("flip", Vector2(-0.35, 1)) == "varial_flip"
		and _id("flip", Vector2(1, -0.35)) == "hardflip"
		and _id("grab", Vector2(-0.35, -1)) == "method_grab",
		"directional tricks: authored diagonals take priority over the stronger cardinal")
	check.call(_id("flip", Vector2(-0.6, -0.9)) == "frontside_shuvit"
		and _id("flip", Vector2(-0.9, -0.6)) == "kickflip"
		and _id("grab", Vector2(0.6, 0.9)) == "tail_grab"
		and _id("grab", Vector2(0.9, 0.6)) == "indy_grab",
		"directional tricks: unassigned diagonals resolve to the dominant cardinal")
	check.call(_id("flip", Vector2(-1, -1)) == "kickflip"
		and _id("grab", Vector2(1, 1)) == "indy_grab"
		and _id("lip", Vector2(-1, -1)) == "disaster",
		"directional tricks: equal unassigned diagonals resolve deterministically to horizontal")
	check.call(_id("manual", Vector2(0.4, -0.9)) == "nose_manual"
		and _id("manual", Vector2(0.9, -0.4)) == "manual",
		"directional tricks: nose manual requires an up-dominant stick rather than any negative Y drift")
	for bad_input: Vector2 in [Vector2(NAN, 0), Vector2(0, INF), Vector2(-INF, NAN)]:
		check.call(Directional.select("flip", bad_input).is_empty(),
			"directional tricks: nonfinite device input rejects without a fallback award")
	check.call(Directional.select("unknown", Vector2.ZERO).is_empty()
		and Directional.select("", Vector2.ONE).is_empty(),
		"directional tricks: unsupported categories cannot select or score a fallback")

	var copy: Dictionary = Directional.select("grab", Vector2.UP)
	copy["base_points"] = 999999
	copy["allowed_states"].append("ground")
	check.call(Directional.select("grab", Vector2.UP)["base_points"] == 300
		and not Catalog.can_perform("nose_grab", "ground"),
		"directional tricks: callers cannot mutate catalogue points or nested eligibility")
	check.call(Catalog.validate_definitions().is_empty(),
		"directional tricks: expanded original definitions retain the complete authoring schema")
	var expected_counts := {"flip": 6, "grab": 5, "manual": 2, "lip": 4}
	for category: String in expected_counts:
		var reachable: Dictionary = {}
		for x: float in [-1.0, 0.0, 1.0]:
			for y: float in [-1.0, 0.0, 1.0]:
				reachable[_id(category, Vector2(x, y))] = true
		check.call(reachable.size() == expected_counts[category] and not reachable.has(""),
			"directional tricks: every authored %s variant is reachable from a normal input" % category)

	var lip_eligible := true
	for trick_id: String in ["axle_stall", "nose_stall", "tail_stall", "disaster"]:
		lip_eligible = lip_eligible and Catalog.can_perform(trick_id, "lip") \
			and not Catalog.can_perform(trick_id, "ground") \
			and not Catalog.can_perform(trick_id, "air") \
			and not Catalog.can_perform(trick_id, "grind")
	check.call(lip_eligible and Catalog.can_perform("ollie", "lip"),
		"directional tricks: lip awards require actual lip state while ollie can pop out")
	check.call(Catalog.can_transition("air", "lip") and Catalog.can_transition("lip", "air")
		and Catalog.can_transition("lip", "ground") and Catalog.can_transition("lip", "bail")
		and not Catalog.can_transition("ground", "lip") and not Catalog.can_transition("grind", "lip")
		and not Catalog.can_transition("lip", "lip") and not Catalog.can_transition("bail", "lip"),
		"directional tricks: lip capture, release and recovery have explicit non-repeating structural paths")
	check.call(Catalog.base_points("kickflip") == 300 and Catalog.base_points("melon_grab") == 250
		and Catalog.base_points("manual") == 100 and Catalog.base_points("rail_grind") == 200
		and Catalog.base_points("revert") == 150 and Catalog.base_points("ollie") == 100
		and Catalog.base_points("special_clyde_carousel") == 1000
		and Catalog.base_points("special_tenement_tumble") == 1200,
		"directional tricks: existing career and encounter trick values retain compatibility")


static func _id(category: String, direction: Vector2) -> String:
	return String(Directional.select(category, direction).get("id", ""))
