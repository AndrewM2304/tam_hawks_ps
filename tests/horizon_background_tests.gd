extends RefCounted
## Independent live-World checks. Actual mesh faces and native collision decide
## coverage; candidate footing_report metadata is deliberately not evidence.
## The matched chase captures remain the visual/performance admission gate.
const Horizon = preload("res://game/levels/horizon_background.gd")
const Protected = preload("res://tests/clyde_surface_tests.gd")
const EPS := .00035
const BOTTOM := -35.0
# Explicit approved facility/infill deltas; old physical identities are checked separately.
const WORLD_BODIES := 354 + 204 + 1 - 2 # Hubba coping; owner removed two raised Clyde bowl access bodies.
const WORLD_SHAPES := 1296 + 358 + 1 - 2 + 1 # East civic rear guard gains one graded panel.
const WORLD_ROUTES := 48 + 8
const CELL := 8.0
const CUBE_SIZE := 512
const CUBE_MIPS := 9
const CUBE_FORMAT := Image.FORMAT_RGB8
const CUBE_FACE_BYTES := 1048575
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
	_frontages(world, context, geometry, check)


static func _sky(world: Node3D, context: Node3D, check: Callable) -> void:
	var environments := world.find_children("*", "WorldEnvironment", false, false)
	check.call(environments.size() == 1, "horizon: one native environment without an extra scene sky")
	if environments.size() != 1: return
	var environment: Environment = (environments[0] as WorldEnvironment).environment
	var material := environment.sky.sky_material as ShaderMaterial
	check.call(environment.background_mode == Environment.BG_SKY and material != null
		and environment.sky.process_mode == Sky.PROCESS_MODE_QUALITY,
		"horizon: native static quality cubemap replaces the uniform procedural sky")
	if material == null: return
	var cube := material.get_shader_parameter("context_sky") as TextureLayered
	check.call(cube != null and cube.get_layered_type()==TextureLayered.LAYERED_TYPE_CUBEMAP
		and cube.get_layers()==6 and cube.get_width()==CUBE_SIZE and cube.get_height()==CUBE_SIZE
		and cube.get_format()==CUBE_FORMAT and cube.has_mipmaps(),
		"horizon cube: actual bound native resource has six512-square RGB8 mipmapped faces")
	var code: String = material.shader.code.replace(" ","").replace("\n","").replace("\t","")
	check.call(code.contains("uniformsamplerCubecontext_sky:source_color,filter_linear;")
		and code.contains("COLOR=textureLod(context_sky,EYEDIR,0.0).rgb;") and code.count("textureLod(")==1
		and not code.contains("texture(")
		and not code.contains("use_half_res_pass") and not code.contains("HALF_RES_COLOR")
		and not code.contains("TIME") and not code.contains("POSITION"),
		"horizon cube: bound static sky performs one explicit base-level colour-correct linear lookup without derivatives or a half-resolution pass")
	if cube != null: _cube_pixels(cube,check)
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
	var emitted_chunks: Array[String] = []
	var bins: Dictionary = {}
	var surfaces := 0
	var material: ShaderMaterial
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
		if material == null: material = display.material_override as ShaderMaterial
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
				emitted_chunks.append(str(display.name))
	var faces := PackedVector3Array()
	var bank_faces := PackedVector3Array()
	var service_faces := PackedVector3Array()
	var foundation_faces := PackedVector3Array()
	var land_faces := PackedVector3Array()
	var expected_land := _expected_land()
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
		if _triangle_present(a,b,c,expected_land):
			land_faces.append_array(PackedVector3Array([a,b,c]))
			valid=emitted_chunks[index]=="CityFootings" and normal.y<0 and valid
			continue
		valid = absf(normal.normalized().y)<.00001 and valid
		if _foundation_face_index(a,b,c)>=0:
			foundation_faces.append_array(PackedVector3Array([a,b,c]))
			valid = emitted_chunks[index]=="CityFootings" and valid
			continue
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
	check.call(actual_names == expected_names and surfaces <= 4 and (all_faces.size()-land_faces.size())/3 <= 832 + 8
		and land_faces.size()==18
		and faces.size() > 0 and valid,
		"horizon: four actual static regional meshes stay within832 original combined budget plus8 native park contour triangles and exactly six enclosed-land triangles with valid footing/bank/foundation triangles and opaque vertex colours")
	var shader_valid := false
	if shared and material != null and material.shader != null:
		var code: String = ""
		for line: String in material.shader.code.split("\n"):
			code += line.get_slice("//",0).replace(" ","").replace("\t","").strip_edges()
		shader_valid = material.next_pass==null and code.contains("shader_typespatial;") \
			and code.contains("render_modeunshaded,cull_disabled,shadows_disabled,specular_disabled;") \
			and code.contains("if(!OUTPUT_IS_SRGB){vec3colour=COLOR.rgb;COLOR.rgb=mix(pow((colour+vec3(0.055))/1.055,vec3(2.4)),colour/12.92,lessThan(colour,vec3(0.04045)));}") \
			and code.contains("voidfragment(){ALBEDO=COLOR.rgb;}") \
			and not code.contains("sampler") and not code.contains("texture") \
			and not code.contains("ALPHA") and not code.contains("fog_disabled") \
			and not code.contains("FOG") and not code.contains("depth_test_disabled") \
			and not code.contains("UV") and not code.contains("TIME")
	check.call(shader_valid,
		"horizon: four footing surfaces share one opaque double-sided texture-free shader with standard sRGB vertex conversion, native fog and no extra pass")
	var passive := context.get_script() == null and not context.is_processing() and not context.is_physics_processing()
	for node: Node in context.find_children("*","",true,false):
		passive = not node is CollisionObject3D and not node is CollisionShape3D and not node is Light3D \
			and not node is Camera3D and node.get_script() == null and not node.is_processing() \
			and not node.is_physics_processing() and passive
	check.call(passive, "horizon: context introduces no collision, cameras, lights, scripts or frame callbacks")
	return {"faces":faces,"bins":bins,"bank_faces":bank_faces,"service_faces":service_faces,
		"foundation_faces":foundation_faces,"land_faces":land_faces,"regional_triangles":all_faces.size()/3}


static func _cube_pixels(cube: TextureLayered, check: Callable) -> void:
	var reference := Image.new()
	var atlas := Image.new()
	var loaded: bool = reference.load_png_from_buffer(FileAccess.get_file_as_bytes("res://game/art/assets/horizon/glasgow_horizon.png"))==OK \
		and atlas.load_png_from_buffer(FileAccess.get_file_as_bytes(cube.resource_path))==OK
	check.call(loaded and reference.get_size()==Vector2i(4096,2048) and atlas.get_size()==Vector2i(CUBE_SIZE*3,CUBE_SIZE*2)
		and atlas.detect_alpha()==Image.ALPHA_NONE,
		"horizon cube: opaque source atlas and retained offline panorama have the agreed dimensions")
	if not loaded: return
	var blocks: Dictionary = {}
	for face: int in range(6):
		_add_cube_block(blocks,face,0,0)
		for edge: int in range(4):
			for t: float in [-.875,-.5,0.0,.5,.875]:
				var uv: Vector2 = [Vector2(-1,t),Vector2(1,t),Vector2(t,-1),Vector2(t,1)][edge]
				_add_cube_block(blocks,face,uv.x,uv.y)
		for s: float in [-1.0,1.0]:
			for t: float in [-1.0,1.0]: _add_cube_block(blocks,face,s,t)
	# Distinct bearings/latitudes catch swapped or mirrored faces. All24 face
	# edges above inspect both sides of every one of the12 physical joins.
	for degrees: int in range(0,360,15):
		for latitude: float in [-15.0,0.0,15.0]:
			var yaw := deg_to_rad(degrees)
			var pitch := deg_to_rad(latitude)
			var direction := Vector3(sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
			var mapped := _cube_coordinates(direction)
			_add_cube_block(blocks,int(mapped.x),mapped.y,mapped.z)
	for face: int in [2,3]:
		for angle: int in range(0,360,45):
			_add_cube_block(blocks,face,.05*cos(deg_to_rad(angle)),.05*sin(deg_to_rad(angle)))
	var source_ok := true
	var source_worst := 0.0
	var source_where := Vector3i.ZERO
	for key: Vector3i in blocks:
		var actual := _atlas_mean(atlas,key.x,key.y,key.z,4)
		var expected := Color(0,0,0,0)
		for y: int in range(key.z,key.z+4):
			for x: int in range(key.y,key.y+4): expected += _panorama_colour(reference,_cube_direction(key.x,x,y)) / 16.0
		var error := _colour_distance(actual,expected)
		if error>source_worst: source_worst=error;source_where=key
		# sqrt(3)*.5/255 rounding is .003397; .005 also covers float32 bake
		# coordinate arithmetic. This limit was fixed before native results.
		source_ok = error<.005 and source_ok
	print("HORIZON CUBE SOURCE blocks=",blocks.size()," worst=",source_worst," where=",source_where)
	check.call(source_ok, "horizon cube: independent world-direction oracle matches axes, all12 joins, eight corners and both polar caps")
	# Renderer readback is not an imported-payload measurement. Parse only the
	# inspected Godot4.6.3 raw RGB8 layered format, with strict headers/EOF.
	var imported := _imported_cube(cube)
	check.call(not imported.is_empty() and int(imported.get("bytes",0))<=6*1024*1024,
		"horizon cube: actual validated six-face RGB8 import chains including mipmaps stay within6MiB")
	if imported.is_empty(): return
	var faces: Array[Image] = imported.faces
	var levels: Dictionary = {}
	var opaque := true
	for face: int in range(6):
		for mip: int in [0,1,2]:
			var chain: Image = faces[face]
			var dimension: int = CUBE_SIZE>>mip
			var offset: int = chain.get_mipmap_offset(mip)
			var length: int = dimension*dimension*3
			var image := Image.create_from_data(dimension,dimension,false,CUBE_FORMAT,chain.get_data().slice(offset,offset+length))
			opaque = not image.is_compressed() and image.detect_alpha()==Image.ALPHA_NONE and opaque
			levels[Vector2i(face,mip)]=image
	check.call(opaque, "horizon cube: actual imported base and two lower mip levels decode as opaque images")
	var pixel_ok := true
	var worst := 0.0
	var where := ""
	for mip: int in [0,1,2]:
		var scale: int = 1<<mip
		for key: Vector3i in blocks:
			var native_image: Image = levels[Vector2i(key.x,mip)]
			var x: int = clampi((key.y/scale)/4,0,native_image.get_width()/4-1)*4
			var y: int = clampi((key.z/scale)/4,0,native_image.get_height()/4-1)*4
			var actual := Color(0,0,0,0)
			for dy: int in range(4):
				for dx: int in range(4): actual += native_image.get_pixel(x+dx,y+dy)/16.0
			var expected := _atlas_mean(atlas,key.x,x*scale,y*scale,4*scale)
			var error := _colour_distance(actual,expected)
			if error>worst: worst=error;where="face%s mip%s x%s y%s"%[key.x,mip,x,y]
			pixel_ok = error<.04 and pixel_ok
	print("HORIZON CUBE IMPORT imported_bytes=",imported.bytes," sampled_mips=3 block_checks=",blocks.size()*3," worst_mean_error=",worst," where=",where)
	check.call(pixel_ok, "horizon cube: actual imported face means preserve directions, all joins, corners and poles through three mip levels")
	if DisplayServer.get_name()=="headless":
		print("HORIZON_NATIVE_PIXELS_DEFERRED: actual RGB8 import chains were checked; Dummy cannot verify GPU upload/readback. No GPU assertion is counted; native focused replay is required.")
		return
	# A warmed native probe on this Compatibility backend returned black RGBA
	# at every face centre/corner despite its visibly rendered correct sky.
	# Preserve that API limitation instead of counting a fabricated GPU pass.
	print("HORIZON_GPU_READBACK_UNVERIFIED: retained1024/DXT1 readback-probe-01 returned blackRGBA after4 native draws while the sky rendered correctly; it does not verify this512/RGB8 upload. No GPU-layer pixel assertion is counted; source-bound37-view native composition and strict timing remain required. Backend=",RenderingServer.get_current_rendering_method())


static func _imported_cube(cube: TextureLayered) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(cube.resource_path+".import")!=OK or not config.has_section_key("remap","path"): return {}
	var path: String = str(config.get_value("remap","path"))
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_buffer(4).get_string_from_ascii()!="GSTL": return {}
	# Version1 / six layers / cubemap1 / raw-image data and five zero fields.
	for expected: int in [1,6,1,0,0,0,0,0]:
		if file.get_32()!=expected: return {}
	var faces: Array[Image] = []
	var total := 0
	for face: int in range(6):
		if file.get_32()!=0 or file.get_16()!=CUBE_SIZE or file.get_16()!=CUBE_SIZE \
			or file.get_32()!=CUBE_MIPS or file.get_32()!=CUBE_FORMAT: return {}
		var bytes: PackedByteArray = file.get_buffer(CUBE_FACE_BYTES)
		if bytes.size()!=CUBE_FACE_BYTES: return {}
		var image := Image.create_from_data(CUBE_SIZE,CUBE_SIZE,true,CUBE_FORMAT,bytes)
		if image==null or image.get_mipmap_count()!=CUBE_MIPS: return {}
		faces.append(image)
		total+=bytes.size()
	if file.get_position()!=file.get_length(): return {}
	print("HORIZON CUBE IMPORT FILE path=",path," bytes=",file.get_length()," payload=",total," sha256=",FileAccess.get_sha256(path))
	return {"faces":faces,"bytes":total}


static func _add_cube_block(blocks: Dictionary, face: int, s: float, t: float) -> void:
	blocks[Vector3i(face,clampi(floori((s+1)*CUBE_SIZE*.5)/4,0,CUBE_SIZE/4-1)*4,clampi(floori((t+1)*CUBE_SIZE*.5)/4,0,CUBE_SIZE/4-1)*4)] = true


static func _cube_direction(face: int, x: int, y: int) -> Vector3:
	var s := 2.0*(x+.5)/CUBE_SIZE-1.0
	var t := 2.0*(y+.5)/CUBE_SIZE-1.0
	var direction: Vector3 = [Vector3(1,-t,-s),Vector3(-1,-t,s),Vector3(s,1,t),
		Vector3(s,-1,-t),Vector3(s,-t,1),Vector3(-s,-t,-1)][face]
	return direction.normalized()


static func _cube_coordinates(d: Vector3) -> Vector3:
	var a := d.abs()
	if a.x>=a.y and a.x>=a.z:
		return Vector3(0,-d.z/a.x,-d.y/a.x) if d.x>=0 else Vector3(1,d.z/a.x,-d.y/a.x)
	if a.y>=a.z:
		return Vector3(2,d.x/a.y,d.z/a.y) if d.y>=0 else Vector3(3,d.x/a.y,-d.z/a.y)
	return Vector3(4,d.x/a.z,-d.y/a.z) if d.z>=0 else Vector3(5,-d.x/a.z,-d.y/a.z)


static func _panorama_colour(image: Image, direction: Vector3) -> Color:
	var u := fposmod(atan2(direction.x,-direction.z)/TAU,1.0)
	var v := acos(clampf(direction.y,-1,1))/PI
	var x := u*image.get_width()-.5
	var y := clampf(v*image.get_height()-.5,0,image.get_height()-1)
	var ix := floori(x)
	var iy := floori(y)
	var a := image.get_pixel(posmod(ix,image.get_width()),iy).lerp(image.get_pixel(posmod(ix+1,image.get_width()),iy),x-ix)
	var b := image.get_pixel(posmod(ix,image.get_width()),mini(iy+1,image.get_height()-1)).lerp(image.get_pixel(posmod(ix+1,image.get_width()),mini(iy+1,image.get_height()-1)),x-ix)
	return a.lerp(b,y-iy)


static func _atlas_mean(atlas: Image, face: int, x: int, y: int, span: int) -> Color:
	var result := Color(0,0,0,0)
	for dy: int in range(span):
		for dx: int in range(span): result += atlas.get_pixel((face%3)*CUBE_SIZE+x+dx,(face/3)*CUBE_SIZE+y+dy)/float(span*span)
	return result


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
		var foundations: PackedVector3Array = geometry.foundation_faces
		for index: int in range(0,foundations.size(),3):
			ports = not _on_triangle(at,foundations[index],foundations[index+1],foundations[index+2]) and ports
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
	check.call(valid and int(geometry.regional_triangles)-geometry.land_faces.size()/3+water_faces.size()/3<=832+8,
		"horizon river: exactY-2 central channel and both bent38m water strips have upward front faces, world UV/tangents and original832-triangle ceiling plus exactly8 native park contour triangles, excluding the separately verified six land triangles")
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
	check.call(bodies.size()==WORLD_BODIES and shapes.size()==WORLD_SHAPES and Protected.original_physics_inventory(world),
		"horizon: exact557 bodies/1654 shapes after Clyde removal and civic guard extension; protected identities retained")
	var routes: Array = world.get_route_definitions()
	var identities: Dictionary = {}
	for route: Dictionary in routes: identities[route.id] = true
	var checkpoints: Dictionary = world.get_district_checkpoints()
	var checkpoint_ids: Array = checkpoints.keys()
	checkpoint_ids.sort()
	check.call(routes.size()==WORLD_ROUTES and identities.size()==WORLD_ROUTES
		and checkpoint_ids==["barras","central_station","clyde","george_square","kelvingrove","royal_exchange"],
		"horizon: all48 original plus8 unique published feature routes and the six district checkpoints remain")
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
		and world.find_children("*","StaticBody3D",true,false).size()==WORLD_BODIES
		and world.find_children("*","CollisionShape3D",true,false).size()==WORLD_SHAPES
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


static func _frontages(world: Node3D, context: Node3D, geometry: Dictionary, check: Callable) -> void:
	var expected: Array[AABB] = _frontage_specs()
	var displays: Array[MeshInstance3D] = []
	var states: Array[Dictionary] = []
	var identities: Dictionary = {}
	var defaults := MeshInstance3D.new()
	var palette: Dictionary = world.get_node("CityArt").get("materials")
	var valid := true
	for display: MeshInstance3D in world.find_children("*","MeshInstance3D",true,false):
		if not bool(display.get_meta("horizon_frontage",false)): continue
		if not display.mesh is BoxMesh:
			valid = false
			continue
		displays.append(display)
		states.append(_frontage_state(display))
		var bounds := _frontage_bounds(world,display)
		var found := -1
		for index: int in range(expected.size()):
			if bounds.position.distance_to(expected[index].position)<EPS \
				and bounds.end.distance_to(expected[index].end)<EPS: found=index
		valid = found>=0 and not identities.has(found) and display.mesh.get_faces().size()==36 \
			and display.cast_shadow==defaults.cast_shadow and display.gi_mode==defaults.gi_mode \
			and display.layers==defaults.layers and display.custom_aabb==defaults.custom_aabb \
			and display.extra_cull_margin==defaults.extra_cull_margin \
			and display.visibility_range_begin==0 and display.visibility_range_end==0 \
			and display.ignore_occlusion_culling==defaults.ignore_occlusion_culling and valid
		if found>=0:
			var rotated: bool = found in [4,5,6]
			var frame: Transform3D = world.global_transform.affine_inverse()*display.global_transform
			var original_basis := Basis(Vector3.UP,-PI*.5) if rotated else Basis.IDENTITY
			var original_size: Vector3 = Vector3(expected[found].size.z,expected[found].size.y,expected[found].size.x) if rotated else expected[found].size
			var original_position: Vector3 = Vector3.ZERO if found==7 else Vector3.UP*original_size.y*.5
			valid = frame.origin.distance_to(expected[found].get_center())<EPS \
				and frame.basis.is_equal_approx(original_basis) and display.basis.is_equal_approx(Basis.IDENTITY) \
				and display.position.distance_to(original_position)<EPS \
				and (display.mesh as BoxMesh).size.distance_to(original_size)<EPS and valid
			var material_key: String = "stone_light" if found==7 else ("warehouse_brick" if found in [2,3,4,5] else "sandstone")
			var material := display.material_override as StandardMaterial3D
			valid = material!=null and display.material_override==palette[material_key] and valid
			if material!=null:
				valid = material.shading_mode==BaseMaterial3D.SHADING_MODE_PER_PIXEL \
					and material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED \
					and material.uv1_triplanar and material.uv1_world_triplanar \
					and material.normal_enabled==(material_key=="warehouse_brick") \
					and not material.disable_receive_shadows and material.next_pass==null and valid
		identities[found]=true
	defaults.free()
	var foundations: PackedVector3Array = geometry.foundation_faces
	var groups: Dictionary = {}
	for index: int in range(0,foundations.size(),3):
		var face: int = _foundation_face_index(foundations[index],foundations[index+1],foundations[index+2])
		if not groups.has(face): groups[face]=PackedVector3Array()
		var triangles: PackedVector3Array = groups[face]
		triangles.append_array(PackedVector3Array([foundations[index],foundations[index+1],foundations[index+2]]))
		groups[face]=triangles
	var complete: bool = foundations.size()==64*3 and groups.size()==32
	var samples := 0
	var edges: Array[PackedVector3Array] = _foundation_edges()
	for face: int in range(edges.size()):
		var triangles: PackedVector3Array = groups.get(face,PackedVector3Array())
		var a: Vector3 = edges[face][0]
		var b: Vector3 = edges[face][1]
		var area := 0.0
		for index: int in range(0,triangles.size(),3):
			area += (triangles[index+1]-triangles[index]).cross(triangles[index+2]-triangles[index]).length()*.5
		complete = triangles.size()==6 and absf(area-a.distance_to(b)*(a.y-BOTTOM))<.025 and complete
		for t: float in [0.0,.25,.5,.75,1.0]:
			var top := a.lerp(b,t)
			for depth: float in [0.0,.25,.5,.75,1.0]:
				var at := Vector3(top.x,lerpf(top.y,BOTTOM,depth),top.z)
				var covered := false
				for index: int in range(0,triangles.size(),3):
					covered = _on_triangle(at,triangles[index],triangles[index+1],triangles[index+2]) or covered
				complete = covered and complete
				samples += 1
	print("HORIZON FOUNDATION triangles=",foundations.size()/3," faces=",groups.size()," independent_samples=",samples," complete=",complete," originals_valid=",valid)
	check.call(valid and identities.size()==8 and displays.size()==8 and complete,
		"horizon frontage:64 actual unshaded triangles cover all32 fixed vertical foundations while eight original lit/shadowed masses retain their bases, roofs and footprints")
	var unchanged := true
	for enabled: bool in [false,true]:
		Horizon.set_enabled(world,enabled)
		unchanged = context.visible==enabled and unchanged
		for index: int in range(displays.size()):
			unchanged = _frontage_state(displays[index])==states[index] and unchanged
	check.call(unchanged and displays.size()==8,
		"horizon frontage: appearance toggle changes only context foundations and never original meshes, poses, bounds, materials or shadow properties")


static func _frontage_specs() -> Array[AABB]:
	# Fixed original World bounds, independent of candidate part metadata,
	# transformed corners or whichever meshes the implementation selected.
	return [AABB(Vector3(-121,6,-155),Vector3(32,15,12)),AABB(Vector3(-86,6,-155),Vector3(32,15,12)),
		AABB(Vector3(54,6,-155),Vector3(32,15,12)),AABB(Vector3(89,6,-155),Vector3(32,15,12)),
		AABB(Vector3(136,0,-41),Vector3(12,16,34)),AABB(Vector3(136,0,1),Vector3(12,16,34)),
		AABB(Vector3(36,6,-128),Vector3(12,18,20)),AABB(Vector3(-31,6,-140),Vector3(62,19,12))]


static func _foundation_edges() -> Array[PackedVector3Array]:
	var edges: Array[PackedVector3Array] = []
	for bounds: AABB in _frontage_specs():
		var a := bounds.position
		var b := Vector3(bounds.end.x,a.y,a.z)
		var c := Vector3(bounds.end.x,a.y,bounds.end.z)
		var d := Vector3(a.x,a.y,bounds.end.z)
		for pair: Array in [[a,b],[b,c],[c,d],[d,a]]:
			edges.append(PackedVector3Array(pair))
	return edges


static func _foundation_face_index(a: Vector3, b: Vector3, c: Vector3) -> int:
	var edges: Array[PackedVector3Array] = _foundation_edges()
	for index: int in range(edges.size()):
		var first: Vector3 = edges[index][0]
		var last: Vector3 = edges[index][1]
		var inside := true
		for at: Vector3 in [a,b,c]:
			inside = at.y>=BOTTOM-EPS and at.y<=first.y+EPS \
				and _segment_distance(Vector3(at.x,first.y,at.z),first,last)<EPS and inside
		if inside: return index
	return -1


static func _frontage_state(display: MeshInstance3D) -> Dictionary:
	var material := display.material_override as StandardMaterial3D
	return {"mesh":display.mesh,"mesh_size":(display.mesh as BoxMesh).size,"faces":display.mesh.get_faces(),
		"pose":display.transform,"world_pose":display.global_transform,"material":material,"overlay":display.material_overlay,
		"shadow":display.cast_shadow,"gi":display.gi_mode,"bounds":display.get_aabb(),"custom_bounds":display.custom_aabb,
		"margin":display.extra_cull_margin,"layers":display.layers,"ignore_occlusion":display.ignore_occlusion_culling,
		"visible":display.visible,"range_begin":display.visibility_range_begin,"range_end":display.visibility_range_end,
		"material_values":[] if material==null else [material.shading_mode,material.albedo_color,material.albedo_texture,
			material.normal_enabled,material.normal_texture,material.uv1_scale,material.uv1_triplanar,
			material.uv1_world_triplanar,material.roughness,material.disable_receive_shadows,material.transparency]}


static func _frontage_bounds(world: Node3D, display: MeshInstance3D) -> AABB:
	var faces: PackedVector3Array = display.mesh.get_faces()
	var bounds := AABB(world.to_local(display.to_global(faces[0])),Vector3.ZERO)
	for point: Vector3 in faces: bounds=bounds.expand(world.to_local(display.to_global(point)))
	return bounds


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


static func _expected_land()->PackedVector3Array:
	var faces:=PackedVector3Array()
	# Independent fixed world corners; do not consume implementation metadata.
	for bounds:Rect2 in [Rect2(-130,-108,36,66),Rect2(-94,-108,59,22),Rect2(-140,-108,10,16)]:
		var a:=Vector3(bounds.position.x,.5,bounds.position.y)
		var b:=Vector3(bounds.end.x,.5,bounds.position.y)
		var c:=Vector3(bounds.end.x,.5,bounds.end.y)
		var d:=Vector3(bounds.position.x,.5,bounds.end.y)
		faces.append_array(PackedVector3Array([a,b,c,a,c,d]))
	return faces
