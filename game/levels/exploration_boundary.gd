extends RefCounted
## Visible retained ironwork at finite scenery edges, never an invisible catch floor.
## Each solid panel follows the same grade/footprint as its batched masonry/rails.

static func build(parent: Node3D, id: String, points: PackedVector3Array,
		stone: Material, iron: Material, height: float = 3.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.set_meta("art_label", id)
	body.set_meta("no_wallride", true)
	body.set_meta("wallride_exclusion_reason", "retained perimeter iron fence; safety boundary")
	body.add_to_group("exploration_boundaries")
	body.set_meta("exploration_boundary", true)
	body.set_meta("boundary_family", id)
	body.set_meta("boundary_points", points)
	body.set_meta("boundary_height", height)
	body.set_meta("surface_audio", "metal")
	parent.add_child(body)
	var masonry: Array[Transform3D] = []
	var metal: Array[Transform3D] = []
	for segment: int in range(points.size() - 1):
		var a := points[segment]
		var b := points[segment + 1]
		var run := Vector2(b.x-a.x,b.z-a.z).length()
		if run < 0.01: continue
		# A retaining prism shares the exact sloping baseline. Its upper panel
		# represents the closely spaced iron uprights, including capsule contact.
		var side := Vector3(b.z-a.z,0,a.x-b.x).normalized() * 0.10
		var vertices := PackedVector3Array()
		for at: Vector3 in [a-side,a+side,b-side,b+side]:
			vertices.append(at - Vector3.UP*0.2)
			vertices.append(at + Vector3.UP*height)
		var shape := ConvexPolygonShape3D.new()
		shape.points = vertices
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		var divisions := maxi(1,ceili(run / 0.28))
		for index: int in range(divisions + 1):
			var at := a.lerp(b,float(index)/divisions)
			metal.append(_box_transform(Vector3(0.035,height-0.4,0.035),at+Vector3.UP*((height+0.4)*0.5)))
		for lift: float in [0.5,height-0.08]:
			metal.append(_beam_transform(a+Vector3.UP*lift,b+Vector3.UP*lift,0.065))
		# Short boxes follow grades without hanging a level wall above a slope.
		for index: int in range(maxi(1,ceili(run / 1.5))):
			var count := maxi(1,ceili(run / 1.5))
			var start := a.lerp(b,float(index)/count)
			var end := a.lerp(b,float(index+1)/count)
			var plinth := _beam_transform(start+Vector3.UP*0.15,end+Vector3.UP*0.15,0.5)
			masonry.append(plinth)
	_flush(body,"RetainedMasonry",masonry,stone)
	_flush(body,"Ironwork",metal,iron)
	_foundation(body,points,stone)
	return body


static func _foundation(parent: Node3D, points: PackedVector3Array, material: Material) -> void:
	# Close exposed map edges with a vertical retaining foundation. All vertices
	# stay below the existing boundary baseline. There is no horizontal catch
	# floor, collision, route extension or new playable ground behind the fence.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var distance := 0.0
	for segment in range(points.size()-1):
		var start := points[segment] - Vector3.UP * 0.2
		var end := points[segment+1] - Vector3.UP * 0.2
		var length := start.distance_to(end)
		if length < 0.01: continue
		var vertices := [start,end,end-Vector3.UP*8.0,start-Vector3.UP*8.0]
		var uv := [Vector2(distance/2.0,0),Vector2((distance+length)/2.0,0),
			Vector2((distance+length)/2.0,4),Vector2(distance/2.0,4)]
		# Separate reversed faces preserve correct lighting on both sides without
		# mutating a shared stone material's cull mode or shader.
		for index: int in [0,1,2,0,2,3,2,1,0,3,2,0]:
			surface.set_uv(uv[index])
			surface.add_vertex(vertices[index])
		distance += length
	if distance <= 0.0: return
	surface.generate_normals()
	var display := MeshInstance3D.new()
	display.name = "ScenicRetainingFoundation"
	display.mesh = surface.commit()
	display.material_override = material
	display.set_meta("scenic_only",true)
	display.set_meta("no_wallride",true)
	display.add_to_group("scenic_foundations")
	parent.add_child(display)


static func _box_transform(size: Vector3, center: Vector3) -> Transform3D:
	return Transform3D(Basis.from_scale(size),center)


static func _beam_transform(a: Vector3,b: Vector3,width: float) -> Transform3D:
	var delta := b-a
	var axis := delta.normalized()
	var basis := Basis(Quaternion(Vector3.FORWARD,axis))
	return Transform3D(basis*Basis.from_scale(Vector3(width,width,delta.length()+0.04)),(a+b)*0.5)


static func _flush(parent: Node3D,id: String,transforms: Array[Transform3D],material: Material) -> void:
	if transforms.is_empty(): return
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	for index: int in range(transforms.size()): instances.set_instance_transform(index,transforms[index])
	var display := MultiMeshInstance3D.new()
	display.name = id
	display.multimesh = instances
	display.material_override = material
	parent.add_child(display)
