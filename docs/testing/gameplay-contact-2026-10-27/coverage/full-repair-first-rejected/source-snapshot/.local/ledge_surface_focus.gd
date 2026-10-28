extends SceneTree
const PureGrindRide = preload("res://tests/grind_ride_tests.gd")
const Main = preload("res://game/main.gd")
const Pond = preload("res://tests/park_pond_tests.gd")
const Facade = preload("res://tests/facade_bay_tests.gd")
const Park = preload("res://tests/kelvingrove_skatepark_tests.gd")
const Fallback = preload("res://tests/native_ledge_fallback_tests.gd")
const Density = preload("res://tests/full_level_density_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	var args:=OS.get_cmdline_user_args()
	var mode:="all" if args.is_empty() else args[0]
	PureGrindRide.run(_check)
	if mode in ["all","terrain"]:
		await Facade.run(self,_check)
		await Pond.run(self,_check)
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	for tick in 25:await physics_frame;await process_frame
	if mode in ["all","terrain"]:
		await Park.run(self,game,_check)
		await Fallback._north_rim(self,game.world,_check)
	if mode in ["all","pond"]:
		await Pond.run_installed(self,game,_check)
		await Pond.run_player(self,game,_check)
	if mode in ["all","density"]:await Density.run(self,game,_check)
	game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
