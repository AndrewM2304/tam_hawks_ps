extends RefCounted
## Actual native collision fixtures. Setup places the fixture/body once; every
## subsequent contact, ride, release and obstruction uses CharacterBody3D motion.

const WallRide = preload("res://game/player/wall_ride.gd")

class Rider extends CharacterBody3D:
	var ride = WallRide.new()
	var running := false
	var request := true
	var attempted := false
	var held := true
	var jump := false
	var steering := 0.0
	var entries := 0
	var bails := 0
	var launches := 0
	var last_result: Dictionary = {}

	func _physics_process(delta: float) -> void:
		if not running:
			return
		ride.tick(delta)
		if not ride.active and request and not attempted:
			attempted = true
			if ride.try_start(self, velocity):
				entries += 1
		if ride.active:
			last_result = ride.step(self, delta, steering, jump, held)
			jump = false
			if last_result.bailed: bails += 1
			if last_result.launched: launches += 1
		else:
			velocity.y -= 22.0 * delta
			move_and_slide()


static func run(tree: SceneTree, check: Callable) -> void:
	await _actual_ride(tree, check)
	await _wallie(tree, check)
	await _duration_and_edges(tree, check)
	await _entry_rejections(tree, check)
	await _obstruction(tree, check)
	await _destroy_and_reset(tree, check)
	await _lost_contact_jump(tree, check)
	await _invalid_step(tree, check)
	_surface_rules(check)


static func _actual_ride(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	var start: Vector3 = rider.global_position
	rider.running = true
	await _frames(tree, 24)
	check.call(rider.entries == 1 and rider.ride.active and rider.last_result.reason == "riding",
		"wallride: actual glancing side approach enters one physical wall ride")
	check.call(rider.global_position.z < start.z - 2.5
		and rider.global_position.x >= fixture.root.global_position.x + 0.47,
		"wallride: native tangent travel advances without penetrating the solid wall")
	check.call(rider.ride.normal.dot(Vector3.RIGHT) > 0.99
		and rider.ride.wall_id.ends_with("ArchitectureWall"),
		"wallride: retained normal and identity come from the real contacted wall")
	check.call(absf(rider.velocity.x) < 0.05 and rider.velocity.z < -6.0,
		"wallride: collision resolves inward support while preserving useful tangent velocity")
	check.call(rider.velocity.y < 0.0 and rider.velocity.y > -4.0,
		"wallride: explicitly reduced gravity descends rather than creating a vertical climb")
	var value: Vector3 = rider.global_position
	var elapsed: float = rider.ride.elapsed
	var clock: float = rider.ride.cooldown
	rider.set_physics_process(false)
	await _frames(tree, 8)
	check.call(rider.global_position == value and rider.ride.elapsed == elapsed and rider.ride.cooldown == clock,
		"wallride: freezing physics consumes neither ride time, cooldown nor motion")
	rider.set_physics_process(true)
	rider.held = false
	await _frames(tree, 1)
	check.call(not rider.ride.active and rider.last_result.reason == "released" and rider.ride.cooldown > 0.30,
		"wallride: releasing the held action exits once with a reentry cooldown")
	check.call(rider.velocity.x > 0.5 and rider.velocity.z < -6.0 and rider.launches == 0,
		"wallride: ordinary release carries tangent momentum outward without a jump award")
	check.call(not rider.ride.try_start(rider, Vector3(-1, 0, -8)) and rider.entries == 1,
		"wallride: immediate recapture cannot bypass the attachment cooldown")
	await _dispose(tree, fixture.root)


static func _wallie(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 8)
	var before: Vector3 = rider.global_position
	rider.jump = true
	await _frames(tree, 1)
	check.call(rider.launches == 1 and not rider.ride.active and rider.last_result.reason == "wallie",
		"wallride: a deliberate wallie releases exactly once through the actual physics step")
	check.call(rider.velocity.x > 4.0 and rider.velocity.y > 7.0 and rider.velocity.z < -7.0,
		"wallride: wallie combines outward kick and upward launch with retained tangent momentum")
	check.call(rider.global_position.x > before.x and rider.global_position.y > before.y,
		"wallride: the launched capsule actually moves clear of its wall")
	await _frames(tree, 4)
	check.call(rider.entries == 1 and rider.launches == 1 and rider.ride.cooldown > 0.0,
		"wallride: held input after a wallie cannot create another capture or launch")
	await _dispose(tree, fixture.root)


static func _duration_and_edges(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 83)
	check.call(not rider.ride.active and rider.last_result.reason == "time" and rider.entries == 1,
		"wallride: an indefinitely held ride releases at its finite 1.25-second bound")
	check.call(rider.global_position.z < fixture.root.global_position.z + 3.0 and rider.bails == 0,
		"wallride: duration expiry follows real travel and does not fabricate a bail")
	await _dispose(tree, fixture.root)
	fixture = await _fixture(tree, Vector3(-1.2, 0, -8), 4.0)
	rider = fixture.rider
	rider.position.z = 1.0 # Declared initial fixture placement only.
	rider.running = true
	await _frames(tree, 35)
	check.call(rider.entries == 1 and not rider.ride.active and rider.last_result.reason == "edge",
		"wallride: finite wall endpoint releases without wrapping or invisible support")
	check.call(rider.global_position.z < fixture.root.global_position.z - 2.0,
		"wallride: the rider physically leaves the wall endpoint")
	await _dispose(tree, fixture.root)
	fixture = await _fixture(tree)
	rider = fixture.rider
	rider.running = true
	await _frames(tree, 3)
	rider.steering = 1.0
	await _frames(tree, 1)
	check.call(not rider.ride.active and rider.last_result.reason == "steer_away" and rider.velocity.x > 1.0,
		"wallride: steering away provides a deliberate lateral exit")
	await _dispose(tree, fixture.root)


static func _entry_rejections(tree: SceneTree, check: Callable) -> void:
	for request: Array in [
		[Vector3(-8, 0, 0), "head-on"], [Vector3(-0.2, 0, -2), "slow"],
		[Vector3(3, 0, -8), "outward"], [Vector3(-1, NAN, -8), "nonfinite"],
	]:
		var fixture := await _fixture(tree, request[0])
		var rider: Rider = fixture.rider
		# Reject invalid motion before it can be sent to native move_and_slide.
		if request[1] == "nonfinite":
			check.call(not rider.ride.try_start(rider, request[0]),
				"wallride: nonfinite entry velocity cannot create support")
		else:
			rider.running = true
			await _frames(tree, 3)
			check.call(rider.entries == 0 and not rider.ride.active,
				"wallride: %s approach retains ordinary collision instead of capturing" % request[1])
		await _dispose(tree, fixture.root)
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	fixture.wall.set_meta("no_wallride", true)
	rider.running = true
	await _frames(tree, 4)
	check.call(rider.entries == 0, "wallride: explicitly excluded wall cannot capture through actual probes")
	await _dispose(tree, fixture.root)
	fixture = await _fixture(tree)
	rider = fixture.rider
	var floor := _box("Floor", Vector3(20, 1, 40), Vector3(0, 7.5, 0))
	fixture.root.add_child(floor)
	rider.velocity = Vector3.ZERO
	rider.request = false
	rider.running = true
	await _frames(tree, 12)
	check.call(rider.is_on_floor(), "wallride: floor rejection fixture has actual grounded support")
	rider.velocity = Vector3(-1, 0, -8)
	rider.request = true
	await _frames(tree, 1)
	check.call(rider.entries == 0, "wallride: grounded contact cannot manufacture an airborne wall ride")
	await _dispose(tree, fixture.root)


static func _obstruction(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	var block := _box("ForwardBlock", Vector3(4, 24, 0.4), Vector3(1.5, 8, 7.0))
	block.set_meta("no_wallride", true)
	fixture.root.add_child(block)
	rider.running = true
	await _frames(tree, 50)
	check.call(rider.entries == 1 and rider.bails == 1 and rider.last_result.reason == "obstruction",
		"wallride: a real obstruction ends support with one failure result")
	check.call(rider.global_position.z >= fixture.root.global_position.z + 7.45 and absf(rider.velocity.z) < 0.05,
		"wallride: actual impact blocks travel and discarded momentum is never restored")
	await _dispose(tree, fixture.root)


static func _destroy_and_reset(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 3)
	fixture.wall.queue_free()
	await _frames(tree, 3)
	check.call(not rider.ride.active and rider.last_result.reason == "edge" and rider.bails == 0,
		"wallride: removed wall releases its weak reference without ghost support or a false bail")
	rider.ride.reset()
	check.call(not rider.ride.active and rider.ride.normal == Vector3.ZERO and rider.ride.wall_id.is_empty()
		and rider.ride.elapsed == 0.0 and rider.ride.cooldown == 0.0 and rider.ride.travel_velocity == Vector3.ZERO,
		"wallride: reset clears all contact, travel and cooldown state")
	rider.ride.cooldown = 0.30
	rider.ride.tick(NAN)
	rider.ride.tick(-1)
	check.call(is_equal_approx(rider.ride.cooldown, 0.30), "wallride: invalid clock samples do not shorten cooldown")
	rider.ride.tick(0.35)
	check.call(rider.ride.cooldown == 0.0, "wallride: a real elapsed cooldown reopens future eligibility")
	await _dispose(tree, fixture.root)


static func _surface_rules(check: Callable) -> void:
	var wall := _box("StoneArchitecture", Vector3(0.4, 4, 8), Vector3.ZERO)
	check.call(WallRide.is_surface_eligible(wall), "wallride: substantial solid architecture is eligible by default")
	wall.set_meta("wallrideable", false)
	check.call(not WallRide.is_surface_eligible(wall), "wallride: explicit false eligibility excludes architecture")
	wall.set_meta("wallrideable", true)
	wall.set_meta("no_wallride", true)
	check.call(not WallRide.is_surface_eligible(wall), "wallride: explicit no-wallride wins over an allow tag")
	wall.remove_meta("no_wallride")
	wall.set_meta("surface_audio", "glass")
	check.call(not WallRide.is_surface_eligible(wall), "wallride: glass is excluded even with an allow tag")
	wall.free()
	for request: Array in [["LowFence", Vector3(0.2, 1.0, 8)], ["TinyProp", Vector3(0.5, 2, 0.5)],
		["WaterBoundary", Vector3(0.4, 4, 8)], ["CanvasCanopy", Vector3(0.4, 4, 8)]]:
		var prop := _box(request[0], request[1], Vector3.ZERO)
		check.call(not WallRide.is_surface_eligible(prop), "wallride: scenery exclusion %s is honest" % request[0])
		prop.free()
	var dynamic := RigidBody3D.new()
	check.call(not WallRide.is_surface_eligible(dynamic), "wallride: moving bodies cannot masquerade as static walls")
	dynamic.free()
	var scaled := _box("ScaledArchitecture", Vector3(0.4, 1, 8), Vector3.ZERO)
	scaled.scale.y = 2.0
	check.call(WallRide.is_surface_eligible(scaled),
		"wallride: detached surface audits account for ancestor scale without global-transform errors")
	scaled.free()
	var turned := _box("TurnedArchitecture", Vector3(0.4, 8, 4), Vector3.ZERO)
	turned.rotation_degrees.x = 90.0
	check.call(WallRide.is_surface_eligible(turned),
		"wallride: architecture eligibility measures actual world dimensions after rotation")
	turned.free()


static func _lost_contact_jump(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 3)
	# Change only the real collision object's eligibility, never helper state.
	# A simultaneous jump must not manufacture a wallie after support disappears.
	fixture.wall.set_meta("no_wallride", true)
	rider.jump = true
	await _frames(tree, 1)
	check.call(rider.entries == 1 and rider.launches == 0 and not rider.ride.active
		and rider.last_result.reason == "edge" and rider.velocity.y < 0.0,
		"wallride: wallie requires contact still eligible on the actual launch frame")
	await _dispose(tree, fixture.root)


static func _invalid_step(tree: SceneTree, check: Callable) -> void:
	var fixture := await _fixture(tree)
	var rider: Rider = fixture.rider
	rider.running = true
	await _frames(tree, 3)
	rider.running = false
	var before: Vector3 = rider.global_position
	var result: Dictionary = rider.ride.step(rider, NAN)
	check.call(not result.active and result.bailed and result.reason == "invalid"
		and rider.global_position == before and rider.ride.cooldown == WallRide.REENTRY_SECONDS,
		"wallride: invalid integration time ends support without sending invalid native motion")
	await _dispose(tree, fixture.root)


static func _fixture(tree: SceneTree, motion := Vector3(-1.2, 0, -8), length: float = 40.0) -> Dictionary:
	var root := Node3D.new()
	root.name = "WallRideFixture"
	root.position = Vector3(1000, 100, 1000)
	tree.root.add_child(root)
	var wall := _box("ArchitectureWall", Vector3(0.4, 24, length), Vector3(0, 8, 0))
	root.add_child(wall)
	var rider := Rider.new()
	rider.name = "Rider"
	rider.position = Vector3(0.65, 8, 12)
	rider.collision_layer = 2
	rider.collision_mask = 1
	rider.safe_margin = 0.015
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.85
	rider.add_child(collision)
	root.add_child(rider)
	rider.velocity = motion
	await _frames(tree, 2)
	return {"root": root, "wall": wall, "rider": rider}


static func _box(label: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body


static func _dispose(tree: SceneTree, node: Node) -> void:
	node.queue_free()
	await tree.process_frame
	await _frames(tree, 1)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
