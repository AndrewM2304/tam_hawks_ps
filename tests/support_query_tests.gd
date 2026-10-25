extends RefCounted
## Regressions for independently found broad-grid mismatches. Actual native
## collision rays, not the query implementation itself, decide contact height.
const Surface = preload("res://game/levels/outdoors/surface_builder.gd")

static func run(world: Node3D,check: Callable) -> void:
 await world.get_tree().physics_frame
 await world.get_tree().process_frame
 var space:=world.get_world_3d().direct_space_state
 for fixture: Dictionary in [
  {"name":"gallery riser seam","xz":Vector2(-2,-8),"height":1.0},
  {"name":"gallery first step end","xz":Vector2(2,-4),"height":0.0},
  {"name":"civic first step end","xz":Vector2(-6,-102),"height":4.0},
  {"name":"market street maximum X shoulder","xz":Vector2(50,-16),"height":0.0},
  {"name":"platform maximum Z with lower concourse","xz":Vector2(-99,-5),"height":2.0},
  {"name":"yard flush floor beyond the retained route ribbon","xz":Vector2(49,135),"height":2.0},
  {"name":"park hip actual sloping triangle","xz":Vector2(-227,-85),"height":8.852535},
  # PT24-07 removes the old35cm/25cm depressed shoulders. Independent
  # native rays establish these new grass supports at the same fixed XZ.
  {"name":"park port beside actual ribbon end","xz":Vector2(-147.856979,.915257),"height":2.0003},
  {"name":"civic park port exact start cap","xz":Vector2(-42.087341,-119.001274),"height":5.98},
  {"name":"Clyde approach shared triangle diagonal","xz":Vector2(94.7650556628,47.6473132093),"height":1.0}
 ]:
  var at:=Vector3(fixture.xz.x,fixture.height,fixture.xz.y)
  var queried: float=world.get_ground_height(at)
  var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.25,at-Vector3.UP*.4,1))
  check.call(not hit.is_empty() and absf(queried-hit.position.y)<.025 and absf(queried-float(fixture.height))<.025,"support query: matches real collision at "+fixture.name)
 # Keep both real levels: resolving a maximum edge must not collapse the low
 # station passage onto the suspended high deck, or erase the upper surface.
 var low: float=world.get_support_height(Vector3(-114,2,-8),.3)
 var high: float=world.get_ground_height(Vector3(-114,5,-8))
 check.call(absf(low-2)<.001 and absf(high-5)<.001,"support query: height-aware station lower and upper levels remain distinct")
 check.call(is_finite(world.get_ground_height(Vector3(35,6,-127.8))),"support query: isolated exposed outside corners remain available to retained boundaries")
 # The ribbon's public query must follow its actual paired triangle geometry;
 # no radial centreline expansion may invent support beyond a bent corner.
 var points:=PackedVector3Array([Vector3(0,0,0),Vector3(0,2,-4),Vector3(4,4,-4)])
 var arrays: Array=Surface._strip_arrays(points,2.0)
 var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
 var outside:=Vector2(-.9,-4.1)
 var radial: Dictionary=Surface.nearest_segment(points,outside)
 check.call(float(radial.distance)<1.0 and is_nan(Surface.strip_height(vertices,outside)),"support query: a centreline-radius false positive stays outside the actual bent ribbon")
 var a:=vertices[0]
 var b:=vertices[1]
 var c:=vertices[2]
 var centroid: Vector3=(a+b+c)/3
 check.call(absf(Surface.strip_height(vertices,Vector2(centroid.x,centroid.z))-centroid.y)<.00001,"support query: graded triangle interior interpolates its actual plane")

 # Internal diagonals must stay included while the exact exterior cap belongs
 # to adjoining support. Millimetre-inside/outside probes preserve the footprint.
 var diagonal: Vector3=(vertices[1]+vertices[2])/2
 check.call(absf(Surface.strip_height(vertices,Vector2(diagonal.x,diagonal.z))-diagonal.y)<.00001,"support query: shared ribbon triangle diagonal has no artificial NAN seam")
 check.call(is_nan(Surface.strip_height(vertices,Vector2.ZERO)) and is_finite(Surface.strip_height(vertices,Vector2(0,-.001))) and is_nan(Surface.strip_height(vertices,Vector2(0,.001))),"support query: exterior cap ownership preserves millimetre inside and outside distinction")
