extends SceneTree
const Wall = preload("res://tests/skater_wall_presentation_tests.gd")
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	Wall.Setup.register_actions()
	for family: String in ["flip","grab"]:
		_release()
		var f: Dictionary=await Wall._fixture(self,-8.0)
		var r: CharacterBody3D=f.rider
		var c: CharacterBody3D=f.control
		var reached:=false
		Input.action_press("push",0.55)
		for tick: int in 180:
			await Wall._frames(self,1)
			if Wall._wall_contact(r,f.wall):reached=true;break
		_release()
		Input.action_press("brake")
		await Wall._frames(self,20)
		_release()
		await Wall._frames(self,2)
		Input.action_press("ollie")
		await Wall._frames(self,20)
		Input.action_release("ollie")
		await Wall._frames(self,2)
		var prior: Vector3=r._obstacle_visual_offset
		var before:=Wall._plane_gap(r)
		var events: Array=[]
		r.trick_performed.connect(func(label: String,points: int):events.append({"label":label,"points":points}))
		var minimum:=INF
		var active:=0
		var prior_clear:=0
		var parity:=true
		var pose_equal:=true
		var trace: Array=[]
		Input.action_press(family)
		for tick: int in 65:
			if tick==6:Input.action_release(family)
			await Wall._frames(self,1)
			var is_active: bool=r._flip_remaining>0 if family=="flip" else r._grab_remaining>0
			var gap:=Wall._plane_gap(r)
			if is_active:
				active+=1
				minimum=minf(minimum,gap)
				prior_clear+=int(r._obstacle_air_clear(prior))
			parity=parity and Wall._physics(r)==Wall._physics(c)
			pose_equal=pose_equal and r._board_visual.transform==c._board_visual.transform and r._rider_visual.transform==c._rider_visual.transform
			trace.append({"tick":tick,"gap":gap,"offset":r._obstacle_visual_offset,"active":is_active,"air":r.airborne,"bail":r.bail_active})
		_check(reached and before>=0.0079 and prior.length()>0.10,"valid native pre-trick wall/Ollie "+family)
		_check(active>0 and not events.is_empty() and parity and pose_equal,"real scored active trick with identical physical/local-pose twin "+family)
		print("ACTIVE_WALL_PROBE ",{"family":family,"before":before,"prior":prior,"active":active,"minimum":minimum,"prior_finite_clear":prior_clear,"physics_equal":parity,"local_pose_equal":pose_equal,"events":events,"landed":r.is_on_floor(),"bail":r.bail_active,"trace":trace})
		_release()
		f.viewport.queue_free()
		await process_frame
	print("RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
func _release() -> void:
	for action: String in InputMap.get_actions():Input.action_release(action)
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;print("FAIL: ",label)
