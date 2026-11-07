extends "res://tools/full_fidelity_capture.gd"
## QA observer only: immutable four-case native driver and production Main.
const Lines=preload("res://tests/line_design_tests.gd")
const MainScene=preload("res://game/main.tscn")
var rows:Array[Dictionary]=[]
var trace:Node
var proof_spheres:Array[MeshInstance3D]=[]
var swatch:ColorRect
var last_selected:=-1
var view:="side"
var side_count:=0
var chase_count:=0

class Trace extends Node:
	var rider:Node
	var frames:Array=[]
	func _physics_process(_delta:float)->void:
		frames.append({"physics":Engine.get_physics_frames(),"air":rider.airborne,"wall":rider.is_on_wall(),
			"floor":rider.is_on_floor(),"body":v(rider.global_position),"velocity":v(rider.velocity),
			"sequence":rider._ramp_air_sequence,"offset":v(rider._obstacle_visual_offset),
			"board":v(rider._board_visual.global_position),"rider":v(rider._rider_visual.global_position)})
	func v(a:Vector3)->Array:return [a.x,a.y,a.z]

func _run()->void:
	if DisplayServer.get_name()=="headless":quit(2);return
	var args:=OS.get_cmdline_user_args()
	if args.size()!=2 or args[1] not in ["side","chase"]:quit(2);return
	output=args[0]
	view=args[1]
	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	RenderingServer.set_render_loop_enabled(false)
	game=MainScene.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	trace=Trace.new()
	trace.rider=game.skater
	trace.process_physics_priority=200
	root.add_child(trace)
	_inspection=Camera3D.new()
	_inspection.name="IndependentPhysicalBodyFollowCamera"
	_inspection.fov=40
	_inspection.far=220
	_inspection.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	game.add_child(_inspection)
	var canvas:=CanvasLayer.new()
	canvas.layer=120
	root.add_child(canvas)
	swatch=ColorRect.new()
	swatch.position=Vector2(12,12)
	swatch.size=Vector2(12,12)
	canvas.add_child(swatch)
	for color:Color in [Color.RED,Color.GREEN]:
		var marker:=MeshInstance3D.new()
		var sphere:=SphereMesh.new()
		sphere.radius=.013
		sphere.height=.026
		marker.mesh=sphere
		marker.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test=true
		material.albedo_color=color
		marker.material_override=material
		game.add_child(marker)
		proof_spheres.append(marker)
	_check(not game.music._can_control and not game.music._persist,"personal Music and persistence isolated")
	await Lines.run_bank_jump_misses(self,game,_check,_observe_crown)
	_check((side_count==32 and chase_count==0) if view=="side" else (chase_count==3 and side_count==0),"declared full-prefix side32 or chase3 samples completed")
	_write(true)
	print("QA_FORECAST_CAPTURE_RESULT checks=",checks," failures=",failures," side=",side_count," chase=",chase_count," trace=",trace.frames.size())
	quit(1 if failures else 0)

func _observe_crown(phase:String,observed:Node,step:int)->void:
	if not phase.begins_with("east_bank_charged_top_miss_80.1_") or step<144 or step>175:return
	if view=="chase" and step not in [155,156,157]:return
	var before_tick:=Engine.get_physics_frames()
	var before_process:=Engine.get_process_frames()
	# Driver already fenced the production camera/HUD on every eighth step.
	# Creating a second timer during that timer callback would advance time.
	if step%8!=0:await create_timer(0.0,true).timeout
	_check(Engine.get_physics_frames()==before_tick and Engine.get_process_frames()==before_process,"observer fence preserves the original driver physics/process frame")
	var physics:=Engine.get_physics_frames()
	if last_selected>=0:_check(physics-last_selected==1,"selected32 samples are consecutive actual physics frames")
	last_selected=physics
	await _capture(view,phase,step)
	# Restore the actual camera/HUD for subsequent native driver observations.
	game.skater._camera.current=true
	game.hud.visible=true

func _capture(view:String,phase:String,step:int)->void:
	if view=="side":
		# Camera follows actual capsule position, never corrected visual bounds.
		var focus:Vector3=game.skater.global_position+Vector3.UP*.7
		_inspection.global_position=focus+Vector3(-4,1.5,-6).normalized()*6.4
		_inspection.look_at(focus)
		_inspection.reset_physics_interpolation()
		_inspection.current=true
		game.hud.visible=true
	else:
		game.skater._camera.current=true
		game.hud.visible=true
	var camera:Camera3D=root.get_camera_3d()
	var marker_pixels:=[Vector2(48,460),Vector2(1232,460)]
	for index:int in 2:proof_spheres[index].global_position=camera.project_position(marker_pixels[index],2.0)
	swatch.color=[Color.BLUE,Color.YELLOW,Color.MAGENTA][rows.size()%3]
	var before:=_pose(camera)
	var state:=_snapshot(game)
	state["presentation_offset"]=_v(game.skater._obstacle_visual_offset)
	state["forecast_active"]=not game.skater._obstacle_air_forecast.is_empty()
	var image:Image=await _render_current_frame()
	var after:=_pose(camera)
	_check(before==after,"camera/actual skater/board/rider/all bones unchanged across natural draw")
	var proofs:Array=[]
	for index:int in 2:
		var world:=proof_spheres[index].global_position
		var projected:=camera.unproject_position(world)
		var proof:=_marker_pixels(image,projected,index)
		proof["world"]=_v(world)
		proof["projected_pixel"]=[projected.x,projected.y]
		proofs.append(proof)
		_check(proof.count>=4 and proof.centroid_error<=2.5,"each native image proves current3D camera projection")
	_check(image.get_pixel(16,16).is_equal_approx(swatch.color),"each native image proves current Canvas state")
	var index:=side_count if view=="side" else chase_count
	var file:="frames/"+view+"-%03d.png"%index
	var storage:=_store_frame(image,file)
	rows.append({"file":file,"view":view,"phase":phase,"phase_step":step,"state":state,
		"before":before,"after":after,"markers":proofs,"canvas_pixel":[16,16],"canvas_expected":_color(swatch.color),"pixels":storage})
	if view=="side":side_count+=1
	else:chase_count+=1
	_write(false)
	print("QA_FORECAST_FRAME ",file," physics=",state.physics_frame," offset=",state.presentation_offset)

func _pose(camera:Camera3D)->Dictionary:
	var bones:Array=[]
	var skeleton:Skeleton3D=game.skater._visual_rig._garments.skeleton
	for index:int in skeleton.get_bone_count():bones.append(_t(skeleton.get_bone_global_pose(index)))
	var projection:=camera.get_camera_projection()
	return {"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames(),
		"camera":_t(camera.get_camera_transform()),"camera_global":_t(camera.global_transform),"physics_interpolation_fraction":Engine.get_physics_interpolation_fraction(),"projection":[_p(projection.x),_p(projection.y),_p(projection.z),_p(projection.w)],
		"fov":camera.fov,"near":camera.near,"far":camera.far,"keep_aspect":camera.keep_aspect,"viewport":[1280,800],
		"body":_t(game.skater.global_transform),"board":_t(game.skater._board_visual.global_transform),
		"visual":_t(game.skater._rider_visual.global_transform),"bones":bones}

func _t(a:Transform3D)->Dictionary:return {"x":_v(a.basis.x),"y":_v(a.basis.y),"z":_v(a.basis.z),"origin":_v(a.origin)}
func _p(a:Vector4)->Array:return [a.x,a.y,a.z,a.w]

func _write(complete:bool)->void:
	var report:={"schema":1,"view":view,"complete":complete,"checks":checks,"failures":failures,"side_count":side_count,"chase_count":chase_count,
		"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),
		"render_workload":"Entire ordinary default Main world, all meshes/colliders/scripts/light/shadows retained; authored body-follow side camera plus actual production chase/HUD.",
		"driver":"EXACT held LineDesign.run_bank_jump_misses full original78/78.7/79.4/80.1 sequence and native assertions; no shortened prefix. No actor/velocity/pose assignment by observer.",
		"camera_policy":"Side follows physical capsule, not corrected visual. At80.1phase144..175,32actual successive physics samples; separate full-prefix chase replay at155/156/157. Exactly one natural readback per physics frame.",
		"proof_policy":"Every image contains two small red/green3D diagnostic spheres at camera-projected corner points plus a12px changing Canvas swatch. Full numeric camera/projection, actual actor/board/rider/all bone pose and physics/process readback brackets retained.",
		"limits":"Qualitative source-bound replay only; diagnostic markers are declared. No Mac/FPS/CPU cost/human whole-animation or AAA acceptance. Entire1408-row physical parity must be independently checked.",
		"frames":rows,"trace":trace.frames}
	FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
