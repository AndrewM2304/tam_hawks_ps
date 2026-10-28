extends Node3D
## Original, compressed Glasgow-inspired landscapes; not surveyed street geometry.
## Published coordinates are world-space board-contact positions except checkpoints.

const Layout = preload("res://game/levels/clyde_layout.gd")
const Surface = preload("res://game/levels/outdoors/surface_builder.gd")
var _sunken_bowls: Array[Node3D] = []
const Vegetation = preload("res://game/levels/outdoors/vegetation.gd")
const ClydeLandmarks = preload("res://game/levels/art/clyde_landmarks.gd")
const GrindLineSource = preload("res://game/tricks/grind_line.gd")
const ExplorationBoundary = preload("res://game/levels/exploration_boundary.gd")
const WATER_SHADER = preload("res://game/art/assets/horizon/clyde_water.gdshader")
const ENCLOSED_GROUND := [Rect2(-130,-108,36,66),Rect2(-94,-108,59,22),Rect2(-140,-108,10,16)]
const TransitionFeature = preload("res://game/levels/transition_feature.gd")
const PRACTICE_APRON := Rect2(-118, -139.5, 42, 13.5)
const PARK := Rect2(-220, -185, 80, 110)
const PARK_LANDSCAPE := Rect2(-255, -225, 115, 165)
const ParkVisualSkin = preload("res://game/levels/park_visual_skin.gd")
const SKATEPARK_SOURCE := "res://game/levels/kelvingrove_skatepark.gd"
const SKATEPARK_BOUNDS := Rect2(-227.5,-202.5,40,30)
const SKATEPARK_ORIGIN := Vector3(-207.5,14.5,-187.5)
const SKATEPARK_ENTRY := Vector3(-187.5,14.5,-182.5)
const SKATEPARK_ACCESS_BOUNDS := Rect2(-187.5,-185.5,8.5,6)
const RIVER := Rect2(-150, 78, 300, 38)
const VISIBLE_WATER := Rect2(-450, 78, 900, 38)
const WATER_Y := -2.0
const YARD_BANK_RADIUS := 4.0
const YARD_BANK_ANGLE := deg_to_rad(35.0)
const YARD_BANK_RUN := YARD_BANK_RADIUS * sin(YARD_BANK_ANGLE)
const YARD_BANK_RISE := YARD_BANK_RADIUS * (1.0 - cos(YARD_BANK_ANGLE))

var _materials: Dictionary
var _surfaces: Array[Dictionary] = []
var _routes: Array[Dictionary] = []
var _rails: Array = []
var _park_path := PackedVector3Array()
var _park_cutback := PackedVector3Array()
var _clyde_yard := PackedVector3Array()
var _park_connector := PackedVector3Array()
var _george_connector := PackedVector3Array()
var _park_height_cache: Dictionary = {}
var _skatepark_source: Script
var _skatepark: Node3D
var _legacy_edge_construction := false
var _built := false
var _transitions: Array[Node3D] = []
var _practice_features: Array[Dictionary] = []
var _park_runs_composed := false
# Existing activity gate positions/heights, sampled before this grading repair.
# Keep the route itself fixed; smooth only its supporting grassy bank.
var _bank_cut_grade := PackedVector3Array([
	Vector3(-148,6,-92),Vector3(-156,9.2044153213501,-112),
	Vector3(-179,10.8526992797852,-136),Vector3(-195,9.0058708190918,-106),
	Vector3(-164,6.41034936904907,-88),Vector3(-155,5.73371362686157,-82)])


func build(world: Node3D, materials: Dictionary) -> void:
	if _built: return
	_built = true
	_materials = materials
	if ResourceLoader.exists(SKATEPARK_SOURCE): _skatepark_source = load(SKATEPARK_SOURCE)
	_build_clyde()
	_build_riverside_edge(world)
	_build_park()
	_build_practice_pockets()
	_separate_park_grass_finishes(world)
	_fit_park_visual_surfaces.call_deferred()
	_build_exploration_boundaries()


## The road owns its whole footprint, including its lower-entry shoulders.
## The native grass grid may cross a road's piecewise plane between samples;
## burying it further changes skating support without establishing ownership.
## Subtract only its display at startup; native/query triangles remain exact.
func _separate_park_grass_finishes(world: Node3D) -> void:
	var clips: Array[Dictionary] = []
	var road_footprints: Array[PackedVector2Array] = []
	# Keep the already admitted summit/terrace finishes untouched. These are
	# the two existing ribbons meeting at the reported lower-park arrivals.
	for id: String in ["KelvingroveCentralApproach","KelvingroveCutbackReturn"]:
		var body := get_node_or_null(id)
		if body == null: continue
		var strip: PackedVector3Array = body.get_meta("support_vertices")
		for i in range(0,strip.size()-2,2):
			var polygon := PackedVector2Array([Vector2(strip[i].x,strip[i].z),
				Vector2(strip[i+1].x,strip[i+1].z),Vector2(strip[i+3].x,strip[i+3].z),
				Vector2(strip[i+2].x,strip[i+2].z)])
			clips.append({"polygon":polygon,"bounds":_finish_bounds(polygon)})
			road_footprints.append(polygon)
	# The station mouth and civic mouth belong to core terrain, not this
	# outdoor ribbon list. Include their actual transformed top footprints;
	# otherwise grass remains visible in the wider arms of each junction.
	for id: String in ["KelvingroveWestPort","KelvingroveCivicPort"]:
		var body := world.get_node_or_null(id)
		if not body is Node3D: continue
		var top: PackedVector3Array = body.get_meta("top_polygon_local",PackedVector3Array())
		var polygon := PackedVector2Array()
		for point: Vector3 in top:
			var local := to_local(body.to_global(point))
			polygon.append(Vector2(local.x,local.z))
		if polygon.size()>=3: clips.append({"polygon":polygon,"bounds":_finish_bounds(polygon)})
	# Union the touching ribbon sections before cutting the terrain. Otherwise
	# every internal road cross-section unnecessarily splits a grass triangle.
	var footprints: Array[PackedVector2Array] = []
	for clip: Dictionary in clips:
		var footprint: PackedVector2Array = clip.polygon
		var index := 0
		while index<footprints.size():
			var joined := Geometry2D.merge_polygons(footprint,footprints[index])
			if joined.size()==1:
				footprint=joined[0]
				footprints.remove_at(index)
				index=0
			else: index+=1
		footprints.append(footprint)
	clips.clear()
	for polygon: PackedVector2Array in footprints:
		clips.append({"polygon":polygon,"bounds":_finish_bounds(polygon)})
	for id: String in ["KelvingroveRollingGround","KelvingroveCentralEmbankment","KelvingroveGeorgeEmbankment"]:
		var body: StaticBody3D = get_node(id)
		var visual: MeshInstance3D = body.get_child(0)
		var arrays := visual.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(0,indices.size(),3):
			var a := vertices[indices[i]]
			var ab := vertices[indices[i+1]]-a
			var ac := vertices[indices[i+2]]-a
			var first := Vector2(a.x,a.z)
			var edge_b := Vector2(ab.x,ab.z)
			var edge_c := Vector2(ac.x,ac.z)
			var determinant := edge_b.cross(edge_c)
			if absf(determinant)<0.00000001: continue
			var triangle := PackedVector2Array([first,first+edge_b,first+edge_c])
			var bounds := _finish_bounds(triangle)
			var pieces: Array[PackedVector2Array] = [triangle]
			for clip: Dictionary in clips:
				if not bounds.intersects(clip.bounds): continue
				var remaining: Array[PackedVector2Array] = []
				for piece: PackedVector2Array in pieces:
					remaining.append_array(_subtract_finish_polygon(piece,clip.polygon))
				pieces = remaining
				if pieces.is_empty(): break
			for piece: PackedVector2Array in pieces:
				var triangles := Geometry2D.triangulate_polygon(piece)
				for index: int in triangles:
					var relative := piece[index]-first
					var wb := relative.cross(edge_c)/determinant
					var wc := edge_b.cross(relative)/determinant
					var wa := 1.0-wb-wc
					tool.set_normal((normals[indices[i]]*wa+normals[indices[i+1]]*wb+normals[indices[i+2]]*wc).normalized())
					tool.set_uv(uv[indices[i]]*wa+uv[indices[i+1]]*wb+uv[indices[i+2]]*wc)
					# Keep clipped XZ coordinates verbatim. Reconstructing them
					# through barycentrics rounds a shared road edge twice.
					tool.add_vertex(Vector3(piece[index].x,a.y+ab.y*wb+ac.y*wc,piece[index].y))
		tool.index()
		visual.mesh = tool.commit()
		visual.set_meta("paved_footprint_ownership",true)
		visual.set_meta("grass_triangles_before",indices.size()/3)
		visual.set_meta("grass_triangles_after",visual.mesh.get_faces().size()/3)
	_conform_station_port_finish(world.get_node("KelvingroveWestPort"),road_footprints)


## The wider station mouth contains continuous grassy support above its old
## flat Y2 slab. Fit its asphalt to those exact native planes, retaining that
## good grade. The approach already owns its overlapping asphalt footprint.
## Only the core body's top is replaced; bottom/retaining faces stay untouched.
func _conform_station_port_finish(body: StaticBody3D,roads: Array[PackedVector2Array]) -> void:
	var top: PackedVector3Array = body.get_meta("top_polygon_local")
	var plane := PackedVector3Array()
	var outline := PackedVector2Array()
	for point: Vector3 in top:
		var local := to_local(body.to_global(point))
		plane.append(local)
		outline.append(Vector2(local.x,local.z))
	var bounds := _finish_bounds(outline)
	var flat: Array[PackedVector2Array] = [outline]
	for road: PackedVector2Array in roads:
		if not bounds.intersects(_finish_bounds(road)): continue
		var pieces: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in flat: pieces.append_array(_subtract_finish_polygon(piece,road))
		flat=pieces
	var raised: Array[Dictionary] = []
	var ground: StaticBody3D = get_node("KelvingroveCentralEmbankment")
	var native: PackedVector3Array = ground.get_child(1).shape.get_faces()
	for i in range(0,native.size(),3):
		var triangle := PackedVector3Array()
		var footprint := PackedVector2Array()
		for offset: int in 3:
			var local := to_local(ground.to_global(native[i+offset]))
			triangle.append(local)
			footprint.append(Vector2(local.x,local.z))
		if not bounds.intersects(_finish_bounds(footprint)): continue
		for clipped: PackedVector2Array in Geometry2D.intersect_polygons(footprint,outline):
			var above := _finish_above_plane(clipped,triangle,plane)
			if above.size()<3: continue
			var remaining: Array[PackedVector2Array] = []
			for piece: PackedVector2Array in flat: remaining.append_array(_subtract_finish_polygon(piece,above))
			flat=remaining
			var displayed: Array[PackedVector2Array] = [above]
			for road: PackedVector2Array in roads:
				if not _finish_bounds(above).intersects(_finish_bounds(road)): continue
				var pieces: Array[PackedVector2Array] = []
				for piece: PackedVector2Array in displayed: pieces.append_array(_subtract_finish_polygon(piece,road))
				displayed=pieces
			for piece: PackedVector2Array in displayed: raised.append({"polygon":piece,"plane":triangle})
	var visual: MeshInstance3D
	for child: Node in body.get_children():
		if child is MeshInstance3D: visual=child;break
	var original: PackedVector3Array = visual.mesh.get_faces()
	var arrays := visual.mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,original.size(),3):
		var is_top := true
		for offset: int in 3:
			var local := to_local(body.to_global(original[i+offset]))
			is_top=is_top and absf(local.y-_finish_plane_height(plane,Vector2(local.x,local.z)))<.00001
		if is_top: continue
		for offset: int in 3:
			var index: int = indices[i+offset] if not indices.is_empty() else i+offset
			tool.set_normal(normals[index])
			tool.add_vertex(original[i+offset])
	for piece: PackedVector2Array in flat: _emit_port_finish(tool,piece,plane,body)
	for piece: Dictionary in raised: _emit_port_finish(tool,piece.polygon,piece.plane,body)
	tool.index()
	visual.mesh=tool.commit()
	visual.set_meta("native_port_finish",true)
	visual.set_meta("port_triangles_before",original.size()/3)
	visual.set_meta("port_triangles_after",visual.mesh.get_faces().size()/3)
	visual.set_meta("port_edge_cap_triangles",0)
	_close_park_approach_edges(plane,outline)


## Close the complete approach perimeter, rather than stopping at the core
## port boundary. Native grass planes give an exact lower height bound for
## each original strip edge. Its constant lower edge remains buried beneath
## the piecewise ground, while the unchanged upper edge is the riding grade.
func _close_park_approach_edges(base: PackedVector3Array,port_outline: PackedVector2Array) -> void:
	var road: StaticBody3D = get_node("KelvingroveCentralApproach")
	var strip: PackedVector3Array = road.get_meta("support_vertices")
	var footprint := PackedVector2Array()
	for point: Vector3 in strip: footprint.append(Vector2(point.x,point.z))
	var road_bounds := _finish_bounds(footprint).grow(.001)
	var grounds: Array[Dictionary] = []
	for id: String in ["KelvingroveRollingGround","KelvingroveCentralEmbankment","KelvingroveGeorgeEmbankment"]:
		var ground: StaticBody3D = get_node(id)
		var native: PackedVector3Array = ground.get_child(1).shape.get_faces()
		for i in range(0,native.size(),3):
			var triangle := PackedVector3Array()
			var polygon := PackedVector2Array()
			for offset: int in 3:
				var point := to_local(ground.to_global(native[i+offset]))
				triangle.append(point)
				polygon.append(Vector2(point.x,point.z))
			if absf((polygon[1]-polygon[0]).cross(polygon[2]-polygon[0]))<.00000001: continue
			var bounds := _finish_bounds(polygon)
			if bounds.intersects(road_bounds,true): grounds.append({"plane":triangle,"polygon":polygon,"bounds":bounds})
	var edges: Array[Dictionary] = []
	for i in range(0,strip.size()-2,2):
		var center := Vector3.ZERO
		for offset: int in 4: center+=to_local(road.to_global(strip[i+offset]))*.25
		for side: int in [0,1]:
			edges.append({"start":to_local(road.to_global(strip[i+side])),
				"finish":to_local(road.to_global(strip[i+2+side])),"center":center})
	for pair: Array in [[0,1,2,3],[strip.size()-2,strip.size()-1,strip.size()-4,strip.size()-3]]:
		var center := Vector3.ZERO
		for index: int in pair: center+=to_local(road.to_global(strip[index]))*.25
		edges.append({"start":to_local(road.to_global(strip[pair[0]])),
			"finish":to_local(road.to_global(strip[pair[1]])),"center":center})
	var visual: MeshInstance3D = road.get_child(0)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.append_from(visual.mesh,0,Transform3D.IDENTITY)
	# append_from imports the old index list. New cap vertices must join the
	# unindexed stream before the final index pass, rather than remain unused.
	tool.deindex()
	var native_caps := PackedVector3Array()
	var records: Array[Dictionary] = []
	for edge: Dictionary in edges:
		var start: Vector3 = edge.start
		var finish: Vector3 = edge.finish
		var line := PackedVector2Array([Vector2(start.x,start.z),Vector2(finish.x,finish.z)])
		var bounds := _finish_bounds(line)
		var lower := INF
		for ground: Dictionary in grounds:
			if not bounds.intersects(ground.bounds,true): continue
			for piece: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line,ground.polygon):
				for point: Vector2 in piece: lower=minf(lower,_finish_plane_height(ground.plane,point))
		# The core slab provides real Y2 support through the complete mouth.
		# Elsewhere the lower bound comes only from the actual grass planes.
		if Geometry2D.is_point_in_polygon(line[0],port_outline) and Geometry2D.is_point_in_polygon(line[1],port_outline):
			lower=maxf(lower,minf(_finish_plane_height(base,line[0]),_finish_plane_height(base,line[1])))
		assert(is_finite(lower),"Approach edge has no native resident ground")
		lower=minf(lower,minf(start.y,finish.y))
		var delta := line[1]-line[0]
		var outward := Vector3(delta.y,0,-delta.x).normalized()
		if outward.dot((start+finish)*.5-edge.center)<0: outward=-outward
		var bottom_start := Vector3(start.x,lower,start.z)
		var bottom_finish := Vector3(finish.x,lower,finish.z)
		var before := native_caps.size()
		for face: Array in [[start,finish,bottom_start],[finish,bottom_finish,bottom_start]]:
			var cross: Vector3 = (face[1]-face[0]).cross(face[2]-face[0])
			if cross.length_squared()<.0000000001: continue
			if cross.dot(outward)>0:
				var swap: Vector3=face[1];face[1]=face[2];face[2]=swap
			for point: Vector3 in face:
				var local := road.to_local(to_global(point))
				tool.set_normal((road.global_basis.inverse()*global_basis*outward).normalized())
				tool.set_uv(Vector2(point.x,point.z)*.2)
				tool.add_vertex(local)
				native_caps.append(local)
		records.append({"start":start,"finish":finish,"lower":lower,"outward":outward,
			"triangles":(native_caps.size()-before)/3})
	tool.index()
	visual.mesh=tool.commit()
	var collision: CollisionShape3D = road.get_child(1)
	var original: PackedVector3Array = collision.shape.get_faces()
	original.append_array(native_caps)
	collision.shape.set_faces(original)
	road.set_meta("port_edge_cap_faces",native_caps)
	road.set_meta("approach_edge_closures",records)
	visual.set_meta("approach_edge_cap_triangles",native_caps.size()/3)


func _finish_above_plane(polygon: PackedVector2Array,upper: PackedVector3Array,lower: PackedVector3Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in polygon.size():
		var start := polygon[i]
		var finish := polygon[(i+1)%polygon.size()]
		var first := _finish_plane_height(upper,start)-_finish_plane_height(lower,start)
		var last := _finish_plane_height(upper,finish)-_finish_plane_height(lower,finish)
		if first>=0.0: result.append(start)
		if (first<0.0 and last>0.0) or (first>0.0 and last<0.0):
			result.append(start.lerp(finish,first/(first-last)))
	return result


func _finish_plane_height(plane: PackedVector3Array,point: Vector2) -> float:
	var first := Vector2(plane[0].x,plane[0].z)
	var ab := Vector2(plane[1].x,plane[1].z)-first
	var ac := Vector2(plane[2].x,plane[2].z)-first
	var relative := point-first
	var wb := relative.cross(ac)/ab.cross(ac)
	var wc := ab.cross(relative)/ab.cross(ac)
	return plane[0].y*(1-wb-wc)+plane[1].y*wb+plane[2].y*wc


func _emit_port_finish(tool: SurfaceTool,polygon: PackedVector2Array,plane: PackedVector3Array,body: StaticBody3D) -> void:
	var normal := (plane[1]-plane[0]).cross(plane[2]-plane[0]).normalized()
	if normal.y<0.0: normal=-normal
	normal=(body.global_basis.inverse()*global_basis*normal).normalized()
	for index: int in Geometry2D.triangulate_polygon(polygon):
		var point := polygon[index]
		tool.set_normal(normal)
		tool.add_vertex(body.to_local(to_global(Vector3(point.x,_finish_plane_height(plane,point),point.y))))


## Convex half-plane partitioning also handles a clip wholly inside one
## triangle: Geometry2D's hole contours cannot be triangulated independently.
## Each emitted piece is outside one clip edge and is therefore hole-free.
func _subtract_finish_polygon(subject: PackedVector2Array,clip: PackedVector2Array) -> Array[PackedVector2Array]:
	var clipped: Array[PackedVector2Array] = Geometry2D.clip_polygons(subject,clip)
	var winding_sign := 0.0
	var has_hole := false
	for polygon: PackedVector2Array in clipped:
		var signed := 0.0
		for i in polygon.size(): signed+=(polygon[i]-polygon[0]).cross(polygon[(i+1)%polygon.size()]-polygon[0])
		if is_zero_approx(signed): continue
		if winding_sign==0.0: winding_sign=signf(signed)
		has_hole=has_hole or signed*winding_sign<0.0
	# Native subtraction keeps untouched triangles intact. Only enclosed holes
	# require the convex partition below; their contours cannot be filled alone.
	if not has_hole: return clipped
	var result: Array[PackedVector2Array] = []
	var remaining := subject
	var winding := 0.0
	for i in clip.size(): winding+=(clip[i]-clip[0]).cross(clip[(i+1)%clip.size()]-clip[0])
	var sign := 1.0 if winding>0.0 else -1.0
	for i in clip.size():
		if remaining.size()<3: break
		var inside := PackedVector2Array()
		var outside := PackedVector2Array()
		var origin := clip[i]
		var edge := clip[(i+1)%clip.size()]-origin
		for j in remaining.size():
			var start := remaining[j]
			var finish := remaining[(j+1)%remaining.size()]
			var first := edge.cross(start-origin)*sign
			var last := edge.cross(finish-origin)*sign
			if first>=0.0: inside.append(start)
			if first<=0.0: outside.append(start)
			if (first<0.0 and last>0.0) or (first>0.0 and last<0.0):
				var crossing := start.lerp(finish,first/(first-last))
				inside.append(crossing)
				outside.append(crossing)
		if outside.size()>=3: result.append(outside)
		remaining = inside
	return result


func _finish_bounds(polygon: PackedVector2Array) -> Rect2:
	var minimum := polygon[0]
	var maximum := polygon[0]
	for point: Vector2 in polygon:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum,maximum-minimum)


func _fit_park_visual_surfaces() -> void:
	# Only the two observed burial areas receive a dense material skin over
	# their existing exact support. Original collision/query triangles stay put.
	# Wait for native bodies to enter the physics space, then fit against that
	# space itself, including intersecting terrain patches and path shoulders.
	await get_tree().physics_frame
	var fitter := ParkVisualSkin.new()
	fitter.prepare(self)
	for child: Node in get_children():
		if not child is StaticBody3D: continue
		if str(child.get_meta("art_label","")) not in ["ParkGranitePathEdge","KelvingroveRollingLoop"]: continue
		# Asphalt keeps the inner half of the 40cm material overlap. Distinct
		# two/six-millimetre skins avoid coplanar stone/asphalt z-fighting.
		var skin := 0.002 if str(child.get_meta("art_label",""))=="ParkGranitePathEdge" else 0.006
		fitter.fit(child,_native_visual_height,skin)


func _native_visual_height(x: float,z: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(to_global(Vector3(x,30,z)),to_global(Vector3(x,-10,z)),1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return NAN if hit.is_empty() else to_local(hit.position).y


func get_checkpoints() -> Dictionary:
	return {"clyde": to_global(Vector3(15, 2.8, 67)), "kelvingrove": to_global(Vector3(-155, 6.8, -82))}


func _build_exploration_boundaries() -> void:
	# These are the exposed edges of the three joined landscape rectangles,
	# not their internal seams. Preserve both real civic/station port mouths.
	for edge: Array in [
		[Vector2(-254.8,-224.8),Vector2(-254.8,-60.2)],
		[Vector2(-254.8,-224.8),Vector2(-140.2,-224.8)],
		[Vector2(-140.2,-224.8),Vector2(-140.2,-142)],
		[Vector2(-140.2,-108),Vector2(-140.2,-92)],
		[Vector2(-140,-141.8),Vector2(-42.2,-141.8)],
		[Vector2(-140,-108.2),Vector2(-42.2,-108.2)],
		[Vector2(-42.2,-141.8),Vector2(-42.2,-128)],
		[Vector2(-42.2,-116),Vector2(-42.2,-108.2)],
		[Vector2(-140,-91.8),Vector2(-130.2,-91.8)],
		[Vector2(-130.2,-91.8),Vector2(-130.2,-8)],
		[Vector2(-130.2,8),Vector2(-130.2,19.8)],
		[Vector2(-214.8,19.8),Vector2(-130.2,19.8)],
		[Vector2(-214.8,-60),Vector2(-214.8,19.8)],
		[Vector2(-254.8,-60.2),Vector2(-215,-60.2)]
	]:
		# The practice terrace and its raised roll-in need a visible fence high
		# enough to contain a deck ollie as well as a rider on the lower path.
		var height := 5.0 if edge[0] == Vector2(-140,-141.8) else 3.0
		_boundary("ParkRetainedBoundary",edge[0],edge[1],height)
	# The station arrival turns north. Mark its closed west/south end instead
	# of letting a straight-ahead run leave the asphalt through an open gap.
	_boundary("StationParkArrivalGuard",Vector2(-130.2,7.8),Vector2(-150,7.8),4.5)
	_boundary("StationParkArrivalGuard",Vector2(-150,7.8),Vector2(-150,-1),4.5)
	# Bound BOTH sides of the landward void between the city and the quay.
	# The river-facing edges remain the explicit, recoverable skating hazard.
	var west_join := _approach_boundaries("ClydeWestApproach", -1.0)
	var east_join := _approach_boundaries("ClydeEastApproach", 1.0)
	for span: Vector2 in [Vector2(west_join.x,-15),Vector2(-9,9),Vector2(15,east_join.x)]:
		_boundary("QuayLandwardBoundary",Vector2(span.x,55.2),Vector2(span.y,55.2))
	_boundary("NorthQuayEndBoundary",Vector2(-84.8,west_join.y),Vector2(-84.8,77.8))
	_boundary("NorthQuayEndBoundary",Vector2(84.8,east_join.y),Vector2(84.8,77.8))
	for x: float in [-38.8,75.8]:
		_boundary("SouthPocketEndBoundary",Vector2(x,116.2),Vector2(x,142.8))
	_boundary("SouthPocketRearBoundary",Vector2(-38.8,142.8),Vector2(75.8,142.8))


# Follow the real bent ribbon outside the quay, leaving its broad join open.
# Returning inner-X / outer-Z joins avoids a straight fence across the approach.
func _approach_boundaries(id: String, side: float) -> Vector2:
	var body: Node3D = get_node(id)
	var vertices: PackedVector3Array = body.get_meta("support_vertices")
	var result := Vector2.ZERO
	for parity: int in 2:
		var edge := PackedVector3Array()
		for index: int in range(parity,vertices.size(),2):
			var point := vertices[index]
			var centre := (vertices[index-index%2]+vertices[index-index%2+1])*0.5
			point=point.move_toward(centre,0.18)
			if edge.is_empty(): point=point.lerp(vertices[index+2].move_toward((vertices[2]+vertices[3])*0.5,0.18),0.02)
			if Layout.NORTH_QUAY.has_point(Vector2(point.x,point.z)):
				var previous := edge[-1]
				var t: float
				# The west ribbon has opposite winding but paired sides still sort
				# by world X. Select the actual rectangle entry, not parity.
				var inner := (parity==0) if side>0 else (parity==1)
				t=(55.2-previous.z)/(point.z-previous.z) if inner else (side*84.8-previous.x)/(point.x-previous.x)
				point=previous.lerp(point,clampf(t,0,1))
				if inner: result.x=point.x
				else: result.y=point.z
				edge.append(point)
				break
			edge.append(point)
		ExplorationBoundary.build(self,"QuayApproachBoundary",edge,_material("stone_light"),_material("iron"),3.0,false,true)
	return result



func _boundary(id: String, start: Vector2, end: Vector2, fence_height: float = 3.0) -> void:
	var points := PackedVector3Array()
	var count := maxi(1,ceili(start.distance_to(end)/2.0))
	for index: int in range(count+1):
		var at := start.lerp(end,float(index)/count)
		var height := _local_ground(at.x,at.y)
		assert(is_finite(height),"Outdoor boundary requires real supported ground: "+id+" "+str(at))
		points.append(Vector3(at.x,height,at.y))
	# The west half/quarter decks stand at Y5.2, above a normal fence's Y5
	# top. Use the existing property back wall to contain their outward exits.
	# Top Y12 also clears the unpumped 18m/s vertical lip's ~Y10 apex.
	var behind_decks := id == "QuayLandwardBoundary" and end.x <= -15.0
	var opaque_edge := id == "NorthQuayEndBoundary" or id == "QuayLandwardBoundary"
	# Large screen-filling walls share the city's lighter masonry family;
	# reserve normal-mapped concrete for the existing shaped skating features.
	var wall_material := _material("cut_stone") if id == "ParkRetainedBoundary" else _material("stone_light")
	if behind_decks: wall_material = _material("shop_navy")
	var boundary := ExplorationBoundary.build(self,id,points,wall_material,_material("iron"),
		10.0 if behind_decks else fence_height,behind_decks or id.begins_with("SouthPocket"),opaque_edge)
	# This is a continuous, solid print-yard masonry wall, rather than exposed
	# perimeter ironwork. Its native backing remains the hard level boundary.
	if id == "SouthPocketRearBoundary":
		boundary.set_meta("no_wallride",false)
		boundary.set_meta("wallrideable",true)
		boundary.remove_meta("wallride_exclusion_reason")


func get_district_id(world_position: Vector3) -> String:
	var at := to_local(world_position)
	if at.z >= 45.0 and at.z <= 143.0 and is_finite(_local_ground(at.x,at.z)): return "clyde"
	if PARK_LANDSCAPE.has_point(Vector2(at.x, at.z)): return "kelvingrove"
	# The paved practice pocket extends beyond the narrow promenade corridor.
	# Use its exact authored footprint so adjacent station/civic land stays put.
	if PRACTICE_APRON.has_point(Vector2(at.x, at.z)): return "kelvingrove"
	for extension: Rect2 in [Rect2(-161,-34,3.2,15),Rect2(-139,-63,3.2,13),Rect2(-70,-132,16,6)]:
		if extension.has_point(Vector2(at.x,at.z)): return "kelvingrove"
	# Narrow connector footprints avoid capturing Central/George from broad bounds.
	if at.x < -145.0 and float(Surface.nearest_segment(_park_connector, Vector2(at.x, at.z)).distance) < 6.5: return "kelvingrove"
	if at.x < -46.0 and float(Surface.nearest_segment(_george_connector, Vector2(at.x, at.z)).distance) < 5.0: return "kelvingrove"
	return ""


func get_location_name(world_position: Vector3) -> String:
	return "CLYDE QUAYS" if get_district_id(world_position) == "clyde" else "KELVINGROVE PARK"


func get_ground_height(world_x: float, world_z: float) -> float:
	for bowl: Node3D in _sunken_bowls:
		var point := Vector3(world_x,bowl.global_position.y,world_z)
		var at := bowl.to_local(point)
		if Vector2(at.x,at.z).length()<=bowl.floor_radius+bowl.radius:
			return bowl.get_surface_height(point)
	var local := to_local(Vector3(world_x, global_position.y, world_z))
	var height := _local_ground(local.x, local.z)
	return NAN if is_nan(height) else to_global(Vector3(local.x, height, local.z)).y


func register_sunken_bowl(bowl: Node3D) -> void:
	_sunken_bowls.append(bowl)


func get_support_height(world_point: Vector3,max_step_up: float = 1.0) -> float:
	var local := to_local(world_point)
	if is_instance_valid(_skatepark) and SKATEPARK_BOUNDS.has_point(Vector2(local.x,local.z)):
		return _skatepark.get_surface_height(world_point,maxf(0.0,max_step_up))
	var height := get_ground_height(world_point.x,world_point.z)
	return height if height<=world_point.y+maxf(0.0,max_step_up) else NAN


func get_recovery_position(world_position: Vector3) -> Vector3:
	var at := to_local(world_position)
	# Every visible part of the river is the same readable water hazard. The
	# scenic plane is wider than the skating quays; do not leave its ends without
	# the prompt supported-quay recovery used by a missed bridge transfer.
	if not VISIBLE_WATER.has_point(Vector2(at.x, at.z)) or at.y >= WATER_Y + 0.25: return Vector3.INF
	var safe_z := 71.0 if at.z < RIVER.get_center().y else 124.0
	# Stay away from deck rails and place the skater directly on a broad quay.
	var bounds: Rect2 = Layout.NORTH_QUAY if safe_z < 100 else Layout.SOUTH_QUAY
	var safe_x := clampf(at.x,bounds.position.x+6.0,bounds.end.x-6.0)
	if absf(safe_x-Layout.SAFE_X)<7.0: safe_x=Layout.SAFE_X+12.0
	if absf(safe_x-Layout.TRANSFER_X)<5.0: safe_x=Layout.TRANSFER_X-10.0
	return to_global(Vector3(safe_x, 2.8, safe_z))


func get_grind_lines() -> Array:
	var lines := _rails.duplicate()
	for feature: Node3D in _transitions:
		lines.append_array(feature.get_grind_lines())
	if is_instance_valid(_skatepark): lines.append_array(_skatepark.get_grind_lines())
	return lines


func get_skate_feature_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = _practice_features.duplicate(true)
	if is_instance_valid(_skatepark):
		for raw: Dictionary in _skatepark.get_feature_definitions():
			var definition := raw.duplicate(true)
			definition.district = "kelvingrove"
			result.append(definition)
	return result


## Called once after the existing infill is built, before guide snapshots and
## batching. Reuse the two seats, their four bearings and their materials: no
## new obstacle, draw, shape or per-frame placement work.
func compose_park_runs(world: Node3D) -> void:
	if _park_runs_composed: return
	_park_runs_composed = true
	for definition: Dictionary in [
		{"id":"park_east_lower","z":-136.0,"old":Rect2(-155,-140,1.2,8)},
		{"id":"park_east_gateway","z":-112.0,"old":Rect2(-154,-116,1.2,8)}]:
		var station := _park_run_station(float(definition.z))
		var direction: Vector3 = station.direction
		var side := Vector3(-direction.z,0,direction.x)
		var center: Vector3 = station.point + side*3.0
		var start := center-direction*4.0
		var finish := center+direction*4.0
		# The exact native road owns the riding plane. A single graded seat
		# bridges the small changes in path tangent; its runout stays on asphalt.
		start.y = _local_ground(start.x,start.z)+0.46
		finish.y = _local_ground(finish.x,finish.z)+0.46
		_refit_park_seat(world,String(definition.id),definition.old,start,finish,side)
	world.set_meta("pt24_park_runs_composed",true)


func _park_run_station(z: float) -> Dictionary:
	var at := Vector2(-145,z)
	var distance := INF
	var result: Dictionary = {}
	for index: int in _park_path.size()-1:
		var a := _park_path[index]
		var b := _park_path[index+1]
		var delta := Vector2(b.x-a.x,b.z-a.z)
		var weight := clampf((at-Vector2(a.x,a.z)).dot(delta)/delta.length_squared(),0,1)
		var point := a.lerp(b,weight)
		var squared := at.distance_squared_to(Vector2(point.x,point.z))
		if squared>=distance: continue
		distance=squared
		var direction := Vector3(delta.x,0,delta.y).normalized()
		if direction.z<0: direction=-direction
		result={"point":point,"direction":direction}
	return result


func _refit_park_seat(world: Node3D,id: String,old: Rect2,start: Vector3,finish: Vector3,side: Vector3) -> void:
	var body: StaticBody3D = world.get_node(id)
	var old_top: PackedVector3Array = body.get_meta("top_polygon_local")
	var old_north := to_local(body.to_global(old_top[0])).y
	var old_south := to_local(body.to_global(old_top[3])).y
	var remap := func(global_point: Vector3) -> Vector3:
		var point := to_local(global_point)
		var along := (point.z-old.position.y)/old.size.y
		var across := (point.x-old.get_center().x)/old.size.x
		var top := start.lerp(finish,along)
		return to_global(top-side*(across*old.size.x)+Vector3.UP*(point.y-lerpf(old_north,old_south,along)))
	var new_top := PackedVector3Array()
	for point: Vector3 in old_top:
		new_top.append(body.to_local(remap.call(body.to_global(point))))
	body.set_meta("top_polygon_local",new_top)
	for child: Node in body.get_children():
		if child is CollisionShape3D:
			var points: PackedVector3Array = child.shape.points
			for index: int in points.size(): points[index]=child.to_local(remap.call(child.to_global(points[index])))
			child.shape.points=points
		elif child is MeshInstance3D:
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tool.set_smooth_group(-1)
			for point: Vector3 in child.mesh.get_faces(): tool.add_vertex(child.to_local(remap.call(child.to_global(point))))
			tool.generate_normals()
			child.mesh=tool.commit()
	var guide_id := "Grind_Ledge_"+id
	var author: Node3D = world.get_node(guide_id)
	var points: PackedVector3Array = author.get_meta("grind_points").duplicate()
	for index: int in points.size(): points[index]=world.to_local(remap.call(world.to_global(points[index])))
	# Publish the intended inboard downhill catch, not the perpendicular
	# perimeter cap that masks it under nearest-point tangent admission.
	# The original perimeter still owns ALL four native/display bearings below.
	var guide_points := PackedVector3Array([points[1],points[2]]) if id=="park_east_lower" else points
	author.set_meta("grind_points",guide_points)
	# Keep unit world-up authoring frames, which the contact snapshot requires.
	# Refit the existing cylinder instances and existing native cylinder shapes.
	var native: StaticBody3D = author.get_node("NativeGrindBearing")
	var visual: MultiMeshInstance3D = author.get_child(1)
	var radius := float(author.get_meta("grind_contact_radius"))
	for index: int in points.size()-1:
		var first := points[index]-Vector3.UP*radius
		var last := points[index+1]-Vector3.UP*radius
		var delta := last-first
		var orientation := Basis(Quaternion(Vector3.UP,delta.normalized()))
		visual.multimesh.set_instance_transform(index,Transform3D(orientation*Basis.from_scale(Vector3(1,delta.length(),1)),(first+last)*0.5))
		var collision: CollisionShape3D = native.get_child(index)
		collision.shape.height=delta.length()
		collision.transform=Transform3D(orientation,(first+last)*0.5)
	# Replace the old rectangular query by the exact same two graded triangles.
	# No support is left behind at the previous freestanding lawn seat.
	for index: int in range(world._terrain.patches.size()-1,-1,-1):
		if String(world._terrain.patches[index].id)==id: world._terrain.patches.remove_at(index)
	for index: int in range(world._terrain.polygons.size()-1,-1,-1):
		if String(world._terrain.polygons[index].get("id",""))==id: world._terrain.polygons.remove_at(index)
	var corners := PackedVector3Array()
	var footprint := PackedVector2Array()
	for point: Vector3 in new_top:
		var at := world.to_local(body.to_global(point))
		corners.append(at)
		footprint.append(Vector2(at.x,at.z))
	world._terrain.polygons.append({"id":id,"footprint":footprint,"points":corners,"triangles":PackedInt32Array([0,1,2,0,2,3])})
	var bounds := Rect2(footprint[0],Vector2.ZERO)
	for point: Vector2 in footprint: bounds=bounds.expand(point)
	var center := (start+finish)*0.5
	body.set_meta("support_probe",to_global(center))
	body.set_meta("rise",absf(finish.y-start.y))
	body.set_meta("run",Vector2(finish.x-start.x,finish.z-start.z).length())
	body.set_meta("width",old.size.x)
	body.set_meta("park_run_refit",{"start":start,"finish":finish,"width":old.size.x,"added_triangles":0,"added_shapes":0,"added_draws":0})
	for feature: Dictionary in world._fidelity_infill.features:
		if String(feature.id)!=id: continue
		feature.position=world.to_global(center-Vector3.UP*0.46)
		feature.floor_y=minf(start.y,finish.y)-0.46
		feature.bounds=bounds
		feature.line=guide_points.duplicate()
		feature.approach=PackedVector3Array([world.to_global(start-(finish-start).normalized()*7-Vector3.UP*0.46),world.to_global(start-Vector3.UP*0.46)])
		feature.landing=PackedVector3Array([world.to_global(finish-Vector3.UP*0.46),world.to_global(finish+(finish-start).normalized()*7-Vector3.UP*0.46)])
		feature.review_from=world.to_global(start-(finish-start).normalized()*7+Vector3.UP*2.5)
		feature.review_target=world.to_global(center)


func get_park_skatepark_definition() -> Dictionary:
	if not is_instance_valid(_skatepark): return {}
	return {"id":"kelvingrove_sunken_skatepark", "label":"Kelvingrove Sunken Skatepark",
		"bounds":SKATEPARK_BOUNDS, "rim_y":14.5, "entry":to_global(SKATEPARK_ENTRY),
		"position":to_global(SKATEPARK_ORIGIN), "access_bounds":SKATEPARK_ACCESS_BOUNDS,
		"access_route":_skatepark_access_points(), "node_path":get_path_to(_skatepark)}


func get_gap_definitions() -> Array[Dictionary]:
	return [{"id": "clyde_bridge_transfer", "name": "Clyde Broken Bridge", "start": to_global(Vector3(Layout.TRANSFER_X, 3.05, 92)), "end": to_global(Vector3(Layout.TRANSFER_X, 2.69, 104)), "radius": 2.4, "points": 900, "airborne_required": true}]


func get_route_definitions() -> Array[Dictionary]:
	var routes: Array[Dictionary] = []
	for source: Dictionary in _routes:
		var route := source.duplicate()
		var points := PackedVector3Array()
		for at: Vector3 in source.points: points.append(to_global(at))
		route.points = points
		if source.has("map_marker"): route.map_marker = to_global(source.map_marker)
		routes.append(route)
	return routes


func _skatepark_access_points() -> PackedVector3Array:
	var points := PackedVector3Array([Vector3(-173,17,-182.5),Vector3(-179,17,-182.5),
		Vector3(-183.25,15.75,-182.5),SKATEPARK_ENTRY])
	for i in points.size(): points[i] = to_global(points[i])
	return points


func _build_sunken_skatepark() -> void:
	if _skatepark_source == null: return
	_skatepark = _skatepark_source.new()
	_skatepark.name = "KelvingroveSunkenSkatepark"
	_skatepark.position = SKATEPARK_ORIGIN
	add_child(_skatepark)
	_skatepark.apply_finishes(_materials)
	var points := _skatepark_access_points()
	for i in points.size(): points[i] = to_local(points[i])
	# The approach fits inside the existing five-metre summit apron and widens
	# into the facility's six-metre entry. No mandatory pop or stair is needed.
	_path("KelvingroveSkateparkSummitAccess",points,4.5,_material("cut_stone"),"stone")
	_route("kelvingrove_summit_skatepark","Summit to sunken skatepark",points)
	_routes[-1].map_marker = SKATEPARK_ENTRY
	_routes[-1].map_label = "SUNKEN SKATEPARK"
	_routes[-1].map_kind = "skatepark"
	for raw: Dictionary in _skatepark.get_safety_routes():
		var route := raw.duplicate(true)
		var local_points := PackedVector3Array()
		for at: Vector3 in raw.points: local_points.append(to_local(at))
		route.points = local_points
		_routes.append(route)
	_skatepark_entrance_sign()


func _skatepark_entrance_sign() -> void:
	var center := Vector3(-175,18.6,-180.6)
	var direction := Vector3(1,0,-1).normalized()
	for side: float in [-1.0,1.0]:
		var top := center+direction*side*1.3+Vector3.UP*0.3
		var ground := _local_ground(top.x,top.z)
		if is_finite(ground):
			_beam("SkateparkWayfindingPost",Vector3(top.x,ground,top.z),top,0.045,_material("iron"),true)
	var board := _box("SkateparkWayfindingBoard",center,Vector3(3.4,0.9,0.12),_material("teal"),true)
	board.rotation.y = PI*0.25
	var label := Label3D.new()
	label.name = "SkateparkEntranceDirections"
	label.text = "SUNKEN SKATEPARK  →\nBOWLS · STREET · ROLL-IN"
	label.position = center+Vector3(1,0,1).normalized()*0.071
	label.rotation.y = PI*0.25
	label.font_size = 36
	label.pixel_size = 0.0055
	label.modulate = Color("e1d9bd")
	label.outline_size = 0
	add_child(label)


func _build_clyde() -> void:
	_patch("ClydeNorthQuay", Layout.NORTH_QUAY, 2.0, _material("paving"))
	_patch("ClydeSouthQuay", Layout.SOUTH_QUAY, 2.0, _material("paving"))
	var west := PackedVector3Array([Vector3(-94, 2, 45), Vector3(-94, 2, 55), Vector3(-78, 2, 67)])
	var east := PackedVector3Array([Vector3(94, 0, 45), Vector3(94, 2, 55), Vector3(78, 2, 67)])
	_path("ClydeWestApproach",west,16.0,_material("asphalt"),"asphalt")
	_path("ClydeEastApproach",east,16.0,_material("asphalt"),"asphalt")
	Surface.trim_visual_rect(get_node("ClydeWestApproach"),Layout.NORTH_QUAY)
	Surface.trim_visual_rect(get_node("ClydeEastApproach"),Layout.NORTH_QUAY)
	var safe := PackedVector3Array([Vector3(Layout.SAFE_X, 2, 72), Vector3(Layout.SAFE_X, 3.4, 89), Vector3(Layout.SAFE_X, 3.4, 105), Vector3(Layout.SAFE_X, 2, 122)])
	_path("ClydeSafeBridge", safe, 8.0, _material("iron"), "metal")
	var north := PackedVector3Array([Vector3(Layout.TRANSFER_X, 2, 74), Vector3(Layout.TRANSFER_X, 2.6, 86), Vector3(Layout.TRANSFER_X, 3.2, 94)])
	var south := PackedVector3Array([Vector3(Layout.TRANSFER_X, 2.8, 102), Vector3(Layout.TRANSFER_X, 2, 116), Vector3(Layout.TRANSFER_X, 2, 124)])
	_path("ClydeBridgeNorthDeck", north, 5.0, _material("iron"), "metal")
	_path("ClydeBridgeSouthDeck", south, 5.0, _material("iron"), "metal")
	# Retaining masonry leaves the water visibly below skateable quays.
	_box("NorthEmbankment", Vector3(0, -0.2, 77.6), Vector3(170, 4.4, 0.8), _material("cut_stone"))
	_box("SouthEmbankment", Vector3(18.5, -0.2, 116.4), Vector3(115, 4.4, 0.8), _material("cut_stone"))
	_clyde_yard = PackedVector3Array([Vector3(Layout.TRANSFER_X,2,124), Vector3(41.0,2,137), Vector3(63.0,2,124), Vector3(30.0,2,122), Vector3(Layout.TRANSFER_X,2,124)])
	_path("ClydePrintYard", _clyde_yard, 8.0, _material("paving"))
	# The compact urban yard has one flush Y2 floor, not a raised road ribbon
	# over low grass. Keep route/collision data; remove duplicate coplanar art.
	for child: Node in get_node("ClydePrintYard").get_children():
		if child is MeshInstance3D: child.free()
	_box("PrintYardPlanter", Vector3(43.0,2.35,127), Vector3(9,0.7,5), _material("cut_stone"))
	_box("PrintYardSoil", Vector3(41.0,2.73,127), Vector3(3.0,0.08,4.4), _material("bark"), false)
	var hip_bounds := Rect2(43, 126, 4.5 + YARD_BANK_RUN, 3.5 + YARD_BANK_RUN)
	var hip_body := Surface.terrain(self, "PrintYardCurvedBankHip", hip_bounds, 0.25, _yard_hip_height, _material("cut_stone"))
	hip_body.add_to_group("curved_banks")
	hip_body.set_meta("max_angle_degrees", 35.0)
	hip_body.set_meta("radius", YARD_BANK_RADIUS)
	_surfaces.append({"bounds": hip_bounds, "height_at": _yard_hip_height, "spacing":0.25})
	var hip_route := PackedVector3Array([Vector3(54.0,2,127.5), Vector3(47.5 + YARD_BANK_RUN,2,127.5)])
	for degrees: float in [5.0,10.0,15.0,20.0,25.0,30.0,35.0]:
		var angle := deg_to_rad(degrees)
		hip_route.append(Vector3(47.5 + YARD_BANK_RUN - 4.0 * sin(angle), 2.0 + 4.0 * (1.0 - cos(angle)), 127.5))
	hip_route.append(Vector3(45.0,2 + YARD_BANK_RISE,127.5))
	hip_route.append(Vector3(45.0,2 + YARD_BANK_RISE,129.5))
	for degrees: float in [30.0,25.0,20.0,15.0,10.0,5.0,0.0]:
		var angle := deg_to_rad(degrees)
		hip_route.append(Vector3(45.0,2.0 + 4.0 * (1.0 - cos(angle)),129.5 + YARD_BANK_RUN - 4.0 * sin(angle)))
	hip_route.append(Vector3(45.0,2,135.5))
	_route("clyde_print_yard_hip", "Print-yard curved bank and hip", hip_route)
	_rail("clyde_print_yard_ledge", PackedVector3Array([Vector3(38.3,2.77,124.4), Vector3(47.7,2.77,124.4)]), "ledge", 0.16)
	_water()
	var bank_material := _material("paving")
	var bank_bounds := Layout.YARD_GROUND
	var yard_ground := Surface.terrain(self, "ClydePrintYardGround", bank_bounds, 5.0, _yard_ground_height, bank_material)
	# The hip includes flat toe triangles. Its complete display owns that
	# footprint; duplicate Y2 paving underneath would shimmer after flattening
	# the yard. Keep all support/collision; subtract displayed faces only.
	Surface.trim_visual_rect(yard_ground,hip_bounds)
	Surface.trim_visual_rect(get_node("ClydeSouthQuay"),hip_bounds)
	# The optional landing's flat metal run-out is also flush with this quay.
	Surface.trim_visual_rect(get_node("ClydeBridgeSouthDeck"),Layout.SOUTH_QUAY)
	_surfaces.append({"bounds": bank_bounds, "height_at": _yard_ground_height, "spacing":5.0})
	_bridge_structure(safe, 8.0, true)
	_bridge_structure(north, 5.0, false)
	_bridge_structure(south, 5.0, false)
	# Low coping is readable from the quay and accessible to ordinary ollies.
	_rail("clyde_quay_coping", PackedVector3Array([Vector3(-69, 2.42, 76.7), Vector3(-38, 2.42, 76.7)]), "coping", 0.22)
	_rail("clyde_bridge_rail", PackedVector3Array([Vector3(Layout.TRANSFER_X+2.2, 3.25, 80), Vector3(Layout.TRANSFER_X+2.2, 3.55, 86), Vector3(Layout.TRANSFER_X+2.2, 4.0, 92)]), "rail", 0.065)
	for x: float in [-76.0,-58.0,-8.0,8.0,44.0,66.0,79.0]:
		_bollard(Vector3(x, 2.0, 75.0))
	for x: float in [-73.0,8.0,70.0]:
		_bench(Vector3(x, 2.0, 59.0))
	_route("clyde_north_quay", "Station to Barras via Clyde", PackedVector3Array([
		Vector3(-94,2,45),Vector3(-94,2,55),Vector3(-78,2,67),Vector3(-78,2,69),
		Vector3(78,2,69),Vector3(78,2,67),Vector3(94,2,55),
		# Real shared triangle diagonal splits the bent grade into its two planes.
		Vector3(94,1.105744513,47.927252054),Vector3(94,0,45)]))
	var safe_route := PackedVector3Array([Vector3(Layout.SAFE_X, 2, 67)])
	safe_route.append_array(safe)
	safe_route.append(Vector3(Layout.SAFE_X, 2, 125))
	_route("clyde_safe_crossing", "Clyde continuous crossing", safe_route)
	var transfer := PackedVector3Array([Vector3(Layout.TRANSFER_X, 2, 65)])
	transfer.append_array(north)
	transfer.append_array(south)
	_route("clyde_bridge_transfer", "Clyde eight-metre transfer", transfer, true)
	# Publish the real south-bank return too: otherwise the route map depicts
	# the continuous bridge as a dead end disconnected from the yard circuit.
	var yard_return := PackedVector3Array([Vector3(Layout.SAFE_X,2,125),Vector3(Layout.SAFE_X,2,124)])
	yard_return.append_array(_clyde_yard)
	yard_return.append_array(PackedVector3Array([Vector3(Layout.SAFE_X,2,124),Vector3(Layout.SAFE_X,2,125)]))
	_route("clyde_print_yard_loop", "Clyde print-yard loop and safe bridge return", yard_return)


func _build_park() -> void:
	_park_connector = Surface.smooth_points(PackedVector3Array([Vector3(-145, 2, 0), Vector3(-151, 3, -22), Vector3(-147, 4.5, -48), Vector3(-155, 6, -82)]))
	_george_connector = PackedVector3Array([Vector3(-42, 6, -122), Vector3(-145, 6, -125)])
	_park_cutback = Surface.smooth_points(PackedVector3Array([Vector3(-208,11,-126), Vector3(-226,10,-111), Vector3(-210,8,-86), Vector3(-185,6.5,-70), Vector3(-162,5,-54), Vector3(-147,4.5,-48)]))
	_park_path = Surface.smooth_points(PackedVector3Array([
		Vector3(-155, 6, -82), Vector3(-173, 7, -96), Vector3(-195, 9, -106), Vector3(-208, 11, -126), Vector3(-200, 13, -147), Vector3(-181, 15, -164), Vector3(-161, 17, -178), Vector3(-146, 15, -165), Vector3(-145, 11, -146), Vector3(-145, 6, -125), Vector3(-145, 6, -104), Vector3(-155, 6, -82)]))
	# The viewpoint spur and terrace share this summit datum. Flatten the
	# overlapping loop footprint too; a flat spur over a descending ribbon
	# otherwise leaves a real 73mm step across the riding line.
	# Shared branch mouths use one grade; independently smoothed ribbons
	# otherwise intersect as small ramps/ledges across the riding direction.
	for path: PackedVector3Array in [_park_connector,_park_path,_park_cutback]:
		for i in path.size():
			for junction: Vector3 in [Vector3(-147,4.5,-48),Vector3(-155,6,-82)]:
				var distance := Vector2(path[i].x-junction.x,path[i].z-junction.z).length()
				var point := path[i]
				point.y=lerpf(junction.y,point.y,smoothstep(7.0,14.0,distance))
				path[i]=point
	var summit := Rect2(-181,-187,24,11)
	for index in _park_path.size():
		var point := _park_path[index]
		var closest := Vector2(clampf(point.x,summit.position.x,summit.end.x),clampf(point.z,summit.position.y,summit.end.y))
		var blend := 1.0-smoothstep(0.0,5.0,Vector2(point.x,point.z).distance_to(closest))
		point.y = lerpf(point.y,17.0,blend)
		_park_path[index] = point
	# A level fork apron joins the two graded branches without overlapping lips.
	for path: PackedVector3Array in [_park_path, _park_cutback]:
		for index in path.size():
			var distance := Vector2(path[index].x + 208, path[index].z + 126).length()
			var at := path[index]
			at.y = lerpf(11.0, at.y, smoothstep(6.0, 14.0, distance))
			path[index] = at
	var grass := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);vec2 u=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),u.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),u.x),u.y);}
void fragment(){
	// Keep detail broad enough to remain stable across the Mac and GL renderer.
	// Sub-10cm hash cells shimmer and alias on this large, shallow landscape.
	vec2 p=world_position.xz;
	float patches=noise(p*0.12)*0.68+noise(p*0.38)*0.32;
	float shade=0.96+0.04*sin(dot(p,vec2(0.037,0.051)));
	ALBEDO=mix(vec3(0.20,0.27,0.14),vec3(0.29,0.35,0.20),patches)*shade;
	ROUGHNESS=0.98;
	SPECULAR=0.08;
}
"""
	grass.shader = shader
	var excavations: Array[Rect2] = []
	if _skatepark_source != null: excavations.append(SKATEPARK_BOUNDS)
	Surface.terrain(self, "KelvingroveRollingGround", PARK_LANDSCAPE, 2.5, _park_height, grass, excavations)
	# The approaches are raised park embankments, not unsupported road ribbons.
	var central_bank := Rect2(-215, -60, 85, 80)
	var east_bank := Rect2(-140,-92.5,10,32.5)
	var george_bank := Rect2(-145, -142, 103, 34)
	var central_ground := Surface.terrain(self, "KelvingroveCentralEmbankment", central_bank, 2.5, _central_bank_height, grass)
	# The old central grid overlapped the rolling grid across32m of hillside.
	# Keep a disjoint L footprint, merged into the same resident body/surface.
	var eastern := Surface.terrain(self,"ParkEastBankConstruction",east_bank,2.5,_central_bank_height,grass)
	var joined := SurfaceTool.new();joined.begin(Mesh.PRIMITIVE_TRIANGLES)
	joined.append_from(central_ground.get_child(0).mesh,0,Transform3D.IDENTITY)
	joined.append_from(eastern.get_child(0).mesh,0,Transform3D.IDENTITY)
	central_ground.get_child(0).mesh=joined.commit()
	central_ground.get_child(1).shape.set_faces(central_ground.get_child(0).mesh.get_faces())
	eastern.free()
	_fill_enclosed_ground(central_ground)
	Surface.terrain(self, "KelvingroveGeorgeEmbankment", george_bank, 3.0, _george_bank_height, grass)
	_surfaces.append({"bounds": central_bank, "height_at": _central_bank_height, "spacing":2.5})
	_surfaces.append({"bounds": east_bank, "height_at": _central_bank_height, "spacing":2.5})
	_surfaces.append({"bounds": george_bank, "height_at": _george_bank_height, "spacing":3.0})
	# Broad smooth asphalt ribbons share exact sampled physics/query coordinates.
	_path("KelvingroveCentralApproach", _park_connector, 10.0, _material("asphalt"))
	_path("KelvingroveGeorgePromenade", _george_connector, 10.0, _material("paving"))
	_path("KelvingroveRollingLoop", _park_path, 8.0, _material("asphalt"))
	_path("KelvingroveCutbackReturn", _park_cutback, 8.0, _material("asphalt"))
	var hip := PackedVector3Array([Vector3(-224,8.0,-91), Vector3(-226,9.1,-84), Vector3(-220,8.4,-78)])
	_path("KelvingroveCutbackHip", hip, 4.5, _material("paving"))
	_rail("kelvingrove_cutback_ledge", PackedVector3Array([Vector3(-227.2,9.28,-84), Vector3(-221.2,8.58,-78)]), "ledge", 0.18)
	_legacy_edge_construction = true
	_path_border(_park_path)
	_legacy_edge_construction = false
	# Upper viewpoint sits off the riding line and is reached at the summit.
	_patch("KelvingroveViewTerrace", Rect2(-179, -185, 18, 5), 17.0, _material("paving"))
	_path("KelvingroveViewpointSpur", PackedVector3Array([Vector3(-161, 17, -178), Vector3(-165, 17, -182), Vector3(-173, 17, -182)]), 4.0, _material("paving"))
	_separate_summit_finishes()
	Surface.solidify_perimeter(get_node("KelvingroveViewTerrace"),PackedVector3Array([
		Vector3(-179,17,-185),Vector3(-161,17,-185),Vector3(-161,17,-180),
		Vector3(-179,17,-180),Vector3(-179,17,-185)]),_park_resident_ground,_material("cut_stone"))
	Surface.solidify_strip(get_node("KelvingroveViewpointSpur"),_park_resident_ground,_material("cut_stone"),[Rect2(-179,-185,18,5)])
	_rail("kelvingrove_terrace_coping", PackedVector3Array([Vector3(-177, 17.4, -184), Vector3(-164, 17.4, -184)]), "coping", 0.2)
	var bend := PackedVector3Array()
	var bend_piece := 0
	for at: Vector3 in _park_path:
		var edge := at + Vector3(-3.3, 0.55, 0)
		var branch := Surface.nearest_segment(_park_cutback, Vector2(edge.x, edge.z))
		if at.x < -201 and at.z < -113 and at.z > -139 and float(branch.distance) > 6.0:
			bend.append(edge)
		else:
			if bend.size() >= 2:
				_rail("kelvingrove_s_bend_" + str(bend_piece), bend, "rail", 0.065)
				bend_piece += 1
			bend = PackedVector3Array()
	if bend.size() >= 2: _rail("kelvingrove_s_bend_" + str(bend_piece), bend, "rail", 0.065)
	_park_pavilion()
	_build_sunken_skatepark()
	var trees: Array[Dictionary] = []
	for row in 11:
		for col in 8:
			var x := -247.0 + col * 13.5 + sin(row * 5.13 + col) * 2.7
			var z := -217.0 + row * 14.5 + cos(col * 4.1 + row) * 2.5
			if _skatepark_source != null and (SKATEPARK_BOUNDS.grow(4.0).has_point(Vector2(x,z)) or SKATEPARK_ACCESS_BOUNDS.grow(2.0).has_point(Vector2(x,z))): continue
			# Preserve the two small graded ledge clearings beside the existing
			# loop; tree silhouettes still frame their outer edge, not the line.
			if Rect2(-190,-93,16,7.2).has_point(Vector2(x,z)) or Rect2(-197,-175,17,7.2).has_point(Vector2(x,z)) or Rect2(-162,-158,13,7.2).has_point(Vector2(x,z)): continue
			if Rect2(-158,-143,7.2,14).has_point(Vector2(x,z)): continue
			if Rect2(-157,-119,7.2,14).has_point(Vector2(x,z)): continue
			var nearest := Surface.nearest_segment(_park_path, Vector2(x, z))
			var central := Surface.nearest_segment(_park_connector, Vector2(x, z))
			var george := Surface.nearest_segment(_george_connector, Vector2(x, z))
			var cutback := Surface.nearest_segment(_park_cutback, Vector2(x, z))
			if minf(minf(float(nearest.distance), float(cutback.distance)), minf(float(central.distance), float(george.distance))) < 8.0 or (x > -184 and z < -172): continue
			trees.append({"position": Vector3(x, _park_height(x, z), z), "scale": 0.78 + fmod(row * 0.13 + col * 0.21, 0.36), "yaw": row * 1.7 + col * 0.7})
	Vegetation.build(self, trees, _material("bark"))
	_route("kelvingrove_central_climb", "Central to Kelvingrove", _park_connector)
	_route("kelvingrove_george_promenade", "George Square park promenade", _george_connector)
	_route("kelvingrove_rolling_loop", "Kelvingrove hillside loop", _park_path)
	_route("kelvingrove_cutback_return", "Kelvingrove cutback to Central", _park_cutback)


## One displayed owner per summit face: terrace, then connecting spur, then
## granite shoulder, then asphalt. Keep every native top triangle unchanged.
func _separate_summit_finishes() -> void:
	var terrace := Rect2(-179,-185,18,5)
	var spur: StaticBody3D=get_node("KelvingroveViewpointSpur")
	var loop: StaticBody3D=get_node("KelvingroveRollingLoop")
	var vertices: PackedVector3Array=spur.get_meta("support_vertices")
	Surface.trim_visual_rect(spur,terrace)
	Surface.trim_visual_rect(loop,terrace)
	for i in range(0,vertices.size()-2,2):
		Surface.trim_visual_polygon(loop,PackedVector2Array([
			Vector2(vertices[i].x,vertices[i].z),Vector2(vertices[i+1].x,vertices[i+1].z),
			Vector2(vertices[i+3].x,vertices[i+3].z),Vector2(vertices[i+2].x,vertices[i+2].z)]))
	for body: Node in get_children():
		if not body is StaticBody3D or str(body.get_meta("art_label",""))!="ParkGranitePathEdge":continue
		# Only the independently levelled summit facets are coplanar. Retain
		# all existing grades and material coverage elsewhere on the hillside.
		var original: PackedVector3Array=body.get_child(0).mesh.get_faces()
		for i in range(0,original.size(),3):
			if absf(original[i].y-17)>.0001 or absf(original[i+1].y-17)>.0001 or absf(original[i+2].y-17)>.0001:continue
			Surface.trim_visual_polygon(loop,PackedVector2Array([
				Vector2(original[i].x,original[i].z),Vector2(original[i+1].x,original[i+1].z),Vector2(original[i+2].x,original[i+2].z)]))
		Surface.trim_visual_rect(body,terrace)
		for i in range(0,vertices.size()-2,2):
			Surface.trim_visual_polygon(body,PackedVector2Array([
				Vector2(vertices[i].x,vertices[i].z),Vector2(vertices[i+1].x,vertices[i+1].z),
				Vector2(vertices[i+3].x,vertices[i+3].z),Vector2(vertices[i+2].x,vertices[i+2].z)]))


## The retained streets used to surround an unbuilt L-shaped hole. Keep the
## fences/ports, but give their enclosed planted ground real visible support.
## Append six collision triangles to the resident trimesh at startup: no new
## draw, node, material, collision body/shape or per-frame work.
func _fill_enclosed_ground(body: StaticBody3D) -> void:
	var collision := body.get_child(1) as CollisionShape3D
	var shape := collision.shape as ConcavePolygonShape3D
	var faces := shape.get_faces()
	for bounds: Rect2 in ENCLOSED_GROUND:
		var a := Vector3(bounds.position.x,0.5,bounds.position.y)
		var b := Vector3(bounds.end.x,0.5,bounds.position.y)
		var c := Vector3(bounds.end.x,0.5,bounds.end.y)
		var d := Vector3(bounds.position.x,0.5,bounds.end.y)
		faces.append_array(PackedVector3Array([a,b,c,a,c,d]))
		_surfaces.append({"bounds":bounds,"height":0.5})
	# No temporary rendering mesh/upload is needed for these physical faces.
	# HorizonContext draws the same land with its resident vertex-colour surface.
	shape.set_faces(faces)


func _build_riverside_edge(_world: Node3D) -> void:
	# Original, researched bridge/terrace geometry replaces the generic shop row.
	# It adds no collision or grind path; tested routes remain authoritative.
	ClydeLandmarks.build(self, _materials)
	# The old generic facades were solid. Keep the new joined houses solid too,
	# matching their actual footprints instead of retaining hidden old boxes.
	for block: Vector2 in Layout.TERRACE_BLOCKS:
		var body := StaticBody3D.new()
		body.name = "CarltonPlaceBoundary"
		body.set_meta("art_label", "CarltonPlaceFacade")
		body.position = Vector3(block.x,7.5,151.4)
		var shape := BoxShape3D.new()
		shape.size = Vector3(block.y,13.0,12.0)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _yard_hip_height(x: float, z: float) -> float:
	var distance := Vector2(maxf(0.0, x - 47.5), maxf(0.0, z - 129.5)).length()
	var toward_deck := clampf(YARD_BANK_RUN - distance, 0.0, YARD_BANK_RUN)
	return 2.0 + YARD_BANK_RADIUS - sqrt(maxf(0.0, YARD_BANK_RADIUS * YARD_BANK_RADIUS - toward_deck * toward_deck))


func _yard_ground_height(_x: float, _z: float) -> float:
	# Flat supported work yard meets the quay and native hip toe exactly.
	# The old 1.8m grass trough trapped ordinary riders against a 20cm lip.
	return 2.0


func _central_bank_height(x: float, z: float) -> float:
	var nearest := Surface.nearest_segment(_park_connector, Vector2(x, z))
	var cutback := Surface.nearest_segment(_park_cutback, Vector2(x, z))
	if float(cutback.distance) < float(nearest.distance): nearest = cutback
	# Grass meets the asphalt shoulder within wheel clearance. The previous
	# constant35cm depression created a kerb on both sides of every approach.
	var clearance := _park_shoulder_clearance(nearest,0.35)
	var original := lerpf(float(nearest.height) - clearance, 0.5, smoothstep(7.0, 15.0, float(nearest.distance)))
	var at:=Vector2(x,z)
	var seam:=Vector2(clampf(x,PARK_LANDSCAPE.position.x,PARK_LANDSCAPE.end.x),clampf(z,PARK_LANDSCAPE.position.y,PARK_LANDSCAPE.end.y))
	var distance:=at.distance_to(seam)
	if distance<8.0:return lerpf(_park_height(seam.x,seam.y),original,smoothstep(0.0,8.0,distance))
	return original


func _george_bank_height(x: float, z: float) -> float:
	var nearest := Surface.nearest_segment(_george_connector, Vector2(x, z))
	var height := lerpf(5.98, 0.5, smoothstep(6.0, 15.5, float(nearest.distance)))
	# Extend the existing promenade into a supported skate apron. Its grass
	# shoulders blend back into the old embankment instead of hiding a slab void.
	var nearest_apron := Vector2(clampf(x, PRACTICE_APRON.position.x, PRACTICE_APRON.end.x), clampf(z, PRACTICE_APRON.position.y, PRACTICE_APRON.end.y))
	var distance := Vector2(x, z).distance_to(nearest_apron)
	height = maxf(height, lerpf(5.98, height, smoothstep(3.0, 6.0, distance)))
	# The western embankment joins the rolling hillside, not a second low
	# plate underneath it. Sample the actual neighbouring native triangles.
	if x < -132.0:
		var seam := Surface.grid_height(PARK_LANDSCAPE,2.5,_park_height,-140.0,z)
		height = lerpf(seam,height,smoothstep(-140.0,-132.0,x))
	return height


func _park_height(x: float, z: float) -> float:
	# Static grid vertices are shared by terrain, support queries and visual
	# fitting. Reuse their exact result rather than repeatedly evaluating every
	# nearest-path segment during level construction.
	var key := Vector2(x,z)
	if _park_height_cache.has(key): return _park_height_cache[key]
	var height := _park_facility_collar(x,z,_park_route_height(x,z))
	# Keep every coarse terrain triangle under the shared summit paving, not
	# just height-function samples at its centre. A five-metre shoulder covers
	# the complete native grid cell across the spur/loop intersection.
	var summit := Rect2(-181,-187,24,11)
	var nearest := Vector2(clampf(x,summit.position.x,summit.end.x),clampf(z,summit.position.y,summit.end.y))
	var distance := Vector2(x,z).distance_to(nearest)
	if distance<8.0:height=minf(height,16.75+maxf(0.0,distance-5.0)*0.6)
	_park_height_cache[key] = height
	return height


func _park_facility_collar(x: float,z: float,existing: float) -> float:
	if _skatepark_source == null: return existing
	var at := Vector2(x,z)
	var nearest := Vector2(clampf(x,SKATEPARK_BOUNDS.position.x,SKATEPARK_BOUNDS.end.x),
		clampf(z,SKATEPARK_BOUNDS.position.y,SKATEPARK_BOUNDS.end.y))
	var distance := at.distance_to(nearest)
	if distance>=8.0: return existing
	# Existing lap asphalt and its three-metre gates are outside the cut. Do
	# not regrade the preserved riding corridor to make a new facility fit.
	for route: PackedVector3Array in [_park_path,_park_cutback,_park_connector,_george_connector]:
		if float(Surface.nearest_segment(route,at).distance)<6.0: return existing
	return lerpf(SKATEPARK_ORIGIN.y,existing,smoothstep(0.0,8.0,distance))


func _park_route_height(x: float, z: float) -> float:
	var original := _park_natural_height(x,z)
	var nearest := Surface.nearest_segment(_bank_cut_grade,Vector2(x,z))
	if not nearest.get("within",true) or float(nearest.distance)>=10.0: return original
	# The grass cut formerly climbed irregular noise/nearest-path facets that
	# could pin an ordinary pushing capsule. A broad graded core follows the
	# same gates; smooth shoulders retain the surrounding rolling landscape.
	var height := lerpf(float(nearest.height),original,smoothstep(4.5,10.0,float(nearest.distance)))
	# Existing asphalt remains the authoritative riding surface. Keep this
	# grading below each road and limit the bank rising beside its edge.
	for route: Dictionary in [
		{"points":_park_path,"half":4.0},{"points":_park_cutback,"half":4.0},
		{"points":_park_connector,"half":5.0},{"points":_george_connector,"half":5.0}]:
		var road := Surface.nearest_segment(route.points,Vector2(x,z))
		if not road.get("within",true): continue
		if float(road.distance)<float(route.half)+10.0:
			height = minf(height,float(road.height)-0.04+maxf(0,float(road.distance)-float(route.half)-0.4)*0.5)
	return height


func _park_natural_height(x: float, z: float) -> float:
	var rise := clampf((-z - 80.0) / 100.0, 0.0, 1.0)
	var natural := 6.0 + rise * 10.0 + sin(x * 0.09 + z * 0.03) * 1.15 + sin(z * 0.12) * 0.65
	var nearest := Surface.nearest_segment(_park_path, Vector2(x, z))
	for path: PackedVector3Array in [_park_connector, _george_connector, _park_cutback]:
		var candidate := Surface.nearest_segment(path, Vector2(x, z))
		if float(candidate.distance) < float(nearest.distance): nearest = candidate
	var distance: float = nearest.distance
	var weight := smoothstep(6.0, 13.0, distance)
	var height := lerpf(float(nearest.height) - _park_shoulder_clearance(nearest,0.25), natural, weight)
	# Flatten the summit apron into the hillside, not a floating slab.
	if x >= -181 and x <= -159 and z <= -178:
		var apron := Rect2(-179, -185, 18, 5)
		var distance_apron := Vector2(x, z).distance_to(Vector2(clampf(x, apron.position.x, apron.end.x), clampf(z, apron.position.y, apron.end.y)))
		height = minf(height, lerpf(16.75, height, smoothstep(0.0, 3.0, distance_apron)))
	# Blend the north/west woodland skirts continuously. A conditional applied
	# to all four rectangle edges previously produced a~16m discontinuity where
	# its north cutoff met the east edge, despite looking like ordinary grass.
	var woodland := minf(smoothstep(-255.0,-225.0,x),smoothstep(-225.0,-195.0,z))
	height = lerpf(1.0 + sin(x * 0.025 + z * 0.014),height,woodland)
	return height


func _park_shoulder_clearance(nearest: Dictionary, interior_clearance: float) -> float:
	# Preserve the flush lateral shoulder and exterior end caps. Under the
	# road's interior, retain enough clearance for a coarse terrain triangle
	# spanning a changing road grade; otherwise its chord can rise through the
	# asphalt even though each nearest-height vertex looked safe in isolation.
	if not nearest.get("within",true): return 0.02
	var clearance := lerpf(interior_clearance,0.02,smoothstep(2.0,3.0,float(nearest.distance)))
	# A cap's adjacent coarse cell also needs the shared entry datum, even
	# when its individual vertices project a little inside the first segment.
	return lerpf(0.02,clearance,smoothstep(4.0,8.0,float(nearest.get("endpoint_distance",INF))))


func _local_ground(x: float, z: float) -> float:
	var at := Vector2(x, z)
	var excavated := _skatepark_source != null and SKATEPARK_BOUNDS.has_point(at)
	var highest := Surface.grid_height(PARK_LANDSCAPE,2.5,_park_height,x,z) if PARK_LANDSCAPE.has_point(at) and not excavated else NAN
	if is_instance_valid(_skatepark):
		var feature_height: float = _skatepark.get_surface_height(to_global(Vector3(x,0,z)))
		if is_finite(feature_height): highest = feature_height-global_position.y if is_nan(highest) else maxf(highest,feature_height-global_position.y)
	for surface: Dictionary in _surfaces:
		var height := NAN
		if surface.has("edge_triangles"):
			if not surface.bounds.has_point(at): continue
			for triangle: PackedVector3Array in surface.edge_triangles:
				height = _triangle_support_height(triangle,at)
				if is_nan(height): continue
				break
		elif surface.has("strip_sections"):
			if not surface.bounds.has_point(at): continue
			for section: Dictionary in surface.strip_sections:
				if not section.bounds.has_point(at): continue
				for triangle: PackedVector3Array in section.triangles:
					var found := _triangle_support_height(triangle,at)
					if is_nan(found): continue
					if is_nan(height) or found>height: height = found
		elif surface.has("bounds"):
			if surface.bounds.has_point(at): height = Surface.grid_height(surface.bounds,surface.spacing,surface.height_at,x,z) if surface.has("height_at") else surface.height
		else:
			height = Surface.strip_height(surface.support_vertices,at)
		if is_finite(height) and (is_nan(highest) or height > highest): highest = height
	if not is_nan(highest): return highest
	return NAN


func _triangle_support_height(triangle: PackedVector3Array,at: Vector2) -> float:
	# Include shared edges. Geometry2D's strict interior predicate can reject
	# both adjacent faces at an exact waypoint/diagonal and return lower grass.
	var a := Vector2(triangle[0].x,triangle[0].z)
	# Keep the already verified shoulder collision construction identical.
	# Inclusive shared-edge support is a query fix, not permission to rebuild
	# the old trim into new collision while addressing its visual material.
	if _legacy_edge_construction and not Geometry2D.point_is_inside_triangle(at,a,
		Vector2(triangle[1].x,triangle[1].z),Vector2(triangle[2].x,triangle[2].z)): return NAN
	var ab := Vector2(triangle[1].x,triangle[1].z)-a
	var ac := Vector2(triangle[2].x,triangle[2].z)-a
	var determinant := ab.cross(ac)
	if absf(determinant)<0.000000001: return NAN
	var relative := at-a
	var u := relative.cross(ac)/determinant
	var v := ab.cross(relative)/determinant
	if u < -0.00001 or v < -0.00001 or u+v > 1.00001: return NAN
	return triangle[0].y*(1-u-v)+triangle[1].y*u+triangle[2].y*v


func _patch(id: String, bounds: Rect2, height: float, material: Material) -> void:
	Surface.terrain(self, id, bounds, 5.0, func(_x: float, _z: float) -> float: return height, material)
	_surfaces.append({"bounds": bounds, "height": height})


## Terrain below the raised paving, excluding roads and terraces themselves.
## Using _local_ground here would sample the very deck whose sides need filling.
func _park_resident_ground(x: float,z: float) -> float:
	var at := Vector2(x,z)
	var highest := Surface.grid_height(PARK_LANDSCAPE,2.5,_park_height,x,z) if PARK_LANDSCAPE.has_point(at) else NAN
	for surface: Dictionary in _surfaces:
		if not surface.has("height_at") or not surface.bounds.has_point(at): continue
		var height := Surface.grid_height(surface.bounds,surface.spacing,surface.height_at,x,z)
		if is_nan(highest) or height>highest: highest=height
	# The angled ten-metre promenade mouth extends15cm beyond its grass
	# rectangle into the existing civic terrace; that seam is the same Y6 datum.
	if is_nan(highest) and Rect2(-145,-142,103,34).grow(0.2).has_point(at):
		highest = _george_bank_height(clampf(x,-145,-42),clampf(z,-142,-108))
	return highest


func _path(id: String, points: PackedVector3Array, width: float, material: Material, audio: String = "asphalt", visual_points: PackedVector3Array = PackedVector3Array()) -> void:
	var body := Surface.strip(self, id, points, width, material, audio, visual_points)
	if id=="KelvingroveCutbackHip":Surface.solidify_strip(body,_local_ground,_material("stone"))
	if id == "KelvingroveGeorgePromenade":
		Surface.solidify_strip(body,_park_resident_ground,_material("cut_stone"))
	if id in ["KelvingroveRollingLoop","KelvingroveCutbackReturn"]:
		var approach:StaticBody3D=get_node("KelvingroveCentralApproach")
		var vertices:PackedVector3Array=approach.get_meta("support_vertices")
		for i in range(0,vertices.size()-2,2):
			Surface.trim_visual_polygon(body,PackedVector2Array([Vector2(vertices[i].x,vertices[i].z),Vector2(vertices[i+1].x,vertices[i+1].z),Vector2(vertices[i+3].x,vertices[i+3].z),Vector2(vertices[i+2].x,vertices[i+2].z)]))
	_surfaces.append({"points": points, "width": width, "support_vertices":body.get_meta("support_vertices")})


func _route(id: String, label: String, points: PackedVector3Array, jump: bool = false) -> void:
	_routes.append({"id": id, "label": label, "points": points, "requires_jump": jump})


func _material(id: String) -> Material:
	if _materials.has(id): return _materials[id]
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color(0.3, 0.32, 0.3)
	fallback.roughness = 0.9
	return fallback


func _box(id: String, at: Vector3, size: Vector3, material: Material, colliding: bool = true) -> Node3D:
	var root: Node3D = StaticBody3D.new() if colliding else Node3D.new()
	root.name = id
	root.set_meta("art_label", id)
	root.position = at
	add_child(root)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	root.add_child(visual)
	if colliding:
		root.set_meta("surface_audio", "stone")
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		root.add_child(collision)
	return root


func _beam(id: String, a: Vector3, b: Vector3, radius: float, material: Material, colliding: bool = false) -> Node3D:
	var delta := b - a
	var piece := _box(id, (a + b) * 0.5, Vector3(radius * 2.0, radius * 2.0, delta.length()), material, colliding)
	piece.look_at(to_global(b), Vector3.UP if absf(delta.normalized().y) < 0.98 else Vector3.FORWARD)
	return piece


func _rail(id: String, points: PackedVector3Array, kind: String, radius: float) -> void:
	var line := GrindLineSource.from_local_points(id, points, global_transform, kind)
	# _beam keeps these points at the square beam centre. Its look_at uses
	# world up on ordinary grades, so the top is one radius along projected up.
	# Do not certify its different near-vertical fallback or transformed scales.
	var supported := _grind_contact_frame_supported(global_transform)
	for index: int in range(line.points.size() - 1):
		var tangent := (line.points[index + 1] - line.points[index]).normalized()
		supported = supported and tangent.is_finite() and absf(tangent.y) < 0.98
	if supported and radius > 0.0:
		# A changing-grade polyline has no single verified normal at its joints;
		# configure_contact keeps it unverified rather than averaging a new top.
		line.configure_contact(0.0, radius, "outdoors.square_beam_normal_top")
		# Bent/changing-grade beams retain generic grind contact. Their actual
		# native square half-height is independent body-clearance geometry;
		# capsule/path queries still decide whether finite joints are usable.
		if not line.contact_verified and radius<=0.10 and kind=="rail":
			line.configure_body_profile(radius,"outdoor.native_square_beam_radius")
	_rails.append(line)
	for i in range(points.size() - 1):
		# The default contact model already maps this centre guide to the real
		# projected-up crown. Preserve that datum rather than lowering it twice.
		var body: StaticBody3D
		if radius > 0.10 and kind in ["ledge", "coping"]:
			body = _rounded_stone_crown(id,points[i],points[i+1],radius)
		else:
			body = _beam(id+"NativeBeam",points[i],points[i+1],radius,
				_material("cut_stone" if kind=="coping" else "iron"),true) as StaticBody3D
		body.collision_layer = 1 | 2
		body.collision_mask = 0
		body.set_meta("surface_audio","stone" if radius>0.10 and kind in ["ledge","coping"] else "metal")
		body.set_meta("authored_grind_ids",[id])
		body.set_meta("audit_capture_ids",[id])
		body.set_meta("grind_bearing_points",PackedVector3Array([points[i],points[i+1]]))


func _rounded_stone_crown(id: String,start: Vector3,finish: Vector3,radius: float) -> StaticBody3D:
	var direction := finish-start
	var body := StaticBody3D.new()
	body.name = id+"NativeBeam"
	body.set_meta("art_label",id+"NativeBeam")
	body.position = (start+finish)*0.5
	body.basis = Basis(Quaternion(Vector3.UP,direction.normalized()))
	add_child(body)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = direction.length()
	mesh.radial_segments = 32
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material("cut_stone")
	body.add_child(visual)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = direction.length()
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	return body


func _grind_contact_frame_supported(frame: Transform3D) -> bool:
	var basis := frame.basis
	return frame.origin.is_finite() and basis.x.is_finite() and basis.y.is_finite() and basis.z.is_finite() \
		and basis.y.distance_to(Vector3.UP) < 0.00001 \
		and absf(basis.x.length_squared() - 1.0) < 0.00001 \
		and absf(basis.z.length_squared() - 1.0) < 0.00001 \
		and absf(basis.x.dot(basis.z)) < 0.00001 and absf(basis.determinant() - 1.0) < 0.00001


func _bridge_structure(points: PackedVector3Array, width: float, safe: bool) -> void:
	for side: float in [-1.0, 1.0]:
		var handrail := PackedVector3Array()
		for at: Vector3 in points:
			handrail.append(at + Vector3(side * (width * 0.5 - 0.15), 1.10, 0))
		# Each intact bridge piece has its own finite track. The broken bridge's
		# eight-metre water gap remains a real transfer, never an invisible rail.
		var bridge_id := "safe" if safe else ("north" if points[0].z < 90 else "south")
		var grind_id := "clyde_" + bridge_id + "_handrail_" + ("west" if side < 0 else "east")
		_rails.append(GrindLineSource.from_local_points(grind_id, handrail, global_transform, "rail"))
		for i in range(points.size() - 1):
			var a := points[i] + Vector3(side * (width * 0.5 - 0.15), 0, 0)
			var b := points[i + 1] + Vector3(side * (width * 0.5 - 0.15), 0, 0)
			_beam("BridgeEdgeGirder", a - Vector3.UP * 0.25, b - Vector3.UP * 0.25, 0.18, _material("iron"))
			var handrail_body := _beam("BridgeHandrail", a + Vector3.UP * 1.05, b + Vector3.UP * 1.05, 0.045, _material("iron"), true) as StaticBody3D
			if not safe:
				handrail_body.collision_layer = 1 | 2
				handrail_body.collision_mask = 0
			handrail_body.set_meta("authored_grind_ids", [grind_id])
			handrail_body.set_meta("audit_capture_ids", [grind_id])
			if safe: _beam("BridgeLowerRail", a + Vector3.UP * 0.5, b + Vector3.UP * 0.5, 0.025, _material("iron"))
			var steps := maxi(1, ceili(a.distance_to(b) / 4.0))
			for j in steps:
				var at := a.lerp(b, float(j) / steps)
				_beam("BridgePost", at, at + Vector3.UP * 1.1, 0.045, _material("iron"))
	for i in [0, points.size() - 1]:
		var at := points[i]
		_box("BridgePier", Vector3(at.x, -0.6, at.z), Vector3(width - 1.0, 4.0, 1.0), _material("cut_stone"), false)


func _build_practice_pockets() -> void:
	# A low, widened part of the existing George-to-park promenade offers a
	# second practice stop. The original through route stays on its north side.
	_patch("KelvingrovePromenadeSkateApron", PRACTICE_APRON, 6.0, _material("paving"))
	_transition("KelvingrovePromenadeQuarter", Vector3(-96,6,-130), PI * 0.5, 2.4, 8.0)
	_practice_box("PracticeLedge", Vector3(-111,6.275,-130), Vector3(6,0.55,0.7))
	_practice_box("PracticeManualPad", Vector3(-82,6.20,-135), Vector3(5,0.4,3))
	_practice_features.append({"id":"kelvingrove_promenade_practice", "district":"kelvingrove", "bounds":PRACTICE_APRON, "floor_y":6.0,
		"features":["quarter_pipe", "manual_pad", "low_ledge"],
		"approach":PackedVector3Array([Vector3(-78,6,-130),Vector3(-96,6,-130)]),
		"landing":PackedVector3Array([Vector3(-96,6,-130),Vector3(-78,6,-130)])})
	# Broad, restrained inlaid lines identify approaches without adding props
	# to the landing space. Small seams make the concrete read at board height.
	for x: float in [-115, -107, -99, -91, -83]:
		_box("ApronPavingJoint",Vector3(x,6.006,-132.75),Vector3(0.025,0.008,13.3),_material("slate"),false)
	for at: Vector3 in [Vector3(-91,6.009,-130)]:
		for offset: float in [-0.9,0.9]:
			_box("PracticeApproachInlay",at+Vector3(0,0,offset),Vector3(5,0.012,0.06),_material("cream"),false)


func _transition(id: String, at: Vector3, yaw: float, radius: float, width: float) -> void:
	var feature := TransitionFeature.new()
	feature.name = id
	feature.feature_id = id
	feature.position = at
	feature.rotation.y = yaw
	feature.radius = radius
	feature.width = width
	feature.deck_length = 3.0
	add_child(feature)
	_transitions.append(feature)


func _practice_box(label: String, at: Vector3, size: Vector3) -> void:
	var body := _box(label, at, size, _material("cut_stone"))
	body.set_meta("practice_feature", true)
	# A flush steel strip marks the usable top edge. Geometry-derived grind
	# tracks are built later from this same body's collision bounds.
	for side: float in [-1.0,1.0]:
		_box("PracticeSteelEdge", at + Vector3(0,size.y*0.5+0.006,side*size.z*0.5),Vector3(size.x,0.012,0.045),_material("iron"),false)


func _water() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = VISIBLE_WATER.size
	var instance := MeshInstance3D.new()
	instance.name = "ClydeWater"
	instance.mesh = mesh
	instance.position = Vector3(0, WATER_Y, RIVER.get_center().y)
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	instance.material_override = material
	add_child(instance)


func _bollard(at: Vector3) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.14
	cylinder.bottom_radius = 0.20
	cylinder.height = 0.70
	cylinder.radial_segments = 12
	var visual := MeshInstance3D.new()
	visual.mesh = cylinder
	visual.material_override = _material("iron")
	visual.position = at + Vector3.UP * 0.35
	add_child(visual)


func _bench(at: Vector3) -> void:
	_box("QuayBenchSeat", at + Vector3.UP * 0.44, Vector3(2.8, 0.10, 0.55), _material("wood"))
	for x: float in [-1.0, 1.0]: _box("QuayBenchSupport", at + Vector3(x, 0.20, 0), Vector3(0.14, 0.4, 0.45), _material("iron"), false)


func _path_border(points: PackedVector3Array) -> void:
	# One ribbon per edge rather than hundreds of individual kerb MeshInstances.
	for side: float in [-1.0, 1.0]:
		var edge := PackedVector3Array()
		for i in points.size():
			var direction := points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]
			var offset := Vector3(direction.z, 0, -direction.x).normalized() * (4.0 * side)
			var at := points[i] + offset + Vector3.UP * 0.025
			var branch := Surface.nearest_segment(_park_cutback, Vector2(at.x, at.z))
			if float(branch.distance) <= 6.0:
				if edge.size() >= 2: _conforming_path_edge(edge,side)
				edge = PackedVector3Array()
			else:
				edge.append(at)
		if edge.size() >= 2: _conforming_path_edge(edge,side)


func _conforming_path_edge(points: PackedVector3Array,outer_side: float) -> void:
	# The old narrow ribbon copied centre-road Y across lower grass. This
	# shallow shoulder samples actual support on both sides, removing its
	# floating collision seam. Query records share the exact visible triangles.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var records: Array[Dictionary] = []
	var distance := 0.0
	for i in points.size():
		var direction := points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]
		var across := Vector3(direction.z,0,-direction.x).normalized()*0.4
		if i>0: distance += points[i].distance_to(points[i-1])
		for side: float in [-1.0,0.0,1.0]:
			var at := points[i]+across*side
			at.y = _local_ground(at.x,at.z)+0.008
			# The centre is the actual asphalt edge. A single outer-to-inner
			# chord would sit below the asphalt halfway across, leaving a lip.
			if side==0.0: at.y = maxf(at.y,points[i].y+0.008)
			# A kerb must become flush through the summit's crossing path.
			# Retain this ribbon/record and its exterior grade, but remove the
			# crowned shoulder across the actual paved junction.
			if Rect2(-170,-187,14,13).has_point(Vector2(at.x,at.z)):at.y=17.0
			vertices.append(at)
			normals.append(Vector3.ZERO)
			uv.append(Vector2((side+1.0)*0.2,distance*0.5))
	for i in range(points.size()-1):
		var a := i*3
		var local_indices := [a,a+1,a+3,a+1,a+4,a+3,a+1,a+2,a+4,a+2,a+5,a+4]
		indices.append_array(PackedInt32Array(local_indices))
		var triangles: Array[PackedVector3Array] = []
		var north_west := Vector2(INF,INF)
		var south_east := Vector2(-INF,-INF)
		for start: int in [0,3,6,9]:
			var triangle := PackedVector3Array()
			var face_normal := (vertices[local_indices[start+1]]-vertices[local_indices[start]]).cross(vertices[local_indices[start+2]]-vertices[local_indices[start]])
			if face_normal.y<0: face_normal = -face_normal
			for offset in 3:
				var index: int = local_indices[start+offset]
				var at := vertices[index]
				normals[index] += face_normal
				triangle.append(at)
				north_west = north_west.min(Vector2(at.x,at.z))
				south_east = south_east.max(Vector2(at.x,at.z))
			triangles.append(triangle)
		records.append({"bounds":Rect2(north_west,south_east-north_west).grow(0.001),"edge_triangles":triangles})
	for i in normals.size(): normals[i] = normals[i].normalized()
	var body := Surface._body(self,"ParkGranitePathEdge",vertices,normals,uv,indices,_material("cut_stone"),"stone")
	body.set_meta("visual_trim_outer_side",outer_side)
	_surfaces.append_array(records)


func _park_pavilion() -> void:
	# Small original Victorian-inspired viewing shelter, outside the main ride line.
	var center := Vector3(-174, 17, -182.5)
	for x: float in [-2.0, 2.0]:
		# The rear row stays under the same roof,50cm clear of the coping
		# centreline rather than occupying its native standing volume.
		for z: float in [-1.0, 1.5]: _beam("PavilionColumn", center + Vector3(x, 0, z), center + Vector3(x, 3.1, z), 0.08, _material("iron"), true)
	for side: float in [-1.0, 1.0]:
		var roof := _box("PavilionSlateRoof", center + Vector3(side * 1.25, 3.1, 0), Vector3(2.8, 0.14, 4.2), _material("slate"), true)
		roof.add_to_group("pavilion_roofs")
		roof.rotation.z = -side * 0.25
	_bench(center + Vector3(0, 0, -0.8))
