extends RefCounted
## The low-court route reaches the ramp's real toe/head. Ordinary mapped
## push/brake then traverses that same native ramp both ways without an ollie.
const Routes = preload("res://tests/world_routes_tests.gd")

static func run(tree: SceneTree,game: Node,check: Callable) -> void:
	var route: Dictionary = {}
	for value: Dictionary in game.world.get_route_definitions():
		if value.id=="merchant_service_west_return":route=value
	check.call(not route.is_empty(),"merchant return: existing stable route ID remains published")
	if route.is_empty():return
	var points: PackedVector3Array = route.points
	var clear := true
	var support := true
	for i in points.size()-1:
		clear = clear and Routes._clear_sweep(game.world,points[i],points[i+1]) and Routes._clear_sweep(game.world,points[i+1],points[i])
		for j in 9:
			var point := points[i].lerp(points[i+1],float(j)/8.0)
			var hit := Routes._floor_hit(game.world,point+Vector3.UP*0.2)
			support = support and not hit.is_empty() and absf(hit.get("position",Vector3.INF).y-point.y)<0.003
	check.call(clear and support,"merchant return: every published segment has native support and clear bidirectional capsules")
	var original_spawn: Vector3 = game.skater.spawn_position
	var original_mode: bool = game.free_skate_mode
	var events := {"bails":0,"ollies":0}
	var on_bail := func()->void:events.bails+=1
	var on_trick := func(label:String,_points:int)->void:
		if label.contains("Ollie"):events.ollies+=1
	game.skater.bailed.connect(on_bail)
	game.skater.trick_performed.connect(on_trick)
	for downhill: bool in [false,true]:
		_release()
		game.skater.spawn_position=Vector3(-78,4.03,-76) if downhill else Vector3(-78,1.03,-65.6)
		game.start_mode(true)
		game.skater.rotation.y=PI if downhill else 0.0
		for i in 3:
			await tree.physics_frame
			await tree.process_frame
		var reached := false
		var supported := true
		var frames := 0
		for i in 480:
			# Inputs regulate a modest ordinary approach; no pose, heading,
			# velocity or speed is corrected after the initial fixture placement.
			var maximum := 2.0 if downhill else 5.0
			var brake := absf(game.skater.speed)>maximum
			if brake:
				Input.action_release("push")
				Input.action_press("brake")
			else:
				Input.action_release("brake")
				Input.action_press("push")
			await tree.physics_frame
			await tree.process_frame
			frames+=1
			var at: Vector3 = game.skater.global_position
			var height: float = game.world.get_support_height(at,0.3)
			supported = supported and is_finite(height) and absf(at.y-height)<0.13
			reached = at.z>=-65.8 if downhill else at.z<=-75.0
			if reached or events.bails>0:break
		_release()
		check.call(reached and supported and events.bails==0 and events.ollies==0,
			"merchant return: ordinary no-jump "+("descent reaches the full-width low toe" if downhill else "climb leaves the low pocket for the backstreet"))
		print("MERCHANT_RETURN downhill=%s reached=%s supported=%s frames=%d position=%s bails=%d ollies=%d"%[
			downhill,reached,supported,frames,game.skater.global_position,events.bails,events.ollies])
	game.skater.bailed.disconnect(on_bail)
	game.skater.trick_performed.disconnect(on_trick)
	game.skater.spawn_position=original_spawn
	game.start_mode(original_mode)


static func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
