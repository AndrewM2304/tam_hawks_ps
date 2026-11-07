extends RefCounted
## Cached actual-model convex pieces. Native queries include ordinary world,
## rail-only steel and moving platforms; only the rider itself is excluded.

const Style = preload("res://game/tricks/grind_style.gd")
const WELD_SCALE := 1000000.0
const MAX_SWEEP_STEPS := 256
const ANGULAR_SKIN := Style.CONTACT_TOLERANCE * 0.45
const MAX_PATH_REFINEMENT_DEPTH := 8
const MAX_PATH_QUERIES := 8192
const MAX_NATIVE_HITS := 16
const MAX_SUPPORT_CERTIFICATE_VERTICES := 65536
# Conservative floating-point arithmetic allowance, not a physical contact skin.
const SUPPORT_ROUNDOFF_FACTOR := 64.0 * 2.220446049250313e-16
var ready := false
var component_count: int:
	get: return _parts.size()
var last_rejection := "unconfigured"
var last_obstruction: Dictionary = {}
var last_path_queries := 0
var last_path_subdivisions := 0
var last_path_max_depth := 0
var last_path_budget_exhausted := false
var last_support_certificates := 0
var last_support_vertex_tests := 0
var last_support_minimum_gap := INF
var last_support_hit_cap := false
var last_support_vertex_cap := false
## Minimum neutral edge roll for this actual model, derived at startup. The
## caller still proves each final pose against all native solid geometry.
var edge_roll_angle := INF
var _parts: Array[Dictionary] = []
var _space: PhysicsDirectSpaceState3D
var _query := PhysicsShapeQueryParameters3D.new()
var _sweep_shape := ConvexPolygonShape3D.new()
var _radius := 0.0
var model_radius: float:
	get: return _radius if ready else 0.0


func rebuild(board: Node3D, geometry: Dictionary, rider: RID) -> bool:
	ready = false
	edge_roll_angle = INF
	_parts.clear()
	_radius = 0.0
	last_rejection = "missing_model"
	if not is_instance_valid(board) or not board.is_inside_tree() or not rider.is_valid(): return false
	var meshes: Variant = geometry.get("meshes")
	if not meshes is Array or meshes.is_empty(): return false
	var vertices: Array[Vector3] = []
	var parents: Array[int] = []
	var welded := {}
	var board_inverse := board.global_transform.affine_inverse()
	for mesh: Variant in meshes:
		if not mesh is MeshInstance3D or mesh.mesh == null: return false
		var local: Transform3D = board_inverse * mesh.global_transform
		var faces: PackedVector3Array = mesh.mesh.get_faces()
		for face in range(0,faces.size(),3):
			var first := -1
			for corner in 3:
				var point := local * faces[face+corner]
				if not point.is_finite(): return false
				var key := Vector3i(roundi(point.x*WELD_SCALE),roundi(point.y*WELD_SCALE),roundi(point.z*WELD_SCALE))
				var index: int = welded.get(key,-1)
				if index<0:
					index = vertices.size()
					welded[key] = index
					vertices.append(point)
					parents.append(index)
				if first<0: first=index
				else: parents[_root(parents,index)] = _root(parents,first)
	var components := {}
	for index in vertices.size():
		var root := _root(parents,index)
		if not components.has(root): components[root]=[]
		components[root].append(vertices[index])
	for raw: Array in components.values():
		if raw.size()<3: continue
		var points := PackedVector3Array(raw)
		var normal := Vector3.ZERO
		for index in range(2,points.size()):
			normal = (points[index-1]-points[0]).cross(points[index]-points[0])
			if normal.length_squared()>0.000000000001: break
		if normal.length_squared()<=0.000000000001: continue
		normal = normal.normalized()
		var depth := 0.0
		for point: Vector3 in points: depth=maxf(depth,absf((point-points[0]).dot(normal)))
		if depth<0.000001:
			# A rendered decal can be a zero-thickness connected component. A
			# conservative 10-micrometre prism stays inside the bearing tolerance.
			var count := points.size()
			points.resize(count*2)
			for index in count:
				points[count+index]=points[index]-normal*0.000005
				points[index]+=normal*0.000005
		var shape := ConvexPolygonShape3D.new()
		shape.margin = 0.0
		shape.points = points
		var sweep := PackedVector3Array()
		sweep.resize(points.size()*2)
		_parts.append({"points":points,"shape":shape,"sweep":sweep})
		for point: Vector3 in points: _radius=maxf(_radius,point.length())
	if _parts.is_empty(): return false
	var required_roll := 0.0
	for part: Dictionary in _parts:
		for point: Vector3 in part.points:
			var depth := Style.TRUCK_UNDERSIDE-point.y
			if depth<=Style.CONTACT_TOLERANCE:continue
			if absf(point.x)<=Style.CONTACT_TOLERANCE:
				required_roll=INF
				break
			required_roll=maxf(required_roll,atan2(depth,absf(point.x)))
	if required_roll<=Style.BALANCE_ROLL:edge_roll_angle=required_roll
	_space = board.get_world_3d().direct_space_state
	_query.collision_mask = 1 | 2 | 8
	_query.collide_with_areas = false
	_query.exclude = [rider]
	_query.margin = 0.0
	_sweep_shape.margin = 0.0
	ready = true
	last_rejection = ""
	return true


func allows(pose: Style.ContactPose, support_up: Vector3) -> bool:
	if not _valid(pose,support_up): return false
	return allows_frame(pose.board_transform,support_up)


## The same connected native model can verify a grounded presentation fit
## without claiming a named grind or changing the physical player.
func allows_frame(frame: Transform3D, support_up: Vector3) -> bool:
	_reset_support_certificates()
	if not ready or not _rigid(frame.basis) or not frame.origin.is_finite() \
			or not support_up.is_finite() or support_up.length_squared()<0.5:
		last_rejection = "invalid_frame_or_model"
		return false
	_query.margin = 0.0
	_query.transform = frame
	_query.transform.origin += support_up.normalized()*Style.CONTACT_TOLERANCE
	for part: Dictionary in _parts:
		_query.shape = part.shape
		if not _native_volume_clear(part.points,support_up):
			last_rejection = "model_obstruction"
			return false
	last_rejection = ""
	return true


## A convex union of each piece's two endpoint poses encloses its linear chord.
## The exact rotational sagitta encloses the intervening shortest rotation.
## Initial subdivisions keep that margin below half the contact skin. A native
## envelope hit may refine the SAME continuous motion only while both endpoints
## remain clear; both child envelopes must pass, within depth/query caps.
func allows_path(from: Transform3D, to: Style.ContactPose, support_up: Vector3) -> bool:
	if not _valid(to,support_up): return false
	return allows_frame_path(from,to.board_transform,support_up)


## Unweighted transfers have a real model frame without claiming rail contact.
func allows_frame_path(from: Transform3D, to: Transform3D, support_up: Vector3) -> bool:
	last_obstruction.clear()
	last_path_queries=0
	last_path_subdivisions=0
	last_path_max_depth=0
	last_path_budget_exhausted=false
	_reset_support_certificates()
	if not ready or not _rigid(from.basis) or not from.origin.is_finite() \
			or not _rigid(to.basis) or not to.origin.is_finite() \
			or not support_up.is_finite() or support_up.length_squared()<0.5:
		last_rejection = "invalid_frame_or_model"
		return false
	var angle := _rotation_angle(from.basis,to.basis)
	var maximum_angle := 2.0*acos(clampf(1.0-ANGULAR_SKIN/maxf(_radius,ANGULAR_SKIN),-1.0,1.0))
	var steps := maxi(1,ceili(angle/maxf(maximum_angle,0.000001)))
	if steps>MAX_SWEEP_STEPS:
		last_rejection = "unbounded_rotation"
		return false
	var lift := support_up.normalized()*Style.CONTACT_TOLERANCE
	for step in steps:
		var first_fraction:float=float(step)/steps
		var last_fraction:float=float(step+1)/steps
		for index:int in _parts.size():
			if not _part_path_clear(_parts[index],index,from,to,first_fraction,last_fraction,angle,lift,0):
				_query.margin=0.0
				last_rejection="model_path_budget" if last_path_budget_exhausted else "model_path_obstruction"
				return false
	_query.margin=0.0
	last_obstruction.clear()
	last_rejection=""
	return true


func _part_path_clear(part:Dictionary,index:int,from:Transform3D,to:Transform3D,
		first_fraction:float,last_fraction:float,total_angle:float,lift:Vector3,depth:int)->bool:
	last_path_max_depth=maxi(last_path_max_depth,depth)
	# A genuinely stationary ORIGINAL path is exactly the cached model volume;
	# do not manufacture another hull through far-origin inverse round trips.
	if from==to:return _part_frame_clear(part,index,from,lift)
	if not _path_query_available():return false
	# Both endpoints always come from the ORIGINAL interpolation. Refinement
	# never replaces the tested linear translation/shortest rotation by a
	# guide-following arc or modifies the actual board's proposed motion.
	var first:=from.interpolate_with(to,first_fraction)
	var last:=from.interpolate_with(to,last_fraction)
	var inverse:=first.affine_inverse()
	var points:PackedVector3Array=part.points
	var sweep:PackedVector3Array=part.sweep
	for point:int in points.size():
		sweep[point]=points[point]
		sweep[points.size()+point]=inverse*(last*points[point])
	part.sweep=sweep
	_sweep_shape.points=sweep
	_query.shape=_sweep_shape
	_query.transform=first
	_query.transform.origin+=lift
	# The stable sine form retains a positive conservative rotational sagitta
	# even when cos(a) would round to1 for a very small interval.
	var half_sine:=sin(total_angle*(last_fraction-first_fraction)*.25)
	_query.margin=2.0*_radius*half_sine*half_sine
	last_path_queries+=1
	var clear:=_native_volume_clear(sweep,lift)
	_query.margin=0.0
	if clear:return true
	last_obstruction["frame"]=first
	last_obstruction["component"]=index
	if last_support_hit_cap or last_support_vertex_cap:return false
	# A true endpoint overlap remains an immediate refusal. Only a loose
	# continuous envelope with two native-clear endpoints may subdivide.
	if not _part_frame_clear(part,index,first,lift) or not _part_frame_clear(part,index,last,lift):return false
	if depth>=MAX_PATH_REFINEMENT_DEPTH:return false
	var middle:float=(first_fraction+last_fraction)*.5
	if middle<=first_fraction or middle>=last_fraction:return false
	last_path_subdivisions+=1
	# EACH child must independently prove its entire continuous envelope clear.
	# A clear midpoint/sample, depth exhaustion or query cap never grants entry.
	return _part_path_clear(part,index,from,to,first_fraction,middle,total_angle,lift,depth+1) \
		and _part_path_clear(part,index,from,to,middle,last_fraction,total_angle,lift,depth+1)


func _part_frame_clear(part:Dictionary,index:int,frame:Transform3D,lift:Vector3)->bool:
	if not _path_query_available():return false
	_query.shape=part.shape
	_query.transform=frame
	_query.transform.origin+=lift
	_query.margin=0.0
	last_path_queries+=1
	if _native_volume_clear(part.points,lift):return true
	last_obstruction["frame"]=frame
	last_obstruction["component"]=index
	last_obstruction["static_endpoint"]=true
	return false


func _reset_support_certificates()->void:
	last_support_certificates=0
	last_support_vertex_tests=0
	last_support_minimum_gap=INF
	last_support_hit_cap=false
	last_support_vertex_cap=false


func _native_volume_clear(points:PackedVector3Array,normal:Vector3)->bool:
	var hits:=_space.intersect_shape(_query,MAX_NATIVE_HITS)
	if hits.is_empty():return true
	if hits.size()>=MAX_NATIVE_HITS:
		last_support_hit_cap=true
		last_obstruction=hits[0].duplicate()
		last_obstruction["native_hit_cap"]=true
		return false
	# Every reported collision remains present. A strict half-space proof may
	# refine a native numerical/proxy hit; no RID is excluded or skipped.
	for hit:Dictionary in hits:
		if not _separated_single_cylinder(hit,points,normal):
			last_obstruction=hit.duplicate()
			return false
	return true


func _separated_single_cylinder(hit:Dictionary,points:PackedVector3Array,normal:Vector3)->bool:
	var body:Variant=hit.get("collider")
	if not body is StaticBody3D or int(hit.get("shape",-1))!=0 or points.is_empty():return false
	var rid:RID=body.get_rid()
	# TOTAL count1 is intentionally stricter than merely one active shape: an
	# unreported second native shape cannot hide behind a certified first hit.
	if not rid.is_valid() or PhysicsServer3D.body_get_shape_count(rid)!=1:return false
	var shape:RID=PhysicsServer3D.body_get_shape(rid,0)
	if not shape.is_valid() or PhysicsServer3D.shape_get_type(shape)!=PhysicsServer3D.SHAPE_CYLINDER:return false
	var data:Variant=PhysicsServer3D.shape_get_data(shape)
	if not data is Dictionary or not data.has_all(["radius","height"]):return false
	var radius:float=float(data.radius)
	var height:float=float(data.height)
	if not is_finite(radius) or not is_finite(height) or radius<=0.0 or height<=0.0:return false
	var native_body:Transform3D=PhysicsServer3D.body_get_state(rid,PhysicsServer3D.BODY_STATE_TRANSFORM)
	var native_shape:Transform3D=PhysicsServer3D.body_get_shape_transform(rid,0)
	if not native_body.origin.is_finite() or not _rigid(native_body.basis) \
		or not native_shape.origin.is_finite() or not _rigid(native_shape.basis) or not normal.is_finite():return false
	var normal_length:=sqrt(normal.x*normal.x+normal.y*normal.y+normal.z*normal.z)
	if not is_finite(normal_length) or normal_length<=0.0:return false
	# Compose the projection in scalar float64, never a native Transform3D.
	# A small translated child at a distant body can otherwise lose several
	# micrometres before the purported separation proof even begins.
	var nbx:float=_dot64(normal,native_body.basis.x)
	var nby:float=_dot64(normal,native_body.basis.y)
	var nbz:float=_dot64(normal,native_body.basis.z)
	var nx:float=_dot_components64(nbx,nby,nbz,native_shape.basis.x)
	var ny:float=_dot_components64(nbx,nby,nbz,native_shape.basis.y)
	var nz:float=_dot_components64(nbx,nby,nbz,native_shape.basis.z)
	var native_extent:float=height*.5*absf(ny)+radius*sqrt(nx*nx+nz*nz)
	# Use scalar float64 origin-relative arithmetic. A world Vector3 dot or
	# subtraction would first round the tiny separation at far-origin scales.
	var ox:float=float(_query.transform.origin.x)-float(native_body.origin.x)
	var oy:float=float(_query.transform.origin.y)-float(native_body.origin.y)
	var oz:float=float(_query.transform.origin.z)-float(native_body.origin.z)
	var child_projection:float=_dot_components64(nbx,nby,nbz,native_shape.origin)
	var projected_origin:float=ox*normal.x+oy*normal.y+oz*normal.z-child_projection
	var origin_magnitude:float=absf(ox*normal.x)+absf(oy*normal.y)+absf(oz*normal.z) \
		+absf(nbx*native_shape.origin.x)+absf(nby*native_shape.origin.y)+absf(nbz*native_shape.origin.z)
	var qx:float=_dot64(normal,_query.transform.basis.x)
	var qy:float=_dot64(normal,_query.transform.basis.y)
	var qz:float=_dot64(normal,_query.transform.basis.z)
	var margin:float=float(_query.margin)+maxf(0.0,float(_query.shape.margin))
	if not is_finite(margin) or margin<0.0:return false
	var allowance:float=margin*normal_length
	var lower:=INF
	var magnitude:float=origin_magnitude+absf(native_extent)+absf(allowance)
	if last_support_vertex_tests+points.size()>MAX_SUPPORT_CERTIFICATE_VERTICES:
		last_support_vertex_cap=true;last_path_budget_exhausted=true;return false
	for point:Vector3 in points:
		last_support_vertex_tests+=1
		var px:float=qx*point.x
		var py:float=qy*point.y
		var pz:float=qz*point.z
		var projected:float=projected_origin+px+py+pz
		if not is_finite(projected):return false
		lower=minf(lower,projected)
		magnitude=maxf(magnitude,origin_magnitude+absf(px)+absf(py)+absf(pz)+absf(native_extent)+absf(allowance))
	var gap:float=lower-allowance-native_extent
	var arithmetic_bound:float=SUPPORT_ROUNDOFF_FACTOR*maxf(1.0,magnitude)
	if not is_finite(gap) or gap<=arithmetic_bound:return false
	last_support_certificates+=1
	last_support_minimum_gap=minf(last_support_minimum_gap,(gap-arithmetic_bound)/normal_length)
	return true


static func _dot64(first:Vector3,second:Vector3)->float:
	return float(first.x)*float(second.x)+float(first.y)*float(second.y)+float(first.z)*float(second.z)


static func _dot_components64(x:float,y:float,z:float,second:Vector3)->float:
	return x*float(second.x)+y*float(second.y)+z*float(second.z)

func _path_query_available()->bool:
	if last_path_queries<MAX_PATH_QUERIES:return true
	last_path_budget_exhausted=true
	return false


static func _rotation_angle(from:Basis,to:Basis)->float:
	# angle_to uses an acos of a float quaternion dot; tiny real turns can
	# round that dot to1. The relative quaternion's vector retains those turns.
	var relative:=from.get_rotation_quaternion().inverse()*to.get_rotation_quaternion()
	var vector_length:=sqrt(relative.x*relative.x+relative.y*relative.y+relative.z*relative.z)
	return 2.0*atan2(vector_length,absf(relative.w))

func _valid(pose: Style.ContactPose, support_up: Vector3) -> bool:
	if not ready or pose == null or not pose.valid or not pose.board_transform.origin.is_finite() \
			or not _rigid(pose.board_transform.basis) or not support_up.is_finite() or support_up.length_squared()<0.5:
		last_rejection = "invalid_pose_or_model"
		return false
	return true


static func _rigid(basis: Basis) -> bool:
	return basis.is_finite() and absf(basis.determinant()-1.0)<0.00001 \
		and absf(basis.x.length()-1.0)<0.00001 and absf(basis.y.length()-1.0)<0.00001 \
		and absf(basis.z.length()-1.0)<0.00001


static func _root(parents: Array[int], at: int) -> int:
	var root := at
	while parents[root]!=root: root=parents[root]
	while parents[at]!=at:
		var next := parents[at]
		parents[at]=root
		at=next
	return root
