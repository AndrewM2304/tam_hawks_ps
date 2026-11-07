extends SceneTree
const World = preload("res://game/levels/merchant_neighbourhood.gd")
const Art = preload("res://game/levels/art/merchant_architecture.gd")
var checks := 0
var failures := 0
var cases: Array[Dictionary] = []
var world: Node3D
var art: Node3D
var result: Dictionary = {}
var render_camera: Camera3D
var sync_markers: Array[MeshInstance3D] = []

func _initialize() -> void: _run.call_deferred()
func _check(ok: bool,label: String) -> void:
	checks += 1
	cases.append({"pass":ok,"message":label})
	if not ok: failures += 1; push_error("FAIL: "+label)

func _run() -> void:
	world = World.new()
	get_root().add_child(world)
	await physics_frame
	var baseline: Array = _native(world)
	var original_geometry: Dictionary = _geometry(world)
	var material_ids: Array = []
	for value: Material in world._materials.values(): material_ids.append(value.get_instance_id())
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://architecture-layout.json"))
	var baseline_api: Dictionary = {}
	var baseline_views: Array[Dictionary] = []
	if OS.get_cmdline_user_args().has("--render-six"):
		_setup_camera(layout)
		for warm: int in 4: await process_frame
		await RenderingServer.frame_post_draw
		baseline_views = await _render_six(layout,"baseline")
		baseline_api = _render_counters()
	art = Art.build(world,world._materials,layout)
	_check(_native(world)==baseline,"every original native body/shape/transform/layer/property remains exact after art construction")
	_check(art.report.errors.is_empty(),"six frontage contracts match actual native front planes and register static batches")
	_check(art.report.frontages.size()==6,"all six requested hero frontages have actual native-backed architecture")
	var geometry: Dictionary = _geometry(world)
	var art_geometry: Dictionary = _geometry(art)
	_check(geometry.triangles-original_geometry.triangles<=90000,"visible source triangle delta remains within declared90000 ceiling")
	_check(art_geometry.nodes<=48,"all submitted art geometry nodes, including shells/vector signs, remain within48")
	_check(art_geometry.serialized_mesh_and_instance_bytes<=4*1024*1024,"serialized CPU arrays/instance records within4MiB proxy (not actual GPU allocation)")
	_check(_native(art).is_empty(),"art helper adds no native collider, body, trigger or gameplay portal")
	var shared := true
	for item: GeometryInstance3D in _geometry_nodes(art):
		shared = shared and item.material_override!=null and material_ids.has(item.material_override.get_instance_id())
	_check(shared,"every submitted architectural surface shares an exact existing material object")
	var aperture_count := 0
	for entry: Dictionary in art.report.openings:
		var node := art.get_node(NodePath(entry.shell)) as MeshInstance3D
		var r: Rect2 = entry.rectangle
		var point := r.get_center()
		var arrays: Array = node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var z: float = node.mesh.get_aabb().end.z
		var covered := false
		for i: int in range(0,indices.size(),3):
			var a := vertices[indices[i]]; var b := vertices[indices[i+1]]; var c := vertices[indices[i+2]]
			if absf(a.z-z)>.0001 or absf(b.z-z)>.0001 or absf(c.z-z)>.0001: continue
			if Geometry2D.is_point_in_polygon(point,PackedVector2Array([Vector2(a.x,a.y),Vector2(b.x,b.y),Vector2(c.x,c.y)])): covered = true
		_check(not covered,"native uploaded shell has a real front aperture at recorded opening%d"%aperture_count)
		aperture_count += 1
	_check(aperture_count>=30,"recesses are genuine whole-world apertures, not black panes on complete walls")
	_check(_reserved_clear(layout),"roof channel, open close and underpass retain declared native clearance envelopes")
	result = {"checks":checks,"failures":failures,"cases":cases,"baseline_geometry":original_geometry,"candidate_geometry":geometry,"art_geometry":art_geometry,
		"native_shape_count":baseline.size(),"baseline_api":baseline_api,"baseline_views":baseline_views,"art_report":art.report,"engine":Engine.get_version_info(),
		"scope":"Private selected-world native structural/CPU inventory. GPU allocation, per-view draws, moving quality and M5 remain separate."}
	for arg: String in OS.get_cmdline_user_args():
		if arg=="--render-six":
			result["candidate_views"] = await _render_six(layout,"candidate")
			var native_api := _render_counters()
			result["candidate_api"] = native_api
			result["native_buffer_delta_bytes"] = native_api.buffer_memory-baseline_api.buffer_memory
			result["native_texture_delta_bytes"] = native_api.texture_memory-baseline_api.texture_memory
			_check(result.native_buffer_delta_bytes<=4*1024*1024,"actual per-process GPU mesh/instance allocation increment within4MiB")
			_check(result.native_texture_delta_bytes==0,"actual per-process texture allocation remains unchanged")
			for phase: String in ["baseline_views","candidate_views"]:
				for view: Dictionary in result[phase]:
					var proof: Dictionary = view.synchronization
					_check(proof.canvas_pass and proof.world_markers[0].pass and proof.world_markers[1].pass,"same-camera/Canvas native pixel witnesses pass "+phase+"/"+view.id)
	result.checks = checks;result.failures = failures
	var file := FileAccess.open("res://native-result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")+"\n");file.close()
	print("MERCHANT_ARCHITECTURE: %d passed,%d failed"%[checks-failures,failures])
	quit(1 if failures else 0)

func _native(node: Node) -> Array:
	var data: Array = []
	if node is CollisionObject3D:
		data.append([str(node.get_path()),node.get_class(),node.transform,node.collision_layer,node.collision_mask])
	if node is CollisionShape3D:
		var shape: Shape3D = node.shape
		var properties: Dictionary = {}
		for property: Dictionary in shape.get_property_list():
			if int(property.usage)&PROPERTY_USAGE_STORAGE and property.name not in ["resource_name","resource_local_to_scene","script"]:
				properties[property.name] = shape.get(property.name)
		data.append([str(node.get_path()),node.transform,node.disabled,shape.get_class(),properties])
	for child: Node in node.get_children(): data.append_array(_native(child))
	return data

func _geometry_nodes(node: Node) -> Array[GeometryInstance3D]:
	var nodes: Array[GeometryInstance3D] = []
	if node is MeshInstance3D or node is MultiMeshInstance3D:
		if node.is_visible_in_tree(): nodes.append(node)
	for child: Node in node.get_children(): nodes.append_array(_geometry_nodes(child))
	return nodes

func _geometry(node: Node) -> Dictionary:
	var triangles := 0
	var unique: Dictionary = {}
	var bytes := 0
	var nodes: Array[GeometryInstance3D] = _geometry_nodes(node)
	for item: GeometryInstance3D in nodes:
		var mesh: Mesh = item.mesh if item is MeshInstance3D else item.multimesh.mesh
		var count: int = 1 if item is MeshInstance3D else item.multimesh.instance_count
		if not unique.has(mesh.get_instance_id()):
			var tri := 0
			for surface: int in mesh.get_surface_count():
				var arrays := mesh.surface_get_arrays(surface)
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				tri += (indices.size() if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size())/3
				bytes += var_to_bytes(arrays).size()
			unique[mesh.get_instance_id()] = tri
		triangles += unique[mesh.get_instance_id()]*count
		if item is MultiMeshInstance3D: bytes += count*12*4
	return {"triangles":triangles,"nodes":nodes.size(),"unique_meshes":unique.size(),"serialized_mesh_and_instance_bytes":bytes}

func _reserved_clear(layout: Dictionary) -> bool:
	for reservation: Dictionary in layout.reserved_openings:
		if reservation.id not in ["ground_underpass","upper_close_lower_opening","depot_roof_gap"]: continue
		var b: Array = reservation.bounds_xz
		var low: float = float(reservation.get("floor_y",reservation.get("air_y_from",10.0)))
		var high: float = float(reservation.get("clear_to_y",30.0))
		var region := AABB(Vector3(b[0]+.01,low+.01,b[1]+.01),Vector3(b[2]-b[0]-.02,high-low-.02,b[3]-b[1]-.02))
		for item: GeometryInstance3D in _geometry_nodes(art):
			var mesh: Mesh = item.mesh if item is MeshInstance3D else item.multimesh.mesh
			var transforms: Array = [Transform3D.IDENTITY] if item is MeshInstance3D else preload("res://game/levels/static_batches.gd").authored_transforms(item)
			for xform: Transform3D in transforms:
				var bounds: AABB = (item.global_transform*xform)*mesh.get_aabb()
				# Whole closed replacement shell includes retained non-facing mass
				# surfaces; original native fragments already define these clear.
				if item.name.begins_with("CutShell_"): continue
				if region.intersects(bounds):
					print("RESERVED HIT ",reservation.id," ",item.name," ",bounds)
					return false
	return true

func _render_six(layout: Dictionary,phase: String) -> Array[Dictionary]:
	var camera := render_camera
	var views: Array[Dictionary] = []
	for frontage: Dictionary in layout.hero_frontages:
		var a: Array = frontage.view_from; var b: Array = frontage.view_to
		camera.position = Vector3(a[0],a[1],a[2])
		camera.look_at(Vector3(b[0],b[1],b[2]))
		for warm: int in 3: await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_root().get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		var bytes: PackedByteArray = image.get_data()
		var hash := HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
		var path := "res://"+phase+"-"+str(frontage.id)+".png"
		image.save_png(path)
		views.append({"id":frontage.id,"png":path,"png_sha256":FileAccess.get_sha256(path),"raw_rgba_sha256":hash.finish().hex_encode(),"size":[image.get_width(),image.get_height()],
			"position":camera.global_position,"basis":camera.global_basis,"projection":camera.get_camera_projection(),"fov":camera.fov,"near":camera.near,"far":camera.far,
			"process_frames":Engine.get_process_frames(),"physics_frames":Engine.get_physics_frames(),
			"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"buffer_memory":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),"texture_memory":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"synchronization":_sync_proof(image,camera)})
		var partial := FileAccess.open("res://"+phase+"-partial.json",FileAccess.WRITE)
		partial.store_string(JSON.stringify({"phase":phase,"views":views},"\t")+"\n");partial.close()
		print("CAPTURE ",phase," ",frontage.id)
	return views

func _setup_camera(layout: Dictionary) -> void:
	render_camera = Camera3D.new()
	get_root().add_child(render_camera)
	render_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	render_camera.fov = 70.0; render_camera.near = .1; render_camera.far = 250.0; render_camera.current = true
	var view: Dictionary = layout.hero_frontages[0]
	var a: Array = view.view_from; var b: Array = view.view_to
	render_camera.position = Vector3(a[0],a[1],a[2]);render_camera.look_at(Vector3(b[0],b[1],b[2]))
	# Observer-only synchronization witnesses, equal in baseline/candidate. They
	# are outside the art/world inventories and use two tiny unshaded materials.
	for index: int in 2:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new();sphere.radius = .035;sphere.height = .07;sphere.radial_segments = 8;sphere.rings = 4
		var material := StandardMaterial3D.new();material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = true
		material.albedo_color = Color(1,0,1) if index==0 else Color(0,1,1)
		marker.mesh = sphere;marker.material_override = material;marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		render_camera.add_child(marker);marker.position = Vector3(-.65 if index==0 else .65,-.40,-2)
		sync_markers.append(marker)
	var canvas := CanvasLayer.new();get_root().add_child(canvas)
	var patch := ColorRect.new();patch.position = Vector2(12,12);patch.size = Vector2(9,9);patch.color = Color(.125,.875,.375)
	canvas.add_child(patch)

func _render_counters() -> Dictionary:
	return {"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"buffer_memory":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),"texture_memory":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"scope":"Per-process native API; warm source baseline includes identical observer markers/Canvas, no timing claim."}

func _sync_proof(image: Image,camera: Camera3D) -> Dictionary:
	var witnesses: Array = []
	for index: int in 2:
		var marker := sync_markers[index]
		var logical: Vector2 = camera.unproject_position(marker.global_position)
		var pixel: Vector2 = logical*Vector2(image.get_size())/camera.get_viewport().get_visible_rect().size
		var actual: Color = image.get_pixel(clampi(roundi(pixel.x),0,image.get_width()-1),clampi(roundi(pixel.y),0,image.get_height()-1))
		var expected := Color(1,0,1) if index==0 else Color(0,1,1)
		witnesses.append({"world":marker.global_position,"projected_pixel":pixel,"sample_rgba8":actual.to_html(),"expected_rgb":expected.to_html(),
			"pass":(actual.r>.75 and actual.g<.15 and actual.b>.75) if index==0 else (actual.r<.15 and actual.g>.75 and actual.b>.75)})
	var canvas_pixel := Vector2i(Vector2(16,16)*Vector2(image.get_size())/camera.get_viewport().get_visible_rect().size)
	var actual: Color = image.get_pixelv(canvas_pixel)
	return {"world_markers":witnesses,"canvas_rgba8":actual.to_html(),"canvas_pixel":canvas_pixel,"logical_viewport_size":camera.get_viewport().get_visible_rect().size,"canvas_pass":absf(actual.r-.125)<.01 and absf(actual.g-.875)<.01 and absf(actual.b-.375)<.01,
		"scope":"Natural frame_post_draw readback; exact full camera basis/projection and current pixel witnesses. No forced draw."}
