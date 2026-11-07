extends SceneTree
const Main=preload("res://game/main.gd")
func v(a:Array)->Vector3:return Vector3(a[0],a[1],a[2])
func vec(p:Vector3)->Array:return [p.x,p.y,p.z]
func frame(a:Array)->Transform3D:
	return Transform3D(Basis(Vector3(a[0][0],a[1][0],a[2][0]),Vector3(a[0][1],a[1][1],a[2][1]),Vector3(a[0][2],a[1][2],a[2][2])),Vector3(a[0][3],a[1][3],a[2][3]))
func hit(h:Dictionary)->Dictionary:
	if h.is_empty():return {}
	return {"point":vec(h.position),"normal":vec(h.normal),"rid":str(h.rid),"shape":h.shape,"path":str(h.collider.get_path())}
func _initialize()->void:run.call_deferred()
func run()->void:
	var g:=Main.new();g.persistence_enabled=false;root.add_child(g);g.start_mode(true)
	for i:int in 30:await physics_frame;await process_frame
	var rider:CharacterBody3D=g.skater
	var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://.local/landing-input.json"))
	var pose:Transform3D=frame(d.board)
	var point:=Vector3(0,2,0)
	var space:=rider.get_world_3d().direct_space_state
	var records:Array=[]
	for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		var center:Vector3=pose*Vector3(wheel.center)
		var q:=PhysicsRayQueryParameters3D.create(center+Vector3.UP*.35,center-Vector3.UP*.50,rider.collision_mask,[rider.get_rid()])
		var h:Dictionary=space.intersect_ray(q)
		records.append({"local":vec(wheel.center),"current_world":vec(center),"native":hit(h),"gap_to_y2":center.y-2.0})
	var poses:Array=[]
	for lift:float in [0.0,.002,.004,.008,.012,.016,.020,.025]:
		var candidate:Transform3D=pose;candidate.origin.y+=lift
		poses.append({"lift_m":lift,"all_board_tyres_native_clear":rider._native_rim_frame_clear(candidate,0.0),"model_native_clear":rider._manual_model_frame_clear(candidate)})
	var q:=PhysicsRayQueryParameters3D.create(v([d.body[0][3],d.body[1][3],d.body[2][3]])+Vector3.UP*.2,v([d.body[0][3],d.body[1][3],d.body[2][3]])-Vector3.UP*3,rider.collision_mask,[rider.get_rid()])
	var support:Dictionary=space.intersect_ray(q)
	var collisions:Array=[]
	for i:int in rider._grind_clearance._parts.size():
		var part:Dictionary=rider._grind_clearance._parts[i]
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=part.shape;query.transform=pose;query.collision_mask=1|2|8;query.exclude=[rider.get_rid()];query.margin=0
		var hits:Array=[]
		for h:Dictionary in space.intersect_shape(query,16):hits.append({"rid":str(h.rid),"shape":h.shape,"path":str(h.collider.get_path())})
		if not hits.is_empty():collisions.append({"part":i,"points":part.points.size(),"hits":hits})
	var out:Dictionary={"scope":"Fresh native finite geometry evaluated at exact retained board query frame; no player pose injection, ordinary trajectory, GPU or performance claim.","wheels":records,"pose_query_native":poses,"actual_center_ray":hit(support),"colliding_components":collisions}
	var f:=FileAccess.open("res://.local/landing-witness.json",FileAccess.WRITE);f.store_string(JSON.stringify(out,"\t",true,true));f.close()
	print("LANDING_FINITE_GEOMETRY ",JSON.stringify(out,"",true,true))
	g.queue_free();await process_frame;quit()
