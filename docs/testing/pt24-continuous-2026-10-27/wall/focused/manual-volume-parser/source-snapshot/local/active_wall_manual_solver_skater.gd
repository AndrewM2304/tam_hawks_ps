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
	if manual_active and global_position.z> -0.56:
		var q: PhysicsShapeQueryParameters3D=_grind_board_query
		var shape:=q.shape;var margin:=q.margin;var frame:=q.transform;var motion:=q.motion
		var size:=_grind_board_box.size
		var space:=get_world_3d().direct_space_state
		var volumes: Array[Dictionary]=[]
		for index: int in 3:
			var points: PackedVector3Array=PackedVector3Array()
			if index==0:
				q.shape=geometry.convex_shape;q.transform=_board_visual.global_transform
				points=geometry.support_points
			else:
				var bounds: AABB=_obstacle_shoe_bounds[index-1]
				_grind_board_box.size=bounds.size;q.shape=_grind_board_box
				q.transform=_visual_rig._legs[index-1].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
				for corner: int in 8:points.append(bounds.get_endpoint(corner))
			var pose:=q.transform;pose.origin+=offset;q.transform=pose
			q.margin=GROUND_PRESENTATION_SKIN-0.00001;q.motion=Vector3.ZERO
			var hits:=space.intersect_shape(q,8)
			var native: Array[Dictionary]=[]
			for hit: Dictionary in hits:
				var node: Object=hit.get("collider")
				native.append({"rid":hit.get("rid"),"name":node.name if node is Node else str(node),"shape_index":hit.get("shape")})
			var rest:=space.get_rest_info(q)
			var pairs:=space.collide_shape(q,8)
			var floor_gap:=INF;var wall_gap:=INF
			var actual_frame: Transform3D=_board_visual.global_transform if index==0 else _visual_rig._legs[index-1].foot.global_transform
			for vertex: Vector3 in points:
				var world:=actual_frame*vertex+offset
				floor_gap=minf(floor_gap,world.y);wall_gap=minf(wall_gap,-0.09-world.z)
			volumes.append({"shape":index,"shape_class":q.shape.get_class(),"hits":native,"rest":_rest(rest),"contact_pairs":pairs,
				"cached_envelope_floor_gap":floor_gap,"cached_envelope_wall_gap":wall_gap})
		q.shape=shape;q.margin=margin;q.transform=frame;q.motion=motion;_grind_board_box.size=size
		diagnostic_rows.append({"at":global_position,"candidate":offset,"supported":valid,"volumes":volumes,
			"restored":q.shape==shape and q.margin==margin and q.transform==frame and q.motion==motion and _grind_board_box.size==size})
	return valid
func _rest(info: Dictionary) -> Dictionary:
	return {} if info.is_empty() else {"rid":info.get("rid"),"normal":info.get("normal"),"point":info.get("point"),"collider":info.get("collider_id")}
