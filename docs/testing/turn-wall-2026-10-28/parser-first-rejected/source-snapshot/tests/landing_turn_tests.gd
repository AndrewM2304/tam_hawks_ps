extends RefCounted
## Actual Ollie/left-right input/native landings, with shoulder/trick controls.
const Classic = preload("res://tests/classic_tricks_integration_tests.gd")

class FlightProbe extends Node:
	var rider: CharacterBody3D
	var launch := Vector3.ZERO
	var heading := 0.0
	var maximum_air_velocity_error := 0.0
	var maximum_air_heading_error := 0.0
	var armed := false
	func _ready() -> void: process_physics_priority = 100
	func _physics_process(_delta: float) -> void:
		if not armed or not rider.airborne or rider.bailing: return
		maximum_air_velocity_error = maxf(maximum_air_velocity_error,
			Vector2(rider.velocity.x-launch.x,rider.velocity.z-launch.z).length())
		maximum_air_heading_error = maxf(maximum_air_heading_error,absf(angle_difference(heading,rider.rotation.y)))

static func run(tree: SceneTree, check: Callable) -> void:
	Classic.Setup.register_actions()
	for side: float in [-1.0,1.0]:
		for degrees: float in [45.0,90.0,135.0,159.0,161.0,180.0]:
			await _turn(tree,check,side,degrees)
	await _mixed_spin(tree,check)
	await _late_flip(tree,check)
	await _restart(tree,check)
	await _blocked_rollout(tree,check)

static func _launch(tree: SceneTree, f: Dictionary) -> FlightProbe:
	Input.action_press("push")
	await Classic._frames(tree,30)
	Input.action_release("push")
	Input.action_press("ollie")
	await Classic._frames(tree,24)
	Input.action_release("ollie")
	await Classic._frames(tree,1)
	var probe := FlightProbe.new()
	probe.rider=f.rider;probe.launch=f.rider.velocity;probe.heading=f.rider.rotation.y;probe.armed=true
	f.root.add_child(probe)
	return probe

static func _turn(tree: SceneTree, check: Callable, side: float, degrees: float) -> void:
	var f: Dictionary = await Classic._fixture(tree)
	var e := {"bails":0,"lands":0,"entries":[],"points":0,"landing_velocity":Vector3.ZERO,"landing_speed":0.0}
	f.rider.bailed.connect(func():e.bails+=1)
	f.rider.trick_performed.connect(func(label:String,points:int):e.entries.append(label);e.points+=points)
	f.rider.landed.connect(func(clean:bool):
		if clean:e.lands+=1;e.landing_velocity=f.rider.velocity;e.landing_speed=f.rider.speed)
	var p := await _launch(tree,f)
	var action := "steer_right" if side>0.0 else "steer_left"
	Input.action_press(action,deg_to_rad(degrees)/(28.0*f.rider.SPIN_SPEED/60.0))
	await Classic._frames(tree,28)
	Input.action_release(action)
	var actual_turn: float=f.rider._air_steer_turn
	for frame: int in 70:
		await Classic._frames(tree,1)
		if e.bails>0 or not f.rider.airborne:break
	var landing_at: Vector3=f.rider.global_position
	await Classic._frames(tree,8)
	var expected_yaw := -side*deg_to_rad(degrees)
	var expected_direction := Vector3.FORWARD.rotated(Vector3.UP,expected_yaw)
	var actual_direction := Vector3(f.rider.velocity.x,0,f.rider.velocity.z).normalized()
	var label := "side=%s degrees=%s"%[side,degrees]
	check.call(e.bails==0 and e.lands==1 and f.rider.is_on_floor() and not f.rider.airborne,
		"steering landing: actual left/right Ollie lands once without a spin bail "+label)
	check.call(absf(angle_difference(expected_yaw,f.rider.rotation.y))<0.002
		and expected_direction.dot(actual_direction)>0.999 and f.rider.stance=="REGULAR"
		and (f.rider.global_position-landing_at).dot(expected_direction)>0.6,
		"steering landing: continuous chosen heading and forward rollout survive the score threshold "+label)
	check.call(p.maximum_air_velocity_error<0.001 and p.maximum_air_heading_error<0.001
		and absf(actual_turn-expected_yaw)<0.002 and float(e.landing_speed)>5.0
		and absf(Vector2(e.landing_velocity.x,e.landing_velocity.z).length()-Vector2(p.launch.x,p.launch.z).length())<0.03,
		"steering landing: native contact redirects earned speed without bending or boosting flight "+label)
	var spin_entries := 0
	for entry: String in e.entries:
		if entry.ends_with(" 180"):spin_entries+=1
	check.call(e.entries.count("Ollie")==1 and spin_entries==(1 if degrees>=160.0 else 0)
		and e.points==(300 if degrees>=160.0 else 100) and f.rider._air_steer_turn==0.0,
		"steering landing: actual rotation scores once while steering never manufactures fakie "+label)
	print("STEERING_LANDING ",{"side":side,"degrees":degrees,"turn":actual_turn,"heading":f.rider.rotation.y,
		"velocity":f.rider.velocity,"landing_velocity":e.landing_velocity,"landing_speed":e.landing_speed,
		"air_velocity_error":p.maximum_air_velocity_error,"air_heading_error":p.maximum_air_heading_error,
		"bails":e.bails,"landings":e.lands,"entries":e.entries,"points":e.points,"stance":f.rider.stance})
	await Classic._dispose(tree,f)

static func _mixed_spin(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await Classic._fixture(tree)
	var e := {"bails":0,"lands":0}
	f.rider.bailed.connect(func():e.bails+=1)
	f.rider.landed.connect(func(_clean:bool):e.lands+=1)
	await _launch(tree,f)
	Input.action_press("steer_right")
	await Classic._frames(tree,13)
	Input.action_release("steer_right")
	Input.action_press("spin_left")
	await Classic._frames(tree,13)
	Input.action_release("spin_left")
	var cancelled_yaw: float=f.rider._air_spin
	for frame: int in 60:
		await Classic._frames(tree,1)
		if e.bails>0:break
	check.call(absf(cancelled_yaw)<0.001 and e.bails==1 and e.lands==0
		and f.rider._air_steer_turn==0.0,
		"steering landing: a cancelling steer cannot wash out an unfinished explicit shoulder spin")
	await Classic._dispose(tree,f)

static func _late_flip(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await Classic._fixture(tree)
	var e := {"bails":0,"lands":0}
	f.rider.bailed.connect(func():e.bails+=1)
	f.rider.landed.connect(func(_clean:bool):e.lands+=1)
	await _launch(tree,f)
	Input.action_press("steer_right",PI/2.0/(20.0*f.rider.SPIN_SPEED/60.0))
	await Classic._frames(tree,20)
	Input.action_release("steer_right")
	for frame: int in 40:
		if f.rider.velocity.y<0.0 and f.rider.global_position.y<0.35:break
		await Classic._frames(tree,1)
	Input.action_press("flip")
	await Classic._frames(tree,1)
	Input.action_release("flip")
	var started := f.rider._flip_remaining>0.0
	for frame: int in 20:
		await Classic._frames(tree,1)
		if e.bails>0:break
	check.call(started and e.bails==1 and e.lands==0,
		"steering landing: ordinary turn forgiveness still rejects a real unfinished late flip")
	await Classic._dispose(tree,f)

static func _restart(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await Classic._fixture(tree)
	await _launch(tree,f)
	Input.action_press("steer_left")
	await Classic._frames(tree,6)
	Input.action_release("steer_left")
	var earned: bool=absf(f.rider._air_steer_turn)>0.5
	f.rider.reset_skater()
	check.call(earned and f.rider._air_steer_turn==0.0,
		"steering landing: explicit restart clears only the prior flight's earned steering")
	await Classic._frames(tree,45)
	await _launch(tree,f)
	await Classic._frames(tree,65)
	check.call(not f.rider.bailing and f.rider.is_on_floor() and absf(f.rider.rotation.y)<0.001
		and f.rider.velocity.z< -5.0 and f.rider._air_steer_turn==0.0,
		"steering landing: a fresh unsteered flight cannot inherit its predecessor's turn")
	await Classic._dispose(tree,f)

static func _blocked_rollout(tree: SceneTree, check: Callable) -> void:
	var f: Dictionary = await Classic._fixture(tree)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(0.2,5,100);shape.shape=box;wall.add_child(shape)
	wall.position=Vector3(2,2.5,0);f.root.add_child(wall)
	await _launch(tree,f)
	Input.action_press("steer_right",PI/2.0/(20.0*f.rider.SPIN_SPEED/60.0))
	await Classic._frames(tree,20)
	Input.action_release("steer_right")
	await Classic._frames(tree,45)
	check.call(not f.rider.bailing and f.rider.is_on_floor() and f.rider.global_position.x<1.65
		and f.rider.global_position.x>1.0 and absf(f.rider.velocity.x)<0.05,
		"steering landing: redirected rollout still stops at the actual native wall without restoring blocked motion")
	await Classic._dispose(tree,f)
