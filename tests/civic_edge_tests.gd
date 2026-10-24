extends RefCounted
## Owner's right-hand civic crack: native support, displayed paving and real guard.

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var world:Node3D=game.world
	var space:=world.get_world_3d().direct_space_state
	var supported:=true
	var visible:=true
	var count:=0
	for x:float in [35.25,35.5,35.75]:
		for z:float in [-127.4,-124.,-110.,-106.,-100.,-96.,-90.,-74.,-58.]:
			var y:=6. if z<=-108 else (4.+(-z-96.)/6. if z< -96 else 4.)
			var at:=Vector3(x,y,z)
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.2,at-Vector3.UP*.2,1))
			supported=not hit.is_empty() and absf(hit.position.y-y)<.001 and absf(world.get_ground_height(at)-y)<.001 and supported
			var body:StaticBody3D=world.get_node("CivicForecourt" if z<=-108 else ("CivicEastBank" if z< -96 else "GeorgeSquareFloor"))
			var drawn:=false
			for child:Node in body.get_children():
				if not child is MeshInstance3D:continue
				var faces:PackedVector3Array=child.mesh.get_faces()
				for i in range(0,faces.size(),3):
					drawn=drawn or _on_triangle(at,child.to_global(faces[i]),child.to_global(faces[i+1]),child.to_global(faces[i+2]))
			visible=visible and drawn
			count+=1
	check.call(supported,"civic right gap:27 independent native rays and height queries support the full east setback")
	check.call(visible and count==27,"civic right gap: actual visible paving covers all27 repaired support samples")
	var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.margin=.005
	q.transform=Transform3D(Basis.IDENTITY,Vector3(35.55,6.9,-126))
	check.call(space.intersect_shape(q).is_empty(),"civic right gap: standing capsule fits the supported setback without hidden obstruction")
	var guard_panels:=0
	var guard_exact:=false
	for body:Node3D in world.find_children("*","StaticBody3D",true,false):
		if body.get_meta("boundary_family","")!="CivicRearCornerBoundary":continue
		var points:PackedVector3Array=body.get_meta("boundary_points",PackedVector3Array())
		if points.is_empty() or points[0].x<0:continue
		var low:=Vector3.INF;var high:=-Vector3.INF
		for child:Node in body.get_children():
			if not child is CollisionShape3D:continue
			guard_panels+=1
			for point:Vector3 in child.shape.points:
				var actual:Vector3=child.to_global(point)
				low=low.min(actual);high=high.max(actual)
		guard_exact=low.is_equal_approx(Vector3(31,5.8,-127.9)) and high.is_equal_approx(Vector3(36,9,-127.7))
	q.motion=Vector3(0,0,-4)
	var sweep:=space.cast_motion(q)
	check.call(sweep[0]<.6 and guard_exact and guard_panels==3,"civic right gap: native rear fence stops a capsule before the unsupported north edge")

	var spawn:Vector3=game.skater.spawn_position
	var free:bool=game.free_skate_mode
	game.skater.spawn_position=Vector3(35.55,6.03,-123)
	game.start_mode(true)
	for i in 20:await tree.physics_frame;await tree.process_frame
	game.skater.rotation.y=0
	game.skater.velocity=Vector3(0,0,-4);game.skater.speed=4
	Input.action_press("push")
	var safe:=true
	for i in 90:
		await tree.physics_frame;await tree.process_frame
		safe=safe and game.skater.position.y>5.9 and not game.skater.bail_active and not game.skater.airborne
	Input.action_release("push")
	check.call(safe and game.skater.position.z< -125 and game.skater.position.z> -127.8,
		"civic right gap: actual skater rides the setback and is stopped by the rear guard without falling or bailing")
	game.skater.spawn_position=spawn
	game.start_mode(free)
	for i in 20:await tree.physics_frame;await tree.process_frame

static func _on_triangle(p:Vector3,a:Vector3,b:Vector3,c:Vector3)->bool:
	var ab:=Vector2(b.x-a.x,b.z-a.z);var ac:=Vector2(c.x-a.x,c.z-a.z)
	var offset:=Vector2(p.x-a.x,p.z-a.z);var determinant:=ab.cross(ac)
	if absf(determinant)<.000001:return false
	var wb:=offset.cross(ac)/determinant;var wc:=ab.cross(offset)/determinant
	var wa:=1.-wb-wc
	return minf(wa,minf(wb,wc))>=-.00002 and absf(p.y-(a.y*wa+b.y*wb+c.y*wc))<.001
