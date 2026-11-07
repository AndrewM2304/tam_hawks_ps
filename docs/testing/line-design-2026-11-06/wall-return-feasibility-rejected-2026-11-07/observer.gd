extends SceneTree
# OFFLINE PROTOTYPE: real native WallRide/Wallie return slice, not circuit acceptance.
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
var passed:=0
var failed:=0
func _initialize():_run.call_deferred()
func _check(ok: bool,label: String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	create_timer(100,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await Driver._frames(self,40)
	var wall: StaticBody3D
	for body: StaticBody3D in game.world.find_children("*","StaticBody3D",true,false):
		if body.get_meta("boundary_family","")=="QuayLandwardBoundary":
			var points: PackedVector3Array=body.get_meta("boundary_points")
			if points[0].x>=14.9:wall=body
	if wall==null:
		_check(false,"east landward masonry exists")
	else:
		print("RETURN WALL ACTUAL points=",wall.get_meta("boundary_points")," height=",wall.get_meta("boundary_height"))
		for heading: Vector2 in [Vector2(.94,.342),Vector2(.8,.6)]:
			await _case(game,wall,heading.normalized())
	game.free()
	print("RETURN WALL PROTOTYPE RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed>0 else 0)
func _case(game: Node,wall: StaticBody3D,heading: Vector2):
	# Test two honest approach angles. A more glancing line retains enough
	# board-forward momentum after the real outward Wallie for a useful Manual.
	await Driver._reset(self,game,Vector3(65,2.08,60.8),atan2(heading.x,heading.y))
	await Driver._frames(self,40)
	var e=Driver._evidence(game,"prototype_native_landward_return_"+str(heading))
	Driver._connect(game,e)
	var charged:=false
	var popped:=false
	var wall_seen:=false
	var wallie:=false
	var wall_ticks:=0
	var wall_start:=Vector3.ZERO
	var wall_end:=Vector3.ZERO
	var events: Array[Dictionary]=[]
	for tick: int in 240:
		if not popped:
			# Stable mapped Push through the cap avoids an alternating setup cue.
			Input.action_press("push")
			Input.action_release("brake")
			if absf(game.skater.speed)>8.5:Input.action_press("brake")
			if game.skater.global_position.z<=58.8 and not charged:
				charged=true
				Input.action_press("ollie")
			if game.skater.global_position.z<=57.2:
				Input.action_release("ollie")
				Input.action_release("push")
				Input.action_release("brake")
				Input.action_press("grind")
				popped=true
				events.append({"event":"mapped_pop","physics":Engine.get_physics_frames(),"at":game.skater.global_position,"velocity":game.skater.velocity})
		await Driver._step(self,game,e,"prototype_landward_approach",Callable())
		if game.skater.wallriding or e.bails>0:break
	if game.skater.wallriding:
		wall_seen=game.skater._wall.wall_id==str(wall.get_path())
		wall_start=game.skater.global_position
		events.append({"event":"native_wallride","physics":Engine.get_physics_frames(),"at":wall_start,"wall":game.skater._wall.wall_id})
		for tick: int in 30:
			await Driver._step(self,game,e,"prototype_landward_wallride",Callable())
			if not game.skater.wallriding or e.bails>0:break
			wall_ticks+=1
		wall_end=game.skater.global_position
		if game.skater.wallriding and wall_ticks>=30:
			Input.action_press("ollie")
			await Driver._steps(self,game,e,2,"prototype_wallie_charge",Callable())
			var supported_release: bool=game.skater.wallriding and game.skater._wall.wall_id==str(wall.get_path())
			Input.action_release("ollie")
			await Driver._step(self,game,e,"prototype_mapped_wallie_release",Callable())
			wallie=supported_release and not game.skater.wallriding and game.skater._launch_id=="wallie"
			events.append({"event":"mapped_wallie_release","physics":Engine.get_physics_frames(),"at":game.skater.global_position,"velocity":game.skater.velocity,"native_wallie":wallie})
			Input.action_release("grind")
			await Driver._landing_manual(self,game,e,150,"prototype_wallie_manual_landing",Callable())
	var travel:=Vector2(wall_end.x-wall_start.x,wall_end.z-wall_start.z).length()
	_check(wall_seen and wall_ticks>=30 and travel>=3.0 and wallie,"prototype actual glancing native masonry ride spans >=30 physics steps/3m and mapped Wallie")
	_check(game.skater.manual_active and e.bails==0 and e.recoveries==0 and e.camera_clear,"prototype actual supported Manual landing with strict chase")
	print("RETURN WALL EVENTS heading=",heading," events=",events," wall_ticks=",wall_ticks," wall_travel=",travel," manual_speed=",game.skater.speed)
	Driver._disconnect(game,e)
	Driver._report(e,game)
	Driver._release()
