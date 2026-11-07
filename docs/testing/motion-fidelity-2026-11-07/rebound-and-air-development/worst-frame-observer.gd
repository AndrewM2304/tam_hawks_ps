extends SceneTree
const Main=preload("res://game/main.tscn")
const Lines=preload("res://tests/line_design_tests.gd")
var passed:=0
var failed:=0

class Observer extends Node:
	var rider:Node
	var frames:Array=[]
	var worst:Dictionary={}
	var maximum:=-1.0
	var prior:Dictionary={}
	func _physics_process(_delta:float):
		var offset:Vector3=rider._obstacle_visual_offset
		var at:Vector3=rider.global_position
		var board:Vector3=rider._board_visual.global_position
		var root_at:Vector3=rider._rider_visual.global_position
		var row:Dictionary={"physics":Engine.get_physics_frames(),"air":rider.airborne,"wall":rider.is_on_wall(),
			"floor":rider.is_on_floor(),"body":v(at),"board":v(board),"rider":v(root_at),"offset":v(offset),
			"velocity":v(rider.velocity),"active":not rider._obstacle_air_wall.is_empty(),
			"owner_hint":not rider._obstacle_air_wall_owner.is_empty(),"sequence":rider._ramp_air_sequence}
		if not prior.is_empty():
			row["body_step_m"]=at.distance_to(Vector3(prior.body[0],prior.body[1],prior.body[2]))
			row["board_step_m"]=board.distance_to(Vector3(prior.board[0],prior.board[1],prior.board[2]))
			row["rider_step_m"]=root_at.distance_to(Vector3(prior.rider[0],prior.rider[1],prior.rider[2]))
			row["offset_step_m"]=offset.distance_to(Vector3(prior.offset[0],prior.offset[1],prior.offset[2]))
		frames.append(row)
		prior=row
		if rider.airborne and offset.length()>maximum:
			maximum=offset.length()
			if maximum>.09:worst=measure(row,offset)
	func measure(row:Dictionary,offset:Vector3)->Dictionary:
		var result:Dictionary={"frame":row,"board_transform":t(rider._board_visual.global_transform),"probes":[]}
		var space:PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
		var geometry:Dictionary=rider._visual_rig.board_contact_geometry()
		for fraction:float in [0.0,.25,.5,.75,1.0]:
			var delta:=offset*(fraction-1.0)
			var frame:Transform3D=rider._board_visual.global_transform
			frame.origin+=delta
			var probe:Dictionary={"fraction":fraction,"actual_components_clear":rider._manual_model_frame_clear(frame),
				"whole_board_and_shoes_clear":rider._obstacle_air_clear(delta),"hits":[]}
			for item:int in 3:
				var query:=PhysicsShapeQueryParameters3D.new()
				query.margin=rider.GROUND_PRESENTATION_SKIN-.00001
				query.collision_mask=1|8
				query.exclude=[rider.get_rid()]
				if item==0:
					query.shape=geometry.convex_shape
					query.transform=frame
				else:
					var bounds:AABB=rider._obstacle_shoe_bounds[item-1]
					var box:=BoxShape3D.new()
					box.size=bounds.size
					query.shape=box
					query.transform=rider._visual_rig._legs[item-1].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
					query.transform.origin+=delta
				for hit:Dictionary in space.intersect_shape(query,8):
					probe.hits.append({"part":"whole_board" if item==0 else "shoe"+str(item-1),
						"body":str(hit.collider.get_path()),"rid":hit.rid.get_id(),"shape":hit.shape})
			result.probes.append(probe)
		var face:Dictionary=rider._obstacle_air_wall
		if not face.is_empty():
			var body:CollisionObject3D=face.collider
			var index:int=face.shape
			var shape:RID=PhysicsServer3D.body_get_shape(body.get_rid(),index)
			var data:Variant=PhysicsServer3D.shape_get_data(shape)
			if data is PackedVector3Array:
				var points:Array=[]
				for point:Vector3 in data:points.append(v(point))
				data=points
			elif data is Vector3:data=v(data)
			result["native_wall"]={"path":str(body.get_path()),"rid":body.get_rid().get_id(),"shape":index,
				"type":PhysicsServer3D.shape_get_type(shape),"data":data,
				"transform":t(body.global_transform*PhysicsServer3D.body_get_shape_transform(body.get_rid(),index))}
		result["actual_components"]=[]
		for part:Dictionary in rider._grind_clearance._parts:
			var points:Array=[]
			for point:Vector3 in part.points:points.append(v(point))
			result.actual_components.append(points)
		result["rendered_meshes"]=[]
		for mesh:MeshInstance3D in geometry.meshes:
			result.rendered_meshes.append(m(mesh))
		for leg:Dictionary in rider._visual_rig._legs:
			for mesh:MeshInstance3D in leg.foot.find_children("*","MeshInstance3D",true,false):
				result.rendered_meshes.append(m(mesh))
		return result
	func m(mesh:MeshInstance3D)->Dictionary:
		var faces:Array=[]
		for point:Vector3 in mesh.mesh.get_faces():faces.append(v(point))
		return {"path":str(mesh.get_path()),"world_transform":t(mesh.global_transform),"local_triangle_vertices":faces}
	func v(a:Vector3)->Array:return [a.x,a.y,a.z]
	func t(a:Transform3D)->Dictionary:return {"x":v(a.basis.x),"y":v(a.basis.y),"z":v(a.basis.z),"origin":v(a.origin)}

func _initialize():run.call_deferred()
func run():
	var game=Main.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	var observer:=Observer.new()
	observer.rider=game.skater
	observer.process_physics_priority=200
	root.add_child(observer)
	await Lines.run_bank_jump_misses(self,game,check)
	FileAccess.open("res://.local/air-worst-frame.json",FileAccess.WRITE).store_string(JSON.stringify({"frames":observer.frames,"worst":observer.worst}))
	print("AIR WORST OBSERVER RESULT: ",passed," passed, ",failed," failed; maximum=",observer.maximum)
	observer.free()
	game.free()
	quit(1 if failed else 0)
func check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
