extends "res://game/levels/transition_feature.gd"
## Original circular bowl: one finite shared mesh/collision wall, real flat
## bottom, annular deck and optional external roll-in. Lateral coordinates wrap.

var floor_radius := 3.5
const AROUND_SEGMENTS := 128
const VERTICAL_SEGMENTS := 90

func build() -> void:
	if _built: return
	_built = true
	radius = clampf(radius, 1.5, 3.5)
	floor_radius = clampf(floor_radius, 3.0, 8.0)
	deck_length = clampf(deck_length, 1.5, 3.0)
	width = TAU * floor_radius
	wrap_lateral = true
	add_to_group("skate_transitions")
	set_meta("skate_feature", "bowl")
	var concrete := _concrete_material()
	var faces := PackedVector3Array()
	for i in VERTICAL_SEGMENTS:
		for j in AROUND_SEGMENTS:
			var t := float(i) / VERTICAL_SEGMENTS * PI * 0.5
			var t2 := float(i + 1) / VERTICAL_SEGMENTS * PI * 0.5
			var x := float(j) / AROUND_SEGMENTS * width
			var x2 := float(j + 1) / AROUND_SEGMENTS * width
			var a: Vector3 = local_sample(t,x).point
			var b: Vector3 = local_sample(t,x2).point
			var c: Vector3 = local_sample(t2,x).point
			var d: Vector3 = local_sample(t2,x2).point
			faces.append_array(PackedVector3Array([a,c,b,b,c,d]))
	surface_body = StaticBody3D.new()
	surface_body.name = "ContinuousBowlWall"
	surface_body.set_meta("transition_feature", self)
	surface_body.set_meta("surface_audio", "stone")
	surface_body.set_meta("wallrideable", false)
	add_child(surface_body)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	surface_body.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in faces:
		var radial := Vector3(point.x,0,point.z).normalized()
		var theta := atan2(Vector2(point.x,point.z).length()-floor_radius,radius-point.y)
		surface.set_normal(Vector3.UP*cos(theta)-radial*sin(theta))
		surface.add_vertex(point)
	var mesh := MeshInstance3D.new()
	mesh.name = "ContinuousConcreteBowl"
	mesh.mesh = surface.commit()
	mesh.material_override = concrete
	surface_body.add_child(mesh)
	var deck := PackedVector3Array()
	var outer_wall := PackedVector3Array()
	var inner := floor_radius + radius
	var outer := inner + deck_length
	for i in AROUND_SEGMENTS:
		var radial := Vector3(sin(float(i)/AROUND_SEGMENTS*TAU),0,-cos(float(i)/AROUND_SEGMENTS*TAU))
		var radial2 := Vector3(sin(float(i+1)/AROUND_SEGMENTS*TAU),0,-cos(float(i+1)/AROUND_SEGMENTS*TAU))
		var a := radial*inner+Vector3.UP*radius
		var b := radial2*inner+Vector3.UP*radius
		var c := radial*outer+Vector3.UP*radius
		var d := radial2*outer+Vector3.UP*radius
		deck.append_array(PackedVector3Array([a,c,b,b,c,d]))
		outer_wall.append_array(PackedVector3Array([c,radial*outer,d,d,radial*outer,radial2*outer]))
	_panel("AnnularDeck",deck,concrete)
	_panel("BowlOuterWall",outer_wall,concrete)
	var bottom := StaticBody3D.new()
	bottom.name = "FlatBowlBottom"
	bottom.position.y = -0.12
	bottom.set_meta("surface_audio","stone")
	add_child(bottom)
	var bottom_shape := CylinderShape3D.new()
	bottom_shape.height = 0.24
	bottom_shape.radius = floor_radius + 0.01
	var bottom_collision := CollisionShape3D.new()
	bottom_collision.shape = bottom_shape
	bottom.add_child(bottom_collision)
	var bottom_mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.height = 0.24
	cylinder.top_radius = floor_radius + 0.01
	cylinder.bottom_radius = floor_radius + 0.01
	cylinder.radial_segments = AROUND_SEGMENTS
	bottom_mesh.mesh = cylinder
	bottom_mesh.material_override = concrete
	bottom.add_child(bottom_mesh)
	# Finish above the outer retaining wall before joining the annular deck.
	# Ending the slope inside the ring would send its approach under that wall.
	if build_access:
		var run := 7.7
		var angle := atan2(radius,run)
		var start := Vector3(0,0,outer+8)
		var finish := Vector3(0,radius,outer+0.3)
		var ramp := _box("BowlAccessRollIn",Vector3(4,0.24,sqrt(run*run+radius*radius)),
			(start+finish)*0.5-Vector3(0,cos(angle),sin(angle))*0.12,concrete)
		ramp.rotation.x = angle
		_box("BowlAccessTopLanding",Vector3(4,0.24,1.0),Vector3(0,radius-0.12,outer-0.15),concrete)
	var coping := MeshInstance3D.new()
	coping.name = "ContinuousBowlCoping"
	var torus := TorusMesh.new()
	torus.inner_radius = inner-0.045
	torus.outer_radius = inner+0.045
	torus.rings = AROUND_SEGMENTS
	torus.ring_segments = 16
	coping.mesh = torus
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("bdc4c1")
	steel.metallic = 0.75
	steel.roughness = 0.4
	coping.material_override = steel
	coping.position.y = radius+0.025
	add_child(coping)
	var coping_body := StaticBody3D.new()
	coping_body.name = "NativeBowlSteelCoping"
	coping_body.set_meta("authored_grind_ids",["Grind_Coping_"+feature_id])
	coping_body.set_meta("audit_capture_ids",["Grind_Coping_"+feature_id])
	coping_body.collision_layer = 1 | 2
	coping_body.transform = coping.transform
	coping_body.set_meta("coping_feature",self)
	coping_body.set_meta("surface_audio","metal")
	add_child(coping_body)
	var coping_shape := ConcavePolygonShape3D.new()
	coping_shape.backface_collision = true
	coping_shape.set_faces(torus.get_faces())
	var coping_collision := CollisionShape3D.new()
	coping_collision.shape = coping_shape
	coping_body.add_child(coping_collision)

func local_sample(theta: float, lateral: float) -> Dictionary:
	var phi := lateral/floor_radius
	var radial := Vector3(sin(phi),0,-cos(phi))
	return {"point":radial*(floor_radius+radius*sin(theta))+Vector3.UP*radius*(1.0-cos(theta)),
		"normal":Vector3.UP*cos(theta)-radial*sin(theta),
		"tangent":radial*cos(theta)+Vector3.UP*sin(theta),
		"lateral":Vector3(cos(phi),0,sin(phi)),"theta":theta,"x":wrapf(lateral,-width*0.5,width*0.5)}

func sample(theta: float, lateral: float) -> Dictionary:
	var value := local_sample(theta,lateral)
	value.point = to_global(value.point)
	for axis: String in ["normal","tangent","lateral"]:
		value[axis] = (global_basis*Vector3(value[axis])).normalized()
	return value

func surface_sample(world_point: Vector3) -> Dictionary:
	if not world_point.is_finite() or global_basis.get_scale().distance_to(Vector3.ONE)>0.001: return {}
	var local := to_local(world_point)
	var rho := Vector2(local.x,local.z).length()
	var theta := atan2(rho-floor_radius,radius-local.y)
	var value := sample(clampf(theta,0,PI*0.5),atan2(local.x,-local.z)*floor_radius)
	value.in_bounds = rho>=floor_radius-0.10 and theta>=-0.03 and theta<=PI*0.5+0.04
	value.distance = world_point.distance_to(value.point)
	return value

func advance_lateral(theta: float, lateral: float, metres: float) -> float:
	return wrapf(lateral+metres*floor_radius/(floor_radius+radius*sin(theta)),-width*0.5,width*0.5)

func lateral_acceleration(theta: float, _lateral: float, radial_speed: float, around_speed: float) -> Vector2:
	var connection := cos(theta)/(floor_radius+radius*sin(theta))
	return Vector2(around_speed*around_speed*connection,-radial_speed*around_speed*connection)

func air_return_frame(world_point: Vector3, _lateral: float) -> Dictionary:
	var local := to_local(world_point)
	var frame := lip_frame(atan2(local.x,-local.z)*floor_radius)
	frame.normal = frame.face_normal
	frame.over_lip = local.y>=radius-0.12 and absf(Vector2(local.x,local.z).length()-floor_radius-radius)<0.55
	frame.lip_height = frame.point.y
	return frame

func get_grind_lines() -> Array:
	var points := PackedVector3Array()
	for i in AROUND_SEGMENTS+1:
		points.append(sample(PI*0.5,float(i)/AROUND_SEGMENTS*width).point+Vector3.UP*0.070)
	return [_native_coping_line("Grind_Coping_"+feature_id,points,"coping")]

func get_feature_definitions() -> Array:
	var outer := floor_radius+radius+deck_length
	var approach_y := 0.0 if build_access else radius
	return [{"id":feature_id,"kind":"bowl","floor_y":global_position.y,
		"rim_y":to_global(Vector3.UP*radius).y,
		"outer_radius":outer,"roll_in_end":to_global(Vector3(0,approach_y,outer+8)),
		"approach":PackedVector3Array([to_global(Vector3(0,approach_y,outer+10)),to_global(Vector3(0,radius,outer-0.8))]),
		"bottom":global_position,"lip":lip_frame(0.0).point}]

## Exact height of the unported, yaw-only bowl's sampled collision, including
## between angular spokes. Ring trapezoids are planar along the sector bisector.
func get_surface_height(world_point: Vector3) -> float:
	var local := to_local(world_point)
	var phi := wrapf(atan2(local.x,-local.z),0.0,TAU)
	var sector := TAU/AROUND_SEGMENTS
	var middle := (floorf(phi/sector)+0.5)*sector
	var rho := Vector2(local.x,local.z).length()*cos(phi-middle)/cos(sector*0.5)
	var height := radius
	if rho<=floor_radius:
		height = 0.0
	elif rho<floor_radius+radius:
		var step := PI*0.5/VERTICAL_SEGMENTS
		var theta := asin(clampf((rho-floor_radius)/radius,0.0,1.0))
		var lower := minf(floorf(theta/step),VERTICAL_SEGMENTS-1)*step
		var fraction := (rho-floor_radius-radius*sin(lower))/(radius*(sin(lower+step)-sin(lower)))
		height = lerpf(radius*(1-cos(lower)),radius*(1-cos(lower+step)),fraction)
	return to_global(Vector3(local.x,height,local.z)).y
