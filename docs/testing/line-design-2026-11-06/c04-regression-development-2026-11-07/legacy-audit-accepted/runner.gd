extends SceneTree
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const Compact=preload("res://tests/test_compact_clyde.gd")
const Metadata=preload("res://tests/grind_contact_metadata_tests.gd")
const Surfaces=preload("res://tests/surface_coverage_tests.gd")
var passed:=0
var failed:=0
func _initialize():_run.call_deferred()
func _check(ok: bool,label: String):
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	create_timer(120,true).timeout.connect(func():quit(3))
	Setup.register_actions()
	var game=Main.new()
	game.persistence_enabled=false
	# Match the existing required-suite historical inventory/empty-footprint fixture.
	# Default-on career/facility/local lines were separately exercised in tail01.
	game.set_meta("pt24_design_preview",false)
	root.add_child(game)
	await Driver._frames(self,35)
	await Compact.run(self,game.world,_check)
	Metadata.run_world(game.world,_check)
	await Surfaces.run(self,game.world,_check)
	print("LEGACY COMPACT METADATA SURFACE RESULT: ",passed," passed, ",failed," failed")
	game.free()
	quit(1 if failed>0 else 0)
