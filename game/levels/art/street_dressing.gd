extends RefCounted
## Original decorative edge detail. No collision bodies, triggers or route changes.


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
		_drain(art, batches, at)
	# Street furniture occupies the nonplayable strip behind the outside walls,
	# between wall and facade. It cannot clutter or fake collision in the routes.
	for at: Vector3 in [Vector3(-130.5, 0.0, 28), Vector3(130.5, 0.0, 27), Vector3(70, 0.0, 44.0), Vector3(-70, 0.0, 44.0)]:
		_bench(art, batches, at)
		art._cylinder(art, at + Vector3(2.5, 0.56, 0), 0.34, 1.12, art.materials["iron"])
		art._cylinder(art, at + Vector3(2.5, 1.13, 0), 0.39, 0.08, art.materials["slate"])
		art._batch_box(batches, "brass", Vector3(0.27, 0.11, 0.06), at + Vector3(2.5, 0.82, 0.34))
	# Thin visible sidewalk strips remain on the far side of existing walls.
	for x: float in [-130.5, 130.5]:
		art._batch_box(batches, "path", Vector3(4.4, 0.12, 80), Vector3(x, 0.02, 0))
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
