extends RefCounted
## Independent native fixture: excavation must remove real support, the water
## edge must meet its bank, and every claimed truck support must hit steel.

const Pond = preload("res://game/levels/park_pond.gd")
const Surface = preload("res://game/levels/outdoors/surface_builder.gd")
const Style = preload("res://game/tricks/grind_style.gd")

class Fixture extends Node3D:
	var _materials: Dictionary = {}


static func run(tree: SceneTree, check: Callable) -> void:
	# Isolate native collision without translating authored contact coordinates
	# into the lower-precision, far-away range of the float32 physics world.
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(16,16)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var world := Fixture.new()
	world.name = "PondNativeFixture"
	for key: String in ["cut_stone","iron","stone_light","bronze","orange"]:
		world._materials[key] = StandardMaterial3D.new()
	viewport.add_child(world)
	var outdoors := Node3D.new()
	outdoors.name = "OutdoorRoutes"
	world.add_child(outdoors)
	Surface.terrain(outdoors,"KelvingroveCentralEmbankment",Rect2(-205,-45,55,50),2.5,
		func(_x: float,_z: float) -> float: return 0.5,world._materials.cut_stone)
	var water := MeshInstance3D.new()
	water.name = "ClydeWater"
	water.mesh = PlaneMesh.new()
	water.material_override = StandardMaterial3D.new()
	water.visible = false
	outdoors.add_child(water)
	var pond := Pond.new()
	pond.build(world)
	await tree.physics_frame
	await tree.physics_frame
	var space := world.get_world_3d().direct_space_state
	var centre := world.to_global(Vector3(-184,0,-21))
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(centre+Vector3.UP*3,centre-Vector3.UP*3,1))
	check.call(not hit.is_empty() and absf(hit.position.y+0.85)<0.001
		and hit.collider.name=="PondExcavatedBank",
		"PT24-16: independent centre ray reaches recessed native basin; old lawn is physically excavated")
	var support_matches := true
	var shore_matches := true
	var recoveries_clear := true
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	for step: int in 32:
		var angle := float(step)/32.0*TAU
		for radial: float in [0.3,0.65,0.9,1.0]:
			var at := world.to_global(Vector3(-184+10*cos(angle)*radial,0,-21+8*sin(angle)*radial))
			var expected: float = pond.get_ground_height(at)
			var ray := space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*3,at-Vector3.UP*3,1))
			support_matches = support_matches and is_finite(expected) and not ray.is_empty() and absf(ray.position.y-expected)<0.002
		var shore := world.to_global(Vector3(-184+8*cos(angle),0.12,-21+6*sin(angle)))
		shore_matches = shore_matches and absf(pond.get_ground_height(shore)-0.12)<0.002
		var wet := world.to_global(Vector3(-184+7.6*cos(angle),0.13,-21+5.6*sin(angle)))
		var recovery: Vector3 = pond.get_recovery_position(wet)
		var native := space.intersect_ray(PhysicsRayQueryParameters3D.create(recovery,recovery-Vector3.UP*2,1))
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.collision_mask = 1
		query.margin = 0.001
		query.transform = Transform3D(Basis.IDENTITY,Vector3(recovery.x,1.38,recovery.z))
		recoveries_clear = recoveries_clear and recovery.is_finite() and not native.is_empty() \
			and absf(native.position.y-0.5)<0.002 and space.intersect_shape(query).is_empty()
	check.call(support_matches,"PT24-16: 128 radial native support probes agree with the exact basin query")
	check.call(shore_matches,"PT24-16: all 32 shoreline corners meet the visible water plane without an underwater dry gap")
	check.call(recoveries_clear,"PT24-16: every sampled water bank returns to supported clear dry lawn")
	check.call(not pond.get_recovery_position(world.to_global(Vector3(-184,1.1,-21))).is_finite()
		and not pond.get_recovery_position(world.to_global(Vector3(-173,0.5,-21))).is_finite()
		and not is_finite(pond.get_ground_height(world.to_global(Vector3(-170,0.5,-21)))),
		"PT24-16: high air and dry bypass do not trigger water recovery or replace unrelated ground queries")
	var bypass := true
	for step: int in 29:
		var at := world.to_global(Vector3(-169,0.5,-35+step))
		var ray := space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.2,at-Vector3.UP*0.2,1))
		bypass = bypass and not ray.is_empty() and absf(ray.position.y-0.5)<0.001
	check.call(bypass,"PT24-16: the independent 28m dry bypass keeps its original native lawn support")
	var line = pond.get_grind_lines()[0]
	var steel := true
	var trucks := true
	var pose := Style.ContactPose.new()
	for step: int in 64:
		var distance: float = line.length*float(step)/64.0
		var support: Vector3 = line.contact_at(distance)
		var ray := space.intersect_ray(PhysicsRayQueryParameters3D.create(support+Vector3.UP*0.05,support-Vector3.UP*0.1,2))
		steel = steel and not ray.is_empty() and absf(ray.position.y-support.y)<0.002
		var solved := Style.solve_into(pose,line,distance,1.0,0.0,"grind_50_50",0.0)
		trucks = trucks and solved
		if not solved: continue
		for contact: int in pose.anchor_count:
			var point: Vector3 = pose.supports[contact]
			var native := space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.05,point-Vector3.UP*0.1,2))
			trucks = trucks and not native.is_empty() and absf(native.position.y-point.y)<0.002
	check.call(line.is_loop and line.contact_verified and line.length>50 and steel and trucks,
		"PT24-16: the closed pond rail supplies actual steel and rigid two-truck contact around its complete loop")
	var visual: MeshInstance3D = pond.get_node("PondWater")
	var upward := true
	var faces := visual.mesh.get_faces()
	for index: int in range(0,faces.size(),3):
		upward = upward and (faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).y<0
	check.call(upward and visual.material_override==water.material_override
		and pond.get_node("PondDuckBodies").multimesh.instance_count==2
		and pond.get_node("PondDuckHeads").multimesh.instance_count==2,
		"PT24-16: upward visible water reuses the resident shader and two original ducks use shared static batches")
	check.call(pond.find_children("*","StaticBody3D",true,false).size()==2
		and pond.find_children("*","CollisionShape3D",true,false).size()==41,
		"PT24-16: candidate stays within its two-body / 41-shape construction budget")
	viewport.queue_free()
	await tree.process_frame


static func run_installed(tree: SceneTree, game: Node, check: Callable) -> void:
	var pond: Node3D = game.world.find_child("KelvingrovePond",true,false)
	check.call(pond!=null,"PT24-16 installed: the explicitly admitted candidate has its real pond")
	if pond==null: return
	var old_spawn: Vector3 = game.skater.spawn_position
	var old_free: bool = game.free_skate_mode
	game.skater.spawn_position = pond.to_global(Vector3(-171,0.58,-21))
	game.start_mode(true)
	game.skater.rotation.y = PI*0.5
	var entries := [0]
	var on_bail := func(): entries[0]+=1
	game.skater.bailed.connect(on_bail)
	Input.action_press("push")
	var entered := false
	var recovered := false
	for tick: int in 420:
		if game.skater.bailing:
			entered = true
			Input.action_release("push")
		if entered and not game.skater.bailing and game.skater.is_on_floor():
			recovered = true
			break
		await tree.physics_frame
		await tree.process_frame
	Input.action_release("push")
	game.skater.bailed.disconnect(on_bail)
	check.call(entered and recovered and entries[0]==1
		and not pond.get_recovery_position(game.skater.global_position).is_finite(),
		"PT24-16 installed: ordinary Push enters the pond, triggers one existing dramatic bail, and recovers on dry land")
	game.skater.spawn_position = old_spawn
	game.start_mode(old_free)


static func run_player(tree: SceneTree, game: Node, check: Callable, observer: Callable = Callable()) -> void:
	var pond: Node3D = game.world.find_child("KelvingrovePond",true,false)
	check.call(pond!=null,"PT24-16 input: actual Main explicitly installs the pond candidate")
	if pond==null: return
	var old_spawn: Vector3 = game.skater.spawn_position
	var old_free: bool = game.free_skate_mode
	for direction: float in [1.0,-1.0]:
		await _drive_pond(tree,game,pond,check,direction,observer)
	_release()
	game.skater.spawn_position = old_spawn
	game.start_mode(old_free)


static func _drive_pond(tree: SceneTree, game: Node, pond: Node3D, check: Callable,
		direction: float, observer: Callable) -> void:
	_release()
	game.skater.spawn_position = pond.to_global(Vector3(-173.65,0.58,-26 if direction>0.0 else -16))
	game.start_mode(true)
	# This is the sole initial facing assignment. Subsequent motion, catches,
	# curve heading, landing, manual, bail and score are ordinary runtime results.
	game.skater.rotation.y = PI if direction>0.0 else 0.0
	var evidence := {"phase":"settle","ticks":0,"captures":[],"bails":0,
		"banks":0,"last_score":0,"rail_ticks":0,"manual_ticks":0,"stages":[]}
	var on_capture := func(id: String): evidence.captures.append(id)
	var on_bail := func(): evidence.bails+=1
	game.skater.grind_captured.connect(on_capture)
	game.skater.bailed.connect(on_bail)
	await _input_frames(tree,game,evidence,5,"settle",observer)
	Input.action_press("push")
	await _input_frames(tree,game,evidence,30,"dry_tangent_push",observer)
	Input.action_press("ollie")
	await _input_frames(tree,game,evidence,16,"charge_to_perimeter",observer)
	Input.action_release("ollie")
	Input.action_press("grind")
	var caught := false
	for frame: int in 100:
		await _input_frames(tree,game,evidence,1,"perimeter_air_catch",observer)
		if game.skater.grinding and game.skater._grind.line.id=="kelvingrove_pond_perimeter":
			caught = true
			break
		if game.skater.bailing: break
	if caught:
		await _input_frames(tree,game,evidence,24,"ride_perimeter",observer)
		Input.action_press("ollie")
		await _input_frames(tree,game,evidence,2,"dry_exit_charge",observer)
		_set_steer(-direction)
		Input.action_release("ollie")
		await _input_frames(tree,game,evidence,1,"outward_ollie",observer)
		_release()
		var manual_requested := false
		for frame: int in 120:
			# Buffer an actual manual near the descending landing, then hold a
			# short flatland continuation. No contact or manual state is injected.
			if not manual_requested and game.skater.velocity.y<0.0 and game.skater.global_position.y<1.05:
				manual_requested = true
				Input.action_press("manual")
			await _input_frames(tree,game,evidence,1,"dry_landing_manual",observer)
			if evidence.manual_ticks>=12: break
			if game.skater.bailing: break
		Input.action_release("manual")
		for frame: int in 90:
			await _input_frames(tree,game,evidence,1,"clean_bank",observer)
			if game.score.total_score>0 and game.skater.is_on_floor() and not game.skater.airborne: break
		await _input_frames(tree,game,evidence,24,"single_bank_observation",observer)
	_release()
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.bailed.disconnect(on_bail)
	var accepted: bool = caught and evidence.captures==["kelvingrove_pond_perimeter"] \
		and evidence.rail_ticks>=24 and evidence.manual_ticks>=12 and evidence.bails==0 \
		and evidence.banks==1 and game.score.total_score>0 and game.skater.is_on_floor()
	print("POND_INPUT_RESULT ",JSON.stringify({"direction":direction,"accepted":accepted,
		"captures":evidence.captures,"rail_ticks":evidence.rail_ticks,"manual_ticks":evidence.manual_ticks,
		"bails":evidence.bails,"banks":evidence.banks,"bank":game.score.total_score,
		"position":var_to_str(game.skater.global_position),"ticks":evidence.ticks,"stages":evidence.stages}))
	check.call(accepted,"PT24-16 input: dry lawn→Ollie→perimeter rail→outward Ollie→dry Manual earns one clean bank, direction="+str(direction))
	if accepted and direction>0.0:
		await _water_with_banked_score(tree,game,pond,check)


static func _water_with_banked_score(tree: SceneTree, game: Node, pond: Node3D, check: Callable) -> void:
	var banked: int = game.score.total_score
	var bails := [0]
	var on_bail := func(): bails[0]+=1
	game.skater.bailed.connect(on_bail)
	var entered := false
	var recovered := false
	# Turn and drive back from the actual clean landing. This uses ordinary
	# steering/braking; there is no second placement or fabricated bank value.
	for frame: int in 600:
		if game.skater.bailing:
			entered = true
			_release()
		elif entered and game.skater.is_on_floor():
			recovered = true
			break
		else:
			var target: Vector3 = pond.to_global(Vector3(-184,0.12,-21))-game.skater.global_position
			var desired := atan2(-target.x,-target.z)
			var error := angle_difference(game.skater.rotation.y,desired)
			_set_steer(-clampf(error/0.7,-1.0,1.0))
			Input.action_release("push")
			Input.action_release("brake")
			if absf(error)>0.5:
				Input.action_press("brake")
			elif game.skater.speed>4.0:
				Input.action_press("brake",0.25)
			else:
				Input.action_press("push",0.35)
		await tree.physics_frame
		await tree.process_frame
	_release()
	game.skater.bailed.disconnect(on_bail)
	check.call(banked>0 and entered and recovered and bails[0]==1
		and game.score.total_score==banked and not pond.get_recovery_position(game.skater.global_position).is_finite(),
		"PT24-16 input: earned pond combo survives an actual later water bail and supported recovery unchanged")
	print("POND_BANKED_WATER_RESULT ",JSON.stringify({"bank_before":banked,"bank_after":game.score.total_score,
		"entered":entered,"recovered":recovered,"bails":bails[0],"position":var_to_str(game.skater.global_position)}))


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
		if game.skater.grinding and game.skater._grind.line.id=="kelvingrove_pond_perimeter": evidence.rail_ticks+=1
		if game.skater.manual_active: evidence.manual_ticks+=1
		if observer.is_valid(): await observer.call(stage,game,evidence.ticks)


static func _set_steer(amount: float) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if amount<0.0: Input.action_press("steer_left",-amount)
	if amount>0.0: Input.action_press("steer_right",amount)


static func _release() -> void:
	for action: String in ["push","brake","steer_left","steer_right","ollie","grind","manual","flip","grab"]:
		Input.action_release(action)
