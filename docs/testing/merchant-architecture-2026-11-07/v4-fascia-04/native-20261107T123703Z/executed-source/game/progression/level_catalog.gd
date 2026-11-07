extends RefCounted
## Metadata only: obtaining a definition never loads or instantiates a world.
const BaseCareer = preload("res://game/progression/career_progress.gd")
const DEFAULT_LEVEL := "merchant_neighbourhood_v1"
const LEGACY_LEVEL := "glasgow_legacy_v1"
const MERCHANT_CAREER: Dictionary = {
	"schema_version": 1,
	"level_id": "merchant_neighbourhood_v1",
	"goals": [
		{
			"id": "md_first_shift",
			"title": "First shift",
			"kind": "score",
			"target": 1000,
			"detail": "Bank 1,000 points in one Merchant District run."
		},
		{
			"id": "md_good_shift",
			"title": "Good shift",
			"kind": "score",
			"target": 5000,
			"detail": "Bank 5,000 points in one Merchant District run."
		},
		{
			"id": "md_some_shift",
			"title": "Some shift",
			"kind": "score",
			"target": 15000,
			"detail": "Bank 15,000 points in one Merchant District run."
		},
		{
			"id": "md_one_long_line",
			"title": "One long line",
			"kind": "combo",
			"target": 3000,
			"detail": "Bank one combo worth 3,000 points."
		},
		{
			"id": "md_letters",
			"title": "Letters through the district",
			"kind": "letter",
			"target": 5,
			"detail": "Collect the five letters through the district in one run."
		},
		{
			"id": "md_cone_duty",
			"title": "Cone duty",
			"kind": "interaction",
			"target": 1,
			"detail": "Knock the marked sign cone loose."
		},
		{
			"id": "md_roof_gap",
			"title": "Across the roofs",
			"kind": "gap",
			"target": 1,
			"detail": "Clear the high roof channel gap."
		},
		{
			"id": "md_market_sweep",
			"title": "Market sweep",
			"kind": "market_item",
			"target": 3,
			"detail": "Collect three market items in one run."
		},
		{
			"id": "md_four_corners",
			"title": "Four corners",
			"kind": "district",
			"target": 4,
			"detail": "Visit the four local zones in one run."
		},
		{
			"id": "md_lost_recording",
			"title": "Lost recording",
			"kind": "collectible",
			"target": 1,
			"detail": "Find the hidden recording."
		}
	],
	"accepted_events": {
		"letter": [
			"md_letter_h",
			"md_letter_a",
			"md_letter_w",
			"md_letter_k",
			"md_letter_s"
		],
		"interaction": [
			"md_cone"
		],
		"gap": [
			"md_roof_channel"
		],
		"market_item": [
			"md_market_1",
			"md_market_2",
			"md_market_3"
		],
		"district": [
			"md_upper_steps",
			"md_market_cross",
			"md_warehouse_row",
			"md_foundry_basin"
		],
		"collectible": [
			"md_secret_recording"
		]
	},
	"global_unlocks": {
		"md_first_shift": [
			"color_orange",
			"special_clyde_carousel"
		],
		"md_some_shift": [
			"color_purple"
		],
		"md_one_long_line": [
			"special_tenement_tumble"
		]
	},
	"old_domain": "glasgow_legacy_v1",
	"old_goal_ids_reused": false,
	"old_profile_not_overwritten": true
}

static func ids() -> Array[String]:
	return [DEFAULT_LEVEL,LEGACY_LEVEL]

static func definition(id: String) -> Dictionary:
	if id not in ids(): return {}
	var path := "res://game/levels/merchant_neighbourhood.gd" if id == DEFAULT_LEVEL else "res://game/levels/glasgow_square.gd"
	return {"id":id,"label":"Merchant District" if id == DEFAULT_LEVEL else "City Tour",
		"description":"Interconnected streets, roof routes and shared courts." if id == DEFAULT_LEVEL else "The original wider Glasgow city and its ten career goals.",
		"world_path":path,"world_script":path,"career":career(id)}

static func career(id: String) -> Dictionary:
	if id == DEFAULT_LEVEL: return MERCHANT_CAREER.duplicate(true)
	if id != LEGACY_LEVEL: return {}
	var goals: Array = BaseCareer.GOALS.duplicate(true)
	var kinds := {"first_shift":"score","good_shift":"score","some_shift":"score","one_long_line":"combo",
		"letters":"letter","cone":"interaction","platform_change":"gap","market_sweep":"market_item","across_toon":"district","lost_recording":"collectible"}
	for goal: Dictionary in goals: goal["kind"] = kinds[goal.id]
	return {"schema_version":1,"level_id":LEGACY_LEVEL,"goals":goals,
		"accepted_events":{"letter":BaseCareer.LETTER_IDS.duplicate(),"market_item":BaseCareer.MARKET_IDS.duplicate(),
			"district":BaseCareer.DISTRICT_IDS.duplicate(),"interaction":["cone"],"gap":["central_gap"],"collectible":["secret_recording"]},
		"global_unlocks":{"first_shift":["color_orange","special_clyde_carousel"],"some_shift":["color_purple"],"one_long_line":["special_tenement_tumble"]}}
