extends SceneTree
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Feature=preload("res://tests/feature_transition_ride_tests.gd")
const Connected=preload("res://tests/connected_transition_tests.gd")
const Bowl=preload("res://tests/pt24_bowl_contact_tests.gd")
const Player=preload("res://tests/transition_player_tests.gd")
const Main=preload("res://game/main.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: "+label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	var args:=OS.get_cmdline_user_args()
	var mode:String=args[0] if not args.is_empty() else "all"
	if mode in ["all","classic"]:await Classic.run(self,_check)
	if mode in ["all","feature"]:
		await Feature.run(self,_check)
		await Connected.run(self,_check)
		await Bowl.run(self,_check)
	if mode in ["all","player"]:
		var game=Main.new();game.persistence_enabled=false
		game.set_meta("pt24_design_preview",false)
		root.add_child(game)
		for frame in 35:await physics_frame;await process_frame
		await Player.run(self,game,_check)
		game.queue_free();await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(0 if failed==0 else 1)
