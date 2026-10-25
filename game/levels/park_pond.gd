extends Node3D
## PT24-16 candidate in the existing low park lawn. Installation is explicit;
## normal play must retain the existing rendering admission gate.
## All terrain cutting, native shapes and shared scenic batches are built once.

const Line = preload("res://game/tricks/grind_line.gd")
const StaticBatches = preload("res://game/levels/static_batches.gd")
const CENTRE := Vector3(-184.0, 0.5, -21.0)
const INNER := Vector2(8.0, 6.0)
const OUTER := Vector2(10.0, 8.0)
const WATER_Y := 0.12
const FLOOR_Y := -0.85
const SEGMENTS := 32
const RAIL_Y := 1.02
const RAIL_RADIUS := 0.07
const BUDGET := {"resident_surfaces": 8, "new_triangles": 1400,
	"bodies": 2, "shapes": 41, "textures": 0, "lights": 0}

var _world: Node3D
var _built := false
var _outer := PackedVector2Array()
var _water := PackedVector2Array()
var _ground := PackedVector3Array()
var _lines: Array = []


func build(world: Node3D) -> void:
	if _built: return
	_world = world
	name = "KelvingrovePond"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if get_parent() == null: world.add_child(self)
	assert(transform.is_equal_approx(Transform3D.IDENTITY))
	var outdoors: Node3D = world.get_node("OutdoorRoutes")
	var ground: StaticBody3D = outdoors.get_node("KelvingroveCentralEmbankment")
	for index: int in SEGMENTS:
		var angle := float(index) / SEGMENTS * TAU
		_outer.append(Vector2(CENTRE.x + OUTER.x * cos(angle), CENTRE.z + OUTER.y * sin(angle)))
		_water.append(Vector2(CENTRE.x + INNER.x * cos(angle), CENTRE.z + INNER.y * sin(angle)))
	# There must be a real hole in both authoritative terrain and displayed lawn.
	# Cutting only the art would leave an invisible lawn over the water hazard.
	_excavate(ground, _outer)
	_build_basin(world._materials["cut_stone"])
	var water_visual := MeshInstance3D.new()
	water_visual.name = "PondWater"
	water_visual.mesh = _disc(_water, WATER_Y)
	water_visual.material_override = outdoors.get_node("ClydeWater").material_override
	add_child(water_visual)
	_build_rail(world._materials["iron"])
	_build_ducks(world._materials)
	_built = true
	set_meta("construction_budget", BUDGET.duplicate())
	set_meta("hazard_id", "kelvingrove_pond")


func get_grind_lines() -> Array:
	return _lines.duplicate()


func get_route_definitions() -> Array[Dictionary]:
	return [{"id":"kelvingrove_pond_dry_bypass", "label":"Pond dry lawn bypass",
		"points":_world_points([Vector3(-169,0.5,-35),Vector3(-169,0.5,-21),Vector3(-169,0.5,-7)]),
		"requires_jump":false},
		{"id":"kelvingrove_pond_rail_approach", "label":"Pond rail tangent approach",
		"points":_world_points([Vector3(-174,0.5,-34),Vector3(-174,0.5,-27),Vector3(-174,0.5,-21)]),
		"requires_jump":true}]


func get_ground_height(world_point: Vector3) -> float:
	if not _built: return NAN
	var local := to_local(world_point)
	var at := Vector2(local.x, local.z)
	if not _inside(at, _outer): return NAN
	for index: int in range(0, _ground.size(), 3):
		var a := _ground[index]
		var b := _ground[index + 1]
		var c := _ground[index + 2]
		if not _inside_triangle(at, a, b, c): continue
		var normal := (b-a).cross(c-a)
		var height := a.y-(normal.x*(at.x-a.x)+normal.z*(at.y-a.z))/normal.y
		return to_global(Vector3(local.x, height, local.z)).y
	return NAN


func get_recovery_position(world_point: Vector3) -> Vector3:
	if not _built: return Vector3.INF
	var local := to_local(world_point)
	if local.y > WATER_Y + 0.16 or not _inside(Vector2(local.x,local.z), _water): return Vector3.INF
	var angle := atan2((local.z-CENTRE.z)/INNER.y, (local.x-CENTRE.x)/INNER.x)
	var outward := Vector3(cos(angle),0,sin(angle))
	var bank := Vector3(CENTRE.x+OUTER.x*cos(angle), CENTRE.y+0.8, CENTRE.z+OUTER.y*sin(angle))
	return to_global(bank + outward*2.0)


func reset_run() -> void:
	# Scenic ducks and the pond are deliberately static. Recovery state belongs
	# to the existing skater lifecycle; there is no second timer or score owner.
	pass


func _build_basin(material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in SEGMENTS:
		var next := (index + 1) % SEGMENTS
		var outside_a := Vector3(_outer[index].x,CENTRE.y,_outer[index].y)
		var outside_b := Vector3(_outer[next].x,CENTRE.y,_outer[next].y)
		# A separate shore ring meets the water exactly. The submerged bank
		# continues inward; no exposed dry annulus lies below the water plane.
		var shore_a := Vector3(_water[index].x,WATER_Y,_water[index].y)
		var shore_b := Vector3(_water[next].x,WATER_Y,_water[next].y)
		var a := float(index)/SEGMENTS*TAU
		var b := float(next)/SEGMENTS*TAU
		var inside_a := Vector3(CENTRE.x+(INNER.x-1.5)*cos(a),FLOOR_Y,CENTRE.z+(INNER.y-1.5)*sin(a))
		var inside_b := Vector3(CENTRE.x+(INNER.x-1.5)*cos(b),FLOOR_Y,CENTRE.z+(INNER.y-1.5)*sin(b))
		_add_ground(surface, outside_a, shore_a, outside_b)
		_add_ground(surface, outside_b, shore_a, shore_b)
		_add_ground(surface, shore_a, inside_a, shore_b)
		_add_ground(surface, shore_b, inside_a, inside_b)
		_add_ground(surface, Vector3(CENTRE.x,FLOOR_Y,CENTRE.z), inside_b, inside_a)
	var body := StaticBody3D.new()
	body.name = "PondExcavatedBank"
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("surface_audio", "stone")
	body.set_meta("art_label", "PondExcavatedBank")
	add_child(body)
	var visual := MeshInstance3D.new()
	visual.mesh = surface.commit()
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(_ground)
	shape.backface_collision = true
	collision.shape = shape
	body.add_child(collision)


func _add_ground(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var points := PackedVector3Array([a,b,c])
	if (b-a).cross(c-a).y > 0.0:
		points = PackedVector3Array([a,c,b])
	var normal := -(points[1]-points[0]).cross(points[2]-points[0]).normalized()
	_ground.append_array(points)
	for point: Vector3 in points:
		surface.set_normal(normal)
		surface.set_uv(Vector2(point.x,point.z)*0.2)
		surface.add_vertex(point)


func _build_rail(material: Material) -> void:
	var points := PackedVector3Array()
	var beams: Array[Transform3D] = []
	var rail := StaticBody3D.new()
	rail.name = "PondPerimeterRail"
	rail.collision_layer = 2
	rail.collision_mask = 0
	rail.set_meta("authored_grind_ids", ["kelvingrove_pond_perimeter"])
	rail.set_meta("audit_capture_ids", ["kelvingrove_pond_perimeter"])
	rail.set_meta("surface_audio", "metal")
	add_child(rail)
	for index: int in SEGMENTS + 1:
		var at := _outer[index % SEGMENTS]
		points.append(Vector3(at.x, RAIL_Y, at.y))
	for index: int in SEGMENTS:
		var a := points[index]
		var b := points[index+1]
		var frame := Transform3D(Basis.looking_at((b-a).normalized(), Vector3.UP), (a+b)*0.5)
		var size := Vector3(RAIL_RADIUS*2,RAIL_RADIUS*2,a.distance_to(b))
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.transform = frame
		rail.add_child(collision)
		beams.append(Transform3D(frame.basis * Basis.from_scale(size), frame.origin))
		if index % 4 == 0:
			var post_size := Vector3(0.1, RAIL_Y-CENTRE.y, 0.1)
			var post_frame := Transform3D(Basis.IDENTITY,Vector3(a.x,(RAIL_Y+CENTRE.y)*0.5,a.z))
			var post_shape := BoxShape3D.new()
			post_shape.size = post_size
			var post := CollisionShape3D.new()
			post.shape = post_shape
			post.transform = post_frame
			rail.add_child(post)
			beams.append(Transform3D(Basis.from_scale(post_size),post_frame.origin))
	_batch("PondRailSteel", BoxMesh.new(), beams, material)
	var line := Line.from_local_points("kelvingrove_pond_perimeter",points,global_transform,"rail")
	line.configure_contact(0.0,RAIL_RADIUS,"pond.native_flat_square_perimeter")
	_lines.append(line)


func _build_ducks(materials: Dictionary) -> void:
	# Two original, static, low-poly waterfowl, grouped by existing material.
	# No new animation loop, imported asset, light, texture or material.
	var bodies: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var beaks: Array[Transform3D] = []
	for duck: Dictionary in [{"at":Vector3(-186,WATER_Y,-20),"yaw":-0.5},
		{"at":Vector3(-181,WATER_Y,-23),"yaw":1.1}]:
		var frame := Transform3D(Basis(Vector3.UP,float(duck.yaw)),duck.at)
		bodies.append(frame * Transform3D(Basis.from_scale(Vector3(0.52,0.24,0.77)),Vector3(0,0.14,0)))
		heads.append(frame * Transform3D(Basis.from_scale(Vector3(0.25,0.28,0.25)),Vector3(0,0.39,-0.27)))
		beaks.append(frame * Transform3D(Basis.from_scale(Vector3(0.17,0.065,0.24)),Vector3(0,0.36,-0.44)))
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 8
	sphere.rings = 4
	_batch("PondDuckBodies",sphere,bodies,materials["stone_light"])
	_batch("PondDuckHeads",sphere,heads,materials["bronze"])
	_batch("PondDuckBeaks",BoxMesh.new(),beaks,materials["orange"])


func _batch(id: String, mesh: Mesh, frames: Array[Transform3D], material: Material) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = frames.size()
	for index: int in frames.size(): batch.set_instance_transform(index,frames[index])
	var visual := MultiMeshInstance3D.new()
	visual.name = id
	visual.multimesh = batch
	visual.material_override = material
	add_child(visual)
	StaticBatches.register(visual,frames)


func _disc(polygon: PackedVector2Array, height: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in polygon.size():
		var a := polygon[index]
		var b := polygon[(index+1)%polygon.size()]
		for point: Vector3 in [Vector3(CENTRE.x,height,CENTRE.z),Vector3(a.x,height,a.y),Vector3(b.x,height,b.y)]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(point)
	return surface.commit()


func _excavate(body: StaticBody3D, polygon: PackedVector2Array) -> void:
	assert(body.transform.is_equal_approx(Transform3D.IDENTITY))
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
			var before: int = child.shape.get_faces().size()/3
			child.shape.set_faces(_subtract(child.shape.get_faces(),polygon))
			body.set_meta("pond_native_triangle_delta",child.shape.get_faces().size()/3-before)
		elif child is MeshInstance3D:
			var faces := _subtract(child.mesh.get_faces(),polygon)
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for index: int in range(0,faces.size(),3):
				var normal := -(faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).normalized()
				for corner: int in 3:
					var point := faces[index+corner]
					surface.set_normal(normal)
					surface.set_uv(Vector2(point.x,point.z)*0.2)
					surface.add_vertex(point)
			surface.generate_tangents()
			child.mesh = surface.commit()
		body.set_meta("pond_excavated",true)


func _subtract(faces: PackedVector3Array, polygon: PackedVector2Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	for index: int in range(0,faces.size(),3):
		var a := faces[index]
		var b := faces[index+1]
		var c := faces[index+2]
		var normal := (b-a).cross(c-a)
		if absf(normal.y)<0.000001:
			result.append_array(PackedVector3Array([a,b,c]))
			continue
		var footprint := PackedVector2Array([Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z)])
		for remainder: PackedVector2Array in Geometry2D.clip_polygons(footprint,polygon):
			var indices := Geometry2D.triangulate_polygon(remainder)
			for at: int in range(0,indices.size(),3):
				var triangle := PackedVector3Array()
				for corner: int in 3:
					var xz := remainder[indices[at+corner]]
					var y := a.y-(normal.x*(xz.x-a.x)+normal.z*(xz.y-a.z))/normal.y
					triangle.append(Vector3(xz.x,y,xz.y))
				if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).y>0.0:
					var swap := triangle[1];triangle[1]=triangle[2];triangle[2]=swap
				result.append_array(triangle)
	return result


func _world_points(local_points: Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	for point: Vector3 in local_points: result.append(to_global(point))
	return result


func _inside(at: Vector2, polygon: PackedVector2Array) -> bool:
	if absf(at.x-CENTRE.x)>OUTER.x+0.00001 or absf(at.y-CENTRE.z)>OUTER.y+0.00001:
		return false
	if Geometry2D.is_point_in_polygon(at,polygon): return true
	for index: int in polygon.size():
		if Geometry2D.get_closest_point_to_segment(at,polygon[index],polygon[(index+1)%polygon.size()]).distance_to(at)<0.00001:
			return true
	return false


func _inside_triangle(at: Vector2,a: Vector3,b: Vector3,c: Vector3) -> bool:
	var first := Vector2(b.x-a.x,b.z-a.z)
	var second := Vector2(c.x-a.x,c.z-a.z)
	var offset := at-Vector2(a.x,a.z)
	var area := first.cross(second)
	if absf(area)<0.000001: return false
	var u := offset.cross(second)/area
	var v := first.cross(offset)/area
	return u>=-0.00001 and v>=-0.00001 and u+v<=1.00001
