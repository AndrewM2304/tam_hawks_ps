extends "res://tools/area_audit_play.gd"
## Continuous actual mapped keyboard drive from production spawn; no resets.
func _run()->void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().size()!=1:quit(2);return
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game=MainScene.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.apply_settings({"graphics_quality":"balanced"},false)
	game.start_mode(true)
	var driver:=Driver.new()
	driver.audit=self
	driver.process_physics_priority=-100
	root.add_child(driver)
	var recorder:=Recorder.new()
	recorder.audit=self
	recorder.process_physics_priority=100
	root.add_child(recorder)
	game.skater.bailed.connect(func():if active:bails+=1)
	points=PackedVector3Array([Vector3(-22,0,28),Vector3(-22,2,-42),Vector3(-22,4,-80),Vector3(-22,6,-122),Vector3(-42,6,-122),Vector3(-95,6,-123.54),Vector3(-145,6,-125),Vector3(-145,6,-104),Vector3(-155,6,-82)])
	var return_points:=points.duplicate()
	return_points.reverse()
	points.append_array(return_points.slice(1))
	for frame:int in 60:await RenderingServer.frame_post_draw
	current_id="spawn-park-roundtrip"
	waypoint=1
	last_position=game.skater.global_position
	last_yaw=game.skater.rotation.y
	active=true
	var next_capture:=0.0
	while seconds<150 and waypoint<points.size() and bails==0:
		await RenderingServer.frame_post_draw
		if seconds>=next_capture:
			_capture("approach-%03d"%roundi(seconds))
			next_capture+=10
	active=false
	_release()
	_capture("approach-end")
	_write_trace(current_id,rows)
	var valid:=waypoint>=points.size() and bails==0 and discontinuities==0 and is_finite(distance) and distance>500 and max_deviation<=5.5 and errors.is_empty()
	var file:=FileAccess.open(output.path_join("approach.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"valid":valid,"errors":errors,"seconds":seconds,"waypoint":waypoint,"points":points,"distance":distance,"bails":bails,"discontinuities":discontinuities,"max_deviation":max_deviation,"actual_end":str(game.skater.global_position),"images":images,"limits":"One bounded keyboard driver, no per-tick transforms/velocity assignment; not human fun or controller comfort."},"\t"))
	print("RESULT: ",1 if valid else 0," passed, ",0 if valid else 1," failed")
	quit(0 if valid else 1)

# Neutral for longer than the 220ms manual gesture before opposite push/brake.
# The old inherited driver could send a direct opposite command and enter a
# manual accidentally; preserve that failed trial rather than changing physics.
func _drive(delta:float)->void:
	if not active:return
	var at:Vector3=game.skater.global_position
	while waypoint<points.size() and Vector2(at.x-points[waypoint].x,at.z-points[waypoint].z).length()<1.1:waypoint+=1
	if waypoint>=points.size():_release();return
	var to:=points[waypoint]-at
	var error:=angle_difference(game.skater.rotation.y,atan2(-to.x,-to.z))
	steer=1 if error<-.06 else (-1 if error>.06 else 0)
	_key(KEY_D,steer>0)
	_key(KEY_A,steer<0)
	var target_speed:=2.7 if absf(error)>.45 else 6.0
	var magnitude:float=game.skater.velocity.length()
	var command:=1 if magnitude<target_speed-.4 else (-1 if magnitude>target_speed+.6 else 0)
	if command!=0 and previous_vertical!=0 and command!=previous_vertical and neutral_seconds<.25:command=0
	if command==0:neutral_seconds+=delta
	else:
		previous_vertical=command
		neutral_seconds=0
	vertical=command
	_key(KEY_W,command>0)
	_key(KEY_S,command<0)


func _capture(name: String) -> void:
	var image := root.get_texture().get_image()
	var camera: Camera3D=root.get_camera_3d()
	var rider: Node3D=game.skater
	var frame: Transform3D=rider.get_global_transform_interpolated()
	var collision: Node3D=rider.get_node("BodyCollision")
	var up: Vector3=collision.get_global_transform_interpolated().basis.y.normalized()
	var chest:=frame.origin+up*1.05
	var ray:=PhysicsRayQueryParameters3D.create(chest,camera.global_position,1,[rider.get_rid()])
	var blocked:=not rider.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	var body_visible:=camera.is_position_in_frustum(frame.origin+up*0.12) and camera.is_position_in_frustum(frame.origin+up*1.8)
	var path:=name+".png"
	if image.get_size()!=Vector2i(1280,800) or image.save_png(output.path_join(path))!=OK: errors.append("PNG failure "+path)
	if not body_visible or blocked or not camera.current: errors.append("Production chase obstruction/framing "+path)
	images.append({"file":path,"segment":current_id,"sim_seconds":seconds,"physics_tick":Engine.get_physics_frames(),
		"player":_v(rider.global_position),"displayed_player":_v(frame.origin),"camera":_v(camera.global_position),
		"camera_node":str(camera.get_path()),"fov":camera.fov,"near":camera.near,"far":camera.far,
		"body_visible":body_visible,"chest_ray_blocked":blocked,"hud_visible":game.hud.visible,"menu":game.hud._page,
		"waypoint":waypoint,"held_keys":key_states.duplicate(),"draw_frame":Engine.get_frames_drawn()})

