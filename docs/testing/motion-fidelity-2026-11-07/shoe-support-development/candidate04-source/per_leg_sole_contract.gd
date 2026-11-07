extends RefCounted
## PRIVATE cache-ownership regression. Full native skating contacts stay separate.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Footwear=preload("res://game/player/skater_footwear.gd")
static func run(tree:SceneTree,check:Callable)->void:
 Classic.Setup.register_actions()
 var fixture:Dictionary=await Classic._fixture(tree)
 var rider:CharacterBody3D=fixture.rider
 var rig:RefCounted=rider._visual_rig
 var actor:Transform3D=rider.global_transform
 var velocity:Vector3=rider.velocity
 var board:Transform3D=rider._board_visual.global_transform
 var markers:Array=[]
 for leg:Dictionary in rig._legs:
  markers.append([leg.foot.global_transform,leg.foot.to_global(Footwear.SOLE_CONTACT),leg.foot.to_global(Footwear.TOE_CONTACT)])
  var points:PackedVector3Array=rig.sole_contact_points(leg)
  check.call(_matches_actual_bounds(leg,points),"per-leg sole: complete cached bounds follow this exact native Cupsole mesh and local transform side="+str(leg.side))
 var positive:Dictionary=rig._legs[1]
 var sole:MeshInstance3D=positive.foot.get_node("Cupsole")
 var original:Transform3D=sole.transform
 # Deliberate geometric negative: change only the positive actual mesh's
 # translation by the authored left/right asymmetry scale, not the ankle or
 # contact markers. A shared negative-leg cache now gives the wrong boundary.
 sole.position.x+=.00625
 rig._cache_support_geometry()
 var actual:PackedVector3Array=rig.sole_contact_points(positive)
 check.call(_matches_actual_bounds(positive,actual) and not _matches_actual_bounds(positive,rig.sole_contact_points(rig._legs[0])),
  "per-leg sole: real positive-mesh6.25mm asymmetry rejects the old shared negative-leg boundary")
 var unchanged:bool=rider.global_transform==actor and rider.velocity==velocity and rider._board_visual.global_transform==board
 for index:int in rig._legs.size():
  var foot:Node3D=rig._legs[index].foot
  unchanged=unchanged and foot.global_transform==markers[index][0] \
   and foot.to_global(Footwear.SOLE_CONTACT)==markers[index][1] and foot.to_global(Footwear.TOE_CONTACT)==markers[index][2]
 check.call(unchanged,"per-leg sole: source-cache refresh changes no actor/velocity/board/ankle or public SOLE/TOE marker")
 sole.transform=original
 rig._cache_support_geometry()
 check.call(_matches_actual_bounds(positive,rig.sole_contact_points(positive)),"per-leg sole: restored positive source rebuilds without stale transformed vertices")
 print("PER_LEG_SOLE_CACHE ",{"left_count":rig.sole_contact_points(rig._legs[0]).size(),"right_count":rig.sole_contact_points(positive).size(),"fixture":"explicit positive native mesh translation; no live motion or source-asset substitution","physical_and_markers_unchanged":unchanged})
 await Classic._dispose(tree,fixture)
static func _matches_actual_bounds(leg:Dictionary,points:PackedVector3Array)->bool:
 if points.is_empty():return false
 var low:=Vector3.INF
 var high:=-Vector3.INF
 for point:Vector3 in points:
  if not point.is_finite():return false
  low=low.min(point)
  high=high.max(point)
 var sole:MeshInstance3D=leg.foot.get_node("Cupsole")
 # Inspect the actual native rendered position/index buffers independently.
 # Importer AABBs can include compression padding or unused vertices.
 var native_low:=Vector3.INF
 var native_high:=-Vector3.INF
 for surface:int in sole.mesh.get_surface_count():
  var arrays:Array=sole.mesh.surface_get_arrays(surface)
  var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
  if indices.is_empty():
   for point:Vector3 in vertices:
    var at:Vector3=sole.transform*point
    native_low=native_low.min(at);native_high=native_high.max(at)
  else:
   for index:int in indices:
    var at:Vector3=sole.transform*vertices[index]
    native_low=native_low.min(at);native_high=native_high.max(at)
 return low.distance_to(native_low)<.000001 and high.distance_to(native_high)<.000001
