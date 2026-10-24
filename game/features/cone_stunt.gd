extends Node3D
## Recoverable foam prop stunt. Only native RigidBody motion may cross the target;
## a real airborne skating launch, clean landing and bank complete the attempt.

const Art = preload("res://game/features/feature_visuals.gd")
signal feedback(text: String)
const ATTEMPT_SECONDS := 25.0
const APERTURE_RADIUS := 1.12
const APERTURE_MARGIN := 0.025
var reduced_motion := false
var cone: RigidBody3D
var _offer := Vector3.INF
var _launch := Vector3.INF
var _target := Vector3.INF
var _direction := Vector3.BACK
var _raft := Vector3.INF
var _state := "idle"
var _remaining := 0.0
var _flight_age := 0.0
var _previous_cone := Vector3.INF
var _target_hit := false
var _launched := false
var _player_landed := false
var _banked := false
var _raft_landed := false
var _attempts := 0
var _wins := 0
var _reason := ""
var _recovering := false
var _recovery_age := 0.0
var _recovery_from := Vector3.ZERO
var _ring_body: StaticBody3D
var _hull_points := PackedVector3Array()
var _previous_hull := PackedVector3Array()
var _crossed_hull: Dictionary = {}
var _aperture_clear := true
var _rim_hit := false

func configure(offer: Vector3, launch: Vector3, target: Vector3, raft: Vector3) -> void:
	if not offer.is_finite() or not launch.is_finite() or not target.is_finite() or not raft.is_finite(): return
	_offer = offer
	_launch = launch
	_target = target
	_raft = raft
	_direction = Vector3(target.x-launch.x, 0, target.z-launch.z).normalized()
	if _direction.length() < 0.5: return
	Art.regular(self, to_local(offer + Vector3(2.7, 0, 0)), true)
	Art.sign(self, to_local(offer + Vector3(0, 2.6, 0)), "CONE ON A CRUISE\nPOP · LAUNCH · LAND")
	Art.cylinder(self, "StuntMark", to_local(launch), 1.5, 0.025, Color("b89c5d"))
	var raft_body := StaticBody3D.new()
	raft_body.name = "ConeRecoveryRaft"
	raft_body.position = to_local(raft)
	raft_body.collision_layer = 4
	raft_body.collision_mask = 4
	add_child(raft_body)
	var raft_shape := BoxShape3D.new()
	raft_shape.size = Vector3(4.0, 0.28, 3.8)
	var raft_collision := CollisionShape3D.new()
	raft_collision.shape = raft_shape
	raft_body.add_child(raft_collision)
	Art.box(raft_body, "FloatingRecoveryDeck", Vector3.ZERO, raft_shape.size, Color("697b72"))
	for side: float in [-1,1]:
		Art.cylinder(raft_body, "RaftFloat", Vector3(side * 1.75, -0.16, 0), 0.22, 3.4, Color("bd754e")).rotation.x = PI * 0.5
	_ring_body = StaticBody3D.new()
	_ring_body.name = "NativeTargetRim"
	_ring_body.position = to_local(target)
	_ring_body.rotation = Vector3(PI*0.5,atan2(_direction.x,_direction.z),0)
	_ring_body.collision_layer = 4
	_ring_body.collision_mask = 4
	_ring_body.set_meta("no_wallride",true)
	add_child(_ring_body)
	var ring := MeshInstance3D.new()
	ring.name = "RiverTargetRing"
	var torus := TorusMesh.new()
	torus.inner_radius = APERTURE_RADIUS
	torus.outer_radius = 1.28
	ring.mesh = torus
	ring.material_override = Art.material(Color("dbba64"))
	_ring_body.add_child(ring)
	var rim_collision := CollisionShape3D.new()
	var rim_shape := torus.create_trimesh_shape()
	rim_shape.backface_collision = true
	rim_collision.shape = rim_shape
	_ring_body.add_child(rim_collision)
	cone = RigidBody3D.new()
	cone.name = "FoamFestivalCone"
	cone.mass = 0.35
	cone.gravity_scale = 22.0 / float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	cone.continuous_cd = true
	cone.collision_layer = 4
	cone.collision_mask = 1 | 4
	cone.linear_damp = 0.0
	cone.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	cone.angular_damp = 0.5
	cone.contact_monitor = true
	cone.max_contacts_reported = 8
	cone.freeze = true
	add_child(cone)
	cone.body_entered.connect(func(body: Node):
		if body == _ring_body and _launched: _rim_hit = true
		if body == raft_body and _launched:
			_raft_landed = true
			_try_success())
	var shape := ConvexPolygonShape3D.new()
	var vertices := PackedVector3Array()
	for i in 12:
		vertices.append(Vector3(cos(TAU*i/12.0)*0.35,-0.43,sin(TAU*i/12.0)*0.35))
		vertices.append(Vector3(cos(TAU*i/12.0)*0.02,0.43,sin(TAU*i/12.0)*0.02))
	shape.points = vertices
	_hull_points = vertices.duplicate()
	var collision := CollisionShape3D.new()
	collision.shape = shape
	cone.add_child(collision)
	var base_shape := BoxShape3D.new()
	base_shape.size = Vector3(0.75,0.08,0.75)
	var base_collision := CollisionShape3D.new()
	base_collision.name = "FoamBaseCollision"
	base_collision.position = Vector3(0,-0.4,0)
	base_collision.shape = base_shape
	cone.add_child(base_collision)
	for x: float in [-0.375,0.375]:
		for y: float in [-0.44,-0.36]:
			for z: float in [-0.375,0.375]: _hull_points.append(Vector3(x,y,z))
	var band_shape := CylinderShape3D.new()
	band_shape.radius = 0.21
	band_shape.height = 0.13
	var band_collision := CollisionShape3D.new()
	band_collision.name = "ConeBandCollision"
	band_collision.position = Vector3(0,0.05,0)
	band_collision.shape = band_shape
	cone.add_child(band_collision)
	for i in 16:
		for y: float in [-0.015,0.115]: _hull_points.append(Vector3(cos(TAU*i/16.0)*0.21,y,sin(TAU*i/16.0)*0.21))
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.35
	mesh.height = 0.86
	var visible := MeshInstance3D.new()
	visible.mesh = mesh
	visible.material_override = Art.material(Color("d67b48"))
	cone.add_child(visible)
	Art.box(cone, "FoamBase", Vector3(0,-0.4,0), Vector3(0.75,0.08,0.75), Color("a45b3f"))
	Art.cylinder(cone, "ReflectiveBand", Vector3(0,0.05,0), 0.21, 0.13, Color("efe8d7"))
	reset_run()

func nearby_prompt(at: Vector3) -> String:
	if _state == "active" and not _launched and _near(at, _launch, 3.2): return "LAUNCH FOAM CONE DURING YOUR POP"
	if _state != "active" and not _recovering and _near(at, _offer, 4.2): return "TRY CONE ON A CRUISE"
	return ""

func poll(at: Vector3, interact: bool, delta: float, combo_value: int = 0, skater: CharacterBody3D = null) -> void:
	if not is_instance_valid(cone) or not at.is_finite(): return
	if _state == "active":
		var offset := at-_launch
		var along := offset.dot(_direction)
		var lateral := Vector3(offset.x,0,offset.z).slide(_direction).length()
		if lateral > 22.0 or along < -24.0 or along > 4.1 or at.y < _launch.y-2.0:
			_fail("Stay on the quay. The foam cone is coming back in.")
		elif is_finite(delta) and delta > 0.0:
			_remaining = maxf(0.0, _remaining-delta)
			if _remaining <= 0.0: _fail("Time's up. Another cone cruise starts by the steward.")
		if _state == "active" and interact and not _launched and _near(at, _launch, 3.2):
			_try_launch(skater, combo_value)
	elif interact and not nearby_prompt(at).is_empty():
		if combo_value > 0:
			feedback.emit("STEWARD: Bank your line first. Then give the foam mascot a cruise.")
		else:
			_state = "active"
			_remaining = ATTEMPT_SECONDS
			_attempts += 1
			_reason = ""
			_target_hit = false
			_launched = false
			_player_landed = false
			_banked = false
			_raft_landed = false
			_clear_aperture()
			_restore_cone()
			feedback.emit("STEWARD: Build speed towards the painted mark, pop and launch the foam cone. Land your trick and bank on the quay!")
	_try_success()

func _try_launch(skater: CharacterBody3D, combo_value: int) -> bool:
	if not is_instance_valid(skater): return false
	var planar := Vector3(skater.velocity.x, 0, skater.velocity.z)
	if not bool(skater.get("airborne")) or combo_value <= 0 or planar.length() < 6.0 \
		or planar.normalized().dot(_direction) < 0.85:
		feedback.emit("STEWARD: A forward pop at speed, then launch from the painted mark.")
		return false
	_launched = true
	_flight_age = 0.0
	cone.freeze = false
	cone.sleeping = false
	cone.apply_central_impulse((planar.normalized() * clampf(planar.length()*0.8, 7.0, 9.0) + Vector3.UP*8.2)*cone.mass)
	# A centred launch does not manufacture tumbling. Native rim/raft contacts
	# remain free to rotate the complete foam prop and its weighted base.
	_previous_cone = cone.global_position
	_previous_hull = _world_hull()
	feedback.emit("STEWARD: There it goes! Keep your landing clean.")
	return true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(cone) or not is_finite(delta) or delta <= 0.0: return
	if _recovering:
		_recovery_age += delta
		var t := clampf(_recovery_age / 1.4, 0.0, 1.0)
		var home := _launch + Vector3.UP*0.52
		cone.global_position = _recovery_from.lerp(home, smoothstep(0.0,1.0,t)) + Vector3.UP*sin(PI*t)*2.0
		if t >= 1.0:
			_recovering = false
			_restore_cone()
		return
	if not _launched: return
	_flight_age += delta
	var current := cone.global_position
	if _state == "active" and _rim_hit:
		_aperture_clear = false
		_fail("Clipped the target rim. Foam mascot coming back for another try.")
		return
	if _state == "active" and not _target_hit and _previous_cone.is_finite():
		_observe_aperture(current)
	_previous_cone = current
	if current.y < _raft.y-0.6 or _flight_age > 4.0:
		if _state == "active" and not _target_hit: _fail("Missed the ring. The foam mascot's on its way back.")
		elif _state == "active" and _target_hit and not (_player_landed and _banked and _raft_landed):
			_fail("The cone needs its raft and your trick needs a clean bank. Try again.")
		if _state != "success": _recover_cone()

func _world_hull() -> PackedVector3Array:
	var result := PackedVector3Array()
	for point: Vector3 in _hull_points: result.append(cone.global_transform*point)
	return result

func _clear_aperture() -> void:
	_crossed_hull.clear()
	_previous_hull.clear()
	_aperture_clear = true
	_rim_hit = false

func _observe_aperture(current: Vector3) -> void:
	var hull := _world_hull()
	if current.distance_to(_previous_cone)>=1.0 or hull.size()!=_previous_hull.size():
		_aperture_clear = false
		_previous_hull = hull
		return
	var rear := INF
	for i in hull.size():
		var before := (_previous_hull[i]-_target).dot(_direction)
		var after := (hull[i]-_target).dot(_direction)
		rear = minf(rear,after)
		if before<0.0 and after>=0.0:
			var crossing := _previous_hull[i].lerp(hull[i],-before/maxf(0.000001,after-before))
			if (crossing-_target).slide(_direction).length()>APERTURE_RADIUS-APERTURE_MARGIN:
				_aperture_clear = false
			_crossed_hull[i] = true
	_previous_hull = hull
	# Every native hull vertex must cross within the clear aperture and the
	# trailing hull must leave the torus's .08m half-depth before success.
	if _aperture_clear and not _rim_hit and _crossed_hull.size()==_hull_points.size() and rear>0.10:
		_target_hit = true
		feedback.emit("STEWARD: Through the ring! Land and bank that line.")
		_try_success()

func on_landed(clean: bool) -> void:
	if _state == "active" and _launched and clean:
		_player_landed = true
		_try_success()

func on_bank(points: int, at: Vector3) -> void:
	var offset := at-_launch
	if _state == "active" and _launched and _player_landed and points > 0 and at.y >= _launch.y-0.5 \
		and Vector3(offset.x,0,offset.z).slide(_direction).length() <= 22.0 and offset.dot(_direction) < 4.0:
		_banked = true
		_try_success()

func _try_success() -> void:
	if _state == "active" and _target_hit and _player_landed and _banked and _raft_landed:
		_state = "success"
		_wins += 1
		feedback.emit("STEWARD: Cone on a cruise, skater on the quay. That's the festival sorted!")

func _fail(reason: String) -> void:
	_state = "failed"
	_reason = reason
	feedback.emit("STEWARD: " + reason)
	if _launched: _recover_cone()

func _recover_cone() -> void:
	if _recovering: return
	cone.freeze = true
	cone.linear_velocity = Vector3.ZERO
	cone.angular_velocity = Vector3.ZERO
	_recovering = true
	_recovery_age = 0.0
	_recovery_from = cone.global_position

func _restore_cone() -> void:
	cone.freeze = true
	cone.linear_velocity = Vector3.ZERO
	cone.angular_velocity = Vector3.ZERO
	cone.global_transform = Transform3D(Basis.IDENTITY, _launch+Vector3.UP*0.52)
	_launched = false
	_flight_age = 0.0
	_previous_cone = Vector3.INF

func cancel_attempt() -> void:
	if _state == "active": _fail("Cruise cancelled. Cone's back on duty.")

func finish_run() -> void:
	if _state == "active": _fail("Run finished. Foam mascot safely recovered.")

func on_bail() -> void:
	if _state == "active": _fail("A clean landing was part of the deal. Have another go.")

func reset_run() -> void:
	_state = "idle"
	_remaining = 0.0
	_target_hit = false
	_player_landed = false
	_banked = false
	_raft_landed = false
	_clear_aperture()
	_attempts = 0
	_wins = 0
	_reason = ""
	_recovering = false
	if is_instance_valid(cone): _restore_cone()

func status_snapshot() -> Dictionary:
	var text := "CONE ON A CRUISE · POP, LAUNCH, LAND"
	if _state == "active": text = "CONE CRUISE · %ds · %s" % [ceili(_remaining), "LAND AND BANK" if _target_hit else ("IN FLIGHT" if _launched else "POP AT THE MARK")]
	elif not _reason.is_empty(): text = _reason
	elif _state == "success": text = "CONE CRUISE · CLEAN LANDING"
	return {"id":"cone_on_a_cruise", "state":_state, "remaining":_remaining, "attempts":_attempts,
		"wins":_wins, "position":_offer, "payoff_position":_target, "target_hit":_target_hit,
		"launched":_launched, "landed":_player_landed, "banked":_banked, "raft_landed":_raft_landed, "recovering":_recovering,
		"rim_hit":_rim_hit,"aperture_clear":_aperture_clear,"crossed_vertices":_crossed_hull.size(),"hull_vertices":_hull_points.size(),
		"cone_position":cone.global_position if is_instance_valid(cone) else Vector3.INF,
		"target":_target, "launch":_launch, "raft":_raft, "hud_text":text, "reason":_reason}

static func _near(a: Vector3, b: Vector3, radius: float) -> bool:
	return a.is_finite() and b.is_finite() and absf(a.y-b.y)<2.8 and Vector2(a.x-b.x,a.z-b.z).length()<=radius
