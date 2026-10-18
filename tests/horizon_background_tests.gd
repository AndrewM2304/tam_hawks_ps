extends RefCounted
## Independent live-World checks. Actual mesh faces and native collision decide
## coverage; candidate footing_report metadata is deliberately not evidence.
## The matched chase captures remain the visual/performance admission gate.
const Horizon = preload("res://game/levels/horizon_background.gd")
const Protected = preload("res://tests/clyde_surface_tests.gd")
const EPS := .00035
const BOTTOM := -35.0
const CELL := 8.0
const FOOTINGS := ["CityFootings", "ClydeFootings", "ParkWestFootings", "ParkNorthFootings"]


static func run(tree: SceneTree, world: Node3D, check: Callable) -> void:
	await tree.physics_frame
	await tree.process_frame
	var context := world.get_node_or_null("HorizonContext") as Node3D
	check.call(context != null, "horizon: normal production World installs its context")
	if context == null: return
	_sky(world, context, check)
	var geometry := _geometry(world, context, check)
	_coverage(world, geometry, check)
	_river(world, context, geometry, check)
	_preservation(world, context, check)
	_finish(world, context, check)


static func _sky(world: Node3D, context: Node3D, check: Callable) -> void:
	var environments := world.find_children("*", "WorldEnvironment", false, false)
	check.call(environments.size() == 1, "horizon: one native environment without an extra scene sky")
	if environments.size() != 1: return
	var environment: Environment = (environments[0] as WorldEnvironment).environment
	var panorama := environment.sky.sky_material as PanoramaSkyMaterial
	check.call(environment.background_mode == Environment.BG_SKY and panorama != null
		and environment.sky.process_mode == Sky.PROCESS_MODE_QUALITY,
		"horizon: native static quality panorama replaces the uniform procedural sky")
	if panorama == null or panorama.panorama == null: return
	var image: Image = panorama.panorama.get_image()
	var resident_bytes: int = image.get_data().size()
	var imported_ok := image.get_width() == 4096 and image.get_height() == 2048 \
		and image.has_mipmaps() and resident_bytes > 0 and resident_bytes <= 6*1024*1024
	check.call(imported_ok, "horizon: actual imported 4096x2048 mipmapped panorama data stays within6MiB")
	if image.is_compressed(): image.decompress()
	check.call(not image.is_compressed() and image.detect_alpha() == Image.ALPHA_NONE,
		"horizon: decoded actual panorama is opaque including its lower hemisphere")
	var raw: Image = Image.load_from_file(panorama.panorama.resource_path)
	var source_wrap: bool = raw != null and raw.get_width()==4096 and raw.get_height()==2048
	var native_pattern := true
	var block_wrap := true
	var max_seam := 0.0
	var max_block_seam := 0.0
	var max_pattern_delta := 0.0
	var max_repeat_excess := 0.0
	var varied := false
	var low := Color(1,1,1)
	var high := Color(0,0,0)
	for y: int in range(image.get_height()):
		var difference := _colour_distance(image.get_pixel(0,y),image.get_pixel(image.get_width()-1,y))
		max_seam = maxf(max_seam,difference)
		var first_mean := Color(0,0,0,0)
		var last_mean := Color(0,0,0,0)
		for x: int in range(4):
			var first := image.get_pixel(x,y)
			var last := image.get_pixel(image.get_width()-4+x,y)
			first_mean += first*.25
			last_mean += last*.25
			var pattern_delta := _colour_distance(first,last)
			max_pattern_delta = maxf(max_pattern_delta,pattern_delta)
			native_pattern = pattern_delta<.00001 and native_pattern
			if source_wrap:
				source_wrap = raw.get_pixel(x,y)==raw.get_pixel(raw.get_width()-4+x,y) and source_wrap
		var block_delta := _colour_distance(first_mean,last_mean)
		max_block_seam = maxf(max_block_seam,block_delta)
		block_wrap = block_delta<.04 and block_wrap
		# DXT1 dithers within a flat4px block. Wrapping column3->0 must be
		# no larger than that same ordinary periodic boundary in the matching
		# first block; otherwise raw texel noise is mistaken for a unique seam.
		var ordinary_repeat := _colour_distance(image.get_pixel(3,y),image.get_pixel(0,y))
		max_repeat_excess = maxf(max_repeat_excess,difference-ordinary_repeat)
	for y: int in [960,1000,1024,1100,1200]:
		for x: int in range(0,image.get_width(),32):
			var colour := image.get_pixel(x,y)
			low = Color(minf(low.r,colour.r),minf(low.g,colour.g),minf(low.b,colour.b))
			high = Color(maxf(high.r,colour.r),maxf(high.g,colour.g),maxf(high.b,colour.b))
	varied = _colour_distance(low,high) > .15
	print("HORIZON PIXELS raw_max_texel_seam=",max_seam," block_mean_seam=",max_block_seam," decoded_pattern_delta=",max_pattern_delta," ordinary_repeat_excess=",max_repeat_excess," source_blocks_match=",source_wrap," range=",_colour_distance(low,high)," low=",low," high=",high," imported_bytes=",resident_bytes)
	check.call(source_wrap and block_wrap and native_pattern and max_repeat_excess<.00001 and varied,
		"horizon: exact source edge blocks and native periodic block means/pattern wrap correctly with varied distant land/building silhouettes")
	check.call(environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR
		and environment.ambient_light_color.is_equal_approx(Color("c7dfeb"))
		and absf(environment.ambient_light_energy-.44)<.00001
		and environment.tonemap_mode == Environment.TONE_MAPPER_ACES
		and environment.fog_enabled and absf(environment.fog_density-.0015)<.000001
		and environment.fog_light_color.is_equal_approx(Color("b4bec3"))
		and absf(environment.fog_sky_affect-.15)<.00001,
		"horizon: established ambient light, ACES and fog remain unchanged rather than concealing gaps")
	var sun := world.get_node_or_null("LateAfternoonSun") as DirectionalLight3D
	check.call(sun != null and sun.light_color.is_equal_approx(Color("ffe8d1"))
		and absf(sun.light_energy-.80)<.00001,
		"horizon: existing sun colour and energy are retained")
	check.call(context.get_meta("original_sky_material",null) is ProceduralSkyMaterial,
		"horizon: controlled comparison retains the original procedural material")


static func _geometry(world: Node3D, context: Node3D, check: Callable) -> Dictionary:
	var all_faces := PackedVector3Array()
	var emitted_normals := PackedVector3Array()
	var bins: Dictionary = {}
	var surfaces := 0
	var material: StandardMaterial3D
	var shared := true
	var valid := true
	var actual_names: Array[String] = []
	for child: Node in context.get_children():
		if not child is MeshInstance3D: continue
		var display := child as MeshInstance3D
		if not FOOTINGS.has(str(display.name)): continue
		actual_names.append(str(display.name))
		valid = display.mesh is ArrayMesh and display.mesh.get_surface_count() == 1 \
			and display.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
			and display.gi_mode == GeometryInstance3D.GI_MODE_DISABLED and valid
		if material == null: material = display.material_override as StandardMaterial3D
		shared = material != null and display.material_override == material and shared
		for surface: int in range(display.mesh.get_surface_count()):
			surfaces += 1
			var arrays := display.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
			var indices := PackedInt32Array()
			if arrays[Mesh.ARRAY_INDEX] != null: indices = arrays[Mesh.ARRAY_INDEX]
			valid = normals.size() == vertices.size() and colours.size() == vertices.size() and valid
			for index: int in range(vertices.size()):
				valid = vertices[index].is_finite() and absf(normals[index].length()-1)<.001 \
					and absf(colours[index].a-1)<.00001 and valid
			var count: int = indices.size() if not indices.is_empty() else vertices.size()
			valid = count%3 == 0 and valid
			for index: int in range(count):
				var vertex_index: int = indices[index] if not indices.is_empty() else index
				var at: Vector3 = vertices[vertex_index]
				all_faces.append(world.to_local(display.to_global(at)))
				emitted_normals.append((world.global_basis.inverse()*display.global_basis*normals[vertex_index]).normalized())
	var faces := PackedVector3Array()
	var bank_faces := PackedVector3Array()
	var service_faces := PackedVector3Array()
	var expected_banks := _expected_banks()
	var expected_service := _expected_service()
	for index: int in range(0,all_faces.size(),3):
		var a := all_faces[index]
		var b := all_faces[index+1]
		var c := all_faces[index+2]
		var normal := (b-a).cross(c-a)
		valid = normal.length()>.00001 and valid
		for corner: int in range(3):
			valid = absf(emitted_normals[index+corner].dot(normal.normalized()))>.9999 and valid
		if _triangle_present(a,b,c,expected_service):
			service_faces.append_array(PackedVector3Array([a,b,c]))
			continue
		if _triangle_present(a,b,c,expected_banks):
			bank_faces.append_array(PackedVector3Array([a,b,c]))
			continue
		valid = absf(normal.normalized().y)<.00001 and valid
		var footing_index: int = faces.size()
		faces.append_array(PackedVector3Array([a,b,c]))
		var low := Vector2(minf(a.x,minf(b.x,c.x)),minf(a.z,minf(b.z,c.z)))
		var high := Vector2(maxf(a.x,maxf(b.x,c.x)),maxf(a.z,maxf(b.z,c.z)))
		for x: int in range(floori(low.x/CELL),floori(high.x/CELL)+1):
			for z: int in range(floori(low.y/CELL),floori(high.y/CELL)+1):
				var key := Vector2i(x,z)
				if not bins.has(key): bins[key] = []
				bins[key].append(footing_index)
	actual_names.sort()
	var expected_names: Array = FOOTINGS.duplicate()
	expected_names.sort()
	check.call(actual_names == expected_names and surfaces <= 4 and all_faces.size()/3 <= 768
		and faces.size() > 0 and valid,
		"horizon: four actual static regional meshes stay within budget with valid footing/bank triangles and opaque vertex colours")
	check.call(shared and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
		and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		and material.vertex_color_use_as_albedo and material.vertex_color_is_srgb
		and material.cull_mode == BaseMaterial3D.CULL_DISABLED and material.disable_receive_shadows
		and material.albedo_texture == null and not material.normal_enabled and material.next_pass == null,
		"horizon: footing surfaces share one opaque double-sided unshaded material without textures or extra passes")
	var passive := context.get_script() == null and not context.is_processing() and not context.is_physics_processing()
	for node: Node in context.find_children("*","",true,false):
		passive = not node is CollisionObject3D and not node is CollisionShape3D and not node is Light3D \
			and not node is Camera3D and node.get_script() == null and not node.is_processing() \
			and not node.is_physics_processing() and passive
	check.call(passive, "horizon: context introduces no collision, cameras, lights, scripts or frame callbacks")
	return {"faces":faces,"bins":bins,"bank_faces":bank_faces,"service_faces":service_faces,"regional_triangles":all_faces.size()/3}


static func _coverage(world: Node3D, geometry: Dictionary, check: Callable) -> void:
	var source_area := 0.0
	var source_segments: Array = []
	var samples := 0
	var covered := true
	var first_missing := ""
	for body: Node3D in world.find_children("*","StaticBody3D",true,false):
		if not bool(body.get_meta("exploration_boundary",false)): continue
		var points: PackedVector3Array = body.get_meta("boundary_points",PackedVector3Array())
		for index: int in range(points.size()-1):
			var a: Vector3 = world.to_local(body.to_global(points[index]))
			var b: Vector3 = world.to_local(body.to_global(points[index+1]))
			if a.distance_to(b)<.000001: continue
			source_segments.append([a,b])
			var run_length := Vector2(a.x-b.x,a.z-b.z).length()
			source_area += run_length*((a.y+b.y)*.5-BOTTOM)
			for t: float in [0.0,.5,1.0]:
				var top: Vector3 = a.lerp(b,t)
				for depth: float in [0.0,.2,.7,1.0]:
					var at := Vector3(top.x,lerpf(top.y,BOTTOM,depth),top.z)
					var present: bool = _covered(at,geometry)
					if not present and first_missing.is_empty(): first_missing = "%s at%s"%[body.name,at]
					covered = present and covered
					samples += 1
	if not covered: print("HORIZON MISSING ACTUAL FOOTING ",first_missing)
	check.call(covered and samples>1000,
		"horizon: actual triangles completely cover every raw physical boundary baseline, corners and downward footing samples")
	var area := 0.0
	var confined := true
	var faces: PackedVector3Array = geometry.faces
	for index: int in range(0,faces.size(),3):
		var a := faces[index]
		var b := faces[index+1]
		var c := faces[index+2]
		area += (b-a).cross(c-a).length()*.5
		for at: Vector3 in [a,b,c,(a+b+c)/3.0]:
			confined = _on_boundary_column(at,source_segments) and confined
	if absf(area-source_area)>.25 or not confined:
		print("HORIZON FACE AREA actual=",area," raw_expected=",source_area," confined=",confined)
	check.call(confined and absf(area-source_area)<.25,
		"horizon: actual face area matches the raw boundary envelope without floating extensions or route-mouth caps")
	var service: PackedVector3Array = geometry.service_faces
	var service_expected := _expected_service()
	var market_covered := service.size()==6
	for index: int in range(0,service_expected.size(),3):
		market_covered = _triangle_present(service_expected[index],service_expected[index+1],service_expected[index+2],service) and market_covered
	for z: float in [-8.0,-5.5,-3.0,-.5,2.0]:
		var baseline: float = world.get_ground_height(Vector3(129.8,0,z))
		for y: float in [-.1,baseline,baseline+4.8,5.05]:
			var at := Vector3(129.81,y,z)
			var present := false
			for index: int in range(0,service.size(),3):
				present = _on_triangle(at,service[index],service[index+1],service[index+2]) or present
			market_covered = present and market_covered
	check.call(market_covered,
		"horizon: separate flat service-back plane matches X129.81/Z-8..2/Y-.1..5.05 and embeds behind the blocked graded boundary")
	var ports := true
	for at: Vector3 in [Vector3(34.8,2,-80),Vector3(-34.8,2,-80),Vector3(88,1,-41.8),
		Vector3(-88,2,-41.8),Vector3(94,1,44.8),Vector3(-94,2,44.8),Vector3(-42.2,3,-122)]:
		ports = not _covered(at,geometry) and ports
	check.call(ports, "horizon: real civic, station, market, park and quay openings contain no footing cap")
	print("HORIZON independent geometry samples=",samples," triangles=",faces.size()/3," area=",area)


static func _river(world: Node3D, context: Node3D, geometry: Dictionary, check: Callable) -> void:
	var banks: PackedVector3Array = geometry.bank_faces
	var expected := _expected_banks()
	var complete := banks.size()==expected.size() and banks.size()==72*3
	for index: int in range(0,expected.size(),3):
		complete = _triangle_present(expected[index],expected[index+1],expected[index+2],banks) and complete
	check.call(complete, "horizon river: actual72 bank triangles match independently fixed shore/back sections behind closed quay ends")
	var water := world.get_node_or_null("OutdoorRoutes/ClydeWater") as MeshInstance3D
	check.call(water != null and water.mesh is ArrayMesh and water.mesh.get_surface_count()==1
		and water.material_override is ShaderMaterial,
		"horizon river: one existing water display retains its ShaderMaterial and one replacement mesh surface")
	if water==null or not water.mesh is ArrayMesh: return
	var material: Material = water.material_override
	var water_faces := PackedVector3Array()
	var valid := true
	var arrays := water.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] != null: indices = arrays[Mesh.ARRAY_INDEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	valid = vertices.size()==normals.size() and vertices.size()==uvs.size() and tangents.size()==vertices.size()*4
	var max_y := 0.0
	var max_uv := 0.0
	var min_normal_dot := 1.0
	var max_normal_error := 0.0
	for index: int in range(vertices.size()):
		var at: Vector3 = world.to_local(water.to_global(vertices[index]))
		max_y = maxf(max_y,absf(at.y+2))
		max_uv = maxf(max_uv,uvs[index].distance_to(Vector2(at.x,at.z)*.1))
		min_normal_dot = minf(min_normal_dot,normals[index].dot(Vector3.UP))
		max_normal_error = maxf(max_normal_error,normals[index].distance_to(Vector3.UP))
		# Native ArrayMesh octahedral normal storage decodes an up vector with
		# measured1.5259e-5 error; component-wise is_equal_approx rejects zero
		# components at that precision. Keep a bounded .00005 vector tolerance.
		valid = absf(at.y+2)<EPS and normals[index].distance_to(Vector3.UP)<.00005 \
			and uvs[index].distance_to(Vector2(at.x,at.z)*.1)<.0001 and valid
	var count: int = indices.size() if not indices.is_empty() else vertices.size()
	for index: int in range(count):
		water_faces.append(world.to_local(water.to_global(vertices[indices[index] if not indices.is_empty() else index])))
	var water_expected := _expected_water()
	valid = water_faces.size()==18*3 and water_faces.size()==water_expected.size() and valid
	var missing := ""
	for index: int in range(0,water_expected.size(),3):
		var present := _triangle_present(water_expected[index],water_expected[index+1],water_expected[index+2],water_faces)
		if not present and missing.is_empty(): missing = str(PackedVector3Array([water_expected[index],water_expected[index+1],water_expected[index+2]]))
		valid = present and valid
	var min_front_area := INF
	var max_front_area := -INF
	for index: int in range(0,water_faces.size(),3):
		var front_area := (water_faces[index+1]-water_faces[index]).cross(water_faces[index+2]-water_faces[index]).y
		min_front_area = minf(min_front_area,front_area)
		max_front_area = maxf(max_front_area,front_area)
		valid = front_area<-.0001 and valid
	print("HORIZON WATER vertices=",vertices.size()," indices=",indices.size()," normals=",normals.size()," uvs=",uvs.size()," tangents=",tangents.size()," max_y=",max_y," max_uv=",max_uv," min_normal_dot=",min_normal_dot," max_normal_error=",max_normal_error," front_area=",Vector2(min_front_area,max_front_area)," missing=",missing," combined_triangles=",int(geometry.regional_triangles)+water_faces.size()/3)
	check.call(valid and int(geometry.regional_triangles)+water_faces.size()/3<=768,
		"horizon river: exactY-2 central channel and both bent38m water strips have upward front faces, world UV/tangents and total768-triangle ceiling")
	var water_top := Protected._horizontal_triangles(water_faces,-2)
	var bank_top := Protected._horizontal_triangles(banks,2)
	var water_overlap := 0.0
	for left: int in range(water_top.size()):
		for right: int in range(left+1,water_top.size()):
			var a: Array[PackedVector2Array] = [water_top[left]]
			var b: Array[PackedVector2Array] = [water_top[right]]
			water_overlap += Protected._overlap_area(a,b)
	check.call(water_overlap<.001 and Protected._overlap_area(water_top,bank_top)<.001,
		"horizon river: actual water triangles never overlap each other or project through the new bank tops")
	var no_support := true
	var support_samples := 0
	var space := world.get_world_3d().direct_space_state
	for index: int in range(0,banks.size(),3):
		var a := banks[index]
		var b := banks[index+1]
		var c := banks[index+2]
		if absf(a.y-2)>.001 or absf(b.y-2)>.001 or absf(c.y-2)>.001: continue
		var at: Vector3 = (a+b+c)/3
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.1,at-Vector3.UP*5,1))
		if not hit.is_empty(): print("HORIZON SCENIC BANK SUPPORT ",at," hit=",hit.position," body=",hit.collider.name)
		no_support = hit.is_empty() and no_support
		support_samples += 1
	check.call(no_support and support_samples==36,
		"horizon river: all36 scenic bank-top triangle interiors stay outside actual playable collision support")
	var candidate: Mesh = water.mesh
	Horizon.set_enabled(world,false)
	var original := water.mesh is PlaneMesh and water.material_override==material
	Horizon.set_enabled(world,true)
	check.call(original and water.mesh==candidate and water.material_override==material,
		"horizon river: controlled comparison swaps only the existing water mesh and retains exactly the same animated material")


static func _expected_banks() -> PackedVector3Array:
	# Fixed cross-sections from the agreed river contract, independent of the
	# candidate report, simplifier or generator. The short south returns begin
	# at the actual compact pocket limits rather than the old wide landscape.
	var sections: Array = [
		[PackedVector2Array([Vector2(85,78),Vector2(115,78),Vector2(145,86),Vector2(174,118),Vector2(230,220)]),
		PackedVector2Array([Vector2(85,76),Vector2(115,70),Vector2(145,62),Vector2(174,94),Vector2(230,196)])],
		[PackedVector2Array([Vector2(-85,78),Vector2(-118,78),Vector2(-150,89),Vector2(-180,120),Vector2(-236,220)]),
		PackedVector2Array([Vector2(-85,76),Vector2(-118,70),Vector2(-150,65),Vector2(-180,96),Vector2(-236,196)])],
		[PackedVector2Array([Vector2(76,116),Vector2(85,116),Vector2(115,116),Vector2(145,124),Vector2(174,156),Vector2(230,258)]),
		PackedVector2Array([Vector2(76,140),Vector2(85,140),Vector2(115,140),Vector2(145,148),Vector2(174,180),Vector2(230,282)])],
		[PackedVector2Array([Vector2(-39,116),Vector2(-85,116),Vector2(-118,116),Vector2(-150,127),Vector2(-180,158),Vector2(-236,258)]),
		PackedVector2Array([Vector2(-39,140),Vector2(-85,140),Vector2(-118,140),Vector2(-150,151),Vector2(-180,182),Vector2(-236,282)])]
	]
	var faces := PackedVector3Array()
	for section: Array in sections:
		var edge: PackedVector2Array = section[0]
		var back: PackedVector2Array = section[1]
		for index: int in range(edge.size()-1):
			var a := Vector3(edge[index].x,2,edge[index].y)
			var b := Vector3(edge[index+1].x,2,edge[index+1].y)
			var c := Vector3(back[index+1].x,2,back[index+1].y)
			var d := Vector3(back[index].x,2,back[index].y)
			faces.append_array(PackedVector3Array([a,b,c,a,c,d,a,b,Vector3(b.x,-35,b.z),a,Vector3(b.x,-35,b.z),Vector3(a.x,-35,a.z)]))
	return faces


static func _expected_water() -> PackedVector3Array:
	var north: Array = [PackedVector2Array([Vector2(-85,78),Vector2(85,78)]),
		PackedVector2Array([Vector2(85,78),Vector2(115,78),Vector2(145,86),Vector2(174,118),Vector2(230,220)]),
		PackedVector2Array([Vector2(-85,78),Vector2(-118,78),Vector2(-150,89),Vector2(-180,120),Vector2(-236,220)])]
	var faces := PackedVector3Array()
	for points: PackedVector2Array in north:
		for index: int in range(points.size()-1):
			var a := Vector3(points[index].x,-2,points[index].y)
			var b := Vector3(points[index+1].x,-2,points[index+1].y)
			var c := b+Vector3(0,0,38)
			var d := a+Vector3(0,0,38)
			faces.append_array(PackedVector3Array([a,b,c,a,c,d]))
	return faces


static func _expected_service() -> PackedVector3Array:
	# A separately agreed construction plane inside the physical guard's .20m
	# width, grounded below both true floor heights with a level masonry top.
	var a := Vector3(129.81,5.05,-8)
	var b := Vector3(129.81,5.05,2)
	var c := Vector3(129.81,-.1,2)
	var d := Vector3(129.81,-.1,-8)
	return PackedVector3Array([a,b,c,a,c,d])


static func _triangle_present(a: Vector3, b: Vector3, c: Vector3, faces: PackedVector3Array) -> bool:
	for index: int in range(0,faces.size(),3):
		var points: Array[Vector3] = [faces[index],faces[index+1],faces[index+2]]
		var matched := true
		for point: Vector3 in [a,b,c]:
			var found := false
			for other: Vector3 in points:
				if point.distance_to(other)<EPS: found = true
			matched = found and matched
		if matched: return true
	return false


static func _preservation(world: Node3D, context: Node3D, check: Callable) -> void:
	var bodies := world.find_children("*","StaticBody3D",true,false)
	var shapes := world.find_children("*","CollisionShape3D",true,false)
	check.call(bodies.size()==354 and shapes.size()==1296 and Protected.original_physics_inventory(world),
		"horizon: exact354 bodies/1296 shapes and independent protected core/bench identities are retained")
	var routes: Array = world.get_route_definitions()
	var identities: Dictionary = {}
	for route: Dictionary in routes: identities[route.id] = true
	var checkpoints: Dictionary = world.get_district_checkpoints()
	var checkpoint_ids: Array = checkpoints.keys()
	checkpoint_ids.sort()
	check.call(routes.size()==48 and identities.size()==48
		and checkpoint_ids==["barras","central_station","clyde","george_square","kelvingrove","royal_exchange"],
		"horizon: all48 unique published routes and the six district checkpoints remain")
	var space := world.get_world_3d().direct_space_state
	var supports := true
	for at: Vector3 in [Vector3(-2,1,-8),Vector3(-6,4,-102),Vector3(-99,2,-5),
		Vector3(50,0,-16),Vector3(49,2,135),Vector3(-227,8.852535,-85)]:
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.25,at-Vector3.UP*.4,1))
		supports = not hit.is_empty() and absf(hit.position.y-at.y)<.025 \
			and absf(world.get_ground_height(at)-at.y)<.025 and supports
	check.call(supports, "horizon: representative real support/query contacts remain correct across all six areas")
	var empty := true
	for at: Vector3 in [Vector3(-135,0,68),Vector3(135,0,68),Vector3(-100,0,124),
		Vector3(120,0,124),Vector3(-250,0,195),Vector3(0,0,195),Vector3(250,0,195)]:
		empty = space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*20,at-Vector3.UP*40,1)).is_empty() and empty
	check.call(empty, "horizon: scenic backing creates no catch floor in deleted quays or former south landscape")
	var environment: Environment = (world.find_children("*","WorldEnvironment",false,false)[0] as WorldEnvironment).environment
	var candidate: Material = environment.sky.sky_material
	Horizon.set_enabled(world,false)
	var original_restored: bool = not context.visible and environment.sky.sky_material == context.get_meta("original_sky_material")
	Horizon.set_enabled(world,true)
	check.call(original_restored and context.visible and environment.sky.sky_material==candidate
		and world.find_children("*","StaticBody3D",true,false).size()==354
		and world.find_children("*","CollisionShape3D",true,false).size()==1296
		and world.get_route_definitions()==routes,
		"horizon: reversible appearance comparison restores both materials while physical routes stay identical")


static func _finish(world: Node3D, context: Node3D, check: Callable) -> void:
	var finishes := 0
	var valid := true
	for body: Node3D in world.find_children("*","StaticBody3D",true,false):
		if str(body.get_meta("boundary_family",""))!="QuayLandwardBoundary" or float(body.get_meta("boundary_height",0))<9: continue
		var display := body.get_node_or_null("PropertyMasonry") as MultiMeshInstance3D
		if display==null:
			valid = false
			continue
		var material := display.material_override as StandardMaterial3D
		valid = material!=null and display.multimesh.instance_count==1 and valid
		if material==null: continue
		valid = material.albedo_texture!=null and material.albedo_texture.resource_path=="res://game/art/assets/zc_textures/T_bricks01/T_bricks01_albedo.jpg" \
			and not material.normal_enabled and material.next_pass==null \
			and material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and material.uv1_scale.is_finite() and valid
		finishes += 1
	check.call(valid and finishes==1 and context.get_meta("wall_finishes",[]).size()==1,
		"horizon: existing high Clyde wall reuses one resident CC0 albedo without another mesh, normal map or pass")


static func _covered(at: Vector3, geometry: Dictionary) -> bool:
	var key := Vector2i(floori(at.x/CELL),floori(at.z/CELL))
	var faces: PackedVector3Array = geometry.faces
	for index: int in geometry.bins.get(key,[]):
		if _on_triangle(at,faces[index],faces[index+1],faces[index+2]): return true
	return false


static func _on_triangle(at: Vector3, a: Vector3, b: Vector3, c: Vector3) -> bool:
	var normal := (b-a).cross(c-a).normalized()
	var distance := normal.dot(at-a)
	if absf(distance)>EPS: return false
	var p := at-normal*distance
	var v0 := b-a
	var v1 := c-a
	var v2 := p-a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denominator := d00*d11-d01*d01
	if absf(denominator)<.000000001: return false
	var v := (d11*d20-d01*d21)/denominator
	var w := (d00*d21-d01*d20)/denominator
	if v>=0 and w>=0 and v+w<=1: return true
	return _segment_distance(p,a,b)<EPS or _segment_distance(p,b,c)<EPS or _segment_distance(p,c,a)<EPS


static func _segment_distance(at: Vector3, a: Vector3, b: Vector3) -> float:
	var delta := b-a
	var t := clampf((at-a).dot(delta)/delta.length_squared(),0,1)
	return at.distance_to(a+delta*t)


static func _on_boundary_column(at: Vector3, source_segments: Array) -> bool:
	if at.y<BOTTOM-EPS: return false
	for pair: Array in source_segments:
		var a: Vector3 = pair[0]
		var b: Vector3 = pair[1]
		var delta := Vector2(b.x-a.x,b.z-a.z)
		if delta.length_squared()<.000000001: continue
		var t := clampf(Vector2(at.x-a.x,at.z-a.z).dot(delta)/delta.length_squared(),0,1)
		var top: Vector3 = a.lerp(b,t)
		if Vector2(at.x-top.x,at.z-top.z).length()<EPS and at.y<=top.y+EPS: return true
	return false


static func _colour_distance(a: Color, b: Color) -> float:
	return Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length()
