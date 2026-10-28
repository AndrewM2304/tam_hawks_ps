extends "res://.local/park-route-repair/bend_probe.gd"
const Variants=preload("res://tests/grind_variant_contact_tests.gd")
const Park=preload("res://tests/pt24_park_run_tests.gd")
var path_metrics:Dictionary={}
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	var board_inverse:Transform3D=game.skater._board_visual.global_transform.affine_inverse()
	for mesh:MeshInstance3D in game.skater._visual_rig.board_contact_geometry().meshes:
		cached_meshes.append({"path":str(mesh.get_path()),"faces":mesh.mesh.get_faces(),"local":board_inverse*mesh.global_transform})
	await Gallery.run(self,game,_check,_observe)
	previous.clear()
	await Driver._gallery(self,game,_check,_observe)
	previous.clear()
	await Density._actual_ledge_admission(self,game,_check,_observe,"Grind_Park_FiveStepHubba")
	await Park.run(self,game,_check)
	await _endpoint_cases(game)
	Driver._release();game.queue_free();await _frames(2)
	# All Main bodies have exited before the isolated variant/foreign-obstacle
	# fixtures enter their private far-away root. No shared rider/world state.
	await Variants.run(self,_check)
	print("NATIVE_PATH_QUERY_METRICS ",JSON.stringify(path_metrics))
	print("BEND_PROBE_OBSERVED ",observed.keys())
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _endpoint_cases(game:Node)->void:
	var line
	for candidate in game.world.get_grind_lines():
		if candidate.id=="Grind_Ledge_park_east_lower":line=candidate;break
	if line==null:_check(false,"endpoint foreignwall: real retained lower-seat guide exists");return
	var rider:CharacterBody3D=game.skater
	var tangent:Vector3=line.dir_at(0.0)
	var flat:Vector3=Vector3(tangent.x,0,tangent.z).normalized()
	var initial:Vector3=line.contact_at(0.0)-flat*.25+Vector3.UP*.20
	var cutoff:float=rider._grind.capture_model_radius+maxf(line.contact_normal_offset,line.body_profile_radius)
	var target:Vector3=rider._grind._body_point(line,cutoff)
	var observations:Array=[]
	for blocked:bool in [false,true]:
		Park._release();rider.spawn_position=initial;game.start_mode(true)
		rider.set_physics_process(false);rider.set_process(false)
		rider.reset_skater();rider.velocity=flat*6.0+Vector3.DOWN;rider.speed=6.0;rider.airborne=true
		rider.rotation.y=atan2(-flat.x,-flat.z)
		rider.set_grind_lines([line])
		var wall:StaticBody3D
		if blocked:
			wall=StaticBody3D.new();wall.name="IndependentForeignEndpointWall";wall.collision_layer=1;wall.collision_mask=0
			var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.6,2,.03);collision.shape=box
			wall.add_child(collision);game.world.add_child(wall);wall.global_position=target+Vector3.UP
		await _frames(1)
		var initial_body_clear:bool=not rider.test_move(rider.global_transform,Vector3.ZERO,null,.001,true,16)
		var source_rid:RID=game.world.get_node("Grind_Ledge_park_east_lower/NativeGrindBearing").get_rid()
		var native_crown:bool=rider._grind_native_crown(line,cutoff,source_rid)
		var body_path:bool=rider._grind_capture_path_clear(line,initial,target,cutoff,1.0,rider.velocity,false)
		var captures:Array[String]=[]
		var callback:=func(id:String)->void:captures.append(id)
		rider.grind_captured.connect(callback);Input.action_press("grind")
		rider.set_physics_process(true);rider.set_process(true)
		await _frames(1)
		var distance:float=rider._grind.distance
		await _frames(8)
		var advanced:float=rider._grind.distance-distance
		if blocked:_check(initial_body_clear and captures.is_empty() and not rider.grinding,"endpoint foreignwall: a real independent solid refuses the same finite-end correction from a clear initial native capsule")
		else:_check(initial_body_clear and native_crown and body_path and captures==[line.id] and rider.grinding and advanced>.4 and not rider.bailing,"endpoint foreignwall: the same declared native approach captures the actual retained cap and advances eight ticks when unblocked")
		observations.append({"blocked":blocked,"initial":initial,"target":target,"model_radius":rider._grind.capture_model_radius,"native_cap_radius":line.contact_normal_offset,"inboard_cutoff":cutoff,"initial_body_clear":initial_body_clear,"native_crown":native_crown,"body_path":body_path,"captures":captures,"advance":advanced,"grinding":rider.grinding,"bailing":rider.bailing,"reason":rider.bail_reason})
		rider.grind_captured.disconnect(callback);Park._release()
		if wall!=null:wall.queue_free();await _frames(1)
	print("PARK_ENDPOINT_NATIVE ",JSON.stringify(observations))
func _frames(count:int)->void:
	for frame:int in count:await physics_frame;await create_timer(0.0,false,false).timeout

func _observe(phase:String,game:Node,tick:int)->void:
	var rider:CharacterBody3D=game.skater
	if rider.grinding:
		var key:String=rider._grind.line.id
		var row:Dictionary=path_metrics.get(key,{"observed_native_updates":0,"maximum_queries_per_last_continuous_check":0,"maximum_subdivisions_per_last_check":0,"maximum_depth":0,"budget_exhausted":false})
		row.observed_native_updates+=1
		row.maximum_queries_per_last_continuous_check=maxi(row.maximum_queries_per_last_continuous_check,rider._grind_clearance.last_path_queries)
		row.maximum_subdivisions_per_last_check=maxi(row.maximum_subdivisions_per_last_check,rider._grind_clearance.last_path_subdivisions)
		row.maximum_depth=maxi(row.maximum_depth,rider._grind_clearance.last_path_max_depth)
		row.budget_exhausted=row.budget_exhausted or rider._grind_clearance.last_path_budget_exhausted
		path_metrics[key]=row
	super._observe(phase,game,tick)
