extends RefCounted
## Independent cloth deformation checks: actual vertex weights, Skin binds and
## Skeleton global poses, rather than healthy-looking control-node positions.
const Classic = preload("res://tests/classic_tricks_integration_tests.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const SETTLED_SEAM_LIMIT := 0.08
const SETTLED_JOINT_LIMIT := 0.06


static func run(tree: SceneTree,check: Callable) -> void:
	Classic.Setup.register_actions()
	for interrupt: bool in [false,true]:
		await _sequence(tree,check,interrupt)
	await _full_grabs(tree,check)
	Classic._release()


static func _sequence(tree: SceneTree,check: Callable,interrupt: bool) -> void:
	var fixture: Dictionary = await Classic._fixture(tree)
	# Keep the complete long post-grab/manual sequence on the declared floor;
	# an unrelated edge fall must not replace the requested local recovery.
	fixture.root.get_child(0).get_child(0).shape.size=Vector3(300,0.4,300)
	var rider: CharacterBody3D = fixture.rider
	var rig: RefCounted = rider._visual_rig
	var data := _prepare(rig)
	var neutral := _sample(rider,data)
	check.call(data.hem.size()>=20 and data.waist.size()>=20 and data.thigh.size()>=2
		and neutral.finite and neutral.seam<SETTLED_SEAM_LIMIT,
		"body attachment: actual neutral skinned hem/waist vertices and native bind mappings form one figure")
	# A deliberately wrong torso bind moves the drawn jacket while every
	# control node, bone pose and limb length remains untouched.
	var jacket: MeshInstance3D = data.jacket
	var original: Skin = jacket.skin
	var corrupt := original.duplicate(true) as Skin
	var torso_bind := _bind_for(corrupt,data.skeleton,"torso")
	var wrong := corrupt.get_bind_pose(torso_bind)
	wrong.origin.y-=0.8
	corrupt.set_bind_pose(torso_bind,wrong)
	jacket.skin=corrupt
	var negative := _sample(rider,data)
	check.call(negative.seam>0.5 and negative.joint_gap==neutral.joint_gap,
		"body attachment: a detached torso bind is rejected even when node/bone joint distances remain unchanged")
	jacket.skin=original
	var events: Array[String] = []
	var on_trick := func(label: String,_points: int) -> void: events.append(label)
	rider.trick_performed.connect(on_trick)
	Input.action_press("push")
	await _observe(tree,rider,data,30,"before_grab_push")
	Input.action_release("push")
	Input.action_press("ollie")
	await _observe(tree,rider,data,18,"crouch")
	Input.action_release("ollie")
	await _observe(tree,rider,data,3,"ollie")
	Classic._direction(Vector2.LEFT)
	Classic._key(KEY_K,true)
	var active := await _observe(tree,rider,data,10,"active_grab")
	check.call(active.maximum_influence>.9 and active.maximum_seam<0.12 and active.maximum_joint_gap<0.12,
		"body attachment: partial-to-full actual grab keeps its skinned torso connected to pelvis and thighs")
	var grabbed: bool = rider.active_grab_id=="melon_grab" and events.has("Melon Grab")
	Classic._key(KEY_K,false)
	Classic._direction(Vector2.ZERO)
	if interrupt:
		rider.begin_bail("attachment_grab_interruption")
		rider.begin_bail("attachment_repeated_request")
		rider.recover_to(rider.global_position+Vector3.RIGHT)
		var bail := await _observe(tree,rider,data,180,"grab_bail_getup")
		check.call(bail.phases.has("get_up") and bail.maximum_surface_gap<0.05 and bail.maximum_joint_gap<0.10 and bail.maximum_neck_gap<0.05,
			"body attachment: interrupted/repeated grab bail keeps actual waist/neck geometry attached through get-up")
	else:
		await _observe(tree,rider,data,60,"grab_landing")
	Input.action_press("push",0.25)
	var recovered := await _observe(tree,rider,data,180,"after_grab_bail_push" if interrupt else "after_grab_push")
	Input.action_release("push")
	check.call(grabbed,"body attachment: real mapped Ollie/K input enters the intended grab before release/interruption")
	check.call(not rider.bailing and rider.is_on_floor() and recovered.samples>=180,
		"body attachment: released/interrupted grab returns to real supported skating")
	check.call(recovered.finite and recovered.maximum_seam<SETTLED_SEAM_LIMIT
		and recovered.maximum_joint_gap<SETTLED_JOINT_LIMIT and recovered.maximum_neck_gap<0.05,
		"body attachment: skinned torso/waist and global pelvis joint remain attached after "+("grab/bail/get-up" if interrupt else "grab/release"))
	print("BODY_ATTACHMENT_RESULT interrupt=",interrupt," neutral=",neutral," settled=",recovered,
		" negative_bind_seam=",negative.seam," events=",events)
	if not interrupt:
		Input.action_press("ollie")
		await _observe(tree,rider,data,18,"post_grab_flip_crouch")
		Input.action_release("ollie")
		await _observe(tree,rider,data,3,"post_grab_flip_pop")
		Classic._key(KEY_J,true)
		await _observe(tree,rider,data,3,"post_grab_flip")
		Classic._key(KEY_J,false)
		var flip := await _observe(tree,rider,data,90,"post_flip_landing")
		check.call(events.has("Kickflip") and flip.maximum_seam<SETTLED_SEAM_LIMIT and flip.maximum_joint_gap<SETTLED_JOINT_LIMIT,
			"body attachment: real post-grab flip and landing keep the actual torso/waist attached")
		Input.action_press("manual")
		var failure := await _observe(tree,rider,data,300,"actual_unbalanced_manual_failure")
		Input.action_release("manual")
		check.call(failure.phases.has("fall") and failure.phases.has("get_up") and not rider.bailing
			and failure.maximum_surface_gap<0.05 and failure.maximum_joint_gap<0.10 and failure.maximum_neck_gap<0.05,
			"body attachment: a real uncorrected manual failure preserves cloth attachment through recovery")
	else:
		rider.begin_bail("attachment_restart_interruption")
		await _observe(tree,rider,data,12,"interrupted_bail")
		rider.reset_skater()
		Input.action_press("push",0.25)
		var restart := await _observe(tree,rider,data,60,"restart_then_push")
		Input.action_release("push")
		check.call(not rider.bailing and restart.maximum_seam<SETTLED_SEAM_LIMIT and restart.maximum_joint_gap<SETTLED_JOINT_LIMIT,
			"body attachment: explicit restart during a fall restores actual connected mesh skinning before skating")
	rider.trick_performed.disconnect(on_trick)
	await Classic._dispose(tree,fixture)


static func _prepare(rig: RefCounted) -> Dictionary:
	var skeleton: Skeleton3D = rig._garments.skeleton
	var jacket: MeshInstance3D = rig._rider.get_node("SkinnedJacket")
	var trousers: MeshInstance3D = rig._rider.get_node("SkinnedTrousers")
	var result := {"rig":rig,"skeleton":skeleton,"jacket":jacket,"trousers":trousers,"hem":[],"waist":[],"thigh":[],"neck":[],"anatomical_neck":PackedVector3Array(),"waist_triangles":PackedVector3Array()}
	for pair: Array in [[jacket,"hem"],[trousers,"waist"],[trousers,"thigh"],[jacket,"neck"]]:
		var mesh: MeshInstance3D = pair[0]
		var arrays := mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := bones.size()/vertices.size()
		for index: int in vertices.size():
			var point := vertices[index]
			var select := false
			if pair[1]=="hem": select=absf(point.y-0.955)<0.0001 and _weight_named(mesh.skin,skeleton,bones,weights,index,stride,"torso")>.99
			elif pair[1]=="waist": select=absf(point.y-1.01)<0.0001 and _weight_named(mesh.skin,skeleton,bones,weights,index,stride,"hips")>.99
			elif pair[1]=="neck": select=absf(point.y-1.435)<0.0001 and _weight_named(mesh.skin,skeleton,bones,weights,index,stride,"torso")>.99
			else: select=absf(point.y-0.965)<0.0001 and absf(point.x)>0.01 and absf(point.x)<0.22
			if select: result[pair[1]].append({"point":point,"bones":bones.slice(index*stride,(index+1)*stride),"weights":weights.slice(index*stride,(index+1)*stride)})
	var head: MeshInstance3D = rig._head.get_node("AnatomicalHead")
	var head_vertices: PackedVector3Array = head.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for point: Vector3 in head_vertices:
		if absf(point.y+0.13)<0.0001: result.anatomical_neck.append(point)
	var arrays := trousers.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride := bones.size()/vertices.size()
	for index: int in range(0,indices.size(),3):
		var pure_waist := true
		for corner: int in 3:
			pure_waist=pure_waist and _weight_named(trousers.skin,skeleton,bones,weights,indices[index+corner],stride,"hips")>.999
		if pure_waist:
			for corner: int in 3: result.waist_triangles.append(vertices[indices[index+corner]])
	return result


static func _weight_named(skin: Skin,skeleton: Skeleton3D,bones: PackedInt32Array,weights: PackedFloat32Array,index: int,stride: int,name: String) -> float:
	var total := 0.0
	for influence: int in stride:
		var bind := bones[index*stride+influence]
		var bone := _bone_for(skin,skeleton,bind)
		if bone>=0 and skeleton.get_bone_name(bone)==name: total+=weights[index*stride+influence]
	return total


static func _bone_for(skin: Skin,skeleton: Skeleton3D,bind: int) -> int:
	var bone := skin.get_bind_bone(bind)
	return skeleton.find_bone(String(skin.get_bind_name(bind))) if bone<0 else bone


static func _bind_for(skin: Skin,skeleton: Skeleton3D,name: String) -> int:
	for bind: int in skin.get_bind_count():
		if skeleton.get_bone_name(_bone_for(skin,skeleton,bind))==name: return bind
	return -1


static func _center(mesh: MeshInstance3D,skeleton: Skeleton3D,points: Array,rendered: bool = false) -> Vector3:
	var result := Vector3.ZERO
	for record: Dictionary in points:
		var deformed := Vector3.ZERO
		for influence: int in record.bones.size():
			var bind: int = record.bones[influence]
			var bone := _bone_for(mesh.skin,skeleton,bind)
			deformed+=(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind)*Vector3(record.point))*float(record.weights[influence])
		var frame := skeleton.get_global_transform_interpolated() if rendered and skeleton.is_physics_interpolated_and_enabled() else skeleton.global_transform
		result+=frame*deformed
	return result/maxi(1,points.size())


static func _sample(rider: Node3D,data: Dictionary,rendered: bool = false) -> Dictionary:
	var skeleton: Skeleton3D = data.skeleton
	var hem := _center(data.jacket,skeleton,data.hem,rendered)
	var waist := _center(data.trousers,skeleton,data.waist,rendered)
	var thigh := _center(data.trousers,skeleton,data.thigh,rendered)
	var torso := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("torso")).origin
	var hips := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hips")).origin
	var head: MeshInstance3D = data.rig._head.get_node("AnatomicalHead")
	var head_center := head.global_transform*head.mesh.get_aabb().get_center()
	var neck := Vector3.ZERO
	var root_frame := skeleton.get_global_transform_interpolated() if rendered and skeleton.is_physics_interpolated_and_enabled() else skeleton.global_transform
	var head_frame := root_frame*skeleton.global_transform.affine_inverse()*head.global_transform
	for point: Vector3 in data.anatomical_neck: neck+=head_frame*point
	neck/=maxi(1,data.anatomical_neck.size())
	var collar := _center(data.jacket,skeleton,data.neck,rendered)
	var surface_gap := _surface_gap(data,root_frame) if rider is CharacterBody3D and rider.bailing else 0.0
	return {"hem":hem,"waist":waist,"thigh":thigh,"seam":hem.distance_to(waist),"joint_gap":torso.distance_to(hips),
		"neck_gap":neck.distance_to(collar),"anatomical_neck_vertices":data.anatomical_neck.size(),
		"surface_gap":surface_gap,
		"head":head_center,"finite":hem.is_finite() and waist.is_finite() and thigh.is_finite() and head_center.is_finite(),
		"grab_blend":data.rig._grab_blend,"body":rider.global_position,"bail":rider.bail_phase if rider is CharacterBody3D else "rig_fixture","rendered":rendered}


static func _observe(tree: SceneTree,rider: CharacterBody3D,data: Dictionary,count: int,phase: String) -> Dictionary:
	var result := {"samples":0,"maximum_seam":0.0,"maximum_joint_gap":0.0,"maximum_neck_gap":0.0,"maximum_surface_gap":0.0,"maximum_influence":0.0,"finite":true,"worst":{},"phases":[]}
	for frame: int in count:
		await tree.physics_frame
		await tree.create_timer(0.0,false,false).timeout
		for rendered: bool in [false,true]:
			var sample := _sample(rider,data,rendered)
			result.finite=result.finite and sample.finite
			if sample.seam>result.maximum_seam:
				result.maximum_seam=sample.seam
				result.worst=sample
			result.maximum_joint_gap=maxf(result.maximum_joint_gap,sample.joint_gap)
			result.maximum_neck_gap=maxf(result.maximum_neck_gap,sample.neck_gap)
			result.maximum_influence=maxf(result.maximum_influence,sample.grab_blend)
			result.maximum_surface_gap=maxf(result.maximum_surface_gap,sample.surface_gap)
		if rider.bailing and not result.phases.has(rider.bail_phase): result.phases.append(rider.bail_phase)
		result.samples+=1
	print("BODY_ATTACHMENT_PHASE ",phase," ",result)
	return result


static func _surface_gap(data: Dictionary,frame: Transform3D) -> float:
	var skeleton: Skeleton3D = data.skeleton
	var trousers: MeshInstance3D = data.trousers
	var bind := _bind_for(trousers.skin,skeleton,"hips")
	var hips := frame*skeleton.get_bone_global_pose(_bone_for(trousers.skin,skeleton,bind))*trousers.skin.get_bind_pose(bind)
	var triangles := PackedVector3Array()
	for point: Vector3 in data.waist_triangles: triangles.append(hips*point)
	var closest := INF
	for record: Dictionary in data.hem:
		var point := Vector3.ZERO
		for influence: int in record.bones.size():
			var index: int = record.bones[influence]
			point+=(frame*skeleton.get_bone_global_pose(_bone_for(data.jacket.skin,skeleton,index))*data.jacket.skin.get_bind_pose(index)*Vector3(record.point))*float(record.weights[influence])
		for index: int in range(0,triangles.size(),3):
			closest=minf(closest,_triangle_distance(point,triangles[index],triangles[index+1],triangles[index+2]))
	return closest


static func _triangle_distance(point: Vector3,a: Vector3,b: Vector3,c: Vector3) -> float:
	var normal := (b-a).cross(c-a).normalized()
	var projected := point-normal*(point-a).dot(normal)
	if (b-a).cross(projected-a).dot(normal)>=-0.0000001 \
		and (c-b).cross(projected-b).dot(normal)>=-0.0000001 \
		and (a-c).cross(projected-c).dot(normal)>=-0.0000001:
		return absf((point-a).dot(normal))
	return minf(point.distance_to(Geometry3D.get_closest_point_to_segment(point,a,b)),
		minf(point.distance_to(Geometry3D.get_closest_point_to_segment(point,b,c)),point.distance_to(Geometry3D.get_closest_point_to_segment(point,c,a))))


static func _full_grabs(tree: SceneTree,check: Callable) -> void:
	for id: String in ["melon_grab","method_grab"]:
		var fixture: Dictionary = await Authentic._fixture(tree)
		fixture.rider.position.y=-0.17
		fixture.rider.rotation.x=-0.30
		var definition: Dictionary = Classic.Catalog.definition(id)
		var state := Authentic._neutral()
		state.merge({"airborne":true,"grab":true,"grab_side":definition.grab_side,"grab_target":definition.grab_target,"grab_definition":definition},true)
		var data := _prepare(fixture.rig)
		var largest := 0.0
		var joint := 0.0
		var neck := 0.0
		for frame: int in 90:
			fixture.rig.animate(1.0/60.0,state)
			var sample := _sample(fixture.body,data)
			largest=maxf(largest,sample.seam)
			joint=maxf(joint,sample.joint_gap)
			neck=maxf(neck,sample.neck_gap)
		check.call(fixture.rig._grab_blend>.999 and largest<0.12 and joint<0.12 and neck<0.05,
			"body attachment: actual skinned cloth and anatomical neck stay connected through fully settled "+id)
		print("BODY_ATTACHMENT_FULL_GRAB ",id," seam=",largest," joint=",joint," neck=",neck," influence=",fixture.rig._grab_blend)
		await Authentic._dispose(tree,fixture.root)
