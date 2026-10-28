extends RefCounted
## Native rider contact with the existing rail shapes, not only guide metadata.
const World = preload("res://game/levels/glasgow_square.gd")
const Skater = preload("res://game/player/skater.gd")
const Setup = preload("res://game/core/input_setup.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	_release()
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var world := World.new()
	# Main forwards this ordinary default before world construction. Include
	# the pond and enclosed station rather than testing only the old inventory.
	world.set_meta("pt24_design_preview", true)
	viewport.add_child(world)
	var rider := Skater.new()
	rider.spawn_position = Vector3(0, 1000, 0)
	world.add_child(rider)
	rider.set_physics_process(false)
	rider.set_grind_lines(world.get_grind_lines())
	await _frames(tree, 2)

	var rail_bodies := 0
	var rail_shapes := 0
	var missing: Array[String] = []
	for body: StaticBody3D in world.find_children("*", "StaticBody3D", true, false):
		if (body.collision_layer & 2) == 0:
			continue
		rail_bodies += 1
		var active := 0
		for node: Node in body.get_children():
			if node is CollisionShape3D and node.shape != null and not node.disabled:
				active += 1
				rail_shapes += 1
		if (body.collision_layer & 1) == 0 or active == 0:
			missing.append(String(world.get_path_to(body)))
	check.call(rail_bodies >= 20 and rail_shapes >= rail_bodies and missing.is_empty(),
		"rail solidity: every ordinary-world rail-query body has active native shapes on the rider's world layer: " + str(missing))
	check.call(rider.collision_mask == (1 | 8) and (rider.collision_mask & rider.collision_layer) == 0,
		"rail solidity: ordinary rider mask meets real solids without colliding with the shared player layer")

	var exchange := world.get_node("Grind_Rail_Exchange/RailProp") as StaticBody3D
	var flatbar := world.find_child("Grind_Park_StreetFlatbar", true, false) as StaticBody3D
	var pond := world.find_child("PondPerimeterRail", true, false) as StaticBody3D
	for pair: Array in [["Exchange box rail", exchange], ["park cylinder rail", flatbar], ["pond perimeter", pond]]:
		var body: StaticBody3D = pair[1]
		var bar := _bar(body)
		check.call(not bar.is_empty() and _ray_hits(rider, body, bar) and _capsule_hits(rider, body, bar),
			"rail solidity: native world-layer ray and actual rider capsule both stop at " + str(pair[0]))
		if not bar.is_empty() and body != pond:
			check.call(not _capsule_hits(rider, body, bar, float(bar.half_length) + 0.5),
				"rail solidity: the rider clears the real finite end of " + str(pair[0]))

	# Reproduce the former pass-through with the same actual shape and rider.
	# Restore it before physical input; no production collision policy changes.
	var bar := _bar(exchange)
	var solid_layer := exchange.collision_layer
	exchange.collision_layer = 2
	await _frames(tree, 1)
	var ghost_missed := not _ray_hits(rider, exchange, bar) and not _capsule_hits(rider, exchange, bar)
	exchange.collision_layer = solid_layer
	await _frames(tree, 1)
	check.call(ghost_missed and _ray_hits(rider, exchange, bar) and _capsule_hits(rider, exchange, bar),
		"rail solidity: unchanged shape reproduces the old ignored-layer failure and restoring world contact fixes it")

	var entries: Array[String] = []
	rider.trick_performed.connect(func(_label: String, _points: int): entries.append(rider.last_trick_id))
	rider.spawn_position = Vector3(13.2, 0.04, 9)
	rider.reset_skater()
	rider.rotation.y = PI / 2.0
	rider.set_physics_process(true)
	await _frames(tree, 4)
	var start: Vector3 = rider.global_position
	var touched := false
	Input.action_press("push")
	for tick: int in 100:
		await _frames(tree, 1)
		for index: int in rider.get_slide_collision_count():
			var contact := rider.get_slide_collision(index)
			for hit: int in contact.get_collision_count():
				touched = touched or contact.get_collider(hit) == exchange
	_release()
	check.call(touched and rider.global_position.x > 12.28 and rider.global_position.x < start.x - 0.15,
		"rail solidity: real held Push approaches the teaching rail and cannot skate through its bar")
	check.call(rider.is_on_floor() and not rider.bailing and not rider.grinding and entries.is_empty(),
		"rail solidity: a blocked ordinary approach retains native floor support without an unrequested grind or trick")
	print("RAIL_SOLIDITY ", {"bodies": rail_bodies, "shapes": rail_shapes, "missing": missing,
		"old_layer_missed": ghost_missed, "touched": touched, "from": start, "at": rider.global_position, "entries": entries})
	rider.set_physics_process(false)
	viewport.queue_free()
	await tree.process_frame


static func _bar(body: StaticBody3D) -> Dictionary:
	if body == null:
		return {}
	for child: Node in body.get_children():
		if not child is CollisionShape3D or child.disabled or child.shape == null:
			continue
		if child.shape is BoxShape3D and child.shape.size.z > 0.5:
			var along: Vector3 = child.global_basis.z.normalized()
			return {"center": child.global_position, "along": along,
				"side": Vector3.UP.cross(along).normalized(), "half_length": child.shape.size.z * 0.5}
		if child.shape is CylinderShape3D and child.shape.height > 0.5:
			var along: Vector3 = child.global_basis.y.normalized()
			return {"center": child.global_position, "along": along,
				"side": Vector3.UP.cross(along).normalized(), "half_length": child.shape.height * 0.5}
	return {}


static func _ray_hits(rider: CharacterBody3D, body: StaticBody3D, bar: Dictionary) -> bool:
	if bar.is_empty():
		return false
	var center: Vector3 = bar.center
	var side: Vector3 = bar.side
	var query := PhysicsRayQueryParameters3D.create(center + side * 0.4, center - side * 0.4, 1)
	query.exclude = [rider.get_rid()]
	var hit := rider.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == body


static func _capsule_hits(rider: CharacterBody3D, body: StaticBody3D, bar: Dictionary, along_offset: float = 0.0) -> bool:
	if bar.is_empty():
		return false
	var center: Vector3 = bar.center + Vector3(bar.along) * along_offset
	var side: Vector3 = bar.side
	var frame := Transform3D(Basis.IDENTITY, center + side * 0.9 - Vector3.UP * 0.35)
	var contact := KinematicCollision3D.new()
	if not rider.test_move(frame, -side * 1.8, contact, 0.001, false, 16):
		return false
	for index: int in contact.get_collision_count():
		if contact.get_collider(index) == body:
			return true
	return false


static func _frames(tree: SceneTree, count: int) -> void:
	for index: int in count:
		await tree.physics_frame
		await tree.process_frame


static func _release() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
