extends SceneTree
const Wall = preload("res://tests/skater_wall_presentation_tests.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	Wall.Setup.register_actions()
	for action: String in ["ollie", "manual"]:
		Wall._release()
		var f: Dictionary = await Wall._fixture(self,-8.0)
		var r: CharacterBody3D = f.rider
		var reached := false
		Input.action_press("push",.55)
		for tick: int in 180:
			await Wall._frames(self,1)
			if Wall._wall_contact(r,f.wall):
				reached=true
				break
		Wall._release()
		Input.action_press("brake")
		await Wall._frames(self,20)
		Wall._release()
		print("WALL_TRANSITION_START ",{"action":action,"reached":reached,"at":r.position,"gap":Wall._plane_gap(r),"offset":r._obstacle_visual_offset,"speed":r.speed})
		Input.action_press(action)
		var records: Array=[]
		for tick: int in 50:
			if tick==12:Input.action_release(action)
			await Wall._frames(self,1)
			records.append({"tick":tick,"gap":Wall._plane_gap(r),"offset":r._obstacle_visual_offset,"position":r.position,"air":r.airborne,"floor":r.is_on_floor(),"crouch":r.crouching,"manual":r.manual_active,"bail":r.bail_active})
		print("WALL_TRANSITION_RESULT ",{"action":action,"records":records})
		Wall._release()
		f.viewport.queue_free()
		await process_frame
	quit(failures)
