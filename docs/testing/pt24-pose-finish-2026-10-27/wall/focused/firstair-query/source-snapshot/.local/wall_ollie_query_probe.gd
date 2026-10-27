extends SceneTree
const Wall = preload("res://tests/skater_wall_presentation_tests.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	Wall.Setup.register_actions()
	var f: Dictionary=await Wall._fixture(self,-8.0)
	var r: CharacterBody3D=f.rider
	Input.action_press("push",0.55)
	for tick: int in 180:
		await Wall._frames(self,1)
		if Wall._wall_contact(r,f.wall):break
	Wall._release()
	Input.action_press("brake")
	await Wall._frames(self,20)
	Wall._release()
	await Wall._frames(self,2)
	Input.action_press("ollie")
	await Wall._frames(self,12)
	var prior: Vector3=r._obstacle_visual_offset
	Input.action_release("ollie")
	await Wall._frames(self,1)
	var query: PhysicsShapeQueryParameters3D=r._grind_board_query
	var box: BoxShape3D=r._grind_board_box
	var space := r.get_world_3d().direct_space_state
	query.margin=0.00799
	var pose: Transform3D=r._board_visual.global_transform
	pose.origin+=prior
	query.transform=pose*Transform3D(Basis.IDENTITY,r.GRIND_BOARD_CENTER)
	print("DIAG_FIRST_AIR ",{"prior":prior,"at":r.global_position,"local_board":r._board_visual.transform,"gap_actual":Wall._plane_gap(r),"component_count":r._grind_clearance.component_count,"bounds":r._obstacle_shoe_bounds,"board_pose":pose,"box_rest":space.get_rest_info(query),"box_hits":space.intersect_shape(query,8)})
	for index: int in r._visual_rig._legs.size():
		var bounds: AABB=r._obstacle_shoe_bounds[index]
		box.size=bounds.size
		var shoe: Transform3D=r._visual_rig._legs[index].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
		shoe.origin+=prior
		query.transform=shoe
		print("DIAG_SHOE ",{"index":index,"pose":shoe,"size":box.size,"rest":space.get_rest_info(query),"hits":space.intersect_shape(query,8)})
	Wall._release()
	f.viewport.queue_free()
	await process_frame
	quit()
