extends SceneTree
const Main=preload("res://game/main.gd")
const Bank=preload("res://tests/terrain_bank_edge_tests.gd")
const Support=preload("res://tests/support_query_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game:=Main.new();game.persistence_enabled=false;root.add_child(game)
	await process_frame
	await Bank.run(self,_check)
	await Bank.run_world(self,game,_check)
	await Support.run(game.world,_check)
	game.queue_free();await process_frame;await physics_frame;await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
func _check(ok: bool,label: String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
