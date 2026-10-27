extends SceneTree
## Observation only: real moving Manual approach, no state injection or repair.
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Catalog=preload("res://game/tricks/trick_catalog.gd")
const Score=preload("res://game/scoring/score_session.gd")
var passed:=0
var failed:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	Wall.Setup.register_actions()
	_release()
	var f: Dictionary=await Wall._fixture(self,-8.0)
	var r: CharacterBody3D=f.rider
	var c: CharacterBody3D=f.control
	var data:=Body._prepare(r._visual_rig)
	var events: Array[Dictionary]=[]
	var score:=Score.new()
	var banks: Array[int]=[]
	r.trick_performed.connect(func(label: String,points: int):
		events.append({"id":r.last_trick_id,"label":label,"points":points})
		score.add_trick(label,points,r.last_trick_id))
	r.combo_link_started.connect(score.continue_combo)
	r.combo_link_ended.connect(score.begin_landing)
	r.landed.connect(func(ok: bool):
		if ok:score.begin_landing()
		else:score.drop_combo())
	r.hold_points_awarded.connect(score.add_hold_points)
	var ray:=PhysicsRayQueryParameters3D.new()
	ray.collision_mask=1|8
	ray.exclude=[r.get_rid(),c.get_rid()]
	var camera_shape:=SphereShape3D.new()
	camera_shape.radius=0.25
	var camera_query:=PhysicsShapeQueryParameters3D.new()
	camera_query.shape=camera_shape
	camera_query.margin=0.015
	camera_query.collision_mask=1
	camera_query.exclude=ray.exclude
	var space:=r.get_world_3d().direct_space_state
	var requested:=false
	var requested_at:=Vector3.ZERO
	var entry_speed:=0.0
	var manual_ticks:=0
	var impact_tick:=-1
	var minimum:=INF
	var manual_minimum:=INF
	var min_loaded_gap:=INF
	var max_loaded_gap:=-INF
	var loaded_pair_proven:=true
	var manual_floor:=true
	var load_signature_valid:=true
	var physical_equal:=true
	var local_equal:=true
	var cloth_finite:=true
	var maximum_seam:=0.0
	var maximum_joint:=0.0
	var camera_clear:=true
	var head_visible:=true
	var camera_finite:=true
	var trace: Array[Dictionary]=[]
	Input.action_press("push",0.55)
	for tick: int in 180:
		# The2.5m/s threshold is above the native2m/s Manual entry minimum.
		# There is no forced speed, pose, active flag or contact assignment.
		if not requested and absf(r.speed)>=2.5 and r.global_position.z< -1.0:
			requested=true
			requested_at=r.global_position
			Input.action_press("manual")
		await Wall._frames(self,1)
		var bank:=score.tick(1.0/60.0)
		if bank>0:banks.append(bank)
		var contact:=Wall._wall_contact(r,f.wall)
		if contact and impact_tick<0:
			impact_tick=tick
			Input.action_release("push")
			Input.action_press("brake")
		var gap:=Wall._plane_gap(r)
		minimum=minf(minimum,gap)
		physical_equal=physical_equal and Wall._physics(r)==Wall._physics(c)
		local_equal=local_equal and r._board_visual.transform==c._board_visual.transform \
			and r._rider_visual.transform==c._rider_visual.transform
		var sample:=Body._sample(r,data)
		cloth_finite=cloth_finite and sample.finite
		maximum_seam=maxf(maximum_seam,sample.seam)
		maximum_joint=maxf(maximum_joint,sample.joint_gap)
		camera_query.transform=Transform3D(Basis.IDENTITY,r._camera.global_position)
		camera_clear=camera_clear and space.intersect_shape(camera_query,1).is_empty()
		camera_finite=camera_finite and r._camera.global_position.is_finite() and is_finite(r._camera.fov)
		var head: MeshInstance3D=r._visual_rig._head.get_node("AnatomicalHead")
		var bounds:=head.mesh.get_aabb()
		for x: float in [bounds.position.x,bounds.end.x]:
			for y: float in [bounds.position.y,bounds.end.y]:
				for z: float in [bounds.position.z,bounds.end.z]:
					ray.from=r._camera.global_position
					ray.to=head.to_global(Vector3(x,y,z))
					head_visible=head_visible and space.intersect_ray(ray).is_empty()
		var support_rows: Array[Dictionary]=[]
		var definition: Dictionary=Catalog.definition(r.manual_trick_id)
		var load_sign:=float(definition.get("manual_sign",0.0))
		if r.manual_active:
			if manual_ticks==0:entry_speed=absf(r.speed)
			manual_ticks+=1
			manual_minimum=minf(manual_minimum,gap)
			manual_floor=manual_floor and r.is_on_floor() and not r.airborne
		if r.manual_active or (impact_tick>=0 and tick-impact_tick<=5):
			# Actual catalog sign declares front/rear axle support. Held Push
			# legitimately selected Nose Manual in the original rejected probe.
			# This is independent of the production board-pitch sign selector.
			load_signature_valid=load_signature_valid and absf(load_sign)==1.0 \
				and signf(r._board_visual.rotation.x)==signf(load_sign)
			for wheel: Dictionary in r._visual_rig.board_contact_geometry().wheels:
				if Vector3(wheel.center).z*load_sign<=0.0:continue
				var bearing: Vector3=r._board_visual.to_global(wheel.center)
				ray.from=bearing+Vector3.UP*0.35
				ray.to=bearing-Vector3.UP*0.50
				var hit:=space.intersect_ray(ray)
				var proven:=not hit.is_empty() and Vector3(hit.get("normal",Vector3.ZERO)).y>0.999 \
					and absf(Vector3(hit.get("position",Vector3.INF)).y)<0.001
				loaded_pair_proven=loaded_pair_proven and proven
				var wheel_gap:=INF
				if proven:
					for point: Vector3 in wheel.points:
						wheel_gap=minf(wheel_gap,(r._board_visual.to_global(point)-Vector3(hit.position)).dot(hit.normal))
				min_loaded_gap=minf(min_loaded_gap,wheel_gap)
				max_loaded_gap=maxf(max_loaded_gap,wheel_gap)
				support_rows.append({"center":bearing,"native_flat_support":proven,"rim_gap":wheel_gap})
			loaded_pair_proven=loaded_pair_proven and support_rows.size()==2
		trace.append({"tick":tick,"manual":r.manual_active,"id":r.manual_trick_id,"speed":r.speed,
			"at":r.global_position,"contact":contact,"wall_gap":gap,"visual_offset":r._obstacle_visual_offset,
			"catalog_load_sign":load_sign,"manual_pitch":r._board_visual.rotation.x,"board_pose":r._board_visual.transform,"loaded_supports":support_rows,"cloth_seam":sample.seam,"joint_gap":sample.joint_gap,
			"camera":r._camera.global_position,"bail":r.bail_active})
		if impact_tick>=0 and tick-impact_tick>=30:break
	_release()
	_check(requested and manual_ticks>=2 and entry_speed>=2.0 and events.size()>=1 \
		and events[0].id in ["manual","nose_manual"] and events[0].points==int(Catalog.definition(events[0].id).base_points),
		"moving Manual observer: genuine mapped catalog Manual/Nose Manual enters above native2m/s minimum")
	_check(impact_tick>=0 and physical_equal and local_equal and not r.bail_active,
		"moving Manual observer: actual native wall impact and Brake preserve physical/local-pose twin equality")
	_check(cloth_finite and camera_finite,
		"moving Manual observer: actual skinned cloth and independent camera samples stay finite")
	print("WALL_MANUAL_OBSERVATION ",{"requested":requested,"requested_at":requested_at,"entry_speed":entry_speed,
		"manual_ticks":manual_ticks,"impact_tick":impact_tick,"minimum_wall_gap":minimum,"minimum_manual_wall_gap":manual_minimum,
		"loaded_pair_proven":loaded_pair_proven,"load_signature_valid":load_signature_valid,"minimum_loaded_tyre_gap":min_loaded_gap,"maximum_loaded_tyre_gap":max_loaded_gap,
		"manual_native_floor":manual_floor,"physics_equal":physical_equal,"local_pose_equal":local_equal,
		"cloth_finite":cloth_finite,"maximum_cloth_seam":maximum_seam,"maximum_joint_gap":maximum_joint,
		"camera_endpoint_clear":camera_clear,"head_aabb_corners_visible":head_visible,"camera_finite":camera_finite,
		"events":events,"banks":banks,"total_score":score.total_score,"pending_combo":score.get_combo_value(),"trace":trace})
	f.viewport.queue_free()
	await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
