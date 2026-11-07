extends SceneTree
const Setup=preload("res://game/core/input_setup.gd")
const Main=preload("res://game/main.gd")
const Motion=preload("res://tests/motion_fidelity_tests.gd")
const Balance=preload("res://tests/fidelity_acceptance_tests.gd")
const Lines=preload("res://tests/line_design_tests.gd")
const Wall=preload("res://tests/skater_wall_manual_tests.gd")
const Arm=preload("res://tests/skater_obstacle_arm_tests.gd")
const Facade=preload("res://tests/facade_bay_tests.gd")
var passed:=0
var failed:=0
var modules:Array[Dictionary]=[]
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1
	print("PASS " if ok else "FAIL ",label)
func _stage(name:String,old_passed:int,old_failed:int)->void:
	modules.append({"name":name,"passed":passed-old_passed,"failed":failed-old_failed})
	print("FOCUS MODULE ",modules[-1])
func _run()->void:
	Setup.register_actions()
	var p:=passed
	var f:=failed
	await Motion.run(self,_check)
	_stage("standalone_motion",p,f)
	var game:=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	for tick in 40:await physics_frame;await process_frame
	p=passed;f=failed
	await Motion.run_main(self,game,_check)
	await Motion.run_main_support(self,game,_check)
	_stage("default_main_motion",p,f)
	p=passed;f=failed
	await Balance.run(self,game,_check)
	_stage("independent_manual_balance",p,f)
	p=passed;f=failed
	await Lines.run(self,game,_check)
	_stage("line_and_forecast_controls",p,f)
	game.queue_free()
	await physics_frame
	await process_frame
	p=passed;f=failed
	await Wall.run(self,_check)
	await Arm.run(self,_check)
	_stage("complete_wall_and_arm",p,f)
	p=passed;f=failed
	await Facade.run(self,_check)
	_stage("complete_facade_bay",p,f)
	var out:=FileAccess.open(OS.get_environment("TAM_ROOT_FOCUS_OUTPUT"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"modules":modules,"passed":passed,"failed":failed},"\t")+"\n")
	out.close()
	print("ROOT INTEGRATED FOCUS: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
