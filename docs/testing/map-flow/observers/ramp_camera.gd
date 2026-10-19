extends "res://tools/area_audit_play.gd"
## Bounded natural half-pipe trial; one initial fixture, held W, then real cycles.
var camera_rows:Array=[]
func _run()->void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
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
	game.skater.bailed.connect(func():if pipe_active:bails+=1)
	await _halfpipe()
	pipe_result.valid=pipe_result.valid and errors.is_empty()
	pipe_result.errors=errors
	var file:=FileAccess.open(output.path_join("camera.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"trial":pipe_result,"camera_rows":camera_rows,"images":images,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name()},"\t"))
	print("RESULT: ",1 if pipe_result.valid else 0," passed, ",0 if pipe_result.valid else 1," failed")
	quit(0 if pipe_result.valid else 1)
func _sample_pipe(delta:float)->void:
	super._sample_pipe(delta)
	var camera:Camera3D=root.get_camera_3d()
	var normal:Vector3=game.skater.transition_normal if game.skater.transition_active else Vector3.UP
	var rider:Vector3=game.skater.global_position
	camera_rows.append({"tick":Engine.get_physics_frames(),"seconds":seconds,"rider":_v(rider),"velocity":_v(game.skater.velocity),"camera":_v(camera.global_position),"target_direction":_v(-camera.global_basis.z),"fov":camera.fov,"board_screen":str(camera.unproject_position(rider+normal*.12)),"head_screen":str(camera.unproject_position(rider+normal*1.8)),"return_armed":not game.skater._vert_return.is_empty(),"wall":str(game.skater._transition.feature.get("id","")) if game.skater.transition_active else ""})


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

