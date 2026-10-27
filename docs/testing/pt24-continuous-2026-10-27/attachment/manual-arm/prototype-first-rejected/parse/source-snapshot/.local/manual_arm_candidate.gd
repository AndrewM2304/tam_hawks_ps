extends "res://game/player/skater_obstacle_arm_fit.gd"
## Ignored eligibility-only candidate. All cached envelopes, finite native face,
## original IK/lengths,12-query/20cm caps and restoration inherit unchanged.
## The controller sets this earned flag only after its final fresh native
## loaded-tyre and complete board/shoe support proof in the same pose update.
func _ordinary_manual_fit() -> bool:
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
			var local_shoulder: Vector3=rig._rider.to_local(shoulder)
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

