extends SceneTree
const Ornament=preload("res://game/levels/art/fountain_ornament.gd")
func _initialize()->void:_run.call_deferred()
func _run()->void:
 for name: String in ["FountainPedestal","FountainBowl","FountainCrown"]:
  var mesh:=Ornament.shared_mesh(name)
  var a:=mesh.surface_get_arrays(0)
  var p: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
  var n: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
  var t: PackedFloat32Array=a[Mesh.ARRAY_TANGENT]
  var uv: PackedVector2Array=a[Mesh.ARRAY_TEX_UV]
  var ix: PackedInt32Array=a[Mesh.ARRAY_INDEX]
  var nl:=0.0
  var tl:=0.0
  var dot:=0.0
  var hand:=0.0
  var bad_winding:=0
  var degenerate:=0
  var nonfinite:=0
  var worst:={}
  for i in p.size():
   var tangent:=Vector3(t[i*4],t[i*4+1],t[i*4+2])
   nl=maxf(nl,absf(n[i].length()-1.0))
   tl=maxf(tl,absf(tangent.length()-1.0))
   if absf(tangent.dot(n[i]))>dot:
    dot=absf(tangent.dot(n[i]));worst={"index":i,"normal":n[i],"tangent":tangent,"dot":dot,"hand":t[i*4+3]}
   hand=maxf(hand,absf(absf(t[i*4+3])-1.0))
   nonfinite+=int(not p[i].is_finite() or not n[i].is_finite() or not tangent.is_finite() or not uv[i].is_finite())
  for f in range(0,ix.size(),3):
   var c: Vector3=(p[ix[f+1]]-p[ix[f]]).cross(p[ix[f+2]]-p[ix[f]])
   bad_winding+=int(c.dot(n[ix[f]]+n[ix[f+1]]+n[ix[f+2]])>=0)
   degenerate+=int(c.length_squared()<=.0000000001)
  print("ORNAMENT_ARRAY_DIAGNOSTIC ",{"name":name,"vertices":p.size(),"triangles":ix.size()/3,"format":mesh.surface_get_format(0),"normal_length_error":nl,"tangent_length_error":tl,"orthogonality_error":dot,"handedness_error":hand,"winding_failures":bad_winding,"degenerate":degenerate,"nonfinite":nonfinite,"worst":worst})
 print("ORNAMENT_ARRAY_DIAGNOSTIC complete")
 quit()
