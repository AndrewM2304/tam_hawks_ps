extends RefCounted
## Collision-backed surface semantics. Generated ledges use the actual box tops;
## decorative meshes never manufacture collision or an invisible skating plane.

const Line = preload("res://game/tricks/grind_line.gd")
const LEDGE_LABELS := ["CourtPlanterSeat", "ClosePocketPlanter", "WorkshopBackSeat",
	"Planter", "QuayBenchSeat", "PrintYardPlanter", "PlinthFoot", "PlinthCrown",
	"PracticeLedge", "PracticeManualPad", "StreetBenchSeat", "StreetBenchBack"]

var lines: Array = []
var _records: Array[Dictionary] = []
var _ordinals: Dictionary = {}
var _world: Node3D
var _authored: Array = []


func build(world: Node3D, authored: Array) -> void:
	_world = world
	_authored = authored
	lines.clear()
	_records.clear()
	_ordinals.clear()
	_visit(world)


func snapshot() -> Dictionary:
	var eligible_walls := 0
	var eligible_ledges := 0
	var exclusions: Dictionary = {}
	for record: Dictionary in _records:
		if record.wallrideable: eligible_walls += 1
		if not record.grind_ids.is_empty(): eligible_ledges += 1
		if not record.wallrideable:
			exclusions[record.wall_reason] = int(exclusions.get(record.wall_reason, 0)) + 1
	return {"version": 1, "collider_count": _records.size(), "wallrideable_count": eligible_walls,
		"ledge_body_count": eligible_ledges, "generated_grind_count": lines.size(),
		"authored_grind_count": _authored.size(), "grind_track_count": _authored.size() + lines.size(),
		"wall_exclusions": exclusions, "surfaces": _records.duplicate(true),
		"visual_exclusions": [
			{"family":"horizon boundary foundations", "reason":"The default static horizon owns exact vertical footing faces below the retained boundary baseline; no added horizontal floor, collision, grind path or playable terrain."},
			{"family":"small upright street containers", "reason":"Accessible bins have matching circular native collision; their narrow round lids do not present a useful finite grind ledge."},
			{"family":"glass, canopy, foliage and ironwork detail", "reason":"Decorative panes, canvas, leaves and open iron bars are not opaque supporting walls."},
			{"family":"terrain-conforming park path edging", "reason":"The shallow stone shoulder shares actual graded collision and supports roll-over access; it is not a raised ledge."}],
		"limits": "An eligibility inventory, not proof every approach is reachable or human-tested. Native collision, capsule sweeps and trick-state gates still control captures."}


func _visit(node: Node) -> void:
	if node is StaticBody3D:
		_record(node)
	for child: Node in node.get_children():
		_visit(child)


func _record(body: StaticBody3D) -> void:
	var label := String(body.get_meta("art_label", String(body.name)))
	var number := int(_ordinals.get(label, 0)) + 1
	_ordinals[label] = number
	var key := label + "_" + str(number)
	var shape_node: CollisionShape3D
	var shape_count := 0
	for child: Node in body.get_children():
		if child is CollisionShape3D and not child.disabled and child.shape != null:
			shape_count += 1
			if shape_node == null: shape_node = child
	if shape_node == null: return
	var box: BoxShape3D = shape_node.shape as BoxShape3D
	var size := box.size if box != null else Vector3.ZERO
	var wall_reason := _wall_reason(body, label, shape_node, size)
	var wall_ok := wall_reason.is_empty()
	body.set_meta("wallrideable", wall_ok)
	body.set_meta("no_wallride", not wall_ok)
	body.set_meta("wallride_exclusion_reason", wall_reason)
	body.set_meta("surface_audit_id", key)
	var grind_ids: Array[String] = []
	if box != null and LEDGE_LABELS.has(label):
		grind_ids = _box_ledges(key, label, shape_node, size)
	var authored_ids: Array[String] = []
	if body.has_meta("authored_grind_ids"):
		for id: String in body.get_meta("authored_grind_ids"): authored_ids.append(id)
	# The default dictionary transitions already tag their actual steel body
	# with one grind_id. Reuse it without introducing a second coping track.
	if body.has_meta("grind_id"):
		var id := str(body.get_meta("grind_id"))
		for track in _authored:
			if track.id == id and not authored_ids.has(id):
				authored_ids.append(id)
				body.set_meta("audit_capture_ids",[id])
	# Native transition coping has its own rail-only collider. Associate that
	# actual steel body with the feature's published track rather than leaving
	# a visibly grindable collider classified as an unassigned prop.
	var coping_feature: Node3D
	if body.has_meta("coping_feature"): coping_feature = body.get_meta("coping_feature")
	if is_instance_valid(coping_feature) and coping_feature.has_method("get_grind_lines"):
		for track in coping_feature.get_grind_lines():
			if not authored_ids.has(track.id): authored_ids.append(track.id)
	grind_ids.append_array(authored_ids)
	body.set_meta("grind_surface_ids", grind_ids.duplicate())
	_records.append({"id": key, "path": String(_world.get_path_to(body)), "label": label,
		"position": body.global_position, "shape_count": shape_count,
		"shape_type": shape_node.shape.get_class(), "box_size": size,
		"collision_layer": body.collision_layer, "wallrideable": wall_ok,
		"wall_reason": "opaque substantial vertical masonry" if wall_ok else wall_reason,
		"grind_ids": grind_ids, "generated_ledge": LEDGE_LABELS.has(label),
		"capture_check_ids": authored_ids.duplicate() if coping_feature != null else body.get_meta("audit_capture_ids", []).duplicate(),
		"grind_reason": "collision-backed exposed top edges" if not grind_ids.is_empty() else _ledge_exclusion(label, body)})


func _wall_reason(body: StaticBody3D, label: String, shape_node: CollisionShape3D, size: Vector3) -> String:
	# Backed masonry may be an authored wallride line while remaining a solid
	# map edge. Only that explicit opt-in proceeds to the ordinary geometry
	# checks; perimeter ironwork and void guards retain their exclusion.
	if body.get_meta("exploration_boundary", false) and not (
			body.get_meta("solid_boundary",false) and body.get_meta("wallrideable",false)
			and not body.get_meta("no_wallride",true)):
		return "retained perimeter iron fence; safety boundary"
	var parent := body.get_parent()
	while parent != _world and parent != null:
		if parent.is_in_group("skate_transitions"): return "quarter-pipe support uses its curved transition state"
		parent = parent.get_parent()
	if body.collision_layer & 1 == 0: return "rail-only collision layer"
	if body.has_meta("transition_feature"): return "quarter-pipe support uses its curved transition state"
	if body.get_meta("no_wallride", false): return String(body.get_meta("wallride_exclusion_reason", "explicit non-wall surface"))
	# Core terrain uses convex prisms for its visible retaining masonry. Mark
	# only prisms with an exposed >=1.6m face beside real lower support; their
	# sloping/horizontal faces remain rejected by the live vertical side probes.
	if body.get_meta("terrain_surface", false) and _has_exposed_retaining_face(body): return ""
	if shape_node.shape is not BoxShape3D: return "terrain, round column or compound fence; no flat opaque wall face"
	if absf(shape_node.global_basis.y.normalized().dot(Vector3.UP)) < 0.995: return "sloping bank or roof; ordinary terrain support"
	var lower := label.to_lower()
	for token: String in ["glass", "awning", "canopy", "roof", "fence", "handrail", "pole", "column", "post", "bench", "seat", "counter"]:
		if lower.contains(token): return "thin prop, open ironwork, furniture or overhead shelter"
	if size.y < 1.6 or maxf(size.x, size.z) < 2.0: return "below 1.6m wall height or 2m face length; low ledge or narrow prop"
	return ""


func _has_exposed_retaining_face(body: StaticBody3D) -> bool:
	var top: PackedVector3Array = body.get_meta("top_polygon_local", PackedVector3Array())
	var bottom := body.to_global(Vector3(0,float(body.get_meta("retaining_bottom_local",0)),0)).y
	for index in top.size():
		var start := body.to_global(top[index])
		var end := body.to_global(top[(index + 1) % top.size()])
		if start.distance_to(end) < 2.0: continue
		if minf(start.y,end.y)-bottom < 1.6: continue
		var across := Vector3(end.z-start.z,0,start.x-end.x).normalized() * 0.7
		var count := maxi(2,ceili(start.distance_to(end)))
		var exposed_run := 0.0
		for sample in count:
			var at := start.lerp(end,(float(sample)+0.5)/count)
			var a: float = _world.get_ground_height(at + across)
			var b: float = _world.get_ground_height(at - across)
			if is_finite(a) and is_finite(b) and at.y-minf(a,b) >= 1.6 and maxf(a,b) <= at.y+0.15:
				exposed_run += start.distance_to(end)/count
				if exposed_run >= 2.0: return true
			else: exposed_run = 0.0
	return false


func _box_ledges(key: String, label: String, shape_node: CollisionShape3D, size: Vector3) -> Array[String]:
	var ids: Array[String] = []
	if absf(shape_node.global_basis.y.normalized().dot(Vector3.UP)) < 0.995: return ids
	# The court's solid seat has a visible 60mm cap projecting 50mm each side.
	var cap := 0.08 if label == "CourtPlanterSeat" else 0.02
	# Court's visible60mm cap is already represented once above the base.
	# Its bearing path then needs the ordinary20mm ledge skin for the actual
	# upright rider capsule and15mm native safe margin, as other ledges do.
	var frame := shape_node.global_transform
	if shape_node.get_parent().has_meta("skate_edge_box_size"):
		size = shape_node.get_parent().get_meta("skate_edge_box_size")
		frame = shape_node.get_parent().global_transform * Transform3D(Basis.IDENTITY,shape_node.get_parent().get_meta("skate_edge_box_center"))
	var half := size * 0.5
	if label == "CourtPlanterSeat":
		half.x += 0.05
		half.z += 0.05
	var corners := PackedVector3Array([
		Vector3(-half.x, half.y + cap, -half.z), Vector3(half.x, half.y + cap, -half.z),
		Vector3(half.x, half.y + cap, half.z), Vector3(-half.x, half.y + cap, half.z)])
	for index in 4:
		var start := frame * corners[index]
		var end := frame * corners[(index + 1) % 4]
		if start.distance_to(end) < 1.2: continue
		var existing := _covering_authored(start, end)
		if not existing.is_empty():
			if not ids.has(existing): ids.append(existing)
			continue
		var id := "Grind_Ledge_" + key + "_" + str(index)
		lines.append(Line.new(id, PackedVector3Array([start, end]), "ledge"))
		ids.append(id)
	return ids


func _covering_authored(start: Vector3, end: Vector3) -> String:
	for line in _authored:
		if line == null or not line.is_valid: continue
		var a: Dictionary = line.closest(start)
		var b: Dictionary = line.closest(end)
		if float(a.gap) < 0.25 and float(b.gap) < 0.25: return line.id
	return ""


func _ledge_exclusion(label: String, body: StaticBody3D) -> String:
	if body.has_meta("grind_exclusion_reason"): return str(body.get_meta("grind_exclusion_reason"))
	if body.get_meta("exploration_boundary", false): return "retained perimeter, not a playable ledge"
	if label.contains("StallCounter"): return "stocked working counter; merchandise and hanging canopy valances obstruct a standing grind"
	if label.contains("Canopy") or label.contains("Awning") or label.contains("Roof"): return "overhead shelter, not a low ledge"
	if label.contains("Foundation"): return "buried retaining foundation; authored skirt edges cover exposed seating"
	if label.contains("Grind_Cat_"): return "dedicated ordered challenge coping track"
	if label.contains("Masonry"): return "dedicated authored seating/coping track"
	return "terrain, wall, support or prop; no unassigned low ledge candidate"
