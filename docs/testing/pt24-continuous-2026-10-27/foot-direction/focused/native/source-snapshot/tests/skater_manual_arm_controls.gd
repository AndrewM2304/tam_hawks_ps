extends RefCounted
## Declared native safety controls begin at a genuine earned Nose Manual pose.
const Skater=preload("res://game/player/skater.gd")
const Candidate=preload("res://game/player/skater_obstacle_arm_fit.gd")
const Arm=preload("res://tests/skater_obstacle_arm_tests.gd")
const Gate=preload("res://game/features/service_gate.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
const Catalog=preload("res://game/tricks/trick_catalog.gd")
var _check_callback: Callable
var actor: CharacterBody3D
var helper: RefCounted
var baseline: Dictionary
var fields: Dictionary
var rig_fields: Dictionary
var visual: Transform3D
var unfitted_visual: Transform3D
var queries: Dictionary

func run(tree: SceneTree,check: Callable) -> void:
	_check_callback=check
	Setup.register_actions();Wall._release()
	var viewport:=SubViewport.new();viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
	var scene:=Node3D.new();viewport.add_child(scene)
	var floor:=StaticBody3D.new();scene.add_child(floor)
	var box:=BoxShape3D.new();box.size=Vector3(20,0.2,20)
	var floor_collision:=CollisionShape3D.new();floor_collision.shape=box;floor_collision.position.y=-0.1;floor.add_child(floor_collision)
	var gate:=Gate.new();scene.add_child(gate)
	gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	actor=Skater.new();actor._obstacle_arm_fit=Arm.NoArmFit.new()
	actor.spawn_position=Vector3(0,0.04,-3.02);scene.add_child(actor);actor.rotation.y=PI
	await Wall._frames(tree,4)
	var requested:=false
	Input.action_press("push",0.55)
	for tick: int in 79:
		if not requested and absf(actor.speed)>=2.5 and actor.global_position.z< -1.0:
			requested=true;Input.action_press("manual")
		await Wall._frames(tree,1)
	Wall._release();actor.set_physics_process(false)
	_check(requested and actor.manual_active and actor.manual_trick_id=="nose_manual" and actor._obstacle_manual_continuation
		and actor.is_on_floor() and not Wall._wall_contact(actor,gate._panel),
		"Manual arm controls: genuine moving Nose Manual reaches the earned finite root-fit active78 baseline")
	helper=Candidate.new();helper.prepare(actor)
	actor._obstacle_arm_fit=helper
	baseline=Arm._arm_pose(actor)
	visual=actor._visual.transform
	unfitted_visual=visual
	unfitted_visual.origin-=actor.global_basis.inverse()*actor._obstacle_visual_offset
	fields={}
	for key: String in ["manual_active","manual_trick_id","airborne","_native_floor_valid","_force_air_tick","_obstacle_manual_continuation","_obstacle_visual_offset","_obstacle_ollie_continuation","_grab_remaining","_special_remaining"]:
		fields[key]=actor.get(key)
	rig_fields={}
	for key: String in ["_manual_blend","_manual_weight_z","_grab_blend","_skitch_blend","_pogo_blend","_handplant_blend","_walk_blend","_cross_blend","_casper_blend","_front_foot_lift","_rear_foot_lift","_grind_blend","_lip_blend","_wall_blend","_transition_blend","_slide_blend","_bail_blend"]:
		rig_fields[key]=actor._visual_rig.get(key)
	actor._grind_board_query.motion=Vector3(0.01,0.02,0.03)
	queries=Arm._query_state(actor)
	var ids: Array[int]=[actor._grind_board_query.get_instance_id(),actor._grind_board_box.get_instance_id(),actor._recovery_floor_query.get_instance_id()]
	helper.apply(1.0/60.0)
	var data:=Arm._skin_data(actor,gate)
	var actual:=Arm._vertices(actor,data)
	_check(helper.accepted>0 and Arm._arm_pose(actor)!=baseline and actual.panel_hits==0 and actual.contained,
		"Manual arm controls: candidate actually clears original Skin/hand vertices at the earned native baseline")
	_check(Arm._query_state(actor)==queries and ids==[actor._grind_board_query.get_instance_id(),actor._grind_board_box.get_instance_id(),actor._recovery_floor_query.get_instance_id()]
		and helper.maximum_calls<=12 and helper.maximum_shift<=0.20,
		"Manual arm controls: positive fit preserves all existing resources/query fields and twelve-call/twenty-centimetre limits")
	for spec: Array in [[actor,"manual_active"],[actor,"bailing"],[actor,"lip_active"],[actor,"powersliding"],[actor._grind,"active"],[actor._wall,"active"],[actor._transition,"active"],[actor._feature_transition,"active"],[actor._setup,"active"],[actor._skitch,"active"]]:
		if spec[0]==actor and spec[1]=="manual_active":continue
		_restore();var object: Object=spec[0];var key: String=spec[1];var prior: Variant=object.get(key)
		object.set(key,true);helper.continuing=true
		_guard("active contact "+key)
		object.set(key,prior)
	for key: String in ["_grab_remaining","_special_remaining"]:
		_restore();actor.set(key,0.1);helper.continuing=true;_guard("active trick "+key)
	for key: String in ["_grab_blend","_skitch_blend","_pogo_blend","_handplant_blend","_walk_blend","_cross_blend","_casper_blend","_front_foot_lift","_rear_foot_lift","_grind_blend","_lip_blend","_wall_blend","_transition_blend","_slide_blend","_bail_blend"]:
		_restore();actor._visual_rig.set(key,0.1);helper.continuing=true;_guard("residual grip/style "+key)
	for id: String in Catalog.family_ids("manual"):
		if id in ["manual","nose_manual"]:continue
		_restore();actor.manual_trick_id=id;helper.continuing=true
		_guard("earned flag cannot bless other Manual style "+id)
	_restore();actor._obstacle_manual_continuation=false;helper.continuing=true
	_guard("unearned active Manual with stale ID")
	_restore();actor.manual_active=false;actor._obstacle_manual_continuation=false;helper.continuing=true
	_guard("unearned residual Manual with stale ID")
	for key: String in ["airborne","_force_air_tick","_native_floor_valid"]:
		_restore();actor.set(key,key!="_native_floor_valid");helper.continuing=true
		_guard("invalid grounded authority "+key)
	for value: Vector3 in [Vector3.ZERO,-Vector3(fields._obstacle_visual_offset),Vector3(NAN,0,0),Vector3(fields._obstacle_visual_offset).normalized()*0.181]:
		_restore();actor._obstacle_visual_offset=value;helper.continuing=true
		var pose:=Arm._arm_pose(actor);helper.apply(1.0/60.0)
		_check(helper.accepted==0 and Arm._arm_pose(actor)==pose and Arm._query_state(actor)==queries and helper.maximum_calls<=12,
			"Manual arm controls: absent/opposite/nonfinite/over-cap axis cannot supply remembered plane authority "+str(value))
	_restore();actor.manual_active=false;actor._visual_rig._manual_blend=0.0;actor._visual_rig._manual_weight_z=0.0;actor._obstacle_manual_continuation=false
	_guard("fully faded unarmed pose cannot start a new fit")
	var floor_pose: Transform3D=floor.transform
	for kind: String in ["disabled","moved","lowered","graded"]:
		_restore();actor._visual.transform=unfitted_visual
		if kind=="disabled":floor_collision.disabled=true
		elif kind=="moved":floor.position.x+=30.0
		elif kind=="lowered":floor.position.y-=0.10
		else:floor.rotation.x=0.12
		await Wall._frames(tree,2)
		actor._place_obstacle_wheels(1.0/60.0)
		var after_final:=Arm._arm_pose(actor)
		helper.continuing=true;helper.apply(1.0/60.0)
		_check(not actor._obstacle_manual_continuation and helper.calls==0 and helper.accepted==0
			and Arm._arm_pose(actor)==after_final and Arm._query_state(actor)==queries,
			"Manual arm controls: normal final board/tyre proof rejects actual "+kind+" floor before arm eligibility")
		floor_collision.disabled=false;floor.transform=floor_pose;await Wall._frames(tree,2)
	_restore();actor._visual.transform=unfitted_visual
	var panel_pose: Transform3D=gate._panel.transform
	gate._panel.position.x+=8.0;await Wall._frames(tree,2)
	actor._place_obstacle_wheels(1.0/60.0)
	var wall_removed_pose:=Arm._arm_pose(actor)
	helper.continuing=true;helper.apply(1.0/60.0)
	_check(helper.accepted==0 and not helper.continuing and Arm._arm_pose(actor)==wall_removed_pose and Arm._query_state(actor)==queries
		and helper.maximum_calls<=12,
		"Manual arm controls: removed finite panel permits no arm correction despite the normal root's bounded decay")
	gate._panel.transform=panel_pose;await Wall._frames(tree,2)
	_restore();actor._obstacle_arm_fit=helper;helper.continuing=true;actor.begin_bail("manual_arm_control")
	_check(actor.bailing and not helper.continuing and helper.calls==0 and not actor._obstacle_manual_continuation,
		"Manual arm controls: actual bail resets arm continuation and earned Manual root authority")
	helper.continuing=true;actor.reset_skater()
	_check(not actor.bailing and not helper.continuing and helper.calls==0 and helper.accepted==0 and not actor._obstacle_manual_continuation,
		"Manual arm controls: actual restart clears retained arm and Manual root authority")
	print("MANUAL_ARM_CONTROLS ",{"query_resources":ids,"catalog_style_ids":Catalog.family_ids("manual"),"note":"Only the initial earned Nose Manual pose is positive. Every later field/geometry change is a declared negative contract; no movement or scoring acceptance is inferred from those manipulations."})
	viewport.queue_free();await tree.process_frame;Wall._release()

func _restore() -> void:
	for key: String in fields:actor.set(key,fields[key])
	for key: String in rig_fields:actor._visual_rig.set(key,rig_fields[key])
	actor._visual.transform=visual
	Arm._restore_pose(actor,baseline)
	helper.reset()

func _guard(label: String) -> void:
	var pose:=Arm._arm_pose(actor)
	helper.apply(1.0/60.0)
	_check(helper.calls==0 and helper.accepted==0 and not helper.continuing and Arm._arm_pose(actor)==pose and Arm._query_state(actor)==queries,
		"Manual arm controls: "+label+" refuses without arm or query effects")

func _check(ok: bool,label: String) -> void:
	_check_callback.call(ok,label)
