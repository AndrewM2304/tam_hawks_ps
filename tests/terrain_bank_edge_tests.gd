extends RefCounted
## Actual convex bank rays decide support; exact lateral/end/outside witnesses
## protect the existing half-open stair/deck and maximum-height contracts.
const Terrain = preload("res://game/levels/core_terrain.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	for axis: String in ["x","z"]:
		for reverse: bool in [false,true]:await _native_bank(tree,check,axis,reverse)
	await _flat_end(tree,check)

static func _native_bank(tree: SceneTree,check: Callable,axis: String,reverse: bool) -> void:
	var viewport:=SubViewport.new();viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
	var root:=Node3D.new();viewport.add_child(root)
	var terrain:=Terrain.new();var material:=StandardMaterial3D.new()
	var lower:=terrain.add_patch(root,"LowerFloor",Rect2(-5,-9,10,16),Vector4.ZERO,material)
	var low:=1.5 if reverse else .5
	var high:=.5 if reverse else 1.5
	var heights:=Vector4(low,high,high,low) if axis=="x" else Vector4(low,low,high,high)
	var slope: float=(high-low)/(4.0 if axis=="x" else 8.0)
	var expected_normal:=Vector3(-slope,1,0).normalized() if axis=="x" else Vector3(0,1,-slope).normalized()
	var bank:=terrain.add_patch(root,"NativeGradedBank",Rect2(-2,-6,4,8),heights,material)
	await tree.physics_frame;await tree.process_frame;await tree.physics_frame;await tree.process_frame
	var space:=root.get_world_3d().direct_space_state
	var exact:=true;var inside:=true;var outside:=true;var bounded:=true;var maximum_error:=0.0
	for fraction: float in [.125,.375,.625,.875]:
		var point:=Vector3(-2+4*fraction,lerpf(low,high,fraction),2) if axis=="x" else Vector3(2,lerpf(low,high,fraction),-6+8*fraction)
		var lateral:=Vector3(0,0,1) if axis=="x" else Vector3(1,0,0)
		for distance: float in [-.001,0]:
			var at:=point+lateral*distance
			var hit: Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(at.x,2,at.z),Vector3(at.x,-.5,at.z),1))
			var query: float=terrain.height_at(at.x,at.z)
			var error: float=INF if hit.is_empty() else absf(query-hit.position.y)
			maximum_error=maxf(maximum_error,error)
			var supported: bool=not hit.is_empty() and hit.collider==bank and error<.002 and absf(query-point.y)<.001 and Vector3(hit.normal).dot(expected_normal)>.999
			if distance==0:exact=exact and supported
			else:inside=inside and supported
			if not supported:print("BANK_EDGE_FAIL axis=",axis," reverse=",reverse," at=",at," queried=",query," hit=",hit)
		var beyond:=point+lateral*.001
		var outside_hit: Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(beyond.x,2,beyond.z),Vector3(beyond.x,-.5,beyond.z),1))
		outside=outside and is_equal_approx(terrain.height_at(beyond.x,beyond.z),0) and not outside_hit.is_empty() and outside_hit.collider==lower and absf(outside_hit.position.y)<.002
		bounded=bounded and terrain.height_at(point.x,point.z,point.y-.01)==0
	check.call(exact and inside,"terrain bank: four exact lateral native supports and four1mm interior sites agree "+axis+str(reverse))
	check.call(outside and bounded,"terrain bank:1mm outside remains lower floor and maximum-height filtering cannot choose the elevated bank "+axis+str(reverse))
	# Far longitudinal end/corners retain their legacy half-open ownership.
	var end:=Vector3(2,0,-2) if axis=="x" else Vector3(0,0,2)
	var corner:=Vector3(2,0,2)
	for endpoint: Vector3 in [end,corner]:
		var native: Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(endpoint.x,2,endpoint.z),Vector3(endpoint.x,-.5,endpoint.z),1))
		print("BANK_END_COMPATIBILITY axis=",axis," reverse=",reverse," point=",endpoint," query=",terrain.height_at(endpoint.x,endpoint.z)," native=",native)
	check.call(terrain.height_at(end.x,end.z)==0 and terrain.height_at(corner.x,corner.z)==0,
		"terrain bank: longitudinal maximum end and its corner keep adjacent interior floor ownership "+axis+str(reverse))
	print("BANK_EDGE_NATIVE axis=",axis," reverse=",reverse," maximum_height_error_m=",maximum_error)
	viewport.queue_free();await tree.process_frame

static func _flat_end(tree: SceneTree,check: Callable) -> void:
	var viewport:=SubViewport.new();viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
	var root:=Node3D.new();viewport.add_child(root)
	var terrain:=Terrain.new();var material:=StandardMaterial3D.new()
	terrain.add_patch(root,"LowerFloor",Rect2(-5,-5,10,10),Vector4.ZERO,material)
	terrain.add_patch(root,"FlatStep",Rect2(-2,-2,4,4),Vector4(1,1,1,1),material)
	await tree.physics_frame;await tree.process_frame
	check.call(terrain.height_at(2,0)==0 and terrain.height_at(0,2)==0 and terrain.height_at(2,2)==0
		and terrain.height_at(1.999,0)==1 and terrain.height_at(0,1.999)==1,
		"terrain bank: flat step maximum faces/corner retain lower ownership while1mm inside stays on the step")
	for point: Vector3 in [Vector3(2,0,0),Vector3(0,0,2),Vector3(2,0,2)]:
		var native: Dictionary=root.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*2,point-Vector3.UP*.5,1))
		print("FLAT_END_COMPATIBILITY point=",point," query=",terrain.height_at(point.x,point.z)," native=",native)
	viewport.queue_free();await tree.process_frame

static func run_world(tree: SceneTree,game: Node,check: Callable) -> void:
	await tree.physics_frame;await tree.process_frame
	var point:=Vector3(76,.05,-6.4)
	var hit: Dictionary=finite_boundary_contact(game.world,point)
	var query: float=game.world.get_ground_height(point)
	var bank: StaticBody3D=game.world.get_node("MarketWestLoadingBank")
	var vertices: PackedVector3Array=bank.get_child(0).shape.points
	var a:=bank.to_global(vertices[0]);var b:=bank.to_global(vertices[1]);var c:=bank.to_global(vertices[2])
	var normal: Vector3=(b-a).cross(c-a).normalized()
	if normal.y<0:normal=-normal
	var inside:=point-Vector3(.001,0,0)
	var inside_hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(inside.x,4,inside.z),Vector3(inside.x,-1,inside.z),1))
	var membership: bool=absf((point-a).dot(normal))<.00001 and point.x==maxf(a.x,maxf(b.x,c.x))
	check.call(membership and not inside_hit.is_empty() and inside_hit.collider==bank and absf(inside_hit.position.y-query)<.002 and Vector3(inside_hit.normal).dot(normal)>.999,
		"terrain bank: actual convex top vertices contain the unchanged maximum-X point and1mm inside native plane has the independent correct normal")
	check.call(not hit.is_empty() and hit.collider==game.world.get_node("MarketWestLoadingBank")
		and absf(query-.05)<.001 and absf(query-hit.position.y)<.002,
		"terrain bank: actual Market west lateral maximum-X support matches native bank instead of buried Barras floor")
	print("MARKET_BANK_EDGE_WORLD query=",query," native=",hit)

static func finite_boundary_contact(world: Node3D,point: Vector3) -> Dictionary:
	# A zero-width cast tangent to a convex side can choose a different owner
	# as its origin changes. Keep EXACT XZ and use a finite1mm native probe.
	var sphere:=SphereShape3D.new();sphere.radius=.001;sphere.margin=0
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=sphere;query.margin=0
	query.collision_mask=1;query.collide_with_areas=false
	query.transform=Transform3D(Basis.IDENTITY,Vector3(point.x,4,point.z))
	query.motion=Vector3(0,-5,0)
	var space:=world.get_world_3d().direct_space_state
	var fractions: PackedFloat32Array=space.cast_motion(query)
	if fractions.size()!=2 or fractions[0]>=1:return {}
	var original_fractions:=fractions.duplicate()
	var brackets: Array[Dictionary]=[{"origin":query.transform.origin,"motion":query.motion,
		"safe":fractions[0],"unsafe":fractions[1],"uncertainty_m":query.motion.length()*(fractions[1]-fractions[0])}]
	var passes:=0
	# Native cast fractions have finite search precision. Refine their SAME
	# safe/unsafe bracket instead of accepting centimetres of sweep uncertainty.
	while query.motion.length()*(fractions[1]-fractions[0])>.00025 and passes<2:
		query.transform.origin+=query.motion*fractions[0]
		query.motion*=fractions[1]-fractions[0]
		fractions=space.cast_motion(query)
		if fractions.size()!=2 or fractions[0]>=1:return {}
		passes+=1
		brackets.append({"origin":query.transform.origin,"motion":query.motion,
			"safe":fractions[0],"unsafe":fractions[1],"uncertainty_m":query.motion.length()*(fractions[1]-fractions[0])})
	var uncertainty: float=query.motion.length()*(fractions[1]-fractions[0])
	if uncertainty>.00025:return {}
	var contact_center: Vector3=query.transform.origin+query.motion*fractions[1]
	# The declared0.25mm rest overlap is below the unchanged2mm agreement gate.
	query.transform.origin=contact_center-Vector3.UP*.00025
	query.motion=Vector3.ZERO
	var rest: Dictionary=space.get_rest_info(query)
	if rest.is_empty():
		print("BANK_NATIVE_PROBE_MISS point=",point," fractions=",fractions," center=",contact_center)
		return {}
	return {"position":rest.point,"normal":rest.normal,"collider":instance_from_id(int(rest.collider_id)),
		"radius":.001,"safe_fraction":fractions[0],"unsafe_fraction":fractions[1],"coarse_fractions":original_fractions,"refinement_passes":passes,"brackets":brackets,"uncertainty_m":uncertainty,"contact_center":contact_center,"rest_overlap_m":.00025}
