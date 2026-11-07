extends RefCounted
const StaticBatches = preload("res://game/levels/static_batches.gd")
const FacadeKit = preload("res://game/levels/art/facade_kit.gd")
const GalleryColumn = preload("res://game/levels/art/gallery_column.gd")
const FacadeShell = preload("res://game/levels/art/facade_shell.gd")
## Original gallery and shop-edge detail. Geometry/collision remain in world.
## Shared local portico dimensions keep visible shafts and their solids aligned.

const BASE_RADIUS:=0.54
const BASE_HEIGHT:=0.4
const SHAFT_RADIUS:=0.34
const COLUMN_HEIGHT:=5.35


static func column_positions() -> PackedVector3Array:
	var positions:=PackedVector3Array()
	for index: int in range(8):
		positions.append(Vector3(lerpf(-6.08,6.08,float(index)/7.0),2.65,-40.4))
	return positions


static func build(art: Node3D) -> void:
	var root:=Node3D.new()
	root.name="ExchangeGalleryArchitecture"
	root.set_meta("column_count",8)
	root.set_meta("art_only",true)
	art.add_child(root)
	var batches: Dictionary={}
	_profile_columns(root, art)
	for at: Vector3 in column_positions():
		art._batch_box(batches,"stone_light",Vector3(0.95,0.35,0.95),at+Vector3.UP*COLUMN_HEIGHT)
	# The old entablature/pediment datum stays8.45/10.85. A deeper back course
	# joins the real wall atZ−42 after the column row moves forward toZ−40.4.
	art._batch_box(batches,"cut_stone",Vector3(16.1,0.12,1.5),Vector3(0,8.78,-41.2))
	art._pediment(root,Vector3(0,8.75,-39.9),16.4,2.1,2.3,art.materials["stone"])
	# Restrained architrave/cornice courses meet the real entablature instead
	# of leaving its large face as a featureless stone rectangle.
	art._batch_box(batches,"cut_stone",Vector3(16.10,0.08,0.14),Vector3(0,8.22,-39.57))
	art._batch_box(batches,"cut_stone",Vector3(16.22,0.09,0.22),Vector3(0,8.70,-39.55))
	for index: int in range(32):
		art._batch_box(batches,"stone_light",Vector3(0.13,0.09,0.14),Vector3(-7.75+index*0.50,8.60,-39.56))
	var rake_length := Vector2(8.2,2.1).length()
	for side: float in [-1.0,1.0]:
		var rake := Basis.from_euler(Vector3(0,0,-side*atan2(2.1,8.2)))
		art._batch_box(batches,"cut_stone",Vector3(rake_length,0.11,0.14),Vector3(side*4.1,9.80,-38.72),rake)
	art._batch_box(batches,"cut_stone",Vector3(16.5,0.10,0.14),Vector3(0,8.77,-38.72))
	# Quiet slab/step bands retain the material's existing world triplanar scale.
	for z: float in [-40.0,-38.0,-36.0]:
		art._batch_box(batches,"stone",Vector3(12.9,0.006,0.018),Vector3(0,2.654,z))
	art._batch_box(batches,"stone_light",Vector3(8.9,0.008,0.07),Vector3(0,2.655,-33.08))
	for z: float in [1.0,4.0,7.0]:
		art._batch_box(batches,"stone",Vector3(6.5,0.006,0.018),Vector3(-31,0.454,z))
	art._flush_batches(root,batches)


static func _profile_columns(root: Node3D, art: Node3D) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = GalleryColumn.shared_mesh()
	var positions := column_positions()
	batch.instance_count = positions.size()
	var records: Array = []
	for index: int in range(positions.size()):
		var frame := Transform3D(Basis.IDENTITY, positions[index])
		batch.set_instance_transform(index,frame)
		records.append(frame)
	var display := MultiMeshInstance3D.new()
	display.name = "GalleryProfiledColumns"
	display.multimesh = batch
	display.material_override = art.materials["stone_light"]
	root.add_child(display)
	StaticBatches.register(display, records)


static func adapt_gallery_front(art: Node3D, building: Node3D) -> void:
	# This low gallery alone bypasses generic retail decoration. All original
	# door/threshold coordinates remain; a restrained shell meets the portico.
	var batches: Dictionary={}
	var recessed := _gallery_shell(building)
	for x: float in [-7.3,-4.6,-2.2,2.2,4.6,7.3]:
		FacadeKit._window(art,batches,x,5.22,1.25,1.40,0.0,"civic",0,recessed)
	for side: float in [-1.0,1.0]:
		var side_batches: Dictionary = {}
		for z: float in [-3.5,0.0,3.5]:
			FacadeKit._window(art,side_batches,z,5.22,1.25,1.40,0.0,"civic",0,recessed)
		_append_batches(batches, side_batches, Transform3D(Basis(Vector3.UP,side*PI/2.0),Vector3(side*3.0,0,0)))
		art._batch_box(batches,"cut_stone",Vector3(18.4,0.18,0.32),Vector3(0,6.53,side*6.10))
		art._batch_box(batches,"cut_stone",Vector3(0.32,0.18,12.2),Vector3(side*9.10,6.53,0))
		art._batch_box(batches,"stone_light",Vector3(18.5,0.10,0.38),Vector3(0,6.70,side*6.10))
		art._batch_box(batches,"stone_light",Vector3(0.38,0.10,12.2),Vector3(side*9.10,6.70,0))
	var back_batches: Dictionary = {}
	for x: float in [-6.0,-3.0,0.0,3.0,6.0]:
		FacadeKit._window(art,back_batches,x,5.22,1.25,1.40,0.0,"civic",0,recessed)
	_append_batches(batches,back_batches,Transform3D(Basis(Vector3.UP,PI),Vector3.ZERO))
	var roof:=MeshInstance3D.new()
	roof.name="GalleryClosedSlateRoof"
	roof.mesh=_closed_roof()
	roof.position.y=6.75
	roof.material_override=art.materials["slate"]
	building.add_child(roof)
	art._batch_box(batches,"window_shadow",Vector3(5.3,3.45,0.10),Vector3(0,2.25,6.10))
	for side: float in [-1.0,1.0]:
		art._batch_box(batches,"wood",Vector3(1.55,2.75,0.16),Vector3(side*0.8,2.105,6.23))
		art._batch_box(batches,"facade_glass",Vector3(1.18,1.65,0.035),Vector3(side*0.8,2.38,6.33))
		for edge: float in [-1.0,1.0]:
			art._batch_box(batches,"wood",Vector3(0.12,2.75,0.10),Vector3(side*0.8+edge*0.71,2.105,6.33))
			art._batch_box(batches,"wood",Vector3(0.055,0.65,0.035),Vector3(side*0.8+edge*0.53,1.18,6.34))
			art._batch_box(batches,"wood",Vector3(1.10,0.055,0.035),Vector3(side*0.8,1.18+edge*0.30,6.34))
		for rail_y: float in [0.81,1.60,3.40]:
			art._batch_box(batches,"wood",Vector3(1.42,0.10,0.10),Vector3(side*0.8,rail_y,6.33))
		art._batch_box(batches,"brass",Vector3(0.045,0.36,0.06),Vector3(side*0.16,1.9,6.36))
		art._batch_box(batches,"cut_stone",Vector3(0.38,3.18,0.34),Vector3(side*1.90,2.20,6.20))
	art._batch_box(batches,"cut_stone",Vector3(4.25,0.32,0.38),Vector3(0,3.93,6.20))
	art._batch_box(batches,"stone_light",Vector3(4.4,0.16,0.12),Vector3(0,4.16,6.22))
	art._flush_batches(building,batches)
	var label:=Label3D.new()
	label.name="GalleryEntranceName"
	label.text="EXCHANGE GALLERY"
	# The existing name belongs on the clear front frieze, above the shafts.
	label.position=Vector3(0,6.45,8.45)
	label.font_size=28
	label.pixel_size=0.0085
	label.modulate=Color("d9cba8")
	label.outline_size=0
	label.double_sided=false
	building.add_child(label)


static func _append_batches(destination: Dictionary, source: Dictionary, frame: Transform3D) -> void:
	for key: String in source:
		if not destination.has(key):
			destination[key] = {"material":source[key].material,"transforms":[]}
		for authored: Transform3D in source[key].transforms:
			destination[key].transforms.append(frame*authored)


static func _gallery_shell(building: Node3D) -> bool:
	var wall := building.get_node_or_null("Facade") as Node3D
	if wall == null:
		return false
	for node: Node in wall.get_children():
		if not node is MeshInstance3D or not node.mesh is BoxMesh:
			continue
		var display := node as MeshInstance3D
		var frame: Transform3D = building.global_transform.affine_inverse()*display.global_transform
		if not frame.basis.is_equal_approx(Basis.IDENTITY):
			continue
		var front: Array[Rect2] = []
		var back: Array[Rect2] = []
		var sides: Array[Rect2] = []
		for x: float in [-7.3,-4.6,-2.2,2.2,4.6,7.3]:
			front.append(Rect2(x-0.625-frame.origin.x,4.52-frame.origin.y,1.25,1.40))
		for x: float in [-6.0,-3.0,0.0,3.0,6.0]:
			back.append(Rect2(x-0.625-frame.origin.x,4.52-frame.origin.y,1.25,1.40))
		for z: float in [-3.5,0.0,3.5]:
			sides.append(Rect2(z-0.625-frame.origin.z,4.52-frame.origin.y,1.25,1.40))
		display.mesh = FacadeShell.make(display.mesh.size,front,sides,back)
		display.set_meta("architectural_recess_shell",true)
		return true
	return false


static func _closed_roof() -> ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var left_front:=Vector3(-9.25,0,6.25)
	var right_front:=Vector3(9.25,0,6.25)
	var left_back:=Vector3(-9.25,0,-6.25)
	var right_back:=Vector3(9.25,0,-6.25)
	var left_ridge:=Vector3(-9.25,1.35,0)
	var right_ridge:=Vector3(9.25,1.35,0)
	_roof_quad(surface,left_front,left_ridge,right_ridge,right_front,Vector3(0,6.25,1.35).normalized())
	_roof_quad(surface,left_back,right_back,right_ridge,left_ridge,Vector3(0,6.25,-1.35).normalized())
	_roof_triangle(surface,left_back,left_ridge,left_front,Vector3.LEFT)
	_roof_triangle(surface,right_back,right_front,right_ridge,Vector3.RIGHT)
	_roof_quad(surface,left_back,left_front,right_front,right_back,Vector3.DOWN)
	return surface.commit()


static func _roof_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	_roof_triangle(surface,a,b,c,normal)
	_roof_triangle(surface,a,c,d,normal)


static func _roof_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var vertices: Array[Vector3]=[a,b,c]
	if (b-a).cross(c-a).dot(normal)>0: vertices=[a,c,b]
	for at: Vector3 in vertices:
		surface.set_normal(normal)
		surface.add_vertex(at)


static func align_west_thresholds(building: Node3D) -> void:
	# The two existing doors within the new terrace have their actual door,
	# glazing, handle and threshold raised together by20.5cm. The old threshold
	# top0.325 now meets the supported0.53 landing over the0.45 terrace.
	# Other door bays, displays, upper windows and the whole building stay put.
	for child: Node in building.get_children():
		if not child is MultiMeshInstance3D: continue
		var authored := StaticBatches.authored_transforms(child)
		for index: int in range(child.multimesh.instance_count):
			var transform: Transform3D = authored[index] if index < authored.size() else child.multimesh.get_instance_transform(index)
			if transform.origin.y>3.0 or transform.origin.z<6.15: continue
			for door_x: float in [-9.59,-3.75]:
				if absf(transform.origin.x-door_x)<0.45:
					transform.origin.y+=0.205
					child.multimesh.set_instance_transform(index,transform)
					if index < authored.size(): authored[index] = transform
					break
		if not authored.is_empty(): StaticBatches.register(child, authored)
