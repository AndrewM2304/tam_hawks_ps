extends RefCounted
## Independent native-query acceptance for a camera optimization. The rider and
## world are frozen during each cached/uncached pair; this is not a played line.

const Chase = preload("res://game/player/chase_camera.gd")
const Skater = preload("res://game/player/skater.gd")
const Setup = preload("res://game/core/input_setup.gd")
const STATE_KEYS := [
	"_ready", "_selected_angle", "_last_anchor", "_body_up", "_travel_sign",
	"_direction_confirm", "_world_rear", "_heading_confirm", "_apex_rear",
	"_motion_pitch", "_horizontal_scale", "_motion_direction", "_orbit_up",
	"_ramp_mode", "_ramp_lift", "_ramp_turn", "_ramp_air_sequence",
	"_ramp_exit_remaining", "_return_arm", "_minimum_arm", "_ground_board_y",
	"_travel_velocity", "_foot_targets", "_wheel_landmarks",
]


static func run(tree: SceneTree, check: Callable) -> void:
	Setup.register_actions()
	var fixture := await _fixture(tree)
	var rider: CharacterBody3D = fixture.rider
	var space: PhysicsDirectSpaceState3D = rider.get_world_3d().direct_space_state
	var cached = Chase.new()
	var plain = Chase.new()
	plain.debug_query_cache_enabled = false
	var cached_camera := Camera3D.new()
	var plain_camera := Camera3D.new()
	fixture.root.add_child(cached_camera)
	fixture.root.add_child(plain_camera)
	var expected_physics := _physics_snapshot(rider)
	var total_cached := {"shape": 0, "ray": 0, "cast": 0}
	var total_plain := {"shape": 0, "ray": 0, "cast": 0}
	var clear_hits := 0
	var usable_hits := 0
	var sample_count := 0
	var blocked_saving := false
	for geometry: String in ["open", "rear_wall", "corner", "low_roof"]:
		_arrange(fixture, geometry)
		await _frames(tree, 2)
		for profile: Dictionary in [
			{"sensitivity": 0.5, "reduced": false, "delta": 1.0 / 60.0},
			{"sensitivity": 2.0, "reduced": false, "delta": 0.2},
			{"sensitivity": 1.0, "reduced": true, "delta": 0.0},
		]:
			cached.reset()
			plain.reset()
			var initial := Transform3D(Basis.IDENTITY, rider.global_position + Vector3(0, 2.5, 5.0))
			cached_camera.global_transform = initial
			plain_camera.global_transform = initial
			cached_camera.fov = 70.0
			plain_camera.fov = 70.0
			var parity := true
			var unchanged := true
			var bounded := true
			var scope_cleared := true
			var saved_queries := 0
			# No awaits, transform edits or input changes within these pairs.
			for sample in 8:
				cached.update(rider, cached_camera, profile.delta, profile.sensitivity, profile.reduced)
				plain.update(rider, plain_camera, profile.delta, profile.sensitivity, profile.reduced)
				parity = parity and cached_camera.global_transform == plain_camera.global_transform \
					and cached_camera.fov == plain_camera.fov and _state(cached) == _state(plain)
				unchanged = unchanged and _physics_snapshot(rider) == expected_physics
				var actual: Dictionary = cached.last_update_queries
				var control: Dictionary = plain.last_update_queries
				bounded = bounded and int(actual.shape) <= int(control.shape) \
					and int(actual.ray) <= int(control.ray) and actual.cast == control.cast
				saved_queries += int(control.shape) + int(control.ray) - int(actual.shape) - int(actual.ray)
				clear_hits += int(actual.clear_hits)
				usable_hits += int(actual.usable_hits)
				for key: String in ["shape", "ray", "cast"]:
					total_cached[key] += int(actual[key])
					total_plain[key] += int(control[key])
				scope_cleared = scope_cleared and not cached._query_cache_active \
					and cached._clear_results.is_empty() and cached._usable_results.is_empty()
				sample_count += 1
			check.call(parity, "PT24 camera cache: exact transform/FOV/semantic-state parity " + geometry + " " + str(profile))
			check.call(unchanged, "PT24 camera cache: rider physics is untouched " + geometry + " " + str(profile))
			check.call(bounded and scope_cleared,
				"PT24 camera cache: native queries never increase, sweeps are unchanged and scope is cleared " + geometry + " " + str(profile))
			if geometry != "open" and saved_queries > 0:
				blocked_saving = true
	check.call(blocked_saving and clear_hits + usable_hits > 0
		and total_cached.shape + total_cached.ray < total_plain.shape + total_plain.ray,
		"PT24 camera cache: repeated blocked-view checks demonstrably reduce actual native shape/visibility-ray queries")
	print("PT24_CAMERA_QUERY_PARITY samples=%d cached=%s uncached=%s clear_hits=%d usable_hits=%d" % [
		sample_count, total_cached, total_plain, clear_hits, usable_hits])
	await _invalidation(tree, fixture, cached, plain, cached_camera, plain_camera, space, check)
	check.call(_physics_snapshot(rider) == expected_physics,
		"PT24 camera cache: obstacle invalidation also leaves every frozen rider physics field unchanged")
	cached.reset()
	check.call(not cached._query_cache_active and cached._clear_results.is_empty() and cached._usable_results.is_empty(),
		"PT24 camera cache: reset retains no native-query answers")
	fixture.viewport.queue_free()
	await tree.process_frame


static func _invalidation(tree: SceneTree, fixture: Dictionary, cached: RefCounted, plain: RefCounted,
		cached_camera: Camera3D, plain_camera: Camera3D, space: PhysicsDirectSpaceState3D, check: Callable) -> void:
	_arrange(fixture, "open")
	await _frames(tree, 2)
	cached.reset()
	plain.reset()
	var rider: CharacterBody3D = fixture.rider
	var initial := Transform3D(Basis.IDENTITY, rider.global_position + Vector3(0, 2.5, 5.0))
	cached_camera.global_transform = initial
	plain_camera.global_transform = initial
	cached_camera.fov = 70.0
	plain_camera.fov = 70.0
	for sample in 3:
		cached.update(rider, cached_camera, 1.0 / 60.0, 1.0, false)
		plain.update(rider, plain_camera, 1.0 / 60.0, 1.0, false)
	var old_position := cached_camera.global_position
	var excluded: Array[RID] = [rider.get_rid()]
	check.call(_native_clear(space, old_position, excluded) and cached._clear_volume(space, old_position),
		"PT24 camera cache: native control confirms the previously selected endpoint is clear")
	# Move an actual solid onto the exact endpoint queried in the prior update.
	var obstacle := _box(Vector3.ONE, old_position)
	fixture.root.add_child(obstacle)
	await _frames(tree, 2)
	check.call(not _native_clear(space, old_position, excluded)
		and not cached._clear_volume(space, old_position)
		and not cached._usable(space, rider.global_position, cached._last_anchor, old_position, excluded),
		"PT24 camera cache: direct helpers observe a newly moved native obstacle at the exact old cache key")
	var before: Dictionary = cached.last_update_queries
	cached._clear_volume(space, old_position)
	cached._clear_volume(space, old_position)
	var after: Dictionary = cached.last_update_queries
	check.call(int(after.shape) == int(before.shape) + 2 and after.clear_hits == before.clear_hits,
		"PT24 camera cache: direct helper calls outside update always perform fresh native queries")
	cached.update(rider, cached_camera, 1.0 / 60.0, 1.0, false)
	plain.update(rider, plain_camera, 1.0 / 60.0, 1.0, false)
	check.call(cached_camera.global_transform == plain_camera.global_transform
		and cached_camera.fov == plain_camera.fov and _state(cached) == _state(plain)
		and cached_camera.global_position != old_position
		and _native_clear(space, cached_camera.global_position, excluded),
		"PT24 camera cache: the next update rejects stale visibility and exactly matches uncached obstacle recovery")
	obstacle.queue_free()
	await _frames(tree, 2)
	check.call(_native_clear(space, old_position, excluded) and cached._clear_volume(space, old_position),
		"PT24 camera cache: removing the obstacle is likewise visible to an uncached direct helper")
	cached.update(rider, cached_camera, 1.0 / 60.0, 1.0, false)
	plain.update(rider, plain_camera, 1.0 / 60.0, 1.0, false)
	check.call(cached_camera.global_transform == plain_camera.global_transform
		and _state(cached) == _state(plain),
		"PT24 camera cache: obstacle removal preserves exact continuation parity across updates")
	cached.update(null, cached_camera, 1.0 / 60.0, 1.0, false)
	check.call(not cached._query_cache_active and cached._clear_results.is_empty() and cached._usable_results.is_empty(),
		"PT24 camera cache: an invalid-rider early return cannot retain a query scope")


static func _state(chase: RefCounted) -> Dictionary:
	var values := {}
	for key: String in STATE_KEYS:
		values[key] = chase.get(key)
	return values


static func _physics_snapshot(rider: CharacterBody3D) -> Dictionary:
	return {"frame": rider.global_transform, "velocity": rider.velocity, "speed": rider.speed,
		"airborne": rider.airborne, "floor": rider.is_on_floor(), "transition": rider.transition_active,
		"bailing": rider.bailing, "up": rider.up_direction,
		"capsule": rider.get_node("BodyCollision").transform}


static func _native_clear(space: PhysicsDirectSpaceState3D, point: Vector3, excluded: Array[RID]) -> bool:
	var sphere := SphereShape3D.new()
	sphere.radius = 0.25
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.margin = 0.015
	query.collision_mask = 1
	query.exclude = excluded
	query.transform = Transform3D(Basis.IDENTITY, point)
	return space.intersect_shape(query, 1).is_empty()


static func _fixture(tree: SceneTree) -> Dictionary:
	# A private native World3D prevents unrelated Main geometry from changing the
	# control fixture when this module runs inside the complete suite.
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(640, 480)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	root.add_child(_box(Vector3(100, 0.4, 100), Vector3(0, -0.2, 0)))
	var rider = Skater.new()
	rider.spawn_position = Vector3(0, 0.8, 0)
	root.add_child(rider)
	await _frames(tree, 45)
	rider.set_process(false)
	rider.set_physics_process(false)
	var rear := _box(Vector3(8, 5, 0.4), Vector3(100, 2.5, 4))
	var side := _box(Vector3(0.4, 5, 9), Vector3(100, 2.5, 1))
	var roof := _box(Vector3(12, 0.25, 12), Vector3(100, 3.6, 0))
	for body: StaticBody3D in [rear, side, roof]:
		root.add_child(body)
	return {"viewport": viewport, "root": root, "rider": rider, "rear": rear, "side": side, "roof": roof}


static func _arrange(fixture: Dictionary, geometry: String) -> void:
	fixture.rear.position = Vector3(0 if geometry in ["rear_wall", "corner", "low_roof"] else 100, 2.5, 4)
	fixture.side.position = Vector3(4.2 if geometry in ["corner", "low_roof"] else 100, 2.5, 1)
	fixture.roof.position = Vector3(0 if geometry == "low_roof" else 100, 3.6, 0)


static func _box(size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	body.position = at
	return body


static func _frames(tree: SceneTree, count: int) -> void:
	for sample in count:
		await tree.physics_frame
		await tree.process_frame
