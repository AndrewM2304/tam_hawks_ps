extends SceneTree
## Independent bounded static audit. Normal movement/framing lives in the separate
## no---script playability scene; this probe never claims human exploration coverage.
const WorldSource = preload("res://game/levels/glasgow_square.gd")
var world: Node3D
var passed := 0
var failed := 0
var metrics: Dictionary = {}
var inputs: Dictionary = {}
var started := Time.get_ticks_msec()

func _initialize() -> void:
	_run.call_deferred()

func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - started > 180000:
		push_error("WORLD PROBE TIMEOUT")
		quit(2)
	return false

func _run() -> void:
	inputs = _source_hashes()
	world = WorldSource.new()
	root.add_child(world)
	await physics_frame
	await process_frame
	_boundaries()
	_mouths()
	_park()
	_water()
	var after := _source_hashes()
	_check(inputs == after, "all source inputs unchanged during independent world probe")
	var receipt := {"utc": Time.get_datetime_string_from_system(true), "passed": passed,
		"failed": failed, "inputs": inputs, "source_unchanged": inputs == after,
		"metrics": metrics, "limits": ["Static actual-world collision/mesh/query samples; no player simulation in this probe.",
		"Each boundary panel is isolated from other bodies for its own collision proof; continuous-route sweeps use all layer-1 collision.",
		"Park rays isolate actual outdoor surface bodies, excluding props/fences; they do not establish human traversability.",
		"Water return checks query real support and capsule clearance; actual missed-jump/recovery motion is separate coverage."]}
	var out := FileAccess.open("res://docs/testing/logs/playability-world-source.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(receipt, "\t") + "\n")
	world.queue_free()
	await process_frame
	print("WORLD PROBE RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _boundaries() -> void:
	var bodies := get_nodes_in_group("exploration_boundaries")
	var all_bodies: Array[CollisionObject3D] = []
	_collision_objects(world, all_bodies)
	var panels := 0
	var rays := 0
	var bad_visual: Array[String] = []
	var bad_collision: Array[String] = []
	_check(bodies.size() == 58, "58 actual retained boundary bodies exist")
	for body: StaticBody3D in bodies:
		var points: PackedVector3Array = body.get_meta("boundary_points")
		var height: float = body.get_meta("boundary_height")
		var excluded: Array[RID] = []
		for other: CollisionObject3D in all_bodies:
			if other != body: excluded.append(other.get_rid())
		var visual_ok := body.collision_layer & 1 and height >= 2.9
		var collision_ok := true
		var stone := body.get_node_or_null("RetainedMasonry") as MultiMeshInstance3D
		var iron := body.get_node_or_null("Ironwork") as MultiMeshInstance3D
		for index: int in range(points.size()-1):
			panels += 1
			var a := body.to_global(points[index])
			var b := body.to_global(points[index+1])
			var mid := (a+b)*0.5
			var across := Vector3(b.z-a.z,0,a.x-b.x).normalized()
			visual_ok = visual_ok and _in_visible_instance(stone,mid+Vector3.UP*0.15) and _in_visible_instance(iron,mid+Vector3.UP*(height-0.08))
			for lift: float in [0.15,1.0,height-0.15]:
				for direction: float in [-1.0,1.0]:
					var target := mid+Vector3.UP*lift
					var query := PhysicsRayQueryParameters3D.create(target+across*direction*0.7,target-across*direction*0.7,1,excluded)
					var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
					rays += 1
					collision_ok = collision_ok and not hit.is_empty() and hit.collider == body and absf(hit.normal.dot(across)) > 0.95
		if not visual_ok: bad_visual.append(str(body.get_path()))
		if not collision_ok: bad_collision.append(str(body.get_path()))
	_check(bad_visual.is_empty(), "every boundary panel has actual visible masonry and continuous top ironwork: "+str(bad_visual))
	_check(bad_collision.is_empty(), "every boundary panel blocks both directions at three heights: "+str(bad_collision))
	metrics.boundary_bodies = bodies.size()
	metrics.boundary_panels = panels
	metrics.boundary_collision_rays = rays
	print("BOUNDARY SAMPLES: bodies=%d panels=%d collision_rays=%d" % [bodies.size(),panels,rays])

func _mouths() -> void:
	var routes: Array = world.get_route_definitions()
	var blocked: Array[String] = []
	var segments := 0
	var continuous := 0
	for route: Dictionary in routes:
		if route.get("requires_jump",false): continue
		continuous += 1
		var points: PackedVector3Array = route.points
		for index: int in range(points.size()-1):
			segments += 1
			for reverse: bool in [false,true]:
				var a := points[index+1] if reverse else points[index]
				var b := points[index] if reverse else points[index+1]
				var query := _capsule(a)
				query.motion = b-a
				var hit := world.get_world_3d().direct_space_state.cast_motion(query)
				if hit.size() != 2 or hit[0] < 0.9999:
					blocked.append("%s segment%d reverse%s" % [route.id,index,reverse])
	_check(routes.size() == 48, "48 published routes retain all four new close mouths")
	_check(blocked.is_empty(), "all continuous route segments remain open in both directions with complete world collision: "+str(blocked))
	metrics.continuous_routes = continuous
	metrics.route_segments = segments
	print("MOUTH SWEEPS: routes=%d segments=%d bidirectional_sweeps=%d" % [continuous,segments,segments*2])

func _park() -> void:
	var outdoor := world.get_node("OutdoorRoutes")
	var excluded: Array[RID] = []
	var bodies: Array[CollisionObject3D] = []
	_collision_objects(world,bodies)
	for body: CollisionObject3D in bodies:
		if not body.is_in_group("outdoor_surfaces"): excluded.append(body.get_rid())
	var count := 0
	var max_error := 0.0
	var failures: Array[String] = []
	# Offset from mesh knots: rays independently test interpolated triangle interiors.
	for xi: int in range(30):
		for zi: int in range(43):
			var at := Vector3(-253.73+xi*3.79,0,-223.41+zi*3.81)
			var expected: float = outdoor.get_ground_height(at.x,at.z)
			var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*35,at-Vector3.UP*5,1,excluded)
			var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
			count += 1
			if hit.is_empty() or not is_finite(expected):
				failures.append("missing "+str(at))
			else:
				var error := absf(hit.position.y-expected)
				max_error = maxf(max_error,error)
				if error > 0.025: failures.append("%s error%.5f" % [at,error])
	_check(failures.is_empty(), "park public heights match actual collision triangle interiors: "+str(failures.slice(0,8)))
	var worst_step := 0.0
	var seam_rays := 0
	var seam_valid := true
	for x: float in [-143.5,-142.5,-141.0]:
		var previous := NAN
		for zi: int in range(33):
			var at := Vector3(x,0,-199+zi*0.25)
			var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*35,at-Vector3.UP*5,1,excluded)
			var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
			seam_rays += 1
			if hit.is_empty():
				seam_valid = false
				continue
			if is_finite(previous): worst_step = maxf(worst_step,absf(hit.position.y-previous))
			previous = hit.position.y
	_check(seam_valid and worst_step < 0.5, "former north/east park discontinuity has no abrupt drop across 0.25m samples")
	metrics.park_triangle_rays = count
	metrics.park_max_height_error = max_error
	metrics.park_discontinuity_rays = seam_rays
	metrics.park_max_quarter_metre_step = worst_step
	print("PARK SAMPLES: triangle_rays=%d max_error=%.8f seam_rays=%d max_step=%.6f" % [count,max_error,seam_rays,worst_step])

func _water() -> void:
	var water := world.get_node("OutdoorRoutes/ClydeWater") as MeshInstance3D
	var bounds := water.get_aabb()
	var count := 0
	var failures: Array[String] = []
	var returns: Dictionary = {}
	for xi: int in range(33):
		for zi: int in range(13):
			var local := Vector3(lerpf(bounds.position.x+0.05,bounds.end.x-0.05,float(xi)/32),-0.1,lerpf(bounds.position.z+0.05,bounds.end.z-0.05,float(zi)/12))
			var at := water.to_global(local)
			var safe: Vector3 = world.get_recovery_position(at)
			count += 1
			if not safe.is_finite():
				failures.append("no recovery "+str(at))
				continue
			returns[str(safe)] = safe
			var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(safe+Vector3.UP*0.1,safe-Vector3.UP*1.5,1))
			if hit.is_empty() or hit.normal.y < 0.95 or safe.y-hit.position.y < 0.5 or safe.y-hit.position.y > 1.0:
				failures.append("unsupported return "+str(safe))
			elif not world.get_world_3d().direct_space_state.intersect_shape(_capsule(hit.position)).is_empty():
				failures.append("blocked return "+str(safe))
	_check(water.visible and bounds.size.x >= 899 and bounds.size.z >= 37, "recovery audit derives the full visible water mesh footprint")
	_check(failures.is_empty(), "visible-water samples recover to actual supported clear quays: "+str(failures.slice(0,8)))
	var outside_ok := true
	for local: Vector3 in [Vector3(bounds.position.x-0.05,-0.1,0),Vector3(bounds.end.x+0.05,-0.1,0),Vector3(0,-0.1,bounds.position.z-0.05),Vector3(0,-0.1,bounds.end.z+0.05),Vector3(0,0.3,0)]:
		outside_ok = outside_ok and not world.get_recovery_position(water.to_global(local)).is_finite()
	_check(outside_ok, "recovery is not triggered outside visible river or above its fall threshold")
	metrics.water_samples = count
	metrics.unique_safe_returns = returns.size()
	print("WATER SAMPLES: footprint=%s hazard_samples=%d unique_clear_returns=%d" % [bounds.size,count,returns.size()])

func _capsule(floor_at: Vector3) -> PhysicsShapeQueryParameters3D:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,floor_at+Vector3.UP*0.98)
	query.collision_mask = 1
	query.margin = 0.01
	return query

func _in_visible_instance(node: MultiMeshInstance3D, at: Vector3) -> bool:
	if node == null or not node.is_visible_in_tree() or node.multimesh == null: return false
	var bounds := node.multimesh.mesh.get_aabb().grow(0.002)
	for index: int in range(node.multimesh.instance_count):
		var transform := node.global_transform * node.multimesh.get_instance_transform(index)
		if transform.origin.is_finite() and bounds.has_point(transform.affine_inverse()*at): return true
	return false

func _collision_objects(node: Node, result: Array[CollisionObject3D]) -> void:
	if node is CollisionObject3D: result.append(node)
	for child: Node in node.get_children(): _collision_objects(child,result)

func _source_hashes() -> Dictionary:
	var files: Array[String] = ["project.godot","docs/testing/playability_world_probe.gd","tools/run.sh"]
	_source_files("game",files)
	files.sort()
	var hashes: Dictionary = {}
	for path: String in files: hashes[path] = FileAccess.get_sha256("res://"+path)
	return hashes

func _source_files(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open("res://"+path)
	for file: String in dir.get_files(): result.append(path+"/"+file)
	for child: String in dir.get_directories(): _source_files(path+"/"+child,result)

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: "+label)
	else:
		failed += 1
		push_error("FAIL: "+label)
