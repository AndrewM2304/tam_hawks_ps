extends Node3D
## Original bin-drum street act and two soft fabric toy cats, informed by inspected
## historical act-type references. No real person's likeness or recording is used.

const Garments = preload("res://game/player/skater_garments.gd")
const Anatomy = preload("res://game/player/skater_anatomy.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const Percussion = preload("res://game/characters/bin_percussion.gd")
const DANCE_SECONDS := 3.2
const STICK_RADIUS := 0.0085
const TIP_RADIUS := 0.0105
const DRUM_GRIP_POINT := Vector3(0,-0.108,-0.047)

var _state := "idle"
var _sequence_index := 0
var _reduced_motion := false
var _dance_elapsed := DANCE_SECONDS
var _drum_phase := 0.0
var _celebration_state := "none"
var _cats: Array[Dictionary] = []
var _indicators: Array[MeshInstance3D] = []
var _sign: Label3D
var _indicator_off: StandardMaterial3D
var _indicator_next: StandardMaterial3D
var _indicator_done: StandardMaterial3D
var _clothes: RefCounted
var _anatomy: RefCounted
var _hands: Array[Node3D] = []
var _sticks: Array[MeshInstance3D] = []
var _stick_tips: Array[MeshInstance3D] = []
var _drum_heads: Array[MeshInstance3D] = []
var _drummer: Node3D
var _music: AudioStreamPlayer3D
var _audio_gain := 0.0
var _audio_enabled := true

func _ready() -> void:
	_indicator_off = _material(Color("776b58"))
	_indicator_next = _material(Color("d3b46f"))
	_indicator_done = _material(Color("88aa91"))
	_build_drummer()
	_build_bin_kit()
	_build_fabric_cat("FabricCatOne", Vector3(-0.87,0.025,-1.05), Color("a2aaad"), Color("647580"), 1.0)
	_build_fabric_cat("FabricCatTwo", Vector3(0.87,0.025,-1.05), Color("c4b6a3"), Color("967366"), 0.9)
	_build_pitch_signs()
	_music = AudioStreamPlayer3D.new()
	_music.name = "OriginalBinPercussion"
	_music.stream = Percussion.stream()
	_music.position = Vector3(0,0.8,-0.3)
	_music.max_distance = 28.0
	_music.unit_size = 4.0
	_music.max_db = 0.0
	_music.max_polyphony = 1
	add_child(_music)
	_apply_audio()
	set_encounter_state(_state,_sequence_index,0.0,_reduced_motion,_celebration_state)

func set_encounter_state(state: String, sequence_index: int, remaining: float, reduce_motion: bool, celebration_state: String = "none") -> void:
	if state != _state: _dance_elapsed = DANCE_SECONDS
	_state = state
	_sequence_index = sequence_index
	_reduced_motion = reduce_motion
	_celebration_state = celebration_state
	if not is_instance_valid(_sign): return
	match state:
		"active": _sign.text = "RAE'S TECHNO BIN\n%s / 3 beats  ·  %ss" % [sequence_index,ceili(remaining)]
		"success":
			if celebration_state == "queued": _sign.text = "BIG FINISH READY\nCome back to see the cats"
			elif celebration_state == "playing": _sign.text = "GET THOSE PAWS UP!\nCat's Got the Beat"
			else: _sign.text = "RAE'S TECHNO BIN\nCat's Got the Beat"
		"failed": _sign.text = "RAE'S TECHNO BIN\nAnother go?"
		_: _sign.text = "RAE'S TECHNO BIN\nDrums & dancing cats"
	for index in _indicators.size():
		_indicators[index].material_override = _indicator_done if index < sequence_index else (_indicator_next if state == "active" and index == sequence_index else _indicator_off)
	_pose()

func set_audio_gain(value: float) -> void:
	_audio_gain = clampf(value,0.0,1.0) if is_finite(value) else 0.0
	_apply_audio()

func set_audio_enabled(value: bool) -> void:
	if value and not _audio_enabled: _drum_phase = 0.0
	_audio_enabled = value
	_apply_audio()
	_pose()

func _apply_audio() -> void:
	if not is_instance_valid(_music): return
	_music.volume_db = linear_to_db(_audio_gain*0.30) if _audio_gain > 0.0 else -80.0
	if not _audio_enabled or _audio_gain <= 0.0:
		_music.stop()
	elif not _music.playing and AudioServer.get_driver_name() != "Dummy":
		_music.play(_drum_phase)

func start_celebration() -> void:
	if _state != "success" or _reduced_motion: return
	_dance_elapsed = 0.0
	_pose()

func stop_celebration() -> void:
	_dance_elapsed = DANCE_SECONDS
	_pose()

func animation_snapshot() -> Dictionary:
	return {"dance_elapsed":_dance_elapsed,"dance_duration":DANCE_SECONDS,
		"dance_active":_state=="success" and not _reduced_motion and _dance_elapsed<DANCE_SECONDS,
		"reduced_motion":_reduced_motion,"state":_state,"sequence_index":_sequence_index,
		"celebration_state":_celebration_state,"audio_enabled":_audio_enabled,
		"audio_gain":_audio_gain,"drum_phase":_drum_phase,
		"drummer_active":_audio_enabled and not _reduced_motion,"soft_cat_count":_cats.size()}

func _process(delta: float) -> void:
	if not _audio_enabled: return
	_drum_phase = fmod(_drum_phase+delta,Percussion.SECONDS)
	# Reduced motion freezes visible poses, while the audible rhythm keeps time.
	if _reduced_motion: return
	if _state=="success": _dance_elapsed=minf(DANCE_SECONDS,_dance_elapsed+delta)
	_pose()

func _pose() -> void:
	if _cats.is_empty(): return
	var dancing := _state=="success" and not _reduced_motion and _dance_elapsed<DANCE_SECONDS
	var envelope := sin(PI*_dance_elapsed/DANCE_SECONDS) if dancing else 0.0
	for index in _cats.size():
		var cat: Dictionary = _cats[index]
		var beat := sin(_dance_elapsed*TAU*2.0+index*PI)
		var idle_sway := sin(_drum_phase*TAU+index*PI)*0.030 if _audio_enabled and not _reduced_motion else 0.0
		cat.node.position = cat.rest + Vector3(0,0.025*envelope*beat*beat+absf(idle_sway)*0.15,0)
		cat.node.rotation = Vector3(0,beat*0.10*envelope,beat*0.11*envelope+idle_sway)
		cat.head.rotation.y = -beat*0.13*envelope
		cat.tail.rotation.x = 0.55+beat*0.15*envelope
		for side_index in 2:
			var raise := maxf(0.0,sin(_dance_elapsed*TAU*2.0+index*PI+side_index*PI))*0.95*envelope
			if _state=="success" and _reduced_motion and side_index==index: raise=0.65
			cat.paws[side_index].rotation.z = (-1.0 if side_index==0 else 1.0)*raise
	_pose_drummer()

func _pose_drummer() -> void:
	if _clothes==null or _hands.size()!=2: return
	for index in 2:
		var side: float = -1.0 if index==0 else 1.0
		var lift := maxf(0.0,sin(_drum_phase*TAU*2.0+index*PI))*0.14 if _audio_enabled and not _reduced_motion else 0.0
		var shoulder := Vector3(side*0.205,1.105,0)
		var wrist := Vector3(side*0.30,0.96+lift,-0.38)
		var elbow := _joint(shoulder,wrist,Vector3(side*0.8,-0.2,0.2))
		_clothes.pose_arm(side,shoulder,elbow,wrist)
		# Cylinder head height is 12 mm. At the downbeat the bead touches its
		# actual transformed top plane; the deliberate upswing lifts it away.
		var tip: Vector3 = _drummer.to_local(_drum_heads[index].to_global(Vector3(-side*0.11,0.006+TIP_RADIUS,0)))
		tip.y += lift*1.7
		var y := (elbow-wrist).normalized()
		var shaft := (tip-wrist).normalized()
		var x := shaft.slide(y).normalized()
		if x.length_squared()<0.001: x=Vector3.RIGHT.slide(y).normalized()
		var z := x.cross(y).normalized()
		if z.dot(Vector3.UP)<0.0:
			x=-x
			z=-z
		var hand_basis := Basis(x,y,z)
		_hands[index].position = wrist
		_hands[index].basis = hand_basis
		var grip := wrist+hand_basis*DRUM_GRIP_POINT
		shaft=(tip-grip).normalized()
		_pose_segment(_sticks[index],grip-shaft*0.095,tip)
		_stick_tips[index].position=tip

func _build_drummer() -> void:
	var person := Node3D.new()
	person.name = "StreetDrummer"
	person.position = Vector3(0,0,0.38)
	add_child(person)
	_drummer=person
	var shirt := _material(Color("48565e"))
	var denim := _material(Color("353a3e"))
	var canvas := _material(Color("bd885c"))
	var rubber := _material(Color("aaa697"))
	_clothes = Garments.new()
	_clothes.build(person,shirt,denim)
	_clothes.pose_body(Transform3D(Basis.IDENTITY,Vector3(0,0.68,0)),Transform3D(Basis.IDENTITY,Vector3(0,0.68,0)))
	_anatomy = Anatomy.new()
	var head := Node3D.new()
	head.name = "DrummerHead"
	head.position = Vector3(0,1.15,0)-Vector3(0,-0.13,0.036)
	person.add_child(head)
	_anatomy.build_head(head)
	_cylinder(person,"Collar",Vector3(0,1.166,-0.012),0.068,0.07,shirt)
	var hat := _material(Color("d8d4c4"),0.0,0.82)
	_ellipsoid(head,"UnbrandedSafetyHat",Vector3(0,0.12,0.005),Vector3(0.112,0.067,0.125),hat)
	_cylinder(head,"SafetyHatBrim",Vector3(0,0.066,-0.008),0.130,0.014,hat)
	for side: float in [-1.0,1.0]:
		_box(person,"CanvasVestPanel",Vector3(side*0.095,0.94,-0.117),Vector3(0.14,0.37,0.028),canvas)
		_box(person,"VestReflector",Vector3(side*0.095,0.92,-0.135),Vector3(0.14,0.025,0.006),rubber)
		var ankle := Vector3(side*0.17,0.061,-0.43)
		_clothes.pose_leg(side,Vector3(side*0.105,0.705,0),Vector3(side*0.16,0.49,-0.34),ankle)
		var shoe := Node3D.new()
		shoe.position=ankle
		shoe.rotation.y=PI+side*0.08
		person.add_child(shoe)
		Footwear.build(shoe,denim,rubber,shirt)
		var hand:Node3D=_anatomy.build_hand(person,side)
		_close_drum_hand(hand,side)
		_hands.append(hand)
		var stick_material:=_material(Color("d4b27c"),0.0,0.82)
		var stick:=_cylinder(person,"WoodenDrumstick",Vector3.ZERO,STICK_RADIUS,1.0,stick_material)
		_sticks.append(stick)
		var bead:=SphereMesh.new()
		bead.radius=TIP_RADIUS
		bead.height=TIP_RADIUS*2.0
		bead.radial_segments=16
		bead.rings=8
		_stick_tips.append(_mesh(person,"DrumstickBeadTip",bead,Vector3.ZERO,stick_material))
	var seat:=_material(Color("434948"),0.2,0.8)
	_cylinder(person,"BuskingStoolSeat",Vector3(0,0.525,0.015),0.23,0.06,seat)
	for side: float in [-1.0,1.0]:
		_segment(person,"FoldingStoolLeg",Vector3(side*0.19,0.49,0.11),Vector3(-side*0.19,0.025,-0.09),0.018,seat)

func _close_drum_hand(hand:Node3D,side:float)->void:
	# This actor's copied anatomical mesh gets a dedicated closed drum grip.
	# Shared skater anatomy and its animation blend shapes remain untouched.
	var instance:MeshInstance3D=hand.get_node("HandAndFingers")
	var source:Mesh=instance.mesh
	var result:=ArrayMesh.new()
	for surface_index in source.get_surface_count():
		var arrays:=source.surface_get_arrays(surface_index)
		var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
		var colors:=PackedColorArray()
		if arrays[Mesh.ARRAY_COLOR] is PackedColorArray: colors=arrays[Mesh.ARRAY_COLOR]
		var surface:=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var vertex_count:=indices.size() if not indices.is_empty() else points.size()
		for item in vertex_count:
			var index:=indices[item] if not indices.is_empty() else item
			var original:=points[index]
			var point:=original
			var distance:=maxf(0.0,-point.y-0.075)
			var angle:=distance*25.0
			point.y+=distance-sin(angle)/25.0
			point.z-=(1.0-cos(angle))/25.0
			point.x*=1.0-0.22*smoothstep(0.075,0.15,-original.y)
			var thumb:=smoothstep(0.038,0.070,-side*original.x)*(1.0-smoothstep(0.125,0.15,-original.y))
			point.x=lerpf(point.x,-side*0.018,thumb*0.80)
			point.y=lerpf(point.y,-0.105,thumb*0.60)
			point.z=lerpf(point.z,-0.064,thumb*0.80)
			if uv.size()==points.size(): surface.set_uv(uv[index])
			surface.set_color(colors[index] if colors.size()==points.size() else Color.WHITE)
			surface.add_vertex(point)
		surface.generate_normals()
		surface.index()
		surface.commit(result)
	instance.mesh=result

func _build_bin_kit() -> void:
	var kit:=Node3D.new()
	kit.name="BinDrumKit"
	add_child(kit)
	var silver:=_material(Color("899296"),0.65,0.50)
	var dark:=_material(Color("4a5355"),0.45,0.65)
	var head_material:=_material(Color("c5cfc8"),0.10,0.85)
	for index in 4:
		var side_x: float = [-0.64,-0.22,0.22,0.64][index]
		var drum:=Node3D.new()
		drum.name="RecycledTubDrum"+str(index+1)
		drum.position=Vector3(side_x,0.49,-0.33 if index in [0,3] else -0.45)
		drum.rotation.x=-0.24
		kit.add_child(drum)
		_cylinder(drum,"RibbedContainer",Vector3.ZERO,0.205,0.62,silver)
		for rib in 5:
			var ring:=TorusMesh.new()
			ring.inner_radius=0.199
			ring.outer_radius=0.214
			ring.rings=24
			ring.ring_segments=6
			_mesh(drum,"RolledRib",ring,Vector3(0,-0.29+rib*0.145,0),silver)
		var drum_head:=_cylinder(drum,"PaleDrumHead",Vector3(0,0.316,0),0.203,0.012,head_material)
		if index in [0,3]: _drum_heads.append(drum_head)
		_cylinder(drum,"RolledTopRim",Vector3(0,0.303,0),0.216,0.015,silver)
		_segment(kit,"TubSupport",Vector3(side_x,0.04,0),Vector3(side_x,0.52,-0.33),0.017,dark)
	_segment(kit,"KitCrossbar",Vector3(-0.83,0.40,-0.15),Vector3(0.83,0.40,-0.15),0.022,dark)
	_segment(kit,"CymbalStand",Vector3(-1.0,0.025,0.05),Vector3(-1.0,1.15,0.05),0.014,silver)
	_cylinder(kit,"SmallCymbal",Vector3(-1.0,1.16,0.05),0.24,0.009,_material(Color("ad9c6b"),0.6,0.55))
	var speaker:=_material(Color("353b3b"))
	_box(kit,"SmallBuskingSpeaker",Vector3(1.14,0.28,0.12),Vector3(0.35,0.56,0.30),speaker)
	_ellipsoid(kit,"SpeakerGrille",Vector3(1.14,0.28,-0.035),Vector3(0.12,0.18,0.012),_material(Color("242b2c")))

func _build_fabric_cat(label: String, at: Vector3, base: Color, stripe: Color, size: float) -> void:
	var node:=Node3D.new()
	node.name=label
	node.position=at
	node.scale=Vector3.ONE*size
	add_child(node)
	var cloth:=_fabric(base,stripe)
	var felt:=_material(Color("ddd0b8"),0.0,1.0)
	felt.metallic_specular=0.08
	var thread:=_material(Color("454a49"),0.0,1.0)
	thread.metallic_specular=0.05
	_ellipsoid(node,"Body",Vector3(0,0.35,0),Vector3(0.15,0.22,0.13),cloth)
	_ellipsoid(node,"SewnBellyPatch",Vector3(0,0.35,-0.119),Vector3(0.10,0.155,0.022),felt)
	var head:=Node3D.new()
	head.name="HeadPivot"
	head.position=Vector3(0,0.65,-0.005)
	node.add_child(head)
	_ellipsoid(head,"StuffedHead",Vector3.ZERO,Vector3(0.17,0.15,0.13),cloth)
	for side: float in [-1.0,1.0]:
		_cloth_ear(head,side,cloth,felt)
		_ellipsoid(head,"EmbroideredEye",Vector3(side*0.059,0.015,-0.126),Vector3(0.012,0.020,0.0035),thread)
		_ellipsoid(head,"PaddedMuzzle",Vector3(side*0.032,-0.044,-0.126),Vector3(0.038,0.025,0.020),felt)
		for whisker in 2:
			_segment(head,"ThreadWhisker",Vector3(side*0.05,-0.037,-0.143),Vector3(side*0.115,-0.025-whisker*0.020,-0.137),0.0015,thread)
	_ellipsoid(head,"FeltNose",Vector3(0,-0.025,-0.150),Vector3(0.016,0.011,0.005),thread)
	_segment(head,"StitchedMouth",Vector3(0,-0.034,-0.151),Vector3(0,-0.056,-0.147),0.0018,thread)
	var paws:Array[Node3D]=[]
	for side: float in [-1.0,1.0]:
		var paw:=Node3D.new()
		paw.name="LeftPaw" if side<0 else "RightPaw"
		paw.position=Vector3(side*0.16,0.47,0)
		node.add_child(paw)
		_ellipsoid(paw,"StuffedArm",Vector3(0,-0.10,0),Vector3(0.057,0.14,0.060),cloth)
		_ellipsoid(paw,"SoftPaw",Vector3(0,-0.225,-0.005),Vector3(0.064,0.059,0.064),felt)
		paws.append(paw)
		_ellipsoid(node,"LeftFoot" if side<0 else "RightFoot",Vector3(side*0.075,0.045,-0.04),Vector3(0.07,0.045,0.10),cloth)
		_ellipsoid(node,"StuffedLeg",Vector3(side*0.075,0.12,0),Vector3(0.058,0.10,0.065),cloth)
	var tail:=Node3D.new()
	tail.name="ClothTail"
	tail.position=Vector3(0,0.24,0.10)
	tail.rotation.x=0.55
	node.add_child(tail)
	_ellipsoid(tail,"PaddedTail",Vector3(0,0.10,0.01),Vector3(0.035,0.18,0.04),cloth)
	var stitch:=SurfaceTool.new()
	stitch.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 22:
		var angle:=TAU*index/22.0
		var a:=Vector3(cos(angle)*0.094,0.35+sin(angle)*0.147,-0.136)
		var tangent:=Vector3(-sin(angle),cos(angle),0)*0.006
		for point:Vector3 in [a-tangent+Vector3(-0.0015,0,0),a+tangent+Vector3(-0.0015,0,0),a-tangent+Vector3(0.0015,0,0),a+tangent+Vector3(-0.0015,0,0),a+tangent+Vector3(0.0015,0,0),a-tangent+Vector3(0.0015,0,0)]: stitch.add_vertex(point)
	stitch.generate_normals()
	var stitch_material:=thread.duplicate() as StandardMaterial3D
	stitch_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	_mesh(node,"SewnPatchStitches",stitch.commit(),Vector3.ZERO,stitch_material)
	_box(self,label+"StreetMat",Vector3(at.x,0.012,at.z),Vector3(0.50,0.024,0.40),_fabric(Color("567a65"),Color("4e705c")))
	_cats.append({"node":node,"rest":at,"head":head,"tail":tail,"paws":paws})

func _cloth_ear(parent:Node3D,side:float,cloth:Material,inner:Material)->void:
	var ear:=Node3D.new()
	ear.position=Vector3(side*0.10,0.10,0)
	ear.rotation.z=-side*0.18
	parent.add_child(ear)
	var mesh:=PrismMesh.new()
	mesh.size=Vector3(0.12,0.16,0.055)
	var shell:=_mesh(ear,"ClothEar",mesh,Vector3(0,0.055,0),cloth)
	shell.rotation.z=side*0.05
	var inset:=PrismMesh.new()
	inset.size=Vector3(0.065,0.09,0.005)
	_mesh(ear,"FeltInnerEar",inset,Vector3(0,0.055,-0.031),inner)

func _build_pitch_signs()->void:
	var wood:=_material(Color("615442"))
	_box(self,"BeatBoard",Vector3(0,0.13,-1.18),Vector3(0.65,0.22,0.12),wood)
	for index in 3:
		var x:=0.22-index*0.22
		var indicator:=_cylinder(self,"ChargeIndicator"+str(index+1),Vector3(x,0.255,-1.18),0.055,0.028,_indicator_off)
		_indicators.append(indicator)
		_label(self,String.chr(65+index),Vector3(x,0.13,-1.245),28,0.0023)
	_sign=Label3D.new()
	_sign.name="PitchSign"
	_sign.position=Vector3(0,1.97,0)
	_sign.font_size=34
	_sign.pixel_size=0.0038
	_sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	_sign.modulate=Color("eee0bc")
	_sign.outline_modulate=Color("23302d")
	_sign.outline_size=7
	_sign.visibility_range_end=26.0
	add_child(_sign)

func _fabric(base:Color,stripe:Color)->StandardMaterial3D:
	var image:=Image.create(64,64,false,Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var weave:=0.94+0.035*cos(float(x)*PI)+0.025*cos(float(y)*PI)
			var tint:=base.lerp(stripe,0.65 if (y/8)%3==0 else 0.0)
			image.set_pixel(x,y,Color(tint.r*weave,tint.g*weave,tint.b*weave))
	image.generate_mipmaps()
	var material:=_material(Color.WHITE,0.0,1.0)
	material.albedo_texture=ImageTexture.create_from_image(image)
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.metallic_specular=0.08
	return material

func _joint(start:Vector3,end:Vector3,bend:Vector3)->Vector3:
	var offset:=end-start
	var distance:=maxf(offset.length(),0.001)
	var direction:=offset/distance
	var reach:=clampf(distance,0.011,0.589)
	var along:=(0.30*0.30-0.29*0.29+reach*reach)/(2.0*reach)
	var height:=sqrt(maxf(0.0,0.30*0.30-along*along))
	var pole:=bend.slide(direction).normalized()
	if pole.length_squared()<0.01:pole=Vector3.RIGHT.slide(direction).normalized()
	return start+direction*along+pole*height

func _pose_segment(node:MeshInstance3D,a:Vector3,b:Vector3)->void:
	node.position=(a+b)*0.5
	node.basis=Basis(Quaternion(Vector3.UP,(b-a).normalized())).scaled_local(Vector3(1,a.distance_to(b),1))

func _label(parent:Node3D,text:String,at:Vector3,font_size:int,pixel_size:float)->void:
	var label:=Label3D.new()
	label.text=text
	label.font_size=font_size
	label.pixel_size=pixel_size
	label.position=at
	label.rotation.y=PI
	label.modulate=Color("eee0ba")
	label.outline_size=3
	parent.add_child(label)

func _box(parent:Node3D,label:String,at:Vector3,size:Vector3,material:Material)->MeshInstance3D:
	var mesh:=BoxMesh.new()
	mesh.size=size
	return _mesh(parent,label,mesh,at,material)

func _cylinder(parent:Node3D,label:String,at:Vector3,radius:float,height:float,material:Material)->MeshInstance3D:
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=24
	return _mesh(parent,label,mesh,at,material)

func _ellipsoid(parent:Node3D,label:String,at:Vector3,radii:Vector3,material:Material)->void:
	var mesh:=SphereMesh.new()
	mesh.radius=1.0
	mesh.height=2.0
	mesh.radial_segments=24
	mesh.rings=12
	var node:=_mesh(parent,label,mesh,at,material)
	node.scale=radii

func _segment(parent:Node3D,label:String,a:Vector3,b:Vector3,radius:float,material:Material)->void:
	var node:=_cylinder(parent,label,(a+b)*0.5,radius,1.0,material)
	_pose_segment(node,a,b)

func _mesh(parent:Node3D,label:String,mesh:Mesh,at:Vector3,material:Material)->MeshInstance3D:
	var node:=MeshInstance3D.new()
	node.name=label
	node.mesh=mesh
	node.position=at
	node.material_override=material
	parent.add_child(node)
	return node

func _material(color:Color,metallic:float=0.0,roughness:float=0.94)->StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.metallic=metallic
	material.roughness=roughness
	return material
