extends RefCounted
## C04-L05: ordinary safe-bridge travel continues through its landing into a
## real flatland/ledge combo. Only the initial spawn and facing are fixtures.

const Density = preload("res://tests/full_level_density_tests.gd")
const Surfaces = preload("res://tests/surface_coverage_tests.gd")
const BoardGeometry = preload("res://tests/board_geometry_tests_support.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const LEDGE := "Grind_Ledge_clyde_south_return"
const TURN_Z := 118.5
const APPROACH := Vector3(-31.5,2.0,129.9)


class BankSampler extends Node:
	var game: Node
	var active := false
	var samples := 0
	var camera_clear := true
	var support_finite := true
	var bowl_samples := 0
	var minimum_y := INF
	var warmup_frames := 30
	var last_state: Dictionary = {}
	func _ready() -> void:
		process_priority = 100
	func _process(_delta: float) -> void:
		if not active or not is_instance_valid(game): return
		if warmup_frames>0:
			warmup_frames-=1
			return
		var rider: CharacterBody3D = game.skater
		var at := rider.global_position
		var inputs: Dictionary = {}
		for action: String in ["push","brake","steer_left","steer_right","ollie","grind","manual"]:
			if Input.is_action_pressed(action): inputs[action]=Input.get_action_strength(action)
		last_state={"at":var_to_str(at),"velocity":var_to_str(rider.velocity),
			"airborne":rider.airborne,"floor":rider.is_on_floor(),"spin":rider._air_spin,
			"feature_state":rider._feature_transition.state,"inputs":inputs}
		minimum_y = minf(minimum_y,at.y)
		support_finite = support_finite and is_finite(game.world.get_ground_height(at))
		if Vector2(at.x+7,at.z-134.5).length()<7.7: bowl_samples+=1
		# Sample every completed presentation frame. Absolute physics-frame
		# modulo sampling concealed the last airborne tyre contact in one prefix.
		samples+=1
		var clear := Density._camera_clear(game)
		if not clear and camera_clear: _contact_failure(game,last_state)
		camera_clear = clear and camera_clear
	func _contact_failure(current: Node,state: Dictionary) -> void:
		var rider: CharacterBody3D=current.skater
		var rig: RefCounted=rider._visual_rig
		var entries: Array[Dictionary]=[{"kind":"head","at":rig._head.global_position},
			{"kind":"board_origin","at":rider._board_visual.global_position}]
		for mesh: MeshInstance3D in BoardGeometry.visible_meshes(rig):
			var hull: ConvexPolygonShape3D=mesh.mesh.create_convex_shape(true,false)
			for point: Vector3 in hull.points:
				entries.append({"kind":"mesh","mesh":str(mesh.get_path()),"local":point,
					"at":mesh.to_global(point),"interpolated_at":mesh.get_global_transform_interpolated()*point})
		for leg: Dictionary in rig._legs:
			for endpoint: Vector3 in [Footwear.SOLE_CONTACT,Footwear.TOE_CONTACT]:
				entries.append({"kind":"foot","side":leg.side,"local":endpoint,
					"at":leg.foot.to_global(endpoint)})
		var space:=rider.get_world_3d().direct_space_state
		var failure: Dictionary={}
		for entry: Dictionary in entries:
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(rider._camera.global_position,entry.at,1|8,[rider.get_rid()]))
			if not hit.is_empty():
				failure=entry.duplicate()
				failure.merge({"hit":hit.position,"normal":hit.normal,
					"collider":hit.collider.get_meta("art_label",str(hit.collider.name)),
					"gap":(Vector3(entry.at)-Vector3(hit.position)).dot(hit.normal)})
				break
		var rims: Array[Dictionary]=[]
		var component:=-1
		var nearest:=INF
		var wheel_index:=0
		for wheel: Dictionary in rig.board_contact_geometry().wheels:
			var minimum:=INF
			var support: Dictionary={}
			for point: Vector3 in wheel.points:
				var at: Vector3=rider._board_visual.to_global(point)
				if failure.has("at") and at.distance_squared_to(failure.at)<nearest:
					nearest=at.distance_squared_to(failure.at);component=wheel_index
				var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.35,1|8,[rider.get_rid()]))
				if hit.is_empty(): continue
				var gap: float=(at-Vector3(hit.position)).dot(hit.normal)
				if gap<minimum:
					minimum=gap
					support={"at":at,"hit":hit.position,"normal":hit.normal,
						"collider":hit.collider.get_meta("art_label",str(hit.collider.name))}
			rims.append({"wheel":wheel_index,"minimum_gap":minimum,"support":support})
			wheel_index+=1
		print("CLYDE_RETURN_FIRST_CONTACT_FAILURE ",JSON.stringify({"state":state,
			"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),
			"camera_process_frame":rider.last_presentation_process_frame,"fraction":Engine.get_physics_interpolation_fraction(),
			"native_valid":rider._native_floor_valid,"force_air":rider._force_air_tick,
			"transition":rider.transition_active,"native_normal":rider._native_floor_normal(),
			"board_pitch":rider._board_visual.rotation.x,"board_frame":rider._board_visual.global_transform,
			"board_interpolated":rider._board_visual.get_global_transform_interpolated(),
			"visual_frame":rider._visual.global_transform,"body_frame":rider.global_transform,
			"air_support":rider._air_support_basis,"failure":failure,"rims":rims,
			"nearest_tyre":component,"tyre_vertex_error":sqrt(nearest)}))


static func run(tree: SceneTree, game: Node, check: Callable, observer: Callable = Callable()) -> void:
	await _construction(tree,game,check)
	await run_player(tree,game,check,observer)
	await run_bank_return(tree,game,check)


static func _construction(tree: SceneTree, game: Node, check: Callable) -> void:
	await tree.physics_frame
	var world: Node3D = game.world
	var line = null
	for track in world.get_grind_lines():
		if track.id==LEDGE: line=track
	check.call(line!=null and line.contact_verified
		and line.points[0].distance_to(Vector3(-32.2,2.6,131))<0.002
		and line.points[-1].distance_to(Vector3(-32.2,2.6,138))<0.002,
		"C04-L05: bridge-arrival continuation uses the real relocated west quay bearing")
	var support := true
	var clear := true
	var space := world.get_world_3d().direct_space_state
	# These independent fixed witness positions include the actual bridge,
	# south landfall, manual turn/apron and protected east/west bypass lane.
	for point: Vector3 in [Vector3(-25,2,69),Vector3(-25,2,72),Vector3(-25,3.4,89),
		Vector3(-25,3.4,97),Vector3(-25,3.4,105),Vector3(-25,2,122),
		Vector3(-27,2,123),Vector3(-29,2,126),Vector3(-29.5,2,126.8),Vector3(-31.5,2,129.9),
		Vector3(-36,2,124),Vector3(-30,2,124),Vector3(-15,2,124),Vector3(0,2,124)]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.15,point-Vector3.UP*0.15,1))
		support = support and not hit.is_empty() and absf(hit.position.y-point.y)<0.002
		clear = clear and Surfaces._clear_capture(world,point,point)
	check.call(support and clear,"C04-L05: fixed bridge/landing/manual envelopes and the safe cross-quay bypass retain clear native support")
	var bank_return := true
	var registered_lines: Dictionary = {}
	for track in world.get_grind_lines(): registered_lines[str(track.id)]=track
	var terrain_steel: Dictionary = {"lines":registered_lines,"seen":{},"known":{},"valid":true}
	for point: Vector3 in [Vector3(-32.5,2,139.5),Vector3(-28.5,2,140),
		Vector3(-27,2.2057143,140),Vector3(-25,2.48,140),Vector3(-22,2.48,140),
		Vector3(-19,2.48,140),Vector3(-17,2.2057143,140),Vector3(-15.5,2,140),
		Vector3(-11.5,2,139.5)]:
		# Match the terrain-only public height query after independently proving
		# each intervening steel RID on its native rail layer at this exact site.
		var hit := Surfaces._terrain_ray(world,point+Vector3.UP*0.15,point-Vector3.UP*0.15,terrain_steel)
		bank_return = bank_return and not hit.is_empty() and absf(hit.position.y-point.y)<0.002 \
			and absf(world.get_ground_height(point)-point.y)<0.002 and Surfaces._clear_capture(world,point,point)
	check.call(bank_return and terrain_steel.valid and not terrain_steel.seen.is_empty(),
		"C04-L05: the reused east-west bank keeps its actual graded Z140 return and a supported bowl-deck endpoint")


static func run_player(tree: SceneTree, game: Node, check: Callable, observer: Callable = Callable()) -> void:
	var old_spawn: Vector3 = game.skater.spawn_position
	var old_free: bool = game.free_skate_mode
	_release()
	game.skater.spawn_position = Vector3(-25,2.08,67)
	game.start_mode(true)
	game.skater.rotation.y = PI
	var evidence := {"phase":"settle","ticks":0,"bails":0,"captures":[],
		"banks":0,"last_score":0,"manual_ticks":0,"ledge_ticks":0,
		"bridge_samples":0,"bridge_supported":true,"camera_samples":0,"camera_clear":true,
		"manual_start":Vector3.INF,"stages":[]}
	var on_bail := func(): evidence.bails+=1
	var on_capture := func(id: String): evidence.captures.append(id)
	game.skater.bailed.connect(on_bail)
	game.skater.grind_captured.connect(on_capture)
	await _frames(tree,game,evidence,40,"settle",observer)
	var crossed := false
	for frame: int in 600:
		_speed(game,6.5)
		_set_steer(0.0)
		await _frames(tree,game,evidence,1,"safe_bridge_crossing",observer)
		if game.skater.global_position.z>=TURN_Z:
			crossed = true
			break
		if game.skater.bailing: break
	var aligned := false
	if crossed:
		# Turn on the bridge's broad southern approach, before entering the
		# manual. Its actual diagonal continues over the Z122 landfall.
		for frame: int in 60:
			_speed(game,6.5)
			var offset: Vector3 = APPROACH-game.skater.global_position
			var desired := atan2(-offset.x,-offset.z)
			var error := angle_difference(game.skater.rotation.y,desired)
			_set_steer(-clampf(error*3.0,-1.0,1.0))
			await _frames(tree,game,evidence,1,"bridge_landing_turn",observer)
			if absf(error)<0.03:
				aligned = true
				break
	var manual := false
	if aligned:
		Input.action_press("manual")
		for frame: int in 180:
			_speed(game,6.5)
			var offset: Vector3 = APPROACH-game.skater.global_position
			var error := angle_difference(game.skater.rotation.y,atan2(-offset.x,-offset.z))
			_set_steer(-clampf(error*2.0,-0.35,0.35))
			await _frames(tree,game,evidence,1,"manual_over_landfall",observer)
			if game.skater.manual_active:
				manual = true
				if not evidence.manual_start.is_finite(): evidence.manual_start=game.skater.global_position
			if game.skater.global_position.z>=APPROACH.z: break
			if game.skater.bailing or game.score.total_score>0: break
	var caught := false
	if manual and not game.skater.bailing:
		_set_steer(0.0)
		Input.action_press("ollie")
		await _frames(tree,game,evidence,2,"manual_to_ledge_pop",observer)
		Input.action_release("ollie")
		Input.action_release("manual")
		Input.action_release("push")
		Input.action_release("brake")
		Input.action_press("grind")
		for frame: int in 90:
			await _frames(tree,game,evidence,1,"quay_ledge_air_catch",observer)
			if game.skater.grinding and game.skater._grind.line.id==LEDGE:
				caught = true
				break
			if game.skater.bailing: break
	if caught:
		await _frames(tree,game,evidence,18,"native_quay_ledge",observer)
		Input.action_press("ollie")
		await _frames(tree,game,evidence,2,"dry_runout_pop",observer)
		_set_steer(-0.65)
		Input.action_release("ollie")
		await _frames(tree,game,evidence,1,"exit_inboard",observer)
		_release()
		for frame: int in 120:
			await _frames(tree,game,evidence,1,"dry_runout_bank",observer)
			if game.score.total_score>0 and game.skater.is_on_floor() and not game.skater.airborne: break
		await _frames(tree,game,evidence,24,"single_bank_observation",observer)
	_release()
	game.skater.bailed.disconnect(on_bail)
	game.skater.grind_captured.disconnect(on_capture)
	var bank: int = game.score.total_score
	check.call(crossed and evidence.bridge_samples>=100 and evidence.bridge_supported,
		"C04-L05: actual ordinary Push crosses the safe bridge from its north quay onto the south landing")
	check.call(aligned and manual and evidence.manual_ticks>=24 and evidence.manual_start.is_finite()
		and evidence.manual_start.z<122.0 and caught and evidence.ledge_ticks>=18,
		"C04-L05: controlled bridge turn feeds a real Manual across the landfall and Ollie onto the quay ledge")
	check.call(evidence.captures==[LEDGE] and evidence.bails==0 and evidence.banks==1
		and bank>0 and game.skater.is_on_floor() and not game.skater.airborne,
		"C04-L05: the complete bridge/manual/ledge continuation exits onto dry support and earns exactly one bank")
	check.call(evidence.camera_samples>=100 and evidence.camera_clear,
		"C04-L05: ordinary chase preserves real head, board, soles, hull extremities and native camera volume along the full run")
	print("CLYDE_FLAGSHIP_RESULT ",JSON.stringify({"crossed":crossed,"aligned":aligned,"manual":manual,
		"caught":caught,"bank":bank,"banks":evidence.banks,"bails":evidence.bails,"captures":evidence.captures,
		"manual_start":var_to_str(evidence.manual_start),"manual_ticks":evidence.manual_ticks,
		"ledge_ticks":evidence.ledge_ticks,"ticks":evidence.ticks,"camera_samples":evidence.camera_samples,
		"camera_clear":evidence.camera_clear,"bridge_supported":evidence.bridge_supported,
		"at":var_to_str(game.skater.global_position),"stages":evidence.stages}))
	game.skater.spawn_position = old_spawn
	game.start_mode(old_free)


static func run_bank_return(tree: SceneTree, game: Node, check: Callable) -> void:
	var feature: Dictionary = {}
	for item: Dictionary in game.world.get_skate_feature_definitions():
		if item.id=="clyde_south_link": feature=item
	check.call(not feature.is_empty(),"C04-L05: the relocated bank retains its published ordinary manual-line identity")
	if feature.is_empty(): return
	var old_spawn: Vector3 = game.skater.spawn_position
	var old_free: bool = game.free_skate_mode
	var sampler := BankSampler.new()
	sampler.game=game
	game.add_child(sampler)
	var bails := [0]
	var bail_records: Array[Dictionary] = []
	var on_bail := func():
		bails[0]+=1
		bail_records.append({"at":var_to_str(game.skater.global_position),
			"reason":game.skater.bail_reason,"phase":game.skater.bail_phase,
			"inputs":_inputs(),"previous":sampler.last_state.duplicate(true)})
	game.skater.bailed.connect(on_bail)
	sampler.active=true
	# Preserve the existing full-map fixture verbatim, including its unchanged
	# post-bank coast. Its east endpoint is a bowl entrance, not a long dry lane.
	await Density._manual_crossing(tree,game,feature,check,Callable())
	var coast_at: Vector3 = game.skater.global_position
	var earned: int = game.score.total_score
	_release()
	var returned := false
	var air_ticks := 0
	for frame: int in 420:
		var rider: CharacterBody3D = game.skater
		var offset: Vector3 = Vector3(-15,2,124)-rider.global_position
		var horizontal := Vector2(offset.x,offset.z).length()
		if horizontal<0.8 and rider.is_on_floor() and not rider.airborne:
			returned=true
			break
		var desired := atan2(-offset.x,-offset.z)
		var error := angle_difference(rider.rotation.y,desired)
		var in_bowl := Vector2(rider.global_position.x+7,rider.global_position.z-134.5).length()<7.7
		# Steering in ordinary air is also the mapped Spin action. Preserve the
		# unscored bowl flight; aim the ground return only while supported.
		_set_steer(0.0 if rider.airborne else -clampf(error*3.0,-1.0,1.0))
		Input.action_release("brake")
		# Preserve actual transition momentum and use the normal full Push on
		# the bowl; a flatland speed limiter must not hold it below lip speed.
		Input.action_press("push",1.0 if in_bowl else 0.5)
		if not in_bowl and (absf(error)>0.35 or rider.speed>5.0): Input.action_press("brake",0.65)
		# Reuse the owner's finite-bowl escape input: release at air tick8,
		# fresh Push at10. No launch/transfer flag or momentum is assigned.
		air_ticks = air_ticks+1 if rider.airborne else 0
		if air_ticks in [8,9]: Input.action_release("push")
		if air_ticks==10: Input.action_press("push")
		await tree.physics_frame
		await tree.process_frame
		if rider.bailing: break
	_release()
	sampler.active=false
	game.skater.bailed.disconnect(on_bail)
	check.call(returned and bails[0]==0 and earned>0 and game.score.total_score==earned
		and sampler.support_finite and sampler.minimum_y>-0.5,
		"C04-L05: unchanged bank crossing/coast and controlled bowl-side return preserve the earned bank and supported Z124 bypass")
	check.call(sampler.samples>=20 and sampler.camera_clear,
		"C04-L05: the moved bank's full crossing, coast and bowl-side return keep strict ordinary full-body chase clearance")
	print("CLYDE_BANK_RETURN_RESULT ",JSON.stringify({"coast_at":var_to_str(coast_at),
		"returned":returned,"bails":bails[0],"bank_before":earned,"bank_after":game.score.total_score,
		"bowl_samples":sampler.bowl_samples,"support_finite":sampler.support_finite,"minimum_y":sampler.minimum_y,
		"camera_samples":sampler.samples,"camera_clear":sampler.camera_clear,
		"at":var_to_str(game.skater.global_position),"bail_records":bail_records}))
	sampler.queue_free()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_free)
	await tree.process_frame


static func _frames(tree: SceneTree, game: Node, evidence: Dictionary, count: int,
		stage: String, observer: Callable) -> void:
	for frame: int in count:
		await tree.physics_frame
		await tree.process_frame
		evidence.ticks+=1
		if stage!=evidence.phase:
			evidence.phase=stage
			evidence.stages.append({"stage":stage,"at":var_to_str(game.skater.global_position),
				"speed":game.skater.speed,"balance":game.skater.manual_balance})
		if stage=="safe_bridge_crossing":
			evidence.bridge_samples+=1
			evidence.bridge_supported = evidence.bridge_supported and game.skater.is_on_floor() \
				and not game.skater.airborne and absf(game.skater.global_position.x+25)<0.05
		if game.skater.manual_active: evidence.manual_ticks+=1
		if game.skater.grinding and game.skater._grind.line.id==LEDGE: evidence.ledge_ticks+=1
		if game.score.total_score!=evidence.last_score:
			evidence.banks+=1
			evidence.last_score=game.score.total_score
		if stage!="settle" and evidence.ticks%6==0:
			evidence.camera_samples+=1
			evidence.camera_clear = Density._camera_clear(game) and evidence.camera_clear
		if observer.is_valid(): await observer.call(stage,game,evidence.ticks)


static func _speed(game: Node, ceiling: float) -> void:
	# Hold Push through braking so a brake correction cannot accidentally
	# manufacture the game's Up-neutral-Down manual gesture.
	Input.action_press("push",0.5)
	Input.action_release("brake")
	if game.skater.speed>ceiling: Input.action_press("brake",0.4)


static func _set_steer(amount: float) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if amount<0.0: Input.action_press("steer_left",-amount)
	if amount>0.0: Input.action_press("steer_right",amount)


static func _release() -> void:
	for action: String in ["push","brake","steer_left","steer_right","ollie","grind","manual","flip","grab"]:
		Input.action_release(action)


static func _inputs() -> Dictionary:
	var result: Dictionary = {}
	for action: String in ["push","brake","steer_left","steer_right","ollie","grind","manual"]:
		if Input.is_action_pressed(action): result[action]=Input.get_action_strength(action)
	return result
