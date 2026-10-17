extends Node3D
## Session-local delivery. Trusted callbacks are real player Manual/gap/bank events;
## physical gate polling supplies route/arrival evidence, never points or saves.

const MarketActor = preload("res://game/characters/market_actor.gd")
const ENCOUNTER_ID := "gull_proof_delivery"
const ATTEMPT_SECONDS := 60.0
const INTERACT_RADIUS := 4.2

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
var _delivery := Vector3.INF
var _bounds := Rect2()
var _routes: Array[Dictionary] = []
var _required_gap := ""
var _gate_radius := 2.2
var _delivery_radius := 2.6
var _actor: Node3D
var _carrier: Node3D
var _bag: Node3D
var _state := "idle"
var _remaining := 0.0
var _attempts := 0
var _wins := 0
var _reason := ""
var _manual_seen := false
var _gap_seen := false
var _line_banked := false
var _route_choice := -1
var _route_index := 0
var _celebration_state := "none"
var _celebration_started := false

func configure(definitions: Array) -> void:
	if is_instance_valid(_actor): _actor.queue_free()
	_actor = null
	_anchor = Vector3.INF
	_delivery = Vector3.INF
	_bounds = Rect2()
	_required_gap = ""
	_routes.clear()
	for raw in definitions:
		if not raw is Dictionary or String(raw.get("id", "")) != ENCOUNTER_ID: continue
		var at: Variant = raw.get("position")
		var end: Variant = raw.get("delivery_position")
		var bounds: Variant = raw.get("area_bounds")
		var routes: Variant = raw.get("routes")
		var gap := String(raw.get("required_gap", ""))
		var gate_radius := float(raw.get("gate_radius", 2.2))
		var delivery_radius := float(raw.get("delivery_radius", 2.6))
		if not at is Vector3 or not at.is_finite() or not end is Vector3 or not end.is_finite(): continue
		if not bounds is Rect2 or not bounds.position.is_finite() or not bounds.size.is_finite(): continue
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or gap.strip_edges().is_empty(): continue
		if not is_finite(gate_radius) or gate_radius < 0.5 or gate_radius > 4.0: continue
		if not is_finite(delivery_radius) or delivery_radius < 0.5 or delivery_radius > 4.0: continue
		if not _valid_routes(routes, bounds): continue
		if not _in_bounds(at, bounds) or not _in_bounds(end, bounds): continue
		_anchor = at
		_delivery = end
		_bounds = bounds
		_required_gap = gap
		_gate_radius = gate_radius
		_delivery_radius = delivery_radius
		for route: Dictionary in routes:
			var normalized: Dictionary=route.duplicate(true)
			normalized.label=String(route.get("label",route.id))
			_routes.append(normalized)
		_actor = MarketActor.new()
		_actor.name = "MarketStallholder"
		_actor.position = to_local(_anchor)
		var yaw := float(raw.get("heading", PI))
		_actor.rotation.y = yaw if is_finite(yaw) else PI
		add_child(_actor)
		var delivery_yaw := float(raw.get("delivery_heading", PI))
		_actor.configure_delivery(_delivery, delivery_yaw if is_finite(delivery_yaw) else PI)
		_actor.configure_route_marks(_routes,_delivery,_gate_radius,_delivery_radius)
		break
	reset_run()

func set_carrier(rider: Node3D) -> void:
	if is_instance_valid(_bag): _bag.queue_free()
	_bag = null
	_carrier = rider.get_node_or_null("TorsoRig") as Node3D if is_instance_valid(rider) else null
	if not is_instance_valid(_carrier): _carrier = rider
	if is_instance_valid(_carrier):
		_bag = MarketActor.create_courier_bag(_carrier)
		_bag.visible = _state == "active"

func _exit_tree() -> void:
	if is_instance_valid(_bag): _bag.queue_free()

func poll(position: Vector3, interact: bool, delta: float, combo_value: int = 0, audience_visible: bool = false) -> void:
	if not _anchor.is_finite() or not position.is_finite(): return
	if _state == "active":
		if not _inside_area(position):
			_fail("That parcel belongs in the market. Back to the stall for another go.")
		elif is_finite(delta) and delta > 0.0:
			_remaining = maxf(0.0, _remaining-delta)
			if _remaining <= 0.000000001: _fail("Time's up. Parcel's back at the stall, safe and sound.")
		if _state == "active":
			_update_route(position)
			_try_delivery(position)
	elif interact and _near(position, _anchor, INTERACT_RADIUS):
		if combo_value > 0:
			feedback.emit("MAIRI: Bank that line first. This parcel needs a fresh start.")
		else:
			_state = "active"
			_remaining = ATTEMPT_SECONDS
			_attempts += 1
			_reason = ""
			_clear_line()
			_celebration_state = "none"
			_celebration_started = false
			if is_instance_valid(_actor): _actor.stop_celebration()
			feedback.emit("MAIRI: Manual into the loading-steps gap, land and bank. Pick a marked lane to the south counter. 60 seconds!")
	_update_celebration(position, audience_visible)
	_sync_actor()

func on_trick(trick: String, points: int, position: Vector3) -> void:
	if not _check_callback(position): return
	if not _line_banked and points > 0 and trick in ["Manual", "Nose Manual"]:
		if not _manual_seen: feedback.emit("MAIRI: Steady! Now ollie the marked loading steps in this line.")
		_manual_seen = true
	_sync_actor()

func on_gap(gap_id: String, position: Vector3) -> void:
	if not _check_callback(position): return
	if not _line_banked and _manual_seen and gap_id == _required_gap:
		if not _gap_seen: feedback.emit("MAIRI: That's the steps! Land and bank, then follow either marked market lane.")
		_gap_seen = true
	_sync_actor()

func on_bank(points: int, position: Vector3) -> void:
	if not _check_callback(position) or points <= 0: return
	if not _line_banked:
		if _manual_seen and _gap_seen:
			_line_banked = true
			feedback.emit("MAIRI: Parcel's still upright! Through a marked lane to the south counter.")
		else:
			_clear_line()
			feedback.emit("MAIRI: Try that line again: Manual, loading-steps gap, then a clean bank. Clock's still running.")
	_try_delivery(position)
	_sync_actor()

func on_bail() -> void:
	if _state == "active": _fail("No spilled breakfasts today. Parcel's back at the stall; have another go.")

func cancel_attempt() -> void:
	if _state == "active": _fail("Parcel returned while you try another challenge. Come back any time.")

func finish_run() -> void:
	if _state == "active": _fail("Shift's over. Fresh parcel next run.")
	elif _state == "success" and _celebration_state in ["queued", "playing"]:
		_celebration_state = "finished"
		if is_instance_valid(_actor): _actor.stop_celebration()
	_sync_actor()

func reset_run() -> void:
	_state = "idle"
	_remaining = 0.0
	_attempts = 0
	_wins = 0
	_reason = ""
	_clear_line()
	_celebration_state = "none"
	_celebration_started = false
	if is_instance_valid(_actor): _actor.stop_celebration()
	_sync_actor()

func nearby_prompt(position: Vector3) -> String:
	if _state == "active" or not _near(position, _anchor, INTERACT_RADIUS): return ""
	return "GULL-PROOF DELIVERY" if _state == "idle" else "MAIRI: ANOTHER DELIVERY?"

func status_snapshot() -> Dictionary:
	var route: Dictionary = _routes[_route_choice] if _route_choice >= 0 else {}
	var next := Vector3.INF
	if not route.is_empty() and _route_index < 3: next = route.gates[_route_index]
	return {"id":ENCOUNTER_ID,"title":"Gull-Proof Delivery","state":_state,
		"remaining":_remaining,"attempts":_attempts,"wins":_wins,"reason":_reason,
		"position":_anchor,"payoff_position":_delivery,"area_bounds":_bounds,
		"manual_seen":_manual_seen,"gap_seen":_gap_seen,"line_banked":_line_banked,
		"required_gap":_required_gap,"route_id":String(route.get("id","")),
		"route_label":String(route.get("label","")),"route_index":_route_index,
		"route_total":3,"next_gate":next,"carrying":_state=="active",
		"navigation_targets":_navigation_targets(),
		"celebration_state":_celebration_state,"celebration_started":_celebration_started,
		"hud_text":_display_detail()}

func _navigation_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary]=[]
	if _state!="active" or not _gap_seen: return targets
	if _route_choice<0:
		for route: Dictionary in _routes:
			targets.append({"label":_navigation_label(route,1),"position":route.gates[0]})
	elif _route_index<3:
		var route: Dictionary=_routes[_route_choice]
		targets.append({"label":_navigation_label(route,_route_index+1),"position":route.gates[_route_index]})
	else:
		targets.append({"label":"DELIVERY","position":_delivery})
	return targets

func _navigation_label(route: Dictionary,index: int) -> String:
	var label:=String(route.label).strip_edges()
	if label.is_empty(): label=String(route.id)
	return "%s %s" % [label.get_slice(" ",0).to_upper(),index]

func _check_callback(position: Vector3) -> bool:
	if _state != "active": return false
	if not _inside_area(position):
		_fail("Keep the parcel in the market. It's back at the stall for a retry.")
		return false
	return true

func _update_route(position: Vector3) -> void:
	if not _gap_seen: return
	if _route_choice < 0:
		for index in _routes.size():
			if _near(position,_routes[index].gates[0],_gate_radius):
				_route_choice=index
				_route_index=1
				feedback.emit("MAIRI: %s it is! Lane marker 1 of 3." % _routes[index].label)
				break
	elif _route_index < 3 and _near(position,_routes[_route_choice].gates[_route_index],_gate_radius):
		_route_index += 1
		feedback.emit("MAIRI: Lane marker %s of 3. %s" % [_route_index,"South counter next!" if _route_index==3 else "Keep it coming!"])

func _try_delivery(position: Vector3) -> void:
	if _state != "active" or not _line_banked or _route_index != 3 or not _near(position,_delivery,_delivery_radius): return
	_state = "success"
	_wins += 1
	_reason = "Breakfast delivered. The gull gets the spare wrapping parcel."
	_celebration_state = "static" if reduced_motion else "queued"
	_celebration_started = false
	feedback.emit("MAIRI: GULL-PROOF DELIVERY COMPLETE! Yours is safe. That gull can have the spare wrapper!")
	_sync_actor()

func _update_celebration(position: Vector3, audience_visible: bool) -> void:
	if _state != "success" or not is_instance_valid(_actor): return
	if _celebration_state == "playing":
		if not bool(_actor.animation_snapshot().payoff_active): _celebration_state="finished"
	elif _celebration_state == "queued" and audience_visible and _near(position,_delivery,10.0):
		_celebration_state="playing"
		_celebration_started=true
		_actor.start_celebration()
		feedback.emit("MAIRI: Oi! That's the spare parcel, you feathered chancer!")

func _clear_line() -> void:
	_manual_seen=false
	_gap_seen=false
	_line_banked=false
	_route_choice=-1
	_route_index=0

func _fail(reason: String) -> void:
	_state="failed"
	_reason=reason
	_clear_line()
	_celebration_state="none"
	_celebration_started=false
	if is_instance_valid(_actor): _actor.stop_celebration()
	feedback.emit("MAIRI: "+reason)
	_sync_actor()

func _near(position: Vector3, anchor: Vector3, radius: float) -> bool:
	if not position.is_finite() or not anchor.is_finite(): return false
	var offset:=position-anchor
	return Vector2(offset.x,offset.z).length() <= radius and absf(offset.y)<2.5

func _inside_area(position: Vector3) -> bool:
	return _anchor.is_finite() and _in_bounds(position,_bounds)

func _in_bounds(position: Vector3,bounds: Rect2) -> bool:
	return position.is_finite() and position.x>=bounds.position.x and position.x<=bounds.end.x and position.z>=bounds.position.y and position.z<=bounds.end.y and position.y>=-3.0 and position.y<=12.0

func _valid_routes(raw: Variant,bounds: Rect2) -> bool:
	if not raw is Array or raw.size()!=2: return false
	var seen: Dictionary={}
	for route in raw:
		if not route is Dictionary: return false
		var id:=String(route.get("id",""))
		var gates: Variant=route.get("gates")
		if id.strip_edges().is_empty() or seen.has(id): return false
		if not (gates is PackedVector3Array or gates is Array) or gates.size()!=3: return false
		for index in 3:
			if not gates[index] is Vector3 or not _in_bounds(gates[index],bounds): return false
			for earlier in index:
				if gates[index].distance_to(gates[earlier])<4.5: return false
		seen[id]=true
	return true

func _display_detail() -> String:
	if _state=="active":
		var lead:="MAIRI  %ss | " % ceili(_remaining)
		if not _manual_seen: return lead+"MANUAL > LOADING-STEPS GAP > CLEAN BANK"
		if not _gap_seen: return lead+"MANUAL READY | OLLIE THE LOADING STEPS"
		if not _line_banked: return lead+"GAP READY | LAND AND BANK"
		if _route_choice<0: return lead+"LINE BANKED | ENTER COVERED OR WEST LANE (NORTH MARKER)"
		if _route_index<3: return lead+"%s %s/3 | NEXT: MARKER %s" % [_routes[_route_choice].label,_route_index,_route_index+1]
		return lead+"3/3 LANE MARKERS | ARRIVE AT SOUTH DELIVERY COUNTER"
	if _state=="success":
		if _celebration_state=="queued": return "DELIVERY COMPLETE | Look towards the south counter for the gull's spare-parcel raid"
		if _celebration_state=="playing": return "DELIVERY COMPLETE | That feathered chancer! Yours is safe."
		if _celebration_state=="static": return "DELIVERY COMPLETE | Gull with spare wrapper (reduced motion)"
		return "DELIVERY COMPLETE | Return to Mairi for another delivery"
	if _state=="failed": return "GULL-PROOF DELIVERY | Parcel returned. Back to Mairi for another go"
	return ""

func _sync_actor() -> void:
	if is_instance_valid(_bag): _bag.visible=_state=="active"
	if is_instance_valid(_actor):
		_actor.set_encounter_state(_state,_remaining,reduced_motion,_celebration_state,_display_detail())
		_actor.set_navigation_targets(_navigation_targets())
