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
