extends SceneTree
## Original route functions in original order on the same ordinary Main/Skater.
## No copied/adapted route or player implementation is used.
const Main=preload("res://.local/park-shoulder-witness/main_adapter.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const Clyde=preload("res://tests/pt24_clyde_flagship_tests.gd")
const Civic=preload("res://tests/pt24_civic_park_run_tests.gd")
const Witness=preload("res://.local/clyde-civic-contact/observer.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Facility=preload("res://tests/pt24_facility_connection_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
	for action:StringName in InputMap.get_actions():Input.action_release(action)
	var game:=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	for frame in 25:
		await physics_frame
		await process_frame
	print("FOCUS_BEGIN originalGalleryStation")
	await Driver.run(self,game,_check)
	print("FOCUS_BEGIN originalFullClydeSameActor")
	await Clyde.run(self,game,_check)
	print("FOCUS_BEGIN originalCivicSameActor")
	await Civic.run(self,game,_check)
	print("FOCUS_BEGIN originalFacilitySameActor")
	await Facility.run(self,game,_check,_observe)
	for action:StringName in InputMap.get_actions():Input.action_release(action)
	game.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)

func _observe(phase:String,game:Node,tick:int)->void:
	var rider:CharacterBody3D=game.skater
	if phase.contains("practice_to_summit_access") and tick%8==0 and rider.global_position.x> -142 and rider.global_position.x< -140:
		if not Density._camera_clear(game):
			print("DIAGNOSTIC_FIRST_FALSE phase=",phase," tick=",tick)
			Witness.observe(game,"park-shoulder-first-false")
			print("DIAGNOSTIC_REPRODUCED; original route intentionally stops after read-only first-false witness; no route acceptance claimed")
			quit(0)
