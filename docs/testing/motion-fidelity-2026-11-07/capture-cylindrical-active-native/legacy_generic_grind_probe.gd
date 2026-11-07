extends SceneTree
## PRIVATE diagnostic: four declared airborne starts, then mapped Grind only.
## A convex query hit alone is not a material penetration certificate.
const Main=preload("res://game/main.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Style=preload("res://game/tricks/grind_style.gd")
const TARGETS=[
 "Grind_Edge_StreetBenchSeat_x2900y0z2700_0_0",
 "Grind_Edge_Planter_x-2900y40z1300_0_0",
 "Grind_Edge_MarketCounter_x10800y60z200_0_0",
 "clyde_bridge_rail",
]
class NativeObserver extends Node:
 var rider:CharacterBody3D
 var armed:=false
 var rows:Array=[]
 var shape_query:=PhysicsShapeQueryParameters3D.new()
 func _physics_process(_delta:float)->void:
  if not armed or not rider.grinding:return
  var state:Transform3D=rider.global_transform
  var velocity:Vector3=rider.velocity
  var frame:Transform3D=rider._board_visual.global_transform
  var tick:=Engine.get_physics_frames()
  var space:=rider.get_world_3d().direct_space_state
  shape_query.transform=frame
  shape_query.motion=Vector3.ZERO
  shape_query.margin=0.0
  shape_query.collision_mask=1|2|8
  shape_query.exclude=[rider.get_rid()]
  var hits:Array=[]
  var bodies:Dictionary={}
  var saturated:=false
  for index:int in rider._grind_clearance._parts.size():
   shape_query.shape=rider._grind_clearance._parts[index].shape
   var found:=space.intersect_shape(shape_query,16)
   saturated=saturated or found.size()==16
   for hit:Dictionary in found:
    hits.append({"component":index,"rid":hit.rid.get_id(),"shape":int(hit.shape),"path":str(hit.collider.get_path())})
    bodies[str(hit.rid.get_id())+":"+str(int(hit.shape))]=hit
  var material:Array=[]
  for hit:Dictionary in bodies.values():
   var owner:=hit.collider as CollisionObject3D
   var native:=_native_shape(owner,int(hit.shape))
   if native.is_empty():continue
   var maximum:=0.0
   var inside:=0
   var worst:Dictionary={}
   for mesh:MeshInstance3D in rider._visual_rig._board_meshes:
    var unique:Dictionary={}
    for point:Vector3 in mesh.mesh.get_faces():unique[point]=true
    for point:Vector3 in unique:
     var world:=mesh.to_global(point)
     var depth:=_inside_depth(native,world)
     if depth<=0.001:continue
     inside+=1
     if depth>maximum:
      maximum=depth
      worst={"world":world,"source_point":point,"mesh":str(mesh.get_path())}
   material.append({"rid":hit.rid.get_id(),"shape":int(hit.shape),"path":str(owner.get_path()),
    "native_type":native.shape.get_class(),"native_transform":native.transform,
    "unique_drawn_vertices_inside_by_over1mm":inside,"maximum_depth_m":maximum,"worst":worst})
  var bearings:Array=[]
  # These two public datums are audited against the original GLB hanger.
  # Record signed AND vertical gap; neither measures physical wheel force.
  for end:float in [-1.0,1.0]:
   var at:Vector3=frame*Vector3(0,Style.TRUCK_UNDERSIDE,end*Style.TRUCK_HALF_SPAN)
   bearings.append(_native_vertical_gap(space,at))
  var rims:Array=[]
  for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
   var best:Dictionary={}
   for point:Vector3 in wheel.points:
    var gap:=_native_vertical_gap(space,frame*point)
    if gap.get("hit",false) and (best.is_empty() or float(gap.signed_gap)<float(best.signed_gap)):best=gap
   rims.append(best if not best.is_empty() else {"hit":false,"unknown":"no native hit in bounded vertex rays"})
  rows.append({"physics":tick,"actor":state,"velocity":velocity,"board":frame,
   "captured_id":str(rider._grind.line.id),"style":rider.grind_style_id,"contact_verified":rider._grind.line.contact_verified,
   "ready_component_count":rider._grind_clearance._parts.size(),"native_component_hits":hits,
   "hit_buffer_saturated_unknown":saturated,"drawn_material_tests":material,
   "native_hanger_bearing_gap_samples":bearings,"native_tyre_vertex_minimum_gap_samples":rims,
   "queries_read_only":rider.global_transform==state and rider.velocity==velocity and rider._board_visual.global_transform==frame and tick==Engine.get_physics_frames()})
 func _native_vertical_gap(space:PhysicsDirectSpaceState3D,point:Vector3)->Dictionary:
  var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.15,point-Vector3.UP*.35,1|2|8,[rider.get_rid()])
  var hit:=space.intersect_ray(ray)
  if hit.is_empty():return {"hit":false,"point":point,"unknown":"no native hit in bounded ray"}
  return {"hit":true,"point":point,"native_point":hit.position,"native_normal":hit.normal,
   "signed_gap":(point-Vector3(hit.position)).dot(hit.normal),"vertical_gap":point.y-Vector3(hit.position).y,
   "rid":hit.rid.get_id(),"shape":int(hit.shape),"path":str(hit.collider.get_path())}
 func _native_shape(body:CollisionObject3D,index:int)->Dictionary:
  if not is_instance_valid(body) or index<0 or index>=PhysicsServer3D.body_get_shape_count(body.get_rid()):return {}
  var identity:=body.shape_find_owner(index)
  if body.is_shape_owner_disabled(identity):return {}
  var frame:Transform3D=body.global_transform*body.shape_owner_get_transform(identity)
  if not frame.origin.is_finite() or not frame.basis.is_finite() or absf(frame.basis.determinant()-1.0)>0.00001 \
    or not frame.basis.is_equal_approx(frame.basis.orthonormalized()):return {}
  for local:int in body.shape_owner_get_shape_count(identity):
   if body.shape_owner_get_shape_index(identity,local)==index:
    var shape:Shape3D=body.shape_owner_get_shape(identity,local)
    if shape is BoxShape3D or shape is CylinderShape3D:return {"shape":shape,"transform":frame}
  return {}
 func _inside_depth(native:Dictionary,world:Vector3)->float:
  var at:Vector3=native.transform.affine_inverse()*world
  var shape:Shape3D=native.shape
  if shape is BoxShape3D:
   var separation:Vector3=shape.size*.5-at.abs()
   return minf(separation.x,minf(separation.y,separation.z))
  if shape is CylinderShape3D:return minf(shape.radius-Vector2(at.x,at.z).length(),shape.height*.5-absf(at.y))
  return -INF
var cases:Array=[]
func _initialize()->void:_run.call_deferred()
func _frames(count:int)->void:
 for index:int in count:
  await physics_frame
  await process_frame
func _run()->void:
 Classic.Setup.register_actions()
 var game=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 game.start_mode(true)
 var observer:=NativeObserver.new()
 observer.rider=game.skater
 observer.process_physics_priority=210
 root.add_child(observer)
 for identity:String in TARGETS:
  Classic._release()
  game.start_mode(true)
  await _frames(40)
  var line:RefCounted
  for candidate in game.world.get_grind_lines():
   if str(candidate.id)==identity:line=candidate;break
  if line==null:
   cases.append({"requested_id":identity,"available":false})
   continue
  var upper:Vector3=line.points[0]
  var lower:Vector3=line.points[1]
  if upper.y<lower.y:
   upper=line.points[1]
   lower=line.points[0]
  var direction:Vector3=(lower-upper).normalized()
  var begin:Vector3=upper.lerp(lower,.14)+Vector3.UP*.15
  var rider:CharacterBody3D=game.skater
  rider.set_physics_process(false)
  rider.spawn_position=begin
  rider.reset_skater()
  rider.rotation.y=atan2(-direction.x,-direction.z)
  rider.velocity=direction*3.2
  rider.velocity.y=minf(rider.velocity.y,-.6)
  rider.speed=3.2
  rider.airborne=true
  rider.reset_physics_interpolation()
  var initial:={"actor":rider.global_transform,"velocity":rider.velocity,"heading":rider.rotation.y,
   "fixture":"one declared airborne start and momentum; no later actor/velocity/heading writes"}
  var bails_before:int=game.bail_count
  observer.rows=[]
  observer.armed=true
  Input.action_press("grind")
  rider.set_physics_process(true)
  var camera:Array=[]
  for frame:int in 24:
   await _frames(1)
   if rider.grinding:camera.append({"physics":Engine.get_physics_frames(),"clear":Density._camera_clear(game)})
  observer.armed=false
  Input.action_release("grind")
  var record:={"requested_id":identity,"available":true,"initial":initial,
   "guide_verified":line.contact_verified,"guide_source":line.contact_source,
   "rows":observer.rows.duplicate(true),"completed_frame_camera":camera,"new_bails":game.bail_count-bails_before}
  cases.append(record)
  print("LEGACY_NATIVE_GRIND ",identity," captured_physics=",observer.rows.size()," camera_samples=",camera.size()," new_bails=",record.new_bails)
 Classic._release()
 observer.free()
 game.free()
 FileAccess.open("res://.local/legacy-generic-grind-native.json",FileAccess.WRITE).store_string(JSON.stringify({"scope":"private bounded representative diagnostics; native query/hull hits are not alone rendered material proof; no full approach/playability/visual/M5 acceptance","cases":cases}))
 print("LEGACY_NATIVE_GRIND_COMPLETE cases=",cases.size())
 quit(0)
