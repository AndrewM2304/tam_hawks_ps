extends RefCounted
## Original edge detail. Reachable bench solids match the existing visible slats
## and frames; the decorative batches, triggers and route layout stay unchanged.


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
	# These benches sit inside supported playable floors. Their former art-only
	# construction let the rider pass through apparently solid street furniture.
	for at: Vector3 in [Vector3(-127,2,28), Vector3(60,0,36), Vector3(29,6,-116), Vector3(29,0,27)]:
		_bench(art, batches, at)
		_bench_collision(world,at)
		art._cylinder(art, at + Vector3(2.5, 0.56, 0), 0.34, 1.12, art.materials["iron"])
		art._cylinder(art, at + Vector3(2.5, 1.13, 0), 0.39, 0.08, art.materials["slate"])
		art._batch_box(batches, "brass", Vector3(0.27, 0.11, 0.06), at + Vector3(2.5, 0.82, 0.34))
	art._flush_batches(art, batches)


static func _bench_collision(world: Node3D,at: Vector3) -> void:
	var seat := _bench_body(world,"StreetBenchSeat",at)
	# Metadata describes the outer slat envelope for optional ledge authoring;
	# physical contact still uses the four actual narrow planks, including gaps.
	seat.set_meta("skate_edge_box_size",Vector3(2.7,0.07,0.54))
	seat.set_meta("skate_edge_box_center",Vector3(0,0.51,-0.01))
	for slat: int in range(4):
		_collision_box(seat,Vector3(2.7,0.07,0.12),Vector3(0,0.51,-0.22+slat*0.14))
	var back := _bench_body(world,"StreetBenchBack",at)
	back.set_meta("skate_edge_box_size",Vector3(2.7,0.10,0.075))
	back.set_meta("skate_edge_box_center",Vector3(0,1.0,-0.3))
	for slat: int in range(3):
		_collision_box(back,Vector3(2.7,0.10,0.075),Vector3(0,0.72+slat*0.14,-0.3))
	var frame := _bench_body(world,"StreetBenchFrame",at)
	for side: float in [-1.0,1.0]:
		_collision_box(frame,Vector3(0.12,0.47,0.55),Vector3(side*1.1,0.24,0))
		_collision_box(frame,Vector3(0.09,0.9,0.09),Vector3(side*1.1,0.46,-0.3))


static func _bench_body(world: Node3D,id: String,at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name=id
	body.position=at
	body.collision_layer=1
	body.collision_mask=0
	body.set_meta("art_label",id)
	body.set_meta("surface_audio","wood" if id!="StreetBenchFrame" else "metal")
	body.add_to_group("street_bench_solids")
	world.add_child(body)
	return body


static func _collision_box(body: StaticBody3D,size: Vector3,at: Vector3) -> void:
	var shape:=BoxShape3D.new()
	shape.size=size
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	collision.position=at
	body.add_child(collision)


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
