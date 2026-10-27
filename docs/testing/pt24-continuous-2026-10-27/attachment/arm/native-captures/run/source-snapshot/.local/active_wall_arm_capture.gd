extends SceneTree
## Completed native input-contact poses, before/after the connected wall fit.
## The legacy controller is immutable cd661ca; both use the same current rig.
const Current = preload("res://game/player/skater.gd")
const Legacy = preload("res://.local/active_wall_arm_legacy_skater.gd")
const Gate = preload("res://game/features/service_gate.gd")
const ArmTests = preload("res://tests/skater_obstacle_arm_tests.gd")
const Body = preload("res://tests/skater_body_attachment_tests.gd")
const Setup = preload("res://game/core/input_setup.gd")
const SIZE := Vector2i(960,640)
const OUTPUT := "res://.local/active-wall-arm-captures"
const NORTH_FACE := -0.09
var camera: Camera3D
var actor: CharacterBody3D
var gate: Node3D
var records: Array[Dictionary] = []
var actor_records: Array[Dictionary] = []
var failures := 0
var arm_data: Dictionary

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
	for legacy: bool in [true,false]:
		_release()
		actor=Legacy.new() if legacy else Current.new()
		actor.spawn_position=Vector3(0,0.04,-3)
		root.add_child(actor)
		actor.rotation.y=PI
		arm_data=ArmTests._skin_data(actor)
		camera.make_current()
		for tick: int in 10:await _frame()
		var contact_tick := -1
		var actual_contacts := 0
		Input.action_press("push",0.55)
		for tick: int in 180:
			await _frame()
			for slide: int in actor.get_slide_collision_count():
				if actor.get_slide_collision(slide).get_collider()==gate._panel:actual_contacts+=1
			if actual_contacts>0:
				contact_tick=tick
				break
			if actor.bailing:break
		var impact := {"position":_v(actor.global_position),"velocity":_v(actor.velocity),
			"geometry":_measure(false)}
		Input.action_release("push")
		Input.action_press("brake")
		for tick: int in 20:await _frame()
		Input.action_release("brake")
		for tick: int in 2:await _frame()
		Input.action_press("ollie")
		for tick: int in 20:await _frame()
		Input.action_release("ollie")
		for tick: int in 2:await _frame()
		Input.action_press("flip")
		for tick: int in 6:await _frame()
		for stage: String in ["flip","landing"]:
			# Freeze only a completed actual native input pose; never place the
			# actor, change its velocity, or assign an animation/trick flag.
			actor.set_physics_process(false)
			actor.set_process(false)
			actor.reset_physics_interpolation()
			if contact_tick<0 or actor.bailing:failures+=1
			if stage=="flip" and (not actor.airborne or actor._flip_remaining<=0.0 or actor.active_flip_id!="kickflip"):failures+=1
			if stage=="landing" and (actor.airborne or not actor.is_on_floor()):failures+=1
			var receipt := {"variant":"before" if legacy else "after","stage":stage,"input_contact_tick":contact_tick,
				"actual_panel_contacts":actual_contacts,"impact":impact,"brake_ticks":20,"neutral_ticks":2,
				"hold_ticks":20,"release_ticks":2,"flip_ticks":6 if stage=="flip" else 40,
				"physics_position":_v(actor.global_position),"physics_velocity":_v(actor.velocity),
				"physics_heading":actor.rotation.y,"physics_speed":actor.speed,
				"bailing":actor.bailing,"airborne":actor.airborne,"crouching":actor.crouching,"on_floor":actor.is_on_floor(),
				"visual_offset":_v(actor._visual.global_position-actor.global_position),
				"actual_geometry":_measure(false),"interpolated_geometry":_measure(true),"actual_arms":_measure_arms()}
			actor_records.append(receipt)
			var height := actor.global_position.y-0.011667
			camera.position=Vector3(2.6,1.4+height,-1.8)
			camera.fov=43
			camera.look_at(Vector3(0,0.85+height,-0.25))
			await _capture(receipt.variant+"-"+stage,receipt)
			if stage=="flip":
				actor.set_physics_process(true)
				actor.set_process(true)
				Input.action_release("flip")
				for tick: int in 34:await _frame()
		_release()
		actor.queue_free()
		await process_frame
		await physics_frame
		await process_frame
	if actor_records.size()!=4:failures+=1
	else:
		for index: int in 2:
			var old: Dictionary=actor_records[index]
			var repaired: Dictionary=actor_records[index+2]
			if int(old.actual_arms.panel_skin_vertices)<=0 or int(repaired.actual_arms.panel_skin_vertices)!=0:failures+=1
			if float(repaired.actual_geometry.board_clearance_m)<0.007 or float(repaired.actual_geometry.shoe_clearance_m)<0.007:failures+=1
			if old.stage!=repaired.stage or old.input_contact_tick!=repaired.input_contact_tick \
				or _vector(old.physics_position).distance_to(_vector(repaired.physics_position))>0.00001 \
				or _vector(old.physics_velocity).distance_to(_vector(repaired.physics_velocity))>0.00001 \
				or absf(float(old.physics_heading)-float(repaired.physics_heading))>0.00001:failures+=1
			# No display geometry or material is added by this pose correction.
			# Exact paired counts admit only the same fixture rendering workload.
			for counter: String in ["draw_calls","primitives","objects"]:
				if records[index][counter]!=records[index+2][counter]:failures+=1
	var after := _sources()
	if before!=after:failures+=1
	var manifest := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
		"size":[SIZE.x,SIZE.y],"frames":records,"actors":actor_records,"failures":failures,
		"source_stable":before==after,"source_before":before,"source_after":after,
		"legacy":JSON.parse_string(FileAccess.get_file_as_string("res://.local/active_wall_arm_legacy_sources.json")),
		"method":"Four completed native frames, immutable cd661ca before/current after at fresh Flip6 and supported landing Flip40 (the v2 centreline-ray miss). Actual original native Skin-weight sleeve and curl hand vertices must keep existing8mm finite-panel skin, no root/physics change. Two sequential actual Skaters, exact immutable cd661ca controller versus current controller, with same current rig/meshes/assets. Actual ServiceGate at origin with2.3m native shutter northfaceZ-.09;20m native/display flat floor. Each actor begins once at(0,.04,-3),headingPI; ordinary Push(.55) reaches actual native panel; Brake20 then neutral2 distinct native ticks precede genuine heldOllie20, release and2native updates, then fresh Flip held6native updates. Capture completed activeKickflip, then release and continue34native updates to actual landing. Capture both before/after poses. Freeze completed actor processing/reset interpolation only for identical fullbody camera frame_post_draw readbacks. No actor pose/velocity/trick assignments after initial placement. Geometry uses actual displayed board and every shoe mesh vertex. Before/after native actor motion must match. Static frame counters do not certify motion, Macperformance or wholemap cost."}
	var file := FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	file.close()
	print("WALL_CAPTURE frames=",records.size()," failures=",failures," source_stable=",before==after)
	quit(1 if failures else 0)

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
func _vector(value: Array) -> Vector3:return Vector3(value[0],value[1],value[2])

func _sources() -> Dictionary:
	var files := PackedStringArray(["res://project.godot","res://.local/active_wall_arm_capture.gd",
		"res://.local/active_wall_arm_capture.sh","res://.local/active_wall_arm_legacy_skater.gd",
		"res://.local/active_wall_arm_legacy_sources.json"])
	_collect("res://game",files)
	files.sort()
	var result := {}
	for path: String in files:result[path]=FileAccess.get_sha256(path)
	return result

func _collect(path: String,files: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	for name: String in directory.get_files():files.append(path.path_join(name))
	for name: String in directory.get_directories():_collect(path.path_join(name),files)
