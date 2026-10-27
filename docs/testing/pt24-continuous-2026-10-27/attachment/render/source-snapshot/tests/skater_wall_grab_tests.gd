extends RefCounted
## Native wall-stop/Ollie/Grab with unchanged physical and local-pose twin.
const Wall = preload("res://tests/skater_wall_presentation_tests.gd")
const Body = preload("res://tests/skater_body_attachment_tests.gd")
const Score = preload("res://game/scoring/score_session.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")

static func run(tree: SceneTree, check: Callable) -> void:
	Wall.Setup.register_actions()
	_release()
	var f: Dictionary=await Wall._fixture(tree,-8.0)
	var rider: CharacterBody3D=f.rider
	var control: CharacterBody3D=f.control
	var data:=Body._prepare(rider._visual_rig)
	var score:=Score.new()
	var entries: Array[Dictionary]=[]
	var banks: Array[int]=[]
	var on_trick:=func(label: String,points: int):
		entries.append({"id":rider.last_trick_id,"label":label,"points":points})
		score.add_trick(label,points,rider.last_trick_id)
	var on_land:=func(ok: bool):
		if ok:score.begin_landing()
		else:score.drop_combo()
	rider.trick_performed.connect(on_trick)
	rider.landed.connect(on_land)
	rider.combo_link_started.connect(score.continue_combo)
	rider.combo_link_ended.connect(score.begin_landing)
	var reached:=false
	Input.action_press("push",0.55)
	for tick: int in 180:
		await Wall._frames(tree,1)
		if Wall._wall_contact(rider,f.wall):reached=true;break
	_release()
	Input.action_press("brake")
	await Wall._frames(tree,20)
	_release()
	await Wall._frames(tree,2)
	Input.action_press("ollie")
	await Wall._frames(tree,20)
	Input.action_release("ollie")
	await Wall._frames(tree,2)
	var prior: Vector3=rider._obstacle_visual_offset
	check.call(reached and rider.airborne and prior.length()>0.10 and Wall._plane_gap(rider)>=0.0079,
		"wall Grab: actual Push/Brake and released Ollie start flight with a proven finite connected fit")
	var minimum:=INF
	var old_minimum:=INF
	var max_offset:=prior.length()
	var active_ticks:=0
	var physics_equal:=true
	var pose_equal:=true
	var finite:=true
	var seam:=0.0
	var joint:=0.0
	var bailing:=false
	var trace: Array[Dictionary]=[]
	Input.action_press("grab")
	for tick: int in 90:
		if tick==6:Input.action_release("grab")
		await Wall._frames(tree,1)
		var bank:=score.tick(1.0/60.0)
		if bank>0:banks.append(bank)
		var sample:=Body._sample(rider,data)
		finite=finite and sample.finite
		seam=maxf(seam,sample.seam)
		joint=maxf(joint,sample.joint_gap)
		var gap:=Wall._plane_gap(rider)
		minimum=minf(minimum,gap)
		old_minimum=minf(old_minimum,Wall._plane_gap(control))
		max_offset=maxf(max_offset,rider._obstacle_visual_offset.length())
		physics_equal=physics_equal and Wall._physics(rider)==Wall._physics(control)
		pose_equal=pose_equal and rider._board_visual.transform==control._board_visual.transform \
			and rider._rider_visual.transform==control._rider_visual.transform
		active_ticks+=int(rider._grab_remaining>0)
		bailing=bailing or rider.bail_active
		trace.append({"tick":tick,"active":rider._grab_remaining>0,"air":rider.airborne,
			"gap":gap,"offset":rider._obstacle_visual_offset,"at":rider.global_position})
	_release()
	check.call(active_ticks>=10 and entries.size()==2 and entries[0].id=="ollie" and entries[1].id=="melon_grab" \
		and entries[0].points==int(Catalog.definition("ollie").base_points) \
		and entries[1].points==int(Catalog.definition("melon_grab").base_points),
		"wall Grab: fresh mapped Grab performs one real catalog Melon Grab after the earned Ollie")
	check.call(old_minimum< -0.10 and minimum>=0.0079 and max_offset<=0.18,
		"wall Grab: actual board/shoe vertices retain eight-millimetre wall clearance throughout Grab, catch and landing")
	check.call(physics_equal and pose_equal and rider.is_on_floor() and not bailing,
		"wall Grab: native motion and local rider/deck pose match the unfitted twin through the real supported landing")
	check.call(finite and seam<0.12 and joint<0.10,
		"wall Grab: the actual Skin-bound torso and trousers stay connected under the shared visual translation")
	var expected: int=(int(Catalog.definition("ollie").base_points)+int(Catalog.definition("melon_grab").base_points))*2
	check.call(banks==[expected] and score.total_score==expected and score.get_combo_value()==0,
		"wall Grab: real native trick/landing signals bank the independently derived two-entry combo exactly once")
	print("WALL_GRAB_RESULT ",{"minimum":minimum,"old_minimum":old_minimum,"maximum_offset":max_offset,
		"active_ticks":active_ticks,"physics_equal":physics_equal,"pose_equal":pose_equal,
		"seam":seam,"joint":joint,"finite":finite,"entries":entries,"banks":banks,"total":score.total_score,"trace":trace})
	rider.trick_performed.disconnect(on_trick)
	rider.landed.disconnect(on_land)
	f.viewport.queue_free()
	await tree.process_frame
	await _negative_controls(tree,check)

static func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)


static func _negative_controls(tree: SceneTree,check: Callable) -> void:
	_release()
	var f: Dictionary=await Wall._fixture(tree,-8.0)
	var rider: CharacterBody3D=f.rider
	var control: CharacterBody3D=f.control
	var reached:=false
	Input.action_press("push",0.55)
	for tick: int in 180:
		await Wall._frames(tree,1)
		if Wall._wall_contact(rider,f.wall):reached=true;break
	_release()
	Input.action_press("brake")
	await Wall._frames(tree,20)
	_release()
	await Wall._frames(tree,2)
	Input.action_press("ollie")
	await Wall._frames(tree,20)
	Input.action_release("ollie")
	await Wall._frames(tree,2)
	Input.action_press("grab")
	await Wall._frames(tree,9)
	_release()
	for body: CharacterBody3D in [rider,control]:body.set_physics_process(false)
	var prior: Vector3=rider._obstacle_visual_offset
	var base: Transform3D=control._visual.transform
	var physics:=Wall._physics(rider)
	var local_board: Transform3D=rider._board_visual.transform
	var local_rider: Transform3D=rider._rider_visual.transform
	check.call(reached and rider.airborne and rider._grab_remaining>0.0 and prior.length()>0.13,
		"wall Grab controls: frozen negative geometry starts from an actual late mapped Melon pose with native wall/Ollie evidence")
	rider._visual.transform=base
	var query: PhysicsShapeQueryParameters3D=rider._grind_board_query
	query.motion=Vector3(0.01,0.02,0.03)
	var state:=_query_state(rider)
	var fit: Vector3=rider._obstacle_grab_air_offset(prior)
	check.call(fit.length()>0.13 and fit.length()<=0.18 and _query_state(rider)==state,
		"wall Grab controls: accepted live face derivation restores every shared shape and ray query field including nonzero motion")
	var stable:=true
	var safe:=true
	var first:=Transform3D.IDENTITY
	for attempt: int in 12:
		rider._visual.transform=base
		rider._place_obstacle_wheels(1.0/60.0)
		if attempt==0:first=rider._visual.transform
		stable=stable and rider._visual.transform.is_equal_approx(first)
		safe=safe and Wall._plane_gap(rider)>=0.0079 and rider._obstacle_visual_offset.length()<=0.18
	check.call(stable and safe and _query_state(rider)==state,
		"wall Grab controls: repeated late-pose solves do not accumulate displacement or mutate the reused native queries")
	query.motion=Vector3.ZERO
	state=_query_state(rider)
	rider._visual.transform=base
	rider._obstacle_visual_offset=prior
	rider._obstacle_ollie_continuation=false
	rider._place_obstacle_wheels(1.0/60.0)
	check.call(rider._visual.transform==base and rider._obstacle_visual_offset==Vector3.ZERO
		and rider._obstacle_grab_air_offset(prior)==Vector3.ZERO,
		"wall Grab controls: an unarmed active airborne Grab cannot manufacture a new wall fit")
	rider._obstacle_ollie_continuation=true
	rider._obstacle_visual_offset=prior
	var board_pose: Transform3D=rider._board_visual.transform
	rider._board_visual.position.z-=0.08
	var ceiling_clear: bool=rider._obstacle_air_clear(prior.normalized()*0.18)
	rider._place_obstacle_wheels(1.0/60.0)
	check.call(not ceiling_clear and rider._visual.transform==base and rider._obstacle_visual_offset==Vector3.ZERO
		and _query_state(rider)==state,
		"wall Grab controls: an actual envelope needing more than eighteen centimetres refuses before casting and restores all query fields")
	rider._board_visual.transform=board_pose
	rider._obstacle_ollie_continuation=true
	rider._obstacle_visual_offset=prior
	# Rotate only the declared finite wall in this paused geometry control.
	# Its live oblique face intersects the pose; its ceiling remains clear.
	f.wall.rotation.y=0.15
	await Wall._frames(tree,2)
	var oblique_ceiling: bool=rider._obstacle_air_clear(prior.normalized()*0.18)
	var oblique_contact: bool=not rider._obstacle_air_clear(Vector3.ZERO)
	var refused: Vector3=rider._obstacle_grab_air_offset(prior)
	check.call(oblique_ceiling and oblique_contact and refused==Vector3.ZERO and _query_state(rider)==state,
		"wall Grab controls: a live oblique face cannot authorize extra translation along a mismatched prior axis")
	f.wall.rotation.y=0.0
	# A second finite side face makes a real corner outside the capsule.
	# Its overlap spans the entire allowed axis interval, so no partial
	# one-wall fit may be applied even though the original face is aligned.
	var side := StaticBody3D.new()
	f.root.add_child(side)
	var side_shape := BoxShape3D.new()
	side_shape.size=Vector3(0.04,0.10,0.45)
	var side_collision := CollisionShape3D.new()
	side_collision.shape=side_shape
	side.add_child(side_collision)
	var outer := Vector3(-INF,0,0)
	for mesh: MeshInstance3D in rider._visual_rig._board_meshes:
		for vertex: Vector3 in mesh.mesh.get_faces():
			var point: Vector3=mesh.to_global(vertex)
			if point.x>outer.x:outer=point
	side.global_position=outer
	await Wall._frames(tree,2)
	rider._visual.transform=base
	rider._obstacle_ollie_continuation=true
	rider._obstacle_visual_offset=prior
	var corner_ceiling: bool=rider._obstacle_air_clear(prior.normalized()*0.18)
	rider._place_obstacle_wheels(1.0/60.0)
	check.call(not corner_ceiling and rider._obstacle_visual_offset==Vector3.ZERO
		and rider._visual.transform==base and _query_state(rider)==state,
		"wall Grab controls: a real secondary side-face corner refuses an impossible fit without a partial wall correction")
	side.queue_free()
	f.wall.position.x=8.0
	await Wall._frames(tree,2)
	rider._obstacle_ollie_continuation=true
	rider._obstacle_visual_offset=prior
	var previous:=prior.length()
	var decays:=true
	for tick: int in 18:
		rider._visual.transform=base
		rider._place_obstacle_wheels(1.0/60.0)
		decays=decays and rider._obstacle_visual_offset.length()<=previous+0.000001
		previous=rider._obstacle_visual_offset.length()
	check.call(decays and previous<0.0003 and rider._obstacle_grab_air_offset(prior)==Vector3.ZERO
		and _query_state(rider)==state,
		"wall Grab controls: removing the finite native wall releases all retained displacement without an invented infinite plane")
	check.call(Wall._physics(rider)==physics and rider._board_visual.transform==local_board
		and rider._rider_visual.transform==local_rider,
		"wall Grab controls: accepted and refused solves preserve the frozen physical body and local rider/deck geometry")
	print("WALL_GRAB_NEGATIVES ",{"fit":fit,"no_accumulation":stable,"safe":safe,"ceiling_clear":ceiling_clear,
		"oblique_ceiling":oblique_ceiling,"oblique_contact":oblique_contact,"oblique_refused":refused,
		"corner_ceiling":corner_ceiling,"removed_decay":previous,"restored":_query_state(rider)==state})
	f.viewport.queue_free()
	await tree.process_frame
	_release()

static func _query_state(rider: CharacterBody3D) -> Dictionary:
	var q: PhysicsShapeQueryParameters3D=rider._grind_board_query
	var ray: PhysicsRayQueryParameters3D=rider._recovery_floor_query
	return {"shape":q.shape,"size":rider._grind_board_box.size,"margin":q.margin,"transform":q.transform,
		"motion":q.motion,"mask":q.collision_mask,"exclude":q.exclude,"bodies":q.collide_with_bodies,
		"areas":q.collide_with_areas,"ray_from":ray.from,"ray_to":ray.to,"ray_mask":ray.collision_mask,
		"ray_exclude":ray.exclude,"ray_bodies":ray.collide_with_bodies,"ray_areas":ray.collide_with_areas,
		"ray_back":ray.hit_back_faces,"ray_inside":ray.hit_from_inside}
