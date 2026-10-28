extends "res://game/player/skater.gd"
func _grind_capture_path_clear(line,from:Vector3,to:Vector3,distance:float,direction:float,motion:Vector3)->bool:
	var result:bool=super._grind_capture_path_clear(line,from,to,distance,direction,motion)
	print("INTENT_PATH ",{"tick":Engine.get_physics_frames(),"from":from,"to":to,"rise":to.y-from.y,"motion":motion,"clear":result,"radius":_grind.body_radius,"base":_grind.body_base_offset})
	return result
func _grind_capsule_segment_clear(from:Vector3,to:Vector3,line)->bool:
	var result:bool=super._grind_capsule_segment_clear(from,to,line)
	print("INTENT_SEGMENT ",{"from":from,"to":to,"clear":result})
	return result
func _grind_capsule_rest_clear(at:Vector3,line)->bool:
	var result:bool=super._grind_capsule_rest_clear(at,line)
	print("INTENT_REST ",{"at":at,"clear":result,"count":_grind_capsule_rest.get_collision_count(),"depth":_grind_capsule_rest.get_depth() if _grind_capsule_rest.get_collision_count()>0 else 0.0,"travel":_grind_capsule_rest.get_travel() if _grind_capsule_rest.get_collision_count()>0 else Vector3.ZERO})
	return result
func _grind_candidate_supported(line,distance:float,direction:float)->bool:
	var result:bool=super._grind_candidate_supported(line,distance,direction)
	print("INTENT_MODEL ",{"clear":result,"valid":_grind_candidate_contact.valid,"reason":_grind_clearance.last_rejection,"obstruction":_grind_clearance.last_obstruction})
	return result
