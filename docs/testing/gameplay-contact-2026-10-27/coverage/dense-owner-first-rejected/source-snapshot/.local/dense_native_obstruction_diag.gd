extends SceneTree
const Main=preload("res://game/main.gd")
const Surface=preload("res://tests/surface_coverage_tests.gd")
func _initialize() -> void:_run.call_deferred()
func _trace(rider: CharacterBody3D,from: Vector3,to: Vector3) -> Dictionary:
	var frame:Transform3D=rider.global_transform;frame.origin=from
	var hit:=KinematicCollision3D.new()
	var touched:bool=rider.test_move(frame,to-from,hit,rider.safe_margin,true,16)
	var contacts:Array=[]
	if touched:
		for index:int in hit.get_collision_count():
			var body:Variant=hit.get_collider(index)
			var shape:Variant=body.shape_owner_get_owner(body.shape_find_owner(hit.get_collider_shape(index)))
			var geometry:Dictionary={"type":shape.shape.get_class(),"frame":shape.global_transform}
			if shape.shape is BoxShape3D:geometry.size=shape.shape.size
			if shape.shape is CylinderShape3D:geometry.radius=shape.shape.radius;geometry.height=shape.shape.height
			contacts.append({"label":str(body.get_meta("art_label",body.name)),"path":str(body.get_path()),
				"normal":hit.get_normal(index),"depth":hit.get_depth(),"travel":hit.get_travel(),
				"ids":body.get_meta("grind_surface_ids",[]),"authored":body.get_meta("authored_grind_ids",[]),
				"grind_id":str(body.get_meta("grind_id","")),"geometry":geometry})
	var collision:CollisionShape3D=rider.get_node("BodyCollision")
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=collision.shape
	query.transform=frame*collision.transform;query.motion=to-from;query.margin=0.0
	query.collision_mask=rider.collision_mask;query.exclude=[rider.get_rid()]
	var fractions:PackedFloat32Array=rider.get_world_3d().direct_space_state.cast_motion(query)
	return {"from":from,"to":to,"clear":rider._rail_path_clear(from,to),"contacts":contacts,"physical_cast":fractions}
func _run() -> void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	game.skater.set_physics_process(false);game.skater.set_process(false)
	await physics_frame;await process_frame
	var rider:CharacterBody3D=game.skater
	var lines:Array=game.world.get_grind_lines()
	var total:=0;var unexpected:=0;var inherited:=0
	for line in lines:
		var count:int=maxi(4,ceili(line.length/.35))
		for sample:int in range(1,count):
			var distance:float=line.length*sample/count
			var point:Vector3=rider._grind._body_point(line,distance)
			var next:Vector3=rider._grind._body_point(line,minf(line.length,distance+.20))
			total+=1
			var down:bool=rider._rail_path_clear(point+Vector3.UP*.12,point)
			var along:bool=rider._rail_path_clear(point,next)
			if down and along:continue
			if Surface.INHERITED_OBSTRUCTIONS.has(line.id):inherited+=1;break
			unexpected+=1
			var nearby:Array=[]
			for other in lines:
				if other==line:continue
				var closest:Dictionary=other.closest(point)
				if float(closest.gap)<.85:nearby.append({"id":other.id,"point":closest.point,"gap":closest.gap})
			var lifts:Array=[]
			for lift:float in [0.0,.015,.065,.10]:
				lifts.append({"lift":lift,"down":rider._rail_path_clear(point+Vector3.UP*(.12+lift),point+Vector3.UP*lift),
					"along":rider._rail_path_clear(point+Vector3.UP*lift,next+Vector3.UP*lift)})
			print("DENSE_UNEXPECTED ",JSON.stringify({"id":line.id,"source":line.contact_source,"verified":line.contact_verified,
				"body_profile_radius":line.body_profile_radius,"body_profile_source":line.body_profile_source,"distance":distance,
				"line_points":line.points,"tangent":line.dir_at(distance),"point":point,"next":next,"down_clear":down,"along_clear":along,
				"down":_trace(rider,point+Vector3.UP*.12,point),"along":_trace(rider,point,next),"nearby":nearby,"diagnostic_lifts":lifts}))
			break
	print("DENSE_DIAGNOSTIC_SUMMARY ",{"samples_before_first_rejection":total,"unexpected_guides":unexpected,"inherited_guides":inherited})
	game.queue_free();await process_frame
	quit()
