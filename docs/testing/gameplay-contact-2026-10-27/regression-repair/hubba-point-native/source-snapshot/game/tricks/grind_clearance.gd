extends RefCounted
## Cached actual-model convex pieces. Native queries include ordinary world,
## rail-only steel and moving platforms; only the rider itself is excluded.

const Style = preload("res://game/tricks/grind_style.gd")
const WELD_SCALE := 1000000.0
const MAX_SWEEP_STEPS := 256
const ANGULAR_SKIN := Style.CONTACT_TOLERANCE * 0.45
const MAX_PATH_REFINEMENT_DEPTH := 8
const MAX_PATH_QUERIES := 8192
var ready := false
var component_count: int:
	get: return _parts.size()
var last_rejection := "unconfigured"
var last_obstruction: Dictionary = {}
var last_path_queries := 0
var last_path_subdivisions := 0
var last_path_max_depth := 0
var last_path_budget_exhausted := false
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
	if not ready or not _rigid(frame.basis) or not frame.origin.is_finite() \
			or not support_up.is_finite() or support_up.length_squared()<0.5:
		last_rejection = "invalid_frame_or_model"
		return false
	_query.margin = 0.0
	_query.transform = frame
	_query.transform.origin += support_up.normalized()*Style.CONTACT_TOLERANCE
	for part: Dictionary in _parts:
		_query.shape = part.shape
		if not _space.intersect_shape(_query,1).is_empty():
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
	var hits:=_space.intersect_shape(_query,1)
	_query.margin=0.0
	if hits.is_empty():return true
	last_obstruction=hits[0].duplicate()
	last_obstruction["frame"]=first
	last_obstruction["component"]=index
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
	var hits:=_space.intersect_shape(_query,1)
	if hits.is_empty():return true
	last_obstruction=hits[0].duplicate()
	last_obstruction["frame"]=frame
	last_obstruction["component"]=index
	last_obstruction["static_endpoint"]=true
	return false


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
