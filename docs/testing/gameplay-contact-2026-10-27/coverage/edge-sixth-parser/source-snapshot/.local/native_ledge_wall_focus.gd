extends SceneTree
const Main = preload("res://game/main.gd")
const Walls = preload("res://tests/wall_ride_tests.gd")
const Fallback = preload("res://tests/native_ledge_fallback_tests.gd")
const Surface = preload("res://tests/surface_coverage_tests.gd")
const Edges = preload("res://tests/skate_edges_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool,label: String) -> void:
	if ok:
		passed+=1;print("PASS: "+label)
	else:
		failed+=1;push_error("FAIL: "+label)
func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var mode := "fallback" if arguments.is_empty() else arguments[0]
	if mode in ["fallback","both","complete"]: await Walls.run(self,_check)
	var game = Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	game.skater.set_physics_process(false);game.skater.set_process(false)
	await physics_frame;await process_frame
	if mode in ["fallback","both"]: await Fallback.run(self,game.world,_check)
	if mode=="complete": await Edges.run(game.world,_check)
	if mode!="fallback": await Surface.run(self,game.world,_check)
	print("NATIVE_LEDGE_WORK ",JSON.stringify(game.world.get_surface_audit().get("native_ledge_fallback",{})))
	game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
