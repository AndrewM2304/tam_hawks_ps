extends SceneTree
## Prepared focused runner; execute only after root's write/engine lease.
const Main = preload("res://game/main.gd")
const FacadeTests = preload("res://tests/facade_bay_tests.gd")
var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if ok: _passed += 1
	else: _failed += 1
	print(("PASS: " if ok else "FAIL: ")+message)

func _ordinary_snapshot(enabled: bool) -> Dictionary:
	var game: Node = Main.new()
	game.persistence_enabled = false
	game.set_meta(&"facade_bay_enabled",enabled)
	root.add_child(game)
	game.start_mode(true)
	await physics_frame
	await process_frame
	var world: Node3D = game.world
	var report: Dictionary = {
		"collisions":FacadeTests._collisions(world),
		"routes":var_to_bytes(world.get_route_definitions()),
		"rails":FacadeTests._rails(world),
		"support":FacadeTests._support(world),
		"bodies":world.find_children("*","StaticBody3D",true,false).size(),
		"shapes":world.find_children("*","CollisionShape3D",true,false).size(),
		"ordinary_defaults":bool(game.get_meta("pt24_design_preview",false))
			and bool(world.get_meta("pt24_design_preview",false))
			and world.find_child("StationRailway",true,false)!=null
			and world.find_child("ScenicTwoCoachTrain",true,false)!=null
			and world.find_child("KelvingrovePond",true,false)!=null
			and world.find_child("CivicPortReturn",true,false)!=null
			and world.has_meta("pt24_central_green_report"),
		"profile_writes":game.persistence_enabled,
		"old_inventory_baseline":bool(world.get_meta("render_budget_probe_baseline",false))
	}
	game.free()
	await process_frame
	await physics_frame
	return report

func _run() -> void:
	await FacadeTests.run(self,_check)
	var original: Dictionary = await _ordinary_snapshot(false)
	var candidate: Dictionary = await _ordinary_snapshot(true)
	_check(original.ordinary_defaults and candidate.ordinary_defaults
		and not original.old_inventory_baseline and not candidate.old_inventory_baseline,
		"reduced facade ordinary Main: station/train/pond/green/civic defaults stay enabled without historical inventory switch")
	_check(not original.profile_writes and not candidate.profile_writes,
		"reduced facade ordinary Main: persistence is disabled before tree entry")
	_check(original.collisions == candidate.collisions and original.bodies == candidate.bodies
		and original.shapes == candidate.shapes,
		"reduced facade ordinary Main: every actual collision/layer/native transform and current world counts are unchanged")
	_check(original.routes == candidate.routes and original.rails == candidate.rails,
		"reduced facade ordinary Main: actual current route data and every grind guide remain equal")
	_check(original.support == candidate.support and candidate.support[0]
		and candidate.support[1] and candidate.support[2],
		"reduced facade ordinary Main: actual threshold, ledge and beginner bypass native support remain equal")
	print("CURRENT_ORDINARY_MAIN_COUNTS bodies=",candidate.bodies," shapes=",candidate.shapes,
		" collision_records=",candidate.collisions.size()," rails=",candidate.rails.size())
	if DisplayServer.get_name() != "headless":
		await FacadeTests.run_rendered(self,_check)
	print("FOCUSED_RESULT passed=",_passed," failed=",_failed,
		" rendered_lod_executed=",DisplayServer.get_name()!="headless")
	quit(0 if _failed==0 else 1)
