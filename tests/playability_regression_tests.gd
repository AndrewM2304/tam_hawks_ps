extends RefCounted
## Ordinary callbacks and mapped inputs. No authored camera, manual _process call,
## or per-frame heading/position/speed assignment. Fixtures are initial placements only.

static func run_normal_boot(tree: SceneTree, game: Node, check: Callable) -> void:
	check.call(not OS.get_cmdline_args().has("--script") and game.paused
		and game.hud._page == "title", "playability boot: unmodified Main enters its actual paused title branch")
	await run(tree, game, check)


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var old_spawn: Vector3 = game.skater.spawn_position
	var old_mode: bool = game.free_skate_mode
	var old_size: Vector2i = tree.root.size
	game.persistence_enabled = false
	_release()
	# The aggregate uses --script; its title branch is deliberately skipped by Main.
	# A separate no---script scene invokes run_normal_boot to prove the real boot branch.
	if game.hud._page != "title":
		game.skater.spawn_position = game.world.get_spawn_position()
		game.start_mode(false)
		game.toggle_pause()
		game.hud.show_title()
	await _frames(tree, 3)
	_check_visuals(game, check)
	await _activate(tree, game.hud, "FREE SKATE")
	await _frames(tree, 45)
	check.call(game.free_skate_mode and not game.paused and game.hud._page == "",
		"playability: title keyboard activation starts ordinary free skate")
	for size: Vector2i in [Vector2i(1280,800),Vector2i(1920,1080),Vector2i(800,600)]:
		tree.root.size = size
		await _frames(tree, 4)
		var frame := camera_sample(game)
		check.call(frame.current and frame.finite and frame.full_body and not frame.blocked
			and frame.distance >= 2.0, "playability: full rider and board remain framed at %s" % size)
	tree.root.size = old_size
	var natural := await drive_natural_spawn(tree,game)
	check.call(natural.distance > 20.0 and natural.left_turn > 0.3 and natural.right_turn < -0.3
		and natural.bails == 0 and natural.min_y > -0.1,
		"playability: spawn push and both steering directions move through real ground without heading assistance")
	check.call(natural.samples > 250 and natural.hidden == 0 and natural.blocked == 0
		and natural.close == 0 and natural.nonfinite == 0,
		"playability: natural spawn curves keep actual rider and board in the current chase view")
	var before_pause: Vector3 = game.skater.global_position
	await _tap(tree,KEY_ESCAPE)
	var paused_position: Vector3 = game.skater.global_position
	var paused_camera: Transform3D = game.get_viewport().get_camera_3d().global_transform
	Input.action_press("push")
	await _frames(tree,12)
	_release()
	check.call(game.paused and game.skater.global_position.is_equal_approx(paused_position)
		and game.get_viewport().get_camera_3d().global_transform.is_equal_approx(paused_camera)
		and paused_position.distance_to(before_pause) < 0.6,
		"playability: ordinary pause freezes player and chase without hiding the built rig")
	await _activate(tree,game.hud,"RESTART")
	await _frames(tree,35)
	var restarted := camera_sample(game)
	check.call(not game.paused and game.skater.global_position.distance_to(game.world.get_spawn_position()) < 1.0
		and restarted.full_body and not restarted.blocked and restarted.distance >= 2.0,
		"playability: mapped pause restart restores supported spawn and third-person framing")
	await _tap(tree,KEY_ESCAPE)
	await _activate(tree,game.hud,"START CAREER RUN")
	await _frames(tree,10)
	var career_frame := camera_sample(game)
	check.call(not game.free_skate_mode and not game.paused and game.time_remaining < 120.0
		and game.time_remaining > 118.0 and career_frame.full_body and career_frame.distance >= 2.0,
		"playability: visible mode control starts timed career with a visible complete rider")
	await _coast(tree,game,check)
	await _fixture(tree,game,Vector3(-34,1.25,4),-PI/2.0)
	var wall := _evidence()
	await _observe(tree,game,60,wall)
	check.call(wall.hidden == 0 and wall.close == 0 and wall.blocked == 0 and wall.nonfinite == 0,
		"playability: shopfront wall obstruction preserves full third-person rider instead of collapsing into the body")
	Input.action_press("steer_left")
	await _observe(tree,game,90,wall)
	_release()
	check.call(wall.hidden == 0 and wall.close == 0 and wall.blocked == 0,
		"playability: actual stationary steering beside the shop wall keeps the rider framed")
	print("PLAYABILITY WALL ",wall)
	for fixture:Dictionary in [
		{"label":"station low ceiling","position":Vector3(-114,2.8,-8),"heading":-PI/2.0},
		{"label":"gallery columns behind rider","position":Vector3(3,3.45,-37),"heading":PI}]:
		await _fixture(tree,game,fixture.position,fixture.heading)
		var tight := _evidence()
		await _observe(tree,game,60,tight)
		check.call(tight.hidden==0 and tight.close==0 and tight.blocked==0 and tight.nonfinite==0,
			"playability: %s keeps full rider and board framed without camera clipping" % fixture.label)
		print("PLAYABILITY CAMERA ",fixture.label," ",tight)
	await _closes(tree,game,check)
	await _edges_and_roofs(tree,game,check)
	_check_visuals(game,check)
	_release()
	tree.root.size = old_size
	game.skater.spawn_position = old_spawn
	game.start_mode(old_mode)
	check.call(not game.persistence_enabled,"playability: diagnosis never writes a player profile")


static func drive_natural_spawn(tree: SceneTree,game:Node,observer:Callable=Callable()) -> Dictionary:
	# Caller uses ordinary default spawn. Steering is only Input actions, including
	# the complete turns; there is no pose/camera correction between samples.
	var e := _evidence()
	var bail_counter := [0]
	var on_bail := func(): bail_counter[0] += 1
	game.skater.bailed.connect(on_bail)
	Input.action_press("push")
	await _observe(tree,game,120,e)
	if observer.is_valid():await observer.call("push",e.duplicate(true))
	var first_heading: float = game.skater.rotation.y
	Input.action_press("steer_left")
	await _observe(tree,game,60,e)
	e.left_turn = angle_difference(first_heading,game.skater.rotation.y)
	if observer.is_valid():await observer.call("left",e.duplicate(true))
	Input.action_release("steer_left")
	first_heading = game.skater.rotation.y
	Input.action_press("steer_right")
	await _observe(tree,game,120,e)
	e.right_turn = angle_difference(first_heading,game.skater.rotation.y)
	if observer.is_valid():await observer.call("right",e.duplicate(true))
	_release()
	e.bails = bail_counter[0]
	game.skater.bailed.disconnect(on_bail)
	print("PLAYABILITY NATURAL ",e)
	return e


static func _coast(tree:SceneTree,game:Node,check:Callable) -> void:
	await _fixture(tree,game,game.world.get_spawn_position(),0.0)
	var evidence:=_evidence()
	var bail_counter:=[0]
	var on_bail:=func():bail_counter[0]+=1
	game.skater.bailed.connect(on_bail)
	Input.action_press("push")
	await _observe(tree,game,90,evidence)
	_release()
	var launch_speed:float=game.skater.speed
	check.call(launch_speed>12.0 and evidence.wall_contacts==0 and bail_counter[0]==0,
		"playability coast: ordinary pushing reaches useful speed on the clear default spine")
	await _observe(tree,game,180,evidence)
	var three_seconds:float=game.skater.speed
	check.call(three_seconds>0.2 and three_seconds<8.0 and evidence.wall_contacts==0 and bail_counter[0]==0,
		"playability coast: releasing push visibly slows in three seconds without a wall or bail doing the braking")
	await _observe(tree,game,270,evidence)
	check.call(game.skater.speed<0.05 and game.skater.is_on_floor() and evidence.wall_contacts==0
		and bail_counter[0]==0 and evidence.distance>25.0 and evidence.distance<90.0,
		"playability coast: ordinary unassisted coasting stops within a bounded distance and time")
	game.skater.bailed.disconnect(on_bail)
	print("PLAYABILITY COAST launch=",launch_speed," after3s=",three_seconds," final=",game.skater.speed," ",evidence)


static func _closes(tree:SceneTree,game:Node,check:Callable) -> void:
	for x in [-12.0,12.0]:
		for north in [true,false]:
			var a := Vector3(x,2,-39) if north else Vector3(x,0,39)
			var b := Vector3(x,4,-59) if north else Vector3(x,2,59)
			var label := ("gallery" if north else "quay") + " close X%s" % x
			var support_ok := true
			for offset in [-2.0,0.0,2.0]:
				for index in 21:
					var at := a.lerp(b,float(index)/20.0)+Vector3(offset,0,0)
					var hit := _ray(game,at+Vector3.UP*3,at+Vector3.DOWN*3)
					if hit.is_empty() or hit.normal.y < 0.8: support_ok=false
			check.call(support_ok,"playability: %s has actual upward support across center and both lateral offsets" % label)
			for reverse in [false,true]:
				var start := b if reverse else a
				var finish := a if reverse else b
				await _fixture(tree,game,start+Vector3.UP*0.8,atan2(-(finish-start).x,-(finish-start).z))
				var e := _evidence()
				var bail_counter := [0]
				var on_bail := func(): bail_counter[0]+=1
				game.skater.bailed.connect(on_bail)
				Input.action_press("push")
				var reached := false
				for tick in 210:
					await _observe(tree,game,1,e)
					var position:Vector3=game.skater.global_position
					if Vector2(position.x-finish.x,position.z-finish.z).length()<0.7:
						reached=true
						break
				_release()
				# A small, real crest departure can still be airborne at the first
				# endpoint sample. Require its normal landing under actual braking,
				# not an instantaneous floor flag or an injected support correction.
				Input.action_press("brake")
				await _observe(tree,game,40,e)
				_release()
				game.skater.bailed.disconnect(on_bail)
				check.call(reached and bail_counter[0]==0 and e.min_y >= minf(a.y,b.y)-0.08
					and game.skater.is_on_floor() and e.hidden==0 and e.close==0 and e.blocked==0,
					"playability: push-only %s %s crosses the formerly open floor without fall or lost rider" % [label,"reverse" if reverse else "forward"])
				print("PLAYABILITY CLOSE ",label," reverse=",reverse," reached=",reached," bails=",bail_counter[0]," ",e)


static func _edges_and_roofs(tree:SceneTree,game:Node,check:Callable) -> void:
	for fixture:Dictionary in [
		{"label":"Barras east edge","position":Vector3(127.8,0.8,0),"heading":-PI/2.0,"axis":"x","limit":129.8},
		{"label":"station south edge","position":Vector3(-120,2.8,43),"heading":PI,"axis":"z","limit":44.8}]:
		await _fixture(tree,game,fixture.position,fixture.heading)
		var e:=_evidence()
		var bails:=[0]
		var on_bail:=func():bails[0]+=1
		game.skater.bailed.connect(on_bail)
		Input.action_press("push")
		await _observe(tree,game,90,e)
		_release()
		var stopped:Vector3=game.skater.global_position
		var contained:bool=stopped.x<fixture.limit if fixture.axis=="x" else stopped.z<fixture.limit
		Input.action_press("steer_left")
		await _observe(tree,game,90,e)
		_release()
		Input.action_press("push")
		await _observe(tree,game,60,e)
		_release()
		game.skater.bailed.disconnect(on_bail)
		check.call(contained and e.wall_contacts>0 and bails[0]==0 and game.skater.is_on_floor()
			and game.skater.global_position.distance_to(stopped)>2.0 and e.hidden==0 and e.blocked==0 and e.close==0,
			"playability: %s physically blocks an off-line exit and permits a natural turn back" % fixture.label)
		print("PLAYABILITY EDGE ",fixture.label," contained=",contained," bails=",bails[0]," ",e)
	var canvas_supported:=true
	for x in [108.0,120.0]:
		for z in [2.0,13.0]:
			var hit:=_ray(game,Vector3(x,4,z),Vector3(x,2.5,z))
			if hit.is_empty() or absf(hit.position.y-3.27)>0.03 or hit.normal.y<0.99:canvas_supported=false
	check.call(canvas_supported,"playability: all four visible market canvas roofs have matching actual top collision")
	var pavilion_supported:=true
	for x in [-175.25,-172.75]:
		var hit:=_ray(game,Vector3(x,21,-182.5),Vector3(x,19,-182.5))
		if hit.is_empty() or absf(hit.position.y-20.17225)>0.03 or hit.normal.y<0.95:pavilion_supported=false
	check.call(pavilion_supported,"playability: both sloped pavilion roof faces have actual upward support at the visible height")


static func _check_visuals(game:Node,check:Callable) -> void:
	var rider:Node=game.skater.get_node("SkaterVisual/Rider")
	var board:Node=game.skater.get_node("SkaterVisual/Board")
	check.call(_mesh_ok(board,"CurvedMapleDeck") and rider.has_node("TorsoRig/Head")
		and _mesh_ok(rider,"SkinnedJacket") and _mesh_ok(rider,"SkinnedTrousers"),
		"playability visuals: board torso jacket and trousers actually exist and are visible")
	check.call(_mesh_ok(rider,"TorsoRig/Head/AnatomicalHead") and _mesh_ok(rider,"TorsoRig/Head/CroppedHair")
		and _mesh_ok(rider,"LeftAnatomicalHand/HandAndFingers") and _mesh_ok(rider,"RightAnatomicalHand/HandAndFingers"),
		"playability visuals: all four imported anatomical meshes built into the actual player rig")
	var mo:Node=game.encounters.get_node("MoBusker")
	check.call(_mesh_ok(mo,"Head/AnatomicalHead") and _mesh_ok(mo,"SkinnedJacket")
		and _mesh_ok(mo,"LeftAnatomicalHand/HandAndFingers") and _mesh_ok(mo,"RightAnatomicalHand/HandAndFingers"),
		"playability visuals: Mo's head clothing and hands finish construction before ordinary animation")
	var rae:Node=game.cat_encounter.get_node("RaeBinBusker/StreetDrummer")
	check.call(_mesh_ok(rae,"DrummerHead/AnatomicalHead") and _mesh_ok(rae,"SkinnedJacket")
		and _mesh_ok(rae,"LeftAnatomicalHand/HandAndFingers") and _mesh_ok(rae,"RightAnatomicalHand/HandAndFingers"),
		"playability visuals: Rae's actual drummer head clothing and both hands finish construction")
	var mairi:Node=game.market_encounter.get_node("MarketStallholder/MairiStallholder")
	check.call(_mesh_ok(mairi,"MairiHead/AnatomicalHead") and _mesh_ok(mairi,"SkinnedJacket")
		and _mesh_ok(mairi,"LeftAnatomicalHand/HandAndFingers") and _mesh_ok(mairi,"RightAnatomicalHand/HandAndFingers"),
		"playability visuals: Mairi's actual head clothing and both hands finish construction")


static func _mesh_ok(parent:Node,path:String) -> bool:
	var node:=parent.get_node_or_null(path) as MeshInstance3D
	return is_instance_valid(node) and is_instance_valid(node.mesh) and node.mesh.get_surface_count()>0 \
		and node.is_visible_in_tree() and node.global_position.is_finite() \
		and node.get_aabb().size.length()>0.01


static func camera_sample(game:Node) -> Dictionary:
	var camera:Camera3D=game.get_viewport().get_camera_3d()
	if not is_instance_valid(camera):return {"current":false,"finite":false,"full_body":false,"blocked":true,"distance":0.0}
	var body:Vector3=game.skater.global_position
	var chest:=body+Vector3.UP
	return {"current":camera.current,"finite":camera.global_position.is_finite(),
		"full_body":camera.is_position_in_frustum(body+Vector3.UP*0.12) and camera.is_position_in_frustum(body+Vector3.UP*1.8),
		"blocked":not _ray(game,chest,camera.global_position).is_empty(),
		"distance":camera.global_position.distance_to(chest)}


static func _evidence() -> Dictionary:
	return {"samples":0,"hidden":0,"blocked":0,"close":0,"nonfinite":0,"wall_contacts":0,"min_y":INF,"camera_min":INF,"distance":0.0,"previous":Vector3.INF}


static func _observe(tree:SceneTree,game:Node,count:int,e:Dictionary) -> void:
	for tick in count:
		await _frames(tree,1)
		var c:=camera_sample(game)
		e.samples+=1
		e.hidden+=int(not c.full_body)
		e.blocked+=int(c.blocked)
		e.close+=int(c.distance<2.0)
		e.nonfinite+=int(not c.finite or not c.current)
		e.camera_min=minf(e.camera_min,c.distance)
		e.min_y=minf(e.min_y,game.skater.global_position.y)
		for index in game.skater.get_slide_collision_count():
			if game.skater.get_slide_collision(index).get_normal().y<0.65:e.wall_contacts+=1
		if e.previous.is_finite():e.distance+=e.previous.distance_to(game.skater.global_position)
		e.previous=game.skater.global_position


static func _fixture(tree:SceneTree,game:Node,point:Vector3,heading:float) -> void:
	_release()
	game.skater.spawn_position=point
	game.start_mode(true)
	game.skater.rotation.y=heading
	await _frames(tree,45)


static func _ray(game:Node,a:Vector3,b:Vector3) -> Dictionary:
	return game.skater.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1))


static func _activate(tree:SceneTree,hud:Node,prefix:String) -> void:
	var button:=_button(hud,prefix)
	if button==null:
		push_error("Playability could not find visible control "+prefix)
		return
	button.grab_focus()
	await _frames(tree,2)
	await _tap(tree,KEY_ENTER)


static func _button(node:Node,prefix:String) -> Button:
	if node is Button and node.visible and node.text.trim_prefix("✓  ").begins_with(prefix):return node
	for child in node.get_children():
		var found:=_button(child,prefix)
		if found!=null:return found
	return null


static func _tap(tree:SceneTree,key:Key) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new()
		event.physical_keycode=key
		event.keycode=key
		event.pressed=down
		Input.parse_input_event(event)
		await _frames(tree,1 if down else 2)


static func _release() -> void:
	for action in InputMap.get_actions():Input.action_release(action)


static func _frames(tree:SceneTree,count:int) -> void:
	for tick in count:
		await tree.physics_frame
		await tree.process_frame
