extends SceneTree
const Main = preload("res://game/main.gd")
const Test = preload("res://tests/pt24_facility_connection_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred("_run")
func _run()->void:
	var game:=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await process_frame
	_check(not game.music._can_control and game.music._worker==null and not game.persistence_enabled,"Facility fixture: scripted Main Music remains isolated before gameplay")
	_check(bool(game.get_meta("pt24_design_preview",false)),"Facility fixture: actual Main enables all merged trial content without an override")
	if failed==0:await Test.run(self,game,_check)
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
func _check(condition:bool,label:String)->void:
	if condition:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
