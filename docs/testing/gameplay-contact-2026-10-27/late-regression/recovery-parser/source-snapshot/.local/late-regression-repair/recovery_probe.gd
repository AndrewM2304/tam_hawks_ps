extends SceneTree
const Main=preload("res://game/main.gd")
const Regression=preload("res://tests/grind_regression_tests.gd")
var passed:=0
var failed:=0
class Poll extends Node:
	var game:Node
	var tick:=0
	var previous_phase:=""
	var previous_position:=Vector3.INF
	var rows:Array[Dictionary]=[]
	var bail_started:=false
	func _physics_process(_delta:float)->void:
		tick+=1
		if not is_instance_valid(game):return
		var r=game.skater
		if not r.bailing:return
		bail_started=true
		var step:float=r.global_position.distance_to(previous_position) if previous_position.is_finite() else 0.0
		previous_position=r.global_position
		if rows.size()>=60 or (tick%8!=0 and str(r.bail_phase)==previous_phase and step<.3):return
		previous_phase=r.bail_phase
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=r._recovery_shape_query.shape
		query.transform=Transform3D(r.global_basis,r.global_position+Vector3.UP*.875)
		query.motion=r._recovery_shape_query.motion
		query.margin=r._recovery_shape_query.margin
		query.collision_mask=r._recovery_shape_query.collision_mask
		query.exclude=r._recovery_shape_query.exclude
		var space:PhysicsDirectSpaceState3D=r.get_world_3d().direct_space_state
		var hits:Array[Dictionary]=space.intersect_shape(query,8)
		var rest:Dictionary=space.get_rest_info(query)
		var rest_record:Dictionary={}
		if not rest.is_empty():rest_record={"point":str(rest.point),"normal":str(rest.normal),"rid":str(rest.rid),"shape":rest.shape}
		var capsule:CapsuleShape3D=query.shape as CapsuleShape3D
		var details:Array[Dictionary]=[]
		for hit:Dictionary in hits:
			var body:CollisionObject3D=hit.collider
			var index:int=int(hit.shape)
			var owner_id:int=body.shape_find_owner(index)
			var owner:Node=body.shape_owner_get_owner(owner_id)
			var detail:Dictionary={"path":str(body.get_path()),"name":str(body.name),"layer":body.collision_layer,"shape_index":index,"body_transform":str(body.global_transform),"owner":str(owner.get_path()) if owner!=null else ""}
			if owner is CollisionShape3D:
				detail["shape_type"]=owner.shape.get_class()
				detail["shape_transform"]=str(owner.global_transform)
				if owner.shape is BoxShape3D:detail["box_size"]=str(owner.shape.size)
				if owner.shape is CylinderShape3D:detail["radius"]=owner.shape.radius;detail["height"]=owner.shape.height
			details.append(detail)
		query.transform=r.global_transform*r._body_collision.transform;query.margin=0.0;query.motion=Vector3.ZERO
		var body_hits:Array[Dictionary]=space.intersect_shape(query,8)
		var body_names:Array[String]=[]
		for hit:Dictionary in body_hits:body_names.append(str(hit.collider.get_path()))
		var ray:=PhysicsRayQueryParameters3D.create(r.global_position+Vector3.UP*.2,r.global_position-Vector3.UP*1.2,1|8)
		ray.exclude=[r.get_rid()]
		var floor_hit:Dictionary=space.intersect_ray(ray)
		var floor:Dictionary={}
		if not floor_hit.is_empty():floor={"path":str(floor_hit.collider.get_path()),"position":str(floor_hit.position),"normal":str(floor_hit.normal)}
		var slides:Array[Dictionary]=[]
		for i in r.get_slide_collision_count():
			var col:KinematicCollision3D=r.get_slide_collision(i)
			slides.append({"body":str(col.get_collider().get_path()),"position":str(col.get_position()),"normal":str(col.get_normal()),"depth":col.get_depth()})
		var row:Dictionary={"tick":tick,"position":str(r.global_position),"velocity":str(r.velocity),"step":step,"floor":r.is_on_floor(),"bail_phase":str(r.bail_phase),"bail_age":r.bail_elapsed,"phase_age":r._bail_phase_elapsed,"reason":r.bail_reason,"fallback":r._bail_fallback_used,"last_supported":str(r._last_supported_position),"spawn":str(r.spawn_position),"root_basis":str(r.global_basis),"body_local_transform":str(r._body_collision.transform),"shape_type":query.shape.get_class(),"capsule_height":capsule.height if capsule!=null else -1,"capsule_radius":capsule.radius if capsule!=null else -1,"recovery_rest":rest_record,"recovery_mask":r._recovery_shape_query.collision_mask,"recovery_margin":r._recovery_shape_query.margin,"recovery_motion":str(r._recovery_shape_query.motion),"recovery_hits":details,"actual_body_hits":body_names,"native_floor":floor,"slides":slides}
		rows.append(row);print("RECOVERY_NATIVE ",JSON.stringify(row))
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(false)
	var poll:=Poll.new();poll.game=game;poll.process_physics_priority=100;root.add_child(poll)
	await Regression._ground_approach_and_obstruction(self,game,_check)
	var args:=OS.get_cmdline_user_args()
	if args.size()==1:
		var path:String=ProjectSettings.globalize_path(args[0])
		if path.begins_with(ProjectSettings.globalize_path("res://.local/")):
			var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(poll.rows,"  ")+"\n");file.close()
	poll.queue_free();game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
