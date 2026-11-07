extends RefCounted
## PRIVATE complete-shoe cache admission; no skating/physics/visual acceptance.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Footwear=preload("res://game/player/skater_footwear.gd")
const EPSILON:=0.00001 # Independent coordinate reconstruction roundoff, not contact skin.
const POINT_BUDGET:=256
static func run(tree:SceneTree,check:Callable)->void:
 Classic.Setup.register_actions()
 var fixture:Dictionary=await Classic._fixture(tree)
 var rider:CharacterBody3D=fixture.rider
 rider.set_physics_process(false)
 var rig:RefCounted=rider._visual_rig
 var actor:Transform3D=rider.global_transform
 var velocity:Vector3=rider.velocity
 var board:Transform3D=rider._board_visual.global_transform
 var tick:=Engine.get_physics_frames()
 var markers:Array=[]
 var records:Array=[]
 var total_points:=0
 for leg:Dictionary in rig._legs:
  markers.append([leg.foot.global_transform,leg.foot.to_global(Footwear.SOLE_CONTACT),leg.foot.to_global(Footwear.TOE_CONTACT)])
  var actual:PackedVector3Array=_source_points(leg)
  var cached:PackedVector3Array=rig.shoe_support_points(leg)
  var sole:PackedVector3Array=rig.sole_contact_points(leg)
  var enclosure:Dictionary=_enclosure(actual,cached)
  var overhang:Dictionary=_old_sole_overhang(actual,sole,cached)
  check.call(cached.size()>=4 and cached.size()<=POINT_BUDGET and enclosure.enclosed and enclosure.native_source_vertices,
   "full shoe support: compact native3Dhull contains every actual indexed transformed shoe vertex without invented support side="+str(leg.side))
  check.call(overhang.maximum>.009 and overhang.maximum<.010 and overhang.new_agreement<EPSILON,
   "full shoe support: real9.462mm upper overhang rejects the old sole-only wall envelope side="+str(leg.side))
  total_points+=cached.size()
  records.append({"side":leg.side,"source_unique_points":actual.size(),"cached_points":cached.size(),"enclosure":enclosure,"overhang":overhang})
 check.call(total_points*12<=6144,"full shoe support: declared two-leg raw XYZ hull payload stays within6KiB")
 var positive:Dictionary=rig._legs[1]
 var upper:MeshInstance3D=positive.foot.get_node("CanvasUpper")
 var original:Transform3D=upper.transform
 var old:PackedVector3Array=rig.shoe_support_points(positive)
 var plane:Dictionary=records[1].overhang
 var normal:Vector3=plane.normal
 upper.position+=normal*.012
 rig._cache_support_geometry()
 var changed:PackedVector3Array=_source_points(positive)
 var updated:PackedVector3Array=rig.shoe_support_points(positive)
 check.call(_enclosure(changed,updated).enclosed and _max_dot(changed,normal)-_max_dot(old,normal)>.011,
  "full shoe support: transformed actual upper invalidates the old cache while the rebuilt complete envelope follows it")
 upper.transform=original
 rig._cache_support_geometry()
 check.call(_enclosure(_source_points(positive),rig.shoe_support_points(positive)).enclosed,
  "full shoe support: restoring actual geometry restores its complete source envelope")
 var resources_before:=int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
 for iteration:int in 10:rig._cache_support_geometry()
 var resources_after:=int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
 check.call(resources_after-resources_before<=4,"full shoe support: repeated startup-only cache refresh retains no growing temporary shape/mesh resource set")
 var unchanged:bool=rider.global_transform==actor and rider.velocity==velocity and rider._board_visual.global_transform==board and tick==Engine.get_physics_frames()
 for index:int in rig._legs.size():
  var foot:Node3D=rig._legs[index].foot
  unchanged=unchanged and foot.global_transform==markers[index][0] and foot.to_global(Footwear.SOLE_CONTACT)==markers[index][1] and foot.to_global(Footwear.TOE_CONTACT)==markers[index][2]
 check.call(unchanged,"full shoe support: cache construction changes no capsule/body velocity/board/ankle/contact marker or physics time")
 print("FULL_SHOE_SUPPORT_CACHE ",{"legs":records,"raw_hull_XYZ_payload_bytes":total_points*12,"retained_resource_delta_after10refreshes":resources_after-resources_before,"physical_and_markers_unchanged":unchanged,"scope":"source enclosure/resource contract only; no Mac performance or final native skating certificate"})
 await Classic._dispose(tree,fixture)
static func _source_points(leg:Dictionary)->PackedVector3Array:
 var unique:Dictionary={}
 var foot:Node3D=leg.foot
 for mesh:MeshInstance3D in foot.find_children("*","MeshInstance3D",true,false):
  if mesh.mesh==null or not mesh.visible:continue
  for point:Vector3 in mesh.mesh.get_faces():
   # Authored three-mesh shoes are direct children. Keep an independent
   # world-space reconstruction for an adversarial nested/translated mesh.
   var local:Vector3=mesh.transform*point if mesh.get_parent()==foot else foot.to_local(mesh.to_global(point))
   unique[local]=true
 var actual:=PackedVector3Array()
 for point:Vector3 in unique:actual.append(point)
 return actual
static func _enclosure(actual:PackedVector3Array,cached:PackedVector3Array)->Dictionary:
 if actual.is_empty() or cached.size()<4:return {"enclosed":false,"native_source_vertices":false}
 var shape:=ConvexPolygonShape3D.new()
 shape.margin=0.0
 shape.points=cached
 var faces:PackedVector3Array=shape.get_debug_mesh().get_faces()
 var centre:=Vector3.ZERO
 for point:Vector3 in cached:centre+=point
 centre/=cached.size()
 var maximum_outside:=-INF
 for index:int in range(0,faces.size(),3):
  var a:Vector3=faces[index]
  var normal:Vector3=(faces[index+1]-a).cross(faces[index+2]-a)
  if normal.length_squared()<1e-18:continue
  normal=normal.normalized()
  if normal.dot(centre-a)>0:normal=-normal
  for point:Vector3 in actual:maximum_outside=maxf(maximum_outside,normal.dot(point-a))
 var nearest_error:=0.0
 for point:Vector3 in cached:
  var nearest:=INF
  for source:Vector3 in actual:nearest=minf(nearest,point.distance_to(source))
  nearest_error=maxf(nearest_error,nearest)
 return {"enclosed":faces.size()>=12 and maximum_outside<=EPSILON,"native_source_vertices":nearest_error<=EPSILON,"maximum_outside_m":maximum_outside,"maximum_cached_vertex_source_error_m":nearest_error,"native_hull_triangles":faces.size()/3}
static func _max_dot(points:PackedVector3Array,normal:Vector3)->float:
 var value:=-INF
 for point:Vector3 in points:value=maxf(value,point.dot(normal))
 return value
static func _old_sole_overhang(actual:PackedVector3Array,sole:PackedVector3Array,cached:PackedVector3Array)->Dictionary:
 var xz:=PackedVector2Array()
 for point:Vector3 in sole:xz.append(Vector2(point.x,point.z))
 var outline:PackedVector2Array=Geometry2D.convex_hull(xz)
 var centre:=Vector2.ZERO
 for point:Vector2 in outline:centre+=point
 centre/=maxi(1,outline.size())
 var worst:=-INF
 var normal:=Vector3.ZERO
 for index:int in outline.size():
  var edge:Vector2=outline[(index+1)%outline.size()]-outline[index]
  if edge.length_squared()<1e-16:continue
  var outward:=Vector2(edge.y,-edge.x).normalized()
  if outward.dot(outline[index]-centre)<0:outward=-outward
  var axis:=Vector3(outward.x,0,outward.y)
  var overhang:=_max_dot(actual,axis)-_max_dot(sole,axis)
  if overhang>worst:worst=overhang;normal=axis
 return {"maximum":worst,"normal":normal,"new_agreement":absf(_max_dot(actual,normal)-_max_dot(cached,normal)),"classification":"geometric wall support overhang, not wheel load or native collision proof"}
