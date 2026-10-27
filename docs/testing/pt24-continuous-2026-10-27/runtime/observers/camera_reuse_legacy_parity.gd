extends SceneTree
const Chase = preload("res://game/player/chase_camera.gd")
const Legacy = preload("res://.local/camera_reuse_legacy_camera.gd")
const Acceptance = preload("res://tests/pt24_acceptance_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	Acceptance.Setup.register_actions()
	var fixture := await Acceptance._fixture(self)
	var rider: CharacterBody3D=fixture.rider
	var actual:=Chase.new()
	var original:=Legacy.new()
	var actual_camera:=Camera3D.new()
	var original_camera:=Camera3D.new()
	fixture.root.add_child(actual_camera)
	fixture.root.add_child(original_camera)
	var rays:=0
	var pairs:=0
	for geometry: String in ["open","rear_wall","corner","low_roof","open"]:
		Acceptance._arrange(fixture,geometry)
		await Acceptance._frames(self,2)
		actual.reset();original.reset()
		var initial:=Transform3D(Basis.IDENTITY,rider.global_position+Vector3(0,2.5,5))
		actual_camera.global_transform=initial;original_camera.global_transform=initial
		actual_camera.fov=70;original_camera.fov=70
		var equal:=true
		for sample: int in 8:
			actual.update(rider,actual_camera,1.0/60.0,1.0,false)
			original.update(rider,original_camera,1.0/60.0,1.0,false)
			equal=equal and actual_camera.global_transform==original_camera.global_transform \
				and actual_camera.fov==original_camera.fov and Acceptance._state(actual)==Acceptance._state(original) \
				and actual.last_update_queries==original.last_update_queries
			rays+=int(actual.last_update_queries.ray);pairs+=1
		_check(equal,"camera legacy parity: immutable old controller agrees exactly for "+geometry)
	print("CAMERA_IMMUTABLE_LEGACY_PARITY ",{"pairs":pairs,"visibility_rays":rays,"old_parameter_constructions":rays,"new_parameter_objects":1})
	fixture.viewport.queue_free()
	await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok: passed+=1;print("PASS: ",label)
	else: failed+=1;print("FAIL: ",label)
