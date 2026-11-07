extends SceneTree
# PRIVATE input-only local connection probe. One initial reset; no actor writes thereafter.
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Lines=preload("res://tests/line_design_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const EdgeTrial=preload("res://tests/edge_grind_integration_tests.gd")
const Catalog=preload("res://game/tricks/trick_catalog.gd")
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
			await _finish_new_bank(game,e)
			trace.observe_bank()
			_check(trace.score_receipts_clear and trace.score_banks.size()==e.banks and trace.score_banks.size()>0 \
				and trace.calculated_total==game.score.total_score and game.score.get_combo_value()==0 \
				and e.hold_valid and e.bails==0 and e.recoveries==0 and e.camera_clear and e.ground_supported,
				"continuous return: every actual score bank independently matches native catalog/repetition/hold events")
			if trace.wall_load_controls_ran:_check(trace.wall_load_controls_clear,"continuous return: loaded-wall capsule proof rejects wrong owner/shape/face/deep/nonfinite neighbours")
			print("CONTINUOUS_SCORE_BANKS one_combo=",e.banks==1," receipts=",trace.score_banks)
			Driver._report(e,game)
			Driver._disconnect(game,e)
			_check(trace.model_clear and trace.capsule_clear and trace.shoe_clear and trace.skin_clear and trace.wall_clear,
				"continuous return: every observed actual physics state retains native board/capsule/shoe and finite wall proof")
			var packet={"kind":"input-only connected quay local feasibility; not whole-map acceptance",
				"initial_resets":1,"events":events,"prefix_events":e.event_ticks,"frames":trace.frames,
				"model_clear":trace.model_clear,"capsule_clear":trace.capsule_clear,"skin_clear":trace.skin_clear,
				"shoe_zero_clear":trace.shoe_clear,"wall_clear":trace.wall_clear,"failures":trace.failures,"path_m":trace.path_m,
				"camera_clear_sampled_driver":e.camera_clear,"captures":e.captures,"entries":e.entries,
				"bails":e.bails,"recoveries":e.recoveries,"score":game.score.total_score,
				"score_banks":trace.score_banks,"one_combo":e.banks==1,"independent_score_clear":trace.score_receipts_clear,
				"loaded_wall_controls_ran":trace.wall_load_controls_ran,"loaded_wall_controls_clear":trace.wall_load_controls_clear,"loaded_wall_controls":trace.wall_load_controls}
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
	trace.connect_native_score()
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
		if not capped and absf(game.skater.speed)<7.2:Input.action_press("push")
		else:
			capped=true
			Input.action_release("push")
			quiet_ticks+=1
		if game.skater.global_position.z<=57.2 and not charged and quiet_ticks>=13:
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
	var join: Vector3=first_end-direction*2.0+outside*1.5
	var aim: Vector3=first_end+direction*4.0+outside*.35
	var charged_return:=false
	var joined:=false
	for tick: int in 240:
		var remaining: float=(first_end-game.skater.global_position).dot(direction)
		if not joined and game.skater.global_position.distance_to(join)<.65:
			joined=true
			_event(game,"return_actual_north_shoulder_join")
		Driver._manual_to(game,aim if joined else join)
		if joined and remaining<=2.5 and not charged_return:
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
	var finite_return_exit:=false
	if recaught:
		_event(game,"first_bearing_native_return_catch")
		await Driver._steps(self,game,e,8,"return_finite_first_bearing",Callable())
		for tick: int in 240:
			if not game.skater.grinding or game.skater._grind.distance<=.65:break
			await Driver._step(self,game,e,"return_first_bearing_payoff",Callable())
		var returning: bool=game.skater.grinding and String(game.skater._grind.line.id)==FIRST
		if returning:
			Input.action_press("ollie")
			await Driver._steps(self,game,e,2,"return_first_exit_charge",Callable())
			var release_witness:=Lines.ExitModelWitness.new()
			release_witness.rider=game.skater
			release_witness.process_physics_priority=100
			game.add_child(release_witness)
			trace.exit_witness=release_witness
			release_witness.arm("return_first_release",Lines._native_seat_fit(game))
			_event(game,"returned_first_bearing_release")
			Input.action_release("ollie")
			await Driver._step(self,game,e,"return_first_exit",Callable())
			Input.action_release("grind")
			await Driver._landing_manual(self,game,e,150,"return_first_paving_landing",Callable())
			var point: Vector3=game.skater.global_position
			var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*.12,point-Vector3.UP*.18,1))
			finite_return_exit=game.skater.manual_active and not hit.is_empty() and hit.collider==game.world._outdoors.get_node("ClydeNorthQuay") \
				and point.x<first_line.points[0].x-.55 and release_witness.clear and release_witness.completed.has("return_first_release")
			_event(game,"returned_first_bearing_paving_manual")
			trace.exit_witness=null
			release_witness.free()
	_check(release_supported and recaught and e.captures==[FIRST,SECOND,FIRST] and e.bails==0 \
		and e.recoveries==0 and e.camera_clear,
		"continuous return: two seats→manual turn→wallride/Wallie/manual→finite named first-bearing catch uses one reset")
	_check(finite_return_exit,"continuous return: mapped finite first-bearing exit lands supported paving Manual with authenticated release")

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
	var shoe_clear:=true
	var wall_load_controls_ran:=false
	var wall_load_controls_clear:=true
	var wall_load_controls: Array[Dictionary]=[]
	var wall_clear:=true
	var path_m:=0.0
	var previous:=Vector3.INF
	var score_receipts_clear:=true
	var score_banks: Array[Dictionary]=[]
	var last_score:=0
	var calculated_total:=0
	var segment_base:=0
	var segment_count:=0
	var segment_entries: Array[Dictionary]=[]
	var repetitions: Dictionary={}
	func connect_native_score() -> void:
		last_score=game.score.total_score
		game.skater.trick_performed.connect(_on_native_trick)
		game.skater.hold_points_awarded.connect(_on_native_hold)
	func _on_native_trick(label: String,points: int) -> void:
		observe_bank()
		var id: String=game.skater.last_trick_id
		var definition: Dictionary=Catalog.definition(id)
		var valid: bool=not definition.is_empty() and String(definition.get("display_name",""))==label \
			and int(definition.get("base_points",0))==points
		score_receipts_clear=score_receipts_clear and valid
		var key: String=Catalog.repetition_id(id)
		var repeats: int=int(repetitions.get(key,0))
		var award:=points
		if String(definition.get("family",""))!="spin":
			award=Catalog.repeated_points(points,repeats)
			repetitions[key]=repeats+1
			segment_count+=1
		segment_base+=award
		segment_entries.append({"physics":Engine.get_physics_frames(),"id":id,"points":points,"repeat_before":repeats,"award":award})
	func _on_native_hold(points: int) -> void:
		observe_bank()
		score_receipts_clear=score_receipts_clear and points>0 and points%25==0 and game.skater.grinding
		segment_base+=points
		segment_entries.append({"physics":Engine.get_physics_frames(),"hold":points})
	func observe_bank() -> void:
		var actual: int=game.score.total_score
		if actual==last_score:return
		var delta:=actual-last_score
		var expected: int=segment_base*mini(segment_count,100)
		var valid: bool=delta==expected and expected>0
		score_receipts_clear=score_receipts_clear and valid
		calculated_total+=expected
		score_banks.append({"physics":Engine.get_physics_frames(),"actual_delta":delta,"expected":expected,
			"base":segment_base,"count":segment_count,"entries":segment_entries.duplicate(true),"valid":valid})
		segment_base=0
		segment_count=0
		segment_entries.clear()
		last_score=actual
	func _physics_process(_delta: float) -> void:
		observe_bank()
		var rider: CharacterBody3D=game.skater
		var at: Vector3=rider.global_position
		if previous.is_finite():path_m+=at.distance_to(previous)
		previous=at
		var frame: Transform3D=rider._board_visual.global_transform
		var mode:="ground"
		var model: bool=rider._manual_model_frame_clear(frame)
		var capsule: bool
		var raw_capsule: Dictionary={}
		var loaded_wall: Dictionary={}
		var skin:=true
		var shoes:=true
		var wall_context:=false
		var raw_zero: Dictionary={}
		var raw_skin: Dictionary={}
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
		var raw_capsule_clear: bool=capsule
		if not capsule:
			raw_capsule=_raw_capsule(rider)
			if rider.wallriding:
				loaded_wall=_loaded_wall_capsule(rider,rider.get_node("BodyCollision").global_transform)
				capsule=bool(loaded_wall.get("clear",false))
				if capsule and not wall_load_controls_ran:_loaded_wall_negatives(rider,loaded_wall)
		if mode in ["air","wallride"]:
			raw_zero=_raw_pose_hits(rider,0.0)
			raw_skin=_raw_pose_hits(rider,.00799)
			shoes=bool(raw_zero.shoes_clear) and not bool(raw_zero.saturated)
			#7.99mm is the earned near-wall proposal skin, not a generic
			#airborne gap above a floor just before its native landing step.
			wall_context=rider.wallriding or not rider._obstacle_air_wall.is_empty() \
				or not rider._obstacle_air_forecast.is_empty() or rider._wall.air_presentation_active
			if wall_context:skin=rider._obstacle_air_clear(Vector3.ZERO)
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
		shoe_clear=shoe_clear and shoes
		wall_clear=wall_clear and native_wall
		var row={"physics":Engine.get_physics_frames(),"phase":evidence.phase,"mode":mode,"position":at,
			"yaw":rider.rotation.y,"velocity":rider.velocity,"speed":rider.speed,"path_m":path_m,
			"manual":rider.manual_active,"grind":String(rider._grind.line.id) if rider.grinding else "",
			"launch":rider._launch_id,"model":model,"capsule":capsule,"skin":skin,"wall":native_wall,
			"wall_skin_context":wall_context,"active_wall_rid":str(rider._obstacle_air_wall.get("rid","")),
			"forecast_rid":str(rider._obstacle_air_forecast.get("rid","")),"wall_air_presentation":rider._wall.air_presentation_active,
			"active_offset":rider._obstacle_visual_offset,"shoe_zero":shoes,"raw_margin_zero":raw_zero,"raw_margin_7_99mm":raw_skin,
			"wall_gap":wall_gap if is_finite(wall_gap) else null,"capsule_raw_strict_clear":raw_capsule_clear,"capsule_failure_raw":raw_capsule,"loaded_wall_capsule":loaded_wall,"raw_direction":rider._trick_input.direction(),"direction_age":rider._trick_input.direction_age(),
			"input":{"push":Input.get_action_strength("push"),"brake":Input.get_action_strength("brake"),
				"left":Input.get_action_strength("steer_left"),"right":Input.get_action_strength("steer_right"),
				"ollie":Input.get_action_strength("ollie"),"manual":Input.get_action_strength("manual"),"grind":Input.get_action_strength("grind")}}
		frames.append(row)
		if not model or not capsule or not shoes or not skin or not native_wall:
			if failures.size()<12:failures.append(row)

	func _raw_pose_hits(rider: CharacterBody3D,margin: float) -> Dictionary:
		# Independent queries are observations only: no actor/input/query-state mutation.
		var query:=PhysicsShapeQueryParameters3D.new()
		query.collision_mask=1
		query.exclude=[rider.get_rid()]
		query.margin=margin
		query.shape=rider._visual_rig.board_contact_geometry().convex_shape
		query.transform=rider._board_visual.global_transform
		var space:=rider.get_world_3d().direct_space_state
		var board_hits:=space.intersect_shape(query,8)
		var saturated: bool=board_hits.size()>=8
		var result: Array[Dictionary]=[]
		for hit: Dictionary in board_hits:result.append(_hit_record(hit,"whole_board_convex"))
		var shoes_clear:=true
		var box:=BoxShape3D.new()
		query.shape=box
		for index: int in rider._visual_rig._legs.size():
			var bounds: AABB=rider._obstacle_shoe_bounds[index]
			box.size=bounds.size
			query.transform=rider._visual_rig._legs[index].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
			var hits:=space.intersect_shape(query,8)
			saturated=saturated or hits.size()>=8
			shoes_clear=shoes_clear and hits.is_empty()
			for hit: Dictionary in hits:result.append(_hit_record(hit,"shoe_"+str(index)))
		return {"margin":margin,"hits":result,"shoes_clear":shoes_clear,"saturated":saturated}
	func _hit_record(hit: Dictionary,part: String) -> Dictionary:
		return {"part":part,"rid":str(hit.rid),"shape":int(hit.shape),"collider":str(hit.collider.get_path())}

	func _raw_capsule(rider: CharacterBody3D) -> Dictionary:
		var collision: CollisionShape3D=rider.get_node("BodyCollision")
		var capsule: CapsuleShape3D=collision.shape
		var index: int=-1
		for owner: int in rider.get_shape_owners():
			if rider.shape_owner_get_owner(owner)==collision:index=rider.shape_owner_get_shape_index(owner,0)
		var native_frame: Transform3D=PhysicsServer3D.body_get_state(rider.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		if index>=0:native_frame=native_frame*PhysicsServer3D.body_get_shape_transform(rider.get_rid(),index)
		var rows: Array[Dictionary]=[]
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=capsule
		query.collision_mask=1
		query.exclude=[rider.get_rid()]
		var space:=rider.get_world_3d().direct_space_state
		for frame_id: String in ["node","native_body_shape"]:
			query.transform=collision.global_transform if frame_id=="node" else native_frame
			for margin: float in [0.0,.001]:
				query.margin=margin
				var hits:=space.intersect_shape(query,16)
				var pairs:=space.collide_shape(query,32)
				var ids: Array[Dictionary]=[]
				for hit: Dictionary in hits:ids.append(_hit_record(hit,"capsule"))
				rows.append({"frame_id":frame_id,"frame":query.transform,"margin":margin,"hits":ids,"contact_pairs":pairs,"hits_saturated":hits.size()>=16,"pairs_saturated":pairs.size()>=32})
		var point: Vector3=rider._wall.contact_point
		var normal: Vector3=rider._wall.normal
		var native_wall: Dictionary={}
		if rider.wallriding:
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+normal*.1,point-normal*.1,1,[rider.get_rid()]))
			if not hit.is_empty():
				var signed: float=(native_frame.origin-Vector3(hit.position)).dot(Vector3(hit.normal)) \
					-maxf(0,capsule.height*.5-capsule.radius)*absf(native_frame.basis.y.dot(Vector3(hit.normal))) \
					-capsule.radius*(native_frame.basis.transposed()*Vector3(hit.normal)).length()
				native_wall={"rid":str(hit.rid),"shape":int(hit.shape),"point":hit.position,"normal":hit.normal,
					"collider":str(hit.collider.get_path()),"native_capsule_signed_gap":signed}
		return {"node_frame":collision.global_transform,"native_frame":native_frame,"native_shape_index":index,
			"current_body_global":rider.global_transform,"node_shape_local":collision.transform,
			"native_shape_local":PhysicsServer3D.body_get_shape_transform(rider.get_rid(),index) if index>=0 else Transform3D.IDENTITY,
			"actual_last_motion":rider.get_last_motion(),"actual_position_delta":rider.get_position_delta(),
			"native_shape_rid":str(PhysicsServer3D.body_get_shape(rider.get_rid(),index)) if index>=0 else "",
			"capsule_rid":str(capsule.get_rid()),"radius":capsule.radius,"height":capsule.height,
			"actual_air":rider.airborne,"actual_wall":rider.wallriding,"actual_floor":rider.is_on_floor(),
			"wall_face":native_wall,"query_records":rows}

	func _loaded_wall_capsule(rider: CharacterBody3D,frame: Transform3D,identity: Dictionary={}) -> Dictionary:
		# Captured wall support is loaded contact. Keep the raw1mm hit and
		# accept only a zero-penetration actual capsule against its own fresh
		# finite supporting face. Every other face/owner/unloaded air stays strict.
		if not rider.wallriding or not rider._wall.active or rider.is_on_floor() or rider._wall.wall_id!=str(wall.get_path()):return {"clear":false,"reason":"not_current_loaded_wall"}
		if not frame.origin.is_finite() or not frame.basis.is_finite() \
			or not is_finite(frame.basis.determinant()) or frame.basis.determinant()<=0:return {"clear":false,"reason":"invalid_frame"}
		var collision: CollisionShape3D=rider.get_node("BodyCollision")
		var capsule: CapsuleShape3D=collision.shape
		var index: int=-1
		for owner: int in rider.get_shape_owners():
			if rider.shape_owner_get_owner(owner)==collision:index=rider.shape_owner_get_shape_index(owner,0)
		if not is_finite(rider.safe_margin) or rider.safe_margin<0:return {"clear":false,"reason":"invalid_native_solver_margin"}
		if collision.disabled or index<0 or not is_finite(capsule.radius) or not is_finite(capsule.height) \
			or capsule.radius<=0 or capsule.height<capsule.radius*2:return {"clear":false,"reason":"invalid_actual_shape"}
		var binding:=_native_capsule_binding(rider,collision,index)
		if not bool(binding.clear):return {"clear":false,"reason":"native_local_binding_refused","binding":binding}
		var current_bound: Transform3D=binding.current_node_body_native_local_frame
		if not _same_actual_frame(frame,collision.global_transform) or not _same_actual_frame(frame,current_bound):return {"clear":false,"reason":"not_actual_native_frame"}
		var point: Vector3=rider._wall.contact_point
		var normal: Vector3=rider._wall.normal
		if not point.is_finite() or not normal.is_finite() or absf(normal.length_squared()-1)>.00001 \
			or absf(normal.y)>.18:return {"clear":false,"reason":"invalid_wall_source"}
		var space:=rider.get_world_3d().direct_space_state
		var face:=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+normal*.1,point-normal*.1,1,[rider.get_rid()]))
		if face.is_empty() or face.collider!=wall or face.rid!=wall.get_rid() or typeof(face.shape)!=TYPE_INT \
			or not Vector3(face.position).is_finite() or not Vector3(face.normal).is_finite() \
			or not is_finite(Vector3(face.normal).length_squared()) or absf(Vector3(face.normal).length_squared()-1)>.00001 \
			or Vector3(face.normal).dot(normal)<.999:return {"clear":false,"reason":"unproven_finite_current_face"}
		if not identity.is_empty() and (identity.get("rid")!=face.rid or int(identity.get("shape",-1))!=int(face.shape) \
			or not Vector3(identity.get("normal",Vector3.ZERO)).is_finite() \
			or absf(Vector3(identity.get("normal",Vector3.ZERO)).length_squared()-1)>.00001 \
			or Vector3(identity.get("normal",Vector3.ZERO)).dot(Vector3(face.normal))<.999):return {"clear":false,"reason":"wrong_expected_identity"}
		normal=face.normal
		point=face.position
		var gap_classification:=_wall_gap_classification(frame,capsule.radius,capsule.height,point,normal,rider.safe_margin)
		if not bool(gap_classification.clear):return {"clear":false,"reason":"penetrating_or_not_loaded_near_face","classification":gap_classification}
		var signed_gap: float=gap_classification.signed_gap
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=capsule
		query.transform=frame
		query.collision_mask=1
		query.exclude=[rider.get_rid()]
		query.margin=0
		if not space.intersect_shape(query,1).is_empty():return {"clear":false,"reason":"zero_margin_actual_overlap"}
		query.margin=.001
		var hits:=space.intersect_shape(query,16)
		var pairs:=space.collide_shape(query,32)
		if hits.is_empty() or hits.size()>=16 or pairs.is_empty() or pairs.size()%2!=0 or pairs.size()>=32:return {"clear":false,"reason":"missing_or_saturated_contact_data"}
		for hit: Dictionary in hits:
			if hit.rid!=face.rid or typeof(hit.shape)!=TYPE_INT or int(hit.shape)!=int(face.shape):return {"clear":false,"reason":"other_contact_owner_or_shape"}
		var finite_pairs: Array[Dictionary]=[]
		for offset: int in range(0,pairs.size(),2):
			var a: Vector3=pairs[offset]
			var b: Vector3=pairs[offset+1]
			var separation: Vector3=b-a
			if not a.is_finite() or not b.is_finite() or not separation.is_finite() \
				or not is_finite(separation.length_squared()) or separation.length_squared()<.000000000001 \
				or separation.normalized().dot(normal)<.999 or absf((b-point).dot(normal))>.002:return {"clear":false,"reason":"contact_pair_not_on_supporting_face"}
			var proof:=space.intersect_ray(PhysicsRayQueryParameters3D.create(b+normal*.02,b-normal*.02,1,[rider.get_rid()]))
			if proof.is_empty() or proof.rid!=face.rid or typeof(proof.shape)!=TYPE_INT or int(proof.shape)!=int(face.shape) \
				or not Vector3(proof.position).is_finite() or not Vector3(proof.normal).is_finite() \
				or not is_finite(Vector3(proof.normal).length_squared()) or absf(Vector3(proof.normal).length_squared()-1)>.00001 \
				or Vector3(proof.normal).dot(normal)<.999 or Vector3(proof.position).distance_to(b)>.002:return {"clear":false,"reason":"contact_pair_finite_face_miss"}
			finite_pairs.append({"query_point":a,"environment_point":b,"fresh_point":proof.position,"fresh_normal":proof.normal})
		return {"clear":true,"contract":"actual_zero_penetration_loaded_wall_contact","rid":str(face.rid),"shape":int(face.shape),
			"normal":normal,"point":point,"signed_gap":signed_gap,"node_frame":frame,"native_binding":binding,
			"native_shape_index":index,"radius":capsule.radius,"height":capsule.height,"raw_margin":.001,
			"zero_margin_overlap":false,"hits":hits.size(),"pairs":finite_pairs,"solver_safe_margin":rider.safe_margin}
	func _same_actual_frame(a: Transform3D,b: Transform3D) -> bool:
		return a.origin.is_finite() and b.origin.is_finite() and a.basis.is_finite() and b.basis.is_finite() \
			and a.origin.distance_to(b.origin)<.00001 and a.basis.x.distance_to(b.basis.x)<.00001 \
			and a.basis.y.distance_to(b.basis.y)<.00001 and a.basis.z.distance_to(b.basis.z)<.00001
	func _loaded_wall_negatives(rider: CharacterBody3D,proof: Dictionary) -> void:
		wall_load_controls_ran=true
		var frame: Transform3D=rider.get_node("BodyCollision").global_transform
		var identity={"rid":wall.get_rid(),"shape":int(proof.shape),"normal":Vector3(proof.normal)}
		var foreign=identity.duplicate()
		foreign.rid=game.world._outdoors.get_node("ClydeNorthQuay").get_rid()
		var shape=identity.duplicate()
		shape.shape=int(proof.shape)+1
		var wrong_face=identity.duplicate()
		wrong_face.normal=-Vector3(proof.normal)
		for item: Dictionary in [{"id":"foreign_owner","identity":foreign},{"id":"wrong_integer_shape","identity":shape},{"id":"opposite_face_normal_same_shape","identity":wrong_face}]:
			var rejected: Dictionary=_loaded_wall_capsule(rider,frame,item.identity)
			wall_load_controls_clear=wall_load_controls_clear and not bool(rejected.get("clear",false))
			wall_load_controls.append({"id":item.id,"result":rejected})
		var deep:=frame
		deep.origin-=Vector3(proof.normal)*.020
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=rider.get_node("BodyCollision").shape
		query.transform=deep
		query.collision_mask=1
		query.exclude=[rider.get_rid()]
		query.margin=0
		var actual_deep_hit: bool=not rider.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
		var rejected: Dictionary=_loaded_wall_capsule(rider,deep)
		wall_load_controls_clear=wall_load_controls_clear and actual_deep_hit and not bool(rejected.get("clear",false))
		var deep_classification:=_wall_gap_classification(deep,float(proof.radius),float(proof.height),Vector3(proof.point),Vector3(proof.normal),rider.safe_margin)
		wall_load_controls_clear=wall_load_controls_clear and not bool(deep_classification.clear)
		wall_load_controls.append({"id":"20mm_deep_query_only_proxy","actual_zero_margin_hit":actual_deep_hit,
			"actual_frame_auth_refusal":rejected,"independent_pure_signed_plane_classification":deep_classification,
			"scope":"modified proxy is not actual Node/native frame; actual helper refuses before its gap branch"})
		var bad_margin:=_wall_gap_classification(frame,float(proof.radius),float(proof.height),Vector3(proof.point),Vector3(proof.normal),NAN)
		var bad_normal:=_wall_gap_classification(frame,float(proof.radius),float(proof.height),Vector3(proof.point),Vector3(proof.normal)*2,rider.safe_margin)
		wall_load_controls_clear=wall_load_controls_clear and not bool(bad_margin.clear) and not bool(bad_normal.clear)
		wall_load_controls.append({"id":"pure_nan_solver_margin","result":bad_margin})
		wall_load_controls.append({"id":"pure_nonunit_native_normal","result":bad_normal})
		var bad:=frame
		bad.origin.x=NAN
		var nan_result: Dictionary=_loaded_wall_capsule(rider,bad)
		var huge:=frame
		huge.basis=Basis.from_scale(Vector3(1e20,1e20,1e20))
		var huge_result: Dictionary=_loaded_wall_capsule(rider,huge)
		wall_load_controls_clear=wall_load_controls_clear and not bool(nan_result.get("clear",false)) and not bool(huge_result.get("clear",false))
		wall_load_controls.append({"id":"nonfinite_origin","result":nan_result})
		wall_load_controls.append({"id":"finite_entries_overflow_determinant","result":huge_result})
		var invalid_backend: Transform3D=proof.native_binding.backend_body_state_shape_frame
		invalid_backend.origin.x=NAN
		var phase_bad:=_pending_motion_phase(frame,invalid_backend,rider.get_last_motion(),rider.get_position_delta())
		var overflow_backend:=frame
		overflow_backend.basis=Basis.from_scale(Vector3(1e20,1e20,1e20))
		var phase_overflow:=_pending_motion_phase(frame,overflow_backend,rider.get_last_motion(),rider.get_position_delta())
		wall_load_controls_clear=wall_load_controls_clear and not bool(phase_bad.clear) and not bool(phase_overflow.clear)
		wall_load_controls.append({"id":"pure_nonfinite_backend_origin","result":phase_bad})
		wall_load_controls.append({"id":"pure_backend_determinant_overflow","result":phase_overflow})

	func _wall_gap_classification(frame: Transform3D,radius: float,height: float,point: Vector3,normal: Vector3,limit: float) -> Dictionary:
		# Pure signed-plane calculation only; never grants native contact authority.
		if not frame.origin.is_finite() or not frame.basis.is_finite() or not is_finite(frame.basis.determinant()) \
			or frame.basis.determinant()<=0 or not is_finite(radius) or not is_finite(height) or radius<=0 or height<radius*2 \
			or not point.is_finite() or not normal.is_finite() or not is_finite(normal.length_squared()) \
			or absf(normal.length_squared()-1)>.00001 or not is_finite(limit) or limit<0:return {"clear":false,"reason":"invalid_pure_inputs"}
		var gap: float=(frame.origin-point).dot(normal)-maxf(0,height*.5-radius)*absf(frame.basis.y.dot(normal)) \
			-radius*(frame.basis.transposed()*normal).length()
		if not is_finite(gap):return {"clear":false,"reason":"nonfinite_signed_gap"}
		return {"clear":gap>=0 and gap<=limit,"signed_gap":gap,"reason":"negative_gap" if gap<0 else ("outside_solver_proximity" if gap>limit else "nonnegative_plane_proximity_only")}

	func _native_capsule_binding(rider: CharacterBody3D,collision: CollisionShape3D,index: int) -> Dictionary:
		# The authoritative current query frame uses the CURRENT body Node and
		# authenticated server LOCALshape. Server GLOBALstate can still be queued;
		# retain it and prove its actual slide-motion relationship, never use it
		# as a substitute for current-pose clearance.
		var capsule: CapsuleShape3D=collision.shape
		var native_rid: RID=PhysicsServer3D.body_get_shape(rider.get_rid(),index)
		if native_rid!=collision.shape.get_rid() or PhysicsServer3D.shape_get_type(native_rid)!=PhysicsServer3D.SHAPE_CAPSULE:return {"clear":false,"reason":"wrong_native_shape_resource"}
		var data: Variant=PhysicsServer3D.shape_get_data(native_rid)
		if typeof(data)!=TYPE_DICTIONARY or not data.has_all(["radius","height"]):return {"clear":false,"reason":"missing_native_capsule_dimensions"}
		if not is_finite(float(data.radius)) or not is_finite(float(data.height)) \
			or absf(float(data.radius)-capsule.radius)>.0000001 or absf(float(data.height)-capsule.height)>.0000001:return {"clear":false,"reason":"different_native_capsule_dimensions"}
		var local: Transform3D=PhysicsServer3D.body_get_shape_transform(rider.get_rid(),index)
		if not _valid_full_frame(local) or not _valid_full_frame(rider.global_transform):return {"clear":false,"reason":"invalid_native_local_or_current_body_frame"}
		if collision.get_parent()!=rider or not _same_actual_frame(local,collision.transform):return {"clear":false,"reason":"local_shape_notification_mismatch"}
		var current: Transform3D=rider.global_transform*local
		if not _same_actual_frame(current,collision.global_transform):return {"clear":false,"reason":"current_full_shape_frame_mismatch"}
		var backend_body: Transform3D=PhysicsServer3D.body_get_state(rider.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		var backend_shape: Transform3D=backend_body*local
		var last_motion: Vector3=rider.get_last_motion()
		var position_delta: Vector3=rider.get_position_delta()
		if not _valid_full_frame(backend_body):return {"clear":false,"reason":"nonfinite_or_invalid_backend_body"}
		var phase_proof:=_pending_motion_phase(current,backend_shape,last_motion,position_delta)
		if not bool(phase_proof.clear):return {"clear":false,"reason":"unexplained_pending_native_transform","phase_proof":phase_proof}
		var delta: Vector3=phase_proof.delta
		var phase: String=phase_proof.phase
		return {"clear":true,"phase":phase,"rid":str(native_rid),"index":index,"native_dimensions":data,
			"current_node_body_native_local_frame":current,"node_body_global":rider.global_transform,"native_local_shape":local,
			"node_local_shape":collision.transform,"backend_body_state_shape_frame":backend_shape,
			"backend_to_current_delta":delta,"last_motion":last_motion,"position_delta":position_delta,
			"scope":"current-pose geometry only; backendglobalstate never replaces the actual Node query frame"}


	func _valid_full_frame(frame: Transform3D) -> bool:
		return frame.origin.is_finite() and frame.basis.is_finite() and is_finite(frame.basis.determinant()) and frame.basis.determinant()>0
	func _pending_motion_phase(current: Transform3D,backend: Transform3D,last_motion: Vector3,position_delta: Vector3) -> Dictionary:
		if not _valid_full_frame(current) or not _valid_full_frame(backend):return {"clear":false,"reason":"invalid_current_or_backend_full_frame"}
		var delta: Vector3=current.origin-backend.origin
		if not delta.is_finite():return {"clear":false,"reason":"nonfinite_backend_to_current_delta"}
		if _same_actual_frame(current,backend):return {"clear":true,"phase":"already_synchronized","delta":delta}
		if not last_motion.is_finite() or not position_delta.is_finite() \
			or not _same_actual_frame(Transform3D(current.basis,Vector3.ZERO),Transform3D(backend.basis,Vector3.ZERO)) \
			or delta.distance_to(last_motion)>.00001 or delta.distance_to(position_delta)>.00001:return {"clear":false,"reason":"unexplained_pending_actual_motion","current":current,"backend":backend,"delta":delta,"last_motion":last_motion,"position_delta":position_delta}
		return {"clear":true,"phase":"pending_actual_current_slide_motion","delta":delta}

func _finish_new_bank(game: Node,e: Dictionary) -> void:
	# Existing first-bank helper's old count cannot terminate a later segment.
	var before: int=e.banks
	Driver._release()
	Input.action_press("brake")
	for tick: int in 240:
		await Driver._step(self,game,e,"final_new_bank",Callable())
		if e.banks>before and not game.skater.airborne and not game.skater.grinding:break
	await Driver._steps(self,game,e,24,"final_new_bank_observation",Callable())
	Driver._release()
