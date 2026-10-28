extends RefCounted
## Collision-backed surface semantics. Generated ledges use the actual box tops;
## decorative meshes never manufacture collision or an invisible skating plane.

const Line = preload("res://game/tricks/grind_line.gd")
const GrindStyle = preload("res://game/tricks/grind_style.gd")
const LEDGE_LABELS := ["CourtPlanterSeat", "ClosePocketPlanter", "WorkshopBackSeat",
	"Planter", "QuayBenchSeat", "PrintYardPlanter", "PlinthFoot", "PlinthCrown",
	"PracticeLedge", "PracticeManualPad", "StreetBenchSeat", "StreetBenchBack"]

var lines: Array = []
var _records: Array[Dictionary] = []
var _ordinals: Dictionary = {}
var _world: Node3D
var _authored: Array = []
# The named set above preserves old identities/cap exceptions. Ordinary new
# low boxes use actual exposed native tops rather than another name allowlist.
const NATIVE_LEDGE_SKIN := 0.02
const NATIVE_LEDGE_MIN_RUN := 1.2
const NATIVE_LEDGE_MAX_RISE := 2.0
var _ledge_obstacles: Array[AABB] = []
var _ledge_obstacle_shapes: Array[CollisionShape3D] = []
var _ledge_work: Dictionary = {}
var _ledge_ground_rects: Array[Dictionary] = []
var _ledge_pond_bounds := Rect2()
var _ledge_pond_active := false
var _ledge_outdoor: Node3D
var _ledge_outdoor_rects: Array[Dictionary] = []
var _ledge_bowl_bounds: Array[Rect2] = []
var _ledge_flat_supports: Array[Dictionary] = []


func build(world: Node3D, authored: Array) -> void:
	_world = world
	_authored = authored
	lines.clear()
	_records.clear()
	_ordinals.clear()
	var startup_begin := Time.get_ticks_usec()
	_ledge_obstacles.clear()
	_ledge_obstacle_shapes.clear()
	_ledge_flat_supports.clear()
	_ledge_work = {"box_shapes":0,"candidate_edges":0,"intervals":0,"guides":0,"native_space_queries":0,
		"edge_obstacle_tests":0,"interval_obstacle_tests":0,"max_nearby_obstacles":0,"audit_startup_us":0,
		"terrain_screened_edges":0,"outdoor_screened_edges":0,"terrain_query_count":0,"headroom_rejected_intervals":0,
		"shared_native_support_links":0}
	_collect_ledge_terrain_screen()
	_collect_ledge_obstacles(world)
	_visit(world)
	_associate_flat_native_supports()
	_ledge_obstacles.clear()
	_ledge_obstacle_shapes.clear()
	_ledge_flat_supports.clear()
	_ledge_ground_rects.clear()
	_ledge_pond_active = false
	_ledge_outdoor = null
	_ledge_outdoor_rects.clear()
	_ledge_bowl_bounds.clear()
	_ledge_work.audit_startup_us = Time.get_ticks_usec()-startup_begin


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
		"native_ledge_fallback": _ledge_work.duplicate(true),
		"wall_exclusions": exclusions, "surfaces": _records.duplicate(true),
		"visual_exclusions": [
			{"family":"horizon boundary foundations", "reason":"The default static horizon owns exact vertical footing faces below the retained boundary baseline; no added horizontal floor, collision, grind path or playable terrain."},
			{"family":"small upright street containers", "reason":"Accessible bins have matching circular native collision; their narrow round lids do not present a useful finite grind ledge."},
			{"family":"non-colliding panes, canopy, foliage and open ironwork detail", "reason":"Render-only panes, canvas, leaves and open bars do not supply wall contact. Continuous native glass panes share ordinary wall eligibility unless explicitly protected scenery."},
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
	var provider_owned := body.has_meta("skate_edge_provider_ids")
	if provider_owned:
		for id: String in body.get_meta("skate_edge_provider_ids"):grind_ids.append(id)
	elif box != null and LEDGE_LABELS.has(label):
		grind_ids = _box_ledges(key, label, shape_node, size)
	elif body.get_meta("authored_grind_ids",[]).is_empty() and str(body.get_meta("grind_id","")).is_empty() \
			and (not body.has_meta("coping_feature") or not is_instance_valid(body.get_meta("coping_feature"))):
		grind_ids = _native_box_ledges(body,key)
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
		"wall_reason": "continuous substantial native wall" if wall_ok else wall_reason,
		"grind_ids": grind_ids, "generated_ledge": (LEDGE_LABELS.has(label) and (not provider_owned or not grind_ids.is_empty())) or grind_ids.any(func(id: String) -> bool: return id.begins_with("Grind_Ledge_"+key+"_Native_")),
		"capture_check_ids": authored_ids.duplicate() if coping_feature != null else body.get_meta("audit_capture_ids", []).duplicate(),
		"grind_reason": "collision-backed exposed top edges" if not grind_ids.is_empty() else _ledge_exclusion(label, body)})


func _wall_reason(body: StaticBody3D, label: String, shape_node: CollisionShape3D, size: Vector3) -> String:
	# The boundary builder admits only its actual opaque/solid masonry after
	# constructing the finite collision. Ironwork and explicit safety exclusions
	# remain closed to wallrides; property names do not change the stone's use.
	if body.get_meta("exploration_boundary", false):
		var masonry: bool = body.get_meta("solid_boundary",false) or body.get_meta("opaque_boundary",false)
		if masonry and body.get_meta("surface_audio","")=="stone" and body.get_meta("wallrideable",false) \
				and not body.get_meta("no_wallride",true) and body.collision_layer & 1 != 0:
			return ""
		return "retained perimeter iron fence or explicitly excluded boundary"
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
	for token: String in ["awning", "canopy", "roof", "fence", "handrail", "pole", "column", "post", "bench", "seat", "counter"]:
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
	if body.has_meta("skate_edge_provider_ids"): return "semantic edge provider found no clear finite interval; do not recreate a whole edge across its exclusions"
	if body.has_meta("grind_exclusion_reason"): return str(body.get_meta("grind_exclusion_reason"))
	if body.get_meta("exploration_boundary", false): return "retained perimeter, not a playable ledge"
	if label.contains("StallCounter"): return "stocked working counter; merchandise and hanging canopy valances obstruct a standing grind"
	if label.contains("Canopy") or label.contains("Awning") or label.contains("Roof"): return "overhead shelter, not a low ledge"
	if label.contains("Foundation"): return "buried retaining foundation; authored skirt edges cover exposed seating"
	if label.contains("Grind_Cat_"): return "dedicated ordered challenge coping track"
	if label.contains("Masonry"): return "dedicated authored seating/coping track"
	return "terrain, wall, support or prop; no unassigned low ledge candidate"


func _collect_ledge_obstacles(node: Node) -> void:
	if node is StaticBody3D and node.collision_layer & 1 != 0:
		for child: Node in node.get_children():
			if not child is CollisionShape3D or child.disabled: continue
			if child.shape is ConcavePolygonShape3D:
				_collect_flat_native_support(child)
				continue
			var bounds := AABB()
			if child.shape is BoxShape3D:
				bounds = AABB(-child.shape.size*0.5,child.shape.size)
			elif child.shape is CylinderShape3D:
				var shape := child.shape as CylinderShape3D
				var size := Vector3(shape.radius*2.0,shape.height,shape.radius*2.0)
				bounds = AABB(-size*0.5,size)
			elif child.shape is CapsuleShape3D:
				var shape := child.shape as CapsuleShape3D
				var size := Vector3(shape.radius*2.0,shape.height,shape.radius*2.0)
				bounds = AABB(-size*0.5,size)
			elif child.shape is SphereShape3D:
				var shape := child.shape as SphereShape3D
				bounds = AABB(-Vector3.ONE*shape.radius,Vector3.ONE*shape.radius*2.0)
			elif child.shape is ConvexPolygonShape3D:
				var points: PackedVector3Array = child.shape.points
				if points.is_empty(): continue
				bounds = AABB(points[0],Vector3.ZERO)
				for point: Vector3 in points: bounds = bounds.expand(point)
			else: continue
			_ledge_obstacles.append(child.global_transform*bounds)
			_ledge_obstacle_shapes.append(child)
	for child: Node in node.get_children(): _collect_ledge_obstacles(child)


func _collect_flat_native_support(shape_node: CollisionShape3D) -> void:
	var shape := shape_node.shape as ConcavePolygonShape3D
	var faces := shape.get_faces()
	if faces.is_empty():return
	var world_faces := PackedVector3Array()
	var height := (shape_node.global_transform*faces[0]).y
	for point: Vector3 in faces:
		var world_point: Vector3=shape_node.global_transform*point
		if not world_point.is_finite() or absf(world_point.y-height)>GrindStyle.CONTACT_TOLERANCE:return
		world_faces.append(world_point)
	_ledge_flat_supports.append({"body":shape_node.get_parent(),"height":height,
		"faces":world_faces,"backfaces":shape.backface_collision})


func _associate_flat_native_supports() -> void:
	# A native floor may share a retaining box's exact top edge. Authenticate
	# continuous finite backing, so native ray tie order cannot turn it into a
	# foreign collider. Actual board queries still include both solids.
	for line in lines:
		if line.contact_edge_outward==Vector3.ZERO:continue
		var a: Vector3=line.contact_at(0.0)
		var b: Vector3=line.contact_at(line.length)
		for support: Dictionary in _ledge_flat_supports:
			if absf(float(support.height)-a.y)>GrindStyle.CONTACT_TOLERANCE:continue
			if not _flat_native_covers(support,a,b,line.length):continue
			var body: StaticBody3D=support.body
			var ids: Array=body.get_meta("grind_surface_ids",[]).duplicate()
			if ids.has(line.id):continue
			ids.append(line.id);body.set_meta("grind_surface_ids",ids)
			for record: Dictionary in _records:
				if record.path==String(_world.get_path_to(body)):
					record.grind_ids=ids.duplicate()
					record.grind_reason="shared finite native flat support at the exact exposed edge"
			_ledge_work.shared_native_support_links+=1


func _flat_native_covers(support: Dictionary,a: Vector3,b: Vector3,length: float) -> bool:
	var intervals: Array[Vector2]=[]
	var faces: PackedVector3Array=support.faces
	var origin := Vector2(a.x,a.z)
	var motion := Vector2(b.x-a.x,b.z-a.z)
	for index: int in range(0,faces.size(),3):
		var first := Vector2(faces[index].x,faces[index].z)-origin
		var second := Vector2(faces[index+1].x,faces[index+1].z)-origin
		var third := Vector2(faces[index+2].x,faces[index+2].z)-origin
		var area := (second-first).cross(third-first)
		if area==0.0 or (not support.backfaces and area<0.0):continue
		var triangle := [first,second,third]
		var low := 0.0;var high := 1.0
		for edge: int in 3:
			var vertex: Vector2=triangle[edge]
			var direction: Vector2=triangle[(edge+1)%3]-vertex
			var start := signf(area)*direction.cross(-vertex)
			var change := signf(area)*direction.cross(motion)
			if change==0.0:
				if start<0.0:high=-1.0;break
			elif change>0.0:low=maxf(low,-start/change)
			else:high=minf(high,-start/change)
			if high<low:break
		if high>=low:intervals.append(Vector2(low,high))
	intervals.sort_custom(func(x: Vector2,y: Vector2) -> bool:return x.x<y.x)
	var covered := 0.0
	var tolerance := GrindStyle.CONTACT_TOLERANCE/length
	for interval: Vector2 in intervals:
		if interval.x>covered+tolerance:return false
		covered=maxf(covered,interval.y)
		if covered>=1.0-tolerance:return true
	return false


func _collect_ledge_terrain_screen() -> void:
	_ledge_ground_rects.clear()
	_ledge_pond_active = false
	# This proof depends on GlasgowSquare's actual highest-terrain merge. Other
	# providers/fixtures retain the original per-interval tests unchanged.
	var script := _world.get_script() as Script
	if script == null or script.resource_path != "res://game/levels/glasgow_square.gd": return
	if not _world.global_basis.y.normalized().is_equal_approx(Vector3.UP): return
	var terrain = _world.get("_terrain")
	if terrain == null: return
	for patch: Dictionary in terrain.patches:
		var bounds: Rect2 = patch.bounds
		var heights: Vector4 = patch.heights
		if not bounds.has_area(): continue
		var minimum := INF
		for corner: Vector3 in [Vector3(bounds.position.x,heights.x,bounds.position.y),
				Vector3(bounds.end.x,heights.y,bounds.position.y),
				Vector3(bounds.end.x,heights.z,bounds.end.y),
				Vector3(bounds.position.x,heights.w,bounds.end.y)]:
			minimum = minf(minimum,_world.to_global(corner).y)
		if is_finite(minimum): _ledge_ground_rects.append({"bounds":bounds,"minimum":minimum})
	_collect_ledge_outdoor_screen()
	var pond = _world.get("_park_pond")
	if not is_instance_valid(pond): return
	var polygon: PackedVector2Array = pond.get("_outer")
	if polygon.is_empty(): return
	var low := Vector2(INF,INF)
	var high := Vector2(-INF,-INF)
	for point: Vector2 in polygon:
		var local: Vector3 = _world.to_local(pond.to_global(Vector3(point.x,0,point.y)))
		low = low.min(Vector2(local.x,local.z))
		high = high.max(Vector2(local.x,local.z))
	_ledge_pond_bounds = Rect2(low,high-low).grow(0.00001)
	_ledge_pond_active = true


func _collect_ledge_outdoor_screen() -> void:
	_ledge_outdoor = null
	_ledge_outdoor_rects.clear()
	_ledge_bowl_bounds.clear()
	var outdoors = _world.get("_outdoors")
	if not is_instance_valid(outdoors): return
	var script := outdoors.get_script() as Script
	if script == null or script.resource_path != "res://game/levels/outdoor_routes.gd": return
	if not outdoors.global_basis.y.normalized().is_equal_approx(Vector3.UP): return
	# Bowls return before the ordinary highest-surface merge. Their actual
	# local circle is contained by this transformed square, conservatively
	# grown1mm for float32 transform rounding; this only disables a proof.
	for bowl: Node3D in outdoors.get("_sunken_bowls"):
		if not bowl.global_basis.y.normalized().is_equal_approx(Vector3.UP): return
		var radius: float = bowl.floor_radius+bowl.radius
		var low := Vector2(INF,INF)
		var high := Vector2(-INF,-INF)
		for corner: Vector3 in [Vector3(-radius,0,-radius),Vector3(radius,0,-radius),
				Vector3(radius,0,radius),Vector3(-radius,0,radius)]:
			var at: Vector3 = _world.to_local(bowl.to_global(corner))
			low = low.min(Vector2(at.x,at.z))
			high = high.max(Vector2(at.x,at.z))
		_ledge_bowl_bounds.append(Rect2(low,high-low).grow(0.001))
	_ledge_outdoor = outdoors
	for surface: Dictionary in outdoors.get("_surfaces"):
		if not surface.has_all(["bounds","height"]) or not surface.bounds is Rect2: continue
		if surface.has("edge_triangles") or surface.has("strip_sections") or surface.has("height_at"): continue
		var bounds: Rect2 = surface.bounds
		var height: float = surface.height
		if not bounds.has_area() or not is_finite(height): continue
		var minimum := INF
		for corner: Vector3 in [Vector3(bounds.position.x,height,bounds.position.y),
				Vector3(bounds.end.x,height,bounds.position.y),
				Vector3(bounds.end.x,height,bounds.end.y),
				Vector3(bounds.position.x,height,bounds.end.y)]:
			minimum = minf(minimum,outdoors.to_global(corner).y)
		_ledge_outdoor_rects.append({"bounds":bounds,"minimum":minimum})


func _native_ledge_buried(a: Vector3,b: Vector3,outward: Vector3) -> bool:
	if _ledge_ground_rects.is_empty() and _ledge_outdoor_rects.is_empty(): return false
	var p3: Vector3 = _world.to_local(a+outward*0.12)
	var q3: Vector3 = _world.to_local(b+outward*0.12)
	var p := Vector2(p3.x,p3.z)
	var q := Vector2(q3.x,q3.z)
	# Pond ground is returned before the normal highest-ground merge. Any
	# overlap with its conservative outer rectangle keeps the detailed path.
	var low := p.min(q)
	var high := p.max(q)
	if _ledge_pond_active and not (high.x<_ledge_pond_bounds.position.x or low.x>_ledge_pond_bounds.end.x
			or high.y<_ledge_pond_bounds.position.y or low.y>_ledge_pond_bounds.end.y): return false
	var threshold := maxf(a.y,b.y)-NATIVE_LEDGE_SKIN-0.04
	for patch: Dictionary in _ledge_ground_rects:
		if float(patch.minimum)<=threshold: continue
		var bounds: Rect2 = patch.bounds
		# Strict interior avoids CoreTerrain's special half-open endpoint
		# ownership. A rectangle is convex, so the entire probe segment fits.
		if (p.x>bounds.position.x and p.x<bounds.end.x and p.y>bounds.position.y and p.y<bounds.end.y
				and q.x>bounds.position.x and q.x<bounds.end.x and q.y>bounds.position.y and q.y<bounds.end.y):
			return true
	if not is_instance_valid(_ledge_outdoor): return false
	for bowl: Rect2 in _ledge_bowl_bounds:
		if not (high.x<bowl.position.x or low.x>bowl.end.x or high.y<bowl.position.y or low.y>bowl.end.y): return false
	# Match OutdoorRoutes.get_ground_height's actual world-XZ input. Keep
	# rectangle containment in its own frame instead of an enlarged rotated AABB.
	var probe_a := a+outward*0.12
	var probe_b := b+outward*0.12
	var outdoor_p: Vector3 = _ledge_outdoor.to_local(Vector3(probe_a.x,_ledge_outdoor.global_position.y,probe_a.z))
	var outdoor_q: Vector3 = _ledge_outdoor.to_local(Vector3(probe_b.x,_ledge_outdoor.global_position.y,probe_b.z))
	var u := Vector2(outdoor_p.x,outdoor_p.z)
	var v := Vector2(outdoor_q.x,outdoor_q.z)
	for patch: Dictionary in _ledge_outdoor_rects:
		if float(patch.minimum)<=threshold: continue
		var bounds: Rect2 = patch.bounds
		if (u.x>bounds.position.x and u.x<bounds.end.x and u.y>bounds.position.y and u.y<bounds.end.y
				and v.x>bounds.position.x and v.x<bounds.end.x and v.y>bounds.position.y and v.y<bounds.end.y):
			_ledge_work.outdoor_screened_edges += 1
			return true
	return false


func _native_box_ledges(body: StaticBody3D,key: String) -> Array[String]:
	var ids: Array[String] = []
	if not _world.has_method("get_ground_height") or body.collision_layer & 1 == 0: return ids
	if body.get_meta("exploration_boundary",false) or body.get_meta("terrain_surface",false) \
			or body.has_meta("transition_feature") or body.has_meta("grind_exclusion_reason"): return ids
	var ancestor: Node = body
	while ancestor != null and ancestor != _world:
		if ancestor.is_in_group("skate_transitions") or ancestor.get_meta("surface_audio","") in ["water","fabric"]: return ids
		ancestor = ancestor.get_parent()
	var shape_index := -1
	for child: Node in body.get_children():
		if not child is CollisionShape3D or child.disabled or not child.shape is BoxShape3D: continue
		shape_index += 1
		_ledge_work.box_shapes += 1
		var frame: Transform3D = child.global_transform
		if frame.basis.y.normalized().dot(Vector3.UP) < 0.999999: continue
		var half: Vector3 = child.shape.size*0.5
		var corners := PackedVector3Array([Vector3(-half.x,half.y,-half.z),Vector3(half.x,half.y,-half.z),
			Vector3(half.x,half.y,half.z),Vector3(-half.x,half.y,half.z)])
		for edge: int in 4:
			var a: Vector3 = frame*corners[edge]+Vector3.UP*NATIVE_LEDGE_SKIN
			var b: Vector3 = frame*corners[(edge+1)%4]+Vector3.UP*NATIVE_LEDGE_SKIN
			if a.distance_to(b)<NATIVE_LEDGE_MIN_RUN+0.24 or absf(a.y-b.y)>0.000001: continue
			_ledge_work.candidate_edges += 1
			var direction := (b-a).normalized()
			var outward := ((a+b)*0.5-frame.origin)*Vector3(1,0,1)
			outward = outward.normalized()
			a += direction*0.12
			b -= direction*0.12
			if _native_ledge_buried(a,b,outward):
				_ledge_work.terrain_screened_edges += 1
				continue
			var count := maxi(1,ceili(a.distance_to(b)/0.25))
			var start := Vector3.INF
			var segment := 0
			var nearby: Array[AABB] = _native_ledge_nearby(a,b,child)
			for index: int in count:
				var from := a.lerp(b,float(index)/count)
				var to := a.lerp(b,float(index+1)/count)
				# Both are required. Reject known blocked headroom before asking
				# the more expensive terrain provider for exact exposed drop.
				var headroom_clear := _native_ledge_interval_clear(from,to,nearby)
				if not headroom_clear: _ledge_work.headroom_rejected_intervals += 1
				var exposed := headroom_clear and _native_ledge_drop(from,to,outward)
				if exposed:
					if not start.is_finite(): start=from
				else:
					if start.is_finite(): _commit_native_ledge(ids,key,shape_index,edge,segment,start,from,outward)
					start=Vector3.INF
					segment+=1
			if start.is_finite(): _commit_native_ledge(ids,key,shape_index,edge,segment,start,b,outward)
	return ids


func _native_ledge_drop(a: Vector3,b: Vector3,outward: Vector3) -> bool:
	_ledge_work.intervals += 1
	for at: Vector3 in [a,(a+b)*0.5,b]:
		_ledge_work.terrain_query_count += 1
		var ground: float = _world.get_ground_height(at+outward*0.12)
		var drop := at.y-NATIVE_LEDGE_SKIN-ground
		if not is_finite(ground) or drop<0.04 or drop>NATIVE_LEDGE_MAX_RISE: return false
	return true


func _native_ledge_volume(a: Vector3,b: Vector3) -> AABB:
	# The upright body sits15mm above this edge; include its existing15mm
	# native safety shell above the full1.7m capsule as well.
	var lower := a.min(b)+Vector3(-0.295,-NATIVE_LEDGE_SKIN-0.015,-0.295)
	var upper := a.max(b)+Vector3(0.295,1.730-NATIVE_LEDGE_SKIN,0.295)
	return AABB(lower,upper-lower)


func _native_ledge_nearby(a: Vector3,b: Vector3,support: CollisionShape3D) -> Array[AABB]:
	var result: Array[AABB] = []
	var volume := _native_ledge_volume(a,b)
	var top := a.y-NATIVE_LEDGE_SKIN
	for index: int in _ledge_obstacles.size():
		_ledge_work.edge_obstacle_tests += 1
		# This exact flat Box primitive is below its own certified top. Other
		# shapes on the SAME body remain obstacles; no rounded-skin inference.
		if _ledge_obstacle_shapes[index] == support: continue
		var bounds: AABB = _ledge_obstacles[index]
		if bounds.end.y<=top+0.000001: continue
		if volume.intersects(bounds): result.append(bounds)
	_ledge_work.max_nearby_obstacles = maxi(_ledge_work.max_nearby_obstacles,result.size())
	return result


func _native_ledge_interval_clear(a: Vector3,b: Vector3,nearby: Array[AABB]) -> bool:
	var volume := _native_ledge_volume(a,b)
	for bounds: AABB in nearby:
		_ledge_work.interval_obstacle_tests += 1
		if volume.intersects(bounds): return false
	return true


func _commit_native_ledge(ids: Array[String],key: String,shape: int,edge: int,part: int,a: Vector3,b: Vector3,outward: Vector3) -> void:
	if a.distance_to(b)<NATIVE_LEDGE_MIN_RUN: return
	var existing := _covering_authored(a,b)
	if not existing.is_empty():
		if not ids.has(existing): ids.append(existing)
		return
	var id := "Grind_Ledge_"+key+"_Native_"+str(shape)+"_"+str(edge)+"_"+str(part)
	var line = Line.new(id,PackedVector3Array([a,b]),"ledge")
	line.configure_contact(-NATIVE_LEDGE_SKIN,0.0,"surface.native_box_top")
	line.configure_edge_contact(outward)
	if line.contact_edge_outward==Vector3.ZERO:return
	lines.append(line)
	ids.append(id)
	_ledge_work.guides += 1
