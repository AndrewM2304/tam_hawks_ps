extends RefCounted
## Additional contact styles use the unchanged default GLB and native solids.
const Line = preload("res://game/tricks/grind_line.gd")
const Style = preload("res://game/tricks/grind_style.gd")
const Clearance = preload("res://game/tricks/grind_clearance.gd")
const Transfer = preload("res://game/tricks/grind_transfer.gd")
const MODEL := "res://game/art/assets/tam_skateboard/tam_skateboard.glb"
const CASES := [
	["nosegrind",0.0,-0.255], ["five_o_grind",0.0,0.255],
	["crooked_grind",-0.35,-0.255], ["overcrook_grind",0.35,-0.255],
	["smith_grind",-0.55,0.255], ["feeble_grind",0.55,0.255]]


static func run(tree: SceneTree, check: Callable) -> void:
	_math(check)
	await _native(tree,check)


static func _math(check: Callable) -> void:
	var line := Line.new("graded original steel",PackedVector3Array([Vector3(1,2,3),Vector3(3,5,-8)])) \
		.configure_contact(-0.07,0.07,"actual lowered graded cylinder")
	var pose := Style.ContactPose.new()
	for entry: Array in CASES:
		for direction: float in [-1.0,1.0]:
			for fakie: float in [0.0,PI]:
				for balance: float in [-0.8,0.0,0.8]:
					var solved := Style.solve_into(pose,line,4.0,direction,float(entry[1])+fakie,str(entry[0]),balance)
					check.call(solved and pose.anchor_count==1 and pose.max_error<=Style.CONTACT_TOLERANCE
						and pose.anchors[0]==Vector3(0,-0.103,float(entry[2]))
						and (pose.board_transform*pose.anchors[0]).distance_to(line.contact_at(4.0))<0.0001
						and _rigid(pose.board_transform.basis),
						"grind variants: real rigid hanger contact on grade %s direction=%s fakie=%s balance=%s"%[entry[0],direction,fakie,balance])
	var alias := Style.ContactPose.new()
	Style.solve_into(pose,line,4,1,PI,"grind_50_50",0.5)
	check.call(Style.solve_into(alias,line,4,1,PI,"rail_grind",0.5)
		and alias.board_transform==pose.board_transform and alias.anchors==pose.anchors and alias.supports==pose.supports,
		"grind variants: rail_grind compatibility uses the identical existing two-truck solve")
	for yaw: float in [-PI*0.5,PI*0.5]:
		check.call(Style.solve_into(pose,line,4,-1,yaw,"lipslide",0.8) and pose.anchor_count==1
			and pose.anchors[0]==Vector3(0,-0.014,0) and pose.max_error<=Style.CONTACT_TOLERANCE,
			"grind variants: signed Lipslide has the actual GLB deck bearing without claiming crossing history")
	var short := Line.new("short finite top",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-0.4)])) \
		.configure_contact(0,0,"finite box top")
	check.call(not Style.solve_into(pose,short,0.2,1,0,"rail_grind",0)
		and Style.solve_into(pose,short,0,1,0,"nosegrind",0) and pose.supports[0]==short.points[0],
		"grind variants: one truck may use a finite endpoint while two trucks still require the original rigid chord")
	for id: String in ["grind_pivot","unimplemented_tailslide"]:
		check.call(not Style.solve_into(pose,line,4,1,0,id,0) and not pose.valid and pose.anchor_count==0,
			"grind variants: an event or unknown ID cannot manufacture another physical pose "+id)
	check.call(not Style.solve_into(pose,line,4,1,0.6,"nosegrind",0)
		and not Style.solve_into(pose,line,4,1,-0.55,"feeble_grind",0),
		"grind variants: a mismatched yaw cannot borrow another named hanger contact")
	var unknown := Line.new("unverified",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-8)]))
	check.call(not Style.solve_into(pose,unknown,3,1,0,"nosegrind",0) and not pose.valid,
		"grind variants: unverified support never gains a named physical contact")


static func _native(tree: SceneTree, check: Callable) -> void:
	var root := Node3D.new()
	root.position = Vector3(500,20,500)
	tree.root.add_child(root)
	var board: Node3D = load(MODEL).instantiate()
	root.add_child(board)
	var rider := CharacterBody3D.new()
	root.add_child(rider)
	var meshes: Array = []
	_meshes(board,meshes)
	var cache := Clearance.new()
	check.call(cache.rebuild(board,{"meshes":meshes},rider.get_rid()) and cache.component_count==32,
		"grind variants native: the actual combined GLB caches32 welded solid components instead of one false hull")
	var beam := StaticBody3D.new()
	beam.collision_layer = 2
	beam.collision_mask = 0
	beam.position.y = -0.05
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.09,0.10,8)
	collision.shape = box
	beam.add_child(collision)
	root.add_child(beam)
	await _frames(tree,3)
	var line := Line.new("actual finite native steel",PackedVector3Array([
		root.to_global(Vector3(0,0,3)),root.to_global(Vector3(0,0,-3))])).configure_contact(0,0,"actual box crown")
	var pose := Style.ContactPose.new()
	var actual_faces := PackedVector3Array()
	for mesh: MeshInstance3D in meshes:
		var local := board.global_transform.affine_inverse()*mesh.global_transform
		for vertex: Vector3 in mesh.mesh.get_faces(): actual_faces.append(local*vertex)
	check.call(_surface_gap(Vector3(0,-0.103,-0.255),actual_faces)<0.0001
		and _surface_gap(Vector3(0,-0.103,0.255),actual_faces)<0.0001
		and _surface_gap(Vector3(0,-0.014,0),actual_faces)<0.0001,
		"grind variants native: loaded hanger/deck anchors are on actual retained GLB triangles")
	var entries := CASES.duplicate()
	entries.append(["lipslide",-PI*0.5,0.0])
	for entry: Array in entries:
		var sustained := true
		var previous := Transform3D.IDENTITY
		for frame in 12:
			var balance := lerpf(-0.8,0.8,float(frame)/11.0)
			sustained = Style.solve_into(pose,line,1.5+frame*0.08,1,float(entry[1]),str(entry[0]),balance) and sustained
			sustained = cache.allows(pose,Vector3.UP) and sustained
			if frame>0: sustained=cache.allows_path(previous,pose,Vector3.UP) and sustained
			previous=pose.board_transform
		check.call(sustained,
			"grind variants native: %s sustains actual thin-steel contact through travel and balance without ignoring its body"%entry[0])
	box.size.x = 0.44
	await _frames(tree,2)
	for entry: Array in entries:
		var solved := Style.solve_into(pose,line,3,1,float(entry[1]),str(entry[0]),0)
		check.call(solved and not cache.allows(pose,Vector3.UP),
			"grind variants native: actual wide steel rejects intersecting GLB wheel/hardware solids "+str(entry[0]))
	box.size.x = 0.09
	await _frames(tree,2)
	var first := Style.ContactPose.new()
	var last := Style.ContactPose.new()
	Style.solve_into(first,line,3,1,-PI*0.5,"lipslide",0)
	Style.solve_into(last,line,3,1,PI*0.5,"lipslide",0)
	check.call(cache.allows(first,Vector3.UP) and cache.allows(last,Vector3.UP)
		and not cache.allows_path(first.board_transform,last,Vector3.UP),
		"grind variants native: two clear deck poses cannot rotate their actual trucks through steel between frames")
	Style.solve_into(first,line,3,1,0,"grind_50_50",0)
	Style.solve_into(last,line,3,1,PI*0.5,"boardslide",0)
	check.call(cache.allows(first,Vector3.UP) and cache.allows(last,Vector3.UP)
		and not cache.allows_path(first.board_transform,last,Vector3.UP),
		"grind variants native: a direct loaded50-50 to deck slide requires real unweighting rather than a hidden steel crossing")
	await _transfers(tree,check,root,line,cache)
	Style.solve_into(first,line,1.3,1,0,"nosegrind",0)
	Style.solve_into(last,line,3.3,1,0,"nosegrind",0)
	var blocker := StaticBody3D.new()
	blocker.collision_layer = 1
	var shape := CollisionShape3D.new()
	var obstacle := BoxShape3D.new()
	obstacle.size = Vector3(0.025,0.025,0.025)
	shape.shape = obstacle
	blocker.add_child(shape)
	root.add_child(blocker)
	blocker.global_position=(first.board_transform*Vector3(0.126,-0.119,-0.255)
		+last.board_transform*Vector3(0.126,-0.119,-0.255))*0.5
	await _frames(tree,2)

	check.call(cache.allows(first,Vector3.UP) and cache.allows(last,Vector3.UP)
		and not cache.allows_path(first.board_transform,last,Vector3.UP),
		"grind variants native: exact endpoint solids stay clear while the cached continuous model sweep catches an intervening world blocker")
	check.call(not cache.rebuild(board,{},rider.get_rid()) and not cache.ready and not cache.allows(last,Vector3.UP),
		"grind variants native: a failed geometry rebuild clears prior clearance authority")
	root.queue_free()
	await _frames(tree,2)


static func _transfers(tree: SceneTree, check: Callable, root: Node3D, line: Line, cache: RefCounted) -> void:
	for target_id: String in ["boardslide","lipslide"]:
		var from := Style.ContactPose.new()
		var target := Style.ContactPose.new()
		Style.solve_into(from,line,2,1,0,"grind_50_50",0)
		var yaw := PI*0.5 if target_id=="boardslide" else -PI*0.5
		Style.solve_into(target,line,2,1,yaw,target_id,0)
		var transfer := Transfer.new()
		var admitted := transfer.begin(from.board_transform,target,Vector3.UP,cache)
		check.call(admitted and transfer.active and transfer.board_transform==from.board_transform
			and transfer.lift>0.0 and transfer.lift<=0.28,
			"grind transfer native: %s queues only a proved bounded lift/rotate/reseat and starts at the actual board frame"%target_id)
		var paused := transfer.board_transform
		var zero: Dictionary = transfer.step(0,target,Vector3.UP,cache)
		check.call(transfer.board_transform==paused and zero.active and not zero.complete,
			"grind transfer native: a zero-time tick cannot advance the unweight phase or complete its award")
		var phases := {}
		var completed := 0
		var failed := false
		var frames := 0
		var maximum_rate := 0.0
		for frame in 48:
			Style.solve_into(target,line,2+(frame+1)*0.05,1,yaw,target_id,0)
			var previous := transfer.board_transform
			var result: Dictionary = transfer.step(1.0/60.0,target,Vector3.UP,cache)
			maximum_rate = maxf(maximum_rate,previous.basis.get_rotation_quaternion().angle_to(transfer.board_transform.basis.get_rotation_quaternion())*60.0)
			phases[result.phase]=true
			frames+=1
			failed = failed or bool(result.failed)
			if result.complete: completed+=1
			if not result.active: break
		check.call(not failed and completed==1 and not transfer.active
			and frames>=ceili(transfer.duration*60.0) and frames<=ceili(transfer.duration*60.0)+3
			and maximum_rate<=Transfer.MAX_ANGULAR_SPEED+0.0001
			and phases.has("lift") and phases.has("rotate") and phases.has("reseat")
			and transfer.board_transform==target.board_transform and cache.allows(target,Vector3.UP),
			"grind transfer native: actual %s moves with its target and reseats at the bounded adaptive turn rate"%target_id)
		check.call(not transfer.step(1.0/60.0,target,Vector3.UP,cache).complete,
			"grind transfer native: a completed reseat can be committed once only")
	var from := Style.ContactPose.new()
	var target := Style.ContactPose.new()
	Style.solve_into(from,line,3,1,PI*0.5,"boardslide",0)
	Style.solve_into(target,line,3,1,-PI*0.5,"lipslide",0)
	var turn := Transfer.new()
	check.call(turn.begin(from.board_transform,target,Vector3.UP,cache) and turn.duration>0.49 and turn.duration<0.50,
		"grind transfer native: a real180-degree deck change receives its longer unweighted rotation phase")
	var rate := 0.0
	var completed := false
	for frame in 48:
		var before := turn.board_transform
		var result: Dictionary = turn.step(1.0/60.0,target,Vector3.UP,cache)
		rate = maxf(rate,before.basis.get_rotation_quaternion().angle_to(turn.board_transform.basis.get_rotation_quaternion())*60.0)
		if not result.active:
			completed = result.complete
			break
	check.call(completed and rate<=Transfer.MAX_ANGULAR_SPEED+0.0001 and turn.board_transform==target.board_transform,
		"grind transfer native: actual180-degree steel clearance keeps every displayed angular step below15rad/s")
	Style.solve_into(from,line,3,1,0,"grind_50_50",0)
	Style.solve_into(target,line,3,1,PI*0.5,"boardslide",0)
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.025,0.025,0.025)
	collision.shape = shape
	obstacle.add_child(collision)
	root.add_child(obstacle)
	obstacle.global_position = from.board_transform*Vector3(0.126,-0.119,-0.255)
	await _frames(tree,2)
	var transfer := Transfer.new()
	check.call(not transfer.begin(from.board_transform,target,Vector3.UP,cache)
		and not transfer.active and transfer.last_rejection=="start_obstruction",
		"grind transfer native: an actual starting wheel overlap cannot be laundered through a later clear lift")
	obstacle.queue_free()
	await _frames(tree,2)
	check.call(transfer.begin(from.board_transform,target,Vector3.UP,cache),
		"grind transfer native: removing the genuine start obstruction permits the same proved transfer")
	transfer.step(1.0/60.0,target,Vector3.UP,cache)
	var safe := transfer.board_transform
	check.call(transfer.cancel()==safe and not transfer.active
		and not transfer.step(1.0/60.0,target,Vector3.UP,cache).complete,
		"grind transfer native: dropping an incomplete transfer retains its last safe air frame without a completion")
	transfer.reset()
	check.call(not transfer.active and transfer.board_transform==Transform3D.IDENTITY and transfer.lift==0.0,
		"grind transfer native: restart clears old path, pose and pending completion")


static func _surface_gap(at: Vector3, faces: PackedVector3Array) -> float:
	var best := INF
	for index in range(0,faces.size(),3):
		var a := faces[index]
		var b := faces[index+1]
		var c := faces[index+2]
		var normal := (b-a).cross(c-a).normalized()
		var projected := at-normal*(at-a).dot(normal)
		if normal.length_squared()>0.5 and normal.dot((b-a).cross(projected-a))>=-0.0000001 \
			and normal.dot((c-b).cross(projected-b))>=-0.0000001 and normal.dot((a-c).cross(projected-c))>=-0.0000001:
			best=minf(best,at.distance_to(projected))
		for edge: Array in [[a,b],[b,c],[c,a]]:
			best=minf(best,at.distance_to(Geometry3D.get_closest_point_to_segment(at,edge[0],edge[1])))
	return best


static func _rigid(basis: Basis) -> bool:
	return absf(basis.determinant()-1.0)<0.00001 and basis.get_scale().distance_to(Vector3.ONE)<0.00001


static func _meshes(node: Node, meshes: Array) -> void:
	if node is MeshInstance3D and node.mesh!=null: meshes.append(node)
	for child: Node in node.get_children(): _meshes(child,meshes)


static func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
