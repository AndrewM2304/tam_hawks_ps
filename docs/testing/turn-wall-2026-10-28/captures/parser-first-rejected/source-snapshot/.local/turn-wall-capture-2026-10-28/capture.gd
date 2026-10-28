extends SceneTree
## Adapted from the existing weighted Ollie native capture: real inputs,
## completed-draw pose witnesses, immutable controller baseline and current rig.
const Current = preload("res://game/player/skater.gd")
const Baseline = preload("res://.local/turn-wall-capture-2026-10-28/baseline_skater.gd")
const Setup = preload("res://game/core/input_setup.gd")
const Body = preload("res://tests/skater_body_attachment_tests.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Density = preload("res://tests/full_level_density_tests.gd")
const SIZE := Vector2i(960,640)
var output := ""
var actor: CharacterBody3D
var fixture: Node3D
var camera: Camera3D
var state: Dictionary = {}
var active := false
var pending := ""
var records: Array[Dictionary] = []
var cases: Array[Dictionary] = []
var errors: Array[String] = []

class Sampler extends Node:
	var audit: SceneTree
	func _ready() -> void: process_physics_priority=100
	func _physics_process(_delta: float) -> void: audit._sample()

class CameraView extends Node:
	var skater: CharacterBody3D

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless" or args.size()!=1: quit(2);return
	output=args[0]
	if not output.is_absolute_path() or FileAccess.file_exists(output.path_join("CAPTURE.json")): quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	root.size=SIZE;root.content_scale_size=SIZE
	Setup.register_actions();_release()
	var before := _sources()
	_build_lighting()
	var sampler := Sampler.new();sampler.audit=self;root.add_child(sampler)
	for side: float in [1.0,-1.0]:
		for old: bool in [true,false]: await _wall_case(side,old)
	for side: float in [-1.0,1.0]: await _turn_case(side)
	_release()
	var after := _sources()
	if before!=after: errors.append("Capture inputs changed")
	if records.size()!=8: errors.append("Eight original images required")
	for side: float in [1.0,-1.0]:
		var old: Dictionary={};var current: Dictionary={}
		for row: Dictionary in cases:
			if row.kind!="wall" or row.side!=side: continue
			if row.variant=="before":old=row
			else:current=row
		if old.is_empty() or current.is_empty():errors.append("Missing mirrored wall pair");continue
		if old.rows.size()!=current.rows.size():errors.append("Wall physical sample count differs");continue
		for index: int in old.rows.size():
			var a: Dictionary=old.rows[index];var b: Dictionary=current.rows[index]
			if _vec(a.position).distance_to(_vec(b.position))>0.00001 or _vec(a.velocity).distance_to(_vec(b.velocity))>0.00001:
				errors.append("Wall native motion differs "+str(side)+" tick "+str(index));break
	var report := {"engine":Engine.get_version_info(),"size":[SIZE.x,SIZE.y],"images":records,"cases":cases,
		"errors":errors,"source_before":before,"source_after":after,"source_stable":before==after,
		"baseline":JSON.parse_string(FileAccess.get_file_as_string("res://.local/turn-wall-capture-2026-10-28/BASELINE.json")),
		"method":"Sequential real Skaters on finite native fixture geometry. Wall initial placement/air velocity are declared once; held Grind earns native support. Steer cases use only Push, held/released Ollie and analog steering after initial placement. Same current rig/assets in both controller epochs. Pauses occur only after completed native samples for fixed-view readback; no per-tick pose/velocity assignment.",
		"limits":"Fixed-60 diagnostic presentation clock, not performance/FPS, target Mac, human feel or ordinary Main-route acceptance. Eight PNGs cover mirrored old/new first wall contact, current release/Wallie and current left/right landed rollout. Prelanding and settled poses remain in continuous metrics. Native chase observations are retained separately from the fixed diagnostic camera."}
	_write(output.path_join("CAPTURE.json"),report)
	print("RESULT: ",8 if errors.is_empty() else 0," passed, ",errors.size()," failed")
	quit(0 if errors.is_empty() else 1)

func _build_lighting() -> void:
	var world := WorldEnvironment.new();var env := Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("9aaebd")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.8
	world.environment=env;root.add_child(world)
	var sun := DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.6;sun.shadow_enabled=true;root.add_child(sun)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.5;camera.near=.04;root.add_child(camera)

func _box(label: String,size: Vector3,at: Vector3,color: Color) -> void:
	var body := StaticBody3D.new();body.name=label;body.position=at;fixture.add_child(body)
	var shape := BoxShape3D.new();shape.size=size
	var collision := CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	var mesh := MeshInstance3D.new();var box := BoxMesh.new();box.size=size;mesh.mesh=box
	var material := StandardMaterial3D.new();material.albedo_color=color;mesh.material_override=material;body.add_child(mesh)

func _create(old: bool,wall: bool,side: float) -> void:
	_release();fixture=Node3D.new();root.add_child(fixture)
	_box("NativeFloor",Vector3(100,.4,100),Vector3(0,-.2,0),Color("777d7b"))
	if wall:_box("ArchitectureWall",Vector3(.4,24,40),Vector3(0,8,0),Color("8b8680"))
	actor=Baseline.new() if old else Current.new()
	actor.spawn_position=Vector3(side*.90,8,8) if wall else Vector3(0,.8,12)
	fixture.add_child(actor);actor.set_physics_process(false)
	state={"kind":"wall" if wall else "turn","variant":"before" if old else "after","side":side,
		"tick":0,"rows":[],"events":[],"bails":0,"lands":0,"seen_wall":false,"seen_air":false,
		"entry_tick":-1,"exit_tick":-1,"ground_ticks":0,"near_landing":{},"clothing":true,
		"maximum_seam":0.0,"maximum_joint_gap":0.0,"maximum_neck_gap":0.0,"maximum_visual_step":0.0,"maximum_raw_quaternion_visual_step":0.0,"maximum_local_offset_step":0.0,
		"body_data":Body._prepare(actor._visual_rig),"previous_visual":actor._visual.global_basis.orthonormalized(),"previous_visual_local":actor._visual.position}
	var data: Dictionary=state
	actor.trick_performed.connect(func(_label: String,_points: int):data.events.append(actor.last_trick_id))
	actor.bailed.connect(func():data.bails+=1)
	actor.landed.connect(func(clean: bool):
		if clean:data.lands+=1)
	camera.make_current()

func _wall_case(side: float,old: bool) -> void:
	_create(old,true,side)
	actor.airborne=true;actor.velocity=Vector3(-side*1.2,0,-8);actor.speed=Vector2(actor.velocity.x,actor.velocity.z).length()
	# Prime the ordinary camera from this declared initial-air placement;
	# physics remains frozen and the wall is not claimed before held input.
	for tick: int in 8: await _frame()
	Input.action_press("grind");active=true;actor.set_physics_process(true)
	for tick: int in 46:
		if tick==1 and side<0:Input.action_press("ollie")
		if tick==5:
			if side>0:Input.action_release("grind")
			else:Input.action_release("ollie")
		await _frame()
		if not pending.is_empty():await _capture_pending()
	active=false
	if not state.seen_wall or state.entry_tick!=1 or state.exit_tick<0 or state.bails!=0:errors.append("Wall input/contact lifecycle "+str(side)+" "+state.variant)
	if not state.clothing:errors.append("Wall connected clothing "+str(side)+" "+state.variant)
	await _dispose()

func _turn_case(side: float) -> void:
	_create(false,false,side);actor.set_physics_process(true);active=true
	for tick: int in 45:await _frame()
	Input.action_press("push")
	for tick: int in 30:await _frame()
	Input.action_release("push");Input.action_press("ollie")
	for tick: int in 24:await _frame()
	Input.action_release("ollie");await _frame()
	var action := "steer_left" if side<0 else "steer_right"
	Input.action_press(action,PI/2.0/(Current.SPIN_SPEED*20.0/60.0))
	for tick: int in 20:await _frame()
	Input.action_release(action)
	for tick: int in 65:
		await _frame()
		if not pending.is_empty():await _capture_pending();break
	active=false
	if not state.seen_air or state.bails!=0 or state.lands!=1 or state.ground_ticks<8 or not actor.is_on_floor():errors.append("Steered landing lifecycle "+str(side))
	var planar := Vector3(actor.velocity.x,0,actor.velocity.z)
	if planar.length()<.1 or planar.normalized().dot(Vector3(side,0,0))<.98:errors.append("Steered outgoing direction "+str(side))
	if not state.clothing:errors.append("Steered landing connected clothing "+str(side))
	await _dispose()

func _sample() -> void:
	if not active or not is_instance_valid(actor):return
	state.tick+=1
	var cloth := Body._sample(actor,state.body_data)
	state.clothing=state.clothing and cloth.finite and cloth.seam<.08 and cloth.joint_gap<.06 and cloth.neck_gap<.05
	state.maximum_seam=maxf(state.maximum_seam,cloth.seam);state.maximum_joint_gap=maxf(state.maximum_joint_gap,cloth.joint_gap);state.maximum_neck_gap=maxf(state.maximum_neck_gap,cloth.neck_gap)
	var visual: Basis=actor._visual.global_basis.orthonormalized()
	var previous: Basis=state.previous_visual
	var raw_quaternion_step: float=previous.get_rotation_quaternion().angle_to(visual.get_rotation_quaternion())
	var step: float=_rotation_angle(previous,visual)
	state.maximum_visual_step=maxf(state.maximum_visual_step,step);state.previous_visual=visual
	state.maximum_raw_quaternion_visual_step=maxf(state.maximum_raw_quaternion_visual_step,raw_quaternion_step)
	var offset_step: float=actor._visual.position.distance_to(state.previous_visual_local)
	state.maximum_local_offset_step=maxf(state.maximum_local_offset_step,offset_step);state.previous_visual_local=actor._visual.position
	var row := {"tick":state.tick,"position":_v(actor.global_position),"velocity":_v(actor.velocity),
		"body_yaw":actor.rotation.y,"visual_basis":_basis_json(actor._visual.global_basis),"spin":actor._spin_angle,
		"airborne":actor.airborne,"on_floor":actor.is_on_floor(),"wallriding":actor.wallriding,"bailing":actor.bailing,
		"visual_step_radians":step,"raw_quaternion_visual_step_radians":raw_quaternion_step,
		"rotation_metric_previous_basis":_basis_json(previous),"rotation_metric_current_basis":_basis_json(visual),
		"local_visual_offset":_v(actor._visual.position),"local_offset_step_m":offset_step,
		"seam":cloth.seam,"joint_gap":cloth.joint_gap,"neck_gap":cloth.neck_gap,
		"native_pose":_pose_json(_pose(false))}
	state.rows.append(row)
	if state.kind=="wall":
		if actor.wallriding and not state.seen_wall:
			state.seen_wall=true;state.entry_tick=state.tick;pending="wall-entry"
		elif state.seen_wall and not actor.wallriding and state.exit_tick<0:
			state.exit_tick=state.tick
			if state.variant=="after":pending="wall-release" if state.side>0 else "wallie"
	else:
		if actor.airborne:state.seen_air=true
		if state.seen_air and actor.airborne and actor.velocity.y<0.0 and actor.global_position.y<.35 and state.near_landing.is_empty():state.near_landing=row.duplicate(true)
		if state.seen_air and not actor.airborne and actor.is_on_floor():state.ground_ticks+=1
		if state.ground_ticks==8:pending="turned-rollout"
	if not pending.is_empty():paused=true

func _capture_pending() -> void:
	var stage := pending;pending="";paused=true
	var tick: int=state.tick
	var physics: bool=actor.is_physics_processing();var process: bool=actor.is_processing()
	actor.set_physics_process(false);actor.set_process(false)
	for node: Node3D in _nodes():node.get_global_transform_interpolated()
	actor.reset_physics_interpolation()
	var frozen := _pose(false)
	var side: float=state.side if state.kind=="wall" else 1.0
	camera.position=actor.global_position+Vector3(side*4.4,1.6,3.0)
	camera.look_at(actor.global_position+Vector3(0,.85,-.1));camera.make_current();camera.reset_physics_interpolation()
	await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
	var native := _pose(false);var drawn := _pose(true)
	var matches := _same(frozen,native) and _same(native,drawn) and state.tick==tick
	if not matches:errors.append("Completed-draw pose "+stage)
	var framed := true
	for point: Vector3 in Authentic._markers(actor._visual_rig):framed=framed and camera.is_position_in_frustum(point)
	if not framed:errors.append("Diagnostic framing "+stage)
	var label: String=state.variant+"-"+("wall-on-left" if state.side>0 else "wall-on-right")+"-"+stage if state.kind=="wall" else ("left" if state.side<0 else "right")+"-"+stage
	var image := root.get_texture().get_image();var file := label+".png"
	if image.get_size()!=SIZE or image.save_png(output.path_join(file))!=OK:errors.append("Native PNG "+file)
	var view := CameraView.new();view.skater=actor
	var chase_clear := Density._camera_clear(view)
	view.free()
	records.append({"file":file,"sha256":FileAccess.get_sha256(output.path_join(file)),"stage":stage,
		"variant":state.variant,"side":state.side,"tick":tick,"position":_v(actor.global_position),"velocity":_v(actor.velocity),
		"body_yaw":actor.rotation.y,"speed":actor.speed,"airborne":actor.airborne,"wallriding":actor.wallriding,
		"bailing":actor.bailing,"events":state.events.duplicate(),"native_pose":_pose_json(native),"draw_pose":_pose_json(drawn),
		"visual_step_radians":state.rows[-1].visual_step_radians,"raw_quaternion_visual_step_radians":state.rows[-1].raw_quaternion_visual_step_radians,
		"completed_draw_pose_matches":matches,"framed":framed,"diagnostic_camera":str(camera.global_transform),
		"normal_chase_camera":str(actor._camera.global_transform),"normal_chase_native_clear_and_framed":chase_clear,
		"normal_chase_observation":"Last ordinary processed camera state frozen at the completed native sample, separate from diagnostic image camera.",
		"observed_draw_frame":Engine.get_frames_drawn(),"observed_process_frame":Engine.get_process_frames(),
		"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))})
	actor.set_physics_process(physics);actor.set_process(process);paused=false

func _dispose() -> void:
	active=false;_release()
	var result: Dictionary=state.duplicate();result.erase("body_data");result.erase("previous_visual");result.erase("previous_visual_local");cases.append(result)
	fixture.queue_free();await process_frame;await physics_frame;await process_frame

func _nodes() -> Array[Node3D]:
	var rig: RefCounted=actor._visual_rig
	var result: Array[Node3D]=[actor,actor._visual,actor._board_visual,actor._rider_visual,rig._head]
	for leg: Dictionary in rig._legs:result.append(leg.foot)
	for arm: Dictionary in rig._arms:result.append(arm.hand)
	return result
func _pose(interpolated: bool) -> Array[Transform3D]:
	var result: Array[Transform3D]=[]
	for node: Node3D in _nodes():result.append(node.get_global_transform_interpolated() if interpolated else node.global_transform)
	return result
func _same(a: Array[Transform3D],b: Array[Transform3D]) -> bool:
	for index: int in a.size():
		if not a[index].is_equal_approx(b[index]):return false
	return true
func _rotation_angle(previous: Basis,current: Basis) -> float:
	# Independent relative-matrix angle. Near zero, acos(dot(quaternions))
	# magnifies native float rounding; keep that raw value beside this witness.
	var relative := previous.transposed()*current
	var skew := Vector3(relative.y.z-relative.z.y,relative.z.x-relative.x.z,relative.x.y-relative.y.x)
	var sine := skew.length()*0.5
	var cosine := (relative.x.x+relative.y.y+relative.z.z-1.0)*0.5
	return atan2(sine,cosine)
func _basis_json(frame: Basis) -> Dictionary:
	return {"x":_v(frame.x),"y":_v(frame.y),"z":_v(frame.z)}
func _pose_json(frames: Array[Transform3D]) -> Array:
	var result: Array=[]
	for frame: Transform3D in frames:result.append({"origin":_v(frame.origin),"basis_x":_v(frame.basis.x),"basis_y":_v(frame.basis.y),"basis_z":_v(frame.basis.z)})
	return result
func _frame() -> void:await physics_frame;await process_frame
func _release() -> void:
	for action: StringName in InputMap.get_actions():Input.action_release(action)
func _v(point: Vector3) -> Array:return [point.x,point.y,point.z]
func _vec(row: Array) -> Vector3:return Vector3(row[0],row[1],row[2])
func _write(path: String,value: Variant) -> void:FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(value,"\t",false,true)+"\n")
func _sources() -> Dictionary:
	var files := PackedStringArray(["res://project.godot","res://.local/turn-wall-capture-2026-10-28/capture.gd",
		"res://.local/turn-wall-capture-2026-10-28/baseline_skater.gd","res://.local/turn-wall-capture-2026-10-28/run_rendered.py","res://.local/turn-wall-capture-2026-10-28/BASELINE.json"])
	_collect("res://game",files)
	for file: String in ["skater_body_attachment_tests.gd","authentic_pose_tests.gd","full_level_density_tests.gd"]:files.append("res://tests/"+file)
	files.sort();var result := {}
	for file: String in files:result[file]=FileAccess.get_sha256(file)
	return result
func _collect(path: String,files: PackedStringArray) -> void:
	var folder := DirAccess.open(path)
	for name: String in folder.get_files():files.append(path.path_join(name))
	for name: String in folder.get_directories():_collect(path.path_join(name),files)
