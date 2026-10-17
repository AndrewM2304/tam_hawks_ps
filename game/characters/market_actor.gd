extends Node3D
## Original fictional market trader, courier bag and gull prop vignette.
## No real shop, person, photograph, brand, voice or paid asset is reproduced.

const Garments = preload("res://game/player/skater_garments.gd")
const Anatomy = preload("res://game/player/skater_anatomy.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const PAYOFF_SECONDS := 3.2
const BEAK_TIP := Vector3(0,0.145,-0.39)
const SPARE_CONTACT := Vector3(0,0.037,0.085)
const SPARE_GRIP := BEAK_TIP-SPARE_CONTACT
const SPARE_REST := Vector3(1.12,0.91,-0.1)
const GULL_PERCH := Vector3(1.5,1.10,-0.3)

var _state := "idle"
var _reduced_motion := false
var _celebration_state := "none"
var _elapsed := PAYOFF_SECONDS
var _pickup_parcel: Node3D
var _delivered_parcel: Node3D
var _spare: Node3D
var _gull: Node3D
var _wings: Array[Node3D] = []
var _delivery: Node3D
var _sign: Label3D
var _delivery_sign: Label3D
var _garments: RefCounted
var _anatomy: RefCounted
var _route_marks: Node3D
var _markers: Array[Dictionary]=[]
var _mark_quiet: StandardMaterial3D
var _mark_next: StandardMaterial3D

func _ready() -> void:
	_build_stallholder()
	_build_pickup()
	_build_delivery()
	set_encounter_state(_state,0.0,_reduced_motion,_celebration_state,"")

func configure_delivery(position_world: Vector3, heading: float) -> void:
	if not is_instance_valid(_delivery): return
	_delivery.global_position=position_world
	_delivery.global_rotation=Vector3(0,heading,0)
	_pose()

func configure_route_marks(routes: Array,delivery_position: Vector3,gate_radius: float,delivery_radius: float) -> void:
	if is_instance_valid(_route_marks): _route_marks.queue_free()
	_markers.clear()
	_route_marks=Node3D.new()
	_route_marks.name="RouteMarkers"
	add_child(_route_marks)
	_route_marks.global_transform=Transform3D.IDENTITY
	_mark_quiet=_material(Color("8b978b"))
	_mark_next=_material(Color("cbd78b"))
	_mark_next.emission_enabled=true
	_mark_next.emission=Color("52653b")
	_mark_next.emission_energy_multiplier=0.35
	for route: Dictionary in routes:
		for index in 3:
			var caption:="%s · %s/3" % [String(route.label).to_upper(),index+1]
			if index==0: caption+="\nNORTH ENTRY"
			_build_route_mark("Route_%s_%s" % [route.id,index+1],route.gates[index],gate_radius,caption,String(route.id),index+1)
	_build_route_mark("DeliveryArrival",delivery_position,delivery_radius,"SOUTH COUNTER\nDELIVERY ARRIVAL","",0)
	set_navigation_targets([])

func set_navigation_targets(targets: Array) -> void:
	for mark: Dictionary in _markers:
		var next:=false
		for target: Dictionary in targets:
			if target.position.distance_squared_to(mark.position)<0.000001:
				next=true
				break
		mark.node.set_meta("navigation_active",next)
		mark.ring.material_override=_mark_next if next else _mark_quiet
		mark.label.text=("NEXT · " if next else "")+mark.caption
		mark.label.modulate=Color("eff4ba") if next else Color("c6cec2")

func _build_route_mark(node_name: String,at: Vector3,radius: float,caption: String,route_id: String,index: int) -> void:
	var mark:=Node3D.new()
	mark.name=node_name.validate_node_name()
	mark.position=at
	mark.set_meta("route_id",route_id)
	mark.set_meta("route_index",index)
	mark.set_meta("arrival",index==0)
	_route_marks.add_child(mark)
	var torus:=TorusMesh.new()
	torus.inner_radius=radius-0.045
	torus.outer_radius=radius+0.045
	torus.rings=48
	torus.ring_segments=6
	var ring:=_mesh(mark,"GroundRing",Vector3(0,0.055,0),torus,_mark_quiet)
	ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label:=_label(mark,"RouteLabel",Vector3(0,0.64,0),caption,0.0026,27)
	label.visibility_range_end=34.0
	_markers.append({"node":mark,"position":at,"ring":ring,"label":label,"caption":caption})

func set_encounter_state(state: String,remaining: float,reduce_motion: bool,celebration_state: String,detail: String) -> void:
	_state=state
	_reduced_motion=reduce_motion
	_celebration_state=celebration_state
	if not is_instance_valid(_sign): return
	match _state:
		"active": _sign.text="MAIRI'S MARKET RUN\nParcel out · %ss" % ceili(remaining)
		"success": _sign.text="MAIRI'S MARKET RUN\nBreakfast delivered!"
		"failed": _sign.text="MAIRI'S MARKET RUN\nParcel returned · Try again"
		_: _sign.text="GULL-PROOF DELIVERY\nMAIRI · Fresh breakfast parcels"
	_delivery_sign.text="SOUTH COUNTER\nDELIVER HERE"
	if _state=="success":
		if celebration_state=="queued": _delivery_sign.text="DELIVERY SAFE\nLook here for the gull!"
		elif celebration_state=="playing": _delivery_sign.text="THAT'S THE SPARE!\nYour breakfast is safe"
		else: _delivery_sign.text="DELIVERY COMPLETE\nSpare wrapper: gull 1, Mairi 0"
	elif _state=="active" and "3/3" in detail:
		_delivery_sign.text="SOUTH COUNTER\nBring that parcel here!"
	_pickup_parcel.visible=_state!="active"
	_delivered_parcel.visible=_state=="success"
	_pose()

func start_celebration() -> void:
	if _state!="success" or _reduced_motion: return
	_elapsed=0.0
	_pose()

func stop_celebration() -> void:
	_elapsed=PAYOFF_SECONDS
	_pose()

func animation_snapshot() -> Dictionary:
	return {"state":_state,"carrying":_state=="active","delivered":_state=="success",
		"payoff_active":_state=="success" and not _reduced_motion and _elapsed<PAYOFF_SECONDS,
		"payoff_time":_elapsed,"payoff_duration":PAYOFF_SECONDS,
		"spare_taken":_state=="success" and (_reduced_motion or _celebration_state in ["finished","static"] or (_celebration_state=="playing" and _elapsed>=0.65)),
		"celebration_state":_celebration_state,"reduced_motion":_reduced_motion}

func _process(delta: float) -> void:
	if _state!="success" or _reduced_motion or _elapsed>=PAYOFF_SECONDS: return
	_elapsed=minf(PAYOFF_SECONDS,_elapsed+delta)
	_pose()

func _pose() -> void:
	if not is_instance_valid(_gull): return
	var taken:=false
	_gull.position=GULL_PERCH
	_gull.rotation=Vector3(0,-0.65,0)
	for wing in _wings: wing.rotation.z=0.0
	_spare.position=SPARE_REST
	_spare.rotation=Vector3.ZERO
	if _state=="success":
		if _reduced_motion or _celebration_state in ["finished","static"]:
			taken=true
		elif _celebration_state=="playing":
			var t:=clampf(_elapsed/PAYOFF_SECONDS,0.0,1.0)
			# Pitch the bird down to reach the counter. The upper rear edge of
			# the spare wrapper and the cone's actual tip meet at the pickup.
			var pickup_basis:=Basis.from_euler(Vector3(-0.70,-0.65,0))
			var pickup_position:=SPARE_REST-pickup_basis*SPARE_GRIP
			if _elapsed<0.65:
				var p:=smoothstep(0.0,0.65,_elapsed)
				_gull.position=GULL_PERCH.lerp(pickup_position,p)+Vector3(0,sin(p*PI)*0.12,0)
				_gull.rotation=Vector3(-0.70*p,-0.65,0)
			else:
				taken=true
				var p:=smoothstep(0.65,PAYOFF_SECONDS,_elapsed)
				_gull.position=pickup_position.lerp(GULL_PERCH,p)+Vector3(sin(p*PI)*0.45,sin(p*PI)*0.92,0)
				_gull.rotation=Vector3(-0.70*(1.0-p),-0.65+sin(p*TAU)*0.25,0)
			for index in _wings.size(): _wings[index].rotation.z=(-1.0 if index==0 else 1.0)*sin(t*TAU*5.0)*0.58*sin(t*PI)
	if taken:
		# Only the labelled empty spare wrapper follows the beak. The customer's
		# delivered parcel remains visibly on the counter for the whole payoff.
		_spare.position=_gull.position+_gull.basis*SPARE_GRIP
		_spare.basis=_gull.basis

func _build_stallholder() -> void:
	var person:=Node3D.new()
	person.name="MairiStallholder"
	# Half a metre towards the terrace edge, out of the customer's approach.
	person.position=Vector3(0.55,0,0)
	add_child(person)
	var shirt:=_material(Color("4e6864"))
	var denim:=_material(Color("323c40"))
	var apron:=_material(Color("b99b6d"))
	_garments=Garments.new()
	_garments.build(person,shirt,denim)
	_garments.pose_body(Transform3D(Basis.IDENTITY,Vector3(0,.94,0)),Transform3D(Basis.IDENTITY,Vector3(0,.94,0)))
	_anatomy=Anatomy.new()
	var head:=Node3D.new()
	head.name="MairiHead"
	head.position=Vector3(0,1.410,0)-Vector3(0,-.13,.036)
	person.add_child(head)
	_anatomy.build_head(head)
	_cylinder(person,"JacketCollar",Vector3(0,1.428,0),.069,.065,shirt)
	# Original cloth apron in front of the jacket, with a lower flared hem.
	var cloth:=SurfaceTool.new()
	cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points:=[Vector3(-.11,1.36,-.137),Vector3(.11,1.36,-.137),Vector3(-.155,.75,-.16),Vector3(.155,.75,-.16)]
	for index in [0,2,1,1,2,3]: cloth.add_vertex(points[index])
	cloth.generate_normals()
	var apron_mesh:=MeshInstance3D.new()
	apron_mesh.name="CanvasApron"
	apron_mesh.mesh=cloth.commit()
	apron.cull_mode=BaseMaterial3D.CULL_DISABLED
	apron_mesh.material_override=apron
	person.add_child(apron_mesh)
	_box(person,"ApronPocket",Vector3(0,.97,-.168),Vector3(.20,.15,.018),_material(Color("a58a61")))
	for side: float in [-1.0,1.0]:
		var hip:=Vector3(side*.105,.965,0)
		var knee:=Vector3(side*.14,.52,-.016)
		var ankle:=Vector3(side*.14,.061,-.015)
		_garments.pose_leg(side,hip,knee,ankle)
		var shoe:=Node3D.new()
		shoe.position=ankle
		shoe.rotation.y=PI+side*.10
		person.add_child(shoe)
		Footwear.build(shoe,_material(Color("493f35")),_material(Color("aaa391")),denim)
		var shoulder:=Vector3(side*.205,1.36,-.01)
		var elbow:=Vector3(side*.27,1.09,.015)
		var wrist:=Vector3(side*.235,.81,-.025)
		_garments.pose_arm(side,shoulder,elbow,wrist)
		var hand: Node3D=_anatomy.build_hand(person,side)
		var y: Vector3=(elbow-wrist).normalized()
		var z: Vector3=Vector3(-side,0,0).slide(y).normalized()
		var x:=y.cross(z).normalized()
		hand.position=wrist
		hand.basis=Basis(x,y,x.cross(y).normalized())
		_anatomy.pose_hand(hand,0.0)

func _build_pickup() -> void:
	var wood:=_material(Color("69543e"))
	var dark:=_material(Color("30433e"))
	_box(self,"PickupCounter",Vector3(-.5,.79,0),Vector3(.85,.09,.58),wood)
	for side: float in [-1.0,1.0]: _box(self,"CounterLeg",Vector3(-.5+side*.31,.39,0),Vector3(.055,.78,.42),dark)
	_pickup_parcel=_parcel(self,"PickupParcel",Vector3(-.5,.92,0),false)
	_cylinder(self,"TeaFlask",Vector3(-.76,1.03,.08),.055,.38,_material(Color("49626a")))
	_cylinder(self,"FlaskLid",Vector3(-.76,1.23,.08),.058,.04,_material(Color("b8b3a3")))
	_sign=_label(self,"PickupSign",Vector3(0,2.02,0),"GULL-PROOF DELIVERY\nMAIRI · Fresh breakfast parcels",.0034,30)
	_label(self,"PickupCounterNote",Vector3(-.5,1.14,-.16),"SEALED PARCELS\nKeep them upright!",.0018,24)

func _build_delivery() -> void:
	_delivery=Node3D.new()
	_delivery.name="DeliveryCounter"
	add_child(_delivery)
	var timber:=_material(Color("766248"))
	var dark:=_material(Color("394e49"))
	# Offset to the side of the actual arrival point. There is no collision;
	# the 103m west lane remains open through its final marker.
	_box(_delivery,"CounterTop",Vector3(1.5,.83,0),Vector3(1.0,.10,.64),timber)
	for side: float in [-1.0,1.0]: _box(_delivery,"CrateSupport",Vector3(1.5+side*.35,.40,0),Vector3(.13,.8,.48),dark)
	for side: float in [-1.0,1.0]:
		for row in 3: _box(_delivery,"CrateSlat",Vector3(1.5+side*.48,.20+row*.18,0),Vector3(.045,.115,.62),timber)
	_delivered_parcel=_parcel(_delivery,"DeliveredParcel",Vector3(1.63,.97,.12),false)
	_spare=_parcel(_delivery,"SpareParcel",Vector3(1.12,.91,-.1),true)
	_delivery_sign=_label(_delivery,"DeliverySign",Vector3(1.5,1.9,.12),"SOUTH COUNTER\nDELIVER HERE",.0033,30)
	_label(_delivery,"SpareWrapperNote",Vector3(1.1,1.19,-.22),"SPARE\nEMPTY WRAPPER",.0015,24)
	_build_gull()

func _build_gull() -> void:
	_gull=Node3D.new()
	_gull.name="MarketGull"
	_delivery.add_child(_gull)
	var white:=_material(Color("e5e3d6"))
	var grey:=_material(Color("929c9f"))
	var black:=_material(Color("252e32"))
	var yellow:=_material(Color("c7a850"))
	_ellipsoid(_gull,"GullBody",Vector3(0,0,.015),Vector3(.115,.145,.25),white)
	_ellipsoid(_gull,"GullNeck",Vector3(0,.095,-.13),Vector3(.073,.13,.085),white)
	_ellipsoid(_gull,"GullHead",Vector3(0,.16,-.205),Vector3(.087,.092,.10),white)
	_beak(_gull,Vector3(0,.145,-.295),yellow)
	for side: float in [-1.0,1.0]:
		_ellipsoid(_gull,"GullEye",Vector3(side*.079,.175,-.231),Vector3(.011,.011,.011),black)
		var wing:=Node3D.new()
		wing.name="GullWingLeft" if side<0 else "GullWingRight"
		wing.position=Vector3(side*.09,.02,.025)
		_gull.add_child(wing)
		_wings.append(wing)
		_wing(wing,side,grey,black)
		_cylinder(_gull,"GullLeg",Vector3(side*.047,-.16,.035),.011,.12,yellow)
		_box(_gull,"GullFoot",Vector3(side*.047,-.219,.003),Vector3(.041,.014,.085),yellow)
	_ellipsoid(_gull,"GullTail",Vector3(0,.025,.265),Vector3(.055,.032,.105),grey)

static func create_courier_bag(parent: Node3D) -> Node3D:
	var bag:=Node3D.new()
	bag.name="CourierBag"
	bag.position=Vector3(0,.23,.175)
	parent.add_child(bag)
	var canvas:=_material(Color("886e49"))
	var webbing:=_material(Color("414d49"))
	var paper:=_material(Color("c6ab76"))
	_box(bag,"CanvasBag",Vector3.ZERO,Vector3(.29,.30,.14),canvas)
	_box(bag,"BagFlap",Vector3(0,.12,.077),Vector3(.30,.09,.025),webbing)
	_box(bag,"SealedParcel",Vector3(0,.16,0),Vector3(.24,.065,.12),paper)
	for side: float in [-1.0,1.0]:
		var strap:=_box(bag,"ShoulderStrap",Vector3(side*.105,.02,-.08),Vector3(.032,.39,.025),webbing)
		strap.rotation.x=-.25
	_box(bag,"ParcelSeal",Vector3(0,.161,.066),Vector3(.035,.06,.009),_material(Color("4d746a")))
	return bag

static func _parcel(parent: Node3D,node_name: String,at: Vector3,spare: bool) -> Node3D:
	var parcel:=Node3D.new()
	parcel.name=node_name
	parcel.position=at
	parent.add_child(parcel)
	_box(parcel,"PaperWrap",Vector3.ZERO,Vector3(.26,.14 if not spare else .065,.18),_material(Color("c8ae7d")))
	_box(parcel,"PaperFold",Vector3(0,.073 if not spare else .037,0),Vector3(.25,.008,.02),_material(Color("ae956c")))
	_box(parcel,"ParcelBand",Vector3(0,.002,0),Vector3(.029,.15 if not spare else .075,.184),_material(Color("4b766a")))
	return parcel

static func _label(parent: Node3D,node_name: String,at: Vector3,caption: String,pixel: float,size: int) -> Label3D:
	var label:=Label3D.new()
	label.name=node_name
	label.position=at
	label.text=caption
	label.font_size=size
	label.pixel_size=pixel
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("f2e8ce")
	label.outline_modulate=Color("23332f")
	label.outline_size=7
	label.visibility_range_end=45.0
	parent.add_child(label)
	return label

static func _material(color: Color) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=.92
	return material

static func _box(parent: Node3D,node_name: String,at: Vector3,size: Vector3,material: Material) -> MeshInstance3D:
	var mesh:=BoxMesh.new()
	mesh.size=size
	return _mesh(parent,node_name,at,mesh,material)

static func _ellipsoid(parent: Node3D,node_name: String,at: Vector3,radii: Vector3,material: Material) -> MeshInstance3D:
	var sphere:=SphereMesh.new()
	sphere.radius=1.0
	sphere.height=2.0
	sphere.radial_segments=24
	sphere.rings=12
	var mesh:=_mesh(parent,node_name,at,sphere,material)
	mesh.scale=radii
	return mesh

static func _cylinder(parent: Node3D,node_name: String,at: Vector3,radius: float,height: float,material: Material) -> MeshInstance3D:
	var cylinder:=CylinderMesh.new()
	cylinder.top_radius=radius
	cylinder.bottom_radius=radius
	cylinder.height=height
	cylinder.radial_segments=20
	return _mesh(parent,node_name,at,cylinder,material)

static func _mesh(parent: Node3D,node_name: String,at: Vector3,shape: Mesh,material: Material) -> MeshInstance3D:
	var instance:=MeshInstance3D.new()
	instance.name=node_name
	instance.position=at
	instance.mesh=shape
	instance.material_override=material
	parent.add_child(instance)
	return instance

static func _beak(parent: Node3D,at: Vector3,material: Material) -> void:
	var shape:=CylinderMesh.new()
	shape.top_radius=0.0
	shape.bottom_radius=0.023
	shape.height=0.14
	shape.radial_segments=16
	var beak:=_mesh(parent,"GullBeak",Vector3(at.x,BEAK_TIP.y,BEAK_TIP.z+0.07),shape,material)
	beak.rotation.x=-PI/2.0

static func _wing(parent: Node3D,side: float,grey: Material,black: Material) -> void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points:=[Vector3.ZERO,Vector3(side*.34,0,-.07),Vector3(side*.40,-.015,.24),Vector3(side*.04,-.035,.25)]
	for index in [0,1,2,0,2,3,2,1,0,3,2,0]: surface.add_vertex(points[index])
	surface.generate_normals()
	_mesh(parent,"GreyFlightFeathers",Vector3.ZERO,surface.commit(),grey)
	var tips:=SurfaceTool.new()
	tips.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,1,2,2,1,0]:
		tips.add_vertex([Vector3(side*.30,-.012,.02),Vector3(side*.40,-.017,.24),Vector3(side*.18,-.028,.24)][index])
	tips.generate_normals()
	_mesh(parent,"DarkWingTips",Vector3.ZERO,tips.commit(),black)
