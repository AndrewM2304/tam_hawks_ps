extends SceneTree
## Read-only native collision audit. Grid coverage is diagnostic, not a claim
## that every jump/edge has been explored. Run alone after an editor import.

const GRID := 4.0
const TOLERANCE := 0.10
var world: Node3D
var space: PhysicsDirectSpaceState3D
var report := {"schema_version":1,"grid_spacing_m":GRID,"height_tolerance_m":TOLERANCE,
 "samples":0,"supported":0,"solid_occupied":0,"unmapped":0,"hazard":0,
 "support_faults":[],"offset_unmapped":[],"boundary_faults":[],"boundary_crossing_faults":[],
 "regions":{},"route_offset_samples":0,"boundary_samples":0,
 "limits":["Finite terrain is compared with actual layer1 rays; occupied scenery is classified separately using the actual rider capsule.","The4mgrid can miss smaller holes. Route offsets and boundary joins supplement it; ordinary-input traversal/render review remain separate.","NANoutside mappedterrain is not silently a floor failure; inviting route offsets are reported separately, and intentional river water is classified.","This does not certify targetperformance, everypossible aerial or humanplayability."]}

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
 report["recorded_at_utc"]=Time.get_datetime_string_from_system(true)
 report["engine"]=Engine.get_version_info()
 report["source_sha256"]=_source_hashes("res://game/levels")
 report["tool_sha256"]=_hash_file("res://tools/support_audit.gd")
 world=load("res://game/levels/glasgow_square.gd").new()
 root.add_child(world)
 await physics_frame
 await process_frame
 space=world.get_world_3d().direct_space_state
 var regions := {
  "exchange_gallery":Rect2(-50,-56,100,111),
  "george_and_backstreets":Rect2(-94,-142,188,86),
  "central_station":Rect2(-145,-42,95,97),
  "barras_market":Rect2(47,-54,84,109),
  "kelvingrove_and_connectors":Rect2(-255,-225,213,245),
  "clyde_and_southbank":Rect2(-103,45,206,98)}
 for name: String in regions:
  var bounds: Rect2=regions[name]
  var before:=int(report.samples)
  for iz: int in range(ceili(bounds.size.y/GRID)+1):
   for ix: int in range(ceili(bounds.size.x/GRID)+1):
    var x:=minf(bounds.end.x,bounds.position.x+ix*GRID)
    var z:=minf(bounds.end.y,bounds.position.y+iz*GRID)
    var height: float=world.get_ground_height(Vector3(x,0,z))
    _sample(Vector3(x,height,z),"grid:"+name)
  report.regions[name]=int(report.samples)-before
  print("SUPPORT AUDIT region=",name," samples=",report.regions[name])
  await process_frame
 # Highest-terrain queries deliberately cannot represent the lower station
 # passage. Sample nearby support at its actual authored2mheight independently.
 for z: float in [-18,-14,-10,-6,-2,2]:
  for x: float in [-128,-124,-120,-116,-112,-108,-104,-100,-96,-92,-88]:
   var height: float=world.get_support_height(Vector3(x,2,z),0.3)
   _sample(Vector3(x,height,z),"station_lower_layer")
 _route_offsets()
 _boundaries()
 report["source_after_sha256"]=_source_hashes("res://game/levels")
 report["source_changed_during_run"]=report.source_sha256!=report.source_after_sha256
 report["route_count"]=world.get_route_definitions().size()
 report["boundary_count"]=get_nodes_in_group("exploration_boundaries").size()
 report["support_fault_count"]=report.support_faults.size()
 report["offset_unmapped_count"]=report.offset_unmapped.size()
 report["boundary_fault_count"]=report.boundary_faults.size()
 report["boundary_crossing_fault_count"]=report.boundary_crossing_faults.size()
 var args:=OS.get_cmdline_user_args()
 var output:=String(args[0]) if args.size()>0 else "res://.local/support-audit.json"
 if not output.begins_with("res://") and not output.begins_with("/"): output="res://"+output
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
 var file:=FileAccess.open(output,FileAccess.WRITE)
 if file==null:
  push_error("Cannot write support audit receipt: "+output)
  quit(2)
  return
 file.store_string(JSON.stringify(report,"  ")+"\n")
 file.close()
 print("SUPPORT AUDIT samples=%d supported=%d occupied=%d unmapped=%d hazards=%d floor_faults=%d route_unmapped=%d boundary_faults=%d crossing_faults=%d" % [report.samples,report.supported,report.solid_occupied,report.unmapped,report.hazard,report.support_fault_count,report.offset_unmapped_count,report.boundary_fault_count,report.boundary_crossing_fault_count])
 quit(1 if report.support_fault_count+report.boundary_fault_count+report.boundary_crossing_fault_count>0 or report.source_changed_during_run else 0)


func _sample(at: Vector3,context: String) -> void:
 report.samples+=1
 if not is_finite(at.y):
  if at.z>=78 and at.z<=116:
   report.hazard+=1
  else: report.unmapped+=1
  return
 # Lift the contact point a small skin above the expected floor. A capsule
 # inside a real planter/building is occupied ground, not an emptyfloor claim.
 var occupied:=_capsule(at+Vector3.UP*.06)
 if not space.intersect_shape(occupied,1).is_empty():
  report.solid_occupied+=1
  return
 var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.25,at-Vector3.UP*1.5,1)
 var hit:=space.intersect_ray(query)
 if hit.is_empty() or float(hit.position.y)<at.y-TOLERANCE:
  report.support_faults.append({"context":context,"expected":_v(at),"actual":null if hit.is_empty() else _v(hit.position),"normal":null if hit.is_empty() else _v(hit.normal),"collider":"NONE" if hit.is_empty() else String(world.get_path_to(hit.collider))})
 else: report.supported+=1


func _route_offsets() -> void:
 for route: Dictionary in world.get_route_definitions():
  var points: PackedVector3Array=route.points
  for segment: int in range(points.size()-1):
   var a:=points[segment]
   var b:=points[segment+1]
   var direction:=Vector3(b.x-a.x,0,b.z-a.z).normalized()
   var side:=Vector3(direction.z,0,-direction.x)
   var samples:=maxi(1,ceili(a.distance_to(b)/3.0))
   for index: int in range(samples+1):
    var center:=a.lerp(b,float(index)/samples)
    for offset: float in [-3.0,-1.5,0.0,1.5,3.0]:
     var at:=center+side*offset
     var height: float=world.get_support_height(at,0.5)
     report.route_offset_samples+=1
     if not is_finite(height) and not (at.z>=78 and at.z<=116):
      report.offset_unmapped.append({"route":route.id,"point":_v(at),"offset_m":offset,"requires_jump":route.get("requires_jump",false)})
     _sample(Vector3(at.x,height,at.z),"route:"+String(route.id)+" offset="+str(offset))


func _boundaries() -> void:
 for body: StaticBody3D in get_nodes_in_group("exploration_boundaries"):
  var points: PackedVector3Array=body.get_meta("boundary_points")
  var family:=String(body.get_meta("boundary_family",body.name))
  for index: int in range(points.size()-1):
   var a: Vector3=body.to_global(points[index])
   var b: Vector3=body.to_global(points[index+1])
   # Midpoints check panel foundations; endpoints exercise actual nearjoins.
   for fraction: float in [0.0,0.5,1.0]:
    var at:=a.lerp(b,fraction)
    report.boundary_samples+=1
    var floor_query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.3,at-Vector3.UP*.5,1)
    floor_query.exclude=[body.get_rid()]
    var floor:=space.intersect_ray(floor_query)
    if floor.is_empty():
     report.boundary_faults.append({"family":family,"point":_v(at),"fraction":fraction})
    var cross:=Vector3(b.z-a.z,0,a.x-b.x).normalized()
    for sign_value: float in [-1.0,1.0]:
     var from:=at+cross*.65*sign_value
     var to:=at-cross*.65*sign_value
     var from_floor:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from+Vector3.UP*.5,from-Vector3.UP*.8,1))
     if from_floor.is_empty(): continue
     var query:=_capsule(from+Vector3.UP*.04)
     if not space.intersect_shape(query,1).is_empty(): continue
     query.motion=to-from
     var motion:=space.cast_motion(query)
     if motion.size()==2 and motion[0]>.999:
      report.boundary_crossing_faults.append({"family":family,"from":_v(from),"to":_v(to),"fraction":fraction})


func _capsule(at: Vector3) -> PhysicsShapeQueryParameters3D:
 var shape:=CapsuleShape3D.new()
 shape.radius=.28
 shape.height=1.7
 var query:=PhysicsShapeQueryParameters3D.new()
 query.shape=shape
 query.collision_mask=1
 query.margin=.002
 query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*.85)
 return query


func _v(at: Vector3) -> Array:
 return [at.x,at.y,at.z]


func _source_hashes(path: String) -> Dictionary:
 var hashes: Dictionary={}
 var directory:=DirAccess.open(path)
 if directory==null: return hashes
 for name: String in directory.get_files():
  if name.ends_with(".gd") or name.ends_with(".tscn"): hashes[path.path_join(name)]=_hash_file(path.path_join(name))
 for name: String in directory.get_directories(): hashes.merge(_source_hashes(path.path_join(name)))
 return hashes


func _hash_file(path: String) -> String:
 var context:=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(FileAccess.get_file_as_bytes(path))
 return context.finish().hex_encode()
