extends RefCounted
## Paired actual native rigs: full output parity and counted fallback objects.
const Visual = preload("res://game/player/skater_visual.gd")
const Motion = preload("res://game/player/trick_animation.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")

class CachedPose extends Visual:
	var constructions := 0
	var _previous_pose: Dictionary = {}
	func _native_grab_pose(grab_id: String) -> Dictionary:
		var pose := super._native_grab_pose(grab_id)
		if not is_same(pose,_previous_pose):constructions+=1
		_previous_pose=pose
		return pose

class FreshPose extends Visual:
	var constructions := 0
	func _native_grab_pose(grab_id: String) -> Dictionary:
		constructions+=1
		return Motion.grab_pose(grab_id)


static func run(tree: SceneTree,check: Callable) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var cached := _fixture(root,CachedPose.new())
	var fresh := _fixture(root,FreshPose.new())
	check.call(_snapshot(cached)==_snapshot(fresh) and cached.data.hem.size()>=20
		and cached.rig._garments.skeleton.get_bone_count()>=10,
		"grab fallback cache: actual built cloth, bones, contacts and anatomical blend shapes equal the fresh controller")
	var state := {"airborne":false,"grab":false,"flip":false,"manual":false,
		"grind":false,"speed":4.0,"push":false,"brake":false}
	var cached_before: int=cached.rig.constructions
	var fresh_before: int=fresh.rig.constructions
	var pairs := 0
	var equal := true
	for frame: int in 60:
		equal=_pair(cached,fresh,state) and equal
		pairs+=1
	check.call(equal and cached.rig.constructions==cached_before and fresh.rig.constructions==fresh_before+60,
		"grab fallback cache: sixty ordinary skating poses preserve every output with zero new fallback objects instead of sixty")
	var grabs: Array=Catalog.family_ids("grab")
	grabs.append_array(["unknown_grab_fixture",""])
	equal=true
	for id: String in grabs:
		state.grab_id=id
		state.grab=true
		state.airborne=true
		for frame: int in 12:
			equal=_pair(cached,fresh,state) and equal
			pairs+=1
		equal=equal and cached.rig._grab_pose==Motion.grab_pose(id)
	check.call(equal and grabs.size()>=10,
		"grab fallback cache: all authored grabs plus unknown and empty raw IDs retain exact native fallback and deformed-rig outputs")
	cached_before=cached.rig.constructions
	state.grab_id="another_unknown_grab_fixture"
	var raw_ids_equal := _pair(cached,fresh,state)
	state.grab_id=""
	raw_ids_equal=_pair(cached,fresh,state) and raw_ids_equal
	pairs+=2
	check.call(raw_ids_equal and cached.rig.constructions==cached_before+2 and cached.rig._grab_pose_id=="",
		"grab fallback cache: distinct raw unknown and empty IDs refresh immediately even when their fallback values are equal")
	# Exact same raw ID, changing actual state/catalog overrides each call.
	state.grab_id="nose_grab"
	state["grab_side"]=-1.0
	state["grab_target"]=Vector3(-0.025,0.026,-0.385)
	state["grab_definition"]={"grab_tuck":0.29}
	_pair(cached,fresh,state)
	pairs+=1
	cached_before=cached.rig.constructions
	var before: Dictionary=_snapshot(cached)
	equal=true
	for frame: int in 20:
		state.grab_side=1.0 if frame%2 else -1.0
		state.grab_target=Vector3(0.025*state.grab_side,0.026,0.385 if frame%2 else -0.385)
		state.grab_definition.grab_tuck=0.29+float(frame)*0.004
		equal=_pair(cached,fresh,state) and equal
		pairs+=1
	check.call(equal and _snapshot(cached)!=before and cached.rig.constructions==cached_before,
		"grab fallback cache: changing hand, deck target and catalog tuck overrides stay live without rereading the unchanged fallback ID")
	state.erase("grab_side")
	state.erase("grab_target")
	state.erase("grab_definition")
	state.grab=false
	state.airborne=false
	state["rest_deck_yaw"]=PI
	state["deck_yaw"]=PI
	cached.board.rotation.y=PI
	fresh.board.rotation.y=PI
	equal=true
	for frame: int in 45:
		equal=_pair(cached,fresh,state) and equal
		pairs+=1
	check.call(equal and cached.rig._grab_blend<0.001,
		"grab fallback cache: release fades preserve full native outputs on a reversed deck")
	cached.rig.reset()
	fresh.rig.reset()
	check.call(_snapshot(cached)==_snapshot(fresh)
		and cached.rig._grab_pose==Motion.grab_pose("melon_grab"),
		"grab fallback cache: explicit reset restores the original default fallback and complete rig immediately")
	print("GRAB_FALLBACK_CACHE ",{"paired_updates":pairs,"cached_objects":cached.rig.constructions,
		"fresh_objects":fresh.rig.constructions,"ordinary_updates":60,"ordinary_new_objects":0,
		"ordinary_fresh_objects":60,"raw_ids":grabs.size(),"retained_slots":1})
	# Prove the full output comparison notices a stale/wrong cached fallback.
	state.erase("rest_deck_yaw")
	state.erase("deck_yaw")
	state.grab_id="nose_grab"
	state.grab=true
	state.airborne=true
	_pair(cached,fresh,state)
	cached.rig._grab_pose.tuck+=0.2
	for frame: int in 20:_pair(cached,fresh,state)
	check.call(_snapshot(cached)!=_snapshot(fresh),
		"grab fallback cache: a deliberately corrupted cached tuck is rejected by actual cloth/bone/contact output parity")
	root.queue_free()
	await tree.process_frame


static func _fixture(root: Node3D,rig: RefCounted) -> Dictionary:
	var body := Node3D.new()
	root.add_child(body)
	var visual := Node3D.new()
	body.add_child(visual)
	var board := Node3D.new()
	board.position.y=0.12
	visual.add_child(board)
	var rider := Node3D.new()
	rider.rotation.y=-PI/2.0+0.28
	visual.add_child(rider)
	rig.build(board,rider,StandardMaterial3D.new())
	return {"body":body,"visual":visual,"board":board,"rig":rig,"data":Attachment._prepare(rig)}


static func _pair(cached: Dictionary,fresh: Dictionary,state: Dictionary) -> bool:
	cached.rig.animate(1.0/60.0,state)
	fresh.rig.animate(1.0/60.0,state)
	return _snapshot(cached)==_snapshot(fresh)


static func _snapshot(fixture: Dictionary) -> Dictionary:
	var nodes: Array[Transform3D]=[]
	var blend_shapes: Array[float]=[]
	_collect(fixture.visual,nodes,blend_shapes)
	var bones: Array[Transform3D]=[]
	var skeleton: Skeleton3D=fixture.rig._garments.skeleton
	for bone: int in skeleton.get_bone_count():bones.append(skeleton.get_bone_pose(bone))
	return {"nodes":nodes,"bones":bones,"blend_shapes":blend_shapes,
		"cloth":Attachment._sample(fixture.body,fixture.data)}


static func _collect(node: Node,nodes: Array[Transform3D],blend_shapes: Array[float]) -> void:
	if node is Node3D:nodes.append(node.global_transform)
	if node is MeshInstance3D and node.mesh is ArrayMesh:
		for shape: int in node.mesh.get_blend_shape_count():blend_shapes.append(node.get_blend_shape_value(shape))
	for child: Node in node.get_children():_collect(child,nodes,blend_shapes)
