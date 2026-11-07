extends SceneTree
## PRIVATE authored asset fixture. Two separate native processes load exact
## Actual Main CURRENT pose replay, no physics resimulation or city rendering.
class RigBody:
	extends CharacterBody3D
	var _visual_rig: RefCounted
	var airborne := false
	var speed := 0.0
var OUTPUT := "res://output"
var fixture: Dictionary
var camera: Camera3D
var frames: Array[Dictionary] = []
var failures := 0
var source_before: Dictionary
var sync_markers: Array[MeshInstance3D] = []
var rig: RefCounted
var body: RigBody
var board: Node3D
var rider: Node3D
var variant := "control"
var skin_refs: Dictionary = {}
var geometry: Dictionary = {}
var authored_state: Dictionary = {}
var allocation_before: Dictionary
func _initialize() -> void:
	_run.call_deferred()
func _run()->void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1 or args[0] not in ["control","candidate"]:
		push_error("Explicit replay variant required")
		quit(2)
		return
	variant=args[0]
	OUTPUT="res://arm-replay-output/"+variant
	DirAccess.make_dir_recursive_absolute(OUTPUT+"/synchronization")
	root.size=Vector2i(1280,800)
	source_before=_sources()
	var stage:=Node3D.new()
	root.add_child(stage)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("29333d")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("b9c9dc")
	env.environment.ambient_light_energy=.36
	env.environment.tonemap_mode=Environment.TONE_MAPPER_ACES
	stage.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-35,0)
	sun.light_energy=.86
	sun.shadow_enabled=true
	stage.add_child(sun)
	var floor_mesh:=MeshInstance3D.new()
	var floor_plane:=PlaneMesh.new()
	floor_plane.size=Vector2(200,200)
	floor_mesh.mesh=floor_plane
	var floor_mat:=StandardMaterial3D.new()
	floor_mat.albedo_color=Color("66727e")
	floor_mat.roughness=1.0
	floor_mesh.material_override=floor_mat
	stage.add_child(floor_mesh)
	camera=Camera3D.new()
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	stage.add_child(camera)
	for color:Color in [Color.RED,Color.GREEN,Color.BLUE]:
		var marker:=MeshInstance3D.new()
		marker.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		var sphere:=SphereMesh.new()
		sphere.radius=1.0
		sphere.height=2.0
		marker.mesh=sphere
		var mat:=StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color=color
		mat.no_depth_test=true
		marker.material_override=mat
		marker.visible=false
		stage.add_child(marker)
		sync_markers.append(marker)
	body=RigBody.new()
	stage.add_child(body)
	body.process_mode=Node.PROCESS_MODE_DISABLED
	body.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var visual:=Node3D.new()
	body.add_child(visual)
	board=Node3D.new()
	board.name="Board"
	board.position.y=.12
	visual.add_child(board)
	rider=Node3D.new()
	rider.name="Rider"
	rider.basis=Basis(Vector3.UP,-PI/2+.28)
	visual.add_child(rider)
	var factory:Script=load("res://replay_control_visual.gd"if variant=="control"else"res://game/player/skater_visual.gd")
	rig=factory.new()
	body._visual_rig=rig
	var shirt:=StandardMaterial3D.new()
	shirt.albedo_color=Color("4d6270")
	rig.build(board,rider,shirt)
	fixture={"root":stage,"rider":body}
	for cloth:MeshInstance3D in rig._garments._surfaces:skin_refs[str(cloth.name)]=rig._garments.skeleton.register_skin(cloth.skin)
	geometry=_geometry()
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://arm-replay-input.json"))
	for selected:Dictionary in data.variants[variant]:
		var r:Dictionary=selected.row.rig
		body.global_transform=_transform(r.actor)
		board.global_transform=_transform(r.board)
		rider.global_transform=_transform(r.rider)
		rig._upper.global_transform=_transform(r.upper)
		rig._head.global_transform=_transform(r.head)
		for i in 2:
			rig._arms[i].hand.global_transform=_transform(r["hand"+str(i)])
			rig._legs[i].foot.global_transform=_transform(r["foot"+str(i)])
		for i in r.bones.size():rig._garments.skeleton.set_bone_global_pose(i,_transform(r.bones[i]))
		body.speed=float(selected.row.state.speed)
		body.airborne=bool(selected.row.state.airborne)
		rig._push_phase=float(r.push_phase)
		rig._push_blend=float(r.push_blend)
		body.reset_physics_interpolation()
		var toward:=body.global_position+Vector3(0,.85,0)
		await _native_frame()
		await shot(selected.label,toward+Vector3(2.4,.50,-2.7),toward,40.)
		frames[-1]["source_record"]=selected
		frames[-1]["replay_scope"]="Recorded currentpose applied directly; actor interpolationOFF onlyinthis isolatedfixture. All nativefeet/body/bones fromoriginal60Hz clock, no input/physics resimulation, no normalcadence claim. Productionstrength sun/ambient numericcontrols .86/.36, isolatedfloor ratherthancitylighting."
		_flush(false)
	_flush(true)
	quit(1 if failures else 0)
func _transform(a:Array)->Transform3D:
	return Transform3D(Basis(Vector3(a[0][0],a[1][0],a[2][0]),Vector3(a[0][1],a[1][1],a[2][1]),Vector3(a[0][2],a[1][2],a[2][2])),Vector3(a[0][3],a[1][3],a[2][3]))
func _state()->Dictionary:
	return {"airborne":false,"grab":false,"flip":false,"manual":false,"grind":false,"speed":0.0,"push":false,"brake":false}
func _pose(state:Dictionary,ticks:int)->void:
	authored_state=state.duplicate(true)
	body.airborne=state.airborne
	body.speed=state.speed
	for tick in ticks:
		rig.animate(1.0/60.0,state)
	await _native_frame()
func _view(label:String,from:Vector3,toward:Vector3,fov:float)->void:
	await shot(label,from,toward,fov)
	frames[-1]["authored_state"]=authored_state.duplicate(true)
	frames[-1]["variant"]=variant
	frames[-1]["native_allocation"]=_allocation()
	frames[-1]["skin_state"]=_skin_state()
	_flush(false)
func _flush(complete:bool)->void:
	var after:=_sources()
	if source_before!=after:
		failures+=1
		push_error("Knee private sourcechanged")
	var file:=FileAccess.open(OUTPUT+"/receipt.json.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"Privateauthored assetfixture, exactcontrol11transported03 vsderived11bonekneerefinement. No Main/input/moving/targetperformance/AAA acceptance.","variant":variant,"complete":complete,"frames":frames,"failures":failures,"source_before":source_before,"source_after":after,"source_stable":source_before==after,"native_geometry":geometry,"allocation_before":allocation_before,"allocation_final":_allocation(),"clock":"CURRENTstate replay only: actor andposedsubtreesOFF, sourcephysics/process countersretained separately. SourceactualMain interpolation/cadence isnotresimulated. ActualRS/current/rendered modelsrecorded."},"\t"))
	file.close()
	DirAccess.rename_absolute(OUTPUT+"/receipt.json.tmp",OUTPUT+"/receipt.json")
func _allocation()->Dictionary:
	return {"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),"buffer_bytes":int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),"scope":"Nativeisolated component processmonitors, includesviewport/lights/floor/loadedselectedrig. Not FPS/comparativeGPUtiming/targetMac."}
func _sources()->Dictionary:
	var out:Dictionary={}
	for dir:String in ["res://game","res://tests"]:_scan(dir,out)
	for file:String in ["res://project.godot","res://arm_replay.gd","res://replay_control_visual.gd","res://arm-replay-input.json"]:out[file]=FileAccess.get_sha256(file)
	return out
func _scan(dir:String,out:Dictionary)->void:
	for file:String in DirAccess.get_files_at(dir):out[dir+"/"+file]=FileAccess.get_sha256(dir+"/"+file)
	for child:String in DirAccess.get_directories_at(dir):_scan(dir+"/"+child,out)
func _xyz(values:PackedVector3Array)->Array:
	var out:Array=[]
	for v:Vector3 in values:out.append([v.x,v.y,v.z])
	return out
func _uv(values:PackedVector2Array)->Array:
	var out:Array=[]
	for v:Vector2 in values:out.append([v.x,v.y])
	return out
func _geometry()->Dictionary:
	var out:Dictionary={}
	for cloth:MeshInstance3D in rig._garments._surfaces:
		var a:=cloth.mesh.surface_get_arrays(0)
		var binds:Array=[]
		for i in cloth.skin.get_bind_count():binds.append({"bone":cloth.skin.get_bind_bone(i),"name":String(cloth.skin.get_bind_name(i)),"pose":_matrix(cloth.skin.get_bind_pose(i))})
		out[String(cloth.name)]={"positions":_xyz(a[Mesh.ARRAY_VERTEX]),"normals":_xyz(a[Mesh.ARRAY_NORMAL]),"uv":_uv(a[Mesh.ARRAY_TEX_UV]),"indices":Array(a[Mesh.ARRAY_INDEX]),"joints":Array(a[Mesh.ARRAY_BONES]),"weights":Array(a[Mesh.ARRAY_WEIGHTS]),"binds":binds,"mesh_surfaces":cloth.mesh.get_surface_count(),"skin_bind_count":cloth.skin.get_bind_count()}
	return out
func _skin_state()->Dictionary:
	var out:Dictionary={}
	for cloth:MeshInstance3D in rig._garments._surfaces:
		var reference:SkinReference=skin_refs[String(cloth.name)]
		var rows:Array=[]
		for i in cloth.skin.get_bind_count():rows.append(_matrix(RenderingServer.skeleton_bone_get_transform(reference.get_skeleton(),i)))
		out[String(cloth.name)]={"rs_palette":rows,"model_current":_matrix(cloth.global_transform),"model_rendered":_matrix(cloth.get_global_transform_interpolated()),"skeleton_current":_matrix(rig._garments.skeleton.global_transform),"skeleton_rendered":_matrix(rig._garments.skeleton.get_global_transform_interpolated())}
	return out
func _pose_snapshot()->Dictionary:
	var skeleton:Skeleton3D=rig._garments.skeleton
	var bones:Dictionary={}
	for i in skeleton.get_bone_count():bones[skeleton.get_bone_name(i)]=_matrix(skeleton.get_bone_global_pose(i))
	var projection:=camera.get_camera_projection()
	var limbs:Dictionary={}
	for i in 2:
		limbs["hand"+str(i)]=_matrix(rig._arms[i].hand.global_transform)
		limbs["foot"+str(i)]=_matrix(rig._legs[i].foot.global_transform)
	return {"camera_global":_matrix(camera.global_transform),"camera_near":camera.near,"camera_far":camera.far,"camera_projection_columns":[[projection.x.x,projection.x.y,projection.x.z,projection.x.w],[projection.y.x,projection.y.y,projection.y.z,projection.y.w],[projection.z.x,projection.z.y,projection.z.z,projection.z.w],[projection.w.x,projection.w.y,projection.w.z,projection.w.w]],"viewport_pixels":[root.size.x,root.size.y],"head_global":_matrix(rig._head.global_transform),"rider_global":_matrix(rider.global_transform),"board_global":_matrix(board.global_transform),"skeleton_global":_matrix(skeleton.global_transform),"bone_global_pose_in_skeleton":bones,"native_limb_models":limbs,"skin_state":_skin_state()}
func shot(label: String, from: Vector3, toward: Vector3, field_of_view: float) -> void:
	fixture.rider.set_physics_process(false)
	fixture.rider.set_process(false)
	camera.global_position = from
	camera.look_at(toward)
	camera.fov = field_of_view
	camera.current = true
	camera.reset_physics_interpolation()
	var depth := from.distance_to(toward)
	var marker_points: Array[Vector3] = [toward,
		toward + camera.global_basis.x * depth * 0.07,
		toward + camera.global_basis.y * depth * 0.07]
	for index in sync_markers.size():
		sync_markers[index].global_position = marker_points[index]
		sync_markers[index].scale = Vector3.ONE * depth * 0.003
		sync_markers[index].visible = true
	var pose_before := _pose_snapshot()
	await _native_frame()
	var proof_pose_before := _pose_snapshot()
	var proof_tick_before := _frame_counts()
	var proof_image := root.get_texture().get_image()
	var proof_tick_after := _frame_counts()
	var proof_pose_after := _pose_snapshot()
	proof_image.convert(Image.FORMAT_RGBA8)
	var proof_path := OUTPUT + "/synchronization/" + label + ".png"
	if proof_image.save_png(proof_path) != OK:
		failures += 1
		push_error("Could not save studio synchronization frame " + label)
	for marker: MeshInstance3D in sync_markers:
		marker.visible = false
	# Let the native draw loop consume the current camera and scene transforms.
	# A manual force_draw immediately after a camera change can retain pixels
	# from the preceding view, so it is not used as current-frame proof.
	await _native_frame()
	var path := OUTPUT + "/" + label + ".png"
	var clean_pose_before := _pose_snapshot()
	var clean_tick_before := _frame_counts()
	var clean_image := root.get_texture().get_image()
	var clean_tick_after := _frame_counts()
	var clean_pose_after := _pose_snapshot()
	clean_image.convert(Image.FORMAT_RGBA8)
	if clean_image.save_png(path) != OK:
		failures += 1
		push_error("Could not save rider studio frame " + label)
	var proofs: Array[Dictionary] = []
	for index in sync_markers.size():
		var projected := camera.unproject_position(marker_points[index])
		projected *= Vector2(proof_image.get_size()) / root.get_visible_rect().size
		var proof := _marker_pixels(proof_image, clean_image, projected, index)
		proof.world_position = marker_points[index]
		proof.projected_pixel = projected
		proofs.append(proof)
		if proof.count < 4 or proof.centroid_error > 2.5:
			failures += 1
			push_error("Studio projected-pixel camera synchronization failed " + label)
	if pose_before != proof_pose_before or pose_before != proof_pose_after or pose_before != clean_pose_before or pose_before != clean_pose_after or proof_tick_before != proof_tick_after or clean_tick_before != clean_tick_after:
		failures += 1
		push_error("Studio rig/camera pose or frame counter changed during readback: " + label)
	if not camera.is_current():
		failures += 1
		push_error("The intended rider studio camera did not own the native frame.")
	frames.append({"label": label, "path": path, "position": fixture.rider.global_position,
		"airborne": fixture.rider.airborne, "speed": fixture.rider.speed,
		"png_sha256": FileAccess.get_sha256(path), "camera_current": camera.is_current(),
		"camera_position": camera.global_position, "camera_fov": camera.fov,
		"native_frame": Engine.get_process_frames(), "synchronization": proofs,
		"native_rgba_sha256": _image_sha256(clean_image), "synchronization_native_rgba_sha256": _image_sha256(proof_image),
		"proof_readback_counter_bracket": [proof_tick_before,proof_tick_after], "clean_readback_counter_bracket": [clean_tick_before,clean_tick_after],
		"proof_readback_pose_bracket": [proof_pose_before,proof_pose_after], "clean_readback_pose_bracket": [clean_pose_before,clean_pose_after],
		"native_state": clean_pose_after, "rendered_head_world": _matrix(fixture.rider._visual_rig._head.get_global_transform_interpolated()),
		"rendered_rider_world": _matrix(fixture.rider._visual_rig._rider.get_global_transform_interpolated()),
		"physics_interpolation_fraction": Engine.get_physics_interpolation_fraction(),
		"synchronization_png_sha256": FileAccess.get_sha256(proof_path)})
	fixture.rider.set_physics_process(true)
	fixture.rider.set_process(true)

func _native_frame() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw

func _marker_pixels(image: Image, clean_image: Image, projected: Vector2, channel: int) -> Dictionary:
	var total := Vector2.ZERO
	var count := 0
	for y in range(maxi(0, int(projected.y) - 12), mini(image.get_height(), int(projected.y) + 13)):
		for x in range(maxi(0, int(projected.x) - 12), mini(image.get_width(), int(projected.x) + 13)):
			var pixel := image.get_pixel(x, y)
			var clean := clean_image.get_pixel(x,y)
			var changed := absf(pixel.r-clean.r)+absf(pixel.g-clean.g)+absf(pixel.b-clean.b)>0.12
			var components := [pixel.r, pixel.g, pixel.b]
			if changed and components[channel] > 0.75 and components[channel] - components[(channel + 1) % 3] > 0.2 \
				and components[channel] - components[(channel + 2) % 3] > 0.2:
				count += 1
				total += Vector2(x + 0.5, y + 0.5)
	return {"count": count, "centroid_error": (total / count).distance_to(projected) if count else 999.0,
		"color_channel": ["red", "green", "blue"][channel]}

func _frame_counts() -> Dictionary:
	return {"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames()}

func _matrix(value: Transform3D) -> Array:
	return [[value.basis.x.x,value.basis.y.x,value.basis.z.x,value.origin.x],
		[value.basis.x.y,value.basis.y.y,value.basis.z.y,value.origin.y],
		[value.basis.x.z,value.basis.y.z,value.basis.z.z,value.origin.z],[0,0,0,1]]

func _image_sha256(value: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.get_data())
	return context.finish().hex_encode()
