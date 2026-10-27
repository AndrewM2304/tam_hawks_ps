extends SceneTree
const Main = preload("res://game/main.gd")
const Fidelity = preload("res://tests/authentic_fidelity_integration_tests.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")
var passed:=0
var failed:=0
var data: Dictionary={}
var report: Dictionary={"samples":0,"tow_samples":0,"maximum_seam":0.0,"maximum_joint":0.0,"maximum_neck":0.0,"finite":true,"worst":{}}
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var game:=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	for frame in 25:
		await physics_frame
		await process_frame
	await Fidelity.run(self,game,_check,_observe,["skitch"])
	print("SKITCH_ATTACHMENT_ACTUAL_MAIN ",report)
	game.queue_free()
	await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _observe(phase: String,game: Node,step: int) -> void:
	if data.is_empty():data=Attachment._prepare(game.skater._visual_rig)
	var sample:=Attachment._sample(game.skater,data)
	report.samples+=1
	if game.skater.skitch_caught:report.tow_samples+=1
	if sample.seam>report.maximum_seam:report.worst={"phase":phase,"step":step,"sample":sample,"tow_blend":game.skater._visual_rig._skitch_blend,"caught":game.skater.skitch_caught}
	report.maximum_seam=maxf(report.maximum_seam,sample.seam)
	report.maximum_joint=maxf(report.maximum_joint,sample.joint_gap)
	report.maximum_neck=maxf(report.maximum_neck,sample.neck_gap)
	report.finite=report.finite and sample.finite
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
