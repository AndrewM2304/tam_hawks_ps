extends RefCounted
## Core clothed-body maintenance for the existing tow, not traffic expansion.
const Authentic = preload("res://.local/skitch_attachment_legacy_authentic.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")
const Fidelity = preload("res://tests/authentic_fidelity_integration_tests.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const Main = preload("res://.local/skitch_attachment_legacy_main.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	for yaw: float in [0.0,0.8]: await _geometry(tree,check,yaw)
	await _native(tree,check)

static func _geometry(tree: SceneTree,check: Callable,yaw: float) -> void:
	var fixture:=await Authentic._fixture(tree,yaw)
	var data:=Attachment._prepare(fixture.rig)
	var state:=Authentic._neutral()
	Authentic._settle(fixture.rig,state)
	var grips: Array[Vector3]=[fixture.body.to_global(Vector3(-0.40,0.93,-0.505)),fixture.body.to_global(Vector3(0.40,0.93,-0.505))]
	state.merge({"skitching":true,"skitch_grips":grips,"skitch_normal":fixture.body.global_basis.z},true)
	var entry:=_phase(fixture,data,state,90)
	var palms:=0.0
	var visible:=0.0
	for index in 2:
		var hand: Node3D=fixture.rig._arms[index].hand
		palms=maxf(palms,hand.to_global(Authentic.PALM).distance_to(grips[index]))
		visible=maxf(visible,Authentic._nearest_vertex(hand.get_node("HandAndFingers"),grips[index]))
	check.call(entry.maximum_seam<0.12 and entry.maximum_joint<0.06,
		"skitch attachment: actual Skin-bound torso and trousers stay connected through tow entry/hold yaw=%.2f"%yaw)
	check.call(entry.finite and entry.maximum_step<0.22 and entry.stretch<=1.12,
		"skitch attachment: existing head/feet/hand continuity and fixed-limb reach remain bounded yaw=%.2f"%yaw)
	check.call(palms<0.025 and visible<0.025 and Authentic._feet_error(fixture)<0.005,
		"skitch attachment: original actual palms, anatomical hand vertices and planted shoes retain their contacts yaw=%.2f"%yaw)
	state.skitching=false
	state.skitch_grips=[]
	var release:=_phase(fixture,data,state,90)
	check.call(release.maximum_seam<0.12 and release.maximum_joint<0.06 and release.maximum_step<0.22
		and release.finite and release.stretch<=1.12 and release.settled.seam<0.08,
		"skitch attachment: ordinary release preserves real cloth attachment while the original tow influence fades yaw=%.2f"%yaw)
	state.skitching=true
	state.skitch_grips=grips
	Authentic._settle(fixture.rig,state)
	var definition:=Catalog.definition("melon_grab")
	state.merge({"skitching":false,"skitch_grips":[],"airborne":true,"grab":true,
		"grab_side":definition.grab_side,"grab_target":definition.grab_target,"grab_definition":definition},true)
	# Exact declared pose fixture from AuthenticPose; this setup transform is
	# not counted as a native controller transition or a continuity observation.
	fixture.rider.position.y=-0.17
	fixture.rider.rotation.x=-0.30
	var interrupted:=_phase(fixture,data,state,14)
	var grab_palm: Vector3=fixture.rig._arms[0].hand.to_global(Authentic.PALM)
	check.call(interrupted.maximum_seam<0.12 and interrupted.maximum_joint<0.06
		and grab_palm.distance_to(fixture.board.to_global(definition.grab_target))<0.025,
		"skitch attachment: an existing released-tow to Melon pose keeps cloth connected and fresh board grip authoritative yaw=%.2f"%yaw)
	fixture.rig.reset()
	var reset:=Attachment._sample(fixture.body,data)
	check.call(fixture.rig._skitch_blend==0.0 and fixture.rig._skitch_local_grips.is_empty()
		and reset.seam<0.08 and reset.joint_gap<0.06,
		"skitch attachment: explicit reset restores native neutral garment attachment and clears tow influence yaw=%.2f"%yaw)
	print("SKITCH_ATTACHMENT_GEOMETRY ",{"yaw":yaw,"entry":entry,"release":release,"interrupted":interrupted,"palms":palms,"visible":visible})
	await Authentic._dispose(tree,fixture.root)

static func _phase(fixture: Dictionary,data: Dictionary,state: Dictionary,count: int) -> Dictionary:
	var result: Dictionary={"maximum_seam":0.0,"maximum_joint":0.0,"maximum_step":0.0,"stretch":0.0,"finite":true,"settled":{}}
	var previous:=Authentic._markers(fixture.rig)
	for frame in count:
		fixture.rig.animate(1.0/60.0,state)
		var sample:=Attachment._sample(fixture.body,data)
		result.maximum_seam=maxf(result.maximum_seam,sample.seam)
		result.maximum_joint=maxf(result.maximum_joint,sample.joint_gap)
		result.finite=result.finite and sample.finite and Authentic._finite(fixture.rig)
		result.stretch=maxf(result.stretch,Authentic._max_stretch(fixture.rig))
		var current:=Authentic._markers(fixture.rig)
		result.maximum_step=maxf(result.maximum_step,Authentic._marker_delta(previous,current))
		previous=current
		result.settled=sample
	return result

static func _native(tree: SceneTree,check: Callable) -> void:
	var game:=Main.new()
	game.persistence_enabled=false
	tree.root.add_child(game)
	var report: Dictionary={"samples":0,"tow_samples":0,"maximum_seam":0.0,"maximum_joint":0.0,"maximum_neck":0.0,"finite":true}
	var data:=Attachment._prepare(game.skater._visual_rig)
	var observer:=func(_phase_name: String,current: Node,_step: int) -> void:
		var sample:=Attachment._sample(current.skater,data)
		report.samples+=1
		if current.skater.skitch_caught:report.tow_samples+=1
		report.maximum_seam=maxf(report.maximum_seam,sample.seam)
		report.maximum_joint=maxf(report.maximum_joint,sample.joint_gap)
		report.maximum_neck=maxf(report.maximum_neck,sample.neck_gap)
		report.finite=report.finite and sample.finite
	# Preserve all seven existing actual native input/contact/score assertions.
	await Fidelity.run(tree,game,check,observer,["skitch"])
	check.call(report.samples>=200 and report.tow_samples>=40 and report.finite,
		"skitch attachment: ordinary default Main observes real caught tow, pause, Ollie, fresh Grab and native landing")
	check.call(report.maximum_seam<0.12 and report.maximum_joint<0.06 and report.maximum_neck<0.05,
		"skitch attachment: native moving-cart input keeps actual clothed waist, torso and neck connected across every observed step")
	await _bail(tree,game,check)
	check.call(not game.persistence_enabled and not game.music._can_control and not game.music._persist,
		"skitch attachment: actual Main remains isolated from profiles and personal Music")
	print("SKITCH_ATTACHMENT_NATIVE ",report)
	Fidelity._release()
	game.queue_free()
	await tree.process_frame

static func _bail(tree: SceneTree,game: Node,check: Callable) -> void:
	await Fidelity._reset(tree,game,Vector3(-82.3,2.8,70.5),-PI/2.0)
	var requested:=false
	var caught:=false
	Input.action_press("push")
	for frame in 150:
		var gap: float=game.skater.global_position.distance_to(game.feature_hub.vehicle.get_skitch_anchor())
		if not requested and gap<1.0 and game.skater.speed>1.0:
			Input.action_press("grind")
			Input.action_press("interact")
			requested=true
		await Fidelity._frames(tree,1)
		Input.action_release("interact")
		if game.skater.skitch_caught:caught=true;break
	Input.action_release("push")
	for frame in 40:
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if absf(game.skater.skitch_balance)>0.05:
			Input.action_press("steer_left" if game.skater.skitch_balance>0.0 else "steer_right",minf(0.6,absf(game.skater.skitch_balance)*4.0))
		await Fidelity._frames(tree,1)
	check.call(caught and game.skater.skitch_caught and game.skater.last_trick_id=="skitch" and game.score.combo_trick_count==1,
		"skitch attachment: bail control first earns a real existing moving-cart grip and catalog entry")
	Fidelity._release()
	game.skater.begin_bail("skitch_attachment_interruption")
	var data:=Attachment._prepare(game.skater._visual_rig)
	var fall:=await Attachment._observe(tree,game.skater,data,180,"skitch_bail_getup")
	check.call(not game.skater.bailing and not game.skater.skitching and game.skater.is_on_floor()
		and fall.phases.has("fall") and fall.phases.has("get_up") and fall.maximum_surface_gap<0.05
		and fall.maximum_joint_gap<0.10 and fall.maximum_neck_gap<0.05,
		"skitch attachment: actual tow interruption preserves cloth and neck attachment through native fall/get-up")
	game.skater.begin_bail("skitch_attachment_restart")
	await Fidelity._frames(tree,3)
	game.skater.reset_skater()
	var reset:=Attachment._sample(game.skater,data)
	check.call(not game.skater.bailing and not game.skater.skitching
		and game.skater._visual_rig._skitch_blend==0.0 and reset.seam<0.08 and reset.joint_gap<0.06,
		"skitch attachment: real restart during recovery immediately restores complete neutral attachment")
