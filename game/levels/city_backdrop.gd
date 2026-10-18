extends RefCounted
## Original non-playable city context behind the existing retained boundaries.
## Startup only: no bodies, routes, camera changes, lights, textures or processing.
## World calls build() after all physical boundaries and before static batching.

const MAX_TRIANGLES := 4040
const MAX_SURFACES := 6
const DEFAULT_MAX_TRIANGLES := 2132
const DEFAULT_MAX_SURFACES := 2
# Direction toward the existing static sun, rotation (-42,-32,0) degrees.
# Baked once into vertex colours; this backdrop never receives dynamic light.
const SUN_TO_LIGHT := Vector3(-0.393807, 0.669131, 0.630223)
const RETAINED_FAMILIES: Array[String] = [
	"StationNorthBoundary", "StationSouthBoundary", "StationWestCornerBoundary",
	"MarketSouthBoundary", "MarketNorthBoundary", "MarketEastBoundary",
	"CivicSideBoundary", "ClimbingStreetOuterBoundary",
	"BackStreetNorthBoundary", "MarketClimbInnerBoundary", "MarketBackStreetInnerBoundary",
	"MerchantCourtEastBoundary", "QuayLandwardBoundary", "NorthQuayEndBoundary",
	"SouthQuayEndBoundary", "ParkRetainedBoundary", "SouthLandscapeEndBoundary",
	"SouthLandscapeRearBoundary", "SouthLandscapeNorthBoundary",
]
const PROTECTED := {
	"river_channel": Rect2(-450, 78, 900, 38),
	"station_clyde_port": Rect2(-102, 40, 16, 31),
	"market_clyde_port": Rect2(86, 40, 16, 31),
	"park_station_port": Rect2(-151, -8, 23, 16),
	"park_civic_port": Rect2(-48, -128, 18, 12),
}


class MeshData:
	extends RefCounted
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var parts: Array[Dictionary] = []


static func build(world: Node3D, _materials: Dictionary, include_held_context: bool = false) -> Node3D:
	assert(world != null and world.is_inside_tree())
	# Idempotence avoids duplicated coplanar scenery if a caller retries setup.
	var existing := world.get_node_or_null("CityBackdrop") as Node3D
	if existing != null: return existing
	var root := Node3D.new()
	root.name = "CityBackdrop"
	root.set_meta("art_only", true)
	root.set_meta("include_held_context", include_held_context)
	root.set_meta("protected_rectangles", PROTECTED.duplicate())
	root.set_meta("reference_note", "Original Glasgow-inspired service backs, warehouse rooflines and wooded-land silhouettes; not surveyed real shops")
	world.add_child(root)
	var distant := StandardMaterial3D.new()
	distant.resource_name = "SharedUnshadedBackdropColour"
	distant.vertex_color_use_as_albedo = true
	distant.vertex_color_is_srgb = true
	distant.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	distant.disable_receive_shadows = true
	distant.roughness = 0.96
	distant.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# Retaining faces join the existing regional meshes, never a whole-map AABB.
	# Only the two Clyde chunks are constructed normally. Station/park work is
	# retained for explicit diagnostics after failing its measured timing gate;
	# it allocates no mesh data or unused geometry on the default startup path.
	var chunks := {
		"ClydeWestContext":MeshData.new(), "ClydeEastContext":MeshData.new(),
	}
	if include_held_context:
		chunks = {
			"ExistingBoundaryRetainingSkirts":MeshData.new(), "StationServiceBacks":MeshData.new(),
			"ClydeWestContext":MeshData.new(), "ClydeEastContext":MeshData.new(),
			"ParkWestHillside":MeshData.new(), "ParkNorthHillside":MeshData.new(),
		}
	_build_retaining_skirts(world, chunks)
	for side: float in [-1.0, 1.0]:
		var river: MeshData = chunks["ClydeWestContext" if side<0 else "ClydeEastContext"]
		_build_river_continuation(river, side)
	if include_held_context:
		var station: MeshData = chunks["StationServiceBacks"]
		_building(station, "WestStationServiceBack", Rect2(-128,48,24,5), -4, 7, Color("756c60"))
		_building(station, "EastStationServiceBack", Rect2(-84,48,32,5), -4, 9, Color("7d7062"))
		for west: bool in [true, false]:
			var park: MeshData = chunks["ParkWestHillside" if west else "ParkNorthHillside"]
			var bounds := Rect2(-325,-225,70,165) if west else Rect2(-325,-295,185,70)
			_terrain(park, "ParkWoodlandSlope", bounds, 10.0,
				func(x: float, z: float) -> float: return _park_backdrop_height(world,x,z), Color("57644f"))
	var rows: Array[Dictionary] = []
	for id: String in chunks: rows.append(_flush(root,id,chunks[id],distant))
	var triangles := 0
	for row: Dictionary in rows: triangles += int(row.triangles)
	var triangle_budget := MAX_TRIANGLES if include_held_context else DEFAULT_MAX_TRIANGLES
	var surface_budget := MAX_SURFACES if include_held_context else DEFAULT_MAX_SURFACES
	assert(triangles <= triangle_budget and rows.size() <= surface_budget, "Backdrop exceeded its declared geometry/draw budget")
	root.set_meta("backdrop_report", {"schema":4, "chunks":rows, "triangles":triangles,
		"include_held_context":include_held_context, "held_context_constructed":include_held_context,
		"mesh_instances":rows.size(), "surfaces":rows.size(), "maximum_main_draws":rows.size(),
		"shared_materials":1, "new_textures":0, "shadow_casting_instances":0,
		"shading":"unshaded_vertex_colour", "receives_lighting_or_shadows":false,
		"baked_sun_direction":SUN_TO_LIGHT, "baked_ambient_factor":0.68, "baked_diffuse_factor":0.28,
		"skirt_partition":"city / river X0 hemispheres / park segment midpoint Z-142",
		"physics_objects":0, "process_callbacks":0, "max_triangles_budget":triangle_budget,
		"max_surfaces_budget":surface_budget, "cost_note":"Authored budgets only; actual matched renderer counters/frame times remain required"})
	return root


static func _build_retaining_skirts(world: Node3D, chunks: Dictionary) -> void:
	for body: Node3D in world.find_children("*", "StaticBody3D", true, false):
		if not bool(body.get_meta("exploration_boundary", false)): continue
		var family := str(body.get_meta("boundary_family", ""))
		if family not in RETAINED_FAMILIES: continue
		if not _is_river_skirt(family) and not chunks.has("ExistingBoundaryRetainingSkirts"): continue
		var source: PackedVector3Array = body.get_meta("boundary_points", PackedVector3Array())
		var points := PackedVector3Array()
		for point: Vector3 in source: points.append(world.to_local(body.to_global(point)))
		var authored := points
		points = _simplified_edge(points)
		if _is_river_skirt(family): points = _split_river_midline(points)
		var fragment := PackedVector3Array()
		var previous_chunk := ""
		for i: int in range(points.size() - 1):
			var chunk := _skirt_chunk(family,(points[i]+points[i+1])*0.5)
			assert(chunks.has(chunk), "Retaining source must belong to an active region")
			if chunk != previous_chunk:
				if not fragment.is_empty():
					_record_fragment(chunks[previous_chunk],family,str(world.get_path_to(body)),authored,fragment)
				fragment=PackedVector3Array([points[i]])
				previous_chunk=chunk
			fragment.append(points[i+1])
			var data: MeshData = chunks[chunk]
			var a := points[i] - Vector3.UP * 0.12
			var b := points[i+1] - Vector3.UP * 0.12
			var bottom := minf(-6.0, minf(a.y,b.y)-4.0)
			var c := Vector3(b.x,bottom,b.z)
			var d := Vector3(a.x,bottom,a.z)
			var normal := Vector3(b.z-a.z,0,a.x-b.x).normalized()
			# Two opposed, culled faces explain the same retained edge from either
			# side. No top face adds apparent supported ground across a void.
			_quad(data,a,b,c,d,normal,Color("72766d"))
			_quad(data,d,c,b,a,-normal,Color("72766d"))
		if not fragment.is_empty():
			_record_fragment(chunks[previous_chunk],family,str(world.get_path_to(body)),authored,fragment)


static func _record_fragment(data: MeshData, family: String, path: String, authored: PackedVector3Array, points: PackedVector3Array) -> void:
	data.parts.append({"id":family,"source_path":path,"boundary_points":authored,
		"rendered_points":points,"is_partition_fragment":true,
		"maximum_simplification_error_m":0.0001,"kind":"vertical_skirt_only","top_offset":-0.12})


static func _is_river_skirt(family: String) -> bool:
	return family in ["QuayLandwardBoundary","NorthQuayEndBoundary","SouthQuayEndBoundary",
		"SouthLandscapeEndBoundary","SouthLandscapeRearBoundary","SouthLandscapeNorthBoundary"]


static func _skirt_chunk(family: String, midpoint: Vector3) -> String:
	if _is_river_skirt(family): return "ClydeWestContext" if midpoint.x<0 else "ClydeEastContext"
	if family=="ParkRetainedBoundary": return "ParkNorthHillside" if midpoint.z<=-142.0 else "ParkWestHillside"
	return "ExistingBoundaryRetainingSkirts"


static func _split_river_midline(points: PackedVector3Array) -> PackedVector3Array:
	# Split only a crossing segment, retaining its exact linear height/UV/colour
	# interpolation. This prevents either river mesh from spanning both halves.
	var result := PackedVector3Array()
	for i: int in range(points.size()-1):
		var a := points[i]
		var b := points[i+1]
		result.append(a)
		if a.x*b.x<0.0:
			var split := a.lerp(b,-a.x/(b.x-a.x))
			split.x=0.0
			result.append(split)
	if not points.is_empty(): result.append(points[points.size()-1])
	return result


static func _simplified_edge(points: PackedVector3Array) -> PackedVector3Array:
	if points.size() <= 2: return points
	var indices: Array[int] = [0]
	_simplify_range(points,0,points.size()-1,indices)
	var result := PackedVector3Array()
	for index: int in indices: result.append(points[index])
	return result


static func _simplify_range(points: PackedVector3Array, first: int, last: int, indices: Array[int]) -> void:
	var delta := points[last]-points[first]
	var squared := delta.length_squared()
	var largest := 0.0001
	var split := -1
	for index: int in range(first+1,last):
		var t := clampf((points[index]-points[first]).dot(delta)/squared,0,1) if squared>0.000001 else 0.0
		var distance := points[index].distance_to(points[first]+delta*t)
		if distance>largest:
			largest=distance
			split=index
	if split<0:
		indices.append(last)
	else:
		_simplify_range(points,first,split,indices)
		_simplify_range(points,split,last,indices)


static func _build_river_continuation(data: MeshData, side: float) -> void:
	var left := -270.0 if side < 0 else 150.5
	var width := 119.5
	for north: bool in [true, false]:
		var bounds := Rect2(left,50,width,28) if north else Rect2(left,116,width,13.5)
		_terrain(data,"RiverBankBeyondEndFence",bounds,8.0,
			func(x: float, z: float) -> float: return _river_bank_height(x,z,north),Color("65715b"))
		var z := 78.0 if north else 116.0
		var a := Vector3(left,_river_bank_height(left,z,north),z)
		var b := Vector3(left+width,_river_bank_height(left+width,z,north),z)
		var normal := Vector3.BACK if north else Vector3.FORWARD
		_quad(data,a,b,Vector3(b.x,-6,z),Vector3(a.x,-6,z),normal,Color("787970"))
	_building(data,"DistantNorthWarehouse",Rect2(side*185-20,38,40,12),-4,10 if side<0 else 12,Color("7a756b"))
	_building(data,"DistantSouthWarehouse",Rect2(side*235-26,119,52,10),-4,16 if side<0 else 13,Color("80756a"))


static func _river_bank_height(x: float, z: float, north: bool) -> float:
	var outward := smoothstep(150.5,190.0,absf(x))
	var from_water := 78.0-z if north else z-116.0
	var ridge := sin(clampf(from_water / (28.0 if north else 13.5),0,1)*PI)
	return 2.0 + outward*(0.4+ridge*(2.0+0.8*sin(x*0.047)))


static func _park_backdrop_height(world: Node3D, x: float, z: float) -> float:
	# Query only inside existing supported park terrain, preserving its actual
	# sampled edge. The new slope starts outside the 3m retained physical fence.
	var at := Vector3(clampf(x,-254.99,-140.01),0,clampf(z,-224.99,-60.01))
	var base: float = float(world.call("get_ground_height",world.to_global(at))) - world.global_position.y
	assert(is_finite(base), "Backdrop needs the authored park edge, not assumed ground")
	var distance := maxf(maxf(-255.0-x,0),maxf(-225.0-z,0))
	var t := clampf(distance/70.0,0,1)
	return base + sin(t*PI)*(18.0+2.0*sin(x*0.029+z*0.037)) - smoothstep(0.68,1.0,t)*12.0


static func _terrain(data: MeshData, id: String, bounds: Rect2, spacing: float, height_at: Callable, color: Color) -> void:
	var xs: Array[float] = []
	var zs: Array[float] = []
	for i: int in range(ceili(bounds.size.x/spacing)+1): xs.append(minf(bounds.end.x,bounds.position.x+i*spacing))
	for i: int in range(ceili(bounds.size.y/spacing)+1): zs.append(minf(bounds.end.y,bounds.position.y+i*spacing))
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for z: float in zs:
		for x: float in xs: vertices.append(Vector3(x,height_at.call(x,z),z))
	for j: int in zs.size():
		for i: int in xs.size():
			var west := vertices[j*xs.size()+maxi(0,i-1)]
			var east := vertices[j*xs.size()+mini(xs.size()-1,i+1)]
			var north := vertices[maxi(0,j-1)*xs.size()+i]
			var south := vertices[mini(zs.size()-1,j+1)*xs.size()+i]
			normals.append(Vector3(-(east.y-west.y)/(east.x-west.x),1.0,-(south.y-north.y)/(south.z-north.z)).normalized())
	for j: int in range(zs.size()-1):
		for i: int in range(xs.size()-1):
			var a := j*xs.size()+i
			for tri: Vector3i in [Vector3i(a,a+1,a+xs.size()),Vector3i(a+1,a+xs.size()+1,a+xs.size())]:
				for index: int in [tri.x,tri.y,tri.z]:
					var shade := 0.96 + 0.04*sin(vertices[index].x*0.031+vertices[index].z*0.023)
					_vertex(data,vertices[index],normals[index],Color(color.r*shade,color.g*shade,color.b*shade))
	data.parts.append({"id":id, "bounds_xz":bounds, "kind":"nonplayable_slope"})


static func _building(data: MeshData, id: String, bounds: Rect2, bottom: float, eaves: float, color: Color) -> void:
	var center := Vector3(bounds.get_center().x,(bottom+eaves)*0.5,bounds.get_center().y)
	_box(data,center,Vector3(bounds.size.x,eaves-bottom,bounds.size.y),color)
	var roof := Color("4e5658")
	var a := Vector3(bounds.position.x-0.22,eaves,bounds.position.y-0.22)
	var b := Vector3(bounds.end.x+0.22,eaves,bounds.position.y-0.22)
	var c := Vector3(bounds.end.x+0.22,eaves,bounds.end.y+0.22)
	var d := Vector3(bounds.position.x-0.22,eaves,bounds.end.y+0.22)
	var l := Vector3(a.x,eaves+1.5,bounds.get_center().y)
	var r := Vector3(b.x,eaves+1.5,bounds.get_center().y)
	_quad(data,a,b,r,l,Vector3(0,bounds.size.y*0.5,-1.5).normalized(),roof)
	_quad(data,d,l,r,c,Vector3(0,bounds.size.y*0.5,1.5).normalized(),roof)
	_triangle(data,a,l,d,Vector3.LEFT,color)
	_triangle(data,b,c,r,Vector3.RIGHT,color)
	# Large, quiet windows and masonry bands read as building backs at range;
	# no thin grids, animated surfaces, emissive panes or fine normal detail.
	for front: bool in [true,false]:
		var z := bounds.position.y-0.04 if front else bounds.end.y+0.04
		var normal := Vector3.FORWARD if front else Vector3.BACK
		for y: float in [3.8,7.0,10.2]:
			if y+0.9 >= eaves: continue
			for i: int in range(1,floori(bounds.size.x/4.5)):
				var x := bounds.position.x+float(i)*4.5
				_quad(data,Vector3(x-0.65,y-0.8,z),Vector3(x+0.65,y-0.8,z),Vector3(x+0.65,y+0.8,z),Vector3(x-0.65,y+0.8,z),normal,Color("455358"))
	_box(data,Vector3(center.x-bounds.size.x*0.28,eaves+1.4,center.z),Vector3(1.1,2.0,0.9),color.darkened(0.12))
	_box(data,Vector3(center.x,eaves-0.20,center.z),Vector3(bounds.size.x+0.12,0.22,bounds.size.y+0.12),color.lightened(0.07))
	data.parts.append({"id":id, "bounds_xz":bounds.grow(0.22), "bottom":bottom, "top":eaves+2.4, "kind":"nonplayable_building_back"})


static func _box(data: MeshData, center: Vector3, size: Vector3, color: Color) -> void:
	var a := center-size*0.5
	var b := center+size*0.5
	_quad(data,Vector3(a.x,a.y,a.z),Vector3(b.x,a.y,a.z),Vector3(b.x,b.y,a.z),Vector3(a.x,b.y,a.z),Vector3.FORWARD,color)
	_quad(data,Vector3(a.x,a.y,b.z),Vector3(a.x,b.y,b.z),Vector3(b.x,b.y,b.z),Vector3(b.x,a.y,b.z),Vector3.BACK,color)
	_quad(data,Vector3(a.x,a.y,a.z),Vector3(a.x,b.y,a.z),Vector3(a.x,b.y,b.z),Vector3(a.x,a.y,b.z),Vector3.LEFT,color)
	_quad(data,Vector3(b.x,a.y,a.z),Vector3(b.x,a.y,b.z),Vector3(b.x,b.y,b.z),Vector3(b.x,b.y,a.z),Vector3.RIGHT,color)
	_quad(data,Vector3(a.x,b.y,a.z),Vector3(b.x,b.y,a.z),Vector3(b.x,b.y,b.z),Vector3(a.x,b.y,b.z),Vector3.UP,color)
	_quad(data,Vector3(a.x,a.y,a.z),Vector3(a.x,a.y,b.z),Vector3(b.x,a.y,b.z),Vector3(b.x,a.y,a.z),Vector3.DOWN,color)


static func _quad(data: MeshData, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color) -> void:
	_triangle(data,a,b,c,normal,color)
	_triangle(data,a,c,d,normal,color)


static func _triangle(data: MeshData, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, color: Color) -> void:
	var vertices: Array[Vector3] = [a,b,c]
	if (b-a).cross(c-a).dot(normal)>0: vertices=[a,c,b]
	for at: Vector3 in vertices: _vertex(data,at,normal,color)


static func _vertex(data: MeshData, at: Vector3, normal: Vector3, color: Color) -> void:
	data.vertices.append(at)
	data.normals.append(normal)
	var light := 0.68 + 0.28*maxf(0.0,normal.dot(SUN_TO_LIGHT))
	data.colors.append(Color(color.r*light,color.g*light,color.b*light,color.a))
	# UVs remain deterministic source attributes; the single unshaded material
	# uses no texture, normal, triplanar or screen-space shadow sampling.
	data.uvs.append(Vector2(at.x+at.z,at.y)*0.25)


static func _flush(root: Node3D, id: String, data: MeshData, material: Material) -> Dictionary:
	assert(not data.vertices.is_empty() and data.vertices.size()%3==0)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=data.vertices
	arrays[Mesh.ARRAY_NORMAL]=data.normals
	arrays[Mesh.ARRAY_COLOR]=data.colors
	arrays[Mesh.ARRAY_TEX_UV]=data.uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var display := MeshInstance3D.new()
	display.name=id
	display.mesh=mesh
	display.material_override=material
	display.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	display.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
	display.set_meta("backdrop_chunk",true)
	root.add_child(display)
	return {"name":id,"triangles":data.vertices.size()/3,"surfaces":1,
		"bounds_local":mesh.get_aabb(),"material_instance_id":material.get_instance_id(),"parts":data.parts}
