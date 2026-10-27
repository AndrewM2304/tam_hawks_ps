extends SceneTree
## Read-only native scalars and sole geometry; two ordinary input twins.
const TraceSkater=preload("res://.local/foot_sign_trace_skater.gd")
const Wall=preload("res://tests/skater_wall_presentation_tests.gd")
const Grade=preload("res://tests/pt24_manual_grade_tests.gd")
const Gate=preload("res://game/features/service_gate.gd")
var passed:=0
var failed:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	Wall.Setup.register_actions();Wall._release()
	var base:=_fixture("baseline");var policy:=_fixture("push-policy")
	await Wall._frames(self,4)
	var r: CharacterBody3D=base.rider;var c: CharacterBody3D=policy.rider
	var requested:=false;var impact:=-1;var physical:=true
	var records: Array[Dictionary]=[]
	var previous: Dictionary={};var peaks: Dictionary={"baseline":0.0,"push-policy":0.0}
	Input.action_press("push",0.55)
	for tick: int in 100:
		if not requested and absf(r.speed)>=2.5 and r.global_position.z< -1.0:requested=true;Input.action_press("manual")
		await Wall._frames(self,1)
		if impact<0 and Wall._wall_contact(r,base.gate._panel):impact=tick;Input.action_release("push");Input.action_press("brake")
		physical=physical and Grade._physics(r)==Grade._physics(c)
		for f: Dictionary in [base,policy]:
			var actor: CharacterBody3D=f.rider
			var rig: RefCounted=actor._visual_rig
			var foot: Node3D=rig._legs[1].foot
			var point:=actor.to_local(foot.global_position)
			var step:=0.0
			if previous.has(f.mode):step=point.distance_to(previous[f.mode])
			previous[f.mode]=point;peaks[f.mode]=maxf(peaks[f.mode],step)
			if tick<75 or tick>90:continue
			var floor_min:=INF;var deck_min:=INF;var deck_samples:=0
			for vertex: Vector3 in rig._sole_points:
				var world:=foot.to_global(vertex);floor_min=minf(floor_min,world.y)
				var local: Vector3=rig._board.to_local(world)
				var height: float=rig._deck_top_height_at(local)
				if is_finite(height):deck_min=minf(deck_min,local.y-height);deck_samples+=1
			records.append({"mode":f.mode,"tick":tick,"manual":actor.manual_active,"speed":actor.speed,
				"real_velocity":actor.get_real_velocity(),"velocity":actor.velocity,"position":actor.global_position,
				"body":actor.global_transform,"root":actor._visual.transform,"board":actor._board_visual.transform,
				"foot":foot.global_transform,"foot_body":point,"foot_step":step,"sole_floor_min":floor_min,
				"sole_deck_min":deck_min if is_finite(deck_min) else null,"sole_deck_samples":deck_samples,
				"trace":rig.trace.duplicate(true)})
	Wall._release()
	_check(requested and impact==79,"foot sign diagnostic: exact ordinary Push/Manual native impact79 occurred")
	_check(physical,"foot sign diagnostic: both native physical histories remain exactly identical")
	_check(records.size()==32,"foot sign diagnostic: exact16 existing phase ticks recorded per direction policy")
	_check(peaks.baseline>0.25,"foot sign diagnostic: retained baseline reproduces measured foot transition; not a healthy-pose assertion")
	var report: Dictionary={"passed":passed,"failed":failed,"impact":impact,"physical_equal":physical,"maximum_right_foot_body_step":peaks,
		"records":records,"method":"Two current-controller native input twins, original signf and proposed physical Push -.5 mapping in ignored visual subclass. Exactly100 native updates; instrumentation intercepts existing animate/drag calls and adds no queries. Signed speed, real movement, gait blends/phase, drag result, actual sole vertices and exact final foot/board/root transforms diagnose existing82to83 transition. No production code or per-tick actor/pose assignment; result counts certify workload only, not healthy gait."}
	var file:=FileAccess.open("res://.local/foot_sign_trace.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("FOOT_SIGN_DIAGNOSTIC ",{"peaks":peaks,"impact":impact,"physical_equal":physical})
	base.viewport.queue_free();policy.viewport.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _fixture(mode: String) -> Dictionary:
	var viewport:=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;root.add_child(viewport)
	var scene:=Node3D.new();viewport.add_child(scene)
	var floor:=StaticBody3D.new();scene.add_child(floor)
	var shape:=BoxShape3D.new();shape.size=Vector3(20,0.2,20)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=-0.1;floor.add_child(collision)
	var gate:=Gate.new();scene.add_child(gate);gate.configure(Vector3.ZERO,PackedVector3Array([Vector3(0,0,-4),Vector3(0,0,4)]),2.3)
	var rider:=TraceSkater.new();rider.trace_mode=mode;rider.spawn_position=Vector3(0,0.04,-3.02);scene.add_child(rider);rider.rotation.y=PI
	return {"viewport":viewport,"scene":scene,"rider":rider,"gate":gate,"mode":mode}
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
