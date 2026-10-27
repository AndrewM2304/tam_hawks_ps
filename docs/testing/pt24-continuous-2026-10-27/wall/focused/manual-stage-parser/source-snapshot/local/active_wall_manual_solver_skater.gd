extends "res://game/player/skater.gd"
## Read-only diagnosis; no proposed correction is applied here.
var diagnostic_rows: Array[Dictionary]=[]
func _obstacle_manual_contact_offset(geometry: Dictionary) -> Vector3:
	var proposed:=super._obstacle_manual_contact_offset(geometry)
	if not manual_active or global_position.z< -0.56:return proposed
	var q: PhysicsShapeQueryParameters3D=_grind_board_query
	var shape:=q.shape;var margin:=q.margin;var frame:=q.transform;var motion:=q.motion;var excluded:=q.exclude
	q.shape=geometry.convex_shape;q.transform=_board_visual.global_transform;q.motion=Vector3.ZERO
	var space:=get_world_3d().direct_space_state
	q.margin=GROUND_PRESENTATION_SKIN-0.00001
	var current:=space.get_rest_info(q)
	q.margin=0.0
	var zero:=space.get_rest_info(q)
	q.margin=GROUND_PRESENTATION_SKIN-0.00001
	var omitted: Array[RID]=[];omitted.assign(excluded)
	if _native_platform_floor.is_valid():omitted.append(_native_platform_floor)
	q.exclude=omitted
	var without_floor:=space.get_rest_info(q)
	q.shape=shape;q.margin=margin;q.transform=frame;q.motion=motion;q.exclude=excluded
	diagnostic_rows.append({"at":global_position,"manual":manual_active,"pitch":_board_visual.rotation.x,
		"proposed":proposed,"floor_rid":_native_platform_floor,"skin_rest":_rest(current),"zero_rest":_rest(zero),
		"skin_without_native_floor":_rest(without_floor),"restored":q.shape==shape and q.margin==margin and q.transform==frame and q.motion==motion and q.exclude==excluded})
	return proposed
func _obstacle_manual_supported(geometry: Dictionary,offset: Vector3) -> bool:
	var valid:=super._obstacle_manual_supported(geometry,offset)
	if manual_active and global_position.z> -0.56:diagnostic_rows.append({"at":global_position,"candidate":offset,"supported":valid})
	return valid
func _rest(info: Dictionary) -> Dictionary:
	return {} if info.is_empty() else {"rid":info.get("rid"),"normal":info.get("normal"),"point":info.get("point"),"collider":info.get("collider_id")}
