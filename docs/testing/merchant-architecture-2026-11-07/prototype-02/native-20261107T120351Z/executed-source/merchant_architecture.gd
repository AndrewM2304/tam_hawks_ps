extends Node3D
## PRIVATE original Glasgow composite; startup-only art, never gameplay geometry.
## Declared ceiling: +90k source triangles /48 submitted batches /4MiB native
## mesh+instance buffers, zero added maps/material objects/lights/colliders.
## Exact shared materials are supplied by the selected world, not created here.
const Shell = preload("res://game/levels/art/facade_shell.gd")
const Arch = preload("res://game/levels/art/arch_mesh.gd")
const Batches = preload("res://game/levels/static_batches.gd")
const PAINT: Array[String] = ["shop_green","shop_burgundy","shop_navy","shop_umber"]
const SHOP_NAMES: Array[String] = ["CLOSE RECORDS","MERCHANT BOOKS","CROSS GROCER","EAST END REPAIRS"]
var report: Dictionary = {"scope":"Private geometry prototype; no final visual, pacing or M5 acceptance", "frontages":[], "shells":[], "openings":[], "labels":[], "errors":[], "batch_instances":0}
var _materials: Dictionary
var _batches: Dictionary = {}
var _meshes: Dictionary = {}
var _world: Node3D

static func build(parent: Node3D,materials: Dictionary,layout: Dictionary) -> Node3D:
	var layer = load("res://game/levels/art/merchant_architecture.gd").new()
	layer.name = "MerchantArchitecture"
	parent.add_child(layer)
	layer._compose(parent,materials,layout)
	return layer

func _compose(parent: Node3D,materials: Dictionary,layout: Dictionary) -> void:
	_world = parent
	_materials = materials
	set_meta(Batches.META_STATIC_SCOPE,true)
	var bodies: Array[StaticBody3D] = []
	for child: Node in parent.get_children():
		if child is StaticBody3D: bodies.append(child)
	for frontage: Dictionary in layout.get("hero_frontages",[]):
		if frontage.type == "brick_railway_arch":
			_underpass()
			continue
		var n: Array = frontage.face_into_street_xz
		var outward := Vector3(n[0],0,n[1])
		var across := Vector3.UP.cross(outward)
		var p: Array = frontage.line_xz
		var a := Vector3(p[0][0],0,p[0][1])
		var b := Vector3(p[1][0],0,p[1][1])
		var admitted := 0
		for body: StaticBody3D in bodies:
			for child: Node in body.get_children():
				if not child is MeshInstance3D or not child.mesh is BoxMesh: continue
				if not child.visible: continue
				var visual := child as MeshInstance3D
				var size: Vector3 = (visual.mesh as BoxMesh).size
				# Construction contracts are world-axis aligned native boxes. Reject
				# a rotated/scaled body rather than silently miscut its front.
				if not visual.global_basis.is_equal_approx(Basis.IDENTITY): continue
				var center: Vector3 = visual.global_position
				var width := absf(across.x)*size.x+absf(across.z)*size.z
				var depth := absf(outward.x)*size.x+absf(outward.z)*size.z
				var front := center+outward*depth*.5
				if absf((a-front).dot(outward))>.015: continue
				var lo := maxf(-width*.5,minf((a-center).dot(across),(b-center).dot(across)))
				var hi := minf(width*.5,maxf((a-center).dot(across),(b-center).dot(across)))
				if hi-lo<3.0: continue
				var frame := Transform3D(Basis(across,Vector3.UP,outward),front)
				_decorate_span(frontage,visual,frame,Vector3(width,size.y,depth),lo,hi)
				admitted += 1
		if admitted == 0: report.errors.append("No exact native front for "+str(frontage.id))
		else: report.frontages.append({"id":frontage.id,"native_fragments":admitted})
	_flush()
	report["submitted_batches"] = _batches.size()
	report["no_new_maps_or_materials"] = true
	report["native_collision_owned_by_level_designer"] = true

func _decorate_span(contract: Dictionary,visual: MeshInstance3D,frame: Transform3D,size: Vector3,lo: float,hi: float) -> void:
	var holes: Array[Rect2] = []
	var industrial: bool = str(contract.type).begins_with("brick_")
	var depot: bool = contract.id == "depot_front"
	var top := size.y*.5
	var cells := maxi(1,floori((hi-lo)/(6.3 if industrial else 6.0)))
	var step := (hi-lo)/cells
	var relief: float = float(contract.max_visual_depth_m)
	for index: int in cells:
		var x := lo+step*(index+.5)
		var at := frame*Vector3(x,0,0)
		var ground: float = float(contract.get("ground_y",_world.call("_ground",at.x,at.z)))
		var floor := ground-frame.origin.y
		var paint: String = PAINT[index%PAINT.size()]
		# Each shop/close steps to its own true graded street datum.
		if not industrial:
			if index%3 == 1:
				_closed_close(frame,x,floor,holes)
			else:
				_shop(frame,x,floor,minf(5.4,step-.28),paint,index,holes,relief)
		else:
			_goods_bay(frame,x,floor,minf(step-.8,4.6),index,holes,depot)
		var y := floor+(4.8 if industrial else 5.0)
		var level := 0
		while y+1.14<top-.5:
			var window_width := 1.55 if industrial else 1.2
			for offset: float in ([-step*.24,step*.24] if step>4.0 else [0.0]):
				var aperture := Rect2(x+offset-window_width*.5,y-1.02,window_width,2.04)
				holes.append(aperture)
				_window(frame,aperture,industrial,index+level,relief)
			level += 1
			y += 2.85
		# Dressed corners and a readable floor string belong to construction;
		# very fine block-by-block bevels would consume cost without a silhouette.
		if not industrial:
			_box("cut_stone",Vector3(step-.05,.12,.1),Vector3(x,floor+3.65,.02),frame)
		else:
			_box("warehouse_brick",Vector3(.38,size.y-.2,.10),Vector3(x-step*.5+.19,0,.025),frame)
	# Closed mass faces remain exact except genuine front apertures. Native Box
	# owners/shapes/support queries are deliberately not touched by this helper.
	var shell := MeshInstance3D.new()
	shell.name = "CutShell_"+str(contract.id)+"_"+str(report.shells.size())
	shell.mesh = Shell.make(size,holes,[])
	shell.material_override = _materials.warehouse_brick if industrial else _materials.sandstone
	add_child(shell)
	shell.global_transform = Transform3D(frame.basis,frame.origin-frame.basis.z*size.z*.5)
	visual.visible = false
	report.shells.append({"owner":str(visual.get_parent().name),"original_size":size,"apertures":holes.size(),"material":shell.material_override.get_instance_id()})
	for opening: Rect2 in holes:
		report.openings.append({"shell":str(shell.name),"frame":frame,"rectangle":opening,"recess_m":.22,"kind":contract.type})
	# All accessible depot roof edges remain at their native10m datum. Boundary
	# roofs alone have LD-approved +2m skyline allowance inside their footprints.
	if not depot:
		_cornice(frame,lo,hi,top,industrial,relief)
		_roof(frame,lo,hi,top,size.z,industrial)
	else:
		_box("cut_stone",Vector3(hi-lo,.12,.08),Vector3((lo+hi)*.5,top-.08,.0),frame)

func _window(frame: Transform3D,r: Rect2,industrial: bool,variation: int,relief: float) -> void:
	var c := r.get_center()
	var pane := "window_dull" if variation%5==0 else "facade_glass"
	_box(pane,Vector3(r.size.x,r.size.y,.025),Vector3(c.x,c.y,-.225),frame)
	var joinery := "iron" if industrial else "window_frame"
	for sign_value: float in [-1.0,1.0]:
		_box("cut_stone" if not industrial else "warehouse_brick",Vector3(.12,r.size.y+.18,.25),Vector3(c.x+sign_value*(r.size.x*.5+.06),c.y,-.105),frame)
		_box(joinery,Vector3(.055,r.size.y,.07),Vector3(c.x+sign_value*(r.size.x*.5-.028),c.y,-.17),frame)
		_box(joinery,Vector3(r.size.x,.065,.075),Vector3(c.x,c.y+sign_value*(r.size.y*.5-.033),-.165),frame)
	_box(joinery,Vector3(r.size.x,.055,.085),Vector3(c.x,c.y+.035,-.145),frame)
	_box(joinery,Vector3(.028,r.size.y*.48,.055),Vector3(c.x,c.y+r.size.y*.25,-.17),frame)
	_box("cut_stone",Vector3(r.size.x+.34,.15,.22),Vector3(c.x,r.end.y+.075,0),frame)
	_box("cut_stone",Vector3(r.size.x+.38,.1,.33),Vector3(c.x,r.position.y-.065,-.055),frame,Basis.from_euler(Vector3(.07,0,0)))
	_box("cut_stone",Vector3(r.size.x+.26,.035,.055),Vector3(c.x,r.position.y-.13,relief-.035),frame)
	if variation%4==1:
		_box("curtain",Vector3(r.size.x*.22,r.size.y-.1,.012),Vector3(c.x-r.size.x*.35,c.y,-.205),frame)

func _shop(frame: Transform3D,x: float,floor: float,width: float,paint: String,index: int,holes: Array[Rect2],relief: float) -> void:
	var door_x := x-width*.36
	var display_x := x+width*.13
	var display_w := width*.63
	holes.append(Rect2(door_x-.43,floor+.08,.86,2.62))
	holes.append(Rect2(display_x-display_w*.5,floor+.55,display_w,2.15))
	# Shopfront is real layered timber joinery, not a chunky block sitting on a wall.
	for edge: float in [-1.0,1.0]:
		_box(paint,Vector3(.16,3.4,.15),Vector3(x+edge*(width*.5-.08),floor+1.7,0),frame)
		_box("brass",Vector3(.025,2.9,.018),Vector3(x+edge*(width*.5-.08),floor+1.65,.084),frame)
	_box(paint,Vector3(width,.42,.18),Vector3(x,floor+3.08,.02),frame)
	_box("cut_stone",Vector3(width+.08,.09,.22),Vector3(x,floor+3.36,.0),frame)
	_box(paint,Vector3(display_w,.48,.12),Vector3(display_x,floor+.28,-.02),frame)
	_box("wood",Vector3(display_w-.12,2.08,.025),Vector3(display_x,floor+1.61,-.38),frame)
	for edge: float in [-1.0,1.0]:
		_box(paint,Vector3(.065,2.16,.28),Vector3(display_x+edge*(display_w*.5-.035),floor+1.625,-.12),frame)
	_box("shop_glass",Vector3(display_w-.10,2.06,.018),Vector3(display_x,floor+1.61,-.025),frame)
	_door(frame,door_x,floor,paint)
	# Only one original business sign per shop; vector glyph mesh shares cream,
	# adds no raster texture/material. Its exact tessellation is inventoried natively.
	_text(SHOP_NAMES[index%SHOP_NAMES.size()],Vector3(x,floor+3.08,relief-.005),frame,minf(.22,(width-.3)/14.0))
	for shelf: int in 2:
		_box("wood",Vector3(display_w-.18,.05,.24),Vector3(display_x,floor+.84+shelf*.7,-.17),frame)
		for item: int in 7:
			var color: String = PAINT[(item+shelf)%4]
			var item_x := display_x-display_w*.42+item*display_w*.14
			if index%2==0:
				_box(color,Vector3(.23,.29,.035),Vector3(item_x,floor+1.02+shelf*.7,-.15),frame,Basis.from_euler(Vector3(0,.1*(item%3-1),.04*(item%2))))
				_box("cream",Vector3(.14,.025,.006),Vector3(item_x,floor+1.09+shelf*.7,-.13),frame)
			else:
				_box(color,Vector3(.07,.22+.025*(item%3),.16),Vector3(item_x,floor+.99+shelf*.7,-.14),frame,Basis.from_euler(Vector3(0,0,.08*(item%3-1))))

func _door(frame: Transform3D,x: float,floor: float,paint: String) -> void:
	_box(paint,Vector3(.84,2.58,.065),Vector3(x,floor+1.37,-.18),frame)
	_box("facade_glass",Vector3(.61,1.22,.015),Vector3(x,floor+1.90,-.14),frame)
	for h: float in [.40,.85]:
		_box("wood",Vector3(.61,.32,.018),Vector3(x,floor+h,-.138),frame)
		for side: float in [-1.0,1.0]:
			_box(paint,Vector3(.025,.34,.025),Vector3(x+side*.317,floor+h,-.12),frame)
	_box("brass",Vector3(.025,.18,.035),Vector3(x+.28,floor+1.22,-.10),frame)
	_box("cut_stone",Vector3(.92,.06,.22),Vector3(x,floor+.045,-.09),frame)

func _closed_close(frame: Transform3D,x: float,floor: float,holes: Array[Rect2]) -> void:
	var r := Rect2(x-.76,floor+.06,1.52,3.2)
	holes.append(r)
	_box("window_shadow",Vector3(1.5,3.18,.02),Vector3(x,floor+1.66,-.34),frame)
	for side: float in [-1.0,1.0]:
		_box("cut_stone",Vector3(.18,3.48,.24),Vector3(x+side*.86,floor+1.74,-.08),frame)
		for tile: int in 12:
			_box("shop_green" if tile%2 else "cream",Vector3(.15,.13,.19),Vector3(x+side*.66,floor+.14+tile*.14,-.20),frame)
	_box("cut_stone",Vector3(1.94,.22,.27),Vector3(x,floor+3.36,-.035),frame)
	_door(frame,x,floor,"shop_navy")
	_text("CLOSE",Vector3(x,floor+2.99,-.10),frame,.16)

func _goods_bay(frame: Transform3D,x: float,floor: float,width: float,index: int,holes: Array[Rect2],depot: bool) -> void:
	var sill := floor+2.1 if depot else floor+.7
	var h := 3.0 if depot else 2.6
	var r := Rect2(x-width*.5,sill,width,h)
	holes.append(r)
	_box("shop_navy",Vector3(width,h,.035),Vector3(x,sill+h*.5,-.23),frame)
	for side: float in [-1.0,1.0]:
		_box("warehouse_brick",Vector3(.24,h+.28,.27),Vector3(x+side*(width*.5+.12),sill+h*.5,-.10),frame)
	_box("cut_stone",Vector3(width+.5,.18,.25),Vector3(x,r.end.y+.09,-.03),frame)
	_box("cut_stone",Vector3(width+.25,.12,.25),Vector3(x,sill-.06,-.04),frame)
	for strip: int in 10:
		_box("iron",Vector3(width-.07,.035,.025),Vector3(x,sill+.10+strip*(h-.2)/9,-.19),frame)
	_box("iron",Vector3(.055,h,.04),Vector3(x,sill+h*.5,-.16),frame)
	if index%2==0:
		_text("GOODS IN" if depot else "FOUNDRY WORKS",Vector3(x,r.end.y+.43,.08),frame,.22 if depot else .18)

func _cornice(frame: Transform3D,lo: float,hi: float,top: float,industrial: bool,relief: float) -> void:
	var key := "warehouse_brick" if industrial else "cut_stone"
	var center := (lo+hi)*.5
	for index: int in 3:
		var height: float = [.09,.14,.10][index]
		var depth: float = [.14,.20,.24][index]
		var inset: float = [.08,.04,0.0][index]
		_box(key,Vector3(hi-lo+.03,height,depth),Vector3(center,top-.36+index*.08,relief-inset-depth*.5),frame)
	if not industrial:
		for index: int in floori((hi-lo)/.46):
			_box("cut_stone",Vector3(.12,.10,.14),Vector3(lo+.25+index*.46,top-.43,relief-.09),frame)

func _roof(frame: Transform3D,lo: float,hi: float,top: float,depth: float,industrial: bool) -> void:
	# Pitched skyline stays entirely behind the native front, and inside the
	# non-skateable boundary footprint. LD granted at most2m above these tops.
	var roof_depth := minf(depth-.12,11.0)
	if roof_depth<1.0: return
	var center := Vector3((lo+hi)*.5,top+.62,-roof_depth*.5-.04)
	_primitive("prism","slate",Vector3(roof_depth,1.24,hi-lo-.08),center,frame,Basis.from_euler(Vector3(0,PI*.5,0)))
	if industrial: return
	for index: int in maxi(1,floori((hi-lo)/12.0)):
		var x := lo+3.0+index*12.0
		_box("sandstone",Vector3(1.2,.68,.65),Vector3(x,top+1.3,-roof_depth*.46),frame)
		_box("cut_stone",Vector3(1.32,.09,.76),Vector3(x,top+1.68,-roof_depth*.46),frame)
		for pot: int in 3:
			_primitive("cylinder","shop_umber",Vector3(.18,.25,.18),Vector3(x-.35+pot*.35,top+1.85,-roof_depth*.46),frame)

func _underpass() -> void:
	# Segmental bands sit entirely ABOVE the native8.5m soffit, not over the
	# ground path. Actual pier faces carry shallow brick/stone courses only.
	for x: float in [30,52,74]:
		for z: float in [-13.2,1.2]:
			_box("cut_stone",Vector3(1.92,.16,1.92),Vector3(x,8.35,z),Transform3D.IDENTITY)
			for course: int in 4:
				_box("warehouse_brick",Vector3(1.92,.07,1.92),Vector3(x,4.22+course*1.0,z),Transform3D.IDENTITY)
	for x: float in [28.02,75.98]:
		var outward := Vector3(-1,0,0) if x<40 else Vector3(1,0,0)
		var frame := Transform3D(Basis(Vector3.UP.cross(outward),Vector3.UP,outward),Vector3(x,8.51,-6))
		_primitive("arch","warehouse_brick",Vector3(6.25,.33,.14),Vector3.ZERO,frame)
	report.frontages.append({"id":"depot_underpass","native_piers":6,"minimum_art_soffit_y":8.51,"native_clearance_m":4.5})

func _box(key: String,size: Vector3,at: Vector3,frame: Transform3D,rotation: Basis = Basis.IDENTITY) -> void:
	_primitive("box",key,size,at,frame,rotation)

func _primitive(kind: String,key: String,size: Vector3,at: Vector3,frame: Transform3D,rotation: Basis = Basis.IDENTITY) -> void:
	var family := kind+":"+key
	if not _batches.has(family): _batches[family] = {"kind":kind,"material":key,"transforms":[]}
	_batches[family].transforms.append(global_transform.affine_inverse()*frame*Transform3D(rotation*Basis.from_scale(size),at))
	report.batch_instances += 1

func _text(words: String,at: Vector3,frame: Transform3D,height: float) -> void:
	var mesh := TextMesh.new()
	mesh.text = words
	mesh.font_size = 64
	mesh.pixel_size = height/64.0
	mesh.depth = .007
	var instance := MeshInstance3D.new()
	instance.name = "FictionalSign_"+str(report.labels.size())
	instance.mesh = mesh
	instance.material_override = _materials.cream
	add_child(instance)
	instance.global_transform = frame*Transform3D(Basis.IDENTITY,at)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	report.labels.append({"text":words,"fictional":true,"vector_glyph_mesh":true})

func _flush() -> void:
	for family: String in _batches:
		var spec: Dictionary = _batches[family]
		if not _meshes.has(spec.kind):
			var mesh: Mesh
			match spec.kind:
				"arch": mesh = Arch.shared_mesh()
				"prism":
					var prism := PrismMesh.new()
					prism.size = Vector3.ONE
					mesh = prism
				"cylinder":
					var cylinder := CylinderMesh.new()
					cylinder.top_radius = .5; cylinder.bottom_radius = .5; cylinder.height = 1
					cylinder.radial_segments = 16; cylinder.rings = 0
					mesh = cylinder
				_:
					var box := BoxMesh.new(); box.size = Vector3.ONE; mesh = box
			_meshes[spec.kind] = mesh
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = _meshes[spec.kind]
		batch.instance_count = spec.transforms.size()
		for index: int in batch.instance_count: batch.set_instance_transform(index,spec.transforms[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "ArchitecturalBatch_"+family.replace(":","_")
		instance.multimesh = batch
		instance.material_override = _materials[spec.material]
		add_child(instance)
		if not Batches.register(instance,spec.transforms): report.errors.append("Batch registration rejected: "+family)
