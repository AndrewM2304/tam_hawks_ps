extends RefCounted
## Independent PT24-08/09 witnesses: expected ramp sides, native two-sided
## coverage, outward mesh winding and one owner for each shared cheek cap.

static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var park: Node3D = game.world.find_child("KelvingroveSunkenSkatepark",true,false)
	check.call(park!=null,"park construction: ordinary world contains the reported facility")
	if park==null:return
	await tree.physics_frame
	# The required sides are authored independently of the resulting meshes:
	# looking only at existing triangles cannot catch an omitted side wall.
	for witness: Dictionary in [
		{"label":"BeginnerArrivalBank","a":Vector3(17.5,0,6.5),"b":Vector3(7.5,-1.5,6.5),"out":Vector3.FORWARD},
		{"label":"BeginnerArrivalBank","a":Vector3(17.5,0,10.5),"b":Vector3(7.5,-1.5,10.5),"out":Vector3.BACK},
		{"label":"StepBypassBank","a":Vector3(2,0,3.5),"b":Vector3(2,-1.5,9.5),"out":Vector3.LEFT},
		{"label":"StepBypassBank","a":Vector3(5,0,3.5),"b":Vector3(5,-1.5,9.5),"out":Vector3.RIGHT},
	]:
		var body: StaticBody3D = park.get_node(witness.label)
		var native_faces := _native_faces(body)
		var visual_faces := _visual_faces(body)
		var both_sides := true
		var visible_outside := true
		var samples := 0
		for step in range(1,20):
			var top: Vector3 = witness.a.lerp(witness.b,float(step)/20.0)
			for height: float in [0.2,0.5,0.8]:
				var local := Vector3(top.x,lerpf(-1.5,top.y,height),top.z)
				var origin := park.to_global(local)
				var outside: Vector3 = park.global_basis*witness.out
				for sign: float in [-1.0,1.0]:
					var hit := _ray(park,origin+outside*0.025*sign,origin-outside*0.025*sign)
					both_sides = both_sides and not hit.is_empty() and hit.get("collider")==body
				visible_outside = visible_outside and _front_face_at(visual_faces,local,witness.out)
				samples += 1
		check.call(both_sides,"park construction: "+witness.label+" "+str(witness.out)+" has native side coverage from both directions at "+str(samples)+" independent points")
		check.call(visible_outside and _same_faces(visual_faces,native_faces),
			"park construction: "+witness.label+" exposed side has outward visible faces matching actual collision")
	# The upper deck and the street retaining face already close these joins.
	# Duplicate cheek caps would reintroduce z-fighting even with good collision.
	for bowl_name: String in ["DeepBowl","ShallowBowl"]:
		var bowl: Node3D = park.get_node(bowl_name)
		var cheeks: StaticBody3D = bowl.get_node("NativePortCheeks")
		var no_duplicate_caps := true
		var faces := _visual_faces(cheeks)
		for i in range(0,faces.size(),3):
			var a := faces[i]
			var b := faces[i+1]
			var c := faces[i+2]
			var cap_top := absf(a.y-bowl.radius)<0.00001 and absf(b.y-bowl.radius)<0.00001 and absf(c.y-bowl.radius)<0.00001
			var cap_end := absf(a.z-bowl.channel_end_z)<0.00001 and absf(b.z-bowl.channel_end_z)<0.00001 and absf(c.z-bowl.channel_end_z)<0.00001
			no_duplicate_caps = no_duplicate_caps and not cap_top and not cap_end
		check.call(no_duplicate_caps and _same_faces(faces,_native_faces(cheeks)),
			"park construction: "+bowl_name+" cheek mesh/collision omit coplanar deck and street-end caps")
		var shared_join_closed := true
		var outer: float = bowl.floor_radius+bowl.radius+bowl.deck_length
		for side: float in [-1.0,1.0]:
			var phi: float = PI+side*bowl.port_half_angle()
			var x := sin(phi)*outer
			var mouth_z := -cos(phi)*outer
			var strip_x := x+signf(x)*0.06
			var cap := bowl.to_global(Vector3(strip_x,bowl.radius,(mouth_z+bowl.channel_end_z)*0.5))
			var top_hit := _ray(park,cap+Vector3.UP*0.1,cap-Vector3.UP*0.1)
			var street := bowl.to_global(Vector3(strip_x,(bowl.radius+bowl.access_height)*0.5,bowl.channel_end_z))
			var end_hit := _ray(park,street+Vector3.BACK*0.1,street-Vector3.BACK*0.1)
			shared_join_closed = shared_join_closed and not top_hit.is_empty() and top_hit.get("collider")==park.get_node("ExcavatedUpperDeck") \
				and not end_hit.is_empty() and _street_retaining(end_hit.get("collider"),park)
		check.call(shared_join_closed,"park construction: "+bowl_name+" shared deck and street faces retain native closure after duplicate-cap removal")


static func _native_faces(body: StaticBody3D) -> PackedVector3Array:
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
			return child.shape.get_faces()
	return PackedVector3Array()


static func _visual_faces(body: StaticBody3D) -> PackedVector3Array:
	for child: Node in body.get_children():
		if child is MeshInstance3D and child.mesh!=null:return child.mesh.get_faces()
	return PackedVector3Array()


static func _same_faces(visual: PackedVector3Array,native: PackedVector3Array) -> bool:
	if visual.size()!=native.size():return false
	# ArrayMesh compresses decimal vertices at commit; compare positions within
	# its sub-millimetre precision rather than requiring identical byte storage.
	for i in visual.size():
		if visual[i].distance_to(native[i])>0.00025:return false
	return true


static func _street_retaining(body: Node3D,park: Node3D) -> bool:
	# Repeated Node names are intentionally not a geometry oracle: Godot may
	# assign an internal generated name to the later retaining spans.
	return body!=null and body.get_parent()==park and absf(body.position.z-3.425)<0.00001 \
		and absf(body.position.y+0.75)<0.00001


static func _front_face_at(faces: PackedVector3Array, point: Vector3, outward: Vector3) -> bool:
	for i in range(0,faces.size(),3):
		var a := faces[i]
		var b := faces[i+1]
		var c := faces[i+2]
		var cross := (b-a).cross(c-a)
		if cross.length_squared()<0.00000001:continue
		if -cross.normalized().dot(outward)<0.99:continue
		if absf(cross.normalized().dot(point-a))>0.00001:continue
		var ab := b-a
		var ac := c-a
		var relative := point-a
		var denominator := ab.dot(ab)*ac.dot(ac)-pow(ab.dot(ac),2)
		var u := (ac.dot(ac)*relative.dot(ab)-ab.dot(ac)*relative.dot(ac))/denominator
		var v := (ab.dot(ab)*relative.dot(ac)-ab.dot(ac)*relative.dot(ab))/denominator
		if u>=-0.00001 and v>=-0.00001 and u+v<=1.00001:return true
	return false


static func _ray(park: Node3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	query.hit_back_faces = true
	return park.get_world_3d().direct_space_state.intersect_ray(query)
