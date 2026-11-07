extends SceneTree
## Tiny executable typed-return/predicate guard before any fitted Main pilot.
const Hull=preload("res://game/player/shoe_support_hull.gd")
var passes:int=0
var failures:Array[String]=[]
func _initialize()->void:_run.call_deferred()
func _check(ok:bool,label:String)->void:
	if ok:passes+=1
	else:failures.append(label)
	print("PASS " if ok else "FAIL ",label)
func _run()->void:
	var product:Array[float]=Hull._product(1.5,1.25)
	_check(product.size()>0 and product[-1]==1.875,"shoe math: actual typed expansion return executes")
	var grown:Array[float]=Hull._grow(product,0.125)
	_check(grown.size()>0 and grown[-1]==2.0,"shoe math: actual typed expansion sum executes")
	var a:=Vector3.ZERO;var b:=Vector3.RIGHT;var c:=Vector3.UP
	_check(Hull._side(a,b,c,Vector3(0.25,0.25,0.0))==0.0,"shoe math: exact coplanar adaptive path executes")
	_check(Hull._side(a,b,c,Vector3(0.25,0.25,0.00000000001))>0.0,"shoe math: positive subnanometre source side retained")
	_check(Hull._side(a,c,b,Vector3(0.25,0.25,0.00000000001))<0.0,"shoe math: reversed plane reverses exact sign")
	var points:=PackedVector3Array([a,b,c,Vector3.BACK,Vector3(.25,.25,0),Vector3(.25,0,.25),Vector3(0,.25,.25),Vector3(.25,.25,.25)])
	var built:Dictionary=Hull.build(points)
	_check(built.valid and built.indices.size()==4 and built.faces.size()==12,"shoe math: tetra plus coplanar/interior source returns four exact support vertices")
	var exact_sources:bool=true
	for index:int in built.indices:exact_sources=exact_sources and index>=0 and index<4
	_check(exact_sources,"shoe math: retained tetra extrema preserve source index provenance")
	var outside:int=0
	for index:int in range(0,built.faces.size(),3):
		var fa:Vector3=points[built.indices[built.faces[index]]]
		var fb:Vector3=points[built.indices[built.faces[index+1]]]
		var fc:Vector3=points[built.indices[built.faces[index+2]]]
		for point:Vector3 in points:
			if Hull._side(fa,fb,fc,point)>0.0:outside+=1
	_check(outside==0,"shoe math: all actual tetra/interior/coplanar points inside oriented support faces")
	var flat:Dictionary=Hull.build(PackedVector3Array([a,b,c,Vector3(.5,.5,0)]))
	_check(not flat.valid,"shoe math: zero-volume source is refused")
	var malformed:Dictionary=Hull.build(PackedVector3Array([a,b,c,Vector3(NAN,0,1)]))
	_check(not malformed.valid,"shoe math: nonfinite source is refused")
	var extreme:Dictionary=Hull.build(PackedVector3Array([a,b,c,Vector3(1e-30,0,1)]))
	_check(not extreme.valid and not extreme.coordinate_guard.supported and extreme.indices.is_empty(),"shoe math: unsupported finite exponent span earns no compact support authority")
	print("SHOE_MATH_SMOKE ",JSON.stringify({"passes":passes,"failures":failures,"scope":"executable typed math guard only; no fitted native/rendered contact acceptance"}))
	quit(0 if failures.is_empty() else 1)
