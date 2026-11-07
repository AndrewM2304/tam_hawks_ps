extends SceneTree
# PRIVATE input-only local connection probe. One initial reset; no actor writes thereafter.
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Lines=preload("res://tests/line_design_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const EdgeTrial=preload("res://tests/edge_grind_integration_tests.gd")
const FIRST=Lines.FIRST
const SECOND=Lines.SECOND
var passed:=0
var failed:=0
var wall: StaticBody3D
var trace: NativeTrace
var events: Array[Dictionary]=[]
func _initialize():_run.call_deferred()
func _check(ok: bool,label: String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _event(game: Node,id: String):
	events.append({"event":id,"physics":Engine.get_physics_frames(),"position":game.skater.global_position,
		"velocity":game.skater.velocity,"speed":game.skater.speed,"yaw":game.skater.rotation.y,
		"path_m":trace.path_m if trace!=null else 0.0,"launch":game.skater._launch_id,
		"trick_direction":game.skater._trick_input.direction(),"direction_edge_age":game.skater._trick_input.direction_age()})
func _run():
	create_timer(110,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await Driver._frames(self,40)
	for candidate: StaticBody3D in game.world.find_children("*","StaticBody3D",true,false):
		if candidate.get_meta("boundary_family","")=="QuayLandwardBoundary":
			var points: PackedVector3Array=candidate.get_meta("boundary_points")
			if points[0].x>=14.9:wall=candidate
	_check(wall!=null,"continuous return: actual existing east landward masonry is available")
	if wall!=null:
		var e: Dictionary=await _relay_prefix(game)
		if not e.is_empty():
			if e.prefix_complete:await _connected_return(game,e)
			Driver._release()
			await Driver._finish_bank(self,game,e,Callable())
			Driver._check_receipt(game,e,_check,"continuous return local chain")
			Driver._report(e,game)
			Driver._disconnect(game,e)
			_check(trace.model_clear and trace.capsule_clear and trace.skin_clear and trace.wall_clear,
				"continuous return: every observed actual physics state retains native board/capsule/shoe and finite wall proof")
			var packet={"kind":"input-only connected quay local feasibility; not whole-map acceptance",
				"initial_resets":1,"events":events,"prefix_events":e.event_ticks,"frames":trace.frames,
				"model_clear":trace.model_clear,"capsule_clear":trace.capsule_clear,"skin_clear":trace.skin_clear,
				"wall_clear":trace.wall_clear,"failures":trace.failures,"path_m":trace.path_m,
				"camera_clear_sampled_driver":e.camera_clear,"captures":e.captures,"entries":e.entries,
				"bails":e.bails,"recoveries":e.recoveries,"score":game.score.total_score}
			var file:=FileAccess.open("res://.local/connected-return-trace.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(packet,"  "))
			file.close()
			print("CONTINUOUS_RETURN_EVENTS ",events)
			print("CONTINUOUS_NATIVE_SUMMARY frames=",trace.frames.size()," failures=",trace.failures,
				" path_m=",trace.path_m," captures=",e.captures)
	game.free()
	print("CONTINUOUS_RETURN RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed>0 else 0)

func _relay_prefix(game: Node) -> Dictionary:
	var tree: SceneTree=self
	var check: Callable=_check
	var observer:=Callable()
	var next_line: RefCounted
	for line: RefCounted in game.world.get_grind_lines():
		if String(line.id)==SECOND:next_line=line
	if next_line==null:
		check.call(false,"November lines: second native seat bearing exists for the real relay")
		return {}
	var next_start: Vector3=next_line.points[0]
	var next_direction: Vector3=(next_line.points[-1]-next_start).normalized()
	var next_outside: Vector3=next_line.contact_edge_outward
	var next_join: Vector3=next_start-next_direction*4.0+next_outside*.35
	var next_aim: Vector3=next_start+next_direction*4.0+next_outside*.35
	await Driver._reset(tree,game,Vector3(33,2.08,63.55),-PI*.5)
	await Driver._frames(tree,40)
	var exit_witness:=Lines.ExitModelWitness.new()
	exit_witness.rider=game.skater
	exit_witness.process_physics_priority=100
	game.add_child(exit_witness)
	var e:=Driver._evidence(game,"east_quay_seating_relay")
	e["event_ticks"]=[]
	e["physics_start"]=Engine.get_physics_frames()
	e["seat_fit"]=true
	Driver._connect(game,e)
	trace=NativeTrace.new()
	trace.game=game
	trace.evidence=e
	trace.wall=wall
	trace.exit_witness=exit_witness
	trace.process_physics_priority=100
	game.add_child(trace)
	var popped:=false
	for tick: int in 240:
		if not popped:
			Driver._steer_to(game,Vector3(48,2,63.55),false)
			# Hold Push through the cap, matching the existing gallery driver.
			# Equal brake pressure controls speed without repeatedly arming a
			# directional Boneless/Nollie cue immediately before the plain pop.
			Input.action_press("push")
			Input.action_release("brake")
			if absf(game.skater.speed)>6.6:Input.action_press("brake")
			if game.skater.global_position.x>=36.5:Input.action_press("ollie")
			if game.skater.global_position.x>=38:
				Input.action_release("ollie")
				Input.action_release("push")
				Input.action_release("brake")
				popped=true
		Input.action_press("grind")
		await Driver._step(tree,game,e,"first_seat_approach",observer)
		if game.skater.grinding or e.bails>0:break
	var first: bool=game.skater.grinding and game.skater._grind.line.id==FIRST
	if first:
		e.seat_fit=e.seat_fit and Lines._native_seat_fit(game)
		e.event_ticks.append({"event":"first_catch","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		for tick: int in 120:
			await Driver._step(tree,game,e,"first_seat_ride",observer)
			if game.skater.grinding and tick%4==0:e.seat_fit=e.seat_fit and Lines._native_seat_fit(game)
			if game.skater.global_position.x>=43.4 or not game.skater.grinding:break
		e.event_ticks.append({"event":"first_exit_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"first_outward_pop_charge",observer)
		exit_witness.arm("first_seat_release",Lines._native_seat_fit(game))
		var intruded: Transform3D=exit_witness.loaded_frame
		intruded.origin.y-=.0263
		var rolled: Transform3D=exit_witness.loaded_frame
		rolled.basis=Basis(-rolled.basis.z,-.304)*rolled.basis
		check.call(not exit_witness.retained_clear(intruded,exit_witness.loaded_capsule,exit_witness.loaded_visual)
			and not exit_witness.retained_clear(rolled,exit_witness.loaded_capsule,exit_witness.loaded_visual),
			"November lines: known26.3mm intrusion and stale0.304rad roll cannot inherit authenticated loaded-pose authority")
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"first_outward_pop",observer)
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"seats_manual_link",observer)
	var linked: bool=first and game.skater.manual_active
	if linked:
		e.event_ticks.append({"event":"manual_landing","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		for tick: int in 420:
			# Join the actual rotated bearing's outside lead-in, then align with
			# its tangent before charging. No guessed world-Z catch target.
			var remaining: float=(next_start-game.skater.global_position).dot(next_direction)
			Driver._manual_to(game,next_join if remaining>4.0 else next_aim)
			await Driver._step(tree,game,e,"seats_manual_link",observer)
			if (next_start-game.skater.global_position).dot(next_direction)<=2.3 or e.bails>0:break
	var second:=false
	var paving_landing:=false
	var second_pop_from_bearing:=false
	if linked and game.skater.manual_active and e.bails==0:
		e.event_ticks.append({"event":"second_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		for tick: int in 16:
			Driver._manual_to(game,next_aim)
			await Driver._step(tree,game,e,"second_seat_charge",observer)
		e.event_ticks.append({"event":"second_release","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_release("ollie")
		Input.action_release("manual")
		Input.action_release("push")
		Input.action_release("brake")
		Driver._axis("steer_left","steer_right",0)
		Driver._axis("spin_left","spin_right",0)
		Input.action_press("grind")
		for tick: int in 150:
			await Driver._step(tree,game,e,"second_seat_catch",observer)
			if game.skater.grinding or e.bails>0:break
		second=game.skater.grinding and game.skater._grind.line.id==SECOND
	if second:
		e.seat_fit=e.seat_fit and Lines._native_seat_fit(game)
		e.event_ticks.append({"event":"second_catch","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		# Ride the finite bearing toward its end so the intended landing is the
		# paving runout. The earlier twelve-tick exit landed atop the seat and
		# exposed a separately retained native-prop visual support defect.
		for tick: int in 120:
			await Driver._step(tree,game,e,"second_seat_payoff",observer)
			if game.skater.grinding and tick%4==0:e.seat_fit=e.seat_fit and Lines._native_seat_fit(game)
			if (game.skater.global_position-next_start).dot(next_direction)>=next_line.length-.65 or not game.skater.grinding:break
		second_pop_from_bearing=game.skater.grinding and game.skater._grind.line.id==SECOND
		e.event_ticks.append({"event":"second_exit_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"second_exit_charge",observer)
		second_pop_from_bearing=second_pop_from_bearing and game.skater.grinding and game.skater._grind.line.id==SECOND
		e.seat_fit=e.seat_fit and Lines._native_seat_fit(game)
		e.event_ticks.append({"event":"second_exit_release","tick":e.ticks,"physics":Engine.get_physics_frames(),
			"at":game.skater.global_position,"speed":game.skater.speed,"still_on_bearing":second_pop_from_bearing})
		exit_witness.arm("second_seat_release",Lines._native_seat_fit(game))
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"second_exit",observer)
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"second_landing",observer)
		var point: Vector3=game.skater.global_position
		var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			point+Vector3.UP*.12,point-Vector3.UP*.18,1))
		var paving: StaticBody3D=game.world._outdoors.get_node("ClydeNorthQuay")
		paving_landing=game.skater.manual_active and absf(point.y-2.0)<0.18 \
			and (point-next_line.points[-1]).dot(next_direction)>.55 and EdgeTrial._standing_clear(game.skater) \
			and not hit.is_empty() and hit.collider==paving and absf(Vector3(hit.position).y-2.0)<0.002
		e.event_ticks.append({"event":"paving_landing","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"clear":paving_landing})
	var exit_model_clear: bool=exit_witness.clear and exit_witness.completed.has("first_seat_release") \
		and exit_witness.completed.has("second_seat_release")
	check.call(exit_model_clear,"November lines: both actual loaded bearing frames persist until native body travel, then GLB components clear on every initial airborne physics step")
	print("NOVEMBER_NATIVE_EXIT_WITNESS completed=",exit_witness.completed," clear=",exit_witness.clear," samples=",exit_witness.samples)
	trace.exit_witness=null
	exit_witness.free()
	var complete: bool=first and linked and second and e.captures==[FIRST,SECOND] and e.manual_ticks>=20 \
		and e.seat_fit and second_pop_from_bearing and paving_landing and exit_model_clear
	_check(complete,"continuous return: unchanged native two-seat prefix reaches actual Manual paving runout")
	print("CONTINUOUS_PREFIX events=",e.event_ticks," complete=",complete," speed=",game.skater.speed)
	e["prefix_complete"]=complete
	return e

func _connected_return(game: Node,e: Dictionary) -> void:
	_event(game,"second_seat_paving_manual")
	var heading:=Vector3(-.94,0,-.342).normalized()
	var turn_completed:=false
	var manual_turn_ticks:=0
	for tick: int in 120:
		Driver._manual_to(game,game.skater.global_position+heading*20)
		await Driver._step(self,game,e,"manual_north_quay_turn",Callable())
		if game.skater.manual_active:manual_turn_ticks+=1
		var desired:=atan2(-heading.x,-heading.z)
		if absf(angle_difference(game.skater.rotation.y,desired))<.08:
			turn_completed=true
			break
		if e.bails>0 or not game.skater.manual_active:break
	_event(game,"manual_turn_finished")
	_check(turn_completed and manual_turn_ticks>=20 and e.bails==0,
		"continuous return: actual second-seat Manual carves through mapped A/D to the wall approach")
	if not turn_completed:return
	# The Manual has no acceleration channel. End it honestly and push the
	# supported approach; then coast with no Brake, leaving raw fore/aft quiet
	# before charge/release. Holding Ollie itself retains ordinary pop acceleration.
	Input.action_release("manual")
	Driver._axis("push","brake",0)
	var capped:=false
	var quiet_ticks:=0
	var charged:=false
	var popped:=false
	for tick: int in 300:
		Driver._steer_to(game,game.skater.global_position+heading*20,false)
		Input.action_release("brake")
		if not capped and absf(game.skater.speed)<8.0:Input.action_press("push")
		else:
			capped=true
			Input.action_release("push")
			quiet_ticks+=1
		if game.skater.global_position.z<=57.6 and not charged and quiet_ticks>=13:
			charged=true
			Input.action_press("ollie")
			_event(game,"wall_plain_charge_quiet")
		if game.skater.global_position.z<=56.6 and charged:
			Input.action_release("ollie")
			Input.action_release("push")
			Input.action_press("grind")
			Driver._axis("steer_left","steer_right",0)
			popped=true
			_event(game,"wall_plain_pop")
		await Driver._step(self,game,e,"landward_quiet_approach",Callable())
		if popped:break
		if e.bails>0 or game.skater.global_position.z<55.7:break
	_check(popped and quiet_ticks>=13,"continuous return: mapped wall pop has >=13 quiet raw fore/aft ticks and no cap Brake")
	if not popped:return
	for tick: int in 100:
		await Driver._step(self,game,e,"native_wall_entry",Callable())
		if game.skater.wallriding or e.bails>0 or (not game.skater.airborne and game.skater.is_on_floor()):break
	var entered: bool=game.skater.wallriding and game.skater._wall.wall_id==str(wall.get_path())
	var wall_ticks:=0
	var wall_start: Vector3=game.skater.global_position
	var wall_finish:=wall_start
	if entered:
		_event(game,"native_landward_wall_entry")
		for tick: int in 30:
			await Driver._step(self,game,e,"landward_wallride",Callable())
			if not game.skater.wallriding or e.bails>0:break
			wall_ticks+=1
		wall_finish=game.skater.global_position
	var wallie:=false
	if entered and game.skater.wallriding and wall_ticks>=30:
		Input.action_press("ollie")
		await Driver._steps(self,game,e,2,"landward_wallie_charge",Callable())
		var supported_release: bool=game.skater.wallriding and game.skater._wall.wall_id==str(wall.get_path())
		Input.action_release("ollie")
		await Driver._step(self,game,e,"landward_wallie_release",Callable())
		wallie=supported_release and not game.skater.wallriding and game.skater._launch_id=="wallie"
		_event(game,"earned_landward_wallie")
		Input.action_release("grind")
		await Driver._landing_manual(self,game,e,150,"wallie_manual_return",Callable())
	var wall_m:=Vector2(wall_finish.x-wall_start.x,wall_finish.z-wall_start.z).length()
	_check(entered and wall_ticks>=30 and wall_m>=3 and wallie,
		"continuous return: connected prefix earns native30-tick/3m wallride and mapped Wallie")
	_check(wallie and game.skater.manual_active and e.bails==0 and e.recoveries==0 and e.camera_clear,
		"continuous return: earned Wallie lands a real supported Manual without reset or recovery")
	print("CONTINUOUS_WALL ticks=",wall_ticks," metres=",wall_m," quiet_ticks=",quiet_ticks,
		" charge=",charged," position=",game.skater.global_position," speed=",game.skater.speed)
	if not game.skater.manual_active:return
	_event(game,"wallie_manual_landing")
	var first_line: RefCounted
	for line: RefCounted in game.world.get_grind_lines():
		if String(line.id)==FIRST:first_line=line
	if first_line==null:return
	# Approach from the actual north shoulder, reverse along its finite tangent.
	# This is a return catch inside a wall sequence, not a second line by reversal.
	var first_end: Vector3=first_line.points[-1]
	var direction: Vector3=(first_line.points[0]-first_end).normalized()
	var outside: Vector3=first_line.contact_edge_outward
	var join: Vector3=first_end-direction*2.0+outside*.35
	var aim: Vector3=first_end+direction*4.0+outside*.35
	var charged_return:=false
	for tick: int in 240:
		var remaining: float=(first_end-game.skater.global_position).dot(direction)
		Driver._manual_to(game,join if remaining>2.0 else aim)
		if remaining<=2.5 and not charged_return:
			charged_return=true
			Input.action_press("ollie")
			_event(game,"return_first_bearing_charge")
		if charged_return and remaining<=1.1:break
		await Driver._step(self,game,e,"manual_first_bearing_return",Callable())
		if not game.skater.manual_active or e.bails>0:break
	var release_supported: bool=game.skater.manual_active and charged_return
	if release_supported:
		Input.action_release("ollie")
		Input.action_release("manual")
		Driver._axis("push","brake",0)
		Driver._axis("steer_left","steer_right",0)
		Driver._axis("spin_left","spin_right",0)
		Input.action_press("grind")
		_event(game,"return_first_bearing_pop")
		for tick: int in 150:
			await Driver._step(self,game,e,"return_first_bearing_catch",Callable())
			if game.skater.grinding or e.bails>0:break
	var recaught: bool=game.skater.grinding and String(game.skater._grind.line.id)==FIRST \
		and Lines._native_seat_fit(game)
	if recaught:
		_event(game,"first_bearing_native_return_catch")
		await Driver._steps(self,game,e,8,"return_finite_first_bearing",Callable())
	_check(release_supported and recaught and e.captures==[FIRST,SECOND,FIRST] and e.bails==0 \
		and e.recoveries==0 and e.camera_clear,
		"continuous return: two seats→manual turn→wallride/Wallie/manual→finite named first-bearing catch uses one reset")

class NativeTrace extends Node:
	var game: Node
	var evidence: Dictionary
	var wall: StaticBody3D
	var exit_witness: Node
	var frames: Array[Dictionary]=[]
	var failures: Array[Dictionary]=[]
	var model_clear:=true
	var capsule_clear:=true
	var skin_clear:=true
	var wall_clear:=true
	var path_m:=0.0
	var previous:=Vector3.INF
	func _physics_process(_delta: float) -> void:
		var rider: CharacterBody3D=game.skater
		var at: Vector3=rider.global_position
		if previous.is_finite():path_m+=at.distance_to(previous)
		previous=at
		var frame: Transform3D=rider._board_visual.global_transform
		var mode:="ground"
		var model: bool=rider._manual_model_frame_clear(frame)
		var capsule: bool
		var skin:=true
		var native_wall:=true
		var wall_gap:=INF
		if rider.grinding:
			mode="named_bearing"
			model=Lines._native_seat_fit(game)
		elif exit_witness!=null and exit_witness.armed and at.distance_to(exit_witness.loaded_origin)<.00001:
			mode="authenticated_stationary_bearing_release"
			model=exit_witness.retained_clear(frame,rider.get_node("BodyCollision").global_transform,rider._visual.global_transform)
		elif rider.wallriding:mode="wallride"
		elif rider.airborne:mode="air"
		elif rider.manual_active:mode="manual"
		if rider.is_on_floor() and not rider.airborne and not rider.grinding:
			capsule=bool(Lines._loaded_capsule_contact(game,rider.get_node("BodyCollision").global_transform).get("clear",false))
		else:capsule=EdgeTrial._capsule_clear(rider)
		if mode in ["air","wallride"]:skin=rider._obstacle_air_clear(Vector3.ZERO)
		if rider.wallriding:
			var point: Vector3=rider._wall.contact_point
			var normal: Vector3=rider._wall.normal
			var hit: Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(point+normal*.10,point-normal*.10,1,[rider.get_rid()]))
			native_wall=rider._wall.wall_id==str(wall.get_path()) and not hit.is_empty() \
				and hit.collider==wall and Vector3(hit.normal).dot(normal)>.999
			for wheel: Dictionary in rider._visual_rig.board_contact_geometry().wheels:
				for vertex: Vector3 in wheel.points:wall_gap=minf(wall_gap,(frame*vertex-point).dot(normal))
			native_wall=native_wall and is_finite(wall_gap) and wall_gap>=.0149
		model_clear=model_clear and model
		capsule_clear=capsule_clear and capsule
		skin_clear=skin_clear and skin
		wall_clear=wall_clear and native_wall
		var row={"physics":Engine.get_physics_frames(),"phase":evidence.phase,"mode":mode,"position":at,
			"yaw":rider.rotation.y,"velocity":rider.velocity,"speed":rider.speed,"path_m":path_m,
			"manual":rider.manual_active,"grind":String(rider._grind.line.id) if rider.grinding else "",
			"launch":rider._launch_id,"model":model,"capsule":capsule,"skin":skin,"wall":native_wall,
			"wall_gap":wall_gap,"raw_direction":rider._trick_input.direction(),"direction_age":rider._trick_input.direction_age(),
			"input":{"push":Input.get_action_strength("push"),"brake":Input.get_action_strength("brake"),
				"left":Input.get_action_strength("steer_left"),"right":Input.get_action_strength("steer_right"),
				"ollie":Input.get_action_strength("ollie"),"manual":Input.get_action_strength("manual"),"grind":Input.get_action_strength("grind")}}
		frames.append(row)
		if not model or not capsule or not skin or not native_wall:
			if failures.size()<12:failures.append(row)
