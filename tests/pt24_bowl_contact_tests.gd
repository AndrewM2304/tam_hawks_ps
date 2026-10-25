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
	await _controls(tree,fixture,check)
	await _air_landing_controls(tree,fixture,check)
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


static func _state(body: CharacterBody3D) -> Dictionary:
	return {"transform":body.global_transform,"velocity":body.velocity,"speed":body.speed,
		"floor":body.is_on_floor(),"limit":body.floor_max_angle,"capsule":body.get_node("BodyCollision").transform,
		"air":body.airborne,"manual":body.manual_active,"balance":body.manual_balance,
		"transition":body.transition_active,"feature_state":body._feature_transition.state}


static func _controls(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
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
	await tree.physics_frame
	await tree.process_frame
	return {"viewport":viewport,"root":root,"bowl":bowl,"rider":rider,"control":control}
