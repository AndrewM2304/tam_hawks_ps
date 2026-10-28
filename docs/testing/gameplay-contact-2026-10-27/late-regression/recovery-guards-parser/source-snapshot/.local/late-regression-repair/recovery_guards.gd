extends SceneTree
## Declared native contact fixtures; these are guard tests, not played routes.
const Main=preload("res://game/main.gd")
const Regression=preload("res://tests/grind_regression_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(false)
	await Regression._ground_approach_and_obstruction(self,game,_check)
	for kind:String in ["clear","foreign_2mm","embedded_body","no_support"]:
		var r=game.skater
		r.set_physics_process(true);r.spawn_position=Vector3(12,1.1,7);game.start_mode(false);await _frames(40)
		r.set_physics_process(false);r.begin_bail("native_clearance_guard");r.bail_phase="slide";r._bail_phase_elapsed=.16;r.speed=0.0
		var at:Vector3=r.global_position
		var nodes:Array[Node]=[]
		nodes.append(_box(game,at+Vector3(0,1,-.29064),Vector3(4,4,.02),"SideShellWall"))
		if kind=="foreign_2mm":nodes.append(_box(game,at+Vector3(0,1,.2825),Vector3(4,4,.002),"Foreign2mmSlab"))
		if kind=="embedded_body":nodes.append(_box(game,at+Vector3(0,.001,0),Vector3(1,.004,1),"EmbeddedFootPlate"))
		await _frames(2)
		var disabled:Array[Dictionary]=[]
		if kind=="no_support":
			for i in 8:
				var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.2,at-Vector3.UP*r.floor_snap_length,1|8)
				ray.exclude=[r.get_rid()]
				var hit:Dictionary=r.get_world_3d().direct_space_state.intersect_ray(ray)
				if hit.is_empty():break
				var body:CollisionObject3D=hit.collider
				disabled.append({"body":body,"layer":body.collision_layer});body.collision_layer=0
		var q:PhysicsShapeQueryParameters3D=r._recovery_shape_query
		var rayq:PhysicsRayQueryParameters3D=r._recovery_floor_query
		var before:Array=[q.transform,q.motion,q.margin,q.collision_mask,q.exclude.duplicate(),q.shape,rayq.from,rayq.to]
		var moved:bool=r._try_recovery_clearance_step()
		var after:Array=[q.transform,q.motion,q.margin,q.collision_mask,q.exclude.duplicate(),q.shape,rayq.from,rayq.to]
		var distance:float=r.global_position.distance_to(at)
		var correct:bool=moved and distance>.0005 and distance<.00101 if kind=="clear" else not moved and distance==0.0
		_check(correct and before==after,"recovery clearance: native "+kind+" enforces the full shell/path/support and restores query fields")
		print("RECOVERY_GUARD ",{"kind":kind,"moved":moved,"distance":distance,"query_restored":before==after,"floor_flag":r.is_on_floor(),"phase":r.bail_phase,"disabled_supports":disabled.size()})
		for item:Dictionary in disabled:item.body.collision_layer=item.layer
		for node:Node in nodes:node.queue_free()
		await _frames(2)
	game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
func _box(game:Node,at:Vector3,size:Vector3,label:String)->StaticBody3D:
	var body:=StaticBody3D.new();body.name=label;body.position=at;body.collision_layer=1;body.collision_mask=0
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;collision.shape=shape;body.add_child(collision);game.world.add_child(body);return body
func _frames(count:int)->void:
	for i in count:await physics_frame;await process_frame
func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)
