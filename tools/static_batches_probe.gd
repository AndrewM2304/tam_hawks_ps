extends SceneTree
## Same-world opaque batch and solid-wall occlusion comparison; counters, not FPS.
const World = preload("res://game/levels/glasgow_square.gd")
const Budget = preload("res://game/levels/render_budget.gd")
const Batches = preload("res://game/levels/static_batches.gd")
const VIEWS: Array[Dictionary] = [
	{"id": "royal_exchange", "at": Vector3(-22, 3.4, 34), "yaw": 0.0},
	{"id": "george_square", "at": Vector3(-22, 7.4, -68), "yaw": 0.0},
	{"id": "central_station", "at": Vector3(-57.757, 5.4, 26.243), "yaw": PI / 4.0},
	{"id": "barras", "at": Vector3(60, 3.4, 28), "yaw": 0.0},
	{"id": "clyde", "at": Vector3(15, 5.4, 61), "yaw": PI},
	{"id": "kelvingrove", "at": Vector3(-150.757, 9.4, -77.757), "yaw": PI / 4.0},
	{"id": "park_north", "at": Vector3(-204, 16, -146), "yaw": 0.0},
	{"id": "park_south", "at": Vector3(-204, 16, -146), "yaw": PI},
]
var world: Node3D
var camera: Camera3D
var output := ""
var rows: Array[Dictionary] = []
var failures := 0
const TRANSFORM_TOLERANCE := 0.0001
const CHANNEL_TOLERANCE := 1.0 / 255.0 + 0.000001

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or args.size() > 3 or (args.size() == 3 and args[2] != "--records-only"):
		quit(2)
		return
	var records_only := args.size() == 3
	output = ProjectSettings.globalize_path(args[0])
	var cell_size := float(args[1])
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	root.use_occlusion_culling = false
	Engine.max_fps = 0
	Engine.time_scale = 0.0
	world = World.new()
	world.set_meta("render_budget_probe_baseline", true)
	root.add_child(world)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Budget.apply_static_decor(world)
	camera = Camera3D.new()
	camera.fov = 68.0
	camera.far = 220.0
	root.add_child(camera)
	camera.make_current()
	for frame in 2: await RenderingServer.frame_post_draw
	var before_inventory := _inventory(world)
	var before_cpu := _capture_records(world, false)
	var before_gpu := _capture_records(world, true)
	var before_pair := _paired_records(before_cpu, before_gpu)
	print("STATIC_RECORDS before_authored_live ", JSON.stringify(before_pair))
	if not records_only: await _scan("before")
	var changes := Batches.finalize(world, cell_size)
	for frame in 2: await RenderingServer.frame_post_draw
	var after_cpu := _capture_records(world, false)
	var after_gpu := _capture_records(world, true)
	var after_pair := _paired_records(after_cpu, after_gpu)
	var cpu_preservation := _multiset_records(before_cpu, after_cpu, 0.0)
	var gpu_preservation := _multiset_records(before_gpu, after_gpu, CHANNEL_TOLERANCE)
	var preserved: bool = before_pair.ok and after_pair.ok and cpu_preservation.ok and gpu_preservation.ok
	if not preserved: failures += 1
	print("STATIC_RECORDS after_authored_live ", JSON.stringify(after_pair))
	print("STATIC_RECORDS cpu_preservation ", JSON.stringify(cpu_preservation))
	print("STATIC_RECORDS live_preservation ", JSON.stringify(gpu_preservation))
	if not records_only:
		await _scan("batched")
		root.use_occlusion_culling = true
		await _scan("occlusion")
	var report := {"schema":2, "engine":Engine.get_version_info(), "renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(), "resolution":[1280,800], "physics_and_gameplay":false,
		"performance_measurement":false, "cell_size":cell_size,"errors":failures,"records_preserved":preserved,
		"records_only":records_only,"transform_tolerance":TRANSFORM_TOLERANCE,"channel_tolerance":CHANNEL_TOLERANCE,
		"record_checks":{"before_authored_live":before_pair,"after_authored_live":after_pair,
			"authored_before_after":cpu_preservation,"live_before_after":gpu_preservation},
		"diagnostic_hash_quantization":0.001,"hashes_are_diagnostic_only":true,
		"before_cpu_hash":_records_hash(before_cpu),"before_gpu_hash":_records_hash(before_gpu),
		"after_cpu_hash":_records_hash(after_cpu),"after_gpu_hash":_records_hash(after_gpu),"inventory_before":before_inventory,
		"inventory_after":_inventory(world),"occluders":world.solid_wall_occluders,"changes":changes,"views":rows,
		"limits":"Frozen world-only geometry, real renderer. Initial resource sharing is baseline. Each authored/live source pair is checked directly; before/after records consume one matching record each in origin-neighbor buckets, with exact mesh/material/render state/channel flags and 0.1mm transform tolerance. Authored channels are exact; live channels allow 1/255 Compatibility precision. Quantized hashes are diagnostics only: rounding boundaries are not tolerance checks. Records-only mode has no view/FPS evidence. No FPS/Mac/human acceptance. time_scale=0 freezes shader animation; renderer and culling continue."}
	var file := FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("STATIC_BATCH_PROBE errors=",failures," preserved=",preserved," changes=",changes)
	quit(1 if failures else 0)

func _scan(phase:String) -> void:
	for view:Dictionary in VIEWS:
		camera.position=view.at
		camera.rotation=Vector3(-0.3154876,view.yaw,0)
		for frame in 4: await RenderingServer.frame_post_draw
		var draws:Array[int]=[]
		var primitives:Array[int]=[]
		for frame in 3:
			await RenderingServer.frame_post_draw
			draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
			primitives.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		draws.sort(); primitives.sort()
		var name := phase+"-"+str(view.id)+".png"
		if root.get_texture().get_image().save_png(output.path_join(name)) != OK: failures+=1
		rows.append({"phase":phase,"view":view.id,"draws":draws,"primitives":primitives,
			"draws_p50":draws[1],"primitives_p50":primitives[1],"image":name})
		print("STATIC_VIEW ",phase," ",view.id," draws=",draws[1]," primitives=",primitives[1])

func _records_hash(captured:Array[Dictionary]) -> String:
	var records:Array[String]=[]
	for record:Dictionary in captured:
		var numbers:PackedInt64Array=[]
		for value:float in _components(record.transform): numbers.append(roundi(value*1000.0))
		records.append(str(record.family)+"|"+str(numbers)+"|"+str(record.color)+"|"+str(record.custom))
	records.sort()
	return "\n".join(records).sha256_text()

func _capture_records(node:Node,live:bool) -> Array[Dictionary]:
	var records:Array[Dictionary]=[]
	_gather_records(node,live,records)
	return records

func _gather_records(node:Node,live:bool,records:Array[Dictionary]) -> void:
	if node is MultiMeshInstance3D and bool(node.get_meta(Batches.META_PERMISSION,false)):
		var authored:Dictionary=node.get_meta(Batches.META_RECORDS,{})
		var state:Dictionary=Batches._render_state(node)
		var mesh:MultiMesh=node.multimesh
		state.visible_in_tree=node.is_visible_in_tree()
		state.visible_instance_count=mesh.visible_instance_count
		state.multimesh_custom_aabb=mesh.custom_aabb
		var valid:bool=authored.get("transforms",[]).size()==mesh.instance_count \
			and authored.get("use_colors",false)==mesh.use_colors \
			and authored.get("use_custom_data",false)==mesh.use_custom_data \
			and (not mesh.use_colors or authored.get("colors",[]).size()==mesh.instance_count) \
			and (not mesh.use_custom_data or authored.get("custom_data",[]).size()==mesh.instance_count)
		if not valid:
			failures+=1
			push_error("STATIC_RECORDS invalid author records: "+str(node.get_path()))
			return
		var family:Array=[mesh.mesh.get_rid().get_id(),state,mesh.use_colors,mesh.use_custom_data]
		for i in mesh.instance_count:
			var local:Transform3D=mesh.get_instance_transform(i) if live else authored.transforms[i]
			var color:=Color.WHITE
			var custom:=Color(0,0,0,0)
			if mesh.use_colors: color=mesh.get_instance_color(i) if live else authored.colors[i]
			if mesh.use_custom_data: custom=mesh.get_instance_custom_data(i) if live else authored.custom_data[i]
			records.append({"family":family,"transform":node.global_transform*local,"local":local,
				"color":color,"custom":custom,"source":str(node.get_path()),"index":i})
	for child:Node in node.get_children(): _gather_records(child,live,records)

func _paired_records(authored:Array[Dictionary],live:Array[Dictionary]) -> Dictionary:
	var report:Dictionary={"ok":authored.size()==live.size(),"authored_records":authored.size(),
		"live_records":live.size(),"max_local_transform_error":0.0,"max_world_transform_error":0.0,
		"max_color_error":0.0,"max_custom_error":0.0,"exact_local_differences":0,
		"quantization_boundary_differences":0,"first_exact_difference":{},"first_failure":{}}
	for index:int in mini(authored.size(),live.size()):
		var a:Dictionary=authored[index]
		var b:Dictionary=live[index]
		var local_error:=_transform_error(a.local,b.local)
		var world_error:=_transform_error(a.transform,b.transform)
		var color_error:=_color_error(a.color,b.color)
		var custom_error:=_color_error(a.custom,b.custom)
		report.max_local_transform_error=maxf(report.max_local_transform_error,local_error)
		report.max_world_transform_error=maxf(report.max_world_transform_error,world_error)
		report.max_color_error=maxf(report.max_color_error,color_error)
		report.max_custom_error=maxf(report.max_custom_error,custom_error)
		if a.local!=b.local:
			report.exact_local_differences+=1
			if report.first_exact_difference.is_empty(): report.first_exact_difference=_difference(a,b)
		if _quantized_transform(a.transform)!=_quantized_transform(b.transform):
			report.quantization_boundary_differences+=1
		var valid:bool=a.source==b.source and a.index==b.index and a.family==b.family \
			and local_error<=TRANSFORM_TOLERANCE and world_error<=TRANSFORM_TOLERANCE \
			and color_error<=CHANNEL_TOLERANCE and custom_error<=CHANNEL_TOLERANCE
		if not valid:
			report.ok=false
			if report.first_failure.is_empty(): report.first_failure=_difference(a,b)
	return report

func _multiset_records(before:Array[Dictionary],after:Array[Dictionary],channel_tolerance:float) -> Dictionary:
	var report:Dictionary={"ok":before.size()==after.size(),"before_records":before.size(),
		"after_records":after.size(),"matched_records":0,"unmatched_records":0,
		"max_world_transform_error":0.0,"max_color_error":0.0,"max_custom_error":0.0,"first_failure":{},
		"quantization_boundary_differences":0,"first_quantization_boundary_difference":{}}
	var families:Dictionary={}
	for record:Dictionary in after:
		if not families.has(record.family): families[record.family]={}
		var buckets:Dictionary=families[record.family]
		var cell:=_origin_cell(record.transform.origin)
		if not buckets.has(cell): buckets[cell]=[]
		buckets[cell].append(record)
	for original:Dictionary in before:
		var matched:Dictionary={}
		var buckets:Dictionary=families.get(original.family,{})
		var cell:=_origin_cell(original.transform.origin)
		for dx:int in [-1,0,1]:
			if not matched.is_empty(): break
			for dy:int in [-1,0,1]:
				if not matched.is_empty(): break
				for dz:int in [-1,0,1]:
					var candidates:Array=buckets.get(cell+Vector3i(dx,dy,dz),[])
					for index:int in candidates.size():
						var candidate:Dictionary=candidates[index]
						if _transform_error(original.transform,candidate.transform)<=TRANSFORM_TOLERANCE \
							and _color_error(original.color,candidate.color)<=channel_tolerance \
							and _color_error(original.custom,candidate.custom)<=channel_tolerance:
							matched=candidate
							candidates.remove_at(index) # Every output record is consumed once.
							break
					if not matched.is_empty(): break
		if matched.is_empty():
			report.ok=false
			report.unmatched_records+=1
			if report.first_failure.is_empty():
				report.first_failure={"source":original.source,"index":original.index,
					"world_transform":_components(original.transform),"compatible_family_present":families.has(original.family)}
		else:
			report.matched_records+=1
			report.max_world_transform_error=maxf(report.max_world_transform_error,_transform_error(original.transform,matched.transform))
			report.max_color_error=maxf(report.max_color_error,_color_error(original.color,matched.color))
			report.max_custom_error=maxf(report.max_custom_error,_color_error(original.custom,matched.custom))
			if _quantized_transform(original.transform)!=_quantized_transform(matched.transform):
				report.quantization_boundary_differences+=1
				if report.first_quantization_boundary_difference.is_empty():
					report.first_quantization_boundary_difference={"before_source":original.source,"before_index":original.index,
						"after_source":matched.source,"after_index":matched.index,
						"world_error":_transform_error(original.transform,matched.transform),
						"world_before":_components(original.transform),"world_after":_components(matched.transform)}
	return report

func _origin_cell(at:Vector3) -> Vector3i:
	return Vector3i(floori(at.x/TRANSFORM_TOLERANCE),floori(at.y/TRANSFORM_TOLERANCE),floori(at.z/TRANSFORM_TOLERANCE))

func _components(transform:Transform3D) -> Array[float]:
	var result:Array[float]=[]
	for vector:Vector3 in [transform.basis.x,transform.basis.y,transform.basis.z,transform.origin]:
		result.append_array([vector.x,vector.y,vector.z])
	return result

func _quantized_transform(transform:Transform3D) -> PackedInt64Array:
	var result:PackedInt64Array=[]
	for value:float in _components(transform): result.append(roundi(value*1000.0))
	return result

func _transform_error(a:Transform3D,b:Transform3D) -> float:
	return maxf(maxf(a.origin.distance_to(b.origin),a.basis.x.distance_to(b.basis.x)),
		maxf(a.basis.y.distance_to(b.basis.y),a.basis.z.distance_to(b.basis.z)))

func _color_error(a:Color,b:Color) -> float:
	return maxf(maxf(absf(a.r-b.r),absf(a.g-b.g)),maxf(absf(a.b-b.b),absf(a.a-b.a)))

func _difference(a:Dictionary,b:Dictionary) -> Dictionary:
	return {"source":a.source,"index":a.index,"other_source":b.source,"other_index":b.index,
		"same_mesh_material_state":a.family==b.family,"local_error":_transform_error(a.local,b.local),
		"world_error":_transform_error(a.transform,b.transform),
		"local_authored":_components(a.local),"local_live":_components(b.local),
		"world_authored":_components(a.transform),"world_live":_components(b.transform),
		"color_error":_color_error(a.color,b.color),"custom_error":_color_error(a.custom,b.custom)}

func _inventory(node:Node) -> Dictionary:
	var result={"nodes":1,"multimeshes":int(node is MultiMeshInstance3D),"bodies":int(node is PhysicsBody3D),"shapes":int(node is CollisionShape3D)}
	for child:Node in node.get_children():
		var nested:=_inventory(child)
		for key:String in result: result[key]+=nested[key]
	return result
