extends RefCounted
## The trailing foot keeps its stroke at a native stop and turns continuously.
const Visual=preload("res://game/player/skater_visual.gd")
const Manual=preload("res://tests/skater_wall_manual_tests.gd")
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
const Grade=preload("res://tests/pt24_manual_grade_tests.gd")
const Authentic=preload("res://tests/authentic_pose_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Score=preload("res://game/scoring/score_session.gd")

class LegacyDirection extends Visual:
	func _locomotion_direction(_delta: float,requested: float) -> float:
		return -1.0 if requested<0.0 else 1.0

static func run(tree: SceneTree,check: Callable) -> void:
	await _native_stop(tree,check)
	await _sample_rates(tree,check)

static func _native_stop(tree: SceneTree,check: Callable) -> void:
	Wall.Setup.register_actions();Wall._release()
	var f: Dictionary=await _stop_fixture(tree)
	var r: CharacterBody3D=f.rider;var c: CharacterBody3D=f.control
	var score:=Score.new();var events: Array[Dictionary]=[];var banks: Array[int]=[]
	r.trick_performed.connect(func(label: String,points: int):
		events.append({"id":r.last_trick_id,"points":points});score.add_trick(label,points,r.last_trick_id))
	r.combo_link_started.connect(score.continue_combo);r.combo_link_ended.connect(score.begin_landing)
	var data:=Body._prepare(r._visual_rig)
	var requested:=false;var impact:=-1;var physical:=true;var attached:=true;var loaded:=true
	var previous: Array[Vector3]=[];var maximum:=0.0;var stop_step:=0.0;var floor_min:=INF
	var ray:=PhysicsRayQueryParameters3D.new();ray.collision_mask=1|8;ray.exclude=[r.get_rid(),c.get_rid()]
	var trace: Array[Dictionary]=[]
	var backward_brake:=false;var stopped_brake_fade:=false
	Input.action_press("push",0.55)
	for tick: int in 110:
		if not requested and absf(r.speed)>=2.5 and r.global_position.z< -1.0:requested=true;Input.action_press("manual")
		await Wall._frames(tree,1)
		if impact<0 and Wall._wall_contact(r,f.wall):impact=tick;Input.action_release("push");Input.action_press("brake")
		var bank:=score.tick(1.0/60.0)
		if bank>0:banks.append(bank)
		physical=physical and Grade._physics(r)==Grade._physics(c)
		var rig: RefCounted=r._visual_rig
		backward_brake=backward_brake or (r.speed< -0.2 and rig._brake_blend>0.0 and Input.get_action_strength("brake")>0.99)
		stopped_brake_fade=stopped_brake_fade or (backward_brake and r.speed==0.0 and rig._brake_blend>0.0 and rig._last_travel_direction<0.0)
		var points:=_sole_points(rig)
		var step:=0.0
		if previous.size()==points.size():step=Authentic._marker_delta(previous,points)
		maximum=maxf(maximum,step)
		if tick==83:stop_step=step
		previous=points
		for point: Vector3 in points:floor_min=minf(floor_min,point.y)
		if r._obstacle_manual_continuation:loaded=loaded and Manual._loaded(r,ray).valid
		var sample:=Body._sample(r,data)
		attached=attached and sample.finite and sample.seam<0.08 and sample.joint_gap<0.06
		if tick>=80 and tick<=84:trace.append({"tick":tick,"speed":r.speed,"direction":rig._travel_direction,
			"last_direction":rig._last_travel_direction,"brake":rig._brake_blend,"sole_step":step,"input_brake":Input.get_action_strength("brake"),"input_push":Input.get_action_strength("push"),"input_manual":Input.get_action_strength("manual"),"controls":r._controls_enabled,"manual":r.manual_active,"velocity":r.velocity,"contacts":r.get_slide_collision_count()})
	Wall._release()
	check.call(requested and impact==79 and backward_brake and stopped_brake_fade and events==[{"id":"nose_manual","points":100}] and banks==[100] and score.total_score==100,
		"gait direction: actual Push/Manual/impact/Brake preserves the real Nose Manual and once-only100-point bank")
	check.call(physical and r.is_on_floor() and not r.bailing and loaded,
		"gait direction: native movement matches the unfitted twin and both loaded tyres retain their original support")
	check.call(maximum<0.22 and stop_step<0.10 and floor_min>=-0.001,
		"gait direction: actual complete shoe outline stays continuous through the former253mm zero-speed flip without entering the native floor")
	check.call(attached and r._visual_rig._last_travel_direction<0.0,
		"gait direction: connected real clothing and the final backward stroke survive a stopped fading Brake")
	print("GAIT_NATIVE_STOP ",{"maximum_sole_step":maximum,"stop83_sole_step":stop_step,"minimum_sole_y":floor_min,"banks":banks,"trace":trace})
	f.viewport.queue_free();await tree.process_frame

static func _sample_rates(tree: SceneTree,check: Callable) -> void:
	var f: Dictionary=await Authentic._fixture(tree,0.0,0.0,Vector3.UP,true)
	var rig: RefCounted=f.rig
	var legacy:=_legacy(f)
	var body_before: Transform3D=f.body.global_transform
	var endpoints: Array[Transform3D]=[]
	for rate: int in [30,60,120]:
		var delta:=1.0/float(rate)
		var state:=Authentic._neutral();state.merge({"brake":true,"speed":6.0,"travel_sign":1.0},true)
		var steady:=true
		for sign: float in [1.0,-1.0]:
			rig.reset();legacy.reset();state.travel_sign=sign
			for sample: int in rate*2:rig.animate(delta,state);legacy.animate(delta,state)
			steady=steady and rig._legs[1].foot.global_transform.is_equal_approx(legacy._legs[1].foot.global_transform)
		check.call(steady,"gait direction: original steady forward/backward shoe positions and yaw remain unchanged at%dHz"%rate)
		var previous:=_sole_points(rig)
		var old_rotation: Quaternion=rig._legs[1].foot.global_basis.get_rotation_quaternion()
		var maximum_speed:=0.0;var maximum_yaw_speed:=0.0;var floor_min:=INF
		state.speed=0.0;state.brake=false;state.travel_sign=0.0
		for sample: int in rate:
			rig.animate(delta,state)
			var points:=_sole_points(rig)
			maximum_speed=maxf(maximum_speed,Authentic._marker_delta(previous,points)/delta);previous=points
			for point: Vector3 in points:floor_min=minf(floor_min,point.y-f.root.global_position.y)
		check.call(maximum_speed<0.22*60.0 and rig._last_travel_direction==-1.0,
			"gait direction: zero-speed stroke retains its direction with bounded actual shoe speed at%dHz"%rate)
		# A genuine opposite signed traversal must rotate the whole shoe, not
		# switch only its ankle marker or choose a different shortest arc midway.
		state.speed=6.0;state.brake=true;state.travel_sign=-1.0
		for sample: int in rate*2:rig.animate(delta,state)
		previous=_sole_points(rig);old_rotation=rig._legs[1].foot.global_basis.get_rotation_quaternion()
		state.travel_sign=1.0
		for sample: int in rate:
			rig.animate(delta,state)
			var points:=_sole_points(rig)
			maximum_speed=maxf(maximum_speed,Authentic._marker_delta(previous,points)/delta);previous=points
			var rotation: Quaternion=rig._legs[1].foot.global_basis.get_rotation_quaternion()
			maximum_yaw_speed=maxf(maximum_yaw_speed,old_rotation.angle_to(rotation)/delta);old_rotation=rotation
			for point: Vector3 in points:floor_min=minf(floor_min,point.y-f.root.global_position.y)
		check.call(maximum_speed<0.22*60.0 and maximum_yaw_speed<PI*12.0+0.001 and floor_min>=-0.001,
			"gait direction: genuine reverse-to-forward transition turns actual sole corners and yaw continuously on native support at%dHz"%rate)
		endpoints.append(rig._legs[1].foot.global_transform)
		check.call(Authentic._finite(rig) and Authentic._max_stretch(rig)<=1.12 and f.body.global_transform==body_before,
			"gait direction: direction changes preserve the native body and finite fixed-length rig at%dHz"%rate)
		print("GAIT_POSE_RATE ",{"rate":rate,"maximum_sole_speed":maximum_speed,"maximum_yaw_speed":maximum_yaw_speed,"minimum_sole_floor_gap":floor_min})
	check.call(endpoints[0].is_equal_approx(endpoints[1]) and endpoints[1].is_equal_approx(endpoints[2]),
		"gait direction: equal-duration30/60/120Hz pose samples converge to identical original forward shoe output")
	rig.reset()
	check.call(rig._last_travel_direction==1.0 and rig._travel_direction==1.0 and Authentic._feet_error(f)<0.001,
		"gait direction: reset clears both direction scalars and immediately restores original planted shoes")
	await Authentic._dispose(tree,f.root)

static func _legacy(f: Dictionary) -> RefCounted:
	var visual:=Node3D.new();f.body.add_child(visual)
	var board:=Node3D.new();board.position.y=0.12;visual.add_child(board)
	var rider:=Node3D.new();rider.rotation.y=-PI/2.0+0.28;visual.add_child(rider)
	var rig:=LegacyDirection.new();rig.build(board,rider,StandardMaterial3D.new())
	return rig

static func _sole_points(rig: RefCounted) -> Array[Vector3]:
	var foot: Node3D=rig._legs[1].foot
	var result: Array[Vector3]=[]
	for vertex: Vector3 in rig._sole_points:result.append(foot.to_global(vertex))
	return result

static func _stop_fixture(tree: SceneTree) -> Dictionary:
 var viewport:=SubViewport.new();viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
 var root:=Node3D.new();viewport.add_child(root)
 var floor:=StaticBody3D.new();root.add_child(floor)
 var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
 var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-0.1;floor.add_child(collision)
 var gate:=preload("res://game/features/service_gate.gd").new();root.add_child(gate)
 gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
 var rider:=Wall.Skater.new();var control:=Wall.UnfittedSkater.new()
 for body: CharacterBody3D in [rider,control]:
  body.spawn_position=Vector3(0,0.04,-3.02);root.add_child(body);body.rotation.y=PI
 await Wall._frames(tree,4)
 return {"viewport":viewport,"rider":rider,"control":control,"wall":gate._panel}
