extends SceneTree
const Test=preload("res://tests/pt24_bowl_contact_tests.gd")
const Historical=preload("res://.local/historical_bowl.gd")
const Setup=preload("res://game/core/input_setup.gd")
var failed:=0
var passed:=0
func _initialize():call_deferred("_run")
func _check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1
	print("PASS " if ok else "FAIL ",label)
func _run():
	Setup.register_actions()
	for historical:bool in [false,true]:
		var fixture:Dictionary=await Test._fixture(self)
		if historical:
			var old:Node3D=fixture.bowl
			fixture.root.remove_child(old)
			old.free()
			var bowl:Node3D=Historical.new()
			bowl.radius=2.4;bowl.floor_radius=3.5;bowl.deck_length=1.8;bowl.build_access=false
			bowl.position=Vector3(-7,-.4,134.5);bowl.rotation.y=PI*.5
			fixture.root.add_child(bowl);fixture.bowl=bowl
			await physics_frame
			await process_frame
		var rider:CharacterBody3D=fixture.rider
		for x:float in [-10.63339,-10.639068,-10.647394,-10.62713]:
			rider.global_transform=Transform3D(Basis(Vector3.UP,-PI*.5),Vector3(x,2.014172,139.5004))
			var physical:Dictionary=Test._state(rider)
			var fit:Dictionary=rider._native_board_floor()
			var data:Dictionary={"historical_profile":historical,"x":x,"fit":fit,"center":rider._native_floor_hit(Vector3.UP)}
			if not fit.is_empty():
				var pose:Transform3D=Test._presentation_pose(rider,fit)
				data.pose=pose
				data.model_clear=rider._manual_model_frame_clear(pose)
				data.tyre_volumes_clear=Test._volumes_clear(rider,pose)
				data.rim_clear=rider._native_rim_frame_clear(pose,0.0)
				data.hits=_hits(rider,pose)
				data.native_rims=_rims(rider,pose)
			else:
				var center:Dictionary=rider._native_floor_hit(Vector3.UP)
				if not center.is_empty():
					var axis:Vector3=center.normal
					var point:Vector3=rider.global_position-axis*(rider.global_position-Vector3(center.position)).dot(axis)
					var local:Vector3=rider.global_basis.inverse()*axis
					var frame:Basis=rider.global_basis*Basis.from_euler(Vector3(atan2(local.z,local.y),0,-asin(clampf(local.x,-1,1))))
					data.original_footprint_retry=rider._native_footprint_board_fit(point,axis,frame,fixture.bowl)
					var original_board:=Transform3D(frame,point+axis*.008+frame*rider._visual_rig._board_rest_position)
					data.original_native_plane_candidate=original_board
					data.original_plane_hits=_hits(rider,original_board)
					data.original_plane_rims=_rims(rider,original_board)
					var supports:Array=[]
					for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
						var bearing:Vector3=point+axis*.008+frame*(rider._visual_rig._board_rest_position+wheel.center)
						supports.append(rider._native_board_wheel_support(rider.get_world_3d().direct_space_state,bearing,fixture.bowl))
					data.original_native_wheel_supports=supports
			_check(Test._state(rider)==physical,"diagnostic native queries preserve physical state")
			print("OLD_PHASE_DIAGNOSTIC ",data)
		fixture.viewport.queue_free()
		await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _hits(rider:CharacterBody3D,pose:Transform3D)->Array:
	var hits:Array=[]
	var query:=PhysicsShapeQueryParameters3D.new()
	query.transform=pose;query.collision_mask=1|2|8;query.exclude=[rider.get_rid()];query.margin=0.0
	var space:PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
	for index:int in rider._grind_clearance._parts.size():
		query.shape=rider._grind_clearance._parts[index].shape
		for hit:Dictionary in space.intersect_shape(query,8):
			hits.append({"part":index,"rid":hit.rid,"shape":hit.shape,"body":str(hit.collider.get_path()),"rest":space.get_rest_info(query)})
	return hits

func _rims(rider:CharacterBody3D,pose:Transform3D)->Array:
	var rims:Array=[]
	var space:PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
	for index:int in rider._visual_rig.board_contact_geometry().wheels.size():
		var wheel:Dictionary=rider._visual_rig.board_contact_geometry().wheels[index]
		var minimum:float=INF
		var nearest:Dictionary={}
		var misses:=0
		for vertex:Vector3 in wheel.points:
			var at:Vector3=pose*vertex
			var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.35,1|8,[rider.get_rid()]))
			if hit.is_empty():misses+=1;continue
			var signed_gap:float=(at-Vector3(hit.position)).dot(Vector3(hit.normal))
			if signed_gap<minimum:
				minimum=signed_gap
				nearest={"vertex":at,"native_point":hit.position,"native_normal":hit.normal,"rid":hit.rid,"shape":hit.shape,
					"body":str(hit.collider.get_path()),"signed_face_gap":signed_gap,"vertical_separation":at.y-Vector3(hit.position).y}
		rims.append({"wheel":index,"missed_vertex_rays":misses,"minimum_contact":nearest,"weight_bearing_claim":false})
	return rims
