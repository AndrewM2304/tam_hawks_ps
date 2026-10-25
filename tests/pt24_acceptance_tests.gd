extends RefCounted
## Independent native-query acceptance for a camera optimization. The rider and
## world are frozen during each cached/uncached pair; this is not a played line.

const Chase = preload("res://game/player/chase_camera.gd")
const Skater = preload("res://game/player/skater.gd")
const Setup = preload("res://game/core/input_setup.gd")
const BoardGeometry = preload("res://tests/board_geometry_tests_support.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")

class FrozenPresentation extends "res://game/player/chase_camera.gd":
	# Exact frozen displayed endpoint, independent of interpolation scheduling.
	# The actual visual nodes and native blocker remain in the private World3D.
	var frames: Dictionary = {}
	func _follow_transform(node: Node3D) -> Transform3D:
		if frames.has(node.get_instance_id()): return frames[node.get_instance_id()]
		return super._follow_transform(node)

const STATE_KEYS := [
	"_ready", "_selected_angle", "_last_anchor", "_body_up", "_travel_sign",
	"_direction_confirm", "_world_rear", "_heading_confirm", "_apex_rear",
	"_motion_pitch", "_horizontal_scale", "_motion_direction", "_orbit_up",
	"_ramp_mode", "_ramp_lift", "_ramp_turn", "_ramp_air_sequence",
	"_ramp_exit_remaining", "_return_arm", "_minimum_arm", "_ground_board_y",
	"_travel_velocity", "_foot_targets", "_wheel_landmarks", "_head_targets", "_head_bounds",
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
	await _actual_head_visibility(tree,fixture,check)
	await _head_extent_visibility(tree,fixture,check)
	await _current_pose_visibility(tree,fixture,check)
	fixture.viewport.queue_free()
	await tree.process_frame


static func _actual_head_visibility(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
	_arrange(fixture,"open")
	await _frames(tree,2)
	var rider: CharacterBody3D=fixture.rider
	var space:=rider.get_world_3d().direct_space_state
	var chase:=Chase.new()
	var camera:=Camera3D.new()
	fixture.root.add_child(camera)
	var from: Vector3=rider.global_position+Vector3(0,2.5,5)
	camera.global_position=from
	chase.update(rider,camera,1.0/60.0,1.0,false)
	var head: Vector3=rider._visual_rig._head.global_position
	var saved:=chase._head_targets.duplicate()
	var saved_bounds:=chase._head_bounds.duplicate()
	var excluded: Array[RID]=[rider.get_rid()]
	var platform:=_box(Vector3(.7,.025,.6),from.lerp(head,.55))
	fixture.root.add_child(platform)
	await _frames(tree,2)
	var proxies_clear:=true
	for height: float in [.12,Chase.CHEST_HEIGHT,1.8]:
		proxies_clear=proxies_clear and space.intersect_ray(PhysicsRayQueryParameters3D.create(
			from,rider.global_position+Vector3.UP*height,1|8,excluded)).is_empty()
	var head_hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,head,1|8,excluded))
	check.call(proxies_clear and not head_hit.is_empty() and head_hit.collider==platform
		and _native_clear(space,from,excluded),
		"PT24 camera head: thin native deck blocks the actual head while all three old proxies and camera volume stay clear")
	chase._head_targets.clear()
	chase._head_bounds.clear()
	var old_usable: bool=chase._usable(space,rider.global_position,chase._last_anchor,from,excluded)
	chase._head_targets=saved
	chase._head_bounds=saved_bounds
	check.call(old_usable and not chase._usable(space,rider.global_position,chase._last_anchor,from,excluded)
		and saved.size()>=1 and saved.size()<=2 and saved.has(head),
		"PT24 camera head: removing only real head targets reproduces the old false-clear endpoint; the complete query rejects it")
	chase.reset()
	camera.global_position=from
	for frame in 8: chase.update(rider,camera,1.0/60.0,1.0,false)
	check.call(space.intersect_ray(PhysicsRayQueryParameters3D.create(
		camera.global_position,head,1|8,excluded)).is_empty() and _native_clear(space,camera.global_position,excluded),
		"PT24 camera head: ordinary solver recovers a native-clear endpoint with the real head visible")
	chase.reset()
	check.call(chase._head_targets.is_empty() and chase._head_bounds.is_empty(),
		"PT24 camera head: reset clears rendered/current head centers and bounds")
	platform.queue_free()
	await _frames(tree,2)


static func _head_extent_visibility(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
	_arrange(fixture,"open")
	await _frames(tree,2)
	var rider: CharacterBody3D=fixture.rider
	var space:=rider.get_world_3d().direct_space_state
	var chase:=Chase.new()
	var camera:=Camera3D.new()
	fixture.root.add_child(camera)
	var from: Vector3=rider.global_position+Vector3(0,2.5,5)
	camera.global_position=from
	chase.update(rider,camera,1.0/60.0,1.0,false)
	var mesh: MeshInstance3D=rider._visual_rig._head.get_node("AnatomicalHead")
	var hull: ConvexPolygonShape3D=mesh.mesh.create_convex_shape(true,false)
	var extremity:=mesh.to_global(hull.points[0])
	for vertex: Vector3 in hull.points:
		var point:=mesh.to_global(vertex)
		if point.x>extremity.x: extremity=point
	var platform:=_box(Vector3.ONE*.006,from.lerp(extremity,.55))
	fixture.root.add_child(platform)
	await _frames(tree,2)
	var excluded: Array[RID]=[rider.get_rid()]
	var centers_clear:=true
	for point: Vector3 in chase._head_targets:
		centers_clear=centers_clear and space.intersect_ray(PhysicsRayQueryParameters3D.create(from,point,1|8,excluded)).is_empty()
	var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,extremity,1|8,excluded))
	check.call(centers_clear and not hit.is_empty() and hit.collider==platform and _native_clear(space,from,excluded),
		"PT24 camera head extent: a native thin edge hides an actual anatomical hull vertex while both head centers and camera volume stay clear")
	var bounds:=chase._head_bounds.duplicate()
	chase._head_bounds.clear()
	var old_before: Dictionary=chase.last_update_queries
	var old_usable: bool=chase._usable(space,rider.global_position,chase._last_anchor,from,excluded)
	var old_after: Dictionary=chase.last_update_queries
	chase._head_bounds=bounds
	var before: Dictionary=chase.last_update_queries
	var usable: bool=chase._usable(space,rider.global_position,chase._last_anchor,from,excluded)
	var after: Dictionary=chase.last_update_queries
	check.call(old_usable and not usable,
		"PT24 camera head extent: removing only the bounds volume reproduces the center-only false clear; complete visibility rejects it")
	check.call(int(after.shape)-int(before.shape)==int(old_after.shape)-int(old_before.shape)+1
		and bounds.size()>=8 and bounds.size()<=16,
		"PT24 camera head extent: one native shape query covers at most sixteen current/rendered corners per unique endpoint")
	chase.reset()
	camera.global_position=from
	for frame in 8: chase.update(rider,camera,1.0/60.0,1.0,false)
	var hull_clear:=true
	for vertex: Vector3 in hull.points:
		hull_clear=hull_clear and space.intersect_ray(PhysicsRayQueryParameters3D.create(
			camera.global_position,mesh.to_global(vertex),1|8,excluded)).is_empty()
	check.call(hull_clear and _native_clear(space,camera.global_position,excluded),
		"PT24 camera head extent: bounded ordinary solver recovery leaves every actual head hull vertex visible")
	platform.queue_free()
	await _frames(tree,2)


static func _current_pose_visibility(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
	_arrange(fixture,"open")
	await _frames(tree,2)
	var rider: CharacterBody3D=fixture.rider
	var rig: RefCounted=rider._visual_rig
	var space:=rider.get_world_3d().direct_space_state
	var excluded: Array[RID]=[rider.get_rid()]
	var from: Vector3=rider.global_position+Vector3(0,2.5,5)
	var physics:=_physics_snapshot(rider)
	for kind: String in ["board","foot"]:
		var node: Node3D=rider._board_visual if kind=="board" else rig._legs[0].foot
		var original:=node.global_transform
		var chase:=FrozenPresentation.new()
		chase.frames[node.get_instance_id()]=original
		node.global_position+=Vector3.RIGHT*.8
		var camera:=Camera3D.new()
		fixture.root.add_child(camera)
		camera.global_position=from
		chase.update(rider,camera,1.0/60.0,1.0,false)
		var actual: Vector3=node.to_global(Footwear.TOE_CONTACT)
		if kind=="board":
			actual=Vector3(-INF,0,0)
			for mesh: MeshInstance3D in BoardGeometry.visible_meshes(rig,false):
				var hull: ConvexPolygonShape3D=mesh.mesh.create_convex_shape(true,false)
				for vertex: Vector3 in hull.points:
					var point:=mesh.to_global(vertex)
					if point.x>actual.x: actual=point
		var blocker:=_box(Vector3.ONE*.02,from.lerp(actual,.55))
		fixture.root.add_child(blocker)
		await _frames(tree,2)
		var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,actual,1|8,excluded))
		var complete:=chase._foot_targets.duplicate()
		var displayed:=PackedVector3Array()
		for leg: Dictionary in rig._legs:
			var foot: Transform3D=chase._follow_transform(leg.foot)
			displayed.append(foot*Footwear.SOLE_CONTACT)
			displayed.append(foot*Footwear.TOE_CONTACT)
		var deck: Transform3D=chase._follow_transform(rider._board_visual)
		for point: Vector3 in chase._wheel_landmarks: displayed.append(deck*point)
		chase._foot_targets=displayed
		var old_usable: bool=chase._usable(space,rider.global_position,chase._last_anchor,from,excluded)
		chase._foot_targets=complete
		check.call(not hit.is_empty() and hit.collider==blocker and _native_clear(space,from,excluded)
			and old_usable,"PT24 camera current pose: a real "+kind+" extremity is hidden while every displayed-only target and the camera volume stay clear")
		check.call(complete.size()>displayed.size() and not chase._usable(space,rider.global_position,chase._last_anchor,from,excluded),
			"PT24 camera current pose: restoring only current "+kind+" targets rejects the old false clear without changing the4mm endpoint allowance")
		check.call(_physics_snapshot(rider)==physics,"PT24 camera current pose: collecting both "+kind+" transforms changes no rider physics")
		node.global_transform=original
		blocker.queue_free()
		camera.queue_free()
		await _frames(tree,2)


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
