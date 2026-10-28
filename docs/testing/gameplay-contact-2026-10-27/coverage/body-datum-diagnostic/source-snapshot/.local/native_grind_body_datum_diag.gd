extends SceneTree
const Main=preload("res://game/main.gd")
func _initialize() -> void:_run.call_deferred()
func _sample(rider: CharacterBody3D,at: Vector3,skin: float) -> Dictionary:
	var from:=at+Vector3.UP*.15
	var target:=at+Vector3.UP*skin
	var frame:Transform3D=rider.global_transform;frame.origin=from
	var collision:CollisionShape3D=rider.get_node("BodyCollision")
	var contact:=KinematicCollision3D.new()
	var touched:bool=rider.test_move(frame,target-from,contact,rider.safe_margin,true,16)
	var contacts:Array=[]
	if touched:
		for i:int in contact.get_collision_count():
			var body:Variant=contact.get_collider(i)
			contacts.append({"normal":contact.get_normal(i),"depth":contact.get_depth(),"travel":contact.get_travel(),
				"label":str(body.get_meta("art_label",body.name)),"layer":body.collision_layer})
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=collision.shape
	query.transform=frame*collision.transform;query.motion=target-from;query.margin=0.0
	query.collision_mask=rider.collision_mask;query.exclude=[rider.get_rid()]
	var fractions:PackedFloat32Array=rider.get_world_3d().direct_space_state.cast_motion(query)
	frame.origin=target
	var rest:=KinematicCollision3D.new()
	var resting:bool=rider.test_move(frame,Vector3.ZERO,rest,.001,true,16)
	return {"body_target":target,"skin":skin,"clear":rider._rail_path_clear(from,target),"native_hit":touched,
		"contacts":contacts,"zero_margin_cast":fractions,"rest_hit":resting,
		"rest_depth":rest.get_depth() if resting else 0.0,"rest_travel":rest.get_travel() if resting else Vector3.ZERO}
func _run() -> void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	game.skater.set_physics_process(false);game.skater.set_process(false)
	await physics_frame;await process_frame
	var rider:CharacterBody3D=game.skater
	var lines:Dictionary={}
	for line in game.world.get_grind_lines():lines[line.id]=line
	for id:String in ["Grind_Rail_Exchange","Grind_Ledge_GalleryEntrance","Grind_Coping_ExchangeFountain","Grind_Rail_George"]:
		var line=lines[id]
		var distance:float=line.length*.5
		var at:Vector3=rider._grind._body_point(line,distance)
		print("GRIND_BODY_DATUM ",{"id":id,"verified":line.contact_verified,"crown":line.contact_at(distance),"body":at,
			"baseline":_sample(rider,at,0.0),"native_skin":_sample(rider,at,rider.safe_margin)})
	for line in lines.values():
		if not line.id.begins_with("Grind_Ledge_NorthStreetRetaining_1_Native_"):continue
		var distance:float=line.length*.5;var crown:Vector3=line.contact_at(distance)
		var side:Vector3=Vector3.UP.cross(line.dir_at(distance)).normalized()
		var hits:Array=[]
		for offset:float in [0.0,-.005,.005]:
			var point:=crown+side*offset
			var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.04,point-Vector3.UP*.08,1|2|8)
			ray.exclude=[rider.get_rid()]
			var hit:Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty():
				var body:StaticBody3D=hit.collider
				hits.append({"offset":offset,"hit":hit,"label":str(body.get_meta("art_label",body.name)),
					"ids":body.get_meta("grind_surface_ids",[]),"authored":body.get_meta("authored_grind_ids",[])})
		print("RETAINING_CROWN_OWNER ",{"id":line.id,"crown":crown,"outward":line.contact_edge_outward,"hits":hits})
	print("GRIND_BODY_PROFILE ",{"offset":rider.get_node("BodyCollision").position,"base":rider._grind.body_base_offset,
		"radius":rider._grind.body_radius,"native_margin":rider.safe_margin})
	game.queue_free();await process_frame
	quit()
