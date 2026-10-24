extends RefCounted
## Original 90-degree finite collision fixtures. The rider's declared initial
## speed is never rewritten; native motion and transition gravity drive each run.

const TransitionRide = preload("res://game/player/feature_transition_ride.gd")
const TransitionFeature = preload("res://game/levels/transition_feature.gd")

class Rider extends CharacterBody3D:
	var ride = TransitionRide.new()
	var running := false
	var request := true
	var steering := 0.0
	var push := 0.0
	var brake := 0.0
	var jump := false
	var held := false
	var entries := 0
	var launches := 0
	var landings := 0
	var exits := 0
	var bails := 0
	var lips := 0
	var max_y := 0.0
	var max_pitch := 0.0
	var max_error := 0.0
	var max_energy := 0.0
	var last_result: Dictionary = {}

	func _physics_process(delta: float) -> void:
		if not running:
			return
		if not ride.active and request and ride.try_enter(self, velocity):
			entries += 1
		if ride.active:
			last_result = ride.step(self, delta, push, brake, steering, jump, held)
			jump = false
			match last_result.event:
				"launch": launches += 1
				"landed": landings += 1
				"exit": exits += 1
				"bail":
					bails += 1
					request = false
				"lip": lips += 1
			max_pitch = maxf(max_pitch, acos(clampf(ride.normal.dot(Vector3.UP), -1.0, 1.0)))
			max_error = maxf(max_error, ride.max_support_error)
		else:
			velocity.y -= 22.0 * delta
			move_and_slide()
		max_y = maxf(max_y, global_position.y)
		max_energy = maxf(max_energy, velocity.length_squared() * 0.5 + 22.0 * global_position.y)


static func run(tree: SceneTree, check: Callable) -> void:
	await _vertical_return(tree, check)
	await _rollback(tree, check)
	await _lip_release(tree, check)
	await _lip_failure(tree, check)
	await _entry_guards(tree, check)
	await _obstruction(tree, check)
	await _transformed(tree, check)
	await _approach_variants(tree, check)
	await _surface_geometry(tree, check)
	await _collision_loss(tree, check)
	await _transfers(tree, check)
	await _grind_handoff_clearance(tree, check)


static func _vertical_return(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 12.0)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 180)
	print("TRANSITION90 position=%s velocity=%s entry=%d launch=%d land=%d exit=%d bail=%d height=%.3f pitch=%.3f error=%.5f energy=%.3f" % [rider.position, rider.velocity, rider.entries, rider.launches, rider.landings, rider.exits, rider.bails, rider.max_y, rad_to_deg(rider.max_pitch), rider.max_error, rider.max_energy])
	check.call(rider.entries == 1 and rider.launches == 1 and rider.bails == 0,
		"transition: real approach traverses the finite face and launches once")
	check.call(rider.max_pitch > deg_to_rad(89.9) and rider.max_y > fixture.feature.radius + 0.5,
		"transition: capsule reaches a genuine 90-degree wall and rises above its lip")
	check.call(rider.landings == 1 and rider.exits == 1 and not rider.ride.active,
		"transition: descending vertical return lands once then rolls out through the actual toe")
	check.call(rider.velocity.z > 8.0 and rider.position.z > 2.0,
		"transition: full gravity returns useful outward momentum onto the approach")
	check.call(rider.max_error <= 0.045 and rider.max_energy < 73.0,
		"transition: collision correction remains bounded and unpowered traversal creates no energy")
	var collision: CollisionShape3D = rider.get_node("BodyCollision")
	check.call(collision.transform.is_equal_approx(Transform3D(Basis.IDENTITY, Vector3(0, 0.85, 0)))
		and rider.up_direction == Vector3.UP,
		"transition: normal toe exit restores the original capsule and world up")
	await _dispose(tree, fixture.root)


static func _rollback(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 4.0)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 150)
	check.call(rider.entries == 1 and rider.exits == 1 and rider.launches == 0 and rider.bails == 0,
		"transition: insufficient energy rolls back smoothly instead of climbing to the lip")
	check.call(rider.max_y > 0.20 and rider.max_y < 0.42 and rider.velocity.z > 3.0,
		"transition: low-speed maximum height and return agree with full tangent gravity")
	check.call(rider.max_energy < 8.6 and rider.max_error < 0.045,
		"transition: rollback neither manufactures momentum nor drifts off collision")
	await _dispose(tree, fixture.root)


static func _lip_release(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 12.0)
	var rider: Rider = fixture.rider
	rider.held = true
	rider.running = true
	await _frames(tree, 50)
	check.call(rider.lips == 1 and rider.ride.state == "lip" and rider.ride.lip
		and rider.global_position.distance_to(fixture.feature.lip_frame(0.0).point) < 0.01,
		"transition: held grind catches the real coping with one finite lip state")
	var at: Vector3 = rider.position
	var balance: float = rider.ride.lip_balance
	rider.set_physics_process(false)
	await _frames(tree, 8)
	check.call(rider.position == at and rider.ride.lip_balance == balance,
		"transition: paused physics advances neither lip balance nor position")
	rider.set_physics_process(true)
	rider.held = false
	await _frames(tree, 110)
	check.call(rider.exits == 1 and rider.bails == 0 and rider.velocity.z > 8.0,
		"transition: releasing coping drops into the actual face and rolls back out")
	await _dispose(tree, fixture.root)
	fixture = await _fixture(tree, 12.0)
	rider = fixture.rider
	rider.held = true
	rider.running = true
	await _frames(tree, 50)
	rider.jump = true
	await _frames(tree, 1)
	check.call(rider.launches == 1 and rider.ride.state == "air" and rider.velocity.y > 8.0
		and rider.velocity.z > 4.0,
		"transition: deliberate coping jump launches upward and away with one event")
	await _frames(tree, 20)
	check.call(not rider.ride.active and rider.last_result.event == "exit_air",
		"transition: an away jump releases its contact frame only after actual capsule clearance")
	await _dispose(tree, fixture.root)


static func _lip_failure(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 12.0)
	var rider: Rider = fixture.rider
	rider.held = true
	rider.running = true
	await _frames(tree, 50)
	rider.steering = 1.0
	await _frames(tree, 50)
	check.call(rider.bails == 1 and not rider.ride.active,
		"transition: uncorrected coping balance reaches a real finite failure")
	check.call(rider.get_node("BodyCollision").position.is_equal_approx(Vector3(0, 0.85, 0)),
		"transition: lip failure restores the capsule even while touching a vertical wall")
	await _dispose(tree, fixture.root)


static func _entry_guards(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	check.call(not rider.ride.try_enter(rider, Vector3(0, NAN, -12)),
		"transition: nonfinite velocity cannot enter native transition motion")
	rider.position = Vector3(8, 0.022, -1)
	check.call(not rider.ride.try_enter(rider, Vector3.FORWARD * 12),
		"transition: finite width rejects invisible continuation beyond the sides")
	rider.position = Vector3(0, 0.022, 4)
	check.call(not rider.ride.try_enter(rider, Vector3.FORWARD * 12),
		"transition: ordinary approach ground does not become transition support at a distance")
	rider.position = Vector3(0, 1, -2)
	fixture.feature.surface_body.collision_layer = 0
	await _frames(tree, 2)
	var contact: Dictionary = fixture.feature.sample(0.6, 0.0)
	rider.position = contact.point + contact.normal * 0.022
	check.call(not rider.ride.try_enter(rider, contact.tangent * 6),
		"transition: an analytic surface without actual tagged collision cannot support the rider")
	fixture.feature.surface_body.collision_layer = 1
	await _frames(tree, 2)
	check.call(rider.ride.try_enter(rider, contact.tangent * 6),
		"transition: native collision restoration admits the same declared contact fixture")
	rider.ride.reset(rider)
	check.call(not rider.ride.active and rider.ride.air_feature == null
		and rider.get_node("BodyCollision").position.is_equal_approx(Vector3(0, 0.85, 0)),
		"transition: reset clears every associated state and restores the body collider")
	await _dispose(tree, fixture.root)


static func _obstruction(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 12.0)
	var obstruction := _box(Vector3(10, 2, 0.3), Vector3(0, 1, -1.2))
	fixture.root.add_child(obstruction)
	await _frames(tree, 2)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 45)
	check.call(rider.entries == 1 and rider.bails == 1 and rider.launches == 0,
		"transition: a real solid obstruction interrupts supported motion rather than passing through")
	check.call(rider.position.z > -1.1,
		"transition: interrupted native sweeps leave the rider on the near side of the obstacle")
	await _dispose(tree, fixture.root)


static func _transformed(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 12.0, Vector3(30, 5, 40), PI * 0.5)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 180)
	check.call(rider.entries == 1 and rider.launches == 1 and rider.landings == 1
		and rider.exits == 1 and rider.bails == 0,
		"transition: translated and yawed features retain true vertical launch and return")
	check.call(rider.position.z > 3.0 and absf(rider.position.x) < 0.05,
		"transition: transformed rollout follows the feature's actual local approach")
	await _dispose(tree, fixture.root)


static func _approach_variants(tree: SceneTree, check: Callable) -> void:
	for trial: Array in [[12.0, 0.0], [15.0, 0.0], [12.0, 15.0], [12.0, -15.0], [12.0, 30.0], [12.0, -30.0]]:
		var fixture := await _fixture(tree, trial[0])
		var rider: Rider = fixture.rider
		var angle: float = deg_to_rad(trial[1])
		# Declared initial placement and velocity on ordinary approach ground.
		rider.position = Vector3(-sin(angle) * 8.0, 0.022, cos(angle) * 8.0)
		rider.velocity = Vector3(sin(angle), 0, -cos(angle)) * float(trial[0])
		rider.running = true
		await _frames(tree, 210)
		print("APPROACH speed=%.1f angle=%.1f entry=%d launch=%d land=%d exit=%d bail=%d height=%.3f" % [trial[0], trial[1], rider.entries, rider.launches, rider.landings, rider.exits, rider.bails, rider.max_y])
		check.call(rider.entries == 1 and rider.bails == 0 and rider.launches >= 1,
			"transition: %.0fm/s %+.0f-degree approach enters from actual flat-ground travel" % [trial[0], trial[1]])
		check.call(rider.max_pitch > deg_to_rad(89.9) and rider.landings == 1 and rider.exits == 1,
			"transition: %.0fm/s %+.0f-degree approach completes the true vertical return" % [trial[0], trial[1]])
		await _dispose(tree, fixture.root)
	var fixture := await _fixture(tree, 6.0)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 8)
	rider.jump = true
	await _frames(tree, 1)
	check.call(rider.launches == 1 and rider.ride.state == "air",
		"transition: a deliberate early ollie leaves support through one launch")
	await _frames(tree, 4)
	check.call(rider.launches == 1 and rider.landings == 0,
		"transition: an upward ollie cannot snap back to its surface on the following frame")
	await _dispose(tree, fixture.root)
	fixture = await _fixture(tree, 8.0)
	rider = fixture.rider
	rider.position.x = -fixture.feature.width * 0.5 + 0.35
	rider.velocity = Vector3(-4, 0, -8)
	rider.running = true
	await _frames(tree, 40)
	check.call(rider.entries == 1 and rider.launches >= 1 and rider.position.x < -fixture.feature.width * 0.5
		and rider.bails == 0 and not rider.ride.active,
		"transition: lateral departure physically clears the finite side without invisible continuation")
	await _dispose(tree, fixture.root)


static func _surface_geometry(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	for angle: float in [0.5, 35.0, 55.0, 57.0, 80.0, 89.9]:
		var sample: Dictionary = fixture.feature.sample(deg_to_rad(angle), 0.0)
		var ray := PhysicsRayQueryParameters3D.create(sample.point + sample.normal * 0.10,
			sample.point - sample.normal * 0.08, 1)
		ray.exclude = [rider.get_rid()]
		var hit := rider.get_world_3d().direct_space_state.intersect_ray(ray)
		check.call(not hit.is_empty() and hit.collider == fixture.feature.surface_body
			and hit.position.distance_to(sample.point) < 0.001 and hit.normal.dot(sample.normal) > 0.999,
			"transition geometry: %.1f-degree visible sample matches native collision and its front normal" % angle)
	var contact: Dictionary = fixture.feature.sample(0.7, 0.0)
	rider.position = contact.point - contact.normal * 0.04
	check.call(not rider.ride.try_enter(rider, contact.tangent * 6),
		"transition: the back side cannot acquire through a thin collision face")
	# Verify ordinary support on the ramp landing and the rear deck, with enough
	# room to cross their common edge. No analytic quarter-pipe sample is involved.
	for point: Vector3 in [Vector3(fixture.feature.width * 0.5 + 2, fixture.feature.radius, -fixture.feature.radius - fixture.feature.deck_length + 1), Vector3(fixture.feature.width * 0.5 - 0.5, fixture.feature.radius, -fixture.feature.radius - fixture.feature.deck_length + 1)]:
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.15, point - Vector3.UP * 0.15, 1)
		ray.exclude = [rider.get_rid()]
		var hit := rider.get_world_3d().direct_space_state.intersect_ray(ray)
		check.call(not hit.is_empty() and hit.normal.y > 0.99 and hit.position.distance_to(point) < 0.002,
			"transition geometry: side roll-in landing and deck share a supported level crossover")
	await _dispose(tree, fixture.root)


static func _collision_loss(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	rider.held = true
	rider.running = true
	await _frames(tree, 50)
	fixture.feature.surface_body.collision_layer = 0
	await _frames(tree, 2)
	check.call(rider.bails == 1 and not rider.ride.active,
		"transition: removing actual coping support ends a held lip instead of floating")
	await _dispose(tree, fixture.root)
	fixture = await _fixture(tree, 4.0)
	rider = fixture.rider
	rider.running = true
	await _frames(tree, 8)
	fixture.feature.surface_body.collision_layer = 0
	await _frames(tree, 2)
	check.call(rider.bails == 1 and not rider.ride.active,
		"transition: removing curved collision during travel prevents analytic invisible support")
	await _dispose(tree, fixture.root)


static func _transfers(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 15.0)
	var rider: Rider = fixture.rider
	rider.push = 1.0
	rider.running = true
	for i in 60:
		await _frames(tree, 1)
		if rider.ride.state == "air": break
	await _frames(tree, 8)
	check.call(rider.launches == 1 and absf(rider.velocity.z) < 0.001,
		"transition transfer: held approach push retains the ordinary vertical air")
	rider.push = 0.0
	await _frames(tree, 1)
	var incoming_y: float = rider.velocity.y
	rider.push = 1.0
	await _frames(tree, 15)
	check.call(rider.velocity.z < -1.0 and rider.velocity.z >= -3.501 and rider.bails == 0,
		"transition transfer: a fresh push in air deliberately carries momentum over the rear deck")
	check.call(absf((incoming_y - rider.velocity.y) - 22.0 * 0.25) < 0.03,
		"transition transfer: directional input adds no vertical impulse or gravity reduction")
	await _frames(tree, 20)
	check.call(not rider.ride.active and rider.bails == 0 and rider.position.z < -fixture.feature.radius - 0.55,
		"transition transfer: actual deck clearance returns control to ordinary air")
	await _dispose(tree, fixture.root)
	fixture = await _fixture(tree, 12.0)
	rider = fixture.rider
	rider.running = true
	for i in 60:
		await _frames(tree, 1)
		if rider.ride.state == "air": break
	rider.brake = 1.0
	await _frames(tree, 16)
	check.call(rider.velocity.z > 1.0 and rider.velocity.z <= 3.501 and rider.bails == 0,
		"transition transfer: fresh brake input moves an airborne rider away from the coping")
	await _dispose(tree, fixture.root)
	fixture = await _fixture(tree, 12.0)
	rider = fixture.rider
	rider.running = true
	for i in 60:
		await _frames(tree, 1)
		if rider.ride.state == "air": break
	rider.steering = 1.0
	await _frames(tree, 12)
	check.call(rider.velocity.x > 0.5 and Vector2(rider.velocity.x, rider.velocity.z).length() <= 3.501,
		"transition transfer: steering can carve a purely vertical air with bounded lateral motion")
	await _dispose(tree, fixture.root)


static func _grind_handoff_clearance(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree, 15.0)
	var rider: Rider = fixture.rider
	rider.running = true
	for i in 60:
		await _frames(tree, 1)
		if rider.ride.state == "air": break
	await _frames(tree, 8)
	var collision: CollisionShape3D = rider.get_node("BodyCollision")
	var before: Transform3D = collision.transform
	var velocity: Vector3 = rider.velocity
	var line = fixture.feature.get_grind_lines()[0]
	var coping: Vector3 = line.point_at(line.length * 0.5)
	check.call(rider.ride.grind_path_clear(rider.global_position, coping, rider),
		"transition grind: prospective upright capture clears the actual coping and rear deck")
	check.call(rider.ride.active and rider.ride.state == "air" and collision.transform == before
		and rider.velocity == velocity,
		"transition grind: admission queries preserve associated air and collider until capture succeeds")
	check.call(not rider.ride.grind_path_clear(rider.global_position, coping - Vector3.UP * 0.3, rider),
		"transition grind: prospective upright overlap cannot capture through the solid deck")
	rider.ride.reset(rider)
	check.call(not rider.ride.active and rider.velocity == velocity
		and collision.position.is_equal_approx(Vector3(0, 0.85, 0)),
		"transition grind: successful caller handoff can restore upright collision without losing velocity")
	await _dispose(tree, fixture.root)



static func _fixture(tree: SceneTree, speed: float = 12.0,
		at: Vector3 = Vector3.ZERO, yaw: float = 0.0, radius: float = 2.4) -> Dictionary:
	var root := Node3D.new()
	root.name = "TransitionCollisionFixture"
	root.position = at
	root.rotation.y = yaw
	tree.root.add_child(root)
	var feature := TransitionFeature.new()
	feature.radius = radius
	root.add_child(feature)
	root.add_child(_box(Vector3(30, 0.5, 36), Vector3(0, -0.25, 8)))
	var rider := Rider.new()
	rider.name = "TransitionRider"
	rider.position = Vector3(0, 0.022, 0.05)
	rider.velocity = root.global_basis * Vector3.FORWARD * speed
	rider.collision_layer = 2
	rider.collision_mask = 1
	rider.floor_max_angle = deg_to_rad(56)
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.7
	capsule.radius = 0.28
	collision.shape = capsule
	collision.position.y = 0.85
	rider.add_child(collision)
	root.add_child(rider)
	await _frames(tree, 3)
	return {"root": root, "feature": feature, "rider": rider}


static func _box(size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body


static func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.physics_frame
		await tree.process_frame


static func _dispose(tree: SceneTree, root: Node) -> void:
	root.queue_free()
	await tree.process_frame
	await _frames(tree, 1)
