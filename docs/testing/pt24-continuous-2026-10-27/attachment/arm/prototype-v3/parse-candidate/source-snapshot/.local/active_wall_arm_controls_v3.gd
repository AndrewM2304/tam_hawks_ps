extends SceneTree
## Ignored bounded native contracts. Negative state assignments occur only after
## the ordinary Push/Brake/Ollie/Flip fixture has been earned and physics frozen.
const Current = preload("res://game/player/skater.gd")
const Candidate = preload("res://.local/active_wall_arm_candidate_v3.gd")
const Gate = preload("res://game/features/service_gate.gd")
const Setup = preload("res://game/core/input_setup.gd")
var actor: CharacterBody3D
var gate: Node3D
var helper: RefCounted
var baseline: Dictionary
var checks: Array[Dictionary]=[]
var passed:=0
var failed:=0
func _initialize() -> void:_run.call_deferred()
func _check(ok: bool,label: String) -> void:
	checks.append({"ok":ok,"label":label})
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
func _run() -> void:
	Setup.register_actions();_release()
	var floor:=StaticBody3D.new();root.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-0.1;floor.add_child(collision)
	gate=Gate.new();root.add_child(gate)
	gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	actor=Current.new();actor.spawn_position=Vector3(0,0.04,-3);root.add_child(actor);actor.rotation.y=PI
	for tick in 10:await _frame()
	var reached:=false
	Input.action_press("push",0.55)
	for tick in 180:
		await _frame()
		for slide in actor.get_slide_collision_count():
			if actor.get_slide_collision(slide).get_collider()==gate._panel:reached=true
		if reached:break
	_release();Input.action_press("brake")
	for tick in 20:await _frame()
	_release()
	for tick in 2:await _frame()
	Input.action_press("ollie")
	for tick in 20:await _frame()
	_release()
	for tick in 2:await _frame()
	Input.action_press("flip")
	for tick in 6:await _frame()
	_release();actor.set_physics_process(false)
	_check(reached and actor.airborne and actor._flip_remaining>0 and actor._obstacle_ollie_continuation and actor._obstacle_visual_offset.length()>0.10,"controls use earned real shutter contact and active Flip6 pose")
	helper=Candidate.new();helper.prepare(actor);baseline=_pose()
	var query_before:=_query()
	helper.apply(1.0/60.0)
	_check(helper.accepted>0 and _pose()!=baseline and helper.maximum_calls<=12,"live finite arm envelope earns a bounded correction")
	_check(_query()==query_before,"positive correction restores every reused query field")
	for spec: Array in [[actor,"manual_active"],[actor,"bailing"],[actor,"lip_active"],[actor,"powersliding"],[actor._grind,"active"],[actor._wall,"active"],[actor._transition,"active"],[actor._feature_transition,"active"],[actor._setup,"active"],[actor._skitch,"active"]]:
		var object: Object=spec[0];var key: String=spec[1];var prior: Variant=object.get(key)
		_restore();object.set(key,true);helper.continuing=true;var accepted: int=helper.accepted;helper.apply(1.0/60.0)
		_check(helper.calls==0 and helper.accepted==accepted and _pose()==baseline and not helper.continuing,"active contact guard "+str(spec)+" has no arm or query effects")
		object.set(key,prior)
	for key: String in ["_grab_remaining","_special_remaining"]:
		var prior: float=actor.get(key);_restore();actor.set(key,0.1);helper.continuing=true
		var accepted: int=helper.accepted;helper.apply(1.0/60.0)
		_check(helper.calls==0 and helper.accepted==accepted and _pose()==baseline and not helper.continuing,"active trick guard "+key+" has no arm or query effects")
		actor.set(key,prior)
	for key: String in ["_grab_blend","_skitch_blend","_pogo_blend","_handplant_blend","_manual_blend","_walk_blend","_cross_blend","_casper_blend","_manual_weight_z","_front_foot_lift","_rear_foot_lift","_grind_blend","_lip_blend","_wall_blend","_transition_blend","_slide_blend","_bail_blend"]:
		var rig: RefCounted=actor._visual_rig;var prior: float=rig.get(key);_restore();rig.set(key,0.1);helper.continuing=true
		var accepted: int=helper.accepted;helper.apply(1.0/60.0)
		_check(helper.calls==0 and helper.accepted==accepted and _pose()==baseline and not helper.continuing,"residual contact guard "+key+" has no arm or query effects")
		rig.set(key,prior)
	var axis: Vector3=actor._obstacle_visual_offset
	for value: Vector3 in [Vector3.ZERO,-axis,Vector3(NAN,0,0),axis.normalized()*0.181]:
		_restore();actor._obstacle_visual_offset=value;helper.continuing=false;var accepted: int=helper.accepted
		helper.apply(1.0/60.0)
		_check(helper.accepted==accepted and _pose()==baseline and _query()==query_before,"absent, opposite, nonfinite or over-cap axis refuses stale plane authority: "+str(value))
	actor._obstacle_visual_offset=axis
	_restore();var armed: bool=actor._obstacle_ollie_continuation;actor._obstacle_ollie_continuation=false;helper.continuing=false;helper.apply(1.0/60.0)
	_check(helper.calls==0 and _pose()==baseline,"unarmed ordinary pose adds zero native queries")
	actor._obstacle_ollie_continuation=armed
	var panel_frame: Transform3D=gate._panel.transform
	gate._panel.position+=Vector3(5,0,0);await _frame();_restore();helper.continuing=true;var accepted: int=helper.accepted;helper.apply(1.0/60.0)
	_check(helper.accepted==accepted and _pose()==baseline and not helper.continuing and _query()==query_before,"moved-away actual finite panel clears continuation without remembered plane")
	gate._panel.transform=panel_frame;await _frame()
	var panel_size: Vector3=gate._shape.size
	gate._shape.size=Vector3(panel_size.x,0.05,panel_size.z);await _frame();_restore();helper.continuing=true;accepted=helper.accepted;helper.apply(1.0/60.0)
	_check(helper.accepted==accepted and _pose()==baseline and not helper.continuing and _query()==query_before,"short finite panel does not extend an infinite arm correction above its edge")
	gate._shape.size=panel_size;await _frame()
	var blocker:=StaticBody3D.new();var solid:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(3,3,3);solid.shape=box;blocker.add_child(solid);root.add_child(blocker);blocker.global_position=actor._rider_visual.global_position;await _frame()
	_restore();helper.continuing=false;accepted=helper.accepted;helper.apply(1.0/60.0)
	_check(helper.accepted==accepted and _pose()==baseline and _query()==query_before and helper.calls<=12,"corner/enclosing solid refuses unsafe shoulder or full-envelope fit within unchanged budget")
	blocker.queue_free();await process_frame
	var report: Dictionary={"passed":passed,"failed":failed,"checks":checks,"maximum_calls":helper.maximum_calls,"maximum_shift":helper.maximum_shift,"method":"Native current controller fixture first; afterwards frozen-actor negative contracts exercise every active/residual grip guard and current finite collision authority. No geometric or continuity tolerance changes."}
	var file:=FileAccess.open("res://.local/active_wall_arm_controls_v3.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("RESULT: ",passed," passed, ",failed," failed")
	actor.queue_free();gate.queue_free();floor.queue_free();await process_frame;quit(1 if failed else 0)
func _pose() -> Dictionary:
	var rig: RefCounted=actor._visual_rig;var skeleton: Skeleton3D=rig._garments.skeleton
	var bones: Array[Transform3D]=[]
	for bone in skeleton.get_bone_count():bones.append(skeleton.get_bone_pose(bone))
	return {"bones":bones,"left_hand":rig._arms[0].hand.transform,"right_hand":rig._arms[1].hand.transform}
func _restore() -> void:
	var rig: RefCounted=actor._visual_rig;var skeleton: Skeleton3D=rig._garments.skeleton
	for bone in skeleton.get_bone_count():
		var frame: Transform3D=baseline.bones[bone];skeleton.set_bone_pose(bone,frame)
	rig._arms[0].hand.transform=baseline.left_hand;rig._arms[1].hand.transform=baseline.right_hand
func _query() -> Dictionary:
	var q: PhysicsShapeQueryParameters3D=actor._grind_board_query;var ray: PhysicsRayQueryParameters3D=actor._recovery_floor_query
	return {"shape":q.shape,"margin":q.margin,"transform":q.transform,"motion":q.motion,"size":actor._grind_board_box.size,"mask":q.collision_mask,"exclude":q.exclude.duplicate(),"bodies":q.collide_with_bodies,"areas":q.collide_with_areas,"from":ray.from,"to":ray.to,"raymask":ray.collision_mask,"rayexclude":ray.exclude.duplicate(),"raybodies":ray.collide_with_bodies,"rayareas":ray.collide_with_areas,"rayback":ray.hit_back_faces,"rayinside":ray.hit_from_inside}
func _frame() -> void:await physics_frame;await process_frame
func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
