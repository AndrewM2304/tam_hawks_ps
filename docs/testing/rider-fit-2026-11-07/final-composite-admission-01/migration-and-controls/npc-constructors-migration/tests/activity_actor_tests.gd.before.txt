extends RefCounted
## Actual anatomical meshes, native ground/sole contacts and inherited motion.
const Art = preload("res://game/features/feature_visuals.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")

class ActivityFixture extends Node3D:
	var reduced_motion := false
	var activity_state := "idle"
	func status_snapshot() -> Dictionary: return {"state":activity_state}


static func run(tree: SceneTree, check: Callable) -> void:
	for steward: bool in [false,true]:
		for normal: Vector3 in [Vector3.UP,Vector3(0.16,0.98,0.08).normalized()]:
			var fixture := Node3D.new()
			tree.root.add_child(fixture)
			var floor := StaticBody3D.new()
			floor.position = Vector3(17,1,-12)
			floor.basis = Basis(Quaternion(Vector3.UP,normal))
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(16,0.1,16)
			collision.shape = shape
			collision.position.y = -0.05
			floor.add_child(collision)
			fixture.add_child(floor)
			var activity := ActivityFixture.new()
			activity.process_mode = Node.PROCESS_MODE_PAUSABLE
			activity.position = Vector3(17,0,-12)
			activity.rotation.y = 0.65
			fixture.add_child(activity)
			var anchor := Vector3(0,3.8,0)
			var actor = Art.regular(activity,anchor,steward)
			actor.rotation.y = 0.3
			await _frames(tree,5)
			var label := ("steward" if steward else "regular") + (" flat" if normal == Vector3.UP else " slope")
			check.call(actor.position.is_equal_approx(anchor) and actor.name == ("FestivalSteward" if steward else "ParkRegular")
				and _count(actor,"CollisionObject3D") == 0,
				"activity actor: factory preserves root identity/placement and adds no collision " + label)
			check.call(actor._grounded and actor._body.visible and actor._body.global_position.y < actor.global_position.y-2.0,
				"activity actor: actual ray support grounds a visual body instead of floating at its high activity anchor " + label)
			check.call(_sole_contacts(actor),
				"activity actor: both actual shoe soles meet independently probed native support planes " + label)
			var head: MeshInstance3D = actor._head.get_node("AnatomicalHead")
			var hands := true
			for hand: Node3D in actor._hands:
				var mesh: MeshInstance3D = hand.get_node("HandAndFingers")
				hands = hands and mesh.mesh.get_blend_shape_count() == 1 and _vertices(mesh.mesh) > 300
			check.call(_vertices(head.mesh) > 500 and hands and _count(actor,"AudioStreamPlayer3D") == 0,
				"activity actor: detailed cleared adult face/finger meshes replace cylinders without adding an instrument or voice " + label)
			check.call(actor._garments.skeleton.get_bone_count() == 10
				and actor._body.get_node("SkinnedJacket").skin != null and _finite_reach(actor),
				"activity actor: original native clothing is skinned to finite articulated adult limbs " + label)
			var clearance := _plane_bounds(head,Vector3(17,1,-12),normal)
			check.call(clearance.x > 1.1 and clearance.y < 2.1,
				"activity actor: actual head vertices sit at plausible adult height above native ground " + label)
			check.call(actor._details.has_node("ShapedHiVisWaistcoat") == steward
				and actor._details.has_node("ReflectiveWaistBand") == steward,
				"activity actor: shaped hi-vis and reflective tailoring distinguish the steward " + label)
			var hand_start: Vector3 = actor._hands[1].global_position
			activity.activity_state = "active"
			await _frames(tree,35)
			check.call(actor._offer_blend > 0.8 and actor._hands[1].global_position.distance_to(hand_start) > 0.14
				and _sole_contacts(actor) and _finite_reach(actor),
				"activity actor: a bounded offer gesture articulates the actual hand while soles stay planted " + label)
			activity.activity_state = "success"
			await _frames(tree,35)
			check.call(actor._success_blend > 0.8 and actor._hands[0].global_position.y > actor._body.global_position.y+1.30
				and _finite_reach(actor) and _sole_contacts(actor),
				"activity actor: earned success raises finite articulated palms above a grounded stance " + label)
			await _frames(tree,180)
			check.call(actor._gesture_remaining == 0.0 and actor._success_blend < 0.01,
				"activity actor: a persistent success state cannot restart its completed gesture " + label)
			actor.set_look_target(actor._body.global_position+actor._body.global_basis*Vector3(2,1.3,-3))
			await _frames(tree,40)
			check.call(absf(actor._look_yaw) > 0.1 and absf(actor._look_yaw) <= 0.451,
				"activity actor: bounded anatomical head look follows a nearby offer target " + label)
			activity.reduced_motion = true
			var phase: float = actor._phase
			var before: Array[Transform3D] = [actor._head.global_transform,actor._hands[0].global_transform,actor._hands[1].global_transform]
			await _frames(tree,25)
			check.call(actor._phase == phase and actor._head.global_transform.is_equal_approx(before[0])
				and actor._hands[0].global_transform.is_equal_approx(before[1]) and actor._hands[1].global_transform.is_equal_approx(before[2]),
				"activity actor: parent reduced-motion freezes actual head and hand animation " + label)
			activity.reduced_motion = false
			tree.paused = true
			phase = actor._phase
			for frame in 8: await tree.process_frame
			check.call(not actor.can_process() and actor._phase == phase,
				"activity actor: inherited menu pause freezes the actor without an always-process override " + label)
			tree.paused = false
			await _frames(tree,4)
			check.call(actor._phase > phase,
				"activity actor: ordinary activity animation resumes after pause " + label)
			fixture.queue_free()
			await tree.process_frame
	await _dynamic_support_rejection(tree,check)


static func run_world(tree: SceneTree, game: Node, check: Callable) -> void:
	var actors: Array[Node] = []
	_find_actors(game,actors)
	await _frames(tree,8)
	check.call(actors.size() == 2,
		"activity actor world: both actual park regular and quay steward use the adult actor")
	for actor: Node3D in actors:
		check.call(actor._grounded and actor._body.visible and _sole_contacts(actor),
			"activity actor world: native " + str(actor.name) + " support and actual sole contacts agree at its authored site")
		var head: MeshInstance3D = actor._head.get_node("AnatomicalHead")
		check.call(_vertices(head.mesh) > 500 and _finite_reach(actor),
			"activity actor world: actual " + str(actor.name) + " constructs finite anatomical/garment meshes")
		print("ACTIVITY_ACTOR world ",actor.name," root=",actor.global_position," body=",actor._body.global_position,
			" contacts=",actor.get_ground_contacts())


static func _dynamic_support_rejection(tree: SceneTree, check: Callable) -> void:
	var fixture := Node3D.new()
	tree.root.add_child(fixture)
	var floor := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(8,0.1,8)
	floor_shape.shape = slab
	floor_shape.position.y = -0.05
	floor.add_child(floor_shape)
	fixture.add_child(floor)
	var passer := CharacterBody3D.new()
	passer.position.y = 1.0
	var character_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	character_shape.shape = capsule
	passer.add_child(character_shape)
	fixture.add_child(passer)
	var activity := ActivityFixture.new()
	fixture.add_child(activity)
	var actor = Art.regular(activity,Vector3(0,3,0))
	await _frames(tree,5)
	check.call(actor._grounded and absf(actor._body.global_position.y) < 0.005 and _sole_contacts(actor),
		"activity actor: a passing character cannot become fake ground underneath either foot")
	fixture.queue_free()
	await tree.process_frame


static func _sole_contacts(actor: Node) -> bool:
	if not actor._grounded: return false
	for foot: Dictionary in actor._feet:
		var node: Node3D = foot.node
		if node.to_global(Footwear.SOLE_CONTACT).distance_to(foot.point) > 0.004: return false
		if node.global_basis.y.normalized().dot(foot.normal) < 0.999: return false
		var bounds := _plane_bounds(node.get_node("Cupsole"),foot.point,foot.normal)
		if bounds.x < -0.005: return false
	return true


static func _finite_reach(actor: Node) -> bool:
	var skeleton: Skeleton3D = actor._garments.skeleton
	for index in skeleton.get_bone_count():
		var pose := skeleton.get_bone_pose(index)
		if not pose.origin.is_finite() or not pose.basis.is_finite() or skeleton.get_bone_pose_scale(index).y > 1.12: return false
	return true


static func _vertices(mesh: Mesh) -> int:
	var total := 0
	for surface in mesh.get_surface_count(): total += mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
	return total


static func _plane_bounds(mesh: MeshInstance3D, point: Vector3, normal: Vector3) -> Vector2:
	var result := Vector2(INF,-INF)
	for surface in mesh.mesh.get_surface_count():
		var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for vertex: Vector3 in vertices:
			var distance := (mesh.to_global(vertex)-point).dot(normal)
			result.x = minf(result.x,distance)
			result.y = maxf(result.y,distance)
	return result


static func _count(node: Node, kind: String) -> int:
	var result := 1 if node.is_class(kind) else 0
	for child: Node in node.get_children(): result += _count(child,kind)
	return result


static func _find_actors(node: Node, result: Array[Node]) -> void:
	if node.has_method("get_ground_contacts") and node.name in ["ParkRegular","FestivalSteward"]:
		result.append(node)
	for child: Node in node.get_children(): _find_actors(child,result)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
