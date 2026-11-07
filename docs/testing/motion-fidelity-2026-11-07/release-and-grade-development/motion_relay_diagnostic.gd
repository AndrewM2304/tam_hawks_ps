extends SceneTree
const Main=preload("res://game/main.tscn")
const Setup=preload("res://game/core/input_setup.gd")
const Lines=preload("res://tests/line_design_tests.gd")
const Board=preload("res://tests/board_geometry_tests_support.gd")
var passed:=0
var failed:=0
func _initialize():_run.call_deferred()
func _check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	create_timer(180,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await Lines.run_relay(self,game,_check,_observe)
	print("MOTION_RELAY_DIAGNOSTIC ",passed,"/",failed)
	game.free()
	quit(1 if failed>0 else 0)
func _observe(phase:String,game:Node,tick:int)->void:
	if not (phase.ends_with("second_exit_charge") or phase.ends_with("second_exit") or (phase.ends_with("second_landing") and tick<445)):return
	var rider:Node=game.skater
	var rig:RefCounted=rider._visual_rig
	var records:Array=[]
	var overall:=INF
	for mesh:MeshInstance3D in Board.visible_meshes(rig,false):
		var low:=INF
		var at:=Vector3.ZERO
		var native:Dictionary={}
		var hull:ConvexPolygonShape3D=mesh.mesh.create_convex_shape(true,false)
		for point:Vector3 in hull.points:
			var actual:=mesh.to_global(point)
			var ray:=PhysicsRayQueryParameters3D.create(actual+Vector3.UP*.3,actual-Vector3.UP*.3,1|8,[rider.get_rid()])
			var hit:Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty():continue
			var gap:float=(actual-Vector3(hit.position)).dot(hit.normal)
			if gap<low:
				low=gap;at=actual;native={"label":hit.collider.get_meta("art_label",hit.collider.name),"shape":hit.shape,"point":hit.position}
		overall=minf(overall,low)
		records.append({"mesh":rider.get_path_to(mesh),"min_gap":low,"point":at,"support":native})
	print("MOTION_SECOND_EXIT tick=",tick," physics=",Engine.get_physics_frames()," phase=",phase," grinding=",rider.grinding,
		" air=",rider.airborne," body=",rider.global_position," velocity=",rider.velocity," visual=",rider._visual.transform,
		" board=",rider._board_visual.global_transform," offset=",rider._grind_visual_offset,
		" support_basis=",rider._air_support_basis," min_native_gap=",overall," components=",records)
