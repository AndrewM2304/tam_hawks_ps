extends RefCounted
## Earned moving Nose Manual, finite loaded axle and the real residual pivot.
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Queries=preload("res://tests/skater_wall_grab_tests.gd")
const Grade=preload("res://tests/pt24_manual_grade_tests.gd")
const Catalog=preload("res://game/tricks/trick_catalog.gd")
const Score=preload("res://game/scoring/score_session.gd")
const Arm=preload("res://tests/skater_obstacle_arm_tests.gd")
const Authentic=preload("res://tests/authentic_pose_tests.gd")
const Gate=preload("res://game/features/service_gate.gd")
const ArmControls=preload("res://tests/skater_manual_arm_controls.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	Wall.Setup.register_actions()
	_release()
	# Twenty millimetres of initial spawn phase gives a native moving frame
	# inside the existing skin before the unfitted mesh actually penetrates.
	var f: Dictionary=await _skin_phase_fixture(tree)
	var r: CharacterBody3D=f.rider
	var c: CharacterBody3D=f.control
	var arm_control: CharacterBody3D=f.arm_control
	var skin_data:=Arm._skin_data(r,f.gate)
	var old_skin_data:=Arm._skin_data(arm_control,f.gate)
	var data:=Body._prepare(r._visual_rig)
	var score:=Score.new()
	var events: Array[Dictionary]=[]
	var banks: Array[int]=[]
	r.trick_performed.connect(func(label: String,points: int):
		events.append({"id":r.last_trick_id,"label":label,"points":points})
		score.add_trick(label,points,r.last_trick_id))
	r.combo_link_started.connect(score.continue_combo)
	r.combo_link_ended.connect(score.begin_landing)
	var ray:=PhysicsRayQueryParameters3D.new()
	ray.collision_mask=1|8
	ray.exclude=[r.get_rid(),c.get_rid()]
	var sphere:=SphereShape3D.new();sphere.radius=0.25
	var camera_query:=PhysicsShapeQueryParameters3D.new()
	camera_query.shape=sphere;camera_query.margin=0.015;camera_query.collision_mask=1
	camera_query.exclude=ray.exclude
	var requested:=false
	var entered:=0.0
	var impact:=-1
	var active:=0
	var precontact_fits:=0
	var residual_fits:=0
	var positive_skin_fit:=false
	var minimum:=INF
	var old_minimum:=INF
	var maximum:=0.0
	var loaded_min:=INF
	var loaded_max:=-INF
	var supported:=true
	var physics:=true
	var local_pose:=true
	var bones:=true
	var arm_root_equal:=true
	var shoulders_equal:=true
	var far_arm_equal:=true
	var fixed_arms:=true
	var arm_contained:=true
	var arm_clear:=true
	var old_arm_hits:=0
	var skin_frames:=0
	var previous_markers: Array[Vector3]=[]
	var previous_elbows: Array[Vector3]=[]
	var previous_changed: Array[bool]=[false,false]
	var maximum_changed_wrist:=0.0
	var maximum_changed_elbow:=0.0
	var unchanged_markers:=true
	var query_ids: Array[int]=[r._grind_board_query.get_instance_id(),r._grind_board_box.get_instance_id(),r._recovery_floor_query.get_instance_id()]
	var attached:=true
	var seam:=0.0
	var joint:=0.0
	var camera_clear:=true
	var continuous:=true
	var previous_offset:=Vector3.ZERO
	var previous_gap:=INF
	var maximum_offset_step:=0.0
	var trace: Array[Dictionary]=[]
	Input.action_press("push",0.55)
	for tick: int in 180:
		if not requested and absf(r.speed)>=2.5 and r.global_position.z< -1.0:
			requested=true;Input.action_press("manual")
		await Wall._frames(tree,1)
		var bank:=score.tick(1.0/60.0)
		if bank>0:banks.append(bank)
		var contact:=Wall._wall_contact(r,f.wall)
		if contact and impact<0:
			impact=tick;Input.action_release("push");Input.action_press("brake")
		if r.manual_active:
			if active==0:entered=absf(r.speed)
			active+=1
		var gap:=Wall._plane_gap(r)
		var old_gap:=Wall._plane_gap(c)
		minimum=minf(minimum,gap);old_minimum=minf(old_minimum,old_gap)
		maximum=maxf(maximum,r._obstacle_visual_offset.length())
		precontact_fits+=int(r.manual_active and not contact and r._obstacle_manual_continuation)
		residual_fits+=int(not r.manual_active and r._visual_rig._manual_blend>0.0001 and r._obstacle_manual_continuation)
		positive_skin_fit=positive_skin_fit or (r.manual_active and r._obstacle_manual_continuation and old_gap>0.0 and old_gap<0.00799)
		physics=physics and Grade._physics(r)==Grade._physics(c)
		local_pose=local_pose and r._board_visual.transform==c._board_visual.transform and r._rider_visual.transform==c._rider_visual.transform
		bones=bones and Arm._nonarm(r)==Arm._nonarm(c)
		arm_root_equal=arm_root_equal and Grade._physics(r)==Grade._physics(arm_control) and r._visual.transform==arm_control._visual.transform \
			and r._board_visual.transform==arm_control._board_visual.transform and r._rider_visual.transform==arm_control._rider_visual.transform \
			and Arm._nonarm(r)==Arm._nonarm(arm_control)
		var skeleton: Skeleton3D=r._visual_rig._garments.skeleton
		var old_skeleton: Skeleton3D=arm_control._visual_rig._garments.skeleton
		var changed: Array[bool]=[]
		var elbows: Array[Vector3]=[]
		for index: int in 2:
			var arm: Dictionary=r._obstacle_arm_fit.arms[index]
			var shoulder:=skeleton.global_transform*skeleton.get_bone_global_pose(arm.upper).origin
			var old_shoulder:=old_skeleton.global_transform*old_skeleton.get_bone_global_pose(arm.upper).origin
			var elbow:=skeleton.global_transform*skeleton.get_bone_global_pose(arm.lower).origin
			var wrist: Vector3=r._visual_rig._arms[index].hand.global_position
			shoulders_equal=shoulders_equal and shoulder==old_shoulder
			fixed_arms=fixed_arms and absf(shoulder.distance_to(elbow)-0.30)<0.00001 and absf(elbow.distance_to(wrist)-0.29)<0.00001
			elbows.append(r.to_local(elbow))
			var different: bool=skeleton.get_bone_pose(arm.upper)!=old_skeleton.get_bone_pose(arm.upper) or skeleton.get_bone_pose(arm.lower)!=old_skeleton.get_bone_pose(arm.lower) \
				or r._visual_rig._arms[index].hand.transform!=arm_control._visual_rig._arms[index].hand.transform
			changed.append(different)
			if index==1:far_arm_equal=far_arm_equal and not different
		var world_markers:=Authentic._markers(r._visual_rig)
		var old_markers:=Authentic._markers(arm_control._visual_rig)
		var markers: Array[Vector3]=[]
		for index: int in world_markers.size():
			markers.append(r.to_local(world_markers[index]))
			if index<3 or not changed[index-3]:unchanged_markers=unchanged_markers and world_markers[index]==old_markers[index]
		if previous_markers.size()==markers.size():
			for index: int in 2:
				if changed[index] or previous_changed[index]:
					maximum_changed_wrist=maxf(maximum_changed_wrist,previous_markers[index+3].distance_to(markers[index+3]))
					maximum_changed_elbow=maxf(maximum_changed_elbow,previous_elbows[index].distance_to(elbows[index]))
		previous_markers=markers;previous_elbows=elbows;previous_changed=changed
		if r._obstacle_manual_continuation:
			var skin:=Arm._vertices(r,skin_data)
			var old_skin:=Arm._vertices(arm_control,old_skin_data)
			skin_frames+=1
			arm_contained=arm_contained and skin.contained
			arm_clear=arm_clear and skin.panel_hits==0
			old_arm_hits+=int(old_skin.panel_hits)
		var sample:=Body._sample(r,data)
		attached=attached and sample.finite;seam=maxf(seam,sample.seam);joint=maxf(joint,sample.joint_gap)
		var support: Dictionary={}
		if r.manual_active or r._visual_rig._manual_blend>0.0001:
			support=_loaded(r,ray)
			supported=supported and support.valid
			loaded_min=minf(loaded_min,support.minimum);loaded_max=maxf(loaded_max,support.maximum)
		var step: float=r._obstacle_visual_offset.distance_to(previous_offset)
		maximum_offset_step=maxf(maximum_offset_step,step)
		if is_finite(previous_gap):continuous=continuous and step<=absf(old_gap-previous_gap)+0.002
		previous_offset=r._obstacle_visual_offset;previous_gap=old_gap
		camera_query.transform=Transform3D(Basis.IDENTITY,r._camera.global_position)
		camera_clear=camera_clear and r.get_world_3d().direct_space_state.intersect_shape(camera_query,1).is_empty()
		trace.append({"tick":tick,"manual":r.manual_active,"pitch":r._board_visual.rotation.x,"blend":r._visual_rig._manual_blend,
			"contact":contact,"gap":gap,"old_gap":old_gap,"offset":r._obstacle_visual_offset,"support":support})
		if impact>=0 and tick-impact>=55:break
	_release()
	check.call(requested and entered>=2.0 and active>=30 and events.size()==1 and events[0].id=="nose_manual"
		and events[0].points==int(Catalog.definition("nose_manual").base_points),
		"wall Manual: real held Push and fresh Manual earn the actual catalog Nose Manual above two metres per second")
	check.call(impact>=0 and precontact_fits>=3 and residual_fits>=15 and not r.bail_active and r.is_on_floor(),
		"wall Manual: finite board contact fits before capsule impact and continues the actually earned residual pivot")
	check.call(positive_skin_fit,
		"wall Manual: actual moving approach acquires inside positive native skin before the unfitted mesh penetrates")
	check.call(old_minimum< -0.11 and minimum>=0.0079 and maximum<=0.18,
		"wall Manual: actual board/shoe vertices retain eight-millimetre wall clearance through approach, native impact and residual within eighteen centimetres")
	check.call(supported and loaded_min>=0.0079 and loaded_max<=0.00901,
		"wall Manual: both catalog-loaded actual tyres retain their native flat plane and skin throughout active and every residual pose")
	check.call(physics and local_pose and bones,
		"wall Manual: full native state, balance, local axle pivot and every non-arm garment bone match the unfitted physical twin")
	check.call(attached and seam<0.08 and joint<0.06 and camera_clear,
		"wall Manual: actual skin-bound torso stays attached and the independent native camera endpoint remains clear")
	check.call(continuous,
		"wall Manual: wall-offset derivatives stay bounded by independently measured pose/physical approach changes without a release snap")
	var expected:=int(Catalog.definition("nose_manual").base_points)
	check.call(banks==[expected] and score.total_score==expected and score.get_combo_value()==0,
		"wall Manual: genuine entry and grounded link-exit signals bank the catalog score exactly once")
	check.call(skin_frames>=30 and old_arm_hits>0 and r._obstacle_arm_fit.accepted>0 and arm_clear,
		"wall Manual arms: actual original Skin/curl vertices clear the finite panel throughout earned active/residual fits while the same-root control intrudes")
	check.call(arm_root_equal and shoulders_equal and far_arm_equal and unchanged_markers,
		"wall Manual arms: physical/root/board/non-arm, exact shoulder origins and every unmodified marker match the fitted-root no-arm twin")
	check.call(fixed_arms and arm_contained and maximum_changed_wrist<0.22 and maximum_changed_elbow<0.22,
		"wall Manual arms: fixed .30/.29 lengths and conservative Skin/hand bounds preserve220mm changed-wrist/elbow continuity including first correction")
	check.call(query_ids==[r._grind_board_query.get_instance_id(),r._grind_board_box.get_instance_id(),r._recovery_floor_query.get_instance_id()] \
		and r._obstacle_arm_fit.maximum_calls<=12 and r._obstacle_arm_fit.maximum_shift<=0.20,
		"wall Manual arms: same three resources retain twelve-call and20cm wrist limits")
	print("WALL_MANUAL_ARM_RESULT ",{"skin_frames":skin_frames,"old_skin_hits":old_arm_hits,"arm_clear":arm_clear,"root_equal":arm_root_equal,
		"shoulders_equal":shoulders_equal,"far_arm_equal":far_arm_equal,"unchanged_markers":unchanged_markers,
		"fixed":fixed_arms,"contained":arm_contained,"maximum_changed_wrist":maximum_changed_wrist,"maximum_changed_elbow":maximum_changed_elbow,
		"accepted":r._obstacle_arm_fit.accepted,"maximum_calls":r._obstacle_arm_fit.maximum_calls,"maximum_shift":r._obstacle_arm_fit.maximum_shift})
	print("WALL_MANUAL_RESULT ",{"entry_speed":entered,"active_ticks":active,"impact":impact,"precontact_fits":precontact_fits,
		"residual_fits":residual_fits,"minimum":minimum,"old_minimum":old_minimum,"max_offset":maximum,
		"positive_skin_fit":positive_skin_fit,
		"loaded_minimum":loaded_min,"loaded_maximum":loaded_max,"supported":supported,"physics_equal":physics,"local_equal":local_pose,
		"bones_equal":bones,"seam":seam,"joint":joint,"continuous":continuous,"maximum_offset_step":maximum_offset_step,
		"banks":banks,"total":score.total_score,"camera_clear":camera_clear,"native_board_points":r._visual_rig.board_contact_geometry().convex_shape.points.size(),"trace":trace})
	f.viewport.queue_free();await tree.process_frame
	await _negatives(tree,check)
	await _ordinary_manual_arms(tree,check)
	var arm_controls:=ArmControls.new()
	await arm_controls.run(tree,check)

static func _negatives(tree: SceneTree,check: Callable) -> void:
	_release()
	var f: Dictionary=await Wall._fixture(tree,-8.0)
	var r: CharacterBody3D=f.rider
	var c: CharacterBody3D=f.control
	var requested:=false
	var fitted:=false
	Input.action_press("push",0.55)
	for tick: int in 180:
		if not requested and absf(r.speed)>=2.5 and r.global_position.z< -1.0:requested=true;Input.action_press("manual")
		await Wall._frames(tree,1)
		if r.manual_active and r._obstacle_visual_offset.length()>0.10:fitted=true;break
	_release()
	check.call(fitted and r._obstacle_manual_continuation and not Wall._wall_contact(r,f.wall),
		"wall Manual controls: declared negative geometry begins with an actual earned pre-capsule-contact loaded-axle fit")
	if not fitted:f.viewport.queue_free();await tree.process_frame;return
	for body: CharacterBody3D in [r,c]:body.set_physics_process(false)
	var base: Transform3D=c._visual.transform
	var prior: Vector3=r._obstacle_visual_offset
	var state:=Grade._physics(r)
	var board: Transform3D=r._board_visual.transform
	var rider_pose: Transform3D=r._rider_visual.transform
	r._grind_board_query.motion=Vector3(0.01,0.02,0.03)
	var queries:=Queries._query_state(r)
	var stable:=true
	var first:=Transform3D.IDENTITY
	for attempt: int in 12:
		r._visual.transform=base;r._place_obstacle_wheels(1.0/60.0)
		if attempt==0:first=r._visual.transform
		stable=stable and r._visual.transform.is_equal_approx(first) and Wall._plane_gap(r)>=0.0079
	check.call(stable and r._obstacle_visual_offset.length()<=0.18 and Queries._query_state(r)==queries,
		"wall Manual controls: repeated fits do not accumulate and restore all shape/ray fields including nonzero motion")
	r._visual.transform=base;r.manual_active=false;r._obstacle_manual_continuation=false;r._obstacle_visual_offset=prior
	r._place_obstacle_wheels(1.0/60.0)
	check.call(r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO and not r._obstacle_manual_continuation,
		"wall Manual controls: a saved ID and surviving blend cannot arm an unearned residual fit")
	r.manual_active=true
	var floor_body: Node3D=f.root.get_child(0)
	floor_body.rotation.x=0.12
	await Wall._frames(tree,2)
	_solve(r,base,prior)
	check.call(r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO and Queries._query_state(r)==queries,
		"wall Manual controls: actual graded loaded-axle support refuses the flat-only correction without changing pose")
	floor_body.rotation.x=0.0;floor_body.position.x+=8.0
	var one:=_block(f.root,Vector3(0.12,0.20,4),Vector3(0.115,-0.10,0))
	await Wall._frames(tree,2)
	_solve(r,base,prior)
	check.call(r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO and Queries._query_state(r)==queries,
		"wall Manual controls: finite support under only one loaded tyre refuses an edge backoff")
	one.queue_free();floor_body.position.x-=8.0
	await Wall._frames(tree,2)
	r._board_visual.position.z-=0.10
	_solve(r,base,prior)
	check.call(r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO and Queries._query_state(r)==queries,
		"wall Manual controls: a board needing more than eighteen centimetres gets no partial or widened correction")
	r._board_visual.transform=board
	var outer:=Vector3(-INF,0,0)
	for mesh: MeshInstance3D in r._visual_rig._board_meshes:
		for vertex: Vector3 in mesh.mesh.get_faces():
			var point:=mesh.to_global(vertex)
			if point.x>outer.x:outer=point
	var side:=_block(f.root,Vector3(0.04,0.10,0.45),outer)
	await Wall._frames(tree,2)
	_solve(r,base,prior)
	check.call(r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO and Queries._query_state(r)==queries,
		"wall Manual controls: a real secondary side-face corner refuses an unsafe partial wall fit")
	side.queue_free()
	await Wall._frames(tree,2)
	# The added wall shares the floor's RID but has its own native shape.
	# Keep its narrow face beyond each bearing ray, at the actual tyre edge.
	var compound:=CollisionShape3D.new()
	var compound_box:=BoxShape3D.new();compound_box.size=Vector3(0.008,0.10,0.45)
	compound.shape=compound_box;floor_body.add_child(compound)
	compound.global_position=outer+Vector3(0.002,0,0)
	await Wall._frames(tree,2)
	var ray:=PhysicsRayQueryParameters3D.new();ray.collision_mask=1|8;ray.exclude=[r.get_rid(),c.get_rid()]
	r._visual.transform=base
	var compound_support:=_loaded(r,ray)
	_solve(r,base,prior)
	check.call(compound_support.valid and r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO
		and Queries._query_state(r)==queries,
		"wall Manual controls: native flat tyre rays cannot bless a separate wall shape sharing the floor body's RID")
	compound.queue_free();await Wall._frames(tree,2)
	var bearing:=Vector3.ZERO
	for wheel: Dictionary in r._visual_rig.board_contact_geometry().wheels:
		if Vector3(wheel.center).z<0.0:
			bearing=r._board_visual.to_global(wheel.center)+prior
			break
	var raised:=_block(f.root,Vector3(0.008,0.001,0.02),Vector3(bearing.x+0.01,0.0005,bearing.z))
	await Wall._frames(tree,2)
	_solve(r,base,prior)
	check.call(r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO and Queries._query_state(r)==queries,
		"wall Manual controls: a one-millimetre raised blocker remains unsafe despite harmless native floor touching")
	raised.queue_free();await Wall._frames(tree,2)
	var foot: Node3D=r._visual_rig._legs[0].foot
	var foot_pose:=foot.transform
	foot.position.y-=0.20
	var unchanged_axle:=_loaded(r,ray)
	_solve(r,base,prior)
	check.call(unchanged_axle.valid and r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO
		and Queries._query_state(r)==queries,
		"wall Manual controls: complete shoe-envelope floor penetration is refused even when both loaded tyre rays stay valid")
	foot.transform=foot_pose
	floor_body.position.x+=8.0
	var unsupported:=StaticBody3D.new();f.root.add_child(unsupported)
	var boundary:=WorldBoundaryShape3D.new();boundary.plane=Plane(Vector3.UP,0)
	var boundary_collision:=CollisionShape3D.new();boundary_collision.shape=boundary;unsupported.add_child(boundary_collision)
	await Wall._frames(tree,2)
	var boundary_support:=_loaded(r,ray)
	_solve(r,base,prior)
	check.call(boundary_support.valid and r._visual.transform==base and r._obstacle_visual_offset==Vector3.ZERO
		and Queries._query_state(r)==queries,
		"wall Manual controls: an unsupported native floor primitive is conservatively refused despite valid flat tyre hits")
	unsupported.queue_free();floor_body.position.x-=8.0
	f.wall.position.x=8.0
	await Wall._frames(tree,2)
	r._obstacle_manual_continuation=true;r._obstacle_visual_offset=prior
	var previous:=prior.length()
	var decays:=true
	for tick: int in 18:
		r._visual.transform=base;r._place_obstacle_wheels(1.0/60.0)
		decays=decays and r._obstacle_visual_offset.length()<=previous+0.000001
		previous=r._obstacle_visual_offset.length()
	check.call(decays and previous<0.0003 and Queries._query_state(r)==queries,
		"wall Manual controls: removing the finite wall releases the fitted offset without retaining an infinite plane")
	check.call(Grade._physics(r)==state and r._board_visual.transform==board and r._rider_visual.transform==rider_pose,
		"wall Manual controls: accepted/refused solvers preserve the actual physical body and local articulated pivot")
	var all_restored:=Queries._query_state(r)==queries
	r._obstacle_manual_continuation=true;r._obstacle_visual_offset=prior;r.begin_bail("manual_wall_control")
	check.call(r.bail_active and not r._obstacle_manual_continuation and r._obstacle_visual_offset==Vector3.ZERO,
		"wall Manual controls: actual bail clears Manual wall provenance before recovery")
	r.reset_skater()
	check.call(not r.bail_active and not r._obstacle_manual_continuation and r._obstacle_visual_offset==Vector3.ZERO and r._visual.position==Vector3.ZERO,
		"wall Manual controls: actual restart clears Manual wall provenance and restores neutral presentation")
	print("WALL_MANUAL_NEGATIVES ",{"stable":stable,"removed_decay":previous,"query_restored":all_restored})
	f.viewport.queue_free();await tree.process_frame;_release()

static func _solve(r: CharacterBody3D,base: Transform3D,prior: Vector3) -> void:
	r._visual.transform=base;r._obstacle_visual_offset=prior;r._obstacle_manual_continuation=true
	r._place_obstacle_wheels(1.0/60.0)

static func _block(parent: Node3D,size: Vector3,at: Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new();parent.add_child(body)
	var shape:=BoxShape3D.new();shape.size=size
	var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision);body.global_position=at
	return body

static func _loaded(r: CharacterBody3D,ray: PhysicsRayQueryParameters3D) -> Dictionary:
	var load_sign:=float(Catalog.definition(r.manual_trick_id).get("manual_sign",0.0))
	var count:=0
	var minimum:=INF
	var maximum:=-INF
	var valid:=absf(load_sign)==1.0 and signf(load_sign)==signf(r._board_visual.rotation.x)
	for wheel: Dictionary in r._visual_rig.board_contact_geometry().wheels:
		if Vector3(wheel.center).z*load_sign<=0.0:continue
		count+=1
		var bearing: Vector3=r._board_visual.to_global(wheel.center)
		ray.from=bearing+Vector3.UP*0.35;ray.to=bearing-Vector3.UP*0.50
		var hit:=r.get_world_3d().direct_space_state.intersect_ray(ray)
		var clear:=not hit.is_empty() and Vector3(hit.get("normal",Vector3.ZERO)).y>0.999 \
			and absf(Vector3(hit.get("position",Vector3.INF)).y)<0.001
		valid=valid and clear
		var gap:=INF
		if clear:
			for vertex: Vector3 in wheel.points:gap=minf(gap,(r._board_visual.to_global(vertex)-Vector3(hit.position)).dot(hit.normal))
		minimum=minf(minimum,gap);maximum=maxf(maximum,gap)
	return {"valid":valid and count==2,"minimum":minimum,"maximum":maximum}

static func _skin_phase_fixture(tree: SceneTree) -> Dictionary:
	var viewport:=SubViewport.new()
	viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var root:=Node3D.new();viewport.add_child(root)
	var terrain:=Wall.Terrain.new()
	terrain.add_patch(root,"FiniteFlat",Rect2(-4,-8,8,16),Vector4.ZERO,StandardMaterial3D.new())
	var gate:=Gate.new();root.add_child(gate)
	gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),3.0)
	var wall: Node3D=gate._panel
	var rider:=Wall.Skater.new()
	var control:=Wall.UnfittedSkater.new()
	var arm_control:=Wall.Skater.new();arm_control._obstacle_arm_fit=Arm.NoArmFit.new()
	for body: CharacterBody3D in [rider,control,arm_control]:
		body.spawn_position=Vector3(0,0.04,-3.02);root.add_child(body);body.rotation.y=PI
	await Wall._frames(tree,4)
	return {"viewport":viewport,"root":root,"rider":rider,"control":control,"arm_control":arm_control,"wall":wall,"gate":gate}

static func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)

static func _ordinary_manual_arms(tree: SceneTree,check: Callable) -> void:
	Wall.Setup.register_actions();Wall._release()
	var viewport:=SubViewport.new();viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
	var scene:=Node3D.new();viewport.add_child(scene)
	var floor:=StaticBody3D.new();scene.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
	var solid:=CollisionShape3D.new();solid.shape=shape;solid.position.y=-0.1;floor.add_child(solid)
	var gate:=Gate.new();scene.add_child(gate)
	gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	var rider:=Wall.Skater.new()
	var control:=Wall.Skater.new();control._obstacle_arm_fit=Arm.NoArmFit.new()
	for actor: CharacterBody3D in [rider,control]:
		actor.spawn_position=Vector3(0,0.04,-6.0);scene.add_child(actor);actor.rotation.y=PI
	var data:=Arm._skin_data(rider,gate)
	var old_data:=Arm._skin_data(control,gate)
	var attachment:=Body._prepare(rider._visual_rig)
	var score:=Score.new();var old_score:=Score.new()
	var events: Array[Dictionary]=[];var old_events: Array[Dictionary]=[]
	var banks: Array[int]=[];var old_banks: Array[int]=[]
	rider.trick_performed.connect(func(label: String,points: int):
		events.append({"id":rider.last_trick_id,"points":points});score.add_trick(label,points,rider.last_trick_id))
	control.trick_performed.connect(func(label: String,points: int):
		old_events.append({"id":control.last_trick_id,"points":points});old_score.add_trick(label,points,control.last_trick_id))
	rider.combo_link_started.connect(score.continue_combo);rider.combo_link_ended.connect(score.begin_landing)
	control.combo_link_started.connect(old_score.continue_combo);control.combo_link_ended.connect(old_score.begin_landing)
	var ray:=PhysicsRayQueryParameters3D.new();ray.collision_mask=1|8;ray.exclude=[rider.get_rid(),control.get_rid()]
	await Wall._frames(tree,4)
	var release_tick:=-1;var request_tick:=-1;var impact:=-1
	var entry_speed:=0.0;var active_ticks:=0;var active_fits:=0;var precontact_active_fits:=0;var residual_fits:=0
	var physical:=true;var local_pose:=true;var nonarm:=true;var loaded:=true
	var loaded_min:=INF;var loaded_max:=-INF
	var max_skin_hits:=0;var old_max_skin_hits:=0;var contained:=true
	var cloth:=true;var minimum_gap:=INF
	var samples: Array[Dictionary]=[]
	var resources: Array[int]=[rider._grind_board_query.get_instance_id(),rider._grind_board_box.get_instance_id(),rider._recovery_floor_query.get_instance_id()]
	var motion: Dictionary={"candidate_world_peak":0.0,"baseline_world_peak":0.0,"candidate_body_peak":0.0,"baseline_body_peak":0.0,"candidate_root_peak":0.0,"baseline_root_peak":0.0,
		"candidate_arm_body_peak":0.0,"baseline_arm_body_peak":0.0,"changed_arm_body_peak":0.0,
		"candidate_arm_world_peak":0.0,"baseline_arm_world_peak":0.0,"changed_arm_world_peak":0.0,
		"candidate_arm_root_peak":0.0,"baseline_arm_root_peak":0.0,"changed_arm_root_peak":0.0,
		"exact_unaffected_world":true,"exact_unaffected_body":true,"exact_unaffected_root":true,"exact_shoulders_world":true,"exact_shoulders_body":true,"exact_shoulders_root":true,
		"exact_shoulders_local":true,"maximum_shoulder_world_delta":0.0,"maximum_shoulder_body_delta":0.0,"maximum_shoulder_local_delta":0.0,"maximum_shoulder_root_delta":0.0,
		"exact_far_elbow_world":true,"exact_far_elbow_body":true,"exact_far_elbow_root":true,"exact_common_root":true}
	var previous: Dictionary=_motion_markers(rider)
	var old_previous: Dictionary=_motion_markers(control)
	Input.action_press("push",0.55)
	for tick: int in 220:
		if release_tick<0 and absf(rider.speed)>=4.5 and rider.global_position.z< -2.0:
			release_tick=tick;Input.action_release("push")
		elif release_tick>=0 and request_tick<0 and tick-release_tick>=12:
			# Twelve actual neutral physics ticks also expire the18/100s
			# directional memory; the fresh Manual uses real neutral input.
			request_tick=tick;Input.action_press("manual")
		await Wall._frames(tree,1)
		var bank:=score.tick(1.0/60.0);var old_bank:=old_score.tick(1.0/60.0)
		if bank>0:banks.append(bank)
		if old_bank>0:old_banks.append(old_bank)
		if rider.manual_active:
			if active_ticks==0:entry_speed=absf(rider.speed)
			active_ticks+=1
		if impact<0 and Wall._wall_contact(rider,gate._panel):
			impact=tick;Input.action_press("brake")
		physical=physical and Grade._physics(rider)==Grade._physics(control) and rider._visual.transform==control._visual.transform
		local_pose=local_pose and rider._board_visual.transform==control._board_visual.transform and rider._rider_visual.transform==control._rider_visual.transform
		nonarm=nonarm and Arm._nonarm(rider)==Arm._nonarm(control)
		var current: Dictionary=_motion_markers(rider)
		var old_current: Dictionary=_motion_markers(control)
		_track_motion(motion,previous,current,old_previous,old_current,tick)
		previous=current;old_previous=old_current
		minimum_gap=minf(minimum_gap,Wall._plane_gap(rider))
		if rider.manual_active or rider._visual_rig._manual_blend>0.0001:
			var support:=_loaded(rider,ray)
			loaded=loaded and support.valid;loaded_min=minf(loaded_min,support.minimum);loaded_max=maxf(loaded_max,support.maximum)
		if rider._obstacle_manual_continuation:
			active_fits+=int(rider.manual_active);precontact_active_fits+=int(rider.manual_active and impact<0);residual_fits+=int(not rider.manual_active)
			var skin:=Arm._vertices(rider,data);var old_skin:=Arm._vertices(control,old_data)
			max_skin_hits=maxi(max_skin_hits,int(skin.panel_hits));old_max_skin_hits=maxi(old_max_skin_hits,int(old_skin.panel_hits));contained=contained and skin.contained
			var body:=Body._sample(rider,attachment)
			cloth=cloth and body.finite and body.seam<0.12 and body.joint_gap<0.10 and body.neck_gap<0.05
			if samples.is_empty() or (impact>=0 and tick-impact==20):
				samples.append({"tick":tick,"impact":impact,"position":rider.global_position,"velocity":rider.velocity,
					"manual_id":rider.manual_trick_id,"active":rider.manual_active,"blend":rider._visual_rig._manual_blend,
					"root_offset":rider._obstacle_visual_offset,"native_skin":skin,"old_native_skin":old_skin})
		if impact>=0 and tick-impact>=60:break
	Wall._release()
	var expected:=int(Catalog.definition("manual").base_points)
	check.call(release_tick>=0 and request_tick-release_tick>=12 and entry_speed>=2.0 and events==[{"id":"manual","points":expected}],
		"ordinary Manual: actual Push release, twelve neutral rolling ticks and fresh Manual earn the genuine neutral catalog ID")
	check.call(impact>=0 and active_fits==2 and precontact_active_fits==1 and residual_fits>=15 and rider.is_on_floor() and not rider.bailing,
		"ordinary Manual: the observed fast coast has one precontact and one impact active fitted tick plus the earned residual axle fit")
	check.call(loaded and loaded_min>=0.0079 and loaded_max<=0.00901 and minimum_gap>=0.0079,
		"ordinary Manual: actual catalog-loaded rear tyres and board/shoes retain native8mm support and wall clearance")
	check.call(physical and local_pose and nonarm,
		"ordinary Manual: exact native body/balance/root/local board/rider and every non-arm bone match the current physical twin")
	check.call(events==old_events and banks==[expected] and old_banks==banks and score.total_score==expected and old_score.total_score==expected,
		"ordinary Manual: both genuine event streams bank catalog100 exactly once")
	check.call(max_skin_hits==0 and old_max_skin_hits>0 and contained and cloth,
		"ordinary Manual: original Skin/curl clears the finite panel during earned fits while the no-arm twin intrudes, with contained envelopes and attached clothes")
	check.call(resources==[rider._grind_board_query.get_instance_id(),rider._grind_board_box.get_instance_id(),rider._recovery_floor_query.get_instance_id()] \
		and rider._obstacle_arm_fit.maximum_calls<=12 and rider._obstacle_arm_fit.maximum_shift<=0.20,
		"ordinary Manual: original shared resources and twelve-call/20cm free-wrist caps remain bounded")
	# The first proposal wrongly called actor-relative root backoff an arm
	# teleport. Retain that raw256.631mm peak; constrain BOTH actual world
	# travel and pose inside the exact common visual root to the original220mm.
	check.call(motion.exact_common_root and motion.exact_unaffected_world and motion.exact_unaffected_body and motion.exact_unaffected_root
		and motion.exact_far_elbow_world and motion.exact_far_elbow_body and motion.exact_far_elbow_root
		and motion.exact_shoulders_world and motion.exact_shoulders_body and motion.exact_shoulders_root and motion.exact_shoulders_local
		and float(motion.changed_arm_world_peak)<0.22 and float(motion.changed_arm_root_peak)<0.22,
		"ordinary Manual: exact common-root/head/feet/far-arm/shoulder parity with first changed wrist/elbow transitions within220mm in world AND common visual-root pose")
	print("ORDINARY_MANUAL_INPUT ",{"candidate":"production","release_tick":release_tick,"request_tick":request_tick,"entry_speed":entry_speed,
		"impact":impact,"active_ticks":active_ticks,"active_fits":active_fits,"precontact_active_fits":precontact_active_fits,"residual_fits":residual_fits,
		"loaded_min":loaded_min,"loaded_max":loaded_max,"minimum_board_shoe_gap":minimum_gap,
		"physical":physical,"local_pose":local_pose,"nonarm":nonarm,"skin_hits":max_skin_hits,"old_skin_hits":old_max_skin_hits,
		"accepted":rider._obstacle_arm_fit.accepted,"refused":rider._obstacle_arm_fit.refused,"maximum_calls":rider._obstacle_arm_fit.maximum_calls,
		"maximum_shift":rider._obstacle_arm_fit.maximum_shift,"motion":motion,"events":events,"old_events":old_events,"banks":banks,"old_banks":old_banks,"samples":samples})
	viewport.queue_free();await tree.process_frame

static func _motion_markers(actor: CharacterBody3D) -> Dictionary:
	var rig: RefCounted=actor._visual_rig
	var skeleton: Skeleton3D=rig._garments.skeleton
	var world: Array[Vector3]=Authentic._markers(rig)
	var body: Array[Vector3]=[];var root_pose: Array[Vector3]=[]
	for point: Vector3 in world:body.append(actor.to_local(point));root_pose.append(actor._visual.to_local(point))
	var arm_world: Array[Vector3]=[];var arm_body: Array[Vector3]=[];var arm_root: Array[Vector3]=[]
	var shoulder_world: Array[Vector3]=[];var shoulder_body: Array[Vector3]=[];var shoulder_local: Array[Vector3]=[];var shoulder_root: Array[Vector3]=[]
	for index: int in 2:
		var side: String="left" if index==0 else "right"
		var upper: int=skeleton.find_bone(side+"_sleeve")
		var lower: int=skeleton.find_bone(side+"_forearm")
		var shoulder: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(upper).origin
		var elbow: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(lower).origin
		var wrist: Vector3=rig._arms[index].hand.global_position
		shoulder_world.append(shoulder);shoulder_body.append(actor.to_local(shoulder));shoulder_local.append(skeleton.get_bone_global_pose(upper).origin);shoulder_root.append(actor._visual.to_local(shoulder))
		for point: Vector3 in [elbow,wrist]:arm_world.append(point);arm_body.append(actor.to_local(point));arm_root.append(actor._visual.to_local(point))
	var frame: Transform3D=actor._visual.global_transform
	var rows: Array[Vector3]=[frame.basis.x,frame.basis.y,frame.basis.z,frame.origin]
	return {"world":world,"body":body,"root":root_pose,"arm_world":arm_world,"arm_body":arm_body,"arm_root":arm_root,
		"shoulder_world":shoulder_world,"shoulder_body":shoulder_body,"shoulder_local":shoulder_local,"shoulder_root":shoulder_root,
		"root_frame":rows,"actor_origin":actor.global_position}

static func _track_motion(metrics: Dictionary,previous: Dictionary,current: Dictionary,old_previous: Dictionary,old_current: Dictionary,tick: int) -> void:
	metrics.exact_common_root=metrics.exact_common_root and current.root_frame==old_current.root_frame
	for space: String in ["world","body","root"]:
		var now: Array[Vector3]=current[space];var before: Array[Vector3]=previous[space]
		var old_now: Array[Vector3]=old_current[space];var old_before: Array[Vector3]=old_previous[space]
		for index: int in now.size():
			_peak(metrics,"candidate_"+space+"_peak",before[index].distance_to(now[index]),tick,index)
			_peak(metrics,"baseline_"+space+"_peak",old_before[index].distance_to(old_now[index]),tick,index)
		# Actual marker order: head, left/right foot, left/right hand.
		for index: int in [0,1,2,4]:metrics["exact_unaffected_"+space]=metrics["exact_unaffected_"+space] and now[index]==old_now[index]
		var arms: Array[Vector3]=current["arm_"+space];var old_arms: Array[Vector3]=old_current["arm_"+space]
		metrics["exact_far_elbow_"+space]=metrics["exact_far_elbow_"+space] and arms[2]==old_arms[2]
	for space: String in ["world","body","local","root"]:
		var shoulders: Array[Vector3]=current["shoulder_"+space];var old_shoulders: Array[Vector3]=old_current["shoulder_"+space]
		for index: int in shoulders.size():
			if shoulders[index]!=old_shoulders[index] and not metrics.has("first_shoulder_difference_"+space):
				metrics["first_shoulder_difference_"+space]={"tick":tick,"side":index,"candidate":shoulders[index],"baseline":old_shoulders[index]}
			metrics["exact_shoulders_"+space]=metrics["exact_shoulders_"+space] and shoulders[index]==old_shoulders[index]
			metrics["maximum_shoulder_"+space+"_delta"]=maxf(float(metrics["maximum_shoulder_"+space+"_delta"]),shoulders[index].distance_to(old_shoulders[index]))
	for space: String in ["world","body","root"]:
		var arms: Array[Vector3]=current["arm_"+space];var before: Array[Vector3]=previous["arm_"+space]
		var old_arms: Array[Vector3]=old_current["arm_"+space];var old_before: Array[Vector3]=old_previous["arm_"+space]
		for index: int in arms.size():
			_peak(metrics,"candidate_arm_"+space+"_peak",before[index].distance_to(arms[index]),tick,index)
			_peak(metrics,"baseline_arm_"+space+"_peak",old_before[index].distance_to(old_arms[index]),tick,index)
			# Both first correction and return to baseline remain in the bound.
			if arms[index]!=old_arms[index] or before[index]!=old_before[index]:
				_peak(metrics,"changed_arm_"+space+"_peak",before[index].distance_to(arms[index]),tick,index)
				if not metrics.has("first_changed_arm"):
					metrics.first_changed_arm={"tick":tick,"marker":index,"previous_world":previous.arm_world,"current_world":current.arm_world,"baseline_previous_world":old_previous.arm_world,"baseline_world":old_current.arm_world,
						"previous_actor_relative":previous.arm_body,"current_actor_relative":current.arm_body,"baseline_actor_relative":old_current.arm_body,
						"previous_root_pose":previous.arm_root,"current_root_pose":current.arm_root,"baseline_root_pose":old_current.arm_root,
						"previous_common_root":previous.root_frame,"current_common_root":current.root_frame,
						"previous_actor_origin":previous.actor_origin,"current_actor_origin":current.actor_origin}

static func _peak(metrics: Dictionary,key: String,value: float,tick: int,index: int) -> void:
	if value>float(metrics[key]):
		metrics[key]=value;metrics[key+"_at"]={"tick":tick,"marker":index}
