extends SceneTree
const Ride=preload("res://tests/grind_ride_tests.gd")
const Bounds=preload("res://tests/grind_capture_bounds_tests.gd")
const Metadata=preload("res://tests/grind_contact_metadata_tests.gd")
const Style=preload("res://tests/grind_style_tests.gd")
const Native=preload("res://tests/named_grind_integration_tests.gd")
const Consumers=preload("res://tests/named_grind_consumers_tests.gd")
const Edges=preload("res://tests/edge_grind_integration_tests.gd")
const Main=preload("res://game/main.gd")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred('_run')
func _run()->void:
	Ride.run(_check);Bounds.run(_check);Metadata.run(_check);Style.run(_check)
	await Native.run(self,_check)
	await Consumers.run(self,_check)
	await Edges.run(self,_check)
	var game=Main.new();game.persistence_enabled=false;root.add_child(game)
	await Classic._frames(self,35)
	Metadata.run_world(game.world,_check)
	game.queue_free();await process_frame
	print('RESULT: ',passed,' passed, ',failed,' failed');quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print('PASS: ',message)
	else:failed+=1;printerr('FAIL: ',message)
