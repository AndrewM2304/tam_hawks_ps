extends RefCounted
## Actual mapped Ollie after ordinary wall contact, with an unfitted physical
## twin. No active-state flag, actor transform or velocity is assigned here.
const Wall = preload("res://tests/skater_wall_presentation_tests.gd")


static func run(tree: SceneTree,check: Callable) -> void:
	Wall.Setup.register_actions()
	Wall._release()
	var fixture: Dictionary = await Wall._fixture(tree,-8.0)
	var rider: CharacterBody3D = fixture.rider
	var control: CharacterBody3D = fixture.control
	_shared_hull(rider,check)
	var reached := false
	Input.action_press("push",0.55)
	for tick: int in 180:
		await Wall._frames(tree,1)
		if Wall._wall_contact(rider,fixture.wall):
			reached=true
			break
	Wall._release()
	Input.action_press("brake")
	await Wall._frames(tree,20)
	Wall._release()
	# Release and press on distinct native input frames; a same-frame pair
	# can retain both Godot edge flags and become an immediate tap.
	await Wall._frames(tree,2)
	var before_gap := Wall._plane_gap(rider)
	var before_offset: Vector3 = rider._obstacle_visual_offset
	check.call(reached and rider.is_on_floor() and not rider.bail_active
		and absf(rider.speed)<0.001 and before_gap>=0.0079 and before_offset.length()>0.10,
		"wall transition: actual Push/Brake stops at a native shutter with the connected neutral fit before Ollie")
	var minimum := INF
	var old_minimum := INF
	var maximum_offset := before_offset.length()
	var air_ticks := 0
	var crouch_ticks := 0
	var floor_ticks := 0
	var parity := true
	var local_pose := true
	var bailing := false
	var trace: Array[Dictionary] = []
	Input.action_press("ollie")
	for tick: int in 70:
		if tick==12: Input.action_release("ollie")
		await Wall._frames(tree,1)
		var gap := Wall._plane_gap(rider)
		minimum=minf(minimum,gap)
		old_minimum=minf(old_minimum,Wall._plane_gap(control))
		maximum_offset=maxf(maximum_offset,rider._obstacle_visual_offset.length())
		parity=parity and Wall._physics(rider)==Wall._physics(control)
		local_pose=local_pose and rider._board_visual.transform==control._board_visual.transform \
			and rider._rider_visual.transform==control._rider_visual.transform
		air_ticks+=int(rider.airborne)
		crouch_ticks+=int(rider.crouching)
		floor_ticks+=int(rider.is_on_floor())
		bailing=bailing or rider.bail_active
		trace.append({"tick":tick,"gap":gap,"offset":rider._obstacle_visual_offset,
			"at":rider.global_position,"air":rider.airborne,"crouch":rider.crouching,"floor":rider.is_on_floor()})
	Wall._release()
	check.call(crouch_ticks>=8 and air_ticks>=20 and floor_ticks>=20 and not bailing and rider.is_on_floor(),
		"wall transition: distinct mapped hold/release edges earn actual crouch, flight and returns to native flat support without bail")
	check.call(old_minimum< -0.10 and minimum>=0.0079 and maximum_offset<=0.18,
		"wall transition: board and shoe vertices keep eight-millimetre shutter clearance through Ollie and landing within the existing eighteen-centimetre fit ceiling")
	check.call(parity and local_pose,
		"wall transition: physical motion and local rider/deck pose remain identical to the unfitted input twin during flight and landing")
	print("WALL_TRANSITION_OLLIE ",{"before_gap":before_gap,"before_offset":before_offset,
		"minimum":minimum,"old_minimum":old_minimum,"maximum_offset":maximum_offset,
		"air_ticks":air_ticks,"crouch_ticks":crouch_ticks,"floor_ticks":floor_ticks,"physics_equal":parity,
		"local_pose_equal":local_pose,"trace":trace})
	fixture.viewport.queue_free()
	await tree.process_frame
	Wall._release()
	await _quick_tap(tree,check)
	await _finite_release(tree,check)
	await _obstruction_refusal(tree,check)


static func _fitted_air(tree: SceneTree) -> Dictionary:
	Wall._release()
	var fixture: Dictionary = await Wall._fixture(tree,-8.0)
	var rider: CharacterBody3D = fixture.rider
	Input.action_press("push",0.55)
	var reached := false
	for tick: int in 180:
		await Wall._frames(tree,1)
		if Wall._wall_contact(rider,fixture.wall):
			reached=true
			break
	Wall._release()
	Input.action_press("brake")
	await Wall._frames(tree,20)
	Wall._release()
	await Wall._frames(tree,2)
	Input.action_press("ollie")
	await Wall._frames(tree,12)
	Input.action_release("ollie")
	await Wall._frames(tree,5)
	fixture["reached"]=reached
	return fixture


static func _finite_release(tree: SceneTree,check: Callable) -> void:
	var fixture: Dictionary = await _fitted_air(tree)
	var rider: CharacterBody3D = fixture.rider
	var control: CharacterBody3D = fixture.control
	var initial: float = rider._obstacle_visual_offset.length()
	check.call(fixture.reached and rider.airborne and initial>0.10,
		"wall transition: actual held/released Ollie retains a ground-proven offset against the finite shutter during flight")
	# Remove only this fixture's actual finite wall. No remembered plane may
	# prevent the connected visual returning to neutral in ordinary clear air.
	fixture.wall.position.x=8.0
	var previous := initial
	var monotone := true
	var parity := true
	for tick: int in 18:
		await Wall._frames(tree,1)
		var current: float = rider._obstacle_visual_offset.length()
		monotone=monotone and current<=previous+0.000001
		previous=current
		parity=parity and Wall._physics(rider)==Wall._physics(control)
	check.call(monotone and previous<0.0003 and parity and not rider.bail_active,
		"wall transition: removing the finite native wall releases the airborne offset with bounded decay and identical physical motion")
	print("WALL_TRANSITION_FINITE_RELEASE ",{"initial":initial,"remaining":previous,"monotone":monotone,"physics_equal":parity,"air":rider.airborne})
	fixture.viewport.queue_free()
	await tree.process_frame
	Wall._release()


static func _obstruction_refusal(tree: SceneTree,check: Callable) -> void:
	var fixture: Dictionary = await _fitted_air(tree)
	var rider: CharacterBody3D = fixture.rider
	var control: CharacterBody3D = fixture.control
	var prior: Vector3 = rider._obstacle_visual_offset
	check.call(fixture.reached and rider.airborne and prior.length()>0.10,
		"wall transition: secondary-obstruction control starts from actual supported-wall Ollie flight")
	# A declared negative geometry fixture pauses its already-earned airborne
	# pose and obstructs both allowed candidates outside the physical capsule.
	# Refusal is not a claim that an impossible visual fit clears both walls.
	for body: CharacterBody3D in [rider,control]: body.set_physics_process(false)
	rider._visual.transform=control._visual.transform
	var base: Transform3D = rider._visual.transform
	var block := StaticBody3D.new()
	fixture.root.add_child(block)
	var shape := BoxShape3D.new()
	shape.size=Vector3(0.5,0.12,0.07)
	var collision := CollisionShape3D.new()
	collision.shape=shape
	block.add_child(collision)
	block.global_position=rider._board_visual.to_global(Vector3(0,0,0.39))+prior
	await Wall._frames(tree,2)
	var box_size: Vector3 = rider._grind_board_box.size
	var query_margin: float = rider._grind_board_query.margin
	var query_shape: Shape3D = rider._grind_board_query.shape
	rider._place_obstacle_wheels(1.0/60.0)
	check.call(rider._obstacle_visual_offset==Vector3.ZERO and rider._visual.transform==base,
		"wall transition: a real secondary block refuses both unsafe airborne visual candidates without moving the actor")
	check.call(rider._grind_board_box.size==box_size and rider._grind_board_query.margin==query_margin
		and rider._grind_board_query.shape==query_shape,
		"wall transition: airborne refusal restores the shared native board-query shape, bounds and margin")
	print("WALL_TRANSITION_REFUSAL ",{"prior":prior,"remaining":rider._obstacle_visual_offset,"block":block.global_position,"actor":rider.global_position})
	fixture.viewport.queue_free()
	await tree.process_frame
	Wall._release()


static func _shared_hull(rider: CharacterBody3D,check: Callable) -> void:
	var geometry: Dictionary = rider._visual_rig.board_contact_geometry()
	var hull: ConvexPolygonShape3D = geometry.get("convex_shape") as ConvexPolygonShape3D
	var valid := hull!=null and hull.margin==0.0
	check.call(valid and hull.get_debug_mesh().get_faces()==geometry.support_points,
		"wall transition: the retained native hull has zero added margin and exactly the existing actual-model support faces")
	if hull==null:
		check.call(false,"wall transition: retained hull is required for the margin negative control")
		return
	# Change only this disposable copy. The production shared hull and actual
	# support-face bytes must remain immutable for every other contact solver.
	var old_margin_control := hull.duplicate(true) as ConvexPolygonShape3D
	old_margin_control.margin=0.04
	check.call(old_margin_control.get_debug_mesh().get_faces()==geometry.support_points and hull.margin==0.0,
		"wall transition: original temporary-hull margin does not change published support geometry and the shared native hull stays untouched")


static func _quick_tap(tree: SceneTree,check: Callable) -> void:
	Wall._release()
	var fixture: Dictionary = await Wall._fixture(tree,-8.0)
	var rider: CharacterBody3D = fixture.rider
	var control: CharacterBody3D = fixture.control
	var reached := false
	Input.action_press("push",0.55)
	for tick: int in 180:
		await Wall._frames(tree,1)
		if Wall._wall_contact(rider,fixture.wall):
			reached=true
			break
	Wall._release()
	Input.action_press("brake")
	await Wall._frames(tree,20)
	Wall._release()
	await Wall._frames(tree,2)
	var initial: float = rider._obstacle_visual_offset.length()
	# A deliberately genuine A press AND release before the next physics tick
	# is the shortest native input tap; no synthetic airborne flag is assigned.
	for pressed: bool in [true,false]:
		var event := InputEventJoypadButton.new()
		event.device=0
		event.button_index=JOY_BUTTON_A
		event.pressed=pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	var minimum := INF
	var maximum_offset := initial
	var air_ticks := 0
	var parity := true
	for tick: int in 50:
		await Wall._frames(tree,1)
		minimum=minf(minimum,Wall._plane_gap(rider))
		maximum_offset=maxf(maximum_offset,rider._obstacle_visual_offset.length())
		air_ticks+=int(rider.airborne)
		parity=parity and Wall._physics(rider)==Wall._physics(control)
	check.call(reached and initial>0.10 and air_ticks>=20 and rider.is_on_floor() and not rider.bail_active,
		"wall transition: same-tick actual A press/release earns plain Ollie flight and returns without a crouch prerequisite")
	check.call(minimum>=0.0079 and maximum_offset<=0.18 and parity,
		"wall transition: quick-tap Ollie retains finite deck/shoe clearance within the existing bound and unchanged native-twin motion")
	print("WALL_TRANSITION_QUICK_TAP ",{"initial":initial,"minimum":minimum,"maximum_offset":maximum_offset,"air_ticks":air_ticks,"physics_equal":parity})
	fixture.viewport.queue_free()
	await tree.process_frame
	Wall._release()
