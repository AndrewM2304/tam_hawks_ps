extends "res://tools/full_fidelity_capture.gd"
const Clyde=preload("res://tests/pt24_clyde_flagship_tests.gd")
class ActiveSnapshot extends Node:
	var observed:Node
	var runner
	var authored:=false
	var cylindrical:=false
	var records:Array=[]
	var trajectory:Array=[]
	func _physics_process(_delta:float):
		var rider:CharacterBody3D=observed.skater
		trajectory.append({"tick":Engine.get_physics_frames(),"at":rider.global_transform,"velocity":rider.velocity,"speed":rider.speed,"floor":rider.is_on_floor(),"air":rider.airborne,"bails":observed.bail_count if "bail_count" in observed else -1})
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
class ContactObserver extends Node:
	var observed:Node
	var rows:Array=[]
	var all_model_clear:=true
	var all_rim_gaps_safe:=true
	var queries_leave_state:=true
	var negative_checked:=false
	var negative_rejected:=false
	func _physics_process(_delta:float):
		var rider:CharacterBody3D=observed.skater
		var at:Vector3=rider.global_position
		# Exact original defect envelope before authored bowl attachment; the
		# established curved-surface matrix owns subsequent carving contacts.
		if at.x< -11.2 or at.x> -9.6 or at.z<139.0 or at.z>140.0 or rider._feature_transition.active:return
		if rider.airborne or not rider.is_on_floor():return
		var physical:Transform3D=rider.global_transform
		var velocity:Vector3=rider.velocity
		var frame:Transform3D=rider._board_visual.global_transform
		var tick:=Engine.get_physics_frames()
		var clear:bool=rider._native_rim_frame_clear(frame,0.0)
		all_model_clear=all_model_clear and clear
		var rims:Array=[]
		var loaded:=0
		var unloaded:=0
		var missing:=0
		var space:=rider.get_world_3d().direct_space_state
		for index:int in rider._visual_rig.board_contact_geometry().wheels.size():
			var wheel:Dictionary=rider._visual_rig.board_contact_geometry().wheels[index]
			var minimum:=INF
			var support:Dictionary={}
			for point:Vector3 in wheel.points:
				var world:Vector3=frame*point
				var ray:=PhysicsRayQueryParameters3D.create(world+Vector3.UP*.15,world-Vector3.UP*.35,1|8,[rider.get_rid()])
				var hit:Dictionary=space.intersect_ray(ray)
				if hit.is_empty():continue
				var gap:float=(world-Vector3(hit.position)).dot(hit.normal)
				if gap<minimum:
					minimum=gap
					support={"rid":hit.rid.get_id(),"shape":int(hit.shape),"path":str(hit.collider.get_path()),"position":hit.position,"normal":hit.normal,"tyre_point":world}
			var status:="near_contact"
			if not is_finite(minimum):
				status="no_native_hit_in_bounded_vertex_rays"
				missing+=1
			elif minimum>=.004 and minimum<=.030:
				status="loaded"
				loaded+=1
			elif minimum>.030:
				status="unloaded"
				unloaded+=1
			elif minimum< -.001:
				status="penetration"
				all_rim_gaps_safe=false
			rims.append({"wheel":index,"minimum_gap":minimum if is_finite(minimum) else null,"classification":status,"support":support})
		if not negative_checked:
			negative_checked=true
			var old:=Transform3D(Basis(Vector3(.139809,-.400391,.905616),Vector3(-.297786,.855257,.424098),Vector3(-.944339,-.328973,.000342)),Vector3(-10.41023,2.108346,139.5383))
			negative_rejected=not rider._manual_model_frame_clear(old)
		queries_leave_state=queries_leave_state and rider.global_transform==physical and rider.velocity==velocity and rider._board_visual.global_transform==frame and Engine.get_physics_frames()==tick
		rows.append({"physics":tick,"actor":physical,"velocity":velocity,"board":frame,"full_native_model_and_four_tyre_volumes_clear":clear,"loaded":loaded,"unloaded":unloaded,"ray_missing":missing,"rims":rims})

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
	var contacts:=ContactObserver.new()
	contacts.observed=game
	contacts.process_physics_priority=210
	root.add_child(contacts)
	await Clyde.run_bank_return(self,game,_check)
	_check(contacts.rows.size()>=4,"researched coping: read-only contact witness covers every actual physics tick through the original defect envelope")
	_check(contacts.all_model_clear and contacts.all_rim_gaps_safe,"researched coping: all actual model components/four tyre volumes and independent native rim gaps remain clear")
	_check(contacts.negative_checked and contacts.negative_rejected,"researched coping: retained actual old deeply tilted model still fails native floor/coping clearance")
	_check(contacts.queries_leave_state,"researched coping: native witness changes no actor transform/velocity/board/time")
	FileAccess.open("res://.local/profile-native-contact.json",FileAccess.WRITE).store_string(JSON.stringify({"rows":contacts.rows,"all_model_clear":contacts.all_model_clear,"rim_gaps_safe":contacts.all_rim_gaps_safe,"negative_rejected":contacts.negative_rejected,"read_only":contacts.queries_leave_state}))
	contacts.free()
	print("CLYDE ACTIVE SNAPSHOT authored=",observer.authored," cylindrical=",observer.cylindrical)
	FileAccess.open("res://.local/clyde-active-snapshots.json",FileAccess.WRITE).store_string(JSON.stringify(observer.records))
	FileAccess.open("res://.local/clyde-trajectory.json",FileAccess.WRITE).store_string(JSON.stringify(observer.trajectory))
	observer.free()
	game.free()
	print("CLYDE CURRENT MAIN RESULT: ",checks-failures," passed, ",failures," failed")
	quit(1 if failures else 0)
