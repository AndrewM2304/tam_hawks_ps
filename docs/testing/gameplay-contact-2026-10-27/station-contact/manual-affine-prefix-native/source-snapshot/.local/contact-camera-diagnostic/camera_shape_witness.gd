extends RefCounted
## Diagnostic observer only. Never moves a camera, rider or visible node.
const BoardGeometry = preload("res://tests/board_geometry_tests_support.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")

static func observe(game: Node,tag: String) -> void:
	print("CAMERA_SHAPE_WITNESS ",JSON.stringify(snapshot(game,tag+"/at-check")))
	# SceneTreeTimer runs after normal Node._process. Frame IDs still decide
	# whether this is a same-physics-frame comparison; never assume it is.
	var late := func() -> void:
		await game.get_tree().create_timer(0.0,false,false).timeout
		if is_instance_valid(game):print("CAMERA_SHAPE_WITNESS ",JSON.stringify(snapshot(game,tag+"/after-process")))
	late.call()

static func snapshot(game: Node,tag: String) -> Dictionary:
	var r=game.skater
	var rig=r._visual_rig
	var camera: Camera3D=r._camera
	var report := {"tag":tag,"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),
		"last_physics":r.last_physics_frame,"last_camera_process":r.last_presentation_process_frame,
		"fraction":Engine.get_physics_interpolation_fraction(),"rider":r.global_transform,
		"camera":camera.global_transform,"board":r._board_visual.global_transform,
		"board_displayed":r._board_visual.get_global_transform_interpolated(),"visual":r._visual.global_transform,
		"grinding":r.grinding,"style":r.grind_style_id,"airborne":r.airborne,
		"grind_visual_offset":r._grind_visual_offset,"rig_release_offset":rig._grind_release_offset,
		"native_margin":r.safe_margin,"blocked":[]}
	var space: PhysicsDirectSpaceState3D=r.get_world_3d().direct_space_state
	# Density checks these two node origins BEFORE material-mesh hull vertices.
	# Record proxies separately; a hidden origin is not itself a rendered face.
	report["node_proxies"]=[_point_witness(r,space,camera,rig._head.global_position,"head_origin"),
		_point_witness(r,space,camera,r._board_visual.global_position,"board_origin")]
	report["actual_component_overlaps"]=_component_overlaps(r,space)
	for mesh: MeshInstance3D in BoardGeometry.visible_meshes(rig):
		var hull: ConvexPolygonShape3D=mesh.mesh.create_convex_shape(true,false)
		var vertices := PackedVector3Array()
		for surface: int in mesh.mesh.get_surface_count():
			vertices.append_array(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
		for point: Vector3 in hull.points:
			var marker: Vector3=mesh.to_global(point)
			var ray:=PhysicsRayQueryParameters3D.create(camera.global_position,marker,1|8)
			ray.exclude=[r.get_rid()]
			var hit:=space.intersect_ray(ray)
			if hit.is_empty():continue
			var nearest := Vector3.ZERO
			var gap:=INF
			for vertex: Vector3 in vertices:
				var error: float=point.distance_squared_to(vertex)
				if error<gap:gap=error;nearest=vertex
			var nearest_camera_target:=INF
			for target: Vector3 in r._camera_follow._foot_targets:
				nearest_camera_target=minf(nearest_camera_target,marker.distance_to(target))
			var displayed: Vector3=mesh.get_global_transform_interpolated()*point
			var back:=PhysicsRayQueryParameters3D.create(marker,camera.global_position,1|8)
			back.exclude=[r.get_rid()];back.hit_from_inside=true
			var reverse:=space.intersect_ray(back)
			report.blocked.append({"mesh":str(r.get_path_to(mesh)),"mesh_local_hull_point":point,
				"nearest_actual_vertex":nearest,"hull_to_actual_vertex_error_m":sqrt(gap),
				"actual_marker":marker,"displayed_marker":displayed,"hit":_hit(hit),
				"hit_to_marker_m":marker.distance_to(hit.position),
				"marker_signed_hit_plane_m":(marker-Vector3(hit.position)).dot(hit.normal),
				"nearest_previous_camera_target_m":nearest_camera_target,
				"native_shape":_shape_containment(hit,marker),"reverse_hit":_hit(reverse)})
			if report.blocked.size()>=4:return report
	return report

static func _hit(hit: Dictionary) -> Dictionary:
	if hit.is_empty():return {}
	return {"position":hit.position,"normal":hit.normal,"collider":str(hit.collider.get_path()),
		"label":hit.collider.get_meta("art_label",str(hit.collider.name)),"rid":str(hit.rid),"shape":hit.shape}

static func _shape_containment(hit: Dictionary,point: Vector3) -> Dictionary:
	var body: CollisionObject3D=hit.collider
	var owner=body.shape_owner_get_owner(body.shape_find_owner(int(hit.shape)))
	if not owner is CollisionShape3D or owner.shape==null:return {"supported_primitive":false}
	var local: Vector3=owner.to_local(point)
	var result: Dictionary={"shape_node":str(owner.get_path()),"type":owner.shape.get_class(),
		"local_point":local,"frame":owner.global_transform,"supported_primitive":true}
	if owner.shape is BoxShape3D:
		var half: Vector3=owner.shape.size*0.5
		var remaining: Vector3=half-local.abs()
		result["half_size"]=half
		result["minimum_interior_depth_local_m"]=minf(remaining.x,minf(remaining.y,remaining.z))
	elif owner.shape is CylinderShape3D:
		result["radius"]=owner.shape.radius;result["height"]=owner.shape.height
		result["minimum_interior_depth_local_m"]=minf(owner.shape.radius-Vector2(local.x,local.z).length(),owner.shape.height*0.5-absf(local.y))
	else:result["supported_primitive"]=false
	return result


static func _point_witness(r: Node,space: PhysicsDirectSpaceState3D,camera: Camera3D,point: Vector3,kind: String) -> Dictionary:
	var ray:=PhysicsRayQueryParameters3D.create(camera.global_position,point,1|8)
	ray.exclude=[r.get_rid()]
	var hit:=space.intersect_ray(ray)
	var reverse:=PhysicsRayQueryParameters3D.create(point,camera.global_position,1|8)
	reverse.exclude=[r.get_rid()];reverse.hit_from_inside=true
	var result: Dictionary={"kind":kind,"point":point,"hit":_hit(hit),"reverse_hit":_hit(space.intersect_ray(reverse))}
	if not hit.is_empty():
		result["native_shape"]=_shape_containment(hit,point)
		result["hit_to_marker_m"]=point.distance_to(hit.position)
	return result


static func _component_overlaps(r: Node,space: PhysicsDirectSpaceState3D) -> Array[Dictionary]:
	# Reuse the existing startup-welded CONNECTED native model pieces. A single
	# convex material hull would fill empty space between four separate wheels.
	var results: Array[Dictionary]=[]
	var query:=PhysicsShapeQueryParameters3D.new()
	query.collision_mask=1|8;query.exclude=[r.get_rid()]
	query.margin=0.0;query.transform=r._board_visual.global_transform
	var index: int=0
	for part: Dictionary in r._grind_clearance._parts:
		query.shape=part.shape
		var overlaps:=space.intersect_shape(query,16)
		if not overlaps.is_empty():
			var points: PackedVector3Array=part.points
			var bounds:=AABB(points[0],Vector3.ZERO)
			for point: Vector3 in points:bounds=bounds.expand(point)
			var hits: Array[Dictionary]=[]
			for hit: Dictionary in overlaps:
				hits.append({"collider":str(hit.collider.get_path()),
					"label":hit.collider.get_meta("art_label",str(hit.collider.name)),"rid":str(hit.rid),"shape":hit.shape})
			var rest:=space.get_rest_info(query)
			var contact: Dictionary={}
			if not rest.is_empty():contact={"point":rest.point,"normal":rest.normal,"rid":str(rest.rid),"shape":rest.shape}
			results.append({"component":index,"board_local_bounds":bounds,"vertices":points.size(),"hits":hits,"native_rest":contact})
		index+=1
	return results
