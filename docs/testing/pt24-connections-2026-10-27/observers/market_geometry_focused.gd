extends SceneTree
const Legacy=preload("res://.local/market_legacy_terrain.gd")
const Main = preload("res://game/main.gd")
const Bank=preload("res://tests/terrain_bank_edge_tests.gd")
const Support=preload("res://tests/support_query_tests.gd")
const Test = preload("res://tests/pt24_market_full_run_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game:=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await process_frame
	_check(not game.music._can_control and game.music._worker==null and game.music._pending.is_empty(),"Market fixture: personal Music is inert before start_mode")
	_check(bool(game.get_meta("pt24_design_preview",false)),"Market fixture: ordinary Main content is enabled without override")
	await Bank.run(self,_check)
	await Bank.run_world(self,game,_check)
	var legacy:=Legacy.new();legacy.patches=game.world._terrain.patches.duplicate(true);legacy.polygons=game.world._terrain.polygons.duplicate(true)
	var actual: Dictionary=Bank.finite_boundary_contact(game.world,Vector3(76,.05,-6.4))
	_check(legacy.height_at(76,-6.4)==0 and absf(game.world.get_ground_height(Vector3(76,.05,-6.4))-.05)<.001
		and not actual.is_empty() and actual.collider==game.world.get_node("MarketWestLoadingBank") and absf(actual.position.y-.05)<.002,
		"Market native finite negative control: immutable prior query picks buried floor while current query matches unchanged real bank")
	await Support.run(game.world,_check)
	await Test._construction(self,game,_check)
	game.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
func _check(ok: bool,label: String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
