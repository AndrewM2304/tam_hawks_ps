extends RefCounted
## Original street detail with physical, grindable accessible furniture.

const BENCH_GROUPS := [
	{"id":"station_west", "position":Vector3(-127,2,28)},
	{"id":"barras_south", "position":Vector3(60,0,41.5)},
	{"id":"civic_east", "position":Vector3(29,6,-116)},
	{"id":"exchange_east", "position":Vector3(29,0,27)}]


static func build(art: Node3D, world: Node3D) -> void:
	var batches: Dictionary = {}
	# Coping follows every authored boundary segment, so connector gaps stay open.
	for body: Node in world.get_children():
		var label := String(body.get_meta("art_label", ""))
		if label not in ["BoundaryWall", "GeorgeBoundary", "CentralBoundary", "BarrasBoundary"]:
			continue
		for child: Node in body.get_children():
			if child is CollisionShape3D and child.shape is BoxShape3D:
				var size: Vector3 = child.shape.size
				art._batch_box(batches, "cut_stone", Vector3(size.x + 0.12, 0.12, size.z + 0.12), body.position + Vector3.UP * 0.7)
	for at: Vector3 in [Vector3(-31.5, 0.035, 10), Vector3(31.5, 0.035, -6),
			Vector3(-31, 0.035, -110), Vector3(31, 0.035, -96),
			Vector3(-124, 0.035, 30), Vector3(-51, 0.035, -10),
			Vector3(124, 0.035, 29), Vector3(51, 0.035, -10)]:
		var height: float = world.get_ground_height(at)
		if not is_nan(height):
			_drain(art, batches, Vector3(at.x, height + 0.035, at.z))
	# These seats are inside the playable floors. Their original visible slats
	# now have matching support and finite front-seat/backrest grind tracks.
	# Barras sits clear of the bank island instead of passing through its deck.
	for group: Dictionary in BENCH_GROUPS:
		var at: Vector3 = group.position
		_bench(art, batches, at)
		_bench_collision(world, at, group.id)
		art._cylinder(art, at + Vector3(2.5, 0.56, 0), 0.34, 1.12, art.materials["iron"])
		art._cylinder(art, at + Vector3(2.5, 1.13, 0), 0.39, 0.08, art.materials["slate"])
		art._batch_box(batches, "brass", Vector3(0.27, 0.11, 0.06), at + Vector3(2.5, 0.82, 0.34))
		_bin_collision(world, at + Vector3(2.5,0,0), group.id)
	art._flush_batches(art, batches)


static func _drain(art: Node3D, batches: Dictionary, at: Vector3) -> void:
	art._batch_box(batches, "window_shadow", Vector3(0.95, 0.025, 0.5), at)
	for side: float in [-1.0, 1.0]:
		art._batch_box(batches, "iron", Vector3(1.04, 0.035, 0.045), at + Vector3(0, 0.005, side * 0.26))
	for index: int in range(11):
		art._batch_box(batches, "iron", Vector3(0.04, 0.035, 0.5), at + Vector3(-0.46 + index * 0.092, 0.008, 0))


static func _bench(art: Node3D, batches: Dictionary, at: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		art._batch_box(batches, "iron", Vector3(0.12, 0.47, 0.55), at + Vector3(side * 1.1, 0.24, 0))
		art._batch_box(batches, "iron", Vector3(0.09, 0.9, 0.09), at + Vector3(side * 1.1, 0.46, -0.3))
	for slat: int in range(4):
		art._batch_box(batches, "wood", Vector3(2.7, 0.07, 0.12), at + Vector3(0, 0.51, -0.22 + slat * 0.14))
	for slat: int in range(3):
		art._batch_box(batches, "wood", Vector3(2.7, 0.1, 0.075), at + Vector3(0, 0.72 + slat * 0.14, -0.3))


static func _bench_collision(world: Node3D, at: Vector3, id: String) -> void:
	var body := StaticBody3D.new()
	body.name = "StreetBench_" + id
	body.position = at
	body.set_meta("art_label", "StreetBench")
	body.set_meta("street_furniture_id", id)
	body.set_meta("surface_audio", "wood")
	world.add_child(body)
	# Tiny slat gaps are narrower than a wheel/capsule, so shared support boxes
	# follow the outer faces without creating snagging seams between slats.
	_collision_box(body, Vector3(0,0.51,-0.01), Vector3(2.7,0.07,0.54))
	_collision_box(body, Vector3(0,0.86,-0.3), Vector3(2.7,0.38,0.075))
	for side: float in [-1.0,1.0]:
		_collision_box(body, Vector3(side*1.1,0.24,0), Vector3(0.12,0.47,0.55))
		_collision_box(body, Vector3(side*1.1,0.46,-0.3), Vector3(0.09,0.9,0.09))
	var ids: Array[String] = []
	for edge: Dictionary in [{"name":"Seat", "height":0.565, "z":0.26}, {"name":"Back", "height":1.07, "z":-0.3}]:
		var track := Node3D.new()
		var track_id := "Grind_Bench_Street_" + id + "_" + str(edge.name)
		track.name = track_id
		track.add_to_group("grind_rails")
		track.set_meta("grind_id", track_id)
		track.set_meta("grind_kind", "ledge")
		track.set_meta("grind_points", PackedVector3Array([
			Vector3(-1.35,edge.height,edge.z), Vector3(1.35,edge.height,edge.z)]))
		body.add_child(track)
		world._rail_authors.append(track)
		ids.append(track_id)
	body.set_meta("authored_grind_ids", ids)
	body.set_meta("audit_capture_ids", ids.duplicate())
	body.add_to_group("physical_street_benches")


static func _bin_collision(world: Node3D, at: Vector3, id: String) -> void:
	var body := StaticBody3D.new()
	body.name = "StreetLitterBin_" + id
	body.position = at
	body.set_meta("art_label", "StreetLitterBin")
	body.set_meta("street_furniture_id", id)
	body.set_meta("surface_audio", "metal")
	body.set_meta("grind_exclusion_reason", "upright circular litter container; lid diameter 0.78m, below a useful finite ledge run")
	world.add_child(body)
	for dimensions: Vector3 in [Vector3(0.34,1.12,0.56), Vector3(0.39,0.08,1.13)]:
		var shape := CylinderShape3D.new()
		shape.radius = dimensions.x
		shape.height = dimensions.y
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position.y = dimensions.z
		body.add_child(collision)
	body.add_to_group("physical_street_bins")


static func _collision_box(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = at
	body.add_child(collision)
