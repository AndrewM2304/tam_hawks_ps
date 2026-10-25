extends Node3D

const GraphicsQuality = preload("res://game/core/graphics_quality.gd")
const InputSetup = preload("res://game/core/input_setup.gd")
const InputProfile = preload("res://game/core/input_profile.gd")
const ScoreSession = preload("res://game/scoring/score_session.gd")
const Skater = preload("res://game/player/skater.gd")
const GlasgowSquare = preload("res://game/levels/glasgow_square.gd")
const Hud = preload("res://game/ui/hud.gd")
const CareerProgressSource = preload("res://game/progression/career_progress.gd")
const ObjectiveTrackerSource = preload("res://game/progression/objective_tracker.gd")
const GapTrackerSource = preload("res://game/tricks/gap_tracker.gd")
const SpecialMeterSource = preload("res://game/tricks/special_meter.gd")
const TrickCatalog = preload("res://game/tricks/trick_catalog.gd")
const SkateAudioSource = preload("res://game/audio/skate_audio.gd")
const AppleMusicSource = preload("res://game/audio/apple_music.gd")
const GlasgowEncountersSource = preload("res://game/characters/glasgow_encounters.gd")
const CatEncounterSource = preload("res://game/characters/cat_encounter.gd")
const MarketEncounterSource = preload("res://game/characters/market_encounter.gd")
const FeatureHubSource = preload("res://game/features/feature_hub.gd")
const PlaytestRecorder = preload("res://game/core/playtest_recorder.gd")
const RUN_SECONDS := 120.0

var playtest_recorder: CanvasLayer
var score := ScoreSession.new()
var career = CareerProgressSource.new()
var gaps = GapTrackerSource.new()
var special_meter = SpecialMeterSource.new()
var _special_axis_held: Dictionary = {}
var objectives: Node3D
var encounters: Node3D
var cat_encounter: Node3D
var market_encounter: Node3D
var feature_hub: Node3D
var _focused_encounter := "busker_big_finish"
var audio: Node
var music: Node
# Developer/script runners never write the player's profile by default.
var persistence_enabled: bool = not OS.get_cmdline_args().has("--script")
var profile_path := "user://career.json"
var save_status := ""
var save_warning := ""
var _caption := ""
var _caption_time := 0.0
var _last_district := ""
var world: Node3D
var skater: CharacterBody3D
var hud: CanvasLayer
var time_remaining: float = RUN_SECONDS
var run_finished: bool = false
var paused: bool = false
var free_skate_mode: bool = false
var _overtime: float = 0.0
var _feedback: String = "YOUR SQUARE. YOUR LINE."
var _feedback_timer: float = 4.0
var _landings: int = 0
var _flips: int = 0
var _grabs: int = 0
var _hud_career_source: RefCounted
var _hud_career_revision := -1
var _hud_goals: Array[Dictionary] = []
var _hud_unlocks: Array[String] = []
var _hud_music_source: Node
var _hud_music_state: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Only physics-driven actors opt in; render-step NPC/UI motion stays direct.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	InputSetup.register_actions()
	Input.joy_connection_changed.connect(_on_controller_connection)
	if persistence_enabled:
		var loaded: Error = career.load_profile(profile_path)
		if loaded != OK and loaded != ERR_FILE_NOT_FOUND:
			save_warning = "Saved progress could not be loaded. Existing files are safe; this session will not be saved."
			save_status = save_warning
	career.begin_run(free_skate_mode)
	world = GlasgowSquare.new()
	world.name = "GlasgowSquare"
	# An explicit source-launch candidate lets the owner inspect pending design
	# work on target hardware without changing its ordinary-play admission.
	if OS.get_cmdline_user_args().has("--pt24-design-preview"):
		set_meta("pt24_design_preview",true)
	# Read-only visual A/B diagnostics set these before construction; no profile/UI switch.
	for flag: StringName in [&"facade_bay_enabled", &"facade_bay_audit", &"pt24_design_preview", &"pt24_render_repairs_baseline"]:
		if has_meta(flag): world.set_meta(flag, get_meta(flag))
	add_child(world)
	objectives = ObjectiveTrackerSource.new()
	objectives.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(objectives)
	objectives.configure(world.get_goal_markers())
	gaps.configure(world.get_gap_definitions())
	encounters = GlasgowEncountersSource.new()
	encounters.name = "GlasgowEncounters"
	encounters.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(encounters)
	encounters.configure(world.get_encounter_definitions())
	encounters.feedback.connect(_on_encounter_feedback)
	cat_encounter = CatEncounterSource.new()
	cat_encounter.name = "CatEncounter"
	cat_encounter.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cat_encounter)
	cat_encounter.configure(world.get_encounter_definitions())
	cat_encounter.feedback.connect(_on_encounter_feedback)
	market_encounter = MarketEncounterSource.new()
	market_encounter.name = "MarketEncounter"
	market_encounter.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(market_encounter)
	market_encounter.configure(world.get_encounter_definitions())
	market_encounter.feedback.connect(_on_encounter_feedback)
	audio = SkateAudioSource.new()
	add_child(audio)
	music = AppleMusicSource.new()
	music.name = "AppleMusic"
	music.configure(persistence_enabled)
	add_child(music)
	music.changed.connect(_on_music_changed)
	if audio.has_signal("caption"):
		audio.connect("caption", _on_caption)
	skater = Skater.new()
	skater.name = "Skater"
	skater.process_mode = Node.PROCESS_MODE_PAUSABLE
	skater.spawn_position = world.get_spawn_position()
	add_child(skater)
	skater.reset_skater()
	skater.set_grind_lines(world.get_grind_lines())
	skater.set_transition_features(world.get_transition_features())
	market_encounter.set_carrier(skater.get_node("SkaterVisual/Rider"))
	skater.trick_performed.connect(_on_trick)
	skater.trick_upgraded.connect(_on_trick_upgraded)
	skater.special_requested.connect(_try_special)
	skater.hold_points_awarded.connect(_on_hold_points)
	skater.grind_captured.connect(_on_grind_captured)
	skater.landed.connect(_on_landed)
	skater.bailed.connect(_on_bailed)
	skater.recovered.connect(_on_recovered)
	skater.combo_link_started.connect(score.continue_combo)
	skater.combo_link_ended.connect(score.begin_landing)
	feature_hub = FeatureHubSource.new()
	feature_hub.name = "GlasgowActivities"
	feature_hub.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(feature_hub)
	feature_hub.configure(world, skater)
	feature_hub.feedback.connect(_on_encounter_feedback)
	feature_hub.routes_changed.connect(_refresh_map_routes)
	hud = Hud.new()
	hud.name = "HUD"
	add_child(hud)
	hud.set_map_data(world.get_district_checkpoints(), world.get_route_definitions() + feature_hub.get_route_definitions())
	hud.restart_requested.connect(restart_run)
	hud.pause_requested.connect(toggle_pause)
	hud.free_skate_requested.connect(toggle_free_skate)
	hud.music_requested.connect(_on_music_requested)
	if hud.has_signal("settings_changed"):
		hud.connect("settings_changed", apply_settings)
	if hud.has_signal("start_requested"):
		hud.connect("start_requested", start_mode)
	if hud.has_signal("ui_feedback"):
		hud.connect("ui_feedback", func(): audio.play_event("ui"))
	if hud.has_signal("cosmetic_selected"):
		hud.connect("cosmetic_selected", select_cosmetic)
	apply_settings(career.settings, false)
	playtest_recorder=PlaytestRecorder.new()
	playtest_recorder.name="PlaytestRecorder"
	add_child(playtest_recorder)
	playtest_recorder.configure(self)
	hud.debug_requested.connect(playtest_recorder.show_menu)
	_refresh_hud()
	if not OS.get_cmdline_args().has("--script") and hud.has_method("show_title"):
		paused = true
		get_tree().paused = true
		audio.set_paused(true)
		hud.show_title()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(playtest_recorder) and (playtest_recorder.editing or playtest_recorder.busy):return
	# Stick motion produces repeated events while held. Specials are discrete:
	# attempt once per excursion, then require a return through the deadzone.
	if event is InputEventJoypadMotion:
		var matched := false
		for action: String in ["special_one", "special_two"]:
			if not event.is_action(action): continue
			matched = true
			var held := event.is_action_pressed(action)
			if held and not bool(_special_axis_held.get(action, false)):
				_try_special("special_clyde_carousel" if action == "special_one" else "special_tenement_tumble")
			_special_axis_held[action] = held
		if matched: return
	if event.is_action_pressed("restart"):
		restart_run()
	elif event.is_action_pressed("pause"):
		toggle_pause()
	elif event.is_action_pressed("free_skate"):
		toggle_free_skate()
	elif event.is_action_pressed("special_one"):
		_try_special("special_clyde_carousel")
	elif event.is_action_pressed("special_two"):
		_try_special("special_tenement_tumble")
	elif event.is_action_pressed("goals") and hud.has_method("toggle_goals"):
		hud.toggle_goals()

func _process(_delta: float) -> void:
	if is_instance_valid(playtest_recorder) and (playtest_recorder.editing or playtest_recorder.busy):return
	_refresh_hud()

func _physics_process(delta: float) -> void:
	if paused or run_finished:
		return
	_feedback_timer = maxf(0.0, _feedback_timer - delta)
	_caption_time = maxf(0.0, _caption_time - delta)
	if world.has_method("get_recovery_position"):
		var recovery: Vector3 = world.get_recovery_position(skater.global_position)
		if recovery.is_finite() and not skater.bail_active:
			_feedback = world.get_recovery_message(skater.global_position)
			skater.recover_to(recovery)
			_feedback_timer = 3.0
	if skater.bailing and skater.bail_phase == "blocked":
		_feedback = "CAN'T GET UP HERE. OPEN PAUSE TO RESTART."
		_feedback_timer = 1.0
	var district: String = world.get_district_id(skater.global_position)
	_update_contact_audio()
	var rolling_contact: bool = not skater.bailing and not skater.airborne \
		and (skater.is_on_floor() or skater.transition_active)
	audio.set_motion(skater.speed, rolling_contact, skater.grinding, district)
	if free_skate_mode or time_remaining > 0.0:
		var objective_has_prompt: bool = not objectives.nearby_prompt(skater.global_position).is_empty()
		if not skater.bail_active: _update_objectives(delta, district)
		_update_encounters(delta, Input.is_action_just_pressed("interact") and not objective_has_prompt and not skater.bail_active and not skater.setup_active)
	if _combo_link_active():
		score.continue_combo()
	var banked: int = score.tick(delta)
	if banked > 0:
		_on_combo_banked(banked)
	special_meter.tick(delta, score.get_combo_value() > 0
		and (_combo_link_active() or score.pending_landing))
	if not free_skate_mode:
		var had_career_time := time_remaining > 0.0
		time_remaining = maxf(0.0, time_remaining - delta)
		if had_career_time and time_remaining <= 0.0:
			encounters.finish_run()
			cat_encounter.finish_run()
			market_encounter.finish_run()
			feature_hub.finish_run()
		if time_remaining <= 0.0:
			var resolving: bool = score.get_combo_value() > 0 \
				and (_combo_link_active() or score.pending_landing)
			if resolving and _overtime < 3.0:
				_overtime += delta
			else:
				_finish_run()
	skater.set_trick_entries_enabled(free_skate_mode or time_remaining > 0.0)

func restart_run() -> void:
	paused = false
	get_tree().paused = false
	run_finished = false
	time_remaining = RUN_SECONDS
	_overtime = 0.0
	score.reset()
	special_meter.reset()
	gaps.reset()
	career.begin_run(free_skate_mode)
	objectives.reset_run()
	encounters.reset_run()
	cat_encounter.reset_run()
	market_encounter.reset_run()
	if is_instance_valid(feature_hub): feature_hub.reset_run()
	_focused_encounter = "busker_big_finish"
	if world.has_method("reset_interactions"): world.reset_interactions()
	audio.set_paused(false)
	audio.set_surface("stone")
	_last_district = ""
	_caption_time = 0.0
	_landings = 0
	_flips = 0
	_grabs = 0
	_feedback = "FRESH RUN. GIE IT LALDY."
	_feedback_timer = 3.0
	skater.reset_skater()
	skater.set_trick_entries_enabled(true)
	skater.set_controls_enabled(true)
	skater.set_physics_process(true)
	_refresh_hud()

func toggle_pause() -> void:
	if run_finished:
		return
	paused = not paused
	get_tree().paused = paused
	audio.set_paused(paused)
	audio.play_event("ui")
	_refresh_hud()

func start_mode(free: bool) -> void:
	free_skate_mode = free
	restart_run()
	music.begin_session()

func toggle_free_skate() -> void:
	free_skate_mode = not free_skate_mode
	restart_run()
	music.begin_session()


func _on_music_requested(action: String, value: String) -> void:
	music.request(action, value)
	_refresh_hud()

func _on_trick(trick_name: String, points: int) -> void:
	if paused or run_finished:
		return
	var definition := _trick_definition(trick_name)
	var identity: String = str(definition.get("id", ""))
	var awarded := 0
	if not definition.is_empty():
		if str(definition.get("family", "")) == "spin":
			awarded = score.add_spin_bonus(points, trick_name)
		else:
			awarded = score.add_trick(trick_name, points, TrickCatalog.repetition_id(identity))
	# Styling belongs to score receipts; encounter family lookup uses the catalog.
	# Legacy zero-point notifications still reach their classifiers unchanged;
	# an unknown display name never becomes an admitted score/audio event.
	var canonical_name: String = str(definition.get("display_name", trick_name))
	encounters.on_trick(canonical_name, awarded, skater.global_position)
	market_encounter.on_trick(canonical_name, awarded, skater.global_position)
	if awarded <= 0: return
	special_meter.earn_trick(awarded)
	if is_instance_valid(feature_hub):
		feature_hub.on_trick(canonical_name, awarded, skater.global_position, identity)
	var family: String = str(definition.get("family", ""))
	if family == "launch": audio.play_event("ollie")
	elif family == "grind": audio.play_event("grind")
	if family == "flip":
		_flips += 1
	if family == "grab":
		_grabs += 1


## Retained native paths also emit their real display names. Resolve those names
## before trusting an ID left by an earlier trick; stance styling is presentation.
func _trick_definition(trick_name: String) -> Dictionary:
	var name := trick_name
	if name != name.strip_edges(): return {}
	for prefix: String in ["Switch ", "Fakie ", "Nollie "]:
		if name.begins_with(prefix):
			name = name.trim_prefix(prefix)
			break
	var hinted_id: Variant = skater.get("last_trick_id") if is_instance_valid(skater) else null
	var definition: Dictionary = TrickCatalog.definition(hinted_id) if hinted_id is String else {}
	if not definition.is_empty() and str(definition.get("display_name", "")) == name:
		return definition
	for prefix: String in ["FS ", "BS ", "Frontside ", "Backside "]:
		if name.begins_with(prefix):
			var degrees := name.trim_prefix(prefix)
			if degrees.is_valid_int() and int(degrees) > 0 and int(degrees) % 180 == 0:
				return TrickCatalog.definition("spin_180")
	for identity: String in TrickCatalog.ids() + TrickCatalog.compatibility_ids():
		definition = TrickCatalog.definition(identity)
		if str(definition.get("display_name", "")) == name:
			return definition
	return {}


func _on_hold_points(points: int) -> void:
	if not paused and not run_finished:
		special_meter.earn_trick(score.add_hold_points(points))


func _on_trick_upgraded(trick_name: String, points: int, identity: String) -> void:
	if paused or run_finished:
		return
	# The original flip already counts once for encounters and run statistics.
	# A stale upgrade may reduce score; only positive new points earn live charge.
	special_meter.earn_trick(score.upgrade_last_trick(trick_name, points, TrickCatalog.repetition_id(identity)))


## Carving a supported transition is ordinary ground travel. Only physical air,
## balance links, wallrides and lip support keep an existing combo alive.
func _combo_link_active() -> bool:
	return not skater.bail_active and (skater.airborne or skater.grinding or skater.manual_active \
		or skater.wallriding or skater.lip_active or skater.skitch_caught or skater.setup_active)

func _on_grind_captured(rail_id: String) -> void:
	if paused or run_finished or (not free_skate_mode and time_remaining <= 0.0):
		return
	cat_encounter.on_grind_capture(rail_id, skater.global_position)


func _on_landed(clean: bool) -> void:
	feature_hub.on_landed(clean)
	if run_finished:
		return
	if clean:
		score.begin_landing()
		audio.play_event("landing")
	else:
		_on_bailed()

func _on_combo_banked(banked: int) -> void:
	_landings += 1
	_feedback = "LANDED  +%s" % banked
	_feedback_timer = 2.0
	_notify_goals(career.record_score(score.total_score, score.best_combo))
	_save_profile()
	audio.play_event("bank")
	encounters.on_bank(banked, skater.global_position)
	cat_encounter.on_bank(banked, skater.global_position)
	market_encounter.on_bank(banked, skater.global_position)
	feature_hub.on_bank(banked, skater.global_position)
	if banked >= 1000 and _near_npc() and audio.has_method("play_bark"):
		audio.play_bark("landing")

func _on_bailed() -> void:
	score.drop_combo()
	special_meter.on_bail()
	if is_instance_valid(feature_hub): feature_hub.on_bail()
	gaps.reset()
	audio.play_event("bail")
	_feedback = "BAILED  /  %s LOST" % score.last_dropped_value if score.last_dropped_value > 0 else "BACK ON THE BOARD."
	_feedback_timer = 2.0
	encounters.on_bail()
	cat_encounter.on_bail()
	market_encounter.on_bail()

func _on_recovered() -> void:
	_feedback = "BACK ON THE BOARD."
	_feedback_timer = 1.5


func _finish_run() -> void:
	if run_finished:
		return
	run_finished = true
	encounters.finish_run()
	cat_encounter.finish_run()
	market_encounter.finish_run()
	if is_instance_valid(feature_hub): feature_hub.finish_run()
	_notify_goals(career.finish_run(score.total_score, score.best_combo))
	_save_profile()
	audio.set_motion(0, false, false, "")
	if _near_npc(): audio.play_bark("again")
	if score.get_combo_value() > 0:
		score.drop_combo()
	skater.set_controls_enabled(false)
	skater.set_physics_process(skater.bail_active)

func _try_special(trick_id: String) -> void:
	if paused or run_finished or (not free_skate_mode and time_remaining <= 0.0):
		return
	var definition := Skater.TrickCatalog.definition(trick_id)
	if definition.get("family", "") != "special": return
	var required: String = str(definition.get("required_unlock", trick_id))
	if not free_skate_mode and not career.unlocks().has(required):
		_feedback = "COMPLETE CAREER GOALS TO UNLOCK THIS SPECIAL"
		_feedback_timer = 2.0
		return
	if not special_meter.ready():
		_feedback = "BUILD A COMBO TO FILL YOUR SPECIAL METER"
		_feedback_timer = 2.0
		return
	if skater.try_special(trick_id):
		special_meter.consume()

func _update_objectives(delta: float, district: String) -> void:
	var completed: Array = []
	if district != _last_district and not district.is_empty():
		_last_district = district
		completed.append_array(career.record_event("district", district))
		# Landmarks announce the district. Record career visits quietly; location
		# context remains available in the map/pause menu without live name banners.
	for event: Dictionary in objectives.poll(skater.global_position, Input.is_action_just_pressed("interact")):
		completed.append_array(career.record_event(event.kind, event.id))
		_feedback = _pickup_message(event)
		_feedback_timer = 2.0
		audio.play_event("ui")
		if event.kind == "interaction" and event.id == "cone" and world.has_method("activate_cone"):
			world.activate_cone()
		if event.kind == "interaction" and audio.has_method("play_bark"):
			audio.play_bark("cone")
		_save_profile()
	for gap: Dictionary in gaps.update(skater.global_position, skater.airborne, delta):
		special_meter.earn_trick(score.add_trick(gap.name, gap.points, "gap:" + str(gap.id)))
		market_encounter.on_gap(gap.id, skater.global_position)
		completed.append_array(career.record_event("gap", gap.id))
		if not _combo_link_active():
			score.begin_landing()
		_feedback = "GAP  /  " + str(gap.name).to_upper()
		_feedback_timer = 2.0
		_save_profile()

	_notify_goals(completed)
	if not completed.is_empty(): _save_profile()

func _notify_goals(ids: Array) -> void:
	if ids.is_empty():
		return
	var titles: Array[String] = []
	for goal: Dictionary in career.goals_snapshot():
		if ids.has(goal.id): titles.append(goal.title)
	if titles.is_empty():
		return
	_feedback = "GOAL COMPLETE  /  " + titles.front().to_upper()
	if titles.size() > 1:
		_feedback += "  +%d MORE" % (titles.size() - 1)
	_feedback_timer = 3.0

func _pickup_message(event: Dictionary) -> String:
	match str(event.kind):
		"letter":
			return "LETTER %s  /  %d OF 5" % [event.id, objectives.collected_count("letter")]
		"market_item":
			return "MARKET PICKUP  /  %d OF 3" % objectives.collected_count("market_item")
		"collectible":
			return "SECRET RECORDING FOUND"
		"interaction":
			return "CONE DUTY COMPLETE"
	return "FOUND SOMETHING NEW"

func _update_contact_audio() -> void:
	if not skater.is_on_floor() or skater.grinding:
		return
	for index in skater.get_slide_collision_count():
		var collision := skater.get_slide_collision(index)
		if collision.get_normal().dot(Vector3.UP) < 0.55:
			continue
		var body := collision.get_collider()
		if body is Node:
			audio.set_surface(str(body.get_meta("surface_audio", "stone")))
			return

func _save_profile() -> void:
	if not persistence_enabled:
		return
	var result: Error = career.save_profile(profile_path)
	save_warning = "" if result == OK else "Progress could not be saved. You can keep playing; existing saves are protected."
	save_status = "Progress saved" if result == OK else save_warning

func apply_settings(settings: Dictionary, persist: bool = true) -> void:
	# Validate/clamp user-facing settings even before the persistence validator runs.
	if settings.has("bindings"):
		if InputProfile.apply_saved(settings.bindings):
			career.settings["bindings"] = settings.bindings.duplicate(true)
		else:
			_feedback = "CONTROL CHANGE REJECTED — CHECK FOR DUPLICATE BINDINGS"
			_feedback_timer = 3.0
	for key in ["audio", "sfx_volume", "ambience_volume"]:
		if settings.has(key): career.settings[key] = clampf(float(settings[key]), 0.0, 1.0)
	for key in ["captions", "reduced_motion"]:
		if settings.has(key): career.settings[key] = bool(settings[key])
	career.settings.ui_scale = clampf(float(settings.get("ui_scale", career.settings.ui_scale)), 1.0, 1.4)
	career.settings.camera_sensitivity = clampf(float(settings.get("camera_sensitivity", career.settings.camera_sensitivity)), 0.5, 2.0)
	career.settings.graphics_quality = GraphicsQuality.apply(get_viewport(), skater, world, settings.get("graphics_quality", career.settings.graphics_quality))
	audio.set_mix(career.settings.audio * career.settings.sfx_volume, career.settings.audio * career.settings.ambience_volume)
	encounters.set_mix(career.settings.audio, career.settings.ambience_volume)
	cat_encounter.set_mix(career.settings.audio, career.settings.ambience_volume)
	skater.set_presentation_settings(career.settings.camera_sensitivity, career.settings.reduced_motion)
	objectives.reduced_motion = career.settings.reduced_motion
	encounters.reduced_motion = career.settings.reduced_motion
	cat_encounter.reduced_motion = career.settings.reduced_motion
	market_encounter.reduced_motion = career.settings.reduced_motion
	if is_instance_valid(feature_hub): feature_hub.reduced_motion = career.settings.reduced_motion
	select_cosmetic(str(settings.get("cosmetic_id", career.settings.get("cosmetic_id", "color_blue"))), false)
	if persist: _save_profile()

func select_cosmetic(id: String, persist: bool = true) -> void:
	if not career.unlocks().has(id):
		return
	var colours := {"color_blue": Color("4d6270"), "color_orange": Color("a66642"), "color_purple": Color("695a76")}
	if colours.has(id):
		skater.set_skater_color(colours[id])
		career.settings["cosmetic_id"] = id
		if persist: _save_profile()

func _near_npc() -> bool:
	if not world.has_method("get_npc_positions"):
		return false
	for position: Vector3 in world.get_npc_positions():
		if position.distance_to(skater.global_position) <= 18.0:
			return true
	return false

func _on_controller_connection(_device: int, connected: bool) -> void:
	if not connected and not run_finished and not paused:
		toggle_pause()
		_feedback = "CONTROLLER DISCONNECTED — RECONNECT OR USE KEYBOARD"
		_feedback_timer = 8.0

func _on_encounter_feedback(text: String) -> void:
	_feedback = text
	_feedback_timer = 5.0
	audio.play_event("ui")


## Objectives retain interaction priority. The nearest eligible side offer wins;
## accepting it cancels other active attempts without changing ordinary scoring.
func _side_encounters() -> Array[Node3D]:
	var result: Array[Node3D] = [encounters, cat_encounter, market_encounter]
	if is_instance_valid(feature_hub): result.append_array(feature_hub.challenges())
	return result


func _refresh_map_routes() -> void:
	if is_instance_valid(hud) and is_instance_valid(feature_hub):
		hud.set_map_data(world.get_district_checkpoints(), world.get_route_definitions() + feature_hub.get_route_definitions())


func _nearby_encounter_id(statuses: Array[Dictionary] = []) -> String:
	var at := skater.global_position
	var chosen := ""
	var closest := INF
	var components := _side_encounters()
	for index in components.size():
		var component: Node3D = components[index]
		if component.nearby_prompt(at).is_empty(): continue
		var status: Dictionary = statuses[index] if statuses.size() == components.size() else component.status_snapshot()
		var offer_position: Vector3 = status.launch if str(status.id) == "cone_on_a_cruise" and status.state == "active" else status.position
		var distance := at.distance_squared_to(offer_position)
		if distance < closest:
			closest = distance
			chosen = str(status.id)
	return chosen


func _update_encounters(delta: float, interact: bool) -> void:
	var chosen := _nearby_encounter_id() if interact else ""
	var combo_value: int = score.get_combo_value()
	if combo_value == 0 and not chosen.is_empty():
		for component: Node3D in _side_encounters():
			if str(component.status_snapshot().id) != chosen:
				component.cancel_attempt()
		_focused_encounter = chosen
	encounters.poll(skater.global_position, chosen == "busker_big_finish", delta, combo_value)
	var camera: Camera3D = get_viewport().get_camera_3d()
	var stage_position: Vector3 = cat_encounter.status_snapshot().position
	var audience_visible := is_instance_valid(camera) and stage_position.is_finite() \
		and camera.is_position_in_frustum(stage_position + Vector3(0, 0.8, 0))
	cat_encounter.poll(skater.global_position, chosen == "cat_got_the_beat", delta, combo_value, audience_visible)
	var delivery_position: Vector3 = market_encounter.status_snapshot().payoff_position
	var delivery_visible := is_instance_valid(camera) and delivery_position.is_finite() \
		and camera.is_position_in_frustum(delivery_position + Vector3(0, 0.8, 0))
	market_encounter.poll(skater.global_position, chosen == "gull_proof_delivery", delta, combo_value, delivery_visible)
	var hub_choice := chosen
	if interact and hub_choice.is_empty() and not feature_hub.gate_prompt(skater.global_position).is_empty(): hub_choice = "service_gate"
	feature_hub.poll(skater.global_position, interact, delta, combo_value, false, hub_choice)


func _challenge_text(statuses: Array[Dictionary] = []) -> String:
	if statuses.is_empty(): statuses = _encounter_snapshots()
	for status: Dictionary in statuses:
		if status.state == "active":
			var text := str(status.get("hud_text", ""))
			var navigation := _market_navigation_text(status.get("navigation_targets", []))
			return text + ("\n" + navigation if not navigation.is_empty() else "")
	for status: Dictionary in statuses:
		if str(status.id) == _focused_encounter: return str(status.get("hud_text", ""))
	return ""


func _market_navigation_text(targets: Array) -> String:
	var cues: PackedStringArray = []
	for target: Dictionary in targets:
		var at: Vector3 = target.get("position", Vector3.INF)
		if not at.is_finite(): continue
		var offset := at - skater.global_position
		offset.y = 0.0
		var local := Basis(Vector3.UP, -skater.rotation.y) * offset
		var angle := rad_to_deg(atan2(local.x, -local.z))
		var direction := "AHEAD"
		if absf(angle) > 120.0: direction = "TURN BACK"
		elif angle > 30.0: direction = "RIGHT"
		elif angle < -30.0: direction = "LEFT"
		cues.append("%s: %s %dm" % [str(target.get("label", "MARKER")), direction, ceili(offset.length())])
	return "  /  ".join(cues)


func _interaction_prompt(statuses: Array[Dictionary] = []) -> String:
	var prompt: String = objectives.nearby_prompt(skater.global_position)
	if not prompt.is_empty(): return prompt
	if statuses.is_empty(): statuses = _encounter_snapshots()
	var chosen := _nearby_encounter_id(statuses)
	var components := _side_encounters()
	for index in components.size():
		var component: Node3D = components[index]
		if str(statuses[index].id) == chosen:
			return component.nearby_prompt(skater.global_position)
	return feature_hub.gate_prompt(skater.global_position) if is_instance_valid(feature_hub) else ""


func _encounter_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for component: Node3D in _side_encounters():
		snapshots.append(component.status_snapshot())
	return snapshots


func _on_caption(text: String) -> void:
	_caption = text
	_caption_time = 3.0


func _on_music_changed() -> void:
	_hud_music_source = null
	_refresh_hud()

func _refresh_hud() -> void:
	if not is_instance_valid(hud):
		return
	# Playlist data changes on Music events, not on each rendered frame. Keep
	# the current-main HUD allocation policy while retaining the copy boundary.
	if music != _hud_music_source:
		_hud_music_source = music
		_hud_music_state = music.snapshot()
	var revision: int = career.presentation_revision()
	if career != _hud_career_source or revision != _hud_career_revision:
		_hud_career_source = career
		_hud_career_revision = revision
		_hud_goals = career.goals_snapshot()
		_hud_unlocks = career.unlocks()
	var statuses := _encounter_snapshots()
	hud.update_display({
		"time": time_remaining, "score": score.total_score,
		"combo": score.get_combo_value(), "multiplier": score.combo_multiplier,
		"combo_base": score.combo_base,
		"trick_count": score.combo_trick_count, "last_award": score.last_award,
		"last_repeat": score.last_repeat, "last_banked_tricks": score.last_banked_tricks,
		"banked_combo": score.last_banked, "stance": skater.stance,
		"last_bonus": score.last_bonus,
		"active_trick": skater.active_trick, "hold_points": skater.hold_points,
		"grind_name": Skater.TrickCatalog.definition(skater.grind_trick_id).get("display_name", ""),
		"manual_name": Skater.TrickCatalog.definition(skater.manual_trick_id).get("display_name", "Manual"),
		"tricks": "  +  ".join(score.trick_history), "best": score.best_combo,
		"speed": skater.velocity.length() if skater.transition_active else (skater.get_real_velocity().length() if skater._native_floor_valid and not skater.grinding and skater.is_on_floor() and skater.get_platform_velocity().length_squared() > 0.01 else skater.speed), "airborne": skater.airborne,
		"grinding": skater.grinding, "balance": skater.grind_balance,
		"manual": skater.manual_active, "manual_balance": skater.manual_balance,
		"wallriding": skater.wallriding, "transition_active": skater.transition_active,
		"lip": skater.lip_active, "lip_active": skater.lip_active, "lip_balance": skater.lip_balance,
		"ollie_charge": skater.ollie_charge,
		"crouching": skater.crouching, "powersliding": skater.powersliding,
		"takeoff_mode": skater.takeoff_mode, "bail_active": skater.bail_active,
		"bail_phase": skater.bail_phase, "bail_progress": skater.bail_progress, "recovery_fade": skater.recovery_fade,
		"setup_active": skater.setup_active, "setup_id": skater.setup_id, "setup_phase": skater.setup_phase,
		"lip_name": skater.lip_name, "skitching": skater.skitching, "skitch_caught": skater.skitch_caught, "skitch_balance": skater.skitch_balance,
		"landing_window": score.landing_remaining, "revert_window": skater.revert_remaining,
		"location": world.get_location_name(skater.global_position),
		"player_position": skater.global_position, "player_heading": skater.rotation.y,
		"paused": paused, "finished": run_finished, "free_skate": free_skate_mode,
		"feedback": _feedback if _feedback_timer > 0 else "",
		"challenge_text": _challenge_text(statuses),
		"landings": _landings, "flips": _flips, "grabs": _grabs,
		"goals": _hud_goals, "unlocks": _hud_unlocks,
		"record_score": career.best_score, "record_combo": career.best_combo,
		"special_meter": special_meter.value, "settings": career.settings,
		"special_ready": special_meter.ready(), "special_active": special_meter.active,
		"caption": _caption if _caption_time > 0 and career.settings.captions else "",
		"save_status": save_status, "save_warning": save_warning,
		"interaction_prompt": _interaction_prompt(statuses),
		"music": _hud_music_state,
	})
