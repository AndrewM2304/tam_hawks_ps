extends SceneTree
## Actual native Manual poses. Only prior/current arm helper differs.
const Current=preload("res://game/player/skater.gd")
const Legacy=preload("res://.local/manual_arm_before_helper.gd")
const Gate=preload("res://game/features/service_gate.gd")
const Setup=preload("res://game/core/input_setup.gd")
const ArmTests=preload("res://tests/skater_obstacle_arm_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const SIZE:=Vector2i(960,640)
const OUTPUT:="res://.local/manual-arm-captures"
const NORTH_FACE:=-0.09
var camera: Camera3D
var actor: CharacterBody3D
var gate: Node3D
var arm_data: Dictionary
var records: Array[Dictionary]=[]
var actor_records: Array[Dictionary]=[]
var failures:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	Setup.register_actions()
	_release()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size=SIZE
	root.content_scale_size=SIZE
	var before := _sources()
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color("9aaebd")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color.WHITE
	settings.ambient_light_energy=0.8
	env.environment=settings
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-25,0)
	sun.light_energy=1.6
	sun.shadow_enabled=true
	root.add_child(sun)
	var floor := StaticBody3D.new()
	floor.name="Declared20mFloor"
	root.add_child(floor)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(20,0.2,20)
	collision.shape=box
	collision.position.y=-0.1
	floor.add_child(collision)
	var displayed := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size=box.size
	displayed.mesh=floor_mesh
	displayed.position.y=-0.1
	var material := StandardMaterial3D.new()
	material.albedo_color=Color("777d7b")
	displayed.material_override=material
	floor.add_child(displayed)
	gate=Gate.new()
	root.add_child(gate)
	gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	camera=Camera3D.new()
	camera.near=0.04
	root.add_child(camera)
	for ordinary: bool in [false,true]:
		for legacy: bool in [true,false]:await _variant(legacy,ordinary)
	if records.size()!=6:failures+=1
	var paired: Dictionary={}
	for frame: Dictionary in records:
		var key: String=frame.pose.kind+"-"+frame.pose.stage
		if not paired.has(key):paired[key]={}
		paired[key][frame.pose.variant]=frame
	for key: String in paired:
		if not paired[key].has("before") or not paired[key].has("after"):failures+=1;continue
		var before_frame: Dictionary=paired[key].before;var after_frame: Dictionary=paired[key].after
		var old_pose: Dictionary=before_frame.pose;var new_pose: Dictionary=after_frame.pose
		if old_pose.physics_position!=new_pose.physics_position or old_pose.physics_velocity!=new_pose.physics_velocity \
			or old_pose.physics_heading!=new_pose.physics_heading or old_pose.native_tick!=new_pose.native_tick \
			or old_pose.visual_frame!=new_pose.visual_frame or old_pose.board_local_transform!=new_pose.board_local_transform \
			or old_pose.nonarm!=new_pose.nonarm:failures+=1
		if int(old_pose.actual_arms.panel_skin_vertices)<=0 or int(new_pose.actual_arms.panel_skin_vertices)!=0:failures+=1
		for variant: Dictionary in [old_pose,new_pose]:
			if float(variant.actual_geometry.board_clearance_m)<0.0079 or float(variant.actual_geometry.shoe_clearance_m)<0.0079:failures+=1
		for counter: String in ["draw_calls","primitives","objects","texture_bytes"]:
			if before_frame[counter]!=after_frame[counter]:failures+=1
	var after:=_sources()
	if before!=after:failures+=1
	var manifest: Dictionary={"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"size":[SIZE.x,SIZE.y],
		"frames":records,"actors":actor_records,"failures":failures,"source_stable":before==after,"source_before":before,"source_after":after,
		"legacy":JSON.parse_string(FileAccess.get_file_as_string("res://.local/manual_arm_before_sources.json")),
		"method":"Six actual native PNG readbacks. Both variants use the exact same current Skater/Visual/root floor fit/assets; before assigns exact immutable e0c9427 arm helper before tree entry, after uses the normal new helper. Nose route starts once at(0,.04,-3.02),headingPI,4settle,Push(.55),freshManual afterspeed2.5;capture active78 and residualimpact+20(99),Brakefromimpact79. Ordinary route starts once at(0,.04,-6),Push(.55) to4.5m/s,release and12neutral ticks,freshManual;capture actual first earnedfit103 beforeimpact104. Freeze completed native actor processing/reset interpolation only for fixed-camera frame_post_draw readback. No actor pose/velocity/trick assignment after entry. Paired physics/commonroot/localboard/nonarm and native support remain unchanged; original Skin/curl finite-panel samples must clear8mm. Exact draw/object/primitive/texture counts required. Static views do not certify motion, allvariants, target frame times or Mac."}
	var file:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t")+"\n");file.close()
	print("MANUAL_ARM_CAPTURE frames=",records.size()," failures=",failures," source_stable=",before==after)
	quit(1 if failures else 0)
func _variant(legacy: bool,ordinary: bool) -> void:
	_release();actor=Current.new()
	if legacy:actor._obstacle_arm_fit=Legacy.new()
	actor.spawn_position=Vector3(0,0.04,-6.0 if ordinary else -3.02);root.add_child(actor);actor.rotation.y=PI
	arm_data=ArmTests._skin_data(actor,gate);camera.make_current()
	for tick: int in 4:await _frame()
	var impact:=-1;var contacts:=0;var requested:=false;var release_tick:=-1;var request_tick:=-1;var entry_speed:=0.0
	var events: Array[Dictionary]=[]
	actor.trick_performed.connect(func(label: String,points: int):events.append({"id":actor.last_trick_id,"label":label,"points":points}))
	Input.action_press("push",0.55)
	for tick: int in 180:
		if ordinary:
			if release_tick<0 and absf(actor.speed)>=4.5 and actor.global_position.z< -2.0:release_tick=tick;Input.action_release("push")
			elif release_tick>=0 and request_tick<0 and tick-release_tick>=12:request_tick=tick;Input.action_press("manual")
		elif not requested and absf(actor.speed)>=2.5 and actor.global_position.z< -1.0:requested=true;Input.action_press("manual")
		await _frame()
		if actor.manual_active and entry_speed==0.0:entry_speed=absf(actor.speed)
		for slide: int in actor.get_slide_collision_count():
			if actor.get_slide_collision(slide).get_collider()==gate._panel:contacts+=1
		if impact<0 and contacts>0:impact=tick;Input.action_release("push");Input.action_press("brake")
		var stage: String=""
		if ordinary and tick==103:stage="first-fit"
		elif not ordinary and tick==78:stage="active"
		elif not ordinary and impact>=0 and tick-impact==20:stage="residual"
		if stage=="":continue
		actor.set_physics_process(false);actor.set_process(false);actor.reset_physics_interpolation()
		var expected: String="manual" if ordinary else "nose_manual"
		if actor.bailing or not actor.is_on_floor() or entry_speed<2.0 or not actor._obstacle_manual_continuation:failures+=1
		if stage!="residual" and (not actor.manual_active or impact>=0):failures+=1
		if stage=="residual" and (actor.manual_active or actor._visual_rig._manual_blend<=0.0001 or impact<0):failures+=1
		if actor.manual_trick_id!=expected or events.size()!=1 or events[0].id!=expected or events[0].points!=100:failures+=1
		var receipt: Dictionary={"variant":"before" if legacy else "after","kind":"ordinary" if ordinary else "nose","stage":stage,
			"native_tick":tick,"input_contact_tick":impact,"actual_panel_contacts":contacts,"entry_speed":entry_speed,"release_tick":release_tick,"request_tick":request_tick,
			"physics_position":_v(actor.global_position),"physics_velocity":_v(actor.velocity),"physics_heading":actor.rotation.y,"physics_speed":actor.speed,
			"manual_active":actor.manual_active,"manual_id":actor.manual_trick_id,"manual_blend":actor._visual_rig._manual_blend,
			"visual_frame":_transform(actor._visual.transform),"board_local_transform":_transform(actor._board_visual.transform),"nonarm":ArmTests._nonarm(actor),
			"events":events.duplicate(true),"actual_geometry":_measure(false),"interpolated_geometry":_measure(true),"actual_arms":_measure_arms()}
		actor_records.append(receipt);camera.position=Vector3(2.6,1.4,-1.8);camera.fov=43;camera.look_at(Vector3(0,0.85,-0.25))
		await _capture(receipt.variant+"-"+receipt.kind+"-"+stage,receipt)
		if ordinary or stage=="residual":break
		actor.set_physics_process(true);actor.set_process(true)
	_release();actor.queue_free();await process_frame;await physics_frame;await process_frame
func _measure_arms() -> Dictionary:
	var rig: RefCounted=actor._visual_rig
	var skeleton: Skeleton3D=rig._garments.skeleton
	var jacket: MeshInstance3D=arm_data.jacket
	var palette: Array[Transform3D]=[]
	for bind: int in jacket.skin.get_bind_count():palette.append(skeleton.global_transform*skeleton.get_bone_global_pose(Body._bone_for(jacket.skin,skeleton,bind))*jacket.skin.get_bind_pose(bind))
	var panel:=AABB(-gate._shape.size*0.5,gate._shape.size).grow(0.00799)
	var near_sleeve:=INF;var near_hand:=INF;var hits:=0;var count:=0
	for index: int in 2:
		for record: Dictionary in arm_data.sleeves[index]:
			var point:=Vector3.ZERO
			for influence: int in record.binds.size():point+=(palette[record.binds[influence]]*Vector3(record.point))*float(record.weights[influence])
			if index==0:near_sleeve=minf(near_sleeve,NORTH_FACE-point.z)
			hits+=int(panel.has_point(gate._panel.to_local(point)));count+=1
		var mesh: MeshInstance3D=rig._arms[index].hand.get_node("HandAndFingers")
		for record: Dictionary in arm_data.hands[index]:
			var point: Vector3=mesh.to_global(Vector3(record.base).lerp(Vector3(record.curl),mesh.get_blend_shape_value(0)))
			if index==0:near_hand=minf(near_hand,NORTH_FACE-point.z)
			hits+=int(panel.has_point(gate._panel.to_local(point)));count+=1
	return {"panel_skin_vertices":hits,"original_skin_curl_vertices":count,"near_sleeve_clearance_m":near_sleeve,"near_hand_clearance_m":near_hand}

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

func _sources() -> Dictionary:
	var files:=PackedStringArray(["res://project.godot","res://.local/manual_arm_capture.gd","res://.local/manual_arm_capture.sh","res://.local/manual_arm_before_helper.gd","res://.local/manual_arm_before_sources.json"])
	_collect("res://game",files);files.sort()
	var result: Dictionary={}
	for path: String in files:result[path]=FileAccess.get_sha256(path)
	return result
func _collect(path: String,files: PackedStringArray) -> void:
	var directory:=DirAccess.open(path)
	for name: String in directory.get_files():files.append(path.path_join(name))
	for name: String in directory.get_directories():_collect(path.path_join(name),files)
