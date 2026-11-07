extends SceneTree
const Main=preload("res://game/main.tscn")
const Setup=preload("res://game/core/input_setup.gd")
const Lines=preload("res://tests/line_design_tests.gd")
const Board=preload("res://tests/board_geometry_tests_support.gd")
var passed:=0
var failed:=0
var dumped:=false
func _initialize():_run.call_deferred()
func _check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	create_timer(180,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await Lines.run_relay(self,game,_check,_observe)
	print("MOTION_RELAY_DIAGNOSTIC ",passed,"/",failed)
	game.free()
	quit(1 if failed>0 else 0)
func _observe(phase:String,game:Node,tick:int)->void:
	if not (phase.ends_with("second_exit_charge") or phase.ends_with("second_exit") or (phase.ends_with("second_landing") and tick<445)):return
	var rider:Node=game.skater
	var rig:RefCounted=rider._visual_rig
	var records:Array=[]
	var part_hits:Array=[]
	var part_index:=0
	for part:Dictionary in rider._grind_clearance._parts:
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=part.shape
		query.transform=rider._board_visual.global_transform
		query.collision_mask=1|2|8
		query.exclude=[rider.get_rid()]
		query.margin=0.0
		for hit:Dictionary in rider.get_world_3d().direct_space_state.intersect_shape(query,16):
			var body:CollisionObject3D=hit.collider
			var owner:int=body.shape_find_owner(int(hit.shape))
			var shape:Shape3D=body.shape_owner_get_shape(owner,0)
			var frame:Transform3D=body.global_transform*body.shape_owner_get_transform(owner)
			var bounds:Array=[]
			if shape is BoxShape3D:
				for axis:int in 3:
					var lo:=INF;var hi:=-INF
					for point:Vector3 in part.points:
						var local:Vector3=frame.affine_inverse()*(rider._board_visual.global_transform*point)
						lo=minf(lo,local[axis]);hi=maxf(hi,local[axis])
					bounds.append([lo,hi,shape.size[axis]*.5])
			part_hits.append({"component":part_index,"points":part.points.size(),"label":body.get_meta("art_label",body.name),"shape":hit.shape,"local_axis_min_max_half":bounds})
		part_index+=1
	if phase.ends_with("second_exit") and not dumped:
		var packet:Dictionary={"board":_pose(rider._board_visual.global_transform),"parts":[],"native_boxes":[]}
		for part:Dictionary in rider._grind_clearance._parts:
			var points:Array=[]
			for point:Vector3 in part.points:points.append(_v(point))
			packet.parts.append(points)
		for body:Node in game.world.find_children("*","StaticBody3D",true,false):
			if String(body.get_meta("art_label",""))!="QuayBenchSeat":continue
			var rid:RID=body.get_rid()
			for index:int in PhysicsServer3D.body_get_shape_count(rid):
				var native:RID=PhysicsServer3D.body_get_shape(rid,index)
				if PhysicsServer3D.shape_get_type(native)!=PhysicsServer3D.SHAPE_BOX:continue
				packet.native_boxes.append({"body":_pose(PhysicsServer3D.body_get_state(rid,PhysicsServer3D.BODY_STATE_TRANSFORM)),
					"child":_pose(PhysicsServer3D.body_get_shape_transform(rid,index)),"half":_v(PhysicsServer3D.shape_get_data(native))})
		var file:=FileAccess.open("res://.local/motion-seat-sat.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(packet,"\t"))
		file.close()
		dumped=true
	var overall:=INF
	for mesh:MeshInstance3D in Board.visible_meshes(rig,false):
		var low:=INF
		var at:=Vector3.ZERO
		var native:Dictionary={}
		var hull:ConvexPolygonShape3D=mesh.mesh.create_convex_shape(true,false)
		for point:Vector3 in hull.points:
			var actual:=mesh.to_global(point)
			var ray:=PhysicsRayQueryParameters3D.create(actual+Vector3.UP*.3,actual-Vector3.UP*.3,1|8,[rider.get_rid()])
			var hit:Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty():continue
			var gap:float=(actual-Vector3(hit.position)).dot(hit.normal)
			if gap<low:
				low=gap;at=actual;native={"label":hit.collider.get_meta("art_label",hit.collider.name),"shape":hit.shape,"point":hit.position}
		overall=minf(overall,low)
		records.append({"mesh":rider.get_path_to(mesh),"min_gap":low,"point":at,"support":native})
	print("MOTION_SECOND_EXIT tick=",tick," physics=",Engine.get_physics_frames()," phase=",phase," grinding=",rider.grinding,
		" air=",rider.airborne," body=",rider.global_position," velocity=",rider.velocity," visual=",rider._visual.transform,
		" board=",rider._board_visual.global_transform," offset=",rider._grind_visual_offset,
		" support_basis=",rider._air_support_basis," min_native_gap=",overall," components=",records," actual_component_hits=",part_hits)
func _v(point:Vector3)->Array:return [point.x,point.y,point.z]
func _pose(pose:Transform3D)->Dictionary:return {"origin":_v(pose.origin),"basis":[_v(pose.basis.x),_v(pose.basis.y),_v(pose.basis.z)]}
