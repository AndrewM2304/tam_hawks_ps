extends RefCounted
## Independent PT24 witnesses: native shoulder support and closed visible skirts.
## No route driving, authored success flags or renderer-dependent ray picks.

const World = preload("res://game/levels/glasgow_square.gd")
const Surface = preload("res://game/levels/outdoors/surface_builder.gd")
const Routes = preload("res://tests/world_routes_tests.gd")

static func run(tree: SceneTree, check: Callable) -> void:
	var world := World.new()
	world.set_meta("render_budget_probe_baseline",true)
	tree.root.add_child(world)
	await tree.physics_frame
	await tree.process_frame
	var outdoors: Node3D = world.get_node("OutdoorRoutes")
	var space := world.get_world_3d().direct_space_state
	var clear_climb:=false
	for route: Dictionary in world.get_route_definitions():
		if route.id!="kelvingrove_central_climb":continue
		clear_climb=true
		for i in range(route.points.size()-1):
			clear_climb=Routes._clear_sweep(world,route.points[i],route.points[i+1]) \
				and Routes._clear_sweep(world,route.points[i+1],route.points[i]) and clear_climb
	check.call(clear_climb,"PT24 outdoor: complete central climb keeps actual capsule clearance in both directions below grass shoulders")
	for center: Vector3 in [Vector3(-141.119,2.103,-3.586),Vector3(-152.933,4.161,-44.939)]:
		var smooth := true
		var agreed := true
		var previous := NAN
		for index in range(-32,33):
			var at := center+Vector3(index*.125,0,0)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(at.x,10,at.z),Vector3(at.x,-1,at.z),1))
			if hit.is_empty():
				smooth=false
				agreed=false
				continue
			var height: float = hit.position.y
			smooth=smooth and (is_nan(previous) or absf(height-previous)<.06) and hit.normal.y>.80
			agreed=agreed and absf(world.get_ground_height(at)-height)<.001
			previous=height
		check.call(smooth,"PT24 outdoor:65 native lateral supports cross the recorded lower park shoulder without a kerb "+str(center))
		check.call(agreed,"PT24 outdoor:65 public height samples agree with the actual highest core/outdoor support "+str(center))
	var retained := 0
	var surfaces := 0
	for id: String in ["KelvingroveGeorgePromenade","KelvingroveViewTerrace","KelvingroveViewpointSpur"]:
		var body: StaticBody3D=outdoors.get_node(id)
		var visual: MeshInstance3D=body.get_child(0)
		var collision: CollisionShape3D=body.get_child(1)
		retained+=int(body.get_meta("retaining_triangles",0))
		surfaces+=visual.mesh.get_surface_count()-1
		var skirt:=ArrayMesh.new()
		skirt.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,visual.mesh.surface_get_arrays(1))
		var native: PackedVector3Array=collision.shape.get_faces()
		check.call(visual.mesh.get_surface_count()==2 and int(body.get_meta("retaining_triangles",0))>0
			and _same_faces(skirt.get_faces(),native.slice(native.size()-skirt.get_faces().size())),
			"PT24 outdoor: raised paving has matching native/displayed masonry sides on its resident shape "+id)
	# Fixed expected shelter footprint catches a missing whole side. Check actual
	# outward rendered triangles and native rays in both directions at33 points.
	var terrace: StaticBody3D=outdoors.get_node("KelvingroveViewTerrace")
	var visible:=true
	var blocked:=true
	for edge: Array in [
		[Vector3(-178.75,16.9,-185),Vector3(-161.25,16.9,-185),Vector3.FORWARD],
		[Vector3(-179,16.9,-184.75),Vector3(-179,16.9,-180.25),Vector3.LEFT],
		[Vector3(-178.75,16.9,-180),Vector3(-173.25,16.9,-180),Vector3.BACK]
	]:
		for index in range(11):
			var at: Vector3=edge[0].lerp(edge[1],float(index)/10)
			var direction: Vector3=edge[2]
			visible=visible and _drawn_face(terrace,at,direction)
			for sign: float in [-1.,1.]:
				var query:=PhysicsRayQueryParameters3D.create(at+direction*.12*sign,at-direction*.12*sign,1)
				var hit:=space.intersect_ray(query)
				blocked=blocked and not hit.is_empty() and hit.collider==terrace
	check.call(visible,"PT24 outdoor: all33 independently fixed shelter-edge points have outward visible masonry faces")
	check.call(blocked,"PT24 outdoor: native side rays hit all33 shelter-edge points from both sides")
	check.call(surfaces<=3 and retained<=1800,"PT24 outdoor: three resident skirts stay within3 surfaces/1800 triangles without new physics bodies")
	var arrival:=0
	var guard_heights:=true
	for body: Node in outdoors.get_children():
		if str(body.get_meta("boundary_family",""))!="StationParkArrivalGuard":continue
		arrival+=1
		guard_heights=guard_heights and is_equal_approx(float(body.get_meta("boundary_height",0)),4.5)
	check.call(arrival==2 and guard_heights,"PT24 outdoor: both authored4.5m station arrival guards retain their requested height")
	var summit: Array[Array] = []
	for body: Node in outdoors.get_children():
		if not body is StaticBody3D:continue
		if str(body.name) not in ["KelvingroveRollingLoop","KelvingroveViewTerrace","KelvingroveViewpointSpur"] \
				and str(body.get_meta("art_label",""))!="ParkGranitePathEdge":continue
		var top: Array[PackedVector2Array]=[]
		for child: Node in body.get_children():
			if not child is MeshInstance3D:continue
			var faces: PackedVector3Array=child.mesh.get_faces()
			for i in range(0,faces.size(),3):
				if absf(faces[i].y-17)>.0001 or absf(faces[i+1].y-17)>.0001 or absf(faces[i+2].y-17)>.0001:continue
				top.append(PackedVector2Array([Vector2(faces[i].x,faces[i].z),Vector2(faces[i+1].x,faces[i+1].z),Vector2(faces[i+2].x,faces[i+2].z)]))
		summit.append(top)
	var overlap:=0.0
	for first in summit.size():
		for second in range(first+1,summit.size()):
			for a: PackedVector2Array in summit[first]:
				for b: PackedVector2Array in summit[second]:
					for polygon: PackedVector2Array in Geometry2D.intersect_polygons(a,b):
						overlap+=_area(polygon)
	check.call(overlap<.001,"PT24 outdoor: summit terrace/spur/granite/asphalt displayed tops have no positive-area coplanar overlap")
	print("PT24_OUTDOOR shoulder_samples=130 shelter_side_samples=66 added_surfaces=%d retaining_triangles=%d"%[surfaces,retained])
	world.free()
	await tree.process_frame

static func _same_faces(a: PackedVector3Array,b: PackedVector3Array) -> bool:
	if a.size()!=b.size():return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):return false
	return true

static func _area(polygon: PackedVector2Array) -> float:
	if polygon.size()<3:return 0.0
	var signed:=0.0
	# Translate before summing: world coordinates near(-180,-180) otherwise
	# lose millimetre precision to cancellation on shared, zero-area seams.
	for i in polygon.size():signed+=(polygon[i]-polygon[0]).cross(polygon[(i+1)%polygon.size()]-polygon[0])
	return absf(signed)*.5

static func _drawn_face(body: Node3D,at: Vector3,outward: Vector3) -> bool:
	for child: Node in body.get_children():
		if not child is MeshInstance3D:continue
		var faces: PackedVector3Array=child.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var a: Vector3=child.to_global(faces[i])
			var b: Vector3=child.to_global(faces[i+1])
			var c: Vector3=child.to_global(faces[i+2])
			var normal:=-(b-a).cross(c-a).normalized()
			if normal.dot(outward)<.99 or absf((at-a).dot(normal))>.0001:continue
			var edge_b:=b-a
			var edge_c:=c-a
			var relative:=at-a
			var denominator:=edge_b.length_squared()*edge_c.length_squared()-pow(edge_b.dot(edge_c),2)
			if denominator<=.00000001:continue
			var wb: float=(edge_c.length_squared()*relative.dot(edge_b)-edge_b.dot(edge_c)*relative.dot(edge_c))/denominator
			var wc: float=(edge_b.length_squared()*relative.dot(edge_c)-edge_b.dot(edge_c)*relative.dot(edge_b))/denominator
			if minf(1-wb-wc,minf(wb,wc))>=-.0001:return true
	return false
