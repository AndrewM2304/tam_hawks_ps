extends Node3D

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
const SkateAudioSource = preload("res://game/audio/skate_audio.gd")
const GlasgowEncountersSource = preload("res://game/characters/glasgow_encounters.gd")
const CatEncounterSource = preload("res://game/characters/cat_encounter.gd")
const RUN_SECONDS := 120.0

var score := ScoreSession.new()
var career = CareerProgressSource.new()
var gaps = GapTrackerSource.new()
var special_meter = SpecialMeterSource.new()
var objectives: Node3D
var encounters: Node3D
var cat_encounter: Node3D
var _focused_encounter := "busker_big_finish"
var audio: Node
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	audio = SkateAudioSource.new()
	add_child(audio)
	if audio.has_signal("caption"):
		audio.connect("caption", _on_caption)
	skater = Skater.new()
	skater.name = "Skater"
	skater.process_mode = Node.PROCESS_MODE_PAUSABLE
	skater.spawn_position = world.get_spawn_position()
	add_child(skater)
	skater.reset_skater()
	skater.set_grind_lines(world.get_grind_lines())
	skater.trick_performed.connect(_on_trick)
	skater.grind_captured.connect(_on_grind_captured)
	skater.landed.connect(_on_landed)
	skater.bailed.connect(_on_bailed)
	skater.combo_link_started.connect(score.continue_combo)
	skater.combo_link_ended.connect(score.begin_landing)
	hud = Hud.new()
	hud.name = "HUD"
	add_child(hud)
	hud.set_map_data(world.get_district_checkpoints(), world.get_route_definitions())
	hud.restart_requested.connect(restart_run)
	hud.pause_requested.connect(toggle_pause)
	hud.free_skate_requested.connect(toggle_free_skate)
	if hud.has_signal("settings_changed"):
		hud.connect("settings_changed", apply_settings)
	if hud.has_signal("start_requested"):
		hud.connect("start_requested", start_mode)
	if hud.has_signal("ui_feedback"):
		hud.connect("ui_feedback", func(): audio.play_event("ui"))
	if hud.has_signal("cosmetic_selected"):
		hud.connect("cosmetic_selected", select_cosmetic)
	apply_settings(career.settings, false)
	_refresh_hud()
	if not OS.get_cmdline_args().has("--script") and hud.has_method("show_title"):
		paused = true
		get_tree().paused = true
		audio.set_paused(true)
		hud.show_title()

func _unhandled_input(event: InputEvent) -> void:
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
	_refresh_hud()

func _physics_process(delta: float) -> void:
	if paused or run_finished:
		return
	_feedback_timer = maxf(0.0, _feedback_timer - delta)
	_caption_time = maxf(0.0, _caption_time - delta)
	if world.has_method("get_recovery_position"):
		var recovery: Vector3 = world.get_recovery_position(skater.global_position)
		if recovery.is_finite():
			skater.recover_to(recovery)
			_feedback = "BACK ON THE QUAY. FIND YOUR NEXT LINE."
			_feedback_timer = 3.0
	var district: String = world.get_district_id(skater.global_position)
	_update_contact_audio()
	audio.set_motion(skater.speed, skater.is_on_floor(), skater.grinding, district)
	if free_skate_mode or time_remaining > 0.0:
		var objective_has_prompt: bool = not objectives.nearby_prompt(skater.global_position).is_empty()
		_update_objectives(delta, district)
		_update_encounters(delta, Input.is_action_just_pressed("interact") and not objective_has_prompt)
	if skater.airborne or skater.grinding or skater.manual_active:
		score.continue_combo()
	var banked: int = score.tick(delta)
	if banked > 0:
		_on_combo_banked(banked)
	if not free_skate_mode:
		var had_career_time := time_remaining > 0.0
		time_remaining = maxf(0.0, time_remaining - delta)
		if had_career_time and time_remaining <= 0.0:
			encounters.finish_run()
			cat_encounter.finish_run()
		if time_remaining <= 0.0:
			var resolving: bool = score.get_combo_value() > 0 and (skater.airborne
				or skater.grinding or skater.manual_active or score.pending_landing)
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

func toggle_free_skate() -> void:
	free_skate_mode = not free_skate_mode
	restart_run()

func _on_trick(trick_name: String, points: int) -> void:
	if run_finished:
		return
	score.add_trick(trick_name, points)
	encounters.on_trick(trick_name, points, skater.global_position)
	if trick_name == "Ollie": audio.play_event("ollie")
	elif trick_name == "Rail Grind": audio.play_event("grind")
	if "flip" in trick_name.to_lower():
		_flips += 1
	if "grab" in trick_name.to_lower() or "indy" in trick_name.to_lower():
		_grabs += 1

func _on_grind_captured(rail_id: String) -> void:
	if paused or run_finished or (not free_skate_mode and time_remaining <= 0.0):
		return
	cat_encounter.on_grind_capture(rail_id, skater.global_position)


func _on_landed(clean: bool) -> void:
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
	special_meter.earn_bank(banked)
	_notify_goals(career.record_score(score.total_score, score.best_combo))
	_save_profile()
	audio.play_event("bank")
	encounters.on_bank(banked, skater.global_position)
	cat_encounter.on_bank(banked, skater.global_position)
	if banked >= 1000 and _near_npc() and audio.has_method("play_bark"):
		audio.play_bark("landing")

func _on_bailed() -> void:
	score.drop_combo()
	gaps.reset()
	audio.play_event("bail")
	_feedback = "BACK ON THE BOARD."
	_feedback_timer = 2.0
	encounters.on_bail()
	cat_encounter.on_bail()

func _finish_run() -> void:
	if run_finished:
		return
	run_finished = true
	encounters.finish_run()
	cat_encounter.finish_run()
	_notify_goals(career.finish_run(score.total_score, score.best_combo))
	_save_profile()
	audio.set_motion(0, false, false, "")
	if _near_npc(): audio.play_bark("again")
	score.drop_combo()
	skater.set_controls_enabled(false)
	skater.set_physics_process(false)

func _try_special(trick_id: String) -> void:
	if paused or run_finished or (not free_skate_mode and time_remaining <= 0.0):
		return
	if not free_skate_mode and not career.unlocks().has(trick_id):
		_feedback = "COMPLETE CAREER GOALS TO UNLOCK THIS SPECIAL"
		_feedback_timer = 2.0
		return
	if special_meter.value < 100.0:
		_feedback = "BANK COMBOS TO FILL YOUR SPECIAL METER"
		_feedback_timer = 2.0
		return
	if skater.try_special(trick_id):
		special_meter.consume()

func _update_objectives(delta: float, district: String) -> void:
	var completed: Array = []
	if district != _last_district and not district.is_empty():
		_last_district = district
		completed.append_array(career.record_event("district", district))
		_feedback = "WELCOME TO " + world.get_location_name(skater.global_position)
		_feedback_timer = 2.0
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
		score.add_trick(gap.name, gap.points)
		completed.append_array(career.record_event("gap", gap.id))
		if not skater.airborne and not skater.grinding and not skater.manual_active:
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
	audio.set_mix(career.settings.audio * career.settings.sfx_volume, career.settings.audio * career.settings.ambience_volume)
	encounters.set_mix(career.settings.audio, career.settings.ambience_volume)
	cat_encounter.set_mix(career.settings.audio, career.settings.ambience_volume)
	skater.set_presentation_settings(career.settings.camera_sensitivity, career.settings.reduced_motion)
	objectives.reduced_motion = career.settings.reduced_motion
	encounters.reduced_motion = career.settings.reduced_motion
	cat_encounter.reduced_motion = career.settings.reduced_motion
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


## Objectives retain their existing interaction priority. Side offers select the
## nearest eligible performer and accepting one ends the other active attempt.
func _nearby_encounter_id() -> String:
	var at := skater.global_position
	var mo_offer: String = encounters.nearby_prompt(at)
	var cat_offer: String = cat_encounter.nearby_prompt(at)
	if cat_offer.is_empty():
		return "busker_big_finish" if not mo_offer.is_empty() else ""
	if mo_offer.is_empty():
		return "cat_got_the_beat"
	var mo_position: Vector3 = encounters.status_snapshot().position
	var cat_position: Vector3 = cat_encounter.status_snapshot().position
	return "cat_got_the_beat" if at.distance_squared_to(cat_position) < at.distance_squared_to(mo_position) else "busker_big_finish"


func _update_encounters(delta: float, interact: bool) -> void:
	var chosen := _nearby_encounter_id() if interact else ""
	var combo_value: int = score.get_combo_value()
	if combo_value == 0:
		if chosen == "cat_got_the_beat":
			encounters.cancel_attempt()
			_focused_encounter = chosen
		elif chosen == "busker_big_finish":
			cat_encounter.cancel_attempt()
			_focused_encounter = chosen
	encounters.poll(skater.global_position, chosen == "busker_big_finish", delta, combo_value)
	var camera: Camera3D = get_viewport().get_camera_3d()
	var stage_position: Vector3 = cat_encounter.status_snapshot().position
	var audience_visible := is_instance_valid(camera) and stage_position.is_finite() \
		and camera.is_position_in_frustum(stage_position + Vector3(0, 0.8, 0))
	cat_encounter.poll(skater.global_position, chosen == "cat_got_the_beat", delta, combo_value, audience_visible)


func _challenge_text() -> String:
	var cat_status: Dictionary = cat_encounter.status_snapshot()
	var mo_status: Dictionary = encounters.status_snapshot()
	if cat_status.state == "active":
		return str(cat_status.get("hud_text", ""))
	if mo_status.state == "active":
		return str(mo_status.get("hud_text", ""))
	return str((cat_status if _focused_encounter == "cat_got_the_beat" else mo_status).get("hud_text", ""))


func _interaction_prompt() -> String:
	var prompt: String = objectives.nearby_prompt(skater.global_position)
	if not prompt.is_empty():
		return prompt
	match _nearby_encounter_id():
		"cat_got_the_beat": return cat_encounter.nearby_prompt(skater.global_position)
		"busker_big_finish": return encounters.nearby_prompt(skater.global_position)
	return ""


func _on_caption(text: String) -> void:
	_caption = text
	_caption_time = 3.0

func _refresh_hud() -> void:
	if not is_instance_valid(hud):
		return
	hud.update_display({
		"time": time_remaining, "score": score.total_score,
		"combo": score.get_combo_value(), "multiplier": score.combo_multiplier,
		"combo_base": score.combo_base,
		"tricks": "  +  ".join(score.trick_history), "best": score.best_combo,
		"speed": skater.speed, "airborne": skater.airborne,
		"grinding": skater.grinding, "balance": skater.grind_balance,
		"manual": skater.manual_active, "manual_balance": skater.manual_balance,
		"landing_window": score.landing_remaining, "revert_window": skater.revert_remaining,
		"location": world.get_location_name(skater.global_position),
		"player_position": skater.global_position, "player_heading": skater.rotation.y,
		"paused": paused, "finished": run_finished, "free_skate": free_skate_mode,
		"feedback": _feedback if _feedback_timer > 0 else "",
		"challenge_text": _challenge_text(),
		"landings": _landings, "flips": _flips, "grabs": _grabs,
		"goals": career.goals_snapshot(), "unlocks": career.unlocks(),
		"record_score": career.best_score, "record_combo": career.best_combo,
		"special_meter": special_meter.value, "settings": career.settings,
		"caption": _caption if _caption_time > 0 and career.settings.captions else "",
		"save_status": save_status, "save_warning": save_warning,
		"interaction_prompt": _interaction_prompt(),
	})
