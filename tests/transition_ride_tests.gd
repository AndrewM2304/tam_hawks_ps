extends RefCounted
## Finite contact/energy checks plus one real generated-mesh ray-support fixture.
## Pure checks use an explicit permissive callback; they do not certify collider
## motion, which remains the caller's separately tested responsibility.

const Ride = preload("res://game/player/transition_ride.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	var body := StaticBody3D.new()
	body.set_meta("transition_id", "test-quarter")
	tree.root.add_child(body)
	var curve := _feature(body)
	var supported := func(_point: Vector3, _normal: Vector3, _body: StaticBody3D) -> bool: return true
	var ride = Ride.new()
	check.call(ride.try_start([curve], _point(curve, 0.1) + _normal(curve, 0.1) * 0.02,
		_tangent(curve, 0.1) * 8.0, supported), "transition: eligible finite front-face contact starts")
	check.call(ride.active and absf(ride.theta - 0.1) < 0.0001 and absf(ride.along_speed - 8.0) < 0.0001
		and ride.normal().dot(_normal(curve, 0.1)) > 0.9999,
		"transition: capture preserves signed tangent speed and support frame")
	check.call(not ride.try_start([curve], _point(curve, 0.2), Vector3.ZERO, supported),
		"transition: an active contact cannot be silently replaced")
	var paused_point: Vector3 = ride.position()
	var paused_velocity: Vector3 = ride.travel_velocity()
	check.call(ride.step(0.0, 1.0, true, false) == "riding" and ride.position() == paused_point
		and ride.travel_velocity() == paused_velocity, "transition: zero-time pause consumes no movement or energy")
	ride.stop()
	check.call(not ride.active and ride.position() == paused_point and ride.travel_velocity() == paused_velocity
		and ride.step(0.1, 0.0, false, false) == "stopped",
		"transition: explicit stop clears contact without erasing outgoing momentum")
	_admission(check, curve, supported)
	_energy(check, curve, supported)
	_control(check, curve, supported)
	_signed_steering(check, curve, supported)
	_reconciliation(check, curve, supported)
	for invalid in [NAN, INF, -0.01, 0.251]:
		var invalid_ride = Ride.new()
		invalid_ride.try_start([curve], _point(curve, 0.2), _tangent(curve, 0.2) * 5.0, supported)
		check.call(invalid_ride.step(invalid, 0.0, false, false) == "invalid" and not invalid_ride.active
			and invalid_ride.position().is_finite() and invalid_ride.travel_velocity().is_finite(),
			"transition: invalid elapsed time safely releases: %s" % invalid)
	var invalid_steer = Ride.new()
	invalid_steer.try_start([curve], _point(curve, 0.2), _tangent(curve, 0.2) * 5.0, supported)
	check.call(invalid_steer.step(0.1, NAN, false, false) == "invalid", "transition: nonfinite steering releases safely")
	var changed_support := [true]
	var conditional := func(_point: Vector3, _normal: Vector3, _body: StaticBody3D) -> bool: return changed_support[0]
	var unsupported = Ride.new()
	unsupported.try_start([curve], _point(curve, 0.3), _tangent(curve, 0.3) * 5.0, conditional)
	changed_support[0] = false
	check.call(unsupported.step(1.0 / 60.0, 0.0, false, false) == "unsupported" and not unsupported.active,
		"transition: lost actual support releases instead of following a metadata-only surface")
	var removed = Ride.new()
	removed.try_start([curve], _point(curve, 0.3), _tangent(curve, 0.3) * 5.0, supported)
	body.free()
	check.call(removed.step(1.0 / 60.0, 0.0, false, false) == "invalid" and not removed.active,
		"transition: removed feature body cannot retain an invisible attachment")
	await _actual_support(tree, check)


static func _admission(check: Callable, curve: Dictionary, supported: Callable) -> void:
	var angle := 0.6
	var point := _point(curve, angle)
	var normal := _normal(curve, angle)
	var velocity := _tangent(curve, angle) * 6.0
	var rejected := [
		[point - normal * 0.06, velocity, "back face"],
		[point + normal * 0.21, velocity, "distant front face"],
		[_point(curve, angle, 5.001), velocity, "past finite width"],
		[Vector3(0, 0, 0.08), Vector3(0, 0, -6), "past toe seam"],
		[_point(curve, PI * 0.5) + Vector3.UP * 0.08, Vector3.DOWN * 6, "past finite lip"],
		[point, velocity + normal * 1.1, "departing front face"],
		[_point(curve, deg_to_rad(80)), Vector3.UP * 8, "rising vert takeoff"],
		[Vector3(INF, 0, 0), velocity, "nonfinite point"],
		[point, Vector3(NAN, 0, 0), "nonfinite velocity"],
	]
	for entry in rejected:
		check.call(not Ride.new().try_start([curve], entry[0], entry[1], supported),
			"transition: admission rejects " + entry[2])
	check.call(not Ride.new().try_start([curve], point, velocity, Callable()),
		"transition: missing physical support callback cannot attach")
	check.call(not Ride.new().try_start([curve], point, velocity,
		func(_p: Vector3, _n: Vector3, _b: StaticBody3D) -> bool: return false),
		"transition: explicit physical support rejection overrides geometric proximity")
	check.call(Ride.new().try_start([curve], _point(curve, deg_to_rad(85)), Vector3.DOWN * 6.0, supported),
		"transition: descending front-face re-entry near the lip is eligible")
	for field in ["radius", "width", "angle"]:
		var malformed := curve.duplicate()
		malformed[field] = NAN
		check.call(not Ride.new().try_start([malformed], point, velocity, supported),
			"transition: nonfinite feature %s is rejected" % field)
	var scaled := curve.duplicate()
	scaled.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(1, 2, 1)), Vector3.ZERO)
	check.call(not Ride.new().try_start([scaled], point, velocity, supported),
		"transition: scaled transforms cannot invalidate metre/energy bounds")
	var transformed := curve.duplicate()
	transformed.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(14, 2, -9))
	var world = Ride.new()
	check.call(world.try_start([transformed], _point(transformed, 0.4, -1.2), _tangent(transformed, 0.4) * 7.0, supported)
		and world.position().distance_to(_point(transformed, 0.4, -1.2)) < 0.001
		and world.travel_velocity().distance_to(_tangent(transformed, 0.4) * 7.0) < 0.001,
		"transition: translated yawed features retain their own world tangent frame")
	var wrong_tag := curve.duplicate()
	wrong_tag.id = "unrelated-pipe"
	check.call(not Ride.new().try_start([null, "pipe", {}, wrong_tag], point, velocity, supported),
		"transition: malformed features and mismatched live body identity cannot attach")


static func _energy(check: Callable, curve: Dictionary, supported: Callable) -> void:
	for max_angle: float in [deg_to_rad(80.0), PI * 0.5]:
		var feature := curve.duplicate()
		feature.angle = max_angle
		for hz: int in [30, 60, 120]:
			for entry_speed: float in [4.0, 15.0]:
				var ride = Ride.new()
				ride.try_start([feature], _point(feature, 0.001), _tangent(feature, 0.001) * entry_speed, supported)
				var initial_energy: float = _energy_of(ride)
				var highest_energy := initial_energy
				var highest_y: float = ride.position().y
				var result := "riding"
				var rolled_back := false
				for frame in range(hz * 8):
					result = ride.step(1.0 / hz, 0.0, false, false)
					highest_energy = maxf(highest_energy, _energy_of(ride))
					highest_y = maxf(highest_y, ride.position().y)
					rolled_back = rolled_back or ride.along_speed < -0.1
					if not ride.active: break
				var expected := "toe" if entry_speed == 4.0 else "lip"
				check.call(result == expected and not ride.active and (rolled_back if entry_speed == 4.0 else ride.travel_velocity().y > 6.0),
					"transition: %d-degree %d Hz %.0f m/s unforced approach exits %s" % [roundi(rad_to_deg(max_angle)), hz, entry_speed, expected])
				check.call(highest_energy <= initial_energy * 1.005 and (entry_speed > 4.0 or highest_y < 0.37),
					"transition: %d-degree %d Hz %.0f m/s contact adds no unexplained energy" % [roundi(rad_to_deg(max_angle)), hz, entry_speed])
				print("TRANSITION ENERGY angle=%d hz=%d entry=%.1f release=%s max_gain=%.6f%% max_y=%.4f release_velocity=%s" % [
					roundi(rad_to_deg(max_angle)), hz, entry_speed, result, (highest_energy / initial_energy - 1.0) * 100.0,
					highest_y, ride.travel_velocity()])


static func _control(check: Callable, curve: Dictionary, supported: Callable) -> void:
	var turning = Ride.new()
	turning.try_start([curve], _point(curve, 0.4), _tangent(curve, 0.4) * 7.0, supported)
	var initial := _energy_of(turning)
	turning.step(0.1, 1.0, false, false)
	check.call(turning.active and turning.across > 0.0 and turning.lateral_speed > 0.0
		and _energy_of(turning) <= initial * 1.005,
		"transition: right steering carves across the real surface tangent without adding energy")
	var side = Ride.new()
	side.try_start([curve], _point(curve, 0.4, 4.99), Vector3.RIGHT * 6.0, supported)
	check.call(side.step(0.1, 0.0, false, false) == "side" and not side.active
		and absf(side.across - 5.0) < 0.001 and side.travel_velocity().x > 5.0 and side.unused_time > 0.09,
		"transition: finite side boundary releases with lateral momentum and unused frame time")
	var no_drive = Ride.new()
	var drive = Ride.new()
	for ride in [no_drive, drive]:
		ride.try_start([curve], _point(curve, 0.1), _tangent(curve, 0.1) * 5.0, supported)
	no_drive.step(0.1, 0.0, false, false)
	drive.step(0.1, 0.0, true, false)
	check.call(drive.along_speed > no_drive.along_speed and drive.along_speed <= 5.6,
		"transition: explicit pushing adds only bounded acceleration")
	var brake = Ride.new()
	brake.try_start([curve], _point(curve, 0.1), _tangent(curve, 0.1) * 5.0, supported)
	brake.step(0.1, 0.0, true, true)
	check.call(brake.along_speed < no_drive.along_speed - 0.9,
		"transition: braking removes speed and suppresses simultaneous pumping")
	var extreme = Ride.new()
	extreme.try_start([curve], _point(curve, 0.2), _tangent(curve, 0.2) * 1000.0 + Vector3.RIGHT * 1000.0, supported)
	check.call(extreme.travel_velocity().length() <= Ride.MAX_SPEED + 0.001,
		"transition: capture projects and bounds extreme finite tangent velocities")


static func _reconciliation(check: Callable, curve: Dictionary, supported: Callable) -> void:
	var ride = Ride.new()
	ride.try_start([curve], _point(curve, 0.3), _tangent(curve, 0.3) * 9.0, supported)
	ride.step(0.03, 0.0, false, false)
	check.call(ride.reconcile(_point(curve, 0.31), _tangent(curve, 0.31) * 1.0)
		and absf(ride.theta - 0.31) < 0.0001 and absf(ride.along_speed - 1.0) < 0.001,
		"transition: real blocked motion replaces the predicted arc and discarded momentum")
	ride.step(0.01, 0.0, false, false)
	check.call(ride.along_speed < 1.0,
		"transition: the next update cannot reconstruct pre-obstacle contact speed")
	check.call(not ride.reconcile(Vector3(20, 20, 20), Vector3.ZERO) and not ride.active,
		"transition: an actual move outside the finite surface releases contact")
	var lateral = Ride.new()
	lateral.try_start([curve], _point(curve, 0.5),
		_tangent(curve, 0.5) * 9.0 + Vector3.RIGHT * 4.0, supported)
	lateral.step(0.03, 0.0, false, false)
	var remaining_velocity := _tangent(curve, 0.52) * 2.0 - Vector3.RIGHT * 0.75
	check.call(lateral.reconcile(_point(curve, 0.52, 0.04), remaining_velocity)
		and absf(lateral.along_speed - 2.0) < 0.0001
		and absf(lateral.lateral_speed + 0.75) < 0.0001
		and lateral.travel_velocity().distance_to(remaining_velocity) < 0.0001,
		"transition: actual oblique collision replaces both signed arc and lateral momentum")
	check.call(lateral.reconcile(lateral.position(), Vector3.ZERO)
		and lateral.travel_velocity() == Vector3.ZERO,
		"transition: an actual full stop clears both predicted tangent components")
	lateral.step(1.0 / 60.0, 0.0, false, false)
	check.call(lateral.active and lateral.along_speed < 0.0
		and absf(lateral.lateral_speed) < 0.000001 and lateral.travel_velocity().length() < 0.5,
		"transition: after an impact only downhill gravity resumes, without restored lateral speed")


static func _signed_steering(check: Callable, curve: Dictionary, supported: Callable) -> void:
	# Ground right input rotates heading clockwise around its support normal.
	# With signed speed, the same right input moves uphill travel toward local +X
	# and backward/downhill travel toward local -X. A yawed wall must keep that
	# handedness; global-X-only checks would miss the opposite half-pipe wall.
	for yaw: float in [-PI * 0.5, 0.0, PI * 0.5]:
		var feature := curve.duplicate()
		feature.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(14.0, 2.0, -9.0))
		for signed_speed: float in [-8.0, 8.0]:
			for steer: float in [-1.0, 1.0]:
				var ride = Ride.new()
				ride.try_start([feature], _point(feature, 0.5),
					_tangent(feature, 0.5) * signed_speed, supported)
				var initial_energy := _energy_of(ride)
				var result: String = ride.step(0.08, steer, false, false)
				var world_side: Vector3 = feature.transform.basis.x
				var lateral_in_surface: float = ride.travel_velocity().dot(world_side)
				check.call(result == "riding" and ride.active
					and signf(ride.along_speed) == signf(signed_speed)
					and lateral_in_surface * signf(signed_speed) * steer > 0.35
					and _energy_of(ride) <= initial_energy * 1.005,
					"transition: %d-degree wall %.0f m/s steer %.0f keeps signed ground handedness without extra energy" % [
						roundi(rad_to_deg(yaw)), signed_speed, steer])


static func _actual_support(tree: SceneTree, check: Callable) -> void:
	var body := StaticBody3D.new()
	body.name = "GeneratedQuarterSupport"
	body.set_meta("transition_id", "test-quarter")
	var curve := _feature(body)
	var faces := PackedVector3Array()
	for segment in range(45):
		var a := float(segment) / 45.0 * PI * 0.5
		var b := float(segment + 1) / 45.0 * PI * 0.5
		var left_a := _point(curve, a, -5.0)
		var right_a := _point(curve, a, 5.0)
		var left_b := _point(curve, b, -5.0)
		var right_b := _point(curve, b, 5.0)
		# Godot's concave front faces use clockwise winding, opposite the usual
		# mathematical cross-product normal of these vertex triples.
		faces.append_array(PackedVector3Array([left_a, right_b, right_a, left_a, left_b, right_b]))
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	collision.shape = shape
	body.add_child(collision)
	tree.root.add_child(body)
	await tree.physics_frame
	await tree.physics_frame
	var support := func(point: Vector3, normal: Vector3, expected: StaticBody3D) -> bool:
		var query := PhysicsRayQueryParameters3D.create(point + normal * 0.12, point - normal * 0.08, 1)
		var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
		return not hit.is_empty() and hit.collider == expected and hit.normal.dot(normal) > 0.98
	var confirmed := true
	for angle: float in [0.1, deg_to_rad(45), deg_to_rad(80), deg_to_rad(89)]:
		var ride = Ride.new()
		confirmed = confirmed and ride.try_start([curve], _point(curve, angle), _tangent(curve, angle) * -4.0, support)
	check.call(confirmed, "transition: real front-face triangle collision confirms shallow, steep and near-vertical support")
	body.collision_layer = 0
	await tree.physics_frame
	check.call(not Ride.new().try_start([curve], _point(curve, 0.6), _tangent(curve, 0.6) * 4.0, support),
		"transition: disabling actual curve collision prevents tagged geometry capture")
	body.free()


static func _feature(body: StaticBody3D) -> Dictionary:
	return {"id": "test-quarter", "transform": Transform3D.IDENTITY,
		"radius": 3.2, "width": 10.0, "angle": PI * 0.5, "body": body}


static func _point(feature: Dictionary, angle: float, across: float = 0.0) -> Vector3:
	return feature.transform * Vector3(across, feature.radius * (1.0 - cos(angle)), -feature.radius * sin(angle))


static func _normal(feature: Dictionary, angle: float) -> Vector3:
	return feature.transform.basis * Vector3(0.0, cos(angle), sin(angle))


static func _tangent(feature: Dictionary, angle: float) -> Vector3:
	return feature.transform.basis * Vector3(0.0, sin(angle), -cos(angle))


static func _energy_of(ride: RefCounted) -> float:
	return 0.5 * ride.travel_velocity().length_squared() + Ride.GRAVITY * ride.position().y
