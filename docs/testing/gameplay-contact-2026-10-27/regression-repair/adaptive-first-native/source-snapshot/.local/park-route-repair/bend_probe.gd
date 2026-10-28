extends SceneTree
const Main=preload("res://game/main.gd")
const Gallery=preload("res://tests/pt24_gallery_entrance_run_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Style=preload("res://game/tricks/grind_style.gd")
var passed:=0
var failed:=0
var previous:Dictionary={}
var observed:Dictionary={}
var cached_meshes:Array[Dictionary]=[]
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	var board_inverse:Transform3D=game.skater._board_visual.global_transform.affine_inverse()
	for mesh:MeshInstance3D in game.skater._visual_rig.board_contact_geometry().meshes:
		cached_meshes.append({"path":str(mesh.get_path()),"faces":mesh.mesh.get_faces(),"local":board_inverse*mesh.global_transform})
	await Gallery.run(self,game,_check,_observe)
	previous.clear()
	await Driver._gallery(self,game,_check,_observe)
	previous.clear()
	await Density._actual_ledge_admission(self,game,_check,_observe,"Grind_Park_FiveStepHubba")
	Driver._release();game.queue_free();await process_frame
	print("BEND_PROBE_OBSERVED ",observed.keys())
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _observe(phase:String,game:Node,tick:int)->void:
	var rider:CharacterBody3D=game.skater
	if rider.grinding:
		previous={"id":rider._grind.line.id,"style":rider.grind_style_id,"yaw":rider._grind_style_yaw,"direction":rider._grind.direction,"distance":rider._grind.distance,"board":rider._board_visual.global_transform,"intended_board":rider._grind_contact.board_transform,"at":rider.global_position,"phase":phase,"tick":tick}
	if not rider.bailing or previous.is_empty():return
	if not rider.bail_reason.begins_with("grind_") and rider.bail_reason!="rail_balance_or_obstruction":return
	var key:String=str(previous.id)
	if observed.has(key) or key not in ["Grind_Ledge_GalleryEntrance","Grind_Coping_ExchangeFountain","Grind_Park_FiveStepHubba"]:return
	observed[key]=true
	var line=rider._grind.line
	var offset:float=rider._grind.distance
	var up:Vector3=line.contact_up(offset)
	var angle:float=rider._grind_clearance.edge_roll_angle
	var saved_rejection:String=rider._grind_clearance.last_rejection
	var saved_obstruction:Dictionary=rider._grind_clearance.last_obstruction.duplicate()
	var results:Array=[]
	for roll:float in [0.0,-angle,angle]:
		var pose:=Style.ContactPose.new()
		var solved:bool=Style.solve_into(pose,line,offset,float(previous.direction),float(previous.yaw),str(previous.style),roll/Style.BALANCE_ROLL,angle)
		var static_clear:bool=solved and rider._grind_clearance.allows(pose,up)
		var static_reason:String=rider._grind_clearance.last_rejection
		var overlaps:Array=_overlaps(rider,pose.board_transform,up) if solved else []
		var to_same:bool=solved and rider._grind_clearance.allows_frame_path(pose.board_transform,pose.board_transform,up)
		var path_clear:bool=solved and rider._grind_clearance.allows_frame_path(previous.board,pose.board_transform,up)
		var intended_path:bool=solved and rider._grind_clearance.allows_frame_path(previous.intended_board,pose.board_transform,up)
		var path_stats:Dictionary={"queries":rider._grind_clearance.last_path_queries,"subdivisions":rider._grind_clearance.last_path_subdivisions,"max_depth":rider._grind_clearance.last_path_max_depth,"budget_exhausted":rider._grind_clearance.last_path_budget_exhausted}
		results.append({"requested_roll_radians":roll,"solved":solved,"anchors":pose.anchors.slice(0,pose.anchor_count),"supports":pose.supports.slice(0,pose.anchor_count),"anchor_count":pose.anchor_count,"support_error":pose.max_error,"board":pose.board_transform,"static_clear":static_clear,"static_reason":static_reason,"incoming_path_clear":path_clear,"incoming_intended_path_clear":intended_path,"intended_path_stats":path_stats,"target_same_frame_path_clear":to_same,"path_reason":rider._grind_clearance.last_rejection,"path_obstruction":rider._grind_clearance.last_obstruction.duplicate(),"overlaps":overlaps})
	print("BEND_NATIVE_DIAGNOSTIC ",JSON.stringify({"id":key,"phase":phase,"tick":tick,"reason":rider.bail_reason,"at":rider.global_position,"offset":offset,"previous":previous,"prior_model_reason":saved_rejection,"prior_model_obstruction":saved_obstruction,"actual_model_edge_roll":angle,"prior_actual_static":rider._grind_clearance.allows_frame(previous.board,up),"prior_actual_same_path":rider._grind_clearance.allows_frame_path(previous.board,previous.board,up),"prior_intended_static":rider._grind_clearance.allows_frame(previous.intended_board,up),"prior_intended_same_path":rider._grind_clearance.allows_frame_path(previous.intended_board,previous.intended_board,up),"guide_subdivision":_guide_samples(rider,line,offset),"alternatives":results,"method":"Pure existing Style solve about exact existing support anchor/chord; no actor/input/crown/axes edits, every native convex model piece queried against ALL1|2|8 solids with only rider excluded. Existing100micrometre support skin; incoming continuous path starts at preceding actual native board frame."}))
func _overlaps(rider:CharacterBody3D,frame:Transform3D,up:Vector3)->Array:
	var result:Array=[]
	var index:=0
	for part:Dictionary in rider._grind_clearance._parts:
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=part.shape;query.transform=frame
		query.transform.origin+=up*Style.CONTACT_TOLERANCE;query.collision_mask=1|2|8;query.exclude=[rider.get_rid()];query.margin=0.0
		var hits:Array=rider.get_world_3d().direct_space_state.intersect_shape(query,16)
		for hit:Dictionary in hits:
			var body:CollisionObject3D=hit.collider
			var owner:int=body.shape_find_owner(int(hit.shape))
			var collision:CollisionShape3D=body.shape_owner_get_owner(owner) as CollisionShape3D
			var entry:Dictionary={"part":index,"vertices":part.points.size(),"collider":str(body.get_path()),"rid":body.get_rid(),"shape":int(hit.shape),"label":str(body.get_meta("art_label",body.name))}
			if collision!=null and (collision.shape is BoxShape3D or collision.shape is CylinderShape3D):
				var local:Transform3D=collision.global_transform.affine_inverse()*query.transform
				var inside:=0;var minimum:=INF;var worst:=Vector3.ZERO
				for vertex:Vector3 in part.points:
					var at:Vector3=local*vertex
					var margin:float
					if collision.shape is BoxShape3D:
						var delta:Vector3=at.abs()-collision.shape.size*.5;margin=maxf(delta.x,maxf(delta.y,delta.z))
					else:margin=maxf(Vector2(at.x,at.z).length()-collision.shape.radius,absf(at.y)-collision.shape.height*.5)
					if margin<minimum:minimum=margin;worst=at
					if margin< -Style.CONTACT_TOLERANCE:inside+=1
				entry.merge({"native_shape_node":str(collision.get_path()),"native_shape_type":collision.shape.get_class(),"native_shape_frame":collision.global_transform,"actual_vertices_inside":inside,"minimum_vertex_margin":minimum,"worst_local_vertex":worst,"actual_rendered_triangles":_triangle_hits(rider,query.transform,collision)})
			result.append(entry)
		index+=1
	return result
func _triangle_hits(rider:CharacterBody3D,frame:Transform3D,collision:CollisionShape3D)->Dictionary:
	var count:=0;var firsts:Array=[]
	for mesh:Dictionary in cached_meshes:
		var transform:Transform3D=collision.global_transform.affine_inverse()*frame*mesh.local
		var faces:PackedVector3Array=mesh.faces
		for index:int in range(0,faces.size(),3):
			var polygon:Array[Vector3]=[transform*faces[index],transform*faces[index+1],transform*faces[index+2]]
			if collision.shape is BoxShape3D:
				for axis:int in 3:
					for sign_value:float in [-1.0,1.0]:polygon=_clip_axis(polygon,axis,collision.shape.size[axis]*.5-Style.CONTACT_TOLERANCE,sign_value)
			else:
				polygon=_clip_axis(polygon,1,collision.shape.height*.5-Style.CONTACT_TOLERANCE,1.0)
				polygon=_clip_axis(polygon,1,collision.shape.height*.5-Style.CONTACT_TOLERANCE,-1.0)
			if polygon.is_empty():continue
			var intersects:=collision.shape is BoxShape3D
			if collision.shape is CylinderShape3D:
				var projected:=PackedVector2Array()
				for point:Vector3 in polygon:projected.append(Vector2(point.x,point.z))
				var radial:=INF
				for edge:int in projected.size():radial=minf(radial,Geometry2D.get_closest_point_to_segment(Vector2.ZERO,projected[edge],projected[(edge+1)%projected.size()]).length())
				if projected.size()>=3 and Geometry2D.is_point_in_polygon(Vector2.ZERO,projected):radial=0.0
				intersects=radial<collision.shape.radius-Style.CONTACT_TOLERANCE
			if intersects:
				count+=1
				if firsts.size()<3:firsts.append({"mesh":str(mesh.path),"face":index/3,"native_triangle_clipped":polygon})
	return {"count":count,"firsts":firsts,"method":"Original rendered triangles clipped to finite native primitive100micrometres inside each end/box plane; cylinder candidates require actual projected radial intersection by more than the same100micrometre contact tolerance."}
func _clip_axis(polygon:Array[Vector3],axis:int,half:float,sign_value:float)->Array[Vector3]:
	var out:Array[Vector3]=[]
	if polygon.is_empty():return out
	var previous:Vector3=polygon[-1]
	var previous_inside:bool=previous[axis]*sign_value<=half
	for point:Vector3 in polygon:
		var inside:bool=point[axis]*sign_value<=half
		if inside!=previous_inside:
			var t:float=(half*sign_value-previous[axis])/(point[axis]-previous[axis])
			out.append(previous.lerp(point,t))
		if inside:out.append(point)
		previous=point;previous_inside=inside
	return out

func _guide_samples(rider:CharacterBody3D,line,offset:float)->Array:
	var result:Array=[]
	var prior:Transform3D=previous.intended_board
	var prior_body:Vector3=rider._grind._body_point(line,float(previous.distance))
	for sample:int in 9:
		var distance:float=lerpf(float(previous.distance),offset,float(sample)/8.0)
		var pose:=Style.ContactPose.new()
		var solved:bool=Style.solve_into(pose,line,distance,float(previous.direction),float(previous.yaw),str(previous.style),0.0,rider._grind_clearance.edge_roll_angle)
		var up:Vector3=line.contact_up(distance)
		var target:Vector3=rider._grind._body_point(line,distance)
		var frame_clear:bool=solved and rider._grind_clearance.allows(pose,up)
		var same_clear:bool=solved and rider._grind_clearance.allows_frame_path(pose.board_transform,pose.board_transform,up)
		var segment_clear:bool=solved and rider._grind_clearance.allows_frame_path(prior,pose.board_transform,up)
		var linear:Transform3D=Transform3D(previous.intended_board).interpolate_with(pose.board_transform,1.0) if sample==0 else Transform3D(previous.intended_board).interpolate_with(_end_frame(line,offset),float(sample)/8.0)
		var linear_static:bool=rider._grind_clearance.allows_frame(linear,up)
		result.append({"fraction":float(sample)/8.0,"distance":distance,"solved":solved,"support_error":pose.max_error,"native_crown":rider._grind_native_crown(line,distance),"native_body_segment":rider._rail_path_clear(prior_body,target),"static_clear":frame_clear,"same_frame_path_clear":same_clear,"piecewise_continuous_clear":segment_clear,"linear_static_clear":linear_static,"overlaps":_overlaps(rider,pose.board_transform,up) if not frame_clear else []})
		prior=pose.board_transform;prior_body=target
	return result
func _end_frame(line,offset:float)->Transform3D:
	var pose:=Style.ContactPose.new()
	Style.solve_into(pose,line,offset,float(previous.direction),float(previous.yaw),str(previous.style),0.0,0.0)
	return pose.board_transform

func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: "+label)
	else:failed+=1;push_error("FAIL: "+label)
