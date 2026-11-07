extends SceneTree
const Main=preload("res://game/main.gd")
const Setup=preload("res://game/core/input_setup.gd")
const Lines=preload("res://tests/line_design_tests.gd")
var passed:=0
var failed:=0
var legacy_marker:=false
func _initialize():_run.call_deferred()
func _check(ok: bool,label: String):
	if label=="continuous return: actual existing east landward masonry is available":
		legacy_marker=true
		print("LD_LEGACY_GROUP_COMPLETE ",passed," passed, ",failed," failed atphysics ",Engine.get_physics_frames())
	if ok:passed+=1
	else:failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run():
	Setup.register_actions()
	var game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	await Lines.run(self,game,_check)
	var matching: Array[Dictionary]=[]
	for route: Dictionary in game.world.get_route_definitions():
		if route.id=="clyde_east_quay_wall_return":matching.append(route)
	_check(matching.size()==1 and bool(matching[0].requires_jump) and matching[0].points.size()==17,
		"optional quay route: one existing-map jump route retains seventeen authored waypoints")
	game.free()
	print("LD_INTEGRATION RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed>0 else 0)
