extends RefCounted
## Earned moving Nose Manual, finite loaded axle and the real residual pivot.
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Queries=preload("res://tests/skater_wall_grab_tests.gd")
const Grade=preload("res://tests/pt24_manual_grade_tests.gd")
const Catalog=preload("res://game/tricks/trick_catalog.gd")
const Score=preload("res://game/scoring/score_session.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	Wall.Setup.register_actions()
	_release()
	# Twenty millimetres of initial spawn phase gives a native moving frame
	# inside the existing skin before the unfitted mesh actually penetrates.
	var f: Dictionary=await _skin_phase_fixture(tree)
	var r: CharacterBody3D=f.rider
	var c: CharacterBody3D=f.control
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
		for index: int in r._visual_rig._garments.skeleton.get_bone_count():
			bones=bones and r._visual_rig._garments.skeleton.get_bone_pose(index)==c._visual_rig._garments.skeleton.get_bone_pose(index)
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
		"wall Manual: full native state, balance, local axle pivot and every garment bone match the unfitted physical twin")
	check.call(attached and seam<0.08 and joint<0.06 and camera_clear,
		"wall Manual: actual skin-bound torso stays attached and the independent native camera endpoint remains clear")
	check.call(continuous,
		"wall Manual: wall-offset derivatives stay bounded by independently measured pose/physical approach changes without a release snap")
	var expected:=int(Catalog.definition("nose_manual").base_points)
	check.call(banks==[expected] and score.total_score==expected and score.get_combo_value()==0,
		"wall Manual: genuine entry and grounded link-exit signals bank the catalog score exactly once")
	print("WALL_MANUAL_RESULT ",{"entry_speed":entered,"active_ticks":active,"impact":impact,"precontact_fits":precontact_fits,
		"residual_fits":residual_fits,"minimum":minimum,"old_minimum":old_minimum,"max_offset":maximum,
		"positive_skin_fit":positive_skin_fit,
		"loaded_minimum":loaded_min,"loaded_maximum":loaded_max,"supported":supported,"physics_equal":physics,"local_equal":local_pose,
		"bones_equal":bones,"seam":seam,"joint":joint,"continuous":continuous,"maximum_offset_step":maximum_offset_step,
		"banks":banks,"total":score.total_score,"camera_clear":camera_clear,"trace":trace})
	f.viewport.queue_free();await tree.process_frame
	await _negatives(tree,check)

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
	side.queue_free();f.wall.position.x=8.0
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
	var wall:=StaticBody3D.new();root.add_child(wall)
	var shape:=BoxShape3D.new();shape.size=Vector3(3,2.8,0.18)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=1.4;wall.add_child(collision)
	var rider:=Wall.Skater.new()
	var control:=Wall.UnfittedSkater.new()
	for body: CharacterBody3D in [rider,control]:
		body.spawn_position=Vector3(0,0.04,-3.02);root.add_child(body);body.rotation.y=PI
	await Wall._frames(tree,4)
	return {"viewport":viewport,"root":root,"rider":rider,"control":control,"wall":wall}

static func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
