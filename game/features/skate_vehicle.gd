extends CharacterBody3D
## One original electric parks-service cart on an optional quay lane. Native
## obstruction checks stop it before a person or obstacle; no traffic simulation.

const Art = preload("res://game/features/feature_visuals.gd")
const CRUISE_SPEED := 6.0
const TURN_RATE := PI / 3.0
const TURN_PROBE_STEP := PI / 720.0
var speed := 0.0
var travel_velocity := Vector3.ZERO
var stopped := true
var _ends: PackedVector3Array = []
var _target := 1
var _wait := 0.0
var _start := Vector3.ZERO
var _built := false
var _collision_shape: BoxShape3D
var _body_shapes: Array[CollisionShape3D] = []
var _turning := false
var _turn_target_yaw := 0.0
var _turn_blocked := ""
var _phase := "cruise"
var _sign: Label3D

func configure(points: PackedVector3Array) -> void:
	if _built or points.size() != 2 or not points[0].is_finite() or not points[1].is_finite() \
		or points[0].distance_to(points[1]) < 12.0: return
	_built = true
	_ends = points.duplicate()
	_start = points[0]
	global_position = _start
	process_physics_priority = -10
	collision_layer = 8
	# Native world movement must not mutually block a CharacterBody riding the
	# roof. Floor-level people use the explicit native safety volume below.
	collision_mask = 1
	floor_snap_length = 0.35
	safe_margin = 0.015
	add_to_group("skate_vehicles")
	set_meta("no_wallride", true)
	_collision_shape = BoxShape3D.new()
	_collision_shape.size = Vector3(1.71,1.60,3.10)
	_box_collision("ChassisCollision",Vector3(0,0.65,0),Vector3(1.48,0.62,3.10))
	_box_collision("CabCollision",Vector3(0,1.22,-0.55),Vector3(1.30,0.70,1.20))
	Art.box(self, "ServiceCartBody", Vector3(0, 0.65, 0.0), Vector3(1.48, 0.62, 3.1), Color("587468"))
	Art.box(self, "Cab", Vector3(0, 1.22, -0.55), Vector3(1.30, 0.70, 1.20), Color("83978d"))
	Art.box(self, "Windscreen", Vector3(0, 1.30, -1.17), Vector3(1.12, 0.40, 0.035), Color("243d43"))
	Art.box(self, "RearCatchBar", Vector3(0, 0.93, 1.69), Vector3(1.12, 0.08, 0.10), Color("d6cba8"))
	for x: float in [-0.78, 0.78]:
		for z: float in [-1.0, 1.0]:
			var wheel := Art.cylinder(self, "Wheel", Vector3(x, 0.31, z), 0.30, 0.15, Color("26302d"))
			wheel.rotation.z = PI * 0.5
			var shape := CylinderShape3D.new()
			shape.radius = 0.30
			shape.height = 0.15
			var collision := CollisionShape3D.new()
			collision.name = "WheelCollision"
			collision.position = wheel.position
			collision.rotation = wheel.rotation
			collision.shape = shape
			add_child(collision)
			_body_shapes.append(collision)
	_sign = Art.sign(self, Vector3(0, 2.0, 0), "QUAY CREW\nOPTIONAL TOW", Color("dfdfc0"))
	_align()

func _box_collision(label: String, at: Vector3, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	collision.name = label
	collision.position = at
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)
	_body_shapes.append(collision)

func _physics_process(delta: float) -> void:
	if not _built or not is_finite(delta) or delta <= 0.0: return
	# Native floor snap owns grounded support. A constant downward move would
	# alternate wheel recovery and travel by 8.3 mm on a perfectly flat lane.
	var vertical := 0.0 if is_on_floor() else -0.5
	if _wait > 0.0:
		_wait = maxf(0.0, _wait - delta)
		_park(vertical)
		_set_phase("rest", "RESTING")
		return
	if _turning:
		_park(vertical)
		_turn_parked(delta)
		return
	var offset := _ends[_target] - global_position
	offset.y = 0.0
	if offset.length() < 0.30:
		_wait = 1.8
		_target = 1 - _target
		_turning = true
		_turn_target_yaw = _heading_to_target()
		_turn_blocked = ""
		_park(vertical)
		_set_phase("rest", "RESTING")
		return
	var direction := offset.normalized()
	var intended := direction * minf(CRUISE_SPEED, speed + 3.0 * delta)
	var collision := KinematicCollision3D.new()
	var reach := 0.55 + intended.length() * delta
	var obstructed := test_move(global_transform, direction * reach, collision, safe_margin, false)
	if (obstructed and absf(collision.get_normal().y) < 0.65) or _pedestrian_ahead(direction, reach):
		speed = 0.0
		stopped = true
		travel_velocity = Vector3.ZERO
		velocity = Vector3.UP * vertical
		_set_phase("obstructed", "WAITING FOR SPACE")
	else:
		stopped = false
		speed = intended.length()
		travel_velocity = intended
		velocity = intended + Vector3.UP * vertical
		_set_phase("cruise", "OPTIONAL TOW")
	move_and_slide()
	var measured := get_real_velocity()
	var actual := Vector3(measured.x, 0, measured.z)
	if actual.length() < speed * 0.5:
		stopped = true
	speed = actual.length()
	travel_velocity = actual

func _park(vertical: float) -> void:
	speed = 0.0
	stopped = true
	travel_velocity = Vector3.ZERO
	velocity = Vector3.UP * vertical
	move_and_slide()

func _turn_parked(delta: float) -> void:
	# Native angular support cannot safely carry a person between the separate
	# cab and bed roofs. Keep both roofs still until that person steps clear.
	if _roof_occupied():
		_turn_blocked = "rider"
		_set_phase("waiting_rider", "PLEASE STEP OFF")
		return
	var remaining := angle_difference(rotation.y, _turn_target_yaw)
	var amount := clampf(remaining, -minf(TURN_RATE * delta, PI / 120.0), minf(TURN_RATE * delta, PI / 120.0))
	if not _turn_clear(amount):
		_turn_blocked = "space"
		_set_phase("waiting_space", "WAITING FOR SPACE")
		return
	_turn_blocked = ""
	rotation.y += amount
	_set_phase("turning", "TURNING - STAND CLEAR")
	if absf(angle_difference(rotation.y, _turn_target_yaw)) < 0.0001:
		_turning = false

func _turn_clear(amount: float) -> bool:
	# Check the actual six native shapes through the angular sweep, including
	# people (layer 2). The 0.25-degree samples plus 6 mm query margin cover the
	# largest corner's arc between samples. Raising only the query by that same
	# margin includes the real shape while preserving native wheel-floor skin.
	var samples := maxi(1, ceili(absf(amount) / TURN_PROBE_STEP))
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = 1 | 2
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	query.margin = 0.006
	for sample in range(1, samples + 1):
		var candidate := global_transform * Transform3D(Basis(Vector3.UP, amount * float(sample) / samples), Vector3.ZERO)
		for collision: CollisionShape3D in _body_shapes:
			query.shape = collision.shape
			query.transform = candidate * collision.transform
			query.transform.origin += Vector3.UP * query.margin
			if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(): return false
	return true

func _roof_occupied() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = 2
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	# These thin native sensing slabs cover the two real roof footprints.
	for roof: Vector4 in [Vector4(0, 1.57, -0.55, 1.20), Vector4(0, 0.96, 0, 3.10)]:
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.30 if roof.y > 1.0 else 1.48, 0.24, roof.w)
		query.shape = shape
		query.transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(roof.x, roof.y + 0.10, roof.z))
		for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 16):
			var body: Object = hit.collider
			if body is CharacterBody3D:
				var feet := to_local(body.global_position)
				if feet.y >= roof.y - 0.06 and feet.y <= roof.y + 0.25: return true
	return false

func _set_phase(phase: String, caption: String) -> void:
	if _phase == phase: return
	_phase = phase
	if is_instance_valid(_sign): _sign.text = "QUAY CREW\n" + caption

func _pedestrian_ahead(direction: Vector3, reach: float) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collision_shape
	query.transform = global_transform * Transform3D(Basis.IDENTITY,Vector3(0,0.80,0))
	query.transform.origin += direction*reach
	query.collision_mask = 2
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query,16):
		var body: Object = hit.collider
		if body is CharacterBody3D:
			var foot := to_local(body.global_position)
			var on_cab := absf(foot.x)<=0.67 and foot.z>=-1.17 and foot.z<=0.07
			var on_bed := absf(foot.x)<=0.76 and absf(foot.z)<=1.57
			var roof := 1.57 if on_cab else 0.96
			if not on_bed or foot.y < roof-0.06: return true
	return false

func _align() -> void:
	rotation.y = _heading_to_target()

func _heading_to_target() -> float:
	var direction := _ends[_target] - global_position
	return atan2(-direction.x, -direction.z)

func get_skitch_anchor() -> Vector3:
	return to_global(Vector3(0, 0, 2.25))

func get_skitch_hand_targets() -> Array[Vector3]:
	return [to_global(Vector3(-0.40,0.93,1.745)),to_global(Vector3(0.40,0.93,1.745))]

func get_skitch_surface_normal() -> Vector3:
	return global_basis.z.normalized()

func reset_run() -> void:
	if not _built: return
	global_position = _start
	_target = 1
	_wait = 0.0
	_turning = false
	_turn_blocked = ""
	speed = 0.0
	travel_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	stopped = true
	_align()
	_turn_target_yaw = rotation.y
	_set_phase("cruise", "OPTIONAL TOW")

func stop_run() -> void:
	_wait = 0.0
	_turning = false
	_turn_blocked = ""
	speed = 0.0
	travel_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	stopped = true
	_set_phase("finished", "OFF DUTY")
	set_physics_process(false)

func status_snapshot() -> Dictionary:
	return {"position": global_position, "speed": speed, "stopped": stopped,
		"anchor": get_skitch_anchor(), "path": _ends.duplicate(), "phase": _phase,
		"turning": _turning, "turn_blocked": _turn_blocked, "wait": _wait}
