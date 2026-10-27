extends SceneTree
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	for yaw: float in [0.0,0.8]:
		var fixture := await Authentic._fixture(self,yaw)
		var data := Attachment._prepare(fixture.rig)
		var state := Authentic._neutral()
		Authentic._settle(fixture.rig,state)
		var neutral := Attachment._sample(fixture.body,data)
		var grips: Array[Vector3] = [fixture.body.to_global(Vector3(-0.40,0.93,-0.505)), fixture.body.to_global(Vector3(0.40,0.93,-0.505))]
		state.merge({"skitching":true,"skitch_grips":grips,"skitch_normal":fixture.body.global_basis.z},true)
		var entry := _phase(fixture,data,state,90)
		var palms := 0.0
		for index in 2: palms=maxf(palms,fixture.rig._arms[index].hand.to_global(Authentic.PALM).distance_to(grips[index]))
		var active := Attachment._sample(fixture.body,data)
		state.skitching=false
		state.skitch_grips=[]
		var released := _phase(fixture,data,state,90)
		state.skitching=true
		state.skitch_grips=grips
		Authentic._settle(fixture.rig,state)
		var definition := Catalog.definition("melon_grab")
		state.merge({"skitching":false,"skitch_grips":[],"airborne":true,"grab":true,"grab_side":definition.grab_side,"grab_target":definition.grab_target,"grab_definition":definition},true)
		fixture.rider.position.y=-0.17
		fixture.rider.rotation.x=-0.30
		var interrupted := _phase(fixture,data,state,14)
		print("SKITCH_ATTACHMENT_PROBE ",{"yaw":yaw,"neutral":neutral,"entry":entry,"active":active,"released":released,"interrupted":interrupted,"palms":palms,"soles":Authentic._feet_error(fixture),"stretch":Authentic._max_stretch(fixture.rig)})
		await Authentic._dispose(self,fixture.root)
	quit(0)
func _phase(fixture: Dictionary,data: Dictionary,state: Dictionary,count: int) -> Dictionary:
	var result := {"maximum_seam":0.0,"maximum_joint":0.0,"maximum_neck":0.0,"maximum_step":0.0,"finite":true,"worst":{},"settled":{}}
	var previous := Authentic._markers(fixture.rig)
	for frame in count:
		fixture.rig.animate(1.0/60.0,state)
		var sample := Attachment._sample(fixture.body,data)
		if sample.seam>result.maximum_seam:result.worst={"frame":frame,"sample":sample}
		result.maximum_seam=maxf(result.maximum_seam,sample.seam)
		result.maximum_joint=maxf(result.maximum_joint,sample.joint_gap)
		result.maximum_neck=maxf(result.maximum_neck,sample.neck_gap)
		result.finite=result.finite and sample.finite
		var current:=Authentic._markers(fixture.rig)
		result.maximum_step=maxf(result.maximum_step,Authentic._marker_delta(previous,current))
		previous=current
		result.settled=sample
	return result
