extends SceneTree
const Main=preload("res://game/main.gd")
const Flagship=preload("res://tests/pt24_flagship_runs_tests.gd")
const BoardGeometry=preload("res://tests/board_geometry_tests_support.gd")
const Footwear=preload("res://game/player/skater_footwear.gd")
var passed:=0
var failed:=0
var diagnosed:=false
func _initialize(): _run.call_deferred()
func _check(ok:bool,label:String):
	if ok: passed+=1
	else: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _observe(phase:String,game:Node,tick:int):
	if diagnosed or tick%8!=0:return
	var rider=game.skater
	var camera:Camera3D=rider._camera
	var rig=rider._visual_rig
	var chase=rider._camera_follow
	var named:Array=[{"kind":"head.global_position","point":rig._head.global_position},{"kind":"board_visual.global_position","point":rider._board_visual.global_position}]
	for mesh:MeshInstance3D in BoardGeometry.visible_meshes(rig):
		var hull:ConvexPolygonShape3D=mesh.mesh.create_convex_shape(true,false)
		for index:int in hull.points.size():named.append({"kind":"board_hull:"+str(mesh.get_path())+":"+str(index),"point":mesh.to_global(hull.points[index])})
	for index:int in rig._legs.size():
		var foot:Node3D=rig._legs[index].foot
		named.append({"kind":"sole:"+str(index),"point":foot.to_global(Footwear.SOLE_CONTACT)})
		named.append({"kind":"toe:"+str(index),"point":foot.to_global(Footwear.TOE_CONTACT)})
	var space:PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
	var excluded:Array[RID]=[rider.get_rid()]
	for marker:Dictionary in named:
		var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,marker.point,1|8,excluded))
		if hit.is_empty():continue
		diagnosed=true
		print("STATION_CAMERA_DIAGNOSTIC phase=",phase," tick=",tick," marker_kind=",marker.kind," marker=",marker.point," hit=",hit.position," collider=",hit.collider.get_path())
		print("STATION_CAMERA_STATE rider=",rider.global_position," camera=",camera.global_position," anchor=",chase._last_anchor," actual_head=",rig._head.global_position," rendered_head=",chase._follow_transform(rig._head).origin," head_targets=",chase._head_targets," selected_angle=",chase._selected_angle," rear=",chase._world_rear," pitch=",chase._motion_pitch," min_arm=",chase._minimum_arm," ramp=",chase._ramp_mode," queries=",chase.last_update_queries)
		var board:Vector3=chase._follow_transform(rider).origin
		print("STATION_CAMERA_EMITTED_USABLE ",chase._usable(space,board,chase._last_anchor,camera.global_position,excluded))
		var distance:float=4.9+clampf(Vector2(chase._travel_velocity.x,chase._travel_velocity.z).length(),0,15)*.02
		for angle:float in [0.0]+chase.ORBIT_ANGLES:
			for height:float in [chase.NORMAL_HEIGHT,chase.LOW_HEIGHT,7.2]:
				var candidate:Dictionary=chase._candidate(space,chase._last_anchor,board,chase._world_rear,distance,angle,height,excluded)
				print("STATION_CAMERA_CANDIDATE angle=",angle," height=",height," result=",candidate)
		return
func _run():
	var game:=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	for tick in 12:
		await physics_frame
		await process_frame
	await Flagship._station(self,game,_check,_observe)
	game.queue_free()
	for tick in 3:
		await physics_frame
		await process_frame
	print("RESULT: %d passed, %d failed diagnosed=%s"%[passed,failed,diagnosed])
	quit(1 if failed else 0)
