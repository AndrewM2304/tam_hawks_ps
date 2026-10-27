extends "res://game/player/skater.gd"
const Candidate=preload("res://.local/manual_arm_candidate_anchored.gd")
func _ready() -> void:
	_obstacle_arm_fit=Candidate.new()
	super._ready()
