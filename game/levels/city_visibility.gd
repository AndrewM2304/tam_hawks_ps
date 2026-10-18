extends RefCounted
## Explicit solid-wall occluders. Never infer solids from a whole district AABB.

const WALL_MARK := &"tam_closed_facade_wall"
const BUILT_MARK := &"tam_wall_occluder_built"
const INSET := 0.10


static func register_closed_facade(body: Node3D) -> void:
	# Caller promises a permanently closed, static facade; open porticos, halls,
	# canopies and bridges must never use this registration.
	body.set_meta(WALL_MARK, true)


static func build(world: Node3D) -> int:
	var count := 0
	for body: Node in world.find_children("*", "Node3D", true, false):
		if not bool(body.get_meta(WALL_MARK, false)) or bool(body.get_meta(BUILT_MARK, false)):
			continue
		for child: Node in body.get_children():
			if not child is MeshInstance3D or not child.is_visible_in_tree() or not child.mesh is BoxMesh:
				continue
			if child.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
				continue # A shadow approximation is not an actual visible wall.
			var material := child.material_override as BaseMaterial3D
			if material == null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			var size: Vector3 = child.mesh.size - Vector3.ONE * (INSET * 2.0)
			if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
				continue
			var box := BoxOccluder3D.new()
			box.size = size
			var occluder := OccluderInstance3D.new()
			occluder.name = "ClosedFacadeOccluder"
			occluder.occluder = box
			occluder.transform = child.transform
			body.add_child(occluder)
			body.set_meta(BUILT_MARK, true)
			count += 1
			break
	return count
