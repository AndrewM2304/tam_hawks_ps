extends RefCounted
## Existing visual beams, independent fixed cable coordinates, actual native
## crowns and rigid truck contacts. This is not a human combo-feel assertion.

const Cable = preload("res://game/levels/clyde_cable_line.gd")
const Landmarks = preload("res://game/levels/art/clyde_landmarks.gd")
const Style = preload("res://game/tricks/grind_style.gd")
const StaticBatches = preload("res://game/levels/static_batches.gd")

class Fixture extends Node3D:
	var _materials: Dictionary = {}


static func run(tree: SceneTree, check: Callable) -> void:
	# A private native World3D removes cross-test geometry while preserving the
	# authored-coordinate precision required by the rigid two-truck solver.
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(16,16)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var world := Fixture.new()
	world.name = "CableNativeFixture"
	for key: String in ["iron","sandstone","cut_stone","slate","window_frame","window_shadow","window_dull","wood","glass"]:
		world._materials[key] = StandardMaterial3D.new()
	viewport.add_child(world)
	var outdoors := Node3D.new()
	outdoors.name = "OutdoorRoutes"
	world.add_child(outdoors)
	Landmarks.build(outdoors,world._materials)
	var art: MultiMeshInstance3D = outdoors.get_node("ClydeLandmarks/Clyde_box_clyde_red")
	var before := StaticBatches.authored_transforms(art)
	var mesh_count: int = world.find_children("*","MeshInstance3D",true,false).size()
	var batch_count: int = world.find_children("*","MultiMeshInstance3D",true,false).size()
	var cable := Cable.new()
	cable.build(world)
	await tree.physics_frame
	await tree.physics_frame
	var lines := cable.get_grind_lines()
	check.call(lines.size()==2 and cable.find_children("*","CollisionShape3D",true,false).size()==16
		and before==StaticBatches.authored_transforms(art)
		and world.find_children("*","MeshInstance3D",true,false).size()==mesh_count
		and world.find_children("*","MultiMeshInstance3D",true,false).size()==batch_count,
		"PT24-25: native backing copies sixteen existing cable facets without a new draw or changing red bridge art")
	var native: StaticBody3D = cable.get_node("ExistingCableNativeCrowns")
	check.call(native.collision_layer==(1|2) and native.collision_mask==0,
		"PT24-25: existing cable backing is solid to the rider and retains authored rail queries")
	var space := world.get_world_3d().direct_space_state
	var crowns_supported := true
	var trucks_supported := true
	var rigid := Style.ContactPose.new()
	var max_gap := 0.0
	for line in lines:
		var expected_x := -29.35 if line.id=="clyde_cable_west" else -20.65
		check.call(line.contact_verified and line.contact_normal_offset==0.0
			and absf(world.to_local(line.points[0]).x-expected_x)<0.001
			and absf(world.to_local(line.points[0]).z-90.75)<0.001 and absf(world.to_local(line.points[-1]).z-103.25)<0.001
			and line.length>12.5 and line.length<12.7,
			"PT24-25: finite actual crown stays on the reachable central existing strand "+line.id)
		for step: int in range(1,64):
			var distance: float = line.length*float(step)/64.0
			var point: Vector3 = line.contact_at(distance)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.05,point-Vector3.UP*0.1,2))
			crowns_supported = crowns_supported and not hit.is_empty()
			if not hit.is_empty():
				max_gap = maxf(max_gap,absf(hit.position.y-point.y))
				crowns_supported = crowns_supported and absf(hit.position.y-point.y)<0.002
			if distance<0.35 or distance>line.length-0.35: continue
			for direction: float in [-1.0,1.0]:
				var solved := Style.solve_into(rigid,line,distance,direction,0.0,"grind_50_50",0.0)
				trucks_supported = trucks_supported and solved
				if not solved: continue
				for contact: int in rigid.anchor_count:
					var support: Vector3 = rigid.supports[contact]
					var actual := space.intersect_ray(PhysicsRayQueryParameters3D.create(support+Vector3.UP*0.05,support-Vector3.UP*0.1,2))
					trucks_supported = trucks_supported and not actual.is_empty() and absf(actual.position.y-support.y)<0.002
	check.call(crowns_supported,"PT24-25: 126 independent crown rays hit real cable backing; max gap="+str(max_gap))
	check.call(trucks_supported,"PT24-25: both directions keep rigid native two-truck supports through the changing cable grade")
	var transfers := cable.get_gap_definitions()
	var reach := transfers.size()==4
	for gap: Dictionary in transfers:
		var start: Vector3 = gap.start
		var finish: Vector3 = gap.end
		reach = reach and gap.airborne_required and start.distance_to(finish)<3.2 \
			and absf(start.x-finish.x)<0.51 and absf(start.y-finish.y)<0.7
	check.call(reach,"PT24-25: optional handrail/cable air entries and returns have bounded real offsets without physics boosts")
	var retained := true
	for x: float in [-29.0,-25.0,-21.0]:
		for z: float in [91.0,97.0,103.0]:
			retained = retained and space.intersect_ray(PhysicsRayQueryParameters3D.create(world.to_global(Vector3(x,5,z)),world.to_global(Vector3(x,2,z)),2)).is_empty()
	check.call(retained,"PT24-25: all nine fixed ordinary bridge-corridor columns remain clear of the cable extension")
	viewport.queue_free()
	await tree.process_frame


static func run_player(tree: SceneTree, game: Node, check: Callable, observer: Callable = Callable()) -> void:
	var candidate: Node3D = game.world.find_child("ClydeCableContacts",true,false)
	check.call(candidate!=null,"PT24-25 input: cable acceptance uses the explicitly installed Main candidate")
	if candidate==null: return
	var old_spawn: Vector3 = game.skater.spawn_position
	var old_free: bool = game.free_skate_mode
	for direction: float in [1.0,-1.0]:
		await _drive_player(tree,game,check,direction,observer)
	_release()
	game.skater.spawn_position = old_spawn
	game.start_mode(old_free)


static func _drive_player(tree: SceneTree, game: Node, check: Callable, direction: float, observer: Callable) -> void:
	_release()
	var start := Vector3(-28.1,0.0,85.0 if direction>0.0 else 109.0)
	start.y = game.world.get_ground_height(start)+0.08
	game.skater.spawn_position = start
	game.start_mode(true)
	# Initial declared orientation only. Every later metre, speed, direction,
	# catch, contact and award follows the real mapped inputs and native motion.
	game.skater.rotation.y = PI if direction>0.0 else 0.0
	var evidence := {"captures":[],"bails":0,"banks":0,"last_score":0,"phase":"settle",
		"ticks":0,"cable_ticks":0,"max_cable_gap":0.0,"stages":[]}
	var on_capture := func(id: String): evidence.captures.append(id)
	var on_bail := func(): evidence.bails+=1
	game.skater.grind_captured.connect(on_capture)
	game.skater.bailed.connect(on_bail)
	await _input_frames(tree,game,evidence,5,"settle",observer)
	Input.action_press("push")
	await _input_frames(tree,game,evidence,30,"push_on_bridge",observer)
	Input.action_press("ollie")
	await _input_frames(tree,game,evidence,16,"charge_to_handrail",observer)
	Input.action_release("ollie")
	Input.action_press("grind")
	var first := await _wait_capture(tree,game,evidence,"Grind_Edge_BridgeRail_x-2885y445z9700_0",100,"first_handrail",observer)
	if first:
		await _input_frames(tree,game,evidence,8,"handrail_run",observer)
		Input.action_press("ollie")
		await _input_frames(tree,game,evidence,16,"charge_to_cable",observer)
		_set_steer(direction*0.55)
		Input.action_release("ollie")
		await _input_frames(tree,game,evidence,1,"leave_handrail",observer)
		_set_steer(0.0)
		Input.action_release("grind")
		await _input_frames(tree,game,evidence,1,"fresh_cable_request",observer)
		Input.action_press("grind")
	var cable := false
	if first: cable = await _wait_capture(tree,game,evidence,"clyde_cable_west",100,"cable_air_catch",observer)
	if cable:
		Input.action_press("ollie")
		await _input_frames(tree,game,evidence,16,"charge_from_cable",observer)
		_set_steer(-direction*0.55)
		Input.action_release("ollie")
		await _input_frames(tree,game,evidence,1,"leave_cable",observer)
		_set_steer(0.0)
		Input.action_release("grind")
		await _input_frames(tree,game,evidence,1,"fresh_return_request",observer)
		Input.action_press("grind")
	var returned := false
	if cable: returned = await _wait_capture(tree,game,evidence,"Grind_Edge_BridgeRail_x-2885y445z9700_0",100,"return_handrail",observer)
	if returned:
		Input.action_press("ollie")
		await _input_frames(tree,game,evidence,2,"short_dry_exit_charge",observer)
		_set_steer(-direction)
		Input.action_release("ollie")
		await _input_frames(tree,game,evidence,1,"exit_to_deck",observer)
		_release()
		for frame: int in 140:
			await _input_frames(tree,game,evidence,1,"dry_landing_and_bank",observer)
			if game.score.total_score>0 and game.skater.is_on_floor() and not game.skater.airborne: break
		await _input_frames(tree,game,evidence,24,"single_bank_observation",observer)
	_release()
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.bailed.disconnect(on_bail)
	print("CABLE_INPUT_RESULT ",JSON.stringify({"direction":direction,"first":first,"cable":cable,
		"returned":returned,"captures":evidence.captures,"bails":evidence.bails,
		"banks":evidence.banks,"bank":game.score.total_score,"ticks":evidence.ticks,
		"cable_ticks":evidence.cable_ticks,"max_cable_gap":evidence.max_cable_gap,
		"position":var_to_str(game.skater.global_position),"stages":evidence.stages}))
	check.call(first and cable and returned and evidence.captures==[
		"Grind_Edge_BridgeRail_x-2885y445z9700_0","clyde_cable_west","Grind_Edge_BridgeRail_x-2885y445z9700_0"]
		and evidence.cable_ticks>=8 and evidence.bails==0 and evidence.banks==1
		and game.score.total_score>0 and game.skater.is_on_floor() and not game.skater.airborne,
		"PT24-25 input: native bridge→handrail→air→cable→air→handrail→dry deck earns one clean combo, direction="+str(direction))


static func _wait_capture(tree: SceneTree, game: Node, evidence: Dictionary, id: String,
		limit: int, stage: String, observer: Callable) -> bool:
	for frame: int in limit:
		await _input_frames(tree,game,evidence,1,stage,observer)
		if game.skater.grinding and game.skater._grind.line.id==id: return true
		if game.skater.bailing: return false
	return false


static func _input_frames(tree: SceneTree, game: Node, evidence: Dictionary, count: int,
		stage: String, observer: Callable) -> void:
	for frame: int in count:
		await tree.physics_frame
		await tree.process_frame
		evidence.ticks+=1
		if stage!=evidence.phase:
			evidence.phase=stage
			evidence.stages.append({"stage":stage,"at":var_to_str(game.skater.global_position),
				"speed":game.skater.speed,"y_velocity":game.skater.velocity.y})
		if game.score.total_score!=evidence.last_score:
			evidence.banks+=1
			evidence.last_score=game.score.total_score
		if game.skater.grinding and game.skater._grind.line.id=="clyde_cable_west":
			evidence.cable_ticks+=1
			evidence.max_cable_gap=maxf(evidence.max_cable_gap,
				game.skater.global_position.distance_to(game.skater._grind.position()))
		if observer.is_valid(): await observer.call(stage,game,evidence.ticks)


static func _set_steer(amount: float) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if amount<0.0: Input.action_press("steer_left",-amount)
	if amount>0.0: Input.action_press("steer_right",amount)


static func _release() -> void:
	for action: String in ["push","brake","steer_left","steer_right","ollie","grind","manual","flip","grab"]:
		Input.action_release(action)
