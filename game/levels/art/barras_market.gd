extends RefCounted
## Original modeled interpretation of inspected Barras/Barrowland photographs.
## No reference image, traced logo, downloaded font or photo texture is bundled.
## World source owns all counters, backing walls, shelter and post collision.


static func build_rows(art: Node3D) -> void:
	_materials(art)
	var rows := Node3D.new()
	rows.name = "BarrasCoveredMarket"
	art.add_child(rows)
	var batch: Dictionary = {}
	for x: float in [105.25,122.75]:
		# Low opposed hall fronts frame an actual aisle, rather than isolated tents.
		for z: float in [0.3,7.0,17.7]:
			art._batch_box(batch,"warehouse_brick",Vector3(0.6,3.7,0.7),Vector3(x,1.85,z))
		art._batch_box(batch,"market_green",Vector3(0.28,0.8,21.5),Vector3(x,3.35,7))
		art._batch_box(batch,"iron",Vector3(0.4,0.1,22),Vector3(x,3.82,7))
	for x: float in [109.0,119.0]:
		var side: float = -1.0 if x < 114 else 1.0
		for rib: int in range(18):
			var offset := -2.95 + float(rib) * 0.35
			art._batch_box(batch,"market_roof",Vector3(0.035,0.04,22),Vector3(x+offset,5.59+side*offset*0.14,7))
		var edge_x := 112.0 if x < 114 else 116.0
		art._batch_box(batch,"iron",Vector3(0.12,0.2,22),Vector3(edge_x,5.08,7))
		# Ceiling trusses sit above4.9m and leave a continuous central light slot.
		for z: float in [-1.0,7.5,17.0]:
			art._batch_box(batch,"iron",Vector3(5.8,0.1,0.1),Vector3(x,5.07,z))
	for z: float in [-2.0,18.0]:
		_gateway(art,rows,batch,z)
	# The original repair shed is a modest market frontage, with real thresholds.
	art._batch_box(batch,"slate",Vector3(12.2,0.18,15.2),Vector3(56,4.94,7.5))
	for x: float in [49.95,62.05]:
		art._batch_box(batch,"iron",Vector3(0.12,0.18,15.2),Vector3(x,4.85,7.5))
	art._batch_box(batch,"market_green",Vector3(0.16,0.7,14.8),Vector3(62.12,4.08,7.5))
	for x: float in [52.0,56.0,60.0]:
		art._batch_box(batch,"iron",Vector3(3.4,2.65,0.12),Vector3(x,2.03,15.08))
		for rib: int in range(12):
			art._batch_box(batch,"market_shutter",Vector3(3.3,0.035,0.04),Vector3(x,0.85+float(rib)*0.205,15.16))
	art._batch_box(batch,"market_green",Vector3(13.0,0.7,0.16),Vector3(56,4.08,15.12))
	var repair_label := _label(rows,"CALTON REPAIR & REUSE",Vector3(56,4.1,15.23),35,0.0085)
	repair_label.modulate=Color("ddd7b9")
	art._flush_batches(rows,batch)


static func _gateway(art: Node3D, rows: Node3D, batch: Dictionary, z: float) -> void:
	# A thin open red-iron arch and circular spandrels echo the inspected gateways.
	var path := PackedVector3Array()
	for index: int in range(25):
		var a := PI * float(index) / 24.0
		path.append(Vector3(114+cos(a)*4.0,5.25+sin(a)*1.3,z))
	var paths: Array[PackedVector3Array] = [path]
	art._batch_box(batch,"market_red",Vector3(8.0,0.16,0.15),Vector3(114,6.55,z))
	for x: float in [110.0,118.0]:
		art._batch_box(batch,"market_red",Vector3(0.16,7.6,0.16),Vector3(x,3.8,z))
	for index: int in range(9):
		var ring := PackedVector3Array()
		var x := 111.0+float(index)*0.75
		for step: int in range(17):
			var a := TAU*float(step)/16.0
			ring.append(Vector3(x+cos(a)*0.24,6.16+sin(a)*0.24,z))
		paths.append(ring)
	_tubes(rows,paths,0.045,art.materials["market_red"])
	var front := _label(rows,"THE BARRAS",Vector3(114,7.05,z+0.1),48,0.014)
	front.modulate=Color("e2bca4")
	var back := _label(rows,"THE BARRAS",Vector3(114,7.05,z-0.1),48,0.014)
	back.rotation.y=PI
	back.modulate=front.modulate


static func dress_stall(art: Node3D, stall: Node3D) -> void:
	_materials(art)
	var batch: Dictionary = {}
	var trade: String = stall.get_meta("market_trade","books")
	# All original merchandise stays inside the solid counter's7x3 footprint.
	art._batch_box(batch,"wood",Vector3(7,1.2,3),Vector3(0,0.6,0))
	for end: float in [-3.45,3.45]:
		for side: float in [-1.45,1.45]:
			art._batch_cylinder(batch,"iron",0.045,3.35,Vector3(end,1.675,side))
	for stripe: int in range(14):
		art._batch_box(batch,"market_canvas" if stripe%2 else "market_green",Vector3(0.5,0.08,3.1),Vector3(-3.25+float(stripe)*0.5,3.23,0))
	art._batch_box(batch,"market_green",Vector3(7.1,0.55,0.10),Vector3(0,2.98,-1.57))
	art._batch_box(batch,"market_green",Vector3(7.1,0.55,0.10),Vector3(0,2.98,1.57))
	match trade:
		"records":
			for x: float in [-2.4,-0.8,0.8,2.4]:
				art._batch_box(batch,"wood",Vector3(1.2,0.28,1.4),Vector3(x,1.34,0))
				for index: int in range(7):
					art._batch_box(batch,"shop_navy" if index%2 else "cream",Vector3(0.035,0.62,0.60),Vector3(x-0.42+float(index)*0.14,1.72,0))
		"clothes":
			for x: float in [-2.4,-0.8,0.8,2.4]:
				# Folded clothes plus small hanging garments without copied graphics.
				for layer: int in range(3):
					art._batch_box(batch,"shop_burgundy" if layer%2 else "cream",Vector3(1.0,0.12,0.8),Vector3(x,1.28+float(layer)*0.12,0.2))
				art._batch_box(batch,"teal",Vector3(0.55,0.78,0.16),Vector3(x,2.30,-0.65))
				art._batch_box(batch,"teal",Vector3(0.95,0.23,0.16),Vector3(x,2.61,-0.65))
		"homewares":
			for x: float in [-2.5,-1.25,0.0,1.25,2.5]:
				art._batch_cylinder(batch,"cream",0.23,0.42,Vector3(x,1.41,0.6))
				art._batch_cylinder(batch,"shop_burgundy",0.16,0.30,Vector3(x,1.35,-0.45))
				art._batch_box(batch,"brass",Vector3(0.35,0.04,0.35),Vector3(x,1.53,-0.45))
		_:
			for x: float in [-2.5,-0.85,0.85,2.5]:
				for index: int in range(5):
					art._batch_box(batch,"shop_umber" if index%2 else "shop_navy",Vector3(0.22,0.4,0.7),Vector3(x-0.47+float(index)*0.235,1.4,0))
	art._flush_batches(stall,batch)
	var words := {"records":"SECOND SPIN / RECORDS","clothes":"GOOD AGAIN / CLOTHES","homewares":"ODDS & ENDS","books":"BOOKS BY THE BOX"}
	for side: float in [-1.0,1.0]:
		var label := _label(stall,words.get(trade,"ODDS & ENDS"),Vector3(0,2.98,side*1.64),32,0.010)
		if side < 0: label.rotation.y=PI


static func build_venue(art: Node3D) -> void:
	_materials(art)
	var venue := Node3D.new()
	venue.name="BarrowlandLandmark"
	venue.position=Vector3(108,1.5,-41.9)
	art.add_child(venue)
	var batch: Dictionary = {}
	# Broad grey-green gridded upper front over low shutters: intentionally unlike
	# the generic tall sandstone shop block used by the first layout prototype.
	art._batch_box(batch,"venue_panel",Vector3(31.9,9.0,0.14),Vector3(0,7.45,0))
	for x: float in [-15.5,-13.5,-11.5,-9.5,-7.5,-5.5,-3.5,-1.5,0.5,2.5,4.5,6.5,8.5,10.5,12.5,14.5]:
		art._batch_box(batch,"venue_grid",Vector3(0.065,9,0.08),Vector3(x,7.45,0.12))
	for y: float in [3.0,4.5,6.0,7.5,9.0,10.5,12.0]:
		art._batch_box(batch,"venue_grid",Vector3(32,0.07,0.08),Vector3(0,y,0.12))
	for x: float in [-12.0,-6.0,0.0,6.0,12.0]:
		art._batch_box(batch,"window_shadow",Vector3(4.5,2.8,0.12),Vector3(x,1.4,0.06))
		for rib: int in range(15):
			art._batch_box(batch,"market_shutter",Vector3(4.5,0.065,0.06),Vector3(x,0.14+float(rib)*0.18,0.15))
		art._batch_box(batch,"sandstone",Vector3(1.0,3.0,0.28),Vector3(x+2.7,1.5,0.12))
	art._batch_box(batch,"cream",Vector3(1.5,12.0,0.22),Vector3(15.1,6,0.16))
	for y: float in [4.0,7.0,10.0]:
		art._batch_box(batch,"window_shadow",Vector3(0.8,2.2,0.1),Vector3(15.1,y,0.32))
	for x: float in [-4.5,-2.7,-0.9,0.9,2.7,4.5]:
		art._batch_box(batch,"window_dull",Vector3(1.25,0.8,0.15),Vector3(x,3.65,0.22))
	# Original hand-authored strokes interpret the lettering's case, slant and
	# loopingB; curves are not traced from a photograph or supplied logo file.
	var letters := _letter_paths()
	_tubes(venue,letters,0.125,art.materials["neon_teal"])
	_tubes(venue,_depth(letters,0.095),0.087,art.materials["neon_red"])
	_tubes(venue,_depth(letters,0.16),0.042,art.materials["neon_cream"])
	var stars: Array[PackedVector3Array] = []
	for item: Vector3 in [Vector3(-12,10.2,0.8),Vector3(-6.5,11,1.0),Vector3(0,10.8,1.15),Vector3(6.5,11,1.0),Vector3(12.2,10.2,0.8),Vector3(-11,4.3,0.8),Vector3(-4.8,4.3,0.95),Vector3(3.0,4.3,1.0),Vector3(10.4,4.3,0.8)]:
		stars.append(_star(Vector2(item.x,item.y),item.z,0.3))
	_tubes(venue,stars,0.055,art.materials["neon_cream"])
	var rays: Array[PackedVector3Array] = []
	for anchor: Vector2 in [Vector2(-8.5,9.6),Vector2(-1.8,10),Vector2(4,10),Vector2(10.5,9.6)]:
		for ray: int in range(4):
			rays.append(PackedVector3Array([Vector3(anchor.x,anchor.y,0.30),Vector3(anchor.x-4+float(ray)*1.15,anchor.y+1.8,0.30)]))
	_tubes(venue,rays,0.027,art.materials["neon_red"])
	var small_teal: Array[PackedVector3Array] = []
	var small_red: Array[PackedVector3Array] = []
	for index: int in range(17):
		var x := -14.5+float(index)*1.8
		var y := 5.5 if index%2 else 11.5
		if index%2: small_teal.append(_star(Vector2(x,y),0.2,0.33))
		else: small_red.append(_star(Vector2(x,y),0.2,0.33))
	_tubes(venue,small_teal,0.035,art.materials["neon_teal"])
	_tubes(venue,small_red,0.035,art.materials["neon_red"])
	art._flush_batches(venue,batch)


static func _letter_paths() -> Array[PackedVector3Array]:
	var glyphs: Array = [
		# Each entry is an advance plus one or more original pen strokes.
		[1.45,[[Vector2(0.05,0),Vector2(0.38,1.55)],[Vector2(0.15,1.48),Vector2(0.75,1.55),Vector2(1.02,1.32),Vector2(0.85,0.99),Vector2(0.4,0.8),Vector2(0.16,0.81),Vector2(0.75,0.85),Vector2(1.03,0.55),Vector2(0.86,0.22),Vector2(0.38,0),Vector2(-0.13,-0.12),Vector2(-0.42,-0.46),Vector2(-0.29,-0.72),Vector2(0.02,-0.7),Vector2(0.27,-0.35),Vector2(0.28,0.05)]]],
		[1.1,[[Vector2(0.78,0.75),Vector2(0.46,0.94),Vector2(0.09,0.65),Vector2(0.05,0.23),Vector2(0.3,0.04),Vector2(0.66,0.26),Vector2(0.86,0.84),Vector2(0.71,0.22),Vector2(0.82,0.03),Vector2(1.05,0.12)]]],
		[0.9,[[Vector2(0.04,0.02),Vector2(0.18,0.7),Vector2(0.33,0.96),Vector2(0.46,0.85),Vector2(0.43,0.59),Vector2(0.69,0.9),Vector2(0.82,0.83)]]],
		[0.9,[[Vector2(0.04,0.02),Vector2(0.18,0.7),Vector2(0.33,0.96),Vector2(0.46,0.85),Vector2(0.43,0.59),Vector2(0.69,0.9),Vector2(0.82,0.83)]]],
		[1.1,[[Vector2(0.85,0.75),Vector2(0.64,0.96),Vector2(0.25,0.84),Vector2(0.05,0.48),Vector2(0.15,0.12),Vector2(0.49,0.03),Vector2(0.81,0.3),Vector2(0.89,0.66),Vector2(0.85,0.75)]]],
		[1.45,[[Vector2(0.06,0.91),Vector2(0.04,0.13),Vector2(0.28,0.06),Vector2(0.64,0.69),Vector2(0.66,0.18),Vector2(0.86,0.06),Vector2(1.2,0.49),Vector2(1.32,0.95)]]],
		[0.7,[[Vector2(0.13,0.05),Vector2(0.48,1.48),Vector2(0.62,1.54),Vector2(0.41,0.59),Vector2(0.26,0.08),Vector2(0.56,0.03)]]],
		[1.1,[[Vector2(0.78,0.75),Vector2(0.46,0.94),Vector2(0.09,0.65),Vector2(0.05,0.23),Vector2(0.3,0.04),Vector2(0.66,0.26),Vector2(0.86,0.84),Vector2(0.71,0.22),Vector2(0.82,0.03),Vector2(1.05,0.12)]]],
		[1.15,[[Vector2(0.04,0.02),Vector2(0.22,0.89),Vector2(0.25,0.47),Vector2(0.59,0.9),Vector2(0.88,0.88),Vector2(0.91,0.53),Vector2(0.78,0.05),Vector2(1.07,0.10)]]],
		[1.1,[[Vector2(0.82,0.77),Vector2(0.52,0.94),Vector2(0.15,0.74),Vector2(0.03,0.33),Vector2(0.24,0.05),Vector2(0.57,0.17),Vector2(0.81,0.59),Vector2(1.04,1.5),Vector2(0.91,1.52),Vector2(0.63,0.16),Vector2(0.93,0.03)]]],
	]
	var result: Array[PackedVector3Array] = []
	var advance := -12.6
	for glyph: Array in glyphs:
		for stroke: Array in glyph[1]:
			var path := PackedVector3Array()
			for index: int in range(stroke.size()-1):
				var a: Vector2=stroke[maxi(0,index-1)]
				var b: Vector2=stroke[index]
				var c: Vector2=stroke[index+1]
				var d: Vector2=stroke[mini(stroke.size()-1,index+2)]
				for step: int in range(5):
					var t := float(step)/5.0
					var v := 0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
					path.append(Vector3(advance+(v.x+0.17*v.y)*2.2,6.45+v.y*2.2,0.42))
			var last: Vector2=stroke[-1]
			path.append(Vector3(advance+(last.x+0.17*last.y)*2.2,6.45+last.y*2.2,0.42))
			result.append(path)
		advance+=float(glyph[0])*2.2
	return result


static func _depth(paths: Array[PackedVector3Array], amount: float) -> Array[PackedVector3Array]:
	var result: Array[PackedVector3Array] = []
	for path: PackedVector3Array in paths:
		var shifted := path.duplicate()
		for index: int in range(shifted.size()): shifted[index].z+=amount
		result.append(shifted)
	return result


static func _star(center: Vector2, radius: float, z: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	for index: int in range(11):
		var a := PI/2+float(index)*PI/5
		var r := radius if index%2==0 else radius*0.42
		points.append(Vector3(center.x+cos(a)*r,center.y+sin(a)*r,z))
	return points


static func _tubes(parent: Node3D, paths: Array[PackedVector3Array], radius: float, material: Material) -> void:
	var transforms: Array[Transform3D] = []
	for path: PackedVector3Array in paths:
		for index: int in range(path.size()-1):
			var delta := path[index+1]-path[index]
			if delta.length_squared()<0.000001: continue
			var basis := Basis(Quaternion(Vector3.UP,delta.normalized()))*Basis.from_scale(Vector3(radius*2,delta.length()+radius*0.3,radius*2))
			transforms.append(Transform3D(basis,(path[index]+path[index+1])*0.5))
	var cylinder := CylinderMesh.new()
	cylinder.top_radius=0.5
	cylinder.bottom_radius=0.5
	cylinder.height=1.0
	cylinder.radial_segments=8
	var multimesh := MultiMesh.new()
	multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multimesh.mesh=cylinder
	multimesh.instance_count=transforms.size()
	for index: int in range(transforms.size()): multimesh.set_instance_transform(index,transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh=multimesh
	instance.material_override=material
	parent.add_child(instance)


static func _label(parent: Node3D, text: String, at: Vector3, font_size: int, pixel_size: float) -> Label3D:
	var label:=Label3D.new()
	label.text=text
	label.position=at
	label.font_size=font_size
	label.pixel_size=pixel_size
	label.modulate=Color("e3ddc7")
	label.outline_size=0
	# Opposite gateway and counter faces are authored explicitly. Showing the
	# reverse of either face would superimpose mirrored text on its proper mate.
	label.double_sided=false
	parent.add_child(label)
	return label


static func _materials(art: Node3D) -> void:
	var colors := {"market_green":"3f6755","market_red":"744134","market_canvas":"d1c9ac","market_roof":"596960","market_shutter":"727b75","venue_panel":"6b7872","venue_grid":"414f4c","neon_teal":"3aaf9e","neon_red":"d87854","neon_cream":"f5dfa4"}
	for key: String in colors:
		if art.materials.has(key): continue
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color(colors[key])
		material.roughness=0.72
		if key.begins_with("neon_"):
			material.emission_enabled=true
			material.emission=Color(colors[key])
			material.emission_energy_multiplier=0.35
		art.materials[key]=material
