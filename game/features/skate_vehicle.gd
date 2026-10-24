extends CharacterBody3D
## One original electric parks-service cart on an optional quay lane. Native
## obstruction checks stop it before a person or obstacle; no traffic simulation.

const Art = preload("res://game/features/feature_visuals.gd")
const CRUISE_SPEED := 6.0
var speed := 0.0
var travel_velocity := Vector3.ZERO
var stopped := true
var _ends: PackedVector3Array = []
var _target := 1
var _wait := 0.0
var _start := Vector3.ZERO
var _built := false
var _collision_shape: BoxShape3D

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
	Art.sign(self, Vector3(0, 2.0, 0), "QUAY CREW\nOPTIONAL TOW", Color("dfdfc0"))
	_align()

func _box_collision(label: String, at: Vector3, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	collision.name = label
	collision.position = at
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	if not _built or not is_finite(delta) or delta <= 0.0: return
	var offset := _ends[_target] - global_position
	offset.y = 0.0
	if offset.length() < 0.30:
		_wait = 1.8
		_target = 1 - _target
		stopped = true
	if _wait > 0.0:
		_wait = maxf(0.0, _wait - delta)
		speed = 0.0
		travel_velocity = Vector3.ZERO
		velocity = Vector3.DOWN * 0.5
		move_and_slide()
		if _wait == 0.0: _align()
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
		velocity = Vector3.DOWN * 0.5
	else:
		stopped = false
		speed = intended.length()
		travel_velocity = intended
		velocity = intended + Vector3.DOWN * 0.5
	move_and_slide()
	var measured := get_real_velocity()
	var actual := Vector3(measured.x, 0, measured.z)
	if actual.length() < speed * 0.5:
		stopped = true
	speed = actual.length()
	travel_velocity = actual

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
	var direction := _ends[_target] - global_position
	rotation.y = atan2(-direction.x, -direction.z)

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
	speed = 0.0
	travel_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	stopped = true
	_align()

func stop_run() -> void:
	speed = 0.0
	travel_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	stopped = true
	set_physics_process(false)

func status_snapshot() -> Dictionary:
	return {"position": global_position, "speed": speed, "stopped": stopped,
		"anchor": get_skitch_anchor(), "path": _ends.duplicate()}
