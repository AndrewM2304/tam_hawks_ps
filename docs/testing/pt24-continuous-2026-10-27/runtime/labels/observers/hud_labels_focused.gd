extends SceneTree
const Main = preload("res://game/main.gd")
const Labels = preload("res://tests/hud_trick_label_cache_tests.gd")
const Existing = preload("res://tests/hud_efficiency_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var game := Main.new()
	_check(not game.persistence_enabled,"HUD labels observer: Main is profile-isolated before scene construction")
	if game.persistence_enabled:
		game.free()
		quit(1)
		return
	root.add_child(game)
	for frame: int in 35:
		await physics_frame
		await process_frame
	Labels.run(self,game,_check)
	Existing.run(self,game,_check)
	game.queue_free()
	await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
