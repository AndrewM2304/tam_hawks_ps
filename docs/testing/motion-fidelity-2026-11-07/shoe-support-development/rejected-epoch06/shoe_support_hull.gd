extends RefCounted
## Startup-only source-indexed hull. No physics/debug mesh simplification.
## Vector3 coordinates are native float32 values; all scalar arithmetic below
## uses GDScript float64. Ambiguous orientation signs use error-free expansions.

static func build(points:PackedVector3Array)->Dictionary:
	var result:Dictionary={"valid":false,"indices":PackedInt32Array(),"faces":PackedInt32Array()}
	if points.size()<4:return result
	for point:Vector3 in points:
		if not point.is_finite():return result
	var first:=0
	var second:=0
	for index:int in points.size():
		if points[index].x<points[first].x:first=index
	var maximum:float=-1.0
	for index:int in points.size():
		var value:float=_distance_squared(points[first],points[index])
		if value>maximum:maximum=value;second=index
	if maximum<=0.0:return result
	var third:=first
	maximum=-1.0
	for index:int in points.size():
		var value:float=_cross_squared(points[first],points[second],points[index])
		if value>maximum:maximum=value;third=index
	if maximum<=0.0:return result
	var fourth:=first
	maximum=-1.0
	for index:int in points.size():
		var value:float=absf(_side(points[first],points[second],points[third],points[index]))
		if value>maximum:maximum=value;fourth=index
	if maximum<=0.0:return result
	var centre:Vector3=(points[first]+points[second]+points[third]+points[fourth])*.25
	var faces:Array[PackedInt32Array]=[]
	for face:PackedInt32Array in [PackedInt32Array([first,second,third]),PackedInt32Array([first,fourth,second]),PackedInt32Array([first,third,fourth]),PackedInt32Array([second,fourth,third])]:
		faces.append(_outward(face,points,centre))
	var seeds:Dictionary={first:true,second:true,third:true,fourth:true}
	for index:int in points.size():
		if seeds.has(index):continue
		var visible:Dictionary={}
		for face_index:int in faces.size():
			var face:PackedInt32Array=faces[face_index]
			if _side(points[face[0]],points[face[1]],points[face[2]],points[index])>0.0:visible[face_index]=true
		if visible.is_empty():continue
		var edges:Dictionary={}
		var survivors:Array[PackedInt32Array]=[]
		for face_index:int in faces.size():
			var face:PackedInt32Array=faces[face_index]
			if not visible.has(face_index):survivors.append(face);continue
			for edge_index:int in 3:
				var a:int=face[edge_index]
				var b:int=face[(edge_index+1)%3]
				var key:=Vector2i(mini(a,b),maxi(a,b))
				if edges.has(key):edges.erase(key)
				else:edges[key]=Vector2i(a,b)
		for edge:Vector2i in edges.values():
			var face:=PackedInt32Array([edge.x,edge.y,index])
			if _cross_squared(points[edge.x],points[edge.y],points[index])<=0.0:continue
			survivors.append(_outward(face,points,centre))
		faces=survivors
	var used:Dictionary={}
	for face:PackedInt32Array in faces:
		for index:int in face:used[index]=true
	var indices:=PackedInt32Array()
	var remap:Dictionary={}
	for index:int in used:
		remap[index]=indices.size()
		indices.append(index)
	var packed_faces:=PackedInt32Array()
	for face:PackedInt32Array in faces:
		for index:int in face:packed_faces.append(remap[index])
	result.valid=indices.size()>=4 and packed_faces.size()>=12
	result.indices=indices
	result.faces=packed_faces
	return result

static func _outward(face:PackedInt32Array,points:PackedVector3Array,centre:Vector3)->PackedInt32Array:
	if _side(points[face[0]],points[face[1]],points[face[2]],centre)>0.0:
		var swap:int=face[1];face[1]=face[2];face[2]=swap
	return face

static func _distance_squared(a:Vector3,b:Vector3)->float:
	var x:float=float(b.x)-float(a.x)
	var y:float=float(b.y)-float(a.y)
	var z:float=float(b.z)-float(a.z)
	return x*x+y*y+z*z

static func _cross_squared(a:Vector3,b:Vector3,c:Vector3)->float:
	var bx:float=float(b.x)-float(a.x);var by:float=float(b.y)-float(a.y);var bz:float=float(b.z)-float(a.z)
	var cx:float=float(c.x)-float(a.x);var cy:float=float(c.y)-float(a.y);var cz:float=float(c.z)-float(a.z)
	var x:float=by*cz-bz*cy;var y:float=bz*cx-bx*cz;var z:float=bx*cy-by*cx
	return x*x+y*y+z*z

static func _side(a:Vector3,b:Vector3,c:Vector3,p:Vector3)->float:
	var bx:float=float(b.x)-float(a.x);var by:float=float(b.y)-float(a.y);var bz:float=float(b.z)-float(a.z)
	var cx:float=float(c.x)-float(a.x);var cy:float=float(c.y)-float(a.y);var cz:float=float(c.z)-float(a.z)
	var px:float=float(p.x)-float(a.x);var py:float=float(p.y)-float(a.y);var pz:float=float(p.z)-float(a.z)
	var t0:float=bx*cy*pz;var t1:float=-bx*cz*py;var t2:float=by*cz*px
	var t3:float=-by*cx*pz;var t4:float=bz*cx*py;var t5:float=-bz*cy*px
	var determinant:float=t0+t1+t2+t3+t4+t5
	var permanent:float=absf(t0)+absf(t1)+absf(t2)+absf(t3)+absf(t4)+absf(t5)
	# Conservative forward error filter. Uncertain/coplanar input gets an
	# exact sign, never an enlarged contact tolerance or a joggled vertex.
	if absf(determinant)>permanent*0.000000000000004:return determinant
	var expansion:Array[float]=[]
	for factors:Array in [[bx,cy,pz],[-bx,cz,py],[by,cz,px],[-by,cx,pz],[bz,cx,py],[-bz,cy,px]]:
		var product:Array[float]=_product(factors[0],factors[1])
		for part:float in product:
			for value:float in _product(part,factors[2]):expansion=_grow(expansion,value)
	return expansion[-1] if not expansion.is_empty() else 0.0

static func _product(a:float,b:float)->Array[float]:
	var value:float=a*b
	var split_a:float=134217729.0*a
	var big_a:float=split_a-a
	var high_a:float=split_a-big_a
	var low_a:float=a-high_a
	var split_b:float=134217729.0*b
	var big_b:float=split_b-b
	var high_b:float=split_b-big_b
	var low_b:float=b-high_b
	var error_one:float=value-high_a*high_b
	var error_two:float=error_one-low_a*high_b
	var error_three:float=error_two-high_a*low_b
	var error:float=low_a*low_b-error_three
	return [error,value] if error!=0.0 else [value]

static func _grow(expansion:Array[float],value:float)->Array[float]:
	var result:Array[float]=[]
	var accumulator:float=value
	for part:float in expansion:
		var sum:float=accumulator+part
		var virtual:float=sum-accumulator
		var error:float=(accumulator-(sum-virtual))+(part-virtual)
		if error!=0.0:result.append(error)
		accumulator=sum
	if accumulator!=0.0 or result.is_empty():result.append(accumulator)
	return result
