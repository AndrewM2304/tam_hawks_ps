extends Node3D
## Original fictional musician. Reuses the cleared anatomical/garment helpers;
## no photograph, likeness, voice, recording or branded instrument is included.

const Garments = preload("res://game/player/skater_garments.gd")
const Anatomy = preload("res://game/player/skater_anatomy.gd")
const Footwear = preload("res://game/player/skater_footwear.gd")
const BuskerSound = preload("res://game/characters/busker_sound.gd")

var reduced_motion := false
var _garments: RefCounted
var _anatomy: RefCounted
var _hands: Array[Node3D] = []
var _head: Node3D
var _sign: Label3D
var _phase := 0.0
var _state := "idle"
var _music: AudioStreamPlayer3D
var _audio_gain := 0.0
var _audio_enabled := true

func _ready() -> void:
	var shirt := _material(Color("655449"))
	var denim := _material(Color("30383c"))
	var rubber := _material(Color("a5a195"))
	var shoes := _material(Color("34312b"))
	_garments = Garments.new()
	_garments.build(self, shirt, denim)
	_anatomy = Anatomy.new()
	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = 0.062
	collar_mesh.bottom_radius = 0.072
	collar_mesh.height = 0.070
	collar_mesh.radial_segments = 24
	var collar := MeshInstance3D.new()
	collar.name = "BuskerJacketCollar"
	collar.mesh = collar_mesh
	collar.material_override = shirt
	collar.position = Vector3(0, 1.426, -0.012)
	add_child(collar)
	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0, 1.410, 0) - Vector3(0, -0.13, 0.036)
	add_child(_head)
	_anatomy.build_head(_head)
	for side: float in [-1.0, 1.0]:
		var shoe := Node3D.new()
		shoe.name = "BuskerShoe"
		shoe.position = Vector3(side * 0.14, 0.061, -0.015)
		shoe.rotation.y = PI + side * 0.12
		add_child(shoe)
		Footwear.build(shoe, shoes, rubber, denim)
		_hands.append(_anatomy.build_hand(self, side))
	_build_guitar()
	_build_case()
	_sign = Label3D.new()
	_sign.name = "ChallengeSign"
	_sign.position = Vector3(0.0, 2.03, 0.0)
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.font_size = 34
	_sign.pixel_size = 0.0038
	_sign.modulate = Color("f5e7c9")
	_sign.outline_modulate = Color("202b2a")
	_sign.outline_size = 7
	_sign.visibility_range_end = 25.0
	add_child(_sign)
	_music = AudioStreamPlayer3D.new()
	_music.name = "OriginalBuskerPlucks"
	_music.stream = BuskerSound.stream()
	_music.position = Vector3(0, 1.0, 0)
	_music.max_distance = 28.0
	_music.unit_size = 4.0
	_music.max_db = 0.0
	_music.max_polyphony = 1
	add_child(_music)
	_apply_audio()
	set_encounter_state(_state, 0, 0)
	_pose()

func set_audio_gain(value: float) -> void:
	_audio_gain = clampf(value, 0.0, 1.0) if is_finite(value) else 0.0
	_apply_audio()

func set_audio_enabled(value: bool) -> void:
	_audio_enabled = value
	_apply_audio()

func _apply_audio() -> void:
	if not is_instance_valid(_music): return
	_music.volume_db = linear_to_db(_audio_gain * 0.30) if _audio_gain > 0.0 else -80.0
	if not _audio_enabled or _audio_gain <= 0.0:
		_music.stop()
	elif not _music.playing and AudioServer.get_driver_name() != "Dummy":
		_music.play()

func set_encounter_state(state: String, families: int, remaining: float) -> void:
	_state = state
	if not is_instance_valid(_sign): return
	match state:
		"active": _sign.text = "MO\n%s / 3 TYPES  ·  %ss" % [families, ceili(remaining)]
		"success": _sign.text = "MO\nYA DANCER!"
		"failed": _sign.text = "MO\nANOTHER GO?"
		_: _sign.text = "MO\nBig Finish"

func _process(delta: float) -> void:
	if reduced_motion: return
	_phase += delta
	_pose()

func _pose() -> void:
	var nod := sin(_phase * 2.6) * 0.025
	var strum := sin(_phase * (15.0 if _state == "success" else 8.0)) * 0.035
	_garments.pose_body(Transform3D(Basis.IDENTITY, Vector3(0, 0.94, 0)),
		Transform3D(Basis(Vector3.RIGHT, -0.025), Vector3(0, 0.94, 0)))
	_head.rotation.x = nod - 0.035
	_head.position = Vector3(0, 1.410, -0.012) - _head.basis * Vector3(0, -0.13, 0.036)
	for index in 2:
		var side: float = -1.0 if index == 0 else 1.0
		var hip := Vector3(side * 0.105, 0.965, 0)
		var knee := Vector3(side * 0.14, 0.52, -0.025)
		var ankle := Vector3(side * 0.14, 0.061, -0.015)
		_garments.pose_leg(side, hip, knee, ankle)
		var shoulder := Vector3(side * 0.205, 1.36, -0.01)
		var elbow := Vector3(-0.32, 1.23, -0.12) if index == 0 else Vector3(0.32, 1.12, -0.13)
		var wrist := Vector3(-0.265, 1.40, -0.20) if index == 0 else Vector3(0.12, 1.01 + strum, -0.30)
		var hand_basis := _hand_basis(elbow - wrist)
		if index == 0:
			# Place the anatomical palm on the neck, rather than raising a wrist
			# beside it. Its local palm is 7.5 cm beyond the wrist towards -Y.
			var palm_target := Vector3(0.02, 1.0, -0.21) + Basis(Vector3.FORWARD, -0.55) * Vector3(0, 0.45, -0.055)
			wrist = palm_target + Vector3(0, -0.06, 0.03)
			for iteration in 5:
				elbow = _joint(shoulder, wrist, Vector3(-0.8, -0.15, 0.2))
				hand_basis = _hand_basis(elbow - wrist)
				wrist = palm_target - hand_basis * Vector3(0, -0.075, -0.015)
			elbow = _joint(shoulder, wrist, Vector3(-0.8, -0.15, 0.2))
			hand_basis = _hand_basis(elbow - wrist)
		_garments.pose_arm(side, shoulder, elbow, wrist)
		_hands[index].position = wrist
		_hands[index].basis = hand_basis
		_anatomy.pose_hand(_hands[index], 1.0 if index == 0 else 0.25)

func _hand_basis(forearm: Vector3) -> Basis:
	var y := forearm.normalized()
	var z := Vector3.BACK.slide(y).normalized()
	if z.length_squared() < 0.001: z = Vector3.RIGHT.slide(y).normalized()
	var x := y.cross(z).normalized()
	return Basis(x, y, x.cross(y).normalized())

func _joint(start: Vector3, end: Vector3, bend: Vector3) -> Vector3:
	var offset := end - start
	var distance := maxf(offset.length(), 0.001)
	var direction := offset / distance
	var reach := clampf(distance, 0.011, 0.589)
	var along := (0.30 * 0.30 - 0.29 * 0.29 + reach * reach) / (2.0 * reach)
	var height := sqrt(maxf(0.0, 0.30 * 0.30 - along * along))
	var pole := bend.slide(direction).normalized()
	if pole.length_squared() < 0.01: pole = Vector3.RIGHT.slide(direction).normalized()
	return start + direction * along + pole * height

func _build_guitar() -> void:
	var guitar := Node3D.new()
	guitar.name = "OriginalAcousticGuitar"
	guitar.position = Vector3(0.02, 1.00, -0.21)
	guitar.rotation.z = 0.55
	add_child(guitar)
	var wood := _material(Color("97704a"))
	wood.cull_mode = BaseMaterial3D.CULL_DISABLED
	var edge := _material(Color("4b3528"))
	var dark := _material(Color("202526"))
	var metal := _material(Color("bab4a4"))
	# Smooth original outline in the instrument's XY plane, with depth in Z.
	var profile: Array[Vector2] = []
	for sample in 48:
		var angle := TAU * sample / 48.0
		var y := sin(angle) * 0.25
		var waist := 0.77 + 0.23 * absf(sin(angle))
		profile.append(Vector2(cos(angle) * 0.205 * waist, y))
	var front := SurfaceTool.new()
	front.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in profile.size():
		var a: Vector2 = profile[index]
		var b: Vector2 = profile[(index + 1) % profile.size()]
		for point: Vector3 in [Vector3(0, 0, -0.055), Vector3(b.x, b.y, -0.055), Vector3(a.x, a.y, -0.055)]: front.add_vertex(point)
		for point: Vector3 in [Vector3(a.x, a.y, -0.055), Vector3(b.x, b.y, -0.055), Vector3(a.x, a.y, 0.055),
			Vector3(b.x, b.y, -0.055), Vector3(b.x, b.y, 0.055), Vector3(a.x, a.y, 0.055)]: sides.add_vertex(point)
	_finish(guitar, "SpruceSoundboard", front, wood)
	_finish(guitar, "GuitarRim", sides, edge)
	_box(guitar, "Fretboard", Vector3(0, 0.42, -0.025), Vector3(0.048, 0.50, 0.035), dark)
	_box(guitar, "Headstock", Vector3(0, 0.73, -0.012), Vector3(0.075, 0.13, 0.04), edge)
	_box(guitar, "Bridge", Vector3(0, -0.12, -0.061), Vector3(0.095, 0.025, 0.012), dark)
	var hole := CylinderMesh.new()
	hole.top_radius = 0.061
	hole.bottom_radius = 0.061
	hole.height = 0.002
	hole.radial_segments = 32
	var sound_hole := MeshInstance3D.new()
	sound_hole.name = "SoundHole"
	sound_hole.mesh = hole
	sound_hole.material_override = dark
	sound_hole.rotation.x = PI / 2.0
	sound_hole.position = Vector3(0, 0.065, -0.057)
	guitar.add_child(sound_hole)
	for string_index in 6:
		_box(guitar, "String", Vector3(-0.015 + string_index * 0.006, 0.26, -0.065), Vector3(0.0009, 0.77, 0.0009), metal)
	for fret in 12:
		_box(guitar, "Fret", Vector3(0, 0.20 + fret * 0.034, -0.045), Vector3(0.049, 0.0016, 0.002), metal)

func _build_case() -> void:
	var canvas := _material(Color("33352e"))
	var lining := _material(Color("564950"))
	_box(self, "OpenGuitarCase", Vector3(0.63, 0.08, -0.39), Vector3(0.42, 0.14, 0.91), canvas)
	_box(self, "CaseLining", Vector3(0.63, 0.153, -0.39), Vector3(0.35, 0.012, 0.84), lining)
	var sign := Label3D.new()
	sign.name = "BuskerCaseSign"
	sign.text = "GIE IT LALDY"
	sign.font_size = 28
	sign.pixel_size = 0.0018
	sign.position = Vector3(0.63, 0.29, -0.80)
	sign.rotation.y = PI
	sign.modulate = Color("e9ddbd")
	_box(self, "CaseSignBacking", Vector3(0.63, 0.29, -0.79), Vector3(0.46, 0.16, 0.016), canvas)
	add_child(sign)

func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)

func _finish(parent: Node3D, label: String, surface: SurfaceTool, material: Material) -> void:
	surface.generate_normals()
	surface.index()
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = surface.commit()
	node.material_override = material
	parent.add_child(node)

func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.91
	return result
