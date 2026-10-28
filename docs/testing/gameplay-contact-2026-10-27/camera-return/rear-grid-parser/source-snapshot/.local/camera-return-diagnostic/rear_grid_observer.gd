extends RefCounted
## Counterfactual native camera queries only; never assigns the real camera/body.
static func inspect(chase: RefCounted,rider: CharacterBody3D,camera: Camera3D,previous_camera: Transform3D,delta: float,reduced: bool) -> void:
	var space: PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
	var board: Vector3=chase._follow_transform(rider).origin
	var anchor: Vector3=chase._last_anchor
	var rear: Vector3=-chase._motion_direction
	var excluded: Array[RID]=[rider.get_rid()]
	var preview:=Camera3D.new();preview.current=false;preview.cull_mask=0
	rider.add_child(preview);preview.current=false
	preview.fov=camera.fov;preview.near=camera.near;preview.far=camera.far;preview.keep_aspect=camera.keep_aspect
	var rows: Array[Dictionary]=[]
	for arm: float in [1.6,2.0,2.5,3.0,4.0,4.9]:
		for height: float in [-3.0,0.0,1.05,1.95,2.5,4.0,7.2]:
			var candidate: Dictionary=chase._candidate(space,anchor,board,rear,arm,0.0,height,excluded)
			var position: Vector3=candidate.position
			var reason: Dictionary=_reason(chase,space,board,anchor,position,excluded,rider)
			var screen_ok:=false
			if candidate.usable:
				_aim(chase,rider,camera,preview,previous_camera,anchor,position,delta,reduced)
				screen_ok=_framed(chase,rider,preview)
			rows.append({"arm":arm,"height":height,"position":position,"usable":candidate.usable,
				"screen":screen_ok,"move_from_previous":position.distance_to(previous_camera.origin),"reason":reason})
	preview.free()
	print("CAMERA_REAR_GRID ",JSON.stringify({"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),
		"reduced":reduced,"rider":rider.global_transform,"velocity":rider.velocity,"anchor":anchor,"rear":rear,
		"body_up":chase._body_up,"orbit_up":chase._orbit_up,"lift":chase._ramp_lift,
		"actual_camera":camera.global_transform,"previous_camera":previous_camera,"rows":rows}))

static func _aim(chase: RefCounted,rider: CharacterBody3D,actual: Camera3D,preview: Camera3D,previous: Transform3D,anchor: Vector3,position: Vector3,delta: float,reduced: bool) -> void:
	preview.global_position=position
	var speed: float=clampf(Vector2(chase._travel_velocity.x,chase._travel_velocity.z).length(),0,15)
	var ahead: float=clampf((anchor.distance_to(position)-3.0)/3.0,0,1)*(0.35 if reduced else 0.35+speed*0.055)
	var target: Vector3=anchor+chase._motion_direction*ahead
	var forward: Vector3=(target-position).normalized()
	var wanted: Vector3=chase._orbit_up.slide(forward)
	var transported: Vector3=previous.basis.y.slide(forward)
	if transported.length_squared()<0.01:transported=(Vector3.UP if absf(forward.y)<0.9 else Vector3.FORWARD).slide(forward)
	transported=transported.normalized()
	var up: Vector3=transported
	if wanted.length_squared()>0.1:
		wanted=wanted.normalized()
		var roll: float=transported.signed_angle_to(wanted,forward)
		up=transported.rotated(forward,clampf(roll,-chase.ROLL_RATE*delta,chase.ROLL_RATE*delta))
	preview.global_basis=Basis.looking_at(forward,up)
	chase._fit_ramp_framing(preview,chase._follow_transform(rider._visual_rig._head).origin,rider._visual_rig)

static func _framed(chase: RefCounted,rider: CharacterBody3D,camera: Camera3D) -> bool:
	for point: Vector3 in chase._foot_targets:
		if not camera.is_position_in_frustum(point):return false
	for point: Vector3 in chase._head_bounds:
		if not camera.is_position_in_frustum(point):return false
	var displayed: Transform3D=rider.get_global_transform_interpolated()
	var normal: Vector3=rider._visual.get_global_transform_interpolated().basis.y.normalized()
	for height: float in [0.12,1.05,1.8]:
		if not camera.is_position_in_frustum(displayed.origin+normal*height):return false
	return true

static func _ray(space: PhysicsDirectSpaceState3D,from: Vector3,to: Vector3,excluded: Array[RID]) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(from,to,1|8)
	query.exclude=excluded
	return space.intersect_ray(query)

static func _brief(hit: Dictionary) -> Dictionary:
	if hit.is_empty():return {}
	return {"collider":str(hit.collider.get_path()),"label":hit.collider.get_meta("art_label",str(hit.collider.name)),
		"shape":hit.shape,"rid":str(hit.rid),"position":hit.get("position",Vector3.ZERO),"normal":hit.get("normal",Vector3.ZERO)}

static func _reason(chase: RefCounted,space: PhysicsDirectSpaceState3D,board: Vector3,anchor: Vector3,position: Vector3,excluded: Array[RID],rider: Node) -> Dictionary:
	if anchor.distance_to(position)<chase._minimum_arm:return {"kind":"minimum_arm","length":anchor.distance_to(position)}
	var volume:=PhysicsShapeQueryParameters3D.new();volume.shape=chase._sphere
	volume.transform=Transform3D(Basis.IDENTITY,position);volume.margin=0.015;volume.collision_mask=1;volume.exclude=excluded
	var overlap:=space.intersect_shape(volume,1)
	if not overlap.is_empty():return {"kind":"camera_volume","hit":_brief(overlap[0])}
	for height: float in [0.12,chase.CHEST_HEIGHT,1.8]:
		var point: Vector3=board+chase._body_up*height
		var hit:=_ray(space,position,point,excluded)
		if not hit.is_empty():return {"kind":"body_proxy","height":height,"target":point,"hit":_brief(hit)}
	for point: Vector3 in chase._head_targets:
		var hit:=_ray(space,position,point,excluded)
		if not hit.is_empty():return {"kind":"head_target","target":point,"hit":_brief(hit)}
	if not chase._head_bounds.is_empty():
		var points:=PackedVector3Array([Vector3.ZERO])
		for corner: Vector3 in chase._head_bounds:points.append(corner-position)
		var shape:=ConvexPolygonShape3D.new();shape.margin=0;shape.points=points
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.margin=0;query.collision_mask=1|8
		query.transform=Transform3D(Basis.IDENTITY,position);query.exclude=excluded
		var hits:=space.intersect_shape(query,1)
		if not hits.is_empty():return {"kind":"head_volume","hit":_brief(hits[0])}
	for index: int in chase._foot_targets.size():
		var point: Vector3=chase._foot_targets[index]
		var hit:=_ray(space,position,point,excluded)
		if hit.is_empty():continue
		var support:=_ray(space,point+chase._body_up*0.03,point-chase._body_up*0.03,excluded)
		var accepted: bool=not support.is_empty() and support.collider==hit.collider and Vector3(hit.normal).dot(chase._body_up)>=0.65 			and Vector3(support.normal).dot(hit.normal)>=0.99 			and absf((point-Vector3(support.position)).dot(support.normal))<=0.004 			and absf((point-Vector3(hit.position)).dot(hit.normal))<=0.004
		if not accepted:return {"kind":"foot_or_board_target","index":index,"target":point,
			"board_local":rider._board_visual.to_local(point),"hit":_brief(hit),"endpoint_support":_brief(support)}
	return {"kind":"all_native_clear"}
