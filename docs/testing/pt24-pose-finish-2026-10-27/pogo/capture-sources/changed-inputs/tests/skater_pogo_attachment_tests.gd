extends RefCounted
## Pogo's palm reach must move the actual clothed pelvis and torso together.
## Geometry controls cover both deck stances; a real controller trial uses
## ordinary mapped inputs, then releases or interrupts its manual with a bail.
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")
const Classic = preload("res://tests/classic_tricks_integration_tests.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const SOLE := Vector3(0,-0.0605,0)
const PALM := Vector3(0,-0.075,-0.015)


static func run(tree: SceneTree,check: Callable) -> void:
	Classic.Setup.register_actions()
	for rest: float in [0.0,PI]:
		await _geometry(tree,check,rest)
	for interrupt: bool in [false,true]:
		await _input(tree,check,interrupt)
	Classic._release()


static func _geometry(tree: SceneTree,check: Callable,rest: float) -> void:
	var fixture := await Authentic._fixture(tree,0.6,rest)
	var data := Attachment._prepare(fixture.rig)
	var state := Authentic._neutral()
	state.merge({"manual":true,"manual_definition":Catalog.definition("manual"),
		"deck_yaw":rest,"rest_deck_yaw":rest},true)
	# Enter through the ordinary loaded Manual, as the controller requires.
	for frame: int in 40:Authentic._manual_frame(fixture,state)
	state.manual_definition=Catalog.definition("pogo")
	var maximum_seam:=0.0
	var maximum_joint:=0.0
	var stretch:=0.0
	var finite:=true
	var previous:=Authentic._markers(fixture.rig)
	var step:=0.0
	var sole_error:=0.0
	var palm_error:=0.0
	for phase: int in 2:
		if phase==1:state.manual_definition=Catalog.definition("manual")
		for frame: int in 90:
			Authentic._manual_frame(fixture,state)
			var sample := Attachment._sample(fixture.body,data)
			maximum_seam=maxf(maximum_seam,sample.seam)
			maximum_joint=maxf(maximum_joint,sample.joint_gap)
			finite=finite and sample.finite and Authentic._finite(fixture.rig)
			stretch=maxf(stretch,Authentic._max_stretch(fixture.rig))
			var current:=Authentic._markers(fixture.rig)
			step=maxf(step,Authentic._marker_delta(previous,current))
			previous=current
		if phase==0:
			for index: int in 2:
				var side: float=fixture.rig._legs[index].side
				sole_error=maxf(sole_error,fixture.rig._legs[index].foot.to_global(SOLE).distance_to(fixture.rig.pogo_foot_contact(side,rest)))
				var target: Vector3=fixture.board.to_global(Basis(Vector3.UP,-rest)*fixture.rig.pogo_hand_target(side))
				palm_error=maxf(palm_error,fixture.rig._arms[index].hand.to_global(PALM).distance_to(target))
	check.call(maximum_seam<0.12 and maximum_joint<0.06,
		"Pogo attachment: actual deformed hem/waist and torso/pelvis stay connected throughout entry, hold and release rest=%.2f"%rest)
	check.call(finite and stretch<=1.12 and step<0.22,
		"Pogo attachment: common reach preserves finite fixed-length limbs and bounded pose continuity rest=%.2f"%rest)
	check.call(sole_error<0.005 and palm_error<0.025,
		"Pogo attachment: actual settled cupsoles and anatomical palms retain their wheel/nose contacts rest=%.2f"%rest)
	fixture.rig.reset()
	var neutral:=Attachment._sample(fixture.body,data)
	check.call(fixture.rig._pogo_blend==0.0 and neutral.seam<0.08 and neutral.joint_gap<0.06,
		"Pogo attachment: explicit reset restores the actual neutral garment attachment rest=%.2f"%rest)
	print("POGO_ATTACHMENT_GEOMETRY ",{"rest":rest,"maximum_seam":maximum_seam,"maximum_joint":maximum_joint,
		"stretch":stretch,"maximum_step":step,"sole_error":sole_error,"palm_error":palm_error,"finite":finite})
	await Authentic._dispose(tree,fixture.root)


static func _input(tree: SceneTree,check: Callable,interrupt: bool) -> void:
	var fixture:=await Classic._fixture(tree)
	var rider: CharacterBody3D=fixture.rider
	var rig: RefCounted=rider._visual_rig
	var data:=Attachment._prepare(rig)
	var events: Array[Dictionary]=[]
	var on_trick:=func(label: String,points: int):events.append({"label":label,"points":points})
	rider.trick_performed.connect(on_trick)
	Input.action_press("push")
	await Classic._frames(tree,42)
	Input.action_release("push")
	await Classic._frames(tree,13)
	Input.action_press("manual")
	await Classic._frames(tree,1)
	Classic._direction(Vector2.DOWN)
	Input.action_press("grab")
	var entry:=await Attachment._observe(tree,rider,data,1,"pogo_input_entry")
	Input.action_release("grab")
	Classic._direction(Vector2.ZERO)
	var hold:=await Attachment._observe(tree,rider,data,30,"pogo_input_hold")
	check.call(rider.manual_active and rider.manual_trick_id=="pogo" and events.count({"label":"Pogo","points":450})==1,
		"Pogo attachment: real Manual then Down/Grab enters Pogo and emits its exact catalog award once")
	check.call(entry.finite and hold.finite and maxf(entry.maximum_seam,hold.maximum_seam)<0.12
		and maxf(entry.maximum_joint_gap,hold.maximum_joint_gap)<0.06,
		"Pogo attachment: native mapped entry and hold keep the drawn torso and trousers connected")
	Input.action_release("manual")
	if interrupt:rider.begin_bail("pogo_attachment_interruption")
	var released:=await Attachment._observe(tree,rider,data,150,"pogo_bail_getup" if interrupt else "pogo_release")
	check.call(not rider.bailing and rider.is_on_floor() and not rider.manual_active,
		"Pogo attachment: actual released/interrupted manual returns to supported ordinary skating")
	if interrupt:
		check.call(released.phases.has("get_up") and released.maximum_surface_gap<0.05
			and released.maximum_joint_gap<0.10 and released.maximum_neck_gap<0.05,
			"Pogo attachment: actual interrupted Pogo keeps native clothed waist and neck attached through fall/get-up")
	else:
		check.call(released.finite and released.maximum_seam<0.12 and released.maximum_joint_gap<0.06,
			"Pogo attachment: native manual release retains actual cloth attachment while its reach influence fades")
	Input.action_press("push",0.25)
	var settled:=await Attachment._observe(tree,rider,data,45,"pogo_after_recovery_push")
	Input.action_release("push")
	check.call(settled.finite and settled.maximum_seam<0.08 and settled.maximum_joint_gap<0.06
		and events.count({"label":"Pogo","points":450})==1,
		"Pogo attachment: ordinary skating after release/recovery stays connected without a duplicate trick award")
	if interrupt:
		rider.begin_bail("pogo_attachment_restart")
		await Classic._frames(tree,3)
		rider.reset_skater()
		var restart:=Attachment._sample(rider,data)
		check.call(not rider.bailing and rig._pogo_blend==0.0 and restart.seam<0.08 and restart.joint_gap<0.06,
			"Pogo attachment: real restart during fall clears the manual reach and immediately restores native cloth attachment")
	print("POGO_ATTACHMENT_INPUT ",{"interrupt":interrupt,"entry":entry,"hold":hold,"released":released,"settled":settled,"events":events})
	rider.trick_performed.disconnect(on_trick)
	await Classic._dispose(tree,fixture)
