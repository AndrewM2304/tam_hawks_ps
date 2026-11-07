extends "res://tools/full_fidelity_capture.gd"
const Clyde=preload("res://tests/pt24_clyde_flagship_tests.gd")
class ActiveSnapshot extends Node:
	var observed:Node
	var runner
	var authored:=false
	var cylindrical:=false
	var records:Array=[]
	func _physics_process(_delta:float):
		var rider:CharacterBody3D=observed.skater
		if rider._feature_transition.active and not authored:
			authored=true
			var state:Dictionary=runner._snapshot(observed)
			runner._check(state.transition_state==rider._feature_transition.state and not state.transition_feature.is_empty(),"capture snapshot: real active authored native feature records state and actual Node path")
			records.append({"kind":"authored","snapshot":state})
		if rider._transition.active and not cylindrical:
			cylindrical=true
			var state:Dictionary=runner._snapshot(observed)
			runner._check(state.cylindrical_transition_active and not state.cylindrical_transition_feature_id.is_empty() and not state.cylindrical_transition_body.is_empty(),"capture snapshot: real active cylindrical native feature records actual Dictionary identity/body")
			records.append({"kind":"cylindrical","snapshot":state})
func _run()->void:
	print("CLYDE CURRENT MAIN START")
	game=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	var observer:=ActiveSnapshot.new()
	observer.observed=game
	observer.runner=self
	observer.process_physics_priority=200
	root.add_child(observer)
	await Clyde.run_bank_return(self,game,_check)
	print("CLYDE ACTIVE SNAPSHOT authored=",observer.authored," cylindrical=",observer.cylindrical)
	FileAccess.open("res://.local/clyde-active-snapshots.json",FileAccess.WRITE).store_string(JSON.stringify(observer.records))
	observer.free()
	game.free()
	print("CLYDE CURRENT MAIN RESULT: ",checks-failures," passed, ",failures," failed")
	quit(1 if failures else 0)
