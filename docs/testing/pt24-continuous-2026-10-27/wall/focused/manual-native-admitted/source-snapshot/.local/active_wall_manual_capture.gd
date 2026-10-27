extends SceneTree
## Completed native active and residual Nose Manual poses before/after fitting.
## The legacy controller is immutable cd661ca; both use the same current rig.
const Current = preload("res://game/player/skater.gd")
const Legacy = preload("res://.local/active_wall_manual_legacy_skater.gd")
const Gate = preload("res://game/features/service_gate.gd")
const Setup = preload("res://game/core/input_setup.gd")
const SIZE := Vector2i(960,640)
const OUTPUT := "res://.local/active-wall-manual-captures"
const NORTH_FACE := -0.09
var camera: Camera3D
var actor: CharacterBody3D
var gate: Node3D
var records: Array[Dictionary] = []
var actor_records: Array[Dictionary] = []
var failures := 0

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
		actor.spawn_position=Vector3(0,0.04,-3.02)
		root.add_child(actor)
		actor.rotation.y=PI
		camera.make_current()
		for tick: int in 4:await _frame()
		var contact_tick := -1
		var actual_contacts := 0
		var requested := false
		var entry_speed := 0.0
		var events: Array[Dictionary]=[]
		actor.trick_performed.connect(func(label: String,points: int):events.append({"id":actor.last_trick_id,"label":label,"points":points}))
		Input.action_press("push",0.55)
		for tick: int in 150:
			if not requested and absf(actor.speed)>=2.5 and actor.global_position.z< -1.0:
				requested=true
				Input.action_press("manual")
			await _frame()
			if actor.manual_active and entry_speed==0.0:entry_speed=absf(actor.speed)
			for slide: int in actor.get_slide_collision_count():
				if actor.get_slide_collision(slide).get_collider()==gate._panel:actual_contacts+=1
			if contact_tick<0 and actual_contacts>0:
				contact_tick=tick
				Input.action_release("push")
				Input.action_press("brake")
			var stage := ""
			if tick==78:stage="active-manual"
			elif contact_tick>=0 and tick-contact_tick==20:stage="residual-manual"
			if stage=="":continue
			# Freeze only a completed actual input pose for a native readback.
			# Initial spawn is the only actor pose/velocity/state assignment.
			actor.set_physics_process(false)
			actor.set_process(false)
			actor.reset_physics_interpolation()
			if actor.bailing or not actor.is_on_floor() or entry_speed<2.0:failures+=1
			if stage=="active-manual" and (not actor.manual_active or contact_tick>=0):failures+=1
			if stage=="residual-manual" and (actor.manual_active or actor._visual_rig._manual_blend<=0.0001 or contact_tick<0):failures+=1
			if actor.manual_trick_id!="nose_manual" or events.size()!=1 or events[0].id!="nose_manual" or events[0].points!=100:failures+=1
			var receipt := {"variant":"before" if legacy else "after","stage":stage,"native_tick":tick,
				"input_contact_tick":contact_tick,"actual_panel_contacts":actual_contacts,"entry_speed":entry_speed,
				"physics_position":_v(actor.global_position),"physics_velocity":_v(actor.velocity),
				"physics_heading":actor.rotation.y,"physics_speed":actor.speed,
				"bailing":actor.bailing,"airborne":actor.airborne,"on_floor":actor.is_on_floor(),
				"manual_active":actor.manual_active,"manual_id":actor.manual_trick_id,
				"manual_blend":actor._visual_rig._manual_blend,"board_local_transform":_transform(actor._board_visual.transform),
				"visual_offset":_v(actor._visual.global_position-actor.global_position),"events":events.duplicate(true),
				"actual_geometry":_measure(false),"interpolated_geometry":_measure(true)}
			actor_records.append(receipt)
			camera.position=Vector3(2.6,1.4,-1.8)
			camera.fov=43
			camera.look_at(Vector3(0,0.85,-0.25))
			await _capture(receipt.variant+"-"+stage,receipt)
			if stage=="residual-manual":break
			actor.set_physics_process(true)
			actor.set_process(true)
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
			if float(old.actual_geometry.board_clearance_m)> -0.03 \
				or float(repaired.actual_geometry.board_clearance_m)<0.0079 \
				or float(repaired.actual_geometry.shoe_clearance_m)<0.0079:failures+=1
			if old.stage!=repaired.stage or old.native_tick!=repaired.native_tick or old.input_contact_tick!=repaired.input_contact_tick \
				or _vector(old.physics_position).distance_to(_vector(repaired.physics_position))>0.00001 \
				or _vector(old.physics_velocity).distance_to(_vector(repaired.physics_velocity))>0.00001 \
				or absf(float(old.physics_heading)-float(repaired.physics_heading))>0.00001 \
				or old.board_local_transform!=repaired.board_local_transform:failures+=1
			for counter: String in ["draw_calls","primitives","objects","texture_bytes"]:
				if records[index][counter]!=records[index+2][counter]:failures+=1
	var after := _sources()
	if before!=after:failures+=1
	var manifest := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
		"size":[SIZE.x,SIZE.y],"frames":records,"actors":actor_records,"failures":failures,
		"source_stable":before==after,"source_before":before,"source_after":after,
		"legacy":JSON.parse_string(FileAccess.get_file_as_string("res://.local/active_wall_manual_legacy_sources.json")),
		"method":"Two sequential actual Skaters: exact immutable cd661ca controller versus current controller with the same current rig/assets. Actual native ServiceGate shutter north face Z=-.09 and 20 m native/display flat floor. Initial spawn (0,.04,-3.02), heading PI, then four settling ticks; genuine held Push(.55), followed by fresh held Manual after speed >=2.5 and Z<-1, earns Nose Manual. Capture the actual active pre-capsule-contact tick 78 and the actual residual pose 20 ticks after first native panel contact; Brake is held from contact. Freeze only completed native actor processing and reset interpolation for fixed-camera frame_post_draw readback. No actor pose, velocity or trick assignments after initial placement. Native physical motion, local board pose and ordinary input schedule must match. Measure actual board/shoe mesh vertices and frame counters; draw calls, primitives, objects and texture bytes must match each before/after pair. Four static PNGs do not certify whole-map performance, Mac or human motion acceptance."}
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
	var files := PackedStringArray(["res://project.godot","res://.local/active_wall_manual_capture.gd",
		"res://.local/active_wall_manual_capture.sh","res://.local/active_wall_manual_legacy_skater.gd",
		"res://.local/active_wall_manual_legacy_sources.json"])
	_collect("res://game",files)
	files.sort()
	var result := {}
	for path: String in files:result[path]=FileAccess.get_sha256(path)
	return result

func _collect(path: String,files: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	for name: String in directory.get_files():files.append(path.path_join(name))
	for name: String in directory.get_directories():_collect(path.path_join(name),files)
