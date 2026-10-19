extends "res://docs/testing/map-flow/observers/ramp_camera.gd"
## Separate graphical review; readbacks explicitly excluded from timing admission.
var phases:Dictionary={}
func _initialize()->void:
	RenderingServer.frame_post_draw.connect(_phase_frame)
	create_timer(60.0,true).timeout.connect(func():printerr("Capture watchdog");quit(2))
	super._initialize()
func _capture(name: String) -> void:
	var image := root.get_texture().get_image()
	var camera: Camera3D=root.get_camera_3d()
	var rider: Node3D=game.skater
	var frame: Transform3D=rider.get_global_transform_interpolated()
	var collision: Node3D=rider.get_node("SkaterVisual") if rider.transition_active or (rider.airborne and rider._ramp_air) else rider.get_node("BodyCollision")
	var up: Vector3=collision.get_global_transform_interpolated().basis.y.normalized()
	var chest:=frame.origin+up*1.05
	var ray:=PhysicsRayQueryParameters3D.create(chest,camera.global_position,1,[rider.get_rid()])
	var blocked:=not rider.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	var body_visible:=camera.is_position_in_frustum(frame.origin+up*0.12) and camera.is_position_in_frustum(frame.origin+up*1.8)
	var path:=name+".png"
	if image.get_size()!=Vector2i(1280,800) or image.save_png(output.path_join(path))!=OK: errors.append("PNG failure "+path)
	if not body_visible or blocked or not camera.current: errors.append("Production chase obstruction/framing "+path)
	images.append({"file":path,"segment":current_id,"sim_seconds":seconds,"physics_tick":Engine.get_physics_frames(),
		"player":_v(rider.global_position),"displayed_player":_v(frame.origin),"displayed_up":_v(up),"velocity":_v(rider.velocity),"visual_forward":_v(-rider.get_node("SkaterVisual").get_global_transform_interpolated().basis.z),"camera":_v(camera.global_position),
		"camera_node":str(camera.get_path()),"fov":camera.fov,"near":camera.near,"far":camera.far,
		"body_visible":body_visible,"chest_ray_blocked":blocked,"hud_visible":game.hud.visible,"menu":game.hud._page,
		"waypoint":waypoint,"held_keys":key_states.duplicate(),"draw_frame":Engine.get_frames_drawn()})


func _phase_frame()->void:
	if not pipe_active or not is_instance_valid(game):return
	var rider:CharacterBody3D=game.skater
	var label:=""
	if rider.airborne and not rider._vert_return.is_empty():
		if rider.velocity.y>6.0 and not phases.has("ascent"):label="ascent"
		elif rider.velocity.y>0.0 and rider.velocity.y<2.0 and not phases.has("pre-apex"):label="pre-apex"
		elif rider.velocity.y<0.0 and not phases.has("first-descent"):label="first-descent"
	elif rider.transition_active and rider.velocity.y<0.0 and phases.has("first-descent") and not phases.has("re-entry"):
		label="re-entry"
	if label.is_empty():return
	phases[label]=true
	_capture("phase-"+label)
