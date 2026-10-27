extends RefCounted
## Bounded free-arm presentation after the connected board/shoe wall fit.
## Constant-weight garment rows use affine
## cylinder support; their union encloses every native skinned vertex.
## The hand bound encloses base and normalized curl, hence every curl mixture.
const SKIN := 0.008
const MAX_WRIST_SHIFT := 0.20
const MAX_ROW_GROUPS := 32
var supported:=true
var actor: CharacterBody3D
var rig: RefCounted
var skeleton: Skeleton3D
var jacket: MeshInstance3D
var arms: Array[Dictionary]=[]
var continuing:=false
var calls:=0
var maximum_calls:=0
var maximum_shift:=0.0
var accepted:=0
var refused:=0

func reset() -> void:
	continuing=false
	calls=0
	maximum_calls=0
	maximum_shift=0.0
	accepted=0
	refused=0

func prepare(body: CharacterBody3D) -> void:
	reset()
	arms.clear()
	supported=true
	actor=body;rig=body._visual_rig;skeleton=rig._garments.skeleton
	jacket=rig._rider.get_node("SkinnedJacket")
	var arrays:=jacket.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var binds: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	var stride:=binds.size()/vertices.size()
	for side: float in [-1.0,1.0]:
		var prefix: String="left" if side<0.0 else "right"
		var upper:=skeleton.find_bone(prefix+"_sleeve")
		var lower:=skeleton.find_bone(prefix+"_forearm")
		var rows: Array[Dictionary]=[]
		var radius:=0.0
		for index in vertices.size():
			var native_binds:=binds.slice(index*stride,(index+1)*stride)
			var native_weights:=weights.slice(index*stride,(index+1)*stride)
			var arm_weight:=0.0
			for influence in stride:
				var bone:=_bone(native_binds[influence])
				if bone==upper or bone==lower:arm_weight+=native_weights[influence]
			if arm_weight<=0.001:continue
			var point:=vertices[index]
			var rest:=skeleton.get_bone_rest(upper)
			var radial: float=(point-rest.origin).slide(rest.basis.y).length()
			radius=maxf(radius,radial)
			var found:=false
			for row: Dictionary in rows:
				if row.binds==native_binds and row.weights==native_weights:
					row.bounds=AABB(row.bounds).expand(point);row.radius=maxf(row.radius,radial);found=true;break
			if not found:rows.append({"binds":native_binds,"weights":native_weights,"bounds":AABB(point,Vector3.ZERO),"radius":radial,"center":Vector2(rest.origin.x,rest.origin.z)})
		var hand: Node3D=rig._arms[arms.size()].hand
		var mesh: MeshInstance3D=hand.get_node("HandAndFingers")
		var hand_bounds:=AABB();var first:=true
		for surface in mesh.mesh.get_surface_count():
			var base: PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var shapes: Array=mesh.mesh.surface_get_blend_shape_arrays(surface)
			var curl: PackedVector3Array=shapes[0][Mesh.ARRAY_VERTEX]
			for index in base.size():
				for point: Vector3 in [base[index],curl[index]]:
					hand_bounds=AABB(point,Vector3.ZERO) if first else hand_bounds.expand(point);first=false
		var hand_radius:=0.0
		var hand_length:=0.0
		for corner in 8:
			var point:=hand_bounds.get_endpoint(corner)
			hand_radius=maxf(hand_radius,Vector2(point.x,point.z).length())
			hand_length=maxf(hand_length,absf(point.y))
		if rows.size()>MAX_ROW_GROUPS:supported=false
		arms.append({"side":side,"upper":upper,"lower":lower,"rows":rows,"radius":radius,
			"hand":hand,"mesh_local":mesh.transform,"hand_bounds":hand_bounds,"hand_radius":hand_radius,"hand_length":hand_length})

func _ordinary_manual_fit() -> bool:
	# The immediately preceding final root fit has proved current native
	# loaded-tyre and complete board/shoe support; never reuse a stale ID alone.
	return (actor.manual_active or rig._manual_blend>0.0001) \
		and actor._obstacle_manual_continuation \
		and actor.manual_trick_id in ["manual","nose_manual"] \
		and not actor.airborne and actor._native_floor_valid and actor.is_on_floor() \
		and not actor._force_air_tick and actor._native_floor_normal().y>0.999

func apply(_delta: float) -> void:
	calls=0
	if not supported:return
	var ordinary_manual: bool=_ordinary_manual_fit()
	if (actor.manual_active and not ordinary_manual) or actor.transition_active or actor.grinding or actor.wallriding \
			or actor.bailing or actor.setup_active or actor.skitching or actor.lip_active \
			or actor.powersliding or actor._special_remaining>0.0 \
			or actor._grab_remaining>0.0 or rig._grab_blend>0.0001 \
			or rig._skitch_blend>0.0001 or rig._pogo_blend>0.0001 or rig._handplant_blend>0.0001 \
			or ((rig._manual_blend>0.0001 or absf(rig._manual_weight_z)>0.0001) and not ordinary_manual) \
			or rig._walk_blend>0.0001 or rig._cross_blend>0.0001 or rig._casper_blend>0.0001 \
			or rig._front_foot_lift>0.0001 or rig._rear_foot_lift>0.0001 \
			or rig._grind_blend>0.0001 or rig._lip_blend>0.0001 or rig._wall_blend>0.0001 \
			or rig._transition_blend>0.0001 or rig._slide_blend>0.0001 or rig._bail_blend>0.0001:
		continuing=false;return
	if not continuing and not ordinary_manual and not (actor.airborne and actor._obstacle_ollie_continuation and actor._launch_id=="ollie"):
		return
	var query: PhysicsShapeQueryParameters3D=actor._grind_board_query
	var ray: PhysicsRayQueryParameters3D=actor._recovery_floor_query
	var shape:=query.shape;var margin:=query.margin;var frame:=query.transform;var motion:=query.motion
	var size: Vector3=actor._grind_board_box.size
	var ray_from:=ray.from;var ray_to:=ray.to;var mask:=ray.collision_mask
	query.shape=actor._grind_board_box;query.margin=SKIN;query.motion=Vector3.ZERO
	ray.collision_mask=query.collision_mask
	var fitted:=false
	for arm: Dictionary in arms:
		var hand: Node3D=arm.hand
		var shoulder: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(arm.upper).origin
		var elbow: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(arm.lower).origin
		var wrist:=hand.global_position
		var current:=_bounds(arm,{},hand.global_transform)
		if _clear(query,current):continue
		# The base Box overlaps now; rest+same-RID ray authenticates its
		# current finite face even when both joint centres are outside it.
		var face:=_envelope_face(query,ray)
		if face.is_empty():refused+=1;continue
		var normal: Vector3=face.normal;var point: Vector3=face.position
		if not normal.is_finite() or not point.is_finite() or absf(normal.y)>0.001 or normal.length_squared()<0.99:
			refused+=1;continue
		# Fixed shoulder must be outside the solid; this is not a body fit.
		if (shoulder-point).dot(normal)<float(arm.radius)+SKIN:refused+=1;continue
		var elbow_min: float=arm.radius+SKIN
		var goal:=elbow_min+SKIN
		var wrist_gap: float=(wrist-point).dot(normal)
		var solved:=false
		for attempt in 3:
			var target_gap:=goal+SKIN*attempt
			var shift:=maxf(0.0,target_gap-wrist_gap)
			if shift>MAX_WRIST_SHIFT:continue
			var target:=wrist+normal*shift
			var elbow_max:=target_gap
			var circle:=_elbow(shoulder,target,elbow,normal,point,elbow_min,elbow_max)
			if circle.is_empty():continue
			# Independent garment bones already use rider space. Preserve this
			# original shoulder origin without a world/local round-trip drift.
			var local_shoulder: Vector3=skeleton.get_bone_global_pose(arm.upper).origin
			var local_elbow: Vector3=rig._rider.to_local(circle.point)
			var local_wrist: Vector3=rig._rider.to_local(target)
			var upper: Transform3D=rig._garments._bone_transform(local_shoulder,local_elbow-local_shoulder)
			upper.basis=upper.basis.scaled_local(Vector3(1,local_shoulder.distance_to(local_elbow)/0.30,1))
			var lower: Transform3D=rig._garments._bone_transform(local_elbow,local_wrist-local_elbow)
			lower.basis=lower.basis.scaled_local(Vector3(1,local_elbow.distance_to(local_wrist)/0.29,1))
			var hand_local:=Transform3D(rig._hand_basis(arm.side,local_elbow-local_wrist,0.0),local_wrist)
			var poses: Dictionary={arm.upper:upper,arm.lower:lower}
			var envelope:=_bounds(arm,poses,rig._rider.global_transform*hand_local)
			if not _clear(query,envelope):continue
			rig._garments.pose_arm(arm.side,local_shoulder,local_elbow,local_wrist)
			hand.transform=hand_local
			maximum_shift=maxf(maximum_shift,shift);accepted+=1;solved=true;fitted=true;break
		if not solved:refused+=1
	query.shape=shape;query.margin=margin;query.transform=frame;query.motion=motion
	actor._grind_board_box.size=size
	ray.from=ray_from;ray.to=ray_to;ray.collision_mask=mask
	continuing=fitted
	maximum_calls=maxi(maximum_calls,calls)

func _bone(bind: int) -> int:
	var bone:=jacket.skin.get_bind_bone(bind)
	return skeleton.find_bone(String(jacket.skin.get_bind_name(bind))) if bone<0 else bone

func _envelope_face(query: PhysicsShapeQueryParameters3D,ray: PhysicsRayQueryParameters3D) -> Dictionary:
	# This axis belongs to the final freshly validated board/shoe fit, not a
	# remembered wall plane or an arbitrary direction manufactured in flight.
	var axis: Vector3=actor._obstacle_visual_offset
	if not axis.is_finite() or axis.length_squared()<0.0000000001 or axis.length()>0.18:return {}
	axis=axis.normalized()
	calls+=1
	var contact:=actor.get_world_3d().direct_space_state.get_rest_info(query)
	if contact.is_empty():return {}
	var point: Vector3=contact.point
	if not point.is_finite():return {}
	var face:=_face(ray,point+axis*SKIN*2.0,point-axis*SKIN*2.0)
	var normal: Vector3=face.get("normal",Vector3.ZERO)
	if face.is_empty() or face.get("rid")!=contact.get("rid") or not normal.is_finite() \
			or absf(normal.y)>0.001 or normal.dot(axis)<0.999:return {}
	return face

func _face(ray: PhysicsRayQueryParameters3D,from: Vector3,to: Vector3) -> Dictionary:
	ray.from=from;ray.to=to;calls+=1
	return actor.get_world_3d().direct_space_state.intersect_ray(ray)

func _clear(query: PhysicsShapeQueryParameters3D,bounds: AABB) -> bool:
	actor._grind_board_box.size=bounds.size
	query.transform=Transform3D(Basis.IDENTITY,bounds.get_center());calls+=1
	return actor.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _bounds(arm: Dictionary,overrides: Dictionary,hand_world: Transform3D) -> AABB:
	var palette: Array[Transform3D]=[]
	for bind in jacket.skin.get_bind_count():
		var bone:=_bone(bind)
		var pose: Transform3D=overrides.get(bone,skeleton.get_bone_global_pose(bone))
		palette.append(skeleton.global_transform*pose*jacket.skin.get_bind_pose(bind))
	var result:=AABB();var first:=true
	for row: Dictionary in arm.rows:
		var x:=Vector3.ZERO;var y:=Vector3.ZERO;var z:=Vector3.ZERO;var origin:=Vector3.ZERO
		for influence in row.binds.size():
			var pose: Transform3D=palette[row.binds[influence]]
			var weight: float=row.weights[influence]
			x+=pose.basis.x*weight;y+=pose.basis.y*weight;z+=pose.basis.z*weight;origin+=pose.origin*weight
		# This source cylinder contains every original row vertex; affine axis
		# support preserves that enclosure without empty rectangle corners.
		var bounds: AABB=row.bounds
		var half_height: float=bounds.size.y*0.5
		var source_center:=Vector3(row.center.x,bounds.get_center().y,row.center.y)
		var center:=Transform3D(Basis(x,y,z),origin)*source_center
		var radial: float=row.radius
		var extent:=Vector3(absf(y.x)*half_height+radial*sqrt(x.x*x.x+z.x*z.x),
			absf(y.y)*half_height+radial*sqrt(x.y*x.y+z.y*z.y),
			absf(y.z)*half_height+radial*sqrt(x.z*x.z+z.z*z.z))
		var actual:=AABB(center-extent,extent*2.0)
		result=actual if first else result.merge(actual);first=false
	return result.merge(hand_world*Transform3D(arm.mesh_local)*AABB(arm.hand_bounds))

func _elbow(shoulder: Vector3,wrist: Vector3,old: Vector3,normal: Vector3,point: Vector3,minimum: float,maximum: float) -> Dictionary:
	var offset:=wrist-shoulder;var distance:=offset.length()
	if distance<0.011 or distance>0.589:return {}
	var direction:=offset/distance
	var along: float=(0.30*0.30-0.29*0.29+distance*distance)/(2.0*distance)
	var height:=sqrt(maxf(0.0,0.30*0.30-along*along))
	var center:=shoulder+direction*along
	var outward:=normal.slide(direction);var reach:=height*outward.length()
	if reach<0.000001:return {}
	outward=outward.normalized()
	var across:=direction.cross(outward).normalized()
	var current: Vector3=(old-center).slide(direction).normalized()
	if current.length_squared()<0.01:current=outward
	var gap: float=(center-point).dot(normal)
	var low:=maxf(minimum,gap-reach);var high:=minf(maximum,gap+reach)
	if low>high:return {}
	var original: float=(center+current*height-point).dot(normal)
	if original>=low and original<=high:return {"point":center+current*height}
	var cosine:=clampf((clampf(original,low,high)-gap)/reach,-1.0,1.0)
	var sine:=sqrt(maxf(0.0,1.0-cosine*cosine))
	var a:=outward*cosine+across*sine
	var b:=outward*cosine-across*sine
	return {"point":center+(a if a.dot(current)>=b.dot(current) else b)*height}
