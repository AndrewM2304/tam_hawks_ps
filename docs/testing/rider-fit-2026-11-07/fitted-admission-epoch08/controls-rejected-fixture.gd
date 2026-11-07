extends SceneTree
const Rig=preload("res://game/player/skater_visual.gd")
const Adapter=preload("res://tests/fitted_adapter.gd")
var passes:=0
var failures:Array[String]=[]
var findings:Dictionary={}
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
 if ok:passes+=1;print("PASS ",label)
 else:failures.append(label);print("FAIL ",label)
func _run()->void:
 var root3:=Node3D.new()
 root.add_child(root3)
 var board:=Node3D.new()
 board.position.y=.12
 root3.add_child(board)
 var rider:=Node3D.new()
 root3.add_child(rider)
 var rig:=Rig.new()
 rig.build(board,rider,StandardMaterial3D.new())
 var reference:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fitted-reference.json"))
 var data:Dictionary=Adapter.prepare(rig,reference)
 _check(data.errors.is_empty(),"actual source-authenticated positive11bone mesh/Head/edges")
 if data.errors.is_empty():
  for orphan:bool in [false,true]:
   var head:MeshInstance3D=data.head.mesh
   var original:Mesh=head.mesh
   var changed:=ArrayMesh.new()
   var removed:=0
   var edge:Array=reference.head_edges[0]
   for surface:int in original.get_surface_count():
    var arrays:Array=original.surface_get_arrays(surface)
    var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
    var retained:=PackedInt32Array()
    var mapping:Dictionary=data.head.surfaces[surface].source
    for i:int in range(0,indices.size(),3):
     var sources:Array=[]
     for k:int in 3:sources.append(int(mapping.get(indices[i+k],-1)))
     var omit:bool=sources.has(int(edge[0])) if orphan else (sources.has(int(edge[0])) and sources.has(int(edge[1])))
     if omit:removed+=1
     else:
      for k:int in 3:retained.append(indices[i+k])
    arrays[Mesh.ARRAY_INDEX]=retained
    changed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   head.mesh=changed
   var rejected:Dictionary=Adapter.prepare(rig,reference)
   var label:String="orphan" if orphan else "missing_edge"
   findings[label]={"removed_native_triangles":removed,"errors":rejected.errors,"all_original_vertex_arrays_retained":true}
   _check(removed>0 and not rejected.errors.is_empty(),"actual indexed Head "+label+" fails despite retained matching orphan vertex arrays")
   head.mesh=original
  var chest:MeshInstance3D=data.parts.UpperChest.mesh
  var original:Mesh=chest.mesh
  var clone:=ArrayMesh.new()
  for surface:int in original.get_surface_count():clone.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,original.surface_get_arrays(surface))
  chest.mesh=clone
  var cloned:Dictionary=Adapter.prepare(rig,reference)
  findings.clone_errors=cloned.errors
  _check(cloned.errors.is_empty(),"native buffer reconstruction control preserves source admission before winding change")
  chest.mesh=original
  var flipped:=ArrayMesh.new()
  for surface:int in original.get_surface_count():
   var arrays:Array=original.surface_get_arrays(surface)
   var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
   var first:int=indices[0]
   indices[0]=indices[1]
   indices[1]=first
   arrays[Mesh.ARRAY_INDEX]=indices
   flipped.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  chest.mesh=flipped
  var winding:Dictionary=Adapter.prepare(rig,reference)
  findings.winding_errors=winding.errors
  _check("incomplete native source topology UpperChest" in winding.errors,"actual reversed native triangle winding fails directed source topology")
  chest.mesh=original
  _check(Adapter.prepare(rig,reference).errors.is_empty(),"restored actual native resources authenticate again")
 var output:=FileAccess.open("res://semantic-result.json",FileAccess.WRITE)
 output.store_string(JSON.stringify({"passes":passes,"failures":failures,"findings":findings,"scope":"native source semantic negative controls only, no contact/visual/Main/M5 acceptance"},"\t"));output.close()
 print("SEMANTIC_CONTROL_RESULT passes=",passes," failures=",failures)
 quit(0 if failures.is_empty() else 1)
