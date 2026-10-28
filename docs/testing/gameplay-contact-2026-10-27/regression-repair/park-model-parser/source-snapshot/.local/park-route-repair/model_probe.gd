extends SceneTree
const Main=preload("res://game/main.gd")
const Style=preload("res://game/tricks/grind_style.gd")
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	var rider:CharacterBody3D=game.skater;rider.set_physics_process(false);rider.set_process(false)
	await physics_frame;await process_frame
	var line
	for candidate in game.world.get_grind_lines():
		if candidate.id=="Grind_Ledge_park_east_lower":line=candidate;break
	if line==null:quit(2);return
	var native:StaticBody3D=game.world.get_node("Grind_Ledge_park_east_lower/NativeGrindBearing")
	var collision:CollisionShape3D=native.get_child(0)
	var shape:CylinderShape3D=collision.shape
	var pose:=Style.ContactPose.new()
	for offset:float in [0.0,.0561287105,.255,.27,.51,1.0,4.0]:
		var solved:bool=rider._solve_grind_contact(pose,line,offset,1.0,0.0,"grind_50_50",0.0)
		var static_clear:bool=solved and rider._grind_clearance.allows(pose,line.contact_up(offset))
		var static_reason:String=rider._grind_clearance.last_rejection
		var path_clear:bool=solved and rider._grind_clearance.allows_frame_path(pose.board_transform,pose.board_transform,line.contact_up(offset))
		var part_hits:Array=[]
		var index:=0
		var min_vertex_margin:=INF
		for part:Dictionary in rider._grind_clearance._parts:
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=part.shape;query.transform=pose.board_transform
			query.transform.origin+=line.contact_up(offset)*Style.CONTACT_TOLERANCE
			query.collision_mask=1|2|8;query.exclude=[rider.get_rid()];query.margin=0.0
			var hits:Array=rider.get_world_3d().direct_space_state.intersect_shape(query,16)
			for hit:Dictionary in hits:
				if hit.collider!=native:continue
				var inside_vertices:=0
				var worst:=0.0
				var worst_at:=Vector3.ZERO
				var transform:Transform3D=collision.global_transform.affine_inverse()*query.transform
				for vertex:Vector3 in part.points:
					var local:Vector3=transform*vertex
					var radial:=Vector2(local.x,local.z).length()
					var margin:=maxf(radial-shape.radius,absf(local.y)-shape.height*.5)
					min_vertex_margin=minf(min_vertex_margin,margin)
					if margin< -Style.CONTACT_TOLERANCE:
						inside_vertices+=1
						if margin<worst:worst=margin;worst_at=local
				part_hits.append({"part":index,"points":part.points.size(),"native_shape":hit.shape,"inside_vertices":inside_vertices,"worst_vertex_margin":worst,"worst_at":worst_at})
			index+=1
		var actual:=_triangles(rider,pose.board_transform,line.contact_up(offset),collision)
		print("PARK_MODEL_STATIC ",JSON.stringify({"offset":offset,"solved":solved,"origin":pose.board_transform.origin,"anchors":pose.supports,"support_error":pose.max_error,"static_clear":static_clear,"static_reason":static_reason,"path_same_clear":path_clear,"path_reason":rider._grind_clearance.last_rejection,"part_hits":part_hits,"minimum_actual_vertex_margin":min_vertex_margin,"actual_triangle_penetrations":actual}))
	game.queue_free();await process_frame;print("RESULT: 1 passed, 0 failed");quit(0)
func _triangles(rider:CharacterBody3D,pose:Transform3D,up:Vector3,collision:CollisionShape3D)->Dictionary:
	var geometry:Dictionary=rider._visual_rig.board_contact_geometry()
	var original_inverse:Transform3D=rider._board_visual.global_transform.affine_inverse()
	var cylinder:CylinderShape3D=collision.shape
	var firsts:Array=[];var count:=0;var worst:=INF
	var lift:=Transform3D(Basis.IDENTITY,up*Style.CONTACT_TOLERANCE)
	for mesh:MeshInstance3D in geometry.meshes:
		var frame:Transform3D=collision.global_transform.affine_inverse()*lift*pose*original_inverse*mesh.global_transform
		var faces:PackedVector3Array=mesh.mesh.get_faces()
		for index:int in range(0,faces.size(),3):
			var polygon:Array[Vector3]=[frame*faces[index],frame*faces[index+1],frame*faces[index+2]]
			polygon=_clip(polygon,cylinder.height*.5-Style.CONTACT_TOLERANCE,1.0)
			polygon=_clip(polygon,cylinder.height*.5-Style.CONTACT_TOLERANCE,-1.0)
			if polygon.is_empty():continue
			var radial:=INF
			var projected:=PackedVector2Array()
			for point:Vector3 in polygon:projected.append(Vector2(point.x,point.z))
			for edge:int in projected.size():
				radial=minf(radial,Geometry2D.get_closest_point_to_segment(Vector2.ZERO,projected[edge],projected[(edge+1)%projected.size()]).length())
			if projected.size()>=3 and Geometry2D.is_point_in_polygon(Vector2.ZERO,projected):radial=0.0
			var margin:=radial-cylinder.radius
			worst=minf(worst,margin)
			if margin< -Style.CONTACT_TOLERANCE:
				count+=1
				if firsts.size()<4:firsts.append({"mesh":str(mesh.get_path()),"face":index/3,"radial_margin":margin,"native_triangle":polygon})
	return {"count":count,"minimum_radial_margin":worst,"firsts":firsts,"method":"Each actual rendered triangle clipped inside both finite cylinder end planes by100micrometres, then exact projected radial segment/polygon distance to native axis; threshold original100micrometre contact tolerance."}
func _clip(polygon:Array[Vector3],half:float,sign_value:float)->Array[Vector3]:
	var out:Array[Vector3]=[]
	if polygon.is_empty():return out
	var previous:Vector3=polygon[-1]
	var previous_inside:=previous.y*sign_value<=half
	for point:Vector3 in polygon:
		var inside:=point.y*sign_value<=half
		if inside!=previous_inside:
			var t:float=(half*sign_value-previous.y)/(point.y-previous.y)
			out.append(previous.lerp(point,t))
		if inside:out.append(point)
		previous=point;previous_inside=inside
	return out
