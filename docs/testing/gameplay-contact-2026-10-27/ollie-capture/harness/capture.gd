extends SceneTree
## Native floor/input twins; intentionally different flight, fixed diagnostic view.
const Current=preload("res://game/player/skater.gd")
const Legacy=preload("res://.local/weighted_ollie_capture/legacy/skater.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Authentic=preload("res://tests/authentic_pose_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Board=preload("res://tests/board_geometry_tests_support.gd")
const SIZE=Vector2i(960,640)
var output:String
var actors:Array[CharacterBody3D]=[]
var state:Array[Dictionary]=[]
var camera:Camera3D
var pending:Array[Dictionary]=[]
var images:Array[Dictionary]=[]
var phase:="settle"
var native_tick:=0
var failures:Array[String]=[]
var before:Dictionary

class Sampler extends Node:
	var audit:SceneTree
	func _ready()->void:process_physics_priority=100
	func _physics_process(_delta:float)->void:audit._sample()

func _initialize()->void:_run.call_deferred()

func _run()->void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size=SIZE;root.content_scale_size=SIZE
	Setup.register_actions();_release()
	before=_sources()
	_build()
	var sampler:=Sampler.new();sampler.audit=self;root.add_child(sampler)
	for tick:int in 80:await _frame()
	for index:int in 2:
		state[index].origin=actors[index].global_position
		state[index].neutral_hips=actors[index]._visual_rig._upper.position.y
	Input.action_press("ollie")
	for tick:int in 24:await _frame()
	if actors[0].global_transform!=actors[1].global_transform or actors[0].velocity!=actors[1].velocity:
		failures.append("Before release native body history differs")
	await _capture_batch([{"index":0,"stage":"crouch"},{"index":1,"stage":"crouch"}])
	phase="flight";native_tick=0;Input.action_release("ollie")
	for tick:int in 100:
		await _frame()
		if not pending.is_empty():
			var batch:Array[Dictionary]=pending.duplicate(true);pending.clear()
			await _capture_batch(batch)
		if state[0].stages.size()==3 and state[1].stages.size()==3:break
	_release()
	for index:int in 2:
		if state[index].stages!=["rise","apex","contact"]:failures.append("Missing ordered phases "+str(index))
		if state[index].events!=["ollie"] or state[index].bails!=0:failures.append("Native award/bail contract "+str(index))
		if not state[index].clothing or state[index].minimum_sole_y< -0.001:failures.append("Actual clothing/floor clearance "+str(index))
	var after:=_sources()
	if before!=after:failures.append("Execution inputs changed")
	if images.size()!=8:failures.append("Eight original PNGs required")
	var actor_results:Array[Dictionary]=[]
	for data:Dictionary in state:
		var row:Dictionary=data.duplicate();row.erase("data");row.origin=_v(data.origin);actor_results.append(row)
	var report:Dictionary={"images":images,"actors":actor_results,"errors":failures,"source_before":before,"source_after":after,
		"camera_transform":str(camera.global_transform),"camera_projection":"orthographic","camera_size":camera.size,
		"workload":"Both real actors on one native Box floor, 80 settle ticks, 24 held Ollie ticks, one release. Rise is common fifth flight update; apex is first nonpositive vertical velocity; contact is third native grounded update. Capture pauses only after the completed native sample and hides only the other visual for readback.",
		"limits":"Intentional new physical trajectory: no false native position/velocity parity after release. Old controller/Visual/TrickAnimation are immutable 838e6f4 adapters; other dependencies are shared current and hashed. Static fixed-view PNGs do not certify moving-camera quality, target Mac feel, display FPS or timing admission."}
	FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("RESULT: ",8 if failures.is_empty() else 0," passed, ",failures.size()," failed")
	quit(0 if failures.is_empty() else 1)

func _build()->void:
	var world:=WorldEnvironment.new();var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("9aaebd")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.8
	world.environment=environment;root.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.6;sun.shadow_enabled=true;root.add_child(sun)
	var floor:=StaticBody3D.new();floor.name="Declared20mFloor";root.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,.2,20)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-.1;floor.add_child(collision)
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=shape.size;mesh.mesh=box;mesh.position.y=-.1
	var material:=StandardMaterial3D.new();material.albedo_color=Color("777d7b");mesh.material_override=material;floor.add_child(mesh)
	for index:int in 2:
		var actor:CharacterBody3D=Legacy.new() if index==0 else Current.new()
		actor.spawn_position=Vector3(0,.04,0);root.add_child(actor);actors.append(actor)
		var data:Dictionary={"variant":"before" if index==0 else "after","stages":[],"rows":[],"events":[],"bails":0,"air_ticks":0,"ground_ticks":0,"seen":false,"peak":0.0,"origin":Vector3.ZERO,"neutral_hips":0.0,"data":Body._prepare(actor._visual_rig),"clothing":true,"minimum_sole_y":INF,"maximum_seam":0.0,"maximum_joint":0.0,"maximum_grip_after_catch":0.0}
		state.append(data)
		actor.trick_performed.connect(func(_label:String,_points:int):data.events.append(actor.last_trick_id))
		actor.bailed.connect(func():data.bails+=1)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.9;camera.near=.04
	root.add_child(camera);camera.position=Vector3(4.4,1.8,1.3);camera.look_at(Vector3(0,1.5,-1.7));camera.make_current()

func _sample()->void:
	if phase!="flight":return
	native_tick+=1
	for index:int in 2:
		var actor:CharacterBody3D=actors[index];var data:Dictionary=state[index];var rig:RefCounted=actor._visual_rig
		if actor.airborne:data.seen=true;data.air_ticks+=1
		elif data.seen:data.ground_ticks+=1
		var height:float=actor.global_position.y-data.origin.y;data.peak=maxf(data.peak,height)
		var cloth:Dictionary=Body._sample(actor,data.data)
		data.clothing=data.clothing and cloth.finite and cloth.seam<.08 and cloth.joint_gap<.06 and cloth.neck_gap<.05
		data.maximum_seam=maxf(data.maximum_seam,cloth.seam);data.maximum_joint=maxf(data.maximum_joint,cloth.joint_gap)
		for leg:Dictionary in rig._legs:
			for vertex:Vector3 in rig._sole_points:data.minimum_sole_y=minf(data.minimum_sole_y,leg.foot.to_global(vertex).y)
			if data.air_ticks>=8:data.maximum_grip_after_catch=maxf(data.maximum_grip_after_catch,Board.grip_distance(rig,leg.foot.to_global(Authentic.SOLE)))
		data.rows.append({"tick":native_tick,"seconds":native_tick/60.0,"position":_v(actor.global_position),"velocity":_v(actor.velocity),"airborne":actor.airborne,"on_floor":actor.is_on_floor(),"hips_y":rig._upper.position.y,"board_pitch":actor._board_visual.rotation.x,"front_lead":rig._legs[0].foot.global_position.y-rig._legs[1].foot.global_position.y})
		var event:=""
		if data.air_ticks==5 and actor.airborne and not data.stages.has("rise"):event="rise"
		elif actor.airborne and actor.velocity.y<=0.0 and not data.stages.has("apex"):event="apex"
		elif data.seen and actor.is_on_floor() and data.ground_ticks==3 and not data.stages.has("contact"):event="contact"
		if not event.is_empty():data.stages.append(event);pending.append({"index":index,"stage":event})
	if not pending.is_empty():paused=true

func _capture_batch(batch:Array[Dictionary])->void:
	paused=true;camera.make_current()
	var processing:Array[Dictionary]=[]
	for actor:CharacterBody3D in actors:
		processing.append({"physics":actor.is_physics_processing(),"process":actor.is_processing()})
		actor.set_physics_process(false);actor.set_process(false)
		# Prime the native interpolation pumps before resetting the completed
		# physics pose; both actors stay frozen throughout all readbacks.
		for node:Node3D in _pose_nodes(actor):node.get_global_transform_interpolated()
		actor.reset_physics_interpolation()
	for request:Dictionary in batch:
		var index:int=request.index;var actor:CharacterBody3D=actors[index]
		var frozen_tick:int=native_tick
		var frozen_pose:Array[Transform3D]=_pose(actor,false)
		for other:int in 2:actors[other]._visual.visible=other==index
		await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		# These getters and the PNG observe the same completed native draw.
		var physics_pose:Array[Transform3D]=_pose(actor,false)
		var draw_pose:Array[Transform3D]=_pose(actor,true)
		var pose_matches:bool=_same_pose(frozen_pose,physics_pose) and _same_pose(physics_pose,draw_pose)
		var draw_camera:Transform3D=camera.get_global_transform_interpolated()
		if not pose_matches or native_tick!=frozen_tick or not camera.global_transform.is_equal_approx(draw_camera):failures.append("Completed-draw pose witness "+str(request))
		var picture:=root.get_texture().get_image();var file:String=state[index].variant+"-"+str(request.stage)+".png"
		if picture.get_size()!=SIZE or picture.save_png(output.path_join(file))!=OK:failures.append("Native image "+file)
		var framed:=true
		for point:Vector3 in Authentic._markers(actor._visual_rig):framed=framed and camera.is_position_in_frustum(point)
		if not framed:failures.append("Fixed diagnostic framing "+file)
		images.append({"file":file,"sha256":FileAccess.get_sha256(output.path_join(file)),"stage":request.stage,"variant":state[index].variant,"native_tick":native_tick,"native_seconds":native_tick/60.0,"air_ticks":state[index].air_ticks,"ground_ticks":state[index].ground_ticks,"position":_v(actor.global_position),"velocity":_v(actor.velocity),"hips_y":actor._visual_rig._upper.position.y,"board_pitch":actor._board_visual.rotation.x,"camera":str(draw_camera),"pose_nodes":["actor","visual","board","rider","head","front_foot","rear_foot","left_hand","right_hand"],"native_pose":_pose_json(physics_pose),"draw_pose":_pose_json(draw_pose),"completed_draw_pose_matches":pose_matches,"frozen_native_tick":frozen_tick,"frozen_physics":not actor.is_physics_processing(),"frozen_process":not actor.is_processing(),"observed_engine_draw_frame":Engine.get_frames_drawn(),"observed_engine_process_frame":Engine.get_process_frames(),"interpolation_fraction":Engine.get_physics_interpolation_fraction(),"framed":framed,"objects":int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))})
	for index:int in 2:
		actors[index]._visual.visible=true
		actors[index].set_physics_process(processing[index].physics)
		actors[index].set_process(processing[index].process)
	paused=false

func _pose_nodes(actor:CharacterBody3D)->Array[Node3D]:
	var rig:RefCounted=actor._visual_rig
	var nodes:Array[Node3D]=[actor,actor._visual,actor._board_visual,actor._rider_visual,rig._head]
	for leg:Dictionary in rig._legs:nodes.append(leg.foot)
	for arm:Dictionary in rig._arms:nodes.append(arm.hand)
	return nodes
func _pose(actor:CharacterBody3D,interpolated:bool)->Array[Transform3D]:
	var frames:Array[Transform3D]=[]
	for node:Node3D in _pose_nodes(actor):frames.append(node.get_global_transform_interpolated() if interpolated else node.global_transform)
	return frames
func _same_pose(a:Array[Transform3D],b:Array[Transform3D])->bool:
	if a.size()!=b.size():return false
	for index:int in a.size():
		if not a[index].is_equal_approx(b[index]):return false
	return true
func _pose_json(frames:Array[Transform3D])->Array:
	var rows:Array=[]
	for frame:Transform3D in frames:rows.append({"origin":_v(frame.origin),"basis_x":_v(frame.basis.x),"basis_y":_v(frame.basis.y),"basis_z":_v(frame.basis.z)})
	return rows

func _frame()->void:await physics_frame;await process_frame
func _release()->void:
	for action:String in InputMap.get_actions():Input.action_release(action)
func _v(point:Vector3)->Array:return [point.x,point.y,point.z]
func _sources()->Dictionary:
	var files:=PackedStringArray(["res://project.godot","res://.local/weighted_ollie_capture/capture.gd","res://.local/weighted_ollie_capture/run_rendered.py","res://.local/weighted_ollie_capture/sources.json"])
	_collect("res://game",files);_collect("res://.local/weighted_ollie_capture/legacy",files);_collect("res://.local/weighted_ollie_capture/raw",files)
	for helper:String in ["authentic_pose_tests.gd","skater_body_attachment_tests.gd","board_geometry_tests_support.gd"]:files.append("res://tests/"+helper)
	files.sort();var result:Dictionary={}
	for file:String in files:result[file]=FileAccess.get_sha256(file)
	return result
func _collect(path:String,files:PackedStringArray)->void:
	var directory:=DirAccess.open(path)
	for file:String in directory.get_files():files.append(path.path_join(file))
	for child:String in directory.get_directories():_collect(path.path_join(child),files)
