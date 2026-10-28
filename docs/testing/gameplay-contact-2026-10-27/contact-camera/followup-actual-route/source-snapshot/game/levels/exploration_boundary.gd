extends RefCounted
## Visible retained ironwork at finite scenery edges, never an invisible catch floor.
## Each solid panel follows the same grade/footprint as its batched masonry/rails.

static func build(parent: Node3D, id: String, points: PackedVector3Array,
		stone: Material, iron: Material, height: float = 3.0, solid: bool = false,
		opaque: bool = false) -> StaticBody3D:
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
	if solid:
		# A straight masonry property wall closes a dry world edge behind the
		# retained yard or raised transition decks.
		# Its buried base covers the small ground grade; one box replaces many
		# fence panels/bars and cannot show empty ground through ironwork gaps.
		var low := points[0]
		var high := points[0]
		for point: Vector3 in points:
			low=low.min(point)
			high=high.max(point)
		low-=Vector3(.18,.25,.18)
		high+=Vector3(.18,height,.18)
		var shape := BoxShape3D.new()
		shape.size=high-low
		var collision := CollisionShape3D.new()
		collision.shape=shape
		collision.position=(high+low)*.5
		body.add_child(collision)
		body.set_meta("solid_boundary",true)
		body.set_meta("surface_audio","stone")
		_flush(body,"PropertyMasonry",[_box_transform(high-low,(high+low)*.5)],stone)
		_admit_masonry(body,points,height)
		return body
	var masonry: Array[Transform3D] = []
	var metal: Array[Transform3D] = []
	var panels := SurfaceTool.new()
	if opaque: panels.begin(Mesh.PRIMITIVE_TRIANGLES)
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
		if opaque:
			# Reuse the exact graded collision prism; a bounding box would cut
			# across the bent approach. Merge all panels into one shared-material
			# surface instead of displaying hundreds of bars and plinths.
			_panel_prism(panels,vertices)
			continue
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
	if opaque:
		panels.generate_tangents()
		var display := MeshInstance3D.new()
		display.name = "GradedMasonryPanels"
		display.mesh = panels.commit()
		display.material_override = stone
		body.add_child(display)
		body.set_meta("opaque_boundary",true)
		body.set_meta("surface_audio","stone")
		_admit_masonry(body,points,height)
	else:
		_flush(body,"RetainedMasonry",masonry,stone)
		_flush(body,"Ironwork",metal,iron)
	return body


static func _admit_masonry(body: StaticBody3D, points: PackedVector3Array, height: float) -> void:
	# Opaque walls keep every existing boundary collider. Riding their real
	# inboard face must not depend on one named property's opt-in. Open iron
	# fences still retain the explicit exclusion established above.
	if not is_finite(height) or height < 1.6 or points.size() < 2:
		return
	var run := 0.0
	for index in range(points.size() - 1):
		if not points[index].is_finite() or not points[index + 1].is_finite():
			return
		run += Vector2(points[index + 1].x - points[index].x, points[index + 1].z - points[index].z).length()
	if run < 2.0:
		return
	body.set_meta("wallrideable", true)
	body.set_meta("no_wallride", false)
	body.remove_meta("wallride_exclusion_reason")


static func _panel_prism(tool: SurfaceTool, vertices: PackedVector3Array) -> void:
	# Clockwise outward faces match the enabled convex collision's eight
	# corners. Face-local UVs preserve stone scale on slopes and diagonal runs.
	for face: Array in [[0,1,4,5],[2,6,3,7],[1,3,5,7],
		[0,4,2,6],[0,2,1,3],[4,5,6,7]]:
		var a: Vector3 = vertices[face[0]]
		var width: float = a.distance_to(vertices[face[2]])*.5
		var height: float = a.distance_to(vertices[face[1]])*.5
		var normal: Vector3 = -(vertices[face[1]]-a).cross(vertices[face[2]]-a).normalized()
		var uvs := [Vector2.ZERO,Vector2(0,height),Vector2(width,0),Vector2(width,height)]
		for corner: int in [0,1,2,1,3,2]:
			tool.set_normal(normal)
			tool.set_uv(uvs[corner])
			tool.add_vertex(vertices[face[corner]])


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
