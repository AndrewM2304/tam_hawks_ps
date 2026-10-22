extends RefCounted
## Actual mapped input: one charged release adds real pop to the current ramp ascent.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Setup=preload("res://game/core/input_setup.gd")
static func run(tree:SceneTree,check:Callable)->void:
	Setup.register_actions()
	var results:Array[Dictionary]=[]
	for charged:bool in [false,true]:
		var f:=await Classic._pipe_fixture(tree)
		var rider:CharacterBody3D=f.rider
		var awards:Array[String]=[]
		rider.trick_performed.connect(func(id:String,_points:int):awards.append(id))
		Classic._key(KEY_W,true)
		if charged:Classic._key(KEY_SPACE,true)
		var reached:=false
		for tick in 180:
			await Classic._frames(tree,1)
			if rider.transition_active and rider._transition.theta>=deg_to_rad(65.0) and rider.velocity.y>4.0:
				reached=true
				break
		if not charged:
			Classic._key(KEY_SPACE,true)
			await Classic._frames(tree,2)
		var before:Vector3=rider.velocity
		var on_ramp:bool=rider.transition_active
		var normal:Vector3=rider.transition_normal
		Classic._key(KEY_SPACE,false)
		await Classic._frames(tree,1)
		var launch:Vector3=rider.velocity
		var impulse:=13.0 if charged else 8.0
		check.call(reached and on_ramp and rider.airborne and rider._ramp_air
			and absf(launch.y-(maxf(0.0,before.y)+impulse+normal.y*.25))<.15
			and Vector2(launch.x,launch.z).distance_to(Vector2(before.x, before.z)+Vector2(normal.x,normal.z)*.25)<.10,
			"ramp pop: actual %s release adds upward impulse and preserves carried horizontal momentum"%('charged' if charged else 'tap'))
		var origin_y:=rider.global_position.y
		var rise:=0.0
		var landed:=false
		Classic._key(KEY_SPACE,true)
		await Classic._frames(tree,2)
		Classic._key(KEY_SPACE,false)
		for tick in 240:
			await Classic._frames(tree,1)
			rise=maxf(rise,rider.global_position.y-origin_y)
			if not rider.airborne:
				landed=true
				break
		check.call(landed and awards.count('Ollie')==1 and not rider._ramp_air,
			"ramp pop: %s flight lands physically and a second airborne release adds no impulse/award"%('charged' if charged else 'tap'))
		check.call(rise>launch.y*launch.y/(2.0*22.0)*.85,
			"ramp pop: %s boost produces real height rather than a visual-only lift"%('charged' if charged else 'tap'))
		results.append({'charged':charged,'before':before,'launch':launch,'rise':rise,'landed':landed,'awards':awards})
		print('RAMP_POP ',results[-1])
		await Classic._dispose(tree,f)
	check.call(results[1].launch.y>results[0].launch.y+3.5 and results[1].rise>results[0].rise*1.3,
		"ramp pop: charged release gives materially more launch speed and actual height than tap")
