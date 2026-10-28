extends RefCounted
const Base=preload("res://.local/contact-camera-diagnostic/camera_shape_witness.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Geometry=preload("res://tests/board_geometry_tests_support.gd")
const Footwear=preload("res://game/player/skater_footwear.gd")
static func observe(game:Node)->void:
	var r=game.skater
	var chase=r._camera_follow
	var space:PhysicsDirectSpaceState3D=r.get_world_3d().direct_space_state
	var report:Dictionary=Base.snapshot(game,"clyde-civic-first-false")
	var first:Dictionary=_first(game)
	report["first_exact_density_marker"]=first
	report["manual"]=r.manual_active
	report["transition"]=r.transition_active
	report["feature_state"]=r._feature_transition.state
	report["feature"]=str(r._feature_transition.feature)
	report["feature_theta"]=r._feature_transition._theta
	report["feature_x"]=r._feature_transition._x
	report["body_collision"]=r._body_collision.global_transform
	if is_instance_valid(r._feature_transition.feature):
		var sample:Dictionary=r._feature_transition.feature.sample(r._feature_transition._theta,r._feature_transition._x)
		report["feature_sample"]=sample
		report["root_feature_normal_gap"]=(r.global_position-Vector3(sample.point)).dot(sample.normal)
	report["velocity"]=r.velocity
	report["flip"]=r._flip_remaining
	report["lip"]=r.lip_active
	report["force_air"]=r._force_air_tick
	report["root_determinant"]=r.global_basis.determinant()
	report["board_determinant"]=r._board_visual.global_basis.determinant()
	report["native_floor"]=Base._hit(r._native_floor_hit(Vector3.UP))
	var excluded:Array[RID]=[r.get_rid()]
	report["camera_usable"]=chase._usable(space,chase._follow_transform(r).origin,chase._last_anchor,r._camera.global_position,excluded)
	report["camera_foot_targets"]=chase._foot_targets.size()
	var wheels:Array[Dictionary]=[]
	var geometry:Dictionary=r._visual_rig.board_contact_geometry()
	for index:int in r._floor_wheel_shapes.size():
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=r._floor_wheel_shapes[index]
		query.transform=r._board_visual.global_transform;query.margin=0;query.exclude=excluded;query.collision_mask=1|8
		var hits:=space.intersect_shape(query,8)
		var brief:Array[Dictionary]=[]
		for hit:Dictionary in hits:brief.append({"label":hit.collider.get_meta("art_label",str(hit.collider.name)),"shape":hit.shape,"rid":str(hit.rid)})
		var center:Vector3=r._board_visual.to_global(geometry.wheels[index].center)
		wheels.append({"index":index,"center":center,"native_overlaps":brief,
			"support_ray":Base._hit(_ray(r,center+Vector3.UP*0.35,center-Vector3.UP*0.50))})
	report["actual_four_tyres"]=wheels
	print("CONTACT_WITNESS ",JSON.stringify(report))

static func _first(game:Node)->Dictionary:
	var r=game.skater;var camera:Camera3D=r._camera;var rig=r._visual_rig
	var rows:Array[Dictionary]=[{"kind":"head_origin","point":rig._head.global_position},
		{"kind":"board_origin","point":r._board_visual.global_position}]
	for mesh:MeshInstance3D in Geometry.visible_meshes(rig):
		var key:int=mesh.mesh.get_instance_id()
		var hull:PackedVector3Array=Density._camera_hulls[key]
		for index:int in hull.size():rows.append({"kind":"raw_mesh_hull","point":mesh.to_global(hull[index]),"mesh":mesh,"hull_local":hull[index],"hull_index":index})
	for leg:Dictionary in rig._legs:
		rows.append({"kind":"sole","point":leg.foot.to_global(Footwear.SOLE_CONTACT)})
		rows.append({"kind":"toe","point":leg.foot.to_global(Footwear.TOE_CONTACT)})
	for row:Dictionary in rows:
		var point:Vector3=row.point
		var hit:Dictionary=_ray(r,camera.global_position,point)
		if hit.is_empty() and camera.is_position_in_frustum(point):continue
		row["frustum"]=camera.is_position_in_frustum(point);row["hit"]=Base._hit(hit)
		row["board_local"]=r._board_visual.to_local(point)
		if not hit.is_empty():row["analytic_native_containment"]=_containment(hit,point)
		row["world_vertical_endpoint_support"]=Base._hit(_ray(r,point+Vector3.UP*0.03,point-Vector3.UP*0.03))
		row["body_axis_endpoint_support"]=Base._hit(_ray(r,point+r._camera_follow._body_up*0.03,point-r._camera_follow._body_up*0.03))
		var nearest_target:=INF
		for target:Vector3 in r._camera_follow._foot_targets:nearest_target=minf(nearest_target,target.distance_to(point))
		row["nearest_current_or_interpolated_camera_target_m"]=nearest_target
		if row.has("mesh"):
			var mesh:MeshInstance3D=row.mesh;var vertices:=PackedVector3Array()
			for surface:int in mesh.mesh.get_surface_count():vertices.append_array(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
			var nearest:=Vector3.ZERO;var gap:=INF
			for vertex:Vector3 in vertices:
				var error:float=vertex.distance_squared_to(row.hull_local)
				if error<gap:gap=error;nearest=vertex
			row["mesh"]=str(r.get_path_to(mesh));row["nearest_actual_mesh_local"]=nearest
			row["nearest_actual_world"]=mesh.to_global(nearest)
			row["hull_to_actual_error_world_m"]=mesh.to_global(nearest).distance_to(point)
			row["nearest_actual_ray"]=Base._hit(_ray(r,camera.global_position,mesh.to_global(nearest)))
			var native_gap:=INF
			for target:Vector3 in r._camera_follow._wheel_landmarks:native_gap=minf(native_gap,target.distance_to(r._board_visual.to_local(mesh.to_global(nearest))))
			row["actual_vertex_to_cached_board_landmark_m"]=native_gap
		return row
	return {"kind":"no_occluded_marker"}

static func _ray(r:Node,from:Vector3,to:Vector3)->Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(from,to,1|8);query.exclude=[r.get_rid()]
	return r.get_world_3d().direct_space_state.intersect_ray(query)

static func _containment(hit:Dictionary,point:Vector3)->Dictionary:
	var simple:Dictionary=Base._shape_containment(hit,point)
	if simple.supported_primitive:return simple
	var body:CollisionObject3D=hit.collider
	var node=body.shape_owner_get_owner(body.shape_find_owner(int(hit.shape)))
	if not node is CollisionShape3D or not node.shape is ConvexPolygonShape3D:return simple
	var shape:ConvexPolygonShape3D=node.shape
	var center:=Vector3.ZERO
	for vertex:Vector3 in shape.points:center+=vertex
	center/=shape.points.size()
	var local:Vector3=node.to_local(point)
	var faces:PackedVector3Array=shape.get_debug_mesh().get_faces()
	var inside:=INF;var nearest_normal:=Vector3.ZERO;var nearest_plane_point:=Vector3.ZERO
	for index:int in range(0,faces.size(),3):
		var a:Vector3=faces[index];var normal:Vector3=(faces[index+1]-a).cross(faces[index+2]-a).normalized()
		if normal.length_squared()<0.5:continue
		if normal.dot(center-a)>0:normal=-normal
		var depth:float=-(local-a).dot(normal)
		if depth<inside:inside=depth;nearest_normal=normal;nearest_plane_point=a
	return {"type":"ConvexPolygonShape3D","shape_node":str(node.get_path()),"local_point":local,
		"minimum_interior_depth_local_m":inside,"closest_outward_normal":nearest_normal,
		"closest_plane_point_local":nearest_plane_point,"frame":node.global_transform,"native_shape_margin":shape.margin}
