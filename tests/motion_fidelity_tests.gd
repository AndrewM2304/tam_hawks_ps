extends RefCounted
## Actual push input on native flat support. Plant-slip is measured in world
## metres from the real visible sole; no per-tick heading or speed is injected.
const Skater = preload("res://game/player/skater.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const Board = preload("res://tests/board_geometry_tests_support.gd")
static var _observer:=Callable()
static var _game:Node
static var _phase:=""
static var _step:=0

static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	_release()
	for sign_value: float in [1.0,-1.0]:
		await _push_contact(tree,check,sign_value)
	for grade:float in [20.0,-20.0]:
		await _push_contact(tree,check,1.0,grade)
	await _raised_edge_support(tree,check)
	_release()

static func _raised_edge_support(tree:SceneTree,check:Callable)->void:
	# Reproduce the real quay-seat failure with an independent finite shape:
	# a capsule remains natively supported a few millimetres beyond the seat's
	# centre ray. The four rendered wheels must not follow that ray49cm down.
	var fixture:=Node3D.new()
	fixture.name="NativeRaisedEdgeSupportFixture"
	tree.root.add_child(fixture)
	var floor_body:=StaticBody3D.new()
	floor_body.position.y=-0.2
	var floor_shape:=BoxShape3D.new()
	floor_shape.size=Vector3(20,0.4,20)
	var floor_collision:=CollisionShape3D.new()
	floor_collision.shape=floor_shape
	floor_body.add_child(floor_collision)
	fixture.add_child(floor_body)
	var seat:=StaticBody3D.new()
	seat.position.y=0.44
	seat.rotation.y=deg_to_rad(15)
	var seat_shape:=BoxShape3D.new()
	seat_shape.size=Vector3(5.6,0.10,0.55)
	var seat_collision:=CollisionShape3D.new()
	seat_collision.shape=seat_shape
	seat.add_child(seat_collision)
	fixture.add_child(seat)
	for lateral:float in [0.0,-0.280]:
		var rider=Skater.new()
		rider.spawn_position=seat.to_global(Vector3(0.6,0.8,lateral))
		fixture.add_child(rider)
		rider.rotation.y=deg_to_rad(-75)
		await _frames(tree,70)
		var native:Dictionary=rider._native_floor_hit(Vector3.UP)
		check.call(rider.is_on_floor() and native.get("collider")==seat and typeof(native.get("shape"))==TYPE_INT
			and absf(Vector3(native.get("position",Vector3.ZERO)).y-0.49)<0.001,
			"native raised edge: %s retains the actual finite seat's current floor ownership"%lateral)
		var geometry:Dictionary=rider._visual_rig.board_contact_geometry()
		var query:=PhysicsShapeQueryParameters3D.new()
		query.collision_mask=1|8
		query.exclude=[rider.get_rid()]
		query.margin=0.0
		query.transform=rider._board_visual.global_transform
		query.shape=geometry.convex_shape
		var clear:bool=rider.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
		var lowest:=INF
		for vertex:Vector3 in geometry.support_points:
			lowest=minf(lowest,rider._board_visual.to_global(vertex).y)
		check.call(clear and lowest>=0.494 and lowest<0.520,
			"native raised edge: %s actual connected board and tyres clear the real bearing instead of sinking49cm"%lateral)
		print("NATIVE_RAISED_EDGE lateral=",lateral," body=",rider.global_position,
			" board=",rider._board_visual.global_position," actual_model_lowest_y=",lowest," clear=",clear)
		# reset_skater invalidates native support before the next move. Its
		# previous seat collision must not become a support at the new spawn.
		rider.spawn_position=Vector3(5,1,5)
		rider.reset_skater()
		check.call(not rider._native_floor_valid and rider._native_floor_hit(Vector3.UP).is_empty(),
			"native raised edge: %s restart cannot resurrect the previous seat's floor contact"%lateral)
		rider.queue_free()
		await tree.process_frame
	fixture.queue_free()
	await tree.process_frame

static func run_main(tree:SceneTree,game:Node,check:Callable,observer:Callable=Callable())->void:
	var original_spawn:Vector3=game.skater.spawn_position
	var original_free:bool=game.free_skate_mode
	_observer=observer
	_game=game
	_step=0
	for direction:float in [1.0,-1.0]:
		await _main_fixture(tree,game,direction)
		check.call(game.skater.is_on_floor(),"push Main: %s starts on the real default-spawn support"%direction)
		_phase="push_contact_regular" if direction>0.0 else "push_contact_fakie"
		await _measure_push(tree,game.skater,check,direction)
	await _main_fixture(tree,game)
	_phase="push_contact_from_rest"
	await _measure_push(tree,game.skater,check,1.0,false)
	await _main_brake_and_pop(tree,game,check)
	_phase=""
	_observer=Callable()
	_game=null
	_release()
	game.skater.spawn_position=original_spawn
	game.start_mode(original_free)

static func run_main_support(tree:SceneTree,game:Node,check:Callable)->void:
	var original_spawn:Vector3=game.skater.spawn_position
	var original_free:bool=game.free_skate_mode
	_release()
	# Exact ordinary-world witness from the rejected early second-seat exit.
	# One restart/heading and one moving-start seed; Manual and all subsequent
	# travel/contact are production input/physics, never pose or balance writes.
	game.skater.spawn_position=Vector3(64.58057,3.2,63.55468)
	game.start_mode(true)
	game.skater.rotation.y=deg_to_rad(-75)
	await _frames(tree,70)
	var rider:CharacterBody3D=game.skater
	var floor_hit:Dictionary=rider._native_floor_hit(Vector3.UP)
	var seat:=floor_hit.get("collider") as CollisionObject3D
	check.call(rider.is_on_floor() and is_instance_valid(seat) and typeof(floor_hit.get("shape"))==TYPE_INT
		and String(seat.get_meta("art_label",""))=="QuayBenchSeat"
		and absf(Vector3(floor_hit.get("position",Vector3.ZERO)).y-2.49)<0.001,
		"native Main raised edge: actual capsule seat contact survives a centre ray onto lower paving")
	rider.speed=6.0
	rider.velocity=-rider.global_basis.z*6.0
	Input.action_press("manual")
	var samples:=0
	var clear:=true
	var loaded_gap:=INF
	var worst_loaded_gap:=-INF
	for tick in 12:
		await _frames(tree,1)
		if not rider.manual_active:continue
		samples+=1
		clear=clear and rider._manual_model_frame_clear(rider._board_visual.global_transform)
		var frame_gap:=INF
		for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
			if Vector3(wheel.center).z*rider._board_visual.rotation.x<=0:continue
			var at:Vector3=rider._board_visual.to_global(wheel.center)
			var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.35,at-Vector3.UP*0.5,1|8,[rider.get_rid()])
			var hit:=rider.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.get("collider")!=seat:continue
			var lowest:=INF
			for vertex:Vector3 in wheel.points:
				lowest=minf(lowest,(rider._board_visual.to_global(vertex)-Vector3(hit.position)).dot(hit.normal))
			frame_gap=minf(frame_gap,lowest)
		loaded_gap=minf(loaded_gap,frame_gap)
		worst_loaded_gap=maxf(worst_loaded_gap,frame_gap)
	check.call(samples>=8 and rider.is_on_floor() and clear and loaded_gap>=0.004 and worst_loaded_gap<0.03,
		"native Main raised edge: mapped moving Manual keeps its actual connected model clear and a real loaded tyre on the seat")
	print("NATIVE_MAIN_RAISED_EDGE samples=",samples," native_floor=",rider._native_floor_hit(Vector3.UP),
		" actual_model_clear=",clear," loaded_tyre_gap_min_m=",loaded_gap," loaded_tyre_gap_max_m=",worst_loaded_gap," body=",rider.global_position,
		" board=",rider._board_visual.global_position)
	_release()
	await _main_graded_wall(tree,game,check)
	game.skater.spawn_position=original_spawn
	game.start_mode(original_free)

static func _main_graded_wall(tree:SceneTree,game:Node,check:Callable)->void:
	# Actual fast approach to the retained finite quay bank/wall. One restart
	# and heading; every acceleration, wall response and rollback is native.
	game.skater.spawn_position=Vector3(66,2.08,73.5)
	game.start_mode(true)
	game.skater.rotation.y=-PI*.5
	game.skater.reset_physics_interpolation()
	await _frames(tree,45)
	var rider:CharacterBody3D=game.skater
	var released:=false
	var wall_seen:=false
	var reverse:=false
	var samples:=0
	var clear:=true
	var min_gap:=INF
	var max_gap:=-INF
	var max_offset:=0.0
	var rejection_checked:=false
	var refuses_float:=false
	var refuses_intrusion:=false
	var refuses_stale_floor:=false
	var stale_floor_checked:=false
	var max_offset_step:=0.0
	var previous_offset:=Vector3.ZERO
	for tick in 400:
		if not released:
			Input.action_press("push")
			Input.action_release("brake")
			if absf(rider.speed)>12.0:Input.action_press("brake")
			if rider.global_position.x>=80.5:
				_release()
				released=true
		await _frames(tree,1)
		for slide:int in rider.get_slide_collision_count():
			var contact:KinematicCollision3D=rider.get_slide_collision(slide)
			for index:int in contact.get_collision_count():
				var body:Object=contact.get_collider(index)
				if is_instance_valid(body) and body.has_meta("bank_terminal_return") and contact.get_normal(index).x<-.98:wall_seen=true
		if not wall_seen:continue
		samples+=1
		var model_clear:bool=rider._manual_model_frame_clear(rider._board_visual.global_transform)
		var gaps:=_native_wheel_gaps(rider)
		var frame_clear:bool=rider.is_on_floor() and not rider.airborne and model_clear and gaps.size()==4
		clear=clear and frame_clear
		if not frame_clear:
			var hits:Array=[]
			var part_index:=0
			for part:Dictionary in rider._grind_clearance._parts:
				var query:=PhysicsShapeQueryParameters3D.new()
				query.shape=part.shape
				query.transform=rider._board_visual.global_transform
				query.collision_mask=1|2|8
				query.exclude=[rider.get_rid()]
				query.margin=0.0
				for hit:Dictionary in rider.get_world_3d().direct_space_state.intersect_shape(query,16):
					hits.append({"part":part_index,"label":hit.collider.get_meta("art_label",hit.collider.name),"rid":hit.rid.get_id(),"shape":hit.shape})
				part_index+=1
			print("NATIVE_GRADED_WALL_REJECT tick=",tick," physics=",Engine.get_physics_frames()," position=",rider.global_position,
				" speed=",rider.speed," velocity=",rider.velocity," floor=",rider.is_on_floor()," native_valid=",rider._native_floor_valid,
				" wall=",rider.is_on_wall()," air=",rider.airborne," model_clear=",model_clear," wheel_gaps=",gaps,
				" offset=",rider._obstacle_visual_offset," board=",rider._board_visual.global_transform," hits=",hits)
		for gap:float in gaps:
			min_gap=minf(min_gap,gap)
			max_gap=maxf(max_gap,gap)
		max_offset=maxf(max_offset,rider._obstacle_visual_offset.length())
		max_offset_step=maxf(max_offset_step,rider._obstacle_visual_offset.distance_to(previous_offset))
		previous_offset=rider._obstacle_visual_offset
		if not stale_floor_checked and not rider.is_on_wall() and rider._obstacle_visual_offset!=Vector3.ZERO:
			# Inject a stale identity from a DIFFERENT real native floor into an
			# otherwise unchanged rebound frame. It must neither carry the old
			# fit nor move the already displayed connected model a second time.
			var at:Vector3=game.world.get_spawn_position()
			var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*2,at-Vector3.UP*3,1|8,[rider.get_rid()])
			var foreign:Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(ray)
			var support:Dictionary=rider._native_floor_hit(rider._native_floor_normal())
			if not foreign.is_empty() and (foreign.rid!=support.rid or int(foreign.shape)!=int(support.shape)):
				var saved_offset:Vector3=rider._obstacle_visual_offset
				var saved_floor:RID=rider._graded_obstacle_floor_rid
				var saved_shape:int=rider._graded_obstacle_floor_shape
				var saved_visual:Transform3D=rider._visual.global_transform
				rider._graded_obstacle_floor_rid=foreign.rid
				rider._graded_obstacle_floor_shape=int(foreign.shape)
				rider._place_graded_obstacle_wheels(1.0/60.0)
				refuses_stale_floor=rider._obstacle_visual_offset==Vector3.ZERO and rider._visual.global_transform==saved_visual
				stale_floor_checked=true
				rider._obstacle_visual_offset=saved_offset
				rider._graded_obstacle_floor_rid=saved_floor
				rider._graded_obstacle_floor_shape=saved_shape
		if not rejection_checked:
			var support:Dictionary=rider._native_floor_hit(rider._native_floor_normal())
			var geometry:Dictionary=rider._visual_rig.board_contact_geometry()
			var planes:Array[Vector4]=[]
			refuses_float=not rider._graded_obstacle_offset_supported(geometry,Vector3.UP*.05,planes,support)
			refuses_intrusion=not rider._graded_obstacle_offset_supported(geometry,Vector3.DOWN*.05,planes,support)
			rejection_checked=true
		if rider.speed<-.5:reverse=true
		if reverse and rider.global_position.x<83.8:break
	_release()
	check.call(released and wall_seen and reverse and samples>=10 and clear and max_offset>0.01 and max_offset<=.18 and max_offset_step<=.18,
		"native graded wall: real fast approach and rollback keep the connected model clear without moving the physical capsule")
	check.call(min_gap>=.004 and max_gap<.03,
		"native graded wall: every sampled actual tyre retains finite bank support during the tangential wall correction")
	check.call(rejection_checked and refuses_float and refuses_intrusion,
		"native graded wall: finite support refuses an offset that floats tyres or cuts them into the actual grade")
	print("NATIVE_GRADED_WALL samples=",samples," clear=",clear," native_wheel_gap_min_m=",min_gap,
		" native_wheel_gap_max_m=",max_gap," max_connected_offset_m=",max_offset," max_connected_offset_step_m=",max_offset_step," reverse=",reverse,
		" reject_float=",refuses_float," reject_intrusion=",refuses_intrusion," final_body=",rider.global_position)
	rider.reset_skater()
	check.call(stale_floor_checked and refuses_stale_floor and rider._obstacle_visual_offset==Vector3.ZERO
		and not rider._graded_obstacle_floor_rid.is_valid() and rider._graded_obstacle_floor_shape==-1,
		"native graded wall: a different real floor cannot donate a rebound fit and restart clears its exact support ownership")

static func _main_fixture(tree:SceneTree,game:Node,direction:float=1.0)->void:
	_release()
	_phase=""
	game.skater.spawn_position=game.world.get_spawn_position()
	game.start_mode(true)
	# Both travel senses use the same clear northbound spine. This is one
	# disclosed initial heading; no subsequent heading/velocity is corrected.
	if direction<0.0:game.skater.rotation.y=PI
	game.skater.reset_physics_interpolation()
	await _frames(tree,45)

static func _main_brake_and_pop(tree:SceneTree,game:Node,check:Callable)->void:
	await _main_fixture(tree,game)
	_phase="push_contact_brake"
	Input.action_press("push")
	await _frames(tree,75)
	Input.action_release("push")
	Input.action_press("brake")
	var rig:RefCounted=game.skater._visual_rig
	var foot:Node3D=rig._legs[1].foot
	var drag_samples:=0
	var drag_gap:=0.0
	for tick in 45:
		await _frames(tree,1)
		if rig._brake_blend>0.98 and absf(game.skater.speed)>0.5:
			drag_samples+=1
			drag_gap=maxf(drag_gap,absf(foot.to_global(Footwear.SOLE_CONTACT).y))
	check.call(game.skater.is_on_floor() and absf(game.skater.speed)<0.05
		and drag_samples>=3 and drag_gap<0.004,
		"push Main: real braking stops the board with a supported dragging sole")
	print("PUSH_BRAKE samples=",drag_samples," loaded_sole_gap_m=",drag_gap," final_speed=",game.skater.speed)
	_release()
	_phase="push_contact_brake_return"
	await _frames(tree,36)
	check.call(Board.grip_distance(rig,foot.to_global(Footwear.SOLE_CONTACT))<0.005,
		"push Main: actual brake release returns the rear sole to griptape")
	await _main_pop(tree,game,check,18)
	await _main_pop(tree,game,check,6)

static func _main_pop(tree:SceneTree,game:Node,check:Callable,lead_ticks:int)->void:
	await _main_fixture(tree,game)
	_phase="push_contact_pop_early" if lead_ticks<10 else "push_contact_pop_catch"
	var rig:RefCounted=game.skater._visual_rig
	var landed_count:=[0]
	var bails:=[0]
	var on_landed:=func(_clean:bool):landed_count[0]+=1
	var on_bail:=func():bails[0]+=1
	game.skater.landed.connect(on_landed)
	game.skater.bailed.connect(on_bail)
	Input.action_press("push")
	await _frames(tree,lead_ticks)
	Input.action_press("ollie")
	await _frames(tree,2)
	Input.action_release("push")
	Input.action_release("ollie")
	var saw_air:=false
	var settled_frames:=0
	for tick in 90:
		await _frames(tree,1)
		saw_air=saw_air or game.skater.airborne
		if saw_air and not game.skater.airborne:settled_frames+=1
		if settled_frames>=30:break
	check.call(saw_air and landed_count[0]==1 and bails[0]==0 and game.skater.is_on_floor(),
		"push Main: actual crouch/pop at%s ticks interrupts a stroke and returns through one clean native landing"%lead_ticks)
	check.call(Board.grip_distance(rig,rig._legs[0].foot.to_global(Footwear.SOLE_CONTACT))<0.005
		and Board.grip_distance(rig,rig._legs[1].foot.to_global(Footwear.SOLE_CONTACT))<0.005,
		"push Main: after the%s-tick interrupted stroke and landing both actual soles recover detailed deck contact"%lead_ticks)
	game.skater.landed.disconnect(on_landed)
	game.skater.bailed.disconnect(on_bail)

static func _push_contact(tree: SceneTree,check: Callable,direction:float,grade:float=0.0) -> void:
	var fixture:=Node3D.new()
	fixture.name="PushSoleSlipFixture"
	# Keep long descending coast/release motion above the world's deliberate
	# recovery threshold; a below-world fixture would test the wrong contract.
	if not is_zero_approx(grade):fixture.position.y=12.0
	tree.root.add_child(fixture)
	var floor_body:=StaticBody3D.new()
	floor_body.rotation.x=deg_to_rad(grade)
	floor_body.position=-floor_body.basis.y*0.2
	var shape:=BoxShape3D.new()
	shape.size=Vector3(60,0.4,100)
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	floor_body.add_child(collision)
	fixture.add_child(floor_body)
	var rider=Skater.new()
	rider.spawn_position=fixture.to_global(floor_body.basis.y*0.8)
	fixture.add_child(rider)
	if not is_zero_approx(grade):Input.action_press("brake")
	await _frames(tree,45)
	check.call(rider.is_on_floor(),"push contact: independent %s grade%s fixture settles on real support"%[direction,grade])
	# Inclines use an actual brake hold against gravity, then push from rest;
	# only the declared flat moving-start fixtures seed6m/s.
	if not is_zero_approx(grade):Input.action_release("brake")
	await _measure_push(tree,rider,check,direction,is_zero_approx(grade),"grade%s"%grade)
	fixture.queue_free()
	await tree.process_frame
	await _frames(tree,1)

static func _measure_push(tree:SceneTree,rider:CharacterBody3D,check:Callable,direction:float,moving_start:bool=true,fixture_label:String="Main flat")->void:
	var case_name:="%s %s"%[direction,fixture_label]
	# Declare one moving-start fixture; all later acceleration and feet follow input.
	if moving_start:
		rider.speed=direction*6.0
		rider.velocity=-rider.global_basis.z*direction*6.0
	var initial_speed:float=rider.speed
	var rig:RefCounted=rider._visual_rig
	var foot:Node3D=rig._legs[1].foot
	var previous:Vector3=foot.to_global(Footwear.SOLE_CONTACT)
	var previous_phase:float=rig._push_phase
	var previous_loaded:=false
	var contacts:=0
	var peak_slip:=0.0
	var total_slip:=0.0
	var peak_lift:=0.0
	var front_error:=0.0
	var peak_relative_step:=0.0
	var facing_samples:=0
	var torso_alignment:=1.0
	var hips_alignment:=1.0
	var front_toe_alignment:=1.0
	var head_alignment:=1.0
	var wheel_min:=INF
	var wheel_max:=-INF
	var wheel_samples:=0
	var previous_body:Vector3=rider.global_position
	var previous_head:Vector3=rig._head.global_position
	var trace:Array[Dictionary]=[]
	Input.action_press("push")
	for tick in 72:
		await _frames(tree,1)
		var sole:Vector3=foot.to_global(Footwear.SOLE_CONTACT)
		var support:=_sole_support(rider,sole)
		var support_gap:=INF if support.is_empty() else (sole-Vector3(support.position)).dot(support.normal)
		var loaded:bool=rider.is_on_floor() and rig._push_blend>0.98 and rig._push_phase<0.60 \
			and support_gap>=-0.002 and support_gap<0.004 and absf(rider.speed)<14.5
		var same_stroke:bool=rig._push_phase>=previous_phase
		if loaded and previous_loaded and same_stroke:
			var slip:=sole.distance_to(previous)
			peak_slip=maxf(peak_slip,slip)
			total_slip+=slip
			contacts+=1
			trace.append({"tick":tick,"speed":rider.speed,"phase":rig._push_phase,"slip_m":slip})
		if rig._push_blend>0.90 and rig._push_phase>0.65:
			if is_finite(support_gap):peak_lift=maxf(peak_lift,support_gap)
		if tick%6==0:
			var front:Node3D=rig._legs[0].foot
			front_error=maxf(front_error,Board.grip_distance(rig,front.to_global(Footwear.SOLE_CONTACT)))
			var gaps:=_native_wheel_gaps(rider)
			for gap:float in gaps:
				wheel_min=minf(wheel_min,gap)
				wheel_max=maxf(wheel_max,gap)
				wheel_samples+=1
		if rig._push_blend>0.98 and absf(rider.speed)<14.5:
			var forward:Vector3=(-rider.global_basis.z*direction).slide(Vector3.UP).normalized()
			var front:Node3D=rig._legs[0].foot
			var hips_basis:Basis=rig._garments.skeleton.global_basis \
				* rig._garments.skeleton.get_bone_global_pose(int(rig._garments._bones.hips)).basis
			torso_alignment=minf(torso_alignment,(-rig._upper.global_basis.z).slide(Vector3.UP).normalized().dot(forward))
			hips_alignment=minf(hips_alignment,(-hips_basis.z).slide(Vector3.UP).normalized().dot(forward))
			front_toe_alignment=minf(front_toe_alignment,(-front.global_basis.z).slide(Vector3.UP).normalized().dot(forward))
			head_alignment=minf(head_alignment,(-rig._head.global_basis.z).slide(Vector3.UP).normalized().dot(forward))
			facing_samples+=1
		var body_step:Vector3=rider.global_position-previous_body
		peak_relative_step=maxf(peak_relative_step,(rig._head.global_position-previous_head-body_step).length())
		previous_body=rider.global_position
		previous_head=rig._head.global_position
		previous=sole
		previous_phase=rig._push_phase
		previous_loaded=loaded
	_release()
	check.call(contacts>=4 and peak_slip<0.005,
		"push contact: %s planted sole moves less than5mm per tick against stationary pavement"%case_name)
	check.call(peak_lift>0.10 and front_error<0.005,
		"push contact: %s unloaded return lifts clearly while the supporting shoe retains real griptape contact"%case_name)
	check.call(peak_relative_step<0.22,
		"push contact: %s stroke/return keeps connected head motion within220mm relative to native travel"%case_name)
	check.call(facing_samples>=5 and hips_alignment>0.96 and torso_alignment>0.96 and front_toe_alignment>0.96,
		"push contact: %s loaded hips, torso and planted front shoe face actual travel rather than sideways"%case_name)
	check.call(wheel_samples>=48 and wheel_min>=-0.003 and wheel_max<0.030,
		"push contact: %s actual four-wheel GLB vertices retain native support within existing contact bounds"%case_name)
	await _frames(tree,45)
	var release_grip_error:=Board.grip_distance(rig,foot.to_global(Footwear.SOLE_CONTACT))
	check.call(release_grip_error<0.005,
		"push contact: %s release returns the actual rear sole to the detailed board"%case_name)
	print("PUSH_SOLE_SLIP ",JSON.stringify({"direction":direction,"fixture":fixture_label,"contacts":contacts,"peak_slip_m":peak_slip,
		"total_slip_m":total_slip,"return_lift_m":peak_lift,"front_grip_error_m":front_error,
		"head_relative_step_m":peak_relative_step,"release_grip_error_m":release_grip_error,
		"release_body":rider.global_position,"release_bail_active":rider.bail_active,"trace":trace}))
	print("PUSH_FACING ",JSON.stringify({"direction":direction,"moving_start":moving_start,"initial_speed":initial_speed,
		"fixture":fixture_label,
		"samples":facing_samples,"hips_alignment":hips_alignment,"torso_alignment":torso_alignment,"front_toe_alignment":front_toe_alignment,
		"head_alignment":head_alignment,"wheel_samples":wheel_samples,"wheel_min_m":wheel_min,"wheel_max_m":wheel_max}))

static func _sole_support(rider:CharacterBody3D,sole:Vector3)->Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(sole+Vector3.UP*0.4,sole-Vector3.UP*0.8,1|8,[rider.get_rid()])
	var hit:=rider.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or Vector3(hit.normal).y<0.65:return {}
	return hit

static func _native_wheel_gaps(rider:CharacterBody3D)->Array[float]:
	var gaps:Array[float]=[]
	for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		var lowest:=Vector3.INF
		for point:Vector3 in wheel.points:
			var world:Vector3=rider._board_visual.to_global(point)
			if world.y<lowest.y:lowest=world
		if not lowest.is_finite():continue
		var query:=PhysicsRayQueryParameters3D.create(lowest+Vector3.UP*0.25,lowest-Vector3.UP*0.40,1|8,[rider.get_rid()])
		var hit:=rider.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():gaps.append((lowest-Vector3(hit.position)).dot(Vector3(hit.normal)))
	return gaps

static func _frames(tree:SceneTree,count:int)->void:
	for tick in count:
		await tree.physics_frame
		await tree.process_frame
		if _observer.is_valid() and not _phase.is_empty():
			await _observer.call(_phase,_game,_step)
			_step+=1

static func _release()->void:
	for action in InputMap.get_actions():Input.action_release(action)
