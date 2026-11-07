extends RefCounted
## Original static civic clock: cut-stone bezel, dark dial and brass furniture.
## Design inference from Glasgow civic architecture, never a surveyed building.
const SEGMENTS := 64

static func make() -> Dictionary:
	var stone:=SurfaceTool.new();stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dial:=SurfaceTool.new();dial.begin(Mesh.PRIMITIVE_TRIANGLES)
	var metal:=SurfaceTool.new();metal.begin(Mesh.PRIMITIVE_TRIANGLES)
	# True stepped/recessed collar. No coplanar layers or alpha/transparency pass.
	var profile:Array[Vector2]=[Vector2(1.28,-.025),Vector2(1.34,.025),
		Vector2(1.29,.12),Vector2(1.105,.12),Vector2(1.045,.04)]
	for section:int in profile.size()-1:
		_ring(stone,profile[section],profile[section+1],SEGMENTS)
	_disc(dial,1.045,.038,SEGMENTS)
	_ring(metal,Vector2(.975,.045),Vector2(.995,.045),SEGMENTS)
	# Sixty individually readable marks; long/broad hour marks anchor the dial.
	for minute:int in 60:
		var major:bool=minute%5==0
		var angle:float=TAU*minute/60.0
		var axis:=Vector2(sin(angle),cos(angle));var side:=Vector2(axis.y,-axis.x)
		var length:float=.13 if major else .048;var half_width:float=.021 if major else .008
		var outer:Vector2=axis*.915;var inner:Vector2=axis*(.915-length)
		_quad(metal,Vector3((inner-side*half_width).x,(inner-side*half_width).y,.049),
			Vector3((outer-side*half_width).x,(outer-side*half_width).y,.049),
			Vector3((outer+side*half_width).x,(outer+side*half_width).y,.049),
			Vector3((inner+side*half_width).x,(inner+side*half_width).y,.049),Vector3.BACK)
	# Authored fixed time10:08, no clocks/tick callbacks or script animation.
	_hand(metal,TAU*(10.0+8.0/60.0)/12.0,.53,.058,.058)
	_hand(metal,TAU*8.0/60.0,.77,.033,.065)
	_disc(metal,.07,.074,16)
	var result:Dictionary={}
	for spec:Array in [["stone",stone],["dial",dial],["metal",metal]]:
		var tool:SurfaceTool=spec[1];tool.index();tool.generate_tangents();result[spec[0]]=tool.commit()
	return result

static func _hand(surface:SurfaceTool,angle:float,length:float,width:float,depth:float)->void:
	var axis:=Vector2(sin(angle),cos(angle));var side:=Vector2(axis.y,-axis.x)
	var tip:Vector2=axis*length;var heel:Vector2=-axis*.12
	_quad(surface,Vector3((heel-side*width*.5).x,(heel-side*width*.5).y,depth),
		Vector3((tip-side*width*.16).x,(tip-side*width*.16).y,depth),
		Vector3((tip+side*width*.16).x,(tip+side*width*.16).y,depth),
		Vector3((heel+side*width*.5).x,(heel+side*width*.5).y,depth),Vector3.BACK)

static func _disc(surface:SurfaceTool,radius:float,depth:float,segments:int)->void:
	for i:int in segments:
		var a:float=TAU*i/segments;var b:float=TAU*(i+1)/segments
		_triangle(surface,Vector3(0,0,depth),Vector3(sin(a)*radius,cos(a)*radius,depth),
			Vector3(sin(b)*radius,cos(b)*radius,depth),Vector3.BACK)

static func _ring(surface:SurfaceTool,a:Vector2,b:Vector2,segments:int)->void:
	for i:int in segments:
		var first:float=TAU*i/segments;var second:float=TAU*(i+1)/segments
		var p:=Vector3(sin(first)*a.x,cos(first)*a.x,a.y)
		var q:=Vector3(sin(second)*a.x,cos(second)*a.x,a.y)
		var r:=Vector3(sin(second)*b.x,cos(second)*b.x,b.y)
		var s:=Vector3(sin(first)*b.x,cos(first)*b.x,b.y)
		var normal:Vector3=(q-p).cross(r-p).normalized()
		# Godot front triangles use clockwise winding. Explicitly choose the
		# physically outward normal independently of their clockwise index order.
		var outward:Vector3=Vector3(sin((first+second)*.5),cos((first+second)*.5),0)
		var wanted:Vector3=outward*(b.y-a.y)+Vector3.BACK*(a.x-b.x)
		if normal.dot(wanted)>0:
			_quad(surface,p,s,r,q,wanted.normalized())
		else:_quad(surface,p,q,r,s,wanted.normalized())

static func _quad(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,normal:Vector3)->void:
	_triangle(surface,a,b,c,normal);_triangle(surface,a,c,d,normal)

static func _triangle(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,normal:Vector3)->void:
	var vertices:Array[Vector3]=[a,b,c]
	# Maintain clockwise convention even for mirrored radial profiles.
	if (b-a).cross(c-a).dot(normal)>0:vertices=[a,c,b]
	for point:Vector3 in vertices:
		surface.set_normal(normal);surface.set_uv(Vector2(point.x,point.y));surface.add_vertex(point)
