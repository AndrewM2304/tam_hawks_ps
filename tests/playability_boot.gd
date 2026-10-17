extends Node
## Scene-based wrapper: deliberately omit --script so Main runs its normal title branch.
const MainScene = preload("res://game/main.tscn")
const Tests = preload("res://tests/playability_regression_tests.gd")
var passed := 0
var failed := 0
var _started_ms := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_started_ms = Time.get_ticks_msec()
	_run.call_deferred()

func _process(_delta:float) -> void:
	if Time.get_ticks_msec()-_started_ms > 180000:
		push_error("PLAYABILITY BOOT TIMEOUT: normal gameplay checks did not finish")
		get_tree().quit(2)

func _run() -> void:
	var game:Node = MainScene.instantiate()
	game.persistence_enabled = false
	add_child(game)
	await get_tree().process_frame
	await Tests.run_normal_boot(get_tree(),game,_check)
	get_tree().paused = false
	game.queue_free()
	await get_tree().process_frame
	print("PLAYABILITY RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(1 if failed else 0)

func _check(ok:bool,label:String) -> void:
	if ok:
		passed+=1
		print("PASS: "+label)
	else:
		failed+=1
		push_error("FAIL: "+label)
