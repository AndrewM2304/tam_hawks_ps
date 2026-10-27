extends SceneTree
## Two original native stop83 poses, old/new visual with current controller.
const Current=preload("res://game/player/skater.gd")
const Before=preload("res://.local/gait_capture_before_skater.gd")
const Gate=preload("res://game/features/service_gate.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Grade=preload("res://tests/pt24_manual_grade_tests.gd")
const SIZE:=Vector2i(960,640)
const OUTPUT:="res://.local/gait-stop-captures"
const NORTH_FACE:=-0.09
var camera: Camera3D
var actor: CharacterBody3D
var gate: Node3D
var records: Array[Dictionary]=[]
var actor_records: Array[Dictionary]=[]
var failures:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	Setup.register_actions();_release();DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size=SIZE;root.content_scale_size=SIZE
	var sources:=_sources()
	var env:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("9aaebd")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=0.8
	env.environment=settings;root.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.6;sun.shadow_enabled=true;root.add_child(sun)
	var floor:=StaticBody3D.new();root.add_child(floor)
	var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(20,0.2,20);collision.shape=box;collision.position.y=-0.1;floor.add_child(collision)
	var display:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=box.size;display.mesh=mesh;display.position.y=-0.1
	var material:=StandardMaterial3D.new();material.albedo_color=Color("777d7b");display.material_override=material;floor.add_child(display)
	gate=Gate.new();root.add_child(gate);gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	camera=Camera3D.new();camera.near=0.04;root.add_child(camera)
	var twins: Array[CharacterBody3D]=[Before.new(),Current.new()]
	for rider: CharacterBody3D in twins:
		rider.spawn_position=Vector3(0,0.04,-3.02);root.add_child(rider);rider.rotation.y=PI
		rider.set_meta("gait_capture_events",[]);rider.trick_performed.connect(_on_trick.bind(rider))
	camera.make_current()
	for tick: int in 4:await _frame()
	var requested:=false;var input_impact:=-1;var impacts: Array[int]=[-1,-1]
	var previous: Array[Array]=[[],[]];var previous_rotation: Array[Quaternion]=[Quaternion.IDENTITY,Quaternion.IDENTITY]
	var steps: Array[float]=[0.0,0.0];var yaw_steps: Array[float]=[0.0,0.0]
	var physical:=true;var history: Array[Dictionary]=[]
	Input.action_press("push",0.55)
	for tick: int in 84:
		if not requested and absf(twins[0].speed)>=2.5 and twins[0].global_position.z< -1.0:requested=true;Input.action_press("manual")
		await _frame()
		physical=physical and Grade._physics(twins[0])==Grade._physics(twins[1])
		for index: int in 2:
			actor=twins[index]
			for slide: int in actor.get_slide_collision_count():
				if impacts[index]<0 and actor.get_slide_collision(slide).get_collider()==gate._panel:impacts[index]=tick
			var points:=_shoe_points();var rotation: Quaternion=actor._visual_rig._legs[1].foot.global_basis.get_rotation_quaternion()
			if previous[index].size()==points.size():
				steps[index]=0.0
				for vertex: int in points.size():steps[index]=maxf(steps[index],Vector3(previous[index][vertex]).distance_to(points[vertex]))
				yaw_steps[index]=previous_rotation[index].angle_to(rotation)
			previous[index]=points;previous_rotation[index]=rotation
			if tick>=75:history.append({"tick":tick,"variant":"before" if index==0 else "after","physical":Grade._physics(actor)})
		if input_impact<0 and impacts[0]>=0:input_impact=tick;Input.action_release("push");Input.action_press("brake")
	if not physical:failures+=1
	for rider: CharacterBody3D in twins:rider.set_physics_process(false);rider.set_process(false);rider.reset_physics_interpolation()
	for index: int in 2:
		actor=twins[index];var events: Array=actor.get_meta("gait_capture_events")
		if impacts[index]!=79 or actor.manual_active or actor.bailing or not actor.is_on_floor() or events!=[{"id":"nose_manual","points":100}]:failures+=1
		var receipt: Dictionary={"variant":"before" if index==0 else "after","stage":"stop83","native_tick":83,"input_contact_tick":impacts[index],
			"physics_position":_v(actor.global_position),"physics_velocity":_v(actor.velocity),"physics_heading":actor.rotation.y,"physics_speed":actor.speed,
			"board_local_transform":_transform(actor._board_visual.transform),"events":events.duplicate(true),"shoe_corner_step":steps[index],"shoe_yaw_step":yaw_steps[index],
			"foot_body":_v(actor.to_local(actor._visual_rig._legs[1].foot.global_position)),"actual_geometry":_measure(false)}
		actor_records.append(receipt)
		twins[0]._visual.visible=index==0;twins[1]._visual.visible=index==1
		camera.position=Vector3(-2.4,0.8,-1.6);camera.fov=43;camera.look_at(Vector3(0,0.70,-0.48))
		await _capture(receipt.variant+"-stop83",receipt)
	_release()
	var old: Dictionary=actor_records[0];var changed: Dictionary=actor_records[1]
	for key: String in ["physics_position","physics_velocity","physics_heading","physics_speed","board_local_transform","events","input_contact_tick"]:
		if old[key]!=changed[key]:failures+=1
	if old.shoe_corner_step<0.25 or changed.shoe_corner_step>=0.10 or old.shoe_yaw_step<=changed.shoe_yaw_step:failures+=1
	for key: String in ["draw_calls","primitives","objects","texture_bytes","video_bytes"]:
		if records[0][key]!=records[1][key]:failures+=1
	var after:=_sources()
	if sources!=after:failures+=1
	var manifest: Dictionary={"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"frames":records,"actors":actor_records,
		"failures":failures,"physical_history_equal":physical,"history":history,"source_before":sources,"source_after":after,"source_stable":sources==after,
		"method":"Two simultaneous genuine Push/Manual native stop83 poses on original shared ServiceGate/floor. Both rigs are built and rendered throughout the same input history before hiding only the opposite figure for each readback. Before uses immutable98311 visual in exact current controller; after current visual. Initial spawn only; actual contact79 triggers Brake. Freeze completed pose for identical camera and native frame_post_draw. Measure full actual right shoe corners and yaw82to83, unchanged physical/board/events, and matched draw/primitive/object/texture/video counters. Two static PNGs do not certify full motion or target performance."}
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t")+"\n");file.close()
	print("GAIT_CAPTURE frames=",records.size()," failures=",failures," source_stable=",sources==after)
	quit(1 if failures else 0)

func _on_trick(_label: String,points: int,rider: CharacterBody3D) -> void:
	var events: Array=rider.get_meta("gait_capture_events");events.append({"id":rider.last_trick_id,"points":points})

func _shoe_points() -> Array[Vector3]:
	var result: Array[Vector3]=[];var foot: Node3D=actor._visual_rig._legs[1].foot
	for point: Vector3 in actor._visual_rig._sole_points:result.append(foot.to_global(point))
	return result

func _sources() -> Dictionary:
	var files:=PackedStringArray(["res://project.godot","res://.local/gait_stop_capture.gd","res://.local/gait_stop_capture.sh",
		"res://.local/gait_capture_before_skater.gd","res://.local/gait_capture_before_visual.gd","res://.local/gait_capture_provenance.json"])
	_collect("res://game",files);files.sort();var result: Dictionary={}
	for path: String in files:result[path]=FileAccess.get_sha256(path)
	return result
func _collect(path: String,files: PackedStringArray) -> void:
	var directory:=DirAccess.open(path)
	for name: String in directory.get_files():files.append(path.path_join(name))
	for name: String in directory.get_directories():_collect(path.path_join(name),files)

func _measure(interpolated: bool) -> Dictionary:
	var rig: RefCounted=actor._visual_rig
	var board_front := -INF
	var shoe_front := -INF
	var board_vertices := 0
	var shoe_vertices := 0
	for mesh: MeshInstance3D in rig.board_contact_geometry().meshes:
		var frame: Transform3D=mesh.get_global_transform_interpolated() if interpolated else mesh.global_transform
		for point: Vector3 in mesh.mesh.get_faces():
			board_front=maxf(board_front,(frame*point).z)
			board_vertices+=1
	for leg: Dictionary in rig._legs:
		for mesh: MeshInstance3D in leg.foot.find_children("*","MeshInstance3D",true,false):
			var frame: Transform3D=mesh.get_global_transform_interpolated() if interpolated else mesh.global_transform
			for point: Vector3 in mesh.mesh.get_faces():
				shoe_front=maxf(shoe_front,(frame*point).z)
				shoe_vertices+=1
	return {"board_vertices":board_vertices,"shoe_vertices":shoe_vertices,
		"board_front_z":board_front,"shoe_front_z":shoe_front,"wall_north_face_z":NORTH_FACE,
		"board_clearance_m":NORTH_FACE-board_front,"shoe_clearance_m":NORTH_FACE-shoe_front}

func _capture(label: String,receipt: Dictionary) -> void:
	camera.make_current()
	camera.reset_physics_interpolation()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var path := OUTPUT+"/"+label+".png"
	if frame.get_size()!=SIZE or frame.save_png(path)!=OK:failures+=1
	records.append({"file":label+".png","sha256":FileAccess.get_sha256(path),
		"dimensions":[frame.get_width(),frame.get_height()],"camera_position":_v(camera.position),
		"camera_fov":camera.fov,"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),
		"pose":receipt,"draw_geometry":_measure(true),"physics_geometry":_measure(false),"frozen_physics":not actor.is_physics_processing(),"frozen_process":not actor.is_processing(),
		"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"objects":int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))})
	print("WALL_CAPTURE_FRAME ",label," actual=",receipt.actual_geometry)

func _frame() -> void:
	await physics_frame
	await process_frame

func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)

func _v(value: Vector3) -> Array:return [value.x,value.y,value.z]
func _transform(value: Transform3D) -> Array:return [_v(value.basis.x),_v(value.basis.y),_v(value.basis.z),_v(value.origin)]
func _vector(value: Array) -> Vector3:return Vector3(value[0],value[1],value[2])
