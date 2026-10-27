extends "res://game/player/skater.gd"
const Candidate = preload("res://.local/active_wall_arm_candidate.gd")
var _arm_candidate: RefCounted
var _arm_query_restored:=true
func _ready() -> void:
	super._ready()
	_arm_candidate=Candidate.new()
	_arm_candidate.prepare(self)
func _update_pose(delta: float) -> void:
	super._update_pose(delta)
	if _arm_candidate!=null:
		var q:=_grind_board_query
		var ray:=_recovery_floor_query
		var before: Dictionary={"shape":q.shape,"margin":q.margin,"transform":q.transform,"motion":q.motion,
			"size":_grind_board_box.size,"mask":q.collision_mask,"exclude":q.exclude.duplicate(),
			"bodies":q.collide_with_bodies,"areas":q.collide_with_areas,
			"from":ray.from,"to":ray.to,"raymask":ray.collision_mask,"rayexclude":ray.exclude.duplicate(),
			"raybodies":ray.collide_with_bodies,"rayareas":ray.collide_with_areas,
			"rayback":ray.hit_back_faces,"rayinside":ray.hit_from_inside}
		_arm_candidate.apply(delta)
		var after: Dictionary={"shape":q.shape,"margin":q.margin,"transform":q.transform,"motion":q.motion,
			"size":_grind_board_box.size,"mask":q.collision_mask,"exclude":q.exclude.duplicate(),
			"bodies":q.collide_with_bodies,"areas":q.collide_with_areas,
			"from":ray.from,"to":ray.to,"raymask":ray.collision_mask,"rayexclude":ray.exclude.duplicate(),
			"raybodies":ray.collide_with_bodies,"rayareas":ray.collide_with_areas,
			"rayback":ray.hit_back_faces,"rayinside":ray.hit_from_inside}
		_arm_query_restored=_arm_query_restored and before==after
func arm_candidate_report() -> Dictionary:
	if _arm_candidate==null:return {}
	return {"query_restored":_arm_query_restored,"accepted":_arm_candidate.accepted,"refused":_arm_candidate.refused,
		"continuing":_arm_candidate.continuing,"calls":_arm_candidate.calls,
		"maximum_calls":_arm_candidate.maximum_calls,"maximum_shift":_arm_candidate.maximum_shift,
		"rows":[_arm_candidate.arms[0].rows.size(),_arm_candidate.arms[1].rows.size()]}
