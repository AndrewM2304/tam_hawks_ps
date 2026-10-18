extends RefCounted
## Startup-only, original distant context and exact vertical boundary footings.
## No collision, horizontal support, lights or frame callbacks.
const EdgeSource = preload("res://game/levels/city_backdrop.gd")
const SKY_CUBE = preload("res://game/art/assets/horizon/glasgow_horizon_cube.png")
const SKY_SHADER = preload("res://game/art/assets/horizon/horizon_sky.gdshader")
const FOOTING_SHADER = preload("res://game/art/assets/horizon/footing_colour.gdshader")
const MASONRY = preload("res://game/art/assets/zc_textures/T_bricks01/T_bricks01_albedo.jpg")
const MAX_TRIANGLES := 832
const MAX_SURFACES := 4
const BOTTOM := -35.0


static func install(world: Node3D, sky: Sky) -> Node3D:
	var existing := world.get_node_or_null("HorizonContext") as Node3D
	if existing != null: return existing
	var context := Node3D.new()
	context.name = "HorizonContext"
	context.set_meta("art_only", true)
	world.add_child(context)
	var panorama := ShaderMaterial.new()
	panorama.shader = SKY_SHADER
	panorama.set_shader_parameter("context_sky", SKY_CUBE)
	context.set_meta("sky", sky)
	context.set_meta("original_sky_material", sky.sky_material)
	context.set_meta("original_sky_process_mode", sky.process_mode)
	context.set_meta("panorama_material", panorama)
	var material := ShaderMaterial.new()
	material.resource_name = "BoundaryFootingColour"
	material.shader = FOOTING_SHADER
	var chunks := {}
	for id: String in ["CityFootings", "ClydeFootings", "ParkWestFootings", "ParkNorthFootings"]:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		chunks[id] = {"tool":tool, "triangles":0, "parts":[]}
	for body: Node3D in world.find_children("*", "StaticBody3D", true, false):
		if not bool(body.get_meta("exploration_boundary", false)): continue
		var family := str(body.get_meta("boundary_family", ""))
		var source: PackedVector3Array = body.get_meta("boundary_points", PackedVector3Array())
		var authored := PackedVector3Array()
		for point: Vector3 in source: authored.append(world.to_local(body.to_global(point)))
		var points: PackedVector3Array = EdgeSource._simplified_edge(authored)
		for i: int in range(points.size()-1):
			var a := points[i]
			var b := points[i+1]
			var mid := (a+b)*.5
			var id := "CityFootings"
			if family == "ParkRetainedBoundary":
				id = "ParkWestFootings" if mid.z > -142.0 else "ParkNorthFootings"
			elif family in ["QuayApproachBoundary", "QuayLandwardBoundary", "NorthQuayEndBoundary", "SouthPocketEndBoundary", "SouthPocketRearBoundary"]:
				id = "ClydeFootings"
			var chunk: Dictionary = chunks[id]
			var colour := Color("686f65") if family == "ParkRetainedBoundary" else Color("77766d")
			# Meet the baseline inside its existing buried plinth, never create
			# supported-looking horizontal ground or bridge an authored opening.
			_quad(chunk.tool, a, b, Vector3(b.x,BOTTOM,b.z), Vector3(a.x,BOTTOM,a.z), colour)
			chunk.triangles += 2
			chunk.parts.append({"source_path":str(world.get_path_to(body)), "family":family,
				"a":a,"b":b,"top_lift":0.0,"bottom":BOTTOM})
		# The reported brick-block slit is behind this continuous blocked edge.
		# Its fixed-level service back embeds in the plinth across the loading
		# bank's .25m grade. A 1cm outward offset avoids coplanar footing faces
		# while remaining inside the existing 20cm solid guard footprint.
		if family == "MarketEastBoundary":
			var a := Vector3(129.81,-.1,-8)
			var b := Vector3(129.81,-.1,2)
			_quad(chunks.CityFootings.tool,a+Vector3.UP*5.15,b+Vector3.UP*5.15,b,a,Color("827665"))
			chunks.CityFootings.triangles += 2
			chunks.CityFootings.parts.append({"source_path":str(world.get_path_to(body)),"family":family,
				"a":a,"b":b,"top_lift":5.15,"bottom":-.1,"service_back":true})
	# The distant water must turn behind real scenic banks before the camera's
	# far clip. A sky cannot disguise a rectangular water plane ending in air.
	_river_bends(world, context, chunks.ClydeFootings)
	_frontage_foundations(world, chunks.CityFootings)
	var triangles := 0
	var surfaces := 0
	var parts: Array = []
	for id: String in chunks:
		var chunk: Dictionary = chunks[id]
		if int(chunk.triangles) == 0: continue
		var display := MeshInstance3D.new()
		display.name = id
		display.mesh = chunk.tool.commit()
		display.material_override = material
		display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		display.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		context.add_child(display)
		triangles += int(chunk.triangles)
		surfaces += 1
		parts.append_array(chunk.parts)
	assert(triangles + 18 <= MAX_TRIANGLES and surfaces <= MAX_SURFACES, "Horizon context budget exceeded")
	context.set_meta("footing_report", {"triangles":triangles,"surfaces":surfaces,"parts":parts})
	_finish_guard(world,context)
	set_enabled(world, true)
	return context


static func set_enabled(world: Node3D, enabled: bool) -> void:
	var context := world.get_node_or_null("HorizonContext") as Node3D
	if context == null: return
	var sky: Sky = context.get_meta("sky")
	sky.sky_material = context.get_meta("panorama_material" if enabled else "original_sky_material")
	sky.process_mode = Sky.PROCESS_MODE_QUALITY if enabled else int(context.get_meta("original_sky_process_mode"))
	context.visible = enabled
	for row: Dictionary in context.get_meta("wall_finishes", []):
		row.display.material_override = row.candidate if enabled else row.original
	var river: Dictionary = context.get_meta("river_report")
	river.display.mesh = river.candidate if enabled else river.original


static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, colour: Color) -> void:
	for i: int in [0,1,2,0,2,3]:
		tool.set_color(colour if i < 2 else colour.darkened(.16))
		tool.set_normal(-(b-a).cross(c-a).normalized())
		tool.add_vertex([a,b,c,d][i])


static func _finish_guard(world: Node3D, context: Node3D) -> void:
	var finishes: Array = []
	for body: Node3D in world.find_children("*", "StaticBody3D", true, false):
		if str(body.get_meta("boundary_family", "")) != "QuayLandwardBoundary" or float(body.get_meta("boundary_height",0.0)) < 9.0: continue
		var display := body.get_node_or_null("PropertyMasonry") as MultiMeshInstance3D
		if display == null: continue
		var finish := (display.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		finish.resource_name = "OriginalWarehouseStone"
		finish.albedo_color = Color("9aa8b0")
		finish.albedo_texture = MASONRY
		# The native headless MultiMesh transform readback is a dummy. Derive
		# physical dimensions from the existing authored CPU collision instead.
		var collision := body.find_children("*","CollisionShape3D",false,false)[0] as CollisionShape3D
		var size: Vector3 = (collision.shape as BoxShape3D).size
		finish.uv1_scale = Vector3(size.x/1.25,size.y/1.25,1)
		finishes.append({"display":display,"original":display.material_override,"candidate":finish})
	context.set_meta("wall_finishes",finishes)


static func _frontage_foundations(world: Node3D, chunk: Dictionary) -> void:
	# Leave the original lit/shadow-casting masses intact. Only their four
	# vertical foundations join the existing unshaded, shadow-free footing mesh.
	# Read each original bottom corner through both transforms so parent yaw,
	# scale and placement cannot shift its footprint or elevate its roof.
	for display: MeshInstance3D in world.find_children("*","MeshInstance3D",true,false):
		if not bool(display.get_meta("horizon_frontage",false)) or not display.mesh is BoxMesh: continue
		var original := display.mesh as BoxMesh
		var half: Vector3 = original.size*.5
		var corners := PackedVector3Array()
		for point: Vector3 in [Vector3(-half.x,-half.y,-half.z),Vector3(half.x,-half.y,-half.z),
			Vector3(half.x,-half.y,half.z),Vector3(-half.x,-half.y,half.z)]:
			corners.append(world.to_local(display.to_global(point)))
		for side: int in 4:
			var a := corners[side]
			var b := corners[(side+1)%4]
			_quad(chunk.tool,a,b,Vector3(b.x,BOTTOM,b.z),Vector3(a.x,BOTTOM,a.z),Color("877b6b"))
			chunk.triangles += 2
			chunk.parts.append({"source_path":str(world.get_path_to(display)),
				"family":"HorizonFrontageFoundation","foundation":true,"side":side,
				"a":a,"b":b,"top_lift":0.0,"bottom":BOTTOM})


static func _river_bends(world: Node3D, context: Node3D, chunk: Dictionary) -> void:
	var water := world.get_node("OutdoorRoutes/ClydeWater") as MeshInstance3D
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_water_quad(tool, water, world, Vector2(-85,78),Vector2(85,78),Vector2(85,116),Vector2(-85,116))
	var banks: Array = []
	for east: bool in [true,false]:
		var shore := PackedVector2Array([Vector2(85,78),Vector2(115,78),Vector2(145,86),Vector2(174,118),Vector2(230,220)]) if east else PackedVector2Array([Vector2(-85,78),Vector2(-118,78),Vector2(-150,89),Vector2(-180,120),Vector2(-236,220)])
		for i: int in range(shore.size()-1):
			_water_quad(tool,water,world,shore[i],shore[i+1],shore[i+1]+Vector2(0,38),shore[i]+Vector2(0,38))
		for south: bool in [false,true]:
			var edge := PackedVector2Array()
			var back := PackedVector2Array()
			if south:
				edge.append(Vector2(76 if east else -39,116))
				back.append(edge[0]+Vector2(0,24))
			for i: int in shore.size():
				var point := shore[i]+Vector2(0,38 if south else 0)
				var width := 24.0 if south or i>1 else (2.0 if i==0 else 8.0)
				edge.append(point)
				back.append(point+Vector2(0,width if south else -width))
			for i: int in range(edge.size()-1):
				var a := Vector3(edge[i].x,2,edge[i].y)
				var b := Vector3(edge[i+1].x,2,edge[i+1].y)
				var c := Vector3(back[i+1].x,2,back[i+1].y)
				var d := Vector3(back[i].x,2,back[i].y)
				_quad(chunk.tool,a,b,c,d,Color("70766a"))
				_quad(chunk.tool,a,b,Vector3(b.x,BOTTOM,b.z),Vector3(a.x,BOTTOM,a.z),Color("77766d"))
				chunk.triangles += 4
			banks.append({"east":east,"south":south,"edge":edge,"back":back})
	tool.generate_tangents()
	context.set_meta("river_report", {"display":water,"original":water.mesh,"candidate":tool.commit(),
		"banks":banks,"bank_triangles":72,"water_triangles":18,"new_water_materials":0,
		"note":"Art-only bends behind existing closed quay ends; original supported ground/recovery queries unchanged"})


static func _water_quad(tool: SurfaceTool, water: MeshInstance3D, world: Node3D,
		a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> void:
	var corners := [a,b,c,d]
	# Godot's clockwise front faces, independent of east/west path ordering.
	var forward := (b-a).cross(c-a)>0
	for i: int in ([0,1,2,0,2,3] if forward else [0,2,1,0,3,2]):
		var point: Vector2 = corners[i]
		tool.set_normal(Vector3.UP)
		tool.set_uv(point*.1)
		tool.add_vertex(water.to_local(world.to_global(Vector3(point.x,-2,point.y))))
