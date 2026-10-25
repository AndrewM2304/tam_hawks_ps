extends SceneTree
const Music = preload("res://game/audio/apple_music.gd")
const Main = preload("res://game/main.gd")
const Tests = preload("res://tests/apple_music_tests.gd")

class PreferenceSpy extends Music:
	var preference_reads := 0
	func _load_preferences() -> void: preference_reads+=1

var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func _check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	print("ACTUAL_ENGINE_ARGUMENTS ",OS.get_cmdline_args())
	var game := Main.new()
	_check(not game.persistence_enabled,"actual script alias: Main defaults to isolated profile before entering tree")
	var main_isolated: bool = not game.persistence_enabled
	game.free()
	if not main_isolated:
		print("SCRIPT LAUNCH: %d passed, %d failed"%[passed,failed])
		quit(1)
		return
	var music := PreferenceSpy.new()
	music.configure(true)
	var music_isolated: bool = not music._persist and not music._can_control and not music.snapshot().enabled and music.preference_reads==0
	_check(music_isolated,
		"actual script alias: Music stays inert even if persistence is requested")
	music.free()
	if not music_isolated:
		print("SCRIPT LAUNCH: %d passed, %d failed"%[passed,failed])
		quit(1)
		return
	if not OS.get_cmdline_user_args().has("--guard-only"):
		await Tests.run(self,_check)
	print("SCRIPT LAUNCH: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
