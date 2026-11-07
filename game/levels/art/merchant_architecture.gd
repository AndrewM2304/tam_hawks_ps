extends Node3D
## PRIVATE original Glasgow composite; startup-only art, never gameplay geometry.
## Declared ceiling: +145k source triangles /48 submitted batches /4MiB native
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
var _wall_tools: Dictionary = {}
var _retired_unit_visuals: Array[MeshInstance3D] = []
var _unit_mode := false

static func build(parent: Node3D,materials: Dictionary,layout: Dictionary = {}) -> Node3D:
	var layer = load("res://game/levels/art/merchant_architecture.gd").new()
	layer.name = "MerchantArchitecture"
	parent.add_child(layer)
	layer._compose(parent,materials,layout)
	return layer

func _compose(parent: Node3D,materials: Dictionary,layout: Dictionary) -> void:
	_world = parent
	_materials = materials
	set_meta(Batches.META_STATIC_SCOPE,true)
	var manifest: Dictionary = parent.call("get_level_manifest")
	if not manifest.get("architecture_units",[]).is_empty():
		_compose_units(manifest.architecture_units)
		return
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
		report.openings.append({"shell":str(shell.name),"frame":frame,"rectangle":opening,"native_cut_front":true,"kind":contract.type})
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
	# A genuine shallow shop room sits behind the glazing: back/floor/soffit
	# and deep side reveals meet inside the existing native building footprint.
	_box("interior_plaster",Vector3(display_w-.12,2.08,.035),Vector3(display_x,floor+1.61,-1.45),frame)
	_box("wood",Vector3(display_w,.055,1.42),Vector3(display_x,floor+.57,-.73),frame)
	_box("interior_plaster",Vector3(display_w,.06,1.42),Vector3(display_x,floor+2.68,-.73),frame)
	for side: float in [-1.0,1.0]:
		_box("interior_plaster",Vector3(.05,2.08,1.40),Vector3(display_x+side*(display_w*.5-.025),floor+1.61,-.73),frame)
	for edge: float in [-1.0,1.0]:
		_box(paint,Vector3(.065,2.16,.28),Vector3(display_x+edge*(display_w*.5-.035),floor+1.625,-.12),frame)
	_box("shop_glass",Vector3(display_w-.10,2.06,.018),Vector3(display_x,floor+1.61,-.025),frame)
	_door(frame,door_x,floor,paint)
	# Only one original business sign per shop; vector glyph mesh shares cream,
	# adds no raster texture/material. Its exact tessellation is inventoried natively.
	_text(SHOP_NAMES[index%SHOP_NAMES.size()],Vector3(x,floor+3.08,relief-.005),frame,minf(.22,(width-.3)/14.0))
	_shop_stock(frame,display_x,floor,display_w,index%4)

func _shop_stock(frame: Transform3D,x: float,floor: float,width: float,kind: int) -> void:
	for shelf: int in 2:
		var y := floor+.88+shelf*.72
		_box("wood",Vector3(width-.15,.045,.50),Vector3(x,y,-.63),frame)
		if kind==0: # Full-size original record sleeves and exposed black vinyl.
			for item: int in 7:
				var at_x := x-width*.40+item*width*.133
				_box(PAINT[(item+shelf)%4],Vector3(.30,.30,.025),Vector3(at_x,y+.18,-.55),frame,Basis.from_euler(Vector3(0,.10*(item%3-1),.03*(item%2))))
				_stock_label(Vector3(.16,.035,.006),Vector3(at_x,y+.25,-.534),frame)
				if item%3==1:
					_primitive("record","iron",Vector3(.26,.012,.26),Vector3(at_x+.11,y+.17,-.51),frame,Basis.from_euler(Vector3(PI*.5,0,0)))
		elif kind==1: # Dense small groups with varied book heights/lean.
			for group: int in 3:
				for book: int in 7:
					var at_x := x+(group-1)*width*.29+(book-3)*.075
					_box(PAINT[(book+group+shelf)%4],Vector3(.064,.21+.025*(book%4),.17),Vector3(at_x,y+.15,-.54),frame,Basis.from_euler(Vector3(0,0,.035*(book%3-1))))
					_stock_label(Vector3(.038,.012,.008),Vector3(at_x,y+.23,-.449),frame)
		elif kind==2: # Boxes, tins and bottles belong to a grocer, not a record shop.
			for item: int in 12:
				var at_x := x-width*.42+item*width*.076
				if item%3==0:
					_primitive("stock_cylinder","shop_green",Vector3(.075,.22,.075),Vector3(at_x,y+.14,-.52),frame)
					_primitive("stock_cylinder","shop_umber",Vector3(.032,.065,.032),Vector3(at_x,y+.275,-.52),frame)
				else:
					_box(PAINT[(item+shelf)%4],Vector3(.13,.16+.025*(item%2),.10),Vector3(at_x,y+.12,-.53),frame)
					_stock_label(Vector3(.08,.05,.008),Vector3(at_x,y+.14,-.475),frame)
		else: # Work cases and clearly shaped repair tools on the bench.
			for item: int in 4:
				var at_x := x-width*.35+item*width*.23
				_box("shop_umber",Vector3(.40,.20,.24),Vector3(at_x,y+.13,-.57),frame)
				_box("iron",Vector3(.14,.025,.035),Vector3(at_x,y+.25,-.57),frame)
				_box("iron",Vector3(.035,.18,.035),Vector3(at_x+.17,y+.34,-.52),frame)
				_box("iron",Vector3(.10,.03,.035),Vector3(at_x+.17,y+.43,-.52),frame)

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
	if index%2==0 and not _unit_mode:
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
	# Existing piers alone carry shallow brick/stone courses. The flat native
	# slab receives a joined steel edge; a curved floating trim was rejected.
	for x: float in [30,52,74]:
		if _unit_mode:continue # Native03a already supplies complete exposed pier skins.
		for z: float in [-13.2,1.2]:
			_box("cut_stone",Vector3(1.92,.16,1.92),Vector3(x,8.35,z),Transform3D.IDENTITY)
			for course: int in 4:
				_box("warehouse_brick",Vector3(1.92,.07,1.92),Vector3(x,4.22+course*1.0,z),Transform3D.IDENTITY)
	# The actual bridge has a flat steel-deck soffit, not an arched tunnel.
	# A thin floating decorative curve was rejected in native views. Joined
	# girder webs/flanges instead meet that exact existing slab edge; no new
	# component enters the4.5m clear ground passage or published9m roof.
	for x: float in [27.95,76.05]:
		_primitive("box","iron",Vector3(.09,.40,11.94),Vector3(x,8.74,-6),Transform3D.IDENTITY)
		for y: float in [8.55,8.93]:
			_primitive("box","iron",Vector3(.10,.06,11.96),Vector3(x,y,-6),Transform3D.IDENTITY)
		for index: int in 11:
			_primitive("box","iron",Vector3(.10,.055,.055),Vector3(x,8.74,-11.25+index*1.05),Transform3D.IDENTITY)
	report.frontages.append({"id":"depot_underpass","native_piers":6,"minimum_art_soffit_y":8.52,"native_clearance_m":4.5,"structure":"joined girder on native flat slab; genuine masonry arch is a later LD-owned shape"})

func _box(key: String,size: Vector3,at: Vector3,frame: Transform3D,rotation: Basis = Basis.IDENTITY) -> void:
	_primitive("facade_box" if _unit_mode else "box",key,size,at,frame,rotation)

func _stock_label(size: Vector3,at: Vector3,frame: Transform3D) -> void:
	# Printed labels keep the exact former front plane, without an unseen box.
	_primitive("stock_label","cream",Vector3(size.x,size.y,1),at+Vector3(0,0,size.z*.5),frame)

func _primitive(kind: String,key: String,size: Vector3,at: Vector3,frame: Transform3D,rotation: Basis = Basis.IDENTITY) -> void:
	var family := kind+":"+key
	if not _batches.has(family): _batches[family] = {"kind":kind,"material":key,"transforms":[]}
	_batches[family].transforms.append(global_transform.affine_inverse()*frame*Transform3D(rotation*Basis.from_scale(size),at))
	report.batch_instances += 1

func _text(words: String,at: Vector3,frame: Transform3D,height: float) -> void:
	# Shared vector word meshes need no glyph atlas. Four-pixel outline sampling
	# at64px font size preserves small sign curves without default0.5px overdraw.
	var kind := "text_"+words+"_"+str(height)
	if not _meshes.has(kind):
		var mesh := TextMesh.new()
		mesh.text = words
		mesh.font_size = 64
		mesh.pixel_size = height/64.0
		mesh.curve_step = 4.0
		mesh.depth = 0.0
		_meshes[kind] = mesh
	_primitive(kind,"cream",Vector3.ONE,at,frame)
	report.labels.append({"text":words,"fictional":true,"vector_glyph_mesh":true,"curve_step_pixels":4.0,"shared_word_mesh":true,"painted_flat_letters":true})

func _flush() -> void:
	for family: String in _batches:
		var spec: Dictionary = _batches[family]
		if not _meshes.has(spec.kind):
			var mesh: Mesh
			match spec.kind:
				"stock_label":
					var label := QuadMesh.new();label.size=Vector2.ONE;mesh=label
				"facade_box":
					var box := BoxMesh.new();box.size=Vector3.ONE
					var arrays: Array=box.surface_get_arrays(0)
					var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
					var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
					var kept:=PackedInt32Array()
					for i in range(0,indices.size(),3):
						if normals[indices[i]].z < -.99:continue
						kept.append_array(indices.slice(i,i+3))
					arrays[Mesh.ARRAY_INDEX]=kept
					var trimmed:=ArrayMesh.new();trimmed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh=trimmed
				"arch": mesh = Arch.shared_mesh()
				"prism":
					var prism := PrismMesh.new()
					prism.size = Vector3.ONE
					mesh = prism
				"cylinder", "record":
					var cylinder := CylinderMesh.new()
					cylinder.top_radius = .5; cylinder.bottom_radius = .5; cylinder.height = 1
					cylinder.radial_segments = 16; cylinder.rings = 0
					cylinder.cap_bottom = spec.kind != "record"
					mesh = cylinder
				"stock_cylinder":
					var cylinder:=CylinderMesh.new();cylinder.top_radius=.5;cylinder.bottom_radius=.5;cylinder.height=1
					cylinder.radial_segments=8;cylinder.rings=0;mesh=cylinder
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
		if str(spec.kind).begins_with("text_"): instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		if not Batches.register(instance,spec.transforms): report.errors.append("Batch registration rejected: "+family)

# V5 OFFLINE PROFILE PROTOTYPE. Not yet wired to LD's new native unit contract.
# Shared real joinery replaces the intersecting per-window box collection.
# At canonical size: stone60tri /timber56tri /glazing2tri. No new materials/maps.
static var _window_kit_cache: Dictionary = {}

static func make_window_kit(width: float = 1.4,height: float = 2.0) -> Dictionary:
	if not is_finite(width) or not is_finite(height) or width<.45 or width>4.0 or height<.8 or height>4.0:
		return {}
	var key := Vector2(width,height)
	if _window_kit_cache.has(key): return _window_kit_cache[key]
	var stone := SurfaceTool.new();stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Section moves from the actual inner reveal, through a bevelled face and
	# dressed outer edge, then closes behind the wall. Mitered corners join.
	var stone_section: Array[Vector2] = [Vector2(0,-.30),Vector2(0,-.02),
		Vector2(.025,.025),Vector2(.12,.025),Vector2(.15,0),Vector2(.15,-.30)]
	_kit_ring(stone,width,height,stone_section)
	_kit_sill(stone,width,height)
	var timber := SurfaceTool.new();timber.begin(Mesh.PRIMITIVE_TRIANGLES)
	var timber_section: Array[Vector2] = [Vector2(0,-.225),Vector2(0,-.16),
		Vector2(.055,-.16),Vector2(.055,-.225)]
	_kit_ring(timber,width-.12,height-.12,timber_section)
	_kit_box(timber,Vector3(width-.10,.045,.065),Vector3(0,.03,-.1925))
	var mullion_bottom := .0525
	var mullion_top := height*.5-.055
	_kit_box(timber,Vector3(.022,mullion_top-mullion_bottom,.065),
		Vector3(0,(mullion_top+mullion_bottom)*.5,-.1925))
	var glazing := SurfaceTool.new();glazing.begin(Mesh.PRIMITIVE_TRIANGLES)
	_kit_quad(glazing,Vector3(-width*.5,-height*.5,-.245),Vector3(width*.5,-height*.5,-.245),
		Vector3(width*.5,height*.5,-.245),Vector3(-width*.5,height*.5,-.245),Vector3.BACK,Vector2(width,height))
	var result := {"stone":_kit_finish(stone),"timber":_kit_finish(timber),"glazing":_kit_finish(glazing),
		"width_m":width,"height_m":height,"sash_recess_m":.16,"glazing_recess_m":.245,
		"sill_projection_m":.09,"stone_section":stone_section,"timber_section":timber_section,
		"expected_triangles":{"stone":42,"timber":28,"glazing":2},
		"topology":"street-facing stone/sill/sash; buried returns closed by solid wall; glazing:intentional single front sheet"}
	_window_kit_cache[key] = result
	return result

static func _kit_ring(surface: SurfaceTool,width: float,height: float,section: Array[Vector2]) -> void:
	var outward: Array[Vector3] = [Vector3.LEFT,Vector3.UP,Vector3.RIGHT,Vector3.DOWN]
	for edge: int in 4:
		for profile: int in section.size():
			# Back and outer returns are enclosed by the opaque solid facade.
			if profile >= section.size()-2:continue
			var a: Vector2 = section[profile]
			var b: Vector2 = section[(profile+1)%section.size()]
			var normal: Vector3 = (outward[edge]*-(b.y-a.y)+Vector3.BACK*(b.x-a.x)).normalized()
			_kit_quad(surface,_kit_corner(width,height,a,edge),_kit_corner(width,height,a,(edge+1)%4),
				_kit_corner(width,height,b,(edge+1)%4),_kit_corner(width,height,b,edge),normal)

static func _kit_corner(width: float,height: float,section: Vector2,index: int) -> Vector3:
	var signs: Array[Vector2] = [Vector2(-1,-1),Vector2(-1,1),Vector2(1,1),Vector2(1,-1)]
	var at: Vector2 = signs[index]
	return Vector3(at.x*(width*.5+section.x),at.y*(height*.5+section.x),section.y)

static func _kit_sill(surface: SurfaceTool,width: float,height: float) -> void:
	var half_width := (width+.36)*.5
	var rear := -.30
	var front := .09
	var rear_top := -height*.5-.01
	var front_top := -height*.5-.055
	var bottom := -height*.5-.14
	var a := Vector3(-half_width,rear_top,rear);var b := Vector3(half_width,rear_top,rear)
	var c := Vector3(half_width,front_top,front);var d := Vector3(-half_width,front_top,front)
	var e := Vector3(-half_width,bottom,rear);var f := Vector3(half_width,bottom,rear)
	var g := Vector3(half_width,bottom,front);var h := Vector3(-half_width,bottom,front)
	_kit_quad(surface,a,b,c,d,Vector3(0,1,(rear_top-front_top)/(front-rear)).normalized())
	_kit_quad(surface,e,h,g,f,Vector3.DOWN)
	_kit_quad(surface,d,c,g,h,Vector3.BACK)
	_kit_quad(surface,a,d,h,e,Vector3.LEFT)
	_kit_quad(surface,b,f,g,c,Vector3.RIGHT)

static func _kit_box(surface: SurfaceTool,size: Vector3,at: Vector3) -> void:
	var h := size*.5
	var a := at+Vector3(-h.x,-h.y,-h.z);var b := at+Vector3(h.x,-h.y,-h.z)
	var c := at+Vector3(h.x,h.y,-h.z);var d := at+Vector3(-h.x,h.y,-h.z)
	var e := at+Vector3(-h.x,-h.y,h.z);var f := at+Vector3(h.x,-h.y,h.z)
	var g := at+Vector3(h.x,h.y,h.z);var j := at+Vector3(-h.x,h.y,h.z)
	_kit_quad(surface,e,f,g,j,Vector3.BACK)
	# Bar ends join the surrounding sash or the meeting rail. Keep only the
	# front and the two exposed long side faces of each rectangular bar.
	if size.x > size.y:
		_kit_quad(surface,d,j,g,c,Vector3.UP)
		_kit_quad(surface,a,b,f,e,Vector3.DOWN)
	else:
		_kit_quad(surface,a,e,j,d,Vector3.LEFT)
		_kit_quad(surface,b,c,g,f,Vector3.RIGHT)

static func _kit_quad(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,normal: Vector3,glazing_size: Vector2 = Vector2.ZERO) -> void:
	for triangle: Array in [[a,b,c],[a,c,d]]:
		# Godot's visible winding is clockwise viewed from the supplied normal.
		if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).dot(normal)>0: triangle.reverse()
		for vertex: Vector3 in triangle:
			surface.set_normal(normal)
			var uv := Vector2(vertex.x,vertex.y)
			if absf(normal.z)<.5:
				uv = Vector2(vertex.z,vertex.y) if absf(normal.x)>absf(normal.y) else Vector2(vertex.x,vertex.z)
			if glazing_size != Vector2.ZERO:
				# SharedGlazing expects a BoxMesh front atlas cell. One complete
				# opening spans U1/3..2/3,V0..1/2 before its shader multiplies3x2.
				uv = Vector2(.5+vertex.x/(3.0*glazing_size.x),.25+vertex.y/(2.0*glazing_size.y))
			surface.set_uv(uv)
			surface.add_vertex(vertex)

static func _kit_finish(surface: SurfaceTool) -> ArrayMesh:
	surface.index()
	# Native MikkTSpace derives handedness from the real UV Jacobian. No manual
	# tangent-W shortcut; the native fixture must inspect uploaded arrays.
	surface.generate_tangents()
	return surface.commit()

func _compose_units(units: Array) -> void:
	_unit_mode=true
	# Actual03a metadata only. No research JSON, global-position style guess or
	# hidden replacement physics. Native wall/roof/bay volumes stay authoritative.
	report["unit_count"] = units.size()
	report["unit_faces"] = 0
	report["kit_windows"] = 0
	report["native_roofs_retained"] = 0
	report["phase"] = "V5 whole-street pilot; native roof ornaments require coupled volumes"
	var kit: Dictionary = make_window_kit()
	_meshes["window_stone"] = kit.stone
	_meshes["window_timber"] = kit.timber
	_meshes["window_pane"] = kit.glazing
	_meshes["unit_cornice"] = _make_unit_cornice()
	for raw: Variant in units:
		if not raw is Dictionary: report.errors.append("Invalid native unit record");continue
		var unit: Dictionary = raw
		var body := _world.get_node_or_null(NodePath(str(unit.body_path))) as StaticBody3D
		if body==null: report.errors.append("Missing actual unit "+str(unit.id));continue
		var original: MeshInstance3D
		for child: Node in body.get_children():
			if child is MeshInstance3D and child.mesh is BoxMesh and child.visible:
				original = child
				break
		if original==null: report.errors.append("No native wall mesh "+str(unit.id));continue
		var floor_y: float = float(unit.floor_y)
		var bottom_y: float = float(unit.wall_bottom_y)
		var eave_y: float = float(unit.eave_y)
		var height: float = eave_y-floor_y
		var material: String = str(unit.get("material_key","sandstone"))
		var size: Vector3 = (original.mesh as BoxMesh).size
		var center: Vector3 = original.global_position
		if floor_y>bottom_y:
			_primitive("box",material,Vector3(size.x,floor_y-bottom_y,size.z),Vector3.ZERO,
				Transform3D(original.global_basis,Vector3(center.x,(floor_y+bottom_y)*.5,center.z)))
		var active: Dictionary = {}
		for front: Dictionary in unit.front_frames:
			var face_name: String = str(front.face)
			if not active.has(face_name):active[face_name]=[]
			active[face_name].append(front)
		for face_name: String in ["north","south","east","west"]:
			var description: Dictionary = _unit_face(original,face_name,floor_y)
			var frame: Transform3D = description.frame
			var width: float = description.width
			var holes: Array[Rect2] = []
			var bay_holes: Array[Rect2] = []
			for bay: Dictionary in unit.native_bay_hulls:
				var bay_frame: Transform3D = bay.front_frame
				if bay_frame.basis.z.dot(frame.basis.z)<.999:continue
				var offset: Vector3 = frame.affine_inverse()*bay_frame.origin
				# Intersect the genuine canted side with the parent wall plane.
				var seam_inset: float = .4*.02/.57
				var hole := Rect2(offset.x-float(bay.width)*.5+seam_inset,
					float(bay.bottom_y)-floor_y,float(bay.width)-2*seam_inset,float(bay.top_y)-float(bay.bottom_y))
				bay_holes.append(hole)
				holes.append(hole)
				_skin_native_bay(unit,bay,material)
			if active.has(face_name):
				report.unit_faces += 1
				var columns: int = clampi(floori(width/2.8),1,4)
				var rows: int = int(unit.storeys)-1
				var step: float = width/columns
				var floor_height: float = float(unit.upper_floor_height_m)
				for row: int in rows:
					var upper_base: float = float(unit.ground_floor_height_m)+row*floor_height
					var last: bool = row==rows-1
					var window_height: float = minf(2.05 if not last else 1.85,floor_height-.9)
					if str(unit.type)=="brick_industrial":window_height=minf(2.65,floor_height-.8)
					var sill: float = upper_base+(.60 if last else .70)
					for column: int in columns:
						var x: float = -width*.5+step*(column+.5)
						var window_width: float = minf(1.30,step*.48)
						var outer := Rect2(x-window_width*.60715,sill-window_height*.075,
							window_width*1.2143,window_height*1.15)
						var covered := false
						for bay_rect: Rect2 in bay_holes:
							if outer.intersects(bay_rect):covered=true
						if not covered:_unit_window(frame,x,sill+window_height*.5,window_width,window_height,holes,material)
				var segment_index := 0
				for front: Dictionary in active[face_name]:
					var segment_frame: Transform3D = front.frame
					segment_frame.origin.y=floor_y
					var offset: Vector3 = frame.affine_inverse()*segment_frame.origin
					var segment_width: float = float(front.width)
					var commercial: bool = str(unit.source_mass) in ["street_block_4","street_block_10","street_block_26"] or bool(unit.get("new_market_framing",false))
					var seed: int = (str(unit.id).hash()&0x7fffffff)+segment_index
					if str(unit.type)=="brick_industrial":
						var dummy: Array[Rect2] = []
						var inset := segment_frame.translated_local(Vector3(0,0,-.12))
						_goods_bay(inset,0,0,minf(4.6,segment_width-.4),seed,dummy,false)
						for r: Rect2 in dummy:
							holes.append(Rect2(r.position+Vector2(offset.x,0),r.size))
						_unit_sign(frame,offset.x,3.73,minf(3.4,segment_width-.3),"FOUNDRY WORKS",holes,material)
					elif commercial and segment_width>=3.7:
						_unit_shop(segment_frame,minf(6.4,segment_width-.2),seed,holes,offset.x,material)
					else:
						var door: bool = face_name==str(unit.front_face) and segment_index==0
						if door:
							var door_x: float = -minf(segment_width*.27,1.65)
							if seed%5==0 and segment_width>=4.5:
								_unit_close(segment_frame,door_x,holes,offset.x,material)
							else:
								_door(segment_frame.translated_local(Vector3(0,0,-.10)),door_x,0,PAINT[seed%4])
								var door_rect := Rect2(offset.x+door_x-.43,.08,.86,2.62)
								holes.append(door_rect);_wall_bridge(frame,door_rect,-.24,material)
						var wx: float = minf(segment_width*.23,1.55) if door else 0.0
						if segment_width>=2.8:_unit_window(frame,offset.x+wx,1.65,minf(1.5,segment_width*.32),1.8,holes,material)
					if bool(unit.get("new_market_framing",false)) and not report.has("junction_sign"):
						_unit_sign(frame,offset.x,float(unit.ground_floor_height_m)+.28,minf(4.2,segment_width-.2),"MERCHANT CROSS",holes,material)
						report["junction_sign"] = str(unit.id)
					segment_index += 1
				# A recessed, swept native-envelope cornice replaces a stack of
				# isolated trim boxes. Cut its strip so the relief is actually visible.
				holes.append(Rect2(-width*.5,height-.35,width,.35))
				_primitive("unit_cornice","stone_light" if material!="warehouse_brick" else material,
					Vector3(width,1,1),Vector3(0,height,0),frame)
				# Deliberate belt courses line up on common floors around corners.
				for row: int in maxi(0,rows-1):
					var band_y: float = float(unit.ground_floor_height_m)+(row+1)*floor_height-.10
					holes.append(Rect2(-width*.5,band_y-.06,width,.12))
					_box("stone_light",Vector3(width,.12,.12),Vector3(0,band_y,-.06),frame)
			_emit_wall(frame,Rect2(-width*.5,0,width,height),holes,material)
		_retired_unit_visuals.append(original)
		report.native_roofs_retained += 1
	# A few readable names identify the actual junction, with painted vector
	# lettering already included in business frontage construction.
	_underpass()
	for family: String in _wall_tools:
		var record: Dictionary = _wall_tools[family]
		_meshes[family]=_kit_finish(record.surface)
		_batches[family]={"kind":family,"material":record.material,"transforms":[Transform3D.IDENTITY]}
	_flush()
	if report.errors.is_empty():
		for visual: MeshInstance3D in _retired_unit_visuals:visual.visible=false
	else:
		for child: Node in get_children():child.free()
	report["submitted_batches"]=_batches.size()
	report["native_visuals_retired"]=_retired_unit_visuals.size()
	report["no_new_maps_or_materials"]=true
	report["native_collision_owned_by_level_designer"]=true

func _unit_face(visual: MeshInstance3D,name_value: String,floor_y: float) -> Dictionary:
	var size: Vector3 = (visual.mesh as BoxMesh).size
	var normal := Vector3.BACK
	var width: float = size.x
	var depth: float = size.z
	match name_value:
		"north":normal=Vector3.FORWARD
		"east":normal=Vector3.RIGHT;width=size.z;depth=size.x
		"west":normal=Vector3.LEFT;width=size.z;depth=size.x
	var world_normal: Vector3 = (visual.global_basis*normal).normalized()
	var center: Vector3 = visual.global_position+world_normal*depth*.5
	center.y=floor_y
	return {"frame":Transform3D(Basis(Vector3.UP.cross(world_normal),Vector3.UP,world_normal),center),"width":width}

func _wall_key(frame: Transform3D,material: String) -> String:
	var sector := "west" if frame.origin.x< -35 else ("market" if frame.origin.x<30 else "east")
	return "unit_wall_"+sector+"_"+material

func _wall_record(frame: Transform3D,material: String) -> Dictionary:
	var key := _wall_key(frame,material)
	if not _wall_tools.has(key):
		var surface := SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_wall_tools[key]={"surface":surface,"material":material}
	return _wall_tools[key]

func _emit_wall(frame: Transform3D,bounds: Rect2,holes: Array[Rect2],material: String) -> void:
	var record: Dictionary = _wall_record(frame,material)
	var local: Transform3D = global_transform.affine_inverse()*frame
	Shell._plane(record.surface,bounds,holes,local.origin,local.basis.x,local.basis.y,local.basis.z)

func _wall_bridge(frame: Transform3D,r: Rect2,rear: float,material: String) -> void:
	var record: Dictionary = _wall_record(frame,material)
	var local: Transform3D = global_transform.affine_inverse()*frame
	var corners: Array[Vector2] = [r.position,Vector2(r.position.x,r.end.y),r.end,Vector2(r.end.x,r.position.y)]
	var normals: Array[Vector3] = [Vector3.RIGHT,Vector3.DOWN,Vector3.LEFT,Vector3.UP]
	for edge: int in 4:
		var a: Vector2=corners[edge];var b: Vector2=corners[(edge+1)%4]
		_kit_quad(record.surface,local*Vector3(a.x,a.y,0),local*Vector3(b.x,b.y,0),
			local*Vector3(b.x,b.y,rear),local*Vector3(a.x,a.y,rear),(local.basis*normals[edge]).normalized())

func _unit_window(frame: Transform3D,x: float,y: float,width: float,height: float,holes: Array[Rect2],material: String) -> void:
	var sx: float=width/1.4;var sy: float=height/2.0
	var r:=Rect2(x-(1.4+.30)*sx*.5,y-(2.0+.30)*sy*.5,(1.4+.30)*sx,(2.0+.30)*sy)
	holes.append(r)
	_wall_bridge(frame,r,-.09,material)
	var size:=Vector3(sx,sy,1)
	var at:=Vector3(x,y,-.09)
	_primitive("window_stone","stone_light" if material!="warehouse_brick" else material,size,at,frame)
	_primitive("window_timber","window_frame" if material!="warehouse_brick" else "iron",size,at,frame)
	_primitive("window_pane","facade_glass",size,at,frame)
	report.kit_windows += 1
	report.openings.append({"frame":frame,"rectangle":r,"wall_family":_wall_key(frame,material),"pane_recess_m":.335})

func _unit_shop(frame: Transform3D,width: float,seed: int,holes: Array[Rect2],offset: float,material: String) -> void:
	var front:=frame.translated_local(Vector3(0,0,-.12))
	var internal: Array[Rect2]=[]
	var paint: String=PAINT[seed%4]
	_shop(front,0,0,width,paint,seed,internal,.12)
	var outside:=Rect2(-width*.5-.10,0,width+.20,3.45)
	_emit_wall(front,outside,internal,paint)
	var actual:=Rect2(outside.position+Vector2(offset,0),outside.size)
	holes.append(actual)
	_wall_bridge(frame,outside,-.12,material)

func _unit_close(frame: Transform3D,x: float,holes: Array[Rect2],offset: float,material: String) -> void:
	var front:=frame.translated_local(Vector3(0,0,-.12))
	var internal: Array[Rect2]=[]
	_closed_close(front,x,0,internal)
	var outside:=Rect2(x-1.02,0,2.04,3.55)
	_emit_wall(front,outside,internal,material)
	holes.append(Rect2(outside.position+Vector2(offset,0),outside.size))
	_wall_bridge(frame,outside,-.12,material)

func _skin_native_bay(unit: Dictionary,bay: Dictionary,material: String) -> void:
	var points: PackedVector3Array=bay.world_points
	var bottom: float=float(bay.bottom_y)
	var top: float=float(bay.top_y)
	var floor_y: float=float(unit.floor_y)
	var original:=_world.get_node_or_null(NodePath(str(bay.mesh_path))) as MeshInstance3D
	if original==null:report.errors.append("Missing actual bay visual "+str(bay.id));return
	for edge: int in 3:
		var a: Vector3=points[edge];var b: Vector3=points[edge+1]
		var across: Vector3=(b-a).normalized()
		var normal: Vector3=across.cross(Vector3.UP).normalized()
		var center: Vector3=(a+b)*.5
		var frame:=Transform3D(Basis(across,Vector3.UP,normal),Vector3(center.x,bottom,center.z))
		var width: float=a.distance_to(b)
		var holes: Array[Rect2]=[]
		for row: int in int(unit.storeys)-1:
			var base: float=floor_y+float(unit.ground_floor_height_m)+row*float(unit.upper_floor_height_m)
			var low: float=maxf(base+.70,bottom+.18)
			var high: float=minf(base+float(unit.upper_floor_height_m)-.35,top-.18)
			if high-low<.8:continue
			var pane_height: float=(high-low)/1.15
			var pane_width: float=minf(1.30,(width-.06)/1.2143)
			_unit_window(frame,0,(high+low)*.5-bottom,pane_width,pane_height,holes,material)
		_emit_wall(frame,Rect2(-width*.5,0,width,top-bottom),holes,material)
	var record: Dictionary=_wall_record(Transform3D(Basis.IDENTITY,points[0]),material)
	var inverse: Transform3D=global_transform.affine_inverse()
	_kit_quad(record.surface,inverse*points[4],inverse*points[5],inverse*points[6],inverse*points[7],Vector3.UP)
	_kit_quad(record.surface,inverse*points[3],inverse*points[2],inverse*points[1],inverse*points[0],Vector3.DOWN)
	_retired_unit_visuals.append(original)

static func _make_unit_cornice() -> ArrayMesh:
	var section: Array[Vector2]=[Vector2(-.35,-.30),Vector2(-.35,0),Vector2(-.28,-.12),
		Vector2(-.19,-.12),Vector2(-.15,0),Vector2(-.07,0),Vector2(-.04,-.04),Vector2(0,0),Vector2(0,-.30)]
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for edge: int in section.size():
		var a: Vector2=section[edge];var b: Vector2=section[(edge+1)%section.size()]
		var normal:=Vector3(0,-(b.y-a.y),b.x-a.x).normalized()
		_kit_quad(surface,Vector3(-.5,a.x,a.y),Vector3(.5,a.x,a.y),Vector3(.5,b.x,b.y),Vector3(-.5,b.x,b.y),normal)
	var polygon:=PackedVector2Array(section)
	var triangles: PackedInt32Array=Geometry2D.triangulate_polygon(polygon)
	for side: float in [-1.0,1.0]:
		for index: int in range(0,triangles.size(),3):
			var points: Array[Vector3]=[]
			for offset: int in 3:
				var at: Vector2=section[triangles[index+offset]]
				points.append(Vector3(side*.5,at.x,at.y))
			var normal:=Vector3(side,0,0)
			if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0:points.reverse()
			for at: Vector3 in points:
				surface.set_normal(normal);surface.set_uv(Vector2(at.z,at.y));surface.add_vertex(at)
	return _kit_finish(surface)

func _unit_sign(frame: Transform3D,x: float,y: float,width: float,words: String,holes: Array[Rect2],material: String) -> void:
	var rectangle:=Rect2(x-width*.5,y-.20,width,.40)
	holes.append(rectangle)
	_wall_bridge(frame,rectangle,-.07,material)
	_box("shop_navy",Vector3(width,.40,.04),Vector3(x,y,-.07),frame)
	_text(words,Vector3(x,y,-.045),frame,minf(.28,width/16.0))
