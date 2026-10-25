extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures+=1
func _run() -> void:
	var game=preload("res://game/main.gd").new()
	game.persistence_enabled=false
	root.add_child(game)
	for frame in 20:
		await physics_frame
		await process_frame
	await preload("res://tests/pt24_clyde_flagship_tests.gd").run(self,game,_check)
	game.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("CLYDE_FLAGSHIP_RESULT passed=",checks-failures," failed=",failures)
	quit(0 if failures==0 else 1)
