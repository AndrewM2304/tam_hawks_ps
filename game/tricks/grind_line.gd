class_name GrindLine
extends RefCounted
# Adapted from TinyBitAdventures/not-pro-skater by Austin Ginder (2026), MIT.
# Upstream commit: d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988
# Source: game/scripts/skater/grind_line.gd
# Full notice in this repository: docs/licences/third-party/not-pro-skater-MIT.txt
# Local changes: validation, duplicate filtering, endpoint tangents, authoring factory.
## A grindable line in world space (rail, ledge edge, coping, curb), backed by a Curve3D.
## Callers supply sampled world-space polylines; a level importer is not included.
## `kind` is one of "rail", "ledge", "coping", "curb".

const BAKE: float = 0.05
const TANGENT_STEP: float = 0.08
const MAX_CONTACT_OFFSET: float = 0.5

var id: String
var kind: String = "rail"
var curve: Curve3D
var points: PackedVector3Array
var length: float = 0.0
var is_valid: bool = false
var is_loop: bool = false
## Reserved upstream endpoint-link metadata. This project has no rail-link builder yet.
var links: Dictionary = {}
## Optional support datum, independent from the unchanged travel guide. Unknown
## legacy geometry must not silently become a certified truck/deck contact.
var contact_verified: bool = false
var contact_source: String = ""
var contact_vertical_offset: float = 0.0
var contact_normal_offset: float = 0.0
## Optional real exposed box side. This is independent of the upward crown
## normal; it permits a board to lean over the edge without moving support.
var contact_edge_outward := Vector3.ZERO
## Native bearing cross-section used only for body travel. A changing-grade
## beam may have this inspected radius without certifying named board contact.
var body_profile_radius := 0.0
var body_profile_source := ""
## Runtime native owners of an inspected finite box-edge support assembly.
## Other guides retain an empty list; matching metadata alone grants no RID.
var native_support_rids: Array[RID] = []
## Explicit finite round bearing; distinct from an exposed planar box edge.
var contact_round_declared := false
var contact_round_radius := 0.0
var contact_round_deck_reveal := 0.0
var contact_round_face_reveal := 0.0
var contact_round_outward := Vector3.ZERO
var contact_round_shape := -1
var _contact_round_body: WeakRef



func _init(p_id: String, p_points: PackedVector3Array, p_kind: String = "") -> void:
	id = p_id
	points = PackedVector3Array()
	kind = p_kind if p_kind != "" else kind_from_id(p_id)
	curve = Curve3D.new()
	curve.bake_interval = BAKE
	if p_points.size() < 2:
		return
	for p in p_points:
		if not p.is_finite():
			return
	for p in p_points:
		if points.is_empty() or points[points.size() - 1].distance_squared_to(p) > 0.000000000001:
			points.append(p)
	if points.size() < 2:
		return
	for p in points:
		curve.add_point(p)
	length = curve.get_baked_length()
	is_valid = is_finite(length) and length > 0.001
	if not is_valid:
		length = 0.0
	is_loop = is_valid and points.size() >= 4 and points[0].distance_to(points[-1]) < 0.001


## Snapshot authored local vertices into world space, including rotation/scale.
## Rebuild the line if its authoring transform changes; distances are world metres.
static func from_local_points(p_id: String, local_points: PackedVector3Array,
		authoring_transform: Transform3D, p_kind: String = "") -> GrindLine:
	var world_points := PackedVector3Array()
	for p in local_points:
		world_points.append(authoring_transform * p)
	return GrindLine.new(p_id, world_points, p_kind)


static func kind_from_id(gid: String) -> String:
	var head: String = gid.trim_prefix("Grind_").split("_")[0].to_lower()
	match head:
		"coping":
			return "coping"
		"ledge", "bench", "funbox":
			return "ledge"
		"curb":
			return "curb"
	return "rail"


## Configure inspected support geometry only. A rejected reconfiguration clears
## earlier metadata so an uncertain replacement cannot retain stale authority.
func configure_contact(vertical_offset: float, normal_offset: float, source: String) -> GrindLine:
	contact_verified = false
	contact_source = ""
	contact_vertical_offset = 0.0
	contact_normal_offset = 0.0
	contact_edge_outward = Vector3.ZERO
	contact_round_declared=false
	contact_round_radius=0.0
	contact_round_deck_reveal=0.0
	contact_round_face_reveal=0.0
	contact_round_outward=Vector3.ZERO
	contact_round_shape=-1
	_contact_round_body=null
	native_support_rids.clear()
	if not is_valid or not is_finite(vertical_offset) or not is_finite(normal_offset) \
			or absf(vertical_offset) > MAX_CONTACT_OFFSET or absf(normal_offset) > MAX_CONTACT_OFFSET \
			or source.strip_edges().is_empty():
		return self
	# A vertical guide has no defined upward side in this contact model. Do not
	# certify an otherwise valid Curve3D merely because its endpoints are finite.
	for index: int in range(points.size() - 1):
		var segment := points[index + 1] - points[index]
		if not segment.is_finite() or Vector2(segment.x, segment.z).length_squared() < 0.000001:
			return self
	# dir_at averages the adjoining directions near a joint. Its radial offset
	# is a real beam/cylinder top only when that normal is constant: a flat path
	# or one straight grade. Do not certify a new surface across changing grades.
	if normal_offset != 0.0 and not _normal_contact_path_supported():
		return self
	contact_vertical_offset = vertical_offset
	contact_normal_offset = normal_offset
	contact_source = source.strip_edges()
	contact_verified = true
	return self


func configure_edge_contact(outward: Vector3) -> GrindLine:
	contact_edge_outward = Vector3.ZERO
	if not contact_verified or not outward.is_finite() or not is_finite(outward.length_squared()) or outward.length_squared()<0.5 \
			or absf(outward.y)>0.000001: return self
	var normal := outward.normalized()
	var tangent := (points[-1]-points[0]).normalized()
	if absf(tangent.y)>0.000001 or absf(normal.dot(tangent))>0.000001:return self
	for index: int in range(points.size()-1):
		var direction := (points[index+1]-points[index]).normalized()
		if direction.dot(tangent)<0.999999 or absf(direction.y)>0.000001:return self
	contact_edge_outward = normal
	return self


func configure_round_contact(radius:float,reveal:float,face_reveal:float,outward:Vector3,
		body:StaticBody3D,shape_index:int) -> GrindLine:
	contact_round_declared=true
	contact_round_radius=0.0
	contact_round_deck_reveal=0.0
	contact_round_face_reveal=0.0
	contact_round_outward=Vector3.ZERO
	contact_round_shape=-1
	_contact_round_body=null
	if not contact_verified or contact_edge_outward!=Vector3.ZERO or points.size()!=2 			or not is_finite(radius) or radius<=0.0 or radius>MAX_CONTACT_OFFSET 			or not is_finite(reveal) or reveal<0.0 or reveal>radius 			or not outward.is_finite() or absf(outward.length_squared()-1.0)>0.00001 			or absf(outward.y)>0.000001 or not is_instance_valid(body):return self
	contact_round_radius=radius
	contact_round_deck_reveal=reveal
	contact_round_face_reveal=face_reveal
	contact_round_outward=outward
	contact_round_shape=shape_index
	_contact_round_body=weakref(body)
	if not round_contact_live():
		contact_round_radius=0.0
		contact_round_deck_reveal=0.0
		contact_round_face_reveal=0.0
		contact_round_outward=Vector3.ZERO
		contact_round_shape=-1
		_contact_round_body=null
		return self
	if not native_support_rids.has(body.get_rid()):native_support_rids.append(body.get_rid())
	return self


func round_contact_live() -> bool:
	if (not contact_round_declared or not contact_verified
			or contact_source!="feature.native_coping_crown" or not is_valid or is_loop
			or contact_edge_outward!=Vector3.ZERO or contact_vertical_offset!=0.0
			or contact_normal_offset!=0.0 or not is_finite(length) or length<=0.001
			or points.size()!=2 or not points[0].is_finite() or not points[1].is_finite()
			or not is_finite(contact_round_radius) or contact_round_radius<=0.0
			or contact_round_radius>MAX_CONTACT_OFFSET or not is_finite(contact_round_deck_reveal)
			or contact_round_deck_reveal<0.0 or contact_round_deck_reveal>contact_round_radius
			or not is_finite(contact_round_face_reveal) or contact_round_face_reveal<0.0
			or contact_round_face_reveal>contact_round_radius or not contact_round_outward.is_finite()
			or absf(contact_round_outward.length_squared()-1.0)>0.00001
			or absf(contact_round_outward.y)>0.000001 or _contact_round_body==null
			or contact_round_shape<0):return false
	var chord:Vector3=points[1]-points[0]
	if not chord.is_finite() or not is_finite(chord.length_squared()) 			or chord.length_squared()<=0.000001 or absf(chord.length()-length)>0.0001:return false
	var raw:Variant=_contact_round_body.get_ref()
	if typeof(raw)!=TYPE_OBJECT or not is_instance_valid(raw):return false
	var body:=raw as StaticBody3D
	if body==null or not body.is_inside_tree():return false
	if not body.has_meta("coping_feature") or not body.has_meta("authored_grind_ids"):return false
	var feature:Variant=body.get_meta("coping_feature")
	if (typeof(feature)!=TYPE_OBJECT or not is_instance_valid(feature) or not feature is Node3D
			or body.get_parent()!=feature or feature.get_node_or_null("NativeSteelCoping")!=body
			or feature.get_script()==null
			or feature.get_script().resource_path!="res://game/levels/transition_feature.gd"
			or not _round_unit_frame(feature.global_transform)):return false
	var ids:Variant=body.get_meta("authored_grind_ids")
	if not (ids is Array or ids is PackedStringArray) or not ids.has(id):return false
	# This exact authored quarter's local+Z is its exposed transition side.
	# Read the live frame directly, avoiding allocating lip/sample dictionaries.
	var outward:Vector3=feature.global_basis*Vector3.BACK
	if not outward.is_finite() or outward.dot(contact_round_outward)<0.999999:return false
	var deck:=feature.get_node_or_null("RearDeck") as StaticBody3D
	if not is_instance_valid(deck) or PhysicsServer3D.body_get_shape_count(deck.get_rid())!=1:return false
	var deck_owner:int=deck.shape_find_owner(0)
	var deck_primitive:Variant=deck.shape_owner_get_owner(deck_owner)
	if (not deck_primitive is CollisionShape3D or not deck_primitive.shape is BoxShape3D
			or deck_primitive.disabled
			or deck_primitive.shape.get_rid()!=PhysicsServer3D.body_get_shape(deck.get_rid(),0)):return false
	var size:Vector3=deck_primitive.shape.size
	if not size.is_finite() or size.x<=0.0 or size.y<=0.0 or size.z<=0.0:return false
	var deck_frame:Transform3D=deck.global_transform*PhysicsServer3D.body_get_shape_transform(deck.get_rid(),0)
	if (not _round_unit_frame(deck_frame) or deck_frame.basis.y.distance_to(Vector3.UP)>0.00001
			or deck_frame.basis.x.distance_to(feature.global_basis.x)>0.00001
			or deck_frame.basis.z.distance_to(feature.global_basis.z)>0.00001):return false
	var half:Vector3=size*.5
	var inverse:Transform3D=deck_frame.affine_inverse()
	for point:Vector3 in points:
		var local:Vector3=inverse*point
		if (not local.is_finite() or absf(absf(local.x)-half.x)>0.0001
				or absf(local.y-half.y-contact_round_deck_reveal)>0.0001
				or absf(local.z-(half.z-contact_round_radius+contact_round_face_reveal))>0.0001):return false
	var rid:RID=body.get_rid()
	if not rid.is_valid() or contact_round_shape>=PhysicsServer3D.body_get_shape_count(rid):return false
	var shape:RID=PhysicsServer3D.body_get_shape(rid,contact_round_shape)
	var primitive_owner:int=body.shape_find_owner(contact_round_shape)
	var primitive:Variant=body.shape_owner_get_owner(primitive_owner)
	if (not primitive is CollisionShape3D or not primitive.shape is CylinderShape3D
			or primitive.disabled or primitive.shape.get_rid()!=shape):return false
	if PhysicsServer3D.shape_get_type(shape)!=PhysicsServer3D.SHAPE_CYLINDER:return false
	var data:Variant=PhysicsServer3D.shape_get_data(shape)
	if (not data is Dictionary or not data.has_all(["radius","height"])
			or not is_finite(float(data.radius))
			or absf(float(data.radius)-contact_round_radius)>0.000001):return false
	var frame:Transform3D=body.global_transform*PhysicsServer3D.body_get_shape_transform(rid,contact_round_shape)
	if not _round_unit_frame(frame):return false
	var tangent:Vector3=chord.normalized()
	if (absf(tangent.y)>0.000001 or absf(absf(tangent.dot(frame.basis.y))-1.0)>0.00001
			or absf(contact_round_outward.dot(tangent))>0.000001):return false
	var half_height:float=float(data.height)*.5
	if not is_finite(half_height) or half_height<=0.0:return false
	for point:Vector3 in points:
		var centre:Vector3=point-Vector3.UP*contact_round_radius
		var delta:Vector3=centre-frame.origin
		if not delta.is_finite() or absf(absf(delta.dot(frame.basis.y))-half_height)>0.0001 				or delta.slide(frame.basis.y).length()>0.0001:return false
	return true


static func _round_unit_frame(frame:Transform3D) -> bool:
	if not frame.is_finite():return false
	var b:Basis=frame.basis
	var determinant:float=b.determinant()
	return (is_finite(determinant) and absf(determinant-1.0)<=0.00001
		and absf(b.x.length_squared()-1.0)<=0.00001 and absf(b.y.length_squared()-1.0)<=0.00001
		and absf(b.z.length_squared()-1.0)<=0.00001 and absf(b.x.dot(b.y))<=0.00001
		and absf(b.x.dot(b.z))<=0.00001 and absf(b.y.dot(b.z))<=0.00001)


func round_contact_rid() -> RID:
	if not round_contact_live():return RID()
	var raw:Variant=_contact_round_body.get_ref()
	if typeof(raw)!=TYPE_OBJECT or not is_instance_valid(raw):return RID()
	return (raw as StaticBody3D).get_rid()


func configure_body_profile(normal_radius: float,source: String) -> GrindLine:
	body_profile_radius=0.0
	body_profile_source=""
	if not is_valid or not is_finite(normal_radius) or normal_radius<=0.0 \
			or normal_radius>MAX_CONTACT_OFFSET or source.strip_edges().is_empty():return self
	for index: int in range(points.size()-1):
		var segment := points[index+1]-points[index]
		if not segment.is_finite() or Vector2(segment.x,segment.z).length_squared()<0.000001:return self
	body_profile_radius=normal_radius
	body_profile_source=source.strip_edges()
	return self


func _normal_contact_path_supported() -> bool:
	var flat := true
	var straight := true
	var reference := (points[1] - points[0]).normalized()
	for index: int in range(points.size() - 1):
		var direction := (points[index + 1] - points[index]).normalized()
		flat = flat and absf(points[index + 1].y - points[0].y) <= 0.000001
		straight = straight and reference.dot(direction) > 0.0 \
			and reference.cross(direction).length_squared() <= 0.0000000001
	return flat or straight


## The upward radial side of a usable guide, independent of travel direction.
## This follows the same finite-difference tangent as travel; it does not invent
## smooth physical support across a sharp polyline corner.
func contact_up(dist: float) -> Vector3:
	if not is_valid or not is_finite(dist):
		return Vector3.ZERO
	var tangent := dir_at(dist)
	if not tangent.is_finite() or tangent.length_squared() < 0.5:
		return Vector3.ZERO
	var up := Vector3.UP.slide(tangent)
	return up.normalized() if up.is_finite() and up.length_squared() > 0.000001 else Vector3.ZERO


## Existing point_at clamping is retained; loop callers wrap their own distance.
## Unverified guides retain their original travel point without fabricated skin.
func contact_at(dist: float) -> Vector3:
	if not is_valid or not is_finite(dist):
		return Vector3.ZERO
	var at := point_at(dist)
	if not contact_verified or contact_source.is_empty() \
			or not is_finite(contact_vertical_offset) or not is_finite(contact_normal_offset) \
			or absf(contact_vertical_offset) > MAX_CONTACT_OFFSET or absf(contact_normal_offset) > MAX_CONTACT_OFFSET:
		return at
	if contact_normal_offset == 0.0:
		return at + Vector3.UP * contact_vertical_offset
	var up := contact_up(dist)
	if up.length_squared() < 0.5:
		return at
	return at + Vector3.UP * contact_vertical_offset + up * contact_normal_offset


func point_at(dist: float) -> Vector3:
	if not is_valid or not is_finite(dist):
		return Vector3.ZERO
	if points.size()==2:
		# The native two-point bar is exactly this authored segment. Sampling
		# its baked far-origin curve adds unrelated quantized intermediate bends.
		return points[0].lerp(points[1],clampf(dist/length,0.0,1.0))
	return curve.sample_baked(clampf(dist, 0.0, length))


## Unit direction of travel for increasing `dist`.
func dir_at(dist: float) -> Vector3:
	if not is_valid or not is_finite(dist):
		return Vector3.ZERO
	var bounded: float = clampf(dist, 0.0, length)
	if points.size()==2:
		# A two-point native bar has one exact authored direction. Differencing
		# adjacent baked world samples magnifies far-origin float rounding and
		# invents changing normals along this physically straight bearing.
		return (points[1]-points[0]).normalized()
	if is_loop:
		var before := curve.sample_baked(fposmod(bounded - TANGENT_STEP, length))
		var after := curve.sample_baked(fposmod(bounded + TANGENT_STEP, length))
		return (after - before).normalized()
	var a: float = clampf(bounded - TANGENT_STEP, 0.0, length)
	var b: float = clampf(bounded + TANGENT_STEP, 0.0, length)
	if b - a < 0.001:
		return (points[points.size() - 1] - points[0]).normalized()
	return (curve.sample_baked(b) - curve.sample_baked(a)).normalized()


## Closest point on the line to `p`: {dist, point, gap}.
func closest(p: Vector3) -> Dictionary:
	if not is_valid or not p.is_finite():
		return {}
	var off: float = curve.get_closest_offset(p)
	var q: Vector3 = curve.sample_baked(off)
	return {"dist": off, "point": q, "gap": q.distance_to(p)}
