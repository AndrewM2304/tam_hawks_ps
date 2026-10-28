extends RefCounted
## Fixed actual Clyde bowl witnesses, independent native tyre/material probes
## and a former-locomotion-limit control. No camera tolerance or physics edit.

const Skater = preload("res://game/player/skater.gd")
const Bowl = preload("res://game/levels/bowl_feature.gd")
const Quarter = preload("res://game/levels/transition_feature.gd")
const Terrain = preload("res://game/levels/core_terrain.gd")
const Setup = preload("res://game/core/input_setup.gd")
const WITNESSES := [
	{"at":Vector3(-5.628685,0.60745,139.6117),
		"board":Transform3D(Basis(Vector3(-0.300799,0.738562,0.603362),Vector3(-0.227576,0.558798,-0.797467),Vector3(-0.926137,-0.377188,-0.000007)),Vector3(-5.628413,0.60678,139.6127)),
		"vertex":Vector3(0.123994,-0.118448,0.26482)},
	{"at":Vector3(-4.377836,0.793868,139.2057),
		"board":Transform3D(Basis(Vector3(-0.352331,0.551336,0.756235),Vector3(-0.407219,0.637231,-0.6543),Vector3(-0.842636,-0.538484,-0.000001)),Vector3(-4.364649,0.773233,139.2269)),
		"vertex":Vector3(0.14,-0.092282,-0.256401)},
	{"at":Vector3(-1.96736,1.133256,136.7784),
		"board":Transform3D(Basis(Vector3(-0.269851,0.199638,0.941979),Vector3(-0.757272,0.560236,-0.335671),Vector3(-0.594743,-0.803916,0.0)),Vector3(-1.913025,1.093058,136.8025)),
		"vertex":Vector3(0.14,-0.092282,-0.256401)},
]

class LocomotionLimitSkater extends "res://game/player/skater.gd":
	# Preserve the former eligibility boundary without adding a product switch.
	func _native_board_support_allowed(hit: Dictionary,_bowl: Node3D) -> bool:
		return not hit.is_empty() and Vector3(hit.normal).y>=cos(floor_max_angle)
	func _place_air_landing_wheels(_support: Dictionary) -> void:
		pass


static func run(tree: SceneTree,check: Callable) -> void:
	Setup.register_actions()
	var fixture := await _fixture(tree)
	var rider: CharacterBody3D=fixture.rider
	var control: CharacterBody3D=fixture.control
	var bowl: Node3D=fixture.bowl
	var negative := 0
	for index: int in WITNESSES.size():
		var entry: Dictionary=WITNESSES[index]
		for body: CharacterBody3D in [rider,control]:
			body.global_position=entry.at
			body.rotation.y=-PI*0.5
		var before := _state(rider)
		var fit: Dictionary=rider._native_board_floor()
		var legacy: Dictionary=control._native_board_floor()
		var prior: Transform3D=entry.board
		prior.basis=prior.basis.orthonormalized()
		var old_contact := _contact(rider,bowl,prior)
		negative+=int(float(old_contact.minimum)<-0.004)
		check.call(not fit.is_empty() and legacy.is_empty(),
			"PT24 native bowl: finite four-wheel fit survives the individual steep-face rejection at exact witness "+str(index))
		if fit.is_empty(): continue
		var pose := _presentation_pose(rider,fit)
		var contact := _contact(rider,bowl,pose)
		var material := _native_gap(rider,bowl,pose*Vector3(entry.vertex))
		check.call(contact.misses==0 and contact.minimum>=-0.001 and contact.maximum<=0.030
			and material.gap>=-0.001 and _volumes_clear(rider,pose),
			"PT24 native bowl: all real tyre rims and the recorded urethane/axle extremity clear actual finite concrete "+str(index))
		check.call(_state(rider)==before and rider.floor_max_angle==control.floor_max_angle,
			"PT24 native bowl: contact fit changes no locomotion/capsule/manual/velocity state or physical floor limit "+str(index))
		print("PT24_NATIVE_BOWL_CONTACT ",{"witness":index,"fit":fit,"minimum":contact.minimum,
			"maximum":contact.maximum,"material_gap":material.gap,"legacy_minimum":old_contact.minimum,
			"misses":contact.misses})
	check.call(negative==3,"PT24 native bowl: all three recorded old-frame controls independently reproduce real tyre penetration")
	_native_footprint_phase_controls(fixture,check)
	await _controls(tree,fixture,check)
	await _air_landing_controls(tree,fixture,check)
	await _air_offset_controls(tree,fixture,check)
	await _feature_air_coping_controls(tree,fixture,check)
	_ramp_air_pose_handoff_controls(fixture,check)
	fixture.viewport.queue_free()
	await tree.process_frame


static func _contact(rider: CharacterBody3D,bowl: Node3D,pose: Transform3D) -> Dictionary:
	var minimum := INF
	var maximum := -INF
	var misses := 0
	for wheel: Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		var lowest := INF
		for vertex: Vector3 in wheel.points:
			var gap := _native_gap(rider,bowl,pose*vertex)
			if not gap.valid:
				misses+=1
				continue
			lowest=minf(lowest,float(gap.gap))
		minimum=minf(minimum,lowest)
		maximum=maxf(maximum,lowest)
	return {"minimum":minimum,"maximum":maximum,"misses":misses}


static func _native_gap(rider: CharacterBody3D,bowl: Node3D,point: Vector3) -> Dictionary:
	# Analytic normal only aims a finite ray. The measured face, normal and
	# distance always come from independent native collision geometry.
	var sample: Dictionary=bowl.surface_sample(point)
	var axis: Vector3=sample.normal
	var hit:=rider.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(point+axis*0.12,point-axis*0.22,1|8,[rider.get_rid()]))
	if hit.is_empty() or hit.collider!=bowl.surface_body: return {"valid":false,"gap":-INF}
	return {"valid":true,"gap":(point-Vector3(hit.position)).dot(hit.normal)}


static func _presentation_pose(rider: CharacterBody3D,fit: Dictionary) -> Transform3D:
	var normal: Vector3=fit.normal
	var local: Vector3=rider.global_basis.inverse()*normal
	var frame: Basis=rider.global_basis*Basis.from_euler(Vector3(atan2(local.z,local.y),0,-asin(clampf(local.x,-1,1))))
	return Transform3D(frame,Vector3(fit.position)+normal*0.008+frame*rider._visual_rig._board_rest_position)


static func _volumes_clear(rider: CharacterBody3D,pose: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.transform=pose
	query.collision_mask=1|8
	query.margin=0.0
	query.exclude=[rider.get_rid()]
	for wheel: Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		var shape := ConvexPolygonShape3D.new()
		shape.margin=0.0
		shape.points=wheel.points
		query.shape=shape
		if not rider.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return false
	return true


static func _ramp_air_pose_handoff_controls(fixture:Dictionary,check:Callable)->void:
	var rider:CharacterBody3D=fixture.rider
	rider.reset_skater()
	rider.global_transform=Transform3D(Basis(Vector3.UP,0.6),Vector3(200,30,200))
	rider.airborne=true
	rider._ramp_air=true
	rider._force_air_tick=false
	rider._ramp_air_normal=Vector3(0.723209,0,0.690626).normalized()
	rider._ramp_launch_forward=Vector3(-0.690626,0,0.723209).normalized()
	rider.velocity=Vector3(1.77,0.46,-4.27)
	rider._spin_angle=0.7
	rider._stance_angle=0.0
	rider._air_grind_yaw=0.0
	rider._air_support_basis=Basis(Vector3.UP,-1.1)
	rider._surface_pitch=-0.2
	var old_surface:Basis=rider._air_support_basis
	rider._update_pose(1.0/60.0)
	# Derive the contract from the actual drawn figure, not a duplicate of
	# the assisted-return formula. Earned yaw is a separate local rotation.
	var drawn_base:Basis=(rider._visual.basis*Basis(Vector3.UP,-0.7)).orthonormalized()
	var seed_error:float=drawn_base.get_rotation_quaternion().angle_to(rider._air_support_basis.get_rotation_quaternion())
	var stale_gap:float=drawn_base.get_rotation_quaternion().angle_to(old_surface.get_rotation_quaternion())
	check.call(stale_gap>PI/4 and seed_error<0.00001,
		"PT24 air pose: horizontal-normal ramp flight retains its actual pre-yaw body frame instead of a stale surface frame")
	var previous:Basis=rider._visual.basis
	rider._ramp_air=false
	rider._force_air_tick=true
	var physical:=_state(rider)
	var board_local:Transform3D=rider._board_visual.transform
	rider._update_pose(1.0/60.0)
	var angle:float=previous.get_rotation_quaternion().angle_to(rider._visual.basis.get_rotation_quaternion())
	check.call(angle<=4.5/60.0+0.00001 and _state(rider)==physical
		and rider._board_visual.transform==board_local and rider._spin_angle==0.7,
		"PT24 air pose: ramp-to-ordinary handoff keeps the existing4.5rad/s body limit, earned yaw, local board and physical flight")
	print("PT24_RAMP_AIR_POSE_HANDOFF ",{"stale_angle":stale_gap,"seed_error":seed_error,"first_ordinary_angle":angle})


static func _state(body: CharacterBody3D) -> Dictionary:
	return {"transform":body.global_transform,"velocity":body.velocity,"speed":body.speed,
		"floor":body.is_on_floor(),"limit":body.floor_max_angle,"capsule":body.get_node("BodyCollision").transform,
		"air":body.airborne,"manual":body.manual_active,"balance":body.manual_balance,
		"transition":body.transition_active,"feature_state":body._feature_transition.state}


static func _native_footprint_phase_controls(fixture:Dictionary,check:Callable) -> void:
	var rider:CharacterBody3D=fixture.rider
	for x:float in [-10.63339,-10.639068]:
		rider.global_transform=Transform3D(Basis(Vector3.UP,-PI*0.5),Vector3(x,2.014172,139.5004))
		var before:=_state(rider)
		var fit:Dictionary=rider._native_board_floor()
		var clear:=false
		if not fit.is_empty():clear=rider._native_rim_frame_clear(_presentation_pose(rider,fit),0.0)
		check.call(not fit.is_empty() and clear and _state(rider)==before,
			"PT24 native footprint: exact full/standalone Clyde5.68mm phase pair supplies finite tyres/model clearance without changing physical state "+str(x))


static func _controls(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
	var bowl:Node3D=fixture.bowl
	var rider_identity:CharacterBody3D=fixture.rider
	var actual_deck:StaticBody3D=bowl._native_annular_deck
	var original_name:StringName=actual_deck.name
	actual_deck.name="RetainedDeckIdentityControl"
	var foreign:=StaticBody3D.new()
	foreign.name=original_name
	foreign.position=Vector3(1000,0,0)
	for key:StringName in actual_deck.get_meta_list():foreign.set_meta(key,actual_deck.get_meta(key))
	foreign.set_meta("transition_feature",bowl)
	foreign.set_meta("coping_feature",bowl)
	var collision:=CollisionShape3D.new()
	collision.shape=BoxShape3D.new()
	foreign.add_child(collision)
	bowl.add_child(foreign)
	var steep:=Vector3(sqrt(0.96),0.2,0)
	var accepted:=true
	for body:CollisionObject3D in [bowl.surface_body,actual_deck,bowl._native_steel_coping]:
		accepted=accepted and bowl.owns_native_wheel_support(body) \
			and rider_identity._native_board_support_allowed({"normal":steep,"collider":body},bowl)
	check.call(accepted,"PT24 native bowl: all three exact constructor-owned wall/deck/coping bodies retain steep support identity after a real body rename")
	check.call(foreign.name==original_name and foreign.get_parent()==bowl \
		and not bowl.owns_native_wheel_support(foreign) \
		and not rider_identity._native_board_support_allowed({"normal":steep,"collider":foreign},bowl),
		"PT24 native bowl: same-parent foreign native body with copied exact name and feature metadata cannot acquire steep support")
	bowl.remove_child(foreign)
	foreign.queue_free()
	actual_deck.name=original_name
	var terrain := Terrain.new()
	var material := StandardMaterial3D.new()
	terrain.add_patch(fixture.root,"UnrelatedFlat",Rect2(-34,-4,8,8),Vector4.ZERO,material)
	terrain.add_patch(fixture.root,"UnrelatedSteepBank",Rect2(26,-4,8,8),Vector4(0,0,16,16),material)
	var quarter := Quarter.new()
	quarter.position=Vector3(60,0,0)
	fixture.root.add_child(quarter)
	await tree.physics_frame
	await tree.process_frame
	var rider: CharacterBody3D=fixture.rider
	var control: CharacterBody3D=fixture.control
	var sample: Dictionary=quarter.sample(0.5,0.0)
	for point: Vector3 in [Vector3(-30,0.02,0),sample.point+sample.normal*0.022,Vector3(30,8.02,0)]:
		for body: CharacterBody3D in [rider,control]:
			body.global_position=point
			body.rotation=Vector3.ZERO
		var fixed: Dictionary=rider._native_board_floor()
		var old: Dictionary=control._native_board_floor()
		check.call(fixed==old,
			"PT24 native bowl: ordinary flat, nonwrapped quarter and unrelated steep-wall eligibility remains identical "+str(point))
		if point.x>26 and point.x<34:
			check.call(fixed.is_empty(),"PT24 native bowl: an unrelated actual steep plane still cannot acquire the wrapped-bowl exception")
	fixture.quarter=quarter


static func _air_landing_controls(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
	var terrain:=Terrain.new()
	terrain.add_patch(fixture.root,"ActualQuayReturn",Rect2(-16,120,14,10),Vector4(2,2,2,2),StandardMaterial3D.new())
	await tree.physics_frame
	await tree.process_frame
	var rider: CharacterBody3D=fixture.rider
	var control: CharacterBody3D=fixture.control
	# Exact CURRENT (not interpolated) last-air frame from the retained prefix
	# diagnostic; the capsule has not landed and its tilt still follows the bowl.
	var body_pose:=Transform3D(Basis(Vector3(.80915,0,.5876),Vector3.UP,Vector3(-.5876,0,.80915)),Vector3(-9.289708,2.102755,127.4841))
	body_pose.basis=body_pose.basis.orthonormalized()
	var visible:=Transform3D(Basis(Vector3(.76799,-.592710,.24266),Vector3(.438893,.762984,.474581),Vector3(-.466434,-.257973,.846101)),body_pose.origin)
	visible.basis=visible.basis.orthonormalized()
	for body: CharacterBody3D in [rider,control]:
		body.global_transform=body_pose
		body.airborne=true
		body.velocity=Vector3(4.7677145,-6.4583817,-7.5835876)
		body._visual.global_transform=visible
		body._board_visual.transform=Transform3D(Basis.IDENTITY,Vector3(0,.12,0))
		body._air_support_basis=body.global_basis.inverse()*visible.basis
	var space:=rider.get_world_3d().direct_space_state
	var support:=space.intersect_ray(PhysicsRayQueryParameters3D.create(body_pose.origin+Vector3.UP*.2,body_pose.origin-Vector3.UP*.3,1|8,[rider.get_rid()]))
	var before:=_state(rider)
	var local_board: Transform3D=rider._board_visual.transform
	var feet: Array[Transform3D]=[]
	for leg: Dictionary in rider._visual_rig._legs:
		feet.append(rider._board_visual.global_transform.affine_inverse()*leg.foot.global_transform)
	control._place_air_landing_wheels(support)
	var old:=_flat_contact(control,control._board_visual.global_transform)
	var old_axle:=_flat_gap(control,control._board_visual.to_global(Vector3(.14,-.088003,.259425)))
	check.call(old.minimum<-.035 and old_axle<-.022 and control._visual.global_transform.is_equal_approx(visible),
		"PT24 air landing: exact current-frame negative control retains the real rear-tyre and metal-axle penetration")
	rider._place_air_landing_wheels(support)
	var fixed:=_flat_contact(rider,rider._board_visual.global_transform)
	var axle:=_flat_gap(rider,rider._board_visual.to_global(Vector3(.14,-.088003,.259425)))
	check.call(fixed.misses==0 and fixed.minimum>=.0075 and axle>=.0075 and _volumes_clear(rider,rider._board_visual.global_transform),
		"PT24 air landing: every actual finite tyre hull and recorded axle vertex clear the native quay before capsule landing")
	var planted:=true
	for side: int in feet.size():
		var foot: Node3D=rider._visual_rig._legs[side].foot
		planted=planted and (rider._board_visual.global_transform.affine_inverse()*foot.global_transform).is_equal_approx(feet[side])
	check.call(_state(rider)==before and rider._board_visual.transform==local_board and planted \
		and rider._visual.global_position==visible.origin and rider._visual.global_basis.y.y<.999,
		"PT24 air landing: smallest rigid orientation fit preserves physics, zero lift, board-local pose and both planted feet")
	print("PT24_AIR_LANDING_CONTACT ",{"legacy_minimum":old.minimum,"legacy_axle":old_axle,
		"minimum":fixed.minimum,"axle":axle,"old_visual":visible,"fixed_visual":rider._visual.global_transform})
	# Clear ordinary flat flight and distant flight keep their exact original
	# presentation; the new fit also refuses an actual nonflat quarter plane.
	for variant: int in 3:
		rider._visual.global_transform=visible
		var plane:=support
		if variant==0: rider._visual.global_basis=body_pose.basis
		elif variant==1: rider._visual.global_position+=Vector3.UP*2.0
		else:
			var quarter: Node3D=fixture.quarter
			var sample: Dictionary=quarter.sample(.5,0.0)
			plane=space.intersect_ray(PhysicsRayQueryParameters3D.create(sample.point+sample.normal*.15,sample.point-sample.normal*.15,1|8,[rider.get_rid()]))
		var original: Transform3D=rider._visual.global_transform
		rider._place_air_landing_wheels(plane)
		check.call(not plane.is_empty() and rider._visual.global_transform==original,
			"PT24 air landing: clear flat/far-air/nonflat-quarter presentation is exactly unchanged "+str(variant))


static func _air_offset_controls(tree:SceneTree,fixture:Dictionary,check:Callable) -> void:
	var rider:CharacterBody3D=fixture.rider
	Terrain.new().add_patch(fixture.root,"AirOffsetNativeFloor",Rect2(122,122,16,16),Vector4.ONE*2.0,StandardMaterial3D.new())
	rider.global_transform=Transform3D(Basis.IDENTITY,Vector3(130,2.02,130))
	rider.airborne=true
	rider._board_visual.transform=Transform3D(Basis.IDENTITY,rider._visual_rig._board_rest_position)
	rider._visual.global_transform=Transform3D(Basis.IDENTITY,Vector3(130,1.985,130))
	await tree.physics_frame
	await tree.process_frame
	var offset:=Vector3.DOWN*0.035
	var original:Transform3D=rider._visual.global_transform
	var local_board:Transform3D=rider._board_visual.transform
	var physical:=_state(rider)
	var queries:=[_air_query_state(rider._floor_wheel_query),_air_query_state(rider._grind_board_query)]
	var feet:Array[Transform3D]=[]
	for leg:Dictionary in rider._visual_rig._legs:
		feet.append(rider._board_visual.global_transform.affine_inverse()*leg.foot.global_transform)
	check.call(not rider._native_rim_frame_clear(rider._board_visual.global_transform,0.0),
		"PT24 air offset: declared anticipated pose genuinely intersects the finite native floor")
	rider._withdraw_air_support_offset(offset)
	var planted:=true
	for side:int in feet.size():
		var foot:Node3D=rider._visual_rig._legs[side].foot
		planted=planted and (rider._board_visual.global_transform.affine_inverse()*foot.global_transform).is_equal_approx(feet[side])
	var moved:Vector3=rider._visual.global_position-original.origin
	check.call(moved.y>0.0 and moved.y<=0.03501 and moved.x==0.0 and moved.z==0.0 \
		and rider._native_rim_frame_clear(rider._board_visual.global_transform,0.0) \
		and _state(rider)==physical and rider._board_visual.transform==local_board and planted,
		"PT24 air offset: bounded withdrawal clears actual tyres/model while preserving native flight, local board and both foot attachments")
	check.call(queries==[_air_query_state(rider._floor_wheel_query),_air_query_state(rider._grind_board_query)],
		"PT24 air offset: accepted native fit restores every borrowed shape parameter")
	var clear_pose:Transform3D=rider._visual.global_transform
	rider._withdraw_air_support_offset(offset)
	check.call(rider._visual.global_transform==clear_pose,
		"PT24 air offset: already clear flight remains exactly unchanged")
	rider._visual.global_transform=original
	rider._withdraw_air_support_offset(Vector3.ZERO)
	check.call(rider._visual.global_transform==original,
		"PT24 air offset: zero earned offset cannot create a correction")
	var roof:=StaticBody3D.new()
	roof.position=Vector3(130,2.22,130)
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(1,0.10,1)
	collision.shape=shape
	roof.add_child(collision)
	fixture.root.add_child(roof)
	await tree.physics_frame
	await tree.process_frame
	var endpoint:=original
	endpoint.origin-=offset
	var board_local:Transform3D=original.affine_inverse()*rider._board_visual.global_transform
	var unsafe_endpoint:bool=not rider._native_rim_frame_clear(endpoint*board_local,0.0)
	rider._withdraw_air_support_offset(offset)
	check.call(unsafe_endpoint and rider._visual.global_transform==original and _state(rider)==physical \
		and queries==[_air_query_state(rider._floor_wheel_query),_air_query_state(rider._grind_board_query)],
		"PT24 air offset: real foreign endpoint blocker refuses the whole correction without physics or query side effects")


static func _feature_air_coping_controls(tree:SceneTree,fixture:Dictionary,check:Callable) -> void:
	var rider:CharacterBody3D=fixture.rider
	var bowl:Node3D=fixture.bowl
	var frame:=Basis(Vector3(.653843,-.36276,-.663999),Vector3(.712535,0,.701637),Vector3(-.254525,-.931883,.258479)).orthonormalized()
	rider.global_transform=Transform3D(Basis.IDENTITY,Vector3(-11.08071,2.310279,130.3022))
	rider._visual.global_transform=Transform3D(frame,rider.global_position)
	rider._board_visual.transform=Transform3D(Basis.IDENTITY,rider._visual_rig._board_rest_position)
	rider.airborne=true
	rider._ramp_air=true
	rider._feature_transition.active=true
	rider._feature_transition.state="air"
	rider._feature_transition.feature=bowl
	rider._feature_transition.normal=frame.y
	rider.transition_normal=frame.y
	var original:Transform3D=rider._visual.global_transform
	var local_board:Transform3D=rider._board_visual.transform
	var physical:=_state(rider)
	var coping:CollisionObject3D=bowl._native_steel_coping
	check.call(rider._native_model_hits_support(rider._board_visual.global_transform,{"rid":coping.get_rid(),"shape":0}),
		"PT24 Feature air: retained real release pose intersects the constructor-owned native coping")
	rider._place_feature_air_coping_wheels()
	var moved:Vector3=rider._visual.global_position-original.origin
	check.call(moved.dot(frame.y)>0.0 and moved.length()<=0.02501 \
		and moved.cross(frame.y).length()<0.00002 and rider._visual.global_basis.is_equal_approx(frame) \
		and rider._board_visual.transform==local_board and _state(rider)==physical \
		and rider._native_rim_frame_clear(rider._board_visual.global_transform,0.0),
		"PT24 Feature air: finite normal-only continuation clears actual tyres/model inside25mm while preserving flight, basis and local rig")
	rider._visual.global_transform=original
	rider._ramp_air=false
	rider._place_feature_air_coping_wheels()
	var guarded:bool=rider._visual.global_transform==original
	rider._ramp_air=true
	rider._feature_transition.state="surface"
	rider._place_feature_air_coping_wheels()
	guarded=guarded and rider._visual.global_transform==original
	rider._feature_transition.state="air"
	rider._feature_transition.active=false
	rider._place_feature_air_coping_wheels()
	guarded=guarded and rider._visual.global_transform==original
	rider._feature_transition.active=true
	check.call(guarded,"PT24 Feature air: non-ramp, surface and unassociated modes cannot acquire the coping continuation")
	var maximum:=-INF
	for part:Dictionary in rider._grind_clearance._parts:
		for point:Vector3 in part.points:maximum=maxf(maximum,point.y)
	var blocker:=StaticBody3D.new()
	blocker.transform=Transform3D(frame,rider._board_visual.global_position+frame.y*(maximum+0.018))
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(.6,.004,1.0)
	collision.shape=shape
	blocker.add_child(collision)
	fixture.root.add_child(blocker)
	await tree.physics_frame
	await tree.process_frame
	var current_clear:bool=not rider._native_model_hits_support(rider._board_visual.global_transform,{"rid":blocker.get_rid(),"shape":0})
	var endpoint:Transform3D=rider._board_visual.global_transform
	endpoint.origin+=frame.y*0.025
	var endpoint_blocked:bool=not rider._native_rim_frame_clear(endpoint,0.0)
	rider._place_feature_air_coping_wheels()
	check.call(current_clear and endpoint_blocked and rider._visual.global_transform==original and _state(rider)==physical,
		"PT24 Feature air: real foreign slab clear of the starting model blocks the endpoint and refuses the whole continuation")


static func _air_query_state(query:PhysicsShapeQueryParameters3D) -> Dictionary:
	return {"shape":query.shape,"transform":query.transform,"motion":query.motion,"margin":query.margin,
		"mask":query.collision_mask,"exclude":query.exclude,"bodies":query.collide_with_bodies,"areas":query.collide_with_areas}


static func _flat_contact(rider: CharacterBody3D,pose: Transform3D) -> Dictionary:
	var minimum:=INF
	var misses:=0
	for wheel: Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		for vertex: Vector3 in wheel.points:
			var gap:=_flat_gap(rider,pose*vertex)
			if not is_finite(gap): misses+=1
			minimum=minf(minimum,gap)
	return {"minimum":minimum,"misses":misses}


static func _flat_gap(rider: CharacterBody3D,point: Vector3) -> float:
	var hit:=rider.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(point+Vector3.UP*.3,point-Vector3.UP*.4,1|8,[rider.get_rid()]))
	if hit.is_empty() or Vector3(hit.normal).y<.999: return -INF
	return (point-Vector3(hit.position)).dot(hit.normal)


static func _fixture(tree: SceneTree) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.own_world_3d=true
	viewport.size=Vector2i(640,480)
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	var bowl := Bowl.new()
	bowl.radius=2.4
	bowl.floor_radius=3.5
	bowl.deck_length=1.8
	bowl.build_access=false
	bowl.position=Vector3(-7,-0.4,134.5)
	bowl.rotation.y=PI*0.5
	root.add_child(bowl)
	var rider=Skater.new()
	var control=LocomotionLimitSkater.new()
	for body: CharacterBody3D in [rider,control]:
		root.add_child(body)
		body.set_process(false)
		body.set_physics_process(false)
	# The superimposed measurement twin keeps its real capsule and mask9 but
	# cannot be a foreign layer2 obstacle inside the tested board volume.
	control.collision_layer=0
	await tree.physics_frame
	await tree.process_frame
	return {"viewport":viewport,"root":root,"bowl":bowl,"rider":rider,"control":control}
