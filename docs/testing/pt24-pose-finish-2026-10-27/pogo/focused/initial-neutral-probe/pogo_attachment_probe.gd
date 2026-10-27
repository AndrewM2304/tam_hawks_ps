extends SceneTree
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	for rest: float in [0.0,PI]:
		var fixture := await Authentic._fixture(self,0.6,rest)
		var data := Attachment._prepare(fixture.rig)
		var state := Authentic._neutral()
		state.merge({"manual":true,"manual_definition":Catalog.definition("pogo"),"deck_yaw":rest,"rest_deck_yaw":rest},true)
		var maximum_seam:=0.0
		var maximum_joint:=0.0
		for frame: int in 90:
			Authentic._manual_frame(fixture,state)
			var sample:=Attachment._sample(fixture.body,data)
			maximum_seam=maxf(maximum_seam,sample.seam)
			maximum_joint=maxf(maximum_joint,sample.joint_gap)
		print("POGO_ATTACHMENT_BEFORE ",{"rest":rest,"maximum_seam":maximum_seam,"maximum_joint":maximum_joint,"settled":Attachment._sample(fixture.body,data)})
		await Authentic._dispose(self,fixture.root)
	quit(0)
