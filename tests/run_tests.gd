extends SceneTree
## Dependency-free unit and physics integration checks. Run with tools/check.sh.

const MAP_CONNECTOR_TESTS = preload("res://tests/map_connector_tests.gd")
const HORIZON_TESTS = preload("res://tests/horizon_background_tests.gd")
const COMPACT_CLYDE_TESTS = preload("res://tests/test_compact_clyde.gd")
const COMPACT_CLYDE_LINES = preload("res://tests/compact_clyde_lines_tests.gd")
const EDGE_GRIND_TESTS = preload("res://tests/edge_grind_integration_tests.gd")
const SUPPORT_QUERY_TESTS = preload("res://tests/support_query_tests.gd")
const GLASGOW_MURALS_TESTS = preload("res://tests/glasgow_murals_tests.gd")
const GRIND_INDEX_TESTS = preload("res://tests/grind_index_tests.gd")
const SKATE_EDGES_TESTS = preload("res://tests/skate_edges_tests.gd")
const BAIL_RECOVERY_TESTS = preload("res://tests/bail_recovery_tests.gd")
const FLAT_OLLIE_TESTS = preload("res://tests/flat_ollie_tests.gd")
const LIMB_POSE_TESTS = preload("res://tests/limb_pose_tests.gd")
const RAMP_POP_TESTS = preload("res://tests/ramp_pop_tests.gd")
const ARCADE_RESPONSE_TESTS = preload("res://tests/arcade_response_integration_tests.gd")
const ENVIRONMENT_TEXT_TESTS = preload("res://tests/environment_text_tests.gd")
const STATIC_BATCHES_TESTS = preload("res://tests/static_batches_tests.gd")
const PHYSICS_INTERPOLATION_TESTS = preload("res://tests/physics_interpolation_tests.gd")
const HUD_EFFICIENCY_TESTS = preload("res://tests/hud_efficiency_tests.gd")
const HUD_TRICK_LABEL_CACHE_TESTS = preload("res://tests/hud_trick_label_cache_tests.gd")
const GRAPHICS_QUALITY_TESTS = preload("res://tests/graphics_quality_tests.gd")
const CITY_VISIBILITY_TESTS = preload("res://tests/city_visibility_tests.gd")
const FACADE_BAY_TESTS = preload("res://tests/facade_bay_tests.gd")
const CLYDE_SURFACE_TESTS = preload("res://tests/clyde_surface_tests.gd")
const CIVIC_EDGE_TESTS = preload("res://tests/civic_edge_tests.gd")
const OWNER_PLAYTEST_REPAIRS = preload("res://tests/owner_playtest_repairs_tests.gd")
const CITY_BACKDROP_TESTS = preload("res://tests/city_backdrop_tests.gd")
const SCORE_SCRIPT = preload("res://game/scoring/score_session.gd")
const MAIN_SCRIPT = preload("res://game/main.gd")
const INPUT_SETUP = preload("res://game/core/input_setup.gd")
const RAIL_GEOMETRY_TESTS = preload("res://tests/rail_geometry_tests.gd")
const TAKEOFF_TESTS = preload("res://tests/takeoff_tests.gd")
const PLAYER_FORGIVENESS_TESTS = preload("res://tests/player_forgiveness_tests.gd")
const RENDER_BUDGET_TESTS = preload("res://tests/render_budget_tests.gd")
const SKATE_RESPONSE_TESTS = preload("res://tests/skate_response_tests.gd")
const GRINDING_TESTS = preload("res://tests/grinding_tests.gd")
const GRIND_REGRESSION_TESTS = preload("res://tests/grind_regression_tests.gd")
const GRIND_RIDE_TESTS = preload("res://tests/grind_ride_tests.gd")
const GRIND_CAPTURE_BOUNDS_TESTS = preload("res://tests/grind_capture_bounds_tests.gd")
const GRIND_CONTACT_METADATA_TESTS = preload("res://tests/grind_contact_metadata_tests.gd")
const GRIND_STYLE_TESTS = preload("res://tests/grind_style_tests.gd")
const GRIND_VARIANT_TESTS = preload("res://tests/grind_variant_contact_tests.gd")
const NAMED_GRIND_TESTS = preload("res://tests/named_grind_integration_tests.gd")
const NAMED_GRIND_CONSUMERS_TESTS = preload("res://tests/named_grind_consumers_tests.gd")
const CATALOG_TESTS = preload("res://tests/trick_catalog_tests.gd")
const TRICK_INPUT_TESTS = preload("res://tests/trick_input_tests.gd")
const TRICK_SCORE_TESTS = preload("res://tests/trick_score_tests.gd")
const TRICK_POSE_TESTS = preload("res://tests/trick_pose_tests.gd")
const GRAB_POSE_CACHE_TESTS = preload("res://tests/grab_pose_cache_tests.gd")
const TRICK_FIDELITY_TESTS = preload("res://tests/trick_fidelity_tests.gd")
const TRICK_ENCOUNTER_TESTS = preload("res://tests/trick_encounter_tests.gd")
const COMBO_RESOLUTION_TESTS = preload("res://tests/combo_resolution_tests.gd")
const MANUAL_REVERT_TESTS = preload("res://tests/manual_revert_tests.gd")
const COMBO_INTEGRATION_TESTS = preload("res://tests/combo_integration_tests.gd")
const PROGRESSION_TESTS = preload("res://tests/progression_tests.gd")
const SPECIAL_GAP_TESTS = preload("res://tests/special_gap_tests.gd")
const WORLD_ROUTES_TESTS = preload("res://tests/world_routes_tests.gd")
const AUDIO_TESTS = preload("res://tests/audio_tests.gd")
const APPLE_MUSIC_TESTS = preload("res://tests/apple_music_tests.gd")
const MUSIC_UI_TESTS = preload("res://tests/music_ui_tests.gd")
const MUSIC_INTEGRATION_TESTS = preload("res://tests/music_integration_tests.gd")
const CAREER_INTEGRATION_TESTS = preload("res://tests/career_integration_tests.gd")
const INPUT_PROFILE_TESTS = preload("res://tests/input_profile_tests.gd")
const CLASSIC_CONTROL_TESTS = preload("res://tests/classic_control_input_tests.gd")
const UI_INTEGRATION_TESTS = preload("res://tests/ui_integration_tests.gd")
const UI_FEEDBACK_TESTS = preload("res://tests/ui_feedback_tests.gd")
const PRESENTATION_INTEGRATION_TESTS = preload("res://tests/presentation_integration_tests.gd")
const ENCOUNTERS_TESTS = preload("res://tests/glasgow_encounters_tests.gd")
const CAT_ENCOUNTER_TESTS = preload("res://tests/cat_encounter_tests.gd")
const MARKET_ENCOUNTER_TESTS = preload("res://tests/market_encounter_tests.gd")
const EXCHANGE_PLACE_TESTS = preload("res://tests/exchange_place_tests.gd")
const PLAYABILITY_TESTS = preload("res://tests/playability_regression_tests.gd")
const TOPOGRAPHY_TESTS = preload("res://tests/topography_tests.gd")
const CAREER_ROUTE_TESTS = preload("res://tests/career_route_tests.gd")
const DIRECTIONAL_TRICKS_TESTS = preload("res://tests/directional_tricks_tests.gd")
const TRICK_ANIMATION_TESTS = preload("res://tests/trick_animation_tests.gd")
const TRANSITION_RIDE_TESTS = preload("res://tests/transition_ride_tests.gd")
const TRANSITION_GEOMETRY_TESTS = preload("res://tests/transition_geometry_tests.gd")
const CLASSIC_TRICKS_TESTS = preload("res://tests/classic_tricks_integration_tests.gd")
const CAMERA_TURN_REVIEW_TESTS = preload("res://tests/camera_turn_review_tests.gd")
const CAMERA_RAY_REUSE_TESTS = preload("res://tests/camera_ray_reuse_tests.gd")
const ARCADE_ECONOMY_TESTS = preload("res://tests/arcade_economy_tests.gd")
const TRICK_LANGUAGE_TESTS = preload("res://tests/trick_language_tests.gd")
const REPETITION_ALIAS_TESTS = preload("res://tests/repetition_alias_tests.gd")
const WALL_RIDE_TESTS = preload("res://tests/wall_ride_tests.gd")
const OVERNIGHT_INTEGRATION_TESTS = preload("res://tests/overnight_integration_tests.gd")
const FEATURE_TRANSITION_RIDE_TESTS = preload("res://tests/feature_transition_ride_tests.gd")
const SURFACE_COVERAGE_TESTS = preload("res://tests/surface_coverage_tests.gd")
const TRANSITION_PLAYER_TESTS = preload("res://tests/transition_player_tests.gd")
const PROCESS_GUARD_TESTS = preload("res://tests/process_guard_tests.gd")
const FULL_REPERTOIRE_TESTS = preload("res://tests/full_repertoire_tests.gd")
const AUTHENTIC_POSE_TESTS = preload("res://tests/authentic_pose_tests.gd")
const BODY_ATTACHMENT_TESTS = preload("res://tests/skater_body_attachment_tests.gd")
const POGO_ATTACHMENT_TESTS = preload("res://tests/skater_pogo_attachment_tests.gd")
const SKITCH_ATTACHMENT_TESTS = preload("res://tests/skater_skitch_attachment_tests.gd")
const WALL_PRESENTATION_TESTS = preload("res://tests/skater_wall_presentation_tests.gd")
const WALL_TRANSITION_TESTS = preload("res://tests/skater_wall_transition_tests.gd")
const WALL_FLIP_TESTS = preload("res://tests/skater_wall_flip_tests.gd")
const WALL_GRAB_TESTS = preload("res://tests/skater_wall_grab_tests.gd")
const NATIVE_GRIND_TRANSFER_TESTS = preload("res://tests/native_grind_transfer_tests.gd")
const CONNECTED_TRANSITION_TESTS = preload("res://tests/connected_transition_tests.gd")
const REMAINING_FEATURE_TESTS = preload("res://tests/remaining_feature_tests.gd")
const AUTHENTIC_FIDELITY_TESTS = preload("res://tests/authentic_fidelity_integration_tests.gd")
const FULL_LEVEL_DENSITY_TESTS = preload("res://tests/full_level_density_tests.gd")
const PLATFORM_CONTACT_TESTS = preload("res://tests/platform_contact_tests.gd")
const ACTIVITY_ACTOR_TESTS = preload("res://tests/activity_actor_tests.gd")
const ROUTE_AVAILABILITY_TESTS = preload("res://tests/route_availability_tests.gd")
const AMBIENT_ADULT_TESTS = preload("res://tests/ambient_adult_tests.gd")
const CURVED_VISUAL_CONTACT_TESTS = preload("res://tests/curved_visual_contact_tests.gd")
const SKATEPARK_NAVIGATION_TESTS = preload("res://tests/skatepark_navigation_tests.gd")
const GRIND_SURFACE_CONTACT_TESTS = preload("res://tests/grind_surface_contact_tests.gd")
const KELVINGROVE_SKATEPARK_TESTS = preload("res://tests/kelvingrove_skatepark_tests.gd")
const PLAYTEST_RECORDER_TESTS = preload("res://tests/playtest_recorder_tests.gd")
const PARK_CONSTRUCTION_TESTS = preload("res://tests/park_construction_tests.gd")
const PT24_BOUNDARY_TESTS = preload("res://tests/pt24_boundary_tests.gd")
const PT24_CITY_REPAIRS_TESTS = preload("res://tests/pt24_city_repairs_tests.gd")
const STATION_GATE_REPAIRS = preload("res://tests/station_gate_repairs_tests.gd")
const OUTDOOR_REPAIR_TESTS = preload("res://tests/outdoor_repair_tests.gd")
const TERRAIN_TOP_OWNERSHIP_TESTS = preload("res://tests/terrain_top_ownership_tests.gd")
const MERCHANT_RETURN_TESTS = preload("res://tests/merchant_return_tests.gd")
const PT24_ACCEPTANCE_TESTS = preload("res://tests/pt24_acceptance_tests.gd")
const PT24_PARK_FINISH_TESTS = preload("res://tests/pt24_park_finish_tests.gd")
const PT24_RENDER_REPAIRS_TESTS = preload("res://tests/pt24_render_repairs_tests.gd")
const STATION_RAILWAY_TESTS = preload("res://tests/station_railway_tests.gd")
const PARK_POND_TESTS = preload("res://tests/park_pond_tests.gd")
const CLYDE_CABLE_LINE_TESTS = preload("res://tests/clyde_cable_line_tests.gd")
const PT24_DESIGN_INTEGRATION_TESTS = preload("res://tests/pt24_design_integration_tests.gd")
const PT24_MANUAL_GRADE_TESTS = preload("res://tests/pt24_manual_grade_tests.gd")
const PT24_BOWL_CONTACT_TESTS = preload("res://tests/pt24_bowl_contact_tests.gd")
const ACTIONS = [
	"push", "brake", "steer_left", "steer_right", "ollie", "flip", "grab", "grind",
	"spin_left", "spin_right", "restart", "pause", "free_skate",
	"manual", "revert", "special_one", "special_two", "interact", "goals",
]

var passed: int = 0
var failed: int = 0
var game: Node
var observed_tricks: Array[String] = []
var observed_landings: Array[bool] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Tam Hawks Pro Skater — independent QE checks")
	INPUT_SETUP.register_actions()
	_test_score_session()
	SKATE_RESPONSE_TESTS.run(_check)
	RENDER_BUDGET_TESTS.run(_check)
	await STATIC_BATCHES_TESTS.run(self, _check)
	CITY_VISIBILITY_TESTS.run(self, _check)
	await FACADE_BAY_TESTS.run(self, _check)
	await CLYDE_SURFACE_TESTS.run(self, _check)
	await CITY_BACKDROP_TESTS.run(self, _check)
	await OUTDOOR_REPAIR_TESTS.run(self,_check)
	await TERRAIN_TOP_OWNERSHIP_TESTS.run(self,_check)
	await PT24_ACCEPTANCE_TESTS.run(self,_check)
	await PT24_MANUAL_GRADE_TESTS.run(self,_check)
	await PT24_BOWL_CONTACT_TESTS.run(self,_check)
	await PT24_PARK_FINISH_TESTS.run(self,_check)
	await PARK_POND_TESTS.run(self,_check)
	await CLYDE_CABLE_LINE_TESTS.run(self,_check)
	await PT24_DESIGN_INTEGRATION_TESTS.run(self,_check)
	await PHYSICS_INTERPOLATION_TESTS.run(self, _check)
	RAIL_GEOMETRY_TESTS.run(_check)
	GRIND_RIDE_TESTS.run(_check)
	GRIND_CAPTURE_BOUNDS_TESTS.run(_check)
	GRIND_CONTACT_METADATA_TESTS.run(_check)
	GRIND_STYLE_TESTS.run(_check)
	await GRIND_VARIANT_TESTS.run(self, _check)
	GRIND_INDEX_TESTS.run(_check)
	CATALOG_TESTS.run(_check)
	DIRECTIONAL_TRICKS_TESTS.run(_check)
	TRICK_ANIMATION_TESTS.run(self, _check)
	TRICK_INPUT_TESTS.run(_check)
	TRICK_SCORE_TESTS.run(_check)
	COMBO_RESOLUTION_TESTS.run(_check)
	PROGRESSION_TESTS.run(_check)
	INPUT_PROFILE_TESTS.run(_check)
	await CLASSIC_CONTROL_TESTS.run(self, _check)
	SPECIAL_GAP_TESTS.run(_check)
	ARCADE_ECONOMY_TESTS.run(_check)
	TRICK_LANGUAGE_TESTS.run(_check)
	await REPETITION_ALIAS_TESTS.run(self, _check)
	FULL_REPERTOIRE_TESTS.run(_check)
	AUDIO_TESTS.run(self, _check)
	await APPLE_MUSIC_TESTS.run(self, _check)
	await MANUAL_REVERT_TESTS.run(self, _check)
	await TAKEOFF_TESTS.run(self, _check)
	await PLAYER_FORGIVENESS_TESTS.run(self, _check)
	await TRANSITION_RIDE_TESTS.run(self, _check)
	await TRANSITION_GEOMETRY_TESTS.run(self, _check)
	await CAMERA_TURN_REVIEW_TESTS.run(self, _check)
	await CAMERA_RAY_REUSE_TESTS.run(self, _check)
	await CLASSIC_TRICKS_TESTS.run(self, _check)
	await FLAT_OLLIE_TESTS.run(self,_check)
	await LIMB_POSE_TESTS.run(self, _check)
	await RAMP_POP_TESTS.run(self,_check)
	await ARCADE_RESPONSE_TESTS.run(self, _check)
	await EDGE_GRIND_TESTS.run(self, _check)
	await BAIL_RECOVERY_TESTS.run(self, _check)
	await NAMED_GRIND_TESTS.run(self,_check)
	await NAMED_GRIND_CONSUMERS_TESTS.run(self,_check)
	await WALL_RIDE_TESTS.run(self, _check)
	await FEATURE_TRANSITION_RIDE_TESTS.run(self, _check)
	await CONNECTED_TRANSITION_TESTS.run(self, _check)
	await REMAINING_FEATURE_TESTS.run(self, _check)
	await TRICK_POSE_TESTS.run(self, _check)
	await GRAB_POSE_CACHE_TESTS.run(self, _check)
	await AUTHENTIC_POSE_TESTS.run(self, _check)
	await BODY_ATTACHMENT_TESTS.run(self, _check)
	await POGO_ATTACHMENT_TESTS.run(self, _check)
	await SKITCH_ATTACHMENT_TESTS.run(self, _check)
	await WALL_PRESENTATION_TESTS.run(self, _check)
	await WALL_TRANSITION_TESTS.run(self, _check)
	await WALL_FLIP_TESTS.run(self, _check)
	await WALL_GRAB_TESTS.run(self, _check)
	await NATIVE_GRIND_TRANSFER_TESTS.run(self, _check)
	await ACTIVITY_ACTOR_TESTS.run(self, _check)
	await TRICK_SCORE_TESTS.run_ui(self, _check)
	await FULL_REPERTOIRE_TESTS.run_ui(self, _check)
	await ROUTE_AVAILABILITY_TESTS.run_ui(self, _check)
	await SKATEPARK_NAVIGATION_TESTS.run_ui(self, _check)
	game = MAIN_SCRIPT.new()
	game.persistence_enabled = false
	# Historical inventory/A-B control, not the owner's normal launch. Keep
	# exact established counts; design integration and the no-script boot scene
	# independently prove the now-default railway, pond, green and civic return.
	game.set_meta("pt24_design_preview",false)
	root.add_child(game)
	await _physics_frames(35)
	await HORIZON_TESTS.run(self, game.world, _check)
	await PT24_BOUNDARY_TESTS.run(self,game.world,_check)
	await PT24_CITY_REPAIRS_TESTS.run(self,game,_check)
	await MERCHANT_RETURN_TESTS.run(self,game,_check)
	await PARK_CONSTRUCTION_TESTS.run(self,game,_check)
	await STATION_GATE_REPAIRS.run(self,game,_check)
	await PT24_RENDER_REPAIRS_TESTS.run(self,game.world,_check)
	await STATION_RAILWAY_TESTS.run(self,game,_check)
	await CLYDE_CABLE_LINE_TESTS.run_player(self,game,_check)
	await MAP_CONNECTOR_TESTS.run(self, game.world, _check)
	await COMPACT_CLYDE_TESTS.run(self, game.world, _check)
	await WORLD_ROUTES_TESTS.run(self, game.world, _check)
	GRIND_CONTACT_METADATA_TESTS.run_world(game.world,_check)
	await SKATE_EDGES_TESTS.run(game.world, _check)
	await SUPPORT_QUERY_TESTS.run(game.world, _check)
	ENVIRONMENT_TEXT_TESTS.run(self, game, _check)
	GLASGOW_MURALS_TESTS.run(game.world, _check)
	await SURFACE_COVERAGE_TESTS.run(self, game.world, _check)
	_test_structure()
	_test_world_floor()
	_test_ramp_collision_and_boundaries()
	await _test_movement()
	await _test_ramp_routes()
	await _test_jump_tricks_and_landing()
	await _test_spin_scoring()
	await _test_controls_disabled()
	await _test_bail_recovery()
	await _test_run_flow()
	await _test_overtime()
	await _test_input_events()
	await GRINDING_TESTS.run(self, game, _check)
	await GRIND_REGRESSION_TESTS.run(self, game, _check)
	await COMBO_INTEGRATION_TESTS.run(self, game, _check)
	await TRICK_FIDELITY_TESTS.run(self, game, _check)
	await OVERNIGHT_INTEGRATION_TESTS.run(self, game, _check)
	await TRANSITION_PLAYER_TESTS.run(self, game, _check)
	await PROCESS_GUARD_TESTS.run(self, game, _check)
	await AUTHENTIC_FIDELITY_TESTS.run(self, game, _check)
	await CURVED_VISUAL_CONTACT_TESTS.run(self, game, _check)
	await CIVIC_EDGE_TESTS.run(self,game,_check)
	await OWNER_PLAYTEST_REPAIRS.run(self,game,_check)
	await GRIND_SURFACE_CONTACT_TESTS.run(self, game, _check)
	await KELVINGROVE_SKATEPARK_TESTS.run(self, game, _check)
	await FULL_REPERTOIRE_TESTS.run_playable(self, game, _check)
	await FULL_LEVEL_DENSITY_TESTS.run(self, game, _check)
	await PLATFORM_CONTACT_TESTS.run(self, game, _check)
	await REMAINING_FEATURE_TESTS.run_main(self, game, _check)
	await REMAINING_FEATURE_TESTS.run_park_regions_main(self, game, _check)
	await SKATEPARK_NAVIGATION_TESTS.run_world(self, game, _check)
	await ACTIVITY_ACTOR_TESTS.run_world(self, game, _check)
	await AMBIENT_ADULT_TESTS.run(self, game, _check)
	await TRICK_ENCOUNTER_TESTS.run(self, game, _check)
	await CAREER_INTEGRATION_TESTS.run(self, game, _check)
	await UI_INTEGRATION_TESTS.run(self, game, _check)
	await UI_FEEDBACK_TESTS.run(self, game, _check)
	await PLAYTEST_RECORDER_TESTS.run(self,game,_check)
	await HUD_EFFICIENCY_TESTS.run(self, game, _check)
	await HUD_TRICK_LABEL_CACHE_TESTS.run(self, game, _check)
	await GRAPHICS_QUALITY_TESTS.run(self, game, _check)
	await MUSIC_UI_TESTS.run(self, game, _check)
	MUSIC_INTEGRATION_TESTS.run(self, game, _check)
	await PRESENTATION_INTEGRATION_TESTS.run(self, game, _check)
	await ENCOUNTERS_TESTS.run(self, game, _check)
	await CAT_ENCOUNTER_TESTS.run(self, game, _check)
	await MARKET_ENCOUNTER_TESTS.run(self, game, _check)
	await EXCHANGE_PLACE_TESTS.run(self, game, _check)
	await PLAYABILITY_TESTS.run(self, game, _check)
	await TOPOGRAPHY_TESTS.run(self, game, _check)
	await CAREER_ROUTE_TESTS.run(self, game, _check)
	await COMPACT_CLYDE_LINES.run(self, game, _check)
	_release_actions()
	paused = false
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + description)
	else:
		failed += 1
		push_error("FAIL: " + description)


func _test_score_session() -> void:
	var session = SCORE_SCRIPT.new()
	_check(session.total_score == 0 and session.get_combo_value() == 0,
		"new scoring session has no score or active combo")
	session.add_trick("Kickflip", 100)
	_check(session.combo_base == 100 and session.combo_multiplier == 1,
		"first trick contributes its base points and one multiplier")
	session.add_trick("Kickflip", 100)
	session.add_trick("Kickflip", 100)
	_check(session.combo_base == 175 and session.combo_multiplier == 3,
		"each accepted repeat adds a multiplier while its base degrades to half then quarter")
	session.add_trick("Melon Grab", 100)
	_check(session.combo_base == 275 and session.combo_multiplier == 4,
		"a fourth accepted entry contributes the fourth multiplier")
	_check(session.get_combo_value() == 1100 and session.total_score == 0,
		"active combo previews multiplied value without awarding unlanded points")
	var awarded: int = session.bank_combo()
	_check(awarded == 1100 and session.total_score == 1100 and session.best_combo == 1100,
		"landing bank awards combo and records best combo")
	_check(session.get_combo_value() == 0 and session.combo_base == 0,
		"banking clears active combo")
	_check(session.bank_combo() == 0 and session.total_score == 1100,
		"banking twice cannot award the same combo again")
	session.add_trick("Kickflip", 100)
	_check(session.combo_base == 12, "repeat degradation persists through a bank within the run")
	session.drop_combo()
	_check(session.get_combo_value() == 0 and session.total_score == 1100,
		"bailing drops the active combo and preserves previously banked score")
	for i in range(12):
		session.add_trick("Unique trick %d" % i, 100)
	_check(session.combo_multiplier == 12, "accepted entries grow the multiplier beyond the former eight-entry cap")
	session.reset()
	_check(session.total_score == 0 and session.best_combo == 0
		and session.get_combo_value() == 0 and session.last_banked == 0,
		"run reset clears totals, best combo, bank feedback and active combo")


func _test_structure() -> void:
	_check(game.world is Node3D, "main instantiates the procedural world")
	_check(game.skater is CharacterBody3D, "main instantiates the skating physics body")
	_check(_count_nodes(game.skater, "Camera3D") >= 1, "skater includes a gameplay camera")
	_check(_count_nodes(game.world, "MeshInstance3D") >= 15,
		"square contains original procedural visible geometry")
	_check(_count_nodes(game.world, "StaticBody3D") >= 5,
		"floor, obstacles and boundaries include static collision")
	for action in ACTIONS:
		_check(InputMap.has_action(action), "input action is registered: " + action)
	var keyboard_actions: int = 0
	var controller_actions: int = 0
	for action in ACTIONS:
		var has_key: bool = false
		var has_pad: bool = false
		for event in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_pad = has_pad or event is InputEventJoypadButton or event is InputEventJoypadMotion
		keyboard_actions += 1 if has_key else 0
		controller_actions += 1 if has_pad else 0
	_check(keyboard_actions == ACTIONS.size(), "every gameplay action has a keyboard binding")
	_check(controller_actions == ACTIONS.size(), "every gameplay action has a gamepad binding")
	_check(game.world.get_spawn_position().is_equal_approx(Vector3(-22, 0.8, 28)),
		"world spawn matches the shared coordinate contract")
	_check(not game.world.get_location_name(game.skater.global_position).is_empty(),
		"world provides a readable location label")


func _test_world_floor() -> void:
	var spawn: Vector3 = game.world.get_spawn_position()
	var query = PhysicsRayQueryParameters3D.create(spawn + Vector3.UP * 5, spawn - Vector3.UP * 3)
	query.exclude = [game.skater.get_rid()]
	var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
	_check(not hit.is_empty(), "spawn has a supporting collision surface")
	if not hit.is_empty():
		_check(absf(hit.position.y) < 0.1 and hit.normal.y > 0.99,
			"spawn support is a level floor at the documented ground height")
	_check(game.skater.is_on_floor() and not game.skater.airborne,
		"spawn settles onto the floor without falling or becoming stuck airborne")


func _test_ramp_collision_and_boundaries() -> void:
	var ramps: Array[Node] = get_nodes_in_group("skateable_ramps")
	_check(ramps.size() >= 9, "city and outdoor routes include at least nine authored graded surfaces")
	for ramp in ramps:
		# Authored local probes allow a lower bank beneath a genuine upper deck.
		var probe: Vector3 = ramp.get_meta("support_probe", ramp.global_position + Vector3.UP * 39.75)
		var from: Vector3 = probe + Vector3.UP * 0.25
		var query = PhysicsRayQueryParameters3D.create(from, from - Vector3.UP * 80.0, 1)
		var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
		_check(not hit.is_empty() and hit.collider == ramp,
			"graded surface owns its supporting collision: " + ramp.name)
		if not hit.is_empty():
			_check(hit.normal.y >= cos(game.skater.floor_max_angle),
				"graded surface is within the skating floor angle: " + ramp.name)
		_check(_count_nodes(ramp, "MeshInstance3D") > 0,
			"graded collision has visible geometry: " + ramp.name)
	# Closed walls at the former square edge would obstruct the new streets.
	# Route support/clearance and river recovery are exercised by topography tests.
	_check(game.world.get_district_checkpoints().size() == 6,
		"the level exposes six connected places instead of sealing the original square")


func _test_movement() -> void:
	game.restart_run()
	await _physics_frames(30)
	var start: Vector3 = game.skater.global_position
	Input.action_press("push")
	await _physics_frames(30)
	Input.action_release("push")
	_check(game.skater.speed > 0.1 and game.skater.global_position.z < start.z - 0.5,
		"pushing accelerates and travels forward through the central route")
	_check(absf(game.skater.global_position.x - start.x) < 0.25,
		"unsteered flat-ground travel stays on its heading")
	var moving_speed: float = game.skater.speed
	Input.action_press("brake")
	await _physics_frames(24)
	Input.action_release("brake")
	_check(absf(game.skater.speed) < absf(moving_speed), "braking reduces forward speed")
	game.restart_run()
	await _physics_frames(30)
	var heading: float = game.skater.rotation.y
	Input.action_press("push")
	Input.action_press("steer_left")
	await _physics_frames(20)
	_release_actions()
	_check(absf(angle_difference(heading, game.skater.rotation.y)) > 0.05,
		"steering changes heading while skating")


func _test_ramp_routes() -> void:
	game.restart_run()
	await _physics_frames(30)
	Input.action_press("push")
	var max_height: float = 0.0
	for i in range(480):
		await _physics_frames(1)
		max_height = maxf(max_height, game.skater.global_position.y)
	Input.action_release("push")
	_check(max_height > 3.9, "default approach climbs the gallery and George Square terraces")
	_check(game.skater.global_position.z < -60.0 and absf(game.skater.global_position.x + 22.0) < 0.25,
		"default forward route connects the lower square to the upper city without jumping")
	_check(game.skater.is_on_floor(), "uphill city route finishes on supporting collision")
	game.restart_run()
	game.skater.global_position = Vector3(-22.0, 4.8, -80.0)
	game.skater.rotation.y = PI
	await _physics_frames(30)
	Input.action_press("push")
	for i in range(480):
		await _physics_frames(1)
	Input.action_release("push")
	_check(game.skater.global_position.z > 10.0 and absf(game.skater.global_position.x + 22.0) < 0.25,
		"reverse route descends through both terrace transitions to the lower square")
	_check(game.skater.is_on_floor() and game.skater.global_position.y < 0.1,
		"downhill city route finishes on the lower square floor")


func _test_jump_tricks_and_landing() -> void:
	game.restart_run()
	await _physics_frames(30)
	observed_tricks.clear()
	observed_landings.clear()
	game.skater.trick_performed.connect(_record_trick)
	game.skater.landed.connect(_record_landing)
	var resting_y: float = game.skater.global_position.y
	Input.action_press("ollie")
	await _physics_frames(3)
	_check(not game.skater.airborne and game.skater.global_position.y < resting_y + 0.1,
		"holding ollie charges on the floor before release")
	Input.action_release("ollie")
	await _physics_frames(3)
	_check(game.skater.airborne and game.skater.global_position.y > resting_y + 0.1,
		"releasing ollie launches from the floor")
	Input.action_press("ollie")
	Input.action_press("flip")
	Input.action_press("grab")
	await _physics_frames(8)
	_check(game.score.get_combo_value() > 0 and game.score.total_score == 0,
		"aerial tricks create a pending combo before landing")
	# Keep trick inputs held until after touchdown: one press must not farm points.
	await _physics_frames(90)
	_check(observed_tricks.count("Ollie") == 1, "holding ollie does not auto-jump after landing")
	_check(observed_tricks.count("Kickflip") == 1, "held flip registers once during the jump")
	_check(observed_tricks.count("Melon Grab") == 1, "held grab registers once during the jump")
	_check(observed_landings.size() == 1 and observed_landings[0],
		"flat-ground airtime ends in exactly one clean landing signal")
	_check(game.score.total_score > 0 and game.score.get_combo_value() == 0,
		"clean landing banks the observed tricks through the main-to-score wiring")
	_check(game.skater.is_on_floor() and not game.skater.airborne,
		"skater returns to grounded physics state after landing")
	var banked_total: int = game.score.total_score
	await _physics_frames(12)
	_check(game.score.total_score == banked_total and observed_landings.size() == 1,
		"remaining grounded does not emit duplicate landings or awards")
	game.skater.trick_performed.disconnect(_record_trick)
	game.skater.landed.disconnect(_record_landing)
	# Releasing a charged ollie on the floor is a new deliberate pop. Reset the
	# fixture before clearing its held inputs, after proving no held auto-jump.
	game.restart_run()
	_release_actions()


func _test_controls_disabled() -> void:
	game.restart_run()
	await _physics_frames(30)
	game.skater.set_controls_enabled(false)
	var start: Vector3 = game.skater.global_position
	Input.action_press("push")
	Input.action_press("ollie")
	Input.action_press("flip")
	await _physics_frames(20)
	_release_actions()
	_check(game.skater.global_position.distance_to(start) < 0.1
		and game.score.get_combo_value() == 0,
		"disabled controls prevent movement, jumps and scoring inputs")
	game.skater.set_controls_enabled(true)


func _test_spin_scoring() -> void:
	game.restart_run()
	await _physics_frames(30)
	observed_tricks.clear()
	game.skater.trick_performed.connect(_record_trick)
	Input.action_press("ollie")
	await _physics_frames(3)
	Input.action_release("ollie")
	await _physics_frames(1)
	Input.action_press("spin_right")
	await _physics_frames(26)
	Input.action_release("spin_right")
	await _physics_frames(55)
	_check(observed_tricks.count("Backside 180") == 1,
		"sustained aerial spin registers one completed 180 on landing")
	_check(game.score.total_score == 300,
		"spin bonus raises the ollie base without creating a separate multiplier")
	game.restart_run()
	await _physics_frames(30)
	observed_tricks.clear()
	Input.action_press("ollie")
	await _physics_frames(3)
	Input.action_release("ollie")
	await _physics_frames(1)
	Input.action_press("spin_left")
	await _physics_frames(14)
	Input.action_release("spin_left")
	Input.action_press("spin_right")
	await _physics_frames(14)
	Input.action_release("spin_right")
	await _physics_frames(45)
	_check(observed_tricks.size() == 1 and observed_tricks[0] == "Ollie"
		and game.score.total_score == 100,
		"opposing spins cancel net rotation instead of farming rotation awards")
	game.skater.trick_performed.disconnect(_record_trick)


func _test_bail_recovery() -> void:
	game.restart_run()
	await _physics_frames(30)
	game.score.add_trick("Prior bank", 100)
	game.score.bank_combo()
	game.score.add_trick("Pending trick", 500)
	game.skater.global_position.y = -10.0
	await _physics_frames(3)
	_check(game.skater.bail_active and game.skater.global_position.distance_to(game.skater.spawn_position) < 1.0,
		"out-of-world fall relocates to its supported safety point and begins visible native recovery")
	_check(game.score.total_score == 100 and game.score.get_combo_value() == 0,
		"bail signal drops the pending combo without erasing banked points")
	await _physics_frames(85)
	_check(not game.skater.bail_active and game.skater.global_position.distance_to(game.skater.spawn_position) < 1.0,
		"completed out-of-world recovery returns to a supported spawn after its actual animation")


func _test_run_flow() -> void:
	game.restart_run()
	await _physics_frames(3)
	var run_time: float = game.time_remaining
	await _physics_frames(6)
	_check(game.time_remaining < run_time, "run timer decreases during active play")
	game.toggle_pause()
	var pause_time: float = game.time_remaining
	var pause_position: Vector3 = game.skater.global_position
	Input.action_press("push")
	await _physics_frames(6)
	Input.action_release("push")
	_check(game.paused and is_equal_approx(game.time_remaining, pause_time),
		"pausing freezes the run timer")
	_check(game.skater.global_position.is_equal_approx(pause_position),
		"pausing freezes skater physics")
	game.toggle_pause()
	await _physics_frames(3)
	_check(not game.paused and game.time_remaining < pause_time,
		"unpausing resumes the run timer")
	game.toggle_free_skate()
	var free_time: float = game.time_remaining
	await _physics_frames(6)
	_check(game.free_skate_mode and is_equal_approx(game.time_remaining, free_time),
		"free skate disables countdown expiry")
	game.toggle_free_skate()
	game.restart_run()
	await _physics_frames(30)
	game.time_remaining = 0.01
	await _physics_frames(6)
	_check(game.run_finished and game.time_remaining <= 0.0,
		"grounded run ends when countdown reaches zero")
	var finished_position: Vector3 = game.skater.global_position
	Input.action_press("push")
	await _physics_frames(6)
	Input.action_release("push")
	_check(game.skater.global_position.distance_to(finished_position) < 0.1,
		"finished run gates player movement")
	game.restart_run()
	_check(not game.run_finished and not game.paused and game.time_remaining > 119.0
		and game.score.total_score == 0 and game.score.get_combo_value() == 0,
		"restart restores a fresh 120-second run and clears score")
	_check(game.skater.global_position.is_equal_approx(game.skater.spawn_position),
		"restart restores the world spawn position")


func _test_overtime() -> void:
	game.restart_run()
	await _physics_frames(30)
	Input.action_press("ollie")
	await _physics_frames(3)
	Input.action_release("ollie")
	await _physics_frames(1)
	game.time_remaining = 0.01
	await _physics_frames(6)
	_check(game.time_remaining <= 0.0 and not game.run_finished
		and game.score.get_combo_value() > 0,
		"timer expiry gives an active aerial combo time to land")
	await _physics_frames(65)
	_check(game.run_finished and game.score.total_score > 0
		and game.score.get_combo_value() == 0,
		"overtime clean landing banks its combo before finishing the run")
	game.restart_run()
	await _physics_frames(30)
	game.score.add_trick("Stalled aerial combo", 100)
	game.skater.airborne = true
	game.skater.set_physics_process(false)
	game.time_remaining = 0.01
	await _physics_frames(200)
	_check(game.run_finished and game.score.get_combo_value() == 0
		and game.score.total_score == 0,
		"overtime cannot preserve an unlanded combo indefinitely")
	game.restart_run()


func _test_input_events() -> void:
	await _physics_frames(30)
	_send_key(KEY_ESCAPE)
	await _physics_frames(2)
	_check(game.paused, "injected Escape key event reaches pause flow")
	_send_key(KEY_ESCAPE)
	await _physics_frames(2)
	_check(not game.paused, "injected Escape key event resumes paused play")
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_START
	button.pressed = true
	Input.parse_input_event(button)
	button = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_START
	button.pressed = false
	Input.parse_input_event(button)
	await _physics_frames(2)
	_check(game.paused, "injected standard gamepad Options event reaches pause flow")
	game.score.add_trick("Restart test", 100)
	_send_key(KEY_R)
	await _physics_frames(2)
	_check(not game.paused and not game.run_finished and game.score.get_combo_value() == 0
		and game.time_remaining > 119.0,
		"injected R key restarts directly from a paused run")


func _send_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)


func _physics_frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame


func _release_actions() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)


func _count_nodes(node: Node, type_name: String) -> int:
	var total: int = 1 if node.is_class(type_name) else 0
	for child in node.get_children():
		total += _count_nodes(child, type_name)
	return total


func _record_trick(trick_name: String, _points: int) -> void:
	observed_tricks.append(trick_name)


func _record_landing(clean: bool) -> void:
	observed_landings.append(clean)
