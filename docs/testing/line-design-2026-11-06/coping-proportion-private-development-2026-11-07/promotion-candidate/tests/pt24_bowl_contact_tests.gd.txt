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


# Rounded source-bound transforms from the seven actual Main defect-edge frames.
# Static geometry witnesses supplement, not replace, that separate input replay.
const CURRENT_EDGE_FRAMES := [
	{"physics":179,"actor":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.0,1.0,0.0),Vector3(-1.0,0.0,-0.0)),Vector3(-11.03528,2.01381,139.5002)),
		"board":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.001796,0.999998,0.0),Vector3(-0.999998,0.001796,-0.0)),Vector3(-11.03528,2.128458,139.5002)),"near_face":4,"far_face":0,"unknown":0},
	{"physics":180,"actor":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.0,1.0,0.0),Vector3(-1.0,0.0,-0.0)),Vector3(-10.8177,2.01381,139.5002)),
		"board":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.001376,0.999999,0.0),Vector3(-0.999999,0.001376,-0.0)),Vector3(-10.8177,2.128351,139.5002)),"near_face":4,"far_face":0,"unknown":0},
	{"physics":181,"actor":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.0,1.0,0.0),Vector3(-1.0,0.0,-0.0)),Vector3(-10.60112,2.01381,139.5002)),
		"board":Transform3D(Basis(Vector3(0.000273,-0.024594,0.999698),Vector3(-0.010034,0.999647,0.024595),Vector3(-0.99995,-0.010038,0.000026)),Vector3(-10.60246,2.135467,139.5031)),"near_face":4,"far_face":0,"unknown":0},
	{"physics":182,"actor":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.0,1.0,0.0),Vector3(-1.0,0.0,-0.0)),Vector3(-10.38555,2.01381,139.5002)),
		"board":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.000807,1.0,0.0),Vector3(-1.0,0.000807,-0.0)),Vector3(-10.38555,2.128206,139.5002)),"near_face":3,"far_face":0,"unknown":1},
	{"physics":183,"actor":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.0,1.0,0.0),Vector3(-1.0,0.0,-0.0)),Vector3(-10.17096,2.01381,139.5002)),
		"board":Transform3D(Basis(Vector3(0.000038,-0.0078,0.99997),Vector3(-0.004322,0.99996,0.0078),Vector3(-0.999991,-0.004322,0.000005)),Vector3(-10.17158,2.139633,139.5011)),"near_face":3,"far_face":0,"unknown":1},
	{"physics":184,"actor":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.0,1.0,0.0),Vector3(-1.0,0.0,-0.0)),Vector3(-9.957256,1.992015,139.5002)),
		"board":Transform3D(Basis(Vector3(0.056214,0.302138,0.951605),Vector3(0.174528,0.935464,-0.307323),Vector3(-0.983046,0.183358,-0.000146)),Vector3(-9.936348,2.104393,139.4633)),"near_face":0,"far_face":1,"unknown":3},
	{"physics":185,"actor":Transform3D(Basis(Vector3(-0.0,0.0,1.0),Vector3(0.0,1.0,0.0),Vector3(-1.0,0.0,-0.0)),Vector3(-9.750462,1.934972,139.5078)),
		"board":Transform3D(Basis(Vector3(0.22893,0.527465,0.818152),Vector3(0.326069,0.750367,-0.575002),Vector3(-0.917208,0.398409,-0.000209)),Vector3(-9.711343,2.025103,139.4387)),"near_face":1,"far_face":0,"unknown":3},
]

class HistoricalCopingBowl extends "res://game/levels/bowl_feature.gd":
	# Explicit original 90mm OD /70mm crown regression geometry; never used
	# by the game. Native, display and guide/lip datums remain atomic.
	func build() -> void:
		if _built:return
		super.build()
		var steel:MeshInstance3D=get_node("ContinuousBowlCoping")
		var torus:TorusMesh=steel.mesh
		var concrete_lip:float=floor_radius+radius
		torus.inner_radius=concrete_lip-.045
		torus.outer_radius=concrete_lip+.045
		steel.position.y=radius+.025
		_native_steel_coping.transform=steel.transform
		var collision:CollisionShape3D=_native_steel_coping.get_child(0)
		collision.shape.set_faces(torus.get_faces())
	func lip_frame(lateral:float) -> Dictionary:
		var frame:Dictionary=sample(PI*.5,lateral)
		frame.face_normal=frame.normal
		frame.point+=Vector3.UP*.070
		frame.normal=Vector3.UP
		frame.coping_tangent=frame.lateral
		return frame

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
	await _historical_coping_controls(tree,check)
	_current_profile_controls(fixture,check)
	await _controls(tree,fixture,check)
	await _buried_air_landing_controls(tree,fixture,check)
	await _air_landing_controls(tree,fixture,check)
	await _air_offset_controls(tree,fixture,check)
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
	for x:float in [-10.63339,-10.639068,-10.647394,-10.62713]:
		rider.global_transform=Transform3D(Basis(Vector3.UP,-PI*0.5),Vector3(x,2.014172,139.5004))
		var before:=_state(rider)
		var fit:Dictionary=rider._native_board_floor()
		var clear:=false
		if not fit.is_empty():clear=rider._native_rim_frame_clear(_presentation_pose(rider,fit),0.0)
		check.call(not fit.is_empty() and clear and _state(rider)==before,
			"PT24 native footprint: exact Clyde phase and steep coping-tangent witnesses supply finite tyres/model clearance without changing physical state "+str(x))
		if x!=-10.62713 or fit.is_empty():continue
		var pose:=_presentation_pose(rider,fit)
		var loaded:=0
		var unloaded:=0
		var native:=true
		for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
			var gap:=INF
			for vertex:Vector3 in wheel.points:
				var at:Vector3=pose*vertex
				var hit:=rider.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.35,1|8,[rider.get_rid()]))
				if hit.is_empty() or not fixture.bowl.owns_native_wheel_support(hit.collider):
					native=false
					continue
				gap=minf(gap,(at-Vector3(hit.position)).dot(hit.normal))
			if gap>=.004 and gap<=.030:loaded+=1
			elif gap>.030 and gap<=.10:unloaded+=1
		check.call(native and loaded==2 and unloaded==2 and _volumes_clear(rider,pose)
			and rider._manual_model_frame_clear(pose) and Vector3(fit.position).y-2.0<=.10,
			"PT24 native coping: twisted rim/deck patch retains two actual loaded and two unloaded tyres, clear whole GLB and original100mm fit budget")


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


static func _buried_air_landing_controls(tree:SceneTree,fixture:Dictionary,check:Callable)->void:
	var rider:CharacterBody3D=fixture.rider
	rider.reset_skater()
	rider.global_transform=Transform3D(Basis(Vector3.UP,-0.65),Vector3(-9.796431,2.129778,127.7172))
	rider.airborne=true
	rider.velocity=Vector3(1.0558074,-11.341945,-3.6876566)
	var recorded:=Basis(Vector3(.743844,.620413,-.24856),Vector3(-.074727,.44677,.891521),Vector3(.664161,-.64458,.378689)).orthonormalized()
	rider._visual.global_transform=Transform3D(recorded,rider.global_position)
	var original:Transform3D=rider._visual.global_transform
	var board_local:Transform3D=rider._board_visual.transform
	var before:=_state(rider)
	var support:Dictionary=rider._native_floor_hit(Vector3.UP)
	var minimum_center:=INF
	var crossings:=0
	var wheels:Array=rider._visual_rig.board_contact_geometry().wheels
	var space:=rider.get_world_3d().direct_space_state
	var query:=PhysicsShapeQueryParameters3D.new()
	query.transform=rider._board_visual.global_transform
	query.collision_mask=1|2|8
	query.exclude=[rider.get_rid()]
	query.margin=0.0
	for index:int in wheels.size():
		minimum_center=minf(minimum_center,rider._board_visual.to_global(wheels[index].center).y-2.0)
		query.shape=rider._floor_wheel_shapes[index]
		crossings+=int(not space.intersect_shape(query,1).is_empty())
	check.call(not support.is_empty() and support.collider==fixture.bowl._native_annular_deck
		and minimum_center<-.08 and crossings==0,
		"PT24 air landing: retained real rear tyre is wholly behind its finite native deck although all four tyre-volume crossing queries are empty")
	rider._place_air_landing_wheels(support)
	var corrected:Transform3D=rider._board_visual.global_transform
	var gap:float=rider._air_landing_wheel_gap(corrected,wheels,Vector3(support.position),Vector3.UP)
	check.call(gap>=0.008 and rider._native_rim_frame_clear(corrected,0.0)
		and _state(rider)==before and rider._visual.global_position==original.origin
		and rider._board_visual.transform==board_local,
		"PT24 air landing: smallest native-clear rigid fit catches a fully buried tyre without translating the figure or changing physical flight/local board")
	var blocker:=StaticBody3D.new()
	blocker.name="ForeignBuriedAirNose"
	blocker.collision_layer=1
	blocker.collision_mask=0
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new();shape.size=Vector3(.5,.3,.002);collision.shape=shape
	blocker.add_child(collision)
	fixture.root.add_child(blocker)
	blocker.global_transform=corrected*Transform3D(Basis.IDENTITY,Vector3(0,0,-.4))
	await tree.physics_frame
	await tree.process_frame
	var endpoint_tyres:bool=_volumes_clear(rider,corrected)
	var endpoint_blocked:bool=not rider._manual_model_frame_clear(corrected)
	rider._visual.global_transform=original
	var blocked_original:Transform3D=rider._visual.global_transform
	rider._place_air_landing_wheels(support)
	check.call(endpoint_tyres and endpoint_blocked and rider._visual.global_transform==blocked_original
		and _state(rider)==before and rider._board_visual.transform==board_local,
		"PT24 air landing: a foreign nose slab missed by all four tyres still refuses the actual connected-model endpoint")
	blocker.queue_free()
	await tree.physics_frame
	await tree.process_frame


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


static func _fixture(tree: SceneTree,historical_coping:bool=false) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.own_world_3d=true
	viewport.size=Vector2i(640,480)
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	var bowl:Node3D=HistoricalCopingBowl.new() if historical_coping else Bowl.new()
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


static func _native_footprint_authentication_controls(fixture:Dictionary,check:Callable)->void:
	var rider:CharacterBody3D=fixture.rider
	var bowl:Node3D=fixture.bowl
	var space:=rider.get_world_3d().direct_space_state
	var native:=space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-10.38,2.2,139.3764),Vector3(-10.38,1.9,139.3764),1|8,[rider.get_rid()]))
	check.call(not native.is_empty() and native.collider==bowl._native_steel_coping,
		"PT24 footprint authentication: positive control begins on an independently ray-confirmed real native coping face")
	if native.is_empty():return
	var before:=_state(rider)
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=rider._floor_wheel_shapes[0]
	query.transform=Transform3D(Basis(Vector3.UP,-PI*.5),Vector3(-10.647394,2.128,139.5004))
	query.collision_mask=1|2|8
	query.exclude=[rider.get_rid()]
	query.margin=.008
	var rest:Dictionary={"point":native.position,"normal":native.normal,"rid":native.rid,"shape":native.shape}
	var positive:Dictionary=rider._native_footprint_contact(space,query,rest)
	check.call(not positive.is_empty() and positive.rid==native.rid and positive.shape==native.shape,
		"PT24 footprint authentication: a real native top face supplies a finite same-owner support")
	var virtual:=rest.duplicate()
	virtual.point=Vector3(-10.40756,2.120990,139.2645)
	var recovered:Dictionary=rider._native_footprint_contact(space,query,virtual)
	check.call(not recovered.is_empty() and Vector3(recovered.position).y<=2.07001,
		"PT24 footprint authentication: the recorded virtual concave point cannot replace recovered actual native coping geometry")
	var clear_query:=PhysicsShapeQueryParameters3D.new()
	clear_query.shape=query.shape
	clear_query.transform=query.transform
	clear_query.transform.origin.y+=1.0
	clear_query.collision_mask=query.collision_mask
	clear_query.exclude=query.exclude
	clear_query.margin=query.margin
	check.call(rider._native_footprint_contact(space,clear_query,virtual).is_empty(),
		"PT24 footprint authentication: virtual point above the finite30mm ray reach cannot supply a plane without live contacts")
	var underside:=rest.duplicate()
	underside.point=Vector3(native.position.x,1.98,native.position.z)
	underside.normal=Vector3.DOWN
	check.call(rider._native_footprint_contact(space,clear_query,underside).is_empty(),
		"PT24 footprint authentication: an underside-only contact cannot supply an upward support")
	var wrong_owner:=rest.duplicate()
	wrong_owner.rid=rider.get_rid()
	var wrong_shape:=rest.duplicate()
	wrong_shape.shape=99
	check.call(rider._native_footprint_contact(space,query,wrong_owner).is_empty()
		and rider._native_footprint_contact(space,query,wrong_shape).is_empty(),
		"PT24 footprint authentication: wrong native RID and shape cannot reuse genuine coping contacts")
	var malformed:=rest.duplicate()
	malformed.normal=Vector3.UP*100
	var nonfinite:=rest.duplicate()
	nonfinite.point=Vector3.INF
	check.call(rider._native_footprint_contact(space,clear_query,malformed).is_empty()
		and rider._native_footprint_contact(space,clear_query,nonfinite).is_empty() and _state(rider)==before,
		"PT24 footprint authentication: malformed/nonfinite points cannot expand the30mm ray and leave physical state unchanged")



static func _historical_coping_controls(tree:SceneTree,check:Callable)->void:
	var fixture:Dictionary=await _fixture(tree,true)
	var bowl:Node3D=fixture.bowl
	var visual:MeshInstance3D=bowl.get_node("ContinuousBowlCoping")
	var torus:TorusMesh=visual.mesh
	var collision:CollisionShape3D=bowl._native_steel_coping.get_child(0)
	var inner:float=bowl.floor_radius+bowl.radius
	var old_datums:bool=absf(torus.outer_radius-torus.inner_radius-.090)<.000001 \
		and absf((torus.outer_radius+torus.inner_radius)*.5-inner)<.000001 \
		and absf(visual.position.y-bowl.radius-.025)<.000001 \
		and visual.transform==bowl._native_steel_coping.transform \
		and collision.shape.get_faces()==visual.mesh.get_faces() \
		and absf(Vector3(bowl.lip_frame(0).point).y-2.070)<.000001
	for point:Vector3 in bowl.get_grind_lines()[0].points:
		var local:Vector3=bowl.to_local(point)
		old_datums=old_datums and absf(local.y-bowl.radius-.070)<.00001 \
			and absf(Vector2(local.x,local.z).length()-inner)<.00001
	check.call(old_datums,"PT24 historical coping: original90mm section/70mm crown has matching actual native/display/lip/guide datums")
	var historical_check:=func(ok:bool,label:String):check.call(ok,"Historical90/70 fixture: "+label)
	_native_footprint_phase_controls(fixture,historical_check)
	_native_footprint_authentication_controls(fixture,historical_check)
	await _feature_air_coping_controls(tree,fixture,historical_check)
	fixture.viewport.queue_free()
	await tree.process_frame


static func _current_profile_controls(fixture:Dictionary,check:Callable)->void:
	var rider:CharacterBody3D=fixture.rider
	var bowl:Node3D=fixture.bowl
	var visual:MeshInstance3D=bowl.get_node("ContinuousBowlCoping")
	var torus:TorusMesh=visual.mesh
	check.call(absf(torus.outer_radius-torus.inner_radius-.060)<.000001 \
		and absf(visual.position.y-bowl.radius+.018)<.000001 \
		and absf(Vector3(bowl.lip_frame(0).point).y-2.012)<.000001,
		"PT24 current coping: actual60mm pipe section and12mm crown match the researched fixture")
	# At the old exact phase the thinner pipe needs no overlap correction.
	# Empty correction is not an invented support plane or a successful fit.
	rider.reset_skater()
	rider.global_transform=Transform3D(Basis(Vector3.UP,-PI*.5),Vector3(-10.647394,2.014172,139.5004))
	var before:Dictionary=_state(rider)
	var native:Dictionary=rider._native_floor_hit(Vector3.UP)
	var no_correction:Dictionary=rider._native_board_floor()
	var plane_clear:=false
	if not native.is_empty() and native.collider==bowl._native_annular_deck and native.normal==Vector3.UP:
		var floor_point:Vector3=Vector3(rider.global_position.x,Vector3(native.position).y,rider.global_position.z)
		var candidate:=Transform3D(rider.global_basis,floor_point+Vector3.UP*.008+rider.global_basis*rider._visual_rig._board_rest_position)
		plane_clear=rider._native_rim_frame_clear(candidate,0.0) and _volumes_clear(rider,candidate) \
			and rider._manual_model_frame_clear(candidate)
		for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
			var bearing:Vector3=candidate*(wheel.center)
			var support:Dictionary=rider._native_board_wheel_support(rider.get_world_3d().direct_space_state,bearing,bowl)
			plane_clear=plane_clear and not support.is_empty() and support.collider==bowl._native_annular_deck \
				and support.normal==Vector3.UP
		var penetrating:=candidate
		penetrating.origin.y-=.020
		check.call(not rider._native_rim_frame_clear(penetrating,0.0),
			"PT24 current coping: genuine20mm downward penetration still rejects at the old phase")
	check.call(no_correction.is_empty() and plane_clear and _state(rider)==before,
		"PT24 current coping: old exact phase has four native flat supports and clear actual model/tyres without a manufactured correction")
	for sample:Dictionary in CURRENT_EDGE_FRAMES:
		rider.reset_skater()
		rider.global_transform=sample.actor
		var pose:Transform3D=sample.board
		pose.basis=pose.basis.orthonormalized()
		rider._board_visual.global_transform=pose
		var physical:Dictionary=_state(rider)
		var physics:int=Engine.get_physics_frames()
		var observed:Dictionary=_current_native_face_bands(rider,bowl,pose)
		check.call(rider._native_rim_frame_clear(pose,0.0) and _volumes_clear(rider,pose) \
			and rider._manual_model_frame_clear(pose) and observed.owners_valid and observed.minimum_signed>=-.001 \
			and observed.near_face==sample.near_face and observed.far_face==sample.far_face and observed.unknown==sample.unknown,
			"PT24 current coping: recorded Main frame retains exact native model/tyre clearance and honest signed-face bands "+str(sample.physics))
		check.call(_state(rider)==physical and rider._board_visual.global_transform==pose and Engine.get_physics_frames()==physics,
			"PT24 current coping: static native witness changes no physical/board/time state "+str(sample.physics))
		print("PT24_CURRENT_COPING_FACE_BANDS ",{"source_physics":sample.physics,"observed":observed,
			"weight_bearing_claim":false,"rounded_static_fixture":true})
	var old_deep:=Transform3D(Basis(Vector3(.139809,-.400391,.905616),Vector3(-.297786,.855257,.424098),Vector3(-.944339,-.328973,.000342)),Vector3(-10.41023,2.108346,139.5383))
	check.call(not rider._manual_model_frame_clear(old_deep),
		"PT24 current coping: the retained deeply tilted actual old model remains rejected")


static func _current_native_face_bands(rider:CharacterBody3D,bowl:Node3D,pose:Transform3D)->Dictionary:
	# Signed proximity is not a tyre-load certificate. Preserve native normals,
	# vertical separations and every bounded miss; never manufacture support.
	var result:Dictionary={"near_face":0,"far_face":0,"unknown":0,"owners_valid":true,"minimum_signed":INF,"wheels":[]}
	var space:PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
	for wheel_index:int in rider._visual_rig.board_contact_geometry().wheels.size():
		var wheel:Dictionary=rider._visual_rig.board_contact_geometry().wheels[wheel_index]
		var minimum:float=INF
		var closest:Dictionary={}
		var misses:=0
		for vertex:Vector3 in wheel.points:
			var at:Vector3=pose*vertex
			var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.35,1|8,[rider.get_rid()]))
			if hit.is_empty():misses+=1;continue
			result.owners_valid=result.owners_valid and rider._native_bowl_hit_owned(hit,bowl)
			var signed_gap:float=(at-Vector3(hit.position)).dot(Vector3(hit.normal))
			if signed_gap<minimum:
				minimum=signed_gap
				closest={"vertex":at,"point":hit.position,"normal":hit.normal,"rid":hit.rid,"shape":hit.shape,
					"signed_face_gap":signed_gap,"vertical_separation":at.y-Vector3(hit.position).y}
		var label:="unknown_no_native_ray_hit"
		if is_finite(minimum):
			result.minimum_signed=minf(result.minimum_signed,minimum)
			if minimum>=.004 and minimum<=.030:result.near_face+=1;label="near_native_face"
			elif minimum>.030 and minimum<=.10:result.far_face+=1;label="far_native_face"
		else:result.unknown+=1
		result.wheels.append({"wheel":wheel_index,"classification":label,"missed_vertex_rays":misses,"closest":closest})
	return result
