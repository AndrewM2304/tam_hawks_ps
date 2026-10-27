extends RefCounted
## Native arrays, displayed cup profile and unchanged physical fountain contract.
const Ornament = preload("res://game/levels/art/fountain_ornament.gd")
# Godot packs native normal/tangent directions. Built-in CylinderMesh controls
# also exceed a 1e-4 decoded dot error; keep the angular precision explicit.
const MAX_NATIVE_FRAME_ANGLE_DEGREES := 0.02


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	await tree.physics_frame
	var world: Node3D=game.world
	var body: StaticBody3D=world.get_node("ExchangeFountain")
	var parts: Array[MeshInstance3D]=[]
	var transforms:=true
	var materials:=true
	var shared:=true
	var vertices:=0
	var triangles:=0
	var valid:=true
	var clockwise:=true
	var enclosed:=true
	var max_frame_angle:=0.0
	for spec: Array in [["FountainPedestal",Vector3(0,1.2,0),"stone_light"],
			["FountainBowl",Vector3(0,2.1,0),"stone_light"],
			["FountainCrown",Vector3(0,2.7,0),"bronze"]]:
		var part: MeshInstance3D=body.get_node(spec[0])
		parts.append(part)
		transforms=transforms and part.transform==Transform3D(Basis.IDENTITY,spec[1]) \
			and part.get_meta("art_label")==spec[0]
		materials=materials and part.material_override==world._materials[spec[2]]
		shared=shared and part.mesh is ArrayMesh and part.mesh==Ornament.shared_mesh(spec[0]) \
			and part.mesh.get_surface_count()==1
		var arrays:=part.mesh.surface_get_arrays(0)
		var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
		var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		vertices+=positions.size()
		triangles+=indices.size()/3
		valid=valid and positions.size()==normals.size() and positions.size()==uvs.size() \
			and tangents.size()==positions.size()*4 and indices.size()%3==0
		for index: int in positions.size():
			var tangent:=Vector3(tangents[index*4],tangents[index*4+1],tangents[index*4+2])
			var frame_angle:=rad_to_deg(asin(clampf(absf(tangent.normalized().dot(normals[index].normalized())),0.0,1.0)))
			max_frame_angle=maxf(max_frame_angle,frame_angle)
			valid=valid and positions[index].is_finite() and normals[index].is_finite() \
				and tangent.is_finite() and uvs[index].is_finite() and absf(normals[index].length()-1.0)<.0001 \
				and absf(tangent.length()-1.0)<.0001 and frame_angle<=MAX_NATIVE_FRAME_ANGLE_DEGREES \
				and absf(absf(tangents[index*4+3])-1.0)<.0001
			enclosed=enclosed and _inside_old_envelope(part.transform*positions[index])
		for face: int in range(0,indices.size(),3):
			var a:=indices[face]
			var b:=indices[face+1]
			var c:=indices[face+2]
			valid=valid and mini(a,mini(b,c))>=0 and maxi(a,maxi(b,c))<positions.size()
			var cross: Vector3=(positions[b]-positions[a]).cross(positions[c]-positions[a])
			clockwise=clockwise and cross.length_squared()>.0000000001 \
				and cross.dot(normals[a]+normals[b]+normals[c])<0.0
	check.call(transforms and materials and shared,
		"fountain ornament: three original display slots keep transforms/material identities and share indexed native meshes")
	check.call(triangles==288 and triangles<=360 and vertices<=270,
		"fountain ornament: real native arrays use288triangles within original360triangle/270vertex display budget")
	check.call(valid and clockwise,
		"fountain ornament: displayed triangles have finite indexed geometry, clockwise winding and unit UV frames within0.02degree native packing precision")
	check.call(enclosed,
		"fountain ornament: all display vertices stay inside the original combined authored frusta envelope")
	var bowl: MeshInstance3D=parts[1]
	var inner:=_display_hit_y(bowl,Vector3(.7,4,10))
	var rim:=_display_hit_y(bowl,Vector3(1.58,4,10))
	var floor_y:=_display_hit_y(bowl,Vector3(.2,4,10))
	check.call(inner>2.08 and inner<2.30 and absf(rim-2.35)<.00001 and absf(floor_y-2.08)<.00001,
		"fountain ornament: actual displayed rays find the recessed cup floor/inner wall and raised annular lip instead of a solid top disk")
	var crown_min:=INF
	for point: Vector3 in parts[2].mesh.get_faces():crown_min=minf(crown_min,(parts[2].transform*point).y)
	var pedestal_top: float=parts[0].position.y+parts[0].mesh.get_aabb().end.y
	check.call(absf(crown_min-floor_y)<.00001 and pedestal_top<floor_y-.15,
		"fountain ornament: finial foot meets the displayed inner floor while the pedestal stays below the cup")
	var shapes: Array[CollisionShape3D]=[]
	for child: Node in body.get_children():
		if child is CollisionShape3D:shapes.append(child)
	var native:=shapes.size()==2 and shapes[0].shape is CylinderShape3D \
		and is_equal_approx(shapes[0].shape.radius,6.2) and is_equal_approx(shapes[0].shape.height,.55) \
		and shapes[0].position==Vector3(0,.275,0) and shapes[1].shape is CylinderShape3D \
		and is_equal_approx(shapes[1].shape.radius,.7) and is_equal_approx(shapes[1].shape.height,2.7) \
		and shapes[1].position==Vector3(0,1.35,0)
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(0,4,10),Vector3(0,0,10),1))
	check.call(native and not hit.is_empty() and hit.collider==body and absf(hit.position.y-2.7)<.001,
		"fountain ornament: the existing two native shapes and2.7m pedestal top remain unchanged; the decorative cup is not new playable support")
	print("FOUNTAIN_ORNAMENT ",{"vertices":vertices,"triangles":triangles,"native_unchanged":native,
		"inner_y":inner,"rim_y":rim,"floor_y":floor_y,"crown_foot_y":crown_min,"pedestal_top_y":pedestal_top,
		"max_native_frame_angle_degrees":max_frame_angle})


static func _inside_old_envelope(point: Vector3) -> bool:
	var radius:=Vector2(point.x,point.z).length()
	for old: Vector4 in [Vector4(.2,2.2,1.0,.65),Vector4(1.85,2.35,.65,1.65),
			Vector4(2.275,3.125,.42,.22)]:
		if point.y<old.x-.00001 or point.y>old.y+.00001:continue
		var t:=clampf((point.y-old.x)/(old.y-old.x),0.0,1.0)
		if radius<=lerpf(old.z,old.w,t)+.00001:return true
	return false


static func _display_hit_y(mesh: MeshInstance3D, origin: Vector3) -> float:
	var highest: float=-INF
	var faces:=mesh.mesh.get_faces()
	for face: int in range(0,faces.size(),3):
		var hit: Variant=Geometry3D.ray_intersects_triangle(origin,Vector3.DOWN,
			mesh.to_global(faces[face]),mesh.to_global(faces[face+1]),mesh.to_global(faces[face+2]))
		if hit is Vector3:highest=maxf(highest,hit.y)
	return highest
