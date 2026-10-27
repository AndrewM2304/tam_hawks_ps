extends RefCounted
## Two identical native bodies receive the same mapped wall-approach input.
## The old-presentation control differs only by omitting the visual fit.
const Skater = preload("res://game/player/skater.gd")
const Terrain = preload("res://game/levels/core_terrain.gd")
const Setup = preload("res://game/core/input_setup.gd")

class UnfittedSkater extends "res://game/player/skater.gd":
	func _place_obstacle_wheels(_delta: float) -> void:
		pass


static func run(tree: SceneTree,check: Callable) -> void:
	Setup.register_actions()
	var fixture := await _fixture(tree,-8.0)
	var rider: CharacterBody3D=fixture.rider
	var control: CharacterBody3D=fixture.control
	var parity := true
	var local_pose := true
	var contacts := 0
	var fitted := 0
	var minimum := INF
	var old_minimum := INF
	var maximum := 0.0
	Input.action_press("push",0.55)
	for tick: int in 200:
		await _frames(tree,1)
		parity=parity and _physics(rider)==_physics(control)
		local_pose=local_pose and rider._board_visual.transform==control._board_visual.transform \
			and rider._rider_visual.transform==control._rider_visual.transform
		if not _wall_contact(rider,fixture.wall):continue
		contacts+=1
		minimum=minf(minimum,_plane_gap(rider))
		old_minimum=minf(old_minimum,_plane_gap(control))
		maximum=maxf(maximum,rider._obstacle_visual_offset.length())
		if rider._obstacle_visual_offset.length()>0.001:fitted+=1
	_release()
	check.call(contacts>=12 and fitted==contacts and not rider.bail_active,
		"wall presentation: mapped Push reaches real native wall and every ordinary blocked frame admits its finite connected fit")
	check.call(old_minimum< -0.10 and minimum>=0.0079 and maximum<=0.18,
		"wall presentation: former-frame negative control penetrates over10cm while actual board and shoe vertices retain8mm skin within18cm")
	check.call(parity and local_pose,
		"wall presentation: physical transforms, velocity, floor, capsule and local board/rider pose stay identical to the unfitted control")
	print("WALL_PRESENTATION_INPUT ",{"contacts":contacts,"fits":fitted,"minimum":minimum,
		"old_minimum":old_minimum,"maximum_offset":maximum,"physical_equal":parity,"local_pose_equal":local_pose})
	for body: CharacterBody3D in [rider,control]:body.set_physics_process(false)
	var base: Transform3D=control._visual.transform
	var fitted_pose: Transform3D=rider._visual.transform
	var fitted_offset: Vector3=rider._obstacle_visual_offset
	for repetition: int in 12:
		rider._visual.transform=base
		rider._place_obstacle_wheels(1.0/60.0)
	check.call(rider._visual.transform.is_equal_approx(fitted_pose) and rider._obstacle_visual_offset.length()<=0.18,
		"wall presentation: repeated real-contact solves never accumulate displacement")
	await _eligibility(tree,fixture,base,check)
	# A larger-than-permitted declared presentation must be refused; never
	# move the capsule or silently enlarge the18cm bound to make a pose pass.
	rider._visual.transform=base
	rider._obstacle_visual_offset=Vector3.ZERO
	var old_board: Transform3D=rider._board_visual.transform
	rider._board_visual.position.z-=0.11
	var unchanged: Transform3D=rider._visual.transform
	rider._place_obstacle_wheels(1.0/60.0)
	check.call(rider._visual.transform==unchanged and rider._obstacle_visual_offset==Vector3.ZERO,
		"wall presentation: an actual board envelope needing more than18cm is rejected without a partial fit")
	rider._board_visual.transform=old_board
	await _obstruction_refusal(tree,fixture,base,check)
	# Clear native contact by moving the existing wall only in this declared
	# contact fixture. Preserve the current offset; validate its finite decay.
	fixture.wall.position.z=4.0
	await _frames(tree,2)
	rider.velocity=Vector3.ZERO
	rider.move_and_slide()
	rider._restore_platform_after_move()
	rider._obstacle_visual_offset=fitted_offset
	var previous := rider._obstacle_visual_offset.length()
	var decays := true
	for tick: int in 18:
		rider._visual.transform=base
		rider._place_obstacle_wheels(1.0/60.0)
		decays=decays and rider._obstacle_visual_offset.length()<=previous+0.000001
		previous=rider._obstacle_visual_offset.length()
	check.call(decays and previous<0.0003,
		"wall presentation: released contact decays to neutral without drift while all four candidate supports remain on the original plane")
	fixture.viewport.queue_free()
	await tree.process_frame
	await _edge_refusal(tree,check)
	_release()


static func _eligibility(_tree: SceneTree,fixture: Dictionary,base: Transform3D,check: Callable) -> void:
	var rider: CharacterBody3D=fixture.rider
	var original:=_physics(rider)
	for kind: String in ["air","manual","flip","grab","special","wallride","bail","crouch"]:
		rider._visual.transform=base
		rider._obstacle_visual_offset=Vector3(0,0,-0.10)
		match kind:
			"air":rider.airborne=true
			"manual":rider.manual_active=true
			"flip":rider._flip_remaining=0.1
			"grab":rider._grab_remaining=0.1
			"special":rider._special_remaining=0.1
			"wallride":rider._wall.active=true
			"bail":rider.bailing=true
			"crouch":rider.crouching=true
		var before:=_physics(rider)
		rider._place_obstacle_wheels(1.0/60.0)
		check.call(rider._visual.transform==base and rider._obstacle_visual_offset==Vector3.ZERO and _physics(rider)==before,
			"wall presentation: excluded active state preserves presentation/physics and clears stale offset "+kind)
		rider.airborne=false;rider.manual_active=false;rider._flip_remaining=0;rider._grab_remaining=0
		rider._special_remaining=0;rider._wall.active=false;rider.bailing=false;rider.crouching=false
	check.call(_physics(rider)==original,"wall presentation: declared inactive-state controls restore the original native fixture")


static func _obstruction_refusal(tree: SceneTree,fixture: Dictionary,base: Transform3D,check: Callable) -> void:
	var rider: CharacterBody3D=fixture.rider
	var obstacle:=StaticBody3D.new();fixture.root.add_child(obstacle)
	var shape:=BoxShape3D.new();shape.size=Vector3(1,0.16,0.06)
	var collision:=CollisionShape3D.new();collision.shape=shape
	collision.position=Vector3(0,0.08,-0.94);obstacle.add_child(collision)
	await _frames(tree,2)
	rider._visual.transform=base
	rider._obstacle_visual_offset=Vector3.ZERO
	rider._place_obstacle_wheels(1.0/60.0)
	check.call(rider._visual.transform==base and rider._obstacle_visual_offset==Vector3.ZERO,
		"wall presentation: a finite secondary obstruction beyond the rear axle refuses the fitted deck even when all four supports remain flat")
	obstacle.queue_free()
	await _frames(tree,2)


static func _edge_refusal(tree: SceneTree,check: Callable) -> void:
	var fixture := await _fixture(tree,-0.70)
	var rider: CharacterBody3D=fixture.rider
	var contacts := 0
	var refused := true
	Input.action_press("push",0.55)
	for tick: int in 90:
		await _frames(tree,1)
		if _wall_contact(rider,fixture.wall):
			contacts+=1
			refused=refused and rider._obstacle_visual_offset==Vector3.ZERO
	_release()
	check.call(contacts>=8 and refused and rider.is_on_floor(),
		"wall presentation: capsule-supported narrow ledge refuses any backoff whose actual rear wheel would lose finite support")
	fixture.viewport.queue_free()
	await tree.process_frame


static func _fixture(tree: SceneTree,north: float) -> Dictionary:
	var viewport:=SubViewport.new()
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var root:=Node3D.new();viewport.add_child(root)
	var terrain:=Terrain.new()
	terrain.add_patch(root,"FiniteFlat",Rect2(-4,north,8,8-north),Vector4.ZERO,StandardMaterial3D.new())
	var wall:=StaticBody3D.new();wall.name="ActualClosedShutter";root.add_child(wall)
	var shape:=BoxShape3D.new();shape.size=Vector3(3,2.8,0.18)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=1.4;wall.add_child(collision)
	var rider:=Skater.new()
	var control:=UnfittedSkater.new()
	for body: CharacterBody3D in [rider,control]:
		body.spawn_position=Vector3(0,0.04,-3.0 if north< -1 else -0.48)
		root.add_child(body)
		body.rotation.y=PI
	await _frames(tree,4)
	return {"viewport":viewport,"root":root,"rider":rider,"control":control,"wall":wall}


static func _wall_contact(body: CharacterBody3D,wall: Node3D) -> bool:
	for index: int in body.get_slide_collision_count():
		if body.get_slide_collision(index).get_collider()==wall:return true
	return false


static func _plane_gap(body: CharacterBody3D) -> float:
	# Independently declared shutter's north plane is Z=-0.09. Measure actual
	# authored vertices, not the production correction or capsule bounds.
	var result:=INF
	for mesh: MeshInstance3D in body._visual_rig._board_meshes:
		for point: Vector3 in mesh.mesh.get_faces():result=minf(result,-0.09-mesh.to_global(point).z)
	for leg: Dictionary in body._visual_rig._legs:
		for child: Node in leg.foot.get_children():
			if not child is MeshInstance3D:continue
			for point: Vector3 in child.mesh.get_faces():result=minf(result,-0.09-child.to_global(point).z)
	return result


static func _physics(body: CharacterBody3D) -> Dictionary:
	return {"transform":body.global_transform,"velocity":body.velocity,"speed":body.speed,
		"floor":body.is_on_floor(),"normal":body.get_floor_normal(),"air":body.airborne,
		"manual":body.manual_active,"bail":body.bail_active,"capsule":body.get_node("BodyCollision").transform}


static func _release() -> void:
	for action: String in ["push","brake","steer_left","steer_right","manual","ollie","grind"]:Input.action_release(action)


static func _frames(tree: SceneTree,count: int) -> void:
	for index: int in count:
		await tree.physics_frame
		await tree.process_frame
