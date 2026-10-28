extends SceneTree
const Main=preload("res://.local/clyde-civic-contact/main_print_adapter.gd")
const Clyde=preload("res://.local/clyde-civic-contact/clyde_adapter.gd")
const Civic=preload("res://.local/clyde-civic-contact/civic_adapter.gd")
const Observe=preload("res://.local/clyde-civic-contact/density_adapter.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	await Civic.Driver._frames(self,3)
	var args=OS.get_cmdline_user_args()
	var selected=args[0] if args.size()>0 else "clyde"
	Observe.tag=selected;Observe.enabled=true
	if selected=="clyde":await Clyde.run_bank_return(self,game,_check)
	elif selected=="civic":await Civic._combo(self,game,_check,Callable())
	else:_check(false,"unknown contact diagnostic")
	print("RESULT: %d passed, %d failed"%[passed,failed])
	game.queue_free();await process_frame
	quit(1 if failed else 0)
