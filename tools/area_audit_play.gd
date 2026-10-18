extends SceneTree
## Six declared initial fixtures, then actual mapped inputs on production Main.
## This is six traversals, not a continuous between-district city tour or a human
## playtest. Native rendering/chase/HUD stay active throughout each traversal.
const MainScene = preload("res://game/main.tscn")
const Quality = preload("res://game/core/graphics_quality.gd")
const SIZE := Vector2i(960,600)
const MAX_SEGMENT_SECONDS := 26.0

class Driver extends Node:
	var audit: SceneTree
	func _physics_process(delta: float) -> void: audit._drive(delta)

class Recorder extends Node:
	var audit: SceneTree
	func _physics_process(delta: float) -> void: audit._sample(delta)

var game: Node
var output := ""
var active := false
var points := PackedVector3Array()
var waypoint := 1
var seconds := 0.0
var distance := 0.0
var last_position := Vector3.ZERO
var last_yaw := 0.0
var turning := 0.0
var bails := 0
var discontinuities := 0
var grounded_ticks := 0
var stalled_ticks := 0
var rows: Array[Dictionary] = []
var segments: Array[Dictionary] = []
var images: Array[Dictionary] = []
var errors: Array[String] = []
var current_id := ""
var key_states: Dictionary = {}
var steer := 0
var vertical := 0
var previous_vertical := 0
var neutral_seconds := 1.0
var max_deviation := 0.0
var started_usec := 0
var pipe_active := false
var pipe_trace: Array[Dictionary] = []
var pipe_result: Dictionary = {}


func _initialize() -> void: _run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().size() != 1:
		push_error("AREA_AUDIT requires a normal rendering display and one existing output directory")
		quit(2)
		return
	for argument: String in OS.get_cmdline_args():
		if argument.begins_with("--fixed-fps") or argument == "--disable-render-loop":
			push_error("AREA_AUDIT rejects fixed-step/disabled rendering")
			quit(2)
			return
	output = OS.get_cmdline_user_args()[0]
	if not DirAccess.dir_exists_absolute(output):
		quit(2)
		return
	started_usec = Time.get_ticks_usec()
	root.size = SIZE
	root.content_scale_size = SIZE
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game = MainScene.instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	game.apply_settings({"graphics_quality":"performance"},false)
	game.start_mode(true)
	var driver := Driver.new()
	driver.audit = self
	driver.process_physics_priority = -100
	root.add_child(driver)
	var recorder := Recorder.new()
	recorder.audit = self
	recorder.process_physics_priority = 100
	root.add_child(recorder)
	game.skater.bailed.connect(func():
		if active or pipe_active: bails += 1)
	var routes: Dictionary = {}
	for route: Dictionary in game.world.get_route_definitions(): routes[route.id] = route.points
	var specifications := [
		{"id":"royal_exchange","source":"exchange_fountain_loop first two sides","points":PackedVector3Array([Vector3(-22,0,28),Vector3(22,0,28),Vector3(22,0,-2)])},
		{"id":"george_square","source":"cat_workshop_bypass","points":routes.get("cat_workshop_bypass",PackedVector3Array())},
		{"id":"central_station","source":"station_low_level_close","points":routes.get("station_low_level_close",PackedVector3Array())},
		{"id":"barras","source":"barras_market_inner_loop","points":routes.get("barras_market_inner_loop",PackedVector3Array())},
		{"id":"clyde","source":"declared north-quay weave inside existing route corridor","points":PackedVector3Array([Vector3(-78,2,69),Vector3(-56,2,69),Vector3(-34,2,69),Vector3(-8,2,69),Vector3(16,2,69)])},
		{"id":"kelvingrove","source":"first 65m of kelvingrove_rolling_loop","points":_prefix(routes.get("kelvingrove_rolling_loop",PackedVector3Array()),65.0)}]
	for specification: Dictionary in specifications: await _segment(specification)
	await _halfpipe()
	_release()
	var adapter := RenderingServer.get_video_adapter_name()
	var report := {"schema":1,"kind":"six_area_actual_mapped_input_segments","valid":errors.is_empty() and segments.size()==6 and bool(pipe_result.get("valid",false)),
		"errors":errors,"segments":segments,"halfpipe":pipe_result,"images":images,"engine":Engine.get_version_info(),"os":OS.get_name(),
		"adapter":adapter,"display_server":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"resolution":[SIZE.x,SIZE.y],"applied_quality":"performance","quality_budget":Quality.profile("performance"),
		"physics_hz":Engine.physics_ticks_per_second,"time_scale":Engine.time_scale,"profile_writes":game.persistence_enabled,
		"native_render_loop":RenderingServer.render_loop_enabled,"wall_seconds":float(Time.get_ticks_usec()-started_usec)/1000000.0,
		"limitations":["Six independent initial fixtures; no claim of a continuous city tour or completion of all 48 routes.",
			"Feedback submits mapped physical-key events; no per-tick position, heading or speed assignment.",
			"Normal production chase/HUD/native rendering remains active. PNG readbacks are outside any performance claim.",
			"Scripted input is independent automated QE, not human fun, physical controller or target-Mac performance acceptance."]}
	var file := FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	if file == null: errors.append("Cannot write manifest")
	else: file.store_string(JSON.stringify(report,"\t"))
	print("AREA_AUDIT_RESULT segments=",segments.size()," images=",images.size()," errors=",errors)
	quit(0 if errors.is_empty() and segments.size()==6 and bool(pipe_result.get("valid",false)) else 1)


func _segment(specification: Dictionary) -> void:
	_release()
	active = false
	points = specification.points
	current_id = specification.id
	if points.size()<2:
		errors.append("Missing path "+current_id)
		return
	# Sole declared transform placement, before this trial's native simulation.
	game.skater.spawn_position = points[0]+Vector3.UP*0.8
	game.start_mode(true)
	var forward := points[1]-points[0]
	game.skater.rotation.y = atan2(-forward.x,-forward.z)
	game.skater.reset_physics_interpolation()
	var settle_start := Time.get_ticks_usec()
	var stable := 0
	while stable<3 and Time.get_ticks_usec()-settle_start<20000000:
		await RenderingServer.frame_post_draw
		stable = stable+1 if game.skater.is_on_floor() and game.skater.velocity.length()<0.05 else 0
	if stable<3: errors.append(current_id+": initial fixture lacks stable support")
	waypoint=1
	seconds=0.0
	distance=0.0
	turning=0.0
	bails=0
	discontinuities=0
	grounded_ticks=0
	stalled_ticks=0
	max_deviation=0.0
	previous_vertical=0
	vertical=0
	neutral_seconds=1.0
	last_position=game.skater.global_position
	last_yaw=game.skater.rotation.y
	var first_tick := Engine.get_physics_frames()
	var first_row := rows.size()
	var actual_start: Vector3 = game.skater.global_position
	var next_capture := 2.0
	var stage := 0
	active=true
	while seconds<MAX_SEGMENT_SECONDS and waypoint<points.size() and bails==0 and discontinuities==0:
		await RenderingServer.frame_post_draw
		if seconds>=next_capture:
			stage+=1
			_capture("%s-%02d" %[current_id,stage])
			next_capture+=5.0
	active=false
	_release()
	# Preserve the completed actual render; do not author a replacement camera.
	await RenderingServer.frame_post_draw
	_capture(current_id+"-end")
	var visited := 0
	var nonfinite := 0
	for row: Dictionary in rows.slice(first_row):
		visited += int(row.district==current_id)
		nonfinite += int(not is_finite(float(row.x)) or not is_finite(float(row.y)) or not is_finite(float(row.z)))
	var complete := waypoint>=points.size()
	var valid := complete and distance>=20.0 and seconds>=3.0 and bails==0 and discontinuities==0 and nonfinite==0 and max_deviation<=5.5 and visited>0
	if not valid: errors.append(current_id+": incomplete or invalid actual traversal")
	var path: Array = []
	for at: Vector3 in points: path.append(_v(at))
	var result := {"id":current_id,"source":specification.source,"valid":valid,"completed":complete,
		"fixture_start":_v(points[0]+Vector3.UP*0.8),"actual_start":_v(actual_start),"actual_end":_v(game.skater.global_position),
		"points":path,"waypoint":waypoint,"point_count":points.size(),"sim_seconds":seconds,"distance_m":distance,
		"turn_radians":turning,"bails":bails,"discontinuities":discontinuities,"grounded_ticks":grounded_ticks,
		"stalled_ticks":stalled_ticks,"max_corridor_deviation_m":max_deviation,"district_ticks":visited,
		"first_tick":first_tick,"last_tick":Engine.get_physics_frames(),"trace_rows":rows.size()-first_row}
	segments.append(result)
	_write_trace(current_id,rows.slice(first_row))
	print("AREA_AUDIT_SEGMENT ",JSON.stringify(result))


func _drive(delta: float) -> void:
	if pipe_active:
		_key(KEY_W,true)
		return
	if not active: return
	var at: Vector3=game.skater.global_position
	while waypoint<points.size() and Vector2(at.x-points[waypoint].x,at.z-points[waypoint].z).length()<1.1: waypoint+=1
	if waypoint>=points.size():
		_release()
		return
	var to := points[waypoint]-at
	var error := angle_difference(game.skater.rotation.y,atan2(-to.x,-to.z))
	# Binary physical keys deliberately retain imperfect steering, unlike a
	# transform-aiming fixture or direct fractional heading replacement.
	steer = 1 if error< -0.06 else (-1 if error>0.06 else 0)
	_key(KEY_D,steer>0)
	_key(KEY_A,steer<0)
	var target_speed := 2.7 if absf(error)>0.45 else 6.0
	var magnitude: float=game.skater.velocity.length()
	var command := 1 if magnitude<target_speed-0.4 else (-1 if magnitude>target_speed+0.6 else 0)
	# Do not turn ordinary feedback braking into the manual gesture. The game
	# still receives the same mapped Up/Down events a player would submit.
	if command!=0 and previous_vertical!=0 and command!=previous_vertical and vertical==0 and neutral_seconds<0.25: command=0
	if command==0: neutral_seconds+=delta
	else:
		previous_vertical=command
		neutral_seconds=0.0
	vertical=command
	_key(KEY_W,command>0)
	_key(KEY_S,command<0)


func _sample(delta: float) -> void:
	if pipe_active:
		_sample_pipe(delta)
		return
	if not active: return
	seconds+=delta
	var at: Vector3=game.skater.global_position
	var step: float=at.distance_to(last_position)
	if step>3.0: discontinuities+=1
	else: distance+=step
	turning+=absf(angle_difference(last_yaw,game.skater.rotation.y))
	last_yaw=game.skater.rotation.y
	last_position=at
	grounded_ticks+=int(game.skater.is_on_floor())
	stalled_ticks+=int(game.skater.velocity.length()<0.1 and seconds>1.0)
	var nearest := INF
	for index: int in range(points.size()-1):
		var a:=Vector2(points[index].x,points[index].z)
		var b:=Vector2(points[index+1].x,points[index+1].z)
		nearest=minf(nearest,Geometry2D.get_closest_point_to_segment(Vector2(at.x,at.z),a,b).distance_to(Vector2(at.x,at.z)))
	max_deviation=maxf(max_deviation,nearest)
	rows.append({"tick":Engine.get_physics_frames(),"sim_seconds":seconds,"x":at.x,"y":at.y,"z":at.z,
		"yaw":game.skater.rotation.y,"speed":game.skater.velocity.length(),"waypoint":waypoint,
		"steer":steer,"vertical":vertical,"floor":game.skater.is_on_floor(),"air":game.skater.airborne,
		"grinding":game.skater.grinding,"transition":game.skater.transition_active,"manual":game.skater.manual_active,
		"district":game.world.get_district_id(at),"bails":bails,"deviation":nearest})


func _halfpipe() -> void:
	_release()
	active=false
	pipe_active=false
	current_id="halfpipe"
	game.skater.spawn_position=Vector3(-42,2.8,60.5)
	game.start_mode(true)
	game.skater.rotation.y=-PI*0.5
	game.skater.reset_physics_interpolation()
	var settle_start:=Time.get_ticks_usec()
	var stable:=0
	while stable<3 and Time.get_ticks_usec()-settle_start<20000000:
		await RenderingServer.frame_post_draw
		stable=stable+1 if game.skater.is_on_floor() and game.skater.velocity.length()<0.05 else 0
	if stable<3: errors.append("halfpipe: unsupported initial fixture")
	seconds=0.0
	bails=0
	discontinuities=0
	distance=0.0
	last_position=game.skater.global_position
	waypoint=0
	var next_capture:=0.75
	var stage:=0
	pipe_active=true
	while seconds<12.0 and bails==0 and discontinuities==0:
		await RenderingServer.frame_post_draw
		if seconds>=next_capture:
			stage+=1
			_capture("halfpipe-%02d" % stage)
			next_capture+=0.75
	pipe_active=false
	_release()
	await RenderingServer.frame_post_draw
	_capture("halfpipe-end")
	var visits: Array[String]=[]
	var previous: String=""
	var finite:=true
	for row: Dictionary in pipe_trace:
		var id: String=row.wall
		if not id.is_empty() and id!=previous:
			visits.append(id)
			previous=id
		finite=finite and is_finite(float(row.x)) and is_finite(float(row.y)) and is_finite(float(row.z))
	var valid:=visits.size()>=4 and visits.has("clyde_half_east") and visits.has("clyde_half_west") and bails==0 and discontinuities==0 and finite and seconds>=12.0
	var lip_heights: Dictionary={}
	for feature: Dictionary in game.world.get_transition_features():
		var toe: Transform3D=feature.transform
		lip_heights[feature.id]=toe.origin.y+float(feature.radius)*(1.0-cos(float(feature.angle)))
	var natural:=_pipe_natural_returns(lip_heights)
	valid=valid and natural.departures>0 and natural.reentries>0 and natural.opposite_after_return
	if not valid: errors.append("halfpipe: incomplete repeated physical returns")
	pipe_result={"valid":valid,"fixture":[-42,2.8,60.5],"initial_yaw":-PI*0.5,
		"input":"held physical W only","sim_seconds":seconds,"wall_visits":visits,"bails":bails,
		"discontinuities":discontinuities,"distance_m":distance,"trace_rows":pipe_trace.size(),"natural_returns":natural}
	_write_trace("halfpipe",pipe_trace)
	print("AREA_AUDIT_HALFPIPE ",JSON.stringify(pipe_result))


func _sample_pipe(delta: float) -> void:
	seconds+=delta
	var at: Vector3=game.skater.global_position
	var step: float=at.distance_to(last_position)
	if step>3.0: discontinuities+=1
	else: distance+=step
	last_position=at
	pipe_trace.append({"tick":Engine.get_physics_frames(),"sim_seconds":seconds,"x":at.x,"y":at.y,"z":at.z,
		"yaw":game.skater.rotation.y,"velocity":_v(game.skater.velocity),"vertical_speed":game.skater.velocity.y,"air":game.skater.airborne,
		"wall":str(game.skater._transition.feature.get("id","")) if game.skater.transition_active else "",
		"theta":game.skater._transition.theta if game.skater.transition_active else 0.0,"bails":bails})


func _pipe_natural_returns(lip_heights: Dictionary) -> Dictionary:
	var departures:=0
	var reentries:=0
	var opposite_after_return:=false
	var previous: Dictionary={}
	var pending: String=""
	var recaptured: String=""
	for row: Dictionary in pipe_trace:
		var id: String=row.wall
		if not previous.is_empty() and not str(previous.wall).is_empty() and float(previous.theta)>=deg_to_rad(65.0) \
				and id.is_empty() and row.air and float(row.vertical_speed)>1.0 \
				and absf(float(row.y)-float(lip_heights.get(previous.wall,INF)))<=0.25:
			pending=previous.wall
			departures+=1
		if not pending.is_empty():
			if id==pending and float(row.vertical_speed)<0.0 and not previous.is_empty() and previous.air:
				reentries+=1
				recaptured=pending
				pending=""
			elif (not id.is_empty() and id!=pending) or (id.is_empty() and not row.air): pending=""
		if id in ["clyde_half_east","clyde_half_west"] and not recaptured.is_empty() and id!=recaptured:
			opposite_after_return=true
		previous=row
	return {"departures":departures,"reentries":reentries,"opposite_after_return":opposite_after_return}


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
	if image.get_size()!=SIZE or image.save_png(output.path_join(path))!=OK: errors.append("PNG failure "+path)
	if not body_visible or blocked or not camera.current: errors.append("Production chase obstruction/framing "+path)
	images.append({"file":path,"segment":current_id,"sim_seconds":seconds,"physics_tick":Engine.get_physics_frames(),
		"player":_v(rider.global_position),"displayed_player":_v(frame.origin),"camera":_v(camera.global_position),
		"camera_node":str(camera.get_path()),"fov":camera.fov,"near":camera.near,"far":camera.far,
		"body_visible":body_visible,"chest_ray_blocked":blocked,"hud_visible":game.hud.visible,"menu":game.hud._page,
		"waypoint":waypoint,"held_keys":key_states.duplicate(),"draw_frame":Engine.get_frames_drawn()})


func _key(code: Key, down: bool) -> void:
	if bool(key_states.get(code,false))==down: return
	key_states[code]=down
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _release() -> void:
	for code: Key in [KEY_W,KEY_S,KEY_A,KEY_D,KEY_SPACE,KEY_L,KEY_J,KEY_K]: _key(code,false)
	for action: StringName in InputMap.get_actions(): Input.action_release(action)


func _write_trace(id: String, trace: Array) -> void:
	var file:=FileAccess.open(output.path_join(id+"-trace.json"),FileAccess.WRITE)
	if file==null: errors.append("Trace write failed "+id)
	else: file.store_string(JSON.stringify(trace))


func _prefix(source: PackedVector3Array, metres: float) -> PackedVector3Array:
	var result:=PackedVector3Array()
	var walked:=0.0
	for point: Vector3 in source:
		if not result.is_empty(): walked+=result[-1].distance_to(point)
		result.append(point)
		if walked>=metres: break
	return result


func _v(at: Vector3) -> Array: return [at.x,at.y,at.z]
