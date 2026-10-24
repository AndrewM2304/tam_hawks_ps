extends RefCounted
## Standalone native-physics fixtures. Declared initial placement and motion are
## the only setup: feature admission, collision and completion remain production.

const ServiceGate = preload("res://game/features/service_gate.gd")
const SkateVehicle = preload("res://game/features/skate_vehicle.gd")
const SkitchRide = preload("res://game/player/skitch_ride.gd")
const LapChallenge = preload("res://game/features/lap_challenge.gd")
const ConeStunt = preload("res://game/features/cone_stunt.gd")
const Score = preload("res://game/scoring/score_session.gd")
static var _main_observer := Callable()
static var _main_game: Node
static var _main_phase := ""
static var _main_step := 0

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
	var walk := Vector3.INF
	var releases := 0

	func _physics_process(delta: float) -> void:
		if not running: return
		ride.tick(delta)
		if request and not attempted:
			attempted = true
			if ride.try_start(self, vehicle): entries += 1
		if ride.active:
			var correction := -clampf(ride.balance * 5.0, -1.0, 1.0) if correct_balance else steer
			last_result = ride.step(self, delta, correction, jump, held, jump_impulse)
			if not ride.active: releases += 1
			jump = false
			if last_result.get("launched", false): launches += 1
			if last_result.get("bailed", false): bails += 1
		else:
			if walk.is_finite():
				velocity.x = walk.x
				velocity.z = walk.z
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
	await _vehicle_vertical_stability(tree, check)
	await _vehicle_people(tree, check)
	await _vehicle_endpoint_turn(tree, check)
	await _vehicle_turn_blockers(tree, check)
	await _vehicle_roof_wait(tree, check)
	await _vehicle_endpoint_tow(tree, check)
	await _skitch_motion(tree, check)
	await _skitch_guards(tree, check)
	await _skitch_exits(tree, check)
	await _charged_skitch_exits(tree, check)
	await _lap_routes(tree, check)
	await _lap_lifecycle(tree, check)
	await _lap_late_pop(tree, check)
	await _lap_facility_regions(tree, check)
	await _cone_flight(tree, check)
	await _cone_guards(tree, check)
	await _cone_miss_recovery(tree, check)
	await _cone_rim_recovery(tree, check)

static func run_main(tree: SceneTree, game: Node, check: Callable, observer: Callable = Callable()) -> void:
	# No player/vehicle pose or motion injection: a normal Main restart starts
	# the complete authored trip. Its idle avatar remains at the existing spawn.
	var original_free: bool = game.free_skate_mode
	for action: String in ["push","brake","steer_left","steer_right","ollie","flip","grab","grind",
		"manual","revert","spin_left","spin_right","interact","special_one","special_two"]:
		Input.action_release(action)
	_main_observer = observer
	_main_game = game
	_main_phase = ""
	_main_step = 0
	game.start_mode(true)
	var cart: CharacterBody3D = game.feature_hub.vehicle
	var path: PackedVector3Array = cart.status_snapshot().path
	var initial_heading: float = cart.rotation.y
	var arrived := false
	var began_turn := false
	for frame in 1000:
		await _main_frames(tree,1)
		if not arrived and cart.status_snapshot().phase=="rest":
			arrived = cart.stopped and cart.global_position.distance_to(path[1])<0.35
			_main_phase = "cart_parked_turn"
			_main_step = 0
		if cart.status_snapshot().phase=="turning":
			began_turn = true
			break
	check.call(arrived and began_turn and game.score.total_score==0 and game.score.get_combo_value()==0,
		"remaining Main: an empty cart completes its native trip and begins a clear parked turn without player or vehicle pose injection")
	var parked: Vector3 = cart.global_position
	var heading: float = cart.rotation.y
	game.toggle_pause()
	await _main_frames(tree,8)
	check.call(cart.rotation.y==heading and cart.global_position==parked,
		"remaining Main: pausing freezes the actual endpoint turn and native cart position")
	game.toggle_pause()
	var bounded := arrived and began_turn
	var largest_step := 0.0
	var largest_rate := 0.0
	for frame in 250:
		var before_yaw: float = cart.rotation.y
		var before_at: Vector3 = cart.global_position
		var tick := Engine.get_physics_frames()
		await _main_frames(tree,1)
		var step := absf(angle_difference(before_yaw,cart.rotation.y))
		var elapsed := float(maxi(1,Engine.get_physics_frames()-tick))/float(Engine.physics_ticks_per_second)
		largest_step = maxf(largest_step,step)
		largest_rate = maxf(largest_rate,step/elapsed)
		bounded = bounded and step<=SkateVehicle.TURN_RATE*elapsed+0.0001
		if cart.status_snapshot().phase=="cruise": break
		bounded = bounded and cart.stopped and cart.global_position.distance_to(before_at)<0.001
	await _main_frames(tree,35)
	var return_direction := (path[0]-path[1]).normalized()
	print("MAIN CART TURN peak_sample_deg=%.6f peak_rate_deg=%.6f phase=%s travel=%s"%[
		rad_to_deg(largest_step),rad_to_deg(largest_rate),cart.status_snapshot().phase,cart.travel_velocity])
	check.call(bounded and not cart.stopped and cart.travel_velocity.dot(return_direction)>1.5
		and absf(angle_difference(initial_heading,cart.rotation.y))>PI-0.001,
		"remaining Main: the native parked turn stays within its angular rate and resumes the existing return lane")
	# Restart is outside the observed clip; its authored reset is separately
	# checked and restores the caller's mode without changing its spawn.
	_main_phase = ""
	game.start_mode(original_free)
	await _main_frames(tree,1)
	var status: Dictionary = cart.status_snapshot()
	check.call(not status.turning and status.turn_blocked.is_empty() and status.wait==0.0
		and status.phase=="cruise" and cart.global_position.distance_to(path[0])<0.08,
		"remaining Main: restart clears the old endpoint rotation and native safety holds")
	await _lap_native_paint(tree,game,check)
	_main_observer = Callable()
	_main_game = null

static func _lap_native_paint(tree: SceneTree, game: Node, check: Callable) -> void:
	await _frames(tree,2)
	var lap: Node3D = game.feature_hub.park_lap
	var space := lap.get_world_3d().direct_space_state
	var checked := 0
	for mark: Node3D in lap._markers:
		var paint: MeshInstance3D = mark.get_node("PaintedGate")
		var ready := paint.mesh is ArrayMesh and paint.mesh.get_surface_count()==1
		if not ready:
			check.call(false,"park paint: every actual gate has a native-fitted paint mesh at %s"%mark.global_position)
			continue
		var arrays: Array = paint.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var finite := vertices.size()>1000 and indices.size()>3000
		var vertex_low := INF
		var vertex_high := -INF
		var interior_low := INF
		var interior_high := -INF
		var outer := 0.0
		var inner := INF
		var longest := 0.0
		for vertex: Vector3 in vertices:
			var at := paint.to_global(vertex)
			var height := _paint_ground(space,at)
			finite = finite and vertex.is_finite() and is_finite(height)
			var gap := at.y-height
			vertex_low = minf(vertex_low,gap)
			vertex_high = maxf(vertex_high,gap)
			var radius := Vector2(vertex.x,vertex.z).length()
			outer = maxf(outer,radius)
			inner = minf(inner,radius)
		for index in range(0,indices.size(),3):
			var a := paint.to_global(vertices[indices[index]])
			var b := paint.to_global(vertices[indices[index+1]])
			var c := paint.to_global(vertices[indices[index+2]])
			longest = maxf(longest,maxf(a.distance_to(b),maxf(b.distance_to(c),c.distance_to(a))))
			# Independent interior samples also catch a triangle chord that floats
			# or cuts into a terrain seam despite correct endpoint heights.
			for weights: Vector3 in [Vector3(1.0/3.0,1.0/3.0,1.0/3.0),Vector3(0.6,0.2,0.2),Vector3(0.2,0.6,0.2),Vector3(0.2,0.2,0.6)]:
				var at := a*weights.x+b*weights.y+c*weights.z
				var height := _paint_ground(space,at)
				finite = finite and is_finite(height)
				interior_low = minf(interior_low,at.y-height)
				interior_high = maxf(interior_high,at.y-height)
		print("PARK PAINT at=%s vertices=%d triangles=%d vertex_mm=[%.3f,%.3f] interior_mm=[%.3f,%.3f] edge=%.5f skipped=%d"%[
			mark.global_position,vertices.size(),indices.size()/3,vertex_low*1000.0,vertex_high*1000.0,
			interior_low*1000.0,interior_high*1000.0,longest,paint.get_meta("paint_skipped_triangles",-1)])
		check.call(finite and vertex_low>0.0085 and vertex_high<0.0095 and interior_low>0.006 and interior_high<0.012,
			"park paint: actual gate %s vertices and triangle interiors stay on native ground with a thin paint skin"%mark.global_position)
		check.call(absf(outer-LapChallenge.GATE_RADIUS)<0.001 and inner>1.1 and longest<0.14
			and mark.find_children("*","CollisionObject3D",true,false).is_empty(),
			"park paint: actual gate %s is a fine hollow ring with chevrons and no added collision"%mark.global_position)
		checked += 1
	check.call(checked==9,"park paint: all nine distinct gates across both unchanged real park routes are audited")

static func _paint_ground(space: PhysicsDirectSpaceState3D, at: Vector3) -> float:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.20,at-Vector3.UP*0.20,1))
	return Vector3(hit.position).y if not hit.is_empty() else NAN

## Actual-world binding checks complement the continuous native-driver visit
## fixtures and the independent production-skater facility journey.
static func run_park_regions_main(tree: SceneTree, game: Node, check: Callable) -> void:
	await _frames(tree,2)
	var facility: Dictionary = {}
	if game.world.has_method("get_park_skatepark_definition"):
		facility = game.world.get_park_skatepark_definition()
	var available := facility.get("bounds") is Rect2 and facility.get("access_bounds") is Rect2 \
		and is_finite(float(facility.get("rim_y",NAN)))
	check.call(available,"park lap Main: the real installed facility publishes its exact bounds, access and rim datum")
	if not available: return
	var lap: Node3D = game.feature_hub.park_lap
	var bounds: Rect2 = facility.bounds
	var access: Rect2 = facility.access_bounds
	var regions: Array = lap.status_snapshot().attempt_regions
	var original := Rect2(-225,-190,90,125)
	check.call(regions.size()==3 and regions[0]==original
		and regions.has(bounds.grow(LapChallenge.ATTEMPT_BODY_MARGIN))
		and regions.has(access.grow(LapChallenge.ATTEMPT_BODY_MARGIN)),
		"park lap Main: FeatureHub retains the original attempt area and binds only the declared facility/access regions")
	var outside_original := 0
	for x_fraction: float in [0.025,0.50,0.90]:
		for z_fraction: float in [0.10,0.50,0.90]:
			var at := Vector3(lerpf(bounds.position.x,bounds.end.x,x_fraction),float(facility.rim_y),
				lerpf(bounds.position.y,bounds.end.y,z_fraction))
			var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*6.0,at-Vector3.UP*20.0,1)
			var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(ray)
			var supported: bool = not hit.is_empty() and Vector3(hit.position).is_finite()
			if not original.has_point(Vector2(at.x,at.z)): outside_original += 1
			check.call(supported and lap.is_in_attempt_area(Vector3(hit.position) if supported else Vector3.INF),
				"park lap Main: actual native facility support at %s stays inside the permitted lap area"%at)
	var unrelated := Vector3(bounds.position.x+0.10,0,original.end.y-1.0)
	check.call(outside_original>=3 and not lap.is_in_attempt_area(unrelated),
		"park lap Main: the real extension covers new park ground without admitting unrelated bounding-box corners")

static func _main_frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
		_main_step += 1
		if _main_observer.is_valid() and not _main_phase.is_empty():
			await _main_observer.call(_main_phase,_main_game,_main_step)


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

static func _turn_fixture(tree: SceneTree) -> Dictionary:
	var root := _base(tree)
	var cart := SkateVehicle.new()
	root.add_child(cart)
	cart.configure(PackedVector3Array([root.global_position+Vector3(0,0.025,10),root.global_position+Vector3(0,0.025,-10)]))
	return {"root":root,"vehicle":cart}

static func _wait_cart_phase(tree: SceneTree, cart: CharacterBody3D, phase: String, limit := 900) -> bool:
	for frame in limit:
		if cart.status_snapshot().phase == phase: return true
		await _frames(tree,1)
	return false

static func _vehicle_endpoint_turn(tree: SceneTree, check: Callable) -> void:
	var fixture := await _turn_fixture(tree)
	var cart: CharacterBody3D = fixture.vehicle
	var start: Vector3 = cart.global_position
	var initial_heading: float = cart.rotation.y
	var arrived := await _wait_cart_phase(tree,cart,"turning")
	var parked: Vector3 = cart.global_position
	var bounded := arrived
	for frame in 35:
		var yaw: float = cart.rotation.y
		await _frames(tree,1)
		bounded = bounded and cart.stopped and cart.travel_velocity==Vector3.ZERO \
			and cart.global_position.distance_to(parked)<0.001 \
			and absf(angle_difference(yaw,cart.rotation.y))<=SkateVehicle.TURN_RATE/60.0+0.0001
	check.call(bounded and absf(angle_difference(initial_heading,cart.rotation.y))>0.3,
		"service vehicle: an empty endpoint turns smoothly while parked instead of rotating its cab in one frame")
	var frozen_yaw: float = cart.rotation.y
	var frozen_wait: float = cart.status_snapshot().wait
	tree.paused = true
	await _frames(tree,8)
	check.call(cart.rotation.y==frozen_yaw and cart.global_position==parked and cart.status_snapshot().wait==frozen_wait,
		"service vehicle: native endpoint turn and wait remain still while the world is paused")
	tree.paused = false
	await _frames(tree,3)
	check.call(absf(angle_difference(frozen_yaw,cart.rotation.y))>0.01,
		"service vehicle: resuming the world continues the bounded parked turn")
	cart.reset_run()
	check.call(cart.global_position==start and is_equal_approx(cart.rotation.y,initial_heading)
		and not cart.status_snapshot().turning and cart.status_snapshot().turn_blocked.is_empty()
		and cart.status_snapshot().wait==0.0 and cart.speed==0.0,
		"service vehicle: reset during a turn clears its pending rotation, safety hold and endpoint wait")
	await _wait_cart_phase(tree,cart,"turning")
	await _wait_cart_phase(tree,cart,"cruise")
	await _frames(tree,40)
	print("CART TURN RETURN stopped=%s speed=%.6f z=%.6f endpoint=%.6f yaw=%.8f initial=%.8f phase=%s"%[cart.stopped,cart.speed,cart.global_position.z,parked.z,cart.rotation.y,initial_heading,cart.status_snapshot().phase])
	check.call(not cart.stopped and cart.speed>1.5 and cart.global_position.z>parked.z+0.4
		and absf(angle_difference(initial_heading,cart.rotation.y))>PI-0.001,
		"service vehicle: the complete clear native turn resumes the original return lane and acceleration")
	await _dispose(tree,fixture.root)

static func _native_cart_overlap(cart: CharacterBody3D, other: CollisionObject3D) -> bool:
	for child: Node in cart.get_children():
		if not child is CollisionShape3D: continue
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = child.shape
		query.transform = child.global_transform
		query.collision_mask = other.collision_layer
		query.exclude = [cart.get_rid()]
		for hit: Dictionary in cart.get_world_3d().direct_space_state.intersect_shape(query,16):
			if hit.collider == other: return true
	return false

static func _vehicle_turn_blockers(tree: SceneTree, check: Callable) -> void:
	for person: bool in [false,true]:
		var fixture := await _turn_fixture(tree)
		var cart: CharacterBody3D = fixture.vehicle
		await _wait_cart_phase(tree,cart,"rest")
		var obstacle: CollisionObject3D
		if person:
			var pedestrian := _rider(cart.position+Vector3(1.65,0.025,0))
			pedestrian.walk = Vector3.ZERO
			obstacle = pedestrian
		else:
			obstacle = _box("EndpointTurnWall",Vector3(0.20,2.0,0.20),cart.position+Vector3(1.45,1.0,0))
		fixture.root.add_child(obstacle)
		var clear := not _native_cart_overlap(cart,obstacle)
		var blocked := false
		for frame in 360:
			await _frames(tree,1)
			clear = clear and not _native_cart_overlap(cart,obstacle)
			if cart.status_snapshot().phase=="waiting_space":
				blocked = true
				break
		var stopped_yaw: float = cart.rotation.y
		await _frames(tree,30)
		check.call(clear and blocked and cart.stopped and is_equal_approx(stopped_yaw,cart.rotation.y)
			and cart.get_node("ActivitySign").text.contains("WAITING FOR SPACE"),
			"service vehicle: the actual six-shape turn sweep waits outside a native %s with a visible status"%["person" if person else "wall"])
		obstacle.queue_free()
		await _frames(tree,2)
		await _wait_cart_phase(tree,cart,"cruise")
		await _frames(tree,35)
		check.call(not cart.stopped and cart.speed>1.5 and absf(angle_difference(0.0,cart.rotation.y))>PI-0.001,
			"service vehicle: removing the native %s safely resumes the interrupted turn and original route"%["person" if person else "wall"])
		await _dispose(tree,fixture.root)

static func _vehicle_roof_wait(tree: SceneTree, check: Callable) -> void:
	var fixture := await _turn_fixture(tree)
	var cart: CharacterBody3D = fixture.vehicle
	await _frames(tree,135)
	var hit := _cart_ray(cart,Vector3(0,0,-0.55))
	var passenger := _rider(Vector3(hit.position)-fixture.root.global_position+Vector3.UP*0.025)
	passenger.walk = Vector3.ZERO
	fixture.root.add_child(passenger)
	await _wait_cart_phase(tree,cart,"rest")
	var parked: Vector3 = cart.global_position
	var yaw: float = cart.rotation.y
	var supported := true
	var low := INF
	var high := -INF
	for frame in 330:
		await _frames(tree,1)
		var feet := cart.to_local(passenger.global_position)
		low = minf(low,feet.y)
		high = maxf(high,feet.y)
		supported = supported and passenger.is_on_floor() and absf(feet.x)<0.64 and absf(feet.z+0.55)<0.30
	check.call(supported and high-low<0.002 and cart.stopped and cart.global_position==parked
		and is_equal_approx(cart.rotation.y,yaw) and cart.status_snapshot().phase=="waiting_rider"
		and cart.get_node("ActivitySign").text.contains("PLEASE STEP OFF"),
		"service vehicle: an actual supported roof passenger keeps both roofs parked after the endpoint wait")
	passenger.walk = Vector3.RIGHT*3.0
	await _frames(tree,15)
	check.call(passenger.global_position.x>parked.x+0.6,
		"service vehicle: the roof passenger leaves through native walking without any rider position snap")
	await _wait_cart_phase(tree,cart,"cruise")
	await _frames(tree,35)
	check.call(not cart.stopped and cart.speed>1.5 and cart.global_position.z>parked.z+0.25,
		"service vehicle: stepping clear releases the roof safety hold and allows the parked turn to finish")
	await _dispose(tree,fixture.root)

static func _vehicle_endpoint_tow(tree: SceneTree, check: Callable) -> void:
	var fixture := await _turn_fixture(tree)
	var cart: CharacterBody3D = fixture.vehicle
	await _frames(tree,135)
	var rider := _rider(cart.get_skitch_anchor()-fixture.root.global_position+Vector3(0,0.025,0.20))
	rider.vehicle = cart
	rider.velocity = Vector3.FORWARD*6.0
	rider.correct_balance = true
	fixture.root.add_child(rider)
	await _frames(tree,6)
	rider.request = true
	await _frames(tree,1)
	await _wait_caught(tree,rider)
	var caught: bool = rider.ride.caught
	await _wait_cart_phase(tree,cart,"rest")
	await _frames(tree,2)
	print("CART ENDPOINT TOW caught=%s entries=%d releases=%d active=%s result=%s bails=%d launches=%d phase=%s"%[caught,rider.entries,rider.releases,rider.ride.active,rider.last_result,rider.bails,rider.launches,cart.status_snapshot().phase])
	check.call(caught and rider.entries==1 and rider.releases==1 and not rider.ride.active
		and rider.last_result.get("reason")=="vehicle_stopped" and rider.bails==0 and rider.launches==0,
		"skitch: native endpoint parking releases one real tow once without a false bail or launch")
	await _frames(tree,330)
	check.call(rider.entries==1 and rider.releases==1 and not rider.ride.active and rider.bails==0 and rider.launches==0,
		"skitch: waiting and turning cannot duplicate its released tow or invent another accepted trick")
	await _dispose(tree,fixture.root)

static func _cart_ray(vehicle: CharacterBody3D, local: Vector3) -> Dictionary:
	var at := vehicle.to_global(local)
	return vehicle.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*4.0,at-Vector3.UP*2.0,8))

static func _vehicle_vertical_stability(tree: SceneTree, check: Callable) -> void:
	for occupied: bool in [false,true]:
		var fixture := await _vehicle_fixture(tree,false)
		var cart: CharacterBody3D = fixture.vehicle
		await _frames(tree,135)
		var rider: Driver
		if occupied:
			var hit := _cart_ray(cart,Vector3(0,0,-0.55))
			rider = _rider(Vector3(hit.position)-fixture.root.global_position+Vector3.UP*0.035)
			fixture.root.add_child(rider)
			await _frames(tree,12)
		var lowest := INF
		var highest := -INF
		var lowest_passenger := INF
		var highest_passenger := -INF
		var supported := true
		var largest_vertical_velocity := 0.0
		for frame in 120:
			await _frames(tree,1)
			lowest = minf(lowest,cart.global_position.y)
			highest = maxf(highest,cart.global_position.y)
			largest_vertical_velocity = maxf(largest_vertical_velocity,absf(cart.get_real_velocity().y))
			supported = supported and cart.is_on_floor() and not cart.stopped
			if is_instance_valid(rider):
				supported = supported and rider.is_on_floor()
				var relative: float = rider.global_position.y-cart.global_position.y
				lowest_passenger = minf(lowest_passenger,relative)
				highest_passenger = maxf(highest_passenger,relative)
		var passenger_range := highest_passenger-lowest_passenger if occupied else 0.0
		print("CART VERTICAL occupied=%s amplitude=%.8f velocity=%.8f passenger=%.8f"%[occupied,highest-lowest,largest_vertical_velocity,passenger_range])
		check.call(supported and highest-lowest<0.001 and largest_vertical_velocity<0.06 and passenger_range<0.002,
			"service vehicle:120 actual cruise frames keep flat-lane wheel support stable without30Hz jitter, occupied=%s"%occupied)
		await _dispose(tree,fixture.root)

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

static func _lap_facility_regions(tree: SceneTree, check: Callable) -> void:
	for branch_index in 2:
		var fixture := await _lap_fixture(tree)
		var rider: ActivityDriver = fixture.rider
		var lap: Node3D = fixture.lap
		var before: Array = lap.status_snapshot().branches.duplicate(true)
		var site := Rect2(Vector2(fixture.root.global_position.x-29,fixture.root.global_position.z-35),Vector2(12,12))
		var access := Rect2(Vector2(fixture.root.global_position.x-21,fixture.root.global_position.z-26),Vector2(6,9))
		lap.set_attempt_regions([site,access])
		rider.interact = true
		await _frames(tree,1)
		# A declared physical extension of the same native floor is reached by
		# actual continuous capsule travel, without skipping a numbered gate.
		for at: Vector3 in [Vector3(-16,0,10),Vector3(-16,0,-18),Vector3(-18,0,-24),Vector3(-23,0,-29)]:
			await _drive_activity(tree,rider,fixture.root.global_position+at)
		rider.desired = Vector3.ZERO
		check.call(rider.is_on_floor() and lap.status_snapshot().state=="active"
			and lap.status_snapshot().branch==-1 and lap.status_snapshot().remaining>0.0,
			"park lap: branch %d keeps its active attempt through native traversal of the added facility and access"%branch_index)
		rider.pop = true
		await _frames(tree,2)
		for frame in 90:
			await _frames(tree,1)
			if not rider.airborne: break
		await _frames(tree,24)
		check.call(rider.pops==1 and rider.is_on_floor() and lap.status_snapshot().landed_pop
			and lap.status_snapshot().state=="active" and rider.score.total_score==100,
			"park lap: a real pop and clean landing in the permitted facility qualify normally without failing the attempt")
		for at: Vector3 in [Vector3(-18,0,-24),Vector3(-16,0,-18),Vector3(-16,0,10),Vector3(0,0,10)]:
			await _drive_activity(tree,rider,fixture.root.global_position+at)
		for target: Vector3 in lap.status_snapshot().branches[branch_index].points:
			await _drive_activity(tree,rider,target)
		await _drive_activity(tree,rider,fixture.anchor)
		rider.desired = Vector3.ZERO
		await _frames(tree,2)
		check.call(lap.status_snapshot().state=="success" and lap.status_snapshot().wins==1
			and lap.status_snapshot().branch==branch_index and lap.status_snapshot().branches==before
			and rider.score.total_score==100,
			"park lap: visiting the native facility preserves original branch %d order, clean finish and once-only score"%branch_index)
		await _dispose(tree,fixture.root)
	var fixture := await _lap_fixture(tree)
	var lap: Node3D = fixture.lap
	var rider: ActivityDriver = fixture.rider
	var site := Rect2(Vector2(fixture.root.global_position.x-29,fixture.root.global_position.z-35),Vector2(12,12))
	var access := Rect2(Vector2(fixture.root.global_position.x-21,fixture.root.global_position.z-26),Vector2(6,9))
	lap.set_attempt_regions([site,access])
	rider.interact = true
	await _frames(tree,1)
	await _drive_activity(tree,rider,fixture.root.global_position+Vector3(-25,0,10))
	rider.desired = Vector3.ZERO
	check.call(lap.status_snapshot().state=="failed" and lap.status_snapshot().wins==0 and rider.score.total_score==0,
		"park lap: an unrelated corner of the facility bounding rectangle remains outside the allowed park union")
	lap.reset_run()
	check.call(lap.is_in_attempt_area(fixture.root.global_position+Vector3(-29.3,0,-29))
		and not lap.is_in_attempt_area(fixture.root.global_position+Vector3(-29.5,0,-29))
		and lap.status_snapshot().attempt_regions.size()==3,
		"park lap: restart preserves only declared extra park areas with a bounded body margin")
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
