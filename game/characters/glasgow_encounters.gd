extends Node3D
## Original, replayable free-skate encounters. Real score callbacks provide evidence;
## this node never awards score, changes career saves or manufactures trick events.

const BuskerActor = preload("res://game/characters/busker_actor.gd")
const ENCOUNTER_ID := "busker_big_finish"
const ATTEMPT_SECONDS := 35.0
const INTERACT_RADIUS := 4.2
const COURT_RADIUS := 34.0
const TARGET_POINTS := 1000
const REQUIRED_FAMILIES := 3

signal feedback(text: String)

var reduced_motion := false
var _anchor := Vector3.INF
var _actor: Node3D
var _state := "idle"
var _remaining := 0.0
var _families: Dictionary = {}
var _combo_valid := true
var _attempts := 0
var _wins := 0
var _reason := ""
var _audio_gain := 0.0
var _audio_enabled := true

func configure(definitions: Array) -> void:
	if is_instance_valid(_actor):
		_actor.queue_free()
	_actor = null
	_anchor = Vector3.INF
	for raw in definitions:
		if not raw is Dictionary or String(raw.get("id", "")) != ENCOUNTER_ID:
			continue
		var at: Variant = raw.get("position")
		if not at is Vector3 or not at.is_finite():
			continue
		_anchor = at
		_actor = BuskerActor.new()
		_actor.name = "MoBusker"
		_actor.position = to_local(_anchor)
		var yaw: float = float(raw.get("heading", 0.93))
		_actor.rotation.y = yaw if is_finite(yaw) else 0.93
		add_child(_actor)
		break
	reset_run()

## Called only during active play. Existing combos must resolve before a fresh
## attempt, so an old high-value line cannot be imported into Mo's challenge.
func poll(position: Vector3, interact: bool, delta: float, combo_value: int = 0) -> void:
	if not _anchor.is_finite() or not position.is_finite():
		return
	if _state == "active":
		if is_finite(delta) and delta > 0.0:
			_remaining = maxf(0.0, _remaining - delta)
		if not _inside_court(position):
			_families.clear()
			_combo_valid = false
		if _remaining <= 0.000000001:
			_fail("Time's up. Mo's got another chorus if you have.")
	elif interact and _near_actor(position):
		if combo_value > 0:
			feedback.emit("MO: Bank that line first, then we'll start fresh.")
		else:
			_state = "active"
			_remaining = ATTEMPT_SECONDS
			_families.clear()
			_combo_valid = true
			_reason = ""
			_attempts += 1
			feedback.emit("MO: Gie it laldy! Bank 1,000 with 3 trick types in this court. 35 seconds.")
	_sync_actor()

func on_trick(trick_name: String, points: int, position: Vector3) -> void:
	if _state != "active" or points <= 0:
		return
	if not _inside_court(position):
		_families.clear()
		_combo_valid = false
		return
	if not _combo_valid:
		return
	var family := _trick_family(trick_name)
	if not family.is_empty():
		_families[family] = true
	_sync_actor()

func on_bank(points: int, position: Vector3) -> void:
	if _state != "active":
		return
	if _combo_valid and _inside_court(position) and points >= TARGET_POINTS and _families.size() >= REQUIRED_FAMILIES:
		_state = "success"
		_reason = "A big finish, right enough."
		_wins += 1
		feedback.emit("YA DANCER! MO'S BIG FINISH COMPLETE. %s points, %s trick types." % [points, _families.size()])
	else:
		# A resolved short combo is a fresh chance within the same timed attempt.
		_families.clear()
		_combo_valid = true
	_sync_actor()

func on_bail() -> void:
	if _state == "active":
		_fail("No bother. Back to Mo for another go.")

func finish_run() -> void:
	if _state == "active":
		_fail("Shift's over. Find Mo again on your next run.")
	_audio_enabled = false
	_sync_actor()

func set_mix(master: float, ambience: float) -> void:
	var master_gain := clampf(master, 0.0, 1.0) if is_finite(master) else 0.0
	var ambience_gain := clampf(ambience, 0.0, 1.0) if is_finite(ambience) else 0.0
	_audio_gain = master_gain * ambience_gain
	_sync_actor()

func reset_run() -> void:
	_state = "idle"
	_remaining = 0.0
	_families.clear()
	_combo_valid = true
	_attempts = 0
	_wins = 0
	_reason = ""
	_audio_enabled = true
	_sync_actor()

func nearby_prompt(position: Vector3) -> String:
	if not _near_actor(position) or _state == "active":
		return ""
	return "MO'S BIG FINISH" if _state == "idle" else "MO: TRY AGAIN"

func status_snapshot() -> Dictionary:
	return {"id": ENCOUNTER_ID, "title": "Mo's Big Finish", "state": _state,
		"remaining": _remaining, "family_count": _families.size(),
		"required_families": REQUIRED_FAMILIES, "target_points": TARGET_POINTS,
		"attempts": _attempts, "wins": _wins, "reason": _reason,
		"detail": _display_detail(), "hud_text": _display_detail(),
		"position": _anchor, "combo_valid": _combo_valid}

func _display_detail() -> String:
	if _state == "active":
		if not _combo_valid:
			return "MO  %ss | Back in the court; bank this line to start fresh." % ceili(_remaining)
		return "MO  %ss | %s/3 trick types | Bank 1,000 in one clean line" % [ceili(_remaining), _families.size()]
	if _state == "success":
		return "MO'S BIG FINISH COMPLETE | Return to Mo to replay"
	if _state == "failed":
		return "MO'S BIG FINISH | Return to Mo for another go"
	return ""

func _near_actor(position: Vector3) -> bool:
	if not position.is_finite() or not _anchor.is_finite():
		return false
	var offset := position - _anchor
	return Vector2(offset.x, offset.z).length() <= INTERACT_RADIUS and absf(offset.y) < 2.5

func _inside_court(position: Vector3) -> bool:
	if not position.is_finite() or not _anchor.is_finite():
		return false
	var offset := position - _anchor
	return Vector2(offset.x, offset.z).length() <= COURT_RADIUS and absf(offset.y) < 10.0

func _fail(reason: String) -> void:
	_state = "failed"
	_reason = reason
	_families.clear()
	feedback.emit("MO: " + reason)
	_sync_actor()

func _sync_actor() -> void:
	if is_instance_valid(_actor):
		_actor.set_encounter_state(_state, _families.size(), _remaining)
		_actor.reduced_motion = reduced_motion
		_actor.set_audio_gain(_audio_gain)
		_actor.set_audio_enabled(_audio_enabled)

func _trick_family(trick_name: String) -> String:
	var lower := trick_name.strip_edges().to_lower()
	if lower == "ollie": return "ollie"
	if "flip" in lower: return "flip"
	if "grab" in lower or "indy" in lower: return "grab"
	if "grind" in lower: return "grind"
	if "manual" in lower: return "manual"
	if "revert" in lower: return "revert"
	if "spin" in lower or lower.begins_with("frontside ") or lower.begins_with("backside ") or lower.begins_with("180") or lower.begins_with("360") or lower.begins_with("540") or lower.begins_with("720"): return "spin"
	if "clyde carousel" in lower or "tenement tumble" in lower: return "special"
	return ""
