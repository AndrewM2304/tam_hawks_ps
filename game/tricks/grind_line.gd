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

var id: String
var kind: String = "rail"
var curve: Curve3D
var points: PackedVector3Array
var length: float = 0.0
var is_valid: bool = false
var is_loop: bool = false
## Reserved upstream endpoint-link metadata. This project has no rail-link builder yet.
var links: Dictionary = {}


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


func point_at(dist: float) -> Vector3:
	if not is_valid or not is_finite(dist):
		return Vector3.ZERO
	return curve.sample_baked(clampf(dist, 0.0, length))


## Unit direction of travel for increasing `dist`.
func dir_at(dist: float) -> Vector3:
	if not is_valid or not is_finite(dist):
		return Vector3.ZERO
	var bounded: float = clampf(dist, 0.0, length)
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
