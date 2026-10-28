extends RefCounted
## Fresh native support parity; this measures allocation counts, not timing.
const Skater = preload("res://game/player/skater.gd")
const Terrain = preload("res://game/levels/core_terrain.gd")
const Bowl = preload("res://game/levels/bowl_feature.gd")
const Park = preload("res://game/levels/kelvingrove_skatepark.gd")
const BowlChecks = preload("res://tests/pt24_bowl_contact_tests.gd")
const Setup = preload("res://game/core/input_setup.gd")

class PairedSupport extends Skater:
	var fresh_parameters := false
	var allocations := 0
	var requests: Array[Dictionary] = []
	func _native_board_floor_ray(space: PhysicsDirectSpaceState3D,from: Vector3,to: Vector3) -> Dictionary:
		var parameter: PhysicsRayQueryParameters3D
		var hit: Dictionary
		if fresh_parameters:
			allocations+=1
			parameter=PhysicsRayQueryParameters3D.create(from,to,collision_mask,[get_rid()])
			hit=space.intersect_ray(parameter)
		else:
			hit=super._native_board_floor_ray(space,from,to)
			parameter=_board_floor_ray
		requests.append({"from":parameter.from,"to":parameter.to,"mask":parameter.collision_mask,
			"exclude":parameter.exclude,"flags":[parameter.collide_with_bodies,parameter.collide_with_areas,
				parameter.hit_back_faces,parameter.hit_from_inside],"hit":hit.duplicate(true)})
		return hit


static func run(tree: SceneTree,check: Callable) -> void:
	Setup.register_actions()
	for action: StringName in InputMap.get_actions():Input.action_release(action)
	var fixture := await _fixture(tree)
	_solver_pairs(fixture,check)
	await _partial_bank_controls(tree,fixture,check)
	await _native_parameters(tree,fixture,check)
	fixture.viewport.queue_free()
	await tree.process_frame


static func _solver_pairs(fixture: Dictionary,check: Callable) -> void:
	var rider: CharacterBody3D=fixture.rider
	var parameter_id: int=rider._board_floor_ray.get_instance_id()
	var native_rays := 0
	var pairs := 0
	for record: Dictionary in [
		{"name":"ordinary flat","at":Vector3(0,0.08,0),"minimum":4,"maximum":4,"fit":false},
		{"name":"lowered six-centimetre split fit blocked by upper step","at":Vector3(20.01,0.14,0),"minimum":16,"maximum":16,"fit":false,"blocked_by":"StepUpper"},
		{"name":"clear six-centimetre split step","at":Vector3(19.94,0.14,0),"minimum":16,"maximum":16,"fit":true,"model_clear":true},
		{"name":"finite support edge","at":Vector3(40,0.08,0),"minimum":1,"maximum":4,"fit":false},
		{"name":"missing lower side of tall step","at":Vector3(30.01,0.88,0),"minimum":1,"maximum":4,"fit":false},
		{"name":"ordinary finite bank","at":Vector3(60,2.08,0),"minimum":4,"maximum":4},
		{"name":"unrelated steep surface","at":Vector3(80,16.08,0),"minimum":0,"maximum":0,"fit":false},
		{"name":"absent floor","at":Vector3(200,0.08,0),"minimum":0,"maximum":0,"fit":false},
	]:
		rider.global_position=record.at
		rider.rotation=Vector3.ZERO
		var result := _pair(rider)
		var count: int=result.rays
		native_rays+=count
		pairs+=1
		var model_ok := true
		if record.has("blocked_by"):
			model_ok=rider._grind_clearance.last_rejection=="model_obstruction" \
				and rider._grind_clearance.last_obstruction.get("collider")==fixture.root.get_node(str(record.blocked_by))
		if bool(record.get("model_clear",false)):
			model_ok=not result.fit.is_empty() and rider._grind_clearance.allows_frame(
				BowlChecks._presentation_pose(rider,result.fit),Vector3(result.fit.normal))
		check.call(result.equal and model_ok and count>=int(record.minimum) and count<=int(record.maximum)
			and (not record.has("fit") or (not result.fit.is_empty())==bool(record.fit)),
			"board ray reuse: exact native support, query order/count and unchanged rider/presentation for "+record.name)
		print("BOARD_SUPPORT_RAY_PAIR ",{"case":record.name,"rays":count,"fit":result.fit,"equal":result.equal})
	for index: int in BowlChecks.WITNESSES.size():
		rider.global_position=BowlChecks.WITNESSES[index].at
		rider.rotation.y=-PI*0.5
		var result := _pair(rider)
		native_rays+=int(result.rays)
		pairs+=1
		check.call(result.equal and not result.fit.is_empty() and int(result.rays)==16,
			"board ray reuse: exact finite wrapped-bowl fit and all sixteen native rays at recorded witness "+str(index))
	fixture.bowl.wrap_lateral=false
	for index: int in BowlChecks.WITNESSES.size():
		rider.global_position=BowlChecks.WITNESSES[index].at
		var result := _pair(rider)
		native_rays+=int(result.rays)
		pairs+=1
		check.call(result.equal and result.fit.is_empty(),
			"board ray reuse: removing wrapped ownership still rejects the same real steep native supports "+str(index))
	fixture.bowl.wrap_lateral=true
	check.call(rider.allocations==native_rays and native_rays>60
		and rider._board_floor_ray.get_instance_id()==parameter_id,
		"board ray reuse: fresh control constructs one parameter per unchanged native support ray while the actual solver retains one")
	print("BOARD_SUPPORT_RAY_REUSE ",{"pairs":pairs,"native_support_rays":native_rays,
		"fresh_parameter_objects":rider.allocations,"retained_parameter_objects":1})


static func _partial_bank_controls(tree:SceneTree,fixture:Dictionary,check:Callable)->void:
	# Original authored geometry at its real distant world origin. At this
	# pose tyre centres have left Z-177, but their finite contours still bear
	# on BeginnerArrivalBank. No moved route target or fictional support plane.
	var park:=Park.new()
	park.position=Vector3(-207.5,14.5,-187.5)
	fixture.root.add_child(park)
	await _frames(tree,2)
	var rider:CharacterBody3D=fixture.rider
	var initial_allocations:int=rider.allocations
	var parameter_id:int=rider._board_floor_ray.get_instance_id()
	rider.global_position=Vector3(-199.9204,13.01199,-176.7438)
	rider.rotation=Vector3.ZERO
	var before:=_state(rider)
	var positive:=_pair(rider)
	var valid:bool=positive.equal and positive.rays==4 and not positive.fit.is_empty()
	var pose:=Transform3D.IDENTITY
	if valid:
		pose=BowlChecks._presentation_pose(rider,positive.fit)
		valid=BowlChecks._volumes_clear(rider,pose) \
			and rider._grind_clearance.allows_frame(pose,Vector3(positive.fit.normal))
	check.call(valid,"board ray reuse: exact finite arrival-bank tyre footprint yields a native-clear full-model fit with four unchanged centre rays")
	print("BOARD_PARTIAL_BANK ",{"fit":positive.fit,"rays":positive.rays,"equal":positive.equal,"full_clear":valid})
	if not valid:return
	# This2mm foreign wall intersects the nose beyond the physical capsule
	# and all four tyres. Full connected-model validation must still refuse it.
	var blocker:=StaticBody3D.new()
	blocker.name="PartialBankForeignEndpoint"
	blocker.position=rider.global_position+Vector3(0,1,-.38)
	blocker.collision_layer=1
	blocker.collision_mask=0
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(.65,4,.002)
	collision.shape=shape
	blocker.add_child(collision)
	fixture.root.add_child(blocker)
	await _frames(tree,2)
	var capsule:=PhysicsShapeQueryParameters3D.new()
	capsule.shape=rider.get_node("BodyCollision").shape
	capsule.transform=rider.get_node("BodyCollision").global_transform
	capsule.collision_mask=1|8
	capsule.exclude=[rider.get_rid()]
	capsule.margin=0.0
	var body_clear:bool=rider.get_world_3d().direct_space_state.intersect_shape(capsule,1).is_empty()
	var tyres_clear:bool=BowlChecks._volumes_clear(rider,pose)
	var model_blocked:bool=not rider._grind_clearance.allows_frame(pose,Vector3(positive.fit.normal)) \
		and rider._grind_clearance.last_obstruction.get("collider")==blocker
	var negative:=_pair(rider)
	check.call(body_clear and tyres_clear and model_blocked and negative.equal and negative.rays==4 \
		and negative.fit.is_empty() and _state(rider)==before,
		"board ray reuse: a foreign2mm nose blocker refuses the footprint fit while native capsule and all four tyres remain clear")
	blocker.queue_free()
	await _frames(tree,2)
	var restored:=_pair(rider)
	valid=restored.equal and restored.rays==4 and not restored.fit.is_empty() and _state(rider)==before \
		and rider.allocations-initial_allocations==12 and rider._board_floor_ray.get_instance_id()==parameter_id
	if valid:
		pose=BowlChecks._presentation_pose(rider,restored.fit)
		valid=BowlChecks._volumes_clear(rider,pose) \
			and rider._grind_clearance.allows_frame(pose,Vector3(restored.fit.normal))
	check.call(valid,"board ray reuse: removing the actual foreign blocker restores the same finite-support eligibility without stale refusal")
	print("BOARD_PARTIAL_BANK_PARITY ",{"pairs":3,"support_rays":12,
		"fresh_parameter_objects":rider.allocations-initial_allocations,"retained_parameter_objects":1})


static func _pair(rider: CharacterBody3D) -> Dictionary:
	var before := _state(rider)
	rider.fresh_parameters=false
	rider.requests.clear()
	var fit: Dictionary=rider._native_board_floor()
	var trace: Array=rider.requests.duplicate(true)
	rider.fresh_parameters=true
	rider.requests.clear()
	var control: Dictionary=rider._native_board_floor()
	var equal: bool=fit==control and trace==rider.requests and _state(rider)==before
	rider.fresh_parameters=false
	return {"equal":equal,"fit":fit,"rays":trace.size()}


static func _native_parameters(tree: SceneTree,fixture: Dictionary,check: Callable) -> void:
	var rider: CharacterBody3D=fixture.rider
	var space: PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
	var parameter: PhysicsRayQueryParameters3D=rider._board_floor_ray
	var parameter_id:=parameter.get_instance_id()
	var defaults:=PhysicsRayQueryParameters3D.create(Vector3.ZERO,Vector3.ONE,rider.collision_mask,[rider.get_rid()])
	check.call(_flags(parameter)==_flags(defaults),
		"board ray reuse: every native body/area/back-face/inside flag remains equal to the original factory")
	var boxes: Array[StaticBody3D]=[]
	for record: Array in [[100.0,1],[104.0,8],[108.0,2]]:
		var box:=_box(Vector3(record[0],1,0),int(record[1]))
		fixture.root.add_child(box)
		boxes.append(box)
	var area:=Area3D.new()
	area.position=Vector3(112,1,0)
	var area_shape:=CollisionShape3D.new()
	area_shape.shape=BoxShape3D.new()
	area.add_child(area_shape)
	fixture.root.add_child(area)
	await _frames(tree,2)
	for record: Array in [[100.0,true],[104.0,true],[108.0,false],[112.0,false]]:
		var from:=Vector3(record[0],3,0)
		var to:=Vector3(record[0],0,0)
		var actual: Dictionary=rider._native_board_floor_ray(space,from,to)
		var control:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,rider.collision_mask,[rider.get_rid()]))
		check.call(actual==control and (not actual.is_empty())==bool(record[1]),
			"board ray reuse: actual layer1/layer8 versus layer2/area hit boundary matches fresh parameters x="+str(record[0]))
	# Put the actual rider in this ray on its normal player-only layer. The
	# unexcluded native control must hit it; the helper must restore self-only
	# exclusion even after another RID was deliberately left in the resource.
	rider.collision_mask=2
	rider.global_position=Vector3(108,2,0)
	await _frames(tree,2)
	var from:=Vector3(108,5,0)
	var to:=Vector3(108,0,0)
	parameter.exclude=[boxes[2].get_rid()]
	var hit: Dictionary=rider._native_board_floor_ray(space,from,to)
	var control:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,2,[rider.get_rid()]))
	var unexcluded:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,2))
	check.call(hit==control and hit.get("collider")==boxes[2] and unexcluded.get("collider")==rider
		and parameter.exclude==[rider.get_rid()] and parameter.collision_mask==2,
		"board ray reuse: a current mask change and stale exclusions cannot hide the finite support or hit the rider itself")
	rider.collision_mask=1|8
	check.call(rider._native_board_floor_ray(space,from,to).is_empty() and parameter.collision_mask==(1|8),
		"board ray reuse: restoring the normal mask immediately excludes the same layer2 support")
	boxes[2].position.x+=2.0
	await _frames(tree,2)
	rider.collision_mask=2
	var moved: Dictionary=rider._native_board_floor_ray(space,from,to)
	control=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,2,[rider.get_rid()]))
	check.call(moved==control and moved.is_empty() and hit.get("collider")==boxes[2]
		and Vector3(hit.get("position",Vector3.INF)).distance_to(Vector3(108,1.5,0))<0.00001,
		"board ray reuse: moving a finite blocker is observed immediately without altering the earlier returned hit dictionary")
	rider.collision_mask=1|8
	check.call(parameter.get_instance_id()==parameter_id,
		"board ray reuse: one persistent parameter identity survives changing endpoints, masks, exclusions, layers and native blocker movement")


static func _flags(query: PhysicsRayQueryParameters3D) -> Array:
	return [query.collide_with_bodies,query.collide_with_areas,query.hit_back_faces,query.hit_from_inside]


static func _state(rider: CharacterBody3D) -> Dictionary:
	var result:=BowlChecks._state(rider)
	result["visual"]=rider._visual.global_transform
	result["board"]=rider._board_visual.transform
	return result


static func _fixture(tree: SceneTree) -> Dictionary:
	var viewport:=SubViewport.new()
	viewport.own_world_3d=true
	viewport.size=Vector2i(640,480)
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var root:=Node3D.new()
	viewport.add_child(root)
	var terrain:=Terrain.new()
	var material:=StandardMaterial3D.new()
	terrain.add_patch(root,"Flat",Rect2(-8,-8,16,16),Vector4.ZERO,material)
	terrain.add_patch(root,"StepLower",Rect2(12,-8,8,16),Vector4.ZERO,material)
	terrain.add_patch(root,"StepUpper",Rect2(20,-8,8,16),Vector4.ONE*0.06,material)
	terrain.add_patch(root,"TallStepLower",Rect2(28,-8,2,16),Vector4.ZERO,material)
	terrain.add_patch(root,"TallStepUpper",Rect2(30,-8,4,16),Vector4.ONE*0.8,material)
	terrain.add_patch(root,"FiniteEdge",Rect2(39.98,-8,0.04,16),Vector4.ZERO,material)
	terrain.add_patch(root,"Bank",Rect2(52,-8,16,16),Vector4(0,4,4,0),material)
	terrain.add_patch(root,"UnrelatedSteep",Rect2(72,-8,16,16),Vector4(0,32,32,0),material)
	var bowl:=Bowl.new()
	bowl.radius=2.4
	bowl.floor_radius=3.5
	bowl.deck_length=1.8
	bowl.build_access=false
	bowl.position=Vector3(-7,-0.4,134.5)
	bowl.rotation.y=PI*0.5
	root.add_child(bowl)
	var rider:=PairedSupport.new()
	root.add_child(rider)
	rider.set_process(false)
	rider.set_physics_process(false)
	await _frames(tree,2)
	return {"viewport":viewport,"root":root,"rider":rider,"bowl":bowl}


static func _box(at: Vector3,layer: int) -> StaticBody3D:
	var body:=StaticBody3D.new()
	body.position=at
	body.collision_layer=layer
	var collision:=CollisionShape3D.new()
	collision.shape=BoxShape3D.new()
	body.add_child(collision)
	return body


static func _frames(tree: SceneTree,count: int) -> void:
	for frame: int in count:
		await tree.physics_frame
		await tree.process_frame
