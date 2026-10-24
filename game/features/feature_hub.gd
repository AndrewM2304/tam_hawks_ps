extends Node3D
## Original optional activities. No career/save identities, points or unlocks.
## Main forwards actual player events and owns cross-challenge offer priority.

const Gate = preload("res://game/features/service_gate.gd")
const Cone = preload("res://game/features/cone_stunt.gd")
const Lap = preload("res://game/features/lap_challenge.gd")
const Vehicle = preload("res://game/features/skate_vehicle.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
signal feedback(text: String)
signal routes_changed()
var gate: Node3D
var cone_stunt: Node3D
var park_lap: Node3D
var vehicle: CharacterBody3D
var reduced_motion := false:
	set(value):
		reduced_motion = value
		if is_instance_valid(cone_stunt): cone_stunt.reduced_motion = value
		if is_instance_valid(park_lap): park_lap.reduced_motion = value
var _world: Node3D
var _skater: CharacterBody3D
var _last_position := Vector3.INF
var _built := false

func configure(world: Node3D, skater: CharacterBody3D) -> void:
	if _built or not is_instance_valid(world) or not is_instance_valid(skater): return
	_built = true
	_world = world
	_skater = skater
	process_mode = Node.PROCESS_MODE_PAUSABLE
	gate = Gate.new()
	gate.name = "ServiceShortcut"
	add_child(gate)
	var service_points := PackedVector3Array([_ground(Vector3(-48.5,2,-18)), _ground(Vector3(-48.5,2,-2)), _ground(Vector3(-48.5,2,12))])
	gate.configure(service_points[1], service_points, 2.3)
	gate.changed.connect(func(): routes_changed.emit())
	cone_stunt = Cone.new()
	cone_stunt.name = "ConeOnACruise"
	add_child(cone_stunt)
	cone_stunt.configure(_ground(Vector3(-5,2,66)), _ground(Vector3(-5,2,74)), Vector3(-5,1.2,80), Vector3(-5,-1.9,82))
	cone_stunt.feedback.connect(func(text: String): feedback.emit(text))
	park_lap = Lap.new()
	park_lap.name = "OneMoreLap"
	add_child(park_lap)
	var scenic := _ground_points(PackedVector3Array([
		Vector3(-164,6,-88), Vector3(-195,9,-106), Vector3(-208,11,-126),
		Vector3(-181,15,-164), Vector3(-145,11,-146), Vector3(-145,6,-104)]))
	var bank_cut := _ground_points(PackedVector3Array([
		Vector3(-148,6,-92), Vector3(-156,8,-112), Vector3(-179,12,-136),
		Vector3(-195,9,-106), Vector3(-164,6,-88)]))
	park_lap.configure(_ground(Vector3(-155,6,-82)), [
		{"id":"park_full_loop", "label":"Full park loop", "points":scenic},
		{"id":"park_bank_cut", "label":"Grass-bank cut", "points":bank_cut}], Rect2(-225,-190,90,125))
	park_lap.feedback.connect(func(text: String): feedback.emit(text))
	vehicle = Vehicle.new()
	vehicle.name = "QuayCrewElectricCart"
	add_child(vehicle)
	vehicle.configure(_ground_points(PackedVector3Array([Vector3(-78,2,70.5),Vector3(-28,2,70.5)])))
	reduced_motion = reduced_motion

func challenges() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if is_instance_valid(cone_stunt): result.append(cone_stunt)
	if is_instance_valid(park_lap): result.append(park_lap)
	return result

func poll(at: Vector3, interact: bool, delta: float, combo_value: int = 0,
		_audience_visible: bool = false, selected_id: String = "") -> void:
	if not _built or not at.is_finite(): return
	_last_position = at
	gate.tick(delta)
	var chosen := selected_id
	if interact and chosen.is_empty(): chosen = nearby_id(at)
	if interact and chosen == "service_gate":
		if gate.request_toggle():
			feedback.emit("SERVICE CUT-THROUGH · " + ("OPENING" if gate.requested_open else "CLOSING"))
		else:
			feedback.emit("GATE SENSOR · Clear the doorway before closing.")
	if interact and chosen == "cone_on_a_cruise" and combo_value == 0 and cone_stunt.status_snapshot().state != "active":
		park_lap.cancel_attempt()
	if interact and chosen == "one_more_lap" and combo_value == 0 and park_lap.status_snapshot().state != "active":
		cone_stunt.cancel_attempt()
	cone_stunt.poll(at, interact and chosen == "cone_on_a_cruise", delta, combo_value, _skater)
	park_lap.poll(at, interact and chosen == "one_more_lap", delta, combo_value)

func nearby_id(at: Vector3) -> String:
	var closest := INF
	var chosen := ""
	for challenge: Node3D in challenges():
		if challenge.nearby_prompt(at).is_empty(): continue
		var snapshot: Dictionary = challenge.status_snapshot()
		var target: Vector3 = snapshot.launch if str(snapshot.id) == "cone_on_a_cruise" and snapshot.state == "active" else snapshot.position
		var distance := at.distance_squared_to(target)
		if distance < closest:
			closest = distance
			chosen = str(snapshot.id)
	if is_instance_valid(gate) and _near_gate(at):
		var distance := at.distance_squared_to(gate.global_position)
		if distance < closest: chosen = "service_gate"
	return chosen

func nearby_prompt(at: Vector3) -> String:
	match nearby_id(at):
		"service_gate": return "CLOSE SERVICE CUT-THROUGH" if gate.requested_open else "OPEN SERVICE CUT-THROUGH"
		"cone_on_a_cruise": return cone_stunt.nearby_prompt(at)
		"one_more_lap": return park_lap.nearby_prompt(at)
	return ""

func gate_prompt(at: Vector3) -> String:
	if not _near_gate(at): return ""
	return "CLOSE SERVICE CUT-THROUGH" if gate.requested_open else "OPEN SERVICE CUT-THROUGH"

func _near_gate(at: Vector3) -> bool:
	return is_instance_valid(gate) and at.is_finite() and absf(at.y-gate.global_position.y)<1.6 \
		and Vector2(at.x-gate.global_position.x,at.z-gate.global_position.z).length()<3.2

func on_trick(_name: String, points: int, at: Vector3, identity: String = "") -> void:
	if points > 0 and str(Catalog.definition(identity).get("family", "")) == "launch":
		park_lap.on_launch(at)

func on_landed(clean: bool) -> void:
	if not _built: return
	park_lap.on_landed(clean)
	cone_stunt.on_landed(clean)

func on_bank(points: int, at: Vector3) -> void:
	if _built: cone_stunt.on_bank(points, at)

func on_bail() -> void:
	for challenge: Node3D in challenges(): challenge.on_bail()

func cancel_attempt() -> void:
	for challenge: Node3D in challenges(): challenge.cancel_attempt()

func finish_run() -> void:
	for challenge: Node3D in challenges(): challenge.finish_run()
	if is_instance_valid(vehicle): vehicle.stop_run()

func reset_run() -> void:
	for challenge: Node3D in challenges(): challenge.reset_run()
	if is_instance_valid(gate): gate.reset_run()
	if is_instance_valid(vehicle):
		vehicle.reset_run()
		vehicle.set_physics_process(true)

func get_route_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if is_instance_valid(gate): result.append(gate.route_definition())
	return result

func status_snapshot() -> Dictionary:
	for challenge: Node3D in challenges():
		var snapshot: Dictionary = challenge.status_snapshot()
		if snapshot.state == "active": return snapshot
	var chosen := nearby_id(_last_position)
	if chosen == "cone_on_a_cruise": return cone_stunt.status_snapshot()
	if chosen == "one_more_lap": return park_lap.status_snapshot()
	return {"id":"service_gate", "state":"idle", "position":gate.global_position if is_instance_valid(gate) else Vector3.INF,
		"payoff_position":Vector3.INF, "hud_text":"", "gate":gate.status_snapshot() if is_instance_valid(gate) else {}}

func definitions_snapshot() -> Dictionary:
	return {"service_gate":gate.status_snapshot(), "service_route":gate.route_definition(),
		"cone":cone_stunt.status_snapshot(), "lap":park_lap.status_snapshot(), "vehicle":vehicle.status_snapshot()}

func _ground(at: Vector3) -> Vector3:
	var result := at
	if is_instance_valid(_world) and _world.has_method("get_ground_height"):
		var height: float = _world.get_ground_height(at)
		if is_finite(height): result.y = height
	return result

func _ground_points(points: PackedVector3Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	for at: Vector3 in points: result.append(_ground(at))
	return result
