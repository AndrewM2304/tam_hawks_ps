extends Node
## Scene-based wrapper: deliberately omit --script so Main runs its normal title branch.
const MainScene = preload("res://game/main.tscn")
const Tests = preload("res://tests/playability_regression_tests.gd")
const Music = preload("res://game/audio/apple_music.gd")
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
	_check(not Music.is_scripted_launch(OS.get_cmdline_args())
		and not OS.get_cmdline_user_args().has("--pt24-design-preview")
		and game.paused and game.hud._page=="title",
		"playability boot: ordinary no-script launch constructs current content at the real title without preview opt-in")
	var world: Node3D=game.world
	var railway: Node3D=world.get_node_or_null("StationRailway")
	_check(is_instance_valid(railway) and bool(railway.get("built"))
		and is_instance_valid(railway.get("train")) and railway.train.get_child_count()>0,
		"playability boot: normal Main builds the enclosed station and actual scenic train")
	var pond: Node3D=world.get_node_or_null("KelvingrovePond")
	_check(is_instance_valid(pond) and bool(pond.get("_built"))
		and pond.has_node("PondWater") and not pond.get_grind_lines().is_empty(),
		"playability boot: normal Main builds the real pond, water and perimeter bearing")
	var green: Dictionary=world.get_meta("pt24_central_green_report",{})
	var relocated: Array=green.get("relocated_trees",[])
	var trunks: MultiMeshInstance3D=world.get_node("OutdoorRoutes/ParkTreeTrunks")
	var crowns: MultiMeshInstance3D=world.get_node("OutdoorRoutes/ParkTreeCanopies")
	var lower: Array=trunks.get_meta("authored_tree_transforms",[])
	var upper: Array=crowns.get_meta("authored_tree_transforms",[])
	var paired:=relocated.size()==6
	for row: Dictionary in relocated:
		var index: int=row.index
		paired=paired and index>=0 and index<lower.size() and index<upper.size() \
			and lower[index]==row.after and upper[index]==row.after and row.before!=row.after
	_check(paired,"playability boot: normal Main installs all six paired central-green tree relocations")
	var civic: Node3D=world.get_node_or_null("CivicPortReturn")
	_check(is_instance_valid(civic) and is_instance_valid(civic.get("surface_body"))
		and world.has_node("CivicPortReturnFoundation") and not civic.get_grind_lines().is_empty(),
		"playability boot: normal Main builds the native civic return quarter, coping and retained foundation")
	_check(not game.persistence_enabled and not game.music._persist and not game.music._can_control
		and not game.music.snapshot().enabled,
		"playability boot: ordinary-title fixture keeps profile writes and real Music control isolated")
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
