extends RefCounted
## Real input regression for the shop wall which blocked the Foundry west bank.
const Main=preload("res://game/main.gd")

static func run(tree:SceneTree,check:Callable)->void:
	_release()
	var game:=Main.new();game.persistence_enabled=false
	game.profile_path="user://unused-merchant-portal-tests.json";game.legacy_profile_path=""
	check.call(not game.persistence_enabled,"Merchant portal: isolate persistence before Main enters tree")
	tree.root.add_child(game)
	check.call(game.level_id=="merchant_neighbourhood_v1" and not game.music._persist and not game.music._can_control,
		"Merchant portal: ordinary default world with personal Music inert")
	await _frames(tree,2)
	var routes:Array=game.world.get_route_definitions();var ids:Dictionary={};var unique:=true;var west:Array=[]
	for route:Dictionary in routes:
		if ids.has(route.id):unique=false
		ids[route.id]=true
		if route.id=="md_foundry_west":west.append(route)
	check.call(unique and west.size()==1,"Merchant portal: one unambiguous west-bank navigation route")
	var native_datums:bool=west.size()==1
	if native_datums:
		for point:Vector3 in west[0].points:
			var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.5,point-Vector3.UP*.5,1)
			ray.collide_with_areas=false
			var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(ray)
			native_datums=native_datums and not hit.is_empty() and absf(float(hit.get("position",Vector3.INF).y)-point.y)<.002
	check.call(native_datums,"Merchant portal: route heights agree with actual native floor rays through the bank")
	var retaining_faces:=true
	for z:float in [24.0,30.0]:
		var inward:=Vector3.BACK if z==24.0 else Vector3.FORWARD
		for x:float in ([23.0,25.0,29.0] if z==24.0 else [23.0,25.0,29.0,35.0,60.0,75.0]):
			var bank_y:float=4.0-clampf((x-20.0)*.15,0,1.5)
			var at:=Vector3(x,(4.0+bank_y)*.5,27)
			var ray:=PhysicsRayQueryParameters3D.create(at,Vector3(x,at.y,z)-inward*.2,1)
			var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty():retaining_faces=false;continue
			var visuals:Array=hit.collider.find_children("*","MeshInstance3D",true,false)
			retaining_faces=retaining_faces and absf(hit.position.z-z)<.001 and hit.normal.dot(inward)>.99 and visuals.size()==1
			if visuals.size()!=1:continue
			var arrays:Array=visuals[0].mesh.surface_get_arrays(0)
			var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			retaining_faces=retaining_faces and uv.size()>=3 and absf((uv[1]-uv[0]).cross(uv[2]-uv[0]))>.0001
			for normal:Vector3 in arrays[Mesh.ARRAY_NORMAL]:retaining_faces=retaining_faces and normal.dot(inward)>.99
	check.call(retaining_faces,"Merchant portal: real bank retaining faces cover the street drop with inward drawn normals and noncollapsed UVs")
	for eastbound:bool in [true,false]:
		for z:float in [25.0,27.0,29.0]:
			_release()
			# One initial fixture per independent run. No subsequent actor state writes.
			game.skater.spawn_position=Vector3(12,4.04,z) if eastbound else Vector3(36,2.54,z)
			game.start_mode(true);game.skater.rotation.y=-PI*.5 if eastbound else PI*.5
			await _frames(tree,12)
			var crossed:=false;var bail_ticks:=0;var air_ticks:=0;var maximum_y_step:=0.0
			var prior_y:float=game.skater.global_position.y
			Input.action_press("push")
			for tick:int in 300:
				await _frames(tree,1)
				var rider:CharacterBody3D=game.skater;var at:Vector3=rider.global_position
				maximum_y_step=maxf(maximum_y_step,absf(at.y-prior_y));prior_y=at.y
				if rider.bail_active:bail_ticks+=1
				if rider.airborne:air_ticks+=1
				if (at.x>=33.0 if eastbound else at.x<=12.0):crossed=true;break
			_release()
			var label:String=("east" if eastbound else "west")+" shoulder/centre z"+str(z)
			check.call(crossed and bail_ticks==0,"Merchant portal: mapped push crosses the real bank without obstruction "+label)
			check.call(air_ticks==0 and maximum_y_step<.12,"Merchant portal: native passage stays grounded without a jump or height snap "+label)
			print("MERCHANT_PORTAL ",label," final=",game.skater.global_position," max_y_step=",maximum_y_step," air_ticks=",air_ticks," bail_ticks=",bail_ticks)
	# The old frontage AND its rear service masses blocked this return. These
	# independent component fixtures start outside both original and revised walls.
	for from_market:bool in [true,false]:
		for sample:float in ([-14.0,-12.0,-10.0] if from_market else [57.0,58.0,59.0]):
			_release()
			game.skater.spawn_position=Vector3(sample,4.04,33) if from_market else Vector3(18,4.04,sample)
			game.start_mode(true);game.skater.rotation.y=PI if from_market else PI*.5
			await _frames(tree,12)
			var crossed:=false;var air_ticks:=0;var bail_ticks:=0;var maximum_y_step:=0.0;var prior_y:float=game.skater.global_position.y
			Input.action_press("push")
			for tick:int in 300:
				await _frames(tree,1)
				var rider:CharacterBody3D=game.skater;var at:Vector3=rider.global_position
				maximum_y_step=maxf(maximum_y_step,absf(at.y-prior_y));prior_y=at.y
				if rider.airborne:air_ticks+=1
				if rider.bail_active:bail_ticks+=1
				if (at.z>=59.0 if from_market else at.x<=-12.0):crossed=true;break
			_release()
			var label:String=("south from Market x" if from_market else "west from court z")+str(sample)
			check.call(crossed and bail_ticks==0,"Merchant service close: mapped push clears the former frontage/rear obstruction "+label)
			check.call(air_ticks==0 and maximum_y_step<.12,"Merchant service close: native component stays grounded "+label)
	for from_market:bool in [true,false]:await _dogleg(tree,game,from_market,check)
	_release();game.queue_free();await tree.process_frame;await tree.physics_frame

static func _dogleg(tree:SceneTree,game:Node,from_market:bool,check:Callable)->void:
	_release()
	game.skater.spawn_position=Vector3(-12,4.04,33) if from_market else Vector3(18,4.04,59)
	game.start_mode(true);game.skater.rotation.y=PI if from_market else PI*.5
	await _frames(tree,12)
	var targets:Array[Vector3]=[]
	targets.assign([Vector3(-12,4,59),Vector3(18,4,59)] if from_market else [Vector3(-12,4,59),Vector3(-12,4,33)])
	var index:=0;var air_ticks:=0;var bail_ticks:=0;var maximum_y_step:=0.0;var prior_y:float=game.skater.global_position.y
	for tick:int in 1500:
		var rider:CharacterBody3D=game.skater;var offset:Vector3=targets[index]-rider.global_position;offset.y=0
		if offset.length()<.8:
			index+=1
			if index==targets.size():break
			offset=targets[index]-rider.global_position;offset.y=0
		var forward:Vector3=-rider.global_basis.z;forward.y=0
		var axis:float=clampf(-forward.normalized().signed_angle_to(offset.normalized(),Vector3.UP)*2.0,-.9,.9)
		_release()
		if rider.speed<3.4:Input.action_press("push")
		elif rider.speed>3.8:Input.action_press("brake")
		if axis>0:Input.action_press("steer_right",axis)
		elif axis<0:Input.action_press("steer_left",-axis)
		await _frames(tree,1)
		maximum_y_step=maxf(maximum_y_step,absf(rider.global_position.y-prior_y));prior_y=rider.global_position.y
		if rider.airborne:air_ticks+=1
		if rider.bail_active:bail_ticks+=1
		if rider.bail_active:break
	_release()
	check.call(index==targets.size() and air_ticks==0 and bail_ticks==0 and maximum_y_step<.12,
		"Merchant service close: one real rider steers the complete grounded dogleg "+str(from_market))

static func _release()->void:
	for action:String in ["push","brake","steer_left","steer_right","ollie","grind","manual","flip","grab","spin_left","spin_right","revert"]:Input.action_release(action)

static func _frames(tree:SceneTree,count:int)->void:
	for tick:int in count:await tree.physics_frame;await tree.process_frame
