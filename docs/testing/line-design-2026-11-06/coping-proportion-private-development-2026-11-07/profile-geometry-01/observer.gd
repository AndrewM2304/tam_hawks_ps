extends SceneTree
## Private physical-proportion witness. No Main, Skater, actor or input tuning.
const Quarter = preload("res://game/levels/transition_feature.gd")
const Bowl = preload("res://game/levels/bowl_feature.gd")
const Sunken = preload("res://game/levels/sunken_bowl_feature.gd")
const OldQuarter = preload("res://.local/baseline-70mm/transition_feature.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		print("FAIL ",label)

func _run() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	var features: Array[Node3D] = []
	for index: int in 3:
		var feature: Node3D = Quarter.new() if index==0 else (Bowl.new() if index==1 else Sunken.new())
		feature.feature_id = ["PrivateProfileQuarter","PrivateProfileBowl","PrivateProfileSunken"][index]
		feature.position = Vector3(28.0*index,3.0,0)
		feature.rotation.y = 0.37
		feature.build_access = false
		fixture.add_child(feature)
		features.append(feature)
	var old: Node3D = OldQuarter.new()
	old.feature_id = "RetainedOld70mmQuarter"
	old.position = Vector3(-28.0,3.0,0)
	old.rotation.y = 0.37
	old.build_access = false
	fixture.add_child(old)
	await physics_frame
	await physics_frame
	for index: int in features.size():
		_inspect(features[index],index>0,index==2)
	var old_body: StaticBody3D = old.get_node("NativeSteelCoping")
	var old_shape: CylinderShape3D = old_body.get_child(0).shape
	_check(absf(old_shape.radius-.045)<.000001 and absf(old_body.position.y-old.radius-.025)<.000001,
		"retained original fixture independently contains90mmOD/70mmdeckcrown")
	_check(not _quarter_profile(old),"original70mm profile rejects proposed60mmOD/12mmup/10mmout specification")
	fixture.queue_free()
	await process_frame
	print("RESULT ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)

func _quarter_profile(feature: Node3D) -> bool:
	var body: StaticBody3D = feature.get_node("NativeSteelCoping")
	var shape: CylinderShape3D = body.get_child(0).shape
	return absf(shape.radius-.030)<.000001 and absf(body.position.y-feature.radius+.018)<.000001 \
		and absf(body.position.z+feature.radius+.020)<.000001

func _inspect(feature: Node3D, curved: bool, port: bool) -> void:
	var body: StaticBody3D = feature.get_node("NativeBowlSteelCoping" if curved else "NativeSteelCoping")
	var visual: MeshInstance3D = feature.get_node("ContinuousBowlCoping" if curved else "ContinuousSteelCoping")
	var shape: Shape3D = body.get_child(0).shape
	_check(body.global_transform.is_equal_approx(visual.global_transform) and body.collision_layer==3 \
		and body.get_meta("coping_feature",null)==feature,
		feature.feature_id+": visible/native frame,mask and real owner match")
	if curved:
		_check(shape is ConcavePolygonShape3D and shape.get_faces()==visual.mesh.get_faces(),
			feature.feature_id+": every displayed steel triangle equals actual native face")
		var inner: float = feature.floor_radius+feature.radius
		var bounds := AABB()
		var first := true
		var finite := true
		for at: Vector3 in shape.get_faces():
			finite = finite and at.is_finite()
			if first: bounds=AABB(at,Vector3.ZERO);first=false
			else: bounds=bounds.expand(at)
		_check(finite and absf(bounds.position.y+.030)<.000002 and absf(bounds.end.y-.030)<.000002 \
			and absf(body.position.y-feature.radius+.018)<.000002,
			feature.feature_id+": actual torus section60mm and crown12mm above deck")
		if not port:
			var torus: TorusMesh=visual.mesh
			_check(absf((torus.inner_radius+torus.outer_radius)*.5-inner-.020)<.000002 \
				and absf(torus.outer_radius-torus.inner_radius-.060)<.000002,
				feature.feature_id+": major radius20mm behind tangent,minordiameter60mm")
	else:
		var cylinder: CylinderMesh=visual.mesh
		_check(_quarter_profile(feature) and absf(cylinder.top_radius-.030)<.000001 \
			and absf(cylinder.bottom_radius-.030)<.000001 and absf(cylinder.height-feature.width)<.000001,
			feature.feature_id+": actual native/display60mm pipe axis−18mmY/−20mmZ")
	var samples := ([0,16,31,95,112] if port else [0,16,31,63,95,112]) if curved else [0,1,2]
	var top_ok := true
	var front_ok := true
	var datum_ok := true
	var max_error := 0.0
	for index: int in samples:
		var lateral: float = float(index)/128.0*feature.width if curved else (float(index)-1.0)*feature.width*.3
		var concrete: Dictionary=feature.sample(PI*.5,lateral)
		var inward: Vector3=concrete.normal
		var expected: Vector3=concrete.point+Vector3.UP*.012-inward*.020
		var crown: Dictionary=feature.lip_frame(lateral)
		datum_ok = datum_ok and Vector3(crown.point).distance_to(expected)<.00001 \
			and crown.normal==Vector3.UP and Vector3(crown.face_normal).distance_to(inward)<.00001
		var hit := _ray(feature,expected+Vector3.UP*.080,expected-Vector3.UP*.080)
		top_ok = top_ok and not hit.is_empty() and hit.collider==body
		if not hit.is_empty():
			max_error=maxf(max_error,Vector3(hit.position).distance_to(expected))
			top_ok = top_ok and hit.normal.y>.95 and Vector3(hit.position).distance_to(expected)<.002
		var front: Vector3=concrete.point-Vector3.UP*.018+inward*.010
		var face := _ray(feature,front+inward*.080,front-inward*.080)
		front_ok = front_ok and not face.is_empty() and face.collider==body
		if not face.is_empty():front_ok=front_ok and Vector3(face.position).distance_to(front)<.002 and Vector3(face.normal).dot(inward)>.95
	_check(datum_ok,feature.feature_id+": independent12mmup/20mmbehind crown and face normal match public lip datum")
	_check(top_ok,feature.feature_id+": actual native top rays hit real crown within2mm")
	_check(front_ok,feature.feature_id+": actual native inward rays hit10mm exposed face within2mm")
	var lines: Array=feature.get_grind_lines()
	var expected_id: String = "Grind_Coping_"+feature.feature_id if curved else "Grind_"+feature.feature_id+"_Coping"
	var guide_ok := lines.size()==1 and lines[0].id==expected_id and lines[0].is_valid and lines[0].contact_verified \
		and lines[0].contact_source=="feature.native_coping_crown" and absf(lines[0].contact_vertical_offset)<.000001
	if lines.size()==1:
		for world_point: Vector3 in lines[0].points:
			var local: Vector3=feature.to_local(world_point)
			guide_ok=guide_ok and absf(local.y-feature.radius-.012)<.00001
			if curved:guide_ok=guide_ok and absf(Vector2(local.x,local.z).length()-feature.floor_radius-feature.radius-.020)<.00001
			else:guide_ok=guide_ok and absf(local.z+feature.radius+.020)<.00001
	_check(guide_ok,feature.feature_id+": unchanged guide identity/source bears on same actual crown withoutoffset")
	if port:
		var through: Dictionary=feature.sample(PI*.5,PI*feature.floor_radius)
		var absent: Vector3=through.point+Vector3.UP*.012-Vector3(through.normal)*.020
		_check(_ray(feature,absent+Vector3.UP*.080,absent-Vector3.UP*.080).is_empty(),
			feature.feature_id+": real entry port has no steel collision across open mouth")
	print("PRIVATE_PROFILE_GEOMETRY ",{"id":feature.feature_id,"radius_m":.030,"deck_reveal_m":.012,
		"face_reveal_m":.010,"max_native_crown_error_m":max_error,"guide_points":lines[0].points.size() if lines.size()==1 else 0})

func _ray(feature: Node3D,from: Vector3,to: Vector3) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(from,to,2)
	query.hit_back_faces=false
	return feature.get_world_3d().direct_space_state.intersect_ray(query)
