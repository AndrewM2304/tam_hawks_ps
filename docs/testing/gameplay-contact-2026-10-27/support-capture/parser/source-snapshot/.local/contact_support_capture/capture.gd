extends SceneTree
const Native=preload("res://tests/native_ledge_fallback_tests.gd")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Skater=preload("res://game/player/skater.gd")
const Audit=preload("res://game/levels/surface_audit.gd")
const Line=preload("res://game/tricks/grind_line.gd")
const Style=preload("res://game/tricks/grind_style.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Authentic=preload("res://tests/authentic_pose_tests.gd")
const Body=preload("res://tests/skater_body_attachment_tests.gd")
const Board=preload("res://tests/board_geometry_tests_support.gd")
const SIZE=Vector2i(960,640)
var output:String
var camera:Camera3D
var errors:Array[String]=[]
var images:Array[Dictionary]=[]
var before:Dictionary
var counter:NativeCounter
class NativeCounter extends Node:
	var ticks:=0
	func _physics_process(_delta:float)->void:ticks+=1
func _initialize()->void:_run.call_deferred()
func _run()->void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().is_empty():quit(2);return
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	root.size=SIZE;root.content_scale_size=SIZE;Setup.register_actions();Classic._release()
	before=_sources();_environment()
	counter=NativeCounter.new();counter.process_physics_priority=100;root.add_child(counter)
	await _bench()
	await _lip()
	Classic._release()
	var after:=_sources()
	if before!=after:errors.append("Input sources changed")
	if images.size()!=2:errors.append("Exactly two original PNGs required")
	var report:Dictionary={"images":images,"errors":errors,"source_before":before,"source_after":after,
		"workload":"Actual generated lowbench fullSkater heldGrind plus8advancingupdates; actual Classic native solidcoping Push->mappedTriangle AxleStall plus10heldupdates. Declared sourceadapter retained.",
		"limits":"Two static native frames verify earned support presentation and completed-draw pose only; not continuous motion, performance, targetMac or human feel."}
	FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("RESULT: ",2 if errors.is_empty() else 0," passed, ",errors.size()," failed")
	for failure:String in errors:push_error(failure)
	quit(0 if errors.is_empty() else 1)
func _environment()->void:
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("9aaebd")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.7
	world.environment=env;root.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.25;sun.shadow_enabled=true;root.add_child(sun)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.near=.04;root.add_child(camera)
func _visible_box(body:StaticBody3D,color:Color)->void:
	var collision:CollisionShape3D=body.get_child(0)
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=collision.shape.size;mesh.mesh=box
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.9;mesh.material_override=material
	body.add_child(mesh)
func _bench()->void:
	Classic._release()
	var fixture:=Native.FlatWorld.new();root.add_child(fixture)
	var floor:StaticBody3D=Native._box(fixture,"NativeFloor",Vector3(30,.2,30),Vector3(0,-.1,0))
	var bench:StaticBody3D=Native._box(fixture,"UnlistedPhysicalBench",Vector3(6,.1,.6),Vector3(0,.5,0))
	var audit:=Audit.new();audit.build(fixture,[])
	var line:Line
	for candidate in audit.lines:
		if candidate.contact_edge_outward.dot(Vector3.BACK)>.99:line=candidate;break
	_visible_box(floor,Color("747b78"));_visible_box(bench,Color("43534d"))
	if line==null:errors.append("Actual generated bench outward guide missing");fixture.queue_free();await process_frame;return
	var distance:float=line.length*.4;var target:Vector3=line.contact_at(distance);var tangent:Vector3=line.dir_at(distance)
	var rider:=Skater.new();rider.spawn_position=target+Vector3.UP*.15;fixture.add_child(rider)
	rider.set_physics_process(false);rider.set_process(false)
	rider.rotation.y=atan2(-tangent.x,-tangent.z);rider.set_grind_lines([line])
	await _frames(1)
	rider.velocity=tangent*6.0-Vector3.UP;rider.speed=6.0;rider.airborne=true
	var captures:Array[String]=[];rider.grind_captured.connect(func(id:String):captures.append(id))
	Input.action_press("grind");rider.set_physics_process(true);rider.set_process(true)
	await _frames(1)
	var first:float=rider._grind.distance
	await _frames(8)
	if captures!=[line.id] or not rider.grinding or rider.bailing or rider._grind.distance<=first+.5:errors.append("Actual bench heldGrind acquisition/8nativeadvancingupdates failed")
	if not rider._grind_contact.valid or rider._grind_contact.max_error>Style.CONTACT_TOLERANCE:errors.append("Bench actual truck support failed")
	var details:Dictionary={"guide_id":line.id,"native_box_size":[6,.1,.6],"native_crown":_v(line.contact_at(rider._grind.distance)),"outward":_v(line.contact_edge_outward),"captures":captures,"grinding":rider.grinding,"style":rider.grind_style_id,"distance_advance":rider._grind.distance-first,"support_error":rider._grind_contact.max_error,"derived_edge_roll_radians":rider._grind_clearance.edge_roll_angle}
	await _capture(rider,"generated-bench-edge.png",details,Vector3(3.4,1.8,3.8),3.0)
	Classic._release();fixture.queue_free();await process_frame;await _frames(1)
func _lip()->void:
	var fixture:Dictionary=await Classic._pipe_fixture(self)
	var rider:CharacterBody3D=fixture.rider
	var seen:Array[String]=[];rider.trick_performed.connect(func(label:String,_points:int):seen.append(label))
	Input.action_press("push")
	var reached:=false;var updates:=0
	for tick:int in 180:
		await _frames(1);updates+=1
		if rider.transition_active and rider._transition.theta>=deg_to_rad(72.0):reached=true;break
	Classic._direction(Vector2.ZERO);Classic._pad(JOY_BUTTON_Y,true)
	for tick:int in 10:
		await _frames(1)
		if rider.lip_active:break
	Classic._direction(Vector2.ZERO);await _frames(10)
	var coping:Dictionary=rider._transition_coping_data(rider._lip_feature,rider._lip_feature.get("coping_contact",rider.global_position))
	if not reached or not rider.lip_active or rider.lip_id!="axle_stall" or seen.count("Axle Stall")!=1 or rider.bailing or coping.is_empty():errors.append("Actual Push->Triangle solidcoping AxleStall failed")
	var details:Dictionary={"push_updates":updates,"reached72degrees":reached,"lip_active":rider.lip_active,"lip_id":rider.lip_id,"tricks":seen,"coping_contact":_v(rider._lip_feature.get("coping_contact",rider.global_position)),"coping_radius":float(coping.get("radius",-1.0)),"coping_layer":coping.body.collision_layer if coping.has("body") else 0,"held_native_updates":10}
	await _capture(rider,"solid-coping-axle-stall.png",details,Vector3(4.2,1.9,4.2),3.2)
	Classic._release();fixture.root.queue_free();await process_frame;await _frames(1)
func _capture(rider:CharacterBody3D,file:String,details:Dictionary,eye:Vector3,size:float)->void:
	paused=true;rider.set_physics_process(false);rider.set_process(false)
	camera.size=size;camera.position=rider.global_position+eye;camera.look_at(rider.global_position+Vector3.UP*.78);camera.make_current()
	for node:Node3D in _pose_nodes(rider):node.get_global_transform_interpolated()
	rider.reset_physics_interpolation();camera.get_global_transform_interpolated();camera.reset_physics_interpolation()
	var tick:int=counter.ticks;var frozen:Array[Transform3D]=_pose(rider,false)
	await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
	var physical:Array[Transform3D]=_pose(rider,false);var drawn:Array[Transform3D]=_pose(rider,true)
	var matches:bool=_same_pose(frozen,physical) and _same_pose(physical,drawn) and tick==counter.ticks and camera.global_transform.is_equal_approx(camera.get_global_transform_interpolated())
	if not matches:errors.append("Completed native/draw pose witness "+file)
	var cloth:Dictionary=Body._sample(rider,Body._prepare(rider._visual_rig))
	var grip:=0.0
	for leg:Dictionary in rider._visual_rig._legs:grip=maxf(grip,Board.grip_distance(rider._visual_rig,leg.foot.to_global(Authentic.SOLE)))
	if not cloth.finite or cloth.seam>=.08 or cloth.joint_gap>=.06 or cloth.neck_gap>=.05 or grip>=.004:errors.append("Actual clothing/footdeck contact "+file)
	var framed:=true
	for marker:Vector3 in Authentic._markers(rider._visual_rig):framed=framed and camera.is_position_in_frustum(marker)
	if not framed:errors.append("Fullbody native framing "+file)
	var picture:=root.get_texture().get_image()
	if picture.get_size()!=SIZE or picture.save_png(output.path_join(file))!=OK:errors.append("Native PNG "+file)
	var row:Dictionary={"file":file,"sha256":FileAccess.get_sha256(output.path_join(file)),"details":details,"actor_position":_v(rider.global_position),"velocity":_v(rider.velocity),"camera":str(camera.global_transform),"camera_projection":"orthographic","camera_size":camera.size,"native_physics_tick":tick,"completed_draw_pose_matches":matches,"native_pose":_pose_json(physical),"draw_pose":_pose_json(drawn),"pose_nodes":["actor","visual","board","rider","head","front_foot","rear_foot","left_hand","right_hand"],"observed_engine_physics_frame":Engine.get_physics_frames(),"observed_engine_draw_frame":Engine.get_frames_drawn(),"observed_engine_process_frame":Engine.get_process_frames(),"interpolation_fraction":Engine.get_physics_interpolation_fraction(),"framed":framed,"clothing_seam":cloth.seam,"joint_gap":cloth.joint_gap,"neck_gap":cloth.neck_gap,"shoe_deck_distance":grip}
	images.append(row)
	rider.set_physics_process(true);rider.set_process(true);paused=false
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
func _frames(count:int)->void:
	for tick:int in count:await physics_frame;await process_frame
func _v(point:Vector3)->Array:return [point.x,point.y,point.z]
func _sources()->Dictionary:
	var files:=PackedStringArray(["res://project.godot","res://docs/testing/horizon-background/observers/run_checked.py"])
	for folder:String in ["game","tests","tools",".local/contact_support_capture"]:_collect("res://"+folder,files)
	files.sort();var result:Dictionary={}
	for file:String in files:result[file]=FileAccess.get_sha256(file)
	return result
func _collect(path:String,files:PackedStringArray)->void:
	var directory:=DirAccess.open(path)
	for file:String in directory.get_files():
		if not file.ends_with(".pyc"):files.append(path.path_join(file))
	for child:String in directory.get_directories():
		if child!="__pycache__":_collect(path.path_join(child),files)
