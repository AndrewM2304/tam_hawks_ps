extends "res://game/levels/bowl_feature.gd"
## Original excavated bowl with a real finite entry. The lower circular wall
## retains the tested bowl metric; the absent upper sector joins a native bank.

var port_half_segments := 9
var port_cut_theta := deg_to_rad(40.0)
var access_height := 2.0
var channel_end_z := 10.0
var support_faces := PackedVector3Array()

func build() -> void:
	if _built: return
	super.build()
	# These standalone uphill ramps have no role in a genuinely sunken park.
	for label: String in ["BowlAccessRollIn", "BowlAccessTopLanding"]:
		var obsolete := get_node_or_null(label)
		if obsolete != null:
			remove_child(obsolete)
			obsolete.free()
	_filter_body(surface_body, true, false)
	_filter_body(get_node("AnnularDeck"), false, false)
	_filter_body(get_node("BowlOuterWall"), false, false)
	var steel_body: StaticBody3D = get_node("NativeBowlSteelCoping")
	_filter_body(steel_body, false, true)
	steel_body.set_meta("authored_grind_ids",["Grind_Coping_"+feature_id])
	steel_body.set_meta("audit_capture_ids",["Grind_Coping_"+feature_id])
	var steel: MeshInstance3D = get_node("ContinuousBowlCoping")
	steel.mesh = _mesh(_kept_faces(steel.mesh.get_faces(), false, true))
	_build_access()
	set_meta("skate_feature", "sunken_bowl")

func contact_is_valid(theta: float, lateral: float) -> bool:
	return theta <= port_cut_theta + 0.000001 or not _inside_port(lateral / floor_radius)

func surface_sample(world_point: Vector3) -> Dictionary:
	var value := super.surface_sample(world_point)
	if not value.is_empty():
		value.in_bounds = value.in_bounds and contact_is_valid(float(value.theta), float(value.x))
	return value

func _inside_port(phi: float) -> bool:
	return absf(angle_difference(phi, PI)) < port_half_angle() - 0.000001

func port_half_angle() -> float:
	return float(port_half_segments) * TAU / AROUND_SEGMENTS

func _kept_faces(faces: PackedVector3Array, curved: bool, _steel: bool) -> PackedVector3Array:
	var kept := PackedVector3Array()
	for index in range(0, faces.size(), 3):
		var center := (faces[index] + faces[index + 1] + faces[index + 2]) / 3.0
		var phi := atan2(center.x, -center.z)
		var theta := atan2(Vector2(center.x, center.z).length() - floor_radius, radius - center.y)
		if _inside_port(phi) and (not curved or theta > port_cut_theta + 0.000001): continue
		kept.append_array(PackedVector3Array([faces[index], faces[index + 1], faces[index + 2]]))
	return kept

func _filter_body(body: StaticBody3D, curved: bool, steel: bool) -> void:
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
			child.shape.set_faces(_kept_faces(child.shape.get_faces(), curved, steel))
		elif child is MeshInstance3D and child.mesh != null:
			child.mesh = _mesh(_kept_faces(child.mesh.get_faces(), curved, steel))

func _mesh(faces: PackedVector3Array) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in faces: surface.add_vertex(point)
	surface.generate_normals()
	return surface.commit()

func _build_access() -> void:
	var outer := floor_radius + radius + deck_length
	var inner := floor_radius + radius * sin(port_cut_theta)
	var lower := radius * (1.0 - cos(port_cut_theta))
	var faces := PackedVector3Array()
	const RUN_STEPS := 40
	for run in RUN_STEPS:
		for lateral in port_half_segments * 2:
			var corners := PackedVector3Array()
			for corner: Vector2i in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]:
				var t := float(run + corner.x) / RUN_STEPS
				var phi := PI - port_half_angle() + float(lateral + corner.y) * TAU / AROUND_SEGMENTS
				var rho := lerpf(inner, outer, t)
				# A cubic joins the actual lower circular tangent to a horizontal
				# street landing. The shallow port is simply a level native floor.
				var height := lower * (2*t*t*t - 3*t*t + 1) \
					+ tan(port_cut_theta) * (outer-inner) * (t*t*t - 2*t*t + t) \
					+ access_height * (-2*t*t*t + 3*t*t)
				corners.append(Vector3(sin(phi)*rho, height, -cos(phi)*rho))
			faces.append_array(PackedVector3Array([corners[0],corners[2],corners[1],corners[1],corners[2],corners[3]]))
	# The mouth is an arc, so each flat channel strip starts at that exact arc.
	for lateral in port_half_segments * 2:
		var phi := PI - port_half_angle() + float(lateral) * TAU / AROUND_SEGMENTS
		var phi2 := phi + TAU / AROUND_SEGMENTS
		var a := Vector3(sin(phi)*outer,access_height,-cos(phi)*outer)
		var b := Vector3(sin(phi2)*outer,access_height,-cos(phi2)*outer)
		var c := Vector3(a.x,access_height,channel_end_z)
		var d := Vector3(b.x,access_height,channel_end_z)
		faces.append_array(PackedVector3Array([a,b,c,b,d,c]))
	# Both edge cheeks close the cut concrete without filling the entry.
	var cheeks := PackedVector3Array()
	for side: float in [-1.0,1.0]:
		var phi := PI + side * port_half_angle()
		for run in RUN_STEPS:
			var a := _access_point(float(run)/RUN_STEPS,phi)
			var b := _access_point(float(run+1)/RUN_STEPS,phi)
			# Below the lip the solid cheek ends at the ORIGINAL curved face,
			# not at the rim. A full-height slab here would block a real rider
			# carving off the finite edge into the lower port.
			var c := Vector3(a.x,_original_height(Vector2(a.x,a.z).length()),a.z)
			var d := Vector3(b.x,_original_height(Vector2(b.x,b.z).length()),b.z)
			if side<0:
				cheeks.append_array(PackedVector3Array([a,c,b,b,c,d]))
			else:
				cheeks.append_array(PackedVector3Array([a,b,c,b,d,c]))
	# The original cheeks stopped at the circular mouth. Continue both along
	# the flat channel, closing the visible/collidable gap under the upper deck.
	for side:float in [-1.,1.]:
		var phi:=PI+side*port_half_angle()
		var a:=Vector3(sin(phi)*outer,access_height,-cos(phi)*outer)
		var b:=Vector3(a.x,access_height,channel_end_z)
		var outward:=Vector3(signf(a.x)*.12,0,0)
		var points:=PackedVector3Array([a,b,a+outward,b+outward])
		for at:Vector3 in [a,b,a+outward,b+outward]:points.append(Vector3(at.x,radius,at.z))
		# ExcavatedUpperDeck owns the rim top and NorthStreetRetaining owns
		# the flat street end. Their coplanar cheek caps formerly drew the
		# same surfaces twice. Keep both vertical side faces and the curved
		# mouth end, with native collision following that same face ownership.
		for face:Array in [[0,4,1],[1,4,5],[2,3,6],[3,7,6],[0,2,4],[2,6,4]]:
			var triangle:=PackedVector3Array([points[face[0]],points[face[1]],points[face[2]]])
			if side>0:
				var swap:=triangle[1];triangle[1]=triangle[2];triangle[2]=swap
			cheeks.append_array(triangle)
	_panel("NativePortCheeks",cheeks,_concrete_material())
	# All access floor triangles must follow Godot's clockwise front-face
	# convention. Native backface collision must not hide invisible concrete.
	for index in range(0,faces.size(),3):
		if (faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).y>0:
			var swap := faces[index+1]
			faces[index+1] = faces[index+2]
			faces[index+2] = swap
	_panel("NativeGentlePort",faces,_concrete_material())
	support_faces = faces

func _original_height(rho: float) -> float:
	if rho>=floor_radius+radius: return radius
	return radius-sqrt(maxf(0.0,radius*radius-pow(rho-floor_radius,2)))

func _access_point(t: float, phi: float) -> Vector3:
	var outer := floor_radius+radius+deck_length
	var inner := floor_radius+radius*sin(port_cut_theta)
	var lower := radius*(1.0-cos(port_cut_theta))
	var height := lower*(2*t*t*t-3*t*t+1) + tan(port_cut_theta)*(outer-inner)*(t*t*t-2*t*t+t) \
		+ access_height*(-2*t*t*t+3*t*t)
	return Vector3(sin(phi)*lerpf(inner,outer,t),height,-cos(phi)*lerpf(inner,outer,t))

func get_deck_voids() -> Array[PackedVector2Array]:
	var outer := floor_radius+radius+deck_length
	var circle := PackedVector2Array()
	for i in AROUND_SEGMENTS:
		var phi := float(i)/AROUND_SEGMENTS*TAU
		var p := to_global(Vector3(sin(phi)*outer,radius,-cos(phi)*outer))
		circle.append(Vector2(p.x,p.z))
	var channel := PackedVector2Array()
	for i in port_half_segments*2+1:
		var phi := PI-port_half_angle()+float(i)*TAU/AROUND_SEGMENTS
		var p := to_global(Vector3(sin(phi)*outer,radius,-cos(phi)*outer))
		channel.append(Vector2(p.x,p.z))
	var right := to_global(Vector3(sin(PI+port_half_angle())*outer,radius,channel_end_z))
	var left := to_global(Vector3(sin(PI-port_half_angle())*outer,radius,channel_end_z))
	channel.append(Vector2(right.x,right.z))
	channel.append(Vector2(left.x,left.z))
	return [circle,channel]

func get_grind_lines() -> Array:
	var points := PackedVector3Array()
	var count := AROUND_SEGMENTS-port_half_segments*2
	for i in count+1:
		var phi := PI+port_half_angle()+float(i)*TAU/AROUND_SEGMENTS
		# The track bears on the actual torus crown, matching lip_frame().
		points.append(sample(PI*0.5,phi*floor_radius).point+Vector3.UP*0.070)
	return [_native_coping_line("Grind_Coping_"+feature_id,points,"coping")]

func get_feature_definitions() -> Array:
	return [{"id":feature_id,"kind":"sunken_bowl","floor_y":global_position.y,"position":global_position,
		"radius":radius,"floor_radius":floor_radius,"rim_y":global_position.y+radius,
		"entry":to_global(Vector3(0,access_height,channel_end_z)),"bottom":global_position,
		"port_half_angle":port_half_angle(),"port_cut_theta":port_cut_theta,
		"lip":lip_frame(0.0).point}]
