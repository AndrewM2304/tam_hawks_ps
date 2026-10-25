extends SceneTree
const Main = preload("res://game/main.gd")
const Bowl = preload("res://tests/pt24_bowl_contact_tests.gd")
const Manual = preload("res://tests/pt24_manual_grade_tests.gd")
const Clyde = preload("res://tests/pt24_clyde_flagship_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func _check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	await Bowl.run(self,_check)
	await Manual.run(self,_check)
	var game := Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	_check(not game.music._can_control and not game.music._persist,"bowl focused has no Music control or preferences")
	for tick in 20:
		await physics_frame
		await process_frame
	await Clyde.run_bank_return(self,game,_check)
	game.queue_free()
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
