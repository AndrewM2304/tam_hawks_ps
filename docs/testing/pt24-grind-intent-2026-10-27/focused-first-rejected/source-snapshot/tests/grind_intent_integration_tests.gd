extends RefCounted
## Real held input reaches a solid rail; controlled drops isolate the landing tick.
const Skater=preload("res://game/player/skater.gd")
const Line=preload("res://game/tricks/grind_line.gd")
const Setup=preload("res://game/core/input_setup.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	Setup.register_actions();_release()
	await _played_rise(tree,check,0.0)
	await _played_rise(tree,check,84.0)
	await _landing_tick(tree,check,true)
	await _landing_tick(tree,check,false)
	await _obstructed(tree,check)
	await _ordinary_floor(tree,check)
	_release()

static func _played_rise(tree: SceneTree,check: Callable,degrees: float) -> void:
	_release()
	var radians:=deg_to_rad(degrees)
	var heading:=Vector3(-sin(radians),0.0,-cos(radians))
	var front:=Vector3.ZERO if degrees==0.0 else Vector3(0.0,0.0,-6.0)
	var f: Dictionary=await _fixture(tree,front-heading*4.5,heading)
	var r: CharacterBody3D=f.rider
	var observations: Array[Dictionary]=[]
	var awards: Array[String]=[]
	var held_ticks: Array[int]=[0]
	r.grind_captured.connect(func(id: String):observations.append({"id":id,"position":r.global_position,"held_ticks":held_ticks[0],
		"launched":r._launch_age,"direction":r._grind.direction}))
	r.trick_performed.connect(func(_label: String,_points: int):awards.append(r.last_trick_id))
	check.call(r.is_on_floor() and not r.airborne,"grind intent native: mapped approach begins on actual floor "+str(degrees))
	Input.action_press("push",0.55);Input.action_press("grind")
	for tick: int in 100:
		await _frames(tree,1);held_ticks[0]+=1
		if absf(r.speed)>=4.5:break
	check.call(not r.grinding and r.is_on_floor() and absf(r.speed)>=4.5,
		"grind intent native: holding Grind on supported approach does not attach before Ollie "+str(degrees))
	Input.action_press("ollie")
	await _frames(tree,15);held_ticks[0]+=15
	Input.action_release("ollie")
	var previous_vy:=r.velocity.y
	var prior_rising:=false
	var maximum:=0.0
	var previous:=r.global_position
	var left_floor:=false
	for tick: int in 65:
		previous_vy=r.velocity.y
		await _frames(tree,1);held_ticks[0]+=1
		maximum=maxf(maximum,previous.distance_to(r.global_position));previous=r.global_position
		left_floor=left_floor or r.airborne or r.grinding
		if r.grinding:
			prior_rising=previous_vy>1.0
			break
	check.call(left_floor and prior_rising and observations.size()==1 and observations[0].id==f.line.id
		and held_ticks[0]>20 and Input.is_action_pressed("grind"),
		"grind intent native: already-held Grind catches the real solid rail on Ollie ascent with rough aim "+str(degrees))
	check.call(not r.bailing and maximum<=0.99 and awards.count("ollie")==1 and _grind_awards(awards)==1,
		"grind intent native: one bounded rising catch retains one Ollie and one grind award "+str(degrees))
	print("GRIND_INTENT_RISE ",{"degrees":degrees,"captured":observations,"prior_vy":previous_vy,
		"maximum_native_step":maximum,"at":r.global_position,"velocity":r.velocity,"awards":awards})
	_release();f.viewport.queue_free();await tree.process_frame

static func _landing_tick(tree: SceneTree,check: Callable,held: bool) -> void:
	_release()
	var f: Dictionary=await _fixture(tree,Vector3(0,1.60,-5),Vector3.FORWARD)
	var r: CharacterBody3D=f.rider
	# Declared initial-state contact fixture, not a played Ollie. Position and
	# velocity are set once; native movement owns every subsequent sample.
	r.set_physics_process(false);r.global_position=Vector3(0,1.60,-5);r.velocity=Vector3.ZERO;r.move_and_slide()
	r.airborne=true;r.velocity=Vector3(0,-45,-6);r.speed=6.0;r.set_physics_process(true)
	var captures: Array[Dictionary]=[]
	r.grind_captured.connect(func(id: String):captures.append({"id":id,"floor":r.is_on_floor(),"at":r.global_position}))
	if held:Input.action_press("grind")
	await _frames(tree,1)
	if held:
		check.call(captures.size()==1 and captures[0].id==f.line.id and captures[0].floor and r.grinding,
			"grind intent native: completed fast descent catches before a real rail-floor landing can bank the combo")
		await _frames(tree,5)
		check.call(captures.size()==1 and r.grinding and not r.bailing,
			"grind intent native: native rail-floor catch continues without duplicate capture or solid-support bail")
	else:
		await _frames(tree,5)
		check.call(captures.is_empty() and not r.grinding and r.is_on_floor() and r.global_position.y>=0.919,
			"grind intent native: without Grind the rail stays solid and supports the real rider without automatic capture")
	print("GRIND_INTENT_LANDING ",{"held":held,"captures":captures,"floor":r.is_on_floor(),"grinding":r.grinding,"at":r.global_position})
	_release();f.viewport.queue_free();await tree.process_frame

static func _obstructed(tree: SceneTree,check: Callable) -> void:
	_release()
	var f: Dictionary=await _fixture(tree,Vector3(0.65,1.1,-5),Vector3.FORWARD)
	var wall:=_box(f.root,Vector3(0.3,1.5,-6),Vector3(0.08,3,12),1)
	wall.set_meta("no_wallride",true)
	var r: CharacterBody3D=f.rider
	r.set_physics_process(false);r.global_position=Vector3(0.65,1.1,-5);r.velocity=Vector3.ZERO;r.move_and_slide()
	r.airborne=true;r.velocity=Vector3(0,-1,-6);r.speed=6.0;r.set_physics_process(true)
	var captures: Array[String]=[];r.grind_captured.connect(func(id:String):captures.append(id))
	Input.action_press("grind");await _frames(tree,3)
	check.call(captures.is_empty() and not r.grinding and r.global_position.x>0.58,
		"grind intent native: a nearby target behind a real solid wall cannot borrow held-input forgiveness")
	_release();f.viewport.queue_free();await tree.process_frame

static func _ordinary_floor(tree: SceneTree,check: Callable) -> void:
	_release()
	var f: Dictionary=await _fixture(tree,Vector3(2,0.05,-5),Vector3.FORWARD)
	var r: CharacterBody3D=f.rider
	var captures: Array[String]=[];r.grind_captured.connect(func(id:String):captures.append(id))
	Input.action_press("push",0.55);Input.action_press("grind");await _frames(tree,40)
	Input.action_press("ollie");await _frames(tree,15);Input.action_release("ollie");Input.action_release("push");await _frames(tree,90)
	check.call(captures.is_empty() and not r.grinding and r.is_on_floor() and not r.bailing,
		"grind intent native: ordinary floor landing away from the rail remains a floor landing while Grind is held")
	_release();f.viewport.queue_free();await tree.process_frame

static func _fixture(tree: SceneTree,spawn: Vector3,heading: Vector3) -> Dictionary:
	var viewport:=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport);var root:=Node3D.new();viewport.add_child(root)
	_box(root,Vector3(0,-0.1,-5),Vector3(40,0.2,40),1)
	var rail:=_box(root,Vector3(0,0.85,-6),Vector3(0.14,0.14,12),1|2)
	var line:=Line.new("intent_native_rail",PackedVector3Array([Vector3(0,0.92,0),Vector3(0,0.92,-12)]),"rail")
	line.configure_contact(0.0,0.0,"intent_native.box_bar_top")
	rail.set_meta("authored_grind_ids",[line.id]);rail.set_meta("audit_capture_ids",[line.id])
	var rider:=Skater.new();rider.spawn_position=spawn;root.add_child(rider)
	rider.rotation.y=atan2(-heading.x,-heading.z);rider.set_grind_lines([line])
	await _frames(tree,4)
	return {"viewport":viewport,"root":root,"rider":rider,"rail":rail,"line":line}

static func _box(root: Node3D,at: Vector3,size: Vector3,layer: int) -> StaticBody3D:
	var body:=StaticBody3D.new();body.position=at;body.collision_layer=layer;body.collision_mask=0
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size
	collision.shape=shape;body.add_child(collision);root.add_child(body);return body

static func _grind_awards(awards: Array[String]) -> int:
	var count:=0
	for id: String in awards:
		if id in ["rail_grind","grind_50_50","boardslide"]:count+=1
	return count

static func _frames(tree: SceneTree,count: int) -> void:
	for tick: int in count:await tree.physics_frame;await tree.process_frame

static func _release() -> void:
	for action: StringName in InputMap.get_actions():Input.action_release(action)
