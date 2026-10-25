extends Node3D
## Reversible native moving collision. The whole doorway is checked before and
## throughout closing; a skater cannot be crushed by a late sensor entry.

const Art = preload("res://game/features/feature_visuals.gd")
signal changed()
var progress := 0.0
var requested_open := false
var blocked := false
var _panel: AnimatableBody3D
var _shape: BoxShape3D
var _sensor: BoxShape3D
var _closed := Vector3.ZERO
var _opening_height := 3.6
var _route: PackedVector3Array = []
var _built := false

func configure(at: Vector3, route: PackedVector3Array, width: float = 2.3) -> void:
	if _built: return
	_built = true
	global_position = at
	_route = route.duplicate()
	_panel = AnimatableBody3D.new()
	_panel.name = "SlidingServiceGate"
	_panel.sync_to_physics = false
	_panel.collision_layer = 1
	_panel.collision_mask = 0
	_panel.set_meta("no_wallride", true)
	_panel.set_meta("wallride_exclusion_reason", "moving service shutter")
	add_child(_panel)
	_closed = Vector3(0, 1.4, 0)
	_panel.position = _closed
	_shape = BoxShape3D.new()
	_shape.size = Vector3(width, 2.8, 0.18)
	var collision := CollisionShape3D.new()
	collision.shape = _shape
	_panel.add_child(collision)
	Art.box(_panel, "SteelGate", Vector3.ZERO, _shape.size, Color("4d6468"))
	for height: float in [-1.12, -0.56, 0.0, 0.56, 1.12]:
		Art.box(_panel, "ShutterRib", Vector3(0, height, -0.11), Vector3(width, 0.045, 0.06), Color("a6b1ac"))
	_sensor = BoxShape3D.new()
	_sensor.size = Vector3(width + 0.72, 3.4, 1.5)
	# One compact, depth-tested sign reads from either approach without covering
	# the passage. Live mapped interaction wording belongs to the ordinary HUD.
	var sign := Art.sign(self, Vector3(0, 3.05, -0.3), "NORTH STREET ↔ SOUTH STREET\nSERVICE SHORTCUT")
	sign.font_size = 32
	sign.pixel_size = 0.004
	sign.outline_size = 6
	Art.box(self, "SwitchBox", Vector3(-1.18, 1.0, -0.45), Vector3(0.16, 0.24, 0.12), Color("c5944e"))

func request_toggle() -> bool:
	if not _built: return false
	if requested_open or progress > 0.99:
		blocked = _occupied()
		if blocked: return false
		requested_open = false
	else:
		requested_open = true
	blocked = false
	changed.emit()
	return true

func tick(delta: float) -> void:
	if not _built or not is_finite(delta) or delta <= 0.0: return
	var next := move_toward(progress, 1.0 if requested_open else 0.0, delta / 1.25)
	blocked = next < progress and _occupied()
	if blocked: return
	var was_open := progress >= 0.99
	progress = next
	_panel.position = _closed + Vector3.UP * _opening_height * progress
	if was_open != (progress >= 0.99): changed.emit()

func _occupied() -> bool:
	if not is_inside_tree(): return true
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _sensor
	query.transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.5, 0))
	query.collision_mask = 2
	query.collide_with_areas = false
	query.exclude = [_panel.get_rid()]
	return not get_world_3d().direct_space_state.intersect_shape(query, 8).is_empty()

func reset_run() -> void:
	requested_open = false
	blocked = false
	progress = 0.0
	if is_instance_valid(_panel): _panel.position = _closed
	changed.emit()

func status_snapshot() -> Dictionary:
	return {"open": progress >= 0.99, "requested_open": requested_open, "progress": progress,
		"blocked": blocked, "position": global_position, "collision_position": _panel.global_position if is_instance_valid(_panel) else Vector3.INF}

func route_definition() -> Dictionary:
	return {"id": "service_gate_shortcut", "label": "Service cut-through · " + ("OPEN" if progress >= 0.99 else "CLOSED"),
		"points": _route.duplicate(), "requires_jump": false, "enabled": progress >= 0.99,
		"destinations": PackedStringArray(["North station street", "South station street"])}

func action_prompt() -> String:
	return ("CLOSE" if requested_open else "OPEN") + " SHORTCUT · NORTH ↔ SOUTH STATION"
