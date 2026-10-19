extends RefCounted
## Regression for the owner-reported missing land. Inspect physical geometry,
## not the implementation's patch metadata, and preserve playable port heights.
static func run(tree:SceneTree,world:Node3D,check:Callable)->void:
	await tree.physics_frame
	var space:=world.get_world_3d().direct_space_state
	var missing:=0
	var mismatched:=0
	var samples:=0
	for x:float in [-138,-134,-128,-120,-110,-100,-95,-90,-80,-70,-60,-50,-40]:
		for z:float in [-106,-100,-94,-90,-84,-72,-60,-44]:
			if (x< -130 and z> -92) or (x> -94 and z> -86):continue
			var at:=Vector3(x,0,z)
			var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*1.0,at-Vector3.UP,1)
			var hit:=space.intersect_ray(ray)
			samples+=1
			if hit.is_empty():missing+=1;continue
			if absf(hit.position.y-.5)>.001 or absf(world.get_ground_height(at)-hit.position.y)>.001:mismatched+=1
	check.call(samples>50 and missing==0,"map connector: enclosed land has real collision at every interior sample (%d probes)"%samples)
	check.call(mismatched==0,"map connector: land height queries agree with actual Y0.5 collision")
	var body:=world.get_node("OutdoorRoutes/KelvingroveCentralEmbankment")
	var displays:=body.find_children("*","MeshInstance3D",false,false)
	var shapes:=body.find_children("*","CollisionShape3D",false,false)
	check.call(displays.size()==1 and shapes.size()==1 and body.get_child_count()==2,"map connector: existing grass body retains one display and one shape without extra nodes")
	var up:=0
	var down:=0
	for display:MeshInstance3D in [world.get_node("HorizonContext/CityFootings")]:
		var faces:=display.mesh.get_faces()
		for index:int in range(0,faces.size(),3):
			var centre:Vector3=(faces[index]+faces[index+1]+faces[index+2])/3.0
			if absf(centre.y-.5)>.001 or centre.x< -140 or centre.z< -108 or centre.x< -130 and centre.z> -92:continue
			var normal:Vector3=(faces[index+1]-faces[index]).cross(faces[index+2]-faces[index])
			if normal.y<0:up+=1
			else:down+=1
	check.call(up==6 and down==0,"map connector: six finite front-facing land triangles cover the former hole")
	var ports:=true
	for at:Vector3 in [Vector3(-42,6,-122),Vector3(-88,4,-80),Vector3(-88,3.625,-68),Vector3(-145,2,0)]:
		var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.5,at-Vector3.UP*.5,1))
		ports=not hit.is_empty() and absf(hit.position.y-at.y)<.01 and ports
	check.call(ports,"map connector: civic promenade, climbing lane, cross-street and station mouths retain physical heights")
	var guards:=true
	for sample:Vector3 in [Vector3(-93.8,4,-60),Vector3(-70,5,-85.8),Vector3(-130.2,1.5,-60)]:
		var at:=sample
		var direction:=Vector3.RIGHT if at.x< -90 else Vector3.FORWARD
		var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(at-direction*.5,at+direction*.5,1))
		guards=not hit.is_empty() and guards
	check.call(guards,"map connector: existing physical guards still separate planted ground from skating routes")
