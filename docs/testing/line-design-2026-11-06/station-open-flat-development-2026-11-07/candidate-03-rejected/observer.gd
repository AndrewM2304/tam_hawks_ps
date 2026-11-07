extends SceneTree
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const Routes=preload("res://tests/world_routes_tests.gd")
const Camera=preload("res://tests/full_level_density_tests.gd")
var passed:=0
var failed:=0
var events: Array[Dictionary]=[]
var recorder: Witness

func _initialize() -> void:_run.call_deferred()
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)

func _run() -> void:
	Setup.register_actions()
	var game:=Main.new()
	game.name="StationProbeMain"
	game.persistence_enabled=false
	root.add_child(game)
	await Driver._frames(self,5)
	var inventory:=_inventory(game)
	print("STATION_NATIVE_INVENTORY ",JSON.stringify(inventory))
	if OS.get_cmdline_user_args().has("--inventory-only"):
		print("STATION_PROBE RESULT: 0 passed, 0 failed")
		game.free();quit();return
	var half: Node3D=game.world.get_node("StationConcourseHalfpipe")
	_check(half.global_position.distance_to(Vector3(-65,2,35))<.00001 and absf(half.rotation.y)<.00001,
		"station candidate: actual halfpipe is yaw0 at(-65,2,35)")
	var protected:=true
	for pair: Array in [[Vector3(-62,2,22),Vector3(-82,2,34)],
		[Vector3(-82,2,34),Vector3(-82,2,-34)],
		[Vector3(-126,2,0),Vector3(-145,2,0)],
		[Vector3(-50,2,22),Vector3(-70,2,22)]]:
		protected=protected and Routes._clear_sweep(game.world,pair[0],pair[1]) and Routes._clear_sweep(game.world,pair[1],pair[0])
	_check(protected,"station candidate: original career diagonal, low bypass and district mouths remain clear both ways")
	await Driver._reset(self,game,Vector3(-94,2.08,37.2),-PI*.5)
	var e:=Driver._evidence(game,"station_open_bank_pipe")
	Driver._connect(game,e)
	recorder=Witness.new();recorder.game=game;recorder.process_physics_priority=100
	game.add_child(recorder)
	Input.action_press("push")
	var bank_loaded:=false
	for tick: int in 350:
		if game.skater.global_position.x>=-82.5 and not bank_loaded:
			Input.action_release("push");Input.action_press("manual");bank_loaded=true
		if game.skater.manual_active:Driver._balance_manual(game)
		else:
			if absf(game.skater.speed)<8.0:Input.action_press("push")
			else:Input.action_release("push")
		await _step(game,e,"bank_crossing")
		if game.skater.global_position.x>=-74.5 or e.bails>0:break
	_event(game,"bank_east_toe_exit")
	_check(recorder.bank_manual_steps>=6 and game.skater.global_position.x>=-74.5 and e.bails==0,
		"station candidate: genuine balanced Manual crosses the existing bank plateau and native east toe")
	Driver._release()
	var entered_open:=false
	for tick: int in 180:
		if absf(game.skater.speed)<7.8:Input.action_press("push")
		else:Input.action_release("push")
		# Push/coast through the actual open west side; the next input is
		# an ordinary left carve, rather than aiming at a closed outer deck.
		if game.skater.global_position.x>=-69.8:
			Driver._steer_to(game,Vector3(-65.8,2,27),false)
		await _step(game,e,"open_flat_north_carve")
		var local: Vector3=half.to_local(game.skater.global_position)
		entered_open=entered_open or (absf(local.x)<=4 and absf(local.z)<3 and game.skater.global_position.y<2.15)
		if game.skater._feature_transition.active or e.bails>0:break
	_event(game,"first_native_curve")
	Driver._release()
	var both:=false
	var returned_from_south:=false
	for tick: int in 780:
		var ride: RefCounted=game.skater._feature_transition
		# After earning both faces, brake the real south-face descent for the
		# narrow west open-side turn; no velocity/pose/state is assigned.
		if both and ride.active and String(ride.feature.name)=="SouthTransition" and ride.state=="surface" \
			and float(ride._speed)<0 and rad_to_deg(float(ride._theta))<30:
			Input.action_press("brake",.8)
		else:Input.action_release("brake")
		await _step(game,e,"opposing_native_faces")
		both=recorder.face_angles.has("NorthTransition") and recorder.face_angles.has("SouthTransition") \
			and float(recorder.face_angles.get("NorthTransition",0))>=35 and float(recorder.face_angles.get("SouthTransition",0))>=35
		if both and not game.skater._feature_transition.active and not game.skater.airborne \
			and game.skater.global_position.y<2.15 and game.skater.velocity.z< -1:
			returned_from_south=true;break
		if e.bails>0:break
	_event(game,"opposing_faces_return")
	_check(entered_open and both and returned_from_south and e.bails==0,
		"station candidate: bank runout feeds real open flat, both35degree opposing faces and native return")
	var reentered:=false
	if returned_from_south:
		Input.action_release("brake")
		for tick: int in 400:
			Driver._steer_to(game,Vector3(-78,2,37.2),false)
			if not game.skater._feature_transition.active and not game.skater.airborne:Input.action_press("push",.4)
			await _step(game,e,"west_open_exit_reentry")
			if game.skater.global_position.x<=-74.8 and absf(game.skater.global_position.z-37.2)<2.5 \
				and not game.skater.airborne and game.skater.is_on_floor():reentered=true;break
			if e.bails>0:break
	_event(game,"bank_return_approach")
	_check(reentered and e.bails==0 and e.recoveries==0,"station candidate: same rider exits open side onto supported bank re-entry without reset")
	Driver._release()
	await Driver._steps(self,game,e,24,"final_bank_observation",Callable())
	recorder.active=false
	_check(recorder.contiguous and recorder.max_step<1.0,"station candidate: every native physics row is contiguous with finite bounded travel")
	_check(recorder.model_clear and recorder.shoes_clear and recorder.capsule_zero_clear,
		"station candidate: every actual native pose has zero-overlap connected board/shoe/capsule volumes")
	_check(e.camera_clear,"station candidate: existing full-body native chase witness remains clear")
	var result: Dictionary={"scope":"private one-initial-fixture bank/open-pipe feasibility; not full C04/L1", "initial_resets":1,
		"events":events,"physics":recorder.rows,"face_angles":recorder.face_angles,"bank_manual_steps":recorder.bank_manual_steps,
		"entered_open":entered_open,"both_faces":both,"returned_from_south":returned_from_south,"reentered":reentered,
		"bails":e.bails,"recoveries":e.recoveries,"camera":e.camera_clear,"captures":e.captures,"score":game.score.total_score,
		"model_clear":recorder.model_clear,"shoes_clear":recorder.shoes_clear,"capsule_zero_clear":recorder.capsule_zero_clear,
		"raw_failures":recorder.failures,"resource_inventory":inventory}
	print("STATION_NATIVE_TRACE ",JSON.stringify(result))
	Driver._disconnect(game,e);Driver._release();game.free()
	print("STATION_PROBE RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed>0 else 0)

func _step(game: Node,e: Dictionary,phase: String) -> void:
	recorder.phase=phase
	await Driver._step(self,game,e,phase,Callable())

func _event(game: Node,label: String) -> void:
	events.append({"event":label,"physics":Engine.get_physics_frames(),"at":game.skater.global_position,
		"velocity":game.skater.velocity,"speed":game.skater.speed,"path_m":recorder.path_m})

func _inventory(game: Node) -> Dictionary:
	var counts: Dictionary={"bodies":0,"shape_slots":0,"mesh_nodes":0,"multimesh_nodes":0}
	var meshes: Dictionary={};var materials: Dictionary={};var bodies: Array[Dictionary]=[]
	for node: Node in game.world.find_children("*","Node",true,false):
		if node is StaticBody3D:
			counts.bodies+=1
			var selected: bool=String(node.get_path()).contains("StationConcourseHalfpipe") or String(node.get_meta("art_label","")).begins_with("station_low_manual")
			var body: Dictionary={"path":str(game.world.get_path_to(node)),"frame":node.global_transform,"shapes":[]}
			for owner: int in node.get_shape_owners():
				for index: int in node.shape_owner_get_shape_count(owner):
					counts.shape_slots+=1
					if selected:
						var shape: Shape3D=node.shape_owner_get_shape(owner,index)
						var frame: Transform3D=node.global_transform*node.shape_owner_get_transform(owner)
						body.shapes.append({"owner":owner,"index":index,"type":shape.get_class(),"rid":str(shape.get_rid()),
							"frame":frame,"aabb":frame*shape.get_debug_mesh().get_aabb()})
			if selected:bodies.append(body)
		if node is MeshInstance3D and node.mesh!=null:
			counts.mesh_nodes+=1;meshes[node.mesh.get_rid()]=true
			if node.material_override!=null:materials[node.material_override.get_rid()]=true
		if node is MultiMeshInstance3D and node.multimesh!=null:
			counts.multimesh_nodes+=1
			if node.multimesh.mesh!=null:meshes[node.multimesh.mesh.get_rid()]=true
			if node.material_override!=null:materials[node.material_override.get_rid()]=true
	counts.unique_visual_meshes=meshes.size();counts.unique_override_materials=materials.size()
	var guides: Array[Dictionary]=[]
	for line in game.world.get_grind_lines():
		if String(line.id).contains("StationConcourseHalfpipe") or String(line.id).contains("station_low_manual"):
			guides.append({"id":line.id,"points":line.points,"length":line.length,"source":line.contact_source,"verified":line.contact_verified})
	var bank: Dictionary={}
	for f: Dictionary in game.world.get_skate_feature_definitions():
		if String(f.id)=="station_low_manual":bank=f
	return {"counts":counts,"selected_bodies":bodies,"selected_guides":guides,"bank_definition":bank,"gaps":game.world.get_gap_definitions()}

class Witness extends Node:
	var game: Node
	var active:=true
	var phase:="setup"
	var rows: Array[Dictionary]=[]
	var failures: Array[Dictionary]=[]
	var face_angles: Dictionary={}
	var contiguous:=true
	var max_step:=0.0
	var bank_manual_steps:=0
	var model_clear:=true
	var shoes_clear:=true
	var capsule_zero_clear:=true
	var path_m:=0.0
	func _physics_process(_delta: float) -> void:
		if not active:return
		var rider: Node=game.skater
		var at: Vector3=rider.global_position
		if not rows.is_empty():
			contiguous=contiguous and int(rows[-1].physics)+1==Engine.get_physics_frames()
			var step: float=at.distance_to(rows[-1].at)
			max_step=maxf(max_step,step);path_m+=step
		var feature_id:="";var feature_state:="";var theta:=0.0
		if rider._feature_transition.active:
			feature_id=String(rider._feature_transition.feature.feature_id)
			feature_state=rider._feature_transition.state
			theta=rad_to_deg(rider._feature_transition._theta)
			if feature_id.begins_with("StationConcourseHalfpipe"):
				var id: String=rider._feature_transition.feature.name
				face_angles[id]=maxf(float(face_angles.get(id,0)),theta)
		if rider.manual_active and at.x>=-83 and at.x<=-77 and absf(at.z-37.2)<1.05 and at.y>2.25:bank_manual_steps+=1
		var query:=PhysicsShapeQueryParameters3D.new()
		query.collision_mask=1|2|8;query.exclude=[rider.get_rid()];query.margin=0.0
		var space: PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
		query.transform=rider._board_visual.global_transform
		var model_hits: Array[Dictionary]=[]
		for i: int in rider._grind_clearance._parts.size():
			query.shape=rider._grind_clearance._parts[i].shape
			var hits:=space.intersect_shape(query,8)
			if not hits.is_empty():model_hits.append({"part":i,"hits":_hits(hits)})
		model_clear=model_clear and model_hits.is_empty()
		var shoe_hits: Array[Dictionary]=[]
		var box:=BoxShape3D.new();query.shape=box
		for i: int in rider._visual_rig._legs.size():
			var bounds: AABB=rider._obstacle_shoe_bounds[i]
			box.size=bounds.size
			query.transform=rider._visual_rig._legs[i].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
			var hits:=space.intersect_shape(query,8)
			if not hits.is_empty():shoe_hits.append({"foot":i,"hits":_hits(hits)})
		shoes_clear=shoes_clear and shoe_hits.is_empty()
		var capsule: CollisionShape3D=rider.get_node("BodyCollision")
		query.shape=capsule.shape;query.transform=capsule.global_transform
		var capsule_hits:=space.intersect_shape(query,32)
		capsule_zero_clear=capsule_zero_clear and capsule_hits.is_empty()
		query.margin=.001
		var capsule_skin:=space.intersect_shape(query,32)
		if (not model_hits.is_empty() or not shoe_hits.is_empty() or not capsule_hits.is_empty()) and failures.size()<16:
			failures.append({"physics":Engine.get_physics_frames(),"phase":phase,"at":at,"feature":feature_id,"theta":theta,
				"model_hits":model_hits,"shoe_hits":shoe_hits,"capsule_zero":_hits(capsule_hits),"capsule_skin":_hits(capsule_skin)})
		var inputs: Dictionary={}
		for key: String in ["push","brake","steer_left","steer_right","manual","ollie","grind","revert"]:inputs[key]=Input.get_action_strength(key)
		rows.append({"physics":Engine.get_physics_frames(),"phase":phase,"at":at,"velocity":rider.velocity,"speed":rider.speed,
			"yaw":rider.rotation.y,"air":rider.airborne,"floor":rider.is_on_floor(),"manual":rider.manual_active,
			"feature":feature_id,"feature_state":feature_state,"theta_degrees":theta,"inputs":inputs,"path_m":path_m,
			"board_zero":model_hits.is_empty(),"shoes_zero":shoe_hits.is_empty(),"capsule_zero":capsule_hits.is_empty(),
			"capsule_skin":_hits(capsule_skin)})
	func _hits(hits: Array[Dictionary]) -> Array[Dictionary]:
		var result: Array[Dictionary]=[]
		for h: Dictionary in hits:result.append({"rid":str(h.rid),"shape":h.shape,"path":str(h.collider.get_path())})
		return result
