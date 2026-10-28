extends RefCounted
## Independent production-world invariants. Native distance selection is tested
## separately by run_rendered(), which requires real post-draw frames.

const World = preload("res://game/levels/glasgow_square.gd")
const Bay = preload("res://game/levels/art/facade_bay.gd")
const Batches = preload("res://game/levels/static_batches.gd")
const EPS := 0.0001


static func run(tree: SceneTree, check: Callable) -> void:
	var baseline := _world(tree, false)
	await tree.physics_frame
	await tree.process_frame
	var original := _target(baseline)
	check.call(original != null and _marked(baseline).is_empty(),
		"facade bay: explicit disable preserves the original selected building")
	if original == null:
		baseline.free()
		return
	var collision := _collisions(baseline)
	var routes := var_to_bytes(baseline.get_route_definitions())
	var rails := _rails(baseline)
	var support := _support(baseline)
	var old_labels := _labels(original)
	var old_records := _emitted_records(original)
	var original_visual: MeshInstance3D = original.get_node("Facade").get_child(1)
	var original_frame := original_visual.transform
	var original_material := original_visual.material_override
	var original_occluders: int = baseline.solid_wall_occluders
	baseline.free()
	await tree.physics_frame
	await tree.process_frame
	var world := _world(tree, true)
	await tree.physics_frame
	await tree.process_frame
	var building := _target(world)
	var marked := _marked(world)
	check.call(building != null and marked.size() == 1 and marked[0] == building,
		"facade bay: exactly the fitted west middle Exchange building is enabled")
	if building == null or not building.has_node("GlasgowBayLOD"):
		check.call(false, "facade bay: live fitted assets installed successfully")
		world.free()
		return
	check.call(collision == _collisions(world),
		"facade bay: every actual collision shape, body layer and world transform is unchanged")
	check.call(routes == var_to_bytes(world.get_route_definitions()) and rails == _rails(world),
		"facade bay: actual navigation routes and grind points remain identical")
	check.call(support == _support(world) and support[0] and support[1] and support[2],
		"facade bay: physical entry threshold, turning ledge and lower bypass retain support/clearance")
	_check_shell(building, check)
	_check_shadows(building, original_frame, original_material, check)
	check.call(original_occluders == 23 and world.solid_wall_occluders == 22
		and not building.get_node("Facade").has_node("ClosedFacadeOccluder"),
		"facade bay: invisible shadow mass is excluded from actual visible-wall occluder candidates")
	_check_front(building, old_records, old_labels, check)
	_check_lods(building, check)
	world.free()
	await tree.process_frame
	# A compact second fixture proves composed parents without constructing a
	# second transformed city (whose style seeds deliberately use world space).
	var fixture := Node3D.new()
	fixture.transform = Transform3D(Basis(Vector3.UP, 0.43), Vector3(71, 3, -27))
	tree.root.add_child(fixture)
	var transformed := _bare_building(fixture)
	transformed.transform = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(-41, 0, 0))
	var original_mesh: Mesh = transformed.get_node("Facade").get_child(1).mesh
	var installed := Bay.install(transformed, transformed.get_node("Facade"))
	check.call(installed and transformed.get_node("GlasgowBayLOD").global_transform.is_equal_approx(
		fixture.global_transform * transformed.transform * Transform3D(Basis.IDENTITY, Vector3(-5.75, 0, 6))),
		"facade bay: fitted placement composes actual rotated/translated author parents")
	check.call(installed and transformed.get_node("Facade/BuildingMassShadow").mesh == original_mesh,
		"facade bay: mass shadow reuses the original closed mesh resource without duplication")
	check.call(not transformed.has_meta(Bay.AUDIT_RECORDS),
		"facade bay: ordinary runtime does not retain construction audit records")
	fixture.free()


static func _world(tree: SceneTree, enabled: bool) -> Node3D:
	var world := World.new()
	world.set_meta(&"facade_bay_enabled", enabled)
	world.set_meta(&"facade_bay_audit", true)
	world.set_meta(&"render_budget_probe_baseline", true)
	tree.root.add_child(world)
	return world


static func _target(world: Node3D) -> Node3D:
	for child: Node in world.get_children():
		if child is Node3D and child.position.is_equal_approx(Vector3(-41, 0, 0)) and child.has_node("Facade"):
			return child
	return null


static func _marked(world: Node) -> Array[Node]:
	var result: Array[Node] = []
	for node: Node in world.find_children("*", "Node", true, false):
		if bool(node.get_meta(Bay.META, false)): result.append(node)
	return result


static func _collisions(world: Node3D) -> PackedStringArray:
	var result := PackedStringArray()
	for node: Node in world.find_children("*", "CollisionShape3D", true, false):
		var body: Node = node.get_parent()
		var shape: Shape3D = node.shape
		var properties: Dictionary = {}
		for property: Dictionary in shape.get_property_list():
			var key := String(property.name)
			if int(property.usage) & PROPERTY_USAGE_STORAGE and key not in ["resource_name", "resource_path", "resource_local_to_scene", "script"]:
				properties[key] = shape.get(key)
		result.append(var_to_str([node.global_transform, node.disabled, body.get_class(),
			body.collision_layer, body.collision_mask, shape.get_class(), properties]))
	result.sort()
	return result


static func _rails(world: Node3D) -> PackedStringArray:
	var result := PackedStringArray()
	for line: RefCounted in world.get_grind_lines():
		result.append(var_to_str([line.id, line.kind, line.points, line.is_valid]))
	result.sort()
	return result


static func _support(world: Node3D) -> Array:
	var space := world.get_world_3d().direct_space_state
	var threshold := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-34.7, 3, 3.75), Vector3(-34.7, -1, 3.75), 1))
	var ledge_from := Vector3(-27.4, 3, 3.75)
	var ledge_to := Vector3(-27.4, -1, 3.75)
	var crown := space.intersect_ray(PhysicsRayQueryParameters3D.create(ledge_from, ledge_to, 1))
	var rail := space.intersect_ray(PhysicsRayQueryParameters3D.create(ledge_from, ledge_to, 2))
	var crown_body := crown.get("collider") as StaticBody3D
	var crown_valid: bool = crown_body != null and crown_body.collision_layer & 3 == 3 \
		and "Grind_Ledge_ExchangeShops" in crown_body.get_meta("authored_grind_ids", []) \
		and rail.get("rid") == crown.get("rid") \
		and Vector3(rail.get("position", Vector3.INF)).distance_to(crown.position) <= EPS \
		and absf(crown.position.y - 0.97) < EPS
	# This is the unchanged masonry-support witness, below the newly solid
	# authored steel. Authenticate that exact native crown before skipping it.
	var ledge_query := PhysicsRayQueryParameters3D.create(ledge_from, ledge_to, 1)
	if crown_valid: ledge_query.exclude = [crown_body.get_rid()]
	var ledge := space.intersect_ray(ledge_query)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = Vector3(-22, 0.98, 0.3)
	query.motion = Vector3(0, 0, 8.2)
	query.collision_mask = 1
	query.margin = 0.01
	var sweep := space.cast_motion(query)
	return [not threshold.is_empty() and absf(threshold.position.y - 0.53) < 0.01,
		crown_valid and not ledge.is_empty() and absf(ledge.position.y - 0.82) < 0.01,
		sweep.size() == 2 and sweep[0] >= 0.9999]


static func _check_shell(building: Node3D, check: Callable) -> void:
	var wall: StaticBody3D = building.get_node("Facade")
	var collider: CollisionShape3D = wall.get_child(0)
	var visual: MeshInstance3D = wall.get_child(1)
	check.call(collider.shape is BoxShape3D and collider.shape.size.is_equal_approx(Vector3(30, 16, 12))
		and visual.mesh is ArrayMesh and visual.mesh.get_aabb().is_equal_approx(AABB(Vector3(-15, -8, -6), Vector3(30, 16, 12))),
		"facade bay: front-cut visual keeps the original complete box collider and outer bounds")
	var faces := visual.mesh.get_faces()
	var front_area := 0.0
	var interior_area := 0.0
	var remaining_area := 0.0
	for index: int in range(0, faces.size(), 3):
		var a: Vector3 = faces[index]
		var b: Vector3 = faces[index + 1]
		var c: Vector3 = faces[index + 2]
		var area := (b - a).cross(c - a).length() * 0.5
		if absf(a.z - 6) < EPS and absf(b.z - 6) < EPS and absf(c.z - 6) < EPS:
			front_area += area
			var polygon := PackedVector2Array([Vector2(a.x, a.y), Vector2(b.x, b.y), Vector2(c.x, c.y)])
			polygon = _clip_x(_clip_x(polygon, -9.0, true), -2.5, false)
			interior_area += _polygon_area(polygon)
		else:
			remaining_area += area
	check.call(absf(front_area - 376.0) < 0.001 and interior_area < 0.00001,
		"facade bay: actual front triangles exclude the entire 6.5m strip, including crossing triangles")
	check.call(absf(remaining_area - (30.0 * 16.0 + 2.0 * 12.0 * 16.0 + 2.0 * 30.0 * 12.0)) < 0.001,
		"facade bay: shell preserves complete rear, side, top and bottom surface areas")


static func _clip_x(polygon: PackedVector2Array, edge: float, keep_right: bool) -> PackedVector2Array:
	var output := PackedVector2Array()
	if polygon.is_empty(): return output
	var previous := polygon[-1]
	var previous_inside := previous.x >= edge if keep_right else previous.x <= edge
	for current: Vector2 in polygon:
		var inside := current.x >= edge if keep_right else current.x <= edge
		if inside != previous_inside:
			output.append(previous.lerp(current, (edge - previous.x) / (current.x - previous.x)))
		if inside: output.append(current)
		previous = current
		previous_inside = inside
	return output


static func _check_shadows(building: Node3D, original_frame: Transform3D, original_material: Material, check: Callable) -> void:
	var wall: Node3D = building.get_node("Facade")
	var shell: MeshInstance3D = wall.get_child(1)
	var proxies: Array[MeshInstance3D] = []
	for node: Node in wall.get_children():
		if node is MeshInstance3D and node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			proxies.append(node)
	var valid_mass := proxies.size() == 1
	if valid_mass:
		var mass := proxies[0]
		valid_mass = mass.name == &"BuildingMassShadow" and mass.mesh is BoxMesh and mass.mesh.size.is_equal_approx(Vector3(30, 16, 12)) and mass.mesh.get_faces().size() == 36 and mass.transform.is_equal_approx(original_frame) and mass.material_override == original_material and mass.material_override == shell.material_override and mass.is_visible_in_tree()
	check.call(valid_mass, "facade bay: exactly one cheap closed original box casts only the original building-mass shadow at its unchanged transform/material")
	var details_off := shell.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var receives: bool = shell.material_override is BaseMaterial3D and not shell.material_override.disable_receive_shadows
	for node: Node in building.get_node("GlasgowBayLOD").get_children():
		details_off = details_off and node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for slot: int in range(node.mesh.get_surface_count()):
			var material := node.get_active_material(slot) as BaseMaterial3D
			receives = receives and material != null and not material.disable_receive_shadows
	check.call(details_off and receives,
		"facade bay: cut shell and all detailed native LODs receive shadows without duplicate detailed shadow submissions")


static func _polygon_area(polygon: PackedVector2Array) -> float:
	var twice := 0.0
	for index: int in range(polygon.size()):
		twice += polygon[index].cross(polygon[(index + 1) % polygon.size()])
	return absf(twice) * 0.5


static func _check_front(building: Node3D, old_records: Array, old_labels: Array, check: Callable) -> void:
	var report: Dictionary = building.get_meta(Bay.REPORT, {})
	var records: Array = building.get_meta(Bay.AUDIT_RECORDS, [])
	var excludes_strip := not records.is_empty()
	var no_window_fragments := true
	for record: Dictionary in records:
		# The actual author primitives use a unit cube/triangular prism. All
		# eight transformed corners are considered, rather than just centres.
		var frame: Transform3D = record.transform
		var bounds := frame * AABB(Vector3.ONE * -0.5, Vector3.ONE)
		if bounds.position.x < -2.5 - EPS and bounds.end.x > -9.0 + EPS:
			excludes_strip = false
		if frame.origin.y > 4.0 and frame.origin.y < 13.5 and bounds.size.x < 3.0:
			for center: float in [-9.4666667, -6.3111111, -3.1555556]:
				if absf(frame.origin.x - center) < 1.1: no_window_fragments = false
	check.call(excludes_strip, "facade bay: every actual filtered front primitive has its full transformed bounds outside the strip")
	check.call(report.get("omitted_window_groups", 0) == 9 and no_window_fragments,
		"facade bay: all nine crossing window groups are absent, including their outside-strip fragments")
	check.call(report.get("omitted_shop_bays", 0) == 1 and report.get("clipped_records", 0) > 0
		and report.get("baseline_front_records", 0) > records.size(),
		"facade bay: one complete shop bay is removed and crossing continuous pieces are clipped")
	var current := _emitted_records(building)
	check.call(_has_box(old_records, Vector3(-3.75, 1.825, 6.19), Vector3(1.05, 2.55, 0.17))
		and not _has_box(current, Vector3(-3.75, 1.825, 6.19), Vector3(1.05, 2.55, 0.17)),
		"facade bay: the old selected raised procedural door is actually removed")
	check.call(_has_box(current, Vector3(-9.59, 1.825, 6.19), Vector3(1.05, 2.55, 0.17))
		and _has_box(current, Vector3(2.09, 1.62, 6.19), Vector3(1.05, 2.55, 0.17)),
		"facade bay: adjacent real procedural doors remain with their original individual elevations")
	var closure := AABB(Vector3(-2.5, 0.2, 5.98), Vector3(0.12, 3.1, 0.66))
	var old_covers := _covers(old_records, closure)
	var new_covers := _covers(current, closure)
	var neighbour_paint: Material
	for record: Dictionary in current:
		var bounds: AABB = record.bounds
		if bounds.get_center().distance_to(Vector3(2.09, 1.62, 6.19)) < 0.001 and bounds.size.distance_to(Vector3(1.05, 2.55, 0.17)) < 0.001:
			neighbour_paint = record.material
	var closed_opaque := false
	if new_covers.size() == 1:
		var material := new_covers[0].material as StandardMaterial3D
		closed_opaque = material != null and material == neighbour_paint and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and new_covers[0].bounds.position.x >= -2.5 - EPS
	check.call(old_covers.is_empty() and closed_opaque,
		"facade bay: one actual opaque neighbour jamb seals the full exposed display edge using its existing shared paint")
	var labels := _labels(building)
	var old_identity := ""
	for label: Dictionary in old_labels:
		if absf(label.position.x + 5.84) < 0.01: old_identity = label.text
	var matching := 0
	for label: Dictionary in labels:
		if label.text == old_identity and label.position.is_equal_approx(Vector3(-5.75, 3.25, 6.4)): matching += 1
	check.call(not old_identity.is_empty() and labels.size() == old_labels.size() and matching == 1,
		"facade bay: the original shop identity is retained exactly once on the fitted fascia")


static func _emitted_records(building: Node3D) -> Array:
	var records: Array = []
	for node: Node in building.find_children("*", "MultiMeshInstance3D", true, false):
		var frames := Batches.authored_transforms(node)
		for index: int in range(node.multimesh.instance_count):
			var frame: Transform3D = frames[index] if index < frames.size() else node.multimesh.get_instance_transform(index)
			records.append({"bounds":building.global_transform.affine_inverse() * node.global_transform * frame * node.multimesh.mesh.get_aabb(), "material":node.material_override})
	return records


static func _covers(records: Array, volume: AABB) -> Array:
	var result: Array = []
	for record: Dictionary in records:
		var bounds: AABB = record.bounds
		if bounds.grow(EPS).encloses(volume): result.append(record)
	return result


static func _has_box(records: Array, center: Vector3, size: Vector3) -> bool:
	for record: Dictionary in records:
		var bounds: AABB = record.bounds
		if bounds.get_center().distance_to(center) < 0.001 and bounds.size.distance_to(size) < 0.001: return true
	return false


static func _labels(building: Node3D) -> Array:
	var labels: Array = []
	for node: Node in building.find_children("*", "Label3D", true, false):
		labels.append({"text":node.text, "position":building.to_local(node.global_position)})
	return labels


static func _check_lods(building: Node3D, check: Callable) -> void:
	var holder: Node3D = building.get_node("GlasgowBayLOD")
	var near: MeshInstance3D = holder.get_node("Near")
	var mid: MeshInstance3D = holder.get_node("Mid")
	var far: MeshInstance3D = holder.get_node("Far")
	check.call(holder.position.is_equal_approx(Vector3(-5.75, 0, 6)) and holder.scale.is_equal_approx(Vector3.ONE)
		and holder.get_child_count() == 3 and near.transform == Transform3D.IDENTITY
		and mid.transform == near.transform and far.transform == near.transform,
		"facade bay: exactly three native MeshInstance levels share unscaled metre placement")
	check.call(near.get_node(near.visibility_parent) == mid and mid.get_node(mid.visibility_parent) == far
		and far.visibility_parent.is_empty() and mid.visibility_range_begin == 25.0
		and mid.visibility_range_begin_margin == 4.0 and far.visibility_range_begin == 80.0
		and far.visibility_range_begin_margin == 6.0,
		"facade bay: actual native dependency chain and both hysteresis margins are configured")
	var shared := true
	var opaque := true
	var bounds := true
	var texture_ids: Dictionary = {}
	var triangles_by_level := [9864, 3544, 648]
	var levels: Array[MeshInstance3D] = [near, mid, far]
	for index: int in range(levels.size()):
		var level := levels[index]
		var triangles := level.mesh.get_faces().size() / 3
		check.call(level.mesh.get_surface_count() == 4 and triangles == triangles_by_level[index],
			"facade bay: four fitted material surfaces and authored triangle budget " + String(level.name))
		bounds = bounds and level.mesh.get_aabb().is_equal_approx(near.mesh.get_aabb())
		check.call(level.visibility_range_end == 0.0 and level.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED,
			"facade bay: hard native stage has no alpha fade or premature end " + String(level.name))
		var imported := ConfigFile.new()
		check.call(imported.load(Bay.MESH_ROOT + "glasgow_bay_" + String(level.name).to_lower() + ".glb.import") == OK
			and imported.get_value("params", "meshes/generate_lods", true) == false,
			"facade bay: explicit authored stage has automatic import LODs disabled " + String(level.name))
		for slot: int in range(4):
			var material := level.get_surface_override_material(slot) as StandardMaterial3D
			shared = shared and material != null and material == near.get_surface_override_material(slot)
			if material == null: continue
			opaque = opaque and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
			_collect_textures(material, texture_ids)
			# Placeholder GLB materials are harmless; embedded texture resources
			# remain resident even when overridden and must also be counted.
			_collect_textures(level.mesh.surface_get_material(slot), texture_ids)
	check.call(shared and opaque, "facade bay: all levels share the same four live opaque material resources")
	check.call(bounds and near.mesh.get_aabb().position.distance_to(Vector3(-3.25, 0, -0.5)) < 0.001
		and near.mesh.get_aabb().end.distance_to(Vector3(3.25, 16, 0.36)) < 0.001,
		"facade bay: near/mid/far use the same actual fitted bounds for native selection")
	var correct_textures := texture_ids.size() == 4
	for texture: Texture2D in texture_ids.values():
		correct_textures = correct_textures and texture.get_width() == 1024 and texture.get_height() == 1024
	check.call(correct_textures, "facade bay: active and imported materials retain only four shared 1024px maps")
	var stone := near.get_surface_override_material(0) as StandardMaterial3D
	check.call(stone != null and stone.normal_enabled and stone.normal_texture != null
		and stone.normal_scale == 1.0 and stone.roughness_texture != null
		and stone.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN,
		"facade bay: actual sandstone uses the authored normal strength and ORM green roughness")
	var threshold_area := 0.0
	var faces := near.mesh.get_faces()
	for index: int in range(0, faces.size(), 3):
		var at_threshold := true
		for corner: int in range(3):
			var at: Vector3 = faces[index + corner]
			at_threshold = at_threshold and absf(at.y - 0.53) < EPS and at.x > 1.399 and at.x < 2.601 and at.z > -0.226 and at.z < 0.276
		if at_threshold:
			threshold_area += (faces[index + 1] - faces[index]).cross(faces[index + 2] - faces[index]).length() * 0.5
	check.call(threshold_area > 0.1 and absf((holder.global_transform * Vector3(2, 0.53, 0.025)).y - 0.53) < EPS,
		"facade bay: actual fitted threshold triangles meet the 0.53m landing without a second door lift")


static func _collect_textures(resource: Resource, output: Dictionary) -> void:
	if resource == null: return
	for property: Dictionary in resource.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var value: Variant = resource.get(property.name)
		if value is Texture2D: output[value.get_instance_id()] = value


static func _bare_building(parent: Node3D) -> Node3D:
	var building := Node3D.new()
	parent.add_child(building)
	var wall := StaticBody3D.new()
	wall.name = "Facade"
	wall.position.y = 8
	building.add_child(wall)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 16, 12)
	shape.shape = box
	wall.add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	visual.mesh = mesh
	wall.add_child(visual)
	return building


static func run_rendered(tree: SceneTree, check: Callable) -> void:
	# No dummy-renderer claim: callers must provide a normal Compatibility job.
	if DisplayServer.get_name() == "headless":
		check.call(false, "facade bay native LOD: requires real rendered post-draw frames")
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var scene := Node3D.new()
	viewport.add_child(scene)
	var building := _bare_building(scene)
	if not Bay.install(building, building.get_node("Facade")):
		check.call(false, "facade bay native LOD: real fitted resources load")
		viewport.free()
		return
	building.get_node("Facade").get_child(1).visible = false
	var holder: Node3D = building.get_node("GlasgowBayLOD")
	var counts: Dictionary = {}
	for name: String in ["Near", "Mid", "Far"]:
		var instance: MeshInstance3D = holder.get_node(name)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		counts[name] = instance.mesh.get_faces().size() / 3
	var camera := Camera3D.new()
	camera.fov = 90
	camera.near = 0.05
	camera.far = 220
	scene.add_child(camera)
	camera.current = true
	var near: MeshInstance3D = holder.get_node("Near")
	var center := near.global_transform * near.mesh.get_aabb().get_center()
	var sweep := [[10.0,"Near"], [24.0,"Near"], [28.0,"Near"], [30.0,"Mid"],
		[26.0,"Mid"], [22.0,"Mid"], [28.0,"Mid"], [20.0,"Near"], [28.0,"Near"],
		[30.0,"Mid"], [79.0,"Mid"], [85.0,"Mid"], [87.0,"Far"], [81.0,"Far"],
		[75.0,"Far"], [85.0,"Far"], [73.0,"Mid"], [79.0,"Mid"], [87.0,"Far"],
		[73.0,"Mid"], [20.0,"Near"]]
	for sample: Array in sweep:
		camera.position = center + Vector3(0, 0, sample[0])
		camera.look_at(center)
		for frame: int in range(3): await RenderingServer.frame_post_draw
		var actual := viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
		print("FACADE_NATIVE_LOD distance=%.1f expected=%s primitives=%d tick=%d" % [sample[0], sample[1], actual, Engine.get_process_frames()])
		check.call(actual == counts[sample[1]], "facade bay native LOD: one actual %s stage at %.1fm, hysteresis holds on return/oscillation" % [sample[1], sample[0]])
	viewport.free()
	await tree.process_frame
