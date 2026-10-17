extends Node3D

const InputSetup = preload("res://game/core/input_setup.gd")
const ScoreSession = preload("res://game/scoring/score_session.gd")
const Skater = preload("res://game/player/skater.gd")
const GlasgowSquare = preload("res://game/levels/glasgow_square.gd")
const Hud = preload("res://game/ui/hud.gd")
const RUN_SECONDS := 120.0

var score := ScoreSession.new()
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
	world = GlasgowSquare.new()
	world.name = "GlasgowSquare"
	add_child(world)
	skater = Skater.new()
	skater.name = "Skater"
	skater.process_mode = Node.PROCESS_MODE_PAUSABLE
	skater.spawn_position = world.get_spawn_position()
	add_child(skater)
	skater.reset_skater()
	skater.trick_performed.connect(_on_trick)
	skater.landed.connect(_on_landed)
	skater.bailed.connect(_on_bailed)
	hud = Hud.new()
	hud.name = "HUD"
	add_child(hud)
	hud.restart_requested.connect(restart_run)
	hud.pause_requested.connect(toggle_pause)
	hud.free_skate_requested.connect(toggle_free_skate)
	_refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_run()
	elif event.is_action_pressed("pause"):
		toggle_pause()
	elif event.is_action_pressed("free_skate"):
		toggle_free_skate()

func _process(delta: float) -> void:
	if not paused and not run_finished:
		_feedback_timer = maxf(0.0, _feedback_timer - delta)
		if not free_skate_mode:
			time_remaining = maxf(0.0, time_remaining - delta)
			if time_remaining <= 0.0:
				if skater.airborne and score.get_combo_value() > 0 and _overtime < 3.0:
					_overtime += delta
				else:
					_finish_run()
	_refresh_hud()

func restart_run() -> void:
	paused = false
	get_tree().paused = false
	run_finished = false
	time_remaining = RUN_SECONDS
	_overtime = 0.0
	score.reset()
	_landings = 0
	_flips = 0
	_grabs = 0
	_feedback = "FRESH RUN. GIE IT LALDY."
	_feedback_timer = 3.0
	skater.reset_skater()
	skater.set_controls_enabled(true)
	skater.set_physics_process(true)
	_refresh_hud()

func toggle_pause() -> void:
	if run_finished:
		return
	paused = not paused
	get_tree().paused = paused
	_refresh_hud()

func toggle_free_skate() -> void:
	free_skate_mode = not free_skate_mode
	restart_run()

func _on_trick(trick_name: String, points: int) -> void:
	if run_finished:
		return
	score.add_trick(trick_name, points)
	if "flip" in trick_name.to_lower():
		_flips += 1
	if "grab" in trick_name.to_lower() or "indy" in trick_name.to_lower():
		_grabs += 1

func _on_landed(clean: bool) -> void:
	if run_finished:
		return
	if clean:
		var banked := score.bank_combo()
		if banked > 0:
			_landings += 1
			_feedback = "LANDED  +%s" % banked
			_feedback_timer = 2.0
	else:
		_on_bailed()

func _on_bailed() -> void:
	score.drop_combo()
	_feedback = "BACK ON THE BOARD."
	_feedback_timer = 2.0

func _finish_run() -> void:
	run_finished = true
	score.drop_combo()
	skater.set_controls_enabled(false)
	skater.set_physics_process(false)

func _refresh_hud() -> void:
	if not is_instance_valid(hud):
		return
	hud.update_display({
		"time": time_remaining, "score": score.total_score,
		"combo": score.get_combo_value(), "multiplier": score.combo_multiplier,
		"combo_base": score.combo_base,
		"tricks": "  +  ".join(score.trick_history), "best": score.best_combo,
		"speed": skater.speed, "airborne": skater.airborne,
		"location": world.get_location_name(skater.global_position),
		"paused": paused, "finished": run_finished, "free_skate": free_skate_mode,
		"feedback": _feedback if _feedback_timer > 0 else "",
		"landings": _landings, "flips": _flips, "grabs": _grabs,
	})
