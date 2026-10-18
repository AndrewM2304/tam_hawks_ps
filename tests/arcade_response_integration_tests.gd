extends RefCounted
const ClydeLayout = preload("res://game/levels/clyde_layout.gd")
## Real fixed-tick input trials. Only initial fixtures assign a transform;
## every subsequent change is produced by mapped keys and production physics.
const Skater = preload("res://game/player/skater.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Pipes = preload("res://game/levels/transition_park.gd")
const Line = preload("res://game/tricks/grind_line.gd")

class HandoffProbe extends "res://game/player/skater.gd":
	var probe_feature: Dictionary={}
	var prepare_events: Array[Dictionary]=[]
	var frame_blocker: StaticBody3D
	func _prepare_vert_return_contact(delta: float) -> bool:
		var before: Vector3=global_position
		var motion: Vector3=velocity
		var event: Dictionary={"tick":Engine.get_physics_frames(),"crossing":false,"armed":not _vert_return.is_empty()}
		if is_instance_valid(frame_blocker): event.obstacle_upright_overlap=_hits_blocker(Vector3.UP)
		if not probe_feature.is_empty():
			var toe: Transform3D=probe_feature.transform
			var local:=toe.affine_inverse()*before
			var next:=toe.affine_inverse()*(before+motion*delta)
			var height: float=probe_feature.radius*(1.0-cos(probe_feature.angle))
			var normal: Vector3=toe.basis*Vector3(0,cos(probe_feature.angle),sin(probe_feature.angle))
			if motion.y<0.0 and local.y>=height and next.y<=height and local.y>next.y:
				var at:=local.lerp(next,(height-local.y)/(next.y-local.y))
				event.crossing=true
				event.across=at.x
				event.gap=at.distance_to(Vector3(at.x,height,-probe_feature.radius*sin(probe_feature.angle)))
				event.outward=motion.dot(normal)
				var body: StaticBody3D=probe_feature.body
				event.live=is_instance_valid(body) and body.is_inside_tree() and body.collision_layer!=0
				event.support=event.live and _transition_support(toe*Vector3(at.x,height,-probe_feature.radius*sin(probe_feature.angle)),normal,body)
				if is_instance_valid(frame_blocker):
					event.blocked_start=_hits_blocker(Vector3.UP)
					event.blocked_middle=_hits_blocker(Vector3.UP.slerp(normal,0.5).normalized())
					event.blocked_end=_hits_blocker(normal)
		var accepted: bool=super._prepare_vert_return_contact(delta)
		event.accepted=accepted
		event.position_unchanged=global_position.distance_to(before)<0.000001
		event.velocity_unchanged=velocity.distance_to(motion)<0.000001
		prepare_events.append(event)
		return accepted
	func _hits_blocker(axis: Vector3) -> bool:
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=_body_collision.shape
		query.transform=Transform3D(Basis(Quaternion(Vector3.UP,axis)),global_position+axis*0.85)
		query.collision_mask=1
		query.exclude=[get_rid()]
		query.margin=0.001
		for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query,16):
			if hit.collider==frame_blocker: return true
		return false

class Recorder extends Node:
	var rider: Node3D
	var rows: Array[Dictionary] = []
	var active := false
	func _physics_process(delta: float) -> void:
		if not active: return
		var colliders: Array[String]=[]
		for index: int in rider.get_slide_collision_count():
			var collider: Object=rider.get_slide_collision(index).get_collider()
			if collider is Node: colliders.append(str(collider.name))
		rows.append({"tick":Engine.get_physics_frames(), "dt":delta, "at":rider.global_position,
			"velocity":rider.velocity, "yaw":rider.rotation.y, "air":rider.airborne,
			"floor":rider.is_on_floor(), "grind":rider.grinding,
			"contact_up":rider.get_node("BodyCollision").global_basis.y,"colliders":colliders,
			"transition":str(rider._transition.feature.get("id", "")) if rider.transition_active else "",
			"theta":rider._transition.theta if rider.transition_active else 0.0})


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	_release()
	for held: int in [2, 24]: await _flat_jump(tree, check, held)
	await _wall_pop_repeat(tree, check)
	for crouch: bool in [false, true]: await _pipe_cycles(tree, check, crouch)
	await _handoff_refusals(tree,check)
	for trial: Dictionary in [
		{"id":"held_early_left", "offset":-0.25, "angle":-5.0, "press":-1, "held":true, "catch":true},
		{"id":"held_early_right", "offset":0.25, "angle":5.0, "press":-1, "held":true, "catch":true},
		{"id":"held_angle_left_20", "offset":-1.40, "angle":-20.0, "press":-1, "held":true, "catch":true},
		{"id":"held_angle_right_20", "offset":1.40, "angle":20.0, "press":-1, "held":true, "catch":true},
		{"id":"outside_angle_70", "offset":-4.10, "angle":-70.0, "press":-1, "held":true, "catch":false},
		{"id":"tap_approach", "offset":0.25, "angle":-4.0, "press":12, "held":false, "catch":true},
		{"id":"tap_later", "offset":-0.25, "angle":4.0, "press":16, "held":false, "catch":true},
		{"id":"outside_lateral", "offset":1.25, "angle":0.0, "press":-1, "held":true, "catch":false},
		{"id":"expired_tap", "offset":0.0, "angle":0.0, "press":-1, "held":false, "catch":false},
		{"id":"solid_obstruction", "offset":0.55, "angle":0.0, "press":-1, "held":true, "catch":false, "blocked":true}]:
		await _rail_approach(tree, check, trial)
	_release()


static func _flat_jump(tree: SceneTree, check: Callable, held: int) -> void:
	var f: Dictionary = await _fixture(tree)
	var rider: Node3D = f.rider
	var origin: Vector3 = rider.global_position
	var awards: Array[String] = []
	rider.trick_performed.connect(func(id: String, _points: int): awards.append(id))
	f.recorder.active = true
	_key(KEY_SPACE, true)
	await _ticks(tree, held)
	check.call(rider.is_on_floor() and not rider.airborne and awards.is_empty(),
		"arcade jump: mapped %d-tick crouch stays supported until release" % held)
	_key(KEY_SPACE, false)
	await _ticks(tree, 90)
	var peak := 0.0
	var air_seconds := 0.0
	var contiguous := true
	var previous_tick := -1
	for row: Dictionary in f.recorder.rows:
		peak = maxf(peak, row.at.y-origin.y)
		if row.air: air_seconds += row.dt
		if previous_tick >= 0: contiguous = contiguous and row.tick == previous_tick+1
		previous_tick = row.tick
	var short := held < 10
	var in_envelope := peak >= (0.8 if short else 1.65) and peak <= (1.1 if short else 2.05)
	in_envelope = in_envelope and air_seconds >= (0.40 if short else 0.60) and air_seconds <= (0.53 if short else 0.73)
	check.call(in_envelope, "arcade jump: %s real apex/airtime meet deliberate response envelope" % ("tap" if short else "charged"))
	check.call(contiguous and rider.is_on_floor() and awards.count("Ollie") == 1,
		"arcade jump: native consecutive ticks record exactly one pop and a supported landing")
	print("ARCADE_JUMP held=", held, " apex=", peak, " airtime=", air_seconds, " first_tick=", f.recorder.rows[0].tick, " last_tick=", previous_tick)
	await _dispose(tree, f)


static func _wall_pop_repeat(tree: SceneTree, check: Callable) -> void:
	var results: Array[Dictionary] = []
	for repeat: bool in [false,true]:
		var f: Dictionary = await _fixture(tree,true,false,true)
		var rider: Node3D = f.rider
		# Initial standalone-quarter approach, then mapped input only.
		rider.position = Vector3(17,rider.position.y,73)
		rider.rotation.y = 0.0
		rider.reset_physics_interpolation()
		await _ticks(tree,2)
		var awards: Array[String] = []
		rider.trick_performed.connect(func(id: String,_points: int): awards.append(id))
		_key(KEY_W,true)
		var approach := false
		for tick: int in range(180):
			await _ticks(tree,1)
			if rider.transition_active and rider._transition.theta >= deg_to_rad(50.0) and rider.velocity.y > 4.0:
				approach=true
				break
		_key(KEY_SPACE,true)
		await _ticks(tree,2)
		var before: Vector3=rider.velocity
		var started_on_wall: bool=rider.transition_active
		_key(KEY_SPACE,false)
		await _ticks(tree,1)
		var launch: Vector3=rider.velocity
		var launch_tick := Engine.get_physics_frames()
		check.call(approach and started_on_wall and rider.airborne and not rider.transition_active
			and launch.y <= maxf(before.y,8.0)+0.30 and awards.count("Ollie")==1,
			"arcade wall pop: mapped release leaves real steep support once without stacking a full impulse onto upward ramp speed")
		if repeat:
			_key(KEY_SPACE,true)
			await _ticks(tree,1)
			_key(KEY_SPACE,false)
			await _ticks(tree,1)
			check.call(rider.airborne and awards.count("Ollie")==1 and rider.velocity.y < launch.y,
				"arcade wall pop: immediate second mapped tap cannot reuse stale street coyote time or award/boost a second airborne ollie")
		var peak: float=rider.global_position.y
		var resolved := false
		var elapsed := 0.0
		for tick: int in range(96):
			await _ticks(tree,1)
			peak=maxf(peak,rider.global_position.y)
			elapsed=float(Engine.get_physics_frames()-launch_tick)/Engine.physics_ticks_per_second
			if rider.transition_active or (rider.is_on_floor() and not rider.airborne):
				resolved=true
				break
		check.call(resolved and elapsed<1.30 and awards.count("Ollie")==1,
			"arcade wall pop: %s reaches real support within a bounded flight with one total ollie" % ("quick-double-tap" if repeat else "single tap"))
		results.append({"peak":peak,"elapsed":elapsed,"launch":launch})
		print("ARCADE_WALL_POP repeat=",repeat," initial_up=",before.y," launch=",launch," peak=",peak," flight=",elapsed," ollies=",awards.count("Ollie"))
		await _dispose(tree,f)
	check.call(absf(float(results[0].peak)-float(results[1].peak))<0.10
		and absf(float(results[0].elapsed)-float(results[1].elapsed))<0.10,
		"arcade wall pop: repeated airborne tap preserves the single-pop physical arc and landing time")


static func _pipe_cycles(tree: SceneTree, check: Callable, crouch: bool) -> void:
	var f: Dictionary = await _fixture(tree, true)
	var rider: Node3D = f.rider
	var bails := [0]
	var ollies := [0]
	rider.bailed.connect(func(): bails[0] += 1)
	rider.trick_performed.connect(func(id: String, _points: int):
		if id == "Ollie": ollies[0] += 1)
	f.recorder.active = true
	_key(KEY_SPACE if crouch else KEY_W, true)
	await _ticks(tree, 660)
	var visits: Array[String] = []
	var previous := ""
	var saw_air := false
	var finite := true
	var discontinuities := 0
	var last: Vector3 = f.recorder.rows[0].at
	var maximum_step := 0.0
	for row: Dictionary in f.recorder.rows:
		var id: String = row.transition
		if not id.is_empty() and id != previous:
			visits.append(id)
			previous = id
		saw_air = saw_air or row.air
		finite = finite and row.at.is_finite() and row.velocity.is_finite()
		var step: float = row.at.distance_to(last)
		maximum_step = maxf(maximum_step, step)
		if step > 1.0: discontinuities += 1
		last = row.at
	var alternating := visits.size() >= 4
	for index: int in range(1, visits.size()): alternating = alternating and visits[index] != visits[index-1]
	var lip_heights: Dictionary={}
	for feature: Dictionary in f.features:
		var toe: Transform3D=feature.transform
		lip_heights[feature.id]=toe.origin.y+float(feature.radius)*(1.0-cos(float(feature.angle)))
	var natural:=_natural_returns(f.recorder.rows,lip_heights)
	check.call(natural.departures>0 and natural.reentries>0 and natural.opposite_after_return,
		"arcade halfpipe: real steep upward natural departure recaptures the same live face descending, then reaches the opposite wall")
	var toe_exits:=0
	var toe_grounded:=true
	for index: int in range(1,f.recorder.rows.size()-1):
		var prior: Dictionary=f.recorder.rows[index-1]
		var row: Dictionary=f.recorder.rows[index]
		if str(prior.transition).is_empty() or not str(row.transition).is_empty() or prior.theta>deg_to_rad(8.0): continue
		var expected_toe:=float(lip_heights.get(prior.transition,INF))-3.2
		if absf(row.at.y-expected_toe)>0.03: continue
		toe_exits+=1
		var next: Dictionary=f.recorder.rows[index+1]
		toe_grounded=toe_grounded and not row.air and absf(row.velocity.y)<=0.05 and not next.air and next.floor and absf(next.velocity.y)<=0.05
	check.call(toe_exits>=2 and toe_grounded,
		"arcade halfpipe: actual low toe exits retain supported ground and bounded vertical velocity without artificial seam hops")
	check.call(alternating and visits.has("clyde_half_east") and visits.has("clyde_half_west"),
		"arcade halfpipe: held %s achieves at least four alternating actual wall visits without steering/heading assistance" % ("crouch" if crouch else "push"))
	check.call(finite and bails[0] == 0 and discontinuities == 0 and ollies[0] == 0,
		"arcade halfpipe: repeated automatic returns preserve finite continuous physical travel without bails or invented ollies")
	print("ARCADE_PIPE crouch=", crouch, " walls=", visits, " natural_air=", saw_air, " natural_returns=",natural," max_step=", maximum_step, " bails=", bails[0], " final=", rider.global_position)
	await _dispose(tree, f)


static func _natural_returns(samples: Array,lip_heights: Dictionary) -> Dictionary:
	var departures:=0
	var reentries:=0
	var opposite_after_return:=false
	var previous: Dictionary={}
	var pending: String=""
	var recaptured: String=""
	for row: Dictionary in samples:
		var id: String=row.transition
		if not previous.is_empty() and not str(previous.transition).is_empty() and float(previous.theta)>=deg_to_rad(65.0) \
				and id.is_empty() and row.air and row.velocity.y>1.0 \
				and absf(row.at.y-float(lip_heights.get(previous.transition,INF)))<=0.25:
			pending=previous.transition
			departures+=1
		if not pending.is_empty():
			if id==pending and row.velocity.y<0.0 and not previous.is_empty() and previous.air:
				reentries+=1
				recaptured=pending
				pending=""
			elif (not id.is_empty() and id!=pending) or (id.is_empty() and not row.air): pending=""
		if id in ["clyde_half_east","clyde_half_west"] and not recaptured.is_empty() and id!=recaptured:
			opposite_after_return=true
		previous=row
	return {"departures":departures,"reentries":reentries,"opposite_after_return":opposite_after_return}


static func _handoff_refusals(tree: SceneTree,check: Callable) -> void:
	var f: Dictionary=await _fixture(tree,true,true,true)
	var rider: HandoffProbe=f.rider
	var feature: Dictionary={}
	for entry: Dictionary in f.features:
		if entry.id=="clyde_quarter": feature=entry
	var toe: Transform3D=feature.transform
	var body: StaticBody3D=feature.body
	var body_parent: Node=body.get_parent()
	var lip_y:=toe.origin.y+float(feature.radius)*(1.0-cos(float(feature.angle)))
	var normal:=toe.basis*Vector3(0,cos(feature.angle),sin(feature.angle))
	for mode: String in ["removed","disabled","width","outward","rotation_blocker"]:
		_release()
		rider.spawn_position=Vector3(21.7 if mode=="width" else 17.0,2.8,73)
		rider.reset_skater()
		rider.probe_feature=feature
		rider.frame_blocker=null
		f.recorder.active=false
		await _ticks(tree,40)
		var awards: Array[String]=[]
		var on_trick:=func(id: String,_points: int): awards.append(id)
		rider.trick_performed.connect(on_trick)
		_key(KEY_W,true)
		var carved:=false
		var carve_ticks:=0
		var launched:=false
		for tick: int in range(180):
			if mode=="width" and not carved and rider.transition_active and rider._transition.theta>=deg_to_rad(70.0):
				_key(KEY_D,true)
				carved=true
				carve_ticks=3
			await _ticks(tree,1)
			if carve_ticks>0:
				carve_ticks-=1
				if carve_ticks==0: _key(KEY_D,false)
			if rider.airborne and not rider.transition_active and rider.velocity.y>1.0 and absf(rider.position.y-lip_y)<0.25 and not rider._vert_return.is_empty():
				launched=true
				break
		_key(KEY_W,false)
		_key(KEY_D,false)
		check.call(launched,"arcade handoff: %s begins with a real mapped-input natural steep departure" % mode)
		f.recorder.rows.clear()
		rider.prepare_events.clear()
		f.recorder.active=true
		var obstacle: StaticBody3D=null
		if mode=="removed": body_parent.remove_child(body)
		elif mode=="disabled": body.collision_layer=0
		elif mode=="outward":
			# Place the tilted underside above the actual upright capsule support,
			# with a gap scaled to this real departure's available ballistic rise.
			# A fixed world-Y roof can silently miss a lower natural launch.
			var collider: CollisionShape3D=rider.get_node("BodyCollision")
			var capsule: CapsuleShape3D=collider.shape
			var roof_up:=Basis(Vector3.RIGHT,-PI*0.25).y
			var support: float=(collider.global_position-rider.global_position).dot(roof_up)+capsule.radius \
				+(capsule.height*0.5-capsule.radius)*absf(collider.global_basis.y.dot(roof_up))
			var available_rise: float=rider.velocity.y*rider.velocity.y/(2.0*Skater.GRAVITY)
			var gap:=clampf(available_rise*0.15,0.025,0.10)
			var roof_at: Vector3=rider.global_position+Vector3.UP*((support+0.06)/roof_up.y+gap)
			obstacle=_obstacle(f.root,"OutwardDeflector",roof_at,Vector3(6,0.12,4),-PI*0.25)
			rider.frame_blocker=obstacle
			print("ARCADE_DEFLECTOR launch_y=",rider.position.y," launch_up=",rider.velocity.y," available_rise=",available_rise," gap=",gap," roof=",roof_at)
		var crossing_tick: int=-1
		for tick: int in range(100):
			if mode=="rotation_blocker" and obstacle==null and rider.velocity.y<0.0 and rider.position.y>=lip_y \
					and rider.position.y+(rider.velocity.y-Skater.GRAVITY/60.0)/60.0<=lip_y:
				var middle:=Vector3.UP.slerp(normal,0.5).normalized()
				obstacle=_obstacle(f.root,"IntermediateFrameBlocker",rider.global_position+middle*1.1,Vector3.ONE*0.12)
				rider.frame_blocker=obstacle
			await _ticks(tree,1)
			if not rider.prepare_events.is_empty():
				var event: Dictionary=rider.prepare_events[-1]
				if event.crossing and crossing_tick<0: crossing_tick=event.tick
			if crossing_tick>=0 and Engine.get_physics_frames()>=crossing_tick+8: break
		var fixture_valid:=crossing_tick>=0
		var no_prepare:=true
		var unchanged:=true
		var witness:=false
		for event: Dictionary in rider.prepare_events:
			no_prepare=no_prepare and not event.accepted
			unchanged=unchanged and event.position_unchanged and event.velocity_unchanged
			if not event.crossing: continue
			if mode=="width": witness=witness or absf(float(event.across))>float(feature.width)*0.5+0.02
			elif mode=="outward": witness=witness or float(event.outward)>1.0
			elif mode=="rotation_blocker": witness=witness or (event.armed and event.get("support",false) and not event.get("blocked_start",true) and event.get("blocked_middle",false) and not event.get("blocked_end",true))
			else: witness=witness or not event.get("live",true)
		var upright_air:=true
		var no_missing_support:=true
		var deflected:=false
		for row: Dictionary in f.recorder.rows:
			if row.air and str(row.transition).is_empty(): upright_air=upright_air and row.contact_up.dot(Vector3.UP)>0.999
			if mode in ["removed","disabled"]: no_missing_support=no_missing_support and str(row.transition).is_empty()
			deflected=deflected or row.colliders.has("OutwardDeflector")
		if mode=="outward": fixture_valid=fixture_valid and deflected and not rider.prepare_events.is_empty() and not rider.prepare_events[0].get("obstacle_upright_overlap",true)
		check.call(fixture_valid and witness,"arcade handoff: %s actually reaches its declared invalid crossing/obstruction condition" % mode)
		check.call(no_prepare and unchanged and no_missing_support,
			"arcade handoff: %s refuses preparation without invented support, position or velocity" % mode)
		check.call(upright_air and awards.is_empty(),
			"arcade handoff: refused %s keeps ordinary air capsule upright and invents no trick award" % mode)
		print("ARCADE_HANDOFF mode=",mode," launched=",launched," crossing_tick=",crossing_tick," witness=",witness," prepared=",not no_prepare," upright_air=",upright_air," deflector_hit=",deflected," awards=",awards)
		f.recorder.active=false
		rider.trick_performed.disconnect(on_trick)
		if mode=="removed": body_parent.add_child(body)
		body.collision_layer=1
		rider.frame_blocker=null
		if obstacle!=null: obstacle.free()
	await _dispose(tree,f)


static func _obstacle(parent: Node3D,id: String,at: Vector3,size: Vector3,pitch: float=0.0) -> StaticBody3D:
	var body:=StaticBody3D.new()
	body.name=id
	var collider:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=size
	collider.shape=shape
	body.add_child(collider)
	body.position=at
	body.rotation.x=pitch
	parent.add_child(body)
	return body


static func _rail_approach(tree: SceneTree, check: Callable, trial: Dictionary) -> void:
	var f: Dictionary = await _fixture(tree)
	var rider: Node3D = f.rider
	# Initial lateral/angular imperfections are declared before any movement.
	rider.position = Vector3(float(trial.offset), rider.position.y, 12)
	rider.rotation.y = deg_to_rad(float(trial.angle))
	rider.reset_physics_interpolation()
	rider.set_grind_lines([Line.new("human_margin", PackedVector3Array([Vector3(0,0.5,12),Vector3(0,0.5,-30)]), "rail")])
	if trial.get("blocked", false):
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.10, 2.5, 55)
		shape.shape = box
		wall.add_child(shape)
		wall.position = Vector3(0.20,1.25,-6)
		f.root.add_child(wall)
		await _ticks(tree, 2)
	var awards: Array[String] = []
	var catches: Array[String] = []
	rider.trick_performed.connect(func(id: String, _points: int): awards.append(id))
	rider.grind_captured.connect(func(id: String): catches.append(id))
	_key(KEY_W, true)
	await _ticks(tree, 42)
	_key(KEY_W, false)
	if int(trial.press) < 0: _key(KEY_L, true)
	if int(trial.press) < 0 and not trial.held:
		await _ticks(tree, 1)
		_key(KEY_L, false)
		await _ticks(tree, 16)
	_key(KEY_SPACE, true)
	await _ticks(tree, 2)
	_key(KEY_SPACE, false)
	f.recorder.active = true
	for tick: int in range(65):
		if tick == int(trial.press): _key(KEY_L, true)
		if not trial.held and int(trial.press) >= 0 and tick == int(trial.press)+1: _key(KEY_L, false)
		await _ticks(tree, 1)
		if rider.grinding: break
	var caught: bool = rider.grinding
	if trial.id == "outside_angle_70":
		var geometric_window := false
		for row: Dictionary in f.recorder.rows:
			geometric_window = geometric_window or (absf(row.at.x)<0.65 and row.at.y>=0.36 and row.at.y<=1.10
				and row.velocity.y<=1.0 and Vector2(row.velocity.x,row.velocity.z).length()>2.0)
		check.call(geometric_window,
			"arcade rail: 70-degree negative actually traverses the lateral/vertical/speed window, isolating angle rejection")
	check.call(caught == bool(trial.catch), "arcade rail: imperfect actual mapped approach %s expected catch=%s" % [trial.id,trial.catch])
	if caught:
		_key(KEY_L, false)
		await _ticks(tree, 4)
		check.call(rider.grinding and catches.size() == 1 and awards.count("Rail Grind") == 1,
			"arcade rail: %s release stays locked with one award" % trial.id)
		_key(KEY_L, true)
		await _ticks(tree, 1)
		_key(KEY_L, false)
		await _ticks(tree, 10)
		check.call(not rider.grinding and catches.size() == 1 and awards.count("Rail Grind") == 1,
			"arcade rail: %s fresh second press exits without automatic recapture" % trial.id)
	else:
		check.call(catches.is_empty() and awards.count("Rail Grind") == 0,
			"arcade rail: rejected %s cannot score a phantom catch" % trial.id)
	print("ARCADE_RAIL id=", trial.id, " caught=", caught, " catches=", catches.size(), " position=", rider.global_position)
	await _dispose(tree, f)


static func _fixture(tree: SceneTree, pipe: bool = false,handoff_probe: bool=false, quarter_pose: bool=false) -> Dictionary:
	_release()
	var root := Node3D.new()
	tree.root.add_child(root)
	var floor := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(160, 0.4, 160)
	collider.shape = box
	floor.add_child(collider)
	floor.position = Vector3(0,1.8,60) if pipe else Vector3(0,-0.2,0)
	root.add_child(floor)
	var ramp_root := Node3D.new()
	root.add_child(ramp_root)
	if quarter_pose:
		# Keep the established obstruction experiments in their canonical frame;
		# the World tests independently exercise the moved production contacts.
		ramp_root.transform=Transform3D(Basis.IDENTITY,Vector3(17,2,64.5))*Transform3D(Basis(Vector3.UP,ClydeLayout.QUARTER_YAW),ClydeLayout.QUARTER_TOE).affine_inverse()
	var features: Array = Pipes.build(ramp_root,{}) if pipe else []
	var rider = HandoffProbe.new() if handoff_probe else Skater.new()
	rider.spawn_position = Vector3(-42,2.8,60.5) if pipe else Vector3(0,0.8,12)
	root.add_child(rider)
	rider.set_transition_features(features)
	await _ticks(tree, 40)
	if pipe: rider.rotation.y = -PI*0.5
	var recorder := Recorder.new()
	recorder.rider = rider
	recorder.process_physics_priority = 100
	root.add_child(recorder)
	return {"root":root,"rider":rider,"recorder":recorder,"features":features}


static func _ticks(tree: SceneTree, count: int) -> void:
	var target := Engine.get_physics_frames()+count
	while Engine.get_physics_frames() < target:
		await tree.physics_frame
		await tree.process_frame


static func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


static func _release() -> void:
	for code: Key in [KEY_SPACE,KEY_W,KEY_S,KEY_A,KEY_D,KEY_L]: _key(code,false)
	for action: StringName in InputMap.get_actions(): Input.action_release(action)


static func _dispose(tree: SceneTree, f: Dictionary) -> void:
	_release()
	f.root.free()
	await tree.process_frame
