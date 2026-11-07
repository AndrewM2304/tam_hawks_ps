extends RefCounted
## November geometry admission: fixed native witnesses, directed bank input,
## ordinary seating captures and an unbroken two-bearing/manual relay.
const Routes=preload("res://tests/world_routes_tests.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const BoundaryFaces=preload("res://tests/pt24_boundary_tests.gd")
const EdgeTrial=preload("res://tests/edge_grind_integration_tests.gd")
const FIRST="Grind_Edge_Bench_x800y244z5900_0_0"
const SECOND="Grind_Edge_Bench_x7000y244z5900_0_0"


class ExitModelWitness extends Node:
	# Run after the real skater physics callback. A render observer may advance
	# several physical steps; every step still authenticates the actual GLB.
	var rider: Node
	var clear:=true
	var samples: Array[Dictionary]=[]
	var completed: Array[String]=[]
	var phase:=""
	var air_frames:=0
	var age:=0
	var armed:=false
	var loaded_frame:=Transform3D.IDENTITY
	var loaded_origin:=Vector3.ZERO
	var loaded_capsule:=Transform3D.IDENTITY
	var loaded_visual:=Transform3D.IDENTITY
	var loaded_rider:=Transform3D.IDENTITY
	var loaded_certified:=false

	func arm(id: String,native_supported: bool) -> void:
		loaded_frame=rider._board_visual.global_transform
		loaded_origin=rider.global_position
		loaded_capsule=rider.get_node("BodyCollision").global_transform
		loaded_visual=rider._visual.global_transform
		loaded_rider=rider._rider_visual.global_transform
		loaded_certified=native_supported and rider.grinding
		phase=id
		air_frames=0
		age=0
		armed=true
		_sample("release_input")

	func _physics_process(_delta: float) -> void:
		if not armed:return
		age+=1
		_sample("actual_air" if rider.airborne else "release_transition")
		if rider.airborne:air_frames+=1
		if air_frames>=4:
			completed.append(phase)
			armed=false
		elif age>=30 or rider.bail_active:
			clear=false
			armed=false

	func _sample(state: String) -> void:
		var actual: Transform3D=rider._board_visual.global_transform
		var proof:="separated_native_components"
		var allowed: bool
		if state=="release_input":
			# A loaded hanger is intentionally in real finite bearing contact;
			# the manual no-contact volume oracle is not its physical contract.
			proof="authenticated_loaded_bearing"
			allowed=loaded_certified
		elif rider.global_position.distance_to(loaded_origin)<0.00001:
			# Native release initially changes state before the body travels.
			# Preserve that SAME authenticated actual frame within10micrometres,
			# rather than inventing a new ground/air roll through the seat.
			proof="unchanged_loaded_frame"
			allowed=retained_clear(actual,rider.get_node("BodyCollision").global_transform,
				rider._visual.global_transform)
		else:
			allowed=rider._manual_model_frame_clear(actual)
		clear=clear and allowed
		samples.append({"phase":phase,"state":state,"proof":proof,"physics":Engine.get_physics_frames(),
			"at":rider.global_position,"board":actual,"rider_root_change":rider._rider_visual.global_position.distance_to(loaded_rider.origin),"clear":allowed})

	func retained_clear(board: Transform3D,capsule: Transform3D,visual: Transform3D) -> bool:
		# Articulated rider posture may unload while sole IK stays planted;
		# those separate Motion/contact gates must not freeze a natural pop.
		return loaded_certified and _same_frame(board,loaded_frame) and _same_frame(capsule,loaded_capsule) \
			and _same_frame(visual,loaded_visual)

	func _same_frame(actual: Transform3D,expected: Transform3D) -> bool:
		return actual.origin.distance_to(expected.origin)<0.00001 \
			and actual.basis.x.distance_to(expected.basis.x)<0.00001 \
			and actual.basis.y.distance_to(expected.basis.y)<0.00001 \
			and actual.basis.z.distance_to(expected.basis.z)<0.00001


class AirWallWitness extends Node:
	# Ordinary charged Ollies have no named loaded hanger contact. Inspect the
	# actual board hull after every controller physics callback, so a single
	# airborne wall clip cannot hide between the slower chase-camera samples.
	var rider: Node
	var checked:=0
	var clear:=true
	var shoe_clear:=true
	var offset_clear:=true
	var capsule_clear:=true
	var landing_clear:=true
	var owner_only_clear:=true
	var owner_only_frames:=0
	var foreign_ran:=false
	var foreign_rejected:=false
	var foreign_hint: Dictionary={}
	var saw_air:=false
	var residual_frames:=0
	var maximum_offset:=0.0
	var maximum_step:=0.0
	var previous_offset:=Vector3.ZERO
	var failures: Array[Dictionary]=[]

	func _physics_process(_delta: float) -> void:
		var offset: Vector3=rider._obstacle_visual_offset
		var offset_step:=offset.distance_to(previous_offset)
		previous_offset=offset
		if not rider.airborne:
			if saw_air and rider.is_on_floor():
				landing_clear=landing_clear and rider._obstacle_air_wall.is_empty() and rider._obstacle_air_wall_owner.is_empty()
			return
		saw_air=true
		checked+=1
		var actual: Transform3D=rider._board_visual.global_transform
		var sample_clear: bool=rider._manual_model_frame_clear(actual)
		clear=clear and sample_clear
		var capsule_sample:=EdgeTrial._capsule_clear(rider)
		capsule_clear=capsule_clear and capsule_sample
		maximum_offset=maxf(maximum_offset,offset.length())
		maximum_step=maxf(maximum_step,offset_step)
		var finite_offset:=offset.is_finite() and absf(offset.y)<=0.000001 and offset.length()<=0.18 and offset_step<=0.18
		offset_clear=offset_clear and finite_offset
		var full_skin_clear:=true
		if rider._obstacle_air_wall.is_empty() and not rider._obstacle_air_wall_owner.is_empty():
			owner_only_frames+=1
			owner_only_clear=owner_only_clear and offset==Vector3.ZERO
		if not rider._obstacle_air_wall.is_empty():
			residual_frames+=1
			# This helper rechecks the displayed convex board and both native
			# shoe volumes with the existing8mm skin. It cannot skip the wall RID.
			full_skin_clear=rider._obstacle_air_clear(Vector3.ZERO)
			shoe_clear=shoe_clear and full_skin_clear
			if not foreign_ran and rider.velocity.y<0 and not rider.is_on_wall() and offset!=Vector3.ZERO:
				_foreign_owner_negative()
		if (not sample_clear or not full_skin_clear or not finite_offset or not capsule_sample) and failures.size()<8:
			failures.append({"physics":Engine.get_physics_frames(),"at":rider.global_position,"board":actual,
				"components_clear":sample_clear,"capsule_clear":capsule_sample,"board_shoe_skin_clear":full_skin_clear,"offset":offset,"offset_step":offset_step,
				"air_wall":rider._obstacle_air_wall.duplicate(),"is_on_wall":rider.is_on_wall(),"is_on_floor":rider.is_on_floor(),
				"launch":rider._launch_id,"velocity":rider.velocity,"native_component_hits":_component_hits(actual)})

	func _component_hits(actual: Transform3D) -> Array[Dictionary]:
		var result: Array[Dictionary]=[]
		var query:=PhysicsShapeQueryParameters3D.new()
		query.transform=actual
		query.collision_mask=1|2|8
		query.exclude=[rider.get_rid()]
		query.margin=0.0
		var space: PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
		for index: int in rider._grind_clearance._parts.size():
			query.shape=rider._grind_clearance._parts[index].shape
			var hits: Array[Dictionary]=[]
			for hit: Dictionary in space.intersect_shape(query,4):
				hits.append({"collider":str(hit.collider.get_path()),"rid":hit.rid,"shape":hit.shape})
			if not hits.is_empty():result.append({"component":index,"hits":hits,"rest":space.get_rest_info(query)})
		return result

	func _foreign_owner_negative() -> void:
		# A deliberate fault injection, never a successful-input fixture: swap
		# only owner RID/shape to a real different floor while retaining the old
		# wall hint. No native actor/input mutation or physics advance occurs.
		if foreign_hint.is_empty():return
		foreign_ran=true
		var saved_visual: Transform3D=rider._visual.transform
		var saved_offset: Vector3=rider._obstacle_visual_offset
		var saved_active: Dictionary=rider._obstacle_air_wall.duplicate()
		var saved_owner: Dictionary=rider._obstacle_air_wall_owner.duplicate()
		var wrong: Dictionary=saved_owner.duplicate()
		wrong.rid=foreign_hint.rid
		wrong.shape=foreign_hint.shape
		wrong.collider=foreign_hint.collider
		var unfitted:=saved_visual
		unfitted.origin-=rider.global_basis.inverse()*saved_offset
		rider._visual.transform=unfitted
		rider._obstacle_visual_offset=Vector3.ZERO
		rider._obstacle_air_wall={}
		rider._obstacle_air_wall_owner=wrong
		var accepted: bool=rider._place_air_wall_wheels(1.0/60.0)
		foreign_rejected=not accepted and rider._obstacle_visual_offset==Vector3.ZERO \
			and rider._visual.transform==unfitted
		# Restore the exact displayed native-supported presentation before the
		# callback returns. The next physical/input step sees no injected state.
		rider._visual.transform=saved_visual
		rider._obstacle_visual_offset=saved_offset
		rider._obstacle_air_wall=saved_active
		rider._obstacle_air_wall_owner=saved_owner


static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await Driver._frames(tree,2)
	var world: Node3D=game.world
	var feature: Dictionary={}
	for candidate: Dictionary in world.get_skate_feature_definitions():
		if candidate.id=="exchange_south_line":feature=candidate
	check.call(not feature.is_empty() and feature.position.distance_to(Vector3(-10,0,20))<0.002
		and feature.line[0].distance_to(Vector3(-10,0,9))<0.002
		and feature.line[-1].distance_to(Vector3(-10,0,31))<0.002,
		"November lines: existing Exchange bank follows fixed west-fountain exit witnesses")
	var parity:=true
	for z: float in [12.8,13.2,14,15,16,16.8,17.2,19,22.8,23.2,24,25,26,26.8,27.2]:
		for x: float in [-11.7,-10,-8.3]:
			var expected:=0.55*clampf(minf(z-13,27-z)/4.0,0,1)
			var at:=Vector3(x,expected,z)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.1,at-Vector3.UP*0.1,1))
			parity=parity and absf(world.get_ground_height(at)-expected)<0.002 \
				and not hit.is_empty() and absf(Vector3(hit.position).y-expected)<0.002
	check.call(parity,"November lines:45 independent rotated-bank witnesses match native and query support")
	var passage:=true
	for x: float in [-22,-12,-10,-8,0,12,22]:
		passage=passage and Routes._clear_standing(world,Vector3(x,0,28))
	passage=passage and Routes._clear_sweep(world,Vector3(-22,0,28),Vector3(22,0,28)) \
		and Routes._clear_sweep(world,Vector3(22,0,28),Vector3(-22,0,28))
	check.call(passage,"November lines: unchanged Z28 beginner crossing keeps full native two-way passage")
	var tracks: Dictionary={}
	for line in world.get_grind_lines():tracks[line.id]=line
	var seats:=tracks.has(FIRST) and tracks.has(SECOND)
	if seats:
		seats=tracks[FIRST].points[0].distance_to(Vector3(39.32,2.53,63.725))<0.002 \
			and tracks[FIRST].length>5.3 and tracks[SECOND].length>5.3
	check.call(seats,"November lines: both real extended seats preserve original semantic edge identities")
	var contact:=seats
	if seats:
		for id: String in [FIRST,SECOND]:
			var line: RefCounted=tracks[id]
			contact=contact and line.contact_verified and line.contact_source=="skate_edges.native_box_top" \
				and absf(line.contact_vertical_offset+0.04)<0.000001 and line.native_support_rids.size()==1 \
				and line.contact_edge_outward.length_squared()>0.999
	check.call(contact,"November lines: only inspected seat boxes publish exact finite native top/face/RID contact")
	var bypass:=true
	for z: float in [68.0,68.5,69.0,69.5,70.0,70.5,71.0,71.5,72.0]:
		var start:=Vector3(24,2,z)
		var finish:=Vector3(78,2,z)
		bypass=bypass and Routes._clear_sweep(world,start,finish) and Routes._clear_sweep(world,finish,start)
		for x: float in [24,32,42,54,64,76]:
			bypass=bypass and Routes._ground_below(world,Vector3(x,2,z))
	check.call(bypass,"November lines: independent nine-lane sweeps retain the complete4m east-quay bypass")
	var seat_count:=0
	var seat_shapes:=0
	var supports:=0
	for body: Node3D in world.find_children("*","Node3D",true,false):
		if body.global_position.z<55 or body.global_position.z>78:continue
		var label:=String(body.get_meta("art_label",""))
		if label=="QuayBenchSupport":supports+=1
		if label!="QuayBenchSeat":continue
		seat_count+=1
		for child: Node in body.get_children():
			if child is CollisionShape3D:seat_shapes+=1
	check.call(seat_count==3 and seat_shapes==3 and supports==6,
		"November lines: existing quay seating retains exactly three bodies/shapes and six decorative supports")
	if not feature.is_empty():await Density._manual_crossing(tree,game,feature,check,observer)
	if seats:
		await EdgeTrial._approach(tree,game,world.get_grind_lines(),check,
			{"family":"Bench_x800y244z5900_","at":Vector3(40,2.53,63.725),"direction":Vector3.RIGHT,"outside":Vector3.FORWARD,"behind":0.9,"charge":2})
		var direction:=Vector3(cos(deg_to_rad(15)),0,-sin(deg_to_rad(15)))
		await EdgeTrial._approach(tree,game,world.get_grind_lines(),check,
			{"family":"Bench_x7000y244z5900_","at":tracks[SECOND].points[0],"direction":direction,"outside":Vector3(-direction.z,0,direction.x)*-1,"behind":0.9,"charge":2})
		await run_relay(tree,game,check,observer)
	await run_bank_return(tree,game,check,observer)
	await run_bank_jump_misses(tree,game,check,observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await Driver._frames(tree,3)


static func run_relay(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var next_line: RefCounted
	for line: RefCounted in game.world.get_grind_lines():
		if String(line.id)==SECOND:next_line=line
	if next_line==null:
		check.call(false,"November lines: second native seat bearing exists for the real relay")
		return
	var next_start: Vector3=next_line.points[0]
	var next_direction: Vector3=(next_line.points[-1]-next_start).normalized()
	var next_outside: Vector3=next_line.contact_edge_outward
	var next_join: Vector3=next_start-next_direction*4.0+next_outside*.35
	var next_aim: Vector3=next_start+next_direction*4.0+next_outside*.35
	await Driver._reset(tree,game,Vector3(33,2.08,63.55),-PI*.5)
	await Driver._frames(tree,40)
	var exit_witness:=ExitModelWitness.new()
	exit_witness.rider=game.skater
	exit_witness.process_physics_priority=100
	game.add_child(exit_witness)
	var e:=Driver._evidence(game,"east_quay_seating_relay")
	e["event_ticks"]=[]
	e["physics_start"]=Engine.get_physics_frames()
	e["seat_fit"]=true
	Driver._connect(game,e)
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
		e.seat_fit=e.seat_fit and _native_seat_fit(game)
		e.event_ticks.append({"event":"first_catch","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		for tick: int in 120:
			await Driver._step(tree,game,e,"first_seat_ride",observer)
			if game.skater.grinding and tick%4==0:e.seat_fit=e.seat_fit and _native_seat_fit(game)
			if game.skater.global_position.x>=43.4 or not game.skater.grinding:break
		e.event_ticks.append({"event":"first_exit_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"first_outward_pop_charge",observer)
		exit_witness.arm("first_seat_release",_native_seat_fit(game))
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
		e.seat_fit=e.seat_fit and _native_seat_fit(game)
		e.event_ticks.append({"event":"second_catch","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		# Ride the finite bearing toward its end so the intended landing is the
		# paving runout. The earlier twelve-tick exit landed atop the seat and
		# exposed a separately retained native-prop visual support defect.
		for tick: int in 120:
			await Driver._step(tree,game,e,"second_seat_payoff",observer)
			if game.skater.grinding and tick%4==0:e.seat_fit=e.seat_fit and _native_seat_fit(game)
			if (game.skater.global_position-next_start).dot(next_direction)>=next_line.length-.65 or not game.skater.grinding:break
		second_pop_from_bearing=game.skater.grinding and game.skater._grind.line.id==SECOND
		e.event_ticks.append({"event":"second_exit_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"second_exit_charge",observer)
		second_pop_from_bearing=second_pop_from_bearing and game.skater.grinding and game.skater._grind.line.id==SECOND
		e.seat_fit=e.seat_fit and _native_seat_fit(game)
		e.event_ticks.append({"event":"second_exit_release","tick":e.ticks,"physics":Engine.get_physics_frames(),
			"at":game.skater.global_position,"speed":game.skater.speed,"still_on_bearing":second_pop_from_bearing})
		exit_witness.arm("second_seat_release",_native_seat_fit(game))
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
	exit_witness.free()
	await Driver._finish_bank(tree,game,e,observer)
	e.event_ticks.append({"event":"banked","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
	var complete_relay: bool=first and linked and second and e.captures==[FIRST,SECOND] and e.manual_ticks>=20 \
		and e.seat_fit and second_pop_from_bearing and paving_landing and exit_model_clear
	check.call(complete_relay,
		"November lines: real mapped Ollie/50-50/manual/Ollie/50-50 connects two seats with native model/capsule clearance")
	if first and linked and second:Driver._check_receipt(game,e,check,"November east quay")
	print("NOVEMBER_RELAY physics_start=",e.physics_start," events=",e.event_ticks," first=",first," linked=",linked," second=",second," native_seat_fit=",e.seat_fit," paving_landing=",paving_landing)
	Driver._disconnect(game,e)
	Driver._report(e,game)
	Driver._release()
	if complete_relay and e.bails==0 and e.camera_clear and e.banks==1:
		await _return_to_entry(tree,game,check,observer)


static func _native_seat_fit(game: Node) -> bool:
	var rider: Node=game.skater
	return rider.grinding and rider.grind_style_id=="grind_50_50" and rider._grind_contact.valid \
		and rider._grind_contact.anchor_count==2 and rider._grind_contact.max_error<=0.0001 \
		and EdgeTrial._capsule_clear(rider) and rider._grind_board_clear(rider._grind_contact.board_transform,rider._grind.line,rider._grind.distance) \
		and rider._grind_clearance.allows(rider._grind_contact,rider._grind.line.contact_up(rider._grind.distance))


static func _return_to_entry(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	# Continue from the actual banked landing through the terminal bank and
	# back to the entry. Neither this turnback nor the bypass uses a restart.
	var e:=Driver._evidence(game,"east_quay_bank_and_return")
	Driver._connect(game,e)
	var approach: bool=await _travel_targets(tree,game,e,[Vector3(75,2,68),Vector3(76,2,73.5),Vector3(78,2,73.5)],observer)
	var bank: Dictionary={"returned":false,"supported":false}
	if approach:bank=await _roll_bank_phase(tree,game,e,73.5,4.0,observer)
	var complete:=false
	if bank.returned:
		complete=await _travel_targets(tree,game,e,[Vector3(73,2,71),Vector3(34,2,71),Vector3(30,2,66),Vector3(33,2,63.55)],observer)
	Driver._release()
	check.call(approach and bank.returned and bank.supported and complete and e.bails==0 and e.recoveries==0
		and e.entries.is_empty() and e.camera_clear,
		"November lines: the actual relay landing climbs the terminal bank and returns fakie to entry without a reset")
	Driver._disconnect(game,e)
	Driver._report(e,game)


static func _travel_targets(tree: SceneTree,game: Node,e: Dictionary,targets: Array,observer: Callable) -> bool:
	for target: Vector3 in targets:
		var reached:=false
		for tick: int in 900:
			# A negative real speed is fakie travel. Aim the facing away from
			# its travel target, preserving native reverse motion and controls.
			var delta: Vector3=target-game.skater.global_position
			if game.skater.speed< -0.5:delta=-delta
			var desired:=atan2(-delta.x,-delta.z)
			var error: float=angle_difference(game.skater.rotation.y,desired)
			Driver._axis("spin_left","spin_right",0)
			Driver._axis("steer_left","steer_right",-clampf(error*1.8,-1,1))
			Driver._speed_input(game,4.2)
			await Driver._step(tree,game,e,"supported_return",observer)
			var point: Vector3=game.skater.global_position
			var height: float=game.world.get_support_height(point,0.3)
			if not is_finite(height) or absf(point.y-height)>=0.18 or game.skater.airborne or e.bails>0:return false
			if Vector2(point.x-target.x,point.z-target.z).length()<1.2:
				reached=true
				e.route_gates.append({"target":target,"at":point,"tick":e.ticks,"physics":Engine.get_physics_frames()})
				break
		if not reached:return false
	return true


static func run_bank_return(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var world: Node3D=game.world
	var record: Dictionary={}
	var boundary: StaticBody3D
	for body: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		if body.has_meta("bank_terminal_return"):
			boundary=body
			record=body.get_meta("bank_terminal_return")
	check.call(is_instance_valid(boundary) and not record.is_empty(),
		"November bank: original eastern terminal wall owns the integrated finite return")
	if record.is_empty():return
	var bounds: Rect2=record.bounds
	var native_triangles:=0
	var display_triangles:=0
	var live_shapes:=0
	var live_meshes:=0
	for child: Node in boundary.get_children():
		if child is CollisionShape3D:
			live_shapes+=1
			if child.shape is ConcavePolygonShape3D:native_triangles+=child.shape.get_faces().size()/3
		if child is MeshInstance3D:
			live_meshes+=1
			display_triangles+=child.mesh.get_faces().size()/3
	check.call(live_shapes==int(record.shape_count) and live_meshes==1 and native_triangles==display_triangles
		and display_triangles==live_shapes*20 and display_triangles-live_shapes*12==int(record.added_triangles),
		"November bank: direct native/display counts retain one mesh and original slots with eight added triangles per panel")
	var middle: float=bounds.get_center().y
	var geometry:=true
	for x: float in [80.9,81.3,82.0,82.9,83.6,84.2]:
		for z: float in [bounds.position.y+0.35,middle,bounds.end.y-0.35]:
			var expected:=2.0+(x-80.8)*2.0/3.9
			var at:=Vector3(x,expected,z)
			var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.08,at-Vector3.UP*.08,1)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(ray)
			geometry=geometry and not hit.is_empty() and hit.collider==boundary \
				and absf(hit.position.y-expected)<0.002 and absf(world.get_ground_height(at)-expected)<0.002 \
				and Vector3(hit.normal).dot(Vector3(-2.0/3.9,1,0).normalized())>0.999 \
				and BoundaryFaces._visible_segment(boundary,at+Vector3.UP*.08,at-Vector3.UP*.08)
	check.call(geometry,"November bank:18 independent slope witnesses share exact native/display/query planes and normals")
	var backing:=true
	for y: float in [4.15,5.5,6.85]:
		for z: float in [bounds.position.y+0.35,middle,bounds.end.y-0.35]:
			var start:=Vector3(84.4,y,z)
			var finish:=Vector3(85.1,y,z)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,finish,1))
			backing=backing and not hit.is_empty() and hit.collider==boundary \
				and absf(hit.position.x-84.7)<0.002 and BoundaryFaces._visible_segment(boundary,start,finish)
	check.call(backing,"November bank: nine fixed elevated rays preserve real opaque terminal containment")
	var shoulder:=true
	var mouth:=PackedVector3Array([Vector3(75,2,69),Vector3(78,2,67),Vector3(94,2,55)])
	for index: int in mouth.size()-1:
		var side:=Vector3((mouth[index+1]-mouth[index]).z,0,-(mouth[index+1]-mouth[index]).x).normalized()
		for offset: float in [-1.0,-0.5,0,0.5,1.0]:
			var a:=mouth[index]+side*offset
			var b:=mouth[index+1]+side*offset
			shoulder=shoulder and Routes._clear_sweep(world,a,b) and Routes._clear_sweep(world,b,a)
			for sample: int in 13:
				var point:=a.lerp(b,float(sample)/12)
				shoulder=shoulder and Routes._ground_below(world,point)
	check.call(shoulder,"November bank: existing diagonal Barras mouth retains five supported two-way shoulder sweeps")
	# Independent fixed inboard line leaves the existing river bollards clear.
	for ceiling: float in [3.2,4.0,4.6,8.0,12.0]:
		await _uphill_rollback(tree,game,73.5,ceiling,check,observer)
	# Four retained closed collision slots meet along the bank. Real sideways
	# rolling must cross their internal panel caps without a false wall/air pop.
	await _lateral_bank_crossing(tree,game,1.0,check,observer)
	await _lateral_bank_crossing(tree,game,-1.0,check,observer)
	await Driver._miss_return(tree,game,check,"east_quay_banked_wall",Vector3(74,2.08,69),-PI*.5,
		PackedVector3Array([Vector3(78,2,67),Vector3(94,2,55),Vector3(94,0,45)]),observer)
	print("NOVEMBER_BANK_GEOMETRY bounds=",bounds," profile=",record.profile,
		" shapes=",record.shape_count," native_triangles=",native_triangles," display_triangles=",display_triangles," added_triangles=",record.added_triangles)


static func run_bank_jump_misses(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	# These exact naturally accelerated uphill pops escaped the original Y5
	# backing. Keep all four inputs, actual native landing and strict chase;
	# a capsule-only containment success must not hide a board through the wall.
	for gate: float in [78.0,78.7,79.4,80.1]:
		await Driver._reset(tree,game,Vector3(66,2.08,73.5),-PI*.5)
		await Driver._frames(tree,40)
		var e:=Driver._evidence(game,"east_bank_charged_top_miss_"+str(gate))
		Driver._connect(game,e)
		var air_model:=AirWallWitness.new()
		air_model.rider=game.skater
		air_model.foreign_hint=game.world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(Vector3(66,2.2,73.5),Vector3(66,1.8,73.5),1))
		air_model.process_physics_priority=100
		game.add_child(air_model)
		var reset_air_clear: bool=game.skater._obstacle_air_wall.is_empty() and game.skater._obstacle_air_wall_owner.is_empty()
		var physics_start:=Engine.get_physics_frames()
		var charging:=false
		var released:=false
		var charge_ticks:=0
		var escaped:=false
		var native_landing:=false
		var capsule_clear:=true
		var maximum_loaded_depth:=0.0
		var loaded_contact_samples:=0
		var floor_negatives:=false
		var loaded_contact_examples: Array[Dictionary]=[]
		var loaded_floor_keys: Array[String]=[]
		var actual_air:=false
		var charge_speed:=0.0
		var peak:=Vector3.ZERO
		var maximum_x:=-INF
		var events: Array[Dictionary]=[]
		var capsule_failures: Array[Dictionary]=[]
		for tick: int in 480:
			if not released:
				Driver._steer_to(game,Vector3(88,2,73.5),false)
				Input.action_press("push")
				if not charging and game.skater.global_position.x>=gate:
					charging=true
					Input.action_press("ollie")
					charge_speed=game.skater.speed
					events.append({"event":"charge","physics":Engine.get_physics_frames(),
						"at":game.skater.global_position,"speed":charge_speed})
				if charging:
					charge_ticks+=1
					if charge_ticks>16:
						released=true
						Driver._release()
						events.append({"event":"release","physics":Engine.get_physics_frames(),
							"at":game.skater.global_position,"speed":game.skater.speed,"velocity":game.skater.velocity})
			await Driver._step(tree,game,e,"charged_uphill_top_miss",observer)
			var at: Vector3=game.skater.global_position
			maximum_x=maxf(maximum_x,at.x)
			if at.y>peak.y:peak=at
			escaped=escaped or at.x>85.2
			actual_air=actual_air or game.skater.airborne
			if tick%8==0:
				var sample_clear:=EdgeTrial._capsule_clear(game.skater)
				if not sample_clear:
					var actual_body: CollisionShape3D=game.skater.get_node("BodyCollision")
					var supported:=_loaded_capsule_contact(game,actual_body.global_transform)
					sample_clear=supported.clear
					if supported.clear and supported.get("loaded",false):
						loaded_contact_samples+=1
						maximum_loaded_depth=maxf(maximum_loaded_depth,maxf(0,-float(supported.signed_gap)))
						var floor_key:=str(supported.floor.rid)+":"+str(supported.floor.shape)
						if not loaded_floor_keys.has(floor_key):
							loaded_floor_keys.append(floor_key)
							loaded_contact_examples.append(supported)
						if not floor_negatives and supported.floor.collider.has_meta("bank_terminal_return"):
							floor_negatives=_loaded_capsule_negatives(game,actual_body.global_transform,supported.floor)
				capsule_clear=capsule_clear and sample_clear
				if not sample_clear and capsule_failures.is_empty():
					var body: CollisionShape3D=game.skater.get_node("BodyCollision")
					var capsule: CapsuleShape3D=body.shape
					var native_queries: Array[Dictionary]=[]
					for margin: float in [0.001,0.0]:
						var query:=PhysicsShapeQueryParameters3D.new()
						query.shape=body.shape
						query.transform=body.global_transform
						query.collision_mask=1
						query.exclude=[game.skater.get_rid()]
						query.margin=margin
						var space: PhysicsDirectSpaceState3D=game.world.get_world_3d().direct_space_state
						var hits: Array[Dictionary]=[]
						for hit: Dictionary in space.intersect_shape(query,8):
							hits.append({"collider":str(hit.collider.get_path()),"rid":hit.rid,"shape":hit.shape})
						var rest:=space.get_rest_info(query)
						var signed_gap:=INF
						if not rest.is_empty():
							var normal: Vector3=rest.normal
							var frame:=body.global_transform
							signed_gap=(frame.origin-Vector3(rest.point)).dot(normal) \
								-maxf(0,capsule.height*.5-capsule.radius)*absf(frame.basis.y.dot(normal)) \
								-capsule.radius*(frame.basis.transposed()*normal).length()
						native_queries.append({"margin":margin,"hits":hits,"rest":rest,"signed_capsule_gap":signed_gap,
							"contact_pairs":space.collide_shape(query,32)})
					capsule_failures.append({"physics":Engine.get_physics_frames(),"at":at,"airborne":game.skater.airborne,
						"is_on_floor":game.skater.is_on_floor(),"body":body.global_transform,"radius":capsule.radius,
						"height":capsule.height,"native_safe_margin":game.skater.safe_margin,"queries":native_queries})
			if actual_air and not native_landing and game.skater.is_on_floor() and not game.skater.airborne:
				var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.18,1))
				if not hit.is_empty() and absf(Vector3(hit.position).y-at.y)<.18:
					native_landing=true
					events.append({"event":"native_landing","physics":Engine.get_physics_frames(),"at":at,
						"collider":str(hit.collider.get_path()),"point":hit.position})
			if escaped or e.bails>0 or (released and tick>300):break
		Driver._release()
		check.call(charging and released and charge_speed>=14.9 and actual_air and native_landing and not escaped
			and maximum_x<84.43 and capsule_clear and e.bails==0 and e.recoveries==0 and e.captures.is_empty()
			and air_model.checked>10 and air_model.clear and air_model.shoe_clear and air_model.offset_clear
			and air_model.capsule_clear
			and reset_air_clear and air_model.landing_clear
			and air_model.owner_only_clear and (not air_model.foreign_ran or air_model.foreign_rejected)
			and (gate!=79.4 or (air_model.foreign_ran and floor_negatives))
			and e.entries.size()==1 and e.entries[0].id=="ollie" and e.camera_clear,
			"November bank: maximum-speed charged uphill pop stays natively contained with clear body/chase and real landing at gate"+str(gate))
		print("NOVEMBER_BANK_TOP_MISS physics_start=",physics_start," gate=",gate," events=",events,
			" escaped=",escaped," maximum_x=",maximum_x," peak=",peak," native_landing=",native_landing,
			" capsule=",capsule_clear," camera=",e.camera_clear," bails=",e.bails," recoveries=",e.recoveries," entries=",e.entries,
			" actual_air_physics=",air_model.checked," air_model_clear=",air_model.clear," air_capsule_clear=",air_model.capsule_clear," shoe_clear=",air_model.shoe_clear,
			" reset_air_clear=",reset_air_clear," landing_air_clear=",air_model.landing_clear,
			" owner_only_physics=",air_model.owner_only_frames," owner_only_zero_offset=",air_model.owner_only_clear,
			" foreign_owner_ran=",air_model.foreign_ran," foreign_owner_rejected=",air_model.foreign_rejected,
			" loaded_contact_samples=",loaded_contact_samples," maximum_loaded_depth=",maximum_loaded_depth,
			" wrong_floor_wall_deep_negatives=",floor_negatives,
			" admitted_native_floor_examples=",loaded_contact_examples,
			" residual_physics=",air_model.residual_frames," maximum_offset=",air_model.maximum_offset," maximum_step=",air_model.maximum_step,
			" model_failures=",air_model.failures," capsule_failures=",capsule_failures)
		air_model.free()
		Driver._disconnect(game,e)


static func _loaded_capsule_contact(game: Node,frame: Transform3D,expected_floor: Dictionary={}) -> Dictionary:
	# A grounded capsule can be in the native solver's intended floor contact;
	# its proxy is not an unloaded volume. Authenticate every actual pair on
	# the same fresh finite floor face. Never exclude its RID (the bank wall
	# and its floor deliberately share one body and native shape).
	var rider: CharacterBody3D=game.skater
	if rider.airborne or not rider.is_on_floor() or not rider.global_position.is_finite() \
			or not rider.get_floor_normal().is_finite():return {"clear":false}
	var body: CollisionShape3D=rider.get_node("BodyCollision")
	var capsule: CapsuleShape3D=body.shape
	if not frame.origin.is_finite() or not frame.basis.is_finite() or frame.basis.determinant()<=0 \
			or not is_finite(capsule.radius) or not is_finite(capsule.height) or capsule.radius<=0 \
			or capsule.height<capsule.radius*2 or not is_finite(rider.safe_margin) or rider.safe_margin<=0:
		return {"clear":false}
	var space:=rider.get_world_3d().direct_space_state
	var ray:=PhysicsRayQueryParameters3D.create(rider.global_position+Vector3.UP*.15,
		rider.global_position-Vector3.UP*.18,1,[rider.get_rid()])
	var floor:=space.intersect_ray(ray)
	if floor.is_empty():return {"clear":false}
	if not Vector3(floor.position).is_finite() or not Vector3(floor.normal).is_finite():return {"clear":false}
	if not expected_floor.is_empty() and (floor.rid!=expected_floor.rid or int(floor.shape)!=int(expected_floor.shape)):
		return {"clear":false}
	var normal: Vector3=floor.normal
	if normal.length_squared()<0.99:return {"clear":false}
	normal=normal.normalized()
	if normal.dot(Vector3.UP)<cos(rider.floor_max_angle) or normal.dot(rider.get_floor_normal())<0.999:
		return {"clear":false}
	var query_height: float=game.world.get_ground_height(floor.position)
	if not is_finite(query_height) or absf(query_height-float(floor.position.y))>.002:return {"clear":false}
	var signed_gap: float=(frame.origin-Vector3(floor.position)).dot(normal) \
		-maxf(0,capsule.height*.5-capsule.radius)*absf(frame.basis.y.dot(normal)) \
		-capsule.radius*(frame.basis.transposed()*normal).length()
	# This is the existing engine safe_margin, not an observed penetration or
	# a new allowance. The receipt separately records actual maximum depth.
	if not is_finite(signed_gap) or absf(signed_gap)>rider.safe_margin:return {"clear":false}
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.transform=frame
	query.collision_mask=1
	query.exclude=[rider.get_rid()]
	query.margin=.001
	var hits:=space.intersect_shape(query,16)
	if hits.is_empty():return {"clear":true,"loaded":false}
	if hits.size()>=16:return {"clear":false}
	for hit: Dictionary in hits:
		if hit.rid!=floor.rid or int(hit.shape)!=int(floor.shape):return {"clear":false}
	var pairs:=space.collide_shape(query,32)
	# Conservatively require fewer than32 returned vectors, below both the
	# requested pair capacity and its two-vectors-per-pair representation.
	if pairs.is_empty() or pairs.size()%2!=0 or pairs.size()>=32:return {"clear":false}
	for index: int in range(0,pairs.size(),2):
		if not Vector3(pairs[index]).is_finite() or not Vector3(pairs[index+1]).is_finite():return {"clear":false}
		var separation: Vector3=pairs[index+1]-pairs[index]
		# Native margin contacts are ordered query-point then environment-point.
		# A vertical wall in this SAME shape must fail the floor-normal test.
		if not separation.is_finite() or not is_finite(separation.length_squared()) \
				or separation.length_squared()<0.000000000001 or separation.normalized().dot(normal)<0.999 \
				or absf((Vector3(pairs[index+1])-Vector3(floor.position)).dot(normal))>.002:
			return {"clear":false}
	# Retain the existing lifted standing-volume check without its flat-only
	# centre-ray height shortcut. The actual capsule and actor never move.
	query.transform.origin+=Vector3.UP*rider.safe_margin
	if not space.intersect_shape(query,1).is_empty():return {"clear":false}
	return {"clear":true,"loaded":true,"signed_gap":signed_gap,"floor":floor,"contact_pairs":pairs,
		"body":frame,"radius":capsule.radius,"height":capsule.height,"native_safe_margin":rider.safe_margin,
		"actual_floor_normal":rider.get_floor_normal(),"floor_path":str(floor.collider.get_path())}


static func _loaded_capsule_negatives(game: Node,actual: Transform3D,floor: Dictionary) -> bool:
	var rider: CharacterBody3D=game.skater
	var capsule: CapsuleShape3D=rider.get_node("BodyCollision").shape
	var foreign: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(66,2.2,73.5),Vector3(66,1.8,73.5),1,[rider.get_rid()]))
	if foreign.is_empty() or foreign.rid==floor.rid:return false
	var wrong_floor: bool=not _loaded_capsule_contact(game,actual,foreign).clear
	var deep:=actual
	deep.origin-=Vector3.UP*rider.safe_margin*2.0
	var deep_rejected: bool=not _loaded_capsule_contact(game,deep).clear
	var invalid:=actual
	invalid.origin.x=NAN
	var nonfinite_rejected: bool=not _loaded_capsule_contact(game,invalid).clear
	# Slide only this diagnostic volume along the SAME supporting floor plane
	# until it also meets the real vertical backing. It must still fail even
	# though both contacts share the floor's exact native body/shape identity.
	var wall:=actual
	var shift_x: float=84.7-capsule.radius+.02-wall.origin.x
	wall.origin+=Vector3(shift_x,-float(floor.normal.x)/float(floor.normal.y)*shift_x,0)
	var wall_rejected: bool=not _loaded_capsule_contact(game,wall).clear
	print("NOVEMBER_LOADED_CAPSULE_NEGATIVES physics=",Engine.get_physics_frames(),"wrong_floor=",wrong_floor,
		" deep=",deep_rejected," nonfinite=",nonfinite_rejected," same_owner_vertical_wall=",wall_rejected," actual_gap_floor=",floor)
	return wrong_floor and deep_rejected and wall_rejected and nonfinite_rejected


static func _lateral_bank_crossing(tree: SceneTree,game: Node,direction: float,check: Callable,observer: Callable) -> void:
	var start_z:=72.2 if direction>0 else 77.1
	var finish_z:=77.1 if direction>0 else 72.2
	var x:=82.0
	var expected_y:=2.0+(x-80.8)*2.0/3.9
	await Driver._reset(tree,game,Vector3(x,expected_y+.08,start_z),PI if direction>0 else 0.0)
	await Driver._frames(tree,40)
	var e:=Driver._evidence(game,"east_bank_panel_crossing_"+str(direction))
	Driver._connect(game,e)
	var physics_start:=Engine.get_physics_frames()
	var supported:=true
	var clear:=true
	var reached:=false
	for tick: int in 300:
		Driver._steer_to(game,Vector3(x,expected_y,finish_z),false)
		Driver._speed_input(game,3.2)
		await Driver._step(tree,game,e,"native_lateral_panel_crossing",observer)
		var at: Vector3=game.skater.global_position
		var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			at+Vector3.UP*.15,at-Vector3.UP*.18,1))
		supported=supported and game.skater.is_on_floor() and not game.skater.airborne and absf(at.x-x)<.08 \
			and absf(at.y-expected_y)<.18 and not hit.is_empty() and hit.collider.has_meta("bank_terminal_return")
		if tick%8==0:clear=clear and EdgeTrial._capsule_clear(game.skater)
		if (at.z-finish_z)*direction>=-.15:
			reached=true
			break
		if e.bails>0:break
	Driver._release()
	check.call(reached and supported and clear and e.bails==0 and e.recoveries==0 and e.entries.is_empty() and e.camera_clear,
		"November bank: native sideways rolling crosses every retained panel seam in direction"+str(direction))
	print("NOVEMBER_BANK_PANEL_CROSSING start_physics=",physics_start," end_physics=",Engine.get_physics_frames(),
		" direction=",direction," supported=",supported," capsule=",clear," camera=",e.camera_clear," at=",game.skater.global_position)
	Driver._disconnect(game,e)


static func _uphill_rollback(tree: SceneTree,game: Node,z: float,ceiling: float,check: Callable,observer: Callable) -> void:
	await Driver._reset(tree,game,Vector3(66 if ceiling>=8.0 else 76,2.08,z),-PI*.5)
	await Driver._frames(tree,40)
	var e:=Driver._evidence(game,"east_bank_rollback_"+str(ceiling))
	Driver._connect(game,e)
	var result: Dictionary=await _roll_bank_phase(tree,game,e,z,ceiling,observer)
	var reached_speed: bool=ceiling<8.0 or absf(float(result.entry_speed))>=ceiling-0.5
	# High-speed containment may touch the retained wall; its capsule centre
	# remains west of X84.43 (wallX84.7 minus native radius, with query skin).
	var bounded: bool=result.peak.x<(84.43 if ceiling>=8.0 else 84.4)
	check.call(result.released and result.reverse and result.returned and result.peak.x>81.1 and bounded and result.peak.y>2.2
		and reached_speed
		and result.supported and e.bails==0 and e.recoveries==0 and e.entries.is_empty() and e.captures.is_empty() and e.camera_clear,
		"November bank: native climb/stop/fakie plus mapped Push fully clears the toe at approach cap"+str(ceiling))
	Driver._disconnect(game,e)


static func _roll_bank_phase(tree: SceneTree,game: Node,e: Dictionary,z: float,ceiling: float,observer: Callable) -> Dictionary:
	var released:=false
	var returned:=false
	var peak:=Vector3.ZERO
	var entry_speed:=0.0
	var reverse:=false
	var supported:=true
	var events: Array[Dictionary]=[]
	var physics_start:=Engine.get_physics_frames()
	var wall_contact:=false
	for tick: int in 900:
		if not released:
			Driver._steer_to(game,Vector3(84.0,2,z),false)
			Driver._speed_input(game,ceiling)
			if game.skater.global_position.x>=80.5:
				Driver._release()
				released=true
				entry_speed=game.skater.speed
				events.append({"event":"input_release","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position,"speed":entry_speed})
		# Native grade gravity must establish reversal first. Then ordinary
		# fakie pushing supplies a useful re-entry instead of slowly coasting
		# with the upright capsule/loaded wheels still straddling the toe.
		if reverse:Driver._speed_input(game,3.2)
		await Driver._step(tree,game,e,"real_uphill_and_rollback",observer)
		var point: Vector3=game.skater.global_position
		if point.y>peak.y:peak=point
		for slide: int in game.skater.get_slide_collision_count():
			var collision: KinematicCollision3D=game.skater.get_slide_collision(slide)
			for contact_index: int in collision.get_collision_count():
				var collider: Object=collision.get_collider(contact_index)
				if not wall_contact and is_instance_valid(collider) and collider.has_meta("bank_terminal_return") and collision.get_normal(contact_index).x< -0.98:
					wall_contact=true
					events.append({"event":"native_backing_contact","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"speed":game.skater.speed})
		var height: float=game.world.get_support_height(point,0.3)
		supported=supported and is_finite(height) and absf(point.y-height)<0.18 and game.skater.is_on_floor() and not game.skater.airborne
		if released and game.skater.speed< -0.5 and not reverse:
			reverse=true
			events.append({"event":"native_rollback_then_fakie_push","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"speed":game.skater.speed})
		if reverse and point.x<80.3:
			returned=true
			events.append({"event":"flat_reentry","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"speed":game.skater.speed})
			break
		if e.bails>0 or e.recoveries>0:break
	Driver._release()
	print("NOVEMBER_BANK_RETURN physics_start=",physics_start," cap=",ceiling," entry_speed=",entry_speed," peak=",peak," events=",events,
		" supported=",supported," camera=",e.camera_clear," bails=",e.bails)
	return {"released":released,"reverse":reverse,"returned":returned,"supported":supported,"peak":peak,"entry_speed":entry_speed,"wall_contact":wall_contact}
