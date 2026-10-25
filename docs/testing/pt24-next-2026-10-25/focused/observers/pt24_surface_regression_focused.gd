extends SceneTree
var passed := 0
var failed := 0
func _initialize(): call_deferred("_run")
func _check(ok: bool,label: String):
 if ok: passed+=1
 else:
  failed+=1
  push_error("FAIL: "+label)
func _run():
 var game = preload("res://game/main.gd").new()
 game.persistence_enabled=false
 root.add_child(game)
 for frame in 4:
  await physics_frame
  await create_timer(0.0,false,false).timeout
 await preload("res://tests/surface_coverage_tests.gd").run(self,game.world,_check)
 game.queue_free()
 await physics_frame
 print("RESULT: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
