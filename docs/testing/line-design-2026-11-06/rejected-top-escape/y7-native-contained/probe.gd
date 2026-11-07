extends SceneTree
const Main=preload("res://game/main.tscn")
const Setup=preload("res://game/core/input_setup.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
var failed:=0
func _initialize():_run.call_deferred()
func _run():
	create_timer(120,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	for gate: float in [78.0,78.7,79.4,80.1]:
		await Driver._reset(self,game,Vector3(66,2.08,73.5),-PI*.5)
		await Driver._frames(self,40)
		var e:=Driver._evidence(game,"bank_uphill_top_miss_"+str(gate))
		Driver._connect(game,e)
		var start:=Engine.get_physics_frames()
		var charge:=false
		var released:=false
		var charge_ticks:=0
		var escaped:=false
		var peak:=Vector3.ZERO
		var maximum_x:=-INF
		var events:Array=[]
		for tick: int in 480:
			if not released:
				Driver._steer_to(game,Vector3(88,2,73.5),false)
				Input.action_press("push")
				if not charge and game.skater.global_position.x>=gate:
					charge=true
					Input.action_press("ollie")
					events.append({"event":"charge","physics":Engine.get_physics_frames(),"at":game.skater.global_position,"speed":game.skater.speed})
				if charge:
					charge_ticks+=1
					if charge_ticks>16:
						released=true
						Driver._release()
						events.append({"event":"release","physics":Engine.get_physics_frames(),"at":game.skater.global_position,"speed":game.skater.speed,"velocity":game.skater.velocity})
			await Driver._step(self,game,e,"charged_uphill_top_miss",Callable())
			var at: Vector3=game.skater.global_position
			maximum_x=maxf(maximum_x,at.x)
			if at.y>peak.y:peak=at
			if at.x>85.2 and not escaped:
				escaped=true
				events.append({"event":"outside_quay","physics":Engine.get_physics_frames(),"at":at,"native_support_query":game.world.get_support_height(at,.3)})
			if e.bails>0 or (released and tick>300):break
		Driver._release()
		print("BANK_TOP_ESCAPE gate=",gate," startphysics=",start," events=",events," escaped=",escaped," maxX=",maximum_x," peak=",peak," camera=",e.camera_clear," bails=",e.bails," recoveries=",e.recoveries," tricks=",e.entries)
		if escaped:failed+=1
		Driver._disconnect(game,e)
	game.free()
	print("BANK_TOP_ESCAPE_RESULT failures=",failed)
	quit(1 if failed>0 else 0)
