extends SceneTree
const Cat=preload("res://tests/cat_encounter_tests.gd")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Main=preload("res://game/main.gd")
var game:Node
var passed:=0
var failed:=0
var watching:=false
var rows:Array=[]
class Sampler extends Node:
	var audit:SceneTree
	func _ready()->void:process_physics_priority=100
	func _physics_process(_delta:float)->void:
		if not audit.watching:return
		var r=audit.game.skater
		if r.grinding or Input.is_action_pressed('ollie') or r._jump_buffer_remaining>0 or r._crouch_charge>0:
			audit.rows.append({'tick':Engine.get_physics_frames(),'at':str(r.global_position),'grind':r.grinding,'held':r._ollie_held,'charge':r._crouch_charge,'pop':r._pop_impulse,'buffer':r._jump_buffer_remaining,'pressed':Input.is_action_pressed('ollie'),'just_pressed':Input.is_action_just_pressed('ollie'),'just_released':Input.is_action_just_released('ollie')})
func _initialize()->void:call_deferred('_run')
func _run()->void:
	game=Main.new();game.persistence_enabled=false;root.add_child(game)
	await Classic._frames(self,35)
	var sample:=Sampler.new();sample.audit=self;root.add_child(sample);watching=true
	await Cat._physical_sequence(self,game,_check)
	FileAccess.open(OS.get_cmdline_user_args()[0].path_join('cat-input.json'),FileAccess.WRITE).store_string(JSON.stringify(rows,'\t'))
	print('RESULT: ',passed,' passed, ',failed,' failed');quit(1 if failed else 0)
func _check(ok:bool,message:String)->void:
	if ok:passed+=1;print('PASS: ',message)
	else:failed+=1;printerr('FAIL: ',message)
