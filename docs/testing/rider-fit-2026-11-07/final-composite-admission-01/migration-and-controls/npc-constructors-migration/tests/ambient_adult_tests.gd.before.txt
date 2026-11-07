extends RefCounted
## Passive city bystanders keep their authored identity while using the same
## cleared adult anatomy, skinned garments and native shoe contacts as hosts.
const ActorChecks = preload("res://tests/activity_actor_tests.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const EXPECTED := [
	[Vector3(-27,6,-116),Color("766354"),-0.6],
	[Vector3(-120,2,28),Color("6b5866"),1.2],
	[Vector3(123,0,29),Color("847c67"),-0.3],
]

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	await _frames(tree,8)
	var actors: Array[Node] = tree.get_nodes_in_group("ambient_adults")
	check.call(actors.size()==3 and game.world.get_npc_positions().size()==4,
		"ambient adults: all three passive adults preserve the four existing NPC proximity anchors")
	var materials: Dictionary = {}
	for spec: Array in EXPECTED:
		var actor: Node3D = null
		for candidate: Node3D in actors:
			if candidate.position.is_equal_approx(spec[0]): actor=candidate
		check.call(actor!=null,"ambient adults: authored bystander root remains at %s"%spec[0])
		if actor==null: continue
		check.call(is_equal_approx(actor.rotation.y,spec[2]) and actor.process_mode==Node.PROCESS_MODE_PAUSABLE
			and not actor.is_processing() and actor.reduced_motion
			and ActorChecks._count(actor,"CollisionObject3D")==0 and ActorChecks._count(actor,"AudioStreamPlayer3D")==0,
			"ambient adults: exact facing, pausable static posture and noncolliding passive behavior are preserved")
		var head: MeshInstance3D = actor.get_node("AdultActivityBody/Head/AnatomicalHead")
		var hands := true
		for hand: Node3D in actor._hands:
			hands = hands and ActorChecks._vertices(hand.get_node("HandAndFingers").mesh)>300
		check.call(ActorChecks._vertices(head.mesh)>500 and hands and actor._garments.skeleton.get_bone_count()==10
			and actor.get_node("AdultActivityBody/SkinnedJacket").skin!=null and ActorChecks._finite_reach(actor),
			"ambient adults: actual adult face, fingers and finite skinned limbs replace the capsule mannequin")
		var grounded := ActorChecks._sole_contacts(actor)
		for foot: Dictionary in actor._feet:
			var sole: Vector3 = foot.node.to_global(Footwear.SOLE_CONTACT)
			var query := PhysicsRayQueryParameters3D.create(sole+Vector3.UP*0.04,sole-Vector3.UP*0.04,1)
			var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
			grounded = grounded and not hit.is_empty() and hit.collider is StaticBody3D and hit.position.distance_to(sole)<0.004
			var low_ray := PhysicsRayQueryParameters3D.create(Vector3(sole.x,actor.global_position.y+0.8,sole.z),
				Vector3(sole.x,actor.global_position.y-2.0,sole.z),1)
			var intended := actor.get_world_3d().direct_space_state.intersect_ray(low_ray)
			grounded = grounded and not intended.is_empty() and intended.position.distance_to(sole)<0.004
		check.call(grounded and actor._body.visible,
			"ambient adults: both visible soles meet the actual nearby district floor without a floating root or roof snap")
		var jacket: MeshInstance3D = actor.get_node("AdultActivityBody/SkinnedJacket")
		var coat: StandardMaterial3D = jacket.material_override
		materials[coat.get_instance_id()]=true
		check.call(coat.albedo_color.is_equal_approx(spec[1])
			and actor.get_node("AdultActivityBody/CoatDetails/FoldedCoatCollar").material_override==coat,
			"ambient adults: each original coat color has a matching instance-local tailored collar")
		var before: Dictionary = actor.get_pose_snapshot()
		await _frames(tree,24)
		var after: Dictionary = actor.get_pose_snapshot()
		check.call(before.head.is_equal_approx(after.head) and before.body.is_equal_approx(after.body)
			and before.phase==after.phase and before.gesture==after.gesture,
			"ambient adults: intentional relaxed posture stays still during ordinary play")
		print("AMBIENT_ADULT root=%s yaw=%.3f body=%s contacts=%s coat=%s"%[actor.global_position,actor.rotation.y,actor._body.global_position,actor.get_ground_contacts(),coat.albedo_color])
	check.call(materials.size()==3,"ambient adults: coat overrides do not recolor other bystanders or activity hosts")
	var before_pause: Array[Dictionary] = []
	for actor: Node3D in actors: before_pause.append(actor.get_pose_snapshot())
	game.toggle_pause()
	await _frames(tree,10)
	var paused := true
	for i in actors.size():
		var actor: Node3D = actors[i]
		var pose: Dictionary = actor.get_pose_snapshot()
		paused = paused and not actor.can_process() and pose.head.is_equal_approx(before_pause[i].head)
		paused = paused and pose.body.is_equal_approx(before_pause[i].body)
	check.call(paused,"ambient adults: all three adults remain frozen under the actual Main pause flow")
	game.toggle_pause()
	await _frames(tree,4)
	var resumed := true
	for actor: Node3D in actors: resumed = resumed and actor.can_process() and ActorChecks._sole_contacts(actor)
	check.call(resumed,"ambient adults: resume retains native grounded soles without starting an idle or interaction")

static func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame
