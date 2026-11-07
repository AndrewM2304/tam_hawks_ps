extends Node3D
## Session-local bin-busker challenge, driven only by attributed real grind captures
## and resolved score banks. No proximity capture, points, saves or career awards.

const CatActor = preload("res://game/characters/cat_actor.gd")
const ENCOUNTER_ID := "cat_got_the_beat"
const ATTEMPT_SECONDS := 60.0
const INTERACT_RADIUS := 4.2
const DEFAULT_SEQUENCE: Array[String] = ["Grind_Cat_A", "Grind_Cat_B", "Grind_Cat_C"]

signal feedback(text: String)

var reduced_motion := false:
	set(value):
		reduced_motion = value
		if _state == "success":
			if value:
				_celebration_state = "static"
				if is_instance_valid(_actor): _actor.stop_celebration()
			elif _celebration_state == "static":
				_celebration_state = "finished" if _celebration_started else "queued"
		_sync_actor()

var _anchor := Vector3.INF
var _area_center := Vector3.INF
var _area_radius := 32.0
var _required_ids: Array[String] = []
var _actor: Node3D
var _state := "idle"
var _remaining := 0.0
var _sequence_index := 0
var _last_capture_id := ""
var _attempts := 0
var _wins := 0
var _reason := ""
var _celebration_state := "none"
var _celebration_started := false
var _audio_gain := 0.0
var _audio_enabled := true

func configure(definitions: Array) -> void:
	if is_instance_valid(_actor):
		_actor.queue_free()
	_actor = null
	_anchor = Vector3.INF
	_area_center = Vector3.INF
	_required_ids.clear()
	for raw in definitions:
		if not raw is Dictionary or String(raw.get("id", "")) != ENCOUNTER_ID:
			continue
		var at: Variant = raw.get("position")
		var center: Variant = raw.get("area_center", at)
		var sequence: Variant = raw.get("sequence", DEFAULT_SEQUENCE)
		var radius: float = float(raw.get("area_radius", 32.0))
		if not at is Vector3 or not at.is_finite() or not center is Vector3 or not center.is_finite():
			continue
		if not is_finite(radius) or radius < 8.0 or radius > 60.0 or not _valid_sequence(sequence):
			continue
		_anchor = at
		_area_center = center
		_area_radius = radius
		for rail_id: String in sequence:
			_required_ids.append(rail_id)
		_actor = CatActor.new()
		_actor.name = "RaeBinBusker"
		_actor.position = to_local(_anchor)
		var yaw: float = float(raw.get("heading", PI))
		_actor.rotation.y = yaw if is_finite(yaw) else PI
		add_child(_actor)
		break
	reset_run()

func poll(position: Vector3, interact: bool, delta: float, combo_value: int = 0, audience_visible: bool = false) -> void:
	if not _anchor.is_finite() or not position.is_finite():
		return
	if _state == "active":
		if not _inside_area(position):
			_fail("Back to the bin session for another go. Keep the line in this court.")
		elif is_finite(delta) and delta > 0.0:
			_remaining = maxf(0.0, _remaining - delta)
			if _remaining <= 0.000000001:
				_fail("Time's up. The wee cats can wait for another beat.")
	elif interact and _near_actor(position):
		if combo_value > 0:
			feedback.emit("RAE: Bank that line first. Fresh beat, fresh start.")
		else:
			_state = "active"
			_remaining = ATTEMPT_SECONDS
			_sequence_index = 0
			_last_capture_id = ""
			_reason = ""
			_celebration_state = "none"
			_celebration_started = false
			_attempts += 1
			feedback.emit("RAE: Give us a skate beat! Grind A > B > C, then land and bank. 60 seconds.")
	_update_celebration(position, audience_visible)
	_sync_actor()

func on_grind_capture(rail_id: String, position: Vector3) -> void:
	if _state != "active": return
	if not _inside_area(position):
		_fail("That line left the busking court. Come back for another go.")
		return
	if not _required_ids.has(rail_id) or rail_id == _last_capture_id:
		return
	_last_capture_id = rail_id
	if _sequence_index < _required_ids.size() and rail_id == _required_ids[_sequence_index]:
		_sequence_index += 1
		if _sequence_index == _required_ids.size():
			feedback.emit("RAE: All three in time! Land and bank for the cats' big finish.")
		else:
			feedback.emit("RAE: Nice one. Next coping: %s." % _letter(_sequence_index))
	else:
		_sequence_index = 1 if rail_id == _required_ids[0] else 0
		feedback.emit("RAE: Wrong order. %s" % ("A's in time; next is B." if _sequence_index == 1 else "Start again at A."))
	_sync_actor()

func on_bank(points: int, position: Vector3) -> void:
	if _state != "active": return
	if not _inside_area(position):
		_fail("Bank it in the busking court. Back to Rae for another go.")
		return
	if points <= 0 or _sequence_index != _required_ids.size(): return
	_state = "success"
	_wins += 1
	_reason = "Three copings. Two dancing toy cats and one big bin beat."
	_celebration_state = "static" if reduced_motion else "queued"
	_celebration_started = false
	if reduced_motion:
		feedback.emit("RAE: PURR-FECT! CAT'S GOT THE BEAT COMPLETE. Two proud wee paw salutes!")
	else:
		feedback.emit("RAE: PURR-FECT! CAT'S GOT THE BEAT COMPLETE. Come back for the wee cats' dance.")
	_sync_actor()

func on_bail() -> void:
	if _state == "active": _fail("No bother. Come back and we'll strike up another beat.")

func cancel_attempt() -> void:
	if _state == "active": _fail("Bin session paused for another challenge. Come back any time.")

func finish_run() -> void:
	if _state == "active": _fail("Shift's over. The bin session will be here next run.")
	elif _state == "success" and _celebration_state in ["queued", "playing"]:
		_celebration_state = "finished"
		if is_instance_valid(_actor): _actor.stop_celebration()
	_audio_enabled = false
	_sync_actor()

func set_mix(master: float, ambience: float) -> void:
	var master_gain := clampf(master,0.0,1.0) if is_finite(master) else 0.0
	var ambience_gain := clampf(ambience,0.0,1.0) if is_finite(ambience) else 0.0
	_audio_gain = master_gain*ambience_gain
	_sync_actor()

func reset_run() -> void:
	if is_instance_valid(_actor): _actor.set_audio_enabled(false)
	_state = "idle"
	_remaining = 0.0
	_sequence_index = 0
	_last_capture_id = ""
	_attempts = 0
	_wins = 0
	_reason = ""
	_celebration_state = "none"
	_celebration_started = false
	_audio_enabled = true
	_sync_actor()

func nearby_prompt(position: Vector3) -> String:
	if not _near_actor(position) or _state == "active": return ""
	return "CAT'S GOT THE BEAT" if _state == "idle" else "RAE: TRY AGAIN"

func status_snapshot() -> Dictionary:
	var next_id := _required_ids[_sequence_index] if _sequence_index < _required_ids.size() else ""
	return {"id": ENCOUNTER_ID, "title": "Cat's Got the Beat", "state": _state,
		"remaining": _remaining, "sequence_index": _sequence_index,
		"next_rail_id": next_id, "required_ids": _required_ids.duplicate(),
		"attempts": _attempts, "wins": _wins, "reason": _reason,
		"position": _anchor, "area_center": _area_center, "area_radius": _area_radius,
		"hud_text": _display_detail(), "celebration_state": _celebration_state,
		"celebration_started": _celebration_started}

func _update_celebration(position: Vector3, audience_visible: bool) -> void:
	if _state != "success" or reduced_motion or not is_instance_valid(_actor): return
	if _celebration_state == "playing":
		if not _actor.animation_snapshot().dance_active:
			_celebration_state = "finished"
	elif _celebration_state == "queued" and audience_visible:
		var offset := position - _anchor
		if Vector2(offset.x,offset.z).length() <= 10.0 and absf(offset.y) < 2.5:
			_celebration_started = true
			_celebration_state = "playing"
			_actor.start_celebration()
			feedback.emit("RAE: There we go! Look at those wee paws.")

func _valid_sequence(raw: Variant) -> bool:
	if not raw is Array or raw.size() != 3: return false
	var seen: Dictionary = {}
	for rail_id in raw:
		if not rail_id is String or rail_id.strip_edges().is_empty() or seen.has(rail_id):
			return false
		seen[rail_id] = true
	return true

func _near_actor(position: Vector3) -> bool:
	if not position.is_finite() or not _anchor.is_finite(): return false
	var offset := position - _anchor
	return Vector2(offset.x, offset.z).length() <= INTERACT_RADIUS and absf(offset.y) < 2.5

func _inside_area(position: Vector3) -> bool:
	if not position.is_finite() or not _area_center.is_finite(): return false
	var offset := position - _area_center
	return Vector2(offset.x, offset.z).length() <= _area_radius and absf(offset.y) < 10.0

func _letter(index: int) -> String:
	return ["A", "B", "C"][clampi(index, 0, 2)]

func _display_detail() -> String:
	if _state == "active":
		if _sequence_index == 3:
			return "RAE  %ss | A > B > C IN TIME | LAND AND BANK" % ceili(_remaining)
		return "RAE  %ss | %s/3 beats | A > B > C | NEXT: %s" % [ceili(_remaining), _sequence_index, _letter(_sequence_index)]
	if _state == "success":
		if _celebration_state == "queued": return "CAT'S GOT THE BEAT COMPLETE | Return to Rae to see the cats dance"
		if _celebration_state == "playing": return "CAT'S GOT THE BEAT COMPLETE | The wee cats are dancing!"
		if _celebration_state == "static": return "CAT'S GOT THE BEAT COMPLETE | Two paw salutes (reduced motion)"
		return "CAT'S GOT THE BEAT COMPLETE | Return to Rae to replay"
	if _state == "failed": return "CAT'S GOT THE BEAT | Return to Rae for another go"
	return ""

func _fail(reason: String) -> void:
	_state = "failed"
	_reason = reason
	_sequence_index = 0
	_last_capture_id = ""
	_celebration_state = "none"
	_celebration_started = false
	feedback.emit("RAE: " + reason)
	_sync_actor()

func _sync_actor() -> void:
	if is_instance_valid(_actor):
		_actor.set_encounter_state(_state, _sequence_index, _remaining, reduced_motion, _celebration_state)
		_actor.set_audio_gain(_audio_gain)
		_actor.set_audio_enabled(_audio_enabled)
