extends SceneTree
const Main = preload("res://game/main.gd")
var passed := 0
var failed := 0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var game := Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await physics_frame
	await process_frame
	_check(not game.music._can_control and game.music._worker==null and game.music._pending.is_empty(),
		"Civic/park classification fixture: scripted Music stays inert")
	_check(bool(game.get_meta("pt24_design_preview",false)),"Civic/park classification fixture: normal default-on Main")
	for row: Array in [
		[Vector3(-96,6,-130),"kelvingrove","actual practice quarter"],
		[Vector3(-82,6.4,-135),"kelvingrove","actual practice manual pad"],
		[Vector3(-111,6.55,-130),"kelvingrove","actual practice ledge"],
		[Vector3(-117.8,6,-139.3),"kelvingrove","inside southwest apron edge"],
		[Vector3(-76.2,6,-126.2),"kelvingrove","inside northeast apron edge"],
		[Vector3(-118.2,6,-139.3),"central_station","outside west apron edge"],
		[Vector3(-75.8,6,-132),"central_station","outside east apron edge"],
		[Vector3(-72,2,20),"central_station","unchanged station concourse"],
		[Vector3(-22,4,-74),"george_square","unchanged civic court"],
		[Vector3(-38.5,6,-124.8),"george_square","unchanged civic quarter approach"],
		[Vector3(-65,6,-123),"kelvingrove","unchanged narrow promenade"]]:
		var actual: String=game.world.get_district_id(row[0])
		_check(actual==String(row[1]),"C04 park classification: "+String(row[2])+" is "+actual+"; expected "+String(row[1]))
	for path: String in ["OutdoorRoutes/KelvingrovePromenadeQuarter","OutdoorRoutes/PracticeManualPad","OutdoorRoutes/PracticeLedge"]:
		var feature: Node3D=game.world.get_node(path)
		var actual: String=game.world.get_location_name(feature.global_position)
		_check(actual=="KELVINGROVE PARK","C04 park public location: "+path+" is "+actual)
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok:
		passed+=1
		print("PASS: ",label)
	else:
		failed+=1
		print("FAIL: ",label)
