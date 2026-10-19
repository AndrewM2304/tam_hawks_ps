extends SceneTree
const MainScene=preload("res://game/main.tscn")
const Review=preload("res://tests/playability_regression_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred("_run")
func _run()->void:
	var game=MainScene.instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	await Review.run(self,game,_check)
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print("PASS: ",message)
	else:failed+=1;print("FAIL: ",message)
