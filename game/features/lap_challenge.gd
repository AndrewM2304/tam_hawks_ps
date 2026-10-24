extends Node3D
## Ordered physical park traversal. The shortcut is a route choice, never a
## teleport; a real launch and clean landing are required before the finish.

const Art = preload("res://game/features/feature_visuals.gd")
signal feedback(text: String)
const ATTEMPT_SECONDS := 75.0
const GATE_RADIUS := 3.0
const MAX_SWEEP := 6.0
var reduced_motion := false
var _anchor := Vector3.INF
var _branches: Array[Dictionary] = []
var _bounds := Rect2()
var _state := "idle"
var _remaining := 0.0
var _choice := -1
var _index := 0
var _previous := Vector3.INF
var _air_qualified := false
var _landed := false
var _attempts := 0
var _wins := 0
var _reason := ""
var _markers: Array[Node3D] = []
var _celebration := 0.0
var _regular: Node3D

func configure(anchor: Vector3, branches: Array, bounds: Rect2) -> void:
	if not anchor.is_finite() or not bounds.position.is_finite() or bounds.size.x <= 0.0 or bounds.size.y <= 0.0: return
	_anchor = anchor
	_bounds = bounds
	_branches.clear()
	for raw: Variant in branches:
		if not raw is Dictionary: continue
		var points: Variant = raw.get("points")
		if not points is PackedVector3Array or points.size() < 3: continue
		var valid := true
		for at: Vector3 in points:
			valid = valid and at.is_finite() and bounds.has_point(Vector2(at.x, at.z))
		if valid: _branches.append({"id": str(raw.get("id", "route")), "label": str(raw.get("label", "Park loop")), "points": points.duplicate()})
	if _branches.is_empty(): return
	_regular = Art.regular(self, to_local(anchor + Vector3(2.7, 0, 0)))
	Art.sign(self, to_local(anchor + Vector3(0, 2.5, 0)), "ONE MORE LAP, HEN\nCHOOSE A LOOP · LAND A POP")
	var placed: Dictionary = {}
	for branch: Dictionary in _branches:
		for i in branch.points.size():
			var at: Vector3 = branch.points[i]
			var key := str(at)
			var cue := "%d · %s" % [i+1,str(branch.label).to_upper()]
			if placed.has(key):
				var shared: Label3D = placed[key].get_node("ActivitySign")
				shared.text += "\n"+cue
				continue
			var mark := Node3D.new()
			mark.position = to_local(at)
			add_child(mark)
			Art.cylinder(mark, "PaintedGate", Vector3(0, 0.015, 0), GATE_RADIUS, 0.025, Color("9b955a"))
			Art.sign(mark, Vector3(0, 1.3, 0), cue, Color("e1d69d"))
			placed[key] = mark
			_markers.append(mark)
	reset_run()

func nearby_prompt(at: Vector3) -> String:
	if _anchor.is_finite() and _state != "active" and _near(at, _anchor, 4.0): return "TRY ONE MORE LAP"
	return ""

func poll(at: Vector3, interact: bool, delta: float, combo_value: int = 0) -> void:
	if not at.is_finite() or _branches.is_empty(): return
	if _celebration > 0.0 and is_finite(delta) and delta > 0.0:
		_celebration = maxf(0.0, _celebration - delta)
		if is_instance_valid(_regular): _regular.rotation.y = 0.0 if reduced_motion else sin(_celebration * 8.0) * 0.20
	if _state != "active":
		if interact and not nearby_prompt(at).is_empty():
			if combo_value > 0:
				feedback.emit("PARK REGULAR: Settle that line first, then we'll time you.")
			else:
				_state = "active"
				_remaining = ATTEMPT_SECONDS
				_choice = -1
				_index = 0
				_previous = at
				_air_qualified = false
				_landed = false
				_attempts += 1
				_reason = ""
				feedback.emit("PARK REGULAR: Follow the numbered gates. Pick the full loop or bank cut, land a pop, and come back. 75 seconds!")
		return
	if not _bounds.has_point(Vector2(at.x, at.z)):
		_fail("Keep this lap in the park. Come back for another go.")
		return
	if not is_finite(delta) or delta <= 0.0: return
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= 0.000000001:
		_remaining = 0.0
		_fail("Time's up. One more lap when you're ready.")
		return
	if not _previous.is_finite() or _previous.distance_to(at) > MAX_SWEEP:
		_previous = at
		return
	if _choice < 0:
		for branch_index in _branches.size():
			if _crossed(_previous, at, _branches[branch_index].points[0]):
				_choice = branch_index
				_index = 1
				feedback.emit("PARK REGULAR: %s it is. Keep the numbers in order!" % str(_branches[_choice].label))
				break
	else:
		var points: PackedVector3Array = _branches[_choice].points
		if _index < points.size() and _crossed(_previous, at, points[_index]):
			_index += 1
		elif _index < points.size():
			for future in range(_index + 1, points.size()):
				if _crossed(_previous, at, points[future]):
					_fail("Missed a numbered gate. Back to the start for a fresh lap.")
					break
		if _state == "active" and _index == points.size() and _near(at, _anchor, 3.2):
			if _landed:
				_state = "success"
				_reason = ""
				_wins += 1
				_celebration = 2.4
				feedback.emit("PARK REGULAR: A clean lap! You've still got another in you, hen.")
			else:
				_reason = "Land a real pop, then return to the finish."
	_previous = at

func on_launch(at: Vector3) -> void:
	if _state == "active" and _bounds.has_point(Vector2(at.x, at.z)):
		_air_qualified = true

func on_landed(clean: bool) -> void:
	if _state == "active" and clean and _air_qualified:
		_landed = true
		_air_qualified = false

func on_bail() -> void:
	if _state == "active": _fail("That was a tumble. Another lap starts back by me.")

func cancel_attempt() -> void:
	if _state == "active": _fail("Lap cancelled. The park will still be here.")

func finish_run() -> void:
	if _state == "active": _fail("Run finished. Try another lap next time.")

func reset_run() -> void:
	_state = "idle"
	_remaining = 0.0
	_choice = -1
	_index = 0
	_previous = Vector3.INF
	_air_qualified = false
	_landed = false
	_attempts = 0
	_wins = 0
	_reason = ""
	_celebration = 0.0
	if is_instance_valid(_regular): _regular.rotation.y = 0.0

func _fail(reason: String) -> void:
	_state = "failed"
	_reason = reason
	_air_qualified = false
	feedback.emit("PARK REGULAR: " + reason)

func status_snapshot() -> Dictionary:
	var next := _anchor
	var navigation: Array[Dictionary] = []
	var stage := "CHOOSE ROUTE"
	if _choice >= 0:
		var points: PackedVector3Array = _branches[_choice].points
		if _index < points.size():
			next = points[_index]
			stage = "GATE %d" % (_index+1)
		else:
			stage = "FINISH"
		if _state=="active":
			navigation.append({"position":next,"label":str(_branches[_choice].label)+" · "+stage.capitalize()})
	elif _state=="active":
		for branch: Dictionary in _branches:
			navigation.append({"position":branch.points[0],"label":str(branch.label)+" · Gate 1"})
	var text := "ONE MORE LAP · PICK A ROUTE"
	if _state == "active":
		text = "PARK LAP · %ds · %s · %s" % [ceili(_remaining),stage,"POP LANDED" if _landed else "LAND A POP"]
	elif not _reason.is_empty(): text = _reason
	elif _state == "success": text = "ONE MORE LAP · CLEAN FINISH"
	return {"id": "one_more_lap", "state": _state, "remaining": _remaining, "attempts": _attempts,
		"wins": _wins, "position": _anchor, "payoff_position": _anchor, "branch": _choice,
		"gate_index": _index, "landed_pop": _landed, "hud_text": text, "reason": _reason,
		"next_gate": next,"navigation_targets":navigation,"branches": _branches.duplicate(true)}

static func _near(a: Vector3, b: Vector3, radius: float) -> bool:
	return a.is_finite() and b.is_finite() and absf(a.y - b.y) <= 1.6 and Vector2(a.x-b.x, a.z-b.z).length() <= radius

static func _crossed(from: Vector3, to: Vector3, gate: Vector3) -> bool:
	var closest := Geometry3D.get_closest_point_to_segment(gate, from, to)
	return _near(closest, gate, GATE_RADIUS)
