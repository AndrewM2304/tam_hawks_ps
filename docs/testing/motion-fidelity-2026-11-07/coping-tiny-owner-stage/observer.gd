extends SceneTree
const Tests=preload("res://tests/pt24_bowl_contact_tests.gd")
const Setup=preload("res://game/core/input_setup.gd")
func _initialize():call_deferred("_run")
func _run():
	Setup.register_actions()
	var f:=await Tests._fixture(self)
	var original:StaticBody3D=f.bowl._native_annular_deck
	var paving:=StaticBody3D.new()
	paving.name="ForeignCoincidentAnnularFloor"
	for node in original.get_children():
		if not node is CollisionShape3D:continue
		var collision:=CollisionShape3D.new()
		collision.shape=node.shape
		collision.transform=node.transform
		paving.add_child(collision)
	f.root.add_child(paving)
	paving.global_transform=original.global_transform
	# Explicit2um height separates coincident native ray tie winners. The
	# actual finite source triangles/annular aperture are unchanged.
	paving.global_position.y+=.000002
	await physics_frame
	await process_frame
	var rider:CharacterBody3D=f.rider
	for at:Vector3 in [Vector3(-10.601124,2.0138104,139.50015),Vector3(-10.391407,2.0489893,139.51155),Vector3(-10.19133,2.063749,139.5394)]:
		rider.global_transform=Transform3D(Basis(Vector3.UP,-PI*.5),at)
		var fit:Dictionary=rider._native_board_floor()
		var clear:=false
		if not fit.is_empty():clear=rider._native_rim_frame_clear(Tests._presentation_pose(rider,fit),0.0)
		print("TINY_MIXED_OWNER ",{"at":at,"center":rider._native_floor_hit(Vector3.UP),"fit":fit,"clear":clear})
	f.viewport.free()
	quit()
