extends Node3D
## Original fictional tinkerer and copper/teal clockwork-cat sculpture. All prop
## geometry and movement are authored here; no real performer's act is reproduced.

const Garments = preload("res://game/player/skater_garments.gd")
const Anatomy = preload("res://game/player/skater_anatomy.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const DANCE_SECONDS := 3.2

var _state := "idle"
var _sequence_index := 0
var _reduced_motion := false
var _dance_elapsed := DANCE_SECONDS
var _phase := 0.0
var _celebration_state := "none"
var _cat: Node3D
var _head: Node3D
var _tail: Node3D
var _front_paws: Array[Node3D] = []
var _indicators: Array[MeshInstance3D] = []
var _sign: Label3D
var _indicator_off: StandardMaterial3D
var _indicator_next: StandardMaterial3D
var _indicator_done: StandardMaterial3D

func _ready() -> void:
	_indicator_off = _material(Color("625b4f"), 0.4, 0.6)
	_indicator_next = _material(Color("c5a46a"), 0.45, 0.45)
	_indicator_done = _material(Color("79a88f"), 0.35, 0.55)
	_build_tinkerer()
	_build_stage()
	_build_cat()
	_sign = Label3D.new()
	_sign.name = "WorkshopSign"
	_sign.position = Vector3(0, 2.04, 0)
	_sign.font_size = 34
	_sign.pixel_size = 0.0038
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.modulate = Color("e9dfbf")
	_sign.outline_modulate = Color("1c2827")
	_sign.outline_size = 7
	_sign.visibility_range_end = 26.0
	add_child(_sign)
	set_encounter_state(_state, _sequence_index, 0.0, _reduced_motion)

func set_encounter_state(state: String, sequence_index: int, remaining: float, reduce_motion: bool, celebration_state: String = "none") -> void:
	if state != _state:
		_dance_elapsed = DANCE_SECONDS
	_state = state
	_sequence_index = sequence_index
	_reduced_motion = reduce_motion
	_celebration_state = celebration_state
	if not is_instance_valid(_sign): return
	match state:
		"active": _sign.text = "RAE'S WORKSHOP\n%s / 3 charged  ·  %ss" % [sequence_index, ceili(remaining)]
		"success":
			if celebration_state == "queued": _sign.text = "FULL CHARGE!\nReturn to see it dance"
			elif celebration_state == "playing": _sign.text = "PURR-FECT!\nCat's Got the Beat"
			else: _sign.text = "FULL CHARGE!\nCat's Got the Beat"
		"failed": _sign.text = "RAE'S WORKSHOP\nAnother charge?"
		_: _sign.text = "RAE'S WORKSHOP\nCat's Got the Beat"
	for index in _indicators.size():
		_indicators[index].material_override = _indicator_done if index < sequence_index else (_indicator_next if state == "active" and index == sequence_index else _indicator_off)
	_pose()

func start_celebration() -> void:
	if _state != "success" or _reduced_motion: return
	_dance_elapsed = 0.0
	_pose()

func stop_celebration() -> void:
	_dance_elapsed = DANCE_SECONDS
	_pose()

func animation_snapshot() -> Dictionary:
	return {"dance_elapsed": _dance_elapsed, "dance_duration": DANCE_SECONDS,
		"dance_active": _state == "success" and not _reduced_motion and _dance_elapsed < DANCE_SECONDS,
		"reduced_motion": _reduced_motion, "state": _state, "sequence_index": _sequence_index,
		"celebration_state": _celebration_state}

func _process(delta: float) -> void:
	if _reduced_motion: return
	_phase += delta
	if _state == "success": _dance_elapsed = minf(DANCE_SECONDS, _dance_elapsed + delta)
	_pose()

func _pose() -> void:
	if not is_instance_valid(_cat): return
	var dancing := _state == "success" and not _reduced_motion and _dance_elapsed < DANCE_SECONDS
	var envelope := sin(PI * _dance_elapsed / DANCE_SECONDS) if dancing else 0.0
	var beat := sin(_dance_elapsed * TAU * 1.65)
	_cat.position = Vector3(0.55, 0.20 + 0.025 * envelope * beat * beat, -0.25)
	_cat.rotation = Vector3(0, beat * 0.12 * envelope, sin(_dance_elapsed * TAU * 0.85) * 0.045 * envelope)
	_head.rotation = Vector3(beat * 0.08 * envelope, sin(_dance_elapsed * TAU) * 0.18 * envelope, 0)
	_tail.rotation = Vector3(sin(_dance_elapsed * TAU) * 0.18 * envelope, beat * 0.28 * envelope, 0)
	for index in _front_paws.size():
		var lift := maxf(0.0, sin(_dance_elapsed * TAU * 1.65 + index * PI)) * 0.16 * envelope
		if _state == "success" and _reduced_motion and index == 0: lift = 0.12
		_front_paws[index].position.y = 0.29 + lift
		_front_paws[index].rotation.x = -lift * 1.2

func _build_tinkerer() -> void:
	var person := Node3D.new()
	person.name = "RaeTinkerer"
	person.position = Vector3(-0.78, 0, 0.55)
	person.rotation.y = -0.15
	add_child(person)
	var jacket := _material(Color("4c605a"))
	var denim := _material(Color("343b3e"))
	var leather := _material(Color("665444"))
	var rubber := _material(Color("aaa797"))
	var clothes := Garments.new()
	clothes.build(person, jacket, denim)
	clothes.pose_body(Transform3D(Basis.IDENTITY, Vector3(0,0.94,0)), Transform3D(Basis.IDENTITY,Vector3(0,0.94,0)))
	var anatomy := Anatomy.new()
	var head := Node3D.new()
	head.name = "TinkererHead"
	head.rotation.y = -0.20
	head.position = Vector3(0,1.410,0) - head.basis * Vector3(0,-0.13,0.036)
	person.add_child(head)
	anatomy.build_head(head)
	_cylinder(person, "JacketCollar", Vector3(0,1.426,-0.012), 0.068,0.07,jacket)
	_box(person, "ToolBelt", Vector3(0,0.985,0),Vector3(0.365,0.06,0.255),leather)
	_box(person, "ToolPouch", Vector3(0.155,0.895,-0.125),Vector3(0.11,0.17,0.08),leather)
	for side: float in [-1.0,1.0]:
		var ankle := Vector3(side*0.14,0.061,-0.015)
		clothes.pose_leg(side,Vector3(side*0.105,0.965,0),Vector3(side*0.14,0.52,-0.02),ankle)
		var shoe := Node3D.new()
		shoe.position = ankle
		shoe.rotation.y = PI + side*0.12
		person.add_child(shoe)
		Footwear.build(shoe,denim,rubber,leather)
		var shoulder := Vector3(side*0.205,1.365,0)
		var elbow := Vector3(side*0.31,1.16,-0.04)
		var wrist := Vector3(side*0.22,0.98,-0.20)
		clothes.pose_arm(side,shoulder,elbow,wrist)
		var hand: Node3D = anatomy.build_hand(person,side)
		hand.position = wrist
		var y := (elbow-wrist).normalized()
		var z := Vector3.BACK.slide(y).normalized()
		var x := y.cross(z).normalized()
		hand.basis = Basis(x,y,x.cross(y).normalized())
		anatomy.pose_hand(hand,0.9 if side < 0 else 0.0)
		if side < 0:
			var tool := _material(Color("8c9593"),0.7,0.4)
			_box(hand,"OriginalSpanner",Vector3(0,-0.125,-0.02),Vector3(0.019,0.22,0.012),tool)
			var ring := TorusMesh.new()
			ring.inner_radius = 0.022
			ring.outer_radius = 0.038
			ring.rings = 16
			ring.ring_segments = 8
			var tip := _mesh(hand,"SpannerRing",ring,Vector3(0,-0.235,-0.02),tool)
			tip.rotation.x = PI/2.0

func _build_stage() -> void:
	var iron := _material(Color("414b4a"),0.65,0.55)
	var wood := _material(Color("76674e"),0.05,0.85)
	_cylinder(self,"WorkshopTurntable",Vector3(0.55,0.10,-0.25),0.83,0.20,iron)
	_cylinder(self,"TurntableDeck",Vector3(0.55,0.202,-0.25),0.77,0.022,wood)
	_box(self,"SequenceConsole",Vector3(0.55,0.18,-1.00),Vector3(0.92,0.24,0.22),iron)
	for index in 3:
		# The workshop faces south (yaw PI): local +X is the viewer's left.
		var x := 0.85 - index*0.30
		var indicator := _cylinder(self,"ChargeIndicator"+str(index+1),Vector3(x,0.323,-1.0),0.075,0.045,_indicator_off)
		_indicators.append(indicator)
		_label(self,String.chr(65+index),Vector3(x,0.20,-1.118),28,0.0028)
	_label(self,"RAE'S REPAIR SHOP",Vector3(0.55,0.50,-0.95),26,0.0020)

func _build_cat() -> void:
	_cat = Node3D.new()
	_cat.name = "OriginalClockworkCat"
	add_child(_cat)
	var teal := _material(Color("537d75"),0.65,0.43)
	var copper := _material(Color("ad8259"),0.72,0.40)
	var iron := _material(Color("3b4543"),0.75,0.50)
	var eye := _material(Color("d7bd78"),0.40,0.35)
	_ellipsoid(_cat,"CopperMotorShell",Vector3(0,0.45,0.0),Vector3(0.235,0.19,0.34),copper)
	_cylinder(_cat,"TopMotorCap",Vector3(0,0.64,0.04),0.075,0.045,iron)
	_head = Node3D.new()
	_head.name = "CatHeadPivot"
	_head.position = Vector3(0,0.74,-0.24)
	_cat.add_child(_head)
	_ellipsoid(_head,"TealHeadShell",Vector3.ZERO,Vector3(0.225,0.205,0.18),teal)
	for side: float in [-1.0,1.0]:
		_ear(_head,side,copper)
		_ellipsoid(_head,"SteadyBrassEye",Vector3(side*0.086,0.015,-0.162),Vector3(0.033,0.039,0.013),eye)
		_ellipsoid(_head,"EyeSlot",Vector3(side*0.086,0.015,-0.175),Vector3(0.008,0.025,0.004),iron)
		_ellipsoid(_head,"CheekRivet",Vector3(side*0.155,-0.065,-0.125),Vector3.ONE*0.018,copper)
	_box(_head,"CopperMuzzle",Vector3(0,-0.075,-0.172),Vector3(0.085,0.035,0.035),copper)
	for side: float in [-1.0,1.0]:
		for front: bool in [true,false]:
			var leg := Node3D.new()
			leg.name = ("Front" if front else "Rear") + ("LeftPaw" if side < 0 else "RightPaw")
			leg.position = Vector3(side*0.17,0.29,-0.20 if front else 0.22)
			_cat.add_child(leg)
			_cylinder(leg,"PistonLeg",Vector3(0,-0.11,0),0.047,0.24,iron)
			_ellipsoid(leg,"RubberPaw",Vector3(0,-0.245,-0.025),Vector3(0.075,0.045,0.10),teal)
			_ellipsoid(leg,"KneeBolt",Vector3(side*0.055,-0.035,0),Vector3.ONE*0.026,copper)
			if front: _front_paws.append(leg)
	_tail = Node3D.new()
	_tail.name = "TailPivot"
	_tail.position = Vector3(0,0.52,0.30)
	_cat.add_child(_tail)
	_segment(_tail,"TailLower",Vector3.ZERO,Vector3(0,0.15,0.24),0.033,teal)
	_segment(_tail,"TailUpper",Vector3(0,0.15,0.24),Vector3(0,0.42,0.29),0.030,copper)
	_ellipsoid(_tail,"TailCap",Vector3(0,0.42,0.29),Vector3.ONE*0.045,teal)

func _ear(parent: Node3D,side: float,material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(side*0.07,0.12,-0.025)
	var b := Vector3(side*0.20,0.12,-0.025)
	var tip := Vector3(side*0.17,0.34,0.005)
	var back := Vector3(side*0.14,0.14,0.075)
	for point: Vector3 in [a,b,tip,a,tip,back,b,back,tip,a,back,b]: surface.add_vertex(point)
	surface.generate_normals()
	_mesh(parent,"FoldedMetalEar",surface.commit(),Vector3.ZERO,material)

func _label(parent: Node3D,text: String,at: Vector3,font_size: int,pixel_size: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.position = at
	label.rotation.y = PI
	label.modulate = Color("eee0ba")
	label.outline_size = 3
	parent.add_child(label)

func _box(parent: Node3D,label: String,at: Vector3,size: Vector3,material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent,label,mesh,at,material)

func _cylinder(parent: Node3D,label: String,at: Vector3,radius: float,height: float,material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _mesh(parent,label,mesh,at,material)

func _ellipsoid(parent: Node3D,label: String,at: Vector3,radii: Vector3,material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	var node := _mesh(parent,label,mesh,at,material)
	node.scale = radii

func _segment(parent: Node3D,label: String,a: Vector3,b: Vector3,radius: float,material: Material) -> void:
	var node := _cylinder(parent,label,(a+b)*0.5,radius,a.distance_to(b),material)
	node.basis = Basis(Quaternion(Vector3.UP,(b-a).normalized()))

func _mesh(parent: Node3D,label: String,mesh: Mesh,at: Vector3,material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = at
	node.material_override = material
	parent.add_child(node)
	return node

func _material(color: Color,metallic: float=0.0,roughness: float=0.94) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material
