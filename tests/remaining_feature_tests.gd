extends RefCounted
## Standalone native-physics fixtures. Declared initial placement and motion are
## the only setup: feature admission, collision and completion remain production.

const ServiceGate = preload("res://game/features/service_gate.gd")
const SkateVehicle = preload("res://game/features/skate_vehicle.gd")
const SkitchRide = preload("res://game/player/skitch_ride.gd")
const LapChallenge = preload("res://game/features/lap_challenge.gd")
const ConeStunt = preload("res://game/features/cone_stunt.gd")
const Score = preload("res://game/scoring/score_session.gd")

class ActivityDriver extends CharacterBody3D:
	var desired := Vector3.ZERO
	var pop := false
	var interact := false
	var lap: Node3D
	var stunt: Node3D
	var score = Score.new()
	var airborne := false
	var pops := 0
	var landings := 0
	func _physics_process(delta: float) -> void:
		if is_on_floor():
			velocity.x = desired.x
			velocity.z = desired.z
			if desired.length() > 0.1: rotation.y = atan2(-desired.x,-desired.z)
			if pop:
				velocity.y = 8.8
				score.add_trick("Ollie",100,"ollie")
				pops += 1
				if is_instance_valid(lap): lap.on_launch(global_position)
		pop = false
		velocity.y -= 22.0*delta
		var was_air := airborne
		move_and_slide()
		airborne = not is_on_floor()
		if was_air and not airborne:
			landings += 1
			score.begin_landing()
			if is_instance_valid(lap): lap.on_landed(true)
			if is_instance_valid(stunt): stunt.on_landed(true)
		if is_instance_valid(lap): lap.poll(global_position,interact,delta,score.get_combo_value())
		if is_instance_valid(stunt): stunt.poll(global_position,interact,delta,score.get_combo_value(),self)
		interact = false
		var bank := score.tick(delta)
		if bank > 0 and is_instance_valid(stunt): stunt.on_bank(bank,global_position)

class Driver extends CharacterBody3D:
	var ride = SkitchRide.new()
	var vehicle: Node3D
	var request := false
	var attempted := false
	var held := true
	var jump := false
	var jump_impulse := 8.8
	var steer := 0.0
	var correct_balance := false
	var running := true
	var entries := 0
	var launches := 0
	var bails := 0
	var last_result: Dictionary = {}

	func _physics_process(delta: float) -> void:
		if not running: return
		ride.tick(delta)
		if request and not attempted:
			attempted = true
			if ride.try_start(self, vehicle): entries += 1
		if ride.active:
			var correction := -clampf(ride.balance * 5.0, -1.0, 1.0) if correct_balance else steer
			last_result = ride.step(self, delta, correction, jump, held, jump_impulse)
			jump = false
			if last_result.get("launched", false): launches += 1
			if last_result.get("bailed", false): bails += 1
		else:
			velocity.y -= 22.0 * delta
			move_and_slide()

class GateDriver extends Node:
	var gate: Node3D
	func _physics_process(delta: float) -> void:
		gate.tick(delta)


static func run(tree: SceneTree, check: Callable) -> void:
	await _gate_collision(tree, check)
	await _gate_safety(tree, check)
	await _vehicle_collision(tree, check)
	await _vehicle_geometry(tree, check)
	await _vehicle_people(tree, check)
	await _skitch_motion(tree, check)
	await _skitch_guards(tree, check)
	await _skitch_exits(tree, check)
	await _charged_skitch_exits(tree, check)
	await _lap_routes(tree, check)
	await _lap_lifecycle(tree, check)
	await _lap_late_pop(tree, check)
	await _cone_flight(tree, check)
	await _cone_guards(tree, check)
	await _cone_miss_recovery(tree, check)
	await _cone_rim_recovery(tree, check)


static func _gate_collision(tree: SceneTree, check: Callable) -> void:
	var fixture := await _gate_fixture(tree)
	var rider: Driver = fixture.rider
	var gate: Node3D = fixture.gate
	rider.velocity = Vector3.FORWARD * 5.0
	await _frames(tree, 65)
	check.call(rider.position.z > 0.38 and rider.position.z < 0.52 and absf(rider.velocity.z) < 0.01,
		"service gate: closed native shutter blocks a real approaching capsule")
	check.call(not gate.route_definition().enabled and not gate.status_snapshot().open,
		"service gate: map shortcut remains disabled while its collision is closed")
	check.call(gate.request_toggle(), "service gate: fresh request begins reversible opening")
	await _frames(tree, 80)
	check.call(gate.status_snapshot().open and gate.route_definition().enabled,
		"service gate: fully raised physical shutter enables its matching map route")
	rider.velocity = Vector3.FORWARD * 5.0
	await _frames(tree, 50)
	check.call(rider.position.z < -3.0 and rider.is_on_floor(),
		"service gate: native capsule actually traverses the opened doorway")
	check.call(gate.request_toggle(), "service gate: an unoccupied open doorway accepts close")
	await _frames(tree, 25)
	var partly_closed: float = gate.status_snapshot().progress
	check.call(partly_closed > 0.3 and partly_closed < 0.9 and not gate.route_definition().enabled,
		"service gate: a moving shutter disables the shortcut before it is fully closed")
	check.call(gate.request_toggle(), "service gate: a second request reverses a moving close")
	await _frames(tree, 40)
	check.call(gate.status_snapshot().open and gate.route_definition().enabled,
		"service gate: reversed motion returns collision and route to open together")
	gate.reset_run()
	check.call(gate.status_snapshot().progress == 0.0 and not gate.route_definition().enabled
		and not gate.status_snapshot().requested_open,
		"service gate: restart restores the original closed collision and route")
	await _dispose(tree, fixture.root)


static func _gate_safety(tree: SceneTree, check: Callable) -> void:
	var fixture := await _gate_fixture(tree, Vector3(0, 0.03, 0))
	var gate: Node3D = fixture.gate
	var rider: Driver = fixture.rider
	check.call(gate.request_toggle(), "service gate: opening remains available beside the player")
	await _frames(tree, 80)
	check.call(not gate.request_toggle() and gate.status_snapshot().blocked and gate.status_snapshot().requested_open,
		"service gate: native doorway sensor refuses to close over a grounded player")
	var open_at: Vector3 = gate.status_snapshot().collision_position
	await _frames(tree, 8)
	check.call(gate.status_snapshot().collision_position == open_at and rider.is_on_floor(),
		"service gate: refused close leaves the real panel raised without moving the player")
	rider.velocity = Vector3.BACK * 5.0
	await _frames(tree, 35)
	check.call(gate.request_toggle(), "service gate: leaving the sensor permits a later close")
	rider.velocity = Vector3.FORWARD * 5.0
	await _frames(tree, 30)
	var frozen: float = gate.status_snapshot().progress
	check.call(gate.status_snapshot().blocked and frozen > 0.0,
		"service gate: actual entry during closing freezes the shutter before a crush")
	rider.velocity = Vector3.ZERO
	await _frames(tree, 10)
	check.call(is_equal_approx(gate.status_snapshot().progress, frozen),
		"service gate: occupied doorway holds the physical closing position across frames")
	rider.velocity = Vector3.FORWARD * 5.0
	await _frames(tree, 55)
	check.call(gate.status_snapshot().progress < frozen and not gate.status_snapshot().blocked,
		"service gate: native sensor clearance allows the interrupted close to resume")
	await _dispose(tree, fixture.root)


static func _vehicle_collision(tree: SceneTree, check: Callable) -> void:
	var fixture := await _vehicle_fixture(tree, false)
	var vehicle: CharacterBody3D = fixture.vehicle
	var start: Vector3 = vehicle.global_position
	await _frames(tree, 80)
	check.call(vehicle.global_position.z < start.z - 2.0 and vehicle.speed > 3.5 and not vehicle.stopped,
		"service vehicle: native body accelerates and travels along its authored lane")
	check.call(vehicle.is_on_floor() and vehicle.global_position.y >= fixture.root.global_position.y - 0.03,
		"service vehicle: lane movement keeps real floor collision instead of teleporting")
	var blocker := _box("LaneObstacle", Vector3(4, 3, 0.4),
		Vector3(0, 1.5, vehicle.position.z - 4.0))
	fixture.root.add_child(blocker)
	await _frames(tree, 100)
	check.call(vehicle.stopped and vehicle.speed < 0.01 and vehicle.travel_velocity.length() < 0.01,
		"service vehicle: actual solid obstruction stops its native travel")
	check.call(vehicle.position.z > blocker.position.z + 1.9,
		"service vehicle: obstruction stop leaves the complete cart outside the obstacle")
	var at: Vector3 = vehicle.global_position
	vehicle.set_physics_process(false)
	await _frames(tree, 10)
	check.call(vehicle.global_position == at and vehicle.speed == 0.0,
		"service vehicle: paused processing consumes no route motion")
	vehicle.reset_run()
	check.call(vehicle.global_position.is_equal_approx(start) and vehicle.stopped and vehicle.speed == 0.0,
		"service vehicle: restart restores its authored start, heading and stopped state")
	vehicle.set_physics_process(true)
	await _frames(tree, 30)
	check.call(vehicle.global_position.z < start.z - 0.3 and not vehicle.stopped,
		"service vehicle: reset leaves the native route usable for the next run")
	vehicle.stop_run()
	var finished_at: Vector3 = vehicle.global_position
	await _frames(tree,6)
	check.call(vehicle.global_position == finished_at and vehicle.stopped and vehicle.speed == 0.0
		and vehicle.travel_velocity == Vector3.ZERO,
		"service vehicle: finishing a run stops native motion and clears stale tow readiness")
	vehicle.reset_run()
	vehicle.set_physics_process(true)
	await _frames(tree,20)
	check.call(vehicle.global_position.z < start.z-0.1 and not vehicle.stopped,
		"service vehicle: restart after finish restores its optional moving route")
	await _dispose(tree, fixture.root)


static func _skitch_motion(tree: SceneTree, check: Callable) -> void:
	var fixture := await _vehicle_fixture(tree)
	var rider: Driver = fixture.rider
	rider.request = true
	var start: Vector3 = rider.global_position
	await _frames(tree,1)
	check.call(rider.entries == 1 and rider.ride.active and not rider.ride.caught
		and rider.ride.hand_targets().is_empty() and rider.ride.elapsed == 0.0,
		"skitch: a forgiving far admission starts bounded attraction without a false handle catch")
	await _wait_caught(tree,rider)
	await _frames(tree,12)
	check.call(rider.entries == 1 and rider.ride.active and rider.last_result.get("reason") == "riding",
		"skitch: grounded aligned approach catches the actual moving rear anchor once")
	check.call(rider.global_position.z < start.z - 1.0 and rider.is_on_floor(),
		"skitch: native tow movement advances the real supported capsule")
	check.call(rider.global_position.distance_to(fixture.vehicle.get_skitch_anchor()) < 1.4
		and rider.global_position.distance_to(fixture.vehicle.global_position) > 2.0,
		"skitch: towing follows behind the cart without snapping inside its collision")
	var hands: Array[Vector3] = rider.ride.hand_targets()
	var grip := (hands[0]+hands[1])*0.5 if hands.size()==2 else Vector3.INF
	var handle: MeshInstance3D = fixture.vehicle.get_node("RearCatchBar")
	var local_grip := handle.to_local(grip)
	check.call(rider.ride.caught and hands.size()==2 and absf(local_grip.z-handle.mesh.get_aabb().size.z*0.5)<0.01
		and Vector2(grip.x-rider.global_position.x,grip.z-rider.global_position.z).length()<0.70
		and rider.ride.hand_normal().dot(fixture.vehicle.global_basis.z)>0.99,
		"skitch: caught palms target the actual rear bar surface within real crouched arm reach")
	var at: Vector3 = rider.global_position
	var elapsed: float = rider.ride.elapsed
	rider.set_physics_process(false)
	fixture.vehicle.set_physics_process(false)
	await _frames(tree, 8)
	check.call(rider.global_position == at and rider.ride.elapsed == elapsed,
		"skitch: pause freezes actual attachment motion and its duration")
	rider.set_physics_process(true)
	fixture.vehicle.set_physics_process(true)
	rider.held = false
	await _frames(tree, 1)
	check.call(not rider.ride.active and rider.last_result.get("reason") == "released"
		and rider.launches == 0 and rider.bails == 0 and rider.velocity.z < -3.0,
		"skitch: releasing Grind exits once with real retained forward momentum")
	check.call(rider.ride.cooldown > 0.65 and not rider.ride.try_start(rider, fixture.vehicle),
		"skitch: immediate release recapture is rejected by the finite cooldown")
	await _frames(tree, 45)
	check.call(rider.ride.cooldown == 0.0, "skitch: active unpaused time naturally expires reentry cooldown")
	rider.ride.reset()
	check.call(not rider.ride.active and rider.ride.cooldown == 0.0 and rider.ride.elapsed == 0.0
		and rider.ride.travel_velocity == Vector3.ZERO,
		"skitch: restart clears attachment, balance, clock and carried travel")
	await _dispose(tree, fixture.root)


static func _skitch_guards(tree: SceneTree, check: Callable) -> void:
	for kind: String in ["airborne", "far", "slow_rider", "opposite", "backwards", "slow_vehicle", "obstructed"]:
		var fixture := await _vehicle_fixture(tree, true, kind)
		var rider: Driver = fixture.rider
		rider.request = true
		await _frames(tree, 1)
		check.call(rider.entries == 0 and not rider.ride.active,
			"skitch: %s native approach cannot manufacture attachment" % kind)
		await _dispose(tree, fixture.root)


static func _skitch_exits(tree: SceneTree, check: Callable) -> void:
	for kind: String in ["ollie", "balance", "vehicle_stopped", "time"]:
		var fixture := await _vehicle_fixture(tree)
		var rider: Driver = fixture.rider
		rider.request = true
		rider.correct_balance = kind == "time"
		await _frames(tree, 3)
		await _wait_caught(tree,rider)
		check.call(rider.entries == 1 and rider.ride.active and rider.ride.caught,
			"skitch: %s exit fixture first earns real moving attachment" % kind)
		match kind:
			"ollie":
				var y: float = rider.global_position.y
				rider.jump = true
				await _frames(tree, 1)
				check.call(rider.launches == 1 and not rider.ride.active and rider.last_result.get("reason") == "ollie"
					and rider.velocity.y > 8.0 and rider.global_position.y > y,
					"skitch: deliberate Ollie releases into actual upward native movement")
			"balance":
				rider.steer = 1.0
				await _frames(tree, 50)
				check.call(rider.bails == 1 and not rider.ride.active and rider.last_result.get("reason") == "balance",
					"skitch: sustained uncorrected steering reaches exactly one balance bail")
			"vehicle_stopped":
				fixture.root.add_child(_box("TowLaneObstacle", Vector3(4, 3, 0.4),
					Vector3(0, 1.5, fixture.vehicle.position.z - 3.0)))
				await _frames(tree, 70)
				check.call(fixture.vehicle.stopped and not rider.ride.active
					and rider.last_result.get("reason") == "vehicle_stopped" and rider.bails == 0,
					"skitch: actual cart obstruction releases its tow without a fabricated balance bail")
			"time":
				await _frames(tree, 365)
				check.call(not rider.ride.active and rider.last_result.get("reason") == "time"
					and rider.bails == 0 and rider.launches == 0,
					"skitch: a corrected real tow releases at its finite six-second duration")
		await _dispose(tree, fixture.root)


static func _base(tree: SceneTree) -> Node3D:
	var root := Node3D.new()
	root.name = "RemainingFeatureNativeFixture"
	tree.root.add_child(root)
	root.position = Vector3(2000, 100, 2000)
	root.add_child(_box("Floor", Vector3(60, 1, 140), Vector3(0, -0.5, -35)))
	return root

static func _vehicle_people(tree: SceneTree, check: Callable) -> void:
	var fixture := await _vehicle_fixture(tree,false)
	await _frames(tree,75)
	var pedestrian := _rider(Vector3(0,0.03,fixture.vehicle.position.z-4.5))
	fixture.root.add_child(pedestrian)
	await _frames(tree,90)
	check.call(fixture.vehicle.stopped and fixture.vehicle.speed<0.05
		and fixture.vehicle.position.z>pedestrian.position.z+2.0,
		"service vehicle: native pedestrian safety volume stops before a real floor-level rider")
	await _dispose(tree,fixture.root)
	fixture = await _vehicle_fixture(tree,false)
	await _frames(tree,135)
	var roof_hit := _cart_ray(fixture.vehicle,Vector3(0,0,-0.55))
	var top_rider := _rider(Vector3(roof_hit.position)-fixture.root.global_position+Vector3.UP*0.03)
	fixture.root.add_child(top_rider)
	await _frames(tree,8)
	var start: Vector3 = fixture.vehicle.global_position
	var regular_motion := true
	for frame in 24:
		var before: Vector3 = fixture.vehicle.global_position
		await _frames(tree,1)
		var real_speed := Vector2(fixture.vehicle.global_position.x-before.x,fixture.vehicle.global_position.z-before.z).length()*60.0
		regular_motion = regular_motion and real_speed>5.5 and absf(real_speed-fixture.vehicle.travel_velocity.length())<0.05
	check.call(top_rider.is_on_floor() and not fixture.vehicle.stopped and regular_motion
		and fixture.vehicle.global_position.z<start.z-2.0,
		"service vehicle: a supported roof rider preserves native cart travel and truthful measured platform velocity")
	await _dispose(tree,fixture.root)

static func _vehicle_geometry(tree: SceneTree, check: Callable) -> void:
	var fixture := await _vehicle_fixture(tree,false)
	await _frames(tree,5)
	var vehicle: CharacterBody3D = fixture.vehicle
	var cab_hit := _cart_ray(vehicle,Vector3(0,0,-0.55))
	var bed_hit := _cart_ray(vehicle,Vector3(0,0,1.0))
	var shoulder_hit := _cart_ray(vehicle,Vector3(0.70,0,-0.55))
	check.call(not cab_hit.is_empty() and absf(vehicle.to_local(cab_hit.position).y-1.57)<0.002
		and not bed_hit.is_empty() and absf(vehicle.to_local(bed_hit.position).y-0.96)<0.002
		and not shoulder_hit.is_empty() and absf(vehicle.to_local(shoulder_hit.position).y-0.96)<0.002,
		"service vehicle: native roof rays match visible cab and bed heights without an invisible enclosing roof")
	var wheel_count := 0
	var boxes_match := true
	for child: Node in vehicle.get_children():
		if not child is CollisionShape3D: continue
		if child.shape is BoxShape3D:
			var visual: MeshInstance3D = vehicle.get_node("Cab" if child.name=="CabCollision" else "ServiceCartBody")
			boxes_match = boxes_match and child.position.is_equal_approx(visual.position) \
				and child.shape.size.is_equal_approx(visual.mesh.size)
		elif child.shape is CylinderShape3D:
			wheel_count += 1
			var matched := false
			for mesh: Node in vehicle.get_children():
				if mesh is MeshInstance3D and mesh.mesh is CylinderMesh and mesh.position.is_equal_approx(child.position):
					matched = mesh.rotation.is_equal_approx(child.rotation) and is_equal_approx(mesh.mesh.height,child.shape.height) \
						and is_equal_approx(mesh.mesh.top_radius,child.shape.radius)
			boxes_match = boxes_match and matched
	check.call(boxes_match and wheel_count==4,
		"service vehicle: both boxes and all four native wheel cylinders coincide with their actual visible meshes")
	var wheel_hit := _cart_ray(vehicle,Vector3(0.78,0,1.0))
	check.call(not wheel_hit.is_empty() and absf(vehicle.to_local(wheel_hit.position).y-0.61)<0.002
		and absf(vehicle.global_position.y+0.01-fixture.root.global_position.y)<0.04,
		"service vehicle: actual wheel contact supplies ground support with only the native collision skin")
	await _dispose(tree,fixture.root)

static func _cart_ray(vehicle: CharacterBody3D, local: Vector3) -> Dictionary:
	var at := vehicle.to_global(local)
	return vehicle.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*4.0,at-Vector3.UP*2.0,8))

static func _wait_caught(tree: SceneTree, rider: Driver) -> void:
	for frame in 60:
		if rider.ride.caught or not rider.ride.active: return
		await _frames(tree,1)

static func _charged_skitch_exits(tree: SceneTree, check: Callable) -> void:
	for charge: Dictionary in [{"input":11.0,"expected":11.0}, {"input":99.0,"expected":12.0},
		{"input":-20.0,"expected":3.0}, {"input":NAN,"expected":8.8}]:
		var fixture := await _vehicle_fixture(tree)
		var rider: Driver = fixture.rider
		rider.request = true
		await _frames(tree,3)
		await _wait_caught(tree,rider)
		var attached: bool = rider.ride.active and rider.ride.caught and rider.entries == 1
		rider.jump_impulse = float(charge.input)
		rider.jump = true
		await _frames(tree,1)
		check.call(attached and rider.launches == 1 and not rider.ride.active
			and absf(rider.velocity.y-float(charge.expected)) < 0.01,
			"skitch: actual release uses bounded charged impulse %s without changing default exit behavior" % str(charge.input))
		await _dispose(tree,fixture.root)

static func _lap_routes(tree: SceneTree, check: Callable) -> void:
	for branch_index in 2:
		var fixture := await _lap_fixture(tree)
		var rider: ActivityDriver = fixture.rider
		var lap: Node3D = fixture.lap
		rider.interact = true
		await _frames(tree,1)
		check.call(lap.status_snapshot().state == "active" and lap.status_snapshot().attempts == 1
			and lap.status_snapshot().navigation_targets.size()==2,
			"park lap: settled native rider accepts route %d and receives both first-gate navigation choices" % branch_index)
		var points: PackedVector3Array = lap.status_snapshot().branches[branch_index].points
		var reached := true
		var correct_navigation := true
		for index in points.size():
			if index == 1: rider.pop = true
			reached = await _drive_activity(tree,rider,points[index]) and reached
			var targets: Array = lap.status_snapshot().navigation_targets
			correct_navigation = correct_navigation and targets.size()==1 \
				and Vector3(targets[0].position).distance_to(points[index+1] if index+1<points.size() else fixture.anchor)<0.01
		var finish_text: String = lap.status_snapshot().hud_text
		reached = await _drive_activity(tree,rider,fixture.anchor) and reached
		rider.desired = Vector3.ZERO
		await _frames(tree,3)
		check.call(reached and correct_navigation and finish_text.contains("FINISH") and lap.status_snapshot().state == "success"
			and lap.status_snapshot().branch == branch_index and lap.status_snapshot().wins == 1
			and rider.pops == 1 and rider.landings >= 1 and rider.is_on_floor(),
			"park lap: actual native traversal of branch %d, a physical pop/landing and return finish once" % branch_index)
		var wins: int = lap.status_snapshot().wins
		await _frames(tree,15)
		check.call(lap.status_snapshot().wins == wins and rider.score.total_score == 100,
			"park lap: repeated finish polling gives no duplicate reward or invented score")
		await _dispose(tree,fixture.root)

static func _lap_lifecycle(tree: SceneTree, check: Callable) -> void:
	var fixture := await _lap_fixture(tree)
	var rider: ActivityDriver = fixture.rider
	var lap: Node3D = fixture.lap
	rider.interact = true
	await _frames(tree,1)
	var points: PackedVector3Array = lap.status_snapshot().branches[0].points
	await _drive_activity(tree,rider,points[0])
	await _drive_activity(tree,rider,points[3])
	rider.desired = Vector3.ZERO
	check.call(lap.status_snapshot().state == "failed" and lap.status_snapshot().wins == 0,
		"park lap: actual out-of-order arrival at a later gate fails instead of skipping required traversal")
	await _drive_activity(tree,rider,fixture.anchor)
	rider.desired = Vector3.ZERO
	rider.interact = true
	await _frames(tree,1)
	check.call(lap.status_snapshot().state == "active" and lap.status_snapshot().attempts == 2,
		"park lap: a physical return accepts retry without a stale gate index")
	var remaining: float = lap.status_snapshot().remaining
	tree.paused = true
	await _frames(tree,12)
	check.call(lap.status_snapshot().remaining == remaining,
		"park lap: real paused scene processing freezes its deadline")
	tree.paused = false
	await _frames(tree,4505)
	check.call(lap.status_snapshot().state == "failed" and lap.status_snapshot().remaining == 0.0
		and lap.status_snapshot().wins == 0,
		"park lap: native unpaused physics time expires a stationary attempt without an unearned finish")
	lap.reset_run()
	check.call(lap.status_snapshot().state == "idle" and lap.status_snapshot().attempts == 0
		and lap.status_snapshot().wins == 0,
		"park lap: restart clears route, timing and session-only results")
	await _dispose(tree,fixture.root)

static func _lap_late_pop(tree: SceneTree, check: Callable) -> void:
	var fixture := await _lap_fixture(tree)
	var rider: ActivityDriver = fixture.rider
	var lap: Node3D = fixture.lap
	var shared_label := ""
	for mark: Node in lap.get_children():
		if mark is Node3D and mark.has_node("PaintedGate") and mark.position.is_equal_approx(Vector3(-6,0,4)):
			shared_label = mark.get_node("ActivitySign").text
	check.call(shared_label.contains("1 · LEFT LOOP") and shared_label.contains("4 · RIGHT LOOP"),
		"park lap: a shared physical gate displays both route names and their actual ordinal numbers")
	rider.interact = true
	await _frames(tree,1)
	for target: Vector3 in lap.status_snapshot().branches[0].points:
		await _drive_activity(tree,rider,target)
	await _drive_activity(tree,rider,fixture.anchor)
	rider.desired = Vector3.ZERO
	await _frames(tree,2)
	check.call(lap.status_snapshot().state=="active" and lap.status_snapshot().reason.contains("Land a real pop")
		and lap.status_snapshot().navigation_targets.size()==1 and lap.status_snapshot().hud_text.contains("FINISH"),
		"park lap: completing gates without a pop keeps the attempt active and directs the rider to the finish")
	await _drive_activity(tree,rider,fixture.anchor+Vector3.BACK*6.0,3.0)
	rider.desired = Vector3.ZERO
	rider.pop = true
	await _frames(tree,2)
	for frame in 90:
		await _frames(tree,1)
		if not rider.airborne: break
	await _drive_activity(tree,rider,fixture.anchor)
	rider.desired = Vector3.ZERO
	await _frames(tree,2)
	check.call(rider.pops==1 and rider.is_on_floor() and lap.status_snapshot().state=="success"
		and lap.status_snapshot().wins==1 and lap.status_snapshot().reason.is_empty()
		and lap.status_snapshot().hud_text=="ONE MORE LAP · CLEAN FINISH"
		and lap.status_snapshot().navigation_targets.is_empty(),
		"park lap: a real late pop, clean landing and return replace the stale instruction with one successful finish")
	await _dispose(tree,fixture.root)

static func _cone_flight(tree: SceneTree, check: Callable) -> void:
	var fixture := await _cone_fixture(tree)
	var rider: ActivityDriver = fixture.rider
	var stunt: Node3D = fixture.stunt
	var centre_query := PhysicsRayQueryParameters3D.create(stunt.status_snapshot().target-Vector3.BACK,
		stunt.status_snapshot().target+Vector3.BACK,4,[stunt.cone.get_rid()])
	var edge_query := PhysicsRayQueryParameters3D.create(stunt.status_snapshot().target+Vector3.RIGHT*1.20-Vector3.BACK,
		stunt.status_snapshot().target+Vector3.RIGHT*1.20+Vector3.BACK,4,[stunt.cone.get_rid()])
	var rim_hit := stunt.get_world_3d().direct_space_state.intersect_ray(edge_query)
	check.call(stunt.get_world_3d().direct_space_state.intersect_ray(centre_query).is_empty()
		and not rim_hit.is_empty() and rim_hit.collider.name=="NativeTargetRim",
		"cone cruise: native target torus blocks its visible rim while the actual central aperture stays clear")
	rider.interact = true
	await _frames(tree,1)
	check.call(stunt.status_snapshot().state == "active" and stunt.cone.freeze,
		"cone cruise: a settled physical offer starts with the real foam body in its cradle")
	rider.desired = Vector3.BACK*6.5
	for frame in 100:
		await _frames(tree,1)
		if rider.global_position.z >= fixture.launch.z-3.1: break
	rider.pop = true
	rider.interact = true
	await _frames(tree,2)
	check.call(stunt.status_snapshot().launched and not stunt.cone.freeze and rider.airborne
		and stunt.cone.linear_velocity.z > 6.5 and stunt.cone.linear_velocity.y > 5.0,
		"cone cruise: actual moving pop applies an impulse to a native RigidBody rather than awarding a button success")
	var moved_from: Vector3 = stunt.cone.global_position
	await _frames(tree,12)
	check.call(stunt.cone.global_position.z > moved_from.z+1.0 and not stunt.status_snapshot().target_hit,
		"cone cruise: visible native flight advances before the target can qualify")
	var paused_at: Vector3 = stunt.cone.global_position
	var paused_remaining: float = stunt.status_snapshot().remaining
	tree.paused = true
	await _frames(tree,12)
	check.call(stunt.cone.global_position.is_equal_approx(paused_at)
		and stunt.status_snapshot().remaining == paused_remaining,
		"cone cruise: actual pause freezes native projectile flight and the attempt timer")
	tree.paused = false
	for frame in 150:
		await _frames(tree,1)
		if not rider.airborne: rider.desired = Vector3.ZERO
		if stunt.status_snapshot().state != "active": break
	var outcome: Dictionary = stunt.status_snapshot()
	print("CONE HULL OUTCOME ",outcome)
	check.call(outcome.state == "success" and outcome.target_hit and outcome.raft_landed
		and outcome.landed and outcome.banked and outcome.wins == 1
		and rider.score.total_score == 100 and rider.is_on_floor(),
		"cone cruise: real ring crossing, physical raft contact, native player landing and bank earn one session win")
	check.call(outcome.target_hit and outcome.crossed_vertices==outcome.hull_vertices
		and outcome.aperture_clear and not outcome.rim_hit,
		"cone cruise: the complete native cone, base and band clear the ring before target credit")
	await _frames(tree,20)
	check.call(stunt.status_snapshot().wins == 1 and rider.score.total_score == 100,
		"cone cruise: repeated target/raft polling never duplicates the win or awards extra score")
	stunt.reset_run()
	check.call(stunt.status_snapshot().state == "idle" and stunt.cone.freeze
		and stunt.cone.global_position.distance_to(fixture.launch+Vector3.UP*0.52)<0.01,
		"cone cruise: restart physically restores the recoverable prop and clears its result")
	await _dispose(tree,fixture.root)

static func _cone_guards(tree: SceneTree, check: Callable) -> void:
	var fixture := await _cone_fixture(tree)
	var rider: ActivityDriver = fixture.rider
	var stunt: Node3D = fixture.stunt
	rider.interact = true
	await _frames(tree,1)
	await _drive_activity(tree,rider,fixture.launch-Vector3.BACK*2.5,2.0)
	rider.desired = Vector3.BACK*2.0
	rider.pop = true
	rider.interact = true
	await _frames(tree,2)
	check.call(rider.airborne and rider.pops == 1 and not stunt.status_snapshot().launched
		and stunt.cone.freeze and stunt.status_snapshot().wins == 0,
		"cone cruise: a real low-speed pop cannot launch the mascot or invent target progress")
	stunt.cancel_attempt()
	await _frames(tree,2)
	check.call(stunt.status_snapshot().state == "failed" and stunt.status_snapshot().wins == 0,
		"cone cruise: cancelling an incomplete physical attempt cannot produce a reward")
	stunt.reset_run()
	check.call(stunt.status_snapshot().attempts == 0 and not stunt.status_snapshot().target_hit,
		"cone cruise: restart removes old trajectory and landing evidence")
	await _dispose(tree,fixture.root)

static func _cone_miss_recovery(tree: SceneTree, check: Callable) -> void:
	var fixture := await _cone_fixture(tree)
	var rider: ActivityDriver = fixture.rider
	var stunt: Node3D = fixture.stunt
	rider.interact = true
	await _frames(tree,1)
	rider.desired = Vector3.BACK*6.5
	for frame in 100:
		await _frames(tree,1)
		if rider.global_position.z >= fixture.launch.z-3.1: break
	# This legal glancing approach still has to aim the physical cone. Its own
	# lateral impulse makes a real miss; no target/success state is assigned.
	rider.desired = Vector3(2.2,0,6.5)
	rider.pop = true
	rider.interact = true
	await _frames(tree,2)
	check.call(stunt.status_snapshot().launched and stunt.cone.linear_velocity.x > 1.5,
		"cone cruise: an admitted off-centre native approach retains its actual lateral aim")
	for frame in 420:
		await _frames(tree,1)
		if not rider.airborne: rider.desired = Vector3.ZERO
		if stunt.status_snapshot().state == "failed" and not stunt.status_snapshot().recovering: break
	check.call(stunt.status_snapshot().state == "failed" and not stunt.status_snapshot().target_hit
		and stunt.status_snapshot().wins == 0 and stunt.cone.freeze
		and stunt.cone.global_position.distance_to(fixture.launch+Vector3.UP*0.52)<0.01,
		"cone cruise: a real missed ring fails without reward and visibly recovers the foam body to its cradle")
	await _drive_activity(tree,rider,fixture.launch+Vector3(0,0,-8))
	rider.desired = Vector3.ZERO
	rider.interact = true
	await _frames(tree,1)
	check.call(stunt.status_snapshot().state == "active" and stunt.status_snapshot().attempts == 2
		and not stunt.status_snapshot().target_hit and not stunt.status_snapshot().launched,
		"cone cruise: physical return after a recovered miss permits a clean retry")
	await _dispose(tree,fixture.root)

static func _cone_rim_recovery(tree: SceneTree, check: Callable) -> void:
	var fixture := await _cone_fixture(tree)
	var rider: ActivityDriver = fixture.rider
	var stunt: Node3D = fixture.stunt
	rider.interact = true
	await _frames(tree,1)
	rider.desired = Vector3.BACK*6.5
	for frame in 100:
		await _frames(tree,1)
		if rider.global_position.z>=fixture.launch.z-3.1: break
	rider.desired = Vector3(1.0,0,6.5)
	rider.pop = true
	rider.interact = true
	await _frames(tree,2)
	var launched: bool = stunt.status_snapshot().launched
	for frame in 420:
		await _frames(tree,1)
		if not rider.airborne: rider.desired = Vector3.ZERO
		if stunt.status_snapshot().state=="failed" and not stunt.status_snapshot().recovering: break
	var result: Dictionary = stunt.status_snapshot()
	check.call(launched and result.rim_hit and not result.target_hit and result.wins==0,
		"cone cruise: an actual near-rim hull collision cannot score from its centre-only trajectory")
	check.call(result.state=="failed" and stunt.cone.freeze
		and stunt.cone.global_position.distance_to(fixture.launch+Vector3.UP*0.52)<0.01,
		"cone cruise: a clipped native rim fails and physically recovers for a retry")
	await _dispose(tree,fixture.root)

static func _lap_fixture(tree: SceneTree) -> Dictionary:
	var root := _base(tree)
	var anchor := root.global_position+Vector3(0,0,10)
	var first := PackedVector3Array()
	var second := PackedVector3Array()
	for at: Vector3 in [Vector3(-6,0,4),Vector3(-6,0,-8),Vector3(6,0,-8),Vector3(6,0,4)]: first.append(root.global_position+at)
	for at: Vector3 in [Vector3(6,0,4),Vector3(6,0,-12),Vector3(-6,0,-12),Vector3(-6,0,4)]: second.append(root.global_position+at)
	var lap := LapChallenge.new()
	root.add_child(lap)
	lap.configure(anchor,[{"id":"left","label":"Left loop","points":first},{"id":"right","label":"Right loop","points":second}],Rect2(root.position.x-20,root.position.z-20,40,40))
	var rider := _activity_rider(Vector3(0,0.03,10))
	rider.lap = lap
	root.add_child(rider)
	await _frames(tree,4)
	return {"root":root,"lap":lap,"rider":rider,"anchor":anchor}

static func _cone_fixture(tree: SceneTree) -> Dictionary:
	var root := Node3D.new()
	root.name = "NativeRiverStuntFixture"
	tree.root.add_child(root)
	root.position = Vector3(2000,100,2000)
	root.add_child(_box("Quay",Vector3(30,1,34),Vector3(0,-0.5,-13)))
	var launch := root.global_position
	var stunt := ConeStunt.new()
	root.add_child(stunt)
	stunt.configure(launch+Vector3(0,0,-8),launch,launch+Vector3(0,-0.8,6),launch+Vector3(0,-3.9,8))
	var rider := _activity_rider(Vector3(0,0.03,-8))
	rider.stunt = stunt
	root.add_child(rider)
	await _frames(tree,4)
	return {"root":root,"stunt":stunt,"rider":rider,"launch":launch}

static func _activity_rider(at: Vector3) -> ActivityDriver:
	var rider := ActivityDriver.new()
	rider.position = at
	rider.collision_layer = 2
	rider.collision_mask = 1 | 8
	rider.floor_snap_length = 0.25
	rider.safe_margin = 0.015
	var shape := CapsuleShape3D.new()
	shape.radius = 0.30
	shape.height = 1.70
	var collision := CollisionShape3D.new()
	collision.position.y = 0.85
	collision.shape = shape
	rider.add_child(collision)
	return rider

static func _drive_activity(tree: SceneTree, rider: ActivityDriver, target: Vector3, pace: float = 6.0) -> bool:
	for frame in 360:
		var offset := target-rider.global_position
		offset.y = 0.0
		if offset.length()<0.6:
			rider.desired = Vector3.ZERO
			return true
		rider.desired = offset.normalized()*pace
		await _frames(tree,1)
	return false


static func _gate_fixture(tree: SceneTree, at := Vector3(0, 0.03, 4)) -> Dictionary:
	var root := _base(tree)
	var gate := ServiceGate.new()
	root.add_child(gate)
	gate.configure(root.global_position, PackedVector3Array([root.global_position + Vector3.BACK * 4,
		root.global_position + Vector3.FORWARD * 4]))
	var ticker := GateDriver.new()
	ticker.gate = gate
	root.add_child(ticker)
	var rider := _rider(at)
	root.add_child(rider)
	await _frames(tree, 3)
	return {"root": root, "gate": gate, "rider": rider}


static func _vehicle_fixture(tree: SceneTree, with_rider := true, kind := "") -> Dictionary:
	var root := _base(tree)
	var vehicle := SkateVehicle.new()
	root.add_child(vehicle)
	vehicle.configure(PackedVector3Array([root.global_position + Vector3(0, 0.025, 20),
		root.global_position + Vector3(0, 0.025, -65)]))
	var result := {"root": root, "vehicle": vehicle}
	if not with_rider: return result
	await _frames(tree, 10 if kind == "slow_vehicle" else 75)
	var at: Vector3 = vehicle.get_skitch_anchor() - root.global_position + Vector3(0, 0.025, 0.9)
	if kind == "far": at.z += 3.0
	if kind == "airborne": at.y += 1.3
	var rider := _rider(at)
	rider.vehicle = vehicle
	rider.velocity = Vector3.FORWARD * (0.4 if kind == "slow_rider" else 3.0)
	if kind == "opposite": rider.velocity = Vector3.BACK * 3.0
	if kind == "backwards": rider.rotation.y = PI
	root.add_child(rider)
	if kind == "obstructed":
		root.add_child(_box("CatchObstruction", Vector3(1.2, 2.0, 0.10),
			Vector3(at.x, 1.0, at.z - 0.52)))
	# Wheel support puts the cart origin slightly above its lane. Let the
	# separately placed rider genuinely fall onto that floor before admission.
	await _frames(tree, 6)
	result["rider"] = rider
	return result


static func _rider(at: Vector3) -> Driver:
	var rider := Driver.new()
	rider.name = "NativeRider"
	rider.position = at
	rider.collision_layer = 2
	rider.collision_mask = 1 | 8
	rider.floor_snap_length = 0.25
	rider.safe_margin = 0.015
	var shape := CapsuleShape3D.new()
	shape.radius = 0.30
	shape.height = 1.70
	var collision := CollisionShape3D.new()
	collision.position.y = 0.85
	collision.shape = shape
	rider.add_child(collision)
	return rider


static func _box(label: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	body.collision_layer = 1
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	return body


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame


static func _dispose(tree: SceneTree, root: Node) -> void:
	root.queue_free()
	await _frames(tree, 2)
