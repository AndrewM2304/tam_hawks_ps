extends Node3D
## Original activity hosts use the existing cleared adult anatomy and native
## skinned clothing. Root placement/identity belongs to the activity; only this
## noncolliding visual body settles to independently probed ground contacts.
const Garments = preload("res://game/player/skater_garments.gd")
const Anatomy = preload("res://game/player/skater_anatomy.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const COAT_PROFILE: Array[Vector4] = [Vector4(0.015,0.176,0.126,0),Vector4(0.04,0.178,0.127,0),
	Vector4(0.10,0.174,0.121,0),Vector4(0.17,0.175,0.116,-0.002),
	Vector4(0.25,0.188,0.118,-0.005),Vector4(0.33,0.207,0.121,-0.007),
	Vector4(0.40,0.219,0.115,-0.003),Vector4(0.44,0.204,0.104,0),Vector4(0.475,0.131,0.081,-0.003)]

var steward := false
var reduced_motion := false
var _body: Node3D
var _details: Node3D
var _head: Node3D
var _garments: RefCounted
var _anatomy: RefCounted
var _feet: Array[Dictionary] = []
var _hands: Array[Node3D] = []
var _phase := 0.0
var _state := "idle"
var _gesture := ""
var _gesture_remaining := 0.0
var _offer_blend := 0.0
var _success_blend := 0.0
var _look_yaw := 0.0
var _look_target := Vector3.INF
var _near := false
var _ground_timer := 0.0
var _grounded := false
var _last_root := Transform3D.IDENTITY
var _skater: WeakRef


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	_body = Node3D.new()
	_body.name = "AdultActivityBody"
	_body.visible = false
	add_child(_body)
	var coat := _material(Color("34454b") if steward else Color("675460"))
	var trousers := _material(Color("303b3d"))
	var shoes := _material(Color("303432"))
	var rubber := _material(Color("858b83"))
	_garments = Garments.new()
	_garments.build(_body,coat,trousers)
	_anatomy = Anatomy.new()
	_details = Node3D.new()
	_details.name = "HiVisWaistcoat" if steward else "CoatDetails"
	_body.add_child(_details)
	_build_clothing_details(coat)
	_head = Node3D.new()
	_head.name = "Head"
	_body.add_child(_head)
	_anatomy.build_head(_head)
	for side: float in [-1.0,1.0]:
		var foot := Node3D.new()
		foot.name = "LeftShoe" if side < 0.0 else "RightShoe"
		_body.add_child(foot)
		Footwear.build(foot,shoes,rubber,trousers)
		_feet.append({"node":foot,"side":side,"point":Vector3.ZERO,"normal":Vector3.UP})
		_hands.append(_anatomy.build_hand(_body,side))
	_find_skater()
	_pose(0.0)


func _physics_process(delta: float) -> void:
	_ground_timer -= delta
	if not _grounded or _ground_timer <= 0.0 or not global_transform.is_equal_approx(_last_root):
		_refresh_ground()
		_ground_timer = 0.35


func _process(delta: float) -> void:
	if not _grounded or not is_finite(delta) or delta <= 0.0: return
	_read_activity_state()
	if _motion_reduced(): return
	var step := minf(delta,0.1)
	_phase += step
	_gesture_remaining = maxf(0.0,_gesture_remaining-step)
	_pose(step)


func set_activity_state(value: String) -> void:
	if value == _state: return
	_state = value
	if value == "success":
		_gesture = "success"
		_gesture_remaining = 2.2
	elif value == "active":
		_gesture = "offer"
		_gesture_remaining = 1.4
	else:
		_gesture_remaining = 0.0


func set_look_target(world_point: Vector3) -> void:
	_look_target = world_point


func get_pose_snapshot() -> Dictionary:
	var soles: Array[Vector3] = []
	for foot: Dictionary in _feet: soles.append(foot.node.to_global(Footwear.SOLE_CONTACT))
	return {"grounded":_grounded,"state":_state,"phase":_phase,"gesture":_gesture,
		"gesture_remaining":_gesture_remaining,"offer_blend":_offer_blend,"success_blend":_success_blend,
		"head":_head.global_transform,"soles":soles,"body":_body.global_transform,
		"reduced_motion":_motion_reduced()}


func get_ground_contacts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for foot: Dictionary in _feet:
		result.append({"point":foot.point,"normal":foot.normal,"side":foot.side})
	return result


func _motion_reduced() -> bool:
	return reduced_motion or bool(_property(get_parent(),"reduced_motion",false))


func _read_activity_state() -> void:
	var parent := get_parent()
	if parent.has_method("status_snapshot"):
		var snapshot: Dictionary = parent.status_snapshot()
		set_activity_state(str(snapshot.get("state","idle")))
	var target := _look_target
	var player: Node3D = _skater.get_ref() if _skater != null else null
	if is_instance_valid(player): target = player.global_position+Vector3.UP*1.2
	if target.is_finite():
		var nearby := Vector2(target.x-_body.global_position.x,target.z-_body.global_position.z).length() < 5.0
		if nearby and not _near and _state == "idle":
			_gesture = "offer"
			_gesture_remaining = 1.4
		_near = nearby


func _find_skater() -> void:
	var ancestor := get_parent()
	for level in 4:
		if ancestor == null: return
		var player: Variant = _property(ancestor,"_skater",null)
		if not is_instance_valid(player): player = _property(ancestor,"skater",null)
		if player is Node3D:
			_skater = weakref(player)
			return
		ancestor = ancestor.get_parent()


func _refresh_ground() -> void:
	if not is_inside_tree(): return
	var yaw := atan2(global_basis.z.x,global_basis.z.z)
	var upright := Basis(Vector3.UP,yaw)
	var hits: Array[Dictionary] = []
	for foot: Dictionary in _feet:
		var sample := global_position+upright*Vector3(float(foot.side)*0.14,0,-0.015)
		var hit := _ground_ray(sample)
		if hit.is_empty():
			_grounded = false
			_body.visible = false
			return
		hits.append(hit)
	var height := (float(hits[0].position.y)+float(hits[1].position.y))*0.5
	_body.global_transform = Transform3D(upright,Vector3(global_position.x,height,global_position.z))
	for index in _feet.size():
		var foot: Dictionary = _feet[index]
		foot.point = hits[index].position
		foot.normal = hits[index].normal
		var shoe_basis := _surface_basis(foot.normal,upright.z)*Basis(Vector3.UP,-float(foot.side)*0.08)
		var ankle: Vector3 = Vector3(foot.point)+Vector3(foot.normal)*0.0005-shoe_basis*Footwear.SOLE_CONTACT
		foot.node.global_transform = Transform3D(shoe_basis,ankle)
	_grounded = true
	_body.visible = true
	_last_root = global_transform
	_pose(0.0)


func _ground_ray(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*12.0,point-Vector3.UP*24.0,1)
	# Activity hosts stand on scenery, never on a passing skater/cart/foam prop.
	for attempt in 8:
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): return {}
		if hit.collider is StaticBody3D and Vector3(hit.normal).dot(Vector3.UP) > 0.65: return hit
		var excluded: Array[RID] = query.exclude
		excluded.append(hit.rid)
		query.exclude = excluded
	return {}


func _pose(delta: float) -> void:
	if not is_instance_valid(_head): return
	var rate := 1.0-exp(-8.0*delta)
	_offer_blend = lerpf(_offer_blend,1.0 if _gesture == "offer" and _gesture_remaining > 0.0 else 0.0,rate)
	_success_blend = lerpf(_success_blend,1.0 if _gesture == "success" and _gesture_remaining > 0.0 else 0.0,rate)
	var target := _look_target
	var player: Node3D = _skater.get_ref() if _skater != null else null
	if is_instance_valid(player): target = player.global_position+Vector3.UP*1.2
	var desired_look := 0.0
	if target.is_finite():
		var local := _body.to_local(target)
		if local.z < 0.8 and local.length() < 12.0: desired_look = clampf(atan2(-local.x,-local.z),-0.45,0.45)
	_look_yaw = lerpf(_look_yaw,desired_look,1.0-exp(-4.0*delta))
	var breathing := sin(_phase*1.7)*0.003
	var hips := Vector3(0,0.92+breathing,0)
	var torso := Transform3D(Basis.from_euler(Vector3(-0.015-_offer_blend*0.025,_look_yaw*0.12,0)),hips)
	_garments.pose_body(Transform3D(Basis.IDENTITY,hips),torso)
	_details.transform = torso
	_head.basis = torso.basis*Basis.from_euler(Vector3(-0.02+sin(_phase*1.8)*0.012,_look_yaw,0))
	_head.position = torso*Vector3(0,0.47,-0.012)-_head.basis*Vector3(0,-0.13,0.036)
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var ankle: Vector3 = _feet[index].node.position
		var hip := hips+Vector3(side*0.105,0.025,0)
		var knee := _joint(hip,ankle,0.45,0.45,Vector3(side*0.20,0,-1))
		_garments.pose_leg(side,hip,knee,ankle)
		var shoulder: Vector3 = torso*Vector3(side*0.205,0.425,-0.01)
		var wrist := Vector3(side*0.245,0.82+breathing,0.005)
		if index == 1:
			wrist = wrist.lerp(Vector3(0.32,1.15,-0.29)+Vector3(0,sin(_phase*4.5)*0.012,0),_offer_blend)
		wrist = wrist.lerp(Vector3(side*0.34,1.48,-0.16)+Vector3(0,sin(_phase*5.0+side)*0.018,0),_success_blend)
		var elbow := _joint(shoulder,wrist,0.30,0.29,Vector3(side*0.8,-0.15,0.3))
		_garments.pose_arm(side,shoulder,elbow,wrist)
		_hands[index].transform = Transform3D(_hand_basis(elbow-wrist),wrist)
		_anatomy.pose_hand(_hands[index],0.05+0.12*(1.0-maxf(_offer_blend,_success_blend)))


func _build_clothing_details(coat: StandardMaterial3D) -> void:
	var dark := _material(Color("263237"))
	var collar := [Vector3(0.46,0.073,0.063),Vector3(0.52,0.067,0.058)]
	_loft(_details,"FoldedCoatCollar",collar,coat)
	var outer: Array[Vector4] = []
	for ring: Vector4 in COAT_PROFILE:
		outer.append(Vector4(ring.x,ring.y+0.012,ring.z+0.012,ring.w))
	if steward:
		var hi_vis := _material(Color("c4ce59"))
		hi_vis.albedo_texture = coat.albedo_texture
		_loft(_details,"ShapedHiVisWaistcoat",outer,hi_vis)
		var reflective := _material(Color("cad4d0"))
		reflective.metallic = 0.2
		_loft(_details,"ReflectiveWaistBand",[_ring_at(outer,0.105,0.003),_ring_at(outer,0.145,0.003)],reflective)
		_loft(_details,"ReflectiveChestBand",[_ring_at(outer,0.274,0.003),_ring_at(outer,0.313,0.003)],reflective)
		for side: float in [-1.0,1.0]:
			_panel(_details,"ReflectiveShoulderTape",Vector3(side*0.11,0.374,0),Vector2(0.027,0.16),reflective,outer)
	else:
		for side: float in [-1.0,1.0]:
			_panel(_details,"CoatPocketFlap",Vector3(side*0.105,0.153,0),Vector2(0.105,0.032),dark,COAT_PROFILE)
	_panel(_details,"CoatZip",Vector3(0,0.25,0),Vector2(0.008,0.43),dark,outer if steward else COAT_PROFILE)


static func _loft(parent: Node3D, label: String, rings: Array, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in rings.size()-1:
		for column in 40:
			for corner: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1)]:
				var ring: Variant = rings[row+corner.x]
				var angle := TAU*float(column+corner.y)/40.0
				surface.set_uv(Vector2(float(column+corner.y)/40.0,ring.x*4.0))
				var x := signf(cos(angle))*pow(absf(cos(angle)),0.86)*float(ring.y)
				var z := signf(sin(angle))*pow(absf(sin(angle)),0.86)*float(ring.z)+(float(ring.w) if ring is Vector4 else 0.0)
				surface.add_vertex(Vector3(x,ring.x,z))
	_finish(parent,label,surface,material)


static func _panel(parent: Node3D, label: String, center: Vector3, size: Vector2, material: Material, profile: Array) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 8:
		for column in 4:
			for corner: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1)]:
				var y := center.y+(float(row+corner.x)/8.0-0.5)*size.y
				var x := center.x+(float(column+corner.y)/4.0-0.5)*size.x
				var ring := _ring_at(profile,y)
				var cosine := pow(clampf(absf(x)/ring.y,0.0,0.999),1.0/0.86)
				var z := -pow(sqrt(maxf(0,1.0-cosine*cosine)),0.86)*ring.z+ring.w-0.003
				surface.add_vertex(Vector3(x,y,z))
	_finish(parent,label,surface,material)


static func _ring_at(profile: Array, height: float, padding: float = 0.0) -> Vector4:
	var result: Vector4 = profile[0]
	for index in profile.size()-1:
		var a: Vector4 = profile[index]
		var b: Vector4 = profile[index+1]
		if height <= b.x:
			result = a.lerp(b,clampf((height-a.x)/(b.x-a.x),0,1))
			break
		result = b
	return Vector4(height,result.y+padding,result.z+padding,result.w)


static func _finish(parent: Node3D, label: String, surface: SurfaceTool, material: Material) -> void:
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface.commit()
	mesh.material_override = material
	parent.add_child(mesh)


static func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _joint(start: Vector3, end: Vector3, upper: float, lower: float, bend: Vector3) -> Vector3:
	var direction := (end-start).normalized()
	var reach := clampf(start.distance_to(end),0.011,upper+lower-0.001)
	var along := (upper*upper-lower*lower+reach*reach)/(2.0*reach)
	var height := sqrt(maxf(0.0,upper*upper-along*along))
	var pole := bend.slide(direction).normalized()
	if pole.length_squared() < 0.01: pole = Vector3.RIGHT.slide(direction).normalized()
	return start+direction*along+pole*height


static func _hand_basis(forearm: Vector3) -> Basis:
	var y := forearm.normalized()
	var z := Vector3.BACK.slide(y).normalized()
	if z.length_squared() < 0.001: z = Vector3.RIGHT.slide(y).normalized()
	var x := y.cross(z).normalized()
	return Basis(x,y,x.cross(y).normalized())


static func _surface_basis(normal: Vector3, back: Vector3) -> Basis:
	var y := normal.normalized()
	var z := back.slide(y).normalized()
	if z.length_squared() < 0.001: z = Vector3.BACK.slide(y).normalized()
	var x := y.cross(z).normalized()
	return Basis(x,y,x.cross(y).normalized())


static func _property(object: Object, name: String, fallback: Variant) -> Variant:
	if not is_instance_valid(object): return fallback
	for property: Dictionary in object.get_property_list():
		if property.name == name: return object.get(name)
	return fallback
