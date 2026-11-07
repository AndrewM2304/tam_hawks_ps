extends RefCounted
## PRIVATE complete-shoe cache admission; no skating/physics/visual acceptance.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Footwear=preload("res://game/player/skater_footwear.gd")
const EPSILON:=0.00001 # Independent coordinate reconstruction roundoff, not contact skin.
const POINT_BUDGET:=512
const Hull=preload("res://game/player/shoe_support_hull.gd")
static var last_evidence:Dictionary={}
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
   "full shoe support: source-indexed closed hull passes robust enclosure/provenance (independent exact certificate separate) side="+str(leg.side))
  check.call(overhang.maximum>.009 and overhang.maximum<.010 and overhang.new_agreement<EPSILON,
   "full shoe support: real9.462mm upper overhang rejects the old sole-only wall envelope side="+str(leg.side))
  total_points+=cached.size()
  records.append({"side":leg.side,"source_unique_points":actual.size(),"source_triangle_endpoints":_endpoint_count(leg),"cached_points":cached.size(),"enclosure":enclosure,"overhang":overhang,"coordinate_guard":leg.shoe_support_coordinate_guard.duplicate(),"source_coordinates":_coordinates(actual),"support_coordinates":_coordinates(cached),"support_faces":Array(_faces(cached))})
 check.call(total_points*12<=12288,"full shoe support: declared two-leg raw XYZ hull payload stays within12KiB")
 check.call(records[0].source_unique_points<=4096 and records[1].source_unique_points<=4096,"full shoe support: exact per-leg source snapshots fit4096point startup budget")
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
 # Separate adversarial source fixture: an actual indexed triangle with a
 # tiny finite coordinate exceeds the declared exact-difference range.
 # Compact authority must fail; the production cache retains EVERY source
 # endpoint rather than granting an under-enclosing hull or dropping it.
 var extra:=MeshInstance3D.new()
 extra.name="ExtremeExponentSource"
 var extra_mesh:=ArrayMesh.new()
 var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(1e-30,0,.01),Vector3(.01,.01,0),Vector3(0,.01,.01)])
 arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2])
 extra_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 extra.mesh=extra_mesh
 positive.foot.add_child(extra)
 rig._cache_support_geometry()
 var unsupported:PackedVector3Array=_source_points(positive)
 var fallback:PackedVector3Array=rig.shoe_support_points(positive)
 var fallback_set:Dictionary={}
 for point:Vector3 in fallback:fallback_set[point]=true
 var retained_all:bool=unsupported.size()==fallback.size()
 for point:Vector3 in unsupported:retained_all=retained_all and fallback_set.has(point)
 var unsupported_guard:Dictionary=positive.shoe_support_coordinate_guard.duplicate()
 check.call(not unsupported_guard.supported and retained_all and fallback.size()>POINT_BUDGET,
  "full shoe support: unsupported exponent span refuses compact authority and retains every actual source endpoint")
 extra.free()
 rig._cache_support_geometry()
 check.call(positive.shoe_support_coordinate_guard.supported and _enclosure(_source_points(positive),rig.shoe_support_points(positive)).enclosed,
  "full shoe support: removing unsupported source restores freshly proved compact geometry")
 var resources_before:=int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
 for iteration:int in 10:rig._cache_support_geometry()
 var resources_after:=int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
 check.call(resources_after-resources_before<=4,"full shoe support: repeated startup-only cache refresh retains no growing temporary shape/mesh resource set")
 var unchanged:bool=rider.global_transform==actor and rider.velocity==velocity and rider._board_visual.global_transform==board and tick==Engine.get_physics_frames()
 for index:int in rig._legs.size():
  var foot:Node3D=rig._legs[index].foot
  unchanged=unchanged and foot.global_transform==markers[index][0] and foot.to_global(Footwear.SOLE_CONTACT)==markers[index][1] and foot.to_global(Footwear.TOE_CONTACT)==markers[index][2]
 check.call(unchanged,"full shoe support: cache construction changes no capsule/body velocity/board/ankle/contact marker or physics time")
 last_evidence={"schema":2,"legs":records,"extreme_exponent_negative":{"guard":unsupported_guard,"all_source_endpoints_retained":retained_all,"source_unique_points":unsupported.size(),"fallback_support_points":fallback.size()},"raw_hull_XYZ_payload_bytes":total_points*12,"retained_source_XYZ_payload_bytes":int(records[0].source_unique_points+records[1].source_unique_points)*12,"retained_resource_delta_after10refreshes":resources_after-resources_before,"physical_and_markers_unchanged":unchanged,"scope":"source enclosure/resource contract only; independent exact-integer face certificate required; no Mac performance or final native skating certificate"}
 print("FULL_SHOE_SUPPORT_CACHE ",JSON.stringify(last_evidence,"",true,true))
 var certificate:=FileAccess.open("res://.local/shoe-support-certificate.json",FileAccess.WRITE)
 if certificate!=null:certificate.store_string(JSON.stringify(last_evidence,"",true,true))
 await Classic._dispose(tree,fixture)
static func _endpoint_count(leg:Dictionary)->int:
 var count:=0
 for mesh:MeshInstance3D in leg.foot.find_children("*","MeshInstance3D",true,false):
  if mesh.mesh==null or not mesh.visible:continue
  for surface:int in mesh.mesh.get_surface_count():
   var arrays:Array=mesh.mesh.surface_get_arrays(surface)
   var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
   count+=indices.size() if not indices.is_empty() else positions.size()
 return count
static func _source_points(leg:Dictionary)->PackedVector3Array:
 var unique:Dictionary={}
 var foot:Node3D=leg.foot
 for mesh:MeshInstance3D in foot.find_children("*","MeshInstance3D",true,false):
  if mesh.mesh==null or not mesh.visible:continue
  for surface:int in mesh.mesh.get_surface_count():
   var arrays:Array=mesh.mesh.surface_get_arrays(surface)
   var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
   var selected:=PackedVector3Array()
   if indices.is_empty():selected=positions
   else:
    for index:int in indices:selected.append(positions[index])
   for point:Vector3 in selected:
    # Independent direct-child path and world reconstruction for nested meshes.
    var local:Vector3=mesh.transform*point if mesh.get_parent()==foot else foot.to_local(mesh.to_global(point))
    unique[local]=true
 var actual:=PackedVector3Array()
 for point:Vector3 in unique:actual.append(point)
 return actual
static func _faces(points:PackedVector3Array)->PackedInt32Array:
 var hull:Dictionary=Hull.build(points)
 var result:=PackedInt32Array()
 for index:int in hull.faces:result.append(hull.indices[index])
 return result
static func _coordinates(points:PackedVector3Array)->Array:
 var result:Array=[]
 for point:Vector3 in points:result.append([float(point.x),float(point.y),float(point.z)])
 return result
static func _enclosure(actual:PackedVector3Array,cached:PackedVector3Array)->Dictionary:
 if actual.is_empty() or cached.size()<4:return {"enclosed":false,"native_source_vertices":false}
 var hull:Dictionary=Hull.build(cached)
 var faces:PackedInt32Array=hull.faces
 var edges:Dictionary={}
 var outside:=0
 for index:int in range(0,faces.size(),3):
  var a:int=hull.indices[faces[index]]
  var b:int=hull.indices[faces[index+1]]
  var c:int=hull.indices[faces[index+2]]
  for point:Vector3 in actual:
   if Hull._side(cached[a],cached[b],cached[c],point)>0.0:outside+=1
  for edge:Vector2i in [Vector2i(a,b),Vector2i(b,c),Vector2i(c,a)]:edges[edge]=int(edges.get(edge,0))+1
 var manifold:bool=true
 for edge:Vector2i in edges:
  if edges[edge]!=1 or edges.get(Vector2i(edge.y,edge.x),0)!=1:manifold=false
 var actual_set:Dictionary={}
 for point:Vector3 in actual:actual_set[point]=true
 var exact_source:bool=true
 for point:Vector3 in cached:
  if not actual_set.has(point):exact_source=false
 return {"enclosed":hull.valid and outside==0 and manifold,"native_source_vertices":exact_source,"positive_orientation_count":outside,"closed_oriented_manifold":manifold,"triangles":faces.size()/3,"native_debug_mesh_used":false,"independent_exact_certificate_required":true}
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
