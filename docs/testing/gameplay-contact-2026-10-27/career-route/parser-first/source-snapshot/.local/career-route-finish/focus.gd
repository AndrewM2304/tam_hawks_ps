extends SceneTree
const Main=preload("res://game/main.gd")
const Suite=preload("res://tests/career_route_tests.gd")
var passed:=0
var failed:=0
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
 if ok:passed+=1;print("PASS: ",label)
 else:failed+=1;push_error("FAIL: "+label)
func _run()->void:
 var game=Main.new();game.persistence_enabled=false;game.set_meta("pt24_design_preview",false)
 root.add_child(game);game.start_mode(false)
 await _frames(4)
 print("CAREER_CONTEXT legacy=",not bool(game.world.get_meta("pt24_design_preview",true))," personal_persistence=",game.persistence_enabled)
 _preflight(game)
 if not OS.get_cmdline_user_args().has("preflight"):
  await Suite.run(self,game,_check)
 game.queue_free();await process_frame
 print("RESULT: ",passed," passed, ",failed," failed")
 quit(1 if failed else 0)
func _preflight(game:Node)->void:
 var actor:CharacterBody3D=game.skater
 var collision:CollisionShape3D=actor.get_node("BodyCollision")
 var space:PhysicsDirectSpaceState3D=actor.get_world_3d().direct_space_state
 var capsule:CapsuleShape3D=collision.shape as CapsuleShape3D
 var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=actor.collision_mask
 q.exclude=[actor.get_rid()];q.collide_with_areas=false;q.margin=actor.safe_margin
 var blocked_from:=Vector3(106,.02,26)
 q.transform=Transform3D(Basis.IDENTITY,blocked_from)*collision.transform
 q.motion=Vector3(20,0,0)
 var old_fractions:=space.cast_motion(q)
 var old_blocked:bool=old_fractions.size()==2 and old_fractions[0]<1.0
 var rest:Dictionary={}
 if old_blocked:
  q.transform.origin+=Vector3(20,0,0)*float(old_fractions[1]);q.motion=Vector3.ZERO
  rest=space.get_rest_info(q)
 var rail:Node=game.world.find_child("Grind_Rail_Barras",true,false)
 var rail_body:StaticBody3D=rail.get_node("RailProp") if rail!=null else null
 old_blocked=old_blocked and rail_body!=null and rest.get("rid")==rail_body.get_rid()
 _check(old_blocked,"career runway: actual player capsule independently confirms the former direct leg is blocked by newly solid Barras steel")
 var clear:=true
 var witnesses:Array=[]
 var points:=PackedVector3Array([Vector3(106,.02,26),Vector3(106,.02,34),Vector3(126,.02,34),Vector3(126,.02,26)])
 for index:int in points.size()-1:
  for reverse:bool in [false,true]:
   var a:Vector3=points[index+1] if reverse else points[index]
   var b:Vector3=points[index] if reverse else points[index+1]
   q.transform=Transform3D(Basis.IDENTITY,a)*collision.transform;q.motion=b-a
   var fractions:=space.cast_motion(q)
   var segment_clear:bool=fractions.size()==2 and fractions[0]==1.0 and fractions[1]==1.0
   q.transform=Transform3D(Basis.IDENTITY,b)*collision.transform;q.motion=Vector3.ZERO
   var overlaps:=space.intersect_shape(q,1)
   clear=clear and segment_clear and overlaps.is_empty()
   witnesses.append({"index":index,"reverse":reverse,"fractions":fractions,"endpoint_hits":overlaps.size()})
 _check(clear,"career runway: both directions of every finite-end detour segment and endpoint retain actual capsule, original mask and15mm safety shell")
 print("CAREER_RUNWAY ",JSON.stringify({"old_fractions":old_fractions,"old_native_blocker_rid":str(rest.get("rid")),"old_native_normal":str(rest.get("normal")),"new_segments":witnesses,"native_mask":q.collision_mask,"native_margin":q.margin,"capsule_height":capsule.height,"capsule_radius":capsule.radius}))
func _frames(count:int)->void:
 for index:int in count:
  await physics_frame;await process_frame
