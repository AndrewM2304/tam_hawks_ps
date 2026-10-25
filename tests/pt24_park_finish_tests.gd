extends RefCounted
## The road owns the lower-entry display footprint; native support is retained.
const World = preload("res://game/levels/glasgow_square.gd")
const Outdoors = preload("res://game/levels/outdoor_routes.gd")
const Main = preload("res://game/main.gd")
const LOWER_ENTRY := Rect2(-160,-58,25,59)
const STATION_PORT := Rect2(-145,-8,15,16)
## Packed world vertices and Geometry2D's polygon grid round a shared edge.
## Admit at most0.25mm at its perimeter; do not mask an interior grass wedge.
const EDGE_PRECISION := 0.00025

static func run(tree: SceneTree,check: Callable) -> void:
	var helper := Outdoors.new()
	var area := 0.0
	for polygon: PackedVector2Array in helper._subtract_finish_polygon(
			PackedVector2Array([Vector2.ZERO,Vector2(8,0),Vector2(0,8)]),
			PackedVector2Array([Vector2(1,1),Vector2(2,1),Vector2(2,2),Vector2(1,2)])):
		area+=_area(polygon)
	check.call(absf(area-31.0)<0.00001,"PT24 park finish: wholly enclosed paving removes exactly one square metre without filling a polygon hole")
	helper.free()
	var world := World.new()
	world.set_meta("render_budget_probe_baseline",true)
	tree.root.add_child(world)
	await tree.physics_frame
	await tree.process_frame
	var outdoors: Node3D = world.get_node("OutdoorRoutes")
	var road: StaticBody3D = outdoors.get_node("KelvingroveCentralApproach")
	var paved := _polygons(road.get_child(1).shape.get_faces(),LOWER_ENTRY)
	paved.append_array(_polygons(outdoors.get_node("KelvingroveCutbackReturn").get_child(1).shape.get_faces(),LOWER_ENTRY))
	# Independently declared full core-port footprint, rather than inferring
	# its wider arms from the outdoor approach's narrower ribbon generator.
	var port_paved := _polygons(PackedVector3Array([
		Vector3(-145,2,-8),Vector3(-130,2,-8),Vector3(-130,2,8),
		Vector3(-145,2,-8),Vector3(-130,2,8),Vector3(-145,2,8)]),STATION_PORT)
	var native_overlap := 0.0
	var display_overlap := 0.0
	var edge_roundoff := 0.0
	var triangles_before := 0
	var triangles_after := 0
	var resident := true
	var port_native_overlap := 0.0
	var port_display_overlap := 0.0
	var port_edge_roundoff := 0.0
	for id: String in ["KelvingroveRollingGround","KelvingroveCentralEmbankment","KelvingroveGeorgeEmbankment"]:
		var body: StaticBody3D = outdoors.get_node(id)
		var visual: MeshInstance3D = body.get_child(0)
		var collision: CollisionShape3D = body.get_child(1)
		resident=resident and body.get_child_count()==2 and visual.mesh.get_surface_count()==1 \
			and visual.material_override is ShaderMaterial and collision.shape is ConcavePolygonShape3D
		triangles_before+=int(visual.get_meta("grass_triangles_before",0))
		triangles_after+=visual.mesh.get_faces().size()/3
		native_overlap+=_overlap(_polygons(collision.shape.get_faces(),LOWER_ENTRY),paved)
		var displayed := _polygons(visual.mesh.get_faces(),LOWER_ENTRY)
		display_overlap+=_overlap(displayed,paved,EDGE_PRECISION)
		edge_roundoff+=_overlap(displayed,paved)
		port_native_overlap+=_overlap(_polygons(collision.shape.get_faces(),STATION_PORT),port_paved)
		var port_displayed := _polygons(visual.mesh.get_faces(),STATION_PORT)
		port_display_overlap+=_overlap(port_displayed,port_paved,EDGE_PRECISION)
		port_edge_roundoff+=_overlap(port_displayed,port_paved)
	check.call(native_overlap>100.0,"PT24 park finish: fixed lower-entry witness retains the original native grass support beneath the existing asphalt")
	check.call(display_overlap<0.00001,"PT24 park finish: lower-entry grass stays outside the asphalt interior beyond the0.25mm native-float edge envelope")
	check.call(edge_roundoff<.002,"PT24 park finish: summed grass/asphalt edge roundoff stays below0.002 square metres across the whole lower-entry witness")
	check.call(port_native_overlap>200.0,"PT24 park finish: independently fixed15x16m core station-port witness includes the wider junction arms")
	check.call(port_display_overlap<.00001 and port_edge_roundoff<.002,
		"PT24 park finish: the complete core station-port footprint has no grass wedges, including arms outside the outdoor ribbon")
	check.call(resident and triangles_before>0,"PT24 park finish: ownership changes retain the three original bodies, shapes, resident surfaces and grass material")
	# Exact clipping creates a few legitimate perimeter faces. The combined
	# default repair removes315 quay triangles and adds12 gate-frame triangles;
	# this component's64-triangle ceiling keeps the package net-negative.
	check.call(triangles_after<=triangles_before+64,"PT24 park finish: lower-road ownership stays within the declared64-triangle component budget")
	var support := true
	var visible_road := true
	var samples := 0
	for center: Vector3 in [Vector3(-145.5,0,-2),Vector3(-147,0,-8),Vector3(-151,0,-22),Vector3(-147,0,-48)]:
		for dx: float in [-.25,0.,.25]:
			for dz: float in [-.25,0.,.25]:
				var at := center+Vector3(dx,0,dz)
				var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*10,at-Vector3.UP*2,1)
				var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
				support=support and not hit.is_empty()
				if not hit.is_empty(): support=support and absf(world.get_ground_height(at)-hit.position.y)<.001
				visible_road=visible_road and _covered(road.get_child(0).mesh.get_faces(),Vector2(at.x,at.z))
				samples+=1
	check.call(support,"PT24 park finish:36 fixed entry-road native supports still agree with the public height query")
	check.call(visible_road,"PT24 park finish:36 fixed entry-road points retain displayed asphalt after grass subtraction")
	var port: Node3D = world.get_node("KelvingroveWestPort")
	var port_faces := PackedVector3Array()
	var retained_wall_area := 0.0
	var port_triangles_before := 0
	var port_triangles_after := 0
	for child: Node in port.get_children():
		if not child is MeshInstance3D: continue
		port_triangles_before=int(child.get_meta("port_triangles_before",0))
		port_triangles_after=child.mesh.get_faces().size()/3
		var faces: PackedVector3Array = child.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var a: Vector3 = child.to_global(faces[i])
			var b: Vector3 = child.to_global(faces[i+1])
			var c: Vector3 = child.to_global(faces[i+2])
			var cross := (b-a).cross(c-a)
			if absf(cross.y)<.0000001 and minf(a.y,minf(b.y,c.y))<1.99999:
				retained_wall_area+=cross.length()*.5
			if minf(a.y,minf(b.y,c.y))>=1.99999 and cross.y<-.0000001:
				port_faces.append_array(PackedVector3Array([a,b,c]))
	check.call(absf(retained_wall_area-310.0)<.0001,
		"PT24 park finish: all310 square metres of the fixed station-port retaining walls remain displayed")
	check.call(port_triangles_before>0 and port_triangles_after<=port_triangles_before+64,
		"PT24 park finish: exact native-plane port conformance stays within64 added resident triangles")
	var port_supported := true
	var port_drawn := true
	var max_port_native_excess := 0.0
	var paved_display_faces := port_faces.duplicate()
	for id: String in ["KelvingroveCentralApproach","KelvingroveCutbackReturn"]:
		var body: Node3D = outdoors.get_node(id)
		for child: Node in body.get_children():
			if not child is MeshInstance3D: continue
			for point: Vector3 in child.mesh.get_faces(): paved_display_faces.append(child.to_global(point))
	var port_witnesses: Array[Vector2] = [Vector2(-141.119,-3.586)]
	for x: float in [-144.5,-141,-137.5,-134,-130.5]:
		for z: float in [-7.5,-4,0,4,7.5]:
			port_witnesses.append(Vector2(x,z))
	for point: Vector2 in port_witnesses:
		var at := Vector3(point.x,2,point.y)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(at+Vector3.UP*8,at-Vector3.UP*4,1))
		port_supported=port_supported and not hit.is_empty()
		if not hit.is_empty():
			port_supported=port_supported and absf(world.get_ground_height(at)-hit.position.y)<.001
			var displayed_height := _display_height(paved_display_faces,point)
			max_port_native_excess=maxf(max_port_native_excess,absf(hit.position.y-displayed_height))
			if point==port_witnesses[0] or absf(hit.position.y-displayed_height)>.001:
				print("PT24_PORT_HEIGHT at=%s native=%f collider=%s displayed_paving=%f gap=%f"%[
					point,hit.position.y,hit.collider.name,displayed_height,hit.position.y-displayed_height])
		port_drawn=port_drawn and _covered(paved_display_faces,point)
	check.call(port_drawn,"PT24 park finish:26 independently fixed points retain actual displayed paving across the whole station-port mouth")
	check.call(port_supported,"PT24 park finish:26 independently fixed core-port supports remain native/query consistent")
	check.call(max_port_native_excess<.001,"PT24 park finish: highest displayed paving agrees with native support across all26 station-port witnesses")
	var overlap := _overlap(_polygons(port_faces,STATION_PORT),_polygons(road.get_child(0).mesh.get_faces(),STATION_PORT),EDGE_PRECISION)
	check.call(overlap<.00001,"PT24 park finish: actual core-port and approach asphalt have no duplicate interior top faces")
	var caps_visible := true
	var caps_native := true
	var cap_queries := 0
	var all_port_faces := PackedVector3Array()
	for child: Node in port.get_children():
		if child is MeshInstance3D:
			for point: Vector3 in child.mesh.get_faces(): all_port_faces.append(child.to_global(point))
	for point: Vector3 in road.get_child(0).mesh.get_faces(): all_port_faces.append(road.to_global(point))
	for at: Vector3 in [Vector3(-140.60,2.035,-2.552),Vector3(-141.42,2.134,-4.958),Vector3(-142.14,2.223,-7.028)]:
		var start := at+Vector3.RIGHT*.08
		var finish := at-Vector3.RIGHT*.08
		var displayed := false
		for i in range(0,all_port_faces.size(),3):
			var a := all_port_faces[i]
			var b := all_port_faces[i+1]
			var c := all_port_faces[i+2]
			# This curved edge is not axis-aligned. Its actual front face must
			# face the supplied owner camera, rather than an assumed +X normal.
			var camera := Vector3(-136.219406,4.602189,-3.709707)
			if -(b-a).cross(c-a).dot(camera-a)<=0.0: continue
			displayed=displayed or Geometry3D.segment_intersects_triangle(start,finish,a,b,c)!=null
		caps_visible=caps_visible and displayed
		for sign: float in [-1.,1.]:
			var query := PhysicsRayQueryParameters3D.create(at+Vector3.RIGHT*.08*sign,at-Vector3.RIGHT*.08*sign,1)
			var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
			caps_native=caps_native and not hit.is_empty() and hit.get("collider")==road
			cap_queries+=1
	check.call(caps_visible,"PT24 park finish: all three fixed bright-line witnesses have outward visible asphalt closure across the real20mm shoulder step")
	check.call(caps_native,"PT24 park finish: six fixed horizontal native rays hit the same shoulder closures in both directions")
	_check_complete_approach(world,road,check)
	print("PT24_PARK_FINISH native_overlap_m2=%.6f displayed_interior_overlap_m2=%.8f edge_roundoff_m2=%.8f grass_triangles=%d->%d samples=%d"%[
		native_overlap,display_overlap,edge_roundoff,triangles_before,triangles_after,samples])
	print("PT24_PARK_CORE_PORT native_overlap_m2=%.6f displayed_interior_overlap_m2=%.8f edge_roundoff_m2=%.8f native_display_difference_m=%.6f port_triangles=%d->%d samples=26"%[
		port_native_overlap,port_display_overlap,port_edge_roundoff,max_port_native_excess,port_triangles_before,port_triangles_after])
	print("PT24_PARK_EDGE_CAPS native_triangles=%d fixed_native_rays=%d"%[road.get_meta("port_edge_cap_faces",PackedVector3Array()).size()/3,cap_queries])
	world.free()
	await tree.process_frame
	await _drive_port_crossings(tree,check)

static func _drive_port_crossings(tree: SceneTree,check: Callable) -> void:
	var game := Main.new()
	game.persistence_enabled=false
	tree.root.add_child(game)
	var bails := [0]
	game.skater.bailed.connect(func(): bails[0]+=1)
	for route: Vector3 in [Vector3(-141.42,0,-4.958),Vector3(-143.3,0,-10)]:
		for side: float in [1.,-1.]:
			for action: String in ["push","brake","manual","ollie","grind","steer_left","steer_right"]: Input.action_release(action)
			var start := route+Vector3.RIGHT*side*1.4
			start.y=game.world.get_ground_height(start)+.08
			game.skater.spawn_position=start
			game.start_mode(true)
			game.skater.rotation.y=PI*.5*side
			for frame in 6:
				await tree.physics_frame
				await tree.process_frame
			var before: int=bails[0]
			var reached := false
			Input.action_press("push")
			for frame in 120:
				if (game.skater.global_position.x-route.x)*side< -1.0:
					reached=true
					break
				await tree.physics_frame
				await tree.process_frame
			Input.action_release("push")
			check.call(reached and bails[0]==before,"PT24 park finish: ordinary Push crosses the repaired shoulder without ollie or bail side="+str(side)+" z="+str(route.z))
			print("PT24_PORT_CROSS side=%f reached=%s bails=%d at=%s"%[side,reached,bails[0]-before,game.skater.global_position])
	game.queue_free()
	await tree.process_frame

static func _check_complete_approach(world: Node3D,road: StaticBody3D,check: Callable) -> void:
	var vertices: PackedVector3Array=road.get_meta("strip_vertices")
	var indices: PackedInt32Array=road.get_meta("strip_indices")
	var source_arrays: Array=[]
	source_arrays.resize(Mesh.ARRAY_MAX)
	source_arrays[Mesh.ARRAY_VERTEX]=vertices
	source_arrays[Mesh.ARRAY_INDEX]=indices
	var source_mesh:=ArrayMesh.new()
	source_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,source_arrays)
	var expected: PackedVector3Array=source_mesh.create_trimesh_shape().get_faces()
	var native: PackedVector3Array=road.get_child(1).shape.get_faces()
	var tops := PackedVector3Array()
	for i in range(0,native.size(),3):
		if absf((native[i+1]-native[i]).cross(native[i+2]-native[i]).y)>.000001:
			tops.append_array(native.slice(i,i+3))
	# The physics backend may reorder triangle storage when rebuilding its BVH.
	# Compare exact packed vertex bytes independent of triangle order/winding.
	check.call(_triangle_bytes(tops)==_triangle_bytes(expected),
		"PT24 park finish: complete approach native top vertex bytes remain identical independent of BVH order")
	var records: Array=road.get_meta("approach_edge_closures",[])
	check.call(records.size()==vertices.size() and ((vertices[0]+vertices[1])*.5).distance_to(Vector3(-145,2,0))<.00001
		and ((vertices[-2]+vertices[-1])*.5).distance_to(Vector3(-155,6,-82))<.00001,
		"PT24 park finish: both complete authored approach sides and both endpoint caps are covered fromz0toz-82")
	var visible := PackedVector3Array()
	for point: Vector3 in road.get_child(0).mesh.get_faces(): visible.append(road.to_global(point))
	var exclude: Array[RID]=[]
	for body: Node in world.find_children("*","PhysicsBody3D",true,false):
		if body!=road: exclude.append((body as PhysicsBody3D).get_rid())
	var drawn := true
	var blocked := true
	var rays := 0
	for record: Dictionary in records:
		if record.triangles==0: continue
		var at: Vector3=(record.start+record.finish)*.5
		at.y=(at.y+record.lower)*.5
		var start: Vector3=at+record.outward*.02
		var finish: Vector3=at-record.outward*.02
		var hit_visible := false
		for i in range(0,visible.size(),3):
			if -(visible[i+1]-visible[i]).cross(visible[i+2]-visible[i]).dot(record.outward)<=0:continue
			hit_visible=hit_visible or Geometry3D.segment_intersects_triangle(start,finish,visible[i],visible[i+1],visible[i+2])!=null
		drawn=drawn and hit_visible
		for side: float in [-1.,1.]:
			var query:=PhysicsRayQueryParameters3D.create(at+record.outward*.02*side,at-record.outward*.02*side,1,exclude)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
			blocked=blocked and not hit.is_empty() and hit.get("collider")==road
			rays+=1
	check.call(drawn and blocked and rays>=records.size(),"PT24 park finish: every complete side/end interval has matching outward display and two-sided native closure")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/testing/debug-session-2026-10-24/reports/issue-0011.json"))
	var camera: Vector3=Vector3(data.camera.position[0],data.camera.position[1],data.camera.position[2])
	var basis:=Basis.looking_at(Vector3(data.camera.forward[0],data.camera.forward[1],data.camera.forward[2]),Vector3(data.camera.up[0],data.camera.up[1],data.camera.up[2]))
	var half_height:=tan(deg_to_rad(float(data.camera.fov))*.5)
	var far_closed := true
	for pixel: Vector2 in [Vector2(1120,515),Vector2(1150,509),Vector2(1180,503)]:
		for subpixel: Vector2 in [Vector2.ZERO,Vector2(.5,.5)]:
			var point:=pixel+subpixel
			var direction:=(-basis.z+basis.x*(point.x/640.0-1.0)*1.6*half_height+basis.y*(1.0-point.y/400.0)*half_height).normalized()
			var finish:=camera+direction*50
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera,finish,1))
			var targeted:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera,finish,1,exclude))
			var cap_visible := false
			var nearest := Vector3.INF
			var nearest_distance := INF
			for i in range(0,visible.size(),3):
				var normal: Vector3=-(visible[i+1]-visible[i]).cross(visible[i+2]-visible[i])
				if normal.dot(camera-visible[i])<=0:continue
				var drawn_hit: Variant=Geometry3D.segment_intersects_triangle(camera,finish,visible[i],visible[i+1],visible[i+2])
				if drawn_hit==null:continue
				cap_visible=cap_visible or absf(normal.y)<.000001
				if camera.distance_to(drawn_hit)<nearest_distance:
					nearest=drawn_hit
					nearest_distance=camera.distance_to(drawn_hit)
			print("PT24_FAR_PIXEL at=%s subpixel=%s visible_cap=%s first_native=%s first_at=%s displayed_at=%s"%[
				pixel,subpixel,cap_visible,hit.get("collider"),hit.get("position"),nearest])
			far_closed=far_closed and not targeted.is_empty() and targeted.get("collider")==road \
				and nearest.is_finite() and nearest.distance_to(targeted.position)<.001
	check.call(far_closed,"PT24 park finish: all three independently fixed far-right white pixels now hit visible/native closure beyond the core-port boundary")
	var cap_count: int=road.get_meta("port_edge_cap_faces",PackedVector3Array()).size()/3
	check.call(cap_count<=192 and road.get_child(0).mesh.get_surface_count()==1 and road.get_child_count()==2,
		"PT24 park finish: full-perimeter closure stays within192 triangles and the original resident draw/body/shape")
	print("PT24_APPROACH_FULL intervals=%d native_rays=%d cap_triangles=%d far_pixels=3"%[records.size(),rays,cap_count])

static func _triangle_bytes(faces: PackedVector3Array) -> Array[String]:
	var result: Array[String]=[]
	for i in range(0,faces.size(),3):
		var points: Array[String]=[]
		for j in 3: points.append(faces.slice(i+j,i+j+1).to_byte_array().hex_encode())
		points.sort()
		result.append("".join(points))
	result.sort()
	return result

static func _polygons(faces: PackedVector3Array,envelope: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(0,faces.size(),3):
		var polygon := PackedVector2Array([Vector2(faces[i].x,faces[i].z),
			Vector2(faces[i+1].x,faces[i+1].z),Vector2(faces[i+2].x,faces[i+2].z)])
		var minimum := polygon[0].min(polygon[1]).min(polygon[2])
		var maximum := polygon[0].max(polygon[1]).max(polygon[2])
		var bounds := Rect2(minimum,maximum-minimum)
		if _area(polygon)<0.0000001 or not envelope.intersects(bounds): continue
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(polygon,PackedVector2Array([
			envelope.position,Vector2(envelope.end.x,envelope.position.y),envelope.end,Vector2(envelope.position.x,envelope.end.y)])):
			result.append({"polygon":piece,"bounds":bounds})
	return result

static func _overlap(first: Array[Dictionary],second: Array[Dictionary],inset: float = 0.0) -> float:
	var result := 0.0
	for a: Dictionary in first:
		for b: Dictionary in second:
			if not a.bounds.intersects(b.bounds): continue
			var interiors: Array[PackedVector2Array] = [b.polygon]
			if inset>0.0: interiors=Geometry2D.offset_polygon(b.polygon,-inset)
			for interior: PackedVector2Array in interiors:
				for polygon: PackedVector2Array in Geometry2D.intersect_polygons(a.polygon,interior): result+=_area(polygon)
	return result

static func _covered(faces: PackedVector3Array,at: Vector2) -> bool:
	for i in range(0,faces.size(),3):
		var a := Vector2(faces[i].x,faces[i].z)
		var ab := Vector2(faces[i+1].x,faces[i+1].z)-a
		var ac := Vector2(faces[i+2].x,faces[i+2].z)-a
		var determinant := ab.cross(ac)
		if absf(determinant)<0.000000001: continue
		var relative := at-a
		var wb := relative.cross(ac)/determinant
		var wc := ab.cross(relative)/determinant
		if minf(1-wb-wc,minf(wb,wc))>=-.000001:return true
	return false

static func _display_height(faces: PackedVector3Array,at: Vector2) -> float:
	var highest := -INF
	for i in range(0,faces.size(),3):
		var a := Vector2(faces[i].x,faces[i].z)
		var ab := Vector2(faces[i+1].x,faces[i+1].z)-a
		var ac := Vector2(faces[i+2].x,faces[i+2].z)-a
		var determinant := ab.cross(ac)
		if absf(determinant)<.000000001: continue
		var relative := at-a
		var wb := relative.cross(ac)/determinant
		var wc := ab.cross(relative)/determinant
		var wa := 1-wb-wc
		if minf(wa,minf(wb,wc))>=-.000001:
			highest=maxf(highest,faces[i].y*wa+faces[i+1].y*wb+faces[i+2].y*wc)
	return highest

static func _area(polygon: PackedVector2Array) -> float:
	if polygon.size()<3:return 0.0
	var result := 0.0
	for i in polygon.size():result+=(polygon[i]-polygon[0]).cross(polygon[(i+1)%polygon.size()]-polygon[0])
	return absf(result)*.5
