extends RefCounted
## Cached actual-model convex pieces. Native queries include ordinary world,
## rail-only steel and moving platforms; only the rider itself is excluded.

const Style = preload("res://game/tricks/grind_style.gd")
const WELD_SCALE := 1000000.0
const MAX_SWEEP_STEPS := 256
const ANGULAR_SKIN := Style.CONTACT_TOLERANCE * 0.45
var ready := false
var component_count: int:
	get: return _parts.size()
var last_rejection := "unconfigured"
var last_obstruction: Dictionary = {}
var _parts: Array[Dictionary] = []
var _space: PhysicsDirectSpaceState3D
var _query := PhysicsShapeQueryParameters3D.new()
var _sweep_shape := ConvexPolygonShape3D.new()
var _radius := 0.0


func rebuild(board: Node3D, geometry: Dictionary, rider: RID) -> bool:
	ready = false
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
	_query.margin = 0.0
	_query.transform = pose.board_transform
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
## Subdivision keeps that conservative margin below half the contact skin.
func allows_path(from: Transform3D, to: Style.ContactPose, support_up: Vector3) -> bool:
	if not _valid(to,support_up): return false
	return allows_frame_path(from,to.board_transform,support_up)


## Unweighted transfers have a real model frame without claiming rail contact.
func allows_frame_path(from: Transform3D, to: Transform3D, support_up: Vector3) -> bool:
	last_obstruction.clear()
	if not ready or not _rigid(from.basis) or not from.origin.is_finite() \
			or not _rigid(to.basis) or not to.origin.is_finite() \
			or not support_up.is_finite() or support_up.length_squared()<0.5:
		last_rejection = "invalid_frame_or_model"
		return false
	var angle := from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion())
	var maximum_angle := 2.0*acos(clampf(1.0-ANGULAR_SKIN/maxf(_radius,ANGULAR_SKIN),-1.0,1.0))
	var steps := maxi(1,ceili(angle/maxf(maximum_angle,0.000001)))
	if steps>MAX_SWEEP_STEPS:
		last_rejection = "unbounded_rotation"
		return false
	var sagitta := _radius*(1.0-cos(angle/steps*0.5))
	var lift := support_up.normalized()*Style.CONTACT_TOLERANCE
	for step in steps:
		var first := from.interpolate_with(to,float(step)/steps)
		var last := from.interpolate_with(to,float(step+1)/steps)
		var inverse := first.affine_inverse()
		_query.transform = first
		_query.transform.origin += lift
		_query.margin = sagitta
		for part: Dictionary in _parts:
			var points: PackedVector3Array = part.points
			var sweep: PackedVector3Array = part.sweep
			for index in points.size():
				sweep[index] = points[index]
				sweep[points.size()+index] = inverse*(last*points[index])
			part.sweep = sweep
			_sweep_shape.points = sweep
			_query.shape = _sweep_shape
			var hits := _space.intersect_shape(_query,1)
			if not hits.is_empty():
				last_obstruction=hits[0].duplicate()
				last_obstruction["frame"]=first
				_query.margin = 0.0
				last_rejection = "model_path_obstruction"
				return false
	_query.margin = 0.0
	last_rejection = ""
	return true


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
