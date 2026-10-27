extends RefCounted
## Native wall-stop/Ollie/Flip with unchanged physical and local-pose twin.
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
		"wall Flip: actual Push/Brake and released Ollie start flight with a proven finite connected fit")
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
	Input.action_press("flip")
	for tick: int in 90:
		if tick==6:Input.action_release("flip")
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
		active_ticks+=int(rider._flip_remaining>0)
		bailing=bailing or rider.bail_active
		trace.append({"tick":tick,"active":rider._flip_remaining>0,"air":rider.airborne,
			"gap":gap,"offset":rider._obstacle_visual_offset,"at":rider.global_position})
	_release()
	check.call(active_ticks>=15 and entries.size()==2 and entries[0].id=="ollie" and entries[1].id=="kickflip" \
		and entries[0].points==int(Catalog.definition("ollie").base_points) \
		and entries[1].points==int(Catalog.definition("kickflip").base_points),
		"wall Flip: fresh mapped Flip performs one real catalog Kickflip after the earned Ollie")
	check.call(old_minimum< -0.10 and minimum>=0.0079 and max_offset<=0.18,
		"wall Flip: actual board/shoe vertices retain eight-millimetre wall clearance throughout Flip, catch and landing")
	check.call(physics_equal and pose_equal and rider.is_on_floor() and not bailing,
		"wall Flip: native motion and local rider/deck pose match the unfitted twin through the real supported landing")
	check.call(finite and seam<0.12 and joint<0.10,
		"wall Flip: the actual Skin-bound torso and trousers stay connected under the shared visual translation")
	var expected: int=(int(Catalog.definition("ollie").base_points)+int(Catalog.definition("kickflip").base_points))*2
	check.call(banks==[expected] and score.total_score==expected and score.get_combo_value()==0,
		"wall Flip: real native trick/landing signals bank the independently derived two-entry combo exactly once")
	print("WALL_FLIP_RESULT ",{"minimum":minimum,"old_minimum":old_minimum,"maximum_offset":max_offset,
		"active_ticks":active_ticks,"physics_equal":physics_equal,"pose_equal":pose_equal,
		"seam":seam,"joint":joint,"finite":finite,"entries":entries,"banks":banks,"total":score.total_score,"trace":trace})
	rider.trick_performed.disconnect(on_trick)
	rider.landed.disconnect(on_land)
	f.viewport.queue_free()
	await tree.process_frame

static func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
