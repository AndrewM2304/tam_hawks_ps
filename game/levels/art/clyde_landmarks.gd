extends RefCounted
## Original compressed South Portland / Carlton Place architectural interpretation.
## Reference photographs are inspection only. All generated geometry is art-only.


static func build(parent: Node3D, materials: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "ClydeLandmarks"
	root.set_meta("art_only", true)
	root.set_meta("reference_note", "Original compressed South Portland suspension and Carlton Place terrace cues")
	parent.add_child(root)
	var palette := materials.duplicate()
	palette["clyde_red"] = _tint(materials["iron"], Color("79483e"))
	palette["clyde_sandstone"] = _tint(materials["sandstone"], Color("c2b18f"))
	palette["clyde_pale_wall"] = _tint(materials["sandstone"], Color("c4c0ad"))
	var batches: Dictionary = {}
	_suspension_bridge(root, batches, palette)
	for block: Vector2 in [Vector2(-100, 96), Vector2(-1, 88), Vector2(99, 92)]:
		_terrace(root, batches, block.x, block.y, palette)
	_flush(root, batches, palette)


static func _suspension_bridge(root: Node3D, batches: Dictionary, palette: Dictionary) -> void:
	# Deck, rails and every collider remain owned by OutdoorRoutes. Portal posts
	# start 5.4m from its centre; the original deck/rail envelope is only +/-4m.
	var portal_mesh := _portal_mesh()
	for z: float in [72.0, 122.0]:
		var portal := MeshInstance3D.new()
		portal.name = "SandstonePortal"
		portal.mesh = portal_mesh
		portal.material_override = palette["clyde_sandstone"]
		portal.position = Vector3(-98, 0, z)
		root.add_child(portal)
		for side: float in [-1.0, 1.0]:
			var x := -98.0 + side * 6.2
			_box(batches, "clyde_sandstone", Vector3(x, 5.8, z), Vector3(1.6, 8.8, 1.7))
			_box(batches, "cut_stone", Vector3(x, 1.7, z), Vector3(2.0, 0.6, 2.1))
			_box(batches, "clyde_sandstone", Vector3(x, 7.0, z), Vector3(1.85, 0.22, 1.9))
		_box(batches, "clyde_sandstone", Vector3(-98, 10.6, z), Vector3(14.4, 0.65, 2.0))
		_box(batches, "cut_stone", Vector3(-98, 10.98, z), Vector3(14.8, 0.16, 2.15))
	for side: float in [-1.0, 1.0]:
		var chain_x := -98.0 + side * 4.45
		for offset: float in [-0.10, 0.10]:
			for index: int in range(32):
				var a := float(index) / 32.0
				var b := float(index + 1) / 32.0
				_beam(batches, "clyde_red", Vector3(chain_x + offset, _chain_height(a), 72 + 50 * a), Vector3(chain_x + offset, _chain_height(b), 72 + 50 * b), 0.075)
		for index: int in range(1, 25):
			var t := float(index) / 25.0
			var z := 72.0 + 50.0 * t
			_beam(batches, "clyde_red", Vector3(chain_x, _deck_height(z) + 1.05, z), Vector3(chain_x, _chain_height(t), z), 0.026)
		for index: int in range(20):
			var a := 72.0 + float(index) * 2.5
			var b := a + 2.5
			var x := -98.0 + side * 3.88
			_beam(batches, "window_frame", Vector3(x, _deck_height(a) + 0.22, a), Vector3(x, _deck_height(b) + 0.97, b), 0.035)
			_beam(batches, "window_frame", Vector3(x, _deck_height(a) + 0.97, a), Vector3(x, _deck_height(b) + 0.22, b), 0.035)
		for z: float in [82.0, 112.0]:
			var at := Vector3(-98.0 + side * 4.8, _deck_height(z), z)
			_beam(batches, "iron", at, at + Vector3.UP * 3.2, 0.045)
			_box(batches, "window_frame", at + Vector3.UP * 3.38, Vector3(0.24, 0.40, 0.24))
			_box(batches, "iron", at + Vector3.UP * 3.64, Vector3(0.34, 0.12, 0.34))


static func _chain_height(t: float) -> float:
	return 4.85 + 4.75 * pow(2.0 * t - 1.0, 2.0)


static func _deck_height(z: float) -> float:
	if z < 89.0: return lerpf(2.0, 3.4, (z - 72.0) / 17.0)
	if z > 105.0: return lerpf(3.4, 2.0, (z - 105.0) / 17.0)
	return 3.4


static func _portal_mesh() -> ArrayMesh:
	# Closed spandrel over a real arched opening. Even at its spring line the
	# underside is Y7.1, 5.1m above the board at either Y2 bridge entrance.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(24):
		var a := PI - PI * float(index) / 24.0
		var b := PI - PI * float(index + 1) / 24.0
		var inner_a := Vector3(cos(a) * 5.4, 7.1 + sin(a) * 2.7, 0)
		var inner_b := Vector3(cos(b) * 5.4, 7.1 + sin(b) * 2.7, 0)
		var top_a := Vector3(inner_a.x, 10.3, 0)
		var top_b := Vector3(inner_b.x, 10.3, 0)
		for side: float in [-1.0, 1.0]:
			var offset := Vector3(0, 0, side * 0.72)
			_quad(surface, inner_a + offset, inner_b + offset, top_b + offset, top_a + offset, Vector3(0, 0, side))
		var inward := Vector3(-cos((a + b) * 0.5), -sin((a + b) * 0.5), 0).normalized()
		_quad(surface, inner_a + Vector3(0,0,-0.72), inner_a + Vector3(0,0,0.72), inner_b + Vector3(0,0,0.72), inner_b + Vector3(0,0,-0.72), inward)
		_quad(surface, top_a + Vector3(0,0,-0.72), top_b + Vector3(0,0,-0.72), top_b + Vector3(0,0,0.72), top_a + Vector3(0,0,0.72), Vector3.UP)
	return surface.commit()


static func _terrace(root: Node3D, batches: Dictionary, centre_x: float, width: float, palette: Dictionary) -> void:
	# Joined residential bays, rather than another row of repeated fake shops.
	# Front Z145.4 is behind the existing yard and both Z130 return openings.
	_box(batches, "cut_stone", Vector3(centre_x, 2.0, 151.4), Vector3(width, 2.0, 12.0))
	_box(batches, "clyde_pale_wall", Vector3(centre_x, 8.4, 151.4), Vector3(width, 10.8, 12.0))
	for y: float in [3.08, 6.2, 9.5, 13.75]:
		_box(batches, "clyde_sandstone", Vector3(centre_x, y, 145.25), Vector3(width + 0.12, 0.20, 0.32))
	_box(batches, "clyde_sandstone", Vector3(centre_x, 13.96, 151.4), Vector3(width + 0.5, 0.28, 12.6))
	var roof := MeshInstance3D.new()
	roof.name = "JoinedSlateRoof"
	roof.mesh = _roof_mesh(width + 0.4)
	roof.material_override = palette["slate"]
	roof.position = Vector3(centre_x, 14.08, 151.4)
	root.add_child(roof)
	var bays := maxi(1, floori(width / 5.4))
	var spacing := width / float(bays)
	for index: int in range(bays):
		var x := centre_x - width * 0.5 + spacing * (float(index) + 0.5)
		for storey: int in range(3):
			var y := 4.6 + float(storey) * 3.25
			if storey == 0 and index % 2 == 0:
				_box(batches, "window_shadow", Vector3(x, 4.24, 145.34), Vector3(1.22, 2.4, 0.10))
				_box(batches, "wood", Vector3(x, 4.13, 145.26), Vector3(0.95, 2.15, 0.08))
				_box(batches, "window_frame", Vector3(x, 5.35, 145.17), Vector3(1.5, 0.22, 0.22))
				for side: float in [-1.0, 1.0]:
					_box(batches, "window_frame", Vector3(x + side * 0.66, 4.24, 145.17), Vector3(0.16, 2.4, 0.22))
				continue
			_box(batches, "window_shadow", Vector3(x, y, 145.34), Vector3(1.7, 2.15, 0.10))
			_box(batches, "window_dull", Vector3(x, y, 145.25), Vector3(1.42, 1.92, 0.08))
			for side: float in [-1.0, 1.0]:
				_box(batches, "window_frame", Vector3(x + side * 0.77, y, 145.17), Vector3(0.11, 2.08, 0.12))
				_box(batches, "window_frame", Vector3(x, y + side * 1.0, 145.17), Vector3(1.62, 0.11, 0.12))
			_box(batches, "window_frame", Vector3(x, y, 145.13), Vector3(1.5, 0.07, 0.08))
			_box(batches, "window_frame", Vector3(x, y, 145.13), Vector3(0.055, 1.95, 0.08))
			_box(batches, "clyde_sandstone", Vector3(x, y - 1.13, 145.03), Vector3(1.95, 0.16, 0.35))
		if index % 3 == 0:
			_box(batches, "clyde_sandstone", Vector3(x, 16.4, 151.4), Vector3(1.35, 1.5, 1.0))
			_box(batches, "cut_stone", Vector3(x, 17.15, 151.4), Vector3(1.65, 0.18, 1.25))
			for side: float in [-1.0, 1.0]:
				_cylinder(batches, "clyde_red", Vector3(x + side * 0.38, 17.48, 151.4), 0.12, 0.55)
	# A quiet continuous iron property edge explains the separate planted strip;
	# it sits behind every playable quay/yard path and has no riding collision.
	for x_index: int in range(ceili(width / 2.0) + 1):
		var x := centre_x - width * 0.5 + minf(float(x_index) * 2.0, width)
		_box(batches, "iron", Vector3(x, 3.2, 141.8), Vector3(0.045, 1.1, 0.045))
	_box(batches, "iron", Vector3(centre_x, 3.72, 141.8), Vector3(width, 0.055, 0.055))


static func _roof_mesh(width: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var left_front := Vector3(-width * 0.5, 0, -6.2)
	var right_front := Vector3(width * 0.5, 0, -6.2)
	var left_back := Vector3(-width * 0.5, 0, 6.2)
	var right_back := Vector3(width * 0.5, 0, 6.2)
	var left_ridge := Vector3(-width * 0.5, 2.0, 0)
	var right_ridge := Vector3(width * 0.5, 2.0, 0)
	_quad(surface, left_front, right_front, right_ridge, left_ridge, Vector3(0, 6.2, -2.0).normalized())
	_quad(surface, left_ridge, right_ridge, right_back, left_back, Vector3(0, 6.2, 2.0).normalized())
	_triangle(surface, left_front, left_ridge, left_back, Vector3.LEFT)
	_triangle(surface, right_front, right_back, right_ridge, Vector3.RIGHT)
	return surface.commit()


static func _tint(source: StandardMaterial3D, color: Color) -> StandardMaterial3D:
	var material := source.duplicate() as StandardMaterial3D
	material.albedo_color = color
	return material


static func _box(batches: Dictionary, key: String, at: Vector3, size: Vector3, rotation: Basis = Basis.IDENTITY) -> void:
	_add(batches, key, "box", Transform3D(rotation * Basis.from_scale(size), at))


static func _cylinder(batches: Dictionary, key: String, at: Vector3, radius: float, height: float) -> void:
	_add(batches, key, "cylinder", Transform3D(Basis.from_scale(Vector3(radius * 2, height, radius * 2)), at))


static func _beam(batches: Dictionary, key: String, a: Vector3, b: Vector3, radius: float) -> void:
	var direction := b - a
	if direction.length_squared() < 0.000001: return
	var axis := Vector3.UP.cross(direction.normalized())
	var rotation := Basis.IDENTITY
	if axis.length_squared() > 0.000001:
		rotation = Basis(axis.normalized(), Vector3.UP.angle_to(direction))
	elif direction.y < 0.0:
		rotation = Basis(Vector3.RIGHT, PI)
	_box(batches, key, (a + b) * 0.5, Vector3(radius * 2, direction.length(), radius * 2), rotation)


static func _add(batches: Dictionary, key: String, kind: String, transform: Transform3D) -> void:
	var batch_key := kind + ":" + key
	if not batches.has(batch_key): batches[batch_key] = {"key": key, "kind": kind, "transforms": []}
	batches[batch_key].transforms.append(transform)


static func _flush(root: Node3D, batches: Dictionary, palette: Dictionary) -> void:
	for batch_key: String in batches:
		var batch: Dictionary = batches[batch_key]
		var mesh: Mesh
		if batch.kind == "cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.height = 1.0
			cylinder.top_radius = 0.5
			cylinder.bottom_radius = 0.5
			cylinder.radial_segments = 10
			mesh = cylinder
		else:
			mesh = BoxMesh.new()
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = batch.transforms.size()
		for index: int in batch.transforms.size(): multimesh.set_instance_transform(index, batch.transforms[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Clyde_" + batch_key.replace(":", "_")
		instance.multimesh = multimesh
		instance.material_override = palette[batch.key]
		root.add_child(instance)


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	_triangle(surface, a, b, c, normal)
	_triangle(surface, a, c, d, normal)


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var vertices: Array[Vector3] = [a, b, c]
	if (b - a).cross(c - a).dot(normal) > 0.0: vertices = [a, c, b]
	for vertex: Vector3 in vertices:
		surface.set_normal(normal)
		surface.add_vertex(vertex)
