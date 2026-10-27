extends "res://game/player/skater.gd"
const TraceVisual=preload("res://.local/foot_sign_trace_visual.gd")
var trace_mode := "baseline"
var signed_pose_speed := 0.0
func _update_pose(delta: float) -> void:
	signed_pose_speed=speed
	_visual_rig.reported_speed=speed
	super._update_pose(delta)
func _build_skater() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.7
	var collision := CollisionShape3D.new()
	_body_collision = collision
	collision.name = "BodyCollision"
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)
	_visual = Node3D.new()
	_visual.name = "SkaterVisual"
	add_child(_visual)
	_board_visual = Node3D.new()
	_board_visual.name = "Board"
	_board_visual.position.y = 0.12
	_visual.add_child(_board_visual)
	_rider_visual = Node3D.new()
	_rider_visual.name = "Rider"
	_visual.add_child(_rider_visual)

	_shirt_material = _material(_shirt_color, 0.94)
	_visual_rig = TraceVisual.new()
	_visual_rig.mode = trace_mode
	_visual_rig.build(_board_visual, _rider_visual, _shirt_material)
	_build_loose_board()

